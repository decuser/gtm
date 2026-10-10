package main

import (
	"bytes"
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"
	"syscall"

	"github.com/hanwen/go-fuse/v2/fs"
	"github.com/hanwen/go-fuse/v2/fuse"
)

type entryKind uint8

const (
	kindDir entryKind = iota
	kindFile
	kindSymlink
	kindGitlink
)

type entry struct {
	path string
	name string
	oid  string
	size uint64
	mode uint32
	kind entryKind
}

type snapshot struct {
	repo    string
	commit  string
	entries map[string]*entry
	cache   string

	mu        sync.Mutex
	blobFiles map[string]string
}

type node struct {
	fs.Inode
	snap *snapshot
	ent  *entry
}

type fileHandle struct {
	f *os.File
}

var _ fs.NodeGetattrer = (*node)(nil)
var _ fs.NodeOpener = (*node)(nil)
var _ fs.NodeReadlinker = (*node)(nil)
var _ fs.FileReader = (*fileHandle)(nil)
var _ fs.FileReleaser = (*fileHandle)(nil)

func main() {
	debug := flag.Bool("debug", false, "enable FUSE debug logging")
	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "usage: %s [--debug] REPO COMMIT MOUNTPOINT\n", os.Args[0])
	}
	flag.Parse()
	if flag.NArg() != 3 {
		flag.Usage()
		os.Exit(2)
	}

	repo, err := filepath.Abs(flag.Arg(0))
	if err != nil {
		log.Fatal(err)
	}
	commit := flag.Arg(1)
	mountpoint, err := filepath.Abs(flag.Arg(2))
	if err != nil {
		log.Fatal(err)
	}

	if err := validateRepo(repo); err != nil {
		log.Fatal(err)
	}
	fullCommit, err := resolveCommit(repo, commit)
	if err != nil {
		log.Fatal(err)
	}
	if err := ensureMountpoint(mountpoint); err != nil {
		log.Fatal(err)
	}

	cache, err := os.MkdirTemp("", "gtm-mount-")
	if err != nil {
		log.Fatal(err)
	}
	defer os.RemoveAll(cache)

	s := &snapshot{
		repo:      repo,
		commit:    fullCommit,
		entries:   make(map[string]*entry),
		cache:     cache,
		blobFiles: make(map[string]string),
	}
	if err := s.loadTree(); err != nil {
		log.Fatal(err)
	}

	rootEntry := &entry{path: "", name: "", mode: syscall.S_IFDIR | 0555, kind: kindDir}
	root := &node{snap: s, ent: rootEntry}

	server, err := fs.Mount(mountpoint, root, &fs.Options{
		MountOptions: fuse.MountOptions{
			Debug:  *debug,
			FsName: "gtm:" + filepath.Base(repo) + ":" + fullCommit[:12],
			Name:   "gtm",
		},
		OnAdd: func(ctx context.Context) {
			if err := s.populate(ctx, root); err != nil {
				panic(err)
			}
		},
	})
	if err != nil {
		log.Fatal(err)
	}

	server.Wait()
}

func validateRepo(repo string) error {
	cmd := exec.Command("git", "-C", repo, "rev-parse", "--git-dir")
	if out, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("not a git repository: %s: %w", strings.TrimSpace(string(out)), err)
	}
	return nil
}

func resolveCommit(repo, ref string) (string, error) {
	cmd := exec.Command("git", "-C", repo, "rev-parse", "--verify", ref+"^{commit}")
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("cannot resolve commit %q: %w", ref, err)
	}
	return strings.TrimSpace(string(out)), nil
}

func ensureMountpoint(path string) error {
	if err := os.MkdirAll(path, 0755); err != nil {
		return err
	}
	ents, err := os.ReadDir(path)
	if err != nil {
		return err
	}
	if len(ents) != 0 {
		return fmt.Errorf("mountpoint is not empty: %s", path)
	}
	return nil
}

func (s *snapshot) loadTree() error {
	cmd := exec.Command("git", "-C", s.repo, "ls-tree", "-r", "-t", "-l", "-z", s.commit)
	out, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("git ls-tree: %w", err)
	}

	for _, record := range bytes.Split(out, []byte{0}) {
		if len(record) == 0 {
			continue
		}
		metaPath := bytes.SplitN(record, []byte{'\t'}, 2)
		if len(metaPath) != 2 {
			return fmt.Errorf("unexpected ls-tree record %q", record)
		}
		fields := strings.Fields(string(metaPath[0]))
		if len(fields) != 4 {
			return fmt.Errorf("unexpected ls-tree metadata %q", metaPath[0])
		}
		gitMode := fields[0]
		typ := fields[1]
		oid := fields[2]
		sizeText := fields[3]
		path := string(metaPath[1])

		e := &entry{path: path, name: filepath.Base(path), oid: oid}
		switch {
		case gitMode == "040000" || typ == "tree":
			e.kind = kindDir
			e.mode = syscall.S_IFDIR | 0555
		case gitMode == "120000":
			e.kind = kindSymlink
			e.mode = syscall.S_IFLNK | 0777
		case gitMode == "160000" || typ == "commit":
			e.kind = kindGitlink
			e.mode = syscall.S_IFREG | 0444
			e.size = uint64(len(oid) + 1)
		default:
			e.kind = kindFile
			perm := uint32(0444)
			if gitMode == "100755" {
				perm = 0555
			}
			e.mode = syscall.S_IFREG | perm
			if sizeText != "-" {
				n, err := strconv.ParseUint(sizeText, 10, 64)
				if err != nil {
					return fmt.Errorf("bad size for %s: %w", path, err)
				}
				e.size = n
			}
		}
		s.entries[path] = e
	}
	return nil
}

func (s *snapshot) populate(ctx context.Context, root *node) error {
	paths := make([]string, 0, len(s.entries))
	for path := range s.entries {
		paths = append(paths, path)
	}
	sort.Slice(paths, func(i, j int) bool {
		di := strings.Count(paths[i], "/")
		dj := strings.Count(paths[j], "/")
		if di != dj {
			return di < dj
		}
		return paths[i] < paths[j]
	})

	inodeByPath := map[string]*fs.Inode{"": &root.Inode}
	var ino uint64 = 2
	for _, path := range paths {
		e := s.entries[path]
		parentPath := filepath.Dir(path)
		if parentPath == "." {
			parentPath = ""
		}
		parent := inodeByPath[parentPath]
		if parent == nil {
			return fmt.Errorf("missing parent %q for %q", parentPath, path)
		}
		n := &node{snap: s, ent: e}
		child := parent.NewPersistentInode(ctx, n, fs.StableAttr{Mode: e.mode & syscall.S_IFMT, Ino: ino})
		ino++
		parent.AddChild(e.name, child, true)
		if e.kind == kindDir {
			inodeByPath[path] = child
		}
	}
	return nil
}

func (n *node) Getattr(ctx context.Context, fh fs.FileHandle, out *fuse.AttrOut) syscall.Errno {
	out.Mode = n.ent.mode
	out.Size = n.ent.size
	return 0
}

func (n *node) Open(ctx context.Context, flags uint32) (fs.FileHandle, uint32, syscall.Errno) {
	if flags&(syscall.O_WRONLY|syscall.O_RDWR) != 0 {
		return nil, 0, syscall.EROFS
	}
	if n.ent.kind == kindDir || n.ent.kind == kindSymlink {
		return nil, 0, syscall.EISDIR
	}

	if n.ent.kind == kindGitlink {
		return &memoryHandle{data: []byte(n.ent.oid + "\n")}, fuse.FOPEN_KEEP_CACHE, 0
	}

	path, err := n.snap.materializeBlob(n.ent.oid)
	if err != nil {
		return nil, 0, syscall.EIO
	}
	f, err := os.Open(path)
	if err != nil {
		return nil, 0, errno(err)
	}
	return &fileHandle{f: f}, fuse.FOPEN_KEEP_CACHE, 0
}

func (n *node) Readlink(ctx context.Context) ([]byte, syscall.Errno) {
	if n.ent.kind != kindSymlink {
		return nil, syscall.EINVAL
	}
	cmd := exec.Command("git", "-C", n.snap.repo, "cat-file", "blob", n.ent.oid)
	out, err := cmd.Output()
	if err != nil {
		return nil, syscall.EIO
	}
	return out, 0
}

func (s *snapshot) materializeBlob(oid string) (string, error) {
	s.mu.Lock()
	if path := s.blobFiles[oid]; path != "" {
		s.mu.Unlock()
		return path, nil
	}
	s.mu.Unlock()

	tmp, err := os.CreateTemp(s.cache, oid+"-")
	if err != nil {
		return "", err
	}
	tmpName := tmp.Name()
	ok := false
	defer func() {
		tmp.Close()
		if !ok {
			os.Remove(tmpName)
		}
	}()

	cmd := exec.Command("git", "-C", s.repo, "cat-file", "blob", oid)
	cmd.Stdout = tmp
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("git cat-file %s: %s: %w", oid, strings.TrimSpace(stderr.String()), err)
	}
	if err := tmp.Close(); err != nil {
		return "", err
	}
	ok = true

	s.mu.Lock()
	defer s.mu.Unlock()
	if existing := s.blobFiles[oid]; existing != "" {
		os.Remove(tmpName)
		return existing, nil
	}
	s.blobFiles[oid] = tmpName
	return tmpName, nil
}

func (h *fileHandle) Read(ctx context.Context, dest []byte, off int64) (fuse.ReadResult, syscall.Errno) {
	n, err := h.f.ReadAt(dest, off)
	if err != nil && !errors.Is(err, io.EOF) {
		return nil, errno(err)
	}
	return fuse.ReadResultData(dest[:n]), 0
}

func (h *fileHandle) Release(ctx context.Context) syscall.Errno {
	if err := h.f.Close(); err != nil {
		return errno(err)
	}
	return 0
}

type memoryHandle struct {
	data []byte
}

var _ fs.FileReader = (*memoryHandle)(nil)

func (h *memoryHandle) Read(ctx context.Context, dest []byte, off int64) (fuse.ReadResult, syscall.Errno) {
	if off >= int64(len(h.data)) {
		return fuse.ReadResultData(nil), 0
	}
	end := off + int64(len(dest))
	if end > int64(len(h.data)) {
		end = int64(len(h.data))
	}
	return fuse.ReadResultData(h.data[off:end]), 0
}

func errno(err error) syscall.Errno {
	var pe *os.PathError
	if errors.As(err, &pe) {
		err = pe.Err
	}
	var se syscall.Errno
	if errors.As(err, &se) {
		return se
	}
	return syscall.EIO
}


```
gtm/
├── core/        shared Pascal mechanics
├── src/         CLI front end
├── gui/         Lazarus front end
├── mount/       Go/FUSE snapshot filesystem
├── bin/         generated executables/build products
├── Makefile     build orchestration
├── go.mod/sum   Go dependency metadata
└── *.txt        deliberate Git-history test artifacts
```

### `core/` — the real Pascal engine

This is increasingly the part that matters.

`gtmcore.pas` is the Git/history/filesystem plumbing. It shells out to Git and answers questions like:

```text
What commit existed at this time?
What is the GTM path for this branch?
What files existed at this commit?
What changed from predecessor → current?
What is the history of this file?
Extract this historical file.
```

Its major areas are roughly:

```text
RunGit / RunGitInteractive
        ↓
Git plumbing

ResolveCommit
CommitTime / CommitUnixTime / CommitSubject
        ↓
commit metadata

BuildTimeline
ListBranches
ListTags
FindMergeBase
BranchTip / BranchRoot
        ↓
history topology

BuildTimelineSlice
ResolveCommitAbbreviation
        ↓
timeline/window mechanics

DirectoryExistsAtCommit
ListDirectoryEntries
ListDirectoryObjects
BuildDirectoryEntryStates
ExtractFile
        ↓
historical filesystem

GetHistory
ShowDiff
ShowVisualDiff
        ↓
history/diff CLI functionality
```

`gtmstate.pas` is now the **shared session state**:

```pascal
TGTMState
```

It knows things such as:

```text
repository
selected branch
selected commit
current directory
full branch path
visible timeline slice
tags
added/modified/deleted entry state
fork / merge locations
timeline positions
commit times
```

So conceptually:

```text
gtmcore = things GTM can know/do
gtmstate = what GTM is currently looking at
```

That separation is what makes another UI practical.

`gtmexec.pas` is intentionally tiny. It owns generic external-program launches:

```text
LaunchDetached
xdg-open
meld
```

So `mainform.pas` doesn't need to construct `TProcess` objects merely to launch things.

`gtmmount.pas` is the one remaining somewhat OO bit:

```pascal
TGTMMountManager
```

It tracks the mounts GTM created and invokes:

```text
bin/gtm-mount
fusermount3
```

It owns:

```text
commit ↔ mountpoint registry
mount
unmount
unmount all
"is this commit mounted?"
```

That's probably the most obvious remaining candidate if we eventually want to purge OO from the shared layer.

---

### `src/gtm.lpr` — command-line GTM

This is just the CLI shell around `gtmcore`.

It parses:

```text
--repo
--branch
--at

ls
cat
get
history
diff
vdiff
```

For example:

```bash
gtm --repo foo --branch master --at "2026-09-01 12:00" ls src
```

becomes essentially:

```text
parse args
    ↓
ResolveCommit()
    ↓
ListDirectory()
```

There's very little GTM intelligence here. That's good.

---

### `gui/` — Lazarus presentation layer

`gtm-gui.lpr` is almost nothing:

```text
initialize Lazarus
create TMainForm
run application
```

`mainform.lfm` is the Lazarus form description: positions, sizes, menus, controls, captions, event hookups.

`mainform.pas` is still large, but it is becoming much more recognizably a **UI controller** instead of the application itself.

It currently handles things such as:

```text
button/menu callbacks
slider mouse/keyboard behavior
hold-to-accelerate navigation
painting colored file states
dialogs
tag chooser
history popup
mount-list popup
updating labels
opening files
```

There is still some GTM policy embedded there, particularly around:

```text
PopulateTags
SwitchBranch
BuildBranchTimeline
SelectCommitHash
SelectTimelineIndex
UpdateForkInfo
LoadCurrentDirectory
```

Those are probably the next interesting seam. Some of those can eventually become procedural operations on `TGTMState`.

The important distinction now is:

```text
mainform.pas
   ↓
TGTMState + gtmcore
```

rather than the old:

```text
mainform.pas = everything
```

---

### `mount/main.go` — the cool part

This is the actual read-only Git snapshot filesystem.

Invocation is essentially:

```bash
gtm-mount REPO COMMIT MOUNTPOINT
```

It first does:

```text
git ls-tree -r -t -l -z COMMIT
```

and builds an in-memory namespace representing the entire commit.

That includes:

```go
type entry struct {
    path
    name
    oid
    size
    mode
    kind
}
```

Directories, regular files, symlinks and gitlinks are represented.

Then go-fuse exposes that namespace as a real filesystem.

The particularly nice design decision is that it **does not check out every blob up front**.

Instead:

```text
mount snapshot
    ↓
read tree metadata once
    ↓
build filesystem namespace
    ↓
user opens foo.c
    ↓
git cat-file blob <oid>
    ↓
materialize blob into temporary cache
    ↓
serve it through FUSE
```

And blobs are cached thereafter.

So when you did:

```bash
cp -a /tmp/gtm-test/samples /tmp/aiki-copy/
```

ordinary Unix thought it was copying an ordinary directory tree. FUSE lazily supplied Git objects underneath it.

That's the core trick that made the project pay off.

---

### `bin/` — disposable output

Nothing here is source.

```text
gtm             Pascal CLI executable
gtm-gui         Lazarus executable
gtm-mount       Go/FUSE executable

*.o
*.ppu           FPC build products

gtmversion.inc  generated version constant
```

`gtmversion.inc` comes from:

```make
git describe --tags --always --dirty
```

So both CLI and GUI can say what exact source tree produced them.

`make clean` can kill this whole directory.

---

### `gui/lib/x86_64-linux/`

Also disposable.

This is Lazarus/FPC's private pile of:

```text
.o
.ppu
.res
.compiled
generated copy of mainform.lfm
```

It can disappear and Lazarus will rebuild it.

---

### `gui/backup/`

This is Lazarus's backup directory.

Not part of the architecture. I'd regard it as editor debris, not source-of-record.

In fact, this is one place I'd consider cleaning from Git if it is tracked.

---

### `gui/*.lpi`, `.lps`, `.res`

`gtm-gui.lpi` is the Lazarus **project definition**. Keep it.

`gtm-gui.lpr` is the Pascal program entry point. Keep it.

`mainform.pas` / `.lfm` are source. Definitely keep them.

`gtm-gui.lps` is Lazarus session/editor state. Usually personal workspace cruft rather than project source.

`gtm-gui.res` is generated resource material. Depending on Lazarus workflow it may not need to be versioned.

We could inspect Git tracking and `.gitignore` before changing anything.

---

### `Makefile`

Currently gives you four useful builds:

```bash
make
make gui
make mount
make clean
```

`make` defaults to CLI only.

There is also:

```bash
make baseline
```

which creates the handoff tarball we have been using.

It deliberately excludes:

```text
bin/
gui/lib/
*.o
*.ppu
*.compiled
```

and deliberately **includes `.git`**, because our baselines need actual repository history for GTM itself.

---

### `go.mod` / `go.sum`

Only there because `gtm-mount` uses:

```text
github.com/hanwen/go-fuse/v2
```

No Node, npm, framework pile, etc.

---

### The four top-level `.txt` files

```text
after-merge.txt
after-rejoin.txt
experiment-merged.txt
experiment-rejoin.txt
```

These aren't program data.

They're archaeological artifacts from the branch-topology tests we deliberately committed so GTM had unmistakable filesystem changes on different sides of forks and merges.

For instance:

```text
8a52398 shared point
   |
   +--- experimental commits
   |
master commits
   |
   +--- merge/rejoin
```

Those files made it easy to tell which historical snapshot/path GTM was actually presenting.

I'd **leave them**. They're tiny and now constitute useful regression-test fixtures embedded in the repository's real history.

---

## Runtime picture

Today, when you run the GUI, the pieces fit approximately like this:

```text
             ┌──────────────────┐
             │   gtm-gui.lpr    │
             └────────┬─────────┘
                      │
               ┌──────▼───────┐
               │ mainform.pas │
               │ Lazarus UI   │
               └───┬────┬─────┘
                   │    │
          ┌────────┘    └───────────┐
          ▼                         ▼
   ┌──────────────┐          ┌──────────────┐
   │  gtmstate    │          │   gtmmount   │
   │ current view │          │ mount registry│
   └──────┬───────┘          └───────┬──────┘
          │                          │
          ▼                          ▼
   ┌──────────────┐            bin/gtm-mount
   │   gtmcore    │                  │
   │ Git/history  │                  ▼
   └──────┬───────┘             go-fuse
          │                          │
          ▼                          ▼
        git                     real mounted FS
```

And `gtmexec` hangs alongside the GUI for:

```text
xdg-open
meld
```

The **big architectural achievement of the last few cuts** is that we are approaching:

```text
                  GTM mechanics
              core + state + mount
                     / \
                    /   \
              Lazarus   TUI
```

rather than having to write a TUI that secretly calls or reproduces `TMainForm`.


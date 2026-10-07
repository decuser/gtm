# Git Time Machine

A temporal filesystem browser over Git history.

## CLI

```sh
make
```

## GUI

The first Lazarus GUI cut reuses `core/gtmcore.pas`.

Build it with:

```sh
make gui
```

Then run:

```sh
./bin/gtm-gui
```

The form currently provides:

- repository path + Browse
- branch, default `master`
- time, default current local time
- Load Snapshot
- resolved commit hash
- root directory listing

This is intentionally only the first browser slice. It does not yet navigate into directories and does not use FUSE.

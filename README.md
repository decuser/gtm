# Git Time Machine (GTM)

Git Time Machine is a local Git-history browser that lets you navigate a repository **as it existed at a selected commit or time**. It combines a command-line interface, a Lazarus/Free Pascal graphical interface, a terminal interface, and a Go/FUSE snapshot mount utility.

**Status:** early development (`dev-v0.0.1`). Interfaces and behavior may change.

## What it does

- Resolve historical snapshots by branch and time.
- Browse directories and files in a selected snapshot.
- Inspect file history and compare revisions, including external visual diff support.
- Navigate commits using a timeline in the graphical interface; inspect branch and tag context.
- Mount commit snapshots as read-only filesystem views using FUSE on supported Linux systems.

See [Orientation.md](Orientation.md) for an overview of the implementation and module responsibilities.

## Build

You will need Git, Free Pascal, Lazarus (for the GUI), Go (for the mount utility), and the platform dependencies for FUSE when mounting snapshots.

```sh
make all        # GUI, TUI, and FUSE mount utility
make gui        # Lazarus GUI
make tui        # terminal interface
make mount      # Go/FUSE utility
make clean      # remove build products
```

## Run

From the project directory after building:

```sh
./bin/gtm-gui
./bin/gtm-tui
```

The CLI entry point is in `src/gtm.lpr`. It accepts repository, branch, and time selection options alongside commands such as `ls`, `cat`, `get`, `history`, `diff`, and `vdiff`; see the source for the complete current argument contract. The GUI uses Git history from a selected local repository.

Install the GUI, TUI, and mount utility into `~/.local/bin` with `make install` (or override `PREFIX`).

## Repository structure

| Path | Purpose |
|---|---|
| `core/` | Git-history operations and shared session state |
| `src/` | Command-line frontend |
| `gui/` | Lazarus GUI |
| `tui/` | Terminal frontend |
| `mount/` | Go/FUSE historical snapshot filesystem |
| `tools/` | Repository maintenance scripts |

## License

BSD 3-Clause. See [LICENSE](LICENSE).

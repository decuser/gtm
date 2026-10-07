# Git Time Machine

A temporal filesystem browser over Git history.

## Build

```sh
make
```

Defaults:
- branch: `master`
- time: current local time

## Snapshot

```sh
./bin/gtm --repo /path/to/repo
```

## List

```sh
./bin/gtm --repo /path/to/repo ls /
./bin/gtm --repo /path/to/repo ls engine/
```

## Cat

```sh
./bin/gtm --repo /path/to/repo cat README.md
```

## Get

```sh
./bin/gtm --repo /path/to/repo --at "2026-09-04 12:00" get README.md old-README.md
```

## History

```sh
./bin/gtm --repo /path/to/repo history README.md
```

## Diff

Whole snapshot:

```sh
./bin/gtm --repo /path/to/repo   diff --from "2026-09-06 17:00" --to "2026-09-07 15:00"
```

Single path:

```sh
./bin/gtm --repo /path/to/repo   diff --from "2026-09-06 17:00" --to "2026-09-07 15:00" README.md
```

## Visual diff

```sh
./bin/gtm --repo /path/to/repo   vdiff --from "2026-09-06 17:00" --to "2026-09-07 15:00" README.md
```

Optional:

```sh
--tool meld
```

## Structure

Reusable Git/time operations live in `core/gtmcore.pas`.

The CLI entry point is `src/gtm.lpr`.

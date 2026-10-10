#!/bin/sh
set -eu

ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"

if [ -n "$(git status --porcelain)" ]; then
    echo "repo-purge-binaries: working tree must be clean" >&2
    exit 1
fi

PARENT=$(dirname "$ROOT")
NAME=$(basename "$ROOT")
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="$PARENT/$NAME-before-binary-purge-$STAMP.bundle"

echo "Creating backup bundle:"
echo "  $BACKUP"
git bundle create "$BACKUP" --all

echo "Rewriting history to remove build/binary artifacts..."
FILTER_BRANCH_SQUELCH_WARNING=1 \
git filter-branch --force \
  --index-filter '
    git rm -r --cached --ignore-unmatch \
      bin gui/lib gui/backup \
      ":(glob)**/*.o" \
      ":(glob)**/*.ppu" \
      ":(glob)**/*.compiled" \
      ":(glob)**/*.res" \
      ":(glob)**/*.lps" \
      ":(glob)**/*.a" \
      ":(glob)**/*.so" \
      ":(glob)**/*.so.*" \
      ":(glob)**/*.dylib" \
      ":(glob)**/*.dll" \
      ":(glob)**/*.exe" \
      >/dev/null 2>&1 || true
  ' \
  --prune-empty \
  --tag-name-filter cat \
  -- --all

# filter-branch deliberately keeps original refs. Remove them so the old
# binary blobs can actually become unreachable.
rm -rf .git/refs/original/

git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo
echo "Verifying history..."
if git rev-list --objects --all | grep -E \
  ' (bin/|gui/lib/|gui/backup/|.*\.(o|ppu|compiled|res|lps|a|so|dylib|dll|exe)$)' \
  >/dev/null; then
    echo "repo-purge-binaries: build artifacts remain in history" >&2
    exit 1
fi

echo "No build/binary artifacts remain in reachable history."
echo "Backup bundle: $BACKUP"
du -sh .git

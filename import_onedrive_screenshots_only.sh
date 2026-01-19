#!/usr/bin/env bash
set -euo pipefail

BRANCH="${1:-archive/onedrive-snapshot}"

SRC_ALTERYX='archive/onedrive/AGA_Datathon_OneDrive/GitHub Screenshots/Alteryx screenshots'
SRC_TABLEAU='archive/onedrive/AGA_Datathon_OneDrive/GitHub Screenshots/Tableau viz screenshots'

DST_ALTERYX='docs/appendix_hubs/methodology/screenshots/alteryx'
DST_TABLEAU='docs/appendix_hubs/methodology/screenshots/tableau'

die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "==> $*"; }

# Allow ONLY these scripts to be untracked/dirty, everything else must be clean
allow_only_script_dirty() {
  local status filtered
  status="$(git status --porcelain)"
  if [ -z "$status" ]; then
    return 0
  fi

  filtered="$(echo "$status" | grep -vE '^\?\? (import_onedrive_screenshots_only\.sh|import_onedrive_snapshot_to_main\.sh|migrate_repo_layout\.sh)$' || true)"
  if [ -n "$filtered" ]; then
    echo "$status" >&2
    die "Working tree is not clean (beyond helper scripts). Commit or stash your changes first."
  fi

  info "Working tree has only untracked helper script(s). Proceeding."
}

ensure_branch_exists() {
  git rev-parse --verify --quiet "$BRANCH" >/dev/null \
    || die "Branch not found: $BRANCH. Run: git fetch --all"
}

ensure_on_main() {
  local b
  b="$(git rev-parse --abbrev-ref HEAD)"
  [ "$b" = "main" ] || die "Run this on main (current: $b)."
}

mkdirp() { mkdir -p "$1"; }

backup_if_exists() {
  local dst="$1" backup_root="$2"
  if [ -e "$dst" ]; then
    local backup_path="${backup_root}/${dst}"
    mkdirp "$(dirname "$backup_path")"
    info "Backup existing: $dst -> $backup_path"
    # Use git mv if tracked, else mv
    if git ls-files --error-unmatch "$dst" >/dev/null 2>&1; then
      git mv "$dst" "$backup_path"
    else
      mv "$dst" "$backup_path"
    fi
  fi
}

import_dir_flattened() {
  # Copies all files under $src_dir from BRANCH and moves them into $dst_dir,
  # flattening the structure (uses basename only).
  local src_dir="$1" dst_dir="$2" backup_root="$3"

  info "Scanning snapshot dir in branch: $src_dir"
  local files
  files="$(git ls-tree -r --name-only "$BRANCH" -- "$src_dir" || true)"

  if [ -z "$files" ]; then
    info "No files found under: $src_dir (in $BRANCH)."
    return 0
  fi

  mkdirp "$dst_dir"

  local count=0
  while IFS= read -r src_path; do
    [ -n "$src_path" ] || continue
    local base dst_path
    base="$(basename "$src_path")"
    dst_path="${dst_dir}/${base}"

    # Checkout file from snapshot branch into main working tree
    git checkout "$BRANCH" -- "$src_path"

    # If destination exists, back it up (never overwrite silently)
    backup_if_exists "$dst_path" "$backup_root"

    # Move into final location
    git mv "$src_path" "$dst_path"
    count=$((count + 1))
  done <<< "$files"

  info "Imported $count file(s) into: $dst_dir"
}

main() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Run inside a git repo."
  ensure_on_main
  ensure_branch_exists
  allow_only_script_dirty

  local ts backup_root
  ts="$(date +"%Y%m%d-%H%M%S")"
  backup_root="_backup/onedrive_screenshots_${ts}"

  info "Creating safety tag: pre-screenshot-import-${ts}"
  git tag "pre-screenshot-import-${ts}" >/dev/null 2>&1 || true

  info "Ensuring destination folders exist..."
  mkdirp "$DST_ALTERYX"
  mkdirp "$DST_TABLEAU"

  info "Importing screenshots from $BRANCH..."
  import_dir_flattened "$SRC_ALTERYX" "$DST_ALTERYX" "$backup_root"
  import_dir_flattened "$SRC_TABLEAU" "$DST_TABLEAU" "$backup_root"

  # Clean any leftover empty snapshot dirs that might have been created
  if [ -d "archive/onedrive/AGA_Datathon_OneDrive/GitHub Screenshots" ]; then
    rm -rf "archive/onedrive/AGA_Datathon_OneDrive/GitHub Screenshots" || true
  fi

  info "Done. Review changes:"
  git status -sb
  info "If any files were replaced, backups are in: $backup_root"
}

main "$@"


#!/bin/bash
set -euo pipefail

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
target_home="${1:-$HOME}"
target_home="$(cd "$target_home" && pwd -P)"
rc="$target_home/.zshrc"
import='source "$HOME/.config/zsh/shared.zsh"'
legacy=false

# Migrate the old Stow link, including after a pull has moved its target.
if [ -L "$rc" ]; then
  link="$(readlink "$rc")"
  case "$link" in
    /*) ;;
    *) link="$target_home/$link" ;;
  esac
  link_dir="$(cd "$(dirname "$link")" && pwd -P)"
  if [ "$link_dir/$(basename "$link")" = "$dotfiles_dir/zsh/.zshrc" ]; then
    legacy=true
  elif [ ! -e "$rc" ]; then
    echo "Cannot migrate dangling symlink: $rc" >&2
    exit 1
  fi
fi

# Keep directories real too: tools may create files beside the shared config.
stow --restow --no-folding --dir="$dotfiles_dir" --target="$target_home" zsh

if [ ! -L "$rc" ] && [ -f "$rc" ] && grep -Fqx "$import" "$rc"; then
  exit 0
fi

if [ -e "$rc" ]; then
  backup="$(mktemp "$target_home/.zshrc.backup.XXXXXX")"
  cp -L "$rc" "$backup"
  echo "Saved existing shell config to $backup"
fi

next_rc="$(mktemp "$target_home/.zshrc.XXXXXX")"
trap 'rm -f "$next_rc"' EXIT
{
  echo '# Shared config; keep installer additions and experiments in this local file.'
  echo "$import"
  if [ "$legacy" = false ] && [ -f "$rc" ]; then
    printf '\n'
    cat "$rc"
  fi
} > "$next_rc"
mv -f "$next_rc" "$rc"

#!/bin/bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title() {
  echo -e "\n${COLOR_PURPLE}$1${COLOR_NONE}"
  echo -e "${COLOR_GRAY}==============================${COLOR_NONE}\n"
}

error() {
  echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1"
  exit 1
}

warning() {
  echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"
}

info() {
  echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

success() {
  echo -e "${COLOR_GREEN}$1${COLOR_NONE}"
}

# Download fully before execution so a failed download cannot report success.
run_installer() (
  installer_shell="$1"
  installer_url="$2"
  shift 2
  installer_file="$(mktemp)"
  trap 'rm -f "$installer_file"' EXIT
  curl -fsSL "$installer_url" -o "$installer_file"
  "$installer_shell" "$installer_file" "$@"
)

install_homebrew() {
  title "Homebrew"

  if ! command -v brew &>/dev/null; then
    info "Homebrew not installed. Installing."
    run_installer /bin/bash https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    info "Homebrew is already installed. Updating..."
    brew update
  fi

  brew --version

  info "Installing brew dependencies from Brewfile"
  brew bundle --file="$DOTFILES/Brewfile"

  success "Homebrew installation complete"
}

install_vite_plus() {
  title "Vite+"
  if command -v vp >/dev/null 2>&1; then
    info "Vite+ is already installed"
  else
    VP_NODE_MANAGER=yes run_installer /bin/bash https://vite.plus
    source "$HOME/.config/vite-plus/env"
  fi
  vp --version
}

install_shell() {
  title "Shell"

  zsh_bin="$(command -v zsh)"
  if [ "${SHELL:-}" != "$zsh_bin" ]; then
    info "Setting Zsh as the default shell"
    if ! grep -Fxq "$zsh_bin" /etc/shells; then
      printf '%s\n' "$zsh_bin" | sudo tee -a /etc/shells
    fi
    chsh -s "$zsh_bin" || error "Failed to change the default shell to Zsh"
  else
    info "Zsh is already the default shell"
  fi

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh"
    run_installer /bin/sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh --unattended --keep-zshrc
  else
    info "Oh My Zsh is already installed"
  fi

  ZSH_PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

  ZSH_AUTOSUGGESTIONS_DIR="${ZSH_PLUGINS_DIR}/zsh-autosuggestions"
  if [ -d "$ZSH_AUTOSUGGESTIONS_DIR" ]; then
    info "zsh-autosuggestions already exists. Updating..."
    git -C "$ZSH_AUTOSUGGESTIONS_DIR" pull || error "Failed to update zsh-autosuggestions"
  else
    info "Installing zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_DIR" || error "Failed to install zsh-autosuggestions"
  fi

  ZSH_SYNTAX_HIGHLIGHTING_DIR="${ZSH_PLUGINS_DIR}/zsh-syntax-highlighting"
  if [ -d "$ZSH_SYNTAX_HIGHLIGHTING_DIR" ]; then
    info "zsh-syntax-highlighting already exists. Updating..."
    git -C "$ZSH_SYNTAX_HIGHLIGHTING_DIR" pull || error "Failed to update zsh-syntax-highlighting"
  else
    info "Installing zsh-syntax-highlighting"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_SYNTAX_HIGHLIGHTING_DIR" || error "Failed to install zsh-syntax-highlighting"
  fi

  bash "$DOTFILES/scripts/install-zsh.sh" || error "Failed to configure Zsh"

  warning "Please restart your terminal or run 'exec zsh' to apply changes."
  success "Shell configuration complete"
}

install_git() {
  title "Git"

  stow --restow --dir="$DOTFILES" --target="$HOME" git --verbose
  if ! git config --global --get-all include.path | grep -Fxq '~/.gitconfig.personal'; then
    git config --global --add include.path "~/.gitconfig.personal"
  fi

  success "Git configuration complete"
}

install_ghostty() {
  title "Ghostty configuration"
  stow --restow --no-folding --dir="$DOTFILES" --target="$HOME" ghostty
  success "Ghostty configuration complete"
}

main() {
  case "${1:-all}" in
  all | install)
    install_homebrew
    install_shell
    install_vite_plus
    install_git
    install_ghostty
    ;;
  brew | homebrew)
    install_homebrew
    ;;
  shell)
    install_shell
    ;;
  git)
    install_git
    ;;
  help | -h | --help)
    cat <<'EOF'
Usage: ./install.sh [all|install|brew|shell|git]
EOF
    ;;
  *)
    error "Unknown target: $1"
    ;;
  esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi

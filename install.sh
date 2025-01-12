#!/bin/bash

DOTFILES="$(pwd)"
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

install_homebrew() {
  title "Homebrew"

  if ! command -v brew &>/dev/null; then
    info "Homebrew not installed. Installing."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    info "Homebrew is already installed. Updating..."
    brew update
  fi

  brew --version

  info "Installing brew dependencies from Brewfile"
  brew bundle

  success "Homebrew installation complete"
}

install_shell() {
  title "Shell"

  if [ "$SHELL" != "$(which zsh)" ]; then
    info "Setting Zsh as the default shell"
    echo "/opt/homebrew/bin/zsh" | sudo tee -a /etc/shells
    chsh -s "$(which zsh)" || error "Failed to change the default shell to Zsh"
  else
    info "Zsh is already the default shell"
  fi

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || error "Failed to install Oh My Zsh"
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

  warning "Please restart your terminal or run 'exec $SHELL' to apply changes."
  success "Shell configuration complete"
}

install_git() {
  title "Git"

  git config --global include.path "~/.gitconfig.personal"
  stow --restow --target=$HOME git --verbose

  success "Git configuration complete"
}

main() {
  install_homebrew
  install_shell
  install_git
}

main

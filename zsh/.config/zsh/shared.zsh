export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  alias-finder
  docker
  docker-compose
  npm
  yarn
  uv
)

zstyle ':omz:plugins:alias-finder' autoload yes
zstyle ':omz:plugins:alias-finder' longer yes
zstyle ':omz:plugins:alias-finder' exact yes
zstyle ':omz:plugins:alias-finder' cheaper yes

source "$ZSH/oh-my-zsh.sh"
source "$HOME/.zsh_aliases"

# User-installed CLI tools, including `uv tool install` executables.
typeset -U path
path=("$HOME/.local/bin" $path)
export PATH

# Machine-specific settings retained from the previous layout.
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi

# Shared Vite+ setup. Load after local tools so its shims take precedence.
if [ -f "$HOME/.config/vite-plus/env" ]; then
  source "$HOME/.config/vite-plus/env"
fi

if command -v fzf >/dev/null 2>&1; then
  export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS---height=40% --layout=reverse --border}"
  if command -v fd >/dev/null 2>&1; then
    export FZF_CTRL_T_COMMAND="${FZF_CTRL_T_COMMAND-fd --type f --hidden --exclude .git}"
    export FZF_ALT_C_COMMAND="${FZF_ALT_C_COMMAND-fd --type d --hidden --exclude .git}"
  fi
  if [ -z "${FZF_CTRL_T_OPTS+x}" ] && command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 -- {}'"
  fi
  eval "$(fzf --zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

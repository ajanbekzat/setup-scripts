#!/usr/bin/env fish
# Mac setup script (fish)
# Usage: fish setup-mac.fish

set -l GREEN '\033[0;32m'
set -l YELLOW '\033[1;33m'
set -l NC '\033[0m'

function log
    echo -e "$GREEN[+]$NC $argv"
end

function warn
    echo -e "$YELLOW[!]$NC $argv"
end

# --- Homebrew ---
if not command -q brew
    log "Installing Homebrew..."
    /bin/bash -c "(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fish_add_path /opt/homebrew/bin
else
    log "Homebrew already installed"
end

# --- Core packages ---
set -l packages \
    neovim \
    tmux \
    fish \
    lazygit \
    fzf \
    ripgrep \
    fd \
    csvlens \
    chafa \
    node \
    stylua

for pkg in $packages
    if brew list $pkg &>/dev/null
        log "$pkg already installed"
    else
        log "Installing $pkg..."
        brew install $pkg
    end
end

# --- Ghostty (cask) ---
if not test -d /Applications/Ghostty.app
    log "Installing Ghostty..."
    brew install --cask ghostty
else
    log "Ghostty already installed"
end

# --- Fisher + plugins ---
if not functions -q fisher
    log "Installing Fisher..."
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher install jorgebucaran/fisher
end

set -l fish_plugin_list \
    ilancosman/tide@v6 \
    jethrokuan/z \
    patrickf1/fzf.fish

for plugin in $fish_plugin_list
    log "Installing fish plugin: $plugin"
    fisher install $plugin
end

# --- Clone configs ---
log "Setting up Neovim config..."
if test -d ~/.config/nvim
    warn "~/.config/nvim already exists, skipping clone"
else
    git clone https://github.com/ajanbekzat/nvim.git ~/.config/nvim
    rm -f ~/.config/nvim/lazy-lock.json
end

log "Setting up tmux config..."
if test -d ~/.config/tmux
    warn "~/.config/tmux already exists, skipping clone"
else
    git clone https://github.com/ajanbekzat/tmux.git ~/.config/tmux
end

# --- tmux plugins (TPM + resurrect / continuum / pain-control) ---
# TPM must be cloned and plugins installed, otherwise session resurrect won't work.
if not test -d ~/.config/tmux/plugins/tpm
    log "Installing tmux plugin manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
else
    log "TPM already installed"
end
log "Installing tmux plugins..."
# install_plugins reads @plugin from tmux.conf and clones into TMUX_PLUGIN_MANAGER_PATH
env TMUX_PLUGIN_MANAGER_PATH="$HOME/.config/tmux/plugins/" ~/.config/tmux/plugins/tpm/bin/install_plugins

# --- Ghostty config ---
log "Setting up Ghostty config..."
mkdir -p ~/.config/ghostty
if not test -f ~/.config/ghostty/config
    cat >~/.config/ghostty/config <<'GHOSTTY'
theme = light:iTerm2 Solarized Light,dark:Solarized Dark Patched

clipboard-read = allow
clipboard-write = allow

background-opacity = 0.9
background-blur-radius = 20

font-family = PlemolJP Console NF

cursor-style = block
cursor-style-blink = true

window-theme = auto
macos-option-as-alt = left
keybind = alt+left=unbind
keybind = alt+right=unbind
GHOSTTY
else
    warn "Ghostty config already exists, skipping"
end

# --- Claude Code global config (skills + CLAUDE.md + settings) ---
# Private repo; needs an SSH key on GitHub. install.sh is idempotent + non-destructive.
log "Setting up Claude Code config..."
if test -d ~/.claude-config
    warn "~/.claude-config already exists, pulling latest"
    git -C ~/.claude-config pull --ff-only; or warn "claude-config pull failed; skipping update"
else
    git clone git@github.com:ajanbekzat/claude-config.git ~/.claude-config
end
bash ~/.claude-config/install.sh

# --- Fish aliases & config ---
log "Setting up fish aliases..."
set -l fish_config ~/.config/fish/config.fish

# Only append if not already configured
if not grep -q 'alias icat' $fish_config 2>/dev/null
    cat >>$fish_config <<'FISH'

# --- Tool aliases ---
alias icat 'chafa --format=kitty'
alias vi 'nvim'
alias t 'tmux a || tmux'
alias tt 'tmux attach'
alias tto 'tmux detach'
alias lg 'lazygit'
alias pip 'pip3'
alias python 'python3'

# --- PATH ---
fish_add_path $HOME/.local/bin
FISH
    log "Aliases added to config.fish"
else
    warn "Aliases already in config.fish, skipping"
end

# --- Reminders ---
echo ""
log "Setup complete!"
echo ""
warn "Don't forget to:"
echo "  1. Set your API keys (DO NOT put them in config files):"
echo "     set -Ux ANTHROPIC_API_KEY 'your-key-here'"
echo "  2. Launch nvim to let lazy.nvim install plugins"
echo "  3. Install the PlemolJP Console NF font if not already installed"
echo "  4. Restart your terminal / run: source ~/.config/fish/config.fish"

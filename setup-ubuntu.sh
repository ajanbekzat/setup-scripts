#!/usr/bin/env bash
# Ubuntu setup script
# Usage: bash setup-ubuntu.sh

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }

# --- System packages ---
log "Updating apt..."
sudo apt update -y

log "Installing base packages..."
sudo apt install -y \
    git \
    curl \
    wget \
    unzip \
    build-essential \
    g++ \
    npm \
    ripgrep \
    fd-find \
    fzf \
    chafa \
    libevent-dev \
    ncurses-dev \
    bison \
    pkg-config

# --- tmux 3.5a (build from source, apt version is too old for OSC 52 passthrough) ---
TMUX_REQUIRED="3.5a"
if command -v tmux &>/dev/null && [[ "$(tmux -V)" == *"$TMUX_REQUIRED"* ]]; then
    log "tmux $TMUX_REQUIRED already installed"
else
    # Remove old apt version if present
    sudo apt remove -y tmux 2>/dev/null || true
    log "Building tmux $TMUX_REQUIRED from source..."
    cd /tmp
    curl -LO "https://github.com/tmux/tmux/releases/download/${TMUX_REQUIRED}/tmux-${TMUX_REQUIRED}.tar.gz"
    tar xzf "tmux-${TMUX_REQUIRED}.tar.gz"
    cd "tmux-${TMUX_REQUIRED}"
    ./configure && make
    sudo make install
    cd /tmp
    rm -rf "tmux-${TMUX_REQUIRED}" "tmux-${TMUX_REQUIRED}.tar.gz"
    hash -r
    log "tmux installed: $(tmux -V)"
fi

# --- Neovim (AppImage, avoids snap issues) ---
if ! command -v nvim &>/dev/null; then
    log "Installing Neovim (AppImage)..."
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
    chmod u+x nvim-linux-x86_64.appimage
    sudo mv nvim-linux-x86_64.appimage /usr/local/bin/nvim
else
    log "Neovim already installed: $(nvim --version | head -1)"
fi

# --- lazygit ---
if ! command -v lazygit &>/dev/null; then
    log "Installing lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm -f lazygit lazygit.tar.gz
else
    log "lazygit already installed"
fi

# --- csvlens ---
if ! command -v csvlens &>/dev/null; then
    log "Installing csvlens..."
    CSVLENS_VERSION=$(curl -s "https://api.github.com/repos/YS-L/csvlens/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
    curl -Lo csvlens.tar.xz "https://github.com/YS-L/csvlens/releases/download/${CSVLENS_VERSION}/csvlens-x86_64-unknown-linux-gnu.tar.xz"
    tar xf csvlens.tar.xz
    sudo mv csvlens-x86_64-unknown-linux-gnu/csvlens /usr/local/bin/
    rm -rf csvlens.tar.xz csvlens-x86_64-unknown-linux-gnu
else
    log "csvlens already installed"
fi

# --- nvm + node ---
if [ ! -d "$HOME/.nvm" ]; then
    log "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
else
    log "nvm already installed"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# --- tree-sitter-cli (needs nvm node, not system node) ---
if ! command -v tree-sitter &>/dev/null; then
    log "Installing tree-sitter-cli..."
    npm install -g tree-sitter-cli || {
        warn "npm install failed, trying older version..."
        npm install -g tree-sitter-cli@0.24.7
    }
else
    log "tree-sitter-cli already installed"
fi

# --- Oh My Bash ---
if [ ! -d "$HOME/.oh-my-bash" ]; then
    log "Installing Oh My Bash..."
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
else
    log "Oh My Bash already installed"
fi

# --- Clone configs ---
log "Setting up Neovim config..."
if [ -d ~/.config/nvim ]; then
    warn "~/.config/nvim already exists, skipping clone"
else
    git clone git@github.com:ajanbekzat/nvim.git ~/.config/nvim
    rm -f ~/.config/nvim/lazy-lock.json
fi

log "Setting up tmux config..."
if [ -d ~/.config/tmux ]; then
    warn "~/.config/tmux already exists, skipping clone"
else
    git clone git@github.com:ajanbekzat/tmux.git ~/.config/tmux
fi

# --- tmux plugins (TPM + resurrect / continuum / pain-control) ---
# TPM must be cloned and plugins installed, otherwise session resurrect won't work.
if [ ! -d ~/.config/tmux/plugins/tpm ]; then
    log "Installing tmux plugin manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
else
    log "TPM already installed"
fi
log "Installing tmux plugins..."
# install_plugins reads @plugin from tmux.conf and clones into TMUX_PLUGIN_MANAGER_PATH
TMUX_PLUGIN_MANAGER_PATH="$HOME/.config/tmux/plugins/" \
    ~/.config/tmux/plugins/tpm/bin/install_plugins \
    || warn "tmux plugin install failed; inside tmux press prefix + I to retry"

# --- Claude Code global config (skills + CLAUDE.md + settings) ---
# Private repo; needs an SSH key on GitHub. install.sh is idempotent + non-destructive.
log "Setting up Claude Code config..."
if [ -d ~/.claude-config ]; then
    warn "~/.claude-config already exists, pulling latest"
    git -C ~/.claude-config pull --ff-only || warn "claude-config pull failed; skipping update"
else
    git clone git@github.com:ajanbekzat/claude-config.git ~/.claude-config
fi
bash ~/.claude-config/install.sh

# --- Bashrc aliases ---
log "Setting up bash aliases..."
if ! grep -q 'alias lg=' ~/.bashrc 2>/dev/null; then
    cat >>~/.bashrc <<'BASHRC'

# --- Tool aliases ---
alias vi='nvim'
alias lll='ls -lhF --color=auto'
alias tt='tmux a'
alias tto='tmux detach'
alias lg='lazygit'
alias python='python3'
alias pip='pip3'
alias srcbash='source ~/.bashrc'
alias icat='chafa image.png'

export PATH="$HOME/.local/bin:$PATH"
BASHRC
    log "Aliases added to .bashrc"
else
    warn "Aliases already in .bashrc, skipping"
fi

# --- Reminders ---
echo ""
log "Setup complete!"
echo ""
warn "Don't forget to:"
echo "  1. Set your API keys in a SEPARATE file (not .bashrc!):"
echo "     echo 'export ANTHROPIC_API_KEY=your-key' >> ~/.secrets"
echo "     echo 'source ~/.secrets' >> ~/.bashrc"
echo "     chmod 600 ~/.secrets"
echo "  2. Launch nvim to let lazy.nvim install plugins"
echo "  3. Restart your shell: source ~/.bashrc"
echo "  4. For chafa kitty protocol over SSH, ensure chafa >= 1.14"
echo "     Check with: chafa --version"

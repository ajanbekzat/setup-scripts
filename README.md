# Setup Scripts

Automated setup scripts for my development environment on macOS and Ubuntu.

## What's Included

| Tool | macOS | Ubuntu | Purpose |
|---|---|---|---|
| Neovim | Homebrew | AppImage | Editor ([config](https://github.com/ajanbekzat/nvim)) |
| tmux | Homebrew | apt | Terminal multiplexer ([config](https://github.com/ajanbekzat/tmux)) |
| Ghostty | Homebrew Cask | - | Terminal emulator |
| Fish shell | Homebrew | - | Shell + Fisher, Tide, z, fzf.fish |
| Oh My Bash | - | installer | Bash framework (agnoster theme) |
| lazygit | Homebrew | binary | Git TUI |
| fzf | Homebrew | apt | Fuzzy finder |
| ripgrep | Homebrew | apt | Fast search |
| fd | Homebrew | apt | Fast find |
| csvlens | Homebrew | binary | CSV viewer TUI |
| chafa | Homebrew | apt | Terminal image viewer (Kitty protocol) |
| stylua | Homebrew | - | Lua formatter |
| nvm + Node | Homebrew (node) | nvm | JS runtime |
| tree-sitter-cli | - | npm | Treesitter parser builds |

## Usage

### macOS (fresh machine)

```bash
git clone https://github.com/ajanbekzat/setup-scripts.git
cd setup-scripts
fish setup-mac.fish
```

### Ubuntu (fresh machine or remote server)

```bash
git clone https://github.com/ajanbekzat/setup-scripts.git
cd setup-scripts
bash setup-ubuntu.sh
```

Both scripts are idempotent — safe to run multiple times. Already-installed tools are skipped.

## Configs Cloned

The scripts automatically clone these configs into `~/.config/`:

- **Neovim** — [ajanbekzat/nvim](https://github.com/ajanbekzat/nvim) → `~/.config/nvim`
- **tmux** — [ajanbekzat/tmux](https://github.com/ajanbekzat/tmux) → `~/.config/tmux`
- **Ghostty** — created inline by the macOS script → `~/.config/ghostty`

After cloning the tmux config, both scripts install [TPM](https://github.com/tmux-plugins/tpm) and its
plugins (resurrect, continuum, pain-control) into `~/.config/tmux/plugins/`, so tmux session
save/restore (`prefix + Ctrl-s` / `prefix + Ctrl-r`, plus auto-restore on reboot) works out of the box.

## Claude Code Config

Both scripts also clone my global [Claude Code](https://claude.com/claude-code) setup from the private
[ajanbekzat/claude-config](https://github.com/ajanbekzat/claude-config) repo into `~/.claude-config`, then run
its `install.sh` to place skills, `CLAUDE.md` (i-have-adhd output style + about-me), `settings.json`, and the
custom statusline into `~/.claude/`. The installer is **idempotent and non-destructive** — existing files are kept.

Set up **just the skills that are missing** (standalone, run anytime):

```bash
bash ~/.claude-config/install.sh --skills-only
```

Note: `claude-config` is private, so the clone uses SSH — add an SSH key to GitHub first.

## Shell Aliases

Both scripts set up these aliases:

```
vi    → nvim
lg    → lazygit
tt    → tmux attach
tto   → tmux detach
icat  → chafa --format=kitty  (macOS only, for inline images)
```

## API Keys

**Never store API keys in shell config files.** After running the setup:

macOS (fish):
```fish
set -Ux ANTHROPIC_API_KEY 'your-key-here'
```

Ubuntu (bash):
```bash
echo 'export ANTHROPIC_API_KEY=your-key' >> ~/.secrets
echo 'source ~/.secrets' >> ~/.bashrc
chmod 600 ~/.secrets
```

## Font

The Ghostty config uses **PlemolJP Console NF**. Install it separately if not already available.

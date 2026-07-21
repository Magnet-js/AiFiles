# Getting Started & Hotkeys

A guide to bootstrapping this configuration and navigating every tool it configures.

---

## Getting started

### Prerequisites

- Apple Silicon Mac (default).  Intel Mac: change one line in [`configuration.nix`](configuration.nix) — set `nixpkgs.hostPlatform = "x86_64-darwin";`.

### First-time bootstrap

```sh
git clone https://github.com/Magnet-js/AiFiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

[`bootstrap.sh`](bootstrap.sh) does five things in order:

1. Installs Determinate Nix if it isn't already there.
2. Symlinks the repo to `~/.dotfiles` (required before the first build because [`home.nix`](home.nix) resolves config paths through `~/.dotfiles`).
3. Checks the `user` configured in [`flake.nix`](flake.nix) against your macOS username and offers to fix it if they differ.
4. Generates an `ed25519` SSH key at `~/.ssh/id_ed25519` (if missing), adds it to `ssh-agent`, and prints the public key so you can add it to GitHub.
5. Runs the first `darwin-rebuild switch` — fetching `darwin-rebuild` from the nix-darwin 26.05 release branch and applying this repo's locked [`flake.nix`](flake.nix).

### Personalise before running

| What | Where | Default |
|------|-------|---------|
| macOS username | `user = "…"` in [`flake.nix`](flake.nix) | `kunchen` |
| Host label | `"mac"` in [`flake.nix`](flake.nix), [`rebuild.sh`](rebuild.sh) line 5, and [`bootstrap.sh`](bootstrap.sh) | `mac` |
| CPU architecture | `nixpkgs.hostPlatform` in [`configuration.nix`](configuration.nix) | `aarch64-darwin` |

> **Homebrew cleanup warning** — [`configuration.nix`](configuration.nix) sets `homebrew.onActivation.cleanup = "zap"`.  Every rebuild removes any Homebrew package **not** listed in `brews`/`casks`.  Add anything you want to keep before the first switch.

### Rebuilding after a change

```sh
./rebuild.sh
```

[`rebuild.sh`](rebuild.sh) re-symlinks the repo to `~/.dotfiles` and runs `darwin-rebuild switch`.  You only need to rebuild when changing something outside the symlinked config files (e.g. package lists, system defaults).  Changes to files under `home/` (NeoVim, WezTerm …) take effect immediately — no rebuild required.

### Validate without applying

```sh
nix flake check --no-build
nix build .#darwinConfigurations.mac.system --dry-run
```

---

## NeoVim

Config lives in [`home/.config/nvim/`](home/.config/nvim/).

### Modes (built-in)

| Mode | Enter | Exit |
|------|-------|------|
| Normal | `<Esc>` from any mode | — |
| Insert | `i` (before cursor) · `a` (after) · `o` (new line below) · `O` (new line above) | `<Esc>` |
| Visual | `v` (char) · `V` (line) · `<C-v>` (block) | `<Esc>` |
| Command | `:` | `<Esc>` · `<Enter>` |

### Leader key

`<Space>` — set in [`lua/vim_config.lua`](home/.config/nvim/lua/vim_config.lua).

Press `<Space>` in Normal mode to open the **which-key** popup listing all available leader mappings.

### Custom keymaps

Defined in [`lua/keys.lua`](home/.config/nvim/lua/keys.lua).

| Key | Mode | Action |
|-----|------|--------|
| `<Esc>` | Normal | Save the current file (`:w`) |
| `<C-a>` | Normal | Select all (`ggVG`) |
| `p` | Visual | Paste without overwriting the clipboard register |

### Plugin keybindings

#### Navigation — [oil.nvim](https://github.com/stevearc/oil.nvim) · [snacks.nvim](https://github.com/folke/snacks.nvim)

Defined in [`lua/plugins/navigation.lua`](home/.config/nvim/lua/plugins/navigation.lua).

| Key | Action |
|-----|--------|
| `<leader>e` | Open file browser (oil.nvim) |
| `<leader>f` | Fuzzy-find files |
| `<leader>s` | Grep / search text in project |
| `<leader>b` | Switch between open buffers |
| `gd` | Go to definition (LSP via snacks picker) |

Inside a **snacks picker** popup:

| Key | Action |
|-----|--------|
| `<Enter>` | Open selected item |
| `<Esc>` | Close picker |
| `<C-j>` / `<C-k>` | Move down / up |
| Type | Filter results live |

Inside the **oil.nvim** file browser:

| Key | Action |
|-----|--------|
| `<Enter>` | Open file or directory |
| `-` | Go up one directory |
| `<C-s>` | Save pending edits (rename/delete/create) |
| `g.` | Toggle hidden files |

#### UI — [which-key.nvim](https://github.com/folke/which-key.nvim)

Defined in [`lua/plugins/ui.lua`](home/.config/nvim/lua/plugins/ui.lua).

| Key | Action |
|-----|--------|
| `<Space>` (hold) | Show leader-key hint popup |
| `<Esc>` | Dismiss popup |

#### Git — [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)

Defined in [`lua/plugins/git.lua`](home/.config/nvim/lua/plugins/git.lua).

The plugin is loaded on `BufWinEnter` with `current_line_blame = true` — it shows who last touched the current line as virtual text.  No custom keys are mapped; gitsigns default keys are available:

| Key | Action |
|-----|--------|
| `]c` | Next hunk |
| `[c` | Previous hunk |
| `<leader>hs` | Stage hunk |
| `<leader>hu` | Undo stage hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | Full blame for line |

### Essential built-in navigation

| Key | Action |
|-----|--------|
| `h` `j` `k` `l` | Left · Down · Up · Right |
| `w` / `b` | Next / previous word |
| `0` / `^` / `$` | Line start (col 0) · first non-blank · end |
| `gg` / `G` | File start / end |
| `{` / `}` | Previous / next blank-line paragraph |
| `<C-d>` / `<C-u>` | Half-page down / up |
| `zz` | Centre cursor line |
| `/pattern` | Search forward (`n` next · `N` prev) |
| `*` | Search word under cursor |
| `ciw` | Change inner word |
| `di"` | Delete inside quotes |
| `yy` / `p` | Yank line / paste |
| `u` / `<C-r>` | Undo / redo |
| `<C-w>s` / `<C-w>v` | Split horizontal / vertical |
| `<C-w>h/j/k/l` | Move between splits |
| `gt` / `gT` | Next / previous tab |

---

## WezTerm

Config lives in [`home/.config/wezterm/wezterm.lua`](home/.config/wezterm/wezterm.lua).

No custom keybindings are defined — the config only sets visual options (color scheme, font, opacity, blur, window decoration).  The table below covers the most useful **WezTerm defaults** on macOS.

### Tabs

| Key | Action |
|-----|--------|
| `⌘ T` | New tab |
| `⌘ W` | Close tab |
| `⌘ 1–9` | Jump to tab by number |
| `⌘ [` / `⌘ ]` | Previous / next tab |
| `Ctrl-Shift-Tab` / `Ctrl-Tab` | Previous / next tab (keyboard-only) |

### Panes

| Key | Action |
|-----|--------|
| `⌘ D` | Split pane horizontally |
| `⌘ Shift-D` | Split pane vertically |
| `⌘ ←/→/↑/↓` | Move focus between panes |
| `Ctrl-Shift-Z` | Zoom / un-zoom current pane |
| `⌘ W` | Close current pane (or tab if only one pane) |

### Copy mode

| Key | Action |
|-----|--------|
| `Ctrl-Shift-X` | Enter copy mode |
| `h/j/k/l` | Move cursor |
| `v` | Start selection |
| `y` | Copy selection and exit |
| `q` / `Esc` | Exit copy mode |

### General

| Key | Action |
|-----|--------|
| `⌘ +` / `⌘ -` | Increase / decrease font size |
| `⌘ 0` | Reset font size |
| `⌘ F` | Find / search in scrollback |
| `⌘ K` | Clear scrollback |
| `Ctrl-Shift-L` | Open debug overlay |

---

## Shell (zsh)

Config lives in [`home.nix`](home.nix).

### Keybinding

| Key | Action |
|-----|--------|
| `Ctrl-F` | Accept the ghost-text autosuggestion in full |

### Aliases

| Alias | Expands to |
|-------|-----------|
| `..` | `cd ..` |
| `add` | `git add .` |
| `push` | `git push` |
| `pull` | `git pull` |
| `m` | `git switch main` |
| `cc` | `claude --dangerously-skip-permissions` |
| `co` | `codex --full-auto` |

> **`cc` and `co` are high-agency shortcuts.** Know what they do before you use them.

---

## lazygit

`lazygit` is installed via Nix ([`home.nix`](home.nix)).  No custom config is included in this repo; all bindings are lazygit's built-in defaults.

| Key | Action |
|-----|--------|
| `↑↓` / `j k` | Navigate list |
| `Space` | Stage / unstage file or hunk |
| `c` | Commit (opens message prompt) |
| `P` | Push |
| `p` | Pull |
| `b` | Branch panel |
| `l` | Log / commit history |
| `?` | Show all keybindings |
| `q` | Quit |

---

## fzf

`fzf` is installed via Nix ([`home.nix`](home.nix)).  No custom config is included; all bindings are fzf defaults.

| Key | Action |
|-----|--------|
| Type | Filter results |
| `↑↓` / `Ctrl-K/J` | Move up / down |
| `Enter` | Confirm selection |
| `Tab` | Multi-select toggle |
| `Ctrl-C` / `Esc` | Cancel |

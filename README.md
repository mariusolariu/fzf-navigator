# fzf-navigator

`fzf-navigator` is an interactive file system navigator that uses [fzf](https://github.com/junegunn/fzf). It provides a speedy alternative to `cd` + `ls` with previews, toggles, history navigation and contextual command-line insertion.

![](fzf-navigator.png)

## Installation

Download `fzf-navigator.sh` and source it in your shell rc file.

Example:

```bash
curl -o ~/.config/fzf-navigator.sh https://raw.githubusercontent.com/benward2301/fzf-navigator/main/fzf-navigator.sh
echo 'source ~/.config/fzf-navigator.sh' >> ~/.${SHELL##*/}rc
```

### Dependencies

- [fzf](https://github.com/junegunn/fzf) ≥ 0.45.0
- [eza](https://github.com/eza-community/eza) - Optional (required for icons), falls back to ls
- [bat](https://github.com/sharkdp/bat) - Optional (required for colorized file previews), falls back to cat

## Usage

Press `ctrl-space` (default) to open the navigator.

### Bindings

| Key | Action | Description |
|-----|--------|-------------|
| `enter` | `open` | Enter directory / edit file |
| `ctrl-o` | `open_and_exit` | Enter directory / edit file and exit navigator |
| `space` | `exit` | Exit navigator (cd to current directory if locked) |
| `ctrl-v` | `insert_selection` | Insert relative path(s) at cursor |
| `ctrl-c` | `copy_selection` | Copy absolute path(s) to clipboard, one per line, and stay open |
| `esc` | `cancel` | Exit, or reset path if locked |
| `bspace`, `ctrl-bspace` | `go_to_parent` | Go to parent directory (deletes a character instead while the query is not empty) |
| `alt-b`, `alt-left` | `go_back` | Go back in history |
| `alt-f`, `alt-right` | `go_forward` | Go forward in history |
| `alt-s` | `go_to_session_start` | Go to session start |
| `alt-~` | `go_home` | Go to home |
| `alt-/` | `go_to_root` | Go to root |
| `ctrl-l` | `toggle_locked` | Toggle locked mode (navigation doesn't change shell CWD) |
| `alt-h` | `toggle_hidden_files` | Toggle hidden files |
| `ctrl-g` | `toggle_file_details` | Toggle file details (`-l`) |
| `ctrl-r` | `toggle_recent_first` | Toggle recent-first sort |
| `?` | `toggle_help` | Toggle help |

`alt-*` keys need the terminal's Option key to send Esc+ (iTerm2: Profiles → Keys → Left Option key → Esc+).
With iTerm2's "Natural Text Editing" preset, Option+←/→ arrive as `alt-b`/`alt-f`, which is why both are bound.
`ctrl-bspace` is indistinguishable from `ctrl-h` in most macOS terminals.

## Tests

```bash
brew install bats-core   # or your package manager
bats test/
```

## Configuration

| Variable | Description |
|----------|-------------|
| `FZF_NAVIGATOR_KEY` | Keybinding to launch navigator (default: `ctrl-space`) |
| `FZF_NAVIGATOR_SHOW_HIDDEN` | Show hidden files by default if set |
| `FZF_NAVIGATOR_LOCK_CWD` | Start in locked mode if set (navigation doesn't change shell CWD) |
| `FZF_NAVIGATOR_HIDE_HELP` | Hide the "? for help" hint if set |
| `FZF_NAVIGATOR_LS_FORMAT` | Comma-separated: `icons`, `color`, `classify`, or `plain` (default: `icons,color`) |
| `FZF_NAVIGATOR_BINDINGS` | Custom keybindings: `"key:action,key:action,..."` |
| `FZF_NAVIGATOR_OPTIONS` | Additional fzf options |
| `FZF_NAVIGATOR_FILE_PREVIEW_COMMAND` | Custom file preview command (receives path as `$1`) |
| `FZF_NAVIGATOR_DIR_PREVIEW_COMMAND` | Custom directory preview command (receives path as `$1`) |

## Compatibility

- **Shells**: zsh, bash ≥ 5.0
- **Platforms**: Linux, macOS
- **ls variants**: eza, GNU ls, BSD ls

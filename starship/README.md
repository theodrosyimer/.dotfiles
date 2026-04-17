# Starship

Two configs:

| file | used by |
|---|---|
| `starship.toml` | interactive shell prompt |
| `starship-claude.toml` | Claude Code statusline (`~/.dotfiles/claude/scripts/statusline.sh`) |

## Why a Claude-specific variant

Claude Code allocates a **fixed-width pty (~147 cols)** to the statusline process, regardless of the real terminal width. The main config uses `$fill` to right-align the language-version modules; inside the Claude statusline that fill stops at col 147, leaving a dead gap mid-line on wider terminals and wrapping/clipping on narrower ones.

`starship-claude.toml` drops:

- `$fill` — nothing to right-align against.
- `$character` — shell prompt arrow, meaningless in a statusline.
- `$cmd_duration`, `$time` — no command context.

Everything else (palette, directory, git, nodejs/python/rust/golang, jobs) is kept verbatim so the two prompts stay visually consistent.

## Maintenance

When updating `starship.toml`, the Claude variant usually wants the same change. The safe way to refresh it:

```bash
cat ~/.dotfiles/starship/starship.toml > ~/.dotfiles/starship/starship-claude.toml
# then re-apply the format-block patch (drop $fill/$character/$cmd_duration/$time)
```

### The Nerd Font glyph trap

`[git_branch].symbol`, `[nodejs].symbol`, `[python].symbol` etc. contain **non-ASCII Nerd Font glyphs** (3-byte UTF-8 sequences like `ef 90 98` for ). If those bytes are replaced with plain ASCII spaces, the icons silently disappear from the prompt.

**Safe — byte-preserving:**

| method | notes |
|---|---|
| `cat src > dest` | raw byte stream copy. The method used above. |
| `cp src dest` | fine, but watch for `cp -i` aliases prompting interactively. |
| `sed -i 's/OLD/NEW/' file` | preserves every byte it doesn't match. |
| Editing in VS Code / Neovim / any real UTF-8 editor | edits in place, untouched bytes stay intact. |
| `git checkout`, `git restore`, `rsync` | byte-exact. |
| `python3` / `jq` reading + writing the file | UTF-8 safe by default on modern installs. |

**Unsafe — can silently strip glyphs:**

| method | why |
|---|---|
| LLM/AI tools that write the full file from a prompt | the model may transcribe glyphs as plain spaces if it doesn't know to emit the raw bytes. ← this is how we broke it. |
| Pasting via the clipboard through apps that normalize Unicode | some terminals/clipboards replace uncommon glyphs with `?` or drop them. |
| `echo`/`printf` with a non-UTF-8 `LANG`/`LC_ALL` | non-ASCII bytes may be mangled. |
| Retyping the glyph from memory | unless you paste from a Nerd Font cheatsheet, you'll miss. |

### Verifying glyphs survived

```bash
# Should see byte sequences starting with ee/ef for each module symbol.
rg '^symbol' starship-claude.toml | xxd | head
```

If the bytes after `"` are only `20` (space), the glyphs were stripped — restore from `starship.toml`.

## Related

- `~/.dotfiles/claude/scripts/statusline.sh` — caller for the Claude variant. Documents the pty-width gotcha at the call site.

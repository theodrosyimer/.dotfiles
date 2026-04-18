# Setting up a new Mac

## Fast path (automated)

```bash
curl -fsSL https://raw.githubusercontent.com/theodrosyimer/dotfiles/main/bootstrap.sh -o /tmp/bootstrap.sh
bash /tmp/bootstrap.sh
```

`bootstrap.sh` runs all 14 steps below in order, idempotently (safe to
re-run after failures). It will pause at 4 points that require you to act:

1. Install + sign in to 1Password desktop, enable SSH agent + CLI integration
2. Accept the Xcode Command Line Tools license dialog
3. `gh auth login` browser OAuth
4. `op signin` biometric / master password

Between those, it runs unattended.

<details>
<summary><strong>Manual path (reference / fallback)</strong></summary>

Use these steps if you want to run the flow by hand, or if you're debugging
a specific step of `bootstrap.sh`.

1. **Install 1Password desktop** — App Store, or direct from
   [downloads.1password.com](https://downloads.1password.com). Sign in. Settings
   → Developer → enable **Use the SSH agent** and **Integrate with 1Password
   CLI**.

2. **Command Line Tools** (provides `git`, `clang`):

   ```bash
   xcode-select --install
   ```

3. **Homebrew**:

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

4. **Just enough to clone** (full Brewfile comes later):

   ```bash
   brew install gh
   ```

5. **Authenticate `gh`** (browser OAuth, ~10 seconds):

   ```bash
   gh auth login
   ```

6. **Clone dotfiles over HTTPS** (no SSH needed yet):

   ```bash
   gh repo clone theodrosyimer/dotfiles ~/.dotfiles
   ```

7. **Symlink all dotfiles** into their canonical locations (`$HOME`,
    `~/.config`, `~/Library/KeyBindings`) via git-tracked files only —
    sets up `.zshenv`, `.zshrc`, nvim, ghostty, karabiner, etc. in one
    shot. Does NOT touch `~/.claude` (that's step 10).

    ```bash
    ~/.dotfiles/bootstrap/symlink.sh
    exec zsh   # load .zshenv → $HOMEBREW_BUNDLE_FILE_GLOBAL + $ZSH_CUSTOM
    ```

8. **Install oh-my-zsh + external custom plugins** (must run before any
    interactive zsh — `~/.zshrc` sources `$ZSH/oh-my-zsh.sh` and expects
    `$ZSH_CUSTOM/plugins/*` to exist):

    ```bash
    ~/.dotfiles/bootstrap/omz.sh
    ```

9. **Install everything from the Brewfile** (pulls `jq`, `1password-cli`,
    and the rest):

    ```bash
    brew bundle --global
    ```

10. **Sync `~/.claude`** — depth-2 per-item symlinks inside `skills/`,
    `hooks/`, `rules/`, plus file-level links for `CLAUDE.md` and
    `settings.json`. Uses the `ccsync` zsh function (loaded via
    `zsh/custom/agents.zsh` after step 7's `exec zsh`):

    ```bash
    ccsync
    ```

11. **Sign in to the 1Password CLI**:

    ```bash
    eval "$(op signin)"
    ```

12. **Materialise `~/.ssh`** from 1Password (config + all `*.pub` files):

    ```bash
    ~/.dotfiles/bootstrap/ssh.sh
    ```

    Verify:

    ```bash
    ssh -v vps 'echo ok' 2>&1 | grep -E 'Offering public key|Authenticated to'
    ```

13. **Materialise per-user secret files** (`~/.npmrc`, future
    `~/.aws/credentials`, etc.) from 1Password documents:

    ```bash
    ~/.dotfiles/bootstrap/secrets.sh
    ```

14. **Switch the dotfiles remote from HTTPS to SSH** (mandatory — so future
    `git push` from this repo uses the 1Password agent, not the `gh` HTTPS
    creds):
    ```bash
    git -C ~/.dotfiles remote set-url origin \
        git@github.com:theodrosyimer/dotfiles.git
    git -C ~/.dotfiles fetch    # sanity check
    ```

</details>

## Prerequisites in 1Password (verify once from a working machine)

- **Vaults** named `Dev Perso` and `Pro` (or whatever `VAULTS=()` in
  `bootstrap/ssh.sh` lists).
- **SSH Key items** in those vaults, titled so that the slug rule (lowercase,
  `" - "` → `"_"`) produces the filename that `~/.ssh/config` references.
- **Document** titled `ssh config` in `Dev Perso`, content is the full
  `~/.ssh/config`. Create with:
  ```bash
  op document create ~/.ssh/config --title "ssh config" --vault "Dev Perso"
  ```
  Update after local edits:
  ```bash
  op document edit "ssh config" --vault "Dev Perso" ~/.ssh/config
  ```
- **One Document per entry** in the `SECRETS` table of
  `bootstrap/secrets.sh`. Currently:
  - `npmrc` in `Dev Perso` → body of `~/.dotfiles/npm/.npmrc`
    (`~/.npmrc` is a symlink, created by the script after fetch)

  Create from current machine:
  ```bash
  op document create ~/.dotfiles/npm/.npmrc --title "npmrc" --vault "Dev Perso"
  ```
  Update after local edits:
  ```bash
  op document edit "npmrc" --vault "Dev Perso" ~/.dotfiles/npm/.npmrc
  ```


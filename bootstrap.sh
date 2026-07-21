#!/usr/bin/env bash
# Takes a fresh Mac from nothing to a built nix-darwin config.
# Run this once. After it finishes, use ./rebuild.sh for every later change.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

echo "==> Step 1: Determinate Nix"
if command -v nix >/dev/null 2>&1; then
  echo "    nix already installed, skipping"
else
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo "==> Step 2: symlink this repo to ~/.dotfiles"
# home.nix resolves its mkOutOfStoreSymlink paths through ~/.dotfiles, so this
# has to exist before the first switch or the build will fail to find them.
ln -sfn "$DIR" ~/.dotfiles

echo "==> Step 3: personalize the configured username"
# Do this before any sudo call: sudo resets $USER to root, so whoami has to
# run as the real interactive user first.
REAL_USER="$(whoami)"
FLAKE_USER="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"
if [ -z "$FLAKE_USER" ]; then
  echo "    Could not find the single \"user = \" line in flake.nix."
  echo "    Edit flake.nix yourself before continuing."
  exit 1
elif [ "$FLAKE_USER" != "$REAL_USER" ]; then
  echo "    flake.nix is configured for user \"$FLAKE_USER\", but you are \"$REAL_USER\"."
  read -r -p "    Rewrite flake.nix's \"user = \" line to \"$REAL_USER\"? [y/N] " REPLY
  if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    sed -i '' -E "s/^([[:space:]]*user = \")[^\"]+(\";.*)/\1${REAL_USER}\2/" "$DIR/flake.nix"
    echo "    Updated. Review the change with: git diff flake.nix"
  else
    echo "    Skipped. Edit the single \"user = \" line in flake.nix yourself before continuing."
    exit 1
  fi
else
  echo "    flake.nix already matches \"$REAL_USER\", nothing to do."
fi

echo "==> Step 4: generate and load an SSH key for GitHub"
# Generate a modern SSH key once so git+ssh works right after bootstrap.
SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"
SSH_PUB="${SSH_KEY}.pub"
SSH_CONFIG="$SSH_DIR/config"
SSH_COMMENT="${REAL_USER}@$(hostname -s 2>/dev/null || hostname)"

if [ ! -d "$SSH_DIR" ]; then
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
fi

if [ -f "$SSH_KEY" ]; then
  echo "    $SSH_KEY already exists, skipping generation."
else
  ssh-keygen -t ed25519 -C "$SSH_COMMENT" -f "$SSH_KEY" -N ""
fi

if [ ! -f "$SSH_PUB" ]; then
  ssh-keygen -y -f "$SSH_KEY" > "$SSH_PUB"
fi

if [ -z "${SSH_AUTH_SOCK:-}" ]; then
  eval "$(ssh-agent -s)" >/dev/null
else
  set +e
  ssh-add -l >/dev/null 2>&1
  SSH_ADD_LIST_RC=$?
  set -e
  if [ "$SSH_ADD_LIST_RC" -eq 2 ]; then
    eval "$(ssh-agent -s)" >/dev/null
  fi
fi

if ssh-add --apple-use-keychain "$SSH_KEY" >/dev/null 2>&1; then
  echo "    Added $SSH_KEY to ssh-agent."
elif ssh-add "$SSH_KEY" >/dev/null 2>&1; then
  echo "    Added $SSH_KEY to ssh-agent."
else
  echo "    Could not add $SSH_KEY to ssh-agent automatically."
fi

if [ ! -f "$SSH_CONFIG" ]; then
  touch "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
fi
if grep -Eq '^[[:space:]]*Host[[:space:]]+github\.com([[:space:]]|$)' "$SSH_CONFIG"; then
  echo "    ~/.ssh/config already has a github.com host entry, leaving it as-is."
else
  {
    echo ""
    echo "Host github.com"
    echo "  AddKeysToAgent yes"
    echo "  UseKeychain yes"
    echo "  IdentityFile ~/.ssh/id_ed25519"
    echo "  IdentitiesOnly yes"
  } >> "$SSH_CONFIG"
  echo "    Added github.com SSH config entry in ~/.ssh/config."
fi

echo "    Public key (add it at https://github.com/settings/keys):"
cat "$SSH_PUB"
if command -v pbcopy >/dev/null 2>&1; then
  echo "    To copy it on macOS: pbcopy < \"$SSH_PUB\""
fi

echo "==> Step 5: first darwin-rebuild switch (pinned to nix-darwin-26.05)"
# darwin-rebuild doesn't exist yet on a fresh machine, so run it straight
# from the flake this once. After this, rebuild.sh works normally.
# This fetches the darwin-rebuild tool from the nix-darwin-26.05 release branch,
# not the exact flake.lock revision. The system config it applies is still pinned
# by this repo's flake.lock.
# sudo resets PATH to a secure default that excludes /nix/.../bin, so a
# freshly installed `nix` would not be found under sudo even though it's
# on PATH here. Resolve the absolute path first and invoke that instead.
NIX_BIN="$(command -v nix)"
# "mac" is the flake host label - if you renamed it, change it in flake.nix
# and rebuild.sh too.
sudo "$NIX_BIN" run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake ~/.dotfiles#mac
# If this still fails with "nix: command not found", open a new terminal
# (Determinate adds nix to new shells' PATH) and re-run ./bootstrap.sh.

echo "==> Done. Use ./rebuild.sh for future changes."

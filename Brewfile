# Aligned with the machine on 2026-11-04. `brew bundle` installs what is
# missing on apply; it never removes, so treat this as the guaranteed set.
# node is deliberately absent: node and go versions come from mise
# (~/.config/mise/config.toml).

tap "ampcode/tap"
tap "anomalyco/tap"
tap "hashicorp/tap"
tap "jwarykowski/tap"
tap "nikitabobko/tap", trusted: { casks: ["aerospace"] }
tap "oven-sh/bun"
tap "snowplow/taps"
tap "stablyai/orca", trusted: { casks: ["orca"] }

# CLI basics
brew "bat"
brew "mas"
brew "btop"
brew "coreutils"
brew "fd"
brew "ffmpeg"
brew "findutils"
brew "fzf"
brew "gawk"
brew "gnu-sed"
brew "jq"
brew "just"
brew "mcfly"
brew "neovim"
brew "ripgrep"
brew "shfmt"
brew "switchaudio-osx"
brew "tmux"
brew "tree"
brew "yazi"
brew "yq"

# Git and dotfiles
brew "chezmoi"
brew "gh"
brew "git"
brew "git-delta"
brew "lazygit"
# For the encrypted ssh config; encryption is not yet configured, see
# .chezmoiignore.
brew "age"

# Languages and runtimes (node and go live in mise)
brew "mise"
brew "uv"
brew "oven-sh/bun/bun", trusted: true

# Agents and AI tooling
brew "herdr"
brew "hunk"
brew "anomalyco/tap/opencode", trusted: true
brew "ampcode/tap/ampcode", trusted: true
brew "rtk"
brew "rust"
brew "jwarykowski/tap/shepherd", trusted: true

# Cloud and data
brew "awscli"
brew "colima"
brew "docker"
brew "docker-buildx"
brew "docker-compose"
brew "docker-credential-helper"
brew "lazydocker"
brew "railway"
brew "rclone"
brew "snowflake-cli"
brew "hashicorp/tap/terraform", trusted: true
brew "gopass"
brew "gnupg"
brew "pinentry-mac"
brew "snowplow/taps/snowplow-cli", trusted: true

# Desktop odds and ends
brew "mole"

# Window management and menu bar
cask "aerospace"
cask "flux-app"
cask "scroll-reverser"
cask "vicinae"
cask "superkey"

# Terminals and development
cask "kitty"
cask "zed"

# AI
cask "chatgpt"
cask "claude"
cask "codex"

# Productivity
cask "antinote"
cask "obsidian"
cask "portfolioperformance"

# Media and communication
cask "discord"
cask "spotify"

# Sync and network
cask "syncthing-app"
cask "tailscale-app"

# Fonts
cask "font-geist-mono"
cask "font-jetbrains-mono-nerd-font"

# App Store
mas "Amphetamine", id: 937984704

# Other package managers
uv "context-stats"
uv "dbt-core", with: ["dbt-snowflake"]
uv "meltano"
uv "ruff"
# JS CLIs (td, qmd, defuddle, serverless) are bun globals: `bun add -g`.
# Brewfile has no bun verb, and npm here would install into mise's node.

# Aligned with the machine on 2026-09-25. `brew bundle` installs what is
# missing on apply; it never removes, so treat this as the guaranteed set.
# node is deliberately absent: it stays installed as a brew dependency of
# agent-browser, but node and go versions come from mise
# (~/.config/mise/config.toml).

tap "ampcode/tap"
tap "anomalyco/tap"
tap "bjarneo/cliamp"
tap "jwarykowski/tap"
tap "nikitabobko/tap", trusted: { casks: ["aerospace"] }
tap "oven-sh/bun"
tap "snowplow/taps"
tap "stablyai/orca", trusted: { casks: ["orca"] }
tap "steipete/tap", trusted: { casks: ["codexbar"] }

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
brew "htop"
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

# Documents and publishing
brew "code2prompt"
brew "hugo"
brew "marp-cli"
brew "pandoc"
brew "poppler"

# Agents and AI tooling
brew "agent-browser"
brew "herdr"
brew "hunk"
brew "llama.cpp"
brew "anomalyco/tap/opencode", trusted: true
brew "ampcode/tap/ampcode", trusted: true
brew "rtk"
brew "python@3.11"
brew "rust"
brew "jwarykowski/tap/shepherd", trusted: true

# Cloud and data
brew "awscli"
brew "docker-buildx"
brew "kubernetes-cli"
brew "lazydocker"
brew "lazysql"
brew "mysql-client"
brew "pocketbase"
brew "railway"
brew "rclone"
brew "redis"
brew "snowflake-cli"
brew "terraform"
brew "gopass"
brew "snowplow/taps/snowplow-cli", trusted: true

# Networking
brew "wireguard-tools"

# Desktop odds and ends
brew "automake"
brew "mole"
brew "nvtop"
brew "bjarneo/cliamp/cliamp", trusted: true

# Window management and menu bar
cask "aerospace"
cask "betterdisplay"
cask "flux-app"
cask "hiddenbar"
cask "meetingbar"
cask "raycast"
cask "scroll-reverser"
cask "shottr"
cask "stats"
cask "superkey"

# Terminals and development
cask "clickhouse"
cask "docker-desktop"
cask "fork"
cask "kitty"
cask "linear"
cask "visual-studio-code"

# AI
cask "chatgpt"
cask "claude"
cask "codex"
cask "codex-app"
cask "codexbar"
cask "superwhisper"

# Productivity
cask "antinote"
cask "bettercapture"
cask "coteditor"
cask "libreoffice"
cask "obsidian"
cask "portfolioperformance"

# Media and communication
cask "discord"
cask "spotify"
cask "vlc"

# Sync and network
cask "syncthing-app"
cask "tailscale-app"

# Fonts
cask "font-geist-mono"
cask "font-jetbrains-mono-nerd-font"

# App Store
mas "Amphetamine", id: 937984704
mas "rcmd", id: 1596283165

# VSCode Extensions
vscode "charliermarsh.ruff"
vscode "github.vscode-github-actions"
vscode "golang.go"
vscode "hashicorp.terraform"
vscode "ms-azuretools.vscode-containers"
vscode "ms-azuretools.vscode-docker"
vscode "ms-python.debugpy"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-python.vscode-python-envs"
vscode "ms-toolsai.datawrangler"
vscode "ms-toolsai.jupyter"
vscode "ms-toolsai.jupyter-keymap"
vscode "ms-toolsai.jupyter-renderers"
vscode "ms-toolsai.vscode-jupyter-cell-tags"
vscode "ms-toolsai.vscode-jupyter-slideshow"
vscode "ms-vscode-remote.remote-ssh"
vscode "ms-vscode-remote.remote-ssh-edit"
vscode "ms-vscode-remote.vscode-remote-extensionpack"
vscode "ms-vscode.remote-explorer"
vscode "ms-vscode.remote-server"

# Other package managers
uv "context-stats"
uv "cookiecutter"
uv "dbt-core", with: ["dbt-snowflake"]
uv "meltano"
uv "ruff"
npm "@doist/todoist-cli"
npm "defuddle"
npm "node-gyp"
npm "serverless"

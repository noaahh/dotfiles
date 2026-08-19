# Aligned with the machine on 2026-08-19. `brew bundle` installs what is
# missing on apply; it never removes, so treat this as the guaranteed set.
# node is deliberately absent: it stays installed as a brew dependency of
# opencode and agent-browser, but node and go versions come from mise
# (~/.config/mise/config.toml).

tap "bjarneo/cliamp"
tap "cloudmanic/spice-edit", "https://github.com/cloudmanic/spice-edit"
tap "felixkratz/formulae", "https://github.com/FelixKratz/homebrew-formulae"
tap "jwarykowski/tap"
tap "nikitabobko/tap"
tap "oven-sh/bun"
tap "schpet/tap"
tap "snowplow/taps"
tap "stablyai/orca", trusted: { casks: ["orca"] }
tap "steipete/tap", trusted: { casks: ["codexbar"] }
tap "vjeantet/tap"

# CLI basics
brew "bat"
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
brew "vjeantet/tap/alerter", trusted: true

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
brew "opencode"
brew "rtk"
brew "jwarykowski/tap/shepherd", trusted: true
brew "schpet/tap/linear", link: false, trusted: true

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
brew "zrok"

# Desktop odds and ends
brew "automake"
brew "mole"
brew "nvtop"
brew "felixkratz/formulae/borders", restart_service: :changed, trusted: true
brew "bjarneo/cliamp/cliamp", trusted: true
brew "cloudmanic/spice-edit/spice-edit"

# Window management and menu bar
cask "aerospace"
cask "betterdisplay"
cask "flux-app"
cask "hiddenbar"
cask "itsycal"
cask "meetingbar"
cask "openlogi"
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
cask "ngrok"
cask "visual-studio-code"

# AI
cask "chatgpt"
cask "claude"
cask "claude-code@latest"
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
cask "onedrive"
cask "syncthing-app"
cask "tailscale-app"

# Fonts
cask "font-geist-mono"
cask "font-jetbrains-mono-nerd-font"

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
uv "cookiecutter"
uv "dbt-core", with: ["dbt-snowflake"]
uv "graphifyy"
uv "meltano"
uv "ruff"
npm "@doist/todoist-cli"
npm "defuddle"
npm "node-gyp"
npm "serverless"

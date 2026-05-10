# ~/.config/fish/config.fish — copiado por 3-caelestia-setup.sh

# ─── Starship prompt ──────────────────────────────────────────────────────────
if command -q starship
    starship init fish | source
end

# ─── eza como reemplazo de ls ─────────────────────────────────────────────────
if command -q eza
    alias ls  'eza --group-directories-first'
    alias ll  'eza -la --group-directories-first --git'
    alias la  'eza -a --group-directories-first'
    alias lt  'eza --tree --level=2'
    alias llt 'eza --tree --level=3 -la'
else
    alias ll 'ls -la'
    alias la 'ls -A'
end

# ─── Navegación rápida ────────────────────────────────────────────────────────
alias ..   'cd ..'
alias ...  'cd ../..'
alias dev  'cd ~/dev'

# ─── Seguridad — pedir confirmación en operaciones destructivas ───────────────
alias rm   'rm -i'
alias cp   'cp -i'
alias mv   'mv -i'

# ─── Abreviaciones (se expanden al escribir) ──────────────────────────────────
abbr -a g    git
abbr -a gs   'git status'
abbr -a ga   'git add'
abbr -a gc   'git commit -m'
abbr -a gp   'git push'
abbr -a gpl  'git pull'
abbr -a gco  'git checkout'
abbr -a gd   'git diff'
abbr -a gl   'git log --oneline --graph --decorate -20'

abbr -a yi   'yay -S --needed'
abbr -a yr   'yay -Rns'
abbr -a ys   'yay -Ss'
abbr -a yu   'yay -Syu'
abbr -a pi   'sudo pacman -S --needed'
abbr -a pr   'sudo pacman -Rns'
abbr -a pu   'sudo pacman -Syu'

abbr -a s    'systemctl'
abbr -a ss   'sudo systemctl'
abbr -a js   'sudo journalctl -xe'

# ─── Variables de entorno ─────────────────────────────────────────────────────
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx BROWSER google-chrome-stable

# XDG dirs
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_DATA_HOME   "$HOME/.local/share"
set -gx XDG_CACHE_HOME  "$HOME/.cache"

# Wayland para apps que lo necesitan
set -gx QT_QPA_PLATFORM wayland
set -gx GDK_BACKEND     wayland
set -gx MOZ_ENABLE_WAYLAND 1

# ─── nvm.fish (Node.js) ───────────────────────────────────────────────────────
if functions -q nvm
    nvm use lts --silent 2>/dev/null
end

# ─── PATH custom ─────────────────────────────────────────────────────────────
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/dev/bin"

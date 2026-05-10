#!/bin/bash
# Configuración de dos cuentas de GitHub con SSH
# Cuenta personal: diegoramirez772 / hidiegoramirez@gmail.com
# Cuenta escuela:  diego-frias-ramirez / diego_3141240221@utd.edu.mx
# Uso: bash install/setup-git.sh

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
section() { echo -e "\n${BLUE}══ $1 ══${NC}\n"; }

section "Configuración Git — dos cuentas de GitHub"

# ─── Crear directorio de proyectos de escuela ─────────────────────────────────
mkdir -p "$HOME/school"
mkdir -p "$HOME/dev"
info "Carpetas ~/dev y ~/school creadas"

# ─── SSH key — cuenta personal ────────────────────────────────────────────────
section "SSH key — cuenta personal (diegoramirez772)"
KEY_PERSONAL="$HOME/.ssh/id_ed25519_personal"

if [ -f "$KEY_PERSONAL" ]; then
    warn "Ya existe una SSH key personal — saltando generación"
else
    ssh-keygen -t ed25519 -C "hidiegoramirez@gmail.com" -f "$KEY_PERSONAL" -N ""
    info "SSH key personal generada: $KEY_PERSONAL"
fi

# ─── SSH key — cuenta escuela ─────────────────────────────────────────────────
section "SSH key — cuenta escuela (diego-frias-ramirez)"
KEY_SCHOOL="$HOME/.ssh/id_ed25519_school"

if [ -f "$KEY_SCHOOL" ]; then
    warn "Ya existe una SSH key de escuela — saltando generación"
else
    ssh-keygen -t ed25519 -C "diego_3141240221@utd.edu.mx" -f "$KEY_SCHOOL" -N ""
    info "SSH key de escuela generada: $KEY_SCHOOL"
fi

# ─── SSH config ───────────────────────────────────────────────────────────────
section "Configurando ~/.ssh/config"
SSH_CONFIG="$HOME/.ssh/config"

# Backup si ya existe
[ -f "$SSH_CONFIG" ] && cp "$SSH_CONFIG" "${SSH_CONFIG}.bak"

cat > "$SSH_CONFIG" << 'EOF'
# GitHub — cuenta personal (diegoramirez772)
Host github-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
    AddKeysToAgent yes

# GitHub — cuenta escuela (diego-frias-ramirez)
Host github-school
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_school
    AddKeysToAgent yes
EOF

chmod 600 "$SSH_CONFIG"
info "~/.ssh/config configurado"

# ─── Git config global — personal ────────────────────────────────────────────
section "Git config global (cuenta personal por defecto)"
git config --global user.name "Diego Fer"
git config --global user.email "hidiegoramirez@gmail.com"
git config --global init.defaultBranch main
git config --global core.editor "nano"
git config --global pull.rebase false

# includeIf: proyectos en ~/school/ usan automáticamente la cuenta de escuela
git config --global includeIf."gitdir:$HOME/school/".path "$HOME/.gitconfig-school"

info "Git global configurado con cuenta personal"

# ─── Git config escuela ───────────────────────────────────────────────────────
cat > "$HOME/.gitconfig-school" << 'EOF'
[user]
    name = Diego Frias Ramirez
    email = diego_3141240221@utd.edu.mx
EOF

info "~/.gitconfig-school configurado"
info "Proyectos en ~/school/ usan automáticamente la cuenta de escuela"

# ─── Agregar keys al agente SSH ───────────────────────────────────────────────
section "Iniciando SSH agent"
eval "$(ssh-agent -s)"
ssh-add "$KEY_PERSONAL" 2>/dev/null || true
ssh-add "$KEY_SCHOOL" 2>/dev/null || true

# ─── Mostrar public keys para agregar a GitHub ────────────────────────────────
section "ACCIÓN REQUERIDA — Agregar estas keys a GitHub"

echo ""
echo -e "${GREEN}=== KEY PERSONAL (github.com/settings/keys) ===${NC}"
echo -e "${YELLOW}Cuenta: diegoramirez772${NC}"
cat "${KEY_PERSONAL}.pub"

echo ""
echo -e "${GREEN}=== KEY ESCUELA (github.com/settings/keys en cuenta diego-frias-ramirez) ===${NC}"
echo -e "${YELLOW}Cuenta: diego-frias-ramirez${NC}"
cat "${KEY_SCHOOL}.pub"

echo ""
echo "Pasos:"
echo "  1. Copiar la key personal → ir a github.com → Settings → SSH keys → New SSH key → pegar"
echo "  2. Hacer lo mismo en la cuenta de escuela con la key de escuela"
echo "  3. Verificar conexión:"
echo "     ssh -T git@github-personal   # debe decir: Hi diegoramirez772!"
echo "     ssh -T git@github-school     # debe decir: Hi diego-frias-ramirez!"
echo ""
echo "Para clonar repos:"
echo "  Personal: git clone git@github-personal:diegoramirez772/repo.git"
echo "  Escuela:  git clone git@github-school:diego-frias-ramirez/repo.git"
echo ""
echo "  Dentro de ~/school/ git usa automáticamente tu cuenta de escuela."
echo "  En cualquier otra carpeta usa la cuenta personal."
echo ""

#!/bin/bash
# Reparación de Git SSH — dos cuentas de GitHub
# Síntomas: git push pide contraseña, permission denied, wrong account
# Uso: bash install/repair/fix-git-ssh.sh

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'
info()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[x]${NC} $1"; }
section() { echo -e "\n${BLUE}══ $1 ══${NC}\n"; }

echo ""
echo "=== FIX GIT SSH — Dos cuentas GitHub ==="
echo ""

KEY_PERSONAL="$HOME/.ssh/id_ed25519_personal"
KEY_SCHOOL="$HOME/.ssh/id_ed25519_school"
SSH_CONFIG="$HOME/.ssh/config"

# ─── Diagnóstico ──────────────────────────────────────────────────────────────
section "Diagnóstico"

echo "SSH keys:"
[ -f "$KEY_PERSONAL" ]     && info "  key personal existe" || warn "  key personal NO existe"
[ -f "$KEY_SCHOOL" ]       && info "  key escuela existe"  || warn "  key escuela NO existe"
[ -f "$SSH_CONFIG" ]       && info "  ~/.ssh/config existe" || warn "  ~/.ssh/config NO existe"

echo ""
echo "Test de conexión a GitHub:"
ssh -T git@github-personal 2>&1 | grep -q "successfully authenticated" && \
    info "  cuenta personal: conectada" || warn "  cuenta personal: sin conexión"
ssh -T git@github-school 2>&1 | grep -q "successfully authenticated" && \
    info "  cuenta escuela: conectada"  || warn "  cuenta escuela: sin conexión"

# ─── Fix 1: Regenerar keys faltantes ─────────────────────────────────────────
section "Fix 1: SSH keys"

if [ ! -f "$KEY_PERSONAL" ]; then
    warn "Generando key personal..."
    ssh-keygen -t ed25519 -C "hidiegoramirez@gmail.com" -f "$KEY_PERSONAL" -N ""
    info "Key personal generada"
fi

if [ ! -f "$KEY_SCHOOL" ]; then
    warn "Generando key escuela..."
    ssh-keygen -t ed25519 -C "diego_3141240221@utd.edu.mx" -f "$KEY_SCHOOL" -N ""
    info "Key escuela generada"
fi

# ─── Fix 2: Recrear ~/.ssh/config ────────────────────────────────────────────
section "Fix 2: ~/.ssh/config"

cat > "$SSH_CONFIG" << 'EOF'
Host github-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
    AddKeysToAgent yes

Host github-school
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_school
    AddKeysToAgent yes
EOF
chmod 600 "$SSH_CONFIG"
info "~/.ssh/config recreado"

# ─── Fix 3: Recrear git config ────────────────────────────────────────────────
section "Fix 3: Git config"

git config --global user.name  "Diego Fer"
git config --global user.email "hidiegoramirez@gmail.com"
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global includeIf."gitdir:$HOME/school/".path "$HOME/.gitconfig-school"

cat > "$HOME/.gitconfig-school" << 'EOF'
[user]
    name = Diego Frias Ramirez
    email = diego_3141240221@utd.edu.mx
EOF
info "Git config global y escuela configurados"

# ─── Fix 4: Agregar keys al agente ───────────────────────────────────────────
section "Fix 4: SSH agent"
eval "$(ssh-agent -s)" 2>/dev/null
ssh-add "$KEY_PERSONAL" 2>/dev/null && info "Key personal cargada en agente"
ssh-add "$KEY_SCHOOL"   2>/dev/null && info "Key escuela cargada en agente"

# ─── Mostrar keys para agregar a GitHub ───────────────────────────────────────
section "ACCIÓN REQUERIDA — Agregar keys a GitHub"

echo -e "${GREEN}KEY PERSONAL → github.com (cuenta diegoramirez772) → Settings → SSH keys:${NC}"
cat "${KEY_PERSONAL}.pub"
echo ""
echo -e "${GREEN}KEY ESCUELA → github.com (cuenta diego-frias-ramirez) → Settings → SSH keys:${NC}"
cat "${KEY_SCHOOL}.pub"

echo ""
echo "Después de agregar las keys, verificar:"
echo "  ssh -T git@github-personal   # debe decir: Hi diegoramirez772!"
echo "  ssh -T git@github-school     # debe decir: Hi diego-frias-ramirez!"
echo ""
echo "Clonar repos:"
echo "  Personal: git clone git@github-personal:diegoramirez772/repo.git"
echo "  Escuela:  git clone git@github-school:diego-frias-ramirez/repo.git"
echo ""
echo "  Dentro de ~/school/ el git usa automáticamente la cuenta de escuela."

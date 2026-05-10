#!/bin/bash
# Reparación de Node.js / nvm.fish en fish shell
# Síntomas: comando 'node' no encontrado en fish, nvm no funciona
# Uso: bash install/repair/fix-node.sh

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

echo ""
echo "=== FIX NODE.JS + NVM.FISH ==="
echo ""

# ─── Diagnóstico ──────────────────────────────────────────────────────────────
echo "--- Diagnóstico ---"
fish -c "type nvm" &>/dev/null && echo "nvm.fish: instalado" || echo "nvm.fish: NO instalado"
fish -c "type node" &>/dev/null && echo "node: $(fish -c 'node --version')" || echo "node: NO disponible en fish"
command -v fish &>/dev/null && echo "fish: $(fish --version)" || echo "fish: no instalado"

echo ""

# ─── Fix 1: Instalar fisher y nvm.fish ───────────────────────────────────────
echo "--- Fix 1: Instalar fisher + nvm.fish ---"
fish -c "
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher install jorgebucaran/fisher
    fisher install jorgebucaran/nvm.fish
" && info "fisher + nvm.fish instalados" || warn "Error instalando — verificar conexión a internet"

# ─── Fix 2: Instalar Node.js LTS ──────────────────────────────────────────────
echo ""
echo "--- Fix 2: Instalar Node.js LTS ---"
fish -c "nvm install lts && nvm use lts" && \
    info "Node.js LTS: $(fish -c 'node --version')" || \
    warn "Error instalando Node — intentar: fish -c 'nvm install lts'"

# ─── Fix 3: Verificar en fish ─────────────────────────────────────────────────
echo ""
echo "--- Verificación final ---"
fish -c "node --version" && info "node funciona en fish" || warn "node aún no disponible"
fish -c "npm --version"  && info "npm funciona en fish"  || warn "npm aún no disponible"

echo ""
echo "Para usar nvm dentro de fish:"
echo "  nvm install lts     # instalar LTS"
echo "  nvm use lts         # activar LTS"
echo "  nvm list            # ver versiones instaladas"
echo "  nvm install 20      # instalar versión específica"

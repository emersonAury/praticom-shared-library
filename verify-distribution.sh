#!/bin/bash
# Script para verificar se a exclusão de arquivos está funcionando corretamente

echo "🔍 Verificando distribuição da shared-library..."
echo ""

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para verificar API
check_service() {
    local SERVICE_PATH=$1
    local SERVICE_NAME=$2
    
    if [ ! -d "$SERVICE_PATH/vendor/praticom/shared-library" ]; then
        echo -e "${YELLOW}⚠️  $SERVICE_NAME: Biblioteca não instalada ainda${NC}"
        return
    fi
    
    echo "📦 Verificando $SERVICE_NAME..."
    
    local LIB_PATH="$SERVICE_PATH/vendor/praticom/shared-library"
    local SHOULD_NOT_EXIST=(
        ".github"
        "resources"
        "deploy.sh"
        "update.sh"
        "quick-deploy.sh"
        "check_git.sh"
        "DEPLOY_README.md"
        "README.md"
        ".gitattributes"
    )
    
    local SHOULD_EXIST=(
        "src"
        "composer.json"
    )
    
    local ERRORS=0
    local SUCCESS=0
    
    # Verifica arquivos que NÃO devem existir
    for item in "${SHOULD_NOT_EXIST[@]}"; do
        if [ -e "$LIB_PATH/$item" ]; then
            echo -e "  ${RED}❌ ERRO: $item existe (não deveria)${NC}"
            ((ERRORS++))
        else
            echo -e "  ${GREEN}✅ $item não existe (correto)${NC}"
            ((SUCCESS++))
        fi
    done
    
    # Verifica arquivos que DEVEM existir
    for item in "${SHOULD_EXIST[@]}"; do
        if [ -e "$LIB_PATH/$item" ]; then
            echo -e "  ${GREEN}✅ $item existe (correto)${NC}"
            ((SUCCESS++))
        else
            echo -e "  ${RED}❌ ERRO: $item não existe (deveria)${NC}"
            ((ERRORS++))
        fi
    done
    
    # Tamanho do diretório
    local SIZE=$(du -sh "$LIB_PATH" 2>/dev/null | cut -f1)
    echo -e "  📊 Tamanho: $SIZE"
    
    echo ""
    if [ $ERRORS -eq 0 ]; then
        echo -e "${GREEN}✅ $SERVICE_NAME: Tudo correto! ($SUCCESS verificações OK)${NC}"
    else
        echo -e "${RED}⚠️  $SERVICE_NAME: $ERRORS problemas encontrados${NC}"
    fi
    echo ""
}

# Diretórios
ROOT_DIR="/e/Mega/PraticomAI"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Verificação da Distribuição da Shared Library"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar APIs
if [ -d "$ROOT_DIR/api" ]; then
    for api_dir in "$ROOT_DIR/api"/*/ ; do
        if [ -d "$api_dir" ]; then
            SERVICE_NAME="API: $(basename "$api_dir")"
            check_service "$api_dir" "$SERVICE_NAME"
        fi
    done
fi

# Verificar Dashboard
if [ -d "$ROOT_DIR/dashboard" ]; then
    check_service "$ROOT_DIR/dashboard" "Dashboard"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Verificação concluída!"
echo ""
echo "💡 Dica: Se encontrou problemas, execute:"
echo "   ./quick-deploy.sh \"Atualizar exclusões\" \"1.0.6\""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

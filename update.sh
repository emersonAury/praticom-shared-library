#!/bin/bash

# Diretórios e arquivos de log
ROOT_DIR=".."
UPDATE_LOG="$ROOT_DIR/Logs/update_log.txt"
API_DIR="$ROOT_DIR/api"
DASHBOARD_DIR="$ROOT_DIR/dashboard"
CENTRAL_JS="$ROOT_DIR/praticom-shared-library/resources/_js"

log_write() {
    local MSG=$1
    local LOG_FILE=$2
    echo "[`date '+%Y-%m-%d %H:%M:%S'`] $MSG" | tee -a "$LOG_FILE"
}

# Função para sincronizar JS
sync_js_to_service() {
    local SERVICE_DIR=$1
    local SERVICE_NAME=$2
    
    local JS_DIR="$SERVICE_DIR/_js"
    mkdir -p "$JS_DIR"

    for jsfile in "$CENTRAL_JS"/*.js; do
        if [ -f "$jsfile" ]; then
            cp -u "$jsfile" "$JS_DIR/"
            log_write "📄 JS $(basename $jsfile) copiado para $SERVICE_NAME" "$UPDATE_LOG"
        fi
    done
}

# Função para atualizar serviço via Composer
update_service() {
    local SERVICE_DIR=$1
    local SERVICE_NAME=$2
    
    if [ ! -d "$SERVICE_DIR" ]; then
        log_write "⚠️  Diretório $SERVICE_NAME não encontrado: $SERVICE_DIR" "$UPDATE_LOG"
        return 1
    fi
    
    if [ ! -f "$SERVICE_DIR/composer.json" ]; then
        log_write "⚠️  $SERVICE_NAME não possui composer.json. Pulando atualização." "$UPDATE_LOG"
        return 1
    fi

    cd "$SERVICE_DIR" || {
        log_write "❌ Erro ao acessar diretório $SERVICE_NAME" "$UPDATE_LOG"
        return 1
    }

    # Verifica alterações pendentes
    if command -v git &> /dev/null && [ -d ".git" ]; then
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            log_write "⚠️  $SERVICE_NAME possui alterações não commitadas. Pulando atualização." "$UPDATE_LOG"
            cd - > /dev/null
            return 1
        fi
    fi

    log_write "🔄 Atualizando $SERVICE_NAME..." "$UPDATE_LOG"

    # Composer update da shared-library
    if composer update praticom/shared-library --with-all-dependencies; then
        log_write "✅ Composer update concluído para $SERVICE_NAME" "$UPDATE_LOG"
        
        # Sincronizar JS
        sync_js_to_service "$SERVICE_DIR" "$SERVICE_NAME"
        
        cd - > /dev/null
        log_write "✅ $SERVICE_NAME atualizado e JS sincronizados." "$UPDATE_LOG"
        return 0
    else
        log_write "❌ Erro no composer update para $SERVICE_NAME" "$UPDATE_LOG"
        cd - > /dev/null
        return 1
    fi
}

# --- Inicialização ---
log_write "🚀 Iniciando processo de atualização..." "$UPDATE_LOG"

# --- Shared-library ---
cd praticom-shared-library || {
    log_write "❌ Erro: não foi possível acessar praticom-shared-library" "$UPDATE_LOG"
    exit 1
}

# Verifica alterações pendentes na shared-library
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  ================================="
    echo "⚠️  ALTERAÇÕES NÃO COMMITADAS ENCONTRADAS"
    echo "⚠️  ================================="
    echo ""
    echo "📋 Arquivos modificados:"
    git status --porcelain
    echo ""
    echo "🔧 Para resolver, execute UM dos comandos:"
    echo "   1️⃣  git add . && git commit -m 'Suas alterações'"
    echo "   2️⃣  git stash  (guarda temporariamente)"
    echo "   3️⃣  ./check_git.sh  (script assistente)"
    echo ""
    echo "🚀 Depois execute novamente: ./update.sh \"$COMMIT_MESSAGE\" \"$VERSION\""
    echo ""
    log_write "⚠️  Deploy abortado: alterações não commitadas na shared-library." "$UPDATE_LOG"
    exit 1
fi

# Pede mensagem e versão
COMMIT_MESSAGE=$1
VERSION=$2

if [ -z "$COMMIT_MESSAGE" ] || [ -z "$VERSION" ]; then
    log_write "❌ Uso: $0 \"Mensagem do commit\" \"Versão\"" "$UPDATE_LOG"
    exit 1
fi

TAG="v$VERSION"

# Commit, push e tag
git add .
if git commit -m "$COMMIT_MESSAGE"; then
    log_write "✅ Commit criado: $COMMIT_MESSAGE" "$UPDATE_LOG"
else
    log_write "ℹ️  Nenhuma alteração para commitar." "$UPDATE_LOG"
fi

git push origin main || {
    log_write "❌ Erro ao fazer push para main" "$UPDATE_LOG"
    exit 1
}

git tag "$TAG" || log_write "⚠️  Tag $TAG já existe ou erro ao criar" "$UPDATE_LOG"
git push origin "$TAG" || log_write "⚠️  Erro ao enviar tag $TAG" "$UPDATE_LOG"

log_write "✅ Shared-library atualizada e tag $TAG processada." "$UPDATE_LOG"

cd "$ROOT_DIR" || exit 1

# --- Contadores para relatório ---
UPDATED_SERVICES=()
FAILED_SERVICES=()

# --- Atualização das APIs ---
log_write "🔄 Processando APIs..." "$UPDATE_LOG"

if [ -d "$API_DIR" ]; then
    for api in "$API_DIR"/*; do
        if [ -d "$api" ]; then
            SERVICE_NAME="api/$(basename "$api")"
            if update_service "$api" "$SERVICE_NAME"; then
                UPDATED_SERVICES+=("$SERVICE_NAME")
            else
                FAILED_SERVICES+=("$SERVICE_NAME")
            fi
        fi
    done
else
    log_write "⚠️  Diretório de APIs não encontrado: $API_DIR" "$UPDATE_LOG"
fi

# --- Atualização do Dashboard ---
log_write "🔄 Processando Dashboard..." "$UPDATE_LOG"

if update_service "$DASHBOARD_DIR" "dashboard"; then
    UPDATED_SERVICES+=("dashboard")
else
    FAILED_SERVICES+=("dashboard")
fi

# --- Relatório final ---
log_write "=============================================" "$UPDATE_LOG"
log_write "📊 RELATÓRIO FINAL DE ATUALIZAÇÃO" "$UPDATE_LOG"
log_write "=============================================" "$UPDATE_LOG"

if [ ${#UPDATED_SERVICES[@]} -gt 0 ]; then
    log_write "✅ Serviços atualizados com sucesso (${#UPDATED_SERVICES[@]}):" "$UPDATE_LOG"
    for service in "${UPDATED_SERVICES[@]}"; do
        log_write "   - $service" "$UPDATE_LOG"
    done
fi

if [ ${#FAILED_SERVICES[@]} -gt 0 ]; then
    log_write "❌ Serviços com falha ou ignorados (${#FAILED_SERVICES[@]}):" "$UPDATE_LOG"
    for service in "${FAILED_SERVICES[@]}"; do
        log_write "   - $service" "$UPDATE_LOG"
    done
fi

log_write "=============================================" "$UPDATE_LOG"
log_write "🎉 Processo de atualização concluído!" "$UPDATE_LOG"
log_write "📝 Total de serviços processados: $((${#UPDATED_SERVICES[@]} + ${#FAILED_SERVICES[@]}))" "$UPDATE_LOG"
log_write "=============================================" "$UPDATE_LOG"

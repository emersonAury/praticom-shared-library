#!/bin/bash
# ------------------------------------------------------
# Script avançado de deploy PRATICOM
# Sincroniza JS + atualiza PHP (Composer) + logs + backups
# Inclui suporte ao DASHBOARD além das APIs
# Uso: ./deploy.sh "Mensagem do commit" "Versão"
# ------------------------------------------------------

ROOT_DIR="/e/Mega/PraticomAI"
LIB_DIR="$ROOT_DIR/praticom-shared-library"
API_DIR="$ROOT_DIR/api"
DASHBOARD_DIR="$ROOT_DIR/dashboard"
BACKUP_DIR="$ROOT_DIR/Backups/shared_js"
LOG_DIR="$ROOT_DIR/Logs"
SYNC_LOG="$LOG_DIR/sync_log.txt"
UPDATE_LOG="$LOG_DIR/update_log.txt"

# Verifica parâmetros
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 \"Mensagem do commit\" \"Versão\""
    exit 1
fi

COMMIT_MESSAGE=$1
VERSION=$2
TAG="v$VERSION"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Função de log
log_write() {
    local TIMESTAMP_NOW
    TIMESTAMP_NOW=$(date +"%Y-%m-%d %H:%M:%S")
    local LINE="[$TIMESTAMP_NOW] $1"
    echo "$LINE"
    echo "$LINE" >> "$2"
}

# Garante diretórios
mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR/$TIMESTAMP"

# ------------------------------------------------------
# 1️⃣ Backup + Sincronizar arquivos JS
# ------------------------------------------------------
log_write "Iniciando backup e sincronização de JS..." "$SYNC_LOG"

# Função para sincronizar JS para um diretório específico
sync_js_to_dir() {
    local TARGET_DIR=$1
    local SERVICE_NAME=$2
    
    local JS_DIR="$TARGET_DIR/_js"
    mkdir -p "$JS_DIR"
    
    for file in "$LIB_DIR"/resources/_js/*.js ; do
        BASENAME=$(basename "$file")
        
        # Backup (só faz uma vez)
        if [ ! -f "$BACKUP_DIR/$TIMESTAMP/$BASENAME" ]; then
            cp "$file" "$BACKUP_DIR/$TIMESTAMP/$BASENAME"
        fi
        
        # Copia somente se diferente
        if [ ! -f "$JS_DIR/$BASENAME" ] || ! cmp -s "$file" "$JS_DIR/$BASENAME"; then
            cp "$file" "$JS_DIR/$BASENAME"
            log_write "JS atualizado: $BASENAME -> $SERVICE_NAME/_js" "$SYNC_LOG"
        else
            log_write "JS já atualizado: $BASENAME -> $SERVICE_NAME (nenhuma mudança)" "$SYNC_LOG"
        fi
    done
}

# Sincronizar JS para APIs
for dir in "$API_DIR"/*/ ; do
    if [ -d "$dir" ]; then
        SERVICE_NAME=$(basename "$dir")
        sync_js_to_dir "$dir" "api/$SERVICE_NAME"
    fi
done

# Sincronizar JS para Dashboard
if [ -d "$DASHBOARD_DIR" ]; then
    sync_js_to_dir "$DASHBOARD_DIR" "dashboard"
    log_write "JS sincronizado para o Dashboard" "$SYNC_LOG"
fi

log_write "Backup criado em $BACKUP_DIR/$TIMESTAMP" "$SYNC_LOG"
log_write "Sincronização de JS concluída!" "$SYNC_LOG"

# ------------------------------------------------------
# 2️⃣ Atualizar shared-library via Git e Composer
# ------------------------------------------------------
log_write "Iniciando atualização da shared-library..." "$UPDATE_LOG"

cd "$LIB_DIR" || exit

# Verifica estado do Git
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
    echo "🚀 Depois execute novamente: ./deploy.sh \"$COMMIT_MESSAGE\" \"$VERSION\""
    echo ""
    log_write "⚠️  Deploy abortado: alterações não commitadas na shared-library." "$UPDATE_LOG"
    exit 1
fi

# Commit e push
git add .
git commit -m "$COMMIT_MESSAGE" || log_write "Nenhuma alteração para commitar." "$UPDATE_LOG"
git push origin main || { log_write "❌ Falha ao dar push para main." "$UPDATE_LOG"; exit 1; }

# Tagging
git tag "$TAG"
git push origin "$TAG" || { log_write "❌ Falha ao enviar tag $TAG." "$UPDATE_LOG"; exit 1; }

# Função para atualizar via composer
update_composer() {
    local DIR=$1
    local SERVICE_NAME=$2
    
    if [ -f "$DIR/composer.json" ]; then
        log_write "Atualizando $SERVICE_NAME via Composer..." "$UPDATE_LOG"
        cd "$DIR" || return 1
        if composer update praticom/shared-library; then
            log_write "✅ $SERVICE_NAME atualizado com sucesso" "$UPDATE_LOG"
            cd - > /dev/null
            return 0
        else
            log_write "❌ Erro ao atualizar $SERVICE_NAME via composer." "$UPDATE_LOG"
            cd - > /dev/null
            return 1
        fi
    else
        log_write "⚠️  $SERVICE_NAME ignorado (sem composer.json)" "$UPDATE_LOG"
        return 1
    fi
}

# Atualizar APIs
UPDATED=()
IGNORED=()

cd "$API_DIR" || exit
for dir in */ ; do
    if [ -d "$dir" ]; then
        SERVICE_NAME="api/$(basename "$dir")"
        if update_composer "$API_DIR/$dir" "$SERVICE_NAME"; then
            UPDATED+=("$SERVICE_NAME")
        else
            IGNORED+=("$SERVICE_NAME")
        fi
    fi
done

# Atualizar Dashboard
cd "$ROOT_DIR" || exit
if update_composer "$DASHBOARD_DIR" "dashboard"; then
    UPDATED+=("dashboard")
else
    IGNORED+=("dashboard")
fi

# Resumo final
log_write "=============================================" "$UPDATE_LOG"
log_write "Resumo da atualização" "$UPDATE_LOG"

if [ ${#UPDATED[@]} -gt 0 ]; then
    log_write "✅ Serviços atualizados:" "$UPDATE_LOG"
    for u in "${UPDATED[@]}"; do
        log_write "   - $u" "$UPDATE_LOG"
    done
else
    log_write "⚠️  Nenhum serviço atualizado." "$UPDATE_LOG"
fi

if [ ${#IGNORED[@]} -gt 0 ]; then
    log_write "ℹ️  Serviços ignorados (sem composer.json ou erro):" "$UPDATE_LOG"
    for i in "${IGNORED[@]}"; do
        log_write "   - $i" "$UPDATE_LOG"
    done
fi

log_write "Deploy concluído com segurança!" "$UPDATE_LOG"
log_write "=============================================" "$UPDATE_LOG"

# ------------------------------------------------------
# 3️⃣ Resumo geral no terminal
# ------------------------------------------------------
echo "============================================="
echo "✅ Deploy completo concluído com sucesso!"
echo "🎯 Serviços incluídos: APIs + Dashboard"
echo "📦 Backup de JS: $BACKUP_DIR/$TIMESTAMP"
echo "📝 Logs detalhados:"
echo "   - JS:   $SYNC_LOG"
echo "   - PHP:  $UPDATE_LOG"
echo "============================================="
#!/bin/bash
# ------------------------------------------------------
# Script completo de deploy PRATICOM
# Sincroniza JS + atualiza PHP (Composer) + logs
# Uso: ./deploy.sh "Mensagem do commit" "Versão"
# ------------------------------------------------------

ROOT_DIR="/e/Mega/PraticomAI"
LIB_DIR="$ROOT_DIR/praticom-shared-library"
API_DIR="$ROOT_DIR/api"
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

# Função de log
log_write() {
    local TIMESTAMP
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    local LINE="[$TIMESTAMP] $1"
    echo "$LINE"
    echo "$LINE" >> "$2"
}

# Garante diretório de logs
mkdir -p "$LOG_DIR"

# ------------------------------------------------------
# 1️⃣ Sincronizar arquivos JS
# ------------------------------------------------------
log_write "Iniciando sincronização de JS..." "$SYNC_LOG"

# Percorre microserviços e copia JS
for dir in "$API_DIR"/*/ ; do
    MICRO_JS_DIR="$dir"_js
    mkdir -p "$MICRO_JS_DIR"
    for file in "$LIB_DIR"/resources/_js/*.js ; do
        BASENAME=$(basename "$file")
        cp -u "$file" "$MICRO_JS_DIR/$BASENAME"
        log_write "JS sincronizado: $BASENAME -> $MICRO_JS_DIR" "$SYNC_LOG"
    done
done

log_write "Sincronização de JS concluída!" "$SYNC_LOG"

# ------------------------------------------------------
# 2️⃣ Atualizar shared-library via Composer
# ------------------------------------------------------
log_write "Iniciando atualização da shared-library..." "$UPDATE_LOG"

# Commit e push na biblioteca
cd "$LIB_DIR" || exit
git add .
git commit -m "$COMMIT_MESSAGE"
git push origin main
git tag "$TAG"
git push origin "$TAG"

# Atualiza microserviços
UPDATED=()
IGNORED=()

cd "$API_DIR" || exit
for dir in */ ; do
    if [ -f "$dir/composer.json" ]; then
        log_write "Atualizando microserviço: $dir" "$UPDATE_LOG"
        cd "$dir" || continue
        composer update praticom/shared-library
        cd ..
        UPDATED+=("$dir")
    else
        IGNORED+=("$dir")
    fi
done

# Resumo final
log_write "=============================================" "$UPDATE_LOG"
log_write "Resumo da atualização" "$UPDATE_LOG"

if [ ${#UPDATED[@]} -gt 0 ]; then
    log_write "✅ Microserviços atualizados:" "$UPDATE_LOG"
    for u in "${UPDATED[@]}"; do
        log_write "   - $u" "$UPDATE_LOG"
    done
else
    log_write "⚠️  Nenhum microserviço atualizado." "$UPDATE_LOG"
fi

if [ ${#IGNORED[@]} -gt 0 ]; then
    log_write "ℹ️  Microserviços ignorados (sem composer.json):" "$UPDATE_LOG"
    for i in "${IGNORED[@]}"; do
        log_write "   - $i" "$UPDATE_LOG"
    done
fi

log_write "Processo de deploy concluído!" "$UPDATE_LOG"
log_write "=============================================" "$UPDATE_LOG"

# ------------------------------------------------------
# 3️⃣ Resumo geral no terminal
# ------------------------------------------------------
echo "============================================="
echo "✅ Deploy completo concluído!"
echo "Veja logs detalhados em:"
echo "   - JS:   $SYNC_LOG"
echo "   - PHP:  $UPDATE_LOG"
echo "============================================="

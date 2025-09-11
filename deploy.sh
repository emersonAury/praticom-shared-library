#!/bin/bash
# ------------------------------------------------------
# Script avançado de deploy PRATICOM
# Sincroniza JS + atualiza PHP (Composer) + logs + backups
# Uso: ./deploy.sh "Mensagem do commit" "Versão"
# ------------------------------------------------------

ROOT_DIR="/e/Mega/PraticomAI"
LIB_DIR="$ROOT_DIR/praticom-shared-library"
API_DIR="$ROOT_DIR/api"
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

for dir in "$API_DIR"/*/ ; do
    MICRO_JS_DIR="$dir"_js
    mkdir -p "$MICRO_JS_DIR"

    for file in "$LIB_DIR"/resources/_js/*.js ; do
        BASENAME=$(basename "$file")

        # Backup
        cp "$file" "$BACKUP_DIR/$TIMESTAMP/$BASENAME"

        # Copia somente se diferente
        if [ ! -f "$MICRO_JS_DIR/$BASENAME" ] || ! cmp -s "$file" "$MICRO_JS_DIR/$BASENAME"; then
            cp "$file" "$MICRO_JS_DIR/$BASENAME"
            log_write "JS atualizado: $BASENAME -> $MICRO_JS_DIR" "$SYNC_LOG"
        else
            log_write "JS já atualizado: $BASENAME (nenhuma mudança)" "$SYNC_LOG"
        fi
    done
done

log_write "Backup criado em $BACKUP_DIR/$TIMESTAMP" "$SYNC_LOG"
log_write "Sincronização de JS concluída!" "$SYNC_LOG"

# ------------------------------------------------------
# 2️⃣ Atualizar shared-library via Git e Composer
# ------------------------------------------------------
log_write "Iniciando atualização da shared-library..." "$UPDATE_LOG"

cd "$LIB_DIR" || exit

# Verifica estado do Git
if ! git diff-index --quiet HEAD --; then
    log_write "⚠️  Atenção: existem alterações não commitadas na shared-library." "$UPDATE_LOG"
    log_write "Abortando deploy até resolver (commit ou stash)." "$UPDATE_LOG"
    exit 1
fi

# Commit e push
git add .
git commit -m "$COMMIT_MESSAGE" || log_write "Nenhuma alteração para commitar." "$UPDATE_LOG"
git push origin main || { log_write "❌ Falha ao dar push para main." "$UPDATE_LOG"; exit 1; }

# Tagging
git tag "$TAG"
git push origin "$TAG" || { log_write "❌ Falha ao enviar tag $TAG." "$UPDATE_LOG"; exit 1; }

# Atualiza microserviços
UPDATED=()
IGNORED=()

cd "$API_DIR" || exit
for dir in */ ; do
    if [ -f "$dir/composer.json" ]; then
        log_write "Atualizando microserviço: $dir" "$UPDATE_LOG"
        cd "$dir" || continue
        if composer update praticom/shared-library; then
            UPDATED+=("$dir")
        else
            log_write "❌ Erro ao atualizar $dir via composer." "$UPDATE_LOG"
        fi
        cd ..
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

log_write "Deploy concluído com segurança!" "$UPDATE_LOG"
log_write "=============================================" "$UPDATE_LOG"

# ------------------------------------------------------
# 3️⃣ Resumo geral no terminal
# ------------------------------------------------------
echo "============================================="
echo "✅ Deploy completo concluído com sucesso!"
echo "📦 Backup de JS: $BACKUP_DIR/$TIMESTAMP"
echo "📝 Logs detalhados:"
echo "   - JS:   $SYNC_LOG"
echo "   - PHP:  $UPDATE_LOG"
echo "============================================="

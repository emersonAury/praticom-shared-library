#!/bin/bash
# ---------------------------------------------
# Script para atualizar PRATICOM shared-library
# Uso: ./update.sh "Mensagem do commit" "1.0.1"
# ---------------------------------------------

# Diretórios principais
ROOT_DIR="/e/Mega/PraticomAI"
LIB_DIR="$ROOT_DIR/praticom-shared-library"
API_DIR="$ROOT_DIR/api"
LOG_DIR="$ROOT_DIR/Logs"
LOG_FILE="$LOG_DIR/update_log.txt"

# Verifica se os parâmetros foram passados
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 \"Mensagem do commit\" \"Versão\""
    echo "Exemplo: $0 \"Adiciona nova classe\" \"1.0.1\""
    exit 1
fi

COMMIT_MESSAGE=$1
VERSION=$2
TAG="v$VERSION"

# Função de log (escreve no terminal e no arquivo)
log_write() {
    local TIMESTAMP
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    local LINE="[$TIMESTAMP] $1"
    echo "$LINE"
    echo "$LINE" >> "$LOG_FILE"
}

# Garante que o diretório de logs existe
mkdir -p "$LOG_DIR"

log_write "---------------------------------------------"
log_write "Iniciando atualização da biblioteca..."
log_write "Mensagem de commit: $COMMIT_MESSAGE"
log_write "Tag da versão: $TAG"
log_write "---------------------------------------------"

# 1️⃣ Vai para a pasta da shared-library
cd "$LIB_DIR" || exit

# Adiciona e commita mudanças
git add .
git commit -m "$COMMIT_MESSAGE"

# Envia para o GitHub
git push origin main

# Cria e envia a tag
git tag "$TAG"
git push origin "$TAG"

log_write "Biblioteca atualizada com sucesso!"

# 2️⃣ Atualiza TODOS os microserviços em api/
cd "$API_DIR" || exit

UPDATED=()
IGNORED=()

for dir in */ ; do
    if [ -f "$dir/composer.json" ]; then
        log_write "Atualizando microserviço: $dir"
        cd "$dir" || continue
        composer update praticom/shared-library
        cd ..
        UPDATED+=("$dir")
    else
        IGNORED+=("$dir")
    fi
done

# 3️⃣ Resumo final
log_write "============================================="
log_write "Resumo da atualização"

if [ ${#UPDATED[@]} -gt 0 ]; then
    log_write "✅ Microserviços atualizados:"
    for u in "${UPDATED[@]}"; do
        log_write "   - $u"
    done
else
    log_write "⚠️  Nenhum microserviço atualizado."
fi

if [ ${#IGNORED[@]} -gt 0 ]; then
    log_write "ℹ️  Microserviços ignorados (sem composer.json):"
    for i in "${IGNORED[@]}"; do
        log_write "   - $i"
    done
fi

log_write "Processo concluído!"
log_write "============================================="

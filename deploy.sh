#!/bin/bash
# ------------------------------------------------------
# DEPLOY - Deploy automático com Git integrado
# Faz commit automático + deploy completo em um comando
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
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 DEPLOY - Deploy Automático Completo"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 Uso: $0 \"Mensagem do commit\" \"Versão\""
    echo ""
    echo "📌 Exemplos:"
    echo "   $0 \"Adicionar dashboard\" \"1.0.5\""
    echo "   $0 \"Corrigir bugs\" \"1.0.6\""
    echo ""
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

# Banner inicial
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 DEPLOY - Deploy Automático Completo"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Commit: $COMMIT_MESSAGE"
echo "🏷️  Versão: $VERSION"
echo "⏰ Horário: $(date '+%d/%m/%Y %H:%M:%S')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Garante diretórios
mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR/$TIMESTAMP"

# ------------------------------------------------------
# ETAPA 1: Verificar e Commitar Git
# ------------------------------------------------------
echo "🔍 [1/4] Verificando Git..."
cd "$LIB_DIR" || exit

# Verifica se há alterações
if ! git diff-index --quiet HEAD --; then
    echo "📝 Alterações encontradas. Fazendo commit automático..."
    git add .
    
    if git commit -m "$COMMIT_MESSAGE"; then
        echo "✅ Commit realizado com sucesso!"
    else
        echo "ℹ️  Nenhuma alteração para commitar (arquivos já commitados)"
    fi
else
    echo "✅ Repositório já está limpo (nenhuma alteração pendente)"
fi

# Push para origin/main
echo "📤 Enviando para repositório remoto..."
if git push origin main; then
    echo "✅ Push realizado com sucesso!"
else
    echo "⚠️  Aviso: Push falhou ou não havia nada para enviar"
fi

# Criar e enviar tag
echo "🏷️  Criando tag $TAG..."
if git tag "$TAG" 2>/dev/null; then
    echo "✅ Tag criada!"
    if git push origin "$TAG" 2>/dev/null; then
        echo "✅ Tag enviada para repositório!"
    else
        echo "⚠️  Tag já existe no repositório remoto"
    fi
else
    echo "⚠️  Tag já existe localmente"
    # Tenta enviar mesmo assim
    git push origin "$TAG" 2>/dev/null && echo "✅ Tag enviada!" || echo "ℹ️  Tag já estava no remoto"
fi

log_write "Git: Commit '$COMMIT_MESSAGE' e tag $TAG processados" "$UPDATE_LOG"

# ------------------------------------------------------
# ETAPA 2: Sincronizar arquivos JS
# ------------------------------------------------------
echo ""
echo "📦 [2/4] Sincronizando arquivos JS..."
log_write "Iniciando backup e sincronização de JS..." "$SYNC_LOG"

# Função para sincronizar JS
sync_js_to_dir() {
    local TARGET_DIR=$1
    local SERVICE_NAME=$2
    
    local JS_DIR="$TARGET_DIR/_js"
    mkdir -p "$JS_DIR"
    
    local UPDATED=0
    for file in "$LIB_DIR"/resources/_js/*.js ; do
        BASENAME=$(basename "$file")
        
        # Backup (só faz uma vez)
        if [ ! -f "$BACKUP_DIR/$TIMESTAMP/$BASENAME" ]; then
            cp "$file" "$BACKUP_DIR/$TIMESTAMP/$BASENAME"
        fi
        
        # Copia somente se diferente
        if [ ! -f "$JS_DIR/$BASENAME" ] || ! cmp -s "$file" "$JS_DIR/$BASENAME"; then
            cp "$file" "$JS_DIR/$BASENAME"
            echo "  ✅ $BASENAME → $SERVICE_NAME"
            log_write "JS atualizado: $BASENAME -> $SERVICE_NAME/_js" "$SYNC_LOG"
            UPDATED=1
        fi
    done
    
    if [ $UPDATED -eq 0 ]; then
        echo "  ℹ️  $SERVICE_NAME (sem alterações)"
    fi
}

# Sincronizar para APIs
for dir in "$API_DIR"/*/ ; do
    if [ -d "$dir" ]; then
        SERVICE_NAME="api/_dist/$(basename "$dir")"
        sync_js_to_dir "$dir" "$SERVICE_NAME"
    fi
done

# Sincronizar para Dashboard
if [ -d "$DASHBOARD_DIR" ]; then
    sync_js_to_dir "$DASHBOARD_DIR" "dashboard"
fi

log_write "Backup criado em $BACKUP_DIR/$TIMESTAMP" "$SYNC_LOG"
log_write "Sincronização de JS concluída!" "$SYNC_LOG"

# ------------------------------------------------------
# ETAPA 3: Atualizar via Composer
# ------------------------------------------------------
echo ""
echo "🔄 [3/4] Atualizando via Composer..."

# Função para atualizar via composer
update_composer() {
    local DIR=$1
    local SERVICE_NAME=$2
    
    if [ -f "$DIR/composer.json" ]; then
        echo "  🔄 Atualizando $SERVICE_NAME..."
        cd "$DIR" || return 1
        if composer update praticom/shared-library --quiet 2>&1 | grep -q "Nothing to modify"; then
            echo "  ✅ $SERVICE_NAME (já atualizado)"
            log_write "✅ $SERVICE_NAME já estava atualizado" "$UPDATE_LOG"
        elif composer update praticom/shared-library --quiet; then
            echo "  ✅ $SERVICE_NAME atualizado!"
            log_write "✅ $SERVICE_NAME atualizado com sucesso" "$UPDATE_LOG"
        else
            echo "  ⚠️  $SERVICE_NAME (erro no update)"
            log_write "❌ Erro ao atualizar $SERVICE_NAME" "$UPDATE_LOG"
            cd - > /dev/null
            return 1
        fi
        cd - > /dev/null
        return 0
    else
        echo "  ⚠️  $SERVICE_NAME (sem composer.json)"
        log_write "⚠️ $SERVICE_NAME ignorado (sem composer.json)" "$UPDATE_LOG"
        return 1
    fi
}

# Contadores
UPDATED=()
FAILED=()

# Atualizar APIs
for dir in "$API_DIR"/*/ ; do
    if [ -d "$dir" ]; then
        SERVICE_NAME="api/$(basename "$dir")"
        if update_composer "$dir" "$SERVICE_NAME"; then
            UPDATED+=("$SERVICE_NAME")
        else
            FAILED+=("$SERVICE_NAME")
        fi
    fi
done

# Atualizar Dashboard
if update_composer "$DASHBOARD_DIR" "dashboard"; then
    UPDATED+=("dashboard")
else
    FAILED+=("dashboard")
fi

# ------------------------------------------------------
# ETAPA 4: Relatório Final
# ------------------------------------------------------
echo ""
echo "📊 [4/4] Gerando relatório..."

log_write "=============================================" "$UPDATE_LOG"
log_write "Resumo do Deploy" "$UPDATE_LOG"
log_write "Commit: $COMMIT_MESSAGE" "$UPDATE_LOG"
log_write "Versão: $TAG" "$UPDATE_LOG"

if [ ${#UPDATED[@]} -gt 0 ]; then
    log_write "✅ Serviços atualizados (${#UPDATED[@]}):" "$UPDATE_LOG"
    for u in "${UPDATED[@]}"; do
        log_write "   - $u" "$UPDATE_LOG"
    done
fi

if [ ${#FAILED[@]} -gt 0 ]; then
    log_write "⚠️  Serviços ignorados/falha (${#FAILED[@]}):" "$UPDATE_LOG"
    for i in "${FAILED[@]}"; do
        log_write "   - $i" "$UPDATE_LOG"
    done
fi

log_write "Deploy concluído!" "$UPDATE_LOG"
log_write "=============================================" "$UPDATE_LOG"

# ------------------------------------------------------
# Resumo Final no Terminal
# ------------------------------------------------------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DEPLOY COMPLETO CONCLUÍDO COM SUCESSO!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Resumo:"
echo "   🏷️  Tag: $TAG"
echo "   📦 Backup JS: $BACKUP_DIR/$TIMESTAMP"
echo "   ✅ Serviços atualizados: ${#UPDATED[@]}"
if [ ${#FAILED[@]} -gt 0 ]; then
    echo "   ⚠️  Serviços com problema: ${#FAILED[@]}"
fi
echo ""
echo "📝 Logs detalhados:"
echo "   - JS:  $SYNC_LOG"
echo "   - PHP: $UPDATE_LOG"
echo ""
echo "🎉 Tudo pronto! APIs e Dashboard atualizados."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

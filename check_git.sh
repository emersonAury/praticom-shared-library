#!/bin/bash
# Script para verificar e resolver o status do Git na shared-library

SHARED_LIB_DIR="/e/Mega/PraticomAI/praticom-shared-library"

echo "🔍 Verificando status do Git na shared-library..."
cd "$SHARED_LIB_DIR" || exit 1

echo ""
echo "📋 Status atual do Git:"
git status --porcelain

echo ""
echo "📝 Status detalhado:"
git status

echo ""
echo "🔧 Opções para resolver:"
echo "1️⃣  git add . && git commit -m 'Commit das alterações pendentes'"
echo "2️⃣  git stash (para guardar temporariamente)"  
echo "3️⃣  git reset --hard (para descartar alterações - CUIDADO!)"

echo ""
echo "💡 Executar automaticamente a opção 1? (y/n)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "📤 Fazendo commit das alterações..."
    git add .
    
    # Pede mensagem de commit
    echo "💬 Digite a mensagem do commit:"
    read -r commit_message
    
    if [ -z "$commit_message" ]; then
        commit_message="Alterações automáticas - $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    
    git commit -m "$commit_message"
    
    echo "✅ Commit realizado com sucesso!"
    echo "🚀 Agora pode executar o deploy normalmente."
else
    echo "ℹ️  Execute manualmente um dos comandos acima antes de rodar o deploy."
fi
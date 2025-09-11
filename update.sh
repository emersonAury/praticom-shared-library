#!/bin/bash
# ---------------------------------------------
# Script para atualizar PRATICOM shared-library
# Uso: ./atualizar_projeto.sh "Mensagem do commit" "1.0.1"
# ---------------------------------------------
set -x

# Verifica se os parâmetros foram passados
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 \"Mensagem do commit\" \"Versão\""
    echo "Exemplo: $0 \"Adiciona nova classe\" \"1.0.1\""
    exit 1
fi

COMMIT_MESSAGE=$1
VERSION=$2
TAG="v$VERSION"

echo "---------------------------------------------"
echo "Iniciando atualização da biblioteca..."
echo "Mensagem de commit: $COMMIT_MESSAGE"
echo "Tag da versão: $TAG"
echo "---------------------------------------------"

# 1️⃣ Vai para a pasta da shared-library
cd /e/Mega/PraticomAI/praticom-shared-library || exit

# Adiciona e commita mudanças
git add .
git commit -m "$COMMIT_MESSAGE"

# Envia para o GitHub
git push origin main

# Cria e envia a tag
git tag "$TAG"
git push origin "$TAG"

echo "---------------------------------------------"
echo "Biblioteca atualizada com sucesso!"
echo "---------------------------------------------"

# 2️⃣ Atualiza TODOS os microserviços em api/
cd ../api || exit

for dir in */ ; do
    if [ -f "$dir/composer.json" ]; then
        echo "Atualizando microserviço: $dir"
        cd "$dir" || continue
        composer update praticom/shared-library
        cd ..
    else
        echo "Ignorando $dir (não contém composer.json)"
    fi
done

echo "---------------------------------------------"
echo "Todos os microserviços foram atualizados!"
echo "Processo concluído!"
echo "---------------------------------------------"

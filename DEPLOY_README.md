# 🚀 Scripts de Deploy - Praticom Shared Library

## 📋 Scripts Disponíveis

### 1. **quick-deploy.sh** ⭐ (RECOMENDADO)
Deploy completo em um único comando - faz tudo automaticamente!

```bash
./quick-deploy.sh "Mensagem do commit" "1.0.5"
```

**O que faz:**
- ✅ Verifica alterações no Git
- ✅ Faz commit automático
- ✅ Envia para repositório remoto
- ✅ Cria e envia tag
- ✅ Sincroniza arquivos JS
- ✅ Atualiza via Composer
- ✅ Gera relatórios completos

### 2. **deploy.sh**
Deploy tradicional (requer Git limpo)

```bash
./deploy.sh "Mensagem do commit" "1.0.5"
```

**O que faz:**
- ⚠️  Exige que não haja alterações pendentes
- ✅ Faz commit e push
- ✅ Sincroniza JS
- ✅ Atualiza Composer

### 3. **update.sh**
Update mais simples

```bash
./update.sh "Mensagem do commit" "1.0.5"
```

### 4. **check_git.sh**
Verifica e resolve problemas de Git

```bash
./check_git.sh
```

---

## 🎯 Uso Rápido

### Cenário 1: Deploy rápido (MAIS COMUM)
```bash
cd praticom-shared-library
./quick-deploy.sh "Adicionar feature X" "1.0.5"
```

### Cenário 2: Verificar antes de fazer deploy
```bash
cd praticom-shared-library
./check_git.sh
./deploy.sh "Minha mensagem" "1.0.5"
```

### Cenário 3: Já fiz commit manualmente
```bash
cd praticom-shared-library
git add .
git commit -m "Minhas alterações"
./deploy.sh "Deploy da versão" "1.0.5"
```

---

## 📦 O que é distribuído

Os scripts sincronizam para:

```
praticom-shared-library/
    ├── resources/_js/          # Arquivos JavaScript
    └── src/                    # Classes PHP
            ↓ ↓ ↓
    ┌────────────────────────────────┐
    │  api/auth/_js/                 │
    │  api/outro-servico/_js/        │
    │  dashboard/_js/           ⭐NEW│
    └────────────────────────────────┘
```

**Via Composer:**
- `api/*/composer.json` → `praticom/shared-library`
- `dashboard/composer.json` → `praticom/shared-library` ⭐NEW

---

## 📝 Logs

Todos os deploys geram logs em:
- `Logs/sync_log.txt` - Sincronização de JS
- `Logs/update_log.txt` - Updates do Composer

## 💾 Backups

Backups automáticos dos arquivos JS em:
- `Backups/shared_js/YYYYMMDD_HHMMSS/`

---

## 🆘 Problemas Comuns

### "Alterações não commitadas"
```bash
# Solução rápida: use quick-deploy
./quick-deploy.sh "Minha mensagem" "1.0.5"

# Ou resolva manualmente
git add .
git commit -m "Minhas alterações"
./deploy.sh "Deploy" "1.0.5"
```

### "Tag já existe"
```bash
# Apague a tag local e remota
git tag -d v1.0.5
git push origin :refs/tags/v1.0.5

# Use uma nova versão
./quick-deploy.sh "Nova versão" "1.0.6"
```

### Composer não atualiza
```bash
# Force o update em um serviço específico
cd ../api/auth
composer update praticom/shared-library --with-all-dependencies

# Ou
cd ../dashboard
composer update praticom/shared-library --with-all-dependencies
```

---

## 🎨 Comparação dos Scripts

| Feature | quick-deploy.sh | deploy.sh | update.sh |
|---------|----------------|-----------|-----------|
| Commit automático | ✅ | ❌ | ❌ |
| Push automático | ✅ | ✅ | ✅ |
| Sincronização JS | ✅ | ✅ | ✅ |
| Update Composer | ✅ | ✅ | ✅ |
| Backup JS | ✅ | ✅ | ❌ |
| Interface bonita | ✅ | ⚠️ | ⚠️ |
| Requer Git limpo | ❌ | ✅ | ✅ |

---

## 💡 Dicas

1. **Use quick-deploy.sh sempre que possível** - é mais rápido e seguro
2. **Incremente a versão sempre** - v1.0.5 → v1.0.6 → v1.0.7
3. **Mensagens descritivas** - facilita rastrear mudanças depois
4. **Verifique os logs** - em caso de problemas

---

## 📌 Exemplos Reais

```bash
# Deploy de nova feature
./quick-deploy.sh "Adicionar validação de formulários" "1.1.0"

# Correção de bug
./quick-deploy.sh "Corrigir erro no login" "1.0.8"

# Atualização de segurança
./quick-deploy.sh "Patch de segurança XSS" "1.0.9"

# Nova funcionalidade major
./quick-deploy.sh "Implementar dashboard completo" "2.0.0"
```

---

✨ **Desenvolvido para PRATICOM - Distribuição inteligente de código!**

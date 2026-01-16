# n8n Proxmox AI Agent - Instrukcja użycia

## 📋 Wymagania

1. **n8n** zainstalowane i działające
2. **OpenAI API Key** (lub Gemini API)
3. **GitHub Personal Access Token** z uprawnieniami:
   - `repo` (pełny dostęp)
   - `workflow` (uruchamianie workflow)

## 🚀 Instalacja

### 1. Import workflow do n8n

1. Otwórz n8n
2. Kliknij **"+"** → **"Import from File"**
3. Wybierz plik `n8n-proxmox-ai-agent.json`
4. Workflow zostanie zaimportowany

### 2. Konfiguracja credentials

#### A. OpenAI API
1. W n8n przejdź do **Settings** → **Credentials**
2. Kliknij **"+ Add Credential"** → **"OpenAI"**
3. Wpisz swój **API Key**
4. Nazwij: `OpenAI API`
5. Zapisz

#### B. GitHub API
1. W n8n: **Settings** → **Credentials**
2. **"+ Add Credential"** → **"GitHub"**
3. Wybierz **"Access Token"**
4. Wklej swój **Personal Access Token**
5. Nazwij: `GitHub API`
6. Zapisz

#### Jak wygenerować GitHub Token:
```
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token (classic)
3. Zaznacz: repo, workflow
4. Wygeneruj i skopiuj token
```

### 3. Aktywacja workflow

1. Otwórz workflow w n8n
2. Kliknij **"Active"** w prawym górnym rogu
3. Skopiuj **Webhook URL** (z node'a "Webhook")

## 💬 Użycie

### Przez Webhook (curl):

```bash
# Stworzenie VM
curl -X POST https://your-n8n-instance.com/webhook/proxmox-agent \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Stwórz 3 maszyny AlmaLinux"
  }'

# Usunięcie VM
curl -X POST https://your-n8n-instance.com/webhook/proxmox-agent \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Usuń VM RedHat od 5 do 10"
  }'

# Monitoring
curl -X POST https://your-n8n-instance.com/webhook/proxmox-agent \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Potrzebuję serwer Grafana do monitoringu"
  }'
```

### Przykładowe komendy:

- ✅ "Stwórz 5 maszyn AlmaLinux"
- ✅ "Potrzebuję 3 VM z RedHat"
- ✅ "Usuń maszyny Alma od 10 do 15"
- ✅ "Zrób mi monitoring (Grafana)"
- ✅ "Usuń VM numer 7 z AlmaLinux"
- ✅ "Stwórz wszystkie maszyny RedHat"

## 🔧 Rozszerzenia workflow

### Dodanie Telegram bota:

1. Usuń node "Webhook"
2. Dodaj **"Telegram Trigger"**
3. Skonfiguruj Telegram Bot Token
4. Podłącz do "OpenAI Chat"

### Dodanie Slack:

1. Dodaj **"Slack Trigger"**
2. Skonfiguruj Slack App
3. Odpowiedzi będą wysyłane do Slacka

### Dodanie logowania do Google Sheets:

Po node'u "Format Response" dodaj:
1. **"Google Sheets"** node
2. Operacja: **"Append"**
3. Kolumny: timestamp, action, os_type, vm_range, status

### Dodanie powiadomień email:

Po node'u "Check Workflow Status" dodaj:
1. **"Send Email"** node
2. Wyślij status do admina

## 🛠️ Troubleshooting

### Problem: "OpenAI API error"
- Sprawdź czy API Key jest poprawny
- Sprawdź limity użycia API

### Problem: "GitHub API 401"
- Token musi mieć uprawnienia `repo` i `workflow`
- Sprawdź czy token nie wygasł

### Problem: "Workflow nie startuje"
- Upewnij się że webhook jest aktywny
- Sprawdź czy runner GitHub Actions działa

## 📊 Monitoring

Workflow loguje:
- ✅ Wszystkie zapytania użytkownika
- ✅ Odpowiedzi AI
- ✅ Status GitHub Actions
- ✅ Błędy i ostrzeżenia

Możesz dodać:
- **Google Sheets** dla historii
- **PostgreSQL** dla auditów
- **Prometheus/Grafana** dla metryk

## 🎯 Alternatywy dla OpenAI

Jeśli wolisz inne modele AI, zamień node "OpenAI Chat" na:

### Google Gemini:
```javascript
Node: @n8n/n8n-nodes-langchain.lmChatGoogleGemini
```

### Anthropic Claude:
```javascript
Node: @n8n/n8n-nodes-langchain.lmChatAnthropic
```

### Ollama (local):
```javascript
Node: @n8n/n8n-nodes-langchain.lmChatOllama
Model: llama3.2 lub mistral
```

## 📞 Support

W razie problemów:
1. Sprawdź logi w n8n (Executions)
2. Sprawdź GitHub Actions logs
3. Sprawdź Proxmox logs

---

Powodzenia! 🚀

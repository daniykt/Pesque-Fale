# Autenticação (JWT) e Armazenamento de Imagens (Cloudinary)

Este documento explica **duas tecnologias novas** que entraram no projeto no **4º semestre**, junto com a migração de React+Firebase para Flutter+API Node. Feito pra qualquer pessoa do time entender — mesmo quem não é dev.

> **Contexto rápido:**
> - **3º semestre (React):** autenticação via **Firebase Authentication**, imagens em **Firestore como base64**
> - **4º semestre (Flutter):** autenticação via **JWT próprio**, imagens em **Cloudinary como URLs**
>
> Essas duas mudanças foram planejadas na Task 0.1 (v2.0 da arquitetura) e são fundamentais pra migração fazer sentido.

---

# Parte 1 — Autenticação com JWT

## O que é JWT

**JWT** significa "JSON Web Token". É um crachá digital que a API entrega pro usuário depois que ele faz login. Toda vez que o app precisa fazer alguma coisa protegida (curtir, comentar, avaliar, editar perfil), envia esse crachá junto pra provar quem é.

Analogia real: você compra ingresso do cinema. A bilheteria confirma sua identidade uma vez, te dá uma pulseira que vale o dia inteiro. Você não precisa provar quem é pra cada sala de cinema — a pulseira fala por você. Se alguém pegar sua pulseira, pode entrar por você. Por isso a pulseira tem validade.

## Por que trocamos Firebase Auth por JWT no 4º semestre

**Firebase Auth (React 3º sem):**
- ✅ Fácil de configurar
- ❌ Amarra o projeto ao ecossistema Google inteiro
- ❌ Cobra dinheiro se o projeto passar de X usuários grátis
- ❌ Não temos controle sobre o que é retornado no token
- ❌ Não roda em qualquer servidor — só onde Firebase funciona

**JWT próprio (Flutter 4º sem):**
- ✅ Padrão da indústria — usado por 90% das APIs REST profissionais
- ✅ Grátis pra sempre — é só assinatura criptográfica
- ✅ Roda em qualquer lugar (Railway, Render, VPS, Docker)
- ✅ Controle total sobre o que vai no token
- ✅ Habilidade valorizada no mercado — Firebase Auth é "modo fácil", JWT é "modo profissional"

## Como funciona o fluxo de login

```
1. Usuário digita email + senha no app Flutter
2. App envia POST /v1/auth/login com { email, senha }
3. API valida no banco (bcrypt na senha_hash)
4. Se OK, API gera 2 tokens:
   - access_token (validade: 24h) — pra usar nas requests
   - refresh_token (validade: 30 dias) — pra renovar o access sem relogar
5. Tokens voltam pro app
6. App salva ambos localmente (flutter_secure_storage)
7. Toda request futura vai com header:
   Authorization: Bearer <access_token>
```

## Estrutura do access_token

Um JWT parece um monte de letra aleatória:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6InV1aWQtMTIzIiwiZW1haWwiOiJqb2FvQGVtYWlsLmNvbSJ9.abc123...
```

Mas é só um JSON codificado em Base64 com 3 partes separadas por `.`:

1. **Header** — diz "sou JWT com assinatura HS256"
2. **Payload** — dados do usuário (id, email, expiração)
3. **Assinatura** — hash HMAC usando `JWT_SECRET` do servidor

**A assinatura é o que impede falsificação.** Se alguém mudar o payload manualmente (ex: trocar `id` pra outro usuário), a assinatura não bate mais e a API rejeita.

## Quando o access_token expira (24h)

Passou 24h desde o login, o `access_token` fica inválido. O app tem duas opções:

**A) Renovar automaticamente** (padrão implementado):
- App detecta 401 UNAUTHORIZED
- Envia `refresh_token` pro endpoint `POST /v1/auth/refresh`
- Recebe `access_token` novo
- Repete a request original
- Usuário nem percebe

**B) Se o refresh_token também expirou (>30 dias):**
- App deleta tokens locais
- Redireciona pra tela de login
- Usuário digita email/senha de novo

## O que o time precisa saber (para não-devs também)

### Se você é dev backend/frontend:
- Nunca commite `JWT_SECRET` no Git — está em `.env`, e `.env` está no `.gitignore`
- Em produção, `JWT_SECRET` deve ser uma string longa aleatória (>32 chars). Em dev pode ser qualquer coisa
- Tokens ficam armazenados no Flutter em `flutter_secure_storage`, que usa Keychain (iOS) / Keystore (Android) / localStorage encriptado (web)

### Se você é designer/documentação:
- Você não precisa mexer com JWT — é infraestrutura invisível pro usuário final
- Só entenda que **login expira em 24h** — isso influencia UX (avisar usuário quando sessão termina, oferecer "manter conectado")

### Se você é do time (qualquer papel):
- Se ver mensagem "TOKEN_INVALIDO" ou "TOKEN_EXPIRADO" durante teste, é normal — só relogue
- Não compartilhe seu `access_token` em prints/screenshots públicos (parece letra aleatória, mas quem tiver ele consegue agir como você por 24h)

## Endpoints de autenticação

Todos definidos na Task 0.3 (Contrato de API):

| Método | Rota | O que faz |
|---|---|---|
| POST | `/v1/auth/cadastro` | Cria conta nova, retorna tokens |
| POST | `/v1/auth/login` | Loga usuário existente, retorna tokens |
| POST | `/v1/auth/refresh` | Renova access_token usando refresh_token |
| POST | `/v1/auth/logout` | Invalida refresh_token no servidor |

---

# Parte 2 — Armazenamento de Imagens com Cloudinary

## O que é Cloudinary

**Cloudinary** é um serviço externo especializado em armazenar e servir imagens/vídeos. Você faz upload da imagem uma vez, ele te devolve uma URL, e essa URL é acessível de qualquer lugar do mundo com velocidade otimizada.

Analogia: é como YouTube pra fotos. Você não guarda o vídeo do casamento no seu celular pra mostrar pros parentes — sobe no YouTube e manda o link. Cloudinary é a mesma ideia pra fotos de perfil, fotos de pesca, banners.

## Por que trocamos base64 no Firestore por Cloudinary no 4º semestre

**React 3º semestre — base64 no Firestore (o pior mundo possível):**
- ❌ Imagem de 500KB vira string de ~700KB no Firestore
- ❌ Documento fica pesado, download do post fica lento
- ❌ Firestore cobra por bytes armazenados — inflacionava custo
- ❌ Não dá pra otimizar imagem (redimensionar, comprimir)
- ❌ Foto de perfil de 4000x4000 baixava inteira pra mostrar avatar 40x40 pixels

**Cloudinary no 4º semestre — CDN dedicado:**
- ✅ Imagem fica em servidor otimizado (não infla o banco)
- ✅ **Transformações via URL** — mesma imagem em vários tamanhos sem reupload
- ✅ Formatos modernos automáticos (WebP em Android, AVIF quando suportado)
- ✅ Cache global — imagem baixa rápido de qualquer país
- ✅ Plano grátis: 25 GB storage + 25 GB de bandwidth/mês (mais que suficiente pro projeto acadêmico)
- ✅ Padrão da indústria — usado por Netflix, Airbnb, GitHub, dezenas de startups grandes

Essa migração está registrada como **decisão arquitetural na Task 0.1 v2.0** com esse aviso literal:

> "⚠️ Nunca aceitar base64 via JSON na API. Isso foi um problema herdado do Firestore atual e não deve ser replicado."

## Como funciona o fluxo de upload

```
1. Usuário escolhe foto no app Flutter (image_picker)
2. App envia POST multipart/form-data pra API
   POST /v1/usuarios/me/foto
   Content-Type: multipart/form-data
   Body: [arquivo binário]
3. API recebe o arquivo, autentica JWT, faz upload pro Cloudinary
4. Cloudinary devolve URL pública pra API
5. API salva essa URL no banco (coluna foto_perfil de usuarios)
6. API responde 200 com a URL:
   { "data": { "fotoPerfil": "https://res.cloudinary.com/..." } }
7. App usa essa URL pra exibir a foto
```

**Importante:** o Flutter **nunca** fala direto com Cloudinary. Só a API tem as credenciais (`API_KEY`, `API_SECRET`). Isso protege a conta e permite validação de arquivos antes do upload.

## Otimização automática via URL (o pulo do gato)

Depois que a imagem está no Cloudinary, dá pra mudar tamanho/formato só editando a URL. **Sem reupload.**

Exemplo:
```
Original:
https://res.cloudinary.com/xxx/image/upload/v123/fotos_perfil/abc.jpg

Avatar 56×56 otimizado:
https://res.cloudinary.com/xxx/image/upload/w_112,h_112,c_fill,q_auto,f_auto/v123/fotos_perfil/abc.jpg
```

Parâmetros comuns:
- `w_112` — largura 112 pixels
- `h_112` — altura 112 pixels
- `c_fill` — corta pra preencher (não distorce)
- `q_auto` — qualidade automática (Cloudinary escolhe)
- `f_auto` — formato automático (WebP em Chrome, AVIF em navegadores modernos)

**Ganho real:** avatar de perfil que antes baixava imagem 400×400 (~30KB) passa a baixar 112×112 (~6KB). 80% menos banda pra mostrar a mesma coisa.

No app, o arquivo `lib/core/utils/cloudinary_url.dart` tem helpers prontos:
- `CloudinaryUrl.avatar(url)` — otimiza pra avatar
- `CloudinaryUrl.coverCard(url)` — otimiza pra capa de card
- `CloudinaryUrl.detailFull(url)` — versão maior pra tela cheia

## Presets do backend (definidos pela API)

Quando o usuário faz upload, a API aplica algumas transformações antes de salvar:

| Tipo | Dimensões | Corte | Uso |
|---|---|---|---|
| **Foto de perfil** | 400×400 | Face-crop (foca no rosto) | Perfil, header |
| **Banner** | 1200×400 | Fill | Topo do perfil |
| **Foto de post** | 1200×1200 max | Limit (mantém proporção) | Feed |

Face-crop é um recurso mágico do Cloudinary: ele **detecta o rosto** na foto e recorta em volta dele. Se a pessoa manda foto tirada de longe, a API entrega uma foto de perfil centrada no rosto sem precisar recortar manualmente.

## O que o time precisa saber

### Se você é dev backend:
- 3 variáveis de ambiente essenciais em `.env`:
  ```
  CLOUDINARY_CLOUD_NAME=seu_cloud_name
  CLOUDINARY_API_KEY=sua_api_key
  CLOUDINARY_API_SECRET=seu_api_secret
  ```
- Todas ficam em `api/.env` (não subir pro Git)
- Cria conta grátis em https://cloudinary.com — os 3 valores aparecem no Dashboard
- Em dev, se essas variáveis estiverem vazias, upload de foto simplesmente não funciona (mas todo o resto do app roda normal)

### Se você é dev frontend:
- Nunca faça upload direto pro Cloudinary — sempre via API
- Use os helpers `CloudinaryUrl.avatar()` / `.coverCard()` / `.detailFull()` — nunca monte a URL na mão
- Se a URL vier `null` (usuário sem foto), tenha fallback visual (ícone genérico, círculo com inicial do nome, etc)

### Se você é designer:
- Não precisa se preocupar com Cloudinary — é infra invisível
- Só saiba que **imagens carregam rápido no app** por causa dessas otimizações
- Se especificar tamanhos de avatar/card no Figma, considera que a foto real será baixada nesse tamanho (não maior) — economiza banda do usuário

### Se você é documentação/QA:
- Se testar upload e a foto não aparecer, verifica se as 3 variáveis `CLOUDINARY_*` estão preenchidas em `.env`
- Cloudinary tem dashboard web onde dá pra ver todas as imagens do projeto — útil pra confirmar que upload funcionou

## Endpoints que usam Cloudinary

| Método | Rota | O que faz |
|---|---|---|
| POST | `/v1/usuarios/me/foto` | Upload de foto de perfil |
| POST | `/v1/usuarios/me/banner` | Upload de banner |
| POST | `/v1/publicacoes` (multipart) | Upload de foto do post |

---

# FAQ

### JWT vs Cloudinary — qual a relação?
Nenhuma direta. São duas ferramentas separadas que entraram juntas no 4º semestre:
- **JWT** = quem você é (autenticação)
- **Cloudinary** = onde suas fotos ficam (armazenamento)

Coloquei os dois no mesmo doc porque ambos são novidades do 4º sem e ambos exigem variáveis de ambiente em `.env`.

### Preciso pagar Cloudinary?
Não. Plano free serve pro projeto acadêmico inteiro. Só precisa se preocupar com custo se o projeto virar produto real com milhares de usuários.

### E se o JWT_SECRET vazar?
É como se alguém achasse a chave mestra do prédio. Consegue gerar tokens válidos pra qualquer usuário. Solução: trocar `JWT_SECRET` no servidor (invalida todos os tokens existentes — todos os usuários precisam relogar) e investigar como vazou.

Por isso `.env` **nunca** deve ir pro Git.

### Cloudinary substitui banco?
Não. Cloudinary só guarda **arquivos** (imagens/vídeos). Todos os outros dados (usuários, posts, comentários, avaliações) continuam no PostgreSQL. Cloudinary é complemento, não substituto.

### Se Cloudinary sair do ar, o app quebra?
Só a parte de imagens. Autenticação, feed, avaliações, chat — tudo continua funcionando. Os cards do feed vão aparecer sem foto (fallback visual entra no lugar). Isso é uma vantagem grande do modelo desacoplado.

### Como aprender mais?
- JWT: https://jwt.io (tem playground pra decodificar tokens)
- Cloudinary: https://cloudinary.com/documentation/image_transformations (transformações via URL)

---

# TL;DR

**JWT no 4º semestre:**
- Substituiu Firebase Auth do 3º sem
- Access token vale 24h, refresh vale 30 dias
- Token vai no header `Authorization: Bearer <token>`
- Nunca commite `JWT_SECRET` no Git
- Padrão da indústria, habilidade valorizada no mercado

**Cloudinary no 4º semestre:**
- Substituiu base64 no Firestore do 3º sem
- Fluxo: Flutter → API → Cloudinary → URL → banco
- Otimização automática de tamanho/formato via parâmetros na URL
- Plano free (25GB) sobra pro projeto
- 3 variáveis em `.env` (nunca commitar)
- Redução real de banda (~80% em avatares)

**Ambos são decisões arquiteturais registradas na Task 0.1 v2.0** — não são improviso, foram planejados desde a modelagem inicial da API pra deixar o projeto mais profissional e independente do ecossistema Google.

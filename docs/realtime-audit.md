# Auditoria do estado atual do Socket.IO — Pesque & Fale

> **Issue:** 9.6.1 (parent: #183 — Epic: Realtime global do aplicativo)
> **Branch:** `chore/9.6.1-auditoria-socket`
> **Data:** 24/10/2026
> **Autor:** Danilo da Silva Pereira (@daniykt)
> **Status:** somente leitura — nenhuma mudança de código foi feita nesta task

Este documento mapeia o uso atual de Socket.IO no monorepo Pesque & Fale (backend `api/` + Flutter `pesque_fale_app/`). Serve de linha de base pras sub-issues 9.6.2 a 9.6.6 da epic #183.

---

## 1. Visão geral da arquitetura atual

```
┌───────────────────────────────────────────┐
│  BACKEND (api/) — Node.js + Express       │
│                                           │
│  server.js                                │
│   ├─ http.createServer(app)               │
│   └─ new Server(server, { cors: '*' })    │
│       └─ initChatGateway(io)              │
│           └─ src/modules/chat/            │
│              chat.gateway.js              │
│              (ÚNICO ponto de uso de io)   │
└───────────────────────────────────────────┘
                     ▲
                     │  WebSocket (Socket.IO v4)
                     │  Auth via JWT no handshake.auth.token
                     ▼
┌───────────────────────────────────────────┐
│  FLUTTER (pesque_fale_app/)               │
│                                           │
│  lib/features/chat/data/                  │
│    chat_socket_service.dart               │
│    ├─ instanciado 1x POR TELA DE CHAT     │
│    ├─ connect() no initState              │
│    └─ dispose() no dispose do provider    │
│                                           │
│  Consumido APENAS por:                    │
│    lib/features/chat/providers/           │
│      chat_provider.dart                   │
│                                           │
│  socket_io_client: ^3.1.6                 │
└───────────────────────────────────────────┘
```

**Conclusão rápida:** o Socket.IO hoje serve exclusivamente à tela de conversa individual (`ChatPage`). Nenhum outro feature do app (feed, notificações, perfil, inbox, badges) usa realtime — todos dependem de polling HTTP ou refresh manual.

---

## 2. Backend — mapa completo

### 2.1 Arquivos envolvidos

| Arquivo | Responsabilidade |
|---|---|
| `api/src/server.js` | Instancia `http.Server` + `socket.io.Server`, chama `initChatGateway(io)` |
| `api/src/app.js` | Monta rotas REST (não toca em socket) |
| `api/src/modules/chat/chat.gateway.js` | **ÚNICO** arquivo que registra handlers de socket |
| `api/src/modules/chat/chat.routes.js` | REST: `GET /v1/chats` e `GET /v1/chats/:chatId/mensagens` (fallback) |
| `api/src/modules/notificacoes/notificacoes.helper.js` | `criarNotificacao()` — grava no BD, **não emite nada via socket** |

### 2.2 Configuração do servidor socket (`server.js`)

```js
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});
initChatGateway(io);
```

- Único gateway inicializado.
- CORS totalmente aberto (`origin: '*'`) — aceitável em dev, revisar antes de produção estável.
- Nenhum middleware global de socket além do que o gateway registra.

### 2.3 Autenticação do handshake (`chat.gateway.js`, linhas 50-61)

```js
io.use((socket, next) => {
  const token = socket.handshake.auth?.token;
  if (!token) return next(new Error('TOKEN_INVALIDO'));
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.usuario = decoded;  // { id, email } — payload do mesmo JWT da REST
    next();
  } catch {
    next(new Error('TOKEN_INVALIDO'));
  }
});
```

- JWT trafega em `handshake.auth.token` (padrão socket.io v3+), **não** em query string.
- O payload decodificado vira `socket.usuario` em todos os handlers.
- Falha silenciosa: cliente só recebe `connect_error` com mensagem `TOKEN_INVALIDO`.

### 2.4 Rooms

| Nome do room | Padrão | Quem entra | Quando entra |
|---|---|---|---|
| `<chatId>` | `${minUid}_${maxUid}` (uids ordenados alfabeticamente e concatenados com `_`) | Ambos participantes de uma conversa | Quando qualquer um dos dois emite `entrar_chat` |

**NÃO EXISTE** room pessoal por usuário (`user:${userId}` ou similar). Essa ausência é a causa raiz do bug reportado na #183: o backend não tem canal pra notificar um usuário sobre eventos **globais** (nova conversa recebida, notificação criada, etc.) — só sobre eventos **dentro de uma conversa já aberta**.

### 2.5 Eventos — mapa completo

#### Client → Server (handlers em `chat.gateway.js`)

| Evento | Payload | Linhas | O que faz |
|---|---|---|---|
| `entrar_chat` | `{ outroId: string }` | 68-108 | Valida mutual follow → cria chat se não existir → entra no room `<chatId>` → marca mensagens como vistas → emite `historico` pro próprio socket → emite `mensagens_vistas` pro room |
| `enviar_mensagem` | `{ texto: string }` | 111-128 | Insere mensagem no BD → emite `nova_mensagem` pro room `<chatId>` |
| `marcar_visto` | *(sem payload)* | 131-139 | `UPDATE mensagens SET status = 'visto'` → emite `mensagens_vistas` pro room |
| `digitando` | *(sem payload)* | 142-145 | Emite `outro_digitando` pros OUTROS do room (não pro próprio) |
| `parou_digitando` | *(sem payload)* | 148-151 | Emite `outro_parou_digitando` pros OUTROS do room |
| `disconnect` | *(automático)* | 153-155 | Só loga no console |

#### Server → Client (emits em `chat.gateway.js`)

| Evento | Direção | Payload |
|---|---|---|
| `historico` | `socket.emit` (1-to-1) | `{ chatId, mensagens: Mensagem[] }` |
| `nova_mensagem` | `io.to(chatId).emit` (room) | `Mensagem` formatada |
| `mensagens_vistas` | `io.to(chatId).emit` (room) | `{ chatId, porId }` |
| `outro_digitando` | `socket.to(chatId).emit` (room exceto self) | `{ userId }` |
| `outro_parou_digitando` | `socket.to(chatId).emit` (room exceto self) | `{ userId }` |
| `erro` | `socket.emit` (1-to-1) | `{ message, code? }` |

### 2.6 Formato padrão de `Mensagem`

```js
function _formatMensagem(m) {
  return {
    id: m.id,
    chatId: m.chat_id,
    userId: m.user_id,
    nome: m.nome,
    texto: m.texto,
    status: m.status,       // 'enviado' | 'visto'
    criadoEm: m.criado_em,
  };
}
```

### 2.7 Esquema das tabelas relevantes

(extraído de `api/db/migrations/001_schema_inicial.sql`)

```sql
CREATE TABLE chats (
  id             VARCHAR(255) PRIMARY KEY,  -- formato "<uuidA>_<uuidB>" ordenado
  participante_a UUID NOT NULL,
  participante_b UUID NOT NULL,
  criado_em      TIMESTAMP DEFAULT now(),
  CONSTRAINT chats_check CHECK (participante_a < participante_b)
);

CREATE TABLE mensagens (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id    VARCHAR(255) NOT NULL,
  user_id    UUID NOT NULL,
  nome       VARCHAR(100) NOT NULL,
  texto      TEXT NOT NULL,
  status     VARCHAR(20) DEFAULT 'enviado',  -- CHECK: 'enviado' | 'visto'
  criado_em  TIMESTAMP DEFAULT now()
);

CREATE TABLE notificacoes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  para        UUID NOT NULL,
  de_id       UUID,
  de          VARCHAR(100),
  de_username VARCHAR(50),
  tipo        VARCHAR(50) NOT NULL,  -- 'curtida' | 'comentario' | 'seguindo' | 'mensagem' | 'sistema'
  texto       TEXT,
  post_id     UUID,
  chat_id     VARCHAR(255),
  lida        BOOLEAN DEFAULT false,
  criado_em   TIMESTAMP DEFAULT now()
);
```

### 2.8 Pontos onde `criarNotificacao` é chamada hoje

Já são 3 lugares que gravam notificação no BD e **nenhum deles emite via socket**:

| Arquivo | Linha | Tipo da notificação |
|---|---|---|
| `src/modules/usuarios/usuarios.controller.js` | 206 | `seguindo` (follow / follow back) |
| `src/modules/comentarios/comentarios.controller.js` | 69 | `comentario` |
| `src/modules/curtidas/curtidas.controller.js` | 20 | `curtida` |

Nenhum deles tem acesso à instância `io` do socket. **Pra fazer realtime de notificações (sub-issue 9.6.4), vamos precisar expor `io` globalmente ou passar por um emitter helper.** Decisão arquitetural que fica pra 9.6.2.

---

## 3. Frontend — mapa completo

### 3.1 Dependência

```yaml
# pesque_fale_app/pubspec.yaml
socket_io_client: ^3.1.6
```

Nenhuma dependência nova será necessária em toda a epic #183.

### 3.2 Arquivos envolvidos

| Arquivo | Responsabilidade |
|---|---|
| `lib/features/chat/data/chat_socket_service.dart` | Wrapper fino sobre `io.Socket` — conecta, inscreve, emite, descarta |
| `lib/features/chat/providers/chat_provider.dart` | Único consumidor do `ChatSocketService` hoje |
| `lib/features/chat/providers/inbox_provider.dart` | Lista de conversas — **sem socket**, só busca HTTP no `initState` |
| `lib/features/chat/providers/badge_mensagens_provider.dart` | Badge de não-lidas do bottom nav — **polling de 30s** |
| `lib/features/notificacoes/providers/badge_notificacoes_provider.dart` | Badge de notificações — **polling de 30s** |
| `lib/core/router/main_shell.dart` | Dispara os polls dos 2 badges via `Timer.periodic(30s)` + no resume do app |

### 3.3 Configuração da conexão (`chat_socket_service.dart`)

```dart
_socket = io.io(
  AppConfig.apiBaseUrl.replaceFirst('/v1', ''),  // socket roda na raiz, REST sob /v1
  io.OptionBuilder()
    .setTransports(['websocket'])     // sem fallback pra long-polling
    .setAuth({'token': token})        // JWT no handshake.auth.token
    .enableForceNew()                 // nova conexão sempre
    .enableReconnection()             // auto-reconnect do pacote
    .setReconnectionDelay(2000)       // 2s entre tentativas
    .build(),
);
```

Observação sobre `enableForceNew()`: cada tela cria **uma conexão TCP nova**, não compartilha com outras instâncias. Isso é parte do problema — não existe conexão persistente a nível de usuário logado.

### 3.4 Padrão de ciclo de vida atual (anti-pattern a corrigir)

```
Usuário abre tela de chat com X
  └─ ChatPage.initState()
      └─ cria ChatSocketService
          └─ connect() → novo socket TCP + handshake JWT
              └─ ChatProvider.iniciar()
                  └─ emite 'entrar_chat'

Usuário sai da tela de chat
  └─ ChatPage.dispose()
      └─ ChatProvider.dispose()
          └─ socketService.dispose() → desconecta socket
```

**Consequência direta:** fora da `ChatPage`, o app está "mudo" pro backend. Nenhum evento chega. Isso é exatamente o bug descrito em #183.

### 3.5 Handlers registrados hoje (apenas no `chat_provider.dart`)

| Evento escutado | Reação |
|---|---|
| `connect` | Emite `entrar_chat` com `outroId` |
| `historico` | Popula `mensagens` + muda `status` pra `conectado` |
| `nova_mensagem` | Adiciona na lista + emite `marcar_visto` se recebida |
| `mensagens_vistas` | Atualiza status das próprias mensagens pra `visto` |
| `outro_digitando` | Mostra indicador |
| `outro_parou_digitando` | Esconde indicador |
| `erro` | Classifica em `semMutualFollow` ou `erroConexao` |
| `disconnect` | Muda status pra `erroConexao` se estava conectado |
| `connect_error` | Muda status pra `erroConexao` |

### 3.6 Como os badges funcionam HOJE (sem socket)

**`main_shell.dart`** (linhas 68-105):

```dart
// Timer.periodic a cada 30s dispara _atualizarBadge()
_timerBadge = Timer.periodic(
  MainShell.intervaloBadge,  // 30 segundos
  (_) => _atualizarBadge(),
);

// Também dispara no resume do app
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) _atualizarBadge();
}

void _atualizarBadge() {
  if (!mounted) return;
  if (_currentIndex != _alertasIndex) {
    context.read<BadgeNotificacoesProvider>().atualizar();  // GET /v1/notificacoes/nao-lidas
  }
  context.read<BadgeMensagensProvider>().atualizar();       // GET /v1/chats (full list)
}
```

**Problemas desse polling:**

1. **Latência de até 30s** — exatamente a origem do "parece que o app está quebrado" do público 40+.
2. **Chamada HTTP cara** em `BadgeMensagensProvider.atualizar()` — baixa toda a lista de conversas só pra contar quantas têm `naoLidas > 0`.
3. **Zero coordenação com `InboxProvider`** — se o usuário está na aba Chat, dois componentes diferentes fazem a mesma chamada `GET /v1/chats` com defasagem.
4. **Não detecta mudanças durante os 30s** — exatamente o cenário do bug.

### 3.7 Árvore de providers em `main.dart`

Providers já instanciados no `MultiProvider` global (relevantes pra epic):

```dart
Provider<ConversasRepository>.value(value: conversasRepository),
Provider<NotificacoesRepository>.value(value: notificacoesRepository),

ChangeNotifierProvider<BadgeNotificacoesProvider>(
  create: (ctx) => BadgeNotificacoesProvider(
    repository: ctx.read<NotificacoesRepository>(),
  )..atualizar(),
),
ChangeNotifierProvider<BadgeMensagensProvider>(
  create: (ctx) => BadgeMensagensProvider(
    repository: ctx.read<ConversasRepository>(),
  ),
),

// ⚠️ Falta: um RealtimeManager global que seja o único detentor da conexão socket.
// É o que a 9.6.2 vai introduzir aqui.
```

E o `InboxProvider` é instanciado **por rota** (não global):

```dart
'/chat': (context) => ChangeNotifierProvider<InboxProvider>(
  create: (ctx) => InboxProvider(repository: ctx.read<ConversasRepository>()),
  child: const InboxPage(),
),
```

Isso significa que o `InboxProvider` é destruído ao sair da aba Chat. **Pra 9.6.3 funcionar, o estado da lista precisa ser mantido em algo global ou re-sincronizado a cada entrada na aba** — decisão arquitetural que o `RealtimeManager` precisa resolver.

---

## 4. Fluxo do bug reportado em #183 (reproduzido)

```
┌──────────────────────────────────────────────────────────────┐
│  Cenário: Henrique segue Danilo e manda primeira mensagem    │
└──────────────────────────────────────────────────────────────┘

Henrique (app aberto na tela de chat com Danilo):
  1. emite 'entrar_chat' { outroId: Danilo }
  2. gateway cria o chat no BD (INSERT INTO chats ... ON CONFLICT DO NOTHING)
  3. Henrique entra no room <chatId>
  4. Henrique emite 'enviar_mensagem' { texto: "oi" }
  5. gateway INSERT na mensagens → io.to(chatId).emit('nova_mensagem', ...)
     ⚠️  Danilo NÃO está no room <chatId> → não recebe nada
     ⚠️  Nenhum outro evento é emitido

Danilo (app aberto na aba Chat / InboxPage):
  6. InboxProvider carregou a lista 1 vez quando entrou na aba (initState)
  7. BadgeMensagensProvider pode levar até 30s pra fazer o próximo poll
  8. ChatSocketService nem existe pra Danilo nesse momento
     (só é instanciado quando ele abre uma conversa individual)

Resultado:
  → InboxPage continua com lista desatualizada
  → Badge não sobe
  → Único jeito de ver: pull-to-refresh ou deslogar/logar
```

---

## 5. Problemas identificados (gaps que a epic #183 vai resolver)

| # | Problema | Sub-issue que resolve |
|---|---|---|
| P1 | Backend não tem conceito de "room pessoal" (`user:${userId}`) — só rooms de conversa | 9.6.2 (padrão) + 9.6.3 (chat) |
| P2 | Backend não emite nenhum evento quando uma conversa nova é criada | 9.6.3 |
| P3 | Backend não emite nenhum evento quando uma notificação é criada (os 3 pontos de `criarNotificacao`) | 9.6.4 |
| P4 | Frontend abre conexão socket **por tela de chat**, descarta ao sair → fora dessa tela o app está "mudo" | 9.6.2 (RealtimeManager singleton) |
| P5 | `InboxProvider` só carrega lista 1x no `initState` + refresh manual — sem canal realtime | 9.6.3 |
| P6 | Badges dependem de polling de 30s — latência percebida pelo usuário | 9.6.3 (chat) + 9.6.4 (notif) |
| P7 | `BadgeMensagensProvider.atualizar()` baixa a lista inteira de conversas pra contar não-lidas | 9.6.3 (incremento reativo em vez de recontagem) |
| P8 | `InboxProvider` é instanciado por rota (destruído ao sair da aba) — estado se perde | 9.6.3 (decidir: eleva pra global ou re-hidrata pelo RealtimeManager) |
| P9 | Perfil não atualiza contador de seguidores em tempo real | 9.6.5 |
| P10 | Feed exige pull-to-refresh pra ver novas publicações | 9.6.6 |

---

## 6. Decisões arquiteturais pendentes (pra discutir na 9.6.2)

Essas decisões saem desta auditoria e precisam ser definidas antes de escrever o `RealtimeManager`:

1. **Como expor `io` pros controllers REST que precisam emitir** (notificações, seguidores, feed)?
   Opções:
   - (a) `app.set('io', io)` + `req.app.get('io')` nos controllers
   - (b) Módulo singleton `src/config/socket-emitter.js` que o `server.js` configura
   - (c) EventBus interno Node.js + um listener centralizado no gateway

   **Preferência inicial do Danilo:** (b) — fica mais limpo que ter que puxar via `req.app`.

2. **Nome do room pessoal.**
   Proposta: `user:${userId}` — simples, previsível, zero colisão com `<chatId>` (que usa `_` como separador).

3. **Entrada no room pessoal.**
   Fazer no middleware de auth do socket (depois de `jwt.verify`) ou no `io.on('connection', ...)` com `socket.join('user:' + usuarioId)`? **Preferência:** no `connection` handler, mais explícito.

4. **Reconexão: refetch de quê?**
   O `RealtimeManager` precisa expor um callback `onReconnect` que cada provider assinante usa pra re-sincronizar o estado. Lista mínima:
   - `InboxProvider.refresh()` (chat)
   - `BadgeNotificacoesProvider.atualizar()` (notif)
   - `BadgeMensagensProvider.atualizar()` (badge chat)

5. **Preservar `chat_socket_service.dart` ou substituir?**
   Hoje ele é usado só pelo `ChatProvider`. **Decisão sugerida:** manter por enquanto, mas na 9.6.3 refatorar o `ChatProvider` pra consumir o `RealtimeManager` global, e **remover** o `ChatSocketService` quando não houver mais consumidor dele (evita duas conexões socket por usuário).

6. **Multi-dispositivo / múltiplos sockets por usuário.**
   Hoje `io.to('user:' + id)` entrega pra TODAS as abas/dispositivos abertos daquele usuário — é o comportamento desejado. Só documentar isso explicitamente.

---

## 7. Checklist de aceitação da 9.6.1

- [x] Arquivo `docs/realtime-audit.md` criado na raiz do repo ← este arquivo
- [x] Lista todos os eventos socket atuais com payload e direção (seção 2.5)
- [x] Lista todas as rooms com padrão de nome e critério de entrada (seção 2.4)
- [x] Diagrama (ascii-art) do fluxo de conexão (seção 1 e seção 4)
- [x] Seção "problemas identificados" apontando os gaps da epic 9.6 (seção 5)

---

## 8. Próximo passo

**Sub-issue 9.6.2** — criar o `RealtimeManager` singleton no Flutter, com base nas decisões da seção 6. É pré-requisito de todas as outras sub-issues.

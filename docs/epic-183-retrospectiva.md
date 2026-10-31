# Epic #183 — Realtime Global do Pesque & Fale: Retrospectiva Técnica Completa

> **Status:** ✅ Concluída em 27/10/2026
> **Branch base:** `dev`
> **Issues:** #183 (epic) + 9 sub-issues (#184, #206, #207, #208, #215, #217, #219, #209, #210)
> **Total de pontos:** 22
> **Autor da execução:** Danilo da Silva Pereira (@daniykt)
> **Período:** 24-27/10/2026
>
> Esse documento é a referência histórica da epic. Serve de onboarding
> pra quem for mexer em qualquer parte da camada de realtime no futuro.
> Lê o índice primeiro; só pula pra uma task específica se precisar
> entender a decisão arquitetural dela.

---

## Índice

1. [Resumo executivo](#1-resumo-executivo)
2. [Panorama da arquitetura final](#2-panorama-da-arquitetura-final)
3. [Decisões arquiteturais permanentes](#3-decisões-arquiteturais-permanentes)
4. [Convenções estabelecidas](#4-convenções-estabelecidas)
5. [Tasks em detalhe](#5-tasks-em-detalhe)
   - [9.6.1 — Auditoria do socket](#51-961--auditoria-do-socket)
   - [9.6.2 — RealtimeManager singleton](#52-962--realtimemanager-singleton)
   - [9.6.3 — Chat realtime (bug original)](#53-963--chat-realtime-bug-original)
   - [9.6.4 — Notificações realtime](#54-964--notificações-realtime)
   - [9.6.4.1 — ChatProvider migrado](#55-9641--chatprovider-migrado)
   - [9.6.4.2 — Race do chatId fixado](#56-9642--race-do-chatid-fixado)
   - [9.6.4.3 — Atrito visível na ressincronização](#57-9643--atrito-visível-na-ressincronização)
   - [9.6.5 — Seguidores em tempo real](#58-965--seguidores-em-tempo-real)
   - [9.6.6 — Chip "X novas publicações" no feed](#59-966--chip-x-novas-publicações-no-feed)
6. [Dívidas técnicas pós-epic](#6-dívidas-técnicas-pós-epic)
7. [Lições aprendidas (pros próximos refactors)](#7-lições-aprendidas-pros-próximos-refactors)
8. [Onde mexer quando](#8-onde-mexer-quando)

---

## 1. Resumo executivo

### O problema

Antes dessa epic, o Pesque & Fale só tinha realtime em UMA tela: a conversa
aberta no chat. Fora dela, o app estava "mudo" — notificações só apareciam
em polling de 30s, badges só atualizavam no reload, novas conversas não
apareciam até deslogar/logar, e o feed exigia pull-to-refresh.

O bug catalisador foi reportado em #183: Henrique seguiu Danilo e mandou
uma mensagem; Danilo estava com o app aberto na aba Chat; a conversa NÃO
apareceu até ele deslogar e logar. **Pra o público 40+ da COPEX, isso dá
a impressão de app quebrado.**

### A solução

Construção, em 9 tasks encadeadas, de uma camada de realtime global:

- Backend: módulo singleton `socket-emitter` que qualquer controller REST
  pode usar; rooms pessoais `user:<id>` que todos os sockets entram no
  handshake; eventos nomeados por domínio (`nova_conversa`,
  `nova_notificacao`, `conversa_lida`, `seguidor_adicionado`,
  `nova_publicacao_feed`, etc.)
- Frontend: `RealtimeManager` singleton no Flutter com UMA conexão socket
  por usuário logado, API `subscribe/unsubscribe/onReconnect/emit`,
  reconexão automática, contrato stateless de callbacks

### O resultado

| Área | Antes | Depois |
|---|---|---|
| Chat | Precisava deslogar pra ver conversa nova | Aparece em tempo real |
| Notificações | Polling 30s | Chegam na hora, badge sobe sozinho |
| Perfil próprio | Contador só atualizava com reload | Atualiza em tempo real |
| Feed Seguindo | Pull-to-refresh pra ver novas | Chip flutuante não interrompe leitura |
| Rooms conectadas | 1 por tela de chat aberta | 1 total por usuário |
| Polling HTTP de badges | 30s a cada 30s | 0 (eliminado) |

---

## 2. Panorama da arquitetura final

### Backend

```
┌────────────────────────────────────────────────────┐
│  BACKEND (api/) — Node.js + Express                │
│                                                    │
│  server.js                                         │
│   ├─ http.createServer(app)                        │
│   ├─ new Server(server, cors)                      │
│   ├─ socketEmitter.init(io)  ← fundação 9.6.2      │
│   └─ initChatGateway(io)                           │
│                                                    │
│  src/config/socket-emitter.js  (9.6.2)             │
│   └─ emitToUser(userId, evento, payload)           │
│                                                    │
│  src/modules/chat/chat.gateway.js                  │
│   ├─ io.use (handshake JWT)                        │
│   ├─ io.on 'connection'                            │
│   │  ├─ socket.join('user:<id>')  ← 9.6.2          │
│   │  └─ handlers:                                  │
│   │     ├─ entrar_chat                             │
│   │     ├─ enviar_mensagem  (+9.6.3 +9.6.4.2)      │
│   │     ├─ marcar_visto     (+9.6.4.1)             │
│   │     ├─ digitando, parou_digitando              │
│   │     └─ disconnect                              │
│                                                    │
│  Controllers REST (consumidores do emitter):       │
│   ├─ notificacoes.helper.js   → nova_notificacao   │
│   ├─ usuarios.controller.js   → seguidor_*         │
│   └─ publicacoes.controller.js → nova_publicacao_feed │
└────────────────────────────────────────────────────┘
                       ▲
                       │  Socket.IO v4
                       │  JWT no handshake.auth.token
                       │  Room pessoal: `user:<id>`
                       │  Room de conversa: `<uidA>_<uidB>` ordenado
                       ▼
┌────────────────────────────────────────────────────┐
│  FRONTEND (pesque_fale_app/) — Flutter             │
│                                                    │
│  main.dart — MultiProvider:                        │
│   ├─ AuthProvider                                  │
│   ├─ ProxyProvider<Auth, RealtimeManager>  ← 9.6.2 │
│   ├─ ProxyProvider2<Auth, Realtime,                │
│   │     NotificacoesProvider> ← 9.6.4              │
│   ├─ ProxyProvider<Notif, BadgeNotif> ← 9.6.4      │
│   ├─ ProxyProvider2<Auth, Realtime,                │
│   │     InboxProvider> ← 9.6.3                     │
│   ├─ ProxyProvider<Inbox, BadgeMensagens> ← 9.6.3  │
│   ├─ ProxyProvider2<Auth, Realtime,                │
│   │     PerfilProvider> ← 9.6.5                    │
│   └─ ProxyProvider2<Auth, Realtime,                │
│         FeedProvider> ← 9.6.6                      │
│                                                    │
│  lib/core/realtime/realtime_manager.dart (9.6.2)   │
│   ├─ Única conexão socket por usuário logado       │
│   ├─ subscribe/unsubscribe/onReconnect/            │
│   │  removerOnReconnect/emit                       │
│   ├─ Reconexão automática + callbacks de           │
│   │  re-sincronização                              │
│   └─ Contrato stateless pros callbacks             │
│                                                    │
│  Providers consumidores:                           │
│   ├─ InboxProvider — nova_conversa, nova_msg,      │
│   │   conversa_lida                                │
│   ├─ NotificacoesProvider — nova_notificacao       │
│   ├─ PerfilProvider (global) — seguidor_*          │
│   ├─ FeedProvider — nova_publicacao_feed           │
│   └─ ChatProvider — historico, nova_mensagem,      │
│       mensagens_vistas, outro_digitando,           │
│       outro_parou_digitando, erro                  │
└────────────────────────────────────────────────────┘
```

### Fluxo de dados (ex.: nova mensagem no chat)

```
A clica em B → ChatProvider.iniciar
  → RealtimeManager.subscribe(6 eventos)
  → RealtimeManager.emit('entrar_chat', {outroId: B})

Backend:
  → chat.gateway.entrar_chat handler
    → verificarMutualFollow(A, B)
    → obterOuCriarChat → chatId_AB
    → socket.join(chatId_AB)
    → socket.chatId = chatId_AB
    → marcarComoVistas(chatId_AB, A)
    → emit 'historico' ao socket
    → emit 'mensagens_vistas' no room do chat
    → emitirConversaLida(chatId_AB, A)  ← 9.6.4.1
      → emitToUser(A, 'conversa_lida', ...)
      → emitToUser(B, 'conversa_lida', ...)

A recebe 'historico' → _onHistorico popula tela
A digita + envia:
  → ChatProvider.enviarMensagem
  → RealtimeManager.emit('enviar_mensagem', {texto, chatId})

Backend:
  → chat.gateway.enviar_mensagem
    → validarChatSincronizado(socket, chatId)  ← 9.6.4.2
    → salvarMensagem no banco
    → contarMensagens(chatId) → 5
    → (não é 1ª mensagem)
    → emitToUser(A, 'nova_mensagem_em_conversa', ...)
    → emitToUser(B, 'nova_mensagem_em_conversa', ...)
    → io.to(chatId_AB).emit('nova_mensagem', ...)

B (em qualquer tela):
  → RealtimeManager recebe 'nova_mensagem_em_conversa' no user:B
  → InboxProvider._onNovaMensagemEmConversa atualiza preview + move topo

B em outra conversa não aberta no momento:
  → Se tiver tela do chat_AB aberta: ChatProvider.onNovaMensagem adiciona
  → Senão: só o InboxProvider reage

B que não está vendo chat_AB → badge sobe (via InboxProvider)
```

---

## 3. Decisões arquiteturais permanentes

Lista do que ficou como lei do projeto. Mexer sem entender bem **vai**
quebrar.

### D1. Única conexão socket por usuário logado

**Onde:** `RealtimeManager` singleton no `main.dart` como ProxyProvider.

**Por quê:** antes da epic, cada `ChatPage` abria um socket próprio com
`enableForceNew()`. Isso significava múltiplos handshakes JWT, múltiplos
rooms, overhead de conexões TCP. Pior: quando o usuário saía da tela, o
socket morria, então nada chegava fora da tela ativa.

**Agora:** `RealtimeManager` tem UMA conexão. Toda feature que precisa de
realtime chama `subscribe/unsubscribe/emit` nessa instância global.

### D2. Rooms pessoais `user:<id>` + rooms de conversa `<chatId>`

**Onde:** `chat.gateway.js` linha 103 (join automático).

**Por quê:** rooms pessoais permitem o backend "falar" com um usuário
específico independente de qual tela ele está vendo. Rooms de conversa
continuam existindo pros eventos escopados (ex.: `nova_mensagem` que só
quem está na tela do chat deve receber).

**Padrão de nomes:**
- `user:<uuid>` — prefixo `user:` + uuid do usuário
- `<uidMenor>_<uidMaior>` — ids dos 2 participantes do chat, ordenados
  alfabeticamente

### D3. Payloads sempre em camelCase

**Onde:** todo evento emitido pelo backend. Convenção da epic.

**Por quê:** o Flutter consome via `Notificacao.fromJson`, `Conversa.fromJson`
etc., que todos esperam camelCase. Padronizar o payload de evento com o
retorno REST evita "parsing paralelo" (dois jeitos de ler o mesmo dado).

### D4. Emits REST feitos via `socket-emitter.js`, não via `req.app.get('io')`

**Onde:** `src/config/socket-emitter.js`.

**Por quê:** o helper é um singleton inicializado no `server.js`. Qualquer
controller importa e usa `emitToUser(id, evento, payload)` sem precisar
puxar `io` do `req.app`. Isso:
- Permite emitir de helpers que não têm acesso a `req` (ex.: `criarNotificacao`)
- Facilita testes (um `jest.mock` cobre todos os controllers)
- Centraliza o acesso ao `io` — se um dia precisar logar/instrumentar, muda num lugar

### D5. Falha pós-sucesso é apenas log, nunca derruba a response

**Onde:** padrão aplicado em `chat.gateway.enviar_mensagem`,
`criarNotificacao`, `seguir`, `deixarDeSeguir`, `publicacoes.criar`,
`marcar_visto`.

**Por quê:** depois que o banco commitou (INSERT, UPDATE, DELETE), qualquer
erro subsequente (contagem, emit socket, query de dados derivados) é
problema OPERACIONAL, não DO CLIENTE. Repropagar o erro faria o cliente
achar que a operação não aconteceu — quando aconteceu.

**Formato padrão:**

```js
let resultado;
try {
  resultado = await operacaoCritica();
} catch (err) {
  console.error(err);
  return res.status(500).json(...);
}

// A partir daqui, o banco já persistiu. Erros são só log.
try {
  // emits, queries derivadas, etc.
} catch (err) {
  console.error('[módulo] erro pós-sucesso:', err);
}

// Sempre acontece — resposta de sucesso.
return res.json(...);
```

### D6. Contrato stateless de callbacks do RealtimeManager

**Onde:** dartdoc do `RealtimeManager`, aplicado em `InboxProvider`,
`NotificacoesProvider`, `PerfilProvider`, `FeedProvider`.

**Por quê:** o manager preserva as assinaturas entre logout/login (pra que
badges globais não precisem re-assinar). Se um callback capturasse
`userId` no closure, ao trocar de conta ele ficaria apontando pro `userId`
antigo.

**Regra:** callbacks passados pra `subscribe` e `onReconnect` NÃO podem
capturar no closure dados do usuário logado. Devem reagir ao payload do
evento ou ler estado do `AuthProvider` no momento em que rodam.

**Padrão de implementação:** cada provider que precisa saber "quem sou"
guarda `_meuId` como **campo da instância** (não closure), atualizado no
`reagirAuth`.

### D7. `lazy: false` em ProxyProviders que escutam eventos

**Onde:** `RealtimeManager`, `InboxProvider`, `NotificacoesProvider`,
`PerfilProvider`, `FeedProvider` no `main.dart`.

**Por quê:** Provider do pacote `provider` é lazy por padrão — o `create`
só roda quando alguém faz `context.read`. Mas providers que precisam
RECEBER eventos independente de alguém ler (ex.: enquanto o usuário está
em outra aba) precisam existir desde o login.

**Regra prática:** se o provider tem `subscribe` no construtor, usa
`lazy: false`.

### D8. Dedupe por id em prepends otimistas

**Onde:** `InboxProvider._onNovaConversa` (verifica `_todas.any((c) => c.id == conversaId)`),
`FeedProvider.aplicarPendentesSeguindo` (filtro `!idsAtuais.contains(p.id)`).

**Por quê:** prepend otimista + resposta HTTP paralela + reconexão + eventos
duplicados por race = múltiplos caminhos pra o mesmo item entrar na lista.
Dedupe por id é o padrão correto — não assume ordem, não assume unicidade
na fonte.

### D9. Geração (`_geracao`) pra descartar respostas de conta anterior

**Onde:** `InboxProvider`, `NotificacoesProvider`, `FeedProvider` (via
cache de usuario comparado por `_meuId`).

**Por quê:** quando usuário faz logout no meio de uma request HTTP, a
response pode chegar com dados da conta anterior e sobrepor estado da
conta nova. Guard por `_geracao` descarta a response antiga.

**Padrão:** incrementar `_geracao` em `resetar()`; cada método async
captura o `_geracao` no início e descarta a resposta se mudou no fim.

### D10. Validação de `chatId` nos emits de chat

**Onde:** `chat.gateway.js` helper `validarChatSincronizado`.

**Por quê:** 9.6.4.2 fechou. Com UM socket global por usuário, dois
`entrar_chat` em sucessão rápida podem resolver fora de ordem no backend
e deixar `socket.chatId` com o chat errado. Cliente envia `chatId` esperado
no payload de `enviar_mensagem`/`marcar_visto`/`digitando`/`parou_digitando`
e o backend valida.

**Comportamento em mismatch:** backend emite `erro { code: 'CHAT_FORA_DE_SINCRONIA' }`,
cliente reemite `entrar_chat` em silêncio pra ressincronizar.

### D11. Preserva assinaturas entre logout/login

**Onde:** `RealtimeManager._desconectar` (não limpa `_assinantes` nem
`_callbacksReconexao`).

**Por quê:** se cada troca de conta forçasse os providers globais a
re-assinar, a UX teria eventos perdidos durante o re-handshake. Preservar
+ reaplicar no socket novo é o que elimina essa janela.

**Consequência:** reforça o contrato D6 (callbacks stateless).

---

## 4. Convenções estabelecidas

Padrões que não são decisões arquiteturais mas que ficam como "o jeito do
projeto".

### C1. Nomes de eventos

**Server → Client:**
- `nova_<entidade>` para criação (`nova_conversa`, `nova_mensagem`,
  `nova_mensagem_em_conversa`, `nova_notificacao`, `nova_publicacao_feed`)
- `<entidade>_<ação>` para mudanças de estado (`conversa_lida`,
  `mensagens_vistas`, `seguidor_adicionado`, `seguidor_removido`)
- `erro` genérico com `code` opcional (`CHAT_CONSIGO_MESMO`,
  `CHAT_FORA_DE_SINCRONIA`)

**Client → Server:**
- Verbo no infinitivo (`entrar_chat`, `enviar_mensagem`, `marcar_visto`,
  `digitando`, `parou_digitando`)

Snake_case nos nomes de eventos (`nova_conversa`), camelCase dentro do
payload (`conversaId`, `remetenteId`).

### C2. Testes

**Backend (`npm test` com Jest):**
- Suíte principal por módulo (`chat.test.js`, `notificacoes.test.js`)
- Suíte específica de realtime quando aplicável (`chat-gateway-eventos.test.js`,
  `notificacoes-realtime.test.js`, `seguidores-realtime.test.js`,
  `publicacoes-realtime.test.js`)
- Mock do `socket-emitter` por `jest.mock('../src/config/socket-emitter', ...)`

**Frontend (`flutter test`):**
- `FakeRealtimeManager` em `test/features/chat/support/` reutilizado por
  todos os testes de provider com realtime
- Testes de widget pra componentes com estado (`InputMensagem`,
  `NovasPublicacoesButton`)
- Testes de regressão invertidos: quando o comportamento muda, substitui
  o teste antigo pelo novo que valida o comportamento novo

**Teste manual com 2 contas:**
- Sempre bloqueador do push
- Mínimo: cenário do bug principal + 1 cenário de regressão

### C3. Mensagens de commit

- `feat:`, `fix:`, `refactor:`, `docs:`, `chore:` em pt-BR
- Corpo detalhado explicando o PORQUÊ, não só o quê
- Final sempre com `Closes #<issue>` + `Refs #183`
- Sem assinatura do Claude Code

### C4. Branches

- Padrão: `<tipo>/<numero>-<slug-curto>` (ex.: `fix/9.6.4.2-race-chatid`)
- Sempre a partir de `dev`
- PRs sempre pra `dev`, nunca pra `main`
- 1 PR por sub-issue (não agrupar)

### C5. Documentação

- `docs/realtime-events.md` — catálogo canônico de todos os eventos
  (atualizar a cada nova sub-issue que introduza evento)
- `docs/realtime-audit.md` — foto do estado pré-epic, mantida como
  referência histórica (não atualizar)
- Este arquivo (`docs/epic-183-retrospectiva.md`) — fechado quando a epic
  mergeou

---

## 5. Tasks em detalhe

### 5.1 9.6.1 — Auditoria do socket

**Issue:** #184 (criada depois pra formalizar) · **Branch:** `chore/9.6.1-auditoria-socket`
· **Pontos:** 2 · **Tipo:** chore + docs

#### Objetivo

Mapear o estado atual do socket.io no monorepo antes de qualquer mudança.
Documentar causa raiz do bug #183 e identificar os gaps que as próximas
sub-issues precisam fechar.

#### O que mudou

- Novo arquivo `docs/realtime-audit.md` (8 seções, ~400 linhas)
- Zero código tocado

#### Descobertas-chave

1. **O backend não tinha conceito de "room pessoal"** — só `<chatId>`. Fora
   de uma conversa aberta, o backend não tinha como notificar nada
2. **`criarNotificacao` é chamada em 3 lugares** (seguir, comentar, curtir)
   e nenhum emitia via socket
3. **Frontend abria conexão socket NOVA por tela de chat** (`enableForceNew()`).
   Fora da tela, zero socket ativo
4. **Dois diretórios de notificação no Flutter** (`features/notificacao/`
   vazio e `features/notificacoes/` populado) — lixo de refatoração
5. **`BadgeMensagensProvider.atualizar()` baixava a lista inteira de
   conversas a cada 30s** só pra contar não-lidas. Pesado.
6. **`InboxProvider` instanciado por rota**, não globalmente — era
   destruído ao sair da aba Chat

#### Lições pra o futuro

- Toda refatoração grande começa com auditoria dedicada. Vale os 2 pontos.
- O que você descobre na auditoria dita as decisões arquiteturais das
  próximas tasks

---

### 5.2 9.6.2 — RealtimeManager singleton

**Issue:** #206 · **Branch:** `feat/9.6.2-realtime-manager` · **Pontos:** 3 · **Tipo:** feat

#### Objetivo

Criar a fundação de realtime: uma única conexão socket por usuário logado,
gerenciada globalmente, consumida por qualquer feature via API uniforme
`subscribe/unsubscribe/onReconnect/emit`.

#### O que mudou

**Backend:**
- `api/src/config/socket-emitter.js` (novo) — `init(io)` + `emitToUser(userId, evento, payload)`
- `api/src/server.js` — plugar `socketEmitter.init(io)` antes de `initChatGateway(io)`
- `api/src/modules/chat/chat.gateway.js` — `socket.join('user:' + usuarioId)` no handler de `connection`

**Frontend:**
- `lib/core/realtime/realtime_manager.dart` (novo)
- `lib/main.dart` — `ChangeNotifierProxyProvider<AuthProvider, RealtimeManager>`
  com `lazy: false`

#### Decisões arquiteturais tomadas aqui

- D1 (única conexão), D2 (rooms), D4 (socket-emitter), D6 (contrato stateless),
  D7 (lazy: false), D11 (preservar assinaturas no logout)

#### Bugs descobertos (durante implementação)

1. **`enableForceNew()` é obrigatório** — sem ele, o `socket_io_client` 3.1.6
   compara path da URL com namespace, a comparação nunca bate, e a lib
   devolve o socket cacheado com `auth` da sessão ANTERIOR. Resultado: no
   logout + login com outra conta, o socket conectava com o token velho.
   Esse bug era silencioso e grave (dados de A vazariam pra B).

2. **`lazy: false` é mandatório** — `Provider` é lazy por padrão, então
   sem a flag o `RealtimeManager` nunca seria instanciado (ninguém o lia
   no primeiro frame), e o socket nunca conectaria no login.

3. **`removerOnReconnect` precisou ser adicionado como mini-fix** — API
   assimétrica (tinha `onReconnect` mas não como remover) causaria memory
   leak em providers de rota.

#### Commits principais

- `c55842b feat: adiciona RealtimeManager singleton e emitter socket global`
- `95f1e5b feat: adiciona removerOnReconnect e documenta contrato de callbacks`

---

### 5.3 9.6.3 — Chat realtime (bug original)

**Issue:** #207 · **Branch:** `fix/9.6.3-chat-realtime` · **Pontos:** 3 · **Tipo:** fix

#### Objetivo

**Essa é a task que resolve o bug reportado em #183.** Henrique segue
Danilo, manda mensagem; Danilo com app aberto na aba Chat vê a conversa
aparecer sem deslogar/logar.

#### O que mudou

**Backend:**
- `chat.gateway.js` handler `enviar_mensagem`:
  - Detecta primeira mensagem via `contarMensagens(chatId)` após o insert
  - Se é primeira, emite `nova_conversa` nos rooms pessoais de ambos
  - Sempre emite `nova_mensagem_em_conversa` nos rooms pessoais de ambos
  - Mantém o `nova_mensagem` existente no room `<chatId>` (serve à tela aberta)

**Frontend:**
- `conversa.dart` — adiciona `copyWith` cirúrgico (3 campos: ultimaMensagem, ultimaMensagemEm, naoLidas)
- `inbox_provider.dart` — refatoração grande: vira global, assina 2 eventos + onReconnect, guarda `_meuId` + `_geracao`
- `badge_mensagens_provider.dart` — deixa de fazer polling, deriva do `InboxProvider` via `addListener`
- `main.dart` — `ProxyProvider2<AuthProvider, RealtimeManager, InboxProvider>` + `ProxyProvider<InboxProvider, BadgeMensagensProvider>`
- `main_shell.dart` — remove polling do badge chat
- `inbox_page.dart` — vira `StatelessWidget`, remove `initState`

#### Decisões arquiteturais tomadas aqui

- D3 (payloads camelCase), D5 (falha pós-sucesso), D8 (dedupe), D9 (geração)

#### Bugs descobertos (durante implementação)

1. **"Para `nova_conversa` do próprio remetente, `refresh()` em vez de
   construir Conversa"** — o payload traz dados do remetente, mas o "outro"
   da conversa é o destinatário. Montar uma Conversa com dados do
   próprio usuário colocaria ele mesmo como "outro".

2. **"Primeira mensagem contava duas vezes"** — chegava `nova_conversa` com
   `naoLidas: 1` e logo depois o preview da mesma mensagem, que somaria +1.
   Fix: ignorar preview quando timestamp não é mais novo que o conhecido.

3. **Erro pós-insert deixava mensagem "fantasma"** — se qualquer query
   subsequente ao salvarMensagem falhasse, backend emitia `erro` pro
   cliente mesmo com mensagem já salva no banco. Fix via commit adicional
   isolou try/catch pós-insert. **Estabeleceu o padrão D5.**

#### Teste de regressão de ouro

Em `test/features/chat/presentation/inbox_page_test.dart`, foi criado um
teste que reproduz exatamente o cenário do bug original da #183. Qualquer
mexida na `InboxPage` ou no `InboxProvider` que quebre esse teste é
regressão imediata.

#### Commits principais

- `23852a0 fix: adiciona realtime na lista de conversas e no badge de chat`
- `a706f01 fix: isola erro pós-insert pra não derrubar mensagem já salva`

---

### 5.4 9.6.4 — Notificações realtime

**Issue:** #208 · **Branch:** `feat/9.6.4-notificacoes-realtime` · **Pontos:** 3 · **Tipo:** feat

#### Objetivo

Curtidas, comentários e follows chegam no destinatário em tempo real.
Badge do bottom nav sobe sem polling.

#### O que mudou

**Backend:**
- `criarNotificacao` helper (único lugar) emite `nova_notificacao` após
  o INSERT no banco, com payload no shape do `_format` do controller
- Query que busca os campos derivados (`deFoto`, `jaSigoDe`) idêntica à
  do controller — garante que o payload do evento bate byte a byte com
  o que o REST retorna

**Frontend:**
- `NotificacoesProvider` sobe pra global no `main.dart` (antes vivia dentro
  do `MainShell`)
- Assina `nova_notificacao` + `onReconnect`
- `BadgeNotificacoesProvider` deixa de fazer polling, deriva do
  `NotificacoesProvider` via `addListener`
- `main_shell.dart` — remove polling + remove criação local do provider;
  o `_timerBadge` e o `WidgetsBindingObserver` saíram inteiros
- `notificacoes_page.dart` — adiciona set `_vistas` separado de `lida`
  (persistência vs UX, dois conceitos distintos)

#### Decisões arquiteturais tomadas aqui

Reforço de D3, D5, D7, D8, D9. **Zero decisão nova** — a fundação da 9.6.2
e os padrões da 9.6.3 cobriam tudo.

#### Bugs descobertos (durante implementação)

1. **"Tudo seria marcado como lido no login"** — `carregar()` embutia
   `marcarTodasComoLidas`. Com provider global, `reagirAuth` chama
   `carregar()` no login → marca tudo lido sem usuário abrir Alertas.
   Fix: separar `carregar()` puro de `carregar(marcarComoLidas: true)`.

2. **"Badge voltaria a subir"** — `lida` fica `false` localmente de
   propósito pra highlight visual. Badge contando `!lida` subiria de novo
   a cada `notifyListeners`. Fix: set `_vistas` separado, badge conta
   `!lida && !vistas`.

3. **UX descoberto no teste manual** — se chega notificação com aba
   Alertas ativa, badge sobe pra 1 até usuário sair/voltar. Virou escopo
   da 9.6.4.1.

#### Commit principal

- `4c2b210 feat: adiciona realtime nas notificações e no badge de alertas`

---

### 5.5 9.6.4.1 — ChatProvider migrado

**Issue:** #215 · **Branch:** `refactor/9.6.4.1-chatprovider-realtime` · **Pontos:** 3 · **Tipo:** refactor

#### Objetivo

Fechar 4 dívidas técnicas acumuladas:
1. `ChatProvider` migra pro `RealtimeManager` (mata `ChatSocketService`)
2. Backend emite `conversa_lida` após `marcar_visto` e `entrar_chat`
3. `InboxPage.onTap` remove o `refresh()` manual
4. UX: `NotificacoesPage` com aba ativa marca novas como vistas

Marco histórico: depois dessa, o `RealtimeManager` vira o ÚNICO canal
socket do app.

#### O que mudou

**Backend:**
- `chat.gateway.js`:
  - Helper `emitirConversaLida(chatId, leitorId)` com try/catch próprio
  - Chamado após `marcarComoVistas` tanto no `entrar_chat` quanto no `marcar_visto`
  - Evento `conversa_lida` emitido nos rooms pessoais de AMBOS participantes

**Frontend:**
- `RealtimeManager` ganha `emit(evento, payload)` público com dartdoc
  explicando o contrato (no-op se desconectado, não enfileira)
- `ChatProvider` refatorado:
  - Recebe `RealtimeManager` em vez de `ChatSocketService`
  - Guarda `_chatIdAtivo` interno, handlers filtram por ele
  - Escuta `realtime.addListener` pra reagir a conexão/desconexão
  - Reemite `entrar_chat` sempre que `conectado` vira `true` (cobre
    primeira conexão E reconexão com UM caminho só)
- `ChatPage` — remove `TokenStorage` + `_ChatIndisponivel`
- `chat_socket_service.dart` deletado
- `InboxProvider` escuta `conversa_lida` → zera `naoLidas` da conversa
- `InboxPage.onTap` remove `provider.refresh()`
- `NotificacoesPage` escuta provider enquanto `ativa == true`, marca novas
  como vistas

#### Decisões arquiteturais tomadas aqui

- API `emit()` do manager documentada como contrato público
- Mesma convenção stateless D6 aplicada ao `ChatProvider` (via `_chatIdAtivo`)

#### Bugs descobertos (durante implementação)

1. **`historico` precisava de filtro adicional** — o filtro por `chatId`
   ignorava eventos de outras conversas, mas o `historico` chega sem o
   `_chatIdAtivo` ter sido setado ainda. Fix: filtrar por `outroId` estar
   presente no `chatId`.

2. **Idempotência do reemit em `_onErro`** — se backend continuar
   respondendo erro, cliente podia loopar. Decidido manter sem backoff
   (cenário raro, dor de cabeça só pós-COPEX).

#### Riscos levantados (viraram 9.6.4.2 e 9.6.4.3)

1. **Socket global não sai dos rooms de conversas antigas** (sem evento
   `sair_chat` no backend) — issue de follow-up pós-COPEX
2. **Race do `socket.chatId`** — bug REAL de corrupção de dados, virou 9.6.4.2
3. **Perda silenciosa em race** — virou 9.6.4.3

#### Commit principal

- `65f8c39 refactor: migra ChatProvider pro RealtimeManager e fecha dívidas de chat`

---

### 5.6 9.6.4.2 — Race do chatId fixado

**Issue:** #217 · **Branch:** `fix/9.6.4.2-race-chatid` · **Pontos:** 2 · **Tipo:** fix

#### Objetivo

Fechar bug de corrupção de dados introduzido pela 9.6.4.1: dois `entrar_chat`
em sucessão rápida resolvem fora de ordem no backend por race de query
lenta de mutual follow. `socket.chatId` fica com chat antigo; mensagem
subsequente é salva no chat ERRADO.

#### O que mudou

**Backend:**
- Helper `validarChatSincronizado(socket, chatIdDoPayload)` novo
- Handlers `enviar_mensagem`, `marcar_visto`, `digitando`, `parou_digitando`
  passam a aceitar `chatId` opcional no payload
- Se `chatId` do payload bate com `socket.chatId`, prossegue
- Se não bate, emite `erro { code: 'CHAT_FORA_DE_SINCRONIA' }` sem persistir nada
- Compatibilidade: payload sem `chatId` continua aceito (nenhum rolling
  update necessário)

**Frontend:**
- `ChatProvider` passa a enviar `chatId` em todos os emits DEPOIS que
  `_chatIdAtivo` foi setado (após `historico`)
- Emits antes do `_chatIdAtivo` são no-op (janela de milésimos)
- `_onErro` detecta `CHAT_FORA_DE_SINCRONIA` e reemite `entrar_chat` em
  silêncio

#### Decisões arquiteturais tomadas aqui

- D10 (validação de chatId)
- Code `CHAT_FORA_DE_SINCRONIA` catalogado em `realtime-events.md`

#### Limitação conhecida

**Perda silenciosa de mensagem** — se usuário envia mensagem em <300ms
após trocar de conversa, backend rejeita, cliente reemite `entrar_chat`,
mas a mensagem rejeitada **não é persistida nem fica em fila**. Vira
"usuário acha que mandou mas não mandou".

Isso é cenário extremamente raro (público 40+ não digita tão rápido), mas
virou 9.6.4.3 pra fechar via UX.

#### Teste de regressão de ouro

`chat-gateway-eventos.test.js` tem um teste que **mocka `verificarMutualFollow`
com delay diferente** pros dois `entrar_chat` → simula a race → confirma
que a mensagem com `chatId` do 2º é rejeitada (ao invés de salvar no chat
do 1º, que seria corrupção).

#### Commit principal

- `8636321 fix: valida chatId em emits do chat pra evitar race do socket.chatId`

---

### 5.7 9.6.4.3 — Atrito visível na ressincronização

**Issue:** #219 (título atualizado pra refletir Opção A escolhida) · **Branch:** `feat/9.6.4.3-reenvio-pos-sincronia` · **Pontos:** 2 · **Tipo:** feat

#### Objetivo

Fechar a limitação UX da 9.6.4.2: antes, perda silenciosa de mensagem.
Depois, atrito visível (botão desabilitado + banner "Reconectando...") que
força o usuário a redigitar.

**Decisão fechada:** Opção A da análise — atrito visível. Não enfileirar
(Opção B e C ficaram documentadas como follow-up se virar problema).

#### O que mudou

**Frontend:**
- `ChatProvider._onErro` com `CHAT_FORA_DE_SINCRONIA` muda status pra
  `conectando` até o próximo `historico` chegar
- `ChatProvider.enviarMensagem` passa a ser no-op se `status != conectado`
  (defesa em profundidade)
- `InputMensagem` ganha parâmetro `habilitado` que afeta `_podeEnviar`
- `ChatPage` passa `habilitado: status == conectado`
- Banner condicional: `erroConexao` OU `(conectando E chatId != null)` —
  o `chatId != null` evita banner aparecer no load inicial

#### Decisões arquiteturais tomadas aqui

- Padrão de UX: perda visível > perda silenciosa (WhatsApp/Telegram)
- Fila persistente ficou documentada mas NÃO implementada

#### Bugs descobertos (durante implementação)

1. **Skeleton no race** — `_buildConteudo` mostrava skeleton quando status
   era `conectando`. No race (não load inicial), isso trocaria a lista de
   mensagens pelo skeleton por 300-800ms. Fix: mesmo guard `chatId == null`
   do banner, aplicado ao skeleton.

2. **Texto do banner "Sem conexão..."** é ligeiramente incorreto no race
   (a rede está OK). Mantido por simplicidade; se virar atrito depois,
   introduzir `motivo` como propriedade do `_BannerReconectando`.

#### Commit principal

- `c1bc075 feat: desabilita envio e mostra banner durante ressincronização de chat`

---

### 5.8 9.6.5 — Seguidores em tempo real

**Issue:** #209 · **Branch:** `feat/9.6.5-seguidores-realtime` · **Pontos:** 1 · **Tipo:** feat

#### Objetivo

Contador de seguidores no perfil próprio atualiza em tempo real quando
alguém segue/deixa de seguir.

#### O que mudou

**Backend:**
- `seguir` emite `seguidor_adicionado` quando `inserido.rows.length > 0`
  (follow novo, não idempotente)
- `deixarDeSeguir` ganha `RETURNING seguidor_id` + guard `removido.rows.length > 0`
- Emite `seguidor_removido` só em unfollow real
- Payload: `{ totalSeguidores, seguidorId, acao }`

**Frontend:**
- `PerfilProvider` recebe `RealtimeManager` opcional no construtor
- Handler único `_onSeguidorMudou` assinado em ambos os eventos
- Atualiza `_perfil.seguidores` só se `isOwnProfile == true` E
  `totalSeguidores` difere do atual

#### Decisões arquiteturais tomadas aqui

- `RealtimeManager?` opcional como padrão legítimo pra features opt-in
  (permite rota `/perfil` de OUTROS continuar sem realtime)
- Payload mais rico (`{ totalSeguidores, seguidorId, acao }`) em vez do
  minimalista `{ total_seguidores_atualizado }` da issue original

#### Bugs descobertos (durante implementação)

- `deixarDeSeguir` sem `RETURNING` era bug latente: cliente idempotente
  retornava 204 várias vezes, parecendo que removeu N vezes. Agora
  retorna 204 todas as vezes mas só emite realtime na primeira.
- Dois testes antigos (`seguir.test.js` e `notificacoes-realtime.test.js`)
  tinham mocks que faltavam a nova query de COUNT — passavam logando
  erro silenciosamente. Fix: adicionar resposta do COUNT ao mock.

#### Commit principal

- `0a2d2ee feat: adiciona contador de seguidores em tempo real no perfil`

---

### 5.9 9.6.6 — Chip "X novas publicações" no feed

**Issue:** #210 · **Branch:** `feat/9.6.6-feed-realtime` · **Pontos:** 3 · **Tipo:** feat

#### Objetivo

Última da epic. Novas publicações na aba Seguindo aparecem como chip
flutuante no topo da lista, sem interromper o scroll do leitor.

#### O que mudou

**Backend:**
- `POST /publicacoes` após INSERT:
  - `SELECT seguidor_id FROM usuario_seguidores WHERE seguido_id = autor`
  - Loop com `emitToUser(seguidor, 'nova_publicacao_feed', payload)`
  - Payload: `{ publicacaoId, autorId, timestamp }`

**Frontend:**
- `FeedProvider` recebe `RealtimeManager`
- Set interno `_pendentesSeguindo` acumula ids
- `_onNovaPublicacaoFeed` adiciona id se `autor != meuId`
- `aplicarPendentesSeguindo()` chama REST página 1 + prepend com dedupe
- Pendentes zeram em: `pullRefresh`, `_carregarInicial(seguindo)`,
  `reagirAuth(deslogado)`, `_onReconnect`
- Novo widget `NovasPublicacoesButton` — pill arredondado, elevation,
  `colors.primaryAccent` + `colors.onPrimaryAccent`
- `_FeedListaView` adiciona overlay via `Stack`
- Chip aparece quando `aba == seguindo && pendentesCount > 0 && scrollOffset > 100`
- `_onProviderChange` injeta automático quando `scrollOffset <= 100`
  (padrão Twitter/Instagram: "no topo → injeta direto, sem chip")

#### Decisões arquiteturais tomadas aqui

- Só aba Seguindo recebe realtime (Para Você fica com pull-to-refresh)
- Padrão UX "topo → inject direto, longe do topo → chip" codificado
- Autor NÃO recebe emit pra si (SELECT de seguidores naturalmente exclui;
  cliente também valida como defesa em profundidade)

#### Bugs descobertos (durante implementação)

1. **Paginação quebrava com `_paginaSeguindo = 1`** — se usuário tivesse
   páginas 1-3 carregadas e aplicasse pendentes, o `carregarMais`
   subsequente duplicaria itens. Fix: manter página atual + dedupe no
   `carregarMais`.

2. **Logout com request em andamento** — se `aplicarPendentesSeguindo`
   estivesse em voo quando usuário desloga, publicações da conta antiga
   entrariam na lista nova. Fix: capturar `_meuId` no início, descartar
   response se mudou.

3. **`context.read` no dispose** — não é seguro no Flutter, try/catch só
   escondia. Fix: cachear referência do provider no `initState`.

4. **Chip não sumia ao subir manualmente** — se usuário scrollasse pra
   cima sem clicar no chip, chip ficava visível com `offset = 0`. Fix:
   `_onProviderChange` injeta automático quando offset vai pra zero.

5. **Lista vazia** — sem itens, `_scrollController.hasClients` é `false`,
   nem chip nem injeção aconteciam. Fix: tratar lista vazia como "topo".

6. **Cor do chip** — `Colors.white` fixo quebrava contraste no tema escuro.
   Fix: `colors.onPrimaryAccent` do design system.

#### Commit principal

- `e7424c2 feat: adiciona chip "X novas publicações" na aba Seguindo`

---

## 6. Dívidas técnicas pós-epic

### 6.1 Rooms de conversas antigas não são limpos

**Severidade:** baixa (banda extra, zero bug visual)
**Issue sugerida:** 9.6.X Chore: socket.io emite `sair_chat` ao trocar conversa

Quando usuário abre conversa com A, depois com B, depois com C, o socket
global permanece nos 3 rooms `<chatId>`. Eventos `nova_mensagem` dos chats
antigos continuam chegando — o `ChatProvider` filtra pelo `_chatIdAtivo`,
mas é carga extra.

### 6.2 Perda silenciosa de mensagem em race extremo (9.6.4.2)

**Severidade:** baixa (cenário raro: toque duplo + envio em <300ms)
**Issue:** documentada no corpo da 9.6.4.3 como "Opção B/C"

Hoje: atrito visível via botão desabilitado. Se virar problema pós-COPEX,
implementar fila persistente de mensagens pendentes.

### 6.3 Perf de `nova_publicacao_feed` em escala

**Severidade:** nenhuma pra escopo atual
**Issue potencial:** se autor tiver muitos seguidores (>1000)

Hoje o backend faz um loop `for` com `emitToUser` sequencial. Em escala
grande, isso vira gargalo. Pode trocar por broadcast em room
`feed_seguidores:<autorId>` com join no login.

### 6.4 Dois diretórios de notificação no Flutter

**Severidade:** cosmética
**Issue potencial:** cleanup

`features/notificacao/` (singular, vazio) e `features/notificacoes/`
(plural, usado). Primeiro é lixo de refatoração anterior. Deletar.

### 6.5 TODO 8.4.4 — notificações do tipo `mensagem`

**Severidade:** baixa (filtro já ativo)
**Issue:** mencionada no código do `NotificacoesProvider`

Backend ainda cria notificações de tipo `mensagem` em `chat.gateway.js`.
Mensagens têm sua própria aba (Chat) com badge próprio — não devem
aparecer na lista de alertas sociais. O cliente filtra, mas a geração
desnecessária continua.

### 6.6 Texto do banner "Sem conexão..." é inexato no race (9.6.4.3)

**Severidade:** cosmética
**Issue potencial:** design cleanup

Quando o banner aparece em race (`CHAT_FORA_DE_SINCRONIA`), a rede está
OK — mas o texto diz "Sem conexão". Introduzir `motivo` como propriedade
do `_BannerReconectando`.

---

## 7. Lições aprendidas (pros próximos refactors)

### L1. Comece com auditoria dedicada

A 9.6.1 (auditoria pura, zero código) parecia overhead. Na prática, as
6 decisões arquiteturais pendentes que ela identificou poupaom horas de
discussão nas tasks seguintes.

**Regra:** refactor > 10 pontos começa com uma task de auditoria.

### L2. Divida em sub-issues menores que você acha

Minha tendência inicial era fazer "9.6 inteiro de uma vez". A divisão em
9 sub-issues:
- Permitiu PRs revisáveis (<15 arquivos cada)
- Isolou risco (um bug na 9.6.3 não bloqueou a 9.6.4)
- Rastreabilidade perfeita no board

**Regra:** se um PR tem mais que 15 arquivos modificados, considera
dividir.

### L3. Teste de regressão invertido

Quando o comportamento muda, substitui o teste antigo pelo novo que
valida o novo comportamento. **Não** mantém o teste antigo "pra
compatibilidade" — ele era pra o código errado.

Padrão: `inbox_page_test.dart` da 9.6.3 reproduz o bug original da #183.
Qualquer refatoração que quebre esse teste é regressão imediata.

### L4. Documente o PORQUÊ, não só o quê

Comentários no código tipo "contrato stateless: callbacks não podem
capturar userId" valem mais que 10 testes. Daqui a 6 meses, quem for
mexer vai ler ESSE comentário antes de qualquer coisa.

### L5. Cada task gera a próxima

Padrão típico de refactor em produção:

```
9.6.3 → Fix do bug original
9.6.4.1 → Dívida técnica (migrar pro RealtimeManager)
9.6.4.2 → Bug descoberto na migração (race)
9.6.4.3 → UX gap descoberto no fix (perda silenciosa)
```

Cada task **gera** a próxima. Não é falha de planejamento — é natureza
de refactor incremental. **A diferença entre amador e sênior é saber
quando parar essa cadeia.**

### L6. "Edge case primeiro, caso feliz depois"

Praticamente todos os bugs descobertos durante implementação (não
previstos no prompt) eram edge cases:
- Logout no meio de request em voo
- Lista vazia sem controller com clientes
- `context.read` no dispose
- Load inicial vs ressincronização
- Primeira mensagem contando duas vezes
- `deixarDeSeguir` idempotente

**Regra:** gaste mais tempo pensando "e se o usuário fizer logout agora?",
"e se a lista estiver vazia?", "e se duas chamadas chegarem em paralelo?",
do que escrevendo o caminho feliz.

### L7. Dedupe por id, sempre

Em qualquer prepend/append otimista, assume que a mesma entidade pode
chegar por 2+ caminhos. Dedupe por id elimina a classe de bug de
duplicata. Padrão aplicado em `InboxProvider`, `FeedProvider`,
`NotificacoesProvider`.

### L8. Fail-safe para operações pós-sucesso

Depois que o banco commitou, qualquer falha subsequente (emit, query
derivada, logging) é problema OPERACIONAL, não DO CLIENTE. O padrão D5
evita bugs tipo "mensagem fantasma" (persistida mas cliente acha que
falhou).

### L9. Preserve estado entre sessões com cuidado

O `RealtimeManager` preserva assinaturas entre logout/login — isso simplifica
badges mas força o contrato D6 (callbacks stateless). Se um dia precisar
limpar assinaturas no logout por outro motivo, lembra que a decisão foi
intencional pra evitar re-assinar.

### L10. Teste manual com 2 contas é bloqueador do push

Em TODA task da epic, o teste manual com 2 celulares/emuladores foi
bloqueador do push. Vários bugs só apareceriam em interação real
multi-usuário (ex.: badge subindo com conversa aberta, race do chatId).

Automatizar o smoke com Playwright/Puppeteer multi-sessão em alguma task
futura seria ganho real.

---

## 8. Onde mexer quando

Guia prático pra quem for alterar comportamento depois da epic.

### "Quero adicionar um evento realtime novo"

1. Backend: emite via `emitToUser` do `src/config/socket-emitter.js`.
   Nome em snake_case, payload em camelCase.
2. Frontend: provider consumidor chama `realtime.subscribe('<nome>', handler)`
   no construtor, `realtime.unsubscribe` no dispose.
3. Documenta em `docs/realtime-events.md` com Room, Quando, Payload,
   Consumidor, Introduzido em.

### "Quero remover o polling de X"

1. Confirma que X tem evento realtime equivalente (ou crie um — veja item
   anterior).
2. Deriva o estado do provider que mantém dados reais em vez de refazer
   fetch.
3. Padrão: `BadgeMensagensProvider` deriva de `InboxProvider` via
   `addListener`. `BadgeNotificacoesProvider` deriva de `NotificacoesProvider`.

### "Quero que uma feature nova consuma realtime"

1. Provider recebe `RealtimeManager` no construtor (via
   `ChangeNotifierProxyProvider2<AuthProvider, RealtimeManager, X>` no
   `main.dart`).
2. Assina eventos no construtor, desassina no dispose.
3. `lazy: false` no provider se precisar receber eventos sem ser lido.
4. Callbacks respeitam contrato stateless D6 — `_meuId` como campo da
   instância se precisar saber "quem sou".

### "Quero debugar por que um evento não está chegando"

1. Backend: adiciona `console.log` antes do `emitToUser`. Confirma que o
   `userId` que você está passando é o certo.
2. Frontend: adiciona `print` dentro do callback. Se não imprime, veja:
   - O manager está conectado? `realtime.conectado`
   - O backend fez `socket.join('user:<id>')`? (ver log do servidor)
   - O nome do evento bate EXATAMENTE? snake_case nos dois lados?

### "O chat está mandando mensagem no chat errado"

Isso é o bug da 9.6.4.2 voltando. Confere:
1. `ChatProvider` está enviando `chatId` no payload de `enviar_mensagem`?
2. Backend tem o helper `validarChatSincronizado` e usa nos 4 handlers?
3. Teste da race em `chat-gateway-eventos.test.js` continua passando?

### "O badge não zera quando entro na conversa"

Confere:
1. Backend emite `conversa_lida` nos rooms pessoais de ambos participantes?
   (9.6.4.1)
2. `InboxProvider` tem `_onConversaLida` registrado?
3. `_onConversaLida` filtra por `lidaPor == _meuId`?

### "Quero adicionar realtime na aba 'Para você' do feed"

Essa foi decisão intencional de NÃO fazer (viraria flood). Se mudar:
1. Backend precisa de outra estratégia (talvez broadcast em room global
   em vez de per-seguidor)
2. Cliente precisa pensar o UX (botão de "novo conteúdo"? Prepend
   automático?)
3. Issue nova, não "ajuste pequeno"

---

**Fim do documento.**

Mantido em `docs/epic-183-retrospectiva.md`.
Atualizar só se encontrar inconsistência factual com o código real.
Decisões documentadas aqui foram tomadas com contexto da epoca — reverter
qualquer uma delas exige entender por que foi tomada.

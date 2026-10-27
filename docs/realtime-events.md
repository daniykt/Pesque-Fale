# Eventos realtime do Pesque & Fale

> Catálogo dos eventos Socket.IO emitidos entre backend e cliente Flutter.
> Atualize este doc a cada novo evento adicionado (toda sub-issue da epic #183).

## Rooms

| Room | Padrão | Entrada |
|---|---|---|
| `user:<id>` | prefixo + uuid do usuário | automática no `connection` após handshake JWT |
| `<chatId>` | `<uidA>_<uidB>` ordenado | ao emitir `entrar_chat` |

## Server → Client

### `nova_conversa`
- **Room:** `user:<destinatarioId>` + `user:<remetenteId>`
- **Quando:** primeira mensagem de um chat é enviada
- **Payload:**
  ```json
  {
    "conversaId": "uuidA_uuidB",
    "remetente": { "id": "...", "nome": "...", "username": "...", "fotoUrl": "..." },
    "ultimaMensagem": { "id": "...", "chatId": "...", "userId": "...", "nome": "...", "texto": "...", "status": "enviado", "criadoEm": "..." }
  }
  ```
- **Consumidor no app:** `InboxProvider` (via `RealtimeManager`). No destinatário, a conversa entra no topo com `naoLidas: 1`. No remetente, o payload não traz os dados do destinatário, então o provider recarrega a lista pelo REST.
- **Introduzido em:** sub-issue 9.6.3 (#207)

### `nova_mensagem_em_conversa`
- **Room:** `user:<destinatarioId>` + `user:<remetenteId>`
- **Quando:** qualquer mensagem é enviada (incluindo a primeira). Na primeira, sai logo depois de `nova_conversa`.
- **Payload:**
  ```json
  {
    "conversaId": "uuidA_uuidB",
    "previewTexto": "...",
    "timestamp": "ISO-8601",
    "remetenteId": "uuid"
  }
  ```
- **Consumidor no app:** `InboxProvider`. Atualiza o preview, move a conversa pro topo e soma 1 em `naoLidas` quando o usuário não é o remetente. Ignora conversas que ainda não estão na lista e eventos com `timestamp` que não seja mais novo que o da última mensagem conhecida. Assim a primeira mensagem não conta duas vezes.
- **Introduzido em:** sub-issue 9.6.3 (#207)

### `nova_notificacao`
- **Room:** `user:<destinatarioId>`
- **Quando:** uma notificação é inserida no banco pelo helper `criarNotificacao` (follow, curtida, comentário — qualquer caller atual ou futuro). Não sai quando `para === deId`. Se a montagem do payload falhar depois do INSERT, a notificação continua salva e o evento só não é emitido.
- **Payload:** shape idêntico ao `_format` do `notificacoes.controller.js` (o mesmo item do `GET /v1/notificacoes`):
  ```json
  {
    "id": "uuid",
    "para": "uuid",
    "deId": "uuid",
    "de": "nome",
    "deUsername": "username",
    "deFoto": "url?",
    "jaSigoDe": true,
    "deVolta": false,
    "tipo": "seguindo|curtida|comentario|mensagem|sistema",
    "texto": "...",
    "postId": "uuid?",
    "chatId": "string?",
    "lida": false,
    "criadoEm": "ISO-8601"
  }
  ```
- **Consumidor no app:** `NotificacoesProvider` (via `RealtimeManager`). Coloca no topo da lista com `lida: false` e ignora ids que já estão nela. Notificações do tipo `mensagem` são filtradas (TODO 8.4.4). O evento não marca nada como lido: isso continua acontecendo quando a aba Alertas abre. O `BadgeNotificacoesProvider` deriva da lista, então o badge sobe sozinho.
- **Introduzido em:** sub-issue 9.6.4 (#208)

### `nova_mensagem` (pré-existente)
- **Room:** `<chatId>`
- **Quando:** mensagem enviada em um chat
- **Payload:** objeto `Mensagem` completo
- **Consumidor no app:** `ChatProvider` (tela de conversa aberta, via `ChatSocketService`)
- **Introduzido em:** fase anterior à epic #183

### `historico`, `mensagens_vistas`, `outro_digitando`, `outro_parou_digitando`, `erro`
Pré-existentes. Detalhes na seção 2.5 do `realtime-audit.md`.

## Client → Server

Pré-existentes. Detalhes na seção 2.5 do `realtime-audit.md`.

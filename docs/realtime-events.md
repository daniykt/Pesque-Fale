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

### `conversa_lida`
- **Room:** `user:<leitorId>` + `user:<outroParticipanteId>`
- **Quando:** depois do `UPDATE mensagens SET status = 'visto'` (`marcarComoVistas`) nos handlers `marcar_visto` e `entrar_chat` do gateway, ou seja, quando o usuário abre a conversa ou recebe mensagem com ela aberta. Se o UPDATE falhar, não sai (nem `mensagens_vistas`); se o emit falhar depois do UPDATE, só loga.
- **Payload:**
  ```json
  {
    "conversaId": "uuidA_uuidB",
    "lidaPor": "uuid",
    "quandoEm": "ISO-8601"
  }
  ```
- **Consumidor no app:** `InboxProvider`. Quando `lidaPor == meuId`, zera `naoLidas` da conversa afetada (reflete no `BadgeMensagensProvider` sem refresh HTTP, inclusive nos outros dispositivos do leitor). Quando `lidaPor != meuId`, no-op: o outro usuário leu, e o contador local não muda. O "visto" nas mensagens da tela aberta continua vindo de `mensagens_vistas`.
- **Introduzido em:** sub-issue 9.6.4.1 (#215)

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

### `seguidor_adicionado`
- **Room:** `user:<seguidoId>` (o perfil que ganhou um seguidor)
- **Quando:** `POST /usuarios/:id/seguir` resulta em follow novo (não dispara em follow idempotente). Se a contagem falhar depois do INSERT, o follow continua salvo e o evento só não é emitido.
- **Payload:**
  ```json
  {
    "totalSeguidores": 42,
    "seguidorId": "uuid",
    "acao": "adicionado"
  }
  ```
- **Consumidor no app:** `PerfilProvider` global. Atualiza `_perfil.seguidores` pelo valor autoritativo de `totalSeguidores` **se** o perfil carregado é o próprio (`isOwnProfile`); se o total bate com o atual, é no-op. Perfis de outros usuários (rota `/perfil`) NÃO consomem — o `PerfilProvider` dessa rota é criado sem `RealtimeManager`.
- **Introduzido em:** sub-issue 9.6.5 (#209)

### `seguidor_removido`
- **Room:** `user:<seguidoId>` (o perfil que perdeu um seguidor)
- **Quando:** `DELETE /usuarios/:id/seguir` remove um registro de fato (`DELETE ... RETURNING`; não dispara em unfollow idempotente).
- **Payload:** idêntico ao `seguidor_adicionado`, com `"acao": "removido"`.
- **Consumidor no app:** mesmo `PerfilProvider` global, mesmo handler (`_onSeguidorMudou` assinado em ambos os eventos).
- **Introduzido em:** sub-issue 9.6.5 (#209)

### `nova_mensagem` (pré-existente)
- **Room:** `<chatId>`
- **Quando:** mensagem enviada em um chat
- **Payload:** objeto `Mensagem` completo
- **Consumidor no app:** `ChatProvider` (tela de conversa aberta, via `RealtimeManager` desde a 9.6.4.1 (#215)). Descarta eventos cujo `chatId` não é o da conversa aberta: o socket global continua nos rooms de conversas abertas antes.
- **Introduzido em:** fase anterior à epic #183

### `historico`, `mensagens_vistas`, `outro_digitando`, `outro_parou_digitando`
Pré-existentes. Detalhes na seção 2.5 do `realtime-audit.md`. Consumidos pelo `ChatProvider` via `RealtimeManager`: `mensagens_vistas` é filtrado pelo `chatId`; `outro_digitando`/`outro_parou_digitando` não trazem `chatId` e são filtrados pelo `userId` do outro participante.

### `erro`
- **Room:** socket específico do emissor (via `socket.emit`)
- **Payload:** `{ message, code? }`
- **Códigos conhecidos:**
  - `CHAT_CONSIGO_MESMO` — tentou abrir chat com o próprio id
  - `CHAT_FORA_DE_SINCRONIA` — o `chatId` enviado no payload de
    `enviar_mensagem` / `marcar_visto` / `digitando` / `parou_digitando`
    não bate com `socket.chatId`. Introduzido em 9.6.4.2 pra evitar
    corrupção por race do `entrar_chat`.
    **UX cliente (9.6.4.3):** quando recebe este code, o `ChatProvider`
    muda `status` para `conectando` e dispara `entrar_chat` para
    ressincronizar. O botão de enviar fica desabilitado e o banner
    de reconexão ("Sem conexão. Tentando reconectar...") aparece até o próximo `historico` restaurar
    `status = conectado`. Usuário redigita a mensagem após o atrito
    visual — não há reenvio automático.
- **Consumidor no app:** `ChatProvider`. `CHAT_FORA_DE_SINCRONIA` muda o status pra `conectando` (se estava `conectado`) e reemite `entrar_chat`; os outros erros viram `semMutualFollow` ou `erroConexao`.
- **Introduzido em:** fase anterior à epic #183 (code CHAT_FORA_DE_SINCRONIA em 9.6.4.2)

## Client → Server

Pré-existentes. Detalhes na seção 2.5 do `realtime-audit.md`. Desde a 9.6.4.1 (#215) o app emite todos pelo `RealtimeManager.emit` (descartado em silêncio se desconectado). O `ChatProvider` reemite `entrar_chat` toda vez que o manager volta a `conectado`.

Desde a 9.6.4.2, `enviar_mensagem`, `marcar_visto`, `digitando` e `parou_digitando` aceitam um `chatId` opcional no payload. Se vier e não bater com `socket.chatId`, o backend descarta o emit e responde `erro` com `CHAT_FORA_DE_SINCRONIA`; sem `chatId`, segue o comportamento antigo (compatibilidade com builds anteriores). O app só emite esses eventos depois do `historico`, sempre com o `chatId` dele.

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

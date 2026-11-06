# Eventos realtime do Pesque & Fale

> Catálogo dos eventos Socket.IO emitidos entre backend e cliente Flutter.
> Atualize este doc a cada novo evento adicionado (toda sub-issue da epic #183).

## Rooms

| Room | Padrão | Entrada |
|---|---|---|
| `user:<id>` | prefixo + uuid do usuário | automática no `connection` após handshake JWT |
| `<chatId>` | `<uidA>_<uidB>` ordenado | ao emitir `entrar_chat` |
| `feed` | nome fixo | automática no `connection` após handshake JWT (todo socket autenticado). Introduzido em 10.5.2 (#259) |

## Alcance dos eventos da Home (decisão da 10.5.1, #258)

Os eventos de publicação (`publicacao_criada`, `publicacao_removida`, `publicacao_curtidas`, `publicacao_comentarios`) são um **broadcast leve para todos os sockets autenticados**, não um room por publicação.

**Por quê:**
- A base de usuários é pequena: mandar alguns bytes para todos custa menos que gerenciar inscrições.
- Room por publicação exigiria `join`/`leave` a cada rolagem do feed (cada card que entra ou sai da tela), mais estado no servidor e mais eventos client → server.
- O app já filtra: só aplica eventos de publicações que estão no `PublicacoesStore`; o resto é ignorado sem custo.

**Proposta de implementação (10.5.2):**
- No `io.on('connection')` do gateway, todo socket entra no room `feed`, ao lado do `user:<id>`.
- Novo helper `emitToFeed(evento, payload)` no `config/socket-emitter.js`, no mesmo padrão do `emitToUser` (sem `io`, só loga e não quebra a request REST).
- Como o handshake já exige JWT, `io.emit` alcançaria os mesmos sockets. O room `feed` deixa o alcance explícito e continua correto se um dia houver socket sem login.

**Reavaliar se:** a base crescer a ponto de o tráfego de broadcast pesar; aí o caminho é room por publicação visível, com `join`/`leave` em lote.

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

### `nova_publicacao_feed`
- **Room:** `user:<seguidorId>` (um emit por seguidor do autor)
- **Quando:** `POST /publicacoes` resulta em INSERT bem-sucedido. O autor não recebe (ninguém segue a si mesmo). Se a query de seguidores falhar, a publicação continua salva (201) e o evento só não é emitido.
- **Payload:**
  ```json
  {
    "publicacaoId": "uuid",
    "autorId": "uuid",
    "timestamp": "ISO-8601"
  }
  ```
- **Consumidor no app:** `FeedProvider` global. Guarda o id em `_pendentesSeguindo` (ignora o próprio usuário como autor e ids já na lista). A `FeedPage` decide pelo scroll da aba Seguindo: com a lista a mais de 100px do topo, mostra o chip "X novas publicações"; no topo (ou ao voltar pra ele), aplica direto sem chip. Aplicar = buscar a página 1 do Seguindo e fazer prepend do que ainda não está na lista. Pendentes zeram em pull-to-refresh, carregamento inicial da aba, logout e reconexão do socket.
- **Introduzido em:** sub-issue 9.6.6 (#210)
- **Coexiste com `publicacao_criada` (10.5.2):** continua igual e continua sendo o evento da aba Seguindo. Um seguidor do autor recebe os dois: `nova_publicacao_feed` alimenta o chip da Seguindo e `publicacao_criada` alimenta o chip da Para você.

### `publicacao_criada`
- **Room:** `feed` (broadcast para todos os sockets autenticados, inclusive o do autor)
- **Quando:** `POST /publicacoes` resulta em INSERT bem-sucedido, logo depois do INSERT. Falha no emit só loga; a resposta continua 201.
- **Payload:**
  ```json
  {
    "publicacaoId": "uuid",
    "autorId": "uuid",
    "timestamp": "ISO-8601"
  }
  ```
- **Consumidor no app:** `FeedProvider` global, para a aba Para você. Mesmo comportamento da Seguindo com `nova_publicacao_feed`: guarda o id em pendentes da Para você (ignora `autorId == usuário logado`, porque a tela de nova publicação já chamou `adicionarPublicacao`, e ignora ids já na lista); com a lista a mais de 100px do topo, mostra o chip "X novas publicações"; no topo, aplica direto (página 1 da Para você + prepend do que ainda não está na lista).
- **Introduzido em:** sub-issue 10.5.2 (#259); consumo em 10.5.5 (#262)

### `publicacao_removida`
- **Room:** `feed`
- **Quando:** `DELETE /publicacoes/:id` remove a publicação, emitido depois do `DELETE` (não sai em 404 nem em 403). Falha no emit só loga; a resposta continua 204.
- **Payload:**
  ```json
  {
    "publicacaoId": "uuid",
    "autorId": "uuid"
  }
  ```
- **Consumidor no app:** `PublicacoesStore`, via `FeedProvider`: `store.remover(publicacaoId)`. A remoção tira o id de todas as listas (Feed e Perfil) e leva o Detalhe aberto para o estado `removida` (aviso e volta). No dispositivo do autor, a publicação já foi removida pelo próprio fluxo de exclusão; o `remover` repetido não muda nada nem notifica, então o eco não precisa de filtro.
- **Introduzido em:** sub-issue 10.5.2 (#259); consumo em 10.5.4 (#261)

### `publicacao_curtidas`
- **Room:** `feed`
- **Quando:** `POST` ou `DELETE /publicacoes/:publicacaoId/curtir` muda algo de fato. Curtir uma publicação já curtida ou descurtir uma que não estava curtida não emite (mesma regra da notificação de curtida).
- **Payload:**
  ```json
  {
    "publicacaoId": "uuid",
    "curtidasCount": 12,
    "porId": "uuid"
  }
  ```
  `curtidasCount` é sempre o **total** da publicação, nunca "+1"/"-1".
- **Como obter o total sem outra ida ao banco:** a curtida e a leitura do contador ficam numa query só (CTE). O trigger `trg_curtidas_count` é AFTER ROW e roda no fim do comando, então o `SELECT` da CTE ainda lê o `curtidas_count` de antes da mudança:
  - **Curtir:** a CTE atual passa a devolver também `p.curtidas_count`. Se `nova = true`, `total = curtidas_count + 1`.
  - **Descurtir:** o `DELETE` vira uma CTE (`WITH del AS (DELETE ... RETURNING publicacao_id) SELECT p.curtidas_count, EXISTS (SELECT 1 FROM del) AS removida FROM publicacoes p WHERE p.id = $2`). Se `removida = true`, `total = max(curtidas_count - 1, 0)`. Um `DELETE ... RETURNING` sozinho devolve a linha da curtida, não o contador da publicação.
  - **Limite conhecido:** com duas curtidas simultâneas na mesma publicação, os dois eventos podem sair com o mesmo total. O próximo evento ou carregamento corrige; não vale uma ida extra ao banco para cobrir isso.
- **Consumidor no app:** `PublicacoesStore`, via `FeedProvider`. Atualiza só o `curtidasCount` da publicação; o `jaCurtiu` não muda, porque é do usuário logado e a curtida foi de outra pessoa. O store hoje só tem `atualizarCurtida(id, jaCurtiu:, curtidasCount:)`, então a 10.5.4 precisa de um método que mude só o contador. Publicação fora do store é ignorada. Eventos com `porId == usuário logado` são ignorados: é o eco da própria ação, que já foi aplicada de forma otimista.
- **Introduzido em:** sub-issue 10.5.3 (#260); consumo em 10.5.4 (#261)

### `publicacao_comentarios`
- **Room:** `feed`
- **Quando:** `POST /publicacoes/:publicacaoId/comentarios` cria um comentário, ou `DELETE /comentarios/:id` exclui um (não sai em 404, 403 nem erro de validação).
- **Payload:**
  ```json
  {
    "publicacaoId": "uuid",
    "comentariosCount": 5,
    "porId": "uuid"
  }
  ```
  `comentariosCount` é sempre o **total** da publicação.
- **Como obter o total sem outra ida ao banco:** mesmo raciocínio do `trg_comentarios_count` (AFTER ROW):
  - **Criar:** a CTE atual já faz `JOIN publicacoes p`; passa a devolver também `p.comentarios_count`, e `total = comentarios_count + 1`.
  - **Excluir:** o `SELECT autor_id FROM comentarios` que já existe (o que confere a permissão) passa a trazer `publicacao_id` e `p.comentarios_count` com `JOIN publicacoes`. Depois do `DELETE`, `total = max(comentarios_count - 1, 0)`. Alternativa equivalente: `DELETE` numa CTE com `RETURNING publicacao_id` e `SELECT` do contador, como no descurtir.
  - Mesmo limite de ações simultâneas do `publicacao_curtidas`.
- **Consumidor no app:** `PublicacoesStore`, via `FeedProvider`: `store.atualizarComentarios(publicacaoId, comentariosCount)`, que já existe e ignora publicação fora do store. Eventos com `porId == usuário logado` são ignorados (eco).
- **Introduzido em:** sub-issue 10.5.3 (#260); consumo em 10.5.4 (#261)

### Reconexão (eventos da Home)
Ao reconectar, o servidor não reenvia os eventos perdidos durante a queda. Por isso, quando o `RealtimeManager` volta a `conectado`, o `FeedProvider` recarrega a página 1 da aba ativa (e zera os pendentes, como já faz hoje com a Seguindo). As outras abas recarregam quando forem abertas. Logout e login não podem deixar listeners duplicados: o `FeedProvider` é global e assina os eventos uma vez só. Introduzido em 10.5.6 (#263).

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

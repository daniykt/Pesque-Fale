# AGENTS.md — API Node

Complementa o `AGENTS.md` da raiz. Node 20 (mesma versão do CI), Express 4, `pg`, Socket.IO, Jest + Supertest.

## Rodar

```bash
cp .env.example .env   # nunca commitar o .env
npm install
npm run migrate        # aplica db/migrations/*.sql em ordem; idempotente
npm run dev            # http://localhost:3333 — Swagger em /docs, saúde em /health
npm test
```

## Estrutura

- `src/app.js`: monta middlewares e rotas (prefixo `/v1`). `src/server.js` sobe HTTP + Socket.IO.
- `src/modules/<modulo>/`: `<modulo>.routes.js` (com o comentário `@swagger`) e `<modulo>.controller.js`.
- `src/config/`: `database.js` (pool `pg`), `cloudinary.js`, `multer.js`, `socket-emitter.js`, `swagger.js`.
- `src/middlewares/`: `auth.middleware.js` (JWT obrigatório, preenche `req.usuario`), `auth-opcional.middleware.js`, `rejeitar-base64.middleware.js`.

## Convenções

- **SQL sempre parametrizado** (`$1, $2…`). Nunca concatene valor do usuário na query.
- **Envelope de resposta:** sucesso `{ data, meta? }`; erro `{ error: 'CODIGO_EM_MAIUSCULO', message: 'Texto em pt-BR.', details? }`. Erro inesperado: `console.error(err)` + 500 `INTERNAL_ERROR`.
- **Banco em snake_case, JSON em camelCase.** A conversão fica numa função de formatação do controller (ex.: `_format` em `publicacoes.controller.js`).
- Nunca devolva `senha_hash` nem `firebase_uid`. Há teste para isso (`tests/serializer-seguranca.test.js`).
- Emitir evento realtime pelo REST: `emitToUser(userId, evento, payload)` de `config/socket-emitter.js` (room `user:<id>`). Documente o evento em `docs/realtime-events.md` antes de implementar.
- Upload só via `multer` + Cloudinary. Base64 em JSON é rejeitado de propósito.

## Migrations

- Arquivo novo em `db/migrations/` com o próximo número (`008_descricao.sql`). **Nunca edite uma migration já aplicada.** A `002` não existe; isso é esperado.
- Cada migration roda numa transação pelo `scripts/migrate.js`. Escreva de forma idempotente quando der (`IF NOT EXISTS`).
- Migration nova ganha um teste em `tests/migration-<nnn>.test.js`, seguindo os existentes.
- Não rode migration em produção. Isso é feito à mão pelo time.

## Testes

- `jest.mock('../src/config/database', () => ({ query: jest.fn() }))` + Supertest no `app`. Token de teste: `gerarToken(id)` de `tests/helpers/token.js`.
- Os mocks usam `mockResolvedValueOnce` **na ordem das queries**. Se você mudar a quantidade ou a ordem das queries de um controller, ajuste os testes dele e confira que ainda validam o comportamento.
- Nenhum teste fala com banco real ou com o Cloudinary.

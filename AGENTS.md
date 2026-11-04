# AGENTS.md — Pesque & Fale

Instruções para agentes de IA (Claude Code, Copilot, Cursor, Codex…) que trabalham neste repositório.
Regras específicas de cada lado estão em `pesque_fale_app/AGENTS.md` e `api/AGENTS.md`.

## O projeto

Rede social para pescadores (projeto interdisciplinar da FATEC Matão). Monorepo com:

| Pasta | O que é |
|---|---|
| `pesque_fale_app/` | App Flutter (Android + web), Provider, Material 3 |
| `api/` | API Node.js 20 + Express, PostgreSQL/PostGIS, Socket.IO, Cloudinary |
| `docs/` | Docs técnicos: `CI.md`, `JWT_E_CLOUDINARY.md`, `realtime-events.md`, `realtime-audit.md` |
| `.github/workflows/` | `ci.yml` (analyze + testes em PR) e `build-apk.yml` (APK ao publicar release) |

Produção: API no Render (`https://pesque-fale-api.onrender.com/v1`, Swagger em `/docs`), banco no Supabase.

## Antes de mexer

- Leia os arquivos que vai alterar e os que eles usam. Não presuma estrutura de pastas nem nomes.
- Faça só o que a task pede. Se precisar alterar algo fora do escopo, **pare e avise** em vez de editar.
- Se encontrar uma divergência de contrato entre app e API, **a API é a referência**. Avise antes de mudar qualquer lado.
- Não adicione dependências (`pubspec.yaml` ou `package.json`) sem aprovação explícita.

## Git

- Todo desenvolvimento parte da `dev`. A `main` só recebe merge versionado (`vX.Y.Z`) de release.
- Commits em **pt-BR** no padrão Conventional Commits: `feat:`, `fix:`, `refactor:`, `style:`, `test:`, `docs:`, `ci:`, `perf:`, com escopo quando fizer sentido (`fix(feed): ...`).
- Commits pequenos e atômicos. Cada commit deve deixar o CI verde.
- **Nunca** adicione `Co-Authored-By`, "Generated with Claude Code" ou qualquer assinatura de IA em commits e PRs.
- Não faça push, merge, tag nem release sem pedido explícito.

## Antes de cada commit

Rode na pasta afetada e só siga com tudo verde:

```bash
# pesque_fale_app/
flutter analyze
flutter test

# api/
npm test
```

São os mesmos comandos do CI (`docs/CI.md`). Se um teste quebrar, corrija a causa; não apague nem enfraqueça o teste para passar.

## Princípios do produto

- **UX honesta:** só entra funcionalidade com suporte real no backend. Nada de status "online" falso, "digitando…" simulado ou dado mockado em produção.
- **Não portar antipatterns da versão React antiga:** imagem em base64, `alert()`/`prompt()`, banners do Firebase.
- **Imagens:** sempre multipart → API → Cloudinary → URL no banco. A API rejeita base64 em JSON.
- **Público 40+:** textos claros, alvos de toque grandes, contraste adequado no tema claro e no escuro.

## Segurança

- Nunca commite `.env`, keystores (`*.jks`, `*.keystore`, `key.properties`) nem chaves.
- Nunca devolva `senha_hash` ou `firebase_uid` em resposta da API. O `email` só aparece em `GET /usuarios/me`.

## Documentação

- Evento Socket.IO novo ou alterado → atualize `docs/realtime-events.md` **antes** de implementar.
- Endpoint novo ou alterado → atualize o comentário `@swagger` da rota.

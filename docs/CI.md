# CI do Pesque & Fale

Este documento explica o que acontece automaticamente toda vez que alguém abre um PR ou dá push em `dev`. Serve pra qualquer pessoa do time — não precisa ser dev pra entender.

---

## O que é CI

CI significa "Integração Contínua". É um conjunto de checks que roda **sozinho no GitHub** sempre que o código muda, pra garantir que:

- O código compila
- Os testes passam
- Nada quebrou o que já funcionava

Se um check falhar, o botão de "Merge" do PR fica bloqueado até resolver. É uma rede de segurança pra ninguém subir código quebrado na `dev` ou `main`.

O arquivo que define isso é `.github/workflows/ci.yml` na raiz do repo.

---

## Quando o CI roda

| Evento | Roda o CI? |
|---|---|
| Abrir PR pra `dev` | ✅ Sim |
| Abrir PR pra `main` | ✅ Sim |
| Novo commit num PR aberto | ✅ Sim (cancela o run antigo) |
| Push direto na `dev` (sem PR) | ✅ Sim |
| Push em qualquer outra branch | ❌ Não (roda só quando vira PR) |

**Detalhe importante:** se você fizer 3 commits seguidos no mesmo PR, o CI cancela os 2 primeiros e roda só o último. Economiza tempo e libera fila.

---

## O que o CI faz

O CI é dividido em **3 jobs**, e é inteligente: só roda o que precisa.

### Job 1 — `changes` (detector)

Olha quais arquivos mudaram no PR e decide quais jobs seguintes rodam. Se você mexeu só em `pesque_fale_app/`, o job da API nem começa. Se mexeu só em `api/`, o do Flutter é pulado. Se mexeu nos dois, os dois rodam.

Isso economiza tempo — não faz sentido rodar teste do backend por causa de mudança visual num widget.

### Job 2 — `mobile-ci` (Flutter)

Roda **só se algum arquivo em `pesque_fale_app/` mudou**. Faz 3 coisas em ordem:

1. **`flutter pub get`** — baixa as dependências do `pubspec.yaml`
2. **`flutter analyze`** — analisador estático do Dart. Reclama de erros de sintaxe, imports não usados, variáveis não usadas, código morto, más práticas. Se acusar algo, o CI falha.
3. **`flutter test`** — roda todos os arquivos `*_test.dart` da pasta `test/`. Se qualquer teste falhar, o CI falha.

**Tempo médio:** ~2 minutos.

### Job 3 — `api-ci` (Backend Node)

Roda **só se algum arquivo em `api/` mudou**. Faz 2 coisas:

1. **`npm ci`** — instala dependências do `package.json` de forma limpa (usa exatamente as versões do `package-lock.json`)
2. **`npm test`** — roda todos os testes com Jest

**Tempo médio:** ~1 minuto.

---

## O que **não** o CI faz (decisão consciente)

Removemos coisas que davam problema mais do que valor:

| Removido | Motivo |
|---|---|
| **Build de APK Android em todo PR** | Dependia de baixar bibliotecas Kotlin do `plugins.gradle.org`, que constantemente devolvia erro `429 Too Many Requests` (rate limit). APK debug do CI nunca era usado por ninguém. O APK agora é gerado só quando sai uma release (veja "Build do APK na release" abaixo). |
| **`dart format` bloqueante** | Falhava CI por vírgula fora do lugar. Formatação já é feita pelo VS Code automaticamente. Não vale bloquear PR por estética. |
| **Publicar APK como artefato** | Ninguém baixava. Ocupava espaço. |

---

## Build do APK na release

Existe um segundo workflow, separado do CI: `.github/workflows/build-apk.yml` (Task 9.3).

- **Quando roda:** só quando uma release é publicada no GitHub.
- **O que faz:** gera o APK de release e anexa na própria release com o nome `pesque-fale-<tag>.apk` (ex.: `pesque-fale-v1.0.0.apk`).
- **Por que separado:** o CI precisa ser rápido e roda em todo PR; o APK só interessa quando sai versão nova.

### Assinatura do APK

O APK de release é assinado com uma **keystore fixa** (Task 10.1). Com isso, a partir da **v1.1.0** o app atualiza por cima, sem desinstalar. A v1.0.0 saiu com outra chave e precisa ser desinstalada uma última vez.

**Secrets do repositório** (só os nomes; os valores ficam no GitHub):

| Secret | O que guarda |
|---|---|
| `KEYSTORE_BASE64` | O arquivo `.jks` da keystore, em base64 |
| `KEYSTORE_PASSWORD` | Senha da keystore |
| `KEY_ALIAS` | Alias da chave: `pesquefale` |
| `KEY_PASSWORD` | Senha da chave. É igual ao `KEYSTORE_PASSWORD` (keystore PKCS12) |

O workflow decodifica a keystore e gera o `android/key.properties` na hora do build. Se faltar algum secret, o job falha.

**SHA-256 do certificado oficial** (é público, não é segredo):

- formato keytool: `8F:11:E5:05:C0:1B:06:3C:FC:E0:45:1A:BA:DF:84:F3:6C:A8:C1:35:DB:58:63:A0:9B:1C:4E:61:1D:12:E3:2B`
- formato apksigner: `8f11e505c01b063cfce0451abadf84f36ca8c135db5863a09b1c4e611d12e32b`

O passo "Conferir assinatura do APK" falha se o APK sair assinado com qualquer outra chave.

**Cuidados:**

- A keystore **não fica no repositório**. Há backup em dois lugares: ver com o Felipe ou o Danilo.
- Perder a keystore = nunca mais atualizar o app por cima. **Nunca** trocar a keystore nem o `applicationId`.
- Para regerar o `KEYSTORE_BASE64` a partir do arquivo: `base64 -w 0 arquivo.jks`.
- Para conferir o SHA-256 localmente: `keytool -J-Duser.language=en -list -v -keystore <arquivo>.jks -alias pesquefale`. O `-J-Duser.language=en` é necessário porque a tradução pt-BR do keytool trava ao imprimir o certificado.
- Build local sem `android/key.properties` usa a chave de debug: esse APK não instala por cima do APK do CI.

---

## Como saber se o CI passou

Em qualquer PR, aparece no rodapé uma seção **"Checks"** com uma dessas 3 marcas:

- 🟡 **Amarelo (círculo girando)** — ainda rodando, espera terminar
- ✅ **Verde** — passou, pode dar merge
- ❌ **Vermelho** — falhou, precisa investigar

**Merge fica bloqueado quando está amarelo ou vermelho.**

Pra ver detalhes:
1. Clica em **"Details"** ao lado do check que falhou
2. Vai abrir a página do GitHub Actions com o log completo
3. O passo que falhou fica com um ícone vermelho — clica pra expandir e ver a mensagem de erro

---

## O que fazer quando o CI falha

Segue esse guia rápido antes de me chamar (Danilo) ou perguntar pro time. 90% dos erros caem em 3 categorias:

### Categoria 1 — "Meu código quebrou algo" (problema real)

**Sinais no log:**
- `error: ...`
- `Expected 3 arguments, got 2`
- `stack trace de algum arquivo .dart`
- `Test failed: expected X, got Y`

**O que fazer:**
1. Ler a mensagem — o Dart/Flutter/Jest costumam ser bem claros
2. Corrigir o código local
3. Rodar local o mesmo comando que falhou:
   - Se foi `flutter analyze` → rodar `flutter analyze` na pasta `pesque_fale_app/`
   - Se foi `flutter test` → rodar `flutter test`
   - Se foi `npm test` → rodar `npm test` na pasta `api/`
4. Corrigir até passar
5. Commit + push — o CI reexecuta automaticamente

### Categoria 2 — "Infra da internet falhou" (problema externo)

**Sinais no log:**
- `429 Too Many Requests`
- `503 Service Unavailable`
- `timeout`
- `Could not GET https://...`
- `Connection refused`

**O que fazer:**
1. **Não mexer no código** — a culpa não é sua
2. Esperar uns 30 minutos (o serviço externo se recupera)
3. Ir em **Actions** no GitHub, achar o run que falhou, clicar **"Re-run failed jobs"**
4. Se rodar limpo agora, pronto

### Categoria 3 — "Esqueci de commitar alguma coisa" (problema chato)

**Sinais no log:**
- `Error: Cannot find file X`
- `Missing pubspec.lock`
- `Package X not found`

**O que fazer:**
1. Ver quais arquivos você deveria ter commitado (`git status` local)
2. Adicionar e commitar
3. Push de novo

---

## FAQ (perguntas frequentes)

### Preciso rodar CI localmente antes de abrir PR?

Não é obrigatório, mas **ajuda muito**. Se você rodar os mesmos comandos localmente antes:

```bash
# Flutter (na pasta pesque_fale_app/)
flutter analyze
flutter test

# Backend (na pasta api/)
npm test
```

...quando você abrir o PR, o CI vai passar de primeira. Economiza uns 3 minutos de "commit → esperar CI → falhou → corrigir → commit de novo".

### O CI vai bloquear meu merge se falhar?

Sim. É a intenção — evita que código quebrado entre em `dev` ou `main`. Se precisar de um bypass excepcional (ex: fix emergencial), o Danilo (admin do repo) consegue mergear mesmo com CI vermelho, mas é caso raro.

### O CI tá rodando faz 10 minutos e não termina, é normal?

Não. Tempo esperado:
- Só Flutter: ~2 min
- Só Backend: ~1 min
- Ambos: ~3 min (rodam em paralelo)

Se passar de 8 minutos, provavelmente travou. Vai em Actions → cancela o run → push um commit qualquer (pode ser mudar 1 espaço) pra reexecutar.

### Como eu vejo os testes falhando exatamente?

No log do CI, o `flutter test` (ou `npm test`) mostra qual teste falhou e por quê. Exemplo:

```
Expected: <5>
Actual: <3>
Test: PesquisaLocaisProvider muda status para vazio quando lista retornar vazia
```

Isso te diz: o teste do arquivo `pesquisa_locais_provider_test.dart`, o caso "muda status para vazio quando lista retornar vazia", esperava 5 mas recebeu 3. Vai ao teste, entende o que devia acontecer, ajusta o código ou o teste.

### O que é `flutter analyze` e por que ele reclama tanto?

É um "linter" — analisador estático que lê seu código sem rodar e diz "aqui você tem uma variável não usada", "aqui falta um `await`", "esse import não precisa". É chato mas evita bugs bobos. Se ele reclamar, o CI trava. Solução:

- Rodar `flutter analyze` local
- Corrigir cada aviso
- Push

Alguns avisos são **erros reais** (código não compila). Outros são **warnings** (compila mas tem cheiro ruim). Ambos travam o CI — decisão consciente pra manter código limpo.

### Posso desligar o CI temporariamente pra um PR?

**Não** através da UI do GitHub — o workflow sempre roda. Se você quiser marcar um PR como "trabalho em progresso, não valida ainda", coloca `[WIP]` no título e transforma em Draft PR (botão embaixo da descrição). Draft PR ainda roda CI, mas te lembra que não é pra revisar/mergear ainda.

Se por algum motivo você precisar bypassar (não recomendo), o Danilo consegue mergear com CI vermelho como admin.

---

## Manutenção do CI

**Quando atualizar a versão do Flutter no CI:**

Se o time decidir usar Flutter mais novo local (ex: 3.45.0), atualiza a linha no `ci.yml`:

```yaml
- uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.45.0'  # ← atualiza aqui
```

Se a versão do CI diverge da que o time usa local, aparece o clássico "passou aqui, falhou no CI".

**Quando atualizar a versão do Node no CI:**

Mesma coisa, na parte de `api-ci`:

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'  # ← atualiza aqui
```

---

## TL;DR

- CI roda `flutter analyze` + `flutter test` + `npm test` automaticamente em cada PR
- Passa em ~2-3 minutos
- Se falhar por causa do seu código → corrige local e faz push
- Se falhar por erro `429`/`503`/`timeout` → espera 30 min e clica "Re-run failed jobs"
- O APK não é gerado nos PRs, só quando sai uma release (`build-apk.yml`)
- Rode local antes de abrir PR pra evitar surpresas

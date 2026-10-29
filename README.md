# 🎣 Pesque & Fale

## 🌊 Sobre o Projeto

O Pesque & Fale é uma plataforma inspirada em redes sociais, criada para conectar pescadores e facilitar o compartilhamento de experiências, avaliações e recomendações de locais de pesca.

A proposta é centralizar informações úteis e ajudar usuários a encontrarem os melhores ambientes para pesca, promovendo também o lazer e a sustentabilidade.

O projeto nasceu no 3º semestre como uma aplicação web e, a partir do 4º semestre, está evoluindo para uma plataforma completa: app mobile em Flutter + API própria com integração de mapas.

---

## 🎯 Objetivos

- 🎣 Conectar pescadores
- 📍 Ajudar na descoberta de novos pontos de pesca
- ⭐ Permitir avaliações de locais
- 💬 Compartilhar experiências
- 🌱 Incentivar práticas sustentáveis

---

## ❗ Problema

Encontrar bons locais para pesca nem sempre é fácil. Falta informação centralizada, confiável e acessível para pescadores iniciantes e experientes.

## 💡 Solução

Uma plataforma onde usuários possam:  
✔ Avaliar locais | ✔ Publicar experiências | ✔ Interagir com outros pescadores | ✔ Descobrir novos pontos recomendados — agora também pelo celular, com mapa interativo mostrando os pontos próximos.

---

## 🕓 3º Semestre — A Plataforma Web

O 3º semestre entregou a primeira versão funcional do Pesque & Fale: uma aplicação web completa, responsiva e com autenticação real.

### ⚙️ Funcionalidades entregues

**Principais:** Cadastro e Login, Pesquisa de locais de pesca, Avaliação de pontos, Sistema de notificações, Perfil do usuário, Feed de publicações.  
**Extras:** Modo Dark, Responsividade (Mobile + Desktop), Navegação intuitiva.

### 🖥️ Tecnologias & Design

- **Tech Stack:** React, JavaScript, HTML5, CSS3, Firebase (Authentication e banco de dados)
- **Design:** Foco em simplicidade e usabilidade, identidade visual baseada no universo da pesca, cor principal: Azul escuro (`#062A6C`), interface limpa e intuitiva.

O código do 3º semestre está preservado na branch `3-semestre` deste repositório.

---

## 🚀 4º Semestre — API própria + Integração de Mapas

Este semestre marca a transformação do Pesque & Fale de uma rede social simples em uma plataforma de descoberta baseada em localização, com arquitetura profissional por trás.

### 🎯 Foco do semestre

- 🛠️ Construir uma API REST própria, substituindo o Firestore por um banco relacional com suporte geoespacial
- 🗺️ Integrar mapas interativos para geolocalização e busca de pontos de pesca por proximidade
- 📱 Migrar a experiência mobile de React para Flutter

### ⚙️ Tecnologias adicionadas este semestre

- **Mobile:** Flutter, Dart, Provider, `google_fonts`, `shared_preferences`
- **Mapas:** OpenStreetMap, `flutter_map`, `geolocator`, Nominatim (geocoding)
- **Backend:** Node.js/Express, PostgreSQL + PostGIS, Cloudinary (upload de imagens), Socket.io (chat)
- **Versionamento:** Git Flow com `dev` para desenvolvimento e `main` recebendo merges versionados

---

## 🚀 Como rodar o projeto

### 📱 Mobile — Flutter

```bash
git clone https://github.com/daniykt/Pesque-Fale
cd Pesque-Fale/pesque_fale_app
flutter pub get
flutter run -d chrome
# ou um emulador/dispositivo Android conectado
```

### ⚙️ Backend — API

#### 1. Pré-requisitos
- Node.js 18+
- PostgreSQL 18 com a extensão **PostGIS** (no Windows, instale pelo **Stack Builder**, que abre ao final da instalação do PostgreSQL → *Spatial Extensions* → PostGIS)
- Conta gratuita no [Cloudinary](https://cloudinary.com/users/register_free)

#### 2. Configurar variáveis de ambiente

```bash
cd api
cp .env.example .env
```

Edita o arquivo `api/.env` com os valores reais:

```env
PORT=3333
DATABASE_URL=postgresql://postgres:SUA_SENHA@localhost:5432/pesqueefale
JWT_SECRET=seu_jwt_secret_aqui
JWT_EXPIRES_IN=24h
CLOUDINARY_CLOUD_NAME=   # Dashboard Cloudinary → Product Environment Credentials
CLOUDINARY_API_KEY=      # Dashboard Cloudinary → Product Environment Credentials
CLOUDINARY_API_SECRET=   # Dashboard Cloudinary → Product Environment Credentials
```

> ⚠️ **Atenção:** sem as 3 variáveis do Cloudinary preenchidas, o servidor sobe normalmente mas uploads de foto/banner falham com 500. O servidor emite um `console.warn` claro no startup se detectar valores ausentes ou placeholder.

#### 3. Montar o banco de dados

O schema fica versionado em `api/db/migrations/`, em arquivos numerados. Quem aplica é o script `npm run migrate`: ele roda os arquivos em ordem e registra cada um na tabela `schema_migrations` (criada automaticamente na primeira execução).

| Migration | O que faz |
|---|---|
| `001_schema_inicial.sql` | Cria as extensões (pgcrypto, PostGIS) e as tabelas base: usuários, seguidores, pontos de pesca, avaliações, publicações, eventos, chats, mensagens e notificações |
| `003_curtidas_comentarios.sql` | Cria curtidas e comentários, com os triggers de contagem (e remove os triggers de nome antigo, que causavam contagem dupla em bancos montados antes dela) |
| `004_notificacoes_de_volta.sql` | Adiciona a coluna `de_volta` em notificações |
| `005_limpar_notificacoes_mensagem.sql` | Apaga as notificações antigas do tipo `mensagem` (o chat passou a ter aba e badge próprios) |
| `006_seed_pontos.sql` | Cria a conta oficial "Pesque & Fale" e 10 pontos de pesca da região de Matão/SP (5 pesqueiros e 5 em rios); rodar de novo não duplica |
| `007_fotos_tags_pontos.sql` | Preenche a foto de capa (7 pontos, fotos provisórias até a 008) e as tags (10 pontos) dos pontos oficiais da 006 |

**Banco novo (primeira vez)** — de dentro da pasta `api`, com o `.env` já configurado:

```bash
createdb -U postgres pesqueefale
npm install
npm run migrate
```

Saída esperada: uma linha `✅ aplicada: <arquivo>` por migration. Rodando de novo, cada uma aparece como `⏭️  já aplicada: <arquivo>`, e nada é executado: o script é idempotente e pode rodar quantas vezes quiser.

Cada migration roda em uma transação própria, junto com o seu registro em `schema_migrations`. Se uma falhar (por exemplo, com o PostGIS não instalado), ela é desfeita, o script mostra `❌ erro em <arquivo>: <mensagem>`, para ali e sai com código 1. Corrija o problema e rode de novo. A `001` é uma exceção parcial: ela tem `BEGIN`/`COMMIT` próprios, que fecham a transação do script antes do registro em `schema_migrations`. O conteúdo dela continua sendo desfeito se falhar.

> ⚠️ **Nota de operação.** O script é idempotente a partir da primeira execução, mas a migration `001_schema_inicial.sql` não é: ela foi escrita antes do runner existir. Se o banco já foi montado manualmente (produção via DBeaver, ou dev local seguindo o fluxo antigo com `psql -f`), rodar `npm run migrate` nele vai falhar, porque o script tenta recriar objetos que já existem. Antes da primeira execução nesses bancos, crie a `schema_migrations` e registre à mão as migrations já aplicadas:
>
> ```sql
> CREATE TABLE IF NOT EXISTS schema_migrations (
>   id SERIAL PRIMARY KEY,
>   filename VARCHAR(255) NOT NULL UNIQUE,
>   executed_at TIMESTAMP NOT NULL DEFAULT NOW()
> );
>
> INSERT INTO schema_migrations (filename) VALUES
>   ('001_schema_inicial.sql'),
>   ('003_curtidas_comentarios.sql'),
>   ('004_notificacoes_de_volta.sql'),
>   ('005_limpar_notificacoes_mensagem.sql');
> ```
>
> Registre só as que de fato foram aplicadas naquele banco; as que ficarem de fora o `npm run migrate` aplica em seguida. Em banco limpo (dev novo, CI, QA zerado) nada disso é necessário: o runner aplica tudo do zero.

**Criando uma migration nova:** adicione um arquivo `NNN_descricao_curta.sql` em `api/db/migrations/`, com o próximo número livre (ex.: `006_adiciona_coluna_x.sql`). O nome do arquivo é o que fica registrado em `schema_migrations`, então nunca renomeie nem edite uma migration já aplicada: para corrigir algo, crie uma nova.

**Aplicação manual (só em casos excepcionais)** — para depurar ou aplicar uma migration isolada, dá para rodar o arquivo direto com `psql` (ou colar o conteúdo no **Query Tool** do pgAdmin e apertar **F5**):

```bash
psql -U postgres -d pesqueefale -v ON_ERROR_STOP=1 -f db/migrations/004_notificacoes_de_volta.sql
```

Esse caminho **não** registra nada em `schema_migrations`. Depois de aplicar à mão, registre o arquivo (`INSERT INTO schema_migrations (filename) VALUES ('004_notificacoes_de_volta.sql');`); senão o próximo `npm run migrate` tenta aplicá-lo de novo.

Os comandos `psql` e `createdb` precisam da pasta `bin` do PostgreSQL no PATH. Se o terminal não os reconhecer, no PowerShell: `$env:Path += ";C:\Program Files\PostgreSQL\18\bin"`.

> ⚠️ **Atenção:** a cada `git pull` na `dev`, rode `npm run migrate` dentro de `api/`. Com o banco desatualizado, a API sobe normalmente, mas algumas operações falham em silêncio. Exemplo: sem a `004`, **nenhuma notificação é criada** — seguir, curtir e comentar continuam respondendo `201`, e o erro só aparece no terminal da API como `Erro ao criar notificação` com `code: '42703'` (coluna inexistente).

#### 4. Instalar dependências e rodar

```bash
npm install
npm run dev
```

A API estará disponível em `http://localhost:3333`.  
Documentação interativa: `http://localhost:3333/docs`

#### 5. Scripts pontuais

```bash
node scripts/limpar-imagens-orfas.js
```

Rodar **uma única vez, após o deploy do fix do #114**. As fotos de perfil e banners enviados antes do fix foram apagados do Cloudinary, então as URLs gravadas no banco respondem 404. O script zera `usuarios.foto_perfil` e `usuarios.banner` para que o app exiba o fallback visual (inicial do nome / gradiente) em vez de imagem quebrada, até os usuários reenviarem.

---

## 📲 Instalar o app (APK)

O APK Android é gerado **automaticamente** pelo workflow `.github/workflows/build-apk.yml` sempre que uma release é publicada no GitHub. Ele aparece em **Assets** da release como `pesque-fale-<tag>.apk` (ex.: `pesque-fale-v1.0.0.apk`). Não é preciso ter Flutter instalado para baixar e testar.

**Como instalar:** abra a aba [Releases](https://github.com/daniykt/Pesque-Fale/releases), baixe o `.apk` da versão desejada no celular e permita "instalar apps de fontes desconhecidas" quando o Android pedir. O app já aponta para a API de produção.

> ⚠️ **Para atualizar, desinstale a versão anterior antes.** Por enquanto o APK é assinado com uma chave de debug gerada a cada build, então cada versão tem uma assinatura diferente e o Android recusa instalar por cima ("App não instalado"). Desinstalar apaga só o login salvo no celular; conta, publicações e mensagens ficam no servidor.

**Como publicar uma release (time):** em Releases → **Draft a new release**, crie a tag (ex.: `v1.0.0`) apontando para a branch certa e clique em **Publish release**. O workflow roda na aba **Actions** e anexa o APK em alguns minutos. Rascunho (draft) não dispara o build. Inclua no texto da release o aviso de desinstalar antes de atualizar.

---

## 📦 Estrutura do Repositório

Pesque-Fale/
├── api/ # Backend Node.js/Express
│ ├── src/
│ ├── tests/
│ ├── scripts/ # Scripts pontuais rodados manualmente
│ ├── .env.example # Template de variáveis de ambiente
│ └── package.json
└── pesque_fale_app/ # App mobile Flutter


---

## 👥 Equipe

| Nome | Função |
|------|--------|
| Danilo | Front-End Principal / QA / Back-end |
| Henrique | Back-End / QA / Front-end |
| Felipe   | Back-end / Front-end   |
| João Pedro | Documentação |
| Lucas | Documentação |
| Vinicius |  Documentação |
| Rebeca | Documentação |

---

## 📄 Licença

📘 Projeto acadêmico — uso educacional.

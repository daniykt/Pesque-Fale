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

O schema fica versionado em `api/db/migrations/`, em arquivos numerados que devem ser aplicados **em ordem numérica**. Eles **não** rodam sozinhos: cada pessoa aplica no próprio banco local.

| Migration | O que faz |
|---|---|
| `001_schema_inicial.sql` | Cria as extensões (pgcrypto, PostGIS) e as tabelas base: usuários, seguidores, pontos de pesca, avaliações, publicações, eventos, chats, mensagens e notificações |
| `003_curtidas_comentarios.sql` | Cria curtidas e comentários, com os triggers de contagem |
| `004_notificacoes_de_volta.sql` | Adiciona a coluna `de_volta` em notificações |

Os comandos abaixo usam `psql` e `createdb`. Se o terminal não reconhecer esses comandos, adicione a pasta `bin` do PostgreSQL ao PATH (no PowerShell: `$env:Path += ";C:\Program Files\PostgreSQL\18\bin"`).

**Banco novo (primeira vez)** — de dentro da pasta `api`:

```bash
createdb -U postgres pesqueefale
psql -U postgres -d pesqueefale -v ON_ERROR_STOP=1 -f db/migrations/001_schema_inicial.sql
psql -U postgres -d pesqueefale -v ON_ERROR_STOP=1 -f db/migrations/003_curtidas_comentarios.sql
psql -U postgres -d pesqueefale -v ON_ERROR_STOP=1 -f db/migrations/004_notificacoes_de_volta.sql
```

A `001` roda dentro de uma transação e só deve ser aplicada em um banco **vazio**. Se falhar (por exemplo, com o PostGIS não instalado), nada é criado pela metade: corrija o problema e rode de novo.

**Banco que já existia** — **não** rode a `001`. Aplique apenas as migrations a partir da `003`:

```bash
psql -U postgres -d pesqueefale -v ON_ERROR_STOP=1 -f db/migrations/003_curtidas_comentarios.sql
psql -U postgres -d pesqueefale -v ON_ERROR_STOP=1 -f db/migrations/004_notificacoes_de_volta.sql
```

A partir da `003`, as migrations usam `IF NOT EXISTS` / `CREATE OR REPLACE` / `DROP ... IF EXISTS`, então é seguro rodá-las de novo. A `003` também substitui os triggers de contagem com nome antigo (`trigger_curtidas_count` / `trigger_comentarios_count`), que existiam em bancos montados antes dela, evitando contagem dupla de curtidas e comentários.

Também é possível aplicar pelo pgAdmin: clique com o botão direito no banco `pesqueefale` → **Query Tool** → cole o conteúdo de cada arquivo → **F5**.

> ⚠️ **Atenção:** a cada `git pull` na `dev`, confira se entrou arquivo novo em `api/db/migrations/`. Com o banco desatualizado, a API sobe normalmente, mas algumas operações falham em silêncio. Exemplo: sem a `004`, **nenhuma notificação é criada** — seguir, curtir e comentar continuam respondendo `201`, e o erro só aparece no terminal da API como `Erro ao criar notificação` com `code: '42703'` (coluna inexistente).

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
| Danilo | Testes / Front-End Principal / Back-end |
| Henrique | Back-End / Documentação / Front-end |
| Felipe   | Back-end / Front-end   |
| João Pedro | Front-End |
| Lucas | Designer / Back-End |
| Vinicius | Designer / Front-End / Documentação |
| Rebeca | Documentação |

---

## 📄 Licença

📘 Projeto acadêmico — uso educacional.
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
- PostgreSQL 18
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

#### 3. Instalar dependências e rodar

```bash
npm install
npm run dev
```

A API estará disponível em `http://localhost:3333`.  
Documentação interativa: `http://localhost:3333/docs`

#### 4. Scripts pontuais

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
| Danilo | Testes / Front-End Principal |
| Henrique | Back-End / Documentação |
| João Pedro | Front-End |
| Lucas | Designer / Back-End |
| Vinicius | Designer / Front-End |
| Rebeca | Documentação |

---

## 📄 Licença

📘 Projeto acadêmico — uso educacional.
🎣 Pesque & Fale
&nbsp;

## 🌊 Sobre o Projeto

O **Pesque & Fale** é uma plataforma inspirada em redes sociais, criada para conectar pescadores e facilitar o compartilhamento de experiências, avaliações e recomendações de locais de pesca.

A proposta é centralizar informações úteis e ajudar usuários a encontrarem os melhores ambientes para pesca, promovendo também o lazer e a sustentabilidade.

O projeto nasceu no 3º semestre como uma aplicação web e, a partir do 4º semestre, está evoluindo para uma plataforma completa: app mobile em Flutter + API própria com integração de mapas.

## 🎯 Objetivos

- 🎣 Conectar pescadores
- 📍 Ajudar na descoberta de novos pontos de pesca
- ⭐ Permitir avaliações de locais
- 💬 Compartilhar experiências
- 🌱 Incentivar práticas sustentáveis

## ❗ Problema

Encontrar bons locais para pesca nem sempre é fácil. Falta informação centralizada, confiável e acessível para pescadores iniciantes e experientes.

## 💡 Solução

Uma plataforma onde usuários possam:

✔ Avaliar locais ✔ Publicar experiências ✔ Interagir com outros pescadores ✔ Descobrir novos pontos recomendados — agora também pelo celular, com mapa interativo mostrando os pontos próximos.

---

## 🕓 3º Semestre — A Plataforma Web

O 3º semestre entregou a primeira versão funcional do Pesque & Fale: uma aplicação web completa, responsiva e com autenticação real.

### ⚙️ Funcionalidades entregues

**🔹 Principais**
- 🔐 Cadastro e Login
- 🔎 Pesquisa de locais de pesca
- ⭐ Avaliação de pontos
- 🔔 Sistema de notificações
- 👤 Perfil do usuário
- 📰 Feed de publicações

**🔹 Extras**
- 🌙 Modo Dark
- 📱 Responsividade (Mobile + Desktop)
- 🧭 Navegação intuitiva

### 🖥️ Tecnologias

React · JavaScript · HTML5 · CSS3 · Firebase (Authentication e banco de dados)

### 🎨 Design

- 🎯 Foco em simplicidade e usabilidade
- 🌊 Identidade visual baseada no universo da pesca
- 🔵 Cor principal: Azul escuro (`#062A6C`)
- 📐 Interface limpa e intuitiva

### 🚧 Status

✅ Front-end estruturado em React · ✅ Back-end implementado (Firebase) · ✅ Sistema de autenticação funcional

> O código do 3º semestre está preservado na branch `3-semestre` deste repositório.

---

## 🚀 4º Semestre — API própria + Integração de Mapas

Este semestre marca a transformação do Pesque & Fale de uma rede social simples em uma **plataforma de descoberta baseada em localização**, com arquitetura profissional por trás.

### 🎯 Foco do semestre

- 🛠️ Construir uma **API REST própria**, substituindo o Firestore por um banco relacional com suporte geoespacial
- 🗺️ Integrar **mapas interativos** para geolocalização e busca de pontos de pesca por proximidade
- 📱 Migrar a experiência mobile de React para **Flutter**

### ⚙️ Tecnologias adicionadas este semestre

- **Mobile:** Flutter, Dart, Provider, `google_fonts`, `shared_preferences`
- **Mapas:** OpenStreetMap, `flutter_map`, `geolocator`, Nominatim (geocoding)
- **Backend (em construção):** Node.js/Express, PostgreSQL + PostGIS
- **Versionamento:** Git Flow com `dev` para desenvolvimento e `main` recebendo merges versionados pelas versões do planejamento

### 🗂️ Metodologia

Trabalho dividido em 2 squads paralelos (Backend e front-end), com backlog estruturado em 8 sprints (Fase 0 a 5) no GitHub Projects, usando Scrum com pontuação Fibonacci e prioridades Alta/Média/Baixa.

### 🚧 Status atual

✅ Sprint 0 — arquitetura, provedor de mapas e contrato de auth/perfil definidos · ✅ Setup do projeto Flutter + design tokens (claro/escuro) · 🔄 Implementação dos endpoints da API · 🔄 Telas do Flutter (Fase 1 em diante)

---

## 📦 Estrutura do Repositório

```
Pesque-Fale/
├── pesque_fale_app/   # App mobile em Flutter (4º semestre, em desenvolvimento)
└── ...                # Documentação e configuração do projeto
```

> O código React do 3º semestre vive na branch `3-semestre`, preservado como entrega congelada daquele período. A reintegração de web + mobile + API num único histórico de branch principal é decisão a ser tomada quando a API estiver pronta para ambos consumirem.

## 👥 Equipe

| Nome | Função |
| --- | --- |
| Danilo | Testes / Front-End Principal |
| Henrique | Back-End / Documentação |
| João Pedro | Front-End |
| Lucas | Designer / Back-End |
| Vinicius | Designer / Front-End |
| Rebeca | Documentação |

## 🚀 Como rodar o projeto


### Mobile — Flutter (4º semestre, em desenvolvimento)

```bash
git clone https://github.com/daniykt/Pesque-Fale
cd Pesque-Fale/pesque_fale_app
flutter pub get
flutter run -d chrome   # ou um emulador/dispositivo Android conectado
```

## 📄 Licença

📘 Projeto acadêmico — uso educacional.

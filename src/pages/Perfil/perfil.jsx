import React from "react";
import { Link } from "react-router-dom";
import Layout from "../../components/sidebar/layout"; // Importa o Layout padronizado
import "./perfil.css";
import "../../styles/global.css";

export default function Perfil() {
  const handlePublicar = () => {
    console.log("Abrir modal ou página de publicação");
  };

  const postsData = [
    {
      id: 1,
      imagem: "https://preview.redd.it/pesquei-meu-primeiro-peixe-hoje-v0-ztfepe85lp951.jpg?auto=webp&s=d3ea57b13b5b798c86a77e3ee7dac80320db1df1",
      data: "12/04/2025 às 18:30",
      comentario: "Que dia incrível de pesca!",
      local: "São Paulo, Brasil",
      avaliacao: "★★★★★",
      curtidas: 42,
      comentarios: 8,
    },
    {
      id: 2,
      imagem: "https://preview.redd.it/took-some-pics-of-my-fish-v0-bnt9ipm8w3cf1.jpg?width=1080&crop=smart&auto=webp&s=b9d00498506254486c3726c99795c29610dc129c",
      data: "12/04/2025 às 14:30",
      comentario: "Lugar top pra pescar com os amigos!",
      local: "Rio de Janeiro, Brasil",
      avaliacao: "★★★★☆",
      curtidas: 58,
      comentarios: 11,
    },
  ];

  return (
    <Layout>
      {/* Conteúdo principal do perfil */}
      <div className="container2">
        <div className="perfil">
          <img
            src="https://preview.redd.it/on9y92ssh1mb1.jpg?auto=webp&s=a881b5e709139d5b233b52418169faab7d3c355b"
            alt="Foto de Perfil"
            className="foto-perfil"
          />

          <div className="profile-stats">
            <div className="stat-box">
              <span className="number">10</span>
              <span className="label">Publicações</span>
            </div>
            <div className="stat-box">
              <span className="number">200</span>
              <span className="label">Seguidores</span>
            </div>
            <div className="stat-box">
              <span className="number">180</span>
              <span className="label">Seguindo</span>
            </div>
          </div>

          <div className="username-container">
            <h2 className="username">PesqueFale_Oficial</h2>
          </div>

          <div className="bio">
            <p>Quem não gosta de pesca?</p>
          </div>

          <div className="botoes-acao">
            <button className="btn-publicar" onClick={handlePublicar}>
              <span className="material-symbols-outlined">add_box</span>
              <span className="btn-text">Publicar</span>
            </button>
          </div>

          {postsData.map((post) => (
            <div className="publicacao-horizontal" key={post.id}>
              <img src={post.imagem} alt={`Post ${post.id}`} className="foto-horizontal" />
              <div className="info-direita">
                <div className="data-publicacao">Postado em {post.data}</div>
                <div className="comentario">{post.comentario}</div>
                <div className="local">{post.local}</div>
                <div className="avaliacao">{post.avaliacao}</div>
                <div className="interacoes">
                  <button className="btn-interacao">
                    <span className="material-symbols-outlined">thumb_up</span> {post.curtidas}
                  </button>
                  <button className="btn-interacao">
                    <span className="material-symbols-outlined">comment</span> {post.comentarios}
                  </button>
                  <button className="btn-interacao">
                    <span className="material-symbols-outlined">share</span>
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Rodapé (footer) – agora dentro do Layout, respeitando a margem da sidebar */}
      <footer>
        <div className="footer-container">
          <div className="footer-info">
            <h3>Sobre Nós</h3>
            <p>
              Grupo de estudantes dedicados ao desenvolvimento de iniciativas
              voltadas à melhoria do trabalho socioeconômico em Matão-SP e região.
            </p>
          </div>

          <div className="footer-links">
            <h3>Links Úteis</h3>
                <a href="/home">Página Inicial</a>
                <br />
                <a href="/pesquisar">Pesquisa de Locais</a>
                <br />
                <a href="/locais">Melhores Locais</a>
                <br />
                <a href="/notificacao">Notificações</a>
                <br />
                <a href="/sobre">Sobre Nós</a>
                <br />
                <a href="/perfil">Perfil</a>
          </div>

          <div className="footer-contact">
            <h3>Contato</h3>
            <p>
              Email: <strong>pesquefale@gmail.com</strong>
            </p>
          </div>
        </div>
        <p className="copyright">
          &copy; Pesque & Fale 2025 - Todos os direitos reservados.
        </p>
      </footer>
    </Layout>
  );
}
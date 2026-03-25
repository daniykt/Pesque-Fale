import React, { useState } from "react";
import { Link } from "react-router-dom";


// import imgLagoAzul from "../../assets/image/pesquisa/lagoazulserra.jpg";
import imgRecantoVerde from "../../assets/image/pesquisa/recantoverde.jpg";
import imgEvento1 from "../../assets/image/eventos/evento1.jpg";
import imgEvento2 from "../../assets/image/eventos/evento2.jpg";
import imgEvento3 from "../../assets/image/eventos/evento3.jpg";
import imgPesqueiro311 from "../../assets/image/eventos/pesqueiro_311.jpg";
import imgRecantoPescador from "../../assets/image/eventos/recanto_pescador.jpg";
import imgHomemPeixe from "../../assets/image/eventos/400x300imagem-01.jpg";
import imgHenrique from "../../assets/image/sobrenos/fotohenrique.jpg";
import imgLucas from "../../assets/image/sobrenos/fotolucas.jpg";
import imgDanilo from "../../assets/image/sobrenos/fotodanilo.jpg";

const Home = () => {
  const [posts] = useState([
    {
      autor: "Henrique",
      localizacao: "Matão - SP • Lago Azul • 06/05/2025",
      texto:
        "Meu amigo pescou hoje! Que experiência incrível no Lago Azul. O tucunaré estava atacando muito bem hoje de manhã. 🎣",
      imagemPerfil: imgHenrique,
      imagemPost: imgHomemPeixe,
      curtidas: 24,
      comentarios: 8,
      listaComentarios: [
        {
          autor: "Lucas",
          texto: "Não me chamou? Da próxima vez me avisa!",
          imagem: imgLucas,
        },
        {
          autor: "Danilo",
          texto: "Foi legal a experiência! Quero ir na próxima também.",
          imagem: imgDanilo,
        },
      ],
    },
    {
      autor: "Lucas",
      localizacao: "Matão - SP • Recanto do Pescador • 06/05/2025",
      texto:
        "Olha o peixe que o pai pegou! Dourado de 3kg no Recanto do Pescador. A isca artificial funcionou perfeitamente! 🐟",
      imagemPerfil: imgLucas,
      imagemPost: imgRecantoVerde,
      curtidas: 18,
      comentarios: 5,
      listaComentarios: [
        {
          autor: "Henrique",
          texto: "Que peixe amigo! Parabéns pela pescaria!",
          imagem: imgHenrique,
        },
      ],
    },
  ]);

  const eventos = [
    {
      titulo: "Torneio de Tucunaré",
      data: "10/05/2025",
      local: "Recanto do Pescador",
      imagem: imgEvento1,
      descricao: "Participe do maior torneio do estado!",
    },
    {
      titulo: "Pesca de Praia",
      data: "20/05/2025",
      local: "Pesqueiro Rota do Peixe",
      imagem: imgEvento2,
      descricao: "Competição de pesca na orla.",
    },
    {
      titulo: "Campeonato de Caiaque",
      data: "05/06/2025",
      local: "Pesqueiro 311",
      imagem: imgEvento3,
      descricao: "Pesca esportiva de caiaque.",
    },
  ];

  const locais = [
    {
      nome: "Lago Azul",
      cidade: "Matão - SP",
      avaliacao: 4.8,
      avaliacoes: 124,
      imagem: imgPesqueiro311,
    },
    {
      nome: "Recanto do Pescador",
      cidade: "Matão - SP",
      avaliacao: 4.6,
      avaliacoes: 89,
      imagem: imgRecantoPescador,
    },
    {
      nome: "Pesqueiro 311",
      cidade: "Araraquara - SP",
      avaliacao: 4.7,
      avaliacoes: 156,
      imagem: imgPesqueiro311,
    },
  ];

  const clicarNovaPublicacao = () => {
    window.location.href = "/registro";
  };
  const clicarPerfil = () => {
    window.location.href = "/perfil";
  };

  return (
    <>
      {/* Barra Lateral Esquerda - Componente separado */}
      <aside className="_Sidebar">Conteúdo da barra lateral esquerda</aside>

      <div className="column">
        <main className="main-content">
          <header className="content-header-home">
            <h1>Bem-vindo ao Pesque & Fale</h1>
            <p>
              Compartilhe suas experiências de pesca e descubra novos locais
            </p>
          </header>

          {/* Botão Nova Publicação */}
          <section className="new-post-section">
            <div className="btn-new-post" onClick={clicarNovaPublicacao}>
              <img
                src={imgHomemPeixe}
                alt="Homem Peixe"
                className="post-author-img"
              />
              <input
                type="text"
                placeholder="O que você deseja publicar sobre pesca hoje?"
                readOnly
              />
              <button className="post-btn" title="Adicionar Mídia">
                <span className="material-symbols-outlined">
                  add_photo_alternate
                </span>
              </button>
            </div>
          </section>

          {/* Layout Principal: Feed e Eventos */}
          <div className="content-layout">
            {/* Feed de Publicações */}
            <section className="feed">
              {posts.map((post, index) => (
                <div key={index} className="post-card" onClick={clicarPerfil}>
                  <div className="post-header">
                    {/* <img
                      src={imgHenrique}
                      alt={post.autor}
                      className="post-author-img"
                    /> */}

                    <img
                      src={post.imagemPerfil}
                      alt={post.autor}
                      className="post-author-img"
                    />

                    <div className="post-author-info">
                      <h3 className="post-author">{post.autor}</h3>
                      <p className="post-meta">{post.localizacao}</p>
                    </div>
                    <button className="post-menu" aria-label="Mais Opções">
                      <span className="material-symbols-outlined">
                        more_vert
                      </span>
                    </button>
                  </div>

                  <div className="post-content">
                    {/* <p className="post-text">{post.texto}</p> */}

                    <p>{post.texto}</p>
                  </div>

                  <div className="post-main-image-container">
                    <img
                      src={post.imagemPost}
                      alt="Publicação de Pesca"
                      className="post-main-image"
                    />
                  </div>

                  {/* <div className="comments-section">
                    {post.listaComentarios.map((comentario, indiceCom) => (
                      <div key={indiceCom} className="comment-item"></div>
                    ))}
                  </div> */}

                  <div className="post-interact-bar"></div>
                  <div className="post-stats-row">
                    <span>{post.curtidas} curtidas</span>
                    <span>{post.comentarios} comentários</span>
                  </div>

                  <div className="post-actions-row">
                    <button className="action-btn">
                      <span className="material-symbols-outlined">
                        favorite
                      </span>
                      Curtir
                    </button>

                    <button className="action-btn">
                      <span className="material-symbols-outlined">
                        chat_bubble
                      </span>
                      Comentar
                    </button>

                    <button className="action-btn">
                      <span className="material-symbols-outlined">share</span>
                      Compartilhar
                    </button>
                  </div>

                  <div className="post-comments-area">
                    <div className="comment-list"></div>
                    {post.listaComentarios.map((comentario, cIndex) => (
                      <div key={cIndex} className="comment-item">
                        <img
                          src={comentario.imagem}
                          alt={comentario.autor}
                          className="comment-avatar-img"
                        />

                        <div className="comment-content-bubble">
                          <span className="comment-author-name">
                            {comentario.autor}
                          </span>
                          <p>{comentario.texto}</p>
                        </div>
                      </div>
                    ))}

                    <div className="comment-input">
                      <img
                        src="/assets/eventos/recanto_pescador.jpg"
                        alt="Você"
                        className="comment-avatar"
                      />
                      <input
                        type="text"
                        placeholder="Escreva um comentário..."
                      />
                      <button
                        className="comment-btn"
                        aria-label="Enviar Comentário"
                      >
                        <span className="material-symbols-outlined">send</span>
                      </button>
                    </div>
                  </div>
                </div>
              ))}

              {/* Card de Dicas */}
              <div className="tips-card">
                <div className="tips-header">
                  <span className="material-symbols-outlined">lightbulb</span>
                  <h3>Dica do Dia</h3>
                </div>
                <p>
                  Para pescar tucunaré, use iscas artificiais como jigs e
                  spinners. O melhor horário é no início da manhã ou final da
                  tarde.
                </p>
              </div>
            </section>

            {/* Sidebar Direita - Eventos e Informações */}
            <aside className="right-sidebar">
              {/* Eventos */}
              <div className="widget events-widget">
                <h3 className="widget-title">
                  <span className="material-symbols-outlined">event</span>
                  Próximos Eventos
                </h3>
                {eventos.map((evento, indice) => (
                  <div key={indice} className="event-item">
                    <div className="event-image">
                      <img src={evento.imagem} alt={evento.titulo} />
                    </div>
                    <div className="event-info">
                      <h4 className="event-title">{evento.titulo}</h4>
                      <p className="event-date">{evento.data}</p>
                      <p className="event-location">{evento.local}</p>
                      <p className="event-desc">{evento.descricao}</p>
                      <button className="event-btn">Participar</button>
                    </div>
                  </div>
                ))}
              </div>

              <div className="widget popular-places">
                <h3 className="widget-title">
                  <span className="material-symbols-outlined">trending_up</span>
                  Locais em Alta
                </h3>
                {locais.map((local, indice) => (
                  <div key={indice} className="place-item">
                    <img src={local.imagem} alt={local.nome} />
                    <div className="place-info">
                      <h4>{local.nome}</h4>
                      <p>{local.cidade}</p>
                      <div className="place-rating">
                        <span>⭐ {local.avaliacao}</span>
                        <span>{local.avaliacoes} avaliações</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              <div className="widget weather-widget">
                <h3 className="widget-title">
                  <span className="material-symbols-outlined">wb_sunny</span>
                  Condições para Pesca
                </h3>
                <div className="weather-info">
                  <div className="weather-main">
                    <span className="weather-icon">☀️</span>
                    <div>
                      <h4>28°C</h4>
                      <p>Ensolarado</p>
                    </div>
                  </div>
                  <div className="weather-details">
                    <div className="weather-item">
                      <span className="material-symbols-outlined">air</span>
                      <span>Vento: 12 km/h</span>
                    </div>
                    <div className="weather-item">
                      <span className="material-symbols-outlined">
                        water_drop
                      </span>
                      <span>Umidade: 65%</span>
                    </div>
                    <div className="weather-item">
                      <span className="material-symbols-outlined">
                        visibility
                      </span>
                      <span>Visibilidade: Boa</span>
                    </div>
                  </div>
                  <div className="fishing-conditions">
                    <span className="condition-good">
                      🎣 Condições Excelentes para Pesca
                    </span>
                  </div>
                </div>
              </div>
            </aside>
          </div>
        </main>

        <footer>
          <div className="footer-container">
            <div>
              <h3>Sobre Nós</h3>
              <p>
                Grupo de estudantes dedicados ao desenvolvimento de iniciativas
                voltadas à melhoria do trabalho socioeconômico em Matão-SP e
                região.
              </p>
            </div>
            <div>
              <h3>Links Úteis</h3>
              <a href="/home">Página Inicial</a>
              <br />
              <a href="/pesquisar">Pesquisa de Locais</a>
              <br />
              <a href="/melhoreslocais">Melhores Locais</a>
              <br />
              <a href="/notificacao">Notificações</a>
              <br />
              <a href="/sobrenos">Sobre Nós</a>
              <br />
              <a href="/perfil">Perfil</a>

              {/* <Link to="/">Página Inicial</Link>
                <Link to="/pesquisar">Pesquisa de Locais</Link>
                <Link to="locaisAvaliados">Melhores Locais</Link>
                <Link to="/notificacoes">Notificações</Link>
                <Link to="/sobre">Sobre nós</Link>
                <Link to="/perfil">Perfil</Link> */}
            </div>
            <div>
              <h3>Contato</h3>
              <p>E-mail: pesquefale@gmail.com</p>
            </div>
          </div>
          <p className="copyright">
            &copy; Pesque & Fale 2025 - Todos os direitos reservados.
          </p>
        </footer>
      </div>
    </>
  );
};

export default Home;

import React, { useState, useEffect } from "react";
import { Link, useLocation } from "react-router-dom";
import "./home.css";
import Layout from "../../components/sidebar/layout";

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
  const location = useLocation();

  const [darkMode, setDarkMode] = useState(false);
  const [postsState, setPostsState] = useState([
    {
      autor: "Henrique",
      localizacao: "Matão - SP • Lago Azul • 06/05/2025",
      texto:
        "Meu amigo pescou hoje! Que experiência incrível no Lago Azul. O tucunaré estava atacando muito bem hoje de manhã. 🎣",
      imagemPerfil: imgHenrique,
      imagemPost: imgHomemPeixe,
      curtidas: 24,
      comentarios: 2,
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
      comentarios: 1,
      listaComentarios: [
        {
          autor: "Henrique",
          texto: "Que peixe amigo! Parabéns pela pescaria!",
          imagem: imgHenrique,
        },
      ],
    },
  ]);
  const [comentariosInput, setComentariosInput] = useState({});

  // Quando Home recebe showTour via state, salva no localStorage para persistir através de navegações
  useEffect(() => {
    const shouldShowTour = location.state?.showTour;
    if (shouldShowTour) {
      localStorage.setItem('tourAtivo', 'true');
      localStorage.removeItem('tourConcluido');
      // Limpar o state da URL para evitar recarregar o tour
      window.history.replaceState({}, document.title);
    }
  }, [location.state]);

  // Dark mode
  useEffect(() => {
    const savedTheme = localStorage.getItem("theme");
    if (savedTheme === "dark") {
      setDarkMode(true);
      document.body.classList.add("dark-mode");
    }
  }, []);

  const toggleTheme = () => {
    const newTheme = !darkMode;
    setDarkMode(newTheme);
    if (newTheme) {
      document.body.classList.add("dark-mode");
      localStorage.setItem("theme", "dark");
    } else {
      document.body.classList.remove("dark-mode");
      localStorage.setItem("theme", "light");
    }
  };

  // Scroll shadow sidebar
  useEffect(() => {
    const handleScroll = () => {
      const sidebar = document.querySelector("._Sidebar");
      if (!sidebar) return;
      if (window.scrollY > 10) {
        sidebar.style.boxShadow = "0 4px 20px rgba(0,0,0,0.1)";
      } else {
        sidebar.style.boxShadow = "none";
      }
    };
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const curtirPost = (index) => {
    setPostsState((prevPosts) =>
      prevPosts.map((post, i) =>
        i === index ? { ...post, curtidas: post.curtidas + 1 } : post
      )
    );
  };

  const adicionarComentario = (index, texto) => {
    if (!texto || !texto.trim()) return;

    setPostsState((prevPosts) =>
      prevPosts.map((post, i) =>
        i === index
          ? {
              ...post,
              comentarios: post.comentarios + 1,
              listaComentarios: [
                ...post.listaComentarios,
                {
                  autor: "Você",
                  texto: texto.trim(),
                  imagem: imgHomemPeixe,
                },
              ],
            }
          : post
      )
    );

    setComentariosInput((prev) => ({ ...prev, [index]: "" }));
  };

  const handleInputComentario = (index, valor) => {
    setComentariosInput((prev) => ({ ...prev, [index]: valor }));
  };

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
    <Layout>

      <div className="column">
        <main className="main-content">
          <header className="content-header-home">
            <h1>Bem-vindo ao Pesque & Fale</h1>
            <p>Compartilhe suas experiências de pesca e descubra novos locais</p>
          </header>

          <section className="new-post-section">
            <div className="btn-new-post" onClick={clicarNovaPublicacao}>
              <img
                src={imgHomemPeixe}
                alt="Homem Peixe"
                className="post-author-img"
              />
              <input
                type="text"
                placeholder="O que você deseja publicar hoje?"
                onClick={(e) => e.stopPropagation()}
              />
              <button className="post-btn" title="Adicionar Mídia">
                <span className="material-symbols-outlined">
                  add_photo_alternate
                </span>
              </button>
            </div>
          </section>

          <div className="content-layout">
            <section className="feed">
              {postsState.map((post, index) => (
                <div key={index} className="post-card" onClick={clicarPerfil}>
                  <div className="post-header">
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
                      <span className="material-symbols-outlined">more_vert</span>
                    </button>
                  </div>

                  <div className="post-content">
                    <p>{post.texto}</p>
                  </div>

                  <div className="post-main-image-container">
                    <img
                      src={post.imagemPost}
                      alt="Publicação de Pesca"
                      className="post-main-image"
                    />
                  </div>

                  <div className="post-interact-bar"></div>

                  <div className="post-stats-row">
                    <span>{post.curtidas} curtidas</span>
                    <span>{post.comentarios} comentários</span>
                  </div>

                  <div className="post-actions-row">
                    <button
                      className="action-btn"
                      onClick={(e) => {
                        e.stopPropagation();
                        curtirPost(index);
                      }}
                    >
                      <span className="material-symbols-outlined">favorite</span>
                      Curtir
                    </button>

                    <button
                      className="action-btn"
                      onClick={(e) => e.stopPropagation()}
                    >
                      <span className="material-symbols-outlined">chat_bubble</span>
                      Comentar
                    </button>

                    <button
                      className="action-btn"
                      onClick={(e) => e.stopPropagation()}
                    >
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
                        src={imgHomemPeixe}
                        alt="Você"
                        className="comment-avatar"
                      />
                      <input
                        type="text"
                        placeholder="Escreva um comentário..."
                        value={comentariosInput[index] || ""}
                        onClick={(e) => e.stopPropagation()}
                        onChange={(e) =>
                          handleInputComentario(index, e.target.value)
                        }
                        onKeyDown={(e) => {
                          if (e.key === "Enter") {
                            e.preventDefault();
                            e.stopPropagation();
                            adicionarComentario(index, e.target.value);
                          }
                        }}
                      />
                      <button
                        className="comment-btn"
                        aria-label="Enviar Comentário"
                        onClick={(e) => {
                          e.preventDefault();
                          e.stopPropagation();
                          adicionarComentario(index, comentariosInput[index]);
                        }}
                      >
                        <span className="material-symbols-outlined">send</span>
                      </button>
                    </div>
                  </div>
                </div>
              ))}

              <div className="tips-card">
                <div className="tips-header">
                  <span className="material-symbols-outlined">lightbulb</span>
                  <h3>Dica do Dia</h3>
                </div>
                <p>
                  Para pescar tucunaré, use iscas artificiais como jigs e spinners.
                  O melhor horário é no início da manhã ou final da tarde.
                </p>
              </div>
            </section>

            <aside className="right-sidebar">
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
                      <span className="material-symbols-outlined">water_drop</span>
                      <span>Umidade: 65%</span>
                    </div>
                    <div className="weather-item">
                      <span className="material-symbols-outlined">visibility</span>
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
      </div>
    </Layout>
  );
};

export default Home;
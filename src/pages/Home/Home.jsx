import React, { useState, useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import Layout from "../../components/sidebar/layout";
import "./home.css";

import { db } from "../../firebase";
import { doc, onSnapshot, updateDoc, getDoc, runTransaction } from "firebase/firestore";
import { observeAuthState } from "../../auth";

import imgEvento1         from "../../assets/image/eventos/evento1.jpg";
import imgEvento2         from "../../assets/image/eventos/evento2.jpg";
import imgEvento3         from "../../assets/image/eventos/evento3.jpg";
import imgPesqueiro311    from "../../assets/image/eventos/pesqueiro_311.jpg";
import imgRecantoPescador from "../../assets/image/eventos/recanto_pescador.jpg";
import imgHomemPeixe      from "../../assets/image/eventos/400x300imagem-01.jpg";

const Home = () => {
  const navigate = useNavigate();
  const location = useLocation();

  /* ── auth ── */
  const [user,         setUser]         = useState(null);
  const [usuarioDados, setUsuarioDados] = useState(null);

  /* ── feed ── */
  const [feedPosts,   setFeedPosts]   = useState([]);
  const [feedLoading, setFeedLoading] = useState(true);

  /* ── comentários ── */
  const [comentariosInput,   setComentariosInput]   = useState({});
  const [comentariosAbertos, setComentariosAbertos] = useState({});

  /* ── compartilhar feedback ── */
  const [compartilhadoFeedback, setCompartilhadoFeedback] = useState({});

  /* ── ui ── */
  const [activeTab,   setActiveTab]   = useState("para-voce");
  const [eventoIndex, setEventoIndex] = useState(0);
  const [localIndex,  setLocalIndex]  = useState(0);

  /* ── dados estáticos ── */
  const eventos = [
    { titulo: "Torneio de Tucunaré",  data: "10/05/2025", local: "Recanto do Pescador",     imagem: imgEvento1, descricao: "Participe do maior torneio do estado!" },
    { titulo: "Pesca de Praia",        data: "20/05/2025", local: "Pesqueiro Rota do Peixe", imagem: imgEvento2, descricao: "Competição de pesca na orla." },
    { titulo: "Campeonato de Caiaque", data: "05/06/2025", local: "Pesqueiro 311",            imagem: imgEvento3, descricao: "Pesca esportiva de caiaque." },
  ];
  const locais = [
    { nome: "Lago Azul",           cidade: "Matão - SP",      avaliacao: 4.8, avaliacoes: 124, imagem: imgPesqueiro311 },
    { nome: "Recanto do Pescador", cidade: "Matão - SP",      avaliacao: 4.6, avaliacoes: 89,  imagem: imgRecantoPescador },
    { nome: "Pesqueiro 311",       cidade: "Araraquara - SP", avaliacao: 4.7, avaliacoes: 156, imagem: imgPesqueiro311 },
  ];

  /* ── tour ── */
  useEffect(() => {
    if (location.state?.showTour) {
      localStorage.setItem("tourAtivo", "true");
      localStorage.removeItem("tourConcluido");
      window.history.replaceState({}, document.title);
    }
  }, [location.state]);

  /* ── auth ── */
  useEffect(() => {
    const unsub = observeAuthState(setUser);
    return unsub;
  }, []);

  /* ── feed em tempo real ── */
  useEffect(() => {
    if (!user) return;

    const secondaryUnsubs = {};
    const postsMap = {};
    let mainUnsub;

    const recalcFeed = () => {
      const todos = Object.values(postsMap).flat();
      todos.sort((a, b) => (b.id || 0) - (a.id || 0));
      setFeedPosts(todos);
      setFeedLoading(false);
    };

    const subscribeToUser = (uid) => {
      if (secondaryUnsubs[uid]) return;
      secondaryUnsubs[uid] = onSnapshot(doc(db, "usuarios", uid), (snap) => {
        if (snap.exists()) {
          const data = snap.data();
          postsMap[uid] = (data.posts || []).map((p) => ({
            autorId:   uid,
            autorNome: data.nome || data.displayName || "Pescador",
            autorFoto: data.fotoPerfil || "",
            ...p,
          }));
        } else {
          postsMap[uid] = [];
        }
        recalcFeed();
      });
    };

    const unsubscribeFromUser = (uid) => {
      if (secondaryUnsubs[uid]) {
        secondaryUnsubs[uid]();
        delete secondaryUnsubs[uid];
        delete postsMap[uid];
      }
    };

    mainUnsub = onSnapshot(doc(db, "usuarios", user.uid), (snap) => {
      if (!snap.exists()) return;
      const data    = snap.data();
      setUsuarioDados(data);

      const seguindo = data.seguindo || [];
      const uidsAlvo = [user.uid, ...seguindo];

      Object.keys(secondaryUnsubs).forEach((uid) => {
        if (!uidsAlvo.includes(uid)) unsubscribeFromUser(uid);
      });
      uidsAlvo.forEach(subscribeToUser);
    });

    return () => {
      mainUnsub?.();
      Object.values(secondaryUnsubs).forEach((fn) => fn());
    };
  }, [user]);

  /* ── dark mode ── */
  useEffect(() => {
    if (localStorage.getItem("theme") === "dark") {
      document.body.classList.add("dark-mode");
    }
  }, []);

  /* ── scroll shadow sidebar ── */
  useEffect(() => {
    const handle = () => {
      const sb = document.querySelector("._Sidebar");
      if (sb) sb.style.boxShadow = window.scrollY > 10 ? "0 4px 20px rgba(0,0,0,0.1)" : "none";
    };
    window.addEventListener("scroll", handle);
    return () => window.removeEventListener("scroll", handle);
  }, []);

  /* ── curtir (com transação para evitar race condition) ── */
  const curtirPost = async (post) => {
  if (!user || !post.autorId) return;

  const jaCurtiu = (post.curtidas || []).includes(user.uid);

  // atualização otimista
  setFeedPosts((prev) =>
    prev.map((p) => {
      if (p.id !== post.id || p.autorId !== post.autorId) return p;
      return {
        ...p,
        curtidas: jaCurtiu
          ? (p.curtidas || []).filter((id) => id !== user.uid)
          : [...(p.curtidas || []), user.uid],
      };
    })
  );

  try {
    const ref = doc(db, "usuarios", post.autorId);
    await runTransaction(db, async (transaction) => {
      const snap = await transaction.get(ref);
      if (!snap.exists()) return;
      const posts = snap.data().posts || [];
      const atualizados = posts.map((p) => {
        if (p.id !== post.id) return p;
        return {
          ...p,
          curtidas: jaCurtiu
            ? (p.curtidas || []).filter((id) => id !== user.uid)
            : [...(p.curtidas || []), user.uid],
        };
      });
      transaction.update(ref, { posts: atualizados });
    });
  } catch (e) {
    console.error("Erro ao curtir:", e);
    // reverte se falhar
    setFeedPosts((prev) =>
      prev.map((p) => {
        if (p.id !== post.id || p.autorId !== post.autorId) return p;
        return {
          ...p,
          curtidas: jaCurtiu
            ? [...(p.curtidas || []), user.uid]
            : (p.curtidas || []).filter((id) => id !== user.uid),
        };
      })
    );
  }
};

  /* ── comentar (com transação para evitar race condition) ── */
 const adicionarComentario = async (post, texto) => {
  if (!texto?.trim() || !user || !post.autorId) return;

  const novoComentario = {
    autorId:   user.uid,
    autorNome: usuarioDados?.nome || user.displayName || "Você",
    autorFoto: usuarioDados?.fotoPerfil || "",
    texto:     texto.trim(),
    data:      new Date().toLocaleString("pt-BR"),
  };

  // limpa o input imediatamente
  setComentariosInput((prev) => ({ ...prev, [post.id]: "" }));

  // atualização otimista — mostra o comentário na tela antes do Firestore confirmar
  setFeedPosts((prev) =>
    prev.map((p) => {
      if (p.id !== post.id || p.autorId !== post.autorId) return p;
      return { ...p, comentarios: [...(p.comentarios || []), novoComentario] };
    })
  );

  try {
    const ref = doc(db, "usuarios", post.autorId);
    await runTransaction(db, async (transaction) => {
      const snap = await transaction.get(ref);
      if (!snap.exists()) return;
      const posts = snap.data().posts || [];
      const atualizados = posts.map((p) => {
        if (p.id !== post.id) return p;
        return {
          ...p,
          comentarios: [...(p.comentarios || []), novoComentario],
        };
      });
      transaction.update(ref, { posts: atualizados });
    });
  } catch (e) {
    console.error("Erro ao comentar:", e);
    // reverte o otimismo se falhar
    setFeedPosts((prev) =>
      prev.map((p) => {
        if (p.id !== post.id || p.autorId !== post.autorId) return p;
        return {
          ...p,
          comentarios: (p.comentarios || []).filter((c) => c !== novoComentario),
        };
      })
    );
  }
};

  /* ── compartilhar ── */
  const compartilharPost = async (post) => {
    const url = `${window.location.origin}/perfil/${post.autorId}`;
    try {
      if (navigator.share) {
        await navigator.share({ title: `Post de ${post.autorNome}`, url });
      } else {
        await navigator.clipboard.writeText(url);
        setCompartilhadoFeedback((prev) => ({ ...prev, [post.id]: true }));
        setTimeout(
          () => setCompartilhadoFeedback((prev) => ({ ...prev, [post.id]: false })),
          2000
        );
      }
    } catch (e) {
      console.error("Erro ao compartilhar:", e);
    }
  };

  /* ── carrossel ── */
  const prevEvento = () => setEventoIndex((i) => (i - 1 + eventos.length) % eventos.length);
  const nextEvento = () => setEventoIndex((i) => (i + 1) % eventos.length);
  const prevLocal  = () => setLocalIndex((i)  => (i - 1 + locais.length)  % locais.length);
  const nextLocal  = () => setLocalIndex((i)  => (i + 1) % locais.length);

  const tabs = [
    { id: "para-voce", label: "Para você", icon: "stars"    },
    { id: "seguindo",  label: "Seguindo",  icon: "group"    },
    { id: "eventos",   label: "Eventos",   icon: "event"    },
    { id: "locais",    label: "Locais",    icon: "pin_drop" },
  ];

  /* ── render post ── */
  const renderPost = (post, idx) => {
    const curtidas     = post.curtidas    || [];
    const comentarios  = post.comentarios || [];
    const jaCurtiu     = user && curtidas.includes(user.uid);
    const comentAberto = comentariosAbertos[post.id] || false;

    return (
      <div key={`${post.autorId}-${post.id}`} className="post-card">

        {/* header */}
        <div className="post-header">
          <img
            src={post.autorFoto || imgHomemPeixe}
            alt={post.autorNome}
            className="post-author-img"
            onClick={() => navigate(`/perfil/${post.autorId}`)}
            style={{ cursor: "pointer" }}
          />
          <div className="post-author-info">
            <h3
              className="post-author"
              onClick={() => navigate(`/perfil/${post.autorId}`)}
              style={{ cursor: "pointer" }}
            >
              {post.autorNome}
            </h3>
            <p className="post-meta">
              {post.local && `${post.local} • `}{post.data}
            </p>
          </div>
          <button className="post-menu" aria-label="Mais Opções">
            <span className="material-symbols-outlined">more_vert</span>
          </button>
        </div>

        {/* conteúdo */}
        {post.comentario && post.comentario !== "Sem descrição" && (
          <div className="post-content"><p>{post.comentario}</p></div>
        )}

        {post.imagem && (
          <div className="post-main-image-container">
            <img src={post.imagem} alt="Publicação" className="post-main-image" />
          </div>
        )}

        {post.tags?.length > 0 && (
          <div className="post-tags-row">
            {post.tags.map((t) => <span key={t} className="post-tag">{t}</span>)}
          </div>
        )}

        <div className="post-interact-bar" />

        {/* contadores */}
        <div className="post-stats-row">
          <span>{curtidas.length} curtida{curtidas.length !== 1 ? "s" : ""}</span>
          <span>{comentarios.length} comentário{comentarios.length !== 1 ? "s" : ""}</span>
        </div>

        {/* botões de ação */}
        <div className="post-actions-row">
          <button
            className={`action-btn ${jaCurtiu ? "action-btn-ativo" : ""}`}
            onClick={() => curtirPost(post)}
          >
            <span className="material-symbols-outlined">
              {jaCurtiu ? "favorite" : "favorite_border"}
            </span>
            Curtir
          </button>

          <button
            className={`action-btn ${comentAberto ? "action-btn-ativo" : ""}`}
            onClick={() =>
              setComentariosAbertos((prev) => ({ ...prev, [post.id]: !prev[post.id] }))
            }
          >
            <span className="material-symbols-outlined">chat_bubble</span>
            Comentar
          </button>

          <button
            className={`action-btn ${compartilhadoFeedback[post.id] ? "action-btn-ativo" : ""}`}
            onClick={() => compartilharPost(post)}
          >
            <span className="material-symbols-outlined">
              {compartilhadoFeedback[post.id] ? "check_circle" : "share"}
            </span>
            {compartilhadoFeedback[post.id] ? "Copiado!" : "Compartilhar"}
          </button>
        </div>

        {/* área de comentários — toggle */}
        {comentAberto && (
          <div className="post-comments-area">
            {comentarios.map((c, ci) => (
              <div key={ci} className="comment-item">
                <img
                  src={c.autorFoto || imgHomemPeixe}
                  alt={c.autorNome}
                  className="comment-avatar-img"
                />
                <div className="comment-content-bubble">
                  <span className="comment-author-name">{c.autorNome}</span>
                  <p>{c.texto}</p>
                </div>
              </div>
            ))}

            <div className="comment-input">
              <img
                src={usuarioDados?.fotoPerfil || imgHomemPeixe}
                alt="Você"
                className="comment-avatar"
              />
              <input
                type="text"
                placeholder="Escreva um comentário..."
                value={comentariosInput[post.id] || ""}
                onChange={(e) =>
                  setComentariosInput((prev) => ({ ...prev, [post.id]: e.target.value }))
                }
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    e.preventDefault();
                    adicionarComentario(post, comentariosInput[post.id]);
                  }
                }}
              />
              <button
                className="comment-btn"
                onClick={() => adicionarComentario(post, comentariosInput[post.id])}
              >
                <span className="material-symbols-outlined">send</span>
              </button>
            </div>
          </div>
        )}
      </div>
    );
  };

  /* ── JSX ── */
  return (
    <Layout>
      <div className="column">
        <main className="main-content">

          {/* widget bar */}
          <div className="context-bar">
            <div className="context-widget weather-widget-mini">
              <span className="weather-icon-mini">☀️</span>
              <div className="weather-text">
                <span className="weather-temp">28°C</span>
                <span className="weather-label">Ensolarado • Matão - SP</span>
              </div>
              <div className="fishing-badge">
                <span className="material-symbols-outlined">phishing</span>
                Condições ótimas
              </div>
            </div>
            <div className="context-widget tip-widget-mini">
              <span className="material-symbols-outlined tip-icon">lightbulb</span>
              <p className="tip-text">
                <strong>Dica do dia:</strong> Tucunaré ataca melhor com isca artificial no começo da manhã. 🎣
              </p>
            </div>
          </div>

          {/* sticky post bar */}
          <div className="sticky-post-bar">
            <div className="btn-new-post" onClick={() => navigate("/registro")}>
              <img
                src={usuarioDados?.fotoPerfil || imgHomemPeixe}
                alt="Você"
                className="post-author-img"
              />
              <input
                type="text"
                placeholder="O que você deseja publicar hoje?"
                readOnly
              />
              <button className="post-btn" title="Nova publicação">
                <span className="material-symbols-outlined">add_photo_alternate</span>
              </button>
            </div>
          </div>

          {/* tabs */}
          <nav className="feed-tabs">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                className={`feed-tab ${activeTab === tab.id ? "active" : ""}`}
                onClick={() => setActiveTab(tab.id)}
              >
                <span className="material-symbols-outlined">{tab.icon}</span>
                {tab.label}
              </button>
            ))}
          </nav>

          {/* conteúdo das tabs */}
          <div className="tab-content">

            {/* para você */}
            {activeTab === "para-voce" && (
              <div className="content-layout">
                <section className="feed">
                  {feedLoading ? (
                    <div className="feed-loading">
                      <span className="material-symbols-outlined spin">progress_activity</span>
                      <p>Carregando feed...</p>
                    </div>
                  ) : feedPosts.length === 0 ? (
                    <div className="empty-tab-hint">
                      <span className="material-symbols-outlined">water</span>
                      <p>Nenhuma publicação ainda. Siga outros pescadores ou publique algo!</p>
                    </div>
                  ) : (
                    feedPosts.map((post, i) => renderPost(post, i))
                  )}
                </section>
              </div>
            )}

            {/* seguindo */}
            {activeTab === "seguindo" && (
              <div className="content-layout">
                <section className="feed">
                  {feedLoading ? (
                    <div className="feed-loading">
                      <span className="material-symbols-outlined spin">progress_activity</span>
                      <p>Carregando...</p>
                    </div>
                  ) : (
                    (() => {
                      const seguindo = usuarioDados?.seguindo || [];
                      const postsSeguindo = feedPosts.filter(
                        (p) => p.autorId !== user?.uid && seguindo.includes(p.autorId)
                      );
                      return postsSeguindo.length === 0 ? (
                        <div className="empty-tab-hint">
                          <span className="material-symbols-outlined">group</span>
                          <p>Siga outros pescadores para ver as publicações deles aqui.</p>
                        </div>
                      ) : (
                        postsSeguindo.map((post, i) => renderPost(post, i))
                      );
                    })()
                  )}
                </section>
              </div>
            )}

            {/* eventos */}
            {activeTab === "eventos" && (
              <div className="carousel-section">
                <div className="carousel-header">
                  <h2 className="section-title">
                    <span className="material-symbols-outlined">event</span>
                    Próximos Eventos
                  </h2>
                  <div className="carousel-controls">
                    <button className="carousel-btn" onClick={prevEvento}>
                      <span className="material-symbols-outlined">chevron_left</span>
                    </button>
                    <span className="carousel-counter">{eventoIndex + 1} / {eventos.length}</span>
                    <button className="carousel-btn" onClick={nextEvento}>
                      <span className="material-symbols-outlined">chevron_right</span>
                    </button>
                  </div>
                </div>
                <div className="carousel-track">
                  {eventos.map((evento, i) => (
                    <div
                      key={i}
                      className={`carousel-card evento-card ${
                        i === eventoIndex ? "active"
                        : i === (eventoIndex - 1 + eventos.length) % eventos.length ? "prev"
                        : "next"
                      }`}
                    >
                      <div className="carousel-card-image">
                        <img src={evento.imagem} alt={evento.titulo} />
                        <span className="evento-date-badge">{evento.data}</span>
                      </div>
                      <div className="carousel-card-body">
                        <h3>{evento.titulo}</h3>
                        <p className="carousel-local">
                          <span className="material-symbols-outlined">pin_drop</span>
                          {evento.local}
                        </p>
                        <p className="carousel-desc">{evento.descricao}</p>
                        <button className="event-btn">Participar</button>
                      </div>
                    </div>
                  ))}
                </div>
                <div className="carousel-dots">
                  {eventos.map((_, i) => (
                    <button
                      key={i}
                      className={`dot ${i === eventoIndex ? "active" : ""}`}
                      onClick={() => setEventoIndex(i)}
                    />
                  ))}
                </div>
              </div>
            )}

            {/* locais */}
            {activeTab === "locais" && (
              <div className="carousel-section">
                <div className="carousel-header">
                  <h2 className="section-title">
                    <span className="material-symbols-outlined">trending_up</span>
                    Locais Mais Avaliados
                  </h2>
                  <div className="carousel-controls">
                    <button className="carousel-btn" onClick={prevLocal}>
                      <span className="material-symbols-outlined">chevron_left</span>
                    </button>
                    <span className="carousel-counter">{localIndex + 1} / {locais.length}</span>
                    <button className="carousel-btn" onClick={nextLocal}>
                      <span className="material-symbols-outlined">chevron_right</span>
                    </button>
                  </div>
                </div>
                <div className="carousel-track">
                  {locais.map((local, i) => (
                    <div
                      key={i}
                      className={`carousel-card local-card ${
                        i === localIndex ? "active"
                        : i === (localIndex - 1 + locais.length) % locais.length ? "prev"
                        : "next"
                      }`}
                    >
                      <div className="carousel-card-image">
                        <img src={local.imagem} alt={local.nome} />
                      </div>
                      <div className="carousel-card-body">
                        <h3>{local.nome}</h3>
                        <p className="carousel-local">
                          <span className="material-symbols-outlined">location_on</span>
                          {local.cidade}
                        </p>
                        <div className="place-rating-large">
                          <span className="rating-num">{local.avaliacao}</span>
                          <span className="stars">⭐⭐⭐⭐⭐</span>
                          <span className="rating-count">({local.avaliacoes} avaliações)</span>
                        </div>
                        <button className="event-btn">Ver local</button>
                      </div>
                    </div>
                  ))}
                </div>
                <div className="carousel-dots">
                  {locais.map((_, i) => (
                    <button
                      key={i}
                      className={`dot ${i === localIndex ? "active" : ""}`}
                      onClick={() => setLocalIndex(i)}
                    />
                  ))}
                </div>
              </div>
            )}

          </div>
        </main>
      </div>
    </Layout>
  );
};

export default Home;
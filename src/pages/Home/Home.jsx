
import React, { useState, useEffect } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import "./home.css";
import Layout from "../../components/sidebar/layout";

import imgHomemPeixe from "../../assets/image/eventos/400x300imagem-01.jpg";

// FIREBASE
import {
  collection,
  onSnapshot,
  query,
  orderBy,
  doc,
  updateDoc,
  increment,
  arrayUnion
} from "firebase/firestore";

import { db } from "../../firebase";

const Home = () => {
  const location = useLocation();
  const navigate = useNavigate();

  const [postsState, setPostsState] = useState([]);
  const [comentariosInput, setComentariosInput] = useState({});

  // TOUR
  useEffect(() => {
    const shouldShowTour = location.state?.showTour;
    if (shouldShowTour) {
      localStorage.setItem("tourAtivo", "true");
      localStorage.removeItem("tourConcluido");
      window.history.replaceState({}, document.title);
    }
  }, [location.state]);

  // FEED EM TEMPO REAL
  useEffect(() => {
    const q = query(
      collection(db, "publicacoes"),
      orderBy("createdAt", "desc")
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const lista = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data()
      }));

      setPostsState(lista);
    });

    return () => unsubscribe();
  }, []);

  // CURTIR
  const curtirPost = async (postId) => {
    const ref = doc(db, "publicacoes", postId);

    await updateDoc(ref, {
      curtidas: increment(1)
    });
  };

  // COMENTAR
  const adicionarComentario = async (postId, texto) => {
    if (!texto || !texto.trim()) return;

    const ref = doc(db, "publicacoes", postId);

    await updateDoc(ref, {
      comentarios: arrayUnion({
        autor: "Você",
        texto: texto.trim(),
        imagem: imgHomemPeixe
      })
    });

    setComentariosInput((prev) => ({ ...prev, [postId]: "" }));
  };

  const handleInputComentario = (postId, valor) => {
    setComentariosInput((prev) => ({ ...prev, [postId]: valor }));
  };

  // ABRIR REGISTRO
  const clicarNovaPublicacao = () => {
    navigate("/registro");
  };

  return (
    <Layout>
      <div className="column">
        <main className="main-content">

          <header className="content-header-home">
            <h1>Bem-vindo ao Pesque & Fale</h1>
            <p>Compartilhe suas experiências de pesca</p>
          </header>

          {/* NOVA PUBLICAÇÃO */}
          <section className="new-post-section">
            <div className="btn-new-post">
              <img
                src={imgHomemPeixe}
                alt="perfil"
                className="post-author-img"
              />

              <input
                type="text"
                placeholder="O que você deseja publicar hoje?"
                readOnly
                onClick={clicarNovaPublicacao}
              />

              <button
                className="post-btn"
                onClick={clicarNovaPublicacao}
              >
                Publicar
              </button>
            </div>
          </section>

          {/* FEED */}
          <section className="feed">
            {postsState.map((post) => (
              <div key={post.id} className="post-card">

                <div className="post-header">
                  <img
                    src={post.imagemPerfil || imgHomemPeixe}
                    alt="perfil"
                    className="post-author-img"
                  />
                  <div>
                    <h3>{post.autor}</h3>
                    <p>{post.localizacao}</p>
                  </div>
                </div>

                <div className="post-content">
                  <p>{post.texto}</p>
                </div>

                {post.imagemPost && (
                  <img
                    src={post.imagemPost}
                    alt="post"
                    className="post-main-image"
                  />
                )}

                <div className="post-stats-row">
                  <span>{post.curtidas || 0} curtidas</span>
                  <span>{post.comentarios?.length || 0} comentários</span>
                </div>

                <div className="post-actions-row">
                  <button onClick={() => curtirPost(post.id)}>
                    ❤️ Curtir
                  </button>
                </div>

                <div className="post-comments-area">
                  {post.comentarios?.map((c, i) => (
                    <div key={i} className="comment-item">
                      <img
                        src={c.imagem || imgHomemPeixe}
                        alt="coment"
                      />
                      <div>
                        <strong>{c.autor}</strong>
                        <p>{c.texto}</p>
                      </div>
                    </div>
                  ))}

                  <input
                    type="text"
                    placeholder="Comentar..."
                    value={comentariosInput[post.id] || ""}
                    onChange={(e) =>
                      handleInputComentario(post.id, e.target.value)
                    }
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        adicionarComentario(
                          post.id,
                          comentariosInput[post.id]
                        );
                      }
                    }}
                  />
                </div>
              </div>
            ))}
          </section>

        </main>
      </div>
    </Layout>
  );
};

export default Home;


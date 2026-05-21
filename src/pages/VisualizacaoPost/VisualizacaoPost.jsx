import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import Layout from "../../components/sidebar/layout";
import "./VisualizacaoPost.css";

import { db } from "../../firebase";
import { 
  doc, 
  onSnapshot, 
  updateDoc, 
  addDoc, 
  collection, 
  serverTimestamp,
  getDoc
} from "firebase/firestore";
import { observeAuthState } from "../../auth";

export default function VisualizacaoPost() {
  const { userId, postId } = useParams();
  const navigate = useNavigate();

  const [user, setUser] = useState(null);
  const [usuarioPerfil, setUsuarioPerfil] = useState(null);    // dono do post
  const [usuarioLogado, setUsuarioLogado] = useState(null);    // usuário atual (dados completos)
  const [post, setPost] = useState(null);
  const [carregando, setCarregando] = useState(true);
  const [comentario, setComentario] = useState("");
  const [enviando, setEnviando] = useState(false);
  const [linkCopiado, setLinkCopiado] = useState(false);
  const [feedback, setFeedback] = useState(null);
  const [modalExclusao, setModalExclusao] = useState(false);
  const [excluindo, setExcluindo] = useState(false);

  // Mapa para armazenar fotos de comentários faltantes
  const [fotosComentarios, setFotosComentarios] = useState({});

  // Auth
  useEffect(() => {
    const unsubscribe = observeAuthState(setUser);
    return unsubscribe;
  }, []);

  // Dados do usuário logado (Firestore)
  useEffect(() => {
    if (!user?.uid) return;
    const unsub = onSnapshot(doc(db, "usuarios", user.uid), (docSnap) => {
      if (docSnap.exists()) setUsuarioLogado(docSnap.data());
    });
    return unsub;
  }, [user]);

  // Dados do perfil do post (dono)
  useEffect(() => {
    if (!userId) return;
    const docRef = doc(db, "usuarios", userId);
    const unsubscribe = onSnapshot(docRef, (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data();
        setUsuarioPerfil({ id: docSnap.id, ...data });
        const posts = data.posts || [];
        const postEncontrado = posts.find((p) => String(p.id) === String(postId));
        setPost(postEncontrado || null);
      }
      setCarregando(false);
    });
    return unsubscribe;
  }, [userId, postId]);

  // Carregar fotos faltantes dos comentários (quando não têm autorFoto)
  useEffect(() => {
    if (!post?.comentarios) return;

    const comentariosSemFoto = post.comentarios.filter(c => c.autorId && !c.autorFoto);
    if (comentariosSemFoto.length === 0) return;

    const carregarFotos = async () => {
      const novasFotos = {};
      await Promise.all(
        comentariosSemFoto.map(async (c) => {
          try {
            const snap = await getDoc(doc(db, "usuarios", c.autorId));
            if (snap.exists()) {
              novasFotos[c.autorId] = snap.data().fotoPerfil || "";
            }
          } catch (error) {
            console.error("Erro ao carregar foto do comentário:", error);
          }
        })
      );
      setFotosComentarios(prev => ({ ...prev, ...novasFotos }));
    };

    carregarFotos();
  }, [post]);

  const mostrarFeedback = (msg, tipo = "sucesso") => {
    setFeedback({ msg, tipo });
    setTimeout(() => setFeedback(null), 3000);
  };

  const jaCurtiu = post?.curtidas?.includes(user?.uid);

  const atualizarPosts = async (postsAtualizados) => {
    await updateDoc(doc(db, "usuarios", userId), { posts: postsAtualizados });
  };

  const handleCurtir = async () => {
    if (!user || !post) return;

    const postsAtuais = usuarioPerfil.posts || [];
    let curtiuAgora = false;

    const postsAtualizados = postsAtuais.map((p) => {
      if (String(p.id) !== String(postId)) return p;
      const curtidas = p.curtidas || [];
      const jaCurtiuLocal = curtidas.includes(user.uid);
      if (!jaCurtiuLocal) curtiuAgora = true;
      return {
        ...p,
        curtidas: jaCurtiuLocal
          ? curtidas.filter((id) => id !== user.uid)
          : [...curtidas, user.uid],
      };
    });

    await atualizarPosts(postsAtualizados);

    if (curtiuAgora && user.uid !== userId) {
      try {
        await addDoc(collection(db, "notificacoes"), {
          tipo: "curtida",
          de: user.displayName || "Pescador",
          de_id: user.uid,
          para: userId,
          postId: postId,
          createdAt: serverTimestamp(),
          lida: false,
        });
      } catch (error) {
        console.error("Erro ao notificar curtida:", error);
      }
    }
  };

  const handleComentar = async () => {
    if (!user || !comentario.trim() || !post) return;

    setEnviando(true);
    const textoComentario = comentario.trim();

    // Usa a foto do usuário logado (Firestore) ou fallback do Auth
    const fotoAutor = usuarioLogado?.fotoPerfil || user.photoURL || "";

    const novoComentario = {
      id: Date.now(),
      texto: textoComentario,
      autorNome: usuarioLogado?.nome || user.displayName || "Pescador",
      autorFoto: fotoAutor,
      autorId: user.uid,
      data: new Date().toLocaleString(),
    };

    try {
      const postsAtuais = usuarioPerfil.posts || [];
      const postsAtualizados = postsAtuais.map((p) => {
        if (String(p.id) !== String(postId)) return p;
        return {
          ...p,
          comentarios: [...(p.comentarios || []), novoComentario],
        };
      });

      await atualizarPosts(postsAtualizados);
      setComentario("");

      if (user.uid !== userId) {
        await addDoc(collection(db, "notificacoes"), {
          tipo: "comentario",
          de: usuarioLogado?.nome || user.displayName || "Pescador",
          de_id: user.uid,
          para: userId,
          texto: textoComentario,
          postId: postId,
          createdAt: serverTimestamp(),
          lida: false,
        });
      }
    } catch (error) {
      console.error("Erro ao comentar:", error);
    } finally {
      setEnviando(false);
    }
  };

  const handleCompartilhar = async () => {
    const url = window.location.href;
    try {
      if (navigator.share) {
        await navigator.share({ title: "Pesque & Fale", text: `Olha essa publicação em ${post?.local}!`, url });
      } else {
        await navigator.clipboard.writeText(url);
        setLinkCopiado(true);
        setTimeout(() => setLinkCopiado(false), 2500);
      }
    } catch (e) {
      // usuário cancelou
    }
  };

  const handleExcluir = () => setModalExclusao(true);

  const confirmarExcluir = async () => {
    setExcluindo(true);
    try {
      const postsAtualizados = (usuarioPerfil.posts || []).filter(
        (p) => String(p.id) !== String(postId)
      );
      await atualizarPosts(postsAtualizados);
      navigate("/perfil");
    } catch (e) {
      setExcluindo(false);
      setModalExclusao(false);
      mostrarFeedback("Erro ao excluir. Tente novamente.", "erro");
    }
  };

  if (carregando) {
    return (
      <Layout>
        <div className="vp-carregando">
          <span className="material-symbols-outlined vp-carregando-icone">hourglass_top</span>
          <p>Carregando publicação...</p>
        </div>
      </Layout>
    );
  }

  if (!post) {
    return (
      <Layout>
        <div className="vp-nao-encontrado">
          <span className="material-symbols-outlined vp-nao-encontrado-icone">search_off</span>
          <p>Publicação não encontrada.</p>
          <button className="vp-btn-voltar-erro" onClick={() => navigate(-1)}>Voltar</button>
        </div>
      </Layout>
    );
  }

  const isDono = user?.uid === userId;

  return (
    <Layout>
      <div className="vp-container">

        {/* CABEÇALHO */}
        <div className="vp-header">
          <button className="vp-voltar" onClick={() => navigate(-1)}>
            <span className="material-symbols-outlined">arrow_back</span>
            Voltar
          </button>
        </div>

        {/* FEEDBACK */}
        {feedback && (
          <div className={`vp-feedback vp-feedback-${feedback.tipo}`}>
            <span className="material-symbols-outlined">
              {feedback.tipo === "erro" ? "error" : "check_circle"}
            </span>
            {feedback.msg}
          </div>
        )}

        {/* MODAL EXCLUSÃO */}
        {modalExclusao && (
          <div className="vp-modal-fundo" onClick={() => !excluindo && setModalExclusao(false)}>
            <div className="vp-modal" onClick={(e) => e.stopPropagation()}>
              <div className="vp-modal-icone">
                <span className="material-symbols-outlined">delete_forever</span>
              </div>
              <h2 className="vp-modal-titulo">Excluir publicação?</h2>
              <p className="vp-modal-texto">
                Essa ação não pode ser desfeita. A publicação será removida permanentemente.
              </p>
              <div className="vp-modal-botoes">
                <button
                  className="vp-modal-btn-cancelar"
                  onClick={() => setModalExclusao(false)}
                  disabled={excluindo}
                >
                  Cancelar
                </button>
                <button
                  className="vp-modal-btn-excluir"
                  onClick={confirmarExcluir}
                  disabled={excluindo}
                >
                  {excluindo ? (
                    <>
                      <span className="material-symbols-outlined vp-enviando">hourglass_top</span>
                      Excluindo...
                    </>
                  ) : (
                    <>
                      <span className="material-symbols-outlined">delete</span>
                      Sim, excluir
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        )}

        <div className="vp-card">

          {/* FOTO */}
          <div className="vp-foto-wrapper">
            <img src={post.imagem} alt={post.local} className="vp-foto" />
          </div>

          <div className="vp-info">

            {/* AUTOR */}
            <div className="vp-autor">
<div className="vp-autor-clicavel" onClick={() => navigate(`/perfil/${userId}`)} title={`Ver perfil de ${usuarioPerfil?.nome}`}>
  {usuarioPerfil?.fotoPerfil ? (
    <img src={usuarioPerfil.fotoPerfil} alt={usuarioPerfil?.nome} className="vp-autor-foto" />
  ) : (
    <div className="vp-autor-foto-placeholder fallback">
      {usuarioPerfil?.nome ? usuarioPerfil.nome.charAt(0).toUpperCase() : "P"}
    </div>
  )}
</div>

              <div className="vp-autor-dados">
                <span
                  className="vp-autor-nome"
                  onClick={() => navigate(`/perfil/${userId}`)}
                  title={`Ver perfil de ${usuarioPerfil?.nome || "Pescador"}`}
                >
                  {usuarioPerfil?.nome || "Pescador"}
                </span>
                <span className="vp-data">{post.data}</span>
              </div>

              {isDono && (
                <button className="vp-btn-excluir" onClick={handleExcluir} title="Excluir post">
                  <span className="material-symbols-outlined">delete</span>
                </button>
              )}
            </div>

            {/* LOCAL */}
            <div className="vp-local">
              <span className="material-symbols-outlined vp-local-icone">location_on</span>
              <span className="vp-local-texto">{post.local}</span>
            </div>

            {/* AVALIAÇÃO */}
            {post.avaliacao && <div className="vp-avaliacao">{post.avaliacao}</div>}

            {/* DESCRIÇÃO */}
            {post.comentario && post.comentario !== "Sem descrição" && (
              <p className="vp-descricao">{post.comentario}</p>
            )}

            {/* TAGS */}
            {post.tags?.length > 0 && (
              <div className="vp-tags">
                {post.tags.map((tag) => (
                  <span key={tag} className="vp-tag">{tag}</span>
                ))}
              </div>
            )}

            {/* AÇÕES */}
            <div className="vp-acoes">
              <button
                className={`vp-btn-acao ${jaCurtiu ? "vp-btn-curtido" : ""}`}
                onClick={handleCurtir}
              >
                <span className="material-symbols-outlined">
                  {jaCurtiu ? "favorite" : "favorite_border"}
                </span>
                <span>{post.curtidas?.length || 0} {post.curtidas?.length === 1 ? "curtida" : "curtidas"}</span>
              </button>

              <button
                className="vp-btn-acao"
                onClick={() => document.getElementById("campo-comentario")?.focus()}
              >
                <span className="material-symbols-outlined">chat_bubble_outline</span>
                <span>{post.comentarios?.length || 0} {post.comentarios?.length === 1 ? "comentário" : "comentários"}</span>
              </button>

              <button
                className={`vp-btn-acao ${linkCopiado ? "vp-btn-copiado" : ""}`}
                onClick={handleCompartilhar}
              >
                <span className="material-symbols-outlined">
                  {linkCopiado ? "check" : "share"}
                </span>
                <span>{linkCopiado ? "Copiado!" : "Compartilhar"}</span>
              </button>
            </div>

            {/* COMENTÁRIOS */}
            <div className="vp-comentarios">
              <p className="vp-comentarios-aviso">
                <span className="material-symbols-outlined">info</span>
                Alguns posts podem parar de aceitar novos comentários devido ao limite de armazenamento do Firebase.
              </p>

              {/* LISTA COM SCROLL */}
              {post.comentarios?.length > 0 ? (
                <div className="vp-comentarios-lista">
                  {post.comentarios.map((c) => {
                    const fotoExibir = c.autorFoto || fotosComentarios[c.autorId];
                    return (
                      <div key={c.id || c.data} className="vp-comentario-item">
                        {/* Foto clicável */}
                        {fotoExibir ? (
                          <img
                            src={fotoExibir}
                            alt={c.autorNome}
                            className="vp-comentario-foto vp-comentario-foto--clickable"
                            onClick={() => c.autorId && navigate(`/perfil/${c.autorId}`)}
                            title={`Ver perfil de ${c.autorNome}`}
                          />
                        ) : (
                          <div
className="vp-comentario-foto-placeholder fallback vp-comentario-foto--clickable"
          onClick={() => c.autorId && navigate(`/perfil/${c.autorId}`)}
          title={`Ver perfil de ${c.autorNome}`}
                          >
                           {c.autorNome ? c.autorNome.charAt(0).toUpperCase() : "P"}                           
                          </div>
                        )}
                        <div className="vp-comentario-conteudo">
                          <span
                            className="vp-comentario-autor vp-comentario-autor--clickable"
                            onClick={() => c.autorId && navigate(`/perfil/${c.autorId}`)}
                          >
                            {c.autorNome || "Pescador"}
                          </span>
                          <p className="vp-comentario-texto">{c.texto}</p>
                          <span className="vp-comentario-data">{c.data}</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <p className="vp-sem-comentarios">Nenhum comentário ainda. Seja o primeiro!</p>
              )}

              {/* NOVO COMENTÁRIO COM FOTO DO USUÁRIO LOGADO */}
              {user && (
                <div className="vp-novo-comentario">
                  {usuarioLogado?.fotoPerfil ? (
                    <img src={usuarioLogado.fotoPerfil} alt="Você" className="vp-comentario-foto" />
                  ) : (
                    <div className="vp-comentario-foto-placeholder">
                      {usuarioLogado?.nome ? usuarioLogado.nome.charAt(0).toUpperCase() : "P"}
                    </div>
                  )}
                  <div className="vp-comentario-input-wrapper">
                    <input
                      id="campo-comentario"
                      type="text"
                      className="vp-comentario-input"
                      placeholder="Escreva um comentário..."
                      value={comentario}
                      onChange={(e) => setComentario(e.target.value)}
                      onKeyDown={(e) => e.key === "Enter" && handleComentar()}
                      maxLength={200}
                    />
                    <button
                      className="vp-comentario-enviar"
                      onClick={handleComentar}
                      disabled={!comentario.trim() || enviando}
                      title="Enviar comentário"
                    >
                      {enviando ? (
                        <span className="material-symbols-outlined vp-enviando">hourglass_top</span>
                      ) : (
                        <span className="material-symbols-outlined">send</span>
                      )}
                    </button>
                  </div>
                </div>
              )}
            </div>

          </div>
        </div>
      </div>
    </Layout>
  );
}
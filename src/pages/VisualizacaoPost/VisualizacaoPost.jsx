import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import Layout from "../../components/sidebar/layout";
import "./VisualizacaoPost.css";

import { db } from "../../firebase";
import {
  doc,
  onSnapshot,
  updateDoc,
  arrayUnion,
  arrayRemove,
} from "firebase/firestore";
import { observeAuthState } from "../../auth";

export default function VisualizacaoPost() {
  const { userId, postId } = useParams();
  const navigate = useNavigate();

  const [user, setUser] = useState(null);
  const [usuarioPerfil, setUsuarioPerfil] = useState(null);
  const [post, setPost] = useState(null);
  const [carregando, setCarregando] = useState(true);
  const [comentario, setComentario] = useState("");
  const [enviando, setEnviando] = useState(false);

  // Auth
  useEffect(() => {
    const unsubscribe = observeAuthState(setUser);
    return unsubscribe;
  }, []);

  // Busca o post via onSnapshot
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

  const jaCurtiu = post?.curtidas?.includes(user?.uid);

  // Atualiza os posts no Firestore
  const atualizarPosts = async (postsAtualizados) => {
    await updateDoc(doc(db, "usuarios", userId), {
      posts: postsAtualizados,
    });
  };

  // Curtir / Descurtir
  const handleCurtir = async () => {
    if (!user || !post) return;

    const postsAtuais = usuarioPerfil.posts || [];
    const postsAtualizados = postsAtuais.map((p) => {
      if (String(p.id) !== String(postId)) return p;

      const curtidas = p.curtidas || [];
      const jaCurtiu = curtidas.includes(user.uid);

      return {
        ...p,
        curtidas: jaCurtiu
          ? curtidas.filter((id) => id !== user.uid)
          : [...curtidas, user.uid],
      };
    });

    await atualizarPosts(postsAtualizados);
  };

  // Comentar
  const handleComentar = async () => {
    if (!user || !comentario.trim() || !post) return;

    setEnviando(true);

    const novoComentario = {
      id: Date.now(),
      texto: comentario.trim(),
      autorNome: user.displayName || "Pescador",
      autorFoto: user.photoURL || "",
      autorId: user.uid,
      data: new Date().toLocaleString(),
    };

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
    setEnviando(false);
  };

  // Compartilhar
  const handleCompartilhar = async () => {
    const url = window.location.href;
    if (navigator.share) {
      await navigator.share({ title: "Pesque & Fale", text: "Olha esse post!", url });
    } else {
      navigator.clipboard.writeText(url);
      alert("Link copiado!");
    }
  };

  // Excluir post (só dono)
  const handleExcluir = async () => {
    if (!window.confirm("Tem certeza que deseja excluir este post?")) return;

    const postsAtualizados = (usuarioPerfil.posts || []).filter(
      (p) => String(p.id) !== String(postId)
    );

    await atualizarPosts(postsAtualizados);
    navigate(`/perfil`);
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
          <button className="vp-btn-voltar-erro" onClick={() => navigate(-1)}>
            Voltar
          </button>
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

        <div className="vp-card">

          {/* FOTO DO POST */}
          <div className="vp-foto-wrapper">
            <img src={post.imagem} alt={post.local} className="vp-foto" />
          </div>

          {/* INFORMAÇÕES */}
          <div className="vp-info">

            {/* AUTOR */}
            <div className="vp-autor">
              <img
                src={usuarioPerfil?.fotoPerfil || "https://via.placeholder.com/40"}
                alt={usuarioPerfil?.nome}
                className="vp-autor-foto"
                onClick={() => navigate(`/perfil/${userId}`)}
              />
              <div className="vp-autor-dados">
                <span
                  className="vp-autor-nome"
                  onClick={() => navigate(`/perfil/${userId}`)}
                >
                  {usuarioPerfil?.nome || "Pescador"}
                </span>
                <span className="vp-data">{post.data}</span>
              </div>

              {/* Excluir — só dono */}
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
            {post.avaliacao && (
              <div className="vp-avaliacao">{post.avaliacao}</div>
            )}

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
                {post.curtidas?.length || 0}
              </button>

              <button className="vp-btn-acao" onClick={() => document.getElementById("campo-comentario").focus()}>
                <span className="material-symbols-outlined">chat_bubble_outline</span>
                {post.comentarios?.length || 0}
              </button>

              <button className="vp-btn-acao" onClick={handleCompartilhar}>
                <span className="material-symbols-outlined">share</span>
                Compartilhar
              </button>
            </div>

            {/* SEÇÃO DE COMENTÁRIOS */}
            <div className="vp-comentarios">
              <h3 className="vp-comentarios-titulo">
                Comentários ({post.comentarios?.length || 0})
              </h3>

              {/* Lista de comentários */}
              {post.comentarios?.length > 0 ? (
                <div className="vp-comentarios-lista">
                  {post.comentarios.map((c) => (
                    <div key={c.id} className="vp-comentario-item">
                      <img
                        src={c.autorFoto || "https://via.placeholder.com/36"}
                        alt={c.autorNome}
                        className="vp-comentario-foto"
                      />
                      <div className="vp-comentario-conteudo">
                        <span className="vp-comentario-autor">{c.autorNome}</span>
                        <p className="vp-comentario-texto">{c.texto}</p>
                        <span className="vp-comentario-data">{c.data}</span>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="vp-sem-comentarios">Nenhum comentário ainda. Seja o primeiro!</p>
              )}

              {/* Campo de novo comentário */}
              {user && (
                <div className="vp-novo-comentario">
                  <img
                    src={user.photoURL || "https://via.placeholder.com/36"}
                    alt="Você"
                    className="vp-comentario-foto"
                  />
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
                    >
                      <span className="material-symbols-outlined">send</span>
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
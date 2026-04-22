import React, { useState } from "react";
import "./Galeriaperfil.css";

import { db } from "../../firebase";
import { addDoc, collection, serverTimestamp } from "firebase/firestore";

export default function GaleriaPerfil({
  posts,
  user,
  usuarioPerfil,
  salvarPosts,
}) {
  const [postSelecionado, setPostSelecionado] = useState(null);

  const abrirPost = (post) => setPostSelecionado(post);
  const fecharPost = () => setPostSelecionado(null);

  const getCurtidasArray = (curtidas) => {
    if (Array.isArray(curtidas)) return curtidas;
    if (typeof curtidas === "number") return [];
    return [];
  };

  // 👍 CURTIR + NOTIFICAÇÃO (CORRIGIDO)
  const handleCurtir = async (post) => {
    if (!user) return alert("Faça login");

    const curtidasAntes = getCurtidasArray(post.curtidas);
    const jaCurtiuAntes = curtidasAntes.includes(user.uid);

    const novosPosts = posts.map((p) => {
      if (p.id !== post.id) return p;

      return {
        ...p,
        curtidas: jaCurtiuAntes
          ? curtidasAntes.filter((id) => id !== user.uid)
          : [...curtidasAntes, user.uid],
      };
    });

    await salvarPosts(novosPosts);

    const atualizado = novosPosts.find((p) => p.id === post.id);
    setPostSelecionado(atualizado);

    // 🔥 NOTIFICAÇÃO CORRETA
    if (!jaCurtiuAntes && user.uid !== usuarioPerfil?.id) {
      try {
        await addDoc(collection(db, "notificacoes"), {
          tipo: "curtida", // ✅ CORRIGIDO AQUI
          de: user.displayName || "Usuário",
          para: usuarioPerfil.id,
          postId: post.id,
          createdAt: serverTimestamp(),
          lida: false,
        });
      } catch (error) {
        console.error("Erro ao criar notificação de curtida:", error);
      }
    }
  };

  // 💬 COMENTAR + NOTIFICAÇÃO
  const handleComentar = async (post) => {
    if (!user) return alert("Faça login");

    const texto = prompt("Digite seu comentário:");
    if (!texto) return;

    const novoComentario = {
      texto,
      userId: user.uid,
      nome: user.displayName || "Usuário",
      data: new Date().toLocaleString(),
    };

    const novosPosts = posts.map((p) =>
      p.id === post.id
        ? {
            ...p,
            comentarios: [...(p.comentarios || []), novoComentario],
          }
        : p
    );

    await salvarPosts(novosPosts);

    const atualizado = novosPosts.find((p) => p.id === post.id);
    setPostSelecionado(atualizado);

    // 🔥 NOTIFICAÇÃO
    if (user.uid !== usuarioPerfil?.id) {
      try {
        await addDoc(collection(db, "notificacoes"), {
          tipo: "comentario",
          de: user.displayName || "Usuário",
          para: usuarioPerfil.id,
          texto: texto,
          postId: post.id,
          createdAt: serverTimestamp(),
          lida: false,
        });
      } catch (error) {
        console.error("Erro ao criar notificação de comentário:", error);
      }
    }
  };

  // 🗑️ DELETAR
  const handleDeletar = (post) => {
    if (user?.uid !== usuarioPerfil?.id) return;

    if (!window.confirm("Tem certeza que deseja excluir este post?")) return;

    const novosPosts = posts.filter((p) => p.id !== post.id);

    salvarPosts(novosPosts);
    fecharPost();
  };

  // 🔗 COMPARTILHAR
  const handleShare = async (post) => {
    const url = window.location.href;

    if (navigator.share) {
      await navigator.share({
        title: "Pesque & Fale",
        text: `Olha essa publicação em ${post.local}`,
        url,
      });
    } else {
      navigator.clipboard.writeText(url);
      alert("Link copiado!");
    }
  };

  const contarCurtidas = (post) => {
    return Array.isArray(post.curtidas)
      ? post.curtidas.length
      : post.curtidas || 0;
  };

  if (!posts.length) {
    return (
      <div className="galeria-vazia">
        <span className="material-symbols-outlined galeria-vazia-icone">
          photo_camera
        </span>
        <p>Nenhuma publicação ainda.</p>
        <span>Clique em "Nova Publicação" para começar!</span>
      </div>
    );
  }

  return (
    <>
      <div className="galeria-grid">
        {posts.map((post) => (
          <div
            key={post.id}
            className="galeria-item"
            onClick={() => abrirPost(post)}
          >
            <img src={post.imagem} alt={post.local} className="galeria-foto" />

            <div className="galeria-overlay">
              <span className="galeria-overlay-info">
                👍 {contarCurtidas(post)}
              </span>
              <span className="galeria-overlay-info">
                💬 {post.comentarios?.length || 0}
              </span>
            </div>
          </div>
        ))}
      </div>

      {postSelecionado && (
        <div className="galeria-modal-fundo" onClick={fecharPost}>
          <div
            className="galeria-modal"
            onClick={(e) => e.stopPropagation()}
          >
            <button className="galeria-modal-fechar" onClick={fecharPost}>
              <span className="material-symbols-outlined">close</span>
            </button>

            <img
              src={postSelecionado.imagem}
              alt={postSelecionado.local}
              className="galeria-modal-foto"
            />

            <div className="galeria-modal-info">
              <p className="galeria-modal-data">
                {postSelecionado.data}
              </p>
              <p className="galeria-modal-local">
                {postSelecionado.local}
              </p>
              <p className="galeria-modal-comentario">
                {postSelecionado.comentario}
              </p>

              <div className="galeria-modal-acoes">
                <button
                  className="btn-interacao"
                  onClick={() => handleCurtir(postSelecionado)}
                >
                  👍 {contarCurtidas(postSelecionado)}
                </button>

                <button
                  className="btn-interacao"
                  onClick={() => handleComentar(postSelecionado)}
                >
                  💬 {postSelecionado.comentarios?.length || 0}
                </button>

                <button
                  className="btn-interacao"
                  onClick={() => handleShare(postSelecionado)}
                >
                  🔗 Compartilhar
                </button>

                {user?.uid === usuarioPerfil?.id && (
                  <button
                    className="btn-interacao btn-deletar"
                    onClick={() => handleDeletar(postSelecionado)}
                  >
                    🗑️ Excluir
                  </button>
                )}
              </div>

              {postSelecionado.comentarios?.length > 0 && (
                <div className="galeria-modal-comentarios">
                  {postSelecionado.comentarios.map((c, i) => (
                    <p key={i}>
                      💬 <strong>{c.nome || "Usuário"}</strong>:{" "}
                      {c.texto || c}
                    </p>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
}
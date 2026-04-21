import React, { useState } from "react";
import "./Galeriaperfil.css";

import { db } from "../../firebase";
import { doc, updateDoc } from "firebase/firestore";

export default function GaleriaPerfil({ posts, onShare, user, usuarioPerfil }) {
  const [postSelecionado, setPostSelecionado] = useState(null);

  const abrirPost = (post) => setPostSelecionado(post);
  const fecharPost = () => setPostSelecionado(null);

  // 👍 CURTIR (CORRIGIDO)
  const handleCurtir = async (post) => {
    try {
      const novosPosts = posts.map((p) =>
        p.id === post.id
          ? { ...p, curtidas: (p.curtidas || 0) + 1 }
          : p
      );

      const docRef = doc(db, "usuarios", usuarioPerfil.id);

      await updateDoc(docRef, {
        posts: novosPosts,
      });

      setPostSelecionado({
        ...postSelecionado,
        curtidas: (postSelecionado.curtidas || 0) + 1,
      });

    } catch (error) {
      console.error("Erro ao curtir:", error);
    }
  };

  // 💬 COMENTAR (CORRIGIDO)
  const handleComentar = async (post) => {
    const texto = prompt("Digite seu comentário:");
    if (!texto) return;

    try {
      const novosPosts = posts.map((p) =>
        p.id === post.id
          ? {
              ...p,
              comentarios: [...(p.comentarios || []), texto],
            }
          : p
      );

      const docRef = doc(db, "usuarios", usuarioPerfil.id);

      await updateDoc(docRef, {
        posts: novosPosts,
      });

      setPostSelecionado({
        ...postSelecionado,
        comentarios: [...(postSelecionado.comentarios || []), texto],
      });

    } catch (error) {
      console.error("Erro ao comentar:", error);
    }
  };

  // 🗑️ DELETAR (SÓ DONO)
  const handleDeletar = async (post) => {
    if (!window.confirm("Tem certeza que deseja excluir este post?")) return;

    try {
      const novosPosts = posts.filter((p) => p.id !== post.id);

      const docRef = doc(db, "usuarios", usuarioPerfil.id);

      await updateDoc(docRef, {
        posts: novosPosts,
      });

      fecharPost();
      window.location.reload();

    } catch (error) {
      console.error("Erro ao deletar:", error);
    }
  };

  if (posts.length === 0) {
    return (
      <div className="galeria-vazia">
        <span className="material-symbols-outlined galeria-vazia-icone">photo_camera</span>
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
                👍 {post.curtidas || 0}
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
              <p className="galeria-modal-data">Postado em {postSelecionado.data}</p>
              <p className="galeria-modal-local">{postSelecionado.local}</p>
              <p className="galeria-modal-comentario">{postSelecionado.comentario}</p>
              <p className="galeria-modal-avaliacao">{postSelecionado.avaliacao}</p>

              <div className="galeria-modal-acoes">
                <button
                  className="btn-interacao"
                  onClick={() => handleCurtir(postSelecionado)}
                >
                  👍 {postSelecionado.curtidas || 0}
                </button>

                <button
                  className="btn-interacao"
                  onClick={() => handleComentar(postSelecionado)}
                >
                  💬 {postSelecionado.comentarios?.length || 0}
                </button>

                <button className="btn-interacao" onClick={onShare}>
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
                    <p key={i}>💬 {c}</p>
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
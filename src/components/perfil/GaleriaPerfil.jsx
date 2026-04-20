import React, { useState } from "react";
import "./Galeriaperfil.css";

export default function GaleriaPerfil({ posts, onCurtir, onComentar, onShare, onDeletar }) {
  const [postSelecionado, setPostSelecionado] = useState(null);

  const abrirPost = (post) => setPostSelecionado(post);
  const fecharPost = () => setPostSelecionado(null);

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
      {/* GRID 3x3 */}
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
                👍 {post.curtidas}
              </span>
              <span className="galeria-overlay-info">
                💬 {post.comentarios?.length || 0}
              </span>
            </div>
          </div>
        ))}
      </div>

      {/* MODAL DO POST SELECIONADO */}
      {postSelecionado && (
        <div className="galeria-modal-fundo" onClick={fecharPost}>
          <div
            className="galeria-modal"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Botão fechar */}
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
                  onClick={() => onCurtir(postSelecionado.id)}
                >
                  👍 {postSelecionado.curtidas}
                </button>
                <button
                  className="btn-interacao"
                  onClick={() => onComentar(postSelecionado.id)}
                >
                  💬 {postSelecionado.comentarios?.length || 0}
                </button>
                <button className="btn-interacao" onClick={onShare}>
                  🔗 Compartilhar
                </button>
                <button
                  className="btn-interacao btn-deletar"
                  onClick={() => {
                    onDeletar(postSelecionado.id);
                    fecharPost();
                  }}
                >
                  🗑️ Excluir
                </button>
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
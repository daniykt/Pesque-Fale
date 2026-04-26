import React from "react";
import "./Galeriaperfil.css";

export default function GaleriaPerfil({
  posts,
  user,
  usuarioPerfil,
  salvarPosts,
  navigate, // ← recebe navigate como prop
}) {
  const getCurtidasArray = (curtidas) => {
    if (Array.isArray(curtidas)) return curtidas;
    return [];
  };

  const contarCurtidas = (post) => {
    return Array.isArray(post.curtidas) ? post.curtidas.length : post.curtidas || 0;
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
    <div className="galeria-grid">
      {posts.map((post) => (
        <div
          key={post.id}
          className="galeria-item"
          onClick={() => navigate(`/post/${usuarioPerfil.id}/${post.id}`)}
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
  );
}
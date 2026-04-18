import React from "react";

export default function GaleriaPerfil({ posts, onCurtir, onComentar, onShare, onDeletar }) {
  return (
    <div className="publicacoes">
      {posts.map((post) => (
        <div className="publicacao-horizontal" key={post.id}>
          <img src={post.imagem} alt="Post" className="foto-horizontal" />

          <div className="info-direita">
            <div className="data-publicacao">Postado em {post.data}</div>
            <div className="comentario">{post.comentario}</div>
            <div className="local">{post.local}</div>
            <div className="avaliacao">{post.avaliacao}</div>

            <div className="interacoes">
              <button className="btn-interacao" onClick={() => onCurtir(post.id)}>
                👍 {post.curtidas}
              </button>
              <button className="btn-interacao" onClick={() => onComentar(post.id)}>
                💬 {post.comentarios?.length || 0}
              </button>
              <button className="btn-interacao" onClick={onShare}>
                🔗 Compartilhar
              </button>
              <button className="btn-interacao" onClick={() => onDeletar(post.id)}>
                🗑️ Excluir
              </button>
            </div>

            {post.comentarios?.length > 0 && (
              <div className="lista-comentarios">
                {post.comentarios.map((c, index) => (
                  <p key={index}>💬 {c}</p>
                ))}
              </div>
            )}
          </div>
        </div>
      ))}
    </div>
  );
}
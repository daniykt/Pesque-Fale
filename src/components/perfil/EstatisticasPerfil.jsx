import React from "react";

export default function EstatisticasPerfil({ totalPosts, usuario }) {
  // 🔥 pega direto do Firestore
  const seguidores = usuario?.seguidores?.length || 0;
  const seguindo = usuario?.seguindo?.length || 0;

  return (
    <div className="profile-stats">
      <div className="stat-box">
        <span className="number">{totalPosts}</span>
        <span className="label">Publicações</span>
      </div>

      <div className="stat-box">
        <span className="number">{seguidores}</span>
        <span className="label">Seguidores</span>
      </div>

      <div className="stat-box">
        <span className="number">{seguindo}</span>
        <span className="label">Seguindo</span>
      </div>
    </div>
  );
}
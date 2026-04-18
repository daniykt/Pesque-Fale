import React from "react";

export default function EstatisticasPerfil({ totalPosts }) {
  return (
    <div className="profile-stats">
      <div className="stat-box">
        <span className="number">{totalPosts}</span>
        <span className="label">Publicações</span>
      </div>
      <div className="stat-box">
        <span className="number">200</span>
        <span className="label">Seguidores</span>
      </div>
      <div className="stat-box">
        <span className="number">180</span>
        <span className="label">Seguindo</span>
      </div>
    </div>
  );
}
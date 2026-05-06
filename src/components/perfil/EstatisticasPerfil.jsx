import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { db } from "../../firebase";
import { doc, getDoc } from "firebase/firestore";

function ModalUsuarios({ titulo, ids, onFechar }) {
  const navigate = useNavigate();
  const [usuarios, setUsuarios] = useState([]);
  const [carregando, setCarregando] = useState(true);

  useEffect(() => {
    if (!ids || ids.length === 0) {
      setCarregando(false);
      return;
    }

    const buscar = async () => {
      const promises = ids.map((id) =>
        getDoc(doc(db, "usuarios", id)).then((snap) =>
          snap.exists() ? { id: snap.id, ...snap.data() } : null
        )
      );
      const results = await Promise.all(promises);
      setUsuarios(results.filter(Boolean));
      setCarregando(false);
    };

    buscar();
  }, [ids]);

  const irParaPerfil = (id) => {
    onFechar();
    navigate(`/perfil/${id}`);
  };

  return (
    <div
      className="modal-seguidores-fundo"
      onClick={onFechar}
    >
      <div
        className="modal-seguidores"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="modal-seguidores-header">
          <h3 className="modal-seguidores-titulo">{titulo}</h3>
          <button className="modal-seguidores-fechar" onClick={onFechar}>
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>

        <div className="modal-seguidores-lista">
          {carregando ? (
            <div className="modal-vazio">
              <span className="material-symbols-outlined">hourglass_empty</span>
              <p>Carregando...</p>
            </div>
          ) : usuarios.length === 0 ? (
            <div className="modal-vazio">
              <span className="material-symbols-outlined">person_off</span>
              <p>Nenhum usuário encontrado.</p>
            </div>
          ) : (
            usuarios.map((u) => (
              <div
                key={u.id}
                className="modal-usuario-item"
                onClick={() => irParaPerfil(u.id)}
              >
                {u.fotoPerfil ? (
                  <img
                    src={u.fotoPerfil}
                    alt={u.nome}
                    className="modal-usuario-foto"
                  />
                ) : (
                  <div className="modal-usuario-foto-placeholder">
                    <span className="material-symbols-outlined">person</span>
                  </div>
                )}
                <span className="modal-usuario-nome">{u.nome || "Usuário"}</span>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}

export default function EstatisticasPerfil({ totalPosts, usuario }) {
  const [modalAberto, setModalAberto] = useState(null); // 'seguidores' | 'seguindo' | null

  const seguidores = usuario?.seguidores || [];
  const seguindo   = usuario?.seguindo   || [];

  return (
    <>
      <div className="profile-stats">
        <div className="stat-box">
          <span className="number">{totalPosts}</span>
          <span className="label">Publicações</span>
        </div>

        <div
          className="stat-box stat-clicavel"
          onClick={() => seguidores.length > 0 && setModalAberto("seguidores")}
          title="Ver seguidores"
        >
          <span className="number">{seguidores.length}</span>
          <span className="label">Seguidores</span>
        </div>

        <div
          className="stat-box stat-clicavel"
          onClick={() => seguindo.length > 0 && setModalAberto("seguindo")}
          title="Ver quem você segue"
        >
          <span className="number">{seguindo.length}</span>
          <span className="label">Seguindo</span>
        </div>
      </div>

      {modalAberto === "seguidores" && (
        <ModalUsuarios
          titulo="Seguidores"
          ids={seguidores}
          onFechar={() => setModalAberto(null)}
        />
      )}

      {modalAberto === "seguindo" && (
        <ModalUsuarios
          titulo="Seguindo"
          ids={seguindo}
          onFechar={() => setModalAberto(null)}
        />
      )}
    </>
  );
}
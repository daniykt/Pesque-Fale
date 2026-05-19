import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { db } from "../../firebase";
import {
  doc,
  getDoc,
  updateDoc,
  arrayUnion,
  arrayRemove,
  addDoc,
  collection,
  serverTimestamp,
  query,
  where,
  getDocs,
  deleteDoc,
} from "firebase/firestore";

// ── Modal de lista de usuários (seguidores / seguindo) ──
function ModalUsuarios({ titulo, ids, currentUserId, isOwnProfile, onFechar }) {
  const navigate = useNavigate();
  const [usuarios, setUsuarios] = useState([]);
  const [carregando, setCarregando] = useState(true);
  // Mapa de uid → true se currentUser já segue aquele usuario
  const [seguindoMap, setSeguindoMap] = useState({});
  const [loadingMap, setLoadingMap] = useState({});

  // Busca usuários e, se for o próprio perfil olhando seus seguidores,
  // busca quem o currentUser já segue para mostrar o botão correto
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
      const validos = results.filter(Boolean);
      setUsuarios(validos);

      // Descobre quem currentUser já segue (para o botão seguir de volta)
      if (currentUserId) {
        const meSnap = await getDoc(doc(db, "usuarios", currentUserId));
        const meusSeguindo = meSnap.exists() ? meSnap.data().seguindo || [] : [];
        const mapa = {};
        validos.forEach((u) => {
          mapa[u.id] = meusSeguindo.includes(u.id);
        });
        setSeguindoMap(mapa);
      }

      setCarregando(false);
    };

    buscar();
  }, [ids, currentUserId]);

  const irParaPerfil = (id) => {
    onFechar();
    navigate(`/perfil/${id}`);
  };

  // ── Seguir de volta direto (sem solicitação) ──
  const seguirDeVolta = async (e, usuarioAlvo) => {
    e.stopPropagation();
    if (!currentUserId || loadingMap[usuarioAlvo.id]) return;

    setLoadingMap((prev) => ({ ...prev, [usuarioAlvo.id]: true }));

    try {
      // Adiciona alvo nos "seguindo" do currentUser
      await updateDoc(doc(db, "usuarios", currentUserId), {
        seguindo: arrayUnion(usuarioAlvo.id),
      });
      // Adiciona currentUser nos "seguidores" do alvo
      await updateDoc(doc(db, "usuarios", usuarioAlvo.id), {
        seguidores: arrayUnion(currentUserId),
      });
      // Busca nome do currentUser para notificação
      const meSnap = await getDoc(doc(db, "usuarios", currentUserId));
      const meuNome = meSnap.exists() ? meSnap.data().nome || "Pescador" : "Pescador";
      // Notifica o alvo que foi seguido de volta
      await addDoc(collection(db, "notificacoes"), {
        tipo: "seguindo",
        de: meuNome,
        de_id: currentUserId,
        para: usuarioAlvo.id,
        lida: false,
        createdAt: serverTimestamp(),
      });
      setSeguindoMap((prev) => ({ ...prev, [usuarioAlvo.id]: true }));
    } catch (err) {
      console.error("Erro ao seguir de volta:", err);
    } finally {
      setLoadingMap((prev) => ({ ...prev, [usuarioAlvo.id]: false }));
    }
  };

  // ── Deixar de seguir (dentro do modal) ──
  const deixarDeSeguir = async (e, usuarioAlvo) => {
    e.stopPropagation();
    if (!currentUserId || loadingMap[usuarioAlvo.id]) return;

    setLoadingMap((prev) => ({ ...prev, [usuarioAlvo.id]: true }));

    try {
      await updateDoc(doc(db, "usuarios", currentUserId), {
        seguindo: arrayRemove(usuarioAlvo.id),
      });
      await updateDoc(doc(db, "usuarios", usuarioAlvo.id), {
        seguidores: arrayRemove(currentUserId),
      });
      // Remove notificação de seguindo que enviamos anteriormente
      const q = query(
        collection(db, "notificacoes"),
        where("tipo", "==", "seguindo"),
        where("de_id", "==", currentUserId),
        where("para", "==", usuarioAlvo.id)
      );
      const snap = await getDocs(q);
      await Promise.all(snap.docs.map((d) => deleteDoc(d.ref)));

      setSeguindoMap((prev) => ({ ...prev, [usuarioAlvo.id]: false }));
    } catch (err) {
      console.error("Erro ao deixar de seguir:", err);
    } finally {
      setLoadingMap((prev) => ({ ...prev, [usuarioAlvo.id]: false }));
    }
  };

  return (
    <div className="modal-seguidores-fundo" onClick={onFechar}>
      <div className="modal-seguidores" onClick={(e) => e.stopPropagation()}>
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
            usuarios.map((u) => {
              const jaSeguindo = seguindoMap[u.id];
              const carregandoBtn = loadingMap[u.id];
              // Não mostra botão no próprio perfil do currentUser
              const ehOMesmo = u.id === currentUserId;

              return (
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

                  {/* Botão seguir/seguindo — só para usuários que não são o próprio */}
                  {!ehOMesmo && (
                    <button
                      className={`modal-btn-seguir ${jaSeguindo ? "modal-btn-seguindo" : ""}`}
                      onClick={(e) =>
                        jaSeguindo
                          ? deixarDeSeguir(e, u)
                          : seguirDeVolta(e, u)
                      }
                      disabled={carregandoBtn}
                    >
                      {carregandoBtn ? (
                        <span className="material-symbols-outlined modal-btn-loading">
                          hourglass_empty
                        </span>
                      ) : jaSeguindo ? (
                        <>
                          <span className="material-symbols-outlined">person_check</span>
                          Seguindo
                        </>
                      ) : (
                        <>
                          <span className="material-symbols-outlined">person_add</span>
                          Seguir
                        </>
                      )}
                    </button>
                  )}
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
}

export default function EstatisticasPerfil({ totalPosts, usuario, currentUserId, isOwnProfile }) {
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
          currentUserId={currentUserId}
          isOwnProfile={isOwnProfile}
          onFechar={() => setModalAberto(null)}
        />
      )}

      {modalAberto === "seguindo" && (
        <ModalUsuarios
          titulo="Seguindo"
          ids={seguindo}
          currentUserId={currentUserId}
          isOwnProfile={isOwnProfile}
          onFechar={() => setModalAberto(null)}
        />
      )}
    </>
  );
}
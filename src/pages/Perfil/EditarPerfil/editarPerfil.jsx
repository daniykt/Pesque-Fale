import React, { useState, useRef, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import Layout from "../../../components/sidebar/layout";
import "./Editarperfil.css";

import { db } from "../../../firebase";
import { doc, setDoc, getDoc } from "firebase/firestore";
import { observeAuthState } from "../../../auth";
import {
  validarUsername,
  verificarDisponibilidade,
} from "../../../utils/usernameUtils";

export default function EditarPerfil() {
  const navigate = useNavigate();

  const [user, setUser] = useState(null);

  const [nome, setNome] = useState("");
  const [bio, setBio] = useState("");
  const [localizacao, setLocalizacao] = useState("");
  const [fotoPerfil, setFotoPerfil] = useState("");
  const [banner, setBanner] = useState("");

  // ========== NOVO: estados do username ==========
  const [username, setUsername] = useState("");
  const [usernameOriginal, setUsernameOriginal] = useState("");
  const [usernameStatus, setUsernameStatus] = useState({
    disponivel: false,
    mensagem: "",
    verificando: false,
  });

  const [salvando, setSalvando] = useState(false);
  const [salvo, setSalvo] = useState(false);
  const [erro, setErro] = useState("");

  const fotoInputRef = useRef(null);
  const bannerInputRef = useRef(null);

  const handleResetUsername = () => {
  setUsername(usernameOriginal);
  // Reseta o status para o valor original válido
  if (usernameOriginal) {
    setUsernameStatus({
      disponivel: true,
      mensagem: "✅ Username atual",
      verificando: false,
    });
  } else {
    setUsernameStatus({
      disponivel: false,
      mensagem: "",
      verificando: false,
    });
  }
};

  // 🔐 pega usuário logado
  useEffect(() => {
    const unsubscribe = observeAuthState((currentUser) => {
      setUser(currentUser);
    });
    return unsubscribe;
  }, []);

  // 🔥 CARREGAR DADOS DO FIRESTORE
  useEffect(() => {
    const carregarDados = async () => {
      if (!user) return;

      try {
        const docRef = doc(db, "usuarios", user.uid);
        const snap = await getDoc(docRef);

        if (snap.exists()) {
          const data = snap.data();

          setNome(data.nome || "");
          setBio(data.bio || "");
          setLocalizacao(data.localizacao || "");
          setFotoPerfil(data.fotoPerfil || "");
          setBanner(data.banner || "");

          // Carrega username
          const uname = data.username || "";
          setUsername(uname);
          setUsernameOriginal(uname);
          if (uname) {
            setUsernameStatus({
              disponivel: true,
              mensagem: "✅ Username atual",
              verificando: false,
            });
          } else {
            setUsernameStatus({
              disponivel: false,
              mensagem: "",
              verificando: false,
            });
          }
        }
      } catch (e) {
        console.error("Erro ao carregar perfil:", e);
      }
    };

    carregarDados();
  }, [user]);

  // ========== DEBOUNCE para verificar username ==========
  useEffect(() => {
    const timer = setTimeout(async () => {
      // Se o username não mudou, não precisa verificar
      if (username === usernameOriginal) {
        setUsernameStatus((prev) => ({
          ...prev,
          disponivel: true,
          mensagem: username ? "✅ Username atual" : "",
          verificando: false,
        }));
        return;
      }

      // Campo vazio
      if (!username || username.trim() === "") {
        setUsernameStatus({
          disponivel: false,
          mensagem: "",
          verificando: false,
        });
        return;
      }

      // Valida formato
      if (!validarUsername(username)) {
        setUsernameStatus({
          disponivel: false,
          mensagem: "3-20 caracteres. Use letras, números, _ ou .",
          verificando: false,
        });
        return;
      }

      // Verifica disponibilidade (ignora o próprio usuário)
      setUsernameStatus((prev) => ({ ...prev, verificando: true }));
      const disponivel = await verificarDisponibilidade(username, user?.uid);
      setUsernameStatus({
        disponivel,
        mensagem: disponivel ? "✅ Disponível" : "❌ Indisponível",
        verificando: false,
      });
    }, 500);

    return () => clearTimeout(timer);
  }, [username, usernameOriginal, user?.uid]);

  const handleFotoChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => setFotoPerfil(reader.result);
    reader.readAsDataURL(file);
  };

  const handleBannerChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => setBanner(reader.result);
    reader.readAsDataURL(file);
  };

  const handleSalvar = async () => {
    setErro("");

    if (!nome.trim()) {
      setErro("O nome não pode ficar vazio.");
      return;
    }

    // Valida username se foi preenchido
    if (username && username.trim() !== "") {
      if (!validarUsername(username)) {
        setErro(
          "Username inválido. Use 3-20 caracteres, letras, números, _ ou ."
        );
        return;
      }
      if (!usernameStatus.disponivel) {
        setErro("Username indisponível. Escolha outro.");
        return;
      }
    }

    if (!user) {
      setErro("Usuário não autenticado.");
      return;
    }

    setSalvando(true);

    try {
      const updateData = {
        nome,
        bio,
        localizacao,
        fotoPerfil,
        banner,
      };
      // Só envia username se não estiver vazio (ou se for string vazia para remover? Melhor não remover)
      if (username && username.trim() !== "") {
        updateData.username = username.trim();
      } else if (usernameOriginal && !username) {
        // Se o usuário removeu o username, permitir? Vou manter como não remove, apenas não altera.
        // Mas para ser consistente, se ele apagou o campo, não salvamos username (deixa como estava).
        // A UI não permite apagar completamente, mas por segurança:
        if (username === "") {
          // Não enviar username, mantém o antigo
        }
      }

      await setDoc(doc(db, "usuarios", user.uid), updateData, { merge: true });

      // Atualiza cache local
      localStorage.setItem(
        "usuarioCache",
        JSON.stringify({
          nome,
          bio,
          localizacao,
          fotoPerfil,
          banner,
          username: username || usernameOriginal,
        })
      );

      setSalvando(false);
      setSalvo(true);

      setTimeout(() => navigate("/perfil"), 500);
    } catch (error) {
      console.error(error);
      setErro("Erro ao salvar.");
      setSalvando(false);
    }
  };

  return (
    <Layout>
      <div className="editar-perfil-container">
        <div className="editar-perfil-header">
          <button className="btn-voltar" onClick={() => navigate("/perfil")}>
            <span className="material-symbols-outlined">arrow_back</span>
            Voltar
          </button>
          <h1 className="editar-perfil-titulo">Editar Perfil</h1>
        </div>

        <div className="editar-perfil-card">
          {/* BANNER */}
          <div className="editar-secao">
            <label className="editar-label">Foto de Capa</label>
            <div
              className="editar-banner-preview"
              onClick={() => bannerInputRef.current.click()}
              style={{ backgroundImage: banner ? `url(${banner})` : undefined }}
            >
              {!banner && (
                <div className="editar-banner-vazio">
                  <span className="material-symbols-outlined">
                    add_photo_alternate
                  </span>
                  <p>Clique para adicionar uma capa</p>
                </div>
              )}
              <div className="editar-banner-overlay">
                <span className="material-symbols-outlined">photo_camera</span>
                <p>Trocar capa</p>
              </div>
            </div>
            <input
              type="file"
              accept="image/*"
              ref={bannerInputRef}
              style={{ display: "none" }}
              onChange={handleBannerChange}
            />
          </div>

          {/* FOTO */}
          <div className="editar-secao editar-secao-foto">
            <label className="editar-label">Foto de Perfil</label>
            <div
              className="editar-foto-wrapper"
              onClick={() => fotoInputRef.current.click()}
            >
              {fotoPerfil ? (
                <img
                  src={fotoPerfil}
                  alt="Foto"
                  className="editar-foto-preview"
                />
              ) : (
                <div className="editar-foto-vazio">
                  <span className="material-symbols-outlined">person</span>
                </div>
              )}
              <div className="editar-foto-overlay">
                <span className="material-symbols-outlined">photo_camera</span>
              </div>
            </div>
            <input
              type="file"
              accept="image/*"
              ref={fotoInputRef}
              style={{ display: "none" }}
              onChange={handleFotoChange}
            />
          </div>

          {/* NOME */}
          <div className="editar-secao">
            <label className="editar-label">Nome</label>
            <input
              className={`editar-input ${erro && !nome.trim() ? "editar-input-erro" : ""}`}
              value={nome}
              onChange={(e) => setNome(e.target.value)}
            />
          </div>

          {/* ========== NOVO CAMPO USERNAME ========== */}
<div className="editar-secao">
  <label className="editar-label">Username</label>
  <div className="editar-input-icone">
    <span className="material-symbols-outlined editar-input-icone-symbol">
      alternate_email
    </span>
    <input
      className={`editar-input editar-input-com-icone ${
        (usernameStatus.mensagem.includes("❌") ||
          (usernameStatus.mensagem.includes("inválido") &&
            !usernameStatus.verificando))
          ? "editar-input-erro"
          : ""
      }`}
      value={username}
      onChange={(e) => setUsername(e.target.value)}
      placeholder="ex: joao_pescador"
    />
    {username !== usernameOriginal && (
      <button
        type="button"
        className="editar-username-reset"
        onClick={handleResetUsername}
        title="Voltar ao original"
      >
        <span className="material-symbols-outlined">undo</span>
      </button>
    )}
  </div>
  {/* status e dicas permanecem iguais */}
  {usernameStatus.verificando && (
    <p className="editar-dica" style={{ color: "#888" }}>
      Verificando...
    </p>
  )}
  {usernameStatus.mensagem && !usernameStatus.verificando && (
    <p
      className="editar-dica"
      style={{
        color: usernameStatus.mensagem.includes("✅") ? "#2e7d32" : "#d32f2f",
      }}
    >
      {usernameStatus.mensagem}
    </p>
  )}
  <p className="editar-dica">
    Seu username único será usado no link do perfil e em menções.
  </p>
</div>

          {/* LOCAL */}
          <div className="editar-secao">
            <label className="editar-label">Localização</label>
            <input
              className="editar-input"
              value={localizacao}
              onChange={(e) => setLocalizacao(e.target.value)}
            />
          </div>

          {/* BIO */}
          <div className="editar-secao">
            <label className="editar-label">Bio</label>
            <textarea
              className="editar-textarea"
              value={bio}
              onChange={(e) => setBio(e.target.value)}
              rows={4}
              maxLength={300}
            />
            <p className="editar-contador">{bio.length}/300</p>
          </div>

          {/* ERRO */}
          {erro && (
            <div className="editar-erro">
              <span className="material-symbols-outlined">error</span>
              {erro}
            </div>
          )}

          {/* BOTÃO SALVAR */}
          <button
            className={`btn-salvar ${salvando ? "btn-salvando" : ""} ${salvo ? "btn-salvo" : ""}`}
            onClick={handleSalvar}
            disabled={salvando}
          >
            {salvando ? (
              <>
                <span className="btn-spinner" />
                Salvando alterações...
              </>
            ) : salvo ? (
              <>
                <span className="material-symbols-outlined">check_circle</span>
                Salvo!
              </>
            ) : (
              "Salvar Alterações"
            )}
          </button>
        </div>
      </div>
    </Layout>
  );
}
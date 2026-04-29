import React, { useState, useRef, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import Layout from "../../../components/sidebar/layout";
import "./Editarperfil.css";

import { db } from "../../../firebase";
import { doc, setDoc, getDoc } from "firebase/firestore";
import { observeAuthState } from "../../../auth";

export default function EditarPerfil() {
  const navigate = useNavigate();

  const [user, setUser] = useState(null);

  const [nome, setNome] = useState("");
  const [bio, setBio] = useState("");
  const [localizacao, setLocalizacao] = useState("");
  const [fotoPerfil, setFotoPerfil] = useState("");
  const [banner, setBanner] = useState("");

  const [salvando, setSalvando] = useState(false);
  const [salvo, setSalvo] = useState(false);
  const [erro, setErro] = useState("");

  const fotoInputRef = useRef(null);
  const bannerInputRef = useRef(null);

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
        }
      } catch (e) {
        console.error("Erro ao carregar perfil:", e);
      }
    };

    carregarDados();
  }, [user]);

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

    if (!user) {
      setErro("Usuário não autenticado.");
      return;
    }

    setSalvando(true);

    try {
      await setDoc(
        doc(db, "usuarios", user.uid),
        {
          nome,
          bio,
          localizacao,
          fotoPerfil,
          banner,
        },
        { merge: true }
      );

      // 🔥 Atualiza cache correto
      localStorage.setItem(
        "usuarioCache",
        JSON.stringify({
          nome,
          bio,
          localizacao,
          fotoPerfil,
          banner,
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
            />
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

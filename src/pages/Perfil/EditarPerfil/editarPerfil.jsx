import React, { useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import Layout from "../../../components/sidebar/layout";
import "./Editarperfil.css";

import { db } from "../../../firebase";
import { doc, setDoc } from "firebase/firestore";
import { observeAuthState } from "../../../auth";

export default function EditarPerfil() {
  const navigate = useNavigate();

  const [user, setUser] = useState(null);

  const [nome, setNome] = useState(localStorage.getItem("nome") || "");
  const [bio, setBio] = useState(localStorage.getItem("bio") || "");
  const [localizacao, setLocalizacao] = useState(localStorage.getItem("localizacao") || "");
  const [fotoPerfil, setFotoPerfil] = useState(localStorage.getItem("fotoPerfil") || "");
  const [banner, setBanner] = useState(localStorage.getItem("banner") || "");

  const [salvando, setSalvando] = useState(false);
  const [salvo, setSalvo] = useState(false);
  const [erro, setErro] = useState("");

  const fotoInputRef = useRef(null);
  const bannerInputRef = useRef(null);

  // 🔐 pega usuário logado
  React.useEffect(() => {
    const unsubscribe = observeAuthState((currentUser) => setUser(currentUser));
    return unsubscribe;
  }, []);

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
      setErro("O nome não pode ficar vazio. Por favor, preencha seu nome.");
      return;
    }

    if (!user) {
      setErro("Usuário não autenticado.");
      return;
    }

    setSalvando(true);

    try {
      // 🔥 SALVA NO FIRESTORE
      await setDoc(doc(db, "usuarios", user.uid), {
        nome,
        bio,
        localizacao,
        fotoPerfil,
        banner,
      });

      // 💾 mantém localStorage (compatibilidade com resto do app)
      localStorage.setItem("nome", nome);
      localStorage.setItem("bio", bio);
      localStorage.setItem("localizacao", localizacao);
      if (fotoPerfil) localStorage.setItem("fotoPerfil", fotoPerfil);
      if (banner) localStorage.setItem("banner", banner);

      setSalvando(false);
      setSalvo(true);

      setTimeout(() => {
        navigate("/perfil");
      }, 1000);

    } catch (error) {
      console.error(error);
      setErro("Erro ao salvar no servidor. Tente novamente.");
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

          <div className="editar-secao">
            <label className="editar-label">Foto de Capa</label>
            <div
              className="editar-banner-preview"
              onClick={() => bannerInputRef.current.click()}
              style={{ backgroundImage: banner ? `url(${banner})` : undefined }}
            >
              {!banner && (
                <div className="editar-banner-vazio">
                  <span className="material-symbols-outlined">add_photo_alternate</span>
                  <p>Clique para adicionar uma capa</p>
                </div>
              )}
              <div className="editar-banner-overlay">
                <span className="material-symbols-outlined">photo_camera</span>
                <p>Trocar capa</p>
              </div>
            </div>
            <input type="file" accept="image/*" ref={bannerInputRef} style={{ display: "none" }} onChange={handleBannerChange} />
          </div>

          <div className="editar-secao editar-secao-foto">
            <label className="editar-label">Foto de Perfil</label>
            <div className="editar-foto-wrapper" onClick={() => fotoInputRef.current.click()}>
              {fotoPerfil ? (
                <img src={fotoPerfil} alt="Foto de perfil" className="editar-foto-preview" />
              ) : (
                <div className="editar-foto-vazio">
                  <span className="material-symbols-outlined">person</span>
                </div>
              )}
              <div className="editar-foto-overlay">
                <span className="material-symbols-outlined">photo_camera</span>
              </div>
            </div>
            <input type="file" accept="image/*" ref={fotoInputRef} style={{ display: "none" }} onChange={handleFotoChange} />
            <p className="editar-dica">Clique na foto para trocar</p>
          </div>

          <div className="editar-secao">
            <label className="editar-label" htmlFor="campo-nome">
              Nome completo <span className="editar-obrigatorio">*</span>
            </label>
            <input
              id="campo-nome"
              type="text"
              className={`editar-input ${erro ? "editar-input-erro" : ""}`}
              placeholder="Seu nome completo"
              value={nome}
              onChange={(e) => {
                setNome(e.target.value);
                if (erro) setErro("");
              }}
              maxLength={60}
            />
            <p className="editar-contador">{nome.length}/60</p>

            {erro && (
              <div className="editar-erro">
                <span className="material-symbols-outlined">error</span>
                {erro}
              </div>
            )}
          </div>

          <div className="editar-secao">
            <label className="editar-label" htmlFor="campo-localizacao">Localização</label>
            <div className="editar-input-icone">
              <span className="material-symbols-outlined editar-input-icone-symbol">location_on</span>
              <input
                id="campo-localizacao"
                type="text"
                className="editar-input editar-input-com-icone"
                placeholder="Ex: Matão, SP"
                value={localizacao}
                onChange={(e) => setLocalizacao(e.target.value)}
                maxLength={60}
              />
            </div>
          </div>

          <div className="editar-secao">
            <label className="editar-label" htmlFor="campo-bio">Bio</label>
            <textarea
              id="campo-bio"
              className="editar-textarea"
              placeholder="Conte um pouco sobre você e sua paixão pela pesca..."
              value={bio}
              onChange={(e) => setBio(e.target.value)}
              maxLength={150}
              rows={4}
            />
            <p className="editar-contador">{bio.length}/150</p>
          </div>

          <button
            className={`btn-salvar ${salvando ? "btn-salvando" : ""} ${salvo ? "btn-salvo" : ""}`}
            onClick={handleSalvar}
            disabled={salvando || salvo}
          >
            {salvo ? (
              <>
                <span className="material-symbols-outlined">check_circle</span>
                Salvo com sucesso!
              </>
            ) : salvando ? (
              <>
                <span className="material-symbols-outlined">hourglass_top</span>
                Salvando...
              </>
            ) : (
              <>
                <span className="material-symbols-outlined">save</span>
                Salvar Alterações
              </>
            )}
          </button>

        </div>
      </div>
    </Layout>
  );
}
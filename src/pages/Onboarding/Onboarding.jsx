// src/pages/Onboarding/Onboarding.jsx

import React, { useEffect, useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import "./Onboarding.css";

import { db, auth } from "../../firebase";
import { doc, getDoc, updateDoc } from "firebase/firestore";
import { observeAuthState } from "../../auth";
import { updateProfile } from "firebase/auth";

export default function Onboarding() {
  const navigate = useNavigate();
  const [user, setUser] = useState(null);
  const [nomeUsuario, setNomeUsuario] = useState("");
  const [etapa, setEtapa] = useState(1);
  const TOTAL_ETAPAS = 6;

  // Estados das etapas
  const [fotoPerfil, setFotoPerfil] = useState(null);
  const [fotoPreview, setFotoPreview] = useState(null);
  const [fotoCapa, setFotoCapa] = useState(null);
  const [fotoCapaPreview, setFotoCapaPreview] = useState(null);
  const [nome, setNome] = useState("");
  const [localizacao, setLocalizacao] = useState("");
  const [bio, setBio] = useState("");

  const fotoInputRef = useRef(null);
  const capaInputRef = useRef(null);

  useEffect(() => {
    const unsubscribe = observeAuthState(async (currentUser) => {
      if (!currentUser) {
        navigate("/login");
        return;
      }
      setUser(currentUser);

      try {
        const docSnap = await getDoc(doc(db, "usuarios", currentUser.uid));
        if (docSnap.exists()) {
          const data = docSnap.data();
          setNome(data.nome || "");
          setLocalizacao(data.localizacao || "");
          setBio(data.bio || "");
          setFotoCapaPreview(data.banner || null);
          setFotoPreview(data.fotoPerfil || null);
          const nomeCompleto = data.nome || currentUser.displayName || "Pescador";
          setNomeUsuario(nomeCompleto.split(" ")[0]);
        }
      } catch (e) {
        const fallback = currentUser.displayName?.split(" ")[0] || "Pescador";
        setNomeUsuario(fallback);
      }
    });
    return unsubscribe;
  }, [navigate]);

  const avancar = () => {
    if (etapa < TOTAL_ETAPAS) setEtapa((e) => e + 1);
  };

  const pular = () => {
    if (etapa < TOTAL_ETAPAS) setEtapa((e) => e + 1);
  };

  // Tela 2 — Foto de perfil
  const handleFotoChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    setFotoPerfil(file);
    const reader = new FileReader();
    reader.onload = () => setFotoPreview(reader.result);
    reader.readAsDataURL(file);
  };

  const handleSalvarFoto = async () => {
    if (!fotoPreview || !user) {
      avancar();
      return;
    }
    try {
      await updateDoc(doc(db, "usuarios", user.uid), {
        fotoPerfil: fotoPreview,
      });
    } catch (e) {
      console.error("Erro ao salvar foto:", e);
    }
    avancar();
  };

  // Tela 3 — Nome e localização
  const handleSalvarNomeLocalizacao = async () => {
    if (!user) return avancar();

    if (!nome.trim()) {
      alert("Por favor, informe seu nome.");
      return;
    }

    try {
      await updateDoc(doc(db, "usuarios", user.uid), {
        nome: nome.trim(),
        localizacao: localizacao.trim(),
      });

      if (auth.currentUser) {
        await updateProfile(auth.currentUser, { displayName: nome.trim() });
      }
    } catch (error) {
      console.error("Erro ao salvar dados:", error);
    }

    avancar();
  };

  // Tela 4 — Bio
  const handleSalvarBio = async () => {
    if (!user) return avancar();

    try {
      await updateDoc(doc(db, "usuarios", user.uid), {
        bio: bio.trim(),
      });
    } catch (error) {
      console.error("Erro ao salvar bio:", error);
    }

    avancar();
  };

  // Tela 5 — Foto de capa
  const handleCapaChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    setFotoCapa(file);
    const reader = new FileReader();
    reader.onload = () => setFotoCapaPreview(reader.result);
    reader.readAsDataURL(file);
  };

  const handleSalvarCapa = async () => {
    if (!fotoCapaPreview || !user) {
      avancar();
      return;
    }
    try {
      await updateDoc(doc(db, "usuarios", user.uid), {
        banner: fotoCapaPreview,
      });
    } catch (e) {
      console.error("Erro ao salvar capa:", e);
    }
    avancar();
  };

  return (
    <div className="onboarding-container">

      {/* BARRA DE PROGRESSO */}
      <div className="onboarding-progresso">
        {Array.from({ length: TOTAL_ETAPAS }).map((_, i) => (
          <div
            key={i}
            className={`onboarding-progresso-item ${i + 1 <= etapa ? "ativa" : ""}`}
          />
        ))}
      </div>

      {/* TELA 1 — BOAS VINDAS */}
      {etapa === 1 && (
        <div className="onboarding-tela onboarding-tela-animada">

          <div className="onboarding-icone-wrapper">
            <span className="onboarding-emoji">🎣</span>
          </div>

          <h1 className="onboarding-titulo">
            Bem-vindo ao Pesque & Fale,<br />
            <span className="onboarding-nome">{nomeUsuario}!</span>
          </h1>

          <p className="onboarding-descricao">
            Vamos montar o seu perfil para que outros pescadores possam te conhecer.
            Vai levar menos de 2 minutos!
          </p>

          <div className="onboarding-passos">
            <div className="onboarding-passo">
              <span className="material-symbols-outlined onboarding-passo-icone">photo_camera</span>
              <span>Foto de perfil</span>
            </div>
            <div className="onboarding-passo">
              <span className="material-symbols-outlined onboarding-passo-icone">person</span>
              <span>Nome e localização</span>
            </div>
            <div className="onboarding-passo">
              <span className="material-symbols-outlined onboarding-passo-icone">edit_note</span>
              <span>Bio</span>
            </div>
            <div className="onboarding-passo">
              <span className="material-symbols-outlined onboarding-passo-icone">image</span>
              <span>Foto de capa</span>
            </div>
          </div>

          <button className="onboarding-btn-primary" onClick={avancar}>
            Vamos começar!
            <span className="material-symbols-outlined">arrow_forward</span>
          </button>

          <button className="onboarding-btn-pular" onClick={() => navigate("/home")}>
            Pular por agora
          </button>

        </div>
      )}

      {/* TELA 2 — FOTO DE PERFIL */}
      {etapa === 2 && (
        <div className="onboarding-tela onboarding-tela-animada">

          <h1 className="onboarding-titulo">Adicione sua foto de perfil</h1>
          <p className="onboarding-descricao">
            Uma boa foto ajuda outros pescadores a te reconhecerem na comunidade.
          </p>

          <div
            className="onboarding-foto-wrapper"
            onClick={() => fotoInputRef.current.click()}
            title="Clique para escolher uma foto"
          >
            {fotoPreview ? (
              <>
                <img src={fotoPreview} alt="Foto de perfil" className="onboarding-foto-preview" />
                <div className="onboarding-foto-overlay">
                  <span className="material-symbols-outlined">photo_camera</span>
                  <span>Trocar foto</span>
                </div>
              </>
            ) : (
              <div className="onboarding-foto-vazio">
                <span className="material-symbols-outlined onboarding-foto-icone">add_a_photo</span>
                <span className="onboarding-foto-texto">Clique para adicionar</span>
              </div>
            )}
          </div>

          <input
            type="file"
            accept="image/*"
            ref={fotoInputRef}
            style={{ display: "none" }}
            onChange={handleFotoChange}
          />

          <button
            className="onboarding-btn-primary"
            onClick={handleSalvarFoto}
          >
            {fotoPreview ? "Salvar e continuar" : "Continuar sem foto"}
            <span className="material-symbols-outlined">arrow_forward</span>
          </button>

          <button className="onboarding-btn-pular" onClick={pular}>
            Pular esta etapa
          </button>

        </div>
      )}

      {/* TELA 3 — NOME E LOCALIZAÇÃO */}
      {etapa === 3 && (
        <div className="onboarding-tela onboarding-tela-animada">

          <h1 className="onboarding-titulo">Qual é o seu nome e onde você pesca?</h1>
          <p className="onboarding-descricao">
            Essas informações ajudam a personalizar sua experiência e a conectar você com pescadores da sua região.
          </p>

          <div className="onboarding-input-wrapper">
            <span className="material-symbols-outlined onboarding-input-icone">person</span>
            <input
              type="text"
              className="onboarding-input"
              placeholder="Nome completo"
              value={nome}
              onChange={(e) => setNome(e.target.value)}
            />
          </div>

          <div className="onboarding-input-wrapper">
            <span className="material-symbols-outlined onboarding-input-icone">location_on</span>
            <input
              type="text"
              className="onboarding-input"
              placeholder="Cidade, estado ou região"
              value={localizacao}
              onChange={(e) => setLocalizacao(e.target.value)}
            />
          </div>

          <button className="onboarding-btn-primary" onClick={handleSalvarNomeLocalizacao}>
            Continuar
            <span className="material-symbols-outlined">arrow_forward</span>
          </button>

          <button className="onboarding-btn-pular" onClick={pular}>
            Pular esta etapa
          </button>

        </div>
      )}

      {/* TELA 4 — BIO */}
      {etapa === 4 && (
        <div className="onboarding-tela onboarding-tela-animada">

          <h1 className="onboarding-titulo">Conte um pouco sobre você</h1>
          <p className="onboarding-descricao">
            Uma boa bio ajuda outros pescadores a te conhecerem e a se conectarem com você.
          </p>

          <div className="onboarding-input-wrapper onboarding-input-wrapper-bio">
            <span className="material-symbols-outlined onboarding-input-icone onboarding-input-icone-bio">edit_note</span>
            <textarea
              className="onboarding-textarea"
              placeholder="Sou pescador há 10 anos, adoro pescar em rios de água doce..."
              value={bio}
              onChange={(e) => setBio(e.target.value)}
              rows={4}
              maxLength={300}
            />
            <span className="onboarding-contador">{bio.length}/300</span>
          </div>

          <button className="onboarding-btn-primary" onClick={handleSalvarBio}>
            Continuar
            <span className="material-symbols-outlined">arrow_forward</span>
          </button>

          <button className="onboarding-btn-pular" onClick={pular}>
            Pular esta etapa
          </button>

        </div>
      )}

      {/* TELA 5 — FOTO DE CAPA */}
      {etapa === 5 && (
        <div className="onboarding-tela onboarding-tela-animada">

          <h1 className="onboarding-titulo">Adicione uma foto de capa</h1>
          <p className="onboarding-descricao">
            Dê um toque pessoal ao seu perfil com uma imagem de fundo.
          </p>

          <div
            className="onboarding-capa-wrapper"
            onClick={() => capaInputRef.current.click()}
            title="Clique para escolher uma capa"
          >
            {fotoCapaPreview ? (
              <>
                <img src={fotoCapaPreview} alt="Foto de capa" className="onboarding-capa-preview" />
                <div className="onboarding-capa-overlay">
                  <span className="material-symbols-outlined">image</span>
                  <span>Trocar capa</span>
                </div>
              </>
            ) : (
              <div className="onboarding-capa-vazio">
                <span className="material-symbols-outlined onboarding-capa-icone">add_photo_alternate</span>
                <span className="onboarding-capa-texto">Clique para adicionar uma capa</span>
              </div>
            )}
          </div>

          <input
            type="file"
            accept="image/*"
            ref={capaInputRef}
            style={{ display: "none" }}
            onChange={handleCapaChange}
          />

          <button
            className="onboarding-btn-primary"
            onClick={handleSalvarCapa}
          >
            {fotoCapaPreview ? "Salvar e continuar" : "Continuar sem capa"}
            <span className="material-symbols-outlined">arrow_forward</span>
          </button>

          <button className="onboarding-btn-pular" onClick={pular}>
            Pular esta etapa
          </button>

        </div>
      )}

    </div>
  );
}
import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import "./Onboarding.css";

import { db } from "../../firebase";
import { doc, getDoc } from "firebase/firestore";
import { observeAuthState } from "../../auth";

export default function Onboarding() {
  const navigate = useNavigate();
  const [user, setUser] = useState(null);
  const [nomeUsuario, setNomeUsuario] = useState("");
  const [etapa, setEtapa] = useState(1);
  const TOTAL_ETAPAS = 6;

  useEffect(() => {
    const unsubscribe = observeAuthState(async (currentUser) => {
      if (!currentUser) {
        navigate("/login");
        return;
      }
      setUser(currentUser);

      // Busca o nome salvo no Firestore
      try {
        const docSnap = await getDoc(doc(db, "usuarios", currentUser.uid));
        if (docSnap.exists()) {
          const nome = docSnap.data().nome || currentUser.displayName || "Pescador";
          setNomeUsuario(nome.split(" ")[0]); // pega só o primeiro nome
        }
      } catch (e) {
        setNomeUsuario(currentUser.displayName?.split(" ")[0] || "Pescador");
      }
    });
    return unsubscribe;
  }, []);

  const avancar = () => {
    if (etapa < TOTAL_ETAPAS) setEtapa((e) => e + 1);
  };

  const pular = () => {
    if (etapa < TOTAL_ETAPAS) setEtapa((e) => e + 1);
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

    </div>
  );
}
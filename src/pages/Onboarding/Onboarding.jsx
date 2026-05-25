import React, { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { updateProfile } from "firebase/auth";
import { doc, getDoc, updateDoc } from "firebase/firestore";

import { db, auth } from "../../firebase";
import { observeAuthState } from "../../auth";
import {
  validarUsername,
  verificarDisponibilidade,
  gerarSugestao,
} from "../../utils/usernameUtils";

import "./Onboarding.css";

const TOTAL_ETAPAS = 7; // ← agora são 7 etapas

export default function Onboarding() {
  const navigate = useNavigate();
  const [usernameErro, setUsernameErro] = useState("");

  /* ─── Estados ─── */
  const [user, setUser] = useState(null);
  const [nomeUsuario, setNomeUsuario] = useState("");
  const [etapa, setEtapa] = useState(1);

  const [fotoPerfil, setFotoPerfil] = useState(null);
  const [fotoPreview, setFotoPreview] = useState(null);
  const [fotoCapa, setFotoCapa] = useState(null);
  const [fotoCapaPreview, setFotoCapaPreview] = useState(null);

  const [nome, setNome] = useState("");
  const [localizacao, setLocalizacao] = useState("");
  const [bio, setBio] = useState("");

  // ========== NOVO: estados do username ==========
  const [username, setUsername] = useState("");
  const [usernameDisponivel, setUsernameDisponivel] = useState(false);
  const [usernameVerificando, setUsernameVerificando] = useState(false);
  const [usernameMensagem, setUsernameMensagem] = useState("");

  const [darkMode, setDarkMode] = useState(() => {
    return localStorage.getItem("theme") === "dark";
  });

  const fotoInputRef = useRef(null);
  const capaInputRef = useRef(null);

  /* ─── Efeitos ─── */
  useEffect(() => {
    if (darkMode) {
      document.body.classList.add("dark-mode");
      localStorage.setItem("theme", "dark");
    } else {
      document.body.classList.remove("dark-mode");
      localStorage.setItem("theme", "light");
    }
  }, [darkMode]);

  // Observa autenticação e carrega dados do usuário
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
          // Se já existir username (caso raro de reedição) preenche
          if (data.username) setUsername(data.username);

          const nomeCompleto =
            data.nome || currentUser.displayName || "Pescador";
          setNomeUsuario(nomeCompleto.split(" ")[0]);
        }
      } catch (e) {
        const fallback = currentUser.displayName?.split(" ")[0] || "Pescador";
        setNomeUsuario(fallback);
      }
    });

    return unsubscribe;
  }, [navigate]);

  // ========== DEBOUNCE para verificar username ==========
  useEffect(() => {
    const timer = setTimeout(async () => {
      if (!username || username.trim() === "") {
        setUsernameDisponivel(false);
        setUsernameMensagem("");
        return;
      }

      if (!validarUsername(username)) {
        setUsernameDisponivel(false);
        setUsernameMensagem("3-20 caracteres. Use letras, números, _ ou .");
        return;
      }

      setUsernameVerificando(true);
      const disponivel = await verificarDisponibilidade(username);
      setUsernameVerificando(false);
      setUsernameDisponivel(disponivel);
      setUsernameMensagem(disponivel ? "✅ Disponível" : "❌ Indisponível");
    }, 500);

    return () => clearTimeout(timer);
  }, [username]);

  /* ─── Handlers ─── */
  const toggleDarkMode = () => setDarkMode((prev) => !prev);

  const avancar = () => {
    if (etapa < TOTAL_ETAPAS) setEtapa((e) => e + 1);
  };

  const pular = () => {
    if (etapa < TOTAL_ETAPAS) setEtapa((e) => e + 1);
  };

  // Etapa 2: Foto de perfil
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

  // Etapa 3: Nome e localização
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

  // Etapa 4: Username (NOVA)
  const handleSalvarUsername = async () => {
    if (!user) return;

    if (!username.trim()) {
      setUsernameErro("O username é obrigatório para continuar.");
      return;
    }

    if (!usernameDisponivel) {
      setUsernameErro("Username inválido ou indisponível. Escolha outro.");
      return;
    }

    try {
      await updateDoc(doc(db, "usuarios", user.uid), {
        username: username.trim(),
      });
      setUsernameErro("");
    } catch (error) {
      console.error("Erro ao salvar username:", error);
      setUsernameErro("Erro ao salvar username. Tente novamente.");
      return;
    }

    avancar();
  };

  // Etapa 5: Bio (antiga etapa 4)
  const handleSalvarBio = async () => {
    if (!user) return avancar();

    try {
      await updateDoc(doc(db, "usuarios", user.uid), { bio: bio.trim() });
    } catch (error) {
      console.error("Erro ao salvar bio:", error);
    }

    avancar();
  };

  // Etapa 6: Foto de capa (antiga etapa 5)
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

  // Etapa 7: Conclusão
  const handleConcluir = async () => {
    if (!user) return;

    try {
      await updateDoc(doc(db, "usuarios", user.uid), {
        onboardingConcluido: true,
      });
    } catch (e) {
      console.error("Erro ao finalizar onboarding:", e);
    }

    // Ativa o tour via localStorage — é o que o layout.jsx lê para exibir o OnboardingTour
    localStorage.setItem('tourAtivo', 'true');
    localStorage.removeItem('tourConcluido');
    localStorage.removeItem('tourCurrentStep'); // garante início sempre do step 0

    navigate("/home", { replace: true });
  };

  /* ─── Render ─── */
  return (
    <div className="onboarding-container">
      {/* Barra de progresso */}
      <div className="onboarding-progresso">
        {Array.from({ length: TOTAL_ETAPAS }).map((_, i) => {
          const numero = i + 1;
          const ativa = numero <= etapa;
          return (
            <React.Fragment key={i}>
              <div
                className={`onboarding-progresso-circulo ${ativa ? "ativa" : ""}`}
              >
                <span className="onboarding-progresso-numero">{numero}</span>
              </div>
              {i < TOTAL_ETAPAS - 1 && (
                <div
                  className={`onboarding-progresso-linha ${numero < etapa ? "preenchida" : ""}`}
                />
              )}
            </React.Fragment>
          );
        })}
      </div>

      {/* ── Etapa 1: Boas-vindas ── */}
      {etapa === 1 && (
        <div className="onboarding-tela onboarding-tela-animada">
          <h1 className="onboarding-titulo">
            Bem-vindo ao Pesque &amp; Fale,
            <br />
            <span className="onboarding-nome">{nomeUsuario}!</span>
          </h1>

          <p className="onboarding-descricao">
            Vamos montar o seu perfil para que outros pescadores possam te
            conhecer. Vai levar menos de 2 minutos!
          </p>

          <div className="onboarding-passos">
            <div className="onboarding-passo">
              <span className="material-symbols-outlined onboarding-passo-icone">
                photo_camera
              </span>
              <span>Foto de perfil</span>
            </div>
            <div className="onboarding-passo">
              <span className="material-symbols-outlined onboarding-passo-icone">
                person
              </span>
              <span>Nome e localização</span>
            </div>
            <div className="onboarding-passo">
              <span className="material-symbols-outlined onboarding-passo-icone">
                alternate_email
              </span>
              <span>Username único</span>
            </div>
            <div className="onboarding-passo">
              <span className="material-symbols-outlined onboarding-passo-icone">
                edit_note
              </span>
              <span>Bio</span>
            </div>
            <div className="onboarding-passo">
              <span className="material-symbols-outlined onboarding-passo-icone">
                image
              </span>
              <span>Foto de capa</span>
            </div>
          </div>

          <button className="onboarding-btn-primary" onClick={avancar}>
            Vamos começar!
            <span className="material-symbols-outlined">arrow_forward</span>
          </button>

          <button className="onboarding-btn-pular" onClick={avancar}>
            Pular esta etapa
          </button>
        </div>
      )}

      {/* ── Etapa 2: Foto de perfil ── */}
      {etapa === 2 && (
        <div className="onboarding-tela onboarding-tela-animada">
          <h1 className="onboarding-titulo">Adicione sua foto de perfil</h1>
          <p className="onboarding-descricao">
            Uma boa foto ajuda outros pescadores a te reconhecerem na
            comunidade.
          </p>

          <div
            className="onboarding-foto-wrapper"
            onClick={() => fotoInputRef.current.click()}
            title="Clique para escolher uma foto"
          >
            {fotoPreview ? (
              <>
                <img
                  src={fotoPreview}
                  alt="Foto de perfil"
                  className="onboarding-foto-preview"
                />
                <div className="onboarding-foto-overlay">
                  <span className="material-symbols-outlined">
                    photo_camera
                  </span>
                  <span>Trocar foto</span>
                </div>
              </>
            ) : (
              <div className="onboarding-foto-vazio">
                <span className="material-symbols-outlined onboarding-foto-icone">
                  add_a_photo
                </span>
                <span className="onboarding-foto-texto">
                  Clique para adicionar
                </span>
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

          <button className="onboarding-btn-primary" onClick={handleSalvarFoto}>
            {fotoPreview ? "Salvar e continuar" : "Continuar sem foto"}
            <span className="material-symbols-outlined">arrow_forward</span>
          </button>

          <button className="onboarding-btn-pular" onClick={pular}>
            Pular esta etapa
          </button>
        </div>
      )}

      {/* ── Etapa 3: Nome e localização ── */}
      {etapa === 3 && (
        <div className="onboarding-tela onboarding-tela-animada">
          <h1 className="onboarding-titulo">
            Qual é o seu nome e onde você pesca?
          </h1>
          <p className="onboarding-descricao">
            Essas informações ajudam a personalizar sua experiência e a conectar
            você com pescadores da sua região.
          </p>

          <div className="onboarding-input-wrapper">
            <span className="material-symbols-outlined onboarding-input-icone">
              person
            </span>
            <input
              type="text"
              className="onboarding-input"
              placeholder="Nome completo"
              value={nome}
              onChange={(e) => setNome(e.target.value)}
            />
          </div>

          <div className="onboarding-input-wrapper">
            <span className="material-symbols-outlined onboarding-input-icone">
              location_on
            </span>
            <input
              type="text"
              className="onboarding-input"
              placeholder="Cidade, estado ou região"
              value={localizacao}
              onChange={(e) => setLocalizacao(e.target.value)}
            />
          </div>

          <button
            className="onboarding-btn-primary"
            onClick={handleSalvarNomeLocalizacao}
          >
            Continuar
            <span className="material-symbols-outlined">arrow_forward</span>
          </button>

          <button className="onboarding-btn-pular" onClick={pular}>
            Pular esta etapa
          </button>
        </div>
      )}

      {/* ── Etapa 4: Username (NOVA) ── */}
      {etapa === 4 && (
        <div className="onboarding-tela onboarding-tela-animada">
          <h1 className="onboarding-titulo">Escolha seu username único</h1>
          <p className="onboarding-descricao">
            Será usado no link do seu perfil e para te marcarem em posts e
            comentários.
            <br />
            <small>Ex: joao_pescador, maria.2024</small>
          </p>

          <div className="onboarding-input-wrapper">
            <span className="material-symbols-outlined onboarding-input-icone">
              alternate_email
            </span>
            <input
              type="text"
              className="onboarding-input"
              placeholder="seu_username"
              value={username}
              onChange={(e) => {
                setUsername(e.target.value);
                setUsernameErro("");
              }}
            />
          </div>

          {usernameVerificando && (
            <p className="onboarding-dica" style={{ color: "#888" }}>
              Verificando disponibilidade...
            </p>
          )}
          {usernameMensagem && !usernameVerificando && (
            <p
              className={`onboarding-dica`}
              style={{
                color: usernameMensagem.includes("✅") ? "#2e7d32" : "#d32f2f",
                fontWeight: 500,
              }}
            >
              {usernameMensagem}
            </p>
          )}

          {usernameErro && (
            <p
              className="onboarding-dica"
              style={{ color: "#d32f2f", fontWeight: 500 }}
            >
              {usernameErro}
            </p>
          )}

          <button
            className="onboarding-btn-primary"
            onClick={handleSalvarUsername}
            disabled={username && !usernameDisponivel}
          >
            Continuar
            <span className="material-symbols-outlined">arrow_forward</span>
          </button>
        </div>
      )}

      {/* ── Etapa 5: Bio (antiga etapa 4) ── */}
      {etapa === 5 && (
        <div className="onboarding-tela onboarding-tela-animada">
          <h1 className="onboarding-titulo">Conte um pouco sobre você</h1>
          <p className="onboarding-descricao">
            Uma boa bio ajuda outros pescadores a te conhecerem e a se
            conectarem com você.
          </p>

          <div className="onboarding-input-wrapper onboarding-input-wrapper-bio">
            <span className="material-symbols-outlined onboarding-input-icone onboarding-input-icone-bio">
              edit_note
            </span>
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

      {/* ── Etapa 6: Foto de capa (antiga etapa 5) ── */}
      {etapa === 6 && (
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
                <img
                  src={fotoCapaPreview}
                  alt="Foto de capa"
                  className="onboarding-capa-preview"
                />
                <div className="onboarding-capa-overlay">
                  <span className="material-symbols-outlined">image</span>
                  <span>Trocar capa</span>
                </div>
              </>
            ) : (
              <div className="onboarding-capa-vazio">
                <span className="material-symbols-outlined onboarding-capa-icone">
                  add_photo_alternate
                </span>
                <span className="onboarding-capa-texto">
                  Clique para adicionar uma capa
                </span>
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

          <button className="onboarding-btn-primary" onClick={handleSalvarCapa}>
            {fotoCapaPreview ? "Salvar e continuar" : "Continuar sem capa"}
            <span className="material-symbols-outlined">arrow_forward</span>
          </button>

          <button className="onboarding-btn-pular" onClick={pular}>
            Pular esta etapa
          </button>
        </div>
      )}

      {/* ── Etapa 7: Conclusão ── */}
      {etapa === 7 && (
        <div className="onboarding-tela onboarding-tela-animada">
          <div className="onboarding-icone-wrapper">
            <span className="onboarding-emoji">🎉</span>
          </div>

          <h1 className="onboarding-titulo">Perfil completo, bora pescar!</h1>
          <p className="onboarding-descricao">
            Seu perfil foi configurado com sucesso. Agora você pode explorar
            locais de pesca, conectar-se com outros pescadores e compartilhar
            suas aventuras.
          </p>

          <button className="onboarding-btn-primary" onClick={handleConcluir}>
            Ir para Home
            <span className="material-symbols-outlined">home</span>
          </button>
        </div>
      )}

      {/* ── FAB de tema ── */}
      <button
        className="onboarding-fab-theme"
        onClick={toggleDarkMode}
        title={darkMode ? "Modo claro" : "Modo escuro"}
      >
        <span className="material-symbols-outlined">
          {darkMode ? "light_mode" : "dark_mode"}
        </span>
      </button>
    </div>
  );
}
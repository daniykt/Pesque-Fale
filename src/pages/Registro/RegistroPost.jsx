import React, { useState, useRef, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import Layout from "../../components/sidebar/layout";
import "./Registro.css";

import { db } from "../../firebase";
import { doc, updateDoc, arrayUnion, getDoc } from "firebase/firestore";
import { observeAuthState } from "../../auth";

const TAGS_FIXAS = [
  "Rio", "Lago", "Represa", "Mar", "Pesca Esportiva",
  "Pesca Noturna", "Pesca de Fundo", "Iniciante", "Família"
];

export default function RegistroPost() {
  const navigate = useNavigate();

  const [user, setUser]                       = useState(null);
  const [usuarioDados, setUsuarioDados]       = useState(null);
  const [foto, setFoto]                       = useState(null);
  const [fotoPreview, setFotoPreview]         = useState(null);
  const [descricao, setDescricao]             = useState("");
  const [local, setLocal]                     = useState("");
  const [avaliacao, setAvaliacao]             = useState(0);
  const [avaliacaoHover, setAvaliacaoHover]   = useState(0);
  const [tagsSelecionadas, setTagsSelecionadas] = useState([]);
  const [tagCustom, setTagCustom]             = useState("");
  const [publicando, setPublicando]           = useState(false);
  const [publicado, setPublicado]             = useState(false);
  const [erros, setErros]                     = useState({});

  const fotoInputRef = useRef(null);

  // Autentica e carrega dados do usuário (nome + foto de perfil)
  useEffect(() => {
    const unsubscribe = observeAuthState(async (u) => {
      setUser(u);
      if (u) {
        const snap = await getDoc(doc(db, "usuarios", u.uid));
        if (snap.exists()) setUsuarioDados(snap.data());
      }
    });
    return unsubscribe;
  }, []);

  /* ── handlers de foto ── */
  const handleFotoChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    setFoto(file);
    const reader = new FileReader();
    reader.onload = () => setFotoPreview(reader.result);
    reader.readAsDataURL(file);
  };

  /* ── handlers de tags ── */
  const handleToggleTag = (tag) =>
    setTagsSelecionadas((prev) =>
      prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]
    );

  const handleAdicionarTagCustom = () => {
    const tag = tagCustom.trim();
    if (!tag || tagsSelecionadas.includes(tag)) return;
    setTagsSelecionadas((prev) => [...prev, tag]);
    setTagCustom("");
  };

  const handleRemoverTag = (tag) =>
    setTagsSelecionadas((prev) => prev.filter((t) => t !== tag));

  /* ── validação ── */
  const validar = () => {
    const novosErros = {};
    if (!fotoPreview)    novosErros.foto  = "Adicione uma foto para publicar.";
    if (!local.trim())   novosErros.local = "Informe o nome do local.";
    setErros(novosErros);
    return Object.keys(novosErros).length === 0;
  };

  /* ── publicar ── */
  const handlePublicar = async () => {
    if (!validar() || !user) return;
    setPublicando(true);

    try {
      const novoPost = {
        id: Date.now(),
        // identificação do autor — essencial para a home montar o feed
        autorId:        user.uid,
        autorNome:      usuarioDados?.nome || usuarioDados?.displayName || user.displayName || "Pescador",
        autorFoto:      usuarioDados?.fotoPerfil || user.photoURL || "",
        // conteúdo
        imagem:         fotoPreview,
        data:           new Date().toLocaleString("pt-BR"),
        comentario:     descricao.trim() || "Sem descrição",
        local:          local.trim(),
        avaliacao:      avaliacao > 0 ? "⭐".repeat(avaliacao) : null,
        avaliacaoNumero: avaliacao > 0 ? avaliacao : null,
        tags:           tagsSelecionadas,
        curtidas:       [],
        comentarios:    [],
      };

      // Salva no documento do usuário → aparece no perfil e no feed de seguidores
      await updateDoc(doc(db, "usuarios", user.uid), {
        posts: arrayUnion(novoPost),
      });

      setPublicando(false);
      setPublicado(true);
      setTimeout(() => navigate("/perfil"), 1200);
    } catch (error) {
      console.error("Erro ao publicar:", error);
      setPublicando(false);
      setErros({ geral: "Erro ao publicar. Tente novamente." });
    }
  };

  return (
    <Layout>
      <div className="rp-container">

        {/* CABEÇALHO */}
        <div className="rp-header">
          <button className="rp-voltar" onClick={() => navigate(-1)}>
            <span className="material-symbols-outlined">arrow_back</span>
            Voltar
          </button>
          <h1 className="rp-titulo">Nova Publicação</h1>
        </div>

        <div className="rp-card">

          {/* ── FOTO ── */}
          <div className="rp-secao">
            <label className="rp-label">
              Foto <span className="rp-obrigatorio">*</span>
            </label>

            {fotoPreview ? (
              <div className="rp-foto-preview-wrapper">
                <img src={fotoPreview} alt="Preview" className="rp-foto-preview" />
                <button className="rp-foto-trocar" onClick={() => fotoInputRef.current.click()}>
                  <span className="material-symbols-outlined">photo_camera</span>
                  Trocar foto
                </button>
              </div>
            ) : (
              <div
                className={`rp-foto-upload ${erros.foto ? "rp-campo-erro" : ""}`}
                onClick={() => fotoInputRef.current.click()}
              >
                <span className="material-symbols-outlined rp-upload-icone">add_photo_alternate</span>
                <p className="rp-upload-texto">Clique para adicionar uma foto</p>
                <span className="rp-upload-dica">JPG, PNG até 10 MB</span>
              </div>
            )}

            {erros.foto && (
              <p className="rp-erro-msg">
                <span className="material-symbols-outlined">error</span>{erros.foto}
              </p>
            )}

            <input type="file" accept="image/*" ref={fotoInputRef}
              style={{ display: "none" }} onChange={handleFotoChange} />
          </div>

          {/* ── LOCAL ── */}
          <div className="rp-secao">
            <label className="rp-label" htmlFor="rp-local">
              Local <span className="rp-obrigatorio">*</span>
            </label>
            <div className="rp-input-icone">
              <span className="material-symbols-outlined rp-input-symbol">location_on</span>
              <input
                id="rp-local"
                type="text"
                className={`rp-input rp-input-com-icone ${erros.local ? "rp-campo-erro" : ""}`}
                placeholder="Ex: Represa de Ibitinga, SP"
                value={local}
                onChange={(e) => { setLocal(e.target.value); if (erros.local) setErros((p) => ({ ...p, local: "" })); }}
                maxLength={80}
              />
            </div>
            {erros.local && (
              <p className="rp-erro-msg">
                <span className="material-symbols-outlined">error</span>{erros.local}
              </p>
            )}
          </div>

          {/* ── DESCRIÇÃO ── */}
          <div className="rp-secao">
            <label className="rp-label" htmlFor="rp-descricao">Descrição</label>
            <textarea
              id="rp-descricao"
              className="rp-textarea"
              placeholder="Conte como foi a pescaria, dicas do local..."
              value={descricao}
              onChange={(e) => setDescricao(e.target.value)}
              maxLength={300}
              rows={4}
            />
            <p className="rp-contador">{descricao.length}/300</p>
          </div>

          {/* ── AVALIAÇÃO ── */}
          <div className="rp-secao">
            <label className="rp-label">
              Avaliação do local
              <span className="rp-opcional"> (opcional)</span>
            </label>
            <p className="rp-avaliacao-dica">Avalie o local para ajudar outros pescadores.</p>
            <div className="rp-estrelas">
              {[1, 2, 3, 4, 5].map((estrela) => (
                <button
                  key={estrela}
                  type="button"
                  className={`rp-estrela ${estrela <= (avaliacaoHover || avaliacao) ? "ativa" : ""}`}
                  onClick={() => setAvaliacao(avaliacao === estrela ? 0 : estrela)}
                  onMouseEnter={() => setAvaliacaoHover(estrela)}
                  onMouseLeave={() => setAvaliacaoHover(0)}
                  title={["", "Ruim", "Regular", "Bom", "Muito Bom", "Excelente"][estrela]}
                >
                  ⭐
                </button>
              ))}
              {avaliacao > 0 && (
                <>
                  <span className="rp-avaliacao-texto">
                    {["", "Ruim", "Regular", "Bom", "Muito Bom", "Excelente"][avaliacao]}
                  </span>
                  <button className="rp-limpar-avaliacao" onClick={() => setAvaliacao(0)} type="button">
                    <span className="material-symbols-outlined">close</span>
                  </button>
                </>
              )}
            </div>
          </div>

          {/* ── TAGS ── */}
          <div className="rp-secao">
            <label className="rp-label">Tags</label>
            <div className="rp-tags-fixas">
              {TAGS_FIXAS.map((tag) => (
                <button
                  key={tag} type="button"
                  className={`rp-tag ${tagsSelecionadas.includes(tag) ? "rp-tag-ativa" : ""}`}
                  onClick={() => handleToggleTag(tag)}
                >
                  {tagsSelecionadas.includes(tag) && (
                    <span className="material-symbols-outlined" style={{ fontSize: 14 }}>check</span>
                  )}
                  {tag}
                </button>
              ))}
            </div>

            <div className="rp-tag-custom">
              <input
                type="text" className="rp-input"
                placeholder="Adicionar tag personalizada..."
                value={tagCustom}
                onChange={(e) => setTagCustom(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleAdicionarTagCustom()}
                maxLength={30}
              />
              <button className="rp-tag-custom-btn" onClick={handleAdicionarTagCustom} type="button">
                <span className="material-symbols-outlined">add</span>
              </button>
            </div>

            {tagsSelecionadas.length > 0 && (
              <div className="rp-tags-selecionadas">
                <p className="rp-tags-titulo">Selecionadas:</p>
                <div className="rp-tags-lista">
                  {tagsSelecionadas.map((tag) => (
                    <span key={tag} className="rp-tag-selecionada">
                      {tag}
                      <button onClick={() => handleRemoverTag(tag)} type="button">
                        <span className="material-symbols-outlined">close</span>
                      </button>
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* ── ERRO GERAL ── */}
          {erros.geral && (
            <p className="rp-erro-msg">
              <span className="material-symbols-outlined">error</span>{erros.geral}
            </p>
          )}

          {/* ── BOTÃO PUBLICAR ── */}
          <button
            className={`rp-btn-publicar ${publicando ? "publicando" : ""} ${publicado ? "publicado" : ""}`}
            onClick={handlePublicar}
            disabled={publicando || publicado}
          >
            {publicado ? (
              <><span className="material-symbols-outlined">check_circle</span>Publicado com sucesso!</>
            ) : publicando ? (
              <><span className="material-symbols-outlined">hourglass_top</span>Publicando...</>
            ) : (
              <><span className="material-symbols-outlined">publish</span>Publicar</>
            )}
          </button>

        </div>
      </div>
    </Layout>
  );
}

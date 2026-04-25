import React, { useState, useRef, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import Layout from "../../components/sidebar/layout";
import "./novapublicacao.css";

import { db } from "../../firebase";
import { doc, updateDoc, arrayUnion } from "firebase/firestore";
import { observeAuthState } from "../../auth";

const TAGS_FIXAS = [
  "Rio", "Lago", "Represa", "Mar", "Pesca Esportiva",
  "Pesca Noturna", "Pesca de Fundo", "Iniciante", "Família"
];

export default function NovaPublicacao() {
  const navigate = useNavigate();

  const [user, setUser] = useState(null);
  const [foto, setFoto] = useState(null);
  const [fotoPreview, setFotoPreview] = useState(null);
  const [descricao, setDescricao] = useState("");
  const [local, setLocal] = useState("");
  const [avaliacao, setAvaliacao] = useState(0);
  const [avaliacaoHover, setAvaliacaoHover] = useState(0);
  const [tagsSelecionadas, setTagsSelecionadas] = useState([]);
  const [tagCustom, setTagCustom] = useState("");
  const [publicando, setPublicando] = useState(false);
  const [publicado, setPublicado] = useState(false);
  const [erros, setErros] = useState({});

  const fotoInputRef = useRef(null);

  // Pega o usuário autenticado
  useEffect(() => {
    const unsubscribe = observeAuthState(setUser);
    return unsubscribe;
  }, []);

  const handleFotoChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    setFoto(file);
    const reader = new FileReader();
    reader.onload = () => setFotoPreview(reader.result);
    reader.readAsDataURL(file);
  };

  const handleToggleTag = (tag) => {
    setTagsSelecionadas((prev) =>
      prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]
    );
  };

  const handleAdicionarTagCustom = () => {
    const tag = tagCustom.trim();
    if (!tag || tagsSelecionadas.includes(tag)) return;
    setTagsSelecionadas((prev) => [...prev, tag]);
    setTagCustom("");
  };

  const handleRemoverTag = (tag) => {
    setTagsSelecionadas((prev) => prev.filter((t) => t !== tag));
  };

  const validar = () => {
    const novosErros = {};
    if (!fotoPreview) novosErros.foto = "Adicione uma foto para publicar.";
    if (!local.trim()) novosErros.local = "Informe o nome do local.";
    setErros(novosErros);
    return Object.keys(novosErros).length === 0;
  };

  const handlePublicar = async () => {
    if (!validar()) return;
    if (!user) return;

    setPublicando(true);

    try {
      const novoPost = {
        id: Date.now(),
        imagem: fotoPreview,
        data: new Date().toLocaleString(),
        comentario: descricao || "Sem descrição",
        local: local,
        avaliacao: avaliacao > 0 ? "⭐".repeat(avaliacao) : null,
        avaliacaoNumero: avaliacao > 0 ? avaliacao : null,
        tags: tagsSelecionadas,
        curtidas: [],
        comentarios: [],
      };

      // Salva no Firestore — mesmo padrão do Perfil.jsx
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
      <div className="nova-pub-container">

        {/* CABEÇALHO */}
        <div className="nova-pub-header">
          <button className="nova-pub-voltar" onClick={() => navigate("/perfil")}>
            <span className="material-symbols-outlined">arrow_back</span>
            Voltar
          </button>
          <h1 className="nova-pub-titulo">Nova Publicação</h1>
        </div>

        <div className="nova-pub-card">

          {/* SEÇÃO — FOTO */}
          <div className="nova-pub-secao">
            <label className="nova-pub-label">
              Foto <span className="nova-pub-obrigatorio">*</span>
            </label>

            {fotoPreview ? (
              <div className="nova-pub-foto-preview-wrapper">
                <img src={fotoPreview} alt="Preview" className="nova-pub-foto-preview" />
                <button
                  className="nova-pub-foto-trocar"
                  onClick={() => fotoInputRef.current.click()}
                >
                  <span className="material-symbols-outlined">photo_camera</span>
                  Trocar foto
                </button>
              </div>
            ) : (
              <div
                className={`nova-pub-foto-upload ${erros.foto ? "nova-pub-campo-erro" : ""}`}
                onClick={() => fotoInputRef.current.click()}
              >
                <span className="material-symbols-outlined nova-pub-upload-icone">add_photo_alternate</span>
                <p className="nova-pub-upload-texto">Clique para adicionar uma foto</p>
                <span className="nova-pub-upload-dica">JPG, PNG até 10MB</span>
              </div>
            )}

            {erros.foto && (
              <p className="nova-pub-erro-msg">
                <span className="material-symbols-outlined">error</span>
                {erros.foto}
              </p>
            )}

            <input
              type="file"
              accept="image/*"
              ref={fotoInputRef}
              style={{ display: "none" }}
              onChange={handleFotoChange}
            />
          </div>

          {/* SEÇÃO — LOCAL */}
          <div className="nova-pub-secao">
            <label className="nova-pub-label" htmlFor="campo-local">
              Local <span className="nova-pub-obrigatorio">*</span>
            </label>
            <div className="nova-pub-input-icone">
              <span className="material-symbols-outlined nova-pub-input-symbol">location_on</span>
              <input
                id="campo-local"
                type="text"
                className={`nova-pub-input nova-pub-input-com-icone ${erros.local ? "nova-pub-campo-erro" : ""}`}
                placeholder="Ex: Represa de Ibitinga, SP"
                value={local}
                onChange={(e) => {
                  setLocal(e.target.value);
                  if (erros.local) setErros((prev) => ({ ...prev, local: "" }));
                }}
                maxLength={80}
              />
            </div>
            {erros.local && (
              <p className="nova-pub-erro-msg">
                <span className="material-symbols-outlined">error</span>
                {erros.local}
              </p>
            )}
          </div>

          {/* SEÇÃO — DESCRIÇÃO */}
          <div className="nova-pub-secao">
            <label className="nova-pub-label" htmlFor="campo-descricao">Descrição</label>
            <textarea
              id="campo-descricao"
              className="nova-pub-textarea"
              placeholder="Conte como foi a pescaria, dicas do local..."
              value={descricao}
              onChange={(e) => setDescricao(e.target.value)}
              maxLength={300}
              rows={4}
            />
            <p className="nova-pub-contador">{descricao.length}/300</p>
          </div>

          {/* SEÇÃO — AVALIAÇÃO OPCIONAL */}
          <div className="nova-pub-secao">
            <label className="nova-pub-label">
              Avaliação do local
              <span className="nova-pub-opcional"> (opcional)</span>
            </label>
            <p className="nova-pub-avaliacao-dica">
              Se quiser, avalie o local para ajudar outros pescadores.
            </p>
            <div className="nova-pub-estrelas">
              {[1, 2, 3, 4, 5].map((estrela) => (
                <button
                  key={estrela}
                  className={`nova-pub-estrela ${estrela <= (avaliacaoHover || avaliacao) ? "ativa" : ""}`}
                  onClick={() => setAvaliacao(avaliacao === estrela ? 0 : estrela)}
                  onMouseEnter={() => setAvaliacaoHover(estrela)}
                  onMouseLeave={() => setAvaliacaoHover(0)}
                  type="button"
                  title={["", "Ruim", "Regular", "Bom", "Muito Bom", "Excelente"][estrela]}
                >
                  ⭐
                </button>
              ))}
              {avaliacao > 0 && (
                <>
                  <span className="nova-pub-avaliacao-texto">
                    {["", "Ruim", "Regular", "Bom", "Muito Bom", "Excelente"][avaliacao]}
                  </span>
                  <button
                    className="nova-pub-limpar-avaliacao"
                    onClick={() => setAvaliacao(0)}
                    type="button"
                    title="Remover avaliação"
                  >
                    <span className="material-symbols-outlined">close</span>
                  </button>
                </>
              )}
            </div>
          </div>

          {/* SEÇÃO — TAGS */}
          <div className="nova-pub-secao">
            <label className="nova-pub-label">Tags</label>

            <div className="nova-pub-tags-fixas">
              {TAGS_FIXAS.map((tag) => (
                <button
                  key={tag}
                  className={`nova-pub-tag ${tagsSelecionadas.includes(tag) ? "nova-pub-tag-ativa" : ""}`}
                  onClick={() => handleToggleTag(tag)}
                  type="button"
                >
                  {tagsSelecionadas.includes(tag) && (
                    <span className="material-symbols-outlined" style={{ fontSize: "14px" }}>check</span>
                  )}
                  {tag}
                </button>
              ))}
            </div>

            <div className="nova-pub-tag-custom">
              <input
                type="text"
                className="nova-pub-input"
                placeholder="Adicionar tag personalizada..."
                value={tagCustom}
                onChange={(e) => setTagCustom(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleAdicionarTagCustom()}
                maxLength={30}
              />
              <button
                className="nova-pub-tag-custom-btn"
                onClick={handleAdicionarTagCustom}
                type="button"
              >
                <span className="material-symbols-outlined">add</span>
              </button>
            </div>

            {tagsSelecionadas.length > 0 && (
              <div className="nova-pub-tags-selecionadas">
                <p className="nova-pub-tags-titulo">Selecionadas:</p>
                <div className="nova-pub-tags-lista">
                  {tagsSelecionadas.map((tag) => (
                    <span key={tag} className="nova-pub-tag-selecionada">
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

          {/* ERRO GERAL */}
          {erros.geral && (
            <p className="nova-pub-erro-msg">
              <span className="material-symbols-outlined">error</span>
              {erros.geral}
            </p>
          )}

          {/* BOTÃO PUBLICAR */}
          <button
            className={`nova-pub-btn-publicar ${publicando ? "publicando" : ""} ${publicado ? "publicado" : ""}`}
            onClick={handlePublicar}
            disabled={publicando || publicado}
          >
            {publicado ? (
              <>
                <span className="material-symbols-outlined">check_circle</span>
                Publicado com sucesso!
              </>
            ) : publicando ? (
              <>
                <span className="material-symbols-outlined">hourglass_top</span>
                Publicando...
              </>
            ) : (
              <>
                <span className="material-symbols-outlined">publish</span>
                Publicar
              </>
            )}
          </button>

        </div>
      </div>
    </Layout>
  );
}
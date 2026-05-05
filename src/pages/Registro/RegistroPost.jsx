
import React, { useState } from "react";
import "./Registro.css";
import { useNavigate } from "react-router-dom";

// FIREBASE
import {
  collection,
  addDoc,
  serverTimestamp
} from "firebase/firestore";
import { db } from "../../firebase";

const RegistroPost = () => {
  const navigate = useNavigate();

  const [imagem, setImagem] = useState(null);
  const [local, setLocal] = useState("");
  const [descricao, setDescricao] = useState("");
  const [avaliacao, setAvaliacao] = useState(0);
  const [tags, setTags] = useState([]);
  const [novaTag, setNovaTag] = useState("");
  const [loading, setLoading] = useState(false);

  const tagsPadrao = [
    "Rio",
    "Lago",
    "Represa",
    "Mar",
    "Pesca Esportiva",
    "Pesca Noturna",
    "Pesca de Fundo",
    "Iniciante",
    "Família"
  ];

  const handleImagem = (e) => {
    const file = e.target.files[0];
    if (file) {
      setImagem(URL.createObjectURL(file));
    }
  };

  const toggleTag = (tag) => {
    if (tags.includes(tag)) {
      setTags(tags.filter((t) => t !== tag));
    } else {
      setTags([...tags, tag]);
    }
  };

  const adicionarTag = () => {
    if (!novaTag.trim()) return;
    setTags([...tags, novaTag]);
    setNovaTag("");
  };

  const publicar = async () => {
    if (!descricao || !local) {
      alert("Preencha os campos obrigatórios");
      return;
    }

    try {
      setLoading(true);

      await addDoc(collection(db, "publicacoes"), {
        autor: "Usuário",
        texto: descricao,
        localizacao: local,
        avaliacao,
        tags,
        imagemPost: imagem || "",
        curtidas: 0,
        comentarios: [],
        createdAt: serverTimestamp()
      });

      // pequeno delay pra UX
      await new Promise((resolve) => setTimeout(resolve, 700));

      navigate("/");
    } catch (error) {
      console.error("Erro ao publicar:", error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="registro-container">
      <div className="registro-card">

        <div className="header">
          <button type="button" onClick={() => navigate(-1)}>← Voltar</button>
          <h2>Nova Publicação</h2>
        </div>

        {/* FOTO */}
        <label className="upload-box">
          {imagem ? (
            <img src={imagem} alt="preview" />
          ) : (
            <span>Clique para adicionar uma foto</span>
          )}
          <input type="file" hidden onChange={handleImagem} />
        </label>

        {/* LOCAL */}
        <input
          type="text"
          placeholder="Ex: Represa de Ibitinga, SP"
          value={local}
          onChange={(e) => setLocal(e.target.value)}
        />

        {/* DESCRIÇÃO */}
        <textarea
          placeholder="Conte como foi a pescaria..."
          maxLength={300}
          value={descricao}
          onChange={(e) => setDescricao(e.target.value)}
        />

        <span>{descricao.length}/300</span>

        {/* AVALIAÇÃO */}
        <div className="stars">
          {[1, 2, 3, 4, 5].map((n) => (
            <span
              key={n}
              onClick={() => setAvaliacao(n)}
              className={avaliacao >= n ? "active" : ""}
            >
              ⭐
            </span>
          ))}
        </div>

        {/* TAGS */}
        <div className="tags">
          {tagsPadrao.map((tag) => (
            <button
              type="button"
              key={tag}
              className={tags.includes(tag) ? "active" : ""}
              onClick={() => toggleTag(tag)}
            >
              {tag}
            </button>
          ))}
        </div>

        <div className="add-tag">
          <input
            type="text"
            placeholder="Adicionar tag personalizada..."
            value={novaTag}
            onChange={(e) => setNovaTag(e.target.value)}
          />
          <button type="button" onClick={adicionarTag}>+</button>
        </div>

        {/* BOTÃO */}
        <button
          type="button"
          className="btn-publicar"
          onClick={publicar}
          disabled={loading}
        >
          {loading ? "Publicando..." : "Publicar"}
        </button>

      </div>
    </div>
  );
};

export default RegistroPost;


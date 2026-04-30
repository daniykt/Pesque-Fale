import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import Layout from "../../components/sidebar/layout";
import "./pesquisa.css";
import { collection, getDocs } from "firebase/firestore";
import { db } from "../../firebase";

/* ===== COMPONENTES REUTILIZÁVEIS ===== */

// Abas (Usuários / Locais)
const Tabs = ({ activeTab, onTabChange }) => {
  return (
    <div className="tabs-container">
      <button
        className={`tab ${activeTab === "users" ? "active" : ""}`}
        onClick={() => onTabChange("users")}
      >
        <i className="fas fa-users"></i> Usuários
      </button>
      <button
        className={`tab ${activeTab === "locations" ? "active" : ""}`}
        onClick={() => onTabChange("locations")}
      >
        <i className="fas fa-map-marker-alt"></i> Locais
      </button>
    </div>
  );
};

// Barra de busca
const SearchBar = ({ placeholder, value, onChange }) => {
  return (
    <div className="search-bar-wrapper">
      <i className="fas fa-search search-icon"></i>
      <input
        type="text"
        className="search-input"
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    </div>
  );
};

// Card de Usuário
const UserCard = ({ user, onClick }) => {
  const [imgError, setImgError] = useState(false);
  const nomeExibicao = user.nome || user.username || "Pescador";

  // Iniciais para o avatar placeholder (ex: "João Pedro" → "JP")
  const iniciais = nomeExibicao
    .split(" ")
    .slice(0, 2)
    .map((p) => p[0])
    .join("")
    .toUpperCase();

  const temFoto = user.foto && !imgError;

  return (
    <div className="user-card" onClick={onClick}>
      {/* Avatar com fallback de iniciais — sem via.placeholder.com */}
      {temFoto ? (
        <img
          src={user.foto}
          alt={nomeExibicao}
          className="user-avatar"
          onError={() => setImgError(true)}
        />
      ) : (
        <div className="user-avatar-placeholder">{iniciais}</div>
      )}

      <div className="user-info">
        {/* Nome + verificado */}
        <h4 className="user-name">
          {nomeExibicao}
          {user.verificado && (
            <span className="user-verified" title="Verificado">
              <i className="fas fa-check-circle"></i>
            </span>
          )}
        </h4>

        <span className="user-username">@{user.username || "usuario"}</span>

        {/* Cidade */}
        {user.cidade && (
          <div className="user-cidade">
            <i className="fas fa-map-marker-alt"></i>
            {user.cidade}
          </div>
        )}

        {/* Bio */}
        {user.bio && <p className="user-bio">{user.bio}</p>}

        {/* Badges: capturas + especialidades */}
        {(user.capturas || user.especialidades?.length > 0) && (
          <div className="user-badges">
            {user.capturas && (
              <span className="user-badge-pill capturas">
                <i className="fas fa-fish"></i> {user.capturas} capturas
              </span>
            )}
            {user.especialidades?.slice(0, 2).map((esp, idx) => (
              <span key={idx} className="user-badge-pill">
                {esp}
              </span>
            ))}
          </div>
        )}
      </div>

      <button className="user-action-btn">Ver perfil</button>
    </div>
  );
};

// Card de Local
const LocationCard = ({ local }) => {
  const [imgError, setImgError] = useState(false);

  const ratingValue = Number(local.avaliacao) || 0;
  const safeRating  = Math.min(5, Math.max(0, ratingValue));
  const fullStars   = Math.floor(safeRating);
  const emptyStars  = 5 - fullStars;

  const temImagem = local.imagem && !imgError;

  return (
    <div className="location-card-new">
      {/* Imagem ou placeholder próprio — sem via.placeholder.com */}
      {temImagem ? (
        <img
          src={local.imagem}
          alt={local.nome}
          className="location-card-image"
          onError={() => setImgError(true)}
        />
      ) : (
        <div
          className="location-card-image"
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            background: "rgba(6,42,108,0.07)",
            fontSize: "2.5rem",
          }}
        >
          🎣
        </div>
      )}

      <div className="location-card-content">
        {/* Badge do tipo */}
        {local.tipo && (
          <span className="location-tipo-badge">{local.tipo}</span>
        )}

        <h4 className="location-card-name">{local.nome}</h4>

        {/* Estrelas + contagem */}
        <div className="location-card-rating">
          <span className="stars">
            {"★".repeat(fullStars)}
            {"☆".repeat(emptyStars)}
          </span>
          <span className="rating-value">{safeRating.toFixed(1)}</span>
          <span className="reviews-count">
            ({local.avaliacoes || 0} avaliações)
          </span>
        </div>

        {/* Descrição curta */}
        {local.descricao && (
          <p className="location-card-desc">{local.descricao}</p>
        )}

        {/* Endereço */}
        <div className="location-card-address">
          <i className="fas fa-map-pin"></i> {local.localizacao}
        </div>

        {/* Tags */}
        {local.tags?.length > 0 && (
          <div className="location-tags">
            {local.tags.slice(0, 4).map((tag, idx) => (
              <span key={idx} className="location-tag">
                {tag}
              </span>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

/* ===== COMPONENTE PRINCIPAL ===== */
export default function Pesquisar() {
  const navigate = useNavigate();

  const [activeTab, setActiveTab] = useState("users");
  const [searchTerm, setSearchTerm] = useState("");

  const [locais, setLocais] = useState([]);
  const [usuarios, setUsuarios] = useState([]);
  const [loading, setLoading] = useState(true);

  // Filtros de locais
  const [filtroTipo, setFiltroTipo] = useState("todos");
  const [filtroAvaliacao, setFiltroAvaliacao] = useState("todas");

  // 🔥 Buscar dados do Firestore
  useEffect(() => {
    const fetchData = async () => {
      try {
        const locaisSnap = await getDocs(collection(db, "locais"));
        const usuariosSnap = await getDocs(collection(db, "usuarios"));

        const locaisData = locaisSnap.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));

        const usuariosData = usuariosSnap.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));

        setLocais(locaisData);
        setUsuarios(usuariosData);
      } catch (error) {
        console.error("Erro ao buscar dados:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  // 🔎 Filtragem baseada no termo de busca
  const filterData = () => {
    const termo = searchTerm.toLowerCase();

    if (activeTab === "users") {
      if (!termo) return usuarios;
      return usuarios.filter(
        (user) =>
          user.username?.toLowerCase().includes(termo) ||
          user.nome?.toLowerCase().includes(termo) ||
          user.bio?.toLowerCase().includes(termo)
      );
    } else {
      return locais.filter((local) => {
        const matchTermo =
          !termo ||
          local.nome?.toLowerCase().includes(termo) ||
          local.localizacao?.toLowerCase().includes(termo);

        const matchTipo =
          filtroTipo === "todos" || local.tipo === filtroTipo;

        const avNum = Number(local.avaliacao ?? 0);
        const matchAvaliacao =
          filtroAvaliacao === "todas" ||
          (filtroAvaliacao === "4+" && avNum >= 4) ||
          (filtroAvaliacao === "3+" && avNum >= 3) ||
          (filtroAvaliacao === "2+" && avNum >= 2);

        return matchTermo && matchTipo && matchAvaliacao;
      });
    }
  };

  const filteredResults = filterData();

  // Placeholder dinâmico conforme aba ativa
  const searchPlaceholder =
    activeTab === "users"
      ? "Buscar pescadores..."
      : "Buscar rios, lagos...";

  return (
    <Layout>
      <main className="search-container">

        <Tabs activeTab={activeTab} onTabChange={setActiveTab} />

        <SearchBar
          placeholder={searchPlaceholder}
          value={searchTerm}
          onChange={setSearchTerm}
        />

        {/* Filtros — visíveis só na aba de Locais */}
        {activeTab === "locations" && (
          <div className="filtros-locais">
            <div className="filtro-group">
              <label htmlFor="filtro-tipo">Tipo</label>
              <select
                id="filtro-tipo"
                value={filtroTipo}
                onChange={(e) => setFiltroTipo(e.target.value)}
              >
                <option value="todos">Todos</option>
                <option value="rio">Rio</option>
                <option value="represa">Represa</option>
                <option value="pesqueiro">Pesqueiro</option>
                <option value="lago">Lago</option>
              </select>
            </div>

            <div className="filtro-group">
              <label htmlFor="filtro-avaliacao">Avaliação mínima</label>
              <select
                id="filtro-avaliacao"
                value={filtroAvaliacao}
                onChange={(e) => setFiltroAvaliacao(e.target.value)}
              >
                <option value="todas">Todas</option>
                <option value="4+">4+ estrelas</option>
                <option value="3+">3+ estrelas</option>
                <option value="2+">2+ estrelas</option>
              </select>
            </div>
          </div>
        )}

        {/* Resultados */}
        <div className="results-section">
          {loading ? (
            <div className="loading-state">
              <i className="fas fa-spinner fa-pulse"></i>
              <p>Carregando...</p>
            </div>
          ) : filteredResults.length === 0 ? (
            <div className="empty-state">
              <i
                className={`fas ${
                  activeTab === "users" ? "fa-user-friends" : "fa-map-marked-alt"
                }`}
              ></i>
              <p>
                {activeTab === "users"
                  ? "Nenhum pescador encontrado 🐟"
                  : "Nenhum local encontrado 📍"}
              </p>
            </div>
          ) : (
            <div className="results-grid">
              {activeTab === "users"
                ? filteredResults.map((user) => (
                    <UserCard
                      key={user.id}
                      user={user}
                      onClick={() => navigate(`/perfil/${user.id}`)}
                    />
                  ))
                : filteredResults.map((local) => (
                    <LocationCard key={local.id} local={local} />
                  ))}
            </div>
          )}
        </div>
      </main>
    </Layout>
  );
}
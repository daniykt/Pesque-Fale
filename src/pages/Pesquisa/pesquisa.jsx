import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import Layout from "../../components/sidebar/layout";
import "./pesquisa.css";

import { collection, getDocs } from "firebase/firestore";
import { db } from "../../firebase";

export default function Pesquisar() {
  const navigate = useNavigate();

  const [searchTerm, setSearchTerm] = useState("");
  const [locais, setLocais] = useState([]);
  const [usuarios, setUsuarios] = useState([]);

  const [filteredLocais, setFilteredLocais] = useState([]);
  const [filteredUsuarios, setFilteredUsuarios] = useState([]);

  const [loading, setLoading] = useState(true);

  // 🔥 Buscar dados
  useEffect(() => {
    const fetchData = async () => {
      const locaisSnap = await getDocs(collection(db, "locais"));
      const usuariosSnap = await getDocs(collection(db, "usuarios"));

      const locaisData = locaisSnap.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      const usuariosData = usuariosSnap.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      setLocais(locaisData);
      setUsuarios(usuariosData);

      setFilteredLocais(locaisData);
      setLoading(false);
    };

    fetchData();
  }, []);

  // 🔎 Busca estilo Instagram
  useEffect(() => {
    const timeout = setTimeout(() => {
      const termo = searchTerm.toLowerCase();

      const locaisFiltrados = locais.filter(local =>
        local.nome?.toLowerCase().includes(termo) ||
        local.localizacao?.toLowerCase().includes(termo)
      );

      const usuariosFiltrados = usuarios.filter(user =>
        user.username?.toLowerCase().includes(termo) ||
        user.nome?.toLowerCase().includes(termo)
      );

      setFilteredLocais(locaisFiltrados);
      setFilteredUsuarios(searchTerm ? usuariosFiltrados : []);
    }, 300);

    return () => clearTimeout(timeout);
  }, [searchTerm, locais, usuarios]);

  return (
    <Layout>
      <main className="search-container">

        {/* 🔎 TOPO */}
        <div className="search-header">
          <h2>Pesquisar</h2>

          <input
            type="text"
            placeholder="Buscar locais ou usuários..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="search-input"
          />
        </div>

        {/* 🔥 RESULTADOS */}
        <div className="results-container">

          {loading && <p>Carregando...</p>}

          {/* 👤 USUÁRIOS */}
          {filteredUsuarios.length > 0 && (
            <div className="users-section">
              <h3>Usuários</h3>

              {filteredUsuarios.map(user => (
                <div
                  key={user.id}
                  className="user-card"
                  onClick={() => navigate(`/perfil/${user.id}`)}
                >
                  <img
                    src={user.foto || "https://via.placeholder.com/50"}
                    alt={user.nome}
                    className="user-avatar"
                  />

                  <div>
                    <strong>@{user.username}</strong>
                    <p>{user.nome}</p>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* 📍 LOCAIS */}
          <div className="locais-section">
            <h3>Locais</h3>

            {filteredLocais.length > 0 ? (
              filteredLocais.map(local => (
                <div key={local.id} className="location-card">
                  <img
                    src={local.imagem}
                    alt={local.nome}
                    className="location-image"
                  />

                  <div className="location-info">
                    <h3>{local.nome}</h3>
                    <p>{local.localizacao}</p>

                    <div className="rating">
                      ⭐ {Number(local.avaliacao ?? 0).toFixed(1)}
                    </div>
                  </div>
                </div>
              ))
            ) : (
              !loading && <p>Nenhum local encontrado.</p>
            )}
          </div>

        </div>
      </main>

        <footer>
        <div className="footer-container">
          <div className="footer-info">
            <h3>Sobre Nós</h3>
            <p>
              Grupo de estudantes dedicados ao desenvolvimento de iniciativas
              voltadas à melhoria do trabalho socioeconômico em Matão-SP e
              região.
            </p>
          </div>

          <div className="footer-links">
            <h3>Links Úteis</h3>
                <a href="/home">Página Inicial</a>
                <br />
                <a href="/pesquisar">Pesquisa de Locais</a>
                <br />
                <a href="/locais">Melhores Locais</a>
                <br />
                <a href="/notificacao">Notificações</a>
                <br />
                <a href="/sobre">Sobre Nós</a>
                <br />
                <a href="/perfil">Perfil</a>
          </div>

          <div className="footer-contact">
            <h3>Contato</h3>
            <p>
              Email: <strong>pesquefale@gmail.com</strong>
            </p>
          </div>
        </div>
        <p className="copyright">
          &copy; Pesque & Fale 2025 - Todos os direitos reservados.
        </p>
      </footer>
    </Layout>
  );
}
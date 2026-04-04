import React, { useEffect, useState, useRef } from "react";
import Layout from "../../components/sidebar/layout";
import "./perfil.css";
import "../../styles/global.css";
import { observeAuthState } from "../../auth";

export default function Perfil() {
  const [user, setUser] = useState(null);

  const [fotoPerfil, setFotoPerfil] = useState(
    localStorage.getItem("fotoPerfil") ||
    "https://preview.redd.it/on9y92ssh1mb1.jpg"
  );

  // 🆕 BIO EDITÁVEL
  const [bio, setBio] = useState(
    localStorage.getItem("bio") || "Quem não gosta de pesca?"
  );

  const [posts, setPosts] = useState(() => {
    const dados = JSON.parse(localStorage.getItem("posts")) || [];

    return dados.map((post) => ({
      ...post,
      comentarios: Array.isArray(post.comentarios)
        ? post.comentarios
        : [],
    }));
  });

  const fileInputRef = useRef(null);
  const postInputRef = useRef(null);

  useEffect(() => {
    const unsubscribe = observeAuthState((currentUser) => {
      setUser(currentUser);
    });
    return unsubscribe;
  }, []);

  const salvarPosts = (novosPosts) => {
    setPosts(novosPosts);
    localStorage.setItem("posts", JSON.stringify(novosPosts));
  };

  // 🆕 EDITAR BIO
  const handleEditarBio = () => {
    const novaBio = prompt("Digite sua nova bio:", bio);
    if (novaBio !== null) {
      setBio(novaBio);
      localStorage.setItem("bio", novaBio);
    }
  };

  const handleFotoClick = () => {
    fileInputRef.current.click();
  };

  const handleFotoChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => {
      setFotoPerfil(reader.result);
      localStorage.setItem("fotoPerfil", reader.result);
    };
    reader.readAsDataURL(file);
  };

  const handlePublicar = () => {
    postInputRef.current.click();
  };

  const handlePostChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const comentario = prompt("Digite uma descrição para o post:");
    const local = prompt("Digite o local:");

    const reader = new FileReader();

    reader.onload = () => {
      const novoPost = {
        id: Date.now(),
        imagem: reader.result,
        data: new Date().toLocaleString(),
        comentario: comentario || "Sem descrição",
        local: local || "Local não informado",
        avaliacao: "★★★★★",
        curtidas: 0,
        comentarios: [],
      };

      const novosPosts = [novoPost, ...posts];
      salvarPosts(novosPosts);
    };

    reader.readAsDataURL(file);
  };

  const handleCurtir = (id) => {
    const novosPosts = posts.map((post) =>
      post.id === id
        ? { ...post, curtidas: post.curtidas + 1 }
        : post
    );

    salvarPosts(novosPosts);
  };

  const handleComentar = (id) => {
    const texto = prompt("Digite seu comentário:");
    if (!texto) return;

    const novosPosts = posts.map((post) => {
      if (post.id === id) {
        return {
          ...post,
          comentarios: [...post.comentarios, texto],
        };
      }
      return post;
    });

    salvarPosts(novosPosts);
  };

  const handleShare = async () => {
    const url = window.location.href;

    if (navigator.share) {
      await navigator.share({
        title: "Pesque & Fale",
        text: "Olha meu perfil!",
        url,
      });
    } else {
      navigator.clipboard.writeText(url);
      alert("Link copiado!");
    }
  };

  const handleDeletePost = (id) => {
    const confirmar = window.confirm("Tem certeza que deseja excluir este post?");
    if (!confirmar) return;

    const novosPosts = posts.filter((post) => post.id !== id);
    salvarPosts(novosPosts);
  };

  return (
    <Layout>
      <div className="container2">
        <div className="perfil">

          {/* FOTO */}
          <img
            src={fotoPerfil}
            alt="Foto de Perfil"
            className="foto-perfil"
            style={{ cursor: "pointer" }}
            onClick={handleFotoClick}
          />

          <input
            type="file"
            accept="image/*"
            ref={fileInputRef}
            style={{ display: "none" }}
            onChange={handleFotoChange}
          />

          {/* STATS */}
          <div className="profile-stats">
            <div className="stat-box">
              <span className="number">{posts.length}</span>
              <span className="label">Publicações</span>
            </div>
            <div className="stat-box">
              <span className="number">200</span>
              <span className="label">Seguidores</span>
            </div>
            <div className="stat-box">
              <span className="number">180</span>
              <span className="label">Seguindo</span>
            </div>
          </div>

          {/* NOME */}
          <div className="username-container">
            <h2 className="username">
              {user?.displayName || user?.email || "Usuário"}
            </h2>
          </div>

          {/* 🆕 BIO CLICÁVEL */}
          <div
            className="bio"
            style={{ cursor: "pointer" }}
            onClick={handleEditarBio}
            title="Clique para editar sua bio"
          >
            <p>{bio}</p>
          </div>

          {/* BOTÃO */}
          <div className="botoes-acao">
            <button className="btn-publicar" onClick={handlePublicar}>
              <span className="material-symbols-outlined">add_box</span>
              <span className="btn-text">Publicar</span>
            </button>
          </div>

          <input
            type="file"
            accept="image/*"
            ref={postInputRef}
            style={{ display: "none" }}
            onChange={handlePostChange}
          />

          {/* POSTS */}
          {posts.map((post) => (
            <div className="publicacao-horizontal" key={post.id}>
              <img src={post.imagem} className="foto-horizontal" />

              <div className="info-direita">
                <div className="data-publicacao">
                  Postado em {post.data}
                </div>

                <div className="comentario">{post.comentario}</div>
                <div className="local">{post.local}</div>
                <div className="avaliacao">{post.avaliacao}</div>

                <div className="interacoes">
                  <button
                    className="btn-interacao"
                    onClick={() => handleCurtir(post.id)}
                  >
                    👍 {post.curtidas}
                  </button>

                  <button
                    className="btn-interacao"
                    onClick={() => handleComentar(post.id)}
                  >
                    💬 {post.comentarios?.length || 0}
                  </button>

                  <button
                    className="btn-interacao"
                    onClick={handleShare}
                  >
                    🔗 Compartilhar
                  </button>

                  <button
                    className="btn-interacao"
                    onClick={() => handleDeletePost(post.id)}
                  >
                    🗑️ Excluir
                  </button>
                </div>

                {post.comentarios?.length > 0 && (
                  <div className="lista-comentarios">
                    {post.comentarios.map((c, index) => (
                      <p key={index}>💬 {c}</p>
                    ))}
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* FOOTER */}
      <footer>
        <div className="footer-container">
          <div className="footer-info">
            <h3>Sobre Nós</h3>
            <p>
              Grupo de estudantes dedicados ao desenvolvimento de iniciativas
              voltadas à melhoria do trabalho socioeconômico em Matão-SP.
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
            <p>Email: <strong>pesquefale@gmail.com</strong></p>
          </div>
        </div>

        <p className="copyright">
          &copy; Pesque & Fale 2025
        </p>
      </footer>
    </Layout>
  );
}
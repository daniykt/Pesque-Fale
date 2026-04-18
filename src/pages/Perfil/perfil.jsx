import React, { useEffect, useState, useRef } from "react";
import Layout from "../../components/sidebar/layout";
import "./perfil.css";
import "../../styles/global.css";
import { observeAuthState } from "../../auth";
import {
  CabecalhoPerfil,
  EstatisticasPerfil,
  AcoesPerfil,
  GaleriaPerfil,
} from "../../components/perfil";

export default function Perfil() {
  const [user, setUser] = useState(null);

  const [fotoPerfil, setFotoPerfil] = useState(
    localStorage.getItem("fotoPerfil") ||
    "https://preview.redd.it/on9y92ssh1mb1.jpg"
  );

  const [banner, setBanner] = useState(
    localStorage.getItem("banner") || null
  );

  const [bio, setBio] = useState(
    localStorage.getItem("bio") || "Quem não gosta de pesca?"
  );

  const [localizacao, setLocalizacao] = useState(
    localStorage.getItem("localizacao") || ""
  );

  const [posts, setPosts] = useState(() => {
    const dados = JSON.parse(localStorage.getItem("posts")) || [];
    return dados.map((post) => ({
      ...post,
      comentarios: Array.isArray(post.comentarios) ? post.comentarios : [],
    }));
  });

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

  const handleFotoChange = (file) => {
    const reader = new FileReader();
    reader.onload = () => {
      setFotoPerfil(reader.result);
      localStorage.setItem("fotoPerfil", reader.result);
    };
    reader.readAsDataURL(file);
  };

  const handleBannerChange = (file) => {
    const reader = new FileReader();
    reader.onload = () => {
      setBanner(reader.result);
      localStorage.setItem("banner", reader.result);
    };
    reader.readAsDataURL(file);
  };

  const handlePublicar = () => postInputRef.current.click();

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
      salvarPosts([novoPost, ...posts]);
    };
    reader.readAsDataURL(file);
  };

  const handleCurtir = (id) => {
    salvarPosts(posts.map((post) =>
      post.id === id ? { ...post, curtidas: post.curtidas + 1 } : post
    ));
  };

  const handleComentar = (id) => {
    const texto = prompt("Digite seu comentário:");
    if (!texto) return;
    salvarPosts(posts.map((post) =>
      post.id === id
        ? { ...post, comentarios: [...post.comentarios, texto] }
        : post
    ));
  };

  const handleShare = async () => {
    const url = window.location.href;
    if (navigator.share) {
      await navigator.share({ title: "Pesque & Fale", text: "Olha meu perfil!", url });
    } else {
      navigator.clipboard.writeText(url);
      alert("Link copiado!");
    }
  };

  const handleDeletar = (id) => {
    if (!window.confirm("Tem certeza que deseja excluir este post?")) return;
    salvarPosts(posts.filter((post) => post.id !== id));
  };

  return (
    <Layout>
      <div className="container2">
        <div className="perfil">

          <CabecalhoPerfil
            fotoPerfil={fotoPerfil}
            onFotoChange={handleFotoChange}
            banner={banner}
            onBannerChange={handleBannerChange}
            usuario={user}
            bio={bio}
            localizacao={localizacao}
          />

          <EstatisticasPerfil totalPosts={posts.length} />

          <AcoesPerfil onPublicar={handlePublicar} />

          <input
            type="file"
            accept="image/*"
            ref={postInputRef}
            style={{ display: "none" }}
            onChange={handlePostChange}
          />

          <GaleriaPerfil
            posts={posts}
            onCurtir={handleCurtir}
            onComentar={handleComentar}
            onShare={handleShare}
            onDeletar={handleDeletar}
          />

        </div>
      </div>

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
            <a href="/home">Página Inicial</a><br />
            <a href="/pesquisar">Pesquisa de Locais</a><br />
            <a href="/locais">Melhores Locais</a><br />
            <a href="/notificacao">Notificações</a><br />
            <a href="/sobre">Sobre Nós</a><br />
            <a href="/perfil">Perfil</a>
          </div>
          <div className="footer-contact">
            <h3>Contato</h3>
            <p>Email: <strong>pesquefale@gmail.com</strong></p>
          </div>
        </div>
        <p className="copyright">&copy; Pesque & Fale 2025</p>
      </footer>
    </Layout>
  );
}
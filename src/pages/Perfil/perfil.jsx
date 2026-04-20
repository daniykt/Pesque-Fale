import React, { useEffect, useState, useRef } from "react";
import { useParams } from "react-router-dom";
import Layout from "../../components/sidebar/layout";
import "./perfil.css";
import "../../styles/global.css";
import { observeAuthState } from "../../auth";

import { db } from "../../firebase";
import { doc, getDoc, updateDoc } from "firebase/firestore";

import {
  CabecalhoPerfil,
  EstatisticasPerfil,
  AbasPerfil,
  GaleriaPerfil,
} from "../../components/perfil";

export default function Perfil() {
  const { id } = useParams(); // 🔥 pega ID da URL

  const [user, setUser] = useState(null);
  const [usuarioPerfil, setUsuarioPerfil] = useState(null); // 🔥 perfil sendo exibido

  const [abaSelecionada, setAbaSelecionada] = useState("Galeria");

  const [fotoPerfil, setFotoPerfil] = useState("https://preview.redd.it/on9y92ssh1mb1.jpg");
  const [banner, setBanner] = useState(null);
  const [bio, setBio] = useState("");
  const [localizacao, setLocalizacao] = useState("");

  const [posts, setPosts] = useState([]);

  const postInputRef = useRef(null);

  // 🔐 usuário logado
  useEffect(() => {
    const unsubscribe = observeAuthState((currentUser) => setUser(currentUser));
    return unsubscribe;
  }, []);

  // 🔥 BUSCA PERFIL (PRINCIPAL)
  useEffect(() => {
    const carregarDados = async () => {
      try {
        // 🔥 define qual ID usar
        const userId = id ? id : user?.uid;

        if (!userId) return;

        const docRef = doc(db, "usuarios", userId);
        const docSnap = await getDoc(docRef);

        if (docSnap.exists()) {
          const data = docSnap.data();

          setUsuarioPerfil({ id: docSnap.id, ...data });

          setBio(data.bio || "");
          setLocalizacao(data.localizacao || "");
          setFotoPerfil(data.fotoPerfil || "https://preview.redd.it/on9y92ssh1mb1.jpg");
          setBanner(data.banner || null);
          setPosts(data.posts || []);
        } else {
          console.log("Usuário não encontrado");
        }
      } catch (error) {
        console.error("Erro ao carregar perfil:", error);
      }
    };

    carregarDados();
  }, [user, id]);

  // 🔒 só pode editar se for seu perfil
  const isOwnProfile = !id || id === user?.uid;

  // 💾 salvar posts (só se for seu perfil)
  const salvarPosts = async (novosPosts) => {
    if (!isOwnProfile) return;

    setPosts(novosPosts);

    try {
      const docRef = doc(db, "usuarios", user.uid);

      await updateDoc(docRef, {
        posts: novosPosts,
      });
    } catch (error) {
      console.error("Erro ao salvar posts:", error);
    }
  };

  const handleFotoChange = (file) => {
    if (!isOwnProfile) return;

    const reader = new FileReader();
    reader.onload = () => setFotoPerfil(reader.result);
    reader.readAsDataURL(file);
  };

  const handleBannerChange = (file) => {
    if (!isOwnProfile) return;

    const reader = new FileReader();
    reader.onload = () => setBanner(reader.result);
    reader.readAsDataURL(file);
  };

  const handlePublicar = () => {
    if (!isOwnProfile) return;
    postInputRef.current.click();
  };

  const handlePostChange = (e) => {
    if (!isOwnProfile) return;

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

  const handleCurtir = (idPost) => {
    salvarPosts(
      posts.map((post) =>
        post.id === idPost ? { ...post, curtidas: post.curtidas + 1 } : post
      )
    );
  };

  const handleComentar = (idPost) => {
    const texto = prompt("Digite seu comentário:");
    if (!texto) return;

    salvarPosts(
      posts.map((post) =>
        post.id === idPost
          ? { ...post, comentarios: [...post.comentarios, texto] }
          : post
      )
    );
  };

  const handleShare = async () => {
    const url = window.location.href;
    if (navigator.share) {
      await navigator.share({ title: "Pesque & Fale", text: "Olha esse perfil!", url });
    } else {
      navigator.clipboard.writeText(url);
      alert("Link copiado!");
    }
  };

  const handleDeletar = (idPost) => {
    if (!isOwnProfile) return;

    if (!window.confirm("Tem certeza que deseja excluir este post?")) return;
    salvarPosts(posts.filter((post) => post.id !== idPost));
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
            onPublicar={handlePublicar}
            usuario={usuarioPerfil}
            bio={bio}
            localizacao={localizacao}
            isOwnProfile={isOwnProfile} // 🔥 novo
          />

          <EstatisticasPerfil totalPosts={posts.length} />

          <input
            type="file"
            accept="image/*"
            ref={postInputRef}
            style={{ display: "none" }}
            onChange={handlePostChange}
          />

          <AbasPerfil
            abaSelecionada={abaSelecionada}
            onTrocarAba={setAbaSelecionada}
          />

          {abaSelecionada === "Galeria" && (
            <GaleriaPerfil
              posts={posts}
              onCurtir={handleCurtir}
              onComentar={handleComentar}
              onShare={handleShare}
              onDeletar={handleDeletar}
              isOwnProfile={isOwnProfile} // 🔥 novo
            />
          )}

          {abaSelecionada === "Equipamentos" && (
            <div className="aba-em-breve">
              <p>Equipamentos em breve!</p>
            </div>
          )}

          {abaSelecionada === "Locais Salvos" && (
            <div className="aba-em-breve">
              <p>Locais Salvos em breve!</p>
            </div>
          )}

        </div>
      </div>

       <footer>
        <div className="footer-container">
          <div className="footer-info">
            <h3>Sobre Nós</h3>
            <p>Grupo de estudantes dedicados ao desenvolvimento de iniciativas voltadas à melhoria do trabalho socioeconômico em Matão-SP.</p>
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
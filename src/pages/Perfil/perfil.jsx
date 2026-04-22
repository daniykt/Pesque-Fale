import React, { useEffect, useState, useRef } from "react";
import { useParams } from "react-router-dom";
import Layout from "../../components/sidebar/layout";
import "./perfil.css";
import "../../styles/global.css";
import { observeAuthState } from "../../auth";

import { db } from "../../firebase";
import { doc, onSnapshot, updateDoc } from "firebase/firestore";

import {
  CabecalhoPerfil,
  EstatisticasPerfil,
  AbasPerfil,
  GaleriaPerfil,
} from "../../components/perfil";

export default function Perfil() {
  const { id } = useParams();

  const [user, setUser] = useState(null);
  const [usuarioPerfil, setUsuarioPerfil] = useState(null);
  const [posts, setPosts] = useState([]);

  const [fotoPerfil, setFotoPerfil] = useState("");
  const [banner, setBanner] = useState(null);
  const [bio, setBio] = useState("");
  const [localizacao, setLocalizacao] = useState("");

  const [abaSelecionada, setAbaSelecionada] = useState("Galeria");

  const postInputRef = useRef(null);

  // 🔐 Auth
  useEffect(() => {
    const unsubscribe = observeAuthState(setUser);
    return unsubscribe;
  }, []);

  // 🔥 TEMPO REAL
  useEffect(() => {
    if (!user && !id) return;

    const userId = id || user?.uid;
    if (!userId) return;

    const docRef = doc(db, "usuarios", userId);

    const unsubscribe = onSnapshot(docRef, (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data();

        setUsuarioPerfil({ id: docSnap.id, ...data });
        setPosts(data.posts || []);
        setBio(data.bio || "");
        setLocalizacao(data.localizacao || "");
        setFotoPerfil(data.fotoPerfil || "");
        setBanner(data.banner || null);
      }
    });

    return unsubscribe;
  }, [id, user]);

  const isOwnProfile = !id || id === user?.uid;

  // 💾 SALVAR POSTS
  const salvarPosts = async (novosPosts) => {
    if (!usuarioPerfil?.id) return;

    await updateDoc(doc(db, "usuarios", usuarioPerfil.id), {
      posts: novosPosts,
    });
  };

  // 🖼️ ATUALIZAR FOTO DE PERFIL
  const handleFotoChange = async (file) => {
    if (!isOwnProfile || !usuarioPerfil?.id) return;

    const reader = new FileReader();
    reader.onload = async () => {
      const base64 = reader.result;
      try {
        await updateDoc(doc(db, "usuarios", usuarioPerfil.id), {
          fotoPerfil: base64,
        });
        // O estado será atualizado automaticamente via onSnapshot
      } catch (error) {
        console.error("Erro ao atualizar foto de perfil:", error);
        alert("Não foi possível atualizar a foto. Tente novamente.");
      }
    };
    reader.readAsDataURL(file);
  };

  // 🌄 ATUALIZAR BANNER
  const handleBannerChange = async (file) => {
    if (!isOwnProfile || !usuarioPerfil?.id) return;

    const reader = new FileReader();
    reader.onload = async () => {
      const base64 = reader.result;
      try {
        await updateDoc(doc(db, "usuarios", usuarioPerfil.id), {
          banner: base64,
        });
      } catch (error) {
        console.error("Erro ao atualizar banner:", error);
        alert("Não foi possível atualizar a capa. Tente novamente.");
      }
    };
    reader.readAsDataURL(file);
  };

  // 📸 NOVO POST
  const handlePostChange = (e) => {
    if (!isOwnProfile) return;

    const file = e.target.files[0];
    if (!file) return;

    const comentario = prompt("Descrição:");
    const local = prompt("Local:");

    const reader = new FileReader();
    reader.onload = () => {
      const novoPost = {
        id: Date.now(),
        imagem: reader.result,
        data: new Date().toLocaleString(),
        comentario,
        local,
        curtidas: [],
        comentarios: [],
      };

      salvarPosts([novoPost, ...posts]);
    };

    reader.readAsDataURL(file);
  };

  return (
    <Layout>
      <div className="container2">
        <div className="perfil">

          <CabecalhoPerfil
            fotoPerfil={fotoPerfil}
            banner={banner}
            usuario={usuarioPerfil}
            bio={bio}
            localizacao={localizacao}
            isOwnProfile={isOwnProfile}
            onPublicar={() => postInputRef.current.click()}
            onFotoChange={handleFotoChange}
            onBannerChange={handleBannerChange}
          />

          <EstatisticasPerfil totalPosts={posts.length} />

          <input
            type="file"
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
              user={user}
              usuarioPerfil={usuarioPerfil}
              salvarPosts={salvarPosts}
            />
          )}

        </div>
      </div>
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
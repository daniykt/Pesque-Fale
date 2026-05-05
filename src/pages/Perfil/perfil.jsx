import React, { useEffect, useState, useRef } from "react";
import { useParams, useNavigate } from "react-router-dom";
import Layout from "../../components/sidebar/layout";
import "./perfil.css";
import "../../styles/global.css";
import { observeAuthState } from "../../auth";

import { db } from "../../firebase";
import {
  doc,
  onSnapshot,
  updateDoc,
  arrayUnion,
  arrayRemove,
  addDoc,
  collection,
  getDoc,
  setDoc,
  serverTimestamp,
} from "firebase/firestore";

import {
  CabecalhoPerfil,
  EstatisticasPerfil,
  AbasPerfil,
  GaleriaPerfil,
} from "../../components/perfil";

export default function Perfil() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [user, setUser] = useState(null);
  const [usuarioPerfil, setUsuarioPerfil] = useState(null);
  const [posts, setPosts] = useState([]);

  const [fotoPerfil, setFotoPerfil] = useState("");
  const [banner, setBanner] = useState(null);
  const [bio, setBio] = useState("");
  const [localizacao, setLocalizacao] = useState("");

  const [abaSelecionada, setAbaSelecionada] = useState("Galeria");
  const [isFollowing, setIsFollowing] = useState(false);

  const postInputRef = useRef(null);

  // 🔐 AUTH
  useEffect(() => {
    const unsubscribe = observeAuthState(setUser);
    return unsubscribe;
  }, []);

  const isOwnProfile = !id || id === user?.uid;

  // =========================
  // 🧹 LIMPA ESTADOS ao trocar de perfil
  // Evita que dados do perfil anterior apareçam antes do Firestore responder
  // =========================
  useEffect(() => {
    setUsuarioPerfil(null);
    setFotoPerfil("");
    setBanner(null);
    setBio("");
    setLocalizacao("");
    setPosts([]);
    setIsFollowing(false);
  }, [id]);

  // =========================
  // ⚡ CACHE INSTANTÂNEO — só para o próprio perfil
  // =========================
  useEffect(() => {
    // Só aplica cache quando for o próprio perfil E o user já foi carregado
    if (!isOwnProfile || !user) return;

    const cache = localStorage.getItem("usuarioCache");
    if (cache) {
      try {
        const dados = JSON.parse(cache);
        // Só aplica se o cache bater com o uid do usuário logado
        if (dados.uid && dados.uid !== user.uid) return;

        setUsuarioPerfil((prev) => ({ ...prev, ...dados }));
        setBio(dados.bio || "");
        setLocalizacao(dados.localizacao || "");
        setFotoPerfil(dados.fotoPerfil || "");
        setBanner(dados.banner || null);
      } catch {
        localStorage.removeItem("usuarioCache");
      }
    }
  }, [isOwnProfile, user]);

  // =========================
  // 🔥 FIRESTORE REALTIME
  // =========================
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

        // Atualiza o cache apenas se for o próprio perfil
        if (!id || id === user?.uid) {
          localStorage.setItem(
            "usuarioCache",
            JSON.stringify({ uid: docSnap.id, ...data })
          );
        }
      }
    });

    return unsubscribe;
  }, [id, user]);

  // 🔍 VER SE SEGUE
  useEffect(() => {
    if (!user || !usuarioPerfil) return;
    const seguidores = usuarioPerfil.seguidores || [];
    setIsFollowing(seguidores.includes(user.uid));
  }, [user, usuarioPerfil]);

  // ➕ SEGUIR
  const seguir = async () => {
    if (!user || !usuarioPerfil) return;

    await updateDoc(doc(db, "usuarios", user.uid), {
      seguindo: arrayUnion(usuarioPerfil.id),
    });
    await updateDoc(doc(db, "usuarios", usuarioPerfil.id), {
      seguidores: arrayUnion(user.uid),
    });
    await addDoc(collection(db, "notificacoes"), {
      tipo: "seguindo",
      de: user.displayName || "Pescador",
      para: usuarioPerfil.id,
      createdAt: serverTimestamp(),
    });
  };

  // ➖ DEIXAR DE SEGUIR
  const deixarDeSeguir = async () => {
    if (!user || !usuarioPerfil) return;

    await updateDoc(doc(db, "usuarios", user.uid), {
      seguindo: arrayRemove(usuarioPerfil.id),
    });
    await updateDoc(doc(db, "usuarios", usuarioPerfil.id), {
      seguidores: arrayRemove(user.uid),
    });
  };

  // 💬 CHAT
  const gerarChatId = (id1, id2) => [id1, id2].sort().join("_");

  const irParaChat = async () => {
    const chatId = gerarChatId(user.uid, usuarioPerfil.id);
    const chatRef = doc(db, "chats", chatId);
    const chatSnap = await getDoc(chatRef);
    if (!chatSnap.exists()) {
      await setDoc(chatRef, { participantes: [user.uid, usuarioPerfil.id] });
    }
    navigate(`/chat/${chatId}`);
  };

  // 💾 SALVAR POSTS
  const salvarPosts = async (novosPosts) => {
    if (!usuarioPerfil?.id) return;
    await updateDoc(doc(db, "usuarios", usuarioPerfil.id), { posts: novosPosts });
  };

  // 🖼️ FOTO DE PERFIL
  const handleFotoChange = async (file) => {
    if (!isOwnProfile || !usuarioPerfil?.id) return;
    const reader = new FileReader();
    reader.onload = async () => {
      try {
        await updateDoc(doc(db, "usuarios", usuarioPerfil.id), {
          fotoPerfil: reader.result,
        });
      } catch (error) {
        console.error("Erro ao atualizar foto de perfil:", error);
        alert("Não foi possível atualizar a foto. Tente novamente.");
      }
    };
    reader.readAsDataURL(file);
  };

  // 🌄 BANNER
  const handleBannerChange = async (file) => {
    if (!isOwnProfile || !usuarioPerfil?.id) return;
    const reader = new FileReader();
    reader.onload = async () => {
      try {
        await updateDoc(doc(db, "usuarios", usuarioPerfil.id), {
          banner: reader.result,
        });
      } catch (error) {
        console.error("Erro ao atualizar banner:", error);
        alert("Não foi possível atualizar a capa. Tente novamente.");
      }
    };
    reader.readAsDataURL(file);
  };

  
  //  Novo handle para publicação de post, agora com prompts para comentário e local
const handlePostChange = (e) => {
  const file = e.target.files[0];
  if (!file) return;

  let comentario = prompt("Descrição:");
  if (comentario === null) return;

  let localPost = prompt("Local:");
  if (localPost === null) return;

  const reader = new FileReader();
  reader.onload = () => {
    const novoPost = {
      id:        Date.now(),
      // ← campos necessários para o feed da home
      autorId:   user.uid,
      autorNome: usuarioPerfil?.nome || usuarioPerfil?.displayName || user.displayName || "Pescador",
      autorFoto: usuarioPerfil?.fotoPerfil || user.photoURL || "",
      // ← conteúdo
      imagem:    reader.result,
      data:      new Date().toLocaleString("pt-BR"),
      comentario: comentario.trim() || "Sem descrição",
      local:     localPost.trim(),
      curtidas:  [],
      comentarios: [],
    };
    salvarPosts([novoPost, ...posts]);
  };
  reader.readAsDataURL(file);
  e.target.value = "";
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
            isFollowing={isFollowing}
            onSeguir={seguir}
            onDeixarDeSeguir={deixarDeSeguir}
            onMensagem={irParaChat}
          />

          <EstatisticasPerfil
            totalPosts={posts.length}
            usuario={usuarioPerfil}
          />

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
              navigate={navigate}
            />
          )}
        </div>
      </div>
    </Layout>
  );
}
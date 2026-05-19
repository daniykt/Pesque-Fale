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
  query,
  where,
  getDocs,
  deleteDoc,
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
  const [carregando, setCarregando] = useState(true);

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

  // ⚡ CACHE + SKELETON
  useEffect(() => {
    const targetId = id || user?.uid;
    if (!targetId) return;

    const cacheKey = `perfilCache_${targetId}`;
    const cacheRaw = localStorage.getItem(cacheKey);
    if (cacheRaw && cacheRaw.includes("data:image")) {
      localStorage.removeItem(cacheKey);
    }

    const cache = localStorage.getItem(cacheKey);
    if (cache) {
      try {
        const dados = JSON.parse(cache);
        setUsuarioPerfil((prev) => ({ ...prev, ...dados }));
        setBio(dados.bio || "");
        setLocalizacao(dados.localizacao || "");
        setFotoPerfil(dados.fotoPerfil || "");
        setBanner(dados.banner || null);
        setPosts(dados.posts || []);
        setCarregando(false);
        return;
      } catch {
        localStorage.removeItem(cacheKey);
      }
    }

    setCarregando(true);
    setUsuarioPerfil(null);
    setFotoPerfil("");
    setBanner(null);
    setBio("");
    setLocalizacao("");
    setPosts([]);
    setIsFollowing(false);
  }, [id, user?.uid]);

  // 🔥 FIRESTORE REALTIME
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
        setCarregando(false);

        // Deriva isFollowing direto do snapshot — sem flash
        if (user && docSnap.id !== user.uid) {
          const seguidores = data.seguidores || [];
          setIsFollowing(seguidores.includes(user.uid));
        }

        // ⚠️ Não cachear campos binários (base64) para não estourar o localStorage (~5MB).
        // Cache serve apenas para dados textuais: nome, bio, contadores etc.
        // Imagens sempre virão do Firestore em tempo real.
        const { fotoPerfil: _fp, banner: _bn, posts: postsRaw, ...dadosLeves } = data;
        const postsSemImagem = (postsRaw || []).map(({ imagem: _img, ...resto }) => resto);
        try {
          localStorage.setItem(
            `perfilCache_${docSnap.id}`,
            JSON.stringify({ uid: docSnap.id, ...dadosLeves, posts: postsSemImagem })
          );
        } catch (quotaError) {
          // Se mesmo assim estourar (muitos perfis em cache), limpa e ignora silenciosamente
          console.warn("Cache de perfil ignorado por quota:", quotaError.message);
          localStorage.removeItem(`perfilCache_${docSnap.id}`);
        }
      }
    });
    return unsubscribe;
  }, [id, user]);

  // ⭐ Chat liberado se A segue B OU B segue A
  const chatLiberado = (() => {
    if (!user || !usuarioPerfil || isOwnProfile) return false;
    const bSegueA = (usuarioPerfil.seguidores || []).includes(user.uid);
    return isFollowing || bSegueA;
  })();

  // ── SEGUIR (direto, sem solicitação) ──
  const seguir = async () => {
    if (!user || !usuarioPerfil) return;

    // Adiciona B nos seguidores de A imediatamente
    await updateDoc(doc(db, "usuarios", user.uid), {
      seguindo: arrayUnion(usuarioPerfil.id),
    });
    // Adiciona A nos seguidores do perfil B
    await updateDoc(doc(db, "usuarios", usuarioPerfil.id), {
      seguidores: arrayUnion(user.uid),
    });
    // Notifica B — tipo "seguindo", com botão de seguir de volta
    await addDoc(collection(db, "notificacoes"), {
      tipo: "seguindo",
      de: user.displayName || "Pescador",
      de_id: user.uid,
      para: usuarioPerfil.id,
      lida: false,
      createdAt: serverTimestamp(),
    });
  };

  // ── DEIXAR DE SEGUIR ──
  const deixarDeSeguir = async () => {
    if (!user || !usuarioPerfil) return;

    await updateDoc(doc(db, "usuarios", user.uid), {
      seguindo: arrayRemove(usuarioPerfil.id),
    });
    await updateDoc(doc(db, "usuarios", usuarioPerfil.id), {
      seguidores: arrayRemove(user.uid),
    });
    // Remove notificação de "seguindo" que A enviou para B, se existir
    const q = query(
      collection(db, "notificacoes"),
      where("tipo", "==", "seguindo"),
      where("de_id", "==", user.uid),
      where("para", "==", usuarioPerfil.id)
    );
    const snap = await getDocs(q);
    await Promise.all(snap.docs.map((d) => deleteDoc(d.ref)));

    setIsFollowing(false);
  };

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

  const salvarPosts = async (novosPosts) => {
    if (!usuarioPerfil?.id) return;
    await updateDoc(doc(db, "usuarios", usuarioPerfil.id), { posts: novosPosts });
  };

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

  const handlePostChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    let comentario = prompt("Descrição:");
    if (comentario === null) return;
    let local = prompt("Local:");
    if (local === null) return;
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
    e.target.value = "";
  };

  if (carregando) {
    return (
      <Layout>
        <div className="container2">
          <div className="perfil perfil-skeleton">
            <div className="sk sk-banner" />
            <div className="sk-inferior">
              <div className="sk sk-avatar" />
              <div className="sk-botoes">
                <div className="sk sk-btn" />
                <div className="sk sk-btn" />
              </div>
            </div>
            <div className="sk-info">
              <div className="sk sk-nome" />
              <div className="sk sk-linha" />
              <div className="sk sk-linha sk-linha--curta" />
            </div>
            <div className="sk-stats">
              <div className="sk sk-stat" />
              <div className="sk sk-stat" />
              <div className="sk sk-stat" />
            </div>
            <div className="sk-grid">
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="sk sk-grid-item" />
              ))}
            </div>
          </div>
        </div>
      </Layout>
    );
  }

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
            chatLiberado={chatLiberado}
            onSeguir={seguir}
            onDeixarDeSeguir={deixarDeSeguir}
            onMensagem={irParaChat}
            currentUserId={user?.uid}
          />

          <EstatisticasPerfil
            totalPosts={posts.length}
            usuario={usuarioPerfil}
            currentUserId={user?.uid}
            isOwnProfile={isOwnProfile}
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

          {abaSelecionada === "Equipamentos" && (
            <div className="aba-em-breve">
              <span className="material-symbols-outlined">construction</span>
              <p>Equipamentos</p>
              <span>Recursos para gerenciar seus equipamentos de pesca estarão aqui.</span>
            </div>
          )}

          {abaSelecionada === "Locais Salvos" && (
            <div className="aba-em-breve">
              <span className="material-symbols-outlined">bookmark</span>
              <p>Locais Salvos</p>
              <span>Seus pontos de pesca favoritos aparecerão nesta seção.</span>
            </div>
          )}
        </div>
      </div>
    </Layout>
  );
}
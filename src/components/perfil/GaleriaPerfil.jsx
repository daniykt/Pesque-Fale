import React, { useState } from "react";
import "./Galeriaperfil.css";

export default function GaleriaPerfil({
  posts,
  user,
  usuarioPerfil,
  salvarPosts,
}) {
  const [postSelecionado, setPostSelecionado] = useState(null);

  const abrirPost = (post) => setPostSelecionado(post);
  const fecharPost = () => setPostSelecionado(null);

  // 🔥 GARANTE ARRAY (resolve seu erro)
  const getCurtidasArray = (curtidas) => {
    if (Array.isArray(curtidas)) return curtidas;
    if (typeof curtidas === "number") return []; // converte antigo
    return [];
  };

  // 👍 CURTIR (COM CORREÇÃO COMPLETA)
  const handleCurtir = (post) => {
    if (!user) return alert("Faça login");

    const novosPosts = posts.map((p) => {
      if (p.id !== post.id) return p;

      const curtidasArray = getCurtidasArray(p.curtidas);
      const jaCurtiu = curtidasArray.includes(user.uid);

      return {
        ...p,
        curtidas: jaCurtiu
          ? curtidasArray.filter((id) => id !== user.uid)
          : [...curtidasArray, user.uid],
      };
    });

    salvarPosts(novosPosts);

    // Atualiza modal sem bug
    const atualizado = novosPosts.find((p) => p.id === post.id);
    setPostSelecionado(atualizado);
  };

  // 💬 COMENTAR (COM USUÁRIO)
  const handleComentar = (post) => {
    if (!user) return alert("Faça login");

    const texto = prompt("Digite seu comentário:");
    if (!texto) return;

    const novoComentario = {
      texto,
      userId: user.uid,
      nome: user.displayName || "Usuário",
      data: new Date().toLocaleString(),
    };

    const novosPosts = posts.map((p) =>
      p.id === post.id
        ? {
            ...p,
            comentarios: [...(p.comentarios || []), novoComentario],
          }
        : p
    );

    salvarPosts(novosPosts);

    const atualizado = novosPosts.find((p) => p.id === post.id);
    setPostSelecionado(atualizado);
  };

  // 🗑️ DELETAR (SÓ DONO)
  const handleDeletar = (post) => {
    if (user?.uid !== usuarioPerfil?.id) return;

    if (!window.confirm("Tem certeza que deseja excluir este post?")) return;

    const novosPosts = posts.filter((p) => p.id !== post.id);

    salvarPosts(novosPosts);
    fecharPost();
  };

  // 📊 CONTADOR SEGURO
  const contarCurtidas = (post) => {
    return Array.isArray(post.curtidas)
      ? post.curtidas.length
      : post.curtidas || 0;
  };

  if (!posts.length) {
    return (
      <div className="galeria-vazia">
        <span className="material-symbols-outlined galeria-vazia-icone">
          photo_camera
        </span>
        <p>Nenhuma publicação ainda.</p>
        <span>Clique em "Nova Publicação" para começar!</span>
      </div>
    );
  }

  return (
    <>
      {/* GRID */}
      <div className="galeria-grid">
        {posts.map((post) => (
          <div
            key={post.id}
            className="galeria-item"
            onClick={() => abrirPost(post)}
          >
            <img src={post.imagem} alt={post.local} className="galeria-foto" />

            <div className="galeria-overlay">
              <span className="galeria-overlay-info">
                👍 {contarCurtidas(post)}
              </span>
              <span className="galeria-overlay-info">
                💬 {post.comentarios?.length || 0}
              </span>
            </div>
          </div>
        ))}
      </div>

      {/* MODAL */}
      {postSelecionado && (
        <div className="galeria-modal-fundo" onClick={fecharPost}>
          <div
            className="galeria-modal"
            onClick={(e) => e.stopPropagation()}
          >
            {/* FECHAR */}
            <button className="galeria-modal-fechar" onClick={fecharPost}>
              <span className="material-symbols-outlined">close</span>
            </button>

            {/* IMAGEM */}
            <img
              src={postSelecionado.imagem}
              alt={postSelecionado.local}
              className="galeria-modal-foto"
            />

            {/* INFO */}
            <div className="galeria-modal-info">
              <p className="galeria-modal-data">
                {postSelecionado.data}
              </p>
              <p className="galeria-modal-local">
                {postSelecionado.local}
              </p>
              <p className="galeria-modal-comentario">
                {postSelecionado.comentario}
              </p>

              {/* AÇÕES */}
              <div className="galeria-modal-acoes">
                <button
                  className="btn-interacao"
                  onClick={() => handleCurtir(postSelecionado)}
                >
                  👍 {contarCurtidas(postSelecionado)}
                </button>

                <button
                  className="btn-interacao"
                  onClick={() => handleComentar(postSelecionado)}
                >
                  💬 {postSelecionado.comentarios?.length || 0}
                </button>

                {user?.uid === usuarioPerfil?.id && (
                  <button
                    className="btn-interacao btn-deletar"
                    onClick={() => handleDeletar(postSelecionado)}
                  >
                    🗑️ Excluir
                  </button>
                )}
              </div>

              {/* COMENTÁRIOS */}
              {postSelecionado.comentarios?.length > 0 && (
                <div className="galeria-modal-comentarios">
                  {postSelecionado.comentarios.map((c, i) => (
                    <p key={i}>
                      💬 <strong>{c.nome || "Usuário"}</strong>:{" "}
                      {c.texto || c}
                    </p>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
}
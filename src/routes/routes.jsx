import { BrowserRouter, Routes, Route } from "react-router-dom";
import { useEffect, useState } from "react";

import { observeAuthState } from "../auth";
import ProtectedRoute from "./ProtectedRoute";

import Index from "../pages/Index/Index";
import Login from "../pages/Login/login";
import Home from "../pages/Home/Home";
import Perfil from "../pages/Perfil/perfil";
import EditarPerfil from "../pages/Perfil/EditarPerfil/editarPerfil";
import NovaPublicacao from "../pages/NovaPublicacao/novapublicacao";
import VisualizacaoPost from "../pages/VisualizacaoPost/VisualizacaoPost";
import Pesquisa from "../pages/Pesquisa/pesquisa";
import Notificacao from "../pages/Notificacao/notificacao";
import Chat from "../pages/chat/Chat";
import Sobre from "../pages/Sobre/sobre";

function AppRoutes() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = observeAuthState((currentUser) => {
      setUser(currentUser);
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  if (loading) return <h1>Carregando...</h1>;

  return (
    <BrowserRouter>
      <Routes>

        <Route path="/" element={<Index />} />
        <Route path="/login" element={<Login />} />

        {/* 🔒 ROTAS PROTEGIDAS */}

        <Route
          path="/home"
          element={
            <ProtectedRoute user={user}>
              <Home />
            </ProtectedRoute>
          }
        />

        <Route
          path="/perfil/:id"
          element={
            <ProtectedRoute user={user}>
              <Perfil />
            </ProtectedRoute>
          }
        />

        <Route
          path="/perfil"
          element={
            <ProtectedRoute user={user}>
              <Perfil />
            </ProtectedRoute>
          }
        />

        <Route
          path="/perfil/editar"
          element={
            <ProtectedRoute user={user}>
              <EditarPerfil />
            </ProtectedRoute>
          }
        />

        <Route
          path="/publicar"
          element={
            <ProtectedRoute user={user}>
              <NovaPublicacao />
            </ProtectedRoute>
          }
        />

        <Route
          path="/post/:userId/:postId"
          element={
            <ProtectedRoute user={user}>
              <VisualizacaoPost />
            </ProtectedRoute>
          }
        />

        <Route
          path="/pesquisar"
          element={
            <ProtectedRoute user={user}>
              <Pesquisa />
            </ProtectedRoute>
          }
        />

        <Route
          path="/notificacao"
          element={
            <ProtectedRoute user={user}>
              <Notificacao />
            </ProtectedRoute>
          }
        />

        {/* ✅ INBOX */}
        <Route
          path="/chat"
          element={
            <ProtectedRoute user={user}>
              <Chat />
            </ProtectedRoute>
          }
        />

        {/* ✅ CHAT PRIVADO */}
        <Route
          path="/chat/:chatId"
          element={
            <ProtectedRoute user={user}>
              <Chat />
            </ProtectedRoute>
          }
        />

        <Route
          path="/sobre"
          element={
            <ProtectedRoute user={user}>
              <Sobre />
            </ProtectedRoute>
          }
        />

      </Routes>
    </BrowserRouter>
  );
}

export default AppRoutes;
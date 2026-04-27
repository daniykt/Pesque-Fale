import { BrowserRouter, Routes, Route } from "react-router-dom";
import { useEffect, useState } from "react";

import { observeAuthState } from "../auth";
import ProtectedRoute from "./ProtectedRoute";

import Index from "../pages/Index/Index";
import Login from "../pages/Login/login";
import Onboarding from "../pages/Onboarding/Onboarding";
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
  const [loading, setLoading] = useState(true); // ← começa true

  useEffect(() => {
    const unsubscribe = observeAuthState((currentUser) => {
      setUser(currentUser);
      setLoading(false); // ← só para de carregar quando Firebase responde
    });

    return unsubscribe;
  }, []);

  // Não renderiza nada até saber o estado do auth
  if (loading) return null;

  return (
    <BrowserRouter>
      <Routes>

        <Route path="/" element={<Index />} />
        <Route path="/login" element={<Login />} />

        {/* ✅ ONBOARDING — sem ProtectedRoute, o componente valida internamente */}
        <Route path="/onboarding" element={<Onboarding />} />

        {/* 🔒 ROTAS PROTEGIDAS */}
        <Route
          path="/home"
          element={
            <ProtectedRoute user={user} loading={loading}>
              <Home />
            </ProtectedRoute>
          }
        />

        <Route
          path="/perfil/:id"
          element={
            <ProtectedRoute user={user} loading={loading}>
              <Perfil />
            </ProtectedRoute>
          }
        />

        <Route
          path="/perfil"
          element={
            <ProtectedRoute user={user} loading={loading}>
              <Perfil />
            </ProtectedRoute>
          }
        />

        <Route
          path="/perfil/editar"
          element={
            <ProtectedRoute user={user} loading={loading}>
              <EditarPerfil />
            </ProtectedRoute>
          }
        />

        <Route
          path="/publicar"
          element={
            <ProtectedRoute user={user} loading={loading}>
              <NovaPublicacao />
            </ProtectedRoute>
          }
        />

        <Route
          path="/post/:userId/:postId"
          element={
            <ProtectedRoute user={user} loading={loading}>
              <VisualizacaoPost />
            </ProtectedRoute>
          }
        />

        <Route
          path="/pesquisar"
          element={
            <ProtectedRoute user={user} loading={loading}>
              <Pesquisa />
            </ProtectedRoute>
          }
        />

        <Route
          path="/notificacao"
          element={
            <ProtectedRoute user={user} loading={loading}>
              <Notificacao />
            </ProtectedRoute>
          }
        />

        <Route
          path="/chat"
          element={
            <ProtectedRoute user={user} loading={loading}>
              <Chat />
            </ProtectedRoute>
          }
        />

        <Route
          path="/chat/:chatId"
          element={
            <ProtectedRoute user={user} loading={loading}>
              <Chat />
            </ProtectedRoute>
          }
        />

        <Route
          path="/sobre"
          element={
            <ProtectedRoute user={user} loading={loading}>
              <Sobre />
            </ProtectedRoute>
          }
        />

      </Routes>
    </BrowserRouter>
  );
}

export default AppRoutes;
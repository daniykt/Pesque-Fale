import { BrowserRouter, Routes, Route } from "react-router-dom"

import Index from "../pages/Index/Index"
import Login from "../pages/Login/login"
import Home from "../pages/Home/Home"
import Perfil from "../pages/Perfil/perfil"
import Pesquisa from "../pages/Pesquisa/pesquisa"
import Notificacao from "../pages/Notificacao/notificacao"
import LocaisAvaliados from "../pages/locaisAvaliados/locaisAvaliados"
import Sobre from "../pages/Sobre/sobre"

function AppRoutes() {
  return (
    <BrowserRouter>
      <Routes>

        <Route path="/" element={<Index />} />

        <Route path="/login" element={<Login />} />

        <Route path="/home" element={<Home />} />

        <Route path="/perfil" element={<Perfil />} />

        <Route path="/pesquisa" element={<Pesquisa />} />

        <Route path="/notificacao" element={<Notificacao />} />

        <Route path="/locais" element={<LocaisAvaliados />} />

        <Route path="/sobre" element={<Sobre />} />

      </Routes>
    </BrowserRouter>
  )
}

export default AppRoutes
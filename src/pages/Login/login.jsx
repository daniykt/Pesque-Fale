import React, { useEffect, useState } from "react";
import "../../styles/base.css";
import "../../styles/global.css";
import "./login.css";

import { loginWithEmail, registerWithEmail, logout } from "../../auth";
import { useNavigate } from "react-router-dom";

import logo1 from "../../assets/image/login/logo1.png";
import logo2 from "../../assets/image/login/logo2.png";
import flat from "../../assets/image/login/flat.png";

export default function Login() {
  const navigate = useNavigate();

  const [isRegisterActive, setIsRegisterActive] = useState(false);
  const [showLoginPassword, setShowLoginPassword] = useState(false);
  const [showRegisterPassword, setShowRegisterPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const [toast, setToast] = useState({ visible: false, message: "", type: "info" });

  const [loginData, setLoginData] = useState({ email: "", password: "" });
  const [registerData, setRegisterData] = useState({
    email: "",
    password: "",
    confirmPassword: "",
  });

  const showToast = (message, type = "info") => {
    setToast({ visible: true, message, type });
  };

  const hideToast = () => setToast((t) => ({ ...t, visible: false }));

  useEffect(() => {
    if (toast.visible) {
      const timer = setTimeout(hideToast, 4000);
      return () => clearTimeout(timer);
    }
  }, [toast.visible]);

  const TOAST_ICONS = {
    success: "check_circle",
    error: "error",
    info: "info",
  };

  // 🔐 LOGIN
  const handleLogin = async (e) => {
    e.preventDefault();
    try {
      await loginWithEmail(loginData.email, loginData.password);
      showToast("Login realizado com sucesso!", "success");
      navigate("/home");
    } catch (error) {
      console.error(error);
      showToast("E-mail ou senha incorretos. Tente novamente.", "error");
    }
  };

  // 🆕 CADASTRO
  const handleRegister = async (e) => {
    e.preventDefault();

    if (registerData.password !== registerData.confirmPassword) {
      showToast("As senhas não coincidem. Verifique e tente novamente.", "error");
      return;
    }

    if (registerData.password.length < 6) {
      showToast("A senha deve ter pelo menos 6 caracteres.", "error");
      return;
    }

    try {
      await registerWithEmail(registerData.email, registerData.password);
      await logout();
      showToast("Conta criada com sucesso! Faça login para continuar.", "success");
      setIsRegisterActive(false);
    } catch (error) {
      console.error(error);
      const msg =
        error?.code === "auth/email-already-in-use"
          ? "Este e-mail já está cadastrado."
          : "Não foi possível criar a conta. Tente novamente.";
      showToast(msg, "error");
    }
  };

  return (
    <div className="login-page-container">

      {/* TOAST */}
      {toast.visible && (
        <div className={`site-toast show ${toast.type}`}>
          <div className="toast-content">
            <span className="material-symbols-outlined toast-icon">
              {TOAST_ICONS[toast.type]}
            </span>
            <div className="toast-message">{toast.message}</div>
          </div>
          <button className="toast-close-btn" onClick={hideToast}>
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>
      )}

      <div className={`wrapper ${isRegisterActive ? "active" : ""}`}>

        <aside className="side-image">
          <img src={flat} alt="Imagem lateral profissional" />
        </aside>

        <div className="auth-area">

          {/* LOGIN */}
          <div className={`form-box login ${isRegisterActive ? "hidden" : "visible"}`}>
            <div className="logo">
              <img src={logo1} alt="Logo" />
              <img src={logo2} alt="Logo" />
            </div>
            <h2>ENTRAR</h2>
            <form onSubmit={handleLogin}>
              <div className="input-box">
                <span className="material-symbols-outlined icon">alternate_email</span>
                <input
                  type="email"
                  required
                  placeholder=" "
                  value={loginData.email}
                  onChange={(e) => setLoginData({ ...loginData, email: e.target.value })}
                />
                <label>Email</label>
              </div>
              <div className="input-box">
                <span className="material-symbols-outlined icon">password</span>
                <input
                  type={showLoginPassword ? "text" : "password"}
                  required
                  placeholder=" "
                  value={loginData.password}
                  onChange={(e) => setLoginData({ ...loginData, password: e.target.value })}
                />
                <label>Senha</label>
                <span
                  className="material-symbols-outlined toggle-password"
                  onClick={() => setShowLoginPassword(!showLoginPassword)}
                >
                  {showLoginPassword ? "visibility_off" : "visibility"}
                </span>
              </div>
              <button type="submit" className="btn">ENTRAR</button>
              <div className="login-register">
                <p>
                  Não tem conta?
                  <button type="button" className="register-link" onClick={() => setIsRegisterActive(true)}>
                    Cadastre-se
                  </button>
                </p>
              </div>
            </form>
          </div>

          {/* REGISTER */}
          <div className={`form-box register ${isRegisterActive ? "visible" : "hidden"}`}>
            <div className="logo">
              <img src={logo1} alt="Logo" />
              <img src={logo2} alt="Logo" />
            </div>
            <h2>CADASTRO</h2>
            <form onSubmit={handleRegister}>
              <div className="input-box">
                <input
                  type="email"
                  required
                  placeholder=" "
                  value={registerData.email}
                  onChange={(e) => setRegisterData({ ...registerData, email: e.target.value })}
                />
                <label>Email</label>
              </div>
              <div className="input-box">
                <input
                  type={showRegisterPassword ? "text" : "password"}
                  required
                  placeholder=" "
                  value={registerData.password}
                  onChange={(e) => setRegisterData({ ...registerData, password: e.target.value })}
                />
                <label>Senha</label>
                <span
                  className="material-symbols-outlined toggle-password"
                  onClick={() => setShowRegisterPassword(!showRegisterPassword)}
                >
                  {showRegisterPassword ? "visibility_off" : "visibility"}
                </span>
              </div>
              <div className="input-box">
                <input
                  type={showConfirmPassword ? "text" : "password"}
                  required
                  placeholder=" "
                  value={registerData.confirmPassword}
                  onChange={(e) => setRegisterData({ ...registerData, confirmPassword: e.target.value })}
                />
                <label>Confirmar Senha</label>
                <span
                  className="material-symbols-outlined toggle-password"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                >
                  {showConfirmPassword ? "visibility_off" : "visibility"}
                </span>
              </div>
              <button type="submit" className="btn">CADASTRAR</button>
              <div className="login-register">
                <p>
                  Já tem conta?
                  <button type="button" className="login-link" onClick={() => setIsRegisterActive(false)}>
                    Entrar
                  </button>
                </p>
              </div>
            </form>
          </div>

        </div>
      </div>
    </div>
  );
}
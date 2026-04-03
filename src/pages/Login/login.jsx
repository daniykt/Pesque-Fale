import React, { useEffect, useState } from "react";
import "../../styles/base.css";
import "../../styles/global.css";
import "./login.css";
import "./toast.css";

import { loginWithEmail, registerWithEmail, logout } from "../../auth";
import { useNavigate } from "react-router-dom";

// IMAGENS
import logo1 from "../../assets/image/login/logo1.png";
import logo2 from "../../assets/image/login/logo2.png";
import flat from "../../assets/image/login/flat.png";

export default function Login() {
  const navigate = useNavigate();

  const [isRegisterActive, setIsRegisterActive] = useState(false);
  const [showLoginPassword, setShowLoginPassword] = useState(false);
  const [showRegisterPassword, setShowRegisterPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const [showToast, setShowToast] = useState(false);
  const [toastMessage, setToastMessage] = useState("");

  const [loginData, setLoginData] = useState({ email: "", password: "" });

  const [registerData, setRegisterData] = useState({
    email: "",
    password: "",
    confirmPassword: "",
  });


  useEffect(() => {
    if (showToast) {
      const timer = setTimeout(() => setShowToast(false), 4000);
      return () => clearTimeout(timer);
    }
  }, [showToast]);

  // 🔐 LOGIN
  const handleLogin = async (e) => {
    e.preventDefault();

    try {
      await loginWithEmail(loginData.email, loginData.password);

      setToastMessage("Login realizado com sucesso!");
      setShowToast(true);

      navigate("/home");
    } catch (error) {
      console.error(error);
      setToastMessage("Erro ao fazer login");
      setShowToast(true);
    }
  };

  // 🆕 CADASTRO
  const handleRegister = async (e) => {
    e.preventDefault();

    if (registerData.password !== registerData.confirmPassword) {
      setToastMessage("As senhas não coincidem");
      setShowToast(true);
      return;
    }

    try {
      await registerWithEmail(
        registerData.email,
        registerData.password
      );

      // 🔥 LOGOUT PRA NÃO ENTRAR AUTOMATICAMENTE
      await logout();

      setToastMessage("Cadastro realizado com sucesso!");
      setShowToast(true);

      // 🔥 VOLTA PRA TELA DE LOGIN
      setIsRegisterActive(false);

    } catch (error) {
      console.error(error);
      setToastMessage("Erro ao cadastrar");
      setShowToast(true);
    }
  };

  return (
    <div className="login-page-container">

      {/* TOAST */}
      {showToast && (
        <div className="site-toast show">
          <div className="toast-content">
            <span className="material-symbols-outlined toast-icon">
              check_circle
            </span>
            <div className="toast-message">
              {toastMessage}
            </div>
          </div>
          <button className="toast-close-btn" onClick={() => setShowToast(false)}>
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
                  onChange={(e) =>
                    setLoginData({ ...loginData, email: e.target.value })
                  }
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
                  onChange={(e) =>
                    setLoginData({ ...loginData, password: e.target.value })
                  }
                />
                <label>Senha</label>
                <span
                  className="material-symbols-outlined toggle-password"
                  onClick={() => setShowLoginPassword(!showLoginPassword)}
                >
                  {showLoginPassword ? "visibility_off" : "visibility"}
                </span>
              </div>

              <button
                type="submit"
                className="btn"
              >
                ENTRAR
              </button>

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
                  onChange={(e) =>
                    setRegisterData({ ...registerData, email: e.target.value })
                  }
                />
                <label>Email</label>
              </div>

              <div className="input-box">
                <input
                  type={showRegisterPassword ? "text" : "password"}
                  required
                  placeholder=" "
                  value={registerData.password}
                  onChange={(e) =>
                    setRegisterData({ ...registerData, password: e.target.value })
                  }
                />
                <label>Senha</label>
              </div>

              <div className="input-box">
                <input
                  type={showConfirmPassword ? "text" : "password"}
                  required
                  placeholder=" "
                  value={registerData.confirmPassword}
                  onChange={(e) =>
                    setRegisterData({
                      ...registerData,
                      confirmPassword: e.target.value,
                    })
                  }
                />
                <label>Confirmar Senha</label>
              </div>

              <button
                type="submit"
                className="btn"
              >
                CADASTRAR
              </button>

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
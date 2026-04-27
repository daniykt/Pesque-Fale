import React, { useEffect, useState } from "react";
import "../../styles/base.css";
import "../../styles/global.css";
import "./login.css";
// Importe também o CSS do toast (se necessário, ou coloque os estilos do spinner aqui)
import "./toast.css";

import { loginWithEmail, registerWithEmail, logout, updateUserName, verificarOnboarding } from "../../auth";
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
  const [justRegistered, setJustRegistered] = useState(false);
  const [toast, setToast] = useState({ visible: false, message: "", type: "info" });
  const [isRegistering, setIsRegistering] = useState(false); // estado do loading

  const [loginData, setLoginData] = useState({ email: "", password: "" });

  const [registerData, setRegisterData] = useState({
    name: "",
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

  useEffect(() => {
    const msg = sessionStorage.getItem("mensagemLogin");
    if (msg) {
      showToast(msg, "success");
      sessionStorage.removeItem("mensagemLogin");
    }
  }, []);

  // LOGIN
  const handleLogin = async (e) => {
    e.preventDefault();
    try {
      const userCredential = await loginWithEmail(loginData.email, loginData.password);
      const uid = userCredential.user.uid;

      const onboardingFeito = await verificarOnboarding(uid);

      if (onboardingFeito) {
        navigate("/home");
      } else {
        navigate("/onboarding");
      }
    } catch (error) {
      showToast("E-mail ou senha incorretos.", "error");
    }
  };

  // CADASTRO – loading no botão
  const handleRegister = async (e) => {
    e.preventDefault();

    if (registerData.password !== registerData.confirmPassword) {
      return showToast("As senhas não coincidem.", "error");
    }

    if (registerData.password.length < 6) {
      return showToast("A senha deve ter pelo menos 6 caracteres.", "error");
    }

    setIsRegistering(true); // ativa o loading no botão

    try {
      await registerWithEmail(registerData.email, registerData.password, registerData.name);
      await updateUserName(registerData.name);

      // Redireciona imediatamente após o cadastro (loading já no botão)
      navigate("/onboarding");
    } catch (error) {
      showToast("Erro ao criar conta.", "error");
      setIsRegistering(false); // libera o botão em caso de erro
    }
  };

  return (
    <>
      <div className="login-page-container">

        {toast.visible && (
          <div className={`site-toast show ${toast.type}`}>
            <div className="toast-content">
              <div className="toast-message">{toast.message}</div>
            </div>
            <button className="toast-close-btn" onClick={hideToast}>X</button>
          </div>
        )}

        <div className={`wrapper ${isRegisterActive ? "active" : ""}`}>

          <aside className="side-image">
            <img src={flat} alt="Imagem lateral" />
          </aside>

          <div className="auth-area">

            {/* LOGIN */}
            <div className={`form-box login ${isRegisterActive ? "hidden" : "visible"}`}>
              <div className="logo">
                <img src={logo1} alt="" />
                <img src={logo2} alt="" />
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
                    <button
                      type="button"
                      className="register-link"
                      onClick={() => setIsRegisterActive(true)}
                    >
                      Cadastre-se
                    </button>
                  </p>
                </div>
              </form>
            </div>

            {/* CADASTRO */}
            <div className={`form-box register ${isRegisterActive ? "visible" : "hidden"}`}>
              <div className="logo">
                <img src={logo1} alt="" />
                <img src={logo2} alt="" />
              </div>

              <h2>CADASTRO</h2>

              <form onSubmit={handleRegister}>
                <div className="input-box">
                  <span className="material-symbols-outlined icon">person</span>
                  <input
                    type="text"
                    required
                    placeholder=" "
                    value={registerData.name}
                    onChange={(e) => setRegisterData({ ...registerData, name: e.target.value })}
                  />
                  <label>Nome</label>
                </div>

                <div className="input-box">
                  <span className="material-symbols-outlined icon">alternate_email</span>
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
                  <span className="material-symbols-outlined icon">password</span>
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
                  <span className="material-symbols-outlined icon">password</span>
                  <input
                    type={showConfirmPassword ? "text" : "password"}
                    required
                    placeholder=" "
                    value={registerData.confirmPassword}
                    onChange={(e) =>
                      setRegisterData({ ...registerData, confirmPassword: e.target.value })
                    }
                  />
                  <label>Confirmar Senha</label>
                  <span
                    className="material-symbols-outlined toggle-password"
                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  >
                    {showConfirmPassword ? "visibility_off" : "visibility"}
                  </span>
                </div>

                {/* BOTÃO COM SPINNER */}
                <button
                  type="submit"
                  className="btn btn-register"
                  disabled={isRegistering}
                >
                  {isRegistering ? (
                    <>
                      <span className="btn-spinner"></span>
                      Criando conta...
                    </>
                  ) : (
                    "CADASTRAR"
                  )}
                </button>

                <div className="login-register">
                  <p>
                    Já tem conta?
                    <button
                      type="button"
                      className="login-link"
                      onClick={() => setIsRegisterActive(false)}
                    >
                      Entrar
                    </button>
                  </p>
                </div>
              </form>
            </div>

          </div>
        </div>
      </div>
    </>
  );
}
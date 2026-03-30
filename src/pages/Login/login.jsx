import React, { useEffect, useState } from "react";
import "../../styles/base.css";
import "../../styles/global.css";
import "./login.css";
import "./toast.css";

// IMAGENS
import logo1 from "../../assets/image/login/logo1.png";
import logo2 from "../../assets/image/login/logo2.png";
import flat from "../../assets/image/login/flat.png";

export default function Login({ successMessage, errorMessage }) {
  // Estados para controlar o comportamento (Substitui o vanilla JS)
  const [isRegisterActive, setIsRegisterActive] = useState(false);
  const [showLoginPassword, setShowLoginPassword] = useState(false);
  const [showRegisterPassword, setShowRegisterPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  
  // Controle do Toast
  const [showToast, setShowToast] = useState(!!(successMessage || errorMessage));

  // Esconder Toast automaticamente após 10s
  useEffect(() => {
    if (showToast) {
      const timer = setTimeout(() => setShowToast(false), 10000);
      return () => clearTimeout(timer);
    }
  }, [showToast]);

  return (
    // Substituímos o body.login-page por uma div encapsuladora para evitar o Flash/Quebra no reload
    <div className="login-page-container">
      
      {/* TOAST */}
      {showToast && (
        <div 
          className={`site-toast show ${successMessage ? 'success' : 'error'}`} 
          role={successMessage ? 'status' : 'alert'}
        >
          <div className="toast-content">
            <span className="material-symbols-outlined toast-icon">
              {successMessage ? 'check_circle' : 'error'}
            </span>
            <div className="toast-message">{successMessage || errorMessage}</div>
          </div>
          <button className="toast-close-btn" onClick={() => setShowToast(false)}>
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>
      )}

      {/* WRAPPER (Adiciona a classe 'active' dinamicamente se isRegisterActive for true) */}
      <div className={`wrapper ${isRegisterActive ? "active" : ""}`}>
        
        {/* LADO ESQUERDO */}
        <aside className="side-image">
          <img src={flat} alt="Imagem lateral profissional" />
        </aside>

        {/* FORMULÁRIOS */}
        <div className="auth-area">
          
          {/* LOGIN */}
          <div className={`form-box login ${isRegisterActive ? "hidden" : "visible"}`} aria-hidden={isRegisterActive}>
            <div className="logo">
              <img src={logo1} alt="Logo" />
              <img src={logo2} alt="Logo" />
            </div>

            <h2>ENTRA</h2>

            <form>
              <div className="input-box">
                <span className="material-symbols-outlined icon">alternate_email</span>
                <input type="email" required placeholder=" " name="email" />
                <label>Email</label>
                <span className="input-hint">exemplo@gmail.com</span>
              </div>

              <div className="input-box">
                <span className="material-symbols-outlined icon">password</span>
                <input 
                  type={showLoginPassword ? "text" : "password"} 
                  required 
                  placeholder=" " 
                  name="password" 
                />
                <label>Senha</label>
                <span className="input-hint">Entre 6 a 10 caracteres pelo menos</span>
                <span 
                  className="material-symbols-outlined toggle-password"
                  onClick={() => setShowLoginPassword(!showLoginPassword)}
                  style={{ pointerEvents: 'auto' }}
                >
                  {showLoginPassword ? "visibility_off" : "visibility"}
                </span>
              </div>

              <div className="remember-forgot">
                <label>
                  <input type="checkbox" name="rememberMe" />
                  Lembre-se de mim
                </label>
                <a href="#!">Esqueceu sua senha?</a>
              </div>

              <button type="submit" className="btn">ENTRA</button>

              <div className="login-register">
                <p>
                  Não tem conta aqui?
                  <button 
                    type="button" 
                    className="register-link" 
                    style={{background: 'none', border: 'none', color: '#062A6C', fontWeight: 'bold', cursor: 'pointer', fontSize: '1em'}}
                    onClick={() => setIsRegisterActive(true)}
                  >
                    Cadastre-se aqui
                  </button>
                </p>
              </div>
            </form>
          </div>

          {/* CADASTRO */}
          <div className={`form-box register ${isRegisterActive ? "visible" : "hidden"}`} aria-hidden={!isRegisterActive}>
            <div className="logo">
              <img src={logo1} alt="Logo" />
              <img src={logo2} alt="Logo" />
            </div>

            <h2>CADASTRO</h2>

            <form>
              <div className="input-box">
                <span className="material-symbols-outlined icon">person</span>
                <input type="text" required placeholder=" " name="nome" />
                <label>Nome de Usuário</label>
                <span className="input-hint">Sem espaços ou caracteres especiais</span>
              </div>

              <div className="input-box">
                <span className="material-symbols-outlined icon">alternate_email</span>
                <input type="email" required placeholder=" " name="email" />
                <label>Email</label>
                <span className="input-hint">exemplo@gmail.com</span>
              </div>

              <div className="input-box">
                <span className="material-symbols-outlined icon">password</span>
                <input 
                  type={showRegisterPassword ? "text" : "password"} 
                  required 
                  placeholder=" " 
                  name="senha" 
                />
                <label>Senha</label>
                <span className="input-hint">Entre 6 a 10 caracteres</span>
                <span 
                  className="material-symbols-outlined toggle-password"
                  onClick={() => setShowRegisterPassword(!showRegisterPassword)}
                  style={{ pointerEvents: 'auto' }}
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
                  name="confirmar_senha" 
                />
                <label>Confirmar Senha</label>
                <span className="input-hint">Digite a senha novamente</span>
                <span 
                  className="material-symbols-outlined toggle-password"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  style={{ pointerEvents: 'auto' }}
                >
                  {showConfirmPassword ? "visibility_off" : "visibility"}
                </span>
              </div>

              <div className="remember-forgot">
                <label>
                  <input type="checkbox" name="acceptTerms" required />
                  Eu aceito os termos &amp; condições.
                </label>
              </div>

              <button type="submit" className="btn">Cadastrar-se</button>

              <div className="login-register">
                <p>
                  Já tem conta aqui?
                  <button 
                    type="button" 
                    className="login-link" 
                    style={{background: 'none', border: 'none', color: '#062A6C', fontWeight: 'bold', cursor: 'pointer', fontSize: '1em'}}
                    onClick={() => setIsRegisterActive(false)}
                  >
                    Entra
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
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyDdlXERa3udwLzjgOnSZ8VTa_2QXOPf6Ic",
  authDomain: "bdpesquefale.firebaseapp.com",
  projectId: "bdpesquefale",
  storageBucket: "bdpesquefale.firebasestorage.app",
  messagingSenderId: "541866151273",
  appId: "1:541866151273:web:242d6263d2a5ddf35601f8",
  measurementId: "G-C07YGYNYYG"
};

// Inicializa
const app = initializeApp(firebaseConfig);

// 🔐 AUTENTICAÇÃO (ESSENCIAL)
const auth = getAuth(app);

export { app, auth };
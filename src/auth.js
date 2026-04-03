import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signOut,
} from "firebase/auth";
import { auth } from "./firebase";

// 🔐 LOGIN
export const loginWithEmail = (email, password) => {
  return signInWithEmailAndPassword(auth, email, password);
};

// 🆕 CADASTRO
export const registerWithEmail = (email, password) => {
  return createUserWithEmailAndPassword(auth, email, password);
};

// 👀 OBSERVAR USUÁRIO
export const observeAuthState = (callback) => {
  return onAuthStateChanged(auth, callback);
};

// 🚪 LOGOUT
export const logout = () => {
  return signOut(auth);
};
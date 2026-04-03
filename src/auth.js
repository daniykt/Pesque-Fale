import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signOut,
  updateProfile,
} from "firebase/auth";

import { auth } from "./firebase";

// 🔐 LOGIN
export const loginWithEmail = async (email, password) => {
  try {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    return userCredential;
  } catch (error) {
    console.error("Erro no login:", error);
    throw error;
  }
};

// 🆕 CADASTRO
export const registerWithEmail = async (email, password) => {
  try {
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    return userCredential;
  } catch (error) {
    console.error("Erro no cadastro:", error);
    throw error;
  }
};

// 👀 OBSERVAR USUÁRIO (mantém usuário logado)
export const observeAuthState = (callback) => {
  return onAuthStateChanged(auth, callback);
};

// 🧑‍💻 ATUALIZAR NOME DO USUÁRIO
export const updateUserName = async (name) => {
  try {
    if (auth.currentUser) {
      await updateProfile(auth.currentUser, {
        displayName: name,
      });
    }
  } catch (error) {
    console.error("Erro ao atualizar nome:", error);
    throw error;
  }
};

// 🚪 LOGOUT
export const logout = async () => {
  try {
    await signOut(auth);
  } catch (error) {
    console.error("Erro no logout:", error);
    throw error;
  }
};
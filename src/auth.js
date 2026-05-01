import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signOut,
  updateProfile,
} from "firebase/auth";

import { auth } from "./firebase";
import { db } from "./firebase";
import { doc, setDoc, getDoc, serverTimestamp } from "firebase/firestore";

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

// 🆕 CADASTRO — cria documento no Firestore com onboardingConcluido: false
export const registerWithEmail = async (email, password, nome) => {
  try {
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;

    // Cria o documento do usuário no Firestore
    await setDoc(doc(db, "usuarios", user.uid), {
      nome: nome || "",
      email: email,
      fotoPerfil: "",
      banner: null,
      bio: "",
      localizacao: "",
      seguidores: [],
      seguindo: [],
      posts: [],
      onboardingConcluido: false, // ← controla o onboarding
      criadoEm: serverTimestamp(),
    });

    return userCredential;
  } catch (error) {
    console.error("Erro no cadastro:", error);
    throw error;
  }
};

// ✅ VERIFICAR SE ONBOARDING FOI CONCLUÍDO
export const verificarOnboarding = async (uid) => {
  try {
    const docSnap = await getDoc(doc(db, "usuarios", uid));

    // ⚠️ Se não existe documento → NÃO força onboarding
    if (!docSnap.exists()) return true;

    const data = docSnap.data();

    // ✅ Se o campo existe, respeita ele
    if (typeof data.onboardingConcluido === "boolean") {
      return data.onboardingConcluido;
    }

    // 🧠 Conta antiga (sem campo) → considera como concluído
    return true;

  } catch (error) {
    console.error("Erro ao verificar onboarding:", error);

    // Segurança: nunca travar usuário no onboarding por erro
    return true;
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
import { db } from "../firebase";
import { collection, query, where, getDocs } from "firebase/firestore";

/**
 * Valida o formato do username
 * Regras: 3 a 20 caracteres, apenas letras (a-z A-Z), números (0-9),
 *         underscore (_) e ponto (.)
 * @param {string} username
 * @returns {boolean}
 */
export const validarUsername = (username) => {
  if (!username || typeof username !== "string") return false;
  const regex = /^[a-zA-Z0-9_.]{3,20}$/;
  return regex.test(username);
};

/**
 * Verifica se o username já está em uso
 * @param {string} username
 * @param {string|null} uidAtual - Se fornecido, ignora o próprio usuário (edição)
 * @returns {Promise<boolean>} true = disponível, false = indisponível
 */
export const verificarDisponibilidade = async (username, uidAtual = null) => {
  if (!validarUsername(username)) return false;

  const q = query(collection(db, "usuarios"), where("username", "==", username));
  const snapshot = await getDocs(q);

  if (snapshot.empty) return true;

  // Se tem um uidAtual, verifica se o único documento encontrado é ele mesmo
  if (uidAtual && snapshot.docs.length === 1 && snapshot.docs[0].id === uidAtual) {
    return true;
  }

  return false;
};

/**
 * Gera uma sugestão de username baseada no nome completo
 * Ex: "João da Silva" -> "joao_da_silva" (limitado a 20 caracteres)
 * @param {string} nomeCompleto
 * @returns {string}
 */
export const gerarSugestao = (nomeCompleto) => {
  if (!nomeCompleto) return "pescador";

  let sugestao = nomeCompleto
    .toLowerCase()
    .normalize("NFD") // separa letras acentuadas do diacrítico
    .replace(/[\u0300-\u036f]/g, "") // remove os acentos
    .replace(/\s+/g, "_") // espaços viram underscore
    .replace(/[^a-z0-9_]/g, ""); // remove caracteres especiais

  // Fallback se ficar vazio
  if (!sugestao) sugestao = "pescador";

  // Limitar comprimento
  if (sugestao.length > 20) sugestao = sugestao.slice(0, 20);
  if (sugestao.length < 3) sugestao = sugestao.padEnd(3, "0");

  return sugestao;
};

/**
 * Função auxiliar para validar + verificar disponibilidade em um único fluxo
 * @param {string} username
 * @param {string|null} uidAtual
 * @returns {Promise<{valido: boolean, disponivel: boolean, mensagem: string}>}
 */
export const validarEVerificarUsername = async (username, uidAtual = null) => {
  if (!username || username.trim() === "") {
    return { valido: false, disponivel: false, mensagem: "Username não pode estar vazio." };
  }

  if (!validarUsername(username)) {
    return {
      valido: false,
      disponivel: false,
      mensagem: "3-20 caracteres. Use letras, números, _ ou .",
    };
  }

  const disponivel = await verificarDisponibilidade(username, uidAtual);
  return {
    valido: true,
    disponivel,
    mensagem: disponivel ? "✅ Disponível" : "❌ Indisponível",
  };
};
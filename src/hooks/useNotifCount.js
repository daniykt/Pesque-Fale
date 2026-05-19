import { useEffect, useState } from 'react';
import { db } from '../firebase';
import {
  collection,
  query,
  where,
  onSnapshot,
} from 'firebase/firestore';
import { observeAuthState } from '../auth';

export function useNotifCount() {
  const [user, setUser]   = useState(null);
  const [count, setCount] = useState(0);

  // 🔐 Observa auth — zera o count ao deslogar
  useEffect(() => {
    const unsubscribe = observeAuthState((u) => {
      setUser(u);
      if (!u) setCount(0);
    });
    return unsubscribe;
  }, []);

  // 🔔 Escuta Firestore em tempo real
  useEffect(() => {
    if (!user) return;

    const q = query(
      collection(db, 'notificacoes'),
      where('para', '==', user.uid),
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      // ✅ Corrigido: conta como não lida se NÃO for explicitamente true
      const naoLidas = snapshot.docs.filter((d) => d.data().lida !== true);
      setCount(naoLidas.length);
    });

    return unsubscribe;
  }, [user]);

  return count;
}
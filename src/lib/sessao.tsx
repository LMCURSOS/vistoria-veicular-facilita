import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import type { Session } from '@supabase/supabase-js';
import { linkDoEmail, supabase } from './supabase';

export type Pessoa = {
  id: string;
  nome: string;
  email: string;
  papel: 'admin' | 'equipe';
  ativo: boolean;
};

type Estado = {
  carregando: boolean;
  sessao: Session | null;
  pessoa: Pessoa | null; // null com sessão = não está na equipe ou foi desativada
  precisaCriarSenha: boolean; // chegou por convite ou por "esqueci minha senha"
  senhaCriada: () => void;
  sair: () => Promise<void>;
};

const Contexto = createContext<Estado | null>(null);

async function buscarPessoa(id: string): Promise<Pessoa | null> {
  const { data, error } = await supabase
    .from('equipe')
    .select('id, nome, email, papel, ativo')
    .eq('id', id)
    .maybeSingle();
  if (error || !data || !data.ativo) return null;
  return data as Pessoa;
}

export function SessaoProvider({ children }: { children: ReactNode }) {
  const [carregando, setCarregando] = useState(true);
  const [sessao, setSessao] = useState<Session | null>(null);
  const [pessoa, setPessoa] = useState<Pessoa | null>(null);
  const [precisaCriarSenha, setPrecisaCriarSenha] = useState(
    linkDoEmail.tipo === 'invite' || linkDoEmail.tipo === 'recovery',
  );

  useEffect(() => {
    let vivo = true;

    async function aplicar(s: Session | null) {
      const p = s ? await buscarPessoa(s.user.id) : null;
      if (!vivo) return;
      setSessao(s);
      setPessoa(p);
      setCarregando(false);
    }

    supabase.auth.getSession().then(({ data }) => aplicar(data.session));

    const { data } = supabase.auth.onAuthStateChange((evento, s) => {
      if (evento === 'PASSWORD_RECOVERY') setPrecisaCriarSenha(true);
      // Fora do callback, como pede o Supabase, para não travar o login.
      setTimeout(() => aplicar(s), 0);
    });

    return () => {
      vivo = false;
      data.subscription.unsubscribe();
    };
  }, []);

  const valor: Estado = {
    carregando,
    sessao,
    pessoa,
    precisaCriarSenha,
    senhaCriada: () => setPrecisaCriarSenha(false),
    sair: async () => {
      await supabase.auth.signOut();
    },
  };

  return <Contexto.Provider value={valor}>{children}</Contexto.Provider>;
}

export function useSessao() {
  const c = useContext(Contexto);
  if (!c) throw new Error('useSessao fora do SessaoProvider');
  return c;
}

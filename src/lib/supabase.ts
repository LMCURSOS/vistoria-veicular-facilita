import { createClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const chave = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY as string | undefined;

if (!url || !chave) {
  throw new Error(
    'Faltam VITE_SUPABASE_URL e VITE_SUPABASE_PUBLISHABLE_KEY. Veja o .env.example.',
  );
}

// Links que chegam por e-mail (convite e troca de senha) trazem no endereço
// o tipo do link ou o erro. Lemos antes de o Supabase limpar o endereço.
const doLink = new URLSearchParams(window.location.hash.slice(1));
export const linkDoEmail = {
  tipo: doLink.get('type'), // 'invite' | 'recovery' | null
  erro: doLink.get('error_code'), // ex.: 'otp_expired'
};

export const supabase = createClient(url, chave, {
  auth: {
    // Convites feitos pelo painel do Supabase só funcionam no fluxo "implicit".
    flowType: 'implicit',
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});

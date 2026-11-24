import { useId, useState, type ReactNode } from 'react';

export function IconeCarro({ tamanho = 30 }: { tamanho?: number }) {
  return (
    <svg width={tamanho} height={tamanho} viewBox="0 0 24 24" fill="none" stroke="currentColor"
      strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M5 17h14M3 17v-4l2-5a2 2 0 0 1 2-1h10a2 2 0 0 1 2 1l2 5v4" />
      <circle cx="7.5" cy="17" r="1.8" />
      <circle cx="16.5" cy="17" r="1.8" />
    </svg>
  );
}

/** Cabeçalho das telas de acesso (mesmo da tela "Entrar" do canvas). */
export function Marca({ titulo, texto }: { titulo: string; texto: string }) {
  return (
    <div className="marca">
      <span className="marca-icone" aria-hidden="true"><IconeCarro /></span>
      <span className="marca-nome">Facilita</span>
      <h1>{titulo}</h1>
      <p>{texto}</p>
    </div>
  );
}

export function Alerta({ children, ok = false }: { children: ReactNode; ok?: boolean }) {
  return (
    <div role={ok ? 'status' : 'alert'} className={'alerta' + (ok ? ' ok' : '')}>
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
        strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        {ok ? <path d="M5 12.5l4.5 4.5L19 7.5" /> : <><circle cx="12" cy="12" r="9" /><path d="M12 8v5M12 16h.01" /></>}
      </svg>
      <span>{children}</span>
    </div>
  );
}

type CampoProps = {
  rotulo: string;
  valor: string;
  aoMudar: (v: string) => void;
  erro?: boolean;
  tipo?: 'email' | 'text';
  autoComplete?: string;
  ajuda?: string;
};

export function Campo({ rotulo, valor, aoMudar, erro, tipo = 'text', autoComplete, ajuda }: CampoProps) {
  const id = useId();
  return (
    <div className="fld">
      <label htmlFor={id}>{rotulo}</label>
      <input id={id} className={'inp' + (erro ? ' is-err' : '')} type={tipo}
        inputMode={tipo === 'email' ? 'email' : undefined} autoComplete={autoComplete}
        value={valor} onChange={(e) => aoMudar(e.target.value)} />
      {ajuda && <span className="help">{ajuda}</span>}
    </div>
  );
}

export function CampoSenha({ rotulo, valor, aoMudar, erro, autoComplete, ajuda }: Omit<CampoProps, 'tipo'>) {
  const id = useId();
  const [vendo, setVendo] = useState(false);
  return (
    <div className="fld">
      <label htmlFor={id}>{rotulo}</label>
      <div style={{ position: 'relative' }}>
        <input id={id} className={'inp' + (erro ? ' is-err' : '')} type={vendo ? 'text' : 'password'}
          autoComplete={autoComplete} value={valor} onChange={(e) => aoMudar(e.target.value)}
          style={{ paddingRight: 92 }} />
        <button type="button" className="linkbtn" onClick={() => setVendo(!vendo)} aria-pressed={vendo}
          style={{ position: 'absolute', right: 8, top: 2, padding: '0 8px' }}>
          {vendo ? 'Esconder' : 'Mostrar'}
        </button>
      </div>
      {ajuda && <span className="help">{ajuda}</span>}
    </div>
  );
}

/** Traduz os erros do Supabase para a linguagem das telas. */
export function mensagemDeErro(e: { message?: string; code?: string; status?: number } | null): string {
  if (!e) return '';
  const c = e.code ?? '';
  if (c === 'invalid_credentials') return 'E-mail ou senha não conferem. Confira e tente de novo.';
  if (c === 'over_request_rate_limit' || c === 'over_email_send_rate_limit' || e.status === 429)
    return 'Muitas tentativas seguidas. Espere alguns minutos e tente de novo.';
  if (c === 'weak_password') return 'Senha fraca. Use pelo menos 8 caracteres, misturando letras e números.';
  if (c === 'same_password') return 'A senha nova precisa ser diferente da anterior.';
  if (/fetch|network/i.test(e.message ?? '')) return 'Sem conexão com a internet. Confira e tente de novo.';
  return 'Não deu certo agora. Tente de novo em instantes.';
}

import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { Alerta, Campo, Marca, mensagemDeErro } from '../componentes/basicos';

/** "Esqueci minha senha": manda um link para criar uma senha nova. */
export default function EsqueciSenha() {
  const [email, setEmail] = useState('');
  const [erro, setErro] = useState('');
  const [enviado, setEnviado] = useState(false);
  const [enviando, setEnviando] = useState(false);

  async function enviar(e: FormEvent) {
    e.preventDefault();
    setErro('');
    if (!email.trim()) {
      setErro('Digite o e-mail da sua conta.');
      return;
    }
    setEnviando(true);
    const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), {
      redirectTo: window.location.origin + '/criar-senha',
    });
    setEnviando(false);
    // Por segurança, a mensagem é a mesma exista ou não a conta.
    if (error && error.status !== 400) setErro(mensagemDeErro(error));
    else setEnviado(true);
  }

  return (
    <main className="tela">
      <div className="tela-centro">
        <Marca titulo="Esqueci minha senha" texto="Digite o e-mail da sua conta. Vamos mandar um link para você criar uma senha nova." />
        <form className="form" onSubmit={enviar} noValidate>
          {erro && <Alerta>{erro}</Alerta>}
          {enviado && (
            <Alerta ok>Se esse e-mail for da equipe, o link chega em alguns minutos. Confira também o spam.</Alerta>
          )}
          <Campo rotulo="E-mail" tipo="email" autoComplete="username" valor={email} aoMudar={setEmail} erro={!!erro} />
          <button type="submit" className="cta" disabled={enviando} style={{ marginTop: 8 }}>
            {enviando ? 'Enviando…' : 'Enviar link'}
          </button>
          <Link to="/entrar" className="linkbtn centro">Voltar para entrar</Link>
        </form>
      </div>
    </main>
  );
}

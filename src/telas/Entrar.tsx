import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { Alerta, Campo, CampoSenha, Marca, mensagemDeErro } from '../componentes/basicos';

/** Tela "Entrar" do canvas (D59): e-mail e senha da equipe. */
export default function Entrar({ aviso }: { aviso?: string }) {
  const [email, setEmail] = useState('');
  const [senha, setSenha] = useState('');
  const [erro, setErro] = useState('');
  const [enviando, setEnviando] = useState(false);

  async function entrar(e: FormEvent) {
    e.preventDefault();
    setErro('');
    if (!email.trim() || !senha) {
      setErro('Preencha o e-mail e a senha.');
      return;
    }
    setEnviando(true);
    const { error } = await supabase.auth.signInWithPassword({ email: email.trim(), password: senha });
    setEnviando(false);
    if (error) setErro(mensagemDeErro(error));
  }

  const comErro = erro !== '';

  return (
    <main className="tela">
      <div className="tela-centro">
        <Marca titulo="Fichas de entrega de veículos" texto="Entre com a sua conta da equipe Facilita." />
        <form className="form" onSubmit={entrar} noValidate>
          {aviso && !comErro && <Alerta ok>{aviso}</Alerta>}
          {comErro && <Alerta>{erro}</Alerta>}
          <Campo rotulo="E-mail" tipo="email" autoComplete="username" valor={email} aoMudar={setEmail} erro={comErro} />
          <CampoSenha rotulo="Senha" autoComplete="current-password" valor={senha} aoMudar={setSenha} erro={comErro} />
          <button type="submit" className="cta" disabled={enviando} style={{ marginTop: 8 }}>
            {enviando ? 'Entrando…' : 'Entrar'}
          </button>
          <Link to="/esqueci-senha" className="linkbtn centro">Esqueci minha senha</Link>
        </form>
        <span className="help rodape-nota">
          Acesso só para a equipe Facilita. Cada ficha guarda quem fez a entrega e a devolução, com data e hora.
        </span>
      </div>
    </main>
  );
}

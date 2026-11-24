import { useState, type FormEvent } from 'react';
import { supabase } from '../lib/supabase';
import { useSessao } from '../lib/sessao';
import { Alerta, CampoSenha, Marca, mensagemDeErro } from '../componentes/basicos';

/** Primeira senha (convite) ou senha nova (esqueci minha senha). */
export default function CriarSenha() {
  const { senhaCriada } = useSessao();
  const [senha, setSenha] = useState('');
  const [repete, setRepete] = useState('');
  const [erro, setErro] = useState('');
  const [enviando, setEnviando] = useState(false);

  async function salvar(e: FormEvent) {
    e.preventDefault();
    setErro('');
    if (senha.length < 8) return setErro('A senha precisa ter pelo menos 8 caracteres.');
    if (senha !== repete) return setErro('As duas senhas não são iguais.');
    setEnviando(true);
    const { error } = await supabase.auth.updateUser({ password: senha });
    setEnviando(false);
    if (error) return setErro(mensagemDeErro(error));
    window.history.replaceState(null, '', '/');
    senhaCriada();
  }

  return (
    <main className="tela">
      <div className="tela-centro">
        <Marca titulo="Crie a sua senha" texto="É com ela e com o seu e-mail que você entra no app daqui em diante." />
        <form className="form" onSubmit={salvar} noValidate>
          {erro && <Alerta>{erro}</Alerta>}
          <CampoSenha rotulo="Senha nova" autoComplete="new-password" valor={senha} aoMudar={setSenha}
            erro={!!erro} ajuda="Pelo menos 8 caracteres." />
          <CampoSenha rotulo="Repita a senha" autoComplete="new-password" valor={repete} aoMudar={setRepete} erro={!!erro} />
          <button type="submit" className="cta" disabled={enviando} style={{ marginTop: 8 }}>
            {enviando ? 'Salvando…' : 'Salvar senha'}
          </button>
        </form>
      </div>
    </main>
  );
}

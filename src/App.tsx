import { Navigate, Route, Routes } from 'react-router-dom';
import { linkDoEmail } from './lib/supabase';
import { useSessao } from './lib/sessao';
import Entrar from './telas/Entrar';
import EsqueciSenha from './telas/EsqueciSenha';
import CriarSenha from './telas/CriarSenha';
import SemAcesso from './telas/SemAcesso';
import Inicio from './telas/Inicio';

const avisoLinkVencido =
  linkDoEmail.erro === 'otp_expired'
    ? 'O link do e-mail venceu ou já foi usado. Peça um novo em "Esqueci minha senha" ou ao administrador.'
    : undefined;

export default function App() {
  const { carregando, sessao, pessoa, precisaCriarSenha } = useSessao();

  if (carregando) return <div className="carregando">Carregando…</div>;

  // Sem login: só as telas de acesso.
  if (!sessao) {
    return (
      <Routes>
        <Route path="/entrar" element={<Entrar aviso={avisoLinkVencido} />} />
        <Route path="/esqueci-senha" element={<EsqueciSenha />} />
        <Route path="*" element={<Navigate to="/entrar" replace />} />
      </Routes>
    );
  }

  // Chegou pelo link do convite ou de "esqueci minha senha".
  if (precisaCriarSenha) return <CriarSenha />;

  // Logado, mas fora da equipe ou desativado.
  if (!pessoa) return <SemAcesso />;

  return (
    <Routes>
      <Route path="/" element={<Inicio />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

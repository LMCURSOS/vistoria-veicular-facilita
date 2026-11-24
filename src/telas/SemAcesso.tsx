import { useSessao } from '../lib/sessao';
import { Alerta, Marca } from '../componentes/basicos';

/** Conta existe no Supabase, mas não está ativa na equipe. */
export default function SemAcesso() {
  const { sair, sessao } = useSessao();
  return (
    <main className="tela">
      <div className="tela-centro">
        <Marca titulo="Sem acesso às fichas" texto={sessao?.user.email ?? ''} />
        <div className="form">
          <Alerta>Esta conta não está ativa na equipe Facilita. Fale com o administrador.</Alerta>
          <button type="button" className="ghost" onClick={sair}>Sair</button>
        </div>
      </div>
    </main>
  );
}

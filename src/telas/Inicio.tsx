import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useSessao } from '../lib/sessao';
import { Alerta, Marca } from '../componentes/basicos';

type Conferencia = { pontos: number; componentes: number; veiculos: number } | { erro: string };

/**
 * TEMPORÁRIA: confirma que login e banco estão ligados.
 * Na etapa 1 ela dá lugar à tela inicial do canvas (Home).
 */
export default function Inicio() {
  const { pessoa, sair } = useSessao();
  const [conf, setConf] = useState<Conferencia | null>(null);

  useEffect(() => {
    (async () => {
      const contar = (t: string) => supabase.from(t).select('*', { count: 'exact', head: true });
      const [p, c, v] = await Promise.all([contar('pontos_padrao'), contar('componentes_padrao'), contar('veiculos')]);
      const erro = p.error ?? c.error ?? v.error;
      setConf(erro ? { erro: erro.message } : { pontos: p.count ?? 0, componentes: c.count ?? 0, veiculos: v.count ?? 0 });
    })();
  }, []);

  return (
    <main className="tela">
      <div className="tela-centro">
        <Marca titulo={`Olá, ${pessoa?.nome ?? ''}`} texto={`${pessoa?.email ?? ''} · ${pessoa?.papel === 'admin' ? 'administrador' : 'equipe'}`} />
        <div className="card">
          <b>Base do app no ar</b>
          {!conf && <span className="help">Conferindo o banco…</span>}
          {conf && 'erro' in conf && <Alerta>Não consegui ler o banco: {conf.erro}</Alerta>}
          {conf && !('erro' in conf) && (
            <>
              <div className="rv"><span>Pontos do mapa</span><strong>{conf.pontos} de 28</strong></div>
              <div className="rv"><span>Componentes</span><strong>{conf.componentes} de 16</strong></div>
              <div className="rv"><span>Veículos cadastrados</span><strong>{conf.veiculos}</strong></div>
            </>
          )}
          <span className="help">Tela provisória. As telas da ficha entram na etapa 1.</span>
        </div>
        <button type="button" className="ghost" onClick={sair}>Sair</button>
      </div>
    </main>
  );
}

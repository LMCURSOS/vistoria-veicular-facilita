# Facilita · Ficha de entrega de veículos · Banco de dados (Supabase)

Versão de 23/11/2026. Estes arquivos criam o banco completo do app: tabelas, regras de acesso, espaços de arquivos e dados fixos.

## O que tem aqui

| Arquivo | O que faz |
| --- | --- |
| `migrations/0001_tabelas.sql` | Tabelas: equipe, veículos, condutores, fichas, pontos e componentes da vistoria (entrega e devolução), envios e correções |
| `migrations/0002_regras.sql` | Quem pode o quê (acesso por linha), auditoria feita pelo servidor e travas da ficha |
| `migrations/0003_arquivos.sql` | Quatro espaços privados: fotos dos veículos, fotos de avaria, rubricas e PDFs |
| `seed.sql` | Dados fixos: os 28 pontos do mapa (posição em % da moldura) e os 16 componentes |
| `exemplo.sql` | Dados fictícios do canvas (Etios RIO2A18 e condutores de exemplo). **Só no ambiente de teste** |

## Regras que o banco garante sozinho

- Só quem é da equipe e está ativo vê e mexe nos dados.
- Pessoas entram só por convite; a primeira pessoa convidada vira admin.
- Só o admin muda papel e situação de alguém da equipe; a equipe sempre tem pelo menos um admin.
- A ficha nasce como rascunho, passa a "em uso" com a rubrica da entrega e fica "finalizada" com a rubrica da devolução. Não pula nem volta etapa.
- A entrega só é concluída com os 28 pontos e os 16 componentes marcados (D23) e sem avaria que impeça o uso (D38).
- Quem fez a entrega e a devolução, e a hora de cada rubrica, são gravados pelo servidor (D59).
- A ficha guarda modelo, placa e dados do condutor da época (D64).
- Depois da rubrica, os dados da entrega não mudam. Ficha finalizada só muda pelo admin, com motivo, e cada correção fica registrada.
- Veículo não se apaga, só se desativa (D68), e só entra numa ficha com as 4 fotos (D67).
- KM final não pode ser menor que o inicial. Um carro não fica em duas entregas abertas ao mesmo tempo.
- Rubricas e PDFs, depois de gravados, não podem ser trocados.

Todas essas regras foram testadas antes da entrega (38 verificações). Visitante sem login não chega a nenhuma tabela.

## Passo a passo para criar o projeto

1. **Conta no nome do Facilita.** Crie a conta no Supabase com o **comercial@facilitacnh.com.br** (TEC06) e convide pelo menos mais uma pessoa como administradora da organização.
2. **Dois projetos, ambos no plano gratuito** (TEC04), na **região South America (São Paulo)**: `facilita-fichas-teste` para testes e `facilita-fichas` para a equipe usar de verdade. O plano gratuito aceita dois projetos ativos por conta. Guarde a senha de cada banco num lugar seguro. Na criação: região em "Precisa de uma região específica?" → São Paulo; em Acesso a dados, deixe marcado **Ativar API de Dados**, deixe **desmarcado** "Conceda acesso à API para novas tabelas automaticamente" (os scripts liberam só o necessário) e **marque** "Ativar RLS em novas tabelas automaticamente".
3. **Login só por convite.** Em Authentication, deixe o login por e-mail ligado e **desligue o cadastro aberto** (a opção que permite novos usuários se cadastrarem sozinhos).
4. **Rodar os scripts.** No SQL Editor, cole e rode, nesta ordem: `0001_tabelas.sql`, `0002_regras.sql`, `0003_arquivos.sql` e `seed.sql`. Rode `exemplo.sql` **só no projeto de teste**, nunca no `facilita-fichas`: ele cria um carro e condutores fictícios.
5. **Primeira pessoa (admin).** Em Authentication > Users, use "Invite user" para convidar quem vai ser o admin. Ela recebe o e-mail e cria a senha. Depois convide o resto da equipe.
6. **Conferir.** No Table Editor devem aparecer as tabelas; em Storage, os 4 espaços (`veiculos-fotos`, `avarias-fotos`, `rubricas`, `pdfs`).
7. **Me passar só estes dois dados** para ligar o app: a URL do projeto e a chave pública (anon key), em Settings > API. **Nunca envie a chave service_role** a ninguém.

## Ainda em aberto

- **Prazo de guarda (LGPD):** a ficha já tem o campo `apagar_em` e a função que lista as vencidas; o prazo entra quando o jurídico definir.
- **E-mail dos convites e dos PDFs:** o envio padrão do Supabase é limitado e serve para testes. Para a equipe usar de verdade, configurar o SMTP com o remetente **comercial@facilitacnh.com.br**. Isso pede alguns registros no DNS do domínio facilitacnh.com.br (SPF, DKIM e DMARC) para os e-mails não caírem no spam.
- **Cuidados do plano gratuito:** o projeto pausa depois de 7 dias sem uso (dá para reativar no painel), não tem backup diário e o espaço é de 500 MB de banco e 1 GB de arquivos. Até passar para o Pro, acompanhar o espaço usado e manter uma cópia de segurança periódica feita por fora.
- **Hospedagem das telas:** Cloudflare Workers com static assets (TEC05, revista em 23/11). O código fica no repositório privado do GitHub da empresa (TEC07).

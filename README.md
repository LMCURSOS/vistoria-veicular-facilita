# Vistoria veicular · Facilita CNH

App da Ficha de entrega de veículos do Facilita: entrega e devolução do carro alugado ao instrutor, com vistoria, fotos, rubrica do condutor, PDF e envio por e-mail. Uso interno da empresa.

- Funciona no celular, no tablet e no computador (PWA: pode ser instalado no Android).
- As telas seguem o design aprovado no canvas do projeto e a Biblioteca de componentes.
- As decisões estão na Documentação do projeto (D01–D70, T01–T05, W01–W05, TEC01–TEC07, DB01–DB04).

## Peças

| Parte | Onde |
| --- | --- |
| Telas | React + TypeScript, montadas com Vite (`src/`) |
| Login, banco e arquivos | Supabase, região São Paulo (`supabase/` tem os scripts e o passo a passo) |
| Publicação | Cloudflare Workers com static assets (`wrangler.jsonc`) |

## Pastas

```
src/
  main.tsx          início do app
  App.tsx           qual tela aparece (sem login, criar senha, sem acesso, logado)
  lib/supabase.ts   ligação com o Supabase
  lib/sessao.tsx    quem está logado e se está ativo na equipe
  telas/            uma tela por arquivo
  componentes/      peças repetidas (cabeçalho, campos, avisos)
  estilos/          base.css (página) e pecas.css (classes das telas do canvas)
public/             ícone e manifesto do app instalado
supabase/           scripts do banco (rodar no SQL Editor, na ordem do LEIAME de lá)
```

## Rodar no computador

1. Node 22 ou mais novo.
2. Copie `.env.example` para `.env.local` e preencha com a URL e a chave **publishable** do projeto de teste do Supabase.
3. `npm install` e depois `npm run dev`. O app abre em http://localhost:5173.

`npm run build` confere os tipos e gera a pasta `dist`, que é o que vai para a Cloudflare.

## Publicar (Cloudflare)

A Cloudflare fica ligada a este repositório e publica sozinha a cada envio:

- Comando de build: `npm run build`
- Comando de deploy: `npx wrangler deploy`
- Variáveis de build: `VITE_SUPABASE_URL` e `VITE_SUPABASE_PUBLISHABLE_KEY`

No Supabase, em Authentication > URL Configuration, o endereço publicado entra em **Site URL** e em **Redirect URLs** (com `/criar-senha`), para os links de convite e de troca de senha voltarem ao app.

## Segurança

- Só a URL e a chave **publishable** do Supabase vão para o app. A chave secret e a service_role nunca entram aqui.
- Quem protege os dados é o banco: sem login da equipe ativa, nenhuma tabela responde.
- `.env` e `.env.local` não sobem para o repositório.
- Pessoas entram só por convite (cadastro aberto desligado no Supabase).

## Situação

- **v0.1 (24/11/2026):** base do app: entrar, esqueci minha senha, criar senha (convite e troca), sem acesso e uma tela provisória que confere a ligação com o banco.
- **Próximo (etapa 1):** tela inicial, entrega com rascunho, rubrica, PDF, envio, devolução e Finalizadas.

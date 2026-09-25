# Auditoria completa — OnboardOps
**Data:** 2026-09-25 (2ª rodada, completa) · **Feita por:** Claude (Opus 5.5), com o usuário logado no app, no painel do Supabase e no GitHub.
**Substitui** a 1ª rodada (parcial, interrompida pela queda da sessão).

**Escopo coberto:** leitura do código inteiro (`index.html`), regras de segurança e configuração do Supabase (políticas RLS, gatilhos, autenticação, backups, logs), integridade dos dados no banco, e teste ao vivo de **todas as 19 rotas**, **8 abas da Jornada × 8 clientes (64 combinações)**, **8 fichas de Cadastro** e **5 perfis simulados** — procurando erro de JavaScript, texto quebrado (`undefined`/`NaN`/`[object Object]`), permissões e conexões entre telas.

Regra usada: **corrigido direto** = mudança de código/visual/configuração sem risco a dados. **Só reportado** = mexe na estrutura ou nas regras de segurança do banco, apaga/migra dados, ou muda regra de negócio.

---

## 1. Críticos — precisam da sua decisão (NÃO aplicados)

### 1.1 Qualquer pessoa pode criar uma conta de administrador — **mais grave**
Três fatos combinados:
- **Cadastro aberto + confirmação de e-mail desligada** (Supabase → Authentication → Sign In/Providers). A única trava é o e-mail terminar em `@trinusco.com.br` — mas como não se confirma que a pessoa tem acesso àquela caixa de e-mail, qualquer um pode se cadastrar com o e-mail de outra pessoa.
- **O perfil é escolhido pelo navegador no cadastro** e o banco aceita sem conferir (`handle_new_user` lê `raw_user_meta_data->>'perfil'`). Chamando a API direto, dá pra se cadastrar já como "Desenvolvedor" ou "Gestão Executiva".
- **Só existe 1 conta real no banco (a sua).** Os outros 9 nomes da tela de Usuários (incluindo 3 da Gestão Executiva) ainda não criaram senha — quem se cadastrar primeiro com o e-mail deles herda o perfil de administrador.

O Cloudflare Access protege a tela do app, mas **não protege a API do Supabase**, que é pública (a chave publicável está no código, como deve ser).

**O que fazer (em ordem):**
1. **Ligar "Confirm email"** no painel do Supabase (Authentication → Sign In / Providers → Confirm email → Save). O app já trata esse caso ("Conta criada! Verifique seu e-mail"). Leva 10 segundos e fecha a porta principal.
2. Aplicar `sql/01-seguranca-rls-e-cadastro.sql` (conta nova sempre nasce Área Parceira; só admin muda perfil; histórico imutável; Área Parceira não escreve).

### 1.2 Todas as 13 tabelas liberam leitura e escrita total para qualquer usuário logado
Cada tabela tem uma única política `authenticated full access` com `using (true) with check (true)`. Toda a separação por perfil (`can()`, `canAtivos()`…) existe **só no JavaScript** — um usuário "Área Parceira" (somente leitura) consegue editar ou apagar qualquer dado chamando a API direto, inclusive:
- mudar o **próprio perfil** para administrador na tabela `users`;
- **apagar o Histórico de Alterações e os logins** (trilha de auditoria).

Correção: mesmo script `sql/01-seguranca-rls-e-cadastro.sql`.

### 1.3 Sem backup do banco
Plano grátis do Supabase **não faz backup**. Se algo for apagado (por erro ou pelo problema do item 1.2), não há como recuperar pelo Supabase.
**Opções:** Supabase Pro (US$ 25/mês, 7 dias de backup — já estava no plano de produção), ou, enquanto isso, exportar o JSON pela tela "Backup & Segurança" com regularidade.

### 1.4 Campos que somem ao recarregar a página (perda de dados)
A tela deixa preencher, mas o banco não tem coluna para guardar:
- **Atividades:** Tags, Origem, Interação de origem, Ativo vinculado
- **Interações:** Ativo vinculado, Atividade gerada, e no Histórico Diário: **Pontos de atenção, Decisões, Pendências**; Satisfação (aba nova)
- **First Value:** descrição quando o tipo é "Outra"

Correção: `sql/02-colunas-faltantes.sql` (só adiciona colunas) + ajuste no código depois.

### 1.5 Etapa dos ativos — 24 de 39 ainda com valores antigos
Entrega (9), Comercialização (6), Estruturação (5), Pós-obra (4). Já corrigi a tela para mostrar o valor como "(etapa antiga)" em vez de "—", mas os dados continuam antigos. Mapeamento sugerido em `sql/03-migracao-etapas-ativos.sql` — **precisa da sua confirmação**, porque "Entrega", "Comercialização" e "Estruturação" não têm equivalente exato.

### 1.6 Link de "Esqueci minha senha" não funciona para ninguém
Em Authentication → URL Configuration, o **Site URL está `http://localhost:3000`** (padrão, não existe) e não há nenhum endereço autorizado. O e-mail de redefinição manda a pessoa para um endereço morto. Tentei corrigir, mas o modo automático bloqueou (mudança em configuração compartilhada de produção). **Para você fazer:**
- Site URL → `https://onboardops.pages.dev`
- Redirect URLs → adicionar `https://onboardops.pages.dev/**` e `http://localhost:8080/**`

---

## 2. Corrigido nesta rodada (código — vai no PR)

| # | Problema | Correção |
|---|---|---|
| 1 | Perfil **Middle** acessava o Mapa de Distribuição (fora das 5 áreas liberadas) | `mapa` entrou em `NAV_ACCESS` |
| 2 | Regra de acesso **liberava por padrão** qualquer rota sem configuração — foi assim que o item 1 escapou | `navAllowed()` agora **bloqueia por padrão**; toda rota tem entrada explícita |
| 3 | Abas Executivo/Pipeline/Mapa do Dashboard apareciam para quem não tem acesso (clicar dava "não permitido") | Abas filtradas por permissão |
| 4 | **Todos** os cards de indicador tinham 2 barras de cor (restos de 2 designs); em alguns as cores não batiam (ex.: "Contratos Assinados" azul em cima, azul-marinho do lado) | As duas barras usam a mesma cor; `k-navy` ganhou cor própria |
| 5 | Cada **recarregamento de página** era registrado como login + linha no Histórico (251 logins e 339 históricos com um único usuário) | Só registra login de verdade (senha digitada) |
| 6 | Botões **"Limpar histórico"** e "apagar registro" diziam "Histórico limpo" mas não apagavam nada no banco (voltava tudo ao recarregar) — e trilha de auditoria não deveria ser apagável | Histórico passou a ser somente leitura na interface |
| 7 | Botão **"Restaurar dados de exemplo"** em Configurações sobrescrevia os dados reais do time com dados fictícios (inclusive a BARION, que tem o mesmo código no exemplo) | Botão removido |
| 8 | "Restaurar backup" prometia "sobrescrever todos os dados", mas na prática mescla (não apaga o que foi criado depois) | Textos corrigidos para descrever o comportamento real |
| 9 | Tela de **Usuários** mostrava 9 pessoas sem conta como se fossem reais; Editar/Desativar/Remover diziam "sucesso" sem fazer nada no banco — um admin poderia "desativar" alguém que saiu e a pessoa ainda criaria a conta depois | Marcadas como **"Aguardando 1º acesso"**, sem botões de ação |
| 10 | **"Gerenciar no cadastro"** e **"Editar"** (aba Ativos da Jornada) e **"Novo Cliente"** (Pipeline) abriam um **formulário antigo**, diferente da ficha do Cadastro, com outros campos | Todos abrem a ficha nova; o formulário antigo não é mais alcançável |
| 11 | Aba **Documentos** da Jornada não mostrava os documentos enviados no Cadastro, e não tinha como baixar | Mostra os dois (Cadastro + Interações), com download |
| 12 | Etapa antiga do ativo aparecia como "—" na edição | Aparece como "Entrega (etapa antiga)", sem sumir |
| 13 | Kanbans deixavam **arrastar** cards quem não tem permissão (soltava e dava "não permitido") | Card só é arrastável com permissão |
| 14 | Links "Baixar" usavam o conteúdo do banco direto como endereço — com o item 1.2, um "arquivo" forjado poderia executar código no navegador de quem clicasse | Só aceita arquivo de verdade (`data:…;base64`) |
| 15 | IDs vindos do banco vão dentro dos botões sem proteção — um ID forjado executaria código | Registros com ID fora do padrão são ignorados na leitura |
| 16 | Função de proteção `esc()` não escapava aspas simples | Passa a escapar |
| 17 | "Estado" do ativo sem proteção na lista de seleção | Protegido |
| 18 | "TTFV: 1 dias" | "1 dia" |
| 19 | Página Tarefas dizia "clique" mas precisa de clique duplo | Texto corrigido |
| 20 | Dados de exemplo com Etapa antiga | Atualizados |

Também **desliguei de vez o GitHub Pages** (branch = None) — sem isso, o próximo envio de código republicaria o site antigo, público e sem a trava do Cloudflare.

---

## 3. Verificado e OK

- **Visitantes sem login não leem nada** (teste anônimo → 401; o único erro do Postgres na última hora foi esse teste).
- **Trava de domínio `@trinusco.com.br`** no cadastro está ativa no banco (gatilho `restrict_signup_domain_trigger`).
- **RLS ligado** nas 13 tabelas (o problema é o conteúdo das políticas, item 1.2).
- **Nenhum registro órfão** (ativos, representantes, operações, atividades, interações, pesquisas, ativação e TTFV apontam todos para clientes existentes).
- **Todas as rotas, abas e fichas** carregam sem erro de JavaScript e sem texto quebrado, como Desenvolvedor e simulando os outros 5 perfis.
- **Perfis** enxergam exatamente o que deveriam (depois da correção do Mapa).
- **Cliente, ativo, representante, operação, proposta, pesquisa, configurações** fazem o caminho completo tela → banco → tela.
- Chave do Supabase no código é a publicável (correta).
- Health Score soma no máximo 100 (30 pesquisa + 50 ativação + 20 TTFV), coerente.

---

## 4. Dados que precisam da sua atenção

- **"saaddsd"** (sem CNPJ) e **"werwer"** (CNPJ "3123123", nº operação "drdwrf") são dados de teste — apagar?
- **"Ricardo De Lacerda Teodoro Ltda"** tem CNPJ válido mas nenhum outro dado — real ou teste?
- **RD VILLE** está com negociação "Proposta" mas etapa "onboarding"; **BARION** tem kickoff registrado com contrato ainda "Aguardando Assinatura" (e por isso já tem Health Score "Risco"). O sistema tem **dois campos de estágio independentes** (Ciclo de Negociação e Etapa da jornada) que podem se contradizer — regra de negócio a definir: bloquear kickoff antes da assinatura? Avançar um automaticamente quando o outro muda?

## 5. Mocado / provisório (já conhecido)
- `mockRegional()` — regional dos responsáveis é inventada.
- `mockBookedValue()` — Booked Value do painel da Jornada é inventado (o campo real `bookedValue` existe mas não é o exibido).
- Tipos da aba Interações (Ligação/Mensagem/…) usam vocabulário próprio, fora do filtro da tela de Interações.

## 6. Observações menores (sem ação agora)
- Status "Unhealthy" no painel do Supabase: projeto em compute Nano (RAM 60%). Não há erro — tende a melhorar no plano Pro.
- Anexos e documentos são guardados como texto (base64) dentro das tabelas. Funciona, mas com até 2 MB por arquivo o banco grátis (500 MB) enche rápido. Futuro: usar o Supabase Storage.
- O código carrega só os 500 históricos e 500 logins mais recentes.
- Perfil Middle tem a permissão `editOps` ligada, mas ela só é usada no Pipeline, que Middle não acessa — inofensivo.
- ~35 seletores CSS duplicados de designs antigos continuam no arquivo (o `.kpi` era o único com efeito visível).

# Pendências — OnboardOps

Itens em andamento ou planejados. Quando um item é concluído, ele é removido daqui (o resumo do que foi feito vai para o NOTAS.md).

---

## Inspetor de Desenvolvimento (F9)

Status: em andamento.

- [x] Passo 1 — validar padrão de nomes `tela.tipo.nome` com 5 exemplos reais (aprovado em 2026-09-22)
- [x] Passo 2 — registrar padrão em DECISOES.md
- [x] Passo 3 — tela piloto definida (Jornada do Cliente) e `data-id` aplicado (117 identificadores, sem duplicatas)
- [x] Passo 4 — módulo do inspetor construído (`ferramentas-dev/inspector.js` + `inspector.css`) e testado na tela piloto
- [x] Correspondência sempre exata (sem subir a árvore) + novo tipo `texto`
- [x] Painel: termo em inglês em destaque, português como referência secundária (2026-09-23)
- [x] Granularidade completa na Jornada do Cliente — card de cliente do Kanban, card de atividade, lista de atividades, painéis de interação/prazos/pendências (Visão Geral) e todas as linhas de informação (Tipologia, Status, Ciclo de Negociação, Ciclo de Implantação, Indicadores) marcadas por partes
- [x] **Jornada do Cliente 100% coberta** — incluindo o chrome global visível na tela (topbar, menu do usuário, sidebar/navegação, barra de filtros), sob novo prefixo neutro `global.*` (registrado em DECISOES.md, 2026-09-23).
- [x] Correções pós-checagem manual do usuário: colunas do Kanban (título/contador/vazio, na Jornada e em Atividades) e título de todo `.card-head` da Jornada (que estava marcado só no container, não no `<h3>` em si) — ver DECISOES.md, 2026-09-23. Total: 197 identificadores no projeto, sem duplicatas.
- [ ] Passo 5 — aplicar `data-id` nas demais telas, gradualmente, conforme forem mexidas (usando já o padrão granular: marcar contêiner E partes internas relevantes)
- [x] Mudança de estratégia (2026-09-23): cobertura passa a ser "boa o suficiente", não 100% exaustivo — buracos remanescentes na Jornada (e nas próximas telas) são preenchidos sob demanda, quando o usuário sentir falta durante o uso normal (ver DECISOES.md)
- [ ] Elementos novos do redesenho da Operação (card de identificação, selo de estágio clicável, sidebar de Contexto, botões de atalho) ainda não têm `data-id` — pendente, sob demanda (mesma regra acima)

---

## Redesenho da tela de Operação (Jornada do Cliente)

Status: concluído em 2026-09-23, a partir de um PDF de especificação do usuário.

- [x] Título de página removido em todas as telas (site-wide), só o destaque da sidebar indica a tela atual
- [x] Abas da Jornada movidas para o topo da página da operação (primeiro item)
- [x] Card de identificação: nome do cliente, nº da operação no AZO (clicável), selo único de estágio (clicável → menu pra trocar), linha de meta (Gerente/Onboarding/Key Account/Criado em/Última atualização) e botões de atalho (+ Tarefa, + Interações, + Pesquisa, + Ativação, + First Value, + Documentação)
- [x] Aba "Atividades" renomeada para "Tarefas" (só o rótulo da aba, dentro da Jornada)
- [x] Barra de estágios antiga (pills Proposta/Minuta/...) substituída pelo selo único — `jEstagioBar()` ficou sem uso (não removida, só não é mais chamada)
- [x] Sidebar de Contexto à direita: altura total da operação, botão de aglutinar virado pra direita (fecha) / esquerda (abre), Responsáveis (Gerente de Contas, Onboarding, Key Account — avatar + nome + subtítulo + lápis de edição), Nível de Prioridade, Etiquetas
- [x] Schema Supabase: colunas `etiquetas text[]` e `prioridade text` adicionadas em `clientes` (2026-09-23), sincronização testada e confirmada (upsert retornando 200)
- [ ] "Regional" do responsável é **mockada** (função `mockRegional()`, hash do nome → uma de 5 regionais fixas) — trocar por dado real quando o cadastro de usuários for enriquecido com regional/e-mail etc.
- [x] Botões "+ Pesquisa"/"+ Ativação"/"+ First Value" navegavam pra tela própria em vez de abrir dentro da operação — resolvido em 2026-09-25 (ver seção "Pesquisa Pós-Kickoff/Ativação/First Value dentro da Jornada" abaixo)

---

## Geração da Proposta (formulário de Nova Operação)

Status: em andamento — primeira rodada de reorganização concluída em 2026-09-24 (ver DECISOES.md pros detalhes técnicos de cada correção).

- [x] Cabeçalho reorganizado: busca de cliente em destaque + Número da Operação/Status/Classificação/Cliente Elite (agora Sim/Não)/Tipologia numa fileira, Nome Comercial/Razão Social/CNPJ/Cidade/UF na de baixo
- [x] CNPJ automático (`App.formatCnpj`) na Nova Operação e no Ativo — formata sozinho ao sair do campo
- [x] Ativo: Nome do Empreendimento e Razão Social mais largos, checkboxes discretos abaixo do nome, Localização reordenada (Cidade → Estado → Endereço, numa fileira própria fora do grid de colunas iguais), Cronograma da Obra antes de Números do Empreendimento com Status do Ativo primeiro
- [x] Serviços: catálogo em ordem alfabética lida por coluna, lista de "Mais solicitados" (top 5, calculado a partir do uso real já registrado) ao focar o campo de busca vazio, clique alterna selecionado/removido (chips separados removidos)
- [x] Inspetor: painel não fecha mais instantaneamente ao mover o mouse em direção a ele (tolerância de 1s)
- [x] Duas rodadas de correção pós-teste do usuário: campo de busca "duas caixas" (especificidade de CSS) e Cidade/UF "grudados" (largura fixa estourando a coluna do grid) — ambos com causa raiz documentada em DECISOES.md
- [ ] Segue em aberto: outros ajustes de UI/UX que o usuário mencionou querer revisar depois, com mais foco ("vou fazer depois quando estiver mais focado em uiux") — não especificados ainda

---

## Reestruturação da aba Visão Geral (Jornada do Cliente)

Status: concluído em 2026-09-24 (ver DECISOES.md pros detalhes técnicos).

- [x] Abas superiores reduzidas de 8 pra 5 (Pendências/Interações/Alterações saem do nível de aba)
- [x] Card de identificação (`.jcard`) mais compacto ("de 4 blocos pra 3 blocos")
- [x] Indicadores movidos pro rodapé do sidebar de Contexto, com separador visual dos campos editáveis
- [x] "Informações do Cliente" renomeado pra "Cliente"; grid reordenado com novo card "Serviços" (por ativo) no lugar do antigo "Ciclo de Negociação" (que só mudou de posição, não foi removido)
- [x] `crmPanel()` (Últimas Interações/Atividades/Próximos Prazos/Pendências) substituído por um resumo aglutinável de Pendências e Tarefas + uma Linha do Tempo da Operação com 4 sub-abas (Geral/Tarefas/Interações/Alterações)
- [x] Testado ao vivo em clientes reais via Claude in Chrome, sem erros de console
- [x] Ajustes finos (2026-09-24): alerta vermelho elegante no resumo de Pendências e Tarefas quando há pendência aberta; card de identificação mais fino ainda; card "Cliente" trocado pra dados cadastrais fixos (Nome Comercial/Razão Social/CNPJ/Classificação/Cliente Elite/Tipologia/Cidade/UF/Observação); pill de BV (mockado) no card de Serviços; removida redundância de responsáveis nos cards-resumo de Ciclo de Negociação/Implantação (seguem editáveis na aba Ciclos da Operação)
- [ ] BV (Booked Value) do card de Serviços é mockado (`mockBookedValue()`, hash do id do cliente) — mesma lógica provisória do `mockRegional()` — trocar quando o campo ganhar um lugar de cadastro definitivo
- [x] Card de Serviços (2026-09-25): corrigida a rolagem que não preenchia o card esticado (`.jserv-card` + `.jserv-resumo` viraram flex, `max-height` fixo saiu); chips coloridos trocados por lista de bullets simples (nome do ativo + tipologia no topo, serviços em `<ul>`, separador entre ativos); BV com destaque próprio (`.jserv-bv`, verde, negrito)
- [x] Lote via PDF "Próximo Prompts" (2026-09-25): Observação do card Cliente empilhada; cidade do ativo em Serviços; botão "hoje" ao editar datas em Ciclos da Operação; widget Pendências/Tarefas com ícone reduzido sem fundo + separado em duas listas ordenadas por prazo; card de identificação ainda mais compacto (botões dentro da coluna esquerda); sidebar de Contexto com campo de busca (datalist) no lugar do `<select>` de Onboarding/Key Account e dividido em dois blocos visuais; abas superiores full-width fora de `.jmain`, botão de voltar removido
- [x] Bug corrigido: Escape em campos de edição inline (Responsáveis do sidebar, datas de Ciclos da Operação) não cancelava de verdade — o `blur` disparado pela remoção do input do DOM salvava o valor mesmo assim. Fix: flag `dataset.cancel` checada no `onblur`
- [x] Bug real de altura no grid corrigido (2026-09-25, segunda rodada): causa raiz era CSS Grid usando max-content do Serviços pra dimensionar a linha inteira; fix real é `.jserv-card{height:0;min-height:100%}`, confirmado por medição ao vivo (`offsetHeight`)
- [x] Ciclo de Negociação + Ciclo de Implantação fundidos num card só "Ciclos da Operação" na Visão Geral, com datas editáveis clicando em cima (sem precisar mais de aba própria)
- [x] Aba "Ciclos da Operação" removida (de 5 pra 4 abas). Campos de Classificação & Responsáveis que viviam lá agora abrem num modal pelo botão "Editar" do card Cliente
- [x] BV saiu do card de Serviços e foi pro sidebar, dentro de um novo grupo "Consolidado" (BV, Total de Ativos, Total de Serviços) acima de Indicadores
- [ ] `c.bookedValue` é um campo real (editável no modal de Classificação & Responsáveis) mas o valor **mostrado** no sidebar ainda é o mock (`mockBookedValue()`) — trocar pelo valor real quando o usuário decidir onde/como esse campo deve ser preenchido de verdade
- [x] Ajuste fino pós-lote (2026-09-25): fundo da barra de abas diferenciado da página (`#E6E9F0`) com sangramento total até a borda do sidebar esquerdo e da viewport; gap entre os dois blocos do sidebar direito reduzido de 56px pra 16px; divisor duplicado removido entre "Assinatura Aditivo/Distrato" e "Ciclo de Implantação"; BV do Consolidado com fonte maior (21px)
- [x] Bug real corrigido (2026-09-25, terceira rodada): barra de abas sangrando até a borda direita cobria o topo do sidebar de Contexto (`.jctx` é `position:fixed`, não reservado pelo fluxo normal). Fix: `margin-right:290px`/`62px` na barra, abas redesenhadas pro estilo sublinhado (igual à Linha do Tempo)
- [x] Revisão da correção acima (2026-09-25, quarta rodada): a pedido do usuário, a barra de abas voltou a encostar na borda direita da página; a sobreposição com `.jctx` agora é evitada abaixando tanto `.jctx` quanto `.jcard` (respiro de 14px abaixo do fim da barra) em vez de encolher a largura da barra
- [x] Visual da barra de abas ajustado pra bater com print de referência (2026-09-25, quinta rodada): fundo liso (`var(--surface)`) no lugar do `#E6E9F0`, `box-shadow` trocado por `border-bottom:1px solid var(--line)`, abas inativas com peso de fonte normal (600) e só a ativa em negrito (700) — testado ao vivo, confirmado por `getComputedStyle()`
- [x] Quatro ajustes pós-teste real (2026-09-25, sexta rodada): anel de foco circular da aba ativa neutralizado (`.jtab:focus-visible`, causa raiz era regra global `:focus-visible` — não reproduzido no ambiente de teste, aplicado por leitura de código); barra de abas agora sangra os dois lados (`margin-right:-28px` além do `margin-left` que já existia), encostando de verdade na borda direita; "Criado em"/"Última atualização" voltaram pra `.jcard-meta` (lado do Key Account), `.jcard-meta-right` removida; assimetria vertical do card corrigida como efeito colateral da mudança anterior (coluna esquerda virou a mais alta, padding-bottom passou a valer)
- [x] Causa raiz real do semicírculo sob a aba ativa (2026-09-25, sétima rodada): não era o foco — era `border-radius:var(--radius-pill)` sobrevivente de `.jtab,.chip,.chip-btn,.vsw{}` (resquício do design antigo em pílula das abas), arredondando os cantos do sublinhado. Fix inicial: `.jtab{border-radius:0}`. Também simplificado a pedido do usuário: aba ativa marcada só por sublinhado + `color:var(--txt)` (cinza quase preto), sem mais azul
- [x] Fix da rodada anterior não funcionava de verdade (2026-09-25, oitava rodada): `.jtab{border-radius:0}` empatava em especificidade com a regra da pílula e perdia por vir antes no arquivo. Corrigido com `.jtabs-row .jtab{border-radius:0}` (especificidade maior, vence independente da ordem) — confirmado via `getComputedStyle` clicando de fato na aba

---

## Pesquisa Pós-Kickoff, Ativação Operacional e First Value dentro da Jornada

Status: concluído em 2026-09-25.

- [x] Três abas novas na barra da operação: Pós-Kickoff, Ativação, First Value (entre Tarefas e Documentos) — reaproveitam a lógica das telas independentes (`renderPesquisa`/`renderAtivacao`/`renderTTFV`) sem duplicar dados, escopadas ao cliente aberto via `filters.cliente` (que a Jornada já mantém fixo)
- [x] Botões de atalho "+ Pesquisa"/"+ Ativação"/"+ First Value" renomeados e trocados pra abrir a aba correspondente dentro da operação (`App.jTab(...)`), em vez de navegar pra fora
- [x] Telas independentes ocultadas da sidebar em 2026-09-25 (2ª rodada) — continuam existindo e funcionais (`hideNav:true` no array `NAV`, mesmo mecanismo já usado por `pipeline`/`cadastroAtivos`/`mapa`), só não aparecem mais como item de navegação. **Lembrar o usuário quando fizer sentido** (ex.: se pedir visão de portfólio de pesquisa/ativação/TTFV antes dos Dashboards cobrirem isso, ou pra decidir reativar/apagar de vez)
- [ ] Migração da visão de portfólio (todos os clientes de uma vez) pros Dashboards — mencionada pelo usuário como próximo passo, não especificada ainda

---

## Ajustes no Cadastro (campos, ordem, consistência com Nova Operação)

Status: concluído em 2026-09-25.

- [x] Card "Dados da Holding" trocado de `.form-grid` (2 colunas largas) pra `.form-flow` (larguras fixas por campo), mesmo sistema visual da Nova Operação — sem o buscador de cliente, Número da Operação e Status (que não fazem sentido no Cadastro)
- [x] Endereço movido pro fim do card (full-width), mesmo padrão da Nova Operação (campo full-width sempre por último)
- [x] Ordem dos cards na ficha do cliente: Ativos agora vem antes de Documentos (era o contrário)
- [x] Confirmado que o formulário de Ativo dentro do Cadastro já é idêntico ao da Nova Operação — `ativoAccordionMarkup()` é literalmente a mesma função nos dois lugares, não precisou de nenhuma mudança

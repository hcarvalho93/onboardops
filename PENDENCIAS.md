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
- [ ] Botões "+ Pesquisa"/"+ Ativação"/"+ First Value" navegam pra tela própria (já filtrada pelo cliente) em vez de abrir dentro da operação — combinado como solução provisória até essas telas serem trazidas pra dentro da Jornada

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

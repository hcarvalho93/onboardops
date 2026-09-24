# Decisões — OnboardOps

Registro de decisões de arquitetura e padrões adotados no projeto. Cada entrada é permanente: se uma decisão for revista depois, adiciona-se uma nova entrada explicando a mudança, sem apagar a anterior.

---

## 2026-09-23 — Redesenho da tela de Operação (Jornada do Cliente), a partir de PDF de especificação

**Contexto:** usuário forneceu um PDF com orientações detalhadas (prints de referência de um outro sistema — AZO/Lovable) pedindo: título de página removido site-wide (só destaque na sidebar), abas da Jornada como primeiro item da página, um card de identificação da operação (nome + nº AZO clicável + selo único de estágio, clicável, com menu de troca), renomear a aba "Atividades" para "Tarefas", botões de atalho (+Tarefa/+Interações/+Pesquisa/+Ativação/+First Value/+Documentação), e uma sidebar de Contexto à direita com altura total da operação, botão de aglutinar virado pra direita, e linhas de Responsáveis (Gerente de Contas, Onboarding, Key Account) no formato avatar+nome+subtítulo+lápis de edição, mais Nível de Prioridade e Etiquetas.

**Decisões de schema:** duas colunas novas em `public.clientes` (aplicadas via SQL Editor do Supabase, confirmado com o usuário antes):
```sql
alter table public.clientes
  add column if not exists etiquetas text[] not null default array[]::text[],
  add column if not exists prioridade text;
```
Mapeadas em `rowToCliente`/`clienteToRow`. Testado ao vivo: upsert de cliente com esses campos retornando 200 do PostgREST.

**Decisão — "Gerente de Contas" continua texto livre, não lista fixa:** a primeira versão tentou transformar `respComercial` (Gerente de Contas) num `<select>` com a mesma lista de Onboarding/Key Account (`ANALISTAS`/`KEY_ACCOUNTS`), pra manter o mesmo formato visual dos três. Bug encontrado em teste ao vivo: valores reais já existentes (ex. "Paulo Roberto") não estão nessas listas, então o select sempre caía em "—" ao abrir pra editar — silenciosamente pronto pra apagar o valor real se o usuário confirmasse sem notar. Corrigido: `respComercial` volta a ser um campo de texto livre ao clicar no lápis (igual já era no formulário de "Dados da Operação"), só Onboarding e Key Account usam `<select>` (que já são listas fechadas usadas em outros pontos do sistema). **Lição:** ao converter um campo de texto livre pra uma lista fixa, sempre conferir se os valores já cadastrados cabem na lista antes de assumir que cabe — testar com dado real, não só com o caso vazio.

**Decisão — "Regional" do responsável é mock temporário:** não existe hoje nenhum campo de região vinculado a usuário/pessoa no sistema. O usuário confirmou explicitamente usar um valor mockado por enquanto ("depois vamos enriquecer o cadastro dos usuários, vinculando regionais, e-mails, etc."). Implementado como `mockRegional(nome)` — hash determinístico do nome sobre uma lista fixa de 5 regionais, só para ter uma UI plausível; **não é dado real**, deve ser substituído quando o cadastro de usuários ganhar esse campo de verdade.

**Decisão — barra de estágios (pills) substituída por selo único clicável:** o design anterior (`jEstagioBar()`, uma fileira de botões Proposta/Minuta/Aguardando Assinatura/.../Perdido) foi trocado por um único selo colorido com o estágio atual, que abre um menu ao clicar (sem indicar visualmente que é um menu suspenso, por pedido explícito do usuário). `jEstagioBar()` não foi apagada do código — só deixou de ser chamada — caso sirva de referência ou seja reaproveitada depois.

**Decisão — atalhos "+ Pesquisa"/"+ Ativação"/"+ First Value" navegam pra fora da Jornada:** essas três telas (Pesquisa Pós-Kickoff, Ativação Operacional, Time to First Value) ainda são módulos independentes, não abas da Jornada. Os botões de atalho setam `filters.cliente` e navegam pra tela correspondente (que já vem pré-filtrada pelo cliente, reaproveitando o filtro compartilhado). Combinado como solução provisória — o usuário já sinalizou a intenção de trazer essas telas pra dentro da operação no futuro.

---

## 2026-09-23 — Ajuste fino do layout da Operação (abas coladas no topbar, card real, sidebar de altura total)

**Contexto:** após o primeiro round do redesenho acima, o usuário pediu 3 ajustes visuais, com prints de referência: (1) abas coladas no topbar, sem espaço morto, no estilo de controle segmentado (pill) do print; (2) os itens soltos (nome, selo, meta, botões) dentro de um card de verdade, com borda/sombra, do mesmo formato dos demais cards do sistema; (3) a sidebar de Contexto encostando no topbar e indo até o fim da tela — igual à sidebar de navegação esquerda.

**Decisão — `#pageHead` escondido só na Jornada com cliente aberto:** o `.page-head` (cabeçalho de página compartilhado por todas as telas, já sem título desde o round anterior) ainda ocupava um espaço morto fixo (padding + sombra) mesmo vazio, porque filtros/título ficam ocultos quando um cliente está aberto na Jornada. Adicionado `id="pageHead"` e uma classe `.jhead-hidden` que some com ele. Como esse elemento é compartilhado, a lógica precisa ser simétrica: `App.go()` sempre REMOVE a classe no início (rede de segurança pra qualquer tela) e `renderJornada()` ADICIONA a classe só no ramo de detalhe de cliente e REMOVE no ramo de lista/kanban (cobre o caminho de `fecharCliente()`, que não passa por `go()`). Testado: navegar Jornada→Dashboards restaura o cabeçalho normalmente.

**Decisão — abas viraram controle segmentado (pill), não mais abas de sublinhado:** novo estilo `.jtabs`/`.jtab`, visualmente igual ao print de referência (Executivo/Operacional/Serviços/Minutas/Perdas) — container cinza claro arredondado, aba ativa em caixa branca com sombra, inativas em texto cinza sem fundo. Distinto do `.dash-tabs`/`.dash-tab` já existente no Dashboard (que usa fundo azul na aba ativa) — não reaproveitado de propósito, porque o print pedia especificamente o visual branco/claro.

**Decisão — reestruturação do grid da Operação:** `.jtabs-row`, o card (`.jcard`, agora também com `class="card"` pra herdar o visual padrão de card do sistema) e o painel da aba ativa (`.jpanel`) foram movidos pra dentro de uma nova coluna `.jmain`, junto do `.jctx` (Contexto) no mesmo grid `.jbody` — antes o card/abas ficavam FORA do grid, então o Contexto só acompanhava a altura do painel da aba, não do card+abas. Com `.jctx` usando `position:sticky;top:var(--topbar-h);height:calc(100vh - var(--topbar-h))` — o mesmo padrão já usado pela sidebar de navegação esquerda — o Contexto agora encosta no topbar e vai até o fim da tela, independente do tamanho do conteúdo da aba ativa.

---

## 2026-09-23 — Segunda rodada de ajuste fino (abas 100% coladas, sidebar fixa de verdade, estágio + SLA)

**Contexto:** teste ao vivo do usuário no navegador real revelou 3 problemas que o teste anterior (via `javascript_exec` no Chrome remoto) não pegou: (1) ainda sobrava um respiro visível entre o topbar e as abas — o `.page-head` já estava escondido, mas o `.content` (container compartilhado por todas as telas) mantinha seu próprio `padding-top:28px`; (2) a sidebar de Contexto (`position:sticky`) "mexia" ao rolar a página no navegador real do usuário, mesmo já reproduzindo o mesmo padrão da sidebar de navegação; (3) pediu botões com "caixa" visível nos atalhos (+ Tarefa etc.), o selo de estágio posicionado à esquerda do card, e um texto discreto de SLA ("20 dias nesta etapa").

**Decisão — zero-gap via `#mainContent`:** adicionado `id="mainContent"` no `.content` e uma segunda classe `.jhead-hidden` que zera `padding-top` nele, alternada nos mesmos 3 pontos já usados pro `#pageHead` (`App.go()`, ramo de lista e ramo de detalhe do `renderJornada()`). Os dois elementos (`#pageHead` e `#mainContent`) agora sempre alternam juntos.

**Decisão — sidebar de Contexto trocada de `sticky` pra `fixed`:** o usuário relatou movimento visível no navegador real, então a implementação foi trocada pra `position:fixed;top:var(--topbar-h);right:28px;bottom:0;width:272px` — garantidamente parada, nunca acompanha o scroll. Como `fixed` tira o elemento do fluxo do grid, `.jmain` reserva o espaço manualmente com `margin-right:290px` (272px + 18px de gap), e o estado "aglutinado" ajusta os dois valores (`width:44px` / `margin-right:62px`) em vez de mudar `grid-template-columns`. O alinhamento com a borda direita do conteúdo (`right:28px`) usa o mesmo padding que `.content` já tem — funciona com precisão nas larguras de tela mais comuns; em monitores muito largos (acima do `max-width:1720px` do conteúdo), pode sobrar um respiro maior entre o conteúdo centralizado e a sidebar — aceito como troca razoável pra evitar cálculo dinâmico de centralização via JS.

**Decisão — botões de atalho sem `ghost`:** `.btn.ghost` no sistema é proposital sem borda (texto+ícone soltos). Bastou remover o modificador `ghost` dos 6 botões (`class="btn sm"`), reaproveitando o estilo padrão do `.btn` (borda fina, sombra sutil) já usado no resto do app — sem CSS novo.

**Decisão — selo de estágio à esquerda + SLA:** o selo (`jstage-badge`) e o texto de SLA (`jstage-sla`) viraram o primeiro bloco de `.jcard-top`, antes do nome/número — nome e número viraram um sub-bloco `.jcard-title` ao lado. SLA calculado por `diasNaEtapa(c)`: busca no histórico a entrada mais recente com `campo==='Estágio da Negociação'` pra esse cliente (data da última troca de estágio) e cai pra `c.criadoEm` se nunca mudou; usa `daysBetween` já existente no projeto. **Bug pego no teste:** a primeira versão usava `h.iso` direto (timestamp completo, ex. `2026-09-23T16:58:...`) — `daysBetween`/`parseD` esperam data pura (`AAAA-MM-DD`), então sempre dava "—". Corrigido com `h.iso.slice(0,10)`.

---

## 2026-09-23 — Terceira rodada: alinhamento fino pós-teste no navegador real

**Contexto:** o usuário testou no Chrome real (não no ambiente remoto de teste) e mandou print com anotação em verde marcando desalinhamento no topo/fim da sidebar de Contexto, além de pedir: botões com caixa visível, o selo de estágio ("status") alinhado à direita do card (revisando a decisão anterior de deixá-lo à esquerda), Criado em/Última atualização organizados abaixo do selo+SLA, e corrigir o desalinhamento entre os cards "Últimas Interações" (texto longo demais, estourando a altura do card) e "Informações do Cliente" (título quebrando em 2 linhas).

- `.jctx` (fixed) ganhou respiro simétrico: `top:calc(var(--topbar-h) + 14px)` e `bottom:14px` (antes eram `top:var(--topbar-h)`/`bottom:0`, colados nas bordas), pra alinhar com o respiro natural das abas/cards ao lado.
- `.jcard-top` virou `justify-content:space-between`: bloco esquerdo (`jcard-left` — nome, nº AZO, meta de Gerente/Onboarding/Key Account) e bloco direito (`jcard-right` — selo de estágio, SLA, Criado em/Última atualização, todos alinhados à direita). Isso **substitui** a decisão da rodada anterior (selo à esquerda) — registrado aqui como correção explícita a pedido do usuário, sem apagar a entrada anterior.
- Botões de atalho já tinham perdido o `ghost` na rodada passada; mantido.
- `.crm-main` (usado nos 4 mini-cards do topo — Últimas Interações/Atividades/Próximos Prazos/Pendências) ganhou uma classe `.crm-clamp` (`-webkit-line-clamp:2`) pro texto do item, aplicada por enquanto só em Últimas Interações (a única com texto livre longo o suficiente pra estourar) + um link "Ver mais..." que leva pra aba Interações. Como a classe é compartilhada pelos 4 cards, qualquer um deles fica protegido contra o mesmo problema se o texto crescer no futuro.
- `.jgrid .card-head h3` ganhou `white-space:nowrap;overflow:hidden;text-overflow:ellipsis` — evita títulos de 2 linhas desalinhando a altura dos cards de uma fileira (caso do "Informações do Cliente", que ficou mais estreito depois da sidebar fixa tomar espaço). Título completo continua acessível via `title=""` no hover.

---

## 2026-09-23 — Quarta rodada + causa raiz real do desalinhamento das grades de card

**Contexto:** usuário reportou, de novo com print real: abas somem ao rolar a página (pediu fixas), card de cabeçalho "largo" demais (reduzido o padding), e a fileira de mini-cards (Últimas Interações etc.) e a fileira de "Informações do Cliente" continuavam desalinhadas mesmo após a correção anterior (truncar título). Também pediu renomear a aba "Dados da Operação" para "Ciclos da Operação".

- `.jtabs-row` virou `position:sticky;top:var(--topbar-h)` com `background:var(--bg)` — fica visível o tempo todo ao rolar a página, testado (posição idêntica antes/depois do scroll).
- `.jcard` com padding reduzido (`18px 20px`→`14px 18px`), título menor (19px→17px) e gaps internos mais justos — card mais compacto.
- **Causa raiz real do desalinhamento (achada só agora):** existe uma regra global antiga, `.card + .card,.card + .kpi-grid,.kpi-grid + .card{ margin-top:16px; }` — pensada pra dar espaçamento vertical entre cards EMPILHADOS (a maioria das telas do sistema usa isso). Ela também casava com os cards dentro de `.crm-grid`/`.jgrid` (que são `.card` irmãos lado a lado, não empilhados), empurrando o 2º/3º/4º card de cada fileira 16px pra baixo — e como o grid usa `align-items:stretch`, isso aparecia como "card mais baixo/desalinhado" em vez de um espaço vazio óbvio, o que enganou o diagnóstico anterior (a correção de truncar título ajudou a esconder o sintoma em "Informações do Cliente" mas não resolveu a causa). **As duas rodadas anteriores tentaram consertar sintoma (título, `align-items:stretch` explícito) sem achar essa regra.** Corrigido com seletor mais específico, sem tocar a regra global: `.jbody .crm-grid > .card,.jbody .jgrid > .card{margin-top:0}`. Testado: as 4 alturas de cada fileira ficaram idênticas nas duas grades.
- Aba "Dados da Operação" renomeada para "Ciclos da Operação" (só o rótulo da aba; o botão "Salvar Dados da Operação" dentro dela não foi mexido).

**Lição reforçada:** a mesma classe (`.card`) compartilhada entre contextos de empilhamento vertical e grades horizontais é a origem de bugs de alinhamento sutis — sempre que um `.card` aparecer "descolado" de seus vizinhos numa grade, verificar primeiro se uma regra de espaçamento entre irmãos (`+`/`~`) está vazando pra esse contexto antes de mexer no conteúdo interno do card.

---

## 2026-09-23 — Reorganização do formulário de Nova Operação, Ativo, CNPJ automático, Inspetor e Serviços

**Contexto:** início do trabalho na "geração da proposta" (fluxo de Nova Operação). Pedido grande, várias frentes independentes.

**Nova Operação — cabeçalho reorganizado:** campo de busca de cliente (`jornada.campo.buscar-cliente`) ganhou destaque visual (ícone de lupa, caixa com borda, cresce até 300px — `.op-busca-box`), alinhado na mesma linha com Número da Operação, Status, Classificação, Cliente Elite e Tipologia. **Cliente Elite** deixou de ser checkbox e virou `<select>` Sim/Não (mantendo `_opDraft.elite` como booleano — o `onchange` monta um objeto `{type:'checkbox',checked:...}` pra reaproveitar `opFieldChange` sem alterar a função compartilhada). Linha de baixo: Nome Comercial, Razão Social, CNPJ, Cidade, UF, Observações.

**CNPJ automático:** novo utilitário `App.formatCnpj(v)` — extrai só dígitos e monta `00.000.000/0000-00` progressivamente. Aplicado via `onblur` (não `onchange`, pra evitar corrida entre os dois eventos) no CNPJ da Nova Operação e no CNPJ do Ativo (`ativoAccordionMarkup`, ambos prefixos `opAtivo`/`cadAtivo`).

**Ativo — `ativoAccordionMarkup()` reestruturado:**
- Nome do Empreendimento e Razão Social agora usam `.ativo-wide` (`grid-column:span 2` dentro do `.ativo-grid` de `minmax(150px,1fr)`) — cabem nomes longos.
- "Sem nome definido" e "Empresa não constituída" saíram de células próprias do grid e foram pra dentro do campo Nome do Empreendimento, como uma linha discreta (`.ativo-check-row`) logo abaixo do input.
- Localização: Cidade primeiro, Estado (UF) depois com largura reduzida (`.ativo-narrow`, ~74px, sem ficar menor que o rótulo "Estado"), e um campo `Endereço` novo ocupando o resto da linha — o campo já existia no modelo de dados (`a.endereco`, coluna `endereco` já em `ativos` no Supabase, usada em outro formulário legado) só não estava nessa tela.
- Grupo "Cronograma da Obra" trocou de posição com "Números do Empreendimento" (cronograma agora vem antes). "Status do Ativo" saiu de Números do Empreendimento e virou o primeiro campo de Cronograma, antes de "Lançamento".

**Inspetor de Desenvolvimento — painel não soma mais instantaneamente ao trocar de alvo:** antes, mover o mouse pra fora do elemento hovado chamava `removePanel()` na hora, então o caminho até o painel (que abre a ~16px do canto do cursor) quase sempre cruzava outro elemento e fechava o painel antes do clique. Agora existe um `removeTimer` de 1s de tolerância: o painel só some se, depois de 1s, o mouse não tiver entrado nele (`panelEl.contains(e.target)` cancela o timer). Testado via dispatch de `mousemove` sintético: painel confirmado ainda presente 400ms depois de mudar de alvo (antes sumia na hora).

**Correção rápida (mesmo dia) — larguras do formulário de Nova Operação/Ativo:** o campo de busca (`f-search`) e a Razão Social (`f-grow`) tinham `flex:1`, então cada um sozinho numa fileira com bastante espaço sobrando virava enorme (essa é a causa do "campo de busca parece sobreposto/quebrado" reportado pelo usuário — não era sobreposição de verdade, era o campo crescendo demais e empurrando os vizinhos pra longe). Trocado por larguras fixas: busca 280px, Razão Social nova classe `f-xl` (300px), CNPJ subiu de `f-sm`(140px) pra `f-md`(200px, cabe o placeholder inteiro sem cortar). No Ativo: Cidade ganhou `ativo-md` (220px, era 1fr igual às outras), Endereço trocou `field full` (força quebra de linha) por `ativo-wide` (2 colunas, mas na mesma fileira de Cidade/Estado).

**Correção — causa raiz real do "campo de busca com borda dupla":** não era largura, era especificidade CSS de novo (mesma classe de bug já documentada nesta seção). `.op-busca-box input{border:none;background:none;...}` tinha a mesma especificidade de `.field input,.field select,...{border:1px solid var(--line-strong);background:var(--surface);padding:9px 11px;...}` (a regra global de todo input dentro de `.field`) — e a global vem DEPOIS no arquivo, então vencia, devolvendo pro `<input>` a própria borda/fundo/padding *dentro* do `.op-busca-box` que já tinha os seus — duas caixas visualmente empilhadas. Corrigido escopando `.op-busca-wrap .op-busca-box input` (mais específico, não depende de ordem no arquivo).

**Correção — Cidade/UF "grudados" no Ativo:** a tentativa anterior de aumentar/diminuir campos individuais dentro do `.ativo-grid` (que é `repeat(auto-fit,minmax(150px,1fr))`, colunas sempre iguais) usava `width` fixo maior que a própria coluna — o campo Cidade (220px) estourava a largura da sua faixa e invadia visualmente a faixa vizinha (Estado), sem respeitar o `gap`. Corrigido tirando Cidade/Estado/Endereço do grid de colunas iguais: viram uma fileira flex própria (`.ativo-loc`, `grid-column:1/-1`) com largura de cada campo controlada diretamente (Cidade 220px, Estado 80px, Endereço cresce pra preencher o resto) — sem risco de estourar coluna porque não são mais colunas de grid.

**Serviços — ordem alfabética em colunas + "mais solicitados":** `servicoResultsMarkup` foi reescrita pra absorver a filtragem (antes em `servicosCatalogFiltrado`, removida). Com busca vazia (campo recém-clicado, antes de digitar), mostra os 5 serviços mais usados no momento — contados varrendo `servicos[]` de todos os ativos de todos os clientes já cadastrados; se ainda não há uso suficiente registrado (app novo), completa em ordem alfabética. Com busca preenchida, ordena alfabeticamente e aplica `ordemColunas()` — uma transposição que faz a leitura em 4 colunas ficar alfabética de cima pra baixo em cada coluna (A,E,I,M / B,F,J,N / ...) em vez de esquerda-pra-direita por linha, mantendo o mesmo grid CSS de 4 colunas já existente (só muda a ORDEM dos itens no HTML, não o layout).

**Serviços — removidos os chips duplicados abaixo do catálogo:** `servicosChipsMarkup()` parou de ser chamada (função ficou definida mas sem uso, não apagada). O catálogo (`servicoResultsMarkup`) agora é sempre clicável — clicar num serviço selecionado **remove** (alterna), em vez de precisar do chip separado pra isso. Estado "selecionado" ficou bem mais evidente: fundo verde (`--green-bg`), borda verde, nome em verde e negrito (antes era só um leve `opacity:.6`, que ironicamente deixava o item selecionado com aparência mais apagada). Hover num item já selecionado fica vermelho, sinalizando "clique pra remover". Testado ao vivo: alternar Gestão de Carteira liga/desliga corretamente e atualiza o contador do cabeçalho.

---

## 2026-09-22 — Padrão de identificadores do Inspetor de Desenvolvimento

**Contexto:** construção de um inspetor visual de desenvolvimento (F9) para apontar elementos da tela por identificador único, em vez de descrição de posição/texto.

**Decisão:** todo elemento relevante recebe um atributo `data-id` escrito diretamente no código-fonte (nunca gerado em runtime), seguindo o formato:

```
tela.tipo.nome
```

- Minúsculas, sem acento, sem espaço, palavras separadas por hífen.
- Tipos em português: `botao`, `aba`, `card`, `campo`, `tabela`, `filtro`, `grafico`, `menu`, `modal`, `secao`, `lista`, `indicador`, `selo`.
- Único no projeto inteiro — antes de criar um novo `data-id`, confirmar por busca no arquivo que não existe outro igual.
- Não usar posição na tela nem texto visível como base do nome (ambos mudam).
- O identificador marca o **template/componente no código**, não cada instância renderizada. Ex.: `pipeline.card.cliente` é o mesmo `data-id` nos N cards de cliente do Kanban — todos vêm do mesmo template em `kCard()`. Isso é intencional: o objetivo é localizar o ponto no código-fonte, não distinguir instâncias individuais de dados.

**Caso especial — componente compartilhado entre telas:** `ativoAccordionMarkup()` é a mesma função de markup usada tanto na Jornada (Nova Operação) quanto no Cadastro (Ativos do Cliente) — não são cópias, é o mesmo template. Para esses casos, o prefixo de "tela" é substituído por um prefixo neutro do próprio componente (ex.: `ativo.card.principal`), em vez de forçar `jornada.*` ou `cadastro.*`. Prefixos de tela (`jornada.*`, `cadastro.*`, `dashboard.*` etc.) são reservados para elementos exclusivos daquela tela.

**Exemplos validados com o usuário em 2026-09-22:**
- `jornada.botao.adicionar-operacao`
- `dashboard.indicador.health-score-medio`
- `jornada.aba.dados-da-operacao`
- `pipeline.card.cliente`
- `cadastro.campo.razao-social`

**Escopo de cobertura:** todo elemento clicável, campo de formulário, card, indicador, gráfico, tabela, aba e seção principal recebe `data-id`. Texto decorativo e ícone solto não precisam. Aplicação é **gradual, por tela**, sempre que uma tela for mexida — nunca uma varredura geral do projeto de uma vez.

**Perfil de acesso:** o modo de desenvolvimento (F9) é liberado apenas em `location.hostname` local (`localhost`/`127.0.0.1`) ou para usuários com perfil `Gestão Executiva`. Essa checagem roda no navegador — não é uma barreira de segurança contra inspeção de código-fonte (o app é estático e público via GitHub Pages), apenas evita que o módulo carregue/apareça para o usuário comum. O inspetor não expõe dado de cliente, só metadados de UI (identificador, tipo, cor, posição).

---

## 2026-09-22 — Prefixos neutros confirmados ao aplicar na tela piloto (Jornada do Cliente)

Ao aplicar `data-id` na Jornada do Cliente (passo 3), mais funções de markup compartilhadas entre telas foram encontradas além do `ativoAccordionMarkup` já registrado acima. Cada uma recebeu um prefixo neutro (sem `tela.*`), seguindo a mesma regra:

- `atividade.*` — `kanbanAtividades()`, `atividadeCard()`, `atividadeList()` (usados na Jornada e na tela de Pendências e Atividades).
- `interacao.*` — `intTimeline()` (usado na Jornada e na tela de Interações do Cliente).
- `alteracao.tabela.*` — `histTable()` (usado na Jornada e na tela de Histórico de Alterações).

Regra geral confirmada: **qualquer função de markup chamada a partir de mais de uma tela usa prefixo neutro do domínio/conceito, nunca o nome de uma tela específica.**

Correção de nomenclatura: `atividade.kanban.status` foi renomeado para `atividade.lista.status` — `kanban` não é um dos tipos aprovados; o tipo correto para esse componente é `lista`.

---

## 2026-09-23 — Inspetor: tipos "amplos" só respondem ao ponto exato do mouse

**Contexto:** ao testar o inspetor na tela piloto, passar o mouse num vão vazio dentro do Kanban da Jornada (fora de qualquer card) evidenciava a seção inteira (`jornada.secao.kanban-negociacao`), cobrindo os 5 quadrantes de uma vez — indesejado. O pedido: hover dentro de um card deve evidenciar só aquele card; hover fora de qualquer item marcado deve mostrar "sem identificador" com destaque só no ponto exato do mouse.

**Decisão:** os tipos `secao`, `lista` e `menu` são "amplos" — servem para marcar grandes áreas que agrupam muitos itens menores. Para esses tipos, o inspetor só reconhece o identificador quando o mouse está **exatamente** sobre o elemento marcado (não ao subir a árvore a partir de um filho qualquer). Os demais tipos (`card`, `botao`, `campo`, `selo`, `indicador`, `grafico`, `tabela`, `aba`, `modal`, `filtro`) continuam subindo normalmente a partir de qualquer filho, porque tudo dentro deles pertence ao mesmo item (ex.: o nome do cliente dentro do card é o card).

**Efeito colateral desejado:** ao hover num ponto sem identificador (seja por não ter `data-id` algum, seja por estar dentro de uma "secao"/"lista"/"menu" mas fora do elemento exato), o destaque visual passa a contornar só o elemento real sob o cursor (por menor que seja), nunca uma área ampla — reforça "sempre o ponto exato do mouse, a menos que seja um item individual completo".

**Isso não resolve sozinho** o pedido de "identificador individual para número/título" — itens que hoje não têm `data-id` próprio (como o número de um badge, o texto de um título dentro de um card) continuam aparecendo como "sem identificador" até que alguém decida marcá-los individualmente. Ver PENDENCIAS.md.

---

## 2026-09-23 — Inspetor: correspondência sempre exata (revisão da decisão anterior) + novo tipo `texto`

**Contexto:** a decisão anterior (tipos "amplos" vs. subida livre) ainda deixava hover em qualquer ponto de um card (título, badge, contador) evidenciar o card inteiro. O pedido mudou: isso só deve acontecer quando o mouse está exatamente sobre o card (sua própria área, não a de um filho) — cada pedaço de conteúdo deve responder só pelo que é dele.

**Decisão (substitui a distinção "amplo vs. unitário" acima):** o inspetor não sobe mais a árvore em nenhum caso. Só reconhece um identificador quando o elemento sob o cursor tem `data-id` **nele mesmo**. Se não tiver, mostra "sem identificador" e destaca só aquele elemento exato — não importa o tipo do ancestral mais próximo marcado.

**Consequência aceita e esperada:** muitos pontos hoje aparecem como "sem identificador" — não é bug, é porque aquele pedaço específico (um título, um número, um selo) ainda não tem `data-id` próprio. Corrigir isso é marcar o elemento individualmente, não fazer o inspetor "adivinhar" subindo para o pai.

**Novo tipo aprovado: `texto`** — para texto simples, com informação relevante, mas que não é botão, campo, indicador (número/métrica) nem selo (status/categoria). Lista de tipos agora: `botao`, `aba`, `card`, `campo`, `tabela`, `filtro`, `grafico`, `menu`, `modal`, `secao`, `lista`, `indicador`, `selo`, `texto`.

**Exemplo aplicado — card de cliente no Kanban da Jornada (`jcliKCard`):** antes só o card tinha `data-id`; agora cada pedaço interno tem o seu:
- `jornada.texto.nome-cliente-kanban` — nome do cliente
- `jornada.texto.info-cliente-kanban` — linha de tipologia/Key Account
- `jornada.selo.etapa-cliente-kanban` — selo de etapa
- `jornada.selo.health-score-kanban` — selo de health score
- `jornada.indicador.atividades-abertas-kanban` — contador de atividades abertas

Esse é o padrão a seguir daqui pra frente: ao marcar um card ou componente, marcar também suas partes internas relevantes (texto, selo, indicador), não só o contêiner.

**Correção técnica:** marcar um `badge()` (selo) precisa do `data-id` no próprio `<span class="badge">`, não numa `<span>` envolvendo ele — como o badge preenche todo o espaço, a correspondência exata (decisão acima) nunca "achava" o envelope por fora. A função `badge(txt, tone, dataId)` em `index.html` ganhou um 3º parâmetro opcional pra isso, seguindo o mesmo padrão já usado em `kpi(cls, lbl, val, unit, foot, dataId)`.

---

## 2026-09-23 — Painel: termo em inglês de cada tipo

**Contexto:** o usuário está aprendendo vocabulário de PM e quer conseguir nomear os itens da tela corretamente — inclusive em inglês, já que boa parte do vocabulário técnico/produto circula em inglês.

**Decisão:** o painel do inspetor agora mostra o termo em inglês ao lado do tipo (ex.: "selo · en: badge"). Mapa `TIPO_EN` em `ferramentas-dev/inspector.js`, ao lado do `TIPOS` (descrições em português). Mantido discreto (fonte menor, cor apagada) pra não engordar o painel.

**Nota de nomenclatura:** a própria caixa flutuante que mostra essas informações se chama **painel** (ou "painel do inspetor") na nossa especificação — não "card". Em vocabulário de UX, esse padrão (aparece perto do cursor, ao pairar o mouse, com conteúdo rico) é comumente chamado de **popover**.

---

## 2026-09-23 — Novo prefixo neutro `global.*` para o chrome fixo do app (topbar, sidebar, barra de filtros)

**Contexto:** para fechar 100% da cobertura da Jornada do Cliente (aprovado pelo usuário: "Pode fazer 100% da Jornada"), faltavam três blocos que aparecem em praticamente toda tela do sistema, não só na Jornada: a barra superior (`topbar`), o menu lateral (`sidebar`/`nav`) e a barra de filtros globais (`buildFilters()`). Nenhum prefixo de tela (`jornada.*`) fazia sentido pra eles, pelo mesmo raciocínio já usado para `ativo.*`/`atividade.*`/`interacao.*`/`alteracao.tabela.*`.

**Decisão:** criado o prefixo neutro `global.*` para elementos de chrome do aplicativo — presentes em (quase) todas as telas, não pertencem a nenhuma tela específica:
- Topbar: `global.botao.abrir-menu` (hambúrguer), `global.texto.marca-app` (logo/marca), `global.campo.busca-global` (busca), `global.lista.resultados-busca-global`, `global.botao.relatorios`, `global.botao.alternar-tema`, `global.botao.notificacoes`, `global.selo.notificacoes-pendentes`, `global.lista.notificacoes`.
- Menu do usuário (`buildUserChip`): `global.botao.abrir-menu-usuario`, `global.menu.usuario`, `global.texto.identificacao-usuario`, `global.botao.configuracoes`, `global.botao.alternar-tema-menu`, `global.botao.sair`.
- Sidebar: `global.menu.navegacao-principal` (tipo `menu`, o `<nav>`), e por item de navegação (`buildNav()`, gerado dinamicamente a partir do array `NAV`): `global.botao.nav-${id-em-kebab-case}` + `global.selo.nav-contagem-${id-em-kebab-case}` para o contador. Único id em camelCase no `NAV` é `cadastroAtivos` → convertido para `cadastro-ativos` via regex (`id.replace(/([A-Z])/g,'-$1').toLowerCase()`).
- Barra de filtros globais (`buildFilters()`): `global.filtro.buscar-cliente`, `global.filtro.key-account`, `global.filtro.onboarding`, `global.filtro.produto`, `global.filtro.tipologia`, `global.filtro.etapa`, `global.filtro.status`, `global.filtro.health-score`, `global.botao.aplicar-filtros`, `global.botao.limpar-filtros`.

**Verificação:** 159 `data-id` no total no projeto (eram 130 antes desta rodada), zero duplicatas (checagem via script PowerShell). Testagem visual via hover em navegador não foi possível nesta rodada — exigiria login real no app, e digitar senha em nome do usuário é uma ação que não realizo por padrão de segurança; a verificação foi feita por revisão de código + checagem de duplicatas.

**Com isso, a Jornada do Cliente está 100% coberta** pelo Inspetor de Desenvolvimento, incluindo o chrome global visível nela.

---

## 2026-09-23 — Correção: colunas do Kanban de negociação e cabeçalho do cliente também precisavam de `data-id`

**Contexto:** ao testar manualmente o "100% da Jornada" acima, o usuário encontrou "sem identificador" em três pontos do Kanban de negociação (`kanbanNegociacao()`): o título da coluna (ex. "Aguardando Assinatura"), o contador de itens da coluna, e a área vazia (traço "—") quando a coluna não tem clientes. A seção inteira do Kanban e o card de cliente já tinham `data-id`, mas a coluna em si (nível intermediário) tinha ficado de fora — mesmo padrão de granularidade já aplicado ao card, só que num nível acima.

**Decisão:** aplicado o mesmo padrão granular:
- `jornada.lista.coluna-kanban` (tipo `lista`) — cada coluna do Kanban (ex.: Proposta, Minuta, Aguardando Assinatura). Mesmo id nas duas ocorrências em código-fonte (`kanbanNegociacao()` tem duas construções de coluna — a especial "Sem estágio" e as colunas normais por status) porque é o mesmo componente/conceito, não duas coisas diferentes.
- `jornada.texto.titulo-coluna-kanban` — título da coluna.
- `jornada.indicador.contagem-coluna-kanban` — contador de itens da coluna.
- `jornada.texto.coluna-vazia-kanban` — mensagem "—" quando a coluna está vazia.

De passagem, também corrigido o cabeçalho da tela de detalhe do cliente (`renderJornada()`, quando um cliente está selecionado), que tinha o mesmo problema: `jornada.texto.nome-cliente-detalhe` (nome do cliente), `jornada.selo.health-score-detalhe` e `jornada.selo.etapa-cliente-detalhe` (selos ao lado do nome).

**Lição:** ao aplicar granularidade num componente com hierarquia (seção → coluna → card → partes do card), é preciso conferir *todos* os níveis intermediários, não só o container mais externo e o item mais interno. Verificação: 167 `data-id` estáticos no arquivo, sem duplicatas inesperadas (os 2 casos de repetição intencional do template de coluna foram conferidos manualmente).

---

## 2026-09-23 — Varredura item a item da Jornada: padrão sistemático de título de card sem `data-id`

**Contexto:** usuário pediu uma checagem item a item ("tanto no kanban quanto dentro da operação") em vez de só testar pontos avulsos. Reli todas as funções de markup usadas pela Jornada do Cliente (`jAtivos`, `jGeral`, `crmPanel`, `jOperacao`, `jPendencias`, `jDocs`, `whatsTimeline`, `kanbanAtividades`) e encontrei um padrão recorrente: o `<h3>` (ou `<h2>`/`.crm-h`) de título dentro de um `.card-head` estava marcado só no container (`.card`), não nele mesmo. Pela regra de correspondência exata (sem subir a árvore, decisão de 2026-09-23 acima), passar o mouse exatamente em cima do texto do título — não na borda do card — sempre resultava em "sem identificador". Esse era o mesmo tipo de furo já corrigido para as colunas do Kanban, só que num lugar diferente da árvore.

**Também encontrado:** `kanbanAtividades()` (usado na aba Atividades da Jornada e na tela de Pendências e Atividades) tinha exatamente o mesmo furo de coluna já corrigido em `kanbanNegociacao()` — não tinha sido replicado lá. Corrigido com os mesmos nomes de padrão, prefixo neutro `atividade.*`: `atividade.lista.coluna-kanban`, `atividade.texto.titulo-coluna-kanban`, `atividade.indicador.contagem-coluna-kanban`, `atividade.texto.coluna-vazia-kanban`.

**Decisão/correção aplicada — títulos de card agora marcados em todos os pontos da Jornada:**
- `jAtivos`: título da seção, "Distribuição por Estado/Tipologia", "Status dos Ativos"; linhas da tabela de ativos também ganharam `data-id` (`jornada.tabela.linha-ativo`), espelhando o padrão já usado em `alteracao.tabela.linha`.
- `crmPanel`: título dos 4 mini-cards (Últimas Interações, Últimas Atividades, Próximos Prazos, Pendências em Aberto).
- `jGeral`: título dos 5 cards (Informações do Cliente, Ciclo de Negociação, Ciclo de Implantação, Indicadores, Atividades Abertas).
- `jOperacao`: título dos 3 cards de formulário; cada chip de "Produtos Contratados" ganhou `jornada.botao.toggle-produto` (era só o container que tinha id).
- `jPendencias`, `jDocs`, `whatsTimeline`: título de cada card; linhas de documento anexado ganharam `jornada.texto.item-documento`.
- Aba "Atividades" da Jornada (dentro de `jPanel`) e cabeçalho "Jornada do Cliente" da tela-lista também receberam `data-id` no título.

**Lição geral para o restante do projeto (Passo 5):** ao tagear qualquer `.card-head` daqui pra frente, marcar sempre três coisas — o card, o `<h3>` do título, e o botão de ação (se houver) — nunca só o card. É o erro mais fácil de repetir porque o card "parece" coberto visualmente, mas o título dentro dele não responde sozinho.

**Verificação:** 197 `data-id` estáticos no arquivo (eram 167), sem duplicatas inesperadas.

---

## 2026-09-23 — Mudança de estratégia: cobertura "boa o suficiente" em vez de 100% exaustivo

**Contexto:** mesmo após a varredura item a item acima, ainda restam alguns pontos "sem identificador" na Jornada (confirmado pelo usuário testando com F9). O mecanismo de seleção em si (correspondência exata, destaque no elemento certo) está funcionando corretamente — o que falta é só cobertura de marcação, não um bug de comportamento.

**Decisão:** abandonar a meta de 100% exaustivo por varredura ativa. Daqui pra frente, `data-id` é adicionado **sob demanda**: quando o usuário, durante o uso normal do Modo Dev, sentir falta de um identificador num ponto específico, ele pede e eu marco aquele ponto. Não há mais rodada de "vamos garantir que não falta nada" por tela — a tela evolui organicamente conforme for usada.

**Motivo:** o custo de perseguir 100% dos elementos (incluindo casos raros, texto secundário, ícones soltos) cresce muito mais rápido que o benefício — o objetivo do Inspetor é ajudar o usuário a localizar/nomear elementos que ele *realmente* vai referenciar no dia a dia, não catalogar cada pixel da tela.

**Efeito no Passo 5 (demais telas):** mesma lógica passa a valer — ao entrar numa tela nova, aplicar o padrão de granularidade já estabelecido (container + partes relevantes: título, botão, campo, indicador) nos elementos óbvios, sem perseguir cobertura perfeita; buracos remanescentes são preenchidos sob demanda.

---

## 2026-09-24 — Reestruturação da aba Visão Geral (Jornada do Cliente)

**Contexto:** pedido do usuário, em duas mensagens com anexos, pra consolidar a Visão Geral da operação: menos abas superiores, um resumo aglutinável de pendências/tarefas no lugar dos 4 mini-cards antigos, indicadores movidos pro rodapé do sidebar de Contexto (separados dos campos editáveis), renomear "Informações do Cliente" pra "Cliente", e trocar "Ciclo de Negociação" de lugar por um novo card de "Serviços" (por ativo).

**Mudanças:**
- Abas superiores da Jornada reduzidas de 8 pra 5: `Visão Geral / Ciclos da Operação / Ativos / Tarefas / Documentos`. Pendências, Interações e Alterações saem do nível de aba — viram sub-filtros dentro do novo widget de linha do tempo da Visão Geral.
- `crmPanel()` (cards "Últimas Interações / Últimas Atividades / Próximos Prazos / Pendências") removido por completo, sem call sites restantes. CSS antigo (`.crm-*`) deixado no lugar (regra morta inofensiva, mesmo padrão já usado antes pro `jEstagioBar`), exceto a parte de `.jbody .crm-grid > .card,.jbody .jgrid > .card{margin-top:0}` que continua valendo — ela também cobre `.jgrid`, que segue em uso.
- Substituído por três funções novas: `jPendResumo()` (resumo aglutinado, expande/recolhe, mostra contagem de pendências vs. tarefas), `jTimelineWidget()` (linha do tempo com 4 sub-abas: Geral/Tarefas/Interações/Alterações) e `jServicosResumo()` (lista de serviços por ativo, com rolagem própria — `max-height:220px;overflow-y:auto`).
- **Heurística de separação pendência vs. tarefa:** `activities[].origem === 'Pendência Operacional'` conta como pendência; toda outra atividade em aberto conta como tarefa. É uma leitura interpretativa sobre um campo que já existia (`origem`), não uma distinção nova no schema — se o usuário quiser outro critério no futuro, é só trocar essa condição em `jPendResumo()`.
- Card "Indicadores" saiu do grid principal e foi pro rodapé do sidebar de Contexto (`.jctx-indic`, com separador visual acima pra marcar que dali pra baixo é só leitura, diferente dos campos editáveis de cima).
- Grid principal da Visão Geral reordenado: Cliente (renomeado, era "Informações do Cliente") → Serviços (novo) → Ciclo de Negociação → Ciclo de Implantação.
- `.jcard` (card de identificação no topo da operação) compactado a pedido do usuário ("de 4 blocos pra 3 blocos" — nova convenção de tamanho relativo combinada nesta conversa): `padding` 14px 18px→10px 16px, `margin-bottom` 16px→12px, título 17px→16px, gaps internos reduzidos.

**Teste:** verificado ao vivo via Claude in Chrome (sessão logada real) em dois clientes reais (CALFTECH e NOVA ALIANÇA): expandir/recolher pendências, as 4 sub-abas da linha do tempo, indicadores reais no sidebar, e o card de Serviços (incluindo teste momentâneo com dados injetados só em memória — nunca gravados no Supabase — pra confirmar que a lista de chips renderiza corretamente; descartado com reload). Sem erros no console em nenhum momento.

---

## 2026-09-24 (2) — Ajustes finos da Visão Geral: alerta visual, card "Cliente" com dados cadastrais, BV mockado em Serviços, limpeza de redundância

**Contexto:** segunda rodada de ajustes no mesmo dia, a partir de feedback do usuário com 2 screenshots comparando o estado antes/depois de fechar o popover do Inspetor.

**Mudanças:**
- `jPendResumo()`: quando há pendências abertas (`nPend>0`), o card ganha a classe `jpend-alert` → fundo `var(--red-bg)` e ícone do relógio em `var(--red)` sobre fundo `var(--surface)` (pra manter contraste). Sem pendências, o card fica neutro (mesmo visual dos outros cards). CSS: `.jpend-alert{background:var(--red-bg);border-color:color-mix(in srgb,var(--red) 24%, var(--line))}`. Também adicionado `.jpend-head .ico` (não existia — o ícone do relógio estava sem nenhum estilo de círculo/cor, porque `.jpend-head` não é `.card-head` e por isso não herdava a regra padrão).
- `.jcard-actions{margin-top}` reduzido de 9px pra 2px — o espaço entre a linha de meta (Gerente/Onboarding/Key Account) e a fileira de botões de atalho estava desproporcional ao resto do card compactado na rodada anterior.
- Card "Cliente" da Visão Geral trocado por completo: em vez de Tipologia/Status/Etapa/Produtos/Key Account/Booked Value, agora mostra só dados cadastrais fixos — Nome Comercial (`c.nomeFantasia`), Razão Social (`c.nome` — nome interno da entidade "cliente" é na verdade a razão social, não o nome comercial), CNPJ, Classificação, Cliente Elite (Sim/Não), Tipologia, Cidade, UF (`c.estado`), Observação (`c.obs`). Status/Etapa já aparecem no selo de estágio do cabeçalho; Produtos/Key Account/Booked Value não fazem parte do pedido desta vez (podem voltar em outro lugar se o usuário sentir falta).
- Card "Serviços": título ganhou um pill `BV R$ X mil/mi` ao lado, calculado por `mockBookedValue(id)` — hash determinístico do id do cliente (mesmo padrão do `mockRegional`), **valor mockado, não persiste, não é um campo real ainda**. Combinado com o usuário: ele vai decidir depois onde esse campo é cadastrado de verdade; até lá, fica só decorativo/ilustrativo.
- Removido `Resp. pela Proposta` do card-resumo "Ciclo de Negociação" e `Resp. Onboarding` do card-resumo "Ciclo de Implantação" (Visão Geral) — informação redundante, já aparece em "Responsáveis" no sidebar de Contexto. **Só os cards-resumo da Visão Geral** — os campos continuam existindo e editáveis normalmente na aba "Ciclos da Operação" (`jOperacao()`), não foram removidos do formulário nem do modelo de dados.
- Dados de teste: populados via console (`window.__OO.DB()` + `window.__OO.save()`, o mesmo caminho de persistência real do app) — 10 ativos com 2–3 serviços aleatórios cada em BARION, CALFTECH e RD VILLE; 2–4 ativos com 1–2 serviços em NOVA ALIANÇA, SOLARIS e "Ricardo De Lacerda Teodoro Ltda"; ativos que já existiam e não tinham serviços ganharam serviços também. Cliente "werwer" propositalmente **não tocado** (é lixo de teste já sinalizado, o usuário pediu pra deixar como está). Sincronizado com Supabase com sucesso (POST 200 em `/rest/v1/ativos`).

**Teste:** verificado ao vivo (Claude in Chrome, sessão logada) — alerta vermelho confirmado com uma pendência injetada temporariamente (descartada depois, nunca persistida); card Cliente com os 9 campos corretos incluindo Observação real; card Serviços com scroll funcionando num cliente de 10 ativos (BARION) e sem scroll num cliente de 2 ativos (SOLARIS); `werwer` confirmado com 0 ativos após a rodada. Sem erros de console.

---

## 2026-09-25 — Serviços: rolagem não preenchia o card, chips trocados por lista de bullets

**Contexto:** com dados de teste reais populados na rodada anterior, o usuário viu o card de Serviços "esticado" pelo `align-items:stretch` do `.jgrid` (pra ficar do mesmo tamanho dos cards vizinhos), mas o conteúdo interno (`.jserv-resumo`) tinha um `max-height:220px` fixo — sobrava um espaço em branco morto entre o fim da lista e o fim do card, e a barra de rolagem parecia "não chegar até o final do container". Também pediu pra trocar a visualização por chip/tag colorido por uma lista simples de bullets (a pedido, com um print de referência), e deixar o BV mais em destaque.

**Causa raiz (mesma classe de bug já documentada antes neste projeto):** um elemento filho com altura fixa (`max-height`) dentro de um pai que foi esticado por flex/grid pro tamanho do maior irmão — a altura do `.card` cresce, mas o conteúdo scrollável interno não acompanha, porque nada ali dentro sabia que podia (ou devia) crescer.

**Fix:** `.jserv-card` (nova classe só no card de Serviços) vira `display:flex;flex-direction:column`; seu `.card-body` também vira flex column com `flex:1;min-height:0`; e `.jserv-resumo` troca o `max-height:220px` fixo por `flex:1;min-height:0;overflow-y:auto` — agora a lista sempre ocupa exatamente a altura que o card esticado deixar disponível, e só nasce barra de rolagem se o conteúdo realmente não couber. `min-height:0` é obrigatório nos dois níveis flex intermediários — sem ele, um filho com `overflow` dentro de um flex item não encolhe, ele força o pai a crescer e a rolagem nunca aparece.

**Visualização:** `jServicosResumo()` reescrita — cada ativo agora mostra nome + tipologia (alinhados nas pontas, mesma linha) e, abaixo, uma lista `<ul>` de verdade (bullets `•`, não mais chips/tags coloridos) com os nomes dos serviços; separador (`border-top`) entre um ativo e o próximo. Layout replicado a partir de um mockup fornecido pelo usuário.

**Vocabulário:** o usuário perguntou se "bullet" era o nome certo pro elemento anterior (os chips coloridos) — não é. *Chip* (ou *tag*) é o nome do elemento em pílula com fundo colorido; *bullet* é o pontinho de marcador de lista (•), que é o que ele queria usar no lugar dos chips. Anotado pra reforçar em [[explain-terms-and-pm-concepts]] se ele confundir de novo.

**BV em destaque:** trocado de `.pill` genérico pra uma classe própria `.jserv-bv` — fundo `var(--green-bg)`, texto `var(--green)` em negrito, fonte um pouco maior (14px) — sem virar um número gigante, só mais legível que o pill neutro anterior.

**Teste:** verificado ao vivo em BARION (10 ativos, card alto — confirmado sem espaço morto, card termina alinhado com os vizinhos) e SOLARIS (2 ativos, card curto — sem rolagem desnecessária nem esticamento estranho). Sem erros de console.

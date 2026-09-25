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

---

## 2026-09-25 (16) — Compilado de 11 ajustes via PDF batelado (motivado por economia de créditos), incluindo aba Serviços, página Tarefas, popover com abas e perfis Middle/Desenvolvedor

**Contexto:** depois de uma pergunta exploratória do usuário sobre o que estava consumindo créditos da sessão (resposta: volume de ceremônia de automação de navegador por ajuste pequeno, não o arquivo único nem a conversa longa), o usuário enviou um PDF compilando 11 pedidos numa rodada só, explicitamente pra "economizar" — com autorização prévia pra eu perguntar se algo não ficasse claro. 4 perguntas de esclarecimento foram feitas via `AskUserQuestion` antes de implementar (escopo do "Middle", significado de "minhas tarefas" = responsável, e outras definições de nav/permissão), todas respondidas antes do início da implementação.

**Grupo A/B — cosméticos e reorganização da Jornada:** `jcard-actions` reduzido de 5 pra 3 botões (Tarefa/Interações/Documentação — Pós-Kickoff/Ativação/First Value removidos, já acessíveis como abas); `.jop-num` perdeu o estilo de pílula (fundo azul-claro, `border-radius:20px`) e passou a ter o mesmo tamanho da fonte do título (`16px`, sem fundo, só sublinhado no hover) — mudança puramente visual, o link pro AZO (`azoProposalUrl`) não mudou; `jcliKCard` (card do Kanban de Negociação, distinto do `kCard` usado no Pipeline) ganhou o prefixo `#<número> | ` no nome quando `c.numeroOperacao` existe.

**Grupo C — nova aba "Serviços" na Jornada:** aba nova (`jServicosPanel`) entre "Ativos" e a renomeada "Atividades" (era "Tarefas" — renomeada de volta porque a nova página de Kanban pessoal, ver Grupo D, assumiu o nome "Tarefas"). Cada ativo do cliente vira um bloco com busca e lista de serviços (`servicoResultsMarkup`, componente já existente, reaproveitado com prefixo novo `jSrv`) — clicar adiciona/remove na hora, salva direto (sem rascunho), permissão via `canAtivos()`. **Erro pego antes de testar:** os métodos do App precisam seguir exatamente a convenção `${prefix}ServicoAdd`/`${prefix}ServicoDel` (não `${prefix}Add`) porque é assim que `servicoResultsMarkup` monta o `onclick` — escrevi errado na primeira tentativa (`jSrvAdd`/`jSrvDel`) e corrigi por releitura do código antes de qualquer teste ao vivo. O card "Ativos e Serviços" (era só "Ativos") ganhou contagem `X Ativo(s) | Y Serviço(s)`. O sidebar de Contexto, bloco "Consolidado", perdeu "Total de Ativos"/"Total de Serviços" (redundante com a aba nova) e manteve só o Booked Value, agora maior (28px). As linhas da aba "Ativos" ficaram clicáveis — expandem um card de detalhe somente-leitura (dados cadastrados do ativo) com botão "Editar" que abre o Cadastro (`App.editCliente`).

**Decisão — cabeçalho do Contexto sem a palavra "Contexto":** o pedido literal era "deixe o botão de aglutinar dentro do container" — só que o CSS existente (`.jbody.jctx-closed .jctx-body{display:none}`) já esconde `.jctx-body` inteiro quando colapsado, e colocar o botão *dentro* dele criaria um cadeado sem chave (impossível reabrir). Resolvido removendo só a palavra "Contexto" e deixando o botão de aglutinar sozinho, alinhado à direita, dentro de um `.jctx-head` que fica estruturalmente **fora** de `.jctx-body` (irmão, não filho) — e reduzindo o `margin-top` do corpo (12px→6px) pra colar visualmente. Medido ao vivo: topo do botão fica a 113.99px do topo da página, topo do `jcard` a 116.43px — diferença de ~2.4px, dentro do pedido de "mesma distância do topbar que o cabeçalho tem".

**Grupo D — página "Tarefas" (Kanban pessoal) + popover de Nova Atividade com 2 abas:** nova entrada de nav `tarefas` (`renderTarefas`), Kanban pessoal com todas as atividades onde `a.responsavel===me.nome`, reaproveitando `kanbanAtividades(cid, override)` — que já aceitava um array arbitrário via `override`, sem precisar de nenhum Kanban novo — e o filtro "minhas" já usado em Pendências e Atividades, confirmando que "responsável" (não "criado por") já era a convenção do projeto pra "minhas tarefas". O popover "Nova Atividade" (só ao **criar**, não ao editar) ganhou duas abas centralizadas — "Tarefas" (formulário original, sem mudanças) e "Interações" (formulário novo e simplificado: Título, Cliente, Tipo [Ligação/Mensagem/E-mail/Reunião/Visita/Outros — vocabulário novo, diferente de `INT_TIPOS` e `INT_CANAIS` já existentes, porque o pedido não batia com nenhum dos dois], Satisfação 1-5 com emoji, Descrição). A aba Interações salva em `DB().interactions` (mesma tabela da CRM de interações, aparece na timeline normal), com um campo novo `satisfacao` que **fica só local por enquanto** — não foi adicionado em `interactionToRow`/`rowToInteraction` porque isso exigiria uma coluna nova na tabela Supabase, e mudança de schema precisa de confirmação explícita (regra do projeto); o campo sobrevive a reloads via localStorage mas se perde num `loadFromSupabase()` de outro dispositivo/sessão. Fica pendente perguntar ao usuário se quer criar a coluna.

**Grupo E — perfis "Middle" e "Desenvolvedor" + personificação:** `PERFIS` ganhou dois itens novos. `PERMS['Middle']` espelha `Onboarding` (edição sem privilégios administrativos); `PERMS['Desenvolvedor']` é cópia exata de `Gestão Executiva`. `NAV_ACCESS` foi **reescrito com listas explícitas** em vez de usar o fallback `NAV_ACCESS[key]||PERFIS` — porque esse fallback, com `PERFIS` agora incluindo "Middle", passaria a liberar todo item sem entrada explícita pra "Middle" também, o oposto do pedido ("Middle" só vê Dashboard/Jornada/Cadastro/Tarefas/Relatórios). `canAtivos()` passou a incluir `Middle` e `Desenvolvedor`; `canComercial()` (propostas comerciais, fora da lista das 5 áreas liberadas pro Middle) só ganhou `Desenvolvedor`. Conta do usuário (`henrique.beserra@trinusco.com.br`) convertida pra `Desenvolvedor` — **feito pela própria tela de Gestão de Usuários**, não por script direto no Supabase: uma primeira tentativa de UPDATE direto via `supa.from('users').update(...)` foi bloqueada pelo classificador de permissões do Auto Mode (mutação de dado de produção fora do fluxo do produto); perguntado ao usuário como preferia, e ele escolheu a tela do app.

**Personificação (impersonation):** dropdown "Visualizar como" no menu do usuário, visível só quando o perfil real é "Desenvolvedor". **Bug pego no teste ao vivo:** a primeira versão referenciava a variável `CURRENT` (e o estado `_impersonarPerfil`) diretamente dentro de `buildUserChip()`/`App.setImpersonar()` — só que essas funções vivem na "parte B" (camada de apresentação, sua própria IIFE), enquanto `CURRENT` é privado da "parte A" (camada de dados), só acessível de fora via `getSession()`/`setSession()` explicitamente exportados em `window.__OO`. Corrigido expondo três novas funções da parte A (`isRealDev()`, `getImpersonarPerfil()`, `setImpersonarPerfil(perfil)`) e usando-as na parte B em vez de tocar `CURRENT` cru. `getSession()` devolve um clone raso com `.perfil` trocado quando a personificação está ativa — todo `can()`/`navAllowed()`/`canAtivos()`/`canComercial()` que já passa por `getSession()` respeita automaticamente, sem precisar tocar em nenhum desses call sites.

**Teste:** tudo validado ao vivo (servidor local via `serve.ps1` + `.claude/launch.json`, navegador embutido) numa sessão real logada como Henrique. Confirmado: os 3 botões do jcard, estilo do `.jop-num`, número no card do Kanban de Negociação (`#36710 | RD VILLE...`, `#36582 | BARION...`, sem prefixo quando `numeroOperacao` vazio), abas da Jornada na ordem certa, card "Ativos e Serviços" com contagem, bloco Consolidado só com BV, alinhamento do cabeçalho do Contexto (~2.4px de diferença do jcard), colapsar/expandir o Contexto nos dois sentidos sem travar, linha de Ativo expandindo detalhe com botão Editar funcional, aba Serviços adicionando/removendo um serviço de teste (confirmado no Supabase, revertido depois), página Tarefas renderizando um Kanban com uma tarefa de teste (criada e removida via `App.delAtividade`-equivalente + `deleteRemoto`, sem deixar resíduo no banco), popover com as 2 abas (Tarefas inalterada, Interações salvando com `satisfacao` e depois excluída via `App.delInteracao`, também limpa do Supabase), personificação alternando entre Middle/Área Parceira/normal com o menu lateral reagindo corretamente em cada caso, e a troca de perfil real pela tela de Usuários confirmada tanto no Supabase quanto na sessão recarregada. Um bug real foi encontrado e corrigido durante esse teste (o `CURRENT`/parte A vs parte B acima) — sem ele, a tela inteira quebrava no login com `ReferenceError`.

---

## 2026-09-25 (17) — Aba Ativos da Jornada padronizada com o visual do Cadastro; "Status do Ativo" virou "Etapa" (com etapas novas); "Estado" só com UF em todo formulário

**Contexto:** logo depois do lote acima, o usuário mandou dois prints comparando o visual de Ativos do Cadastro (cards com ícone, nome, cidade/UF, selo, ícones de duplicar/remover) com a tabela larga de 10 colunas da aba Ativos da Jornada, pedindo pra padronizar a segunda no estilo da primeira — mantendo visíveis Ativo, Tipologia, Etapa (renomeado de "Status", com pedido pra renomear no Cadastro também), Estado (só UF, "em qualquer campo que peça Estado"), Cidade, Região, Unidades e VGV. Também pediu pra remover o card "Localização" do resumo da aba e deixar os três cards restantes (Quantidade de Ativos/Total de Unidades/VGV Total) mais elegantes — "os cards estão enormes".

**Decisão — reaproveitar as classes CSS do accordion do Cadastro (`op-ativo-*`) em vez de criar um visual novo do zero:** `jAtivos()` trocou a `<table>` por uma lista de `.op-ativo-card` (mesmas classes que `ativoAccordionMarkup()` já usa em Cadastro/Nova Operação — `op-ativo-ico`, `op-ativo-titulo`, `op-ativo-chev`, `op-ativo-body`), garantindo paridade visual real e não uma cópia aproximada. Só o cabeçalho de cada card ganhou uma classe nova (`.jativo-head`, igual a `.op-ativo-head` só que com `flex-wrap` — precisa caber mais informação que o accordion original: badges de Tipologia e Região, "NNN un." e valor de VGV, além do selo de Etapa) porque aqui é somente-leitura (clique abre o detalhe via `jAtivoDetalhe`, já existente da rodada anterior — reaproveitado sem mudança) em vez de abrir um formulário de edição. O clique/expansão e o botão "Editar" (que abre o Cadastro) continuam funcionando exatamente como antes.

**Decisão — "Status do Ativo" → "Etapa", com um novo conjunto de valores:** `ATIVO_STATUS` trocou de `['Estruturação','Lançamento','Comercialização','Obras','Entrega','Pós-obra']` pra `['Landbank','Pré-lançamento','Lançamento','Obras','Pós-obras','Pós-operacional']` — coerente com os campos "Pós-obra (meses)"/"Pós-operacional (meses)" que já existiam no Cronograma da Obra do Ativo. Rótulo "Status do Ativo" renomeado pra "Etapa" em todos os pontos: campo do accordion (Cadastro/Nova Operação, componente compartilhado — um só lugar corrige os dois), modal legado (`ativoListRender`, sem uso mas mantido consistente), detalhe somente-leitura da Jornada (`jAtivoDetalhe`), rótulo do Histórico de Alterações (`LBL.statusAtivo`) e cabeçalho do CSV de exportação. **Dado existente não foi migrado** — ativos já cadastrados com os valores antigos (`Obras`, `Entrega`, etc.) continuam mostrando o texto antigo nos selos (o badge só exibe a string crua, não valida contra a lista atual), mas o `<select>` de edição não vai mais marcar nenhuma opção como selecionada pra esses valores (cai no "—" em branco) até o usuário escolher e salvar uma etapa nova — não é destrutivo, só precisa de uma correção manual por ativo quando notado.

**Decisão — "Estado" só UF em formulário, em qualquer nível:** o campo Estado do **ativo** (`ativoAccordionMarkup`) já era só UF desde sempre (`ufOpt`, sem nome do estado). O que ainda mostrava "UF · Nome do Estado" era o campo Estado do **cliente** (`ufOpts`, três definições idênticas em Cadastro, no card antigo "Estado do Cliente" e em Nova Operação) — as três trocadas pra mostrar só a UF, igual ao do ativo. Os cards "Estado líder" dos Relatórios/BI (`ufFull`) foram deixados como estavam — são cards analíticos de leitura, não campos de formulário, e o nome completo do estado ali é informação útil, não redundância a cortar.

**Decisão — três KPIs mais compactos, card "Localização" removido:** em vez de reduzir o `.kpi`/`kpi()` genérico (usado em várias outras telas — mexer nele teria efeito colateral em Dashboard/Relatórios/etc.), criado um componente próprio e escopado só pra esta aba (`jAtivoKpi()` + classes `.jativo-kpi*`): ícone pequeno colorido à esquerda, rótulo (maiúsculo, 11px) e valor (19px) empilhados à direita, os três numa fileira flex com `gap`, sem o card enorme de `.kpi-grid` (que reserva espaço fixo pra rótulo+ícone+valor+unidade+rodapé). "Localização" removido (era só `c.estado`/`c.cidade` do cliente, redundante com os cards de Cliente/Contexto que já mostram isso).

**Teste:** verificado ao vivo em BARION (10 ativos reais) — os três KPIs compactos numa fileira única, lista de cards no estilo do Cadastro (ícone, nome, cidade/UF, badges de Tipologia/Região, unidades, VGV, selo de Etapa — mostrando os valores antigos crus tipo "Obras"/"Entrega", como esperado, já que não houve migração de dado), clique num card expandindo o detalhe com `open`/chevron girando, gráfico "Etapa dos Ativos" com o título renomeado. Confirmado por leitura de DOM que o `<select>` "Etapa" (Cadastro) já mostra exatamente as seis opções novas, e que os três `<select>` de Estado (Cadastro cliente, "Estado do Cliente", Nova Operação) mostram só a sigla, sem o nome do estado. Sem erros de console (o único erro visto no console era um log antigo de uma correção anterior nesta mesma sessão, não reproduzido de fato — confirmado lendo o DOM ao vivo).

**Teste:** verificado ao vivo em BARION (10 ativos, card alto — confirmado sem espaço morto, card termina alinhado com os vizinhos) e SOLARIS (2 ativos, card curto — sem rolagem desnecessária nem esticamento estranho). Sem erros de console.

---

## 2026-09-25 (2) — Bug real de altura no grid, fusão dos ciclos, edição inline de datas, BV no sidebar

**Contexto:** o fix da rolagem da rodada anterior (`min-height:0` na cadeia flex) não era suficiente — o usuário mandou print mostrando o card de Serviços vazando conteúdo pra fora do card, sem borda, abaixo da "linha verde" onde os outros cards terminavam. Nesta rodada: (1) causa raiz real do bug de altura foi encontrada e corrigida; (2) Ciclo de Negociação e Ciclo de Implantação viraram um único card "Ciclos da Operação" com datas editáveis inline; (3) a aba "Ciclos da Operação" foi removida; (4) BV saiu do card de Serviços e foi pro sidebar, dentro de um novo grupo "Consolidado".

**Causa raiz do bug de altura (achada por teste empírico direto no navegador, não só por leitura de spec):** `.jgrid` é `display:grid` com `align-items:stretch` e linhas `auto`. O que eu não sabia (e a teoria "min-height:0 resolve tudo" do CSS não cobre): pra **CSS Grid** com linha `auto`, a contribuição de um item pro tamanho da linha usa o **max-content dele** — mesmo com `overflow:auto` e uma cadeia flex com `min-height:0` por dentro, isso só reduz o **mínimo**, não o **máximo**. Resultado medido ao vivo: a linha do grid crescia pra **1270px** (a altura total dos 10 ativos do Serviços sem cortar nada), e os outros dois cards — que têm menos conteúdo — eram esticados pra essa mesma altura enorme, só que com muito espaço em branco sobrando embaixo do conteúdo deles. Ou seja: o "vazamento" que o usuário viu no print era esse espaço morto sendo ocupado por conteúdo do Serviços que não tinha mais onde ficar contido visualmente numa versão anterior do CSS.

**Fix real (confirmado por teste ao vivo, `grid.offsetHeight` medido antes/depois):** `.jserv-card{height:0;min-height:100%}` (mantendo `display:flex;flex-direction:column;overflow:hidden`). Isso usa o "modo de duas passagens" que a spec do Grid reserva pra altura em porcentagem: a **primeira passagem** calcula o tamanho da linha ignorando a contribuição desse item (porque `height:0` faz ele não pedir espaço nenhum por conteúdo), e só na **segunda passagem** o `min-height:100%` resolve contra o tamanho de linha já definido, sem realimentar o cálculo. Resultado: a linha do grid agora fica do tamanho do card mais alto **de conteúdo real** (Cliente ou Ciclos da Operação), e o Serviços rola por dentro dos limites certos. Testado ao vivo: `gridHeight` caiu de 1270px pra 593px, os 3 cards ficaram com `offsetHeight` idêntico (593px) e `scrollHeight` batendo com o conteúdo real (sem overflow nem clipping).

**Lição pro projeto:** essa é uma variante nova da mesma classe de bug de cascata já documentada aqui — só que dessa vez não foi uma regra CSS duplicada brigando, foi um mal-entendido genuíno sobre como CSS Grid calcula altura de linha `auto` quando um dos itens tem conteúdo rolável. **Da próxima vez que aparecer "card não alinha com os vizinhos" ou "conteúdo vazando", medir `offsetHeight`/`scrollHeight` via console ao vivo antes de tentar consertar por teoria** — economiza rodadas erradas.

**Ciclos da Operação (fusão + edição inline):**
- `jOperacao()` foi removida. As datas de Ciclo de Negociação (7 campos) e Ciclo de Implantação (4 campos) viraram um card só na Visão Geral, renomeado "Ciclos da Operação", com um rótulo de grupo (`CICLO DE NEGOCIAÇÃO` / `CICLO DE IMPLANTAÇÃO`) separando os dois blocos por uma linha divisória.
- Cada data agora é editável clicando em cima dela: vira um `<input type="date">` no lugar, salva no `change`/`blur`, cancela com Escape — mesmo padrão já usado pros campos de Responsáveis no sidebar (`jRespEditToggle`/`jRespSet`), replicado como `jCicloEditToggle`/`jCicloDateSave`.
- A aba de topo "Ciclos da Operação" foi removida (de 5 abas pra 4: Visão Geral / Ativos / Tarefas / Documentos).
- O card "Classificação & Responsáveis" (Etapa da Jornada, Status Operacional, Tipologia, Key Account, Resp. Kickoff, Produtos Contratados, Observações, Booked Value) que vivia na mesma aba removida agora abre como **modal**, pelo botão "Editar" do card Cliente (`App.jClassifModal`). Decisão confirmada com o usuário antes de implementar (pergunta feita via AskUserQuestion) — sem essa aba, esses campos ficariam sem lugar de edição.
- `respComercial` e `respOnboarding` **não** foram trazidos pro modal — já são editáveis no sidebar de Contexto (`jRespSet`), então ficariam duplicados; essa duplicação (Key Account continua nos dois lugares) já existia antes e não foi mexida agora.
- **Achado, não implementado:** `c.bookedValue` já é um campo real no modelo de dados (existia desde antes desta sessão, input `#op_bv` na aba antiga) — diferente do `mockBookedValue()` mostrado no sidebar. Mantido no modal (campo "Booked Value (R$)") pra não perder a capacidade de edição, mas o valor **exibido** no sidebar continua sendo o mock, por instrução explícita do usuário ("por hora deixe mokado").

**BV no sidebar:** novo bloco "Consolidado" no `jContexto()`, posicionado acima de "Indicadores" (mesmo padrão visual de grid 2 colunas) — BV (mockado, com destaque em verde/negrito via `.jctx-bv`), Total de Ativos (`c.ativos.length`), Total de Serviços (soma de `servicos.length` de todos os ativos). Indicadores perdeu seu próprio divisor (`border-top`) já que agora tem o Consolidado antes dele com esse mesmo divisor — só um separador entre a seção editável e a seção "só leitura" do sidebar, não dois.

**Teste:** verificado ao vivo em BARION — medição de `offsetHeight` confirmando a correção do grid; edição de data testada via `dispatchEvent(change)` direto no input (a digitação via teclado sintético em `<input type=date>` nativo é sabidamente instável em automação de navegador — não é bug do app, é limitação da ferramenta de teste); valor de teste (`dataHandoff`) revertido e re-sincronizado com o Supabase (POST 200 confirmado); modal de Classificação & Responsáveis abre com todos os campos corretos e fecha limpo; aba Ativos confirmada funcionando após a mudança de dispatch em `jPanel`. Sem erros de console.

---

## 2026-09-25 (3) — Lote via PDF (Próximo Prompts): observação empilhada, cidade em Serviços, botão "hoje", split de Pendências/Tarefas, sidebar em dois blocos, abas full-width

**Contexto:** usuário enviou um PDF (`Prompts.pdf`, 6 páginas, um pedido por página com print + texto) pedindo 7 ajustes na Visão Geral. O ambiente não tinha `pdftoppm` (poppler) instalado — sem ele o Read não renderiza páginas de PDF como imagem. Resolvido instalando poppler via `winget install oschwartz10612.Poppler` e chamando `pdftoppm.exe` diretamente (com o caminho completo do binário, já que o PATH atualizado pelo instalador só é lido por processos novos, não pelo processo já em execução) pra converter cada página em PNG e ler cada uma.

**Os 7 ajustes:**
1. Card Cliente: campo Observação virou `jInfoBlock()` — rótulo em cima, texto embaixo (empilhado), em vez de lado a lado como os outros campos curtos. Novo helper ao lado de `jInfo()`, mesmo `.jinfo` visual mas `flex-direction:column`.
2. Card Serviços: `jServicosResumo()` agora mostra `Nome do ativo | Cidade` (cidade com fonte menor, `.jserv-resumo-cidade`) ao lado do nome, antes da tipologia.
3. Card Ciclos da Operação: ao clicar numa data pra editar, aparece um botão "hoje" ao lado do input — preenche a data atual com um clique. Implementado com `onmousedown="event.preventDefault();..."` (não `onclick`) pra evitar que o `blur` do input (disparado pelo mousedown tirando o foco) dispare um save duplicado ou impeça o clique de chegar a tempo, já que o clique normal só dispara depois do blur.
4. Widget "Pendências e Tarefas": ícone do relógio reduzido de 30px pra 16px e sem fundo colorido (antes tinha círculo azul de fundo tipo `.card-head .ico`). Lista dividida em duas seções com rótulo (`PENDÊNCIAS` / `TAREFAS`) quando aglutinado é expandido — pendências ordenadas por prazo crescente (mais antiga primeiro), tarefas também por prazo crescente (mais próxima primeiro). Mesmo critério de ordenação nos dois casos (ascendente por prazo), só que aplicado a dois grupos com semântica diferente (atraso vs. proximidade).
5. Card de identificação (`.jcard`): botões de atalho (`jcard-actions`) foram movidos pra **dentro** de `.jcard-left`, logo abaixo da linha de meta (Gerente/Onboarding/Key Account) — antes eram um bloco irmão de `.jcard-top` inteiro, então o espaço em branco visível vinha da altura de `.jcard-right` (selo+SLA+meta-direita, 3 linhas) ser maior que `.jcard-left` (2 linhas), deixando um vão entre o fim do texto da esquerda e o início dos botões. Com os botões dentro da própria coluna esquerda, eles ficam colados na meta independentemente da altura da direita.
6. Sidebar de Contexto: (a) o `<select>` de edição de Onboarding/Key Account virou um `<input type="text" list="...">` com `<datalist>` das opções — visual de campo de busca em vez de dropdown nativo cru; (b) o sidebar foi dividido em dois cartões visuais (`.jctx-panel`) — um com Responsáveis/Prioridade/Etiquetas (editável), outro com Consolidado/Indicadores (só leitura) — com `gap:var(--topbar-h)` entre os dois, reaproveitando a altura da topbar como referência de espaçamento, conforme pedido. O `.jctx` externo virou só um contêiner de posicionamento (`position:fixed`, sem fundo/borda própria); cada `.jctx-panel` que carrega o visual de card.
7. Abas superiores: `.jtabs-row` saiu de dentro de `.jmain` e virou irmã de `.jbody` (antes dela) — isso automaticamente faz ela ocupar a largura toda da área de conteúdo (jmain + onde fica o sidebar fixo), já que deixa de estar limitada pelo `margin-right:290px` do `.jmain`. `z-index` subiu de 12 pra 16 (acima do sidebar, que é 15) pra garantir que ela sempre fique por cima ao rolar. Botão de voltar (`.jtab-back`) removido do markup (CSS morta deixada, mesmo padrão de sempre).

**Bug real encontrado e corrigido — Escape não cancelava de verdade:** o padrão já estabelecido (`onkeydown` pra Escape chamando `...EditToggle(null)` + `onblur` chamando a função de salvar) tem um problema: `EditToggle(null)` dispara `refresh()`, que remove o input do DOM — e remover um elemento focado do DOM dispara um evento de `blur` nele como parte da limpeza do navegador, então o `onblur` (que ainda está vinculado ao nó no instante da remoção) **dispara de qualquer forma e salva o que estava digitado**, mesmo depois de "cancelar" com Escape. Achado testando de verdade (digitei "Nat" num campo de Onboarding, apertei Escape, e o valor foi salvo — inclusive sincronizado com o Supabase). Corrigido nos dois lugares que usam esse padrão (`jContexto`'s `pessoa()` e `jCicloDate()`): Escape agora marca `this.dataset.cancel='1'` antes de fechar a edição, e o `onblur` verifica essa flag e sai sem salvar se estiver marcada.

**Limpeza pós-teste:** o teste do bug acima e do botão "hoje" gravou de verdade no Supabase (campo `respOnboarding` e `dataSolicitacaoProposta` do cliente SOLARIS, mais duas linhas na tabela `history`). Revertido via `DB()`+`save()` pros campos, e as duas linhas de `history` foram **apagadas diretamente do Supabase** (não só do estado local) — `history` não passa pelo `syncToSupabase()`/`save()` em lote, cada entrada é inserida individualmente em tempo real por `addHistory()`→`insertHistoryRemoto()`, então limpar só o array local não bastava; a limpeza remota exigiu recriar um client Supabase no console (com a mesma URL/chave publicável já expostas no código-fonte) e chamar `.delete()` pelos ids exatos das duas linhas.

**Teste:** verificado ao vivo (Claude in Chrome) em BARION e SOLARIS — observação empilhada com texto real, cidade nos ativos de Serviços, botão "hoje" gravando a data corretamente, Escape confirmado NÃO salvando mais após o fix, split de Pendências/Tarefas testado com 4 atividades injetadas (2 pendências + 2 tarefas com prazos variados, ordem visual conferida), sidebar em dois blocos visíveis, abas coladas no topo cobrindo o conteúdo ao rolar. Sem erros de console em nenhum momento. Todos os dados de teste e o log de histórico revertidos e sincronizados de volta.

---

## 2026-09-25 (4) — Ajuste fino pós-lote: cor da barra de abas, espaçamento do sidebar, divisor duplicado, BV maior

**Contexto:** usuário mandou print com marcações verdes apontando 5 problemas na rodada anterior.

**Mudanças:**
- `.jtabs-row`: fundo passou a ser `#E6E9F0` (antes usava `var(--bg)`, idêntico ao fundo da página — testado ao vivo e confirmado via `getComputedStyle`: a barra era literalmente invisível como elemento distinto). Também ganhou `border-bottom:1px solid var(--line)` e o "sangramento total" (`margin:0 -28px;padding:14px 28px 16px;width:calc(100% + 56px)`) pra tocar de verdade a borda direita do sidebar esquerdo até a borda direita da viewport — testado via `getBoundingClientRect()`: `left` bate exatamente com a borda direita do `.sidebar`, `right` bate com a borda direita da viewport.
- `.jctx-body{gap}` reduzido de `var(--topbar-h)` (56px — decisão da rodada anterior, que na prática ficou grande demais) pra `16px`, igual ao gap usado em `.jgrid` e outros espaçamentos entre cards do sistema.
- `.jciclo-group:not(:first-child)` perdeu `padding-top`/`border-top` — a linha tracejada do último `.jinfo` (`Assinatura Aditivo/Distrato`) já fazia esse papel de separador; a borda extra a poucos pixels de distância lia como "linha duplicada".
- `.jctx-bv b` ganhou `font-size:21px` (era 12.5px, herdado do padrão dos outros itens de Consolidado/Indicadores) — BV agora se destaca visualmente como o número mais importante do bloco, sem virar um número gigante.

**Investigado e não reproduzido:** o usuário também reportou o topo do sidebar esquerdo "cortado". Testado ao vivo com `getBoundingClientRect()` comparando `.sidebar` e `.jtabs-row` — os dois têm exatamente o mesmo `top` (alinhados perfeitamente, ambos colados no topbar). Não foi possível reproduzir o problema; a hipótese mais provável é que o print enviado estava com a captura de tela levemente cortada nas bordas (os traços azuis finos no topo/esquerda do print batem com esse padrão). Combinado: se o problema persistir visualmente depois deste round, mandar um novo print pra investigar com mais contexto.

**Gotcha da própria sessão de teste:** a ferramenta de screenshot do navegador (Claude in Chrome) apresentou um artefato de renderização nesta rodada — uma captura saiu com a barra de abas e o menu lateral "ladrilhados" repetidamente por toda a tela, parecendo um bug grave de duplicação de elementos. Verificado via `document.querySelectorAll('.jtabs-row').length` → `1` (só existe um elemento de verdade no DOM) — era só falha pontual de captura (timeouts de `Page.captureScreenshot` já tinham acontecido logo antes), não um bug do app. **Lição:** sempre que uma captura de tela parecer bizarra demais pra ser verdade, confirmar via contagem de elementos no DOM antes de assumir que é um bug real.

**Teste:** verificado ao vivo em BARION — barra de abas com fundo visivelmente diferente da página (confirmado por zoom), sangramento total até a borda do sidebar esquerdo e até a borda direita da viewport (confirmado por `getBoundingClientRect`), gap do sidebar direito visivelmente mais compacto, divisor duplicado removido (só a linha tracejada permanece), BV maior e verde. Sem erros de console.

---

## 2026-09-25 (5) — Bug real: barra de abas comendo o topo do sidebar direito; abas redesenhadas pro estilo sublinhado

**Contexto:** o "sangramento até a borda direita da viewport" da rodada anterior (`width:calc(100% + 56px)`) tinha um bug real que só ficou visível depois que a barra ganhou fundo opaco + `z-index:16`: o `.jctx` (sidebar direito) é `position:fixed;right:28px`, então ocupa uma faixa da tela que **não é reservada** pelo fluxo normal do `.content` — só `.jmain` reserva esse espaço, via `margin-right:290px`. Como a barra de abas virou irmã de `.jbody` (não mais filha de `.jmain`) numa rodada anterior, ela nunca soube que precisava reservar esse espaço, e o "sangramento total" piorou isso ao esticar a barra até a borda física da tela — cobrindo os primeiros ~60px do topo do "CONTEXTO" com o próprio fundo da barra, por cima (z-index maior).

**Fix:** `.jtabs-row` ganhou `margin-right:290px` (mesmo valor que `.jmain` já usa) em vez do sangramento simétrico; quando o sidebar direito está recolhido (`.jctx-closed`), cai pra `margin-right:62px`, espelhando exatamente `.jbody.jctx-closed .jmain`. Como a classe de estado (`jCtxOpen`) mora em `.jbody`, e `.jtabs-row` não é mais descendente dela, a própria classe `jctx-closed` passou a ser aplicada direto no `.jtabs-row` também (`jCtxOpen?'':' jctx-closed'` no template). Testado ao vivo com `getBoundingClientRect()` nos dois estados (aberto/fechado) e nos dois casos a barra termina exatos 18px antes do sidebar começar — sem sobreposição.

**Redesign visual (a partir de print de referência do usuário):** o controle segmentado (pill cinza com abas em caixa branca) virou texto simples em caixa alta com sublinhado azul na aba ativa — o mesmo padrão já usado em `.jtl-tab` (sub-abas da Linha do Tempo), agora espelhado em `.jtab` pra consistência visual entre os dois níveis de abas da tela. `.jtabs-row` ganhou `box-shadow:var(--shadow)` pra dar a sensação de elevação/camada por cima do conteúdo que rola por baixo, conforme pedido ("leve sombreado... pra mostrar que está acima dos outros itens").

**Teste:** verificado ao vivo em BARION — sem sobreposição com o sidebar direito em nenhum dos dois estados (aberto/fechado), abas com sublinhado azul funcionando ao trocar entre Visão Geral/Ativos/Tarefas/Documentos, sombra visível. Sem erros de console.

---

## 2026-09-25 (6) — Revisão da rodada anterior: barra de abas volta a encostar na borda direita, usando espaçamento vertical em vez de reserva horizontal

**Contexto:** o usuário pediu explicitamente pra reverter a estratégia da entrada anterior — quer a barra de abas ("topbar da operação") esticando até a borda direita física da página de novo (não mais parando 290px antes, pra "desviar" do sidebar de Contexto), e em vez disso pediu pra abaixar tanto o card de identificação (`.jcard`) quanto o sidebar de Contexto (`.jctx`) por uma distância marcada num print (uma faixa verde horizontal cobrindo a altura da barra).

**Decisão — trocar reserva horizontal por separação vertical:** em vez de `.jtabs-row` "desviar" do `.jctx` encolhendo sua própria largura (abordagem da entrada anterior, `margin-right:290px`/`62px`), a barra agora ocupa 100% da largura (igual a `.jbody`, sem `margin-right`) e o que evita a sobreposição é o `.jctx` (fixed) e o `.jcard` (primeiro item de `.jmain`) começarem mais abaixo — depois do fim da barra, não ao lado dela. Como tanto `.jtabs-row` (sticky) quanto `.jctx` (fixed) ficam em posições constantes na viewport assim que a página rola, basta que a faixa Y de um não colida com a do outro — não importa mais se elas se sobrepõem em X.

**Medição ao vivo (`getBoundingClientRect`) antes de calcular os valores:** `.jtabs-row` mede 44.4px de altura (`top:56` / `bottom:100.4`, com `--topbar-h:56px`); antes desta mudança `.jcard` começava exatamente onde a barra termina (`top:100.4`, sem respiro) e `.jctx` já começava ANTES disso (`top:70`) — só não aparecia por cima porque a reserva horizontal os mantinha em colunas diferentes.

**Mudanças:**
- `.jtabs-row{margin-right:290px}` e `.jtabs-row.jctx-closed{margin-right:62px}` removidos — a barra volta a ocupar a largura inteira de `.jbody` (testado: `.jtabs-row.right === .jbody.right`, exato, nos dois estados aberto/fechado do sidebar). A classe `jctx-closed` no markup do `<div class="jtabs-row">` também foi removida (não tinha mais nenhuma regra CSS associada).
- `.jcard{margin-top:14px;...}` — antes não tinha `margin-top`; agora cria um respiro de 14px entre o fim da barra de abas e o começo do card, igual ao padrão de respiro de 14px já usado em outros pontos da tela (ex.: o próprio `.jctx` já usava `+14px` antes desta mudança).
- `.jctx{top:calc(var(--topbar-h) + 58px)}` — antes era `+14px`. 58px = altura medida da barra de abas (~44px) + 14px de respiro, o mesmo respiro aplicado ao `.jcard`, pra manter os dois alinhados na mesma altura abaixo da barra.

**Teste:** verificado ao vivo em "Ricardo De Lacerda Teodoro Ltda" — `.jtabs-row` tocando a borda direita da viewport (`right` idêntico ao de `.jbody`), `.jcard` e `.jctx` começando ~14px abaixo do fim da barra (sem sobreposição), testado nos dois estados do sidebar (aberto/recolhido) e com scroll (a barra fica fixa por cima do conteúdo que rola por baixo, sem cobrir o sidebar, que também é fixo e já começa abaixo dela). Sem erros de console.

---

## 2026-09-25 (7) — Visual da barra de abas ajustado pra bater com print de referência (fundo liso, divisor fino em vez de sombra)

**Contexto:** usuário mandou um print de referência de outro sistema mostrando o estilo de barra de abas desejado: fundo branco liso (sem tom cinza-azulado diferenciado), abas em caixa alta com a ativa em azul+negrito+sublinhado e as inativas em cinza com peso normal, e uma linha divisória fina cinza-clara logo abaixo de toda a barra separando das abas do conteúdo — nada de sombra/elevação.

**Decisão:** `.jtabs-row` trocou `background:#E6E9F0` (cinza-azulado, da rodada de 25/09 anterior) e `box-shadow:var(--shadow)` por `background:var(--surface)` (branco, igual aos cards) e `border-bottom:1px solid var(--line)` (linha fina, mesmo tom já usado em bordas discretas no resto do app). `.jtab` teve o peso da fonte reduzido de `700` pra `600` nas abas inativas; `.jtab.active` ganhou `font-weight:700` explícito pra manter só a aba ativa em negrito (antes todas eram igualmente bold, só a cor/sublinhado distinguia a ativa).

**Nota:** essa troca de fundo derruba, de propósito, a decisão de 25/09 "fundo da barra de abas diferenciado da página (`#E6E9F0`)" tomada duas rodadas atrás — o usuário mudou de ideia ao ver o print de referência, preferindo o visual mais limpo/liso ao invés do destaque de cor. Registrado aqui como correção explícita, sem apagar a entrada anterior (convenção do arquivo).

**Teste:** a extensão Claude in Chrome caiu no meio da sessão (não reconectou em três tentativas) — perguntado ao usuário como proceder, ele pediu pra tentar reconectar antes de publicar. Na tentativa seguinte a extensão voltou; testado ao vivo em "Ricardo De Lacerda Teodoro Ltda" via `getComputedStyle()`: fundo branco (`rgb(255,255,255)`), `box-shadow:none`, `border-bottom` fino (`~1px solid rgb(231,234,242)`) na barra inteira, aba ativa com `font-weight:700`+sublinhado azul, inativas com `font-weight:600`+cinza. Sem erros de console.

---

## 2026-09-25 (8) — Quatro ajustes pós-teste real: anel de foco circular na aba, barra não encostava de verdade na borda, meta do cabeçalho revertida, assimetria vertical do card

**Contexto:** usuário testou a rodada anterior no navegador real (não no ambiente de teste) e mandou print com 4 problemas: (1) um "círculo" estranho aparecia embaixo do título da aba ativa; (2) a barra de abas ainda não encostava de verdade na borda direita da tela; (3) pediu pra devolver "Criado em"/"Última atualização" pra lado do Key Account, como era antes de uma rodada anterior; (4) os botões de atalho (+Tarefa etc.) tinham menos respiro embaixo do que o título tinha em cima, dentro do card de identificação — pediu simetria.

**Causa raiz do "círculo" (achada por leitura de código, não visível no ambiente de teste — `:focus-visible` não reproduz com clique sintético):** existe uma regra global de acessibilidade, `:where(a,button,input,select,textarea,[tabindex]):focus-visible{outline:none;box-shadow:var(--ring);border-radius:var(--radius-xs)}` (foco visível consistente pro app inteiro). Como `.jtab` é um `<button>` sem padding horizontal (`padding:14px 0`), o `box-shadow` de foco (um anel) ficava quase do tamanho do texto, sem cantos retos pra "esconder" a curva — no Chrome do usuário (Windows), cliques de mouse em `<button>` às vezes disparam `:focus-visible` (comportamento que varia por SO/navegador, diferente do ambiente de teste usado aqui). **Fix:** `.jtab:focus-visible{box-shadow:none;border-radius:0;outline:2px solid var(--blue-soft);outline-offset:-4px}` — como `:where()` tem especificidade zero, a regra nova (`.jtab:focus-visible`, especificidade de classe) já vence a global independente da ordem no arquivo; mantém acessibilidade (usuário de teclado ainda vê um contorno) sem o efeito bolha.

**Causa raiz da barra "não encostando":** `.jtabs-row` tinha `margin-left:-28px` (pra sangrar até a borda esquerda, cancelando o padding de `.content`) mas nunca ganhou o equivalente `margin-right:-28px` — só o lado esquerdo sangrava. Medido ao vivo: `.jtabs-row.right` ficava 1921.75px numa viewport de 1958px de largura, exatos 28px (= o padding de `.content`) antes do fim de `.content` (1949.74px). **Fix:** adicionado `margin-right:-28px`. Testado: `.jtabs-row.right` passou a bater exatamente com `.content.right`.

**Decisão — meta do cabeçalho revertida:** "Criado em"/"Última atualização" voltaram de `.jcard-meta-right` (coluna direita do card, abaixo do selo de estágio) pra dentro de `.jcard-meta`, como mais dois `<span>` depois de "Key Account" — mesmo arranjo de antes da rodada "quarta rodada" de 23/09 que os tinha movido pra lá. `.jcard-meta-right` (CSS) foi apagada por completo (não deixada como código morto — é uma regra pequena, de propósito único, sem motivo pra manter).

**Causa raiz real da assimetria vertical do card (e por que não precisou de CSS extra pra "descer os botões"):** `.jcard-top` é `display:flex;align-items:flex-start`, então sua altura total é ditada pela coluna mais alta entre `.jcard-left` (título+meta+botões) e `.jcard-right` (selo+SLA). Antes desta rodada, `.jcard-right` (89.98px, por causa do bloco de 2 linhas "Criado em/Última atualização") era mais alta que `.jcard-left` (75.18px) — o padding-bottom do card (10px) só "via" a coluna mais alta, deixando um vão de quase 26px embaixo dos botões da coluna mais curta. Ao mover esses dois campos pra `.jcard-meta` (decisão acima), `.jcard-right` encolheu pra só selo+SLA e passou a ser a coluna mais CURTA — `.jcard-left` virou a referência de altura, e o padding-bottom passou a se aplicar corretamente embaixo dela. **O pedido de "abaixar os botões" se resolveu como efeito colateral da correção acima, sem precisar de nenhuma margem nova** — medido ao vivo: vão do topo do título até o topo do card = 11.03px, vão do fim dos botões até o fim do card = 11.02px (praticamente idêntico).

**Teste:** verificado ao vivo em "Ricardo De Lacerda Teodoro Ltda" via `getBoundingClientRect()`: barra tocando a borda direita de `.content`, meta do cabeçalho com os 5 campos numa linha só (sem quebrar), vãos simétricos do card confirmados. Sem erros de console. O anel de foco circular não foi possível reproduzir neste ambiente de teste (não dispara `:focus-visible` em clique sintético) — fix aplicado por leitura de causa raiz no código, pendente de confirmação visual do usuário no navegador real dele.

---

## 2026-09-25 (9) — Causa raiz real do "círculo": resquício de CSS do antigo design em pílula das abas, não o foco

**Contexto:** o usuário testou a correção da rodada anterior (`.jtab:focus-visible`) e o semicírculo azul embaixo do título da aba ativa continuava lá — o diagnóstico anterior estava errado (ou incompleto). Pediu pra simplificar: só sublinhado na aba selecionada, com cor cinza quase preto em vez de azul.

**Causa raiz real:** existe uma regra antiga, `.jtab,.chip,.chip-btn,.vsw{border-radius:var(--radius-pill)}` (comentário no código: "Chips de navegação interna"), sobrevivente do design original das abas como controle segmentado/pílula (rodada de 23/09, antes do redesenho pro estilo sublinhado). Essa regra nunca foi removida quando `.jtab` virou abas de texto simples — como `border-radius` afeta os 4 cantos de qualquer borda, incluindo o `border-bottom:2px solid` usado pra marcar a aba ativa, os dois cantos inferiores do sublinhado ficavam arredondados, formando o "semicírculo" visto no print. É exatamente o padrão já documentado no projeto de bug por classe compartilhada entre componentes não relacionados (`.jtab` aqui reaproveitada por engano de um seletor de "chips"), mesma família do bug do `.jstage` encontrado em 23/09.

**Por que não foi possível reproduzir/confirmar na rodada anterior:** o efeito é puramente visual (CSS), não depende de `:focus-visible` nem de nenhum estado de interação — deveria ter sido visível em qualquer screenshot da aba ativa desde que o redesenho de sublinhado foi feito. A hipótese de foco da rodada anterior (8) estava descartada por esta descoberta, mas a correção lá aplicada (`.jtab:focus-visible{box-shadow:none;...}`) não é errada por si só — só não era a causa deste bug específico. Mantida no código (não faz mal, e ainda protege contra o anel de foco de verdade em navegação por teclado).

**Fix:** `.jtab{border-radius:0}` (override local, seguindo o padrão já estabelecido no projeto de preferir seletor mais específico a editar a regra compartilhada, já que `.chip`/`.chip-btn`/`.vsw` ainda usam a pílula legitimamente). Adicionalmente, a pedido do usuário ("simplificar"): `.jtab.active` trocou `color:var(--blue)` e `border-bottom-color:var(--blue)` por `var(--txt)` (cinza quase preto, `#0E1726`/`#0B1220` conforme o tema — já a cor de texto principal do app) — sublinhado + texto escuro marcam a seleção, sem depender de azul.

**Teste:** verificado ao vivo em "Ricardo De Lacerda Teodoro Ltda" via zoom de screenshot na barra de abas — sublinhado reto (sem curva) embaixo de "VISÃO GERAL", cor cinza quase preto, abas inativas seguem cinza claro (`var(--txt-3)`). A extensão Claude in Chrome caiu de novo logo depois desse teste (não foi possível confirmar via `getComputedStyle()` desta vez), mas a inspeção visual por zoom já confirma a correção do bug reportado.

---

## 2026-09-25 (10) — O fix anterior não funcionou de verdade: erro de especificidade CSS (a mesma classe de bug já documentada no projeto, cometida por mim desta vez)

**Contexto:** usuário testou de novo (print de "ATIVOS" selecionado) e o semicírculo continuava — o diagnóstico da rodada anterior (regra `.jtab,.chip,.chip-btn,.vsw{border-radius:var(--radius-pill)}`) estava certo, mas o **fix** não tinha efeito nenhum.

**Causa raiz do fix não funcionar:** `.jtab{border-radius:0}` (adicionado na linha ~418) e `.jtab,.chip,.chip-btn,.vsw{border-radius:var(--radius-pill)}` (linha ~1370, mais abaixo no arquivo) têm a **mesma especificidade** (um seletor de classe simples, 0-1-0). Com especificidade empatada, quem vem depois no arquivo vence — e a regra da pílula vem depois. Ou seja: eu apliquei exatamente o mesmo erro que este projeto já documentou várias vezes em DECISOES.md ("regra depois no arquivo vence em empate de especificidade") — dessa vez cometido por mim mesmo, não achado num código antigo.

**Fix de verdade:** trocado `.jtab{border-radius:0}` por `.jtabs-row .jtab{border-radius:0}` — um seletor composto (dois níveis: contêiner + classe) tem especificidade 0-2-0, que vence a regra da pílula (0-1-0) **independente da ordem no arquivo**. É o mesmo padrão de correção já usado no caso `.jstage-bar .jstage` (registrado em 2026-09-23) — preferir escopar por um ancestral real a confiar na ordem das regras.

**Lição:** ao corrigir um bug de CSS causado por uma regra compartilhada com a mesma especificidade do seletor problemático, sempre aumentar a especificidade do fix (escopar por um ancestral, não só repetir a mesma classe) — nunca contar com a posição no arquivo pra vencer o empate, mesmo que pareça que a nova regra "deveria" vencer por ter sido escrita depois na tela (a posição real no arquivo é o que importa, e é fácil perder a conta em um arquivo de milhares de linhas).

**Teste:** verificado ao vivo em "Ricardo De Lacerda Teodoro Ltda", clicando de fato na aba (não só inspecionando por seletor) — `getComputedStyle(document.querySelector('.jtab.active')).borderRadius` → `"0px"` (era `"9999px"`/pílula antes do fix real). Confirmado também por zoom de screenshot: sublinhado reto sob "ATIVOS", sem curva nos cantos. Sem erros de console.

---

## 2026-09-25 (11) — Pesquisa Pós-Kickoff, Ativação Operacional e Time to First Value trazidas pra dentro da Jornada, como abas da operação

**Contexto:** pedido do usuário pra consolidar tudo da operação dentro da própria Jornada do Cliente, deixando os Dashboards responsáveis pelas visões consolidadas/portfólio (troca futura, ainda não implementada nesta rodada). As três telas — antes só acessíveis como módulos independentes na sidebar, filtradas por cliente via `App.jAtalho()` (que setava `filters.cliente` e navegava pra fora) — agora também aparecem como abas dentro da barra de abas da operação, renomeadas pra `Pós-Kickoff`, `Ativação` e `First Value`.

**Decisão — reaproveitar a lógica de filtro existente em vez de duplicar dados:** `filteredClients()` já filtra por `filters.cliente===c.id` quando esse filtro está setado (linha ~3175), e `App.abrirCliente(id)` (que abre a Jornada) já seta `filters.cliente=id` antes de navegar. Ou seja, **dentro da Jornada, `filters.cliente` já está sempre fixo no cliente aberto** — as telas originais (`renderPesquisa`, `renderAtivacao`, `renderTTFV`), que fazem `cs=filteredClients()` e depois `cs.map(c=>...)`, já ficariam naturalmente restritas a 1 cliente só se fossem chamadas de dentro da Jornada. Não foi preciso nenhuma mudança na camada de dados (`calcSurvey`, `calcAtivacao`, `calcTTFV`, `DB().surveys`, `DB().activation`, `DB().ttfv` — tudo reaproveitado sem alteração).

**Implementação:** três funções novas — `jPosKickoffPanel(c,m)`, `jAtivacaoPanel(c,m)`, `jFirstValuePanel(c,m)` — cada uma é essencialmente o corpo do `.map(c=>...)` das telas originais, extraído pra fora do loop de `filteredClients()` e recebendo `c` diretamente (mais a `m` já computada em `renderJornada()`: `m.sv`/`m.at`/`m.tv` = `calcSurvey`/`calcAtivacao`/`calcTTFV`, evitando recálculo). A coluna "Cliente" das tabelas originais (Pesquisa/TTFV) foi removida — redundante, já que o nome do cliente aparece no cabeçalho da operação. `jPanel(c,m)` ganhou 3 novos `if` de despacho pras chaves `kickoff`/`ativacao`/`firstvalue` do `jTab`.

**Tabs da Jornada, nova ordem:** `Visão Geral / Ativos / Tarefas / Pós-Kickoff / Ativação / First Value / Documentos` (7 abas, eram 4) — as 3 novas entram entre Tarefas e Documentos, seguindo a ordem cronológica natural do onboarding (kickoff → ativação → primeira entrega de valor, tudo depois das tarefas operacionais, antes da documentação).

**Botões de atalho do card de identificação:** "+ Pesquisa"/"+ Ativação"/"+ First Value" (que chamavam `App.jAtalho(tela,id)` e navegavam pra fora da Jornada) viraram "+ Pós-Kickoff"/"+ Ativação"/"+ First Value" chamando `App.jTab('kickoff'|'ativacao'|'firstvalue')` — mesmo padrão já usado pelo botão "+ Documentação" (`App.jTab('docs')`), agora trocando de aba **dentro** da operação em vez de sair dela. `App.jAtalho()` ficou sem nenhum call site (mantida definida, sem uso — mesmo padrão já usado antes pro `jEstagioBar()`, caso sirva de referência).

**Decisão — telas independentes (sidebar) mantidas por enquanto:** `Pesquisa Pós-Kickoff`, `Ativação Operacional` e `Time to First Value` continuam existindo como itens de navegação e rotas próprias (`renderPesquisa`, `renderAtivacao`, `renderTTFV`, inalteradas) — o usuário mencionou explicitamente que pretende usar os **Dashboards** pra visões consolidadas de portfólio no futuro ("depois"), então essas telas de lista (todos os clientes de uma vez, filtráveis) continuam com utilidade até essa migração acontecer. Não foram removidas da sidebar nem do roteador — só passaram a também estar disponíveis embutidas na Jornada, por cliente.

**Teste:** verificado ao vivo em BARION EMPREENDIMENTOS — as 3 novas abas renderizam corretamente (tabela de Pesquisa com os 5 critérios + rating clicável, os 7 grupos de marcos de Ativação com accordion e selects, TTFV com datas herdadas do Cadastro e classificação calculada), os botões de atalho trocam de aba sem sair da operação, e a tela independente de Pesquisa Pós-Kickoff (sidebar) continua funcionando normalmente com todos os clientes. Testada uma edição real de rating (clique + clique de volta pra reverter) — persistiu e reverteu corretamente, sem erros de console em nenhum momento.

---

## 2026-09-25 (12) — Pesquisa Pós-Kickoff, Ativação Operacional e Time to First Value removidas da sidebar (mas não apagadas)

**Contexto:** agora que as três telas também vivem dentro da Jornada (decisão anterior), o usuário pediu pra tirá-las da sidebar de navegação — mas sem apagar de verdade, só ocultar, "até eu decidir se vamos ter que usá-las por algum motivo".

**Decisão:** reaproveitado o mecanismo `hideNav` que o array `NAV` já usa pra outras 3 entradas (`pipeline`, `cadastroAtivos`, `mapa`) — um 6º elemento `true` na linha da rota, que `buildNav()` já respeita (`if(hideNav) return;` antes de desenhar o botão, mas **não** bloqueia a rota em si — só o item some da lista visual). Aplicado o mesmo em `pesquisa`, `ativacao` e `ttfv`. As três telas continuam 100% funcionais — `App.go('pesquisa')`, por exemplo, ainda funciona normalmente — só não aparecem mais como botão na sidebar.

**Combinado com o usuário:** lembrar dele sobre essas 3 telas ocultas quando fizer sentido — por exemplo, se ele pedir uma visão de portfólio (todos os clientes) de pesquisa/ativação/TTFV antes dos Dashboards ganharem essa função, ou se pedir pra reativar/apagar de vez. Registrado também em memória (fora deste arquivo) pra persistir entre sessões.

**Teste:** verificado ao vivo — sidebar não mostra mais as 3 entradas (grupo OPERAÇÃO ficou só com Dashboards/Jornada do Cliente/Cadastro), sem erros de console.

---

## 2026-09-25 (13) — Cadastro: card "Dados da Holding" no mesmo estilo compacto da Nova Operação, Ativos/Documentos trocados de posição

**Contexto:** usuário mandou prints comparando o card "Dados da Holding" (Cadastro) — campos largos, um por linha, layout de grid 2 colunas — com o cabeçalho da "Nova Operação" (Jornada) — campos compactos, vários por linha, tamanhos proporcionais ao conteúdo. Pediu pra deixar o Cadastro parecido, mas sem os campos que só fazem sentido em Nova Operação (buscador de cliente, Número da Operação, Status). Também pediu pra trocar a ordem dos cards "Ativos" e "Documentos" na ficha do cliente, e confirmar que o formulário de cadastro de Ativo dentro do Cadastro é igual ao da Nova Operação.

**Decisão — `.form-grid` trocado por `.form-flow`:** o card "Dados da Holding" (`renderFicha()`) usava `.form-grid` (grid CSS de 2 colunas iguais — cada campo ocupa ~50% da largura do card, por isso ficavam tão largos). Trocado pra `.form-flow` (flex-wrap com larguras fixas por classe — `f-xs`/`f-sm`/`f-md`/`f-lg`/`f-xl`/`f-full`), o mesmo sistema que a Nova Operação já usa. Larguras escolhidas espelhando os papéis equivalentes em Nova Operação: Razão Social `f-xl` (300px, como lá), Nome Fantasia `f-lg` (230px, como o "Nome Comercial" de lá), CNPJ `f-md` (200px, igual), Estado `f-xs` (86px, como o "UF" de lá), Cidade `f-lg` (230px, igual), Classificação `f-xs` (86px). Cliente Elite (checkbox) sem largura fixa, mesmo padrão de "rótulo invisível `&nbsp;` pra alinhar verticalmente" já usado no campo "Representante principal" da ficha.

**Endereço movido pro fim do card (agora `f-full`):** antes ficava entre CNPJ e Estado, como `field full` num grid — no meio de uma fileira, isso quebraria o fluxo em 3 linhas em vez de 2. Movido pra depois de Cliente Elite, mesmo padrão da Nova Operação (que também deixa seu único campo full-width — Observações — por último). "Operações" (lista de chips, só aparece se o cliente já tiver operações no AZO) continua full-width, agora depois de Endereço.

**Ativos e Documentos trocados de posição:** ordem na ficha do cliente agora é Dados da Holding → Representantes → **Ativos** → **Documentos** → (nota da Jornada) → Timeline (antes Documentos vinha antes de Ativos). Só reordenação de blocos no HTML, nenhuma lógica mudou.

**Ativo do Cadastro já era idêntico ao da Nova Operação — nenhuma mudança necessária:** `ativoAccordionMarkup()` (documentado em 2026-09-22 como componente compartilhado) é chamada tanto por `opAtivoListRender()` (Nova Operação, prefixo `opAtivo`) quanto por `cadAtivoListRender()` (Cadastro → "Ver / Adicionar Ativos", prefixo `cadAtivo`) — é literalmente a mesma função, não duas cópias parecidas. Confirmado ao vivo (accordion expandido em ambos os contextos, visual idêntico).

**Teste:** verificado ao vivo em BARION EMPREENDIMENTOS — "Dados da Holding" com Razão Social/Nome Fantasia/CNPJ/Estado/Cidade/Classificação/Cliente Elite numa fileira só, Endereço full-width abaixo; ordem Ativos→Documentos confirmada; accordion de Ativo (via "Ver / Adicionar Ativos") com o mesmo layout do Ativo em Nova Operação. Sem erros de console.

---

## 2026-09-25 (14) — Ativos do Cadastro embutidos na ficha (sem precisar salvar antes), "aglutinar tudo", Cliente Elite virou select

**Contexto:** usuário testou a rodada anterior e pediu três ajustes: (1) o card de Ativos do Cadastro ainda exigia salvar o cliente primeiro ("Salve o cadastro para adicionar ativos") antes de poder editar ativos — indo pra uma página separada (`renderCadastroAtivos`) — e o pedido foi "isso não é necessário", ficar igual à Nova Operação (que edita ativos direto na mesma tela, num array de rascunho, salvos junto com o resto); (2) duas formas de aglutinar os ativos — a que já existe (cada card individualmente) e uma nova pra aglutinar/expandir todos de uma vez; (3) "Cliente Elite" devia virar um `<select>` Sim/Não como já é na Nova Operação, em vez de checkbox.

**Decisão — Ativos passam a viver embutidos em `renderFicha()`, não mais numa página própria:** `_cadAtivos` (o array de edição, que já existia e já tinha toda a lógica de CRUD — `cadAtivoAdd/Del/Dup/Toggle/Set/...` — reaproveitada dos tempos da página dedicada `renderCadastroAtivos`) agora é inicializado dentro do próprio `renderFicha()` (a partir de `c.ativos`, vazio pra cliente novo) e `cadAtivoListRender()` é chamada no fim da função, igual `representanteListRender()`/`documentoListRender()`. O card "Ativos" perdeu o botão "Ver / Adicionar Ativos" (que navegava pra `App.go('cadastroAtivos')`) e ganhou o mesmo accordion embutido que a Nova Operação já tinha — inclusive pra cliente **ainda não salvo** (`id==='__new__'`), sem aviso nenhum bloqueando.

**Decisão — salvar ativos junto do resto do cadastro, num `save()` só:** `salvarFicha()` ganhou a mesma lógica de normalização/diff que `salvarAtivosCliente()` já tinha (extraída pra uma função compartilhada `normalizarAtivosLista(list, ativosAntes)`, usada pelos dois agora) — assim, criar um cliente novo com ativos já preenchidos grava cliente + ativos + histórico numa única chamada de `save(d)`, sem precisar de um segundo passo de "Salvar Ativos". `abrirAtivosCliente()`/`renderCadastroAtivos()`/`salvarAtivosCliente()` continuam definidos (sem call site do botão que os acionava) — mesmo padrão do projeto de deixar função JS sem uso como referência, em vez de apagar.

**Decisão — gating de permissão usa `canAtivos()`, não `can('editClient')`:** a página antiga (`renderCadastroAtivos`) gatava edição de ativos por `canAtivos()` (perfis Onboarding/Gestão Executiva), diferente da permissão geral da ficha (`editClient`). Pra não afrouxar essa regra ao embutir, `renderFicha()` ganhou uma segunda flag `roAtivos=!canAtivos()`, usada só nos botões do card de Ativos — o resto da ficha continua usando `ro=!can('editClient')`.

**Feature nova — "aglutinar/expandir tudo":** `cadAtivoToggleAll()`/`opAtivoToggleAll()` (App) — se algum ativo está aberto, fecha todos; se todos estão fechados, abre todos. Adicionado tanto no Cadastro quanto na Nova Operação (pra manter os dois em paridade, já que o pedido do usuário compara explicitamente as duas telas). **Bug pego no teste:** a primeira versão só chamava `cadAtivoListRender()`/`opAtivoListRender()` ao clicar, que só substitui o `innerHTML` da lista — o texto do próprio botão (calculado uma vez, na hora que `renderFicha()`/`renderNovaOperacao()` monta o HTML inteiro) ficava desatualizado (sempre "Expandir tudo", mesmo depois de abrir tudo). Corrigido dando `id` ao botão (`cad_ativos_toggle_all`/`op_ativos_toggle_all`) e atualizando seu `innerHTML` também dentro do `*ListRender()`, via uma função compartilhada `ativosToggleAllLabel(list)`.

**Cliente Elite → `<select>` Sim/Não:** trocado o checkbox (`<input type="checkbox">`) por um `<select>` igual ao da Nova Operação (`<option>Não</option><option>Sim</option>`), removendo também o truque de `<label>&nbsp;</label>` que existia só pra alinhar o checkbox verticalmente com os outros campos (não precisa mais, já que agora é um campo normal com label visível). `salvarFicha()` ajustado pra ler `el('f_elite').value==='Sim'` em vez de `.checked`.

**Teste:** verificado ao vivo em BARION (cliente existente — expandir/aglutinar tudo funcionando, contador de ativos e texto do botão atualizando corretamente nos dois sentidos) e num cliente novo criado só pra teste (Ativo adicionado ANTES de salvar, cliente + ativo confirmados persistidos juntos via `DB()` após salvar, com `elite:false` do select). Dado de teste removido depois (cliente, ativo e as 2 linhas de histórico geradas, localmente e no Supabase). Sem erros de console em nenhum momento.

---

## 2026-09-25 (15) — Número da Operação: reordenado no cabeçalho ("#nº | Nome") e editável no sidebar de Contexto

**Contexto:** o link clicável do número da operação no AZO (`azoProposalUrl`, já existente desde a rodada de 23/09) já estava implementado no `jcard-title`, mas depois do nome do cliente. O usuário pediu duas coisas: (1) o número vir **antes** do nome, separado por `|` (formato do exemplo: `#00000 | BARION EMPREENDIMENTOS IMOBILIARIOS LTDA.`); (2) um campo editável no sidebar de Contexto pra corrigir esse número quando necessário — hoje só dava pra editar via formulário de "Nova Operação"/ficha do cliente, não direto na Jornada.

**Decisão — reordenar `jcard-title`:** trocada a ordem (número antes do `<h2>`) e adicionado um separador `<span class="jop-num-sep">|</span>` entre os dois — mantido o mesmo `.jop-num` (pílula azul clicável, sem redesenho, já aprovado antes) só reposicionado. `azoProposalUrl(numero)` não mudou — já gerava exatamente `https://trinus.azo.blue/#/workflows/11/proposals/details/${numero}`, o formato que o usuário pediu.

**Decisão — campo "Número da Operação" no sidebar de Contexto:** novo bloco no topo do primeiro painel do `jContexto()` (antes de "Responsáveis"), reaproveitando o mesmo padrão de edição inline já usado pros campos de Responsáveis (`jCtxEditField`/`App.jRespEditToggle`/`App.jRespSet` — não precisou de nenhuma função nova, só um novo `campo` genérico `'numeroOperacao'` passando pelo `jRespSet` já existente, que já era genérico o bastante: `c[campo]=valor`). Mostra `#<número>` ou `—` quando vazio, com lápis de edição ao lado (`ro` = `!can('editClient')`, mesma permissão do resto da ficha). `LBL` do histórico ganhou `numeroOperacao:'Número da Operação'` pra um rótulo legível no Histórico de Alterações em vez do nome cru do campo.

**Teste:** verificado ao vivo em BARION — editado o número via sidebar (`36710`, o mesmo do exemplo de link do usuário), confirmado que: o cabeçalho passou a mostrar `#36710 | BARION EMPREENDIMENTOS IMOBILIARIOS LTDA.`, o link do badge aponta pra `https://trinus.azo.blue/#/workflows/11/proposals/details/36710` (checado via `.jop-num.href`), o sidebar mostra `#36710` com o lápis, e o valor persistiu em `DB()`. Revertido pra vazio depois do teste (não é dado real do cliente). Sem erros de console.


---

## 2026-09-25 (18) — Auditoria completa (2ª rodada): 20 correções de código, 6 pontos críticos deixados para aprovação

**Contexto:** a 1ª rodada da auditoria (feita sem supervisão) foi interrompida por queda da sessão. Nesta 2ª rodada o usuário logou no app, no painel do Supabase e no GitHub, e autorizou corrigir tudo que não fosse crítico. Critério adotado: corrigir direto o que é código/visual/configuração sem risco a dados; **só reportar** o que mexe em estrutura/regras de segurança do banco, apaga ou migra dados, ou muda regra de negócio. Relatório completo em `AUDITORIA.md`; scripts SQL propostos (não aplicados) em `sql/`.

**Decisão — acesso a rotas passa a ser "bloqueado por padrão":** `navAllowed()` usava `NAV_ACCESS[key]||PERFIS` — com `PERFIS` incluindo "Middle", qualquer rota sem entrada explícita ficava aberta a Middle (foi o que aconteceu com `mapa`, esquecido na rodada 16). Agora rota sem entrada em `NAV_ACCESS` é negada para todos; `mapa` e `cadastroAtivos` ganharam entrada explícita. As abas Executivo/Pipeline/Mapa do Dashboard também passaram a ser filtradas por `navAllowed`.

**Decisão — trilha de auditoria somente leitura na interface:** "Limpar histórico" e o "apagar" por linha só mexiam no array local (o histórico é gravado direto no banco por `addHistory` e não passa pelo `save()`), então diziam "Histórico limpo" sem apagar nada. Em vez de "consertar" apagando no banco, os botões e as funções `limparHistorico`/`delHistorico` foram removidos — histórico de alterações não deve ser apagável. As chaves `clearHistory`/`deleteHistory` continuam em `PERMS`, sem uso.

**Decisão — login só é registrado quando é login de verdade:** `entrarComUsuario()` registrava login + linha de histórico também na restauração de sessão ao recarregar a página (`boot()`), inflando 251 logins e 339 históricos com um único usuário. `boot()` agora passa `{restaurada:true}` e o registro é pulado.

**Decisão — formulário antigo de cliente aposentado:** `App.editCliente` e `App.novoCliente` abriam `clienteModal` (formulário antigo, anterior à ficha do Cadastro), chamados por "Gerenciar no cadastro"/"Editar" da aba Ativos (o "Editar" foi criado por mim na rodada 16 apontando pro lugar errado) e por "Novo Cliente" do Pipeline. Os dois atalhos agora delegam para `abrirFicha`/`novaFicha`. `clienteModal` e `ativoListRender` ficam no arquivo sem uso, no padrão do projeto de não apagar código legado.

**Decisão — defesa contra dados forjados no banco:** como as políticas RLS atuais deixam qualquer usuário logado escrever em qualquer tabela (crítico 1.2 do relatório), dois vetores de injeção de script foram fechados no código: IDs fora de `^[A-Za-z0-9_-]{1,80}$` são descartados em `loadFromSupabase()` (IDs vão para dentro de `onclick="App.x('<id>')"`), e links de download passam por `anxHref()`, que só aceita `data:…;base64`. `esc()` passou a escapar aspas simples. Conferido antes de aplicar que nenhum registro atual tem ID fora do padrão.

**Decisão — cores do KPI unificadas sem mudar o visual:** havia dois blocos `.kpi{}` completos (dois designs), cada card com barra superior (`::before`, cor via `--kpi-accent`) e barra lateral (`::after`, cor fixa por variante). As cores divergiam em `k-navy` (sem `--kpi-accent`), `k-purple` e `k-blue`. A barra lateral passou a usar `var(--kpi-accent)` e `k-navy` ganhou a variável — mesmo visual, cores consistentes. Medido ao vivo com `getComputedStyle` nos 5 primeiros cards do Dashboard.

**Outras correções:** Gestão de Usuários marca como "Aguardando 1º acesso" (sem botões) as pessoas que só existem em `USERS_SEED` — antes Editar/Desativar/Remover diziam sucesso sem efeito no banco; removido o botão "Restaurar dados de exemplo" (sobrescrevia dados reais com o `seed()`); textos de "Restaurar backup" corrigidos (é mesclagem, não substituição); aba Documentos da Jornada passou a listar também os documentos do Cadastro, com download; seletor de Etapa mostra valor antigo como "(etapa antiga)" em vez de "—" (`etapaAtivoOptions`); cards de Kanban só arrastáveis com permissão; "1 dias" → "1 dia"; texto da página Tarefas (clique duplo); dados de exemplo com Etapa nova.

**Configuração externa:** GitHub Pages desligado de vez (branch = None) — só "Unpublish" não bastava, o próximo push republicaria o site antigo, público e sem o Cloudflare Access. A correção do Site URL de autenticação do Supabase (`http://localhost:3000` → `onboardops.pages.dev`) foi **bloqueada pelo classificador do modo automático** e ficou para o usuário.

**Teste:** 19 rotas + 64 combinações cliente×aba da Jornada + 8 fichas de Cadastro sem erro de JavaScript nem texto quebrado; 5 perfis simulados via personificação com rotas, abas do Dashboard e cards arrastáveis conferidos; recarregamento confirmado sem novo registro de login (contagem 251/339 inalterada). Nenhum dado do banco foi alterado nesta rodada.
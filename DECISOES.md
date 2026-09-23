# Decisões — OnboardOps

Registro de decisões de arquitetura e padrões adotados no projeto. Cada entrada é permanente: se uma decisão for revista depois, adiciona-se uma nova entrada explicando a mudança, sem apagar a anterior.

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

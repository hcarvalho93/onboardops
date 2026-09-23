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

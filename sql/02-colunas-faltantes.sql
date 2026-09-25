-- =============================================================================
-- OnboardOps · PROPOSTA de colunas faltantes (NÃO APLICADA)
-- Auditoria 2026-09-25 — ver AUDITORIA.md, "perda de dados ao recarregar".
--
-- Campos que a interface deixa preencher, mas que hoje somem quando a página
-- recarrega, porque não existe coluna no banco para eles. Só adiciona colunas
-- (nada é apagado ou alterado). Depois de aplicar, o código precisa passar a
-- enviar/ler esses campos (activityToRow/rowToActivity, interactionToRow/
-- rowToInteraction, ttfvToRow/rowToTtfv) — a ordem importa: banco primeiro,
-- código depois, senão o salvamento quebra por "coluna inexistente".
-- =============================================================================
begin;

alter table public.activities
  add column if not exists tags             text[] default '{}',
  add column if not exists origem           text,
  add column if not exists origem_interacao text,
  add column if not exists ativo_id         text;

alter table public.interactions
  add column if not exists ativo_id       text,
  add column if not exists atividade_id   text,
  add column if not exists pontos_atencao text,
  add column if not exists decisoes       text,
  add column if not exists pendencias     text,
  add column if not exists satisfacao     smallint check (satisfacao between 1 and 5);

alter table public.ttfv
  add column if not exists tipo_outra text;

commit;

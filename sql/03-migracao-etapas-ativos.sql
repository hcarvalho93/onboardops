-- =============================================================================
-- OnboardOps · PROPOSTA de migração das Etapas dos Ativos (NÃO APLICADA)
-- 24 de 39 ativos ainda usam a nomenclatura antiga (antes da troca de
-- "Status do Ativo" para "Etapa"). O mapeamento abaixo é uma SUGESTÃO —
-- confirme cada linha antes de rodar; é decisão de negócio.
--
--   Pós-obra        -> Pós-obras        (mesma coisa, só plural)      4 ativos
--   Entrega         -> Pós-obras  ?     (obra entregue)               9 ativos
--   Comercialização -> Lançamento ?     (em vendas)                   6 ativos
--   Estruturação    -> Pré-lançamento ? (antes de lançar)             5 ativos
-- =============================================================================
begin;
update public.ativos set status_ativo = 'Pós-obras'      where status_ativo = 'Pós-obra';
update public.ativos set status_ativo = 'Pós-obras'      where status_ativo = 'Entrega';
update public.ativos set status_ativo = 'Lançamento'     where status_ativo = 'Comercialização';
update public.ativos set status_ativo = 'Pré-lançamento' where status_ativo = 'Estruturação';
commit;

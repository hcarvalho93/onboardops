-- =============================================================================
-- OnboardOps · PROPOSTA de correção de segurança (NÃO APLICADA)
-- Auditoria 2026-09-25 — ver AUDITORIA.md, seção "Críticos".
-- Rodar no SQL Editor do Supabase SÓ depois de aprovado. Tudo em uma transação.
--
-- O que muda:
--  1. Ninguém escolhe o próprio perfil ao criar conta: toda conta nova nasce
--     "Área Parceira" (somente leitura) e a Gestão Executiva promove depois
--     pela tela de Gestão de Usuários.
--  2. Tabela users: todos leem; só Gestão Executiva/Desenvolvedor alteram.
--  3. Histórico e logins viram trilha imutável: dá pra ler e inserir, nunca
--     editar nem apagar.
--  4. Demais tabelas: leitura para qualquer usuário ativo; escrita só para
--     perfis com permissão de edição (todos menos Área Parceira).
--
-- Efeito colateral a saber: os 9 colegas pré-cadastrados no código
-- (USERS_SEED) passam a entrar como Área Parceira no 1º acesso e precisam ser
-- promovidos manualmente — é o preço de não confiar no perfil informado pelo
-- navegador.
-- =============================================================================
begin;

-- helpers (security definer: leem o perfil do próprio usuário ignorando RLS)
create or replace function public.meu_perfil() returns text
language sql stable security definer set search_path = public as $$
  select perfil from public.users where id = auth.uid() and coalesce(ativo, true)
$$;

create or replace function public.sou_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(public.meu_perfil() in ('Gestão Executiva','Desenvolvedor'), false)
$$;

create or replace function public.posso_editar() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(public.meu_perfil() in ('Gestão Executiva','Desenvolvedor','Onboarding','Key Account','Middle'), false)
$$;

-- 1) conta nova nunca escolhe o próprio perfil
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.users (id, nome, email, perfil, cargo)
  values (new.id, coalesce(new.raw_user_meta_data->>'nome', new.email), new.email,
          'Área Parceira', new.raw_user_meta_data->>'cargo')
  on conflict (id) do nothing;
  return new;
end; $$;

-- 2) users
drop policy if exists "authenticated full access" on public.users;
create policy users_leitura on public.users for select to authenticated using (true);
create policy users_admin   on public.users for all    to authenticated
  using (public.sou_admin()) with check (public.sou_admin());

-- 3) trilha de auditoria imutável
drop policy if exists "authenticated full access" on public.history;
create policy history_leitura on public.history for select to authenticated using (public.meu_perfil() is not null);
create policy history_insere  on public.history for insert to authenticated with check (true);

drop policy if exists "authenticated full access" on public.logins;
create policy logins_leitura on public.logins for select to authenticated using (public.sou_admin());
create policy logins_insere  on public.logins for insert to authenticated with check (true);

-- 4) dados operacionais
do $$
declare t text;
begin
  foreach t in array array['clientes','ativos','representantes','operacoes','activities',
                           'interactions','propostas','surveys','activation','ttfv','config']
  loop
    execute format('drop policy if exists "authenticated full access" on public.%I', t);
    execute format('create policy %I on public.%I for select to authenticated using (public.meu_perfil() is not null)', t||'_leitura', t);
    execute format('create policy %I on public.%I for all to authenticated using (public.posso_editar()) with check (public.posso_editar())', t||'_escrita', t);
  end loop;
end $$;

commit;

-- Conferência depois de aplicar:
-- select tablename, policyname, cmd from pg_policies where schemaname='public' order by 1,2;

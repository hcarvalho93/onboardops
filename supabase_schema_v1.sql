-- ============================================================
-- OnboardOps — schema inicial (espelha o modelo de dados atual
-- do localStorage). Rodado no projeto "onboardops" / org "Trinus".
-- ============================================================

create extension if not exists pgcrypto;

-- ---------- CLIENTES ----------
create table public.clientes (
  id text primary key,
  nome text not null,
  cnpj text,
  produtos text[] not null default '{}',
  tipologia text,
  data_assinatura date,
  data_kickoff date,
  go_live_previsto date,
  go_live_real date,
  resp_onboarding text,
  key_account text,
  resp_comercial text,
  resp_kickoff text,
  status text,
  etapa text,
  obs text,
  estado text,
  cidade text,
  criado_em date,
  criado_por text,
  etiquetas text[] not null default array[]::text[],  -- v2 (2026-09-23): tags livres do painel de Contexto da Jornada
  prioridade text,                                     -- v2 (2026-09-23): Alto / Médio / Baixo
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- ATIVOS (empreendimentos/SPEs de cada cliente) ----------
create table public.ativos (
  id text primary key,
  cliente_id text not null references public.clientes(id) on delete cascade,
  nome text not null,
  estado text,
  cidade text,
  regiao text,
  tipologia text,
  quantidade int default 1,
  unidades int default 0,
  vgv numeric default 0,
  status_ativo text,
  criado_em date,
  criado_por text,
  obs text,
  created_at timestamptz not null default now()
);

-- ---------- PESQUISA PÓS-KICKOFF ----------
create table public.surveys (
  cliente_id text primary key references public.clientes(id) on delete cascade,
  data_resposta date,
  q1 int, q2 int, q3 int, q4 int, q5 int,
  comentarios text,
  created_at timestamptz not null default now()
);

-- ---------- ATIVAÇÃO OPERACIONAL ----------
-- Guardado como JSON por enquanto: a lista de itens/marcos ainda vai ser
-- redesenhada (regra "cada serviço contratado gera um item de ativação").
create table public.activation (
  cliente_id text primary key references public.clientes(id) on delete cascade,
  items jsonb not null default '{}',
  dates jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- TIME TO FIRST VALUE ----------
create table public.ttfv (
  cliente_id text primary key references public.clientes(id) on delete cascade,
  tipo text,
  data_valor date,
  created_at timestamptz not null default now()
);

-- ---------- ATIVIDADES (Pendências) ----------
create table public.activities (
  id text primary key,
  cliente_id text references public.clientes(id) on delete cascade,
  titulo text not null,
  descricao text,
  responsavel text,
  prioridade text,
  status text,
  criacao date,
  prazo date,
  data_conclusao date,
  created_at timestamptz not null default now()
);

-- ---------- INTERAÇÕES ----------
create table public.interactions (
  id text primary key,
  cliente_id text references public.clientes(id) on delete cascade,
  data date,
  hora text,
  canal text,
  responsavel text,
  tipo text,
  status text,
  resumo text,
  texto text,
  proxima_acao text,
  prazo_acao date,
  tags text[] default '{}',
  anexos jsonb default '[]',
  kind text default 'evento',
  created_at timestamptz not null default now()
);

-- ---------- PROPOSTAS (pipeline comercial) ----------
-- cliente é texto livre (nome da empresa) porque o pipeline inclui prospects
-- que ainda não têm registro em "clientes" — decisão pendente sobre o Pipeline.
create table public.propostas (
  id text primary key,
  cliente_nome text not null,
  status text,
  valor numeric default 0,
  booked_value numeric default 0,
  produto text,
  produtos text[] default '{}',
  responsavel text,
  data_elaboracao date,
  data_prevista date,
  data_aprovacao date,
  data_assinatura date,
  data_perdida date,
  obs text,
  created_at timestamptz not null default now()
);

-- ---------- USUÁRIOS (perfil do app; senha fica no auth.users do Supabase) ----------
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text not null,
  email text not null unique,
  perfil text not null,
  cargo text,
  ativo boolean not null default true,
  created_at timestamptz not null default now()
);

-- ---------- HISTÓRICO / AUDITORIA ----------
create table public.history (
  id text primary key,
  usuario text,
  perfil text,
  data date,
  hora text,
  iso timestamptz not null default now(),
  modulo text,
  cliente text,
  campo text,
  de text,
  para text
);

-- ---------- LOGINS (log de acesso) ----------
create table public.logins (
  id uuid primary key default gen_random_uuid(),
  usuario text,
  email text,
  perfil text,
  data date,
  hora text,
  iso timestamptz not null default now()
);

-- ---------- CONFIGURAÇÃO (linha única) ----------
create table public.config (
  id int primary key default 1,
  empresa text default 'Trinus',
  tagline text default 'Portal de Customer Success & Jornada do Cliente',
  thr jsonb default '{"saudavel":70,"atencao":40}',
  escala_imediata int default 30,
  escala_semanal int default 50,
  produtos text[] default '{}',
  tipologias text[] default '{}',
  constraint config_singleton check (id = 1)
);
insert into public.config (id) values (1);

-- ============================================================
-- RLS — todas as tabelas exigem login; qualquer usuário autenticado
-- tem acesso total (mesmo nível de confiança que já existe hoje,
-- em que qualquer usuário logado lê/grava tudo no sistema).
-- ============================================================
alter table public.clientes enable row level security;
alter table public.ativos enable row level security;
alter table public.surveys enable row level security;
alter table public.activation enable row level security;
alter table public.ttfv enable row level security;
alter table public.activities enable row level security;
alter table public.interactions enable row level security;
alter table public.propostas enable row level security;
alter table public.users enable row level security;
alter table public.history enable row level security;
alter table public.logins enable row level security;
alter table public.config enable row level security;

create policy "authenticated full access" on public.clientes for all to authenticated using (true) with check (true);
create policy "authenticated full access" on public.ativos for all to authenticated using (true) with check (true);
create policy "authenticated full access" on public.surveys for all to authenticated using (true) with check (true);
create policy "authenticated full access" on public.activation for all to authenticated using (true) with check (true);
create policy "authenticated full access" on public.ttfv for all to authenticated using (true) with check (true);
create policy "authenticated full access" on public.activities for all to authenticated using (true) with check (true);
create policy "authenticated full access" on public.interactions for all to authenticated using (true) with check (true);
create policy "authenticated full access" on public.propostas for all to authenticated using (true) with check (true);
create policy "authenticated full access" on public.users for all to authenticated using (true) with check (true);
create policy "authenticated full access" on public.history for all to authenticated using (true) with check (true);
create policy "authenticated full access" on public.logins for all to authenticated using (true) with check (true);
create policy "authenticated full access" on public.config for all to authenticated using (true) with check (true);

-- ============================================================
-- Gatilho: ao criar um usuário no Supabase Auth, já cria a
-- linha correspondente em public.users automaticamente.
-- ============================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, nome, email, perfil, cargo)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nome', new.email),
    new.email,
    coalesce(new.raw_user_meta_data->>'perfil', 'Onboarding'),
    new.raw_user_meta_data->>'cargo'
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

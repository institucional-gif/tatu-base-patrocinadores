-- ============================================================
-- Base de Patrocinadores Rouanet (PJ) — Schema Postgres/Supabase
-- Dados PÚBLICOS (SalicNet/MinC). Sem dado pessoal de titulares.
-- Camada de segurança: RLS liga tudo; acesso só a membros autenticados do domínio.
-- ============================================================

-- Tabela dimensão de UFs (para joins/legendas)
create table if not exists uf (
  uf        char(2) primary key,
  nome      text not null,
  regiao    text not null
);

-- Arquivo 1: 100 maiores por UF e ano (todos os tipos de pessoa)
create table if not exists r1_incentivado_uf_ano (
  uf               text not null,
  ano              int  not null,
  vl_incentivado   numeric(16,2),
  primary key (uf, ano)
);

-- Arquivo 2: PJ por UF/região e ano (valor + nº projetos)
create table if not exists r2_pj_uf_ano (
  ano              int  not null,
  nivel            text not null check (nivel in ('uf','regiao','total')),
  nome             text not null,
  uf               char(2),
  qtd_projetos     int,
  vl_incentivado   numeric(16,2)
);

-- Arquivo 3: matriz cruzada PJ (origem x destino x ano) — tabela-base de consulta
create table if not exists r3_matriz_cruzada (
  ano        int     not null,
  inc_uf     char(2) not null,  -- UF do incentivador (origem)
  proj_uf    char(2) not null,  -- UF do projeto (destino)
  valor      numeric(16,2) not null,
  qtd        int not null,
  primary key (ano, inc_uf, proj_uf)
);
create index if not exists idx_r3_inc on r3_matriz_cruzada (inc_uf, ano);
create index if not exists idx_r3_proj on r3_matriz_cruzada (proj_uf, ano);

-- ============================================================
-- Views de consulta (o produto lê daqui, nunca das tabelas cruas)
-- ============================================================

-- Ranking de UFs de ORIGEM (de onde vem o patrocínio PJ)
create or replace view v_origem_uf as
select inc_uf as uf, sum(valor) as total_captado, sum(qtd) as aportes
from r3_matriz_cruzada group by inc_uf order by total_captado desc;

-- Ranking de UFs de DESTINO (onde os projetos são executados)
create or replace view v_destino_uf as
select proj_uf as uf, sum(valor) as total_captado, sum(qtd) as aportes
from r3_matriz_cruzada group by proj_uf order by total_captado desc;

-- Fluxos origem -> destino (ranking)
create or replace view v_fluxos as
select inc_uf as origem, proj_uf as destino, sum(valor) as total, sum(qtd) as aportes
from r3_matriz_cruzada group by inc_uf, proj_uf order by total desc;

-- ============================================================
-- SEGURANÇA — Row Level Security (contenção por ambiente)
-- Regra: SELECT liberado só para usuário autenticado; nenhuma escrita pelo app.
-- A carga de dados é feita por pipeline server-side (service_role), nunca pelo usuário.
-- ============================================================
alter table r1_incentivado_uf_ano enable row level security;
alter table r2_pj_uf_ano         enable row level security;
alter table r3_matriz_cruzada    enable row level security;
alter table uf                   enable row level security;

-- Política: qualquer usuário AUTENTICADO pode ler (a restrição de domínio é feita no login).
create policy leitura_autenticado_r1 on r1_incentivado_uf_ano for select to authenticated using (true);
create policy leitura_autenticado_r2 on r2_pj_uf_ano         for select to authenticated using (true);
create policy leitura_autenticado_r3 on r3_matriz_cruzada    for select to authenticated using (true);
create policy leitura_autenticado_uf on uf                   for select to authenticated using (true);
-- NENHUMA policy de insert/update/delete para 'authenticated' => app é read-only por construção.

-- ============================================================
-- (Opcional) Allowlist de domínio no cadastro, caso NÃO se use SSO Google.
-- Com SSO Google Workspace a restrição de domínio já vem da identidade.
-- Hook de signup (Supabase Auth Hook) deve rejeitar e-mail fora de @tatucultural.com.br.
-- ============================================================

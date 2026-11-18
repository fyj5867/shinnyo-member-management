-- 信徒管理系統：Supabase 初始資料表與 RLS
-- 先建立一個組織，再由管理者建立/加入 auth.users 對應的 memberships。
create extension if not exists pgcrypto;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);
create table if not exists public.memberships (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','admin','seat_manager','finance','viewer')),
  created_at timestamptz not null default now(),
  unique(org_id,user_id)
);
create table if not exists public.seats (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  parent_seat_id uuid references public.seats(id),
  leader_person_id uuid,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.people (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  person_code text,
  full_name text not null,
  phone text,
  membership_status text not null default 'member' check (membership_status in ('member','non_member')),
  joined_on date,
  seat_id uuid references public.seats(id) on delete set null,
  notes text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.person_relationships (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  mentor_person_id uuid not null references public.people(id) on delete cascade,
  disciple_person_id uuid not null references public.people(id) on delete cascade,
  relationship_type text not null default 'disciple' check (relationship_type in ('disciple')),
  valid_from date,
  valid_to date,
  created_at timestamptz not null default now(),
  check (mentor_person_id <> disciple_person_id),
  unique(org_id,mentor_person_id,disciple_person_id)
);
create table if not exists public.annual_applications (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  person_id uuid not null references public.people(id) on delete cascade,
  application_year integer not null,
  star_supply boolean not null default false,
  set_purchase boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(org_id,person_id,application_year)
);
create table if not exists public.fee_records (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  person_id uuid not null references public.people(id) on delete cascade,
  fee_year integer not null,
  fee_type text not null check (fee_type in ('苑費','祈年證','星供','套子')),
  quantity numeric(10,2) not null default 1,
  amount_due numeric(12,2) not null default 0,
  amount_paid numeric(12,2) not null default 0,
  paid_at date,
  received_by uuid references auth.users(id),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  actor_user_id uuid references auth.users(id),
  table_name text not null,
  record_id uuid,
  action text not null,
  changed_at timestamptz not null default now()
);

create or replace function public.is_org_member(target_org uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.memberships m where m.org_id=target_org and m.user_id=auth.uid()) $$;

create or replace function public.has_org_role(target_org uuid, allowed text[])
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.memberships m where m.org_id=target_org and m.user_id=auth.uid() and m.role=any(allowed)) $$;

alter table public.organizations enable row level security;
alter table public.memberships enable row level security;
alter table public.seats enable row level security;
alter table public.people enable row level security;
alter table public.person_relationships enable row level security;
alter table public.annual_applications enable row level security;
alter table public.fee_records enable row level security;
alter table public.audit_logs enable row level security;

create policy "org members read organization" on public.organizations for select using (public.is_org_member(id));
create policy "members read own org memberships" on public.memberships for select using (public.is_org_member(org_id));
create policy "authorized managers manage memberships" on public.memberships for all using (public.has_org_role(org_id,array['owner','admin'])) with check (public.has_org_role(org_id,array['owner','admin']));

create policy "members read seats" on public.seats for select using (public.is_org_member(org_id));
create policy "admins manage seats" on public.seats for all using (public.has_org_role(org_id,array['owner','admin'])) with check (public.has_org_role(org_id,array['owner','admin']));

create policy "members read people" on public.people for select using (public.is_org_member(org_id));
create policy "authorized roles manage people" on public.people for all using (public.has_org_role(org_id,array['owner','admin','seat_manager'])) with check (public.has_org_role(org_id,array['owner','admin','seat_manager']));

create policy "members read relationships" on public.person_relationships for select using (public.is_org_member(org_id));
create policy "authorized roles manage relationships" on public.person_relationships for all using (public.has_org_role(org_id,array['owner','admin','seat_manager'])) with check (public.has_org_role(org_id,array['owner','admin','seat_manager']));

create policy "members read applications" on public.annual_applications for select using (public.is_org_member(org_id));
create policy "authorized roles manage applications" on public.annual_applications for all using (public.has_org_role(org_id,array['owner','admin','seat_manager'])) with check (public.has_org_role(org_id,array['owner','admin','seat_manager']));

create policy "finance roles read fees" on public.fee_records for select using (public.has_org_role(org_id,array['owner','admin','finance']));
create policy "finance roles manage fees" on public.fee_records for all using (public.has_org_role(org_id,array['owner','admin','finance'])) with check (public.has_org_role(org_id,array['owner','admin','finance']));

create policy "admins read audit logs" on public.audit_logs for select using (public.has_org_role(org_id,array['owner','admin']));
-- audit_logs 不開放前端直接新增/修改；正式版需用 trigger 或受控 RPC 寫入。

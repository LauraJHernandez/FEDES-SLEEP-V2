-- Fede's Sleep 2.0 — Supabase SQL
-- Ejecuta todo este archivo en Supabase > SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.families (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 invite_code text not null unique default upper(substr(encode(gen_random_bytes(8),'hex'),1,10)),
 created_at timestamptz not null default now()
);
create table if not exists public.family_members (
 family_id uuid not null references public.families(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null default 'parent' check (role in ('admin','parent')),
 created_at timestamptz not null default now(),
 primary key(family_id,user_id),
 unique(user_id)
);
create table if not exists public.entries (
 id uuid primary key default gen_random_uuid(),
 family_id uuid not null references public.families(id) on delete cascade,
 created_by uuid not null references auth.users(id),
 kind text not null check(kind in ('sleep','feed','diaper','symptom','note')),
 occurred_at timestamptz not null,
 ended_at timestamptz,
 details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create index if not exists entries_family_time_idx on public.entries(family_id,occurred_at desc);
-- Security-definer helper avoids recursive RLS checks on family_members.
create or replace function public.is_family_member(target_family uuid)
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.family_members where family_id=target_family and user_id=auth.uid());
$$;
revoke all on function public.is_family_member(uuid) from public;
grant execute on function public.is_family_member(uuid) to authenticated;
alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.entries enable row level security;
drop policy if exists "members read own family" on public.families;
drop policy if exists "members read membership" on public.family_members;
drop policy if exists "members read entries" on public.entries;
drop policy if exists "members insert entries" on public.entries;
drop policy if exists "members update entries" on public.entries;
drop policy if exists "members delete entries" on public.entries;
create policy "members read own family" on public.families for select to authenticated using (public.is_family_member(id));
create policy "members read membership" on public.family_members for select to authenticated using (user_id=auth.uid() or public.is_family_member(family_id));
create policy "members read entries" on public.entries for select to authenticated using (public.is_family_member(family_id));
create policy "members insert entries" on public.entries for insert to authenticated with check (created_by=auth.uid() and public.is_family_member(family_id));
create policy "members update entries" on public.entries for update to authenticated using (public.is_family_member(family_id)) with check (public.is_family_member(family_id));
create policy "members delete entries" on public.entries for delete to authenticated using (public.is_family_member(family_id));
create or replace function public.create_family(family_name text)
returns uuid language plpgsql security definer set search_path=public as $$
declare new_id uuid;
begin
 if auth.uid() is null then raise exception 'Debes iniciar sesión'; end if;
 if exists(select 1 from family_members where user_id=auth.uid()) then raise exception 'Esta cuenta ya pertenece a una familia'; end if;
 insert into families(name) values (family_name) returning id into new_id;
 insert into family_members(family_id,user_id,role) values(new_id,auth.uid(),'admin');
 return new_id;
end; $$;
create or replace function public.join_family(invite_code_input text)
returns uuid language plpgsql security definer set search_path=public as $$
declare target_id uuid;
begin
 if auth.uid() is null then raise exception 'Debes iniciar sesión'; end if;
 if exists(select 1 from family_members where user_id=auth.uid()) then raise exception 'Esta cuenta ya pertenece a una familia'; end if;
 select id into target_id from families where invite_code=upper(trim(invite_code_input));
 if target_id is null then raise exception 'Código de invitación no válido'; end if;
 insert into family_members(family_id,user_id,role) values(target_id,auth.uid(),'parent');
 return target_id;
end; $$;
revoke all on function public.create_family(text) from public;
revoke all on function public.join_family(text) from public;
grant execute on function public.create_family(text) to authenticated;
grant execute on function public.join_family(text) to authenticated;
grant select on public.families,public.family_members,public.entries to authenticated;
grant insert,update,delete on public.entries to authenticated;

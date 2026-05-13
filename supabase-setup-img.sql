-- Interconnected Mini-Grid Pipeline Manager — Supabase schema (img_-prefixed copy)
-- Run in Supabase Dashboard › SQL Editor.
-- This script creates a parallel set of tables prefixed with `img_` that mirror
-- the originals defined in supabase-setup.sql. The original tables are left
-- untouched. Safe to re-run: drops only the img_-prefixed objects before recreating.

drop table if exists public.img_tasks            cascade;
drop table if exists public.img_deployment_sites cascade;
drop table if exists public.img_issues           cascade;
drop table if exists public.img_team_members     cascade;
drop table if exists public.img_projects         cascade;
drop table if exists public.img_activities       cascade;

-- ─── TABLES ──────────────────────────────────────────────────────────────────

create table public.img_projects (
  id                 bigint  primary key,
  name               text    not null,
  developer          text,
  state              text,
  stage              text,
  "clusterLead"      text,
  rag                text,
  size               numeric,
  updated_at         timestamptz not null default now(),
  connections        smallint,
  loi                boolean default false,
  jda                boolean default false,
  credit             boolean default false,
  fc                 boolean default false,
  "startDate"        text default '',
  "targetCompletion" text default '',
  "actualCompletion" text default '',
  "subsidyExpected"  bigint  default 0,
  "capexPerConn"     integer default 0,
  issue              text default '',
  "lastUpdate"       text default '',
  "targetClose"      text default '',
  "updateCompliance" integer default 100,
  "evidenceCompliance" integer default 100,
  "pvCapacity"       numeric default 0,
  duration           integer default 0,
  jdacost            smallint
);

create table public.img_team_members (
  id             bigint  primary key,
  name           text    not null,
  role           text,
  assigned       integer default 0,
  "tasksDue"     integer default 0,
  updated_at     timestamptz not null default now(),
  pendingtasks   integer default 0,
  completedtasks integer default 0
);

create table public.img_issues (
  id         bigint primary key,
  project    text,
  owner      text,
  status     text,
  due        date,
  updated_at timestamptz not null default now()
);

create table public.img_deployment_sites (
  id          bigint primary key,
  sitename    text   not null,
  project     text,
  updated_at  timestamptz not null default now(),
  state       text,
  "LGA"       text,
  connections integer default 0,
  "PV"        numeric default 0
);

create table public.img_tasks (
  id           bigint primary key,
  activityname text   not null,
  project      text,
  projectstage text   check (projectstage in (
                 'Preliminary Assessment',
                 'Project Preparation',
                 'Project Development',
                 'Project Finance'
               )),
  vertical     text   check (vertical in (
                 'Technical', 'PUE', 'ESG', 'Legal', 'Procurement'
               )),
  "assignedTo" text,
  "startDate"  date,
  "dueDate"    date,
  status       text   not null default 'Pending'
               check (status in ('Pending', 'In Progress', 'Completed', 'Overdue')),
  updated_at   timestamptz not null default now()
);

create table public.img_activities (
  id               bigint  primary key,
  activityname     text    not null,
  projectstage     text,
  activitycategory text,
  updated_at       timestamptz not null default now()
);

-- ─── FUNCTIONS & TRIGGERS ────────────────────────────────────────────────────

-- Generic updated_at stamper. Identical to the function in supabase-setup.sql;
-- `create or replace` keeps both schemas using a single shared helper.
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_img_projects_updated_at
  before update on public.img_projects
  for each row execute function public.set_updated_at();

create trigger set_img_team_members_updated_at
  before update on public.img_team_members
  for each row execute function public.set_updated_at();

create trigger set_img_issues_updated_at
  before update on public.img_issues
  for each row execute function public.set_updated_at();

create trigger set_img_deployment_sites_updated_at
  before update on public.img_deployment_sites
  for each row execute function public.set_updated_at();

create trigger set_img_tasks_updated_at
  before update on public.img_tasks
  for each row execute function public.set_updated_at();

create trigger set_img_activities_updated_at
  before update on public.img_activities
  for each row execute function public.set_updated_at();

-- Generic overdue stamper. Uses only NEW, so it's shareable across both schemas.
create or replace function public.set_task_overdue()
returns trigger language plpgsql as $$
begin
  if new."dueDate" is not null
     and new."dueDate" < current_date
     and new.status not in ('Completed', 'Overdue') then
    new.status := 'Overdue';
  end if;
  return new;
end;
$$;

create trigger img_tasks_auto_overdue
  before insert or update on public.img_tasks
  for each row execute function public.set_task_overdue();

-- Per-schema sync: this one references specific tables, so it must be its own
-- function targeting img_tasks / img_team_members.
create or replace function public.img_sync_member_task_counts()
returns trigger language plpgsql as $$
declare
  old_name text;
  new_name text;
begin
  if tg_op = 'DELETE' then
    old_name := old."assignedTo";
  elsif tg_op = 'INSERT' then
    new_name := new."assignedTo";
  else
    old_name := old."assignedTo";
    new_name := new."assignedTo";
  end if;

  if old_name is not null and (tg_op = 'DELETE' or old_name is distinct from new_name) then
    update public.img_team_members set
      "tasksDue"     = (select count(*) from public.img_tasks where "assignedTo" = old_name and status = 'Overdue'),
      pendingtasks   = (select count(*) from public.img_tasks where "assignedTo" = old_name and status = 'Pending'),
      completedtasks = (select count(*) from public.img_tasks where "assignedTo" = old_name and status = 'Completed')
    where name = old_name;
  end if;

  if new_name is not null then
    update public.img_team_members set
      "tasksDue"     = (select count(*) from public.img_tasks where "assignedTo" = new_name and status = 'Overdue'),
      pendingtasks   = (select count(*) from public.img_tasks where "assignedTo" = new_name and status = 'Pending'),
      completedtasks = (select count(*) from public.img_tasks where "assignedTo" = new_name and status = 'Completed')
    where name = new_name;
  end if;

  return null;
end;
$$;

create trigger img_tasks_sync_member_counts
  after insert or update or delete on public.img_tasks
  for each row execute function public.img_sync_member_task_counts();

-- ─── ROW LEVEL SECURITY ───────────────────────────────────────────────────────

alter table public.img_projects          enable row level security;
alter table public.img_team_members      enable row level security;
alter table public.img_issues            enable row level security;
alter table public.img_deployment_sites  enable row level security;
alter table public.img_tasks             enable row level security;
alter table public.img_activities        enable row level security;

create policy "Allow browser access img_projects"
  on public.img_projects for all to anon using (true) with check (true);

create policy "Allow browser access img_team_members"
  on public.img_team_members for all to anon using (true) with check (true);

create policy "Allow browser access img_issues"
  on public.img_issues for all to anon using (true) with check (true);

create policy "Allow browser access img_deployment_sites"
  on public.img_deployment_sites for all to anon using (true) with check (true);

create policy "Allow browser access img_tasks"
  on public.img_tasks for all to anon using (true) with check (true);

create policy "Allow browser access img_activities"
  on public.img_activities for all to anon using (true) with check (true);

-- ─── OPTIONAL: daily cron to catch any tasks missed by the trigger ────────────
-- Enable pg_cron in Dashboard → Database → Extensions, then run:
-- select cron.schedule('mark-overdue-img-tasks', '0 0 * * *',
-- $$update public.img_tasks set status = 'Overdue'
-- where "dueDate" < current_date
-- and status not in ('Completed', 'Overdue')$$);

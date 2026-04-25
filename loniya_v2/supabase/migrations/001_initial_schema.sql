-- Yikri — Initial Supabase Schema
-- Run this in the Supabase SQL editor or via `supabase db push`

-- ── Profiles (extends auth.users) ────────────────────────────────────────────
create table if not exists public.profiles (
  id            uuid        primary key references auth.users(id) on delete cascade,
  phone         text        unique,
  role          text        not null default 'student'
                            check (role in ('student','teacher','parent')),
  name          text,
  grade_level   text,
  school_name   text,
  consent_given boolean     not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles: own read"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles: own update"
  on public.profiles for update
  using (auth.uid() = id);

create policy "profiles: insert on signup"
  on public.profiles for insert
  with check (auth.uid() = id);

-- ── Homework ──────────────────────────────────────────────────────────────────
create table if not exists public.homework (
  id           uuid        primary key default gen_random_uuid(),
  teacher_id   uuid        references public.profiles(id) on delete set null,
  student_id   uuid,       -- null = visible to all students
  class_code   text        not null default '',
  title        text        not null,
  subject      text        not null,
  deadline     timestamptz not null,
  duration_min integer     not null default 30,
  course_id    text        not null default '',
  status       text        not null default 'pending'
               check (status in ('pending','inProgress','done')),
  score        integer,
  assigned_at  timestamptz not null default now()
);

alter table public.homework enable row level security;

-- Teachers can insert their own homework
create policy "homework: teacher insert"
  on public.homework for insert
  with check (auth.uid() = teacher_id);

-- Teachers can read their own assignments
create policy "homework: teacher read"
  on public.homework for select
  using (teacher_id = auth.uid());

-- Students can read homework targeted at them or broadcasted (student_id IS NULL)
create policy "homework: student read"
  on public.homework for select
  using (student_id = auth.uid() or student_id is null);

-- Students can update status of homework assigned to them
create policy "homework: student status update"
  on public.homework for update
  using (student_id = auth.uid() or student_id is null)
  with check (student_id = auth.uid() or student_id is null);

-- Teachers can delete their own homework
create policy "homework: teacher delete"
  on public.homework for delete
  using (teacher_id = auth.uid());

-- ── Auto-update updated_at ────────────────────────────────────────────────────
create or replace function public.handle_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.handle_updated_at();

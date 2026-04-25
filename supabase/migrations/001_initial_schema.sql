create extension if not exists vector;

create table public.users (
  id uuid references auth.users(id) on delete cascade primary key,
  display_name text not null default 'Friend',
  recovery_start_date date, dependency_type text,
  timezone text default 'UTC', created_at timestamptz default now()
);

create table public.companions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade not null unique,
  name text not null default 'Sprout', species text not null default 'seedling',
  health int not null default 70 check (health between 0 and 100),
  happiness int not null default 70 check (happiness between 0 and 100),
  energy int not null default 70 check (energy between 0 and 100),
  trust int not null default 50 check (trust between 0 and 100),
  level int not null default 1, xp int not null default 0,
  streak int not null default 0, longest_streak int not null default 0,
  mood_state text not null default 'calm'
    check (mood_state in ('happy','calm','tired','worried','proud','sick','encouraged')),
  last_message text, last_interaction_at timestamptz,
  created_at timestamptz default now(), updated_at timestamptz default now()
);

create table public.check_ins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade not null,
  mood_score int not null check (mood_score between 1 and 10),
  craving_level int not null check (craving_level between 1 and 10),
  stress_level int not null check (stress_level between 1 and 10),
  sleep_quality int not null check (sleep_quality between 1 and 10),
  journal_text text, ai_risk_level text check (ai_risk_level in ('low','medium','high','crisis')),
  ai_emotional_summary text, ai_companion_message text, ai_raw_response jsonb,
  created_at timestamptz default now()
);

create table public.daily_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade not null,
  check_in_id uuid references public.check_ins(id),
  title text not null, description text not null,
  estimated_minutes int default 5,
  difficulty text check (difficulty in ('easy','medium','hard')) default 'easy',
  reason text, source text default 'ai',
  status text default 'pending' check (status in ('pending','completed','skipped')),
  scheduled_for date default current_date, completed_at timestamptz,
  created_at timestamptz default now()
);

create table public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade not null,
  content text not null, ai_triggers text[], ai_emotions text[],
  ai_coping_strategies text[], embedding vector(1536),
  created_at timestamptz default now()
);

create table public.support_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade not null,
  name text not null, relationship text, phone text,
  is_primary boolean default false, created_at timestamptz default now()
);

create table public.companion_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade not null,
  event_type text not null, payload jsonb, seen boolean default false,
  created_at timestamptz default now()
);

alter table public.users enable row level security;
alter table public.companions enable row level security;
alter table public.check_ins enable row level security;
alter table public.daily_tasks enable row level security;
alter table public.journal_entries enable row level security;
alter table public.support_contacts enable row level security;
alter table public.companion_events enable row level security;

create policy "own" on public.users for all using (auth.uid() = id);
create policy "own" on public.companions for all using (auth.uid() = user_id);
create policy "own" on public.check_ins for all using (auth.uid() = user_id);
create policy "own" on public.daily_tasks for all using (auth.uid() = user_id);
create policy "own" on public.journal_entries for all using (auth.uid() = user_id);
create policy "own" on public.support_contacts for all using (auth.uid() = user_id);
create policy "own" on public.companion_events for all using (auth.uid() = user_id);

create or replace function public.handle_new_user() returns trigger as $$
begin
  insert into public.users (id) values (new.id);
  insert into public.companions (user_id) values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create index on public.check_ins(user_id, created_at desc);
create index on public.daily_tasks(user_id, scheduled_for);

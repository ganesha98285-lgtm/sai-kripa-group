-- =====================================================================
--  SAI KRIPA GROUP — office database  (STEP 1)
--  Supabase -> SQL Editor -> New query -> paste -> Run
--  Ye pehle hi chal chuka hai. Dobara chalane se koi nuksaan nahi
--  ("if not exists" laga hua hai) — data safe rehta hai.
-- =====================================================================

create table if not exists clients (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  entity      text,
  phone       text,
  pan         text,
  gstin       text,
  services    text[] default '{}',
  gst_scheme  text default 'monthly',
  tm_date     date,
  tm_no       text,
  notes       text,
  created_at  timestamptz default now()
);

create table if not exists cases (
  id          uuid primary key default gen_random_uuid(),
  client_id   uuid references clients(id) on delete cascade,
  kind        text,
  section     text,
  notice_no   text,
  ay          text,
  amount      numeric,
  received_on date,
  due_on      date,
  status      text default 'Received',
  notes       text,
  history     jsonb default '[]',
  created_at  timestamptz default now()
);

create table if not exists invoices (
  id          uuid primary key default gen_random_uuid(),
  client_id   uuid references clients(id) on delete set null,
  no          text,
  date        date,
  items       jsonb default '[]',
  gst_pct     numeric default 0,
  paid        numeric default 0,
  paid_on     date,
  notes       text,
  created_at  timestamptz default now()
);

-- due date "Done" / "reminder bheja" ka record
create table if not exists deadline_marks (
  key         text primary key,
  done        boolean default false,
  reminded_on date,
  updated_at  timestamptz default now()
);

-- firm details + WhatsApp templates (ek hi row)
create table if not exists app_settings (
  id   int primary key default 1,
  data jsonb default '{}',
  constraint single_row check (id = 1)
);

-- website ke chat bot se aane wali inquiry
create table if not exists leads (
  id         uuid primary key default gen_random_uuid(),
  name       text,
  phone      text,
  service    text,
  message    text,
  source     text default 'website',
  status     text default 'New',
  created_at timestamptz default now()
);

create index if not exists idx_cases_client on cases(client_id);
create index if not exists idx_cases_due    on cases(due_on);
create index if not exists idx_inv_client   on invoices(client_id);

-- ===================== SECURITY =====================
alter table clients        enable row level security;
alter table cases          enable row level security;
alter table invoices       enable row level security;
alter table deadline_marks enable row level security;
alter table app_settings   enable row level security;
alter table leads          enable row level security;

-- login kiya hua banda hi office data dekh/badal sakta hai
do $$
declare t text;
begin
  foreach t in array array['clients','cases','invoices','deadline_marks','app_settings','leads']
  loop
    execute format('drop policy if exists office_all on %I', t);
    execute format(
      'create policy office_all on %I for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;

-- website ka chat bot bina login lead daal sakta hai (padh nahi sakta)
drop policy if exists lead_insert_public on leads;
create policy lead_insert_public on leads for insert to anon with check (true);

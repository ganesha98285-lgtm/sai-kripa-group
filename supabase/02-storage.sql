-- =====================================================================
--  SAI KRIPA GROUP — document upload  (STEP 2)
--  Supabase -> SQL Editor -> New query -> paste -> Run
--
--  Chalate waqt "Potential issue detected / destructive operations" ka
--  popup aayega -> "Run query" daba dein. Ye sirf purani security rule
--  hata ke nayi lagata hai; koi table ya data delete NAHI hota.
--
--  Iske bina upload portal kaam nahi karega.
-- =====================================================================

-- client ka secret upload token (link me yahi jaata hai)
alter table clients add column if not exists upload_token text;
create unique index if not exists idx_clients_token
  on clients(upload_token) where upload_token is not null;

-- kaunsi file aayi uska record
create table if not exists documents (
  id         uuid primary key default gen_random_uuid(),
  client_id  uuid references clients(id) on delete cascade,
  name       text,
  path       text,
  size       bigint,
  note       text,
  created_at timestamptz default now()
);
create index if not exists idx_doc_client on documents(client_id);

alter table documents enable row level security;
drop policy if exists doc_office on documents;
create policy doc_office on documents for all to authenticated
  using (true) with check (true);

-- file rakhne ki jagah (private bucket, 25 MB per file)
insert into storage.buckets (id, name, public, file_size_limit)
values ('docs', 'docs', false, 26214400)
on conflict (id) do nothing;

-- client SIRF upload kar sakta hai — dekh/download/delete nahi
drop policy if exists docs_anon_upload on storage.objects;
create policy docs_anon_upload on storage.objects for insert to anon
  with check (bucket_id = 'docs');

-- office (login kiya hua) sab kuch kar sakta hai
drop policy if exists docs_office_all on storage.objects;
create policy docs_office_all on storage.objects for all to authenticated
  using (bucket_id = 'docs') with check (bucket_id = 'docs');

-- token se sirf client ka NAAM milta hai (baaki kuch nahi)
create or replace function public.upload_lookup(tok text)
returns table(client_name text)
language sql security definer set search_path = public as $$
  select name from clients where upload_token = tok limit 1;
$$;
revoke all on function public.upload_lookup(text) from public;
grant execute on function public.upload_lookup(text) to anon, authenticated;

-- file ka record banao (galat token = reject)
create or replace function public.upload_register(
  tok text, fname text, fpath text, fsize bigint, fnote text)
returns void
language plpgsql security definer set search_path = public as $$
declare cid uuid;
begin
  select id into cid from clients where upload_token = tok;
  if cid is null then
    raise exception 'invalid token';
  end if;
  insert into documents(client_id, name, path, size, note)
  values (cid, fname, fpath, fsize, fnote);
end; $$;
revoke all on function public.upload_register(text,text,text,bigint,text) from public;
grant execute on function public.upload_register(text,text,text,bigint,text) to anon, authenticated;

-- =====================================================================
--  SAI KRIPA GROUP — website service forms  (STEP 3)
--  Supabase -> SQL Editor -> New query -> paste -> Run
--
--  Ye website ke service form ko chalu karta hai. Customer form bharega,
--  data seedha yahan aayega, aur office panel ke "Leads" tab me dikh
--  jayega — reference number aur uske document upload link ke saath.
--
--  Purana data safe hai. Ye naya table nahi banata, sirf leads table me
--  kuch extra column jodta hai.
-- =====================================================================

-- ---------------------------------------------------------------- leads
alter table leads add column if not exists ref          text;
alter table leads add column if not exists email        text;
alter table leads add column if not exists entity       text;
alter table leads add column if not exists answers      jsonb default '{}';
alter table leads add column if not exists urgency      text default 'normal';
alter table leads add column if not exists upload_token text;
alter table leads add column if not exists assigned_to  text;

create unique index if not exists idx_leads_ref
  on leads(ref) where ref is not null;
create unique index if not exists idx_leads_token
  on leads(upload_token) where upload_token is not null;
create index if not exists idx_leads_created on leads(created_at desc);

-- reference number ke liye counter (SKG-2607-0001, SKG-2607-0002 ...)
create sequence if not exists lead_ref_seq start 1;

-- ------------------------------------------------------------ documents
-- Website se aane wali request ke documents ka client abhi bana nahi hota,
-- to file ko lead se joda jata hai. Client banne par CA ise shift kar sakta
-- hai (office panel me "Client banao" dabane par).
alter table documents add column if not exists lead_id uuid
  references leads(id) on delete cascade;
create index if not exists idx_doc_lead on documents(lead_id);

-- client_id ab optional hai (lead ke documents ke liye)
alter table documents alter column client_id drop not null;

-- =====================================================================
--  FORM SUBMIT
--  Website (anon) sirf ye function call kar sakti hai. Ye ek naya lead
--  banata hai aur wapas sirf reference number + upload token deta hai —
--  kisi dusre customer ka data anon kabhi padh nahi sakta.
-- =====================================================================
create or replace function public.submit_request(payload jsonb)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_phone   text;
  v_name    text;
  v_service text;
  v_ref     text;
  v_token   text;
  v_id      uuid;
  v_recent  int;
begin
  -- ---- saaf karo + jaanch lo -----------------------------------------
  v_phone := regexp_replace(coalesce(payload->>'phone',''), '\D', '', 'g');
  if length(v_phone) = 12 and left(v_phone, 2) = '91' then
    v_phone := right(v_phone, 10);
  end if;
  if v_phone !~ '^[6-9][0-9]{9}$' then
    raise exception 'invalid phone';
  end if;

  v_name    := nullif(btrim(coalesce(payload->>'name','')), '');
  v_service := nullif(btrim(coalesce(payload->>'service','')), '');
  if v_name is null then
    raise exception 'name required';
  end if;
  if v_service is null then
    raise exception 'service required';
  end if;

  -- ---- spam brake: ek number se 10 minute me 3 se zyada nahi ---------
  select count(*) into v_recent
  from leads
  where phone = v_phone and created_at > now() - interval '10 minutes';
  if v_recent >= 3 then
    raise exception 'too many requests';
  end if;

  -- ---- reference number + upload token -------------------------------
  v_ref := 'SKG-' || to_char(now(), 'YYMM') || '-' ||
           lpad(nextval('lead_ref_seq')::text, 4, '0');
  v_token := replace(gen_random_uuid()::text, '-', '') ||
             replace(gen_random_uuid()::text, '-', '');

  insert into leads (name, phone, email, entity, service, message,
                     answers, urgency, source, status, ref, upload_token)
  values (
    left(v_name, 120),
    v_phone,
    nullif(btrim(coalesce(payload->>'email','')), ''),
    nullif(btrim(coalesce(payload->>'entity','')), ''),
    left(v_service, 160),
    left(coalesce(payload->>'message',''), 2000),
    coalesce(payload->'answers', '{}'::jsonb),
    case when coalesce(payload->>'urgency','') in ('urgent','normal')
         then payload->>'urgency' else 'normal' end,
    left(coalesce(nullif(payload->>'source',''), 'website-form'), 40),
    'New',
    v_ref,
    v_token
  )
  returning id into v_id;

  return jsonb_build_object('ref', v_ref, 'token', v_token);
end; $$;

revoke all on function public.submit_request(jsonb) from public;
grant execute on function public.submit_request(jsonb) to anon, authenticated;

-- =====================================================================
--  UPLOAD — ab client ka token AUR website request ka token, dono chalte hain
-- =====================================================================
create or replace function public.upload_lookup(tok text)
returns table(client_name text)
language sql security definer set search_path = public as $$
  select name from clients where upload_token = tok
  union all
  select name from leads   where upload_token = tok
  limit 1;
$$;
revoke all on function public.upload_lookup(text) from public;
grant execute on function public.upload_lookup(text) to anon, authenticated;

create or replace function public.upload_register(
  tok text, fname text, fpath text, fsize bigint, fnote text)
returns void
language plpgsql security definer set search_path = public as $$
declare
  cid uuid;
  lid uuid;
begin
  select id into cid from clients where upload_token = tok;
  if cid is null then
    select id into lid from leads where upload_token = tok;
  end if;
  if cid is null and lid is null then
    raise exception 'invalid token';
  end if;
  insert into documents(client_id, lead_id, name, path, size, note)
  values (cid, lid, fname, fpath, fsize, fnote);
end; $$;
revoke all on function public.upload_register(text,text,text,bigint,text) from public;
grant execute on function public.upload_register(text,text,text,bigint,text) to anon, authenticated;

-- =====================================================================
--  Purani direct-insert policy hata di ja rahi hai. Website ab
--  submit_request() se aati hai, jo phone verify karti hai aur spam rokti
--  hai. Chat widget bhi wahi function use karta hai.
-- =====================================================================
drop policy if exists lead_insert_public on leads;

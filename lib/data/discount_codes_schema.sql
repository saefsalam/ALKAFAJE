begin;

create table if not exists public.discount_codes (
  id bigint generated always as identity primary key,
  shop_id uuid not null references public.shops(id) on delete cascade,
  code text not null,
  discount_type text not null check (discount_type in ('percent', 'amount')),
  discount_percent integer,
  discount_amount numeric,
  min_purchase_amount numeric not null default 0 check (min_purchase_amount >= 0),
  max_discount_amount numeric check (max_discount_amount is null or max_discount_amount > 0),
  limit_count integer check (limit_count is null or limit_count > 0),
  used_count integer not null default 0 check (used_count >= 0),
  expiry_date date not null,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint discount_codes_percent_or_amount_check check (
    (
      discount_type = 'percent'
      and discount_percent between 1 and 95
      and discount_amount is null
    )
    or (
      discount_type = 'amount'
      and discount_amount is not null
      and discount_amount > 0
      and discount_percent is null
    )
  ),
  constraint discount_codes_limit_usage_check check (
    limit_count is null or used_count <= limit_count
  )
);

create unique index if not exists discount_codes_shop_id_code_upper_uidx
  on public.discount_codes (shop_id, upper(code));

create index if not exists discount_codes_shop_id_active_expiry_idx
  on public.discount_codes (shop_id, is_active, expiry_date);

create or replace function public.prepare_discount_code_row()
returns trigger
language plpgsql
as $$
begin
  new.code := upper(trim(coalesce(new.code, '')));
  new.discount_type := lower(trim(coalesce(new.discount_type, 'amount')));
  new.min_purchase_amount := coalesce(new.min_purchase_amount, 0);
  new.is_active := coalesce(new.is_active, true);
  new.updated_at := now();

  if tg_op = 'INSERT' and new.created_at is null then
    new.created_at := now();
  end if;

  if new.discount_type = 'percent' then
    new.discount_amount := null;
  elsif new.discount_type = 'amount' then
    new.discount_percent := null;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_prepare_discount_code_row on public.discount_codes;
create trigger trg_prepare_discount_code_row
before insert or update on public.discount_codes
for each row
execute function public.prepare_discount_code_row();

create or replace function public.compute_discount_code_amount(
  p_subtotal numeric,
  p_discount_type text,
  p_discount_percent integer,
  p_discount_amount numeric,
  p_max_discount_amount numeric
)
returns numeric
language plpgsql
immutable
as $$
declare
  v_discount numeric := 0;
begin
  if coalesce(p_subtotal, 0) <= 0 then
    return 0;
  end if;

  if p_discount_type = 'percent' then
    v_discount := round(p_subtotal * (coalesce(p_discount_percent, 0)::numeric / 100), 2);
  else
    v_discount := coalesce(p_discount_amount, 0);
  end if;

  if p_max_discount_amount is not null and v_discount > p_max_discount_amount then
    v_discount := p_max_discount_amount;
  end if;

  if v_discount > p_subtotal then
    v_discount := p_subtotal;
  end if;

  if v_discount < 0 then
    v_discount := 0;
  end if;

  return round(v_discount, 2);
end;
$$;

alter table public.orders
  add column if not exists discount_code_id bigint,
  add column if not exists discount_code_snapshot text,
  add column if not exists discount_amount numeric not null default 0;

update public.orders
set discount_amount = 0
where discount_amount is null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'orders_discount_code_id_fkey'
  ) then
    alter table public.orders
      add constraint orders_discount_code_id_fkey
      foreign key (discount_code_id)
      references public.discount_codes(id)
      on delete set null;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'orders_discount_amount_check'
  ) then
    alter table public.orders
      add constraint orders_discount_amount_check
      check (discount_amount >= 0 and discount_amount <= subtotal + delivery_fee);
  end if;
end $$;

create index if not exists orders_discount_code_id_idx
  on public.orders (discount_code_id);

create or replace function public.apply_discount_code_to_order()
returns trigger
language plpgsql
as $$
declare
  v_discount_code public.discount_codes%rowtype;
  v_discount_amount numeric := 0;
begin
  if new.discount_code_id is null then
    new.discount_amount := 0;
    new.discount_code_snapshot := null;
    new.total := greatest(coalesce(new.subtotal, 0) + coalesce(new.delivery_fee, 0), 0);
    return new;
  end if;

  select *
  into v_discount_code
  from public.discount_codes
  where id = new.discount_code_id
    and shop_id = new.shop_id
  for update;

  if not found then
    raise exception 'DISCOUNT_CODE_NOT_FOUND';
  end if;

  if coalesce(v_discount_code.is_active, false) = false then
    raise exception 'DISCOUNT_CODE_INACTIVE';
  end if;

  if v_discount_code.expiry_date < current_date then
    raise exception 'DISCOUNT_CODE_EXPIRED';
  end if;

  if coalesce(new.subtotal, 0) < coalesce(v_discount_code.min_purchase_amount, 0) then
    raise exception 'DISCOUNT_CODE_MIN_PURCHASE_NOT_MET';
  end if;

  if v_discount_code.limit_count is not null
     and coalesce(v_discount_code.used_count, 0) >= v_discount_code.limit_count then
    raise exception 'DISCOUNT_CODE_LIMIT_REACHED';
  end if;

  v_discount_amount := public.compute_discount_code_amount(
    p_subtotal => coalesce(new.subtotal, 0),
    p_discount_type => v_discount_code.discount_type,
    p_discount_percent => v_discount_code.discount_percent,
    p_discount_amount => v_discount_code.discount_amount,
    p_max_discount_amount => v_discount_code.max_discount_amount
  );

  if v_discount_amount <= 0 then
    raise exception 'DISCOUNT_CODE_INVALID_AMOUNT';
  end if;

  new.discount_code_snapshot := v_discount_code.code;
  new.discount_amount := v_discount_amount;
  new.total := greatest(
    coalesce(new.subtotal, 0) - v_discount_amount + coalesce(new.delivery_fee, 0),
    0
  );

  update public.discount_codes
  set used_count = used_count + 1,
      updated_at = now()
  where id = v_discount_code.id;

  return new;
end;
$$;

drop trigger if exists trg_apply_discount_code_to_order on public.orders;
create trigger trg_apply_discount_code_to_order
before insert on public.orders
for each row
execute function public.apply_discount_code_to_order();

create or replace function public.release_discount_code_from_deleted_order()
returns trigger
language plpgsql
as $$
begin
  if old.discount_code_id is not null then
    update public.discount_codes
    set used_count = greatest(used_count - 1, 0),
        updated_at = now()
    where id = old.discount_code_id;
  end if;

  return old;
end;
$$;

drop trigger if exists trg_release_discount_code_from_deleted_order on public.orders;
create trigger trg_release_discount_code_from_deleted_order
after delete on public.orders
for each row
execute function public.release_discount_code_from_deleted_order();

commit;

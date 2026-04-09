begin;

create table if not exists public.item_colors (
  id bigint generated always as identity primary key,
  item_id bigint not null references public.items(id) on delete cascade,
  name text not null,
  hex_code text check (hex_code is null or hex_code ~* '^#[a-f0-9]{6}$'),
  sort_order smallint not null default 1,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create index if not exists item_colors_item_id_sort_order_idx
  on public.item_colors (item_id, sort_order, id);

create table if not exists public.item_sizes (
  id bigint generated always as identity primary key,
  item_id bigint not null references public.items(id) on delete cascade,
  name text not null,
  sort_order smallint not null default 1,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create index if not exists item_sizes_item_id_sort_order_idx
  on public.item_sizes (item_id, sort_order, id);

alter table public.cart_items
  add column if not exists selection_key text,
  add column if not exists selected_color_id bigint,
  add column if not exists selected_color_name text,
  add column if not exists selected_color_hex text,
  add column if not exists selected_size_id bigint,
  add column if not exists selected_size_name text;

update public.cart_items
set selection_key = coalesce(nullif(selection_key, ''), 'c:0|s:0');

alter table public.cart_items
  alter column selection_key set default 'c:0|s:0',
  alter column selection_key set not null;

with duplicate_rows as (
  select
    min(id) as keep_id,
    cart_id,
    item_id,
    selection_key,
    sum(quantity) as merged_quantity
  from public.cart_items
  group by cart_id, item_id, selection_key
  having count(*) > 1
)
update public.cart_items cart_items
set quantity = duplicate_rows.merged_quantity
from duplicate_rows
where cart_items.id = duplicate_rows.keep_id;

with duplicate_rows as (
  select
    min(id) as keep_id,
    cart_id,
    item_id,
    selection_key
  from public.cart_items
  group by cart_id, item_id, selection_key
  having count(*) > 1
)
delete from public.cart_items cart_items
using duplicate_rows
where cart_items.cart_id = duplicate_rows.cart_id
  and cart_items.item_id = duplicate_rows.item_id
  and cart_items.selection_key = duplicate_rows.selection_key
  and cart_items.id <> duplicate_rows.keep_id;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'cart_items_selected_color_hex_check'
  ) then
    alter table public.cart_items
      add constraint cart_items_selected_color_hex_check
      check (
        selected_color_hex is null
        or selected_color_hex ~* '^#[a-f0-9]{6}$'
      );
  end if;
end $$;

create unique index if not exists cart_items_cart_id_item_id_selection_key_idx
  on public.cart_items (cart_id, item_id, selection_key);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'cart_items_selected_color_id_fkey'
  ) then
    alter table public.cart_items
      add constraint cart_items_selected_color_id_fkey
      foreign key (selected_color_id)
      references public.item_colors(id)
      on delete set null;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'cart_items_selected_size_id_fkey'
  ) then
    alter table public.cart_items
      add constraint cart_items_selected_size_id_fkey
      foreign key (selected_size_id)
      references public.item_sizes(id)
      on delete set null;
  end if;
end $$;

alter table public.order_items
  add column if not exists selected_color_id bigint,
  add column if not exists selected_color_name text,
  add column if not exists selected_color_hex text,
  add column if not exists selected_size_id bigint,
  add column if not exists selected_size_name text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'order_items_selected_color_hex_check'
  ) then
    alter table public.order_items
      add constraint order_items_selected_color_hex_check
      check (
        selected_color_hex is null
        or selected_color_hex ~* '^#[a-f0-9]{6}$'
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'order_items_selected_color_id_fkey'
  ) then
    alter table public.order_items
      add constraint order_items_selected_color_id_fkey
      foreign key (selected_color_id)
      references public.item_colors(id)
      on delete set null;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'order_items_selected_size_id_fkey'
  ) then
    alter table public.order_items
      add constraint order_items_selected_size_id_fkey
      foreign key (selected_size_id)
      references public.item_sizes(id)
      on delete set null;
  end if;
end $$;

create index if not exists order_items_order_id_item_id_idx
  on public.order_items (order_id, item_id);

commit;

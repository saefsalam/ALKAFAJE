-- Discount support for items and order snapshots
-- Apply this on Supabase SQL Editor once.

ALTER TABLE public.items
  ADD COLUMN IF NOT EXISTS discount_percent smallint NOT NULL DEFAULT 0;

ALTER TABLE public.items
  ADD COLUMN IF NOT EXISTS discount_price numeric
  GENERATED ALWAYS AS (
    CASE
      WHEN discount_percent > 0
        THEN round((price * ((100 - discount_percent)::numeric / 100)), 2)
      ELSE NULL::numeric
    END
  ) STORED;

ALTER TABLE public.order_items
  ADD COLUMN IF NOT EXISTS original_unit_price numeric;

ALTER TABLE public.order_items
  ADD COLUMN IF NOT EXISTS discount_percent_snapshot smallint NOT NULL DEFAULT 0;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'items_discount_percent_chk'
  ) THEN
    ALTER TABLE public.items
      ADD CONSTRAINT items_discount_percent_chk
      CHECK (discount_percent >= 0 AND discount_percent <= 95);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'order_items_discount_percent_snapshot_chk'
  ) THEN
    ALTER TABLE public.order_items
      ADD CONSTRAINT order_items_discount_percent_snapshot_chk
      CHECK (discount_percent_snapshot >= 0 AND discount_percent_snapshot <= 95);
  END IF;
END
$$;

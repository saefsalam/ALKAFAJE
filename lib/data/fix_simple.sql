-- Fix: Allow customer to cancel their order

DROP POLICY IF EXISTS "orders_update_own" ON public.orders;

CREATE POLICY "orders_update_own" ON public.orders
  FOR UPDATE 
  USING (customer_id = get_my_customer_id())
  WITH CHECK (customer_id = get_my_customer_id());

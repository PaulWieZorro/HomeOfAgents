-- ============================================
-- FIX RLS POLICIES FOR CART & ORDERS SYSTEM
-- Run this in Supabase SQL Editor to secure your tables
-- ============================================

-- Helper function to get current user ID from session
CREATE OR REPLACE FUNCTION get_current_user_id()
RETURNS UUID AS $$
BEGIN
  -- This gets the current user from the JWT claim set by your application
  RETURN COALESCE(
    NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::UUID,
    NULLIF(current_setting('request.jwt.claims', true)::json->>'user_id', '')::UUID
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing permissive policies
DROP POLICY IF EXISTS "Users can view own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert own orders" ON orders;
DROP POLICY IF EXISTS "Users can update own orders" ON orders;

DROP POLICY IF EXISTS "Users can view own order items" ON order_items;
DROP POLICY IF EXISTS "Users can insert order items" ON order_items;

DROP POLICY IF EXISTS "Users can view own cart" ON cart_items;
DROP POLICY IF EXISTS "Users can insert own cart items" ON cart_items;
DROP POLICY IF EXISTS "Users can update own cart" ON cart_items;
DROP POLICY IF EXISTS "Users can delete own cart items" ON cart_items;

-- Create secure RLS policies for ORDERS table
-- Users can only see their own orders
CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT
  USING (user_id = get_current_user_id());

-- Users can only insert orders with their own user_id
CREATE POLICY "Users can insert own orders"
  ON orders FOR INSERT
  WITH CHECK (user_id = get_current_user_id());

-- Users can only update their own orders
CREATE POLICY "Users can update own orders"
  ON orders FOR UPDATE
  USING (user_id = get_current_user_id());

-- Create secure RLS policies for ORDER_ITEMS table
-- Users can only see order items from their own orders
CREATE POLICY "Users can view own order items"
  ON order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM orders 
      WHERE orders.id = order_items.order_id
      AND orders.user_id = get_current_user_id()
    )
  );

-- Users can only insert order items to their own orders
CREATE POLICY "Users can insert order items"
  ON order_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders 
      WHERE orders.id = order_items.order_id
      AND orders.user_id = get_current_user_id()
    )
  );

-- Create secure RLS policies for CART_ITEMS table
-- Users can only see their own cart items
CREATE POLICY "Users can view own cart"
  ON cart_items FOR SELECT
  USING (user_id = get_current_user_id());

-- Users can only insert their own cart items
CREATE POLICY "Users can insert own cart items"
  ON cart_items FOR INSERT
  WITH CHECK (user_id = get_current_user_id());

-- Users can only update their own cart items
CREATE POLICY "Users can update own cart"
  ON cart_items FOR UPDATE
  USING (user_id = get_current_user_id());

-- Users can only delete their own cart items
CREATE POLICY "Users can delete own cart items"
  ON cart_items FOR DELETE
  USING (user_id = get_current_user_id());

-- Comment for documentation
COMMENT ON FUNCTION get_current_user_id() IS 'Helper function to get the current authenticated user ID from JWT claims. Used by RLS policies to enforce user-level security.';


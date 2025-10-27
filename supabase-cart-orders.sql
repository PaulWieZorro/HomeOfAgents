-- ============================================
-- AGENTRYXX SHOPPING CART & ORDERS SYSTEM
-- Cart items, orders, and order history
-- ============================================

-- Drop existing tables if recreating (commented out for safety)
-- Uncomment these lines if you need to recreate the tables from scratch
-- DROP TABLE IF EXISTS order_items CASCADE;
-- DROP TABLE IF EXISTS cart_items CASCADE;
-- DROP TABLE IF EXISTS orders CASCADE;

-- Drop existing triggers and functions if they exist
DROP TRIGGER IF EXISTS trigger_auto_set_order_number ON orders;
DROP TRIGGER IF EXISTS update_orders_updated_at ON orders;
DROP TRIGGER IF EXISTS update_cart_items_updated_at ON cart_items;

DROP FUNCTION IF EXISTS generate_order_number() CASCADE;
DROP FUNCTION IF EXISTS cleanup_expired_carts() CASCADE;
DROP FUNCTION IF EXISTS calculate_order_total(UUID) CASCADE;
DROP FUNCTION IF EXISTS auto_set_order_number() CASCADE;

DROP VIEW IF EXISTS order_summary CASCADE;
DROP VIEW IF EXISTS cart_summary CASCADE;

-- 1. ORDERS TABLE (Parent table for completed purchases)
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number VARCHAR(50) UNIQUE NOT NULL,
  user_id UUID REFERENCES custom_auth(id) ON DELETE CASCADE,
  
  -- Pricing
  total_price DECIMAL(15, 2) NOT NULL,
  total_price_usd DECIMAL(15, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  
  -- Status & Payment
  order_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'paid', 'processing', 'completed', 'cancelled'
  payment_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'completed', 'failed', 'refunded'
  payment_method VARCHAR(50), -- 'tokens', 'credit_card', 'bank_transfer', etc.
  
  -- Metadata
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Delivery/Activation
  delivery_date TIMESTAMPTZ,
  activation_status VARCHAR(50) DEFAULT 'pending' -- 'pending', 'activating', 'active', 'failed'
);

-- 2. ORDER ITEMS TABLE (Individual agents in an order)
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  
  -- Agent reference
  agent_id UUID REFERENCES agents(id) ON DELETE RESTRICT,
  agent_name VARCHAR(255) NOT NULL, -- Snapshot for historical records
  
  -- Pricing details
  price_per_year DECIMAL(12, 2) NOT NULL,
  price_in_tokens DECIMAL(15, 2) NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  subtotal DECIMAL(15, 2) NOT NULL,
  subtotal_tokens DECIMAL(15, 2) NOT NULL,
  
  -- Agent configuration
  agent_category VARCHAR(100),
  deployment_type VARCHAR(100),
  compliance_level VARCHAR(50),
  
  -- Status
  item_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'processing', 'active', 'suspended', 'cancelled'
  
  -- Dates
  activation_date TIMESTAMPTZ,
  expiry_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. CART ITEMS TABLE (Shopping cart - temporary until checkout)
CREATE TABLE IF NOT EXISTS cart_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES custom_auth(id) ON DELETE CASCADE,
  agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,
  
  -- Item details
  quantity INTEGER NOT NULL DEFAULT 1,
  
  -- Status & tracking
  status VARCHAR(50) DEFAULT 'active', -- 'active', 'abandoned', 'converted'
  
  -- Timestamps
  added_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'), -- Auto-remove abandoned carts
  
  -- Prevent duplicates
  UNIQUE(user_id, agent_id)
);

-- INDEXES for Performance
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(order_status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_agent_id ON order_items(agent_id);
CREATE INDEX IF NOT EXISTS idx_order_items_status ON order_items(item_status);

CREATE INDEX IF NOT EXISTS idx_cart_items_user_id ON cart_items(user_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_agent_id ON cart_items(agent_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_status ON cart_items(status);
CREATE INDEX IF NOT EXISTS idx_cart_items_expires_at ON cart_items(expires_at);

-- TRIGGERS for updated_at timestamps
-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS update_orders_updated_at ON orders;
DROP TRIGGER IF EXISTS update_cart_items_updated_at ON cart_items;

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cart_items_updated_at
    BEFORE UPDATE ON cart_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS POLICIES for Row Level Security
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert own orders" ON orders;
DROP POLICY IF EXISTS "Users can update own orders" ON orders;

DROP POLICY IF EXISTS "Users can view own order items" ON order_items;
DROP POLICY IF EXISTS "Users can insert order items" ON order_items;

DROP POLICY IF EXISTS "Users can view own cart" ON cart_items;
DROP POLICY IF EXISTS "Users can insert own cart items" ON cart_items;
DROP POLICY IF EXISTS "Users can update own cart" ON cart_items;
DROP POLICY IF EXISTS "Users can delete own cart items" ON cart_items;

-- Orders policies
CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own orders"
  ON orders FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update own orders"
  ON orders FOR UPDATE
  USING (true);

-- Order items policies (users can see items from their own orders)
CREATE POLICY "Users can view own order items"
  ON order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM orders 
      WHERE orders.id = order_items.order_id
    )
  );

CREATE POLICY "Users can insert order items"
  ON order_items FOR INSERT
  WITH CHECK (true);

-- Cart items policies
CREATE POLICY "Users can view own cart"
  ON cart_items FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own cart items"
  ON cart_items FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update own cart"
  ON cart_items FOR UPDATE
  USING (true);

CREATE POLICY "Users can delete own cart items"
  ON cart_items FOR DELETE
  USING (true);

-- FUNCTION: Generate unique order number
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS VARCHAR(50) AS $$
DECLARE
  order_num VARCHAR(50);
  date_part VARCHAR(20);
BEGIN
  -- Format: AGXX-YYYYMMDD-XXXXX
  date_part := TO_CHAR(NOW(), 'YYYYMMDD');
  
  SELECT 'AGXX-' || date_part || '-' || LPAD(
    COALESCE((SELECT MAX(CAST(SPLIT_PART(order_number, '-', 3) AS INTEGER)) 
              FROM orders 
              WHERE order_number LIKE 'AGXX-' || date_part || '-%'), 0) + 1
    ::TEXT, 5, '0')
  INTO order_num;
  
  RETURN order_num;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Clean up expired cart items
CREATE OR REPLACE FUNCTION cleanup_expired_carts()
RETURNS void AS $$
BEGIN
  DELETE FROM cart_items
  WHERE expires_at < NOW()
  AND status != 'converted';
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Calculate order total from items
CREATE OR REPLACE FUNCTION calculate_order_total(order_uuid UUID)
RETURNS DECIMAL(15, 2) AS $$
DECLARE
  total DECIMAL(15, 2);
BEGIN
  SELECT COALESCE(SUM(subtotal), 0) INTO total
  FROM order_items
  WHERE order_id = order_uuid;
  
  RETURN total;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Auto-generate order number on insert
CREATE OR REPLACE FUNCTION auto_set_order_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
    NEW.order_number := generate_order_number();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_set_order_number
  BEFORE INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION auto_set_order_number();

-- VIEW: Order summary with item count
CREATE OR REPLACE VIEW order_summary AS
SELECT 
  o.id,
  o.order_number,
  o.user_id,
  o.total_price,
  o.total_price_usd,
  o.order_status,
  o.payment_status,
  o.created_at,
  COUNT(oi.id) as item_count,
  SUM(oi.quantity) as total_quantity
FROM orders o
LEFT JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id, o.order_number, o.user_id, o.total_price, o.total_price_usd, 
         o.order_status, o.payment_status, o.created_at;

-- VIEW: Cart summary with agent details
CREATE OR REPLACE VIEW cart_summary AS
SELECT 
  c.id,
  c.user_id,
  c.agent_id,
  c.quantity,
  c.status,
  c.added_at,
  c.expires_at,
  a.name as agent_name,
  a.price_yearly,
  a.price_currency,
  a.category as agent_category,
  (c.quantity * a.price_yearly) as item_total
FROM cart_items c
INNER JOIN agents a ON c.agent_id = a.id
WHERE c.status = 'active';

-- Comments for documentation
COMMENT ON TABLE orders IS 'Completed purchases and order tracking';
COMMENT ON TABLE order_items IS 'Individual agents/services in an order';
COMMENT ON TABLE cart_items IS 'Shopping cart items (temporary until checkout)';
COMMENT ON COLUMN orders.order_status IS 'pending, paid, processing, completed, cancelled';
COMMENT ON COLUMN orders.payment_status IS 'pending, completed, failed, refunded';
COMMENT ON COLUMN cart_items.status IS 'active, abandoned, converted';
COMMENT ON COLUMN order_items.item_status IS 'pending, processing, active, suspended, cancelled';
COMMENT ON COLUMN cart_items.expires_at IS 'Auto-removes cart items after 30 days if not converted to order';


-- ============================================
-- TOKEN-BASED WALLET SYSTEM FOR MARKETPLACE
-- Extend user accounts with token balance and transactions
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Add token_balance column to custom_auth table
-- This should be added if it doesn't exist already
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'custom_auth' 
        AND column_name = 'token_balance'
    ) THEN
        ALTER TABLE custom_auth ADD COLUMN token_balance DECIMAL(15, 2) DEFAULT 0 NOT NULL;
    END IF;
    
    -- Add check constraint to ensure balance is never negative
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'custom_auth_token_balance_check'
    ) THEN
        ALTER TABLE custom_auth ADD CONSTRAINT custom_auth_token_balance_check 
        CHECK (token_balance >= 0);
    END IF;
END $$;

-- Step 2: Create tokens_transactions table
CREATE TABLE IF NOT EXISTS tokens_transactions (
  transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES custom_auth(id) ON DELETE CASCADE,
  amount DECIMAL(15, 2) NOT NULL, -- Positive for additions, negative for deductions
  type VARCHAR(50) NOT NULL CHECK (type IN ('purchase', 'admin_add', 'admin_subtract', 'refund', 'initial_deposit')),
  description TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  related_order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  metadata JSONB, -- Store additional context (cart items, payment method, etc.)
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 3: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_tokens_transactions_user_id ON tokens_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_tokens_transactions_timestamp ON tokens_transactions(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_tokens_transactions_type ON tokens_transactions(type);
CREATE INDEX IF NOT EXISTS idx_tokens_transactions_order_id ON tokens_transactions(related_order_id);
CREATE INDEX IF NOT EXISTS idx_custom_auth_token_balance ON custom_auth(token_balance) WHERE token_balance > 0;

-- Step 4: Helper function to get current user ID (reuse from RLS fix)
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

-- Step 5: Function to adjust user token balance atomically
CREATE OR REPLACE FUNCTION adjust_user_tokens(
  p_user_id UUID,
  p_amount DECIMAL,
  p_transaction_type VARCHAR,
  p_description TEXT DEFAULT NULL,
  p_related_order_id UUID DEFAULT NULL,
  p_metadata JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_new_balance DECIMAL;
  v_transaction_id UUID;
  v_current_balance DECIMAL;
BEGIN
  -- Get current balance
  SELECT token_balance INTO v_current_balance FROM custom_auth WHERE id = p_user_id;
  
  IF v_current_balance IS NULL THEN
    RAISE EXCEPTION 'User does not exist';
  END IF;
  
  -- Validate balance won't go negative (unless it's a refund or admin addition)
  IF p_amount < 0 AND p_transaction_type NOT IN ('refund', 'admin_add', 'admin_subtract') THEN
    IF (v_current_balance + p_amount) < 0 THEN
      RAISE EXCEPTION 'Insufficient token balance. Current: %, Required: %', 
        v_current_balance, ABS(p_amount);
    END IF;
  END IF;
  
  -- Update token balance atomically
  UPDATE custom_auth 
  SET token_balance = token_balance + p_amount
  WHERE id = p_user_id
  RETURNING token_balance INTO v_new_balance;
  
  -- Create transaction record
  INSERT INTO tokens_transactions (user_id, amount, type, description, related_order_id, metadata)
  VALUES (p_user_id, p_amount, p_transaction_type, p_description, p_related_order_id, p_metadata)
  RETURNING transaction_id INTO v_transaction_id;
  
  RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Function to get user transaction history
CREATE OR REPLACE FUNCTION get_user_transactions(
  p_user_id UUID, 
  p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  transaction_id UUID,
  amount DECIMAL,
  type VARCHAR,
  description TEXT,
  tx_timestamp TIMESTAMPTZ,
  related_order_id UUID,
  order_number VARCHAR,
  metadata JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    tt.transaction_id,
    tt.amount,
    tt.type,
    tt.description,
    tt.timestamp as tx_timestamp,
    tt.related_order_id,
    o.order_number,
    tt.metadata
  FROM tokens_transactions tt
  LEFT JOIN orders o ON tt.related_order_id = o.id
  WHERE tt.user_id = p_user_id
  ORDER BY tt.timestamp DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 7: Enable Row Level Security on tokens_transactions
ALTER TABLE tokens_transactions ENABLE ROW LEVEL SECURITY;

-- Step 8: Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own transactions" ON tokens_transactions;
DROP POLICY IF EXISTS "Users can insert own purchase transactions" ON tokens_transactions;
DROP POLICY IF EXISTS "Admins can view all transactions" ON tokens_transactions;
DROP POLICY IF EXISTS "Admins can insert all transactions" ON tokens_transactions;

-- Step 9: Create RLS policies

-- Policy 1: Users can view their own transactions
CREATE POLICY "Users can view own transactions"
  ON tokens_transactions FOR SELECT
  USING (user_id = get_current_user_id());

-- Policy 2: Users can insert their own purchase transactions
CREATE POLICY "Users can insert own purchase transactions"
  ON tokens_transactions FOR INSERT
  WITH CHECK (
    user_id = get_current_user_id() 
    AND type IN ('purchase', 'initial_deposit')
  );

-- Policy 3: Admins can view all transactions
CREATE POLICY "Admins can view all transactions"
  ON tokens_transactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM custom_auth 
      WHERE id = get_current_user_id() 
      AND role = 'admin'
    )
  );

-- Policy 4: Admins can insert all transaction types
CREATE POLICY "Admins can insert all transactions"
  ON tokens_transactions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM custom_auth 
      WHERE id = get_current_user_id() 
      AND role = 'admin'
    )
  );

-- Step 10: Update RLS policy on custom_auth to allow users to read their own balance
-- (This is already covered by the existing "Users can view own auth data" policy)

-- Comments for documentation
COMMENT ON TABLE tokens_transactions IS 'Tracks all token movements: purchases, refunds, admin additions/subtractions';
COMMENT ON COLUMN tokens_transactions.amount IS 'Positive for additions (admin_add, refund, initial_deposit), negative for deductions (purchase, admin_subtract)';
COMMENT ON COLUMN tokens_transactions.type IS 'purchase: buying agents, admin_add: admin adds tokens, admin_subtract: admin removes tokens, refund: order refund, initial_deposit: initial user deposit';
COMMENT ON FUNCTION adjust_user_tokens IS 'Atomically updates user token balance and creates transaction record. Prevents negative balances for purchases.';
COMMENT ON FUNCTION get_user_transactions IS 'Returns transaction history for a user with order details joined. Respects RLS policies.';

-- Step 11: Give all existing users a starting budget of 15,000,000 tokens
DO $$
DECLARE
    user_record RECORD;
    transaction_id UUID;
    updated_count INTEGER := 0;
BEGIN
    -- Loop through all users who don't already have a token balance set
    FOR user_record IN 
        SELECT id, email 
        FROM custom_auth 
        WHERE COALESCE(token_balance, 0) = 0
    LOOP
        -- Set the token balance
        UPDATE custom_auth 
        SET token_balance = 15000000 
        WHERE id = user_record.id;
        
        -- Create an initial deposit transaction record
        INSERT INTO tokens_transactions (
            user_id, 
            amount, 
            type, 
            description, 
            timestamp
        ) VALUES (
            user_record.id,
            15000000,
            'initial_deposit',
            'Initial account funding - Welcome bonus',
            NOW()
        );
        
        updated_count := updated_count + 1;
        RAISE NOTICE 'Gave user % (ID: %) 15,000,000 starting tokens', user_record.email, user_record.id;
    END LOOP;
    
    RAISE NOTICE 'Initial token distribution completed. % users updated.', updated_count;
END $$;


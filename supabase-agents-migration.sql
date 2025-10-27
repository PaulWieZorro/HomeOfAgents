-- Migration: Add 'pending' status for agent approval workflow
-- Run this SQL in your Supabase SQL Editor AFTER creating the agents table

-- Step 1: Update status column to allow 'pending' status
-- The existing schema already supports VARCHAR(50), so we just need to add a check constraint
-- or update the default value logic

-- Step 2: Add index for pending agents (useful for admin approval workflows)
CREATE INDEX IF NOT EXISTS idx_agents_status_pending ON agents(status) WHERE status = 'pending';

-- Step 3: Add RLS (Row Level Security) policies for agents table
-- This ensures users can only see approved agents in the marketplace
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read approved/active agents
DROP POLICY IF EXISTS "Anyone can read active agents" ON agents;
CREATE POLICY "Anyone can read active agents"
    ON agents FOR SELECT
    USING (status = 'active');

-- Policy: Authenticated users can create agents (pending approval)
DROP POLICY IF EXISTS "Authenticated users can create agents" ON agents;
CREATE POLICY "Authenticated users can create agents"
    ON agents FOR INSERT
    WITH CHECK (true);

-- Policy: Users can update their own pending agents
DROP POLICY IF EXISTS "Users can update their own pending agents" ON agents;
CREATE POLICY "Users can update their own pending agents"
    ON agents FOR UPDATE
    USING (auth.uid() = created_by AND status = 'pending');

-- Policy: Only creators can see their pending agents
DROP POLICY IF EXISTS "Creators can see their pending agents" ON agents;
CREATE POLICY "Creators can see their pending agents"
    ON agents FOR SELECT
    USING (
        status = 'active' OR 
        (status = 'pending' AND auth.uid() = created_by)
    );

-- Policy: Admins can approve/update all agents (if you add an admin role)
-- This is commented out - uncomment if you implement an admin role
/*
CREATE POLICY "Admins can manage all agents"
    ON agents FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM custom_auth
            WHERE id = auth.uid()
            AND role = 'admin'
        )
    );
*/

-- Add helpful comments
COMMENT ON COLUMN agents.status IS 'active: Live in marketplace, pending: Awaiting approval, inactive: Removed from marketplace, deprecated: No longer supported';

-- Create a view for admin dashboard to see pending agents
CREATE OR REPLACE VIEW pending_agents AS
SELECT 
    a.*,
    u.email as creator_email
FROM agents a
LEFT JOIN custom_auth u ON a.created_by = u.id
WHERE a.status = 'pending'
ORDER BY a.created_at DESC;

-- Add helpful function to approve agents
CREATE OR REPLACE FUNCTION approve_agent(agent_uuid UUID)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE agents
    SET status = 'active'
    WHERE id = agent_uuid;
END;
$$;

COMMENT ON FUNCTION approve_agent IS 'Marks an agent as active/approved in the marketplace';

-- Add function to get agent by ID (useful for API endpoints)
CREATE OR REPLACE FUNCTION get_agent_by_id(agent_uuid UUID)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    category VARCHAR,
    description TEXT,
    short_description VARCHAR,
    price_yearly DECIMAL,
    rating DECIMAL,
    reviews_count INTEGER,
    compliance_level VARCHAR,
    vendor_name VARCHAR,
    status VARCHAR,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.name,
        a.category,
        a.description,
        a.short_description,
        a.price_yearly,
        a.rating,
        a.reviews_count,
        a.compliance_level,
        a.vendor_name,
        a.status,
        a.created_at
    FROM agents a
    WHERE a.id = agent_uuid
    AND a.status = 'active';
END;
$$;


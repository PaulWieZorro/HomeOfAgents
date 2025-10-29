-- Contact Interest Table for Agentryxx
-- Stores leads from "Contact me" form on homepage
-- Run this SQL in your Supabase SQL Editor

-- Drop table if exists to recreate
DROP TABLE IF EXISTS contact_interest CASCADE;

-- Contact Interest Table
CREATE TABLE contact_interest (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  name TEXT,
  contact TEXT, -- Phone, LinkedIn, or other contact method
  gdpr_consent BOOLEAN DEFAULT false,
  source TEXT DEFAULT 'contact_form', -- 'contact_form' or 'subscribe'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies for Contact Interest
ALTER TABLE contact_interest ENABLE ROW LEVEL SECURITY;

-- Allow anyone to insert (anonymous users)
DROP POLICY IF EXISTS "Anyone can submit contact interest" ON contact_interest;
CREATE POLICY "Anyone can submit contact interest"
  ON contact_interest FOR INSERT
  WITH CHECK (true);

-- Allow service role to view all (for admin dashboard)
DROP POLICY IF EXISTS "Service role can view all contact interest" ON contact_interest;
CREATE POLICY "Service role can view all contact interest"
  ON contact_interest FOR SELECT
  USING (true); -- We'll handle user verification in application logic

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_contact_interest_email ON contact_interest(email);
CREATE INDEX IF NOT EXISTS idx_contact_interest_created_at ON contact_interest(created_at);

-- Add updated_at trigger
DROP TRIGGER IF EXISTS update_contact_interest_updated_at ON contact_interest;
CREATE TRIGGER update_contact_interest_updated_at 
    BEFORE UPDATE ON contact_interest 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add comments for documentation
COMMENT ON TABLE contact_interest IS 'Stores contact form submissions from homepage and newsletter signups';
COMMENT ON COLUMN contact_interest.email IS 'Email address of the interested user';
COMMENT ON COLUMN contact_interest.name IS 'Name of the interested user (optional)';
COMMENT ON COLUMN contact_interest.contact IS 'Additional contact method (phone, LinkedIn, etc.)';
COMMENT ON COLUMN contact_interest.gdpr_consent IS 'GDPR consent status';
COMMENT ON COLUMN contact_interest.source IS 'Source of the submission: contact_form or subscribe';


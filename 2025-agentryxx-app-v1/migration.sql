-- Migration: Remove email duplication, use user_id FK, enable RLS
-- Run this SQL in your Supabase SQL Editor

-- Step 1: Create profiles table for normalized user data
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES custom_auth(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('developer', 'enterprise')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 2: Migrate existing data to profiles table
INSERT INTO profiles (user_id, email, role, is_active, created_at, updated_at)
SELECT id, email, role, is_active, created_at, updated_at
FROM custom_auth
ON CONFLICT (user_id) DO NOTHING;

-- Step 3: Update kyc_data table to use user_id FK and remove email duplication
-- First, add user_id column if it doesn't exist
ALTER TABLE kyc_data 
ADD COLUMN IF NOT EXISTS user_id_new UUID REFERENCES custom_auth(id) ON DELETE CASCADE;

-- Migrate existing data to use user_id
UPDATE kyc_data 
SET user_id_new = user_id 
WHERE user_id IS NOT NULL;

-- Drop the old user_id column and rename the new one
ALTER TABLE kyc_data DROP COLUMN IF EXISTS user_id;
ALTER TABLE kyc_data RENAME COLUMN user_id_new TO user_id;

-- Make user_id NOT NULL after migration
ALTER TABLE kyc_data ALTER COLUMN user_id SET NOT NULL;

-- Step 4: Update kyb_data table to use user_id FK instead of user_email
-- Add user_id column
ALTER TABLE kyb_data 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES custom_auth(id) ON DELETE CASCADE;

-- Migrate existing data from user_email to user_id
UPDATE kyb_data 
SET user_id = ca.id
FROM custom_auth ca
WHERE kyb_data.user_email = ca.email;

-- Make user_id NOT NULL after migration
ALTER TABLE kyb_data ALTER COLUMN user_id SET NOT NULL;

-- Drop NOT NULL constraint from legacy email column (keep column for backward compatibility)
ALTER TABLE kyb_data ALTER COLUMN user_email DROP NOT NULL;

-- Step 5: Enable RLS on all tables
ALTER TABLE custom_auth ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE kyc_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE kyb_data ENABLE ROW LEVEL SECURITY;

-- Step 6: Drop existing policies and create new ones
-- Custom Auth policies
DROP POLICY IF EXISTS "Anyone can register" ON custom_auth;
DROP POLICY IF EXISTS "Users can view own auth data" ON custom_auth;

CREATE POLICY "Anyone can register"
  ON custom_auth FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can view own auth data"
  ON custom_auth FOR SELECT
  USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update own auth data"
  ON custom_auth FOR UPDATE
  USING (auth.uid()::text = id::text);

-- Profiles policies
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid()::text = user_id::text);

-- KYC Data policies
DROP POLICY IF EXISTS "Users can view own KYC data" ON kyc_data;
DROP POLICY IF EXISTS "Users can insert own KYC data" ON kyc_data;
DROP POLICY IF EXISTS "Users can update own KYC data" ON kyc_data;

CREATE POLICY "Users can view own KYC data"
  ON kyc_data FOR SELECT
  USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own KYC data"
  ON kyc_data FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own KYC data"
  ON kyc_data FOR UPDATE
  USING (auth.uid()::text = user_id::text);

-- KYB Data policies
DROP POLICY IF EXISTS "Users can view own KYB data" ON kyb_data;
DROP POLICY IF EXISTS "Users can insert own KYB data" ON kyb_data;
DROP POLICY IF EXISTS "Users can update own KYB data" ON kyb_data;

CREATE POLICY "Users can view own KYB data"
  ON kyb_data FOR SELECT
  USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own KYB data"
  ON kyb_data FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own KYB data"
  ON kyb_data FOR UPDATE
  USING (auth.uid()::text = user_id::text);

-- Step 7: Update storage policies for better security
DROP POLICY IF EXISTS "Users can upload own documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own documents" ON storage.objects;

CREATE POLICY "Users can upload own documents"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id IN ('kyc-documents', 'kyb-documents') AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view own documents"
  ON storage.objects FOR SELECT
  USING (
    bucket_id IN ('kyc-documents', 'kyb-documents') AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update own documents"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id IN ('kyc-documents', 'kyb-documents') AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own documents"
  ON storage.objects FOR DELETE
  USING (
    bucket_id IN ('kyc-documents', 'kyb-documents') AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Step 8: Update indexes for better performance
DROP INDEX IF EXISTS idx_kyb_data_user_email;
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_kyb_data_user_id ON kyb_data(user_id);

-- Step 9: Add updated_at trigger for profiles table
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at 
    BEFORE UPDATE ON profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Step 10: Create helper functions for user management
CREATE OR REPLACE FUNCTION get_user_profile(user_uuid UUID)
RETURNS TABLE (
  id UUID,
  email TEXT,
  role TEXT,
  is_active BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT p.id, p.email, p.role, p.is_active, p.created_at, p.updated_at
  FROM profiles p
  WHERE p.user_id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 11: Create function to get user's KYC/KYB data
CREATE OR REPLACE FUNCTION get_user_verification_data(user_uuid UUID)
RETURNS TABLE (
  kyc_data JSONB,
  kyb_data JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(
      (SELECT to_jsonb(k.*) FROM kyc_data k WHERE k.user_id = user_uuid),
      'null'::jsonb
    ) as kyc_data,
    COALESCE(
      (SELECT to_jsonb(k.*) FROM kyb_data k WHERE k.user_id = user_uuid),
      'null'::jsonb
    ) as kyb_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 12: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Migration completed successfully
-- Verify the changes in Supabase Studio:
-- 1. Check that profiles table exists with proper structure
-- 2. Verify RLS is enabled on all tables
-- 3. Confirm policies are working correctly
-- 4. Test that user_id foreign keys are properly set up
-- 5. Ensure legacy email columns no longer have NOT NULL constraints

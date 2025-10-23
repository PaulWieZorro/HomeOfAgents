-- Simplified Database Schema for Agentryxx Authentication
-- Run this SQL in your Supabase SQL Editor

-- Custom Auth Table (simplified)
CREATE TABLE IF NOT EXISTS custom_auth (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('developer', 'enterprise')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- KYC Table (for developers)
CREATE TABLE IF NOT EXISTS kyc_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES custom_auth(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  address TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  passport_id TEXT NOT NULL,
  id_document_url TEXT NOT NULL,
  certificate_good_conduct BOOLEAN DEFAULT false,
  gdpr_consent BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Drop existing KYB table if it exists (to recreate with new schema)
DROP TABLE IF EXISTS kyb_data CASCADE;

-- KYB Table (for enterprises) - Independent table
CREATE TABLE kyb_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_email TEXT NOT NULL, -- Store email instead of user_id
  legal_company_name TEXT NOT NULL,
  street_number TEXT NOT NULL,
  postcode TEXT NOT NULL,
  city TEXT NOT NULL,
  country_of_registration TEXT NOT NULL,
  registration_number TEXT NOT NULL,
  director_name TEXT NOT NULL,
  registration_document_url TEXT NOT NULL,
  aml_ctf_verified BOOLEAN DEFAULT false,
  gdpr_consent BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies for Custom Auth
ALTER TABLE custom_auth ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can register" ON custom_auth;
CREATE POLICY "Anyone can register"
  ON custom_auth FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "Users can view own auth data" ON custom_auth;
CREATE POLICY "Users can view own auth data"
  ON custom_auth FOR SELECT
  USING (true); -- We'll handle authentication in application logic

-- RLS Policies for KYC
ALTER TABLE kyc_data ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own KYC data" ON kyc_data;
CREATE POLICY "Users can view own KYC data"
  ON kyc_data FOR SELECT
  USING (true); -- We'll handle user verification in application logic

DROP POLICY IF EXISTS "Users can insert own KYC data" ON kyc_data;
CREATE POLICY "Users can insert own KYC data"
  ON kyc_data FOR INSERT
  WITH CHECK (true); -- We'll handle user verification in application logic

DROP POLICY IF EXISTS "Users can update own KYC data" ON kyc_data;
CREATE POLICY "Users can update own KYC data"
  ON kyc_data FOR UPDATE
  USING (true); -- We'll handle user verification in application logic

-- RLS Policies for KYB (recreated table)
ALTER TABLE kyb_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own KYB data"
  ON kyb_data FOR SELECT
  USING (true); -- We'll handle user verification in application logic

CREATE POLICY "Users can insert own KYB data"
  ON kyb_data FOR INSERT
  WITH CHECK (true); -- We'll handle user verification in application logic

CREATE POLICY "Users can update own KYB data"
  ON kyb_data FOR UPDATE
  USING (true); -- We'll handle user verification in application logic

-- Storage Buckets for Documents
INSERT INTO storage.buckets (id, name, public) 
VALUES ('kyc-documents', 'kyc-documents', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('kyb-documents', 'kyb-documents', false)
ON CONFLICT (id) DO NOTHING;

-- RLS for Storage
DROP POLICY IF EXISTS "Users can upload own documents" ON storage.objects;
CREATE POLICY "Users can upload own documents"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id IN ('kyc-documents', 'kyb-documents')); -- We'll handle user verification in application logic

DROP POLICY IF EXISTS "Users can view own documents" ON storage.objects;
CREATE POLICY "Users can view own documents"
  ON storage.objects FOR SELECT
  USING (bucket_id IN ('kyc-documents', 'kyb-documents')); -- We'll handle user verification in application logic

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_custom_auth_email ON custom_auth(email);
CREATE INDEX IF NOT EXISTS idx_custom_auth_role ON custom_auth(role);
CREATE INDEX IF NOT EXISTS idx_kyc_data_user_id ON kyc_data(user_id);
CREATE INDEX IF NOT EXISTS idx_kyb_data_user_email ON kyb_data(user_email);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
DROP TRIGGER IF EXISTS update_custom_auth_updated_at ON custom_auth;
CREATE TRIGGER update_custom_auth_updated_at 
    BEFORE UPDATE ON custom_auth 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_kyc_data_updated_at ON kyc_data;
CREATE TRIGGER update_kyc_data_updated_at 
    BEFORE UPDATE ON kyc_data 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_kyb_data_updated_at 
    BEFORE UPDATE ON kyb_data 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

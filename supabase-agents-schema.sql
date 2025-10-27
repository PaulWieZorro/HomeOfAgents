-- Agentryxx Agents Marketplace Table
-- Schema for storing AI agents available for purchase by financial institutions
-- 
-- NOTE: This file can be run multiple times safely (idempotent).
-- If agents table already exists, it will NOT be dropped or recreated.
-- To start fresh, run: DROP TABLE IF EXISTS agents CASCADE; first.

CREATE TABLE IF NOT EXISTS agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Basic Information
    name VARCHAR(255) NOT NULL UNIQUE,
    category VARCHAR(100) NOT NULL, -- banking, insurance, risk, compliance, support
    description TEXT NOT NULL,
    short_description VARCHAR(500),
    
    -- Pricing & Availability
    price_yearly DECIMAL(12, 2) NOT NULL,
    price_currency VARCHAR(3) DEFAULT 'USD',
    trial_period_days INTEGER DEFAULT 30,
    demo_available BOOLEAN DEFAULT false,
    demo_url VARCHAR(500),
    
    -- Ratings & Reviews
    rating DECIMAL(3, 2) CHECK (rating >= 0 AND rating <= 5),
    reviews_count INTEGER DEFAULT 0,
    verified_status BOOLEAN DEFAULT true,
    
    -- Compliance & Security (Critical for banks)
    compliance_level VARCHAR(50) NOT NULL, -- enterprise, premium, standard, basic
    compliance_standards TEXT[], -- Array of compliance standards (e.g., ['PCI DSS', 'SOX', 'GDPR'])
    data_security_rating VARCHAR(50), -- A+, A, B+, B, C
    certifications TEXT[], -- Array of certifications
    
    -- Technical Specifications
    integration_options TEXT[], -- Array of integration options
    deployment_type VARCHAR(100), -- cloud, on-premise, hybrid
    api_type VARCHAR(100), -- REST, GraphQL, WebSocket, gRPC
    api_documentation_url VARCHAR(500),
    
    -- Performance & SLA
    sla_uptime_percentage DECIMAL(5, 2), -- 99.9, 99.99, 99.999
    guaranteed_response_time_ms INTEGER,
    max_concurrent_users INTEGER,
    monthly_api_call_limit INTEGER,
    
    -- Support & Services
    support_level VARCHAR(50), -- 24/7, business-hours, standard
    support_channels TEXT[], -- Array of support channels ['email', 'phone', 'chat', 'ticket']
    language_support TEXT[], -- Array of supported languages ['en', 'es', 'fr', 'de']
    
    -- Vendor Information
    vendor_name VARCHAR(255) NOT NULL,
    vendor_url VARCHAR(500),
    vendor_email VARCHAR(255),
    vendor_location VARCHAR(255),
    
    -- Additional Metadata
    use_cases TEXT[], -- Array of use cases
    key_features TEXT[], -- Array of key features
    capabilities TEXT[], -- Array of capabilities
    
    -- Audit & Tracking
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    status VARCHAR(50) DEFAULT 'active', -- active, inactive, deprecated
    
    -- Search Optimization
    search_keywords TEXT[], -- Array of keywords for search optimization
    tags TEXT[], -- Array of tags for categorization
    featured BOOLEAN DEFAULT false,
    popular BOOLEAN DEFAULT false
);

-- Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_agents_category ON agents(category);
CREATE INDEX IF NOT EXISTS idx_agents_compliance_level ON agents(compliance_level);
CREATE INDEX IF NOT EXISTS idx_agents_status ON agents(status);
CREATE INDEX IF NOT EXISTS idx_agents_featured ON agents(featured);
CREATE INDEX IF NOT EXISTS idx_agents_popular ON agents(popular);
CREATE INDEX IF NOT EXISTS idx_agents_rating ON agents(rating DESC);
CREATE INDEX IF NOT EXISTS idx_agents_price_yearly ON agents(price_yearly);
CREATE INDEX IF NOT EXISTS idx_agents_created_at ON agents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_agents_search_keywords ON agents USING GIN(search_keywords);

-- Full Text Search Index
CREATE INDEX IF NOT EXISTS idx_agents_name_description ON agents USING GIN(to_tsvector('english', name || ' ' || description));

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_agents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists, then create it
DROP TRIGGER IF EXISTS trigger_update_agents_updated_at ON agents;

CREATE TRIGGER trigger_update_agents_updated_at
    BEFORE UPDATE ON agents
    FOR EACH ROW
    EXECUTE FUNCTION update_agents_updated_at();

-- Comments for Documentation
COMMENT ON TABLE agents IS 'AI agents available for purchase by financial institutions through the Agentryxx marketplace';
COMMENT ON COLUMN agents.compliance_level IS 'Enterprise: Highest compliance standards (banks, healthcare), Premium: High compliance, Standard: General compliance, Basic: Minimal compliance requirements';
COMMENT ON COLUMN agents.data_security_rating IS 'A+ (Best in class encryption, SOC 2 Type II), A (Strong encryption, SOC 2), B+ (Good encryption), B (Basic encryption), C (Standard security)';
COMMENT ON COLUMN agents.deployment_type IS 'How the agent is deployed: cloud (SaaS), on-premise (on bank infrastructure), hybrid (combination)';
COMMENT ON COLUMN agents.sla_uptime_percentage IS 'Service Level Agreement uptime percentage (e.g., 99.9 = 99.9% uptime guarantee)';
COMMENT ON COLUMN agents.support_level IS '24/7: Round the clock support, business-hours: Business day support, standard: Standard support hours';

-- Insert sample agents data only if not already present
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM agents WHERE name = 'Banking Compliance Monitor') THEN
        INSERT INTO agents (
    name, category, description, short_description,
    price_yearly, price_currency, trial_period_days, demo_available,
    rating, reviews_count, verified_status,
    compliance_level, compliance_standards, data_security_rating, certifications,
    integration_options, deployment_type, api_type, api_documentation_url,
    sla_uptime_percentage, guaranteed_response_time_ms, max_concurrent_users, monthly_api_call_limit,
    support_level, support_channels, language_support,
    vendor_name, vendor_url, vendor_email, vendor_location,
    use_cases, key_features, capabilities,
    search_keywords, tags, featured, popular
) VALUES
(
    'Banking Compliance Monitor',
    'banking',
    'Automatically monitors transactions for AML compliance, flags suspicious activities, and generates regulatory reports for banking institutions.',
    'Real-time AML compliance monitoring with automated reporting.',
    195000.00,
    'USD',
    30,
    true,
    4.8,
    127,
    true,
    'enterprise',
    ARRAY['PCI DSS Level 1', 'SOX', 'BSA', 'AML', 'FDIC', 'OCC'],
    'A+',
    ARRAY['SOC 2 Type II', 'ISO 27001', 'PCI DSS Level 1'],
    ARRAY['Core banking systems', 'SWIFT', 'ACH', 'Wire transfers', 'FEDLINE'],
    'hybrid',
    'REST',
    'https://docs.agentryxx.ai/banking-compliance-monitor',
    99.99,
    500,
    10000,
    1000000,
    '24/7',
    ARRAY['email', 'phone', 'chat', 'ticket'],
    ARRAY['en', 'es', 'fr', 'de'],
    'Agentryxx Financial Solutions',
    'https://agentryxx.ai',
    'support@agentryxx.ai',
    'New York, USA',
    ARRAY['AML (Anti-Money Laundering) compliance monitoring', 'Transaction monitoring and suspicious activity detection', 'Regulatory reporting for FDIC and OCC examinations', 'Customer due diligence automation', 'Watchlist screening and matching'],
    ARRAY['Transaction monitoring', 'AML flagging', 'Regulatory report generation', 'Risk scoring', 'Alert management', 'Audit trails'],
    ARRAY['Monitors all transaction types including wire transfers, ACH, and SWIFT', 'Automated SAR (Suspicious Activity Report) generation', 'Integrates with OFAC, FinCEN, and other watchlists', 'Real-time risk scoring and alert prioritization', 'Comprehensive audit trails for regulatory examinations'],
    ARRAY['banking', 'compliance', 'AML', 'monitoring', 'regulatory', 'transaction'],
    ARRAY['banking', 'compliance', 'enterprise', 'verified'],
    true,
    true
),
(
    'Credit Risk Analyzer',
    'banking',
    'Evaluates loan applications, assesses creditworthiness, calculates risk scores, and provides automated lending decisions for financial institutions.',
    'Automated credit risk assessment and lending decision support.',
    165000.00,
    'USD',
    30,
    true,
    4.6,
    98,
    true,
    'enterprise',
    ARRAY['Fair Lending Act', 'CRA', 'FCRA', 'ECOA', 'Fair Credit Reporting'],
    'A+',
    ARRAY['SOC 2 Type II', 'ISO 27001'],
    ARRAY['Core banking systems', 'Credit bureaus', 'Applicant tracking systems', 'Mortgage systems'],
    'cloud',
    'REST',
    'https://docs.agentryxx.ai/credit-risk-analyzer',
    99.95,
    1000,
    5000,
    500000,
    '24/7',
    ARRAY['email', 'phone', 'chat'],
    ARRAY['en', 'es', 'fr'],
    'Agentryxx Lending Intelligence',
    'https://agentryxx.ai',
    'support@agentryxx.ai',
    'San Francisco, USA',
    ARRAY['Automated loan application processing', 'Credit risk assessment and scoring', 'Automated underwriting decisions', 'Fair lending compliance monitoring', 'Commercial and consumer lending'],
    ARRAY['Credit scoring', 'Income verification', 'Debt-to-income analysis', 'Automated approvals', 'Risk assessment', 'Compliance checks'],
    ARRAY['Multi-bureau credit report analysis (Equifax, Experian, TransUnion)', 'Automated income and employment verification', 'DTI calculation and affordability assessment', 'Automated loan approval workflow', 'Fair lending compliance monitoring'],
    ARRAY['credit', 'risk', 'lending', 'underwriting', 'banking'],
    ARRAY['banking', 'credit', 'enterprise', 'verified'],
    true,
    false
),
(
    'Fraud Detection System',
    'banking',
    'Real-time monitoring of banking transactions, credit card activities, and insurance claims to detect and prevent fraudulent activities.',
    'Real-time fraud detection with machine learning analytics.',
    285000.00,
    'USD',
    30,
    true,
    4.9,
    203,
    true,
    'enterprise',
    ARRAY['PCI DSS', 'TILA', 'Reg E', 'Fair Credit Billing Act'],
    'A+',
    ARRAY['SOC 2 Type II', 'PCI DSS Level 1', 'ISO 27001'],
    ARRAY['Card processing systems', 'Core banking', 'Mobile banking', 'E-commerce platforms', 'Payment gateways'],
    'hybrid',
    'REST',
    'https://docs.agentryxx.ai/fraud-detection-system',
    99.999,
    50,
    50000,
    5000000,
    '24/7',
    ARRAY['email', 'phone', 'chat', 'ticket'],
    ARRAY['en', 'es', 'fr', 'de', 'pt', 'zh'],
    'Agentryxx Fraud Prevention Inc',
    'https://agentryxx.ai',
    'fraud-support@agentryxx.ai',
    'Boston, USA',
    ARRAY['Credit card fraud detection and prevention', 'Account takeover detection', 'Mobile banking fraud prevention', 'E-commerce payment fraud detection', 'Real-time transaction authorization'],
    ARRAY['Real-time fraud scoring', 'Behavioral analytics', 'Device fingerprinting', 'Velocity checks', 'Pattern recognition', 'Auto-decline rules'],
    ARRAY['Machine learning-based fraud detection', 'Real-time transaction monitoring with <50ms latency', 'Behavioral biometrics and device fingerprinting', 'Card-present and card-not-present fraud detection', 'Account takeover and new account fraud prevention'],
    ARRAY['fraud', 'detection', 'security', 'prevention', 'banking'],
    ARRAY['banking', 'security', 'fraud', 'enterprise', 'verified', 'featured'],
    true,
    true
),
(
    'Regulatory Reporting Bot',
    'compliance',
    'Generates automated regulatory reports for banks and insurance companies, ensuring compliance with FDIC, SEC, and state insurance regulations.',
    'Automated regulatory report generation for financial institutions.',
    185000.00,
    'USD',
    30,
    true,
    4.7,
    89,
    true,
    'enterprise',
    ARRAY['Call Report (FFIEC 031/041)', 'SEC reporting', 'State insurance filings', 'SOX'],
    'A',
    ARRAY['SOC 2 Type II', 'ISO 27001'],
    ARRAY['Core banking systems', 'General ledger', 'Regulatory systems (FEDLINE, NMLS)', 'ERP systems'],
    'cloud',
    'REST',
    'https://docs.agentryxx.ai/regulatory-reporting-bot',
    99.95,
    2000,
    500,
    10000,
    'business-hours',
    ARRAY['email', 'phone', 'ticket'],
    ARRAY['en', 'es'],
    'Agentryxx Compliance Solutions',
    'https://agentryxx.ai',
    'compliance@agentryxx.ai',
    'Washington D.C., USA',
    ARRAY['Quarterly regulatory report generation', 'FDIC Call Report automation', 'SEC filing preparation and submission', 'State insurance regulatory compliance', 'Internal compliance audit support'],
    ARRAY['Automated report generation', 'Data validation', 'Submission tracking', 'Schedule management', 'Audit trails', 'Multi-entity support'],
    ARRAY['Automated FFIEC Call Report generation', 'SEC 10-K, 10-Q, and 8-K preparation assistance', 'State insurance regulatory filings', 'SOX control testing and documentation', 'Multi-bank holding company reporting'],
    ARRAY['regulatory', 'reporting', 'compliance', 'FDIC', 'SEC'],
    ARRAY['compliance', 'reporting', 'enterprise', 'verified'],
    true,
    false
),
(
    'Insurance Claims Assessor',
    'insurance',
    'Analyzes insurance claims, validates policy coverage, calculates settlements, and processes automated claim approvals for insurance companies.',
    'Automated insurance claims processing and settlement calculation.',
    235000.00,
    'USD',
    30,
    true,
    4.5,
    156,
    true,
    'premium',
    ARRAY['NAIC standards', 'State-specific regulations', 'Fair Claims Act', 'HIPAA'],
    'A',
    ARRAY['SOC 2 Type II', 'HIPAA', 'ISO 27001'],
    ARRAY['Claims management systems', 'Policy administration', 'Third-party adjusters', 'Document management', 'Third-party administrators'],
    'cloud',
    'REST',
    'https://docs.agentryxx.ai/insurance-claims-assessor',
    99.9,
    1500,
    2000,
    100000,
    '24/7',
    ARRAY['email', 'phone', 'chat'],
    ARRAY['en', 'es', 'fr'],
    'Agentryxx Insurance Intelligence',
    'https://agentryxx.ai',
    'insurance@agentryxx.ai',
    'Hartford, USA',
    ARRAY['Automated claims processing and approval', 'Property and casualty claim assessment', 'Health insurance claim adjudication', 'Workers'' compensation claims', 'Fraud detection and prevention'],
    ARRAY['OCR and document processing', 'Policy coverage analysis', 'Settlement calculation', 'Fraud detection', 'Automated approvals', 'Communication automation'],
    ARRAY['Automated document processing and OCR', 'Policy coverage validation and interpretation', 'Damage assessment and valuation', 'Automated settlement calculations', 'Claims fraud detection scoring'],
    ARRAY['insurance', 'claims', 'assessment', 'settlement'],
    ARRAY['insurance', 'claims', 'premium', 'verified'],
    true,
    true
),
(
    'Policy Underwriting Assistant',
    'insurance',
    'Automates insurance policy underwriting processes, evaluates risk factors, calculates premiums, and generates policy recommendations.',
    'Automated insurance policy underwriting and risk evaluation.',
    210000.00,
    'USD',
    30,
    true,
    4.4,
    112,
    true,
    'premium',
    ARRAY['NAIC', 'State insurance regulations', 'Underwriting guidelines', 'Fair pricing laws'],
    'A',
    ARRAY['SOC 2 Type II', 'ISO 27001'],
    ARRAY['Policy administration systems', 'External data sources', 'Actuarial systems', 'CRM', 'Third-party data providers'],
    'cloud',
    'REST',
    'https://docs.agentryxx.ai/policy-underwriting-assistant',
    99.9,
    2000,
    1000,
    50000,
    'business-hours',
    ARRAY['email', 'phone', 'chat'],
    ARRAY['en', 'es'],
    'Agentryxx Insurance Intelligence',
    'https://agentryxx.ai',
    'insurance@agentryxx.ai',
    'Hartford, USA',
    ARRAY['Automated underwriting and policy issuance', 'Risk assessment and pricing', 'Property and casualty underwriting', 'Health insurance underwriting support', 'Commercial insurance risk evaluation'],
    ARRAY['Risk scoring', 'Premium calculation', 'Automated underwriting rules', 'Risk profiling', 'Policy recommendations', 'Renewal analysis'],
    ARRAY['Multi-factor risk assessment and scoring', 'Automated premium calculation and rating', 'External data integration (credit, claims history, etc.)', 'Automated policy recommendations', 'Risk-based pricing optimization'],
    ARRAY['insurance', 'underwriting', 'risk', 'pricing'],
    ARRAY['insurance', 'underwriting', 'premium', 'verified'],
    true,
    false
),
(
    'Risk Assessment Agent',
    'risk',
    'Analyzes credit risk, market volatility, and compliance requirements for financial institutions.',
    'Comprehensive risk analysis for credit, market, and operational risk.',
    255000.00,
    'USD',
    30,
    true,
    4.7,
    145,
    true,
    'enterprise',
    ARRAY['Basel III', 'CCAR', 'DFAST', 'ICAAP', 'ERM frameworks'],
    'A+',
    ARRAY['SOC 2 Type II', 'ISO 27001'],
    ARRAY['Risk management systems', 'Market data feeds', 'Portfolio management', 'Regulatory systems', 'Trading platforms'],
    'hybrid',
    'REST',
    'https://docs.agentryxx.ai/risk-assessment-agent',
    99.99,
    1000,
    1000,
    100000,
    '24/7',
    ARRAY['email', 'phone', 'chat', 'ticket'],
    ARRAY['en', 'es', 'fr', 'de'],
    'Agentryxx Risk Management',
    'https://agentryxx.ai',
    'risk@agentryxx.ai',
    'London, UK',
    ARRAY['Credit risk portfolio management', 'Market risk and trading desk analysis', 'Regulatory stress testing (CCAR/DFAST)', 'Operational risk assessment', 'Enterprise risk management (ERM)'],
    ARRAY['VaR calculation', 'Stress testing', 'Model validation', 'Risk aggregation', 'Scenario analysis', 'Risk reporting'],
    ARRAY['Comprehensive credit risk analysis and portfolio stress testing', 'Market risk and VaR calculations', 'Basel III capital requirement calculations', 'CCAR and DFAST stress testing support', 'Model validation and backtesting'],
    ARRAY['risk', 'assessment', 'credit', 'market', 'operational'],
    ARRAY['risk', 'enterprise', 'verified', 'featured'],
    true,
    true
),
(
    'Wealth Management Support Agent',
    'support',
    'Guarantees 24/7 availability to wealthy customers, answers every question that has ever been answered to a client, learns from internal documents.',
    'AI-powered support for high-net-worth wealth management clients.',
    180000.00,
    'USD',
    30,
    true,
    4.6,
    187,
    true,
    'premium',
    ARRAY['FINRA', 'SEC Investment Advisor regulations', 'Fiduciary standards'],
    'A',
    ARRAY['SOC 2 Type II', 'ISO 27001'],
    ARRAY['CRM systems', 'Portfolio management', 'Document repositories', 'Market data', 'Client portals', 'Trading platforms'],
    'cloud',
    'REST',
    'https://docs.agentryxx.ai/wealth-management-support-agent',
    99.95,
    2000,
    500,
    50000,
    '24/7',
    ARRAY['email', 'phone', 'chat'],
    ARRAY['en', 'es', 'fr', 'de', 'zh'],
    'Agentryxx Wealth Solutions',
    'https://agentryxx.ai',
    'wealth@agentryxx.ai',
    'New York, USA',
    ARRAY['High-net-worth client support', 'Investment advisory assistant', 'Portfolio performance analysis and reporting', 'Client inquiry handling and education', 'Internal knowledge management for advisors'],
    ARRAY['Natural language processing', 'Knowledge base search', 'Client communication', 'Portfolio insights', 'Document retrieval', 'Market analysis'],
    ARRAY['24/7 client support with natural language understanding', 'Comprehensive knowledge base from historical interactions', 'Real-time portfolio performance and market analysis', 'Document and policy retrieval from internal systems', 'Personalized client communication and reporting'],
    ARRAY['wealth', 'management', 'support', 'client', 'HNW'],
    ARRAY['support', 'wealth', 'premium', 'verified'],
    true,
    false
),
(
    'Internal Strategy & Planning Support Agent',
    'support',
    'Helps Staff with every decision and project proposal to fit into the company''s strategy.',
    'Strategic planning and decision support for financial institutions.',
    150000.00,
    'USD',
    30,
    true,
    4.3,
    76,
    true,
    'standard',
    ARRAY['Internal governance', 'Strategic planning frameworks'],
    'B+',
    ARRAY['SOC 2 Type II'],
    ARRAY['Project management tools', 'Strategy planning systems', 'Data analytics platforms', 'HR systems', 'Enterprise systems'],
    'cloud',
    'REST',
    'https://docs.agentryxx.ai/strategy-planning-support-agent',
    99.9,
    3000,
    100,
    10000,
    'business-hours',
    ARRAY['email', 'chat', 'ticket'],
    ARRAY['en', 'es'],
    'Agentryxx Business Intelligence',
    'https://agentryxx.ai',
    'strategy@agentryxx.ai',
    'New York, USA',
    ARRAY['Strategic planning and analysis support', 'Project proposal evaluation', 'Executive decision support', 'Business unit planning assistance', 'Organizational learning and knowledge management'],
    ARRAY['Strategic analysis', 'Project alignment scoring', 'Decision support frameworks', 'Performance metrics', 'Knowledge base', 'Recommendation engine'],
    ARRAY['Strategic framework alignment and analysis', 'Project proposal evaluation and scoring', 'Decision support with historical context', 'Performance tracking and KPI monitoring', 'Internal knowledge base and best practices'],
    ARRAY['strategy', 'planning', 'support', 'decision'],
    ARRAY['support', 'strategy', 'standard', 'verified'],
    false,
    false
);
    END IF;
END $$;


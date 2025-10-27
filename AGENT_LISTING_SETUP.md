# Agent Listing Setup Instructions

## Summary of Changes

This implementation adds the ability for users to list new agents in the marketplace. The system includes:

1. **Updated Marketplace UI**: Two new cards on the marketplace page
   - "Create Agent Requirements" - Links to conversational AI requirements engineering
   - "List New Agent" - Links to comprehensive agent submission form

2. **Agent Submission Form** (`pages/list-agent.html`)
   - Multi-step form with all database fields
   - Tag-based input for arrays (use cases, features, capabilities, keywords)
   - Validation and data type conversion
   - Direct integration with Supabase

3. **API Integration** (updated `assets/supabase-config.js`)
   - New `createAgent()` function in DatabaseManager class
   - Handles all field mappings and data transformations
   - Includes authentication check
   - Sets default values for ratings and verification status

4. **Database Schema** (`supabase-agents-schema.sql`)
   - Complete schema with all fields for bank buying employees
   - Includes 9 sample agents with realistic data
   - Proper indexes for performance

## SQL Setup Instructions

You need to run these SQL files in your Supabase SQL Editor **IN ORDER**:

### Step 1: Create the main agents table
Run: `supabase-agents-schema.sql`
- This creates the agents table
- Adds all necessary indexes
- Creates trigger for updated_at timestamp
- Inserts 9 sample agents

### Step 2: Add approval workflow (optional but recommended)
Run: `supabase-agents-migration.sql`
- Adds 'pending' status support
- Creates RLS policies for security
- Adds admin views and functions
- Creates pending agents view

## Field Mappings

The form captures all fields from the database schema:

### Basic Information
- Name, Category, Description, Short Description

### Pricing & Availability
- Annual Price (yearly subscription, $150K-$300K range)
- Trial Period, Demo Available

### Compliance & Security
- Compliance Level (Enterprise, Premium, Standard, Basic)
- Data Security Rating (A+, A, B+, B, C)
- Compliance Standards (array: PCI DSS, SOX, GDPR, SOC 2, ISO 27001, HIPAA, AML, BSA)
- Certifications (array)

### Technical Specifications
- Deployment Type (Cloud, On-Premise, Hybrid)
- API Type (REST, GraphQL, WebSocket, gRPC)
- Integration Options (array: Core Banking, SWIFT, ACH, CRM, etc.)
- API Documentation URL

### Performance & SLA
- SLA Uptime Percentage (99.9, 99.99, 99.999)
- Guaranteed Response Time (ms)
- Max Concurrent Users
- Monthly API Call Limit

### Support & Services
- Support Level (24/7, Business Hours, Standard)
- Support Channels (array: email, phone, chat, ticket)
- Language Support (array: en, es, fr, de, zh, pt)

### Vendor Information
- Vendor Name, URL, Email, Location

### Additional Metadata
- Use Cases (array)
- Key Features (array)
- Capabilities (array)
- Search Keywords (array)
- Tags (auto-generated from category)

## Workflow

1. User fills out the multi-step form
2. On submit, all data is collected and validated
3. Authentication check ensures user is logged in
4. Data is formatted and sent to Supabase
5. Agent is created with 'pending' status
6. Agent awaits admin approval
7. Once approved, agent appears in marketplace

## Admin Approval

New agents are created with `status = 'pending'` and need approval before appearing in the marketplace. You can:

1. Query pending agents using the `pending_agents` view
2. Approve agents using `SELECT approve_agent('agent-uuid')`
3. Update agent status directly in the database

## Usage

To list a new agent:
1. Navigate to marketplace
2. Click "List New Agent" card
3. Fill out all 4 steps of the form
4. Submit the form
5. Wait for admin approval
6. Agent appears in marketplace once approved

## Notes

- The ISO/IEC/IEEE 29148 reference was added to the "Create Agent Requirements" card
- All submitted agents start with `verified_status = false` and need approval
- The rating system starts at null/0 until reviews are added
- Search functionality uses the `search_keywords` array for filtering


# Agentryxx - AI Agent Marketplace

## Overview
Agentryxx is a comprehensive AI agent marketplace platform where developers can deploy and monetize their AI agents, and companies can rent or build custom agent solutions. The platform provides a complete ecosystem with pay-as-you-go pricing, marketplace discovery, and integrated billing.

**Project Type:** Static website with Supabase backend  
**Tech Stack:** HTML5, CSS3, JavaScript (ES6+), Supabase  
**Current State:** Fully configured and running in Replit environment

## Recent Changes
- **2025-11-01**: Initial Replit setup
  - Created Python HTTP server (server.py) to serve static files on port 5000
  - Configured workflow to run frontend server with webview output
  - Added .gitignore for Python cache files
  - Server running at http://0.0.0.0:5000/ with cache-control headers

## Project Architecture

### Frontend Structure
```
/
├── index.html              # Landing page
├── pages/                  # Application pages
│   ├── login.html
│   ├── register.html
│   ├── kyc.html           # KYC verification (developers)
│   ├── kyb.html           # KYB verification (enterprises)
│   ├── dashboard_dev.html
│   ├── dashboard_company.html
│   ├── marketplace.html
│   ├── create-agent.html
│   ├── list-agent.html
│   ├── checkout.html
│   ├── billing-and-deployment.html
│   └── ...
├── assets/                 # Scripts and styles
│   ├── styles.css
│   ├── app.js             # Main application logic
│   ├── supabase-config.js # Supabase client & managers
│   ├── cart-api.js
│   ├── dashboard.js
│   ├── form-validation.js
│   ├── otp-verification.js
│   ├── starfield.js
│   └── toaster.js
├── images/                 # Static assets
└── server.py              # Python HTTP server (Replit)
```

### Backend (Supabase)
- **Database:** PostgreSQL with Row Level Security (RLS)
- **Authentication:** Custom auth table with email/password
- **Storage:** File uploads for KYC/KYB documents
- **Key Tables:**
  - `custom_auth` - User authentication and roles
  - `kyc_data` - Developer verification data
  - `kyb_data` - Enterprise verification data
  - `agents` - Agent marketplace listings
  - `cart_items` - Shopping cart
  - `orders` - Purchase orders
  - `contact_interest` - Lead generation
  - `token_transactions` - Payment/wallet system

### Key Features
1. **User Registration & Verification**
   - Role-based registration (Developer/Enterprise)
   - KYC/KYB verification with document uploads
   - Email OTP verification

2. **Agent Marketplace**
   - Browse and search AI agents
   - Category-based filtering
   - Trial periods and demos
   - Compliance and security ratings

3. **Wallet & Billing System**
   - Token-based payment system
   - Transaction history
   - Purchase tracking

4. **Developer Dashboard**
   - Create and list agents
   - Manage deployments
   - Track earnings

5. **Enterprise Dashboard**
   - Browse marketplace
   - Manage subscriptions
   - Billing overview

## Development Setup

### Running Locally (Replit)
The project runs automatically via the configured workflow:
- Server: `python server.py`
- Port: 5000 (webview enabled)
- Host: 0.0.0.0 (required for Replit proxy)

### Environment Configuration
Supabase credentials are currently hardcoded in `assets/supabase-config.js`:
- **SUPABASE_URL:** https://uqwtzggvltodppaaezcj.supabase.co
- **SUPABASE_ANON_KEY:** (public anon key in file)

**Note:** For production deployment, these should be moved to environment variables.

### Database Setup
SQL migration files are provided in the root directory:
- `supabase-schema.sql` - Main schema
- `supabase-agents-schema.sql` - Agent marketplace
- `supabase-cart-orders.sql` - Shopping cart
- `supabase-wallet-system.sql` - Payment system
- `supabase-fix-rls-policies.sql` - RLS fixes

Execute these in Supabase SQL Editor to set up the database.

## Deployment

### Replit Deployment
The project is configured for Replit's autoscale deployment:
- Deployment type: Autoscale (stateless)
- Run command: Production-ready server
- Port: 5000

### Production Considerations
1. **Security:**
   - Move Supabase credentials to environment variables
   - Enable HTTPS (automatic on Replit)
   - Review RLS policies

2. **Performance:**
   - Cache-control headers already configured
   - Consider CDN for static assets
   - Optimize images in /images/

3. **Monitoring:**
   - Set up Supabase monitoring
   - Track API usage
   - Monitor error logs

## Documentation Files
Comprehensive setup guides are available:
- `SETUP_GUIDE.md` - KYC/KYB system setup
- `AGENT_LISTING_SETUP.md` - Agent marketplace
- `CART_ORDERS_SETUP.md` - Shopping cart
- `CHECKOUT_SYSTEM_GUIDE.md` - Checkout flow
- `WALLET_IMPLEMENTATION_GUIDE.md` - Payment system
- `RLS_FIX_GUIDE.md` - Security policies

## User Preferences
- No specific preferences recorded yet

## Support
For questions or issues:
- Email: hello@agentryxx.com
- Project documentation available in root directory

# KYC/KYB Registration System - Setup Guide

## Overview
This implementation provides a complete KYC/KYB registration system with Supabase authentication, file uploads, and OTP verification.

## Files Created/Modified

### New Files:
- `pages/kyb.html` - KYB (Know Your Business) verification page
- `assets/supabase-config.js` - Supabase configuration and helper functions
- `assets/otp-verification.js` - OTP verification modal and flow
- `assets/form-validation.js` - Form validation utilities
- `assets/dashboard.js` - Dashboard functionality
- `supabase-schema.sql` - Database schema for Supabase

### Modified Files:
- `index.html` - Updated registration button routing
- `pages/kyc.html` - Updated with complete KYC form
- `pages/dashboard_dev.html` - Added onboarding button
- `pages/dashboard_company.html` - Added onboarding button
- `assets/styles.css` - Added onboarding button styles

## Setup Instructions

### 1. Supabase Project Setup
1. Create a new Supabase project at https://supabase.com
2. Go to Settings > API to get your project URL and anon key
3. Update `assets/supabase-config.js` with your credentials:
   ```javascript
   const SUPABASE_URL = 'YOUR_SUPABASE_URL';
   const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
   ```

### 2. Database Setup
1. In your Supabase dashboard, go to SQL Editor
2. Copy and paste the contents of `supabase-schema.sql`
3. Run the SQL to create all tables, policies, and storage bucket

### 3. Email Configuration
1. In Supabase dashboard, go to Authentication > Settings
2. Configure your email templates for OTP verification
3. Set up your SMTP settings if using custom email provider

### 4. Storage Configuration
1. The `kyc-documents` bucket is created automatically by the SQL script
2. Files are stored privately with user-based access control
3. Document naming format: `{user_id}_{document_type}_{timestamp}.{extension}`

## Features Implemented

### ✅ Phase 1: Pages & Routing
- ✅ KYC page cloned to create KYB page
- ✅ Registration button routes based on role selection
- ✅ Complete KYB form with all required fields
- ✅ Complete KYC form with all required fields
- ✅ File upload validation (3MB max, JPG/PNG/PDF only)

### ✅ Phase 2: Supabase Configuration
- ✅ Supabase client configuration
- ✅ Authentication helper functions
- ✅ File upload manager
- ✅ Database manager

### ✅ Phase 3: Authentication Flow
- ✅ OTP email verification modal
- ✅ 60-second countdown timer
- ✅ Resend code functionality
- ✅ Error handling for invalid codes

### ✅ Phase 4: Data Storage
- ✅ File upload to Supabase Storage
- ✅ KYC/KYB data insertion
- ✅ User role assignment
- ✅ Document URL linking

### ✅ Phase 5: Dashboard Integration
- ✅ Onboarding button with bounce animation
- ✅ Notification system
- ✅ Placeholder functionality

## Form Fields

### KYC Form (Developers):
- Full Name (required)
- Address (required)
- Date of Birth (required)
- Passport ID Number (required)
- ID Document Upload (required, 3MB max)
- Email (required)
- Password (required, min 8 chars)
- Certificate of Good Conduct checkbox (required)
- GDPR Consent checkbox (required)

### KYB Form (Enterprises):
- Legal Company Name (required)
- Headquarter Address (required)
- Country of Registration (required)
- Registration Number (required)
- Director Name (required)
- Registration Document Upload (required, 3MB max)
- Email (required)
- Password (required, min 8 chars)
- AML/CTF Certificate compliance checkbox (required)
- GDPR Consent checkbox (required)

## Security Features
- Row Level Security (RLS) enabled on all tables
- User-based file access control
- Input validation on both client and server side
- Secure file upload with type and size validation
- OTP-based email verification

## Error Handling
- File type/size validation
- Upload failure handling
- Database connection error handling
- Invalid OTP code handling
- Duplicate email registration handling
- Network timeout handling

## Next Steps
1. **Configure Supabase**: Add your project credentials
2. **Run Database Schema**: Execute the SQL script
3. **Test Registration Flow**: Try both developer and enterprise paths
4. **Customize Email Templates**: Update OTP email design
5. **Add Real Dashboard Logic**: Connect onboarding button to actual verification status

## Testing Checklist
- [ ] Developer registration flow (KYC)
- [ ] Enterprise registration flow (KYB)
- [ ] File upload validation
- [ ] OTP verification process
- [ ] Database data insertion
- [ ] Dashboard onboarding button
- [ ] Error handling scenarios

## Troubleshooting
- **OTP not received**: Check email configuration in Supabase
- **File upload fails**: Verify storage bucket permissions
- **Database errors**: Check RLS policies and user permissions
- **Form validation issues**: Check JavaScript console for errors

The system is now ready for testing with your Supabase project!

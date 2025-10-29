# Contact Form Setup - Supabase Integration

## Issue Fixed
The error "Failed to submit. Please try again later." has been fixed by:
1. Adding the Supabase CDN script to `index.html`
2. Adding the `supabase-config.js` script to `index.html`  
3. Fixing the Supabase client initialization in `supabase-config.js`

## Required: Run SQL Migration

**IMPORTANT**: You must run the SQL file to create the database table before the forms will work.

### Steps:
1. Open your Supabase dashboard: https://uqwtzggvltodppaaezcj.supabase.co
2. Go to **SQL Editor**
3. Open the file `supabase-contact-interest.sql`
4. Copy and paste the entire contents
5. Click **Run**

This will create:
- `contact_interest` table with fields: email, name, contact, gdpr_consent, source
- Row Level Security policies to allow anonymous inserts
- Indexes for performance
- Automatic updated_at trigger

## What's Now Working

After running the SQL:
- **"Contact me" form** will save submissions to Supabase
- **Newsletter "Subscribe" form** will also save to Supabase
- Both forms track GDPR consent
- Each submission is marked with its source (`contact_form` or `subscribe`)
- Users get proper success/error messages
- Forms show loading states during submission

## Test It

1. Submit the contact form on the homepage
2. Check Supabase Table Editor to see the entry
3. Submit the newsletter form
4. Verify both appear in the `contact_interest` table

## Viewing Submissions

Go to Supabase Dashboard > Table Editor > `contact_interest` to see all form submissions.

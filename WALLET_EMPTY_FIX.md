# Wallet Showing Empty? Here's How to Fix It

## Current Problem
Your wallet shows **$0.00** because the database migration hasn't been run yet.

## The Solution (2 Minutes)

### Step 1: Open Supabase Dashboard
Go to: https://supabase.com/dashboard  
Open your project

### Step 2: Open SQL Editor
- Click "SQL Editor" (left sidebar)
- Click "New query"

### Step 3: Copy & Paste the Migration
Open the file `supabase-wallet-system.sql` in your project and copy ALL 236 lines

Then:
1. Paste into Supabase SQL Editor
2. Click "Run" (green button)
3. Wait for success message

### Step 4: Refresh Browser
- Refresh your marketplace page
- Click wallet button
- **You should now see: $15,000,000.00**

## What Happens When You Run the SQL

✅ Adds `token_balance` column to `custom_auth` table  
✅ Creates `tokens_transactions` table  
✅ Sets up security policies  
✅ **Gives you 15,000,000 starting tokens**

## Quick Verification

After running the migration, verify it worked:

```sql
-- Check your balance
SELECT email, token_balance 
FROM custom_auth 
WHERE email = 'your@email.com';
```

Should show: `15000000` (or more if you've used tokens)

## Still Empty After Migration?

1. **Refresh the browser page** (Ctrl/Cmd + R)
2. **Check you're logged in**
3. **Open browser console** (F12) and look for errors
4. **Check your user has the balance** with the query above

## Need Help?

If still not working, the SQL migration likely didn't complete successfully. Check:
- Did you see a success message in SQL Editor?
- Any error messages?
- Try running the migration again


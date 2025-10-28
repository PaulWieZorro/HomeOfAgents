# Wallet Loading Error - Fix Guide

## Problem
The wallet button in marketplace.html shows an error: "Failed to load wallet. Please try again."

## Symptoms
- Error message: "authManager is not defined"
- Wallet modal shows generic error message
- Check browser console for details

## Root Causes
The issue can occur for two reasons:

### 1. Missing Database Setup
The wallet system requires database setup that may not have been completed:
1. Adding the `token_balance` column to the `custom_auth` table
2. Creating the `tokens_transactions` table
3. Setting up the proper RLS (Row Level Security) policies

### 2. Script Loading Race Condition
The JavaScript dependencies (`authManager` and `databaseManager`) might not be loaded before they're accessed.

## What Was Fixed

### Code Changes in marketplace.html
I've added safety checks to prevent the "authManager is not defined" error:

1. **Added dependency checks** in all wallet-related functions:
   - `openWalletModal()`
   - `openTransactionHistory()`
   - `quickTopUp()`
   - `openTopUpModal()`
   - `confirmTopUp()`
   - `updateTokenBalance()`

2. **Better error messages** that guide users to refresh if scripts haven't loaded

3. **Debug logging** to help identify issues in the browser console

## Solution Steps

### Step 1: Check Browser Console
First, open your browser's developer console (F12) and look for error messages. The updated code now logs detailed information:
- Current user status
- Database query results
- Specific error messages
- Script loading status

### Step 2: Run the Wallet System Migration
You need to run the SQL migration in your Supabase project:

1. **Go to Supabase Dashboard**
   - Open your project at: https://supabase.com/dashboard

2. **Open SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New query"

3. **Run the Migration**
   - Copy the **entire contents** of `supabase-wallet-system.sql`
   - Paste into the SQL Editor
   - Click "Run" to execute

This will:
- Add `token_balance` column to `custom_auth` table
- Create `tokens_transactions` table
- Set up helper functions (`adjust_user_tokens`, `get_user_transactions`)
- Create RLS policies
- Give all existing users 15,000,000 starting tokens

### Step 3: Verify the Setup

Run this query to check if the setup was successful:

```sql
-- Check if token_balance column exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'custom_auth' 
AND column_name = 'token_balance';

-- Check if tokens_transactions table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'tokens_transactions';

-- Check your current balance
SELECT id, email, token_balance 
FROM custom_auth 
WHERE email = 'your_email@example.com';
```

### Step 4: Test the Wallet
1. Refresh the marketplace page
2. Click the wallet button
3. You should see your balance
4. Check the browser console for any remaining errors

## Common Issues

### Issue 1: "column token_balance does not exist"
**Solution**: Run the `supabase-wallet-system.sql` migration

### Issue 2: "permission denied for table custom_auth"
**Solution**: This is an RLS (Row Level Security) issue. The migration should handle this, but if it persists:
1. Check if RLS policies are enabled: `SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'custom_auth';`
2. Verify that users can read their own data

### Issue 3: User not logged in
**Solution**: Make sure you're logged in before accessing the wallet

## Testing the Fix

After running the migration, test with:

1. **Check your wallet balance**:
   ```sql
   SELECT id, email, token_balance FROM custom_auth;
   ```

2. **Check your initial deposit transaction**:
   ```sql
   SELECT * FROM tokens_transactions 
   WHERE type = 'initial_deposit' 
   ORDER BY timestamp DESC 
   LIMIT 5;
   ```

3. **Try adding more tokens** (for testing):
   ```sql
   SELECT adjust_user_tokens(
       'your_user_id_here',  -- Replace with actual user ID
       100000,                -- Amount to add
       'admin_add',          -- Transaction type
       'Test addition'       -- Description
   );
   ```

## Next Steps

Once the wallet system is working:
1. Users can top up their wallet by clicking "Add 100,000 Tokens"
2. Check transaction history with the transaction history modal
3. Purchase agents using tokens from the wallet

## Need Help?

If you're still experiencing issues:
1. Check browser console for specific error messages
2. Check Supabase logs in the dashboard
3. Verify all migrations have been run
4. Ensure you're logged in with a valid user account

## Files Modified
- `pages/marketplace.html` - Added better error handling and debug logging

## Files to Run (if not already done)
- `supabase-wallet-system.sql` - Creates wallet tables and functions
- `supabase-fix-rls-policies.sql` - Fixes RLS security policies


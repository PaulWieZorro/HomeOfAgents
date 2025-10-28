# Wallet Setup - Step by Step Guide

## Current Status
❌ Your wallet is showing empty ($0.00) because the database migration hasn't been run yet.

## What You Need to Do RIGHT NOW

### Option 1: Quick Setup (Recommended)

Follow these **3 simple steps**:

#### Step 1: Open Supabase Dashboard
- Go to: https://supabase.com/dashboard
- Select your project (uqwtzggvltodppaaezcj)

#### Step 2: Open SQL Editor
- Click "SQL Editor" in left sidebar
- Click "New query"

#### Step 3: Run the Migration
- Copy the ENTIRE contents of `supabase-wallet-system.sql`
- Paste into SQL Editor
- Click "Run" (green button)

### Option 2: Verify Current Setup

Run this query in Supabase SQL Editor to check if the wallet system is set up:

```sql
-- Check if token_balance column exists
SELECT column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'custom_auth' 
AND column_name = 'token_balance';

-- Check if tokens_transactions table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'tokens_transactions';
```

**Expected Results:**
- Should show `token_balance` column with default `0`
- Should show `tokens_transactions` table exists

**If Results Are Empty:** The migration hasn't been run yet → Run `supabase-wallet-system.sql`

## What the Migration Does

When you run `supabase-wallet-system.sql`, it will:

1. ✅ Add `token_balance` column to `custom_auth` table
2. ✅ Create `tokens_transactions` table for transaction history
3. ✅ Create helper functions (`adjust_user_tokens`, `get_user_transactions`)
4. ✅ Set up RLS security policies
5. ✅ **Give ALL existing users 15,000,000 starting tokens**

## After Running the Migration

### 1. Refresh Your Browser
- Refresh the marketplace page

### 2. Click Wallet Button
- You should now see: **$15,000,000.00**

### 3. Test Top Up
- Click "Add 100,000 Tokens"
- Balance should update to: **$15,100,000.00**

## Troubleshooting

### Error: "column token_balance does not exist"
→ **Solution:** Run the SQL migration

### Error: "permission denied"
→ **Solution:** Check your Supabase RLS policies

### Balance Still Shows $0.00
→ **Check:**
1. Did SQL run without errors?
2. Are you logged in?
3. Open browser console (F12) and look for errors

### Still Not Working?
Run this diagnostic query:

```sql
-- Check your user's token balance
SELECT 
    id,
    email, 
    token_balance,
    token_balance::numeric(15,0) as balance_readable
FROM custom_auth 
WHERE email = 'your_email@example.com';  -- Replace with your email

-- Check your transaction history
SELECT 
    type,
    amount,
    description,
    timestamp
FROM tokens_transactions
WHERE user_id = (
    SELECT id FROM custom_auth 
    WHERE email = 'your_email@example.com'  -- Replace with your email
)
ORDER BY timestamp DESC;
```

## Testing Checklist

- [ ] Migration SQL has been run in Supabase
- [ ] Browser page has been refreshed
- [ ] User is logged in
- [ ] Wallet button shows balance (should be $15,000,000)
- [ ] "Add 100,000 Tokens" button works
- [ ] Transaction history shows initial deposit

## Next Steps After Setup

Once the wallet is working:

1. **Add agents to cart**
2. **Proceed to checkout**
3. **Tokens will be deducted automatically**
4. **View transaction history** to see all purchases

## File Reference

📄 Migration file: `supabase-wallet-system.sql` (236 lines)

This is the file you need to run in Supabase SQL Editor.


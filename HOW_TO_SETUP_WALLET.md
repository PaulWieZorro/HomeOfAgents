# How to Set Up the Wallet System

## What Has Been Implemented

✅ Wallet balance display in navbar (top right, next to cart icon)
✅ Click wallet button → Opens wallet modal showing current balance
✅ Quick top up button → Adds 100,000 tokens instantly
✅ Detailed top up modal with confirmation
✅ Transaction history view
✅ Token deduction on checkout
✅ Database integration with RLS security

## What You Need to Do

### Step 1: Run the SQL Migration

1. **Open Supabase Dashboard**
   - Go to https://supabase.com/dashboard
   - Select your project

2. **Go to SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New query"

3. **Copy and Run the Migration**
   - Open the file: `supabase-wallet-system.sql` from this project
   - Copy ALL the contents (236 lines)
   - Paste into the Supabase SQL Editor
   - Click "Run" (or press Cmd/Ctrl + Enter)

4. **What This Does**
   - ✅ Adds `token_balance` column to `custom_auth` table
   - ✅ Creates `tokens_transactions` table for tracking
   - ✅ Creates helper functions (`adjust_user_tokens`, `get_user_transactions`)
   - ✅ Sets up Row Level Security (RLS) policies
   - ✅ Gives all existing users 15,000,000 starting tokens

### Step 2: Verify Setup

After running the SQL, you should see:
- ✅ Success messages in the SQL console
- ✅ No errors

### Step 3: Test the Wallet

1. **Login to the marketplace**
2. **Click the wallet icon** (top right)
3. **You should see:**
   - Current balance: 15,000,000 tokens (or updated balance)
   - "Top Up" button
   - "Add 100,000 Tokens" quick button
   - "Transactions" button

### Step 4: Try It Out

1. **View Balance**: Click wallet icon → See your current tokens
2. **Quick Top Up**: Click "Add 100,000 Tokens" → Balance updates to 15,100,000
3. **Add to Cart**: Add agents to cart
4. **Checkout**: Cart will deduct tokens from your balance
5. **View Transactions**: Click "Transactions" to see all token movements

## Troubleshooting

### "I see $0.00 in wallet"
- **Cause**: SQL migration hasn't been run yet
- **Fix**: Run the SQL migration file in Supabase SQL Editor

### "Error loading wallet"
- **Cause**: User not logged in
- **Fix**: Login first, then click wallet

### "Function doesn't exist"
- **Cause**: SQL migration didn't complete
- **Fix**: Run the SQL migration again (it's idempotent - safe to run multiple times)

### "Cannot see balance even after running SQL"
- **Check**: 
  1. Are you logged in?
  2. Did the SQL run successfully?
  3. Check browser console for errors

## Current Implementation Details

### Database Tables
- `custom_auth.token_balance` - Stores user's current balance
- `tokens_transactions` - Logs all token movements

### Functions
- `adjust_user_tokens()` - Adds or removes tokens atomically
- `get_user_transactions()` - Retrieves transaction history
- `get_current_user_id()` - Gets authenticated user from session

### Security
- RLS policies ensure users can only see their own data
- All token movements are logged
- Atomic transactions prevent race conditions

## SQL Migration File Location

📁 File: `supabase-wallet-system.sql`

This is the file you need to run in Supabase SQL Editor.


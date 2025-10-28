# RLS Security Fix - Implementation Guide

## Problem Identified

Your current RLS (Row Level Security) policies were using `USING (true)` which means **anyone can see and modify all data**. This is a critical security vulnerability.

### Affected Tables:
- `orders` - Any user could view all orders
- `order_items` - Any user could view all order items
- `cart_items` - Any user could view/modify all shopping carts

## Solution Implemented

I've created two files to fix this:

1. **`supabase-fix-rls-policies.sql`** - Migration script to run in Supabase
2. **`supabase-cart-orders.sql`** - Updated with secure policies (for future use)

## What Changed

### Before (INSECURE):
```sql
CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT
  USING (true);  -- ❌ ALLOWS EVERYONE TO SEE EVERYTHING
```

### After (SECURE):
```sql
CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT
  USING (user_id = get_current_user_id());  -- ✅ ONLY OWN DATA
```

## Step-by-Step Instructions

### Step 1: Open Supabase SQL Editor

1. Go to your Supabase project dashboard
2. Click on **"SQL Editor"** in the left sidebar
3. Click **"New query"**

### Step 2: Run the Fix

Copy and paste the **entire contents** of `supabase-fix-rls-policies.sql` into the SQL Editor and run it.

The script will:
1. Create a helper function `get_current_user_id()` to get the current authenticated user
2. Drop the old insecure policies
3. Create new secure policies that restrict access to user's own data

### Step 3: Verify the Fix

Run this test query to verify policies are working:

```sql
-- Test query (should only return your own orders)
SELECT * FROM orders LIMIT 5;
```

## How It Works

The new `get_current_user_id()` function extracts the user ID from the JWT token that your application sends with each database request.

### Security Model:

- **Orders**: Users can only view/insert/update their own orders
- **Order Items**: Users can only view/insert items that belong to their own orders
- **Cart Items**: Users can only view/insert/update/delete their own cart items

## Application Integration

Your application needs to include the user ID in the JWT claims when making database requests. In your JavaScript code, you should:

```javascript
// When initializing Supabase client
const supabase = createClient(url, key, {
  global: {
    headers: {
      'x-user-id': currentUser.id  // Pass current user ID
    }
  }
});

// Or set it in the session:
await supabase.rpc('set_user_id', { user_id: currentUser.id });
```

## Testing

After running the migration, test with:

1. Log in as User A
2. Try to query orders - should only see User A's orders
3. Log in as User B
4. Try to query orders - should only see User B's orders (different from User A)

## Rollback

If you need to rollback, you can temporarily make the policies permissive again:

```sql
-- TEMPORARY ROLLBACK (for testing only - INSECURE!)
CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT
  USING (true);

-- Don't forget to add back the secure policies later!
```

## Important Notes

- ⚠️ **Backup your data** before running any migration
- ✅ The changes are **idempotent** - safe to run multiple times
- 🔒 The new policies are **secure by default**
- 📝 Your application may need updates to pass user authentication properly


// Cart and Orders API Integration with Supabase
// Handles all cart and order database operations

class CartAPI {
    constructor() {
        this.userId = null;
        this.init();
    }

    async init() {
        // Get current user from auth
        if (typeof authManager !== 'undefined' && authManager.getCurrentUser()) {
            this.userId = authManager.getCurrentUser().id;
        }
    }

    // Set user ID
    setUserId(userId) {
        this.userId = userId;
    }

    // ============================================
    // CART OPERATIONS
    // ============================================

    // Get all cart items for current user
    async getCartItems() {
        try {
            if (!this.userId) {
                throw new Error('User not authenticated');
            }

            const { data, error } = await supabase
                .from('cart_items')
                .select(`
                    id,
                    quantity,
                    added_at,
                    agent_id,
                    agents (
                        id,
                        name,
                        price_yearly,
                        price_currency,
                        category
                    )
                `)
                .eq('user_id', this.userId)
                .eq('status', 'active')
                .order('added_at', { ascending: false });

            if (error) throw error;

            return data || [];
        } catch (error) {
            console.error('Error fetching cart items:', error);
            return [];
        }
    }

    // Add item to cart
    async addToCart(agentId, quantity = 1) {
        try {
            if (!this.userId) {
                throw new Error('User not authenticated');
            }

            // Check if item already exists in cart
            const { data: existing } = await supabase
                .from('cart_items')
                .select('id, quantity')
                .eq('user_id', this.userId)
                .eq('agent_id', agentId)
                .eq('status', 'active')
                .single();

            if (existing) {
                // Update quantity
                const newQuantity = existing.quantity + quantity;
                const { data, error } = await supabase
                    .from('cart_items')
                    .update({ 
                        quantity: newQuantity,
                        updated_at: new Date().toISOString()
                    })
                    .eq('id', existing.id)
                    .select()
                    .single();

                if (error) throw error;
                return data;
            } else {
                // Insert new cart item
                const { data, error } = await supabase
                    .from('cart_items')
                    .insert({
                        user_id: this.userId,
                        agent_id: agentId,
                        quantity: quantity,
                        status: 'active'
                    })
                    .select(`
                        id,
                        quantity,
                        added_at,
                        agent_id,
                        agents (
                            id,
                            name,
                            price_yearly,
                            price_currency
                        )
                    `)
                    .single();

                if (error) throw error;
                return data;
            }
        } catch (error) {
            console.error('Error adding to cart:', error);
            throw error;
        }
    }

    // Update cart item quantity
    async updateCartItem(cartItemId, quantity) {
        try {
            if (!this.userId) {
                throw new Error('User not authenticated');
            }

            if (quantity <= 0) {
                return await this.removeFromCart(cartItemId);
            }

            const { data, error } = await supabase
                .from('cart_items')
                .update({ 
                    quantity: quantity,
                    updated_at: new Date().toISOString()
                })
                .eq('id', cartItemId)
                .eq('user_id', this.userId)
                .select()
                .single();

            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Error updating cart item:', error);
            throw error;
        }
    }

    // Remove item from cart
    async removeFromCart(cartItemId) {
        try {
            if (!this.userId) {
                throw new Error('User not authenticated');
            }

            const { error } = await supabase
                .from('cart_items')
                .delete()
                .eq('id', cartItemId)
                .eq('user_id', this.userId);

            if (error) throw error;
            return true;
        } catch (error) {
            console.error('Error removing from cart:', error);
            throw error;
        }
    }

    // Clear entire cart
    async clearCart() {
        try {
            if (!this.userId) {
                throw new Error('User not authenticated');
            }

            const { error } = await supabase
                .from('cart_items')
                .delete()
                .eq('user_id', this.userId)
                .eq('status', 'active');

            if (error) throw error;
            return true;
        } catch (error) {
            console.error('Error clearing cart:', error);
            throw error;
        }
    }

    // Get cart item count
    async getCartItemCount() {
        try {
            if (!this.userId) {
                return 0;
            }

            const { count, error } = await supabase
                .from('cart_items')
                .select('*', { count: 'exact', head: true })
                .eq('user_id', this.userId)
                .eq('status', 'active');

            if (error) throw error;
            return count || 0;
        } catch (error) {
            console.error('Error getting cart count:', error);
            return 0;
        }
    }

    // ============================================
    // ORDER OPERATIONS
    // ============================================

    // Create order from cart
    async createOrder(paymentMethod = 'tokens') {
        try {
            if (!this.userId) {
                throw new Error('User not authenticated');
            }

            // Get cart items
            const cartItems = await this.getCartItems();
            if (!cartItems || cartItems.length === 0) {
                throw new Error('Cart is empty');
            }

            // Calculate totals
            let totalPrice = 0;
            let totalTokens = 0;

            const orderItemsData = cartItems.map(item => {
                const price = parseFloat(item.agents.price_yearly);
                const quantity = item.quantity;
                const itemTotal = price * quantity;
                
                totalPrice += itemTotal;

                return {
                    agent_id: item.agent_id,
                    agent_name: item.agents.name,
                    price_per_year: price,
                    price_in_tokens: price, // Assuming 1:1 conversion
                    quantity: quantity,
                    subtotal: itemTotal,
                    subtotal_tokens: itemTotal,
                    agent_category: item.agents.category
                };
            });

            // If paying with tokens, validate and deduct balance
            if (paymentMethod === 'tokens') {
                // Get user's current balance
                const { data: balance, error: balanceError } = await databaseManager.getUserTokenBalance(this.userId);
                
                if (balanceError) {
                    throw new Error('Failed to check token balance');
                }
                
                if (balance < totalPrice) {
                    throw new Error(`Insufficient token balance. You have ${balance.toFixed(2)} tokens but need ${totalPrice.toFixed(2)} tokens.`);
                }
            }

            // Create order
            const { data: order, error: orderError } = await supabase
                .from('orders')
                .insert({
                    user_id: this.userId,
                    total_price: totalPrice,
                    total_price_usd: totalPrice,
                    payment_method: paymentMethod,
                    order_status: 'pending',
                    payment_status: paymentMethod === 'tokens' ? 'completed' : 'pending'
                })
                .select()
                .single();

            if (orderError) throw orderError;

            // Create order items
            const orderItemsWithOrderId = orderItemsData.map(item => ({
                ...item,
                order_id: order.id
            }));

            const { data: orderItems, error: itemsError } = await supabase
                .from('order_items')
                .insert(orderItemsWithOrderId)
                .select();

            if (itemsError) throw itemsError;

            // If paying with tokens, deduct the amount
            if (paymentMethod === 'tokens') {
                const description = `Purchase: ${orderItems.length} agent(s) - Order ${order.order_number}`;
                const { data: transactionId, error: tokenError } = await databaseManager.deductTokens(
                    this.userId,
                    totalPrice,
                    order.id,
                    description
                );
                
                if (tokenError) {
                    // Rollback: Delete the order if token deduction fails
                    await supabase.from('orders').delete().eq('id', order.id);
                    throw new Error('Failed to deduct tokens from your account');
                }
            }

            // Mark cart items as converted
            const cartItemIds = cartItems.map(item => item.id);
            await supabase
                .from('cart_items')
                .update({ status: 'converted' })
                .in('id', cartItemIds);

            return {
                order: order,
                items: orderItems
            };
        } catch (error) {
            console.error('Error creating order:', error);
            throw error;
        }
    }

    // Get user's order history
    async getOrderHistory() {
        try {
            if (!this.userId) {
                throw new Error('User not authenticated');
            }

            const { data, error } = await supabase
                .from('orders')
                .select(`
                    id,
                    order_number,
                    total_price,
                    total_price_usd,
                    order_status,
                    payment_status,
                    created_at,
                    order_items (
                        id,
                        agent_name,
                        price_per_year,
                        quantity,
                        subtotal,
                        item_status
                    )
                `)
                .eq('user_id', this.userId)
                .order('created_at', { ascending: false });

            if (error) throw error;

            return data || [];
        } catch (error) {
            console.error('Error fetching order history:', error);
            return [];
        }
    }

    // Get single order details
    async getOrder(orderId) {
        try {
            if (!this.userId) {
                throw new Error('User not authenticated');
            }

            const { data, error } = await supabase
                .from('orders')
                .select(`
                    *,
                    order_items (
                        *,
                        agents (
                            id,
                            name,
                            category
                        )
                    )
                `)
                .eq('id', orderId)
                .eq('user_id', this.userId)
                .single();

            if (error) throw error;

            return data;
        } catch (error) {
            console.error('Error fetching order:', error);
            return null;
        }
    }

    // Update order status (for admin or payment processing)
    async updateOrderStatus(orderId, status) {
        try {
            if (!this.userId) {
                throw new Error('User not authenticated');
            }

            const { data, error } = await supabase
                .from('orders')
                .update({ 
                    order_status: status,
                    updated_at: new Date().toISOString()
                })
                .eq('id', orderId)
                .eq('user_id', this.userId)
                .select()
                .single();

            if (error) throw error;

            return data;
        } catch (error) {
            console.error('Error updating order status:', error);
            throw error;
        }
    }
}

// Initialize cart API (will be available globally)
const cartAPI = new CartAPI();

// Update userId when user logs in
if (typeof authManager !== 'undefined') {
    const checkUser = setInterval(() => {
        const user = authManager.getCurrentUser();
        if (user && user.id) {
            cartAPI.setUserId(user.id);
            clearInterval(checkUser);
        }
    }, 1000);
}

// Export for use
window.cartAPI = cartAPI;


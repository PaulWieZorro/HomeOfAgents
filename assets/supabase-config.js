// Supabase Configuration
// Updated with actual Supabase project credentials
const SUPABASE_URL = 'https://uqwtzggvltodppaaezcj.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVxd3R6Z2d2bHRvZHBwYWFlemNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2NzQ4MjMsImV4cCI6MjA3NjI1MDgyM30.RMHTGwX0FBORVJapQ1gxt0jtIHbTbuiE7fODSia_eFc';
const SUPABASE_JWT_SECRET = 'SJSZnQS/7U3nR2xLc6zw227I7k7r94jPXXXIlEhAeSuCi2rKZtqkwvvO12imE8h7PkWBy3LolMFjHMWth/Mcmg==';

// Initialize Supabase client
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Authentication helper functions
class AuthManager {
    constructor() {
        this.currentUser = null;
        this.isVerifying = false;
    }

    // Hash password using Web Crypto API
    async hashPassword(password) {
        const encoder = new TextEncoder();
        const data = encoder.encode(password);
        const hashBuffer = await crypto.subtle.digest('SHA-256', data);
        const hashArray = Array.from(new Uint8Array(hashBuffer));
        return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    }

    // Sign up user with custom auth table
    async signUp(email, password, role) {
        try {
            const passwordHash = await this.hashPassword(password);
            
            const { data, error } = await supabase
                .from('custom_auth')
                .insert([{
                    email: email,
                    password_hash: passwordHash,
                    role: role
                }])
                .select()
                .single();

            if (error) {
                throw error;
            }

            return data;
        } catch (error) {
            console.error('Sign up error:', error);
            throw error;
        }
    }

    // Sign in user with custom auth table
    async signIn(email, password) {
        try {
            const passwordHash = await this.hashPassword(password);
            
            const { data, error } = await supabase
                .from('custom_auth')
                .select('*')
                .eq('email', email)
                .eq('password_hash', passwordHash)
                .eq('is_active', true)
                .single();

            if (error) {
                throw error;
            }

            this.currentUser = data;
            return data;
        } catch (error) {
            console.error('Sign in error:', error);
            throw error;
        }
    }

    // Sign out user
    async signOut() {
        try {
            this.currentUser = null;
            return true;
        } catch (error) {
            console.error('Sign out error:', error);
            throw error;
        }
    }

    // Get current user
    getCurrentUser() {
        return this.currentUser;
    }

    // Check if user is authenticated
    isAuthenticated() {
        return this.currentUser !== null;
    }
}

// File upload helper functions
class FileUploadManager {
    constructor() {
        this.bucketName = 'kyc-documents';
    }

    // Upload file to Supabase Storage
    async uploadFile(file, userId, documentType) {
        try {
            // Generate unique filename
            const timestamp = Date.now();
            const fileExtension = file.name.split('.').pop();
            const fileName = `${userId}_${documentType}_${timestamp}.${fileExtension}`;

            // Upload file
            const { data, error } = await supabase.storage
                .from(this.bucketName)
                .upload(fileName, file);

            if (error) {
                throw error;
            }

            // Get public URL
            const { data: urlData } = supabase.storage
                .from(this.bucketName)
                .getPublicUrl(fileName);

            return {
                fileName: fileName,
                url: urlData.publicUrl
            };
        } catch (error) {
            console.error('File upload error:', error);
            throw error;
        }
    }

    // Delete file from storage
    async deleteFile(fileName) {
        try {
            const { error } = await supabase.storage
                .from(this.bucketName)
                .remove([fileName]);

            if (error) {
                throw error;
            }
        } catch (error) {
            console.error('File deletion error:', error);
            throw error;
        }
    }
}

// Database helper functions
class DatabaseManager {
    constructor() {
        this.authManager = new AuthManager();
    }

    // Insert KYC data
    async insertKYCData(kycData) {
        try {
            const { data, error } = await supabase
                .from('kyc_data')
                .insert([kycData]);

            if (error) {
                throw error;
            }

            return data;
        } catch (error) {
            console.error('KYC data insertion error:', error);
            throw error;
        }
    }

    // Insert KYB data
    async insertKYBData(kybData) {
        try {
            const { data, error } = await supabase
                .from('kyb_data')
                .insert([kybData]);

            if (error) {
                throw error;
            }

            return data;
        } catch (error) {
            console.error('KYB data insertion error:', error);
            throw error;
        }
    }

    // Create agent in marketplace
    async createAgent(agentData) {
        try {
            // Get current user
            const user = this.authManager.getCurrentUser();
            if (!user) {
                throw new Error('User must be authenticated to create agents');
            }

            // Prepare agent data for database
            const agent = {
                name: agentData.name,
                category: agentData.category,
                description: agentData.description,
                short_description: agentData.short_description || agentData.description.substring(0, 500),
                
                // Pricing
                price_yearly: parseFloat(agentData.price_yearly) || 0,
                price_currency: 'USD',
                trial_period_days: parseInt(agentData.trial_period_days) || 30,
                demo_available: agentData.demo_available === 'true' || agentData.demo_available === true,
                
                // Default ratings (new agents start at 0)
                rating: null,
                reviews_count: 0,
                verified_status: false,
                
                // Compliance & Security
                compliance_level: agentData.compliance_level || 'standard',
                compliance_standards: agentData.compliance_standards || [],
                data_security_rating: agentData.data_security_rating || null,
                certifications: [],
                
                // Technical
                integration_options: agentData.integration_options || [],
                deployment_type: agentData.deployment_type || 'cloud',
                api_type: agentData.api_type || null,
                api_documentation_url: agentData.api_documentation_url || null,
                
                // Performance & SLA
                sla_uptime_percentage: agentData.sla_uptime_percentage ? parseFloat(agentData.sla_uptime_percentage) : null,
                guaranteed_response_time_ms: agentData.guaranteed_response_time_ms ? parseInt(agentData.guaranteed_response_time_ms) : null,
                max_concurrent_users: agentData.max_concurrent_users ? parseInt(agentData.max_concurrent_users) : null,
                monthly_api_call_limit: agentData.monthly_api_call_limit ? parseInt(agentData.monthly_api_call_limit) : null,
                
                // Support
                support_level: agentData.support_level || null,
                support_channels: agentData.support_channels || [],
                language_support: agentData.language_support || [],
                
                // Vendor
                vendor_name: agentData.vendor_name,
                vendor_url: agentData.vendor_url || null,
                vendor_email: agentData.vendor_email || null,
                vendor_location: agentData.vendor_location || null,
                
                // Additional
                use_cases: agentData.use_cases || [],
                key_features: agentData.key_features || [],
                capabilities: agentData.capabilities || [],
                
                // Search
                search_keywords: agentData.search_keywords || [],
                tags: [agentData.category],
                featured: false,
                popular: false,
                
                // Audit
                created_by: user.id,
                status: 'pending' // New agents need approval
            };

            const { data, error } = await supabase
                .from('agents')
                .insert([agent])
                .select();

            if (error) {
                throw error;
            }

            return data[0];
        } catch (error) {
            console.error('Agent creation error:', error);
            throw error;
        }
    }
}

// Initialize managers
const authManager = new AuthManager();
const fileUploadManager = new FileUploadManager();
const databaseManager = new DatabaseManager();

// Export for use in other scripts
window.supabase = supabase;
window.authManager = authManager;
window.fileUploadManager = fileUploadManager;
window.databaseManager = databaseManager;

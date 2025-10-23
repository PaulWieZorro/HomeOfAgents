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

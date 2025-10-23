// OTP Verification Modal and Authentication Flow
class OTPVerificationModal {
    constructor() {
        this.modal = null;
        this.countdownTimer = null;
        this.timeLeft = 60;
        this.userEmail = '';
        this.userRole = '';
        this.formData = null;
    }

    // Create and show OTP verification modal
    show(email, role, formData) {
        this.userEmail = email;
        this.userRole = role;
        this.formData = formData;
        this.timeLeft = 60;

        this.createModal();
        this.startCountdown();
    }

    // Create modal HTML
    createModal() {
        // Remove existing modal if any
        const existingModal = document.getElementById('otpModal');
        if (existingModal) {
            existingModal.remove();
        }

        // Create modal overlay
        const modalOverlay = document.createElement('div');
        modalOverlay.id = 'otpModal';
        modalOverlay.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.8);
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 10000;
            backdrop-filter: blur(10px);
        `;

        // Create modal content
        const modalContent = document.createElement('div');
        modalContent.style.cssText = `
            background: var(--dark);
            border: 1px solid rgba(0, 229, 255, 0.3);
            border-radius: 16px;
            padding: 40px;
            max-width: 400px;
            width: 90%;
            text-align: center;
            position: relative;
        `;

        modalContent.innerHTML = `
            <div class="logo" style="margin-bottom: 20px;">Agentry<span class="xx">xx</span></div>
            <h2 style="color: var(--cyan); margin-bottom: 16px;">Email Verification</h2>
            <p style="color: var(--silver); margin-bottom: 24px;">
                We've sent a 6-digit verification code to<br>
                <strong style="color: var(--light);">${this.userEmail}</strong>
            </p>
            
            <div style="margin-bottom: 24px;">
                <input type="text" id="otpCode" placeholder="Enter 6-digit code" maxlength="6" 
                       style="width: 100%; padding: 16px; border-radius: 8px; border: 1px solid rgba(0, 229, 255, 0.3); 
                              background: rgba(10, 17, 40, 0.8); color: var(--light); font-size: 18px; text-align: center;
                              letter-spacing: 2px;">
            </div>
            
            <div style="margin-bottom: 16px;">
                <button id="verifyOTPBtn" class="btn btn-primary" style="width: 100%; margin-bottom: 12px;">
                    Verify Code
                </button>
                <button id="resendOTPBtn" class="btn btn-secondary" style="width: 100%;" disabled>
                    Resend Code (<span id="countdown">60</span>s)
                </button>
            </div>
            
            <div id="otpError" style="color: #ff4444; font-size: 14px; margin-top: 16px; display: none;"></div>
            
            <div style="margin-top: 20px;">
                <button id="closeOTPModal" style="color: var(--silver); background: none; border: none; cursor: pointer;">
                    Cancel
                </button>
            </div>
        `;

        modalOverlay.appendChild(modalContent);
        document.body.appendChild(modalOverlay);

        this.modal = modalOverlay;
        this.setupEventListeners();
    }

    // Setup event listeners for modal
    setupEventListeners() {
        const verifyBtn = document.getElementById('verifyOTPBtn');
        const resendBtn = document.getElementById('resendOTPBtn');
        const closeBtn = document.getElementById('closeOTPModal');
        const otpInput = document.getElementById('otpCode');

        verifyBtn.addEventListener('click', () => this.verifyOTP());
        resendBtn.addEventListener('click', () => this.resendOTP());
        closeBtn.addEventListener('click', () => this.close());

        // Auto-submit when 6 digits are entered
        otpInput.addEventListener('input', (e) => {
            if (e.target.value.length === 6) {
                this.verifyOTP();
            }
        });

        // Focus on input when modal opens
        setTimeout(() => otpInput.focus(), 100);
    }

    // Start countdown timer
    startCountdown() {
        this.countdownTimer = setInterval(() => {
            this.timeLeft--;
            const countdownElement = document.getElementById('countdown');
            if (countdownElement) {
                countdownElement.textContent = this.timeLeft;
            }

            if (this.timeLeft <= 0) {
                this.enableResend();
            }
        }, 1000);
    }

    // Enable resend button
    enableResend() {
        const resendBtn = document.getElementById('resendOTPBtn');
        if (resendBtn) {
            resendBtn.disabled = false;
            resendBtn.innerHTML = 'Resend Code';
        }
        clearInterval(this.countdownTimer);
    }

    // Verify OTP code
    async verifyOTP() {
        const otpCode = document.getElementById('otpCode').value;
        const errorDiv = document.getElementById('otpError');
        const verifyBtn = document.getElementById('verifyOTPBtn');

        if (!otpCode || otpCode.length !== 6) {
            this.showError('Please enter a valid 6-digit code');
            return;
        }

        // Disable button and show loading
        verifyBtn.disabled = true;
        verifyBtn.textContent = 'Verifying...';

        try {
            // Verify OTP with Supabase
            const result = await authManager.verifyOTP(this.userEmail, otpCode);
            
            if (result.user) {
                // OTP verified successfully, proceed with form submission
                await this.submitFormData(result.user.id);
            }
        } catch (error) {
            console.error('OTP verification failed:', error);
            this.showError(error.message || 'Invalid verification code. Please try again.');
            verifyBtn.disabled = false;
            verifyBtn.textContent = 'Verify Code';
        }
    }

    // Resend OTP code
    async resendOTP() {
        const resendBtn = document.getElementById('resendOTPBtn');
        const errorDiv = document.getElementById('otpError');

        resendBtn.disabled = true;
        resendBtn.textContent = 'Sending...';

        try {
            await authManager.resendOTP(this.userEmail);
            this.timeLeft = 60;
            this.startCountdown();
            resendBtn.innerHTML = 'Resend Code (<span id="countdown">60</span>s)';
            this.clearError();
        } catch (error) {
            console.error('Resend OTP failed:', error);
            this.showError('Failed to resend code. Please try again.');
            resendBtn.disabled = false;
            resendBtn.textContent = 'Resend Code';
        }
    }

    // Submit form data after successful verification
    async submitFormData(userId) {
        try {
            // Upload file if present
            let documentUrl = '';
            if (this.formData.document) {
                const uploadResult = await fileUploadManager.uploadFile(
                    this.formData.document, 
                    userId, 
                    this.userRole === 'developer' ? 'id_document' : 'registration_document'
                );
                documentUrl = uploadResult.url;
            }

            // Prepare data for database
            const dbData = {
                user_id: userId,
                ...this.formData,
                [this.userRole === 'developer' ? 'id_document_url' : 'registration_document_url']: documentUrl
            };

            // Remove document file from data before inserting
            delete dbData.document;

            // Insert data based on user role
            if (this.userRole === 'developer') {
                await databaseManager.insertKYCData(dbData);
            } else {
                await databaseManager.insertKYBData(dbData);
            }

            // Insert user role
            await databaseManager.insertUserRole(userId, this.userRole);

            // Close modal and redirect
            this.close();
            this.showSuccessMessage();
            
            // Redirect to appropriate dashboard
            setTimeout(() => {
                if (this.userRole === 'developer') {
                    window.location.href = 'dashboard_dev.html';
                } else {
                    window.location.href = 'dashboard_company.html';
                }
            }, 2000);

        } catch (error) {
            console.error('Form submission failed:', error);
            this.showError('Failed to submit form. Please try again.');
            const verifyBtn = document.getElementById('verifyOTPBtn');
            verifyBtn.disabled = false;
            verifyBtn.textContent = 'Verify Code';
        }
    }

    // Show success message
    showSuccessMessage() {
        const successDiv = document.createElement('div');
        successDiv.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: linear-gradient(90deg, var(--pink), var(--cyan));
            color: var(--dark);
            padding: 16px 24px;
            border-radius: 8px;
            font-weight: 600;
            z-index: 10001;
            animation: slideIn 0.3s ease;
        `;
        successDiv.textContent = 'Registration successful! Redirecting...';
        document.body.appendChild(successDiv);

        setTimeout(() => {
            successDiv.remove();
        }, 3000);
    }

    // Show error message
    showError(message) {
        const errorDiv = document.getElementById('otpError');
        if (errorDiv) {
            errorDiv.textContent = message;
            errorDiv.style.display = 'block';
        }
    }

    // Clear error message
    clearError() {
        const errorDiv = document.getElementById('otpError');
        if (errorDiv) {
            errorDiv.style.display = 'none';
        }
    }

    // Close modal
    close() {
        if (this.modal) {
            this.modal.remove();
            this.modal = null;
        }
        if (this.countdownTimer) {
            clearInterval(this.countdownTimer);
        }
    }
}

// Initialize OTP modal
const otpModal = new OTPVerificationModal();

// Export for use in other scripts
window.otpModal = otpModal;

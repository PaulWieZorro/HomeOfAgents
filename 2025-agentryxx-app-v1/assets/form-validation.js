// Form validation utilities for KYC/KYB forms
class FormValidator {
    constructor() {
        this.maxFileSize = 3 * 1024 * 1024; // 3MB in bytes
        this.allowedFileTypes = ['image/jpeg', 'image/jpg', 'image/png', 'application/pdf'];
    }

    // Validate file upload
    validateFile(file) {
        const errors = [];
        
        if (!file) {
            errors.push('Please select a file');
            return errors;
        }

        // Check file size
        if (file.size > this.maxFileSize) {
            errors.push('File size must be less than 3MB');
        }

        // Check file type
        if (!this.allowedFileTypes.includes(file.type)) {
            errors.push('File must be JPG, PNG, or PDF format');
        }

        return errors;
    }

    // Validate email format
    validateEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    // Validate password strength
    validatePassword(password) {
        const errors = [];
        
        if (password.length < 8) {
            errors.push('Password must be at least 8 characters long');
        }
        
        if (!/(?=.*[a-z])/.test(password)) {
            errors.push('Password must contain at least one lowercase letter');
        }
        
        if (!/(?=.*[A-Z])/.test(password)) {
            errors.push('Password must contain at least one uppercase letter');
        }
        
        if (!/(?=.*\d)/.test(password)) {
            errors.push('Password must contain at least one number');
        }

        return errors;
    }

    // Show error message
    showError(element, message) {
        // Remove existing error
        const existingError = element.parentNode.querySelector('.error-message');
        if (existingError) {
            existingError.remove();
        }

        // Add new error
        const errorDiv = document.createElement('div');
        errorDiv.className = 'error-message';
        errorDiv.style.color = '#ff4444';
        errorDiv.style.fontSize = '12px';
        errorDiv.style.marginTop = '4px';
        errorDiv.textContent = message;
        
        element.parentNode.appendChild(errorDiv);
        
        // Add error styling to input
        element.style.borderColor = '#ff4444';
    }

    // Clear error message
    clearError(element) {
        const errorMessage = element.parentNode.querySelector('.error-message');
        if (errorMessage) {
            errorMessage.remove();
        }
        element.style.borderColor = 'rgba(0, 229, 255, 0.3)';
    }

    // Validate entire form
    validateForm(formId) {
        const form = document.getElementById(formId);
        const formData = new FormData(form);
        let isValid = true;

        // Clear all previous errors
        const errorMessages = form.querySelectorAll('.error-message');
        errorMessages.forEach(error => error.remove());

        // Validate each field
        const inputs = form.querySelectorAll('input, textarea, select');
        inputs.forEach(input => {
            this.clearError(input);
            
            if (input.hasAttribute('required') && !input.value.trim()) {
                this.showError(input, 'This field is required');
                isValid = false;
            }

            // Email validation
            if (input.type === 'email' && input.value) {
                if (!this.validateEmail(input.value)) {
                    this.showError(input, 'Please enter a valid email address');
                    isValid = false;
                }
            }

            // Password validation
            if (input.type === 'password' && input.value) {
                const passwordErrors = this.validatePassword(input.value);
                if (passwordErrors.length > 0) {
                    this.showError(input, passwordErrors[0]);
                    isValid = false;
                }
            }

            // File validation
            if (input.type === 'file' && input.files.length > 0) {
                const fileErrors = this.validateFile(input.files[0]);
                if (fileErrors.length > 0) {
                    this.showError(input, fileErrors[0]);
                    isValid = false;
                }
            }

            // Checkbox validation
            if (input.type === 'checkbox' && input.hasAttribute('required') && !input.checked) {
                this.showError(input, 'You must agree to this requirement');
                isValid = false;
            }
        });

        return isValid;
    }
}

// Initialize validator
const validator = new FormValidator();

// Add event listeners for real-time validation
document.addEventListener('DOMContentLoaded', function() {
        // KYC Form validation
        const kycForm = document.getElementById('kycForm');
        if (kycForm) {
            kycForm.addEventListener('submit', async function(e) {
                e.preventDefault();
                
                if (validator.validateForm('kycForm')) {
                    // Form is valid, proceed with Supabase submission
                    await submitKYCForm();
                }
            });

        // Real-time validation for file inputs
        const kycFileInput = document.getElementById('idDocument');
        if (kycFileInput) {
            kycFileInput.addEventListener('change', function() {
                if (this.files.length > 0) {
                    const errors = validator.validateFile(this.files[0]);
                    if (errors.length > 0) {
                        validator.showError(this, errors[0]);
                    } else {
                        validator.clearError(this);
                    }
                }
            });
        }
    }

        // KYB Form validation
        const kybForm = document.getElementById('kybForm');
        if (kybForm) {
            kybForm.addEventListener('submit', async function(e) {
                e.preventDefault();
                
                if (validator.validateForm('kybForm')) {
                    // Form is valid, proceed with Supabase submission
                    await submitKYBForm();
                }
            });

        // Real-time validation for email input
        const kybEmailInput = document.getElementById('userEmail');
        if (kybEmailInput) {
            kybEmailInput.addEventListener('blur', function() {
                if (this.value) {
                    if (!validator.validateEmail(this.value)) {
                        validator.showError(this, 'Please enter a valid email address');
                    } else {
                        validator.clearError(this);
                    }
                }
            });
        }
    }
});

// Form submission functions
async function submitKYCForm() {
    try {
        const form = document.getElementById('kycForm');
        const formData = new FormData(form);
        
        // Extract form data
        const kycData = {
            full_name: formData.get('fullName'),
            address: formData.get('address'),
            date_of_birth: formData.get('dateOfBirth'),
            passport_id: formData.get('passportId'),
            certificate_good_conduct: formData.get('certificateGoodConduct') === 'on',
            gdpr_consent: formData.get('gdprConsent') === 'on',
            document: formData.get('idDocument')
        };

        const email = formData.get('email');
        const password = formData.get('password');

        // Show loading state
        const submitBtn = form.querySelector('button[type="submit"]');
        const originalText = submitBtn.textContent;
        submitBtn.disabled = true;
        submitBtn.textContent = 'Creating Account...';

        // Sign up user
        const signUpResult = await authManager.signUp(email, password);
        
        if (signUpResult.user) {
            // User created, show OTP verification modal
            otpModal.show(email, 'developer', kycData);
        } else {
            throw new Error('Failed to create account');
        }

    } catch (error) {
        console.error('KYC submission error:', error);
        alert('Registration failed: ' + (error.message || 'Please try again'));
        
        // Reset button state
        const submitBtn = document.querySelector('#kycForm button[type="submit"]');
        submitBtn.disabled = false;
        submitBtn.textContent = 'Submit for Verification';
    }
}

async function submitKYBForm() {
    try {
        const form = document.getElementById('kybForm');
        const formData = new FormData(form);
        
        // Extract form data
        const kybData = {
            user_email: formData.get('userEmail'),
            legal_company_name: formData.get('legalCompanyName'),
            street_number: formData.get('streetNumber'),
            postcode: formData.get('postcode'),
            city: formData.get('city'),
            country_of_registration: formData.get('countryOfRegistration'),
            registration_number: formData.get('registrationNumber'),
            director_name: formData.get('directorName'),
            aml_ctf_verified: formData.get('amlCtfVerified') === 'on',
            gdpr_consent: formData.get('gdprConsent') === 'on',
            registration_document_url: '' // No document upload anymore
        };

        const userEmail = formData.get('userEmail');

        // Show loading state
        const submitBtn = form.querySelector('button[type="submit"]');
        const originalText = submitBtn.textContent;
        submitBtn.disabled = true;
        submitBtn.textContent = 'Submitting KYB...';

        // Insert KYB data directly using supabase client
        const { data: result, error: insertError } = await supabase
            .from('kyb_data')
            .insert([kybData]);
            
        if (insertError) {
            console.error('KYB insertion error:', insertError);
            throw insertError;
        }
        
        console.log('KYB data insertion result:', result);
        alert('KYB verification submitted successfully! You will be contacted once verification is complete.');
        
        // Redirect to dashboard
        window.location.href = 'dashboard_company.html';

    } catch (error) {
        console.error('KYB submission error:', error);
        alert('KYB submission failed: ' + (error.message || 'Please try again'));
        
        // Reset button state
        const submitBtn = document.querySelector('#kybForm button[type="submit"]');
        submitBtn.disabled = false;
        submitBtn.textContent = 'Submit for Verification';
    }
}

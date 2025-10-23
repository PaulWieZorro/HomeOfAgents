// Dashboard functionality
document.addEventListener('DOMContentLoaded', function() {
    // Onboarding button functionality
    const onboardingBtn = document.getElementById('onboarding-btn');
    if (onboardingBtn) {
        onboardingBtn.addEventListener('click', function() {
            // For now, redirect to a placeholder page
            // Later this can be updated to redirect to the appropriate KYC/KYB page
            // based on user role and verification status
            window.location.href = '#onboarding-page'; // Placeholder
            
            // Show a temporary message
            showNotification('Onboarding feature coming soon!', 'info');
        });
    }
});

// Notification system for dashboard
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 16px 24px;
        border-radius: 8px;
        font-weight: 600;
        z-index: 10000;
        animation: slideIn 0.3s ease;
        max-width: 300px;
    `;
    
    // Set colors based on type
    switch (type) {
        case 'success':
            notification.style.background = 'linear-gradient(90deg, var(--pink), var(--cyan))';
            notification.style.color = 'var(--dark)';
            break;
        case 'error':
            notification.style.background = '#ff4444';
            notification.style.color = 'var(--light)';
            break;
        case 'warning':
            notification.style.background = '#ffaa00';
            notification.style.color = 'var(--dark)';
            break;
        default:
            notification.style.background = 'rgba(0, 229, 255, 0.9)';
            notification.style.color = 'var(--dark)';
    }
    
    notification.textContent = message;
    document.body.appendChild(notification);
    
    // Auto remove after 3 seconds
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.remove();
            }
        }, 300);
    }, 3000);
}

// Add CSS animations for notifications
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(100%);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);

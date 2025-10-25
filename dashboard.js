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

    // Initialize charts with animations
    initializeCharts();
});

// Chart initialization and animations
function initializeCharts() {
    const charts = document.querySelectorAll('.chart-bars');
    
    charts.forEach((chart, chartIndex) => {
        const bars = chart.querySelectorAll('.bar');
        
        // Animate bars on load
        bars.forEach((bar, index) => {
            // Set initial height to 0
            bar.style.height = '0%';
            
            // Animate to target height with delay
            setTimeout(() => {
                const targetHeight = bar.getAttribute('style').match(/height:\s*(\d+%)/);
                if (targetHeight) {
                    bar.style.transition = 'height 0.8s cubic-bezier(0.4, 0, 0.2, 1)';
                    bar.style.height = targetHeight[1];
                }
            }, index * 100 + chartIndex * 200);
        });
        
        // Add hover effects for chart sections
        const chartSection = chart.closest('.chart-section');
        if (chartSection) {
            chartSection.addEventListener('mouseenter', function() {
                bars.forEach(bar => {
                    bar.style.transition = 'all 0.3s ease';
                });
            });
        }
    });
    
    // Add click interactions for bars
    const allBars = document.querySelectorAll('.bar');
    allBars.forEach(bar => {
        bar.addEventListener('click', function() {
            const value = this.getAttribute('data-value');
            const chartTitle = this.closest('.chart-section').querySelector('h3').textContent;
            
            showNotification(`${chartTitle}: ${value}`, 'info');
        });
    });
}

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

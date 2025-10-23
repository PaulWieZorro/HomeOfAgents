// toaster.js - simple toast notification system
class Toaster {
  constructor() {
    this.container = null;
    this.init();
  }
  
  init() {
    // Create toast container
    this.container = document.createElement('div');
    this.container.id = 'toast-container';
    this.container.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      z-index: 10000;
      pointer-events: none;
    `;
    document.body.appendChild(this.container);
  }
  
  show(message, type = 'info', duration = 3000) {
    const toast = document.createElement('div');
    toast.style.cssText = `
      background: rgba(46, 46, 46, 0.9);
      color: var(--light);
      padding: 12px 20px;
      border-radius: 8px;
      margin-bottom: 10px;
      backdrop-filter: blur(10px);
      border: 1px solid rgba(197, 198, 199, 0.2);
      transform: translateX(100%);
      transition: transform 0.3s ease;
      pointer-events: auto;
      max-width: 300px;
      word-wrap: break-word;
    `;
    
    // Add type-specific styling
    if (type === 'success') {
      toast.style.borderColor = 'var(--cyan)';
      toast.style.boxShadow = '0 0 20px rgba(0, 229, 255, 0.3)';
    } else if (type === 'error') {
      toast.style.borderColor = 'var(--pink)';
      toast.style.boxShadow = '0 0 20px rgba(255, 0, 127, 0.3)';
    }
    
    toast.textContent = message;
    this.container.appendChild(toast);
    
    // Animate in
    setTimeout(() => {
      toast.style.transform = 'translateX(0)';
    }, 10);
    
    // Auto remove
    setTimeout(() => {
      toast.style.transform = 'translateX(100%)';
      setTimeout(() => {
        if (toast.parentNode) {
          toast.parentNode.removeChild(toast);
        }
      }, 300);
    }, duration);
  }
  
  success(message, duration) {
    this.show(message, 'success', duration);
  }
  
  error(message, duration) {
    this.show(message, 'error', duration);
  }
  
  info(message, duration) {
    this.show(message, 'info', duration);
  }
}

// Create global instance
window.toaster = new Toaster();

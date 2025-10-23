// Main app.js - handles general functionality
document.addEventListener('DOMContentLoaded', function() {
  // Initialize starfield
  if (typeof initStarfield === 'function') {
    initStarfield();
  }
  
  // Handle subscription form only (not login/registration forms)
  const subscriptionForm = document.querySelector('#subscribe form');
  if (subscriptionForm) {
    subscriptionForm.addEventListener('submit', function(e) {
      e.preventDefault();
      
      // Basic form validation and submission handling
      const email = this.querySelector('input[type="email"]');
      if (email && !email.value) {
        alert('Please enter a valid email address');
        return;
      }
      
      // Show success message
      alert('Thank you for subscribing! We\'ll keep you posted.');
      
      // Reset form
      this.reset();
    });
  }
  
  // Smooth scrolling for anchor links
  const anchorLinks = document.querySelectorAll('a[href^="#"]');
  anchorLinks.forEach(link => {
    link.addEventListener('click', function(e) {
      e.preventDefault();
      const targetId = this.getAttribute('href').substring(1);
      const targetElement = document.getElementById(targetId);
      
      if (targetElement) {
        targetElement.scrollIntoView({
          behavior: 'smooth',
          block: 'start'
        });
      }
    });
  });
  
  // Add loading states to buttons
  const buttons = document.querySelectorAll('.btn');
  buttons.forEach(button => {
    button.addEventListener('click', function() {
      if (this.type === 'submit') {
        this.style.opacity = '0.7';
        setTimeout(() => {
          this.style.opacity = '1';
        }, 1000);
      }
    });
  });
});

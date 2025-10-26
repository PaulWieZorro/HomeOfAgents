// Main app.js - handles general functionality
document.addEventListener('DOMContentLoaded', function() {
  // Initialize starfield
  if (typeof initStarfield === 'function') {
    initStarfield();
  }
  
  // Fade-in animation on scroll for contact section
  const contactSection = document.querySelector('.contact-section');
  if (contactSection) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
        }
      });
    }, {
      threshold: 0.2,
      rootMargin: '0px'
    });
    
    observer.observe(contactSection);
  }
  
  // Handle contact form
  const contactForm = document.querySelector('#contact-form');
  if (contactForm) {
    contactForm.addEventListener('submit', function(e) {
      e.preventDefault();
      
      const email = this.querySelector('input[name="email"]').value.trim();
      const gdpr = this.querySelector('input[name="gdpr"]').checked;
      
      // Validate email
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!email || !emailRegex.test(email)) {
        alert('Please enter a valid email address');
        return;
      }
      
      // Validate GDPR checkbox
      if (!gdpr) {
        alert('Please consent to GDPR to proceed');
        return;
      }
      
      // Collect form data
      const formData = {
        email: email,
        name: this.querySelector('input[name="name"]').value.trim(),
        contact: this.querySelector('input[name="contact"]').value.trim(),
        gdpr: gdpr
      };
      
      // Here you would typically send the data to your backend
      // For now, we'll just show a success message
      console.log('Contact form submitted:', formData);
      
      // Show success message
      alert('Thank you for your interest! We\'ll be in touch soon.');
      
      // Reset form
      this.reset();
    });
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

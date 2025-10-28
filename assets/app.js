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
    contactForm.addEventListener('submit', async function(e) {
      e.preventDefault();
      
      const submitBtn = this.querySelector('button[type="submit"]');
      const originalText = submitBtn.textContent;
      
      try {
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
          name: this.querySelector('input[name="name"]').value.trim() || null,
          contact: this.querySelector('input[name="contact"]').value.trim() || null,
          gdpr_consent: gdpr,
          source: 'contact_form'
        };
        
        // Show loading state
        submitBtn.disabled = true;
        submitBtn.textContent = 'Submitting...';
        
        // Submit to Supabase
        const { data, error } = await supabase
          .from('contact_interest')
          .insert([formData])
          .select();
        
        if (error) {
          console.error('Contact form submission error:', error);
          throw error;
        }
        
        // Show success message
        if (typeof showToast === 'function') {
          showToast('Thank you for your interest! We\'ll be in touch soon.', 'success');
        } else {
          alert('Thank you for your interest! We\'ll be in touch soon.');
        }
        
        // Reset form
        this.reset();
        
      } catch (error) {
        console.error('Contact form submission error:', error);
        alert('Failed to submit. Please try again later.');
      } finally {
        // Restore button state
        submitBtn.disabled = false;
        submitBtn.textContent = originalText;
      }
    });
  }
  
  // Handle subscription form only (not login/registration forms)
  const subscriptionForm = document.querySelector('#subscribe form');
  if (subscriptionForm) {
    subscriptionForm.addEventListener('submit', async function(e) {
      e.preventDefault();
      
      const submitBtn = this.querySelector('button[type="submit"]');
      const originalText = submitBtn.textContent;
      
      try {
        // Get email and validate
        const emailInput = this.querySelector('input[type="email"]');
        const email = emailInput.value.trim();
        
        // Validate email
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!email || !emailRegex.test(email)) {
          alert('Please enter a valid email address');
          return;
        }
        
        // Show loading state
        submitBtn.disabled = true;
        submitBtn.textContent = 'Subscribing...';
        
        // Prepare subscription data
        const formData = {
          email: email,
          name: null,
          contact: null,
          gdpr_consent: true, // Assumed consent for newsletter
          source: 'subscribe'
        };
        
        // Submit to Supabase
        const { data, error } = await supabase
          .from('contact_interest')
          .insert([formData])
          .select();
        
        if (error) {
          console.error('Subscription error:', error);
          throw error;
        }
        
        // Show success message
        if (typeof showToast === 'function') {
          showToast('Thank you for subscribing! We\'ll keep you posted.', 'success');
        } else {
          alert('Thank you for subscribing! We\'ll keep you posted.');
        }
        
        // Reset form
        this.reset();
        
      } catch (error) {
        console.error('Subscription error:', error);
        alert('Failed to subscribe. Please try again later.');
      } finally {
        // Restore button state
        submitBtn.disabled = false;
        submitBtn.textContent = originalText;
      }
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

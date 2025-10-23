// starfield.js - handles the animated starfield background
function initStarfield() {
  const stars = document.getElementById('stars');
  if (!stars) return;
  
  // Clear existing stars
  stars.innerHTML = '';
  
  // Create stars
  for (let i = 0; i < 80; i++) {
    const star = document.createElement('div');
    star.className = 'star';
    star.style.left = Math.random() * 100 + '%';
    star.style.top = Math.random() * 100 + '%';
    star.style.animationDelay = Math.random() * 3 + 's';
    stars.appendChild(star);
  }
}

// Export for use in other files
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { initStarfield };
}

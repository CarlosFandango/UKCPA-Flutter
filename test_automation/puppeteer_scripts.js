/**
 * UKCPA Flutter App - Puppeteer Automation Scripts
 * 
 * These scripts can be used with Claude Code's MCP Puppeteer server
 * to automate testing, debugging, and UI validation workflows.
 */

// Configuration
const CONFIG = {
  baseUrl: 'http://localhost:59203', // Update this with your Flutter app URL
  testCredentials: {
    email: 'info@carl-stanley.com',
    password: 'password'
  },
  screenshots: {
    width: 402, // Width for screenshots
    height: 878, // Height for screenshots
    path: './screenshots/'
  },
  timeouts: {
    navigation: 5000,
    element: 3000,
    form: 2000
  }
};

/**
 * Core automation functions that can be called through MCP
 */

// 1. LOGIN AUTOMATION
async function loginWithCredentials(email = CONFIG.testCredentials.email, password = CONFIG.testCredentials.password) {
  console.log(`🔐 Logging in with email: ${email}`);
  
  // Navigate to login page
  await navigate(`${CONFIG.baseUrl}/#/auth/login`);
  await screenshot('01_login_page');
  
  // Fill email field
  await fill('input[type="email"], [data-testid="email-input"], input[placeholder*="mail" i]', email);
  await screenshot('02_email_filled');
  
  // Fill password field
  await fill('input[type="password"], [data-testid="password-input"], input[placeholder*="password" i]', password);
  await screenshot('03_password_filled');
  
  // Submit form
  await click('button[type="submit"], [data-testid="login-button"], button:has-text("Sign In")');
  await screenshot('04_login_submitted');
  
  // Wait for navigation or error
  await new Promise(resolve => setTimeout(resolve, 3000));
  await screenshot('05_post_login');
  
  console.log('✅ Login flow completed');
}

// 2. PAGE NAVIGATION AUTOMATION
async function navigateToPages() {
  const pages = [
    { name: 'Home', path: '/#/home', id: 'home' },
    { name: 'Courses', path: '/#/courses', id: 'courses' },
    { name: 'My Account', path: '/#/account', id: 'account' },
    { name: 'Booking', path: '/#/booking', id: 'booking' }
  ];
  
  for (const page of pages) {
    console.log(`📄 Navigating to ${page.name}`);
    await navigate(`${CONFIG.baseUrl}${page.path}`);
    await new Promise(resolve => setTimeout(resolve, 2000)); // Wait for load
    await screenshot(`page_${page.id}`);
  }
  
  console.log('✅ Page navigation completed');
}

// 3. FORM TESTING AUTOMATION
async function testFormValidation() {
  console.log('🧪 Testing form validation');
  
  await navigate(`${CONFIG.baseUrl}/#/auth/login`);
  
  // Test empty form submission
  await click('button[type="submit"]');
  await screenshot('form_validation_empty');
  
  // Test invalid email
  await fill('input[type="email"]', 'invalid-email');
  await click('button[type="submit"]');
  await screenshot('form_validation_invalid_email');
  
  // Test short password
  await fill('input[type="email"]', 'test@example.com');
  await fill('input[type="password"]', '123');
  await click('button[type="submit"]');
  await screenshot('form_validation_short_password');
  
  console.log('✅ Form validation testing completed');
}

// 4. RESPONSIVE DESIGN TESTING
async function testResponsiveDesign() {
  const viewports = [
    { name: 'Desktop', width: 1200, height: 800 },
    { name: 'Tablet', width: 768, height: 1024 },
    { name: 'Mobile', width: 375, height: 667 }
  ];
  
  for (const viewport of viewports) {
    console.log(`📱 Testing ${viewport.name} viewport (${viewport.width}x${viewport.height})`);
    
    // Note: This would require page.setViewport() in actual Puppeteer
    // For MCP, we'll take screenshots at different sizes
    await screenshot(`responsive_${viewport.name.toLowerCase()}_login`, viewport.width, viewport.height);
    
    if (viewport.name !== 'Desktop') {
      // Test mobile navigation if applicable
      await click('[data-testid="mobile-menu"], .hamburger-menu, button[aria-label*="menu" i]').catch(e => 
        console.log('No mobile menu found')
      );
      await screenshot(`responsive_${viewport.name.toLowerCase()}_menu_open`, viewport.width, viewport.height);
    }
  }
  
  console.log('✅ Responsive design testing completed');
}

// 5. ACCESSIBILITY TESTING
async function testAccessibility() {
  console.log('♿ Testing accessibility');
  
  await navigate(`${CONFIG.baseUrl}/#/auth/login`);
  
  // Test keyboard navigation
  await evaluate(`
    // Focus first focusable element
    const focusable = document.querySelector('input, button, a, [tabindex]:not([tabindex="-1"])');
    if (focusable) focusable.focus();
  `);
  await screenshot('accessibility_focus_first');
  
  // Test tab navigation (simulate tab key)
  for (let i = 0; i < 5; i++) {
    await evaluate(`
      const focused = document.activeElement;
      const focusables = Array.from(document.querySelectorAll('input, button, a, [tabindex]:not([tabindex="-1"])'));
      const currentIndex = focusables.indexOf(focused);
      const nextElement = focusables[currentIndex + 1];
      if (nextElement) nextElement.focus();
    `);
    await screenshot(`accessibility_tab_${i + 1}`);
  }
  
  console.log('✅ Accessibility testing completed');
}

// 6. PERFORMANCE MONITORING
async function monitorPerformance() {
  console.log('⚡ Monitoring performance');
  
  const startTime = Date.now();
  await navigate(`${CONFIG.baseUrl}/#/auth/login`);
  const loadTime = Date.now() - startTime;
  
  await screenshot('performance_loaded');
  
  // Log performance metrics
  const metrics = await evaluate(`
    return {
      loadTime: ${loadTime},
      domElements: document.querySelectorAll('*').length,
      images: document.querySelectorAll('img').length,
      scripts: document.querySelectorAll('script').length,
      stylesheets: document.querySelectorAll('link[rel="stylesheet"]').length
    };
  `);
  
  console.log('📊 Performance Metrics:', metrics);
  console.log('✅ Performance monitoring completed');
}

// 7. ERROR SCENARIO TESTING
async function testErrorScenarios() {
  console.log('🚫 Testing error scenarios');
  
  // Test network errors by navigating to invalid route
  await navigate(`${CONFIG.baseUrl}/#/invalid-route`);
  await screenshot('error_404_page');
  
  // Test login with invalid credentials
  await navigate(`${CONFIG.baseUrl}/#/auth/login`);
  await fill('input[type="email"]', 'invalid@test.com');
  await fill('input[type="password"]', 'wrongpassword');
  await click('button[type="submit"]');
  await screenshot('error_invalid_login');
  
  console.log('✅ Error scenario testing completed');
}

/**
 * WORKFLOW COMPOSITIONS
 * These combine multiple automation functions for complete testing flows
 */

// Complete UI Testing Workflow
async function fullUITestSuite() {
  console.log('🎯 Starting Full UI Test Suite');
  
  await testFormValidation();
  await loginWithCredentials();
  await navigateToPages();
  await testResponsiveDesign();
  await testAccessibility();
  await monitorPerformance();
  await testErrorScenarios();
  
  console.log('🎉 Full UI Test Suite Completed!');
}

// Quick Smoke Test
async function quickSmokeTest() {
  console.log('💨 Starting Quick Smoke Test');
  
  await loginWithCredentials();
  await navigateToPages();
  
  console.log('✅ Quick Smoke Test Completed!');
}

// Daily Regression Test
async function dailyRegressionTest() {
  console.log('📅 Starting Daily Regression Test');
  
  const timestamp = new Date().toISOString().split('T')[0];
  
  await screenshot(`regression_${timestamp}_start`);
  await loginWithCredentials();
  await navigateToPages();
  await testFormValidation();
  await screenshot(`regression_${timestamp}_end`);
  
  console.log('✅ Daily Regression Test Completed!');
}

/**
 * UTILITY FUNCTIONS
 * Helper functions for the automation scripts
 */

// Screenshot with timestamp
async function timestampedScreenshot(name) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  await screenshot(`${timestamp}_${name}`);
}

// Wait for element with timeout
async function waitForElement(selector, timeout = CONFIG.timeouts.element) {
  console.log(`⏳ Waiting for element: ${selector}`);
  // Implementation would depend on MCP capabilities
  await new Promise(resolve => setTimeout(resolve, 1000));
}

// Check if element exists
async function elementExists(selector) {
  return await evaluate(`document.querySelector('${selector}') !== null`);
}

// Get element text
async function getElementText(selector) {
  return await evaluate(`
    const element = document.querySelector('${selector}');
    return element ? element.textContent.trim() : null;
  `);
}

/**
 * EXPORT CONFIGURATIONS FOR MCP USAGE
 */
module.exports = {
  CONFIG,
  
  // Core Functions
  loginWithCredentials,
  navigateToPages,
  testFormValidation,
  testResponsiveDesign,
  testAccessibility,
  monitorPerformance,
  testErrorScenarios,
  
  // Workflow Compositions
  fullUITestSuite,
  quickSmokeTest,
  dailyRegressionTest,
  
  // Utilities
  timestampedScreenshot,
  waitForElement,
  elementExists,
  getElementText
};

/**
 * USAGE EXAMPLES FOR CLAUDE CODE MCP:
 * 
 * 1. Basic Login Test:
 *    - Call loginWithCredentials() with your test credentials
 * 
 * 2. Page Navigation Test:
 *    - Call navigateToPages() to visit all main pages
 * 
 * 3. Complete Testing:
 *    - Call fullUITestSuite() for comprehensive testing
 * 
 * 4. Quick Check:
 *    - Call quickSmokeTest() for fast validation
 * 
 * 5. Custom Workflow:
 *    - Combine individual functions as needed
 */
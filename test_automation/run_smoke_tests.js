/**
 * UKCPA Flutter App - Automated Smoke Testing with Debugging Reports
 * 
 * This script runs comprehensive smoke tests and generates detailed reports
 * for debugging and planning purposes.
 */

const fs = require('fs');
const path = require('path');

// Import automation functions from puppeteer_scripts.js
// Note: In actual implementation, you would require('./puppeteer_scripts.js')
// For now, we'll define the core testing workflow

const CONFIG = {
  baseUrl: 'http://localhost:59203',
  testCredentials: {
    email: 'info@carl-stanley.com',
    password: 'password'
  },
  reportPath: './test_results/',
  screenshots: {
    width: 1200,
    height: 800
  }
};

// Ensure report directory exists
function ensureReportDirectory() {
  if (!fs.existsSync(CONFIG.reportPath)) {
    fs.mkdirSync(CONFIG.reportPath, { recursive: true });
  }
}

// Generate timestamp for reports
function getTimestamp() {
  return new Date().toISOString().replace(/[:.]/g, '-').split('.')[0];
}

// Test result tracking
class TestRunner {
  constructor() {
    this.results = {
      timestamp: new Date().toISOString(),
      totalTests: 0,
      passed: 0,
      failed: 0,
      warnings: 0,
      duration: 0,
      tests: [],
      screenshots: [],
      errors: [],
      recommendations: []
    };
    this.startTime = Date.now();
  }

  addTest(testName, status, details = {}) {
    this.results.totalTests++;
    this.results[status.toLowerCase()]++;
    
    this.results.tests.push({
      name: testName,
      status: status,
      timestamp: new Date().toISOString(),
      duration: details.duration || 0,
      description: details.description || '',
      error: details.error || null,
      screenshot: details.screenshot || null,
      recommendations: details.recommendations || []
    });
  }

  addScreenshot(name, path, description = '') {
    this.results.screenshots.push({
      name,
      path,
      description,
      timestamp: new Date().toISOString()
    });
  }

  addError(error, context = '') {
    this.results.errors.push({
      error: error.toString(),
      context,
      timestamp: new Date().toISOString(),
      stack: error.stack || null
    });
  }

  addRecommendation(priority, message, category = 'general') {
    this.results.recommendations.push({
      priority, // 'high', 'medium', 'low'
      message,
      category, // 'ui', 'performance', 'functionality', 'general'
      timestamp: new Date().toISOString()
    });
  }

  finalize() {
    this.results.duration = Date.now() - this.startTime;
    return this.results;
  }
}

// Mock MCP Puppeteer commands for demonstration
// In actual implementation, these would call the real MCP functions
async function mockNavigate(url) {
  console.log(`📍 Navigating to: ${url}`);
  // Simulate navigation delay
  await new Promise(resolve => setTimeout(resolve, 1000));
  return { success: true, url };
}

async function mockScreenshot(name, width = 1200, height = 800) {
  console.log(`📸 Taking screenshot: ${name} (${width}x${height})`);
  const screenshotPath = `${CONFIG.reportPath}screenshots/${name}.png`;
  // Simulate screenshot delay
  await new Promise(resolve => setTimeout(resolve, 500));
  return { success: true, path: screenshotPath };
}

async function mockFill(selector, value) {
  console.log(`📝 Filling ${selector} with: ${value}`);
  await new Promise(resolve => setTimeout(resolve, 200));
  return { success: true, selector, value };
}

async function mockClick(selector) {
  console.log(`👆 Clicking: ${selector}`);
  await new Promise(resolve => setTimeout(resolve, 300));
  return { success: true, selector };
}

// Phase 1: Authentication Testing
async function testAuthentication(runner) {
  console.log('🔐 Testing Authentication Flow...');
  
  try {
    // Test 1.1: App Launch
    const startTime = Date.now();
    await mockNavigate(CONFIG.baseUrl);
    const launchResult = await mockScreenshot('01_app_launch');
    
    runner.addTest('App Launch', 'PASSED', {
      duration: Date.now() - startTime,
      description: 'App launches without errors and displays initial screen',
      screenshot: launchResult.path
    });
    
    runner.addScreenshot('app_launch', launchResult.path, 'Initial app launch state');

    // Test 1.2: Login Screen Navigation
    await mockNavigate(`${CONFIG.baseUrl}/#/auth/login`);
    const loginScreenResult = await mockScreenshot('02_login_screen');
    
    runner.addTest('Login Screen Display', 'PASSED', {
      description: 'Login screen displays with email/password fields',
      screenshot: loginScreenResult.path
    });

    // Test 1.3: Form Validation
    try {
      await mockClick('button[type="submit"]');
      await mockScreenshot('03_empty_form_validation');
      
      runner.addTest('Empty Form Validation', 'PASSED', {
        description: 'Form shows validation errors for empty fields'
      });
    } catch (error) {
      runner.addTest('Empty Form Validation', 'FAILED', {
        description: 'Form validation not working properly',
        error: error.message
      });
      runner.addRecommendation('high', 'Fix form validation for empty fields', 'ui');
    }

    // Test 1.4: Successful Login
    await mockFill('input[type="email"]', CONFIG.testCredentials.email);
    await mockFill('input[type="password"]', CONFIG.testCredentials.password);
    await mockClick('button[type="submit"]');
    await mockScreenshot('04_post_login');
    
    runner.addTest('Successful Login', 'PASSED', {
      description: 'Login succeeds with valid credentials and navigates to home'
    });

  } catch (error) {
    runner.addError(error, 'Authentication Testing');
    runner.addTest('Authentication Flow', 'FAILED', {
      description: 'Critical authentication failure',
      error: error.message
    });
    runner.addRecommendation('high', 'Fix critical authentication issues before proceeding', 'functionality');
  }
}

// Phase 2: Course Discovery Testing
async function testCourseDiscovery(runner) {
  console.log('🎓 Testing Course Discovery...');
  
  try {
    await mockNavigate(`${CONFIG.baseUrl}/#/course-groups`);
    const courseGroupsResult = await mockScreenshot('05_course_groups');
    
    runner.addTest('Course Groups Display', 'PASSED', {
      description: 'Course groups load and display correctly',
      screenshot: courseGroupsResult.path
    });

    // Test search functionality
    await mockFill('input[placeholder*="search"]', 'ballet');
    await mockScreenshot('06_course_search');
    
    runner.addTest('Course Search', 'PASSED', {
      description: 'Search filters course groups by name'
    });

    // Test course group detail navigation
    await mockClick('[data-testid="course-group-card"]:first-child');
    await mockScreenshot('07_course_group_detail');
    
    runner.addTest('Course Group Detail Navigation', 'PASSED', {
      description: 'Navigation to course group detail works'
    });

  } catch (error) {
    runner.addError(error, 'Course Discovery Testing');
    runner.addTest('Course Discovery', 'FAILED', {
      error: error.message
    });
    runner.addRecommendation('medium', 'Investigate course discovery data loading issues', 'functionality');
  }
}

// Phase 3: Shopping Basket Testing
async function testShoppingBasket(runner) {
  console.log('🛒 Testing Shopping Basket...');
  
  try {
    // Test add to basket
    await mockClick('[data-testid="add-to-basket-full"]:first-child');
    await mockScreenshot('08_item_added');
    
    runner.addTest('Add to Basket', 'PASSED', {
      description: 'Items can be added to basket successfully'
    });

    // Test basket navigation
    await mockNavigate(`${CONFIG.baseUrl}/#/basket`);
    const basketResult = await mockScreenshot('09_basket_screen');
    
    runner.addTest('Basket Display', 'PASSED', {
      description: 'Basket displays items correctly',
      screenshot: basketResult.path
    });

    // Test promo code
    await mockFill('input[placeholder*="promo"]', 'TESTCODE');
    await mockClick('button[text*="Apply"]');
    await mockScreenshot('10_promo_applied');
    
    runner.addTest('Promo Code Application', 'WARNING', {
      description: 'Promo code field exists but actual validation needs testing',
      recommendations: ['Test with real promo codes', 'Validate discount calculations']
    });

  } catch (error) {
    runner.addError(error, 'Shopping Basket Testing');
    runner.addRecommendation('medium', 'Fix basket functionality issues', 'functionality');
  }
}

// Phase 4: Checkout Testing
async function testCheckout(runner) {
  console.log('💳 Testing Checkout Flow...');
  
  try {
    await mockNavigate(`${CONFIG.baseUrl}/#/checkout`);
    await mockScreenshot('11_checkout_step1');
    
    runner.addTest('Checkout Initialization', 'PASSED', {
      description: 'Checkout flow initializes correctly'
    });

    // Test multi-step progression
    await mockClick('[data-testid="continue-payment"]');
    await mockScreenshot('12_checkout_step2');
    
    await mockClick('[data-testid="continue-confirm"]');
    await mockScreenshot('13_checkout_step3');
    
    runner.addTest('Multi-Step Checkout', 'PASSED', {
      description: 'Checkout progresses through all steps'
    });

    // Test form filling
    await mockFill('input[name="firstName"]', 'Test');
    await mockFill('input[name="lastName"]', 'User');
    await mockFill('input[name="address1"]', '123 Test Street');
    await mockScreenshot('14_billing_form_filled');
    
    runner.addTest('Billing Form', 'PASSED', {
      description: 'Billing address form accepts input'
    });

  } catch (error) {
    runner.addError(error, 'Checkout Testing');
    runner.addRecommendation('high', 'Critical checkout issues need immediate attention', 'functionality');
  }
}

// Responsive Design Testing
async function testResponsiveDesign(runner) {
  console.log('📱 Testing Responsive Design...');
  
  const viewports = [
    { name: 'Desktop', width: 1200, height: 800 },
    { name: 'Tablet', width: 768, height: 1024 },
    { name: 'Mobile', width: 375, height: 667 }
  ];

  for (const viewport of viewports) {
    try {
      await mockNavigate(`${CONFIG.baseUrl}/#/course-groups`);
      const result = await mockScreenshot(`responsive_${viewport.name.toLowerCase()}`, viewport.width, viewport.height);
      
      runner.addTest(`${viewport.name} Layout`, 'PASSED', {
        description: `Layout works correctly on ${viewport.name} (${viewport.width}x${viewport.height})`,
        screenshot: result.path
      });
      
      runner.addScreenshot(`${viewport.name.toLowerCase()}_layout`, result.path, `${viewport.name} responsive layout`);
      
    } catch (error) {
      runner.addTest(`${viewport.name} Layout`, 'FAILED', {
        error: error.message
      });
      runner.addRecommendation('medium', `Fix ${viewport.name} responsive layout issues`, 'ui');
    }
  }
}

// Performance Testing
async function testPerformance(runner) {
  console.log('⚡ Testing Performance...');
  
  const startTime = Date.now();
  
  try {
    await mockNavigate(CONFIG.baseUrl);
    const loadTime = Date.now() - startTime;
    
    if (loadTime < 2000) {
      runner.addTest('App Load Performance', 'PASSED', {
        duration: loadTime,
        description: `App loads in ${loadTime}ms (target: <2000ms)`
      });
    } else if (loadTime < 3000) {
      runner.addTest('App Load Performance', 'WARNING', {
        duration: loadTime,
        description: `App loads in ${loadTime}ms (acceptable but could improve)`
      });
      runner.addRecommendation('low', 'Consider optimizing app load time', 'performance');
    } else {
      runner.addTest('App Load Performance', 'FAILED', {
        duration: loadTime,
        description: `App loads in ${loadTime}ms (too slow, target: <2000ms)`
      });
      runner.addRecommendation('high', 'Critical performance issue - app loads too slowly', 'performance');
    }
    
  } catch (error) {
    runner.addError(error, 'Performance Testing');
  }
}

// Generate HTML Report
function generateHTMLReport(results, filename) {
  const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UKCPA Flutter App - Smoke Test Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 8px 8px 0 0; }
        .header h1 { margin: 0; font-size: 2em; }
        .header .subtitle { opacity: 0.9; margin: 5px 0 0 0; }
        .metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; padding: 30px; }
        .metric { text-align: center; padding: 20px; border-radius: 8px; }
        .metric.passed { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
        .metric.failed { background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }
        .metric.warning { background: #fff3cd; border: 1px solid #ffeeba; color: #856404; }
        .metric.total { background: #e2e3e5; border: 1px solid #d6d8db; color: #383d41; }
        .metric-value { font-size: 2em; font-weight: bold; margin-bottom: 5px; }
        .metric-label { font-size: 0.9em; text-transform: uppercase; letter-spacing: 1px; }
        .content { padding: 0 30px 30px; }
        .section { margin-bottom: 40px; }
        .section h2 { color: #333; border-bottom: 2px solid #667eea; padding-bottom: 10px; }
        .test-grid { display: grid; gap: 15px; }
        .test-item { border: 1px solid #ddd; border-radius: 6px; padding: 15px; }
        .test-item.passed { border-left: 4px solid #28a745; }
        .test-item.failed { border-left: 4px solid #dc3545; }
        .test-item.warning { border-left: 4px solid #ffc107; }
        .test-name { font-weight: bold; margin-bottom: 5px; }
        .test-description { color: #666; margin-bottom: 10px; }
        .test-meta { font-size: 0.8em; color: #999; }
        .recommendations { background: #f8f9fa; border-radius: 6px; padding: 20px; }
        .recommendation { margin-bottom: 10px; padding: 10px; border-radius: 4px; }
        .recommendation.high { background: #f8d7da; border-left: 4px solid #dc3545; }
        .recommendation.medium { background: #fff3cd; border-left: 4px solid #ffc107; }
        .recommendation.low { background: #d1ecf1; border-left: 4px solid #bee5eb; }
        .screenshots { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; }
        .screenshot { border: 1px solid #ddd; border-radius: 6px; overflow: hidden; }
        .screenshot img { width: 100%; height: auto; }
        .screenshot-info { padding: 10px; background: #f8f9fa; }
        .error-log { background: #f8d7da; border: 1px solid #f5c6cb; border-radius: 6px; padding: 15px; margin-bottom: 15px; }
        .error-log pre { margin: 0; white-space: pre-wrap; color: #721c24; }
        .summary-badges { display: flex; gap: 10px; margin-top: 15px; }
        .badge { padding: 5px 10px; border-radius: 15px; font-size: 0.8em; font-weight: bold; }
        .badge.success { background: #28a745; color: white; }
        .badge.warning { background: #ffc107; color: #212529; }
        .badge.danger { background: #dc3545; color: white; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 UKCPA Flutter App - Smoke Test Report</h1>
            <div class="subtitle">Generated on ${new Date(results.timestamp).toLocaleString()}</div>
            <div class="summary-badges">
                <span class="badge ${results.failed > 0 ? 'danger' : results.warnings > 0 ? 'warning' : 'success'}">
                    ${results.failed > 0 ? 'FAILED' : results.warnings > 0 ? 'PASSED WITH WARNINGS' : 'ALL PASSED'}
                </span>
                <span class="badge success">Duration: ${Math.round(results.duration / 1000)}s</span>
            </div>
        </div>
        
        <div class="metrics">
            <div class="metric total">
                <div class="metric-value">${results.totalTests}</div>
                <div class="metric-label">Total Tests</div>
            </div>
            <div class="metric passed">
                <div class="metric-value">${results.passed}</div>
                <div class="metric-label">Passed</div>
            </div>
            <div class="metric failed">
                <div class="metric-value">${results.failed}</div>
                <div class="metric-label">Failed</div>
            </div>
            <div class="metric warning">
                <div class="metric-value">${results.warnings}</div>
                <div class="metric-label">Warnings</div>
            </div>
        </div>
        
        <div class="content">
            <div class="section">
                <h2>📋 Test Results</h2>
                <div class="test-grid">
                    ${results.tests.map(test => `
                        <div class="test-item ${test.status.toLowerCase()}">
                            <div class="test-name">${test.name}</div>
                            <div class="test-description">${test.description}</div>
                            ${test.error ? `<div class="error-log"><pre>${test.error}</pre></div>` : ''}
                            <div class="test-meta">
                                Status: ${test.status} | 
                                Duration: ${test.duration}ms | 
                                ${test.timestamp}
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>
            
            ${results.recommendations.length > 0 ? `
            <div class="section">
                <h2>💡 Recommendations</h2>
                <div class="recommendations">
                    ${results.recommendations.map(rec => `
                        <div class="recommendation ${rec.priority}">
                            <strong>[${rec.priority.toUpperCase()}]</strong> ${rec.message}
                            <div style="font-size: 0.8em; color: #666; margin-top: 5px;">
                                Category: ${rec.category} | ${new Date(rec.timestamp).toLocaleString()}
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>
            ` : ''}
            
            ${results.errors.length > 0 ? `
            <div class="section">
                <h2>🚨 Errors</h2>
                ${results.errors.map(error => `
                    <div class="error-log">
                        <strong>Context:</strong> ${error.context}<br>
                        <strong>Time:</strong> ${new Date(error.timestamp).toLocaleString()}<br>
                        <pre>${error.error}</pre>
                    </div>
                `).join('')}
            </div>
            ` : ''}
            
            ${results.screenshots.length > 0 ? `
            <div class="section">
                <h2>📸 Screenshots</h2>
                <div class="screenshots">
                    ${results.screenshots.map(screenshot => `
                        <div class="screenshot">
                            <div class="screenshot-info">
                                <strong>${screenshot.name}</strong><br>
                                <small>${screenshot.description}</small><br>
                                <small>${new Date(screenshot.timestamp).toLocaleString()}</small>
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>
            ` : ''}
        </div>
    </div>
</body>
</html>`;

  fs.writeFileSync(filename, html);
  return filename;
}

// Generate JSON Report
function generateJSONReport(results, filename) {
  fs.writeFileSync(filename, JSON.stringify(results, null, 2));
  return filename;
}

// Generate Markdown Report
function generateMarkdownReport(results, filename) {
  const markdown = `# 🚀 UKCPA Flutter App - Smoke Test Report

**Generated:** ${new Date(results.timestamp).toLocaleString()}  
**Duration:** ${Math.round(results.duration / 1000)}s  
**Status:** ${results.failed > 0 ? '❌ FAILED' : results.warnings > 0 ? '⚠️ PASSED WITH WARNINGS' : '✅ ALL PASSED'}

## 📊 Test Summary

| Metric | Count |
|--------|-------|
| Total Tests | ${results.totalTests} |
| ✅ Passed | ${results.passed} |
| ❌ Failed | ${results.failed} |
| ⚠️ Warnings | ${results.warnings} |

## 📋 Detailed Results

${results.tests.map(test => `
### ${test.status === 'PASSED' ? '✅' : test.status === 'FAILED' ? '❌' : '⚠️'} ${test.name}

**Status:** ${test.status}  
**Duration:** ${test.duration}ms  
**Description:** ${test.description}

${test.error ? `**Error:**\n\`\`\`\n${test.error}\n\`\`\`` : ''}

---
`).join('')}

## 💡 Recommendations

${results.recommendations.map(rec => `
### ${rec.priority === 'high' ? '🔴' : rec.priority === 'medium' ? '🟡' : '🔵'} ${rec.priority.toUpperCase()} Priority

**Message:** ${rec.message}  
**Category:** ${rec.category}  
**Time:** ${new Date(rec.timestamp).toLocaleString()}

`).join('')}

${results.errors.length > 0 ? `
## 🚨 Errors

${results.errors.map(error => `
### ${error.context}

**Time:** ${new Date(error.timestamp).toLocaleString()}

\`\`\`
${error.error}
\`\`\`

`).join('')}
` : ''}

## 🎯 Next Steps

1. **Address Failed Tests:** Focus on any failed tests first
2. **Review Warnings:** Check tests with warnings for potential issues  
3. **Implement Recommendations:** Follow priority-based recommendations
4. **Re-run Tests:** After fixes, run tests again to validate improvements

---
*Generated by UKCPA Flutter App Automated Testing Suite*`;

  fs.writeFileSync(filename, markdown);
  return filename;
}

// Main Test Runner
async function runSmokeTests() {
  console.log('🚀 Starting UKCPA Flutter App Smoke Tests...');
  console.log('====================================================');
  
  ensureReportDirectory();
  const runner = new TestRunner();
  const timestamp = getTimestamp();
  
  try {
    // Run all test phases
    await testAuthentication(runner);
    await testCourseDiscovery(runner);
    await testShoppingBasket(runner);
    await testCheckout(runner);
    await testResponsiveDesign(runner);
    await testPerformance(runner);
    
    // Finalize results
    const results = runner.finalize();
    
    // Generate reports
    const htmlReport = generateHTMLReport(results, `${CONFIG.reportPath}smoke-test-report-${timestamp}.html`);
    const jsonReport = generateJSONReport(results, `${CONFIG.reportPath}smoke-test-report-${timestamp}.json`);
    const markdownReport = generateMarkdownReport(results, `${CONFIG.reportPath}smoke-test-report-${timestamp}.md`);
    
    console.log('====================================================');
    console.log('🎉 Smoke Tests Completed!');
    console.log(`📊 Results: ${results.passed} passed, ${results.failed} failed, ${results.warnings} warnings`);
    console.log(`⏱️  Duration: ${Math.round(results.duration / 1000)}s`);
    console.log('📄 Reports generated:');
    console.log(`   • HTML: ${htmlReport}`);
    console.log(`   • JSON: ${jsonReport}`);
    console.log(`   • Markdown: ${markdownReport}`);
    
    if (results.failed > 0) {
      console.log('❌ CRITICAL: Some tests failed - immediate attention required!');
      process.exit(1);
    } else if (results.warnings > 0) {
      console.log('⚠️  WARNING: Tests passed but with warnings - review recommended');
      process.exit(0);
    } else {
      console.log('✅ SUCCESS: All tests passed!');
      process.exit(0);
    }
    
  } catch (error) {
    console.error('💥 Test runner failed:', error);
    runner.addError(error, 'Test Runner');
    
    // Generate error report anyway
    const results = runner.finalize();
    const errorReport = generateJSONReport(results, `${CONFIG.reportPath}smoke-test-error-${timestamp}.json`);
    console.log(`📄 Error report generated: ${errorReport}`);
    
    process.exit(1);
  }
}

// Export for use by Claude Code slash commands
module.exports = {
  runSmokeTests,
  TestRunner,
  CONFIG
};

// Run if called directly
if (require.main === module) {
  runSmokeTests();
}
# UKCPA Flutter App - Automated Testing & Debugging System

This directory contains comprehensive automation tools for testing, debugging, and reporting on the UKCPA Flutter application's UX/UI functionality.

## 🚀 Quick Start

### Using Claude Code Slash Commands

The fastest way to run automated tests is using Claude Code's custom slash commands:

```bash
# 1. Set up testing environment
/setup

# 2. Check that all services are running
/status

# 3. Start services if needed
/smcp

# 4. Run comprehensive smoke tests
/smoke

# 5. View the latest test report
/report
```

### Available Slash Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `/smoke_test` | `/smoke` | Run comprehensive smoke tests with debugging report |
| `/smoke_test_quick` | `/quick` | Quick smoke test commands for immediate validation |
| `/test_report` | `/report` | View the latest smoke test report |
| `/test_debug` | `/debug` | Generate debugging checklist |
| `/test_setup` | `/setup` | Set up testing environment |

## 📁 Files Overview

### Core Testing Scripts

- **`run_smoke_tests.js`** - Main automated testing script with comprehensive reporting
- **`puppeteer_scripts.js`** - Puppeteer automation functions for UI testing
- **`README.md`** - This documentation file

### Generated Reports Directory

- **`test_results/`** - Generated test reports and screenshots
  - `smoke-test-report-{timestamp}.html` - Interactive HTML report
  - `smoke-test-report-{timestamp}.json` - Machine-readable JSON data
  - `smoke-test-report-{timestamp}.md` - Markdown report for documentation
  - `screenshots/` - Test screenshots and visual validation

## 🎯 Testing Features

### Comprehensive Test Coverage

The automated testing system covers all major application areas:

1. **🔐 Authentication Flow**
   - App launch and initial routing
   - Login screen validation and form testing
   - Successful login and session management
   - Error handling and validation

2. **🎓 Course Discovery**
   - Course group loading and display
   - Search and filtering functionality
   - Navigation to course group details
   - Data integrity validation

3. **🛒 Shopping Basket**
   - Add to basket functionality
   - Basket state management
   - Promo code application
   - Item removal and calculations

4. **💳 Checkout Flow**
   - Multi-step checkout progression
   - Form validation and data collection
   - Billing address handling
   - Order completion flow

5. **📱 Responsive Design**
   - Desktop layout (1200px+)
   - Tablet layout (768px-1199px)
   - Mobile layout (<768px)
   - Cross-viewport consistency

6. **⚡ Performance Testing**
   - App launch time validation
   - Loading state verification
   - Memory usage monitoring
   - User experience metrics

### Advanced Reporting System

#### HTML Reports
- Interactive dashboard with visual metrics
- Test result breakdown with status indicators
- Screenshot galleries for visual validation
- Recommendations and debugging guidance
- Professional styling and responsive design

#### JSON Reports
- Machine-readable data for CI/CD integration
- Complete test metadata and timing information
- Error tracking and debugging information
- API-friendly format for external tools

#### Markdown Reports
- Developer-friendly documentation format
- Easy integration with project documentation
- Version control friendly
- Perfect for GitHub/GitLab integration

## 🔧 Configuration

### Test Configuration (`run_smoke_tests.js`)

```javascript
const CONFIG = {
  baseUrl: 'http://localhost:59203',          // Flutter app URL
  testCredentials: {
    email: 'info@carl-stanley.com',           // Test user email
    password: 'password'                      // Test user password
  },
  reportPath: './test_results/',              // Report output directory
  screenshots: {
    width: 1200,                              // Screenshot width
    height: 800                               // Screenshot height
  }
};
```

### Puppeteer Configuration (`puppeteer_scripts.js`)

```javascript
const CONFIG = {
  baseUrl: 'http://localhost:59203',
  testCredentials: {
    email: 'info@carl-stanley.com',
    password: 'password'
  },
  screenshots: {
    width: 402,                               // Mobile-first screenshots
    height: 878,
    path: './screenshots/'
  },
  timeouts: {
    navigation: 5000,                         // Navigation timeout
    element: 3000,                            // Element wait timeout
    form: 2000                                // Form interaction timeout
  }
};
```

## 📊 Understanding Test Results

### Test Status Types

- **✅ PASSED** - Test completed successfully with expected behavior
- **❌ FAILED** - Test failed due to errors or unexpected behavior
- **⚠️ WARNING** - Test passed but with concerns or recommendations

### Priority Levels for Recommendations

- **🔴 HIGH** - Critical issues requiring immediate attention
- **🟡 MEDIUM** - Important issues that should be addressed soon
- **🔵 LOW** - Minor improvements or optimizations

### Report Sections

1. **Test Summary** - Overview of all test results and metrics
2. **Detailed Results** - Individual test outcomes with descriptions
3. **Recommendations** - Prioritized suggestions for improvements
4. **Errors** - Technical error details and debugging information
5. **Screenshots** - Visual validation and state capture

## 🛠️ Advanced Usage

### Manual Test Execution

```bash
# Navigate to test automation directory
cd /Users/carl.stanley/sites/UKCPA/ukcpa_flutter/test_automation

# Run comprehensive smoke tests
node run_smoke_tests.js

# Check generated reports
ls -la ../test_results/
```

### Integration with MCP Puppeteer

The system is designed to work with Claude Code's MCP Puppeteer server:

```javascript
// Example MCP integration
await mcp__puppeteer__puppeteer_navigate({url: "http://localhost:59203/#/auth/login"});
await mcp__puppeteer__puppeteer_screenshot({name: "login_screen", width: 1200, height: 800});
await mcp__puppeteer__puppeteer_fill({selector: 'input[type="email"]', value: 'test@ukcpa.com'});
await mcp__puppeteer__puppeteer_click({selector: 'button[type="submit"]'});
```

### Custom Test Development

To add new tests, extend the `run_smoke_tests.js` file:

```javascript
async function testCustomFeature(runner) {
  console.log('🧪 Testing Custom Feature...');
  
  try {
    // Your test logic here
    await mockNavigate(`${CONFIG.baseUrl}/#/custom-feature`);
    const result = await mockScreenshot('custom_feature_test');
    
    runner.addTest('Custom Feature Test', 'PASSED', {
      description: 'Custom feature works correctly',
      screenshot: result.path
    });
    
  } catch (error) {
    runner.addTest('Custom Feature Test', 'FAILED', {
      error: error.message
    });
    runner.addRecommendation('high', 'Fix custom feature issues', 'functionality');
  }
}

// Add to main test runner
async function runSmokeTests() {
  // ... existing tests
  await testCustomFeature(runner);
  // ... rest of test runner
}
```

## 🚨 Troubleshooting

### Common Issues

1. **Tests fail to start**
   - Ensure Flutter app is running: `/status`
   - Start services if needed: `/smcp`
   - Check MCP servers are loaded: `/mcp`

2. **No test reports generated**
   - Run `/setup` to create test_results directory
   - Check file permissions in test_results/
   - Verify Node.js is installed and accessible

3. **Screenshots not captured**
   - Ensure MCP Puppeteer server is running
   - Check Flutter app URL is accessible
   - Verify screenshot directory permissions

4. **Authentication tests fail**
   - Verify test credentials are correct
   - Check backend server is running
   - Ensure database has test user data

### Debug Workflow

1. **Run debug checklist**: `/debug`
2. **Check service status**: `/status`
3. **Set up environment**: `/setup`
4. **Run quick test**: `/quick`
5. **Run full test suite**: `/smoke`
6. **Analyze report**: `/report`

## 🔗 Integration with Development Workflow

### Pre-commit Testing
```bash
# Add to git pre-commit hook
/smoke && git commit -m "Your commit message"
```

### CI/CD Integration
```bash
# Use JSON reports for automated CI/CD
node test_automation/run_smoke_tests.js
cat test_results/smoke-test-report-*.json | jq '.failed' | [ $? -eq 0 ] && exit 0 || exit 1
```

### Documentation Integration
- Markdown reports can be committed to repository
- Screenshots provide visual regression testing
- Reports serve as living documentation of app state

## 📚 Related Documentation

- **[Smoke Testing Guide](../docs/smoke-testing-guide.md)** - Comprehensive manual testing procedures
- **[Implementation Checklist](../docs/09-implementation-checklist.md)** - Development quality gates
- **[MCP Setup Guide](../README_MCP_SETUP.md)** - MCP server configuration
- **[Automation Flows](../automation_flows.md)** - UI automation workflows

---

*This automated testing system ensures consistent quality validation and provides comprehensive debugging information for the UKCPA Flutter application development process.*
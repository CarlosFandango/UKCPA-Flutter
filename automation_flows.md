# UKCPA Flutter - MCP Puppeteer Automation Flows

This document contains predefined automation flows for testing and debugging the UKCPA Flutter app using Claude Code's MCP Puppeteer server.

## Quick Reference Commands

### 1. Login Flow
```javascript
// Navigate to login
await mcp__puppeteer__puppeteer_navigate({url: "http://localhost:59203/#/auth/login"});
await mcp__puppeteer__puppeteer_screenshot({name: "login_page", width: 402, height: 878});

// Fill credentials
await mcp__puppeteer__puppeteer_fill({selector: 'input[type="email"]', value: 'info@carl-stanley.com'});
await mcp__puppeteer__puppeteer_fill({selector: 'input[type="password"]', value: 'password'});
await mcp__puppeteer__puppeteer_screenshot({name: "credentials_filled", width: 402, height: 878});

// Submit login
await mcp__puppeteer__puppeteer_click({selector: 'button[type="submit"]'});
await mcp__puppeteer__puppeteer_screenshot({name: "post_login", width: 402, height: 878});
```

### 2. Page Navigation Flow
```javascript
const pages = [
  {name: "home", url: "/#/home"},
  {name: "courses", url: "/#/courses"}, 
  {name: "account", url: "/#/account"},
  {name: "booking", url: "/#/booking"}
];

// Visit each page and capture screenshot
for (const page of pages) {
  await mcp__puppeteer__puppeteer_navigate({url: `http://localhost:59203${page.url}`});
  await mcp__puppeteer__puppeteer_screenshot({name: `page_${page.name}`, width: 1200, height: 800});
}
```

### 3. Form Validation Testing
```javascript
// Test empty form submission
await mcp__puppeteer__puppeteer_navigate({url: "http://localhost:59203/#/auth/login"});
await mcp__puppeteer__puppeteer_click({selector: 'button[type="submit"]'});
await mcp__puppeteer__puppeteer_screenshot({name: "empty_form_validation", width: 1200, height: 800});

// Test invalid email
await mcp__puppeteer__puppeteer_fill({selector: 'input[type="email"]', value: 'invalid-email'});
await mcp__puppeteer__puppeteer_click({selector: 'button[type="submit"]'});
await mcp__puppeteer__puppeteer_screenshot({name: "invalid_email_validation", width: 1200, height: 800});
```

### 4. Responsive Design Testing
```javascript
const viewports = [
  {name: "desktop", width: 1200, height: 800},
  {name: "tablet", width: 768, height: 1024},
  {name: "mobile", width: 375, height: 667}
];

// Test login page across viewports
for (const viewport of viewports) {
  await mcp__puppeteer__puppeteer_navigate({url: "http://localhost:59203/#/auth/login"});
  await mcp__puppeteer__puppeteer_screenshot({
    name: `responsive_${viewport.name}_login`, 
    width: viewport.width, 
    height: viewport.height
  });
}
```

### 5. Accessibility Testing
```javascript
// Focus testing
await mcp__puppeteer__puppeteer_navigate({url: "http://localhost:59203/#/auth/login"});
await mcp__puppeteer__puppeteer_evaluate({
  script: `
    const firstFocusable = document.querySelector('input, button, a, [tabindex]:not([tabindex="-1"])');
    if (firstFocusable) firstFocusable.focus();
  `
});
await mcp__puppeteer__puppeteer_screenshot({name: "accessibility_focus", width: 1200, height: 800});
```

### 6. Error Scenario Testing
```javascript
// Test 404 page
await mcp__puppeteer__puppeteer_navigate({url: "http://localhost:59203/#/invalid-route"});
await mcp__puppeteer__puppeteer_screenshot({name: "error_404", width: 1200, height: 800});

// Test invalid login
await mcp__puppeteer__puppeteer_navigate({url: "http://localhost:59203/#/auth/login"});
await mcp__puppeteer__puppeteer_fill({selector: 'input[type="email"]', value: 'invalid@test.com'});
await mcp__puppeteer__puppeteer_fill({selector: 'input[type="password"]', value: 'wrongpassword'});
await mcp__puppeteer__puppeteer_click({selector: 'button[type="submit"]'});
await mcp__puppeteer__puppeteer_screenshot({name: "invalid_login_error", width: 1200, height: 800});
```

## Common UI Testing Workflows

### Complete Login-to-Dashboard Flow
1. Navigate to login page
2. Fill credentials
3. Submit form
4. Verify successful navigation
5. Capture dashboard state
6. Test main navigation

### Form Validation Suite
1. Test empty form submission
2. Test invalid email formats
3. Test weak passwords
4. Test SQL injection attempts
5. Verify error messages display correctly

### Cross-Page Navigation Test
1. Login successfully  
2. Visit each main page
3. Verify page loads correctly
4. Check for JavaScript errors
5. Validate responsive behavior

### User Journey Testing
1. New user registration flow
2. Course browsing and selection
3. Booking process
4. Payment flow (if applicable)
5. Account management

## Debugging Commands

### Capture Current State
```javascript
await mcp__puppeteer__puppeteer_screenshot({name: "current_state", width: 1200, height: 800});
```

### Check Console Errors
```javascript
await mcp__puppeteer__puppeteer_evaluate({
  script: `
    console.log('Current URL:', window.location.href);
    console.log('Page Title:', document.title);
    console.log('Errors in console:', window.errors || 'None captured');
  `
});
```

### Inspect Element Properties
```javascript
await mcp__puppeteer__puppeteer_evaluate({
  script: `
    const element = document.querySelector('input[type="email"]');
    if (element) {
      console.log('Element found:', {
        value: element.value,
        placeholder: element.placeholder,
        disabled: element.disabled,
        required: element.required
      });
    }
  `
});
```

## Configuration Variables

Update these values based on your environment:

```javascript
const CONFIG = {
  baseUrl: 'http://localhost:59203', // Your Flutter app URL
  testCredentials: {
    email: 'info@carl-stanley.cm',         // Test user email
    password: 'password'       // Test user password
  },
  screenshots: {
    width: 1200,
    height: 800
  }
};
```

## Best Practices

1. **Always take screenshots** before and after interactions
2. **Use descriptive names** for screenshots to track test progression
3. **Test multiple viewport sizes** for responsive design validation
4. **Include error scenarios** in your testing flows
5. **Combine multiple commands** for comprehensive testing workflows
6. **Use evaluation scripts** to inspect application state
7. **Document your test flows** for team collaboration

## Troubleshooting

### Common Issues:
- **Element not found**: Use more specific selectors or wait for page load
- **Navigation timeout**: Increase wait times between actions
- **Screenshot timing**: Add delays before capturing screenshots
- **Form submission**: Ensure all required fields are filled

### Debugging Steps:
1. Take screenshot to see current state
2. Use evaluate to check console errors
3. Inspect element properties
4. Verify page URL and navigation state
5. Check network errors if applicable
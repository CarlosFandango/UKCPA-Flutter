# Course List Page UX Improvements Checklist

## Overview
This checklist tracks the implementation of UX improvements to match what users currently see on the UKCPA website (pages/class-booking/index.tsx). Each item should be completed and committed individually to bring the Flutter app to feature parity with the existing website experience.

## Current Website Features (Baseline)
✅ **Already implemented on website:**
- Hero section with gradient background and course description
- Term-based organization with headers showing course group count
- Course cards with:
  - High-quality course images with custom positioning
  - Course title and short description
  - Pricing display (from/to format)
  - Location badges (Online, Studio, or Mixed)
  - "View Course" buttons with arrow icons
  - Card hover effects and shadows
  - Responsive grid layout (1-4 columns)
- Pull-to-refresh capability (via server-side props refresh)

## High Priority Fixes

### 1. ✅ Enhance Filter Functionality **[PARTIALLY COMPLETE]**
- [x] Add filter button functionality to the existing filter icon
- [x] Create filter bottom sheet/modal with options:
  - [x] Age group dropdown (Children, Adults, All Ages)
  - [x] Level dropdown (Beginner, Intermediate, Advanced)  
  - [x] Day of week multi-select (Mon-Sun filter chips)
  - [x] Dance type and location filters (already working)
- [x] Apply filters to course list with matching logic
- [x] Show active filter count badge on filter icon
- [ ] **MISSING**: Time of day options (Morning, Afternoon, Evening, Weekend)
- [ ] **MISSING**: Filter count badge display
- **STATUS**: Core filtering implemented, needs minor enhancements
- **Commit message**: "feat: Add comprehensive filter functionality to course list"

### 2. ✅ Course Images **[ALREADY IMPLEMENTED]**
- [x] Image field exists in CourseGroup model (`image`, `thumbImage`, `imagePosition`)
- [x] Placeholder icon shows when no image available
- [x] Image positioning support with X/Y coordinates
- [x] CachedNetworkImage for proper caching
- [x] Fallback handling for broken/missing images
- **STATUS**: ✅ **COMPLETE** - Images are properly implemented, just need real image URLs in data
- **WEBSITE PARITY**: ✅ Matches website functionality
- **Next Action**: Update mock data with real course images when available

### 3. ❌ **CRITICAL**: Change Button Text and Style
- [ ] **WEBSITE SHOWS**: "View Course" button with arrow icon (yellow/primary color)
- [ ] **FLUTTER SHOWS**: Only arrow icon, no text
- [ ] Replace arrow-only with "View Course" text + arrow (match website)
- [ ] Style button to match website yellow/primary theme
- [ ] Ensure button is easily tappable (min 48x48dp) 
- [ ] Add loading state for button when clicked
- **WEBSITE PARITY**: ❌ Missing button text that users expect
- **Priority**: HIGH - Users expect "View Course" button text from website
- **Commit message**: "feat: Add 'View Course' button text to match website UX"

### 4. ❌ **NEW FEATURE**: Schedule Information (Enhancement beyond website)
- [ ] **WEBSITE SHOWS**: Only course name, description, and price
- [ ] **FLUTTER ENHANCEMENT**: Add schedule information to cards:
  - [ ] Days of the week (e.g., "Mon, Wed, Fri") 
  - [ ] Time slots (e.g., "6:00 PM - 7:30 PM")
  - [ ] Start date (e.g., "Starts Jan 15")
- [ ] Format schedule information clearly and concisely
- [ ] Add icon for schedule (calendar icon)
- **WEBSITE PARITY**: ✅ Website doesn't show this (mobile app enhancement)
- **Priority**: MEDIUM - Nice addition for mobile users
- **Commit message**: "feat: Display schedule information on course cards"

### 5. ❌ **NEW FEATURE**: Course Duration and Level (Enhancement beyond website)
- [ ] **WEBSITE SHOWS**: Only basic course info
- [ ] **FLUTTER ENHANCEMENT**: Add metadata to course cards:
  - [ ] Duration display (e.g., "10 weeks", "8 sessions")
  - [ ] Level indicator with styling (Beginner/Intermediate/Advanced)
  - [ ] Age group display (e.g., "Ages 7-12", "Adults 18+")
- [ ] Use icons for visual clarity
- **WEBSITE PARITY**: ✅ Website doesn't show this (mobile app enhancement)
- **Priority**: MEDIUM - Mobile users would benefit from quick overview
- **Commit message**: "feat: Add duration, level, and age information to course cards"

## Medium Priority Improvements

### 6. ❌ Add Availability Indicator
- [ ] Display available spaces (e.g., "5 spaces left")
- [ ] Show "Full" badge for fully booked courses
- [ ] Color code availability:
  - [ ] Green: 5+ spaces
  - [ ] Orange: 1-4 spaces
  - [ ] Red: Full
- [ ] Disable "Book Now" button for full courses
- **Commit message**: "feat: Add availability indicators to course cards"

### 7. ✅ Pull-to-Refresh **[ALREADY IMPLEMENTED]**
- [x] RefreshIndicator widget already wraps course list
- [x] Refresh logic reloads course data via termsNotifierProvider.refreshTerms()
- [x] Loading indicator shows during refresh
- [x] Connected to refresh button in app bar
- **STATUS**: ✅ **COMPLETE** - Pull-to-refresh is fully functional
- **WEBSITE PARITY**: ✅ Matches website refresh capability
- **Commit message**: ✅ Already committed

### 8. ✅ Loading States **[ALREADY IMPLEMENTED]**
- [x] LoadingShimmer component exists and is used
- [x] Shows loading spinner and "Loading dance classes..." text
- [x] Proper state management with TermsStateLoading 
- [x] Replaces with actual content when loaded
- **STATUS**: ✅ **COMPLETE** - Loading states are properly implemented
- **WEBSITE PARITY**: ✅ Better than website (website has no loading state)
- **Possible Enhancement**: Could add card-specific skeleton shapes
- **Commit message**: ✅ Already committed

## Low Priority Enhancements

### 9. ❌ Add Course Badges
- [ ] Implement badge system:
  - [ ] "Popular" badge for high-enrollment courses
  - [ ] "New" badge for recently added courses
  - [ ] "Last Chance" badge for nearly full courses
- [ ] Position badges on top-right of course cards
- [ ] Use appropriate colors and icons
- **Commit message**: "feat: Add course badges for popular and new courses"

### 10. ✅ Empty State **[ALREADY IMPLEMENTED]**
- [x] Custom empty state widget already exists
- [x] Shows search_off icon and helpful message
- [x] Displays "No course groups found" with "Try adjusting your search or filters"
- [x] Includes "Clear Filters" button when filters are active
- [x] Has _clearFilters() functionality
- **STATUS**: ✅ **COMPLETE** - Empty state is well-designed
- **WEBSITE PARITY**: ✅ Better than website (website shows no empty state)
- **Commit message**: ✅ Already committed

## Testing Checklist

After implementing each feature:
- [ ] Run the UX review test to verify improvements
- [ ] Take screenshots of the updated UI
- [ ] Test on different screen sizes
- [ ] Verify accessibility (proper labels, contrast)
- [ ] Check performance (smooth scrolling, fast loading)

## PRIORITY SUMMARY (Based on Website Comparison)

### 🔴 **CRITICAL - Website Parity Issues**
1. **Button Text Missing**: Flutter only shows arrow, website shows "View Course" + arrow ❌
2. **Filter Count Badge**: Website doesn't have this, but it's expected mobile UX ❌

### 🟡 **ENHANCEMENTS - Beyond Website** 
3. Schedule information on cards (mobile-specific enhancement) ⭕
4. Course duration/level metadata (mobile-specific enhancement) ⭕
5. Availability indicators (mobile-specific enhancement) ⭕
6. Course badges for popular/new courses ⭕

### ✅ **COMPLETE - Already Matches or Exceeds Website**
- ✅ Course images with positioning (matches website)
- ✅ Pull-to-refresh functionality (matches website)
- ✅ Loading states (better than website)
- ✅ Empty state handling (better than website) 
- ✅ Search and filtering (enhanced beyond website)
- ✅ Hero section and term organization (matches website)
- ✅ Responsive grid layout (matches website)
- ✅ Card design and hover effects (matches website)

## Updated Completion Tracking

| Priority Level | Total Items | Completed | Remaining | Status |
|---------------|-------------|-----------|-----------|---------|
| 🔴 Critical   | 2           | 0         | 2         | **Fix for parity** |
| 🟡 Enhancement| 4           | 0         | 4         | **Nice to have** |
| ✅ Complete   | 4           | 4         | 0         | **Done** |
| **TOTAL**     | **10**      | **4**     | **6**     | **40% Complete** |

## Next Actions
1. **IMMEDIATE**: Fix "View Course" button text (critical for user expectations)
2. **IMMEDIATE**: Add filter count badge (expected mobile UX)
3. **THEN**: Consider mobile enhancements (schedule info, etc.)

---

*Last Updated: [Current Date]*
*Screenshot Before: build/screenshots/course_group_list_initial.png*
*Screenshot After: [To be added after improvements]*
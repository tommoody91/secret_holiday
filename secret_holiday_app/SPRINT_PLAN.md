# Secret Holiday App - Complete Sprint Plan

## Project Overview
A collaborative trip planning app where groups take turns organizing secret holiday destinations, with rich memory capture and expense tracking.

**Core Concept:** Groups rotate organizers yearly. The organizer surprises the group with a destination, handles planning, then everyone captures memories together.

---

## ✅ COMPLETED SPRINTS

### **SPRINT 1: Authentication & Foundation** ✅
**Status:** Complete  
**Completed:** November 19, 2025

**Features Delivered:**
- Firebase Authentication setup
- Email/password sign up and login
- Email verification flow
- Password reset functionality
- Splash screen with animations
- Auth state management with Riverpod
- Navigation guards and routing
- Error handling and snackbar feedback
- User model and repository

**Files Created:**
- `lib/features/auth/` - Complete auth feature module
- `lib/core/router/app_router.dart` - Navigation with auth guards
- `lib/core/presentation/widgets/` - Reusable UI components

---

### **SPRINT 2: Groups Foundation & Bug Fixes** ✅
**Status:** Complete  
**Completed:** November 20, 2025

**Features Delivered:**
- Group data model with rules and preferences
- Group repository with full CRUD operations
- Create group with comprehensive settings:
  - Budget per person, max trip days, luggage allowance
  - Custom rules, no-repeat countries option
  - 5 preference sliders (adventurousness, food focus, urban vs nature, budget flexibility, pace)
- Join group via 6-character invite code
- Group selection screen with member counts
- Group settings screen with member management
- Remove member, leave group, delete group
- Invite code generation and sharing

**Critical Bug Fixes:**
- Fixed `arrayContains` query issue with complex objects
- Added `memberIds` field for efficient group member queries
- Created Firestore composite index for groups
- Updated all group CRUD operations to maintain `memberIds`

**Files:**
- `lib/features/groups/` - Complete groups feature
- `SPRINT2_BUG_FIXES.md` - Detailed bug fix documentation
- `FIRESTORE_SETUP.md` - Firestore configuration guide

---

### **SPRINT 3: Main Navigation & Timeline Structure** ✅
**Status:** Complete  
**Completed:** November 20, 2025

**Features Delivered:**
- Bottom navigation bar with 5 tabs:
  - Timeline (home)
  - Map (placeholder)
  - Planning (placeholder)
  - Chat (placeholder)
  - Profile (placeholder)
- Main scaffold structure
- Group header in timeline showing selected group
- Empty states for timeline
- Pull-to-refresh capability
- Proper state management for navigation

**Files:**
- `lib/features/home/presentation/screens/main_scaffold.dart`
- `lib/features/timeline/presentation/screens/timeline_screen.dart`
- Tab placeholder screens for map, planning, chat, profile

---

### **SPRINT 4: Trip Management Foundation** ✅
**Status:** Complete  
**Completed:** November 21, 2025

**Features Delivered:**

**Data Layer:**
- `TripModel` with full serialization:
  - Trip ID, name, destination, country, country code
  - Start/end dates with duration calculation
  - Organizer ID and name
  - Status enum (planning, ongoing, completed, cancelled)
  - Budget: total cost and cost per person
  - Participant IDs array (auto-populated with all group members)
  - Itinerary array (for future Sprint 14)
  - Media array (for Sprint 5)
  - Cover photo URL
  - Coordinates (latitude/longitude for maps)
  - Description/summary
  - Created/updated timestamps
- `TripLocation` model for destination data
- `ItineraryDay` model (skeleton for Sprint 14)
- `TripMedia` model (skeleton for Sprint 5)
- Status auto-calculation based on dates with `currentStatus` computed getter

**Repository:**
- `TripRepository` with full CRUD:
  - Create trip (auto-assigns participants and calculates status)
  - Get trip by ID
  - Stream trips for group (ordered by startDate)
  - Stream upcoming trips
  - Stream past trips
  - Update trip details (all fields including status and participants)
  - Delete trip (organizer/admin only with permission check)
  - Add/remove media (prepared for Sprint 5)
- `TripProvider` with Riverpod code generation

**UI - Create/Edit:**
- `CreateTripScreen` with form validation:
  - Trip name input
  - Destination and country inputs
  - Date range picker with visual feedback
  - Budget per person (numeric input)
  - Description textarea
  - Form validation and error handling
  - Success feedback with navigation
- `EditTripScreen` (pre-populated form):
  - Edit all trip details
  - Only accessible to organizer or admin
  - Permission checks in UI

**UI - Display:**
- `TripDetailsScreen` with 3 tabs:
  - **Overview Tab:**
    - Status badge (color-coded: blue/green/grey/red)
    - Participant count with people icon
    - Trip name, location, dates
    - Duration display
    - Organizer card with avatar
    - Budget information
    - Description
  - **Memories Tab:** Placeholder for Sprint 5
  - **Expenses Tab:** Placeholder for Sprint 10
  - Edit button (organizer/admin only)
  - Delete button with confirmation (organizer/admin only)
  
- `TripCard` widget:
  - Destination and dates
  - Color-coded status badge with icons
  - Participant count badge
  - Gradient background matching trip status
  - Duration and budget display
  - Tap to navigate to details

**Timeline Integration:**
- Updated `TimelineScreen`:
  - Upcoming trips section
  - Ongoing trips section ("Happening Now")
  - Past trips section
  - Empty state with "Plan New Trip" button
  - FloatingActionButton for creating trips (when trips exist)
  - Pull-to-refresh
  - Proper navigation to trip details

**Firebase:**
- Firestore security rules for trips:
  - Group members can read all trips
  - Group members can create trips
  - Organizer or admin can update/delete trips
- Composite index for trips:
  - Collection: `groups/{groupId}/trips`
  - Field: `startDate` (descending)
- Complete documentation in `FIRESTORE_SETUP.md`

**Files Created/Modified:**
- `lib/features/timeline/data/models/trip_model.dart` ✅
- `lib/features/timeline/data/repositories/trip_repository.dart` ✅
- `lib/features/timeline/providers/trip_provider.dart` ✅
- `lib/features/timeline/presentation/screens/create_trip_screen.dart` ✅
- `lib/features/timeline/presentation/screens/edit_trip_screen.dart` ✅
- `lib/features/timeline/presentation/screens/trip_details_screen.dart` ✅
- `lib/features/timeline/presentation/widgets/trip_card.dart` ✅
- `lib/features/timeline/presentation/screens/timeline_screen.dart` ✅
- `lib/core/router/app_router.dart` - Added trip routes ✅
- `FIRESTORE_SETUP.md` - Added trips section ✅

---

## 🚀 UPCOMING SPRINTS

### **SPRINT 5: Planning & Memories (MEGA SPRINT)** 🎯 NEXT
**Goal:** Unified system for pre-trip planning AND memory capture with photos  
**Priority:** HIGH - Core feature combining itinerary planning with memory keeping  
**Estimated Time:** 7-8 days

**Key Concept:** A flexible day-by-day system that evolves from planning → execution → memories. Organizers plan the itinerary, everyone captures memories.

**Permissions:**
- **Planning (Itinerary)**: Only trip organizer can add/edit/delete planned activities
- **Memories (Photos/Notes)**: All trip participants can add, react, and comment
- **Editing/Deleting**: Organizer can edit planning, memory creators can edit their own memories

---

#### **5.1: Data Models (Day 1)**
**Tasks:**
- [ ] Create `TripDayModel`:
  - Day number (1, 2, 3...)
  - Date
  - Planning notes (organizer only)
  - Actual notes (what happened - collaborative)
  - Created/updated timestamps
  
- [ ] Create `PlannedActivityModel`:
  - Activity ID, trip ID, group ID
  - Day number (0 = unassigned to day, in "General Lists")
  - Name/title
  - Type: `restaurant`, `activity`, `transport`, `accommodation`, `other`
  - Location (optional)
  - Time (optional - can be "10:00" or "morning" or null)
  - Notes/description
  - Booking reference (optional)
  - Cost (optional)
  - Status: `planned`, `confirmed`, `completed`, `skipped`
  - Created by: user ID (organizer)
  - Created/updated timestamps
  
- [ ] Create `TripMemoryModel`:
  - Memory ID, trip ID, group ID
  - Day number (optional - can be assigned to a day or null)
  - Photo/video URLs array
  - Caption/notes (max 1000 chars)
  - Location data (optional): lat/lng, place name
  - Timestamp (when captured)
  - Created by: user ID, name, avatar URL
  - Reactions: Map of emoji to user ID arrays (`{"❤️": ["user1", "user2"]}`)
  - Created/updated timestamps
  
- [ ] Create repositories:
  - `PlannedActivityRepository`: CRUD for activities (organizer only for write)
  - `TripMemoryRepository`: CRUD for memories (all participants can write)
  - `TripDayRepository`: Get/update day notes
  
- [ ] Create Riverpod providers for each repository

---

#### **5.2: Itinerary Tab - Planning UI (Day 2-3)**
**Tasks:**
- [ ] Update `TripDetailsScreen` tabs:
  - Tab 1: Overview (existing)
  - Tab 2: **Itinerary** (NEW - replaces old placeholder)
  - Tab 3: **Memories** (NEW - photo gallery view)
  - Tab 4: Expenses (existing from Sprint 10)
  
- [ ] Create `ItineraryTab`:
  - **Top Section: General Lists** (expandable):
    - "📋 General Lists" header with expand/collapse
    - Three sublists:
      - **Restaurants** (list of unassigned restaurant activities)
      - **Activities** (list of unassigned activity items)
      - **Notes** (organizer's planning notes)
    - Each item shows: name, type icon, location
    - Add button for each list (organizer only)
    - Drag items to assign to specific days below
  
  - **Day-by-Day Section**:
    - ExpansionTile for each day (Day 1, Day 2, etc.)
    - Day header shows:
      - Day number and date
      - Summary: "3 activities, 5 photos"
      - Add buttons: [+ Activity] [+ Photo] (+ Activity organizer only)
    - Expanded day shows:
      - **Planning Section** (organizer only can edit):
        - List of planned activities for that day
        - Checkbox to mark as completed ✓
        - Time and location displayed
        - Status badge (planned/confirmed/completed/skipped)
        - Tap activity to edit details
        - Swipe to delete (organizer only)
      - **What Happened Section** (collaborative):
        - Text notes (anyone can add/edit)
        - Photo grid (3 columns)
        - Tap photo to open full screen
      - **Empty States**:
        - Planning: "No activities planned yet"
        - Memories: "No photos captured yet"
  
- [ ] Create `AddPlannedActivityScreen` (organizer only):
  - Name input (required)
  - Type selector (icon chips):
    - 🍽️ Restaurant
    - 🎭 Activity
    - ✈️ Transport
    - 🏨 Accommodation
    - 📦 Other
  - Day selector:
    - Dropdown: "Unassigned", "Day 1", "Day 2", etc.
    - Unassigned goes to General Lists
  - Time input (optional):
    - Text field ("10:00", "morning", "lunch", etc.)
  - Location input (optional)
  - Notes/description textarea
  - Booking reference input (optional)
  - Cost input (optional)
  - Save button
  
- [ ] Create `EditPlannedActivityScreen` (organizer only):
  - Same as add, but pre-populated
  - Can change status (planned → confirmed → completed)
  - Can move to different day
  - Delete button with confirmation
  
- [ ] Implement drag & drop:
  - Drag activity from General Lists to specific day
  - Reorder activities within a day
  - Drag between days
  - Only organizer can drag

---

#### **5.3: Memory Capture UI (Day 4-5)**
**Tasks:**
- [ ] Add memory capture to Itinerary tab:
  - [+ Photo] button on each day
  - Opens photo picker
  - Auto-assigns to that day
  - Can add caption immediately or later
  
- [ ] Create `AddMemoryScreen`:
  - Multi-image picker (max 10 photos/videos)
  - Photo preview grid with reorder handles
  - Remove photo button on each preview
  - Caption input (multiline, max 1000 chars, char counter)
  - Day assignment:
    - Auto-assigned when opened from day section
    - Manual day selector if opened from FAB
  - Location toggle:
    - Auto-capture current location (with permission)
    - Manual entry option
  - Image compression before upload (max 1920px width)
  - Upload progress indicator
  - Success feedback
  
- [ ] Memory interactions in day view:
  - Photo grid (3 columns) shows thumbnails
  - Tap photo → full-screen viewer
  - Long-press photo → options (edit caption, delete, share)
  - Reaction bar below photo grid:
    - Quick reaction buttons (❤️ 😂 😍 👏 🎉)
    - Tap to add/remove your reaction
    - Show count per emoji
  
- [ ] Create `FullScreenMemoryViewer`:
  - Swipeable photo gallery (PageView)
  - Pinch to zoom
  - Photo counter ("2 / 5")
  - Caption overlay at bottom (swipe up to expand)
  - Show location and timestamp
  - Show creator name and avatar
  - Reaction buttons with animated counters
  - Share button (exports photo)
  - Edit/delete buttons (if creator or organizer)
  - Back button with hero animation
  
- [ ] Memory editing (creator only):
  - Edit caption
  - Change day assignment
  - Add/remove photos
  - Update location
  
- [ ] Memory deletion (creator or organizer):
  - Confirmation dialog
  - Delete from Firestore
  - Delete photos from AWS S3 via backend API
  - Remove from UI

---

#### **5.4: Memories Tab - Gallery View (Day 6)**
**Tasks:**
- [ ] Create `MemoriesTab` (new tab in trip details):
  - Pure photo/video gallery view
  - Toggle between Grid and Timeline views
  
- [ ] **Grid View** (default):
  - Masonry grid of all photos (3 columns)
  - Show all memories with photos
  - No day grouping, just all photos
  - Tap photo → full-screen viewer
  - Pinch to zoom out (overview)
  
- [ ] **Timeline View**:
  - Grouped by day
  - Day headers: "Day 1 - June 15"
  - Photo cards for each memory:
    - First photo as hero image
    - Photo count badge ("1/3")
    - Caption preview (truncated)
    - Creator avatar and name
    - Reaction counts
    - Tap to open full screen
  - Chronological order (Day 1 → last day)
  
- [ ] Filtering and sorting:
  - Filter by day (dropdown)
  - Sort by: newest first, oldest first, most reactions
  - Search captions
  
- [ ] Empty state:
  - Illustration
  - "No memories yet - start capturing moments!"
  - [+ Add Photos] button
  
- [ ] Floating action button:
  - Large camera icon
  - Opens `AddMemoryScreen`
  - Day selector (not auto-assigned from this entry)

---

#### **5.5: Firebase & Permissions (Day 7)**
**Tasks:**
- [ ] Firestore structure:
  - `groups/{groupId}/trips/{tripId}/plannedActivities/{activityId}`
  - `groups/{groupId}/trips/{tripId}/memories/{memoryId}`
  - `groups/{groupId}/trips/{tripId}/days/{dayNumber}` (for day notes)
  
- [ ] Firestore security rules:
  - **Planned Activities**:
    - Trip participants can read
    - Only organizer (match trip.organizerId) can create/update/delete
  - **Memories**:
    - Trip participants can read
    - Trip participants can create
    - Creator or organizer can update/delete
  - **Day Notes**:
    - Trip participants can read/write (collaborative)
  
- [ ] AWS S3 Storage:
  - Path: `groups/{groupId}/trips/{tripId}/memories/{memoryId}/{photoId}.jpg`
  - Security: IAM-based access control via backend API
  - Image compression on upload:
    - Resize to max 1920px width
    - JPEG quality 85%
    - Generate thumbnail (400px) for grid view
  
- [ ] Firestore composite indexes:
  - `plannedActivities`: `dayNumber` (asc), `time` (asc)
  - `memories`: `dayNumber` (asc), `createdAt` (desc)
  - `memories`: `createdAt` (desc) for timeline

---

#### **5.6: Testing & Polish (Day 8)**
**Tasks:**
- [ ] Permission checks:
  - Verify organizer-only actions blocked for others
  - Test with multiple users (different roles)
  - Ensure proper error messages
  
- [ ] Photo upload testing:
  - Test with poor connection
  - Test upload cancellation
  - Test large photos (compression)
  - Test batch uploads (10 photos)
  
- [ ] UI polish:
  - Hero animations (photo card → full screen)
  - Loading skeletons for photo grids
  - Pull-to-refresh on both tabs
  - Smooth scrolling and transitions
  - Empty states for all sections
  
- [ ] Edge cases:
  - Photos without captions
  - Activities without times
  - Very long captions (truncation)
  - Many photos in one day (performance)
  
- [ ] Write tests:
  - Repository tests (CRUD operations)
  - Permission logic tests
  - Model serialization tests

---

**Packages to Add:**
- `image_picker: ^1.0.0` - Photo/camera picker
- `photo_view: ^0.14.0` - Pinch-to-zoom viewer
- `cached_network_image: ^3.3.0` - Efficient image caching
- `flutter_image_compress: ^2.1.0` - Image compression
- `reorderable_grid_view: ^2.2.0` - Drag & drop grid

**Estimated Time:** 7-8 days
- Day 1: Data models and repositories
- Day 2-3: Itinerary tab and planning UI
- Day 4-5: Memory capture and interactions
- Day 6: Memories tab gallery view
- Day 7: Firebase setup and permissions
- Day 8: Testing and polish

---

### **SPRINT 6: AI Trip Planning Integration** 🤖
**Note:** AI planning suggestions can now pre-populate the Itinerary (Sprint 5) with planned activities!
**Goal:** AI-powered destination suggestions for organizers  
**Priority:** MEDIUM-HIGH - Helps organizers with secret trip planning  
**Estimated Time:** 4-5 days

#### **Tasks:**
- [ ] Set up Cloud Function for AI:
  - OpenAI API or Google Gemini integration
  - Secure API key management (Cloud Function secrets)
  - Rate limiting and cost controls
  
- [ ] Create AI service layer:
  - Build prompt with group preferences:
    - Budget range, max days
    - Adventurousness level
    - Food focus, urban vs nature
    - Previous destinations (no-repeat if enabled)
  - Parse AI response into structured data
  - Handle AI conversation for refinement
  - Returns destination suggestions with details
  
- [ ] Create `AiPlanningScreen` (organizer-only):
  - Only accessible to current organizer
  - Show group preferences summary card
  - "Generate Suggestions" button
  - Loading animation (AI thinking...)
  - Display 3-5 destination suggestions:
    - Destination card with cover photo
    - Why it fits the group (AI explanation)
    - Estimated budget breakdown
    - Best months to visit
    - Sample 3-day itinerary (collapsible)
  - "Suggest More" button (refine suggestions)
  - "Start Over" button (new search)
  
- [ ] Add AI chat interface:
  - Conversational AI for organizers
  - "Show me more beach destinations"
  - "Something adventurous in Asia under $2000"
  - "Destinations good for food lovers"
  - AI remembers conversation context
  - Private to organizer (not visible to group)
  
- [ ] Integration with trip creation:
  - "Use This Destination" button on each AI suggestion
  - Pre-fills create trip form with:
    - Destination name
    - Country
    - AI-generated description
    - Budget estimate
    - Suggested itinerary (optional to include)
  - Organizer can edit before creating trip
  
- [ ] Replace Planning tab placeholder:
  - For organizers: Show AI planning interface
  - For non-organizers: Show message "The organizer is planning something special! 🎉"
  - Link to group settings to see who organizer is

**Entry Points:**
- Planning screen tab (main access for organizer)
- Group settings "Help Me Plan" button (organizer only)
- Create trip screen "Get AI Suggestions" button

**Privacy Note:**
- AI planning is private to organizer only
- Group members cannot see AI suggestions or chat history
- Maintains secrecy of destination planning

**Entry Points:**
- Planning screen tab (main access for organizer)
- Group settings "Help Me Plan" button (organizer only)
- Add Trip screen "Get AI Suggestions" button

**Integration with Sprint 5:**
- "Use This Destination" button on AI suggestions
- Pre-fills Add Trip form AND creates initial planned activities in Itinerary
- AI can suggest restaurants and activities for each day
- Organizer can edit/reorganize before trip starts

**Privacy Note:**
- AI planning is private to organizer only
- Group members cannot see AI suggestions or chat history
- Maintains secrecy of destination planning

**Estimated Time:** 4-5 days

---

### **SPRINT 7: Organizer Selection System**
**Goal:** Implement core organizer assignment mechanism  
**Priority:** MEDIUM - Unique feature but not blocking  
**Estimated Time:** 2-3 days

#### **Tasks:**
- [ ] Update `GroupModel`:
  - `currentOrganizerId` field
  - `organizerHistory` array: `[{userId, year}]`
  - Helper: `getMemberById(userId)` to get member details
  
- [ ] Create `OrganizerSelectionScreen`:
  - Accessible from group settings (admin only)
  - List all group members in cards:
    - Avatar, name
    - "Last organized: 2024" or "Never organized"
    - Eligible badge (green) or "Organized this year" (grey)
  - Filter buttons:
    - All members
    - Eligible only (haven't organized in current year)
  - Random selection button:
    - "Pick Random Organizer"
    - Animated wheel/roulette (fun!)
    - Only from eligible members
  - Manual selection:
    - Tap any member card
    - Confirm selection dialog
  
- [ ] Implement selection logic in `GroupRepository`:
  - `assignOrganizer(groupId, userId, year)`:
    - Update `currentOrganizerId` in group
    - Add to `organizerHistory`
    - Update member's `yearLastOrganized` field in members array
  - `getEligibleOrganizers(groupId)`:
    - Returns members who haven't organized in current year
    - Admin can override and select anyone
  
- [ ] Update UI to show organizer:
  - **Group card** (selection screen): Organizer badge/crown icon
  - **Group settings**: Current Organizer section with avatar
  - **Trip details**: Organizer info (already done in Sprint 4)
  - **Timeline header**: "Organized by [Name]" subtitle
  
- [ ] Add "Select Organizer" button in group settings:
  - Only visible to admin
  - Navigate to organizer selection screen
  - Show current organizer if exists:
    - "Change Organizer" if already selected
    - "Select First Organizer" if none
  
- [ ] Update trip creation:
  - Auto-assign `currentOrganizerId` from group
  - Show organizer name in create form (read-only)
  - If no organizer selected, show message to select one first
  
- [ ] Add system message to chat (Sprint 8):
  - "{Name} is now the organizer for [Year]! 🎉"

**Estimated Time:** 2-3 days

---

### **SPRINT 8: Chat & Group Communication**
**Goal:** Real-time group messaging  
**Priority:** MEDIUM-HIGH - Enables collaboration  
**Estimated Time:** 3-4 days

#### **Tasks:**
- [ ] Create `ChatMessageModel`:
  - Message ID, group ID
  - Text content (max 2000 chars)
  - Sender ID, name, avatar URL
  - Timestamp
  - Type: `text`, `system`, `image` (image for future)
  - Read by: array of user IDs
  - Reply to: optional message ID (for threading)
  
- [ ] Create `ChatRepository`:
  - `sendMessage()`
  - `streamMessages()` ordered by timestamp ascending
  - `markAsRead()` - add user to readBy array
  - `deleteMessage()` - sender only
  - Real-time Firestore listener
  
- [ ] Create `ChatProvider` with Riverpod
  
- [ ] Replace `ChatScreen` placeholder:
  - **Message List:**
    - Inverted ListView (newest at bottom)
    - Group messages by date (date dividers)
    - Message bubbles:
      - Different color for own vs others (primary vs surface)
      - Show sender avatar for others (left side)
      - Show sender name if not consecutive message from same user
      - Timestamp shown on long-press
      - Read receipts (seen by X members)
    - Auto-scroll to bottom on new message
    - "Scroll to bottom" FAB (when scrolled up)
    - Pull-to-load more (pagination, 50 at a time)
  
  - **Input Area:**
    - Text field at bottom (always visible)
    - Send button (only enabled when text not empty)
    - Character counter when near limit
    - "... is typing" indicator (show when others typing)
  
  - **System Messages:**
    - Different style (centered, grey, italic)
    - Examples:
      - "{Name} joined the group"
      - "{Name} left the group"
      - "{Name} created a trip to {Destination}"
      - "{Name} is now the organizer!"
    - Generated automatically on key events
  
- [ ] Implement typing indicator:
  - Separate Firestore document: `groups/{groupId}/typingStatus`
  - Map of `{userId: timestamp}`
  - Update on text change (debounced)
  - Show "Alice, Bob are typing..."
  
- [ ] Add features:
  - Long-press message for options:
    - Copy text
    - Delete (if sender)
    - Reply (future)
  - Pull-to-reply gesture (future)
  - Image messages (future - Sprint 16)
  
- [ ] Firestore setup:
  - Path: `groups/{groupId}/chat/{messageId}`
  - Security rules: group members can read/create, sender can delete
  - Composite index: `timestamp` (ascending)
  - Typing status rules: members can read/write

**Estimated Time:** 3-4 days

---

### **SPRINT 9: Map & Destination Visualization**
**Goal:** Visual representation of trips  
**Priority:** MEDIUM - Nice to have, enhances UX  
**Estimated Time:** 3-4 days

#### **Tasks:**
- [ ] Choose and install map package:
  - `google_maps_flutter: ^2.5.0` (recommended)
  - Configure API keys:
    - Android: `android/app/src/main/AndroidManifest.xml`
    - iOS: `ios/Runner/AppDelegate.swift`
  - Get Google Maps API key from console
  
- [ ] Replace `MapScreen` placeholder:
  - Full-screen map view
  - Initial camera position: center of all trip locations
  - Zoom level to show all markers
  
- [ ] Show markers for all group's trips:
  - Custom marker icons:
    - Different colors for status:
      - Blue pin: planning
      - Green pin: ongoing
      - Grey pin: completed
      - Red pin: cancelled
    - Small organizer badge on marker
  - Marker clustering (if many trips in same area)
  
- [ ] Marker interactions:
  - Tap marker → show info window:
    - Trip name
    - Dates
    - Participant count
  - Tap info window → navigate to trip details
  - Animated camera move to marker
  
- [ ] Add map preview to trip details:
  - Small embedded map in Overview tab
  - Shows single marker for trip destination
  - Tap to open full-screen map focused on that trip
  - Show memories with location as markers (Sprint 16)
  
- [ ] Geocoding for trip creation:
  - Use Google Geocoding API
  - Convert destination name to coordinates
  - Store lat/lng in trip model
  - Handle geocoding errors gracefully
  - Show map preview during creation (optional)
  
- [ ] Add map controls:
  - Zoom in/out buttons
  - My location button
  - Map type selector (normal, satellite, hybrid)
  - Legend for marker colors
  
- [ ] Map filtering:
  - Filter by year
  - Filter by status
  - Search bar for destinations

**Estimated Time:** 3-4 days

---

### **SPRINT 10: Budget & Expense Tracking**
**Goal:** Track and split trip expenses  
**Priority:** HIGH - Practical feature for active trips  
**Estimated Time:** 4-5 days

#### **Tasks:**
- [ ] Create `ExpenseModel`:
  - Expense ID, trip ID
  - Description (e.g., "Hotel for 3 nights")
  - Amount (number), currency (default USD)
  - Paid by: user ID
  - Split among: array of user IDs (equal split for MVP)
  - Split type: `equal`, `custom` (custom for future)
  - Category: `transport`, `accommodation`, `food`, `activities`, `other`
  - Date (date paid)
  - Receipt photo URL (optional)
  - Created timestamp
  
- [ ] Create `ExpenseRepository`:
  - `addExpense()`
  - `streamExpensesForTrip()` ordered by date descending
  - `updateExpense()`
  - `deleteExpense()` (creator only)
  - `calculateTotals()` - total spent, per person breakdown
  - `calculateSettlements()` - who owes whom (minimize transactions)
  
- [ ] Create `ExpenseProvider` with Riverpod
  
- [ ] Update Expenses tab in `TripDetailsScreen`:
  - Remove placeholder
  - **Budget Summary Card** (at top):
    - Total budget: participants × budget per person
    - Total spent
    - Remaining/over budget
    - Progress bar (visual indicator)
    - Color-coded:
      - Green: under budget (< 90%)
      - Yellow: near budget (90-100%)
      - Red: over budget (> 100%)
  
  - **Expense List:**
    - Expense cards showing:
      - Description
      - Amount with currency ($150.00)
      - Category icon (plane, bed, fork, ticket, etc.)
      - Paid by (avatar + name)
      - Split count ("Split among 4 people")
      - Per-person amount ("$37.50 each")
      - Date
    - Sort: most recent first
    - Floating "Add Expense" button
  
  - **Settlement Section** (collapsible):
    - "Who Owes What" heading
    - Per-person breakdown:
      - Total paid by each person
      - Total they owe (their share)
      - Net: paid - owed
    - Simplified settlement transactions:
      - "Alice owes Bob $50"
      - "Charlie owes Bob $25"
      - Minimized number of transactions
    - "Settle Up" buttons (future: payment integration)
  
- [ ] Create `AddExpenseScreen`:
  - Description input
  - Amount input with currency symbol
  - Category selector:
    - Icon chips: ✈️ Transport, 🏨 Accommodation, 🍽️ Food, 🎭 Activities, 📦 Other
    - Selected category highlighted
  - Date picker (defaults to today)
  - "Paid by" selector:
    - List of trip participants
    - Default to current user
  - Split selector:
    - "Split equally among all" (default, all participants)
    - "Split among selected people" (checkboxes of participants)
  - Calculate and show per-person amount
  - Optional: Camera button for receipt photo
  - Add button with validation
  
- [ ] Settlement calculation algorithm:
  - Calculate net for each person (paid - owed)
  - Positive = owed money, negative = owes money
  - Minimize transactions (greedy algorithm):
    - Match largest creditor with largest debtor
    - Continue until settled
  
- [ ] Firestore setup:
  - Path: `groups/{groupId}/trips/{tripId}/expenses/{expenseId}`
  - Security rules: trip participants can read/create, creator can update/delete
  - Index: `date` (descending)

**Estimated Time:** 4-5 days

---

### **SPRINT 11: Profile & Settings**
**Goal:** User profile and app preferences  
**Priority:** MEDIUM - Nice to have  
**Estimated Time:** 2-3 days

#### **Tasks:**
- [ ] Update `UserModel`:
  - User ID
  - Display name
  - Email (from auth)
  - Bio (max 200 chars)
  - Profile picture URL
  - Preferences:
    - Notifications enabled
    - Theme (light/dark/system)
  - Statistics:
    - Trips attended count
    - Times organized count
    - Groups joined count
  - Created timestamp
  
- [ ] Create `UserRepository`:
  - `getUserProfile()`
  - `updateUserProfile()`
  - `uploadProfilePicture()` - to AWS S3 via backend API
  - `updateStatistics()` - triggered by trip/group events
  
- [ ] Create `UserProvider` with Riverpod
  
- [ ] Replace `ProfileScreen` placeholder:
  - **Profile Header:**
    - Large profile picture (tap to change)
    - Edit button → photo picker (camera/gallery)
    - Display name (tap to edit inline)
    - Email (read-only)
    - Bio (tap to edit)
  
  - **Statistics Section:**
    - Cards showing:
      - "🏖️ Trips Attended: 12"
      - "✈️ Times Organized: 3"
      - "👥 Groups Joined: 2"
  
  - **Settings Section** (list tiles):
    - Notifications (toggle switch)
    - Theme (Light/Dark/System - radio buttons)
    - Account Settings (navigate to account screen)
    - Privacy Policy (web view)
    - Terms of Service (web view)
    - About (app version, credits)
    - Logout (confirmation dialog)
  
- [ ] Create `EditProfileScreen`:
  - Display name input
  - Bio textarea (max 200 chars, char counter)
  - Save button
  - Cancel button
  
- [ ] Implement profile picture upload:
  - AWS S3 path: `users/{userId}/profile.jpg`
  - Image picker (camera or gallery)
  - Crop image to square
  - Compress image
  - Upload with progress indicator
  - Update Firestore user document
  - Update Firebase Auth profile photo
  
- [ ] Settings implementation:
  - **Notifications**:
    - Toggle to enable/disable all
    - Store preference in user profile
  - **Theme**:
    - Light, Dark, System options
    - Use Riverpod StateProvider
    - Persist in SharedPreferences
    - Apply immediately
  - **Account**:
    - Change password (re-auth required)
    - Delete account (confirmation + password)
  
- [ ] Calculate and display statistics:
  - Count trips where user is in participantIds
  - Count trips where user is organizerId
  - Count groups where user in memberIds
  - Update in real-time or on profile load

**Estimated Time:** 2-3 days

---

### **SPRINT 12: Notifications & Engagement**
**Goal:** Push notifications to keep users engaged  
**Priority:** MEDIUM - Increases engagement  
**Estimated Time:** 3-4 days

#### **Tasks:**
- [ ] Firebase Cloud Messaging (FCM) setup:
  - Configure for Android:
    - Add `google-services.json`
    - Add dependencies to `build.gradle`
  - Configure for iOS:
    - APNs setup in Firebase Console
    - Add capabilities in Xcode
    - Upload APNs auth key
  - Request notification permissions on app start
  
- [ ] Create `NotificationService`:
  - Get FCM token on app start
  - Store token in Firestore user document
  - Handle token refresh
  - Listen for foreground messages
  - Handle background messages
  - Navigate to relevant screen on tap
  
- [ ] Implement notification triggers (Cloud Functions):
  Write Cloud Functions for:
  
  - **New Chat Message**:
    - Trigger: new document in `groups/{groupId}/chat/{messageId}`
    - Send to: all group members except sender
    - Payload: sender name, message text, group ID
    - Navigate to: Chat screen
  
  - **New Memory Added**:
    - Trigger: new document in `groups/{groupId}/trips/{tripId}/memories/{memoryId}`
    - Send to: all trip participants except creator
    - Payload: creator name, trip name, memory type
    - Navigate to: Trip details (Memories tab)
  
  - **Trip Starting Soon**:
    - Trigger: scheduled function (daily check)
    - Send to: all trip participants
    - When: 7 days before, 1 day before
    - Payload: trip name, start date, organizer
    - Navigate to: Trip details
  
  - **New Proposal**:
    - Trigger: new document in `groups/{groupId}/proposals/{proposalId}`
    - Send to: all group members except creator
    - Payload: destination, creator name
    - Navigate to: Proposals screen
  
  - **Assigned as Organizer**:
    - Trigger: `currentOrganizerId` field updated in group
    - Send to: newly assigned organizer
    - Payload: group name, year
    - Navigate to: Group timeline
  
  - **Trip Revealed** (when organizer reveals destination):
    - Trigger: Trip status changed or specific reveal action
    - Send to: all trip participants
    - Payload: destination name, organizer name
    - Navigate to: Trip details
  
- [ ] In-app notification center:
  - Bell icon in app bar (main scaffold)
  - Badge count for unread notifications
  - Notification list screen:
    - Grouped by date (Today, Yesterday, This Week, etc.)
    - Notification cards showing:
      - Icon based on type
      - Title and body
      - Timestamp ("2 hours ago")
      - Tap to navigate
    - Mark as read on tap
    - "Mark all as read" button
  - Store notifications in Firestore for persistence
  
- [ ] Notification preferences:
  - In Profile > Settings > Notifications:
    - Enable/disable push notifications (master toggle)
    - New message notifications (toggle)
    - New memory notifications (toggle)
    - Trip reminders (toggle)
    - Trip revealed notifications (toggle)
  - Store in user profile
  - Cloud Functions check preferences before sending
  
- [ ] Firestore for notification history:
  - Path: `users/{userId}/notifications/{notificationId}`
  - Fields: type, title, body, data (for navigation), read, timestamp
  - Security rules: user can only read/write their own
  - Index: `timestamp` (descending)

**Estimated Time:** 3-4 days

---

### **SPRINT 13: Memory Enhancements & Export**
**Goal:** Export memories as trip books and slideshows  
**Priority:** LOW - Nice enhancement  
**Estimated Time:** 3-4 days

**Note:** This sprint builds on Sprint 5's memory system to add export functionality.

#### **Tasks:**
- [ ] Trip memory summary:
  - "Trip Highlights" auto-generated card:
    - Most-reacted photo memory
    - Most-reacted note memory
    - Total memory count
    - Total photo count
    - Contributor leaderboard (who added most)
  
- [ ] PDF trip book generator:
  - Use `pdf` package for Flutter
  - Generate beautiful PDF:
    - Cover page with trip name, destination, dates
    - Group photo (if set)
    - Table of contents
    - Chronological photo layout (2-4 per page)
    - Include captions below photos
    - Page numbers
    - Clean, printable design
  - "Export as PDF" button in Memories tab
  - Download PDF to device
  - Share PDF
  
- [ ] Slideshow mode:
  - "Play Slideshow" button in Memories tab
  - Full-screen photo slideshow:
    - Auto-play through all photos (3 seconds each)
    - Transition animations (fade, slide)
    - Show captions overlay
    - Background music (user-selected from device)
    - Pause/play button
    - Skip forward/backward
    - Exit button
  
- [ ] Social media export optimization:
  - Select multiple memories
  - "Export for Instagram" option:
    - Creates carousel format (1080x1080)
    - Optimizes image sizes
    - Includes app watermark (optional)
    - Exports to gallery
  - "Export for Stories" option (1080x1920)
  
- [ ] Bulk memory download:
  - "Download All Photos" button
  - Creates zip file of all trip photos
  - Includes metadata file (JSON):
    - Captions
    - Dates
    - Creators
    - Reactions
  - Download to device
  - Share zip file

**Packages to Add:**
- `pdf: ^3.10.0` - PDF generation
- `printing: ^5.11.0` - PDF preview and saving
- `archive: ^3.4.0` - Create zip files

**Estimated Time:** 3-4 days

---

### **SPRINT 14: Polish & Performance Optimization**
**Goal:** Optimize app performance and UX  
**Priority:** HIGH - Critical before launch  
**Estimated Time:** 4-5 days

#### **Day 1: Performance Optimization**
**Tasks:**
- [ ] Implement pagination everywhere:
  - Timeline trips (load 20 at a time)
  - Memories feed (load 20 at a time)
  - Chat messages (load 50 at a time)
  - Expenses list
  - Proposals list
- [ ] Image optimization:
  - Implement caching strategy (use `cached_network_image`)
  - Lazy loading for images (ListView.builder)
  - Thumbnail generation for memory photos
  - Progressive image loading (low-res → high-res)
- [ ] Reduce Firestore reads:
  - Implement local caching (Hive or SharedPreferences)
  - Cache user profiles
  - Cache group data
  - Only refresh when needed
- [ ] Optimize widget rebuilds:
  - Use `const` constructors everywhere possible
  - Profile with Flutter DevTools
  - Identify and fix unnecessary rebuilds
  - Use `Selector` for granular Riverpod updates

#### **Day 2: UI/UX Polish**
**Tasks:**
- [ ] Add hero animations:
  - Trip card → Trip details
  - Memory card → Full-screen viewer
  - Profile photo → Edit profile
- [ ] Smooth page transitions:
  - Custom route transitions
  - Fade/slide animations
- [ ] Loading states:
  - Skeleton screens for lists:
    - Trip cards
    - Memory cards
    - Chat messages
  - Shimmer effect
  - Replace CircularProgressIndicator with skeletons
- [ ] Better empty states:
  - Custom illustrations (use Undraw or similar)
  - Friendly copy
  - Clear call-to-action buttons
- [ ] Polish interactions:
  - Haptic feedback on key actions:
    - Button taps
    - Reactions
    - Like/vote
  - Pull-to-refresh everywhere appropriate
  - Swipe gestures where sensible
- [ ] Consistent spacing and typography:
  - Audit all screens
  - Apply theme consistently
  - Fix any visual inconsistencies

#### **Day 3: Error Handling & Offline**
**Tasks:**
- [ ] Improve error messages:
  - User-friendly error text (no technical jargon)
  - Actionable suggestions
  - Retry buttons where appropriate
- [ ] Implement retry mechanisms:
  - Auto-retry failed network requests (exponential backoff)
  - Manual retry buttons in error states
- [ ] Offline mode indicators:
  - Banner at top when offline
  - Grey out actions that require internet
  - Queue actions for when back online (e.g., sending messages)
- [ ] Graceful degradation:
  - Show cached data when offline
  - Allow viewing (but not editing) when offline
  - Sync changes when back online

#### **Day 4: Accessibility**
**Tasks:**
- [ ] Screen reader support:
  - Add Semantics widgets everywhere
  - Label all interactive elements
  - Proper focus order
- [ ] Color contrast:
  - Audit all text on backgrounds
  - Ensure WCAG AA compliance (4.5:1 for text)
  - Fix any contrast issues
- [ ] Text scaling:
  - Test with large text sizes
  - Ensure layouts don't break
  - Use relative sizing (em/rem equivalent)
- [ ] Touch targets:
  - Minimum 48x48dp for all interactive elements
  - Add padding where needed
- [ ] Keyboard navigation:
  - Ensure all actions accessible via keyboard (for desktop)
  - Proper tab order

#### **Day 5: Testing & Fixes**
**Tasks:**
- [ ] Write unit tests:
  - Repository tests (mock Firestore)
  - Provider tests (mock repositories)
  - Model tests (serialization)
  - Aim for >70% coverage on business logic
- [ ] Write widget tests:
  - Key screens (login, create trip, etc.)
  - Custom widgets (trip card, memory card)
- [ ] Write integration tests:
  - Critical user flows:
    - Sign up → Create group → Create trip
    - Join group → View trips → Add memory
    - Create proposal → Vote → Accept
- [ ] Fix all analyzer warnings:
  - Run `flutter analyze`
  - Fix all warnings and hints
  - Enable stricter lint rules
- [ ] Run performance profiling:
  - Use Flutter DevTools
  - Check for memory leaks
  - Optimize expensive operations

**Estimated Time:** 4-5 days

---

### **SPRINT 15: Launch Preparation**
**Goal:** Prepare for production release  
**Priority:** CRITICAL - Required for launch  
**Estimated Time:** 5-7 days

#### **Day 1-2: Production Firebase Setup**
**Tasks:**
- [ ] Create production Firebase project:
  - Separate from dev project
  - Configure Android app
  - Configure iOS app
- [ ] Set up security rules:
  - Copy and review all Firestore rules
  - Test rules in production project
  - Enable audit logging
- [ ] Configure Firestore:
  - Set up backups (daily)
  - Create all composite indexes
  - Configure database location (closest to users)
- [ ] Configure AWS S3:
  - Set up bucket with proper permissions
  - Configure CORS for web access
  - Set up backend API for secure access
- [ ] Set up Firebase Authentication:
  - Enable email/password provider
  - Configure authorized domains
  - Set up email templates (verification, password reset)

#### **Day 3: App Configuration**
**Tasks:**
- [ ] Environment configuration:
  - Set up dev/prod environments
  - Environment variables for API keys
  - Separate Firebase configs for dev/prod
- [ ] App signing:
  - Generate Android keystore
  - Configure signing in `build.gradle`
  - Set up iOS certificates and provisioning profiles
- [ ] App configuration:
  - Update app name (production)
  - Update bundle IDs:
    - Android: `com.secretholiday.app`
    - iOS: `com.secretholiday.SecretHolidayApp`
  - Configure deep links:
    - `/join-group?code={code}`
    - `/trip/{tripId}`

#### **Day 4: Analytics & Monitoring**
**Tasks:**
- [ ] Firebase Analytics:
  - Initialize Firebase Analytics
  - Log key events:
    - sign_up, login
    - create_group, join_group
    - create_trip, view_trip
    - add_memory, react_to_memory
    - send_message
  - Set user properties (premium status, etc.)
- [ ] Firebase Crashlytics:
  - Initialize Crashlytics
  - Test crash reporting
  - Set up alerts for crash rate thresholds
- [ ] Performance monitoring:
  - Add custom traces for key flows
  - Monitor app startup time
  - Monitor screen rendering time
- [ ] Define key metrics to track:
  - Daily active users (DAU)
  - Monthly active users (MAU)
  - Trip creation rate
  - Memory creation rate
  - Message send rate
  - Retention (D1, D7, D30)

#### **Day 5-6: Store Preparation**
**Tasks:**
- [ ] App icon:
  - Design 1024x1024 icon
  - Generate all required sizes (Android/iOS)
  - Use `flutter_launcher_icons` package
- [ ] Screenshots:
  - Capture 5-8 screenshots per platform
  - Required sizes:
    - iOS: 6.5", 5.5" (iPhone)
    - Android: 1080x1920, 1440x2960
  - Show key features:
    - Group creation
    - Trip timeline
    - Memory capture
    - Chat
    - Expense tracking
  - Add captions/annotations
- [ ] Feature graphic (Android):
  - 1024x500 image
  - Showcase app name and key visual
- [ ] App description:
  - Short description (80 chars)
  - Long description (4000 chars)
  - Highlight key features:
    - Secret destinations
    - Memory capture
    - Expense splitting
    - Group chat
  - Include keywords for ASO
- [ ] Privacy policy:
  - Create privacy policy page
  - Host on website or Firebase Hosting
  - Cover: data collection, usage, Firebase/Google services
- [ ] Terms of service:
  - Create ToS document
  - Host online
  - Cover: user conduct, liability, account deletion
- [ ] Support:
  - Set up support email: support@secretholiday.app
  - Create support page with FAQs
  - Set up auto-reply

#### **Day 7: Beta Testing & Launch**
**Tasks:**
- [ ] TestFlight setup (iOS):
  - Upload build to App Store Connect
  - Add beta testers (emails)
  - Create testing instructions
- [ ] Internal testing (Android):
  - Upload AAB to Play Console
  - Create internal testing track
  - Add beta testers
- [ ] Recruit beta testers:
  - Friends, family, early users
  - Ask for feedback on:
    - Bugs/crashes
    - UX issues
    - Feature requests
  - Collect feedback (form or chat)
- [ ] Address feedback:
  - Fix critical bugs
  - Polish UX issues
  - Prioritize feature requests
- [ ] Final testing:
  - Test on multiple devices
  - Test all critical flows
  - Test edge cases
  - Test with different network conditions
- [ ] Submit to stores:
  - **Apple App Store:**
    - Complete App Store Connect listing
    - Submit for review
    - Respond to any review feedback
    - Estimated: 1-2 days for review
  - **Google Play Store:**
    - Complete Play Console listing
    - Submit to production track
    - Estimated: few hours to 1 day for review
- [ ] Post-launch:
  - Monitor crash reports
  - Monitor analytics
  - Respond to user reviews
  - Plan first update based on feedback

**Estimated Time:** 5-7 days

---

## Timeline Summary

### Total Development Time: ~12-16 weeks (3-4 months)

**Completed:**
- ✅ Sprint 1: Authentication (3-4 days)
- ✅ Sprint 2: Groups (4-5 days) 
- ✅ Sprint 3: Navigation (2-3 days)
- ✅ Sprint 4: Trips (3-4 days)

**Remaining:**
- Sprint 5: Planning & Memories MEGA SPRINT (7-8 days) ⭐ NEXT - Core Feature
- Sprint 6: AI Planning (4-5 days)
- Sprint 7: Organizer Selection (2-3 days)
- Sprint 8: Chat (3-4 days)
- Sprint 9: Map (3-4 days)
- Sprint 10: Expenses (4-5 days)
- Sprint 11: Profile (2-3 days)
- Sprint 12: Notifications (3-4 days)
- Sprint 13: Memory Export (3-4 days)
- Sprint 14: Polish (4-5 days)
- Sprint 15: Launch (5-7 days)

---

## Dependencies Between Sprints

**Must Complete First:**
- Sprint 4 (Trips) → Sprint 5 (Planning & Memories) ✅
- Sprint 5 (Planning & Memories) → Sprint 13 (Memory Export)
- Sprint 2 (Groups) → Sprint 6 (AI), Sprint 7 (Organizer Selection) ✅
- Sprint 4 (Trips) → Sprint 9 (Map), Sprint 10 (Expenses) ✅
- Sprint 8 (Chat) → Sprint 12 (Notifications)
- Everything → Sprint 14 (Polish) → Sprint 15 (Launch)

**Can Do In Parallel:**
- Sprint 6 (AI) + Sprint 7 (Organizer Selection) (both about planning)
- Sprint 8 (Chat) + Sprint 9 (Map) (independent features)
- Sprint 10 (Expenses) + Sprint 11 (Profile) (independent)
- Sprint 12 (Notifications) + Sprint 13 (Memory Export) (independent)

---

## Tech Stack Summary

**Frontend:**
- Flutter 3.38.1 / Dart 3.10.0
- Riverpod 3.0.3 (state management)
- go_router 17.0.0 (navigation)
- json_serializable (models)

**Backend:**
- Firebase Authentication
- Firebase Firestore (database)
- AWS S3 (photo storage via backend API)
- Firebase Cloud Functions (AI, notifications)
- Firebase Cloud Messaging (push notifications)

**Key Packages:**
- `image_picker` - Photo/camera
- `google_maps_flutter` - Maps
- `cached_network_image` - Image caching
- `flutter_image_compress` - Image optimization
- `pdf` & `printing` - PDF generation
- `photo_view` - Photo viewer
- `reorderable_grid_view` - Drag & drop for itinerary
- `intl` - Date formatting

---

## Notes

- Each sprint includes implementation, testing, and documentation
- Estimated times are for one developer working full-time
- Adjust sprint order based on team size and priorities
- **Sprint 5 is now a MEGA SPRINT** combining planning and memories - this is the core user experience
- **Permission model**: Organizers control planning, everyone captures memories
- Consider parallel development if multiple developers available
- Budget extra time for unexpected bugs and edge cases
- Plan for regular code reviews and refactoring sessions
- Keep documentation up to date as features are built

---

**Last Updated:** November 21, 2025  
**Status:** Sprint 4 Complete, Sprint 5 (Planning & Memories Mega Sprint) Ready to Start

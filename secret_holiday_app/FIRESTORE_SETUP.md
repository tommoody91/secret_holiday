# Firestore Setup Instructions

## Required Composite Index

For the group queries to work efficiently, you need to create a composite index in Firestore.

### Quick Setup (Recommended)
1. Run the app
2. Navigate to a screen that loads groups (e.g., Home screen after login)
3. Check the console for a Firestore error with a link starting with:
   ```
   https://console.firebase.google.com/v1/r/project/secret-holiday/firestore/indexes?create_composite=...
   ```
4. Click the link - it will auto-configure the index
5. Wait ~2 minutes for the index to build

### Manual Setup
If the link doesn't work:

1. Go to: https://console.firebase.google.com/project/secret-holiday/firestore/indexes
2. Click **Create Index**
3. Configure:
   - **Collection ID**: `groups`
   - **Fields**:
     - Field: `memberIds`, Mode: `Arrays`
     - Field: `updatedAt`, Mode: `Descending`
   - **Query scopes**: Collection
4. Click **Create Index**
5. Wait for index to build (status will show as "Building" then "Enabled")

## Why This Index is Needed

The app queries groups with:
```dart
_groupsCollection
  .where('memberIds', arrayContains: user.uid)
  .orderBy('updatedAt', descending: true)
```

Firestore requires a composite index for queries that:
- Filter on an array field (`memberIds`)
- Sort by another field (`updatedAt`)

## Verification

Once the index is created:
1. Hot restart the app
2. Log in
3. You should see "No Groups Yet" or your list of groups without errors
4. Check logs - no "FAILED_PRECONDITION" errors

## Index Status

Check status at: https://console.firebase.google.com/project/secret-holiday/firestore/indexes

Status indicators:
- 🔨 **Building**: Index is being created (wait a few minutes)
- ✅ **Enabled**: Index is ready to use
- ❌ **Error**: Check configuration and retry

---

## Trips Collection Composite Index

For trip queries to work efficiently, you need another composite index.

### Quick Setup (Recommended)
1. Run the app and create a group
2. Navigate to the Timeline screen for that group
3. Check the console for a Firestore error with an auto-configuration link
4. Click the link and wait for the index to build

### Manual Setup

1. Go to: https://console.firebase.google.com/project/secret-holiday/firestore/indexes
2. Click **Create Index**
3. Configure:
   - **Collection ID**: `groups/{groupId}/trips` (use `Collection group` scope)
   - **Fields**:
     - Field: `startDate`, Mode: `Descending`
   - **Query scopes**: Collection group
4. Click **Create Index**
5. Wait for index to build

### Why This Index is Needed

The app queries trips with:
```dart
_getTripsCollection(groupId)
  .orderBy('startDate', descending: true)
```

This allows sorting trips by their start date to show the most recent trips first.

---

## Firestore Security Rules

### Trips Collection Rules

Add these rules to your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isGroupMember(groupId) {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/groups/$(groupId)).data.memberIds.hasAny([request.auth.uid]);
    }
    
    function isTripOrganizer(groupId, tripId) {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/groups/$(groupId)/trips/$(tripId)).data.organizerId == request.auth.uid;
    }
    
    function isGroupAdmin(groupId) {
      let group = get(/databases/$(database)/documents/groups/$(groupId)).data;
      let members = group.members;
      return members.hasAny([{
        'userId': request.auth.uid,
        'role': 'admin'
      }]);
    }
    
    // Groups collection
    match /groups/{groupId} {
      allow read: if isGroupMember(groupId);
      allow create: if isAuthenticated();
      allow update, delete: if isGroupAdmin(groupId);
      
      // Trips subcollection
      match /trips/{tripId} {
        // Any group member can read trips
        allow read: if isGroupMember(groupId);
        
        // Any group member can create trips
        allow create: if isGroupMember(groupId);
        
        // Only the trip organizer or group admin can update/delete
        allow update, delete: if isTripOrganizer(groupId, tripId) || isGroupAdmin(groupId);
      }
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }
  }
}
```

### Applying Security Rules

1. Go to: https://console.firebase.google.com/project/secret-holiday/firestore/rules
2. Replace the content with the rules above
3. Click **Publish**
4. Test that:
   - ✅ Group members can view trips
   - ✅ Group members can create trips
   - ✅ Trip organizers can edit their trips
   - ✅ Group admins can edit any trip
   - ❌ Non-members cannot access trips
   - ❌ Regular members cannot edit others' trips

### Security Rules Explanation

- **Read Access**: Any group member can view all trips in their group
- **Create Access**: Any group member can create new trips
- **Update/Delete Access**: Only the trip organizer or group admins can modify/delete trips
- **Participant Management**: Trip organizers control the participant list
- **Status Changes**: Organizers can manually change trip status (e.g., cancel a trip)

---

## Testing Your Setup

### Test Groups
1. Create a group as User A
2. Invite User B via invite code
3. Verify both users see the group

### Test Trips
1. User A creates a trip (should succeed)
2. User B views the trip (should succeed)
3. User B tries to edit the trip (should fail - only organizer/admin)
4. User A edits the trip (should succeed)
5. User A deletes the trip (should succeed)

### Test Indexes
Check in Firebase Console that both indexes are **Enabled**:
1. `groups` collection: `memberIds` (array) + `updatedAt` (desc)
2. `trips` collection group: `startDate` (desc)

---

## Common Issues

### "FAILED_PRECONDITION" Error
- **Cause**: Missing composite index
- **Fix**: Click the error link to auto-create, or create manually

### "PERMISSION_DENIED" Error
- **Cause**: Security rules not configured
- **Fix**: Apply the security rules above

### Trips Not Loading
- **Cause**: Missing trips index or incorrect query
- **Fix**: Create the trips composite index

### Cannot Edit Trip
- **Cause**: User is not organizer or admin
- **Expected**: Only organizers and admins can edit trips

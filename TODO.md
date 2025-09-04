# TODO: Modify Empty Shift Table Display for Free Users

## Tasks
- [ ] Add helper method `isCurrentOrPreviousWeek()` to check if the current week is current or previous week
- [ ] Update the condition in `build()` method to only show empty shift message and button for free users on current/previous weeks
- [ ] Test the behavior for free users on different weeks

## Information Gathered
- The empty shift table message and "Add Employee" button are shown when `_employees.isEmpty`
- Current logic shows this for all users regardless of week
- For free users, we need to restrict this to current and previous weeks only
- Existing `isFutureWeek()` method can be used as reference for week calculations

## Plan
1. Add `isCurrentOrPreviousWeek()` method inside `_HomeScreenState` class
2. Modify the ternary condition in `build()` method from:
   ```dart
   _employees.isEmpty ? ... : ...
   ```
   to:
   ```dart
   (_employees.isEmpty && (!isFreeUser || isCurrentOrPreviousWeek())) ? ... : ...
   ```
3. This ensures free users only see the message/button for current and previous weeks

## Followup Steps
- Verify the implementation works correctly
- Test with free user account on current, previous, and future weeks
- Ensure pro users still see the message/button on all weeks

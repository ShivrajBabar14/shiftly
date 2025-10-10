# TODO: Fix Subscription Success Dialog and GlobalKey Issues

## Tasks
- [ ] Edit lib/screens/subscription.dart: Modify _listenToPurchaseUpdated to show SuccessDialog only on PurchaseStatus.purchased, not restored. Add SharedPreferences flag 'subscription_success_shown' to prevent re-showing.
- [ ] Edit lib/screens/home_screen.dart: Remove static GlobalKey assignment in HomeScreen constructor to fix duplicate key errors.
- [ ] Test: Run flutter run, simulate new purchase (dialog shows once), uninstall/reinstall (restore enables pro features without dialog).
- [ ] Verify: Check logs for no duplicate key errors, pro features work (unlimited employees, attendance marking, backup).

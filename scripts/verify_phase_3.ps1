Write-Host "Verifying Phase 3: UI Notification System..."
Set-Location am_common
Write-Host "Running tests in am_common..."
flutter test test/features/notifications/notification_provider_test.dart
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Phase 3 Verification Passed!"
    exit 0
}
else {
    Write-Host "❌ Phase 3 Verification Failed!"
    exit 1
}

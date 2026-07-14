# Run AM main app on http://localhost:9000
Set-Location "$PSScriptRoot\..\am_app"
flutter run -d chrome `
  --web-port=9000 `
  --no-web-resources-cdn `
  --web-launch-url=http://localhost:9000/login `
  --dart-define=AM_ENV=local

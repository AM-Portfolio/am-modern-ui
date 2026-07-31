import fs from 'fs';
const content = fs.readFileSync('C:/Users/adhik/Downloads/Asrax/AM/am-modern-ui/am_app/lib/core/router/app_router.dart', 'utf8');
const lines = content.split('\n');
lines.forEach((line, index) => {
  if (line.includes('DeleteAccountPage') || line.includes('delete-account')) {
    console.log(`${index + 1}: ${line.trim()}`);
  }
});

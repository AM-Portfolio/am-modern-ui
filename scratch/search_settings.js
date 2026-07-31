import fs from 'fs';
import path from 'path';

const filePath = 'C:/Users/adhik/Downloads/Asrax/AM/am-modern-ui/am_user_ui/lib/features/profile/presentation/pages/profile_settings_page.dart';
const content = fs.readFileSync(filePath, 'utf8');
const lines = content.split('\n');

console.log(`Total lines: ${lines.length}`);
lines.forEach((line, index) => {
  if (line.toLowerCase().includes('delete') && line.toLowerCase().includes('account')) {
    console.log(`${index + 1}: ${line.trim()}`);
  }
});

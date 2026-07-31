import fs from 'fs';
import path from 'path';

function walkDir(dir, callback) {
  fs.readdirSync(dir).forEach(f => {
    let dirPath = path.join(dir, f);
    let isDirectory = fs.statSync(dirPath).isDirectory();
    if (isDirectory) {
      if (f !== 'node_modules' && f !== '.git' && f !== '.dart_tool' && f !== 'build') {
        walkDir(dirPath, callback);
      }
    } else {
      callback(dirPath);
    }
  });
}

const root = 'C:/Users/adhik/Downloads/Asrax/AM/am-modern-ui';
walkDir(root, (filePath) => {
  if (filePath.endsWith('.dart') && !filePath.includes('search_settings.js') && !filePath.includes('search_gb_flutter.js')) {
    let content = fs.readFileSync(filePath, 'utf8');
    if (content.includes('DeleteAccountPage')) {
      console.log(`${filePath}`);
    }
  }
});

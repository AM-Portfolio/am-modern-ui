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

const root = 'C:/Users/adhik/Downloads/Asrax/AM/am-modern-ui/am_user_ui';
let needsCodegen = false;
walkDir(root, (filePath) => {
  if (filePath.endsWith('.dart')) {
    let content = fs.readFileSync(filePath, 'utf8');
    if (content.includes('part \'') && (content.includes('.g.dart') || content.includes('.freezed.dart'))) {
      console.log(`Found generated part file reference in: ${filePath}`);
      needsCodegen = true;
    }
  }
});

if (needsCodegen) {
  console.log("am_user_ui DOES need code generation!");
} else {
  console.log("am_user_ui does NOT need code generation!");
}

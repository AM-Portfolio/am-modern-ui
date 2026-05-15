import os, re, glob

directory = r'f:\am-repos\am-repos\am-modern-ui\am_analysis\sdk\lib\model'
pattern = re.compile(r"num\.parse\('\$\{json\[r'([^']+)'\]\}'\)")

files = glob.glob(os.path.join(directory, '*.dart'))
count = 0

for file_path in files:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = pattern.sub(r"json[r'\1'] == null ? null : (json[r'\1'] is num ? json[r'\1'] : num.tryParse('${json[r'\1']}'))", content)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'Patched {os.path.basename(file_path)}')
        count += 1

print(f'Done patching {count} files')

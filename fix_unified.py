import re

with open('.github/workflows/unified-ci.yml', 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r'uses: AM-Portfolio/am-pipelines/\.github/workflows/central-build-publish\.yml@main.*?secrets: inherit'

replacement = '''uses: AM-Portfolio/am-pipelines/.github/workflows/central-build-publish-contabo.yml@main
    with:
      language: "flutter"
      working_directory: "am_app"
      build_context: ".."
      image_name: "am-modern-ui"
      skip_security_scan: true
    secrets: inherit'''

new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open('.github/workflows/unified-ci.yml', 'w', encoding='utf-8') as f:
    f.write(new_content)

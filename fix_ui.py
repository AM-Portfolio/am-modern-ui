import sys

f1 = r'am_portfolio_ui/lib/features/portfolio/presentation/widgets/portfolio_heatmap_widget.dart'
with open(f1, 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace(
'''        templateType: widget.config.templateType,
      ),
    );
  }''',
'''              templateType: widget.config.templateType,
            ),
          ),
        ),
      ],
    );
  }'''
)
with open(f1, 'w', encoding='utf-8') as f:
    f.write(content)

f2 = r'am_design_system/lib/shared/widgets/heatmap/layouts/heatmap_layout_builder.dart'
with open(f2, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
'''      return GestureDetector(
        onTap: onTilePressed,''',
'''      return GestureDetector(
        onTap: onTilePressed != null ? () => onTilePressed(tile) : null,''')

content = content.replace(
'''    return GestureDetector(
      onTap: onTilePressed,''',
'''    return GestureDetector(
      onTap: onTilePressed != null ? () => onTilePressed(tile) : null,''')

with open(f2, 'w', encoding='utf-8') as f:
    f.write(content)

f3 = r'am_design_system/lib/shared/widgets/heatmap/layouts/grid_layout_builder.dart'
with open(f3, 'r', encoding='utf-8') as f:
    lines = f.readlines()

lines[124] = "  }\n"

card_lines = lines[126:381]
card_lines[-1] = "}\n"

new_lines = lines[:126] + lines[381:]
new_lines.extend(card_lines)

with open(f3, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print('Fixed!')

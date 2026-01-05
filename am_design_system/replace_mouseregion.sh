#!/bin/bash

# Script to replace MouseRegion with ConditionalMouseRegion
# This preserves all functionality while fixing web errors

echo "🔧 Replacing MouseRegion with ConditionalMouseRegion..."

# Files to update
files=(
  "/Users/munishm/Documents/AM-Repos/am_common_ui/lib/widgets/animations/animated_list_item.dart"
  "/Users/munishm/Documents/AM-Repos/am_common_ui/lib/widgets/display/glass_card.dart"
  "/Users/munishm/Documents/AM-Repos/am_common_ui/lib/widgets/animations/interactive_particle_background.dart"
  "/Users/munishm/Documents/AM-Repos/am_common_ui/lib/widgets/display/architecture_card.dart"
  "/Users/munishm/Documents/AM-Repos/am_common_ui/lib/widgets/tables/sortable_table.dart"
  "/Users/munishm/Documents/AM-Repos/am_common_ui/lib/shared/widgets/media/theme_selector.dart"
  "/Users/munishm/Documents/AM-Repos/am_common_ui/lib/shared/widgets/inputs/glass_text_field.dart"
  "/Users/munishm/Documents/AM-Repos/am_common_ui/lib/shared/widgets/backgrounds/interactive_background.dart"
  "/Users/munishm/Documents/AM-Repos/am_common_ui/lib/widgets/layouts/secondary_sidebar.dart"
)

# Backup directory
backup_dir="/Users/munishm/Documents/AM-Repos/am_common_ui_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

echo "📦 Creating backup in: $backup_dir"

# Process each file
count=0
for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")
    echo "  Processing: $filename"
    
    # Backup original
    cp "$file" "$backup_dir/"
    
    # Replace MouseRegion with ConditionalMouseRegion
    # Also add import if not present
    if ! grep -q "ConditionalMouseRegion" "$file"; then
      # Add import at the top (after package:flutter/material.dart)
      sed -i.bak "/import 'package:flutter\/material.dart';/a\\
import '../../core/utils/conditional_mouse_region.dart';
" "$file"
      
      # Replace MouseRegion( with ConditionalMouseRegion(
      sed -i.bak 's/MouseRegion(/ConditionalMouseRegion(/g' "$file"
      
      # Remove .bak files
      rm -f "${file}.bak"
      
      count=$((count + 1))
      echo "    ✓ Replaced MouseRegion with ConditionalMouseRegion"
    else
      echo "    ⊘ Already uses ConditionalMouseRegion"
    fi
  else
    echo "    ✗ File not found: $filename"
  fi
done

echo ""
echo "✅ Replacement complete!"
echo "   Files updated: $count"
echo "   Backup location: $backup_dir"
echo ""
echo "🔄 Next steps:"
echo "   1. Run: cd /Users/munishm/Documents/AM-Repos/am_common_ui"
echo "   2. Run: flutter pub get"
echo "   3. Rebuild investment-ui: flutter build web --release"
echo "   4. Restart Docker: docker-compose down && docker-compose up -d"

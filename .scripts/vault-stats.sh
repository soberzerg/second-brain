#!/bin/bash

# Vault Statistics Script
# Shows basic stats about your Obsidian vault

echo "=== Vault Statistics ==="
echo ""

echo "📝 Note Counts:"
echo "  Inbox:     $(find 000_Inbox -name "*.md" 2>/dev/null | wc -l)"
echo "  Tasks:     $(find 100_Tasks -name "*.md" 2>/dev/null | wc -l)"
echo "  Projects:  $(find 200_Projects -name "*.md" 2>/dev/null | wc -l)"
echo "  Blog:      $(find 300_Blog -name "*.md" 2>/dev/null | wc -l)"
echo "  Planning:  $(find 400_Planning -name "*.md" 2>/dev/null | wc -l)"
echo "  Research:  $(find 500_Research -name "*.md" 2>/dev/null | wc -l)"
echo ""

echo "📊 Total Notes: $(find . -name "*.md" | wc -l)"
echo ""

echo "🔄 Recent Activity (last 7 days):"
find . -name "*.md" -mtime -7 -type f 2>/dev/null | head -5 | while read file; do
    echo "  - $(basename "$file")"
done

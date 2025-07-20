#!/bin/sh

# Check if exactly two arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_file> <destination_file>"
    exit 1
fi

source_file="$1"
destination_file="$2"

rm -f "$destination_file"

# create a unique prefix for all generated labels
prefix=$(basename "$source_file" | cut -d. -f1 | tr '-' '_')

sed -E \
  -e "1i\;\r\n; Generated from source-doc/${source_file} -- not to be modify directly\r\n;\r\n; " \
  -e '/SECTION IGNORE/d' \
  -e '/\sEXTERN\s/d' \
  -e '/\sGLOBAL\s/d' \
  -e '/SECTION .*/d' \
  -e 's/^IF 0/#IF 0/g' \
  -e 's/^ENDIF/#ENDIF/g' \
  -e 's/\s+cp\s+a,\((ix\+[0-9-]+)\)/\tcp\t\(\1\)/g' \
  -e 's/\s+sub\s+a,\((iy\+[0-9]+)\)/\tsub\t\(\1\)/g' \
  -e 's/\s+sub\s+a,\((ix\+[0-9]+)\)/\tsub\t\(\1\)/g' \
  -e 's/\s+sub\s+a,\((ix-[0-9]+)\)/\tsub\t\(\1\)/g' \
  -e 's/\s+or\s+a,\((ix\+[0-9-]+)\)/\tor\t\(\1\)/g' \
  -e 's/\s+or\s+a,\((ix\-[0-9-]+)\)/\tor\t\(\1\)/g' \
  -e 's/\s+or\s+a,\((iy\+[0-9-]+)\)/\tor\t\(\1\)/g' \
  -e 's/\s+or\s+a,\s*\((hl)\)/\tor\t\(\1\)/g' \
  -e 's/\s+sub\s+a,\s*\((hl)\)/\tsub\t\(\1\)/g' \
  -e 's/\s+cp\s+a,(0x[0-9A-Fa-f]{2})/\tcp\t\1/g' \
  -e 's/\s+or\s+a,(0x[0-9A-Fa-f]{2})/\tor\t\1/g' \
  -e 's/\s+xor\s+a,(0x[0-9A-Fa-f]{2})/\txor\t\1/g' \
  -e 's/\s+and\s+a,(0x[0-9A-Fa-f]{2})/\tand\t\1/g' \
  -e 's/\s+and\s+a,\s*a/\tand\ta/g' \
  -e 's/\s+and\s+a,\s*(b|c|d|e|h|l|iyl|iyh|ixl|ixh)/\tand\t\1/g' \
  -e 's/\s+sub\s+a,(0x[0-9A-Fa-f]{2})/\tsub\t\1/g' \
  -e 's/\s+cp\s+a,\s*a/\tcp\ta/g' \
  -e 's/\s+or\s+a,\s*a/\tor\ta/g' \
  -e 's/\s+xor\s+a,\s*a/\txor\ta/g' \
  -e 's/\s+or\s+a,\s*(b|c|d|e|h|l|iyl|iyh|ixl|ixh)/\tor\t\1/g' \
  -e 's/\s+sub\s+a,\s+(b|c|d|e|h|l|iyl|iyh|ixl|ixh)/\tsub\t\1/g' \
  -e 's/\b([a-zA-Z0-9_]{31})[a-zA-Z0-9_]+\b/\1/g' \
  -e 's/;\t+/; /g' \
  -e 's/defc\s+([a-zA-Z0-9_]+)\s*=\s*(0x[0-9A-Fa-f]+)/\1\t.EQU\t\2/' \
  -e "s/___str_([0-9]+)/${prefix}_str_\1/g" \
  -e 's/\b0x([0-9A-Fa-f]+)\b/\$\1/g' \
  "$source_file" > "$destination_file"


  # -e '/IF 0/d' \
  # -e '/ENDIF/d' \

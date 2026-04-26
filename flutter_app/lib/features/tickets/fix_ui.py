import re

with open(r'd:\FptUniversity\Capstone\capstone_app\flutter_app\lib\features\tickets\tickets_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace Padding( child: Wrap( ... ) ) with SingleChildScrollView( child: Row( ... ) )
content = re.sub(
    r'Padding\(\s*padding: const EdgeInsets.symmetric\(horizontal: 16\),\s*child: Wrap\(\s*spacing: 8,\s*runSpacing: 8,\s*children: \[',
    r'SingleChildScrollView(\n                      scrollDirection: Axis.horizontal,\n                      padding: const EdgeInsets.symmetric(horizontal: 16),\n                      child: Row(\n                        children: [',
    content
)

content = re.sub(
    r'Padding\(\s*padding: const EdgeInsets.symmetric\(horizontal: 16\),\s*child: Wrap\(\s*spacing: 8,\s*runSpacing: 8,\s*children: roomOptions\.map\(\(room\) \{',
    r'SingleChildScrollView(\n                      scrollDirection: Axis.horizontal,\n                      padding: const EdgeInsets.symmetric(horizontal: 16),\n                      child: Row(\n                        children: roomOptions.map((room) {',
    content
)

# Add margin to _buildFilterChip
content = re.sub(
    r'child: AnimatedContainer\(\s*duration: const Duration\(milliseconds: 200\),\s*padding: const EdgeInsets.symmetric\(horizontal: 16, vertical: 8\),',
    r'child: AnimatedContainer(\n        duration: const Duration(milliseconds: 200),\n        margin: const EdgeInsets.only(right: 8),\n        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),',
    content
)

# Add margin to _buildDateFilterChip
content = re.sub(
    r'child: Container\(\s*padding: const EdgeInsets.symmetric\(horizontal: 16, vertical: 8\),',
    r'child: Container(\n        margin: const EdgeInsets.only(right: 8),\n        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),',
    content
)

with open(r'd:\FptUniversity\Capstone\capstone_app\flutter_app\lib\features\tickets\tickets_page.dart', 'w', encoding='utf-8', newline='') as f:
    f.write(content)

print("Done")

import os
import re

def fix_with_opacity(directory):
    pattern = re.compile(r'\.withOpacity\(([^)]+)\)')
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = pattern.sub(r'.withValues(alpha: \1)', content)
                
                if new_content != content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Fixed {filepath}")

if __name__ == '__main__':
    fix_with_opacity('c:\\Users\\harsh\\OneDrive\\Desktop\\NOVA\\Nova_Rangers\\communityPulse-nova-rangers\\frontend\\lib')

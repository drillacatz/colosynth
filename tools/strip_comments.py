import os
import re

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
LIB_DIR = os.path.join(PROJECT_ROOT, 'lib')

# Regex patterns
single_line = re.compile(r'^\s*//.*')
doc_line = re.compile(r'^\s*///.*')
block_comment = re.compile(r'/\*.*?\*/', re.DOTALL)

def strip_comments_from_content(content: str) -> str:
    # Remove block comments first
    content = re.sub(block_comment, '', content)
    lines = []
    for line in content.splitlines():
        if single_line.match(line) or doc_line.match(line):
            # Preserve line break to keep line numbers roughly stable
            lines.append('')
        else:
            lines.append(line)
    return '\n'.join(lines) + '\n'

def process_file(path: str) -> None:
    with open(path, 'r', encoding='utf-8') as f:
        original = f.read()
    stripped = strip_comments_from_content(original)
    if stripped != original:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(stripped)
        print(f"Processed: {path}")

def main():
    for root, _, files in os.walk(LIB_DIR):
        for name in files:
            if name.endswith('.dart'):
                process_file(os.path.join(root, name))

if __name__ == '__main__':
    main()

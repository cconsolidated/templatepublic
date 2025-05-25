import os
import json

def should_ignore(path):
    # List of directories and files to ignore
    ignore_patterns = [
        'node_modules',
        '.git',
        '.vscode',
        '__pycache__',
        '.DS_Store',
        'output.json',
        'generate_output.py',
        'package-lock.json'
    ]
    
    return any(pattern in path for pattern in ignore_patterns)

def get_file_content(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"Error reading {file_path}: {str(e)}")
        return ""

def main():
    file_list = []
    base_dir = os.getcwd()
    
    for root, dirs, files in os.walk(base_dir):
        # Skip ignored directories
        dirs[:] = [d for d in dirs if not should_ignore(os.path.join(root, d))]
        
        for file in files:
            if should_ignore(file):
                continue
                
            file_path = os.path.join(root, file)
            relative_path = os.path.relpath(file_path, base_dir)
            content = get_file_content(file_path)
            
            file_list.append({
                "path": relative_path,
                "content": content
            })
    
    # Write to output.json
    with open('output.json', 'w', encoding='utf-8') as f:
        json.dump({"files": file_list}, f, indent=2)

if __name__ == "__main__":
    main() 
import os
import json
from pathlib import Path

def should_skip_dir(dir_name):
    skip_dirs = {'node_modules', 'build', '__pycache__', '.git'}
    return dir_name in skip_dirs

def read_file_content(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        return f"Error reading file: {str(e)}"

def export_files_to_json():
    root_dir = Path('.')
    result = []
    
    for path in root_dir.rglob('*'):
        if path.is_file() and not should_skip_dir(path.parts[0]):
            relative_path = str(path.relative_to(root_dir))
            content = read_file_content(path)
            
            result.append({
                "path": relative_path,
                "content": content
            })
    
    # Write to JSON file
    with open('files_export.json', 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    
    print(f"Exported {len(result)} files to files_export.json")

if __name__ == "__main__":
    export_files_to_json() 
import os
import json

def ensure_directory_exists(file_path):
    # Get the directory path
    directory = os.path.dirname(file_path)
    # Create directory if it doesn't exist
    if directory and not os.path.exists(directory):
        os.makedirs(directory)

def write_file(file_path, content):
    try:
        # Ensure the directory exists
        ensure_directory_exists(file_path)
        
        # Write the file
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Successfully wrote: {file_path}")
    except Exception as e:
        print(f"Error writing {file_path}: {str(e)}")

def main():
    try:
        # Read input.json
        with open('input.json', 'r', encoding='utf-8') as f:
            file_list = json.load(f)
        
        # Check if data is a list
        if not isinstance(file_list, list):
            raise ValueError("input.json must be an array of file objects")
        
        # Write each file
        for file_info in file_list:
            if not isinstance(file_info, dict) or 'path' not in file_info or 'content' not in file_info:
                print(f"Skipping invalid file entry: {file_info}")
                continue
                
            write_file(file_info['path'], file_info['content'])
            
        print("All files have been written successfully!")
        
    except FileNotFoundError:
        print("Error: input.json not found")
    except json.JSONDecodeError:
        print("Error: input.json is not valid JSON")
    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == "__main__":
    main() 
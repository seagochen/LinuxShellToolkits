import os
import sys
import json


def rename_files(dir_path, rename_dict):
    # Get all files from the given directory
    files = [os.path.join(dir_path, f) for f in os.listdir(dir_path)]

    # Only get the filenames from the files
    files = [os.path.basename(f) for f in files]

    # Create a dictionary that contains the files's name and their extension
    files_dict = {os.path.splitext(os.path.basename(f))[0]: os.path.splitext(f)[1] for f in files}

    # Filter the files_dict with the rename_dict which the files are not going to be renamed
    files_dict = {k: v for k, v in files_dict.items() if k in rename_dict.keys()}

    # Rename the files
    for f in files_dict:
        # Original file path
        original_file_path = os.path.join(dir_path, f + files_dict[f])

        # New file path
        new_file_path = os.path.join(dir_path, rename_dict[f] + files_dict[f])

        # Print the renaming process
        print(f'Renaming {original_file_path} to {new_file_path}')

        # Rename the file
        os.rename(original_file_path, new_file_path)

if __name__ == '__main__':

    # If rename.json is not in the target directory, exit the program
    if not os.path.exists(sys.argv[1] + '/rename.json'):
        print('rename.json does not exist in the given directory!')
        sys.exit()

    # Load the rename dictionary from the given directory
    with open(sys.argv[1] + '/rename.json') as f:
        rename_dict = json.load(f)

        # Rename the files in the given directory
        rename_files(sys.argv[1], rename_dict)
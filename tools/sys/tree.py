import os
import sys

def print_tree(dir_path, padding="", print_files=False):
    # Get the contents of the directory
    contents = os.listdir(dir_path)

    # Loop through the contents
    for item in contents:
        # Get the full path of the item
        item_path = os.path.join(dir_path, item)

        # Check if it's a file or directory
        if os.path.isfile(item_path):
            if print_files:
                # Print the file name with padding
                print(padding + "|-- " + item)
        else:
            # Print the directory name with padding
            print(padding + "+-- " + item)

            # Recursively print the contents of the directory
            print_tree(item_path, padding + "    ", print_files)

if __name__ == "__main__":
   # Get the root path from the command line arguments
    root_path = sys.argv[1]

    # Print the root path
    print(".")

    # Print the folder structure
    print_tree(root_path, print_files=True)
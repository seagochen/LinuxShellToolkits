import hashlib

def calculate_hash(file_path, hash_algorithm='sha256'):
    """
    Calculate the hash value of a file using the specified algorithm.
    
    Args:
    - file_path: The path to the file.
    - hash_algorithm: The hash algorithm to use (e.g., 'md5', 'sha1', 'sha256', etc.).
    
    Returns:
    - The hash value of the file.
    """
    # Initialize the hash object
    hash_func = getattr(hashlib, hash_algorithm.lower(), None)
    if hash_func is None:
        raise ValueError("Invalid hash algorithm specified.")
    
    # Read the file in binary mode and update the hash object
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b''):
            hash_func.update(chunk)
    
    # Return the hexadecimal representation of the hash
    return hash_func.hexdigest()


def calculate_files_in_dir(folder_path, hash_algorithm='sha256'):
    """
    Calculate the hash values of all files in the specified folder.
    
    Args:
    - folder_path: The path to the folder.
    - hash_algorithm: The hash algorithm to use (e.g., 'md5', 'sha1', 'sha256', etc.).
    
    Returns:
    - A dictionary mapping file names to their hash values.
    """
    import os
    
    # Initialize the dictionary to store the hash values
    hash_values = {}
    
    # Iterate over all files in the folder
    for root, _, files in os.walk(folder_path):
        for file_name in files:
            file_path = os.path.join(root, file_name)
            # Initialize the hash object for each file
            hash_func = getattr(hashlib, hash_algorithm.lower(), None)
            if hash_func is None:
                raise ValueError("Invalid hash algorithm specified.")
            hash_func = hash_func()
            # Update the hash object with the file content
            with open(file_path, 'rb') as f:
                for chunk in iter(lambda: f.read(4096), b''):
                    hash_func.update(chunk)
            # Store the hexadecimal representation of the hash in the dictionary
            hash_values[file_path] = hash_func.hexdigest()
    
    return hash_values


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python checksum.py <folder_path>")
        sys.exit(1)
    
    hash_results = calculate_files_in_dir(sys.argv[1])

    for file_path, hash_value in hash_results.items():
        print(f"{file_path}: {hash_value}")
    
    print("Done.")

import os
import sys
import subprocess


def convert_ipynb_to_py(ipynb_path):
    subprocess.run(['jupyter', 'nbconvert', ipynb_path, '--to', 'python'])


def convert_ipynb_to_html(ipynb_path):
    subprocess.run(['jupyter', 'nbconvert', ipynb_path, '--to', 'html'])


def convert_ipynb_to_pdf(ipynb_path):
    subprocess.run(['jupyter', 'nbconvert', ipynb_path, '--to', 'pdf'])


def convert_ipynb_to_md(ipynb_path):
    subprocess.run(['jupyter', 'nbconvert', ipynb_path, '--to', 'markdown'])


def convert_ipynbs_from_dirs(dir_path, dst_path, type='py'):
    # Get all ipynb files from the given directory
    ipynb_files = [os.path.join(dir_path, f) for f in os.listdir(dir_path) if f.endswith('.ipynb')]

    # Convert all ipynb files to the given type
    for ipynb_file in ipynb_files:
        if type == 'py':
            convert_ipynb_to_py(ipynb_file)
        elif type == 'html':
            convert_ipynb_to_html(ipynb_file)
        elif type == 'pdf':
            convert_ipynb_to_pdf(ipynb_file)
        elif type == 'md':
            convert_ipynb_to_md(ipynb_file)
        else:
            print('Invalid type!')

    # Get all converted files and move them to the given directory
    converted_files = [f for f in os.listdir(dir_path) if f.endswith(f'.{type}')]

    # Concatenate the directory path to the converted files
    converted_full_pathes = [os.path.join(dir_path, f) for f in converted_files]

    # Move the converted files to the destination directory
    for full_path, src_file in zip(converted_full_pathes, converted_files):
        os.rename(full_path, os.path.join(dst_path, os.path.basename(src_file)))



if __name__ == '__main__':

    # If nbconvert is not installed, install it
    try:
        import nbconvert
    except ImportError:
        # In windows, use 'pip' instead of 'pip3'
        if os.name == 'nt':
            subprocess.run(['pip', 'install', 'nbconvert'])
        else:
            subprocess.run(['pip3', 'install', 'nbconvert'])

    # Check the number of arguments
    # Usage: python convert_ipynbs.py <ipynb_path> <type> <dst_path>
    if len(sys.argv) != 4:
        print('Usage: python convert_ipynbs.py <ipynb_path> <type> <dst_path>')
        sys.exit(1)

    ipynb_path = sys.argv[1]
    type = sys.argv[2]
    dst_path = sys.argv[3]

    # If dst_path does not exist, create it
    if not os.path.exists(dst_path):
        os.makedirs(dst_path)

    # Convert ipynb files to the given type
    if os.path.isdir(ipynb_path):
        convert_ipynbs_from_dirs(ipynb_path, dst_path, type)
    else:
        print(f'The provided path {ipynb_path} is not a directory')

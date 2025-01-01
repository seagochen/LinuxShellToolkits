#!/bin/bash

# Function to check if file exists and is an ONNX file
validate_onnx() {
    local file="$1"
    
    # Check if argument is provided
    if [ -z "$file" ]; then
        echo "Error: Please provide an ONNX model path"
        echo "Usage: $0 <path-to-onnx-model>"
        exit 1
    fi  # Changed '}' to 'fi'

    # Check if file exists
    if [ ! -f "$file" ]; then
        echo "Error: File '$file' does not exist"
        exit 1
    fi

    # Check file extension
    if [[ "$file" != *.onnx ]]; then
        echo "Error: File '$file' is not an ONNX model (must have .onnx extension)"
        exit 1
    fi

    # Additional check for file readability
    if [ ! -r "$file" ]; then
        echo "Error: File '$file' is not readable"
        exit 1
    fi
}

# Function to check if trtexec is available
check_trtexec() {
    if ! command -v trtexec &> /dev/null; then
        echo "Error: trtexec is not installed or not in PATH"
        exit 1
    fi
}

# Main execution
main() {
    local onnx_path="$1"
    
    # Validate input
    validate_onnx "$onnx_path"
    
    # Check trtexec availability
    check_trtexec
    
    echo "Running TensorRT execution with model: $onnx_path"
    echo "----------------------------------------"
    
    # Execute trtexec with the provided ONNX model
    trtexec --onnx="$onnx_path" --verbose
}

# Call main function with all script arguments
main "$@"
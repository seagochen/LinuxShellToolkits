#!/bin/bash

# Function to check if required tools are installed
check_requirements() {
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Attempting to install..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
            if [ $? -ne 0 ]; then
                echo "Error: Failed to install jq. Please install it manually using: sudo apt-get install jq"
                exit 1
            fi
        else
            echo "Error: Unable to automatically install jq. Please install it manually."
            exit 1
        fi
    fi

    if ! command -v trtexec &> /dev/null; then
        echo "Error: trtexec is not installed or not in PATH"
        exit 1
    fi
}

# Function to validate ONNX file
validate_onnx() {
    local file="$1"
    local name="$2"
    
    if [ ! -f "$file" ]; then
        echo "Error: ONNX file for model '$name' does not exist: $file"
        return 1
    fi

    if [[ "$file" != *.onnx ]]; then
        echo "Error: File for model '$name' is not an ONNX model: $file"
        return 1
    fi

    if [ ! -r "$file" ]; then
        echo "Error: ONNX file for model '$name' is not readable: $file"
        return 1
    fi
}

# Function to validate output engine path
validate_engine_path() {
    local engine_path="$1"
    local name="$2"
    
    local dir=$(dirname "$engine_path")
    if [ ! -d "$dir" ]; then
        echo "Creating directory for engine file: $dir"
        mkdir -p "$dir" || {
            echo "Error: Cannot create directory for engine file: $dir"
            return 1
        }
    fi

    if [ ! -w "$dir" ]; then
        echo "Error: Directory for engine file is not writable: $dir"
        return 1
    fi
}

# Function to build TensorRT engine for a single model
build_engine() {
    local model_json="$1"
    local name=$(echo "$model_json" | jq -r '.name')
    local onnx_path=$(echo "$model_json" | jq -r '.onnx_path')
    local engine_path=$(echo "$model_json" | jq -r '.engine_path')
    
    echo "Processing model: $name"
    
    validate_onnx "$onnx_path" "$name" || return 1
    validate_engine_path "$engine_path" "$name" || return 1
    
    local cmd="trtexec --onnx=$onnx_path --saveEngine=$engine_path"
    
    if [[ $(echo "$model_json" | jq -r '.precision // empty') == "fp16" ]]; then
        cmd="$cmd --fp16"
    fi
    
    if [[ $(echo "$model_json" | jq -r '.min_shapes // empty') != "null" ]]; then
        cmd="$cmd --minShapes=$(echo "$model_json" | jq -r '.min_shapes')"
    fi
    
    if [[ $(echo "$model_json" | jq -r '.opt_shapes // empty') != "null" ]]; then
        cmd="$cmd --optShapes=$(echo "$model_json" | jq -r '.opt_shapes')"
    fi
    
    if [[ $(echo "$model_json" | jq -r '.max_shapes // empty') != "null" ]]; then
        cmd="$cmd --maxShapes=$(echo "$model_json" | jq -r '.max_shapes')"
    fi
    
    if [[ $(echo "$model_json" | jq -r '.verbose // empty') == "true" ]]; then
        cmd="$cmd --verbose"
    fi
    
    echo "Executing command: $cmd"
    eval "$cmd"
    
    if [ $? -eq 0 ]; then
        echo "Successfully built engine for model: $name"
        echo "Engine saved to: $engine_path"
    else
        echo "Failed to build engine for model: $name"
        return 1
    fi
}

# Main function
main() {
    local config_file="$1"
    
    if [ -z "$config_file" ]; then
        echo "Error: Please provide a configuration file"
        echo "Usage: $0 <path-to-config.json>"
        exit 1
    fi
    
    if [ ! -f "$config_file" ] || [ ! -r "$config_file" ]; then
        echo "Error: Configuration file does not exist or is not readable: $config_file"
        exit 1
    fi
    
    check_requirements
    
    jq -c '.models[]' "$config_file" | while read -r model_json; do
        build_engine "$model_json"
    done
}

main "$@"

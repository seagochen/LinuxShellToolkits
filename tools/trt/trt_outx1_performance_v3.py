"""
测试TensorRT模型，单输入 + 单输出的测试脚本
"""

import tensorrt as trt
import pycuda.driver as cuda
import pycuda.autoinit
import numpy as np
import time
import sys
import argparse
from tqdm import tqdm

def parse_args():
    parser = argparse.ArgumentParser(description="TensorRT Engine Performance Tester")
    parser.add_argument("engine_path", type=str, help="Path to TensorRT engine file")
    parser.add_argument("-i", "--input_shape", type=str, required=True, 
                        help="Input shape including batch size in NCHW format (e.g., 1x3x224x224)")
    parser.add_argument("-o", "--output_shape", type=str, required=True, 
                        help="Output shape including batch size (e.g., 1x15)")
    parser.add_argument("-n", "--iterations", type=int, default=100, help="Number of inference iterations")
    return parser.parse_args()

def load_engine(engine_path):
    """Load the TensorRT engine"""
    TRT_LOGGER = trt.Logger(trt.Logger.WARNING)
    with open(engine_path, "rb") as f, trt.Runtime(TRT_LOGGER) as runtime:
        engine = runtime.deserialize_cuda_engine(f.read())
    return engine

def allocate_buffers(engine, input_shape, output_shape):
    """Allocate GPU buffers for the TensorRT engine (TensorRT V3 API)"""
    context = engine.create_execution_context()

    # Use the new TensorRT API to get tensor names
    input_tensor_name = engine.get_tensor_name(0)
    output_tensor_name = engine.get_tensor_name(1)

    # Set dynamic shape if required
    context.set_input_shape(input_tensor_name, input_shape)
    assert context.all_binding_shapes_specified, "Error: Not all binding shapes are specified!"

    # Determine data types
    input_dtype = trt.nptype(engine.get_tensor_dtype(input_tensor_name))
    output_dtype = trt.nptype(engine.get_tensor_dtype(output_tensor_name))

    # Allocate device memory (fixing numpy.int64 to int conversion)
    input_size = int(np.prod(input_shape) * np.dtype(input_dtype).itemsize)
    output_size = int(np.prod(output_shape) * np.dtype(output_dtype).itemsize)

    input_buffer = cuda.mem_alloc(input_size)
    output_buffer = cuda.mem_alloc(output_size)

    # Set tensor addresses instead of binding indices
    context.set_tensor_address(input_tensor_name, input_buffer)
    context.set_tensor_address(output_tensor_name, output_buffer)

    # Return 6 values to match unpacking
    return context, input_buffer, output_buffer, input_dtype, output_dtype, input_tensor_name, output_tensor_name

def generate_random_input(input_shape, input_dtype):
    """Generate random input data"""
    return np.random.random(input_shape).astype(input_dtype)

def run_inference(context, input_buffer, output_buffer, input_data, output_shape, num_iterations=100):
    """Run inference multiple times and display progress"""
    stream = cuda.Stream()
    times = []

    # Copy input data to GPU
    cuda.memcpy_htod_async(input_buffer, input_data, stream)

    for _ in tqdm(range(num_iterations), desc="Running inference", unit="iteration"):
        start_time = time.time()
        context.execute_async_v3(stream.handle)
        cuda.Context.synchronize()
        end_time = time.time()
        times.append(end_time - start_time)

    avg_time = sum(times) / num_iterations
    print(f"\nAverage Inference Time over {num_iterations} iterations: {avg_time:.4f} seconds")

    output_data = np.empty(output_shape, dtype=np.float32)
    cuda.memcpy_dtoh_async(output_data, output_buffer, stream)
    stream.synchronize()
    
    return output_data

if __name__ == "__main__":
    args = parse_args()

    try:
        print(f"Loading TensorRT engine from: {args.engine_path}")
        engine = load_engine(args.engine_path)

        # Parse input and output shapes (convert '1x3x224x224' -> (1, 3, 224, 224))
        input_shape = tuple(map(int, args.input_shape.split('x')))
        output_shape = tuple(map(int, args.output_shape.split('x')))

        # context, bindings, input_buffer, output_buffer, input_dtype, output_dtype = allocate_buffers(
        #     engine, input_shape, output_shape
        # )

        context, input_buffer, output_buffer, input_dtype, output_dtype, input_tensor_name, output_tensor_name = allocate_buffers(
            engine, input_shape, output_shape
        )

        print(f"Input shape: {input_shape}, Output shape: {output_shape}")

        input_data = generate_random_input(input_shape, input_dtype)

        output = run_inference(context, input_buffer, output_buffer, input_data, output_shape, num_iterations=args.iterations)

        print("Inference completed successfully.")
        print("Sample output:", output[:10])  # Display first 10 output values

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

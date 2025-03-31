"""
测试TensorRT模型，单输入 + 双输出的测试脚本
"""

import tensorrt as trt
import pycuda.driver as cuda
import pycuda.autoinit
import numpy as np
import time
import sys
import argparse
from tqdm import tqdm
import ctypes

# 载入 TensorRT 插件库
plugin_path = "/opt/tensorrt/targets/x86_64-linux-gnu/lib/libnvinfer_plugin.so"
ctypes.CDLL(plugin_path, mode=ctypes.RTLD_GLOBAL)

# 初始化 TensorRT 插件
trt.init_libnvinfer_plugins(trt.Logger(trt.Logger.WARNING), namespace="")

def parse_args():
    parser = argparse.ArgumentParser(description="TensorRT Engine Performance Tester")
    parser.add_argument("engine_path", type=str, help="Path to TensorRT engine file")
    parser.add_argument("-i", "--input_shape", type=str, required=True, 
                        help="Input shape in NCHW format (e.g., 1x3x540x960)")
    parser.add_argument("-n", "--iterations", type=int, default=100, help="Number of inference iterations")
    return parser.parse_args()

def load_engine(engine_path):
    """Load the TensorRT engine from file."""
    TRT_LOGGER = trt.Logger(trt.Logger.WARNING)
    with open(engine_path, "rb") as f, trt.Runtime(TRT_LOGGER) as runtime:
        engine = runtime.deserialize_cuda_engine(f.read())
        if not engine:
            raise RuntimeError("Failed to load TensorRT engine. Check if the model file is valid.")
    print("Engine successfully loaded.")
    return engine

def allocate_buffers(engine, input_shape):
    """Allocate GPU buffers for the TensorRT engine."""
    context = engine.create_execution_context()
    if not context:
        raise RuntimeError("Failed to create execution context.")

    # 获取输入和输出张量名称
    input_tensor_name = engine.get_tensor_name(0)
    output_tensor_name_1 = engine.get_tensor_name(1)
    output_tensor_name_2 = engine.get_tensor_name(2)

    # 设置动态输入形状
    context.set_input_shape(input_tensor_name, input_shape)
    assert context.all_binding_shapes_specified, "Error: Not all binding shapes specified!"

    # 获取数据类型并确保正确分配内存
    input_dtype = trt.nptype(engine.get_tensor_dtype(input_tensor_name))
    output_dtype_1 = trt.nptype(engine.get_tensor_dtype(output_tensor_name_1))
    output_dtype_2 = trt.nptype(engine.get_tensor_dtype(output_tensor_name_2))

    input_size = int(np.prod(input_shape)) * np.dtype(input_dtype).itemsize
    output_size_1 = int(1000000)  # 预设较大值
    output_size_2 = int(1000000)

    input_buffer = cuda.mem_alloc(input_size)
    output_buffer_1 = cuda.mem_alloc(output_size_1)
    output_buffer_2 = cuda.mem_alloc(output_size_2)

    # 绑定 GPU 内存
    context.set_tensor_address(input_tensor_name, int(input_buffer))
    context.set_tensor_address(output_tensor_name_1, int(output_buffer_1))
    context.set_tensor_address(output_tensor_name_2, int(output_buffer_2))

    print("Memory buffers allocated successfully.")
    return context, input_buffer, output_buffer_1, output_buffer_2, input_dtype, output_dtype_1, output_dtype_2, input_tensor_name, output_tensor_name_1, output_tensor_name_2

def generate_random_input(input_shape, input_dtype):
    """Generate random input data for inference."""
    return np.random.randn(*input_shape).astype(input_dtype)

# def run_inference(context, input_buffer, output_buffer_1, output_buffer_2, input_data, num_iterations=100):
#     """Run inference multiple times and display progress."""
#     stream = cuda.Stream()
#     times = []

#     # 将输入数据复制到 GPU
#     cuda.memcpy_htod_async(input_buffer, input_data, stream)

#     for _ in tqdm(range(num_iterations), desc="Running inference", unit="iteration"):
#         start_time = time.time()
#         try:
#             context.execute_v2(bindings=[int(input_buffer), int(output_buffer_1), int(output_buffer_2)])
#             cuda.Context.synchronize()
#         except Exception as e:
#             print(f"Inference execution failed: {e}")
#             return None, None
#         end_time = time.time()
#         times.append(end_time - start_time)

#     avg_time = sum(times) / num_iterations
#     print(f"\nAverage Inference Time over {num_iterations} iterations: {avg_time:.4f} seconds")

#     # 使用 get_binding_dimensions 代替 get_binding_shape
#     # output_shape_1 = tuple(context.get_binding_dimensions(engine.get_binding_index(output_tensor_name_1)))
#     # output_shape_2 = tuple(context.get_binding_dimensions(engine.get_binding_index(output_tensor_name_2)))

#     output_shape_1 = tuple(context.get_binding_shape(engine.get_binding_index(output_tensor_name_1)))
#     output_shape_2 = tuple(context.get_binding_shape(engine.get_binding_index(output_tensor_name_2)))

#     output_data_1 = np.empty(output_shape_1, dtype=np.float32)
#     output_data_2 = np.empty(output_shape_2, dtype=np.float32)

#     # 从 GPU 复制回 CPU
#     cuda.memcpy_dtoh_async(output_data_1, output_buffer_1, stream)
#     cuda.memcpy_dtoh_async(output_data_2, output_buffer_2, stream)
#     stream.synchronize()

#     return output_data_1, output_data_2

# def run_inference(context, engine, input_buffer, output_buffer_1, output_buffer_2, 
#                   input_data, output_tensor_name_1, output_tensor_name_2, num_iterations=100):
#     """Run inference multiple times and display progress."""
#     stream = cuda.Stream()
#     times = []

#     # 将输入数据复制到 GPU
#     cuda.memcpy_htod_async(input_buffer, input_data, stream)

#     for _ in tqdm(range(num_iterations), desc="Running inference", unit="iteration"):
#         start_time = time.time()
#         try:
#             context.execute_v2(bindings=[int(input_buffer), int(output_buffer_1), int(output_buffer_2)])
#             cuda.Context.synchronize()
#         except Exception as e:
#             print(f"Inference execution failed: {e}")
#             return None, None
#         end_time = time.time()
#         times.append(end_time - start_time)

#     avg_time = sum(times) / num_iterations
#     print(f"\nAverage Inference Time over {num_iterations} iterations: {avg_time:.4f} seconds")

#     # 使用新的 API 获取输出张量的形状
#     output_shape_1 = tuple(context.get_tensor_shape(output_tensor_name_1))
#     output_shape_2 = tuple(context.get_tensor_shape(output_tensor_name_2))

#     output_data_1 = np.empty(output_shape_1, dtype=np.float32)
#     output_data_2 = np.empty(output_shape_2, dtype=np.float32)

#     # 从 GPU 复制回 CPU
#     cuda.memcpy_dtoh_async(output_data_1, output_buffer_1, stream)
#     cuda.memcpy_dtoh_async(output_data_2, output_buffer_2, stream)
#     stream.synchronize()

#     return output_data_1, output_data_2


def run_inference(context, engine, input_buffer, output_buffer_1, output_buffer_2, 
                  input_data, output_tensor_name_1, output_tensor_name_2, num_iterations=100):
    """Run inference multiple times and display progress."""
    stream = cuda.Stream()
    times = []

    # 将输入数据复制到 GPU
    cuda.memcpy_htod_async(input_buffer, input_data, stream)
    stream.synchronize()  # 确保数据传输完成

    for _ in tqdm(range(num_iterations), desc="Running inference", unit="iteration"):
        start_time = time.time()
        try:
            context.execute_v2(bindings=[int(input_buffer), int(output_buffer_1), int(output_buffer_2)])
            cuda.Context.synchronize()  # 等待推理完成
        except Exception as e:
            print(f"Inference execution failed: {e}")
            return None, None
        end_time = time.time()
        times.append(end_time - start_time)

    avg_time = sum(times) / num_iterations
    print(f"\nAverage Inference Time over {num_iterations} iterations: {avg_time:.4f} seconds")

    # 获取输出张量的形状
    output_shape_1 = tuple(context.get_tensor_shape(output_tensor_name_1))
    output_shape_2 = tuple(context.get_tensor_shape(output_tensor_name_2))

    output_data_1 = np.empty(output_shape_1, dtype=np.float32)
    output_data_2 = np.empty(output_shape_2, dtype=np.float32)

    # 从 GPU 复制回 CPU
    cuda.memcpy_dtoh_async(output_data_1, output_buffer_1, stream)
    cuda.memcpy_dtoh_async(output_data_2, output_buffer_2, stream)
    stream.synchronize()  # 确保所有拷贝完成

    return output_data_1, output_data_2


# def clean_up(context, input_buffer, output_buffer_1, output_buffer_2):
#     """Free allocated GPU resources."""
#     context.__del__()
#     input_buffer.free()
#     output_buffer_1.free()
#     output_buffer_2.free()
#     print("Freed GPU memory resources and destroyed context.")

# def clean_up(context, input_buffer, output_buffer_1, output_buffer_2):
#     """Free allocated GPU resources."""
#     try:
#         # 确保所有操作已完成
#         cuda.Context.synchronize()

#         # 显式销毁执行上下文
#         if context:
#             context.__del__()  # 尝试使用 TensorRT 的内部方法
#             context = None

#         # 释放显存
#         input_buffer.free()
#         output_buffer_1.free()
#         output_buffer_2.free()

#         # 显式释放 CUDA 设备上下文
#         pycuda.autoinit.context.pop()

#         print("Freed GPU memory resources and destroyed context.")
#     except Exception as e:
#         print(f"Error during cleanup: {e}")



if __name__ == "__main__":
    args = parse_args()

    try:
        print(f"Loading TensorRT engine from: {args.engine_path}")
        engine = load_engine(args.engine_path)

        # 解析输入形状
        input_shape = tuple(map(int, args.input_shape.split('x')))

        # 分配缓存
        context, input_buffer, output_buffer_1, output_buffer_2, input_dtype, output_dtype_1, output_dtype_2, input_tensor_name, output_tensor_name_1, output_tensor_name_2 = allocate_buffers(
            engine, input_shape
        )

        print(f"Input shape: {input_shape}")
        input_data = generate_random_input(input_shape, input_dtype)

        # 运行推理
        output_1, output_2 = run_inference(
            context, 
            engine,  # 修复：添加缺少的 engine 参数
            input_buffer, 
            output_buffer_1, 
            output_buffer_2, 
            input_data, 
            output_tensor_name_1,  # 修复：添加缺少的输出张量名称
            output_tensor_name_2,  # 修复：添加缺少的输出张量名称
            num_iterations=args.iterations
        )
        if output_1 is not None and output_2 is not None:
            print("Inference completed successfully.")
            print("Sample output logits shape:", output_1.shape)
            print("Sample output boxes shape:", output_2.shape)

        # 资源释放
        # clean_up  # Python自动资源释放

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

import onnxruntime as ort
import numpy as np
import time
import sys
from tqdm import tqdm

def load_onnx_model(model_path):
    """加载 ONNX 模型"""
    available_providers = ort.get_available_providers()

    if 'CUDAExecutionProvider' in available_providers:
        print("CUDA is used")
        session = ort.InferenceSession(model_path, providers=['CUDAExecutionProvider', 'CPUExecutionProvider'])
    else:
        print("CUDA is not available, using CPU")
        session = ort.InferenceSession(model_path, providers=['CPUExecutionProvider'])

    return session

def generate_random_input(session):
    """根据模型输入定义生成随机输入数据"""
    input_data = {}
    for input_tensor in session.get_inputs():
        input_shape = list(input_tensor.shape)  # 转换为可修改列表
        input_dtype = input_tensor.type

        # 处理批处理大小为动态的情况
        if input_shape[0] is None or isinstance(input_shape[0], str):
            input_shape[0] = 1  # 如果批处理大小未知，则设置为 1

        numpy_type = np.float32 if 'float' in input_dtype else np.int32
        input_data[input_tensor.name] = np.random.randn(*input_shape).astype(numpy_type)

    return input_data

def run_inference(session, input_data, num_iterations=100):
    """运行模型推理多次，并使用 tqdm 显示进度"""
    times = []

    for _ in tqdm(range(num_iterations), desc="Running inference", unit="iteration"):
        start_time = time.time()
        _ = session.run(None, input_data)
        end_time = time.time()
        times.append(end_time - start_time)

    avg_time = sum(times) / num_iterations
    print(f"\nAverage Inference Time over {num_iterations} iterations: {avg_time:.4f} seconds")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python test_onnx.py <model_path>")
        sys.exit(1)
    
    model_path = sys.argv[1]

    try:
        print(f"Loading model from: {model_path}")
        session = load_onnx_model(model_path)
        input_data = generate_random_input(session)
        
        run_inference(session, input_data, num_iterations=100)

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

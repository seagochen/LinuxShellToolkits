import onnx
import onnx.helper as helper
from onnx import numpy_helper
import numpy as np
import sys
import argparse
import re

def get_tensor_type(tensor_type):
    types = {
        1: "FLOAT32", 2: "UINT8", 3: "INT8", 4: "UINT16",
        5: "INT16", 6: "INT32", 7: "INT64", 8: "STRING",
        9: "BOOL", 10: "FLOAT16", 11: "DOUBLE", 12: "UINT32",
        13: "UINT64", 14: "COMPLEX64", 15: "COMPLEX128",
    }
    return types.get(tensor_type, f"UNKNOWN({tensor_type})")

def calculate_params(model):
    total_params = 0
    for init in model.graph.initializer:
        params = 1
        for dim in init.dims:
            params *= dim
        total_params += params
    return total_params

def calculate_output_size(dim_expr, input_params):
    """
    计算输出维度
    参数:
        dim_expr: 原始维度表达式
        input_params: 包含height, width, channel等参数的字典
    """
    def floor(x):
        return int(np.floor(x))
    
    # 创建安全的eval环境
    safe_dict = {
        'floor': floor,
        **input_params
    }
    
    try:
        # 如果是纯数字，直接返回
        if isinstance(dim_expr, (int, float)):
            return dim_expr
            
        # 如果是字符串表达式，尝试计算
        if isinstance(dim_expr, str):
            # 处理 'batch' 特殊情况
            if dim_expr == 'batch':
                return input_params.get('batch', 1)
                
            # 尝试直接计算表达式
            try:
                result = eval(dim_expr, {"__builtins__": {}}, safe_dict)
                return result
            except:
                # 如果计算失败，返回原始表达式和计算后的结果
                return f"{dim_expr}"
    except:
        return f"{dim_expr}"

def format_shape_value(value):
    """格式化维度值显示"""
    if isinstance(value, (int, float)):
        return str(value)
    else:
        try:
            # 对于复杂表达式，只显示计算结果
            return str(value).split('=')[-1].strip()
        except:
            return str(value)


def analyze_onnx(model_path, show_input=False, show_output=False, 
                show_params=False, show_structure=False,
                input_params=None):
    if input_params is None:
        input_params = {}
    
    model = onnx.load(model_path)
    
    if show_input:
        print("===== 模型输入信息 =====")
        if len(model.graph.input) == 0:
            print("没有找到输入信息")
        for input in model.graph.input:
            print("输入名称:", input.name)
            print("数据类型:", get_tensor_type(input.type.tensor_type.elem_type))
            
            # 获取并计算维度
            dims = []
            for dim in input.type.tensor_type.shape.dim:
                dim_value = dim.dim_value if dim.dim_value != 0 else dim.dim_param
                calc_value = calculate_output_size(dim_value, input_params)
                dims.append(format_shape_value(calc_value))
            
            print("输入维度:", dims)
            
            # 计算总元素数
            try:
                total_elements = 1
                for dim in dims:
                    try:
                        num = int(float(dim))
                        total_elements *= num
                    except:
                        print(f"警告: 无法处理维度 '{dim}'")
                print(f"输入元素总数: {total_elements:,}")
            except:
                print("输入元素总数: 无法计算")
            print()

    if show_output:
        print("===== 模型输出信息 =====")
        for output in model.graph.output:
            print("输出名称:", output.name)
            print("数据类型:", get_tensor_type(output.type.tensor_type.elem_type))
            
            # 获取并计算维度
            dims = []
            for dim in output.type.tensor_type.shape.dim:
                dim_value = dim.dim_value if dim.dim_value != 0 else dim.dim_param
                calc_value = calculate_output_size(dim_value, input_params)
                dims.append(format_shape_value(calc_value))
            
            print("输出维度:", dims)
            
            # 计算总元素数
            try:
                total_elements = 1
                for dim in dims:
                    # 尝试将每个维度转换为数字
                    try:
                        num = int(float(dim))
                        total_elements *= num
                    except:
                        print(f"警告: 无法处理维度 '{dim}'")
                print(f"输出元素总数: {total_elements:,}")
            except:
                print("输出元素总数: 无法计算")
            print()

    if show_params:
        print("===== 模型参数信息 =====")
        total_params = calculate_params(model)
        print(f"总参数量: {total_params:,}")
        print(f"参数大小: {total_params * 4 / (1024*1024):.2f} MB (假设为float32)")
        print()
    
    if show_structure:
        print("===== 网络结构信息 =====")
        for node in model.graph.node:
            print("算子类型:", node.op_type)
            print("输入:", node.input)
            print("输出:", node.output)
            if node.attribute:
                print("属性:")
                for attr in node.attribute:
                    print(f"  - {attr.name}: {helper.get_attribute_value(attr)}")
            print()            

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='ONNX模型分析工具')
    parser.add_argument('model_path', type=str, help='ONNX模型路径')
    parser.add_argument('-i', '--input', action='store_true', help='显示输入信息')
    parser.add_argument('-o', '--output', action='store_true', help='显示输出信息')
    parser.add_argument('-p', '--params', action='store_true', help='显示参数信息')
    parser.add_argument('-s', '--structure', action='store_true', help='显示网络结构')
    parser.add_argument('-a', '--all', action='store_true', help='显示所有信息')
    
    # 添加输入参数
    parser.add_argument('--height', type=int, default=640, help='输入图像高度(默认640)')
    parser.add_argument('--width', type=int, default=640, help='输入图像宽度(默认640)')
    parser.add_argument('--channel', type=int, default=3, help='输入图像通道数(默认3)')
    parser.add_argument('--batch', type=int, default=1, help='批处理大小(默认1)')
    
    args = parser.parse_args()
    
    if not (args.input or args.output or args.params or args.structure or args.all):
        parser.print_help()
        sys.exit(1)
    
    if args.all:
        args.input = args.output = args.params = args.structure = True
    
    # 创建输入参数字典
    input_params = {
        'height': args.height,
        'width': args.width,
        'channel': args.channel,
        'batch': args.batch
    }
    
    analyze_onnx(
        args.model_path,
        show_input=args.input,
        show_output=args.output,
        show_params=args.params,
        show_structure=args.structure,
        input_params=input_params
    )

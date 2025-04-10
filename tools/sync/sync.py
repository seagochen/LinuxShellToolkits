#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import json
import shutil
import stat
import getpass
import paramiko

########################################
# 配置加载及通用工具函数
########################################

def load_config(config_file_path):
    """
    从指定的 JSON 文件加载配置
    """
    try:
        with open(config_file_path, "r", encoding="utf-8") as f:
            config = json.load(f)
        return config
    except Exception as e:
        print(f"加载配置文件出错: {e}")
        sys.exit(1)

def delete_existing_target(target_path):
    """
    删除目标路径下已存在的文件或目录
    """
    if os.path.exists(target_path):
        try:
            if os.path.isfile(target_path):
                os.remove(target_path)
            elif os.path.isdir(target_path):
                shutil.rmtree(target_path)
            print(f"已删除目标路径：{target_path}")
        except Exception as e:
            print(f"删除目标路径 {target_path} 失败: {e}")
            sys.exit(1)

########################################
# 本地同步部分（使用 shutil）
########################################

def local_sync(source_dir, sync_rules, target_dir):
    """
    本地同步：
    1. 遍历同步规则中的 include 路径（相对于 source_dir）
    2. 如果该路径不在 exclude 内，则进行同步（目录采用 copytree，文件采用 copy2）
    """
    includes = sync_rules.get("include", [])
    excludes = sync_rules.get("exclude", [])

    for relative_path in includes:
        # 如果相对路径以 exclude 中任一条目为前缀，则跳过
        if any(relative_path.startswith(exclude.rstrip("/")) for exclude in excludes):
            print(f"跳过排除路径：{relative_path}")
            continue

        src = os.path.join(source_dir, relative_path)
        dst = os.path.join(target_dir, relative_path)
        if not os.path.exists(src):
            print(f"源路径不存在：{src}")
            continue

        # 同步前先删除目标中已存在的对应文件或目录
        delete_existing_target(dst)
        if os.path.isdir(src):
            try:
                shutil.copytree(src, dst, dirs_exist_ok=True)
                print(f"同步目录成功: {src} -> {dst}")
            except Exception as e:
                print(f"同步目录失败 {src} -> {dst}: {e}")
        elif os.path.isfile(src):
            # 确保目标父目录存在
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            try:
                shutil.copy2(src, dst)
                print(f"同步文件成功: {src} -> {dst}")
            except Exception as e:
                print(f"同步文件失败 {src} -> {dst}: {e}")

########################################
# 远程同步部分（使用 paramiko 的 SFTP）
########################################

def sftp_delete_remote_item(sftp, remote_path):
    """
    删除远程路径，支持文件和目录（递归删除目录内容）
    """
    try:
        file_attr = sftp.stat(remote_path)
        if stat.S_ISDIR(file_attr.st_mode):
            # 如果是目录，递归删除内部所有内容
            for entry in sftp.listdir_attr(remote_path):
                entry_path = os.path.join(remote_path, entry.filename).replace("\\", "/")
                sftp_delete_remote_item(sftp, entry_path)
            sftp.rmdir(remote_path)
            print(f"删除远程目录：{remote_path}")
        else:
            sftp.remove(remote_path)
            print(f"删除远程文件：{remote_path}")
    except FileNotFoundError:
        print(f"远程路径 {remote_path} 不存在，跳过删除")
    except Exception as e:
        print(f"删除远程路径 {remote_path} 失败: {e}")

def sftp_mkdirs(sftp, remote_path):
    """
    递归在远程创建目录
    """
    dirs = []
    while len(remote_path) > 1:
        dirs.append(remote_path)
        remote_path, _ = os.path.split(remote_path)
    dirs = dirs[::-1]
    for directory in dirs:
        try:
            sftp.stat(directory)
        except IOError:
            try:
                sftp.mkdir(directory)
                print(f"创建远程目录：{directory}")
            except Exception as e:
                print(f"创建远程目录 {directory} 失败: {e}")
                sys.exit(1)

def sftp_put_file(sftp, local_file, remote_file):
    """
    上传单个文件到远程
    """
    remote_dir = os.path.dirname(remote_file)
    sftp_mkdirs(sftp, remote_dir)
    try:
        sftp.put(local_file, remote_file)
        print(f"上传文件成功: {local_file} -> {remote_file}")
    except Exception as e:
        print(f"上传文件 {local_file} 失败: {e}")

def sftp_put_dir(sftp, local_dir, remote_dir):
    """
    上传目录到远程：遍历本地目录，逐文件上传
    """
    for root, dirs, files in os.walk(local_dir):
        rel_path = os.path.relpath(root, local_dir)
        rel_path = "" if rel_path == "." else rel_path
        remote_path = os.path.join(remote_dir, rel_path).replace("\\", "/")
        sftp_mkdirs(sftp, remote_path)
        for file in files:
            local_file = os.path.join(root, file)
            remote_file = os.path.join(remote_path, file).replace("\\", "/")
            try:
                sftp.put(local_file, remote_file)
                print(f"上传文件成功: {local_file} -> {remote_file}")
            except Exception as e:
                print(f"上传文件 {local_file} 失败: {e}")

def remote_sync(source_dir, sync_rules, target_info):
    """
    远程同步：
    1. 根据目标信息（host、port、user、auth）建立 SSH 连接和 SFTP 会话
    2. 遍历同步规则中的 include 路径，上传文件或目录到远程目标目录
    """
    host = target_info.get("host")
    port = target_info.get("port", 22)
    user = target_info.get("user")
    auth = target_info.get("auth", {})
    password = auth.get("password")
    key_path = auth.get("key_path")
    target_dir = target_info.get("target_dir")

    # 建立 SSH 连接
    ssh_client = paramiko.SSHClient()
    ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        if key_path:
            ssh_client.connect(hostname=host, port=port, username=user, key_filename=key_path)
        else:
            # 如果未提供密码，则从命令行提示输入
            if not password:
                password = getpass.getpass(f"请输入 {user}@{host} 的SSH密码：")
            ssh_client.connect(hostname=host, port=port, username=user, password=password)
    except Exception as e:
        print(f"连接远程服务器 {host} 失败: {e}")
        return

    try:
        sftp = ssh_client.open_sftp()
    except Exception as e:
        print(f"建立远程 SFTP 连接失败: {e}")
        ssh_client.close()
        return

    includes = sync_rules.get("include", [])
    excludes = sync_rules.get("exclude", [])
    for relative_path in includes:
        if any(relative_path.startswith(exclude.rstrip("/")) for exclude in excludes):
            print(f"跳过排除路径：{relative_path}")
            continue

        local_path = os.path.join(source_dir, relative_path)
        # 远程路径：将 target_dir 与相对路径拼接
        remote_path = os.path.join(target_dir, relative_path).replace("\\", "/")
        if not os.path.exists(local_path):
            print(f"本地路径不存在：{local_path}")
            continue

        # 先删除远程目标中已存在的对应内容
        sftp_delete_remote_item(sftp, remote_path)
        if os.path.isdir(local_path):
            sftp_put_dir(sftp, local_path, remote_path)
        elif os.path.isfile(local_path):
            sftp_put_file(sftp, local_path, remote_path)

    sftp.close()
    ssh_client.close()
    print(f"远程同步到 {host}:{target_dir} 完成！")

########################################
# 主流程
########################################

def main(json_path="config.json"):
    # 这里指定配置文件路径，也可以通过命令行参数传入
    config_file = "unified_sync_config.json"
    config = load_config(config_file)

    source_dir = config.get("source_dir")
    if not source_dir or not os.path.exists(source_dir):
        print(f"源目录 {source_dir} 不存在，请检查配置。")
        sys.exit(1)
    sync_rules = config.get("sync_rules", {})
    targets = config.get("targets", [])
    if not targets:
        print("配置中未定义任何同步目标。")
        sys.exit(1)

    # 遍历目标列表，分别进行本地和远程同步
    for target in targets:
        target_type = target.get("type")
        if target_type == "local":
            target_dir = target.get("target_dir")
            if not target_dir:
                print("本地目标缺少 target_dir，跳过。")
                continue
            # 如果目标目录不存在，则创建
            if not os.path.exists(target_dir):
                print(f"本地目标目录 {target_dir} 不存在，创建中...")
                os.makedirs(target_dir, exist_ok=True)
            print(f"开始同步到本地目标：{target_dir}")
            local_sync(source_dir, sync_rules, target_dir)
        elif target_type == "remote":
            print(f"开始同步到远程目标：{target.get('host')}:{target.get('target_dir')}")
            remote_sync(source_dir, sync_rules, target)
        else:
            print(f"未知的目标类型：{target_type}")
    print("所有同步任务完成！")

if __name__ == "__main__":
    # 允许通过命令行参数指定配置文件路径
    if len(sys.argv) > 1:
        json_path = sys.argv[1]
    else:
        json_path = "config.json"
    
    # 调用主函数
    main(json_path)

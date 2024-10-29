import subprocess
import os
import sys

def execute_task(git_branch, repo_name):
     # 获取当前工作目录
     current_path = os.path.dirname(os.path.abspath(__file__))

     print("当前工作目录:", current_path)

     # # 获取上一级目录
     # parent_path = os.path.dirname(current_path)
     # print("上一级目录:", parent_path)

     file_name_list = ["auto_process.py"]
     for file_name in file_name_list:
         print(file_name)
         # 指定 Python 脚本的路径 此路径在pycharm执行会错误 但是Xcode执行必须这样写 因为Xcode是在项目目录下执行shell脚本的
         execute_path = current_path + '/' + file_name
         try:
             # 使用 subprocess 执行 Python 文件
             result = subprocess.run(['python3', execute_path, git_branch, repo_name], capture_output=True, text=True, check=True)
             # 输出脚本的标准输出
             print("输出:", result.stdout)

         except subprocess.CalledProcessError as e:
             print("脚本执行失败，错误信息:", e.stderr)

if __name__ == '__main__':
     git_branch = sys.argv[1]
     repo_name = sys.argv[2]
     execute_task(git_branch, repo_name)
     print(repo_name,git_branch)
     pass



import re
import subprocess
import os
import sys

def update_podspec_version(podspec_file):
    """
    更新本地spec文件
    """
    # 读取当前版本号
    with open(podspec_file, 'r') as file:
        content = file.read()

    # 使用正则表达式查找版本号
    version_match = re.search(r"s.version\s*=\s*'(\d+\.\d+\.\d+)'", content)
    if not version_match:
        print("Version not found in the podspec file.")
        return None

   # 处理version版本空格字符问题让文件保持一致
    space_str_list = re.findall(r'(?<=\S) +(?=\S)', version_match.group(0))
    space_str = space_str_list[0] if space_str_list[0] else ""

    current_version = version_match.group(1)
    print(f"Current version: {current_version}")

    # 解析版本号
    major, minor, patch = map(int, current_version.split('.'))
    # 升级补丁版本
    new_patch = patch + 1
    new_version = f"{major}.{minor}.{new_patch}"

    # 更新内容
    new_content = re.sub(r"s.version\s*=\s*'(\d+\.\d+\.\d+)'", f"s.version{space_str}= '{new_version}'", content)
    # 写入更新后的内容回 Podspec 文件
    with open(podspec_file, 'w') as file:
        file.write(new_content)
    print(f"Updated version to: {new_version}")
    return new_version

def git_commit_and_push(podspec_file, new_version, branch):
    """
    提交git
    """
    # 提交更改
    subprocess.run(["git", "add", "."], check=True)
    subprocess.run(["git", "commit", "-m", f"Bump version to {new_version}"], check=True)
    # 打标签
    subprocess.run(["git", "tag", f"{new_version}"], check=True)
    # 推送到远程
    subprocess.run(["git", "push", "origin", branch], check=True)
    subprocess.run(["git", "push", "origin", "--tags"], check=True)

def check_valid_podspec(podspec_file):
    """
    远程本地校验
    """
    try:
        subprocess.run(["pod", "lib", "lint", podspec_file, "--allow-warnings"], check=True)
        #subprocess.run(["pod", "spec", "lint", "--allow-warnings"],check=True)
    except subprocess.CalledProcessError as e:
        print(f"本地校验spec文件失败：{e}")

def publish_to_private_repo(podspec_file, repo_name):
    """
    发布到私有 CocoaPods 仓库
    """
    try:
        subprocess.run(["pod", "repo", "push", repo_name, podspec_file, "--allow-warnings"], check=True)
    except subprocess.CalledProcessError as e:
        print(f"发布到私有仓库失败: {e}")

def xcode_execute():
    """
    如果是从Xcode执行，因为命令来自项目内部，通常标准spec模板文件都在文件夹的最外层，文件夹差了一层，所以需要修改目录
    """
    # 获取上一级目录
    print("执行了xcode_execute")

    parent_dir = os.path.abspath(os.path.join('.', os.pardir))
    # 获取上一级目录下的所有文件
    files = os.listdir(parent_dir)
    podspec_file = next((file for file in files if file.endswith('.podspec')), None)
    print(podspec_file)
    # 获取上两级目录
    parent_of_parent_dir = os.path.abspath(os.path.join(parent_dir, '.'))
    print(parent_of_parent_dir)
    return parent_of_parent_dir + "/" + podspec_file

def target_file_exeute():
    """
    直接在项目根目录下执行
    """
    print("执行了target_file_exeute")
    # 获取当前目录
    current_directory = os.path.dirname(os.path.abspath(__file__))
    current_dir = current_directory#os.path.abspath('.')
    files = os.listdir(current_dir)
    podspec_file = next((file for file in files if file.endswith('.podspec')), None)
    print("~~~~ %s ~~~~"%podspec_file)
    return current_dir + "/" + podspec_file

def is_called_from_xcode():
    """
    检测是否是从Xcode执行
    """
    # Check for environment variables or arguments specific to Xcode
    if 'XCODE_VERSION_ACTUAL' in os.environ:
        return True
    # You can also check sys.argv for specific patterns or arguments passed by Xcode
    # if 'some_xcode_specific_argument' in sys.argv:
    #     return True
    return False

if __name__ == "__main__":
    os.environ['https_proxy'] = 'http://127.0.0.1:7890'
    os.environ['http_proxy'] = 'http://127.0.0.1:7890'
    os.environ['all_proxy'] = 'socks5://127.0.0.1:7890'

    # spec 文件名称
    podspec_file = xcode_execute() if is_called_from_xcode() else target_file_exeute()
    # 上传的分支
    branch = 'main'#sys.argv[1] if sys.argv[1] else "main"
    # 库的名称
    private_repo_name = 'Specs'#sys.argv[2] if sys.argv[2] else "AUCSpeces"
    # 更新版本号
    new_version = update_podspec_version(podspec_file)
    if new_version:
        # 提交并推送更改
        git_commit_and_push(podspec_file, new_version, branch)
        # 校验文件
        check_valid_podspec(podspec_file)
        # 发布到私有 CocoaPods 仓库
        publish_to_private_repo(podspec_file, private_repo_name)
        pass
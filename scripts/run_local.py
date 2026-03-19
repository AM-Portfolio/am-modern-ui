import sys
import subprocess
import os

# Get absolute path to the workspace root (am-modern-ui)
workspace_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def load_env():
    """Load environment variables from .env if it exists."""
    env_path = os.path.join(workspace_root, ".env")
    if os.path.exists(env_path):
        with open(env_path) as f:
            for line in f:
                if "=" in line and not line.strip().startswith("#"):
                    k, v = line.strip().split("=", 1)
                    os.environ[k] = v

def get_available_device():
    """Detect available flutter devices and return the best match."""
    try:
        is_windows = os.name == "nt"
        result = subprocess.run(["flutter", "devices"], capture_output=True, text=True, shell=is_windows)
        output = result.stdout.lower()
        
        if "chrome" in output:
            return "chrome"
        elif "edge" in output:
            return "edge"
        else:
            # Fallback for headless/container environments to run as web-server
            # User can then open the URL in Edge/Chrome on their host machine
            return "web-server"
    except Exception:
        return "chrome" # Default fallback

def run_with_logging(cmd, cwd, env, log_name):
    """Run a command streaming output to terminal and a log file simultaneously."""
    logs_dir = os.path.join(workspace_root, "logs")
    os.makedirs(logs_dir, exist_ok=True)
    log_file = os.path.join(logs_dir, f"{log_name}.log")
    
    print(f"📖 Logging output to {log_file}")
    with open(log_file, "a") as f:
        f.write("\n\n--- NEW EXECUTION ---\n")
        is_windows = os.name == "nt"
        p = subprocess.Popen(cmd, cwd=cwd, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, shell=is_windows)
        
        try:
            for line in p.stdout:
                sys.stdout.write(line)
                sys.stdout.flush()
                f.write(line)
                f.flush()
        except KeyboardInterrupt:
             p.terminate()
        p.wait()
    return p.returncode == 0

def run_flutter_cmd(package, command):
    """Run a flutter command inside a package subdirectory."""
    # Load environment variables first
    load_env()
    
    package_dir = os.path.join(workspace_root, package)
    if not os.path.exists(package_dir):
        print(f"❌ Error: Package directory '{package}' not found in {workspace_root}")
        return False
        
    # Append port if starting the app
    is_interactive = command.startswith("run")
    if is_interactive:
        # Replace default chrome with available device
        if "-d chrome" in command:
            device = get_available_device()
            if device != "chrome":
                print(f"💡 Default device 'chrome' not found. Using '{device}' instead.")
                command = command.replace("-d chrome", f"-d {device}")
                
        port = os.getenv("FLUTTER_WEB_PORT")
        if port:
            command += f" --web-port={port}"

    print(f"🚀 Running 'flutter {command}' in {package}...")
    is_windows = os.name == "nt"
    env = dict(os.environ)

    if is_interactive:
        try:
            result = subprocess.run(["flutter"] + command.split(), cwd=package_dir, shell=is_windows)
            return result.returncode == 0
        except Exception as e:
            print(f"❌ Execution failed: {e}")
            return False
    else:
        log_safe_name = package.replace("/", "-").replace("\\", "-")
        cmd_full = ["flutter"] + command.split()
        return run_with_logging(cmd_full, cwd=package_dir, env=env, log_name=f"{log_safe_name}")

def get_args():
    if len(sys.argv) < 2:
        print("❌ Error: Missing package name argument.")
        print("Usage: poetry run <cmd> <package_name>")
        sys.exit(1)
    package = sys.argv[1]
    
    alias_map = {
        "app": "am_app",
        "auth": "am_auth_ui",
        "design": "am_design_system",
        "trade": "am_trade_ui",
        "portfolio": "am_portfolio_ui",
        "market": "am_analysis_ui",
        "diagnostic": "am_diagnostic_ui",
        "user": "am_user_ui"
    }
    resolved = alias_map.get(package.lower(), package)
    
    # Optional logic to automatically append '/live' if standalone target exists
    target_dir = os.path.join(workspace_root, resolved)
    if os.path.exists(os.path.join(target_dir, "live")):
        return os.path.join(resolved, "live")
    return resolved

# --- Generic handlers ---

def run_package():
    package = get_args()
    run_flutter_cmd(package, "run -d chrome")

def build_package():
    package = get_args()
    run_flutter_cmd(package, "build web")

def clean_package():
    package = get_args()
    run_flutter_cmd(package, "clean")

def get_package():
    package = get_args()
    run_flutter_cmd(package, "pub get")

def generate_package():
    package = get_args()
    # Runs build_runner code generation
    run_flutter_cmd(package, "pub run build_runner build --delete-conflicting-outputs")

# --- Short Aliases ---

def run_app():
    run_flutter_cmd("am_app", "run -d chrome")

def run_auth():
    run_flutter_cmd("am_auth_ui/live", "run -d chrome")

def run_design():
    run_flutter_cmd("am_design_system", "run -d chrome")

def run_trade():
    run_flutter_cmd("am_trade_ui/live", "run -d chrome")

def run_portfolio():
    run_flutter_cmd("am_portfolio_ui/live", "run -d chrome")

def run_market():
    run_flutter_cmd("am_analysis_ui/live", "run -d chrome")

def run_ai():
    run_flutter_cmd("am_ai_ui/live", "run -d chrome")

# --- Utility ---

def all_pub_get():
    """Run flutter pub get on all subdirectories containing pubspec.yaml"""
    print("🚀 Running 'flutter pub get' on all modules...")
    for item in os.listdir(workspace_root):
        item_path = os.path.join(workspace_root, item)
        if os.path.isdir(item_path):
            # Check main module
            if os.path.exists(os.path.join(item_path, "pubspec.yaml")):
                run_flutter_cmd(item, "pub get")
                print("-" * 40)
            # Check standalone live app
            live_path = os.path.join(item_path, "live")
            if os.path.exists(os.path.join(live_path, "pubspec.yaml")):
                run_flutter_cmd(os.path.join(item, "live"), "pub get")
                print("-" * 40)
    print("✅ Finished resolving all packages.")

def all_build_runner():
    """Run flutter pub run build_runner build on all subdirectories containing pubspec.yaml"""
    print("🚀 Running 'flutter pub run build_runner build' on all modules...")
    for item in os.listdir(workspace_root):
        item_path = os.path.join(workspace_root, item)
        if os.path.isdir(item_path):
            # Check main module
            if os.path.exists(os.path.join(item_path, "pubspec.yaml")):
                run_flutter_cmd(item, "pub run build_runner build --delete-conflicting-outputs")
                print("-" * 40)
            # Check standalone live app
            live_path = os.path.join(item_path, "live")
            if os.path.exists(os.path.join(live_path, "pubspec.yaml")):
                run_flutter_cmd(os.path.join(item, "live"), "pub run build_runner build --delete-conflicting-outputs")
                print("-" * 40)
    print("✅ Finished building all packages.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python scripts/run_local.py <command> [argument]")
        print("Commands: run, build, clean, get, app, auth, design, all-get")
        sys.exit(1)
        
    cmd = sys.argv[1]
    # Adjust sys.argv for handlers that parse it
    sys.argv.pop(1)

    commands = {
        "run": run_package,
        "build": build_package,
        "clean": clean_package,
        "get": get_package,
        "generate": generate_package,
        "app": run_app,
        "auth": run_auth,
        "design": run_design,
        "trade": run_trade,
        "portfolio": run_portfolio,
        "market": run_market,
        "ai": run_ai,
        "all-get": all_pub_get,
        "all-generate": all_build_runner,
    }

    if cmd in commands:
        commands[cmd]()
    else:
        print(f"❌ Unknown command: {cmd}")
        print(f"Available: {', '.join(commands.keys())}")

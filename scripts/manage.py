import sys
import os
import subprocess

# Get absolute path to the workspace root (am-modern-ui)
workspace_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ALIAS_MAP = {
    "app": "am_app",
    "auth": "am_auth_ui",
    "design": "am_design_system",
    "common": "am_common",
    "library": "am_library",
    "trade": "am_trade_ui",
    "portfolio": "am_portfolio_ui",
    "dashboard": "am_dashboard_ui",
    "diagnostic": "am_diagnostic_ui",
    "user": "am_user_ui",
    "ai": "am_ai_ui",
    "doc": "am_doc_intelligence_ui",
    "market": "am_market/ui",
    "subscription": "am_subscription_ui",
    "market-sdk": "am_market/sdk",
    "market-common": "am_market/common",
    "market-dev": "am_market/dev",
    "analysis": "am_analysis/ui",
    "analysis-sdk": "am_analysis/sdk",
    "analysis-common": "am_analysis/common",
}

DEFAULT_PORTS = {
    "am_app": "9000",
    "am_diagnostic_ui": "9001",
    "am_market/ui": "8081",
    "am_portfolio_ui": "8082",
    "am_trade_ui": "8083",
    "am_auth_ui": "9002",
    "am_subscription_ui": "9007",
}

# Ordered list of dependencies to run clean/get/gen across submodules
ALL_PACKAGES = [
    "am_common",
    "am_design_system",
    "am_library",
    "am_auth_ui",
    "am_trade_ui",
    "am_portfolio_ui",
    "am_dashboard_ui",
    "am_diagnostic_ui",
    "am_ai_ui",
    "am_doc_intelligence_ui",
    "am_subscription_ui",
    "am_user_ui",
    "am_market/sdk",
    "am_market/common",
    "am_market/ui",
    "am_market/dev",
    "am_analysis/sdk",
    "am_analysis/common",
    "am_analysis/ui",
    "am_app"
]

def load_env(env_name):
    """Load environment variables from .env.<env_name> if it exists."""
    env_vars = {}
    if not env_name:
        env_name = "local"
        
    env_file = f".env.{env_name}"
    env_path = os.path.join(workspace_root, env_file)
    
    # Fallback to standard .env
    if not os.path.exists(env_path):
        env_path = os.path.join(workspace_root, ".env")
        
    if os.path.exists(env_path):
        print(f"[Env] Loading environment configuration: {os.path.basename(env_path)}")
        with open(env_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if "=" in line:
                    k, v = line.split("=", 1)
                    env_vars[k.strip()] = v.strip()
    else:
        print(f"[Warning] Environment config file not found: {env_file}. Using defaults.")
    return env_vars

def get_available_device():
    """Prefer Chrome/Edge so Flutter launches the browser; fall back to web-server."""
    return "web-server"

def run_cmd(package, cmd_parts, env_vars=None):
    """Run a terminal command inside the specified package directory."""
    package_dir = os.path.join(workspace_root, package)
    if not os.path.exists(package_dir):
        print(f"[Error] Directory '{package}' not found in {workspace_root}")
        return False
        
    is_windows = os.name == "nt"
    env = dict(os.environ)
    if env_vars:
        env.update(env_vars)
        
    print(f"\n[Location] {package}")
    print(f"[Command] {' '.join(cmd_parts)}")
    
    is_run = "run" in cmd_parts
    if is_run:
        # For run commands, execute interactively so input streams work
        try:
            result = subprocess.run(cmd_parts, cwd=package_dir, env=env, shell=is_windows)
            return result.returncode == 0
        except Exception as e:
            print(f"[Error] Execution failed: {e}")
            return False
    else:
        # Stream logs to stdout and a file
        logs_dir = os.path.join(workspace_root, "logs")
        os.makedirs(logs_dir, exist_ok=True)
        log_name = package.replace("/", "-").replace("\\", "-")
        log_file = os.path.join(logs_dir, f"{log_name}.log")
        
        print(f"[Logs] Streaming output to logs/{log_name}.log")
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(f"\n\n--- EXECUTION: {' '.join(cmd_parts)} ---\n")
            p = subprocess.Popen(cmd_parts, cwd=package_dir, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", shell=is_windows)
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

def resolve_package(pkg_name):
    if not pkg_name:
        print("[Error] Missing package name.")
        sys.exit(1)
    resolved = ALIAS_MAP.get(pkg_name.lower(), pkg_name)
    
    # Check if a standalone 'live' app exists under this package directory
    target_dir = os.path.join(workspace_root, resolved)
    if os.path.exists(os.path.join(target_dir, "live")):
        resolved = os.path.join(resolved, "live")
        
    return resolved

def parse_cli_args(argv):
    """Split positional args and boot-trace flags from sys.argv[1:]."""
    flags = set()
    positional = []
    for arg in argv:
        if arg == "--boot-trace":
            flags.add("boot_trace")
        elif arg == "--no-boot-trace":
            flags.add("no_boot_trace")
        elif arg.startswith("-"):
            print(f"[Error] Unknown option: {arg}")
            sys.exit(1)
        else:
            positional.append(arg)
    return positional, flags


def resolve_boot_trace(env_vars, flags, action):
    """Resolve boot trace: flags > AM_BOOT_TRACE env > default (on for run, off for build)."""
    if "boot_trace" in flags:
        return True
    if "no_boot_trace" in flags:
        return False
    env_val = env_vars.get("AM_BOOT_TRACE", "").strip().lower()
    if env_val in ("false", "0", "no"):
        return False
    if env_val in ("true", "1", "yes"):
        return True
    return action == "run"


def construct_dart_defines(env_vars, boot_trace):
    defines = []
    for k, v in env_vars.items():
        if k.startswith("AM_") and k != "AM_BOOT_TRACE":
            defines.append(f"--dart-define={k}={v}")
    defines.append(f"--dart-define=AM_BOOT_TRACE={'true' if boot_trace else 'false'}")
    return defines

def get_web_port(package, env_vars):
    if "FLUTTER_WEB_PORT" in env_vars:
        return env_vars["FLUTTER_WEB_PORT"]
    base_package = package.replace("/live", "").replace("\\live", "")
    return DEFAULT_PORTS.get(base_package, "9000")

def handle_run(pkg, env_name, flags):
    package = resolve_package(pkg)
    env_vars = load_env(env_name)
    env_vars['AM_ENV'] = env_name
    boot_trace = resolve_boot_trace(env_vars, flags, action="run")
    defines = construct_dart_defines(env_vars, boot_trace)

    device = get_available_device()
    port = get_web_port(package, env_vars)

    launch_url = f"http://localhost:{port}/login"
    if boot_trace:
        launch_url += "?bootTrace=1"
        print("[BootTrace] Enabled — console timing + summary after load")
        print(f"[BootTrace] Launch URL: {launch_url}")

    cmd = [
        "flutter", "run", "-d", device,
        f"--web-port={port}",
        "--no-web-resources-cdn",
        f"--web-launch-url={launch_url}",
    ] + defines
    run_cmd(package, cmd, env_vars)


def handle_build(pkg, env_name, flags):
    package = resolve_package(pkg)
    env_vars = load_env(env_name)
    env_vars['AM_ENV'] = env_name
    boot_trace = resolve_boot_trace(env_vars, flags, action="build")
    defines = construct_dart_defines(env_vars, boot_trace)

    if boot_trace:
        print("[BootTrace] Enabled in release build — use ?bootTrace=1 in browser to view trace")

    cmd = ["flutter", "build", "web", "--release", "--no-wasm-dry-run", "--no-web-resources-cdn"] + defines
    run_cmd(package, cmd, env_vars)

def handle_clean(pkg):
    package = resolve_package(pkg)
    run_cmd(package, ["flutter", "clean"])

def handle_get(pkg):
    package = resolve_package(pkg)
    run_cmd(package, ["flutter", "pub", "get"])

def handle_gen(pkg):
    package = resolve_package(pkg)
    cmd = ["dart", "run", "build_runner", "build", "--delete-conflicting-outputs"]
    run_cmd(package, cmd)

def handle_test(pkg):
    package = resolve_package(pkg)
    run_cmd(package, ["flutter", "test"])

def handle_clean_all():
    print("[Clean] Cleaning all submodules...")
    for pkg in ALL_PACKAGES:
        run_cmd(pkg, ["flutter", "clean"])
    print("[Clean] Finished cleaning all submodules.")

def handle_get_all():
    print("[Deps] Running 'flutter pub get' in all submodules...")
    for pkg in ALL_PACKAGES:
        run_cmd(pkg, ["flutter", "pub", "get"])
    print("[Deps] Finished resolving all dependencies.")

def handle_gen_all():
    print("[Gen] Generating code via build_runner for all submodules...")
    for pkg in ALL_PACKAGES:
        pubspec_path = os.path.join(workspace_root, pkg, "pubspec.yaml")
        if os.path.exists(pubspec_path):
            with open(pubspec_path, "r", encoding="utf-8") as f:
                content = f.read()
                if "build_runner" in content:
                    run_cmd(pkg, ["dart", "run", "build_runner", "build", "--delete-conflicting-outputs"])
    print("[Gen] Finished generating code.")

def handle_test_all():
    print("[Test] Running tests in all submodules...")
    for pkg in ALL_PACKAGES:
        pubspec_path = os.path.join(workspace_root, pkg, "pubspec.yaml")
        if os.path.exists(pubspec_path):
            test_dir = os.path.join(workspace_root, pkg, "test")
            if os.path.exists(test_dir):
                run_cmd(pkg, ["flutter", "test"])
    print("[Test] Finished testing all submodules.")

def print_help():
    print("\nAM Modern UI Master Runner CLI")
    print("Usage: python scripts/manage.py <action> [package] [env] [options]")
    print("\nActions:")
    print("  run <package> [env]       Run a module in development mode (env defaults to local)")
    print("  build <package> [env]     Build web artifacts for a module (env defaults to local)")
    print("  clean <package>           Clean a module")
    print("  get <package>             Fetch dependencies for a module")
    print("  gen <package>             Run build_runner code generation for a module")
    print("  test <package>            Run unit tests for a module")
    print("  clean-all                 Clean all modules")
    print("  get-all                   Run pub get in all modules")
    print("  gen-all                   Run build_runner in all modules")
    print("  test-all                  Run tests in all modules")
    print("\nOptions:")
    print("  --boot-trace              Enable startup timing trace (default: on for run, off for build)")
    print("  --no-boot-trace           Disable startup timing trace")
    print("  (or set AM_BOOT_TRACE=true|false in .env.<env>)")
    print("\nPackages:")
    print(f"  {', '.join(ALIAS_MAP.keys())}")
    print("\nEnvironments:")
    print("  local, dev, preprod, prod")
    print("\nExamples:")
    print("  python scripts/manage.py run app local")
    print("  python scripts/manage.py run app preprod --boot-trace")
    print("  python scripts/manage.py run trade dev --no-boot-trace")
    print("  python scripts/manage.py build app prod --boot-trace")
    print("  python scripts/manage.py gen common")
    sys.exit(1)

if __name__ == "__main__":
    positional, flags = parse_cli_args(sys.argv[1:])

    if not positional:
        print_help()

    action = positional[0].lower()

    if action == "clean-all":
        handle_clean_all()
    elif action == "get-all":
        handle_get_all()
    elif action == "gen-all":
        handle_gen_all()
    elif action == "test-all":
        handle_test_all()
    else:
        if len(positional) < 2:
            print(f"[Error] Action '{action}' requires a package name.")
            print_help()

        pkg = positional[1]
        env = positional[2] if len(positional) > 2 else "local"

        if action == "run":
            handle_run(pkg, env, flags)
        elif action == "build":
            handle_build(pkg, env, flags)
        elif action == "clean":
            handle_clean(pkg)
        elif action == "get":
            handle_get(pkg)
        elif action == "gen":
            handle_gen(pkg)
        elif action == "test":
            handle_test(pkg)
        else:
            print(f"[Error] Unknown action '{action}'")
            print_help()

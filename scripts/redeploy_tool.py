import os
import sys
import subprocess
import json
from rich.console import Console
from rich.prompt import Prompt, IntPrompt
from rich.panel import Panel
from rich.table import Table

console = Console()

# Configuration
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
KUBECONFIG = os.path.abspath(os.path.join(SCRIPT_DIR, "../../am-infra/k8s/kubeconfig.vps"))
CONTEXT = "kind-am-preprod"
ENVIRONMENTS = {
    "1": {"name": "preprod-am-modern-ui", "namespace": "am-apps-preprod"},
    "2": {"name": "prod-am-modern-ui", "namespace": "am-apps-prod"}
}
IMAGE_BASE = "ghcr.io/am-portfolio/am-modern-ui"

def run_command(cmd):
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        console.print(f"[bold red]Error running command:[/bold red] {e.stderr}")
        return None

def get_current_image(namespace):
    cmd = [
        "kubectl", "--kubeconfig", KUBECONFIG, "--context", CONTEXT,
        "get", "deployment", "am-modern-ui", "-n", namespace,
        "-o", "jsonpath={.spec.template.spec.containers[0].image}"
    ]
    return run_command(cmd)

def get_recent_tags(namespace):
    # Try to get from ReplicaSets
    cmd = [
        "kubectl", "--kubeconfig", KUBECONFIG, "--context", CONTEXT,
        "get", "rs", "-n", namespace, "-l", "app.kubernetes.io/name=am-modern-ui",
        "-o", "jsonpath={.items[*].spec.template.spec.containers[0].image}"
    ]
    output = run_command(cmd)
    if not output:
        return []
    
    images = output.split()
    tags = [img.split(":")[-1] for img in images if ":" in img]
    return sorted(list(set(tags)), reverse=True)[:5]

def redeploy(namespace, tag):
    image = f"{IMAGE_BASE}:{tag}"
    console.print(f"\n[bold cyan]Redeploying to {namespace} with image: {image}...[/bold cyan]")
    
    cmd = [
        "kubectl", "--kubeconfig", KUBECONFIG, "--context", CONTEXT,
        "set", "image", "deployment/am-modern-ui", f"am-modern-ui={image}",
        "-n", namespace
    ]
    if run_command(cmd) is not None:
        console.print("[bold green]Success! Patching deployment...[/bold green]")
        
        # Trigger rollout restart if tag is 'latest' or same as current
        # (Though set image usually handles it, sometimes we want a fresh pod)
        console.print("[yellow]Triggering rollout restart to ensure fresh pod...[/yellow]")
        restart_cmd = [
            "kubectl", "--kubeconfig", KUBECONFIG, "--context", CONTEXT,
            "rollout", "restart", "deployment/am-modern-ui", "-n", namespace
        ]
        run_command(restart_cmd)
        
        console.print("[bold green]Rollout started. Monitoring status...[/bold green]")
        status_cmd = [
            "kubectl", "--kubeconfig", KUBECONFIG, "--context", CONTEXT,
            "rollout", "status", "deployment/am-modern-ui", "-n", namespace
        ]
        subprocess.run(status_cmd)
    else:
        console.print("[bold red]Redeployment failed.[/bold red]")

def main():
    if not os.path.exists(KUBECONFIG):
        console.print(f"[bold red]Error:[/bold red] Kubeconfig not found at {KUBECONFIG}")
        sys.exit(1)
    
    console.clear()
    console.print(Panel("[bold magenta]AM Modern UI Redeployment Tool[/bold magenta]", expand=False))
    
    # 1. Environment Selection
    table = Table(title="Available Environments")
    table.add_column("ID", style="cyan")
    table.add_column("Environment Name", style="green")
    table.add_column("Namespace", style="yellow")
    
    for eid, info in ENVIRONMENTS.items():
        table.add_row(eid, info["name"], info["namespace"])
    
    console.print(table)
    choice = Prompt.ask("Select environment ID", choices=list(ENVIRONMENTS.keys()), default="1")
    selected_env = ENVIRONMENTS[choice]
    
    # 2. Image Tag Selection
    current_image = get_current_image(selected_env["namespace"])
    console.print(f"\n[bold]Current image:[/bold] [yellow]{current_image}[/yellow]")
    
    recent_tags = get_recent_tags(selected_env["namespace"])
    
    console.print("\n[bold cyan]Select Image Tag:[/bold cyan]")
    tag_options = {}
    idx = 1
    for tag in recent_tags:
        tag_options[str(idx)] = tag
        console.print(f"  {idx}. {tag}")
        idx += 1
    
    tag_options[str(idx)] = "latest"
    console.print(f"  {idx}. latest")
    idx += 1
    
    tag_options[str(idx)] = "custom"
    console.print(f"  {idx}. Enter custom tag")
    
    tag_choice = Prompt.ask("Select tag option", choices=list(tag_options.keys()), default=str(idx-1))
    selected_tag = tag_options[tag_choice]
    
    if selected_tag == "custom":
        selected_tag = Prompt.ask("Enter custom tag name")
    
    # 3. Confirmation
    if Prompt.ask(f"\n[bold red]Confirm redeploy to {selected_env['namespace']} with tag {selected_tag}?[/bold red] (y/n)", choices=["y", "n"], default="n") == "y":
        redeploy(selected_env["namespace"], selected_tag)
    else:
        console.print("[yellow]Cancelled.[/yellow]")

if __name__ == "__main__":
    main()

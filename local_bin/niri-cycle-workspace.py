#!/usr/bin/env python3
import json, sys, subprocess

def cycle_workspace(direction):
    try:
        out = subprocess.check_output(["niri", "msg", "-j", "workspaces"]).decode()
        workspaces = json.loads(out)
        if not workspaces:
            return
        
        # Sort workspaces by idx
        workspaces.sort(key=lambda w: w["idx"])
        
        focused = next((w for w in workspaces if w.get("is_focused")), None)
        if not focused:
            return
        
        current_idx = focused["idx"]
        min_idx = workspaces[0]["idx"]
        max_idx = workspaces[-1]["idx"]
        
        if direction == "prev" or direction == "up":
            if current_idx <= min_idx:
                target_idx = max_idx
            else:
                target_idx = current_idx - 1
        elif direction == "next" or direction == "down":
            if current_idx >= max_idx:
                target_idx = min_idx
            else:
                target_idx = current_idx + 1
        else:
            return

        subprocess.call(["niri", "msg", "action", "focus-workspace", str(target_idx)])
    except Exception as e:
        # Fallback to standard Niri workspace focus
        if direction in ["prev", "up"]:
            subprocess.call(["niri", "msg", "action", "focus-workspace-up"])
        else:
            subprocess.call(["niri", "msg", "action", "focus-workspace-down"])

if __name__ == "__main__":
    dir_arg = sys.argv[1] if len(sys.argv) > 1 else "next"
    cycle_workspace(dir_arg)

import subprocess

# Function to get the current desktop number
def get_current_desktop():
    output = subprocess.check_output(["wmctrl", "-d"]).decode("utf-8")
    for line in output.splitlines():
        if "*" in line:
            return int(line.split()[0])
    return 0

# Function to get the total number of desktops
def get_total_desktops():
    output = subprocess.check_output(["wmctrl", "-d"]).decode("utf-8")
    return len(output.splitlines())

# Function to switch to a specific desktop
def switch_to_desktop(desktop_number):
    subprocess.run(["wmctrl", "-s", str(desktop_number)])

# Main logic
current_desktop = get_current_desktop()
total_desktops = get_total_desktops()
next_desktop = (current_desktop + 1) % total_desktops  # Loop to the first desktop if at the last one

switch_to_desktop(next_desktop)

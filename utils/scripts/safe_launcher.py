#!/usr/bin/env python3
import sys
import os
import subprocess
import configparser

def launch_app(app_name):
    search_dirs = [
        os.path.expanduser('~/.local/share/applications'),
        '/usr/share/applications',
        '/var/lib/flatpak/exports/share/applications'
    ]

    target_app = app_name.lower()
    best_match_exec = None

    for d in search_dirs:
        if not os.path.exists(d): continue
        for filename in os.listdir(d):
            if filename.endswith('.desktop'):
                filepath = os.path.join(d, filename)
                try:
                    config = configparser.ConfigParser(interpolation=None)
                    config.read(filepath)
                    if 'Desktop Entry' in config:
                        name = config['Desktop Entry'].get('Name', '').lower()
                        if target_app in name:
                            best_match_exec = config['Desktop Entry'].get('Exec')
                            break
                except Exception:
                    continue
        if best_match_exec:
            break

    if best_match_exec:
        cmd_parts = ["app2unit -- "] + [p for p in best_match_exec.split() if not p.startswith('%')]
        try:
            subprocess.Popen(cmd_parts, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
            print(f"Successfully launched: {app_name}")
            return
        except Exception as e:
            print(f"Error launching {app_name}: {e}")
            return

    print(f"Error: Application '{app_name}' not found.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: safe_launcher.py <app_name>")
        sys.exit(1)
    launch_app(" ".join(sys.argv[1:]))
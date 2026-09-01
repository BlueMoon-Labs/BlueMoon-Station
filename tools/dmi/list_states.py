"""Print icon state names from DMI files. Usage: python list_states.py <path_or_dir>"""
import os
import sys

# Allow running from tools/dmi or repo root
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dmi import Dmi

def list_dmi(path):
    if os.path.isfile(path) and path.lower().endswith('.dmi'):
        try:
            d = Dmi.from_file(path)
            names = [s.name if s.name else '(default)' for s in d.states]
            print(f"{path}: {names}")
        except Exception as e:
            print(f"{path}: ERROR {e}")
        return
    for root, _, files in os.walk(path):
        for f in sorted(files):
            if f.lower().endswith('.dmi'):
                list_dmi(os.path.join(root, f))

if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), '..', '..', 'icons', 'obj', 'hellgate')
    list_dmi(target)

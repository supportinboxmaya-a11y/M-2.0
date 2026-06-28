"""
Maya 2.0 - Safe Update System
--------------------------------
Update করার আগে automatically backup নেয়।
Problem হলে instantly rollback করে।

Usage:
  python safe_update.py backup          # Manual backup
  python safe_update.py restore         # Restore last backup  
  python safe_update.py restore 2       # Restore specific backup
  python safe_update.py list            # List all backups
  python safe_update.py status          # Check current status
"""

import os
import sys
import json
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

BASE_DIR = Path(__file__).parent
BACKUP_DIR = BASE_DIR / "storage" / "backups"
BACKUP_DIR.mkdir(parents=True, exist_ok=True)

EXCLUDE = {".git", "__pycache__", "storage", "workspace", ".env", "*.pyc", "*.db"}

def is_excluded(path: str) -> bool:
    for ex in EXCLUDE:
        if ex.startswith("*"):
            if path.endswith(ex[1:]):
                return True
        elif ex in path:
            return True
    return False

def backup(label: str = "") -> str:
    """Current state backup নেয়।"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    name = f"backup_{timestamp}"
    if label:
        name += f"_{label.replace(' ', '_')}"
    
    backup_path = BACKUP_DIR / name
    backup_path.mkdir(parents=True, exist_ok=True)
    
    count = 0
    for item in BASE_DIR.rglob("*"):
        if item.is_file() and not is_excluded(str(item)):
            rel = item.relative_to(BASE_DIR)
            dst = backup_path / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(item, dst)
            count += 1
    
    # Metadata save
    meta = {
        "name": name,
        "timestamp": timestamp,
        "label": label or "auto",
        "files": count,
        "git_commit": _get_git_commit()
    }
    (backup_path / "BACKUP_META.json").write_text(json.dumps(meta, indent=2))
    
    print(f"Backup created: {name} ({count} files)")
    return name

def restore(index: int = 0) -> bool:
    """Last backup থেকে restore করে।"""
    backups = _list_backups()
    
    if not backups:
        print("No backups found! Run: python safe_update.py backup")
        return False
    
    if index >= len(backups):
        print(f"Invalid index. Available: 0 to {len(backups)-1}")
        return False
    
    target = backups[index]
    print(f"\nRestoring from: {target.name}")
    
    # Restore করার আগে current state backup নিই
    print("Saving current state before restore...")
    backup("pre_restore")
    
    # Files restore
    count = 0
    for src in target.rglob("*"):
        if src.name == "BACKUP_META.json" or src.is_dir():
            continue
        rel = src.relative_to(target)
        dst = BASE_DIR / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        count += 1
    
    print(f"Restored {count} files from {target.name}")
    print("Maya is ready. Run: python start.py")
    return True

def list_backups():
    """সব backups দেখায়।"""
    backups = _list_backups()
    
    if not backups:
        print("No backups found.")
        return
    
    print(f"\nAvailable backups ({len(backups)}):")
    print("-" * 60)
    for i, b in enumerate(backups):
        meta_file = b / "BACKUP_META.json"
        if meta_file.exists():
            meta = json.loads(meta_file.read_text())
            print(f"  [{i}] {meta['name']}")
            print(f"       Time: {meta['timestamp']} | Files: {meta['files']} | Label: {meta['label']}")
        else:
            print(f"  [{i}] {b.name}")
    print("-" * 60)
    print("To restore: python safe_update.py restore <index>")

def status():
    """Current system status।"""
    backups = _list_backups()
    git_commit = _get_git_commit()
    
    print("\nMaya 2.0 System Status")
    print("-" * 40)
    print(f"Base directory: {BASE_DIR}")
    print(f"Git commit: {git_commit}")
    print(f"Total backups: {len(backups)}")
    if backups:
        latest = backups[0]
        meta_file = latest / "BACKUP_META.json"
        if meta_file.exists():
            meta = json.loads(meta_file.read_text())
            print(f"Latest backup: {meta['name']} ({meta['timestamp']})")
    print("-" * 40)

def safe_update(update_func, label: str = "before_update"):
    """
    Update করার আগে backup নেয়।
    Problem হলে automatically rollback করে।
    
    Usage:
        from safe_update import safe_update
        
        def my_update():
            # your update code here
            pass
        
        safe_update(my_update, "my update label")
    """
    print(f"Creating backup before update: {label}")
    backup_name = backup(label)
    
    try:
        print("Running update...")
        update_func()
        print("Update successful!")
        return True
    except Exception as e:
        print(f"Update failed: {e}")
        print("Rolling back to previous state...")
        backups = _list_backups()
        for i, b in enumerate(backups):
            if b.name == backup_name:
                restore(i)
                break
        print("Rollback complete! System restored to previous state.")
        return False

def _list_backups():
    """Backups list করে (newest first)।"""
    backups = sorted(
        [d for d in BACKUP_DIR.iterdir() if d.is_dir()],
        key=lambda x: x.stat().st_mtime,
        reverse=True
    )
    return backups

def _get_git_commit():
    """Current git commit hash।"""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, cwd=BASE_DIR
        )
        return result.stdout.strip()
    except:
        return "unknown"

if __name__ == "__main__":
    args = sys.argv[1:]
    
    if not args or args[0] == "backup":
        label = args[1] if len(args) > 1 else ""
        backup(label)
    
    elif args[0] == "restore":
        idx = int(args[1]) if len(args) > 1 else 0
        restore(idx)
    
    elif args[0] == "list":
        list_backups()
    
    elif args[0] == "status":
        status()
    
    else:
        print(__doc__)

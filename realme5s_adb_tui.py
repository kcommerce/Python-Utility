#!/usr/bin/env python3
"""
Realme 5s (RMX1925) - Safe ADB Text UI
Requires: Python 3 and Android Platform Tools (adb)
Works on macOS, Linux, and Windows terminals.

This tool does NOT root the phone, uninstall apps, factory-reset, or run
Xiaomi/MIUI package commands. Review every package before disabling it.
"""

import json
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

APP_DIR = Path.home() / ".realme5s_adb_tool"
BACKUP_FILE = APP_DIR / "disabled_by_this_tool.json"
REPORT_FILE = APP_DIR / "device_report.txt"

# Critical packages/components that this tool refuses to disable.
# This is a conservative guard, not a complete Android safety database.
BLOCKED_EXACT = {
    "android",
    "com.android.systemui",
    "com.android.settings",
    "com.android.phone",
    "com.android.server.telecom",
    "com.android.packageinstaller",
    "com.google.android.packageinstaller",
    "com.google.android.gms",
    "com.google.android.gsf",
    "com.android.providers.settings",
    "com.android.providers.telephony",
    "com.android.providers.media",
    "com.android.permissioncontroller",
    "com.google.android.permissioncontroller",
    "com.android.launcher3",
}
BLOCKED_PARTS = (
    "launcher", "systemui", "packageinstaller", "permissioncontroller",
    "telephony", "telecom", "providers.settings", "inputmethod",
    "keyguard", "vending", "gms", "gsf",
)

def run_adb(args, timeout=45):
    """Run adb and return (returncode, stdout, stderr)."""
    cmd = ["adb"] + list(args)
    try:
        p = subprocess.run(
            cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=timeout
        )
        return p.returncode, p.stdout.strip(), p.stderr.strip()
    except subprocess.TimeoutExpired:
        return 124, "", "Command timed out."
    except FileNotFoundError:
        return 127, "", "adb not found. Install Android Platform Tools and add adb to PATH."

def pause():
    input("\nกด Enter เพื่อกลับเมนูหลัก...")

def header():
    os.system("cls" if os.name == "nt" else "clear")
    print("=" * 68)
    print(" REALME 5s (RMX1925) - SAFE ADB OPTIMIZATION TOOL")
    print("=" * 68)

def ensure_adb():
    if not shutil.which("adb"):
        print("ไม่พบคำสั่ง adb")
        print("macOS: brew install android-platform-tools")
        print("หรือดาวน์โหลด Platform Tools จาก developer.android.com/tools/releases/platform-tools")
        return False
    return True

def connected_devices():
    rc, out, err = run_adb(["devices"])
    if rc != 0:
        print(err or out or "เรียก adb ไม่สำเร็จ")
        return []
    lines = out.splitlines()[1:]
    devices = []
    for line in lines:
        parts = line.split()
        if len(parts) >= 2:
            devices.append((parts[0], parts[1]))
    return devices

def choose_device():
    devices = connected_devices()
    ready = [d for d in devices if d[1] == "device"]
    if not ready:
        print("ไม่พบอุปกรณ์ที่อนุญาต ADB")
        if devices:
            print("สถานะที่พบ:", ", ".join(f"{s}: {st}" for s, st in devices))
        print("\nตรวจสอบว่า:")
        print("  1) เปิด Developer options และ USB debugging")
        print("  2) ปลดล็อกหน้าจอ แล้วกด Allow USB debugging")
        print("  3) ใช้สาย USB ที่ส่งข้อมูลได้")
        return None
    if len(ready) == 1:
        return ready[0][0]
    print("พบหลายเครื่อง:")
    for i, (serial, _) in enumerate(ready, 1):
        print(f"  {i}. {serial}")
    try:
        n = int(input("เลือกหมายเลขเครื่อง: "))
        return ready[n - 1][0]
    except (ValueError, IndexError):
        print("เลือกไม่ถูกต้อง")
        return None

def adb_for(serial, args, timeout=45):
    return run_adb(["-s", serial] + list(args), timeout=timeout)

def shell(serial, command, timeout=45):
    return adb_for(serial, ["shell"] + command.split(), timeout=timeout)

def get_prop(serial, prop):
    rc, out, _ = adb_for(serial, ["shell", "getprop", prop])
    return out if rc == 0 else "(อ่านค่าไม่ได้)"

def check_device(serial):
    model = get_prop(serial, "ro.product.model")
    product = get_prop(serial, "ro.product.name")
    android = get_prop(serial, "ro.build.version.release")
    sdk = get_prop(serial, "ro.build.version.sdk")
    fingerprint = get_prop(serial, "ro.build.fingerprint")
    print(f"Serial       : {serial}")
    print(f"Model        : {model}")
    print(f"Product      : {product}")
    print(f"Android      : {android} (SDK {sdk})")
    print(f"Fingerprint  : {fingerprint}")
    if "RMX1925" not in model and "RMX1925" not in product and "RMX1925" not in fingerprint:
        print("\nคำเตือน: ไม่พบรหัส RMX1925 ชัดเจน กรุณาตรวจสอบว่าเป็นเครื่องที่ต้องการ")
    rc, out, err = adb_for(serial, ["shell", "df", "-h", "/data"])
    print("\nพื้นที่ /data:")
    print(out or err or "(ไม่มีข้อมูล)")
    rc, out, err = adb_for(serial, ["shell", "cat", "/proc/meminfo"])
    if rc == 0:
        rows = [x for x in out.splitlines() if x.startswith(("MemTotal:", "MemAvailable:", "SwapTotal:"))]
        print("\nหน่วยความจำ:")
        print("\n".join(rows))
    return model, android, fingerprint

def read_animation(serial):
    keys = ["window_animation_scale", "transition_animation_scale", "animator_duration_scale"]
    print("ค่าปัจจุบัน:")
    for key in keys:
        rc, out, _ = adb_for(serial, ["shell", "settings", "get", "global", key])
        print(f"  {key}: {out if rc == 0 else 'อ่านไม่ได้'}")

def set_animation(serial, value):
    keys = ["window_animation_scale", "transition_animation_scale", "animator_duration_scale"]
    for key in keys:
        rc, out, err = adb_for(serial, ["shell", "settings", "put", "global", key, value])
        if rc != 0:
            print(f"ผิดพลาด {key}: {err or out}")
            return False
    print(f"ตั้งค่า Animation เป็น {value}x แล้ว")
    read_animation(serial)
    return True

def list_user_packages(serial):
    rc, out, err = adb_for(serial, ["shell", "pm", "list", "packages", "-3"])
    if rc != 0:
        print(err or out)
        return []
    return sorted({line.replace("package:", "", 1).strip()
                   for line in out.splitlines() if line.startswith("package:")})

def choose_package(packages, prompt="เลือกหมายเลข Package (0 ยกเลิก): "):
    if not packages:
        print("ไม่พบ Package")
        return None
    for i, pkg in enumerate(packages, 1):
        print(f"{i:3}. {pkg}")
    try:
        n = int(input(prompt))
        if n == 0:
            return None
        return packages[n - 1]
    except (ValueError, IndexError):
        print("หมายเลขไม่ถูกต้อง")
        return None

def is_blocked(package):
    low = package.lower()
    return low in BLOCKED_EXACT or any(part in low for part in BLOCKED_PARTS)

def load_backup():
    try:
        APP_DIR.mkdir(parents=True, exist_ok=True)
        if BACKUP_FILE.exists():
            return json.loads(BACKUP_FILE.read_text(encoding="utf-8"))
    except Exception:
        pass
    return {}

def save_backup(data):
    APP_DIR.mkdir(parents=True, exist_ok=True)
    BACKUP_FILE.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")

def force_stop_menu(serial):
    packages = list_user_packages(serial)
    pkg = choose_package(packages)
    if not pkg:
        return
    print(f"\nจะ Force Stop: {pkg}")
    print("การทำงานนี้หยุดแอปชั่วคราว ไม่ได้ถอนการติดตั้ง และแอปอาจเริ่มทำงานอีกเมื่อเปิดใช้งาน")
    if input("พิมพ์ YES เพื่อยืนยัน: ").strip() != "YES":
        print("ยกเลิก")
        return
    rc, out, err = adb_for(serial, ["shell", "am", "force-stop", pkg])
    print("สำเร็จ" if rc == 0 else (err or out or "คำสั่งไม่สำเร็จ"))

def disable_menu(serial):
    packages = list_user_packages(serial)
    pkg = choose_package(packages)
    if not pkg:
        return
    if is_blocked(pkg):
        print("\nปฏิเสธ: Package นี้เข้าข่ายบริการสำคัญ/ระบบที่ไม่ควรปิด")
        return
    print(f"\nกำลังจะ DISABLE: {pkg}")
    print("ข้อควรทราบ: อาจทำให้ฟังก์ชันบางอย่างหยุดทำงาน ต้องแน่ใจว่าไม่ใช้งาน")
    print("เครื่องมือนี้จะบันทึกชื่อ Package ไว้เพื่อช่วยเปิดคืนภายหลัง")
    if input("พิมพ์ DISABLE เพื่อยืนยัน: ").strip() != "DISABLE":
        print("ยกเลิก")
        return
    rc, out, err = adb_for(serial, ["shell", "pm", "disable-user", "--user", "0", pkg])
    print(out or err or ("คำสั่งจบแล้ว" if rc == 0 else "ไม่สำเร็จ"))
    if rc == 0:
        backup = load_backup()
        backup.setdefault(serial, [])
        if pkg not in backup[serial]:
            backup[serial].append(pkg)
        save_backup(backup)
        print("บันทึก Package ลงรายการ restore แล้ว")

def enable_menu(serial):
    backup = load_backup()
    saved = backup.get(serial, [])
    if not saved:
        print("ไม่มี Package ที่เครื่องมือนี้เคยบันทึกไว้สำหรับอุปกรณ์นี้")
        print("หากต้องการเปิดคืน Package อื่น ให้ใช้เมนูเปิดคืนโดยป้อนชื่อ Package")
        pkg = input("Package name (เว้นว่างเพื่อยกเลิก): ").strip()
        if not pkg:
            return
    else:
        print("Package ที่เครื่องมือนี้เคย Disable:")
        pkg = choose_package(saved)
        if not pkg:
            return
    rc, out, err = adb_for(serial, ["shell", "pm", "enable", "--user", "0", pkg])
    print(out or err or ("เปิดใช้งานแล้ว" if rc == 0 else "ไม่สำเร็จ"))
    if rc == 0 and serial in backup and pkg in backup[serial]:
        backup[serial].remove(pkg)
        save_backup(backup)

def export_report(serial):
    model, android, fingerprint = check_device(serial)
    packages = list_user_packages(serial)
    rc, disabled, _ = adb_for(serial, ["shell", "pm", "list", "packages", "-d", "--user", "0"])
    APP_DIR.mkdir(parents=True, exist_ok=True)
    content = [
        "Realme ADB report",
        f"Created: {datetime.now().isoformat(timespec='seconds')}",
        f"Serial: {serial}", f"Model: {model}", f"Android: {android}",
        f"Fingerprint: {fingerprint}", "",
        "Third-party packages:", *packages, "",
        "Disabled packages:", *(disabled.splitlines() if rc == 0 else ["(อ่านไม่ได้)"]),
    ]
    REPORT_FILE.write_text("\n".join(content), encoding="utf-8")
    print(f"บันทึกรายงานแล้ว: {REPORT_FILE}")

def main():
    header()
    if not ensure_adb():
        pause()
        return
    serial = choose_device()
    if not serial:
        pause()
        return

    while True:
        header()
        print(f"Connected device: {serial}")
        print("""
  1) ตรวจสอบรุ่น / Android / RAM / พื้นที่
  2) ดูค่า Animation ปัจจุบัน
  3) ปรับ Animation เป็น 0.5x       [แนะนำ]
  4) คืน Animation เป็น 1.0x
  5) แสดงรายการแอปที่ผู้ใช้ติดตั้ง
  6) Force Stop แอปที่เลือก          [ชั่วคราว]
  7) Disable แอปที่เลือก              [ขั้นสูง - เสี่ยง]
  8) Enable / เปิดคืน Package
  9) Export รายงานเครื่องและ Package
 10) ตรวจสอบการเชื่อมต่อ ADB ใหม่
  0) ออกจากโปรแกรม
""")
        choice = input("เลือกเมนู: ").strip()
        if choice == "1":
            check_device(serial); pause()
        elif choice == "2":
            read_animation(serial); pause()
        elif choice == "3":
            print("ลดระยะเวลา Animation ไม่ได้เพิ่ม CPU/RAM จริง แต่ทำให้ UI ดูตอบสนองเร็วขึ้น")
            if input("พิมพ์ APPLY เพื่อยืนยัน: ").strip() == "APPLY":
                set_animation(serial, "0.5")
            pause()
        elif choice == "4":
            set_animation(serial, "1.0"); pause()
        elif choice == "5":
            pkgs = list_user_packages(serial)
            print(f"\nพบ {len(pkgs)} แอป:")
            print("\n".join(pkgs) if pkgs else "(ไม่พบ)")
            pause()
        elif choice == "6":
            force_stop_menu(serial); pause()
        elif choice == "7":
            disable_menu(serial); pause()
        elif choice == "8":
            enable_menu(serial); pause()
        elif choice == "9":
            export_report(serial); pause()
        elif choice == "10":
            serial = choose_device() or serial
            pause()
        elif choice == "0":
            print("ออกจากโปรแกรม")
            break
        else:
            print("เมนูไม่ถูกต้อง")
            pause()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nยกเลิกโดยผู้ใช้")

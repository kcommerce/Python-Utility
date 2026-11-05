#!/usr/bin/env bash
# ==============================================================================
# Script Name : tune-redmi5a.sh
# Description : Interactive ADB Tuning, Debloat & Performance Utility
#               for Xiaomi Redmi 5A (Codename: riva / MIUI 11 / Android 8.1.0)
# Safe Mode   : Uses 'pm disable-user --user 0' (Non-destructive Freeze)
#               Always explains & asks for confirmation before executing changes
# ==============================================================================

set -u

# ------------------------------------------------------------------------------
# Color & Text Formatting
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ------------------------------------------------------------------------------
# Configuration & Backup Directory
# ------------------------------------------------------------------------------
BACKUP_DIR="${HOME}/.redmi5a_tuning"
LOG_FILE="${BACKUP_DIR}/tuning_history.log"
mkdir -p "${BACKUP_DIR}"

TARGET_SERIAL=""
DEVICE_MODEL=""
DEVICE_BRAND=""
DEVICE_ANDROID=""
DEVICE_MIUI=""
DEVICE_BUILD=""

# ------------------------------------------------------------------------------
# Locate ADB Binary
# ------------------------------------------------------------------------------
find_adb() {
    if command -v adb >/dev/null 2>&1; then
        command -v adb
        return 0
    fi

    # Check common locations on macOS / Linux
    local candidates=(
        "${HOME}/Library/Android/sdk/platform-tools/adb"
        "/opt/homebrew/bin/adb"
        "/usr/local/bin/adb"
        "/usr/bin/adb"
    )

    for path in "${candidates[@]}"; do
        if [ -x "${path}" ]; then
            echo "${path}"
            return 0
        fi
    done

    return 1
}

ADB_CMD=$(find_adb)

if [ -z "${ADB_CMD}" ]; then
    echo -e "${RED}[ERROR] ไม่พบคำสั่ง adb ในระบบ!${RESET}"
    echo "กรุณาติดตั้ง Android Platform Tools:"
    echo "  - macOS (Homebrew): brew install android-platform-tools"
    echo "  - หรือดาวน์โหลดจาก: https://developer.android.com/tools/releases/platform-tools"
    exit 1
fi

# ------------------------------------------------------------------------------
# Device Selection & Verification
# ------------------------------------------------------------------------------
check_device_connection() {
    local raw_devices
    raw_devices=$("${ADB_CMD}" devices | sed '1d' | grep -v '^[[:space:]]*$')

    if [ -z "${raw_devices}" ]; then
        echo -e "${RED}[ERROR] ไม่พบอุปกรณ์ Android เชื่อมต่ออยู่!${RESET}"
        echo -e "กรุณาตรวจสอบ:"
        echo -e "  1. เปิดโหมด Developer options บน Redmi 5A (เคาะ MIUI version 7 ครั้ง)"
        echo -e "  2. เปิดใช้งาน ${BOLD}USB Debugging${RESET}"
        echo -e "  3. ตรวจสอบสาย USB และปลดล็อกหน้าจอกด ${BOLD}'Allow USB debugging'${RESET}"
        exit 1
    fi

    # Count authorized devices
    local authorized_devices
    authorized_devices=$(echo "${raw_devices}" | awk '$2 == "device" {print $1}')

    if [ -z "${authorized_devices}" ]; then
        echo -e "${YELLOW}[WARNING] พบอุปกรณ์ แต่ยังไม่ได้รับอนุญาต (unauthorized หรือ offline)${RESET}"
        echo "${raw_devices}"
        echo -e "กรุณาดูที่หน้าจอโทรศัพท์แล้วกด ${BOLD}'Allow' / 'ตกลง'${RESET}"
        exit 1
    fi

    # Select device (if multiple)
    local count
    count=$(echo "${authorized_devices}" | grep -c .)
    if [ "${count}" -eq 1 ]; then
        TARGET_SERIAL=$(echo "${authorized_devices}" | head -n 1)
    else
        echo -e "${CYAN}พบอุปกรณ์เชื่อมต่อมากกว่า 1 เครื่อง:${RESET}"
        local i=1
        while IFS= read -r s; do
            echo "  ${i}) ${s}"
            i=$((i + 1))
        done <<< "${authorized_devices}"
        read -r -p "เลือกหมายเลขอุปกรณ์ที่ต้องการปรับแต่ง (1-${count}): " dev_choice
        TARGET_SERIAL=$(echo "${authorized_devices}" | sed -n "${dev_choice}p")
        if [ -z "${TARGET_SERIAL}" ]; then
            echo -e "${RED}เลือกอุปกรณ์ไม่ถูกต้อง ยกเลิกการทำงาน${RESET}"
            exit 1
        fi
    fi
}

# Wrapper to run adb on target serial
run_adb() {
    "${ADB_CMD}" -s "${TARGET_SERIAL}" "$@" < /dev/null
}

run_shell() {
    "${ADB_CMD}" -s "${TARGET_SERIAL}" shell "$@" < /dev/null
}

verify_redmi5a() {
    DEVICE_BRAND=$(run_shell getprop ro.product.manufacturer | tr -d '\r')
    DEVICE_MODEL=$(run_shell getprop ro.product.model | tr -d '\r')
    DEVICE_ANDROID=$(run_shell getprop ro.build.version.release | tr -d '\r')
    DEVICE_MIUI=$(run_shell getprop ro.miui.ui.version.name | tr -d '\r')
    DEVICE_BUILD=$(run_shell getprop ro.build.version.incremental | tr -d '\r')
    local device_codename
    device_codename=$(run_shell getprop ro.product.device | tr -d '\r')

    if [[ "${DEVICE_MODEL}" != *"Redmi 5A"* && "${device_codename}" != *"riva"* ]]; then
        echo -e "${YELLOW}======================================================================${RESET}"
        echo -e "${YELLOW}[คำเตือน] อุปกรณ์ที่เชื่อมต่อคือ '${DEVICE_BRAND} ${DEVICE_MODEL}' (Codename: ${device_codename})${RESET}"
        echo -e "สคริปต์นี้ออกแบบมาสำหรับ ${BOLD}Xiaomi Redmi 5A (riva)${RESET} โดยเฉพาะ"
        echo -e "${YELLOW}======================================================================${RESET}"
        read -r -p "คุณต้องการดำเนินการต่อหรือไม่? (y/N): " cont
        if [[ ! "${cont}" =~ ^[Yy]$ ]]; then
            echo "ยกเลิกการทำงาน"
            exit 0
        fi
    fi
}

log_action() {
    local msg="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Serial:${TARGET_SERIAL}] ${msg}" >> "${LOG_FILE}"
}

pause_prompt() {
    echo ""
    read -r -p "กดปุ่ม [Enter] เพื่อกลับสู่เมนูหลัก..." _
}

show_header() {
    clear
    echo -e "${BLUE}======================================================================${RESET}"
    echo -e "${BOLD}${CYAN}   🚀 XIAOMI REDMI 5A (MIUI 11) - ADB TUNING & OPTIMIZATION           ${RESET}"
    echo -e "${BLUE}======================================================================${RESET}"
    echo -e " 📱 อุปกรณ์ : ${GREEN}${DEVICE_BRAND} ${DEVICE_MODEL}${RESET} (Serial: ${YELLOW}${TARGET_SERIAL}${RESET})"
    echo -e " ⚙️  ระบบ    : Android ${DEVICE_ANDROID} | MIUI ${DEVICE_MIUI} (${DEVICE_BUILD})"
    echo -e " 📂 ล็อกไฟล์ : ${LOG_FILE}"
    echo -e "${BLUE}======================================================================${RESET}"
}

confirm_action() {
    local description="$1"
    echo -e "\n${YELLOW}----------------------------------------------------------------------${RESET}"
    echo -e "${BOLD}📋 สิ่งที่จะดำเนินการ:${RESET} ${description}"
    echo -e "${YELLOW}----------------------------------------------------------------------${RESET}"
    read -r -p "ยืนยันการดำเนินการหรือไม่? (พิมพ์ y เพื่อยืนยัน / กด Enter เพื่อยกเลิก) [y/N]: " ans
    if [[ "${ans}" =~ ^[Yy]$ ]]; then
        return 0
    else
        echo -e "${RED}ยกเลิกคำสั่งเรียบร้อยแล้ว${RESET}"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Feature 1: System Info & Diagnostics
# ------------------------------------------------------------------------------
menu_system_info() {
    show_header
    echo -e "${BOLD}[1. ตรวจสอบสถานะเครื่อง & ทรัพยากรระบบ]${RESET}\n"
    
    echo -e "${CYAN}>> ข้อมูลฮาร์ดแวร์และรอม:${RESET}"
    echo "  - CPU Platform   : $(run_shell getprop ro.board.platform | tr -d '\r') (Snapdragon 425)"
    echo "  - Device Codename: $(run_shell getprop ro.product.device | tr -d '\r')"
    echo "  - Security Patch : $(run_shell getprop ro.build.version.security_patch | tr -d '\r')"
    echo "  - MIUI Version   : ${DEVICE_MIUI} (${DEVICE_BUILD})"
    echo ""

    echo -e "${CYAN}>> หน่วยความจำ (RAM 2GB):${RESET}"
    run_shell cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|Active\(anon\)|SwapTotal|SwapFree" | sed 's/^/  /'
    echo ""

    echo -e "${CYAN}>> พื้นที่จัดเก็บข้อมูล (/data, /system, /cache):${RESET}"
    run_shell df -h /data /system /cache 2>/dev/null | sed 's/^/  /'
    echo ""

    echo -e "${CYAN}>> สถานะแบตเตอรี่:${RESET}"
    run_shell dumpsys battery | grep -E "level|temperature|voltage|status|health" | sed 's/^/  /'
    echo ""

    echo -e "${CYAN}>> จำนวนแอปที่ถูก Freeze (Disabled) อยู่ปัจจุบัน:${RESET}"
    local d_count
    d_count=$(run_shell pm list packages -d | grep -c .)
    echo "  จำนวน: ${d_count} แพ็กเกจ"

    pause_prompt
}

# ------------------------------------------------------------------------------
# Feature 2: Animation Speed Tuning
# ------------------------------------------------------------------------------
menu_animation_tuning() {
    show_header
    echo -e "${BOLD}[2. ปรับความเร็ว Animation Scale]${RESET}\n"
    
    echo -e "${CYAN}>> ค่า Animation ปัจจุบันบนเครื่อง:${RESET}"
    local w_scale t_scale a_scale
    w_scale=$(run_shell settings get global window_animation_scale | tr -d '\r')
    t_scale=$(run_shell settings get global transition_animation_scale | tr -d '\r')
    a_scale=$(run_shell settings get global animator_duration_scale | tr -d '\r')
    echo "  - Window animation scale     : ${w_scale:-1.0 (ค่าเริ่มต้น)}"
    echo "  - Transition animation scale : ${t_scale:-1.0 (ค่าเริ่มต้น)}"
    echo "  - Animator duration scale    : ${a_scale:-1.0 (ค่าเริ่มต้น)}"
    echo ""

    echo -e "${YELLOW}💡 คำแนะนำสำหรับ Redmi 5A (Snapdragon 425 / RAM 2GB):${RESET}"
    echo "  - 0.5x : ลดระยะเวลาเอฟเฟกต์ลงครึ่งหนึ่ง ทำให้ UI สลับแอปและเปิดเมนูรวดเร็วขึ้นมาก (แนะนำ)"
    echo "  - 1.0x : คืนค่ามาตรฐานดั้งเดิมของ MIUI"
    echo "  - 0.0x : ปิดเอฟเฟกต์ทั้งหมด ช่วยลดภาระ GPU Adreno 308 ได้สูงสุด"
    echo ""

    echo "เลือกรูปแบบการปรับแต่ง:"
    echo "  1) ปรับเป็น 0.5x (แนะนำ - ตอบสนองไวขึ้นทันที)"
    echo "  2) ปรับเป็น 1.0x (คืนค่าเริ่มต้นของโรงงาน)"
    echo "  3) ปิดแอนิเมชันเป็น 0x (เร็วที่สุด ไม่แสดง Transition)"
    echo "  4) เปิดหน้า Developer Options บนหน้าจอมือถือเพื่อปรับเอง"
    echo "  0) ยกเลิก / กลับสู่เมนูหลัก"
    echo ""
    read -r -p "เลือกข้อ (0-4): " anim_choice

    if [ "${anim_choice}" = "4" ]; then
        run_shell am start -a android.settings.APPLICATION_DEVELOPMENT_SETTINGS >/dev/null 2>&1
        echo -e "\n${GREEN}✅ เปิดหน้า Developer Options บนหน้าจอมือถือแล้ว!${RESET}"
        echo "เลื่อนลงไปที่หมวด Drawing (การวาด) แล้วปรับ Scale ทั้ง 3 ตัวเป็น 0.5x ได้เลยครับ"
        pause_prompt
        return 0
    fi

    local target_val=""
    case "${anim_choice}" in
        1) target_val="0.5" ;;
        2) target_val="1" ;;
        3) target_val="0" ;;
        0) return 0 ;;
        *) echo -e "${RED}เลือกไม่ถูกต้อง${RESET}"; pause_prompt; return ;;
    esac

    if ! confirm_action "จะทำการปรับ Animation Scale ทุกตัวเป็น: ${target_val}x"; then
        pause_prompt
        return
    fi

    echo -e "\n${CYAN}กำลังส่งคำสั่งผ่าน ADB...${RESET}"
    local out
    out=$(run_shell settings put global window_animation_scale "${target_val}" 2>&1)
    if [[ "${out}" == *"SecurityException"* || "${out}" == *"WRITE_SECURE_SETTINGS"* ]]; then
        echo -e "${YELLOW}⚠️  MIUI บล็อกการแก้ไขค่า Global Settings ผ่าน ADB (ติดสิทธิ์ WRITE_SECURE_SETTINGS)${RESET}"
        echo -e "เนื่องจากยังไม่ได้เปิดสวิตช์ ${BOLD}'USB debugging (Security settings)'${RESET} ในโหมดนักพัฒนา"
        echo ""
        echo -e "${CYAN}>> กำลังเปิดหน้า Developer Options บนหน้าจอโทรศัพท์ให้โดยอัตโนมัติ...${RESET}"
        run_shell am start -a android.settings.APPLICATION_DEVELOPMENT_SETTINGS >/dev/null 2>&1
        echo "คุณสามารถเลือกทำวิธีใดวิธีหนึ่งต่อไปนี้บนหน้าจอมือถือ:"
        echo "  วิธีที่ 1: เปิดสวิตช์ 'USB debugging (Security settings)' แล้วมารันเมนูนี้ซ้ำ"
        echo "  วิธีที่ 2: เลื่อนลงไปที่หมวด Drawing แล้วแตะปรับค่าทั้ง 3 ตัวเป็น ${target_val}x ด้วยตนเอง"
    else
        run_shell settings put global transition_animation_scale "${target_val}"
        run_shell settings put global animator_duration_scale "${target_val}"
        echo -e "${GREEN}✅ ปรับค่า Animation เป็น ${target_val}x สำเร็จเรียบร้อย!${RESET}"
        log_action "Set animation scale to ${target_val}x"
    fi

    pause_prompt
}

# ------------------------------------------------------------------------------
# Feature 3: Freeze Bloatware & Telemetry
# ------------------------------------------------------------------------------

# Master list of 36 verified safe packages on Xiaomi Redmi 5A (riva / MIUI 11)
# Format: package_name|group_id|thai_description
PACKAGE_DATABASE=(
    # Group 1: Telemetry, Analytics & Factory Loggers (9 packages)
    "com.xiaomi.joyose|1|Joyose (Telemetry, เก็บสถิติเกม และตัวจำกัดประสิทธิภาพ/Throttling)"
    "com.miui.analytics|1|MIUI Analytics (ตัวเก็บสถิติการใช้งานและการคลิกโฆษณาในระบบ)"
    "com.miui.daemon|1|MiuiDaemon (ดักเก็บข้อมูลระบบและฮาร์ดแวร์ส่งกลับเซิร์ฟเวอร์ Xiaomi)"
    "com.miui.bugreport|1|MiuiBugReport (ตัวดักส่งรายงานข้อผิดพลาด)"
    "com.google.android.feedback|1|Google Feedback (ตัวส่ง Crash Report ของ Google)"
    "com.qualcomm.qti.StatsPollManager|1|Qualcomm StatsPollManager (ดักเก็บสถิติโมเด็มและพลังงานเบื้องหลัง)"
    "com.bsp.catchlog|1|BSP CatchLog (ตัวดักจับล็อกระดับเคอร์เนลและแบตเตอรี่)"
    "com.factory.mmigroup|1|Factory MMI Test Group (เซอร์วิสทดสอบฮาร์ดแวร์โรงงานที่รันค้างกินแรมกว่า 21 MB)"
    "com.mi.AutoTest|1|Factory AutoTest (เซอร์วิสทดสอบอัตโนมัติของโรงงาน)"

    # Group 2: MIUI System Ads, App Vault & Quick Apps (7 packages)
    "com.miui.msa.global|2|MSA (MIUI System Ads - เครื่องมือยิงโฆษณาแฝงหลักในรอม MIUI กินแรมกว่า 20 MB)"
    "com.mi.android.globalminusscreen|2|App Vault / Global Minus Screen (หน้าปัดซ้ายสุดรวมฟีดข่าว/โฆษณา กินแรมกว่า 31 MB)"
    "com.miui.hybrid|2|Quick Apps / Hybrid Platform (เฟรมเวิร์กเว็บแอปแฝงโฆษณา กินแรมกว่า 30 MB)"
    "com.miui.hybrid.accessory|2|Hybrid Accessory (เซอร์วิสเสริมของ Quick Apps)"
    "com.miui.cleanmaster|2|CleanMaster (โมดูลคลีนเนอร์พ่วงโฆษณาของ Cheetah Mobile)"
    "com.miui.yellowpage|2|YellowPage (บริการสมุดหน้าเหลืองพ่วงโฆษณา)"
    "com.miui.wmsvc|2|WMService (บริการซิงก์คอนฟิกโฆษณาและลายน้ำเบื้องหลัง)"

    # Group 3: Core Xiaomi Background Push, Casting & Security Scanners (6 packages)
    "com.xiaomi.xmsf|3|Xiaomi Service Framework (XMSF - เซอร์วิสพุชเบื้องหลังของ Xiaomi กินแรมกว่า 17 MB)"
    "com.miui.guardprovider|3|GuardProvider (ตัวสแกนไวรัสเบื้องหลังที่ต่อเน็ตตลอดเวลา)"
    "com.milink.service|3|MiLink Service (บริการแชร์หน้าจอ/แคสต์ไร้สายของ Xiaomi)"
    "com.xiaomi.mi_connect_service|3|Mi Connect Service (สแกนและเชื่อมต่ออุปกรณ์ IoT รอบข้างตลอดเวลา)"
    "com.xiaomi.miplay_client|3|MiPlay Client (ระบบแคสต์เสียงและมีเดียเบื้องหลัง)"
    "com.xiaomi.upnp|3|Xiaomi UPnP Service (บริการค้นหาอุปกรณ์มีเดียผ่านเครือข่าย)"

    # Group 4: Facebook Pre-installed Trackers (3 packages)
    "com.facebook.appmanager|4|Facebook App Manager (ตัวเช็กและอัปเดตแอปเฟซบุ๊กเบื้องหลัง)"
    "com.facebook.services|4|Facebook Services (Telemetry & Background Sync ของ Facebook)"
    "com.facebook.system|4|Facebook System Installer (ตัวติดตั้งแอปเฟซบุ๊กระดับระบบ)"

    # Group 5: OEM Stores, Bloatware & Regional Financial Apps (11 packages)
    "com.xiaomi.mipicks|5|GetApps / Mi Picks (ร้านโหลดแอปของ Xiaomi ที่ชอบยิงแจ้งเตือน)"
    "com.xiaomi.discover|5|Xiaomi System Apps Updater (ตัวอัปเดตแอประบบที่ชอบแจ้งเตือนและดึง Bloatware กลับ)"
    "com.mipay.wallet.id|5|Mi Pay Indonesia (กระเป๋าเงินออนไลน์สำหรับอินโดนีเซีย)"
    "com.mipay.wallet.in|5|Mi Pay India (กระเป๋าเงินออนไลน์สำหรับอินเดีย)"
    "com.micredit.in|5|Mi Credit India (บริการสินเชื่อเสียวหมี่)"
    "com.xiaomi.payment|5|Xiaomi Payment Service (บริการชำระเงิน Mi Coin)"
    "com.xiaomi.glgm|5|Mi Games (ศูนย์เกมแถม)"
    "com.miui.enbbs|5|Mi Community (แอปฟอรัมชุมชนเสียวหมี่)"
    "cn.wps.xiaomi.abroad.lite|5|Mi Doc Viewer / WPS Lite (แอปอ่านเอกสารแถมที่ฝังโฆษณา)"
    "com.android.browser|5|Mi Browser Global (เบราว์เซอร์แถมที่มีฟีดข่าวและโฆษณา)"
    "com.xiaomi.mirecycle|5|Mi Recycle (บริการประเมินราคาขายเครื่องเก่าในต่างประเทศ)"
)

freeze_package() {
    local pkg="$1"
    local desc="$2"
    
    # Check if package exists on device
    local check_pkg
    check_pkg=$(run_shell pm list packages "${pkg}" | grep -E "^package:${pkg}$" | tr -d '\r')
    if [ -z "${check_pkg}" ]; then
        echo -e "  [${YELLOW}ข้าม${RESET}] ${pkg} (ไม่มีในเครื่อง)"
        return 0
    fi

    # Check if already disabled
    local is_disabled
    is_disabled=$(run_shell pm list packages -d | grep -E "^package:${pkg}$" | tr -d '\r')
    if [ -n "${is_disabled}" ]; then
        echo -e "  [${CYAN}เดิมปิดอยู่แล้ว${RESET}] ${pkg}"
        return 0
    fi

    local out
    out=$(run_shell pm disable-user --user 0 "${pkg}" 2>&1 | tr -d '\r')
    if [[ "${out}" == *"disabled-user"* || "${out}" == *"new state: disabled"* ]]; then
        run_shell am force-stop "${pkg}" >/dev/null 2>&1
        echo -e "  [${GREEN}FREEZE สำเร็จ${RESET}] ${pkg} (${desc})"
        log_action "Freeze package: ${pkg}"
    else
        echo -e "  [${RED}ล้มเหลว${RESET}] ${pkg}: ${out}"
    fi
}

menu_freeze_bloatware() {
    show_header
    echo -e "${BOLD}[3. Freeze Bloatware & Telemetry (ปิดการทำงานแบบปลอดภัย)]${RESET}\n"
    
    echo -e "${YELLOW}💡 คำแนะนำและความปลอดภัยบน Redmi 5A (MIUI 11):${RESET}"
    echo "  - การ Freeze จะใช้คำสั่ง 'pm disable-user --user 0' ร่วมกับ 'am force-stop'"
    echo "  - ข้อมูลและไฟล์ระบบ ${BOLD}จะไม่ถูกลบ${RESET} และสามารถกู้คืน (Unfreeze) กลับมาได้ตลอดเวลา"
    echo "  - บนเครื่อง RAM 2GB / ROM 16GB ช่วยคืน RAM กว่า 100+ MB และลดภาระ CPU ได้ชัดเจน"
    echo "  - ไม่กระทบต่อการโทร, SMS, Wi-Fi, กล้อง, Termux หรือ Google Play Store"
    echo ""

    echo "เลือกกลุ่มที่ต้องการ Freeze:"
    echo "  1) 🛡️  Freeze ทุกกลุ่มที่แนะนำ (Safe All - ทั้ง 36 แพ็กเกจ) [แนะนำสูงสุด]"
    echo "  2) 📊 เฉพาะกลุ่ม Telemetry, Analytics & Factory Test (9 รายการ)"
    echo "  3) 📢 เฉพาะกลุ่ม MIUI System Ads, App Vault & Quick Apps (7 รายการ)"
    echo "  4) ⚙️  เฉพาะกลุ่ม Xiaomi Framework, Casting & GuardProvider (6 รายการ)"
    echo "  5) 👤 เฉพาะกลุ่ม Facebook Pre-installed Trackers (3 รายการ)"
    echo "  6) 🛒 เฉพาะกลุ่ม OEM Stores, Bloatware & Financial Extras (11 รายการ)"
    echo "  7) 🔍 เลือก Freeze ทีละแพ็กเกจด้วยตนเอง"
    echo "  0) ยกเลิก / กลับสู่เมนูหลัก"
    echo ""
    read -r -p "เลือกข้อ (0-7): " freeze_choice

    local target_group=""
    case "${freeze_choice}" in
        1) target_group="ALL" ;;
        2) target_group="1" ;;
        3) target_group="2" ;;
        4) target_group="3" ;;
        5) target_group="4" ;;
        6) target_group="5" ;;
        7) target_group="CUSTOM" ;;
        0) return 0 ;;
        *) echo -e "${RED}เลือกไม่ถูกต้อง${RESET}"; pause_prompt; return ;;
    esac

    if [ "${target_group}" = "CUSTOM" ]; then
        echo -e "\n${CYAN}>> รายการแพ็กเกจทั้งหมด:${RESET}"
        local idx=1
        for item in "${PACKAGE_DATABASE[@]}"; do
            local p_name p_grp p_desc
            IFS='|' read -r p_name p_grp p_desc <<< "${item}"
            echo "  ${idx}) ${p_name} [${p_desc}]"
            idx=$((idx + 1))
        done
        echo ""
        read -r -p "พิมพ์หมายเลขแพ็กเกจที่ต้องการ Freeze (1-${#PACKAGE_DATABASE[@]}): " c_idx
        if [[ "${c_idx}" =~ ^[0-9]+$ ]] && [ "${c_idx}" -ge 1 ] && [ "${c_idx}" -le "${#PACKAGE_DATABASE[@]}" ]; then
            local selected_item="${PACKAGE_DATABASE[$((c_idx - 1))]}"
            local sel_name sel_grp sel_desc
            IFS='|' read -r sel_name sel_grp sel_desc <<< "${selected_item}"
            
            if confirm_action "จะทำการ Freeze แพ็กเกจ: ${sel_name} (${sel_desc})"; then
                echo -e "\n${CYAN}กำลังดำเนินการ...${RESET}"
                freeze_package "${sel_name}" "${sel_desc}"
            fi
        else
            echo -e "${RED}หมายเลขไม่ถูกต้อง${RESET}"
        fi
        pause_prompt
        return
    fi

    # Display packages to be affected
    echo -e "\n${CYAN}>> รายการแพ็กเกจที่จะถูกตรวจสอบและ Freeze:${RESET}"
    for item in "${PACKAGE_DATABASE[@]}"; do
        local p_name p_grp p_desc
        IFS='|' read -r p_name p_grp p_desc <<< "${item}"
        if [ "${target_group}" = "ALL" ] || [ "${target_group}" = "${p_grp}" ]; then
            echo "  - ${p_name} (${p_desc})"
        fi
    done

    if ! confirm_action "คุณต้องการดำเนินการ Freeze แพ็กเกจในกลุ่มดังกล่าวหรือไม่?"; then
        pause_prompt
        return
    fi

    echo -e "\n${CYAN}กำลังส่งคำสั่งผ่าน ADB...${RESET}"
    for item in "${PACKAGE_DATABASE[@]}"; do
        local p_name p_grp p_desc
        IFS='|' read -r p_name p_grp p_desc <<< "${item}"
        if [ "${target_group}" = "ALL" ] || [ "${target_group}" = "${p_grp}" ]; then
            freeze_package "${p_name}" "${p_desc}"
        fi
    done

    echo -e "\n${GREEN}✅ ดำเนินการเสร็จสิ้น!${RESET}"
    pause_prompt
}

# ------------------------------------------------------------------------------
# Feature 4: Unfreeze / Rollback
# ------------------------------------------------------------------------------
menu_unfreeze_packages() {
    show_header
    echo -e "${BOLD}[4. Unfreeze / Rollback คืนค่าแอปที่เคยปิดไว้]${RESET}\n"
    
    local disabled_list
    disabled_list=$(run_shell pm list packages -d | sed 's/^package://' | tr -d '\r')

    if [ -z "${disabled_list}" ]; then
        echo -e "${GREEN}ปัจจุบันไม่มีแพ็กเกจใดที่ถูก Freeze (Disabled) อยู่บนเครื่องนี้${RESET}"
        pause_prompt
        return
    fi

    echo -e "${CYAN}>> รายการแพ็กเกจที่ถูก Freeze อยู่ในขณะนี้:${RESET}"
    local i=1
    local d_arr=()
    while IFS= read -r pkg; do
        if [ -n "${pkg}" ]; then
            echo "  ${i}) ${pkg}"
            d_arr+=("${pkg}")
            i=$((i + 1))
        fi
    done <<< "${disabled_list}"
    echo ""

    echo "เลือกรูปแบบการ Unfreeze:"
    echo "  1) 🔄 Unfreeze คืนค่าทั้งหมด (${#d_arr[@]} แพ็กเกจ)"
    echo "  2) 🎯 เลือก Unfreeze ทีละแพ็กเกจจากรายการด้านบน"
    echo "  3) ⌨️  พิมพ์ชื่อแพ็กเกจเองเพื่อเปิดใช้งาน"
    echo "  0) ยกเลิก / กลับสู่เมนูหลัก"
    echo ""
    read -r -p "เลือกข้อ (0-3): " unfreeze_choice

    case "${unfreeze_choice}" in
        1)
            if confirm_action "ต้องการเปิดใช้งาน (Unfreeze) คืนค่าทุกแพ็กเกจใช่หรือไม่?"; then
                for p in "${d_arr[@]}"; do
                    run_shell pm enable "${p}" >/dev/null 2>&1
                    echo -e "  [${GREEN}เปิดคืนแล้ว${RESET}] ${p}"
                    log_action "Unfreeze package: ${p}"
                done
                echo -e "\n${GREEN}✅ คืนค่าทั้งหมดสำเร็จเรียบร้อย!${RESET}"
            fi
            ;;
        2)
            read -r -p "เลือกหมายเลขที่ต้องการเปิดคืน (1-${#d_arr[@]}): " target_num
            if [[ "${target_num}" =~ ^[0-9]+$ ]] && [ "${target_num}" -ge 1 ] && [ "${target_num}" -le "${#d_arr[@]}" ]; then
                local selected_pkg="${d_arr[$((target_num - 1))]}"
                if confirm_action "ต้องการเปิดคืนแพ็กเกจ: ${selected_pkg}"; then
                    run_shell pm enable "${selected_pkg}" >/dev/null 2>&1
                    echo -e "  [${GREEN}เปิดคืนแล้ว${RESET}] ${selected_pkg}"
                    log_action "Unfreeze package: ${selected_pkg}"
                fi
            else
                echo -e "${RED}หมายเลขไม่ถูกต้อง${RESET}"
            fi
            ;;
        3)
            read -r -p "กรอกชื่อ Package Name (เช่น com.miui.msa.global): " custom_pkg
            if [ -n "${custom_pkg}" ]; then
                if confirm_action "ต้องการเปิดใช้งานแพ็กเกจ: ${custom_pkg}"; then
                    local res
                    res=$(run_shell pm enable "${custom_pkg}" 2>&1 | tr -d '\r')
                    echo -e "  ผลลัพธ์: ${res}"
                    log_action "Unfreeze manual: ${custom_pkg}"
                fi
            fi
            ;;
        0) return 0 ;;
        *) echo -e "${RED}เลือกไม่ถูกต้อง${RESET}" ;;
    esac

    pause_prompt
}

# ------------------------------------------------------------------------------
# Feature 5: ART Runtime Compilation
# ------------------------------------------------------------------------------
menu_art_compilation() {
    show_header
    echo -e "${BOLD}[5. ART Runtime Compilation (Compile Speed)]${RESET}\n"
    
    echo -e "${YELLOW}💡 คำแนะนำสำหรับ Redmi 5A (MIUI 11 / Android 8.1.0):${RESET}"
    echo "  - บน Android 8.1 (Oreo) สามารถรันได้ทั้งคำสั่ง ${BOLD}bg-dexopt-job${RESET} และ ${BOLD}compile -m speed-profile${RESET}"
    echo "  - คำแนะนำสำหรับเครื่องที่มีพื้นที่ /data เหลือน้อย (< 500 MB):"
    echo "    1) ${BOLD}bg-dexopt-job${RESET} หรือ ${BOLD}-m speed-profile -a${RESET} : แนะนำสูงสุด ประหยัดพื้นที่และเปิดแอปไวขึ้น"
    echo "    2) ${BOLD}-m speed -a${RESET} : แปลงโค้ดทุกแอปเต็มรูปแบบ (กินพื้นที่ /data เพิ่มขึ้น ไม่แนะนำหากพื้นที่เหลือน้อย)"
    echo ""
    echo "เลือกรูปแบบการ Compile:"
    echo "  1) ⚡ Background DEX Optimization (cmd package bg-dexopt-job) [แนะนำ]"
    echo "  2) 🎯 Speed-Profile Optimization (-m speed-profile -a) [ละเอียดครบทุกแพ็กเกจ]"
    echo "  3) 🚀 Full Speed AOT Compilation (-m speed -a) [ใช้เวลา 5-15 นาที]"
    echo "  0) ยกเลิก"
    echo ""
    read -r -p "เลือกข้อ (0-3): " art_choice

    case "${art_choice}" in
        1)
            if confirm_action "ต้องการรัน Background DEX Optimization (bg-dexopt-job) ใช่หรือไม่?"; then
                echo -e "\n${CYAN}>> กำลังรัน cmd package bg-dexopt-job...${RESET}"
                echo -e "${YELLOW}กรุณาอย่าถอดสาย USB จนกว่าจะเสร็จสิ้น (ใช้เวลาประมาณ 30-90 วินาที)${RESET}\n"
                log_action "Started bg-dexopt-job"
                local out
                out=$(run_shell cmd package bg-dexopt-job 2>&1)
                if [[ "${out}" == *"Security exception"* || "${out}" == *"Error:"* ]]; then
                    echo "${out}"
                    echo -e "\n${RED}❌ เกิดข้อผิดพลาดในการรัน bg-dexopt-job${RESET}"
                else
                    echo -e "${GREEN}✅ รัน Background DEX Optimization สำเร็จสมบูรณ์!${RESET}"
                    log_action "Finished bg-dexopt-job"
                fi
            fi
            ;;
        2|3)
            local mode_flag="speed-profile"
            [ "${art_choice}" = "3" ] && mode_flag="speed"
            if confirm_action "ต้องการเริ่มการ Compile ทั้งเครื่องในโหมด '${mode_flag}' ใช่หรือไม่?"; then
                echo -e "\n${CYAN}>> กำลังเริ่มดำเนินการ ART Compilation (-m ${mode_flag} -a)...${RESET}"
                echo -e "${YELLOW}กรุณาอย่าถอดสาย USB จนกว่าจะเสร็จสิ้น${RESET}\n"
                log_action "Started ART compilation (-m ${mode_flag} -a)"
                local out
                out=$(run_shell cmd package compile -m "${mode_flag}" -a 2>&1)
                echo "${out}"
                if [[ "${out}" == *"Security exception"* || "${out}" == *"Error:"* ]]; then
                    echo -e "\n${RED}❌ เกิดข้อผิดพลาดระหว่างการ Compile${RESET}"
                    log_action "Failed ART compilation (-m ${mode_flag} -a)"
                else
                    echo -e "\n${GREEN}✅ รัน ART Compilation (-m ${mode_flag} -a) สำเร็จสมบูรณ์!${RESET}"
                    log_action "Finished ART compilation (-m ${mode_flag} -a)"
                fi
            fi
            ;;
        0) return 0 ;;
        *) echo -e "${RED}เลือกไม่ถูกต้อง${RESET}" ;;
    esac

    pause_prompt
}

# ------------------------------------------------------------------------------
# Feature 6: Force Stop Running Apps & Trim Cache
# ------------------------------------------------------------------------------
menu_force_stop() {
    show_header
    echo -e "${BOLD}[6. Force Stop แอปชั่วคราว & ล้างแคชระบบ (Trim Caches)]${RESET}\n"
    
    echo -e "${YELLOW}💡 คำแนะนำ:${RESET}"
    echo "  - สั่งหยุดการทำงานของแอปใน RAM ชั่วคราว และสามารถสั่งล้างไฟล์แคชขยะ (pm trim-caches)"
    echo "  - ช่วยคืนพื้นที่ /data และ RAM ได้ทันทีโดยไม่กระทบข้อมูลผู้ใช้"
    echo ""

    local common_apps=(
        "com.google.android.youtube|YouTube"
        "com.google.android.gm|Gmail"
        "com.google.android.apps.photos|Google Photos"
        "com.google.android.apps.docs|Google Drive"
        "com.android.vending|Google Play Store"
    )

    echo "เลือกรายการที่ต้องการดำเนินการ:"
    local i=1
    for app_entry in "${common_apps[@]}"; do
        local a_pkg a_name
        IFS='|' read -r a_pkg a_name <<< "${app_entry}"
        echo "  ${i}) Force Stop: ${a_name} (${a_pkg})"
        i=$((i + 1))
    done
    echo "  A) 🛑 Force Stop ทุกแอปในรายการนี้ + Kill Background Processes (am kill-all)"
    echo "  T) 🧹 ล้างไฟล์แคชระบบทั้งหมด (pm trim-caches 999G) เพื่อคืนพื้นที่ /data"
    echo "  0) ยกเลิก"
    echo ""
    read -r -p "เลือกตัวเลือก: " fs_choice

    if [ "${fs_choice}" = "0" ]; then
        return 0
    elif [ "${fs_choice}" = "A" ] || [ "${fs_choice}" = "a" ]; then
        if confirm_action "ต้องการ Force Stop ทุกแอปในรายการและเคลียร์ Background Processes ใช่หรือไม่?"; then
            for app_entry in "${common_apps[@]}"; do
                local a_pkg a_name
                IFS='|' read -r a_pkg a_name <<< "${app_entry}"
                run_shell am force-stop "${a_pkg}" >/dev/null 2>&1
                echo -e "  [${GREEN}หยุดแล้ว${RESET}] ${a_name}"
            done
            run_shell am kill-all >/dev/null 2>&1
            echo -e "\n${GREEN}✅ สั่งหยุดทุกแอปและคืนพื้นที่ RAM เบื้องหลังเรียบร้อย!${RESET}"
            log_action "Force stopped common apps & ran am kill-all"
        fi
    elif [ "${fs_choice}" = "T" ] || [ "${fs_choice}" = "t" ]; then
        if confirm_action "ต้องการสั่งล้างแคชระบบ (pm trim-caches 999G) เพื่อคืนพื้นที่ /data ใช่หรือไม่?"; then
            echo -e "\n${CYAN}>> พื้นที่ /data ก่อนล้างแคช:${RESET}"
            run_shell df -h /data | sed 's/^/  /'
            run_shell pm trim-caches 999G
            echo -e "\n${CYAN}>> พื้นที่ /data หลังล้างแคช:${RESET}"
            run_shell df -h /data | sed 's/^/  /'
            echo -e "\n${GREEN}✅ ล้างแคชระบบเรียบร้อย!${RESET}"
            log_action "Ran pm trim-caches 999G"
        fi
    elif [[ "${fs_choice}" =~ ^[0-9]+$ ]] && [ "${fs_choice}" -ge 1 ] && [ "${fs_choice}" -le "${#common_apps[@]}" ]; then
        local sel_entry="${common_apps[$((fs_choice - 1))]}"
        local a_pkg a_name
        IFS='|' read -r a_pkg a_name <<< "${sel_entry}"
        if confirm_action "ต้องการ Force Stop แอป: ${a_name}"; then
            run_shell am force-stop "${a_pkg}" >/dev/null 2>&1
            echo -e "\n${GREEN}✅ สั่งหยุด ${a_name} เรียบร้อย!${RESET}"
        fi
    else
        echo -e "${RED}เลือกไม่ถูกต้อง${RESET}"
    fi

    pause_prompt
}

# ------------------------------------------------------------------------------
# Feature 7: List Disabled Packages
# ------------------------------------------------------------------------------
menu_list_disabled() {
    show_header
    echo -e "${BOLD}[7. รายการแอปที่ถูก Freeze อยู่ปัจจุบัน]${RESET}\n"
    
    local disabled
    disabled=$(run_shell pm list packages -d | sed 's/^package://' | tr -d '\r' | sort)

    if [ -z "${disabled}" ]; then
        echo -e "${GREEN}ไม่มีแพ็กเกจใดที่ถูก Freeze อยู่${RESET}"
    else
        local count
        count=$(echo "${disabled}" | grep -c .)
        echo -e "${CYAN}พบทั้งหมด ${count} แพ็กเกจที่ถูกปิดใช้งานอยู่:${RESET}"
        echo "${disabled}" | sed 's/^/  - /'
    fi

    pause_prompt
}

# ------------------------------------------------------------------------------
# Feature 8: Backup & Snapshot Report
# ------------------------------------------------------------------------------
menu_backup_snapshot() {
    show_header
    echo -e "${BOLD}[8. บันทึก Snapshot ข้อมูลเครื่องลงไฟล์ Backup]${RESET}\n"
    
    local timestamp
    timestamp=$(date "+%Y%m%d_%H%M%S")
    local snap_dir="${BACKUP_DIR}/snapshot_${timestamp}"
    mkdir -p "${snap_dir}"

    echo -e "${CYAN}กำลังบันทึกข้อมูลเครื่องลงไดเรกทอรี:${RESET} ${snap_dir}"
    echo "  - บันทึก getprop..."
    run_shell getprop > "${snap_dir}/android-getprop.txt"
    
    echo "  - บันทึก meminfo..."
    run_shell cat /proc/meminfo > "${snap_dir}/android-meminfo.txt"
    
    echo "  - บันทึก storage (df -h)..."
    run_shell df -h > "${snap_dir}/android-storage.txt"
    
    echo "  - บันทึกรายชื่อแพ็กเกจทั้งหมด..."
    run_shell pm list packages -f > "${snap_dir}/android-all-packages.txt"
    
    echo "  - บันทึกรายชื่อแพ็กเกจที่ถูกปิด..."
    run_shell pm list packages -d > "${snap_dir}/android-disabled-packages.txt"

    echo -e "\n${GREEN}✅ บันทึก Snapshot เรียบร้อยสมบูรณ์!${RESET}"
    log_action "Created system snapshot at: ${snap_dir}"
    pause_prompt
}

# ------------------------------------------------------------------------------
# Main Application Loop
# ------------------------------------------------------------------------------
main() {
    check_device_connection
    verify_redmi5a

    while true; do
        show_header
        echo -e "${BOLD}กรุณาเลือกเมนูที่ต้องการทำงาน:${RESET}"
        echo ""
        echo "  1) 📱 ตรวจสอบสถานะเครื่อง & ทรัพยากรระบบ (RAM, พื้นที่, แบตเตอรี่)"
        echo "  2) ⚡ ปรับความเร็ว Animation Scale (0.5x / 1.0x / 0x)"
        echo "  3) 🛡️  Freeze Bloatware & Telemetry (ปิดโฆษณา/ตัวส่องพฤติกรรม 36 รายการ)"
        echo "  4) 🔄 Unfreeze / Rollback คืนค่าแอปที่เคยปิดไว้"
        echo "  5) 🚀 ART Runtime Compilation (Compile Speed เพิ่มความเร็วแอป)"
        echo "  6) 🛑 Force Stop แอปชั่วคราว & ล้างแคชระบบ (Trim Caches)"
        echo "  7) 📋 ดูรายการแอปที่ถูก Freeze อยู่ปัจจุบัน"
        echo "  8) 💾 บันทึก Snapshot ข้อมูลเครื่องลงไฟล์ Backup"
        echo "  0) 🚪 ออกจากโปรแกรม"
        echo ""
        if ! read -r -p "เลือกเมนู (0-8): " choice; then
            echo -e "\n${GREEN}ออกจากโปรแกรม${RESET}"
            exit 0
        fi

        case "${choice}" in
            1) menu_system_info ;;
            2) menu_animation_tuning ;;
            3) menu_freeze_bloatware ;;
            4) menu_unfreeze_packages ;;
            5) menu_art_compilation ;;
            6) menu_force_stop ;;
            7) menu_list_disabled ;;
            8) menu_backup_snapshot ;;
            0)
                echo -e "\n${GREEN}ขอบคุณที่ใช้งาน ขอให้ใช้งาน Redmi 5A ได้อย่างลื่นไหลครับ!${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}เมนูไม่ถูกต้อง กรุณาเลือก 0-8${RESET}"
                sleep 1
                ;;
        esac
    done
}

main "$@"


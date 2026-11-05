#!/usr/bin/env bash
# ==============================================================================
# Script Name : tune-samsung-s7edge.sh
# Description : Interactive ADB Tuning, Debloat & Performance Utility
#               for Samsung Galaxy S7 Edge (SM-G935F / hero2lte / Exynos 8890)
#               & Samsung Experience 9.0 / One UI Devices
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
BACKUP_DIR="${HOME}/.samsung_tuning"
LOG_FILE="${BACKUP_DIR}/tuning_history.log"
mkdir -p "${BACKUP_DIR}"

TARGET_SERIAL=""
DEVICE_MODEL=""
DEVICE_BRAND=""
DEVICE_ANDROID=""
DEVICE_SEP=""
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
        echo -e "  1. เปิดโหมด Developer options บนเครื่อง Samsung (เคาะ Build number 7 ครั้ง)"
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

verify_samsung() {
    DEVICE_BRAND=$(run_shell getprop ro.product.manufacturer | tr -d '\r')
    DEVICE_MODEL=$(run_shell getprop ro.product.model | tr -d '\r')
    DEVICE_ANDROID=$(run_shell getprop ro.build.version.release | tr -d '\r')
    DEVICE_SEP=$(run_shell getprop ro.build.version.sep | tr -d '\r')
    DEVICE_BUILD=$(run_shell getprop ro.build.version.incremental | tr -d '\r')
    local device_codename
    device_codename=$(run_shell getprop ro.product.device | tr -d '\r')

    if [[ "${DEVICE_BRAND}" != *"samsung"* && "${DEVICE_BRAND}" != *"Samsung"* && "${DEVICE_MODEL}" != *"SM-"* ]]; then
        echo -e "${YELLOW}======================================================================${RESET}"
        echo -e "${YELLOW}[คำเตือน] อุปกรณ์ที่เชื่อมต่อคือ '${DEVICE_BRAND} ${DEVICE_MODEL}' (Codename: ${device_codename})${RESET}"
        echo -e "สคริปต์นี้ออกแบบมาสำหรับ ${BOLD}Samsung Galaxy (SM-G935F / hero2lte)${RESET} โดยเฉพาะ"
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
    echo -e "${BOLD}${CYAN}   🚀 SAMSUNG GALAXY (${DEVICE_MODEL}) - ADB TUNING & OPTIMIZATION      ${RESET}"
    echo -e "${BLUE}======================================================================${RESET}"
    echo -e " 📱 อุปกรณ์ : ${GREEN}${DEVICE_BRAND} ${DEVICE_MODEL}${RESET} (Serial: ${YELLOW}${TARGET_SERIAL}${RESET})"
    echo -e " ⚙️  ระบบ    : Android ${DEVICE_ANDROID} | SEP ${DEVICE_SEP:-9.0} (Build: ${DEVICE_BUILD})"
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
    echo "  - CPU / SoC      : $(run_shell getprop ro.hardware | tr -d '\r') ($(run_shell getprop ro.board.platform | tr -d '\r'))"
    echo "  - Device Codename: $(run_shell getprop ro.product.device | tr -d '\r') (${DEVICE_MODEL})"
    echo "  - Security Patch : $(run_shell getprop ro.build.version.security_patch | tr -d '\r')"
    echo "  - Firmware Build : ${DEVICE_BUILD} (CSC: $(run_shell getprop ro.csc.sales_code | tr -d '\r'))"
    echo ""

    echo -e "${CYAN}>> หน่วยความจำ (RAM 4GB):${RESET}"
    run_shell cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|Active\(anon\)|Inactive\(anon\)|SwapTotal|SwapFree" | sed 's/^/  /'
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
    echo "  - Window animation scale     : ${w_scale:-1.0}"
    echo "  - Transition animation scale : ${t_scale:-1.0}"
    echo "  - Animator duration scale    : ${a_scale:-1.0}"
    echo ""

    echo -e "${YELLOW}💡 คำแนะนำสำหรับเครื่อง Samsung Galaxy:${RESET}"
    echo "  - 0.5x : ลดระยะเวลาเอฟเฟกต์ลงครึ่งหนึ่ง ทำให้การเปิด-ปิดแอปและสลับหน้าต่างลื่นไหลทันใจ (แนะนำ)"
    echo "  - 1.0x : คืนค่ามาตรฐานโรงงานของ Samsung"
    echo "  - 0.0x : ปิดเอฟเฟกต์ทั้งหมด ประหยัดพลังงาน GPU Mali-T880 สูงสุด"
    echo ""

    echo "เลือกรูปแบบการปรับแต่ง:"
    echo "  1) ปรับเป็น 0.5x (แนะนำ - ตอบสนองไวขึ้นทันที)"
    echo "  2) ปรับเป็น 1.0x (คืนค่าเริ่มต้นของโรงงาน)"
    echo "  3) ปิดแอนิเมชันเป็น 0x (เร็วที่สุด ไม่แสดง Transition)"
    echo "  0) ยกเลิก / กลับสู่เมนูหลัก"
    echo ""
    read -r -p "เลือกข้อ (0-3): " anim_choice

    local target_val=""
    case "${anim_choice}" in
        1) target_val="0.5" ;;
        2) target_val="1.0" ;;
        3) target_val="0.0" ;;
        0) return 0 ;;
        *) echo -e "${RED}เลือกไม่ถูกต้อง${RESET}"; pause_prompt; return ;;
    esac

    if ! confirm_action "จะทำการปรับ Animation Scale ทุกตัวเป็น: ${target_val}x"; then
        pause_prompt
        return
    fi

    echo -e "\n${CYAN}กำลังส่งคำสั่งผ่าน ADB...${RESET}"
    run_shell settings put global window_animation_scale "${target_val}"
    run_shell settings put global transition_animation_scale "${target_val}"
    run_shell settings put global animator_duration_scale "${target_val}"

    echo -e "${GREEN}✅ ปรับค่า Animation เป็น ${target_val}x สำเร็จเรียบร้อย!${RESET}"
    log_action "Set animation scale to ${target_val}x"

    pause_prompt
}

# ------------------------------------------------------------------------------
# Feature 3: Freeze Bloatware & Telemetry
# ------------------------------------------------------------------------------

# Master list of 49 verified safe packages on Samsung (SM-G935F / hero2lte)
# Format: package_name|group_id|thai_description
PACKAGE_DATABASE=(
    # Group 1: Samsung Telemetry, Analytics & Diagnostic Loggers (10 packages)
    "com.sec.android.diagmonagent|1|DiagMonAgent (ตัวดักเก็บสถิติการใช้งานและรายงานข้อผิดพลาดส่งกลับ Samsung)"
    "com.samsung.android.rubin.app|1|Customization Service / Rubin (ติดตามพฤติกรรมและสถานที่ผู้ใช้เพื่อวิเคราะห์โฆษณา)"
    "com.samsung.android.providers.context|1|ContextProvider (ดักเก็บบริบทการใช้งานแอปเบื้องหลัง กินแรม 8.8 MB)"
    "com.samsung.android.intelligenceservice2|1|Intelligence Service 2 (เอนจินวิเคราะห์ข้อมูลพฤติกรรมผู้ใช้เบื้องหลัง)"
    "com.samsung.android.securitylogagent|1|SecurityLogAgent (ตัวดักล็อกความปลอดภัยและส่งแจ้งเตือนเบื้องหลัง)"
    "com.sec.modem.settings|1|SilentLog (ตัวดักเก็บล็อกโมเด็มและเครือข่ายเงียบๆ เบื้องหลัง)"
    "com.sec.imslogger|1|IMS Logger (ตัวดักล็อกการโทร VoLTE/IMS)"
    "com.samsung.android.svcagent|1|SVC Agent (เอเจนต์ตรวจสอบและส่งข้อมูลสถานะเครื่อง)"
    "com.sec.android.soagent|1|SOAgent (Software Tracking Agent เบื้องหลัง)"
    "com.google.android.feedback|1|Google Feedback (ตัวส่งรายงานข้อผิดพลาดของ Google)"

    # Group 2: Home Screen Briefing, Flipboard, Marketing Push & Edge Ads (8 packages)
    "com.sec.spp.push|2|Samsung Push Service (ยิงโฆษณาและการตลาดเบื้องหลัง กินแรม 17.7 MB)"
    "com.samsung.android.widgetapp.briefing|2|Briefing Panel (หน้าปัดซ้ายสุดของหน้าจอโฮมรวมฟีดข่าว/โฆษณา กินแรม 14.9 MB)"
    "flipboard.boxer.app|2|Flipboard Briefing (แอปฟีดข่าวและโฆษณาที่ผูกกับหน้าจอโฮม)"
    "com.samsung.privilege|2|Galaxy Gift / Samsung Privilege (แอปโปรโมชันและโฆษณาสิทธิพิเศษ)"
    "com.samsung.android.widgetapp.yahooedge.finance|2|Yahoo Finance Edge (วิตเจ็ตหุ้น Yahoo บนขอบจอแฝงโฆษณา)"
    "com.samsung.android.widgetapp.yahooedge.news|2|Yahoo News Edge (วิตเจ็ตข่าว Yahoo บนขอบจอ)"
    "com.samsung.android.widgetapp.yahooedge.sport|2|Yahoo Sports Edge (วิตเจ็ตกีฬา Yahoo บนขอบจอ)"
    "com.hiya.star|2|Hiya Caller ID Service (บริการฐานข้อมูลเบอร์โทรภายนอก)"

    # Group 3: Game Throttler (GOS) & Game Bloatware (4 packages)
    "com.enhance.gameservice|3|Game Optimizing Service / GOS (ตัวจำกัดความเร็ว CPU/GPU ขณะเล่นเกม - เทียบเท่า Joyose)"
    "com.samsung.android.game.gamehome|3|Samsung Game Launcher (ศูนย์รวมเกมที่มีแบนเนอร์โฆษณาเกม)"
    "com.samsung.android.game.gametools|3|Samsung Game Tools (ปุ่มลอยขณะเล่นเกม)"
    "com.samsung.enhanceservice|3|Samsung Enhance Service (เซอร์วิสปรับแต่งมีเดียเบื้องหลัง)"

    # Group 4: Facebook Pre-installed Trackers & McAfee Scanner (4 packages)
    "com.facebook.appmanager|4|Facebook App Manager (ตัวเช็กและอัปเดต Facebook เบื้องหลัง)"
    "com.facebook.services|4|Facebook Services (บริการ Telemetry และซิงก์ข้อมูลเบื้องหลังของ Facebook)"
    "com.facebook.system|4|Facebook System Installer (ตัวติดตั้ง Facebook ระดับระบบ)"
    "com.samsung.android.sm.devicesecurity|4|Device Security / McAfee (สแกนไวรัสเบื้องหลัง กินแรม 5.8 MB - เทียบเท่า GuardProvider)"

    # Group 5: Legacy S Voice, Gear VR, IoT Beacon, ANT+ & Office Stubs (23 packages)
    "com.samsung.voiceserviceplatform|5|S Voice Platform (ผู้ช่วยสั่งงานด้วยเสียงรุ่นเก่าที่ยุติบริการแล้ว)"
    "com.samsung.android.svoice|5|Voice Service Framework (เฟรมเวิร์กของ S Voice)"
    "com.samsung.android.voicewakeup|5|S Voice WakeUp (ตัวดักฟังเสียงปลุก S Voice เบื้องหลัง)"
    "com.samsung.svoice.sync|5|S Voice Sync / PLM"
    "com.sec.svoice.lang.en_GB|5|S Voice Language Pack (English UK)"
    "com.sec.svoice.lang.en_US|5|S Voice Language Pack (English US)"
    "com.sec.svoice.lang.fr_FR|5|S Voice Language Pack (French)"
    "com.sec.svoice.lang.de_DE|5|S Voice Language Pack (German)"
    "com.sec.svoice.lang.it_IT|5|S Voice Language Pack (Italian)"
    "com.sec.svoice.lang.ru_RU|5|S Voice Language Pack (Russian)"
    "com.sec.svoice.lang.es_ES|5|S Voice Language Pack (Spanish)"
    "com.samsung.android.hmt.vrsvc|5|Gear VR Service (เซอร์วิสแว่น VR ที่เลิกใช้งานแล้ว)"
    "com.samsung.android.app.withtv|5|Samsung withTV (บริการเชื่อมต่อทีวีรุ่นเก่า)"
    "com.samsung.android.beaconmanager|5|Samsung BeaconManager (สแกนหา Bluetooth/Wi-Fi Beacon รอบตัวตลอดเวลา)"
    "com.samsung.android.easysetup|5|Samsung EasySetup (ค้นหาอุปกรณ์ IoT รอบข้างตลอดเวลา)"
    "com.mobeam.barcodeService|5|Mobeam Barcode Beaming Service (บริการยิงบาร์โค้ดรุ่นเก่า)"
    "com.dsi.ant.server|5|ANT+ HAL Service (บริการเซนเซอร์ออกกำลังกาย ANT+)"
    "com.dsi.ant.service.socket|5|ANT+ Radio Service"
    "com.dsi.ant.plugins.antplus|5|ANT+ Plugins Service"
    "com.dsi.ant.sample.acquirechannels|5|ANT+ Acquire Channels Test"
    "com.microsoft.office.word|5|Microsoft Word Stub"
    "com.microsoft.office.excel|5|Microsoft Excel Stub"
    "com.microsoft.office.powerpoint|5|Microsoft PowerPoint Stub"
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
    
    echo -e "${YELLOW}💡 คำแนะนำและความปลอดภัยบนเครื่อง Samsung Galaxy:${RESET}"
    echo "  - การ Freeze จะใช้คำสั่ง 'pm disable-user --user 0' ร่วมกับ 'am force-stop'"
    echo "  - ข้อมูลและไฟล์ระบบ ${BOLD}จะไม่ถูกลบ${RESET} และสามารถกู้คืน (Unfreeze) กลับมาได้ตลอดเวลา"
    echo "  - ช่วยคืน RAM กว่า 500+ MB และตัดภาระ GOS Throttler, Briefing, Samsung Push"
    echo "  - ไม่กระทบต่อการโทร, SMS, Wi-Fi, กล้อง, LINE, WhatsApp หรือ Google Play Store"
    echo ""

    echo "เลือกกลุ่มที่ต้องการ Freeze:"
    echo "  1) 🛡️  Freeze ทุกกลุ่มที่แนะนำ (Safe All - ทั้ง 49 แพ็กเกจ) [แนะนำสูงสุด]"
    echo "  2) 📊 เฉพาะกลุ่ม Telemetry, Analytics & Diagnostic Loggers (10 รายการ)"
    echo "  3) 📢 เฉพาะกลุ่ม Briefing, Flipboard, Push Ads & Yahoo Edge (8 รายการ)"
    echo "  4) 🎮 เฉพาะกลุ่ม Game Optimizing Service (GOS) & Game Tools (4 รายการ)"
    echo "  5) 👤 เฉพาะกลุ่ม Facebook Trackers & McAfee Device Security (4 รายการ)"
    echo "  6) 🗑️  เฉพาะกลุ่ม Legacy S Voice, Gear VR, Beacon, ANT+ & Stubs (23 รายการ)"
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
    disabled_list=$(run_shell pm list packages -d | sed 's/^package://' | tr -d '\r' | sort)

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
            read -r -p "กรอกชื่อ Package Name (เช่น com.sec.spp.push): " custom_pkg
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
    
    echo -e "${YELLOW}💡 คำแนะนำสำหรับเครื่อง Samsung Galaxy (Android 8.0 Oreo):${RESET}"
    echo "  - รองรับทั้งคำสั่ง ${BOLD}cmd package bg-dexopt-job${RESET} และ ${BOLD}cmd package compile -m speed-profile -a${RESET}"
    echo "  - ช่วยจัดเรียงและคอมไพล์ไฟล์ .dex/.oat ล่วงหน้า ทำให้เปิดแอปเร็วขึ้นและลดการใช้ .dex mmap ใน RAM"
    echo ""
    echo "เลือกรูปแบบการ Compile:"
    echo "  1) ⚡ Background DEX Optimization (cmd package bg-dexopt-job) [แนะนำสูงสุด]"
    echo "  2) 🎯 Speed-Profile Optimization (-m speed-profile -a) [ละเอียดครบทุกแพ็กเกจ]"
    echo "  3) 🚀 Full Speed AOT Compilation (-m speed -a) [ใช้เวลา 5-15 นาที]"
    echo "  0) ยกเลิก"
    echo ""
    read -r -p "เลือกข้อ (0-3): " art_choice

    case "${art_choice}" in
        1)
            if confirm_action "ต้องการรัน Background DEX Optimization (bg-dexopt-job) ใช่หรือไม่?"; then
                echo -e "\n${CYAN}>> กำลังรัน cmd package bg-dexopt-job...${RESET}"
                echo -e "${YELLOW}กรุณาอย่าถอดสาย USB จนกว่าจะเสร็จสิ้น (ใช้เวลาประมาณ 1-3 นาที)${RESET}\n"
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
    echo "  - สั่งหยุดการทำงานของแอปใน RAM ชั่วคราว และสามารถสั่งล้างไฟล์แคชขยะ (pm trim-caches 999G)"
    echo "  - ช่วยคืนพื้นที่ /data และ RAM ได้ทันทีโดยไม่กระทบข้อมูลผู้ใช้"
    echo ""

    local common_apps=(
        "com.facebook.katana|Facebook"
        "com.instagram.android|Instagram"
        "com.google.android.youtube|YouTube"
        "com.google.android.gm|Gmail"
        "com.google.android.videos|Google Play Movies & TV"
        "com.spotify.music|Spotify"
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
    verify_samsung

    while true; do
        show_header
        echo -e "${BOLD}กรุณาเลือกเมนูที่ต้องการทำงาน:${RESET}"
        echo ""
        echo "  1) 📱 ตรวจสอบสถานะเครื่อง & ทรัพยากรระบบ (RAM, พื้นที่, แบตเตอรี่)"
        echo "  2) ⚡ ปรับความเร็ว Animation Scale (0.5x / 1.0x / 0x)"
        echo "  3) 🛡️  Freeze Bloatware & Telemetry (ปิดโฆษณา/GOS/Telemetry 49 รายการ)"
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
                echo -e "\n${GREEN}ขอบคุณที่ใช้งาน ขอให้ใช้งานเครื่อง Samsung ได้อย่างลื่นไหลครับ!${RESET}"
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

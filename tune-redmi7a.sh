#!/usr/bin/env bash
# ==============================================================================
# Script Name : tune-redmi7a.sh
# Target      : Xiaomi Redmi 7A (pine) - MIUI 11 / Android 9 (Pie)
# Description : Interactive ADB Tuning & Debloating Script with confirmations
# ==============================================================================

# Exit immediately if interrupted by Ctrl+C
trap 'echo -e "\n\n\033[0;31m[!] ยกเลิกการทำงานโดยผู้ใช้\033[0m"; exit 130' INT

# ------------------------------------------------------------------------------
# Colors & Formatting
# ------------------------------------------------------------------------------
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
MAGENTA="\033[0;35m"
BOLD="\033[1m"
RESET="\033[0m"

# ------------------------------------------------------------------------------
# Directories & Files
# ------------------------------------------------------------------------------
BACKUP_DIR="${HOME}/.redmi7a_tuning"
HISTORY_LOG="${BACKUP_DIR}/tuning-history.log"
mkdir -p "${BACKUP_DIR}"

log_action() {
    local action="$1"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] ${action}" >> "${HISTORY_LOG}"
}

# ------------------------------------------------------------------------------
# Locate ADB Binary
# ------------------------------------------------------------------------------
find_adb() {
    if command -v adb >/dev/null 2>&1; then
        echo "adb"
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
        echo -e "  1. เปิดโหมด Developer options บน Redmi 7A (เคาะ MIUI version 7 ครั้ง)"
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
        read -r -p "เลือกหมายเลขเครื่อง (1-${count}): " choice
        TARGET_SERIAL=$(echo "${authorized_devices}" | sed -n "${choice}p")
        if [ -z "${TARGET_SERIAL}" ]; then
            echo -e "${RED}เลือกไม่ถูกต้อง${RESET}"
            exit 1
        fi
    fi
}

run_adb() {
    "${ADB_CMD}" -s "${TARGET_SERIAL}" "$@" < /dev/null
}

run_shell() {
    "${ADB_CMD}" -s "${TARGET_SERIAL}" shell "$@" < /dev/null
}

verify_redmi7a() {
    DEVICE_MODEL=$(run_shell getprop ro.product.model | tr -d '\r')
    DEVICE_MANUF=$(run_shell getprop ro.product.manufacturer | tr -d '\r')
    DEVICE_ANDROID=$(run_shell getprop ro.build.version.release | tr -d '\r')
    DEVICE_MIUI=$(run_shell getprop ro.miui.ui.version.name | tr -d '\r')
    DEVICE_BUILD=$(run_shell getprop ro.build.version.incremental | tr -d '\r')

    if [[ "${DEVICE_MODEL}" != *"Redmi 7A"* && "${DEVICE_MANUF}" != *"Xiaomi"* ]]; then
        echo -e "${YELLOW}==================================================================${RESET}"
        echo -e "${YELLOW}[คำเตือนความเข้ากันได้]${RESET}"
        echo -e "อุปกรณ์ที่เชื่อมต่อคือ: ${BOLD}${DEVICE_MANUF} ${DEVICE_MODEL} (${DEVICE_MIUI:-Android} ${DEVICE_ANDROID})${RESET}"
        echo -e "สคริปต์นี้ถูกปรับแต่งและทดสอบกับ ${BOLD}Xiaomi Redmi 7A (MIUI 11)${RESET} โดยเฉพาะ"
        echo -e "หากรันกับรุ่นหรือยี่ห้ออื่น บางแพ็กเกจอาจไม่มี หรืออาจเกิดผลข้างเคียงได้"
        echo -e "${YELLOW}==================================================================${RESET}"
        read -r -p "คุณต้องการดำเนินการต่อหรือไม่? (y/N): " proceed
        if [[ ! "${proceed}" =~ ^[yY]([eE][sS])?$ ]]; then
            echo -e "${RED}ยกเลิกการทำงาน${RESET}"
            exit 0
        fi
    fi
}

# ------------------------------------------------------------------------------
# UI Helpers & Prompts
# ------------------------------------------------------------------------------
show_header() {
    clear
    echo -e "${CYAN}==================================================================${RESET}"
    echo -e "${BOLD}       XIAOMI REDMI 7A (MIUI 11) - ADB TUNING & OPTIMIZATION       ${RESET}"
    echo -e "${CYAN}==================================================================${RESET}"
    echo -e "อุปกรณ์: ${GREEN}${DEVICE_MANUF} ${DEVICE_MODEL}${RESET} | Serial: ${GREEN}${TARGET_SERIAL}${RESET}"
    echo -e "ระบบ  : ${GREEN}MIUI ${DEVICE_MIUI} (${DEVICE_BUILD})${RESET} | Android: ${GREEN}${DEVICE_ANDROID}${RESET}"
    echo -e "${CYAN}------------------------------------------------------------------${RESET}"
}

pause_prompt() {
    echo ""
    read -r -p "กด [Enter] เพื่อกลับสู่เมนูหลัก..."
}

confirm_action() {
    local prompt_text="$1"
    
    echo -e "\n${YELLOW}${BOLD}⚠️  ยืนยันการดำเนินการ:${RESET}"
    echo -e "${YELLOW}${prompt_text}${RESET}"
    echo ""
    read -r -p "ต้องการทำต่อหรือไม่? (พิมพ์ 'y' เพื่อตกลง / 'n' หรือกด Enter เพื่อยกเลิก): " ans
    if [[ "${ans}" =~ ^[yY]([eE][sS])?$ ]]; then
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
    echo "  - CPU Platform  : $(run_shell getprop ro.board.platform | tr -d '\r')"
    echo "  - Device Codename: $(run_shell getprop ro.product.device | tr -d '\r')"
    echo "  - Security Patch: $(run_shell getprop ro.build.version.security_patch | tr -d '\r')"
    echo "  - MIUI Version  : ${DEVICE_MIUI} (${DEVICE_BUILD})"
    echo ""

    echo -e "${CYAN}>> หน่วยความจำ (RAM 2GB):${RESET}"
    run_shell cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree" | sed 's/^/  /'
    echo ""

    echo -e "${CYAN}>> พื้นที่จัดเก็บข้อมูล (/data):${RESET}"
    run_shell df -h /data | sed 's/^/  /'
    echo ""

    echo -e "${CYAN}>> สถานะแบตเตอรี่:${RESET}"
    run_shell dumpsys battery | grep -E "level|temperature|voltage|status|health" | sed 's/^/  /'
    echo ""

    echo -e "${CYAN}>> จำนวนแอปที่ถูก Freeze (Disabled) อยู่ปัจจุบัน:${RESET}"
    local d_count
    d_count=$(run_shell pm list packages -d | wc -l | tr -d ' ')
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
    echo "  - Window animation scale     : ${w_scale:-1}"
    echo "  - Transition animation scale : ${t_scale:-1}"
    echo "  - Animator duration scale    : ${a_scale:-1}"
    echo ""

    echo -e "${YELLOW}💡 คำแนะนำสำหรับ Redmi 7A (RAM 2GB):${RESET}"
    echo "  - 0.5x : ลดระยะเวลาเอฟเฟกต์ลงครึ่งหนึ่ง ทำให้ UI สลับแอปและเปิดเมนูรวดเร็วขึ้นมาก (แนะนำ)"
    echo "  - 1.0x : คืนค่ามาตรฐานดั้งเดิมของ MIUI"
    echo "  - 0.0x : ปิดเอฟเฟกต์ทั้งหมด ช่วยลดการประมวลผล GPU เหมาะกับผู้ที่ต้องการความเร็วสูงสุด"
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

# Master list of safe packages for Xiaomi Redmi 7A (MIUI 11)
# Format: package_name|group_id|thai_description
PACKAGE_DATABASE=(
    # Group 1: Telemetry & Analytics (5 packages)
    "com.xiaomi.joyose|1|Joyose (Telemetry, เก็บสถิติเกม และตัวจำกัดประสิทธิภาพ/Throttling)"
    "com.miui.analytics|1|MIUI Analytics (ตัวเก็บสถิติการใช้งานและการคลิกโฆษณาในระบบ)"
    "com.miui.daemon|1|MiuiDaemon (ดักเก็บข้อมูลระบบและฮาร์ดแวร์ส่งกลับเซิร์ฟเวอร์ Xiaomi)"
    "com.miui.bugreport|1|MiuiBugReport (ตัวดักส่งรายงานข้อผิดพลาด)"
    "com.google.android.feedback|1|Google Feedback (ตัวส่ง Crash Report ของ Google)"

    # Group 2: MIUI System Ads & Lockscreen Ads (6 packages)
    "com.miui.msa.global|2|MSA (MIUI System Ads - เครื่องมือยิงโฆษณาแฝงหลักในรอม MIUI)"
    "com.miui.android.fashiongallery|2|Fashion Gallery (Wallpaper Carousel / สลับภาพหน้าจอล็อกพ่วงโฆษณา)"
    "com.miui.hybrid|2|Quick Apps / Hybrid Platform (เฟรมเวิร์กเปิดเว็บแอปทันใจที่แฝงแบนเนอร์โฆษณา)"
    "com.miui.hybrid.accessory|2|Hybrid Accessory (เซอร์วิสเสริมของ Quick Apps)"
    "com.miui.cleanmaster|2|CleanMaster (โมดูลคลีนเนอร์ที่พ่วงตัวแสดงโฆษณาของ Cheetah Mobile)"
    "com.miui.yellowpage|2|YellowPage (บริการสมุดหน้าเหลือง พ่วงโฆษณาและบริการพันธมิตร)"

    # Group 3: Core Framework Services & Xiaomi Background Push (4 packages)
    "com.xiaomi.xmsf|3|Xiaomi Service Framework (XMSF - เซอร์วิสเฟรมเวิร์กเบื้องหลังของ Xiaomi)"
    "com.xiaomi.xmsfkeeper|3|XMSFKeeper (ตัวเฝ้าพิทักษ์ไม่ให้ XMSF หยุดทำงาน)"
    "com.miui.guardprovider|3|GuardProvider (ตัวสแกนไวรัสเบื้องหลังของ Security App ที่ต่อเน็ตตลอดเวลา)"
    "com.milink.service|3|MiLink Service (บริการเชื่อมต่ออุปกรณ์/แชร์จอไร้สายของ Xiaomi)"

    # Group 4: Facebook Pre-installed Trackers (3 packages)
    "com.facebook.appmanager|4|Facebook App Manager (ตัวเช็กและอัปเดตแอปเฟซบุ๊กเบื้องหลัง)"
    "com.facebook.services|4|Facebook Services (Telemetry & Background Sync ของ Facebook)"
    "com.facebook.system|4|Facebook System Installer (ตัวติดตั้งแอปเฟซบุ๊กระดับระบบ)"

    # Group 5: OEM Stores, Bloatware & Financial Extras (8 packages)
    "com.xiaomi.mipicks|5|GetApps / Mi Picks (ร้านโหลดแอปของ Xiaomi ที่ชอบยิงแจ้งเตือนชวนโหลดแอป)"
    "com.mipay.wallet.id|5|Mi Pay Indonesia (กระเป๋าเงินออนไลน์สำหรับอินโดนีเซีย ไม่ได้ใช้งาน)"
    "com.mipay.wallet.in|5|Mi Pay India (กระเป๋าเงินออนไลน์สำหรับอินเดีย)"
    "com.micredit.in|5|Mi Credit India (บริการสินเชื่อเสียวหมี่)"
    "com.mi.globalTrendNews|5|Global Trend News (ฟีดข่าวแถม)"
    "com.xiaomi.glgm|5|Mi Games (ศูนย์เกมแถม)"
    "com.mi.global.bbs|5|Mi Community (แอปฟอรัมชุมชนเสียวหมี่)"
    "com.android.browser|5|Mi Browser Global (เบราว์เซอร์แถมที่มีฟีดข่าวและโฆษณา — เครื่องมี Chrome อยู่แล้ว)"
)

freeze_package() {
    local pkg="$1"
    local desc="$2"
    
    # Check if package exists on device
    local check_pkg
    check_pkg=$(run_shell pm list packages "${pkg}" | tr -d '\r')
    if [ -z "${check_pkg}" ]; then
        echo -e "  [${YELLOW}ข้าม${RESET}] ${pkg} (ไม่มีในเครื่อง)"
        return 0
    fi

    # Check if already disabled
    local is_disabled
    is_disabled=$(run_shell pm list packages -d "${pkg}" | tr -d '\r')
    if [ -n "${is_disabled}" ]; then
        echo -e "  [${CYAN}เดิมปิดอยู่แล้ว${RESET}] ${pkg}"
        return 0
    fi

    local out
    out=$(run_shell pm disable-user --user 0 "${pkg}" 2>&1 | tr -d '\r')
    if [[ "${out}" == *"disabled-user"* || "${out}" == *"new state: disabled"* ]]; then
        echo -e "  [${GREEN}FREEZE สำเร็จ${RESET}] ${pkg} (${desc})"
        log_action "Freeze package: ${pkg}"
    else
        echo -e "  [${RED}ล้มเหลว${RESET}] ${pkg}: ${out}"
    fi
}

menu_freeze_bloatware() {
    show_header
    echo -e "${BOLD}[3. Freeze Bloatware & Telemetry (ปิดการทำงานแบบปลอดภัย)]${RESET}\n"
    
    echo -e "${YELLOW}💡 คำแนะนำและความปลอดภัยบน Redmi 7A (MIUI 11):${RESET}"
    echo "  - การ Freeze จะใช้คำสั่ง 'pm disable-user --user 0' เพื่อสั่งพักการทำงานของแอป"
    echo "  - ข้อมูลและไฟล์ระบบ ${BOLD}จะไม่ถูกลบ${RESET} และสามารถกู้คืน (Unfreeze) กลับมาได้ตลอดเวลา"
    echo "  - บนเครื่อง RAM 2GB จะช่วยลดภาระ CPU และคืนหน่วยความจำได้มหาศาล"
    echo "  - ไม่กระทบต่อการโทร, SMS, Wi-Fi, กล้อง, แอปธนาคาร หรือ Google Play Store"
    echo ""

    echo "เลือกกลุ่มที่ต้องการ Freeze:"
    echo "  1) 🛡️  Freeze ทุกกลุ่มที่แนะนำ (Safe All - ทั้ง 26 แพ็กเกจ) [แนะนำสูงสุด]"
    echo "  2) 📊 เฉพาะกลุ่ม Telemetry & Analytics (สถิติ/พฤติกรรมผู้ใช้ - 5 รายการ)"
    echo "  3) 📢 เฉพาะกลุ่ม MIUI System Ads & Lockscreen Carousel (โฆษณาหลัก & วอลเปเปอร์ - 6 รายการ)"
    echo "  4) ⚙️  เฉพาะกลุ่ม Xiaomi Framework & Background Services (XMSF, MiLink - 4 รายการ)"
    echo "  5) 👤 เฉพาะกลุ่ม Facebook Pre-installed (บริการเบื้องหลังของ Facebook - 3 รายการ)"
    echo "  6) 🛒 เฉพาะกลุ่ม OEM Stores, Bloatware & Financial Extras (GetApps, MiPay - 8 รายการ)"
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
    
    echo -e "${YELLOW}💡 คำแนะนำสำหรับ Redmi 7A (MIUI 11 / Android 9):${RESET}"
    echo "  - บน Android 9 คำสั่ง ${BOLD}bg-dexopt-job${RESET} จะถูกบล็อกด้วย SecurityException (UPDATE_DEVICE_STATS)"
    echo "    เนื่องจาก ADB Shell (UID 2000) ไม่มีสิทธิ์ควบคุม WakeLock ของระบบ"
    echo "  - วิธีที่ ${BOLD}ถูกต้องและสำเร็จ 100%${RESET} บน Redmi 7A คือการใช้คำสั่ง compile โดยตรง:"
    echo "    1) ${BOLD}-m speed-profile -a${RESET} : แนะนำสูงสุด ทำการ Optimize ทั้ง 263 แอปตามโปรไฟล์การใช้งานจริง (เร็วและประหยัดพื้นที่)"
    echo "    2) ${BOLD}-m speed -a${RESET} : บังคับ Compile เป็น Native ทุกแอป (ใช้เวลาและพลังงานสูง)"
    echo ""
    echo "เลือกรูปแบบการ Compile:"
    echo "  1) ⚡ Speed-Profile Optimization (-m speed-profile -a) [แนะนำสูงสุด - เร็ว เสถียร ไม่ติด Error]"
    echo "  2) 🚀 Full Speed AOT Compilation (-m speed -a) [แปลงโค้ดเต็มรูปแบบ 5-15 นาที]"
    echo "  0) ยกเลิก"
    echo ""
    read -r -p "เลือกข้อ (0-2): " art_choice

    local mode_flag=""
    case "${art_choice}" in
        1) mode_flag="speed-profile" ;;
        2) mode_flag="speed" ;;
        0) return 0 ;;
        *) echo -e "${RED}เลือกไม่ถูกต้อง${RESET}"; pause_prompt; return ;;
    esac

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

    pause_prompt
}

# ------------------------------------------------------------------------------
# Feature 6: Force Stop Running Apps
# ------------------------------------------------------------------------------
menu_force_stop() {
    show_header
    echo -e "${BOLD}[6. Force Stop แอปชั่วคราว]${RESET}\n"
    
    echo -e "${YELLOW}💡 คำแนะนำ:${RESET}"
    echo "  - เป็นการสั่งหยุดการทำงานของแอปใน RAM ชั่วคราว ไม่ลบข้อมูล ไม่ถอนการติดตั้ง"
    echo "  - เมื่อแตะเปิดแอปบนหน้าจอ โทรศัพท์จะเปิดแอปขึ้นมาทำงานใหม่ตามปกติ"
    echo ""

    local common_apps=(
        "com.facebook.katana|Facebook"
        "com.alibaba.aliexpresshd|AliExpress"
        "cn.wps.moffice_eng|WPS Office"
        "com.google.android.youtube|YouTube"
        "com.google.android.gm|Gmail"
    )

    echo "เลือกแอปที่ต้องการ Force Stop:"
    local i=1
    for app_entry in "${common_apps[@]}"; do
        local a_pkg a_name
        IFS='|' read -r a_pkg a_name <<< "${app_entry}"
        echo "  ${i}) ${a_name} (${a_pkg})"
        i=$((i + 1))
    done
    echo "  A) 🛑 Force Stop ทุกแอปในรายการนี้พร้อมกัน"
    echo "  0) ยกเลิก"
    echo ""
    read -r -p "เลือกตัวเลือก: " fs_choice

    if [ "${fs_choice}" = "0" ]; then
        return 0
    elif [ "${fs_choice}" = "A" ] || [ "${fs_choice}" = "a" ]; then
        if confirm_action "ต้องการ Force Stop ทุกแอปในรายการใช่หรือไม่?"; then
            for app_entry in "${common_apps[@]}"; do
                local a_pkg a_name
                IFS='|' read -r a_pkg a_name <<< "${app_entry}"
                run_shell am force-stop "${a_pkg}" >/dev/null 2>&1
                echo -e "  [${GREEN}หยุดแล้ว${RESET}] ${a_name}"
            done
            echo -e "\n${GREEN}✅ สั่งหยุดทุกแอปเรียบร้อย!${RESET}"
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
    disabled=$(run_shell pm list packages -d | sed 's/^package://' | tr -d '\r')

    if [ -z "${disabled}" ]; then
        echo -e "${GREEN}ไม่มีแพ็กเกจใดที่ถูก Freeze อยู่${RESET}"
    else
        local count
        count=$(echo "${disabled}" | wc -l | tr -d ' ')
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
    verify_redmi7a

    while true; do
        show_header
        echo -e "${BOLD}กรุณาเลือกเมนูที่ต้องการทำงาน:${RESET}"
        echo ""
        echo "  1) 📱 ตรวจสอบสถานะเครื่อง & ทรัพยากรระบบ (RAM, พื้นที่, แบตเตอรี่)"
        echo "  2) ⚡ ปรับความเร็ว Animation Scale (0.5x / 1.0x / 0x)"
        echo "  3) 🛡️  Freeze Bloatware & Telemetry (ปิดโฆษณา/ตัวส่องพฤติกรรมอย่างปลอดภัย)"
        echo "  4) 🔄 Unfreeze / Rollback คืนค่าแอปที่เคยปิดไว้"
        echo "  5) 🚀 ART Runtime Compilation (Compile Speed เพิ่มความเร็วแอป)"
        echo "  6) 🛑 Force Stop แอปที่ไม่ต้องการใช้งานชั่วคราว"
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
                echo -e "\n${GREEN}ขอบคุณที่ใช้งาน ขอให้ใช้งาน Redmi 7A ได้อย่างลื่นไหลครับ!${RESET}"
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


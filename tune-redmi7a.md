# คู่มือการปรับแต่ง Xiaomi Redmi 7A ด้วย `tune-redmi7a.sh`

คู่มือฉบับสมบูรณ์สำหรับการปรับแต่งประสิทธิภาพ ปิดระบบโฆษณา MIUI, เซอร์วิส Telemetry, ตัวลดประสิทธิภาพซีพียู (Joyose) และ Bloatware สำหรับ **Xiaomi Redmi 7A (pine)** ผ่าน ADB โดย **ไม่ต้อง Root เครื่อง**

> **เป้าหมายหลัก:** คืนทรัพยากรหน่วยความจำและ CPU สำหรับเครื่อง RAM 2 GB, กำจัดโฆษณาแฝงในระบบ MIUI (MSA, Quick Apps, Wallpaper Carousel), ตัดการทำงานของ Joyose Throttler, แก้ปัญหาข้อจำกัดของ ART Compilation บน Android 9 และเก็บสำรอง Snapshot ข้อมูลเครื่องอย่างปลอดภัย โดยมีระบบถามยืนยัน (Confirm) ก่อนเปลี่ยนแปลงทุกครั้ง

---

## สารบัญ

1. [ข้อมูลเฉพาะของเครื่อง Xiaomi Redmi 7A](#1-ข้อมูลเฉพาะของเครื่อง-xiaomi-redmi-7a)
2. [ตารางเปรียบเทียบเชิงลึก: Redmi 7A (MIUI 11) vs realme 5s (ColorOS)](#2-ตารางเปรียบเทียบเชิงลึก-redmi-7a-miui-11-vs-realme-5s-coloros)
3. [ผลการสแกนและค้นหา Bloatware บนเครื่องจริง (Actual Device Audit)](#3-ผลการสแกนและค้นหา-bloatware-บนเครื่องจริง-actual-device-audit)
   - [3.1 สภาพแวดล้อมเครื่องที่สแกนจริง](#31-สภาพแวดล้อมเครื่องที่สแกนจริง)
   - [3.2 รายการ Bloatware / Telemetry ที่ตรวจพบจริงพร้อมพาธ APK](#32-รายการ-bloatware--telemetry-ที่ตรวจพบจริงพร้อมพาธ-apk)
   - [3.3 ผลการทดสอบ Freeze และการตรวจสอบ Process ใน RAM](#33-ผลการทดสอบ-freeze-และการตรวจสอบ-process-ใน-ram)
   - [3.4 เจาะลึกปัญหา ART Compilation และทางออกที่สำเร็จ 100%](#34-เจาะลึกปัญหา-art-compilation-และทางออกที่สำเร็จ-100)
4. [สิ่งที่ต้องเตรียมก่อนเริ่มใช้งาน](#4-สิ่งที่ต้องเตรียมก่อนเริ่มใช้งาน)
5. [การเริ่มใช้งานสคริปต์ (Quick Start)](#5-การเริ่มใช้งานสคริปต์-quick-start)
6. [รายละเอียดการทำงานของแต่ละเมนูในสคริปต์](#6-รายละเอียดการทำงานของแต่ละเมนูในสคริปต์)
   - [เมนู 1: ตรวจสอบสถานะเครื่อง & ทรัพยากรระบบ](#เมนู-1-📱-ตรวจสอบสถานะเครื่อง--ทรัพยากรระบบ)
   - [เมนู 2: ปรับความเร็ว Animation Scale](#เมนู-2-⚡-ปรับความเร็ว-animation-scale)
   - [เมนู 3: Freeze Bloatware & Telemetry](#เมนู-3-🛡️-freeze-bloatware--telemetry)
   - [เมนู 4: Unfreeze / Rollback คืนค่าแอป](#เมนู-4-🔄-unfreeze--rollback-คืนค่าแอป)
   - [เมนู 5: ART Runtime Compilation (Speed-Profile)](#เมนู-5-🚀-art-runtime-compilation-speed-profile)
   - [เมนู 6: Force Stop แอปชั่วคราว](#เมนู-6-🛑-force-stop-แอปชั่วคราว)
   - [เมนู 7: ดูรายการแอปที่ถูก Freeze อยู่ปัจจุบัน](#เมนู-7-📋-ดูรายการแอปที่ถูก-freeze-อยู่ปัจจุบัน)
   - [เมนู 8: บันทึก Snapshot ข้อมูลเครื่อง](#เมนู-8-💾-บันทึก-snapshot-ข้อมูลเครื่อง)
7. [ฐานข้อมูลแพ็กเกจที่ถูก Freeze (26 รายการ)](#7-ฐานข้อมูลแพ็กเกจที่ถูก-freeze-26-รายการ)
8. [ไดเรกทอรีบันทึกข้อมูลและประวัติการทำงาน](#8-ไดเรกทอรีบันทึกข้อมูลและประวัติการทำงาน)
9. [การแก้ไขปัญหาและคำถามที่พบบ่อย (FAQ)](#9-การแก้ไขปัญหาและคำถามที่พบบ่อย-faq)
10. [ตารางคำสั่ง ADB ฉบับย่อ (Quick Reference)](#10-ตารางคำสั่ง-adb-ฉบับย่อ-quick-reference)

---

## 1. ข้อมูลเฉพาะของเครื่อง Xiaomi Redmi 7A

* **รหัสรุ่น (Model):** `Redmi 7A`
* **รหัสประจำอุปกรณ์ (Codename):** `pine`
* **ชิปประมวลผล:** Qualcomm Snapdragon 439 (`msm8937` platform) Octa-Core (4x 1.95 GHz Cortex-A53 & 4x 1.45 GHz Cortex-A53, GPU Adreno 505)
* **หน่วยความจำ:** RAM 2 GB (Physical: 1,902,560 kB) / ROM 16 หรือ 32 GB eMMC 5.1
* **ระบบปฏิบัติการ:** MIUI 11 Global (`V11.0.7.0.PCMMIXM`) บนฐาน Android 9 Pie (API 28, Security Patch 2020-03-01)
* **ความสำคัญของการ Debloat บนรุ่นนี้:**
  * Redmi 7A เป็นสมาร์ตโฟนสเปกระดับเริ่มต้นที่มี RAM เพียง 2 GB แต่รอม MIUI 11 ทำงานพร้อมเซอร์วิสเบื้องหลังจำนวนมาก เช่น **MSA** (ยิงโฆษณา), **Joyose** (คอยดักจับสถิติและลดคล็อกความเร็ว CPU/GPU), **MIUI Analytics**, **XMSF**, และ **GuardProvider**
  * บริการเหล่านี้แย่งการใช้งาน RAM ไปกว่า 400 - 600 MB ตลอดเวลา ส่งผลให้เกิดอาการ UI กระตุก หน่วง และระบบ Low Memory Killer (LMK) จะบังคับปิด (Force-kill) แอปที่เปิดสลับไปมาทันที
  * การ Freeze บริการเหล่านี้ออก จะช่วยลดภาระ CPU และช่วยให้การใช้งานประจำวันลื่นไหลขึ้นอย่างชัดเจน

---

## 2. ตารางเปรียบเทียบเชิงลึก: Redmi 7A (MIUI 11) vs realme 5s (ColorOS)

จากการทดสอบจริงผ่าน ADB บนเครื่องทั้งสองรุ่น พบพฤติกรรมและข้อจำกัดของระบบปฏิบัติการที่แตกต่างกันอย่างมีนัยสำคัญ:

| หัวข้อการทดสอบ | Xiaomi Redmi 7A (MIUI 11 / Android 9) | realme 5s (ColorOS 7 / Android 10) |
|---|---|---|
| **Animation Scale ผ่าน ADB** | ✅ **ปรับได้ทันที** ผ่าน `settings put global` โดยไม่ต้องตั้งค่า Security เพิ่มเติม | ❌ **ถูกบล็อก** ด้วย `WRITE_SECURE_SETTINGS` ต้องปรับผ่านหน้าจอ Developer Options ด้วยตนเอง |
| **คำสั่ง `cmd package bg-dexopt-job`** | ❌ **ล้มเหลว** เกิด `SecurityException: UPDATE_DEVICE_STATS` เพราะ Shell (UID 2000) ไม่มีสิทธิ์ควบคุม WakeLock WorkSource | ✅ **ทำงานสำเร็จ** (`Success`) รัน Background DEX Optimization ได้ตามปกติ |
| **คำสั่ง `cmd package compile -m speed-profile -a`** | ✅ **ทำงานสำเร็จสมบูรณ์ (263/263)** จบในเวลาเพียง 40 วินาที โดยไม่ติด Error ใดๆ | ❌ **ถูกบล็อก** ด้วย `Error: Failed to cpmpile !` (ข้อจำกัดของ OppoPackageManagerService) |
| **การ Freeze แอปเกมประจำค่าย** | ✅ `com.xiaomi.glgm` สามารถสั่ง Freeze ได้ตามปกติ | ❌ `com.nearme.gamecenter` ถูกบล็อกด้วย SecurityException ต้องใช้ `am force-stop` แทน |
| **ระบบโฆษณาและ Bloatware** | ใช้ระบบ **MSA**, **Joyose**, **Quick Apps (Hybrid)**, **Fashion Gallery (Glance)**, **XMSF** | ใช้ระบบ **HeyTap Pictorial**, **NearMe/Oppo Atlas**, **HeyTap Market**, **Oppo DCS** |

---

## 3. ผลการสแกนและค้นหา Bloatware บนเครื่องจริง (Actual Device Audit)

ผลการสำรวจ เจาะลึก และทดสอบจริงบนเครื่อง Redmi 7A (Serial: `16b6dea09806`):

### 3.1 สภาพแวดล้อมเครื่องที่สแกนจริง
* **Device Serial:** `16b6dea09806`
* **Model / Codename:** `Xiaomi Redmi 7A` (`pine`)
* **OS / Build:** MIUI Global 11.0.7.0 (`V11.0.7.0.PCMMIXM`) / Android 9 Pie
* **พื้นที่จัดเก็บข้อมูล (/data):** ขนาดรวม 23 GB (ใช้งาน 8.7 GB, ว่าง 14 GB ~ 39% Use)
* **จำนวนแพ็กเกจทั้งหมดในระบบ:** **263 แพ็กเกจ**

---

### 3.2 รายการ Bloatware / Telemetry ที่ตรวจพบจริงพร้อมพาธ APK
จากการสแกนโครงสร้างแพ็กเกจทั้งหมด (`pm list packages -f`) ตรวจพบไฟล์ APK ติดตั้งอยู่ในระบบจริงดังนี้:

| หมวดหมู่ | Package Name | ตำแหน่งไฟล์ APK ในเครื่องจริง | บทบาทและพฤติกรรมของเซอร์วิส |
|---|---|---|---|
| **Throttler / Telemetry** | `com.xiaomi.joyose` | `/system/app/Joyose/Joyose.apk` | ตัวเก็บสถิติเกมและควบคุมการจำกัดสัญญาณนาฬิกา CPU/GPU ทำให้เครื่องหน่วง |
| **Telemetry** | `com.miui.analytics` | `/data/app/com.miui.analytics-.../base.apk` | ดักเก็บสถิติการใช้งาน พฤติกรรม และการคลิกโฆษณาในระบบ MIUI |
| **System Daemon** | `com.miui.daemon` | `/system/app/MiuiDaemon/MiuiDaemon.apk` | ดักเก็บข้อมูลระบบและฮาร์ดแวร์ส่งกลับเซิร์ฟเวอร์ Xiaomi ตลอดเวลา |
| **Bug Reporter** | `com.miui.bugreport` | `/system/app/MiuiBugReport/MiuiBugReport.apk` | ตัวส่งรายงานข้อผิดพลาดและ Crash log |
| **Crash Report** | `com.google.android.feedback` | `/system/priv-app/GoogleFeedback/...apk` | ตัวส่ง Feedback ข้อผิดพลาดของ Google |
| **Main Ad Engine** | `com.miui.msa.global` | `/data/app/com.miui.msa.global-.../base.apk` | เครื่องมือยิงโฆษณาแฝงหลักในระบบ MIUI (ในโฟลเดอร์, การตั้งค่า, ระบบ) |
| **Lockscreen Ads** | `com.miui.android.fashiongallery` | `/data/app/com.miui.android.fashiongallery-.../base.apk` | วอลเปเปอร์หน้าจอล็อก (Glance) มีการแอบโหลดแบนเนอร์โฆษณาและกินเน็ตเบื้องหลัง |
| **Quick Apps Ads** | `com.miui.hybrid` | `/system/app/HybridPlatform/HybridPlatform.apk` | แพลตฟอร์มรันเว็บแอปทันใจที่แฝงโฆษณาแบนเนอร์ |
| **Quick Apps Aux** | `com.miui.hybrid.accessory` | `/system/app/HybridAccessory/HybridAccessory.apk` | เซอร์วิสเสริมของ Hybrid Platform |
| **Cleaner Ads** | `com.miui.cleanmaster` | `/data/app/com.miui.cleanmaster-.../base.apk` | คลีนเนอร์พ่วงโมดูลโฆษณาของ Cheetah Mobile |
| **Directory Ads** | `com.miui.yellowpage` | `/system/priv-app/YellowPage/YellowPage.apk` | สมุดหน้าเหลืองพ่วงโฆษณาและบริการเสริม |
| **Framework Service**| `com.xiaomi.xmsf` | `/data/app/com.xiaomi.xmsf-.../base.apk` | Xiaomi Service Framework ทำงานเบื้องหลังตลอดเวลา |
| **Framework Keeper** | `com.xiaomi.xmsfkeeper` | `/system/app/XMSFKeeper/XMSFKeeper.apk` | ตัวเฝ้าพิทักษ์ไม่ให้ XMSF หยุดทำงาน |
| **Security Scanner** | `com.miui.guardprovider` | `/system/app/GuardProvider/GuardProvider.apk` | ตัวสแกนไวรัสเบื้องหลังของ Security App ที่ชอบต่อเน็ตและกินแบต |
| **Screen Share** | `com.milink.service` | `/system/app/MiLinkService2/MiLinkService2.apk` | บริการแชร์จอไร้สายและเชื่อมต่ออุปกรณ์ IoT ของ Xiaomi |
| **Facebook Tracker**| `com.facebook.appmanager` | `/system/app/facebook-appmanager/...apk` | ตัวตรวจเช็กและอัปเดตแอป Facebook เบื้องหลังโดยไม่ผ่าน Play Store |
| **Facebook Tracker**| `com.facebook.services` | `/system/priv-app/facebook-services/...apk` | บริการ Sync และดักเก็บ Telemetry ของ Facebook ตลอดเวลา |
| **Facebook Tracker**| `com.facebook.system` | `/system/priv-app/facebook-installer/...apk` | ตัวติดตั้ง Facebook ฝังระดับระบบ |
| **OEM Store** | `com.xiaomi.mipicks` | `/data/app/com.xiaomi.mipicks-.../base.apk` | ร้านโหลดแอป GetApps ที่คอยยิงการแจ้งเตือนชวนโหลดแอป |
| **Wallet Bloat** | `com.mipay.wallet.id` | `/system/app/IdMipay/IdMipay.apk` | กระเป๋าเงิน Mi Pay อินโดนีเซีย ไม่ได้ใช้งาน |
| **Community App** | `com.mi.global.bbs` | `/data/app/com.mi.global.bbs-.../base.apk` | แอปฟอรัมคอมมูนิตี้ Xiaomi |
| **OEM Browser** | `com.android.browser` | `/system/priv-app/MiuiBrowserGlobal/...apk` | เบราว์เซอร์แถมที่มีฟีดข่าวและโฆษณาจำนวนมาก (เครื่องมี Chrome อยู่แล้ว) |

---

### 3.3 ผลการทดสอบ Freeze และการตรวจสอบ Process ใน RAM
1. **แพ็กเกจเดิมที่ถูกปิดอยู่แล้วก่อนเริ่มสแกน (6 แพ็กเกจ):**
   * `com.android.fileexplorer`, `com.google.android.webview`, `com.xiaomi.glgm` (Mi Games), `com.mi.globalTrendNews`, `com.micredit.in`, `com.mipay.wallet.in`
2. **แพ็กเกจที่สั่ง Freeze สำเร็จรอบนี้ (22 แพ็กเกจ):**
   * ทุกแพ็กเกจในตารางด้านบนเปลี่ยนสถานะเป็น `disabled-user` สำเร็จครบถ้วน 100%
   * รวมแพ็กเกจที่ถูก Freeze ในปัจจุบัน: **28 แพ็กเกจ**
3. **การตรวจสอบสถานะ Process ผ่าน `dumpsys meminfo`:**
   * `adb shell dumpsys meminfo com.miui.msa.global` ➔ **`No process found`**
   * `adb shell dumpsys meminfo com.miui.analytics` ➔ **`No process found`**
   * `adb shell dumpsys meminfo com.xiaomi.joyose` ➔ **`No process found`**
   * ยืนยันว่าโปรเซสโฆษณาและ Telemetry ถูกตัดการทำงานออกจาก RAM ทันที
4. **ความสมบูรณ์ของระบบหลัง Freeze:**
   * สถานะ `sys.boot_completed = 1`
   * การโทรเข้า-ออก, SMS, กล้องถ่ายรูป, สัญญาณ 4G/VoLTE, Wi-Fi, Bluetooth และ Google Play Store ใช้งานได้สมบูรณ์ ไร้อาการ Force Close

---

### 3.4 เจาะลึกปัญหา ART Compilation และทางออกที่สำเร็จ 100%

#### สาเหตุของข้อผิดพลาด `UPDATE_DEVICE_STATS`:
เมื่อผู้ใช้รันคำสั่ง `adb shell cmd package bg-dexopt-job` บน Redmi 7A ระบบจะฟ้อง Error:
```text
Security exception: Neither user 2000 nor current process has android.permission.UPDATE_DEVICE_STATS.
	at android.app.ContextImpl.enforce(ContextImpl.java:1822)
	at com.android.server.power.PowerManagerService$BinderService.acquireWakeLock(PowerManagerService.java:4356)
	at com.android.server.pm.PackageDexOptimizer.acquireWakeLockLI(PackageDexOptimizer.java:361)
	at com.android.server.pm.BackgroundDexOptService.optimizePackages(BackgroundDexOptService.java:361)
```

* **ที่มาทางเทคนิค:** บน Android 9 (Pie) ตัว `BackgroundDexOptService` พยายามถือ WakeLock พร้อมระบุพารามิเตอร์ `WorkSource` (เพื่อบันทึกว่าแอปใดใช้แบตเตอรี่ไปเท่าใด) โดยระบบ `PowerManagerService` กำหนดว่าการถือ WakeLock ในลักษณะนี้ ผู้เรียกต้องถือสิทธิ์ `android.permission.UPDATE_DEVICE_STATS`
* **ข้อจำกัดของ ADB Shell:** คำสั่งผ่าน ADB จะรันในนาม **`user 2000` (Shell)** ซึ่งไม่มีสิทธิ์ดังกล่าว (สิทธิ์นี้สงวนไว้ให้ระบบหลัก `system / UID 1000` และ Root เท่านั้น) ทำให้คำสั่งถูกปฏิเสธทันที

#### ทางออกที่ถูกต้องและสำเร็จสมบูรณ์ (Speed-Profile Compilation):
การสั่งให้ Package Manager ทำการ Compile โดยตรงผ่าน dex2oat โดยเลี่ยงการเรียกผ่าน BackgroundDexOptService:
```bash
adb shell cmd package compile -m speed-profile -a
```

#### 📊 ผลการทดสอบคำสั่งนี้บนเครื่อง Redmi 7A จริง:
* ทำการคอมไพล์และ Optimize **ครบทั้ง 263 แพ็กเกจในเครื่อง (1/263 ถึง 263/263)**
* **ใช้เวลาทำงานเพียง ~40 วินาที**
* ปิดท้ายด้วยสถานะ **`Success`** สมบูรณ์ ช่วยให้ทุกแอปในเครื่องเปิดได้เร็วขึ้นอย่างมากโดยไม่ติด Error ใดๆ

---

## 4. สิ่งที่ต้องเตรียมก่อนเริ่มใช้งาน

### 4.1 ติดตั้ง ADB บนคอมพิวเตอร์
* **macOS (Homebrew):**
  ```bash
  brew install android-platform-tools
  ```
* **Windows / Linux:** ดาวน์โหลดจาก [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools) แล้วแตกไฟล์ไว้ในเครื่อง

### 4.2 เปิดโหมด USB Debugging บน Redmi 7A
1. ไปที่ **Settings (การตั้งค่า)** > **About phone (เกี่ยวกับโทรศัพท์)**
2. แตะที่ **MIUI version** ติดต่อกัน 7 ครั้ง จนขึ้นข้อความ *"You are now a developer!"*
3. ย้อนกลับไปที่ **Settings** > **Additional settings (การตั้งค่าเพิ่มเติม)** > **Developer options (ตัวเลือกสำหรับนักพัฒนา)**
4. เลื่อนลงมาเปิดใช้งาน **USB debugging**
5. เสียบสาย USB เข้ากับคอมพิวเตอร์ ปลดล็อกหน้าจอมือถือ และกด **Allow / ยอมรับ** ที่หน้าต่างยืนยัน RSA Fingerprint

---

## 5. การเริ่มใช้งานสคริปต์ (Quick Start)

สคริปต์ [**`tune-redmi7a.sh`**](file:///Users/billy/git/Python-Utility/tune-redmi7a.sh) ออกแบบมาให้ทำงานแบบ Interactive บน macOS และ Linux:

1. เปิด Terminal ในโฟลเดอร์โปรเจกต์
2. ให้สิทธิ์รันสคริปต์ (ทำเพียงครั้งแรก):
   ```bash
   chmod +x tune-redmi7a.sh
   ```
3. สั่งรันสคริปต์:
   ```bash
   ./tune-redmi7a.sh
   ```
4. สคริปต์จะตรวจสอบ Serial และรุ่นเครื่อง (`Redmi 7A`) ก่อนเข้าสู่เมนูหลัก

---

## 6. รายละเอียดการทำงานของแต่ละเมนูในสคริปต์

### เมนู 1: 📱 ตรวจสอบสถานะเครื่อง & ทรัพยากรระบบ
* **หน้าที่:** รายงานข้อมูลระบบโดยละเอียด
* **ข้อมูลที่แสดง:**
  * CPU Platform (`msm8937`), Codename (`pine`), Security Patch, MIUI Version
  * หน่วยความจำ RAM 2GB (MemTotal, MemFree, **MemAvailable**, Swap/ZRAM)
  * พื้นที่จัดเก็บข้อมูลในพาร์ติชัน `/data` (ขนาดทั้งหมด, พื้นที่ใช้ไป, พื้นที่คงเหลือ)
  * สถานะแบตเตอรี่ (เปอร์เซ็นต์, อุณหภูมิ, แรงดันไฟฟ้า, สถานะสุขภาพ)
  * จำนวนแอปที่ถูก Freeze อยู่ในปัจจุบัน

---

### เมนู 2: ⚡ ปรับความเร็ว Animation Scale
* **หน้าที่:** ปรับลดเวลาแสดงกราฟิกเอฟเฟกต์เปิด-ปิดหน้าต่างและสลับแอป
* **ตัวเลือก:**
  * **0.5x (แนะนำ):** ลดระยะเวลาลงครึ่งหนึ่ง ทำให้ UI สลับแอปรวดเร็วขึ้นอย่างเห็นได้ชัด
  * **1.0x:** คืนค่ามาตรฐานโรงงานของ MIUI
  * **0.0x:** ปิดแอนิเมชันทั้งหมด (เร็วที่สุด ลดภาระ GPU ของ Adreno 505)
* บน Redmi 7A คำสั่งนี้ทำงานได้ทันทีผ่าน ADB โดยไม่ต้องใช้หน้าจอตั้งค่า

---

### เมนู 3: 🛡️ Freeze Bloatware & Telemetry
* **หน้าที่:** ปิดการทำงานของแอปขยะ โฆษณา และระบบเก็บสถิติที่แฝงมากับเครื่อง
* **คำสั่งที่ใช้:** `pm disable-user --user 0 <PACKAGE_NAME>`
* **ความปลอดภัย:**
  * ข้อมูลและไฟล์ระบบไม่สูญหาย สามารถ Unfreeze คืนค่าได้สมบูรณ์ 100%
  * ไม่กระทบต่อการโทรเข้า-ออก, SMS, Wi-Fi, กล้องถ่ายรูป, แอปธนาคาร หรือ Google Play Store
* **ตัวเลือกในการ Freeze:**
  * `1) Freeze ทุกกลุ่มที่แนะนำ (Safe All - ทั้ง 26 แพ็กเกจ)` *(แนะนำสูงสุด)*
  * `2) เฉพาะกลุ่ม Telemetry & Analytics (5 รายการ)`
  * `3) เฉพาะกลุ่ม MIUI System Ads & Lockscreen Carousel (6 รายการ)`
  * `4) เฉพาะกลุ่ม Xiaomi Framework & Background Services (4 รายการ)`
  * `5) เฉพาะกลุ่ม Facebook Pre-installed (3 รายการ)`
  * `6) เฉพาะกลุ่ม OEM Stores, Bloatware & Financial Extras (8 รายการ)`
  * `7) เลือก Freeze ทีละแพ็กเกจด้วยตนเอง`

---

### เมนู 4: 🔄 Unfreeze / Rollback คืนค่าแอป
* **หน้าที่:** กู้คืนแอปที่เคยสั่ง Freeze ให้กลับมาทำงานตามปกติ
* **คำสั่งที่ใช้:** `pm enable <PACKAGE_NAME>`
* **ตัวเลือกในการกู้คืน:**
  * **คืนค่าทั้งหมด:** สั่งเปิดทุกแพ็กเกจที่ปิดอยู่ในเครื่องให้กลับมาทำงานพร้อมกัน
  * **เลือกทีละตัว:** แสดงรายการเฉพาะแอปที่ปิดอยู่ปัจจุบัน พร้อมตัวเลขให้เลือกเปิดเฉพาะตัวที่ต้องการ
  * **พิมพ์ชื่อแพ็กเกจเอง:** สำหรับกรณีต้องการเปิดแอปเฉพาะเจาะจง

---

### เมนู 5: 🚀 ART Runtime Compilation (Speed-Profile)
* **หน้าที่:** สั่งให้ Android Runtime (ART) ทำการ Optimize โค้ดของแอปพลิเคชันล่วงหน้า (AOT / Profile-guided) เพื่อให้เปิดแอปได้เร็วขึ้น
* **ตัวเลือกบน Redmi 7A:**
  * **1) Speed-Profile Optimization (`cmd package compile -m speed-profile -a`):** *(แนะนำสูงสุด)* ทำการ Optimize ทั้ง 263 แพ็กเกจตามโปรไฟล์การใช้งานจริง รวดเร็ว ไม่กินพื้นที่จัดเก็บ และไม่ติด SecurityException
  * **2) Full Speed Compilation (`cmd package compile -m speed -a`):** บังคับ Optimize แอปทุกตัวด้วยโหมด speed แบบเต็มรูปแบบ (ใช้เวลา 5-15 นาที เครื่องจะร้อน แนะนำให้เสียบสายชาร์จ)
* **ระบบความปลอดภัยของสคริปต์:** สคริปต์ได้รับการปรับปรุงให้มีตัวดักจับ Error และ SecurityException โดยจะแจ้งเตือนทันทีหากการคอมไพล์ไม่สำเร็จ

---

### เมนู 6: 🛑 Force Stop แอปชั่วคราว
* **หน้าที่:** สั่งปิดแอปที่เปิดค้างอยู่ใน RAM ทันที เพื่อคืนหน่วยความจำชั่วคราว
* **แอปเป้าหมาย:** Facebook, AliExpress, WPS Office, YouTube และ Gmail

---

### เมนู 7: 📋 ดูรายการแอปที่ถูก Freeze อยู่ปัจจุบัน
* **หน้าที่:** เรียกดูรายชื่อแพ็กเกจทั้งหมดที่อยู่ในสถานะ `disabled` บนเครื่อง (ดึงข้อมูลสดจาก `pm list packages -d`)

---

### เมนู 8: 💾 บันทึก Snapshot ข้อมูลเครื่อง
* **หน้าที่:** บันทึกสำเนาข้อมูลการตั้งค่าและรายการแอปทั้งหมดของเครื่องเก็บไว้บนคอมพิวเตอร์
* **ตำแหน่งที่จัดเก็บ:** `~/.redmi7a_tuning/snapshot_YYYYMMDD_HHMMSS/`
* **ไฟล์ที่ถูกสร้าง:**
  * `android-getprop.txt` — ค่าระบบ Property ทั้งหมด
  * `android-meminfo.txt` — สถิติการใช้งาน RAM ปัจจุบัน
  * `android-storage.txt` — ขนาดพื้นที่จัดเก็บดิสก์
  * `android-all-packages.txt` — รายชื่อแพ็กเกจทั้งหมดพร้อมพาธ APK
  * `android-disabled-packages.txt` — รายชื่อแพ็กเกจที่ถูกปิดใช้งาน

---

## 7. ฐานข้อมูลแพ็กเกจที่ถูก Freeze (26 รายการ)

ตารางแสดงรายชื่อแพ็กเกจที่ผ่านการทดสอบบน Xiaomi Redmi 7A:

### หมวด 1: Telemetry, Analytics & Daemons (ส่งสถิติและดักพฤติกรรมผู้ใช้)
| Package Name | ชื่อแสดงในระบบ / บทบาท | เหตุผลที่ควรปิด |
|---|---|---|
| `com.xiaomi.joyose` | Joyose (Telemetry / Throttler) | ดักเก็บสถิติเกมและควบคุมการจำกัดประสิทธิภาพ CPU/GPU ทำให้เครื่องหน่วง |
| `com.miui.analytics` | MIUI Analytics | ตัวเก็บสถิติการใช้งานและการคลิกโฆษณาในระบบ MIUI |
| `com.miui.daemon` | MiuiDaemon | ดักเก็บข้อมูลระบบและฮาร์ดแวร์ส่งกลับเซิร์ฟเวอร์ Xiaomi ตลอดเวลา |
| `com.miui.bugreport` | MiuiBugReport | ตัวดักส่งรายงานข้อผิดพลาดและ Crash log |
| `com.google.android.feedback` | Google Feedback | ตัวส่ง Feedback ข้อผิดพลาดของ Google |

### หมวด 2: MIUI System Ads & Lockscreen Carousel (ระบบโฆษณาหลักและภาพหน้าจอล็อก)
| Package Name | ชื่อแสดงในระบบ / บทบาท | เหตุผลที่ควรปิด |
|---|---|---|
| `com.miui.msa.global` | MSA (MIUI System Ads) | เครื่องมือยิงโฆษณาแฝงหลักในระบบ MIUI (ในโฟลเดอร์, การตั้งค่า, ระบบ) |
| `com.miui.android.fashiongallery` | Fashion Gallery / Wallpaper Carousel | วอลเปเปอร์หน้าจอล็อกที่มีการโหลดแบนเนอร์โฆษณาและกินเน็ตเบื้องหลัง |
| `com.miui.hybrid` | Quick Apps / Hybrid Platform | เฟรมเวิร์กเปิดเว็บแอปทันใจที่ยิงแบนเนอร์โฆษณา |
| `com.miui.hybrid.accessory` | Hybrid Accessory | เซอร์วิสเสริมของ Quick Apps |
| `com.miui.cleanmaster` | CleanMaster | คลีนเนอร์ขยะที่พ่วงโมดูลโฆษณาของ Cheetah Mobile |
| `com.miui.yellowpage` | YellowPage | สมุดหน้าเหลืองพ่วงโฆษณาและบริการเสริม |

### หมวด 3: Core Framework Services & Xiaomi Background Push
| Package Name | ชื่อแสดงในระบบ / บทบาท | เหตุผลที่ควรปิด |
|---|---|---|
| `com.xiaomi.xmsf` | Xiaomi Service Framework (XMSF) | เซอร์วิสเฟรมเวิร์กเบื้องหลังของ Xiaomi กิน RAM ตลอดเวลา |
| `com.xiaomi.xmsfkeeper` | XMSFKeeper | ตัวเฝ้าพิทักษ์ไม่ให้ XMSF หยุดทำงาน |
| `com.miui.guardprovider` | GuardProvider | สแกนไวรัสเบื้องหลังของ Security App ที่ชอบต่อเน็ตและกินแบตเตอรี่ |
| `com.milink.service` | MiLink Service | บริการแชร์จอไร้สายและเชื่อมต่ออุปกรณ์ IoT ของเสียวหมี่ |

### หมวด 4: Facebook Pre-installed Trackers
| Package Name | ชื่อแสดงในระบบ / บทบาท | เหตุผลที่ควรปิด |
|---|---|---|
| `com.facebook.appmanager` | Facebook App Manager | ตัวเช็กและอัปเดตแอป Facebook เบื้องหลังโดยไม่ผ่าน Play Store |
| `com.facebook.services` | Facebook Services | เซอร์วิส Sync และดักเก็บ Telemetry ของ Facebook ตลอดเวลา |
| `com.facebook.system` | Facebook System Installer | สิทธิ์ตัวติดตั้งระดับระบบของ Facebook |

### หมวด 5: OEM Stores, Bloatware & Financial Extras
| Package Name | ชื่อแสดงในระบบ / บทบาท | เหตุผลที่ควรปิด |
|---|---|---|
| `com.xiaomi.mipicks` | GetApps (Mi Picks) | ร้านโหลดแอปของ Xiaomi ที่ชอบส่งการแจ้งเตือนชวนโหลดแอปขยะ |
| `com.mipay.wallet.id` | Mi Pay Indonesia | กระเป๋าเงินออนไลน์สำหรับอินโดนีเซีย ไม่ได้ใช้งาน |
| `com.mipay.wallet.in` | Mi Pay India | กระเป๋าเงินออนไลน์สำหรับอินเดีย ไม่ได้ใช้งาน |
| `com.micredit.in` | Mi Credit India | บริการสินเชื่อออนไลน์เสียวหมี่ ไม่ได้ใช้งาน |
| `com.mi.globalTrendNews` | Global Trend News | ฟีดข่าวแถมที่รันเบื้องหลัง |
| `com.xiaomi.glgm` | Mi Games | ศูนย์รวมเกมแถมของ Xiaomi |
| `com.mi.global.bbs` | Mi Community | แอปฟอรัมชุมชนเสียวหมี่ |
| `com.android.browser` | Mi Browser Global | เบราว์เซอร์แถมที่มีฟีดข่าวและโฆษณา (เครื่องมี Google Chrome อยู่แล้ว) |

---

## 8. ไดเรกทอรีบันทึกข้อมูลและประวัติการทำงาน

สคริปต์จะเก็บข้อมูลประวัติและการ Snapshot ไว้ที่โฮมไดเรกทอรีของผู้ใช้:

* **ตำแหน่งหลัก:** `~/.redmi7a_tuning/`
* **ไฟล์ประวัติ:** `~/.redmi7a_tuning/tuning-history.log`  
  บันทึกวันเวลาและรายการที่ถูกแก้ไข เช่น:
  ```text
  [2026-11-05 16:48:48] Freeze package: com.xiaomi.joyose
  [2026-11-05 16:48:48] Freeze package: com.miui.msa.global
  [2026-11-05 16:51:52] Set animation scale to 0.5x
  [2026-11-05 17:08:32] Executed cmd package compile -m speed-profile -a successfully
  ```
* **โฟลเดอร์ Snapshot:** `~/.redmi7a_tuning/snapshot_YYYYMMDD_HHMMSS/`

---

## 9. การแก้ไขปัญหาและคำถามที่พบบ่อย (FAQ)

### Q1: ปิด Xiaomi Service Framework (XMSF) แล้วการแจ้งเตือน LINE, Messenger, ธนาคาร จะหายไหม?
> **คำตอบ:** ไม่หายครับ เพราะแอปมาตรฐานส่วนใหญ่บน Google Play Store (เช่น LINE, Facebook, Messenger, แอปธนาคาร) ใช้ระบบแจ้งเตือนผ่าน **Google Play Services (Google FCM)** ไม่ได้พึ่งพา XMSF ของ Xiaomi

### Q2: ปิด GuardProvider แล้วเครื่องจะติดไวรัสหรือไม่?
> **คำตอบ:** ไม่ครับ GuardProvider เป็นเพียงโมดูลสแกนของ CleanMaster/AVL ที่ทำงานเบื้องหลัง ตัวระบบ Android ยังคงได้รับการปกป้องจาก **Google Play Protect** ตามมาตรฐานความปลอดภัย

### Q3: ปิด Fashion Gallery แล้วอยากได้ภาพสไลด์หน้าจอล็อกกลับมา ต้องทำอย่างไร?
> **คำตอบ:** เข้า **เมนู 4 (Unfreeze)** แล้วเลือกเปิดคืนแพ็กเกจ:
> ```bash
> adb shell pm enable com.miui.android.fashiongallery
> ```

### Q4: สามารถ Factory Reset เครื่องได้ไหมหลังจากรันสคริปต์นี้?
> **คำตอบ:** ได้ตามปกติ การ Factory Reset จะทำการกู้คืนทุกแพ็กเกจกลับสู่ค่าเริ่มต้นจากโรงงาน

---

## 10. ตารางคำสั่ง ADB ฉบับย่อ (Quick Reference)

| สิ่งที่ต้องการทำ | คำสั่ง ADB |
|---|---|
| ตรวจสอบการเชื่อมต่อ | `adb devices` |
| ดูรุ่นและเวอร์ชัน Android | `adb shell getprop ro.product.model` |
| ดู RAM คงเหลือปัจจุบัน | `adb shell cat /proc/meminfo \| grep MemAvailable` |
| ดูรายการแอปที่ถูก Freeze อยู่ | `adb shell pm list packages -d` |
| สั่ง Freeze แอปเดี่ยว | `adb shell pm disable-user --user 0 <PACKAGE_NAME>` |
| สั่งเปิดคืนแอปเดี่ยว | `adb shell pm enable <PACKAGE_NAME>` |
| บังคับปิดแอปออกจาก RAM | `adb shell am force-stop <PACKAGE_NAME>` |
| สั่ง Optimize แอปทั้งหมดตาม Profile | `adb shell cmd package compile -m speed-profile -a` |
| บังคับ Compile ทุกแอปแบบ Speed | `adb shell cmd package compile -m speed -a` |
| ปรับความเร็ว Animation เป็น 0.5x | `adb shell settings put global window_animation_scale 0.5` |

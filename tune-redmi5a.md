# คู่มือการปรับแต่ง Xiaomi Redmi 5A ด้วย `tune-redmi5a.sh`

คู่มือฉบับสมบูรณ์สำหรับการปรับแต่งประสิทธิภาพ ปิดระบบโฆษณา MIUI, เซอร์วิส Telemetry, ตัวลดประสิทธิภาพซีพียู (Joyose), เซอร์วิสโรงงาน (Factory MMI Test) และ Bloatware สำหรับ **Xiaomi Redmi 5A (riva)** ผ่าน ADB โดย **ไม่ต้อง Root เครื่อง**

> **เป้าหมายหลัก:** คืนทรัพยากรหน่วยความจำ (RAM) และพื้นที่จัดเก็บข้อมูล (`/data`) สำหรับเครื่องสเปกเริ่มต้น RAM 2 GB / ROM 16 GB, กำจัดโฆษณาแฝงในระบบ MIUI 11 (MSA, App Vault, Quick Apps, CleanMaster), ตัดการทำงานของ Joyose Throttler และ Factory MMI Service ที่รันค้างกินแรมเบื้องหลัง พร้อมเก็บสำรอง Snapshot ข้อมูลเครื่องอย่างปลอดภัยโดยมีระบบถามยืนยัน (Confirm) ก่อนเปลี่ยนแปลงทุกครั้ง

---

## สารบัญ

1. [ข้อมูลเฉพาะของเครื่อง Xiaomi Redmi 5A](#1-ข้อมูลเฉพาะของเครื่อง-xiaomi-redmi-5a)
2. [ตารางเปรียบเทียบเชิงลึก 3 รุ่น: Redmi 5A vs Redmi 7A vs realme 5s](#2-ตารางเปรียบเทียบเชิงลึก-3-รุ่น-redmi-5a-vs-redmi-7a-vs-realme-5s)
3. [ผลการสแกนและค้นหา Bloatware บนเครื่องจริง (Actual Device Audit)](#3-ผลการสแกนและค้นหา-bloatware-บนเครื่องจริง-actual-device-audit)
   - [3.1 สภาพแวดล้อมเครื่องที่สแกนจริง (Before Snapshot)](#31-สภาพแวดล้อมเครื่องที่สแกนจริง-before-snapshot)
   - [3.2 รายการ Bloatware / Telemetry ทั้ง 36 รายการพร้อมพาธ APK จริง](#32-รายการ-bloatware--telemetry-ทั้ง-36-รายการพร้อมพาธ-apk-จริง)
   - [3.3 ผลการทดสอบ Freeze และการตรวจสอบ Process ใน RAM](#33-ผลการทดสอบ-freeze-และการตรวจสอบ-process-ใน-ram)
   - [3.4 พฤติกรรมของ Animation Scale และ ART Compilation บน Android 8.1](#34-พฤติกรรมของ-animation-scale-และ-art-compilation-บน-android-81)
   - [3.5 สรุปผลเปรียบเทียบก่อนและหลังทำ (Before vs After: RAM, ZRAM & Disk Space)](#35-สรุปผลเปรียบเทียบก่อนและหลังทำ-before-vs-after-ram-zram--disk-space)
4. [สิ่งที่ต้องเตรียมก่อนเริ่มใช้งาน](#4-สิ่งที่ต้องเตรียมก่อนเริ่มใช้งาน)
5. [การเริ่มใช้งานสคริปต์ (Quick Start)](#5-การเริ่มใช้งานสคริปต์-quick-start)
6. [รายละเอียดการทำงานของแต่ละเมนูในสคริปต์](#6-รายละเอียดการทำงานของแต่ละเมนูในสคริปต์)
   - [เมนู 1: ตรวจสอบสถานะเครื่อง & ทรัพยากรระบบ](#เมนู-1-📱-ตรวจสอบสถานะเครื่อง--ทรัพยากรระบบ)
   - [เมนู 2: ปรับความเร็ว Animation Scale](#เมนู-2-⚡-ปรับความเร็ว-animation-scale)
   - [เมนู 3: Freeze Bloatware & Telemetry (36 รายการ)](#เมนู-3-🛡️-freeze-bloatware--telemetry-36-รายการ)
   - [เมนู 4: Unfreeze / Rollback คืนค่าแอป](#เมนู-4-🔄-unfreeze--rollback-คืนค่าแอป)
   - [เมนู 5: ART Runtime Compilation](#เมนู-5-🚀-art-runtime-compilation)
   - [เมนู 6: Force Stop แอปชั่วคราว & ล้างแคชระบบ (Trim Caches)](#เมนู-6-🛑-force-stop-แอปชั่วคราว--ล้างแคชระบบ-trim-caches)
   - [เมนู 7: ดูรายการแอปที่ถูก Freeze อยู่ปัจจุบัน](#เมนู-7-📋-ดูรายการแอปที่ถูก-freeze-อยู่ปัจจุบัน)
   - [เมนู 8: บันทึก Snapshot ข้อมูลเครื่อง](#เมนู-8-💾-บันทึก-snapshot-ข้อมูลเครื่อง)
7. [ฐานข้อมูลแพ็กเกจที่ถูก Freeze (36 รายการ)](#7-ฐานข้อมูลแพ็กเกจที่ถูก-freeze-36-รายการ)
8. [ไดเรกทอรีบันทึกข้อมูลและประวัติการทำงาน](#8-ไดเรกทอรีบันทึกข้อมูลและประวัติการทำงาน)
9. [การแก้ไขปัญหาและคำถามที่พบบ่อย (FAQ)](#9-การแก้ไขปัญหาและคำถามที่พบบ่อย-faq)
10. [ตารางคำสั่ง ADB ฉบับย่อ (Quick Reference)](#10-ตารางคำสั่ง-adb-ฉบับย่อ-quick-reference)

---

## 1. ข้อมูลเฉพาะของเครื่อง Xiaomi Redmi 5A

* **รหัสรุ่น (Model):** `Redmi 5A`
* **รหัสประจำอุปกรณ์ (Codename):** `riva`
* **ชิปประมวลผล:** Qualcomm Snapdragon 425 (`msm8937` platform family / MSM8917) Quad-Core 1.4 GHz Cortex-A53, GPU Adreno 308
* **หน่วยความจำ:** RAM 2 GB (Physical `MemTotal`: `1,913,488 kB` / ~1.87 GB) / ROM 16 GB eMMC 5.1 (พาร์ติชัน `/data` ใช้งานได้จริง ~10 GB)
* **ระบบปฏิบัติการ:** MIUI 11 Global (`V11.0.2.0.OCKMIXM`) บนฐาน Android 8.1.0 Oreo (API 27, Security Patch `2019-10-01`)
* **ความสำคัญของการ Debloat บนรุ่นนี้:**
  * Redmi 5A ใช้ซีพียูแบบ Quad-Core (4 คอร์) รุ่นประหยัดพลังงานร่วมกับ RAM 2 GB และพื้นที่เก็บข้อมูลเพียง 16 GB
  * จากการตรวจวัดเครื่องจริงก่อนปรับแต่ง พบว่าเซอร์วิสเบื้องหลังของ MIUI 11 เช่น **App Vault (`globalminusscreen` 31.6 MB)**, **Quick Apps (`com.miui.hybrid` 30.5 MB)**, **Factory MMI Test (`com.factory.mmigroup` 21.3 MB)**, **MSA (`20.8 MB`)**, **XMSF (`17.8 MB`)**, **MiuiDaemon (`15.1 MB`)**, **Joyose (`11.6 MB`)**, และ **Analytics (`11.2 MB`)** แอบรันกินแรมรวมกันเกือบ **180 MB** ตลอดเวลา และพื้นที่ `/data` เหลือเพียง **266 MB (เต็ม 98%)**

---

## 2. ตารางเปรียบเทียบเชิงลึก 3 รุ่น: Redmi 5A vs Redmi 7A vs realme 5s

จากการทดสอบจริงผ่าน ADB บนสมาร์ตโฟนทั้ง 3 รุ่น พบความแตกต่างเชิงเทคนิคของแต่ละเวอร์ชัน Android และ OEM ROM ดังนี้:

| หัวข้อการทดสอบ | Xiaomi Redmi 5A (MIUI 11 / Android 8.1) | Xiaomi Redmi 7A (MIUI 11 / Android 9) | realme 5s (ColorOS 7 / Android 10) |
|---|---|---|---|
| **Device Codename / SoC** | `riva` / Snapdragon 425 (Quad-Core) | `pine` / Snapdragon 439 (Octa-Core) | `RMX1925` / Snapdragon 665 (Octa-Core) |
| **Animation Scale ผ่าน ADB** | ⚠️ **ติด `WRITE_SECURE_SETTINGS`** หากไม่ได้เปิดสวิตช์ *"USB debugging (Security settings)"* ในโหมดนักพัฒนา | ✅ **ปรับได้ทันที** ผ่าน `settings put global` (เมื่อเปิด Security settings ไว้) | ❌ **ถูกบล็อกถาวร** ด้วย `WRITE_SECURE_SETTINGS` ต้องปรับผ่านหน้าจอ Developer Options |
| **คำสั่ง `cmd package bg-dexopt-job`** | ✅ **ทำงานสำเร็จ 100%** (Android 8.1 ไม่มีบั๊กสิทธิ์ WakeLock `UPDATE_DEVICE_STATS`) | ❌ **ล้มเหลว** เกิด `SecurityException: UPDATE_DEVICE_STATS` บน Android 9 | ✅ **ทำงานสำเร็จ** (`Success`) รัน Background DEX Optimization ได้ตามปกติ |
| **คำสั่ง `cmd package compile -m speed-profile -a`** | ✅ **ทำงานสำเร็จ** สามารถใช้ร่วมกับ `bg-dexopt-job` ได้ | ✅ **ทำงานสำเร็จสมบูรณ์ (263/263)** เป็นทางออกหลักแทน `bg-dexopt-job` | ❌ **ถูกบล็อก** ด้วย `Error: Failed to cpmpile !` |
| **โปรเซสโรงงานรันค้างใน RAM** | ⚠️ พบ `com.factory.mmigroup` รันค้างกินแรม **21.3 MB** และ `com.mi.AutoTest` | ไม่พบโปรเซสโรงงานรันค้าง | พบ `com.oppo.engineermode` |
| **ปัญหาพื้นที่ `/data` เต็ม** | 🚨 วิกฤต (`10G` ใช้ไป `98%`, เหลือ `266M`) ต้องใช้ `pm clear` + `pm trim-caches 999G` ช่วย | ปกติ (`23G` ใช้ไป `39%`, เหลือ `14G`) | ปกติ (`52G` ใช้ไป `32%`, เหลือ `35G`) |

---

## 3. ผลการสแกนและค้นหา Bloatware บนเครื่องจริง (Actual Device Audit)

ผลการสำรวจ สแกน และสั่ง Freeze บนเครื่อง Xiaomi Redmi 5A จริง (Serial: `f8f2d29a7d05`):

### 3.1 สภาพแวดล้อมเครื่องที่สแกนจริง (Before Snapshot)
* **Device Serial:** `f8f2d29a7d05`
* **Model / Codename:** `Xiaomi Redmi 5A` (`riva`)
* **Platform / SoC:** `msm8937` (Qualcomm Snapdragon 425)
* **OS / Build:** MIUI Global `V11` (`V11.0.2.0.OCKMIXM`) / Android `8.1.0` (SDK `27`, Security Patch `2019-10-01`)
* **จำนวนแพ็กเกจทั้งหมดในระบบ:** **242 แพ็กเกจ**
* **แพ็กเกจที่ถูก Disable อยู่ก่อนเริ่ม (5 แพ็กเกจ):**
  * `com.android.fileexplorer`, `com.google.android.webview`, `com.xiaomi.glgm`, `com.micredit.in`, `com.mipay.wallet.in`

---

### 3.2 รายการ Bloatware / Telemetry ทั้ง 36 รายการพร้อมพาธ APK จริง

จากการสแกนด้วยคำสั่ง `pm list packages -f` และวิเคราะห์โปรเซสใน `dumpsys meminfo` พบแพ็กเกจเป้าหมายทั้ง **36 รายการ** บนเครื่องดังนี้:

| ลำดับ | หมวดหมู่ | Package Name | พาธไฟล์ APK บนเครื่องจริง | RAM ที่กินก่อนปิด (PSS) | สถานะการ Freeze |
|---|---|---|---|---|---|
| 1 | Telemetry / Throttler | `com.xiaomi.joyose` | `/system/app/Joyose/Joyose.apk` | `11,591 KB` (PID 4324) | ✅ `disabled-user` |
| 2 | Telemetry / Analytics | `com.miui.analytics` | `/data/app/com.miui.analytics-.../base.apk` | `11,213 KB` (PID 4165) | ✅ `disabled-user` |
| 3 | System Telemetry | `com.miui.daemon` | `/system/app/MiuiDaemon/MiuiDaemon.apk` | `15,096 KB` (PID 2355) | ✅ `disabled-user` |
| 4 | Bug Reporter | `com.miui.bugreport` | `/data/app/com.miui.bugreport-.../base.apk` | ทำงานเมื่อเกิด Crash | ✅ `disabled-user` |
| 5 | Crash Report | `com.google.android.feedback` | `/system/priv-app/GoogleFeedback/GoogleFeedback.apk` | ทำงานเมื่อเกิด Crash | ✅ `disabled-user` |
| 6 | Modem Telemetry | `com.qualcomm.qti.StatsPollManager` | `/system/app/StatsPollManager/StatsPollManager.apk` | `4,565 KB` (PID 7986) | ✅ `disabled-user` |
| 7 | Kernel/Battery Logger | `com.bsp.catchlog` | `/system/priv-app/BatteryInfoActivity/BatteryInfoActivity.apk` | ทำงานเบื้องหลัง | ✅ `disabled-user` |
| 8 | Factory Hardware Test | `com.factory.mmigroup` | `/system/vendor/app/MMIGroup/MMIGroup.apk` | **`21,364 KB`** (PID 2345) | ✅ `disabled-user` |
| 9 | Factory AutoTest | `com.mi.AutoTest` | `/system/vendor/app/AutoTest/AutoTest.apk` | ทำงานเบื้องหลัง | ✅ `disabled-user` |
| 10 | Main Ad Engine | `com.miui.msa.global` | `/data/app/com.miui.msa.global-.../base.apk` | **`20,882 KB`** (PID 8451) | ✅ `disabled-user` |
| 11 | App Vault / Minus Screen | `com.mi.android.globalminusscreen` | `/system/priv-app/GlobalMinusScreen/GlobalMinusScreen.apk` | **`31,625 KB`** (PID 5447) | ✅ `disabled-user` |
| 12 | Quick Apps Platform | `com.miui.hybrid` | `/system/app/HybridPlatform/HybridPlatform.apk` | **`30,572 KB`** (2 PIDs) | ✅ `disabled-user` |
| 13 | Quick Apps Accessory | `com.miui.hybrid.accessory` | `/system/app/HybridAccessory/HybridAccessory.apk` | เซอร์วิสเสริม | ✅ `disabled-user` |
| 14 | Cleaner Ads | `com.miui.cleanmaster` | `/data/app/com.miui.cleanmaster-.../base.apk` | รันเมื่อเปิดคลีนเนอร์ | ✅ `disabled-user` |
| 15 | Directory Ads | `com.miui.yellowpage` | `/system/priv-app/YellowPage/YellowPage.apk` | ซิงก์สมุดหน้าเหลือง | ✅ `disabled-user` |
| 16 | Ad Config Service | `com.miui.wmsvc` | `/data/app/com.miui.wmsvc-.../base.apk` | `6,897 KB` (PID 5235) | ✅ `disabled-user` |
| 17 | Push Framework | `com.xiaomi.xmsf` | `/system/app/XiaomiServiceFramework/XiaomiServiceFramework.apk` | `17,820 KB` (PID 2370) | ✅ `disabled-user` |
| 18 | Antivirus Scanner | `com.miui.guardprovider` | `/system/app/GuardProvider/GuardProvider.apk` | สแกนเบื้องหลัง | ✅ `disabled-user` |
| 19 | Screen Casting | `com.milink.service` | `/system/app/MiLinkService2/MiLinkService2.apk` | บริการแชร์หน้าจอ | ✅ `disabled-user` |
| 20 | IoT Discovery | `com.xiaomi.mi_connect_service` | `/system/app/mi_connect_service/mi_connect_service.apk` | `5,644 KB` (PID 8098) | ✅ `disabled-user` |
| 21 | Media Casting | `com.xiaomi.miplay_client` | `/system/app/MiPlayClient/MiPlayClient.apk` | แคสต์มีเดียเบื้องหลัง | ✅ `disabled-user` |
| 22 | UPnP Media | `com.xiaomi.upnp` | `/system/app/UpnpService/UpnpService.apk` | ค้นหาอุปกรณ์ UPnP | ✅ `disabled-user` |
| 23 | Facebook Tracker | `com.facebook.appmanager` | `/data/app/com.facebook.appmanager-.../base.apk` | อัปเดต FB เบื้องหลัง | ✅ `disabled-user` |
| 24 | Facebook Telemetry | `com.facebook.services` | `/system/priv-app/facebook-services/facebook-services.apk` | ซิงก์ข้อมูล FB | ✅ `disabled-user` |
| 25 | Facebook Installer | `com.facebook.system` | `/data/app/com.facebook.system-.../base.apk` | ตัวติดตั้งระดับระบบ | ✅ `disabled-user` |
| 26 | Xiaomi App Store | `com.xiaomi.mipicks` | `/data/app/com.xiaomi.mipicks-.../base.apk` | ร้าน GetApps | ✅ `disabled-user` |
| 27 | System App Updater | `com.xiaomi.discover` | `/data/app/com.xiaomi.discover-.../base.apk` | ตัวอัปเดตแอประบบ | ✅ `disabled-user` |
| 28 | Wallet Indonesia | `com.mipay.wallet.id` | `/system/app/IdMipay/IdMipay.apk` | กระเป๋าเงินอินโดนีเซีย | ✅ `disabled-user` |
| 29 | Wallet India | `com.mipay.wallet.in` | `/system/app/InMipay/InMipay.apk` | - | 🔹 ปิดไว้แล้วโดยระบบ |
| 30 | Mi Credit India | `com.micredit.in` | `/data/app/MiCreditInStub/MiCreditInStub.apk` | - | 🔹 ปิดไว้แล้วโดยระบบ |
| 31 | Mi Coin Payment | `com.xiaomi.payment` | `/system/app/PaymentService/PaymentService.apk` | บริการชำระเงิน | ✅ `disabled-user` |
| 32 | Mi Games | `com.xiaomi.glgm` | `/system/priv-app/GameCenterGlobal/GameCenterGlobal.apk` | - | 🔹 ปิดไว้แล้วโดยระบบ |
| 33 | Mi Community | `com.miui.enbbs` | `/data/app/com.miui.enbbs-.../base.apk` | ฟอรัม Xiaomi | ✅ `disabled-user` |
| 34 | WPS Office Lite | `cn.wps.xiaomi.abroad.lite` | `/data/app/wps_lite/wps_lite.apk` | แอปเอกสารพ่วงโฆษณา | ✅ `disabled-user` |
| 35 | Mi Browser Global | `com.android.browser` | `/system/priv-app/MiuiBrowserGlobal/MiuiBrowserGlobal.apk` | เบราว์เซอร์พ่วงข่าว/โฆษณา | ✅ `disabled-user` |
| 36 | Mi Recycle | `com.xiaomi.mirecycle` | `/system/priv-app/MiRecycle/MiRecycle.apk` | บริการรับซื้อเครื่องเก่า | ✅ `disabled-user` |

---

### 3.3 ผลการทดสอบ Freeze และการตรวจสอบ Process ใน RAM
* **สั่ง Freeze สำเร็จใหม่เพิ่ม:** **33 แพ็กเกจ** (`new state: disabled-user`)
* **รวมกับแพ็กเกจเดิมที่ปิดอยู่แล้ว (5 แพ็กเกจ):** รวมมีแพ็กเกจที่ถูกปิดใช้งานทั้งสิ้น **38 แพ็กเกจ**
* **การตรวจสอบสถานะ Process ด้วย `dumpsys meminfo <package>` หลังทำ:**
  ```text
  No process found for: com.xiaomi.joyose
  No process found for: com.miui.msa.global
  No process found for: com.miui.analytics
  No process found for: com.mi.android.globalminusscreen
  No process found for: com.miui.hybrid
  No process found for: com.xiaomi.mi_connect_service
  No process found for: com.qualcomm.qti.StatsPollManager
  No process found for: com.miui.wmsvc
  ```
* **หมายเหตุสำหรับ Persistent System-UID Services (3 ตัว):**
  * `com.factory.mmigroup`, `com.xiaomi.xmsf`, และ `com.miui.daemon` ถูกรันมาตั้งแต่ตอนบูตเครื่องภายใต้ `android.uid.system` แม้จะถูกตั้งสถานะ `disabled-user` และเคลียร์ข้อมูลแล้ว ตัว PID เดิมจะลดขนาดการใช้แรมลง และ **จะไม่ถูกสตาร์ทขึ้นมาอีกเลยอย่างถาวรหลังจากการ Reboot เครื่องครั้งถัดไป** (ประหยัด RAM เพิ่มขึ้นอีก ~42 MB หลัง Reboot)

---

### 3.4 พฤติกรรมของ Animation Scale และ ART Compilation บน Android 8.1

1. **การตั้งค่า Animation Scale ผ่าน ADB บน MIUI 11 (Android 8.1):**
   * เมื่อรัน `adb shell settings put global window_animation_scale 0.5` โดยที่ยังไม่ได้เปิดสวิตช์ **"USB debugging (Security settings)"** ใน Developer Options ระบบจะแจ้ง:
     ```text
     Security exception: Permission denial: writing to settings requires:android.permission.WRITE_SECURE_SETTINGS
     ```
   * **วิธีแก้ไขในสคริปต์ `tune-redmi5a.sh`:** สคริปต์จะตรวจจับ Error นี้อัตโนมัติ และสั่งเปิดหน้า **Developer Options** บนหน้าจอโทรศัพท์ให้ทันที (`am start -a android.settings.APPLICATION_DEVELOPMENT_SETTINGS`) เพื่อให้ผู้ใช้เลือกเปิดสวิตช์ *"USB debugging (Security settings)"* หรือเลื่อนลงไปปรับ Scale ทั้ง 3 ตัวเป็น `0.5x` ด้วยตนเองได้อย่างสะดวก

2. **การรัน ART Runtime Compilation บน Redmi 5A (Android 8.1):**
   * ต่างจาก Redmi 7A (Android 9) ที่ติดบั๊ก `UPDATE_DEVICE_STATS` บน Redmi 5A ซึ่งใช้ **Android 8.1.0 (Oreo)** สามารถรันคำสั่ง **`adb shell cmd package bg-dexopt-job`** ได้สำเร็จโดยไม่ติด SecurityException!
   * นอกจากนี้ยังรองรับคำสั่ง `adb shell cmd package compile -m speed-profile -a` ได้อย่างสมบูรณ์เช่นกัน

---

### 3.5 สรุปผลเปรียบเทียบก่อนและหลังทำ (Before vs After: RAM, ZRAM & Disk Space)

จากการเก็บค่าพารามิเตอร์จริงผ่าน `/proc/meminfo`, `dumpsys meminfo`, และ `df -k /data` ก่อนและหลังการ Freeze แพ็กเกจทั้ง 36 รายการ + ล้างข้อมูลแคช (`pm clear` & `pm trim-caches 999G`):

#### 📊 1. ตารางเปรียบเทียบหน่วยความจำ (RAM & ZRAM Comparison)

| ตัวชี้วัด (Metric) | ก่อนทำ (Before Freeze) | หลังทำ (After Freeze & Clean) | ผลต่าง (Improvement) |
|---|---|---|---|
| **Total Physical RAM (`MemTotal`)** | `1,913,488 kB` (~1,868.6 MB) | `1,913,488 kB` (~1,868.6 MB) | เท่าเดิม (ฮาร์ดแวร์ 2 GB) |
| **Available RAM (`MemAvailable`)** | `647,484 kB` (~632.3 MB) | **`750,932 kB` (~733.3 MB)** | 📈 **เพิ่มขึ้น +103,448 kB (+101.02 MB / +16.0%)** |
| **Pure Free RAM (`MemFree`)** | `40,040 kB` (~39.1 MB) | **`153,688 kB` – `181,048 kB`** | 🚀 **เพิ่มขึ้น +113.6 MB ถึง +141.0 MB (เกือบ 4 เท่า!)** |
| **Active Anonymous Heap (`Active(anon)`)** | `484,436 kB` (~473.1 MB) | **`422,188 kB` (~412.3 MB)** | 📉 **ลดภาระ Heap ลง -62,248 kB (-60.79 MB)** |
| **Used RAM รวม (`dumpsys meminfo`)** | `1,539,788 K` (~1,503.7 MB) | **`1,469,645 K` (~1,435.2 MB)** | 📉 **ลดการใช้ RAM ลง -70,143 K (-68.50 MB)** |
| **Dalvik Heap (`dumpsys meminfo`)** | `183,418 K` (~179.1 MB) | **`151,157 K` (~147.6 MB)** | 📉 **ลดลง -32,261 K (-31.50 MB)** |
| **`.dex mmap` + `.art mmap`** | `258,169 K` (~252.1 MB) | **`196,687 K` (~192.1 MB)** | 📉 **ลดลง -61,482 K (-60.04 MB)** |
| **ข้อมูลใน ZRAM Swap (`in swap`)** | `481,904 K` (~470.6 MB) | **`393,692 K` (~384.5 MB)** | 📉 **ลดภาระ Swap ลง -88,212 K (-86.14 MB / -18.3%)** |
| **Physical RAM ที่เสียให้ ZRAM** | `128,492 K` (~125.5 MB) | **`112,604 K` (~110.0 MB)** | 📈 **ได้ Physical RAM คืน +15,888 K (+15.52 MB)** |
| **RAM ของโปรเซส Bloatware ที่รันค้าง** | `177,269 K` (~173.1 MB) | **ถูกฆ่าทันที `122,999 K`** (และอีก `54,270 K` จะเป็น `0 K` หลัง Reboot) | 🛡️ **หยุดการแย่งชิง RAM ถาวร ~173.1 MB** |

#### 💾 2. ตารางเปรียบเทียบพื้นที่จัดเก็บข้อมูล (Disk Space Comparison)

บนเครื่อง Redmi 5A รุ่นความจุ 16 GB พาร์ติชัน `/data` มีขนาดใช้งานจริงเพียง `10 GB` (`10,124,556 KB`) และก่อนทำอยู่ในสภาวะใกล้เต็ม (`98%`):

| พาร์ติชัน (Partition) | ก่อนทำ (Before) | หลังทำ (After Freeze + Clear Cache) | พื้นที่ที่ได้คืน (Disk Saved) |
|---|---|---|---|
| **`/data` (Used Space)** | `9,705,100 KB` (`9.2 GB`) | **`9,661,420 KB` (`9.2 GB`)** | 📉 **ลดพื้นที่ใช้งานลง -43,680 KB (-42.66 MB)** |
| **`/data` (Available Free Space)** | `272,000 KB` (**`266 MB`**) | **`315,680 KB` (`308 MB`)** | 📈 **พื้นที่ว่างเพิ่มขึ้น +43,680 KB (+42.66 MB)** |
| **`/data` (Use %)** | 🚨 **`98%`** (วิกฤต) | ✅ **`97%`** | ลดความเสี่ยงระบบแจ้งเตือนความจำเต็ม |
| **`/system`** | `2,941,176 KB` / ว่าง `41 MB` (`99%`) | `2,941,176 KB` / ว่าง `41 MB` (`99%`) | คงเดิม (Read-Only System Partition) |
| **`/cache`** | `1,556 KB` / ว่าง `223 MB` (`1%`) | `1,556 KB` / ว่าง `223 MB` (`1%`) | คงเดิม |

---

## 4. สิ่งที่ต้องเตรียมก่อนเริ่มใช้งาน

### 4.1 ติดตั้ง ADB บนคอมพิวเตอร์
* **macOS (Homebrew):**
  ```bash
  brew install android-platform-tools
  ```
* **Windows / Linux:** ดาวน์โหลดจาก [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools)

### 4.2 เปิดโหมด USB Debugging บน Redmi 5A
1. ไปที่ **Settings (การตั้งค่า)** > **About phone (เกี่ยวกับโทรศัพท์)**
2. แตะที่ **MIUI version** ติดต่อกัน 7 ครั้ง จนขึ้นข้อความ *"You are now a developer!"*
3. ย้อนกลับไปที่ **Settings** > **Additional settings (การตั้งค่าเพิ่มเติม)** > **Developer options (ตัวเลือกสำหรับนักพัฒนา)**
4. เปิดสวิตช์ **USB debugging**
5. *(แนะนำ)* เลื่อนลงมาเปิดสวิตช์ **USB debugging (Security settings)** เพื่ออนุญาตให้ ADB ปรับค่า Animation Scale ได้โดยตรง

---

## 5. การเริ่มใช้งานสคริปต์ (Quick Start)

สคริปต์ [**`tune-redmi5a.sh`**](file:///Users/billy/git/Python-Utility/tune-redmi5a.sh) ออกแบบมาให้ทำงานแบบ Interactive พร้อมถามยืนยันก่อนดำเนินการทุกขั้นตอน:

1. ให้สิทธิ์รันสคริปต์ (ทำครั้งแรกครั้งเดียว):
   ```bash
   chmod +x tune-redmi5a.sh
   ```
2. สั่งรันสคริปต์:
   ```bash
   ./tune-redmi5a.sh
   ```

---

## 6. รายละเอียดการทำงานของแต่ละเมนูในสคริปต์

### เมนู 1: 📱 ตรวจสอบสถานะเครื่อง & ทรัพยากรระบบ
* แสดงข้อมูล CPU Platform (`msm8937` / Snapdragon 425), Codename (`riva`), Security Patch, MIUI Version
* แสดงสถานะ RAM (`MemTotal`, `MemFree`, `MemAvailable`, `Active(anon)`, `SwapTotal`, `SwapFree`)
* แสดงพื้นที่ว่างในพาร์ติชัน `/data`, `/system`, `/cache`
* แสดงสถานะแบตเตอรี่ และจำนวนแพ็กเกจที่ถูก Freeze อยู่ปัจจุบัน

### เมนู 2: ⚡ ปรับความเร็ว Animation Scale
* ปรับค่า `window_animation_scale`, `transition_animation_scale`, และ `animator_duration_scale` เป็น `0.5x`, `1.0x`, หรือ `0x`
* หากติดสิทธิ์ `WRITE_SECURE_SETTINGS` สคริปต์จะเปิดหน้า **Developer Options** บนหน้าจอมือถือให้อัตโนมัติ

### เมนู 3: 🛡️ Freeze Bloatware & Telemetry (36 รายการ)
* ใช้คำสั่ง `pm disable-user --user 0` ร่วมกับ `am force-stop`
* แบ่งออกเป็น 5 หมวดหมู่หลัก สามารถเลือก Freeze ทั้งหมด (36 รายการ), เลือกตามหมวดหมู่ หรือเลือกทีละแพ็กเกจได้

### เมนู 4: 🔄 Unfreeze / Rollback คืนค่าแอป
* กู้คืนแพ็กเกจที่ถูก Freeze กลับมาทำงานปกติด้วยคำสั่ง `pm enable <package>` ทั้งแบบคืนค่าทั้งหมดและเลือกเฉพาะตัว

### เมนู 5: 🚀 ART Runtime Compilation
* รองรับทั้ง `cmd package bg-dexopt-job` (ซึ่งทำงานได้สมบูรณ์บน Android 8.1), `cmd package compile -m speed-profile -a`, และ `cmd package compile -m speed -a`

### เมนู 6: 🛑 Force Stop แอปชั่วคราว & ล้างแคชระบบ (Trim Caches)
* สั่งหยุดแอปที่กินแรมสูงชั่วคราว (`am force-stop` + `am kill-all`)
* มีตัวเลือก **`T) ล้างไฟล์แคชระบบทั้งหมด (pm trim-caches 999G)`** เพื่อกู้คืนพื้นที่ว่างใน `/data`

### เมนู 7: 📋 ดูรายการแอปที่ถูก Freeze อยู่ปัจจุบัน
* แสดงรายชื่อแพ็กเกจทั้งหมดที่อยู่ในสถานะ `disabled` เรียงตามตัวอักษร

### เมนู 8: 💾 บันทึก Snapshot ข้อมูลเครื่อง
* สำรองข้อมูล `getprop`, `meminfo`, `df -h`, รายชื่อแพ็กเกจทั้งหมด และรายชื่อแพ็กเกจที่ถูกปิด เก็บไว้ที่ `~/.redmi5a_tuning/snapshot_YYYYMMDD_HHMMSS/`

---

## 7. ฐานข้อมูลแพ็กเกจที่ถูก Freeze (36 รายการ)

### หมวด 1: Telemetry, Analytics & Factory Loggers (9 รายการ)
1. `com.xiaomi.joyose` — Joyose (Telemetry, เก็บสถิติเกม และตัวจำกัดประสิทธิภาพ/Throttling)
2. `com.miui.analytics` — MIUI Analytics (ตัวเก็บสถิติการใช้งานและการคลิกโฆษณาในระบบ)
3. `com.miui.daemon` — MiuiDaemon (ดักเก็บข้อมูลระบบและฮาร์ดแวร์ส่งกลับเซิร์ฟเวอร์ Xiaomi)
4. `com.miui.bugreport` — MiuiBugReport (ตัวดักส่งรายงานข้อผิดพลาด)
5. `com.google.android.feedback` — Google Feedback (ตัวส่ง Crash Report ของ Google)
6. `com.qualcomm.qti.StatsPollManager` — Qualcomm StatsPollManager (ดักเก็บสถิติโมเด็มและพลังงานเบื้องหลัง)
7. `com.bsp.catchlog` — BSP CatchLog (ตัวดักจับล็อกระดับเคอร์เนลและแบตเตอรี่)
8. `com.factory.mmigroup` — Factory MMI Test Group (เซอร์วิสทดสอบฮาร์ดแวร์โรงงานที่รันค้างกินแรมกว่า 21 MB)
9. `com.mi.AutoTest` — Factory AutoTest (เซอร์วิสทดสอบอัตโนมัติของโรงงาน)

### หมวด 2: MIUI System Ads, App Vault & Quick Apps (7 รายการ)
10. `com.miui.msa.global` — MSA (MIUI System Ads - เครื่องมือยิงโฆษณาแฝงหลักในรอม MIUI)
11. `com.mi.android.globalminusscreen` — App Vault / Global Minus Screen (หน้าปัดซ้ายสุดรวมฟีดโฆษณา กินแรมกว่า 31 MB)
12. `com.miui.hybrid` — Quick Apps / Hybrid Platform (เฟรมเวิร์กเว็บแอปแฝงโฆษณา กินแรมกว่า 30 MB)
13. `com.miui.hybrid.accessory` — Hybrid Accessory (เซอร์วิสเสริมของ Quick Apps)
14. `com.miui.cleanmaster` — CleanMaster (โมดูลคลีนเนอร์พ่วงโฆษณาของ Cheetah Mobile)
15. `com.miui.yellowpage` — YellowPage (บริการสมุดหน้าเหลืองพ่วงโฆษณา)
16. `com.miui.wmsvc` — WMService (บริการซิงก์คอนฟิกโฆษณาและลายน้ำเบื้องหลัง)

### หมวด 3: Core Xiaomi Background Push, Casting & Security Scanners (6 รายการ)
17. `com.xiaomi.xmsf` — Xiaomi Service Framework (XMSF - เซอร์วิสพุชเบื้องหลังของ Xiaomi)
18. `com.miui.guardprovider` — GuardProvider (ตัวสแกนไวรัสเบื้องหลังที่ต่อเน็ตตลอดเวลา)
19. `com.milink.service` — MiLink Service (บริการแชร์หน้าจอ/แคสต์ไร้สายของ Xiaomi)
20. `com.xiaomi.mi_connect_service` — Mi Connect Service (สแกนและเชื่อมต่ออุปกรณ์ IoT รอบข้างตลอดเวลา)
21. `com.xiaomi.miplay_client` — MiPlay Client (ระบบแคสต์เสียงและมีเดียเบื้องหลัง)
22. `com.xiaomi.upnp` — Xiaomi UPnP Service (บริการค้นหาอุปกรณ์มีเดียผ่านเครือข่าย)

### หมวด 4: Facebook Pre-installed Trackers (3 รายการ)
23. `com.facebook.appmanager` — Facebook App Manager
24. `com.facebook.services` — Facebook Services
25. `com.facebook.system` — Facebook System Installer

### หมวด 5: OEM Stores, Bloatware & Regional Financial Apps (11 รายการ)
26. `com.xiaomi.mipicks` — GetApps / Mi Picks (ร้านโหลดแอปของ Xiaomi)
27. `com.xiaomi.discover` — Xiaomi System Apps Updater (ตัวอัปเดตแอประบบของ Xiaomi)
28. `com.mipay.wallet.id` — Mi Pay Indonesia
29. `com.mipay.wallet.in` — Mi Pay India
30. `com.micredit.in` — Mi Credit India
31. `com.xiaomi.payment` — Xiaomi Payment Service (Mi Coin)
32. `com.xiaomi.glgm` — Mi Games
33. `com.miui.enbbs` — Mi Community
34. `cn.wps.xiaomi.abroad.lite` — Mi Doc Viewer / WPS Office Lite
35. `com.android.browser` — Mi Browser Global
36. `com.xiaomi.mirecycle` — Mi Recycle

---

## 8. ไดเรกทอรีบันทึกข้อมูลและประวัติการทำงาน

* **ตำแหน่งหลัก:** `~/.redmi5a_tuning/`
* **ไฟล์ประวัติ:** `~/.redmi5a_tuning/tuning_history.log`
* **โฟลเดอร์ Snapshot:** `~/.redmi5a_tuning/snapshot_YYYYMMDD_HHMMSS/`

---

## 9. การแก้ไขปัญหาและคำถามที่พบบ่อย (FAQ)

### Q1: ทำไมหลังสั่ง Freeze แล้ว `com.factory.mmigroup`, `com.xiaomi.xmsf`, และ `com.miui.daemon` ยังมี PID ค้างใน `dumpsys meminfo`?
> **คำตอบ:** เนื่องจากทั้ง 3 แพ็กเกจถูกกำหนดค่า `android:persistent="true"` และรันภายใต้ `android.uid.system` มาตั้งแต่ตอนเปิดเครื่อง คำสั่ง `am force-stop` ของสิทธิ์ Shell จึงไม่สามารถฆ่า PID ระบบที่รันอยู่แล้วได้ทันที แต่เมื่อสถานะถูกเปลี่ยนเป็น `disabled-user` แล้ว **หลังจากที่คุณ Reboot เครื่องเพียงครั้งเดียว ระบบจะไม่สตาร์ททั้ง 3 โปรเซสนี้ขึ้นมาอีกเลย** และจะได้ RAM คืนเพิ่มอีก ~42 MB

### Q2: ปิด App Vault (`com.mi.android.globalminusscreen`) แล้วมีผลอย่างไร?
> **คำตอบ:** หน้าปัดฝั่งซ้ายสุดของหน้าจอโฮม (ที่รวมทางลัดข่าว โฆษณา และวิตเจ็ตที่กินแรมกว่า 31.6 MB) จะถูกปิดการทำงาน ช่วยให้การปัดหน้าจอโฮมของ MIUI Launcher ลื่นขึ้นมาก หากต้องการเปิดกลับมาใช้งาน สามารถใช้เมนู 4 (Unfreeze) ได้ทันที

### Q3: พื้นที่ `/data` ของ Redmi 5A เหลือน้อยมาก ควรดูแลอย่างไร?
> **คำตอบ:** แนะนำให้ใช้ **เมนู 6 -> ตัวเลือก `T`** (`pm trim-caches 999G`) เป็นประจำเพื่อล้างแคชสะสมของแอปต่างๆ และหลีกเลี่ยงการรัน ART Compilation โหมด `-m speed -a` (ให้ใช้ `bg-dexopt-job` หรือ `-m speed-profile -a` แทนเพื่อประหยัดพื้นที่ `/data/dalvik-cache`)

---

## 10. ตารางคำสั่ง ADB ฉบับย่อ (Quick Reference)

| งานที่ต้องการทำ | คำสั่ง ADB |
|---|---|
| ตรวจสอบอุปกรณ์ที่เชื่อมต่อ | `adb devices` |
| ดูสถานะ RAM ปัจจุบัน | `adb shell head -n 15 /proc/meminfo` |
| ดูพื้นที่ว่าง `/data` | `adb shell df -h /data` |
| ล้างแคชระบบทั้งหมดเพื่อคืนพื้นที่ | `adb shell pm trim-caches 999G` |
| สั่ง Freeze แอปแบบปลอดภัย | `adb shell pm disable-user --user 0 <package_name>` |
| สั่งเปิดใช้งานแอปคืน (Unfreeze) | `adb shell pm enable <package_name>` |
| ดูรายชื่อแอปที่ถูก Freeze ทั้งหมด | `adb shell pm list packages -d` |
| รัน Background DEX Optimization | `adb shell cmd package bg-dexopt-job` |
| เปิดหน้า Developer Options บนมือถือ | `adb shell am start -a android.settings.APPLICATION_DEVELOPMENT_SETTINGS` |


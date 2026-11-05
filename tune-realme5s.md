# คู่มือการปรับแต่ง realme 5s ด้วย `tune-realme5s.sh`

คู่มือการใช้งานสคริปต์ปรับแต่งประสิทธิภาพ ปิดบริการโฆษณา/Telemetry และเพิ่มความเร็วสำหรับ **realme 5s (RMX1925)** ผ่าน ADB โดย **ไม่ต้อง Root เครื่อง**

> **เป้าหมาย:** เพิ่ม RAM พร้อมใช้งาน (~2.0 GB+), ลดอาการกระตุกของ ColorOS, ปิดการส่งสถิติเบื้องหลัง, ปิดโฆษณาหน้าจอล็อก และจัดเก็บ Snapshot ข้อมูลเครื่องอย่างปลอดภัย โดยมีระบบถามยืนยัน (Confirm) ก่อนเปลี่ยนแปลงทุกครั้ง

---

## สารบัญ

1. [ข้อมูลเฉพาะของเครื่อง realme 5s](#1-ข้อมูลเฉพาะของเครื่อง-realme-5s)
2. [ผลการสแกนและค้นหา Bloatware บนเครื่องจริง (Actual Device Audit)](#2-ผลการสแกนและค้นหา-bloatware-บนเครื่องจริง-actual-device-audit)
   - [2.1 สภาพแวดล้อมเครื่องที่สแกนจริง](#21-สภาพแวดล้อมเครื่องที่สแกนจริง)
   - [2.2 ตรวจสอบแพ็กเกจข้ามค่าย (Xiaomi / MIUI Check)](#22-ตรวจสอบแพ็กเกจข้ามค่าย-xiaomi--miui-check)
   - [2.3 รายการ Bloatware / Telemetry ที่ตรวจพบจริงพร้อมพาธ APK](#23-รายการ-bloatware--telemetry-ที่ตรวจพบจริงพร้อมพาธ-apk)
   - [2.4 ผลการทดสอบ Freeze และการรับมือข้อจำกัดความปลอดภัย](#24-ผลการทดสอบ-freeze-และการรับมือข้อจำกัดความปลอดภัย)
   - [2.5 ผลการวัดค่าหน่วยความจำจริง (Before vs After)](#25-ผลการวัดค่าหน่วยความจำจริง-before-vs-after)
3. [สิ่งที่ต้องเตรียมก่อนเริ่มใช้งาน](#3-สิ่งที่ต้องเตรียมก่อนเริ่มใช้งาน)
4. [การเริ่มใช้งานสคริปต์ (Quick Start)](#4-การเริ่มใช้งานสคริปต์-quick-start)
5. [รายละเอียดการทำงานของแต่ละเมนู](#5-รายละเอียดการทำงานของแต่ละเมนู)
   - [เมนู 1: ตรวจสอบสถานะเครื่อง & ทรัพยากรระบบ](#เมนู-1-📱-ตรวจสอบสถานะเครื่อง--ทรัพยากรระบบ)
   - [เมนู 2: ปรับความเร็ว Animation Scale](#เมนู-2-⚡-ปรับความเร็ว-animation-scale)
   - [เมนู 3: Freeze Bloatware & Telemetry](#เมนู-3-🛡️-freeze-bloatware--telemetry)
   - [เมนู 4: Unfreeze / Rollback คืนค่าแอป](#เมนู-4-🔄-unfreeze--rollback-คืนค่าแอป)
   - [เมนู 5: ART Runtime Compilation](#เมนู-5-🚀-art-runtime-compilation)
   - [เมนู 6: Force Stop แอปชั่วคราว](#เมนู-6-🛑-force-stop-แอปชั่วคราว)
   - [เมนู 7: ดูรายการแอปที่ถูก Freeze อยู่ปัจจุบัน](#เมนู-7-📋-ดูรายการแอปที่ถูก-freeze-อยู่ปัจจุบัน)
   - [เมนู 8: บันทึก Snapshot ข้อมูลเครื่อง](#เมนู-8-💾-บันทึก-snapshot-ข้อมูลเครื่อง)
6. [ฐานข้อมูลแพ็กเกจที่ถูก Freeze (21 รายการ)](#6-ฐานข้อมูลแพ็กเกจที่ถูก-freeze-21-รายการ)
7. [ไดเรกทอรีบันทึกข้อมูลและประวัติการทำงาน](#7-ไดเรกทอรีบันทึกข้อมูลและประวัติการทำงาน)
8. [การแก้ไขปัญหาและคำถามที่พบบ่อย (FAQ)](#8-การแก้ไขปัญหาและคำถามที่พบบ่อย-faq)
9. [ตารางคำสั่ง ADB ฉบับย่อ (Quick Reference)](#9-ตารางคำสั่ง-adb-ฉบับย่อ-quick-reference)

---

## 1. ข้อมูลเฉพาะของเครื่อง realme 5s

* **รหัสรุ่น (Model):** `RMX1925`
* **ชิปประมวลผล:** Qualcomm Snapdragon 665 (`trinket`) Octa-Core
* **หน่วยความจำ:** RAM 4 GB / ROM 64 หรือ 128 GB
* **ระบบปฏิบัติการ:** ColorOS 6 / 7 (Android 9 หรือ 10)
* **ข้อจำกัดเฉพาะของ ColorOS บนรุ่นนี้:**
  1. **สิทธิ์ Settings Put:** คำสั่ง `adb shell settings put global ...` มักถูกปฏิเสธด้วย `WRITE_SECURE_SETTINGS` เมื่อปรับผ่าน ADB
  2. **สิทธิ์ Package Manager:** มี `OppoPackageManagerService` ป้องกันการใช้คำสั่ง `cmd package compile -m speed -a` (จะแสดงข้อผิดพลาด `Error: Failed to cpmpile !`) และป้องกันการ Disable แอปบางตัว เช่น `com.nearme.gamecenter`
  3. **ห้ามใช้คำสั่งข้ามค่าย:** ไม่ควรใช้สคริปต์ Debloat ของ Xiaomi/MIUI (เช่น Joyose, MiShare, MSA) เพราะไม่มีอยู่จริงในเครื่องนี้ และอาจเผลอปิดเซอร์วิสผิดพลาด

---

## 2. ผลการสแกนและค้นหา Bloatware บนเครื่องจริง (Actual Device Audit)

หัวข้อนี้บันทึกผลการสำรวจและวิเคราะห์แพ็กเกจจากเครื่องจริงผ่านพอร์ต ADB โดยตรง:

### 2.1 สภาพแวดล้อมเครื่องที่สแกนจริง
* **Device Serial:** `53a45a91`
* **Manufacturer / Model:** `realme` / `RMX1925` (realme 5s)
* **Android Release / API:** Android 10 (SDK 29)
* **Build Display ID:** `RMX1925EX_11_C.77`
* **Hardware Platform:** Qualcomm `trinket` (Snapdragon 665)
* **จำนวนแพ็กเกจทั้งหมดในระบบ:** **337 แพ็กเกจ** (รวม System, Priv-app, Framework overlays และ User apps)

---

### 2.2 ตรวจสอบแพ็กเกจข้ามค่าย (Xiaomi / MIUI Check)
ได้ทำการค้นหาเซอร์วิสของ Xiaomi ที่ผู้ใช้มักสับสนหรือนำสคริปต์จากอินเทอร์เน็ตมารัน ด้วยคำสั่ง:
```bash
adb shell "pm list packages | grep -iE 'joyose|mishare|milink|adservice|guardprovider|msa|analytics|miui|xiaomi'"
```
* **ผลลัพธ์:** **ไม่พบแพ็กเกจใดๆ ทั้งสิ้น (0 รายการ / Exit code 1)**  
* **ข้อสรุป:** ยืนยันว่าเครื่อง realme 5s **ไม่มี** เซอร์วิสของ Xiaomi การรันสคริปต์ Debloat ของ MIUI บนเครื่องนี้จึงไม่มีผล และอาจทำให้คำสั่ง Error

---

### 2.3 รายการ Bloatware / Telemetry ที่ตรวจพบจริงพร้อมพาธ APK
จากการสแกนแบบละเอียดด้วย `pm list packages -f` พบแพ็กเกจขยะ, โฆษณา และ Telemetry ที่ติดตั้งอยู่จริงในระบบ แบ่งตามพาธการติดตั้งได้ดังนี้:

| หมวดหมู่ | Package Name | ตำแหน่งไฟล์ APK ในเครื่องจริง | บทบาทของเซอร์วิส |
|---|---|---|---|
| **Lockscreen Ads** | `com.heytap.pictorial` | `/data/app/com.heytap.pictorial-.../base.apk` | โฆษณาหน้าจอล็อก & แมกกาซีน |
| **Telemetry** | `com.heytap.habit.analysis` | `/system/priv-app/IntelligentAnalyticsSystem/...apk` | ระบบดักจับและวิเคราะห์พฤติกรรมผู้ใช้ |
| **Telemetry** | `com.nearme.statistics.rom` | `/system/app/OppoDCS/OppoDCS.apk` | Data Collection Service ดักเก็บสถิติรอม |
| **Log Daemon** | `com.oppo.logkit` | `/system/app/OppoLogKit_Beta/OppoLogKit_Beta.apk` | ตัวเก็บ Log เบื้องหลังอย่างละเอียด |
| **Telemetry** | `com.oppo.qualityprotect` | `/system/app/OppoQualityProtect/OppoQualityProtect.apk` | ตัวส่งรายงานข้อผิดพลาดและ Crash log |
| **Crash Report** | `com.google.android.feedback` | `/system/product/priv-app/GoogleFeedback/...apk` | ตัวส่ง Feedback ข้อผิดพลาดของ Google |
| **Push / Ads** | `com.nearme.atlas` | `/data/app/com.nearme.atlas-.../base.apk` | เฟรมเวิร์กยิงโฆษณาและการแจ้งเตือน NearMe |
| **Push / Ads** | `com.oppo.atlas` | `/system/app/OppoAtlasService/OppoAtlasService.apk` | เซอร์วิสกระจาย Push และโฆษณาของ Oppo |
| **Ad Search Feed** | `com.oppo.quicksearchbox` | `/data/app/com.oppo.quicksearchbox-.../base.apk` | กล่องค้นหาหน้าหลักพร้อมฟีดแนะนำโฆษณา |
| **Facebook Tracker**| `com.facebook.appmanager` | `/data/app/com.facebook.appmanager-.../base.apk` | ตัวอัปเดตและตรวจเช็กแอป Facebook เบื้องหลัง |
| **Facebook Tracker**| `com.facebook.services` | `/data/app/com.facebook.services-.../base.apk` | บริการ Sync และ Telemetry ของ Facebook |
| **Facebook Tracker**| `com.facebook.system` | `/data/app/com.facebook.system-.../base.apk` | ตัวติดตั้งของ Facebook ฝังในระดับระบบ |
| **OEM Store** | `com.heytap.market` | `/data/app/com.heytap.market-.../base.apk` | ร้านค้า HeyTap App Market ชวนโหลดแอป |
| **Theme Ads** | `com.heytap.themestore` | `/data/app/com.heytap.themestore-.../base.apk` | ร้านธีมที่มีการยิงโฆษณาและบริการเสียเงิน |
| **OEM Browser** | `com.heytap.browser` | `/data/app/com.heytap.browser-.../base.apk` | เบราว์เซอร์แถมที่มีฟีดข่าวและโฆษณาแฝง |
| **Game Daemon** | `com.coloros.gamespace` | `/system/app/GameSpace/GameSpace.apk` | ตัวจัดการเกม ColorOS ทำงานตลอดเวลา |
| **Side Screen Feed**| `com.coloros.assistantscreen` | `/system/app/AssistantScreen/AssistantScreen.apk` | หน้าจอด้านซ้ายสุด (-1 Screen) มีฟีดข่าวและโปรโมต |
| **Partner Links** | `com.oppo.partnerbrowsercustomizations` | `/system/app/OppoChromeCustomizations/...apk` | บุ๊กมาร์กและลิงก์โปรโมตฝังในเบราว์เซอร์ |
| **Manual App** | `com.oppo.operationManual` | `/system/app/OppoOperationManualExp/...apk` | คู่มือเครื่องแบบแอปพลิเคชัน |
| **Roaming Service** | `com.redteamobile.roaming` | `/system/priv-app/SoftsimRedteaRoaming/...apk` | ซอฟต์แวร์ SoftSIM โรมมิ่งต่างประเทศ |
| **Roaming Daemon** | `com.redteamobile.roaming.deamon` | `/system/priv-app/SoftsimRedteaRoamingDeamon/...apk` | เซอร์วิสเบื้องหลังของ SoftSIM โรมมิ่ง |
| **Protected App** | `com.nearme.gamecenter` | `/data/app/com.nearme.gamecenter-.../base.apk` | ศูนย์รวมเกม NearMe Game Center |

---

### 2.4 ผลการทดสอบ Freeze และการรับมือข้อจำกัดความปลอดภัย
1. **แพ็กเกจเดิมที่ถูกปิดอยู่แล้วก่อนเริ่มสแกน (3 แพ็กเกจ):**
   * `com.android.nfc` (realme 5s ไม่มีชิป NFC ฮาร์ดแวร์จริง รอมจึงปิดไว้)
   * `com.realme.securitycheck`
   * `com.coloros.gamespaceui`
2. **แพ็กเกจที่สั่ง Freeze สำเร็จผ่านคำสั่ง `pm disable-user --user 0` (21 แพ็กเกจ):**
   * ทุกแพ็กเกจในตารางด้านบน (รายการ 1 - 21) เปลี่ยนสถานะเป็น `disabled-user` สำเร็จสมบูรณ์ 100%
3. **กรณีพิเศษของ `com.nearme.gamecenter`:**
   * เมื่อรันคำสั่ง `pm disable com.nearme.gamecenter` ระบบตอบกลับว่า:
     ```text
     Security exception: Shell cannot change component state for com.nearme.gamecenter/null to 2
     at com.android.server.pm.OppoPackageManagerService.setApplicationEnabledSetting(...)
     ```
   * **การแก้ไข:** `OppoPackageManagerService` ดักป้องกันการปิดแอปนี้ไว้ สคริปต์จึงแก้ไขโดยใช้คำสั่ง `am force-stop com.nearme.gamecenter` เพื่อบังคับปิดการทำงานออกจาก RAM แทน

---

### 2.5 ผลการวัดค่าหน่วยความจำจริง (Before vs After)
การตรวจสอบหน่วยความจำจาก `/proc/meminfo` ของเครื่องจริงเปรียบเทียบผลลัพธ์:

* **ก่อนดำเนินการ (Before):**
  * `MemTotal`: 3,728,932 kB (~3.72 GB)
  * `MemAvailable`: ~1,600,000 kB (~1.60 GB)
* **หลังดำเนินการ Freeze 21 แพ็กเกจ (After):**
  * `MemTotal`: 3,728,932 kB (~3.72 GB)
  * `MemAvailable`: **2,041,644 kB (~2.04 GB)**
  * **ผลลัพธ์:** ได้ RAM พร้อมใช้งานคืนกลับมาทันที **~440 MB** (เพิ่มขึ้นเกือบ 28%)
* **ความสมบูรณ์ของระบบ:** `sys.boot_completed = 1`, กล้องถ่ายรูป, โทรศัพท์เข้า-ออก, ข้อความ SMS, Wi-Fi 2.4GHz/5GHz, บลูทูธ และแอปพลิเคชันธนาคารไทย (SCB Easy, Krungthai NEXT) ใช้งานได้ตามปกติ ไร้อาการ Force Close

---

## 3. สิ่งที่ต้องเตรียมก่อนเริ่มใช้งาน

### 3.1 ติดตั้ง ADB (Android Platform Tools) บนคอมพิวเตอร์
* **macOS (Homebrew):**
  ```bash
  brew install android-platform-tools
  ```
* **Windows / Linux:** ดาวน์โหลดจาก [Android Developer Platform Tools](https://developer.android.com/tools/releases/platform-tools) แล้วแตกไฟล์ไว้ในเครื่อง

### 3.2 เปิดโหมด USB Debugging บนโทรศัพท์
1. ไปที่ **Settings (การตั้งค่า)** > **About phone (เกี่ยวกับโทรศัพท์)**
2. แตะที่ **Version / Build number (หมายเลขบิลด์)** ติดต่อกัน 7 ครั้ง จนขึ้นว่า *"You are now in developer mode!"*
3. ย้อนกลับไปที่ **Settings** > **Additional settings (การตั้งค่าเพิ่มเติม)** > **Developer options (ตัวเลือกสำหรับนักพัฒนา)**
4. เปิดใช้งาน **USB debugging**
5. เสียบสาย USB เข้ากับคอมพิวเตอร์ ปลดล็อกหน้าจอมือถือ และกด **Allow / ยอมรับ** ที่หน้าต่างยืนยัน RSA Fingerprint

---

## 4. การเริ่มใช้งานสคริปต์ (Quick Start)

สคริปต์ [**`tune-realme5s.sh`**](file:///Users/billy/git/Python-Utility/tune-realme5s.sh) ได้รับการออกแบบให้ทำงานได้ทั้งบน macOS และ Linux โดยค้นหาตำแหน่ง ADB อัตโนมัติ

1. เปิด Terminal ในโฟลเดอร์ของโปรเจกต์
2. ให้สิทธิ์รันสคริปต์ (ทำเพียงครั้งแรก):
   ```bash
   chmod +x tune-realme5s.sh
   ```
3. สั่งรันสคริปต์:
   ```bash
   ./tune-realme5s.sh
   ```
4. สคริปต์จะตรวจสอบการเชื่อมต่อ ตรวจสอบชื่อรุ่น (`RMX1925`) และแสดงหน้าจอเมนูหลัก

---

## 5. รายละเอียดการทำงานของแต่ละเมนู

### เมนู 1: 📱 ตรวจสอบสถานะเครื่อง & ทรัพยากรระบบ
* **หน้าที่:** แสดงภาพรวมของเครื่องทันทีโดยไม่ต้องจำคำสั่งยาวๆ
* **ข้อมูลที่รายงาน:**
  * แพลตฟอร์มชิปเซ็ต (`trinket`), Security Patch วันที่อัปเดตความปลอดภัย, สถานะ Boot (`green`)
  * หน่วยความจำ RAM (MemTotal, MemFree, **MemAvailable**, Swap/ZRAM)
  * พื้นที่จัดเก็บข้อมูลในพาร์ติชัน `/data` (ขนาดทั้งหมด, พื้นที่ใช้ไป, พื้นที่คงเหลือ)
  * สถานะแบตเตอรี่ (ระดับเปอร์เซ็นต์, อุณหภูมิ, แรงดันไฟฟ้า, สถานะสุขภาพ)
  * จำนวนแอปที่ถูก Freeze อยู่ในปัจจุบัน

---

### เมนู 2: ⚡ ปรับความเร็ว Animation Scale
* **หน้าที่:** ปรับลดเวลาแสดงกราฟิกเอฟเฟกต์เปิด-ปิดหน้าต่างและสลับแอป
* **ตัวเลือก:**
  * **0.5x (แนะนำ):** ลดระยะเวลาลงครึ่งหนึ่ง ทำให้ UI รู้สึกตอบสนองรวดเร็ว ลื่นไหลขึ้นอย่างเห็นได้ชัด
  * **1.0x:** คืนค่ามาตรฐานโรงงาน
  * **0.0x:** ปิดแอนิเมชันทั้งหมด (หน้าต่างเด้งทันทีโดยไม่มีการเคลื่อนไหว)
* **กลไกการรับมือ ColorOS:**  
  หาก ROM ปฏิเสธคำสั่ง ADB ด้วยข้อผิดพลาด `WRITE_SECURE_SETTINGS` สคริปต์จะ**สั่งเปิดหน้า Developer Options บนหน้าจอมือถือให้ทันที** พร้อมระบุให้ผู้ใช้ปรับ 3 ค่านี้ด้วยตนเอง:
  1. *Window animation scale*
  2. *Transition animation scale*
  3. *Animator duration scale*

---

### เมนู 3: 🛡️ Freeze Bloatware & Telemetry
* **หน้าที่:** ปิดการทำงานของแอปขยะ โฆษณา และระบบเก็บสถิติที่แฝงมากับเครื่อง
* **คำสั่งที่ใช้:** `pm disable-user --user 0 <PACKAGE_NAME>`
* **ความปลอดภัย:**
  * **ไม่ลบไฟล์:** ไฟล์ระบบของ Android ไม่เสียหาย สามารถเปิดคืน (Unfreeze) ได้สมบูรณ์ 100%
  * **ไม่กระทบแอปสำคัญ:** ไม่แตะต้องแป้นพิมพ์ (Gboard), ตัวเปิดแอป (Launcher), กล้อง, โทรศัพท์, SMS, Wi-Fi หรือส่วนความปลอดภัยที่แอปธนาคารไทยเรียกตรวจ
* **ตัวเลือกในการ Freeze:**
  * `1) Freeze ทุกกลุ่มที่แนะนำ (Safe All - ทั้ง 21 แพ็กเกจ)` *(แนะนำสูงสุด)*
  * `2) เฉพาะกลุ่ม Telemetry & Analytics (5 รายการ)`
  * `3) เฉพาะกลุ่ม Lockscreen Ads & Push (4 รายการ)`
  * `4) เฉพาะกลุ่ม Facebook Pre-installed (3 รายการ)`
  * `5) เฉพาะกลุ่ม OEM Store & Bloatware (9 รายการ)`
  * `6) เลือก Freeze ทีละแพ็กเกจด้วยตนเอง`

---

### เมนู 4: 🔄 Unfreeze / Rollback คืนค่าแอป
* **หน้าที่:** กู้คืนแอปที่เคยสั่ง Freeze ให้กลับมาทำงานตามปกติ
* **คำสั่งที่ใช้:** `pm enable <PACKAGE_NAME>`
* **ตัวเลือกในการกู้คืน:**
  * **คืนค่าทั้งหมด:** สั่งเปิดทุกแพ็กเกจที่ปิดอยู่ในเครื่องให้กลับมาทำงานพร้อมกัน
  * **เลือกทีละตัว:** แสดงรายการเฉพาะแอปที่ปิดอยู่ปัจจุบัน พร้อมตัวเลขให้เลือกเปิดเฉพาะตัวที่ต้องการ
  * **พิมพ์ชื่อแพ็กเกจเอง:** สำหรับกรณีต้องการเปิดแอปเฉพาะเจาะจง

---

### เมนู 5: 🚀 ART Runtime Compilation
* **หน้าที่:** สั่งให้ Android Runtime (ART) ทำการ Optimize โค้ดของแอปพลิเคชันล่วงหน้า (Ahead-Of-Time) เพื่อให้เปิดแอปได้เร็วขึ้นและลดอาการโหลดช้า
* **ความเข้ากันได้กับ realme 5s:**
  * คำสั่งดั้งเดิม `cmd package compile -m speed -a` จะถูก ColorOS บล็อกด้วยข้อความ `Error: Failed to cpmpile !` (ซึ่งเป็นบั๊กตัวสะกดใน AOSP ของ Google)
  * สคริปต์ของเรารองรับปัญหานี้ โดยจะสลับไปรันคำสั่งทางการที่ ColorOS อนุญาต:
    ```bash
    adb shell cmd package bg-dexopt-job
    ```
  * คำสั่งนี้จะทำการ Optimize แอปตามสถิติการใช้งานจริง (Profile-guided) และคืนสถานะ `Success` อย่างปลอดภัย
* **ข้อควรระวัง:** ขณะรันคำสั่งนี้ เครื่องอาจอุ่นขึ้นและกินพลังงานแบตเตอรี่ **แนะนำให้เสียบสายชาร์จขณะทำ**

---

### เมนู 6: 🛑 Force Stop แอปชั่วคราว
* **หน้าที่:** สั่งปิดแอปที่เปิดค้างอยู่ใน RAM ทันที เพื่อคืนหน่วยความจำชั่วคราว
* **ความแตกต่างกับการ Freeze:** การ Force-stop ไม่ได้ปิดการทำงานถาวร หากผู้ใช้แตะไอคอนแอปบนหน้าจอมือถือ แอปจะเปิดขึ้นมาทำงานใหม่ตามปกติ
* **แอปเป้าหมาย:** Facebook, Messenger, Instagram, TikTok, YouTube, Gmail และ Oppo Game Center

---

### เมนู 7: 📋 ดูรายการแอปที่ถูก Freeze อยู่ปัจจุบัน
* **หน้าที่:** เรียกดูรายชื่อแพ็กเกจทั้งหมดที่อยู่ในสถานะ `disabled` บนเครื่อง (ดึงข้อมูลสดจาก `pm list packages -d`)

---

### เมนู 8: 💾 บันทึก Snapshot ข้อมูลเครื่อง
* **หน้าที่:** บันทึกสำเนาข้อมูลการตั้งค่าและรายการแอปทั้งหมดของเครื่องเก็บไว้บนคอมพิวเตอร์
* **ตำแหน่งที่จัดเก็บ:** `~/.realme5s_tuning/snapshot_YYYYMMDD_HHMMSS/`
* **ไฟล์ที่ถูกสร้าง:**
  * `android-getprop.txt` — ค่าระบบ Property ทั้งหมด
  * `android-meminfo.txt` — สถิติการใช้งาน RAM ปัจจุบัน
  * `android-storage.txt` — ขนาดพื้นที่จัดเก็บดิสก์
  * `android-all-packages.txt` — รายชื่อแพ็กเกจทั้งหมดพร้อมพาธ APK
  * `android-disabled-packages.txt` — รายชื่อแพ็กเกจที่ถูกปิดใช้งาน

---

## 6. ฐานข้อมูลแพ็กเกจที่ถูก Freeze (21 รายการ)

ตารางแสดงรายชื่อแพ็กเกจที่ผ่านการทดสอบบน realme 5s และได้รับการบรรจุอยู่ในสคริปต์:

### หมวด 1: Telemetry & Analytics (เก็บสถิติ/พฤติกรรมการใช้งาน)
| Package Name | ชื่อแสดงในระบบ / บทบาท | เหตุผลที่ควรปิด |
|---|---|---|
| `com.heytap.habit.analysis` | Intelligent Analytics System | ส่องพฤติกรรม วิเคราะห์รูปแบบการใช้งานเพื่อส่งข้อมูลกลับศูนย์ |
| `com.nearme.statistics.rom` | Oppo DCS (Data Collection Service) | ดักเก็บสถิติการทำงานของ ColorOS เบื้องหลังตลอดเวลา |
| `com.oppo.logkit` | Oppo LogKit Beta Daemon | ดักเก็บ Log การทำงานอย่างละเอียด กินพลังงาน CPU/RAM |
| `com.oppo.qualityprotect` | Quality Protect Telemetry | บริการส่งรายงานข้อผิดพลาดและข้อมูลระบบกลับ Oppo |
| `com.google.android.feedback` | Google Feedback Reporter | ตัวดักส่งรายงานข้อผิดพลาดของ Google ที่ไม่จำเป็นในชีวิตประจำวัน |

### หมวด 2: Lockscreen Ads & Push Daemons (โฆษณาหน้าจอล็อก & แจ้งเตือนแฝง)
| Package Name | ชื่อแสดงในระบบ / บทบาท | เหตุผลที่ควรปิด |
|---|---|---|
| `com.heytap.pictorial` | Lockscreen Magazine / Poster | ตัวสลับรูปหน้าจอล็อกที่มีการดาวน์โหลดแบนเนอร์โฆษณาและเปลืองเน็ต |
| `com.nearme.atlas` | NearMe Push & Ad Delivery | โครงข่ายสำหรับรับ-ส่งข้อมูลโฆษณาและการแจ้งเตือนแนะนำของ NearMe |
| `com.oppo.atlas` | Oppo Atlas Service | เซอร์วิสเบื้องหลังของ Atlas ในการกระจายสื่อโฆษณา |
| `com.oppo.quicksearchbox` | Oppo Quick Search Box | กล่องค้นหาหน้าหลักที่แอบดึงฟีดข่าว คอนเทนต์โปรโมต และคำค้นหายอดนิยม |

### หมวด 3: Facebook Pre-installed Trackers (บริการเบื้องหลังของ Facebook)
| Package Name | ชื่อแสดงในระบบ / บทบาท | เหตุผลที่ควรปิด |
|---|---|---|
| `com.facebook.appmanager` | Facebook App Manager | ตัวเช็กและอัปเดตบริการ Facebook เบื้องหลังโดยไม่ผ่าน Play Store |
| `com.facebook.services` | Facebook Services | เซอร์วิสดักส่ง Telemetry และ Sync ข้อมูลของ Facebook ตลอดเวลา |
| `com.facebook.system` | Facebook System Installer | สิทธิ์ตัวติดตั้งระดับระบบของ Facebook |

> *(หมายเหตุ: การปิด 3 ตัวนี้ **ไม่มีผลกระทบ** ต่อการใช้งานแอป Facebook หรือ Messenger ที่โหลดจาก Google Play Store)*

### หมวด 4: OEM Stores & Redundant Bloatware (ร้านค้าแถม/เบราว์เซอร์/ผู้ช่วย)
| Package Name | ชื่อแสดงในระบบ / บทบาท | เหตุผลที่ควรปิด |
|---|---|---|
| `com.heytap.market` | HeyTap App Market | ร้านโหลดแอปของค่าย คอยยิง Notification ชวนโหลดเกม/แอปขยะ |
| `com.heytap.themestore` | HeyTap Theme Store | ร้านขายธีมและฟอนต์ มีการยิงข้อความโฆษณาและบริการแบบมีค่าใช้จ่าย |
| `com.heytap.browser` | HeyTap Browser | เบราว์เซอร์แถมที่มีฟีดข่าวและโฆษณาจำนวนมาก (เครื่องมี Chrome อยู่แล้ว) |
| `com.coloros.gamespace` | GameSpace Engine | ตัวจัดการพื้นที่เล่นเกมที่รันเบื้องหลังตลอดเวลา |
| `com.coloros.assistantscreen` | Breeno / Assistant Screen | หน้าจอด้านซ้ายสุด (-1 Screen) พร้อมวิดเจ็ตข่าวสารและคอนเทนต์โปรโมต |
| `com.oppo.partnerbrowsercustomizations` | Partner Browser Customization | สคริปต์แฝงบุ๊กมาร์กและลิงก์สปอนเซอร์ลงใน Chrome |
| `com.oppo.operationManual` | Oppo Operation Manual | คู่มือการใช้งานเครื่องในรูปแบบแอปพลิเคชัน |
| `com.redteamobile.roaming` | Redtea Roaming Service | บริการ SoftSIM ซื้อแพ็กเกจเน็ตโรมมิ่งไปต่างประเทศ |
| `com.redteamobile.roaming.deamon` | Redtea Roaming Daemon | เซอร์วิสเบื้องหลังของ SoftSIM โรมมิ่ง |

---

## 7. ไดเรกทอรีบันทึกข้อมูลและประวัติการทำงาน

สคริปต์จะเก็บข้อมูลประวัติและการ Snapshot ไว้ที่โฮมไดเรกทอรีของผู้ใช้:

* **ตำแหน่งหลัก:** `~/.realme5s_tuning/`
* **ไฟล์ประวัติ:** `~/.realme5s_tuning/tuning-history.log`  
  บันทึกวันเวลาและรายการที่ถูกแก้ไข เช่น:
  ```text
  [2026-11-05 16:07:01] Freeze package: com.facebook.services
  [2026-11-05 16:07:01] Freeze package: com.heytap.pictorial
  [2026-11-05 16:30:10] Executed cmd package bg-dexopt-job successfully
  ```
* **โฟลเดอร์ Snapshot:** `~/.realme5s_tuning/snapshot_YYYYMMDD_HHMMSS/`

---

## 8. การแก้ไขปัญหาและคำถามที่พบบ่อย (FAQ)

### Q1: ปิดแอปพวกนี้แล้ว แอปธนาคารไทย (SCB, KTB, Krungsri, Bitkub) จะใช้ได้ไหม?
> **คำตอบ:** ใช้งานได้ตามปกติ 100% สคริปต์ไม่มีการแตะต้อง Keystore, CTS, Play Integrity, Security Provider, หรือไฟล์ระบบใดๆ

### Q2: รูปหน้าจอล็อกหยุดเปลี่ยนภาพ หรืออยากได้ภาพสไลด์หน้าจอล็อกกลับมา ต้องทำอย่างไร?
> **คำตอบ:** ให้เข้า **เมนู 4 (Unfreeze)** แล้วเลือกเปิดคืนแพ็กเกจ:
> ```bash
> adb shell pm enable com.heytap.pictorial
> ```

### Q3: รันคำสั่ง `cmd package compile -m speed -a` แล้วขึ้น `Error: Failed to cpmpile !` เป็นอะไรไหม?
> **คำตอบ:** เครื่องไม่ได้เสียหาย เป็นข้อจำกัดด้านสิทธิ์ของ ColorOS ให้ใช้คำสั่ง `adb shell cmd package bg-dexopt-job` แทน ซึ่งสคริปต์ในเมนู 5 จะจัดการให้โดยอัตโนมัติ

### Q4: สามารถ Factory Reset เครื่องได้ไหมหลังจากรันสคริปต์นี้?
> **คำตอบ:** ได้ตามปกติ การ Factory Reset จะทำการคืนค่าแพ็กเกจทั้งหมดกลับสู่สภาพเดิมจากโรงงาน

---

## 9. ตารางคำสั่ง ADB ฉบับย่อ (Quick Reference)

| สิ่งที่ต้องการทำ | คำสั่ง ADB |
|---|---|
| ตรวจสอบการเชื่อมต่อ | `adb devices` |
| ดูรุ่นและเวอร์ชัน Android | `adb shell getprop ro.product.model` |
| ดู RAM คงเหลือปัจจุบัน | `adb shell cat /proc/meminfo \| grep MemAvailable` |
| ดูรายการแอปที่ถูก Freeze อยู่ | `adb shell pm list packages -d` |
| สั่ง Freeze แอปเดี่ยว | `adb shell pm disable-user --user 0 <PACKAGE_NAME>` |
| สั่งเปิดคืนแอปเดี่ยว | `adb shell pm enable <PACKAGE_NAME>` |
| บังคับปิดแอปออกจาก RAM | `adb shell am force-stop <PACKAGE_NAME>` |
| สั่ง Optimize แอปผ่านระบบ | `adb shell cmd package bg-dexopt-job` |
| เปิดหน้า Developer options | `adb shell am start -a android.settings.APPLICATION_DEVELOPMENT_SETTINGS` |

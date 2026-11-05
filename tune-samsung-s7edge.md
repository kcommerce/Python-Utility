# คู่มือการปรับแต่งเครื่อง Samsung (`SM-G935F` / Galaxy S7 Edge) ด้วย `tune-samsung-s7edge.sh`

คู่มือฉบับสมบูรณ์สำหรับการปรับแต่งประสิทธิภาพ ปิดระบบโฆษณาการตลาด (Samsung Push Service, Briefing, Flipboard, Galaxy Gift), เซอร์วิส Telemetry/Analytics (DiagMonAgent, Customization Service/Rubin, ContextProvider), ตัวจำกัดความเร็วเกม (Game Optimizing Service - GOS) และ Bloatware บนเครื่อง **Samsung (`SM-G935F` / Codename: `hero2lte`)** ผ่าน ADB โดย **ไม่ต้อง Root เครื่อง**

> **เป้าหมายหลัก:** คืนทรัพยากรหน่วยความจำ (RAM) กว่า **+571 MB** และพื้นที่จัดเก็บข้อมูล (`/data`) กว่า **+1.15 GB**, ตัดการทำงานของ Game Optimizing Service (GOS) ที่จำกัดความเร็ว CPU/GPU, ปิดหน้าปัด Briefing/Flipboard และบริการติดตามพฤติกรรมเบื้องหลัง พร้อมระบบสำรองข้อมูล Snapshot และถามยืนยัน (Confirm) ก่อนเปลี่ยนแปลงทุกครั้ง

---

## สารบัญ

1. [ข้อมูลเฉพาะของเครื่อง Samsung ที่เชื่อมต่อจริง](#1-ข้อมูลเฉพาะของเครื่อง-samsung-ที่เชื่อมต่อจริง)
2. [ตารางเปรียบเทียบเชิงลึก 4 รุ่น: Samsung vs Redmi 5A vs Redmi 7A vs realme 5s](#2-ตารางเปรียบเทียบเชิงลึก-4-รุ่น-samsung-vs-redmi-5a-vs-redmi-7a-vs-realme-5s)
3. [ผลการสแกนและค้นหา Bloatware บนเครื่องจริง (Actual Device Audit)](#3-ผลการสแกนและค้นหา-bloatware-บนเครื่องจริง-actual-device-audit)
   - [3.1 สภาพแวดล้อมเครื่องที่สแกนจริง (Before Snapshot)](#31-สภาพแวดล้อมเครื่องที่สแกนจริง-before-snapshot)
   - [3.2 การจับคู่เซอร์วิสเทียบเท่า (Xiaomi MIUI vs Samsung Experience / One UI)](#32-การจับคู่เซอร์วิสเทียบเท่า-xiaomi-miui-vs-samsung-experience--one-ui)
   - [3.3 รายการ Bloatware / Telemetry ทั้ง 49 รายการพร้อมพาธ APK จริง](#33-รายการ-bloatware--telemetry-ทั้ง-49-รายการพร้อมพาธ-apk-จริง)
   - [3.4 ผลการทดสอบ Freeze, Animation Scale และ ART Compilation](#34-ผลการทดสอบ-freeze-animation-scale-และ-art-compilation)
   - [3.5 สรุปผลเปรียบเทียบก่อนและหลังทำ (Before vs After: RAM, Swap & Disk Space)](#35-สรุปผลเปรียบเทียบก่อนและหลังทำ-before-vs-after-ram-swap--disk-space)
4. [สิ่งที่ต้องเตรียมก่อนเริ่มใช้งาน](#4-สิ่งที่ต้องเตรียมก่อนเริ่มใช้งาน)
5. [การเริ่มใช้งานสคริปต์ (Quick Start)](#5-การเริ่มใช้งานสคริปต์-quick-start)
6. [รายละเอียดการทำงานของแต่ละเมนูในสคริปต์](#6-รายละเอียดการทำงานของแต่ละเมนูในสคริปต์)
   - [เมนู 1: ตรวจสอบสถานะเครื่อง & ทรัพยากรระบบ](#เมนู-1-📱-ตรวจสอบสถานะเครื่อง--ทรัพยากรระบบ)
   - [เมนู 2: ปรับความเร็ว Animation Scale](#เมนู-2-⚡-ปรับความเร็ว-animation-scale)
   - [เมนู 3: Freeze Bloatware & Telemetry (49 รายการ)](#เมนู-3-🛡️-freeze-bloatware--telemetry-49-รายการ)
   - [เมนู 4: Unfreeze / Rollback คืนค่าแอป](#เมนู-4-🔄-unfreeze--rollback-คืนค่าแอป)
   - [เมนู 5: ART Runtime Compilation](#เมนู-5-🚀-art-runtime-compilation)
   - [เมนู 6: Force Stop แอปชั่วคราว & ล้างแคชระบบ (Trim Caches)](#เมนู-6-🛑-force-stop-แอปชั่วคราว--ล้างแคชระบบ-trim-caches)
   - [เมนู 7: ดูรายการแอปที่ถูก Freeze อยู่ปัจจุบัน](#เมนู-7-📋-ดูรายการแอปที่ถูก-freeze-อยู่ปัจจุบัน)
   - [เมนู 8: บันทึก Snapshot ข้อมูลเครื่อง](#เมนู-8-💾-บันทึก-snapshot-ข้อมูลเครื่อง)
7. [ฐานข้อมูลแพ็กเกจที่ถูก Freeze (49 รายการ)](#7-ฐานข้อมูลแพ็กเกจที่ถูก-freeze-49-รายการ)
8. [ไดเรกทอรีบันทึกข้อมูลและประวัติการทำงาน](#8-ไดเรกทอรีบันทึกข้อมูลและประวัติการทำงาน)
9. [การแก้ไขปัญหาและคำถามที่พบบ่อย (FAQ)](#9-การแก้ไขปัญหาและคำถามที่พบบ่อย-faq)
10. [ตารางคำสั่ง ADB ฉบับย่อ (Quick Reference)](#10-ตารางคำสั่ง-adb-ฉบับย่อ-quick-reference)

---

## 1. ข้อมูลเฉพาะของเครื่อง Samsung ที่เชื่อมต่อจริง

* **รหัสรุ่นจาก `getprop` (Model):** `SM-G935F` (Samsung Galaxy S7 Edge)
* **รหัสประจำอุปกรณ์ (Codename):** `hero2lte`
* **ชิปประมวลผล:** Samsung Exynos 8890 (`samsungexynos8890` / `exynos5`) Octa-Core (4x 2.3 GHz Exynos M1 Mongoose & 4x 1.6 GHz Cortex-A53, GPU Mali-T880 MP12)
* **หน่วยความจำ:** RAM 4 GB (`MemTotal`: `3,622,724 kB` / ~3.45 GB) / ROM 32 GB UFS 2.0 (พาร์ติชัน `/data` ขนาด 25 GB)
* **ระบบปฏิบัติการ:** Android `8.0.0` Oreo (SDK `26`) | Samsung Experience `9.0` (`SEP 90000`)
* **Firmware Build / CSC:** `G935FXXU8EVG3` (Security Patch `2020-09-01`, CSC: `THL` ประเทศไทย)

---

## 2. ตารางเปรียบเทียบเชิงลึก 4 รุ่น: Samsung vs Redmi 5A vs Redmi 7A vs realme 5s

| หัวข้อการทดสอบ | Samsung (`SM-G935F` / Android 8.0) | Xiaomi Redmi 5A (MIUI 11 / Android 8.1) | Xiaomi Redmi 7A (MIUI 11 / Android 9) | realme 5s (ColorOS 7 / Android 10) |
|---|---|---|---|---|
| **Codename / SoC** | `hero2lte` / Exynos 8890 | `riva` / Snapdragon 425 | `pine` / Snapdragon 439 | `RMX1925` / Snapdragon 665 |
| **Animation Scale ผ่าน ADB** | ✅ **ปรับได้ทันที (`0.5x`)** ผ่าน `settings put global` โดยไม่ติด SecurityException | ⚠️ ติด `WRITE_SECURE_SETTINGS` หากไม่ได้เปิดสวิตช์ Security settings | ✅ **ปรับได้ทันที** ผ่าน `settings put global` | ❌ **ถูกบล็อกถาวร** ต้องปรับผ่านหน้าจอ Developer Options |
| **คำสั่ง `cmd package bg-dexopt-job`** | ✅ **ทำงานสำเร็จ 100%** บน Android 8.0 | ✅ **ทำงานสำเร็จ 100%** บน Android 8.1 | ❌ **ล้มเหลว** ติด `SecurityException: UPDATE_DEVICE_STATS` | ✅ **ทำงานสำเร็จ** (`Success`) |
| **ตัวจำกัดความเร็วเกม (Throttler)** | `com.enhance.gameservice` (**GOS**) | `com.xiaomi.joyose` (**Joyose**) | `com.xiaomi.joyose` (**Joyose**) | `com.coloros.gamespace` |
| **ระบบโฆษณา / หน้าปัดฟีดซ้ายสุด** | `com.sec.spp.push`, `briefing`, `flipboard.boxer.app`, `YahooEdge` | `com.miui.msa.global`, `globalminusscreen` (App Vault), `hybrid` | `com.miui.msa.global`, `fashiongallery`, `hybrid` | `com.heytap.pictorial`, `com.nearme.atlas` |
| **เอนจินสแกนไวรัสเบื้องหลัง** | `com.samsung.android.sm.devicesecurity` (McAfee) | `com.miui.guardprovider` (Avast/AVL) | `com.miui.guardprovider` (Avast/AVL) | `com.coloros.safecenter` |
| **RAM ที่ได้คืนหลัง Tune (`MemAvailable`)** | **+571.61 MB** (`1.59 GB` ➔ `2.15 GB`) | **+111.61 MB** (`632 MB` ➔ `744 MB`) | **+111.82 MB** (`751 MB` ➔ `864 MB`) | **+220+ MB** |
| **พื้นที่ `/data` ที่ได้คืนหลัง Tune** | **+1.15 GB** (`3.6 GB` ➔ `4.8 GB`) | **+42.66 MB** (`266 MB` ➔ `308 MB`) | - | - |

---

## 3. ผลการสแกนและค้นหา Bloatware บนเครื่องจริง (Actual Device Audit)

### 3.1 สภาพแวดล้อมเครื่องที่สแกนจริง (Before Snapshot)
* **Device Serial:** `ce01171125a0521102`
* **Model / Codename:** `samsung SM-G935F` (`hero2lte`)
* **จำนวนแพ็กเกจทั้งหมดในระบบ:** **352 แพ็กเกจ**
* **แพ็กเกจที่ถูก Disable อยู่ก่อนเริ่ม (6 แพ็กเกจ):**
  * `com.android.calendar`, `com.google.android.webview`, `com.samsung.android.dlp.service`, `com.samsung.android.sm`, `com.samsung.upsmtheme`, `com.sec.android.emergencylauncher`

---

### 3.2 การจับคู่เซอร์วิสเทียบเท่า (Xiaomi MIUI vs Samsung Experience / One UI)

| ประเภทเซอร์วิส | บน Xiaomi (MIUI) | บน Samsung (`SM-G935F`) ที่ตรวจพบและสั่ง Freeze |
|---|---|---|
| **Game Throttler & Telemetry** | `com.xiaomi.joyose` | `com.enhance.gameservice` (**Game Optimizing Service - GOS**), `com.samsung.android.game.gamehome`, `com.samsung.android.game.gametools` |
| **System Analytics & Tracking** | `com.miui.analytics`, `com.miui.daemon` | `com.sec.android.diagmonagent` (**DiagMonAgent**), `com.samsung.android.rubin.app` (**Customization Service**), `com.samsung.android.providers.context`, `com.samsung.android.intelligenceservice2`, `com.sec.modem.settings` (**SilentLog**) |
| **Ad Push & Minus-One Feed** | `com.miui.msa.global`, `com.mi.android.globalminusscreen` | `com.sec.spp.push` (**Samsung Push Service**), `com.samsung.android.widgetapp.briefing` (**Briefing Panel**), `flipboard.boxer.app`, `com.samsung.privilege` (**Galaxy Gift**), `YahooEdge` (3 ตัว) |
| **Background Antivirus Scanner** | `com.miui.guardprovider` | `com.samsung.android.sm.devicesecurity` (**SmartManager Device Security / McAfee**) |
| **Background IoT / Casting Scan** | `com.milink.service`, `com.xiaomi.mi_connect_service` | `com.samsung.android.beaconmanager` (**BeaconManager**), `com.samsung.android.easysetup` (**EasySetup**), `com.samsung.android.app.withtv` |

---

### 3.3 รายการ Bloatware / Telemetry ทั้ง 49 รายการพร้อมพาธ APK จริง

| ลำดับ | หมวดหมู่ | Package Name | พาธไฟล์ APK บนเครื่องจริง | RAM ที่กินก่อนปิด (PSS) | สถานะการ Freeze |
|---|---|---|---|---|---|
| 1 | Telemetry / Analytics | `com.sec.android.diagmonagent` | `/system/priv-app/DiagMonAgent/DiagMonAgent.apk` | รันเบื้องหลัง | ✅ `disabled-user` |
| 2 | Ad Customization | `com.samsung.android.rubin.app` | `/system/priv-app/RubinVersion20/RubinVersion20.apk` | รันเบื้องหลัง | ✅ `disabled-user` |
| 3 | Context Tracking | `com.samsung.android.providers.context` | `/system/priv-app/ContextProvider/ContextProvider.apk` | `8,867 KB` (PID 5023) | ✅ `disabled-user` |
| 4 | Behavior Engine | `com.samsung.android.intelligenceservice2` | `/system/priv-app/intelligenceservice2/intelligenceservice2.apk` | รันเบื้องหลัง | ✅ `disabled-user` |
| 5 | Security Logger | `com.samsung.android.securitylogagent` | `/system/app/SecurityLogAgent/SecurityLogAgent.apk` | รันเบื้องหลัง | ✅ `disabled-user` |
| 6 | Modem Logger | `com.sec.modem.settings` | `/system/app/SilentLog/SilentLog.apk` | รันเบื้องหลัง | ✅ `disabled-user` |
| 7 | VoLTE/IMS Logger | `com.sec.imslogger` | `/system/priv-app/ImsLogger/ImsLogger.apk` | รันเบื้องหลัง | ✅ `disabled-user` |
| 8 | Service Agent | `com.samsung.android.svcagent` | `/system/priv-app/SVCAgent/SVCAgent.apk` | รันเบื้องหลัง | ✅ `disabled-user` |
| 9 | Tracking Agent | `com.sec.android.soagent` | `/system/priv-app/SOAgent/SOAgent.apk` | รันเบื้องหลัง | ✅ `disabled-user` |
| 10 | Crash Report | `com.google.android.feedback` | `/system/priv-app/GoogleFeedback/GoogleFeedback.apk` | ทำงานเมื่อเกิด Crash | ✅ `disabled-user` |
| 11 | Marketing Push | `com.sec.spp.push` | `/data/app/com.sec.spp.push-.../base.apk` | **`17,705 KB`** (PID 11378) | ✅ `disabled-user` |
| 12 | Home Briefing Feed | `com.samsung.android.widgetapp.briefing` | `/system/app/BriefingPanel/BriefingPanel.apk` | **`14,895 KB`** (PID 5106) | ✅ `disabled-user` |
| 13 | Flipboard Feed | `flipboard.boxer.app` | `/data/app/flipboard.boxer.app-.../base.apk` | ผูกกับ Briefing | ✅ `disabled-user` |
| 14 | Promo / Ads App | `com.samsung.privilege` | `/data/app/com.samsung.privilege-.../base.apk` | Galaxy Gift | ✅ `disabled-user` |
| 15 | Edge Ad Widget | `com.samsung.android.widgetapp.yahooedge.finance` | `/system/app/YahooEdgeFinance/YahooEdgeFinance.apk` | วิตเจ็ตขอบจอ | ✅ `disabled-user` |
| 16 | Edge Ad Widget | `com.samsung.android.widgetapp.yahooedge.news` | `/system/app/YahooEdgeNews/YahooEdgeNews.apk` | วิตเจ็ตขอบจอ | ✅ `disabled-user` |
| 17 | Edge Ad Widget | `com.samsung.android.widgetapp.yahooedge.sport` | `/system/app/YahooEdgeSports/YahooEdgeSports.apk` | วิตเจ็ตขอบจอ | ✅ `disabled-user` |
| 18 | 3rd-Party Caller ID | `com.hiya.star` | `/system/app/HiyaService/HiyaService.apk` | ซิงก์เบอร์โทร Hiya | ✅ `disabled-user` |
| 19 | Game Throttler (GOS) | `com.enhance.gameservice` | `/system/app/GameOptimizer/GameOptimizer.apk` | `5,873 KB` (PID 11989) | ✅ `disabled-user` |
| 20 | Game Launcher | `com.samsung.android.game.gamehome` | `/system/priv-app/GameHome/GameHome.apk` | ศูนย์เกมพ่วงโฆษณา | ✅ `disabled-user` |
| 21 | Game Tools | `com.samsung.android.game.gametools` | `/system/priv-app/GameTools/GameTools.apk` | ปุ่มลอยในเกม | ✅ `disabled-user` |
| 22 | Enhance Service | `com.samsung.enhanceservice` | `/system/priv-app/EnhanceService/EnhanceService.apk` | เซอร์วิสเสริม | ✅ `disabled-user` |
| 23 | Facebook Tracker | `com.facebook.appmanager` | `/system/app/FBAppManager_NS/FBAppManager_NS.apk` | อัปเดต FB เบื้องหลัง | ✅ `disabled-user` |
| 24 | Facebook Telemetry | `com.facebook.services` | `/system/priv-app/FBServices/FBServices.apk` | ซิงก์ข้อมูล FB | ✅ `disabled-user` |
| 25 | Facebook Installer | `com.facebook.system` | `/system/priv-app/FBInstaller_NS/FBInstaller_NS.apk` | ตัวติดตั้งระดับระบบ | ✅ `disabled-user` |
| 26 | Antivirus Scanner | `com.samsung.android.sm.devicesecurity` | `/system/priv-app/SmartManager_v6_DeviceSecurity/...apk` | `5,868 KB` (PID 11859) | ✅ `disabled-user` |
| 27–37 | Legacy S Voice (11 ตัว) | `com.samsung.voiceserviceplatform`, `svoice`, `voicewakeup`, `svoice.sync`, `com.sec.svoice.lang.*` (7 ภาษา) | `/system/priv-app/SVoice*/...apk` | ยุติบริการแล้ว | ✅ `disabled-user` |
| 38–42 | VR / IoT / Beaming | `com.samsung.android.hmt.vrsvc`, `withtv`, `beaconmanager`, `easysetup`, `com.mobeam.barcodeService` | `/system/priv-app/...` | สแกน Beacon/VR | ✅ `disabled-user` |
| 43–46 | ANT+ Fitness (4 ตัว) | `com.dsi.ant.server`, `service.socket`, `plugins.antplus`, `sample.acquirechannels` | `/system/app/Ant*` & `/data/app/...` | บริการ ANT+ | ✅ `disabled-user` |
| 47–49 | Office Stubs (3 ตัว) | `com.microsoft.office.word`, `excel`, `powerpoint` | `/system/priv-app/*_SamsungStub/...apk` | Stub ติดตั้งแอป | ✅ `disabled-user` |

---

### 3.4 ผลการทดสอบ Freeze, Animation Scale และ ART Compilation
* **สั่ง Freeze สำเร็จใหม่เพิ่ม:** **49 แพ็กเกจ** (`new state: disabled-user`)
* **รวมแพ็กเกจที่ถูกปิดใช้งานทั้งหมดบนเครื่อง:** **55 แพ็กเกจ**
* **การตรวจสอบสถานะ Process ด้วย `dumpsys meminfo <package>`:**
  ```text
  No process found for: com.sec.spp.push
  No process found for: com.samsung.android.widgetapp.briefing
  No process found for: com.enhance.gameservice
  No process found for: com.samsung.android.sm.devicesecurity
  No process found for: com.sec.android.diagmonagent
  No process found for: com.samsung.android.rubin.app
  ```
* **การตั้งค่า Animation Scale (`0.5x`):**
  * รันคำสั่ง `settings put global window_animation_scale 0.5`, `transition_animation_scale 0.5`, และ `animator_duration_scale 0.5` **สำเร็จทันทีโดยไม่ติด SecurityException**
* **การรัน `cmd package bg-dexopt-job`:**
  * ทำงานสำเร็จสมบูรณ์บน Android 8.0 Oreo โดยไม่มีข้อผิดพลาด

---

### 3.5 สรุปผลเปรียบเทียบก่อนและหลังทำ (Before vs After: RAM, Swap & Disk Space)

#### 📊 1. ตารางเปรียบเทียบหน่วยความจำ (RAM & Swap Comparison)

| ตัวชี้วัด (Metric) | ก่อนทำ (Before Freeze) | หลังทำ (After Freeze & Clean) | ผลต่าง (Improvement) |
|---|---|---|---|
| **Total Physical RAM (`MemTotal`)** | `3,622,724 kB` (~3.45 GB) | `3,622,724 kB` (~3.45 GB) | เท่าเดิม (ฮาร์ดแวร์ 4 GB) |
| **Available RAM (`MemAvailable`)** | `1,666,676 kB` (~1.59 GB) | **`2,252,000 kB` (~2.15 GB)** | 📈 **เพิ่มขึ้น +585,324 kB (+571.61 MB / +35.1%!)** |
| **Pure Free RAM (`MemFree`)** | `94,432 kB` (~92.2 MB) | **`562,216 kB` (~549.0 MB)** | 🚀 **เพิ่มขึ้น +467,784 kB (+456.82 MB / เพิ่มขึ้น 5.95 เท่า!)** |
| **Active Anonymous Heap (`Active(anon)`)** | `342,372 kB` (~334.3 MB) | **`208,808 kB` (~203.9 MB)** | 📉 **ลดภาระ Active Heap ลง -133,564 kB (-130.43 MB / -39.0%)** |
| **Inactive Anonymous Heap (`Inactive(anon)`)** | `359,612 kB` (~351.2 MB) | **`171,664 kB` (~167.6 MB)** | 📉 **ลดลง -187,948 kB (-183.54 MB / -52.3%)** |
| **`.dex mmap` (`dumpsys meminfo`)** | `595,716 K` (~581.8 MB) | **`310,028 K` (~302.8 MB)** | 📉 **ลดการแมปไฟล์โค้ด `.dex` ลง -285,688 K (-278.99 MB)** |
| **`Dalvik` + `Dalvik Other` + `Native`** | `613,786 K` (~599.4 MB) | **`320,572 K` (~313.1 MB)** | 📉 **ลดลง -293,214 K (-286.34 MB)** |
| **Free RAM รวม (`dumpsys meminfo`)** | `1,754,690 K` (~1.67 GB) | **`1,850,903 K` (~1.77 GB)** | 📈 **เพิ่มขึ้น +96,213 K (+93.96 MB)** |
| **Lost RAM (`dumpsys meminfo`)** | `451,489 K` (~440.9 MB) | **`252,323 K` (~246.4 MB)** | 📉 **กู้คืน Lost RAM ได้ -199,166 K (-194.50 MB)** |
| **Swap ที่ถูกใช้งาน (`SwapTotal - SwapFree`)** | `855,228 kB` (~835.2 MB) | **`699,952 kB` (~683.5 MB)** | 📉 **ลดภาระ Swap ลง -155,276 kB (-151.64 MB / -18.2%)** |

#### 💾 2. ตารางเปรียบเทียบพื้นที่จัดเก็บข้อมูล (Disk Space `/data` Comparison)

| พาร์ติชัน (Partition) | ก่อนทำ (Before) | หลังทำ (After Freeze + Trim Cache) | พื้นที่ที่ได้คืน (Disk Saved) |
|---|---|---|---|
| **`/data` (Used Space)** | `21,967,272 KB` (`21.0 GB`) | **`20,762,464 KB` (`19.8 GB`)** | 📉 **ลดพื้นที่ใช้งานลง -1,204,808 KB (-1.15 GB!)** |
| **`/data` (Available Free Space)** | `3,869,560 KB` (**`3.6 GB`**) | **`5,074,368 KB` (`4.8 GB`)** | 📈 **ได้พื้นที่ว่างเพิ่มขึ้น +1,204,808 KB (+1.15 GB / +31.1%!)** |
| **`/data` (Use %)** | `86%` | ✅ **`81%`** | ลดอัตราการใช้พื้นที่ลง 5% ทันที |
| **`/system`** | `4,128,816 KB` / ว่าง `167 MB` (`97%`) | `4,128,816 KB` / ว่าง `167 MB` (`97%`) | คงเดิม (Read-Only System Partition) |
| **`/cache`** | `11,480 KB` / ว่าง `182 MB` (`6%`) | `11,480 KB` / ว่าง `182 MB` (`6%`) | คงเดิม |

---

## 4. สิ่งที่ต้องเตรียมก่อนเริ่มใช้งาน

1. ติดตั้ง **ADB (Android Platform Tools)** บนคอมพิวเตอร์ (`brew install android-platform-tools`)
2. บนเครื่อง Samsung ไปที่ **Settings** > **About phone** > **Software information** > แตะ **Build number** 7 ครั้งเพื่อเปิด **Developer options**
3. เข้าไปที่ **Developer options** แล้วเปิดสวิตช์ **USB debugging**
4. เสียบสาย USB และกด **Allow** บนหน้าจอมือถือ

---

## 5. การเริ่มใช้งานสคริปต์ (Quick Start)

สคริปต์ [**`tune-samsung-s7edge.sh`**](file:///Users/billy/git/Python-Utility/tune-samsung-s7edge.sh) พร้อมใช้งานได้ทันที:

```bash
chmod +x tune-samsung-s7edge.sh
./tune-samsung-s7edge.sh
```

---

## 6. รายละเอียดการทำงานของแต่ละเมนูในสคริปต์

### เมนู 1: 📱 ตรวจสอบสถานะเครื่อง & ทรัพยากรระบบ
* แสดงข้อมูล SoC (`samsungexynos8890`), Codename (`hero2lte`), Security Patch, Firmware Build และ CSC
* แสดงสถานะ RAM (`MemTotal`, `MemFree`, `MemAvailable`, `Active(anon)`, `Inactive(anon)`, `SwapTotal`, `SwapFree`)
* แสดงพื้นที่ว่างในพาร์ติชัน `/data`, `/system`, `/cache`
* แสดงสถานะแบตเตอรี่ และจำนวนแพ็กเกจที่ถูก Freeze อยู่ปัจจุบัน

### เมนู 2: ⚡ ปรับความเร็ว Animation Scale
* ปรับค่า `window_animation_scale`, `transition_animation_scale`, และ `animator_duration_scale` เป็น `0.5x` (แนะนำ), `1.0x`, หรือ `0.0x` ได้ทันทีผ่าน ADB

### เมนู 3: 🛡️ Freeze Bloatware & Telemetry (49 รายการ)
* ใช้คำสั่ง `pm disable-user --user 0` ร่วมกับ `am force-stop`
* แบ่งออกเป็น 5 หมวดหมู่หลัก สามารถเลือก Freeze ทั้งหมด 49 รายการ, เลือกเฉพาะหมวดหมู่ หรือเลือกทีละแพ็กเกจได้

### เมนู 4: 🔄 Unfreeze / Rollback คืนค่าแอป
* กู้คืนแพ็กเกจที่ถูก Freeze กลับมาทำงานปกติด้วยคำสั่ง `pm enable <package>` ทั้งแบบคืนค่าทั้งหมดและเลือกเฉพาะตัว

### เมนู 5: 🚀 ART Runtime Compilation
* รองรับทั้ง `cmd package bg-dexopt-job`, `cmd package compile -m speed-profile -a`, และ `cmd package compile -m speed -a`

### เมนู 6: 🛑 Force Stop แอปชั่วคราว & ล้างแคชระบบ (Trim Caches)
* สั่งหยุดแอปโซเชียล/สตรีมมิงที่กินแรมสูงชั่วคราว (`am force-stop` + `am kill-all`)
* มีตัวเลือก **`T) ล้างไฟล์แคชระบบทั้งหมด (pm trim-caches 999G)`** เพื่อกู้คืนพื้นที่ว่างใน `/data`

### เมนู 7: 📋 ดูรายการแอปที่ถูก Freeze อยู่ปัจจุบัน
* แสดงรายชื่อแพ็กเกจทั้งหมดที่อยู่ในสถานะ `disabled` เรียงตามตัวอักษร

### เมนู 8: 💾 บันทึก Snapshot ข้อมูลเครื่อง
* สำรองข้อมูล `getprop`, `meminfo`, `df -h`, รายชื่อแพ็กเกจทั้งหมด และรายชื่อแพ็กเกจที่ถูกปิด เก็บไว้ที่ `~/.samsung_tuning/snapshot_YYYYMMDD_HHMMSS/`

---

## 7. ฐานข้อมูลแพ็กเกจที่ถูก Freeze (49 รายการ)

### หมวด 1: Samsung Telemetry, Analytics & Diagnostic Loggers (10 รายการ)
1. `com.sec.android.diagmonagent` — DiagMonAgent (ส่งสถิติและรายงานวิเคราะห์ระบบกลับเซิร์ฟเวอร์ Samsung)
2. `com.samsung.android.rubin.app` — Customization Service / Rubin (ติดตามพฤติกรรมและสถานที่ผู้ใช้)
3. `com.samsung.android.providers.context` — ContextProvider (ดักเก็บบริบทการใช้งานแอปเบื้องหลัง)
4. `com.samsung.android.intelligenceservice2` — Intelligence Service 2
5. `com.samsung.android.securitylogagent` — SecurityLogAgent
6. `com.sec.modem.settings` — SilentLog (ดักเก็บล็อกโมเด็มเงียบๆ เบื้องหลัง)
7. `com.sec.imslogger` — IMS Logger
8. `com.samsung.android.svcagent` — Samsung SVC Agent
9. `com.sec.android.soagent` — Software Tracking Agent (SOAgent)
10. `com.google.android.feedback` — Google Feedback

### หมวด 2: Home Screen Briefing, Flipboard, Marketing Push & Edge Ads (8 รายการ)
11. `com.sec.spp.push` — Samsung Push Service (ยิงโฆษณาและการตลาดเบื้องหลัง)
12. `com.samsung.android.widgetapp.briefing` — Briefing Panel (หน้าปัดฟีดข่าว/โฆษณาซ้ายสุดของหน้าจอโฮม)
13. `flipboard.boxer.app` — Flipboard Briefing
14. `com.samsung.privilege` — Galaxy Gift / Samsung Privilege
15. `com.samsung.android.widgetapp.yahooedge.finance` — Yahoo Finance Edge
16. `com.samsung.android.widgetapp.yahooedge.news` — Yahoo News Edge
17. `com.samsung.android.widgetapp.yahooedge.sport` — Yahoo Sports Edge
18. `com.hiya.star` — Hiya Caller ID Service

### หมวด 3: Game Throttler (GOS) & Game Bloatware (4 รายการ)
19. `com.enhance.gameservice` — Game Optimizing Service (GOS - ตัวจำกัดความเร็ว CPU/GPU ขณะเล่นเกม)
20. `com.samsung.android.game.gamehome` — Samsung Game Launcher
21. `com.samsung.android.game.gametools` — Samsung Game Tools
22. `com.samsung.enhanceservice` — Samsung Enhance Service

### หมวด 4: Facebook Pre-installed Trackers & Antivirus Scanner (4 รายการ)
23. `com.facebook.appmanager` — Facebook App Manager
24. `com.facebook.services` — Facebook Services
25. `com.facebook.system` — Facebook System Installer
26. `com.samsung.android.sm.devicesecurity` — SmartManager Device Security (McAfee Scanner)

### หมวด 5: Legacy S Voice, Gear VR, IoT Beacon, ANT+ & Office Stubs (23 รายการ)
27. `com.samsung.voiceserviceplatform` — S Voice Platform
28. `com.samsung.android.svoice` — Voice Service Framework
29. `com.samsung.android.voicewakeup` — S Voice WakeUp
30. `com.samsung.svoice.sync` — S Voice Sync (SVoicePLM)
31–37. `com.sec.svoice.lang.en_GB`, `en_US`, `fr_FR`, `de_DE`, `it_IT`, `ru_RU`, `es_ES` — ชุดภาษา S Voice 7 ภาษา
38. `com.samsung.android.hmt.vrsvc` — Gear VR Service
39. `com.samsung.android.app.withtv` — Samsung withTV
40. `com.samsung.android.beaconmanager` — Samsung BeaconManager
41. `com.samsung.android.easysetup` — Samsung EasySetup
42. `com.mobeam.barcodeService` — Mobeam Barcode Beaming Service
43–46. `com.dsi.ant.server`, `com.dsi.ant.service.socket`, `com.dsi.ant.plugins.antplus`, `com.dsi.ant.sample.acquirechannels` — ชุดบริการเซนเซอร์ ANT+
47–49. `com.microsoft.office.word`, `com.microsoft.office.excel`, `com.microsoft.office.powerpoint` — ชุด Stub ติดตั้งแอป Microsoft Office

---

## 8. ไดเรกทอรีบันทึกข้อมูลและประวัติการทำงาน

* **ตำแหน่งหลัก:** `~/.samsung_tuning/`
* **ไฟล์ประวัติ:** `~/.samsung_tuning/tuning_history.log`
* **โฟลเดอร์ Snapshot:** `~/.samsung_tuning/snapshot_YYYYMMDD_HHMMSS/`

---

## 9. การแก้ไขปัญหาและคำถามที่พบบ่อย (FAQ)

### Q1: ปิด `com.sec.spp.push` (Samsung Push Service) แล้วแจ้งเตือน LINE, WhatsApp, Gmail จะหายไหม?
> **คำตอบ:** ไม่หายครับ แอปแชตและโซเชียลทั้งหมดใช้ **Google Firebase Cloud Messaging (FCM / GMS)** ในการรับแจ้งเตือน ส่วน `com.sec.spp.push` เป็นเพียงเซอร์วิสยิงข้อความการตลาดและโปรโมชันของแอปตระกูล Samsung เท่านั้น

### Q2: ปิด `com.enhance.gameservice` (GOS) มีผลดีอย่างไร?
> **คำตอบ:** GOS (Game Optimizing Service) ของ Samsung มีพฤติกรรมเดียวกับ Joyose บน Xiaomi คือคอยดักตรวจรายชื่อแอปเกมแล้วบังคับลดความเร็วคล็อก CPU/GPU และลดความละเอียดหน้าจอ การ Freeze GOS ช่วยให้ชิป Exynos 8890 และ GPU Mali-T880 ทำงานได้เต็มประสิทธิภาพโดยไม่ถูกบีบความเร็ว

### Q3: ทำไมเราไม่ควรสั่ง Freeze `com.samsung.android.lool` (Smart Manager / Device Maintenance)?
> **คำตอบ:** บนรอม Samsung Experience 9.0 แพ็กเกจ `com.samsung.android.lool` คือหน้าเมนู **Device maintenance (การดูแลอุปกรณ์ & แบตเตอรี่)** ในหน้า Settings หากปิดตัวนี้จะทำให้กดเข้าเมนูตั้งค่าแบตเตอรี่ใน Settings แล้วเด้งออก ดังนั้นสคริปต์จึงเลือกปิดเฉพาะโมดูลสแกนไวรัส McAfee (`com.samsung.android.sm.devicesecurity`) เพื่อให้หน้าตั้งค่าแบตเตอรี่ยังใช้งานได้สมบูรณ์ 100%

---

## 10. ตารางคำสั่ง ADB ฉบับย่อ (Quick Reference)

| งานที่ต้องการทำ | คำสั่ง ADB |
|---|---|
| ตรวจสอบอุปกรณ์ที่เชื่อมต่อ | `adb devices` |
| ดูสถานะ RAM ปัจจุบัน | `adb shell head -n 18 /proc/meminfo` |
| ดูพื้นที่ว่าง `/data` | `adb shell df -h /data` |
| ล้างแคชระบบทั้งหมดเพื่อคืนพื้นที่ | `adb shell pm trim-caches 999G` |
| สั่ง Freeze แอปแบบปลอดภัย | `adb shell pm disable-user --user 0 <package_name>` |
| สั่งเปิดใช้งานแอปคืน (Unfreeze) | `adb shell pm enable <package_name>` |
| ดูรายชื่อแอปที่ถูก Freeze ทั้งหมด | `adb shell pm list packages -d` |
| ปรับ Animation Scale เป็น 0.5x | `adb shell settings put global window_animation_scale 0.5` |
| รัน Background DEX Optimization | `adb shell cmd package bg-dexopt-job` |


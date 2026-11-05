# Tuning Android Phone
คู่มือปรับแต่ง Android ผ่าน ADB โดยไม่ Root

> เป้าหมาย: ตรวจสอบเครื่อง ปรับความเร็วแอนิเมชัน จัดการแอปที่ไม่ต้องการ และตรวจสอบผลผ่าน ADB  
> ตัวอย่างเครื่องที่ใช้ประกอบ: **realme 5s (RMX1925)** แต่คำสั่งบางส่วนใช้ได้กับ Android รุ่นอื่นด้วย  
> **ข้อสำคัญ:** Android แต่ละยี่ห้อ/เวอร์ชันมีข้อจำกัดต่างกัน คำสั่งบางรายการอาจถูกปฏิเสธหรือไม่มีผล อย่ารันคำสั่งเป็นชุดโดยไม่ตรวจสอบแพ็กเกจและผลลัพธ์ก่อน

---

## 1. เตรียมเครื่องมือ

### 1.1 ติดตั้ง Android Platform Tools

macOS (Homebrew):

```bash
brew install android-platform-tools
```

Windows / Linux: ดาวน์โหลด Android SDK Platform-Tools จาก Google  
<https://developer.android.com/tools/releases/platform-tools>

ตรวจสอบ:

```bash
adb version
```

### 1.2 เปิด Developer options และ USB debugging

1. เปิด Settings > About phone
2. แตะ Build number หรือ Version number ประมาณ 7 ครั้ง (ชื่อเมนูขึ้นกับยี่ห้อ)
3. กลับไป Settings > Additional settings / System > Developer options
4. เปิด **USB debugging**
5. ต่อโทรศัพท์กับคอมพิวเตอร์ด้วยสาย USB
6. ปลดล็อกหน้าจอและกด **Allow** ที่หน้าต่าง RSA fingerprint บนโทรศัพท์

> ไม่จำเป็นต้องเปิด USB debugging (Security settings) ของ Xiaomi/POCO เว้นแต่มีเหตุจำเป็นเฉพาะ และไม่ควรนำขั้นตอนของ Xiaomi ไปใช้กับ realme หรือ Samsung

### 1.3 ตรวจสอบการเชื่อมต่อ

```bash
adb devices
```

สถานะที่ควรเห็น:

```text
List of devices attached
XXXXXXXX    device
```

ความหมายของสถานะที่พบบ่อย:

- `device` — เชื่อมต่อและอนุญาตแล้ว
- `unauthorized` — ปลดล็อกโทรศัพท์แล้วกดยอมรับ USB debugging
- `offline` — ถอด/เสียบสายใหม่ แล้วลอง `adb kill-server` และ `adb start-server`
- ไม่พบอุปกรณ์ — ตรวจสาย USB, พอร์ต, USB mode และ driver (Windows)

คำสั่งช่วยเชื่อมต่อใหม่:

```bash
adb kill-server
adb start-server
adb devices
```

---

## 2. ตรวจสอบข้อมูลเครื่องก่อนปรับแต่ง

```bash
# รุ่นอุปกรณ์
adb shell getprop ro.product.model

# ชื่อผู้ผลิต
adb shell getprop ro.product.manufacturer

# เวอร์ชัน Android
adb shell getprop ro.build.version.release

# ระดับ API
adb shell getprop ro.build.version.sdk

# เวอร์ชัน Build
adb shell getprop ro.build.display.id

# หน่วยความจำ
adb shell cat /proc/meminfo

# พื้นที่เก็บข้อมูล
adb shell df -h /data

# รายชื่อแอปที่ผู้ใช้ติดตั้ง
adb shell pm list packages -3
```

บันทึกข้อมูลเครื่องลงไฟล์บนคอมพิวเตอร์:

```bash
adb shell getprop > android-getprop.txt
adb shell cat /proc/meminfo > android-meminfo.txt
adb shell df -h > android-storage.txt
adb shell pm list packages -3 > android-third-party-packages.txt
```

---

## 3. ปรับ Animation scale ให้หน้าจอตอบสนองไวขึ้น

ลดเวลาแสดงเอฟเฟกต์เปิด/ปิดหน้าต่างและแอปเป็น 0.5x:

```bash
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
```

ตรวจสอบค่าปัจจุบัน:

```bash
adb shell settings get global window_animation_scale
adb shell settings get global transition_animation_scale
adb shell settings get global animator_duration_scale
```

คืนค่าเริ่มต้น 1x:

```bash
adb shell settings put global window_animation_scale 1
adb shell settings put global transition_animation_scale 1
adb shell settings put global animator_duration_scale 1
```

ปิดแอนิเมชันทั้งหมด (0x):

```bash
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
```

**ข้อจำกัดที่พบกับ realme บาง ROM:** คำสั่ง `settings put global` อาจตอบกลับ:

```text
Security exception: Permission denial: writing to settings requires:
android.permission.WRITE_SECURE_SETTINGS
```

หากพบข้อความนี้ แปลว่า shell บน ROM ไม่ได้รับสิทธิ์เขียนค่าดังกล่าว อย่าพยายาม Root เครื่องหรือให้สิทธิ์แบบสุ่ม ให้ตั้งค่าจากหน้าจอโทรศัพท์แทน:

1. Settings > Additional settings > Developer options
2. ตั้ง Window animation scale = 0.5x
3. ตั้ง Transition animation scale = 0.5x
4. ตั้ง Animator duration scale = 0.5x

เปิดหน้า Developer options ผ่าน ADB ได้ในบางรุ่น:

```bash
adb shell am start -a android.settings.APPLICATION_DEVELOPMENT_SETTINGS
```

การลด Animation ทำให้เอฟเฟกต์สั้นลง ไม่ได้เพิ่มความเร็ว CPU หรือ RAM จริง

---

## 4. ตรวจสอบแอปและ Package

แสดงแอปที่ผู้ใช้ติดตั้ง:

```bash
adb shell pm list packages -3
```

ค้นหา package ตามคำ:

```bash
adb shell pm list packages | grep -i facebook
adb shell pm list packages | grep -i google
adb shell pm list packages | grep -i realme
```

Windows Command Prompt ใช้ `findstr` แทน `grep`:

```bat
adb shell pm list packages | findstr /i facebook
```

ดูรายละเอียด package:

```bash
adb shell dumpsys package PACKAGE.NAME
```

ตัวอย่าง:

```bash
adb shell dumpsys package com.facebook.katana
```

> Package name เป็นตัวระบุแอปจริง อย่าคาดเดาจากชื่อแอป และอย่าปิด package ที่ไม่ทราบหน้าที่

---

## 5. Force-stop แอปที่ไม่ต้องการให้ทำงานชั่วคราว

`force-stop` เป็นการหยุดแอปในขณะนั้น ไม่ได้ถอนการติดตั้งและไม่ลบข้อมูล เมื่อเปิดแอปอีกครั้งก็ทำงานได้ตามปกติ

ตัวอย่าง package ที่พบบ่อย (ใช้เฉพาะเมื่อมีติดตั้งจริง):

```bash
adb shell am force-stop com.facebook.katana
adb shell am force-stop com.facebook.orca
adb shell am force-stop com.instagram.android
adb shell am force-stop com.zhiliaoapp.musically
adb shell am force-stop com.google.android.gm
adb shell am force-stop com.microsoft.office.outlook
```

ตรวจสอบการใช้หน่วยความจำของแอป:

```bash
adb shell dumpsys meminfo
adb shell dumpsys meminfo com.facebook.katana
```

ข้อควรทราบ:
- การ Force-stop ไม่ได้แปลว่าจะคืน RAM ได้ตามจำนวนที่คาดการณ์
- ระบบ Android อาจจัดการ RAM ใหม่โดยอัตโนมัติ
- ไม่ควร Force-stop แอปโทรศัพท์, launcher, system UI, Settings, keyboard, accessibility หรือบริการแจ้งเตือนที่จำเป็น

---

## 6. Disable แอปที่ไม่ต้องการ (ปิดใช้งานแบบย้อนกลับได้)

คำสั่งนี้ปิด package สำหรับผู้ใช้ปัจจุบัน ไม่ใช่การลบไฟล์ระบบ:

```bash
adb shell pm disable-user --user 0 PACKAGE.NAME
```

เปิดใช้งานกลับ:

```bash
adb shell pm enable PACKAGE.NAME
```

ตรวจสอบสถานะ package:

```bash
adb shell pm list packages -d
adb shell pm list packages -e
```

- `-d` แสดง package ที่ถูก disable
- `-e` แสดง package ที่ enabled

### 6.1 ตัวอย่าง package ของ Xiaomi / MIUI เท่านั้น

**อย่ารันรายการนี้บน realme, Samsung, OPPO หรือ Vivo** และอย่าปิดรายการใดจนกว่าจะยืนยันได้ว่า package มีอยู่และไม่ใช่ฟังก์ชันที่ใช้งาน

```bash
# Google Ad Services (ขึ้นกับ Android/ROM)
adb shell pm disable-user --user 0 com.google.android.adservices.api

# Xiaomi / MIUI services
adb shell pm disable-user --user 0 com.miui.guardprovider
adb shell pm disable-user --user 0 com.milink.service
adb shell pm disable-user --user 0 com.milink.runtime
adb shell pm disable-user --user 0 com.miui.mishare.connectivity
adb shell pm disable-user --user 0 com.xiaomi.xmsf
adb shell pm disable-user --user 0 com.xiaomi.xmsfkeeper
adb shell pm disable-user --user 0 com.xiaomi.joyose
adb shell pm disable-user --user 0 com.miui.analytics
adb shell pm disable-user --user 0 com.miui.msa.global
adb shell pm disable-user --user 0 com.miui.daemon
```

การปิดบริการเหล่านี้อาจทำให้คุณสมบัติบางอย่าง เช่น การแชร์ไฟล์ การเชื่อมต่ออุปกรณ์ การแจ้งเตือน หรือการตรวจสอบความปลอดภัย ทำงานผิดปกติได้ ไม่ควรเหมารวมว่าเป็น bloatware ในทุกเครื่อง

### 6.2 กฎความปลอดภัยก่อน Disable

ห้ามปิด package สำคัญ เช่น:
- System UI
- Settings
- Package Installer
- System Launcher / Home app (หากไม่มี launcher สำรองที่ทดสอบแล้ว)
- โทรศัพท์, SMS, Contacts และบริการที่เกี่ยวข้อง
- Google Play services / Play Store โดยไม่เข้าใจผลกระทบ
- Keyboard, Accessibility และบริการที่ผู้ใช้ต้องพึ่งพา

แนวทางที่ปลอดภัย:
1. ตรวจสอบชื่อและหน้าที่ของ package ก่อน
2. ปิดทีละ package ไม่ปิดเป็นชุดใหญ่
3. ทดสอบโทรศัพท์, Wi-Fi, Bluetooth, กล้อง, การแจ้งเตือน และแอปธนาคาร
4. จด package ที่ปิดไว้เพื่อเปิดคืนได้

---

## 7. Android Runtime Compilation (ART)

คำสั่งจาก Android Runtime ที่ใช้ compile package:

```bash
adb shell cmd package compile -m speed -a
```

ความหมายโดยย่อ:
- `compile` — สั่งให้ Package Manager ทำ compilation
- `-m speed` — เลือก compilation mode แบบเน้นประสิทธิภาพ
- `-a` — ใช้กับ package ทั้งหมดที่เข้าเงื่อนไข

ข้อควรระวัง:
- ไม่ใช่การแปลงแอปทุกตัวเป็น native code แบบถาวรตามคำอธิบายง่าย ๆ และไม่รับประกันว่าเครื่องจะเร็วขึ้นอย่างชัดเจน
- ใช้ CPU, เวลา และพื้นที่จัดเก็บเพิ่มระหว่าง/หลังการทำงานได้
- ผลลัพธ์ขึ้นกับ Android version, ART, ROM และสถานะของแต่ละ package
- คำสั่งอาจใช้เวลานานหรือถูก ROM จำกัด
- ไม่ควรรันซ้ำบ่อย ๆ โดยไม่มีเหตุผล
- ควรเสียบชาร์จและมีพื้นที่ว่างเพียงพอ

หากต้องการดู help ของคำสั่งบนเครื่อง:

```bash
adb shell cmd package compile -h
```

หากต้องการทดลอง ให้ทำหลังสำรองข้อมูลและตรวจสอบความเข้ากันได้ของ Android รุ่นนั้นก่อน

---

## 8. ตรวจสอบ RAM และสถานะระบบ

```bash
# ภาพรวม RAM
adb shell cat /proc/meminfo

# ภาพรวมหน่วยความจำของระบบ Android
adb shell dumpsys meminfo

# ข้อมูลแบตเตอรี่
adb shell dumpsys battery

# สรุป process
adb shell ps -A
```

บันทึกผลก่อนและหลังการปรับแต่งเพื่อเปรียบเทียบ:

```bash
adb shell cat /proc/meminfo > meminfo-after.txt
adb shell dumpsys meminfo > dumpsys-meminfo-after.txt
adb shell dumpsys battery > battery-after.txt
```

ควรเปรียบเทียบภายใต้เงื่อนไขใกล้เคียงกัน เช่น แอปที่เปิดอยู่และเวลาหลังบูต เพราะ RAM ว่างเปลี่ยนแปลงตลอดเวลา

---

## 9. เปิดคืนและกู้การตั้งค่าที่เปลี่ยนไป

เปิด package กลับ:

```bash
adb shell pm enable PACKAGE.NAME
```

คืน animation เป็น 1x:

```bash
adb shell settings put global window_animation_scale 1
adb shell settings put global transition_animation_scale 1
adb shell settings put global animator_duration_scale 1
```

หากไม่ทราบว่า package ใดถูกปิด ให้ตรวจรายการ:

```bash
adb shell pm list packages -d
```

จากนั้นเปิดคืนเฉพาะ package ที่ทราบว่าเป็นรายการที่เราปิดเอง:

```bash
adb shell pm enable PACKAGE.NAME
```

การ Factory reset ไม่ใช่วิธีกู้คืนที่ควรใช้เป็นอันดับแรก เพราะจะลบข้อมูลผู้ใช้ ควรลองเปิด package คืนและปรับค่าที่เปลี่ยนก่อน และสำรองข้อมูลก่อนทำ Factory reset เสมอ

---

## 10. ลำดับการ Tuning ที่แนะนำ

1. สำรองข้อมูลสำคัญ และจดรุ่น/เวอร์ชัน Android
2. ติดตั้ง ADB และตรวจ `adb devices`
3. เก็บข้อมูลพื้นฐาน: รุ่น, Android version, RAM, storage และ package list
4. ปรับ animation ผ่าน Developer options เป็น 0.5x
5. ทดลองใช้งานจริงก่อน โดยยังไม่ Disable system package
6. Force-stop เฉพาะแอปที่ไม่ต้องการให้ทำงานชั่วคราว
7. พิจารณา Disable เฉพาะ package ที่ตรวจสอบหน้าที่แล้วและไม่จำเป็น
8. ทดลอง ART compilation เฉพาะเมื่อเข้าใจข้อจำกัดและมีเหตุผล
9. ตรวจสอบการใช้งานจริง เช่น โทรศัพท์, กล้อง, Wi-Fi, Bluetooth, แจ้งเตือน และแอปธนาคาร
10. บันทึกสิ่งที่เปลี่ยนและวิธีเปิดคืน

---

## 11. ข้อเท็จจริงที่ควรเข้าใจ

- ADB ไม่ได้ทำให้โทรศัพท์เร็วขึ้นโดยอัตโนมัติ การปรับแต่งบางอย่างอาจไม่เห็นผล
- การลด animation ทำให้ UI ดูตอบสนองเร็วขึ้น แต่ไม่ได้เพิ่มกำลังประมวลผล
- Force-stop เป็นการหยุดแอปชั่วคราว ไม่ใช่การลบแอปหรือเพิ่ม RAM ถาวร
- Disable package มีความเสี่ยงต่อฟังก์ชันที่พึ่งพากัน แม้จะเปิดกลับได้ก็ตาม
- คำสั่ง package ของ Xiaomi ใช้กับ Xiaomi/MIUI เท่านั้น ไม่ควรนำไปใช้กับ realme RMX1925
- ไม่มีวิธีรับประกันว่า “ปลอดภัย 100%” กับ Android ทุกยี่ห้อและทุก ROM
- ไม่ต้อง Root สำหรับคำสั่งพื้นฐานในคู่มือนี้ และไม่ควร Root เพียงเพื่อข้ามข้อจำกัด `WRITE_SECURE_SETTINGS`

## 12. Quick Reference

| งาน | คำสั่ง |
|---|---|
| ตรวจการเชื่อมต่อ | `adb devices` |
| ดูรุ่นเครื่อง | `adb shell getprop ro.product.model` |
| ดู Android version | `adb shell getprop ro.build.version.release` |
| ดูแอปที่ติดตั้งเอง | `adb shell pm list packages -3` |
| ดูแอปที่ถูกปิด | `adb shell pm list packages -d` |
| Force-stop แอป | `adb shell am force-stop PACKAGE.NAME` |
| Disable package | `adb shell pm disable-user --user 0 PACKAGE.NAME` |
| Enable package | `adb shell pm enable PACKAGE.NAME` |
| ดู RAM | `adb shell cat /proc/meminfo` |
| ดูรายละเอียด RAM | `adb shell dumpsys meminfo` |
| ดู help compilation | `adb shell cmd package compile -h` |

---

**หมายเหตุสำหรับ realme 5s (RMX1925):** เริ่มจากเปิด Developer options และปรับ Animation scale ด้วยมือก่อน เพราะมีรายงานในขั้นตอนทดลองว่าคำสั่ง `settings put global` ถูกปฏิเสธด้วย `WRITE_SECURE_SETTINGS` บน ROM นี้ หลีกเลี่ยงการใช้ package list ของ Xiaomi/MIUI กับเครื่อง realme และอย่า Disable package ที่ไม่ทราบหน้าที่

# VibeCheck: Where Mood Meets Metrics

**ITDS283 Section 2 Group 10**  


---

## Members

| ID | Name |
|------|------------|
| 6787039 | Thanawan Leartthanongsak |
| 6787085 | Wannisa Jitprasong |

---

## About Application

VibeCheck เป็นแอปพลิเคชันสำหรับติดตามอารมณ์และเพิ่มประสิทธิภาพการทำงาน ที่ช่วยให้ผู้ใช้เข้าใจความสัมพันธ์ระหว่างอารมณ์ สภาพอากาศ และประสิทธิภาพในชีวิตประจำวัน ผู้ใช้สามารถบันทึกอารมณ์รายวัน จัดการงาน ใช้งาน Timer ตั้งเป้าหมายรายเดือน และดู Insight เฉพาะบุคคลได้ในแอปเดียว

---

## Features

### ฟีเจอร์พื้นฐาน
- **Emotional Galaxy** — แสดงอารมณ์ในสัปดาห์ในรูปแบบดาวเคราะห์โคจรรอบดวงอาทิตย์บนหน้าหลักและหน้า Emotion
- **บันทึกอารมณ์** — บันทึกอารมณ์ประจำวัน 8 ประเภท ได้แก่ Happy, Calm, Neutral, Stressed, Love, Burnout, Angry, Sad
- **จัดการงาน (Task)** — สร้าง แก้ไข และจัดหมวดหมู่งาน พร้อมกำหนดวัน Deadline ได้
- **Timer** — จับเวลาโฟกัส 3 โหมด: Normal / Focus / Strict
- **ติดตามเป้าหมาย (Goal)** — ตั้งเป้าหมายรายเดือน พร้อมแผนรายวันและติดตามความคืบหน้า
- **Analytics & Insights** — กราฟแนวโน้มประสิทธิภาพ, ค่าสหสัมพันธ์ Pearson ระหว่างอารมณ์กับงาน, ช่วงเวลา Peak และสรุปรายสัปดาห์
- **Emotion Analytics** — ดูประวัติอารมณ์พร้อม Chart และ Breakdown

### ฟีเจอร์ขั้นสูง — Weather × Mood
- ใช้ **GPS (geolocator)** ดึง Location จริงของผู้ใช้
- เรียกข้อมูลสภาพอากาศแบบ Real-time จาก **OpenWeatherMap API**
- แสดง Weather Card บนหน้าหลัก (เมือง, อุณหภูมิ, สภาพอากาศ)
- บันทึกข้อมูลสภาพอากาศอัตโนมัติทุกครั้งที่ผู้ใช้บันทึกอารมณ์
- แสดง **ความสัมพันธ์ระหว่างสภาพอากาศและอารมณ์** ในหน้า Analytics ว่าอากาศแบบไหนทำให้รู้สึกอย่างไร

---

## วิธีติดตั้งและรัน

### ความต้องการเบื้องต้น
- Flutter SDK `^3.11.3`
- Android Studio หรือ VS Code
- Firebase project ที่เปิดใช้งาน Firestore, Auth และ Storage
- OpenWeatherMap API Key: มีการ push API ขึ้นไว้อยู่แล้วเพื่อความสะดวกในการตรวจ (สมัครที่ [openweathermap.org](https://openweathermap.org/api))

### ขั้นตอนการติดตั้ง

**1. Clone repository**
```bash
git clone https://github.com/winnietnw/ITDS283_Sec2_Group10.git
cd ITDS283_Sec2_Group10/vibecheck_app
```

**2. ติดตั้ง dependencies**
```bash
flutter pub get
```

**3. ใส่ OpenWeatherMap API Key (push API ขึ้นไว้อยู่แล้วเพื่อความสะดวกในการตรวจ สามารถข้ามขั้นตอนนี้ได้)**

เปิดไฟล์ `lib/services/weather_service.dart` แล้วแทนที่:
```dart
static const String _apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
```
ด้วย API Key จริง

**4. รันแอป**
```bash
flutter run
```

---

## 📝 หมายเหตุ

- ข้อมูลสภาพอากาศจะถูกบันทึกพร้อมกับการ Log อารมณ์ทุกครั้ง ยิ่ง Log มาก ข้อมูล Weather & Mood Insight ยิ่งแม่นยำ
- แอปต้องการ Permission ด้าน Location เพื่อแสดง Weather Card บนหน้าหลัก
- ถ้าหากขณะเทสพบเจอปัญหา เช่น กด save today's emotion แล้วไม่เกิดการเปลี่ยนหน้า โปรดติดต่อทีมผู้พัฒนา (winniehswm@gmail.com) เนื่องจาก Firestore ใน Firebase ของแอพมีการรวนบ่อยครั้งทำให้เซฟไม่ได้ (ไม่ใช่ปัญหาที่ตัวโค้ดของแอพ)
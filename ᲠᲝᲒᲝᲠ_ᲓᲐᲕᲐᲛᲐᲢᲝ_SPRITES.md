# როგორ დავამატო Player Sprites თამაშში

## 📋 რა გჭირდება

შენი მოწოდებული სურათებიდან (3 სურათი sprite sheets-ით) უნდა ამოჭრა და მოამზადო შემდეგი ფაილები:

### 1️⃣ walk_right.png
- **რომელი სურათიდან:** პირველი სურათი (WALK_RIGHT section)
- **რამდენი frame:** 8 ფრეიმი
- **როგორ ამოვჭრა:**
  1. გახსენი სურათი image editor-ში (GIMP, Photoshop, Photopea, ან Aseprite)
  2. Select tool-ით მონიშნე მხოლოდ WALK_RIGHT ანიმაციის 8 ფრეიმი
  3. Copy და Paste ახალ ფაილში
  4. დარწმუნდი რომ background გამჭვირვალეა (transparent)
  5. შეინახე როგორც: **walk_right.png**
  6. ზომა: უნდა იყოს 8 ფრეიმი ჰორიზონტალურად (მაგ: 512x64 pixels თუ თითო ფრეიმი 64x64)

### 2️⃣ walk_left.png  
- **რომელი სურათიდან:** პირველი სურათი (WALK_LEFT section) + მესამე სურათი
- **რამდენი frame:** 8 ფრეიმი
- **როგორ ამოვჭრა:**
  1. მონიშნე WALK_LEFT ანიმაციის ყველა ფრეიმი
  2. Copy და Paste ახალ ფაილში
  3. გამჭვირვალე background
  4. შეინახე როგორც: **walk_left.png**
  5. ზომა: 8 ფრეიმი ჰორიზონტალურად

### 3️⃣ idle.png
- **რომელი სურათიდან:** პირველი სურათი (IDLE_LEFT section) ან მეორე (SELECT_PLAYER)
- **რამდენი frame:** 3-6 ფრეიმი
- **როგორ ამოვჭრა:**
  1. აირჩიე IDLE ანიმაციის ფრეიმები
  2. Copy და Paste ახალ ფაილში
  3. გამჭვირვალე background
  4. შეინახე როგორც: **idle.png**
  5. ზომა: 4-6 ფრეიმი ჰორიზონტალურად

## 📁 სად მოვათავსო ფაილები

დააკოპირე 3 PNG ფაილი ამ ლოკაციაზე:
```
c:\Users\49172\Desktop\wodkania-game\Wodkania-Game\assets\images\player\
```

ასე უნდა გამოიყურებოდეს:
```
assets/
└── images/
    └── player/
        ├── walk_right.png  ✅
        ├── walk_left.png   ✅
        └── idle.png        ✅
```

## 🎨 რეკომენდებული პარამეტრები

თითოეული sprite sheet-ის ზომები:
- **Frame ზომა:** 64x64 pixels (თითო პერსონაჟი)
- **Walk animation:** 8 frames = 512x64 pixels სულ
- **Idle animation:** 4 frames = 256x64 pixels სულ
- **Format:** PNG with transparent background
- **Layout:** ყველა frame ჰორიზონტალურად ერთ რიგში

## 🛠️ როგორ დავამუშავო სურათები

### Option 1: GIMP (უფასო)
1. გახსენი სურათი GIMP-ში
2. Rectangle Select Tool → მონიშნე WALK_RIGHT სეკცია
3. Image → Crop to Selection
4. File → Export As → walk_right.png
5. გაამეორე სხვა ანიმაციებისთვის

### Option 2: Photopea (ონლაინ, უფასო)
1. შედი photopea.com
2. ატვირთე სურათი
3. Rectangular Marquee Tool → მონიშნე სეკცია
4. Layer → New → Layer via Copy
5. წაშალე სხვა layers
6. File → Export as PNG

### Option 3: Aseprite (paid, საუკეთესო pixel art-სთვის)
1. გახსენი სურათი
2. Import as Sprite Sheet
3. Split frames
4. Export როგორც Animation Strip

## 🔧 თუ sprites სხვა ზომისაა

თუ შენი აპრეიმები სხვა ზომისაა (არა 64x64), შეცვალე კონფიგურაცია:

ფაილი: `lib/game/entities/player/player_sprite_component.dart`

```dart
// შეცვალე ეს რიცხვები:
const int walkFrames = 8;        // რამდენი ფრეიმი walk ანიმაციაში
const int idleFrames = 4;        // რამდენი ფრეიმი idle ანიმაციაში
const double frameWidth = 64.0;  // თითო ფრეიმის სიგანე pixels-ში
const double frameHeight = 64.0; // თითო ფრეიმის სიმაღლე pixels-ში
```

## ✅ როგორ ავშუალო

1. დააკოპირე 3 PNG ფაილი `assets/images/player/` ფოლდერში
2. Terminal-ში:
   ```bash
   flutter run -d windows
   ```
3. თამაში ახლა უნდა აჩვენებს animated sprites მოთამაშისთვის! 🎮

## ⚠️ თუ sprites არჩანს

- დარწმუნდი რომ ფაილების სახელები სწორია (walk_right.png, არა Walk_Right.png)
- Check რომ ფაილები PNG format-ით არის
- გაუშვი: `flutter clean` და შემდეგ `flutter run -d windows`
- თუ მაინც არ მუშაობს, თამაში გამოიყენებს fallback (ფერად წრეებს)

## 🎯 რა მოხდება

- ✅ **Sprites არსებობს:** მოთამაშე იქნება animated pixel art character
- ⚠️ **Sprites არ არის:** მოთამაშე იქნება ლურჯი წრე (default fallback)
- 💫 **Animation:** სიარული აჩვენებს walk ანიმაციას, გაჩერებისას - idle ანიმაციას
- 🎨 **Supporters ring:** მაინც ჩანს supporters-ის რაოდენობა (წრე + dots)

---

**შენიშვნა:** თუ რამეს დახმარება გჭირდება, გაუშვი თამაში და დამიწერე რა პრობლემა გაქვს!

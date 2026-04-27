# FRCLive

FRCLive, FRC takımlarının etkinlik takibini hızlandırmak için geliştirilen modern bir iOS uygulamasıdır.  
Uygulama, **The Blue Alliance (TBA)** ve **FRC Nexus** verilerini birleştirerek takım bilgisi, etkinlik seçimi, maç sırası ve canlı kuyruk durumunu tek bir akışta sunar.

---

## TR - Türkçe

### Uygulama Özeti

FRCLive; pit ortamında hızlı okunabilir, sade ve iOS-native bir deneyim sunar:

- Takım numarası ve TBA API key doğrulaması ile güvenli başlangıç
- TBA üzerinden takım profili, etkinlikler ve maç listesi
- FRC Nexus üzerinden canlı kuyruk/maç durumu
- Dashboard, Schedule ve Settings sekmeleri
- TR/EN dil desteği

### Görsel Kimlik ve Kullanılan Dosyalar

Projede aşağıdaki görseller kullanılmaktadır:

- App Icon: `FRCLive/Assets.xcassets/AppIcon.appiconset/FRC Ö.v-iOS-Default-1024x1024@1x.png`
- FIRST Logo: `FRCLive/Assets.xcassets/FIRST_Vertical_RGB.imageset/FIRST_Vertical_RGB.png`
- Onboarding Animation: `FRCLive/rebuilt.gif`

### Özellikler

- **Onboarding**
  - Takım numarası (max 5 hane) girişi
  - TBA API key onay/kaldırma akışı
  - Key onaylanmadan ilerleme engeli
- **Event Selection**
  - Takım adı/nickname + avatar gösterimi
  - 2026 etkinlik kartları (TBA)
  - Etkinlik seçimi sonrası ana sekme yapısına geçiş
- **Dashboard**
  - Takım bilgisi + seçili etkinlik
  - Canlı “Next Match” kartı
  - FRC Nexus polling (30 saniyede bir yenileme)
  - “Şu an sahada” satırı ve kuyruk durum göstergesi
- **Schedule**
  - Seçili etkinliğin maç listesini TBA’dan çekme
  - Takım bazlı filtreleme
- **Settings**
  - Live Activities ve bildirim ayarları
  - Test bildirimi tetikleme
  - TR/EN dil seçici
  - Çıkış yapma

### Kurulum

1. Depoyu klonlayın:

   ```bash
   git clone <repository-url>
   cd FRCLive
   ```

2. Xcode ile açın:

   ```bash
   open FRCLive.xcodeproj
   ```

3. `Signing & Capabilities` altında takım/provisioning ayarlarını yapın.
4. Simülatör veya fiziksel cihaz seçip `Cmd + R` ile çalıştırın.

### API Notları

- TBA key uygulama içinde onboarding ekranında kullanıcı tarafından girilir.
- TBA key onaylandıktan sonra TBA endpoint’leri aktif olur.
- Nexus tarafı seçili etkinlik ve takım numarası ile canlı veriyi çeker.

### Ekran Görüntüleri

Uygulama ekran görüntüleri çok yakında eklenecek.

---

## EN - English

### Overview

FRCLive is a modern iOS app for FRC teams, designed for fast readability in pit environments:

- Team number + TBA API key validation flow
- Team profile, events, and match schedule from TBA
- Live queuing and match pacing from FRC Nexus
- Dashboard, Schedule, and Settings tabs
- TR/EN language support

### Branding Assets Used

The project currently uses the following assets:

- App Icon: `FRCLive/Assets.xcassets/AppIcon.appiconset/FRC Ö.v-iOS-Default-1024x1024@1x.png`
- FIRST Logo: `FRCLive/Assets.xcassets/FIRST_Vertical_RGB.imageset/FIRST_Vertical_RGB.png`
- Onboarding Animation: `FRCLive/rebuilt.gif`

### Features

- **Onboarding**
  - Team number input (max 5 digits)
  - TBA API key confirm/remove flow
  - Continue action is blocked until key confirmation
- **Event Selection**
  - Team nickname + avatar header
  - 2026 event cards (from TBA)
  - Seamless transition to main tab container
- **Dashboard**
  - Team/event context at top
  - Live “Next Match” card
  - 30-second polling with FRC Nexus
  - “Currently on field” pace indicator
- **Schedule**
  - Match list from selected event (TBA)
  - Filtered for selected team
- **Settings**
  - Live Activities + notification toggles
  - Test notification action
  - TR/EN language picker
  - Logout flow

### Setup

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd FRCLive
   ```

2. Open the project in Xcode:

   ```bash
   open FRCLive.xcodeproj
   ```

3. Configure code signing in `Signing & Capabilities`.
4. Select a simulator/device and run with `Cmd + R`.

### API Notes

- TBA API key is entered and confirmed by the user on onboarding.
- TBA-backed endpoints activate after key confirmation.
- Nexus live data uses the selected event and team number.

### Screenshots

Screenshots will be added soon.

---

## Credits

Developed by Onur Akyüz  
[https://onurakyuz.com](https://onurakyuz.com)

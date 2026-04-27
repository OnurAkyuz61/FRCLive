# FRCLive

FRCLive; FRC takımlarının etkinlik, maç takvimi ve canlı kuyruk durumunu hızlı takip edebilmesi için geliştirilen modern bir iOS uygulamasıdır.  
Uygulama, **The Blue Alliance (TBA)** ve **FRC Nexus** servislerini birleştirerek tek akışta kullanılabilir veri sunar.

**GitHub Repo:** [https://github.com/OnurAkyuz61/FRCLive](https://github.com/OnurAkyuz61/FRCLive)

## Uygulama Görselleri

### Uygulama İkonu

![FRCLive App Icon](<FRCLive/Assets.xcassets/AppIcon.appiconset/FRC Ö.v-iOS-Default-1024x1024@1x.png>)

### FIRST Logo

![FIRST Logo](<FRCLive/Assets.xcassets/FIRST_Vertical_RGB.imageset/FIRST_Vertical_RGB.png>)

### Güncel Oyun (Onboarding Animasyonu)

![Rebuilt](FRCLive/rebuilt.gif)

## Proje Özeti

FRCLive’in ana hedefi pit ortamında hızlı okunabilir ve net bir deneyim sunmaktır:

- Takım numarası ve TBA API key doğrulama
- Takım etkinliklerinin listelenmesi
- Etkinlik seçimi sonrası canlı dashboard akışı
- Maç takvimi, kuyruk durumu ve bildirim desteği
- Live Activity ve widget desteği
- TR/EN dil desteği
- Demo modu (`99999`) ile ekran testleri

## Özellikler

### Onboarding

- Maksimum 5 hane takım numarası girişi
- TBA API key onay/kaldırma akışı
- API key onaylanmadan devam engeli
- `rebuild.gif` ile görsel onboarding başlığı

### Event Selection

- Takım adı (nickname), takım numarası ve avatar
- Kart tabanlı modern etkinlik listesi
- Geçmiş etkinlikler için “Etkinlik Tamamlandı” etiketi
- Uygun etkinlikte ana sekmelere geçiş

### Dashboard (Ana Sayfa)

- Takım ve etkinlik başlığı
- Live “Next Match” kartı
- Kuyruk durumu + tahmini başlama bilgisi
- “Şu an sahada” satırı
- Nexus verisi ile periyodik yenileme

### Takvim

- Seçili etkinliğin TBA maç listesi
- Takıma göre filtreleme
- Takvim henüz yoksa uygun boş durum mesajı

### Ayarlar

- Canlı Etkinlikler aç/kapat
- Bildirim izni ve test bildirimi
- Dil seçimi (TR/EN)
- Çıkış yapma

## Entegrasyonlar

### The Blue Alliance (TBA)

- Takım profili
- Takım etkinlikleri (2026)
- Etkinlik maç listesi (`matches/simple`)
- Takım medyası/avatar

### FRC Nexus

- Canlı kuyruk bilgisi
- Şu an sahadaki maç
- Takımın sıradaki maçı
- Kuyruk statüsü

## Live Activities ve Widget

- Dashboard canlı verisi geldikçe Live Activity güncellenir
- `FRCLiveWidgets` target’ı ile small/medium/large widget desteği
- Lock Screen ve Dynamic Island görünümü
- App Group ile veri paylaşımı:
  - `group.onurakyuz.FRCLive`

## Kurulum

1. Depoyu klonla:

```bash
git clone https://github.com/OnurAkyuz61/FRCLive.git
cd FRCLive
```

2. Xcode ile aç:

```bash
open FRCLive.xcodeproj
```

3. `Signing & Capabilities` ayarları:

- `FRCLive` target: Team, Live Activities, App Groups
- `FRCLiveWidgetsExtension` target: Team, App Groups
- Her iki target için aynı App Group: `group.onurakyuz.FRCLive`

4. Çalıştır:

- Simulator veya gerçek cihaz seç
- `Cmd + R`

## Proje Yapısı

- `FRCLive/` → ana uygulama kodları (view, client, manager)
- `FRCLiveWidgets/` → widget + live activity extension
- `FRCLive/Assets.xcassets/` → ikon/logo/görsel varlıklar
- `README.md` → proje dokümantasyonu

## Screenshots

Bu bölüm düzenli olarak güncellenecektir.  
Yeni uygulama ekran görüntüleri burada yayınlanacaktır.

## Lisans

Bu proje MIT lisansı ile lisanslanmıştır.  
Detay: `LICENSE`

## İletişim

Geliştirici: **Onur Akyüz**  
Web: [https://onurakyuz.com](https://onurakyuz.com)

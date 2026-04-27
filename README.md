# FRCLive

FRCLive, FRC takımlarının etkinlik ve maç takibini hızlı, okunabilir ve modern bir iOS deneyimiyle sunmak için geliştirilen bir uygulamadır.  
Uygulama; **The Blue Alliance (TBA)** ve **FRC Nexus** servislerinden gelen verileri birleştirerek takım profili, etkinlik seçimi, maç takvimi, canlı kuyruk durumu, bildirim ve Live Activity akışını tek bir yerde toplar.

## İçindekiler

- Proje Özeti
- Kullanılan Görseller
- Özellikler
- Uygulama Akışı
- Entegrasyonlar (TBA & Nexus)
- Live Activities ve Widget
- Kurulum
- Proje Yapısı
- Screenshots
- Katkı ve Lisans
- İletişim

## Proje Özeti

FRCLive’in temel amacı, pit alanında hızlı karar almayı kolaylaştırmaktır:

- Takım numarası + TBA API Key ile güvenli giriş
- Takımın 2026 etkinliklerinin listelenmesi
- Etkinlik bazlı maç takvimi ve takım filtrelemesi
- Dashboard’da canlı kuyruk / sıradaki maç bilgisi
- Local notification ve Live Activity desteği
- TR/EN dil desteği (uygulama genelinde)
- Demo modu (`99999`) ile görsel test akışı

## Kullanılan Görseller

Bu projede aşağıdaki görseller aktif olarak kullanılır:

- Uygulama ikonu  
  `FRCLive/Assets.xcassets/AppIcon.appiconset/FRC Ö.v-iOS-Default-1024x1024@1x.png`
- FIRST logosu  
  `FRCLive/Assets.xcassets/FIRST_Vertical_RGB.imageset/FIRST_Vertical_RGB.png`
- Güncel oyun / onboarding animasyonu  
  `FRCLive/rebuilt.gif`

## Özellikler

### 1) Onboarding

- Takım numarası girişi (maksimum 5 hane)
- TBA API key giriş/onaylama/kaldırma
- API key onaylanmadan devam etme engeli
- Yeniden markalanmış onboarding görsel alanı (`rebuilt.gif`)

### 2) Event Selection

- Takım nickname + takım numarası + avatar gösterimi
- Etkinliklerin modern kart yapısında listelenmesi
- Geçmiş etkinliklerin “Etkinlik Tamamlandı” etiketiyle pasifleştirilmesi
- Etkinlik seçimi sonrası ana uygulama sekmelerine geçiş

### 3) Dashboard

- Takım özeti ve seçili etkinlik başlığı
- Live “Next Match” kartı
- Kuyruk durumu + tahmini başlama bilgisi
- “Şu an sahada” satırı
- Nexus verisi periyodik yenileme (polling)

### 4) Schedule

- Seçili etkinliğin maç listesini TBA’den çekme
- Takımın dahil olduğu maçları filtreleme
- Maç takvimi yayınlanmadıysa uygun boş durum mesajı

### 5) Settings

- Canlı Etkinlikler (Live Activities) aç/kapat
- Bildirim izinleri ve test bildirimi
- Dil seçimi (TR / EN)
- Çıkış yapma

## Uygulama Akışı

1. Onboarding (takım + TBA key doğrulama)
2. Event Selection (etkinlik seçimi)
3. MainTabContainer
   - Ana Sayfa
   - Takvim
   - Ayarlar

## Entegrasyonlar

### The Blue Alliance (TBA)

- Takım profili (nickname)
- Takım etkinlikleri (2026)
- Etkinlik maç takvimi (simple matches)
- Takım medyası (avatar çözümleme)

### FRC Nexus

- Etkinlik kuyruk durumu
- Sahadaki güncel maç
- Takımın sıradaki maçı
- Kuyruk statüsü (`Not Called`, `Called to Queue`, `On Field`)

## Live Activities ve Widget

- Dashboard canlı verisi geldikçe Live Activity güncellenir
- Widget target (`FRCLiveWidgets`) üzerinden:
  - Small / Medium / Large widget desteği
  - Lock Screen / Dynamic Island Live Activity görünümü
- App Group ile widget veri paylaşımı desteklenir  
  (`group.onurakyuz.FRCLive`)

## Kurulum

1. Depoyu klonlayın:

```bash
git clone <repository-url>
cd FRCLive
```

2. Projeyi Xcode ile açın:

```bash
open FRCLive.xcodeproj
```

3. `Signing & Capabilities` ayarlarını yapın:
- `FRCLive` ve `FRCLiveWidgetsExtension` için uygun Team seçin
- Gerekli capability’leri doğrulayın:
  - App Groups
  - Live Activities

4. Simülatör veya fiziksel cihaz seçip çalıştırın:
- `Cmd + R`

## Proje Yapısı

- `FRCLive/`  
  Ana uygulama kaynak kodları (Views, API clients, managers)
- `FRCLiveWidgets/`  
  Widget ve Live Activity extension kodları
- `FRCLive/Assets.xcassets/`  
  Uygulama görsel varlıkları
- `Config/`  
  Local config örnekleri

## Screenshots

Ekran görüntüleri bu depoda güncellenmeye devam edecek.  
Yeni ekran görselleri yakında bu bölüme eklenecektir.

## Katkı ve Lisans

- Lisans: MIT (`LICENSE`)
- Katkı yapmak için issue/PR açabilirsiniz.

## İletişim

Geliştirici: **Onur Akyüz**  
Web: [https://onurakyuz.com](https://onurakyuz.com)

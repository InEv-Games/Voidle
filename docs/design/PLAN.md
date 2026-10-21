# Büyük güncelleme uygulama planı

GDD paketleri [KARARLAR.md](KARARLAR.md) doğrultusunda yeniden gruplanmıştır. Her faz kendi içinde oynanabilir bir ara durum bırakır.

## Ön iş: Orbital yerleştirmenin düzeltilmesi

Şu anki oyunda orbital istasyona roket atma akışına ulaşılamıyor; City'ye basınca yalnızca City kurma açılıyor. Büyük güncellemeden önce düzeltilecek.

## Faz 0: Hazırlık
- Belgeler `docs/design/` altında. Kararlar `KARARLAR.md` dosyasında.
- Yeni kayıt sürümü. Eski kayıtlar silinmez, yeni ekonomiye taşınmaz.

## Faz 1: Altyapı (GDD P01–P04 ve komut sistemi)
- `act1_complete` yerine `civilization_type`, `playable_content_type`, `demo_completed`. Erişim kontrolleri (`can_play`, `can_preview`, …) tek yerden yapılır.
- Tek kaynak defteri: bütün ekleme ve harcama tek kapıdan geçer.
- Kayıt: yükleme başlangıç bütçesinin üzerine yazmaz; kimlikler ve ebeveyn/çocuk ağacı saklanır.
- `SettlementCommand` (`can_execute` / `preview` / `execute`) ve sağ tık bağlam menüsü. Mevcut kur/kaldır işlemleri buraya taşınır.

## Faz 2: Ekonominin çekirdeği
- Sabit girdili bina tarifleri; nadirlik verimi model çıktısına gömülür. Otomatik en nadir harcama ve genel `raw` havuzu kalkar.
- Ortak 20 saniyelik döngü; dakikalık hızlar korunarak çevrilir.
- Nüfus maliyetleri mevcut ölçeklenmeyle kalır. Açıkta çıktı azalır (`0,5 + 0,5 × karşılama`). Boş nüfus geliri eklenir.
- Gövde mineral kümesi ve ilk Production ile keşif. Yoğunluk ve `min_hop` kalkar.
- İsimli malzeme bedelleri. Bina seviye yükseltmesi kalkar. Büyük binalar 2 yuva kaplar.
- District fiyat artışı mevcut haliyle kalır.

## Faz 3: Konum (GDD P09–P10)
- Dereceden km'ye geçiş, beş mesafe etiketi.
- 14 görünür arazi türü: üzerinde tam, 250 km yakın kuşakta yarım bonus.
- Yollar yalnızca görsel; yakındaki her kaynak tam katkı; Capital için yol şartı yok.

## Faz 4: İçerik
- Bina kataloğu (sabit girdi kararına göre; Moonstone modelleri; Tier 4 kapatılır).
- Skill ağacı: canonical grafik, 6.500 Science'lık ortak yol, ANY ön koşulları, eski 54 düğümün eşlenmesi.
- Trade: sabit fiyat, taşma satışı, rezervler, otomasyon.

## Faz 5: Ay yolu
Dünya Spaceport → lander → Ay City → Ay Production → 100 yerel Moonstone → Ay Malzemeleri → Lunar Spaceport → gelişmiş roket → hedef gezegen → Tip 1. Shipyard şartı ve gezegen Lv3 kapısı kalkar. Orbital isteğe bağlı içerik olarak kalır.

## Faz 6: Yerleşim yönetimi (sağ tık)
- Yık / içeriği temizle / sıfırla; N/C defteri ile %50/%65/%75 iade.
- Güncelle: yeni içerik için ücretli fark teklifi.
- Taşı: Yerleşim Düzenleme skill'i, eski/yeni bonus önizlemesi.

## Faz 7: Görev paneli ve demo sonu
- Sürekli görev paneli; tutorial ekonomik ödülleri kalkar; başarımlar gerçek olaylara bağlanır.
- Demo bitişinde ekonomi durmaz, evren incelenebilir, Miras düğümü yalnız önizlemedir.

## Faz 8: Offline (araştırma)
- Geçen süre kaydı ve "Sen yokken" ekranı; ekonomik kazanç yok.
- Tek anahtar: `OFFLINE_PROGRESS_ENABLED`. Kazanç kararı sonra.

## Faz 9: Denge testi
Sınırsız yakınlık bonusu, boş nüfus geliri ve fiyat eğrileri öncelikli.

## Sonraya kalanlar
Tip 1'in 50 district'i (GDD P25–P29) ve Tip 2–5 oynanabilir içeriği. Faz 1'deki veri yapısı bunlara uygun kurulur.

## Açık sorular
1. Bina fiyat sayacı: district'teki bütün binalar (şu an) mı, aynı model (GDD) mi? Oran geçici olarak ×1,07, nihai değer denge testinde.
2. Boş nüfus hesabında City'nin ücretsiz 15.000 kapasitesi sayılsın mı?

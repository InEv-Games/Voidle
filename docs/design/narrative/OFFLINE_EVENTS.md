# Çevrimdışı dünya olayları

[Danışman ve dönüş kuralları](ADVISORS.md) · [Kayıt ve simülasyon](IMPLEMENTATION.md)

Bir yoklukta en fazla bir büyük olay ve birkaç küçük olay kayda geçebilir. Danışman bunları oyuncu I-330'daki koruyucu uykudan çıktığında anlatır. Sonuçlar aynı kayıt aralığı için bir kez üretilir.

## Veri dosyaları

- [Büyük olaylar](data/offline_major_events.csv)
- [Küçük olaylar](data/offline_minor_events.csv)

UTF-8 CSV sütunları `id`, `weight`, `target_pool`, `effect_id`, `title_en` ve `report_en` şeklindedir. Ağırlık, o olayın uygun adaylar içindeki göreli seçilme olasılığıdır. `{place}` gerçekten seçilen yerin görünen adından doldurulur. Yer bulunursa özetten haritaya geçilir.

## Seçim ve uygulama

**İlk denge varsayımı.** Çevrimdışı ilerletilen takvim en az bir oyun yılıysa büyük olay için bir kez %30 olasılık atılır. Her tamamlanmış üç oyun ayı için küçük olay olasılığı %35'tir. Bir dönüş en fazla altı küçük olay kaydeder. Aynı olay kimliği ve hedef bir aralıkta bir kez kullanılır. Uygun hedefi kalmayan satır seçim havuzundan çıkar. Olasılık ve adetler ayarlanabilir veri değerleridir.

1. Yokluk aralığını 24 gerçek saatte sınırla ve ekonomi ile takvimi aynı %10 zaman bütçesiyle ilerlet.
2. İş sonuçlarını slotun işlenen durumuna ekle. Rastgele olay adaylarını işlerin bıraktığı güncel dünya durumundan seç. Seçimin tohumu, kayıt ve işlenen yokluk aralığından türetilir.
3. Sonucu haritaya veya günlük kaydına uygula. İşlenmiş aralık kimliğini, seçilen hedefi, sonucu ve bekleyen raporu [tek slot işlemiyle](IMPLEMENTATION.md#çevrimdışı-simülasyon-sınırı) kaydet.
4. Büyük olayı varsa ilk sırada sun. Danışmanın sözlü özeti en önemli üç sonucu taşır. Geri kalanlar ayrıntılarda ve Narrative Log'da okunur.

| Hedef havuzu | Uygunluk |
| --- | --- |
| `owned_city` | Kurulmuş City. Küçük olaylar için rapor konumu. |
| `working_district` | Tamamlanmış ve faaliyet gösteren district. Küçük olaylar için rapor konumu. |
| `owned_spaceport` | Mevcut, tamamlanmış uzay tesisi. |
| `accessible_excavation` | Oyuncunun ulaşabildiği kazı alanı. Hikâye seçimini oyuncu yapar. |
| `unowned_land`, `unowned_coast`, `unowned_crater` | Üzerinde oyuncu yapısı, aktif iş, görev sahası veya sefer hedefi olmayan uygun arazi. Kıyı olayları haritada sıvı suyla sınırı olan hücre ister. `buried_ridge` atmosferi olan gövdelerde seçilir. |
| `unowned_ruin` | Görev, kazı zinciri veya ödülle bağlantısı olmayan sahipsiz kalıntı. |
| `aux_producer` | Tamamlanmış sıradan stok üretim binası. City, Capital, yaşam desteği, konut, enerji, sefer ve görev yapıları bu havuza girmez. |

| Etki | Uygulama |
| --- | --- |
| `log_only` | Yer ve gözlem kayda girer. Oyuncu dönüşte okuyabilir. |
| `survey_marker` | Keşif işareti ve keşfin görünen açıklaması haritada kalır. |
| `terrain_overlay` | Sahipsiz hücrenin yüzey değişimi kayıtlı harita katmanında görünür. İlk sürümde bu katman mevcut arazi çarpanlarından bağımsızdır. |
| `collapse_ruin` | Uygun sahipsiz kalıntı, kayıtta çökmüş kalıntı olarak görünür. |
| `repair_required` | Seçilen bina onarım beklerken üretimi durur. Oyuncu bina kartındaki `Repair` eylemiyle işi başlatır. İlk denge varsayımı 20 ekonomi saniyesi ve sıfır kaynak bedelidir. Onarım bitince bina önceki çalışma tercihine döner. |

Kalıcı yıkım sahipsiz alan ve kalıntılarla sınırlıdır. Kazı alanları, Bolo ve Burkai'nin görüşme koşulları, sefer hedefi ve mevcut ilerleme ödülleri rastgele olaylardan bağımsızdır. Bir rapor, yalnız uygulanmış etkiyi ve o anda kaydedilmiş durumu anlatır.

Önceden kaydedilmiş kazı koordinatlarını çökme ve arazi değişimi hedeflerinden çıkar. Sırası gelince konum alacak kazılar için yeni yer seçimi, daha önce çökmüş veya değişmiş hücreleri aday listesinden eler. Bir yıkım ya da arazi değişimi seçilirse sonucu kaydetmeden önce gövdenin henüz konum almamış her benzersiz `place_key` değeri için ayrı bir uygun hücre kalabildiğini mevcut arazi ve yedek arazi sırasıyla doğrula. Aynı kalıntıyı kullanan kazı aşamaları bir anahtar sayılır. Koşulu karşılamayan hedef elenir. Bu doğrulama kazı koordinatlarını atamaz. [Mevcut kazı yeri seçimi](../../../scripts/game/excavation/Excavations.gd#L129)

# Tasarım belgeleri üzerine kararlarımız

Bu dosya GDD ve V1–V3'ün **önüne geçer**. Burada değiştirilmemiş konularda GDD geçerlidir.

Tarih: 21 Ekim 2026

## 1. Girdi seçimi yok, her binanın girdisi sabit

**GDD'de:** Oyuncu bir işleme binasının hangi minerali harcayacağını seçer; aynı model tek kartta mineral alt satırlarıyla gösterilir.

**Kararımız:** Her bina modelinin tek ve sabit bir tarifi vardır. Moonstone harcayan bina Moonstone harcar; Ferrite harcayan bir yapı ayrı bir bina modelidir (örneğin Goods Factory ile Regolit Goods tesisi). Her model kendi fiyat sayacını kullanır. Nadirlik verimi modelin kendi çıktı değerine gömülür. Otomatik en nadir mineral harcama ve genel `raw` havuzu da kalkar.

## 2. District fiyat artışı mevcut haliyle kalır

**GDD'de:** District fiyatı aynı City'deki aynı aileden adet başına ×1,50 artar.

**Kararımız:** Bunu daha önce denedik. Fiyatlar çok hızlı yükseldiği için uzmanlaşmış şehirler (örneğin maden şehri) kurmak yerine her şehre her şeyi kurmak mantıklı hale geliyordu ve taktiksel derinlik azalıyordu. Mevcut district fiyatlandırması korunur.

*Açık:* Bina fiyat artışı (GDD: aynı model ×1,20; şu an: district'teki bütün binalar ×1,35) aynı gerekçeyle değerlendirilecek.

## 3. Nüfus mevcut sistemde kalır, iki ekleme ile

**GDD'de:** Sabit 500 yük, global kapasite.

**Kararımız:**
- Nüfus maliyetleri şu anki gibi ölçeklenmeye devam eder (sabit değil, fiyat gibi artar).
- **Kabul:** Nüfus veya enerji açığında üretim süresi uzamaz, çıktı miktarı düşer (`0,5 + 0,5 × karşılama`).
- **Kabul:** Boş nüfus kaynak getirir (Sivil Girişimler, Serbest Araştırma, Üretim Rezervi).

## 4. Offline: önce yalnız bilgi, kazanç sonra değerlendirilecek

**GDD'de:** 1/10 hızında offline ekonomi ve kredi/Science kotası.

**Kararımız:** Masaüstü oyun olduğu için offline kazancın doğru olup olmadığından emin değiliz. İlk aşamada yalnızca geçen süre kaydedilir ve girişte gösterilir. Olası bir mekanik tek bir anahtarla (`OFFLINE_PROGRESS_ENABLED`) kolayca kapatılabilir olmalıdır. Kazanç konusu ayrıca incelenecek.

## 5. Ay yolu

**Kabul:** Orbital Shipyard'ın zorunlu kapı olması kalkar. Ay'a Dünya Spaceport'tan atılan lander ile gidilir. Ay'daki 100 yerel Moonstone, Ay'dan ayrılan son roketin şartıdır.

**Ek:** Şu anki oyunda orbital yerleştirmeye aktif oynanıştan ulaşılamıyor. Bu, büyük güncellemeden önce düzeltilecek. Orbital, ana yoldan ayrı ama çalışan isteğe bağlı içerik olarak kalır.

## 6. Yerleşim işlemleri sağ tık menüsünden

Güncelle, taşı, içeriği temizle, sıfırla ve yık gibi işlemler seçili nesnenin **sağ tık bağlam menüsünden** yapılır. Arka planda command pattern kullanılır: her işlem `can_execute` (yapılamıyorsa nedenini döner), `preview` (bedel, iade, değişen kapasite) ve `execute` adımlarına sahiptir.

## 7. Genel değerlendirme

GDD'nin geri kalanı kabul edildi. Derinliğin idle oyun için fazla olabileceği bir risk, ancak oyun 4X–Incremental çizgisinde konumlandığı için bu kabul edilebilir. Sayısal denge ayrı bir denge testinden geçecek.

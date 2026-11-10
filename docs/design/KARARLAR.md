# Tasarım belgeleri üzerine kararlarımız

Bu dosya GDD ve V1–V3'ün **önüne geçer**. Burada değiştirilmemiş konularda GDD geçerlidir.

Tarih: 21 Ekim 2026

## 1. Girdi seçimi yok, her binanın girdisi sabit

**GDD'de:** Oyuncu bir işleme binasının hangi minerali harcayacağını seçer; aynı model tek kartta mineral alt satırlarıyla gösterilir.

**Kararımız:** Her bina modelinin tek ve sabit bir tarifi vardır. Moonstone harcayan bina Moonstone harcar; Ferrite harcayan bir yapı ayrı bir bina modelidir (örneğin Goods Factory ile Regolit Goods tesisi). Tekrar sayacının kapsamı §2'deki açık soruya bağlıdır. Nadirlik verimi modelin kendi çıktı değerine gömülür. Otomatik en nadir mineral harcama ve genel `raw` havuzu da kalkar.

## 2. District fiyat artışı mevcut haliyle kalır

**GDD'de:** District fiyatı aynı City'deki aynı aileden adet başına ×1,50 artar.

**Kararımız:** Bunu daha önce denedik. Fiyatlar çok hızlı yükseldiği için uzmanlaşmış şehirler (örneğin maden şehri) kurmak yerine her şehre her şeyi kurmak mantıklı hale geliyordu ve taktiksel derinlik azalıyordu. Mevcut district fiyatlandırması korunur.

Burada korunan şey **sayacın mantığıdır** (City'deki district'lerin türüne bakılmaksızın sayılması). Oranın kendisi (şu an `DistrictDef.gd`'de ×1,6) denge testinde düşürülebilir; [BALANCE_RAPORU.md](BALANCE_RAPORU.md) ×1,30 öneriyor.

**Bina tekrar oranı:** Hem GDD'nin ×1,20'si hem şu anki ×1,35 idle/incremental için çok yüksek. Geçici başlangıç değeri **×1,07–1,08** (idle oyunlarda tipik aralık 1,07–1,15). Oranlar Economy'de tek bir sabit olarak tutulur; nihai değeri denge testi belirler.

*Açık:* Bina sayacı "district'teki bütün binalar" mı (şu an), "aynı model" mi (GDD)? §1 sabit girdili her modeli ayrı model yapar, ancak tekrar sayacının model bazında mı district bazında mı tutulacağı bu sorudan bağımsızdır ve aynı uzmanlaşma gerekçesiyle değerlendirilecek.

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

**Ek:** Şu anki oyunda orbital yerleştirmeye aktif oynanıştan ulaşılamıyor. Bu, büyük güncellemeden önce düzeltilecek.

**Güncelleme (22 Ekim 2026):** Orbital ana yolun parçasıdır. Ay'a gitmeden önce yörüngede bitmiş bir Space Station şarttır: Orbital Assembly ortak yola girer (Rocketry → Orbital Assembly → Lunar Program), Lunar Program araştırması ve lander hazırlığı bitmiş bir istasyon ister. Shipyard yine şart değildir; Zero-G, Mirrors, Shipyard ve Offworld Trade isteğe bağlı kalır.

## 6. Yerleşim işlemleri sağ tık menüsünden

Güncelle, taşı, içeriği temizle, sıfırla ve yık gibi işlemler seçili nesnenin **sağ tık bağlam menüsünden** yapılır.

**Sağ tık yalnızca eylemler içindir.** Geri gitme/bir üst seviyeye çıkma sağ tıktan kaldırılır ve ayrı bir **navigation HUD**'a taşınır: geri/ileri butonları (tarayıcı gibi geçmiş), Galaxy › Sistem › Gezegen › City/District breadcrumb'ı, fare geri/ileri tuşları ve Alt+←/→. Arka planda command pattern kullanılır: her işlem `can_execute` (yapılamıyorsa nedenini döner), `preview` (bedel, iade, değişen kapasite) ve `execute` adımlarına sahiptir.

## 7. Genel değerlendirme

GDD'nin geri kalanı kabul edildi. Derinliğin idle oyun için fazla olabileceği bir risk, ancak oyun 4X–Incremental çizgisinde konumlandığı için bu kabul edilebilir. Sayısal denge ayrı bir denge testinden geçecek.

## 8. Fraktal skill ağacı

**GDD'de:** Tip 1'de bütün Tip 0 ağacı tek bir "Tip 0 Mirası" düğümüne dönüşür. Fiyatı sabit: 4.000 × 10^(tip−1) Science.

**Kararımız:**
- Her medeniyetin skill ağacının **merkez düğümü bir önceki medeniyetin ağacını temsil eder**. Merkez düğüme **çift tıklayınca** o ağaç açılır. Bu özyinelemeli çalışır: Tip 2'nin merkezi Tip 1'i, onun merkezi Tip 0'ı açar.
- Merkez düğümün altında **"buyout" fiyatı** görünür. Bu, önceki tipin ağacındaki bütün eksik skill'leri tek seferde satın alır.
- **Buyout fiyatı, eksik skill'lerin toplam fiyatıdır** (eksik seviyeler dahil). İndirim veya sabit taban fiyat yoktur. Böylece Tip 0'da strateji düğümlerini ertelemek ödüllendirilmez.
- Satın alınmış seviyeler fiyattan düşülür ve iki kez sayılmaz: etkin seviye = max(kendi alınan, buyout ile gelen).
- GDD'nin "mirasın vermedikleri" listesi (bina, district, keşif, Spaceport, bedava Güncelle yok) geçerlidir. Demoda buyout yalnız önizlemedir.
- *Açık:* Çapraz dal zammının buyout toplamına dahil edilip edilmeyeceği denge ekibine sorulacak.

## 9. District seviyelerinde yol komşusu kuralı kalır

**GDD'de:** District seviyesi yalnız kredi ve nüfusla alınır; yol şartı yoktur.

**Kararımız:** Capital District serbestçe seviye atlar. Diğer district'ler, yolla bağlı bir komşusu hedef seviyeye ulaşmadan seviye atlayamaz; seviyeler Capital'dan dışarıya yayılır. Yollar ekonomide konum bonusu vermez, ama bu seviye kuralını taşır.

## 10. Playtest kararları (23 Ekim playtest'i)

Tarih: 26 Ekim 2026. İş planı: [PLAYTEST_2026-10-23.md](PLAYTEST_2026-10-23.md).

- **Trade fiyatları dinamik.** *GDD'de:* sabit fiyat (satış %90, alış %110). *Kararımız:* her alım o kaynağın fiyatını artırır, her satış düşürür; fiyat zamanla taban değere geri döner. 4.000 kredilik işlem fiyatı %100 oynatır; değişimin yarısı 2 dakikada söner; fiyat referansın 0,4–3 katı arasında kalır (`BalanceConfig` → Trade). Depo taşmasının otomatik satışı artık Trade Automation araştırmasıyla açılır.
- **Sağ sürükleme gezegeni döndürür.** Sürüklemeden yapılan sağ tık §6'daki komut menüsünü açar.
- **Dünya binaları Ay district'lerine kurulabilir.** Kaynaklar (Ferrite dahil) ortak global stoktur; nerede harcandığı fark etmez. §1'deki sabit girdi kuralı değişmez.
- **Uzaklık bantları City'nin erişimine göredir.** *GDD'de:* sabit 500 / 1.000 / 2.000 / 3.500 km. *Kararımız:* bantlar district'in City erişiminin oranıdır (çok yakın ≤ %40, yakın ≤ %60, orta ≤ %80, uzak < %95, sonrası çok uzak). Böylece %0–%50 aralığının tamamı her City seviyesinde ve Ay'da erişilebilir. Yakınlık ve merkez bonusları da aynı bantları kullanır. Oranlar `BalanceConfig` içindedir.
- ~~**Yer çarpanı yarım adımlara yuvarlanır.**~~ *(10 Kasım'da kalktı, bkz. §12.)* Bir district'in ve binalarının yer çarpanı (arazi × konum) en yakın yarım adıma yuvarlanır: 1x, 1,5x, 2x … (en az 1x). Ekonomi yuvarlanmış değeri kullanır, arayüz de aynısını gösterir; yüzdeler yalnızca "neden" açıklamasında kalır. Küçük bonuslar (×1,2 gibi) kaybolur, büyükler yukarı yuvarlanabilir. `Economy.site_mult`.
- **Araştırılan binalar malzeme ve bakım ister.** Başlangıç binaları (Solar Array, Habitat Block, Market, Research Lab, Mine, Warehouse, Goods Factory, Civic Office) bedavadır. Araştırmayla açılan tier-1 binalar Ferrite ile kurulur (10–30); tarifi olmayan üreticiler cycle başına az miktarda Goods tüketir (0,2–0,25). Değerler her binanın kendi `.tres` dosyasındadır. Tier 2+ zaten malzeme ve bakım istiyordu.
- **Capital'de baştan bir bina.** Yeni Civic Office (1 slot, araştırma yok). Capital slotu 2 + seviye başına 1 oldu; Civic Office ile 2 slotluk Spaceport Lv2'de sığar.
- **Erken nüfus.** Residential district tabanı 1.500 → 3.000; district kurma nüfus adımı +%50 → +%25 (maliyet hâlâ artar, §3).
- **Low-rise Housing enerjisiz konut** (+1.250 nüfus, 0 enerji, 10 Ferrite).
- **Spaceport 2.500 kredi + 50 Ferrite + 10 Goods** (önceden 500 kredi).
- **Demoda yalnızca Dünya ve Ay oynanır** (demo bitmeden de). Diğer dünyalar Medeniyet 1 içeriği açılınca oynanır; Earth Spaceport Ay'a kurulamaz (Ay'ın kendi Lunar Spaceport'u var).
- **Son roket 3 dakika uçar** ve yıldız sistemi görünümünde yolu ve ETA'sıyla çizilir.
- **İade kredi ve malzemeyi kapsar.** Clear, reset ve demolish ödenen kredinin ve malzemenin aynı oranını iade eder: %50, Recycling skilleriyle %65 ve %75.

## 11. Oyuncuya gösterilen metinlerde kaynaklar yalnızca ikonla yazılır

**Kararımız (3 Kasım 2026):** Oyunda bir kaynaktan bahsederken adı yazılmaz, ikonu kullanılır. "+5% Credits" değil, Credits ikonu ve "+5%". Bu kural etkiler, bedeller, ödüller, eksik miktarlar, tooltip'ler ve açıklama cümleleri için geçerlidir.

- **Nasıl yazılır:** `UIIcons.bb(id, boyut, renk)` ile ikon, yanına miktar. Trait ve bonus etkileri için `PlanetTags.effect_short_bb`. "Hammadde ve işlenmiş ürünler" (`raw`) dört ikonla gösterilir.
- **Düz metin alanlar:** İkon gösteremeyen yerde (haber bandı, düz `Label`) kaynak adını yazma. Ya alanı `RichTextLabel` yap ya da cümleyi kaynaktan söz etmeyecek şekilde kur; ayrıntı tooltip'e gider.
- **Kapsam dışı:** Hikâye metni gibi kurgu cümleleri ("your scientists"), bina ve araştırma adları, geliştirici konsolu ve kaynağın kendisini tanıtan yerler (Glossary girdisinin başlığı gibi).

## 12. Playtest kararları (7 Kasım playtest'i)

**Kararlarımız (9 Kasım 2026):** 7 Kasım playtest'inin iş planı ve takibi [PLAYTEST_2026-11-07.md](PLAYTEST_2026-11-07.md)'dedir. Kural koyan kararlar:

- **Konum bonusu cezasız.** Uzaklık bonusu, district'in kendi City'sine olan uzaklığına göre verilir: merkezde 0, erişim alanının kenarında +%50 (bantlar 0 / 12,5 / 25 / 37,5 / 50). Önceden en yakın başka district'e göre hesaplanıyordu ve her yeni district komşularının bonusunu düşürüyordu. Aynı türden komşular +%10 / +%5 vermeye devam eder. "City centre" bonusu kalktı; City'nin (Capital District) konum bonusu yoktur. `Location.gd`.
- **Birleşik "Site" çarpanı ve yuvarlama yok** (10 Kasım; 9 Kasım'daki "yuvarlama kalır" kararının ve §10'daki yarım adım kuralının yerine geçer). Oyuncuya Geography ve Location ayrı ayrı gösterilir, ikisini birleştiren bir sayı gösterilmez. Ekonomi de yuvarlamaz: district'in kendi temel üretimi Geography × Location ile tam olarak çarpılır. `Economy.site_mult`.
- **City'ler de coğrafya bonusu alır** (10 Kasım). Capital dahil her yüzey City'si, üzerinde durduğu arazinin coğrafya bonusunu kendi temel üretimine alır; çarpanlar diğer district'lerle aynıdır. Orbit hâlâ almaz. Konum bonusu City'de yoktur (merkez kendisidir). `FeatureMap.terrain_mult`.
- **İlk City'yi yerleştirirken yol gösterme** (10 Kasım). City'nin yerleştirme kartında "Within reach" bölümü var: City'nin erişim alanında hangi arazinin ne kadar olduğu, hangi district türlerine yaradığı ve beş türden kaçına yaradığı. İlk Capital'de haritada en iyi 3 yer altın işaretle önerilir; açılış başlığı kamerayı en iyisine çevirir.
- **Toplu inşa:** Shift bütün boş slotları doldurur, ama yalnızca hepsinin parası yetiyorsa; Ctrl/Cmd paranın yettiği kadarını alır. ×5 kalktı. Gamepad: LB = Shift, RB = Ctrl.
- **Kısayollar sırayla açılır:** Upgrade Tree ilk Science district'i bitince, Companions ilk yoldaş katılınca, Trade Trade Access ile açılır. Arayüz (haber şeridi dahil) ilk City'yle gelir.
- **Kazı ekonomisi:** Kazı yalnızca kredi ister, karşılığında Science (eski Science getirisinin 1,25 katı) ve sitenin maddesini (Ferrite/Moonstone) verir; kredi vermez. City'nin erişim alanındaki kazı %50 daha hızlı ve %25 daha ucuzdur.
- **Market:** Sıra Science, madenler, sonra işlenmiş ürünler. Bu medeniyetin bulunmamış madenleri adsız, kilitli satır olarak görünür; Goods, Basic Processing araştırılana kadar kilitlidir.
- **Coğrafya (Terran):** Her dünyada 5–12 göl (üstüne kurulmaz), kurulabilir arazinin ~%8'i Tundra, ~%2'si Glacier, ~%2,5'i Volcanic. `FeatureMap.gd`.

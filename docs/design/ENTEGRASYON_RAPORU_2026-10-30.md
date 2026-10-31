# Bina / District / Coğrafya entegrasyonu — gece raporu (2026-10-30)

Kaynak: `VOIDLE_BINA_DISTRICT_COGRAFYA_ENTEGRASYON_KARARLARI_2026-10-29.md` (designer tablosu).
Branch: `Development/AI-FastBuild`. Değişiklikler **stage'li ama commit edilmedi**: repo commit'leri SSH anahtarıyla imzalıyor ve anahtarın parolası bende yok. İmzalamayı atlamadım. Sabah `git commit` yeterli. Önerilen mesaj aşağıda.

## 1. Kısa durum

| Alan | Durum |
|---|---|
| 53 bina kataloğu (§2, §9–§15) | Tamam. Headless kontrol 53 aktif modeli doğruladı: Capital 6, Production 16, Energy 7, Science 8, Residential 9, Commercial 7 |
| İnşa malzemesi paketleri (§8.1, §19.2) | Tamam. Ekonomik tiere göre: T0 yok, T1 30F+5G, T2 90F+15G+5Fuel, T3 180F+45G+15Fuel+5Rare |
| Coğrafya: 15 tür, 2x / 1.5x, toplanır (§3) | Tamam |
| District tabanları, Capital adı (§4) | Tamam |
| Capital destekleri ve City × gezegen çarpımı (§5, §7.1) | Tamam |
| Orbit City ve 5 destek districti, prefab (§6) | Tamam. Kendi prefabını kaydetme yapılmadı (bkz. §4 bu rapor) |
| Spaceport ve final roket (§9.2, §18) | Tamam |
| Araştırma fiyat ve önkoşulları (§16, §19.5) | Tamam. Bütün bedeller tablolarla eşleşti |
| UI: destek gösterimi, Ay'a Özel etiketi (§7.2, §3.3) | Büyük ölçüde tamam. Kalanlar §4'te |
| Excel | Değiştirilmedi |
| Oyun içi test | **Yapılmadı** (belge §1.7). Yalnız headless derleme ve katalog kontrolü yapıldı |

## 2. Ne değişti

### Binalar (`resources/buildings/`)
- **36 mevcut model** yeni değerlerle eşlendi. Kimlikler korundu, eski kayıtlar çalışır. Örnek: `cryo_vault` → Housing Authority, `command_center` → Energy Directorate, `field_observatory` → Field Lab, `refinery` → Goods Factory, `plasma_smelter` → Fuel Refinery, `molecular_forge` → Rare Element Forge, `antimatter_chamber` → Antimatter Plant (artık Tip 0).
- **17 yeni model:** river_extractor, geothermal_drill, volcanic_mine, rare_element_refinery, storage_facility, fission_reactor, forest_research_station, desert_research_station, mountain_terraces, forest_homes, desert_habitat, lakeside_market, glacier_exchange, volcanic_market, crater_habitat, cavern_refinery, ion_research_lab.
- **26 eski model `retired = true`.** Bunlar listede çıkmaz ama eski kayıttaki kopyalar çalışmaya devam eder. Liste: Civic Office, Lunar Spaceport, Regolith Extractor/Goods Plant/Silo, Advanced Excavator, Fuel Depot, Fusion Reactor, Lunar Solar Array, Shallow Geothermal Well, Ridge Turbine, Lunar Research Outpost, Lunar Sample Lab, Pressurised/Modular Moon Habitat, Seaside Villas, Bazaar, Harbor Market, Lunar Trade Post/Supply Market, 6 eski orbital modül.
- `BuildingDef`'e eklenen alanlar: `retired`, `cost_tier` (ekonomik referans tier), `requires_atmosphere`, `requires_liquid_sea`. Ayrıca `is_moon_only()`.
- Capital destekleri: Tier 0, 600 kr, 250 çalışan, 1 enerji/sn, 1 slot, araştırmasız, tek kopya sınırı yok, kapsam yalnız kendi City'si.

### Coğrafya (`FeatureMap.gd`, `BalanceConfig.gd`, shader)
- Bonus tablosu §3'teki Evet/Yok matrisiyle birebir. Capital ve Orbit bonus almaz.
- Farklı türlerin katkıları toplanır: üzerinde +1, yakınında +0.5. Örnek: Dağ üzerinde ve Volkanik Alan yakınında = 2.5x.
- **Binalara coğrafya çarpanı artık uygulanmıyor.** Yalnız district tabanı etkileniyor.
- Windy Region kaldırıldı. Enerji merceğindeki rüzgâr çizgileri de kapatıldı.
- Krater artık yalnız Ay'da. Ay'a **Mağaralar** ve **İyon Fırtınası Bölgesi** eklendi; shader'da çiziliyorlar (koyu çukurlar ve mavi-mor parıltı).
- Özel bina, district'in coğrafyanın **tam üzerinde** olmasını istiyor (§3.2).

### District'ler
- City District → **Capital District**: 2 kr, 1 bilim, 600 nüfus, 1 enerji, 2 mineral. Uzman tabanları: Commercial 10, Science 5, Residential 3000, Energy 5, Production 10.
- Capital'in mineral payı, gezegen ilk Production district'i veya madenle keşfedilene kadar beklemede kalır. Keşif akışı bozulmadı.
- Production district'in görünen adı "Production District" oldu.

### Destek hesabı (`Economy.scope_bonus`)
- `(1 + City destekleri) × (1 + gezegen destekleri)`. Aynı ölçekteki yüzdeler toplanır. 100 × 1.2 × 1.1 = 132.
- §7.2: district ve bina ipuçları artık desteksiz değeri gösteriyor. City ekranına "Supports +X%" etiketi eklendi; ipucunda kaynak bazında destek öncesi + destek = sonuç yazıyor. Orbit panelinde "Planet support" satırı var.

### Orbit (§6)
- Eski Space Station türü **Orbit City** oldu (Orbit'in merkezi). Capital ile aynı tabanı verir, bina tutmaz.
- 5 yeni district: Orbital Residential, Commercial, Science, Energy, Production. Her biri 600 kr, 250 çalışan, 1 enerji/sn ve gezegene +10% verir. Destek içindeki binalardan bağımsızdır. Slot sayısı 3 + 2 × (seviye − 1). Orbit kapasitesi seviye + 1.
- Orbital Production kendi depo paketini ekler: 1000 / 150 / 150 / 75.
- Prefab paketleri: 3 Low-rise, 3 Market, 3 Field Lab, 3 Solar Array; Production için Quarry + Ore Sorting + Warehouse. District ile birlikte mevcut tekrar fiyatıyla ödenir. Örnek: Orbital Production toplam 1450 kr. Paket satın alındığı anda inşaya başlar.
- Interstellar Port tanımlı ama `min_civilization = 1`, demoda gizli. Ekonomi değeri uydurulmadı.
- Orbit district'leri seviye atlayabilir. Yol komşusu kuralı uygulanmaz; seviye nüfusu normal district gibi.

### Spaceport ve final roket
- Tier 3, 2500 kr, T3 paketi, 250 çalışan, 0 enerji, 12 sn. Ay dahil her gezegende kurulabilir, gezegen başına 1.
- Rocketry 900 bilim. Final roket artık **Ay'daki normal Spaceport'u** arıyor; eski kayıttaki Lunar Spaceport da kabul ediliyor. Tutorial görevi buna göre güncellendi.

### Araştırma ağacı (`SkillTree.gd`)
- Bütün bina araştırma bedelleri ve önkoşulları tablolarla eşleşiyor. Örnek: Mine 75, Goods Factory 100, Solar Matrix 150, Compact Fuel 450, Ay üçlüsü 900.
- "Herhangi bir Tier 1 …" koşulları birden fazla parent ile kuruldu (parent'lardan biri yeterli).
- Kaldırılan düğümler: Orbit kolları (Zero-G, Mirrors, Shipyard, Offworld), Ay kolları, Ore Sorting, Consumer Goods, Advanced Excavation, Ridge Winds, Shallow Heat, Logistics, Advanced Coordination ve 3 Capital köprüsü.
- Eski kayıtta bu düğümler alınmışsa yüklemede düşer (yeni bina vermiyorlar).
- Yeni düğümler: River Extraction, Geothermal Drilling, Volcanic Mining, Rare Refining, Cavern Refining, Antimatter Power, Forest Homes, Desert Habitats, Crater Habitats, Lakeside/Ice Trade, Forest/Desert/Ion Research.
- Bazı eski kimlikler kayıt uyumu için yeni rolle kullanıldı: `fusion_power` = Fission Power, `coastal_living` = Mountain Terraces, `harbor_trade` = Volcanic Trade, `fuel_storage` = Bulk Storage, `surface_excavation` = Mining.
- Ağaç yerleşimi elle düzeltildi. Headless kontrolde 0.52 ızgara biriminden yakın düğüm kalmadı.

### Diğer
- Tutorial: Habitat Block → Low-rise Housing, Research Lab → Field Lab (artık ikisi de araştırma istiyor). Spaceport ve Orbit metinleri güncellendi.
- Eski üretici Python betikleri (`create_buildings.py` vb.) çalıştırılınca çıkış yapıyor (§19.6), yeni kataloğu ezemezler.

## 3. Yorum gerektiren noktalar — lütfen kontrol edin

1. **City'nin bedava 15.000 nüfusu korundu.** Belge Capital district tabanına 600 nüfus yazıyor ama City'nin ayrı 15K konutundan söz etmiyor. Belge City ile Capital'i ayrı nesne sayıyor, bu yüzden 15K'yı "değiştirilmeyen sistem" kabul edip üstüne 600 ekledim. Designer 15K'yı kaldırmak istiyorsa: `BalanceConfig.city_base_pop = 0`.
2. **Kıyı / göl / nehir binaları artık "tam üzerinde" istiyor.** Bu çizgiler bir hücre ince olduğundan Tidal Generator, Coastal Apartments, Lakeside Market ve River Extractor için yer bulmak zorlaşabilir. Playtest'te sorun çıkarsa tek satır: `FeatureMap.EDGE_NEAR_OK = true`.
3. **District'in coğrafyası artık yalnız kendi konumundan okunuyor.** Önceden City'nin coğrafyası da district'e taşınıyordu ("City'nin konumu dahil").
4. **Konum (proximity / mesafe) etkileri binalarda korundu.** Belge yalnız coğrafyayı binalardan kaldırıyor.
5. ~~Orbit district kuruluşu roket animasyonu kadar sürüyor.~~ 31.10'da değişti (§8): artık normal district gibi süre sayıyor; animasyon onu izliyor.
6. **Orbit district fiyatı sabit 600 + prefab.** Tekrar artışı yok; bu mevcut davranış.
7. **"Sıvı deniz" yalnız Terran dünyalar** olarak yorumlandı. Ice dünyaların kıyısı var ama Tidal kurulamıyor.
8. **Ay coğrafyaları** `PlanetData.Type.MOON` tipindeki gövdelerde oluşuyor.

## 4. Yapılmayanlar / kalanlar

- **Oyuncunun kendi prefabını kaydedip seçmesi (§6.3) yapılmadı.** Bu yeni bir UI özelliği. Varsayılan paketler çalışıyor.
- Üst kaynak çubuğundaki "kim ne üretiyor" dökümü bina oranlarını hâlâ destek dahil gösteriyor; toplam gerçek akışla tutarlı.
- Excel güncellenmedi. Belgedeki görevlerden biri değildi.

## 5. Test ve dikkat

- Oyun oynatılmadı, oyun içi test yapılmadı.
- Godot 4.7 **headless** ile yalnız şunlar yapıldı: import ve sınıf önbelleği yenileme, değişen 14 betiğin derlenmesi (hepsi temiz), katalog sayım ve fiyat kontrolü, araştırma grant ve parent bütünlüğü (hata yok), ağaç çakışma taraması.
- **Önemli:** İlk iki headless çalıştırma (00:50 ve 00:53) GameState'in çıkışta otomatik kaydetmesi yüzünden gerçek kayıt dosyanızı (`~/Library/Application Support/Godot/app_userdata/Voidle/voidle_save.dat`) **yeni kodla yükleyip yeniden kaydetti.** Bunu önceden fark etmedim. Sonuç: o kayıttan, kaldırılan araştırma düğümleri düştü. Bu branch'te etkisi yok; ama eski branch'e o kayıtla dönerseniz o düğümler eksik olur. Çalıştırmalardan önce yedek almamıştım. 00:53 sonrası hâli şurada yedekli: `/private/tmp/claude-501/-Users-sasete-Projects-iBright-Voidle/4652e759-68b4-4b7b-89a4-e060bff8028b/scratchpad/voidle_save_after_headless_0053.dat`. Sonraki çalıştırmada dosyayı önce kopyalayıp sonra geri koydum, aynen kaldı.
- Playtest için yeni oyun önerilir. Eski kayıtlar yüklenir, ama eski Space Station'lar ve emekli binalar yeni dengeyle karışık bir tablo verir.

## 6. Designer playtest kontrol listesi

1. Yeni oyun: Capital 600 + City 15K nüfus. Low-rise, Market, Solar, Field Lab ve Quarry araştırmasız açık mı?
2. Production district kurulunca mineral keşfi oluyor mu? (Capital'in 2 mineral payı ondan önce sayılmamalı.)
3. Capital'e iki Research Directorate kur: City ipucunda +20% görünmeli; district ve bina ipuçlarında görünmemeli.
4. Dağ üzerindeki Science district 2x, Dağ + Volkanik yakını Production 2.5x mı? Lens ipucu her coğrafyayı +100% / +50% olarak listeliyor.
5. Spaceport, Orbit City, Orbit district ekleme: prefab binaları geliyor mu, toplam fiyat doğru mu (Orbital Production 1450 kr)? "Planet support" satırı.
6. Ay: krater, mağara ve iyon bölgeleri görünüyor mu? Ay'a özel üç bina yalnız tam üzerinde mi kuruluyor? Ay'da Spaceport sonrası final roket.
7. Kıyı ve nehir binalarının yer bulma zorluğu (§3 madde 2).

## 7. Önerilen commit mesajı

```
Integrate the building / district / geography decisions of 2026-10-29
```
(Ayrıntılı gövde, `git commit` sırasında bu raporun §2'sinden alınabilir.)

## 8. Ek değişiklikler (2026-10-31, kullanıcı isteği)

1. **Rüzgâr çizgileri geri geldi.** Windy Region coğrafya olarak yok, ama Energy merceğinde rüzgâr akıntıları yine çiziliyor. Artık yalnız **Dağ ve Tundra** hücrelerinde, atmosferi olan dünyalarda (Wind Turbine'in kurulabildiği yerler) görünüyorlar. Rüzgârlı yerlerde daha yoğunlar ve her uygun hücrede en az biraz akıntı var (`FeatureMap.WIND_LENS_MIN = 0.45`).
2. **Orbit roket animasyonu inşa ilerlemesine bağlandı.**
   - Orbit district'leri (Orbit City dahil) artık yüzey district'leri gibi `ProductionManager` içinde ilerliyor.
   - Süre `construction_duration × ORBIT_BUILD_TIME_MULT` (1.25). Orbit district'lerinin süresi 15 sn yapıldı, yani yaklaşık 19 sn; yüzeydekiler 15 sn.
   - Belgedeki "Orbit district 4 sn" değerini kullanıcının "diğer district gibi" isteği geçersiz kıldı.
   - Uçuş sürenin %85'i (`ORBIT_LAUNCH_SHARE`), yörüngeye yerleşme %15'i.
   - Animasyon kendi saatini değil district'in ilerlemesini okuyor. İnşa hızı tek yerden değişiyor (`ProductionManager.district_build_speed()`); bunu hızlandırınca roket de hızlanıyor.
   - Yan fayda: roket uçarken kayıt alınıp yüklense de district tamamlanıyor. Eskiden animasyon kaybolunca district yarım kalabiliyordu.

## 9. Yeni mekanikler (2026-10-31): Relics, Planetary Tags, News

Hepsi veri tabanlı. Sayılar ve metinler dosyanın başındaki tablolardan değiştirilebilir. Oyun içinde test edilmedi; yalnız headless derleme ve küçük bir mantık testi yapıldı.

### Planetary Tags (`scripts/game/PlanetTags.gd`)
- Her dünyada iki sabit pill var: **boyut** ve **atmosfer**. Bunlar yalnız bilgi verir. Atmosfer ipucu Wind Turbine şartını hatırlatır.
- Trait'lerin etkisi açıkça yazıyor ("+10% Science"). Etki gezegen ölçeğinde, Orbit desteğiyle birlikte sayılır (`Economy.planet_bonus`).
- **Dünya** "Cradle World" (+10% housing) trait'iyle başlar; eski kayıtlara da yüklemede eklenir.
- **Diğer dünyalar** scan edilince 3 kart çıkar (survivors tarzı seçim ekranı) ve oyuncu birini seçer. "Later" ile ertelenebilir; o zaman üstte "CHOOSE A PLANET TRAIT" butonu ve gezegen panelinde "+ Choose a trait" pill'i kalır.
- **Planet level 3 ve 5** birer ek seçim verir (`BONUS_LEVELS`).
- Teklifler kayda yazılır, yeniden yükleyerek kartları değiştirmek mümkün değil.
- 13 trait var. Bazıları karışık etkili ("+15% Science · −5% Credits"), üçü yalnız Ay / çorak dünyalarda çıkar.
- Eski tür bazlı modifier'lar ("Fertile Soil +2" vb.) artık gösterilmiyor. Ekonomideki tek etkileri (Ay'ın +30% maden çarpanı vb.) kaldırıldı. **Not:** bu, Ay madenciliğini %30 azaltır. Telafi istenirse Ay'ın trait havuzunda Regolith Seas (+15% hammadde) var.

### Relics (`scripts/game/Relics.gd`, `scripts/ui/GameOverlays.gd`)
- Toplam **5 relic** var, sırayla bulunuyor:
  1. **The First Compass** — Dünya, Old Ruins içinde. +5% Credits her yerde. 250 Science.
  2. **The Selene Seal** — Ay. District'ler %25 daha hızlı kurulur (Orbit roketi dahil; `district_build_speed()` hook'una bağlı). 600 Science.
  3–5. Arid, Ice ve Volcanic dünyalarda: Rust Tablet (+5% raw & processed), Frost Choir (+5% Science), Ember Heart (+5% enerji). Demoda ulaşılamazlar; müzede "???" ve ipucu olarak görünürler.
- Haritada nabız atan altın renkli bir işaret var. Tıklanınca hikâye kartı açılıyor, Science ile "EXCAVATE" ediliyor. Bulunan relic'in bonusu ve **sonraki relic'in ipucu** gösteriliyor.
- Sıradaki relic'in işareti, öncekisi bulunduktan ve dünyası scan edildikten sonra görünüyor.
- **Ay'da Old Ruins yok** (coğrafya kararına dokunmadım). Ay relic'i bu yüzden bir Krater'in içinde.
- Bonuslar `Economy.scope_bonus` içinde City ve gezegenden sonra üçüncü, global ölçek olarak çarpılıyor.
- **Museum:** sol paneldeki kısayol satırına kütüphane ikonlu bir buton eklendi. 5 slotu gösteriyor: bulunanlar (bonus + hikâye), sıradaki (ipucu), bilinmeyenler.

### News (`scripts/system/NewsFeed.gd`, yeni autoload `NewsFeed`)
- Ekranın altında, sol panel ile sağ kenar arasında kayan bir haber şeridi var.
- **Olay haberleri** (altın, "◆"): district kuruldu, bina açıldı (6 sn içindekiler tek haberde toplanıyor), araştırma bitti, City seviye atladı, gezegen seviyesi, mineral keşfi, trait seçildi, relic bulundu, lander ve final roket.
- **Flavour haberleri** (gri): oyuncunun kendi City ve district adlarıyla 20 şablon, ayrıca 4 genel satır. Bekleyen olay yoksa 6 sn arayla geliyor. Örnek: "Three workers lost their lives in an accident at {district}…"
- Herhangi bir koddan haber eklenebilir: `NewsFeed.post("…")`.
- Lens çubuğu, şeridin üstünde kalsın diye 30 px yukarı alındı.

### Açık sorular
- Relic kazı bedeli yalnız Science. "Yakında district olmalı" gibi bir şart eklenebilir.
- Trait değerleri (+10% / +15%) ve relic bonusları (+5%, %25 hız) ilk tahmin; denge geçişi gerekir.

### Düzeltmeler (2026-10-31, ilk deneme sonrası)
- **Donma düzeltildi.** Relic işaretinin nabız animasyonu `_draw()` içinden `queue_redraw.call_deferred()` çağırıyordu. Godot 4'te `queue_redraw` da ertelendiği için bu tek karede sonsuz döngüye giriyordu. Döngü, Dünya'daki relic işareti görününce (harita kurulunca) başlıyordu. Yeniden çizim artık `POILayer._process` içinden yapılıyor.
- **News şeridi** artık tam genişlikte ve NEWS etiketi sağda. Şerit view'in left panel'inin hemen altında çiziliyor; panel üstüne açılıyor, şerit kaymıyor. Left panel olmayan view'lerde şerit kendi katmanında duruyor.
- **News boş kalmıyor.** Haberler arka arkaya akıyor, aralarında "◈" ayırıcı var. Bekleyen olay yoksa yerine bir flavour haber (artık 28 tane) ya da canlı durum satırı geliyor (hazine, Science, nüfus/kapasite, enerji dengesi, City/district sayısı). Son 8 dolgu haberi hemen tekrar etmiyor.

## 10. 30.10 playtest düzeltmeleri (2026-10-31)

Kararlar: Science geliri ×0.25 (`BalanceConfig.science_income_mult`). Logistics Center depo vermiyor; Orbital Production deposunu koruyor. Tekrar fiyatında kredi ve malzeme birlikte artmaya devam ediyor. Final roket için Ay Spaceport'u sorusu açık.

**Kritik**
- **Upgrade tree dolanması:** yalnız ana parent'a çizgi çekiliyor, alternatifler tooltip'te "Requires one of". Tooltip'teki fiyat artışı açıklamaları kaldırıldı.
- **FPS** (statik inceleme; oyun içinde profillenemedi):
  - `BuildingDef.find` sözlükten O(1) arama yapıyor.
  - `Location` imzası kare başına bir kez hesaplanıyor (önceden her bina, her kare için gezegendeki tüm district'leri tarıyordu).
  - `_district_poi` etiket indeksini kullanıyor.
  - Destek çarpanları kare başına gezegen başına tek geçişte hesaplanıyor.
  - **Oyun içinde FPS'i doğrulayın**, hâlâ düşüyorsa profil gerekir.
- **Kendini güncellemeyen bina listesi:** imzada "para yetiyor" ve "nüfus yetiyor" ayrı bitler oldu. Kredi yetince satır artık açılıyor.
- **Ferrite %** her yerden kaldırıldı.

**Sol panel ve okunabilirlik**
- Yeni `MarqueeLabel`: minimum genişliği 0. Sığmayan içerik ileri geri kayıyor. `ListItem` başlığı ve istatistik satırı bunun içinde; sol panel artık içeriğe göre genişlemiyor, uzun başlık maliyet rozetinin altına girmiyor.
- **District paneli**
  - "District Income" satırı çarpılmış üretimi gösteriyor; altında binaların toplamı ("Buildings").
  - Tooltip yalnız district'in kendi kaynağının coğrafyasını ve konumu açıkça listeliyor: Neighbours, City centre, Room to grow.
  - Başlıktaki coğrafya etiketleri kalktı.
- **City paneli:** başlık etiketleri kalktı. "Next level" ve "Supports" artık satır olarak duruyor. Capital en üstte, altında ayırıcı çizgi var.
- **Gezegen paneli:** Orbit en üstte, altında ayırıcı çizgi var.
- **Yerleştirme tooltip'i**
  - Başlıkta o noktanın coğrafyası yazıyor ("Coast" yerine örneğin "River · Forest").
  - "Makes here" satırında üretim, bu district'in kendi coğrafya çarpanları ve sade konum satırları var.
  - "Site 3x" ve km satırları kalktı.
- **Seviye tooltip'i** çarpanı ve kaynak bazında şimdiki → sonraki değeri gösteriyor.
- **Üst kaynak çubuğu**
  - Tüm dünyaların ortak geliri gösteriliyor.
  - Tooltip'te kaynak kaynak + ve − dökümü var.
  - Raw geliri artık tüketimi de düşüyor.
  - Ferrite satırının tooltip'i çalışıyor.
  - Hücreye tıklayınca Trade açılıyor.
- Gülen surat yerine çalışan ikonu. City ile Capital ikonu arasına boşluk eklendi.
- Sol panel kayarken işaretler artık aynı karede yer değiştiriyor (gecikme yok).
- **Tooltip kilidi:** fare 1.6 sn kıpırdamazsa halka doluyor ve tooltip yerinde kalıyor. Üstüne gidilebiliyor, dışarı çıkınca kapanıyor. İç içe terim tooltip'leri henüz yok.
- Upgrade tree açıkken lens tooltip'i artık araya girmiyor.

**Lens ve harita**
- Lens çubuğu her zaman görünüyor: tutorial'sız oyunda ve City kurarken de.
- Her coğrafyanın kendi lens rengi var; lens açıkken çubuğun üstünde renk açıklaması çıkıyor.
- Normal görünümde fareyle üstüne gelince o noktanın coğrafyası yazıyor.
- Terran dünyalarda her zaman biraz Dağ ve Jeotermal yarık oluşuyor (eşik, dünyanın kendi en yüksek dilimi). Ay'ın Krater, Mağara ve İyon bölgeleri büyütüldü.
- Yollar aynı kara parçasında da daha kısaysa deniz rotasını kullanıyor (`RoadNetwork.LAND_ONLY_SAME_LANDMASS`).

**Diğer**
- **Binalar**
  - Bina listesi ve kurulmuş binalar sıralı: çıkarma → işleme → depo, grup içinde yüksek tier üstte.
  - Stack sabit, unstack ve "Stack" kutusu kalktı.
  - Keşfedilmemiş mineral isteyen binalar listede gri görünüyor ve nedenini yazıyor.
- **District ve Orbit**
  - İnşa halindeki district kartında CANCEL butonu var.
  - Yörüngedeki Orbit City'e tıklayınca Orbit paneli açılıyor. Orbit district'lerinin 250 çalışanı listede görünüyor.
  - Orbit district satırında prefab tier seçimi var (− T0 +); yalnız araştırılmış tier'ler seçilebiliyor, fiyat anında güncelleniyor.
- **Spaceport:** kendi City'sine her şeyde +5% veriyor. Wonder olsun mu, karar açık.
- **Final roket:** hazırlanırken ve hazırken kartında "PICK TARGET IN SOLAR SYSTEM" butonu var. Roket hazırlanmaya başlayınca güneş sistemi görünümü açılıyor.
- **Free population geliri:** kaynak tooltip'inde "Idle population" satırı olarak görünüyor, oradan doğrulanabilir.

**Sonraya kalanlar**
- Force Buy (Trade güncellemesiyle birlikte).
- Oto-satış değişikliği (Trade güncellemesi).
- İç içe tooltip terimleri.
- Demo bitiş sekansı (designer tasarlayacak).
- Ay Spaceport zorunluluğu (soru bekliyor).

## 11. Trade ekranı (2026-10-31)

- **Konum:** Panel solda, sol panelin sütununda, üst çubuğun altından haber şeridine kadar. Oyunun geri kalanı yanında kullanılabiliyor; görünümler fareyi yalnız panelin üstündeyken yok sayıyor (`TradePanel.covers`).
- **Satır düzeni:** `[ikon] stok │ fiyat grafiği │ satış/alış fiyatı │ [hedef][mod] │ [SELL][BUY]`. İkonun tooltip'i ürünün adını, referans fiyatını ve stoğunu gösteriyor.
- **SELL / BUY:**
  - Tıklama bir lot (fiyatı tamamen oynatan miktarın yaklaşık %1'i), Shift ×10, Ctrl/Cmd hepsi.
  - Tooltip'te üç seçeneğin de miktarı ve kredisi yazıyor.
- **Otomasyon** (Trade Automation araştırmasıyla): tek bir hedef alanı ve kare bir mod butonu.
  - Modlar: Off / Sell until / Buy until / Keep it at.
  - Keep it at, hedefin ±%5 bandında ticaret yapmıyor.
  - Otomatik işlemler elle yapılandan %10 kötü fiyatla yapılıyor (`BalanceConfig.trade_auto_penalty`).
  - Otomasyon bir turda (20 sn) fiyatı en fazla %5 oynatıyor; böylece fiyatı sürekli aşağı çekemiyor.
  - Depo taşması artık yalnız Sell veya Keep modundaki ürünlerde satılıyor; diğerlerinde taşan kısım kayboluyor.
  - Eski kayıtlardaki otomasyon emirleri Off olarak açılıyor.
- **Fiyat geçmişi:** 5 sn'de bir kayıt, son 6 dakika. Satırdaki küçük grafik referansı noktalı çizgiyle gösteriyor; çizgi referansın üstündeyse turuncu, altındaysa yeşil. Geçmiş kayda yazılıyor.
- **Haberler:** Fiyat referansın 1.5 katına çıkınca ya da 0.6 katına düşünce, her sert harekette bir kez, tooltip'li bir haber çıkıyor.
- **Force Buy:** Trade Automation'dan sonra gelen yeni araştırma, 300 Science.
  - Bina listesinde yalnız malzeme eksikse tooltip "Force Buy: X cr" gösteriyor.
  - Satırın üstündeyken F'ye basınca eksik malzemeler alınıp bina kuruluyor.
  - Log'da "force buy" olarak görünüyor.
- **Kaldırılanlar:** Eski "Reserve" alanı arayüzden kalktı. Kod tarafında duruyor; elle satış eski kayıtlardaki rezervlere hâlâ uyuyor.

### Trade, ikinci tur (2026-10-31)
- **Sol panelin içinde:** Trade artık sol panelin kendi içeriği. `LeftPanel.show_overlay` paneli sola kaydırıyor, içeriği Trade ile değiştiriyor ve geri kaydırıyor. "‹ BACK" veya Esc aynı animasyonla önceki içeriğe dönüyor.
  - Görünümün içeriği bu sırada yalnız gizleniyor. Görünüm araya yeni içerik kurarsa o da gizli kalıyor.
  - Panel kapalıyken Trade açılırsa panel Trade'i göstermek için açılıyor, BACK'te eski durumuna dönüyor.
  - Sol paneli olmayan görünümlerde (Galaxy) aynı sütunda yüzen panel olarak açılıyor.
- **Sabit düzen:** Panel içeriğe göre genişlemiyor. Satırdaki her öğe sabit boyutta: ikon kutusu 24, grafik 58, fiyat 92, hedef 52, mod 24, SELL/BUY 50. Araştırma ya da fiyat değişince hiçbir şey kaymıyor.
- **Kilitli ürünler:** Satır aynı düzende kalıyor; soluk görünüyor ve üstünde etkileşimi kesen bir "Research …" bandı var. Trade Automation yokken hedef ve mod alanları duruyor, yalnız etkileşime kapalı.
- **Satır içeriği:** İkon kare bir item kutusunda. Fiyat kredi ikonuyla "satış / alış" birim fiyatı olarak gösteriliyor, eğilim yüzdesi tooltip'te. Stok ve limitler kalktı (üst çubukta var).
- **Fiyat dalgalanması:** Her ürüne yaklaşık ±%3'lük, kendi kendine geri dönen bir gürültü eklendi (`Trade.NOISE_SIZE`, `NOISE_PULL`). Fiyatları ve grafiği etkiliyor, kayıttaki baskıya yazılmıyor.
- **Performans:** PlanetaryView sol paneli her karede yeniden konumluyordu; artık yalnız HUD yüksekliği değişince konumluyor.
- **Tek fiyat:** Trade satırı tek bir piyasa fiyatı gösteriyor (`Trade.unit_price`). Alım ve satım aynı fiyattan yapılıyor: `trade_sell_ratio` ve `trade_buy_ratio` 1.0, yani satış/alış farkı yok. Büyük işlemler fiyatı işlem boyunca kaydırıyor; otomasyon %10 ceza ödüyor.
- **Lot:** Deponun yaklaşık %5'i kadar (Science'ta stoğun), 1-2-5 dizisine yuvarlanmış: 200'lük depoda 10, 1K'da 50, 10K'da 500, 100K'da 5K. Shift ×10, Ctrl/Cmd hepsi. Oyuncuya yalnız miktar gösteriliyor (`TradePanel.LOT_SHARE`).
- **Sıkıştırılmış satır:**
  - Ölçüler: ikon 22, grafik 42, fiyat 50, hedef 42, mod 22, SELL/BUY 40, aralık 4.
  - Butonlar iç boşluğu kırpılmış düz butonlar; tema boşluğu yüzünden genişlemiyorlar.
- **SELL/BUY tooltip'i:**
  - İçerik: "You pay / You get" ve "You give / You get", büyük ve renkli. Ödenen kırmızı, alınan kaynağın ya da kredinin renginde.
  - Shift veya Ctrl/Cmd basıldığı anda güncelleniyor.
  - Yapılamıyorsa nedenini yazıyor: satacak bir şey yok, depo dolu ya da kredi yetmiyor.
- **İşlem geçmişi** panelden kaldırıldı; `GameState.trade_log` kaydetmeye devam ediyor.
- **Borsa göstergesi:**
  - NEWS etiketinin yanında küçük bir kutu. Her 2.5 sn'de bir ürün gösteriyor: ikon, fiyat ve son bir dakikadaki değişim (yeşil ▲ / kırmızı ▼ ve %).
  - Üstüne gelince tüm liste çıkıyor, tıklayınca Trade açılıyor.
  - Trade Access yokken gizli.

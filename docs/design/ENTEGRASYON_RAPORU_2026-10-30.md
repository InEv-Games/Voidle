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
5. **Orbit district kuruluşu roket animasyonu kadar sürüyor (~20 sn), 4 sn değil.** Görsel akışı bozmamak için dokunmadım.
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

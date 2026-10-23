# Büyük güncelleme: ana uygulama planı

Bu plan GDD'yi, [KARARLAR.md](KARARLAR.md)'deki kararlarımızı, [denge raporunu](BALANCE_RAPORU.md) ve [denge uygulama planını](BALANCE_UYGULAMA_PLANI.md) tek bir iş sırasında birleştirir. Bir konuda çelişki varsa KARARLAR geçerlidir.

Tarih: 21 Ekim 2026

## Çalışma kuralları

- **Her kilometre taşı oynanabilir bir oyun bırakır.** Yarım kalmış sistem başka bir kilometre taşına taşınmaz.
- **Sayılar tek yerden okunur.** Bütün denge değerleri M0'da kurulan `BalanceConfig` profillerinden gelir. Arayüz, satın alma, önizleme ve üretim aynı fonksiyonları çağırır.
- **Oyuncu eylemleri komut olarak yazılır.** Kur, yükselt, yık, taşı, Güncelle, buyout gibi her eylem `can_execute` / `preview` / `execute` adımları olan bir komuttur. Arayüz yalnızca komut çağırır.
- **Görme izni ile oynama izni ayrıdır.** Showcase için eklenen `can_view_*` fonksiyonları M0'da genişletilir; demo sonrası inceleme de aynı yolu kullanır.
- **Test:** Godot'u ve oyunu sen çalıştırırsın. Her teslimde değişen davranış, dokunulan dosyalar, kalan sınırlamalar ve "neyi denemelisin" listesi raporlanır.
- **Kayıtlar:** M0'da yeni kayıt sürümüne geçilir. Eski kayıtlar silinmez, yeni ekonomiye taşınmaz; eski sürümlü kayıt için ana menü "uyumsuz kayıt" der.

## Tamamlananlar

| İş | Durum |
|---|---|
| Tasarım belgeleri repoda (`docs/design/`) | ✓ |
| KARARLAR.md (girdi, district fiyatı, nüfus, offline, Ay, sağ tık, oranlar, fraktal ağaç) | ✓ |
| Denge raporu ve denge uygulama planı | ✓ (denge ekibinde inceleniyor) |
| Orbital'e erişim düzeltmesi (FOUND CITY listesinde gri Orbit satırı ve neden) | ✓ kod, oyunda denenmedi |
| Showcase → **Explore modu**: ana menü tuşu kaldırıldı; tutorial bitince HUD'daki "◎ Explore" ile oyunun içinden salt-okunur harita turu, ESC / RETURN ile ana gezegene dönüş, ekonomi arkada çalışır (cheat console `showcase on/off` duruyor) | ✓ kod, oyunda denenmedi |
| Navigation HUD (geri/ileri geçmişi, breadcrumb); sağ tık gezinmeden ayrıldı | ✓ kod, oyunda denenmedi |
| M0.1 Denge profilleri: `BalanceConfig`, `Balance` autoload, `profile_current` / `report_A` / `report_B`, console `balance` | ✓ kod, oyunda denenmedi. Kayda profil adının yazılması M0.2'de |
| M0.2 Kayıt sürümü: `save_version` (mevcut kayıtlar v1), uyumsuz kayıt yüklenmez/üzerine yazılmaz/NEW GAME'de yedeklenir, kayıt denge profilini taşır, **yüklemede başlangıç bütçesinin krediyi ve kilitleri ezmesi düzeltildi** | ✓ kod, oyunda denenmedi. İşlem kimlikleri ilk ihtiyaç duyan adımda (M4/M5) eklenecek; M1'de `SAVE_VERSION` 2'ye çıkacak |
| M1 (1. parça): açık cezası süre yerine çıktıya; sabit girdiler (Goods/Fuel/Rare tesisleri Ferrite yakar, mineral seçimi kalktı); bütün bina ve district döngüleri 20 sn (dakikalık hızlar korunarak) | ✓ kod, oyunda denenmedi |
| M1 (2. parça): mineral erişimi medeniyet tipine bağlı (R1–2 Tip 0 …), `min_hop` ve yoğunluk/yerel yatak çarpanı kalktı, ilk hammadde üreticisiyle gövde keşfi, keşif öncesi mineral adları gizli; `civilization_type` alanı eklendi | ✓ kod, oyunda denenmedi. MINERALS lensi hâlâ eski yoğunluk görselini kullanıyor (M2'de rol butonlarıyla kalkacak) |
| M1 (3. parça): isimli malzeme bedelleri (tier 2: 30 Ferrite + 5 Goods; tier 3: 90 Ferrite + 15 Goods + 5 Fuel + 2 Rare; profilde, modelde geçersiz kılınabilir) ve toplu alım (Shift ×5, Ctrl/Cmd azami) tek `_buy_buildings` yolundan | ✓ kod, oyunda denenmedi |
| M2 (1. parça): km mesafe (`Location.gd`), yolsuz yakınlık (aynı tür çok yakın +%10 / yakın +%5, sınırsız), City merkez katkısı, 5 kademeli uzaklık bonusu; bina çıktıları district'in konum çarpanını alıyor; sabit komşu geliri kalktı (yol şartlı seviye kapısı 22 Ekim'de kullanıcı kararıyla geri kondu) | ✓ kod, oyunda denenmedi. Yerleşim aralıkları görsellere bağlı olduğu için eski derecede kaldı (GDD: 250 km / 3000 km) |
| M2 (2. parça): görünür arazi — `FeatureMap` 14 özelliği üretir (orman, çöl, tundra, volkan, nehir, göl kenarı, deniz kıyısı, dağ, ova, buzul, jeotermal yarık, rüzgârlı bölge, eski yerleşim, krater); shader'lar aynı ızgarayı çizer; üzerinde tam / 250 km yakında yarım bonus (profildeki tablo); City'nin özellikleri district'lere aktarılır (özellik başına bir kez); rüzgâr/tidal/jeotermal/gözlemevi/kıyı binaları özellik şartına bağlandı, yatak şartı kalktı; özellikler district'e kaydedilir | ✓ kod, oyunda denenmedi. Lens çubuğu hâlâ eski sürekli alanları gösteriyor (3. parçada rol butonlarıyla değişecek) |
| M2 (3. parça): lens çubuğu (Terrain/Minerals/Geothermal/Solar/Wind/Tidal) kaldırıldı; yerine 5 rol butonu (Energy/Population/Production/Science/Commercial) — rolün bonus aldığı özellikler iki kademede (düz ≥ +%30, noktalı ≥ +%10), FeatureMap ile aynı veri | ✓ kod, oyunda denenmedi. Yer önerisi butonu (en fazla 3 öneri + gerekçe) henüz yok |
| M3.1 Bina kataloğu: GDD §12 değerleri (20 sn), büyük modeller 2 yuva, işçiler T1 250 / T2 750 / T3 2.250 / küçük 125, konut 0; Capital destekleri +%10; T3 + Moonstone bedelleri (Particle, Luxury, Planetary Command +60, Commodity +90); Tier 4 Tip 0'da kapalı (`min_civilization`); keşfedilmemiş mineral isteyen modeller gizli; 14 yeni model (Shallow Geothermal Well, Ridge Turbine, Surface Quarry, Ore Sorting Workshop, Compact Fuel Workshop, Regolith Goods Plant, Fuel Depot, Field Observatory, Lunar Sample Lab, Low-rise Housing, Coastal Apartments, Modular Moon Habitat, Local Trade Center, Lunar Supply Market); district tabanları GDD | ✓ kod, oyunda denenmedi. Yeni modeller geçici olarak mevcut skill düğümlerine bağlı (M3.2'de yeniden dağıtılacak) |
| M3.2 Canonical skill ağacı: GDD §17 kimlikleri (86 düğüm, 14 coğrafya uzmanlığı dahil), ANY ebeveyn + `requires`/`access`/`events` şartları, ortak yol 6.500 Science (Rocketry 600, Lunar Program 1.200; gezegen seviyesi ve Shipyard kapıları kalktı), çapraz dal zammı (%2/düğüm, profilden), Lv3 bonuslar, etkin seviye = max(alınan, miras), eski 54 kimliğin kayıtta dönüşümü (§17.23), boş nüfus gelirleri (Sivil Girişimler, Serbest Araştırma, Üretim Rezervi), Küme Planlama / Bağımsız Merkezler / Karma Ağlar / Coğrafya Uzmanlığı etkileri, Yakıt Süreçleri, Capital destekleri iki hak istiyor, Ay'da çıkarılan Moonstone sayacı, satın alma `research_command` | ✓ kod, oyunda denenmedi. Orbital düğümler KARARLAR §5 gereği Tip 0'da alınabilir (GDD'de Tip 1). Geri Kazanım, Yerleşim Düzenleme, Ticaret Erişimi/Otomasyonu ve İnşaat Organizasyonu satın alınabiliyor ama etkileri M3.3/M5'te gelecek |
| M3.3 Trade: `Trade.gd` (sabit referans fiyatlar, satış %90 / alış %110 profilden; Science dahil; keşfedilmemiş mineral görünmez; Fuel/Rare araştırma ister), Ticaret Erişimi sonrası taşma satışı (`GameState.add_resource`), oyuncu rezervleri, Ticaret Otomasyonu emirleri (20 sn'de önce satış sonra alış), son işlemler kaydı; HUD'da **⇄ Trade** butonu ve `TradePanel` | ✓ kod, oyunda denenmedi. M0.4 kaynak defteri yok; işlemler doğrudan stok/kredi üzerinden |
| M4 Ay yolu: sefer durum makinesi (`GameState.expeditions`: preparing → ready → in_transit → arrived); lander 3.000 cr + 40 Ferrite + 20 Fuel, 30 sn hazırlık + 30 sn uçuş, Dünya Spaceport şartı (Shipyard yok); Ay'da ilk Production +30 Ferrite; `lunar_spaceport` binası (8.000 cr + 200 Moonstone + 50 Goods + 30 Fuel + 10 Rare, 2 yuva, Ay Capital); son roket 12.000 cr + 1.200 Moonstone + 30 Goods + 120 Fuel + 40 Rare, 60 sn hazırlık + 60 sn uçuş; hedef SolarView sağ tık; varış → `civilization_type = 1`, `demo_completed`, `playable_content_type = 0`; eski "Ay'da ilk City = Act I" tetiklemesi kaldırıldı; dev console `rocket` | ✓ kod, oyunda denenmedi. Roket uçuşu haritada çizilmiyor (Ay sayfasında durum ve süre görünüyor) |
| M5 Yerleşim yönetimi: `Settlement.gd` + sağ tık komutları (bina adedi kaldır, içeriği temizle, Lv1'e sıfırla, yık, taşı); N/C iade defteri (bina yığını `paid`, district `paid_credits`, seviye `level_paid`), iade %50 / %65 / %75; taşıma Yerleşim Düzenleme ister, bedel ödenmişin %10'u, City district'leriyle birlikte taşınır; onay penceresi (`ConfirmPanel`) önizleme gösterir | ✓ kod, oyunda denenmedi. Güncelle komutu yok (Tip 0'da hazır plan yok). Eski kayıtlarda bina yığınının ödenmiş bedeli taban fiyattan tahmin ediliyor, district kabuğu 0 sayılıyor |
| M6 Fraktal ağaç: Tip 1 ağacı (önizleme) — merkez düğüm `civilization_0_tree` Tip 0 ağacını temsil eder; Tip 0 ağacının tepesindeki Civilization 1 düğümüne çift tık Tip 1 ağacını, Tip 1 merkezine çift tık Tip 0 ağacını açar; merkezin altında buyout butonu = eksik bütün düğüm ve seviyelerin bugünkü toplamı (çapraz dal zammı dahil); buyout `inherited_levels` yazar; demoda kilitli | ✓ kod, oyunda denenmedi. Tip 1 ağacında yalnız 5 aile rol düğümü + Orbital Storage önizlemesi var |
| M7 Görevler ve demo sonu: hedef paneline Ay yolu zinciri (11 adım, ödülsüz, "Main goal: reach Civilization 1"), panel daraltılabilir ve kısa liste gösterir, skip yalnız öğretici görevleri atlar; öğretici/görev hibeleri kapalı (`GRANTS_ENABLED`), yeni oyun bütçesi profile_current'ta 3.000 cr / 450 Science (GDD §3); demo sonu ekranı fraktal toplanma animasyonuyla; demo sonrası bütün haritalar görülebilir, diğer gezegenler oynanamaz (`can_play_on`) | ✓ kod, oyunda denenmedi |
| M8 Offline: kayıt `saved_at` tutar; yüklemede 60 sn'den uzun aradan sonra "Welcome back — X süre" ekranı; kazanç yok, anahtar `Balance.cfg.offline_progress_enabled` (kapalı) | ✓ kod, oyunda denenmedi |
| M0.5'in ilk hali: `GameCommand`, `CommandRegistry`, `ContextMenu`; City/district/istasyon/yüzey/gezegen/sistem/yıldız için varsayılan eylemler | ✓ kod, oyunda denenmedi. `preview()` ve gemi menüsünün bu sisteme taşınması M0.5'te kalıyor |

## Kilometre taşları

| | Kilometre taşı | Özet | Bağımlılık |
|---|---|---|---|
| M0 | Altyapı | Denge profilleri, kayıt sürümü, medeniyet/erişim durumu, kaynak defteri, komut sistemi, ölçüm paneli | — |
| M1 | Ekonominin çekirdeği | 20 sn döngü, sabit girdiler, nüfus/enerji açığı, boş nüfus geliri, keşif, yeni eğriler, toplu alım | M0 |
| M2 | Konum | km mesafe, 14 arazi, yolların ekonomiden çıkması, yakınlık, rol butonları | M1 |
| M3 | İçerik | Bina kataloğu, canonical skill ağacı, trade | M1 (M2 ile paralel olabilir) |
| M4 | Ay yolu | Lander, Ay ekonomisi, 100 Moonstone, Lunar Spaceport, gelişmiş roket, Tip 1 geçişi | M3 |
| M5 | Yerleşim yönetimi | Sağ tık menüsü: yık, temizle, sıfırla, Güncelle, taşı | M0, M2 |
| M6 | Fraktal ağaç | Merkez düğüm, önceki ağaca iniş, buyout | M3 |
| M7 | Görevler ve demo sonu | Görev paneli, başarımlar, demo bitişi, demo sonrası inceleme | M4, M6 |
| M8 | Offline | "Sen yokken" ekranı, tek anahtar | M1 |
| M9 | Denge turu | Denge ekibi profili, ölçümler, ayar | Her kilometre taşından sonra sürekli |

---

## M0: Altyapı

Görünür oyun değişikliği azdır. Sonraki bütün işler buradaki yapıları kullanır.

### M0.1 Denge profilleri (BALANCE_UYGULAMA_PLANI B0, B1)
- `scripts/game/balance/BalanceConfig.gd` (Resource, `@export_group` ile gruplanmış alanlar) ve `scripts/game/balance/Balance.gd` (statik erişim `Balance.cfg` ve eğri fonksiyonları: `geometric`, `geometric_sum`, `max_affordable`).
- Bugünkü sabitler taşınır: `Economy.gd`, `DistrictDef.gd`, `Leveling.gd`, `PlanetProgress.gd`, `ProductionManager.gd`, başlangıç kredisi. Tam liste BALANCE_UYGULAMA_PLANI'nda.
- Profiller: `resources/balance/profile_current.tres` (bugünkü değerler), `profile_report_B.tres`, `profile_report_A.tres`.
- Aktif profil `voidle/balance/profile` ayarından ve cheat console'daki `balance <profil>` komutundan seçilir. Kayıt dosyası profil adını yazar.
- **Denenecek:** `profile_current` ile oyun öncekiyle aynı sayıları göstermeli.

### M0.2 Kayıt sürümü (GDD P03)
- Kayda `save_version` alanı eklenir. Ana menü uyumsuz sürümü tanır: CONTINUE devre dışı kalır ve nedeni yazar. Eski dosya silinmez, yeniden adlandırılıp saklanır.
- 3.000 kredi + 450 Science yalnızca gerçek yeni oyunda verilir. Kayıt yüklemek başlangıç değerlerinin üzerine yazmaz.
- İşlem kimlikleri (inşaat, sefer, buyout) kayda girer; aynı iş iki kez çalışmaz.

### M0.3 Medeniyet ve erişim durumu (GDD P01)
- `GameState`: `civilization_type`, `playable_content_type`, `demo_completed`.
- `act1_complete` ve `act1_completed` sinyali bu alanlara bağlanır. Ay'da ilk City artık son olay değildir; M4'te son varışa taşınır.
- Showcase'teki `can_view_solar/galaxy/moon` fonksiyonları genişletilir: `can_view(scope)`, `can_play(content)`, `can_research(node)`, `can_settle(body)`. Görme izni showcase **veya** demo sonrası durumdan, oynama izni `playable_content_type`'tan gelir.
- `solar_unlocked` / `galaxy_unlocked` / `moon_unlocked` bayrakları bu fonksiyonların arkasına gizlenir. Doğrudan okuyan kod kalmaz.

### M0.4 Kaynak defteri (GDD P04)
- Bütün ekleme ve harcama tek kapıdan geçer: `Ledger.add(id, amount, source)`, `Ledger.spend(costs: Dictionary, reason) -> bool`, `Ledger.can_afford(costs)`, `Ledger.reserve/release`.
- `GameState.spend_credits`, `consume_resource`, `add_resource`, `earn_credits`, `add_science` bu kapıya yönlendirilir.
- Maliyetler artık her yerde `Dictionary` (örneğin `{credits: 300, ferrite: 30, goods: 5}`). Trade (M3) ve offline (M8) bu kapıya bağlanır.

### M0.5 Komut sistemi ve sağ tık menüsü
- Gemi tarafında zaten bir radyal menü ve `ShipCommandRegistry` var. Bu yapı genelleştirilir:
  - `scripts/commands/GameCommand.gd`: `can_execute() -> String` (boşsa yapılabilir; değilse neden), `preview() -> Dictionary` (bedel, iade, değişen kapasite/çıktı), `execute() -> bool`.
  - `scripts/commands/CommandRegistry.gd`: hedef türüne (bina, district, City, gezegen, gemi) göre uygun komutları listeler.
- Sağ tık menüsü hedefe uygun komutları gösterir. Yapılamayanlar gri olur ve nedeni tooltip'te yazar.
- İlk komutlar mevcut eylemlerin taşınmasıdır: bina kur, district kur, City kur, district/City/gezegen seviye atlat. Yık, Güncelle ve taşı M5'te eklenir.
- Sağ tık yalnızca eylem menüsüdür; geri/ileri ve üst seviye `NavigationManager` HUD'ındadır (tamamlandı). Şimdilik sağ tıkta yalnızca gemi menüleri var; yerleşim eylemleri bu adımla eklenir.

### M0.6 Ölçüm paneli (BALANCE_UYGULAMA_PLANI B5)
- Geliştirici modunda açılan denge paneli ve `user://balance_logs/` CSV kaydı. Gelir kaynakları dağılımı, sıradaki alımı karşılama süresi, nüfus/enerji karşılama oranı, alım geri ödeme süreleri, kilometre taşı zamanları.
- Denge ekibi bunu M0'dan sonra mevcut oyunda bile kullanabilir.

---

## M1: Ekonominin çekirdeği

### M1.1 Ortak 20 saniyelik döngü (GDD P06)
- Bina tanımlarına `cycle_inputs`, `cycle_outputs`, `capacity_effects` alanları. Mevcut 30/60 sn değerler dakikalık hız korunarak çevrilir.
- Döngü sırası: biten inşaatlar → girdileri ayır (yalnız beslenebilen adetler başlar) → kapasite/enerji/nüfus → çıktı (verim çarpanıyla) → bir kez teslim.
- Kartlar aynı veriden "−4 Ferrite → +2 Goods / 20 sn" gösterir. Kapasite veren binalarda stok satırı yerine kapasite yazar.

### M1.2 Sabit girdiler (KARARLAR §1)
- Her bina modeli tek ve sabit bir tarife sahiptir. Ferrite ve Moonstone kullanan işleme binaları ayrı modellerdir.
- Nadirlik verimi modelin kendi çıktı değerine gömülür. Otomatik en nadir harcama ve genel `raw` cüzdanı kaldırılır. Depo sınırları hammadde türü başına tutulur.

### M1.3 Nüfus ve enerji (KARARLAR §3)
- Nüfus maliyetleri mevcut yapıda kalır, ölçekleme katsayıları `BalanceConfig`'ten gelir.
- Açık durumunda süre uzamaz, çıktı düşer: `taban + (1 − taban) × karşılama`. Taban, `pop_deficit_floor` / `energy_deficit_floor` profil değeri (başlangıç 0,5).
- Boş nüfus geliri: Sivil Girişimler, Serbest Araştırma, Üretim Rezervi skill'leri. Oranlar ve City tabanının sayılıp sayılmayacağı profilden okunur (denge ekibi kararı bekliyor).

### M1.4 Gövde mineralleri ve keşif (GDD P05)
- Her gövdenin mineral kümesi. Yoğunluk haritası ve `min_hop` kaldırılır.
- İlk uygun Production tamamlanınca mineral keşfedilir ve kalıcı olur. Keşiften önce ad, ikon ve fiyat gizlidir.
- `ResourceMap` mineral yoğunluğu ekonomik hesaptan çıkar.

### M1.5 Fiyat, seviye ve yuvalar (GDD P08, BALANCE B2)
- Tekrar fiyatları ve seviye eğrileri profilden okunur. Bina sayacının kapsamı (`DISTRICT_ALL` / `MODEL`) da profil alanı; denge ekibi seçecek.
- District kurma sayacı bugünkü mantıkla kalır (türe bakmaz), oran profilden gelir.
- Bina seviye yükseltmesi kaldırılır (`BuildingDef.get_upgrade_cost` yolu kapanır).
- Büyük binalar 2 yuva kaplar ve tek, büyük bir kart olarak görünür.
- İsimli malzeme bedelleri ("30 Ferrite + 5 Goods").
- Seviye çıktısı binaları da kapsar (`level_output_mode = GEOMETRIC`). Kredi eğrileri bununla birlikte ayarlanır (denge raporu §4.2).
- Kredi iadesi için N/C edinim defteri burada başlar (M5 kullanır): her bina grubu kaç adet olduğunu ve toplam gerçek ödenen krediyi tutar.

### M1.6 Toplu alım (BALANCE B3)
- `×1 / ×5 / Doldur / Azami`. Shift ve Ctrl kısayolları. `BuildCommand` önizlemesinde toplam bedel ve adet.

**M1'de denenecek:** Döngü kartları doğru giriş/çıkışı gösteriyor mu; açıkta çıktı mı düşüyor; ilk Production Ferrite'ı keşfediyor mu; toplu alım fiyatı tek tek almakla aynı mı?

---

## M2: Konum (GDD P09, P10, P18'in bir kısmı)

- Mesafe dereceden km'ye geçer. Beş etiket ve bonuslar profilde: %0 / %12,5 / %25 / %37,5 / %50.
- 14 görünür arazi türü (`TerrainSampler` ekranla ekonomi için ortak kaynak). Üzerinde tam, 250 km kuşakta yarım bonus. Aynı arazi türü City ve district üzerinden iki kez sayılmaz.
- Yollar ekonomide konum bonusu vermez; komşu geliri kaldırılır. **Yol bağımlı seviye şartı korunur** (kullanıcı kararı, 22 Ekim): Capital dışındaki district, yolla bağlı bir komşusu hedef seviyedeyse seviye atlar. Capital için yol şartı yoktur.
- Yakınlık: yakındaki her uygun kaynak katkı verir. Tavan veya azalan pay profil seçimidir (`proximity_mode`, `proximity_cap`); denge ekibi karar verecek.
- Performans için konum hücreleri; hesap kuruluş, yıkım ve taşımada güncellenir.
- Eski lens çubuğu kalkar, yerine rol butonları gelir (Energy / Population / Production / Science / Commercial). Öneri butonu en fazla üç yer önerir ve nedenini yazar.

**Denenecek:** Bir district dağın üstünde ve dağın yakınında farklı bonus alıyor mu; yol olmadan yakınlık çalışıyor mu; zoom mesafeyi değiştiriyor mu?

---

## M3: İçerik

### M3.1 Bina kataloğu (GDD P11)
- GDD §12 ile KARARLAR'daki sabit girdi kuralı birlikte uygulanır. Moonstone isteyen Dünya ve Ay modelleri eklenir.
- Tier 4 tanımları (Antimatter, Quantum, Arcology, Central Bank) Tip 0'da kapatılır.
- Konut değerleri GDD'ye çekilir. Kodda 2,5–13 kat yüksekler; denge raporunun en büyük uyarılarından biri.
- Mine ve Lab GDD değerlerine çekilir.

### M3.2 Canonical skill ağacı (GDD P12)
- Düğümlerin kalıcı kimlikleri, `minimum_civilization`, `legacy_eligible`, ANY ebeveynler ve ek fiziksel koşullar (`gate`).
- Ortak yol toplam 6.500 Science. Fuel ve Rare erken açılır; gezegen seviyesi kapıları kalkar.
- Eski 54 kimlik yeni kimliklere eşlenir (GDD §17.23).
- Etkin seviye: `max(kendi alınan, miras)`. Bonus hesapları bu tek değeri okur.
- Ağacın merkez düğümü bu aşamada "medeniyet kökü" olarak yer tutar. Davranışı M6'da gelir.
- Satın alma `ResearchCommand` olur.

### M3.3 Trade (GDD P13, P14)
- Sabit fiyatlar, satışta %90, alışta %110 (profilden). Science alınıp satılabilir. Araştırması açılmış işlenmiş ürün fabrikası olmadan alınabilir.
- Ticaret Erişimi'nden sonra depo dolunca fazlası krediye çevrilir; öncesinde kaybolur.
- Ticaret Otomasyonu: rezerv üstü satış ve hedef stok alışı. Roket için ayrılan stok satılmaz.
- Hepsi M0.4'teki kaynak defterinden geçer.

---

## M4: Ay yolu (GDD P19, P20; KARARLAR §5)

1. Rocketry → Dünya Spaceport (Capital Lv2'de 2 yuva). Shipyard şartı ve gezegen Lv3 kapısı kalkar.
2. Lunar Program → **Ay lander** (3.000 kredi + 40 Ferrite + 20 Fuel; 30 sn hazırlık + 30 sn uçuş). Mevcut `moonlaunch` akışı ve lander animasyonu yeniden kullanılır.
3. Ay'da ilk City ücretsiz; ilk Production (300 kredi + 30 Ferrite) Moonstone'u keşfeder.
4. **100 yerel Moonstone sayacı:** yalnızca gerçek üretim olaylarıyla ilerler; trade ile alınan saymaz.
5. Ay Malzemeleri araştırması → Lunar Spaceport (Ay Capital Lv2).
6. Gelişmiş Gezegen Roketi araştırması → roket (isimli bedel, 60 sn hazırlık).
7. Hedef seçimi SolarView'da yapılır; hedefe varınca `civilization_type = 1`, `demo_completed = true`, `playable_content_type = 0`.
8. Orbital ana yoldan ayrılır ama çalışan isteğe bağlı içerik olarak kalır (Orbit City ve istasyonlar).
- Eski gemi/Shipyard kapıları `ShipManager` ve `SpaceportLogic`'ten temizlenir. Genel filo sistemi ana yolun şartı olmaz.

**Denenecek:** Ay'a Shipyard kurmadan gidilebiliyor mu; trade ile alınan Moonstone sayaca eklenmiyor mu; varış bir kez mi işleniyor?

---

## M5: Yerleşim yönetimi (sağ tık; GDD P15, P16, P17)

Hepsi M0.5'teki komut sistemiyle, nesne üzerinde sağ tık menüsünden yapılır.

| Komut | Hedef | Not |
|---|---|---|
| Adet kaldır | bina grubu | N/C defterinden payı düşer; iade %50 (Geri Kazanım I/II ile %65/%75) |
| İçeriği temizle | district, City | Kabuk, ad, yer ve seviye kalır |
| Sıfırla | district, City | Aynı kimlik, Lv1 |
| Yık | district, City, gezegen yerleşimi | Bütün alt ağaç tek işlemle; çift iade yok; doğal gövde silinmez |
| Güncelle | district, City | Yeni açılan içerik için gerçek bedelli fark teklifi; elle sabitlenmiş nesnelere dokunmaz |
| Taşı | district, City (Tip 0) | Yerleşim Düzenleme skill'i; eski/yeni bonus önizlemesi; hizmet bedeli %10 + hedefteki fiyat farkı |

Her komutun önizlemesi kaldırılacakları, iadeyi, kaybolacak kapasite ve üretimi gösterir. Onaydan önce koşullar yeniden denetlenir; fiyat değiştiyse yeni teklif gösterilir.

---

## M6: Fraktal skill ağacı (KARARLAR §8)

- Her medeniyetin ağacının **merkez düğümü bir önceki ağacı temsil eder**. Merkez düğüme çift tıklayınca kamera o ağaca iner; geri çıkmak için sağ tık veya ESC. Özyinelemeli çalışır.
- Merkez düğümün altında **buyout fiyatı**: önceki ağaçtaki eksik skill ve seviyelerin tam toplamı. İndirim de sabit fiyat da yok.
- Buyout bir `BuyoutCommand`'dır. Önizleme açılacak hakları ve oluşacak Güncelle tekliflerini listeler. Bina, keşif veya sefer vermez.
- **Demoda:** Tip 1 ağacı ve buyout yalnızca önizlemedir; satın alma `can_research` tarafından engellenir.
- `SkillTreeView` mevcut pan/zoom'u kullanır. Ağaç verisi medeniyet bazında tutulur (`minimum_civilization`).
- Denge ekibine açık soru: farklı dallardan alım yapınca gelen fiyat zammı buyout toplamına girsin mi?

---

## M7: Görevler ve demo sonu (GDD P21, P23)

- Sürekli, daraltılabilir görev paneli. Ana görev "Tip 1'e ulaş"; ara görevler Ay yolunun adımları. Ekonomik ödül yok.
- Tutorial'ın kredi, Science ve Ferrite hibeleri kaldırılır. Tutorial metni ayrı bir iş olarak bekler.
- Başarımlar gerçek adet ve olaylara bağlanır; her olay bir kez kaydedilir.
- Demo sonu: varış ekranı kapatılabilir, ekonomi durmaz. Fraktal toplanma animasyonu oynar.
- **Demo sonrası inceleme showcase altyapısını kullanır:** `can_view` demo tamamlanınca bütün haritaları açar, `can_play` kapalı kalır. Fark şu: showcase'te ekonomi durur ve arayüz gizlenir; demo sonrasında Dünya ve Ay ekonomisi çalışmaya devam eder ve arayüz görünür.

---

## M8: Offline (KARARLAR §4)

- Kapalı geçen süre kaydedilir. Girişte "Sen yokken: X saat geçti" ekranı gösterilir.
- Ekonomik kazanç yok. Tek anahtar: `offline_progress_enabled` (profil alanı, varsayılan kapalı).
- İleride kazanç açılırsa M1'deki döngü motoru zaman atlamasını aynı kodla işler. İkinci bir offline ekonomisi yazılmaz.

---

## M9: Denge turu

- Denge ekibinin önerisi `profile_team_vN.tres` olarak eklenir.
- Değişiklikler `BALANCE_DEGISIKLIKLERI.md` dosyasına işlenir. Kesinleşen değerler KARARLAR'a taşınır.
- Ölçüm paneli ve CSV kayıtları her kilometre taşından sonra kullanılır.

---

## Sonraya kalanlar

- Tip 1'in 50 district'i ve Host/Rol matrisi (GDD P25–P29). M0'daki erişim alanları ve M3'teki ağaç yapısı buna hazır kurulur.
- Gökada, Evren ve Paralel Evrenler görünümleri. Şu an yalnızca Galaxy, Yıldız sistemi ve Gezegen ekranları var.
- Tip 2–5 oynanabilir içeriği.
- Offline kazanç kararı.
- Tutorial metninin yeniden yazılması ve narrative.

## Bekleyen kararlar

| Karar | Kimde | Etkilediği yer |
|---|---|---|
| Paket A mı B mi (seviye çıktısı ×1,25 / ×1,20) | Denge ekibi | M1.5 |
| Bina tekrar sayacı: district geneli mi, model bazında mı | Denge ekibi | M1.5 |
| District oranı (öneri 1,30) | Denge ekibi | M1.5 |
| Boş nüfus geliri oranı ve City tabanının sayılması | Denge ekibi | M1.3 |
| Açık tabanı (öneri 0,5) | Denge ekibi | M1.3 |
| Yakınlık: tavan mı, azalan pay mı | Denge ekibi | M2 |
| Buyout'a çapraz dal zammı girsin mi | Denge ekibi | M6 |

Kararı bekleyen her değer profil alanı olarak kurulduğu için, cevap gelmeden kod yazılabilir. Cevap gelince yalnız profil değişir.

## İlk adım

M0.1 (denge profilleri) ve M0.2 (kayıt sürümü). İkisi de birbirinden bağımsız. Oyunda görünür değişiklik yapmadıkları için denge ekibinin geri bildirimini beklemeleri gerekmez.

# Denge uygulama planı

[BALANCE_RAPORU.md](BALANCE_RAPORU.md) önerilerinin koda nasıl geçirileceği. Denge ekibinin geri bildirimi gelince yalnız **değerler** değişecek; bu plan, o değişikliğin kod yazmadan yapılabilmesini hedefler.

Tarih: 21 Ekim 2026. Durum: plan. Kod henüz değiştirilmedi.

## Temel ilke

Geri bildirim gelmeden kodu bu sayılara kilitlemiyoruz. Önce bütün denge sayılarını **tek bir veri kaynağına** taşıyoruz. Sonra farklı değer setlerini (mevcut, rapor A, rapor B, denge ekibinin önerisi) **profil** olarak tutup oyun içinde aralarında geçiş yapabiliyoruz. Geri bildirim uygulamak bir profil dosyasını düzenlemekten ibaret olur.

---

## B0: Sabitlerin tek yerde toplanması (davranış değişmez)

### Hedef yapı

- `scripts/game/balance/BalanceConfig.gd`: `Resource` sınıfı. Her denge sayısı `@export` alanı, gruplar `@export_group` ile ayrılır. Böylece denge ekibi değerleri Godot inspector'ında kod açmadan düzenleyebilir.
- `resources/balance/*.tres`: profiller.
- `scripts/game/balance/Balance.gd`: statik erişim (`Balance.cfg`) ve ortak eğri fonksiyonları:
  - `geometric(base, growth, n)` → `base × growth^n`
  - `geometric_sum(base, growth, k, n)` → toplu alım toplamı
  - `max_affordable(base, growth, k, money)` → azami adet
- Arayüz, satın alma, önizleme ve üretim aynı fonksiyonları çağırır. Hiçbir ekran kendi formülünü hesaplamaz.

### Taşınacak sabitler

| Şu anki yer | Sabit / formül | BalanceConfig alanı |
|---|---|---|
| [Economy.gd:196](../../scripts/game/Economy.gd) | `BUILD_COST_GROWTH = 1.35` | `building_cost_growth` |
| Economy.gd:200 | bina sayacı: district'teki bütün binalar | `building_counter_scope` (`DISTRICT_ALL` / `MODEL`) |
| Economy.gd:207–214 | `CITY_BASE_POP`, `DISTRICT_POP`, `LEVEL_POP_BASE`, `MAX_DISTRICT_LEVEL` | `city_base_pop`, `district_found_pop_base`, `level_pop_base`, `max_district_level` |
| Economy.gd:218 | kuruluş nüfusu `3.000 × (1 + 0,5k)` | `district_found_pop_step` |
| Economy.gd seviye nüfusu | `2.000 × 2^(L−1)` | `level_pop_growth` |
| Economy.gd:249 | `MAX_POP_SLOWDOWN = 0.5` | `pop_deficit_floor` |
| [ProductionManager.gd:26](../../scripts/game/ProductionManager.gd) | `MAX_ENERGY_SLOWDOWN = 0.5` | `energy_deficit_floor` |
| ProductionManager.gd:408 | `ISOLATION_MAX`, `ISOLATION_RANGE_DEG` | `distance_bonus_max` vb. (Faz 3'te km'ye geçecek) |
| [DistrictDef.gd:77](../../scripts/game/DistrictDef.gd) | `level_mult = 1 + 0,5(L−1)` | `level_output_mode` (`LINEAR` / `GEOMETRIC`), `level_output_growth` |
| DistrictDef.gd:136–139 | `DISTRICT_BASE_COST`, `DISTRICT_COST_GROWTH`, `CITY_BASE_COST`, `CITY_COST_GROWTH` | aynı adlarla |
| [Leveling.gd:27](../../scripts/game/Leveling.gd) | district seviye kredisi `400 × 2,2^(L−1)` | `level_credit_base`, `level_credit_growth` |
| Leveling.gd:69–77 | City seviye eşiği `1,5·n(n−1)`, kredi `1.500 × 2,5^(n−2)`, nüfus `4.000(n−1)` | `city_level_req_mode`, `city_level_credit_*`, `city_level_pop_*` |
| Leveling.gd:109 | Orbit seviye kredisi `city × 1,2` | `orbit_level_credit_mult` |
| Leveling.gd:146 | gezegen eşiği `2n − 1` | `planet_level_req_*` |
| [PlanetProgress.gd:82](../../scripts/game/PlanetProgress.gd) | gezegen kredisi `8.000 × n`, `250 × n` ham | `planet_level_credit_*`, `planet_level_material_*` |
| [BuildingDef.gd:225](../../scripts/game/BuildingDef.gd) | bina seviye yükseltme `× 1,5^(L−1)` | taşınmaz; GDD'ye göre kaldırılacak (Faz 2) |
| GameState.gd:55, :716 | başlangıç kredisi 500 | `start_credits`, `start_science` |
| SkillTree.gd | araştırma fiyat formülü | `research_level_mode`, `research_cross_branch` |
| `resources/buildings/*.tres` | bina tabanları | `.tres` dosyalarında kalır (zaten veri). Toplu ölçek için `building_cost_scale`, `housing_scale` çarpanları. |

Henüz kodda karşılığı olmayan, sonraki fazlarda eklenecek alanlar da baştan tanımlanır, böylece profil dosyaları ileride değişmez:

- boş nüfus: `idle_pop_credits_per_1000`, `idle_pop_science_per_1000`, `idle_pop_counts_city_base`, `idle_pop_uses_level_mult`
- yakınlık: `proximity_very_near`, `proximity_near`, `proximity_cap`, `proximity_mode` (`FLAT` / `TIERED`)
- miras: `legacy_base`, `legacy_growth`, `legacy_missing_share`
- trade: referans fiyatlar, `trade_sell_ratio` (0,9), `trade_buy_ratio` (1,1)
- `offline_progress_enabled`

### Teslim ölçütü
`profile_current.tres` mevcut değerlerin aynısını taşır. Oyun B0'dan önce ve sonra **aynı sayıları** gösterir. Bunu oyunda sen doğrularsın.

---

## B1: Profiller ve canlı değiştirme

- `resources/balance/profile_current.tres`: bugünkü oyun.
- `resources/balance/profile_report_B.tres`: raporun ilk test için önerdiği paket.
- `resources/balance/profile_report_A.tres`: GDD'ye daha sadık paket (seviye çıktısı ×1,25).
- Denge ekibinin önerisi geldiğinde: `profile_team_v1.tres`.
- Aktif profil `ProjectSettings` üzerinden seçilir (`voidle/balance/profile`). DevConsole'a `balance <profil>` komutu eklenir.
- Kayıt dosyası hangi profille oynandığını yazar. Böylece test raporları karışmaz.

---

## B2: Mevcut yapıya oturan eğriler

Bunlar bugünkü sistemleri değiştirmeden yalnız sayıları değiştirir. B0'dan sonra profil B'de hemen denenebilir.

| Konu | Mevcut | Profil B |
|---|---|---|
| Bina tekrar oranı | 1,35 | 1,08 |
| District kurma | 300 × 1,6ⁿ | 300 × 1,30ⁿ (türe bakmayan sayaç korunur) |
| City kurma | 0; 2.500 × 2,5^(c−2) | 0; 2.000 × 1,6^(c−2) |
| District seviye kredisi | 400 × 2,2^(L−1) | 300 × 1,8^(L−1) |
| District seviye nüfusu | 2.000 × 2^(L−1) | 1.500 × 1,5^(L−1) |
| District kuruluş nüfusu | 3.000 × (1 + 0,5k) | 2.000 × (1 + 0,25k) |
| City seviye kredisi | 1.500 × 2,5^(n−2) | 1.200 × 1,8^(n−2) |
| City seviye eşiği | 1,5·n(n−1) | n(n+1)/2 |
| City seviye nüfusu | 4.000(n−1) | 3.000 × 1,3^(n−2) |
| Gezegen seviyesi | 8.000n + 250n ham | 2.500 × 1,8^(n−2) (+ GDD malzemeleri Faz 2'de) |
| Başlangıç | 500 kredi | 3.000 kredi + 450 Science |

**Dikkat.** Seviye çıktısı bugün yalnız district tabanını ve doğrusal (`1 + 0,5(L−1)`) büyütüyor. Rapor, maliyetin çıktıdan ~1,5 kat hızlı büyümesi kuralını geometrik çıktıya (×1,20) göre kurdu. Bu yüzden B2'deki seviye kredileri **bugünkü doğrusal çıktıyla** fazla ucuz kalabilir. `level_output_mode` alanı bunun için var: profil B'de `GEOMETRIC 1,20`'ye geçiş, binaları da kapsayan çıktı değişikliğiyle (Faz 2) birlikte açılır. O zamana kadar B2 testinde seviye çıktısı modu ayrıca not edilir.

---

## B3: Toplu alım

- Raporun makaleden aldığı formüller `Balance.gd`'de:
  - maliyet `b × r^k × (r^n − 1)/(r − 1)`
  - azami adet `floor(log_r(c(r−1)/(b·r^k) + 1))`
- Bina yuvası kartında: `×1 / ×5 / Doldur / Azami`. Shift ve Ctrl ile kısayol.
- Satın alma, Faz 1'deki komut sistemine (`BuildCommand` + `preview`) bağlanır. Önizlemede toplam bedel ve kaç adet alınacağı görünür.
- Yuva, nüfus ve enerji sınırları azami adedi kısıtlar.

---

## B4: Sistem değişikliği gerektiren denge maddeleri

Bunlar ana [PLAN.md](PLAN.md) fazlarının içinde yapılır. Sayıları BalanceConfig'den okunur.

| Madde | Ana plan fazı | Rapor önerisi | Denge ekibinin kararı gerekli mi? |
|---|---|---|---|
| Seviye çıktısının binaları da kapsaması, geometrik büyüme | Faz 2 | ×1,20 (B) / ×1,25 (A) | Evet: A mı B mi? |
| Açıkta süre yerine çıktı düşüşü | Faz 2 | taban 0,5; açık süresi %30'u aşarsa 0,35 | Taban değeri |
| Boş nüfus geliri | Faz 2 | 1.000 boş nüfus başına +5 kredi/dk ve +1 Science/dk (GDD'nin yarısı), seviye çarpanı yok | Evet: oran ve City tabanının sayılıp sayılmayacağı |
| Bina seviye yükseltmesinin kaldırılması | Faz 2 | (GDD kararı) | Hayır |
| Konut değerlerinin GDD'ye çekilmesi (kodda 2,5–13 kat yüksek) | Faz 4 (katalog) | önce GDD değerleri | Hayır, ama boş nüfus geliriyle birlikte ölçülmeli |
| Mine / Lab zayıflığı | Faz 4 | GDD değerleri | Hayır |
| Yakınlık tavanı | Faz 3 | tavan +%100 veya azalan paylar (%10 / %5 / %2,5) | Evet: tavan mı, azalan pay mı? |
| District seviyesinde yol komşusu şartı | Faz 3 | GDD kaldırıyor | Hayır |
| Fraktal miras fiyatı | Faz 7 | `max(4.000 × 10^(t−1), 0,5 × eksik düğümlerin toplamı)` | Evet (demoda yalnız önizleme, acil değil) |
| Aile başına seviye çarpanı | ilk testten sonra | isteğe bağlı | İlk test sonucuna göre |

---

## B5: Ölçüm araçları

Denge testinin sayısal olması için:

- **Denge paneli** (yalnız geliştirici modunda, DevConsole'dan açılır):
  - aktif profil ve değerler
  - sıradaki en iyi alımı karşılama süresi
  - gelirin kaynak dağılımı: bina, district tabanı, boş nüfus, yakınlık, trade
  - nüfus ve enerji karşılama oranı
- **CSV kaydı** `user://balance_logs/`: her 10 saniyede gelir, Science/dk, kaynak payları, karşılama oranları. Her alımda tür, bedel ve geri ödeme süresi. Kilometre taşları: ilk City, Spaceport, Ay, Tip 0.
- Raporun §6.1'deki alarm eşikleri panelde renkle gösterilir. Örnekler: boş nüfus payı >%25, yakınlık payı >%40, açıkta süre >%30, büyük kararlar arası 3 dakikadan uzun boşluk.
- Oyunu değiştirmez, yalnız ölçer. Normal oyuncuya görünmez.

---

## B6: Geri bildirimin uygulanması

1. Denge ekibinin önerisi `profile_team_vN.tres` olarak eklenir. Yalnız sayılar değişiyorsa kod değişmez.
2. Sistem değişikliği isteyen öneriler (ör. yakınlık tavanının modu) B4 tablosundaki ilgili faza eklenir.
3. Her değişiklik `docs/design/BALANCE_DEGISIKLIKLERI.md` dosyasına işlenir: tarih, profil, değişen değer, gerekçe, hangi test ölçüsüne dayandığı.
4. Kararlaşan değerler KARARLAR.md'ye taşınır. Rapor ve profil geçmişi karar kaydı olarak kalır.

---

## Sıralama önerisi

| Adım | Ne zaman | Neden |
|---|---|---|
| B0, B1 | **Hemen**, ana plan Faz 1'den önce veya onunla birlikte | Küçük ve bağımsız. Sonraki her iş sayıları buradan okur. |
| B5 | B1'den hemen sonra | Denge ekibi mevcut oyunu ölçerek test edebilir. |
| B2 | Geri bildirim gelince (ya da profil B olarak hemen) | Yalnız sayı değişikliği. Bugünkü yapı Faz 2'de değişeceği için bu yapıya fazla ince ayar yapmamak gerekir. |
| B3 | Ana plan Faz 1'deki komut sistemiyle | Toplu alım bir satın alma komutu. |
| B4 | İlgili ana plan fazlarında | Sistem değişiklikleriyle birlikte. |
| B6 | Sürekli | Her geri bildirim turunda. |

## Denge ekibinden beklenen kararlar

1. Paket A mı B mi (seviye çıktısı ×1,25 ve kredi 1,9 / ×1,20 ve kredi 1,8)?
2. Bina sayacı: district'teki bütün binalar mı, model bazında mı? (Rapor 1,08'de etkisinin küçük olduğunu, model bazının KARARLAR §1 ile uyumlu olduğunu söylüyor.)
3. District oranı 1,30 uygun mu (bant 1,25–1,40)?
4. Boş nüfus geliri: yarıya indirme, seviye çarpanı olmaması, City'nin ücretsiz 15.000'inin sayılıp sayılmaması.
5. Yakınlık: +%100 tavan mı, azalan paylar mı?
6. Açık tabanı 0,5 ile mi başlansın?
7. Miras fiyat formülü (acil değil).

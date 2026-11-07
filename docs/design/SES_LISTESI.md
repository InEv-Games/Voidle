# Ses listesi

Tarih: 7 Kasım 2026
Kapsam: Oyundaki bütün ses çağrıları, bunların hangi anlarda çaldığı ve sesi olmayan anlar.
Girdiler:
- `scripts/**/*.gd` içindeki `AudioManager.play(...)` / `VAM.play(...)` çağrıları
- Oyun sinyalleri (`GameState`, `ShipManager`, `ProductionManager`, `NewsFeed`, `TutorialManager`)
- [VOIDLE_GDD.md](VOIDLE_GDD.md) §23 "Ses"

Sesler VAM event'i olarak `res://audio/events/` altında duruyor ve VAM sekmesinden düzenleniyor. Kullanım: [addons/VAM/README.md](../../addons/VAM/README.md).

**Öncelikler.**
- **P1:** Oyuncunun her oturumda gördüğü, şu an tamamen sessiz ya da yanlış sesli anlar.
- **P2:** Sık görülen ama bir sesle idare eden anlar.
- **P3:** Cila.

Önerilen event adları öneridir. Hiçbiri henüz yok.

---

## Özet

- **Mevcut:** 30 VAM event'i var:
  - 28 UI/SFX sesi
  - 1 ambiyans (`music/space_drone`)
  - 1 müzik (`music/main`)
- **Kullanım:** Kodda ~180 çağrı var. `ui/clink` ve `ui/poi_hover` hiç çağrılmıyor.
- **Aşırı yüklenmiş sesler:**
  - `sfx/building_done` 12 farklı anda çalıyor: bina bitişi, Ay'a iniş, roket seferi, demo sonu, oyun açılışı...
  - `ui/click` 68 yerde kullanılıyor: tıklama, panel açma, onay, iptal, lens seçimi hep aynı ses.
- **Hata:** Başarım kazanınca iki ses üst üste çalıyor (`ui/survey` + `ui/achievement`).
- **Hiç sesi olmayan yerler:**
  - Galaksi haritası
  - Asteroid kuşağı
  - Mission Builder
  - Popup'lar (açılma/kapanma)
  - Sahne geçişleri
  - Haber çubuğuna düşen mesajlar
  - Gemi varışı
  - Maden keşfi
- **Öneri:**
  - Yeni sesler: 9 P1, 16 P2, 8 P3 (§3)
  - Mevcut seslerde 6 düzeltme/bölme (§2)

---

## 1. Mevcut sesler

> **7 Kasım güncellemesi:**
> - Koddan üretilmiş geçici sesler (`res://audio/sfx/`) ve onları kullanan 15 event silindi.
> - Şu an event'i olanlar: `ui/click`, `ui/hover`, `ui/blink`, `ui/LeftPanel_Open`, `ui/LeftPanel_Close`, `music/main`, `music/space_drone`.
> - Event'i **olmayan, ama kodun hâlâ çağırdığı** id'ler (ses bekliyor): `ui/error`, `ui/cash`, `ui/level_up`, `ui/skill_buy`, `ui/survey`, `ui/tick`, `ui/clink`, `ui/district_hover`, `ui/poi_hover`, `ui/poi_ping`, `ui/poi_select`, `sfx/construct`, `sfx/construct_loop`, `sfx/rocket`, `sfx/building_done`.
> - Kod bunlardan birini çağırınca VAM Output'a o id için bir kez `unknown event` uyarısı yazar. VAM'de aynı id ile event oluşturup kendi sesini bağlayınca çalmaya başlar.
> - Aşağıdaki tablolar, hangi id'nin oyunda ne zaman çağrıldığını göstermeye devam ediyor.

### UI bus

| Event | Ne zaman çalıyor | Çağrı | Not |
| --- | --- | --- | --- |
| `ui/click` | Genel buton tıklaması: ana menü, HUD kısayolları (Skill/Trade/Explore), panel aç/kapa, onaylar, lens ve yörünge düğmeleri, kamera odağı, story dialog ilerleme, haber çubuğu, kayıt silme | 68 + 6 (`ui_click`) | En kalabalık ses. Bölünmesi önerilir, bkz. §2 |
| `ui/error` | Yetersiz kaynak ya da geçersiz eylem: district yerleştirme, level-up, bina satın alma, kilitli skill, trade ürünü, roket, şehir adı, iptal edilemeyen işlem | 34 | Doğru kullanılıyor |
| `ui/hover` | **Oyundaki bütün buton hover'ları** (etkin butonlar; disabled butonlar sessiz) ve **sol paneldeki bütün etkileşimli satır/kartlar**. Ayrıca slot dropdown satırları, maden kartları, skill ağacı düğümleri, ay ikonları, yörüngedeki gemiler | merkezi | `AudioManager._process` fareyi izler: fare yeni bir butona ya da sol panel satırına geçince bir kez çalar. Panel açılıp kapanırken ve fare durduğu hâlde içerik değişirken sessiz. Aynı karede bir kez |
| `ui/district_hover` | Sadece harita: gezegende district'e tıklama, yörünge katmanı | 2 | Panel satırları artık `ui/hover` |
| `ui/poi_hover` | Hiçbir yerde çağrılmıyor | 0 | Eski kullanıcıları (maden ızgarası, üretim çubuğu, slot kartı, dropdown) artık `ui/hover` |
| `ui/poi_select` | Yüzeyde POI seçme, gezegene tıklama | 4 | |
| `ui/poi_ping` | POI katmanında ping | 3 | |
| `ui/skill_buy` | Skill ağacında araştırma satın alma | 2 | |
| `ui/level_up` | Gezegen level-up popup'ı | 1 | |
| `ui/survey` | Asteroid taraması, survey popup'ı, **ve her başarım** (`AchievementManager._grant`) | 3 | Başarımda çift ses, bkz. §2 |
| `ui/achievement` | Başarım popup'ı, story bitişi | 2 | |
| `ui/tick` | Dev console yazı efekti, tutorial daktilo efekti | 4 | |
| `ui/blink` | Sol panel açılırken/kapanırken her satır titreyişinde (`LeftPanel._set_row`) | 1 (her blink) | 4 klip (`assets/sfx/LeftPanel-Blink1–4.wav`). 0.02 sn cooldown, max 4 kopya: aynı karede titreyen satırlar tek seste birleşir |
| `ui/LeftPanel_Open` | Sol panel açılmaya başladığında (`LeftPanel._apply_fade`) | 1 | `assets/sfx/LeftPanel-Open.wav` |
| `ui/LeftPanel_Close` | Sol panel kapanmaya başladığında; açılırken geri dönerse de (`LeftPanel._apply_fade`) | 1 | `assets/sfx/LeftPanel-Close.wav` |
| `ui/cash` | Kredi değiştikçe | sinyal | 0.25 sn cooldown, GDD'deki "yığılmaz" kuralı |
| `ui/clink` | Hiçbir yerde çağrılmıyor | 0 | Kullanılacak bir yer bulunmalı ya da silinmeli |

### SFX bus

| Event | Ne zaman çalıyor | Çağrı | Not |
| --- | --- | --- | --- |
| `sfx/construct` | İnşaat başlangıcı: district kurma, district/şehir level-up, taşıma, lander inişi, şehir kurma, bina satın alma, yörünge level-up | 9 | |
| `sfx/building_done` | Bina tamamlandı, **ayrıca:** şehir level-up, district spawn, trait slot, yüzey taraması bitti, Ay'a ulaşma, son roket seferi, story ilerleme/bitiş, demo sonu ekranı, oyun açılışı (`HUDManager._ready`) | 13 | Aşırı yüklü, bkz. §2 |
| `sfx/rocket` | Lander kalkışı, iniş, roket animasyonu | 3 | |
| `sfx/terrain_earth/water/sand/ice/fire/dust/gas` | Gezegen yüzeyine tıklama, arazi tipine göre (`PlanetaryView._spawn_terrain_hit`) | 1 (dinamik) | |
| `sfx/construct_loop` | İnşaat sürerken arka planda loop | 2 | |

### Music bus

| Event | Ne zaman çalıyor | Not |
| --- | --- | --- |
| `music/space_drone` | Oyun açılışından itibaren sürekli | Sentezlenmiş 55 Hz uğultu; `music/main`'in AMB katmanıyla üst üste çalıyor |
| `music/main` | Oyun açılışında: intro → loop1 → rastgele loop'lar, altta AMB | Ana menüde de aynı müzik çalıyor |

---

## 2. Düzeltilmesi ya da bölünmesi gerekenler

| Öncelik | Sorun | Öneri |
| --- | --- | --- |
| P1 | Başarımda `ui/survey` ve `ui/achievement` aynı anda çalıyor (`AchievementManager._grant` + `HUDManager._on_achievement_unlocked`) | `_grant` içindeki `survey` çağrısını kaldır |
| P1 | `sfx/building_done` demo sonu / medeniyet anında da çalıyor | Ayrı bir müzik stinger'ı: `music/stinger_act_complete` (§3) |
| P2 | `sfx/building_done` diğer anlarda da çalıyor | Ayrı sesler: `sfx/city_level_up`, `sfx/scan_complete`, `sfx/lander_touchdown` (Ay'a ulaşma), `sfx/rocket_final_launch` (son roket), `ui/story_advance`. Oyun açılışındaki çağrı kaldırılabilir; müzik intro'su zaten başlıyor |
| P2 | `ui/click` her şey için aynı | `ui/panel_open`, `ui/panel_close`, `ui/confirm`, `ui/cancel`, `ui/toggle` (lens/yörünge düğmeleri), `ui/menu_select` (ana menü). Genel tıklama `ui/click` olarak kalır |
| P3 | `ui/clink` kullanılmıyor | Küçük onaylar için kullan (ör. slot dropdown seçimi) ya da sil |
| P3 | `music/space_drone` ile müziğin AMB katmanı üst üste | Dinleyip karar ver: biri yeterli olabilir |

Not: Eskiden sessiz kalan 6 adet `ui_click` çağrısı (pause menüsü, ayarlar, tema seçici) artık `ui/click`'e bağlı.

---

## 3. Eksik sesler

### P1

| Önerilen event | An | Nerede tetiklenir | Not |
| --- | --- | --- | --- |
| `ui/scene_transition` | Galaksi ↔ güneş sistemi ↔ gezegen geçişi | `SceneTransition.go` | GDD: geçiş müziği baştan başlatmaz. VAM müziği zaten autoload'da tutuyor |
| `ui/star_hover` | Galaksi haritasında yıldızın üzerine gelme | `GalaxyView._input` | Galaksi ekranının hiç sesi yok |
| `sfx/star_enter` | Yıldıza girme (tek tık / çift tık) | `GalaxyView._input` | |
| `ui/popup_open` | Onay ve bilgi popup'larının açılması | `ModalPopup.open`, `PopupCard` | Bütün popup'lar sessiz açılıyor |
| `ui/popup_close` | Popup kapanması (Esc, kapat, dışarı tıklama) | `ModalPopup` | |
| `ui/notification` | Haber çubuğuna yeni mesaj | `NewsFeed.post` / `messages_changed` | Cooldown şart: aynı anda birden fazla mesaj düşebiliyor |
| `sfx/minerals_found` | Yüzeyde yeni maden keşfi | `GameState.minerals_discovered` | Şu an sadece panel yenileniyor |
| `sfx/ship_arrive` | Gemi hedefe vardı | `ShipManager.ship_arrived` | |
| `music/stinger_act_complete` | Medeniyet seviyesi / Act 1 tamamlandı, demo sonu ekranı | `GameState.civilization_reached`, `DemoEndScreen` | Kısa müzik stinger'ı. Ana müziği kısıp üstüne çalmalı |

### P2

| Önerilen event | An | Nerede tetiklenir | Not |
| --- | --- | --- | --- |
| `ui/belt_hover`, `sfx/belt_enter` | Asteroid kuşağında hover ve girme | `AsteroidBelt._input` | Sessiz ekran |
| `ui/task_add`, `ui/task_remove`, `ui/mission_confirm` | Mission Builder'da görev ekleme/silme, görevi onaylama | `MissionBuilderPanel` (8 buton) | Sessiz panel |
| `ui/list_hover`, `ui/list_select` | Tasarım sistemi satırları (şehir, district, bina, yörünge) | `ListItem` | Tek yerden eklenince her listeye yayılır |
| `ui/confirm`, `ui/cancel` | Onay paneli butonları | `ConfirmPanel` | §2'deki `click` bölmesiyle aynı sesler |
| `sfx/ship_launch` | Yeni gemi yörüngeye çıktı | `ShipManager.ship_added` | |
| `ui/trade_sell`, `ui/trade_buy` | Trade'de satış/alış başarılı | `TradePanel._do` | Şu an `click` / `error` |
| `sfx/building_queued` | Bina sıraya eklendi | `ProductionManager.building_queued` | |
| `sfx/asteroid_found` | Yeni asteroid keşfi | `GameState.asteroid_discovered` (`SolarView._on_asteroid_discovered`) | Survey popup'ındaki ses ayrı kalır |
| `ui/offline_summary` | Uzun aradan dönüş özeti | Offline dönüş ekranı | GDD: binlerce üretim sesi değil, özet için bir ses |
| `music/menu` | Ana menü | `MainMenu` | Şu an oyun müziği açılışta intro ile başlıyor. Ayrı menü müziği ya da intro'yu menüye saklama kararı gerekiyor |

### P3

| Önerilen event | An | Nerede tetiklenir | Not |
| --- | --- | --- | --- |
| `sfx/building_pause`, `sfx/building_resume` | Bina durduruldu / devam etti | `ProductionManager.building_toggled` | |
| `sfx/production_tick` | Üretim çıktısı (floating text) | `ProductionManager.resource_produced` | Çok sık. Sadece açık gezegende, düşük seste, cooldown ve max instances ile. GDD: üretim sesleri yığılmaz |
| `ui/tutorial_highlight` | Tutorial yeni bir öğeyi vurguladı | `TutorialManager.highlight_changed` | |
| `ui/delete` | Kayıt silme | `MainMenu._delete_slot` | Şu an `click` |
| `ui/screenshot` | Ekran görüntüsü alındı | `ScreenshotManager` | |
| `ui/slider_preview` | Ayarlarda UI/SFX ses slider'ı değişince örnek ses | `HUDManager.show_settings_popup` | Oyuncu seviyeyi duyarak ayarlar |
| Sahneye göre müzik/ambiyans | Galaksi / güneş sistemi / gezegen için farklı katman | Sahne geçişleri | VAM'e parametre sistemi gelince (yol haritasında) |

---

## 4. Kurallar (GDD §23)

- **Bus'lar:**
  - Music: müzik ve uzun ortam katmanları
  - UI: tık, hover, yanlış eylem, araştırma, seçim
  - SFX: inşaat, bina tamamlanması, roket, yüzey geri bildirimi
  - Master: ortak seviye
- **Yığılma yok:** Çok sayıda kredi veya üretim olayı aynı anda olduğunda sesler her adet için yığılmaz. VAM'de **Cooldown** ve **Max Instances** bunun için var.
- **Offline:** Offline hesaplama binlerce üretim sesini tekrar oynatmaz; dönüş özeti bir kez sunulur.
- **Sahne geçişi:** Üst haritaya geçiş mevcut müziği baştan başlatmaz.

## 5. Yeni sesi eklemek

1. VAM sekmesi: klasörü seç (`ui/`, `sfx/` ...) → **New SFX** → isim ver. İsim penceresi event id'sini gösterir.
2. Ses dosyalarını klip listesine sürükle. Tekrar eden seslerde **Volume Random** / **Pitch Random** ver. Spam riski olan seslerde **Cooldown** ve **Max Instances** ayarla.
3. Kodda ilgili yere `VAM.play(&"ui/popup_open")` yaz. **Copy Call** butonu satırı panoya kopyalar.
4. Bu listede ilgili satırı §1'e taşı.

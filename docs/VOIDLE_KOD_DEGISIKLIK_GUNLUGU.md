# Voidle kod değişiklik günlüğü

## 19 Kasım 2026

Çalışma `UXFix` dalında başladı ve `OsmanFix` çalışma ağacında devam etti. Karşılaştırma tabanı `aefcf1a12f219165f1e45c2c24d7c8bc7951d168`. Aşağıdaki kod değişiklikleri çalışma ağacında ve henüz commitlenmedi. `addons/VAM` içindeki beş `.svg.import` farkı bu çalışma öncesinden vardı.

### Çevrimdışı süre ve kayıt slotları

Başka bir slot açıldığında `open_slot()` önceki oturumu sıfırlıyordu. Sıfırlama `_offline_measured` değerini `true` yaptığı için hedef slotun yokluk süresi atlanıyordu. Ana menüde beklerken ya da başka slota geçerken yapılan kayıt da henüz işlenmemiş yokluk süresinin başlangıç zamanını ezebiliyordu.

- `load_save()` artık her geçerli yüklemede o slotun `saved_at` değerinden `offline_seconds` hesaplıyor. `_offline_measured` kaldırıldı. Yeni dünya veya slot sıfırlaması bekleyen süreyi temizliyor.
- `save()`, `offline_pending` açıkken diske yazmayı bekletiyor. Böylece otomatik kayıt, slot değişimi veya sefer içindeki kayıt çağrıları çevrimdışı adımlar bitmeden zaman damgasını ileri almıyor.
- `HUDManager._maybe_show_offline()` simülasyonu oynanış sahnesinde çağırıyor. `run_offline()` bekleyen süreyi tamamladığında bayrağı kapatıp bir kayıt alıyor. Çevrimdışı ilerleme kapalıysa veya simüle edilecek süre bir saniyeden azsa bayrağı temizleyip simülasyona girmeden dönüyor. Özet için gerçek yokluk süresi HUD’a açık kalıyor.
- `saved_at` alanı ve kayıt sürümü `1` kullanılıyor. Varsayılan denge ayarları, en az 60 saniye yoklukta ve en fazla 24 gerçek saat üzerinden normal hızın %10’unu uyguluyor.

Dosyalar [GameState.gd](../scripts/game/GameState.gd) ve [HUDManager.gd](../scripts/system/HUDManager.gd). İlgili çağrılar `open_slot`, `load_save`, `save`, `delete_save`, `run_offline` ve `_maybe_show_offline`.

### Ay aracının çevrimdışı uçuşu

`ProductionManager` uçuşta bir Ay aracı bulduğunda geminin `travel_progress` değerini okuyordu. Bu değeri ilerleten `ShipManager` çevrimdışı döngüye bağlı olmadığı için uçuş, yokluk süresinden pay alamıyordu.

- `ShipManager._advance_travel()` canlı ve çevrimdışı uçuşun ortak ilerleme hesabı. `advance_lander_travel()` hedefe uçan `lander` gemisini ilerletir. `GameState.run_offline()` bu çağrıyı her çevrimdışı adımda üretimden önce yapar. Kayıtta seferin hedef alanı yoksa ana gezegenin Ay’ı kullanılır.
- Süre dolunca mevcut `_on_arrived()` ve `ship_arrived` yolu çalışır. `GameState._on_ship_arrived()` üzerinden Ay yörüngesi kurulur ve oyuncu iniş yerini seçebilir. Çevrimdışı çağrı yalnızca hedefe uçan Ay aracını adımlar. Serbest gemi ve yük gemisi trafiği canlı döngüde kalır.
- `offline_pending` boyunca gezegen görünümü Ay aracının kalkış animasyonunu, kameraya bağlı ayrılış takibini ve varışta otomatik kamera geçişini atlar. `tick_expeditions()` bu sırada `watched_ms` zaman damgasını hesaba katmaz. Böylece çevrimdışı hazırlık ve yörünge turu, sahnedeki bir animasyonu beklemeden uçuşa geçebilir.

Dosyalar [GameState.gd](../scripts/game/GameState.gd), [ShipManager.gd](../scripts/game/ShipManager.gd) ve [PlanetaryView.gd](../scripts/planetary/PlanetaryView.gd).

### Explore düğmesi

`GameState.EXPLORE_BUTTON_ENABLED` şu an `false`. HUD, Explore düğmesinin görünürlüğü için `explore_available()` çağırdığı için oyuncu kısayolu kapalı. Geliştiriciler hâlâ `showcase on` ve `showcase off` komutlarını kullanabiliyor. Konsolu da kapatan ara değişiklik geri alındı. `DevConsole.gd` için net Git farkı boş.

Dosyalar [GameState.gd](../scripts/game/GameState.gd), [HUD bağlantısı](../scripts/system/HUDManager.gd) ve [konsol komutu](../scripts/system/DevConsole.gd).

### Doğrulama durumu

Kod ve Git farkı okundu. Godot çalıştırılmadı ve oyun içi test yapılmadı. Bu ilk değişiklik grubu 19 Kasım playtest tasarımından önce tamamlandı.

### New Game medeniyet metinleri ve önizlemeleri

New Game’deki açıklamalar, kullanıcının onayladığı Tip 0–6 sırasıyla eşleştirildi. Sıra Gezegen Öncesi, Gezegensel, Yıldızsal, Galaktik, Evrensel, Çoklu Evren, Boyutlararası ve Yaratıcı Uygarlık. İlk taslaktaki komşu galaksi ve galaksi kümeleri eşleştirmeleri düzeltildi.

- `SessionPrep.CIVS` seçili uygarlığın İngilizce adını tutuyor. `NewGamePanel._on_civ()` çizimi o uygarlığın fetih hedefine yönlendiriyor. Tip 0 ana gezegeni ve Ay’ı, Tip 1 yıldız sistemini, Tip 2 galaksiyi, Tip 3 evreni, Tip 4 çoklu evreni, Tip 5 dört boyutlu hiperküpün izdüşümünü gösteriyor.
- İlk Tip 6 önizlemesi soyut bir yıldız alanıydı. Bazı yıldızlar sönünce aralarındaki karanlıkta Ω beliriyordu.
- Kod kapsamı New Game’in üç scripti. Final roketinin Tip 1’e geçişi kullanıcı tarafından doğrulandı. Bu geçişin kodu ile gelecekteki `interstellar_port_district.tres` kaynak dosyası bu değişiklik grubunun dışında.

Dosyalar [SessionPrep.gd](../scripts/ui/SessionPrep.gd), [NewGamePanel.gd](../scripts/ui/NewGamePanel.gd) ve [NewGamePreview.gd](../scripts/ui/NewGamePreview.gd). Görsel sonuç Godot’ta doğrulanmadı.

## 20 Kasım 2026

### New Game önizlemelerinde yörünge hareketi

- Tip 1 önizlemesi sekiz gezegen çiziyor. İç yörüngelerde küçük kayalık gezegenler, dış yörüngelerde daha büyük gezegenler var. Bu sayı New Game çizimine ait.
- Tip 2’de parlak çekirdekli, eğik bir spiral disk dönüyor. Tip 3’te farklı boydaki galaksiler kendi eksenlerinde dönerken iki yörüngeye dağılıyor. Tip 4’te üç evren diski ortak bir yörünge boyunca ilerliyor. Tip 5’te hiperküp dört boyutlu bir düzlemde dönerken çevresindeki üç eğik halka da hareket ediyor.
- Tip 6’da yıldız alanı yerini ekranın büyük bölümünü kaplayan parlak bir Ω’ya bıraktı. İşaretin dikey eksenindeki salınım, önden okunan silueti koruyor.

Kod farkı [NewGamePreview.gd](../scripts/ui/NewGamePreview.gd) içinde. Godot çalıştırılmadı ve görsel sonuç oyunda doğrulanmadı.

### Steam Wishlist ve çıkış paneli

- [MainMenu.gd](../scripts/system/MainMenu.gd) içindeki `_build_menu`, `WISHLIST ON STEAM` düğmesini ana menüde `QUIT` üstüne ekliyor. [HUDManager.gd](../scripts/system/HUDManager.gd) içindeki `show_pause_menu`, aynı düğmeyi `RESUME` altına ekliyor. İkisi de `RESUME` ile aynı `IconButton.Variant.POSITIVE` stilini ve `DemoConfig.steam_url` mağaza adresini kullanıyor.
- Ana menüde `QUIT` ve duraklatma menüsünde `QUIT TO DESKTOP`, `HUDManager.show_quit_confirmation` üzerinden mevcut `ModalPopup` bileşenini açıyor. `BACK` ile duraklatma menüsüne dönerken oyun duraklatılmış kalıyor. Çıkış onaylanırsa duraklatma menüsünden gelen akış önce kaydediyor.
- Çıkış panelinde Wishlist çağrısı ve düğmesi, ardından playtest daveti ve katılımcılara özel oyun içi hediye metni geliyor. E-posta alanı ile `SEND` düğmesi `BACK` ve `QUIT` satırının üstünde.
- E-posta entegrasyonu kodcuya devredilecek. Paneldeki `PlaytestEmail` alanı ve `PlaytestSend` düğmesi pasif. Entegrasyon sırasında bu iki bileşeni etkinleştirip düğmeye gönderim davranışı bağlanacak.

Başlangıç commit’i `aefcf1a12f219165f1e45c2c24d7c8bc7951d168`. Godot ve testler çalıştırılmadı.

### New Game açıklama alanları

- [NewGamePanel.gd](../scripts/ui/NewGamePanel.gd) içindeki `_hold_lines` açıklamaları iki satır yüksekliğine sabitliyordu. [NewGamePanel.tscn](../scenes/ui/NewGamePanel.tscn) içindeki Civilization, Start World ve Head Start metin alanları artık 72 piksel yüksekliğinde ve uzun metin için dikey kaydırma kullanıyor. `_hold_height` üç adımın panel yüksekliğini eşit tutuyor.
- `_add_row`, Dünya veya Ay düğmesine basılınca o açıklamayı panelde tutuyor. Başka bir seçeneğin üstüne gelince önizleme metni gösteriliyor, fare ayrılınca son tıklanan açıklama geri geliyor. `_show_description`, metin değiştiğinde kaydırmayı başa alıyor.
- Önceki oyunlarda açılan ve bu sürümde henüz seçilemeyen dünyaların durum satırı, dünya açıklamasıyla birlikte gösteriliyor. Narrative metinleri `SessionPrep` içinden okunmaya devam ediyor.

Başlangıç commit’i `aefcf1a12f219165f1e45c2c24d7c8bc7951d168`. Godot ve testler çalıştırılmadı.

### District uzaklık kademeleri

- [Location.gd](../scripts/game/Location.gd) yerleşim merkezleri arasındaki açıyı ölçüp en yakın yüzey district’ini seçiyor. Capital District yüzey referansları arasında. Minimum açı gezegenin yerleştirme aralığından, maksimum açı bağlı olunan City’nin yerleştirme erişimi ve referans district’in yarıçapı toplamından geliyor. `band`, aralığı üç eşit parçaya bölüyor. Standart gezegende başlangıç örneği `4°–13,5°`, kademe geçişleri yaklaşık `7,17°` ve `10,33°`.
- [TerrainSampler.gd](../scripts/planetary/TerrainSampler.gd) içindeki `territory_radius_deg` yerleştirme kontrolleri ve uzaklık kademeleri için ortak yerleşim yarıçapını sağlıyor. Coğrafya, aynı tür komşu bonusu ve araştırma çarpanları kendi kurallarını kullanıyor.
- [PlanetaryView.gd](../scripts/planetary/PlanetaryView.gd) içindeki `_location_rows`, en yakın district’in adını, km cinsinden mesafesini ve kademesini `1x` durumunda da gösteriyor. `_neighbour_effect_rows`, mevcut district’lerin kademe değişimini `Far 2x → Near 1x` biçiminde, komşuluk bonusundaki değişimi ayrı bir satırda gösteriyor.
- [ProductionManager.gd](../scripts/game/ProductionManager.gd) district, bina ve ilgili seviye geçişleri tamamlandığında konum önbelleğini yeniliyor. Çevrimdışı üretim adımları aynı kare içinde işlenirken biten inşaatlar bu yolla hesaba giriyor. [DevConsole.gd](../scripts/system/DevConsole.gd) içindeki `loc` komutu referans district’i ve hesapta kullanılan merkezden merkeze aralığı gösteriyor.

Başlangıç commit’i `aefcf1a12f219165f1e45c2c24d7c8bc7951d168`. Godot ve testler çalıştırılmadı.

### District ve Capital yakınlık bonusları

- [Location.gd](../scripts/game/Location.gd) tamamlanmış her uygun komşunun mesafesini aynı açısal `Near` kademesiyle değerlendiriyor. [BalanceConfig.gd](../scripts/game/balance/BalanceConfig.gd) varsayılanıyla her aynı tür komşu `+0,5x`, her yakın Capital District district’in türünden bağımsız `+0,5x` ekliyor. Katkılar kendi aralarında ve uzaklık çarpanıyla toplanıyor.
- Cluster Planning aynı tür bonusunu ölçekliyor. Mixed Networks ile bağlı türler bu katkının yarısını veriyor. [SkillTree.gd](../scripts/game/SkillTree.gd) açıklaması güncel tutarı hesaplamak için yarım katkı kuralını tarif ediyor. Capital katkısı `centre` alanında tutuluyor.
- [PlanetaryView.gd](../scripts/planetary/PlanetaryView.gd) içindeki `_location_rows` ve `_neighbour_effect_rows` district ile Capital yakınlığını ayrı satırlarda gösteriyor. Yerleştirme önizlemesi yeni district’in mevcut district’lere inşaat tamamlandığında vereceği yakınlık katkısını da hesaplıyor.

Başlangıç commit’i `aefcf1a12f219165f1e45c2c24d7c8bc7951d168`. Godot ve testler çalıştırılmadı.

### Rehberde district yer önerisi

- [PlanetaryView.gd](../scripts/planetary/PlanetaryView.gd) içindeki `_suggest_guide_site`, seçili district için City grubunun yerleştirme halkaları içinde örnek noktalar çıkarıyor. Her noktayı arazinin ve yerleştirme erişiminin kullandığı kontrollerle eliyor. Örnekleme minimum ve maksimum açı arasındaki üç uzaklık kademesini de kapsıyor.
- `_guide_site_score`, adayın yerleştirme kartındaki `Total` formülüne mevcut her yüzey district’inin `Location` çarpanındaki net değişimi eşit ağırlıkla ekliyor. Başlangıç çarpanlarını arama başında bir kez okuyor. Aday eklenince oluşacak çarpanları, komşuluk önizlemesinde de kullanılan `Location.breakdown_with` üzerinden alıyor.
- Rehber, o an seçili district için en yüksek puanlı geçerli adayı `SUGGESTED` işaretiyle gösteriyor. Puan hesap içinde kalıyor. Bir sonraki district’in yeri, o district yerleştirilirken yeniden seçiliyor.

Başlangıç commit’i `aefcf1a12f219165f1e45c2c24d7c8bc7951d168`. Godot ve testler çalıştırılmadı.

### Haber şeridi ve gezegende sağ tık

- [NewsFeed.gd](../scripts/system/NewsFeed.gd) içindeki `_update_hover`, farenin hangi kontrolün üzerinde olduğunu arayüzden alıyor. Üzerine gelinen ve tıklanan haber, `_label_at` ile şeridin görünür metin alanından seçiliyor. Tıklama olayın anlık konumunu kullandığı için önceki karede vurgulanan habere bağlı kalmıyor.
- [LeftPanel.tscn](../scenes/ui/components/LeftPanel.tscn) içindeki dekoratif yerleşim kapsayıcısı ve saydam boşluklar fare girdisini almıyor. Panelin düğmeleri kendi girdilerini almaya devam ediyor.
- [PlanetaryView.gd](../scripts/planetary/PlanetaryView.gd) sağ tuşa basmayı `_gui_input` üzerinden alıyor. Panelin aldığı sağ tık gezegen hareketi başlatmıyor. Gezegen üzerinde başlayan sürükleme bırakıldığında temizleniyor. Tıklama menüsünün açılması için tuşun gezegen alanında bırakılması gerekiyor.

Başlangıç commit’i `5eed8c0680bfee5184da6f07ec9c92a3088c6b46`. Godot ve testler çalıştırılmadı.

### Kazı tooltip’i

- [POILayer.gd](../scripts/planetary/POILayer.gd) kazı adını ve durumunu ortak `TooltipManager` kartında gösteriyor. Kazı sürerken kalan süre canlı güncelleniyor. Başlanmamış ve tamamlanan kazılarda kart, işareti açınca oyuncunun ne göreceğini belirtiyor. Haritadaki kazı işareti, ilerleme çubuğu ve kısa süre göstergesi korunuyor.
- [PlanetaryView.gd](../scripts/planetary/PlanetaryView.gd) tooltip’i haritanın etkileşime açık alanıyla sınırlıyor ve işaretin üzerine gelindiğinde coğrafya tooltip’ini geri çekiyor. Dünya merkez imleci de aynı kartı açıyor.
- [TooltipManager.gd](../scripts/system/TooltipManager.gd) içindeki `hide_live_tip`, kazı tooltip’inin canlı güncellemesini kendi çağrısı üzerinden kapatıyor. Kazı penceresi açılırken veya görünüm kapanırken kilitli kazı tooltip’i de kapatılabiliyor.

Başlangıç commit’i `185a44ea1d3c890ad0af6f9845ef535ea5fcae2b`. Godot ve testler çalıştırılmadı.

### First Residents bildirimi ve medeniyet etiketleri

- [Inbox.gd](../scripts/system/Inbox.gd) içindeki `_add_task`, `first_residents` görevinden Notifications satırı üretmiyor. Görev ilerleme akışı `TutorialManager` içinde duruyor.
- [ResourceBar.gd](../scripts/ui/components/ResourceBar.gd) üst bardaki rozette ulaşılan `GameState.civilization_type` değerini tam sayı olarak gösteriyor. Rozetin tooltip’i mevcut küsüratlı değeri göstermeye devam ediyor.
- [MainMenu.gd](../scripts/system/MainMenu.gd) içindeki `_slot_text`, silme onayında `Civilization Type 0` biçimini gösteriyor.

Başlangıç commit’i `81f004ebd39244643ed4006ac478f46e1dc35acc`. Godot ve testler çalıştırılmadı.

### Eski tasarım kodunun temizliği

- [Inbox.gd](../scripts/system/Inbox.gd) içindeki `_add_task`, artık eski `TutorialManager.QUESTS` listesinden satır üretmiyor. `Final rocket` hedefi kendi koşulları ve mevcut yönlendirmeleriyle geliyor.
- [MainMenu.gd](../scripts/system/MainMenu.gd) içindeki eski `IntroCard` açma ve gezinme yolları, sahne, script ve UID dosyasıyla birlikte kaldırıldı. [SessionPrep.gd](../scripts/ui/SessionPrep.gd) içinden çağrısız `_world_text`, [PlanetaryView.gd](../scripts/planetary/PlanetaryView.gd) içinden sürekli boş dönen district `Minerals` satırı çıkarıldı.
- [PlanetProgress.gd](../scripts/game/PlanetProgress.gd), [BuildingDef.gd](../scripts/game/BuildingDef.gd) ve [SkillTree.gd](../scripts/game/SkillTree.gd) içindeki çağrısız bina yükseltme ve maliyet fonksiyonları kaldırıldı. Eski bina kayıtlarındaki `level` değeri yığın birleştirmede hâlâ okunuyor. [GameState.gd](../scripts/game/GameState.gd) içinden eski `complete_act1()` ve sinyali çıkarıldı. `act1_complete` eski kayıttan okunup kayıt yeniden yazılırken korunuyor.
- [BalanceConfig.gd](../scripts/game/balance/BalanceConfig.gd) içinden kullanılmayan 600/900 km eşikleri ve önceki beş kademe alanları çıkarıldı. Repodaki `.tres` profilleri bu alanları tanımlamıyordu. Eski araştırma kimlikleri, emekli bina tanımları ve relic dönüşümü kayıt uyumluluğunda kullanılmaya devam ediyor.

Başlangıç commit’i `2a47432055cdbccda5f18d91c054658c49a26a4c`. Godot ve testler çalıştırılmadı.

### Science baz üretimi ve Ion Research Lab

- `BalanceConfig.gd` içinden genel Science çarpanı `science_income_mult` kaldırıldı. `ProductionManager.gd` içindeki `_skill_mods` ve `idle_income_rates` bu alanı artık okumuyor.
- Science District’in aylık baz üretimi Lv 1’de 1 Science. Mevcut district seviye hesabıyla Lv 2’de 1,5 Science. Aylık bina üretimleri Field Lab için 1, Research Lab, Mountain Observatory ve Forest Research Station için 2, Research Institute, Desert Research Station ve Ion Research Lab için 4, Particle Accelerator için 8 Science. Orbital Science paketleri aynı bina tanımlarını kullanıyor. Gezegen bonusundan önce paket çıktıları 3, 6, 12 ve 24 Science.
- `ion_research_lab.tres` için ilk inşa bedeli 450 Credits, aylık işletme girdisi 3 Goods. Capital District, Orbit City, Free Research ve önceki veya sonraki medeniyetlere ait laboratuvar değerleri, genel çarpan kalkınca mevcut üretimleri korunacak şekilde doğrudan tanımlandı.
- Ekonomi revizyonu tamamlandığında bütün kaynakların alım ve satım oranları birlikte gözden geçirilecek.

Başlangıç commit’i `71bb565b1adc774576cbb113457ea57da4a8f1dc`. Godot ve testler çalıştırılmadı.

### Commercial baz üretimi ve Orbital Commercial paketleri

- `commercial_district.tres` aylık baz üretimi Lv 1 için 2 Credits. Mevcut seviye hesabıyla Lv 2 toplam 3 Credits.
- Aylık baza göre Market 2, Local Trade Center, Lakeside Market ve Glacier Exchange 4, Trade Hub ve Volcanic Market 8, Commodity Exchange ve Low-Gravity Exchange 16 Credits üretiyor.
- `orbit_prefabs.csv` içindeki Orbital Commercial paketleri yüzeyle aynı bina kimliklerini kullanıyor. Otomatik kurulan üçlü paketlerin aylık baz üretimi gezegen bonusundan önce sırasıyla 6, 12, 24 ve 48 Credits.

Başlangıç commit’i `71bb565b1adc774576cbb113457ea57da4a8f1dc`. Godot ve testler çalıştırılmadı.

### Bina işletme giderleri ve coğrafya indirimi

- Demo kataloğundaki T0–T3 binalarının işletme giderleri `resources/buildings` tanımlarında maliyet tier’ine göre düzenlendi. T0 için 1 enerji, T1 için 2 enerji ve 1 Goods, T2 için 6 enerji, 3 Goods ve 1 Fuel, T3 için 18 enerji, 9 Goods, 3 Fuel ve 1 Rare Elements. Araziye veya Ay’a özel binalar mevcut `cost_tier` alanıyla bir alt kademenin giderini kullanıyor.
- Bir modelin ürettiği kaynak kendi tier giderinden çıkarıldı. Örneğin santraller enerji, Goods Factory Goods, Fuel Refinery Fuel ve Rare Metal Refinery Rare Elements tüketmiyor. Ferrite gibi mevcut tarif girdileri korundu.
- Orbital paketleri doğrudan aynı bina tanımlarını kullanıyor. Spaceport’un gideri, `ProductionManager.gd` içindeki mevcut aktif hazırlık ve soğuma çevrimlerinde tahsil ediliyor.

Başlangıç commit’i `71bb565b1adc774576cbb113457ea57da4a8f1dc`. Godot ve testler çalıştırılmadı.

## 21 Kasım 2026

### Helium-3 Reactor ve Low-Gravity Exchange giderleri

- `helium3_reactor.tres` ve `low_gravity_exchange.tres` kendi T3 kademelerini kullanıyor. İki model de T3 inşa malzemelerine ve aylık 9 Goods, 3 Fuel, 1 Rare Elements giderine geçti. Low-Gravity Exchange ayrıca 18 enerji tüketiyor. Helium-3 Reactor enerji ürettiği için enerji gideri 0 ve aylık baz üretimi 8 enerji.
- Coğrafya indirimi için binanın özel bir arazi yerleşim koşulu olmalı. `BuildingDef.gd` içindeki `cost_tier` açıklaması alanın güncel işlevini yansıtacak şekilde düzeltildi.

Başlangıç commit’i `71bb565b1adc774576cbb113457ea57da4a8f1dc`. Godot ve testler çalıştırılmadı.

### Residential kapasitesi ve Orbital Residential paketleri

- `residential_district.tres` Lv 1 baz kapasitesi 1.000 nüfus. Mevcut district seviye hesabıyla Lv 2 toplam 1.500.
- Low-rise Housing 1.000, Habitat Block, Mountain Terraces ve Forest Homes 2.000, Apartment Towers, Coastal Apartments ve Desert Habitat 4.000, Luxury Spires ve Crater Habitat 8.000 baz kapasite sağlıyor.
- `orbit_prefabs.csv` içindeki Orbital Residential paketleri aynı konut tanımlarını kullanıyor. Üçlü paketlerin gezegen bonusu öncesi kapasiteleri 3.000, 6.000, 12.000 ve 24.000 nüfus.

Başlangıç commit’i `71bb565b1adc774576cbb113457ea57da4a8f1dc`. Godot ve testler çalıştırılmadı.

### Coğrafya şartı olan binaların aylık giderleri

- Energy, Science, Commercial, Residential ve Production gruplarında özel arazi şartı olan 19 aktif bina kendi bina tier’inin aylık enerji ve kaynak giderlerini kullanıyor. `cost_tier` ile seçilen alt tier inşa malzemesi paketleri korundu.
- Üretilen kaynak binanın kendi girdilerine eklenmiyor. Bu yüzden Wind Turbine ve Tidal Generator yalnızca 1 Goods, Geothermal Plant 3 Goods ve 1 Fuel, Cavern Refinery ise yalnızca 18 enerji ödüyor.
- Production binalarının yeni çıktı dağılımı ve district’in baz maden üretimi bu denge çalışmasının ayrı tasarım kalemleri.

Başlangıç commit’i `71bb565b1adc774576cbb113457ea57da4a8f1dc`. Godot ve testler çalıştırılmadı.

### Production District ve üretim binaları

- `mining_district.tres` aylık baz ham maden üretimi Lv 1, Lv 2 ve Lv 3 için sırasıyla 1, 1,5 ve 2. Aynı tanım Ferrite ve Moonstone üreten yüzey district’lerinde kullanılıyor.
- Surface Quarry, Mine, River Extractor, Deep Drill ve Mantle Cracker aylık bazda sırasıyla 1, 2, 2, 4 ve 8 ham maden üretiyor. Geothermal Drill ayda 4 Goods için 6 enerji, 8 Ferrite ve 1 Fuel, Volcanic Mine ayda 2 Fuel için 6 enerji, 12 Ferrite ve 3 Goods kullanıyor.
- Deep-Core Refinery, Rare Refining ile açılıyor ve dağ koşulu istiyor. Ay kısıtı kaldırıldı. Aylık 18 enerji, 36 Ferrite, 9 Goods ve 3 Fuel ile 2 Rare Elements üretiyor. Mevcut kayıtlardaki binaların geçerliliği için `lunar_deep_bore` kimliği korundu.
- Cavern Refinery tek çevrimde 18 enerji gideriyle 8 Goods, 4 Fuel ve 2 Rare Elements üretiyor. Orbital Production paketleri aynı bina tanımlarını kullanıyor.

Başlangıç commit’i `71bb565b1adc774576cbb113457ea57da4a8f1dc`. Godot ve testler çalıştırılmadı.

### Capital District baz üretimi ve kapasitesi

- `city_district.tres` aylık baz Credits, Science, enerji ve ham maden çıktıları Lv 1’de 1, Lv 2’de 1,5. Ham maden gezegenin madeni keşfedildikten sonra üretiliyor.
- `DistrictDef.level_mult()` Capital District’in nüfus katkısı için seviye çarpanını 1 döndürüyor. `ProductionManager._district_income_now()` ve `PlanetaryView.gd` içindeki yükseltme tooltip’i aynı hesabı kullanıyor. City’nin 15.000 ve Capital’in 600 katkısıyla baz kapasite 15.600. Lv 1 ve Lv 2 slot sayıları sırasıyla 2 ve 3.
- Capital District tasarımına dönüldüğünde oyun mekaniklerini açacak yeni binalar ele alınacak.

Başlangıç commit’i `71bb565b1adc774576cbb113457ea57da4a8f1dc`. Godot ve testler çalıştırılmadı.

### Energy District, santraller ve Orbital Energy

- `generator_district.tres` baz enerji üretimi Lv 1’de 1, Lv 2’de 1,5. Solar Array 1, Solar Matrix, Wind Turbine ve Tidal Generator 2, Geothermal Plant ve Fission Reactor 4, Antimatter Plant ve Helium-3 Reactor 8 baz enerji üretiyor.
- Helium-3 Reactor ilk kurulum fiyatı 450 Credits. `orbital_energy_district.tres` kendi enerji gideri 0. Orbital Energy paketleri yüzeydeki santral tanımlarını kullanıyor ve gezegen bonusu öncesi 3, 6, 12 veya 24 enerji sağlıyor.

Başlangıç commit’i `71bb565b1adc774576cbb113457ea57da4a8f1dc`. Godot ve testler çalıştırılmadı.

### Ekonomi revizyonunun Fork’a aktarımı

- Bu çalışma ağacındaki ekonomi revizyonu Science, Commercial, Residential, Production, Capital ve Energy bölümlerini kapsıyor. Bina işletme giderleri kendi tier’ine göre uygulanıyor. Özel arazi şartı inşa malzemesi kademesini düşürüyor. Binanın ürettiği kaynak kendi işletme giderine eklenmiyor.
- Orbital district paketleri yüzey binalarıyla ortak tanımları kullanıyor. Trade alım ve satım oranları sonraki denge turuna bırakıldı. Capital District için oyun mekaniklerini açan yeni binalar ayrıca tasarlanacak.
- Fork’a gönderilecek güncel kaynak farkını repo kökünde `git diff --no-ext-diff 71bb565b1adc774576cbb113457ea57da4a8f1dc` ile inceleyebilirsin.

## 22 Kasım 2026

### Ekonomi takibi ve tasarım sırası

- Trade fiyatları aşağıdaki revizyonda güncellendi. Sıradaki tasarım konusu, yeni mekanikler açan Capital District binaları. Trade karşılaştırmasında aynı üretim tier’indeki binaların aylık çıktıları ve tükettikleri satılabilir girdiler referans fiyatla Credits’e çevriliyor.
- Upgrade Tree çalışmasında her dal önce kendi içinde ele alınacak, dalların birleşme noktaları daha sonra belirlenecek. Spaceport’un Rare Elements ihtiyacı, Ay’da 100 Moonstone çıkarma koşulu ve final roketinin 1.200 Moonstone ile 12.000 Credits maliyeti bu turda tekrar kontrol edilecek.
- Ödeme karşılanmayan depolar için kapasiteyi koruyan, üretimi %10 düşüren ve kaynak tooltip’inde nedenini gösteren bir ceza önerildi. Uygulama ayrıntıları tasarımda açık.
- Standard başlangıç bütçesi ve tutorial atlama ödülü, oyuncunun ödülü aldığı rehber akışıyla birlikte daha sonra değerlendirilecek.
- Narrative turunda geçici piyasa olayları için ayrı bir CSV hazırlanacak. Olayın etkilediği kaynak, fiyat değişimi, süre ve haber ile Trade tooltip’inde gösterilecek neden birlikte tanımlanacak.

### T1–T3 bina üretimi ve demo Trade fiyatları

- T1 binalarda seçilen baz çıktılar 4 Science, 4 enerji, 12 Credits, 4 ham maden ve 6.000 nüfus kapasitesi. T2’de 20 Science, 28 enerji, 64 Credits, 20 ham maden ve 32.000 nüfus kapasitesi. Geothermal Drill ayda 8 Goods üretiyor.
- T3 binalarda seçilen baz çıktılar 120 Science, 120 enerji, 320 Credits, 120 ham maden, 3 Rare Elements ve 120.000 nüfus kapasitesi. Ion Research Lab 2.250 çalışan kullanıyor. Cavern Refinery aylık 180 enerji tüketiyor ve 8 Goods, 4 Fuel, 2 Rare Elements üretiyor.
- Orbital paketler aynı `.tres` bina tanımlarına bağlı olduğu için yeni çıktıları doğrudan alıyor.
- `Trade.gd` içindeki demo referans fiyatları Science 3, Ferrite 3, Moonstone 6, Goods 8, Fuel 30 ve Rare Elements 120 Credits. `run_orders()` otomatik satış emri için %10, otomatik alış emri için %5 fiyat hareketi sınırı kullanıyor. Bu sınırlar hedef stok emirlerine uygulanıyor.

Başlangıç commit’i `4e24e5f990ed9c05c18fe176936ccecf9fab90e5`. Godot ve testler çalıştırılmadı.

### New Game öğretici seçimi

- `NewGamePanel.gd` öğretici bir kez tamamlanana kadar Tutorial seçimini açık tutuyor. Sonraki yeni oyunlarda oyuncu öğreticiyi açıp kapatabiliyor. Seed, Random ve Head Start seçenekleri yalnızca öğretici kapalıyken gösteriliyor. Aynı panelde öğretici tekrar kapatıldığında serbest başlangıç için yazılan seed ve seçilen Head Start geri geliyor.
- `_on_begin()` ve `SessionPrep.tutorial_seed()` öğreticili oyunun önizlemesinde ve kaydında `847209631758492063` kodundan üretilen aynı seed’i kullanıyor. Kod mevcut `seed_of()` fonksiyonuyla arazi üreticisinin desteklediği aralığa dönüştürülüyor. Öğretici Tip 0, Terran, Rocky Moon ve Standard başlangıcını alıyor.
- `GameState._apply_new_game_start()` öğretici kapalı açılan yeni oyunun rehber adımlarını tamamlanmış durumda başlatıyor. Böylece eski isteğe bağlı kontrol listesi ve atlama ödülü yeni serbest oyunda devreye girmiyor. Mevcut kayıtlar kendi rehber durumlarını okuyor.
- O tarihte sıradaki tasarım işi Head Start seçeneklerini gözden geçirmekti. Bu karar 24 Kasım’da ırk seçimiyle değişti. Narrative turunda danışmanın «Tamam» konuşmalarındaki kaynak desteğinin her adım için nedeni yazılacak.

### Koloni öğreticisi ve Capital District binaları

- `ColonyTutorial.gd`, kamera kontrolünden ücretli Bolo atamasına kadar 46 adımı çalıştırıyor. Kayıt `story_flags` içinde adımı, oyuncunun onayını, gereken eylemleri ve önerilen koordinatları saklıyor. Mother Superior ve High Father ilk adımlarda dönüşümlü konuşuyor. Seçim tamamlanınca konuşmacı mevcut danışman oluyor. Her adımda Continue var. Onay anında yalnızca adımın inşa, araştırma, işlem veya ilk üretim çevrimi için eksik kaynaklar ekleniyor.
- `TutorialSites.gd`, `PlanetaryView.gd` ve `Location.gd` City ile beş district’i baştan planlıyor. District’lerde mesafe, komşuluk ve coğrafyanın toplamı 2× olan noktalar tercih ediliyor. Energy için gerçek Mountain veya Tundra koşulu aranıyor. Tek harita işareti çıkıyor ve tıklama işaretin koordinatına oturuyor. Arama tam eşleşme bulamazsa geçerli seçenekler içinden 2× hedefine en yakın planı kullanıyor. Öğretici boyunca mesafe kademesinin referans erişimi sabit. Residential ve Energy için Capital’e doğrudan bağlantı yol ağına ekleniyor.
- Capital’e Survey Office, Communications Station, Government Building ve Archaeology Bureau eklendi. Baz inşa fiyatları sırasıyla 180, 200, 240 ve 300 Credits. Archaeology Bureau ayrıca baz 10 Goods istiyor. Mevcut district içi fiyat artışı inşa sırasında uygulanıyor. `BuildingDef.gd`, `PlanetaryView.gd`, `HUDManager.gd`, `NewsFeed.gd` ve `Inbox.gd` lensleri, haberi, atamayı ve kazıyı ilgili tesis ve öğretici adımına bağlıyor. Her district’in lensi kendi adımında açılıyor ve oyuncu yerleştirmeden önce lensi seçiyor. Tesisler yeni serbest oyunda da kullanılabiliyor. Eski kayıtlar önceki açılış kurallarını okuyor.
- `Economy.gd` ve `ProductionManager.gd`, öğreticili koloninin ilk City’sinde 200 ek konutla başlıyor ve City Lv 2’de bunu 10.000’e çıkarıyor. Capital District’in kendi konut üretimi ayrı kalıyor ve Cradle World’ün %10 nüfus bonusu hesaba katılıyor. Warehouse kurulana kadar ham madde kapasitesi 20. İlk Ferrite teslimatında taşan 2 birim haber şeridinde belirtiliyor. Notifications, gerçek nüfus ve enerji açıkları ile boş yuvaları ilgili panele bağlıyor. Öğretici, Lv 2 Residential genişletmesini ve bir Low-rise Housing yerine Habitat Block kurmayı içeriyor.
- `SkillTree.gd` ve `SkillTreeView.gd`, ilk araştırmada Mining Operations’ı hedef gösteriyor ve satın alımdan sonra yeni düğümleri ile fiyatları oyuncu ağacı kapatana kadar ekranda tutuyor. Civilization Studies uzay dalının ilk adımı. Satın alınan her araştırma seviyesi diğer araştırmaların fiyatını profil oranıyla artırıyor. Ücretsiz Head Start araştırmaları ve miras alınan seviyeler bu sayaca eklenmiyor. `ResourceBar.gd` takvimi ve Type göstergesini Civilization Studies sonrasında açıyor.
- `Trade.gd` ve `TradePanel.gd`, öğreticide gerçek 50 Ferrite satışı ve Goods alımı istiyor. Trade Automation öğretici dışında. `Excavations.gd` ilk The Toppled Stones kazısını öğreticide bir koloni ayına indiriyor. Sonuçta mevcut Bolo sahnesi çalışıyor. Öğreticiyi bitirmek için oyuncunun Government üzerinden ücretli Bolo atamasını onaylaması gerekiyor.
- Notifications’ın kalıcı görev ve koloni takip işlevi ve danışman desteğinin hikâye gerekçeleri ayrı ele alınacak. Geçici Trade olayları için anlatı turunda ayrı CSV hazırlanacak.

Başlangıç commit’i `6eac4eb`. Godot ve testler çalıştırılmadı. Sabit seed’de bütün district’lerin tam 2× alması ile nüfus ve enerji dengelerinin iki danışman seçimiyle seyri oyun içinde doğrulanmadı.

- Açılış düzeltmesi. `ColonyTutorial.gd` içindeki bildirim satırı üreticisi ve beş çağrısı `_notification_row()` olarak adlandırıldı. Önceki `_notification()` adı Godot’un `Object._notification(int) -> void` metoduyla çakışıyor ve `GameState` yüklenirken parse hatasına yol açıyordu.

## 24 Kasım 2026

### Güncel tasarım sırası

1. **New Game ırk seçimi.** Head Start kaldırılacak. Oyuncu portreler arasından bir ırk seçecek ve seçtiği ırk oyuna bir avantajla başlayacak. Irklar, portreler ve avantajlar tasarım turunda belirlenecek.
2. **District binaları.** Yeni yönetim binaları T2 inşa maliyeti ve aylık gider kullanacak. Pasif üretim katkıları sıfır olacak.
   - **Energy.** Önerilen ad Acil Müdahale Merkezi (*Emergency Response Center*). Zarar veren büyük olaylarda anlatı paneli sonucu kabul etme ve enerjiyle müdahale etme seçeneklerini gösterir. İkinci seçenek bina tamamlanınca kullanılabilir. Müdahale seçilirse olayın zararı önlenir ve bir koloni ayı boyunca toplam enerji tüketimi %20 artar.
   - **Residential.** Sivil İdare, oyuncunun ortada lider olarak göründüğü Government ekranını ve bir yardımcı koltuğunu açar. Mevcut danışman seçimi devam eder.
   - **Production.** Wonder İnşaat Ofisi çalışma adıyla planlanan bina, Wonder inşasını açar. Wonder, City ölçeğinde bir yapı olacak ve gezegen başına bir tane kurulabilecek. Türleri, maliyetleri ve etkileri ayrı bir tasarım turunda belirlenecek.
   - **Commercial.** Trade Automation araştırması Ticaret İdaresi’ni açar. Otomatik Trade bina kurulunca kullanılabilir.
   - **Science.** Rocketry ile açılan mevcut Spaceport, Capital’den Science District’e taşınır.
3. **Upgrade Tree.** Her yeni district binası bir araştırma ile açılacak. Dallar kendi içinde düzenlenirken bu binaların düğümleri ve önkoşulları belirlenecek. Sonra dalların birleşme noktaları tasarlanacak.
4. **Narrative ve rastgele olaylar.** Minör ve majör rastgele olaylar için danışman repliklerini içeren ayrı bir CSV hazırlanacak. Olayın ölçeği, ne zaman gerçekleşebileceği, etkisi ve danışmanın oyuncuya ne söylediği tanımlanacak. Çevrimdışı yaşanan olaylar Welcome Back akışında ele alınacak. Geçici Trade fiyat olaylarının CSV’si de ayrı iş olarak sırada. Danışman ana anlatıyı yürütecek. Yardımcı kamuya basın açıklamaları yapacak ve News haberlerinde adıyla yer alacak. Bu açıklamaların metinleri ve tetikleyicileri Narrative turunda belirlenecek.
5. **Notifications.** Narrative sonrasında kalıcı koloni takip paneli olarak tasarlanacak.

## 25 Kasım 2026

### District yönetim binaları

- `emergency_response_center`, `civil_administration`, `wonder_construction_bureau` ve `trade_administration` sırasıyla Energy, Residential, Production ve Commercial yüzey district’lerine eklendi. Her biri bir slot, 750 çalışan, 450 baz Credits ve profilin T2 inşa malzemelerini kullanıyor. Aylık giderleri 6 enerji, 3 Goods ve 1 Fuel. Çıktıları ve pasif bonusları sıfır. Her model bir district’te bir kez kurulabilir.
- `SkillTree.gd` yönetim binalarının açılma noktalarını bağlıyor. Emergency Response şimdilik Solar Matrix’ten, Civil Administration Habitat Blocks’tan, Wonder Construction Deep Drilling’den geliyor. Üçünün baz bedeli 350 Science. Mevcut Trade Automation düğümü 300 baz Science ile Trade Administration’ı açıyor. Düğüm konumları, bedelleri ve önkoşulları Upgrade Tree turunda yeniden değerlendirilecek.
- `Trade.has_automation()` otomatik emirleri ve taşma satışını çalışan bir Trade Administration’a bağlıyor. Bina devre dışı kalırsa kayıtlı emirler durur. Trade paneli durumu yeniler. Manuel Trade Access ve Force Buy için mevcut akış korunur.
- `GovernmentPanel.gd` Civil Administration tamamlanınca danışman, ortada oyuncu ve basın yardımcısını gösteriyor. Irk seçimi ve oyuncu portreleri tasarlanana kadar ortada mevcut silüet var. İlk danışman seçimi Capital’deki Government Building’den açılıyor. Eski kayıtların önceki kabinesi Civil Administration kurulana kadar kullanılabiliyor. Yeni hükümet açılınca eski bakanlık bonusları devreden çıkıyor ve yardımcı kendi pasif bonusunu uygulamıyor. Atama mevcut kayıt ve görev süresi alanlarını kullanıyor. News şeridi yardımcının atama açıklamasını ve gezegen seviyesi haberlerinde adını gösteriyor. Diğer kamu açıklamaları Narrative turunda yazılacak.
- `Narrative.offer_major_incident()` danışman portresiyle sonucu kabul etme ve acil güç kullanma seçeneklerini açıyor. Acil güç için çalışan Emergency Response Center gerekiyor. Müdahale hasarı önlüyor, bir koloni ayı boyunca enerji talebini %20 artırıyor ve bitiş zamanı kayda giriyor. Enerji tooltip’i ek talebi ayrı gösteriyor. `incident preview` geliştirici komutu akışı açıyor. Sonucu kabul etme yolunda en fazla 5 Goods kaybediliyor. Rastgele olay havuzu, tetikleyiciler ve CSV Narrative turunda eklenecek.
- `BuildingDef.gd` Wonder inşa yetkisini ilgili gezegendeki tamamlanmış Wonder Construction Bureau’ya bağlıyor. Gezegen başına bir Wonder sınırı, farklı modelleri ve inşaatı sürenleri de kapsıyor. City ölçeğindeki Wonder’ların türleri, maliyetleri ve yerleştirmesi ayrıca tasarlanacak.
- Spaceport’un yeni inşa yeri yüzeydeki Science District. Rocketry, T3 tarif ve mevcut işlevleri korunuyor. `PlanetaryView._spaceport_pad()` yeni yerini buluyor, eski kayıtta Capital’de inşa edilmiş Spaceport’u da bulmaya devam ediyor. Roket ve Ay hazırlığı mevcut Spaceport durumunu kullanıyor.

Başlangıç commit’i `6eac4eb`. Godot ve testler çalıştırılmadı.

## Başka bir AI ile kod incelemesi

Repo kökünde ilk komut dalı ve çalışma ağacını, ayrı `git diff` komutları ise değişiklik gruplarının başlangıç commit’ine göre güncel farklarını gösterir. Bu dosyalarda yeni işler başladıysa inceleme çıktısı onları da kapsar.

```powershell
git status --short --branch
git diff --no-ext-diff aefcf1a12f219165f1e45c2c24d7c8bc7951d168 -- scripts/game/GameState.gd scripts/game/ShipManager.gd scripts/planetary/PlanetaryView.gd scripts/system/HUDManager.gd
git diff --no-ext-diff aefcf1a12f219165f1e45c2c24d7c8bc7951d168 -- scenes/ui/NewGamePanel.tscn scripts/ui/SessionPrep.gd scripts/ui/NewGamePanel.gd scripts/ui/NewGamePreview.gd
git diff --no-ext-diff aefcf1a12f219165f1e45c2c24d7c8bc7951d168 -- scripts/system/MainMenu.gd scripts/system/HUDManager.gd
git diff --no-ext-diff aefcf1a12f219165f1e45c2c24d7c8bc7951d168 -- scripts/game/Location.gd scripts/game/ProductionManager.gd scripts/game/SkillTree.gd scripts/game/balance/BalanceConfig.gd scripts/planetary/TerrainSampler.gd scripts/planetary/PlanetaryView.gd scripts/system/DevConsole.gd
git diff --no-ext-diff 5eed8c0680bfee5184da6f07ec9c92a3088c6b46 -- scenes/ui/components/LeftPanel.tscn scripts/system/NewsFeed.gd scripts/planetary/PlanetaryView.gd
git diff --no-ext-diff 185a44ea1d3c890ad0af6f9845ef535ea5fcae2b -- scripts/planetary/POILayer.gd scripts/planetary/PlanetaryView.gd scripts/system/TooltipManager.gd
git diff --no-ext-diff 81f004ebd39244643ed4006ac478f46e1dc35acc -- scripts/system/Inbox.gd scripts/ui/components/ResourceBar.gd scripts/system/MainMenu.gd
git diff --no-ext-diff 2a47432055cdbccda5f18d91c054658c49a26a4c -- scripts/system/Inbox.gd scripts/system/MainMenu.gd scenes/ui/IntroCard.tscn scripts/ui/IntroCard.gd scripts/ui/IntroCard.gd.uid scripts/ui/SessionPrep.gd scripts/planetary/PlanetaryView.gd scripts/game/PlanetProgress.gd scripts/game/BuildingDef.gd scripts/game/SkillTree.gd scripts/game/GameState.gd scripts/game/balance/BalanceConfig.gd
```

İnceleyen AI’a bu dosyayı ve komutların çıktısını ver. Repo erişimi varsa ilgili çağrıları da açabilir. Kullanılacak talimat aşağıda.

```text
Bu günlüğü bağlam olarak kullan ve Git farkını kaynak kodla karşılaştır.
İnceleme salt okunur. Godot ve testler ekip tarafından ayrıca yürütülecek.

1. Ana menüde ilk yükleme ve başka slota geçme sırasında saved_at bilgisini izle.
   Bekleyen yokluk süresinin kaybolabildiği veya iki kez işlenebildiği bir yol ara.
2. Hazırlıktaki, ana dünya yörüngesindeki ve Ay'a uçan lander kayıtlarını ayrı incele.
   Kısmi ilerlemeyi, Ay'a varış sinyalini ve çevrimdışı döngüden sonraki kaydı izle.
3. Oyuncu HUD'unda Explore gizliyken showcase on/off komutlarının çağrılarına bak.
4. New Game etiketlerini ve her tipin bir sonraki fetih ölçeğini gösteren çizim çağrılarını incele.
   Kilit koşulunu, kaydırıcının hızlı değişimini, sekiz gezegenin önizlemeye özel kalmasını ve dönme animasyonlarını kontrol et.
5. Ana menü ve duraklatma menüsündeki Steam bağlantısını ve ortak çıkış panelini incele.
   Panelden geri dönünce duraklatmanın korunduğunu, çıkış onayında kayıt alındığını ve e-posta alanının pasif olduğunu koddan kontrol et.
6. New Game açıklamalarında satır kaydırmayı ve son tıklanan Dünya veya Ay açıklamasının korunmasını incele.
7. District uzaklık kademesinin en yakın yüzey district’ini ve yerleştirme aralığını kullandığını incele.
   Yerleştirme tooltip’i, mevcut komşuların önceki ve sonraki kademesi ve üretimin aynı konum hesabını kullandığını kontrol et.
8. Aynı tür komşuların ayrı ayrı toplandığını, Capital katkısının ayrı kaldığını ve her katkının açısal Near kademesini kullandığını incele.
9. Rehberin öneri puanında adayın Total değerini ve mevcut district’lerin net Location değişimlerini eşit ağırlıkla topladığını incele.
   Yerleştirme kurallarını karşılayan en iyi örnek noktanın yalnızca harita işaretiyle gösterildiğini kontrol et.
10. Sol panel açıkken görünür haber metninin ve gezegen alanında başlayan sağ tuş hareketinin ilgili kontrole ulaştığını koddan kontrol et.
11. Kazı tooltip’inin ortak kartta doğru durumu ve canlı süreyi gösterdiğini, kazı açılınca veya görünüm kapanınca kaldırıldığını incele.
12. First Residents satırının üretilmediğini ve kayıt silme ile üst bar etiketlerinin medeniyet seviyesini doğru kaynaktan aldığını incele.
13. Eski tutorial görevleri sökülürken final roketi bildiriminin kaldığını, çıkarılan kodun referanslarının temizlendiğini ve eski kayıt alanlarının hâlâ okunduğunu incele.

Her bulguda önem derecesini, dosya ve satırı, tetikleyen koşulu ve oyuncuya
etkisini ver. Oyun içinde doğrulama isteyen ihtimalleri açıkça belirt.
```

Sonraki kod değişiklikleri için bu dosyaya tarihli bir bölüm ekle. Başlangıç commit’ini, dosya ve fonksiyon adlarını, davranış değişikliğini ve doğrulama durumunu yaz. Değişiklikler commitlenince bitiş commit’ini de kaydet. İki commit’i `git diff <başlangıç> <bitiş> -- <dosyalar>` ile karşılaştırarak o bölümün kod farkını yeniden alabilirsin.

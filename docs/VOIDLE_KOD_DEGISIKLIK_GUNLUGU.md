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

Her bulguda önem derecesini, dosya ve satırı, tetikleyen koşulu ve oyuncuya
etkisini ver. Oyun içinde doğrulama isteyen ihtimalleri açıkça belirt.
```

Sonraki kod değişiklikleri için bu dosyaya tarihli bir bölüm ekle. Başlangıç commit’ini, dosya ve fonksiyon adlarını, davranış değişikliğini ve doğrulama durumunu yaz. Değişiklikler commitlenince bitiş commit’ini de kaydet. İki commit’i `git diff <başlangıç> <bitiş> -- <dosyalar>` ile karşılaştırarak o bölümün kod farkını yeniden alabilirsin.

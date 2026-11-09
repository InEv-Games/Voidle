# Voidle anlatı uygulama rehberi

[Ana belge](README.md) · [Sahne metinleri](SCENES.md) · [Arayüz](UI.md) · [Danışmanlar](ADVISORS.md)

Bu dosya tasarımı devralan geliştirici için olayları, oyun içindeki giriş noktalarını ve kayıt kurallarını eşler. [Sahneler](SCENES.md) yazılmış sahneleri, [Diyaloglar](DIALOGUE.md) gündelik replikleri ve tetikleyicilerini, [Yol haritası](ROADMAP.md) uygulama sırasını taşır. Aşağıdaki alan adları kavramsal sözleşmedir. Mevcut projedeki eşdeğer sistemlere uyarlanabilir.

## İlk uygulama dilimi

Bu dilim yeni oyunu, iki AI arasındaki ilk seçimi, ilk City'yi, öğreticiyi, Companions ve Narrative Log'u, The Toppled Stones'taki Bolo görüşmesini ve beş yıllık atama kilidini besleyen [canlı takvimi](#koloni-takvimi) kapsar. Ay sahnesi ve gezegen varışı aynı anlatı altyapısını kullanır. Çevrimdışı ekonomi ve rastgele dünya olayları sonraki dilimde etkinleştirilir.

| Durum | Giriş | Başarı koşulu ve sonraki durum |
| --- | --- | --- |
| `opening_intro` | Yeni kayıt oluşturuldu ve ana dünyanın PlanetaryView görünümü hazır. | Son satır okunduğunda iki AI seçimi açılır. |
| `choose_initial_advisor` | Oyuncu Mother Superior veya High Father kartını onaylar. | Aktif danışman kaydedilir ve onun `opening_handover` dalı açılır. |
| `opening_handover` | İlk danışman seçildi. | Son satırla ilk City hedefi ve mevcut yerleştirme işlemi etkinleşir. |
| `guide_city` | Yerleştirme modu açık. | Ana dünyada ilk normal City'nin inşaatı tamamlanır. Yer seçiminin onayı tek başına yeterli değildir. |
| `guide_capital` | City tamamlandı. | Oyuncu o City'nin Capital District görünümünü açar. |
| `guide_district` | Capital District görüldü. | Ana dünyada herhangi bir tamamlanmış Capital dışı yüzey district'i bulunur. |
| `guide_building` | Yüzey district'i tamamlandı. | Ana dünyada oyuncunun yaptırdığı herhangi bir tamamlanmış bina bulunur. |
| `guide_done` | Rehber adımları tamamlandı. | Son kısa AI satırı gösterilir, öğretici kapanır ve normal hedef kartı gösterilir. |
| `meet_bolo` | İlk ana dünya kazısının sonucu oyuncu tarafından açıldı. | Kazının mevcut seçimi ve Bolo görüşmesi bitince Bolo açılır, Ay sinyali hedefi kaydedilir. |

New Game'de öğretici zorunludur. Öğretici adımları mevcut oyun durumuyla karşılandığında geriye dönük tamamlanabilir. İlk kazı ayrı başlatılır. Kazı erken tamamlanırsa Bolo kartı açılır. Aktif atama öğretici ve mevcut danışmanın 5 yıllık görev süresi tamamlanınca yapılır.

## Godot bağlantıları

| Alan | Kaynaktaki giriş | Uygulamada bağlanacak davranış |
| --- | --- | --- |
| Yeni kayıt ve ana dünya | [MainMenu.gd](../../../scripts/system/MainMenu.gd#L743) ve [PlanetaryView.gd](../../../scripts/planetary/PlanetaryView.gd#L2577) | Yeni kayıtta ana dünya görünümünü aç. Mevcut otomatik City yerleşimi çağrısını `opening_handover` tamamlanana kadar beklet. Devam etme sırasında kayıtlı açılış aşamasını yükle. |
| City ve district tamamlanması | [ProductionManager.gd](../../../scripts/game/ProductionManager.gd#L202) ve [PlanetaryView.gd](../../../scripts/planetary/PlanetaryView.gd#L729) | `district_placed` konum onayını gösterir. İnşaat bitişinde tamamlanmış POI durumunu oku. Capital paneli açıldığında rehberlik ilerlesin. |
| Bina ve araştırma | [ProductionManager.gd](../../../scripts/game/ProductionManager.gd#L5) ve [SkillTree.gd](../../../scripts/game/SkillTree.gd#L29) | `building_constructed` ilk bina hedefini ve uygun olay repliğini tetikleyebilir. `skill_unlocked` ilk araştırma tepkisine kaynak olur. |
| Hedefler | [ObjectivesCard.gd](../../../scripts/ui/components/ObjectivesCard.gd) ve [TutorialManager.gd](../../../scripts/system/TutorialManager.gd) | İlk rehber hedefi ile isteğe bağlı kazı işaretini ayrı tut. Öğretici birimleri varsayılan bütçe, tarif ve ilerleme koşullarını okur. |
| Diyalog | [StoryDialog.gd](../../../scripts/ui/excavation/StoryDialog.gd#L205) ve [VSM sayfaları](../../../resources/stories) | VSM'nin konuşmacı, satır ve seçeneklerini ortak diyalog yüzeyine aktar. Açılışta site kimliği gerekmez. Kazı ödeme ve bekleme ekranları siteye bağlı kalır. |
| Kadro | [CompanionGallery.gd](../../../scripts/ui/excavation/CompanionGallery.gd) ve [Excavations.gd](../../../scripts/game/excavation/Excavations.gd#L81) | Companions'a iki AI'ı dahil et. Açık aday, aktif danışman ve bekleme durumunu ayrı göster. Etki hesabı aktif danışmanın kaynağını kullanır. |
| Kayıt | [GameState.gd](../../../scripts/game/GameState.gd#L1194) ve [yükleme](../../../scripts/game/GameState.gd#L1323) | Anlatı durumunu mevcut kayıt işlemiyle birlikte sürümlendir. Aynı durumu kayıt değiştirme, silme ve yeni oyun girişlerinde ayrıştır. |

### Diyalog sunumu

- **İlk uygulama varsayımı.** Ana sahne ve görünür seçim açıkken harita girişi bloke edilir ve simülasyon duraklar. Kısa danışman yorumları sırasında oyun akar. Dönüş özeti, uygulanan çevrimdışı dönemin sonuçlarını gösterir. [Arayüz](UI.md)
- `Continue` yazılan satırı önce tamamlar. Sonraki giriş ilerler. Seçim açıkken onay yalnız seçeneğe gider. Log açılırken panelin satırı, odağı ve simülasyon durumu korunur. Log kapatıldığında aynı noktaya dönülür.
- Her oturumda bir hikâye paneli görünür. Kuyruk önceliği ana sahne, rehber adımı, dönüş özeti, olay tepkisi, boşta replik şeklindedir. Açık bir sahne bitene kadar diğer girişler bekler. Yeri ve koşulu artık geçersiz rutin replikler sunum öncesinde elenir.
- `Narrator`, `I-330 Archive`, `I-330 Flight Control`, `Player`, `Survey Lead` ve `Unknown Voice` metin konuşmacılarıdır. Companions kadrosuna dört karakter girer ve paket portreleri kullanılır. Gelecek kadro kartı adsız `???` silüetidir. [Portre referansları](README.md#karakter-portreleri)
- Bolo'nun iki tanışmasında portre ile görünen konuşmacı adı ayrı alanlardır. Adını söylediği satır tamamlanana kadar etiket `Unknown Woman` olarak gösterilir. [Tanışma sahneleri](SCENES.md#the-toppled-stones-ve-bolo)

## Kazı ve sefer eşlemesi

| Olay | Kaynaktaki iş | Yeni anlatı sonucu |
| --- | --- | --- |
| The Toppled Stones | `vesyn_toppled_stones` ve mevcut [kazı sonucu](../../../resources/stories/vesyn_1_toppled_stones.tres#L52) | `Catalogue everything.` seçimi mevcut 150 Science ve `vesyn_scholars` etkisini taşır. `Sell the bronze to fund the dig.` mevcut 800 Credits ve `vesyn_sold` etkisini taşır. İki dal da oyuncu Bolo'yla tanışmadıysa `meet_bolo`, uzay limanında tanıştıysa `bolo_at_toppled_stones` ile kapanır. Sitenin taban ödülü ve maliyeti mevcut kaynaktan gelir. |
| Ay seferinden önce Bolo | Oyuncu ilk [`Prepare Lander`](../../../scripts/planetary/PlanetaryView.gd#L1927) eylemini seçti, hazırlık koşulları geçerli ve Bolo'yla henüz tanışmadı. | `bolo_before_moon` açılır. Kapanışta Bolo'nun katılımını ve tanışma yolunu kaydet. Bekleyen hazırlık mevcut işleyişten devam eder. |
| Bolo'nun halkı | [Ana dünya dizisindeki](../../../resources/excavations/vesyn.tres#L13) beş sahanın sonuçları kaydedilmiş ve Bolo'yla tanışılmış. | `bolo_surface_invitation` açılır. Kabulde `bolo_people_joined` işlenir ve ana dünyaya tek seferlik +17.490 Population kapasitesi eklenir. Ertelemede teklif açık kalır. |
| Ay sinyali | İki Bolo tanışmasından biri tamamlandı. | `bolo_lunar_signal` hedefi Ay'a erişilince The Rim Echo'ya odaklanır. Normal Ay erişimi ve sefer sırası mevcut oyundan gelir. |
| The Rim Echo | `moon_rim_echo` ve mevcut [kazı sonucu](../../../resources/stories/moon_1_rim_echo.tres#L52) | Araştırma ekibi dalı mevcut 150 Moonstone verir. Patlayıcı dalı mevcut 300 Science ve `moon_loud` etkisini taşır. İki Bolo tanışması aynı `meet_burkai` sahnesine ulaşır. |
| Ölümsüzlük keşfi | `meet_burkai` görüşmesi tamamlandı. | Ay kaydını, `immortality_revealed` ve Burkai'nin açılmasını birlikte kaydet. `mission_after_reveal` bir kez sıraya girer. Varyant, sahne açılırken ilk gezegene varışın kaydedilip kaydedilmediğinden seçilir. |
| Sefer brifingi | Advanced Planetary Rocket araştırması açıldı ve oyuncu ortak [Final Rocket hedef kartını](../../../scripts/planetary/PlanetaryView.gd#L1937) görüntüledi. | Kart `Read expedition briefing` eylemini gösterir. `expedition_briefing` herhangi bir dünyadan isteğe bağlı okunur. Eylem brifing bitene veya roket kalkana kadar açık kalır. |
| İlk gezegen varışı | [`_rocket_arrived`](../../../scripts/game/GameState.gd#L994) ve `civilization_reached` | Varış ve medeniyet geçişi mevcut işleyişle gerçekleşir. `planetary_arrival` sıraya girer. Ay kaydı durumu varış sahnesi ilk gösterildiğinde okunur. |

Kazı sonucu mevcut VSM seçimlerinden ödülleri ve bayrakları geçici bağlamda toplar. Kazı `finish` ile kapandığı anda bunları ve yeni danışman açılışını aynı kapanışta kalıcılaştır. Hazır bildirimini kazının tamamlandığı veya danışmanın açıldığı işaret olarak kullanma. Aynı hedef tekrar açıldığında kaydedilmiş kapanışı oku. [Hazır bildirimi ve kapanış](../../../scripts/game/excavation/Excavations.gd#L222)

İlk Ay aracının hazırlığında mevcut uygunluk kontrolünü önce yap. Bolo görüşmesi gerekiyorsa bekleyen hedefi ve sahne durumunu kaydet. `bolo_intro_route` ve Companions açılışı sahne sonunda birlikte işlenir. Ardından [`start_moon_colonization`](../../../scripts/game/GameState.gd#L806) uygunluğu tekrar kontrol eder, bedeli öder ve hazırlığı başlatır. Aynı hazırlık isteği yüklenirse önce kayıtlı sahneyi sürdür veya kapanmışsa mevcut hazırlık durumunu kontrol et. Böylece Bolo hazırlık başlamadan ekibe katılır ve çevrimdışı kalkış bu sırayı korur.

Varış olayını ve bekleyen sahneyi aynı kayıtta sakla. İlk gösterimde Ay kaydına göre seçilen dalı ve ilerleme düğümünü kaydet. Yeniden yükleme seçilmiş daldan devam eder. Mevcut bitiş kartı varış sahnesi kapandıktan sonra gösterilir. [Mevcut bitiş kartı çağrısı](../../../scripts/system/HUDManager.gd#L806)

Karşılaştırma satırı iki kaydın da bulunduğu ilk uygun sahnede, tek bir `arrival_signal_comparison` kimliğiyle görünür. Varış sahnesi henüz başlamadıysa o sahne satırı taşır. Ham kayıt dalı çoktan tamamlandıysa satır `mission_after_reveal` içinde görünür. Satırın görülmesini ve Narrative Log girdisini birlikte kaydet. Roket varıştan sonra seçilmiş hedefini korur. Ay görüşmesi o varışın ardından açılmışsa hedef türünden yüzey veya yörünge varyantını seç. [Varyantlar](SCENES.md#mission_after_reveal)

Katılım kapasitesini, ana dünya için [`world_max_population`](../../../scripts/game/Economy.gd#L454) toplamına sabit **17.490** olarak bir kez dahil et. Bu katkı `bolo_people_joined` kaydından türetilir ve imparatorluk toplamına mevcut toplama yoluyla yansır. Kabul dalını ve bayrağı aynı kayıt işleminde sakla. Ertelenen sahnenin seçim düğümü tekrar açılabilir. Yüzeydeki buluşma noktası kabul repliğinde tarif edilir. Oynanış etkisi kayıtlı kapasite katkısıdır.

### Eski Sera ve Dorian bağlantıları

Oyuncuya görünen eski karakter adları ve konuşmaları, [uyarlama metinleri](SCENES.md#eski-yoldaş-repliklerini-uyarlama) ile değiştirilir. Şu dört sayfada konuşmacı listelerini ve yoldaş katılım eylemlerini birlikte ele al.

- [The Compass Bearer](../../../resources/stories/vesyn_3_compass_bearer.tres) ve [The Ledger Vault](../../../resources/stories/vesyn_4_ledger_vault.tres)
- [The Sealed Hatch](../../../resources/stories/moon_3_sealed_hatch.tres) ve [Foundations](../../../resources/stories/moon_4_foundations.tres)

[The Trader's Cache](../../../resources/stories/vesyn_2_traders_cache.tres) içinde sandığın sahibiyle ilgili eski giriş ve sonuç satırlarını uyarlama tablosundan değiştir. [The Pale Line](../../../resources/stories/vesyn_5_pale_line.tres) ve [Builder's Marks](../../../resources/stories/moon_2_builders_marks.tres) için yeni bağlayıcı satırları ekle. Böylece Tip 0'ın dokuz kazısı da [sahne eşlemesinde](SCENES.md) yer alır.

Saha kaynağındaki `teaser` alanı kazı kartında ve haber bandında görünür. [Compass Bearer](../../../resources/excavations/sites/vesyn_compass_bearer.tres#L11), [Ledger Vault](../../../resources/excavations/sites/vesyn_ledger_vault.tres#L11), [Sealed Hatch](../../../resources/excavations/sites/moon_sealed_hatch.tres#L11) ve [Foundations](../../../resources/excavations/sites/moon_foundations.tres#L11) için [hazır kart metinlerini](SCENES.md#kazı-kartı-ve-haber-metinleri) kullan. [Haber kaynağı](../../../scripts/game/excavation/Excavations.gd#L231)

Kazı kimliklerini, sırasını, ödüllerini ve sonraki sahnelerin okuduğu bayrakları koru. Dört sayfadan eski danışman katılımını çıkar. Bolo ilk ana dünya kazısında veya Ay seferi öncesinde, Burkai The Rim Echo bağlantılı görüşmede açılır. Oyuncuya gösterilen kadro ve aktif bonus dört yeni karakter üzerinden hesaplanır.

## Kayıt sözleşmesi

| Veri | Anlamı |
| --- | --- |
| `narrative_version` | Yeni anlatı alanlarını eski kayıtlardan ayırır. |
| `onboarding_stage`, `tutorial_step` | Açılış, seçim ve devir sırası ile zorunlu öğreticinin sıradaki veya tamamlanmış adımı. |
| `active_advisor_id`, `unlocked_advisor_ids` | Tek etkin karakter ve Companions adayları. Kimlikler `mother_superior`, `high_father`, `bolo` ve `burkai`. |
| `advisor_switch_ready_at` | Atamanın takvim saniyesi + 1.200 ekonomi saniyesi. Bu süre 60 oyun ayına eşittir. İlk seçimde de kaydedilir ve çevrimdışı uygulanan takvim süresiyle ilerler. |
| `advisor_served_seconds` | Danışman kimliğine göre biriken görev süresi. Takvim adımı yalnız o sırada etkin olan danışmana yazılır. |
| `read_friendship_dialogue_ids` | Açılmış kişisel konuşmalardan tamamlananların kimlikleri. Açılma koşulu görev süresinden hesaplanır. |
| `bolo_intro_route`, `pending_moon_lander_target` | Bolo tanışma yolu `excavation` veya `spaceport`. İki değer de ham sinyal erişiminin ve Ay ipucunun edinildiğini gösterir. Bekleyen hedef, uzay limanı sahnesi kapanınca ilk Ay aracı hazırlığına devam etmek için saklanır. |
| `bolo_people_joined` | Yüzeye katılma teklifinin kabul edildiği ve sabit nüfus katkısının etkin olduğu kayıt durumu. |
| `immortality_revealed` | İki doku kaydının Ay'da çözümlendiği, keşif sonrası sahnelerin kullanılabileceği kayıt durumu. |
| `scene_progress`, `completed_scene_ids` | Son güvenli satır veya seçim düğümü, seçilmiş dal ve tamamlanmış sahneler. Görülmüş satır ile tamamlanmış sahne ayrı tutulur. |
| `narrative_log` | Oyuncuya gerçekten gösterilen satırlar, konuşmacı, sahne, sıra ve verilmiş cevaplar. Eski satır sonradan değişirse geçmişi korumak için gösterilmiş metni sakla. |
| `seen_bark_ids` | İlk gösterimi yapılan olay repliklerinin CSV kimlikleri. Boşta replik seçimi için her danışmanın son repliği ayrı tutulabilir. |
| `calendar_elapsed_seconds` | İlk dilimden itibaren koloni takvimine uygulanmış süre. Kısmi aylar dahil kaydedilir. |
| `offline_anchor_at`, `last_applied_offline_window`, `pending_return_reports` | Slotun son geçerli oturum veya dönüş zamanı, uygulanan son yokluk aralığı ve henüz kapanmamış dönüş raporları. Çevrimdışı dilimde eklenir. |

Kritik geçişi mevcut kayıt işlemiyle aynı noktada kaydet. Oyuncu seçimden sonra çıkarsa seçimi geri yükle. Ödül toplanırken çıkarsa tamamlanma durumuna göre aynı sonucun tekrar uygulanmasını önle. Narrative Log'dan okuma, sahne düğümünü veya ödülü yeniden çalıştırmaz.

### Koloni takvimi

Canlı sayaç ilk dilimde, `opening_handover` kapanınca 2465'in birinci ayında sıfırdan başlar. Her 20 ekonomi saniyesi bir koloni ayı, her 240 saniye bir yıldır. Sayaç canlı simülasyon ilerledikçe artar ve kısmi aylarla birlikte kaydedilir. Duraklatılmış canlı simülasyon takvim ya da görev süresi eklemez. Atama eşiği, takvim saniyesi + 1.200 saniyedir. Çevrimdışı dilim eklendiğinde işlenen süre aynı sayaca uygulanır. [Takvim göstergesi](UI.md#koloni-takvimi)

### Kalp kademesi hesabı

```text
yarım_kalp_adımı = min(10, floor(birikmiş_görev_saniyesi / 12000))
tam_kalp = floor(yarım_kalp_adımı / 2)
gösterilen_kalp = yarım_kalp_adımı / 2
etkin_bonus = 0,10 + tam_kalp × 0,02
```

12.000 ekonomi saniyesi 50 oyun yılıdır. Görev süresini takvim ve ekonomi ilerlemesiyle aynı işlemde bir kez yaz. Her yarım kalp eşiği bir konuşma açar. Konuşma, öğretici tamamlandığında Companions'ta görünür. Etkin bonusu tam kalp eşiklerinde yenile. Çevrimdışı aralık 24.000 saniyenin ilgili bir katını geçerse ekonomi ilerlemesini tam kalp eşiğinde böl ve yeni oranı sonraki süreye uygula. Okunmuş konuşma kimliği, kalp kademesinden bağımsız kaydedilir. [Bonus tablosu](ADVISORS.md#arkadaşlık-ve-kalpler)

**Eski kayıtlar.** Tasarımın hedefi yeni oyun ve bu sürümde üretilen kayıtların kendi içindeki devam davranışıdır. Önceki sürüm kayıtlarının taşınması uygulayan geliştiricinin kararıdır.

## Çevrimdışı simülasyon sınırı

Kalıcı kayıtlarda yokluk simülasyonu sürekli açıktır. Oyuncu bir slota girdiğinde seçilen dünyanın kayıt durumu geri yüklenir, sonra ilk canlı simülasyon adımından önce o slotun yokluk aralığı işlenir. Menü ön yüklemesi aralığı uygulamaz ve slotun zaman damgasını ilerletmez. Uygulama genelindeki `_offline_measured` bayrağı yerine slotun kendi işlenmiş aralığını ve `offline_anchor_at` değerini kullan. Zaman damgasını etkin slot kaydedilirken, slot oturumu sona ererken veya bir yokluk başarıyla işlendiğinde güncelle. Açık bir slotun duraklatılmış süresi yokluk hesabına girmez. Yetki devri tamamlanınca ilk zaman damgası yazılır. [Ön yükleme](../../../scripts/game/GameState.gd#L328) · [Oyuncunun slot girişi](../../../scripts/system/MainMenu.gd#L743) · [Mevcut ölçüm](../../../scripts/game/GameState.gd#L1362)

```text
geçerli_kapalı_süre = min(max(geçen_gerçek_süre, 0), 86400 saniye)
ortak_ilerleme_süresi = geçerli_kapalı_süre × 0,10
takvim_süresi = ortak_ilerleme_süresi
ekonomi_süresi = ortak_ilerleme_süresi
```

**Onaylı.** Üretim, tüketim, bakım ve başlamış inşaat, yükseltme, kazı, hazırlık ve uçuşlar ortak süreyi kullanır. 10 dakikalık yokluk takvimde üç ay, işlerde 1 dakika ilerler. 24 saat ve üzeri yokluk en fazla 2 saat 24 dakika, yani 36 oyun yılı ilerletir. Aralık işlendiğinde gerçek dönüş anı yeni başlangıç olarak kaydedilir. 24 saati aşan bölüm bir sonraki yüklemeye devretmez.

Girdi ve çıktı miktarları tamamlanan çevrimlerde mevcut tariften gelir. %10 çarpanı süreye bir kez uygulanır. Süreyle birlikte tarif miktarını da çarpmak hızı %1'e indirir. Kısmi çevrim ilerlemesini ve o çevrimin ödenmiş girdi durumunu kayıtta taşı. Tamamlanmış iş normal sonucu bir kez verir. Kazının hikâye kapanışı oyuncu dönünce gerçekleşir. [Mevcut girdi ödemesi](../../../scripts/game/ProductionManager.gd#L270)

Yokluk süresince kaydın etkin danışmanı kullanılır. Süre tamamlandığında görev süresi dolmuş olabilir. Yeni atama oyuncunun dönüşteki seçimine bağlıdır. İlk uygulamada kazanç sınırı 24 saat ve %10 kuralıyla belirlenir.

Olay kaydı `id`, `kind`, `body_seed`, varsa sabit konum, sonuç verisi ve uygulandığı anı taşır. Ekonomi, takvim, iş sonuçları, işlenmiş pencere ve bekleyen rapor tek slot işlemiyle diske geçer. Tam kayıt geçici dosyaya yazıldıktan sonra slot dosyasının yerini alır. Kesintiden sonra yükleme ya eski tam kaydı ya da işlenmiş tam kaydı kullanır. İşlenmiş pencerenin raporu, oyuncu kapatmadan çıkarsa yeniden açılır. Sonraki yokluk yeni bir rapor ekler ve bekleyen raporlar oluşma sırasıyla sunulur. Her rapor kendi yokluğunun süresini, danışmanını ve sonuçlarını saklar. [Olay seçimi](OFFLINE_EVENTS.md) · [Dönüş replikleri](SCENES.md#dönüş-ve-gemi-uykusu)

## Geliştiricinin teslim kontrolü

1. İki ayrı yeni kayıtta her AI seçeneğinin doğru açılış dalı, ilk hedef ve ilk City'ye ulaştırdığı senaryoları kullanıcıya sun.
2. Açılış, seçim, yerleştirme ve ilk sonuç sahnesi ortasında kayıt kapatıldığında devam koşullarını belgelenen duruma göre kontrol edilebilir bırak.
3. Yeni oyundaki zorunlu öğreticinin ilk kazıdan bağımsız tamamlandığı ve erken tanışılan danışmanın görev süresi dolana kadar beklediği senaryoları hazırla.
4. İlk kazıda tanışan ve ilk Ay aracı hazırlanırken tanışan oyuncular aynı Burkai görüşmesine ulaşır. Uzay limanı yolundan ilk kazıya geri dönüldüğünde tanışma tekrarlanmaz. İki yolun kazı ve sefer ödüllerini birer kez verdiği senaryoları hazırla.
5. Çevrimdışı sistem devreye girdiğinde iki slot arasında geçişi, rapor açıkken çıkıp dönmeyi, 24 gerçek saat sınırını, ortak %10 ilerlemeyi, kısmi çevrimlerin devamını ve sonraki kazılara yer bırakmayan bir yıkım hedefinin elenmesini ayrı senaryolarla göster.
6. Ana dünyadan okunan roket brifingi, Ay kaydından önce ve sonra gerçekleşen varış ve gaz devi hedefi için geçerli sahne dallarını göster.

Bu maddeler kullanıcı tarafından yapılacak oynanış doğrulamasının kapsamını tarif eder.

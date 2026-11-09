# Voidle Anlatı Tasarım Sırası

[Ana belge](README.md) · [Hikâye](STORY.md) · [UI](UI.md) · [Diyaloglar](DIALOGUE.md) · [Danışmanlar](ADVISORS.md)

Teslim, ana ve yan hikâyeleriyle mevcut Tip 0'ın ilk gezegen varışına kadar uzanır. İlk dilim dünyayı gösterir, AI seçimini açar, zorunlu öğreticiyi ve ayrı ilerleyen ilk kazıyı kurar. Final, sonraki medeniyetlere ve henüz tanışılmamış kişilere bir işaret bırakır.

## Uygulama sırası

| Dilim | Uygulama kapsamı | Devralma kaynağı |
| --- | --- | --- |
| 1. Açılış | Ana dünya görünümü, ön anlatım, ilk AI seçimi, başlangıç bonusu, görev devri, canlı koloni takvimi ve mevcut City yerleştirme akışı. | [Sahne metinleri](SCENES.md#açılış-ve-danışman-seçimi) · [Durum akışı](IMPLEMENTATION.md) |
| 2. Öğretici ve ilk kazı | AI rehberliği, Narrative Log, Companions adayları, ayrı ilerleyen The Toppled Stones ve Bolo. | [İlk oturum](STORY.md) · [Arayüz](UI.md) · [Kazı eşlemesi](IMPLEMENTATION.md#kazı-ve-sefer-eşlemesi) |
| 3. Gündelik diyalog | Etkin danışman, CSV'den idle ve olay replikleri, gösterim sırası ve kaydedilmiş geçmiş. | [CSV başlangıç içeriği](DIALOGUE.md#gündelik-konuşma-csvsi) · [Kayıt](IMPLEMENTATION.md#kayıt-sözleşmesi) |
| 4. Ay ve ilk gezegen | Kazıyı erteleyen oyuncu için Ay öncesi Bolo karşılaşması, The Rim Echo, Burkai ve ölümsüzlük keşfi, eski yoldaş sahnelerinin uyarlanması ve ilk gezegen varışı. | [Sahneler](SCENES.md) · [Kazı ve sefer eşlemesi](IMPLEMENTATION.md#kazı-ve-sefer-eşlemesi) |
| 5. Denge ve çevrimdışı | İlk dilimdeki takvimin ve atama kilidinin çevrimdışı ilerlemesi, kalp kademeleri, ortak %10 çalışma süresi, olaylar ve gemi uykusundan dönüş. | [Danışmanlar](ADVISORS.md) · [Olay CSV'leri](OFFLINE_EVENTS.md) |

Sahne metni, replik sırası ve küçük anlatı ayrıntıları [Sahneler](SCENES.md) içinde düzenlenebilir yazım kararlarıdır. Kullanıcıya danışılması gereken konular, kabul edilmiş kuralla çelişen değişiklikler ve ekonomiyi, takvimi, dünya durumunu veya eski kayıtların ilerlemesini etkileyen tercihlerdir.

## İlk dilimin hazır sayılması

1. Yeni oyunda dünya hemen görünür. Kısa anlatım ve AI konuşması bittikten sonra oyuncu iki AI’dan birini seçer. Seçilen AI yetkiyi teslim eder ve ilk City yer seçimine yönlendirir. Oyuncu City, Capital District ve bina ilişkisini ilk yatırımını yapabileceği kadar anlar.
2. Öğreticinin tamamı AI ile yürür. Oyuncu Science’ını araştırmaya harcayıp kazıyı erteleyebilir ve öğreticiyi bitirebilir. **Mevcut** ilk kazı 300 Credits, 50 Science ve beş dakikalık oyun süresi kullanıyor. Kazı başlarken maliyet ve bekleme görünür. [Kazı kaynağı](../../../resources/excavations/sites/vesyn_toppled_stones.tres) · [Süre tanımı](../../../scripts/game/excavation/ExcavationSiteDef.gd) · [Varsayılan denge](../../../resources/balance/profile_current.tres)
3. Kazının hazır bildirimi ve Bolo’yla karşılaşma ayrı anlardır. Bolo sonuç sahnesinde kadroya katılır. Öğretici devam ediyorsa AI ile tamamlanır. Sahnenin geçerli yolları ortak tanışma anına ulaşır.
4. Oyuncu Companions ekranında aktif danışmanı, bonusunu ve iki AI dahil diğer açılmış seçenekleri görebilir. Hikâye sahnesi açıkken atama sahne kapanana kadar bekler.
5. Oyuncu Narrative Log ile daha önce gördüğü konuşmalara dönebilir. Kaydı yüklediğinde konuşma geçmişi ve tek seferlik olayların durumu korunur. Tamamlanmamış sahneye devam, sıradaki gündelik konuşmalar ve öğretici tercihi [UI](UI.md) ile [Diyaloglar](DIALOGUE.md) içinde birlikte tarif edilir.

## Uygulama öncesi bağımlılıklar

Bu başlık tasarımın Godot’a çevrilebilmesi için kaynak bağlantılarını tarif eder. Uygulama sırası, ilgili kararlar alındığında somutlaştırılır.

| İş | Kontrol edilecek kaynak | Tasarımda karara bağlanacak sınır |
| --- | --- | --- |
| Yeni oyun ve ilk şehir | [MainMenu](../../../scripts/system/MainMenu.gd), [PlanetaryView](../../../scripts/planetary/PlanetaryView.gd) | Görev devri bir yeni oyun olayıdır. Kayda devam etme, demo ve aynı oyun içinde tekrar görüntüleme ayrı girişlerdir. |
| Anlatı olayları ve kaydetme | [GameState](../../../scripts/game/GameState.gd), [Excavations](../../../scripts/game/excavation/Excavations.gd) | Ödül, yeni danışman ve seçim sonucu sahne kapanışında bir kez işlenir. Önceki sürüm kayıtları için geçiş politikası uygulayan geliştiriciye bırakılır. |
| Görev ve diyalog yüzeyi | [TutorialManager](../../../scripts/system/TutorialManager.gd), [ObjectivesCard](../../../scripts/ui/components/ObjectivesCard.gd), [StoryDialog](../../../scripts/ui/excavation/StoryDialog.gd) | Yeni HUD sunumunun rehberlik, eski öğreticinin girdiyi kısıtlaması ve mevcut kazı verisiyle ilişkisi. Panel ile diyalog verisinin yeniden kullanımı ayrı kararlar. |
| Danışman ve üretim | [CompanionDef](../../../scripts/game/excavation/CompanionDef.gd), [Economy](../../../scripts/game/Economy.gd), [ProductionManager](../../../scripts/game/ProductionManager.gd) | Tek aktif etki, açık bonus kapsamı, değişim anı ve bonus altında başlamış üretim ya da inşaat işi. |
| Dönüş raporu | [HUDManager](../../../scripts/system/HUDManager.gd), [GameState](../../../scripts/game/GameState.gd) | En fazla 24 gerçek saatin %10'u takvim ve ekonomiye yazılır. Danışman, koruyucu uykudan dönüşte kaydedilmiş sonuçları anlatır. |
| Ay ve sonrası | [GameState](../../../scripts/game/GameState.gd), [Ay kazı dizisi](../../../resources/excavations/moon.tres), [Final Rocket hedef kartı](../../../scripts/planetary/PlanetaryView.gd#L1937) | Bolo'nun sinyali The Rim Echo'ya bağlanır. Burkai o kazının sonucunda açılır. Sefer brifingi ortak hedef kartından okunur. İlk gezegen varışı aynı sinyalin ikinci kaydını verir. |

## Uygulamadan önce kapanacak mekanik kararlar

| Karar | Şu anki tasarım ve öneri | Etkilediği dilim |
| --- | --- | --- |
| Çevrimdışı denge | İlk olay havuzunun seçim oranları ve onarım süresi [olay belgesinde](OFFLINE_EVENTS.md) başlangıç değeri olarak verildi. İlk uygulama için ayrı Credits ve Science tavanı varsayılmadı. | Denge ve çevrimdışı |

İlk açılış ve kazı dilimleri olay denge değerlerinden bağımsız geliştirilebilir. Companions kartları etkin bonusu, dönüş ekranı simüle edilmiş zamanı ve gerçekleşen olayları gösterir.

## Karar kaydı

Sonraki görüşmelerde onaylanan değişiklikler için aşağıdaki kısa kayıt yeterli. Bir karar birden fazla modülü etkiliyorsa burada tek kayıt açılır, ayrıntılar ilgili dosyalara gider.

| Kimlik | Durum | Karar ve etkisi |
| --- | --- | --- |
| N-01 | Karar | Nükleer savaş 2200’de başlar. I-330’un inişinden 25 yıl sonra, 25 yaşındaki 17.490 kişilik ilk kuşak kalıcı bir City kurmaya hazırdır. Oyun ilk Facilitator’ın seçildiği gün açılır. |
| N-02 | Karar | Oyuncu liderlik için genetik olarak hazırlanmıştır. Dünya açılışta hemen görünür. Kısa anlatım ve AI konuşmasından sonra oyuncu iki AI’dan birini seçer. Seçilen AI yetkiyi teslim eder ve görev listesini verir. |
| N-03 | Karar | Yeni kadro iki AI, Bolo ve Burkai'dir. Bolo ilk ana dünya kazısında veya kazı ertelendiyse Ay aracı hazırlanmadan önce uzay limanında açılır. İki yolda da Bolo Ay seferine katılır. Bolo'nun sinyaliyle gidilen Ay kazısının sonucu Burkai'yi açar. |
| N-04 | Karar | Tek danışman aktiftir. Mother Superior Credits, High Father Energy, Bolo Science ve Burkai Production için +%10 verir. Her atama en az 5 oyun yılı sürer. |
| N-05 | Karar | Diyaloglar portreli visual novel panelinde görünür. Tercih edilen yer alt bölge, alan dar olduğunda alternatif üstteki mevcut öğretici bölgesidir. Görülmüş konuşmalar Narrative Log üzerinden okunabilir. |
| N-06 | Karar | Kalıcı kayıtlarda çevrimdışı her zaman açıktır. En fazla 24 gerçek saat sayılır. Takvim ve ekonomi ortak %10 hızda ilerler. Bir yoklukta en fazla bir büyük olay olur. [Olaylar](OFFLINE_EVENTS.md) |
| N-07 | Karar | New Game'de öğretici zorunludur ve tamamını AI yürütür. İlk ana dünya kazısı ayrı ilerler. |
| N-08 | Karar | Aktif danışman belirli aralıklarla boşta konuşur ve oyun olaylarına tepki verir. Bu replikler ayrı bir CSV dosyasında tutulur. |
| N-09 | Karar | Tip 0 ilk gezegen varışında biter. İlerisi için yeni bir ses ve Companions'ta adsız silüetler gösterilebilir. Kazı görüşmeleri seferi kilitlemez. |
| N-10 | Karar | Takvim 20 ekonomi saniyesini bir ay sayar. 24 saatlik yokluk en fazla 36 oyun yılı ilerletir. |
| N-11 | Karar | Bolo'nun geçmişinde Ece sahneleri kanondur. Halkı yeraltında yaşar ve Titan'a gönderilen grubun sayısı 150'dir. |
| N-12 | Karar | Her 50 birikmiş görev yılı yarım kalp ve bir kişisel konuşma açar. Her 100 yılda dolan tam kalp bonusu iki yüzde puanı artırır. Başlangıç +%10, 500 yılda beş kalple +%20. |
| N-13 | Karar | Beş ana dünya kazısı tamamlanınca Bolo halkının tamamı adına katılım teklifini getirir. Kabulde ana dünyaya bir ilk City kadar, tek seferlik +17.490 Population kapasitesi eklenir. |
| N-14 | Karar | Bolo ilk karşılaşmada yaşlanmasını araştırır. Ay'da Burkai, Bolo ve Facilitator'ın neden yaşlanmadığını gösterir. Keşif, başka gezegenlerde kalıcı varlık kurma görevine bağlanır. Görüşme, seferin herhangi bir aşamasında yapılabilir. |

Yeni satır şablonu `N-XX | Karar, Yazım, Öneri veya Açık | Seçim, etkilenen olay ve dosyalar`. Yazım ayrıntıları sahne metninde düzenlenebilir. Onaylanan mekanikleri bu kayıtla eşleştir.

## İleride ele alınacaklar

- Olası sandbox modu ve o modun ayrı öğretici davranışı.
- Tip 0 sonrasındaki sesin kimliği, yeni yoldaşlar ve daha uzak medeniyetlerin hikâyeleri.

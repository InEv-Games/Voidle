# Voidle danışman sistemi

[Ana belge](README.md) · [Hikâye](STORY.md) · [Diyalog](DIALOGUE.md) · [Arayüz](UI.md) · [Tasarım sırası](ROADMAP.md)

Bu belge danışmanların nasıl açıldığını, aktif danışman seçiminin etkilerini ve seçim değişikliğinin kurallarını tanımlar. **Karar** kabul edilen tasarımı, **öneri** tartışmaya açık başlangıç modelini, **açık** daha sonra doldurulacak kararı belirtir. Uygulama durumu ayrı bölümde kayıtlıdır.

## Kadro ve açılma koşulları

| Danışman | Erişim | Oyun etkisi |
| --- | --- | --- |
| **Mother Superior** | **Karar.** Açılıştaki iki AI danışmandan biri. | **Karar.** Credits üretimi, başlangıç +%10. |
| **High Father** | **Karar.** Açılıştaki diğer AI danışman. | **Karar.** Energy arzı, başlangıç +%10. |
| **Bolo** | **Karar.** İlk ana dünya kazısının sonunda veya Ay aracının hazırlığından önce uzay limanında tanışınca kadroya katılır. | **Karar.** Science üretimi, başlangıç +%10. |
| **Burkai** | **Karar.** Bolo'nun sinyalinin işaret ettiği The Rim Echo kazısı sonuçlanınca kadroya katılır. | **Karar.** Production, başlangıç +%10. **Uygulama kapsamı.** Ham çıkarım ve Goods, Fuel, Rare Elements üretimi. |

**Karar.** Mother Superior ve High Father mevcut **Companions** kadrosunda Bolo ve Burkai ile aynı yüzeyde yer alır. Bir anda yalnızca bir aktif danışman vardır. Oyuncu erişimi açılan yoldaşlardan birini seçer. Seçilen danışman gündelik konuşmaları ve kendi oyun bonusunu üstlenir. Yeni karakterlerle tanışmak seçim havuzunu genişletir.

**Karar.** Açılışta dünya hemen görünür. Oyuncu kısa bir geçmiş anlatımı ve AI diyaloğunun ardından, ilk City yerleşimine geçmeden Mother Superior veya High Father'ı aktif danışman olarak seçer. Seçilen AI öğreticinin tamamında rehberlik eder. Öğretici, oyuncunun ilk ana dünya kazısını ne zaman yapacağından bağımsız tamamlanır.

**Uygulama kuralı.** Kazı ekibinin işi bitirmesi ve oyuncunun sonuç sahnesini tamamlaması ayrı olaylardır. Bolo ilk kazıdaki veya Ay seferi öncesindeki tanışma tamamlandığında listede görünür. Atama, zorunlu öğretici tamamlandıktan ve aktif danışmanın asgari görev süresi dolduktan sonra yapılır. Aynı kural Burkai için geçerlidir. Ana seferleri kendi hızında yapan oyuncu seçtiği AI ile devam edebilir. AI arada ulaşılabilir kazılara dönmeyi önerir.

## Konuşma ve bonusun kapsamı

| Katman | Kural |
| --- | --- |
| Günlük danışmanlık | **Karar.** Aktif danışman aralıklarla boşta konuşur ve yapılan işlere tepki verir. **İlk uygulama varsayımı.** Gündelik replikler CSV'den okunur. Olay tepkisi önceliklidir, boşta konuşma 90 saniye uygun oynanış bekler. [Diyalog verisi](DIALOGUE.md#gündelik-konuşma-csvsi) |
| Hikâye sahnesi | **Öneri.** Görev devri, ilk karşılaşma ve benzeri yazılmış sahnelerde olayın içindeki karakterler kendi repliklerini söyler. Bolo'nun kazı sahnesi aktif danışman kim olursa olsun açılır. Bu sahnelerin konuşmacıları [diyalog dosyasında](DIALOGUE.md) belirtilir. |
| Oyun etkisi | **Karar.** Aktif danışmanın tek bonusu uygulanır. Profil, kapsamı ve yüzdeyi gösterir. |
| Görev durumu | **Öneri.** Ortak görev listesi ve tamamlanma durumu danışmanlar arasında taşınır. Seçim, anlatım ve bonusu değiştirir. |
| Sunum | **Karar.** Yoldaş inceleme ve danışman atama için mevcut Companions ekranı kullanılır. **Öneri.** Aktif danışmanın portresi, kısa bonus açıklaması ve değişim kilidi burada görünür. [Arayüz dosyası](UI.md) |

Kaynak bonusları mevcut üretim çarpanlarına bağlanır. Mother Superior'ın Credits ve Bolo'nun Science bonusu, ilgili düzenli üretime ve araştırmayla açılmış aynı türdeki boşta nüfus gelirine bir kez uygulanır. Gelir göstergesi ve stok hareketi aynı hesabı kullanır. High Father'ın Energy artışı arz hesabında uygulanır. Burkai'nin Production kapsamı, mevcut `RAW` kaynak bonusunun ham çıkarım, Goods, Fuel ve Rare Elements eşlemesini kullanır. Danışman değişince üretim önbelleği geçersiz kılınır. Ticaret, görev ödülleri ve tek seferlik hibeler kendi kaynak verisini kullanır. [Mevcut kaynak eşlemesi](../../../scripts/game/excavation/Excavations.gd#L82) · [Boşta nüfus geliri](../../../scripts/game/ProductionManager.gd#L888) · [Enerji hesabı](../../../scripts/game/ProductionManager.gd#L980)

## Arkadaşlık ve kalpler

**Karar.** Her danışman, etkin görevde biriktirdiği her 50 oyun yılında yarım kalp ve bir kişisel konuşma kazanır. Her tam kalp, yani her 100 görev yılı, etkin danışmanın bonusunu iki yüzde puanı artırır. Üst sınır 500 yılda beş tam kalp ve toplam +%20 bonustur.

Süre atamalar arasında birikir. Seçili danışmanın görev süresi, takvim ilerlerken artar. Çevrimdışında hesaba ortak %10 hızla geçen koloni süresi girer.

| Birikmiş görev süresi | Kalp | Etkin danışmanın toplam bonusu |
| --- | --- | --- |
| 0 yıl | 0 | +%10 |
| 50 yıl | 0,5 | +%10 |
| 100 yıl | 1 | +%12 |
| 150 yıl | 1,5 | +%12 |
| 200 yıl | 2 | +%14 |
| 250 yıl | 2,5 | +%14 |
| 300 yıl | 3 | +%16 |
| 350 yıl | 3,5 | +%16 |
| 400 yıl | 4 | +%18 |
| 450 yıl | 4,5 | +%18 |
| 500 yıl | 5 | +%20 |

Bonus tam kalp eşiği geçildiği anda uygulanır. Öğretici tamamlandıktan sonra açılmış konuşma Companions'ta `New Conversation` olarak görünür. Her konuşma tek başına okunabilir. Sonradan tekrar atanan danışman biriktirdiği süreyle devam eder. Companions, toplam görev yılını ve sıradaki yarım kalbe kalan süreyi gösterir. [Kalp konuşmaları](SCENES.md#kalp-konuşmaları)

## Danışman değiştirme

**Karar.** Her danışman ataması, ilk AI ataması dahil, en az **5 oyun yıllık görev süresi** başlatır. Süre oyun takviminden okunur. Çevrimdışı uygulanan takvim ilerlemesi de görev süresinden sayılır. Öğretici boyunca seçilen AI rehberlik eder.

Seçim yapılınca konuşmacı ve bonus aynı anda güncellenir ve görev başlangıcı kayda yazılır. Companions profili kalan süreyi yıl ve ay olarak gösterir. Yeni karakterin açılması onu görünür yapar. Atama için görev süresinin dolması, öğreticinin tamamlanması ve ana sahnenin veya dönüş özetinin kapanmış olması gerekir. Aynı danışmanın kartına dönmek atama sayılmaz. Oyuncuya kuralı seçilen AI bir cümleyle anlatır. [Görev devri replikleri](SCENES.md#opening_handover)

## Oyuna dönüş ve kayıt

**Karar.** Kalıcı kayıtlarda çevrimdışı ilerleme sürekli açıktır. Bir yokluk en fazla **24 gerçek saat** sayılır. Takvim ve ortak ekonomi saati, bu sürenin **%10'u** kadar ilerler. 24 saat sonunda 2 saat 24 dakikalık normal oyun ilerlemesi uygulanır. 20 saniyelik aylarla bu süre **36 oyun yılına** eşittir.

**Karar.** Aynı süre için çevrimdışı **üretim, tüketim ve iş ilerlemesi normalin %10'u** kadardır. Normalde 20 girdi tüketip 10 çıktı üreten bir işin hız karşılığı çevrimdışında 2 girdi ve 1 çıktıdır. İnşaat, yükseltme, kazı, hazırlık ve uçuş dahil başlamış işler ortak ekonomi zamanında ilerler. [Zaman ve çevrim hesabı](IMPLEMENTATION.md#çevrimdışı-simülasyon-sınırı)

**Karar.** Bir dönüşte en fazla bir büyük rastgele olay görülebilir. Birden fazla küçük olay kayda geçebilir. Sahipsiz arazi ve kalıntılar değişebilir. Küçük oyuncu yapıları onarım gerektiren hasar alabilir. İlerleme için gerekli sahalar ve yerleşim merkezleri korunur. Danışman yalnız kayda geçen sonuçları anlatır ve konumu varsa haritaya gitme eylemi sunar. Kazı ve hikâye seçimleri oyuncunun katılımını bekler. [Olay verisi ve uygulama](OFFLINE_EVENTS.md)

Yokluk aralığının danışmanı, oyuncunun kapattığı slotta etkin olan karakterdir. Rapor aynı danışmanı kaydeder. Oyuncu bekleyen raporları kapattıktan sonra uygun bir danışman seçebilir. Yeni atama sonraki ilerlemeye etki eder. [Slot ve rapor kuralları](IMPLEMENTATION.md#çevrimdışı-simülasyon-sınırı)

Kayıt açılmış danışmanları, etkin danışmanı, 5 yıllık görev süresinin takvim sonunu, görülmüş sahneleri ve sunulmuş dönüş özetini taşır. Oyuncu geçmiş konuşmaları Narrative Log'da okuyabilir. [Arayüz dosyası](UI.md)

### Dönüş olayları için başlangıç havuzu

| Olay | İlk sürüm için önerilen kayıt | İngilizce rapor örneği |
| --- | --- | --- |
| Tamamlanan iş | Gövde ve iş kimliği, işin tamamlandığı an. | The crew finished the work at {location}. You can inspect it on the map. |
| Yeni arazi keşfi | Gövde ve haritadaki keşif noktası. Önerilen ilk olay, mevcut arazide bir kaya çıkıntısını keşif olarak işaretler. | The survey found an exposed ridge at {location}. I saved the coordinates. |
| Arazi değişimi | Etkilenen konum ve gözlenen değişiklik. Oluşturma kuralları denge ve harita tasarımına bağlı. | A slide changed the slope at {location}. I marked the new edge. |
| Hasar | Onarım gerektiren yardımcı üretim binası veya çökmüş sahipsiz kalıntı. Uygun hedefler olay belgesinde tarif edilir. | The crew isolated the damaged unit at {location}. It is waiting for repair. |

Her aralıkta önce gerçekleşen işler ve uygun dünya olayları kaydedilir. Aktif danışman en önemli üç sonucu öne çıkarır. Kalanlar ayrıntı görünümüne ve Narrative Log'a eklenebilir. Olay sıklığı ve yapılar üzerindeki etkiler [mekanik kararları](ROADMAP.md#uygulamadan-önce-kapanacak-mekanik-kararlar) içinde tutulur.

## Akış örnekleri

Tablo, kararları ve önerilen davranışları birlikte gösterir. `first_excavation_ready`, `meet_bolo` ve `meet_burkai`, [hikâye dosyasındaki](STORY.md) örnek olay adlarıdır.

| Durum | Beklenen tasarım davranışı |
| --- | --- |
| Oyuncu yeni oyuna başlıyor | Dünya görünür, kısa açılış diyaloğu oynar ve oyuncu ilk City yerleşiminden önce iki AI'dan birini seçer. Seçilen AI öğretici boyunca rehberlik eder. |
| İlk kazı hazır, sonuç sahnesi bekliyor | `first_excavation_ready` ile ekipten hazır bildirimi gelir. Bolo'nun açılması sahnenin sonuna bağlı kalır. |
| Oyuncu ilk karşılaşmayı öğretici sürerken bitirdi | `meet_bolo` tamamlanınca Bolo danışman listesine gelir. Seçilen AI öğreticiyi bitirir. Bolo'ya geçiş, öğreticinin bitişi ve değişim koşullarıyla açılır. |
| Oyuncu ilk kazı sonucunu görmeden Ay aracını hazırlıyor | `bolo_before_moon` tamamlanınca Bolo sefere ve Companions kadrosuna katılır. Günlük konuşmalar, bonus ve görev süresi etkin danışmanda kalır. |
| Oyuncu sinyalin gösterdiği Ay kazısının sonuç sahnesini tamamladı | `meet_burkai` sahnesinde Burkai kendi repliğini söyler ve sahnenin sonunda danışman listesine eklenir. Günlük kanalda aktif danışman konuşmaya devam eder. |
| Oyuncu değişim kilidindeyken yeni danışman açtı | Yeni danışmanın kartını ve bonusunu inceleyebilir. Olağan seçim için kalan süre gösterilir. |
| Oyuncu daha önce görev yapmış bir danışmanı yeniden atadı | Danışman birikmiş görev süresini, kalplerini ve açılmış konuşmalarını korur. Yeni atama beş yıllık asgari görev süresini başlatır. |
| Oyuncu oyunu 24 saatten uzun kapalı tuttu | Takvim ve ekonomi 2 saat 24 dakikalık normal oyun karşılığı ilerler. Danışman, I-330'daki uykudan dönüşü ve gerçekleşen sonuçları anlatır. |

## Güncel Godot kaynakları

- **Mevcut.** `global_mult` ve `build_speed` katılmış yoldaşların ilgili bonuslarını toplar. `finish` kazı sonuç sahnesi tamamlandığında yoldaşı kayda ekleyebilir. [Kazı ve bonus hesabı](../../../scripts/game/excavation/Excavations.gd)
- **Mevcut.** Yoldaş tanımları kaynak ve inşaat hızı bonusu türlerini taşır. HUD'daki Companions düğmesi mevcut yoldaş galerisini açar. AI profilleri, aktif atama ve değişim kilidi bu ekrana eklenecek durumlardır. [Yoldaş tanımı](../../../scripts/game/excavation/CompanionDef.gd) · [Yoldaş galerisi](../../../scripts/ui/excavation/CompanionGallery.gd) · [HUD](../../../scripts/system/HUDManager.gd#L207)
- **Mevcut.** Kayıt kazı ve yoldaş durumunu, oynanan süreyi ve son kayıt anını saklar. HUD dönüşte geçen süreyi gösterir. Gerçek çevrimdışı ilerleme ve danışman raporu tasarım kapsamındadır. [Kayıt durumu](../../../scripts/game/GameState.gd) · [Dönüş ekranı](../../../scripts/system/HUDManager.gd)

Kesinleştirme sırası ve oturumlar arası aktarım için [tasarım sırasına](ROADMAP.md) bak.

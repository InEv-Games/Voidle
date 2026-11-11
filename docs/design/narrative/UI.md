# Anlatı arayüzü

[Ana belge](README.md) · [Hikâye ve öğretici](STORY.md) · [Diyalog](DIALOGUE.md) · [Danışmanlar](ADVISORS.md) · [Tasarım sırası](ROADMAP.md)

## Tasarım durumu

**Karar.** Yeni oyunda ana dünya hemen görünür. Kısa bir anlatım ve AI diyaloğundan sonra oyuncu Mother Superior ile High Father arasından ilk danışmanını seçer. Seçilen AI yetkiyi devreder ve ilk şehir yerleşiminden öğreticinin sonuna kadar oyuncuya rehberlik eder. NPC konuşmaları portre ve metnin yan yana durduğu visual novel panelinde gösterilir. Geçmiş konuşmalar **Narrative Log** üzerinden yeniden okunabilir.

**Karar.** Mother Superior, High Father, Bolo ve Burkai aynı **Companions** kadrosunda yer alır. Aktif danışman gündelik konuşmaları ve kendi bonusunu üstlenir. Atamalar arasında bir bekleme süresi vardır. Arayüzün yerleşimi, düğme adları ve giriş davranışları aşağıda taslak olarak tarif edilir.

## Arayüz yüzeyleri

| Yüzey | İçerik | Oyuncunun yapabildiği |
| --- | --- | --- |
| Diyalog paneli | Konuşan kişinin portresi ve adı, replik, gerekiyorsa yanıt seçenekleri | Metni tamamla, ilerle, cevap seç, Narrative Log'u aç |
| Hedef kartı | Bir sonraki eylem, mevcut durum, ilerleme ve hedef konumu | İlgili haritayı, şehir panelini veya kazıyı aç |
| Companions | AI'lar ve diğer yoldaşlar, aktif danışman, bonus ve değişim durumu | Profili incele, uygunsa danışmanı ata |
| Narrative Log | Gösterilen konuşmalar ve dönüş özetleri | Geçmiş replikleri ve verilmiş cevapları yeniden oku |
| Kazı kartı | Kazı konumu, maliyeti, bekleme süresi, ilerleme ve sonuç | Kazıyı başlat, haritaya dön, sonuç sahnesini aç |
| Koloni takvimi | Güncel koloni yılı ve ayrıntıda ay | Yıl ve ay bilgisini incele |
| Haber bandı | Dünyada gerçekleşen olayların kısa özeti | İlgili konuma git |

Bir gelişme birkaç yüzeyde görünüyorsa her yüzey kendi bilgisini taşır. Örneğin kazı ekibi hazır olduğunda haber bandı konumu, hedef kartı yapılacak eylemi, sonuç sahnesi ise ekibin bulduğu şeyi taşır. Kazının sayısal durumu kendi kartında görünür.

## Diyalog paneli yerleşimi

```text
                  OYUN DÜNYASI VE HARİTA
                                  [Hedef kartı]

+------------------------------------------------------+
| [Portre]   Konuşan kişi                              |
|            Replik                                    |
|            [Yanıt A] [Yanıt B] veya [Continue]        |
+------------------------------------------------------+
                     [Haber bandı]
```

- Panelin birincil yeri, haritanın altında ve haber bandının üstündeki boş alandır. Sol ve sağ paneller arasındaki kullanılabilir alanın yaklaşık üçte ikisini kaplar. Portre sol tarafta yaklaşık dörtte birlik bir alan alır. Kalan alan ad, metin ve seçimlere ayrılır.
- Hedef kartı panelin sağında yer varsa orada kalır. Alan daraldığında diyalog panelinin üstüne alınır. Alt bölgede harita kontrolleriyle birlikte metin ve cevaplara yeterli yer kalmıyorsa panel eski öğreticinin üstteki anlatım alanına taşınır. Bu yedek konum, üst kaynak çubuğunun altında ve harita alanının ortasındadır. [Mevcut öğretici konumu](../../../scripts/system/TutorialManager.gd#L937)
- Uzun replikler metin sütununda satır kırar. Dar ekranlarda portre küçülür ve cevaplar alt alta dizilir. Yükseklik sınırına gelindiğinde metin kayar, devam ve seçim düğmeleri görünür kalır. Yerleşim ekran boyutu ve açık HUD panellerine göre belirlenir.
- Portre ve ad, konuşan karakter değiştikçe birlikte güncellenir. Anlatıcı satırında portre alanı kapanabilir veya sahnenin simgesi kullanılabilir. Harita hem alt hem üst konumda görünür kalır.
- Dört danışmanın PNG'leri diyalog panelinde ve Companions kartlarında kullanılır. Kaynakların boyutları farklı olduğu için kadraj, portre oranı korunarak görünümde hizalanır. [Karakter portreleri](README.md#karakter-portreleri)
- Güncel tema renkleri, başlık, düğme ve odak stilleri kullanılır. Aktif, kilitli ve seçilebilir durumlar metinle de belirtilir. Görsel ayrımlar yalnız renge bağlı kalmaz.
- Yazı animasyonunun hızını azaltma veya anında gösterme seçeneği ve okunabilir metin ölçeği tasarımda yer alır. Bir seçim görünüyorsa odağı klavye ve fare ile izlemek mümkün olur.

## Sunum ve giriş

| İçerik | Önerilen davranış | Örnek |
| --- | --- | --- |
| Ana hikâye sahnesi | Diyalog paneli oyuncunun dikkatini alır. Diyalog girişleri haritadaki eylemlere geçmez. Oyuncu satırları kendi hızında okur. | Açılış anlatımı, yetki devri, Bolo'yla tanışma |
| Olay tepkisi | Aktif danışman uygun oyun olayına kısa bir replik verir. Panel açıkken harita kullanılabilir. | İlk şehrin tamamlanması, bir işin bitmesi |
| Boşta konuşma | Belirli aralıklarla, arayüz ve konuşma sırası uygunsa aktif danışman kısa bir replik verir. | Koloni hayatı veya karakterin güncel bir gözlemi |
| Öğretici ipucu | Açılışta seçilen AI, kısa açıklama ve mümkünse doğrudan eylem sunar. İlk kez gerçekleşen önemli bir eylem alt panelde de karşılanabilir. | Capital District panelini aç |
| Dönüş özeti | Aktif danışman çevrimdışı sonuçları ve rastgele olayları özetler. Konumlu bir olay varsa harita bağlantısı sunulabilir. | Hazır kazı, keşfedilen bir bölge, hasarlı bir yerleşim |

**İlerleme önerisi.** Bir satır yazılırken ilk ilerleme girişi satırı tamamlar. Sonraki giriş bir sonraki satıra geçer. Yanıt seçenekleri varsa oyuncu açıkça birini seçer. Tuşa basılı kalmak veya paneli açan tıklamayı tekrar kullanmak seçim yapmaz. Seçim sonrasında yeni satırın konuşanı ve portresi birlikte güncellenir.

**Karar.** New Game'de öğretici zorunludur ve City, Capital District, district ve bina adımları normal oynanış içinde tamamlanır. İsteğe bağlı sahnelerde `Later` bağlantıyı hedef kartında veya açıldığı yerde bırakır. Tamamlanma ve ödül sahnenin tanımlı sonuna ulaşıldığında işlenir.

**İlk uygulama varsayımı.** Ana sahne ve seçim açıkken simülasyon duraklar. Kısa olay ve boşta replikleri sırasında dünya ilerler. Log kapanınca önceki sahnenin duraklama ve odak durumu geri gelir. [Diyalog sunumu](IMPLEMENTATION.md#diyalog-sunumu)

Boşta konuşmalar ve olay tepkileri ayrı bir diyalog CSV'sinden beslenir. Açılış ve karşılaşmalar yazılmış sahneler olarak ele alınır. Önerilen sırada sahneler gündelik repliklerin, güncel olay tepkileri boşta konuşmaların önüne geçer. Boşta konuşma için ilk aralık 90 saniyedir. Kısa repliğin ekranda kalma süresi arayüz ayarı olarak belirlenir. [Diyalog türleri ve veri taslağı](DIALOGUE.md)

## Ekran akışı taslağı

1. **Dünya ve ön anlatım.** `New Game` ile ana dünyanın gezegen görünümü hemen açılır. Harita görünürken anlatıcı birkaç kısa geçmiş bilgisi verir, ardından Mother Superior ve High Father sahnede konuşur.
2. **İlk danışman ve City.** Ön anlatım ve AI diyaloğu bittikten sonra oyuncuya iki AI arasından seçim sunulur. Önerilen sunum, Companions ile aynı portre, rol ve bonus kartlarını açılış panelinde göstermektir. Seçilen AI yetkiyi teslim eder. İlk hedef ve City yerleştirme modu bu devir tamamlanınca açılır. City tamamlandığında şehir paneli ve Capital District açıklaması gelir.
3. **Şehirde ilk adımlar.** Oyuncu hedef kartından gerekli ekrana geçer. Hikâyenin kısa parçaları, oyuncu yer seçimi ya da satın alma onayıyla meşgulken bekler. Seçilen AI, ilk kazı beklerken veya ertelendiğinde de öğreticiyi sürdürür ve tamamlar. [İlk oturum akışı](STORY.md)
4. **Kazı.** Konuma gitme ve kazıyı başlatma ayrı adımlardır. Kazı kartı fiyatı ve süreyi gösterir. Oyuncu hazır olduğunda kazıya başlayabilir ve ekip çalışırken şehre dönebilir. İş hazır olduğunda kazı hedefi sonuç sahnesine dönmeyi teklif eder. Sonuç sahnesi diyalog panelinde oynanır.
5. **Bolo'nun açılması.** Karşılaşma sahnesi bitince Bolo Companions listesine eklenir. Adayın profiline kısayol açılır. Oyuncu öğreticiyi tamamlayıp mevcut 5 yıllık görev süresi dolunca `Assign` ile Bolo'yu atayabilir. Kazıyı erteleyen oyuncuya etkin AI arada açık sahayı hatırlatır. [Danışman kuralları](ADVISORS.md)
6. **İlk Ay seferi.** Bolo'yla henüz tanışılmadıysa kullanılabilir `Prepare Lander` eylemi kamerayı ana dünyanın uzay limanına getirir ve kısa diyalogu açar. Oyuncu diyalogu tamamlayınca hazırlık devam eder ve Bolo'nun Companions kartı açılır. [Ay öncesi sahne](SCENES.md#bolo_before_moon)
7. **İlk gezegen seferi.** Advanced Planetary Rocket açıldığında ortak hedef kartında `Read expedition briefing` görünür. Oyuncu brifingi bulunduğu haritadan açabilir. [Sefer brifingi](SCENES.md#expedition_briefing)

## Kuyruk ve kayıt

Bu bölüm uygulama önerisidir. Diyalog içeriği için [diyalog belgesini](DIALOGUE.md), örnek olay kimlikleri ve tetikleyiciler için [hikâye akışını](STORY.md) kullan.

- Aynı anda tek diyalog paneli vardır. Açık sahne tamamlanırken gelen olaylar sıraya girer. Açılış, kadro açılışı ve bekleyen hikâye sahneleri günlük yorumlardan önce gösterilir.
- Yer seçimi, satın alma onayı, yükleme ve başka bir modal açıkken otomatik konuşma sunumu bekler. İşlem bittiğinde koşullar yeniden değerlendirilir. İlgili olayın kısa yorumu eskidiyse elenir, hikâye girişi erişilebilir kalır.
- Aktif danışman değişirse sıradaki günlük yorumun konuşanı gösterimden önce doğrulanır. Eski danışmanın rutin repliği kaldırılabilir. İlgili karakterin hikâye replikleri sahnenin yazılmış konuşanını korur.
- Ana hikâye sahnesi açıkken danışman ataması sahne kapanana kadar bekler. Açık sahnede konuşmacı, satır ve seçim durumu korunur.
- Tek seferlik sahnenin görüldü ve tamamlandı durumları ayrılır. Önerilen kayıt noktası, onaylanan seçim veya tamamlanan sahne adımıdır. Yeniden yüklemede açık sahne son güvenli adımdan devam eder ya da aynı girişten tekrar açılır. İki durumda da önceki tamamlanmış seçim, açılış ve ödül tekrar uygulanmaz.
- Hedef kartı kapalıysa yeniden açma yolu görünür kalır. Bekleyen bir ana sahnenin oynatılabilmesi, kısa yorumların görünürlük ayarından bağımsızdır.

## Narrative Log

**Karar.** Oyuncu geçmişte gördüğü konuşmaları yeniden okuyabilir. Kayıt oyun kaydıyla birlikte saklanır.

**Öneri.** Diyalog panelinde `Log` düğmesi bulunur. Panel kapalıyken aynı geçmiş HUD'dan açılabilir. Girişler kronolojik sırada konuşan adı ve gösterilmiş metinle listelenir. Hikâye konuşması, verilmiş yanıt, gündelik replik ve dönüş özeti sahne veya olay başlığı altında gruplanabilir. Log kapatıldığında açık sahne aynı satırdan devam eder. Geçmişi okumak bir seçim veya ödül işlemi başlatmaz.

## Companions ve danışman seçimi

- Mevcut HUD Companions düğmesi ortak kadro ekranını açar. Seçili karakter listede `Active Advisor` olarak işaretlenir. Açılıştaki iki AI seçimi bu ekranın profil kartlarını kullanabilir.
- Mother Superior ve High Father'ın ayrı profilleri ve bonusları vardır. Bolo ile Burkai kendi kazı kapanışlarında açılır. Henüz bilinmeyen veya sonraki medeniyetlerde gelecek yoldaşlar için ortak silüet ve **???** gösterilebilir. Gelecek içerik silüeti profil ve atama açmaz. [Mevcut silüet](../../../resources/companions/portraits/silhouette.svg)
- Ayrıntı alanında portre, ad, rol, bonus açıklaması ve seçilebilirlik durumu yer alır. Öğretici veya bekleme kilidi sürerken açılmış adaylar incelenebilir. Atama düğmesi kilitliyse nedeni, süreye bağlı bir kilitse kalan süre yazıyla görünür.
- Her açık danışmanın profilinde yarım adımlarla dolan en fazla beş kalp, birikmiş görev yılı, güncel bonus ve sıradaki yarım kalbe kalan süre görünür. Tam kalp eşiğinde gösterilen bonus artar. Açılmış kişisel sohbetler için `New Conversation` eylemi gösterilir. [Kalp kademeleri](ADVISORS.md#arkadaşlık-ve-kalpler)
- Atama onaylandığında günlük panel ve HUD yeni konuşanı, profil ekranı etkin bonusu ve bir sonraki değişimin durumunu gösterir. Sürenin hesabı ve mevcut kayıtların davranışı için [danışman kuralları](ADVISORS.md) esas alınır.

## Koloni takvimi

Yetki devrinden sonra HUD'da `Year 2465` görünür. Ayrıntı görünümü koloni ayını da verir. Her 20 ekonomi saniyesi bir ay, her 12 ay bir yıl ilerletir. Dönüş raporu aynı takvimden hesaplanan süreyi kullanır. [Sayaç ve kayıt](IMPLEMENTATION.md#koloni-takvimi)

## Çevrimdışı dönüş ekranı

**Karar.** Kalıcı kayıtlarda çevrimdışı ilerleme her zaman açıktır. Oyun en fazla **24 gerçek saati** sayar. Takvim ve işler bu aralığın **%10'u** kadar ilerler. Dönüşte ekran gerçek yokluk süresini ve koloni takviminde geçen zamanı ayrı gösterir. Üst sınır, 2 saat 24 dakika normal oyun ilerlemesi ve 36 oyun yılıdır. [Çevrimdışı kurallar](ADVISORS.md)

**Karar.** Dönüşte etkin danışman, koruyucu uykudan çıkan oyuncuyu karşılar ve kaydedilen sonuçları anlatır. Bir büyük olay ve birkaç küçük olay görülebilir. Rapor harita konumu bulunan sonuçlara bağlantı verir. [Olay havuzu ve etkiler](OFFLINE_EVENTS.md)

**Öneri.** Dönüşte danışman diyalog panelinde en önemli birkaç olayı söyler. Ayrıntı görünümünde oyundan ne kadar uzak kalındığı ve bunun ne kadarının simüle edildiği gösterilir. Konumu olan bir olayda `Go to Location` düğmesi ilgili yeri açar. Özet Narrative Log'da saklanır. Oyuncu raporu açıkken çıkarsa aynı rapora döner. Arada yeni bir yokluk işlendiyse onun raporu sırada bekler. [Rapor kaydı](IMPLEMENTATION.md#çevrimdışı-simülasyon-sınırı)

## Godot kaynaklarında bugünkü durum

| Kaynak | Mevcut davranış | Tasarımda kullanılabilecek kısım |
| --- | --- | --- |
| [MainMenu.gd](../../../scripts/system/MainMenu.gd) ve [IntroCard.tscn](../../../scenes/ui/IntroCard.tscn) | Yeni oyunda genel hedef kartı açılır. `Begin` yeni kaydı başlatır ve GalaxyView'a geçer. | Yeni akış, girişte doğrudan ana dünyayı gösterir ve ön anlatımı harita üzerinde açar. |
| [PlanetaryView.gd](../../../scripts/planetary/PlanetaryView.gd) | Ana dünyada henüz City yoksa geçerli ilk City yerleşimi başlar. | İlk yerleşimi, ön anlatım, danışman seçimi ve yetki devri tamamlandıktan sonra aç. |
| [StoryDialog.gd](../../../scripts/ui/excavation/StoryDialog.gd) ve [StoryDialog.tscn](../../../scenes/ui/excavation/StoryDialog.tscn) | Merkezde kazı kartı açılır. VSM konuşanı, repliği ve seçenekleri besler. Açılış, ödeme, bekleme ve dönüş ayrı durumlardır. | Portre, yazı, seçim ve geçiş davranışlarını örnek al. Şu anki giriş `site_id` bekler. Genel alt panel için ortak sunum yüzeyi gerekir. |
| [ObjectivesCard.gd](../../../scripts/ui/components/ObjectivesCard.gd) ve [NewsFeed.gd](../../../scripts/system/NewsFeed.gd) | Sağ altta hedef veya mesaj gösterir. Bazı mesajlarda eylem düğmesi ve konum bağlantısı bulunur. | Göreve dönme ve ilgili yeri açma yüzeyi. Alt panel ile ekran alanını paylaşma kuralı eklenir. |
| [CompanionGallery.gd](../../../scripts/ui/excavation/CompanionGallery.gd) ve [CompanionGallery.tscn](../../../scenes/ui/excavation/CompanionGallery.tscn) | HUD'dan açılan Companions listesi karşılaşılmış karakterin portresini, biyografisini ve bonusunu gösterir. | İki AI'ı aynı kadroya ekle. Aktif atama ve bekleme durumunu mevcut profil düzenine bağla. |
| [HUDManager.gd](../../../scripts/system/HUDManager.gd) | Oyun kapalıyken geçen süreyi `WELCOME BACK` kartında gösterir. Bu kart gerçek çevrimdışı sonuç özetini içermiyor. | Dönüş sunumunun mevcut giriş noktası. Danışman özeti için gerçek olay kayıtları gerekir. |
| [TutorialManager.gd](../../../scripts/system/TutorialManager.gd) | Eski yönlendirmeleri ve ayrı bir anlatım panelini barındırır. Rehberli akış varsayılan olarak kapalıdır. | Mevcut tetikleyicileri ve hedef entegrasyonunu incele. Yeni öğretici için görünüm ve içerik akışını bu belgedeki yüzeylere dağıt. |

## Açık kararlar

Tasarım görüşmesinde aşağıdaki kararlar [tasarım sırasına](ROADMAP.md) göre ele alınır.

1. Narrative Log'un HUD düğmesinin kesin yeri ve gündelik yorumun ekranda kalma süresi. İlk metinler ve 90 saniyelik başlangıç konuşma aralığı [Diyaloglar](DIALOGUE.md#gündelik-konuşma-csvsi) içinde.
2. Portrelerin gerçek HUD boyutlarındaki kadrajı.
3. Çevrimdışı olay sıklığı ve onarım süresi ilk denge varsayımlarından ayarlanır. [Olay ayarları](OFFLINE_EVENTS.md)

## AI portrelerinin üretim istemi

Yerleşik imagegen kullanıldı. İki özgün Bolo ve Burkai portresi her iki istemde de üslup referansı olarak verildi. Aşağıdaki ortak parça, her karakterin kendi tasviriyle birleştirildi.

```text
Use case: illustration-story. One transparent-background visual novel character sprite for Voidle. Both supplied images are style references only, existing Ece and Burkai portrait sprites. Match their sharp low-resolution pixel-art character rendering, deliberately grouped pixels, sharp sparse ink outline, limited contrast ramps, selective dithering, grounded adult proportions, similar head-to-upper-thigh framing and visible silhouette. Depict the character directly facing the camera, head square and both eyes fully closed and readable. Tall narrow sprite, clean cutout, empty transparent space around hands and head, no floor, shadow, scenery, lettering, decorative frame or extra person. One upper-left light source. Use a restrained palette and keep transparent edges clean. This is a newly designed synthetic person, not a copy of either reference character.

Mother Superior is a visibly synthetic adult woman caretaker with a calm, steady stance and two hands naturally folded low. A matte ivory ceramic face with closed articulated eyelids, two small copper seams near the temples and a restrained off-white, worn caretaker coat over a desaturated forest-green inner garment. Soft amber accent on the collar. Long garment silhouette; no religious iconography.

High Father is a visibly synthetic adult man caretaker with a squared build and an even, upright stance, hands calmly down. An angular dark steel and ceramic face with fully closed mechanical eyelids, a narrow jaw seam, practical graphite and faded navy utility coat with one muted copper clasp. A cold blue-gray value ramp distinguishes him from the warmer Mother Superior, both characters from the same game.
```

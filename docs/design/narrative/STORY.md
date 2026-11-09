# Voidle anlatısı ve ilk oturum

Başlangıç noktası [Ana belge](README.md). Oyuncunun okuyacağı İngilizce metin [Sahneler](SCENES.md), karakterlerin sesi [Diyaloglar](DIALOGUE.md) ve oyun bağlantıları [Uygulama](IMPLEMENTATION.md) içinde.

**Karar** kullanıcı tarafından kabul edilmiş tasarımı, **Yazım** uygulanabilir sahne ve lore tercihlerini, **Kaynak taslağı** özgün dosyalardaki malzemeyi, **Öneri** gözden geçirilecek çözümü ve **Mevcut** güncel kaynak kodunu gösterir. Bir kaynak taslağıyla daha yeni karar ayrışırsa yeni karar esas alınır.

## Açılışın öncesi

### Dünya ve Lazarus

**Karar.** Dünya'da nükleer savaş **2200 yılında** başlar.

**Kaynak taslağı.** Dünya'nın eski toplumları çöker ve büyük güçlerden bazıları nükleer savaşı başlatır. Önceden hazırlanan Lazarus Projesi, insan soyunu yeni bir dünyada sürdürebilmek için sekiz tohum gemisi yollar. Gemiler koruma altına alınmış embriyoları, onları yetiştirecek altyapıyı ve gemiyi işletecek sentetik zihinleri taşır. Rotanın hedefi LHS 1140 b'dir.

Altı gemi yol üzerinde aynı motor arızasını yaşar. Yedinci gemi Aniara, adı konmamış bir kozmik varlıkla karşılaşır. Açılış metni Aniara'yla bağlantılı bilinçlerin bu varlıkla hâlâ tartıştığını söyler. Bu bilinçlerin kim olduğu ve nasıl iletişim kurdukları belirsizdir. Sekizinci gemi I-330, asteroit yağmurunda rotasından sapıp bir solucan deliğinden geçer. Vardığı gezegen planlanan hedefe benzer, fakat pulsarlar ve takımyıldızlar geminin kataloğuyla uyuşmaz. Geminin nerede olduğu ve yakınında başka yaşam bulunup bulunmadığı yolculuğun sonunda belirsizdir. [Özgün açılış metni](sources/voidle-exposition.txt)

### I-330, iki AI ve oyuncu

**Kaynak taslağı.** Mother Superior ve High Father gemiyi yöneten iki sentetik zihindir. İkisi İlk Kural Kitabı'nı imzalar. Kitabın ilk maddesi, koloninin kalıcı yerleşim kurabilecek yetişkin nüfusa ulaşacağı eşiği tanımlar.

**Karar.** I-330'un inişinden sonra geçen **25 yılda** gemideki embriyolardan koloninin ilk kuşağı yetişir. Açılışta oyuncu dahil ilk kuşağın tamamı **25 yaşındadır**. İlk Kural Kitabı'ndaki eşik, tamamlanmış ilk City'nin varsayılan nüfus kapasitesine karşılık gelen **17.490 kişidir**. Koloni bu eşiğe ulaştığında kalıcı şehrini kurmaya hazırdır.

**Mevcut.** 15.000, City'nin kodda tanımlı taban kapasitesidir. İlk City'nin otomatik Capital District'i 600 kapasite verir. İlk şehrin tek başına olduğu konumda bu katkı 900'e çıkar. Ana dünyanın Cradle World özelliği toplamı %10 artırır. Böylece ilk City tamamlandığında hesap `(15.000 + 900) × 1,10 = 17.490` olur. [City tabanı](../../../scripts/game/balance/BalanceConfig.gd#L69) · [Capital District](../../../resources/districts/city_district.tres#L16) · [Konum çarpanı](../../../scripts/game/Location.gd#L139) · [Cradle World](../../../resources/traits/cradle_world.tres#L11) · [Kapasite hesabı](../../../scripts/game/Economy.gd#L454)

**Karar.** Oyun, koloninin liderlik için genetik olarak hazırlanmış oyuncuyu ilk Facilitator seçtiği gün başlar. Oyuncu ana dünyayı hemen görür. Kısa bir anlatım ve iki AI'ın konuşması, koloninin buraya nasıl geldiğini ve neden şimdi bir şehir kuracağını anlatır. Oyuncu ardından **Mother Superior veya High Father** arasından ilk danışmanını seçer. Seçilen AI yetkiyi teslim eder, emirlerini uygulayacağını bildirir ve görev listesini açar. Haritadaki ilk eylem, şehrin yerini seçmektir.

**Yazım.** I-330'un gemi takviminde iniş **2440**, ilk Facilitator'ın göreve gelişi **2465**. Solucan deliğinden sonraki yıllar I-330'un kendi kayıtlarına göre tutulur. Oyuncunun liderlik için seçilmiş özellikleri olduğunu AI'lar bilir. Hazırlığın yöntemi daha sonra anlatılabilir.

**Yazım.** Oyuncu gemiden yetkiyi aldıktan sonra uzun aralarda I-330'un koruyucu uyku kabinine döner. İlk kuşağın yetiştirilmesinde kullanılan koruma altyapısı, Facilitator'ın uzun takvim aralıklarından sonra görevine devam etmesini sağlar. Yokluğunda seçtiği danışman bıraktığı iş emirlerini sürdürür ve dönüşte geçen süreyi anlatır. [Dönüş sahnesi](SCENES.md#dönüş-ve-gemi-uykusu)

## İlk oturumun omurgası

Kimlikler sahneler hakkında konuşmak için kullanılan tasarım örnekleridir. Tetikleyiciler, kısa öğretici ile ana hikâyenin birbirinden ayrılabilmesini sağlar. Tetikleyicinin uygulama biçimi [Diyaloglar](DIALOGUE.md) ve [Arayüz](UI.md) üzerinden detaylandırılır.

| Adım | Oyuncu eylemi | Hikâye ve açılan bilgi | Durum |
| --- | --- | --- | --- |
| `opening_intro` | Ana dünyayı görür ve kısa açılış konuşmasını ilerletir. | Koloninin neden şimdi şehre hazır olduğu ve geminin yıldız haritasının uyuşmadığı anlatılır. Mother Superior ve High Father konuşur. | **Karar** dünya hemen görünür ve konuşma seçimden önce gelir. **Yazım** ilk ipucu yıldız haritası. |
| `opening_handover` | Açılış konuşmasından sonra iki AI'dan birini seçer. | Seçilen AI koloni adına yetkiyi teslim eder. Oyuncu görev listesini ve ilk şehir hedefini görür. | **Karar** oyuncu ilk danışmanını seçer. |
| `first_city_founded` | Yeri seçer, şehrin tamamlanmasını görür ve şehir panelini açar. | City içindeki Capital District görünür. Oyuncu isterse ilk gemi kaydını açıp Lazarus hakkında bilgi alır. | **Karar** ilk şehir. **Yazım** gemi kaydı öğreticiden bağımsız okunur. |
| Öğretici | Capital District'i inceler ve kendi seçtiği bir district ve binayı tamamlar. | Seçilen AI, sıradaki arayüz eylemini ve bina kartında hangi bilgilerin bulunduğunu gösterir. | **Karar** öğreticinin tamamını aktif AI yürütür. **Yazım** adımlar [Sahneler](SCENES.md#ai-ile-tamamlanan-öğretici) içinde. |
| `first_ruin_signal` | Hazır olduğunda haritadaki işarete gider ve ilk kazıyı başlatır. | AI, araştırma ekibinin devrilmiş taşların altında bulduğu basamakları gösterir. | **Karar** ilk kazının zamanı oyuncuya bağlıdır. **Yazım** ilk kazı ipucu araştırma raporundan gelir. |
| `first_excavation_ready` | Kazının hazır bildirimini alır ve alana döner. | Ekip sonucu oyuncuya bırakır. Burada asıl sonuç sahnesi açılır. | **Mevcut** hazır bildiriminden sonra sonuç için dönüş. **Öneri** yeni yönlendirme kartı ve zamanlama. |
| `meet_bolo` | Bolo'yla tanışmadan ilk kazının sonuç görüşmesini tamamlar. | Ekip gezegene yerli birini bulmuştur. Oyuncu Bolo'yla tanışır ve onu danışman listesinde görür. | **Karar** ilk kazıda tanışma ve kadroya katılma. |
| `bolo_before_moon` | Bolo'yla henüz tanışmadan ilk Ay aracını hazırlamayı seçer. | Bolo sinyal ve ölçüm kayıtlarıyla uzay limanına gelir. Sefere katılır ve Companions'ta açılır. | **Karar** ilk kazıyı erteleyen oyuncu Ay'a Bolo'yla gider. |

New Game'de öğretici zorunludur. Oyuncu onu kazıya gitmeden tamamlayabilir. Bolo'yla erken tanışırsa onu kadroda görür. Bolo'ya aktif danışman olarak geçiş, öğretici ve mevcut danışmanın 5 yıllık görev süresi tamamlandığında mümkün olur.

### İlk kazının sonucu

**Karar.** Bolo'nun asıl tanışma sahnesi ilk ana dünya kazısının sonundadır. Kazıyı yapmadan Ay aracını hazırlayan oyuncuyla Bolo uzay limanında kısa bir görüşme yapar ve sefere katılır. İki sahne aynı Companions kartını açar. Oyuncu uzay limanı yolundan sonra ilk kazıya dönerse bronz aletlerle ilgili kararı ve ödülleri alır, Bolo tanıdık olarak konuşur. İlk kadro Mother Superior, High Father, Bolo ve Burkai'den oluşur. [İki tanışma sahnesi](SCENES.md#the-toppled-stones-ve-bolo)

**Yazım.** Bolo gezegene yerli bir dilbilimci ve saha araştırmacısıdır. İki tanışma yolunda da yeraltında büyüdüğünü, halkının Büyük Sel'den sonra orada yaşamayı sürdürdüğünü ve gemi indiğinde yüzeye çıktığını anlatır. Bolo, geminin indiği gece diktiği incir ağacının adıdır. Kazı yolunda ağacın koloninin çalışmaları sırasında kesildiğini de söyler. Yeraltı halkının varlığı burada bilinir. İlk gerilim, koloninin genişleme niyetiyle Bolo'nun toprağa ve geçmişe bakışı arasındadır. [Ece sahneleri](sources/ece-scenes.txt) · [Tanışma metinleri](SCENES.md#the-toppled-stones-ve-bolo)

Bolo yıllardır kalıntılardaki yazı ve ses kayıtları üzerinde çalışır. Koloninin aygıtları sinyallerin onda uyandırdığı uğultudan fazlasını yakalayabilir. Bolo bulgularını paylaşmak için I-330'un işlenmemiş alıcı verisine erişim ister. AI'ların güvenlik gerekçesiyle kullandığı filtreler bu görüşmede tartışma konusu olur. Böylece Bolo'nun teklifinin kendi amacı ve karşılığı vardır.

**Yazım.** Ekip önce bulguyu bildirir. İlk kazının iki sonucu, oyuncu Bolo'yla henüz tanışmadıysa kazı odasındaki karşılaşmaya varır. Oyuncunun cevapları görüşmenin tonunu değiştirir. Bolo'yu aktif danışman yapmak ayrı bir arayüz eylemidir. Mevcut AI ile devam eden oyuncu da Bolo'nun hikâyesini görür.

### Kazıdan sonraki kaynak sahneleri

**Kaynak taslağı.** Bir saha çalışmasında disk açılınca ışık ve iletişim gider. Bir laboratuvar sahnesinde disk, ışıklar kapandığında yazı gösterir. Bu malzeme kazı ipuçları için kullanılabilir. **Karar.** Tip 0'daki arkadaşlık konuşmaları, oyuncu her danışmanla zaman geçirdikçe açılır. [Kalp sistemi](ADVISORS.md#arkadaşlık-ve-kalpler)

### Bolo'nun halkı ve yüzeye çıkma teklifi

**Karar.** Bolo'nun geçmişinde Ece sahneleri esas alınır. Üç şirketin kurduğu Federasyon, Büyük Sel öncesi 150 ölümsüzü ve insan tohumlarını terraform edilmiş Titan'a yollar. Yüzeyde kalanlar miselyumu yönlendirerek yeraltında bir toplum kurar. Bolo orada doğmuştur ve halkı hâlâ yaşamaktadır. Topluluğun yerini paylaşma kararı Bolo'ya ve halkına aittir. Voice Bible, Bolo'nun sesine ve kelime seçimine referans verir. [Ece sahneleri](sources/ece-scenes.txt) · [Bolo Voice Bible](sources/bolo-voice-bible-v1.md)

**Karar.** Ana dünyadaki beş kazı sonuçlanınca Bolo, yeraltı topluluğunun tamamı adına yüzeye katılma teklifini getirir. **Yazım.** Kazı raporları yüzeye çıkan eski bir yolun kullanılabilir olduğunu gösterir. Halkı raporları inceledikten sonra topluca taşınmaya karar verir. Kabulde Bolo, yüzeyde ekiplerin arabaları nerede karşılayacağını anlatır. Ana dünyanın Population kapasitesine bir kez **+17.490** eklenir. Bu değer varsayılan ilk City tamamlandığında sağlanan kapasiteye eşittir. Ertelenen teklif daha sonra yeniden açılabilir. Tetikleyici, beş kazının sonuçlarının kaydedilmesi ve Bolo'yla tanışılmış olmasıdır. [Ana dünya kazı dizisi](../../../resources/excavations/vesyn.tres#L13) · [Mevcut nüfus hesabı](../../../scripts/game/Economy.gd#L431) · [Davet sahnesi](SCENES.md#bolo_surface_invitation)

## Ay, Burkai ve daha ileri eşikler

**Karar.** Bolo'nun aldığı Ay sinyali, oyuncuya Ay'a gitmek için bir neden verir ve onu oradaki bir kazı alanına yönlendirir. Oyuncu bu kazının sonucunda Burkai'yle tanışır. Burkai, sonuç sahnesi tamamlandığında danışman kadrosuna eklenir.

**Kaynak taslağı.** Bolo sinyali bir uğultu olarak duyduğunu söyler. Ay sahnesinde oyuncu ve Bolo kraterlerde Burkai'yle karşılaşır. Burkai Bolo'ya Ece diye seslenir. Ece'nin Bolo'nun kişisel adı olduğunu sahne burada açar ve Burkai'nin onu nasıl tanıdığına dair merak yaratır. Diskteki yazıyı tanıması, zaman ve kozmik döngü üzerine söyledikleri, Mycelium ve kask sahnesi ayrı ayrı değerlendirilebilecek taslak unsurlardır. [Burkai sahnesi](sources/burkai-scenes.txt)

**Karar.** Oyuncuya koloni kurmanın ötesinde genel bir motivasyon ve ilk oturumlardan itibaren takip edebileceği büyük hikâye ipuçları verilecek.

**Yazım.** Sinyal Ay'daki mevcut ilk kazı olan **The Rim Echo**'yu işaret eder. Bolo, ana dünyadaki kayıtla Ay sinyalinde aynı aralığı fark eder. Burkai karşılaşması Ay'da benzer işaretler taşıyan bir alıcıyı ortaya çıkarır. Bu, oyuncuya iki yerin geçmişte birbirine bağlı olduğuna dair ilk kanıtı verir. Sinyali kimin kurduğu ve Burkai'nin Ece adını nereden bildiği sonraki sahnelere kalır.

### Bolo ve Facilitator neden yaşlanmıyor?

**Karar.** Bolo, iki tanışma yolunda da yıllar arayla tuttuğu ölçümlerde kendi bedeninde beklediği değişimi görmediğini söyler. Facilitator da yaşlanmaz. Oyuncu ikisinin de ölümsüz olduğunu Ay'da Burkai'yle birlikte öğrenir. İlk kuşağın genetik hazırlığı ve gemideki koruyucu uyku, açılış ve dönüş sahnelerindeki rollerini sürdürür.

**Yazım.** Ana dünyadaki oda ile The Rim Echo arasında çalışan eski bir doku onarım ağı vardır. Bir bedenin yetişkin doku örüntüsü kayda girince ağ o örüntüyü korur ve dokular yaşlandıkça kaydedilen duruma geri döner. Bolo'nun kaydı, odada çalıştığı yıllarda yaptığı kendi doku ölçümünden gelir. Facilitator'ın kişisel görev öncesi muayenesinde ise I-330'un tarayıcısı odadan gelen bir yanıtı yakalamış ve örüntüyü ağa aktarmıştır. Her iki tanışma yolunda da Bolo geminin ham sinyal kayıtlarına erişir ve Ay'a kendi ölçümlerini getirir.

Ay'da Burkai, alıcıda tekrarlanan iki kaydı nasıl okuyacaklarını gösterir. Bolo kendi ölçümünü, Facilitator gemideki muayene kaydını tanır. Ağın bu iki kişide yaşlanmayı durdurduğu burada kesinleşir. Ağın kökeni, neden hâlâ çalıştığı, Burkai'nin onu nasıl tanıdığı ve Titan'a gönderilen 150 ölümsüzle olası bağı sonraki hikâyelere kalır. Tip 0 keşfin biyolojik yaşlanmaya etkisini doğrular. [İlk ölçüm ve Ay görüşmesi](SCENES.md)

### İlk gezegen seferinin amacı

**Yazım.** Koloni, Dünya'da tek bir yuvaya bağlı kalmanın neye mal olduğunu biliyor. İlk başka gezegene ulaşmak, insanlara ikinci bir yerleşim ihtimali ve I-330'un bulduğu tuhaf kayıtları başka bir dünyadan karşılaştırma olanağı verir. Oyuncu bunu ortak Final Rocket hedefinden açılan sefer brifinginde duyabilir. Roket seçilen gezegene ulaştığında alıcı, Ay'dakiyle aynı aralıkta tekrar eden bir darbe kaydeder. Birden fazla dünyada aynı desenin görülmesi daha büyük bir soru açar. Bu kayıtlar birbirine yanıt vermek için mi kuruldu, ve neden artık bu kadar uzun süre boşlukta kalıyorlar?

**Yazım.** Ölümsüzlük keşfinden sonra Facilitator, bir insan ömrünü aşan seferlerin sorumluluğunu üstlenebilir. Hedef başka gezegenlerde kalıcı üsler kurmak, mürettebat için dönüş yolları açmak ve alıcı ağını izlemektir. Bu görev Ay'daki görüşmenin ardından açılır. Roket çoktan ulaştıysa mevcut varış verisi yüzeyi olan gezegende iniş yeri, gaz devinde güvenli yörünge aramak için kullanılır. Üs kurmak Tip 0 sonrasının hedefidir. [Sefer sahneleri](SCENES.md#mission_after_reveal)

**Karar.** Kazılar ve Burkai görüşmesi roketi kilitlemez. Kazıları atlayan oyuncu Ay'a uzay limanında tanıştığı Bolo'yla gider ve dilerse aynı AI'ı etkin danışman olarak kullanır. Etkin AI erişilebilir kazıları arada hatırlatır. Ham sefer kaydı saklanır ve oyuncu Ay kaydını daha sonra bulursa karşılaştırma yapılabilir.

**Karar.** Tip 0 teslimi ilk gezegen varışında tamamlanır. **Yazım.** Varış kaydında yeni bir ses sinyale cevap verir ve oyuncuya karşısında henüz tanışmadığı birilerinin olabileceğini gösterir. Sonraki medeniyetlere, hikâyelere ve yoldaşlara geçiş için bu kayıt ve Companions'taki adsız silüet kartları kullanılır. [Sefer sahneleri](SCENES.md)

**Mevcut.** Oyun ilk şehirden ekonomiye, yörünge altyapısına, Ay'a, Moonstone üretimine ve başka bir gezegene gönderilen rokete ilerler. Roketin varışı Tip 0'ı tamamlar. Bu mekanik eşikler hikâye sahnesi için yer sağlar. İlk dünyanın ötesine yayılmanın anlamı, büyük hikâyenin amacı ve tehdidi tasarımda açık. [Roket varışı](../../../scripts/game/GameState.gd#L994)

### Medeniyet geçişlerini doldurma biçimi

Her geçişi tasarlarken aşağıdaki alanlar doldurulur. İlk oturum ve Ay sahneleri, eldeki bilgiyle ayrıca tasarlanabilir.

| Alan | İçerik |
| --- | --- |
| Oynanış eşiği | Yeni ölçeği açan gerçek oyun olayı ve oyuncunun o olaya ulaşmak için yaptığı iş. |
| Anlatı nedeni | Koloninin o anda neden daha uzağa gitmek istediği ve bulunduğu ölçekte neyi çözemediği. |
| Tehdit veya bedel | Gecikmenin ya da büyümenin kimi, neyi ve nasıl etkilediği. |
| Yeni bilgi | Bu geçişte oyuncunun öğrendiği doğrulanabilir şey ve önceki ipuçlarına etkisi. |
| Oyuncu kararı | Oyuncunun etkileyebildiği sonuç ve bunun sonraki sahnelerde nasıl görüldüğü. |

## Birbiriyle ayrışan kaynaklar

| Konu | Kaynakların anlattıkları | Yeni tasarımdaki durum |
| --- | --- | --- |
| Bolo'nun ilk görünüşü | Bolo Voice Bible örnekleri onu ilk şehirden itibaren öğretici sesi olarak kullanıyor. `Ece.txt` kazı ekibinin onu bulmasıyla açılıyor. | **Karar.** İlk kazı kapanışında veya ilk Ay aracının hazırlığından önceki kısa görüşmede kadroya katılır. Öğreticiyi aktif AI yürütür. |
| Bolo'nun halkı ve Büyük Sel | Olayların kaynağı Ece sahneleridir. Voice Bible, ses ve kelime seçimi için kullanılır. | **Karar.** Bolo'nun halkı yeraltında yaşamaktadır. Federasyon, Büyük Sel öncesinde Titan'a 150 ölümsüz yollar. [Ece sahneleri](sources/ece-scenes.txt) |
| Kalıntıların kökeni | Voice Bible, bulguların yerel ya da uzaydan gelmiş olmasını açık tutar. `Ece.txt` laboratuvar sahnesinde Bolo yazının uzaylılara ait olduğunu söyler. | **Açık.** İlk sinyalin duyulması için kökenin bilinmesi gerekmez. |
| Burkai'nin bilgisi | Ses rehberi Burkai'ye iki anı ve sakin, ketum bir ses verir. Ay sahnesi onu Ece'yi tanıyan, diski çeviren ve kozmik açıklamalar yapan biri olarak yazar. | **Yazım.** Ece adını tanır ve alıcıyı okumaya yardım eder. Kısa, şimdiki zamandaki gözlemleri ses rehberini izler. Ece'yi nereden tanıdığı açık kalır. |
| Burkai ve kozmik varlık | Ses rehberi Burkai'nin Aniara'nın bir parçası veya benzer bir karşılaşma yaşamış ayrı bir varlık olabileceğini belirtir. | **Açık.** Bağlantının kendisi ve açıklanacağı eşik ileride seçilir. |

## Mevcut oyundan geçiş

Bugünkü `IntroCard` yörünge, Ay ve roket hedefini özetler. `Year 2387` repliği, varsayılan olarak devre dışı eski öğreticide durur. Yeni anlatı görevin teslim alındığı gün başlar. İlk şehrin konumunu seçme akışı zaten var. [Yeni oyun kartı](../../../scenes/ui/IntroCard.tscn#L54) · [Eski öğretici](../../../scripts/system/TutorialManager.gd#L349) · [İlk şehir yerleşimi](../../../scripts/planetary/PlanetaryView.gd#L2577)

Bugünkü ilk kazı `The Toppled Stones`, bronz aletler bulunan bir odayla sonuçlanır. Mevcut üçüncü ana dünya ve Ay kazılarında Sera Vale ve Dorian Hale vardır. Yeni kadro kararı ilk kazının içeriğine ve eski yoldaşların kullanıldığı sahnelere uyarlama gerektirir. Kazının hazır olması ve oyuncunun sonuç sahnesini bitirmesi kodda iki ayrı aşamadır. Bolo'nun açıldığı nokta olarak sonuç sahnesinin kapanışı kullanılabilir. [İlk kazı sahnesi](../../../resources/stories/vesyn_1_toppled_stones.tres#L86) · [Eski ana dünya yoldaşı](../../../resources/stories/vesyn_3_compass_bearer.tres#L84) · [Eski Ay yoldaşı](../../../resources/stories/moon_3_sealed_hatch.tres#L77) · [Kazı bitişi](../../../scripts/game/excavation/Excavations.gd#L222)

**Mevcut.** İlk kazının bedeli 300 Credits ve 50 Science, süresi 300 oynanmış saniye. Varsayılan profil 50 Science ile başlıyor. **Karar.** Oyuncu başlangıç Science'ını araştırmaya harcayıp kazıyı daha sonraya bırakabilir. Bu sırada seçtiği AI ile öğreticiyi tamamlar ve oyuna devam eder. [Kazı verisi](../../../resources/excavations/sites/vesyn_toppled_stones.tres#L12) · [Kazı süresi](../../../scripts/game/excavation/ExcavationSiteDef.gd#L26) · [Başlangıç profili](../../../resources/balance/profile_current.tres#L8)

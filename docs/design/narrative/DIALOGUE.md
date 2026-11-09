# Voidle diyalog tasarımı

İngilizce sahne metinleri [Sahneler](SCENES.md), panel davranışı [Arayüz](UI.md), aktif konuşmacının belirlenmesi [Danışmanlar](ADVISORS.md) ve olay bağlantıları [Uygulama](IMPLEMENTATION.md) içinde.

**Karar.** İki AI, Bolo ve Burkai kendi sesleri olan karakterlerdir. Aktif danışman günlük konuşmaları ve seçimine bağlı bonusu üstlenir. Oyuncu dünyayı gördükten ve kısa açılış konuşmasını dinledikten sonra Mother Superior veya High Father'ı seçer. Seçilen AI öğreticinin tamamında ve oyuncu yeni danışman atayana kadar günlük rehberliği sürdürür.

**Öneri.** Karakterlerin görev devri, kazı veya karşılaşma gibi yazılmış sahnelerde konuşması günlük danışman kanalından ayrı ele alınır.

Bu dosya karakter seslerini ve gündelik replik verisini taşır. İngilizce sahneler ayrı dosyada, tetikleyiciler uygulama rehberinde tutulur.

## Konuşma türleri

| Tür | Tetikleyici ve koşul | Konuşmacı | Beklenen sonuç |
| --- | --- | --- | --- |
| Hikâye sahnesi | Anlatı eşiği açılır. Görev devri ve ilk kazının sonuç görüşmesi bu türdedir. | Sahnede bulunan kişiler. Yazılmış sahne gerekirse iki AI'ı veya Bolo'yu birlikte kullanır. | Oyuncu tamamlayınca ilgili sahne tamamlandı sayılır. Bir kilit açılıyorsa sahnenin bitişiyle işlenir. |
| Öğretici ipucu | Oyuncu bir ekranı ilk kez kullanır veya bir hedefe ilerlemek için açıklamaya ihtiyaç duyar. | Açılışta oyuncunun seçtiği AI. | Panelde tek eylem görünür. Eylem gerçekleşince hedef ilerler. New Game'de öğretici tamamlanır. |
| Boşta konuşma | Belirlenen konuşma aralığı dolduğunda ve diyalog kanalı müsait olduğunda. | Aktif danışman. | Karaktere ve bağlama uygun kısa bir gözlem. |
| Kısa tepki | İnşaatın tamamlanması, ilk üretim ya da önemli bir kapasite değişimi. | Aktif danışman. | Olaya ve karaktere özgü tek kısa replik. İlk kez gerçekleşen bir olay, kayıtta görüldü olarak tutulabilir. Tekrar eden olaylar önem derecesine göre seçilebilir. |
| Geçmiş parçası | Oyuncunun bulunduğu adımla bağlantılı bir bilgi açılır. Şehir kurulunca gemide geçen yıllar gibi. | O bilgiyi bilebilen AI veya karakter. Günlük kanaldaysa aktif danışman koşulu uygulanır. | Bir bilgi açığa çıkar ve uygun bir sonraki sahne için referans olur. Açıklama, gereken oyun eylemini kesmeden yerleşir. |
| Dönüş özeti | Kayıt yüklenir ve yokluk sırasında oluşmuş doğrulanmış sonuçlar bulunur. | Yüklemede aktif olan danışman. | Önemli birkaç sonuç ve varsa onları inceleme düğmeleri. Oyun verisi neyin gerçekten gerçekleştiğini belirler. |
| Kalp konuşması | Danışman 50 yıllık bir yarım kalp eşiğini geçti. Oyuncu öğreticiyi tamamladı ve Companions'tan konuşmayı açtı. | İlgili danışman. | Kişisel geçmiş veya güvene dair bir gözlem. Her konuşma tek başına anlaşılır. Metin kayda ve Narrative Log'a eklenir. [Konuşma metinleri](SCENES.md#kalp-konuşmaları) |

**Öneri.** Açılış ve önemli karşılaşmalar birden fazla replikten oluşabilir. Anlık ipucu bir eylem, kısa tepki bir gözlem taşır. Geçmişi açıklayan cümleler oyuncunun o sırada gördüğü bir nesneye, yaptığı işe veya az önce açtığı soruya bağlanır. Öncelik ve kapanma ayrıntıları [Arayüz](UI.md) içinde tanımlanır.

## Dört karakterin sesi

| Karakter | Önce neye dikkat eder? | Cümle ve tavır | Yazım örneği |
| --- | --- | --- | --- |
| **Mother Superior** | Evin, mahallenin ve koloni hafızasının insanlar için anlamına. | Sıcak ve ölçülü. Arşivden kısa, somut bir duyusal ayrıntı kullanabilir. Yetkiyi devrederken güven verir. | “You can see the lights from the ship. That will be how the next arrivals know where home is.” |
| **High Father** | Toleranslara, kapasiteye ve oyuncunun yapabileceği sıradaki kontrole. | Sakin, kesin ve pratik. Bir risk söylerse beraberinde gözlenebilir bir belirti ya da düzeltme yolu verir. | “The foundations are in. Open the City panel and check its available capacity before you expand.” |
| **Bolo** | Hangi verinin gerçekten ölçüldüğüne, bir kelimenin ne anlattığına ve yerin tarihine. | Keskin bir saha dilbilimcisi. Kendi cümlesini düzeltebilir, yakınlık gösterdiğinde bir ayrıntıya dönebilir. Oyuncunun karar vermesine alan açar. | “They called it empty ground. I found three different words for it. Keep that in mind when you read the survey.” |
| **Burkai** | Büyük ölçekten hemen sonra yakındaki küçük ayrıntıya. | Ses rehberi için önerilen başlangıç, sakin ve kısa cümleler, acele etmeden konuşmak ve kuru sıcaklık. Ay sahnesindeki daha taşkın ses ayrı bir taslak. | “Cities look small from here. I can still see your lights.” |

### Kaynak notları

- Caretaker taslağı, iki AI'ın kolonideki çocukları büyütmüş gibi konuştuğu kısa olay replikleri içerir. Mother Superior anılar ve insanlar, High Father ölçümler ve çalışma düzeni için başlangıç noktası sağlar. İki AI'ın aynı olayda sırayla konuştuğu örnekler, aktif danışman kuralına göre günlük kanalda tek sese uyarlanır. Çok konuşmacılı ana sahne formatında birlikte kullanılabilir. [Caretaker olay replikleri](sources/caretaker-barks.md)
- Bolo'nun ses rehberi, gözlem ve kelime seçimini karakterin mesleğine bağlar. İlk kez girilen bir mekânda yankıyı dinleme, yeni bir terimi heceleme ve kendi ifadesini düzeltme seçici biçimde kullanılabilir. `[click]` gibi işaretler performans notudur. Yeraltı dilinden önerilen kelimeler ve telaffuzlar karar bekliyor. Bolo'nun ilk şehir kurulurken konuştuğu eski örnekler öğreticiden sonraki uygun olaylara taşınabilir. [Bolo Voice Bible v1](sources/bolo-voice-bible-v1.md)
- Burkai'nin ses rehberi, kısa ve gündelik bir dille konuşan, tartışmaya girmeyen bir gözlemciyi tarif eder. Ay sahnesinde Ece adını kaynak taslaktaki gibi kullanır. Alıcıyı açıklarken gördüğü izi tarif eder, Bolo ile oyuncu kendi ölçümlerini tanır. [Burkai Voice Guide](sources/burkai-voice-guide.md) · [Burkai sahne taslağı](sources/burkai-scenes.txt) · [Ay sahnesinin tasarımı](STORY.md#ay-burkai-ve-daha-ileri-eşikler)

## Sahne metinleri

Açılış, ilk öğretici, Bolo, The Rim Echo, Burkai ve ilk gezegen varışının satırları, seçenekleri ve sonuçları [Sahneler](SCENES.md) içinde. Yıldız haritası açılışın tek gizem ipucudur. Lazarus kaydı ilk City'den sonra açılabilir.

## Yazım ve veri sözleşmesi önerisi

Her sahne kartında bir kimlik, konuşma türü, tetikleyici, önkoşul, konuşmacı kuralı ve görüldü davranışı bulunabilir. Yazılan dalların ortak devamı ve varsa kayda işlenen etkisi belirtilir. Bu alanlar bir uygulama şeması seçmeden diyalogların üretilebilmesini sağlar.

| Alan | Yazarken belirtilmesi gereken |
| --- | --- |
| Kimlik ve durum | Benzersiz sahne adı ve **Karar**, **Öneri** veya **Açık** durumu. |
| Tetikleyici | Oyuncu eylemi ya da oyun olayı. Kazının hazır olması ile kapanışının tamamlanması ayrı olaylardır. |
| Önkoşul | Bilinen bilgi, erişilebilir konum, ilgili keşif, gereken görev ve günlük konuşmalar için aktif danışman. |
| Konuşmacı ve satır | Sabit hikâye karakteri veya aktif danışmana göre seçilen İngilizce satır. Performans notu ayrı alan olur. |
| Cevap ve devam | Oyuncunun gördüğü cevap, hemen verilen tepki, kalıcı bir etki varsa koşulu ve ortak devam noktası. |
| Kayda etkisi | Tek gösterim, uygun tekrar, sahne tamamlanması ve varsa karakter açılışı. Yükleme davranışı için [Arayüz](UI.md) ve [Danışmanlar](ADVISORS.md). |

Günlük metinler güncel oyun durumundan beslenir. Maliyet, süre, tarif veya kazanım içeren satırlar ilgili veri ya da doğrulanmış mekanikle eşlenir. Kaynak taslaklarındaki eski başlangıç Science değeri veya üretim davranışı yeniden kullanılmadan önce kaynaktan kontrol edilir. Gizli mineral adı ancak oyun onu açtığında kullanılır. Bir danışmanda uygun replik yoksa temel görev bilgisi kartta görünür. Başka bir karakterin kendiliğinden günlük kanala girmesi, oyuncunun seçtiği ses kuralını bozar.

Bugünkü VSM kazı metinleri `StoryDialog` üzerinden konuşma, seçim ve sonuç oynatıyor. Yeni sahnelerin bu yapıyı ve alt paneli nasıl paylaşacağı bir arayüz ve uygulama kararıdır. [Mevcut hikâye paneli](../../../scripts/ui/excavation/StoryDialog.gd#L205)

### Gündelik konuşma CSV'si

**Karar.** Boşta konuşmalar, olay tepkileri ve kazı hatırlatmaları ayrı bir UTF-8 CSV'de tutulur. `advisor_id` etkin danışmanla, `event_id` oyundan gelen olayla eşleşir. `first` satırı, o danışman görevdeyken gerçekleşen ve gösterilebilen ilk eşleşmede bir kez oynar. Görüldü kaydı CSV satır kimliğine yazılır. Öğreticinin karşıladığı, danışman değişince elenen ya da hiç görünmeyen replikler görülmüş sayılmaz. `interval` boşta konuşma aralığını, `pending` açık kazı hatırlatma aralığını kullanır. [Replik CSV'si](data/advisor_barks.csv)

**İlk uygulama varsayımı.** Öğretici bittikten sonra, oyun duraklamadan en az 90 saniye geçmiş ve panel boşsa bir boşta replik seç. Aynı karakterin son boşta repliğini sıradaki seçimden çıkar. Olay tepkisi önceliklidir. Aynı olayı öğretici anlatıyorsa rehber metni yeterlidir. Etkin AI, `home_dig_pending` repliğini ilk City tamamlandıktan ve The Toppled Stones erişilebilir olduktan sonra kullanır. `lunar_dig_pending` için Bolo'yla iki yoldan birinde tanışılmış olmalıdır. The Rim Echo başlatılabildiğinde veya sonucu okunabildiğinde hatırlatma çıkabilir. Kazı başlatma veya kapanış eylemi değişince uygun hatırlatma güncellenir. Aynı saha için ilk öneri iki hatırlatma arasında beş dakika aktif oynanış beklemektir. Hatırlatma hedef kartını ya da kazı konumunu açabilir. Geçmiş olay tepkileri yüklemede tekrar üretilmez.

Olay adayları her yeni City ve bina tamamlanmasında, her `skill_unlocked` olayında ve her kazı hazır bildiriminde değerlendirilir. Örneğin oyuncunun ilk City'si AI öğreticisinde anlatılabilir. Bolo'nun şehir repliği, Bolo görevdeyken tamamlanan sonraki bir City'de açılabilir. `lander_reached_moon` seferin kendi tek seferlik olayıdır. İlk gezegen varışı kendi yazılmış sahnesinde anlatılır. [Godot bağlantıları](IMPLEMENTATION.md#godot-bağlantıları)

### Narrative Log

**Karar.** Oyuncu geçmiş konuşmaları kayıt dosyasına bağlı bir Narrative Log üzerinden tekrar okuyabilir. Günlük, oyuncunun gördüğü satırları ve verdiği cevapları konuşmacı ve sahne bilgisiyle gösterir. Günlüğü açan oyuncu okuduğu sahneye aynı adımdan döner. Geçmişi okumak sahne ilerlemesini değiştirmez. [Arayüz](UI.md)

### Dönüş özeti

Dönüşte aktif danışman önce koruyucu uykudan geçen koloni süresini, sonra kaydedilmiş olayları anlatır. Zaman ve iş sonuçları en fazla 24 gerçek saatten alınan ortak %10 simülasyona dayanır. Bir kazı gerçekten hazır olduysa ekipten bekleyen iş olarak söz edilir. [Karşılama replikleri](SCENES.md#dönüş-ve-gemi-uykusu) · [Olay verisi](OFFLINE_EVENTS.md)

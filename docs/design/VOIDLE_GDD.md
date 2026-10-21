# VOIDLE: ANA OYUN TASARIM BELGESİ

**Belge türü:** Bağımsız Game Design Document ve uygulama sözleşmesi.  
**Dil:** Türkçe.  
**Tasarım tarihi:** 20 Ekim 2026.  
**Proje:** Voidle, Godot 4, masaüstü.  
**Kapsam:** Tip 0'ın oynanabilir ekonomisi, Tip 1'in 50 districtlik tasarımı, Tip 2-5'in ölçek sözleşmesi ve demo sunumu.  
**Durum:** Hedef oyun tasarımı. Bu belgenin hazırlanması oyuna uygulanmış bir güncelleme veya çalıştırılmış oyun doğrulaması anlamına gelmez.

## İçindekiler

1. [Belgenin bağlayıcı kuralları ve uygulama sınırı](#bolum-01)
2. [Oyunun kimliği, amacı ve temel döngüsü](#bolum-02)
3. [Terimler, kaynakların anlamı ve başlangıç oturumu](#bolum-03)
4. [Medeniyet katmanları, yerleşimler ve gerçek alt içerik](#bolum-04)
5. [Tip 1 City aileleri ve district matrisi](#bolum-05)
6. [Yüzey coğrafyası](#bolum-06)
7. [Mesafe, yakınlık ve uzaklık](#bolum-07)
8. [Ekonomi zamanı, stoklar ve ödeme sırası](#bolum-08)
9. [Global nüfus, enerji ve açıklar](#bolum-09)
10. [Sabit kaynak kataloğu ve işleme seçimi](#bolum-10)
11. [Kuruluş fiyatı, tekrar sayacı ve isimli malzeme](#bolum-11)
12. [Tip 0 bina kataloğu](#bolum-12)
13. [City, district ve gezegen seviyeleri](#bolum-13)
14. [Tip 1 sistem coğrafyası ve elli district](#bolum-14)
15. [Hazır plan, Güncelle, yıkım ve yeniden konumlandırma](#bolum-15)
16. [Oyuncunun Medeniyet 0 deneyimi ve ilerleme temposu](#bolum-16)
17. [Araştırma ağacı, strateji ve fraktal miras](#bolum-17)
18. [Trade, tarifler, rezervler ve otomasyon](#bolum-18)
19. [Offline ilerleme ve kazanç bütçeleri](#bolum-19)
20. [Ay, roketler ve Medeniyet 0'ın tamamlanması](#bolum-20)
21. [Sürekli hedefler, başarımlar, izinler ve kayıt sözleşmesi](#bolum-21)
22. [Ekranlar, bilgi düzeni ve kullanıcı deneyimi](#bolum-22)
23. [Kontroller, görsel dil, ses ve ayarlar](#bolum-23)
24. [Kalıcı veri modeli ve içerik sözleşmeleri](#bolum-24)
25. [Kayıt, yükleme ve işlem güvenilirliği](#bolum-25)
26. [Evren üretimi, koordinatlar ve performans](#bolum-26)
27. [Proje sorumluluk haritası ve hedef servisler](#bolum-27)
28. [Uygulama paketleri ve bağımlılıklar](#bolum-28)
29. [Beklenen davranışlar ve uygulama kabul ölçütleri](#bolum-29)
30. [İçerik kapsamı ve gelecekte genişleme sınırı](#bolum-30)
31. [Ana tasarım kararlarının bütünlük özeti](#bolum-31)

<a id="bolum-01"></a>

## 1. Belgenin bağlayıcı kuralları ve uygulama sınırı

Bu dosya Voidle'ın hedef davranışını kendi başına açıklar. Oyunun nasıl oynandığını anlamak, içerik üretmek veya uygulama yapmak için başka bir tasarım belgesinin okunması gerekmez. Formüller, içerik listeleri, ekran davranışları ve teknik sorumluluklar bu dosyada birlikte bulunur.

### Tasarım kuralı ile denge sayısı

| İşaret | Anlamı | Uygulama davranışı |
| --- | --- | --- |
| **Oyun kuralı** | Oyunun işleyiş sözleşmesi. | Başka bir kuralla değiştirmeden uygula. |
| **Denge başlangıcı** | Kurala bağlanmış somut ilk sayısal ayar. | Merkezi veri olarak uygula; kullanıcı geri bildirimiyle bütün ilgili alanları birlikte ayarla. |
| **Gelecek içerik** | Veri yapısının desteklediği, bu teslimde oynanabilir olmayan aşama. | Önizleme ve mimari sınırını koru; ayrıntılı ekonomi uydurarak etkinleştirme. |

Belgede katsayısı verilen ekonomik tablolar birer denge başlangıcıdır. Katsayıların somut olması, farklı stratejilerin oyunda eşit sürede tamamlandığının kanıtı değildir. Uygulama, ilk ayarı gizli istisnalarla değiştirmemelidir.

### Bu belgeyi uygulayan yapay zekâ için çalışma sözleşmesi

1. İlk olarak içerik yetkisini belirle: Tip 0 demo ekonomisi, Tip 1 tam oyun içeriği ve üst ölçek önizlemesi aynı erişim değildir.
2. Kaynak dosyasını okumadan bu tasarımın zaten uygulanmış olduğunu varsayma.
3. Sayıları tek veri tanımında tut. Arayüz, satın alma, üretim ve offline ayrı formüller kullanmasın.
4. Özet ekran ile ayrıntı ekranını aynı gerçek nesnelere bağla.
5. Satın alınan araştırmayı fiziksel bina, district, City veya gezegen hediyesi sayma.
6. Yeni ham veya işlenmiş kaynak, nüfus büyümesi, bina seviye sistemi, zorunlu filo ya da kargo taşıma döngüsü ekleme.
7. Doğal gövde ile o gövdedeki oyuncu yerleşimini ayrı modelle.
8. Tip 1'in 50 districtini yalnız isim değiştirilmiş beş hazır plan olarak daraltma. Her modelin gerçek kimliği, koşulu ve ekonomik rolü bulunur.
9. Üst medeniyete çıkıldığı için mevcut alt yatırımları silme, bedava yeniden kurma veya ikinci defa ücretlendirme.
10. Görünür coğrafyayla açıklanamayan gizli yerel yüzde haritaları üretme.
11. Yıkım, taşıma, satış, otomasyon ve kayıt işlemlerini merkezi erişim ve ödeme kurallarından geçir.
12. Bu dosya bir oyun kodu çalıştırma talimatı değildir. Kullanıcı ayrıca istemedikçe Godot, Unity, oyun, otomatik test veya build çalıştırma. Oynanış denemelerini kullanıcı yapar.
13. Uygulama görevi verilmedikçe bu dosyayı hazırlamak için kaynak, sahne, ayar veya kayıt dosyalarını değiştirme.
14. Mevcut kayıtların yeni ekonomiyle taşınması zorunlu değildir. Bu durum kayıtları izinsiz silme yetkisi vermez.
15. GDD içindeki gelecek kapsamını tamamlanmış ve oynanabilir içerik olarak raporlama.

### Yetki ayrımı

| Kavram | Ne belirler? |
| --- | --- |
| `civilization_type` | Oyuncunun ulaştığı medeniyet göstergesi. |
| `playable_content_type` | Hangi medeniyetin ekonomik eylemlerinin gerçekten açık olduğu. |
| `demo_completed` | Demo yolculuğunun tamamlanıp tamamlanmadığı. |
| `preview_permissions` | Hangi haritaların ve ağaçların incelenebildiği. |
| `effective_grants` | Gerçekten satın alınmış veya geçerli mirastan kazanılmış araştırma hakları. |

Bir nesnenin görünmesi, oraya yerleşme veya içeriğini satın alma hakkı değildir. Arayüz dışında çağrılan komutlar da bu ayrımı korur.

<a id="bolum-02"></a>

## 2. Oyunun kimliği, amacı ve temel döngüsü

Voidle, oyuncunun bir gezegendeki ilk yerleşiminden başlayarak daha büyük medeniyet ölçeklerine çıktığı bir yerleşim ve incremental ekonomi oyunudur. Oyuncu enerji, nüfus kapasitesi, malzeme, bilim ve ticaret arasında bir ekonomik yaklaşım kurar. Yüzey coğrafyası, yerleşim mesafesi ve araştırma tercihleri bu yaklaşımı şekillendirir.

İlerleme yalnız aynı binadan daha çok kurmaktan oluşmaz. Yeni teknoloji, üretim tarifleri, daha yoğun modeller, coğrafyaya uygun uzmanlıklar ve daha büyük yönetim ölçekleri açılır. Oyuncu büyüdükçe daha önce ayrıntıyla yönettiği katmanı üst ekranda bir ekonomik birim olarak yönetebilir.

### Temel oyun döngüsü

1. Görünen coğrafyayı ve mevcut kuruluş seçeneklerini incele.
2. City ve district için yer seç veya otomatik planın önerisini değerlendir.
3. Enerji, nüfus kapasitesi ve üretim araçlarını kur.
4. Gövdedeki uygun ham kaynakları gerçek üretimle keşfet.
5. Seçtiğin hammaddeleri Goods, Fuel ve Rare ürünlerine işle veya erişimin olan ürünleri trade ile edin.
6. Science ile teknoloji ve strateji dalları aç.
7. Kurulu ekonomiyi yeni içerikle güncelle, yoğunlaştır veya yeniden düzenle.
8. Medeniyetin ana hedefine ilerle; gerekli fiziksel tesisleri ve yolculuğu tamamla.
9. Bir üst ölçeğe çıktığında mevcut yerleşimleri koruyarak yeni ekonomik birimler kur.
10. İstersen ayrıntıya geri inip otomatik düzeni elle değiştir.

### Oyuncunun hedefi

Tip 0'ın ana hedefi, ana dünyadan Ay'a ulaşmak, Ay'da gerçek Moonstone üretmek, Ay'a özel uzay tesisini kurmak ve gelişmiş roketi seçilmiş başka bir gezegene ulaştırmaktır. Son varış Tip 0'ı tamamlar ve Tip 1'e geçişi gösterir.

Tam oyunda Tip 1'in yönetim alanı güneş sistemidir. City'ler uzmanlaşır, districtler panelden alınan küçük ekonomik birimlere dönüşür ve gezegenlerin sistem konumu yeni kuruluş tercihleri yaratır. Daha yüksek medeniyetler aynı dört katman örüntüsünü daha geniş haritalara taşır.

### Stratejik yaklaşımlar

| Yaklaşım | Ana yatırım | Ekonomik çıkış | Gerçek bedeli |
| --- | --- | --- | --- |
| Bilim ağırlığı | Laboratuvar, gözlem, bilim coğrafyası ve araştırma dalları. | Teknolojiye hızlı erişim; fazla Science'ı krediye dönüştürme. | Enerji, bakım, çalışan ve araştırmaya ayrılan yatırım. |
| Nüfus ağırlığı | Konut kapasitesi ve fazla nüfus etkileri. | Boş kapasiteden kredi/Science ve üretim desteği. | Konut bakımı, kuruluş alanı ve diğer üretimlere ayrılmayan yatırım. |
| Sanayi ağırlığı | Ham çıkarım, Goods/Fuel/Rare işleme. | Doğrudan malzeme temini ve işlenmiş ürün satışı. | Ham girdiler, enerji, çalışan ve depolama. |
| Ticaret ağırlığı | Ticari üretim ve otomasyon. | Kredi üretip izinli malzemeleri satın alma. | Ticari bakım, alış-satış farkı ve gerekli kaynak keşfi. |
| Enerji ağırlığı | Coğrafyaya uygun enerji ve yoğun üretim desteği. | Büyük ekonomiyi çalıştırmak ve güçlü modellerin giderlerini karşılamak. | Enerji tek başına sınırsız para veya Science'a dönüşmez; desteklediği hatları kurmak gerekir. |
| Yakın küme | Aynı aileden yakın yerleşimler. | Her uygun kaynaktan tam yakınlık katkısı. | Tekrar fiyatları, kapasite, nüfus/enerji ve fiziksel yer. |
| Uzak yerleşim | Uygun coğrafyayı seçen bağımsız kuruluş. | Uzaklık katkısı ve değerli konuma erişim. | Yakın kümelerin çok sayıda kaynak katkısından vazgeçmek. |

Oyuncu bu yaklaşımları birleştirebilir. Bütün ailelerden eşit sayıda kurma zorunluluğu yoktur. Bazı fiziksel keşif ve roket tesisleri ana ilerleme kapısıdır; bunların dışındaki malzeme ihtiyaçları uygun üretim veya trade yoluyla karşılanabilir.

### İncremental akış hedefi

- İlk dakikalarda tek uzun birikim duvarı yerine birkaç uygun yatırım bulunmalı.
- Yeni oyuncu enerji ve nüfus açığını üst arayüzden anlayabilmeli.
- İlk işleme, erken trade ve ilk uzmanlıklar birbirini bekleyen kapalı bir döngü oluşturmamalı.
- Üst tier daha yoğun çıktı vermeli; bakım, çalışan veya yatırım yönünden bir bedeli bulunmalı.
- Üstel fiyat ve çalışan artışı, çıktı ve yeni kapasite seçenekleriyle birlikte ele alınmalı.
- Tip 0 için 45-75 dakikalık ana yol ve gelişim sırasında yaklaşık 30-90 saniyede anlamlı karar fırsatı ilk akış hedefidir.
- Tamamlanma süresi zorunlu sayaç değildir. Oyuncuyu bu süreye getirmek için görünmez gelir ayarı veya gizli kaynak hibesi kullanılmaz.

<a id="bolum-03"></a>

## 3. Terimler, kaynakların anlamı ve başlangıç oturumu

### Temel sözlük

| Terim | Bu oyundaki anlamı |
| --- | --- |
| Medeniyet tipi | Tip 0-5 arasındaki yönetim ve ilerleme ölçeği. |
| Tier | Aynı ölçeğin içindeki içerik yoğunluğu/teknolojik basamak. Medeniyet tipi değildir. |
| Seviye | District, City veya gezegen kapasitesini ve tanımlı tabanlarını geliştiren değer. Binanın seviyesi yoktur. |
| Doğal gövde | Seed, tip, yarıçap, yörünge ve mineral kümesi taşıyan gezegen/uydu gibi dünya nesnesi. |
| Yerleşim | Doğal gövde veya üst harita içinde oyuncunun kurduğu ekonomik alt ağaç. |
| City | Tip 0'da districtleri kapsayan yüzey yerleşimi; Tip 1'de uzmanlık ailesi bulunan alt yerleşim. |
| Capital District | Bir City kurulunca otomatik oluşan merkez district. City'nin kendisi değildir. |
| District | Tip 0'da binaları kapsar; Tip 1'de üst panelden yönetilen gerçek konumlu ekonomik birimdir. |
| Bina modeli | Tek kimliği, kuruluş tarifi, yuva bedeli ve işlevi bulunan yapı türü. |
| Bina adedi | Aynı modelin kurulmuş gerçek sayısı. Farklı girdi satırları toplam adedi değiştirmez. |
| Aile | Energy, Production, Science, Residential veya Commercial ekonomik uzmanlığı. |
| Rol | Bir districtin fiilen enerji, üretim, bilim, konut veya ticaret işlevi. Tip 1'de ev sahibi aile ile farklı olabilir. |
| Genel | Eşit veya boş içerik yüzünden otomatik uzmanlık seçilemeyen City'nin geçiş etiketi. Oyuncu aile seçer. |
| Merkez | Otomatik eklenen, uygun mesafedeki yerleşimlere destek veren özel alt nesne. Beş aileden biri değildir. |
| Plan / prefab | Gerçek alt nesneleri bedelleriyle kuran ve yerleştiren tarif. Bağımsız ikinci gelir kaynağı değildir. |
| Güncelle | Açılmış içerik ve mevcut nesneler arasındaki fark için ücretli kuruluş/değişim teklifi. |
| Keşif | Uygun yerel üretimle bir gövde mineralinin erişiminin kalıcı açılması. Haritaya bakmak değildir. |
| İnceleme | Bir bölgeyi görüntüleme. Ekonomik yerleşim veya kaynak keşfi hakkı vermez. |
| Production | Türkçe arayüzde Üretim/Sanayi; ham çıkarım ve işleme ailesi. |
| Residential | Türkçe arayüzde Nüfus/Konut; sabit kapasite ailesi. |
| Credits | Kredi, küresel para stoğu. |
| Science | Bilim, araştırma ve trade'de kullanılabilen küresel stok. |
| Goods | Consumer Goods, düzenli bakım ve ileri kuruluş ürünü. |
| Fuel | Fuel Rods, yakıt ürünü; enerji ve seferlerde kullanılır. |
| Rare | Rare Elements, nadir işlenmiş ürün. Bir ham mineralin nadirlik değeriyle aynı kavram değildir. |
| AU | Sistem içinde yaklaşık 149,6 milyon km'lik astronomik uzaklık birimi. |
| Gökada / Galaksi | Oyunun ayrı iki üst harita katmanı. Veri adları ve hiyerarşide birleştirilmez. |

### Yeni oyun başlangıcı

| Alan | Başlangıç |
| --- | --- |
| Medeniyet | Tip 0. |
| Oynanabilir içerik | Tip 0. |
| Kredi | 3.000. |
| Science | 450. |
| Ham ve işlenmiş stoklar | 0; henüz keşfedilmemiş kaynaklar gizli. |
| Başlangıç gövdesi | Terran ana dünya, erişilebilir uygun Ay ile. |
| İsim ve arazi | Seed ile üretilir; sabit gerçek Dünya adı gerektirmez. |
| İlk City | Kuruluş için oyuncu geçerli yer seçer; gövdenin ilk City kabuğu ücretsizdir. |
| Otomatik merkez | İlk City ile bir Capital District. |
| Ay yolculuğu | Henüz yapılmamış. |
| Tam üst evren incelemesi | Henüz açık değil. |
| Offline ilerleme | Açık; oyuncu ayarlardan kapatabilir. |
| Görev paneli | Açık ve daraltılabilir. |

3.000 kredi ve 450 Science yalnız yeni oyun kurulumunun bütçesidir. Kayıt yükleme, sahne değiştirme, fraktal miras, içerik sıfırlama veya son yapıyı yıkma bu bütçeyi yeniden vermez.

### İlk oturumun anlaşılır sırası

1. Oyuncu ana dünyayı ve görünen coğrafyayı görür.
2. İlk City yerini seçer; merkez otomatik eklenir.
3. Üstte küresel nüfus ve enerji durumunu, solda seçili yerleşimin alt içeriğini görür.
4. İstediği ekonomik yaklaşımı destekleyen districti kurar.
5. Başlangıç Science'ını tek bir zorunlu araştırma dizisine bağlamadan kullanır.
6. Uygun Production aracıyla ilk ham kaynağı keşfeder ve çıkarır.
7. İşleme veya trade açarak kuruluş ve bakım malzemelerini temin eder.
8. Görev panelinden Ay yolculuğunun hangi fiziksel adımlarının eksik olduğunu takip eder.

### Başlangıç üretiminin erişilebilir olması

- İlk ham çıkarım, henüz açılmamış bir işlenmiş ürünü veya kendi keşfedilmemiş hammaddesini istemez.
- İlk çalışan işleme hattının maliyeti, işlediği ürünü önceden üretmiş olmayı zorunlu kılmaz.
- Fuel ve Rare açılışı araştırma ilerlemesine bağlıdır. Gezegen seviyesi bunların gizli ikinci kilidi olmaz.
- İlk Fuel erişiminin gezegen Lv2-3, Rare erişiminin Lv4 civarındaki normal oyun hızına denk gelmesi hedeflenir; koşul gezegen seviyesi değildir.
- Başlangıç Terran ve Ay dağılımı, zorunlu fiziksel ilerlemeyi imkansız kılacak şekilde üretilemez.
- Sabit eğitim seed'i ve farklı gövde tipinde rastgele başlangıç bu oynanabilir başlangıcın parçası değildir.

<a id="bolum-04"></a>

## 4. Medeniyet katmanları, yerleşimler ve gerçek alt içerik

### 4.1. Dört katmanlı dünya

Her medeniyet aynı dört yönetim katmanını kullanır. Kapsayıcı harita ekonomik ortamı gösterir. Sonraki iki katman haritada konum sahibi nesnelerdir. En alt katman üst görünümde panelden yönetilir.

| Medeniyet | Kapsayıcı harita | Büyük yerleşim | Alt yerleşim | Üst görünümde panelden yönetilen içerik |
| --- | --- | --- | --- | --- |
| Tip 0 | Gezegen | City | District | Bina |
| Tip 1 | Güneş sistemi | Gezegen | City | District |
| Tip 2 | Gökada | Güneş sistemi | Gezegen | City |
| Tip 3 | Galaksi | Gökada | Güneş sistemi | Gezegen |
| Tip 4 | Evren | Galaksi | Gökada | Güneş sistemi |
| Tip 5 | Paralel Evrenler | Evren | Galaksi | Gökada |

Gökada ve Galaksi iki ayrı oyun katmanının adıdır. Katman adları birbirinin yerine kullanılmaz. Medeniyet tipi, bina tier'ı ve yerleşim seviyesi ayrı ilerleme alanlarıdır.

Yalnız bina bağımsız harita konumuna sahip değildir. District, City, gezegen, güneş sistemi ve Gökada üst görünümde panelde listelense bile gerçek konumunu korur.

Tip 1 districti uzaya yerleştirilmez. Seçilmiş gezegen üzerindeki bir City'ye bağlıdır ve gerçek yüzey konumuna sahiptir. Güneş sistemi görünümü bu konumu özetler. Oyuncu gezegene yaklaştığında aynı districti, aynı binaları ve aynı üretim durumunu görür.

### 4.2. Otomatik merkezler

Ana yerleşim ilk kez kurulduğunda merkez alt nesnesi kuruluşun parçası olarak oluşur.

| Medeniyet | Ana yerleşim | Otomatik merkez | Merkezin etkilediği katman |
| --- | --- | --- | --- |
| Tip 0 | City | Capital District | Yakındaki districtler |
| Tip 1 | Gezegen | Orbital City | Yakındaki City'ler |
| Tip 2 | Güneş sistemi | Dyson Sphere Gezegen | Yakındaki gezegenler |
| Tip 3 | Gökada | Stellar Engine System | Yakındaki güneş sistemleri |
| Tip 4 | Galaksi | Black Hole Gökada | Yakındaki Gökada'lar |
| Tip 5 | Evren | Spacetime Galaksi | Yakındaki galaksiler |

Her ana yerleşimde merkez rolünü taşıyan en fazla bir gerçek alt nesne bulunur. Ekranı açmak, kayıt yüklemek, hazır planı yeniden okumak veya Güncelle teklifini açmak ikinci merkez yaratmaz.

Merkezler normal üretim ailesi değildir. Baskın aile sayımına katılmaz. Bir City konteyneri kendi merkezine ek ikinci bir merkez bonusu dağıtmaz.

Merkez katkıları kilometre veya ilgili üst haritanın mesafe profiliyle hesaplanır. Yol bağlantısı aranmaz. Uygun mesafedeki başka ana yerleşime ait merkezler de katkı verebilir. Bir kaynak kimliği aynı alıcıya aynı etkiyi bir kez verir.

Orbital City ayrı bir City rolüdür. Yüzey kuruluşuna uygun olmayan yörünge içeriği, sıradan yüzey districti gibi konumlandırılmaz. Yörünge City'sinin ortak ekonomik haritada kayıtlı, kararlı bir konumu vardır. Görsel yörünge hareketi merkez bonuslarını kareden kareye değiştirmez.

Bir gövdeye varmak o gövdeye yerleşmek değildir. Yalnız seyahat varışı gerçekleştiğinde merkez veya üretim planı otomatik yaratılmaz. Merkez, oynanış izni olan gerçek yerleşim işleminde oluşur.

### 4.3. Tek gerçek nesne ve tek ekonomi

Her yerleşim kalıcı kimlik, ebeveyn kimliği ve gerçek çocuk kimlikleri taşır.

Üst kart, alt görünüm ve üretim hesabı aynı kimliklere bakar. Üst görünümdeki toplam, alt nesnelerin toplamıdır. Üst kart aynı üretimi ikinci bir nominal gelir olarak eklemez.

Bir planın kurduğu binalar yalnız görsel süs değildir. Gerçek adet, tarif, girdi seçimi, tur ilerlemesi, duraklatma durumu, enerji, nüfus, maliyet ve ödeme kayıtları vardır.

Kamera değişimi şu işlemleri yapmaz:

- Nesneyi yeniden satın almaz.
- Üretim turunu yeniden başlatmaz.
- Ödenmiş girdiyi ikinci kez tüketmez.
- Ücretsiz bina veya kaynak oluşturmaz.
- Alt görünümdeki konum ve bonusları silmez.
- Üst kart için ayrı bir üretim kopyası açmaz.

Bir planın gövde seed'i ve kullanıcı adı korunur. Gezegen veya sistem başka harita konumuna taşınırsa içeriği yeniden rastgele üretilmez.

### 4.4. Her medeniyette hazır plan ve elle yönetim

| Tip | Panelde yönetilen nesne | Hazır planın yaptığı iş | Ayrıntıdaki elle yönetim |
| --- | --- | --- | --- |
| 0 | Bina | District yuvalarına gerçek bina adetleri kurar | Adet, girdi, duraklatma, yıkım ve uygun districte aktarım |
| 1 | District | City'ye gerçek yüzey districtleri ve bunların binalarını kurar | Gezegen görünümünde district konumu, binaları ve girdi grupları |
| 2 | City | Gezegene gerçek City, Capital ve district alt ağaçları kurar | City konumundan bina girdisine kadar aynı nesneleri düzenleme |
| 3 | Gezegen | Güneş sistemindeki seçilmiş gezegen için gerçek yerleşim planları kurar | Sistem görünümünde gezegenin ekonomik konumu, ardından City/district/bina ayrıntısı |
| 4 | Güneş sistemi | Seçilmiş Gökada içindeki gerçek sistem ve gezegen yerleşim planlarını kurar | Gökada görünümünde sistem konumu, ardından gezegen ve yüzey ayrıntısı |
| 5 | Gökada | Seçilmiş Galaksi içindeki gerçek Gökada ve sistem yerleşim planlarını kurar | Galaksi görünümünde Gökada konumu, ardından sistem/gezegen/City ayrıntısı |

Tip 3'te gezegen bir sayısal üretim kartına indirgenmez. Sistem içindeki ekonomik konumu, yarıçapı, mineral kümesi, City'leri, districtleri ve binaları kayıtlıdır. Gezegen taşınırken City'lerin yerel enlem/boylamı korunur.

Tip 4'te güneş sistemi gerçek bir üst nesnedir. Yıldız ve gezegen kimlikleri, gezegenlerin yerel ekonomik yörünge konumları ve bütün yerleşimler korunur. Sistem taşınırken iç koordinatlar yeniden seed edilmez.

Tip 5'te Gökada gerçek bir üst nesnedir. Güneş sistemleri ve onların alt içerikleriyle birlikte korunur. Gökada taşımak yalnız bir simgenin adını değiştirmek veya bütün çocuklarını yoktan yeniden üretmek değildir.

Üst nesne konumu oyun haritasındaki ekonomik yerleşim konumudur. Bu düzenleme özelliği ayrı yörünge fiziği, çarpışma, kargo filosu veya yakıtlı taşıma simülasyonu oluşturmaz.

Tip 2-5 için katman, merkez, kalıcı kimlik, hazır plan, elle düzenleme, yıkım ve taşıma sözleşmeleri geçerlidir. Bu medeniyetlerin her birine ellişer tamamlanmış katalog varsayılmaz. Oynanabilir katalogları kendi içerik tasarımlarıyla eklenir.

### 4.5. Kamera ve görünürlük

Oyuncu üst ölçekten bir alt nesneye yaklaşarak ayrıntısına iner. Geri çıktığında aynı nesnenin özetine döner. Kaynaklar imparatorluğun ortak havuzundadır; kamera değiştirmek veya gezegen değiştirmek kaynak transfer görevi gerektirmez.

Harita görünürlüğü, medeniyet seviyesi ve oynanabilir içerik izni ayrı tutulur. Önizleme için üretilen doğal gövdeler aktif koloni veya üretici sayılmaz.

Tip 0 tamamlanıp Tip 1'e varıldığında Dünya ve Ay'daki izinli Tip 0 ekonomisi sürer. Tip 1 aile ataması ve yeni planlar önizlenebilir; oynanabilir Tip 1 içeriği kapalıyken yeni host katkıları, yeni district etkileri veya ileri kaynak erişimleri eski ekonomiye otomatik uygulanmaz.

<a id="bolum-05"></a>

## 5. Tip 1 City aileleri ve district matrisi

### 5.1. Beş City ailesi

Tip 1'de beş normal City ailesi vardır:

- Energy City.
- Production City.
- Science City.
- Residential City.
- Commercial City.

Genel, eşit veya boş başlangıcın belirlenmemiş durumudur. Altıncı kalıcı uzmanlık ağacı veya yeni bir indirim ailesi değildir.

Gezegenin Production Gezegen veya Science Gezegen gibi ekonomik tür alması Tip 2'nin aile sözleşmesidir. Tip 1'de yeni gezegen aileleri oluşturulmaz.

Her yerleşimde şu bilgiler birbirinden ayrılır:

| Alan | İşlev |
| --- | --- |
| Oyuncu adı | Oyuncunun koyduğu özel isim |
| Canlı üretim profili | Gerçek alt yerleşimlerden türetilen, bilgi amaçlı güncel üretim dağılımı |
| Kilitli City ailesi | Tip 1'de içeriğin uyması gereken seçilmiş ana aile |
| Kuruluş fiyat ailesi | Ödeme anında sabitlenen tekrar sayacı ailesi |
| Kuruluş planı ve sürümü | Hangi gerçek alt içeriklerin planlandığı |
| Elle düzenleme kayıtları | Oyuncunun korumak istediği konum ve içerik seçimleri |

Oyuncu adı aile ataması sırasında otomatik değiştirilmez. Kilitli Host A, sonraki yıkım, duraklatma, taşıma veya alt rol dağılımı değişiklikleriyle yeniden hesaplanmaz. Canlı üretim profili yalnız bilgi verir; satın alma iznini ve yakınlık ailesini değiştirmez. Ayrı bir ücretsiz yeniden uzmanlaşma işlemi yoktur. Yeni aileyle kuruluş, yıkım ve yeniden kuruluş kurallarını kullanır.

### 5.2. Tip 1'e geçişte toplu sınıflandırma

Aile ataması bütün mevcut City'lerin uyarlama öncesi tek görüntüsünden yapılır.

1. Bütün City ve tamamlanmış normal district listelerinin anlık görüntüsü alınır.
2. Her City'de Energy, Production, Science, Residential ve Commercial district adetleri sayılır.
3. Capital, Orbital City merkezi ve diğer otomatik merkezler sayılmaz.
4. İnşaat halindeki district sayılmaz.
5. District seviyesi, içindeki bina adedi ve mevcut üretim hızı sayımı ağırlıklandırmaz.
6. Tek başına en yüksek adedi olan aile o City'nin ilk Tip 1 ailesi olur.
7. En yüksek adette eşitlik varsa Genel atanır.
8. Merkez dışında tamamlanmış çocuk yoksa Genel atanır.
9. Bütün City'lerin sonuçları hesaplandıktan sonra uyarlama başlatılır.

Bir City uyarlandıktan sonra oluşan yeni etiketler diğer City'lerin ilk sınıflandırmasını değiştirmez. Sınıflandırma, uyarlama sırasında tekrar tekrar çalışan bir geri besleme değildir.

Örnek: Üç Production, iki Science ve bir Energy districti olan City Production ailesi alır. İki Production ve iki Science olan City Genel olur.

Genel durumundaki City için oyuncu beş aileden birini seçer. Oyuncu seçmeden otomatik maliyetli dönüşüm veya rastgele aile seçimi yapılmaz.

### 5.3. Host A ve rol B

Her Tip 1 districtinin iki ayrı anahtarı vardır:

- Host A: İçinde bulunacağı City ailesi.
- Rol B: Gerçek üretiminin ve alt binalarının işlevi.

Bir Energy City içindeki Enerji Bilimi districti Host Energy, Rol Science taşır. Science üretir, fakat City aile kilidine uygundur.

Normal Tip 1 district yakınlığında aile anahtarı Host A'dır. Aynı Energy hostuna ait Enerji Bilimi, Enerji Sanayisi ve Enerji Merkezi uygun mesafede birbirlerini destekler. Alıcının kendi gerçek çıktısı güçlenir; Enerji Bilimi'ne yakınlık verilmesi Science çıktısını artırır.

Farklı hosta sahip iki Science rolü, yalnız rol adı aynı diye başlangıç yakınlık kuralında eşleşmez. Böyle bir bağlantı açık bir çapraz aile skill'iyle kurulabilir.

Tip 0 districtlerinde ayrı host matrisi yoktur; normal yakınlık doğrudan mevcut işlevsel district ailesini kullanır.

Solar, Wind veya termal enerjiye özel araştırma ve coğrafya etkileri yalnız ilgili çıktı etiketine uygulanır. Energy hostu taşımak Science veya Goods çıktısına Solar bonusu vermez.

### 5.4. Beş çarpı beş temel matris

Satırlar Host A, sütunlar Rol B'dir.

| Host City | Energy rolü | Production rolü | Science rolü | Residential rolü | Commercial rolü |
| --- | --- | --- | --- | --- | --- |
| Energy | Enerji Merkezi | Enerji Sanayisi | Enerji Bilimi | Enerji Yerleşimi | Enerji Ticareti |
| Production | Sanayi Enerjisi | Sanayi Merkezi | Sanayi Araştırmaları | İşçi Yerleşimi | Sanayi Ticareti |
| Science | Araştırma Enerjisi | Deneysel Üretim | Araştırma Merkezi | Akademik Yerleşim | Bilim Ticareti |
| Residential | Yerleşim Enerjisi | Sivil Üretim | Toplum Araştırmaları | Konut Merkezi | Yerel Ticaret |
| Commercial | Ticari Enerji | Ticari Üretim | Pazar Araştırmaları | Ticari Yerleşim | Ticaret Merkezi |

Bu yirmi beş district gerçek kurulabilir modellerdir. Tip 0 districtlerinin yalnız adını değiştiren beş kart değildir. Her modelin kalıcı kimliği, Host A/Rol B bilgisi, fiyat sayacı, alt bina planı, koşulları ve gerçek yüzey konumu vardır.

### 5.5. Mevcut yatırımın uyarlanması

City ailesi kesinleşince bütün normal çocuklar o hosta uygun eşleniğe bağlanır. Rol B mevcut işlevi korur. Kilitli host bütün bu çocukların tekrar fiyatı, yakınlık ailesi ve yeni plan uygunluğu için sabit kalır; canlı üretim dağılımı değişince kendiliğinden başka aileye dönmez.

Örnek: Production City içindeki mevcut Science districti Sanayi Araştırmaları olur. İçindeki Lab binaları Mine'a dönüşmez. Bina kimlikleri, miktarlar, seviyeler, gerçek ödeme kayıtları, seçilmiş girdiler ve konumlar korunur.

Uyarlama için yeniden kuruluş bedeli alınmaz. Yalnız oyuncunun satın aldığı yeni içerik veya onayladığı Güncelle farkı ücretlendirilir.

Bir mevcut district standart planın referansından daha az veya daha fazla bina taşıyabilir. Uyarlama bunları otomatik olarak referans seviyeye tamamlamaz veya azaltmaz.

Aile kilidi, yeni district seçiminin Host A'sının City ailesiyle eşleşmesini gerektirir. City'nin host kilidini değiştirmek, eski child rollerini bedelsiz başka üreticiye dönüştürme yolu değildir. Geçersiz plan önerileri önce açık fark teklifi oluşturur.

City türünün geçici olarak farklı görünmesi kuruluş fiyat ailesini değiştirmez. Kuruluş fiyat ailesi ödeme sırasında sabitlenir; sonradan baskın çocukları değiştirmek tekrar fiyatını düşürmez.

<a id="bolum-06"></a>

## 6. Yüzey coğrafyası

### 6.1. Görünen on dört özellik

Yüzey coğrafyası oyuncu butona basmadan da ayırt edilebilir. Her pikselde değişen gizli potansiyel yüzdeleri kullanılmaz.

| Kimlik | Görünen özellik | Üzerinde tam katkı |
| --- | --- | --- |
| terrain_mountain | Dağ | Production +%20; Science +%30 |
| terrain_plain | Ova | Residential +%20; Commercial +%10 |
| terrain_forest | Orman | Residential +%10; Science +%10 |
| terrain_seacoast | Deniz kıyısı | Residential +%20; Commercial +%20; tidal enerji +%20 |
| terrain_lakeside | Göl kenarı | Residential +%20; Science +%10 |
| terrain_river | Nehir | Residential +%10; Commercial +%20 |
| terrain_desert | Çöl | Solar enerji +%30; Science +%10 |
| terrain_tundra | Tundra | Science +%20; Residential +%10 |
| terrain_glacier | Buzul | Science +%20 |
| terrain_volcanic | Volkanik alan | Jeotermal enerji +%30; Production +%20 |
| terrain_geothermal | Jeotermal yarık | Jeotermal enerji +%40 |
| terrain_wind | Rüzgârlı bölge | Wind enerji +%30 |
| terrain_ruins | Eski yerleşim | Science +%30; Commercial +%20 |
| terrain_crater | Krater | Production +%10; Science +%20 |

Dağ, kıyı, orman, volkan, nehir ve diğer özelliklerin görünür sınırı vardır. Aynı türün birden fazla görsel parçası aynı çıktıya sonsuz kopya bonus vermez.

Ayrı yüksek plato, verimli ova, delta, kanyon, regolit zemini, koyu Ay düzlüğü ve doğal liman bonus türü yoktur. Görsel malzeme olarak bulunmaları ek ekonomi etkisi oluşturmaz.

Regolit işleme modelinin adı, districtin belirli bir regolit noktasına kurulmasını gerektirmez. Harbor modelinin kuruluş koşulu deniz kıyısıdır; ayrı doğal liman etiketi istemez.

Saha Gözlem Evi dağ koşulunu kullanır. Sırt Türbini'nin seçici koşulu dağ ile rüzgârlı bölgenin birlikte bulunmasıdır. Kaldırılmış ayrı plato veya sırt etiketi zorunlu kapı olarak kullanılmaz.

### 6.2. Üç açık uygunluk durumu

| Konum | Tam bonusun alınan payı |
| --- | ---: |
| Özellik alanının dışında ve yakın kuşakta değil | %0 |
| Görünür sınırın dışındaki 250 km yakın kuşakta | %50 |
| Görünür özellik alanının üzerinde | %100 |

Yakın kuşağın içindeki her geçerli nokta aynı yarım payı alır. Yüzde 63 veya yüzde 67 gibi sürekli saha puanları kullanılmaz.

Kara, su ve kıyı kuruluş uygunluğu, bonus miktarından ayrı bir kontroldür. Yakında bonus alınabilmesi her bina modelini oraya kurmaya izin vermez. Tam alan isteyen özel model kuruluşta tam koşulu arar.

### 6.3. City konumunun aktarılması

City konumundan gelen coğrafya ile district konumundan gelen coğrafya aynı çıktı yolunda birlikte değerlendirilir.

Tekilleştirme anahtarı coğrafya türü ve etkilenen çıktı ailesidir. Her anahtar için en güçlü geçerli katkı tutulur.

Örnek:

- City dağ yakınında Production +%10 alıyor.
- District başka bir dağın üzerinde Production +%20 alıyor.
- Geçerli toplam dağ katkısı +%20'dir.
- District krater yakınında ayrıca +%5 alıyorsa toplam coğrafya +%25 olur.

Districtin tabanı 10, uygun binanın tabanı 30 ise sonuç sırasıyla 12,5 ve 37,5'tir. Toplam 50 olur. Binaya +%25 ikinci kez uygulanmaz.

City'nin konumu alt üretimlerini etkiler; City bu nedenle ayrıca ikinci bir merkez kaynağı olmaz.

Energy districtinin ailesiz taban enerji katkısı, bulunduğu yerde en yüksek uygun toplamı veren enerji profilini bir kez kullanır. Wind, Solar, tidal ve termal binalar kendi çıktı etiketlerine uyan coğrafyayı alır.

### 6.4. Mineral erişimi coğrafya değildir

Her gövdenin mineral kümesi vardır. Uygun Production aracı tamamlandığında erişilebilir mineraller keşfedilir. Aynı mineral gövdenin her geçerli Production konumundan çıkarılabilir.

Dağa veya kratere kurulmak miktarı etkileyebilir. Mineralin türünü açmaz veya kapatmaz.

Maden yatağı, yerel mineral yoğunluğu, en zengin damar alanı veya asteroitten yeni kaynak toplama alt sistemi yoktur.

Ay'daki her geçerli Production konumu Moonstone çıkarabilir. İlk gerçek çıkarım görevi gerçek üretim olaylarını sayar; yalnız keşif veya satın alma yeterli değildir.

<a id="bolum-07"></a>

## 7. Mesafe, yakınlık ve uzaklık

### 7.1. Gerçek konum ve sade etiket

Yüzey mesafesi gövde yarıçapı ve iki gerçek konum arasındaki yüzey uzaklığından hesaplanır. Kamera uzaklığı, ekran pikseli ve gezegenin çizimde büyük görünmesi ekonomik mesafe değildir.

Dünya referans yarıçapı 6.000 km'dir. Boyutu 0,45 olan Ay'ın referans yarıçapı 2.700 km olur. Aynı aralıklarla Ay yüzeyine daha az yerleşim sığar.

Yüzey alanı 4 × π × yarıçap²'dir. Bu örnekte Ay yüzeyi Dünya yüzeyinin %20,25'idir. Kullanılabilir arazi, minimum aralık ve ebeveyn kapasitesi birlikte gerçek yer sınırını belirler.

### 7.2. District mesafe profili

| Etiket | Aynı gövdedeki district mesafesi | Uzaklık katkısı |
| --- | --- | ---: |
| Çok yakın | 0-500 km | %0 |
| Yakın | 500 km üstü, 1.000 km dahil | +%12,5 |
| Orta | 1.000 km üstü, 2.000 km dahil | +%25 |
| Uzak | 2.000 km üstü, 3.500 km altı | +%37,5 |
| Çok uzak | 3.500 km ve üzeri | +%50 |

Districtler arasında minimum 250 km vardır. City merkezleri arasında minimum 3.000 km vardır. Aynı gövdede districtin bir City'ye ait olması gerekir; dar bir City erişim yarıçapı uzak district kuruluşunu yasaklamaz.

### 7.3. Tip 1 City mesafe profili

City yakınlığı districtin 500/1.000 km profilini kullanmaz.

| Etiket | Aynı gövdedeki City'ler arası mesafe | Uzaklık katkısı |
| --- | --- | ---: |
| Çok yakın | 4.000 km ve altı | %0 |
| Yakın | 4.000 km üstü, 7.000 km dahil | +%12,5 |
| Orta | 7.000 km üstü, 10.000 km dahil | +%25 |
| Uzak | 10.000 km üstü, 14.000 km altı | +%37,5 |
| Çok uzak | 14.000 km ve üzeri | +%50 |

City mesafesi iki City'nin ekonomik yerleşim konumu arasında ölçülür. Her City'nin gezegen merkezine uzaklığını ölçmek yakınlık stratejisi oluşturmaz.

Yörüngesel merkez rolünün ekonomik City konumu aynı haritanın mesafe sözleşmesine dahil edilir. Kozmetik yörünge hareketi bu konumu değiştirmez.

Küçük bir gövdede bütün uzaklık bantlarına ulaşmak mümkün olmak zorunda değildir. Gövde boyutunun stratejik etkisi budur.

### 7.4. Güneş sistemi uzaklığı

Gezegenin yıldıza uzaklığı ışık kuşağını belirler. Gezegenler arası sistem uzaklığı ise makro konum özelliklerinin girdisidir.

Sistem uzaklığı AU ölçeğinde tutulur. Tip 0 kilometre değerleri AU diye yeniden adlandırılmaz.

Ekonomik hesaplarda kayıtlı ortalama yörünge konumu kullanılır. Kamera dönüşü, gezegen animasyonu ve çizimdeki yörünge açısı üretim bonuslarını periyodik değiştirmez.

Tip 1'de bu profil Production Planet veya Energy Planet türleri oluşturmaz. Gezegenin konumu uygun City ve district rollerini makro özellik yoluyla etkiler. Gezegen ailesi Tip 2'de oluşur.

### 7.5. Bütün uygun kaynakların tam katkısı

| Kaynağın uzaklığı | Aynı aile normal kaynak | Merkez kaynağı |
| --- | ---: | ---: |
| Çok yakın | +%10 | +%10 |
| Yakın | +%5 | +%5 |
| Daha uzak | %0 | %0 |

Her uygun kaynak tam katkısını verir. İkinci, üçüncü veya sonraki kaynak için sıra indirimi yoktur. Kaynak sayısında sert sınır, bonus tavanı veya gizli normalizasyon yoktur.

Uygunluk kuralları:

- Aynı ekonomik harita ve aynı katman kullanılır.
- Kendi kimliği kaynak sayılmaz.
- Aynı kaynak aynı ilişkiyle bir kez sayılır.
- İnşaat halindeki nesne bonus kaynağı değildir.
- Tamamlanmış fiziksel nesne duraklatılınca mesafeden kaybolmaz.
- Normal kaynak başlangıçta aynı aileyi destekler.
- Tip 1 districtlerinde normal aile Host A'dır.
- Başka aile ilişkisi yalnız açık skill veya özel modelle açılır.
- Merkez bütün uygun çıktı rollerini destekler.
- Başka City'ye ait uygun mesafedeki merkez de sayılır.
- Yol, yol kesişimi, yol kalınlığı ve aradaki nesne hesap sonucunu değiştirmez.

Capital ve üst eşlenikleri için yol istisnası yoktur.

### 7.6. Uzaklık kaynağı ve hesap

Uzaklık katkısı merkezler dahil en yakın diğer tamamlanmış aynı katman nesnesinden alınır. Capital'ın yanında duran district aynı anda bütün yerleşimlerden çok uzak sayılamaz.

Bir haritada başka tamamlanmış aynı katman nesnesi yoksa nesne bağımsız çok uzak kabul edilir. Otomatik merkez aynı katmandaysa bu merkez aramaya katılır.

Yakın kaynak katkısı kaynağın büyümüş üretiminden aktarılmaz. Alıcının uygun taban çıktısına sabit yüzde eklenir. Karşılıklı kaynaklar yeniden birbirinin son çıktısını büyüten sonsuz hesap döngüsü oluşturmaz.

Dört çok yakın aynı aile kaynağı +%40, bir çok yakın merkez +%10 verir. Toplam +%50'dir. Sekiz aynı aile kaynağı +%80 verir. Yirminci kaynak da birinciyle aynı tam payı taşır.

Tam kümeye ait N eşdeğer nesnenin her biri diğer N-1 nesnenin çok yakınında ise toplamın basit ifadesi:

    Toplam = N × tek nesne tabanı × [1 + 0,10 × (N - 1)]

Bu, büyüyen kümelerin daha güçlü olabileceğini açıkça gösterir. Yakın ve uzak her büyüklükte eşit sonuç vermek zorunda değildir.

Yoğunlaşmanın bedeli gerçek kuruluş, aynı model tekrar fiyatı, nüfus, enerji, kapasite ve fiziksel alandır. Uzak yerleşim daha az eşlikçi yatırımıyla kendi coğrafyasını kullanır.

### 7.7. Hesap ve performans

Gövde veya ekonomik harita başına uzamsal hücreler tutulur. Yalnız yarıçapla kesişen hücrelerden bütün uygun nesneler sorgulanır.

Kuruluş, yıkım, taşıma, aile değişimi, merkez değişimi ve ilişki skill'i değişimi etkilenen konumları günceller.

Üst görünümde görünmeyen districtler ekonomik hesaptan düşürülmez. İlk yirmi kaynağı saymak gibi sonuç değiştiren performans kestirmesi yapılmaz.

Toplam district sayısı gerçek district kimliklerinin toplamıdır. Toplam bina adedi gerçek bina yığınlarının toplamıdır. Hazır plan kartı ayrıca nesne veya üretim adedi sayılmaz.

<a id="bolum-08"></a>

## 8. Ekonomi zamanı, stoklar ve ödeme sırası

Bu bölüm hedef oyun kurallarını tanımlar. Tablolardaki sayılar uygulanacak ilk denge tabanıdır; oynanışta ölçülmüş sonuç veya tamamlanmış özellik iddiası taşımaz. Bir kuralın kesinliği ile bir sayının daha sonra dengelenebilir olması farklıdır. Global ekonomi, oyuncunun girdi seçimi, bina seviyesinin bulunmaması ve tek üretim kaydı temel kurallardır.

### 8.1. Ekonomik sayı türleri

| Sayı türü | Ne ifade eder? | Örnek | Zamanda davranışı |
| --- | --- | --- | --- |
| Stok | Biriktirilen ve ödenen miktar | 300 Ferrite, 40 Goods | Üretimle artar, ödemeyle azalır. |
| Kapasite | Aynı anda sağlanan imkân | 15.000 nüfus, 8 enerji | Etkin kaynak varken vardır; her tur yeniden birikmez. |
| Yük | Kapasiteye getirilen talep | 250 çalışan, 2 enerji ihtiyacı | İlgili kurulmuş varlığın kullanımını gösterir. |
| Süre | İşin tamamlanması için gereken ekonomi zamanı | 20 saniye üretim, 4 saniye inşaat | Stok veya kapasite değildir. |

Enerji bir pil cüzdanı değildir. Nüfus, zamanla doğan veya satın alınan insan stoğu değildir. Konut 2.500 kapasite sağladığında yirmi saniye sonra buna 2.500 daha eklenmez.

Krediler ve Science ortak cüzdandadır. Ham maddeler, Goods, Fuel ve Rare ortak depodadır. Bunları harcamak için Dünya ile Ay arasında yük gemisi, yerel ambar eşlemesi veya taşıma görevi aranmaz.

### 8.2. Ortak yirmi saniyelik çevrim

Stok üreten veya stok gideri ödeyen bütün ekonomik tariflerin ortak zaman birimi **20 ekonomi saniyesidir**.

| Gösterim | Aynı hızın karşılığı |
| --- | ---: |
| 1 çevrim | 20 saniye |
| 1 dakika | 3 çevrim |
| 4 Science / çevrim | 12 Science / dakika |
| 1/3 Goods / çevrim | 1 Goods / dakika |
| 2/3 Fuel / çevrim | 2 Fuel / dakika |
| 80 kredi / çevrim | 240 kredi / dakika |

İç hesap kesirleri korur. 1/3 Goods değeri veri tarafında 0,33'e indirilmez. Üç çevrimde tam 1 Goods ödenir; 0,99 ödeme ve küçük stok sızıntıları oluşmaz.

Bir çevrim biriminin başlangıcı, ilgili üreticinin tarife başlayabildiği andır. İnşası çevrimin ortasında biten yeni bina tamamlanma anından itibaren ilk yirmi saniyelik işini başlatabilir. Bu, ekranda farklı kalan süreler gösterilmesine izin verir; tariflerin zaman birimi yine aynıdır.

Hızlandırma veya offline ilerleme ekonomi zamanını ilerletir. Oyuncuya gösterilen saniye ve bütün iş süreleri aynı ekonomi saatinden okunur. Ayrı gelir sayacının gerçek zaman, diğerinin hızlandırılmış zaman kullanması yasaktır.

### 8.3. İnşaat ve üretim ayrımı

| İş | Süre tabanı | Sonuç |
| --- | ---: | --- |
| Küçük model inşası | 2 saniye | Bina kurulur; ilk üretim ayrıca başlar. |
| Standart bina inşası | 4 saniye | Bina kurulur; ilk üretim ayrıca başlar. |
| Tip 0 normal district kuruluşu | 4 saniye | District tabanı ve mevcut seviye etkinleşir. |
| City kuruluşu | 4 saniye | City kapasitesi, tabanları ve merkezi etkinleşir. |
| District yükseltmesi | 5 × hedef seviye saniye | Tamamlanınca yeni yuva ve yeni seviye çıktısı açılır. |
| City yükseltmesi | 10 × hedef seviye saniye | Tamamlanınca yeni çocuk kapasitesi açılır. |
| Lunar Spaceport | 30 saniye | Özel sefer tesisi etkinleşir. |
| Roket hazırlama ve uçuş | Seferin kendi tarifi | Bina üretimi gibi tekrar eden gelir sayılmaz. |

Bir inşaat çubuğu ile bir üretim çubuğu aynı kayıt değildir. Spaceport boş dururken her 45 saniyede hayalî bir üretim tamamlamaz. Depoların da görünür bir stok üretim çubuğuna ihtiyacı yoktur.

### 8.4. Çevrim başlangıcındaki işlem sırası

Aşağıdaki liste tek bir üretim çevriminin yaşamını anlatır. Birçok iş aynı anda vadesine ulaştığında küresel olay sırası şöyledir: biten işler ve üretimler; stok teslimi ve izinli taşma; rezerv üstü satış; otomatik alış; yeni tariflerin ödemesi; etkin kapasite ve açık hesabı; yeni vaat edilmiş çıktılar. Önceki turun teslimi, sonraki turun girdisi değerlendirilmeden önce işlenir. Online ve offline aynı sırayı kullanır.

1. O anda bitmiş inşaat, taşıma ve yükseltme olaylarını tek işlem olarak uygula.
2. Geçerli model, çalışan adet, seçili ham girdi ve oyuncu önceliklerini oku.
3. Aynı stok birden fazla tarife söz veremesin diye girdi ve bakım bütçelerini rezerve et.
4. Bir birimin bütün girdileri karşılanıyorsa onları bir kez öde ve o birimi başlat.
5. Ödenemeyen birimi beklet; başka hammaddesine sessizce geçme.
6. Bakımı ödenmiş enerji ve konut sağlayıcılarının dönemlik etkin kapasitesini belirle.
7. Global nüfus yükünü, etkin nüfus kapasitesini, enerji arzını ve enerji talebini hesapla.
8. Stok üreticisinin bu dönemdeki verim oranını ve vaat edilen çıktısını kaydet.
9. Yirmi ekonomi saniyesi sonra bu vaat edilen çıktıyı yalnız bir kez ortak stoğa ekle.
10. Eklenen malzeme için kapasite ve yeni taşan üretim kuralını uygula.
11. Sonraki çevrimde yeni seçimi ve yeni global durumu kullan.

Çevrimde active_units, paid_inputs ve period_paid_until değerleri ayrı tutulur. Üç kapasite biriminden yalnız ikisinin bakımı ödenmişse ikisi etkin, biri bekleyendir; tüm grup için tek bir evet/hayır bayrağı kullanılmaz.

Ödeme sırasında henüz üretilmemiş çıktı harcanamaz. Örneğin büyük Goods üreticisi bir sonraki çevrimde vereceği Goods'u şimdiki bakım borcunun karşılığı sayamaz.

İlk başlatma için temel Goods Factory veya erişimi açılmış trade küçük bakım stoğunu sağlayabilir. Bakımsız temel üretici, büyük sürüm açıldığı için katalogdan çıkarılmaz.

### 8.5. Ödeme garantisi ve çevrim kaydı

Bir ücretli çevrim, model kimliğini, çalışan birim sayısını, seçili ham kimliğini, ödenmiş girdi miktarlarını, başlayış anını, bitiş anını ve vaat edilen çıktılarını taşır.

Oyuncu Ferrite yerine Moonstone seçtiğinde değişiklik bir sonraki çevrimde uygulanır. Devam eden Ferrite çevriminin ödemesi Ferrite, çıktısı da o seçimin sonucu olarak kalır.

Aynı ücretli çevrim kaydı, ekran değiştirildiğinde veya kayıt yeniden açıldığında ikinci kez ödeme yapmaz. Tamamlanmış çıktı yeniden verilmez. Gerçek üretim sayacı da aynı olayı ikinci kez saymaz. Offline tamamlanan kredi ve Science teslimi, kapanışta başlamış tur olsa bile kalan offline kazanç bütçesiyle sınırlıdır. Bütçe dışında kalan finansal çıktı sonraya borç yazılmaz; yeni maliyetli offline turlar ise hak ayırmadan başlatılmaz. Malzeme teslimi kendi depo/taşma kuralını kullanır.

Yıkım veya taşıma gibi özel işlemlerin devam eden çevrimle ilişkisi ilgili işlem kurallarına göre yürütülür. Ortak ekonomi sözleşmesi her durumda tek ödeme ve en fazla tek çıktı gerektirir.

### 8.6. Kısmen çalışabilen adet grupları

| Model grubu | Eldeki seçili girdi | Birim başına ihtiyaç | Başlayabilen | Bekleyen |
| --- | ---: | ---: | ---: | ---: |
| 3 Goods Factory | 8 Ferrite | 4 Ferrite | 2 | 1 |
| 3 Goods Factory | 11 Ferrite | 4 Ferrite | 2 | 1 |
| 3 Goods Factory | 12 Ferrite | 4 Ferrite | 3 | 0 |
| 2 Fuel atölyesi | 8 Ferrite | 8 Ferrite | 1 | 1 |
| 1 Rare Forge | 8 Ferrite +4 Moonstone | Tek türden 12 ham | 0 | 1 |

Son satırda farklı mineral parçaları birleştirilmez. Açıkça çok girdili bir tarif bulunmadıkça oyuncu tek bir çalışma birimine iki mineral karışımı atayamaz.

Aynı öncelikteki gruplar adil dönüşümlü başlatılır. Sürekli ilk sıradaki kartı besleyip alt kartları sonsuza dek aç bırakmak öngörülen otomasyon değildir. Oyuncunun verdiği öncelik ise bu sıranın önündedir.

### 8.7. Tek model kartı ve girdi alt satırları

Aynı districtte aynı ekonomik model tek kartta toplanır. Farklı ham seçimi ayrı bir bina türü, yeni fiyat ailesi veya ikinci simülasyon kaydı yaratmaz.

| Aynı kartın alt grubu | Adet | Çevrim girdisi | Bonus öncesi brüt çıktı |
| --- | ---: | --- | ---: |
| Ferrite seçilmiş Goods Factory | 3 | 12 Ferrite | 6 Goods |
| Moonstone seçilmiş Goods Factory | 2 | 8 Moonstone | 7 Goods |
| Kart toplamı | 5 | İki girdili özet | 13 Goods |

Kart toplamı yeni gelir değildir. Alt satırların hesaplanan toplamıdır. Beş birim de aynı modelin aynı district içindeki tekrar fiyatı sayacına dahildir.

Kart; kurulu adet, bu çevrim çalışan adet, bekleyen adet, seçilmiş mineral, tam gider, gerçek çıktı ve bekleme nedenini gösterir. Kapasite modeli ise stok çıktısı gibi sunulmaz.

### 8.8. Depo tabanları

| Kaynak | Başlangıç depo tavanı |
| --- | ---: |
| Açılmış her ham türü | Tür başına 500 |
| Goods | 200 |
| Fuel | 200 |
| Rare | 100 |
| Kredi | Normal cüzdan tavanı yok |
| Science | Normal cüzdan tavanı yok |
| Enerji | Stok tavanı yok; etkin arz/talep |
| Nüfus | Stok tavanı yok; etkin kapasite/yük |

Ferrite ile Moonstone'un ayrı tavanı vardır. Ferrite'in 500 olması Moonstone'a kalan ortak 500 miktarı azaltmaz.

Henüz erişilmemiş mineral için kapasite artışı mineral keşfi sayılmaz. Bir Warehouse kurulması bütün mineral adlarını, simgelerini ve fiyatlarını açmaz.

### 8.9. Kapasite ekleyen yapılar

| Yapı | Ham kapasitesi | Goods | Fuel | Rare |
| --- | ---: | ---: | ---: | ---: |
| Warehouse | Açılmış tür başına +1.000 | +150 | +150 | +75 |
| Logistics Center | Warehouse ile aynı | +150 | +150 | +75 |
| Yakıt Deposu | 0 | 0 | +300 | 0 |
| Yörünge Yakıt Tankı | 0 | 0 | +1.200 | 0 |

Bu değerler doğrudan kapasite katkısıdır. District çıktısı veya mineral nadirliği depo hacmini kendiliğinden büyütmez. Ayrı bir depo kapasitesi skill'i varsa yalnız onun açık etkisi uygulanır.

Bir Warehouse ile ham tavanı 1.500, Goods 350, Fuel 350, Rare 175 olur. İkinci Warehouse ile ham tavanı 2.500, Goods 500, Fuel 500, Rare 250 olur.

### 8.10. Yeni taşan üretim ve eski stok ayrımı

Trade erişimi yokken tavanı aşan **yeni üretim** kaybolur. Trade erişimi açılınca yeni taşan üretim satılabilir kaynak için geçerli satış fiyatıyla krediye dönüşür.

Depo sökülmesi yüzünden mevcut stok tavanın üstüne çıkarsa önceden biriktirilmiş malzeme silinmez. Bu eski fazlalık geriye dönük otomatik satışa zorlanmaz. Arayüz örneğin 1.200 /500 Moonstone gösterebilir.

| Olay | Önce | Yeni tavan | Sonuç |
| --- | --- | ---: | --- |
| Depo söküldü | 1.200 Moonstone | 500 | 1.200 korunur; kapasite üstünde uyarısı. |
| Üstteki duruma +100 yeni üretim | 1.200 Moonstone | 500 | Yeni 100'ün tamamı taşandır. |
| Tavan 500, stok 490, yeni üretim 30 | 490 Moonstone | 500 | 10 depoya, 20 taşan kurala gider. |
| Tavan 500, stok 200, yeni üretim 30 | 200 Moonstone | 500 | 30 depoya girer. |

Depo dolu diye ücretli üreticiyi otomatik ve sessizce durdurmak taşan satış stratejisini bozar. Oyuncunun açık durdurma/rezerv tercihi yoksa üretim çalışabilir; yeni fazlalık tek akışta kayıp veya satışa gider.

Manuel trade, otomatik trade ve offline hesap aynı stoğu ve aynı taşan çıktı olayını kullanır. Üç ayrı gelir yolu aynı üretilen birimi üç kez satamaz.

### 8.11. Arayüzde aynı zaman penceresi

Bir kartta bütün stok üretim ve giderler aynı **20 saniye** başlığı altında gösterilir.

| İyi gösterim | Açıklama |
| --- | --- |
| +6 Fuel /20 sn; -24 Ferrite, -1/3 Goods /20 sn | Karşılaştırılabilir brüt üretim ve tam gider. |
| +27 enerji kapasitesi; -2/3 Fuel /20 sn | Kapasite ile dönemlik bakım ayrılmıştır. |
| +10.000 nüfus kapasitesi; -2/3 Goods /20 sn | Konut birikmiyor, etkin kaldığı sürece vardır. |
| +1.200 Fuel depo kapasitesi | Hayalî Fuel üretimi değildir. |

Dakika görünümü seçilirse kartın bütün stok satırları birlikte üçle çarpılır. Çıktıyı yirmi saniye, gideri dakika üzerinden küçük gösterme yapılmaz.

### 8.12. Veri ve hedef uygulama haritası

| Kaynak noktası | Hedef uygulama işi |
| --- | --- |
| C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd:218, 254, 276, 283 | Birim bazlı ön ödeme ve sabit yirmi saniyelik vaat edilmiş çıktı sözleşmesi. |
| C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd:317 | District tabanlarının stok saati de yirmi saniyeye bağlanacak. |
| C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd:486 | Dolu depo nedeniyle üretimi bütünüyle kesmek yerine yeni taşan üretim kuralı uygulanacak. |
| C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd:554, 581 | Ödeme ve tamamlama aynı çevrim kaydına bağlanacak. |
| C:/Users/drosm/Voidle/scripts/game/Economy.gd:113 | Global depo tabanları ve bütün kapasite kaynakları tek hesapta toplanacak. |
| C:/Users/drosm/Voidle/scripts/game/GameState.gd | Yeni oyun cüzdanı 3.000 kredi, 450 Science, sıfır malzeme olacak. |

Bu harita dosyaların hedef davranışı zaten uyguladığı anlamına gelmez. Hedef ile uygulama farklarını iş listesine dönüştürür.

<a id="bolum-09"></a>

## 9. Global nüfus, enerji ve açıklar

### 9.1. Tek imparatorluk havuzu

Dünya, Ay ve daha sonraki yerleşimler nüfus ve enerjiyi aynı havuza katar. Yerel panel, o yerin toplam sisteme katkısını ve yükünü açıklar; ikinci bir yerel çalıştırma kilidi oluşturmaz.

| Ölçü | Formül |
| --- | --- |
| Nüfus kapasitesi P | Bütün etkin City ve konut kapasitesi katkılarının toplamı |
| Kullanılan nüfus U | Bütün kurulmuş ve rezerve altyapı/çalışan yüklerinin toplamı |
| Boş kapasite B | en fazla(0, P - U) |
| Enerji arzı A | Bütün etkin enerji katkılarının toplamı |
| Enerji talebi D | Çalışan kapasite ve üreticilerin enerji ihtiyaçlarının toplamı |
| Net enerji | A - D |

Kullanılan nüfus kapasitenin üstüne çıkabilir. Bu durum stok üretimini azaltır; yeni konut kurmayı veya sistemi toparlamayı yasaklayan bir sert kilit değildir.

### 9.2. Kuruluş yükleri

| Varlık | İlk nüfus kapasitesi | Kuruluş yükü | Açıklama |
| --- | ---: | ---: | --- |
| Tip 0 City | 15.000 | 2.000 | Otomatik Capital kuruluşu bu yükün içinde. |
| Production District | 0 | 500 | Tekrar adedine göre yük artmaz. |
| Science District | 0 | 500 | City katkısından ayrı altyapı yükü. |
| Energy District | 0 | 500 | Üretici enerji kapasitesi ayrıca hesaplanır. |
| Commercial District | 0 | 500 | Kredi tabanı ayrıca hesaplanır. |
| Residential District | 1.500 taban | 0 | Konut ekleyerek çıkış yolu açık kalır. |
| Otomatik Capital | City'nin tabanıyla ilişkili | Ek kuruluş yükü 0 | İkinci kez 2.000 veya500 alınmaz. |

City tabanı kapasitedir, gerçekten doğmuş insan sayısı değildir. Her City'nin 15.000 tabanı boş nüfus stratejilerine dahil edilir.

### 9.3. Bina çalışanları

| Profil | Standart çalışan | Açıklama |
| --- | ---: | --- |
| Küçük Tier 1 | 125 | Normal T1'in yarısı |
| Normal Tier 1 | 250 | Temel işçi tabanı |
| Büyük Tier 1 | Karttaki açık değer | Bazaar ve Yerel Ticaret Merkezi 625 |
| Tier 2 | 750 | Normal T1'in üç katı |
| Tier 3 | 2.250 | Normal T1'in dokuz katı |
| Bütün konut modelleri | 0 | Konut kendi kapasitesini çalışan borcuna çevirmez |
| Özel sefer tesisi | Karttaki açık değer | Dünya Spaceport 250; Lunar Spaceport 750 |

Bir Tier 2 modelin kataloğunda 750 yazıyorsa yeniden üçle çarpılmaz. Bu kural enerji, maliyet ve üretim tabanlarında da geçerlidir.

Nüfus yükü kurulumla rezerve edilir. İnşaattaki bina ve başlatılmış yükseltmenin ek yükü bu rezervde yer alır; henüz bitmemiş kapasite ise sağlanmış sayılmaz.

Elle durdurulmuş veya girdisi bekleyen kurulmuş bina, çalışan rezervini korur. Durdurmak yeni boş nüfus geliri yaratmaz. Yük, ilgili varlığın gerçekten kaldırılması veya uygun işlemle başka yere taşınmasıyla değişir.

### 9.4. Kapasite giderinin ödenememesi

Giderli bir konutun Goods bakımı ödenemediyse o dönem konut katkısı etkin değildir. Benzer şekilde Fuel bakımı ödenmemiş reaktör o dönem enerji arzı sağlamaz.

Bu, nüfus/enerji veriminin kapasiteye uygulanması değildir. Önce kapasite sağlayıcısının ücretli dönemi açılır, sonra sağlanan kapasite hesaplanır.

Bakımsız konut, City tabanı ve bakımsız enerji kaynakları, başka üreticilerin girdisi bulunmadığı için kendiliğinden kapanmaz.

### 9.5. Nüfus açığı formülü

Karşılama oranı, ihtiyaç sıfırsa1; diğer durumda kapasite/ihtiyaç değerinin 0 ile1 arasında sınırlanmış halidir.

**Nüfus verimi = 0,5 +0,5 × nüfus karşılama oranı.**

| Kapasite | Kullanılan | Karşılama | Stok çıktı verimi |
| ---: | ---: | ---: | ---: |
| 30.000 | 20.000 | %100 | %100 |
| 30.000 | 30.000 | %100 | %100 |
| 30.000 | 40.000 | %75 | %87,5 |
| 30.000 | 60.000 | %50 | %75 |
| 0 | 30.000 | %0 | %50 |
| 0 | 0 | %100 | %100 |

Nüfus açığı bütün imparatorluktaki stok üreticilerine uygulanır. Dünya'da konut kurmak Ay üretiminin nüfus açığını da düzeltebilir.

### 9.6. Enerji açığı ve birleşik etki

**Enerji verimi = 0,5 +0,5 × enerji karşılama oranı.**

Enerji cezası yalnız enerji isteyen stok üreticilerini azaltır. Enerji sağlaması veya konut kapasitesinin kendisi aynı cezayla tekrar küçülmez.

| Nüfus verimi | Enerji verimi | İkisini isteyen stok üreticisinin çıktısı |
| ---: | ---: | ---: |
| %100 | %100 | %100 |
| %87,5 | %100 | %87,5 |
| %100 | %75 | %75 |
| %75 | %75 | %56,25 |
| %50 | %50 | %25 |

20 saniyelik süre değişmez. Tarifin tam girdisi ve tam bakım gideri ödenir; çıkan stok miktarı düşer. Düşük çıktı ile aynı anda uzamış çevrim uygulamak ikinci ceza olur ve bu modelin parçası değildir.

Örneğin 4 Ferrite ödeyen Goods Factory normalde2 Goods, iki %75 açıkta1,125 Goods verir. Girdi4 Ferrite olarak kalır.

### 9.7. Boş kapasitenin strateji geliri

| Araştırma | 1.000 boş kapasitenin dakika karşılığı | 20 saniye formülü |
| --- | ---: | --- |
| Sivil Girişimler | +10 kredi | Boş kapasite /300 kredi |
| Serbest Araştırma | +2 Science | Boş kapasite /1.500 Science |
| Üretim Rezervi | Boş oranına bağlı malzeme bonusu | +0,20 × B/P; P=0 ise0 |

Bütün boş kapasite uygundur. City'nin bedelsiz kapasitesi için ayrı gelir dışlama etiketi yoktur.

Doğrudan boş nüfus geliri, zaten coğrafyadan ve desteklerden etkilenmiş toplam kapasite üzerinden hesaplanır. Aynı gelir satırına konut coğrafyası veya konut verimi ikinci kez eklenmez.

Üretim Rezervi ham ve işlenmiş stoklara uygulanır. Konut, enerji, kredi, Science ve kendi boş kapasitesini artıran ikinci bir konut hesabı üretmez.

### 9.8. Başlangıç City örneği

| Adım | Kapasite | Yük | Boş |
| --- | ---: | ---: | ---: |
| Tamamlanmış ilk City | 15.000 | 2.000 | 13.000 |
| Bir Production District ekle | 15.000 | 2.500 | 12.500 |
| Bir Mine ekle | 15.000 | 2.750 | 12.250 |
| Bir Habitat Block ekle | 17.500 | 2.750 | 14.750 |

Son satırda konutun geçerli bir Residential District içinde olduğu varsayılır; Residential kuruluş yükü0'dır. Konutun enerji talebi ayrıca global enerji hesabına eklenir.

İlk City yalnız başınayken Sivil Girişimler ve Serbest Araştırma satın alınmışsa dakikada130 kredi ve26 Science boş kapasiteden gelir. City'nin60 kredi ve4 Science tabanıyla toplam190 kredi ve30 Science olur.

Bu örnek ekonomik hız ölçümü değildir. Sayıların birbirine nasıl bağlandığını gösterir. Gerçek toplam, inşaatlar ve çalışan yükleri arttıkça değişir.

### 9.9. Kaynak ve hedef uygulama haritası

| Kaynak noktası | Hedef uygulama işi |
| --- | --- |
| C:/Users/drosm/Voidle/scripts/game/Economy.gd:205 | City15.000 kapasitesi korunur; bütün yerleşimler global toplanır. |
| C:/Users/drosm/Voidle/scripts/game/Economy.gd:208, 219 | Eski district3.000 ve kuruluş sırası yükü yerine sabit500 hedefi. |
| C:/Users/drosm/Voidle/scripts/game/Economy.gd:281 | District yükseltme yükü500 ×1,25 üzeri kuralına taşınır. |
| C:/Users/drosm/Voidle/scripts/game/Economy.gd:286, 309 | Global etkin kapasite ve rezerve yük ayrılır. |
| C:/Users/drosm/Voidle/scripts/game/BuildingDef.gd:55 | T2/T3 çalışan varsayılanları750/2.250 yapılır; özel profiller açık kalır. |
| C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd:743, 771 | Enerji global kaynak olarak kalır; çıktı cezası sabit çevrime bağlanır. |
| C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd:276, 283 | Çevrim yavaşlatma ile çıktı azaltma aynı anda kullanılmaz. |

<a id="bolum-10"></a>

## 10. Sabit kaynak kataloğu ve işleme seçimi

### 10.1. Ekonomi envanteri

Oyun 12 ham kaynak ve3 işlenmiş kaynak kullanır. Kredi ve Science para/araştırma cüzdanıdır; enerji ve nüfus kapasite sistemidir.

Aynı mineralin ayrıca Ore, Ingot, Alloy, Component ve Core basamakları oluşturulmaz. Food, Gas veya Exotic gibi yeni ekonomik stoklar bu sözleşmeye eklenmez.

Ham kaynakta bina level'ına benzeyen kaynak seviyesi yoktur. Hamın nadirlik sırası ve o hammaddenin açıldığı medeniyet vardır.

### 10.1A. Küresel kaynakların canonical kimlikleri

| Sabit kimlik | Ad | Sayı türü |
| --- | --- | --- |
| credits | Kredi | Online tavansız stok |
| science | Science | Online tavansız stok |
| goods | Consumer Goods | Depo sınırlı işlenmiş stok |
| fuel | Fuel Rods | Depo sınırlı işlenmiş stok |
| rare_elements | Rare Elements | Depo sınırlı işlenmiş stok |
| energy | Enerji | Sürekli global arz/talep; stok cüzdanı değil |
| population | Nüfus | Global kapasite/yük; büyüyen insan stoğu değil |

Raw, ayrı harcanabilir bir kaynak kimliği değildir. Tarif şemasında seçilmiş ham anlamında bir yer tutucu kullanılabilir; ödeme veya teslim anında gerçek ferrite, moonstone gibi keşfedilmiş kaynak kimliğine çözülür. Canonical kaynak kimliği görünen Türkçe veya İngilizce addan türetilmez.
### 10.2. On iki ham kaynak

| Sıra | Sabit kimlik | Ad | İlk medeniyet | İşleme verimi | Tematik erişim ailesi |
| ---: | --- | --- | ---: | ---: | --- |
| 1 | ferrite | Ferrite | 0 | ×1 | Başlangıç kayalık/karasal gövde |
| 2 | moonstone | Moonstone | 0 | ×1,75 | Ay |
| 3 | cinderite | Cinderite | 1 | ×2,50 | Volkanik gövde |
| 4 | cryolite | Cryolite | 1 | ×3,25 | Buzlu gövde |
| 5 | dune_quartz | Dune Quartz | 2 | ×4 | Çöl ve kurak bölge ailesi |
| 6 | helion | Helion | 2 | ×4,75 | Gaz bakımından zengin gövde ailesi |
| 7 | astralite | Astralite | 3 | ×5,50 | Kristal bakımından zengin sistem |
| 8 | aurorium | Aurorium | 3 | ×6,25 | Metal bakımından zengin sistem |
| 9 | xenite | Xenite | 4 | ×7 | Sıra dışı madde bölgeleri |
| 10 | nyxium | Nyxium | 4 | ×7,75 | Karanlık bölgeler |
| 11 | quantium | Quantium | 5 | ×8,50 | Anomali bölgeleri |
| 12 | singularite | Singularite | 5 | ×9,25 | Yoğun kara delik/anomali bölgeleri |

Tematik aile bir yerel yatak haritası değildir. Bu adlar fiziksel bilimde doğrulanmış maden iddiası taşımaz; oyunun erişim ve görünüm sınıflarıdır.

Yeni medeniyete geçmek daha önce açılmış hammaddeleri kapatmaz. Tip1'de Ferrite ve Moonstone stokları, tarif seçimleri ve ödeme kayıtları korunur.

### 10.3. Nadirlik formülü

**İşleme verimi = 1 +0,75 ×(nadirlik sırası -1).**

| Sıra hesabı | Sonuç |
| --- | ---: |
| R1:1 +0,75 ×0 | 1 |
| R2:1 +0,75 ×1 | 1,75 |
| R3:1 +0,75 ×2 | 2,50 |
| R12:1 +0,75 ×11 | 9,25 |

Bu katsayı yalnız işlenmiş ürün çıktısına uygulanır. Mine'ın ham çıktısı, depo hacmi, enerji kapasitesi, konut, Science ve isimli kuruluş faturası nadirlikle büyümez.

Moonstone seçmek4 Moonstone bedelini2,286 birime indirmez. Girdi yine4'tür; normal Goods çıktısı2 yerine3,5 olur.

### 10.4. Kaynak keşfi ve kalıcı erişim

Bir hammaddenin erişimi için ilgili medeniyete ulaşılması ve o gövdede gerçek çıkarım yeteneği bulunan uygun varlığın tamamlanması gerekir. Tip0'da bu, çıkarım yapan Production District veya uygun Mine olabilir. Üst ölçekte ev sahibi City'nin adı tek başına şart değildir: Science City içindeki gerçek Production rolüyle çalışan Mine da keşif açabilir. Salt yan ürün olarak verilen küçük ham katkısı keşif açmaz ve yerel çıkarım görevine yazılmaz.

Kaynak erişimi açılmadan adı, simgesi, stok kartı, trade fiyatı ve isimli ödeme satırı kullanıcıya sızdırılmaz. Görsel yüzey veya kilitli gelecek silueti görülebilir.

Keşif kalıcıdır. Son üretici kaldırıldığında mineral yeniden gizlenmez, eldeki stok silinmez ve oyuncunun seçtiği tarif unutulmaz. Yerel çıkarım ise üretici çalışmadığı sürece ilerlemez.

Bir şeyi satın almak o gövdede gerçekten çıkarmış sayılmaz. Yerel100 Moonstone görevi, gerçek üretim olaylarıyla artan ayrı bir toplamdır.

### 10.5. Mineral gövde genelindedir

Production District veya Mine, o gövdede bulunan ve erişilebilir olan hammaddeden çıkarım yapar. Yüzeyde gizli yoğunluk örneği, zengin yatak zorunluluğu veya konuma göre mineral payı bölüşümü yoktur.

Dağ ve krater gibi coğrafya üretim miktarını artırabilir. Coğrafya görünmeyen bir mineral rezervinin miktarı veya tükenme sayacı değildir.

Gelişmiş Ekskavatör'ün kimliğinde vein sözcüğü bulunması bir yatak şartı yaratmaz. Oyuncuya gösterilen adı Gelişmiş Ekskavatör'dür.

### 10.5a. Gövde ham çıkarım katsayısı

Ham çıkarım miktarı, gövdenin aşağıdaki açık katsayısını bir kez alır. Bu katsayı mineral nadirliği değildir; aynı taban üreticinin farklı gövdelerdeki ham verimini tanımlar.

| Gövde türü | Ham çıkarım katsayısı | Yorum |
| --- | ---: | --- |
| Terran | ×1 | Tarafsız referans |
| Arid | ×1 | Hız cezası ayrıca eklenmez |
| Ice | ×1,20 | Gövde ham verimi |
| Volcanic | ×1,75 | Gövde ham verimi |
| Barren | ×1 | İnşaat indirimi kendiliğinden açılmaz |
| Gas Giant | ×0 | Yüzey Mine çıkarımı yapılamaz |
| Moon | ×1,30 | Ay ham çıkarım verimi |
| Asteroid | ×1,75 | Gövde ham verimi |

Districtin gerçek çıkarım tabanı ve gerçek Mine ailesi bu katsayıyı alır. İşleme binasında seçilen girdinin nadirlik bonusuna ayrıca gövde ham katsayısı eklenmez. Dünya'da Moonstone işlemek3,5 Goods verirken Ay'da aynı temel tarifin brüt çıktısı da3,5 Goods'dur; üretim konumunun açık diğer bonusları ayrıca uygulanabilir.

Ay'da10 ham katalog tabanı13 gerçek ham /20 sn olur. Karşılaştırma veya üst ölçek paket tabloları gövde×1 referansıyla yazıldığında bu varsayım açıkça belirtilir.

Veride bulunabilen madencilik hızı, ekstra yuva, district kotası, enerji tüketimi veya kuruluş indirimi pasifleri bu ham katsayısıyla birlikte otomatik etkinleştirilmez. Hız modeli sabit çevrimdir. Isı, soğuk, güneş ve rüzgârın ek etkileri görünür coğrafya/özel model sözleşmesiyle tanımlanır.

### 10.6. İlk üreticiyi kilitlememe

| İlk kurulum | Kuruluş bedeli | Henüz açılmamış kendi hammaddesi |
| --- | --- | --- |
| Dünya ilk Production District | 300 kredi | Ferrite istemez |
| Ay ilk Production District | 300 kredi +30 Ferrite | Moonstone istemez |
| Genel Mine | 200 kredi | Henüz keşfedilecek yerel hammaddesini istemez |
| Temel Goods Factory | 300 kredi | Kuruluşta işlenmiş ürün istemez |
| Kompakt Yakıt Atölyesi | 450 kredi | Kuruluşta Fuel istemez |
| Rare Forge | 600 kredi | Kuruluşta Rare istemez |

Bu istisnalar ilerlemeyi başlatan modellerin kendi çıktılarının arkasına kilitlenmesini önler. Daha büyük modellerin Goods, Fuel veya Rare istemesi temel üreticinin erişimini kapatmaz.

### 10.7. Üç temel tarif

| Ürün | Sabit kimlik | Seçili ham girdisi /20 sn | Brüt taban çıktı /20 sn | Ferrite ile bir ürünün ham bedeli |
| --- | --- | ---: | ---: | ---: |
| Goods | goods | 4 | 2 | 2 |
| Fuel | fuel | 8 | 2 | 4 |
| Rare | rare_elements | 12 | 1 | 12 |

Fuel, aynı ürün adedi için Goods'un iki katı ham ister. Rare daha yoğun ham kullanır. Tarif farkı kredi fiyatından bağımsız gerçek üretim maliyetidir.

Bu tabloda bakım gideri bulunmayan temel modeller karşılaştırılır. Büyük modelin Goods bakımı ayrıca ödenir ve çıktıdan gizlice silinmiş satır olarak saklanmaz.

### 10.8. Bütün hamlarla temel tarif sonuçları

| Seçili ham | Goods:4 hamdan | Fuel:8 hamdan | Rare:12 hamdan |
| --- | ---: | ---: | ---: |
| Ferrite | 2 | 2 | 1 |
| Moonstone | 3,5 | 3,5 | 1,75 |
| Cinderite | 5 | 5 | 2,5 |
| Cryolite | 6,5 | 6,5 | 3,25 |
| Dune Quartz | 8 | 8 | 4 |
| Helion | 9,5 | 9,5 | 4,75 |
| Astralite | 11 | 11 | 5,5 |
| Aurorium | 12,5 | 12,5 | 6,25 |
| Xenite | 14 | 14 | 7 |
| Nyxium | 15,5 | 15,5 | 7,75 |
| Quantium | 17 | 17 | 8,5 |
| Singularite | 18,5 | 18,5 | 9,25 |

Sonraki medeniyet hammaddelerinin bu tabloda bulunması erken erişim vermez. Tip0 oyuncusu yalnız erişimi açılmış Ferrite veya Moonstone seçebilir.

### 10.9. Büyük modelin tarifi

| Model | Tarif /20 sn | Ferrite brüt | Moonstone brüt |
| --- | --- | ---: | ---: |
| Goods Factory | 4 ham ->2 Goods | 2 Goods | 3,5 Goods |
| Cevher Ayıklama Atölyesi | 12 ham +1/3 Goods ->6 taban Goods | 6 Goods | 10,5 Goods |
| Kompakt Yakıt Atölyesi | 8 ham ->2 Fuel | 2 Fuel | 3,5 Fuel |
| Fuel Refinery | 24 ham +1/3 Goods ->6 taban Fuel | 6 Fuel | 10,5 Fuel |
| Rare Forge | 12 ham ->1 taban Rare | 1 Rare | 1,75 Rare |

Regolit Goods planı Cevher Ayıklama modelinin Ay kuruluşudur. 12 Moonstone ve1/3 Goods öder; normal koşulda10,5 brüt Goods verir. Sadece aynı ürünün muhasebe farkı olarak net10 ve1/6 Goods kalır.

Gider, tavan/taşma hesabından önce ödenir. Brüt ve net kavramları karıştırılmaz. Katalog brüt üretimi ve gideri ayrı satırlarda gösterir.

### 10.10. Oyuncu seçimi ve kullanılabilir girdi

Oyuncu işleme grubuna açılmış bir hammadde atar. Bir gövdede çıkarılmış mineral ortak stokta bulunduğu için başka gövdedeki fabrikada da işlenebilir.

Girdi seçimi o fabrikaya yerel maden varmış gibi gerçek çıkarım görevi kazandırmaz. Moonstone'u Dünya'da işlemek Ay'da100 Moonstone üretmiş olmanın yerine geçmez.

Seçili mineral yoksa grup bekler. Otomatik en nadir seçim, Ferrite bittiğinde Moonstone'a geçme veya oyuncunun pahalı stoklarını izinsiz harcama yoktur.

### 10.11. Araştırma kapıları

| Hak | Science tabanı | Ön koşul | Gezegen seviyesi şartı |
| --- | ---: | --- | --- |
| Temel İşleme | 0 | Başlangıç Production hakkı | Yok |
| Fuel İşleme | 450 | Temel İşleme | Yok |
| Yoğun Fuel | 350 | Fuel İşleme | Yok |
| Rare İşleme | 900 | Fuel İşleme | Yok |
| Rocketry | 600 | Fuel İşleme | Yok |
| Lunar Program | 1.200 | Rocketry | Yok |
| Ay Malzemeleri | 1.200 | Lunar Program +Ay Production tamamlanmış | Yok |

Fuel İşleme küçük Fuel üreticisini, Yoğun Fuel büyük Fuel Refinery modelini açar. Büyük model için ayrı yoğunluk tercihi vardır; Fuel erişimi için büyük model zorunlu değildir.

Rare Forge genel T1 profilindedir. Tier3 maddesi istediği için ilk Rare'ı üretemeyen bir kuruluş döngüsü yaratılmaz.

### 10.12. Kaynak ve hedef uygulama haritası

| Kaynak noktası | Hedef uygulama işi |
| --- | --- |
| C:/Users/drosm/Voidle/scripts/game/Economy.gd:43 | On iki sabit kimlik ve nadirlik sırası korunur; erişim medeniyet tablosuna bağlanır. |
| C:/Users/drosm/Voidle/scripts/game/Economy.gd:68 | Gövde kaynağı ve medeniyet erişimi birlikte değerlendirilir. |
| C:/Users/drosm/Voidle/scripts/game/Economy.gd:79 | 1 +0,75 ×(r-1) işleme verimi korunur. |
| C:/Users/drosm/Voidle/scripts/game/Economy.gd:182 | En nadir mineral seçen otomatik davranış oyuncu seçimiyle değiştirilir. |
| C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd:554 | Seçilmiş mineral kimliğiyle birim bazlı ödeme. |
| C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd:581 | İşlenmiş çıktı nadirliği yalnız bir kez alır. |
| C:/Users/drosm/Voidle/scripts/game/PlanetModifier.gd:40, C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd:653 | Açık gövde ham katsayıları korunur; kullanılmayan diğer pasif alanlar sessizce açılmaz. |
| C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd:608, 700 | Yoğunluğa göre ham bölüşümü kaldırılır; gövde genelinde seçilmiş çıkarım uygulanır. |
| C:/Users/drosm/Voidle/scripts/game/ResourceData.gd sabit kaynak adaptörü | Sabit kaynak adaptörü kullanılır; prosedürel ek ürün katmanları ekonomi listesine eklenmez. |

<a id="bolum-11"></a>

## 11. Kuruluş fiyatı, tekrar sayacı ve isimli malzeme

### 11.1. Aynı modelin yeni adedi

Bina kredi fiyatı = katalog kredi tabanı ×1,20 üzeri aynı districtteki mevcut aynı model adedi.

Sayaç tamamlanmış ve inşası başlamış adetleri içerir. İnşaat kuyruğunun aynı karede birden fazla ucuz teklif alması önlenir.

Farklı modelin kurulması bu modelin tekrar fiyatını artırmaz. Bir Mine kurmak Solar Array fiyatını artırmaz; ikinci Mine ise o districtteki ilk Mine'ı sayar.

| Aynı districtte alınan sıra | 150 tabanlı model | 300 tabanlı model | 900 tabanlı model |
| ---: | ---: | ---: | ---: |
| 1 | 150 | 300 | 900 |
| 2 | 180 | 360 | 1.080 |
| 3 | 216 | 432 | 1.296 |
| 4 | 259,20 | 518,40 | 1.555,20 |
| 5 | 311,04 | 622,08 | 1.866,24 |

Tablo indirimsiz kredi hesabıdır. Varsa açık skill indirimi son teklifte gösterilir ve gerçekten ödenen fatura ayrı kaydedilir.

### 11.2. Sayaç anahtarları

| Nesne | Sayaç anahtarı | Sayılmayan farklılık |
| --- | --- | --- |
| Bina | District kimliği +canonical model kimliği | Ham seçimi, kart alt grubu, ad, görünüm |
| Tip0 district | City kimliği +sabit district fiyat ailesi | Oyuncunun adı, coğrafi bonus, kuruluş planı etiketi |
| Tip0 City | Gövde kimliği +normal City kuruluş ailesi | İçerik baskınlığı veya oyuncunun verdiği isim |
| Üst ölçek yerleşimi | Ebeveyn kimliği +sabit kuruluş fiyat ailesi | Sonradan üretim rolü değişmesi |

Tip1'de City ailesi kilidi ve gerçek district türleri ayrı ölçek kataloğunda tanımlıdır. Bu bölümdeki generic Production ailesi, birbirinden farklı Tip1 district modellerini tek bir görünmez fiyat sayacına eritmek için kullanılmaz.

Bir districtin kendi tekrar aile kimliği kalıcıdır. Görünümü, planı veya adı değiştirilerek ilk adet fiyatı tekrar elde edilmez. Aileler arasında uyarlama işlemi varsa kayıt açık uyarlama kuralını taşır.

### 11.3. District ve City tekrar tabanları

| Kuruluş | Kredi formülü |
| --- | --- |
| Tip0 normal district | 300 ×1,50 üzeri aynı City'deki aynı fiyat ailesinin adedi |
| Gövdenin ilk normal City'si | 0 |
| Sonraki Tip0 City | 2.000 ×1,50 üzeri önceki normal City sayısının bir eksiği |
| Otomatik Capital | City kuruluşunun parçası; ayrı satın alma yok |

| Satın alma sırası | Aynı aile district | Aynı gövdede normal City |
| ---: | ---: | ---: |
| 1 | 300 | 0 |
| 2 | 450 | 2.000 |
| 3 | 675 | 3.000 |
| 4 | 1.012,50 | 4.500 |
| 5 | 1.518,75 | 6.750 |
| 6 | 2.278,125 | 10.125 |

City toplamında ücretsiz ilk kabuk gerçek bir kurulu City olarak sayılır. Ay'ın ilk City'si, Dünya'da kurulmuş City adedinden fiyat almaz; farklı gövdenin ilk City'sidir.

Yıkım mevcut adedi azaltır. Taşıma kaynak ve hedef sayacını tek işlemde günceller. Kredi iadesi, gerçek ödenmiş maliyet havuzu ve sömürü önlemleri ilgili işlem bölümünün ayrı sözleşmesidir.

### 11.4. Tier profilleri ve malzeme tabanları

| Profil | Standart miktar ilişkisi | Kuruluş malzemesi |
| --- | ---: | --- |
| Küçük T1 | Normal T1'in yarı ölçeği | Yok |
| Normal T1 | ×1 | Yok |
| Büyük T1 | Açık kart profili | Yok |
| Genel T2 | ×3 | 30 Ferrite +5 Goods |
| Genel T3 | ×9 | 90 Ferrite +15 Goods +5 Fuel +2 Rare |
| Özel Ay modeli | Karttaki açık profil | Özel liste; genel tier listesi eklenmez |
| Özel sefer tesisi | Kendi profili | Kendi listesi |

Tier bir bina seviyesi değildir. T1 Lab aynı modelin T2 seviyesine yükseltilmez. Lab ve Research Institute ayrı modeller olarak ayrı fiyat tabanı ve adet taşır.

Katalogdaki üretim, çalışan ve enerji değerleri zaten tier profilini içerir. Katalog12 Science dediğinde tekrar ×3 yapıp36 Science üretilmez.

### 11.5. Moonstone ekleyen Dünya modelleri

| Model | Genel malzeme | Ek Ay malzemesi | Toplam tek kuruluş malzemesi |
| --- | --- | --- | --- |
| Particle Accelerator | Genel T3 | 60 Moonstone | 90 Ferrite +60 Moonstone +15 Goods +5 Fuel +2 Rare |
| Luxury Spires | Genel T3 | 60 Moonstone | 90 Ferrite +60 Moonstone +15 Goods +5 Fuel +2 Rare |
| Commodity Exchange | Genel T3 | 90 Moonstone | 90 Ferrite +90 Moonstone +15 Goods +5 Fuel +2 Rare |
| Planetary Command | Genel T3 | 60 Moonstone | 90 Ferrite +60 Moonstone +15 Goods +5 Fuel +2 Rare |
| Fusion Reactor | Genel T3 | 0 | 90 Ferrite +15 Goods +5 Fuel +2 Rare |
| Mantle Cracker | Genel T3 | 0 | 90 Ferrite +15 Goods +5 Fuel +2 Rare |

Fusion ve Mantle Ay öncesi yoğunluk seçeneği olarak erişilebilir kalır. Moonstone istememeleri Fuel veya Rare araştırması gerektirmedikleri anlamına gelmez.

### 11.6. Özel Ay kuruluş tarifleri

| Plan/model | Kredi tabanı | Malzeme |
| --- | ---: | --- |
| Regolit Goods planı | 900 | 100 Moonstone +20 Goods |
| Modüler Ay Habitatı | 480 | 50 Moonstone +10 Goods |
| Ay Numune Laboratuvarı | 750 | 75 Moonstone +10 Goods +5 Rare |
| Ay İkmal Pazarı | 900 | 75 Moonstone +20 Goods +10 Fuel |
| Lunar Spaceport | 8.000 | 200 Moonstone +50 Goods +30 Fuel +10 Rare |

Bunlara ayrıca30 Ferrite +5 Goods eklenmez. Genel tier faturası yerine bu özel liste kullanılır. Generic Mine veya temel işleme modeli Ay'a konduğunda yalnız bulunduğu gövde yüzünden özel Moonstone bedeli almaz.

### 11.7. İsimli ödeme sözleşmesi

Bir fatura100 Ferrite diyorsa yalnız100 Ferrite öder. Oyuncunun Moonstone'u bol diye buna otomatik karşılık üretilemez.

Açık alternatifli kuruluş planı varsa her alternatif ayrı isimli listeyle gösterilir. Örneğin Cevher Ayıklama genel planı ile aynı modelin Regolit Ay planı ayrı tarif seçeneğidir; aynı ekonomik modeli kurarlar.

Tekrar katsayısı yalnız krediye uygulanır. İkinci genel T2 binanın isimli malzemesi36 Ferrite +6 Goods olmaz;30 Ferrite +5 Goods olarak kalır.

### 11.8. Kredi ve miktar hassasiyeti

Kredi teklifinde, tahsilatta, harcanan maliyet kaydında ve iade hesabına verilen tabanda aynı küçük para birimi kullanılır. Ekranda150 görünürken gizlice150,40 tahsil edilmez.

Önerilen ortak uygulama tabanı kredide iki ondalık basamaktır. Pozitif kuruluş ücretleri en yakın küçük para birimine yuvarlanır; tam yarımda yukarı yuvarlama kullanılır. Bir toplu alımın toplamı tek kez gösterilir ve tek kez tahsil edilir.

Ham ve işlenmiş stoklarda kesir korunur. 1/3 bakım ödemesi her çevrim ayrı ayrı0,33'e yuvarlanmaz. Kredi yuvarlaması ile malzeme hassasiyeti aynı şey değildir.

### 11.9. Alım teklifi ve eşzamanlılık

Teklif; model, ebeveyn, adet, geçerli tekrar sayacı, kuruluş tarifi, skill indirimi, yuva, yük ve toplam faturayı gösterir.

Oyuncu onaylarken sayaç veya stok değişmişse teklif yeniden doğrulanır. Geçersiz eski teklifle ucuz fiyat alınmaz; kullanıcının gördüğünden yüksek ücret sessizce tahsil edilmez.

Toplu alım bütün kurulabilir miktarı ve bütün toplamı açıklar. Yarım planın bütün bedelini tahsil edip gerisini daha sonra kendiliğinden tamamlama yoktur.

### 11.10. Kaynak ve hedef uygulama haritası

| Kaynak noktası | Hedef uygulama işi |
| --- | --- |
| C:/Users/drosm/Voidle/scripts/game/Economy.gd:193 | Bütün modelleri sayan1,35 büyüme yerine aynı canonical modelin1,20 büyümesi. |
| C:/Users/drosm/Voidle/scripts/game/DistrictDef.gd:136 | District300 tabanı korunur; aynı sabit aile1,50 sayacı kullanılır. |
| C:/Users/drosm/Voidle/scripts/game/DistrictDef.gd:138 | City2.500/2,50 yerine ücretsiz ilk ve2.000/1,50 dizisi. |
| C:/Users/drosm/Voidle/scripts/game/BuildingDef.gd:224 | Bina level yükseltme bedelleri yeni alım akışında kullanılmaz. |
| C:/Users/drosm/Voidle/scripts/game/PlanetProgress.gd:157 | Merkezi uygunluk, yuva, isimli fatura ve rezerv aynı satın alma işleminde doğrulanır. |
| C:/Users/drosm/Voidle/scripts/game/PlanetProgress.gd:207 | Bina seviye yükseltme yolu hedef katalogda çalıştırılmaz. |

### 11.11. Tip 1 City ailelerinin kuruluş fiyatı

Tip 1'de yeni yüzey City'leri Energy, Production, Science, Residential veya Commercial kuruluş ailesinden biriyle alınır. Genel, oyuncunun henüz uzmanlık seçmediği geçiş durumudur; yeni ücretsiz fiyat ailesi değildir. Elle kurulan City de bu beş aileden birini seçer.

| Konu | Denge başlangıcı ve kural |
| --- | --- |
| Normal City kredi tabanı | Bütün beş aile için 2.000 kredi; aileler farklı tekrar sayaçları kullanır. |
| Gövdenin ilk normal City kabuğu | Gövdede başka normal City yoksa ücretsiz ilk kabuk kuralı. Alt bina/district planı ayrıca gerçek bedeliyle kurulur. |
| Sonraki City'ler | Yalnız aynı gövdedeki aynı kuruluş ailesi sayılır. |
| Tekrar katsayısı | Her önceki ücretli eşdeğer adet için ×1,50. |
| İlk ücretsiz City'nin işareti | Gerçek nesnede is_initial_free_city alanıyla korunur; aynı anda her gövdede en fazla bir normal City bu indirimli adettir. |
| Otomatik Orbital City | Normal City değildir; normal aile sayacına veya ücretsiz yüzey City hakkına katılmaz. |
| Kuruluş malzemesi ve süre | City kabuğunda ek malzeme yok; 4 ekonomi saniyesi. Gerçek alt planın malzemeleri ve süreleri ayrıca eklenir. |
| Kapasite ve seviye | Normal City'nin mevcut kapasite, global nüfus/enerji ve seviye kuralları geçerlidir; aile başına ikinci ücretsiz nüfus ödülü yoktur. |

Gövdede en az bir normal City varken ücretli yeni City için n, hedef ailenin mevcut ve inşası başlamış City adedidir. u, bu ailede hâlen bulunan ücretsiz ilk City için 1, yoksa 0'dır.

    Ücretli City kabuğu = 2.000 × 1,50^max(0, n - u)

Örnek: İlk Energy City ücretsizse ikinci Energy 2.000, üçüncü Energy 3.000 kredidir. Aynı gövdede ilk Science City 2.000, ikinci Science City 3.000 kredidir. Her aileye ayrı bir ücretsiz City verilmez.

Bu fiyat alt ağaç dahil hazır planın tamamı değildir. Kabuk, gerçek districtler, seviye işleri ve gerçek binalar bir teklif içinde ayrı edinim paylarıdır. Uyarlanan mevcut City'lerden geçmişe dönük ek kredi alınmaz. Oyuncunun City adını veya içerik ağırlığını değiştirmesi sabit kuruluş fiyat ailesini değiştirmez.

Yıkım mevcut adedi azaltır. Gövdede bütün normal City'ler kaldırılmışsa temel ekonominin yeniden kurulabilmesi için ilk kabuk kuralı yine kullanılabilir; 3.000 kredi/450 Science yeni oyun bütçesi tekrar verilmez. Ücretsiz kabuktan yıkım kredisi doğmaz. Var olan bir City'yi sadece sıfırlamak ikinci ücretsiz City eklemez.

<a id="bolum-12"></a>

## 12. Tip 0 bina kataloğu

### 12.1. Kapsam ve kimlik sözleşmesi

Katalog49 tekil ekonomik model içerir. Regolit Goods kuruluş planı ayrı gösterildiğinde50 görünen satır olur; bu plan Cevher Ayıklama Atölyesi'nin kimliğini ve tekrar sayacını paylaşır.

| Grup | Tekil model | Ek görünen plan | Kapsam |
| --- | ---: | ---: | --- |
| Energy | 8 | 0 | Tip0 |
| Production | 10 | 1 Regolit | Tip0 |
| Depo | 3 | 0 | İki yüzey modeli; bir koşullu yörünge modeli |
| Science | 6 | 0 | Tip0 |
| Residential | 7 | 0 | Tip0 |
| Commercial | 7 | 0 | Tip0 |
| Capital/sefer | 8 | 0 | Tip0 |
| Toplam | 49 | 1 | 50 görünen satır |

Yörünge Yakıt Tankı Tip 1 ve ayrı orbital oynanabilirlik isteyen koşullu destek içeriğidir. Tip 0 yüzey kataloğuna veya demo satın almalarına dahil değildir; Ay ana yolunda zorunlu yapılmaz. Normal yüzeyde kurulabilen tekil Tip 0 model sayısı 48'dir. Tablo, ortak bina veri kataloğu içinde bu bir ileri destek modelini ayrıca korur.

Mevcut kaynak kimliği bulunan33 model aynı kimlikle hedefe taşınır. Yeni16 model için aşağıdaki sabit kimlikler veri sözleşmesidir. Görünen ad veya çeviri, model kimliğini değiştirmez.

### 12.2. Bütün katalog için ortak okuma anahtarı

- Kredi fiyatı indirimsiz ilk adet tabanıdır; tekrar sayacı ayrıca uygulanır.
- Malzeme sütunu tek bir kuruluşun tam isimli faturasıdır.
- Stok üretim ve gider miktarları20 saniye içindir.
- Enerjide artı arz, eksi talep anlamına gelir; enerji stoğu üretilmez.
- Konut miktarı etkin nüfus kapasitesidir; çalışan miktarı kapasite yüküdür.
- Genel Tier2/Tier3 kuruluş listesi kartta zaten açılmıştır; ikinci kez eklenmez.
- Katalogdaki output tabanı tier ölçeğini zaten içerir; ham çıkarım tabanı gövde katsayısından öncedir.
- Gider ve çalışan output bonuslarıyla kendiliğinden büyümez.
- Her model kendi uygun rolünde kurulur; Tip0 aile adları bu rolü doğrudan temsil eder.
- Binaların haritada ayrı koordinatı yoktur; ebeveyn district konumunu miras alırlar.
- Arazi şartı, binanın ebeveyninin gerçek konumundan denetlenir.
- Özel arazi isteyen modelde yalnız yakın olmak kuruluş için yeterli değildir.
- Ayrı yazılmamış hiçbir bina için gezegen seviyesi teknoloji kapısı konmaz.
- Çıkarım çıktısında seçili mineral o gövdenin erişilebilir mineralidir.
- İşleme girdisi global stoktan seçilir; yerel mineral olma şartı yoktur.
- Desteklerin limit1 kuralı satın alma, toplu plan, taşıma, kayıt yükleme ve ölçek uyarlamasında doğrulanır.
- Yapılacak veri dosyası satırı mevcut uygulama iddiası değildir; hedef veri yolunu belirtir.

### 12.3. Energy özeti

| Sabit model | Görünen ad | Profil | Kredi | Yuva | Çalışan | Enerji | Çıktı/kapasite |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| solar_panel | Solar Array | T1 | 150 | 1 | 250 | +3 | +3 etkin enerji |
| wind_turbine | Wind Turbine | T1 | 200 | 1 | 250 | +4 | +4 etkin enerji |
| tidal_generator | Tidal Generator | T2 | 600 | 2 | 750 | +12 | +12 etkin enerji |
| geothermal_plant | Geothermal Plant | T2 | 750 | 2 | 750 | +15 | +15 etkin enerji |
| solar_matrix | Solar Matrix | T2 | 450 | 2 | 750 | +9 | +9 etkin enerji |
| fusion_reactor | Fusion Reactor | T3 | 1350 | 2 | 2250 | +27 | +27 etkin enerji |
| shallow_geothermal_well | Sığ Jeotermal Kuyu | T1 | 250 | 1 | 250 | +5 | +5 etkin enerji |
| ridge_turbine | Sırt Türbini | T2 | 900 | 2 | 750 | +18 | +18 etkin enerji |

### 12.4. Production özeti

| Sabit model | Görünen ad | Profil | Kredi | Yuva | Çalışan | Enerji | Çıktı/kapasite |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| mine | Mine | T1 | 200 | 1 | 250 | -1 | +10 seçili yerel ham /20 sn |
| rich_vein_excavator | Gelişmiş Ekskavatör | T2 | 800 | 2 | 750 | -3 | +40 seçili yerel ham /20 sn |
| deep_drill | Deep Drill | T2 | 600 | 2 | 750 | -3 | +30 seçili yerel ham /20 sn |
| mantle_cracker | Mantle Cracker | T3 | 1800 | 2 | 2250 | -9 | +90 seçili yerel ham /20 sn |
| refinery | Goods Factory | T1 | 300 | 1 | 250 | -2 | +2 taban Goods /20 sn |
| plasma_smelter | Fuel Refinery | T2 | 1350 | 2 | 750 | -6 | +6 taban Fuel /20 sn |
| molecular_forge | Rare Element Forge | T1 | 600 | 1 | 250 | -3 | +1 taban Rare /20 sn |
| surface_quarry | Yüzey Ocağı | Küçük T1 | 100 | 1 | 125 | -0,5 | +5 seçili yerel ham /20 sn |
| ore_sorting_workshop | Cevher Ayıklama Atölyesi | T2 | 900 | 2 | 750 | -6 | +6 taban Goods /20 sn |
| compact_fuel_workshop | Kompakt Yakıt Atölyesi | T1 | 450 | 1 | 250 | -2 | +2 taban Fuel /20 sn |

### 12.5. Depo özeti

| Sabit model | Görünen ad | Profil | Kredi | Yuva | Çalışan | Enerji | Çıktı/kapasite |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| warehouse | Warehouse | T1 | 300 | 1 | 250 | -1 | Ham türü başına +1.000; Goods +150; Fuel +150; Rare +75 kapasite |
| fuel_depot | Yakıt Deposu | Küçük T1 | 150 | 1 | 125 | -0,5 | +300 Fuel depo kapasitesi |
| orbital_fuel_tank | Yörünge Yakıt Tankı | T2 özel | 600 | 2 | 750 | -2 | +1.200 Fuel depo kapasitesi |

### 12.6. Science özeti

| Sabit model | Görünen ad | Profil | Kredi | Yuva | Çalışan | Enerji | Çıktı/kapasite |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| lab | Research Lab | T1 | 150 | 1 | 250 | -1 | +4 Science /20 sn |
| mountain_observatory | Mountain Observatory | T2 | 600 | 2 | 750 | -3 | +16 Science /20 sn |
| advanced_lab | Research Institute | T2 | 450 | 2 | 750 | -3 | +12 Science /20 sn |
| particle_accelerator | Particle Accelerator | T3 | 1350 | 2 | 2250 | -9 | +36 Science /20 sn |
| field_observation_house | Saha Gözlem Evi | Küçük T1 | 75 | 1 | 125 | -0,5 | +2 Science /20 sn |
| moon_sample_lab | Ay Numune Laboratuvarı | T2 özel | 750 | 2 | 750 | -4 | +20 Science /20 sn |

### 12.7. Residential özeti

| Sabit model | Görünen ad | Profil | Kredi | Yuva | Çalışan | Enerji | Çıktı/kapasite |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| residential | Habitat Block | T1 | 120 | 1 | 0 | -1 | +2.500 etkin nüfus kapasitesi |
| seaside_villas | Seaside Villas | T2 | 360 | 2 | 0 | -1 | +6.000 etkin nüfus kapasitesi |
| apartments | Apartment Towers | T2 | 360 | 2 | 0 | -2 | +7.500 etkin nüfus kapasitesi |
| luxury_complex | Luxury Spires | T3 | 1080 | 2 | 0 | -6 | +22.500 etkin nüfus kapasitesi |
| low_rise_housing | Düşük Katlı Konut | Küçük T1 | 60 | 1 | 0 | -0,5 | +1.250 etkin nüfus kapasitesi |
| coastal_apartments | Kıyı Apartmanları | T2 özel | 432 | 2 | 0 | -3 | +9.000 etkin nüfus kapasitesi |
| modular_moon_habitat | Modüler Ay Habitatı | T2 özel | 480 | 2 | 0 | -3 | +10.000 etkin nüfus kapasitesi |

### 12.8. Commercial özeti

| Sabit model | Görünen ad | Profil | Kredi | Yuva | Çalışan | Enerji | Çıktı/kapasite |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| commercial | Market | T1 | 150 | 1 | 250 | -1 | +20 kredi /20 sn |
| bazaar | Bazaar | Büyük T1 | 450 | 2 | 625 | -3 | +80 kredi /20 sn |
| harbor_market | Harbor Market | T2 | 600 | 2 | 750 | -3 | +80 kredi /20 sn |
| trading_post | Trade Hub | T2 | 450 | 2 | 750 | -3 | +60 kredi /20 sn |
| commodities_exchange | Commodity Exchange | T3 | 1800 | 2 | 2250 | -9 | +270 kredi /20 sn |
| local_trade_center | Yerel Ticaret Merkezi | Büyük T1 | 375 | 2 | 625 | -3 | +50 kredi /20 sn |
| moon_supply_market | Ay İkmal Pazarı | T2 özel | 900 | 2 | 750 | -4 | +120 kredi /20 sn |

### 12.9. Capital özeti

| Sabit model | Görünen ad | Profil | Kredi | Yuva | Çalışan | Enerji | Çıktı/kapasite |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| financial_district | Financial District | T2 | 600 | 2 | 750 | -2 | Uygun Commercial kredi çıktısına en fazla +%10 |
| research_academy | Research Directorate | T2 | 600 | 2 | 750 | -2 | Uygun Science çıktısına en fazla +%10 |
| cryo_vault | Housing Authority | T2 | 600 | 2 | 750 | -2 | Uygun konut kapasitesine en fazla +%10 |
| logistics_center | Logistics Center | T2 | 1200 | 2 | 750 | -2 | Uygun Production çıktısına en fazla +%10; Warehouse kadar kapasite |
| command_center | Planetary Command | T3 | 1800 | 2 | 2250 | -3 | Uygun Energy arzına en fazla +%10 |
| spaceport | Spaceport | Özel | 500 | 2 | 250 | 0 | Dünya-Ay seferi başlatma hakkı; stok çıktısı yok |
| construction_bureau | İnşaat Dairesi | T2 | 600 | 2 | 750 | -1 | Uygun districtlerde bina inşaat süresi en fazla -%10 |
| lunar_spaceport | Lunar Spaceport | Özel | 8000 | 2 | 750 | -2 | Ay'dan diğer gezegene gelişmiş roket hazırlama; stok çıktısı yok |

### 12.10. Tekil model fişleri

Her fiş bir ekonomik modelin tam taban tanımıdır. Katalogdaki destek yüzdeleri, hedefin coğrafya veya yakınlık grubuna yeni gizli çarpım eklemez; uygun araştırma/destek toplamına girer.

#### 12-M01. Solar Array

- **Canonical model kimliği:** solar_panel.
- **Uygun ebeveyn:** Energy rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 150.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 1.
- **Nüfus yükü:** 250.
- **Enerji:** +3 etkin arz.
- **Brüt çıktı/kapasite:** +3 etkin enerji.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** start_energy: başlangıç.
- **Konum şartı:** Özel arazi şartı yok; güneş ailesi coğrafyası.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Güneş; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Bakımsız temel arz; iki küçük yatırım esnekliği.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/solar_panel.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M02. Wind Turbine

- **Canonical model kimliği:** wind_turbine.
- **Uygun ebeveyn:** Energy rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 200.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 1.
- **Nüfus yükü:** 250.
- **Enerji:** +4 etkin arz.
- **Brüt çıktı/kapasite:** +4 etkin enerji.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** wind_power:150 Science.
- **Konum şartı:** Ebeveyn district görünen rüzgârlı alan üzerinde olmalı.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Rüzgâr; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Güneşe göre yüksek taban; uygun rüzgâr alanına bağlı.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/wind_turbine.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M03. Tidal Generator

- **Canonical model kimliği:** tidal_generator.
- **Uygun ebeveyn:** Energy rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 600.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** +12 etkin arz.
- **Brüt çıktı/kapasite:** +12 etkin enerji.
- **Çevrim girdisi ve bakımı:** 1/3 Goods; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** tidal_power:350 Science; ANY wind_power/start_commercial.
- **Konum şartı:** Deniz kıyısı üzerinde; göl kıyısı yeterli değil.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Gelgit; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Kıyı seçeneği; Goods bakımı ve iki yuva ister.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/tidal_generator.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M04. Geothermal Plant

- **Canonical model kimliği:** geothermal_plant.
- **Uygun ebeveyn:** Energy rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 750.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** +15 etkin arz.
- **Brüt çıktı/kapasite:** +15 etkin enerji.
- **Çevrim girdisi ve bakımı:** 1/3 Goods; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** geothermal_power:450 Science; ANY shallow_heat/tidal_power.
- **Konum şartı:** Volkanik alan veya jeotermal yarık üzerinde.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Jeotermal; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Solar Matrix'ten güçlü; daha pahalı ve yer koşullu.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/geothermal_plant.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M05. Solar Matrix

- **Canonical model kimliği:** solar_matrix.
- **Uygun ebeveyn:** Energy rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 450.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** +9 etkin arz.
- **Brüt çıktı/kapasite:** +9 etkin enerji.
- **Çevrim girdisi ve bakımı:** 1/3 Goods; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** solar_matrix:350 Science; start_energy.
- **Konum şartı:** Özel arazi şartı yok; güneş ailesi coğrafyası.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Güneş; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Genel yoğun enerji; Goods'a bağımlı.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/solar_matrix.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M06. Fusion Reactor

- **Canonical model kimliği:** fusion_reactor.
- **Uygun ebeveyn:** Energy rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T3; ayrı bina seviyesi yok.
- **İlk adet kredi:** 1350.
- **Kuruluş malzemesi:** 90 Ferrite +15 Goods +5 Fuel +2 Rare.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 2250.
- **Enerji:** +27 etkin arz.
- **Brüt çıktı/kapasite:** +27 etkin enerji.
- **Çevrim girdisi ve bakımı:** 2/3 Fuel; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** fusion_power:900 Science; ANY solar_matrix/geothermal_power; Fuel ve Rare erişimi.
- **Konum şartı:** Özel arazi veya Moonstone şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Füzyon; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** İki yuvada yüksek arz; yüksek çalışan ve Fuel bakımı.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/fusion_reactor.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M07. Sığ Jeotermal Kuyu

- **Canonical model kimliği:** shallow_geothermal_well.
- **Uygun ebeveyn:** Energy rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 250.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 1.
- **Nüfus yükü:** 250.
- **Enerji:** +5 etkin arz.
- **Brüt çıktı/kapasite:** +5 etkin enerji.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** shallow_heat:250 Science; start_energy.
- **Konum şartı:** Volkanik alan veya jeotermal yarık üzerinde.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Jeotermal; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Bakımsız sıcak alan alternatifi; yer koşulu ve ilk maliyet.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/shallow_geothermal_well.tres.

#### 12-M08. Sırt Türbini

- **Canonical model kimliği:** ridge_turbine.
- **Uygun ebeveyn:** Energy rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 900.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** +18 etkin arz.
- **Brüt çıktı/kapasite:** +18 etkin enerji.
- **Çevrim girdisi ve bakımı:** 1/3 Goods; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** ridge_wind:450 Science; wind_power.
- **Konum şartı:** Görünen sırt ve rüzgârlı alan birlikte.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Rüzgâr; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Yüksek coğrafi verim; iki koşul ve yüksek kredi.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/ridge_turbine.tres.

#### 12-M09. Mine

- **Canonical model kimliği:** mine.
- **Uygun ebeveyn:** Production rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 200.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 1.
- **Nüfus yükü:** 250.
- **Enerji:** -1 etkin talep.
- **Brüt çıktı/kapasite:** +10 seçili yerel ham /20 sn.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** start_production: başlangıç.
- **Konum şartı:** Geçerli Production yeri; yerel yatak şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Ham çıkarım; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Bakımsız genel çıkarım; düşük yuva yoğunluğu.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/mine.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M10. Gelişmiş Ekskavatör

- **Canonical model kimliği:** rich_vein_excavator.
- **Uygun ebeveyn:** Production rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 800.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -3 etkin talep.
- **Brüt çıktı/kapasite:** +40 seçili yerel ham /20 sn.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** advanced_excavation:450 Science; start_production.
- **Konum şartı:** Geçerli Production yeri; vein veya yoğunluk şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Ham çıkarım; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Deep Drill'den yüksek çıktı; daha fazla ilk kredi.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/rich_vein_excavator.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M11. Deep Drill

- **Canonical model kimliği:** deep_drill.
- **Uygun ebeveyn:** Production rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 600.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -3 etkin talep.
- **Brüt çıktı/kapasite:** +30 seçili yerel ham /20 sn.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** deep_drilling:350 Science; start_production.
- **Konum şartı:** Geçerli Production yeri; özel arazi zorunlu değil.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Ham çıkarım; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Daha ucuz yoğun çıkarım; ekskavatörden düşük çıktı.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/deep_drill.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M12. Mantle Cracker

- **Canonical model kimliği:** mantle_cracker.
- **Uygun ebeveyn:** Production rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T3; ayrı bina seviyesi yok.
- **İlk adet kredi:** 1800.
- **Kuruluş malzemesi:** 90 Ferrite +15 Goods +5 Fuel +2 Rare.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 2250.
- **Enerji:** -9 etkin talep.
- **Brüt çıktı/kapasite:** +90 seçili yerel ham /20 sn.
- **Çevrim girdisi ve bakımı:** 1/3 Fuel; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** mantle_cracking:900 Science; ANY advanced_excavation/deep_drilling; Fuel ve Rare erişimi.
- **Konum şartı:** Özel yerel yatak veya Moonstone şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Ham çıkarım; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Yüksek yuva verimi; çalışan, enerji ve Fuel yükü.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/mantle_cracker.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M13. Goods Factory

- **Canonical model kimliği:** refinery.
- **Uygun ebeveyn:** Production rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 300.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 1.
- **Nüfus yükü:** 250.
- **Enerji:** -2 etkin talep.
- **Brüt çıktı/kapasite:** +2 taban Goods /20 sn.
- **Çevrim girdisi ve bakımı:** 4 seçili ham; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** processing_basics: başlangıç,0 Science.
- **Konum şartı:** Geçerli Production yeri; seçili girdi global stoktan.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** İşlenmiş Goods; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Bakımsız temel Goods; yüksek tier için başlangıç stoğu.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/refinery.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M14. Fuel Refinery

- **Canonical model kimliği:** plasma_smelter.
- **Uygun ebeveyn:** Production rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 1350.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -6 etkin talep.
- **Brüt çıktı/kapasite:** +6 taban Fuel /20 sn.
- **Çevrim girdisi ve bakımı:** 24 seçili ham +1/3 Goods; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** dense_fuel:350 Science; fuel_processing.
- **Konum şartı:** Geçerli Production yeri; mineral yerel olmak zorunda değil.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** İşlenmiş Fuel; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Kompakt Fuel'ın üç katı tarif; Goods bakımı ve iki yuva.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/plasma_smelter.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M15. Rare Element Forge

- **Canonical model kimliği:** molecular_forge.
- **Uygun ebeveyn:** Production rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 600.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 1.
- **Nüfus yükü:** 250.
- **Enerji:** -3 etkin talep.
- **Brüt çıktı/kapasite:** +1 taban Rare /20 sn.
- **Çevrim girdisi ve bakımı:** 12 seçili ham; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** rare_processing:900 Science; fuel_processing.
- **Konum şartı:** Geçerli Production yeri; gezegen seviyesi kapısı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** İşlenmiş Rare; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Erken Rare erişimi; yüksek ham ve enerji maliyeti.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/molecular_forge.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M16. Yüzey Ocağı

- **Canonical model kimliği:** surface_quarry.
- **Uygun ebeveyn:** Production rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** Küçük T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 100.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 1.
- **Nüfus yükü:** 125.
- **Enerji:** -0,5 etkin talep.
- **Brüt çıktı/kapasite:** +5 seçili yerel ham /20 sn.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 2 ekonomi saniyesi.
- **Araştırma/erişim:** surface_excavation:75 Science; start_production.
- **Konum şartı:** Geçerli Production yeri; yerel yatak şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Ham çıkarım; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Düşük ilk yatırım ve yük; tek yuvada Mine'ın yarısı.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/surface_quarry.tres.

#### 12-M17. Cevher Ayıklama Atölyesi

- **Canonical model kimliği:** ore_sorting_workshop.
- **Uygun ebeveyn:** Production rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 900.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -6 etkin talep.
- **Brüt çıktı/kapasite:** +6 taban Goods /20 sn.
- **Çevrim girdisi ve bakımı:** 12 seçili ham +1/3 Goods; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** ore_sorting:450 Science; processing_basics.
- **Konum şartı:** Genel plan Production yeri; Ay'da Regolit planı alternatif.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** İşlenmiş Goods; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Yoğun Goods; kendi bakım stoğu önceden gerekir.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/ore_sorting_workshop.tres.

#### 12-M18. Kompakt Yakıt Atölyesi

- **Canonical model kimliği:** compact_fuel_workshop.
- **Uygun ebeveyn:** Production rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 450.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 1.
- **Nüfus yükü:** 250.
- **Enerji:** -2 etkin talep.
- **Brüt çıktı/kapasite:** +2 taban Fuel /20 sn.
- **Çevrim girdisi ve bakımı:** 8 seçili ham; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** fuel_processing:450 Science; processing_basics.
- **Konum şartı:** Geçerli Production yeri; gezegen seviyesi kapısı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** İşlenmiş Fuel; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** İlk Fuel için küçük sermaye; düşük yuva yoğunluğu.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/compact_fuel_workshop.tres.

#### 12-M19. Warehouse

- **Canonical model kimliği:** warehouse.
- **Uygun ebeveyn:** Production rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 300.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 1.
- **Nüfus yükü:** 250.
- **Enerji:** -1 etkin talep.
- **Brüt çıktı/kapasite:** Ham türü başına +1.000; Goods +150; Fuel +150; Rare +75 kapasite.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** start_production: başlangıç.
- **Konum şartı:** Production District; özel arazi şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Depo; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Global stok tavanı; doğrudan gelir veya malzeme üretmez.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/warehouse.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M20. Yakıt Deposu

- **Canonical model kimliği:** fuel_depot.
- **Uygun ebeveyn:** Production rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** Küçük T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 150.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 1.
- **Nüfus yükü:** 125.
- **Enerji:** -0,5 etkin talep.
- **Brüt çıktı/kapasite:** +300 Fuel depo kapasitesi.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 2 ekonomi saniyesi.
- **Araştırma/erişim:** fuel_storage:200 Science; fuel_processing.
- **Konum şartı:** Production District; özel arazi şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Depo; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Düşük maliyetli Fuel alanı; diğer stokları büyütmez.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/fuel_depot.tres.

#### 12-M21. Yörünge Yakıt Tankı

- **Canonical model kimliği:** orbital_fuel_tank.
- **Uygun ebeveyn:** Orbital Logistics rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2 özel; ayrı bina seviyesi yok.
- **İlk adet kredi:** 600.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -2 etkin talep.
- **Brüt çıktı/kapasite:** +1.200 Fuel depo kapasitesi.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** orbital_storage:600 Science; orbital_assembly, minimum medeniyet 1 ve oynanabilir orbital içerik izni. Bu model demoda satın alınamaz ve Tip 0 Mirası bu Tip 1 haklarını vermez.
- **Konum şartı:** Yalnız uygun Orbital Logistics districti; koşullu ileri içerik.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Depo; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Yoğun Fuel alanı; yörünge erişimine bağlı, Ay yolunda zorunlu değil.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/orbital_fuel_tank.tres.

#### 12-M22. Research Lab

- **Canonical model kimliği:** lab.
- **Uygun ebeveyn:** Science rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 150.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 1.
- **Nüfus yükü:** 250.
- **Enerji:** -1 etkin talep.
- **Brüt çıktı/kapasite:** +4 Science /20 sn.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** start_science: başlangıç.
- **Konum şartı:** Özel arazi şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Science; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Bakımsız temel araştırma; kolay yayılma.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/lab.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M23. Mountain Observatory

- **Canonical model kimliği:** mountain_observatory.
- **Uygun ebeveyn:** Science rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 600.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -3 etkin talep.
- **Brüt çıktı/kapasite:** +16 Science /20 sn.
- **Çevrim girdisi ve bakımı:** 1/3 Goods; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** mountain_optics:450 Science; start_science.
- **Konum şartı:** Ebeveyn district dağ üzerinde olmalı.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Science; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Institute'tan yüksek çıktı; dağ ve ek kredi şartı.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/mountain_observatory.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M24. Research Institute

- **Canonical model kimliği:** advanced_lab.
- **Uygun ebeveyn:** Science rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 450.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -3 etkin talep.
- **Brüt çıktı/kapasite:** +12 Science /20 sn.
- **Çevrim girdisi ve bakımı:** 1/3 Goods; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** advanced_research:350 Science; start_science.
- **Konum şartı:** Özel arazi şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Science; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** İki Lab'a göre %50 fazla çıktı; daha fazla çalışan ve bakım.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/advanced_lab.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M25. Particle Accelerator

- **Canonical model kimliği:** particle_accelerator.
- **Uygun ebeveyn:** Science rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T3; ayrı bina seviyesi yok.
- **İlk adet kredi:** 1350.
- **Kuruluş malzemesi:** 90 Ferrite +60 Moonstone +15 Goods +5 Fuel +2 Rare.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 2250.
- **Enerji:** -9 etkin talep.
- **Brüt çıktı/kapasite:** +36 Science /20 sn.
- **Çevrim girdisi ve bakımı:** 1/3 Rare; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** particle_physics:900 Science; ANY advanced_research/rare_processing; Rare ve Moonstone erişimi.
- **Konum şartı:** Genel Science yeri; keşfedilmiş Moonstone kuruluşta gerekir.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Science; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Yüksek yoğunluk; Rare bakımı, Moonstone ve çalışan yükü.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/particle_accelerator.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M26. Saha Gözlem Evi

- **Canonical model kimliği:** field_observation_house.
- **Uygun ebeveyn:** Science rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** Küçük T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 75.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 1.
- **Nüfus yükü:** 125.
- **Enerji:** -0,5 etkin talep.
- **Brüt çıktı/kapasite:** +2 Science /20 sn.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 2 ekonomi saniyesi.
- **Araştırma/erişim:** field_research:100 Science; start_science.
- **Konum şartı:** Ebeveyn district dağ üzerinde. Ayrı plato coğrafyası kullanılmaz.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Science; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Ucuz yarım ölçek; uygun saha ve bir yuva.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/field_observation_house.tres.

#### 12-M27. Ay Numune Laboratuvarı

- **Canonical model kimliği:** moon_sample_lab.
- **Uygun ebeveyn:** Science rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2 özel; ayrı bina seviyesi yok.
- **İlk adet kredi:** 750.
- **Kuruluş malzemesi:** 75 Moonstone +10 Goods +5 Rare.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -4 etkin talep.
- **Brüt çıktı/kapasite:** +20 Science /20 sn.
- **Çevrim girdisi ve bakımı:** 1/3 Rare; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** lunar_research:600 Science; lunar_materials; Ay City'si ve Rare erişimi.
- **Konum şartı:** Yalnız Ay'da Science District.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Science; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Ay'a özgü güçlü araştırma; Rare bakımı ve yerel kuruluş bedeli.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/moon_sample_lab.tres.

#### 12-M28. Habitat Block

- **Canonical model kimliği:** residential.
- **Uygun ebeveyn:** Residential rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 120.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 1.
- **Nüfus yükü:** 0.
- **Enerji:** -1 etkin talep.
- **Brüt çıktı/kapasite:** +2.500 etkin nüfus kapasitesi.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** start_residential: başlangıç.
- **Konum şartı:** Özel arazi şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Konut; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Bakımsız temel konut; düşük yuva yoğunluğu.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/residential.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M29. Seaside Villas

- **Canonical model kimliği:** seaside_villas.
- **Uygun ebeveyn:** Residential rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 360.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 0.
- **Enerji:** -1 etkin talep.
- **Brüt çıktı/kapasite:** +6.000 etkin nüfus kapasitesi.
- **Çevrim girdisi ve bakımı:** 1/3 Goods; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** coastal_living:250 Science; start_residential.
- **Konum şartı:** Ebeveyn district deniz kıyısı üzerinde.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Konut; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Düşük enerji talebi; Apartment'tan az kapasite ve kıyı şartı.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/seaside_villas.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M30. Apartment Towers

- **Canonical model kimliği:** apartments.
- **Uygun ebeveyn:** Residential rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 360.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 0.
- **Enerji:** -2 etkin talep.
- **Brüt çıktı/kapasite:** +7.500 etkin nüfus kapasitesi.
- **Çevrim girdisi ve bakımı:** 1/3 Goods; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** high_rise:350 Science; ANY coastal_living/civic_enterprise.
- **Konum şartı:** Özel arazi şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Konut; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Genel yoğun konut; Goods ve iki yuva.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/apartments.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M31. Luxury Spires

- **Canonical model kimliği:** luxury_complex.
- **Uygun ebeveyn:** Residential rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T3; ayrı bina seviyesi yok.
- **İlk adet kredi:** 1080.
- **Kuruluş malzemesi:** 90 Ferrite +60 Moonstone +15 Goods +5 Fuel +2 Rare.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 0.
- **Enerji:** -6 etkin talep.
- **Brüt çıktı/kapasite:** +22.500 etkin nüfus kapasitesi.
- **Çevrim girdisi ve bakımı:** 2/3 Goods +1/3 Fuel; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** luxury_living:900 Science; high_rise; Fuel, Rare ve Moonstone erişimi.
- **Konum şartı:** Genel Residential yeri; keşfedilmiş Moonstone kuruluşta gerekir.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Konut; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Yüksek kapasite; Fuel bakımı ve Ay sonrası malzeme.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/luxury_complex.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M32. Düşük Katlı Konut

- **Canonical model kimliği:** low_rise_housing.
- **Uygun ebeveyn:** Residential rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** Küçük T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 60.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 1.
- **Nüfus yükü:** 0.
- **Enerji:** -0,5 etkin talep.
- **Brüt çıktı/kapasite:** +1.250 etkin nüfus kapasitesi.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 2 ekonomi saniyesi.
- **Araştırma/erişim:** neighborhood_building:75 Science; start_residential.
- **Konum şartı:** Özel arazi şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Konut; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Çok düşük ilk yatırım; bir yuvada yarım kapasite.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/low_rise_housing.tres.

#### 12-M33. Kıyı Apartmanları

- **Canonical model kimliği:** coastal_apartments.
- **Uygun ebeveyn:** Residential rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2 özel; ayrı bina seviyesi yok.
- **İlk adet kredi:** 432.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 0.
- **Enerji:** -3 etkin talep.
- **Brüt çıktı/kapasite:** +9.000 etkin nüfus kapasitesi.
- **Çevrim girdisi ve bakımı:** 1/3 Goods; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** coastal_density:350 Science; coastal_living.
- **Konum şartı:** Ebeveyn district deniz kıyısı üzerinde.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Konut; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Apartment'tan fazla kapasite; daha fazla kredi, enerji ve kıyı şartı.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/coastal_apartments.tres.

#### 12-M34. Modüler Ay Habitatı

- **Canonical model kimliği:** modular_moon_habitat.
- **Uygun ebeveyn:** Residential rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2 özel; ayrı bina seviyesi yok.
- **İlk adet kredi:** 480.
- **Kuruluş malzemesi:** 50 Moonstone +10 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 0.
- **Enerji:** -3 etkin talep.
- **Brüt çıktı/kapasite:** +10.000 etkin nüfus kapasitesi.
- **Çevrim girdisi ve bakımı:** 2/3 Goods; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** lunar_materials:1.200 Science; Ay'da çıkarabilen Production tamamlanmış.
- **Konum şartı:** Yalnız Ay'da Residential District.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Konut; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Ay'da yoğun konut; yüksek Goods bakımı.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/modular_moon_habitat.tres.

#### 12-M35. Market

- **Canonical model kimliği:** commercial.
- **Uygun ebeveyn:** Commercial rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 150.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 1.
- **Nüfus yükü:** 250.
- **Enerji:** -1 etkin talep.
- **Brüt çıktı/kapasite:** +20 kredi /20 sn.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** start_commercial: başlangıç.
- **Konum şartı:** Özel arazi şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Kredi; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Bakımsız temel kredi; küçük ilk sermaye.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/commercial.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M36. Bazaar

- **Canonical model kimliği:** bazaar.
- **Uygun ebeveyn:** Commercial rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** Büyük T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 450.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 625.
- **Enerji:** -3 etkin talep.
- **Brüt çıktı/kapasite:** +80 kredi /20 sn.
- **Çevrim girdisi ve bakımı:** 1 Goods; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** consumer_goods:250 Science; start_commercial.
- **Konum şartı:** Özel arazi şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Kredi; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** İki Market'ten yüksek gelir; Goods tüketimi, ek çalışan ve enerji.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/bazaar.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M37. Harbor Market

- **Canonical model kimliği:** harbor_market.
- **Uygun ebeveyn:** Commercial rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 600.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -3 etkin talep.
- **Brüt çıktı/kapasite:** +80 kredi /20 sn.
- **Çevrim girdisi ve bakımı:** 1/3 Goods; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** harbor_trade:450 Science; ANY coastal_living/trade_networks.
- **Konum şartı:** Ebeveyn district deniz kıyısı üzerinde.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Kredi; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Trade Hub'tan fazla kredi; kıyı ve ek kuruluş fiyatı.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/harbor_market.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M38. Trade Hub

- **Canonical model kimliği:** trading_post.
- **Uygun ebeveyn:** Commercial rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 450.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -3 etkin talep.
- **Brüt çıktı/kapasite:** +60 kredi /20 sn.
- **Çevrim girdisi ve bakımı:** 1/3 Goods; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** trade_networks:350 Science; ANY consumer_goods/local_business.
- **Konum şartı:** Özel arazi şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Kredi; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Genel yoğun kredi; çalışan ve Goods bakımı.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/trading_post.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M39. Commodity Exchange

- **Canonical model kimliği:** commodities_exchange.
- **Uygun ebeveyn:** Commercial rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T3; ayrı bina seviyesi yok.
- **İlk adet kredi:** 1800.
- **Kuruluş malzemesi:** 90 Ferrite +90 Moonstone +15 Goods +5 Fuel +2 Rare.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 2250.
- **Enerji:** -9 etkin talep.
- **Brüt çıktı/kapasite:** +270 kredi /20 sn.
- **Çevrim girdisi ve bakımı:** 3 Goods +1/3 Fuel; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** commodity_markets:900 Science; trade_networks; Fuel, Rare ve Moonstone erişimi.
- **Konum şartı:** Genel Commercial yeri; keşfedilmiş Moonstone kuruluşta gerekir.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Kredi; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Yüksek gelir; büyük Goods gideri, Fuel ve Ay malzemesi.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/commodities_exchange.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M40. Yerel Ticaret Merkezi

- **Canonical model kimliği:** local_trade_center.
- **Uygun ebeveyn:** Commercial rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** Büyük T1; ayrı bina seviyesi yok.
- **İlk adet kredi:** 375.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 625.
- **Enerji:** -3 etkin talep.
- **Brüt çıktı/kapasite:** +50 kredi /20 sn.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** local_business:150 Science; trade_access.
- **Konum şartı:** Özel arazi şartı yok.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Kredi; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** İki Market'ten %25 fazla gelir; daha fazla çalışan ve enerji.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/local_trade_center.tres.

#### 12-M41. Ay İkmal Pazarı

- **Canonical model kimliği:** moon_supply_market.
- **Uygun ebeveyn:** Commercial rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2 özel; ayrı bina seviyesi yok.
- **İlk adet kredi:** 900.
- **Kuruluş malzemesi:** 75 Moonstone +20 Goods +10 Fuel.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -4 etkin talep.
- **Brüt çıktı/kapasite:** +120 kredi /20 sn.
- **Çevrim girdisi ve bakımı:** 1 Goods +1/3 Fuel; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** lunar_supply:600 Science; ANY lunar_materials/trade_networks; Ay City'si, trade_access, Fuel erişimi.
- **Konum şartı:** Yalnız Ay'da Commercial District.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Kredi; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Ay'da güçlü gelir; iki ürün gideri ve özel malzeme.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/moon_supply_market.tres.

#### 12-M42. Financial District

- **Canonical model kimliği:** financial_district.
- **Uygun ebeveyn:** Capital/sefer rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 600.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -2 etkin talep.
- **Brüt çıktı/kapasite:** Uygun Commercial kredi çıktısına en fazla +%10.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** public_administration:350 Science VE trade_networks:350 Science.
- **Konum şartı:** Capital içinde; destek erişimi merkez mesafesine göre.
- **Model/adet sınırı:** Aynı merkezde bu canonical destekten en fazla1; bütün komutlarda sert kontrol.
- **Bonus ailesi:** Destek; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Seçilmiş ticaret desteği; kendi kredi çıktısı yok.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/financial_district.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M43. Research Directorate

- **Canonical model kimliği:** research_academy.
- **Uygun ebeveyn:** Capital/sefer rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 600.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -2 etkin talep.
- **Brüt çıktı/kapasite:** Uygun Science çıktısına en fazla +%10.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** public_administration:350 Science VE advanced_research:350 Science.
- **Konum şartı:** Capital içinde; destek erişimi merkez mesafesine göre.
- **Model/adet sınırı:** Aynı merkezde bu canonical destekten en fazla1; bütün komutlarda sert kontrol.
- **Bonus ailesi:** Destek; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Seçilmiş bilim desteği; kendi Science çıktısı yok.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/research_academy.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M44. Housing Authority

- **Canonical model kimliği:** cryo_vault.
- **Uygun ebeveyn:** Capital/sefer rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 600.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -2 etkin talep.
- **Brüt çıktı/kapasite:** Uygun konut kapasitesine en fazla +%10.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** public_administration:350 Science VE high_rise:350 Science.
- **Konum şartı:** Capital içinde; destek erişimi merkez mesafesine göre.
- **Model/adet sınırı:** Aynı merkezde bu canonical destekten en fazla1; bütün komutlarda sert kontrol.
- **Bonus ailesi:** Destek; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Konut desteği; doğrudan nüfus stoğu üretmez.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/cryo_vault.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M45. Logistics Center

- **Canonical model kimliği:** logistics_center.
- **Uygun ebeveyn:** Capital/sefer rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 1200.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -2 etkin talep.
- **Brüt çıktı/kapasite:** Uygun Production çıktısına en fazla +%10; Warehouse kadar kapasite.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** logistics:450 Science; ANY ore_sorting/trade_networks; public_administration.
- **Konum şartı:** Capital içinde; destek mesafeli, depo katkısı global.
- **Model/adet sınırı:** Aynı merkezde bu canonical destekten en fazla1; bütün komutlarda sert kontrol.
- **Bonus ailesi:** Destek/depo; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Üretim ve depo birlikte; daha pahalı ve merkez yuvası kullanır.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/logistics_center.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M46. Planetary Command

- **Canonical model kimliği:** command_center.
- **Uygun ebeveyn:** Capital/sefer rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T3; ayrı bina seviyesi yok.
- **İlk adet kredi:** 1800.
- **Kuruluş malzemesi:** 90 Ferrite +60 Moonstone +15 Goods +5 Fuel +2 Rare.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 2250.
- **Enerji:** -3 etkin talep.
- **Brüt çıktı/kapasite:** Uygun Energy arzına en fazla +%10.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** advanced_coordination:900 Science; ANY fusion_power/advanced_research; public_administration ve Fuel/Rare/Moonstone erişimi.
- **Konum şartı:** Capital içinde; destek erişimi merkez mesafesine göre.
- **Model/adet sınırı:** Aynı merkezde bu canonical destekten en fazla1; bütün komutlarda sert kontrol.
- **Bonus ailesi:** Destek; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Enerji desteği; kendi enerji üretimi yok, Moonstone ister.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/command_center.tres:7; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M47. Spaceport

- **Canonical model kimliği:** spaceport.
- **Uygun ebeveyn:** Capital/sefer rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** Özel; ayrı bina seviyesi yok.
- **İlk adet kredi:** 500.
- **Kuruluş malzemesi:** Yok.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 250.
- **Enerji:** 0 etkin arz.
- **Brüt çıktı/kapasite:** Dünya-Ay seferi başlatma hakkı; stok çıktısı yok.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** rocketry:600 Science; fuel_processing.
- **Konum şartı:** Dünya Capital içinde; toplam2 boş yuva.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Sefer; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** İlk Ay sefer tesisi; gelir üretmez ve kendi başına uçuş yapmaz.
- **Veri karşılığı:** Kaynak kimlik: C:/Users/drosm/Voidle/resources/buildings/spaceport.tres:11; değerler bu fişteki hedefe göre düzenlenecek.

#### 12-M48. İnşaat Dairesi

- **Canonical model kimliği:** construction_bureau.
- **Uygun ebeveyn:** Capital/sefer rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** T2; ayrı bina seviyesi yok.
- **İlk adet kredi:** 600.
- **Kuruluş malzemesi:** 30 Ferrite +5 Goods.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -1 etkin talep.
- **Brüt çıktı/kapasite:** Uygun districtlerde bina inşaat süresi en fazla -%10.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 4 ekonomi saniyesi.
- **Araştırma/erişim:** construction_management:350 Science; public_administration.
- **Konum şartı:** Capital içinde; destek erişimi merkez mesafesine göre.
- **Model/adet sınırı:** Aynı merkezde bu canonical destekten en fazla1; bütün komutlarda sert kontrol.
- **Bonus ailesi:** Destek; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Kuruluş kolaylığı; üretim veya bedel indirimi değildir.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/construction_bureau.tres.

#### 12-M49. Lunar Spaceport

- **Canonical model kimliği:** lunar_spaceport.
- **Uygun ebeveyn:** Capital/sefer rolü; üst ölçek uyarlamasında gerçek alt rol uyumluluğu korunur.
- **Profil:** Özel; ayrı bina seviyesi yok.
- **İlk adet kredi:** 8000.
- **Kuruluş malzemesi:** 200 Moonstone +50 Goods +30 Fuel +10 Rare.
- **Yuva kullanımı:** 2.
- **Nüfus yükü:** 750.
- **Enerji:** -2 etkin talep.
- **Brüt çıktı/kapasite:** Ay'dan diğer gezegene gelişmiş roket hazırlama; stok çıktısı yok.
- **Çevrim girdisi ve bakımı:** Yok; varsa20 saniyelik tam ödeme.
- **İnşaat tabanı:** 30 ekonomi saniyesi.
- **Araştırma/erişim:** lunar_materials:1.200 Science; yerel Ay Production tamamlanmış.
- **Konum şartı:** Yalnız Ay Capital içinde; toplam2 boş yuva.
- **Model/adet sınırı:** Ek model tekilliği tanımlı değil; uygun rol ve toplam yuva/adet sınırı geçerli.
- **Bonus ailesi:** Sefer; uygun çıktı grubuna yalnız bir kez uygulanır.
- **Tercih ve bedel:** Zorunlu son sefer tesisi; yüksek isimli maliyet ve30 saniye inşaat.
- **Veri karşılığı:** Oluşturulacak hedef: C:/Users/drosm/Voidle/resources/buildings/lunar_spaceport.tres.

### 12.11. Regolit Goods planı

| Alan | Değer |
| --- | --- |
| Canonical ekonomik model | ore_sorting_workshop |
| Kuruluş planı kimliği | regolith_goods_plan |
| Görünen ad | Regolit Goods planı |
| Kuruluş yeri | Ay'da Production rolü |
| Açılış | lunar_materials; Moonstone keşfi |
| Kredi tabanı | 900 |
| Tam isimli kuruluş malzemesi | 100 Moonstone +20 Goods |
| Yuva | 2 |
| Çalışan | 750 |
| Enerji talebi | 6 |
| Çevrim | 20 saniye |
| Girdi | 12 Moonstone +1/3 Goods |
| Taban ürün | 6 Goods |
| Nadirlik uygulanmış brüt ürün | 10,5 Goods |
| Aynı ürün bakımından net | 10 ve1/6 Goods |
| İnşaat | 4 saniye |
| Tekrar sayacı | Aynı districtteki bütün ore_sorting_workshop adetleri |

Genel plan30 Ferrite +5 Goods, Ay planı100 Moonstone +20 Goods ister. Bir kurulumda seçilen faturanın yalnız biri tahsil edilir. Bu, aynı ekonomik model için iki meşru kuruluş yoludur.

Genel planla kurulmuş modelin girdisini Moonstone yapmak modeli yeniden satın almak değildir. Yerel planın görünümü de ikinci bir gelir sağlamaz.

### 12.12. Yoğunluk karşılaştırmaları

| Tercih | Aynı yuva kullanımı | Çıktı/kapasite | Çalışan | Enerji | Temel ek bedel |
| --- | --- | --- | ---: | ---: | --- |
| 2 Lab | 2 | 8 Science /20 sn | 500 | 2 | Bakım yok |
| 1 Institute | 2 | 12 Science /20 sn | 750 | 3 | 1/3 Goods /20 sn |
| 2 Market | 2 | 40 kredi /20 sn | 500 | 2 | Bakım yok |
| 1 Yerel Merkez | 2 | 50 kredi /20 sn | 625 | 3 | İlk fiyat ve çalışan/enerji |
| 1 Bazaar | 2 | 80 kredi /20 sn | 625 | 3 | 1 Goods /20 sn |
| 2 Mine | 2 | 20 ham /20 sn | 500 | 2 | Bakım yok |
| 1 Deep Drill | 2 | 30 ham /20 sn | 750 | 3 | T2 malzemesi |
| 1 Gelişmiş Ekskavatör | 2 | 40 ham /20 sn | 750 | 3 | Daha yüksek ilk kredi |
| 2 Habitat | 2 | 5.000 konut | 0 | 2 | Bakım yok |
| 1 Apartment | 2 | 7.500 konut | 0 | 2 | 1/3 Goods /20 sn |
| 1 Seaside Villas | 2 | 6.000 konut | 0 | 1 | Kıyı ve1/3 Goods /20 sn |
| 1 Kıyı Apartmanı | 2 | 9.000 konut | 0 | 3 | Kıyı ve daha yüksek sermaye |

Bu yoğunluk tablosunun ham miktarları gövde×1 referansıdır. Ay'daki gerçek Mine/çıkarım miktarı×1,30 alır; işlemecinin nadirlik hesabı ayrı kalır.

İki aynı modelin kredi karşılaştırmasında tekrar fiyatı unutulmaz. İki Lab aynı districtte150 +180 =330 kredi tutar. Institute450 kredidir; bu tabloda gösterilen üstünlüğü daha pahalı yoğunluktur.

İki Market150 +180 =330 kredi, Yerel Merkez375 kredi, Bazaar450 kredi tutar. Bazaar'ın yüksek brüt gelirinin Goods gideri tam görünür.

### 12.13. Capital desteklerinin kapsamı

| Destek | Çok yakın hedef | Yakın hedef | Daha uzaktaki hedef |
| --- | ---: | ---: | ---: |
| Financial District | Kredi +%10 | Kredi +%5 | 0 |
| Research Directorate | Science +%10 | Science +%5 | 0 |
| Housing Authority | Konut +%10 | Konut +%5 | 0 |
| Logistics Center | Production +%10 | Production +%5 | 0 |
| Planetary Command | Energy +%10 | Energy +%5 | 0 |
| İnşaat Dairesi | Bina süresi -%10 | Bina süresi -%5 | 0 |

Aynı merkezde aynı destekten ikinci kopya kurulamaz. Taşıma veya otomatik plan bu kuralı aşamaz. Aynı hedefin destek kapsamında olması, hedefin stok çıktısının ikinci kez merkezde üretilmesi anlamına gelmez.

Logistics Center'ın depo katkısı globaldir. Üretim yüzdesi ise geçerli hedef/mesafe kapsamındadır. Bu iki etkinin kapsamı birbirine karıştırılmaz.

Capital'ın temel merkez etkisi ile seçilmiş destek etkisi ayrı açıklanır. City gövdesinin konumu ayrıca ikinci bir gizli merkez bonusu üretmez.

### 12.14. Büyük bina kartı

İki yuva kullanan bina iki standart hücre genişliğinde tek karttır. Dar panelde iki satır yüksekliği kullanılabilir. Kartın genişliği iki ayrı model veya iki ödeme kaydı değildir.

Toplam iki boş yuva varsa kartların görsel dizilişi kuruluşu engellemez. Liste yeniden paketlenebilir. Bina listesi konumsuzdur; yan yana hücre bulma bulmacası coğrafi stratejinin yerine geçmez.

Aynı modelin adetleri tek kartta gösterilir. Girdi seçimleri alt gruplardır. Büyük kartın üzerinde toplam kurulu adet ve çalışan adet ayrı yer alır.

### 12.15. Tip 0'a açık olmayan tanımlar

| Saklanan kimlik | Üst ölçekteki kullanım | Tip0 satın alma |
| --- | --- | --- |
| antimatter_chamber | İleri enerji district planı teması | Kapalı |
| quantum_computer | İleri bilim district planı teması | Kapalı |
| arcology | İleri konut district planı teması | Kapalı |
| central_bank | İleri ticaret district planı teması | Kapalı |
| zero_g_nexus | Orbital Science district teması | Ana yoldan bağımsız |
| orbital_mirrors | Orbital Energy destek teması | Ana yoldan bağımsız |
| orbital_offworld_market | Orbital Commercial teması | Ana yoldan bağımsız |
| orbital_shipyard | Orbital sefer hazırlık district teması | Ay roketi için zorunlu değil |
| orbital_logistics | Orbital Logistics district teması | Ay roketi için zorunlu değil |

Bu dokuz kimlik katalogdaki49 modele ek Tip0 satın alma seçeneği olarak sayılmaz. Üst ölçekteki gerçek district türlerinin kendi model tanımları ayrı katalogdadır.

Varsayılan açık bayrağı bu kapsamı aşamaz. Quantum Computer veya Arcology, eski bir veri bayrağı açık diye başlangıç menüsünde görünmez.

### 12.16. Kaynak ve hedef uygulama haritası

| Kaynak grubu | İlgili dosyalar | Uygulama işi |
| --- | --- | --- |
| Model veri şeması | C:/Users/drosm/Voidle/scripts/game/BuildingDef.gd:9, 14, 15, 23, 41, 50, 55, 67 | Canonical kimlik, isimli kuruluş malzemesi, yuva, tier, çalışan ve tarif ayrımı. |
| Yer şartı | C:/Users/drosm/Voidle/scripts/game/BuildingDef.gd:138, 184, 199 | Gizli yoğunluk yerine ebeveynin görünür coğrafya şartı ve miras etkisi. |
| Hak listesi | C:/Users/drosm/Voidle/scripts/game/BuildingDef.gd:257 | Canonical araştırma ve ek erişim birlikte denetlenir. |
| Yerleştirme | C:/Users/drosm/Voidle/scripts/game/PlanetProgress.gd:157 | Tekillik, yuva, fatura ve çalışan rezervi bütün komutlarda merkezi doğrulanır. |
| Ham üretim | C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd:608 | Seçili yerel mineral; yoğunlukla otomatik paylaştırma yok. |
| Çıktı | C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd:638, 646 | Katalog tabanı tier'ı içerir; district ve uygun araştırma bir kez. |
| Destek | C:/Users/drosm/Voidle/scripts/game/Economy.gd:370 | Gezegen geneline görünmez kapsam yerine açık hedef ve mesafe payı. |
| Bina davranışı | C:/Users/drosm/Voidle/scripts/game/logic/BuildingLogic.gd:5 | Tarif seçimi ve tamamlama ortak stok sözleşmesini kullanır. |
| Veri dosyaları | C:/Users/drosm/Voidle/resources/buildings/ içindeki mevcut33 ilgili model | Hedef katalog tabanlarına taşınır. |
| Yeni model verileri | Fişlerdeki16 yeni hedef veri yolu | Yeni model tanımları oluşturulur; mevcutmış gibi varsayılmaz. |

<a id="bolum-13"></a>

## 13. City, district ve gezegen seviyeleri

### 13.1. Birbirinden bağımsız dört gelişim ölçüsü

| Ölçü | Ne değiştirir? | Ne değiştirmez? |
| --- | --- | --- |
| Bina adedi | Üretici sayısı, yuva kullanımı, çalışan ve enerji ihtiyacı | Tek binanın level'ı yoktur |
| District seviyesi | District ve alt binaların uygun çıktısı; bina yuvası | City'nin toplam district kapasitesi |
| Capital District seviyesi | Merkez yuvası ve uygun merkez stok tabanı | City seviyesiyle aynı kayıt değildir |
| City seviyesi | Normal çocuk district kapasitesi | Tek başına her binaya gizli üretim katsayısı vermez |
| Gezegen seviyesi | City kapasitesi | Fuel/Rare araştırması ve erken üretim erişimi |

Bir City Lv2 iken onun Capital District'i Lv1 olabilir. Dünya Spaceport'u iki yuva istediği için gereken işlem Capital Lv2'dir; City Lv2 adının benzemesi bu fiziksel yuva koşulunu karşılamaz.

Normal district sayısı ile bina sayısı da farklıdır. Üç Mine aynı Production District içinde üç bina adetidir, City'nin üç district yuvasını kullanmaz.

### 13.2. Tip 0 kuruluş tabanları

| Yerleşim | Tek kuruluş kredi tabanı | Stok tabanı /20 sn | Etkin kapasite tabanı | İlk yük |
| --- | ---: | --- | --- | ---: |
| City ve otomatik Capital | İlk City0; sonraki tekrar tarifesi | 20 kredi +4/3 Science | 15.000 nüfus +8 enerji | 2.000 |
| Production District | 300 | 10 seçili yerel ham | Yok | 500 |
| Science District | 300 | 2 Science | Yok | 500 |
| Commercial District | 300 | 10 kredi | Yok | 500 |
| Residential District | 300 | Yok | 1.500 nüfus | 0 |
| Energy District | 300 | Yok | 3 enerji | 500 |

City kuruluş tabanı tek kez eklenir. Otomatik merkez kuruldu diye ikinci15.000 kapasite, ikinci8 enerji veya ikinci20 kredi geliri verilmez.

15.000 konut ve8 enerji City kuruluş kapasitesidir. City seviyesinin çocuk kapasitesini artırması bunları yeniden kurmaz veya seviyeye göre ikinci kez çarpmaz.

20 kredi ve4/3 Science merkez stok tabanıdır; uygun Capital seviye ve çıktı etkilerini bir kez alır. City seviyesinin kendisi bu tabanlara ikinci bir seviye çarpanı eklemez.

### 13.3. District seviye formülleri

| Alan | Formül |
| --- | --- |
| Geçerli seviye L | 1 ile10 arası |
| Çıktı katsayısı | 1,25 üzeri(L-1) |
| Normal bina yuvası | 3 +2 ×(L-1) |
| Capital bina yuvası | L |
| L'denL+1'e kredi | 250 ×1,25 üzeri(L-1) |
| L'denL+1'e ek nüfus yükü | 500 ×1,25 üzeri(L-1) |
| Residential ek seviye yükü | 0 |
| Yükseltme süresi | 5 ×hedef seviye saniye |

District seviyesi kendi tabanını ve içindeki her uygun bina çıktısını birer kez etkiler. Binaların çalışan, enerji talebi, stok girdisi, bakım faturası veya depo hacmi bu üretim katsayısıyla otomatik büyümez.

Enerji üreticisinin arzı ve konutun kapasitesi uygun çıktı olarak district seviye çarpanını alabilir. Sabit çalışan ve talep değerleri kartta kalır. Ayrı City kuruluş kapasitesi bu büyümeyle ikinci kez hesaplanmaz.

Normal districtin komşusunun aynı seviyede olması veya yol bağlı başka bir districtin önce yükseltilmesi gerekmez. Yükseltme için kendi seviye üst sınırı, açık bedel ve devam eden işlem uygunluğu yeterlidir.

### 13.4. Her district seviyesinin çıktısı ve yuvası

| Seviye | Çıktı çarpanı | Normal yuva | Capital yuvası | 10 tabanlı ham /20 sn | 2 tabanlı Science /20 sn |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | ×1 | 3 | 1 | 10 | 2 |
| 2 | ×1,25 | 5 | 2 | 12,5 | 2,5 |
| 3 | ×1,5625 | 7 | 3 | 15,625 | 3,125 |
| 4 | ×1,95313 | 9 | 4 | 19,53125 | 3,90625 |
| 5 | ×2,44141 | 11 | 5 | 24,41406 | 4,88281 |
| 6 | ×3,05176 | 13 | 6 | 30,51758 | 6,10352 |
| 7 | ×3,8147 | 15 | 7 | 38,14697 | 7,62939 |
| 8 | ×4,76837 | 17 | 8 | 47,68372 | 9,53674 |
| 9 | ×5,96046 | 19 | 9 | 59,60464 | 11,92093 |
| 10 | ×7,45058 | 21 | 10 | 74,50581 | 14,90116 |

Tablodaki miktarlar gövde ham katsayısı×1 referansıyla, konum, destek, araştırma, nadirlik ve global açıklar uygulanmadan önceki seviye örneğidir. Gerçek çıktı kartında sonraki etkiler ayrı açıklanır.

### 13.5. District yükseltme bedelleri

| Geçiş | Kredi | Normal district ek yük | Residential ek yük | Süre | Açılan normal yuva |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1 ->2 | 250 | 500 | 0 | 10 sn | +2 |
| 2 ->3 | 312,5 | 625 | 0 | 15 sn | +2 |
| 3 ->4 | 390,625 | 781,25 | 0 | 20 sn | +2 |
| 4 ->5 | 488,28125 | 976,5625 | 0 | 25 sn | +2 |
| 5 ->6 | 610,35156 | 1.220,70313 | 0 | 30 sn | +2 |
| 6 ->7 | 762,93945 | 1.525,87891 | 0 | 35 sn | +2 |
| 7 ->8 | 953,67432 | 1.907,34863 | 0 | 40 sn | +2 |
| 8 ->9 | 1.192,0929 | 2.384,18579 | 0 | 45 sn | +2 |
| 9 ->10 | 1.490,11612 | 2.980,23224 | 0 | 50 sn | +2 |

Lv1'denLv10'a bütün yükseltmelerin yuvarlama öncesi toplamı6.450,5806 kredi ve12.901,16119 ek yüktür. Normal districtin ilk500 kuruluş yükü eklenirse toplam altyapı yükü13.401,16119 olur. Residential'da kuruluş ve seviye yükü0 kalır.

Capital, kuruluşta City'nin2.000 yükü içinde olduğundan ilk500 yükü almaz. Kendi seviye yükseltmelerinin ek yüklerini ise bir kez alır.

### 13.6. Yuva rezervi ve bitiş

İnşaatı başlayan her bina yuvasını hemen rezerve eder. İki yuvalı iki bina, aynı son iki yuvaya eşzamanlı olarak teklif alıp ikisi de kurulamaz.

District yükseltmesi tamamlanana kadar mevcut seviye yuva sayısı geçerlidir. Gelecek iki yuva, yükseltme sürerken hazırmış gibi kullanılamaz.

Yükseltme bitince yeni çıktı katsayısı sonraki yeni ücretli üretim çevrimine girer. Başlatılmış çevrimin vaat edilmiş çıktısı geriye dönük iki kez artırılmaz.

Aynı anda aynı districtte ikinci bir seviye yükseltmesi başlatılmaz. Kredi ve ek nüfus rezervi bir kez alınır. Kayıt yükleme bu işlemi yeniden başlatıp yeniden ücretlendirmez.

City ve gezegen seviyeleri için bu hedef tabanda maksimum10 uygulanır. Bu sayısal sınır ilk denge ayarıdır; kapasite ve fiziksel harita sınırlarının aynı değişken olduğu anlamına gelmez.

### 13.7. City çocuk kapasitesi

**Normal district kapasitesi =3 +2 ×(City seviyesi -1).**

Capital bu normal çocuk kotasına dahil değildir. Normal district kuruluş planları ve manuel kuruluş aynı kotayı tüketir.

City kapasitesi sayarken inşası başlamış district yuvası da rezerve kabul edilir. City seviyesi için gereken tamamlanmış district seviyeleri hesabında ise henüz bitmemiş kuruluş veya yükseltme sayılmaz.

| City seviyesi | Normal district kapasitesi | Otomatik merkez | Başlangıca göre ek normal district |
| ---: | ---: | ---: | ---: |
| 1 | 3 | 1 Capital | 0 |
| 2 | 5 | 1 Capital | 2 |
| 3 | 7 | 1 Capital | 4 |
| 4 | 9 | 1 Capital | 6 |
| 5 | 11 | 1 Capital | 8 |
| 6 | 13 | 1 Capital | 10 |
| 7 | 15 | 1 Capital | 12 |
| 8 | 17 | 1 Capital | 14 |
| 9 | 19 | 1 Capital | 16 |
| 10 | 21 | 1 Capital | 18 |

City'nin konumu fiziksel ve ekonomik ilişkiler için gerçek kayıttır. Daha büyük bir kapasite, uygun yüzey alanı yoksa sınırsız kuruluş yeri oluşturmaz.

### 13.8. City yükseltme eşiği

Hedef seviye n için gereken tamamlanmış normal district seviyeleri toplamı **n ×(n+1) /2**'dir.

Capital bu ilerleme toplamına dahil değildir. Aynı City'ye ait tamamlanmış normal districtlerin mevcut seviyeleri toplanır. Bina adedi, ham stoğu ve diğer City'nin seviyeleri bu yerel eşiğin yerine geçmez.

**Kredi =1.000 ×1,50 üzeri(n-2).**

**Ek yük =2.000 ×1,25 üzeri(n-2).**

**Süre =10 ×n saniye.**

| City hedefi | Gereken normal district seviye toplamı | Kredi | Ek nüfus yükü | Süre | Bitişte normal çocuk kapasitesi |
| --- | ---: | ---: | ---: | ---: | ---: |
| Lv2 | 3 | 1.000 | 2.000 | 20 sn | 5 |
| Lv3 | 6 | 1.500 | 2.500 | 30 sn | 7 |
| Lv4 | 10 | 2.250 | 3.125 | 40 sn | 9 |
| Lv5 | 15 | 3.375 | 3.906,25 | 50 sn | 11 |
| Lv6 | 21 | 5.062,5 | 4.882,8125 | 60 sn | 13 |
| Lv7 | 28 | 7.593,75 | 6.103,51563 | 70 sn | 15 |
| Lv8 | 36 | 11.390,625 | 7.629,39453 | 80 sn | 17 |
| Lv9 | 45 | 17.085,9375 | 9.536,74316 | 90 sn | 19 |
| Lv10 | 55 | 25.628,90625 | 11.920,92896 | 100 sn | 21 |

Lv2 için üçLv1 normal district toplam3 sağlar. Alternatif olarak birLv2 ile birLv1 normal district de3 sağlar. BirLv3 normal district de3 sağlar; yalnız kurulu bina sayısını artırmak bu toplamı artırmaz.

City Lv3 için gereken6, önceki yükseltmede sayılan3'e ayrıca6 daha ödeme değildir. O andaki toplam seviyenin6'ya ulaşması gerekir.

City yükseltme yükleri birikir. Lv1 kuruluş yükü2.000, Lv2 ek yükü2.000, Lv3 ek yükü2.500 ise City'nin bu üç kayıttan toplam yükü6.500 olur. Çocuk district ve bina yükleri bunun üzerine eklenir.

Yükseltme bitene kadar City'nin eski çocuk kotası korunur. İnşa başlaması gelecekteki kotayı erken kullanma hakkı vermez.

### 13.9. Gezegen City kapasitesi

**Normal City kapasitesi =gezegen seviyesi +1.**

| Gezegen seviyesi | City kapasitesi |
| ---: | ---: |
| 1 | 2 |
| 2 | 3 |
| 3 | 4 |
| 4 | 5 |
| 5 | 6 |
| 6 | 7 |
| 7 | 8 |
| 8 | 9 |
| 9 | 10 |
| 10 | 11 |

Orbit merkez rolünün hangi kotayı kullandığı ilgili ölçek/merkez tanımında açık kaydedilir. Aynı fiziksel merkez hem yüzey City'si hem Orbit City'si diye iki ücretsiz kabuk kapasitesi üretemez.

Bu kapasite uygun yüzey, fiziksel kuruluş aralıkları ve medeniyetin oynanabilirlik iznini ortadan kaldırmaz. Kilitli Tip1 önizlemesi City kurma veya yükseltme izni vermez.

### 13.10. Gezegen yükseltme eşiği ve isimli faturalar

Hedef seviye n için gereken tamamlanmış City seviyeleri toplamı **2 ×n -1**'dir. Devam eden City yükseltmesinin hedef seviyesi bitmeden toplamda kullanılmaz.

Lv2-5 kredi tabanı **2.000 ×1,50 üzeri(n-2)**'dir. Lv6-10 devamında kredi ve isimli malzemeler aşağıdaki açık ölçek kuralından türetilir. Bütün satırlar ilk sayısal denge tabanıdır.

| Gezegen hedefi | Gereken City seviyeleri toplamı | Kredi | Tam isimli malzeme | Süre |
| --- | ---: | ---: | --- | ---: |
| Lv2 | 3 | 2.000 | 100 Ferrite | 10 sn |
| Lv3 | 5 | 3.000 | 150 Ferrite +10 Goods | 15 sn |
| Lv4 | 7 | 4.500 | 225 Ferrite +20 Goods | 20 sn |
| Lv5 | 9 | 6.750 | 300 Ferrite +50 Moonstone +10 Fuel +5 Rare | 25 sn |
| Lv6 | 11 | 10.125 | 450 Ferrite +75 Moonstone +15 Fuel +8 Rare | 30 sn |
| Lv7 | 13 | 15.188 | 675 Ferrite +113 Moonstone +23 Fuel +12 Rare | 35 sn |
| Lv8 | 15 | 22.782 | 1.013 Ferrite +169 Moonstone +34 Fuel +17 Rare | 40 sn |
| Lv9 | 17 | 34.172 | 1.519 Ferrite +254 Moonstone +51 Fuel +26 Rare | 45 sn |
| Lv10 | 19 | 51.258 | 2.279 Ferrite +380 Moonstone +76 Fuel +38 Rare | 50 sn |

Gezegen yükseltmesi için ek altyapı nüfus yükü tanımlı değildir. Bu tabloda sadece ücret ve süre vardır; gizli bir nüfus harcı eklenmez.

Lv5'in50 Moonstone ödemesi Ay sonrası tercihtir. Bu yükseltme ilk Ay seferine veya Fuel/Rare üretimine geri dönük şart yapılmaz.

Lv6-10 için k=1,50 üzeri(hedef seviye-5). Kredi yukarı yuvarla(6.750 ×k); Ferrite yukarı yuvarla(300 ×k); Moonstone yukarı yuvarla(50 ×k); Fuel yukarı yuvarla(10 ×k); Rare yukarı yuvarla(5 ×k). Her malzeme ayrı ayrı tam birime, kredi de bu üst seviye tarifinde tam krediye yukarı yuvarlanır. Süre5 ×hedef seviye saniyedir.

Bu devam tarifleri özel denge başlangıcıdır. Lv5'e ayrıca Goods eklenmediğinden Lv6-10'a da görünmez Goods faturası eklenmez. Sadece formülün sonucunda yazılı kaynaklar ödenir.

### 13.11. Ortak çıktı sözleşmesi

Bir varlığın gerçek stok çıktısı aşağıdaki parçalarla hesaplanır:

1. Katalogdaki tek model çıktı tabanı.
2. Bu ücretli çevrimde çalışan birim adedi.
3. Ebeveyn district seviye çarpanı; gerçek ham çıkarımında ayrıca gövde ham katsayısı.
4. Tekilleştirilmiş coğrafya toplamı için1 +toplam.
5. Uygun yakınlık, uzaklık ve merkez toplamı için1 +toplam.
6. Uygun araştırma ve destek toplamı için1 +toplam.
7. Stok çıktısıysa global nüfus verimi.
8. Enerji isteyen stok üreticisiyse global enerji verimi.
9. Hamdan işlenmiş ürüne dönüşümse seçilen mineralin nadirlik verimi.

Bu çarpım sırasının anlamı her etki grubunun bir kez yer almasıdır. Aynı yüzdeleri iki farklı grupta tekrar kaydetmek yasaktır.

Coğrafya, **özellik türü +etkilenen çıktı ailesi** anahtarıyla tekilleştirilir. City dağ yakınından+%10, district dağ üzerinden+%20 alıyorsa dağ katkısı+%20'dir. Farklı bir krater etkisi bununla toplanabilir.

Ailesiz Energy District tabanı kendi konumunda en güçlü uygun enerji ailesi profilini bir kez kullanır. Rüzgâr, gelgit, jeotermal ve güneş yüzdeleri bu tek tabanda gelişigüzel üst üste eklenmez. Her bina ise kendi açık enerji ailesini kullanır.

Tier çarpanı ayrı bir onuncu katman değildir. Katalog tabanında vardır. Bina level çarpanı yoktur. Üst görünüm özeti veya alt plan toplamı da çarpımın ek parçası değildir.

### 13.12. Ebeveyn ve alt ekonomi bir kez çalışır

Bir Production Districtin10 taban hamı ile içindeki Mine'ın10 hamı iki meşru üreticidir. Bunların toplamını gösteren20 hamlık üst kart ise üçüncü üretici değildir.

Üst ölçeğe geçildiğinde aynı gerçek kayıtlar korunur. Özet paneli ve mikro panel aynı ekonomik kimlikleri gösterir. Oyuncu büyütülmüş görünümde aynı yatırımı ikinci bir bağımsız simülasyonda çalıştırmaz.

Gerçek alt binalar için üretim zaten hesaplanıyorsa otomatik planın fiyatı veya gösterim gücü adına aynı gelire ikinci bir bedelsiz district geliri eklenmez. Districtin kendi açık tabanı ayrı tanımlıysa yalnız bu açık taban eklenir.

### 13.13. Basit örnek: Institute

Varsayımlar: tek Institute,12 Science tabanı, districtLv2, toplam+%20 coğrafya, toplam+%20 yakınlık/uzaklık/merkez, +%10 araştırma/destek, nüfus verimi%75 ve yeterli enerji.

| Hesap adımı | Science /20 sn |
| --- | ---: |
| Katalog | 12 |
| DistrictLv2:×1,25 | 15 |
| Coğrafya:×1,20 | 18 |
| Konum ilişkileri:×1,20 | 21,6 |
| Araştırma/destek:×1,10 | 23,76 |
| Nüfus verimi:×0,75 | 17,82 |

Bu çevrimin gideri yine1/3 Goods'dur. Çalışan750, enerji talebi3 olarak kalır. Çıktı17,82 iken ikinci kez tier×3 uygulanmaz.

### 13.14. Basit örnek: Moonstone ile Goods

Tek temel Goods Factory,4 Moonstone öder. Taban2 Goods, Moonstone nadirliği×1,75 olduğu için brüt3,5 Goods verir.

Aynı bina districtLv2 içindeyse ve başka bonus/açık yoksa3,5 ×1,25 =4,375 Goods verir. Girdi4 Moonstone olarak kalır.

İki aynı fabrika aynı şartlarda8 Moonstone öder ve8,75 Goods verir. İkinci fabrika için ayrı kurulum yapılmış olduğundan çalışan500 ve enerji talebi4'tür.

Üçüncü fabrika varsa ama stok yalnız8 Moonstone ise iki birim çalışır. Üçünün giderini ödenmiş sayıp üçünü çalıştırmak veya hiçbirini başlatmamak yerine üçüncü birim bekler.

### 13.15. Basit örnek: Ay'da gerçek çıkarım görevi

Ay'ın ilk Production Districtinin katalog tabanı10'dur. Ay gövde katsayısı×1,30 olduğu için başka bonus ve açık yoksa20 saniyede13 Moonstone çıkarır.100 gerçek çıkarım eşiğine8 tam çevrimde,160 saniyede ulaşır ve toplam104 üretmiş olur.

İçine bir Mine eklenirse district tabanı10 ve Mine10 birlikte20 katalog hamıdır; Ay katsayısıyla26 Moonstone /20 sn olur. Aynı varsayımla100 eşiği4 tam çevrim,80 saniye sürer ve104 gerçek üretim oluşur. Gövde×1 tarafsız referansında aynı çift20/20 sn ve5 çevrim verir.

Bu süre yerleşim inşaatı, ilk seçimin yapılması ve stok çevriminin ne zaman başladığı hariç aritmetik örnektir. Ay'a ulaşma veya tüm oyun temposu ölçümü değildir.

Trade ile100 Moonstone almak görevi ilerletmez. Başka role verilmiş yan ham katkısı da gerçek çıkarım yeteneği taşımıyorsa bu sayacı ilerletmez.

### 13.16. Son sefer için stok kapasitesi örneği

| İş | Moonstone | Goods | Fuel | Rare | Kredi |
| --- | ---: | ---: | ---: | ---: | ---: |
| Lunar Spaceport | 200 | 50 | 30 | 10 | 8.000 |
| Gelişmiş roket | 1.200 | 30 | 120 | 40 | 12.000 |
| Toplam | 1.400 | 80 | 150 | 50 | 20.000 |

1.200 Moonstone tek faturasını500 taban depoyla ödemek mümkün değildir. Bir Warehouse ile ham tavanı1.500 olur ve bu tek ödeme yapılabilir. Warehouse Dünya'da da Ay'da da bulunabilir.

200 Moonstone tesis ödemesi önce yapılmışsa sonraki1.200 ödemesi için yeniden stok biriktirilir. İki faturanın toplamının aynı anda1.400 stokta tutulması zorunlu değildir.

Kapasite kaynağının kimliği zorunlu görev kapısı değildir. Toplam tavanı yeterince artıran meşru depo/destek seçeneği aynı ihtiyacı karşılayabilir.

### 13.17. Ürünlerin ham karşılığı örneği

Bakım, bonus, açık ve tam çevrim yuvarlaması hariç100 Goods +150 Fuel +50 Rare üretimini karşılaştıralım.

| Ürün | İstenen miktar | Ferrite ham karşılığı | Moonstone teorik ham karşılığı |
| --- | ---: | ---: | ---: |
| Goods | 100 | 200 | 114,285714 |
| Fuel | 150 | 600 | 342,857143 |
| Rare | 50 | 600 | 342,857143 |
| Toplam | Üç ürün | 1.400 Ferrite | 800 Moonstone |

Bu, sürekli oran karşılaştırmasıdır. Gerçek temel tariflerde gereken tam çevrim sayıları Goods için29, Fuel için43, Rare için29'dur. Moonstone girdileri116 +344 +348 =808 olur; çıktılar101,5 Goods,150,5 Fuel ve50,75 Rare'dır.

Büyük model, bakım gideri veya global açık kullanılırsa gerçek tüketim değişir. Örneğin Regolit planının1/3 Goods bakımı yukarıdaki bakımsız temel tarif örneğinde yoktur.

### 13.18. Basit başlangıç bütçesi örneği

Yeni oyunda3.000 kredi,450 Science ve sıfır malzeme vardır. İlk City ücretsizdir.

| İşlem | Kredi ödemesi | Kalan kredi |
| --- | ---: | ---: |
| İlk City | 0 | 3.000 |
| İlk Production District | 300 | 2.700 |
| İlk Science District | 300 | 2.400 |
| İlk Energy District | 300 | 2.100 |
| Production içine Mine | 200 | 1.900 |
| Production içine Goods Factory | 300 | 1.600 |
| Science içine Lab | 150 | 1.450 |
| Energy içine Solar Array | 150 | 1.300 |

Farklı district aileleri birbirinin tekrar sayacını yükseltmez. Bu tabloda üç aile de ilk adet300 üzerinden kurulmuştur.

Kalan450 Science, oyuncu isterse Ticaret Erişimi150 +Sivil Girişimler150 +Serbest Araştırma150 üçlüsüne ayrılabilir. Ortak düğüm ve aynı Nüfus ana dalı nedeniyle bu örnek çapraz dal artışıyla453'e çıkmaz.

Bu zorunlu tutorial sırası değildir. Tek bir örnek, ilk yatırımın bütçeye sığdığını ve temel işleme başlamadan önce kendi ürününü kuruluşta istemediğini gösterir.

### 13.19. Seviye ve kapasite için kaynak haritası

| Kaynak noktası | Hedef uygulama işi |
| --- | --- |
| C:/Users/drosm/Voidle/scripts/game/DistrictDef.gd:77 | Doğrusal1 +0,5 ×(L-1) yerine1,25 üzeri(L-1). |
| C:/Users/drosm/Voidle/scripts/game/PlanetProgress.gd:119 | Normal3 +2 ×(L-1), CapitalL yuvası; iki yuvalı kart rezervi. |
| C:/Users/drosm/Voidle/scripts/game/Leveling.gd:26 | District250 ×1,25 tabanı. |
| C:/Users/drosm/Voidle/scripts/game/Leveling.gd:30 | Yol komşusu seviye kapısı kaldırılır. |
| C:/Users/drosm/Voidle/scripts/game/Leveling.gd:62 | City ilerleme toplamından Capital hariç tutulur. |
| C:/Users/drosm/Voidle/scripts/game/Leveling.gd:70, 73, 76 | City üçgensel eşik,1.000/1,50 kredi ve2.000/1,25 yük. |
| C:/Users/drosm/Voidle/scripts/game/Leveling.gd:134, 145 | GezegenL+1 City kapasitesi ve2n-1 eşiği korunur. |
| C:/Users/drosm/Voidle/scripts/game/PlanetProgress.gd:63, 69 | City10 ×n ve district5 ×n süreleri. |
| C:/Users/drosm/Voidle/scripts/game/PlanetProgress.gd:72 | Generic ham faturası yerine tam isimli gezegen tarifleri. |
| C:/Users/drosm/Voidle/resources/districts/city_district.tres:16 | Merkez20 kredi +4/3 Science /20 sn hedef tabanı. |
| C:/Users/drosm/Voidle/resources/districts/mining_district.tres:18 | Production10 seçili ham /20 sn hedef tabanı. |
| C:/Users/drosm/Voidle/resources/districts/science_district.tres:17 | Science2 /20 sn hedef tabanı. |
| C:/Users/drosm/Voidle/resources/districts/generator_district.tres:17 | Energy3 etkin arz hedef tabanı. |
| C:/Users/drosm/Voidle/resources/districts/residential_district.tres:17 | Residential1.500 etkin kapasite tabanı. |
| C:/Users/drosm/Voidle/resources/districts/commercial_district.tres:17 | Commercial10 kredi /20 sn tabanı. |

### 13.20. Uygulama işlerinin sırası

1. Canonical kaynak ve model kimliklerini, isimli fatura şemasını ve tekil sayaç anahtarlarını kur.
2. Global stok ve kapasite hesaplarını tek yetkili ekonomi kaynağında topla.
3. Birim bazlı cyclePaid, seçili girdi ve vaat edilmiş çıktı kaydını kur.
4. Nüfus/enerji açıklarını sabit çevrimde çıktı verimine dönüştür.
5. District/City/gezegen seviye, yuva ve rezerv kurallarını aynı satın alma doğrulamasına bağla.
6. Bütün49 katalog modelini ve Regolit planını hedef veriyle tanımla.
7. Destek tekilliği ve uygun ebeveyn rolünü bütün manuel/toplu/taşıma komutlarında uygula.
8. Üst görünüm özetlerini gerçek alt üretimin toplamı yap; ikinci gelir oluşturma.
9. Aynı20 saniye penceresinde brüt çıktı, tam gider, kapasite ve bekleme nedenlerini göster.
10. Sonradan çalıştırılacak kullanıcı doğrulamasına kaynakla hedef arasındaki açık fark listesini bırak.

Bu bölümün hazırlanması oyun dosyalarının değiştirildiği veya oyun içinde doğrulandığı anlamına gelmez. Hedef kurallar, ilk sayısal tabanlar ve uygulanacak kaynak noktaları birlikte verilmiştir.

<a id="bolum-14"></a>

## 14. Tip 1 sistem coğrafyası ve elli district

### 14.1. Sistem konumu ile yüzey konumu ayrı çalışır

Tip 1 güneş sistemi, gezegen, City ve district katmanlarından oluşur. City ve district gerçek yüzey konumlarını korur.

Gezegenin yıldız sistemindeki konumu makro özelliktir. City'nin dağ, orman veya kıyı üzerindeki konumu mikro özelliktir. Districtin kendi yüzey konumu ayrıntıda çalışmayı sürdürür.

Makro özellik bir districti uzayda konumlandırmaz. Asteroit kuşağına uygun bir district, seçilmiş gezegenin yüzeyinde kurulur; kuşak içinde ayrı bir madencilik gemisi veya uzay districti yaratılmaz.

### 14.2. Dokuz sistem özelliği

| Kimlik | Özellik | Tam uygunluk koşulu | Görünen bilgi |
| --- | --- | --- | --- |
| system_inner_light | Yoğun ışık kuşağı | Ortalama yıldız uzaklığı 0,8 × r0 AU'dan küçük | Yıldız çevresindeki parlak iç halka |
| system_temperate | Ilıman kuşak | 0,8 × r0 AU dahil, 1,6 × r0 AU dahil | Ayrı renkle gösterilen orta halka |
| system_cold | Soğuk dış kuşak | 1,6 × r0 AU'dan büyük | Soluk dış bölge |
| system_asteroid_belt | Asteroit kuşağı | Kayıtlı kuşağın alanı içinde | Görünen kayalık halka |
| body_strong_tides | Güçlü gelgit gövdesi | Gövdenin güçlü gelgit etiketi var | Uydu düzeni ve açık gelgit simgesi |
| system_radiation | Radyasyon kuşağı | Kayıtlı görünür radyasyon alanında | Işıyan kuşak ve radyasyon simgesi |
| body_ice | Buzlu gövde | Gövdenin buzlu etiketi var | Buzlu yüzey ve gövde simgesi |
| body_volcanic | Volkanik gövde | Gövdenin volkanik etiketi var | Lavlı yüzey ve gövde simgesi |
| body_airless | Atmosfersiz gövde | Gövdenin atmosfersiz etiketi var | Atmosfer halosu yokluğu ve açık simge |

r0 yıldızın oyun içi ışık gücünden elde edilen boyutsuz ölçek katsayısıdır. Güneş benzeri başlangıç yıldızında r0 = 1 olur. AU, eşik ifadesinde ayrıca kullanılan uzaklık birimidir.

    r0 = karekök(yıldız ışık gücü / Güneş benzeri referans ışık gücü)

Yıldız gücü kayıtlı ve oyuncunun okuyabildiği bir sistem niteliğidir. Haritadaki halka bu hesapla aynı kaynaktan üretilir. Bütün yıldızlarda aynı ham AU aralığı kullanılıyormuş gibi davranılmaz.

Bu halkalar ekonomik oyun bölgeleridir. Sayısal sınırlar iklim, yaşanabilirlik veya gerçek fizik simülasyonunun sonucu olarak sunulmaz.

Üç yıldız kuşağı bir gövdenin merkez noktasında yalnız bir tam ana kuşak verir. Komşu kuşağın sınırına yakınlık ayrı yarım uygunluk sağlayabilir; ilgili çıktı rolleri açıkça filtrelenir.

### 14.3. Makro üç uygunluk kademesi

Alan özelliğinde:

| Durum | Uygunluk q |
| --- | ---: |
| Alanın dışında, sınırdan 0,10 AU'dan uzak | 0 |
| Alan dışında, sınıra uzaklık 0,10 AU veya daha az | 0,5 |
| Alan içinde | 1 |

Alan içindeki bütün noktalar tam pay, yakın kuşaktaki bütün noktalar yarım pay alır. Gizli sürekli yoğunluk puanı yoktur.

Gövde etiketleri ikilidir: güçlü gelgit, buzlu, volkanik ve atmosfersiz etiketleri ya vardır ya yoktur. Bunlarda q yalnız 0 veya 1 olur. Komşu gövdenin buzlu olması, seçilmiş gezegeni yarım buzlu yapmaz.

İki alternatiften birini isteyen modelde q en yüksek uygun alternatiften alınır. Soğuk kuşak veya buzlu gövde şartı iki kez aynı model bonusu vermez.

İki koşulu birlikte isteyen modelde iki koşul da geçerli olmalıdır. Ortak q, gerekli alan koşullarının en düşük payıdır. İkili gövde veya yüzey şartı geçersizse q = 0 olur.

Özel districtin yerleşim teklifinde uygunluk, ana üretim farkı, ek tüketim ve fiyat birlikte gösterilir.

### 14.4. Ekonomik yörünge verisi

Yıldız uzaklığı, kuşak uzaklığı ve gezegenler arası konum bilgisi kayıtlı ortalama ekonomik yörünge verisinden okunur. Görsel dönme, gün/gece veya dekoratif yörünge animasyonu ekonomik bonus değiştirmez.

Doğal gövdenin mineral kümesi yıldız kuşağına taşındı diye yeniden üretilmez. Asteroit kuşağına uygunluk yeni mineral veya asteroit çıkarım kaynağı eklemez.

Tip 1'in oynanabilir ilk sisteminde Cinderite ve Cryolite erişimini sağlayan geçerli gövdeler bulunur. Kaynak yolu yalnız nadir bir rastgele harita sonucuna bağlanmaz.

Yeni kaynağın ilk uygun çıkarım yapısı, kendi henüz keşfedilmemiş hammaddesini kuruluşta istemez.

### 14.5. Temel ekonomik referans

Bütün stok giriş ve çıkışları 20 ekonomi saniyesi üzerinden verilir. Enerji sürekli denge, konut kapasitedir. Konut veya enerji her yirmi saniyede stoklanmaz.

Tip 1 ortak görünmez medeniyet çarpanı S1 = 1,00'dır. Üst ölçeğin geliri gerçek alt içerikten gelir. Yalnız medeniyet numarası değişti diye bütün binalara ücretsiz kat artışı veya büyük bir fiyat duvarı eklenmez.

Aşağıdaki referans, boş bir City'de modelin ilk kuruluşunu ve gerçek alt bina planını tanımlar. District seviyesi 2'dir; normal 5 bina yuvası vardır. Tablo, nötr gövde çıkarım katsayısı 1 ve mineral işleme verimi 1 içindir. Dış coğrafya, komşu/merkez/uzaklık, araştırma ve stok/enerji/nüfus cezaları bu nominal değerlere henüz uygulanmamıştır.

| Profil | Gerçek district ve bina alt içeriği | İlk paket kredisi | Kuruluş malzemesi | Enerji dengesi | Nüfus yükü |
| --- | --- | ---: | --- | ---: | ---: |
| RE | Lv2 Energy; 2 Solar Matrix | 1.540 | 60 Ferrite + 10 Goods | +26,25 | 2.500 |
| RP | Lv2 Production; Mine, Cevher Ayıklama Atölyesi, Kompakt Yakıt Atölyesi, Rare Forge | 2.700 | 30 Ferrite + 5 Goods | -12 | 2.500 |
| RS | Lv2 Science; 2 Research Institute | 1.540 | 60 Ferrite + 10 Goods | -6 | 2.500 |
| RR | Lv2 Residential; 2 Apartment Towers | 1.342 | 60 Ferrite + 10 Goods | -4 | 0 |
| RC | Lv2 Commercial; 2 Trade Hub | 1.540 | 60 Ferrite + 10 Goods | -6 | 2.500 |

Paket kredisi tek ekonomik toplamdır. İçindeki district kuruluşu 300, ilk seviye yükseltmesi 250 kredidir. İki aynı modelin çocuk fiyatında ikinci adet kendi 1,20 tekrar katsayısını kullanır.

RE örneği: 300 + 250 + 450 + 540 = 1.540. Aynı toplam ayrıca City'ye tekrar maliyet yazılmaz.

RP örneği: 300 + 250 + 200 + 900 + 450 + 600 = 2.700. Beş yuva kullanır: Mine 1, Cevher Atölyesi 2, Kompakt Fuel 1, Rare Forge 1.

| Profil | Bonuslar öncesi gerçek çıktı | 20 saniyelik işletme girdisi |
| --- | --- | --- |
| RE | +26,25 enerji kapasitesi | 2/3 Goods |
| RP | +25 ham, +7,5 Goods, +2,5 Fuel, +1,25 Rare | 32 seçilmiş ham + 1/3 Goods |
| RS | +32,5 Science | 2/3 Goods |
| RR | +20.625 konut kapasitesi | 2/3 Goods |
| RC | +162,5 kredi | 2/3 Goods |

RP bir işleme paketidir; kendi ham çıkarımı bütün işleme girdisini tek başına karşılamak zorunda değildir. Girdi azsa yalnız beslenebilen çocuklar çalışır. Mine veya districtin girdisiz ham tabanı, fabrika girdisi yok diye durmaz.

RP'nin Goods, Fuel ve Rare tabanları seçilmiş ham kaynağın nadirlik verimini henüz içermez. Verim çıktı hesabına bir kez uygulanır. Ham çıkarımında nadirlik nedeniyle ikinci miktar çarpanı yoktur. Ay'ın 1,30 ham çıkarım katsayısıyla RP 32,5 Moonstone/20 sn çıkarır. Moonstone işleme verimi 1,75 olduğunda aynı paketin işleme çıktıları 13,125 Goods, 4,375 Fuel ve 2,1875 Rare/20 sn olur. Tarif girdisi 32 Moonstone +1/3 Goods olarak kalır. Ay çıkarım katsayısı ile mineral işleme verimi farklı aşamalarda birer kez uygulanır.

Bir çocuk araştırmayla kilitliyse hazır plan onu bedelsiz kurmaz. Teklif yalnız erişilebilir gerçek alt içerikle hazırlanır. Tablodaki tam referans çıktı, eksik bina varken gerçek gelir olarak gösterilmez. Kısmi plan, tam paketin basit adet oranı değildir: Lv2 Residential tabanı 1.875 ve bir gerçek Apartment katkısı 9.375 ise toplam 11.250 konuttur. Lv2 Energy tabanı 3,75 ve bir gerçek Solar Matrix katkısı 11,25 ise toplam 15 enerjidir. Tam paketi ikiye bölerek 10.312,5 konut veya 13,125 enerji yazılmaz.

İlk aile seçimi bütün ileri modelleri satın almış sayılmaz. Küçük ve genel başlangıç planları erişilebilir kalır; Güncelle daha yoğun içeriği gerçek fark bedeliyle önerir.

### 14.6. Host katkısı

Her yeni Tip 1 districti kendi Host A'sından sabit bir referans katkı alır. Katkı, City'nin o an büyüyen toplam üretiminin yüzdesi değildir.

| Host A | District başına sabit katkı |
| --- | --- |
| Energy | RE enerji referansının %10'u: +2,625 enerji |
| Production | RP ham çıkarım referansının %10'u: +2,5 seçilmiş ham / 20 sn |
| Science | RS Science referansının %10'u: +3,25 Science / 20 sn |
| Residential | RR konut referansının %10'u: +2.062,5 konut |
| Commercial | RC kredi referansının %10'u: +16,25 kredi / 20 sn |

Production host katkısı ücretsiz Goods, Fuel veya Rare vermez. Yalnız oyuncunun seçtiği, o gövdede keşfedilmiş ve çıkarılabilir ham kaynağa gider. Uygun seçilmiş ham kaynak yoksa bu akışın çıktısı 0 olur; gizli kaynak adı veya simgesi arayüzde açılmaz. Destek akışı ilk keşif ve ilk 100 Moonstone görevine yazılmaz.

Host katkısı ilk keşfi açmaz. Yerel gerçek çıkarım görevinin 100 Moonstone sayacına katkı vermez. Bu görev uygun gerçek çıkarıcıların üretimini sayar.

Katkı districtin kendi sabit destek akışıdır. Anahtar, district kimliği + host_support + çıktı rolüdür. Üst City veya gezegen toplamında ikinci kez verilmez.

Host katkısı hiçbir yeni child bina oluşturmaz. Referans profil paketinin adı, o referansın binalarının ikinci kez kurulması anlamına gelmez.

Mevcut districti Tip 1 eşleniğiyle etiketlemek, eski binaları referans plan sayısına tamamlamaz. Yalnız oynanabilir Tip 1 izni varken etkin host akışı eklenir. Demo sonrası Tip 0 ekonomisi bu katkıyla değiştirilmez.

### 14.7. Yirmi beş temel district kimliği

Tabloda C ilk tam referans paketinin kredisidir. Tekrar ve mevcut içerik farkı gerçek teklifte ayrıca hesaplanır.

| Kalıcı kimlik | Ad | Host | Rol | Profil | C | Host ek akışı |
| --- | --- | --- | --- | --- | ---: | --- |
| t1_energy_core | Enerji Merkezi | Energy | Energy | RE | 1.540 | +2,625 enerji |
| t1_energy_industry | Enerji Sanayisi | Energy | Production | RP | 2.700 | +2,625 enerji |
| t1_energy_science | Enerji Bilimi | Energy | Science | RS | 1.540 | +2,625 enerji |
| t1_energy_habitation | Enerji Yerleşimi | Energy | Residential | RR | 1.342 | +2,625 enerji |
| t1_energy_trade | Enerji Ticareti | Energy | Commercial | RC | 1.540 | +2,625 enerji |
| t1_production_energy | Sanayi Enerjisi | Production | Energy | RE | 1.540 | +2,5 ham |
| t1_production_core | Sanayi Merkezi | Production | Production | RP | 2.700 | +2,5 ham |
| t1_production_science | Sanayi Araştırmaları | Production | Science | RS | 1.540 | +2,5 ham |
| t1_production_habitation | İşçi Yerleşimi | Production | Residential | RR | 1.342 | +2,5 ham |
| t1_production_trade | Sanayi Ticareti | Production | Commercial | RC | 1.540 | +2,5 ham |
| t1_science_energy | Araştırma Enerjisi | Science | Energy | RE | 1.540 | +3,25 Science |
| t1_science_production | Deneysel Üretim | Science | Production | RP | 2.700 | +3,25 Science |
| t1_science_core | Araştırma Merkezi | Science | Science | RS | 1.540 | +3,25 Science |
| t1_science_habitation | Akademik Yerleşim | Science | Residential | RR | 1.342 | +3,25 Science |
| t1_science_trade | Bilim Ticareti | Science | Commercial | RC | 1.540 | +3,25 Science |
| t1_residential_energy | Yerleşim Enerjisi | Residential | Energy | RE | 1.540 | +2.062,5 konut |
| t1_residential_production | Sivil Üretim | Residential | Production | RP | 2.700 | +2.062,5 konut |
| t1_residential_science | Toplum Araştırmaları | Residential | Science | RS | 1.540 | +2.062,5 konut |
| t1_residential_core | Konut Merkezi | Residential | Residential | RR | 1.342 | +2.062,5 konut |
| t1_residential_trade | Yerel Ticaret | Residential | Commercial | RC | 1.540 | +2.062,5 konut |
| t1_commercial_energy | Ticari Enerji | Commercial | Energy | RE | 1.540 | +16,25 kredi |
| t1_commercial_production | Ticari Üretim | Commercial | Production | RP | 2.700 | +16,25 kredi |
| t1_commercial_science | Pazar Araştırmaları | Commercial | Science | RS | 1.540 | +16,25 kredi |
| t1_commercial_habitation | Ticari Yerleşim | Commercial | Residential | RR | 1.342 | +16,25 kredi |
| t1_commercial_core | Ticaret Merkezi | Commercial | Commercial | RC | 1.540 | +16,25 kredi |

Aynı modelin aynı City'deki tekrar sayacı tam model kimliğini kullanır. Enerji Bilimi ile Enerji Merkezi aynı district modeli değildir. Farklı oyuncu ismi, girdi seçimi veya hazır plan adı aynı modele ikinci ucuz ilk adet oluşturmaz.

City kuruluşunun aile fiyatı beş host ailesinden gelir. District model sayacıyla City aile sayacı birbirine karıştırılmaz.

Temel district kabuk bedeli aynı modelin yerel tekrar sayısıyla 1,50 büyür. Çocuk binaların gerçek yerel 1,20 tekrar bedeli kendi alt districtinde hesaplanır. Plan teklifi bu gerçek kalemleri toplar; tablo paketine bütün çocukları ikinci kez eklemez.

### 14.8. Özel modellerin ortak sözleşmesi

Özel model kendi ailesinin gerçek districtidir. Normal paket içeriği ve işletme profili tanımlıdır; üstte ayrıca aynı nominal gelir verilmez.

Standart özel modelin ilk tam kuruluş kredisi normal tam referans paketinin 1,50 katıdır. Dış Sistem Füzyon Kompleksi ve Yıldız Destekli Sentez Tesisi 2 kat kredi kullanır. Özel fiyat primi yalnız gerçek district kabuğunun edinim kaydına yazılır. Çocuklar ve seviye yükseltmeleri standart gerçek bedellerini korur.

    Özel kabuk tabanı = 300 + (özel katsayı - 1) × normal tam referans paket kredisi

Yıldız Toplama Ağı örneğinde normal RE referansı 1.540 kredidir. Özel kabuk 300 +0,50 ×1.540 =1.070 kredidir. Toplam 1.070 kabuk +250 Lv2 +450 ilk Matrix +540 ikinci Matrix =2.310 kredidir. Bu toplam ayrıca üst City veya paket kartına ikinci edinim bedeli yazılmaz.

Aynı tam özel modelin aynı City'de sonraki kabuğu kendi 1,50 tekrar sayacını kullanır. Çocukların gerçek yerel 1,20 sayacı ve seviye tarifleri ayrı kalır. Katalogdaki toplam 2.310'un tamamı tekrar katsayısıyla çarpılıp sonra çocuklar yeniden eklenmez. Kısmi planın fiyatı özel modelin bu sabit kabuk tabanı, gerçekten istenen seviye ve gerçekten kurulacak erişilebilir çocukların toplamıdır. Kilitli çocuk çıkarılınca özel kabuk primi kaybolmaz ve gizlice ücretsiz çocuk oluşmaz. Sonraki bağımsız seviye yükseltmesi veya çocuk eklemesi kendi geçerli tarifini kullanır; ilk paket özel katsayısı ikinci kez vergi olmaz.

Kuruluş malzemesi profilin kendi gerçek alt bina listesi, açık özel satırı ve özel mineral kuruluş tablosundan gelir. Kredi katsayısı bütün malzeme listesini gizlice çarpmaz.

Bir özel modelin ana avantajı +%50 ise tam alanda +%50, yakın kuşakta +%25'tir. +%25 avantajın yakın payı +%12,5 olur. İki kat çıktı tam uygunlukta ×2, yarım uygunlukta ×1,5 olur.

Girdi, nüfus ve işletme yükü artışları alan payıyla bedelsiz kaybolmaz. Ek tüketim, seçilmiş özel modelin sabit işletme bedelidir. Örneğin yarım uygunlukta çalışan pahalı model yine ilan edilmiş ek bakımını öder.

Tam koşul kaybolursa model uygunluk bonusunu kaybeder. Kendiliğinden yıkılmaz veya ücretsiz başka modele dönüşmez. Gerekli zorunlu beden/kuruluş koşulu artık geçersizse uygun çalışan alt akışlar durur ve nedeni gösterilir.

İşletme girdileri oyuncunun kartında ayrı gösterilir. Bütün stok satırları aynı 20 saniyelik döngüdedir.

Yan Science veya başka model-özel çıktı, district kimliği + özel akış kimliğiyle bir kez tutulur. Bir binaya ekleyip aynı district toplamına ikinci kez eklenmez.

### 14.9. Özel enerji alt profilleri

Bazı enerji modelleri genel Solar referansının yerine kendi gerçek bina planını kullanır.

| Profil | Gerçek içerik | C | Kuruluş malzemesi | Enerji | Döngü girdisi | Nüfus |
| --- | --- | ---: | --- | ---: | --- | ---: |
| RW | Lv2 Energy; 5 Wind Turbine | 2.038,32 | Yok | +28,75 Wind | Yok | 2.250 |
| RT | Lv2 Energy; 2 Tidal Generator | 1.870 | 60 Ferrite +10 Goods | +33,75 tidal/ısı | 2/3 Goods | 2.500 |
| RH | Lv2 Energy; 2 Geothermal Plant | 2.200 | 60 Ferrite +10 Goods | +41,25 termal | 2/3 Goods | 2.500 |
| RF | Lv2 Energy; 2 Fusion Reactor | 3.520 | 180 Ferrite +30 Goods +10 Fuel +4 Rare | +71,25 füzyon | 4/3 Fuel | 5.500 |

RW beş tek yuvalı türbinle bütün beş yuvayı kullanır. RT, RH ve RF dört yuva kullanır.

RT'nin gelgit ısı uyarlaması güçlü gelgit makro koşuluyla çalışır. Güçlü gelgit için ayrıca deniz kıyısı veya volkanik zemin uydurulmaz. Yüzeydeki temel Tidal Generator'ın kıyı koşulu, bu özel modelin yeni gelgit ısı dönüşüm rolünden ayrı içerik koşuludur. Aynı alt akış iki enerji türü üzerinden iki kez sayılmaz.

Genel RE profilinin pahalı özel adı, uygun olmayan yerde beş Wind Turbine oluşturmuş sayılmaz. Atmosfer Enerji Ağı RW'yi, Derin Isı RH'yi, Füzyon RF'yi gerçekten kullanır.

### 14.10. Energy City özel districtleri: altı model

| Kimlik ve ad | Profil / ilk C | Koşul | Ana avantaj | Sabit karşılık ve yan çıktı |
| --- | --- | --- | --- | --- |
| t1_energy_stellar_collectors / Yıldız Toplama Ağı | RE / 2.310 | Yoğun ışık | Solar çıktısı +%50 × q | Goods gideri +%25: 5/6 Goods |
| t1_energy_atmospheric_grid / Atmosfer Enerji Ağı | RW / 3.057,48 | Atmosferli gövde ve rüzgârlı yüzey | Wind çıktısı +%50 × q | Nüfus yükü +%25: 2.812,5 |
| t1_energy_tidal_heat / Gelgit Isı Kompleksi | RT / 2.805 | Güçlü gelgit | Gelgit ısı çıktısı +%50 | 2/3 Goods +0,1 Rare |
| t1_energy_deep_heat / Derin Isı Şebekesi | RH / 3.300 | Volkanik gövde veya jeotermal yüzey | Termal çıktı +%50 × q | Goods gideri +%50: 1 Goods |
| t1_energy_outer_fusion / Dış Sistem Füzyon Kompleksi | RF / 7.040 | Soğuk dış kuşak | Enerji ×(1 + q) | Fuel gideri +%50: 2 Fuel |
| t1_energy_magnetosphere / Manyetosfer Dönüştürücüsü | RE / 2.310 | Radyasyon kuşağı | Enerji +%25 × q | Ek 0,1 Rare; sabit yan Science 3,25 × q |

Atmosfer koşulu var/yoktur. Rüzgâr yüzey uygunluğu tam veya yarım olabilir; toplam q geçerli iki koşuldan düşük olandır.

Manyetosfer yan Science'ı, Energy host katkısından ve enerji üretiminden ayrı district-owned akıştır. Energy üzerine uygulanan Solar verimi bu Science'a taşınmaz.


### 14.11. Production City özel districtleri: yedi model

Bütün satırlarda RP'nin değiştirilmeyen akışları aynen kalır. +%50 Goods, bütün ham/Fuel/Rare çıktısını da +%50 yapmaz.

| Kimlik ve ad | İlk C | Koşul | Gerçek ana değişiklik | Diğer gider |
| --- | ---: | --- | --- | --- |
| t1_production_belt_extraction / Kuşak Çıkarım Kompleksi | 4.050 | Asteroit kuşağı | RP ham çıkarımı +%50 × q | Toplam 2/3 Goods +1/6 Fuel |
| t1_production_solar_smelting / Güneş İzabe Kompleksi | 4.050 | Yoğun ışık | Goods +%50 × q; enerji ihtiyacı %25 düşük: 9 | Ek 0,1 Rare; temel 1/3 Goods |
| t1_production_cryo_fuel / Kriyo Yakıt Rafinerisi | 4.050 | Soğuk kuşak veya buzlu gövde | Fuel +%50 × q; enerji ihtiyacı 9 | Goods gideri +%25: 5/12 Goods |
| t1_production_stellar_synthesis / Yıldız Destekli Sentez Tesisi | 5.400 | Yoğun ışık | Fuel ×(1 + q) | Ham tarif girdisi 48; enerji ihtiyacı 24; 1/3 Goods |
| t1_production_magnetic_separation / Manyetik Ayrıştırma Kompleksi | 4.050 | Radyasyon kuşağı | Rare +%50 × q | Enerji ihtiyacı +%50: 18; 1/3 Goods |
| t1_production_vacuum_assembly / Vakum Hassas Montajı | 4.050 | Atmosfersiz gövde | Goods +%25 | Ek 0,1 Rare; yan Science 3,25; 1/3 Goods |
| t1_production_system_supply / Sistem İkmal ve Depo Merkezi | 4.050 | Aynı sistemde en az iki yerleşilmiş gövde | Kendi depolama profili +%50 | Toplam 2/3 Goods +1/6 Fuel |

Güneş İzabe Kompleksi tam uygunlukta 11,25 temel Goods verir. Kriyo Yakıt tam uygunlukta 3,75 temel Fuel verir. Sentez tam uygunlukta 5 temel Fuel verir, fakat ham tarif girdisi 32 yerine 48'dir. Bu değerler mineral nadirlik veriminden öncedir.

Kriyo modelinde soğuk kuşak ve buzlu gövde bir aradaysa iki ayrı +%50 verilmez. Alternatiflerden en güçlü q bir kez kullanılır.

Sentezde ham çıkarım miktarı kendiliğinden +%50 olmaz. Artan kalem işleme tarifinin ham tüketimidir.

Sistem İkmal ve Depo Merkezi'nin kendi pasif depolama referansı, keşfedilmiş ham türü başına 1.000, Goods 150, Fuel 150, Rare 75'tir. +%50 ile katkı sırasıyla 1.500, 225, 225 ve 112,5 olur.

Bu depolama districtin kendisine ait tek kapasite akışıdır. RP alt paketinde ayrıca var olmayan bir Warehouse gelir veya bina adedi gibi sayılmaz.

İki yerleşilmiş gövde koşulu gerçek oyuncu yerleşimidir. Önizleme, yalnız ziyaret, uçuş varışı veya bütün sistemde doğal olarak iki gezegen bulunması yeterli değildir.

### 14.12. Science City özel districtleri: beş model

| Kimlik ve ad | İlk C | Koşul | Ana avantaj | Girdi ve yan kapasite |
| --- | ---: | --- | --- | --- |
| t1_science_solar_observatory / Güneş Gözlemevi | 2.310 | Yoğun ışık | Science +%50 × q | Enerji ihtiyacı +%50: 9; 2/3 Goods |
| t1_science_deep_sky / Derin Gökyüzü Gözlemevi | 2.310 | Soğuk kuşak ve atmosfersiz gövde | Science +%50 × q | Enerji ihtiyacı %25 düşük: 4,5; 2/3 Goods +0,1 Rare |
| t1_science_magnetosphere / Manyetosfer Araştırma Merkezi | 2.310 | Radyasyon kuşağı | Science +%50 × q | 2/3 Goods +0,1 Fuel |
| t1_science_cryo_lab / Kriyo Araştırma Laboratuvarı | 2.310 | Buzlu gövde; Cryolite keşfedilmiş | Science +%50 | 1 Cryolite +2/3 Goods |
| t1_science_planet_ecology / Gezegen Ekolojisi Kampüsü | 2.310 | Ilıman kuşak ve orman veya deniz kıyısı | Science +%25 × q | Goods gideri 1; kendi konut yan katkısı 5.156,25 × q |

Güneş Gözlemevi normal dağ coğrafyasından yararlanır: dağ üzerinde +%30, yakınında +%15 Science. Yoğun ışık uygunluğu ayrı bir sistem etkisidir. Örneğin 100 Science tabanı, tam yoğun ışık +%50 ve tam dağ +%30 ile 180 Science verir; başka etkiler varsa ilgili grupta ayrıca bir kez hesaplanır. Aynı dağ City ve district üzerinden tekrar eklenmez.

Derin Gökyüzü koşulu soğuk kuşak ile atmosfersiz gövdeyi birlikte ister. Soğuk veya atmosfersiz olmak tek başına yeterli değildir.

Kriyo Araştırma Laboratuvarı ilk Cryolite keşfinin yerine geçmez. Yerel uygun çıkarıcıyla Cryolite erişimi açılmalıdır. Cryolite gideri bilinmeyen genel raw ile karşılanmaz.

Gezegen Ekolojisi koşulunun parantezi:

    Ilıman kuşak VE (orman VEYA deniz kıyısı)

Yüzey alternatifi tekilleştirilir. Hem orman hem kıyı olması modelin Science avantajını iki kez vermez.

Ekoloji Kampüsü'nün kendi konut yan katkısı RR sabit konut referansının %25'idir. Başka Residential districtlerin o anki konut toplamının yüzdesi değildir. District kimliği + ecology_housing anahtarıyla bir kez bulunur.

### 14.13. Residential City özel districtleri: üç model

| Kimlik ve ad | İlk C | Koşul | Konut avantajı | Sabit karşılık |
| --- | ---: | --- | --- | --- |
| t1_residential_open_living / Açık Yaşam Mahallesi | 2.013 | Ilıman kuşak ve ova, orman veya deniz kıyısı | RR konutu +%50 × q | Enerji ihtiyacı 3; Goods gideri 5/6 |
| t1_residential_under_ice / Buzaltı Sığınakları | 2.013 | Buzlu gövde | RR konutu ×2 | Enerji ihtiyacı 6; 2/3 Goods +1/3 Fuel |
| t1_residential_closed_ecosystem / Kapalı Ekosistem Yerleşimi | 2.013 | Her geçerli kayalık yerleşim gövdesi | RR konutu +%50 | 2/3 Goods +0,1 Rare |

Açık Yaşam Mahallesi koşulu:

    Ilıman kuşak VE (ova VEYA orman VEYA deniz kıyısı)

Buzaltı tam gövde etiketiyle çalışır; komşu buzlu gezegen yarım uygunluk sağlamaz.

Kapalı Ekosistem geçerli kayalık kuruluş yeri ister. Gaz devinde yüzey varmış gibi kurulmaz. Atmosfersiz kayalık gövdede çalışabilir; ayrıca gizli yaşanabilirlik teknolojisi kapısı eklenmez.

Konut modelleri çalışan nüfus yükü eklemez. Enerji ve ürün giderleri gerçek kapasite etkisinin çalışma koşuludur. Ödenmeyen ücretli dönemde kapasite etkinleşmez.

### 14.14. Commercial City özel districtleri: dört model

| Kimlik ve ad | İlk C | Koşul | Ana çıktı | Gider |
| --- | ---: | --- | --- | --- |
| t1_commercial_belt_market / Kuşak Emtia Pazarı | 2.310 | Asteroit kuşağı | RC kredi +%50 × q | 2/3 Goods +0,1 Fuel |
| t1_commercial_inner_market / İç Sistem Pazarı | 2.310 | Ilıman kuşak ve aynı gövdede en az iki başka yakın normal City | RC kredi +%50 × q | Nüfus yükü +%50: 3.750; 2/3 Goods |
| t1_commercial_outer_exchange / Dış Sistem İkmal Borsası | 2.310 | Soğuk kuşak ve en yakın diğer City uzak veya çok uzak | RC kredi +%50 × q | 2/3 Goods +0,1 Fuel |
| t1_commercial_research_licensing / Araştırma Lisanslama Merkezi | 450 | Yakında kendisinden başka Science rolü taşıyan district | 4 Science +0,1 Goods -> 26 kredi / 20 sn | Enerji ihtiyacı 2; toplam nüfus yükü 750 |

İç Sistem Pazarı'nın adı yoğun ışık şartı anlamına gelmez. Koşulu ılıman kuşaktır.

İki başka City koşulunda kendi City'si sayılmaz. İnşaat, önizleme veya otomatik merkez normal City adedi sayılmaz. Yakınlık City mesafe profilindeki çok yakın veya yakın aralıktır: 7.000 km dahil.

Dış Sistem İkmal Borsası en yakın diğer tamamlanmış City'ye bakar; merkezler de bu mesafe hesabında vardır. 10.000 km üstü uzak ve 14.000 km ve üzeri çok uzak uygundur. Küçük gövdede bu koşulun hiç oluşmaması mümkündür.

Araştırma Lisanslama Merkezi, RC paketinden gelen 162,5 krediyi ayrıca üretmez. Bu modelin doğrudan ve tek esas tarifi 4 Science +0,1 Goods -> 26 kredidir.

Lisanslama küçük bir Lv1 özel Commercial district profilidir. 300 kredi kabuk referansının 1,50 özel katsayısı ilk 450 krediyi oluşturur. İçinde ikinci bir Trade Hub paketi kurulmaz. Toplam 750 yükün 500'ü district, 250'si lisans işletmesidir.

Lisanslama yakın koşulu district profilinde 1.000 km dahildir. Başka districtin Host A'sı farklı olabilir; burada açıkça istenen özellik gerçek Science rolüdür. Kendisini Science kaynağı sayamaz.

Lisanslama akışına Commercial hostunun sabit 16,25 kredi katkısı ayrı bir kez eklenir. 26 kredilik tarifin değeri, bütün yerleşimin toplam geliriyle karıştırılmaz.

Bu model Science kaynağından kendiliğinden ek Science almaz. Science bedeli ortak stoktan ödenir. Girdi bulunmazsa tarif durur; ek kaynak yaratılmaz.

### 14.15. Özel modellerin toplamı ve merkezlerin ayrımı

Katalogda 25 temel ve 25 özel district vardır:

| Host | Temel model | Özel model | Toplam |
| --- | ---: | ---: | ---: |
| Energy | 5 | 6 | 11 |
| Production | 5 | 7 | 12 |
| Science | 5 | 5 | 10 |
| Residential | 5 | 3 | 8 |
| Commercial | 5 | 4 | 9 |
| Toplam | 25 | 25 | 50 |

Orbital City, Capital District veya diğer merkezler bu elli normal modelin içine sayılmaz.

Her özel modelin hostu tablosunun ailesidir. Rolü ana tablodaki çıktı rolüdür: Energy, Production, Science, Residential veya Commercial. Sabit host katkısı özel bonusla kendiliğinden yüzde elli daha büyümez.

Özel yan akışların kimliği:

| Model | Ek akış anahtarı |
| --- | --- |
| Manyetosfer Dönüştürücüsü | special_magnetosphere_science |
| Vakum Hassas Montajı | special_vacuum_science |
| Gezegen Ekolojisi Kampüsü | special_ecology_housing |
| Sistem İkmal ve Depo Merkezi | special_system_storage |
| Araştırma Lisanslama Merkezi | recipe_research_licensing |

Yan akışlar bir kez kaydedilir ve bir kez toplanır. Girdi veya bakım koşulu yerine getirilmediyse ücretli yan etki etkinleşmez.

### 14.16. Kuruluş, kaynak ve plan güvenliği

Tip 1'in ilk temel planları Cinderite veya Cryolite'ı ilk çıkarımdan önce zorunlu kuruluş bedeli yapmaz. İlk üretici yolunda bilinen Ferrite, Moonstone ve açılmış işlenmiş ürünler kullanılır.

Bir mineral henüz keşfedilmediyse kartta adı, miktarı, simgesi veya fiyatı gösterilmez. Oyuncuya önce ilgili yerel çıkarımı açması gerektiği anlatılır.

Makro coğrafya etiketleri açık özelliklerdir. Yeni hammaddenin adını erken açıklamak için kullanılmaz.

Gövde kaynağı, yerel uygun çıkarıcı ve medeniyet erişimi birlikte denetlenir. City host desteği veya özel yan Science akışı ilk keşif aracı sayılmaz.

Tip 1 paketinin gerçek çıkarım yeteneğini Mine, district ham tabanı veya açıkça tanımlı gerçek yerel çıkarıcı sağlar. İşleme-only planı kaynak keşfi yaratmaz.

Özel districtin q'su tek noktadan okunur ve o modelin uygun çıktı farkına uygulanır. Aynı yıldız kuşağı için önce gizli genel +%20, ardından aynı gerekçeyle bir +%50 daha eklenmez. Makro model etkisi açık katalog satırında tanımlıdır.

Yerel yüzey coğrafyası ayrı katkıdır. Yoğun ışık ve çöl ayrı türlerdir; fakat City ve district üzerinden gelen aynı çöl türü tekilleştirilir.

Tam alan isteyen Tip 0 bina modeli ile yarım uygunlukta çalışabilen yeni özel district varyantı aynı kuruluş kapısı değildir. Özel varyantın açık koşulu yalnız o varyanta aittir; temel Wind veya başka Tip 0 modelinin koşulunu genel olarak gevşetmez.

Güncelle, yeni erişilmiş özel modelin daha iyi olacağını bütün gerçek giderleriyle karşılaştırır. Yalnız çıktısı büyük diye bakımını ödeyemeyen veya yerleşim koşulu olmayan model seçilmez.

Mevcut yatırımın eşlenmesi para almaz ve ücretsiz üretim adedi eklemez. Yeni özel varyanta ücretli geçiş açık fark teklifiyle yapılır.

Oynanabilir Tip 1 izni yokken bu elli model, host desteği ve makro özel etkiler yalnız önizlenir. Tip 1 varış bayrağı tek başına bunları eski Dünya/Ay ekonomisine bağlamaz.




### 14.17. Özel modellerde Cinderite ve Cryolite kuruluş malzemeleri

Temel yirmi beş model bu iki ham kaynağı kuruluşta istemez. İlk yerel çıkarıcıyı kurmak için henüz çıkarılamayan kendi hammaddesini isteme döngüsü oluşmaz.

Aşağıdaki özel modellerin tam paket kuruluş bedeline ek ham malzeme eklenir. Bunlar bir defalık kuruluş girdisidir; sürekli bakım veya her tur tekrarlanan tüketim değildir.

| Özel model | Ek kuruluş malzemesi |
| --- | --- |
| Yıldız Toplama Ağı | 50 Cinderite |
| Manyetosfer Dönüştürücüsü | 50 Cinderite |
| Güneş İzabe Kompleksi | 50 Cinderite |
| Yıldız Destekli Sentez Tesisi | 50 Cinderite |
| Manyetik Ayrıştırma Kompleksi | 50 Cinderite |
| Güneş Gözlemevi | 50 Cinderite |
| Manyetosfer Araştırma Merkezi | 50 Cinderite |
| Dış Sistem Füzyon Kompleksi | 50 Cryolite |
| Kriyo Yakıt Rafinerisi | 50 Cryolite |
| Derin Gökyüzü Gözlemevi | 50 Cryolite |
| Kriyo Araştırma Laboratuvarı | 50 Cryolite |
| Buzaltı Sığınakları | 50 Cryolite |

Tabloda yer almayan özel modeller yalnız kendi referans paketinin ve açık özel tarifinin bedellerini ister. Bu iki mineral için tablo dışında genel bir elli district zorunluluğu oluşturulmaz.

Gerekli medeniyet ve gövde erişimi olmadan bu ham malzeme üretilemez. İlgili kaynak keşfedilmeden özel modelin kuruluş kartında malzeme adı, simgesi ve miktarı gizlenir. Kart erişilemeyen yerel kaynak gereksinimi olduğunu söyler.

Kuruluş malzemesi ortak stoktan ödenir. Soğuk kuşakta bulunan fakat buzlu olmayan bir gövdedeki Kriyo Yakıt Rafinerisi için Cryolite'ın aynı gövdeden çıkarılması gerekmez. Oyuncu başka erişilebilir gövdede keşfedip üretebilir veya keşif ve ticaret izinleri açıldıktan sonra satın alabilir. Yerel uygunluk ile ortak kuruluş stoku farklı denetimlerdir.

Önceden kurulmuş bir districtin ücretsiz Host/Rol uyarlaması bu yeni malzemeleri geçmişe dönük talep etmez. Yeni özel model satın alma veya onaylı özel modele Güncelle farkı bu girdileri tüketir.

<a id="bolum-15"></a>

## 15. Hazır plan, Güncelle, yıkım ve yeniden konumlandırma

### 15.1. Hazır plan gerçek bir kuruluş tarifidir

Her hazır plan şu bilgileri taşır:

- Kalıcı plan kimliği ve içerik sürümü.
- Kurulacak gerçek kök nesne ve gerçek alt nesne listesi.
- Her nesnenin tam model kimliği, Host A/Rol B bilgisi ve kuruluş fiyat ailesi.
- Gerçek seviye hedefleri ve bina adetleri.
- Yerel yüzey veya üst harita konum önerileri.
- Girdi ve tarif seçimleri.
- Gerekli medeniyet, skill, keşif, malzeme ve yer koşulları.
- Kuruluş işlemi kimliği ve her kurulmuş çocukla bağlantısı.

Plan kartı ayrı bir üretici değildir. Kartın Science, Credit veya Energy toplamı gerçek alt nesnelerden hesaplanır. Kartın üst toplamını ikinci gelir satırı olarak ekonomiye eklemek yasaktır.

Bir planın bedeli kök kuruluşu, seviye artışları ve gerçek çocukların ödenecek tutarlarının toplamıdır. Tek bir paket tahsilatı yapılabilir; bu ödeme gerçek bileşenlere paylaştırılır. Aynı kredi hem paket kaydında hem çocuk kaydında edinim değeri olarak tutulmaz.

### 15.2. Kuruluş teklifi ve tamamlanma

Oyuncu gerçek kuruluş öncesinde tek teklif görür:

1. Kök ve alt içerik listesi.
2. Ödenecek Credit ve malzeme toplamı.
3. İnşaat süreleri ve sırası.
4. Beklenen çıktı, enerji, nüfus, bakım ve depo farkı.
5. Konum gerekçesi ve coğrafya/yakınlık/uzaklık katkıları.
6. Kurulamayan veya skill açılınca önerilecek eksik çocuklar.

Teklif bütün gerçek yerel fiyat sayaçlarıyla hesaplanır. Beş temel rol paketinin nominal tabanı, kilitli çocuğun bedelsiz kurulması anlamına gelmez. Erişilemeyen bina plan dışına alınır; gerçek teklif ve gerçek çıktı kalan içerikten hesaplanır.

İşlem onaylandığında kredi ve kuruluş girdileri tek işlem kimliğiyle harcanır veya inşaat sistemi gerektiriyorsa ayrılır. Yalnız rezerv oluşturmak tamamlanmış üretici yaratmaz. İnşaat tamamlanınca ilgili gerçek nesne bir kez etkinleşir.

Aynı işlem kimliğinin kayıt yükleme, görünüm açma veya yeniden olay işleme sırasında ikinci kez çalışması yeni nesne veya ikinci ödeme yaratmaz.

Merkez kuruluşu da aynı kimlik sözleşmesini kullanır. Birden fazla inşaat olayı aynı ana yerleşime iki merkez ekleyemez.

### 15.3. Elle düzenleme ve Güncelle

Oyuncu otomatik kurulmuş bir nesneyi ayrıntıda düzenleyebilir. Konum, korunacak bina, kaldırılmaması gereken adet, seçilmiş tarif ve girdi gibi kararlar ilgili gerçek nesnede elle düzenleme kaydı oluşturur.

Güncelle şu karşılaştırmayı yapar:

    Hedef plan - gerçek mevcut alt içerik = önerilen ekleme, kaldırma ve yer değişimleri

Güncelle yalnız eksik yeni içeriği fiyatlandırır. Önceden ödenmiş ve korunacak adetleri yeniden satın almaz. Eşlenmiş eski districtin katalog referansını tamamlamak zorunlu değildir.

Oyuncu şu seçenekleri ayrı ayrı görebilir:

- Eksik erişilebilir bina ekle.
- Yeni açılmış skill'in izin verdiği bina veya özel varyanta geç.
- Gereksiz adedi mevcut iade kuralıyla kaldır.
- Çakışan konumu oyuncu onayıyla değiştir.
- Elle sabitlenmiş nesneyi olduğu gibi koru.

Güncelle elle işaretlenmiş konumu kendiliğinden eski prefab yerine döndürmez. Oyuncu sabitlemeyi kaldırırsa sonraki teklif bu nesneyi yeniden değerlendirebilir.

Bir değişiklik başka bina koşulunu bozuyorsa işlem bunu önceden gösterir. Mevcut bina sessizce silinmez veya farklı modele çevrilmez.

Özel modele geçişte gerçek kaldırma iadesi ve gerçek yeni alış bedeli gösterilir. Uyarlama adı altında ücretsiz özel kapasite, yan Science veya seviye eklenmez.

### 15.4. İşlem kapsamları

| İşlem | Korunan | Kaldırılan veya değişen |
| --- | --- | --- |
| Binadan adet kaldır | Diğer adetler, district ve ayarlar | Seçilmiş gerçek bina adetleri |
| İçeriği temizle | Yerleşimin kabuğu, kimliği, adı, konumu ve seviyesi | Oyuncunun seçtiği alt içerik kapsamı |
| Yerleşimi sıfırla | Aynı kabuk, kimlik, ad ve konum; Lv1 iskelet | Alt ağaç ve Lv1 üstündeki seviye yatırımları |
| Yerleşimi yık | Üst ebeveyn, doğal gövde ve harita | Seçilmiş oyuncu yerleşimi ve bütün ekonomik alt ağacı |
| Taşı | Gerçek kimlik, seviye, adet, ödeme payı ve ayarlar | Konum; açık aktarımda kök ebeveyn bağlantısı |
| Yeni oyun | Ekonomik yıkım işlemi değildir | Ayrı menü işleminin bütün oyun kapsamı |

Bir gezegen yerleşimini yıkmak doğal gezegeni silmez. Yarıçap, seed, mineral kümesi, keşfedilmiş doğal içerik ve ekonomik haritadaki doğal gövde kimliği korunur. Aynı ayrım güneş sistemi ve Gökada yerleşimlerinde geçerlidir.

Sıfırlama medeniyet seviyesini, araştırmaları, keşifleri, adlandırılmış görev geçmişini ve ortak kaynak cüzdanını sıfırlamaz. Yerleşimi yıkmak yeni oyun başlangıç bütçesini tekrar dağıtmaz.

### 15.5. Merkezlerin temizlenmesi ve yeniden kurulması

Capital ve üst merkezler yıkılabilir veya sıfırlanabilir. Merkez yıkıldığı için üst görünüm yeniden açıldığında bedelsiz yüksek seviyeli bir merkez oluşmaz.

İlk otomatik merkez hakkı yerleşim kuruluşunun parçasıdır; sürekli çalışan ücretsiz yeniden üretim değildir. Eksik merkez Güncelle teklifinde gerçek yeniden kuruluş bedeliyle gösterilebilir.

Merkez sıfırlanırsa aynı merkez iskeleti Lv1 kalır. Çocuklar ve üst seviyeler kendi gerçek ödeme paylarıyla birer kez tasfiye edilir. Merkez yıkılırsa ana yerleşim merkez katkısı almaya devam etmez.

Her ana yerleşimin merkez yuvasında en fazla bir gerçek merkez rolü bulunur. İnşaat ve yeniden kuruluş aynı sınırı paylaşır.

### 15.6. N/C edinim havuzu ve iade

İade oranları:

| Hak | Kredi iade oranı |
| --- | ---: |
| Temel | %50 |
| Geri Kazanım I | %65 |
| Geri Kazanım II | %75 |

Malzemeler iade edilmez. İade tabanı bugünkü katalog fiyatı değil, gerçekten ödenmiş ve henüz tasfiye edilmemiş Credit'tir.

Eşdeğer model, seviye ve maliyet kapsamındaki gruplanabilir bina adetleri için iki değer tutulur:

    N = kalan gerçek adet
    C = bu adetlerin kalan gerçek edinim kredisi

k adet kaldırılırsa:

    Maliyet payı = C × k / N
    Kredi iadesi = Maliyet payı × iade oranı
    Yeni C = eski C - maliyet payı
    Yeni N = eski N - k

150, 180 ve 216 krediyle alınmış üç Lab için C=546 ve N=3 olur. Bir adedin payı 182'dir. Temel iade 91, Geri Kazanım II iadesi 136,50 kredidir. Sonrasında C=364, N=2 kalır.

C'den iade tutarı çıkarılmaz. Tam maliyet payı çıkarılır. Aksi halde aynı edinim değeri sonraki yıkımlarda tekrar iade edilebilir.

Birleştirme N ve C toplamlarını toplar. Bölme C'yi adet oranında paylaştırır. Son adet hesap hassasiyetinden kalan küçük para farkını alır.

Girdi seçimi ve ayrı üretim turu durumu korunması gereken adetler operasyonel olarak ayrı durabilir; bu, toplam edinim kredisini çoğaltmaz.

### 15.7. Alt ağaçta tek maliyet, tek iade

Kökün kuruluş kabuğu, seviye yatırımları ve her gerçek çocuğun edinim bedeli ayrı sahiplerdedir.

Bir City yıkıldığında kendi kabuğu, kendi seviye yatırımları, Capital, districtler ve binalar birer kez taranır. Hazır planın gösterdiği toplam tekrar eklenmez.

Ücretsiz verilmiş merkez veya ilk kabuk için ödenmiş Credit 0'dır. Katalogda bugün ücretli görünmesi geçmişe dönük iade hakkı yaratmaz.

İnşaat iptalinde gerçekten harcanmış Credit aynı iade oranına tabidir. Harcanmış malzeme geri verilmez. Henüz tüketilmemiş ayrılmış stok serbest bırakılır. Aynı tutar hem rezerv çözümü hem iade olarak dönmez.

Yıkım teklifi şunları birlikte gösterir:

- Kaldırılacak gerçek nesneler ve adetler.
- Her maliyet sahibinin kalan edinim payı.
- Net Credit iadesi.
- Kaybolacak çıktı, enerji, nüfus kapasitesi ve depo.
- İptal edilecek inşaat, tarif ve taşıma kuyrukları.
- Harcanmış ve yalnız ayrılmış girdilerin ayrımı.

Onaydan sonra rezervler kapatılır, nesneler kaldırılır, Credit bir kez verilir ve sayaçlar/bonuslar güncellenir. Yıkım görevi veya keşif ödülü yeniden çalıştırmaz.

### 15.8. Depo kaybı ve mevcut stok

Depo kaldırılınca önceden elde edilmiş stok silinmez. Stok yeni kapasitenin üstündeyse kapasite aşıldı durumu görünür.

Yeni çıktı için yer açılmalıdır. Trade açıksa yeni taşma, açık ticaret kurallarıyla satılabilir. Trade kapalıysa yeni taşma kabul edilmez. Eski stok yeniden üretilmiş veya yeni satış yapılmış sayılmaz.

Depoyu yeniden kurmak önceki stokun ikinci kopyasını vermez. Sıfırlama ve taşıma da ortak stok havuzunu kopyalamaz.

### 15.9. Her ölçekte yeniden konumlandırma

Taşıma, otomatik planla kurulmuş gerçek nesnenin konumunu değiştirme aracıdır. Bina dışında her taşınabilir nesne kendi harita katmanında gerçek konum taşır.

| Aktif tip | Yönetilen nesne | Düzenlenen konum | Korunan alt içerik |
| --- | --- | --- | --- |
| 0 | Bina | Yüzey koordinatı yok; aynı gövdedeki uygun districtler arasında gerçek adet aktarımı | Aynı model, girdi tercihi, tur durumu ve edinim payı |
| 1 | District | Aynı gezegen üzerindeki gerçek yüzey konumu | Gerçek bina adetleri, seviyeler ve ayarlar |
| 2 | City | Aynı gezegen üzerindeki gerçek City konumu | Capital, districtler ve binalar |
| 3 | Gezegen | Aynı güneş sistemindeki gerçek ekonomik harita konumu | Aynı doğal gövde, seed, mineral kümesi ve bütün yerleşimler |
| 4 | Güneş sistemi | Aynı Gökada içindeki gerçek sistem konumu | Yıldız, gezegenler ve bütün yerleşimler |
| 5 | Gökada | Aynı Galaksi içindeki gerçek Gökada konumu | Sistemler ve bütün alt içerikler |

Tip 3'te gezegenin ekonomik konumu gerçekten değişir. Yalnız gezegen simgesinin görsel yeri değişip yakınlık hesabının eski konumda kalması geçerli değildir. Gezegenin yüzeyindeki yerel City koordinatları korunur.

Tip 4'te sistemin Gökada içindeki ekonomik konumu değişir; gezegenlerin sistem içindeki kararlı yerel konumları korunur.

Tip 5'te Gökada'nın Galaksi içindeki ekonomik konumu değişir; iç sistemlerin yerel konumları korunur.

Bu düzenleme ayrı bir yakıtlı filo görevi, gövde çarpışma simülasyonu veya yörünge fiziği değildir. Yeni gövde yaratmaz ve aynı gövdeyi yeniden seed etmez.

City yüzeyde taşınırken districtlerin City'ye göre gerçek km düzeni yeni konuma aktarılır. Dünya üzerindeki iki district arasındaki 500 km, başka kamera ölçeğinde farklı fiziksel mesafeye dönüşmez. Geçerli küresel dönüşümle yeni yüzey koordinatları hesaplanır.

### 15.10. Taşıma yetkileri

| Skill | İlk kullanım kapsamı | Science tabanı |
| --- | --- | ---: |
| Yerleşim Düzenleme | Tip 0 district/City yüzey düzenleme ve bina aktarımı; Tip 1 district yönetiminde sürer | 250 |
| Üst Ölçek Düzenleme: City | Tip 2 otomatik City planlarını üst görünümden toplu düzenleme | 2.500 |
| Üst Ölçek Düzenleme: Gezegen | Tip 3 gezegen konumu | 25.000 |
| Üst Ölçek Düzenleme: Sistem | Tip 4 sistem konumu | 250.000 |
| Üst Ölçek Düzenleme: Gökada | Tip 5 Gökada konumu | 2.500.000 |

Kazanılmış alt düzenleme hakkı medeniyet yükselince kapanmaz. Yerleşim Düzenleme, Tip 0'da izin verdiği City taşımasını Tip 2'ye gelince geri almaz. Üst City yetkisi büyük otomatik planları üst görünümden toplu yönetme kapsamını ekler.

Her skill açık nesne kapsamına sahiptir. District taşıma yetkisi gezegen taşıma yetkisi değildir. Taşıma skill'i alınmamış olsa da yıkım ve gerçek bedelle yeniden kuruluş kullanılabilir.

### 15.11. Taşıma hizmet bedeli

Bütün taşımalar seçilen gerçek nesne ve taşınacak alt ağacın kalan gerçek edinim kredisi üzerinden hizmet bedeli öder:

    Hizmet bedeli = toplam gerçek edinim kredisi × %10

Kuruluş kabuğu, gerçek seviye yatırımları ve gerçek çocukların C payları birer kez toplanır. Hazır plan toplamı ayrıca eklenmez.

Bu bedel hizmet gideridir. Edinim C havuzuna yazılmaz ve sonradan yıkımda iade edilmez. Sırf katalog fiyatı arttı diye eski edinim C'si kendiliğinden yükselmez.

Aynı ebeveyn içinde yalnız konum değişiyorsa ayrıca kuruluş fiyat farkı alınmaz.

### 15.12. Ebeveyn değişiminde kök kuruluş farkı

Bina başka districte veya district başka City'ye açıkça aktarılıyorsa hedefteki yerel aynı model fiyatının atlanması önlenir.

    B = ebeveyni değişen kökün yalnız kendi gerçek kuruluş payı
    P = hedefte aynı tam modelin sıradaki kök kuruluş fiyatı
    Kuruluş farkı = en fazla(0, P - B)
    Toplam taşıma bedeli = hizmet bedeli + kuruluş farkı
    Yeni kök kuruluş payı = eski kök kuruluş payı + kuruluş farkı

B'ye değişmeyen seviye yatırımları veya çocukların bedelleri eklenmez. Çocukların ebeveynleri değişmiyorsa onlar yeniden satın alınmış sayılmaz.

Örnek: Kuruluşu 300, çocukları 3.000 kredi olan district hedef City'de 675 kredi kuruluş sırasına taşınır. Hizmet 330, kök kuruluş farkı 375 ve toplam 705 kredidir. Çocukların 3.000 kredisi 375 farkı sıfırlamaz.

150 kredi paylı bir Lab hedef districtte 259,20 kredilik sıraya aktarılırsa hizmet 15, kuruluş farkı 109,20 ve toplam 124,20 kredidir. Yeni edinim payı 259,20 olur; 15 kredi hizmet payı iadeye eklenmez.

Bir toplu işlem birden fazla gerçek kökün ebeveynini değiştiriyorsa her değişen kök için kuruluş farkı ayrı hesaplanır. Aynı kök bir kez fiyatlanır. Taşınan City'nin içindeki districtlerin City kimliği değişmiyorsa onlara ek kök kuruluş farkı uygulanmaz.

Hedef fiyatı daha düşükse negatif fark veya taşıma kaynaklı iade verilmez. Önceki daha yüksek edinim değeri korunur.

### 15.13. Hedef uygunluğu

Taşıma teklifi şu kapıları denetler:

- Oynanabilir medeniyet ve nesne erişimi.
- İlgili taşıma skill'i.
- Aynı izinli doğal harita veya gövde.
- Hedef yerin boşluğu ve gerçek minimum mesafeler.
- Kök ebeveyn kapasitesi, district yuvaları ve bina rol uyumu.
- Kilitli Host A uyumu.
- Bütün çocukların yeni yüzey ve sistem koşulları.
- Gerekli ortak stok ve Credit.

Tip 1 districtinin farklı Host A kilitli City'ye taşınması sessizce aile değiştirmez. Yalnız hedef aileyle uyumlu gerçek model aktarılır. Yeni aileyle kuruluş ayrı ve açık yıkım/yeniden kuruluş işlemini kullanır.

Özel arazi isteyen çocuk uygunsuz kalıyorsa varsayılan taşıma geçersizdir. Sistem çocuğu silerek veya koşulu yok sayarak taşımayı tamamlamaz. Oyuncu başka yer seçer ya da açık ek düzenleme teklifini onaylar.

Başka doğal gövdeye koloniyi bedelsiz aktarmak bu aynı harita içi düzenleme kapsamına girmez. Kolonizasyon, kaynak erişimi ve demo kapıları aşılmaz.

### 15.14. Taşımanın atomik tamamlanması

1. Eski ve yeni konum için bütün gerçek alt ağaç farkları hesaplanır.
2. Oyuncu bedeli, kaybolacak ve kazanılacak katkıları görür.
3. Taşınacak adetler yeni ücretli tur başlatmayı bırakır.
4. Önceden ödenmiş mevcut üretim turları normal sonuçlarını tamamlar.
5. Bekleme bitince hedef, izinler, stoklar ve fiyat tekrar denetlenir.
6. Yeni teklif onaylanmış tutarı aşıyorsa sessiz ek ödeme yapılmaz; yenilenmiş teklif gösterilir.
7. Bütün ağaç tek işlemle yeni konuma veya izinli yeni ebeveyne geçer.
8. Kimlikler, isimler, seviyeler, maliyet payları ve girdi ayarları korunur.
9. Eski ve yeni konum hücreleri, aile sayımları ve bonus önbellekleri güncellenir.
10. Düzenlenen plan ilgili nesneler için elle değiştirilmiş olarak işaretlenir.

Taşıma beklemesinde yeni konum bonusu erken verilmez. İşlem geçersizleşirse eski konum korunur. Tahsil edilmemiş hizmet için ödeme alınmaz; ayrılmış ama harcanmamış stok çözülür.

Bir işlem kimliği aynı ağacı iki kere taşımaz. Yeni konuma ulaşmak ilk yerleşim, mineral keşfi veya adlandırılmış görev ödülünü yeniden çalıştırmaz.

### 15.15. Demo ve önizleme sınırı

Dünya ve Ay'da açık Tip 0 oynanışı içindeki izinli düzenlemeler devam eder. Tip 1'e ilk varıştan sonra önizleme haritalarını açmak yeni hedefte City, district veya üst merkez kurma hakkı vermez.

Tip 1'e ait yeni elli model, Host katkıları ve sistem coğrafyası etkileri oynanabilir Tip 1 izniyle etkinleşir. Görsel aile eşlemesi veya önizleme düzeni Dünya/Ay'daki eski gerçek ekonomiye bedelsiz bonus eklemez.

Satın alma, kurma, Güncelle, taşıma, yıkım ve araştırma kapıları yalnız düğme görünürlüğüne bırakılmaz. Gerçek işlem de ilgili nesnenin oynanış iznini denetler.

<a id="bolum-16"></a>

## 16. Oyuncunun Medeniyet 0 deneyimi ve ilerleme temposu

### 16.1. Ana amaç

Oyuncu ana dünyada bir ekonomi kurar, Ay'a yerleşir, Ay'da gerçek Moonstone çıkarır ve gelişmiş bir roket hazırlar.

Medeniyet 0'ın tamamlanma olayı, Ay'dan gönderilen gelişmiş roketin oyuncunun aynı Güneş Sistemi içinde seçtiği başka bir doğal gezegene varmasıdır.

Ay'a ulaşmak veya Ay'da ilk City'yi tamamlamak bu olayı tetiklemez.

Hedefte City kurulması gerekmez.

Demo, hedefte otomatik bir City veya Orbital City oluşturmaz.

Varışta medeniyet tipi 1 olur, fakat demodaki oynanabilir içerik tipi 0 olarak kalır.

Dünya ve Ay ekonomisi çalışmayı sürdürür.

Oyuncu eski yerleşimlerini yönetebilir ve ayrıntılı üst evren önizlemesini inceleyebilir.

Tip 1 skill ağacı ve miras düğümü görünür, fakat demoda hiçbir Tip 1 araştırması satın alınamaz.

### 16.2. İlk oturumun başlangıç durumu

| Alan | Başlangıç değeri |
| --- | --- |
| Medeniyet tipi | 0 |
| Oynanabilir içerik tipi | 0 |
| Kredi | 3.000 |
| Science | 450 |
| Malzeme | 0 |
| İlk ana dünya City'si | Ücretsiz ilk kabuk ve merkezi |
| Temel aile erişimleri | Energy, Production, Science, Residential, Commercial |
| Temel işleme | Goods tarifine erişim açık |
| Fuel | İlgili araştırmayı bekler |
| Rare | İlgili araştırmayı bekler |
| Serbest üst evren turu | Demo sonu varışını bekler |
| Ekonomik görev ödülleri | 0 |

Başlangıç bütçesi yalnız gerçekten yeni oyun oluşturulurken verilir.

Kayıt yüklemek, son yerleşimi yıkmak veya görev panelini tekrar açmak bütçeyi yeniden vermez.

Kaynak erişimi ile kaynak tanımının oyun verisinde bulunması farklıdır.

Kilitli bir mineralin adı başlangıçta depo, araştırma, trade veya maliyet satırına sızdırılmaz.

### 16.3. İlk kararların amacı

İlk dakikada oyuncu gelir, Science ve malzeme arasında bir yön seçebilmelidir.

Oyuncu ilk gelirini elde etmek için her bina ailesini kurmak zorunda bırakılmaz.

Bir Science oyuncusu fazla Science satarak kredi sağlayabilir.

Bir nüfus oyuncusu boş kapasite gelirlerini araştırabilir.

Bir sanayi oyuncusu doğrudan malzeme üretip işleyebilir.

Bir ticaret oyuncusu kredi üretip araştırması ve keşfi açılmış ürünleri satın alabilir.

Bütün yollar yine gerçek Ay çıkarımını, gerekli Spaceport'u ve roket olaylarını tamamlar.

### 16.4. İlk 450 Science için somut tercihler

| Tercih | Alımlar | Nominal Science | İlk fayda |
| --- | --- | ---: | --- |
| Nüfus ve ticaret | Ticaret Erişimi + Sivil Girişimler + Serbest Araştırma | 450 | Boş kapasite gelirleri ve manuel alış/satış |
| Bilim tabanı | Bilim Verimi Lv1 + Saha Araştırmaları + Ticaret Erişimi | 400 taban | Science yatırımı ve fazla Science satışı |
| Enerji hazırlığı | Wind Power + Photovoltaics Lv1 + Ticaret Erişimi | 450 taban | Coğrafyaya göre enerji seçeneği |
| İşleme hazırlığı | Fuel İşleme | 450 | Küçük Fuel üreticisini açma |
| Sanayi ve esneklik | Yüzey Kazı + Çıkarım Verimi Lv1 + Ticaret Erişimi | 375 taban | Ucuz çıkarım ve ticaret |

Tabloda “taban” yazan çok dallı paketlerin kesin bedeli satın alma sırasındaki çapraz dal katsayısıyla hesaplanır.

Nüfus paketinde Ticaret Erişimi ortak düğümdür.

Sivil Girişimler ve Serbest Araştırma aynı ana dala aittir.

Bu nedenle nüfus paketinin toplamı tam 450 Science'tır.

Arayüz paketleri otomatik satın almaz.

Oyuncuya elindeki bütçeyle karşılayabildiği gerçek son fiyat gösterilir.

### 16.5. Ana oturum akışı

| Aşama | Oyuncunun gördüğü ihtiyaç | Kararı | İlerleme kanıtı |
| --- | --- | --- | --- |
| Kuruluş | İlk yerleşimin yeri | Coğrafya ve sonraki genişleme alanı | İlk City ve Capital tamamlanır |
| Temel ekonomi | Gelir, Science, enerji ve iş gücü | Bir ağırlık seçmek | En az bir sürdürülebilir gelir yolu |
| Çıkarım | İlk ham madde | Uygun Production kurmak | Gerçek Ferrite üretimi |
| İşleme ve trade | Gerekli işlenmiş ürünler | Üretmek, satın almak veya karışım | Goods/Fuel erişimi ve temini |
| Ay hazırlığı | Lander teknolojisi ve bedeli | Tasarruf, üretim, satış rezervi | Spaceport ve hazırlanmış lander |
| Ay kuruluşu | Moonstone erişimi | İlk City ve Production yeri | Yerel çıkarım başlar |
| Ay gelişimi | Son roketin malzemeleri | Kapasite ve ekonomik yol | 100 gerçek yerel çıkarım, gerekli araştırmalar |
| Son hazırlık | Lunar Spaceport ve roket | Ödeme rezervlerini korumak | Fiziksel tesis ve tamamlanmış roket |
| Sefer | Hedef seçimi | Aynı sistemde başka doğal gezegen | Tek başarılı varış olayı |
| Demo sonrası | Daha büyük ölçeği görmek | İncelemek veya Dünya/Ay'a dönmek | Serbest önizleme, devam eden ekonomi |

### 16.6. 45-75 dakikalık hedefin anlamı

İlk aktif oturum için hedef aralık 45-75 dakikadır.

Bu aralık bir zaman kilidi değildir.

Oyuncu ekonomik olarak hazırsa daha erken ilerleyebilir.

Oyuncu ayrıntılı yerleşim, bina çeşitliliği veya düşük tempolu gelişim seçerse daha uzun oynayabilir.

Sayılar bir denge taslağıdır.

Bu aralığın farklı başlangıçlarda gerçekleşeceği oynanışla doğrulanmış kabul edilmez.

Offline ilerleme bu aktif süreye bire bir eklenmez.

Bir gerçek offline saat yalnız altı ekonomi dakikası ilerletir.

### 16.7. Araştırma hızından çıkan asgari ihtiyaç

Ticaret dahil nominal ortak yol 6.500 Science'tır.

Başlangıçtaki 450 bunun bir kısmını ödeyebilir.

Yalnız ortak yol için sonradan edinilmesi gereken Science 6.050'dir.

| Aktif hedef süre | Ortak yol için ortalama Science / dk | Ek 1.500 strateji Science'ı da varsa |
| --- | ---: | ---: |
| 45 dakika | 134,44 | 167,78 |
| 60 dakika | 100,83 | 125,83 |
| 75 dakika | 80,67 | 100,67 |

Bu ortalamalar bütün oturuma yayılır.

İlk dakikaların düşük üretimi nedeniyle sonraki bölümün Science hızı bu ortalamadan yüksek olmalıdır.

Science satarak kredi elde etmek araştırma stokunu büyütmez.

Krediyle Science almak araştırma hızını artırabilir, fakat kredi bütçesini tüketir.

Bütün Science'ın yalnız lab üretiminden gelmesi zorunlu değildir.

### 16.8. Erken nüfus yolunun sınırı

İlk City 15.000 kapasite ve 2.000 yük verdiğinde 13.000 boş kapasite kalır.

İki ilgili skill açıksa bu boş kapasite dakikada 130 kredi ve 26 Science sağlar.

City'nin tabanıyla birlikte 190 kredi ve 30 Science/dk oluşur.

Bu, erken nüfus yolunu başlatır.

Bu sabit düzen tek başına 6.050 Science'ı yaklaşık 201,67 dakikada üretir.

Dolayısıyla 45-75 dakika hedefi daha fazla kapasite, bilim yatırımı, ticaret veya bunların birleşimini gerektirir.

Birinci nüfus paketinin güçlü olması, bütün oyunun aynı paketi bekleyerek biteceği anlamına gelmez.

### 16.9. Ay'daki gerçek hız ihtiyacı

| Moonstone üretimi | 100 yerel çıkarım için yalın süre | 1.400 doğrudan Moonstone bedeli için yalın süre |
| --- | ---: | ---: |
| 20 / dk | 5 dakika | 70 dakika |
| 40 / dk | 2,5 dakika | 35 dakika |
| 80 / dk | 1,25 dakika | 17,5 dakika |

Bu hesaplar üretim açığı, bonus, tüketim ve trade olmadan yapılmıştır.

Yerel 100 görevini tamamlamakla son 1.400 ödeme paketini biriktirmek aynı büyüklükte hedef değildir.

45 dakikaya yaklaşan bir yol Ay'a erken ulaşmalı veya Moonstone teminini ciddi biçimde büyütmelidir.

Moonstone erişimi açıldıktan sonra satın alma bu süreyi azaltabilir.

Satın alma yerel 100 çıkarım sayacını tamamlamaz.

### 16.10. Farklı süre yolları

| Yol | İlk dünya gelişimi | Ay'a varış hedefi | Ay hazırlığı | Oturum hedefi |
| --- | --- | --- | --- | --- |
| Hızlı ekonomik yol | Tek güçlü gelir, sınırlı yan araştırma | Yaklaşık 15-22. dakika | Üretim ve alım karışımı | 45-55 dakika |
| Dengeli yol | İki gelir kaynağı, kontrollü kapasite | Yaklaşık 20-30. dakika | Yerel çıkarım, destekli işleme | 55-65 dakika |
| Ayrıntılı yerleşim yolu | Coğrafya, komşuluk ve daha fazla model | Yaklaşık 25-35. dakika | Daha çok yerel üretim | 65-75+ dakika |

Bu satırlar ekonomik hedeflerdir; görevler bu dakikaları şart koşmaz.

Bir yolun bütün koşullarda daha hızlı veya daha kârlı olduğu garanti edilmez.

### 16.11. Maliyet kapsamını doğru okumak

Dünya/Ay seferi, iki Capital yükseltmesi, gerekli Spaceport'lar, Ay Production ve bir standart Warehouse için görünen kredi 24.600'dür.

Bu paketin doğrudan malzemeleri 70 Ferrite, 1.400 Moonstone, 80 Goods, 170 Fuel ve 50 Rare'dır.

Bu toplam temel Dünya ekonomisini, ek districtleri, araştırmayı, işletme giderlerini ve isteğe bağlı binaları içermez.

Bütün bu malzemeler erişim sonrası satın alınırsa ilk fiyatlarla bedel 18.898 kredidir.

Yalnız bu doğrudan paket ve satın alınan malzemeler 43.498 kredi eder.

6.050 Science'ın da tamamı satın alınırsa 33.275 kredi daha gerekir.

Böyle bir yolun yalın toplamı 76.773 kredidir; başlangıç ve üretim yatırımları ayrıca değerlendirilir.

Bu örnek, trade'in bedelsiz bir kısayol olmadığını gösterir.

Yerel üretim kredi ihtiyacını azaltır, fakat zaman, enerji, kapasite ve yatırım ister.

### 16.12. Bekleme oluştuğunda oyuncunun yapabildikleri

| Darboğaz | Açık alternatifler |
| --- | --- |
| Science az | Science yatırımı, boş kapasite araştırması, krediyle Science alımı |
| Kredi az | Commercial, ürün satışı, fazla Science satışı, boş kapasite geliri |
| Fuel az | Küçük atölye, yoğun üretici, erişim sonrası alım |
| Rare az | Rare üretimi veya erişim sonrası alım |
| Moonstone az | Yerel çıkarım büyütme, district seviyesi, erişim sonrası alım |
| Depo küçük | Warehouse, uygun destek, ödeme rezervini düzenleme |
| Enerji açığı | Uygun enerji modeli, girdi isteyen üretimi duraklatma |
| Nüfus açığı | Konut, çalışan yükü düşük model, kontrollü ölçekleme |

Oyuncunun bütün kaynaklar için aynı anda ayrı fabrika zinciri kurması gerekmez.

### 16.13. Görev yönlendirmesinin sınırı

Görev paneli oyuncunun sıradaki somut hedefini açıklar.

Panel bütün alımları belirleyen tek bir inşaat listesi değildir.

“Gerekli Fuel'ı edin” hedefi üretim ve izinli alımı kabul eder.

“Yerel Moonstone çıkar” hedefi ise gerçek Ay üretimi ister.

Rare araştırması Ay seferinden önce tamamlanmak zorunda değildir.

Son roketten önce tamamlanması zorunludur.

### 16.14. Uygulama sorumlulukları

| Alan | Sorumlu kaynak |
| --- | --- |
| Yeni oyun bütçesi, medeniyet ve içerik izinleri | scripts/game/GameState.gd |
| Araştırma erişimi ve nominal ortak yol | scripts/game/SkillTree.gd |
| Ekonomi zamanı ve gerçek hız | scripts/game/ProductionManager.gd |
| Sefer ve yerleşim sunumu | scripts/solar/SolarView.gd, scripts/planetary/PlanetaryView.gd |
| Hedef ve ara adımlar | scripts/system/TutorialManager.gd veya onun yerini alan görev yöneticisi |
| Görünür gelirler | scripts/system/HUDManager.gd |

<a id="bolum-17"></a>

## 17. Araştırma ağacı, strateji ve fraktal miras

### 17.1. Araştırma kimliği

Her araştırmanın tek canonical kimliği bulunur.

Görünür ad değişse de kimlik etkilerin ve kayıtların dayanağıdır.

Aynı hakkı temsil eden iki kaynak kimliği iki ayrı bonus oluşturmaz.

Bir araştırmanın bina modeli açması yeni bina adedi vermesi anlamına gelmez.

Skill seçme veya satın alma adedi sınırı yoktur.

Satın alınmış haklar medeniyet geçişinde kaybolmaz.

### 17.2. Araştırma kaydının alanları

| Alan | Anlamı |
| --- | --- |
| canonical_id | Tekil araştırma kimliği |
| civilization_type | Araştırmanın ait olduğu medeniyet |
| minimum_civilization | Gerçek erişimin başlayabildiği en düşük medeniyet |
| legacy_eligible | İlgili alt medeniyet mirasına katılabilecek gerçek hak mı |
| main_branch | Çapraz dal maliyetinin tek ana dalı |
| base_science_cost | İlk seviyenin taban bedeli |
| max_level | Tek alım veya üç seviyeli bonus |
| parents_any | Grafik yollarından biri yeterli ebeveyn listesi |
| required_access_all | Birlikte gereken ürün ve keşif erişimleri |
| required_events_all | Birlikte gereken fiziksel olaylar |
| grants | Açılan model, işlem veya etki |
| visibility_rule | Önizleme görünürlüğü |
| purchase_permission | Gerçek satın alma yetkisi |
| individual_level | Oyuncunun doğrudan aldığı seviye |
| inherited_level | Mirasın verdiği seviye |
| effective_level | Etkin seviye |

### 17.3. ANY ile fiziksel şart ayrımı

parents_any listesindeki ebeveynlerden biri yeterlidir.

required_access_all listesindeki bütün erişimler gerekir.

required_events_all listesindeki bütün olaylar gerekir.

Örneğin Particle Physics bilim veya Rare yolundan açılabilir.

Buna rağmen Rare ve Moonstone erişiminin ikisi de gerekir.

Gelişmiş roketin araştırma yolu Ay Malzemeleri'nden gelir.

Rare erişimi ve 100 gerçek yerel Moonstone olayı bu düğümün ayrı zorunlu şartlarıdır.

Alternatif ebeveyn kuralı fiziksel sefer şartlarını iptal etmez.

### 17.4. Görünürlük ile satın alma

Satın alınmış düğüm görünürdür.

Bir grafik ebeveyni açılmış düğüm görünürdür.

Gelecek medeniyetlerin ana hatları daha erken, silik önizleme olarak gösterilebilir.

Görünür düğüm otomatik satın alınabilir değildir.

Erişilmemiş kaynakların isimleri gelecek düğüm açıklamasında gösterilmez.

Arayüzde gizlemek yeterli değildir.

Satın alma işlemi medeniyet ve oynanabilir içerik izinlerini tekrar denetler.

### 17.5. Çapraz dal maliyeti

    İlk seviye fiyatı = taban Science × (1 + 0,02 × diğer dallardaki farklı bireysel düğüm sayısı)

Üç seviyeli bir bonusun hedef seviye bedeli bu fiyatın hedef seviye ile çarpılmasıdır.

    Seviye fiyatı = taban Science × hedef seviye × çapraz dal katsayısı

Hedef seviyeler 1, 2 ve 3'tür.

Aynı düğümün sonraki seviyesi yeni farklı düğüm sayılmaz.

### 17.6. Sayacın kapsamı

Sayaç yalnız aynı medeniyette bireysel satın alınmış strateji düğümlerini sayar.

Ortak ilerleme düğümleri zamma girmez ve başka dalları zamlandırmaz.

Miras düğümü zamma girmez.

Mirasla verilmiş alt haklar bireysel satın alma sayılmaz.

Tip 0'daki bireysel alımlar Tip 1 fiyatlarını artırmaz.

Çok etiketli bir düğüm yalnız tek ana dala yazılır.

### 17.7. Fiyat örneği

| Taban | Diğer dallarda farklı düğüm | Lv1 | Lv2 | Lv3 | Üç seviye toplamı |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 150 | 0 | 150 | 300 | 450 | 900 |
| 150 | 5 | 165 | 330 | 495 | 990 |
| 150 | 10 | 180 | 360 | 540 | 1.080 |
| 150 | 25 | 225 | 450 | 675 | 1.350 |

Tablo satın almalar arasında sayaç değişmediğini varsayar.

Başka dal satın alındığında sonraki alımın fiyatı yeniden hesaplanır.

Onay anındaki fiyat arayüzde gösterilir.

Ödenmiş araştırmanın bedeli sonradan değiştirilmez.

### 17.8. Kalıcı uzmanlaşmanın sınırı

Hafif fiyat artışı bir stratejiden başka stratejiye geçmenin fırsat maliyetidir.

Sonsuz süre sonunda bütün dalların alınmasını engellemez.

Kalıcı bonus ve sınırsız seçim birlikte korunur.

Strateji farkı satın alma sırası, yerleşim, coğrafya, bakım ve üretim tercihinden doğar.

Seçim yuvası veya zorunlu sınıf kilidi eklenmez.

### 17.9. Ortak Medeniyet 0 yolu

| Kimlik | Görünür ad | Science | ANY ebeveyn | Birlikte gereken ek şart | Açtığı hak |
| --- | --- | ---: | --- | --- | --- |
| processing_basics | Temel İşleme | 0 | start_production | Yok | Goods Factory ve tarif seçimi |
| trade_access | Ticaret Erişimi | 150 | root | Yok | Manuel al/sat ve taşma satışı |
| fuel_processing | Fuel İşleme | 450 | processing_basics | Yok | Kompakt Yakıt Atölyesi, Fuel erişimi |
| rare_processing | Rare İşleme | 900 | fuel_processing | Yok | Rare Forge, Rare erişimi |
| rocketry | Rocketry | 600 | fuel_processing | Yok | Dünya Spaceport |
| lunar_program | Lunar Program | 1.200 | rocketry | Yok | Ay lander teknolojisi |
| lunar_materials | Ay Malzemeleri | 1.200 | lunar_program | Ay'da çıkarım yapabilen Production tamamlanmış | Ay planları ve Lunar Spaceport |
| advanced_planet_rocket | Gelişmiş Gezegen Roketi | 2.000 | lunar_materials | rare_processing, yerel 100 Moonstone olayı | Son roket |

### 17.10. Ortak yolun toplamı

| Kapsam | Science |
| --- | ---: |
| Bütün ortak satırlar | 6.500 |
| Ticaret Erişimi alınmazsa | 6.350 |
| İlk 450 kullanıldıktan sonra nominal kalan | 6.050 |
| Ticaret alınmaz ve 450 kullanılırsa | 5.900 |

Science'ın ilk 450'sini stratejiye harcamak sonraki ortak yol bedelini azaltmaz.

Toplam isteğe bağlı strateji, bonus ve otomasyon alımlarını içermez.

Spaceport, City veya malzeme maliyetleri Science tablosuna eklenmez.

Fuel ve Rare'a gezegen seviyesi şartı konmaz.

### 17.11. Başlangıç kökleri

| Kimlik | Bedel | Hak |
| --- | ---: | --- |
| root | 0 | Medeniyet 0 kökü |
| start_energy | 0 | Temel Energy ve solar |
| start_production | 0 | Production, Mine, Warehouse |
| start_science | 0 | Science, Lab |
| start_residential | 0 | Residential, Habitat |
| start_commercial | 0 | Commercial, Market |

Ücretsiz açılış, ücretsiz bina adedi değildir.

Bina kurulurken normal kredi ve isimli malzeme bedeli ödenir.

### 17.12. Production ve işleme düğümleri

| Kimlik | Ad | Ana dal | Taban Science | ANY ebeveyn | Ek koşul / etki |
| --- | --- | --- | ---: | --- | --- |
| surface_excavation | Yüzey Kazı | Production | 75 | start_production | Küçük çıkarım modeli |
| advanced_excavation | Gelişmiş Ekskavatör | Production | 450 | start_production | Yoğun çıkarım; mineral yatağı istemez |
| deep_drilling | Deep Drilling | Production | 350 | start_production | Genel yoğun çıkarım |
| mantle_cracking | Mantle Cracking | Production | 900 | advanced_excavation, deep_drilling | Fuel ve Rare erişimi |
| ore_sorting | Cevher Ayıklama | İşleme | 450 | processing_basics | Büyük Goods modeli |
| dense_fuel | Yoğun Fuel | İşleme | 350 | fuel_processing | Büyük Fuel rafinerisi |
| fuel_process_efficiency | Yakıt Süreçleri | İşleme | 150 | fuel_processing | 3 seviye, Fuel +%10/seviye |
| extraction_efficiency | Çıkarım Verimi | Production | 150 | start_production | 3 seviye, Raw +%10/seviye |

### 17.13. Energy ve sıcak saha düğümleri

| Kimlik | Ad | Ana dal | Taban Science | ANY ebeveyn | Ek koşul / etki |
| --- | --- | --- | ---: | --- | --- |
| wind_power | Wind Power | Energy | 150 | start_energy | Wind modeli |
| tidal_power | Tidal Power | Energy | 350 | wind_power, start_commercial | Kıyı üreticisi |
| shallow_heat | Sığ Isı | Coğrafya | 250 | start_energy | Küçük sıcak saha modeli |
| geothermal_power | Geothermal Power | Energy | 450 | shallow_heat, tidal_power | Büyük sıcak saha modeli |
| ridge_wind | Sırt Rüzgârları | Coğrafya | 450 | wind_power | Sırt türbini |
| solar_matrix | Solar Matrix | Energy | 350 | start_energy | Yoğun genel solar |
| fusion_power | Fusion Power | Energy | 900 | solar_matrix, geothermal_power | Fuel ve Rare erişimi |
| solar_efficiency | Photovoltaics | Energy | 150 | start_energy | 3 seviye, solar +%10/seviye |
| grid_efficiency | Superconducting Grid | Energy | 300 | start_energy | 3 seviye, enerji ihtiyacı -%5/seviye |

Araştırmanın alınması uygun bir bina konumu yaratmaz.

Örneğin Tidal araştırması alınmış olsa da bina kıyı koşulunu ayrıca ister.

### 17.14. Science düğümleri

| Kimlik | Ad | Ana dal | Taban Science | ANY ebeveyn | Ek koşul / etki |
| --- | --- | --- | ---: | --- | --- |
| field_research | Saha Araştırmaları | Science | 100 | start_science | Küçük saha modeli |
| mountain_optics | Mountain Optics | Science | 450 | start_science | Dağ gözlemevi |
| advanced_research | Advanced Research | Science | 350 | start_science | Genel yoğun bilim |
| particle_physics | Particle Physics | Science | 900 | advanced_research, rare_processing | Rare ve Moonstone erişimi |
| science_efficiency | Bilim Verimi | Science | 150 | start_science | 3 seviye, Science +%10/seviye |
| lunar_research | Ay Araştırmaları | Science | 600 | lunar_materials | Ay City'si, Rare erişimi |

### 17.15. Nüfus düğümleri

| Kimlik | Ad | Ana dal | Taban Science | ANY ebeveyn | Ek koşul / etki |
| --- | --- | --- | ---: | --- | --- |
| neighborhood_building | Mahalle İnşası | Nüfus | 75 | start_residential | Düşük katlı küçük konut |
| coastal_living | Coastal Living | Nüfus | 250 | start_residential | Kıyıdaki ekonomik enerji konutu |
| coastal_density | Kıyı Yoğunlaşması | Nüfus | 350 | coastal_living | Yoğun kıyı konutu |
| civic_enterprise | Sivil Girişimler | Nüfus | 150 | start_residential | Boş kapasiteden kredi |
| free_research | Serbest Araştırma | Nüfus | 150 | start_residential, start_science | Boş kapasiteden Science |
| population_reserve | Üretim Rezervi | Nüfus | 300 | civic_enterprise, free_research | Boş orana göre Raw/işlenmiş +%0-%20 |
| high_rise | High-Rise Housing | Nüfus | 350 | coastal_living, civic_enterprise | Genel yoğun konut |
| luxury_living | Luxury Living | Nüfus | 900 | high_rise | Fuel, Rare, Moonstone erişimi |
| housing_efficiency | Konut Verimi | Nüfus | 150 | start_residential | 3 seviye, bina konutu +%10/seviye |

### 17.16. Ticaret düğümleri

| Kimlik | Ad | Ana dal | Taban Science | ANY ebeveyn | Ek koşul / etki |
| --- | --- | --- | ---: | --- | --- |
| consumer_goods | Consumer Goods | Ticaret | 250 | start_commercial | Bazaar; Goods erişimini tekrar kilitlemez |
| local_business | Yerel İşletmeler | Ticaret | 150 | trade_access | Yerel Ticaret Merkezi |
| trade_networks | Trade Networks | Ticaret | 350 | consumer_goods, local_business | Genel Trade Hub |
| harbor_trade | Harbor Trade | Ticaret | 450 | coastal_living, trade_networks | Kıyı ticareti |
| commodity_markets | Commodity Markets | Ticaret | 900 | trade_networks | Fuel, Rare, Moonstone erişimi |
| trade_automation | Ticaret Otomasyonu | Ticaret | 300 | trade_access | Hedef stok ve rezervli otomasyon |
| trade_efficiency | Ticaret Verimi | Ticaret | 150 | start_commercial | 3 seviye, üretilen kredi +%10/seviye |
| lunar_supply | Ay İkmal Ağı | Ticaret | 600 | lunar_materials, trade_networks | Ay City'si, trade_access, Fuel erişimi |

Ticaret Verimi satış ve alış fiyatını değiştirmez.

Manuel Science alım/satımı trade_access ile mümkündür.

trade_automation yalnız otomasyon ve gelişmiş stok emirleri içindir.

### 17.17. Kamu, yakınlık ve uzaklık düğümleri

| Kimlik | Ad | Ana dal | Taban Science | ANY ebeveyn | Ek koşul / etki |
| --- | --- | --- | ---: | --- | --- |
| public_administration | Kamu Yönetimi | Kamu | 350 | root | Kamu desteklerinin kökü |
| logistics | Lojistik | Kamu | 450 | ore_sorting, trade_networks | public_administration |
| advanced_coordination | İleri Koordinasyon | Kamu | 900 | fusion_power, advanced_research | public_administration, Fuel/Rare/Moonstone |
| construction_management | İnşaat Organizasyonu | Kamu | 350 | public_administration | İnşaat Dairesi |
| fuel_storage | Yakıt Depolama | Kamu | 200 | fuel_processing | Yakıt Deposu |
| recycling_1 | Geri Kazanım I | Kamu | 250 | root | Kredi iadesi %65 |
| recycling_2 | Geri Kazanım II | Kamu | 500 | recycling_1 | Kredi iadesi %75 |
| settlement_layout | Yerleşim Düzenleme | Kamu | 250 | root | İzinli yüzey düzenlemesi ve bina aktarımı |
| cluster_planning | Küme Planlama | Yakınlık | 200 | root | 3 seviye |
| independent_centers | Bağımsız Merkezler | Uzaklık | 200 | root | 3 seviye |
| cross_networks | Karma Ağlar | Yakınlık | 450 | cluster_planning, science_efficiency, trade_efficiency | Çapraz aile desteği |
| geography_specialization:<terrain_id> | Yerel Coğrafya Uzmanlığı | Coğrafya | 200 | root | Arazi kimliği başına ayrı 3 seviye |

### 17.17A. Tip 1 orbital destek ve ayrılmış ileri haklar

Bu tablo Tip 0 ortak yolunun ve Tip 0 miras hak kümesinin dışındadır. İlk tablodaki gerçek düğümlerde minimum_civilization 1, civilization_type 1 ve legacy_eligible true olur: Tip 0 Mirası bunları vermez, ileride Tip 1 Mirası kendi medeniyetinin gerçek haklarını kapsayabilir. Ayrılmış ileri yer tutucularında ise legacy_eligible false kalır. Demoda hiçbir satır satın alınamaz. Sadece medeniyet varış bayrağı, fiziksel yörünge kuruluşunu veya oynanabilir orbital içeriği açmaz.

| Canonical kimlik | Ad | Taban Science | ANY ebeveyn | Gerçek erişim |
| --- | --- | ---: | --- | --- |
| civilization_1_root | Tip 1 kökü | 0 | Yok | Gerçek tam oyun Tip 1 oynanabilirliği; demoda salt önizleme kökü |
| orbital_assembly | Orbital Kuruluş | 1.500 | civilization_1_root | Tip 1 Kamu/destek araştırması; fiziksel orbital oynanabilirlik ayrıca gerekli |
| orbital_storage | Orbital Depolama | 600 | orbital_assembly | Tip 1 fiziksel orbital kuruluş izni; Yörünge Yakıt Tankı model hakkı |

civilization_1_root bedelsiz araştırma köküdür; ücretsiz City, orbital merkez veya bina adedi oluşturmaz. İki ücretli destek düğümünün fiyatları taban fiyatlardır; aynı medeniyet strateji sayacı kuralı uygulanır.

| Ayrılmış canonical kimlik | Hedef hak | Durum |
| --- | --- | --- |
| orbital_science | Zero-G araştırma planı | Minimum Tip 1; tam orbital tasarımın ileri kapsamı |
| orbital_mirrors | Orbital enerji destek planı | Minimum Tip 1; tam orbital tasarımın ileri kapsamı |
| orbital_offworld_market | Orbital Commercial planı | Minimum Tip 1; tam orbital tasarımın ileri kapsamı |
| orbital_shipyard | Orbital sefer hazırlığı | Minimum Tip 1; Ay ana yolu koşulu değil |
| orbital_logistics | Orbital lojistik planı | Minimum Tip 1; tam orbital tasarımın ileri kapsamı |

Ayrılmış haklar etkin birer satın alma düğümü gibi davranmaz. Kendi fiziksel içerik tasarımları ve oynanabilirlik izni tamamlanmadan yalnız önizleme temsilidir. Tip 0 Mirası bu satırlardan hiçbirini vermez.
### 17.18. Özel desteklerin bina hakları

| Model | Birlikte gereken haklar |
| --- | --- |
| Financial District | public_administration + trade_networks |
| Research Directorate | public_administration + advanced_research |
| Housing Authority | public_administration + high_rise |
| Logistics Center | logistics |
| Planetary Command | advanced_coordination |
| İnşaat Dairesi | construction_management |
| Yakıt Deposu | fuel_storage |
| Yörünge Yakıt Tankı | orbital_storage, minimum_civilization 1 ve fiziksel orbital kuruluş izni; Tip 0 Mirası vermez |

Bu kapılar modelin başlangıçta açık işaretlenmesiyle atlanamaz.

### 17.19. Tekrarlı bonusların son etkileri

| Bonus | Lv1 | Lv2 | Lv3 |
| --- | --- | --- | --- |
| Photovoltaics | Solar +%10 | +%20 | +%30 |
| Superconducting Grid | Enerji ihtiyacı -%5 | -%10 | -%15 |
| Çıkarım Verimi | Raw +%10 | +%20 | +%30 |
| Bilim Verimi | Science +%10 | +%20 | +%30 |
| Konut Verimi | Bina konutu +%10 | +%20 | +%30 |
| Ticaret Verimi | Üretilen kredi +%10 | +%20 | +%30 |
| Yakıt Süreçleri | Fuel +%10 | +%20 | +%30 |
| Küme Planlama | Kaynak katkısı ×1,1 | ×1,2 | ×1,3 |
| Bağımsız Merkezler | Uzak bonusuna +10 puan | +20 puan | +30 puan |
| Coğrafya Uzmanlığı | Mevcut ilgili bonus ×1,1 | ×1,2 | ×1,3 |

Küme Planlama çok yakın %10 katkıyı %11, %12 ve %13 yapar.

Bu bonus kaynak sırası indirimi oluşturmaz.

Uzaklık skill'i yakın konumu uzak konuma dönüştürmez.

Coğrafya skill'i bulunmayan araziyi yaratmaz.

### 17.20. Nüfus stratejisinin araştırma karşılığı

| Hak | Hesap |
| --- | --- |
| Sivil Girişimler | Boş kapasitenin her 1.000'i için 10 kredi/dk |
| Serbest Araştırma | Boş kapasitenin her 1.000'i için 2 Science/dk |
| Üretim Rezervi | Her tam %10 boş oran için Raw/işlenmiş +%2, en fazla +%20 |

Boş kapasite bütün imparatorlukta hesaplanır.

Ücretsiz City kapasitesi bu hesaba dahildir.

Gelir konut kapasitesini tekrar artırmaz.

Üretim Rezervi konuta uygulanmaz.

Science veya kredi gelirini yeni yatırıma harcamak normal ilerlemedir.

Aynı gelirden kendi kapasitesini tekrar büyüten eşzamanlı bir hesap zinciri kurulmaz.

### 17.21. Çapraz aile ilişkisinin sınırı

cross_networks yalnız açıkça tanımlı başka aile kaynaklarını ekler.

Çok yakın uygun çapraz kaynağın katkısı %5'tir.

Yakın uygun çapraz kaynağın katkısı %2,5'tir.

Bütün uygun kaynaklar sayılır.

Bir kaynak aynı hedefe aynı etki kimliğiyle yalnız bir kez katkı verir.

Bonus almış nihai çıktının başka hedefe tekrar katsayı kaynağı yapılmasıyla özyinelemeli hesap kurulmaz.

### 17.22. Ek 16 araştırma yolunun eksiksiz eşlemesi

| Yol | Hedef canonical hak | Açtığı içerik veya işlev |
| --- | --- | --- |
| Yüzey Kazı Teknikleri | surface_excavation | Yüzey Ocağı |
| Cevher Ayıklama | ore_sorting | Büyük Goods üretimi |
| Küçük Ölçekli Yakıt | fuel_processing | Kompakt Yakıt Atölyesi |
| Yakıt Depolama | fuel_storage | Yakıt Deposu |
| Sığ Isı Kuyuları | shallow_heat | Sığ Jeotermal Kuyu |
| Sırt Rüzgârları | ridge_wind | Sırt Türbini |
| Mahalle İnşası | neighborhood_building | Düşük Katlı Konut |
| Kıyı Yoğunlaşması | coastal_density | Kıyı Apartmanları |
| Saha Araştırmaları | field_research | Saha Gözlem Evi |
| Yerel İşletmeler | local_business | Yerel Ticaret Merkezi |
| İnşaat Organizasyonu | construction_management | İnşaat Dairesi |
| Orbital Depolama | orbital_storage | Yörünge Yakıt Tankı |
| Ay Malzemeleri | lunar_materials | Ay Habitatı, yerel planlar, Lunar Spaceport |
| Ay Araştırmaları | lunar_research | Ay Numune Laboratuvarı |
| Ay İkmal Ağı | lunar_supply | Ay İkmal Pazarı |
| Yakıt Süreçleri | fuel_process_efficiency | Fuel çıktısı uzmanlığı |

Aynı ortak hak iki tabloda görünüyorsa iki ücret alınmaz.

### 17.23. Kaynaktaki 54 kimliğin hedef hakları

| Kaynak kimliği | Hedef canonical hak veya kapsam |
| --- | --- |
| root | root |
| unlock_spaceport | rocketry |
| unlock_space_station | orbital_assembly; minimum Tip 1, legacy_eligible false |
| unlock_zero_g_nexus | orbital_science; minimum Tip 1, legacy_eligible false |
| unlock_orbital_mirrors | orbital_mirrors; minimum Tip 1, legacy_eligible false |
| unlock_orbital_shipyard | orbital_shipyard; minimum Tip 1, legacy_eligible false; Ay yoluna zorunlu değil |
| unlock_orbital_offworld_market | orbital_offworld_market; minimum Tip 1, legacy_eligible false |
| unlock_moon | lunar_program |
| unlock_asteroids | İleri keşif önizlemesi |
| unlock_planetary_colonization | Tip 1 gerçek yerleşim; demoda kapalı |
| unlock_orbital_logistics | orbital_logistics; minimum Tip 1, legacy_eligible false |
| unlock_interstellar | İleri medeniyet sefer önizlemesi |
| unlock_solar_panel | start_energy |
| unlock_wind_turbine | wind_power |
| solar_efficiency | solar_efficiency |
| unlock_tidal_generator | tidal_power |
| power_transmission | grid_efficiency |
| unlock_geothermal_plant | geothermal_power |
| unlock_solar_matrix | solar_matrix |
| unlock_fusion_reactor | fusion_power |
| unlock_antimatter_chamber | İleri enerji planı; Tip 0 mirasına dahil değil |
| unlock_mining | start_production + processing_basics |
| unlock_rich_vein_excavator | advanced_excavation |
| mine_speed | extraction_efficiency |
| unlock_deep_drill | deep_drilling |
| deep_mining | extraction_efficiency |
| unlock_plasma_smelter | fuel_processing; büyük model için dense_fuel |
| unlock_molecular_forge | rare_processing |
| unlock_mantle_cracker | mantle_cracking |
| unlock_quantum_harvester | İleri Production önizlemesi |
| unlock_lab | start_science |
| science_income_1 | science_efficiency |
| unlock_mountain_observatory | mountain_optics |
| unlock_advanced_lab | advanced_research |
| science_income_2 | science_efficiency |
| unlock_particle_accelerator | particle_physics |
| unlock_quantum_computer | İleri bilim planı; Tip 0'da kapalı |
| unlock_residential | start_residential |
| housing_income_1 | housing_efficiency |
| unlock_seaside_villas | coastal_living |
| unlock_apartments | high_rise |
| housing_income_2 | housing_efficiency |
| unlock_luxury_complex | luxury_living |
| unlock_arcology | İleri konut planı; Tip 0'da kapalı |
| unlock_commercial | start_commercial |
| unlock_harbor_market | harbor_trade |
| unlock_bazaar | consumer_goods |
| trade_income_1 | trade_efficiency |
| unlock_trading_post | trade_networks |
| trade_income_2 | trade_efficiency |
| unlock_commodities_exchange | commodity_markets |
| unlock_logistics_center | logistics |
| unlock_command_center | advanced_coordination |
| unlock_central_bank | İleri ticaret planı; Tip 0'da kapalı |

### 17.24. Birleşen hakların hesabı

mine_speed ve deep_mining aynı yeni extraction_efficiency hakkına bağlanır.

science_income_1 ve science_income_2 aynı science_efficiency hakkına bağlanır.

housing_income_1 ve housing_income_2 aynı housing_efficiency hakkına bağlanır.

trade_income_1 ve trade_income_2 aynı trade_efficiency hakkına bağlanır.

Bu çiftlerin her biri iki ayrı +%30 etkisi vermez.

Veri ve arayüzde tek hedef kimlik, tek seviye ve tek fiyat kaydı kullanılır.

Kayıt şeması bu GDD'nin hedef kimliklerini kullanır.

### 17.25. Tip 1 temel araştırma düzeni

Tip 1'de beş City ailesi vardır.

Her City ailesinin beş temel rol çaprazı kurulabilir.

Böylece 25 temel district türü oluşur.

Bir Energy City içindeki Science rolü districti bilim üretimini korur ve host desteği alır.

Bir Science City içindeki Production rolü districti Raw üretimini korur ve host desteği alır.

Bu roller gerçek kuruluş türleridir.

Sadece aynı nesnenin görünür plan adı değildir.

### 17.26. Tip 1 district sayısı

| City ailesi | Temel tür | Özel tür | Toplam |
| --- | ---: | ---: | ---: |
| Energy City | 5 | 6 | 11 |
| Production City | 5 | 7 | 12 |
| Science City | 5 | 5 | 10 |
| Residential City | 5 | 3 | 8 |
| Commercial City | 5 | 4 | 9 |
| Toplam | 25 | 25 | 50 |

Bu tablo bütün özel türlerin başlangıçta açık olduğu anlamına gelmez.

### 17.27. Tip 1 açılış aşamaları

| Aşama | Erişim | Araştırmanın amacı |
| --- | --- | --- |
| Temel medeniyet kökü | 25 temel çapraz tür | Yeni ölçeği bütün ana kaynak rolleriyle oynayabilmek |
| İlk uzmanlık | Basit enerji, çıkarım, bilim, konut ve ticaret özel türleri | Coğrafya veya düşük yatırım seçmek |
| Yoğun üretim | İşlenmiş bakım isteyen özel türler | Alan/çalışan başına verim |
| Ağ ve destek | Büyük City'ye yönelik özel districtler | Yakınlık, host ve bakım uzmanlığı |
| Karma birleşme | Science-ticaret, nüfus-bilim, enerji-sanayi | Alternatif ebeveynlerle farklı gelişim |
| Üst ilerleme | Medeniyet geçişinin ortak düğümleri | Stratejiyi tek fabrika listesine zorlamadan ilerlemek |

Temel 25 türü açmak için Tip 0 Mirası'nın ayrıca satın alınması şart değildir.

Tip 1 kökü bu 25 districtin kabuğunu ve ekonomik rolünü açar; katalogdaki yoğun Lv2 referans planın bütün çocuk haklarını ücretsiz vermez. Solar Matrix, Research Institute, Apartments, Trade Hub veya başka bir çocuk modelin araştırması eksikse o çocuk kurulmaz ve plan kapsamına özel bir kilit aşma izni verilmez. Yerine ücretsiz başlangıç aile haklarıyla erişilen Tier 1 Solar Array, Lab, Habitat, Market veya Mine kullanan daha küçük, gerçek bedeli ödenen plan sunulur. Kartta bu gerçek alt içerik, daha düşük toplam bedel ve gerçek çıktı gösterilir; tamamlanmamış yoğun referansın geliri yazılmaz. Oyuncu eksik model hakkını bireysel araştırmayla veya gerçek miras satın alımıyla kazandığında yeni içerik ücretli Güncelle teklifine dönüşür. Araştırmanın açılması, boş yuvaya bile yeni bina adedini bedava eklemez.

Miras, önceki medeniyetin eksik gerçek haklarını tamamlayan ayrı bir ortak alımdır.

### 17.28. Tip 1 araştırmasının koşulları

Özel türün araştırması erişim verir.

City ailesi, yüzey konumu, mikro coğrafya ve sistemdeki AU kuşağı ayrıca denetlenir.

Araştırma almak uygun araziyi veya kaynak keşfini otomatik oluşturmaz.

Temel aynı aile yakınlığı açıktır.

Aynı alt türü özellikle güçlendiren bonuslar araştırmayla açılabilir.

Her bonus yalnız tanımlı kaynak ve hedef kapsamına uygulanır.

### 17.29. Host desteği ile mirasın ayrımı

Uyarlanan bir districtin mevcut ana üretimi korunur.

Host desteği aynı nesneye bir kez eklenen ayrı, sabit tanımlı bir akıştır.

Mirasın önceden uygulandığı alt çıktı üst özette yeniden çarpılmaz.

Bir City toplamı aynı gerçek alt üretimin görünümüdür.

Özet gelir ikinci bir üretici değildir.

### 17.30. Fraktal araştırmanın kesin kuralı

Tip 1'de gerçek Tip 0 ağacı tek ücretli Tip 0 Mirası düğümünde temsil edilir.

Bu düğüm satın alındığında bütün gerçek Tip 0 hakları azami seviyesine tamamlanır.

Tip 0 Mirası'nın kesin kümesi, minimum_civilization değeri 0 ve legacy_eligible değeri true olan canonical haklardır. Tip 0 ortak, strateji ve temel aile hakları bu iki alanla tanımlanır. Minimum Tip 1 orbital düğümleri, orbital_storage, ileri içerik yer tutucuları ve geleceğin dokuz önizleme hakkı bu kümeye girmez. Sonraki mirasların kendi alt medeniyet hak kümeleri de açık veri alanlarıyla belirlenir; yalnız görünür konum veya ad benzerliğiyle hak eklenmez.

Etkin seviye bireysel alınmış seviye ile miras seviyesinin büyüğüdür.

    etkin_seviye = max(bireysel_seviye, miras_seviyesi)

Photovoltaics Lv2 ve miras Lv3 birleşirse sonuç Lv3'tür.

Etki +%30 olur.

Lv5 veya +%50 olmaz.

### 17.31. Mirasın verdiği ve vermediği şeyler

| Mirasın verdiği | Mirasın vermediği |
| --- | --- |
| Eksik gerçek alt araştırmalar | Yeni bina adedi |
| Tekrarlı bonusların azami seviyesi | Ücretsiz district veya City |
| Model ve işlem erişimi | Yerel kaynak keşfi |
| Alt ağacı inceleme hakkı | Gerçek 100 Moonstone çıkarımı |
| Kalıcı canonical haklar | Spaceport inşaatı |
| Önceki özyinelemeli miras hakkı | Hazırlanmamış roket veya sefer |
| Eksik plan seçenekleri | Otomatik ücretsiz Güncelle |

Önceden kazanılmış etkiler satın alma öncesinde de çalışır.

Geçişte kapatılmaz.

Miras için önceki yatırımların otomatik kredi veya Science iadesi verilmez.

### 17.32. Miras fiyatları

| Yeni medeniyet | Önceki miras düğümü | Science tabanı |
| --- | --- | ---: |
| 1 | Tip 0 Mirası | 4.000 |
| 2 | Tip 1 Mirası | 40.000 |
| 3 | Tip 2 Mirası | 400.000 |
| 4 | Tip 3 Mirası | 4.000.000 |
| 5 | Tip 4 Mirası | 40.000.000 |

Tek kural 4.000 × 10^(yeni tip - 1) şeklindedir.

Bu fiyatlar sayısal taslaktır.

Çapraz dal zammı uygulanmaz.

Önceki mirası içeren daha üst miras, aynı alt bonusu tekrar eklemez.

### 17.33. Demodaki fraktal sunum

Varışta Tip 0 ağacının tek düğüme toplandığı gösterilir.

Oyuncu Tip 1 ağacını ve miras düğümünün açıklamasını inceleyebilir.

Tip 1 ağacındaki hiçbir düğüm demoda satın alınamaz.

Tip 0 Mirası da satın alınamaz.

Önizleme Science harcamaz, grant üretmez ve mevcut ekonomiyi değiştirmez.

Simülasyonlu Güncelle örneği gerçek inşaat kuyruğuna yazılmaz.

### 17.34. Araştırma uygulama sorumlulukları

| Kaynak | Sorumluluk |
| --- | --- |
| scripts/game/SkillTree.gd | Canonical düğümler, ANY/ALL koşulları, fiyat ve etkin hak |
| scripts/ui/SkillTreeView.gd | Büyük ağaç, dallar, alt açıklama ve satın alma durumu |
| scripts/game/BuildingDef.gd | Modelin araştırma hakkı ve kuruluş izinleri |
| scripts/game/DistrictDef.gd | District türü ile araştırma arasındaki bağ |
| scripts/game/GameState.gd | Satın alma işlemi, Science, kalıcı haklar, demo izni |
| scripts/game/ProductionManager.gd | Aynı hakkın gerçek çıktıya bir kez uygulanması |

### 17.35. Tip 1 özel districtlerinin tam araştırma kataloğu

Yirmi beş temel district modeli civilization_1_root ile model olarak açılır. Bunun anlamı erişilmemiş alt binaların bedava veya kilit atlanarak kurulması değildir. Tier 1 küçük plan kullanılabilir; daha yoğun gerçek alt içerik için ilgili Tip 0 hakkı önceden alınmış veya Tip 0 Mirası ile tamamlanmış olmalıdır. Tam paket sağlanamıyorsa Güncelle ve kuruluş teklifi erişilebilir çocuklarla gerçek çıktı ve fiyatı gösterir.

Her özel districtin ayrı, tek seviyeli bir araştırması vardır. Kimlik kuralı araştırmanın model kimliğine research_ öneki eklenmesidir. Örneğin t1_energy_stellar_collectors modelini research_t1_energy_stellar_collectors açar. Aşağıdaki tablo bu kuralın bütün yirmi beş modelini kapsar.

Bütün satırlarda:

- minimum_civilization = 1, civilization_type = 1, legacy_eligible = true ve max_level = 1. Bu haklar Tip 0 Mirası'na girmez; ileride Tip 1 Mirası'nın gerçek hak kümesine girer.
- parents_any yalnız civilization_1_root içerir.
- Ana dal, districtin Host City ailesidir; ortak çapraz dal fiyat artışı bu beş ana dal üzerinden çalışır.
- Tablodaki Tip 0 hakları required_access_all olarak birlikte aranır. Aynı canonical hakkın geçerli miras seviyesi bu koşulu karşılar.
- Araştırma fiyatı Science tabanıdır. Bina, mineral veya coğrafya hediyesi vermez.
- Fiziksel coğrafya, uygun City ailesi, kaynak keşfi ve düzenli bakım ayrı kuruluş/çalışma denetimleridir. Araştırma almak bunları tamamlamış sayılmaz.
- Modelin esas çıktısını taşıyan alt bina hakkı olmadan özel modeli açıp boş bir yoğun üretim paketi satmak yasaktır.
- Demoda araştırma ve district satın almalarının tamamı kapalıdır.

| Açılan model | Taban Science | Birlikte gereken Tip 0 hakları | Stratejik dal |
| --- | ---: | --- | --- |
| t1_energy_stellar_collectors | 500 | solar_matrix | Energy |
| t1_energy_atmospheric_grid | 500 | wind_power | Energy |
| t1_energy_tidal_heat | 750 | tidal_power, rare_processing | Energy |
| t1_energy_deep_heat | 750 | geothermal_power | Energy |
| t1_energy_outer_fusion | 1.000 | fusion_power, rare_processing | Energy |
| t1_energy_magnetosphere | 1.000 | solar_matrix, rare_processing | Energy |
| t1_production_belt_extraction | 500 | start_production | Production |
| t1_production_solar_smelting | 750 | ore_sorting, rare_processing | Production |
| t1_production_cryo_fuel | 750 | fuel_processing | Production |
| t1_production_stellar_synthesis | 1.000 | fuel_processing | Production |
| t1_production_magnetic_separation | 1.000 | rare_processing | Production |
| t1_production_vacuum_assembly | 750 | ore_sorting, rare_processing | Production |
| t1_production_system_supply | 500 | start_production | Production |
| t1_science_solar_observatory | 500 | advanced_research | Science |
| t1_science_deep_sky | 750 | advanced_research, rare_processing | Science |
| t1_science_magnetosphere | 1.000 | advanced_research, fuel_processing | Science |
| t1_science_cryo_lab | 1.000 | advanced_research | Science |
| t1_science_planet_ecology | 750 | advanced_research | Science |
| t1_residential_open_living | 500 | high_rise | Residential |
| t1_residential_under_ice | 750 | high_rise, fuel_processing | Residential |
| t1_residential_closed_ecosystem | 1.000 | high_rise, rare_processing | Residential |
| t1_commercial_belt_market | 500 | trade_networks, fuel_processing | Commercial |
| t1_commercial_inner_market | 500 | trade_networks | Commercial |
| t1_commercial_outer_exchange | 750 | trade_networks, fuel_processing | Commercial |
| t1_commercial_research_licensing | 750 | trade_access | Commercial |

T1 araştırma geçişleri yalnız uzun bir sıralı bina listesi oluşturmaz. Bir aileye yatırım başka ailenin yolunu kapatmaz. Geçerli Tip 0 uzmanlık hakları, ilgili farklı Tip 1 model yollarında yeniden kullanılır. Karma Ağlar ve açık alt tür uzmanlıkları bu ana dalları bağlar.

Tam referans RP paketinde bulunabilecek diğer fabrikalar kendi açılış koşullarını korur. Örneğin Kuşak Çıkarım Kompleksi'nin araştırması yalnız çıkarım yeteneği ister; oyuncunun açmadığı Rare Forge'u kendiliğinden kurmaz. Çıkarım bonusu gerçek Mine ve district çıkarımında çalışır, ileride açılmış fabrikalar ücretli Güncelle ile eklenebilir.

Cinderite ve Cryolite isteyen özel kuruluşlar bu kaynaklar keşfedilmeden kurulamaz. Araştırma açıklaması kaynak adını erken sızdırmaz. Gerekli kaynak adının görünmesi yalnız uygun gerçek yerel çıkarımla açılır; araştırma tablosunda yazan hedef erişimin oyunda önceden kazanıldığı anlamına gelmez.

### 17.36. Tip 1 alt tür uzmanlığı

Beş aile için aynı ortak araştırma tarifi kullanılır. research_t1_subtype_<family> kimliği, aile başına tek üç seviyeli düğümdür; minimum_civilization 1, civilization_type 1, legacy_eligible true, ebeveyn civilization_1_root, ilk seviye tabanı 500 Science, sonraki seviyeler 1.000 ve 1.500 Science'tır. Aynı çapraz dal fiyat kuralı ayrıca uygulanır.

Bu araştırma yalnız tamamen aynı gerçek district modelinden gelen uygun yakınlık katkısını seviye başına %10 artırır. Aile içindeki farklı modellerin temel yakınlığı korunur. Yeni bir gizli komşu sayısı sınırı oluşturulmaz.

Örnek: Çok yakın aynı modelin temel %10 katkısı Lv1'de %11, Lv2'de %12, Lv3'te %13 olur. Başka modelin aynı aile katkısı %10 kalır. Küme Planlama gibi ayrı bir araştırma da varsa yüzde artışları aynı ilişki güçlendirme grubunda toplanır; bu katkı iki kez kaynak olarak eklenmez. Aynı kaynak için iki ayrı %10 temel kayıt yaratılmaz.

<a id="bolum-18"></a>

## 18. Trade, tarifler, rezervler ve otomasyon

### 18.1. Trade'in oyun içindeki rolü

Trade uzmanlaşmış ekonomilerin eksik ürünleri edinmesini sağlar.

Oyuncu bütün işlenmiş ürünleri kendi fabrikalarında üretmek zorunda değildir.

Goods, Fuel ve Rare ilerleme tariflerinde yine gereklidir.

Trade bu ürünlerin değerini ortadan kaldırmaz.

Science krediyle alınabilir ve satılabilir.

Kredi ve Science online oyunda stok üst sınırına sahip değildir.

### 18.2. Erişim aşamaları

| Hak | Bedel | İşlev |
| --- | ---: | --- |
| Ticaret Erişimi | 150 Science | Manuel malzeme ve Science alış/satışı |
| Taşma satışı | Ticaret Erişimi içinde | Depoya sığmayan yeni malzemeyi krediye çevirme |
| Ticaret Otomasyonu | 300 taban Science | Rezerv üstü satış ve hedef stok alışı |

Manuel Science satışı için otomasyon araştırması gerekmez.

Manuel Science alışı için de otomasyon gerekmez.

### 18.3. Referans ve alım/satım fiyatları

| Ürün | Referans kredi/adet | Satış fiyatı | Alış fiyatı |
| --- | ---: | ---: | ---: |
| Ferrite | 2 | 1,8 | 2,2 |
| Moonstone | 3,5 | 3,15 | 3,85 |
| Science | 5 | 4,5 | 5,5 |
| Goods | 22 | 19,8 | 24,2 |
| Fuel | 34 | 30,6 | 37,4 |
| Rare | 92 | 82,8 | 101,2 |

Satış referansın %90'ıdır.

Alış referansın %110'udur.

Gelecek ham kaynak referansı 2 × nadirlik verimidir.

Bu fiyatlar ilk denge taslağıdır.

Arz/talep veya sürekli oynayan piyasa sistemi yoktur.

### 18.4. Ücret farkının örneği

100 Goods almak 2.420 kredi ister.

Aynı 100 Goods'ı satmak 1.980 kredi verir.

Anında alış-satış 440 kredi kaybettirir.

Geri dönüş oranı yaklaşık %81,82'dir.

Yalnız para birimleri arasında dönmek kredi yaratmaz.

Gerçek üretimle işlenmiş ürüne değer katmak ise geçerli ekonomik faaliyettir.

### 18.5. Keşif şartı

Ham kaynağa erişim için ilgili medeniyet ve uygun doğal gövdede tamamlanmış, gerçek yerel çıkarım capability'si taşıyan bir varlık gerekir. Denetim yalnız Host veya City ailesinin adına bakmaz. Science City içindeki Production rolü gerçek bir çıkarıcı taşıyorsa geçerlidir; işleme-only model veya host desteğinin yan Raw akışı geçerli değildir.

Kaynağın fiziksel gövdenin mineral kümesinde bulunması gerekir.

Bir mineral yatağı veya yoğunluk haritası şartı yoktur.

Kaynak erişimi açılmadan trade teklifinde adı veya fiyatı görünmez.

Önizlenen kilitli bir gezegende mineral adını görmek keşif sayılmaz.

Trade ilk erişimi satın alamaz.

### 18.6. Ürün erişimi

Goods başlangıçtan işlemeye açıktır.

Fuel için fuel_processing gerekir.

Rare için rare_processing gerekir.

Bu haklardan sonra ürünün fabrikası kurulmadan da ürün alınabilir.

Science ve kredi ürün keşfi gibi yerel mineral koşuluna bağlanmaz.

Yakıt veya Rare alımı araştırma kapısını atlamaz.

### 18.7. İlk üretici kendi kaynağını istemez

Yeni bir gövdenin ilk uygun Production kuruluşu erişimi açacağı minerali zorunlu bedel olarak istemez.

Örneğin Cinderite veya Cryolite'ı keşfedecek ilk üretici, daha keşfedilmemiş aynı kaynağı kuruluş bedeline koymaz.

İlk kuruluş erişilmiş önceki malzemeler ve krediyle yapılır.

Kaynak adı kilitliyken “eksik Cinderite” gibi maliyet hatası gösterilmez.

### 18.8. Global stok ve temin

Satın alınmış ürün global stoğa girer.

Kullanılacağı gezegene fiziksel kargo gönderme şartı yoktur.

Aynı global ürünü iki eşzamanlı ödeme kullanamaz.

Trade kaydı kaynak girişi, kredi gideri ve varsa offline kotayı tek işlemde sonuçlandırır.

### 18.9. Ortak 20 saniyelik işleme tarifleri

| Tarif | R1 ham girdisi | R1 çıktı | R2 ham girdisi | R2 çıktı |
| --- | ---: | ---: | ---: | ---: |
| Temel Goods | 4 | 2 Goods | 4 | 3,5 Goods |
| Kompakt Fuel | 8 | 2 Fuel | 8 | 3,5 Fuel |
| Rare Forge | 12 | 1 Rare | 12 | 1,75 Rare |

R2 çıktı çarpanı 1,75'tir.

R3 çarpanı 2,50'dir.

Sonraki her nadirlik 0,75 ekler.

Nadirlik girdiyi azaltan ikinci bir katsayı olarak ayrıca uygulanmaz.

Oyuncu seçtiği ham türüyle alacağı çıktıyı görür.

### 18.10. Çıktı başına yalın ham ihtiyacı

| Ürün | R1 ham/adet | R2 ham/adet |
| --- | ---: | ---: |
| Goods | 2 | Yaklaşık 1,142857 |
| Fuel | 4 | Yaklaşık 2,285714 |
| Rare | 12 | Yaklaşık 6,857143 |

Bu oranlar üretim bonusu ve açık cezası olmadan geçerlidir.

Tam tur ve gerçek stok hareketleri kesirli hassasiyetle saklanır.

Arayüzde yuvarlamak gerçek kaynağı her turda kesmez.

### 18.11. Sanayi kârını değerlendirmek

| Üretici | Dakikada R1 girdi | Dakikada çıktı | Çıktının satış değeri | Girdi alım bedeli | Yalın fark |
| --- | ---: | ---: | ---: | ---: | ---: |
| Goods Factory | 12 Ferrite | 6 Goods | 118,8 | 26,4 | 92,4 |
| Kompakt Fuel | 24 Ferrite | 6 Fuel | 183,6 | 52,8 | 130,8 |
| Rare Forge | 36 Ferrite | 3 Rare | 248,4 | 79,2 | 169,2 |

Fark enerji, çalışan, district, bakım ve yatırımın bütün bedelini içermez.

Bu tablo satış gelirini girdiler ücretsizmiş gibi göstermemek içindir.

### 18.12. Kendi hammaddesinin fırsat maliyeti

| Üretici | Kullanılan Ferrite'ın satış değeri/dk | Çıktı satışından sonra yalın katkı/dk |
| --- | ---: | ---: |
| Goods Factory | 21,6 | 97,2 |
| Kompakt Fuel | 43,2 | 140,4 |
| Rare Forge | 64,8 | 183,6 |

Kendi üretilmiş ham madde kredi bakımından bedelsiz giriş gibi görünse de satılabilecek değeri vardır.

Bu nedenle yerel çıkarım ile ithal girdi karşılaştırılırken iki farklı net sütun tutulur.

### 18.13. Taşmanın davranışı

| Durum | Yeni malzeme taşması |
| --- | --- |
| Trade kapalı | Depoya sığmayan yeni kısım kaybolur |
| Trade açık ve online | Satış fiyatıyla krediye çevrilir |
| Trade açık ve offline kredi hakkı var | Yalnız kota içinde kalan satış yapılır |
| Trade açık ve offline kredi hakkı yok | Yeni döngü kapasite/kota koşuluna göre bekler |
| Depo yıkılmasıyla eski stok kapasite üstünde | Eski stok korunur; yeni üretim gibi satılmaz |

Taşma satışı otomasyon araştırmasına bağlı değildir.

Kapasite üstündeki eski stok yeniden üretilmiş kaynak değildir.

### 18.14. Satılabilir stok

    Satılabilir stok = max(0, gerçek stok - zorunlu ayrılmış stok - oyuncu rezervi)

Zorunlu ayrılmış stok başlamış turun girdisini ve ilan edilmiş geçerli ödeme rezervini kapsar.

Oyuncu rezervi roket için tutulan ürün gibi açık bir tercihtir.

Aynı miktar iki farklı rezervde iki kez satılabilir görünmez.

### 18.15. Otomasyon emri alanları

| Alan | Anlam |
| --- | --- |
| product_id | Erişilmiş gerçek ürün kimliği |
| enabled | Emir açık mı |
| buy_target | Satın alarak ulaşılacak hedef |
| sell_start | Satışın başlayacağı stok |
| reserve_min | Korunacak miktar |
| credit_reserve | Alışta korunacak asgari kredi |
| priority | Eşzamanlı emirlerin açık sırası |
| max_per_cycle | Bir 20 saniyelik ekonomi kararında üst miktar |
| permission | Keşif ve oynanabilir içerik denetimi |

### 18.16. Alış ve satış birlikte çalışırken

Aynı ürün için buy_target, sell_start değerini aşamaz.

Rezerv satılabilir miktardan önce ayrılır.

Kapasiteyi aşan hedef stok emri kurulamaz.

Kredi rezervi altına düşen alış yapılmaz.

Kredi yetmiyorsa karşılanabilir kısım alınır.

İşlem borç yaratmaz.

### 18.17. Otomasyon örneği

| Ürün | Alış hedefi | Satış başlangıcı | Korunan rezerv |
| --- | ---: | ---: | ---: |
| Fuel | 80 | 180 | 150 |
| Rare | 20 | 90 | 50 |
| Moonstone | 0 | 1.500 | 1.200 |
| Science | 0 | 1.000 | 600 |

Fuel rezervi 150 iken otomatik satış bunun altına inmez.

Fuel alış hedefi 80 olduğu için stok 150'deyken alış tetiklenmez.

Bir ürünün alış hedefi ve rezervi farklı amaçlar için kullanılabilir.

Arayüz emrin gerçek davranışını kısa cümleyle açıklar.

### 18.18. Kuruluş rezervleri

Oyuncu bir roket veya büyük kuruluş bedelini açıkça rezerve edebilir.

Rezerv kaynak sahipliğini değiştirmez.

Başka emirler bu miktarı satamaz veya harcayamaz.

Oyuncu rezervi iptal ederse kaynak tekrar kullanılabilir olur.

Gerçek inşaat başladığında rezerv bir kez ödemeye dönüşür.

Aynı rezerv hem ödeme hem ayrıca stok gideri olarak iki kez uygulanmaz.

### 18.19. Ortak olay sırası

1. Aynı anda tamamlanan önceki işler ve serbest kalan rezervler değerlendirilir. Önceden ayrılmış geçerli tur/kuruluş rezervleri korunur; henüz yeni tur girdisi alınmaz.
2. Girdisi zaten ödenmiş ve vadesi gelmiş bütün gerçek üretim çıktıları bir kez sonuçlandırılır.
3. Depoya sığan malzeme eklenir ve izinli yeni taşma satışı uygulanır.
4. Oyuncunun tanımladığı rezerv üstü otomatik satışlar tamamlanır.
5. Kredi rezervi, kapasite, kota ve erişim izinleri içinde otomatik alışlar yapılır.
6. Bir sonraki dönemin vadesi gelen bakım bedelleri ve korunan rezervleri aynı stok defterinde değerlendirilir.
7. Bakım sonrası aktif kapasite, enerji, çalışan ve açık koşulları ortak fonksiyondan hesaplanır.
8. Ancak bundan sonra yeni başlayabilecek üretim turları seçilir; girdi, vaat edilmiş çıktı ve gerekiyorsa offline kota hakları tek atomik işlemle ayrılır.

Bağlayıcı sıra tamamlanmış üretim, ardından trade, ardından yeni tur girdileridir. Yeni turun girdisini önce düşerek aynı anın tamamlanmış çıktısını veya geçerli otomatik alımını yok sayma. Bakım için geçmiş turda zaten ödenmiş veya ayrılmış miktar yeniden alınmaz. Bu sıra online ve offline için aynıdır.

Online ve offline aynı sırayı kullanır.

Satın alınmış malzeme geçmişte tamamlanmış turun girdisi gibi geriye dönük kullanılamaz.

### 18.20. Science alımı ve satımı

Science satın almak skill satın almak değildir.

Satın alınan Science cüzdana girer.

Oyuncu gerçek araştırmayı ayrıca seçer.

Offline otomasyon Science satın alabilir.

Offline sistem bu Science'ı kendiliğinden bir skill'e harcamaz.

### 18.21. Düşük stok ve girdi tercihi

Seçili ham türü biterse üretici başka türe sessizce geçmez.

Aynı aile içindeki farklı girdi grupları ayrı tarif kaydı taşır.

Grup başlatma hesabı tam üretici adetleriyle yapılır.

Kaynak yalnız bazı adetlere yetiyorsa uygun tam adetler çalışır, kalanlar girdi bekler.

Aynı girdi isteyen gruplar sabit kimlik sırasını her tur döndüren adil bir sırayla değerlendirilir.

Ödenmiş turun tarifini girdi seçimi değiştirmez.

Yeni girdi tercihi henüz başlamamış turlara uygulanır.

### 18.22. Ticaretin fiziksel görevlerle ilişkisi

Satın alınmış 100 Moonstone, 100 yerel çıkarım olayına eşit değildir.

Moonstone satın almak ilk keşif koşulunu atlamaz.

Satın alınan Fuel ise “gerekli Fuel'ı edin” hedefinde geçerlidir.

Satın alınan Rare, araştırması açık son roket ödemesinde geçerlidir.

Trade bir Spaceport'u tamamlanmış veya roketi varmış saymaz.

### 18.23. Trade kayıt alanları

Alış ve satış tekil işlem kimliği taşır.

Ürün miktarı, fiyat, kredi farkı ve işlem zamanı saklanır.

Fiyat ve kota denetimi stok düşümünden önce yapılır.

İşlem yarım kalırsa ya bütün kaynak hareketleri uygulanır ya hiçbiri uygulanmaz.

Aynı kayıt yüklenince işlem tekrar çalışmaz.

### 18.24. Trade uygulama sorumlulukları

| Alan | Kaynak / servis |
| --- | --- |
| Referans fiyat ve erişim | scripts/game/Economy.gd ve ortak kaynak tanımları |
| Gerçek stok ve para | scripts/game/GameState.gd |
| Tarifin girdi ve vaat edilmiş çıktısı | scripts/game/ProductionManager.gd |
| Modelin giriş/çıkış tanımı | scripts/game/BuildingDef.gd |
| Trade emirleri | Ortak trade servisi ve kayıt verisi |
| Fiyat, rezerv ve hata sunumu | HUD ve trade paneli |
| Offline bağlantısı | Aynı kaynak hareketi servisi |

<a id="bolum-19"></a>

## 19. Offline ilerleme ve kazanç bütçeleri

### 19.1. Offline seçeneği

Offline ilerleme varsayılan açıktır.

Oyuncu ayarlardan kapatabilir.

Offline açıkken kapalı geçen gerçek sürenin onda biri ortak ekonomi zamanı olur.

Üretim için ayrı, bakım veya uçuş için ayrı hız kullanılmaz.

    Offline ekonomi saniyesi = geçerli kapalı gerçek saniye × 0,10

### 19.2. Zaman örnekleri

| Gerçek kapalı süre | Ekonomi ilerlemesi |
| --- | --- |
| 10 dakika | 1 dakika |
| 30 dakika | 3 dakika |
| 1 saat | 6 dakika |
| 5 saat | 30 dakika |
| 10 saat | 1 saat |
| 24 saat | 2 saat 24 dakika |
| 7 gün | 16 saat 48 dakika |

Bu süre tablosu sınırsız kredi ve Science hakkı vermez.

Para ve Science ayrı kazanç bütçelerine tabidir.

### 19.3. Kapsanan sistemler

| Sistem | Offline davranışı |
| --- | --- |
| Raw üretimi | Gerçek girdiler, kapasite ve açık koşullarıyla ilerler |
| Goods/Fuel/Rare | Seçili gerçek tarifi kullanır |
| Science ve kredi üretimi | Kalan kazanç bütçesi içinde ilerler |
| Bakım | Aynı ortak zamanda ödenir |
| Trade otomasyonu | Oyuncunun önceden verdiği emirleri uygular |
| İnşaat | Başlamış iş tamamlanabilir |
| District/City/gezegen yükseltmesi | Başlamış işlem ilerler |
| Roket hazırlığı | Başlamış hazırlık ilerler |
| Uçuş | Başlamış sefer varabilir |
| Skill satın alma | Kendiliğinden yapılmaz |
| Yeni City veya district | Kendiliğinden başlatılmaz |
| Yeni hedef veya yeni roket | Kendiliğinden seçilmez |

### 19.4. Kredi ve Science tavanının niteliği

Online cüzdana üst sınır konmaz.

Offline tavanı cüzdan toplamı değil, offline kaynaklı yeni pozitif kazanç bütçesidir.

Oyuncunun online biriktirdiği para offline açılışta silinmez.

Offline kazandığını harcamak yeni bütçe yaratmaz.

Para ve Science bütçesi ayrı tutulur.

### 19.5. Medeniyete bağlı azami bütçeler

| Medeniyet | Kredi bütçesi | Science bütçesi |
| --- | ---: | ---: |
| 0 | 10.000 | 2.000 |
| 1 | 100.000 | 20.000 |
| 2 | 1.000.000 | 200.000 |
| 3 | 10.000.000 | 2.000.000 |
| 4 | 100.000.000 | 20.000.000 |
| 5 | 1.000.000.000 | 200.000.000 |

    Azami kredi bütçesi = 10.000 × 10^medeniyet
    Azami Science bütçesi = 2.000 × 10^medeniyet

Bu katsayılar ilk sayısal denge ayarıdır.

### 19.6. Kullanılabilir bütçenin dolması

Yeni oyunda iki bütçe doludur.

Bütçeler yalnız oyun açık ve ekonomi aktifken dolar.

60 gerçek aktif online dakika bir tam bütçe doldurur.

Bütçe üst sınıra ulaşınca dolum durur.

Offline süre bütçeyi doldurmaz.

Duraklatma bütçeyi doldurmaz.

Kapatıp açmak bütçeyi doldurmaz.

Takvim günü değişmesi bütçeyi sıfırlayıp yeniden vermez.

### 19.7. Dolum örnekleri

| Tip 0 aktif online süre | Boştan dolan kredi hakkı | Boştan dolan Science hakkı |
| --- | ---: | ---: |
| 1 dakika | 166,6667 | 33,3333 |
| 6 dakika | 1.000 | 200 |
| 12 dakika | 2.000 | 400 |
| 30 dakika | 5.000 | 1.000 |
| 60 dakika | 10.000 | 2.000 |

Kesirli haklar kaydedilir.

Her karede küçük miktarı sıfıra yuvarlamak dolumu bozmaz.

Görsel yuvarlama gerçek bütçeyi değiştirmez.

### 19.8. Zaman kaynağı

Online dolum gerçek aktif süreyle ölçülür.

Oyun hızını artırmak bütçeyi hızlandırmaz.

Takvim saatini ileri almak aktif online dakika sayılmaz.

Duraklatma sırasında ölçülen süre doluma eklenmez.

Gerçek zaman kaynağı sistem saatinden bağımsız tekdüze sayaçtır.

### 19.9. Medeniyet geçişinde bütçe

Kota üst sınırı civilization_type alanından hesaplanır.

playable_content_type bu sayısal üst sınırın yerine kullanılmaz.

Bu nedenle demo varışından sonraki aktif online dolum Tip 1 bütçesine göre işler; Tip 1 içerik satın alma izni yine kapalıdır.

Medeniyet geçişi üst sınırı artırır.

Kalan mevcut hak korunur.

Yeni üst sınırın tamamı anında hediye edilmez.

Örneğin Tip 0'dan 3.000 kredi hakkıyla çıkılmışsa Tip 1 başlangıcında hak yine 3.000'dir.

Sonraki online aktif sürede yeni üst sınıra göre dolar.

### 19.10. Offline dönemde medeniyet değişmesi

Offline dönemin kullanılabilir bütçesi kapanış durumundan sabitlenir.

Ay roketi offline varıp Tip 1'i açabilir.

Aynı kapalı dönemde kalan süre Tip 1'in yeni büyük bütçesini hediye almaz.

Varış sonrası Dünya/Ay ekonomisi mevcut kapanış hakkı içinde çalışır.

Oyuncu döndükten sonraki aktif online dolum yeni medeniyete göre ilerler.

### 19.11. Kotaya giren pozitif akışlar

| Akış | Kullanılan bütçe |
| --- | --- |
| City taban kredi geliri | Kredi |
| Commercial üretimi | Kredi |
| Boş nüfus kapasitesi kredi geliri | Kredi |
| Science üretimi | Science |
| Boş kapasite Science geliri | Science |
| Ürün satışı | Kredi |
| Science satışı | Kredi |
| Krediyle Science alımı | Science |
| Otomatik pozitif para iadesi | İlgili para |
| Kredi veya Science harcaması | Bütçeyi geri doldurmaz |

Görevlerin ekonomik ödülü 0'dır.

Buna rağmen ortak kaynak kapısı yeni eklenen herhangi bir otomatik pozitif akışın da bütçeyi atlamasını engeller.

### 19.12. Satışla kotayı aşmama örneği

Oyuncu offline 10.000 kredi üretir.

Bu parayı Fuel'a harcar.

Kredi cüzdanı düşer, fakat offline kredi hakkı yine 0'dır.

Oyuncunun Fuel'ı daha sonra yeniden satması aynı offline dönemde yeni kredi hakkı yaratmaz.

Alış/satış işlemi kullanılmış bütçeyi sıfırlamaz.

### 19.13. Science örneği

Oyuncu 2.000 Science üretip hepsini satar.

Science bütçesi 0 olur.

Satış kredisi ayrıca kredi bütçesini kullanır.

Science cüzdanının sıfıra inmesi yeni 2.000 Science üretme hakkı vermez.

Krediyle alınacak Science da kalan Science hakkıyla sınırlıdır.

### 19.14. Alıştan önce miktarı sınırlama

Alış miktarı ödeme yapılmadan hesaplanır.

Kalan Science hakkı 30 ve sipariş 100 ise en fazla 30 Science alınır.

Yalnız bu 30'un kredi bedeli tahsil edilir.

Önce 100 satın alıp sonra 70'i kota nedeniyle silmek yasaktır.

Malzeme alımında depo boşluğu ve kaynak erişimi aynı biçimde önceden denetlenir.

### 19.15. Üretim için kota rezervi

Yeni maliyetli offline döngü, beklenen para/Science çıktısı için önceden hak ayırır.

Bir tam üretici adedinin çıktısına yetmeyen hak o adedi başlatmaz.

Girdisi alınmaz.

Daha küçük başka bir akış kalan hakkı kullanabilir.

Bir üretimin ayırdığı hak aynı anda trade satışına ayrılmaz.

### 19.16. Önceden başlamış turun sınırı

Online başlamış ve girdisi ödenmiş bir tur offline tamamlanabilir.

Örneğin 20 Science'lık tur sonunda yalnız 3 Science hakkı kalmışsa en fazla 3 verilir.

Kalan 17, offline sınırı nedeniyle üretilemeyen potansiyeldir.

Gizli Science borcu veya sonraki online oturumda verilecek depo oluşturmaz.

Önceden tüketilmiş girdi geri verilmez.

Bu son tur durumu daha fazla boş döngü başlatmaz.

### 19.17. Malzeme ile para kotasının ayrımı

Raw/Goods/Fuel/Rare kendi fiziksel kapasitesine tabidir.

Bu malzemeler için kredi/Science gibi ayrı yeni kazanç kotası yoktur.

Malzeme depoya sığıyorsa üretilebilir.

Trade açıkken taşmayı satmak kredi bütçesi ister.

Kredi hakkı yoksa satılacak stok para alınmadan tüketilmez.

### 19.18. Depo ve satış hakkı birlikte bittiğinde

Depo dolu ve satış hakkı yoksa yeni ilgili üretim döngüsü başlamaz.

Yeni tur girdisi alınmaz.

Önceden ödenmiş en fazla bir tur/çalışan adet çıktısı tamamlanma bekleyebilir.

Bu bekleyen malzeme sonsuz gizli depo değildir.

İlgili yer açıldığında aynı çıktı bir kez aktarılır.

Kredi ve Science için bu bekleyen malzeme kuralı kota aşmak amacıyla kullanılamaz.

### 19.19. Yerel akışın beklemesi bütün oyunu durdurmaz

| Durum | Devam edebilen işler |
| --- | --- |
| Science kotası bitti | Malzeme üretimi, uygun kredi akışları, inşaat, uçuş |
| Kredi kotası bitti | Science hakkı içindeki üretim, depoya sığan malzeme, uçuş |
| Bir mineral bitti | Başka girdili gruplar, bağımsız üretim |
| Bir depo doldu | Başka kaynaklar ve kapasite işlemleri |
| Fuel bakımını ödeyemeyen yapı | Bakımsız alternatifler ve diğer bağımsız işler |

### 19.20. Kullanıcı duraklatması

Oyuncunun durdurduğu grup offline çalışmaz.

Kaynak yetersizliğinden bekleyen grup, koşul düzeldiğinde normal kurala göre tekrar başlayabilir.

Kullanıcı duraklatması ile otomatik bekleme farklı durum kodlarıdır.

Offline sistem kullanıcının tercihini gizlice kaldırmaz.

### 19.21. Olay zamanıyla hesaplama

Offline hesap kapanış durumunu yükler.

Bir sonraki sonucu değiştiren olay zamanına ilerler.

Olay uygulanır.

Kaynak, kota, kapasite ve açık koşulları yeniden hesaplanır.

Ardından sıradaki olay seçilir.

Bütün süreyi tek kapanış üretim hızına çarpmak yeterli değildir.

### 19.22. Olay türleri

| Olay | Yeniden değerlendirilen şey |
| --- | --- |
| İnşaat tamamlanması | Yeni üretici, kapasite, yük |
| Bakım dönemi | Girdi, aktif kapasite, çalışan ve enerji |
| Üretim turu sonu | Gerçek stok ve satış |
| Girdi tükenmesi | Başlayabilecek adetler |
| Depo dolması | Taşma veya bekleme |
| Kota tükenmesi | İzinli para/Science akışları |
| Otomatik alış | Sonraki tur girdileri |
| Yükseltme sonu | Seviye, yuva, yük ve üretim |
| Uçuş varışı | Görev, medeniyet, demo izni |

### 19.23. İnşaat örneği

Oyuncu 10 dakika kapalı kalır.

Bu bir ekonomi dakikasıdır.

Kapanışta dört ekonomi saniyesi sonra tamamlanacak bir Lab vardır.

Lab ilk dört saniyede üretmez.

Tamamlandıktan sonraki 56 ekonomi saniyesinde normal döngü kurallarına katılır.

Kapanış anındaki bina listesini bütün dakikaya uygulamak yeni Lab'ın katkısını kaybeder.

### 19.24. Uçuş örneği

Gelişmiş roketin 60 ekonomi saniyelik uçuşu başlamıştır.

Oyuncu 10 gerçek dakika kapalı kalır.

Sefer tamamlanır.

Varış olayı bir kez çalışır.

Hedefte otomatik yerleşim oluşmaz.

Kalan offline zaman varsa Dünya/Ay ekonomisi sürer.

Tip 1 önizlemesi oyuncu döndüğünde erişilebilir olur.

### 19.25. Kararlı aralıkların toplu hesabı

Çıktı, girdi ve otomasyon kuralları değişmiyorsa aynı döngüler toplu hesaplanabilir.

Toplu hesap stok bitişi, kota sınırı veya yeni olaydan öteye körlemesine ilerlemez.

Her kareyi canlandırmak gerekmez.

Aynı anda bütün önizleme gezegenleri ekonomi nesnesi olarak oluşturulmaz.

Yalnız gerçek sahip olunan aktif ekonomi işlenir.

### 19.26. Tek seferlik zaman kaydı

Kapanış zamanı ve son işlenmiş offline aralık saklanır.

Aynı aralık ikinci kez uygulanmaz.

Kayıt yüklemek aynı sonucu yeniden ödemez.

Kaynak hareketi ve işlenmiş aralık kaydı birlikte tamamlanır.

İşlem yarıda kalırsa yarım stokla tam işlenmiş zaman kaydedilmez.

### 19.27. Sistem saati geriye giderse

Negatif geçen süre 0 sayılır.

Son işlenmiş zaman geriye çekilmez.

Saat tekrar normale gelince geriye alınmış aralık ikinci bir ödül alanı oluşturmaz.

Online bütçe dolumu takvim saatini zaten kullanmaz.

### 19.28. Offline ayarını kapatma

Ayar kapandığı andan sonraki süre hesaplanmaz.

Ayarın daha önce açık olduğu geçerli aralık bir kez sonuçlandırılır.

Tekrar açmak kapalı bırakılmış geçmişi geriye dönük toplamaz.

Ayar değişikliği kullanılabilir bütçeyi doldurmaz veya boşaltmaz.

### 19.29. Sonuç ekranı

| Gösterge | İçerik |
| --- | --- |
| Gerçek kapalı süre | Saat/dakika |
| İşlenmiş ekonomi zamanı | Gerçek sürenin onda biri |
| Brüt üretim | Ürün bazında |
| Gerçek tüketim | Tarif ve bakım ayrı |
| Trade sonucu | Alış/satış ve net kredi |
| Kota kullanımı | Kredi ve Science ayrı |
| Net stok değişimi | Gerçek son fark |
| Tamamlanan işler | İnşaat, yükseltme, varış |
| Bekleyen işler | Girdi, depo, kota veya kullanıcı duraklatması |

Özet ekranını kapatmak ödeme tetikleyicisi değildir.

Kazanç hesap sonucunda kayda işlenmiştir.

Ekranı tekrar açmak yeni kaynak vermez.

### 19.30. Kaydedilen offline alanları

| Alan | Anlam |
| --- | --- |
| offline_enabled | Oyuncu tercihi |
| offline_credit_budget | Kullanılabilir kredi hakkı |
| offline_science_budget | Kullanılabilir Science hakkı |
| quota_civilization | Üst sınırın dayandığı medeniyet |
| active_online_refill | Kesirli dolum durumu |
| last_processed_wall_time | Son işlenmiş takvim noktası |
| processed_interval_id | Aynı aralığın tekrarlanmaması |
| pending_transactions | Atomik kaynak hareketleri |
| closing_permissions | Kapalı dönem başlangıç yetkileri |
| closing_quota_limit | Dönem ortasında yeni hediye oluşmaması |

### 19.31. Offline uygulama sorumlulukları

| Kaynak | Sorumluluk |
| --- | --- |
| scripts/game/ProductionManager.gd | Online ile ortak tur/olay hesapları |
| scripts/game/GameState.gd | Kaynak kapısı, kayıt, işlenmiş aralık |
| scripts/system/SettingsManager.gd | Ayar ve tercih kalıcılığı |
| Ortak trade servisi | Aynı alış/satış ve rezerv hesapları |
| Sefer servisi | Tek varış olayı |
| Görev/başarım servisi | Tek seferlik ilerleme |
| HUD | Gerçek net değişim ve bekleme nedeni |

<a id="bolum-20"></a>

## 20. Ay, roketler ve Medeniyet 0'ın tamamlanması

### 20.1. Sefer modelinin kapsamı

Roketler sade hazırlık, hedef seçimi ve varış olaylarıdır.

Bir filoyu elle yönetmek gerekmez.

Kargo seferiyle global stok taşımak gerekmez.

Manuel rota veya yakıtlı gemi simülasyonu eklenmez.

Dünya-Ay lander'ı ile Ay-diğer gezegen gelişmiş roketi ayrı seferlerdir.

### 20.2. Temel sefer durumları

| Durum | Anlam |
| --- | --- |
| locked | Araştırma veya fiziksel şart eksik |
| ready_to_prepare | Bedel karşılanabilir, hazırlık başlayabilir |
| preparing | Ödeme alınmış, fiziksel hazırlık sürüyor |
| ready_to_launch | Hazırlık tamamlanmış |
| in_transit | Hedef kilitli, yolculuk sürüyor |
| arrived | Tek başarılı varış olayı oluşmuş |

Aynı sefer durum değişimi kaynak bedelini yeniden almaz.

### 20.3. Dünya Capital hazırlığı

| Şart | Bedel | Süre | Sonuç |
| --- | --- | --- | --- |
| Capital Lv1 -> Lv2 | 250 kredi, +500 yük | 10 sn | 2 Capital yuvası |
| Dünya Spaceport | 500 kredi | 4 sn | Lander hazırlama yeteneği |

Spaceport iki yuva kullanır.

Dünya Spaceport'u Moonstone istemez.

Oyuncuyu Ay'a gitmeden Moonstone gerektiren döngüye sokmaz.

### 20.4. Lander hazırlığı

| Alan | Değer |
| --- | --- |
| Gerekli araştırma | lunar_program |
| Gerekli yapı | Tamamlanmış Dünya Spaceport |
| Kredi | 3.000 |
| Ferrite | 40 |
| Fuel | 20 |
| Hazırlık | 30 ekonomi saniyesi |
| Uçuş | 30 ekonomi saniyesi |

Lander'ın Fuel'ı Ay'a ulaşmadan sağlanır.

Bu Fuel Ferrite ile üretilebilir veya erişim sonrası alınabilir.

### 20.5. Ay'a varış ve yer seçimi

Lander varışı Ay'a erişimi açar.

Oyuncu ilk City konumunu seçer ve adını verebilir.

İlk Ay City'sinin kabuk ve merkezi ücretsiz ilk kuruluş kuralını kullanır.

Kuruluş dört ekonomi saniyesi sürer.

Ücretsiz kabuk, bütün bina planının ücretsiz kurulması değildir.

Ay City'si tamamlanınca global kapasiteye, yüke ve gerçek taban gelirlere katılır.

### 20.6. İlk Ay Production

| Alan | Değer |
| --- | --- |
| Kredi | 300 |
| İsimli ham bedeli | 30 Ferrite |
| Süre | 4 ekonomi saniyesi |
| Moonstone bedeli | Yok |
| Yer | Geçerli yüzey kuruluşu |
| Sonuç | Moonstone keşfi ve yerel çıkarım olanağı |

Moonstone'a erişim keşif/üretici koşuluyla açılır.

Ayrı bir mineral yatağına basmak gerekmez.

Coğrafya verim sağlayabilir, fakat mineralin yerel bir yoğunluk noktası değildir.

### 20.7. 100 gerçek Moonstone sayacı

Sayaç Ay'daki gerçek Raw üretim olaylarından gelir.

Sadece Moonstone çıktısı sayılır.

Satın alınan Moonstone sayılmaz.

Başka gövdeden gelen kaynak sayılmaz.

Gövdeyi incelemek veya üretici kurmak tek başına 100 vermez.

Aynı üretim olayı kayıt yüklenince tekrar sayılmaz.

### 20.8. Sayaç harcama değildir

Oyuncu 100 Moonstone çıkardığında görev kalıcı tamamlanır.

Bu 100 stoğa eklenmiş gerçek üründür.

Oyuncu aynı Moonstone'ı sonra kuruluş veya roket için harcayabilir.

Görev tamamlandığında ayrıca 100 daha tüketilmez.

Stok daha sonra 0 olsa da tarihsel çıkarım başarısı kaybolmaz.

### 20.9. Ay Malzemeleri

Ay Malzemeleri 1.200 Science ister.

ANY araştırma ebeveyni lunar_program'dır.

Ay'da çıkarım yapabilen Production tamamlanmış olmalıdır.

Bu araştırma 100 yerel çıkarımın bitmesini beklemek zorunda değildir.

100 koşulu gelişmiş roket araştırmasında ayrıca aranır.

### 20.10. Ay Malzemeleri'nin açtıkları

| İçerik | Rol |
| --- | --- |
| Lunar Spaceport | Son roketin zorunlu fiziksel tesisi |
| Modüler Ay Habitatı | Sabit konut kapasitesi |
| Yerel Goods planı | Moonstone tabanlı işleme seçeneği |
| Ay yapı planları | Coğrafya ve özel modeller |

Bu haklar açılınca yeni binalar bedelsiz eklenmez.

Otomatik planlar için ücretli Güncelle teklifi hazırlanabilir.

### 20.11. Ay Capital Lv2

| Bedel | Süre | Neden |
| --- | --- | --- |
| 250 kredi, +500 yük | 10 sn | Lunar Spaceport için iki yuva |

Capital'ın yuvası ile City'nin çocuk district kapasitesi aynı şey değildir.

Ay City'sinin Lv2 olması Lunar Spaceport için ayrıca zorunlu değildir.

### 20.12. Lunar Spaceport

| Girdi | Miktar |
| --- | ---: |
| Kredi | 8.000 |
| Moonstone | 200 |
| Goods | 50 |
| Fuel | 30 |
| Rare | 10 |
| Capital yuvası | 2 |
| Kuruluş süresi | 30 ekonomi saniyesi |

Ay Malzemeleri araştırması gerekir.

Yapının gerçek inşaatı tamamlanmadan son roket hazırlanmaz.

### 20.13. Gelişmiş roket araştırması

| Şart | Tür |
| --- | --- |
| lunar_materials | Grafik ebeveyni |
| rare_processing | Birlikte gereken ürün/araştırma erişimi |
| 100 gerçek Ay Moonstone çıkarımı | Kalıcı fiziksel olay |
| 2.000 Science | Satın alma bedeli |

Araştırma satın alımı anlıktır.

Fiziksel roket hazırlığı ayrı süredir.

### 20.14. Gelişmiş roketin ödemesi

| Girdi | Miktar |
| --- | ---: |
| Kredi | 12.000 |
| Moonstone | 1.200 |
| Goods | 30 |
| Fuel | 120 |
| Rare | 40 |
| Hazırlık | 60 ekonomi saniyesi |

İlgili araştırma ve tamamlanmış Lunar Spaceport gerekir.

Ödeme başlatma anında bir kez alınır.

### 20.15. Hedefin geçerliliği

Hedef aynı Güneş Sistemi içindeki başka doğal gezegendir.

Yapay City, Orbital City, Space Station veya soyut merkez hedef değildir.

Ay başlangıç gövdesidir, son sefer hedefi değildir.

Ana dünyaya dönüş yeni ilerleme varışı olarak sayılmaz.

Hedef, sistemdeki farklı doğal gezegenlerden seçilir.

Kayalık veya gaz gövde olması yüzey yerleşimi şartı doğurmaz.

### 20.16. Gaz gezegenine varış

Gaz gezegeni doğal bir hedeftir.

Varış, o doğal gövdenin çevresine erişim olarak görselleştirilebilir.

Bu, yapay orbital merkez inşa etmek değildir.

Yüzey City'si kurulmaz.

Demo ekonomisi hedefte başlatılmaz.

### 20.17. Hedef ve süre

Hazırlık sürerken hedef değiştirilebilir.

Hedef değişimi hazırlık bedelini tekrar almaz.

Kalkışta hedef sabitlenir.

Uçuş 60 ekonomi saniyesidir.

Hedef mesafesi demo bedelini veya süreyi ayrıca değiştirmez.

Astronomik konum görüntüsü bir filo yakıt simülasyonu doğurmaz.

### 20.18. Varış olayı

Varış tek bir sefer kimliğiyle kaydedilir.

Sefer zaten arrived ise ikinci varış olayı üretilmez.

Başarılı ilk uygun varışta Medeniyet 0 tamamlanır.

civilization_type 1 olur.

demo_completed true olur.

playable_content_type 0 kalır.

### 20.19. Demo varışında yapılmayan işlemler

| İşlem | Durum |
| --- | --- |
| Hedefte City oluşturmak | Yapılmaz |
| Hedefte Orbital City oluşturmak | Yapılmaz |
| Hedefi aktif koloni listesine yazmak | Yapılmaz |
| Hedefin yeni mineralini keşfetmek | Yapılmaz |
| Tip 1 bina veya district kurmak | Kapalı |
| Tip 1 skill veya miras satın almak | Kapalı |
| Dünya/Ay üretimini durdurmak | Yapılmaz |
| Üst harita incelemesini açmak | Yapılır |

### 20.20. Son hazırlık maliyet tablosu

| Paket | Kredi | Moonstone | Goods | Fuel | Rare |
| --- | ---: | ---: | ---: | ---: | ---: |
| Lunar Spaceport + gelişmiş roket | 20.000 | 1.400 | 80 | 150 | 50 |
| Ay Capital Lv2 de dahil | 20.250 | 1.400 | 80 | 150 | 50 |
| İsteğe bağlı Regolit planı da dahil | 21.150 | 1.500 | 100 | 150 | 50 |

Bu paket Dünya'daki ilk gelişimi ve lander'ı içermez.

### 20.21. Doğrudan zorunlu adımların tamamı

| Adım | Kredi |
| --- | ---: |
| Dünya Capital Lv2 | 250 |
| Dünya Spaceport | 500 |
| Lander | 3.000 |
| İlk Ay City kabuğu | 0 |
| İlk Ay Production | 300 |
| Ay Capital Lv2 | 250 |
| Lunar Spaceport | 8.000 |
| Gelişmiş roket | 12.000 |
| Örnek standart Warehouse | 300 |
| Toplam | 24.600 |

Warehouse kimliği özel bir görev kapısı değildir.

Aynı gerekli kapasiteyi başka uygun model veya destek sağlıyorsa o seçenek kullanılabilir.

### 20.22. Depo gereksinimi

Roketin tek ödemesi 1.200 Moonstone ister.

Ham türü başına taban kapasite 500'dür.

Bu bedel taban depoya sığmaz.

Standart Warehouse açılmış ham türü başına 1.000 ek kapasite verirse toplam 1.500 olur.

Warehouse Dünya'da veya Ay'da olabilir.

Depo kapasitesi global stok sözleşmesini kullanır.

### 20.23. Rezerv örneği

Oyuncu 1.200 Moonstone'ı son roket için koruyabilir.

Trade otomasyonu bu rezervi satmaz.

Lunar Spaceport için 200 Moonstone ayrıca gerekir.

İki ödeme aynı 200'ü iki kez kullanamaz.

Roket hazırlığına geçildiğinde ayrılan 1.200 gerçek ödemeye dönüşür.

### 20.24. İşleme için harcanan ham ayrıca sayılır

Doğrudan 1.400 Moonstone bedeli işleme girdisini içermez.

80 Goods +170 Fuel +50 Rare tamamen R1 hamla üretilirse 1.440 Ferrite ister.

Lander ve Ay Production için ayrıca 70 doğrudan Ferrite gerekir.

İsteğe bağlı Regolit paketindeki 100 Goods +150 Fuel +50 Rare ise 1.400 Ferrite işleme girdisi ister.

Bu son işleme paketi R2 Moonstone ile yalın olarak 800 Moonstone ister.

Doğrudan 1.500 ile birlikte 2.300 Moonstone eşdeğeri oluşur.

Bu son örnek lander'ın ilk 20 Fuel'ını Moonstone ile yapılmış varsaymaz.

### 20.25. İsteğe bağlı Ay ekonomisi

| İçerik | Neden kurulabilir | Neden zorunlu değil |
| --- | --- | --- |
| Modüler Ay Habitatı | Daha fazla ortak kapasite | Kapasite Dünya'dan da gelebilir |
| Ay Numune Lab | Yoğun Science | Başka Science veya alım yolu var |
| Ay İkmal Pazarı | Goods/Fuel tüketen kredi | Başka gelir yolu var |
| Regolit Goods planı | Yerel işleme ve yoğunluk | Temel fabrika veya alım yolu var |
| Ek çıkarım modelleri | Moonstone hızını artırmak | Daha küçük üretim + trade de mümkün |

### 20.26. Kayıt ve yarım kalan sefer

Hazırlık ilerlemesi kayda yazılır.

Ödenmiş girdiler ve hedef kimliği kayda yazılır.

Kayıt yüklenince hazırlık baştan para istemez.

Uçuş kalan ekonomi süresiyle devam eder.

Varış kaydı zaten varsa görev tekrar tamamlanmaz.

Kamera veya sahne değişimi seferi sıfırlamaz.

### 20.27. Sefer sunumu

Hazırlık ve uçuş çubukları gerçek ekonomi süresini gösterir.

Tahmini varış online ve offline hız farkını saklamaz.

Oyuncu sefer ekranını kapatıp ekonomiyi yönetebilir.

Görsel roketin havalanması ayrı bir kaynak ödemesi değildir.

Bir animasyon callback'i tekrar çalışsa da sefer olayı tekil kimlikle korunur.

### 20.28. Demo sonrası yönetim

Dünya/Ay'da izinli Tip 0 alımları devam eder.

Eksik Tip 0 strateji düğümleri normal kuralla satın alınabilir.

Tip 1 canlı aile etiketleri mevcut City'lere atanabilir.

Bu etiket eski ekrana Tip 1 kuruluş fiyatı veya yeni ekonomi yetkisi getirmez.

Mirasın görsel özeti, alınmamış alt Tip 0 araştırmalarını incelemeyi engellemez.

### 20.29. Ay ve sefer uygulama sorumlulukları

| Kaynak | Sorumluluk |
| --- | --- |
| scripts/game/GameState.gd | Araştırma/ödeme/varış durumları ve izinler |
| scripts/game/PlanetProgress.gd | Ay yerleşimi ve fiziksel yapı ilerlemesi |
| scripts/game/ProductionManager.gd | Gerçek Moonstone üretim olayları |
| scripts/solar/SolarView.gd | Doğal gezegen hedefi ve sınırlı sistem görünümü |
| scripts/planetary/PlanetaryView.gd | İlk City, Production, Capital ve Spaceport işlemleri |
| scripts/game/ShipManager.gd | Sade sefer olayına gereken ortak zaman/veri parçaları |
| scripts/data/ShipData.gd | Kalıcı sefer kimliği ve durum verisi |

<a id="bolum-21"></a>

## 21. Sürekli hedefler, başarımlar, izinler ve kayıt sözleşmesi

### 21.1. Ana görev paneli

Panel oyunun sürekli erişilebilir ilerleme rehberidir.

Tam ekran bir zorunlu konuşma penceresi değildir.

Daraltılabilir.

Kapatmak görev durumunu silmez.

Ana hedef medeniyet geçişini gösterir.

Ara hedefler somut araştırma, gerçek üretim, fiziksel yapı ve sefer olaylarına bağlanır.

### 21.2. Ana ve ara görevler

| Kimlik | Görünür hedef | Gerçek tamamlanma |
| --- | --- | --- |
| civ0_to_civ1 | Tip 1'e ulaş | Ay roketinin geçerli başka doğal gezegene varması |
| establish_economy | Üretim temelini oluştur | Tamamlanmış normal district ve çalışabilir temel ekonomi |
| first_ferrite | İlk minerali çıkar | Ana dünyada gerçek Ferrite çıkarımı |
| choose_strategy | Bir strateji kur | Science, nüfus, ticaret veya sanayi gelir yolundan biri |
| access_goods | Goods'a eriş | Temel işleme hakkı ve kullanılabilir Goods temini |
| access_fuel | Fuel'a eriş | fuel_processing ve gerekli ürün temini |
| access_rare | Rare'a eriş | rare_processing ve gerekli ürün temini |
| launch_lander | Ay seferini hazırla | Spaceport ve ödenmiş lander hazırlığı |
| reach_moon | Ay'a ulaş | Lander'ın gerçek Ay varışı |
| lunar_settlement | Ay'da yerleş | Tamamlanmış ilk Ay City |
| lunar_extraction | Ay üretimine başla | Geçerli çıkarım yapan yerel Production |
| lunar_100 | 100 Moonstone çıkar | Gerçek yerel çıkarım toplamı en az 100 |
| lunar_spaceport | Lunar Spaceport'u tamamla | Fiziksel yapı inşaatı tamamlanmış |
| advanced_rocket | Gelişmiş roketi hazırla | Araştırma, gerçek ödeme ve hazırlık |
| choose_target | Hedefini seç | Aynı sistemde geçerli farklı doğal gezegen |
| final_arrival | Seferi tamamla | Tek başarılı son varış |
| inspect_universe | Daha büyük ölçeği incele | Demo sonrası önizlemeye giriş |

### 21.3. Liste bir sert sıra değildir

Görevlerin panelde sırayla görünmesi hepsinin birbirini kilitlediği anlamına gelmez.

Oyuncu gelecekteki bir ara hedefi erken tamamlarsa işaretlenir.

Rare tamamlanmadan Ay'a gidilebilir.

Rare son roketten önce gerekir.

Ay Malzemeleri yerel 100'den önce alınabilir.

Görev sistemi araştırma grafiğine ikinci gizli ön koşul listesi eklemez.

### 21.4. Alternatif temin kabulü

| Hedef | Kabul edilen |
| --- | --- |
| Fuel edin | Geçerli üretim veya erişim sonrası alım |
| Rare edin | Geçerli üretim veya erişim sonrası alım |
| Goods edin | Üretim veya alım |
| Science edin | Üretim, nüfus geliri veya alım |
| 100 yerel Moonstone çıkar | Yalnız gerçek Ay çıkarımı |
| Spaceport'u tamamla | Yalnız gerçek tamamlanmış yapı |
| Yeni gezegene var | Yalnız gerçek sefer varışı |

Görev açıklaması bu farkı açık yazar.

### 21.5. Üretim temelinin koşulu

İlk ekonomik hedef için oyuncunun bütün aileleri kurması gerekmez.

Geçerli bir normal district ve en az bir çalışabilir ekonomik yol yeterlidir.

Küçük geçici kapasite açığı kalıcı başarımı geri almaz.

Görev, oyuncuya mevcut enerji ve nüfus durumunu ayrıca gösterebilir.

Tarihsel tamamlanma ile şu anki ekonomi sağlığı aynı alan değildir.

### 21.6. Bir strateji kur hedefi

| Strateji | Somut kanıt |
| --- | --- |
| Bilim | Etkin Science üreticisi veya ilgili güçlendirilmiş Science yolu |
| Nüfus | Gelir skill'i açık ve gerçek boş kapasiteden pozitif akış |
| Ticaret | Açılmış trade ile gerçek geçerli alış/satış işlemi |
| Sanayi | Gerçek çıkarım ve en az bir çalışan işleme yolu |

Bunlardan herhangi biri yeterlidir.

Dördünü birden tamamlamak ana ilerleme koşulu değildir.

### 21.7. Ekonomik görev ödülleri

Bu GDD'deki ana ve ara görevler ekonomik ödül vermez.

Kredi ödülü 0'dır.

Science ödülü 0'dır.

Mineral ödülü 0'dır.

İlk oyun bütçesi görev panelinin ödülü değildir.

Bir adımın bedeline eksik parayı otomatik tamamlama yoktur.

Paneli atlamak Ferrite vermez.

### 21.8. Tutorial kapsamı

Yeni kurallar için açıklamalar sürekli görev panelinde verilir.

Sabit tutorial seed'i bu oyunun kuruluş şartı değildir.

Rastgele volkanik/gaz başlangıç ve gövdeye özel ayrı ağaç bu temel akışa bağlı değildir.

Bu genişlemeler için veri yapısı engel oluşturmaz, fakat oynanabilir içerik burada var sayılmaz.

Narrative metinleri görevleri ekonomik ödülle gizlice sübvanse etmez.

### 21.9. Gelecek anlatı alanları

| Alan | İşlev |
| --- | --- |
| narrative_hook_id | Göreve bağlanabilecek anlatı kimliği |
| trigger_event | Hangi gerçek olayda açılacağı |
| condition | Gereken durum |
| seen | Oyuncunun görüp görmediği |
| optional_choice | Eklenirse seçilen cevap |
| effect_id | Açıkça tanımlanmış tek seferlik etki |
| locale_key | Yerelleştirilmiş metin |

Bu alanların bulunması hikâyenin yazılmış olduğu anlamına gelmez.

Anlatı seçimi yokken boş alan yeni bir zorunlu pencere üretmez.

### 21.10. Görev durumları

| Durum | Anlam |
| --- | --- |
| hidden | Henüz açıklanmayacak hedef |
| visible | İncelenebilir hedef |
| available | Koşullarından biri üzerinde çalışılabilir |
| in_progress | Gerçek ilerleme başladı |
| waiting | Girdi, araştırma veya fiziksel şart bekliyor |
| completed | Tek seferlik hedef tamamlandı |
| dismissed | Oyuncu görsel bildirimi kapattı |

completed ile dismissed ayrı tutulur.

Bildirim kapatmak tamamlanmayı geri almaz.

### 21.11. Görev satırının gösterimi

Her satır kısa hedef adını gösterir.

Alt satır gerçek eksik koşulu gösterir.

Sayı gerektiren hedef ilerleme payını gösterir.

Örneğin yerel çıkarım 65/100 Moonstone yazabilir.

Araştırma satırı mevcut/istenen Science'ı gösterir.

Bir malzemeyi satın alabilmek ile fiziksel çıkarım farkı görev açıklamasında görünürdür.

### 21.12. Bekleme nedeni

| Kod | Oyuncuya açıklama |
| --- | --- |
| research_locked | Önce ilgili araştırma gerekli |
| not_discovered | Kaynak henüz fiziksel olarak erişilmiş değil |
| missing_input | Seçili girdi yetersiz |
| insufficient_credits | Kredi yetersiz |
| insufficient_science | Science yetersiz |
| no_capacity | Gerekli yuva veya yer yok |
| construction_pending | Fiziksel yapı tamamlanıyor |
| local_extraction_pending | Gerçek yerel çıkarım bekleniyor |
| offline_quota | Offline yeni kazanç hakkı doldu |
| preview_only | Bu içerik yalnız incelenebilir |
| user_paused | Oyuncu tarafından durdurulmuş |

Kilitli kaynağın adı not_discovered hatasıyla sızdırılmaz.

### 21.13. Tek seferlik olay kimliği

Her fiziksel üretim turu ve sefer tekil event_id taşır.

Görev bu kimliği bir kez işler.

Aynı olay görsel callback ve kaynak callback'inden iki kere gelirse ikinci kayıt yok sayılır.

Kayıt yükleme tamamlanmış olayı yeniden ödemez.

Aynı bina yıkılıp tekrar kurulursa tarihsel “ilk bina” başarımı tekrar verilmez.

### 21.14. Gerçek çıkarım yeteneği

Keşif ve yerel çıkarım, yalnız host City ailesinin adına bakmaz.

Uygun ölçekte gerçek çıkarım yeteneği taşıyan bir nesne gerekir.

Gövdenin mineral kümesi o kaynağı içermelidir.

Medeniyet erişimi açık olmalıdır.

Bu üç şart birlikte değerlendirilir.

### 21.15. Çapraz rol keşif örneği

Tip 1'de Science City içindeki gerçek Production rolü districti ham çıkarabiliyorsa keşif açabilir.

Host'un Production City olması zorunlu değildir.

Districtin görünür adında Production geçmesi tek başına yeterli değildir.

Gerçek output/capability verisi denetlenir.

### 21.16. Host yan çıktısının sınırı

Host desteğiyle gelen küçük Raw yan çıktısı ilk keşif olayı değildir.

Bu destek gerçek maden çıkarımı sayılmaz.

100 yerel Moonstone sayacını ilerletmez.

Ham satışından gelen kredi de çıkarım değildir.

Sayaca kaynak kökeni extraction olan gerçek ürün olayı girer.

### 21.17. Çıkarım olayının alanları

| Alan | Anlam |
| --- | --- |
| event_id | Tek tur/çıktı kimliği |
| source_entity_id | Gerçek üretici |
| source_body_id | Çıkarım yapılan doğal gövde |
| resource_id | Gerçek ham kaynak |
| amount | Gerçek üretilmiş miktar |
| origin_kind | extraction, processing, host_support, trade gibi köken |
| economy_time | Olayın ekonomik zamanı |
| transaction_id | Stok hareketiyle bağı |

### 21.18. Başarımların ekonomik rolü

Başarımlar kalıcı ilerleme işaretidir.

Kredi, Science veya mineral ödülü vermez.

Başarım bildirimi üretim akışını kilitlemez.

Steam kimliği bulunması harici platform entegrasyonunun çalıştığı iddiası değildir.

Gerekli platform bağlantısı ayrı uygulama işidir.

### 21.19. Başarım kimliği

Başarım tipi kararsız enum sıra numarasına bağlı bırakılmaz.

Kalıcı bir canonical başarı kimliği kullanılır.

Kaynakta aynı hedefi temsil eden adlar bu kimliğe bağlanabilir.

Aynı görünen hedef iki ayrı ekonomik etki üretmez.

### 21.20. Temel başarım olayları

| Olay | Kanıt |
| --- | --- |
| İlk district | Gerçek normal district tamamlanmış |
| İlk bina | Gerçek bina adedi tamamlanmış |
| İlk Ay varışı | Lander varışı |
| İlk Ay City | Ay'da City tamamlanması |
| Yerel Ay üretimi | Gerçek Moonstone çıkarımı |
| İlk başka gezegene varış | Son roket varışı |
| Medeniyet 0 tamamlandı | Tek medeniyet geçişi olayı |
| Üst evren incelemesi | Demo sonrası izinli önizlemeye giriş |
| Belirli araştırma | Canonical hakkın ilk bireysel kazanımı |

Bu olaylar birbirinin yerine kullanılmaz.

### 21.21. Sayım türlerini ayırmak

| Sayaç | Tanım |
| --- | --- |
| active_building_count | Şu an sahip olunan tamamlanmış bina adedi |
| built_lifetime_count | Tarih boyunca tamamlanmış gerçek adet |
| active_district_count | Gerçek tamamlanmış districtler |
| active_city_count | Gerçek sahip olunan City'ler |
| colonized_body_count | İzinli gerçek yerleşimi olan doğal gövdeler |
| credits_balance | Şu anki kredi |
| science_balance | Şu anki Science |
| raw_balance | Şu anki erişilmiş ham stokların toplamı |
| extracted_lifetime | Gerçek çıkarım olaylarının tarihsel toplamı |

Bir başarım hangi sayacı kullandığını veri alanıyla açık belirtir.

### 21.22. Bina sayımının doğru karşılığı

10 Lab aynı kartta gösterilse de 10 bina sayılır.

Aynı modelin üç girdi satırı üç ayrı bina demek değildir.

Girdi satırlarında 2, 3 ve 5 adet varsa toplam 10'dur.

İnşaatta olan adet tamamlanmış bina sayacına girmez.

Sadece card veya Dictionary kayıt sayısını toplamak yeterli değildir.

### 21.23. Yerleşim ve gövde sayımı

Önizleme objeleri sahip olunan yerleşim sayılmaz.

Son roketin varması hedefi kolonileşmiş yapmaz.

Hedefte City kurulmadığı için kolonileşmiş gövde sayısı artmaz.

Dünya ve Ay gerçek yerleşimler olarak sayılır.

Orbital merkez ayrı doğal gezegen sayılmaz.

### 21.24. Kredi eşik ailesi

Kredi stoku eşikleri 10.000, 100.000, 1.000.000, 10.000.000 ve 100.000.000 ile başlar.

Devamı 1.000.000.000, 10.000.000.000, 100.000.000.000 ve 1.000.000.000.000'dur.

İleri eşikler 10^15, 10^18 ve 10^21'dir.

Bu aile credits_balance ölçer.

Toplam kazanılmış krediyle aynı sayaç değildir.

### 21.25. Science eşik ailesi

Science stoku eşikleri 5.000, 50.000, 500.000, 5.000.000 ve 50.000.000'dur.

Devamı 500.000.000, 5.000.000.000, 50.000.000.000 ve 500.000.000.000'dur.

İleri eşikler 5×10^12, 5×10^15 ve 5×10^18'dir.

Bu aile science_balance ölçer.

Araştırmaya harcanan Science aynı anda cüzdan stoku sayılmaz.

### 21.26. Raw eşik ailesi

Raw stok eşikleri 10.000, 50.000, 250.000, 1.000.000 ve 5.000.000'dur.

Devamı 25.000.000, 100.000.000, 500.000.000, 2.500.000.000 ve 10.000.000.000'dur.

İleri eşikler 50.000.000.000, 250.000.000.000, 10^12, 10^15 ve 10^18'dir.

Bu aile gerçek mevcut ham stoğu ölçer.

Tarihsel Ay çıkarımı ayrı sayaçtır.

### 21.27. Adet eşik aileleri

| Aile | Eşikler |
| --- | --- |
| Bina | 10, 50, 250, 1.000, 5.000, 10.000, 25.000, 50.000, 100.000, 250.000, 500.000, 1.000.000 |
| District | 5, 25, 100, 250, 500, 1.000, 2.500, 5.000, 10.000, 25.000 |
| Gerçek kolonileşmiş gövde | 2, 5, 10, 25, 50, 100, 250, 500, 1.000, 5.000 |
| Gezegen seviyesi | 2, 3, 4, 5, 6, 7, 8, 9, 10 |

Yüksek eşikler demo hedefi değildir.

İleri başarı açıklaması kilitli mineral adlarını görünür yapmaz.

### 21.28. Araştırma başarımları

Araştırma başarımı hedef canonical_id ile eşleşir.

Model adı ile skill kimliği aynı varsayılmaz.

Bilim Verimi'ne bağlanan iki kaynak kimliği iki farklı etkin seviye üretmez.

Miras tamamlaması ilerleme bilgisini güncelleyebilir.

Bir araştırmanın “ilk bireysel alım” başarımı ile “bu hakka sahip olma” başarımı veri alanında ayrıdır.

### 21.29. Başarıların bir kez kazanılması

Eşik sağlandığında canonical başarı kimliği kayıt edilir.

Kaydedilmiş başarı tekrar verilmez.

Daha sonra stok eşiğin altına inse bile kazanılmış başarı kaybolmaz.

Paneli açmak yeni kazanım değildir.

Aynı olay tekrar gönderildiğinde ikinci bildirim kuyruğa girmez.

### 21.30. Başarım kaynaklarının sorumluluğu

| Kaynak | Hedef görev |
| --- | --- |
| scripts/game/AchievementManager.gd | Olay bağlantıları ve tek seferlik kazanım |
| resources/achievements/AchievementDef.gd | Kalıcı kimlik, sayaç türü ve koşul |
| resources/achievements/*.tres | Başlık, açıklama, eşik ve hedef kimlik |
| scripts/game/ProductionManager.gd | Gerçek tamamlanan adet ve üretim olayları |
| scripts/game/SkillTree.gd | Canonical araştırma kazanımı |
| scripts/game/GameState.gd | Kaydedilen başarılar ve sefer olayları |

### 21.31. İçerik izinlerinin ayrımı

| Alan | Sorumluluk |
| --- | --- |
| civilization_type | Tarihsel medeniyet ilerlemesi |
| playable_content_type | Gerçek kurulabilir ve satın alınabilir içerik |
| demo_completed | Demo varışının gerçekleşmesi |
| preview_permissions | İncelenebilir ekranlar |
| discovered_resources | Ekonomik erişimi açılmış kaynaklar |
| research_entitlements | Gerçek kazanılmış haklar |
| owned_entities | Gerçek ekonomik nesneler |

Tek civilization_type alanı bütün yetkileri açmaz.

### 21.32. Demo izin matrisi

| İşlem | Medeniyet 0 | Son varış sonrası demo |
| --- | --- | --- |
| Dünya/Ay Tip 0 ekonomisi | Açık | Açık |
| İzinli Tip 0 araştırması | Açık | Açık |
| Tip 1 araştırması | Kapalı | Yalnız önizleme |
| Tip 0 Mirası | Kapalı | Yalnız önizleme |
| Yeni hedef gezegende City | Kapalı | Kapalı |
| Yeni hedefte otomatik merkez | Kapalı | Kapalı |
| Tam üst evren incelemesi | Kapalı | Açık |
| Sınırlı Ay/hedef sistem görünümü | Görev gereği | Açık |
| Kilitli ileri mineral adı | Gizli | Gizli |
| İzinli Dünya/Ay düzenlemesi | Açık | Açık |

### 21.33. Görsel ile gerçek ekonomi

Büyük evren önizlemesi ekonomik koloni değildir.

Önizleme gezegenini seçmek üretici kurmaz.

Üst ölçeğe yakınlaşmak veya uzaklaşmak kaynak vermez.

Kamera başka gövdedeyken Dünya/Ay ekonomisi ortak saatte sürer.

Oynanabilir olmayan nesne için komut servisi de işlemi reddeder.

Yalnız düğmenin gizli olması yeterli değildir.

### 21.34. Doğal hedef ile ekonomik kayıt

Bir gövdenin PlanetData önizlemesi olabilir.

Bu, onun aktif PlanetProgress ekonomisi olduğu anlamına gelmez.

Salt okunur getirme işlemi kendiliğinden koloni başlatmaz.

Aktif ekonomi listesi gerçek sahiplik ve kuruluş durumuna göre belirlenir.

### 21.35. Yeni oyun ile kayıt yükleme

Yeni oyun kurucusu başlangıç 3.000 kredi ve 450 Science'ı bir kez verir.

Kayıt yükleyicisi kayıtlı değerleri korur.

Yükleme sonrasında başlangıç Inspector değerleri cüzdanın üstüne yazılmaz.

Başlangıç kökleri, kaydedilmiş gerçek erişimlerle çakışmadan doğrulanır.

Yüklü oyuna yeni oyun bütçesi eklenmez.

### 21.36. Yeni kayıt şeması

Kayıt, oyun veri sözleşmesinin sürümünü taşır.

Uyumsuz şema sessizce aynı sayılarla açılmaz.

Bu GDD kapsamı karmaşık bir kayıt taşıma katmanını zorunlu tutmaz.

Mevcut kayıt dosyasının silinmesi otomatik bir tasarım adımı değildir.

Gerçek uygulamada yeni oyun ve uyumsuz kayıt davranışı açık arayüzle ayrılır.

### 21.37. İlerleme kayıt alanları

| Alan | Saklanan değer |
| --- | --- |
| civilization_type | Ulaşılmış tip |
| playable_content_type | Oynanabilir en yüksek içerik tipi |
| demo_completed | Son varış durumu |
| civilization_events | Tek seferlik geçiş kimlikleri |
| home_body_id | Ana dünya |
| moon_body_id | Ay |
| selected_target_body_id | Son sefer hedefi |
| flight_states | Hazırlık/uçuş/varış |
| preview_unlocks | İzinli inceleme ölçekleri |
| actual_local_extraction | Gövde ve mineral bazlı gerçek toplam |

### 21.38. Araştırma kayıt alanları

| Alan | Saklanan değer |
| --- | --- |
| individual_levels | Canonical kimlik başına gerçek alım |
| inherited_levels | Mirasın verdiği seviye |
| purchased_node_civilization | Çapraz dal sayacı kapsamı |
| inherited_bundles | Alınmış miras düğümleri |
| researched_permissions | Model ve işlem erişimleri |
| research_transactions | Tekil ödeme kayıtları |

Etkin seviyeler bu iki hak kaynağından yeniden hesaplanabilir.

Aynı türe ait alias hakları ayrı bonus olarak yüklenmez.

### 21.39. Ekonomi ve trade kayıt alanları

| Alan | Saklanan değer |
| --- | --- |
| credits | Global kredi |
| science | Global Science |
| global_resources | Ürün bazlı stok |
| discovered_resources | Kalıcı erişim |
| reserved_resources | Devam eden geçerli rezervler |
| trade_orders | Oyuncunun otomasyon tercihleri |
| trade_transactions | Uygulanmış alış/satış kimlikleri |
| paid_cycle_inputs | Başlamış tur giderleri |
| promised_cycle_outputs | Başlamış turun vaat edilmiş çıktısı |
| pending_material_output | En fazla tanımlı tek tur beklemesi |
| pause_states | Kullanıcı ve otomatik bekleme ayrımı |

### 21.40. Görev kayıt alanları

| Alan | Saklanan değer |
| --- | --- |
| completed_objective_ids | Kalıcı tamamlanmış hedefler |
| processed_event_ids | Tekrarı engellenen olaylar |
| objective_progress | Sayısal ara ilerleme |
| panel_collapsed | Oyuncunun görünüm tercihi |
| seen_narrative_ids | Görülmüş gelecekteki anlatı öğeleri |
| unlocked_achievement_ids | Kalıcı başarımlar |

### 21.41. Zaman kayıt alanları

İşlenmiş ekonomi zamanı kaydedilir.

Döngü ilerlemesi ve başlangıç tarifleri kaydedilir.

Son güvenli takvim zaman damgası kaydedilir.

Kullanılabilir iki offline bütçe kesirli olarak kaydedilir.

Geçerli kapalı dönemin sabitlenen bütçe ve izinleri kaydedilir.

Görsel gün/gece açısı ayrı sunum alanıdır.

Görsel açı ekonomik offline süreyi ikinci kez üretmez.

### 21.42. Kaydın atomik niteliği

Kaynak gideri ve kazanılan hak aynı işlem olarak kaydedilir.

Örneğin Science düşmüş fakat skill hakkı kaybolmuş yarım kayıt oluşmaz.

Roket bedeli düşmüş fakat hazırlık kimliği yok olmuş yarım kayıt oluşmaz.

Varış işlendiğinde demo ve medeniyet bayrakları birlikte saklanır.

Offline aralık ve kaynak sonucu birlikte saklanır.

### 21.43. Ne zaman kayıt alınır?

| Olay | Kayıt |
| --- | --- |
| Araştırma satın alma | İşlem tamamlanınca |
| Büyük kuruluş veya rezerv | Geçerli işlem tamamlanınca |
| Sefer başlatma | Ödeme ve sefer kimliğiyle |
| Varış | Tek olayla |
| Medeniyet geçişi | İzin ve durum alanlarıyla |
| Ayar değişimi | Tercih kesinleşince |
| Offline hesap | Aralık ve ekonomi birlikte |
| Normal oyun | 60 saniyelik periyodik kayıt |
| Uygulamadan çıkış | Son tamamlanmış tutarlı durum |

### 21.44. Geçici nesneleri kayda ekonomik sahiplik diye yazmama

Önizleme gövdeleri sahip olunan yerleşim listesine girmez.

Güncelle teklifi gerçek bina adedi değildir.

Üretim önizlemesi gerçek gelir değildir.

Seçili ama başlatılmamış roket hedefi varış kaydı değildir.

Bir araştırmanın tooltip'ini açmak satın alma kaydı değildir.

### 21.45. Önemli durum örnekleri

| Durum | Beklenen sonuç |
| --- | --- |
| Oyuncu 99 Moonstone çıkarıp 500 alır | Yerel görev 99/100 kalır |
| Aynı çıkarım olayı iki kez yüklenir | Sayaç bir kez artar |
| Science City içindeki gerçek Mine yeni mineral çıkarır | Medeniyet/gövde şartı açıksa keşif geçerli |
| Host yan Raw desteği oluşur | İlk keşif ve yerel çıkarım sayılmaz |
| Demo sonu hedef gezegen seçilir | Ekonomi başlatılmaz |
| Miras düğümü incelenir | Science ve grant değişmez |
| Tip 0 araştırması demo sonrası alınır | Geçerli Tip 0 hakları işler |
| Son yerleşim yıkılır | Başlangıç 3.000/450 tekrar verilmez |
| Görev paneli tekrar açılır | Ekonomik ödül oluşmaz |
| Bir model üç girdi grubunda toplam 12 adet | Bina sayacı 12 sayar |

### 21.46. Kaynak entegrasyon haritası

| Gerçek kaynak | Bu GDD'deki hedef sorumluluğu |
| --- | --- |
| scripts/game/GameState.gd | Global cüzdan, kaynak akışı, medeniyet, sefer, sahiplik ve kayıt |
| scripts/game/SkillTree.gd | Canonical grafik, fiyat, grant, ANY/ALL, miras |
| scripts/ui/SkillTreeView.gd | Strateji ağacı, önizleme ve gerçek satın alma ayrımı |
| scripts/game/ProductionManager.gd | Tek 20 saniyelik döngü, gerçek çıkarım ve olay zamanlı ilerleme |
| scripts/game/PlanetProgress.gd | Gerçek kuruluş ve seviye durumları |
| scripts/game/BuildingDef.gd | Tarif, model kapısı ve gerçek tüketim |
| scripts/game/DistrictDef.gd | Rol, City host'u ve district erişimi |
| scripts/game/Economy.gd | Ortak kaynak, kapasite ve fiyat hesapları |
| scripts/game/AchievementManager.gd | Güvenilir olay ve adet sayımı |
| resources/achievements/AchievementDef.gd | Canonical başarı tanımı |
| resources/achievements/*.tres | Mevcut eşik/ad verisinin hedef sayaçlara bağlanması |
| scripts/system/TutorialManager.gd | Sürekli görev paneline dönüşüm, ekonomik yardım yollarının kapanması |
| scripts/system/SettingsManager.gd | Offline ve genel tercihlerin kalıcılığı |
| scripts/system/HUDManager.gd | Gerçek kaynak, oran, rezerv ve bekleme sunumu |
| scripts/solar/SolarView.gd | Aynı sistem doğal hedefi ve görev görünümü |
| scripts/planetary/PlanetaryView.gd | Gerçek yerleşim işlemleri ve ortak kartlar |
| scripts/game/ShipManager.gd | Demo seferine gerekli ortak zaman ve kimlik |
| scripts/data/ShipData.gd | Sefer durumunun saklanması |

### 21.47. Kaynaktaki ilgili çağrı aileleri

| Çağrı / alan | Hedef davranış |
| --- | --- |
| add_resource / consume_resource | Kapasite, taşma, rezerv, köken ve offline kota ortak kapısı |
| earn_credits / add_science | Online veya offline pozitif akışın doğru sınıflandırılması |
| save / load_save | Yeni şema, başlangıç üstüne yazmama, idempotent işlem |
| purchase_skill / can_purchase | Gerçek Science ödemesi ve izin doğrulaması |
| gate_block | ANY grafikle ALL fiziksel koşulları ayırma |
| get_next_cost | Aynı medeniyet dal sayacı ve hedef seviye |
| _tick_all / _tick_district_base | Tek ekonomik zaman ve kaynak üretimi |
| _pay_inputs / _on_tick_complete | Tur başı ödeme ve tur sonu tek çıktı |
| _produce_raw | Gerçek kökenli çıkarım, mineral seçimi ve görev olayı |
| output_per_cycle / resource_rates | Kart ve simülasyonun aynı hesapları kullanması |
| moon_colonize_block / start_moon_colonization | Sade lander ön koşulu ve yeni açık bedel |
| complete_act1 / act1_completed | Son doğal gezegen varışına bağlı medeniyet/demo olayı |
| notify_trigger | Canonical olay, gerçek adet ve doğru sayaç |
| _grant_step_needs / _give_skip_minerals | Ekonomik yardım üretmez |
| _advance_action / _advance_quest_sub | Tek seferlik hedef; ödül 0 |

### 21.48. Uygulama sırasındaki tamamlanma ölçütü

Bir fonksiyonun bulunması sistemin tamamlandığı anlamına gelmez.

Arayüz fiyatı ile gerçek ödeme aynı olmalıdır.

Offline ve online üretim aynı tarifi kullanmalıdır.

Preview ve satın alma aynı erişim servisini farklı izinlerle çağırmalıdır.

Kaynak kaydı ile görev olayı aynı gerçek üretim miktarından gelmelidir.

Miras ve bireysel hak aynı canonical seviyede birleşmelidir.

Hedef GDD davranışı, oyun oynanmış veya süre dengesi doğrulanmış gibi sunulmaz.


### 21.49. Panel hedefi ile sefer görevini ayırmak

Sürekli görev panelinin objective_id kaydı oyuncunun kalıcı ilerleme hedefidir.

Seferin task_type kaydı belirli bir fiziksel işin durumudur.

Bu iki kimlik aynı veri nesnesi yapılmaz.

Bir roket varışı seferi tamamlar ve ilgili kalıcı hedefe olay gönderir.

Kalıcı hedefin tamamlanması yeni roket görevi yaratmaz.

scripts/mission/MissionTaskDef.gd içindeki durum ve parametre modeli sade seferin gerekli ortak alanlarına yardımcı olabilir.

scripts/mission/MissionTaskRegistry.gd içindeki görev filtrelemesi, sürekli panelin ekonomik ödül veya medeniyet yetki servisi değildir.

Kayıttaki sefer görevleri okunurken varışın tamamlandığı anlaşılabilir.

Bu okuma, genel kargo veya filo görevlerini demo ekonomisinin zorunlu kapısı yapmaz.

Sürekli hedef, sefer, kaynak hareketi ve başarım farklı sorumluluklardır; ortak tekil olay kimliğiyle bağlanırlar.

<a id="bolum-22"></a>

## 22. Ekranlar, bilgi düzeni ve kullanıcı deneyimi

### Ana menü

Ana menü Yeni Oyun, Devam Et, Ayarlar ve Çıkış seçeneklerini sunar. Devam Et yalnız uyumlu kayıt varsa kullanılabilir. Yeni Oyun mevcut bir kaydın üzerine yazacaksa etkilenecek kayıt açıkça belirtilir. Sıradan içerik güncellemesi mevcut dosyaları sessizce silmez.

Menüde görünmeyen bir aktif ekonomi arka planda tam hızla çalışmaz. Devam Et sırasında kayıt ve kapalı süre bir kez işlenir; oyun durumu tamamlanmadan ekonomik ekran etkinleştirilmez. Ayarlar kayıtlı dünyanın gelirini veya araştırmalarını sıfırlamaz.

### Ana oyun ekranının bölümleri

| Bölge | İçerik | Davranış |
| --- | --- | --- |
| Üst kaynak barı | Kredi, Science, global nüfus, global enerji ve açılmış stoklar. | Seçilen gezegenden bağımsız imparatorluk toplamları. |
| Orta harita | Mevcut ölçeğin gerçek yerleşimleri ve görünen coğrafya. | Seçim, yakınlaşma, uzaklaşma, kurulum önizlemesi. |
| Sol panel | Seçili nesnenin alt ekonomik birimleri. | Adet/girdi, kuruluş, Güncelle, ayrıntı ve düzenleme. |
| Görev paneli | Medeniyet ana hedefi ve ara adımlar. | Sürekli erişilebilir; daraltılabilir; ekonomi durmaz. |
| Alt rol butonları | Energy, Population, Production, Science, Commercial. | Kuruluş uygunluğu ve açıklanabilir yer önerileri. |
| Ölçek yolu | İncelenen bölgenin ebeveynleri. | Gezegen, sistem ve üst haritalarda hangi nesneye bakıldığını gösterir. |
| Durum bildirimleri | Tamamlanan inşaat, araştırma, sefer, keşif ve başarım. | Aynı olayı tekrar tekrar üretmez; kritik arayüzü kapatmaz. |

### Üst kaynak barı

1. Kredi ve Science stok ve değişim hızıyla gösterilir. Online üst sınırları yoktur.
2. Nüfus `kullanılan / toplam` biçiminde gösterilir; açıklamada boş kapasite ve açık varsa ceza bulunur.
3. Enerji `üretilen / gereken` ve net farkla gösterilir; enerji birikmiş stok değildir.
4. Malzeme için miktar/kapasite ve ilgili üretim-tüketim hızı gösterilir.
5. Ham toplamına açılan ayrıntıda her keşfedilmiş mineral ayrı satırdır.
6. Henüz açılmamış mineralin adı, rengi, ikonu, miktarı, fiyatı ve maliyet satırı sızdırılmaz.
7. Kaynak adı ilk geçerli keşiften sonra kalıcı görünür. Son üretici yıkılması ismi tekrar gizlemez.
8. Büyük sayılar yalnız görüntüde kısaltılır. Tam sayı açıklamada bulunur; ekonomi kısaltılmış metinden hesaplanmaz.
9. Üretim döngüsel olduğu için gösterilen saniyelik/dakikalık hız teorik akış özetidir. Gerçek stok teslimleri döngü bitiminde olur.
10. Net hız, mümkünse brüt üretim ve toplam tüketim ayrı açıklanır. `+12 / -8 = +4` gibi bir sunum tercih edilir.

### Bina kartı

Aynı model district içinde tek karttır. Kartın aynı modele ait mineral girdisi alt satırları bulunabilir. Her alt satır yeni bir fiyat ailesi veya yeni bina türü değildir.

Kartta en az şu alanlar bulunur:

- Görünen ad, model, tier ve adet.
- Kullanılan yuva ve büyük model işareti.
- Kuruluş için bir sonraki adedin tam kredi ve isimli malzeme bedeli.
- Çalışan ve enerji ihtiyacı.
- Aynı 20 saniyelik dönem için artan ve azalan stoklar.
- Enerji/konut gibi stok olmayan etkiler için kapasite veya akış etiketi.
- Seçilen mineral, girdi miktarı ve o mineralden beklenen işlenmiş çıktı.
- Aktif, oyuncu durdurdu, kaynak bekliyor, inşada, koşulu sağlanmıyor durumlarından uygun olanı.
- `+`, `-`, durdur/devam et ve girdi dağıtma işlemleri.
- Yıkımda elde edilecek kredi iadesi.

İki yuva kullanan model panelde de daha büyük karttır. Kartın geniş/büyük görünmesi gerçek yüzey koordinatı oluşturmaz. İki boş yuva yeterliyken görsel kart sırası yüzünden ek bir yer engeli oluşturulmaz.

### District, City ve üst yerleşim kartı

| Alan | Gösterilecek bilgi |
| --- | --- |
| Kimlik | Oyuncu adı, aile, gerçek model ve bulunduğu ebeveyn. |
| Üretim | Alt ağacın gerçek net toplamı; ayrı ikinci gelir yok. |
| Yer | İlgili fiziksel birimle konum ve mesafe etiketleri. |
| Coğrafya | Tam, yakın ve etkisiz özelliklerin anlaşılır gerekçesi. |
| Kapasite | Kullanılmış/toplam alt yerleşim veya bina yuvası. |
| Gelişim | Seviye, sonraki seviye koşulu, bedel ve kazanılacak kapasite. |
| Plan | Kullanılan hazır plan, elle sabitlenen içerik ve mevcut güncelleme teklifi. |
| Düzenleme | Ayrıntıya in, taşı, içeriği temizle, sıfırla ve yık. |
| Erişim | Kilidin araştırma, konum, kaynak veya demo kaynaklı nedeni. |

Tip 1'de sol panel districtleri gösterir. District seçilerek yüzeydeki gerçek yerine ve içindeki binalara inilebilir. Tip 2'de aynı sunum City, Tip 3'te gezegen, Tip 4'te güneş sistemi, Tip 5'te Gökada için sürer.

### Rol butonları

| Buton | Yüzey görünümündeki vurgu | Sistem görünümündeki vurgu |
| --- | --- | --- |
| Energy | Rüzgâr, güneş için uygun açık alan, kıyı, volkan ve jeotermal alanlar. | Yoğun ışık, gelgit, radyasyon ve soğuk füzyon koşulları. |
| Population | Ova, orman, kıyı ve uygun konut seçenekleri. | Ilıman gezegenler, buzaltı ve kapalı yaşam seçenekleri. |
| Production | Dağ, volkan, krater gibi miktar avantajları. | Asteroit kuşağı, soğuk işleme ve sıcak izabe olanakları. |
| Science | Dağ, tundra, eski yerleşim ve ilgili araştırma alanları. | Güneş gözlemi, derin gözlem, radyasyon ve kriyo araştırması koşulları. |
| Commercial | Kıyı, nehir, eski yerleşim ve yerleşim mesafeleri. | Kuşak pazarı, iç sistem kümesi ve dış sistem ikmali koşulları. |

Butonlar araziyi var etmez; zaten görünen özelliği vurgular. Mineral yoğunluğu, yeraltı yatak yüzdesi veya Terran/Tidal doğal saha haritası bu rol sunumunun parçası değildir.

### Yer önerisi

Oyuncu yakın küme, bağımsız uzak veya dengeli tercih seçebilir. Önerici en fazla üç geçerli seçenek sunar. Her seçenekte gerekçe, toplam bedel, enerji/nüfus farkı ve beklenen net çıktı bulunur.

İyi açıklama örnekleri:

- `Dağ üzerinde: Science +%30. İki uygun district çok yakın.`
- `Yoğun ışık kuşağında: Güneş Gözlemevi için tam uygunluk.`
- `Kıyı yakınında: konut coğrafyasının yarısı. Kuruluş bedeli daha düşük.`
- `En yakın City uzak: dış ikmal modeli kurulabilir.`

Tek bir gizli toplam puan veya açıklamasız yeşil alan yeterli değildir. Önerici yeni kurulacak nesnelerden daha kurulmadan yakınlık katkısı almaz. Bir toplu planın tamamlanmış durumu ayrıca önizlenebilir; bu bir üretim kaydı değildir.

### Satın alma ve kuruluş önizlemesi

1. Model ve uygun yer seçilir.
2. Kuruluş koşulları merkezi servisle hesaplanır.
3. Kredi, bütün malzemeler, nüfus/enerji ve kapasite farkı gösterilir.
4. Kurulacak gerçek alt içerik ve tahmini süre görünür.
5. Oyuncu onayladığında teklif yeniden doğrulanır.
6. Bakiye veya koşul değişmişse gizli ek bedel alınmaz; teklif yenilenir.
7. İşlem başarılı olursa tek işlem kimliğiyle ödeme ve inşaat başlar.

### Engellenmiş eylemlerin dili

| Neden | Açıklama örneği |
| --- | --- |
| Araştırma eksik | `Kriyo Teknolojileri araştırması gerekli.` |
| Konum uygun değil | `Bu model soğuk dış kuşakta veya buzlu gövdede kurulabilir.` |
| Malzeme eksik | Açılmış malzemenin adı ve eksik miktarı. |
| Kaynak henüz keşfedilmedi | İsim sızdırmadan `İlgili malzemeyi önce uygun yerel üretimle keşfet.` |
| Kapasite eksik | `2 yuva gerekli, 1 boş yuva var.` |
| Aile uyuşmazlığı | `Bu district yalnız Enerji City'sine kurulabilir.` |
| Demo sınırı | `Bu içerik tam oyunda kullanılabilir. Önizlemesini inceleyebilirsin.` |
| Taşıma yetkisi eksik | `İlgili ölçeğin Yerleşim Düzenleme araştırması gerekli.` |

Nüfus veya enerji açığı bir modelin açıkça tanımlanmış özel sert koşulu değilse sıradan kuruluşu gizlice kilitlemez. Beklenen imparatorluk cezası önizlemede görünür.

### Skill ağacı görünümü

- Mevcut medeniyetin düğümleri okunabilir, bağlantıları seçilebilir olmalı.
- Satın alınabilir, alınmış, ön koşulu eksik ve yalnız önizleme düğümleri ayırt edilmeli.
- Üst medeniyetlerin büyük ağaç silueti ölçeği hissettirmeli.
- Seçili düğüm için fiyat, seviye, AND/OR ön koşulları ve gerçek etkiler açıkça yazmalı.
- Satın alma sonrası kamera, seçili dal ve kaydırma konumu korunmalı.
- Fraktal geçişte önceki ağaç üst miras düğümünün içinde incelenebilir olmalı.
- Demoda Tip 1 ağacı ve miras düğümü görülebilir; satın alınamaz.
- Henüz keşfedilmemiş mineralin adı gelecekteki düğüm açıklamasından sızdırılmaz.

### Evren incelemesi

Demo tamamlandığında oyuncu güneş sistemi, Gökada, Galaksi, Evren ve Paralel Evrenler arasında dolaşabilir. Bir bölgenin içindeki gezegenlere kadar ayrıntı açılır. Yalnız art arda değişen arka planlar yerine gerçek hiyerarşi, tohumlanmış içerik ve çokluk hissi sunulur.

Bu sırada Dünya/Ay ekonomisi devam eder. İnceleme için ekonomik survey bedeli alınmaz. Bir gezegeni görüntülemek o gezegende şehir kurmaz, kaynak keşfetmez veya ekonomik kayıt oluşturmaz.

<a id="bolum-23"></a>

## 23. Kontroller, görsel dil, ses ve ayarlar

### Masaüstü kontrolleri

| İşlem | Varsayılan giriş | Kural |
| --- | --- | --- |
| Seçim | Sol tık. | Arayüz üzerindeki tık haritaya geçmez. |
| Yakınlaşma/uzaklaşma | Fare tekerleği; uygun yerde trackpad hareketi. | Fiziksel uzaklıkları veya bonusları değiştirmez. |
| Harita hareketi | Harita sürükleme; gezegen görünümünde WASD/oklar. | Metin alanına yazarken kamera hareket etmez. |
| Yerleştirmeyi iptal et | Sağ tık veya Escape. | Onaylanmamış önizleme para harcamaz. |
| Önceki panel / duraklatma | Escape. | Önce açık modalı kapatır, sonra oyun menüsüne gider. |
| Ekran görüntüsü | F12. | Kaynak veya ilerleme ödülü üretmez. |
| Ayrıntıya in | Seçili karttaki açık tuş veya izinli yakınlaşma. | Demo/oynanabilir içerik kontrolünü atlamaz. |

Haritadaki gizli kısayollar hiçbir ana mekanik için zorunlu değildir. Bütün önemli eylemler anlaşılır tuşlarla erişilir. Tuş isimleri teknik veri alanı veya kod kimliği biçiminde oyuncuya sunulmaz.

### Görsel dil

1. Uzay ve harita zemini koyu, kaynak ve seçim vurguları okunabilir olmalı.
2. Coğrafya yalnız rol butonuna basınca oluşmuş gibi görünmemeli.
3. Dağ, su, orman, buz, çöl, volkan ve krater görsel olarak ayırt edilmeli.
4. Yakınlık ilişkileri gerektiğinde geçici mesafe halkalarıyla gösterilebilir.
5. Yol çizgisi yerleşim düzenini anlatabilir; kalınlık veya kesişim ekonomik güç göstergesi değildir.
6. Büyük bina kartları ve üst ölçek özetleri içerik yoğunluğunu anlatmalı.
7. Kilitli içerikte silik görünüm ve metin birlikte kullanılmalı.
8. Uygunluk yalnız renkle açıklanmamalı; ikon ve kısa gerekçe bulunmalı.
9. Görsel gün/gece, bulut ve yörünge animasyonu ekonomi hesabına gizli dalgalanma eklememeli.
10. Görünürlük için gece gölgesini azaltmak üretim avantajı sağlamamalı.

### Ses

| Ses grubu | Kullanım |
| --- | --- |
| Music | Müzik ve uzun ortam katmanları. |
| UI | Tık, hover, yanlış eylem, araştırma ve seçim. |
| SFX | İnşaat, bina tamamlanması, roket ve yüzey geri bildirimi. |
| Master | Bütün grupların ortak düzeyi. |

Çok sayıda kredi veya üretim olayı aynı anda olduğunda sesler her adet için yığılmaz. Offline hesaplama binlerce üretim sesini tekrar oynatmaz; dönüş özeti bir kez sunulur. Üst haritaya geçiş mevcut müziği her defasında baştan başlatmaz.

### Ayarlar

| Ayar | Başlangıç | Ekonomiyle ilişkisi |
| --- | --- | --- |
| Tam ekran | Açık. | Ekonomik etki yok. |
| Ana/müzik/UI/SFX sesi | Ayrı kaydedilen düzeyler. | Ekonomik etki yok. |
| Gece gölgesi | Kullanıcının görsel tercihi. | Arazi ve üretim hesabını değiştirmez. |
| Offline ilerleme | Açık. | Kapalıyken kapalı süre üretimi ve ilerlemesi yapılmaz. |
| Görev paneli | Açık, daraltılabilir. | Daraltmak görevleri veya ekonomiyi durdurmaz. |
| Görsel hareketin azaltılması | Gerekirse erişilebilirlik tercihi. | Süreler ve bonuslar değişmez. |

Ayarlar dünya kaydından ayrı tutulur. Yeni oyun ses veya ekran tercihlerini sıfırlamaz. Demo sonucu, online kayıt ve offline tercihi oyuncunun açık seçimi olmadan değiştirilmez.

### Duraklatma ve sahne geçişi

- Açık duraklatma oyunun ekonomi saatini, inşaatını ve uçuşunu durdurur.
- Skill ağacı, görev paneli veya serbest evren incelemesi tek başına duraklatma değildir.
- Ana menüde beklemek aktif oyun ekonomisi değildir.
- Açık uygulamadaki duraklatma süresi sonradan offline kazanç olarak eklenmez.
- Uygulamanın gerçekten kapalı kaldığı süre, offline ayarı açıksa ortak 1/10 kuralla işlenir.
- Sahne değişimi ekonomik bir döngüyü yeniden başlatmaz; ödenmiş girdiyi yeniden almaz.

<a id="bolum-24"></a>

## 24. Kalıcı veri modeli ve içerik sözleşmeleri

### Kimlik ve hiyerarşi

Her gerçek nesnenin sabit `entity_id` değeri bulunur. Ebeveyn ve çocuk ilişkileri bu kimlikle tutulur. Oyuncunun ad değiştirmesi, görünümü kapatması veya başka ölçeğe geçmesi kimliği değiştirmez.

Büyük evren kimliği yalnız 0-99.999 arası kısa bir seed veya görünen isimden oluşturulamaz. İki farklı sistemde aynı kısa seed çıksa bile gövdeler aynı ekonomik nesneye birleşmemeli. Kimlik, üst bölge yolu ve yerel üretim anahtarıyla benzersiz oluşturulur.

| Veri nesnesi | Zorunlu alanlar |
| --- | --- |
| Dünya kökü | Kayıt sürümü, evren seed'i, aktif oturum, medeniyet, içerik yetkileri. |
| Doğal gövde | Kimlik, ebeveyn, gövde seed'i, gövde tipi, fiziksel yarıçap, mineral kümesi. |
| Sistem konumu | Ortalama yörünge uzaklığı, yıldız profili, sistem coğrafyası alanları. |
| Yerleşim | Kimlik, ebeveyn, aile, rol/model, seviye, durum, çocuklar. |
| Yüzey konumu | Gövde kimliği, fiziksel koordinat ve yerel yönelim. |
| Üst konum | Harita kimliği, harita birimiyle fiziksel konum. |
| Plan | Plan kimliği/sürümü, gerçek çocuk kimlikleri, elle sabitlenenler. |
| Edinim kaydı | Adet N, ödenmiş kredi toplamı C, kabuk/seviye yatırımı ve hizmet gideri ayrımı. |
| Üretim durumu | Model, adetler, seçilen girdi, ödenmiş döngü ve teslim zamanı. |
| Haklar | Bireysel ve miras kaynakları, canonical etkin seviye. |
| Sefer | Kimlik, başlangıç, hedef, hazırlık/uçuş durumları ve bitiş zamanı. |
| Görev geçmişi | Tek seferlik tamamlanma kimlikleri ve fiziksel üretim sayaçları. |
| Offline | Son işlenen zaman, kalan gelir bütçeleri ve online yenileme ilerlemesi. |

### İçerik tanımı ile canlı nesne ayrımı

`BuildingDefinition` veya `DistrictDefinition` bir model tarifidir. Kurulmuş canlı nesne bu tanıma referans verir. Tanım dosyasını yüklemek, modelin kurulmuş veya araştırılmış olduğu anlamına gelmez.

Bir tanım için en az şu alanlar bulunur:

| Alan | Anlam |
| --- | --- |
| `model_id` | Değişmeyen gerçek model kimliği. |
| `display_name_key` | Arayüz adı; kimlik yerine kullanılmaz. |
| `minimum_civilization` | İçeriğin ekonomik aşaması. |
| `host_family` | Hangi üst aileye kurulabileceği. |
| `functional_role` | Alt içerik ve çıktı işlevi. |
| `research_grants` | Açılış için gereken canonical haklar. |
| `site_requirements` | Açık AND/OR coğrafya ve yerleşim koşulları. |
| `price_key` | Tekrar sayacının gerçek anahtarı. |
| `base_credit_cost` | Kredi bedelinin merkezi tabanı. |
| `material_costs` | İsimli malzeme miktarları. |
| `slot_cost` | Binalarda 1 veya 2 gerçek yuva. |
| `population_load` | Küresel kullanılan nüfusa etkisi. |
| `energy_supply/demand` | Sürekli enerji üretimi ve ihtiyacı. |
| `cycle_inputs/outputs` | Ortak 20 saniyelik stok tarifi. |
| `capacity_effects` | Konut/depo gibi stok olmayan etkiler. |
| `special_effects` | Açık kapsamı ve tekilleştirme anahtarı bulunan destek. |
| `build_duration` | Ekonomi saniyesiyle kuruluş süresi. |
| `plan_children` | Üst ölçek modelinin kuracağı gerçek alt içerik. |

### Üretim kaydı

- Canlı üretici kendi `production_owner_id` değerini taşır.
- Üst özet kayıtları aynı sahip kimliğinin çıktısını tekrar üretmez.
- Aynı modele ait farklı mineral alt satırları modelin toplam adetlerini paylaşır.
- Başlamış döngü, ödediği girdiyi ve hesaplanan teslimi saklar. Offline tamamlanan kredi/Science teslimi yine kalan kazanç bütçesiyle sınırlıdır; kota dışı potansiyel sonraya finansal borç yazılmaz.
- Girdi değişimi başlamış döngüyü ikinci kez ödetmez.
- Durdurma, kaynak bekleme ve erişim engeli aynı durum değildir.
- Üretim kaydı silinirken devam eden döngünün kaydı da açık işlem kuralıyla kapanır.
- Fiziksel maden çıkarımı ve özel host yan katkısı farklı akış türleridir. Moonstone görevleri yalnız gerçek çıkarımı sayar.

### Koşul sistemi

Koşullar serbest metinden veya model adından çıkarılmaz. Açık türlenmiş alanlar kullanılır. Örnekler:

- `all_of`: soğuk dış kuşak **ve** atmosfersiz gövde.
- `any_of`: soğuk dış kuşak **veya** buzlu gövde.
- `surface_feature`: dağ üzerinde veya belirlenmiş yakın kuşakta.
- `nearby_count`: kendisi hariç en az iki gerçek City yakın.
- `nearest_distance_band`: en yakın City uzak veya çok uzak.
- `resource_discovered`: ilgili ham, uygun yerel üretimle keşfedilmiş.
- `content_playable`: Tip 1 ekonomisi açık.

AND/OR parantezleri arayüz açıklamasıyla birebir aynı olmalı. Bir satırdaki `ılıman ve orman veya kıyı`, açıkça `ılıman VE (orman VEYA kıyı)` olarak modellenir.

### Etkilerin kaynak kimliği

Her bonusun kendi kapsamı ve anahtarı bulunur. Aynı arazinin ebeveyn ve çocuk üzerinden gelen aktarımı tekilleştirilir. Araştırma, yakınlık ve farklı coğrafya gibi ayrı etkiler ilgili formülde bir kez birleşir.

| Etki | Kaynak/kapsam örneği |
| --- | --- |
| Yüzey coğrafyası | Özellik türü + etkilenen çıktı ailesi + alıcı. |
| Sistem coğrafyası | Sistem özelliği + etkilenen üretim hattı + alıcı. |
| Yakınlık | Kaynak nesne + alıcı nesne + ilişki. |
| Araştırma | Canonical grant + etkin seviye + uygun çıktı. |
| Host katkısı | District kimliği + sabit host referansı. |
| Plan özeti | Salt okunur toplam; üretim sahibi değildir. |

Kullanıcı adları, görsel lens seçimi veya açık kamera düzeyi bu anahtarların parçası değildir.

<a id="bolum-25"></a>

## 25. Kayıt, yükleme ve işlem güvenilirliği

### Kayıt kapsamı

Kayıt yalnız görünen gezegeni saklamaz. Bütün aktif yerleşimler, küresel cüzdanlar, gerçek çocuk ilişkileri, erişim hakları ve iş zamanları birlikte tutulur.

| Alan grubu | Kaydedilecek ayrıntı |
| --- | --- |
| Oturum | Sürüm, evren seed'i, home kimlikleri, son güvenilir zaman, aktif görünüm. |
| İlerleme | Medeniyet, oynanabilir içerik, demo, Ay ve son varış işaretleri. |
| Cüzdan | Kredi, Science ve keşfedilmiş kaynak stokları. |
| Keşif | Kalıcı keşif kümesi, gövde mineral tanımları, gerçek üretim sayaçları. |
| Yerleşimler | Kimlik, ebeveyn, konum, aile, rol, fiyat ailesi, ad ve seviye. |
| Binalar | Model, gerçek adet, girdi dağılımı, durdurma ve kapasite etkileri. |
| Planlar | Plan sürümü, elle değiştirilen içerik ve sabitlemeler. |
| Maliyet | N/C havuzları, kabuk/seviye ayrımı, iade edilmeyen hizmet bedelleri. |
| İşler | İnşaat, seviye, taşıma ve sefer kimliği; ödenmiş bedel; tamamlanma zamanı. |
| Döngüler | Ödenmiş girdi, mineral seçimi, kalan süre ve vaat edilen çıktı. |
| Araştırma | Bireysel seviyeler, miras seviyeleri, canonical etkiler. |
| Trade | Satış/alım kuralları, stok hedefleri ve malzeme rezervleri. |
| Offline | İşlenmiş aralık, bütçe bakiyeleri, online dolum ilerlemesi. |
| Görev/başarım | Tamamlanan tek seferlik olaylar; başarım tanımlarının kalıcı kimlikleri. |

### Kayıt alma

- Normal otomatik kayıt aralığı 60 gerçek saniyedir.
- Araştırma satın alma, sefer başlatma, ana varış, toplu yıkım/taşıma ve medeniyet geçişi gibi önemli işlemlerden sonra kayıt alınır.
- Uygulama kapanışında mümkün olan son durum kaydedilir.
- Kayıt önce geçici hedefe yazılıp tamamlandığında ana kayıtla değiştirilir. Yarım dosya geçerli kayıt sayılmaz.
- Ayarlar ayrı `user://settings.cfg` dosyasında tutulabilir.
- Dünya kaydı `user://voidle_save.dat` veya aynı sorumluluğu taşıyan sürümlenmiş dosyada saklanır.

### Yükleme sırası

1. Kayıt sürümünü ve bütünlüğünü oku.
2. Seed ve dünya kimliklerini kur; yeni oyun bütçesi dağıtma.
3. Doğal gövdeleri deterministik olarak geri oluştur veya önbellekten bağla.
4. Gerçek yerleşimleri sabit kimlikleri ve ebeveynleriyle yükle.
5. Cüzdanları, keşifleri, canonical hakları ve maliyet havuzlarını yükle.
6. İnşaat, sefer ve ödenmiş üretim döngülerini geri bağla.
7. Görev ve başarım geçmişini geri yükle.
8. Offline ayarı açıksa henüz işlenmemiş kapalı süreyi bir kez işle.
9. Sonuçları ve yeni son işlenen zamanı kaydet.
10. Arayüzü tamamlanmış duruma bağla ve ekonomi saatini aç.

Yüklenmiş kredi, Science, erişim işaretleri veya home yerleşimi daha sonra başlangıç kurulumuyla tekrar atanmaz. Başarısız yükleme yarım canlı ekonomiye dönüşmez.

### Sürüm ve uyumsuz kayıt

Bu ekonomi için açık bir `save_schema_version` kullanılır. Uyumlu olmayan kayıt otomatik yeni kayıt gibi okunmaz. Oyuncuya uyumsuzluk anlaşılır biçimde bildirilir; kullanıcı yeni oyun başlatmadan mevcut dosya silinmez. Ayrıntılı geriye dönük migration bu kapsamın zorunlu teslimi değildir.

### Tek işlem ilkesi

Kuruluş, toplu güncelleme, yıkım, taşıma ve sefer başlatma için benzersiz işlem kimliği bulunur. Aynı işlem tekrar çağrıldığında ikinci bedel, ikinci varlık veya ikinci ödül oluşmaz.

Bir işlem sırası:

1. Erişim ve hedef kimliklerini doğrula.
2. Son fiyat, malzeme, yer ve kapasiteyi yeniden hesapla.
3. Çakışan nesne ve rezervleri kontrol et.
4. Bedeli ve gerçek nesne değişimini tek tutarlı işlemde uygula.
5. Tamamlanma işini kaydet.
6. İlgili önbellekleri ve ekranları güncelle.
7. Kalıcı sonucu kaydet.

İşlem tamamlanmadan arayüzden kaybolması, bedelin alınmış fakat nesnenin oluşmamış olduğu kalıcı durum yaratmaz.

<a id="bolum-26"></a>

## 26. Evren üretimi, koordinatlar ve performans

### Seed ile dünya üretimi

- Aynı evren kimliği ve bölge yolu aynı doğal içeriği üretir.
- Ana dünya Terran, gerekli Ay erişilebilir ve ana ilerleme için uygun yüzeyli olmalı.
- Yüzey görünümü ile ekonomik coğrafya aynı üretim kaynağına dayanmalı.
- Mineral kümesi gövde verisidir; yüzeyde ayrı yatak haritası üretilmez.
- Uzak sisteme geçmek bütün ham kaynakları kendiliğinden açmaz.
- Görüntülenen yıldız/sistem sayısı oyundaki bütün evrenin aynı anda bellekte tutulmasını gerektirmez.
- Doğal içerik üretimi oyuncu yerleşimi üretmez. Ekonomik alt ağaç yalnız gerçek kuruluş işleminde oluşur.

### Harita üretiminin kapsamı

| Katman | Üretilecek içerik | Ekonomi kaydı |
| --- | --- | --- |
| Gezegen | Yüzey, görünen coğrafya, yerleşilebilir alan ve doğal kimlik. | Yalnız gerçek yerleşimler. |
| Güneş sistemi | Yıldız, ortalama yörüngeler, gezegen/uydular, kuşaklar ve sistem özellikleri. | Yalnız izinli aktif gövdelerin yerleşimleri. |
| Gökada | Sistemlerin kimliği, görünür dağılımı ve üst konumları. | Oynanabilir aşamada gerçek sahip olunan sistemler. |
| Galaksi | Gökada bölgeleri ve ayrıntıya açılan çocuklar. | Önizleme sırasında gelir yok. |
| Evren | Galaksi bölgeleri ve ayrıntı zinciri. | Önizleme sırasında gelir yok. |
| Paralel Evrenler | Evren kimlikleri ve ölçek hissi veren görünüm. | Önizleme sırasında gelir yok. |

### Fiziksel koordinatlar

- Yüzeyler km ve fiziksel yarıçapla hesaplanır.
- Sistem içi uzaklık AU ile saklanır veya açık dönüşümle gösterilir.
- Daha üst haritalar kendi açık uzaklık profiline sahiptir.
- Kamera pikseli fiziksel mesafe değildir.
- Küre üzerindeki yüzey mesafesi büyük çember uzaklığıdır; iki boyutlu ekrandaki piksel aralığı değildir.
- Bir nesnenin alt konumları kendi yerel koordinat sisteminde tutulur.
- Üst nesnenin gerçek yeniden konumlandırılması alt yerel düzeni korur; yeni çevrenin koşulları yeniden değerlendirilir.
- Yörünge animasyonu, yıldızın ekrandaki büyüklüğü, kamera eğimi ve gün/gece açısı ekonomik konum değildir.

### Büyük sayılar

Kredi ve Science online sınırsızdır. Bu, kullanılan sayı biçiminin sonsuz değer kabul etmesi anlamına gelmez. Ekonomi tanımlı aralıkta sonlu, negatif olmayan sayılarla çalışır.

- Görüntü kısaltması hesap değerini yuvarlamaz.
- Maliyet karşılaştırmaları aynı hassasiyetle yapılır.
- Tekrarlı kayan nokta sapmaları stokları negatif yapmaz.
- Tier, seviye ve medeniyet çarpanları merkezi parametrelerden gelir.
- Tip 4-5 ekonomisi oynanabilir hale getirilirken mevcut sayı aralığı yetersizse büyük sayı temsili ayrı altyapı işi olarak ele alınır.
- Önizleme için fiziksel watt büyüklüklerini doğrudan üretim parasına eşitleme.

### Performans kuralları

1. Milyarlarca gövdeyi aynı anda üretme; görünür bölgeyi gerektiğinde üret.
2. Aktif ekonomik nesneleri önizleme nesnelerinden ayır.
3. Kamera değişmediği halde bütün araziyi ve bütün kartları her karede yeniden oluşturma.
4. Yakınlık araması için uzamsal indeks kullan; sonuçta bütün uygun kaynakları say.
5. Performans için ekonomik komşu sayısına gizli tavan koyma.
6. Üretim toplamlarını ilgili değişikliklerde geçersiz kıl; aynı toplamı her kart ayrı döngüyle hesaplamasın.
7. Offline zamanı milyonlarca görsel kare çalıştırarak ilerletme.
8. Sonraki olay zamanı üzerinden döngü/inşaat/sefer yürüt; sonuç online ile aynı sırayı korusun.
9. Birbirini etkileyen stoklar için bütün üretimi tek toplu çarpımla bedelsiz sonuçlandırma.
10. Bildirim, ses ve kamera efektleri ekonomik olayın kendisi değildir; toplu işleme sırasında özetlenebilir.

### İçerik ve yetki önbellekleri

Araştırma, keşif, medeniyet, yerleşim konumu, aile, inşaat bitişi veya kapasite değişince ilgili fiyat/koşul/çıktı önbelleği güncellenir. Yalnız ekranı kapatıp açmak doğru sonucu almak için gerekli olmamalı.

<a id="bolum-27"></a>

## 27. Proje sorumluluk haritası ve hedef servisler

Bu bölüm uygulama yapan geliştirici veya yapay zekâ içindir. Godot kaynak yolları proje köküne göredir. Bir dosyanın listede bulunması ilgili hedef sistemin uygulanmış olduğunu göstermez; sorumluluğun nereye bağlanacağını belirtir.

### Mevcut proje girişleri

| Godot kaynak yolu | Sorumluluk ve hedef davranış |
| --- | --- |
| `res://project.godot` | Ana sahne ve autoload kayıtları. Yeni ekonomi servisleri eklenirse başlatma/yükleme sırası açık olmalı. |
| `res://scenes/MainMenu.tscn` | Yeni oyun, devam, ayarlar ve çıkış sunumu. |
| `res://scripts/system/MainMenu.gd` | Uyumlu kayıt kontrolü ve yalnız gerçek yeni oyunda başlangıç kurulumu. |
| `res://scripts/game/GameState.gd` | Küresel cüzdanlar, erişim alanları, gövde/yerleşim kimliği, kayıt ve sefer ana durumları. |
| `res://scripts/game/Economy.gd` | Kaynak tanımları, ortak kapasite, fiyat, nüfus ve ekonomik sabitler. |
| `res://scripts/game/ResourceData.gd` | Kaynak kimliği ve görüntüleme bilgisi; keşif kilidini aşmayan tanımlar. |
| `res://scripts/game/BodyResources.gd` | Gövde mineral kümesi. Yatak, yoğunluk ve sistem sıçramasından bağımsız erişim. |
| `res://scripts/game/PlanetProgress.gd` | Yerleşimler, bina adetleri, yuvalar, aileler, girdi alt satırları ve gerçek maliyet havuzları. |
| `res://scripts/game/ProductionManager.gd` | Online/offline ortak üretim, stok akışları, enerji/nüfus cezası ve gerçek toplamlar. |
| `res://scripts/game/BuildingDef.gd` | Bina model tarifi, yuva, konum, kuruluş, kapasite ve döngü verisi. |
| `res://scripts/game/DistrictDef.gd` | Tip 0 districtler ve Tip 1 gerçek model/aile/rol tanımları. City merkezini normal aileyle karıştırmama. |
| `res://resources/buildings/` | Bütün gerçek bina modellerinin veri kaynakları. Bina erişimi yalnız dosyanın varlığıyla açılmaz. |
| `res://resources/districts/` | District ve merkez veri kaynakları; 50 Tip 1 modelinin açık kimlikleri için genişletilecek içerik alanı. |
| `res://scripts/game/SkillTree.gd` | Canonical araştırmalar, fiyatlar, ön koşullar, etkiler, miras ve içerik erişimi. |
| `res://scripts/ui/SkillTreeView.gd` | Ağaç, bağlantılar, kilit açıklaması ve fraktal önizleme. |
| `res://scripts/planetary/PlanetaryView.gd` | Yerleşim seçimi, rol butonları, ortak kartlar, kuruluş ve düzenleme önizlemeleri. |
| `res://scripts/planetary/PlanetData.gd` | Doğal gövde, yüzey görünümü, yarıçap, atmosfer ve alt uydular. |
| `res://scripts/planetary/TerrainSampler.gd` | Görünen yüzey özelliklerinin ortak sorgusu; ekranla ekonomi aynı araziyi okumalı. |
| `res://scripts/planetary/TerrainMap.gd` | Yüzey coğrafyasının harita temsili. |
| `res://scripts/planetary/ResourceMap.gd` | Sürekli mineral/doğal saha puanları ekonomik erişim kaynağı olmamalı; rol uygunluğu ayrı sözleşmeyle sunulur. |
| `res://scripts/planetary/LocationFinder.gd` | Gerçek koşullara uygun yer ve açıklanabilir kuruluş önerileri. |
| `res://scripts/planetary/POIData.gd` | Gerçek yerleşim kimliği, ebeveyni ve ekonomik tanımı. |
| `res://scripts/planetary/POILayer.gd` | Görsel yerleşim işaretleri; ekonomik kayıt sahipliği değildir. |
| `res://scripts/planetary/RoadNetwork.gd` | Yol görünümü; fiyat, komşu sayısı veya üretim bonusu kaynağı değil. |
| `res://scripts/planetary/RoadAStar.gd` | Görsel yol güzergâhı; ekonomik erişim için zorunlu bağlantı oluşturmaz. |
| `res://scripts/planetary/OrbitalLayer.gd` | Yörünge görünümü ve Orbital City'nin gerçek kimlikle temsil edilmesi. |
| `res://scripts/solar/SolarData.gd` | Sistem kimliği, yıldız, fiziksel yörüngeler ve sistem coğrafyası profili. |
| `res://scripts/solar/SolarView.gd` | Sınırlı sefer hedefi seçimi, sistem incelemesi ve izinli ölçek geçişi. |
| `res://scripts/solar/AsteroidBelt.gd` | Görünür kuşak; varlığı kendiliğinden yeni hammadde keşfi değildir. |
| `res://scripts/solar/PlanetOrbitNode.gd` | Ekonomik ortalama konumdan ayrı görsel yörünge sunumu. |
| `res://scripts/solar/MoonOrbitNode.gd` | Uydu görünümü ve doğru doğal ebeveyn ilişkisi. |
| `res://scripts/galaxy/GalaxyData.gd` | Üst sistem dağılımı ve deterministik bölge üretimi. Gökada/Galaksi katman ayrımı açık eklenmeli. |
| `res://scripts/galaxy/GalaxyView.gd` | Üst harita incelemesi ve içerik yetkisi kontrolü. |
| `res://scripts/galaxy/GalaxyCanvas.gd` | Harita çizimi, seçim ve görünür bölge sunumu. |
| `res://scripts/game/ShipManager.gd` | Sade roket hazırlığı/uçuş olayı. Genel kargo/fleet planlayıcısı ana yolun şartı değil. |
| `res://scripts/game/logic/SpaceportLogic.gd` | Earth ve Lunar Spaceport iş akışları, isimli bedeller ve tek seferlik tamamlanma. |
| `res://scripts/data/ShipData.gd` | Sefer kimliği ve görünür roket durumu; üretim ve varışın iki kez kaydedilmemesi. |
| `res://scripts/mission/MissionTaskRegistry.gd` | Kullanılıyorsa sade sefer adımlarıyla sınırlandırılır; görev panelinin zorunlu kargo zinciri olmaz. |
| `res://scripts/system/HUDManager.gd` | Global bar, tooltip, görev erişimi, ayar/menü ve durum açıklamaları. |
| `res://scripts/system/TutorialManager.gd` | Ekonomik yardım vermeyen görev/öğretim sınırı. Kalıcı yeni görev yapısı ayrı servis olabilir. |
| `res://scripts/game/AchievementManager.gd` | Gerçek olaylar ve adetlerle tek seferlik başarım, ekonomik ödül yok. |
| `res://resources/achievements/` | Sabit kimlikli başarım tanımları; enum sıra numarasına bağımlı bağlantılar doğrulanacak. |
| `res://scripts/system/SettingsManager.gd` | Ekran/ses, offline tercihi ve görsel seçeneklerin ayrı kaydı. |
| `res://scripts/system/AudioManager.gd` | Ses grupları, toplu olay seslerinin sınırlandırılması ve sürekli müzik. |
| `res://scripts/system/ScreenshotManager.gd` | F12 görüntüsü; ekonomi ve keşif üzerinde etkisi yok. |
| `res://scripts/ui/SceneTransition.gd` | Görsel geçiş; kaynak bütçesini veya ekonomi saatini yeniden başlatmaz. |
| `res://scripts/system/DevConsole.gd` | Geliştirici araçları. Oyuncunun normal ilerlemesini açıklayan veya zorunlu yapan yol değildir. |

### Ayrıştırılacak ortak sorumluluklar

Aşağıdakiler görev sınırıdır; aynı sorumluluk mevcut dosyada güvenilir biçimde bulunuyorsa yalnız ad uğruna ikinci servis yaratılmaz.

| Sorumluluk | Tek doğru hesap / komut |
| --- | --- |
| İçerik erişimi | `can_play`, `can_preview`, `can_research`, `can_discover`, `can_settle`. |
| Kaynak defteri | Ekle, harca, rezerve et, teslim et, taşmayı işle ve offline bütçesini uygula. |
| Ekonomi zamanı | Online/offline ortak olay sırası ve ödenmiş döngüler. |
| Konum | Yüzey ve sistem özellikleri, gerçek uzaklık, tam kaynak katkıları. |
| Fiyat | Aynı gerçek model sayacı, seviye, isimli malzeme ve toplu teklif. |
| Yerleşim komutları | Kur, Güncelle, taşı, temizle, sıfırla ve yık. |
| Haklar | Canonical bireysel/miras seviyeleri ve etkilerin tek uygulanması. |
| Sefer | Hazırlık, uçuş, hedef ve bir kez varış. |
| Görevler | Gerçek olaydan ana/ara hedef ilerlemesi; ekonomik ödül üretmeme. |
| Sunum | Gerçek durumdan kart, tooltip, harita ve bildirim oluşturma. |

### Uygulamada kaldırılacak ekonomik varsayımlar

Bu liste teknik görev tarifidir; ana oyun kurallarına alternatif değildir.

1. `act1_complete` gibi içerik etiketlerini medeniyet ve demo durum sözleşmesine bağla. Ay'da ilk City son bitiş olayı değildir.
2. Sisteme uzaklık/hop sayısını hammadde erişiminin anahtarı olarak kullanma.
3. Mineral yoğunluğu ve yerel yatak puanını çıkarım erişiminden kaldır.
4. En nadir hammaddenin otomatik harcanmasını kaldır; oyuncunun girdi seçimini uygula.
5. District içindeki bütün farklı bina türlerini aynı fiyat sayacında toplama.
6. Aynı City'deki bütün farklı district türlerini aynı tekrar sayacında toplama.
7. Gezegen bazlı nüfus cezasını global kapasite/yük sözleşmesiyle değiştir.
8. Tur süresini yavaşlatıp aynı anda ortak döngüde çıktı azaltarak cezayı iki kez uygulama.
9. Yolları, kesişimleri ve paylaşım yoğunluğunu ekonomik bonus kaynağı olmaktan çıkar.
10. Capital için yol veya yalnız doğrudan bağlı çocuk istisnası bırakma.
11. Yakın kaynaklara sıra indirimi veya kaynak sayısı tavanı uygulama.
12. Konut/enerjiyi 20 saniyede stok biriktiren kaynakmış gibi gösterme.
13. Bina seviye yükseltmesini aktif arayüz gelişim sistemi yapma.
14. Üst tier veya gelecekteki modelin yalnız varsayılan `unlocked` alanıyla erken açılmasına izin verme.
15. Tutorial para/Science/Ferrite hibeleri ve eksik cüzdan tamamlama yollarını devreden çıkar.
16. Ücretsiz tam evren incelemesini ekonomik survey bedeline bağlama.
17. Yüklenen kaydı başlangıç dünyası kurulurken yeniden bütçelendirme.
18. İşlevsel rolü korunan hibrit districti sırf City ailesi değişti diye farklı bir bina üreticisine dönüştürme.
19. Genel City veya oyuncu adı üzerinden sınırsız yeni indirim fiyat ailesi yaratma.
20. Aynı research grant'ini bireysel satın alma ve miras üzerinden iki defa uygulama.

<a id="bolum-28"></a>

## 28. Uygulama paketleri ve bağımlılıklar

Her paket hedef davranış ve veri sözleşmesiyle teslim edilir. Kullanıcı yalnız bir paketi isterse diğer paketleri kendiliğinden uygulama. Bu sıralama bütün güncellemenin nasıl somutlaştırılacağını gösterir.

| Paket | İş | Ön koşul | Somut teslim |
| --- | --- | --- | --- |
| P01 | İçerik/medeniyet/demo yetkileri. | Yok. | Ayrı durum alanları ve bütün eylemler için merkezi kontroller. |
| P02 | Gerçek nesne hiyerarşisi ve kimlikler. | P01. | Ebeveyn/çocuk, merkez, aile/rol ve gerçek alt ağaç. |
| P03 | Sürümlü kayıt ve doğru yükleme. | P02. | Yeni oyun bütçesinin tekrarlanmaması; işler ve döngülerin saklanması. |
| P04 | Tek kaynak defteri ve görünürlük. | P01-P03. | Kredi/Science/stok akışları ve kalıcı keşif durumu. |
| P05 | Gövde mineral kümesi ve gerçek yerel keşif. | P04. | Yataksız çıkarım, uygun üretici ve gizli mineralin sızmaması. |
| P06 | Ortak 20 saniyelik stok döngüsü. | P04-P05. | Aynı girdi/çıktı gösterimi ve ödenmiş döngü kaydı. |
| P07 | Global nüfus ve enerji. | P06. | Kapasite, yük, boş nüfus geliri ve tek global ceza. |
| P08 | Fiyat, seviye, yuva ve edinim havuzu. | P02-P07. | Model bazlı tekrar, iki yuva ve N/C kredi muhasebesi. |
| P09 | Görünür 14 yüzey coğrafyası. | P02,P06. | Ekranla aynı özellik, tam/yarım uygunluk ve tekilleştirme. |
| P10 | Gerçek km ve yakın/uzak katkıları. | P09. | Ayrı City/district profili, bütün uygun kaynaklar ve yol etkisinin kaldırılması. |
| P11 | Tip 0 bina kataloğu. | P05-P10. | Bütün tarifler, büyük modeller, Moonstone bedelleri ve doğru açılışlar. |
| P12 | Canonical araştırma grafiği. | P01,P11. | Ortak yol, strateji dalları, erken Fuel/Rare, tek etkili grant'ler. |
| P13 | Trade ve kapasite taşması. | P04,P06,P12. | Manuel al/sat, rezervler, erken erişim ve izinli taşma satışı. |
| P14 | Otomasyon kuralları. | P13. | Aynı model üzerinden stok hedefleri ve güvenilir emir sırası. |
| P15 | Otomatik plan ve Güncelle. | P02,P08-P12. | Gerçek ücretli alt içerik, fark teklifi ve manuel sabitleme. |
| P16 | Yıkma, temizleme ve sıfırlama. | P03,P08,P15. | Alt ağaç tek işlemi, doğru iade ve doğal kimliğin korunması. |
| P17 | Taşıma ve ölçek yetkileri. | P09-P10,P15-P16. | Gerçek konum değişimi, bedel ve yeni koşulların önizlemesi. |
| P18 | Kartlar, rol butonları ve öneriler. | P07-P17. | Tek model/girdi alt satırları, büyük kart ve açıklanabilir öneri. |
| P19 | Ay yolculuğu ve Ay ekonomisi. | P05,P11-P13. | Lander, Ay yerleşimi, gerçek Moonstone ve özel tesis. |
| P20 | Gelişmiş roket ve son hedef. | P19. | Araştırma, isimli bedel, hazırlık, seçilen hedef ve tek varış. |
| P21 | Görev ve başarım bağlantıları. | P12,P19-P20. | Sürekli panel; gerçek adet/olaylar; para hibesi yok. |
| P22 | Fraktal araştırma. | P12,P15. | Canonical max ile miras, ücretsiz fiziksel içerik oluşturmama. |
| P23 | Demo sonucu ve evren incelemesi. | P01,P20-P22. | Ekonomiyi kilitlemeyen sonuç; Tip 1 ağacı salt önizleme. |
| P24 | Offline ortak yürütme. | P03-P07,P13-P14,P19-P20. | 1/10 saat, kredi/Science bütçesi ve tekrar işlenmeyen zaman. |
| P25 | Tip 1 aile atama ve otomatik uyarlama. | P02,P12,P15,P22. | Önce snapshot sınıflandırma, sonra host/rol ayrımı; ücretli dönüşüm yok. |
| P26 | Sistem coğrafyası. | P09-P10,P25. | Görünen dokuz özellik, AU ve sabit ortalama yörünge hesabı. |
| P27 | Tip 1'in 25 temel district modeli. | P11-P12,P15,P25-P26. | Gerçek plan/kimlik/maliyet, sabit host katkısı ve aile kilidi. |
| P28 | Tip 1'in 25 özel district modeli. | P27. | Değişken aile sayıları, bütün açık koşullar ve ekonomik ödünler. |
| P29 | Tip 1 yeni araştırma dalları ve plan güncellemeleri. | P22,P27-P28. | Aşamalı model açılışı; demoda bütün satın almalar kapalı. |
| P30 | Üst ölçek önizleme ve veri kapsamı. | P02,P17,P23. | Tip 2-5 merkez/alt ağaç/koordinat sözleşmesi; yeni tam ekonomi değil. |
| P31 | Ayar, ses ve giriş tutarlılığı. | P18,P23-P24. | Offline tercihi, kamera/UI ayrımı, toplu olay sunumu. |
| P32 | Kullanıcının oynanış geri bildirimine göre denge. | İstenen oynanabilir paketler. | Merkezi katsayı düzenlemesi; hangi kurala neden dokunulduğunun açık raporu. |

P25-P29 tam oyunun Tip 1 ekonomisini hazırlar. Demo teslimi bu modelleri gerçekten satın almaya açmak zorunda değildir. Tip 1 ağacı ve içerik önizlemesi izinlere uygun biçimde sunulur.

### Paket tesliminin anlamı

- İlgili tanımlar ve bunları kullanan gerçek komut yolları aynı kuralı okumalı.
- Yalnız kart metnini değiştirmek ekonomik uygulama sayılmaz.
- Yalnız veri dosyası eklemek, erişim ve gerçek üretim bağlanmadıysa oynanabilir içerik sayılmaz.
- Değişen dosyalar ve kapsam raporlanır.
- Kaynak okuması, kod yazılması veya belge incelemesi oyun davranışının çalıştırılarak doğrulandığı anlamına gelmez.
- Kullanıcı istemedikçe test/build/motor çalıştırılmaz; bu sınırlama açıkça korunur.

<a id="bolum-29"></a>

## 29. Beklenen davranışlar ve uygulama kabul ölçütleri

Bu bölüm otomatik test çalıştırma emri değildir. Tasarımın uygulanmış sayılabilmesi için beklenen davranışları ve kullanıcının değerlendireceği sonuçları tanımlar.

### Ekonomi ve kapasite

| Durum | Beklenen sonuç |
| --- | --- |
| Üst bar 30.000 toplam,20.000 kullanılan nüfus gösteriyor. | Fazla nüfus etkisi10.000 üzerinden hesaplanır; ücretsiz City nüfusu dışlanmaz. |
| Oyuncu başka bir gezegeni inceliyor. | Global nüfus/enerji değişmez; aktif üretimler sürer. |
| Bina stok üretmiyor ve tüketmiyor. | Stok döngüsü çubuğu yerine kapasite/akış bilgisi görünür. |
| İşleme grubunun bazı adetlerine girdi yetiyor. | Yalnız beslenebilen gerçek adetler başlar; bütün grup boş yere durmaz. |
| Girdi seçimi başladıktan sonra değiştirilmiş. | Ödenmiş döngü kendi girdisiyle biter; sonraki döngü yeni seçimi kullanır. |
| Enerji ve nüfus açığı var. | Aynı merkezi ceza bir kez uygulanır; süre ve çıktı aynı anda ikinci ceza almaz. |
| Aynı model farklı mineral satırlarına bölünmüş. | Toplam adet, yuva ve aynı model fiyat sayacı değişmez. |
| Trade henüz açılmamış, depo dolu. | Yeni taşma kaybolur; arayüz nedeni gösterir. |
| Trade açık, depo dolu. | İzinli taşma satış fiyatıyla krediye dönüşür. |
| Depo yıkılmış. | Mevcut stok silinmez; yeni pozitif birikim yeni kapasiteye göre sınırlandırılır. |

### Konum ve yakınlık

| Durum | Beklenen sonuç |
| --- | --- |
| Bir district dağ üzerinde, diğeri dağın yakın kuşağında. | İlki tam, ikincisi yarım dağ bonusu alır. |
| City ve district aynı dağ özelliğini taşıyor. | Aynı çıktı için dağ iki defa sayılmaz. |
| Dört uygun district çok yakın. | Dördünün de tam katkısı alınır; sıra indirimi yok. |
| Araya başka district veya yol girmiş. | Fiziksel yakınlık engellenmez. |
| Capital'ın yolu yok. | Uygun fiziksel mesafede merkez katkısı yine çalışır. |
| Kamera uzaklaşmış. | Fiziksel mesafe ve bütün ekonomik etkiler aynı kalır. |
| Ay daha küçük üretilmiş. | Aynı km aralığı daha az yerleşime izin verir; mesafe dereceye çevrilerek eşitlenmez. |
| Tip 1 City'leri3.000km'den yakın kurulamıyor. | City yakınlık profili bunu dikkate alır; districtin500/1.000km eşiği City'ye kopyalanmaz. |
| Yörünge animasyonu gezegeni başka ekrana taşıyor. | Ekonomik kuşak ortalama konuma göre sabit kalır. |

### İçerik, araştırma ve plan

| Durum | Beklenen sonuç |
| --- | --- |
| Skill açılmış, planın boş yuvası var. | Güncelle gerçek yeni içeriği bedeliyle teklif eder; ücretsiz eklemez. |
| Oyuncu bir nesneyi elle sabitlemiş. | Varsayılan Güncelle onu taşımaz veya yıkmaz. |
| Enerji City'sinde Enerji Bilimi kuruluyor. | Aile uyumludur; bilim rolü ve enerji host katkısı korunur. |
| Enerji City'sine başka City ailesine ait district kurulmak isteniyor. | Komut aile nedeniyle reddedilir; görünmeyen arayüz yolu da atlayamaz. |
| Genel City uzmanlık bekliyor. | Oyuncu beş aileden birini seçer; fiziksel yatırımlar korunur. |
| Tip 0'dan kalan bilim districti Enerji City'sinde. | Aynı nesne Enerji Bilimi olarak uyarlanır; binalar, yer, seviye ve asıl bilim üretimi silinmez. |
| Oyuncu aynı canonical hakkı bireysel ve mirastan almış. | Etkin seviye max kuralıyla bir kez uygulanır. |
| İlerideki tier veri dosyasında açık işaretli. | Merkezi medeniyet/araştırma kontrolü satın almayı yine engeller. |
| Gözlemevi iç kuşakta ve dağ üzerinde. | Farklı sistem ve yüzey etkileri birleşir; aynı özellik yeniden aktarılmaz. |
| Vakum modeli atmosferli gövdeye taşınmak isteniyor. | Geçerlilik ve duracak içerik önizlemede açıkça gösterilir; sessiz üretim sürmez. |

### Yıkım, taşıma ve muhasebe

| Durum | Beklenen sonuç |
| --- | --- |
| Gerçek ödenmiş kredi toplamı1.000, iade oranı%50. | İade500; güncel şişmiş katalog fiyatı üzerinden değil. |
| Aynı gruptan bir adet kaldırılıyor. | Ortalama edinim payı N/C havuzundan düşer; yalnız iade düşülmez. |
| City alt ağacı yıkılıyor. | Kabuk, seviye ve çocuklar birer kez sayılır; plan toplamı ikinci ödeme oluşturmaz. |
| Aynı ebeveynde district taşınıyor. | Alt ağaç ve maliyet geçmişi korunur; hizmet bedeli iade tabanına eklenmez. |
| Başka ebeveyne aktarım hedefte daha pahalı. | Hedef tekrar fiyatı farkı kökün kendi kuruluş edinimiyle karşılaştırılır; bütün çocuk yatırımı farkı sıfırlamak için kullanılamaz. |
| Oyuncu gezegen yerleşimini siliyor. | Doğal gövde seed'i ve mineral kümesi evrenden silinmez. |
| Taşıma üst nesneye uygulanıyor. | Alt yerel koordinatlar korunur, yeni çevrenin uygunluğu yeniden değerlendirilir. |

### Sefer, demo ve offline

| Durum | Beklenen sonuç |
| --- | --- |
| İlk Ay City'si kurulmuş. | Demo bitmez. |
| Moonstone trade ile alınmış. | Gerçek yerel100Moonstone görevi ilerlemez. |
| Gerçek Ay çıkarım aracı Moonstone üretmiş. | Geçerli fiziksel üretim sayacı artar. |
| Seçilen yeni gezegene roket varmış. | Tip 0 tamamlanır, Tip 1 gösterilir, demo tamamlanır. |
| Hedef gaz devi. | Varış yörüngeye erişim olarak sunulabilir; demo yeni City kurmaz. |
| Oyuncu demo sonucunu kapatmış. | Dünya/Ay ekonomisi çalışır, üst evrenler incelenir. |
| Tip 1 ağacında miras düğümüne basılmış. | Demoda satın alma gerçekleşmez. |
| Oyuncu uygulamayı kısa aralıklarla açıp kapatıyor. | Offline gelir bütçesi her girişte sıfırlanmaz. |
| Offline kredi veya Science bütçesi bitmiş. | Diğer izinli simülasyon sürer; sınırsız finansal kazanç oluşmaz. |
| Aynı kayıt ikinci kez yüklenmiş. | İşlenmiş kapalı süre ve varış olayları yeniden kazanç yaratmaz. |
| Offline ayarı kapalı. | Kapalı süre için üretim, uçuş veya inşaat ilerlemesi eklenmez. |

<a id="bolum-30"></a>

## 30. İçerik kapsamı ve gelecekte genişleme sınırı

### Ayrıntılı tanımlanmış içerik

- Tip 0: ana dünya ve Ay, ilk ekonomiden gelişmiş roket varışına kadar tam temel döngü.
- Bütün12ham kaynağın medeniyet erişimi ve üç işlenmiş ürünün ortak anlamı.
- Tip 0 gerçek bina modelleri, araştırmalar, üretim ve fiyat formülleri.
- Trade, offline, kapasite, görünürlük ve kayıt kuralları.
- Tip 1: beş City ailesi,25temel ve25özel gerçek district, sistem coğrafyası ve otomatik/elle yönetim.
- Tip 0-5: dört katman, otomatik merkez, gerçek alt ağaç ve taşıma eşlenikleri.
- Demo: son varış, devam eden temel ekonomi ve ayrıntılı evren/araştırma önizlemesi.

### Gelecek içerik olarak sınırlandırılan alanlar

| Alan | Şimdiki sözleşme | Bu belgeye bakarak kendiliğinden eklenmeyecek içerik |
| --- | --- | --- |
| Tip 2-5 tür katalogları | Katman, merkez, kaynak erişimi, alt ağaç ve genişleme yapısı sabit. | Her aşama için uydurulmuş50City/gezegen/sistem türü ve oynanabilir yeni ekonomi. |
| Üst ölçek coğrafyası | Görünen özellik, açık uzaklık profili, ilgili katmanda yakın/uzak ve tek aktarım. | Tip 0 km veya Tip 1 AU sınırlarının bütün evrene kopyalanması. |
| Gaz devi yerleşimi | Demo hedefi ve inceleme geçerli; yüzey olmayan gövdeye kayalık yüzey kurulmaz. | Tasarlanmamış yüzey veya yüzen şehir ekonomisini bedava açma. |
| Orbital City içeriği | Otomatik merkez rolü ve district seviyesinde genişleyebilir yapı. | Ana Ay yolculuğunu zorunlu genel istasyon/kargo zincirine bağlama. |
| Alternatif başlangıçlar | Başlangıç Terran. | Volkanik/gaz başlangıcı ve otomatik ayrı skill ağaçları. |
| Tutorial | Ekonomik ödülsüz yönlendirme; görevler sürekli. | Kesin eğitim seed'i veya zorunlu kapsamlı yeni tutorial senaryosu. |
| Narrative | Görev verisi ileride metin ve koşullu olay taşıyabilir. | Yazılmamış hikâyeyi tamamlanmış görev zinciri sayma. |
| Steam | Yerel başarımlar sabit kimlikli ve ödülsüz. | Bağlantısı kurulmamış platform entegrasyonunu çalışıyor sayma. |
| Rekabet ve savaş | Bu ekonomik döngünün parçası değil. | Silah, düşman istilası, gezegen yok etme veya savaş kaynağı ekleme. |
| Filo ve yerel kargo | Roket hazırlığı/hedef/varış sade. | Kaynakları gezegenler arasında fiziksel kargo gemileriyle taşımaya zorlama. |

Bu sınırlar eksik doldurulacak sorular değildir; uygulamanın kapsamını belirler. İlgili alan ayrıca tasarlanıp yetkilendirilene kadar açık veri sözleşmesi korunur, oynanabilir içerik eklenmez.

### Yeni içerik eklerken korunacak ilkeler

1. Her model için kurulma nedeni, yer koşulu, girdi, çıktı ve bir bedel yaz.
2. Aynı rolü daha ucuza ve her koşulda daha iyi yapan model üretme.
3. Bir ailenin seçenek sayısını diğerleriyle eşitlemek için işlevsiz tür ekleme.
4. Yeni medeniyet, mevcut ayrıntının silinmesi anlamına gelmesin.
5. Her ölçeğin en küçük gerçek yerleşimi isteğe bağlı elle yönetilebilir kalsın.
6. Kaynak sayısını artırmak yerine mevcut kaynaklara anlamlı talep oluştur.
7. Zorunlu özel yapıları görünür ana hedefe bağla; sıradan temin yollarında stratejik alternatifleri koru.
8. Ekonomik katsayıların ürün değeri, enerji, çalışan, bakım, kapasite ve kuruluş maliyetini birlikte değerlendir.
9. Online ve offline için iki ayrı oyun ekonomisi yazma.
10. Tamamlanmamış içeriği yalnız isim veya siluet bulunduğu için uygulanmış sayma.

<a id="bolum-31"></a>

## 31. Ana tasarım kararlarının bütünlük özeti

Bu tablo ayrıntılı kuralların yerine geçmez. Uygulamada bütün konuların kapsandığını izlemek için kısa dizindir.

| Konu | Bağlayıcı hedef |
| --- | --- |
| İlerleme adı | Medeniyet Tip 0,1,2,3,4,5. |
| Ölçek | Her tipte dört katman; aşağıda gerçek yatırımlar korunur. |
| Merkez | Her yerleşim ölçeğinin otomatik bir alt merkezi vardır. |
| Tip 0 bina | Bağımsız yüzey koordinatı yok, district koşullarını miras alır. |
| Üst en küçük birim | Gerçek konumlu, otomatik yerleştirilen ve ayrıntıda düzenlenebilir. |
| City uzmanlığı | Tip 1'de beş aile; Genel durumda oyuncu seçer. |
| District uyarlama | Host aile değişir, asıl rol ve yatırımlar korunur; ücretli dönüşüm yok. |
| Tip 1 katalog |25temel+25özel=50 gerçek model. |
| Tip 1 aile dağılımı | Enerji11,Üretim12,Bilim10,Nüfus8,Ticaret9. |
| Nüfus | Global kapasite/kullanım, demografik büyüme yok. |
| Enerji | Global sürekli akış, stok değil. |
| Üretim | Ortak20ekonomi saniyelik stok tarifi, açık girdi/çıktı. |
| Ham kaynak |12sabit mineral, medeniyet ve uygun yerel üretimle erişim. |
| İşlenmiş ürün | Goods,Fuel,Rare. |
| Maden dağılımı | Gövde genelinde, yerel yatak veya yoğunluk şartı yok. |
| Girdi seçimi | Oyuncu seçer; otomatik en nadir harcama yok. |
| Kuruluş malzemesi | Açık kaynak isimleri, genelrawcüzdanı yok. |
| Coğrafya | Görünen14yüzey ve9sistem/gövde özelliği; tam/yarım/yok. |
| Yakınlık | Bütün uygun kaynaklar tam sayılır; yol ve sıra indirimi yok. |
| Uzaklık | Gerçek fiziksel mesafe, beş etiket. |
| Fiyat | Aynı gerçek modelin yerel tekrar sayacı. |
| Bina gelişimi | Adet ve yeni model; aktif bina seviye sistemi yok. |
| Tier | Yoğun avantajla birlikte maliyet/işletme bedeli. |
| Araştırma | Dallanan/birleşen strateji ağı, seçim sayısı sınırı yok. |
| Fraktal miras | Önceki gerçek ağacı tek ücretli düğümle tamamlar; etkiler bir kez. |
| Güncelle | Açılmış yeni içeriği gerçek ücretli fark olarak kurar. |
| Yıkım | Gerçek edinim kredisi üzerinden%50,%65,%75iade; malzeme iadesi yok. |
| Taşıma | İlgili skill, korunmuş alt ağaç ve açık maliyet. |
| Trade | Erken erişim, açılmış ürünler, manuelScience, rezervli otomasyon. |
| Taşma | Trade öncesi kayıp, trade sonrası izinli satış. |
| Offline | Varsayılan açık,1/10ortak saat, yeni kredi/Science'a yenilenebilir kota. |
| Ay | Gerçek yerel100Moonstone, özel Spaceport ve gelişmiş roket. |
| Demo bitişi | Seçilen başka gezegene varış; yeni City yok. |
| Demo sonrası | Temel ekonomi sürer; üst evrenler ve Tip 1 ağacı incelenir. |
| Görevler | Sürekli ana/ara panel; ekonomik hibe yok. |
| Başarımlar | Gerçek olay/adet, kalıcı kimlik, ekonomik ödül yok. |
| Kayıt | Tek gerçek dünya, sürümlü veri, aynı süre/iş ikinci kez işlenmez. |
| Uygulama sınırı | Kullanıcı istemedikçe motor/test/build çalıştırılmaz. |

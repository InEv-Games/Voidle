# Voidle büyük güncelleme V2

Yeni sistem, ilk sayısal denge taslağı ve uygulama planı

Tarih: 19 Ekim 2026  
Durum: İncelenecek tasarım belgesi. Oyun güncellenmedi.

Dayanaklar: [Güncel mekanik envanteri](C:/Users/drosm/Voidle/MEDENIYET_0_MEKANIK_VE_MATEMATIK.md), [kullanıcının düzenlediği V1](C:/Users/drosm/Voidle/VOIDLE_BUYUK_GUNCELLEME_TASARIM_V1.md), ilk 48 yorum, sonraki 9 yorum, ek fikirler ve S01-S48 cevapları.

## 1. Bu sürümün anlamı

Bu belge önceki planın güncellenmiş halidir. V1'deki artık cevaplanmış sorular ve eski kararlar yeni kural gibi kullanılmayacak. Kullanıcının doldurduğu medeniyet, merkez ve kaynak tabloları korunmuştur.

| İşaret | Anlamı |
| --- | --- |
| **Karar** | Kullanıcının kesinleştirdiği hedef davranış. |
| **Hesap taslağı** | Kullanıcının verdiği yetkiyle seçilmiş somut sayı veya formül. Oyuna uygulanmadı; iyi olup olmadığı değerlendirilecek. |
| **Askıda** | Henüz kesin değişiklik yapılmayacak fikir. |
| **K sorusu** | Matematik katsayısı değil, eksik kalan anlam veya kapsam kararı. |

**Sayılar aritmetik karşılaştırmalarla hazırlanmıştır. Godot, oyun testi veya oynanış denemesi yapılmadı.** Hiçbir stratejinin her durumda aynı hızda ilerlediği kanıtlanmış değildir. Amaç, ortak kurallarla yakın yatırım geri dönüşleri kurmak ve uzun zorunlu beklemeleri azaltmaktır.

Sayısal taslağın hedefi: Tip 0 demosunda oyuncunun yaklaşık 30-90 saniyede bir anlamlı karar verebilmesi; büyük hazırlıklar sürerken geliştirebileceği alternatifler bulunması. **45-75 dakikalık toplam demo süresi yalnız ilk tasarım hedefidir**, ölçülmüş veya garanti edilmiş süre değildir.

### Kısa okuma haritası

| Konu | Bölüm |
| --- | --- |
| Demo sınırı ve medeniyet katmanları | 2-3 |
| Otomatik planlar, elle yönetim ve tür ataması | 4 |
| Kaynak erişimi ve nüfus | 5-6 |
| Coğrafya ve mesafe/yakınlık/uzaklık | 7-8 |
| Ortak matematik, tarif, fiyat ve iade | 9-12 |
| Bina ve skill düzeni | 13-14 |
| Doldurulmuş Ay geçişi ve görev paneli | 15-16 |
| Trade ve offline | 17-18 |
| Önizleme, kapsam, uygulama sırası ve açık sorular | 19-23 |
| Eski yorum ve cevapların izleme tablosu | 24 |

## 2. Tip 0, demo bitişi ve Tip 1 başlangıcı

### Kararlar

1. Oyuncu ana dünyadan Ay'a gider.
2. Ay'da bir Production / Industrial District kurar ve Moonstone çıkarımını başlatır.
3. İşlenmiş ürünlere yerel üretim veya izin verilen ticaret yollarıyla ulaşabilir.
4. Ay'a özel Spaceport ve gelişmiş roket hazırlanır.
5. Oyuncu kendi yıldız sistemindeki diğer gezegenlerden istediğini hedef seçer. Hedefin uzaklığı bu demo seferinin bedelini veya süresini değiştirmez.
6. **Roket hedef gezegene ilk kez vardığında Civilization Type 0 tamamlanır ve Tip 1 başlar.**
7. **Demo bu eşikte biter. Hedef gezegende City kurulamaz ve Tip 1 ekonomisi oynanamaz.**
8. Ayrıntılı üst ölçek önizlemeleri bu olaydan sonra açılır.

Ay'da ilk City kurulması eski demo bitişini tetiklemeyecek. V1'deki “demo hiç bitmeyecek” anlamı son cevapla değişmiştir: demo artık doğru noktada, başka gezegene varışta biter.

Varış bildirimi, ilerlemenin sonucunu açıklayabilir. Oyuncuyu haritaları incelemekten alıkoyan kapalı bir ekran olmayacak. Ayrıntılı önizleme ile oynanış erişimi birbirinden ayrı kalacak.

**Genel filo/kargo/gemi görev planlayıcısı eklenmeyecek.** Ay ve gezegen seferleri sade ilerleme olayları ve uçuş görselleridir. Sürekli görev paneli de filo görev sistemi değildir.

## 3. Medeniyetler ve otomatik merkezler

### Kullanıcının belirlediği katman sırası

| Tip | Kapsayıcı harita | Büyük yerleşim | Alt yerleşim | Üst görünümde solda özetlenen en alt katman |
| --- | --- | --- | --- | --- |
| 0 | Gezegen | City | District | Bina |
| 1 | Güneş sistemi | Gezegen | City | District |
| 2 | Gökada | Güneş sistemi | Gezegen | City |
| 3 | Galaksi | Gökada | Güneş sistemi | Gezegen |
| 4 | Evren | Galaksi | Gökada | Güneş sistemi |
| 5 | Paralel Evrenler | Evren | Galaksi | Gökada |

Bu tabloda **Gökada** ve **Galaksi**, kullanıcının verdiği iki ayrı oyun katmanının adıdır. Bu belge onları birleştirmiyor veya yeni bir küme katmanı eklemiyor.

### Otomatik merkez eşlemesi

| Tip | Yerleşilen ana nesne | Otomatik oluşan merkez alt nesne | Merkez adı | İşlev |
| --- | --- | --- | --- | --- |
| 0 | City | District | Capital District | Diğer districtlere merkez bonusu. |
| 1 | Gezegen | City | Orbital City | Diğer City'lere merkez bonusu. |
| 2 | Güneş sistemi | Gezegen | Dyson Sphere Gezegen | Diğer gezegenlere merkez bonusu. |
| 3 | Gökada | Güneş sistemi | Stellar Engine System | Diğer güneş sistemlerine merkez bonusu. |
| 4 | Galaksi | Gökada | Black Hole Gökada | Diğer gökadalara merkez bonusu. |
| 5 | Evren | Galaksi | Spacetime Galaksi | Diğer galaksilere merkez bonusu. |

Ana nesneye yerleşildiğinde merkez otomatik eklenir. Tekrar ekran açmak, kayıt yüklemek veya otomatik planı yeniden uygulamak ikinci bir merkez üretmez. Merkezin kuruluş katkısı ana yerleşimin toplam bedeline dahildir; ücretsiz merkezleri yıkıp kredi üretmek mümkün olmayacak.

Tip 0 City'nin konum etkisi doğrudan City'nin bulunduğu yerden hesaplanır. Bu, City'nin ikinci bir Capital gibi komşulara ayrıca merkez bonusu dağıtması değildir. City'nin yerel etkisi kendisine ait alt üretimlere aktarılır; aynı coğrafi özellik aynı çıktı üzerinde tekrar sayılmaz.

## 4. Otomatik plan, ölçeği küçültme ve işlevsel tür

### En alt katmanın düzeltilmiş kuralı

| Durum | Konum ve bonus davranışı |
| --- | --- |
| Tip 0'daki bina | Ayrı yüzey konumu ve bağımsız yakınlık/uzaklık hesabı yok. District koşullarını miras alır. |
| Tip 1'de solda özetlenen district | Gerçek konumu, coğrafyası ve yakınlık/uzaklık ilişkileri vardır. Otomatik plan bunları yerleştirir. |
| Tip 2'de solda özetlenen City | Aynı biçimde gerçek alt yerleşimdir. Üst görünümde yalnız özeti gösterilir. |
| Daha yüksek medeniyetler | Daha önce kurulmuş alt nesneler gerçek kayıtlarıyla korunur; görünümün sadeleşmesi simülasyonu silmez. |

Oyuncu hızlı oynamak isterse otomatik bir kuruluş planı seçer. İsterse ölçeği küçültüp Tip 0 ayrıntısına kadar iner ve **aynı nesneleri** tek tek düzenler. Ayrı bir kopya dünya veya ikinci kez üretim oluşmaz.

### Otomatik planların hesap taslağı

- Enerji, Production, Science, Residential, Commercial ve Karma kuruluş planları sunulur.
- Plan, erişilebilir yapıların gerçek bedellerini toplar; toplamı onaydan önce gösterir.
- Kilitli içerik kurmaz, görünmeyen hammaddenin adını sızdırmaz.
- Uygun coğrafyayı, seçilen yakın/uzak yaklaşımı ve çalıştırılabilir enerji/nüfus durumunu gözetir.
- Elle yerleştirmeye ceza, otomatik plana ücretsiz üretim bonusu verilmez.
- Otomatik plan var olan elle kurulmuş içerikleri izinsiz silmez veya yeniden konumlandırmaz.
- Yer yoksa bütün plan bedelini alıp yarım bırakmaz; kurulabilen kapsam ve bedel önceden gösterilir.

### Üç farklı bilgi tutulacak

| Alan | Örnek | Değişme kuralı |
| --- | --- | --- |
| Oyuncunun verdiği isim | Riva | Oyuncu değiştirmedikçe korunur. |
| Kuruluş planı | Science City | Hangi otomatik/özel planla kurulduğunu açıklar. |
| Güncel işlevsel tür | Production City | Gerçek alt yerleşim sayılarından otomatik hesaplanır. |

“Kendi City'ni kur”, “Kendi gezegenini kur” vb. **kuruluş biçimidir**, fiyat artışından kaçış sağlayan yeni bir ekonomik tür değildir. Oyuncu özel yerleşim düzenini oluşturur; sonuç yine otomatik tür alır.

### Geçişte ve sonradan otomatik tür ataması

- Tip 0'da City'lere ekonomik tür etiketi/fiyatı uygulanmaz.
- Tip 1'e geçince mevcut City'lerde tamamlanmış normal districtler sayılır. Sayısı en yüksek aile City'nin işlevsel türüdür.
- Capital ve otomatik merkezler bu yarışa katılmaz. İnşaat halindeki yapılar sayılmaz.
- Seviye, bina adedi veya üretim hızı sayımı ağırlıklandırmaz. Kullanıcının seçtiği basit ölçü **alt yerleşim sayısıdır**.
- En yüksek sayıda eşitlik varsa Karma, merkez dışında hiç alt nesne yoksa Genel türü atanır.
- Tip 2'de gezegenler City türlerinden, sonraki ölçekler aynı mantıkla kendi alt yerleşimlerinden tür alır.
- Elle ekleme/yıkım tamamlandığında tür güncellenir. Güncel tür kendi başına gizli üretim çarpanı vermez.

| Baskın aile | City örneği | Gezegen örneği |
| --- | --- | --- |
| Production | Production City | Production Gezegen |
| Science | Science City | Science Gezegen |
| Energy | Energy City | Energy Gezegen |
| Residential | Residential City | Residential Gezegen |
| Commercial | Commercial City | Commercial Gezegen |
| Eşitlik | Karma City | Karma Gezegen |

Örnek: 3 Production, 2 Science, 1 Energy districti olan City, Tip 1'de Production City olur. Oyuncunun koyduğu isim değişmez.

Canlı işlevsel türün fiyat sayacını sonradan değiştirip değiştirmemesi ayrı bir konudur. Tür değiştirerek tekrar fiyatından kaçılmaması için önerilen sabit kuruluş ailesi **K04**'te sorulmuştur. Tip 0 City'sinde bu fiyat türü yoktur.

## 5. Kaynaklar ve görünürlük

Yeni kaynak türü yok. 12 ham kaynak ile Goods, Fuel ve Rare korunur.

### Kullanıcının doldurduğu kaynak dağılımı

| Tip | Kaynaklar | Bulunma ve üretim rolü |
| --- | --- | --- |
| 0 | Ferrite, Moonstone | Ferrite metal yataklarında, Moonstone Ay regolitinde. Production Districtler çıkarır ve işler. İnşaat, Goods ve roket hazırlığı. |
| 1 | Cinderite, Cryolite | Cinderite volkanik, Cryolite buzlu alanlarda. Production City'leri çıkarır ve işler. Sanayi ve Fuel. |
| 2 | Dune Quartz, Helion | Çöl ve gaz bakımından zengin bölgeler. Production gezegenleri toplar ve işler. Gelişmiş yapılar ve işlenmiş ürünler. |
| 3 | Astralite, Aurorium | Kristal ve metal bakımından zengin güneş sistemleri. Production güneş sistemleri toplar ve işler. Bilim, enerji, Rare. |
| 4 | Xenite, Nyxium | Sıra dışı madde ve karanlık bölgeleri olan gökadalar. Production gökadaları toplar ve işler. Üst tier yapılar. |
| 5 | Quantium, Singularite | Anomaliler ve yoğun kara delik bölgeleri olan galaksiler. Production galaksileri toplar ve işler. En ileri yapılar ve Rare. |

### Çift erişim koşulu

Bir ham kaynak için hem ilgili medeniyete ulaşılmış olacak hem de kaynağın bulunduğu yerde uygun Production nesnesi tamamlanmış olacak. Kaynak bu koşullar öncesinde hiçbir kaynak listesinde, trade teklifinde veya ödeme satırında görünmeyecek.

Hesap taslağı: Bu iki koşulla kazanılan **ilk erişim kalıcıdır**. Son üretici yıkılınca stok veya adı tekrar gizlenmez; yalnız aktif yerel çıkarım durur. Böylece oyuncu önceden biriktirdiği kaynağı ve tarif seçimini kaybetmez. Yerel üretim görevi için ayrıca gerçek çıkarım kaydı gerekir.

Coğrafi alanın görüntüsü görülebilir; **kaynağın adı, simgesi, fiyatı ve stok kaydı** kilit açılmadan gösterilmez. Gelecek içeriği gösteren harita bu ekonomik kilidi aşmaz.

İlk çıkarımı başlatacak Production nesnesi kendi henüz açılmamış hammaddesini kuruluşta istemez. Örneğin Ay'ın ilk Production District'i için Moonstone bedeli konmaz. Böylece başlangıç döngüsü kilitlenmez.

Yerel çıkarım koşulu üretici sahipliğine bağlıdır. Bir hammaddenin stokunu satın almak, ilgili yerde çıkarım yapmış sayılmaz. Ancak erişim açıldıktan sonra o kaynağı ticaretle desteklemek mümkündür.

### Kaynak seçimi ve isimli ödemeler

- Fabrikada oyuncu girdiyi seçer; seçili mineral biterse grup durur.
- Farklı girdi kullanan aynı binalar ayrı üretim gruplarında gösterilir.
- Girdi değişikliği bir sonraki turda etkili olur. Devam eden turun ödenmiş girdisi ve vaat edilmiş çıktısı değişmez.
- İnşaat/yükseltme bedelleri “200 raw” demez; **100 Ferrite + 50 Moonstone** gibi kaynak isimlerini ve ayrı miktarları ister.
- Bir tarif açıkça alternatif sunmuyorsa Ferrite bedeli Moonstone ile sessizce karşılanamaz.

Nadirlik verimi şimdilik korunur:

```text
R1: ×1     R2: ×1,75     R3: ×2,50
Her sonraki nadirlik için +0,75
```

Bu dönüşüm bonusudur; bütün kaynakların Tip 0'da erişilebilir olması anlamına gelmez.

**Grup davranışı taslağı:** Aynı girdiyi kullanan 3 binanın her biri 4 mineral istiyorsa 8 stokla 2 bina başlar, üçüncü bekler. Tüm grubu yeterli stok gelene kadar kilitlemeyiz; iki farklı hammaddenin eksik parçalarını da tek tarifte birleştirmeyiz. Gruplar oyuncunun verdiği öncelikle, eşit öncelikte dönüşümlü başlatılır. Kartta çalışan/bekleyen adet, seçilmiş girdi, tur başına tüketim ve gerçek çıkacak miktar görünür.

## 6. Ortak nüfus, enerji ve fazla nüfus stratejisi

Nüfus zamanla büyüyen bir stok olmayacak. Konut ve iş gücü kapasitesi olarak kalacak ve bütün imparatorlukta ortak hesaplanacak.

```text
Boş kapasite = toplam konut - toplam nüfus yükü
```

### Ortak ceza hesabı

Konut yeterliyse stok üretim hızı %100. Yetersizse:

```text
Hız = %50 + %50 × karşılanan nüfus payı
```

| Kapasite | Yük | Bütün imparatorlukta stok üretim hızı |
| ---: | ---: | ---: |
| 30.000 | 30.000 | %100 |
| 30.000 | 40.000 | %87,5 |
| 30.000 | 60.000 | %75 |

Enerji de ortak dengedir. Aynı ceza biçimi enerji tüketen üreticilere uygulanır. İki açık aynı üreticide çarpılır. Konut kapasitesi ve enerji akışı tekrar aynı ceza ile azaltılıp kendi kendini büyüten açık oluşturmaz.

### Fazla konutu avantaja çevirme: hesap taslağı

Üç skill ile nüfus ağırlıklı oyun mümkün hale gelir:

| Skill | Katkı |
| --- | --- |
| Sivil Girişimler | Her 1.000 kullanılmayan uygun konut kapasitesi için dakikada 10 kredi. |
| Serbest Araştırma | Aynı 1.000 kapasite için dakikada 2 Science. |
| Üretim Rezervi | Her %10 boş kapasite için ham/işlenmiş üretime +%2; en fazla +%20. |

Doğrudan gelir hesabında kullanılacak uygun kapasite, **binaların verdiği konut ile gerçekten boş toplam kapasitenin küçük olanıdır**. City'lerin ücretsiz 15.000 tabanı tek başına bu geliri üretmez. Böylece yalnız ücretsiz City açarak sınırsız gelir yolu oluşmaz.

Bir Habitat Block 2.500 kapasiteyi boş tutabiliyorsa ilk iki skill ile dakikada 25 kredi + 5 Science sağlar. Bunlar nüfusu satmak değildir; kullanılmayan kapasitenin hizmet/araştırma etkisidir.

Bu gelirler konut kapasitesini tekrar artırmaz. Üretim Rezervi de konuta uygulanmaz. Önce gerçek kapasite/yük, sonra bu etkiler hesaplanır.

## 7. Coğrafya: üç durum ve ilk bakışta okunabilen alanlar

### Kesin model

| Durum | İlgili özelliğin tam bonusundan alınan pay |
| --- | ---: |
| Normal / uzakta | %0 |
| Özelliğin yakınında | %50 |
| Özelliğin üzerinde | %100 |

Özelliğin üzeri, görünür alan sınırının içinde olmak demektir. Yakın alan ilk taslakta bu sınırın dışındaki **250 km** kuşaktır. Oyuncuya kilometre yazmak zorunlu değil; alanın yakın kuşağı seçili yerleşim ön izlemesinde gösterilebilir. Bu, rastgele nokta yüzdesi değildir.

Farklı özelliklerin katkıları toplanır. Aynı dağın birden fazla işareti veya aynı coğrafya türünün üst üste örnekleri bir bonusu tekrar tekrar vermez. Bir noktada dağ, göl ve eski yerleşim gerçekten varsa üçü de katkı verebilir.

### Genişletilmiş görünür coğrafya tablosu

Aşağıdaki yüzdeler **tam bonus hesap taslağıdır**. Yakında yarısı kullanılır. “Enerji: güneş” gibi sınırlar ilgili bina ailesini anlatır; kıyı bonusu ilgisiz bir reaktöre uygulanmaz.

| Özellik | Oyuncu butona basmadan ne görür? | Tam bonus | Kuruluş / kapsam |
| --- | --- | --- | --- |
| Dağ | Belirgin yükselti, kayalık sırt, kar/gölge | Production +%20, Science +%30 | Kara. |
| Yüksek plato | Düz üst yüzeyli yüksek basamak | Production +%10, Science +%10 | Dağ etiketiyle aynı zemin parçasında iki kez sayılmaz. |
| Ova | Geniş düz açık arazi | Residential +%20, Commercial +%10 | Kara. |
| Verimli ova | Parlak bitki örtüsü, tarla dokusu | Residential +%30 | Ayrı yiyecek kaynağı üretmez. |
| Orman | Açıkça seçilen ağaç kümeleri | Residential +%10, Science +%10 | Kara. |
| Deniz kıyısı | Su-kara sınırı ve dalga çizgisi | Residential +%20, Commercial +%20, tidal enerji +%20 | Yapı kara/kıyı kuralına uyar. |
| Göl kenarı | Kapalı su alanı ve kıyı | Residential +%20, Science +%10 | Deniz gelgiti gibi davranmaz. |
| Nehir | Kesintisiz görünen akarsu | Residential +%10, Commercial +%20 | Yeni bir kaynak türü yok. |
| Delta | Nehrin denize dallanarak açılması | Commercial +%30, Residential +%10 | Nadir çoklu uygunluk noktası. |
| Çöl | Kum tepeleri, kuru açık yüzey | Güneş enerjisi +%30, Science +%10 | Güneş ailesi. |
| Tundra | Soluk bitki örtüsü, donmuş toprak | Science +%20, Residential +%10 | İklim görünür olmalı. |
| Buzul | Kalın buz dili, çatlak buz dokusu | Science +%20 | Cryolite adı medeniyet kilidinden önce görünmez. |
| Volkanik alan | Kızıl lav, volkan ve kül | Jeotermal enerji +%30, Production +%20 | Ayrı bir hasar/afet sistemi bu sürüme eklenmez. |
| Jeotermal yarık | Buhar ve parlayan çatlak | Jeotermal enerji +%40 | Volkanik alanla gerçekten ayrı özellikse toplanır. |
| Rüzgârlı bölge | Sürekli yönlü bulut/toz/ot hareketi | Rüzgâr enerjisi +%30 | Wind için görünür uygunluk. |
| Kanyon | Derin yarık ve keskin gölge | Production +%10, Science +%20 | Kara. |
| Eski yerleşim | Yıkık bina izleri ve yollar | Science +%30, Commercial +%20 | Sürekli konum etkisi; henüz narrative ödül yok. |
| Ferrite yatağı | Metalik kaya damarları | Production +%30 | Ferrite erişimi uygun Production kuruluşuyla açılır. |
| Ay regoliti | Açık gri kırıntılı yüzey | Production +%20 | Moonstone çıkarım alanı. |
| Krater | Belirgin halka ve çukur | Production +%10, Science +%20 | Ay ve uygun kayalık gövdeler. |
| Koyu Ay düzlüğü | Koyu, geniş ve düz bazalt alan | Residential +%10, güneş enerjisi +%10 | Ay'a yerleşim seçeneği. |
| Doğal liman | Korunaklı koy ve giriş | Commercial +%30 | Deniz kıyısıyla ayrı özellik olarak görülebilir. |

Bu tablo var olan bütün görsellerin hazır olduğu iddiası değildir. Özelliğin oyuncu tarafından ilk bakışta ayırt edilemediği durumda, ilgili bonusu açmadan önce görseli hazırlanacak. Eski sayısal lensi saklayıp görünmez yeni özellikler üzerinden bonus vermek kabul edilmiyor.

### Bonus aktarımı

Dağ üzerinde Production +%20, krater yakınında Production +%5 varsa toplam +%25 olur.

```text
District tabanı 10 -> 12,5
İlgili bina 30 -> 37,5
Toplam 40 -> 50
```

Binaya aynı +%25 ikinci kez uygulanmaz. City'den ve districtten gelen etkiler **coğrafya türü + etkilenen çıktı ailesi** ile tekilleştirilir; her türün en güçlü geçerli katkısı kullanılır. City dağ yakınında +%10 Production, district başka bir dağın üzerinde +%20 alıyorsa toplam dağ etkisi +%20'dir. Dağ ile krater gibi farklı türler toplanır.

Energy District'in ailesiz 3 enerji tabanı, bulunduğu yerde en güçlü toplamı veren enerji ailesinin coğrafya profilini bir kez kullanır. Rüzgâr ve jeotermal yüzdeleri bu tabanda birbirine eklenmez. Binalarda kendi açık aile etiketi geçerlidir.

Tablodaki kaynak adları belge içindir. Kaynak henüz açılmamışsa oyuncu “Ferrite yatağı” yazısı yerine yalnız görünür metalik kaya alanını görür. Kaynak adı erişim koşulundan önce sızdırılmaz.

## 8. Mesafe, yakınlık ve uzak yerleşim

### Gerçek uzaklık, sade gösterim

Arka planda yüzey uzaklığı kullanılır. Yakınlaştırma veya gezegenin ekranda büyük çizilmesi ekonomik uzaklığı değiştirmez. Fiziksel gövde boyutu küçükse aynı aralıklarla daha az yerleşim sığar.

Tip 0 hesap taslağı:

| Oyuncunun gördüğü etiket | Arka plandaki yüzey uzaklığı | Uzaklık katkısı |
| --- | --- | ---: |
| Çok yakın | 500 km'ye kadar | %0 |
| Yakın | 500-1.000 km | +%12,5 |
| Orta | 1.000-2.000 km | +%25 |
| Uzak | 2.000-3.500 km | +%37,5 |
| Çok uzak | 3.500 km ve üzeri | +%50 |

Oyuncuya kilometre veya derece yazılmaz. Seçili yerde beş etiketten biri gösterilir. Tip 0'da başlangıç hesap değerleri: yüzey districtleri arasında en az 250 km, City merkezleri arasında en az 3.000 km. Görsel alanın boyutu ile bu aralık aynı şey değildir.

Gövde yarıçapı oyun modelinde başlangıç dünyası için 6.000 km referansıyla ölçeklenebilir. Ay boyut oranı 0,45 tutulursa yüzey alanı ana dünyanın yaklaşık %20,25'i olur. Aynı kuruluş aralıkları bu yüzden Ay'a daha az yerleşim sığdırır. Bu, “kesin şu kadar City sığar” sonucu değildir; arazi ve City kapasitesi de etkilidir.

Uzak stratejiyi baştan engelleyen dar City erişim yarıçapı kullanılmayacak. District aynı gövdede bir City'ye ait kalır; kapasite ve minimum kuruluş aralığına uyar. Sadece Capital'dan uzak olduğu için kuruluş düğmesi kapanmaz.

Üst medeniyetlerde etiketler aynı kalır, arka plandaki birim büyür: sistem ölçeğinde yörünge mesafesi, sonraki ölçeklerde daha büyük uzay uzaklıkları. Üst tiplerin sayısal eşikleri, o haritalar oynanabilir yapılırken belirlenir; Tip 0 kilometreleri bütün evrene kopyalanmaz.

### Normal yakınlık geometriktir

- Aynı gövdedeki bütün uygun yakın districtler hesaba katılır; başka City'ye ait olmaları kendiliğinden engel değildir.
- Aradaki district, dağ, deniz veya kesişen yol diğer yakın yapıyı kesmez.
- Normal yakınlık için yol şartı aranmaz.
- Başlangıçta aynı türler birbirini etkiler. Residential konutu, Energy enerjiyi, Science bilimi destekler.
- Başka türden katkı almak skill/özel yapı ile açılır.
- Yakın nesne sayısında sert sınır yoktur.

**Capital istisnası:** S25 cevabına göre kendi City'sindeki doğrudan yol bağlantılı districtlere merkez bonusu verir; aradaki district üzerinden bütün ağa yayılmaz. S26'daki geometrik kural normal districtler içindir. Cevaplanmış yol istisnası tekrar onaya sunulmuyor.

Yol kesişimi ve yol kalınlığı hiçbir ekonomik bonus üretmez.

### Sınırsız sayım, yumuşayan katkı

Çok yakın ilk uygun kaynak +%20, yakın ilk uygun kaynak +%10 katkı verir. Sonraki kaynakların katkısı en yakından başlayarak her sırada yarıya iner. Her uygun kaynak hesaplanır; ilk birkaç kaynaktan sonra artış küçülür.

| Hepsi çok yakın uygun kaynak sayısı | Toplam yakınlık katkısı |
| ---: | ---: |
| 1 | +%20 |
| 2 | +%30 |
| 3 | +%35 |
| 4 | +%37,5 |
| 8 | Yaklaşık +%39,84 |

Bu bir “en fazla dört komşu sayılır” kuralı değildir. Her kaynak katkı verir, toplam %40'a yaklaşır. Böylece yüzlerce yakın nesnenin sayılması üretimi yüzlerce kat artırmaz.

Capital'ın başlangıç merkez katkısı ayrıca **+%10** hesap taslağıdır. Uzaklık, en yakın diğer normal yüzey yerleşimine göre hesaplanır. Çok yakın bir kümenin içindeki district aynı anda çok uzak sayılamaz.

### S27'nin açıklaması: uzmanlık bir seçim kilidi değildir

Yakınlık ve uzaklık başlangıçtan çalışır. “Uzmanlık”, bunları güçlendiren skill ve yapı yatırımı demektir; zorunlu karakter sınıfı veya sınırlı skill yuvası değildir.

“Aynı districtte ikisi çalışsın mı?” sorusu, aynı yerleşimin koşulları izin veriyorsa birden fazla konum katkısı almasını soruyordu. Yeni modelde yasaklayıcı bir tercih düğmesi yok. Etkiyi gerçek mesafe belirler. Skill'in olması tek başına çok yakın bir districti çok uzak saydırmaz.

Yakınlık/uzaklık/merkez etkileri hem districtin tabanını hem içindeki uygun binaları etkiler. Tip 0 binası bunu districtinden alır; kendi bina konumu yoktur.

### İki stratejinin başlangıç kıyası

| Düzen | Konum katkısı, diğer etkiler yok |
| --- | ---: |
| 3 çok yakın aynı tür + merkez | %35 + %10 = +%45 |
| 4 çok yakın aynı tür + merkez | %37,5 + %10 = +%47,5 |
| Çok uzak bağımsız yerleşim, merkez bağlantısız | +%35 |
| Çok uzak bağımsız yerleşim, doğrudan merkez bağlantılı | %35 + %10 = +%45 |

Yakın düzen az alana sığar ve çapraz tür skill'leri için uygun ağ kurar. Uzak düzen daha çok alan ve uygun coğrafya arama imkânı kullanır. Uzak districtin de Capital'a doğrudan bağlanabileceği hesapta unutulmaz. Üç çok yakın kaynak ile tek uzak kuruluş aynı +%45 örneğine ulaşır; daha büyük küme biraz üstünleşebilir, fakat daha fazla kuruluş yatırımı ister. Her haritada eşit sonuç garantisi verilmez.

## 9. Ortak büyüme matematiği

Bu bölümdeki sayılar hesap taslağıdır. Aynı amaç için ikinci bir gizli büyüme formülü kullanılmayacak.

### 9.1. Bina tier'ı

Standart üretici ailelerinde her üst tier için **taban kredi, çalışan, tarif miktarı ve çıktı ×3**.

| Tier | Çarpan | Standart çalışan | 150 kredi ailesi |
| --- | ---: | ---: | ---: |
| 1 | ×1 | 250 | 150 |
| 2 | ×3 | 750 | 450 |
| 3 | ×9 | 2.250 | 1.350 |
| 4 | ×27 | 6.750 | 4.050 |

Üst tier aynı yuvaya üç kat iş sığdırır; ancak büyük tek ödeme, iş gücü ve işlenmiş bakım ister. Alt tier küçük yatırımlarla ilerlemeyi sağlar. Konut çalışanı 0, saf depo/destek yapıları ise kendi açık profiline sahiptir.

Tier 4 başlangıçta açık olmayacak. İlk demo sayılandırması Tier 1-3 üzerinden yapılır; Tier 4 Tip 1 oynanışına bırakılır.

### 9.2. District seviyesi

Her district seviyesinde kendi tabanı ve içindeki ilgili üreticilerin çıktısı **×1,25** olur. Bina seviyelendirmesi yoktur; binanın ebeveyn districtinin seviyesi vardır.

| District seviyesi | Üretim çarpanı | Normal bina yuvası | Capital yuvası |
| ---: | ---: | ---: | ---: |
| 1 | ×1 | 3 | 1 |
| 2 | ×1,25 | 5 | 2 |
| 3 | ×1,5625 | 7 | 3 |
| 4 | Yaklaşık ×1,953 | 9 | 4 |
| 5 | Yaklaşık ×2,441 | 11 | 5 |
| 10 | Yaklaşık ×7,451 | 21 | 10 |

Maksimum 10. Bir yükseltmenin kredi tabanı 250; sonraki yükseltmelerde ×1,25. Ek nüfus yükü tabanı 500 ve aynı ×1,25. Residential yükseltmeleri nüfus yükü kullanmaz. Eski her adımda ikiye katlanan district nüfus yükü kaldırılır.

| Geçiş | Kredi, yaklaşık | Ek nüfus yükü, yaklaşık | Süre |
| --- | ---: | ---: | ---: |
| 1 -> 2 | 250 | 500 | 10 sn |
| 2 -> 3 | 313 | 625 | 15 sn |
| 3 -> 4 | 391 | 781 | 20 sn |
| 4 -> 5 | 488 | 977 | 25 sn |
| 5 -> 6 | 610 | 1.221 | 30 sn |

Eski “önce hedef seviyeye ulaşmış yol komşusu bul” sert yükseltme kapısı kaldırılır. Yakınlık bir üretim tercihi olur; uzak yerleşimin seviye almasını engellemez.

### 9.3. City ve gezegen

City kapasitesi 3, 5, 7... çocuk district; gezegen kapasitesi 2, 3, 4... City olarak devam eder. Fiziksel yer ve gövde boyutu ayrıca sınır getirir.

| City hedefi | Gereken toplam district seviyesi | Kredi | Ek nüfus yükü | Süre |
| --- | ---: | ---: | ---: | ---: |
| Lv2 | 3 | 1.000 | 2.000 | 20 sn |
| Lv3 | 6 | 1.500 | 2.500 | 30 sn |
| Lv4 | 10 | 2.250 | 3.125 | 40 sn |
| Lv5 | 15 | 3.375 | 3.906 | 50 sn |

İnşaatı bitmemiş district seviye şartına katkı vermez. City seviyesi, Capital district seviyesinin yerine geçmez.

| Gezegen hedefi | City seviyeleri toplamı | İsimli bedel | Süre |
| --- | ---: | --- | ---: |
| Lv2 | 3 | 2.000 kredi + 100 Ferrite | 10 sn |
| Lv3 | 5 | 3.000 kredi + 150 Ferrite + 10 Goods | 15 sn |
| Lv4 | 7 | 4.500 kredi + 225 Ferrite + 20 Goods | 20 sn |
| Lv5 | 9 | 6.750 kredi + 300 Ferrite + 50 Moonstone + 10 Fuel + 5 Rare | 25 sn |

Lv5 Ay erişiminden sonra bir seçenektir; ilk Ay seferinin ön koşulu değildir. Fuel ve Rare **bu gezegen seviyelerine bağlanmaz**. Kullanıcının Lv2-3 / Lv4 tarifi yalnız beklenen tempo için referanstır.

### Kuruluşta nüfus ve ilk seviye maliyeti

| Yeni yerleşim | İlk kredi | İlk nüfus yükü | Açıklama |
| --- | ---: | ---: | --- |
| City | İlk City 0, sonrası Bölüm 11 | 2.000 | Otomatik Capital'ın kuruluş yükü dahil; ikinci kez sayılmaz. |
| Capital | City içinde otomatik | 0 ek | İlk yuva 1; Spaceport için Lv2 gerekir. |
| Production / Science / Energy / Commercial | Tür başına 300 | 500 | Aynı tür tekrarında kredi ×1,50; nüfus kuruluşta 500 kalır. |
| Residential | Tür başına 300 | 0 | Konut açmak için kendisi yeni çalışan zorunluluğu getirmez. |

Normal City kapasitesi Capital dışındaki çocuk districtleri sayar. Ana dünyadaki normal district kuruluşları yalnız kredi ister; Ay Production'ı Bölüm 15'teki 30 Ferrite istisnasını kullanır. Böylece gizli eski 3.000/4.500 vb. kuruluş yükleri yeni sayıların üzerine eklenmez.

### 9.4. Bir stok çıktısının hesabı

```text
Tier 1 aile tabanı × tier çarpanı × adet × district seviyesi çarpanı
× (1 + ilgili coğrafya toplamı)
× (1 + yakınlık + uzaklık + merkez)
× (1 + ilgili araştırmalar)
```

Ham tüketen işleme tarifinde sonuca seçilmiş hammaddenin nadirlik verimi de uygulanır. Aynı kaynağın araştırma bonusları kendi grubunda toplanır.

**Tek hesap noktası:** Bölüm 13'ün tabloları tier'ı zaten içeren tek bina tabanını gösterir. Örneğin Institute'un 18 Science'ı kullanılıyorsa tekrar ×3 yapılmaz. Uygulamada ya Tier 1 aile tabanından hesaplanmış değer ya da önceden hesaplanmış bina değeri kullanılır; ikisi birden kullanılmaz.

Enerji ve konut stok turu değildir. Çalışan ihtiyacı, recipe girdisi ve bakım bedelleri bu çıktı bonuslarıyla otomatik artmaz. Nüfus özel gelirleri zaten son konut kapasitesinden hesaplandığı için coğrafyayı ikinci kez almaz.

## 10. İlk ekonomi ve işleme tarifleri

### Başlangıç hesabı

| Alan | V2 hesap taslağı |
| --- | --- |
| Başlangıç kredi | 3.000 |
| Başlangıç Science | 450; ilk strateji düğümlerini seçme bütçesi. |
| Malzeme stoku | 0 |
| İlk City | Kuruluş ücretsiz; Capital otomatik. |
| City tabanı | Dakikada 60 kredi, 4 Science, 15.000 konut ve 8 enerji. |
| Başlangıçta açık aileler | Temel enerji, konut, bilim, ticaret ve Production kuruluşu. |
| Tutorial yeniden tasarımı | Bu başlangıç değerlerinin ön koşulu değil; askıda. |

İlk Production District kuruluşu krediyle yapılır; kendi henüz açılmamış Ferrite'ini istemez. Kaynak görünürlüğü tamamlanmış uygun yerleşimle açılır.

Bu başlangıç bütçesi de yeni hesap taslağıdır. Örneğin 450 Science, Ticaret Erişimi + Sivil Girişimler + Serbest Araştırma'yı açabilir. Böylece nüfus yolunu seçen oyuncu ilk gelirini başlatmak için önce lab kurmak zorunda kalmaz. Başka bir oyuncu aynı bütçeyi bilim veya enerji dallarına dağıtabilir; başlangıç Science bütçesi bitince normal Science üretimiyle devam eder. İlk oyunda bu dağılım otomatik satın alınmaz.

### Temel district getirileri

| District | Kendi tabanı |
| --- | --- |
| Production | 10 ham / 20 sn, seçilen erişilebilir çıkarım türüne. |
| Science | 3 Science / 30 sn. |
| Commercial | 10 kredi / 20 sn. |
| Residential | 1.500 konut kapasitesi. |
| Energy | 3 enerji akışı. |

Bu tabanlar district seviyesi ve uygun konum etkileriyle büyür. Ham kaynak seçimi yalnız o gövdede erişilmiş türleri sunar. Görünmeyen bir kaynağı açılır listeye eklemez.

### Kabul edilen tariflerin tamamlanmış süreleri

| Temel tarif | Süre | Ferrite ile çıktı | Moonstone ile çıktı |
| --- | ---: | ---: | ---: |
| 4 seçilmiş ham -> Goods | 20 sn | 2 | 3,5 |
| 8 seçilmiş ham -> Fuel | 20 sn | 2 | 3,5 |
| 12 seçilmiş ham -> Rare | 20 sn | 1 | 1,75 |

Fuel aynı mineral kullanıldığında Goods'ın iki katı ham ister. Rare daha yoğun tarif kalır. Tier 2/3 tarif miktarları aynı oranda ×3/×9 büyür; bu, dönüşüm oranını gizlice değiştirmez.

### Üretim girdisi ile bakım farklıdır

- Tarif girdisi tur başında alınır, çıktı sonunda verilir.
- Sürekli enerji/konut hizmeti veren binanın Goods/Fuel bakımı ayrı ekonomi saatine bağlıdır.
- Örneğin 60 ekonomi saniyesinde 1 Fuel isteyen reaktör, üretim yavaşladı diye aynı enerjiyi yarı Fuel ile vermez.
- Saf kapasite/pasif bonus nesnesinde sahte üretim turu yoktur. Gerçek bakım varsa bakım aralığı gösterilir.

Bakım dönemi başında gereken stok ayrılır. Ödenemeyen bakım o dönemde ilgili kapasite/enerji/bonusu kapatır; önce bakım ve çalışan/enerji durumu, sonra üretim hesaplanır. Aynı dönem içinde üretilecek ürünü bakım ödenmiş gibi önceden kullanmaz. Temel bakımsız binalar ve manuel trade, yeniden başlatma yolu olarak kalır. Aynı stok iki binanın bakımına birden ayrılmaz.

İnşaatlar genel olarak 4 saniye; küçük seçenekler 2, özel tesisler kendi açık sürelerini kullanır. Üretim döngüsü olmayan binada da inşaat süresi olabilir.

## 11. Tekrar fiyatı ve isimli kuruluş bedelleri

### Tekrar artışı

| Nesne | Sayılan tekrarlar | Artış |
| --- | --- | ---: |
| Bina | Aynı districtte aynı bina türünün mevcut adetleri | Her tekrarda ×1,20 |
| District | Aynı City'de aynı district türünün mevcut adetleri | Her tekrarda ×1,50 |
| Tip 0 City | Aynı gezegendeki normal City sayısı | İlk ücretsiz, sonraki taban 2.000 ve ×1,50 |
| Üst tipte tür kazanmış yerleşim | Aynı ebeveynde aynı işlevsel tür | Aynı tür tekrar kuralı. |

İnşaatta olan adetler sayılır. Yıkılan adet sayacı azaltır. Aynı binanın farklı girdi grupları tek bina türü sayacını paylaşır. Özel plan adı veya oyuncu ismi yeni fiyat türü oluşturmaz.

| Örnek | İlk beş bedel |
| --- | --- |
| 150 tabanlı aynı bina | 150, 180, 216, 259, 311 kredi |
| 300 tabanlı aynı district türü | 300, 450, 675, 1.013, 1.519 kredi |
| İlkinden sonraki City'ler | 2.000, 3.000, 4.500, 6.750, 10.125 kredi |

Farklı tür kurmak diğer türün fiyatını artırmaz. Tekrar artışı krediye uygulanır; tarifte açıkça yazan malzeme bedeli aynı adet için değişmez. Böylece uzun malzeme listelerinde ikinci bir görünmez fiyat eğrisi oluşmaz.

### Standart üretici kuruluş malzemesi

| Tier | Kredi dışında ek bedel |
| --- | --- |
| 1 | Yok; ilk üretici zinciri başlatabilir. |
| 2 | 30 Ferrite + 5 Goods. |
| 3 | 90 Ferrite + 15 Goods + 5 Fuel + 2 Rare. |
| 4 | Tip 1 kataloğunda açık kaynak adlarıyla ayrıca belirlenecek; demoda kurulamaz. |

Ay'a özel binalar ve roket yapıları kendi isimli tarifini kullanır. Bunlar standart ek bedelle ikinci kez ücretlendirilmez. Uygun üretim erişimi olmadan yeni malzeme maliyet satırı oyuncuya gösterilmez.

## 12. %50-%75 iade, her adedi ayrı saklamadan

**Karar:** Temel kredi iadesi %50; skill ile üst sınır %75. Esas gerçek ödenmiş kredidir, güncel katalog fiyatı değildir.

Hesap taslağı: Her aynı üretim grubunda yalnız **adet N** ve **kalan toplam gerçek ödeme C** saklanır.

```text
Bir adedin maliyet payı = C / N
İade = maliyet payı × iade oranı
Kalan C = eski C - maliyet payı
Kalan N = eski N - 1
```

Örnek: 150 + 300 + 600 ödenmiş üç adette C=1.050, N=3. Ortalama pay 350. %50 iade 175; %75 iade 262,5. Bir adet kalkınca kalan C=700, N=2.

Bu yöntem belirli tarihsel adedin bedelini sakladığını iddia etmez; eşdeğer adetlerin **gerçek ödemelerinin ortalamasını** kullanır. İndirim/fiyat değişikliği geçmiş C'yi yeniden değerlemez. Birleştirme C ve N toplamlarını toplar; grubu bölme C'yi adet oranında ayırır.

İç hesapta küçük para birimi ve aşağı yuvarlama kullanılır; son adet kalan maliyet payını alır. %75 üst sınırla iade, gerçek toplam ödemenin %75'ini aşmaz.

Bu taslakta malzeme bedeli yıkımda geri verilmez; kredi iade edilir. İnşaat iptali de aynı kredi oranını kullanır. Hiç ödenmemiş otomatik merkez kendi başına iade üretmez. Kurulmadan vazgeçilen, henüz ücret alınmamış plan sıfır işlem olarak kapanır.

## 13. Bina kataloğunun yeni düzeni

**Bu bölümün bütün sayıları hesap taslağıdır.** Mevcut katalog değerleriyle yeni hedefler karıştırılmamalı. Eski 42 tanımın ve önerilmiş 16 binanın her biri aşağıda bir yere bağlandı. Genel filo sistemine hizmet eden eski işlevler korunacak zorunlu kapılar değildir.

### Kartların ortak dili

- Her bina yalnız kendi district ailesine kurulur; Capital destekleri Capital'a gider.
- Aksi belirtilmedikçe her bina ve destek 1 yuva kullanır; iki Spaceport modeli 2 yuva kullanır.
- Bina level'ı yok. Aynı binadan adet alınır; ileri bir model ayrı bina türüdür.
- Tablodaki kredi ilk adet içindir. İlgili tier'ın isimli kuruluş malzemeleri Bölüm 11'den eklenir; özel Ay tarifleri bunların yerine geçer.
- Standart çalışan: Tier 1 = 250, Tier 2 = 750, Tier 3 = 2.250. Konut binaları çalışan istemez. Küçük model yarım ölçek, büyük model açıkça belirtilmiş farklı ölçektir.
- Üretim, çalışan ve temel kredi birlikte ×3 büyür. Böylece tier atlamak çalışan başına ücretsiz servet oluşturmaz; asıl kazanç yuva başına yoğunluktur. İleri bakım bunun bedelidir.
- Kredi/Science/ham/işlenmiş çıktılar belirtilen turda; enerji sürekli akış, konut sürekli kapasitedir. Depoda veya pasif bonusta üretim turu yazılmaz.
- Bina kendi konumunu ölçmez. “Kıyı”, “dağ”, “rüzgârlı” gibi gereksinimler districtin bulunduğu yere bakar. Tam coğrafi özellik üzerine kurulu district özel binayı açar; yalnız yakında olmak genel yarım bonus verir.
- Coğrafya, seviye, yakınlık ve araştırma çarpanları aşağıdaki tabana sonradan, Bölüm 9'daki sırayla uygulanır. Tarif girdisi de aynı çarpanlarla büyütülmez.

### Energy District

| Bina / mevcut kimlik | Tier | Kredi | Enerji tabanı | Bakım | Çalışan | Tercih nedeni / karşılığı |
| --- | ---: | ---: | ---: | --- | ---: | --- |
| Solar Array / `solar_panel` | 1 | 150 | 3 | Yok | 250 | Her yerde kurulabilen temel seçenek; özel alanın gücünü tek başına geçmez. |
| Wind Turbine / `wind_turbine` | 1 | 200 | 4 | Yok | 250 | Görünen rüzgârlı alan ister; bir yuvada daha yüksek çıktı, daha büyük ilk yatırım. |
| Tidal Generator / `tidal_generator` | 2 | 600 | 12 | 1 Goods / 60 sn | 750 | Deniz kıyısı ister; genel Tier 2 soların üzerinde çıktı, alan ve bakım bedeli. Göl yeterli değil. |
| Geothermal Plant / `geothermal_plant` | 2 | 750 | 15 | 1 Goods / 60 sn | 750 | Volkanik alan veya görünen jeotermal yarık ister; güçlü ama pahalı. |
| Solar Matrix / `solar_matrix` | 2 | 450 | 9 | 1 Goods / 60 sn | 750 | Özel arazi zorunluluğu yok; düşük yatırım, üç panel kadar yuva tasarrufu. |
| Fusion Reactor / `fusion_reactor` | 3 | 1.350 | 27 | 1 Fuel / 60 sn | 2.250 | Arazi bağımsız yoğun enerji; Fuel sürekliliği ister. |
| Antimatter Plant / `antimatter_chamber` | 4 | Tip 1 kataloğu | Demoda yok | Tip 1 planında | Tip 1 planında | Başlangıçta veya yalnız gezegen Lv4 olduğu için açılmaz. |
| **Yeni: Sığ Jeotermal Kuyu** | 1 | 250 | 5 | Yok | 250 | Aynı sıcak saha şartı; daha ucuz ve bakımsız başlangıç, düşük yuva yoğunluğu. |
| **Yeni: Sırt Türbini** | 2 | 900 | 18 | 1 Goods / 60 sn | 750 | Hem görünen sırt hem rüzgârlı alan ister; en seçici konum karşılığında güçlü yuva çıktısı. |

Wind artık solarla aynı çıktıyı daha pahalı vermez. Aynı districtte Wind'in 4 enerjisi rüzgârlı alan bonusunu, Solar'ın 3 enerjisi solarla ilgili bonusları alır. Örneğin yalnız +%30 rüzgâr koşulunda Wind 5,2, Solar 3 taban enerji verir. Diğer ortak etkiler ikisine de ayrıca uygulanır.

### Production District: çıkarım ve işleme

| Bina / mevcut kimlik | Tier | Kredi | Tur | Girdi -> taban çıktı | Enerji | Çalışan | Rol |
| --- | ---: | ---: | ---: | --- | ---: | ---: | --- |
| Mine / `mine` | 1 | 200 | 20 sn | Yok -> 10 ham | 1 | 250 | Genel çıkarım; o yerde açılmış hammaddenin seçimi. |
| Rich Vein Excavator / `rich_vein_excavator` | 2 | 800 | 20 sn | Yok -> 40 ham | 3 | 750 | Görünen maden yatağı üzerinde yüksek yoğunluk. |
| Deep Drill / `deep_drill` | 2 | 600 | 20 sn | Yok -> 30 ham | 3 | 750 | Özel yatak gerektirmeyen kompakt çıkarım. |
| Mantle Cracker / `mantle_cracker` | 3 | 1.800 | 20 sn | Yok -> 90 ham | 9 | 2.250 | 1 Fuel / 60 sn bakım; yoğun geç sanayi. |
| Goods Factory / `refinery` | 1 | 300 | 20 sn | 4 ham -> 2 Goods | 2 | 250 | En baştan açık temel işleme, bootstrap yolu. |
| Fuel Refinery / `plasma_smelter` | 2 | 1.350 | 20 sn | 24 ham -> 6 Fuel | 6 | 750 | Aynı 8:2 tarifin ×3 modeli; 1 Goods / 60 sn bakım. |
| Rare Element Forge / `molecular_forge` | 1 | 600 | 20 sn | 12 ham -> 1 Rare | 3 | 250 | Erken araştırmayla açılır; Rare'ın ilk erişimi için üst tier bina zorunlu olmaz. |
| **Yeni: Yüzey Ocağı** | 1 küçük | 100 | 20 sn | Yok -> 5 ham | 0,5 | 125 | Az kredi/çalışanla başlama; Mine'ın yarı yuva verimi. |
| **Yeni: Cevher Ayıklama Atölyesi** | 2 | 900 | 20 sn | 12 ham -> 6 Goods | 6 | 750 | Üç temel fabrikanın çıktısı tek yuvada; 1 Goods / 60 sn bakım. |
| **Yeni: Kompakt Yakıt Atölyesi** | 1 | 450 | 20 sn | 8 ham -> 2 Fuel | 2 | 250 | Fuel'ın erken ve düşük çalışanlı başlangıcı. |
| **Yeni: Regolit İşleme Tesisi** | 2 özel | 900 | 20 sn | 12 Moonstone -> 6 taban Goods; verimle 10,5 | 6 | 750 | Moonstone'a sabitlenmiş yerel büyük üretim; 1 Goods / 60 sn bakım. |

Regolit Tesisi ayrı bir gizli dönüşüm bonusu yaratmaz: 6 temel Goods × Moonstone'un 1,75 verimi = 10,5. Aynı Moonstone'u seçmiş Cevher Atölyesi aynı dönüşümü yapar. **Ay Malzemeleri araştırması tesisi açar; Cevher Ayıklama araştırmasını seçmemiş oyuncuya Ay'da alternatif açılış sağlar.** İkisini de açmış oyuncuya zorunlu ikinci fabrika değildir. Regolit kuruluş tarifi: 100 Moonstone + 20 Goods + 900 kredi; ayrıca standart Tier 2 malzemesi alınmaz.

Bu iki bina aynı işi tamamen aynı bedelle yapıyorsa ayrı kalıcı tür saymak gereksizdir. Uygulamada Regolit, aynı büyük Goods üreticisinin **Ay planı/yerel görünümü** olarak birleştirilir; tekrar fiyatını ve üretim kimliğini aynı aileyle paylaşır. Böylece iki etiket açıp tekrar fiyatından kaçılmaz. Bina çeşitliliği sayısını artırmak için kopya ekonomi tutulmaz.

Tier 2 Goods üreticisinin kendi Goods bakımını başlatacak ilk stok, temel fabrikadan veya trade'den gelir. Sıfır stokta tamamen kilitlenmez: temel fabrika ve küçük modeller açık kalır. Bakım için ayrılan stok kartta görünür.

### Depolar

| Bina | Yer | Kredi | Kapasite katkısı | Enerji / çalışan | Ayrı rol |
| --- | --- | ---: | --- | --- | --- |
| Warehouse / `warehouse` | Production | 300 | Açılmış her ham türüne +1.000; Goods +150; Fuel +150; Rare +75 | 1 / 250 | Genel malzeme rezervi; bir adet Ay roketinin Moonstone bedelini biriktirmeye yeter. |
| **Yeni: Yakıt Deposu** | Production | 150 | Fuel +300 | 0,5 / 125 | Tek ürüne daha ucuz kapasite, ham/Goods/Rare eklemez. |
| **Yeni: Yörünge Yakıt Tankı** | Yörünge lojistik districti | 600 | Fuel +1.200 | 2 / 750 | Daha az yuvada büyük rezerv; yörünge kurulumu bedeli nedeniyle erken depoyu gereksizleştirmez. |

Taban kapasiteler: ham türü başına 500, Goods 200, Fuel 200, Rare 100. Kredi ve Science için üretim durduran depo tavanı konmaz. Kapasite bonusu kilitli hammaddeyi görünür yapmaz; açıldığında geçerli olur. Depolar pasif kapasitedir, 30 saniyede depo üretmez.

### Science District

| Bina / kimlik | Tier | Kredi | Science / 30 sn | Enerji | Çalışan | Bakım / tercih |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Research Lab / `lab` | 1 | 150 | 6 | 1 | 250 | Genel ilk araştırma. Eski 2/30 tabanı yeni ağaç için 6/30 olur. |
| Mountain Observatory / `mountain_observatory` | 2 | 600 | 24 | 3 | 750 | Dağ üzerinde; 1 Goods / 60 sn. Genel enstitüye göre daha yoğun, daha pahalı. |
| Research Institute / `advanced_lab` | 2 | 450 | 18 | 3 | 750 | Her yerde; 1 Goods / 60 sn. |
| Particle Accelerator / `particle_accelerator` | 3 | 1.350 | 54 | 9 | 2.250 | 1 Rare / 60 sn. Rare araştırması ister; eski gezegen Lv3 kapısı yerine bilim yolu. |
| Quantum Lab / `quantum_computer` | 4 | Tip 1 kataloğu | Demoda yok | Tip 1 | Tip 1 | Başlangıç açık işareti kaldırılacak. |
| **Yeni: Saha Gözlem Evi** | 1 küçük | 75 | 3 | 0,5 | 125 | Dağ veya yüksek düzlük üzerinde küçük bütçe; yarı yuva verimi. |
| **Yeni: Ay Numune Laboratuvarı** | 2 özel | 750 | 30 | 4 | 750 | Yalnız Ay; 1 Rare / 60 sn. Yoğun Science karşılığında işlenmiş bakım. |

Ay Numune Laboratuvarı kuruluşu 75 Moonstone + 10 Goods + 5 Rare + 750 kredi; standart malzeme listesi ayrıca eklenmez. Nadir elemente erişimden önce bu bina açılmaz.

### Residential District

| Bina / kimlik | Tier | Kredi | Konut | Enerji | Bakım | Rol |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| Habitat Block / `residential` | 1 | 120 | 2.500 | 1 | Yok | Temel kapasite. |
| Seaside Villas / `seaside_villas` | 2 | 360 | 6.000 | 1 | 1 Goods / 60 sn | Kıyı; az enerjiyle konut, daha düşük yuva yoğunluğu. |
| Apartment Towers / `apartments` | 2 | 360 | 7.500 | 2 | 1 Goods / 60 sn | Genel, daha yoğun ama iki kat enerji. |
| Luxury Spires / `luxury_complex` | 3 | 1.080 | 22.500 | 6 | 2 Goods + 1 Fuel / 60 sn | Yuva yoğunluğu için tüketim. |
| Arcology / `arcology` | 4 | Tip 1 kataloğu | Demoda yok | Tip 1 | Tip 1 | Başlangıç açık hatası giderilir. |
| **Yeni: Düşük Katlı Konut** | 1 küçük | 60 | 1.250 | 0,5 | Yok | İlk küçük boşluğu doldurur; aynı kapasite için daha fazla yuva. |
| **Yeni: Kıyı Apartmanları** | 2 özel | 432 | 9.000 | 3 | 1 Goods / 60 sn | Kıyıda genel apartmandan %20 yoğun, %50 fazla enerji. |
| **Yeni: Modüler Ay Habitatı** | 2 özel | 480 | 10.000 | 3 | 2 Goods / 60 sn | Ay'da güçlü kapasite, daha fazla Goods bakımı. |

Bütün konutlarda çalışan yükü 0. Ay Habitatı kuruluşu 50 Moonstone + 10 Goods + 480 kredi. Sürekli büyüyen nüfus simülasyonu eklenmez. Konut stratejisinin geliri Bölüm 6'daki skill etkileriyle oluşur.

### Commercial District

| Bina / kimlik | Tier | Kredi bedeli | Kredi / 20 sn | Enerji / çalışan | Tüketim ve rol |
| --- | ---: | ---: | ---: | --- | --- |
| Market / `commercial` | 1 | 150 | 20 | 1 / 250 | Girdisiz temel kredi. |
| Bazaar / `bazaar` | 1 büyük | 300 | 52 | 2 / 500 | 1 Goods / 20 sn. Tek yuvada yoğun gelir, Goods fırsat maliyeti. |
| Harbor Market / `harbor_market` | 2 | 600 | 80 | 3 / 750 | Deniz kıyısı; 1 Goods / 60 sn. |
| Trade Hub / `trading_post` | 2 | 450 | 60 | 3 / 750 | Genel; 1 Goods / 60 sn. |
| Commodity Exchange / `commodities_exchange` | 3 özel | 1.800 | 270 | 9 / 2.250 | 3 Goods / 20 sn + 1 Fuel / 60 sn. Güçlü yuva çıktısı, güçlü işlenmiş tüketimi. |
| Interstellar Bank / `central_bank` | 4 | Tip 1 kataloğu | Demoda yok | Tip 1 | Başlangıçtan kapalı; üst medeniyet için tutulur. |
| **Yeni: Yerel Ticaret Merkezi** | 1 büyük | 225 | 30 | 2 / 375 | Market'tan %50 yoğun; enerji başına daha zayıf. |
| **Yeni: Ay İkmal Pazarı** | 2 özel | 900 | 120 | 4 / 750 | Ay; 1 Goods / 20 sn + 1 Fuel / 60 sn. İşlenmiş fazlayı gelire çeviren yoğun seçenek. |

Ay İkmal Pazarı kuruluşu 75 Moonstone + 20 Goods + 10 Fuel + 900 kredi. Bu binalar trade arayüzünün yerine geçmez; kendi tüketimleriyle çalışan kredi üreticileridir. Kartta brüt kredi yanında bakım ve net malzeme değişimi gösterilir.

### Capital destekleri

Destek etkileri Capital'ın doğrudan bağlı hedefleri üzerinden dağıtılır; gizli biçimde bütün City/gezegene ikinci kez yayılmaz. Aynı destekten Capital başına bir adet kurulabilir. Bu tekillik kredi tekrarından kaçış değil, sınırsız destek çarpanı yığılmasını engelleyen bina özelliğidir.

| Bina / kimlik | Tier | Kredi | Etki | Enerji / çalışan | Açılış |
| --- | ---: | ---: | --- | --- | --- |
| Financial District / `financial_district` | 2 | 600 | Bağlı Commercial kredi çıktısına +%10 | 2 / 750 | Kamu Yönetimi + Ticaret. |
| Research Directorate / `research_academy` | 2 | 600 | Bağlı Science çıktısına +%10 | 2 / 750 | Kamu Yönetimi + Bilim. |
| Housing Authority / `cryo_vault` | 2 | 600 | Bağlı Residential konutuna +%10 | 2 / 750 | Kamu Yönetimi + Nüfus. |
| Logistics Center / `logistics_center` | 2 | 1.200 | Bağlı Production ham/işlenmiş çıktısına +%10; Warehouse kadar depo | 2 / 750 | Lojistik. |
| Planetary Command / `command_center` | 3 | 1.800 | Bağlı Energy çıktısına +%10 | 3 / 2.250 | İleri Koordinasyon. |
| Spaceport / `spaceport` | 1 özel | 500 | Ana dünya-Ay seferinin fiziksel hazırlık noktası; 2 yuva | 0 / 250 | Rocketry. |
| **Yeni: İnşaat Dairesi** | 2 | 600 | Bağlı districtte bina inşaat süresi -%10 | 1 / 750 | İnşaat Organizasyonu. |

Destekler düşük gelirli City'de her zaman doğru ilk yatırım değildir. Çok sayıda gelişmiş üretici çalıştıran düzenlerde bir yuva karşılığında ölçeklenir. Bunları zorunlu demo kapısı yapmak yerine seçilebilir tutuyoruz. Üretim desteklerinin +%10'u aynı çıktıdaki diğer araştırma/destek yüzdelerine eklenir; kendi başına yeni bir çarpım katmanı açmaz.

### Orbit'in City rolü ve eski 5 modül

**Karar:** Orbit bir City rolünde ele alınacak; içinde district düzeyinde yapılar olacak. Eski Space Station'ı tek bir bina deposu gibi aynen sürdürmek yeni ölçekle uyumlu değil. Tip 1'deki otomatik Orbital City de bu mimariyi kullanacak. Tip 0'ın normal City'lerine üretim türü verilmez; yörüngede oluşu bir konum rolüdür.

Bu sürümde Ay'a varmak için Orbit, Orbital Shipyard veya genel gemi altyapısı zorunlu değil. Yörünge içerikleri ana demo yolunu bekleten ek araştırma zinciri olmayacak.

| Eski tanım | Yeni rol | Bu güncellemedeki işlem |
| --- | --- | --- |
| `zero_g_nexus` | Orbital Science District içinde araştırma planı | Science ailesinin aynı tier matematiğine taşınacak. |
| `orbital_mirrors` | Orbital Energy District destek planı | Pasif enerji desteği; sahte üretim turu kaldırılacak. |
| `orbital_offworld_market` | Orbital Commercial District ticaret planı | Commercial ailesinin aynı tier matematiğine taşınacak. |
| `orbital_shipyard` | Orbital Spaceport / sefer hazırlık districti | Eski kredi üretimi ve zorunlu Lunar Program kapısı kaldırılacak; filo üretmeyecek. |
| `orbital_logistics` | Orbital Logistics District | Depo/üretim desteği; tekillik ve kapsam açık olacak. |

Yörünge haritasının elle düzenleme biçimi, districtleri ve toplam kuruluş paketi ayrı bir alt tasarımdır. **Demo için bu ayrıntı zorunlu bağımlılık yapılmaz.** Mevcut 5 tanımın unutulması yerine dönüşüm hedefleri burada kayıtlıdır; Tip 1 oynanışına ait bütün sayılar bu demo belgesinde tamamlanmış sayılmaz.

## 14. Skill ağacı: açık yollar, yumuşak tercih maliyeti

### Ortak kurallar

**Kararlar:** Satın alma birimi Science. Seçim/adet sınırı yok. Birleşen yollarda ebeveynlerden herhangi birini bitirmek yeterli. Alınmış etkiler medeniyet geçişinde çalışmayı sürdürür. Yakınlık, uzaklık ve coğrafya etkilerinin temel halleri başlangıçtan açık; skill bunların varlığını satın aldırmaz.

Özel bina kapıları ise skill olabilir. Kapı satın alınmadan bina kurulmaz; yanlış başlangıç `unlocked` işareti bunu aşamaz. Tier 4 binaları gezegen Lv4'e ulaşmak otomatik açmaz.

**Hesap taslağı:** Her strateji düğümünün bir ana dalı var. Başka dallardan alınmış farklı düğümler bu dalın bedelini yavaşça artırır:

```text
Güncel Science = taban Science × (1 + 0,02 × diğer dallarda alınmış farklı düğüm sayısı)
Tekrarlı bonusun seviye bedelleri = taban × 1, taban × 2, taban × 3
```

Başka dallarda 5 farklı düğüm = +%10; 10 düğüm = +%20. Aynı düğümün ikinci/üçüncü seviyesi bu sayaca yeni düğüm eklemez. Çok etiketli bir skill tek ana dala sayılır. Ortak ilerleme düğümleri bu fiyat etkisinin dışında: hiçbir dala yazılmaz, zam almaz veya başka dalları zamlandırmaz. Böylece Ay'a gidiş, oyuncunun önceden başka stratejiler denemesinden ötürü gizlice aşırı pahalılaşmaz.

İleri araştırmalar pahalılaşırken düşük bedelli alternatifler kalır. Sadece fiyat artışıyla sonsuza kadar kalıcı uzmanlık sağlandığı iddia edilmiyor; zamanla bütün dalların açılması mümkündür. Ağaç üzerindeki satın alma yolu ve yerleşimler yine oyuncunun ara dönemdeki stratejisini belirler.

### Strateji dalları

| Dal | İlk tercihler | Birleşebileceği dal / amaç |
| --- | --- | --- |
| Production ve işleme | Küçük üretici, yoğun üretici, Goods/Fuel/Rare | Ticaret, Ay üretimi, ileri bakım. |
| Bilim | Ucuz lab, dağ gözlemi, yoğun enstitü | Uzak gözlem, Science satışı, Ay numuneleri. |
| Nüfus | Ucuz konut, yoğun konut, boş kapasite geliri | Ticaret ve serbest araştırma. |
| Ticaret | Erken satış, rezervli otomasyon, tüketimli pazar | Bilim satışı, malzeme satın alma, offline. |
| Enerji | Genel solar, rüzgâr, kıyı, yeraltı ısısı, Fuel | Görünen coğrafya, sanayi ve yoğun şehir. |
| Yakınlık | Aynı tür kümeleri, merkez bağlantısı | Başka ailelerden destek aldıran açık bağlantılar. |
| Uzaklık | Seyrek kuruluş, bağımsız merkez | Uzak bilim, uzak ticaret ve konut. |
| Coğrafya | Dağ, kıyı/deniz, rüzgâr, sıcak saha, soğuk saha | Rolüne uygun bina ve yerleşim seçimi. |
| Kamu / kuruluş | İade, inşaat, lojistik, otomatik plan | Daha ucuz yeniden düzenleme ve üst ölçek yönetimi. |

Coğrafya alt dalları “ağ/deniz” gibi belirsiz etiketler yerine görünür araziyi adlandırır. Bir oyuncunun bütün enerji türlerini açması zorunlu değildir.

### Ortak Tip 0 ilerleme yolu: 6.500 Science

| Araştırma | Science | Ön koşul | Sonuç |
| --- | ---: | --- | --- |
| Temel İşleme | 0 | Başlangıç | Goods Factory ve seçilebilir girdi. |
| Ticaret Erişimi | 150 | Başlangıç | İlk trade ekranı ve taşanı satma imkânı. |
| Fuel İşleme | 450 | Temel İşleme | Kompakt Yakıt Atölyesi; büyük Fuel rafinerisi onun ileri seçeneği. |
| Rare İşleme | 900 | Fuel İşleme | İlk Rare Element Forge. |
| Rocketry | 600 | Fuel İşleme | Ana dünya Spaceport'u ve Ay lander hazırlığı. |
| Lunar Program | 1.200 | Rocketry | Ay seferi; Orbital Shipyard şartı yok. |
| Ay Malzemeleri | 1.200 | Ay'da Moonstone çıkarabilen uygun Production tamamlanmış | Yerel Goods planı, Ay Habitatı, Lunar Spaceport. |
| Gelişmiş Gezegen Roketi | 2.000 | Ay Malzemeleri + Rare İşleme + yerel çıkarım görevi | Seçilen gezegene uçuş hazırlığı. |

Toplam: 150 + 450 + 900 + 600 + 1.200 + 1.200 + 2.000 = **6.500**. Ticaret maliyetini de içerir; trade'siz oynamayı seçen için zorunlu toplam 6.350 olur. Burada **fiziksel koşullar ayrı ve birlikte zorunludur**. “Herhangi bir ebeveyn yeterli” kuralı grafik yol birleşmeleri içindir; “roketin gerekli teknolojisi + yerel maden çıkarılmış” şartlarının birini iptal etmez.

Bu nominal ortak araştırma toplamıdır; başlangıçtaki 450 Science bunun bir kısmını ödeyebilir. İsteğe bağlı strateji, üretim yoğunluğu, bonus ve otomasyon araştırmaları bu toplama dahil değildir.

Fuel ve Rare'a gezegen seviyesi koşulu konmaz. Hedeflenen zamanlama, bilim yatırımı makul bir oyunda eski Lv2-3 civarında Fuel, Lv4 civarında Rare hissidir. Bu eşzamanlılık ölçülmüş değildir ve bir kapı olarak kodlanmayacak.

### Eski 16 yeni skill önerisinin tamamlanmış yeri

| Skill | Ana dal | Taban Science | Ön koşul örneği | Etki |
| --- | --- | ---: | --- | --- |
| Yüzey Kazı Teknikleri | Production | 75 | Başlangıç | Yüzey Ocağı. |
| Cevher Ayıklama | İşleme | 450 | Temel İşleme | Büyük Goods üretim planı. |
| Küçük Ölçekli Yakıt | Ortak ilerleme | Fuel İşleme içinde | Temel İşleme | Aynı açılışa ikinci ücret yok. |
| Yakıt Depolama | Kamu / kuruluş | 200 | Fuel İşleme | Yakıt Deposu. |
| Sığ Isı Kuyuları | Coğrafya | 250 | Enerji başlangıcı | Sığ Jeotermal Kuyu. |
| Sırt Rüzgârları | Coğrafya | 450 | Wind Power | Sırt Türbini. |
| Mahalle İnşası | Nüfus | 75 | Başlangıç | Düşük Katlı Konut. |
| Kıyı Yoğunlaşması | Nüfus | 350 | Coastal Living | Kıyı Apartmanları. |
| Saha Araştırmaları | Bilim | 100 | Başlangıç | Saha Gözlem Evi. |
| Yerel İşletmeler | Ticaret | 150 | Ticaret Erişimi | Yerel Ticaret Merkezi. |
| İnşaat Organizasyonu | Kamu / kuruluş | 350 | Kamu Yönetimi | İnşaat Dairesi. |
| Orbital Depolama | Kamu / kuruluş | 600 | Yörünge kurulumu | Yörünge Yakıt Tankı; ana Ay yolunun koşulu değil. |
| Ay Malzemeleri | Ortak ilerleme | 1.200 | Ay'da uygun Moonstone Production | Yukarıdaki ortak düğüm; ikinci ödeme yok. |
| Ay Araştırmaları | Bilim | 600 | Ay'da City | Ay Numune Laboratuvarı; Rare İşleme ayrıca gerekli. |
| Ay İkmal Ağı | Ticaret | 600 | Ay'da City + Ticaret Erişimi | Ay İkmal Pazarı. |
| Yakıt Süreçleri | İşleme | 150 / 300 / 450 | Fuel İşleme | Her seviyede Fuel çıktısına +%10, toplam +%30. |

### Diğer dalların somut ilk düğümleri

| Düğüm | Taban Science | Etki / birleşme |
| --- | ---: | --- |
| Wind Power | 150 | Wind Turbine; görünen rüzgâr şartı. |
| Tidal Power | 350 | Kıyıdan veya Enerji yolundan erişilebilir; Tidal Generator. |
| Geothermal Power | 450 | Sığ Isı veya Enerji yolundan erişilebilir; büyük sıcak saha tesisi. |
| Solar Matrix | 350 | Solar'ın yoğun modeli. |
| Fusion Power | 900 | Enerji veya İşleme yolu; Fuel İşleme fiziksel ürün koşulu da aranır. |
| Vein Excavation / Deep Drilling | 450 / 350 | Özel yatak / genel yoğun çıkarım ayrımı. |
| Yoğun Fuel Üretimi | 350 | Fuel İşleme sonrası büyük Fuel Refinery. |
| Mantle Cracking | 900 | Yoğun çıkarım + Fuel erişimi. |
| Advanced Research / Mountain Optics | 350 / 450 | Genel / dağda yoğun bilim. |
| Particle Physics | 900 | Bilim veya İşleme birleşmesi; Rare erişimi ayrıca gerekli. |
| Coastal Living / High-Rise Housing / Luxury Living | 250 / 350 / 900 | Kıyıda ekonomik enerji / genel yoğunluk / ileri yoğunluk. |
| Trade Networks / Harbor Trade / Commodity Markets | 350 / 450 / 900 | Genel / kıyı / işlenmiş tüketimli ticaret. |
| Kamu Yönetimi | 350 | Capital desteklerinin ilgili dal ile birlikte açılması. |
| Lojistik / İleri Koordinasyon | 450 / 900 | Depo/üretim desteği / yoğun enerji desteği. |
| Sivil Girişimler | 150 | Fazla uygun konut başına kredi; Bölüm 6. |
| Serbest Araştırma | 150 | Ana dal Nüfus; Nüfus veya Bilim yolundan erişilebilir; fazla uygun konuttan Science. |
| Üretim Rezervi | 300 | Fazla kapasiteden ham/işlenmiş +%0-%20; Bölüm 6. |
| Küme Planlama | 200 / 400 / 600 | Yakınlık toplamına seviye başına +%10; yalnız en az bir uygun yakın kaynak varsa. |
| Bağımsız Merkezler | 200 / 400 / 600 | Uzak/çok uzak yerleşimin uzaklık toplamına seviye başına +%10. |
| Karma Ağlar | 450 | Yakınlık veya Bilim/Ticaret birleşmesi; başka aileden ilk yakın kaynağın %5 rol desteği. |
| Yerel Coğrafya Uzmanlığı | 200 / 400 / 600 | Seçilen görünür arazi ailesinin mevcut bonusuna seviye başına +%10; olmayan araziyi yaratmaz. |
| Geri Kazanım I / II | 250 / 500 | İade %50 -> %65 -> %75. |
| Ticaret Otomasyonu | 300 | Rezerv üstü satış ve belirlenmiş hedefe alış kuralları. |

### Mevcut tekrar bonuslarının sade eşlemesi

| Yeni bonus | Taban / 3 seviye Science | Etki |
| --- | --- | --- |
| Photovoltaics | 150 / 300 / 450 | Solar ailesi +%10 / seviye. |
| Superconducting Grid | 300 / 600 / 900 | Bina enerji ihtiyacı -%5 / seviye, en fazla -%15. |
| Çıkarım Verimi | 150 / 300 / 450 | Ham çıktı +%10 / seviye; eski ayrı hız/miktar düğümleri tekleşir. |
| Bilim Verimi | 150 / 300 / 450 | Science çıktısı +%10 / seviye. |
| Konut Verimi | 150 / 300 / 450 | Bina konut kapasitesi +%10 / seviye. |
| Ticaret Verimi | 150 / 300 / 450 | Üretilen kredi +%10 / seviye; trade alış/satış fiyatını değiştirmez. |
| Consumer Goods | 250 | Bazaar açılışı; Goods başlangıç erişimi için ikinci zorunlu kapı değil. |

İki eski bonusun tekleşmesi iki ayrı +%30 vermek anlamına gelmez. Eski kayıt taşıma zorunluluğu olmadığından yeni ağaçta tek kimlik ve tek üç seviyelik ödeme bulunur.

### Eski 54 düğüm için kimlik dönüşüm haritası

Bu eşleme eski bedelleri korumaz; yukarıdaki yeni bedeller kullanılır. “Yörünge planı” ayrı kapsamı, “gelecek” ise satın alınamaz önizlemeyi belirtir.

| Eski kimlik | Yeni karşılık |
| --- | --- |
| `root` | Ücretsiz başlangıç merkezi. |
| `unlock_spaceport` | Rocketry. |
| `unlock_space_station` | Orbital City kuruluşu; ayrı yörünge planı. |
| `unlock_zero_g_nexus` | Orbital Science açılışı; yörünge planı. |
| `unlock_orbital_mirrors` | Orbital Energy destek açılışı; yörünge planı. |
| `unlock_orbital_shipyard` | Orbital sefer hazırlığı; Ay'ın zorunlu kapısı değil. |
| `unlock_orbital_offworld_market` | Orbital Commercial açılışı; yörünge planı. |
| `unlock_moon` | Lunar Program. |
| `unlock_asteroids` | Gelecek önizleme; Tip 0'dan satın alınamaz. |
| `unlock_planetary_colonization` | Tip 1'de gerçek yerleşim; demoda kapalı. Gelişmiş Roket ayrı yeni düğüm. |
| `unlock_orbital_logistics` | Gelecek yörünge lojistiği önizlemesi. |
| `unlock_interstellar` | Gelecek üst medeniyet sefer önizlemesi. |
| `unlock_solar_panel` | Ücretsiz temel enerji ve solar. |
| `unlock_wind_turbine` | Wind Power. |
| `solar_efficiency` | Üç seviyeli Photovoltaics. |
| `unlock_tidal_generator` | Tidal Power. |
| `power_transmission` | Üç seviyeli Superconducting Grid. |
| `unlock_geothermal_plant` | Geothermal Power. |
| `unlock_solar_matrix` | Solar Matrix. |
| `unlock_fusion_reactor` | Fusion Power. |
| `unlock_antimatter_chamber` | Gelecek Tier 4 enerji, Tip 0'da kapalı. |
| `unlock_mining` | Ücretsiz Production/Mine/Warehouse ve Temel İşleme. |
| `unlock_rich_vein_excavator` | Vein Excavation. |
| `mine_speed` | Çıkarım Verimi ile birleşir. |
| `unlock_deep_drill` | Deep Drilling. |
| `deep_mining` | Aynı Çıkarım Verimi düğümü; ikinci çıktı çarpanı değil. |
| `unlock_plasma_smelter` | Fuel İşleme küçük modeli açar; büyük rafineri için ayrıca 350 Science Yoğun Fuel Üretimi. |
| `unlock_molecular_forge` | Rare İşleme. |
| `unlock_mantle_cracker` | Mantle Cracking. |
| `unlock_quantum_harvester` | Gelecek Production önizlemesi; hayali aktif bina açmaz. |
| `unlock_lab` | Ücretsiz temel Science/Lab. |
| `science_income_1` | Bilim Verimi. |
| `unlock_mountain_observatory` | Mountain Optics. |
| `unlock_advanced_lab` | Advanced Research. |
| `science_income_2` | Aynı Bilim Verimi; ikinci paralel bonus değil. |
| `unlock_particle_accelerator` | Particle Physics. |
| `unlock_quantum_computer` | Gelecek Tier 4 Science; gerçek katalog kilidi. |
| `unlock_residential` | Ücretsiz temel Residential/Habitat. |
| `housing_income_1` | Konut Verimi. |
| `unlock_seaside_villas` | Coastal Living. |
| `unlock_apartments` | High-Rise Housing. |
| `housing_income_2` | Aynı Konut Verimi. |
| `unlock_luxury_complex` | Luxury Living. |
| `unlock_arcology` | Gelecek Tier 4 konut; gerçek katalog kilidi. |
| `unlock_commercial` | Ücretsiz temel Commercial/Market. |
| `unlock_harbor_market` | Harbor Trade. |
| `unlock_bazaar` | Consumer Goods, yalnız bina açılışı. |
| `trade_income_1` | Ticaret Verimi. |
| `unlock_trading_post` | Trade Networks. |
| `trade_income_2` | Aynı Ticaret Verimi. |
| `unlock_commodities_exchange` | Commodity Markets. |
| `unlock_logistics_center` | Lojistik. |
| `unlock_command_center` | İleri Koordinasyon. |
| `unlock_central_bank` | Gelecek Tier 4 ticaret, Tip 0'da kapalı. |

Karma Ağlar gibi farklı aileden bonuslar başlangıçta açık aynı tür kuralını genişletir. Örneğin Science districtinin yakındaki Residential'dan bilim desteği alması yalnız bu açık skill ile gelir; eski karmaşık çapraz gelir tablosu kendiliğinden geri dönmez. Aynı kaynaktan aynı çıktı rolüne bu skill bir kez katkı verir, sonsuz karşılıklı üretim döngüsü hesaplanmaz.

Eski 54 düğümün bedelleri bu yeni düzenin üzerine ayrıca yığılmayacak. Başlangıç merkezleri ücretsiz açılış olarak kalır; eski tekrar bonusları üç seviyeli dar aile bonuslarına dönüşür. Lunar/Orbital eski kapıları yeni ortak yol veya isteğe bağlı yörünge planına eşlenir. Gelecek 9 düğüm üst medeniyet önizlemesinde kalır, Tip 0'dan satın alınamaz. Uygulamada eski kimlik -> yeni düğüm tablosu çıkarılarak boşa düşen bina kapısı bırakılmayacak.

### Fraktal ağaç fikri

**Askıda:** Tip 0 ağacının Tip 1'de tek bir üst düğüm olarak özetlenmesi; üst düğümün satın alınması ve her medeniyette benzer önemde düğümler kurulması. Bu görsel özet fikri kesinleşmeden eski araştırmalar silinmez, tekrar ücretlendirilmez veya otomatik kilitlenmez. Şimdilik Tip 1 ağacında “Tip 0 mirası” özeti gösterilebilir; satın alınmış etkiler korunur.

## 15. Ana dünya, Ay ve seçilen gezegene geçiş

### Doldurulmuş geçiş tablosu

| Adım | Araştırma / fiziksel koşul | İsimli bedel | Süre / sonuç |
| --- | --- | --- | --- |
| Ana dünya Capital Lv2 | İlk Capital Lv1 | 250 kredi + 500 ek nüfus yükü | 10 sn; ikinci yuva açılır. |
| Ana dünya Spaceport | Rocketry; Capital'da 2 boş yuva | 500 kredi | 4 sn; Ay hazırlık noktası. |
| Ay lander'ı | Lunar Program + tamamlanmış Spaceport | 3.000 kredi + 40 Ferrite + 20 Fuel | 30 sn hazırlık + 30 sn yolculuk. |
| Ay'da ilk City | Lander varmış | İlk City ücretsiz, Capital otomatik | 4 sn; imparatorluk nüfus/enerji havuzuna katılır. |
| Ay'da ilk Production | City içinde, görünen regolit/Moonstone çıkarım alanı üzerinde | 300 kredi + 30 Ferrite | 4 sn; Moonstone görünürlüğü/çıkarımı açılır. |
| Yerel madeni kullanma görevi | Bu Production tamamlanmış | Gerçek üretimden toplam 100 Moonstone çıkar | Ticaretle alım veya iade bu sayacı ilerletmez. |
| Ay Malzemeleri | Yerel Production tamamlanmış | 1.200 Science | Ay binaları ve Lunar Spaceport açılır. |
| Ay Capital Lv2 | Ay Capital Lv1 | 250 kredi + 500 ek nüfus yükü | 10 sn; Lunar Spaceport'un iki yuvasını sağlar. |
| Regolit büyük Goods planı | İsteğe bağlı; Ay Malzemeleri | 900 kredi + 100 Moonstone + 20 Goods | 4 sn; ithal Goods da geçerli, zorunlu tek fabrika yolu değil. |
| Lunar Spaceport | Ay Capital'ında 2 yuva; Ay Malzemeleri | 8.000 kredi + 200 Moonstone + 50 Goods + 30 Fuel + 10 Rare | 30 sn; özel roketin zorunlu yerel tesisi. |
| Gelişmiş Gezegen Roketi araştırması | Yerel 100 Moonstone görevi + Ay Malzemeleri + Rare İşleme | 2.000 Science | Satın alma anlık. |
| Gelişmiş roket hazırlığı | Lunar Spaceport + gelişmiş roket araştırması | 12.000 kredi + 1.200 Moonstone + 30 Goods + 120 Fuel + 40 Rare | 60 sn; seçilen hedefe kalkışa hazır. |
| Hedef gezegene uçuş | Oyuncu sistemdeki diğer gezegenlerden birini seçer | Ek mesafe bedeli yok | 60 sn; varışta Tip 0 tamamlanır, Tip 1 başlar, demo sınırına ulaşılır. |

Ay üzerindeki Spaceport için yeni bina tanımı gerekir. Adı farklı olsa da genel filo kurma paneli açmaz. Gezegen seçimi listeden veya Solar haritasından yapılabilir. Bu sırada sadece hedef seçimi açılır; demo sonundaki bütün evrenleri inceleme yetkisi erkenden açılmaz.

Gaz gövdesi de hedef seçilebilir; bu durumda varış o gövdenin yörüngesine ulaşmadır. Demo hedefte yüzey City kuruluşu istemediği için “yalnız Terran'a gidebilirsin” kısıtı eklenmez.

Ay Spaceport ve roket bedelleri gizli kaynak adı göstermez. Görev paneli uygun erişimden önce “ileri işlenmiş malzemelere eriş” gibi aşamayı açıklar; Rare/Fuel açılınca isimli listeye dönüşür.

### Son Ay hazırlığının toplu bedeli

| Kapsam | Kredi | Moonstone | Goods | Fuel | Rare |
| --- | ---: | ---: | ---: | ---: | ---: |
| Zorunlu Lunar Spaceport + roket | 20.000 | 1.400 | 80 | 150 | 50 |
| İsteğe bağlı Regolit planı da alınırsa | 20.900 | 1.500 | 100 | 150 | 50 |
| Ay Capital Lv2 de toplamdaysa, Regolit olmadan | 20.250 | 1.400 | 80 | 150 | 50 |
| Ay Capital Lv2 ve Regolit birlikte toplamdaysa | 21.150 | 1.500 | 100 | 150 | 50 |

Bu toplam, lander'ı, erken dünya gelişimini, araştırmaları, enerji/konut desteğini ve aradaki bakım tüketimini içermez. İlk iki satır yalnız tesis/roketi, son iki satır Ay Capital yükseltmesini de içerir. 100 yerel Moonstone görevi ayrı bir ödeme değildir; üretilen bu stok normal bedellerde kullanılabilir.

İşlenmişleri üretirken harcanan ham kaynak da yukarıdaki doğrudan Moonstone bedeline dahil değildir. Örneğin Regolit dahil satırlardaki **100 Goods + 150 Fuel + 50 Rare**, bonuslar olmadan ayrıca:

- Ferrite ile: 200 + 600 + 600 = **1.400 Ferrite** ister.
- Moonstone ile: 114,29 + 342,86 + 342,86 = **800 Moonstone** eşdeğeri ister.
- Hepsi yerel Moonstone ile işlenirse doğrudan 1.500 + işleme için 800 = **2.300 Moonstone**; tam turlara yuvarlama ve bakım buna eklenir.

Böylece yalnız “1.500 Moonstone yeter” denerek işleme ihtiyacı gizlenmez. Oyuncu Ferrite/Moonstone üretimi, fazla Science satışı, krediyle malzeme alımı ve nüfus geliri arasında dağılım yapabilir. **Ay'da fiziksel Production kurma ve yerel çıkarım şartı**, trade ile atlanamaz; bütün Goods/Fuel/Rare fabrikalarını bizzat kurmak şart değildir.

### Depo ve hazırlık akışı

- Roketin 1.200 Moonstone ödemesi için taban 500 kapasite yetmez; bir Warehouse toplamı 1.500'e çıkarır.
- Trade rezervi “roket için 1.200 Moonstone tut” diye ayarlanabilir; otomasyon bu rezervi satmaz.
- Hazırlık sırasında başka yerleşimler yönetilebilir. Aynı roket için iki kez ücret alma veya iki ayrı Tip 0 tamamlanma ödülü oluşmaz.
- Hedef değişikliği kalkıştan önce ücretsizdir; uçuş başladıktan sonra hedef sabittir.
- Uçuş ekranı açık olmasa da ekonomi ilerler. Offline'da da aynı hazırlık/uçuş saati kuralı geçerlidir.

## 16. Sürekli görev paneli

**Karar:** Ana hedef medeniyet seviyesine ulaşmak; ara hedefler bunun gerekli adımları. Panel sürekli erişilebilir, daraltılabilir; yerleşim ekranını kapatmaz. İleride narrative hook'lar aynı ara görev yapısına eklenebilir.

| Sıra | Panelde ana/ara görev | Tamamlanma ölçüsü |
| --- | --- | --- |
| Ana | Tip 1 medeniyete ulaş | Ay'dan çıkan roketin seçilmiş gezegene varışı. |
| 1 | İmparatorluğun üretim temelini kur | İlk normal district + kullanılabilir pozitif enerji/nüfus dengesi. |
| 2 | İlk malzemeyi çıkar | Ana dünyada Production tamamlanması ve Ferrite üretimi. |
| 3 | Bir gelişim yolu oluştur | Science, ticaret veya nüfus gelir yolundan herhangi birini işler hale getir. Üçünü birden zorunlu istemez. |
| 4 | İşlenmiş ürünlere eriş | Goods, sonra Fuel ve Rare erişimi; ihtiyacını üretim veya izinli trade ile karşıla. |
| 5 | Ay'a ulaş | Araştırmalar, Spaceport, lander, varış. Alt adımlar ayrı işaretlenir. |
| 6 | Ay'da üretime başla | City + Production; gerçek çıkarımdan 100 Moonstone. |
| 7 | Lunar Spaceport'u tamamla | Gerekli özel yapı. |
| 8 | Daha iyi roketi hazırla | Gerekli araştırma ve isimli malzeme ödemesi. |
| 9 | Hedefini seç ve gönder | İstenen gezegen seçimi, hazırlık ve uçuş ilerlemesi. |
| Sonuç | Tip 1'e vardın | Demo içeriği tamamlandı; üst ölçekleri incele. |

Alternatif strateji seçilmişken görev “mutlaka Fuel Refinery kur” demez; “gerekli Fuel'ı sağla” der. Sadece kullanıcı tarafından zorunlu istenmiş fiziksel yapılar bina şartı olur.

Liste gösterim sırasıdır, bütün görevleri birbirine bağlayan yeni bir sert kilit değildir. Rare araştırması bitmeden Ay'a gidilebilir; Rare son roket için gerekir. Tamamlanmış ara hedef erkenden işaretlenir. Böylece görev paneli skill ağacının üzerine ikinci gizli teknoloji sırası koymaz.

**Hesap taslağı:** Ana görevler zorunlu ekonomiyi taşıyan büyük ücretsiz kaynak paketi vermesin. İlk sürümde bu görevler yönlendirme ve kalıcı başarı işareti sağlar; ekonomik ödül 0. Daha sonra eklenen hikâye ödülü açık ve tek seferlik olur. Böylece belirsiz görev ödülü bina dengesini değiştirmez.

Her tamamlanma/ödül tek bir olay kimliğiyle kayıt edilir. Paneli açma, oyunu yükleme, zaman atlatma veya aynı nesneyi yeniden kurma tekrar ödül üretmez. Narrative görevler henüz yazılmayacak; ileride hikâye metni, koşul ve ödül alanları eklenebilir.

## 17. Trade: uzmanlaşmayı mümkün kılan ekonomi

**Kesin yön:** Erken açılır. Fazla Science krediye çevrilebilir; krediyle erişilmiş malzemeler alınabilir. Her oyuncu her üretici zincirini kurmak zorunda kalmaz. Yeni hammadde veya yeni işlenmiş ürün eklenmez.

Trade'in bütün ayrıntıları daha önce ayrı konuşulacaktı. Aşağıdaki kurallar bu belgenin boş kalmaması için tamamlanmış **taslaktır**; özellikle Science satın alma kararı K01'de ayrılmıştır.

### İlk sürümün basit fiyatı

Değişken piyasa, talep çöküşü veya sürekli fiyat takibi eklemiyoruz. Ürün başına sabit bir referans fiyat var; satış bunun %90'ı, alış %110'u. Bu ilk oranlar hesap taslağıdır.

| Ürün | Referans kredi / adet | Oyuncu satar | Oyuncu alır |
| --- | ---: | ---: | ---: |
| Ferrite | 2 | 1,8 | 2,2 |
| Moonstone | 3,5 | 3,15 | 3,85 |
| Science | 5 | 4,5 | 5,5; K01'de kapsam kararı. |
| Goods | 22 | 19,8 | 24,2 |
| Fuel | 34 | 30,6 | 37,4 |
| Rare | 92 | 82,8 | 101,2 |

Gelecek hammadde için referans kuralı **2 × nadirlik verimi**; ancak medeniyet ve fiziksel çıkarım erişimi açılmadan hiçbir fiyat/isim gösterilmez. Bu, geleceğin bütün bina ekonomisinin bu belgede dengelendiği anlamına gelmez.

Bir ürünü alıp hemen geri satmak yatırılan paranın 0,9/1,1 = yaklaşık %81,82'sini geri verir. Böylece yalnız alış-satış arasında dönerek kredi üretilemez. Ham maddeyi işleyerek kâr etmek ise üretici, süre, enerji ve çalışan kullanan gerçek stratejidir.

### Kilitler ve alternatif yollar

- Ferrite trade için önce uygun ana dünya Production tamamlanmış olmalı.
- Moonstone trade için önce Ay'a yerleşip yerel Production tamamlanmış olmalı. İlk 100 çıkarım görevini satın alma tamamlamaz.
- Goods işleme başlangıçta açık. Fuel ve Rare kendi Science araştırmasıyla erişilir; trade o araştırmayı atlamaz.
- **Taslak:** Araştırmayla erişilmiş Goods/Fuel/Rare, o ürünün fabrikası kurulmadan da alınabilir. Ticaretin strateji oluşturması için bu tercih gerekir.
- Roket ve Spaceport özel fiziksel şartlarını satın alınmış ürünler iptal etmez.
- Kaynak stok, fiyat ve ödeme listelerinde aynı erişim kuralı geçerlidir.

### Taşma ve rezerv

| Durum | Davranış |
| --- | --- |
| Trade henüz açılmamış | Depoyu aşan pozitif malzeme üretimi kaybolur; S15'in son kararı. |
| Trade açılmış | **Taslak:** Kapasiteyi aşan miktar doğrudan satış fiyatıyla krediye çevrilir. Ayrı sonsuz malzeme deposu yaratılmaz. |
| Ayrıntılı otomasyon açık | Oyuncu rezerv/alış hedefi belirler; rezerv üstü Science ve malzemeler satılabilir, eksik ürün alınabilir. |
| Kredi yetersiz | Karşılanabilen miktar alınır; açık sipariş tekrar kredi yaratmaz, borç oluşmaz. |

Temel taşanı satma özelliği erken Ticaret Erişimi'nin içindedir; oyuncu bu sorun için ayrıca 300 Science otomasyon düğümünü beklemez. Otomasyon düğümü hedef stok/rezerv kuralları ve Science satışı gibi ayrıntıları açar.

Science'ın **manuel satışı 150 Science'lık ilk Ticaret Erişimi ile açılır**. Ek 300 Science yalnız otomatik Science satışı ve gelişmiş stok kuralları içindir.

Otomasyon kendi kendine alış-satış döngüsü kurmaz. Aynı ürün için **alış hedefi <= satışın başlayacağı stok** olmalı. Roket rezervi satıştan korunur; depoda fiziksel yer açılmadan rezerv hedefi kapasitenin üzerine kurulamaz. Aynı ekonomi anında bakım ve ilan edilmiş kuruluş rezervi ayrılır, üretim işlenir, taşma satılır, sonra izin verilen otomatik alışlar yapılır.

Kredi ve Science mevcut taslakta depo tavanı kullanmadığından para birikmesi için ek gizli kasa sınırı yoktur.

## 18. Offline ilerleme

**Kararlar:** Varsayılan açık; oyuncu kapatabilir. Üretim 1/10 hızında. Trade otomasyonu, bakım, girdiler, inşaat, yükseltme ve uçuş da kapsama dahil. Yeni oyuncu kararları otomatik verilmeyecek.

**Ortak saat hesap taslağı:**

```text
İşlenen ekonomi süresi = sınır içinde sayılan gerçek kapalı süre × 0,10
```

Örnek: Sınır aşılmamışsa 60 dakika kapalı kalmak, **6 dakika ortak ekonomi zamanı** sağlar. Sadece üretimi 1/10'a indirip tüketimi tam hızda yürütmeyiz; bakım ve üretim aynı saatle ilerler. İnşaatı/uçuşu tam gerçek sürede bitirip bakımını 1/10'a indiren ikinci bir saat de eklemeyiz.

### Kapsanan işler

| İş | Offline davranış |
| --- | --- |
| Ham/Science/kredi/işlenmiş üretimi | Ortak saatte; gerçek girdi, enerji ve nüfusla. |
| Goods/Fuel/Rare bakımı | Aynı ortak saatte ödenir; stok yoksa ilgili etki kapanır. |
| Otomatik trade | Açılmış ve oyuncu tarafından tanımlanmış kurallarla devam eder. |
| Taşan malzeme | Online ile aynı trade açık/kapalı kuralı. |
| İnşaat ve seviye yükseltme | Önceden başlatılmış iş ilerler ve tamamlanabilir. |
| Roket hazırlığı/uçuş | Önceden başlatılmış iş ilerler; varış olayı bir kez işlenir. |
| Skill satın alma | Kendiliğinden satın alınmaz. |
| Yeni City/district/roket başlatma | Oyuncu kararı olmadan yapılmaz. |

Tamamlanan bir inşaat kalan offline sürede çalışabilir. Dolayısıyla bütün süreyi yalnız kapanış anındaki üretim hızına çarpmak yeterli değildir. Hesap, stok bitişi, bakım, inşaat, uçuş ve otomasyon olayları arasında ilerler. Milyonlarca boş kare çalıştırmak yerine sonucu değiştiren olay aralıkları kullanılır.

Kayıt açılışında geçen süre bir kez işlenir ve zaman damgası güncellenir. Ayarı değiştirmek aynı süreyi ikinci kez kazandırmaz. Saat geriye gitmişse negatif süre ödül üretmez. Sonuç ekranı brüt üretim, tüketim, trade sonucu ve net stok değişimini ayrı gösterebilir.

**Açık anlam sorusu K02:** Kullanıcının “en fazla 10x” sınırında x'in birimi belirlenmedi. Bu ifade otomatik olarak “10 saat” kabul edilmedi. Sınır seçilene kadar birikmenin üst sınırı tamamlanmış uygulama kararı sayılmaz; 1/10 ortak saat kararı kesindir.

## 19. Alt butonlar, büyük ağaç ve demo sonrası önizleme

### Yerleşim butonları

Eski Terran/Tidal/yeraltı yoğunluk lensleri ve doğal saha yüzdeleri tamamen kaldırılacak. Aynı alt alan şu seçimlere dönüşür:

| Buton | Vurgulanan uygunluk | Örnek kısa gerekçe |
| --- | --- | --- |
| Energy | Seçilmiş enerji ailesine uygun görünen alanlar | Rüzgârlı alan üzerinde; Wind için tam bonus. |
| Population | Konut kapasitesi için uygun alanlar | Ova üzerinde, göl yakınında. |
| Production | Görünen maden, dağ, regolit vb. | Dağ üzerinde; Production tam bonus. |
| Science | Gözlem ve araştırmaya uygun alanlar | Dağ ve eski yerleşim etkileri. |
| Commercial | Kıyı, liman, delta ve bağlantı fırsatı | Kıyı üzerinde; merkez bağlantısı mümkün. |

Bu butonlar görünmeyen araziyi açmaz; zaten ilk bakışta görülebilen coğrafyanın ilgili rolünü vurgular. Normal/yakın/üzerinde kademeleri renk/desenle ayrılır. Yalnız renge bağımlı anlatım kullanılmaz.

Yerleşim önerisi coğrafyayı tek başına en yüksek puan diye sıralamaz: oyuncunun **yakın küme / bağımsız uzak / dengeli** hedefini, enerji/nüfusu ve kuruluş maliyetini de hesaba katar. Sonuç en fazla üç öneri ve kısa gerekçe sunar. “Burada +%25 coğrafya, yakın küme” gibi açıklama, hesabın kaynağını gösterir. Sayılar ayrıntıya isteyen bakabilir; temel arayüzde 87,326% gibi sürekli nokta puanı bulunmaz.

### Skill ağacı önizlemesi

Bütün medeniyetlerin devasa bir ağaç oluşturduğu hissi oyun sırasında verilebilir: uzak dalların silik silueti, medeniyet başlıkları ve satın alınamaz gelecek düğümler. Bu, kilitli hammadde isimlerini ve kesinleşmemiş bedelleri göstermeyi gerektirmez.

### Harita önizlemesi

**Karar:** Güneş sistemi, Gökada, Galaksi, Evren ve Paralel Evrenler arasında ayrıntılı serbest inceleme demo bitişinden sonra açılır. Oyun başında bütün bu ekranlar gezilebilir yapılmaz. Ay'a yolculuk veya hedef gezegen seçimi için açılan sınırlı Solar görünümü bu hakkın tamamı değildir.

Oyuncu sistemlerin içine, gezegenlerin ayrıntısına inebilir; çok geniş bir evren hisseder. Önizleme ekranında kaynak harcama, yerleşim, araştırma veya üretim başlatma yoktur. Tip 1 hedef gezegeninde City kurma düğmesi demo kapsamında çalışmaz.

**Uygulama yönü:** Ziyaret edilen bölümleri seed'den gerektiğinde üret; milyarlarca gezegeni aynı anda belleğe yükleme. İnceleme için üretilen gövde kayıtları aktif ekonomi yerleşimine dönüşmez. Kilitli kaynaklar bu ekranda da adlarını sızdırmaz.

Varış mesajı kapatılabilir; oyuncuyu bütün önizlemeyi engelleyen eski demo panelinde tutmaz. Eski dünya/Ay ekonomisine geri dönüp devam etme kapsamı K03'te ayrılmıştır.

## 20. Kapsam, askıdaki fikirler ve kayıtlar

| Konu | Bu sürümde durum |
| --- | --- |
| Tip 0 ekonomisinin ve yeni demo geçişinin güncellenmesi | Bu belgenin ana uygulama kapsamı. |
| Tip 1-5 katmanları, merkezleri ve ölçek sözleşmesi | Kullanıcının tabloları kesin; sonraki içerik bununla uyumlu tasarlanacak. |
| Tip 1-5 oynanabilir bütün bina/skill fiyatları | Bu demo planı bunları bitirmiş sayılmaz; ayrı içerik çalışması. |
| Yörüngenin City/district olarak ayrıntılı kuruluşu | Ayrı alt tasarım; mevcut eşleme Bölüm 13. Demo yoluna zorunlu eklenmez. |
| Genel filo, kargo, gezegenler arası gemi yönetimi | Eklenmeyecek; eski zorunlu bağımlılıklar kaldırılacak. |
| Yeni ham/işlenmiş kaynak türü | Eklenmeyecek. |
| Bina level'ı | Eklenmeyecek; ayrı bina modeli ve adet kullanılacak. |
| Fraktal skill sıkıştırma / yeni miras düğümüne ödeme | Askıda fikir; satın alınmış etkiler şimdilik korunur. |
| Sabit tutorial seed'i, random/volkanik/gaz başlangıcı | Askıda; oyun sistemleri tamamlandıktan sonra konuşulacak. |
| Gövdeye göre farklı skill ağacı | Askıda; başlangıç çeşitliliği kararıyla birlikte. |
| Narrative hook'lar | Görev veri yapısı hazır tutulur; hikâye içeriği daha sonra. |
| Eski tutorial para/Science desteği | Yeni başlangıç bütçesine dahil değil; K05'te açık kapsam kararı. |
| Başarımlar | Ekonomik ödül eklenmez; yeni olay ve kimliklerle uyumlandırma aşağıda. |
| Eski kayıt uyumluluğu | Zorunlu değil; yeni kayıt şeması kullanılabilir. |

**Kayıt kararı:** Eski kayıtları yeni tasarıma dönüştüren kapsamlı bir taşıma katmanı bu güncellemenin şartı değildir. İleride uygulandığında kayıt sürümü artırılır; eski kayıt yeni sayıların arasına sessizce karıştırılmaz. Bu belge hazırlanırken mevcut hiçbir kayıt silinmedi veya değiştirilmedi.

Yeni şemada en az şu bilgiler bulunmalı: medeniyet/geçiş olayları, oyuncu adı/kuruluş planı/canlı işlevsel tür, gerçek alt nesneler, gövde boyutu ve konumları, kalıcı kaynak erişimleri, üretim girdi grupları, adet/gerçek ödeme toplamları, aktif üretim/bakım durumu, rezerv/trade kuralları, tek seferlik görev işaretleri ve son işlenmiş zaman. Kaynak görünürlüğü ile aktif üretici varlığı aynı alan olmayacak.

### Önceki envanterde kalan yan sistemler

- **Tutorial desteği:** Eski rehber yalnız metin değil; kredi/Science ödülleri, eksik parayı tamamlama ve atlamada Ferrite verme yolları içeriyor. Bunlar yeni 3.000/450 başlangıç taslağının üzerine hesaplanmadı. Tutorial yeniden yazımı askıda kalsa da eski ekonomik yardımın açık kalması K05'te karara bağlanmalı.
- **Başarımlar:** Eski envanterde 117 tanım bulunmuştu. Ekonomik ödül vermeme ilkesi korunur. Bina sayımı gerçek adetleri, yerleşim sayımı yeni katmanları, Ay ve Tip 0 bitişi ayrı olayları kullanmalı. Yeniden adlandırılan skill kimlikleri ve eski enum eşleşmeleri güncellenmeli; tanımı olan her başarımın çalıştığı varsayılmamalı.
- **Keşif/survey/asteroit:** Eski 200.000 kredi + 50.000 Science survey ve 5.000 Science asteroit taraması demo yoluna taşınmaz. Üst haritayı incelemek bu ücretleri istemez; gelecekte oynanabilir keşif ekonomisi ayrı tasarımdır.
- **Duraklatma/kayıt:** Online duraklatma ekonomiyi durdurur. Duraklatılmış açık oyunu offline gibi tekrar ödüllendirme yok. Önceki envanterdeki yükleme sonrası başlangıç değerleriyle üstüne yazma riski yeni şemada giderilmeli; yeni oyunun bütçesi kayıt yüklemede yeniden dağıtılmamalı.
- **Sunum/ayarlar:** Görsel gün-gece dönüşü üretim hakkı veya ikinci ekonomi saati değildir. Ses, kamera ve diğer genel ayarlara bu plan yeni bir oynanış sistemi yüklemez.

## 21. Oyuna uygulama sırası

**Bu liste yapılacak işleri sıralar; şimdi uygulanmış değildir.** Bağımlı işler tamamlanmadan yeni katalog bütün halinde açılmaz.

| Sıra | İş | Somut teslim / bağımlılık |
| --- | --- | --- |
| 01 | Terimleri ve kimlikleri ayır | `act` ilerlemesi -> civilization type; bina tier'ı, gezegen seviyesi ve medeniyet tipi ayrı. Eski Ay City'si demo tetikleyicisini kaldır. |
| 02 | Ortak veri/kayıt sözleşmesi | Gerçek alt nesneler, kalıcı kaynak erişimi, olay kimlikleri ve yeni kayıt sürümü. Mevcut oyuncu isimlerini sistem türünden ayır. |
| 03 | Global nüfus ve enerji hesabı | Kuruluş yükleri + çalışan + bakım; imparatorluk geneli ceza; konut gelir döngüsünü tek hesapla. |
| 04 | Kaynak erişimi ve isimli ödeme | Medeniyet + yerel Production kapısı; ilk üretici bootstrap'ı; tüm ödeme ekranlarında gerçek kaynak isimleri. |
| 05 | Aynı tür fiyatı ve iade | Bina/district yerel sayaçları, inşaattaki adet, yıkımda azaltma, N/C ödeme toplamı, %50-%75 iade. |
| 06 | Üretim tarifleri ve girdi grupları | Oyuncu mineral seçimi, düşük stokta grup davranışı, çıktı önizlemesi, Goods/Fuel/Rare oranları; otomatik nadir tüketimini kaldır. |
| 07 | Coğrafi görseller ve üç uygunluk | Görünen alanlar, yakın kuşak, farklı türleri toplama, mirası tekilleştirme. Eski solar/wind/tidal/mineral puanını etkiden çıkar. |
| 08 | Fiziksel mesafe ve konum etkisi | Gövde boyutu, beş etiket, geometrik yakınlık, yumuşayan kaynak katkısı, uzaklık, Capital kapsamı; yol kesişim bonusunu kaldır. |
| 09 | Seviye / yuva / maliyet eğrileri | Yeni ×1,25 district, City/gezegen tabloları; eski yol-komşu seviye kapısını kaldır. Çıktıya tier'ı iki kez uygulama. |
| 10 | Bina kataloğu | Eski 42 tanımı eşle; 16 öneriyi rollere dağıt/birleşen modeli birleştir; her kartta kuruluş/bakım/yuva/çalışan. Tier 4 kilitlerini düzelt. |
| 11 | Trade temeli | Erken erişim, sabit fiyat, alış-satış farkı, erişim kilidi, taşmayı krediye çevirme, rezervli otomasyon. |
| 12 | Strateji skill ağı | Ortak yol + dal fiyatı + birleşmeler; erken Fuel/Rare; nüfus/yakın/uzak/coğrafya; eski 54 düğümün kimlik eşlemesi. |
| 13 | Yerleşim önerileri ve alt butonlar | Eski lensleri kaldır; beş rol butonu, stratejiye uygun üç öneri ve kısa gerekçe. |
| 14 | Ay ekonomisi ve roket | Yerel çıkarım görevi, isteğe bağlı üretim yolları, Lunar Spaceport, hedef gezegen seçimi ve tek varış olayı. |
| 15 | Sürekli görev paneli | Ana/ara görevler, alternatif temin kabulü, tek seferlik sonuç ve narrative için alanlar. |
| 16 | Otomatik plan / elle düzenleme sözleşmesi | Gerçek maliyetle plan kurma, zoom ile aynı nesneleri düzenleme, tür ataması; Tip 1 fiyat kararı K04'e göre. |
| 17 | Yeni demo sonucu ve üst haritalar | Varışta Tip 1, hedefte kuruluş engeli, ayrıntılı serbest önizleme; eski kilitleyen demo panelini değiştir. |
| 18 | Offline | Aynı ekonomi kuralları ve ortak 1/10 saat; girdi/bakım/trade/inşaat/uçuş olaylarını tek kez işle. K02 sınırına göre. |
| 19 | Yörünge dönüşümü | City rolü ve district planı; ana demoyu eski Shipyard zincirine bağlamadan ayrı kapsam. |
| 20 | Kullanıcının oynanış geri bildirimiyle denge | Aynı bütçedeki farklı stratejilerin gerçek ilerleme sürelerini kullanıcı değerlendirir; ölçülmeyen süre dengeli diye işaretlenmez. |
| 21 | Yan sistem eşlemesi | Eski tutorial ekonomik yardımını K05'e göre ayır; başarımların kimlik/adet/medeniyet olaylarını güncelle; eski keşif bedellerini serbest önizlemeye taşıma. |

### Önceki incelemede belirlenen başlıca uygulama yerleri

Dosyalar şu anda değiştirilmedi. Bu liste önceki envanterde bulunan sahiplikleri gösterir; uygulama sırasında aktif çağrı yolları yeniden okunacak.

| Sorumluluk | Dosya / içerik |
| --- | --- |
| Medeniyet, kaynak erişimi, geçiş, kayıt | `scripts/game/GameState.gd`, `scripts/game/PlanetProgress.gd` |
| Tarif, kapasite, nüfus/enerji, bakım | `scripts/game/ProductionManager.gd` ve ekonomi yardımcıları |
| Bina tanımı, filtre, yer ve tier kapıları | `scripts/game/BuildingDef.gd`, `resources/buildings/*.tres` |
| District tanımı, seviye ve kuruluş | District kaynakları, `scripts/planetary/PlanetaryView.gd` |
| Mesafe, yollar, coğrafya ve lensler | PlanetaryView ve gezegen yüzeyi/üretim görselleştirme yardımcıları |
| Araştırma tanımı ve satın alma | Skill tree tanımları ve skill arayüzü |
| Eski gemi bağımlılıklarının kaldırılması | `scripts/game/ShipManager.gd`, `scripts/game/logic/SpaceportLogic.gd` ve seferi çağıran akışlar |
| Demo, Solar ve üst haritalar | Varış olayı, demo paneli ve ilgili görünüm erişim kontrolleri |

Kod değişikliği yapıldıktan sonra Godot/Unity çalıştırma, oyun testi ve oynanış denemesi kullanıcıya bırakılacak. Kullanıcı ayrıca istemedikçe ben test çalıştırmayacağım.

## 22. Sayısal karşılaştırmalar ve sınırları

### Ortak ekonomik ölçü

Burada fiyatları, farklı ürünleri kıyaslamak için kullanıyoruz. İlk yatırım geri dönüşü = taban kredi / dakikalık katkı. Bu bir oyunun toplam süresi veya bütün stratejinin ispatı değildir. Araştırma, district, enerji/nüfus desteği, bakım, yuva, tekrar fiyatı ve sonraki roket harcamaları ayrıca hesaba girer.

| Bina, diğer etkiler olmadan | Dakikalık katkı | Referans kredi karşılığı | Taban kredi | Basit geri dönüş |
| --- | --- | ---: | ---: | ---: |
| Mine | 30 Ferrite | 60 | 200 | 3,33 dk |
| Market | 60 kredi | 60 | 150 | 2,5 dk |
| Lab | 12 Science | 60 | 150 | 2,5 dk |
| Habitat + iki nüfus gelir skilli | 25 kredi + 5 Science | 50 | 120 | 2,4 dk; skill bedeli hariç. |

Gerçek satışta Mine 54 kredi/dk, Lab 54 kredi/dk sağlar; referans fiyat ile elde edilen kredi aynı şey değildir. Habitat'ın 5 Science'ını da satarsa toplam 47,5 kredi/dk olur. Lab'ın bütün Science'ını satması araştırma stokunu büyütmez; bu bilinçli strateji tercihidir.

Üç gelir ailesi aynı mertebede tutulur; biri her koşulda eşit veya üstün ilan edilmez. Nüfus yolu daha çok konut/enerji alanı, bilim yolu araştırmaya doğrudan erişim, sanayi yolu malzemeyi doğrudan elde tutma avantajını taşır.

### İşleme kârı: girdiyi bedava saymadan

Aşağıdaki hesaplar Ferrite ve temel Tier 1 modeller içindir. Bir sütunda kendi hammaddesini satmak yerine işlemenin fırsat maliyeti, diğerinde hammaddenin tümünü trade'den alma maliyeti düşülür. Genel bakım/enerji/yerleşim maliyeti henüz düşülmemiştir.

| Üretici | Çıktı satışı / dk | Kendi Ferrite'ine göre net | Ferrite satın alınırsa net | Kredi / satın alınan girdide geri dönüş |
| --- | ---: | ---: | ---: | ---: |
| Goods Factory: 12 Ferrite -> 6 Goods / dk | 118,8 | 97,2 | 92,4 | 300 / 92,4 = 3,25 dk |
| Kompakt Fuel: 24 Ferrite -> 6 Fuel / dk | 183,6 | 140,4 | 130,8 | 450 / 130,8 = 3,44 dk |
| Rare Forge: 36 Ferrite -> 3 Rare / dk | 248,4 | 183,6 | 169,2 | 600 / 169,2 = 3,55 dk |

Bu fiyat seçimi Fuel ve Rare'a daha ağır ham tüketimi karşılığında daha yüksek mutlak getiri verir; krediye göre ilk geri dönüşleri birbirine yakın kalır. Rare'ın çalışan/enerji ve araştırma yükü hâlâ farklıdır. Moonstone'un 1,75 dönüşümü Ay ekonomisini hızlandırır; bu artışın bütün toplam süreye etkisi oynanışta ölçülmeden kesin dengeli sayılmaz.

### Tekrar fiyatı ile alternatif karar

Beş aynı Lab: 150 + 180 + 216 + 259,2 + 311,04 = **1.116,24 kredi**, 5 yuva ve 1.250 çalışan. Bir Institute 450 kredi, 1 yuva ve 750 çalışanla üç Lab'ın ham çıktısını verir; araştırma, Goods kuruluşu ve bakım ister. İkinci district, yeni coğrafya ve konut yatırımını da seçenek olarak gösteren arayüz, sadece aynı `+` düğmesine basıp giderek bekleme alışkanlığını azaltır.

### Oyuncu akışı için somut korumalar

- Başlangıç 3.000 kredi ve 450 Science, ilk strateji kurulumunu birikim beklemeden başlatır.
- Temel bakımsız ve küçük modeller hiçbir üst model açılınca kaybolmaz.
- Yeni bina açılışı büyük bir tek ödeme istiyorsa küçük üretici, farklı tür, district seviyesi ve trade seçenekleri açık kalır.
- Aynı tür tekrarı krediyle büyür; bütün isimli malzemeler ikinci kez aynı katsayıyla şişmez.
- Fuel/Rare'ı araştırma açar; gereksiz gezegen seviyesi veya zorunlu istasyon zinciri açmaz.
- Malzeme birikimi ve roket hazırlığı sürerken oyuncu diğer yerleşimlere yatırım yapabilir.

30-90 saniyelik karar aralığı ve 45-75 dakikalık demo, bu korumaların hedefidir. Hesap tabloları tek başına bu aralıkları doğrulamaz; gerçek geri bildirime göre önce ortak katsayılar değiştirilir, her binaya ayrı gizli istisna eklenmez.

## 23. Gerçekten açık kalan kararlar

Yeni sorular **K** ile işaretlendi; cevaplanmış S01-S48 tekrar sorulmuyor. Matematik katsayılarını burada sana geri paslamıyorum. Aşağıdakiler anlam/kapsam tercihleri; her biri ilgili bölümde de anılıyor.

| Soru | Konu ve benim önerim | Cevabın |
| --- | --- | --- |
| **K01** | Trade'de Science satışı kesin. **Önerim: krediyle Science da alınabilsin; Fuel/Rare ise araştırması açılınca fabrika kurulmadan alınabilsin.** Böylece ticaret/nüfus oyuncusu lab zincirini zorunlu kurmaz. Bu kapsamı kabul ediyor muyuz? | Henüz cevaplanmadı. |
| **K02** | Offline için “en fazla 10x” derken neyi 10 ile çarpıyoruz? **Önerim: en fazla 10 gerçek saatlik kapalı süre sayalım; 1/10 ile 1 saat ekonomi ilerlesin.** Başka birimi kastettiysen onu yazman yeterli. | Henüz cevaplanmadı. |
| **K03** | Demo sonrasında üst haritaları incelemek kesin. **Önerim: hedef gezegende kuruluş kapalı kalsın, eski dünya ve Ay'da oynamaya devam edilebilsin.** Yoksa varıştan sonra bütün ekonomi dursun ve yalnız inceleme mi kalsın? | Henüz cevaplanmadı. |
| **K04** | Tip 1'de canlı City türü sonradan değişebiliyor. **Önerim: kuruluşta seçilen planın fiyat ailesi sabit kalsın; sonradan otomatik hesaplanan işlevsel tür değişsin.** Özel planda da hedef aile önceden seçilir. Böylece geçici tür değiştirip tekrar fiyatı düşürülemez. Canlı tür ile fiyat ailesinin farklı kalmasını kabul ediyor muyuz? Bu yalnız gelecek Tip 1 kuruluşunu etkiler. | Henüz cevaplanmadı. |
| **K05** | Eski tutorial para/Science/eksik stok yardımları yeni başlangıç bütçesine eklenirse iki farklı yardım sistemi oluşur. **Önerim: eski ekonomik yardım ve tekrar ödül yolları devreden çıksın; yeni görev paneli ödülsüz olsun.** Tutorial metninin/seed'inin yeniden tasarımını yine sonraya bırakalım. Bu ayrımı kabul ediyor muyuz? | Henüz cevaplanmadı. |

**K04 örneği:** Oyuncunun “Riva” adını verdiği Science planı zamanla daha çok Production districti içerirse görünen türü Production City olur; tarihsel kuruluş ailesi Science sayacında kalır. Bu öneri kabul edilmezse tür değişimine fiyat düzeltmesi gibi başka bir kural gerekir. Tip 0'da City tür fiyatı olmadığından mevcut demo bu soru yüzünden kilitlenmez.

Fraktal ağacın satın alma/reset biçimi, tutorial/random başlangıç ve yörünge ayrıntıları askıdaki ayrı çalışmalar. Bunları şimdi cevaplaman Tip 0 tasarımının okunması için gerekmiyor. Bu belgenin hesabı bu fikirler kesinleşmiş gibi yapılmadı.

## 24. Önceki yorumlar ve cevaplar için izleme tablosu

Bu bölüm karar kaybını önler. **İlk 48 yorum**, **S01-S48 cevapları** ve **sonraki 9 seçim yorumu** ayrı numara dizileridir. Son cevabın değiştirdiği eski karar, eski haliyle uygulanmayacak.

### İlk plan üzerindeki dört açıklama

- Act yerine kullanıcının görseli ve sonradan doldurduğu Tip 0-5 katman/merkez sırası kullanıldı. Bölüm 2-3. :codex-annotation{index="1"}
- Tip 0 sınırı, Ay'a çıkıştan sonra yeni roketle seçilen gezegene varış olarak kesinleştirildi; demoda oraya City kurulmaz. Bölüm 2 ve 15. :codex-annotation{index="2"}
- Denge önerileri, yeni bina/skill rolleri ve basit hesap örnekleri eklendi; önerilmiş sayı ile kullanıcı kararı ayrıldı. Bölüm 6-18 ve 22. :codex-annotation{index="3"}
- Bina ve skill karşılaştırmalarında bedel, tüketim, çıktı, çalışan, açılış ve rol birlikte gösterildi. Eski değerler için ilk mekanik envanteri, yeni hedefler için bu V2 kullanılır. Bölüm 13-14. :codex-annotation{index="4"}

### İlk 48 yorumun güncel karşılığı

| Yorum | V2'de uygulama kararı / güncel karşılık | Bölüm |
| ---: | --- | --- |
| 1 | Act 1 tamamlandı yerine Civilization Type 0 tamamlandı. | 2, 21 |
| 2 | Eski engelleyici demo paneli değişir. Son cevapla demo seçilen gezegene varışta biter; üst ölçek önizlemeleri o zaman açılır. | 2, 19 |
| 3 | Genel gemi/filo/kargo altyapısı kullanılmaz. | 2, 13, 20 |
| 4 | Ay'da madeni çıkar, özel Spaceport ve daha iyi roketle başka gezegene var. | 15 |
| 5 | Bilim/nüfus/ticaret/sanayi stratejileri; bütün üretici zincirleri zorunlu değil. | 6, 14, 17, 22 |
| 6 | Tutorial seed'i ve farklı başlangıç gövdeleri son cevaplarla askıda. | 20 |
| 7 | Dört katman her medeniyette yükselir. Son düzeltmeyle yalnız Tip 0 binası konumsuz; diğer alt nesneler otomatik/elle yerleşir. | 3-4 |
| 8 | Nüfus ortak imparatorluk kapasitesidir. | 6 |
| 9 | Goods/Fuel/Rare kuruluşta ve bakımda anlamlı kullanılır. | 10, 13 |
| 10 | Taşma kuralı S15 ile değişti: trade öncesi kayıp, trade sonrası krediye dönüşüm taslağı. | 17 |
| 11 | 12 ham kaynak medeniyet tiplerine bölünür; sistem uzaklığı hepsini açmaz. | 5 |
| 12 | Girdiyi oyuncu seçer; en nadir stok kendiliğinden tüketilmez. | 5, 10 |
| 13 | Goods/Fuel/Rare sırasıyla 4:2, 8:2, 12:1; aynı 20 saniyelik temel tur. | 10, 22 |
| 14 | %50 kredi iadesi, skill ile %75'e kadar. | 12, 14 |
| 15 | Bina level'ı yok. | 13 |
| 16 | Tier başına çalışan ×3; küçük modeller açık yarım profil. | 9, 13 |
| 17 | Bina tekrarı yalnız aynı districtte aynı türü sayar. | 11 |
| 18 | District tekrarı yalnız aynı City'de aynı türü sayar. | 11 |
| 19 | Tip 0 normal City türsüz; Tip 1'de City türleri ve aynı tür fiyatı. Canlı tür/fiyat ayrımı K04. | 4, 11, 23 |
| 20 | Gerçek üretim/bakım olmayan kartta sahte saniye alanı yok. | 10, 13 |
| 21 | Sürekli saha yüzdesi yerine görünen arazinin üç uygunluk durumu. | 7 |
| 22 | Yakın/uzak başlangıçtan çalışan, farklı yerleşim ve skill yatırımlarıdır. | 8, 14 |
| 23 | Residential yakınlığının katkısı konuta gider; normal yakınlıkta kredi çapraz tablosu kalkar. | 8 |
| 24 | Capital merkez desteği; normal district aynı türe; farklı tür katkısı açık skill/özel yapı. | 8, 14 |
| 25 | City ikinci Capital değildir; Capital kendi City'sinde doğrudan yol bağlantılı hedeflere. | 3, 8 |
| 26 | Yol kesişimi ve kalınlık bonusu kalkar. | 8 |
| 27 | Derece yerine fiziksel yüzey uzaklığı, oyuncuya beş anlaşılır etiket. | 8 |
| 28 | District seviyesi ×1,25; yuva/maliyet/çalışan birlikte yeniden düzenlenir. | 9 |
| 29 | Son S09 cevabı genel ham ödeme seçimini değiştirir: kuruluş/yükseltme isimli sabit kaynak ister. Üretim girdisi oyuncu seçimidir. | 5, 9-11 |
| 30 | Zor bina daha fazla malzeme/bakım ister; yoğun çıktı karşılık verir. | 11, 13 |
| 31 | Wind'in özel konum şartı karşılıksız kalmaz; görünen rüzgâr bölgesi. | 7, 13 |
| 32 | Tier 4 başlangıç açık/katalog istisnaları kaldırılır. | 13-14 |
| 33 | Bütün medeniyetleri hissettiren büyük skill ağacı önizlemesi. | 19 |
| 34 | Strateji dalları ve birleşmeler; hafif çapraz dal fiyatı, seçim sınırı yok. Fraktal fikir askıda. | 14 |
| 35 | Alt butonlar rolüne uygun kuruluş yerlerini vurgular ve önerir. | 19 |
| 36 | Gövde boyutu aynı fiziksel aralıklarla daha az/çok yerleşim taşır. | 8 |
| 37 | Dağ dışındaki görünen volkan, göl, tundra, eski yerleşim vb. genişletildi. | 7 |
| 38 | Eski doğal saha puanları ekonomik hesap ve lenslerden tamamen kalkar. | 7, 19, 21 |
| 39 | Tutorial yeniden yazımı son cevapla askıda; eski yardımın durumu K05. | 20, 23 |
| 40 | Offline varsayılan açık, isteğe bağlı kapatma, ortak saat 1/10; sınırın anlamı K02. | 18 |
| 41 | Yeni kaynak türü yok. | 5 |
| 42 | Üst tier yuva kazandırır; yatırım, çalışan ve bakım bedeli vardır. | 9, 13 |
| 43 | Küçük ara bonuslar üç basit seviyede, toplamları açık. | 14 |
| 44 | Her bina kendi district ailesinde. | 13 |
| 45 | Her yeni bina için rol/bedel; ekonomik kopya Regolit modeli ayrı kaçış türü yapılmaz. | 13 |
| 46 | Yeni skill havuzu dallara dağıtıldı; Fuel/Rare erken Science kapısı. | 14 |
| 47 | Yeni alt butonlar uygulama sırasına alındı. | 19, 21 |
| 48 | Üç uygunluk, district ve ilgili binaya etki, öneri, eski kaynak görünümünün kaldırılması. | 7, 19 |

### S01-S48 cevaplarının işlenmesi

| Cevap | İşlenen sonuç | Bölüm |
| --- | --- | --- |
| S01 | Seçilmiş gezegene varış Tip 0 sonu/Tip 1 başlangıcı; hedefte City yok, demo orada. | 2, 15 |
| S02 | Kullanıcının dosyada doldurduğu altı katman satırı aynen temel alındı. | 3 |
| S03 | Otomatik plan + isteğe bağlı zoom/elle yönetim; aynı nesneler. | 4 |
| S04 | Kullanıcının merkez tablosu; City konumu doğrudan kendi konumu. | 3, 7 |
| S05 | Konut/yük modeli, zamanla nüfus büyümesi yok. | 6 |
| S06 | Nüfus cezası bütün imparatorluğa. | 6 |
| S07 | Kullanıcının 12 kaynak dağılımı aktarıldı. | 5 |
| S08 | Medeniyet + uygun yerel Production olmadan kaynak adı/ikon/stok/fiyat görünmez. | 5, 17, 19 |
| S09 | Genel raw ödeme yerine ayrı isimli kaynak listeleri. | 5, 9-11 |
| S10 | Mevcut nadirlik dönüşüm katsayısı korundu. | 5, 10 |
| S11 | Seçili girdiye göre gruplar; çalışan/bekleyen adet ve çıktı açık. | 5 |
| S12 | 4:2 Goods, 8:2 Fuel, 12:1 Rare kabul edilmiş tarifler. | 10 |
| S13 | Fuel/Rare Science ilerlemesine bağlı; Lv2-3/Lv4 yalnız tempo referansı. | 14 |
| S14 | Kuruluş ve bakımda işlenmiş malzeme tüketimi. | 10-13 |
| S15 | Trade öncesi taşma kaybolur, erken trade sonrası satış. | 17 |
| S16 | Bina district yerel, district City yerel aynı tür sayacı. | 11 |
| S17 | Yıkım mevcut adet sayacını düşürür. | 11 |
| S18 | Her ödemeyi ayrı tutmadan N/C gerçek ödeme ortalaması. | 12 |
| S19 | %75 azami iade. | 12, 14 |
| S20 | Coğrafya normal/yakın/üzerinde; yakında yarım. | 7 |
| S21 | Farklı arazi türlerinin etkileri toplanır. | 7 |
| S22 | Özel kuruluş gerekli alanın üzerinde; yakında genel yarım etki. | 7, 13 |
| S23 | Çok yakın, yakın, orta, uzak, çok uzak etiketleri. | 8 |
| S24 | Fiziksel mesafe + gövde boyutu; medeniyette artan arka plan birimi. | 8 |
| S25 | Capital doğrudan yol bağlantısına bonus. | 8 |
| S26 | Normal yakınlık geometrik, sert kaynak sayısı yok, aradaki nesne kesmez. | 8 |
| S27 | Temel bonuslar açık; uzmanlık skill yatırımıdır. Tek districtte yasaklayıcı yakın/uzak seçimi yok. | 8 |
| S28 | Etki district tabanına ve uygun binasına, bir kez. | 7-9 |
| S29 | Çalışan artışı ×3; başlangıç bütçesi/küçük modeller/kapılarla akış taslağı. | 9-14, 22 |
| S30 | Üstel district, yumuşak maliyet, beklerken alternatif kararlar. | 9, 22 |
| S31 | Görünen rüzgârlı bölge ve Wind/Sırt Türbini. | 7, 13 |
| S32 | Orbit City rolü, içinde district düzeyinde içerik; ayrı alt tasarım. | 13, 20 |
| S33 | Düşük tier düşük yatırım/iş gücü, yüksek tier yoğunluk. | 13 |
| S34 | Diğer dallara küçük fiyat etkisi, seçim sınırı yok; fraktal üst skill henüz fikir. | 14 |
| S35 | Satın alınmış etkiler sürer. | 14 |
| S36 | Grafik birleşmesinde herhangi bir ebeveyn yeterli. | 14 |
| S37 | Boş uygun konuttan kredi/Science/üretim skill etkileri. | 6, 14 |
| S38 | Kaynağı yerinde çıkaracak uygun nesne gerekir; ürünlerin temini esnek, özel Spaceport zorunlu. | 5, 15, 17 |
| S39 | İstenen hedef gezegen, mesafeden bağımsız demo seferi, hedefte kuruluş yok. | 2, 15 |
| S40 | Yer önerileri oyuncunun stratejisini dikkate alır. | 19 |
| S41 | Ayrıntılı üst harita incelemesi yalnız demo sonrasında. | 19 |
| S42 | Tutorial başlangıç tasarımı askıda. | 20 |
| S43 | Sabit tutorial seed kararı askıda. | 20 |
| S44 | Alternatif random/gövde başlangıcı ve bağlı ağaç askıda. | 20 |
| S45 | 1/10 kesin; “10x” üst sınır birimi K02. | 18, 23 |
| S46 | Offline üretim, girdi, bakım, otomatik trade, inşaat, yükseltme, uçuşu kapsar. | 18 |
| S47 | Offline varsayılan açık; kapatılabilir. | 18 |
| S48 | Eski kayıt taşıma zorunluluğu yok; yeni şema. Mevcut kayda dokunulmadı. | 20 |

### Sonraki dokuz seçim yorumu ve ek fikirler

| Yorum / ek | V2 karşılığı | Bölüm |
| --- | --- | --- |
| Son seçim 1 | Yalnız Tip 0 binası konumsuz; üst medeniyetin alt nesnesi gerçek konumlu, otomatik plan/elle düzenleme. | 4 |
| Son seçim 2 | Yeni yerleşimde otomatik merkez; Tip 1 gezegende Orbital City. | 3 |
| Son seçim 3 | Yanlış seçim dikkate alınmadı; dosyadaki kullanıcı düzeltmesi kullanıldı. | 3 |
| Son seçim 4 | Yanlış seçim dikkate alınmadı; kullanıcı merkez tablosu kullanıldı. | 3 |
| Son seçim 5 | Farklı başlangıç gövdesine göre kaynak/ağaç uyarlama askıda. | 20 |
| Son seçim 6 | Mevcut yerleşimlere en çok tamamlanmış alt tür sayısıyla tür; isim korunur, kendi planını kurma mümkün. | 4 |
| Son seçim 7 | Üç coğrafya kademesi kabul edildi. | 7 |
| Son seçim 8 | İlk bakışta okunacak 22 görünür coğrafya adayı ve katkıları. | 7 |
| Son seçim 9 | Boş Ay tablosu yerel çıkarım, binalar, bedel/süre/roket/hedef ile dolduruldu. | 15 |
| Görev sistemi eki | Sürekli ana hedef + ara görev + gelecekte narrative hook. | 16 |
| Fraktal skill eki | Önceki ağacın üst medeniyette tek skille özetlenmesi askıda; kesin reset/ödeme yapılmaz. | 14 |
| Konuşulmayanları sor eki | Beş yeni kapsam/anlam sorusu; oranlar ve hesaplar dolduruldu. | 23 |

### Bu dosya üzerinden sonraki revizyon

K01-K05 için numarayla cevap verilebilir. Sayısal tablolarda ise “şu aile çok hızlı/yavaş”, “şu binanın bedeli ağır”, “şu yaklaşımın getirisi daha yüksek olsun” gibi yorum yeterli; yeni katsayıları ben yeniden hesaplarım. Kullanıcının doğrudan dosyada değiştirdiği değerler sonraki sürümün girdisi olarak okunacak.

Bu belge yazılırken yalnız yeni V2 Markdown oluşturuldu. Oyun kaynakları, eski iki Markdown, ayarlar ve kayıt dosyaları değiştirilmedi; motor veya oyun testi çalıştırılmadı.



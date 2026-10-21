# Voidle büyük güncelleme: kararlar, uygulama sırası ve açık sorular

Sürüm: 1.0 tasarım taslağı  
Tarih: 19 Ekim 2026  
Dayanak: Oyuncu tarafından sırasıyla verilen 48 yorum ve [mevcut mekanik envanteri](C:/Users/drosm/Voidle/MEDENIYET_0_MEKANIK_VE_MATEMATIK.md).

**Bu dosya hedef tasarımı anlatır. Oyunun güncellenmiş durumu değildir. Bu çalışma kapsamında yalnızca bu yeni Markdown dosyası oluşturuldu.**

Önceki envanter mevcut sistemi kaydeder. Bu belge ise onu değiştirecek kararları toplar. Bir çelişki olduğunda aşağıdaki kesin kullanıcı kararları esas alınmalıdır. Eski dosyadaki örnek sayıların bu belgeye otomatik olarak onaylanmış denge değerleri şeklinde taşınmaması gerekir.

## 0. Belgenin kullanım şekli

| Durum | Anlamı |
| --- | --- |
| **Kesin karar** | Kullanıcının açıkça istediği hedef davranış. Aynı karar yeniden onaya sunulmuyor. |
| **Taslak** | Kararı somutlaştıran öneri, örnek sayı veya henüz kesinleşmemiş fikir. |
| **Açık soru** | Uygulamadan önce cevabı gereken tasarım tercihi. |
| **Ayrı çalışma** | Bilinçli olarak sonraya bırakılan tasarım. Özellikle trade. |

Açık soruların benzersiz numarası var: **S01, S02...** Yanıt verirken yalnız bu numaraları kullanmak yeterli. Capital eşleme tablosundaki boşluklar da ayrıca doldurulabilir. Sorular ilgili konunun altında bulunur.

Bu belgede bütün işleri sıralamak, kod değişikliği veya test yetkisi vermez. Oyun güncellemesine ayrıca komut verilecek. Testler kullanıcıya bırakılacak.

### Güncellemenin omurgası

```text
Medeniyet ölçeği ve geçiş kuralları
  -> Ortak ekonomi ve kaynak erişimi
  -> Oyuncunun girdi/ödeme seçimi, kayıpsız stok ve satın alma kayıtları
  -> Görünür coğrafya, mesafe ve komşuluk
  -> Bina/tier/district dengesi
  -> Stratejiye göre dallanan skill tree
  -> Ay ekonomisi ve Tip 0'dan Tip 1'e geçiş
  -> Önizlemeler, yerleşim önerileri, tutorial
  -> İsteğe bağlı offline ilerleme
```

Trade tasarımı ayrı yapılacak. Ancak farklı oyun tarzlarının çalışması, taşan kaynakların kullanılması ve son sayısal denge trade kararlarıyla birlikte ele alınmalı. O zamana kadar bu bağımlılıklar tamamlanmış özellik gibi gösterilmeyecek.

## 1. Medeniyet adları, bitiş ve önizleme ayrımı

İlgili yorumlar: **1, 2, 3, 4, 33**.

### Kesin kararlar

- Act 1/2/3 anlatımının yerini **Civilization Type 0/1/2/3/4/5** medeniyet yapısı alacak. Türkçe anlatımda Medeniyet Tip 0 vb. kullanılabilir.
- Eski demo bitiş paneli kaldırılacak. Ay'da ilk City tamamlanması oyunu bitirmeyecek.
- **Tip 0'ın son bölümü Ay'da oynanacak.** Ay madenleri işlenecek, bu ekonominin sağladığı yeni binalar ve gelişmiş roketlerle Ay'dan başka bir gezegene yolculuk eşiğine ulaşılacak.
- Medeniyet tamamlanması oyuncunun devam etmesini engelleyen bir panel olmayacak. İlerleme akışı sürecek.
- Solar View, gökada, evren ve çoklu evren ölçekleri oyuncuya gösterilebilecek. Kilitli ölçekte görmek, orada ekonomi yönetebilmek anlamına gelmeyecek.
- Genel gezegenler arası filo, kargo, gemi görev planlayıcısı ve sevk altyapısı bu güncellemenin oynanış temeli olmayacak.
- Ay'dan yapılan gelişmiş roket yolculuğu, **ilerleme olayı** olarak ele alınacak. Bu karar bütün uçuş görsellerini kaldırmak veya Ay seferini kaldırmak anlamına gelmiyor.

### Yapılacak değişiklikler

- [ ] Ay'da ilk City tamamlanması ile medeniyet tamamlanmasını birbirinden ayır.
- [ ] Medeniyet durumunu tek bir açık ilerleme kaydıyla yönet.
- [ ] Eski `act1_complete` anlamını yeni hedefe göre değiştir; kayıt uyumluluğunu ayrıca koru.
- [ ] Demo panelini ve oyuncuya demo bittiğini söyleyen metinleri kaldır.
- [ ] Üst ölçekler için **görünürlük izni** ile **oynanış iznini** ayır.
- [ ] Kilitli önizlemede inşa, ödeme, kolonizasyon, üretim ve skill satın alma işlemlerini açma.

### Açık soru

- **S01:** Tip 0'ın tamamlanma anı gelişmiş roketin hazır olması mı, Ay'dan ilk kalkış mı, yoksa başka gezegene ilk varış mı? Önerim ilk başarılı varış. Kesin olan, ilk Ay City'sinin bu olay olmayacağı.

## 2. Her medeniyette aynı dört katmanın ölçek değiştirmesi

İlgili yorumlar: **7, 19, 25**.

### Kesin ölçek sözleşmesi

Her medeniyette dört katman olacak. Üst katman kapsayıcı harita, sonraki iki katman haritadaki yerleşimler, en alt katman ise soldaki ebeveyn panelinde listelenen içerikler olacak.

| Medeniyet | Kapsayıcı harita | Haritadaki büyük yerleşim | Haritadaki alt yerleşim | Yalnız solda listelenen en alt içerik |
| --- | --- | --- | --- | --- |
| Tip 0 | Gezegen | City | District | Bina |
| Tip 1 | Güneş sistemi | Gezegen | City | District |
| Tip 2 | Gökada | Güneş sistemi | Gezegen | City |
| Tip 3 | Galaksi | Gökada | Güneş sistemi | Gezegen |
| Tip 4 | Evren | Galaksi | Gökada | Güneş sistemi |
| Tip 5 | Paralel Evrenler | Evren | Galaksi | Gökada |

Kurallar:

- Tip 0'da bina için haritada ayrı konum seçilmeyecek. Bina district panelinde bulunacak.
- En alt nesnenin kendine ait yakınlık, uzaklık veya coğrafya hesabı olmayacak; ebeveyninden etkilenecek.
- Tip 1'de district en alt içerik olurken, City önceki districtin harita rolünü üstlenecek. Gezegen önceki City'nin harita rolünü üstlenecek.
- Tip 2'de City en alt içerik olacak; aynı ilişki sistemi daha büyük ölçekte oynanacak.
- Haritadaki iki yerleşim katmanı konum ilişkilerine katılabilecek. Kaynaklar daha büyük ölçeğe geçti diye yeni kaynak türleri oluşturulmayacak.
- Üst ölçekte coğrafyanın anlamı değişebilir: yıldıza yakınlık, belirli kozmik bölgeler, elmas yağmuru alanları veya kara deliğe yakınlık gibi görünen konum özellikleri düşünülebilir. Bunlar şu anda kesin bonus kataloğu değildir.

### Tip 3-5 için henüz çözülmemiş ölçek

Tip 2'den sonra doğrudan evrene çıkılırsa bir sonraki adım çoklu evren olur ve Tip 5 için ek bir üst ölçek gerekir. Gönderilen ilk görselde Tip 5 çoklu evren olduğu için burayı kendiliğimden doldurmuyorum.

**Yalnız öneri:** Araya gökada grubu/kümesi eklemek, Tip 3 = küme, Tip 4 = evren, Tip 5 = çoklu evren sırasını sağlayabilir. Bu seçilmiş karar değildir.

### Capital karşılıkları: kullanıcının dolduracağı tablo

Capital District, Tip 0'da bir City'nin merkezi districtidir. Üst ölçekte onun işlevsel karşılığı değişecek. Aşağıda yalnız rolün yerini tarif ediyorum; özel adları sen dolduracaksın.

| Tip | Merkezin ait olduğu ana yerleşim | Merkezin bulunduğu alt katman | Merkezin adı | Kendi temel katkısı / dağıttığı bonus |
| --- | --- | --- | --- | --- |
| 0 | City | District | Capital District | Diğer districtlere bonus |
| 1 | Gezegen | City | Orbital City | Diğer City'lere bonus |
| 2 | Güneş sistemi | Gezegen | Dyson Sphere Gezegen   | Diğer gezegenlere bonus |
| 3 | Gökada | Güneş sistemi | Stellar Engine System  | Diğer güneş sistemlerine bonus |
| 4 | Galaksi | Gökada | Black Hole Gökada  | Diğer gökadalara bonus |
| 5 | Evren | Galaksi | Spacetime Galaksi  | Diğer galaksilere bonus |

**City konteyneri ile Capital District aynı nesne değildir.** Tip 0'da City kendi başına ek bir komşuluk bonusu dağıtmayacak. Dağıtıcı fiziksel merkez Capital District olacak. City seviyesinin kapasite işlevi ayrı bir konudur.

City'nin konumundan doğacak yakınlık/uzaklık ve coğrafya etkilerinin Capital üzerinden mi taşınacağı merkez tablosunda netleştirilmeli. City'ye ayrıca ikinci, gizli bir komşuluk bonusu eklenmiş sayılmıyor.

### Açık sorular

- **S02:** Tip 3-5'in dört katmanını nasıl tamamlayalım? Gökada kümesi ara ölçeği kullanılsın mı?
- **S03:** Bir medeniyet ilerleyince önceki en alt katmanın mevcut yatırımları otomatik üretim olarak yeni ölçekte toplanacak mı, yoksa eski ayrıntılı ekrana dönülüp yönetilebilecek mi?
- **S04:** Capital tablosundaki merkez adları ve dağıtacakları temel katkılar ne olacak? Tabloyu doğrudan doldurabilirsin. Tip 0'da City konumunun coğrafya/yakınlık/uzaklık katkıları da Capital üzerinden mi işlesin?

## 3. Nüfus bütün imparatorluğun ortak kapasitesi olacak

İlgili yorumlar: **8, 16, 42**.

### Kesin kararlar

- Nüfus gezegene özel havuz olmaktan çıkacak.
- Konut katkıları ve çalışan/altyapı ihtiyaçları imparatorluk toplamında hesaplanacak.
- Ana gösterim ortak havuzu gösterecek. Yerel panel yalnız o yerin toplam havuza katkısını ve kullandığı miktarı açıklayabilir; ayrı bir yerel nüfus kilidi oluşturmayacak.
- Üst tier çalışan ihtiyacı düzenli bir üstel büyüme kuralıyla ele alınacak. Bina tier yükselişi avantaj ve bedeli birlikte taşıyacak.

### Basit hedef hesap

```text
Ortak boş kapasite = imparatorluğun toplam konutu - toplam nüfus yükü
```

Bu, nüfusun gerçekten zamanla artan bir insan sayısı olmasına henüz karar verildiği anlamına gelmez. Mevcut kapasite modeli ile yeni demografik büyüme modeli ayrı tercihlerdir.

### Açık sorular

- **S05:** Nüfus şimdiki gibi konut/iş gücü kapasitesi olarak mı kalacak, yoksa zamanla büyüyen gerçek nüfus da eklenecek mi? Basitlik için kapasite modelini korumayı öneriyorum.
- **S06:** Ortak kapasite aşılırsa mevcut yavaşlama mantığı bütün imparatorlukta mı uygulanacak, yoksa farklı bir ortak ceza mı kullanılacak? Yerel gezegen cezası geri getirilmeyecek.

## 4. Kaynak listesi sabit, erişim medeniyet tipine bağlı

İlgili yorumlar: **9, 11, 41, 46**.

### Kesin kararlar

- Yeni kaynak türü eklenmeyecek.
- Mevcut **12 ham kaynak** korunacak.
- İşlenmiş kaynaklar **Consumer Goods, Fuel Rods, Rare Elements** olarak kalacak.
- Ham kaynakların temel ilerleme kilidi yıldız sistemi uzaklığı değil, medeniyet tipi olacak.
- Gelecekteki bir medeniyetin hammaddesine erken erişim, keşif veya trade gibi başka bir yolla medeniyet kilidini kendiliğinden aşmayacak. Kilidin tam kapsamı aşağıdaki soruda netleştirilecek.
- Fuel ve Rare üretim yolları mevcut akıştan daha erken açılacak. Bu, ileri medeniyet hammaddelerinin de erken açılacağı anlamına gelmeyecek.

### 12 hammaddenin dağılımı için taslak

Bu tablo **iki kaynak / medeniyet** şeklinde basit bir başlangıç önerisidir. İsimler mevcut; bu dağılım henüz onaylı değildir. İlk ikisinin Tip 0'da olması Ay ekonomisini mevcut kaynaklarla kurmaya uygundur.

| Tip | Ham kaynak adayları | Ana işlev / karar ihtiyacı |
| --- | --- | --- |
| 0 | Ferrite, Moonstone |  Ferrite metal yataklarında, Moonstone Ay regolitinde bulunur. Production Districtler bunları çıkarır ve işler. İnşaat, Goods ve roket hazırlığında kullanılır. |
| 1 | Cinderite, Cryolite |  Cinderite volkanik alanlarda, Cryolite buzlu alanlarda bulunur. Üretim City'leri bunları çıkarır ve işler. Sanayi ve Fuel Rods üretiminde kullanılır. |
| 2 | Dune Quartz, Helion |  Dune Quartz çöl bölgelerinde, Helion gaz bakımından zengin bölgelerde bulunur. Üretim gezegenleri bunları toplar ve işler. Gelişmiş yapılar ve işlenmiş ürünler için kullanılır. |
| 3 | Astralite, Aurorium |  Astralite kristal bakımından zengin güneş sistemlerinde bulunur. Aurorium metal bakımından zengin güneş sistemlerinde bulunur. Üretim güneş sistemleri bunları toplar ve işler. Bilim, enerji ve Rare Elements üretiminde kullanılır. |
| 4 | Xenite, Nyxium |  Xenite sıra dışı madde içeren gökadalarda bulunur. Nyxium karanlık bölgeleri olan gökadalarda bulunur. Üretim gökadaları bunları toplar ve işler. Üst tier yapılar ve işlenmiş ürünler için kullanılır. |
| 5 | Quantium, Singularite |  Quantium anomaliler içeren galaksilerde bulunur. Singularite yoğun kara delik bölgeleri olan galaksilerde bulunur. Üretim galaksileri bunları toplar ve işler. En ileri yapılar ve Rare Elements üretiminde kullanılır. | |

Gövde tipi kaynak seçimini etkileyebilir; fakat yalnız uzaktaki sisteme gidildi diye bütün kaynakların açılması kalkacak. Rastgele volkanik veya gaz başlangıcı fikri kabul edilirse bu tablo onunla ayrıca uyumlu hale getirilecek.

### Açık sorular

- **S07:** İki kaynak / medeniyet taslağı ve yukarıdaki isim sırası uygun mu? Değilse hangi kaynak hangi tipe taşınmalı?
- **S08:** Medeniyet kilidi kaynağın çıkarımını, satın alınmasını ve kullanımını birlikte mi kapatsın? Aynı medeniyet içinde kaynağı önce keşfetmek de şart olacak mı?

## 5. Üretim girdisini ve ham madde ödemesini oyuncu seçecek

İlgili yorumlar: **12, 29**.

### Kesin kararlar

- İşleme binası otomatik olarak en nadir hammaddenin tamamına yönelmeyecek.
- Oyuncu kullanılacak ham kaynağı seçecek ve karşılığında alacağı işlenmiş ürün miktarını görecek.
- Gezegen/seviye gibi ham madde isteyen ödemelerde hangi stokların harcanacağını oyuncu belirleyecek.
- Seçilen kaynak bittiyse başka kaynağa sessizce geçilmeyecek.
- Aynı binanın farklı kaynak kullanan kopyaları oyuncunun tercihini kaybettirecek şekilde tek kayıtta birleştirilmeyecek.

### Gösterilecek bilgiler

| Üretim paneli | Ödeme paneli |
| --- | --- |
| Seçilen ham kaynak ve eldeki stok | Gereken toplam miktar |
| Bir turda tüketilecek miktar | Kullanılabilir ham türleri |
| Bir turda alınacak ürün | Oyuncunun her türden ayırdığı miktar |
| Tur süresi ve gerçek koşullardaki çıktı | Ödeme sonrası kalacak stok |
| Neden beklediği | Ödeme onayı |

**Taslak davranış:** Girdi değişikliği devam eden tur bittikten sonra etkili olsun. Tur başında ödenen kaynak ile tur sonunda verilen ürün aynı tarif kaydına bağlı kalsın. Birleştirilecek üretim grupları aynı bina ve aynı girdi seçimini paylaşsın.

### Açık sorular

- **S09:** Bir yükseltme bedeli tek mineralden mi ödensin, yoksa oyuncu örneğin 100 Ferrite + 100 Moonstone seçerek karışık ödeme yapabilsin mi?
- **S10:** Daha nadir ham kaynağın daha çok işlenmiş çıktı vermesi korunacak mı? Korunacaksa mevcut nadirlik çarpanı mı sadeleştirilmiş başka oranlar mı kullanılacak?
- **S11:** Hammadde seçimi aynı tip binaların tümü için ortak mı olsun, yoksa oyuncu aynı districtte iki ayrı üretim grubu oluşturabilsin mi? Önerim farklı girdi seçimine göre ayrı gruplar.

## 6. Goods, Fuel ve Rare tarifleri ile üst tier kullanımı

İlgili yorumlar: **9, 13, 30, 42, 46**.

### Kesin kararlar

- Fuel, Goods'a göre daha fazla hammadde isteyen işlenmiş ürün olacak.
- Rare, Fuel ve Goods yüksek tier binaların anlamlı maliyet veya bakım girdilerinde kullanılacak.
- Daha zor kurulan bina daha büyük ödül verecek; aynı zamanda anlaşılır ek bedeli olacak.
- Bir ürünün üreticisi, onu zorunlu tüketen bina ailesinden önce erişilebilir olacak.
- Fuel ve Rare, yalnız oyunun sonuna sıkışmayacak; yeni bina seçeneklerini erken görünür kılacak.
- Bütün tarifler tek tek ele alınacak. Sadece bina fiyatını artırıp üretim maliyetini aynı bırakmak yeterli sayılmayacak.

### Karşılaştırma için basit tarif taslağı

Bu sayılar **yalnız tartışma başlangıcıdır**. En düşük ham kaynak, bonus yok ve tek bina referans alınmıştır. Mevcut tariflere uygulanmadılar.

| Ürün | Örnek girdi | Örnek çıktı | Bir ürün için ham maliyeti |
| --- | ---: | ---: | ---: |
| Goods | 4 ham | 2 Goods | 2 ham |
| Fuel | 8 ham | 2 Fuel | 4 ham |
| Rare | 12 ham | 1 Rare | 12 ham |

Bu tablo yalnız ham maliyeti karşılaştırır. Süre, enerji, çalışan, coğrafya ve girdi kalitesi ayrıca aynı tabloda gösterilecek. Nihai kârlılık, özellikle trade fiyatları belirlenmeden kanıtlanmış sayılmayacak.

### Üst tier için tasarım ilkesi

| Avantaj örneği | Karşılığındaki bedel örneği |
| --- | --- |
| Bir yuvada daha fazla üretim | Daha fazla çalışan ve Fuel bakımı. |
| Daha yüksek bilim üretimi | Rare tüketimi. |
| Daha fazla konut | Goods tüketimi ve enerji ihtiyacı. |
| Güçlü özel coğrafya verimi | Daha az uygun kuruluş alanı. |

### Açık sorular

- **S12:** Goods/Fuel/Rare için örnek ham maliyet sırası uygun mu? Kesin tarifleri bunun üzerinden mi kuralım?
- **S13:** Fuel ve Rare ilk City gelişiminde mi, City Lv2 civarında mı, yoksa gezegen Lv2'de mi açılmalı? Erken üreticilerin yolu yörünge zorunluluğundan bağımsız tutulabilir.
- **S14:** İşlenmiş ürünler yüksek tier binalarda hem kuruluş bedeli hem düzenli bakım olarak mı kullanılacak, yoksa bazı ailelerde yalnız biri mi olacak?

## 7. Taşan üretim korunacak, trade ayrı tasarlanacak

İlgili yorumlar: **5, 10, 41**.

### Kesin kararlar

- Tamamlanmış üretimin depoya sığmayan kısmı kaybolmayacak.
- Depo kapasitesi azalınca mevcut ürünler de silinmeyecek.
- Trade geldiğinde oyuncu fazla ürünlerini krediye çevirebilecek.
- Fazla Science -> Credits -> gereken hammaddeler yolu, farklı stratejileri mümkün kılacak tasarımın parçası olacak.
- Trade'in oranları, alış/satış sınırları ve otomasyonu bu belgede kesinleştirilmiyor. Trade ayrı konuşulacak.
- Science/kredi dönüşümü, yeni bir kaynak türü eklenmesi anlamına gelmeyecek.

### Kayıpsız depolama için öneri

Depo dolduğunda tamamlanan turun fazlası **bekleyen çıktı** olarak tutulabilir. Bu yeni kaynak türü değil, aynı ürünün teslim durumu olur. Yer açılınca veya trade ile satış yapılınca işlenir. Yeni turların başlaması sınırlandırılarak depo kapasitesi anlamlı kalır.

Örnek: Depo 200/200 Goods, biten turdan 8 Goods geldi. Sonuç 8 Goods'un silinmesi değil, **200 depoda + 8 bekleyen** bilgisidir.

### Açık soru

- **S15:** Fazla üretim bu bekleyen çıktı modeliyle mi korunsun, yoksa stok geçici olarak kapasiteyi aşsın ve yeni üretim dursun mu?

### Trade için sonraya bırakılan sorular

Alış/satış oranları, işlenmiş ürün alımı, Science satın alma, otomatik satış, işlem kapasitesi ve medeniyet/keşif kilitleri ayrı trade belgesinde cevaplanacak. Bu belge otomatik satış yapılmasına karar vermiyor.

## 8. Aynı tür fiyat artışı, yıkım iadesi ve City türleri

İlgili yorumlar: **14, 15, 17, 18, 19**.

### Kesin kararlar

- Bina fiyatı farklı bina türlerinin toplam adedinden etkilenmeyecek. Yalnız aynı bina türünü tekrar kurmak o türün fiyatını artıracak.
- District fiyatı da yalnız aynı district türünü tekrar kurmakla artacak.
- Artış oranları daha sonra dengelenecek. Eski %35 ve %60 yeni hedefin kesin katsayıları değildir.
- Tip 0'da City türü olmayacak. Bu aşamada yeni City uzmanlık türleri eklenmeyecek.
- Tip 1'de City önceki district rolüne geçtiğinde City türleri olacak. O aşamada aynı City türünü tekrar kurmanın fiyatı artacak. Bu gelecek gereksinim unutulmayacak.
- Bina seviyelendirme eklenmeyecek. Sonradan skill ile bu fikre dönmek yalnız gelecek olasılığı; şimdiki güncellemenin özelliği değil.
- Bina kaldırırken **temel %50 kredi iadesi** olacak. Skill ile artırılabilecek.

### Sayacın mantığı

```text
Bir binanın yeni fiyatı = kendi taban bedeli × yalnız kendi tekrar sayısının çarpanı
```

Market kurmak, aynı yerde ilk Research Lab'in fiyatını artırmayacak. Energy District kurmak, ilk Science District'in fiyatını artırmayacak. Bu örnekler uygun yerleşim kurallarını kaldırmaz; Research Lab yine Science District'e aittir.

### İade için önerilen hesap

İade, yeni katalog fiyatından değil **kaldırılan adedin gerçekten ödediği kredi bedelinden** hesaplansın. Örneğin 1.000 kredi ödenmiş binada temel iade 500 olur.

Bu nedenle aynı binanın 150, 200 ve 300 krediyle alınmış üç adedi birleşse de ödeme geçmişi korunmalı. Yeni satın almalarda malzeme bedeli eklenirse onun iade kuralı ayrıca tanımlanmalı.

### Açık sorular

- **S16:** Aynı tür tekrar sayacı bina için district içinde, district için City içinde mi tutulacak? Yoksa bazı sayaçlar gezegen/imparatorluk genelinde mi olacak? Önerim ilk seçenek.
- **S17:** Bir adet yıkılınca tekrar sayacı azalacak mı, yoksa satın alma geçmişindeki toplam sayı korunacak mı?
- **S18:** Gerçek ödenen kredi üzerinden %50 iade önerisini kullanalım mı? Bir yığından adet kaldırırken en son alınan adedin bedeli esas alınabilir.
- **S19:** Skill'lerle iadenin üst sınırı kaç olsun? İnşaat iptalinde ve malzeme bedellerinde de aynı iade kuralı mı geçerli olsun?

## 9. Sürekli saha yüzdeleri yerine görünen coğrafya

İlgili yorumlar: **7, 21, 35, 37, 38, 47, 48**.

### Kesin kararlar

- Sürekli değişen solar/wind/tidal/geothermal/mineral saha puanı sistemi kaldırılacak.
- Bonus, oyuncunun doğrudan görebildiği ve adı olan coğrafi özelliğe bağlanacak.
- Uygunluk basit kademelerle anlatılacak. Her noktada değişen %63, %67 gibi değerler gösterilmeyecek.
- Coğrafya yalnız yükseklikten oluşmayacak. Dağ, kıyı, göl, volkanik alan, tundra ve eski yerleşim gibi özellikler kullanılabilecek.
- Bina kendi bağımsız coğrafya puanını hesaplamayacak. Districtin konum koşulunu miras alacak.
- Districtin tabanı da içindeki ilgili binalar da coğrafyadan yararlanacak.
- Kaynaklara ait eski renkli yüzde katmanları kaldırılacak. Yeni uygunluk görünümü 16. bölümde tanımlanıyor.

### Basit uygunluk için taslak

| Kademe | Oyuncunun göreceği bilgi | Örnek çarpan |
| --- | --- | ---: |
| Normal | Özel avantaj yok. | ×1 |
| Uygun | Bu district ailesine uygun bir görünen özellik var. | ×1,25 |
| Çok uygun | Bu aileye güçlü uygunluk sağlayan görünen özellik var. | ×1,50 |

Bu çarpanlar onaylı denge sayıları değildir. Kullanıcının dağ varsa ×1,5, yoksa ×1 örneğini sade kademelere çevirmek içindir. Yalnız normal/uygun olmak üzere iki kademe de yeterli olabilir.

### Coğrafya aday tablosu

| Görünen özellik | Güçlendirebileceği rol | Henüz belirlenmeyen |
| --- | --- | --- |
| Dağ / yüksek arazi | Sanayi, gözlem ve bilim | Hangi ailenin hangi kademeyi alacağı. |
| Görünür maden yatağı | Sanayi | Ham türü medeniyet/gövde erişimine göre; bonus sabit uygunlukla. Eski sürekli yoğunluk yüzdesi geri getirilmeyecek. |
| Kıyı / göl kenarı | Konut, ticaret, belirli enerji aileleri | Göl ve denizin aynı etkiyi verip vermeyeceği. |
| Volkanik alan | Güçlü enerji veya ağır sanayi | Avantajın yanında enerji/bakım gibi bir bedel olup olmayacağı. |
| Tundra | Özel konut veya özel bilim yaklaşımı | Aynı kaynak listesini koruyarak ayırt edici işlevi. |
| Eski yerleşim | Bilim, ticaret veya kuruluş kolaylığı | Tek seferlik ödül mü, sürekli konum bonusu mu olacağı. |

### Aynı bonusun iki kez çarpılmaması

Örnek: Dağ coğrafyası ilgili sanayi üretimine ×1,5 veriyor. District tabanı 10, içindeki uygun bina 20 üretiyor.

```text
District tabanı: 10 × 1,5 = 15
Bina:            20 × 1,5 = 30
Toplam:                    45
```

Bina 20 ×1,5 ×1,5 yapılmayacak. District, coğrafyayı binaya **aktaracak**, aynı etkiyi ikinci kez oluşturmayacak.

### Açık sorular

- **S20:** İki uygunluk kademesi mi kullanalım: normal / uygun? Yoksa normal / uygun / çok uygun şeklinde üç kademe mi?
- **S21:** Bir nokta hem dağlık hem göl kenarıysa etkiler toplansın mı, yoksa ilgili üretim için yalnız en güçlü uygunluk mu uygulansın? Basitlik için en güçlü etkiyi öneriyorum.
- **S22:** Dağın yanında sayılmak için bir yakınlık alanı mı kullanacağız, yoksa districtin yerleşim noktası ilgili arazi etiketinin üzerinde mi olmalı? Bu kural bütün benzer özelliklerde aynı biçimde anlatılmalı.

## 10. Mesafe anlaşılır ve görsel boyuttan bağımsız olacak

İlgili yorumlar: **7, 27, 36**.

### Eski derece ne demekti?

Derece, gezegen merkezinden bakıldığında iki yüzey noktasını ayıran açıdır. Tam çevre 360 derecedir. 4 derece, çevrenin 1/90'ı demektir. Aynı açı büyük gezegende daha fazla kilometre eder.

Eski uzak yerleşim hesabı şöyleydi:

| En yakın diğer yerleşime açısal uzaklık | Eski kendi taban üretimi bonusu |
| ---: | ---: |
| 4 derece | %0 |
| 9 derece | +%30 |
| 14 derece ve üstü | +%60 |

Örneğin yalnız bu bonusu alan 10 taban üretim, 9 derecede 13, 14 derecede 16 olurdu. Bunlar **eski sistemi açıklayan sayılardır**, yeni uzaklık eşikleri değildir.

### Yeni hedef

- Oyuncuya derece hesabı yaptırılmayacak.
- Gezegenin çizimde küçük veya büyük olması aynı yerleşim düzeninin kurallarını kendiliğinden değiştirmeyecek.
- Mesafe için basit bir oyun birimi veya yakın/orta/uzak kademeleri kullanılacak.
- Minimum kuruluş aralığı, City erişimi ve uzaklık bonusu aynı anlaşılır mesafe dilini kullanacak.
- Bir üst medeniyete geçince aynı mantık o ölçeğin nesneleri arasında kullanılabilecek.

**Taslak anlatım:** Haritada “Yakın: komşuluk için uygun”, “Uzak: bağımsız yerleşim için uygun” gibi bölge işaretleri ve seçili noktada tek bir mesafe bilgisi gösterilsin. Görsel gezegen yarıçapını ekonomik katsayı olarak kullanmayalım.

Küçük gövdenin daha az yerleşim taşıması istenirse bu bir **kapasite kararı** olmalı. Mesafe biriminin oyuncuya gizlice değişmesiyle yapılmamalı.

### Açık sorular

- **S23:** Arayüzde “mesafe birimi” gibi bir sayı mı, yoksa yalnız yakın/orta/uzak etiketleri mi tercih ediyorsun? İkisi birlikte de gösterilebilir.
- **S24:** Ay ve büyük gezegenler aynı yerleşim kapasitesine mi sahip olsun? Boyut farkının ekonomik etkisi olacaksa bunu ayrı bir kapasite kuralıyla belirleyelim.

## 11. Komşuluk ve uzaklık iki ayrı strateji olacak

İlgili yorumlar: **7, 22, 23, 24, 25, 26, 27**.

### Kesin kararlar

- Capital District, yolla komşu olduğu districtlere kendi bonusunu dağıtacak.
- Yalnız aynı City altında olmak Capital bonusu almak için yeterli olmayacak.
- City konteynerinin kendisi ayrıca bonus dağıtmayacak.
- Normal districtler temel komşulukta yalnız kendi türünü destekleyecek: Energy -> Energy, Residential -> Residential vb.
- Çapraz tür ilişkiler kendiliğinden açık olmayacak; skill veya özel bina ile açılabilecek.
- Residential ilişkisi nüfus/konut rolünü destekleyecek; temel komşulukta kredi dağıtan varsayılan ilişki olmayacak.
- Yol kesişimi, yol kalınlığı veya aynı yol kesiminin daha çok kullanılması bonus vermeyecek.
- Yakın ağ kurmak ile uzak yerleşmek, skill ve bina seçimleriyle farklı güçlere sahip olacak. Biri her durumda diğerini geçmeyecek.

### Eski tablodaki okuma farkı

Eski `Residential -> 3 kredi` satırı Residential'ın kredi üretmesini değil, **City'nin Residential'dan kredi almasını** anlatıyordu. Yeni kararda bu eski ilişki de kaldırılıyor. Residential'ın yeni temel rolü nüfus/konut desteği olacak.

### Hedef ilişki tablosu

| Bonus kaynağı | Temel alıcı | Katkının yönü |
| --- | --- | --- |
| Capital District | Yol komşusu olan districtler | Capital'dan ilgili alıcıya. |
| Energy District | Aynı tür komşular | Enerji üretimi rolü. |
| Industrial District | Aynı tür komşular | Sanayi üretimi rolü. |
| Residential District | Aynı tür komşular | Nüfus/konut kapasitesi rolü. |
| Science District | Aynı tür komşular | Bilim üretimi rolü. |
| Commercial District | Aynı tür komşular | Kredi/ticaret rolü. |
| Özel skill/bina | Açıkça belirtilen başka tür | Yalnız satın alınan özel bağlantı. |

Normal aynı tür ilişkilerin çift yönde işlemesi doğal bir başlangıç taslağıdır; bonusun miktarı ve üst sınırı henüz seçilmedi. Bir districtin üretilmiş toplamını komşuya aktararak tekrar tekrar büyüyen bir hesap yerine, tanımlı sabit katkı veya taban üzerinden yüzde kullanılmalı.

### Stratejilerin anlamı

| Yakın ağ stratejisi | Uzak yerleşim stratejisi |
| --- | --- |
| Aynı tür kümeleri ve Capital bağlantısı. | Kendi başına güçlü yerleşimler. |
| Skill'lerle çapraz tür bağlantıları. | Skill'lerle bağımsız üretim / uzaklık avantajı. |
| Yerleşimleri bağlama ve alan paylaşma tercihi. | İyi coğrafyayı arama ve aralık bırakma tercihi. |
| Komşu sayısının sınırı önemli. | En yakın yerleşimin mesafesi önemli. |

Bu iki taraftaki örnekler henüz kesin sayısal bonuslar değildir. Aynı noktada her iki yaklaşımın bütün avantajları sınırsız alınarak tercih anlamsızlaştırılmayacak.

### Açık sorular

- **S25:** Capital için “yol komşusu” yalnız doğrudan tek yolun iki ucu mu olacak? Önerim evet; aradaki başka district üzerinden otomatik bütün City'ye yayılmasın.
- **S26:** Temel komşuluk katkısı sabit miktar mı, yoksa tabana göre yüzde mi olsun? Kaç komşuya kadar katkı alınabilsin?
- **S27:** Uzaklık bonusu hangi türlerde temel olarak açık olsun? Yakın ve uzak uzmanlık aynı districtte kısmen birlikte çalışabilsin mi, yoksa bu bir uzmanlık seçimi mi olsun?
- **S28:** Komşuluk ve uzaklık yalnız districtin kendi tabanını mı, içindeki uygun binaları da mı etkileyecek? Coğrafyanın ikisini de etkileyeceği kesin; diğer bonusların kapsamını ayrıca seçmeliyiz.

## 12. Üstel gelişim, tier dengesi ve gereksiz sayaçların kaldırılması

İlgili yorumlar: **15, 16, 20, 28, 30, 31, 42, 43**.

### Kesin kararlar

- Bina seviyeleri olmayacak. Tier, farklı bina ailesi/gelişim basamağı olarak kalacak; aynı binanın level düğmesi olmayacak.
- Çalışan ihtiyacı tier ile düzenli üstel büyüyecek.
- Üst tier, yuva verimi gibi bir avantajla çalışan/bakım gibi bir dezavantajı birlikte sunacak.
- District seviyesi üretim artışları incremental yapıya göre yeniden planlanacak.
- Üretim veya tüketim turu olmayan nesnede sahte saniye/tur alanı ve boş üretim çubuğu olmayacak.
- İnşaat süresi üretim süresinden ayrı kalacak. Depo gibi bir binanın üretim turu olmaması, inşaatının süresiz veya anlık olacağı anlamına gelmez.

### Çalışan için düzenli üstel örnek

Bu bir onaylanmış değer seti değil; her tier'da aynı çarpanı kullanmanın nasıl göründüğünü gösterir.

| Tier | Örnek çalışan: her adım ×3 |
| --- | ---: |
| 1 | 250 |
| 2 | 750 |
| 3 | 2.250 |
| 4 | 6.750 |
| 5 | 20.250 |

Bunun yanında üst tier'ın çıktı, konut veya enerji katkısı da incelenecek. Sadece çalışan sayısını büyütmek incremental denge kurmak için yeterli değildir. Konut binaları ve destek binalarının çalışan istisnaları ayrıca belirlenecek.

### District seviyesi için karşılaştırma

| Seviye | Mevcut artış | Örnek üstel artış: her adım ×1,5 |
| --- | ---: | ---: |
| 1 | ×1 | ×1 |
| 2 | ×1,5 | ×1,5 |
| 3 | ×2 | ×2,25 |
| 4 | ×2,5 | ×3,38 |
| 5 | ×3 | ×5,06 |
| 10 | ×5,5 | ×38,44 |

Eski sistemde her seviye tabana +0,5 ekliyordu. Örnek yeni sistemde her seviye önceki sonuca %50 ekler. Bu yüzden üst seviyelerde fark çok büyür. Hangi yolun uygun olduğunu karar vermeden, aynı tabloda maliyet, çalışan, yuva ve üretim birlikte görülecek.

### Hangi nesnede hangi zaman bilgisi görünecek?

| Nesne davranışı | Arayüzde zaman bilgisi |
| --- | --- |
| Tur sonunda malzeme/bilim/kredi üretir | Gerçek üretim turu ve ilerleme. |
| Belirli aralıkla Goods/Fuel/Rare tüketir | Gerçek bakım aralığı ve girdi. |
| Yalnız enerji akışı sağlar/tüketir | Akış miktarı; stok üretiyormuş gibi tur çubuğu yok. |
| Yalnız konut/depo/pasif bonus verir | Katkı ve varsa gerçek bakım; sahte üretim turu yok. |
| İnşaat halindedir | İnşaat süresi, üretim türünden bağımsız. |

### Energy ailesinin yeniden dengelenmesi

Solar Array, Wind Turbine, Tidal Generator ve diğerleri aynı tabloda karşılaştırılacak. Araştırma, özel coğrafya veya daha yüksek maliyet isteyen seçeneğin tercih edilmesi için görünür kazancı olacak.

Küçük kaynak düzeltmesi: Güncel dosyada Wind Turbine kıyı değil `wind` puanı koşuluna bağlı; kıyı şartı Tidal Generator'da. Yeni puan sistemi tamamen kaldırılacağı için gelecekteki Wind coğrafyasını ayrıca seçiyoruz. Bu, zor kurulan binanın karşılığını vermesi gerektiği kararını değiştirmiyor.

Küçük ara bonus düğümleri, belirli bir strateji boşluğunu dolduruyorsa eklenecek. Sırf düğüm sayısını artırmak için tekrar bonusları eklenmeyecek. 43. yorumdaki koşullu kabul bu şekilde yorumlandı.

### Açık sorular

- **S29:** Çalışan için örnek ×3 tier artışı uygun bir başlangıç mı? Konut ve destek binaları bu düzenin dışında mı kalacak?
- **S30:** District üretimi için üstel artış kullanalım mı? Örnekteki %50/adımın özellikle üst seviyelerdeki büyüklüğünü azaltmak ister misin?
- **S31:** Wind yeni coğrafyada kıyıya mı, yüksek sırtlara mı, yoksa bu iki alanın ikisine de uygun olsun? Özel koşulun hangi avantajla karşılanacağını sonra sayılandıracağız.

## 13. Yeni ve mevcut bütün binaların bir kuruluş nedeni olacak

İlgili yorumlar: **9, 15, 30, 31, 32, 42, 44, 45**.

### Kesin kararlar

- Her bina yalnız kendi district ailesine kurulacak.
- Daha çok bina çeşidi, hepsini aynı districtte zorunlu kurmak anlamına gelmeyecek.
- Bir binanın diğer bütün seçeneklerden her koşulda daha iyi olması hedeflenmeyecek.
- Her bina için oyuncunun “Bunu neden kurayım?” sorusunun kısa cevabı bulunacak.
- Tier 4 içeriğin başlangıçta açık görünmesi düzeltilecek. Skill, katalog, medeniyet ve seviye şartları aynı erişim kuralını kullanacak.
- Gelecek içeriğin önizlemede görülmesi bina kataloğunda kurulabilir olması anlamına gelmeyecek.
- Eski 16 yeni bina taslağı içerik havuzuna alınacak. Eski örnek bedeller ve sürekli coğrafya puanına bağlı etkiler yeniden düzenlenecek.

### Her bina için doldurulacak kart

| Alan | Yazılacak bilgi |
| --- | --- |
| Yer | Kendi district ailesi, medeniyet ve varsa görünür coğrafya koşulu. |
| Açılış | Skill ve ilerleme şartı. |
| Kuruluş bedeli | Kredi ve varsa seçilebilir ham/işlenmiş malzemeler. |
| İşletme | Gerçek çıktı, gerçek girdi, tur veya akış. |
| Çalışan | Seçilen üstel tier kuralından gelen ihtiyaç. |
| Seçme nedeni | Ucuzluk, az çalışan, güçlü yuva verimi, iyi coğrafya veya farklı girdi tercihi. |
| Bedeli | Enerji, işlenmiş bakım, sınırlı coğrafya veya daha büyük çalışan yükü. |
| Rakip | Hangi mevcut binanın alternatifi olduğu ve nerede ondan daha iyi/kötü olduğu. |

### Yeni 16 bina havuzunun güncellenmiş rolleri

| Bina | Kendi ailesi | Kurma nedeni | Karşılığı / uyarlama |
| --- | --- | --- | --- |
| Yüzey Ocağı | Industrial | Küçük bütçe ve düşük çalışanla temel ham üretim. | Mine'dan düşük yuva verimi; aynı anda her ölçüde üstün olmayacak. |
| Cevher Ayıklama Atölyesi | Industrial | Bir yuvada daha fazla Goods. | Daha büyük iş gücü veya bakım ihtiyacı. |
| Kompakt Yakıt Atölyesi | Industrial | Erken ve az çalışanlı Fuel erişimi. | Büyük Fuel üreticisine göre düşük yuva verimi; Goods'tan daha pahalı ham tarif. |
| Regolit İşleme Tesisi | Industrial, Ay | Ay malzemesini yerel gelişimin parçası yapmak. | Yeni kaynak adı üretmeyecek; mevcut Moonstone ve işlenmiş ürünler kullanılacak. |
| Sığ Jeotermal Kuyu | Energy | Uygun görünen coğrafyada ekonomik enerji. | Eski geothermal yüzdesi kullanılmayacak; uygunluk district üzerinden gelecek. |
| Sırt Türbini | Energy | Uygun yüksek arazi/kıyı tasarımına göre güçlü yuva verimi. | Kesin coğrafyası S31'e, bedeli yeni enerji dengesine bağlı. |
| Düşük Katlı Konut | Residential | Ucuz ve işlenmiş bakım istemeyen konut seçeneği. | Yuva başına düşük kapasite. |
| Kıyı Apartmanları | Residential | Kıyı konumunu değerlendiren konut. | Konum şartı districtin konumundan okunacak; ayrı bina noktası yok. |
| Modüler Ay Habitatı | Residential, Ay | Ay gelişiminde orta/üst konut seçeneği. | Goods bakımı gibi görünür bir bedel. |
| Saha Gözlem Evi | Science | Erken, küçük ölçekli ve düşük çalışanlı bilim. | İleri bilim binalarından düşük yuva verimi. |
| Ay Numune Laboratuvarı | Science, Ay | Ay üzerinde bilim ağırlıklı gelişim. | Ayrı bir ileri tier bina seçeneğinde Rare bakımı düşünülebilir; bina level'ı eklenmez, nihai tarif açık. |
| Yerel Ticaret Merkezi | Commercial | Küçük yatırımla kredi ağırlıklı strateji. | İleri ticaret binasının yuva verimini geçmeyecek. |
| Ay İkmal Pazarı | Commercial, Ay | Ay'daki fazla üretimi ekonomik stratejiye bağlamak. | Trade arayüzü ve işlenmiş bakım kararıyla uyarlanacak. |
| Yakıt Deposu | Industrial | Fuel kapasitesine özel yatırım. | Genel depoya göre diğer ürünleri desteklememe bedeli. |
| İnşaat Dairesi | Capital | Gelir yerine kuruluş kolaylığı seçmek. | Capital'ın yol/kapsam kurallarını aşan gizli City geneli bonus üretmeyecek. |
| Yörünge Yakıt Tankı | Space Station, koşullu | Roket dönemi için büyük Fuel tamponu. | İstasyonların yeni tasarımdaki yeri korunursa kullanılacak; filo/kargo sistemi istemiyor. |

Bu tablo içerik kimliklerini korur, fakat birbirinin aynısı olan rolleri onaylamaz. Örneğin Düşük Katlı Konut ile Habitat Block arasındaki seçim yalnız ad farkından oluşuyorsa birine farklı bir ekonomi rolü verilmeden eklenmeyecek.

### Mevcut binalara da uygulanacak düzenlemeler

- [ ] Energy ailesini özel konumun karşılığı açısından yeniden sırala.
- [ ] Goods/Fuel/Rare tüketen ileri konut, bilim ve ticaret ailelerini genişlet.
- [ ] Quantum Lab ve Arcology başlangıç erişimi istisnalarını kaldır.
- [ ] Capital destek binalarının bonus kapsamını yeni merkez/yol modeline göre incele.
- [ ] Aynı tür fiyat sayacını, seçili girdi bilgisini ve gerçek ödeme geçmişini bina adetleriyle birlikte koru.
- [ ] Aktif olmayan bina level arayüzü/formüllerini yeni gelişim sistemiymiş gibi kullanma.

### Açık sorular

- **S32:** Orbit ve Space Station üretim alanları yeni düzende korunacak mı? Genel filo sistemini kullanmayacağız; bu soru yalnız istasyonların ekonomi ve bina rolüyle ilgili.
- **S33:** Başlangıç binalarının güçlü yönü özellikle düşük çalışan ve düşük yatırım mı olsun? Önerim bu rolü korumak; üst tier'ın ana avantajı yuva başına üretim olabilir.

## 14. Skill tree bina listesi değil, strateji ağacı olacak

İlgili yorumlar: **5, 15, 22, 24, 33, 34, 43, 46**.

### Kesin kararlar

- Oyuncu bilim, nüfus, ticaret, coğrafya veya yerleşim düzeni ağırlıklı oynayabilecek.
- Dengeli gelişim de mümkün olacak, tek alanda uzmanlaşma da anlamlı kalacak.
- Oyuncunun bütün üreticileri bizzat kurması genel ilerlemenin koşulu haline getirilmeyecek. Gereken ürünlerin başka ekonomik yolla edinilebilmesi trade tasarımıyla tamamlanacak.
- Dallar yalnız beş düz üretim çizgisi olmayacak. Alt dallar ve birleşme noktaları olacak.
- Yakınlık, uzaklık, dağ, deniz, bilim, nüfus ve ticaret gibi tercihler ağaca yansıyacak.
- Çapraz tür komşuluk ve daha iyi yıkım iadesi gibi yeni kararlar uygun skill'lere bağlanabilecek.
- Bütün medeniyetlerin ağacı önceden bir şekilde görülecek; gelecek kısımlar silik/arka plan/özet olabilir. Satın alma izni ilerlemeye bağlı kalacak.
- Fuel ve Rare için erken yollar eklenecek. Yeni bina ve tüketici seçenekleri üretici kilitlerinin arkasında ulaşılmaz kalmayacak.

### Strateji dalları için iskelet

| Ana yaklaşım | Alt dallar | Başka dalla birleşme fikri |
| --- | --- | --- |
| Bilim | Yakın araştırma kümesi / uzak gözlem merkezleri | Dağ coğrafyası, ticaret yoluyla fazla Science kullanımı. |
| Nüfus | Yoğun yerleşim / yaygın uydu yerleşimler | Konut coğrafyası, iş gücü yoğun sanayi. |
| Ticaret | Yerel pazar ağı / uzak pazarlar | Fazla Science veya sanayi üretiminin krediye dönüşümü. |
| Coğrafya | Dağ / kıyı-göl / volkanik alan / diğerleri | İlgili üretim ailesinin uzmanlığı. |
| Yakın ağ | Capital bağlantısı / aynı tür kümeleri / çapraz tür bağlantısı | Bilim, nüfus veya sanayi odaklı ağ. |
| Uzak yerleşim | Bağımsız merkezler / uzak coğrafya fırsatları | Uzak araştırma, uzak ticaret veya güçlü tek üretim. |
| İşleme | Erken Goods / erken Fuel / erken Rare | İleri bina, Ay hazırlığı ve trade. |

Birleşme noktası, iki dalın bütün bonuslarını zorunlu satın almak anlamına gelmemeli. Alternatif yolların ortak ilerleme hedefi ile iki araştırmayı birlikte isteyen özel bir sinerji düğümü arayüzde farklı anlatılmalı.

### Önceki 16 skill taslağının yeni ağa yerleşimi

| Havuzdaki düğüm | Yeni strateji bağlantısı | Yeniden düzenlenecek nokta |
| --- | --- | --- |
| Yüzey Kazı Teknikleri | Erken sanayi / düşük yatırım | Yüzey Ocağı açılışı. |
| Cevher Ayıklama | İşleme / Goods | Atölye ve anlamlı verim tercihi. |
| Küçük Ölçekli Yakıt | Erken Fuel / düşük iş gücü | Eski geç açılan Fuel zincirini zorunlu kopyalamayacak. |
| Yakıt Depolama | İşleme / biriktirme | Depo ve kayıpsız stok düzeniyle uyum. |
| Sığ Isı Kuyuları | Volkanik/jeotermal coğrafya / enerji | Yüzde puan yerine sabit coğrafya uygunluğu. |
| Sırt Rüzgârları | Görünür coğrafya / enerji | S31 kararına göre konum. |
| Mahalle İnşası | Nüfus / düşük yatırım | Temel konut alternatifinin rolü. |
| Kıyı Yoğunlaşması | Nüfus / kıyı | Konum ve yoğun konut tercihi. |
| Saha Araştırmaları | Bilim / coğrafya | Erken küçük bilim seçeneği. |
| Yerel İşletmeler | Ticaret / yakın ağ | Kredi stratejisi. |
| İnşaat Organizasyonu | Capital / kuruluş kolaylığı | Yol komşuluğu ve kapsam. |
| Orbital Depolama | Roket hazırlığı / kapasite | S32'ye göre korunacak veya başka role taşınacak. |
| Ay Malzemeleri | Ay / sanayi ve konut | Ay'a özgü yapıların açılışı. |
| Ay Araştırmaları | Ay / bilim | Bilim odaklı Ay gelişimi. |
| Ay İkmal Ağı | Ay / ticaret | Trade ayrı tasarlanacağı için işlevi ona bağlanacak. |
| Yakıt Süreçleri | İşleme / Fuel uzmanlığı | Küçük ara bonus, maliyet ve sınırı yeniden hesaplanacak. |

Bu 16 aday, nihai ağacın toplam düğüm sayısının 16 olacağı anlamına gelmez. Yakınlık/uzaklık, farklı tür bonusları ve iade uzmanlığı için ek düğümler gerekecek. Mevcut düğümlerle örtüşen içerikler birleştirilecek; aynı etki iki farklı adla şişirilmeyecek.

### Stratejiyi oyun sonunda da koruma problemi

Science üretimi çok yükselince herkes bütün pasif bonusları satın alabiliyorsa ilk uzmanlaşmalar zamanla aynı sonuca yaklaşabilir. Kullanıcının verdiği şu fikirler henüz çözüm olarak seçilmedi:

| Seçenek | Sağladığı tercih | Açık bedeli |
| --- | --- | --- |
| Diğer dalların fiyatını artırma | Bir alana yatırım diğerini daha pahalı yapar. | Ne kadar zorlayacağı ve geri dönüş yolu. |
| Medeniyet geçişinde alınmamış eski skill'leri kilitleme | Geçiş kararı bir fırsat maliyeti taşır. | Oyuncu geçişi bekletip hepsini alabilir; tek başına kalıcı farklılığı garanti etmez. |
| Sınırlı aktif uzmanlık seçimi | Sonunda bilgi açılsa da aynı anda bütün ekonomik etkiler kullanılamaz. | Yeni bir uzmanlık seçimi arayüzü gerektirir. |

Üçüncü satır ek bir öneridir, kullanıcı tarafından kesinleştirilmiş karar değildir. Hangisi seçilirse oyuncuya önceden açıklanmalı.

### Açık sorular

- **S34:** Kalıcı strateji farkını hangi yolla koruyalım: diğer dal fiyatları, medeniyet geçişinde eski alımların kapanması, sınırlı aktif uzmanlık veya bunların belirli bir birleşimi?
- **S35:** Medeniyet geçişinde eski skill'ler kapanırsa alınmış bonuslar çalışmaya devam edecek mi? Önerim kazanılmış etkileri kaybettirmemek.
- **S36:** Dalların birleştiği ortak ilerleme düğümlerinde alternatif yollardan birini bitirmek yeterli mi olsun? İki dalı birlikte isteyen özel sinerjileri ayrıca işaretleyebiliriz.
- **S37:** Nüfus ağırlıklı stratejinin ana ekonomik karşılığı ne olsun: çok çalışanla yüksek üretim mi, konut fazlasını kullanan özel binalar mı, yoksa trade'e bağlanan başka bir rol mü? Nüfusu satılabilir bir hammaddede dönüştürmeye burada karar verilmedi.

## 15. Ay ekonomisi ve yeni roketle Tip 0'ın tamamlanması

İlgili yorumlar: **1, 3, 4, 5, 9, 11, 46**.

### Tip 0'ın son bölümü için ana akış

Ay'dan başka gezegene roket yolculuğu kesin hedeftir. Aşağıdaki hazırlıkların her oyuncu tarafından bizzat mı yapılacağı, yoksa trade ile alternatif malzeme edinme yollarının da mı kullanılabileceği S38'de netleştirilecek.

```text
Ana gezegende gelişim
  -> Ay'a erişim ve ilk yerleşim
  -> Ay hammaddelerinin işlenmesi
  -> Ay'da yeni bina ve ekonomi seçenekleri
  -> Daha gelişmiş roketin hazırlanması
  -> Ay'dan başka gezegene yolculuk
  -> S01'de seçilen olayda Civilization Type 0 tamamlanması
  -> Tip 1'in ölçeğinde oynanış
```

Ay yalnız bir tebrik ekranının açıldığı son durak olmayacak. Tip 0'ın son ekonomik bölümü olacak. Ay'dan gidecek roketin kuruluş bedeli erişilemeyen Tip 1 hammaddesine bağlanmayacak; geçiş öncesi bütün zorunlu girdiler Tip 0 içinde edinilebilir olacak.

Yeni roket için filo yönetimi, rota planlayıcı veya kargo görev sistemi gerekmeyecek. Oyuncunun hedef seçip ilerlemeyi başlatabildiği sade bir sefer olayı yeterli bir taslaktır.

### Doldurulacak geçiş tablosu

| Alan | Karar |
| --- | --- |
| Ay'da gerekli yerleşim aşaması | ______ |
| Kullanılacak mevcut ham kaynaklar | ______ |
| İşlenecek ürünler | Goods / Fuel / Rare arasından: ______ |
| Gerekli yeni bina veya alternatif yollar | ______ |
| Roket araştırmasının adı | ______ |
| Roket kuruluş kredi ve malzeme bedeli | ______ |
| Hazırlık ve yolculuk süresi | ______ |
| Hedef gezegen seçimi | ______ |
| Medeniyetin tamamlandığı olay | S01 cevabı. |

### Açık sorular

- **S38:** Ay'daki yerel maden işleme ve belirli binalar bütün stratejiler için zorunlu bir hikâye adımı mı olacak? Yoksa bilim/ticaret oyuncusu gerekli malzemeleri trade ile sağlayıp Ay'daki roket hazırlığına farklı yoldan ulaşabilecek mi?
- **S39:** Ay'dan hedef gezegen sabit bir sonraki durak mı olsun, yoksa oyuncu erişilebilir birkaç gezegenden seçsin mi?

## 16. Alt butonlar district uygunluğunu ve yerleşim önerilerini gösterecek

İlgili yorumlar: **21, 35, 37, 38, 47, 48**.

### Kesin kararlar

- Eski doğal kaynak görünümü tamamen kaldırılacak.
- Alt butonlar district ailelerine göre uygunluk gösterecek: Energy, Residential, Industrial, Science, Commercial ve gerekiyorsa merkez.
- Science seçildiğinde bilim için uygun dağlık alanların parlaması gibi doğrudan okunabilen bir sunum olacak.
- Basit uygunluk kademeleri kullanılacak; bonuslar districti ve ilgili binaları ebeveyn aktarımıyla etkileyecek.
- Butonlar yerleşim önerisi sunabilecek.
- Önerilen nokta, gerçek kuruluş kurallarından geçecek. Kurulamayacak bir yer en iyi öneri olarak gösterilmeyecek.

### Öneri panelinde gösterilecek kısa açıklama

```text
Science için uygun
Neden: Dağlık alan
Coğrafya etkisi: Seçilmiş uygunluk kademesi
Yerleşim tarzı: Yakın ağ / bağımsız yerleşim için uygun
Kurulabilirlik: Uygun veya engelin açık sebebi
```

Bu metin bir arayüz taslağıdır. Oyuncuya kod alanları veya eski saha puanları gösterilmeyecek. Tip 1 ve üstünde aynı buton mantığı o ölçekte haritada kurulan türlere uyarlanacak; Tip 1'de bütün düğmelere hâlâ district denmesi gerekmiyor.

### Açık soru

- **S40:** Yerleşim önerileri yalnız coğrafyaya göre mi sıralansın, yoksa oyuncunun seçtiği yakınlık/uzaklık uzmanlığını da hesaba katsın mı? Önerim seçilen stratejiye göre öneri vermek ve nedeni tek cümleyle açıklamak.

## 17. Üst ölçekler ve bütün medeniyetlerin skill önizlemesi

İlgili yorumlar: **2, 33**.

### Kesin kararlar

- Oyuncu oyunun büyük kapsamını görebilecek.
- Solar View, gökada, evren ve çoklu evren kilitli olsalar da bir önizleme yoluyla incelenebilecek.
- Kilitli görünüm, aktif ekonomi oluşturmayacak veya işlem başlatmayacak.
- Dev skill ağacının sonraki medeniyetleri silik, arka planda veya özet halinde görünebilecek.
- Kilit mesajı yalnız “hayır” demeyecek; o ölçekte ileride ne yapılabildiğini ve hangi ilerleme eşiğinin gerektiğini açıklayacak.
- Önizlemeden mevcut oynanışa kolayca dönülecek. Oyuncu demo sonu engeline düşmeyecek.

### Taslak kapsam

Tam oynanabilir evren/çoklu evren ekonomisini bu önizleme için uygulamak gerekmiyor. Görsel bir harita kabuğu, örnek yapılar ve gelecek özellik açıklamaları yeterli olabilir. Henüz tasarlanmamış bütün gelecek skill'lerin kesin fiyatını göstermek de gerekmiyor.

### Açık soru

- **S41:** Gelecek ölçekler ilk sürümde gezilebilir örnek haritalar mı olsun, yoksa mevcut haritadan uzaklaşınca açılan katmanlı görsel önizlemeler yeterli mi? Skill tarafında da dal isimleri ve örnek düğümlerle başlayabiliriz.

## 18. Tutorial ve alternatif başlangıçlar yeniden tasarlanacak

İlgili yorumlar: **6, 39**.

### Kesin karar

Tutorial yeni mekaniklere göre baştan ele alınacak. Eski saha puanlarını, eski karma tür komşuluğunu veya gezegene özel nüfusu öğreten adımlar korunmayacak.

### Karar bekleyen başlangıç fikri

- İyi seçilmiş sabit bir Terran seed üzerinde herkes aynı öğretici koşullarla başlayabilir.
- Öğrenme bitince oyuncu aynı oyuna devam edebilir veya rastgele seed ile yeni başlangıç yapabilir.
- Rastgele başlangıç yalnız Terran olmak zorunda olmayabilir; volkanik veya gaz gövde aday olabilir.
- Bu alternatiflerde başlangıç binaları ve erişilebilir skill yolları gezegenin koşullarına uygun olmalı.

Bu dört madde kullanıcı tarafından fikir olarak bırakıldığı için burada tamamlanmış özellik kararı olarak işaretlenmedi.

### Yeni tutorial'ın öğretmesi gerekenler

| Sıra taslağı | Öğrenilecek davranış |
| --- | --- |
| 1 | City ve Capital ile dört katmanı anlamak. |
| 2 | Ortak nüfus ve bina/district yerleşimi. |
| 3 | Sabit görünen coğrafya ve uygunluk butonları. |
| 4 | Aynı tür tekrar fiyatı ve farklı bina tercihi. |
| 5 | Üreticide ham madde seçmek, girdiyi ve çıktıyı okumak. |
| 6 | Aynı tür komşuluk ile uzak yerleşimi karşılaştırmak. |
| 7 | Bir strateji dalı seçmek ve alternatif gelişim yollarını görmek. |
| 8 | Trade tasarlandıktan sonra eksik malzemeyi farklı ekonomik yoldan edinmek. |

### Açık sorular

- **S42:** Sabit Terran tutorial seed fikrini uygulama kararına çevirelim mi?
- **S43:** Tutorial sonrası rastgele başlangıç yeni bir oyun mu açacak, yoksa aynı ilerlemenin başka bir başlangıç noktasına taşınması mı olacak? Kaynak ve skill aktarımı ayrıca açıkça seçilmeli.
- **S44:** Gaz/volkanik rastgele başlangıçlar bu büyük güncellemeye dahil mi, sonraki pakette mi? Dahilse ilk Tip 0 hammaddesine erişim ve gaz gövdedeki ilk City biçimi nasıl olacak?

## 19. İsteğe bağlı offline ilerleme

İlgili yorum: **40**.

### Yön ve taslak

- Offline ilerleme eklenebilecek; kullanıcı kapatabilecek.
- Normal üretimin **1/10 hızı** başlangıç önerisi olarak ele alınacak.
- Bu oran henüz bütün kaynak ve süreler için onaylanmış son kural değildir.

Basit örnek: Aktif oyunda dakikada 100 üreten düzen, 1/10 kabul edilirse offline dakikada 10 üretir. 60 dakikada 600 ürün eder. Girdi ve depolama koşulları bu yalın örnekte dışarıda tutulmuştur.

### Ekonomiyle birlikte ele alınacak kurallar

- Girdi isteyen üreticiler kapalıyken bedelsiz ürün yaratmayacak; seçili tarifin girdi durumu hesaplanacak.
- Seçili ham kaynak biterse daha nadir kaynağa otomatik geçilmeyecek.
- Kullanıcı tarafından durdurulmuş bina offline üretime gizlice katılmayacak.
- Depo taşması kayıpsız stok kuralıyla aynı biçimde ele alınacak.
- Enerji bir stok değildir, nüfus da kapasite olarak kalırsa kapalıyken biriktirilecek ürün değildir. Bunlar üretim koşulu olarak değerlendirilecek.
- Trade'in offline çalışması bu belgede karara bağlanmadı.

### Açık sorular

- **S45:** 1/10 oranını ilk uygulama değeri olarak kabul ediyor musun? En fazla kaç saatlik offline süre birikebilsin?
- **S46:** Offline hesap yalnız üretim ve gerçek bakım girdilerini mi kapsasın, yoksa inşaat, yükseltme ve roket yolculukları da ilerlesin mi? Trade otomasyonu ayrı karar olarak kalabilir.
- **S47:** Offline seçeneği varsayılan açık mı, kapalı mı gelsin? Kapatıldığında geçmişte birikmiş ama henüz alınmamış üretimin durumu ne olsun?

## 20. Kayıt, eski içerik ve ortak veri düzeni

İlgili yorumlar: **1, 3, 7, 8, 12, 14, 17, 18, 19, 32, 40**.

### Uygulamada korunacak bilgiler

| Bilgi | Neden gerekli? |
| --- | --- |
| Medeniyet tipi ve tamamlanan geçişler | Ay City'si ile Tip 0 bitişini ayırmak. |
| Önizleme izni ve oynanış izni | Gelecek haritayı göstermek, ekonomisini açmamak. |
| Nesnenin ebeveyni ve rolü | Dört katmanın her medeniyette aynı mantıkla kayması. |
| Tür ve yerleşim kapsamı | Aynı tür tekrar fiyatı ile gelecekteki City türlerini desteklemek. |
| Seçilmiş üretim girdisi | Nadir hammaddenin otomatik tüketilmesini engellemek. |
| Devam eden turun tarif kaydı | Tur ortasında kaynak seçimi değişince hesabı korumak. |
| Bina adedinin gerçek satın alma bedeli | Doğru yıkım iadesi. |
| Ortak konut ve nüfus yükü | Yerel havuzlardan imparatorluk havuzuna geçmek. |
| Bekleyen üretim | Depo taşmasını kayıpsız tutmak. |
| Coğrafya etiketi ve sabit kademe | Eski sürekli saha puanını kullanmamak. |
| Doğrudan komşular ve özel açılmış ilişkiler | Yol kesişimi bonusu olmadan stratejik ağ. |
| Offline ayarı ve son hesap zamanı | İsteğe bağlı kapalı oyun ilerlemesi. |

Mevcut kayıtlar gerçek ödeme geçmişi veya bekleyen çıktı gibi yeni bilgileri tutmuyor olabilir. Bu alanlara geriye dönük değer atama kuralı seçilmeden eski kayıtlar rastgele dönüştürülmeyecek.

Gezegenler arası genel gemi altyapısı yeni özellik yapılmayacak. Ancak mevcut Ay lander'ının kullandığı ortak parçalar, sade sefer olayından ayrılmadan silinmeyecek. Kullanılmayan filo/görev tanımlarını temizlemek, onların yeni oynanışta kullanılmasına karar vermek değildir.

Achievement, tutorial hedefleri ve arayüz metinleri yeni kaynak kapsamını ve adet sayımını doğru izleyecek şekilde bu değişikliklerle birlikte ele alınmalı. Eski envanterdeki bütün bağımsız sorunlar bu plan adına kendiliğinden ek düzeltme kapsamına alınmıyor.

### Açık soru

- **S48:** Güncelleme mevcut kayıtları uyarlamayı mı hedeflesin, yoksa bu sürüm için yeni oyun başlangıcı mı tercih edilsin? Şu aşamada hiçbir kayıt silinmeyecek veya dönüştürülmeyecek.

## 21. Uygulama sırası ve bağımlılıklar

Bu liste, sonraki kod güncellemesinde takip edilecek iş paketleridir. Kutuların boş olması planlandığını gösterir. **Hiçbiri bu dosya oluşturulurken uygulanmadı.**

| Sıra | İş paketi | Somut sonuç | Önce gerekli olan |
| --- | --- | --- | --- |
| [ ] 01 | Medeniyet sözleşmesi | Tip 0 son olayı, ölçek tablosu, merkez rolleri ve görünür/oynanabilir ayrımı. | S01-S04. |
| [ ] 02 | Trade tasarımını ayrı belgeye çıkar | Dönüşüm yönleri, fiyatlar, erişim ve fazla ürün kullanımı. | Kullanıcının ayrı trade konuşması. |
| [ ] 03 | Ortak veri ve kayıt yapısı | Yeni alanların kaydı, mevcut kayıt yaklaşımı, kaynak erişim kilitleri. | 01, S48 ve kaynak dağılımı. |
| [ ] 04 | İmparatorluk nüfusu | Tek konut/iş gücü havuzu ve ortak gösterim. | 03, S05-S06. |
| [ ] 05 | Tür başına fiyat ve gerçek ödeme kaydı | Aynı bina/district türü tekrar sayacı; iadeye dayanak olan ödeme bilgisi. | 03, S16-S19. |
| [ ] 06 | Üretim girdisi ve ödeme seçimi | Otomatik en nadir seçimi yerine oyuncu tercihi ve açık çıktı hesabı. | 03, S09-S11. |
| [ ] 07 | Kayıpsız stok | Depo taşması ve kapasite düşüşünde kaynak korunması. | 03, S15. Trade gelmeden koruma kısmı hazırlanabilir. |
| [ ] 08 | Coğrafya ve mesafe temeli | Görünen arazi etiketleri, sabit uygunluk, ortak mesafe dili. | 01, S20-S24. |
| [ ] 09 | Komşuluk ve uzaklık | Capital/yol komşusu, aynı tür katkısı, özel çapraz ilişkiler; kesişim bonusunun kalkması. | 08, S25-S28. |
| [ ] 10 | Tarif ve tier denge tabloları | Goods/Fuel/Rare maliyetleri, erken açılış, çalışan ve district büyüme kuralları. | 04-09; trade kararları nihai değerleri etkiler. |
| [ ] 11 | Bina ailelerini güncelle | Mevcut ailelerde tercih nedeni; yeni 16 bina havuzunun uygun üyeleri; Tier 4 erişiminin düzelmesi. | 10, S31-S33. |
| [ ] 12 | Strateji skill ağacı | Yakın/uzak/coğrafya/bilim/nüfus/ticaret yolları ve birleşmeler; eski ve yeni düğümlerin eşlenmesi. | 09-11, S34-S37. |
| [ ] 13 | Trade'i bağla ve strateji yollarını tamamla | Tek bir alanda yoğunlaşan oyuncunun gereken diğer ürünleri edinebilmesi. | 02 ve ilgili ekonomi paketleri. Trade tasarımı bitmeden tamamlandı sayılmaz. |
| [ ] 14 | Ay ekonomisi ve gelişmiş roket | Yerel veya alternatif üretim yolundan Tip 1'e geçiş. | 10-13, S38-S39, geçiş bedel tablosu. |
| [ ] 15 | Uygunluk butonları | Eski katmanlar yerine açıklanabilir yerleşim önerileri. | 08-12, S40. |
| [ ] 16 | Harita ve skill önizlemeleri | İleri medeniyetleri göstermek; kilitli oynanışa izin vermemek; demo panelinin kalkması. | 01, S41. Temel görünürlük ayrımı daha önce hazırlanabilir. |
| [ ] 17 | Yeni tutorial | Yeni ekonomi, arazi, girdi ve strateji kurallarının öğretilmesi. | 04-16, S42-S44. |
| [ ] 18 | Offline ilerleme | Açılıp kapatılan, gerçek girdi ve stok kurallarına uyan kapalı oyun üretimi. | Aktif ekonomi sabitlendikten sonra, S45-S47. |
| [ ] 19 | Metinler ve kayıt uyumu | Act/demo ifadelerinin yeni anlamla değiştirilmesi; ilgili hedef ve göstergelerin uyarlanması. | İlgili paketler ve S48. |
| [ ] 20 | Kullanıcı değerlendirmesi | Kullanıcının oynanış gözlemlerinden sonra miktarların ve hızların sonraki belgeye işlenmesi. | Oyun güncellemesi ayrıca istendikten sonra. Testleri kullanıcı yapar. |

### Trade konuşulmadan tamamlanabilecek tasarım işleri

Ölçek tablosu, merkez adları, basit coğrafya, mesafe anlatımı, tür başına sayaç kapsamı, hammadde seçimi arayüzü ve kaynak kaybını önleme davranışı trade oranlarını beklemeden netleştirilebilir.

Trade belirlenmeden **bütün min-max yolları dengeli çalışıyor**, **işlenmiş ürünler kesin kârlı** veya **fazla üretim otomatik satılıyor** gibi sonuçlar varsayılmayacak.

## 22. Sayısal kararlar için doldurulacak ortak tablo

Bu tablo yeni kod değerleri seçilirken tek başvuru olacak. Boş alanlara eski sayıların fark edilmeden geri dönülmemesi gerekiyor.

| Alan | Kesin yön | Son değer |
| --- | --- | --- |
| Bina tekrar fiyatı | Yalnız aynı tür; kapsam S16. | Artış oranı: ______ |
| District tekrar fiyatı | Yalnız aynı tür; kapsam S16. | Artış oranı: ______ |
| Tip 0 City kuruluşu | Türsüz City. | Taban ve tekrar kuralı: ______ |
| Tip 1 City kuruluşu | Türlü; aynı tür tekrarı pahalanır. | Tip 1 tasarımında doldurulacak. |
| Yıkım iadesi | Temel %50; skill ile yükselir. | Dayanak ve üst sınır: ______ |
| Tier çalışanı | Düzenli üstel büyüme. | Taban: ______, çarpan: ______ |
| District üretim seviyesi | Incremental yapıya göre yeniden planlanacak. | Formül ve üst sınır: ______ |
| Goods tarifi | Temel işlenmiş ürün. | Girdi/çıktı/süre: ______ |
| Fuel tarifi | Goods'tan daha pahalı ham dönüşümü. | Girdi/çıktı/süre: ______ |
| Rare tarifi | İleri bina için anlamlı girdi. | Girdi/çıktı/süre: ______ |
| Fuel/Rare açılışı | Daha erken. | Skill ve ilerleme noktası: ______ |
| Coğrafya | Sabit ve görünen uygunluk. | Kademeler/çarpanlar: ______ |
| Komşuluk | Capital + aynı tür; çapraz tür özel açılır. | Katkı ve alıcı sınırı: ______ |
| Uzaklık | Anlamlı bağımsız yerleşim stratejisi. | Birim/eşik/katkı: ______ |
| Offline | İsteğe bağlı; 1/10 aday. | Oran/süre sınırı/kapsam: ______ |

## 23. 48 yorumun eksiksiz karar eşlemesi

Bu numaralar kullanıcının yorum sırasıdır. Açık soru numaraları olan S01-S48 ile karıştırılmamalı.

| Yorum | Bu belgede karşılığı | Bölüm |
| ---: | --- | --- |
| 1 | Act tamamlanması yerine Civilization Type 0 tamamlanması. | 1, 15 |
| 2 | Demo paneli yok; üst ölçekler oynanış açmadan önizlenir. | 1, 17 |
| 3 | Genel gezegenler arası gemi/filo/görev sistemi kullanılmayacak. | 1, 15, 20 |
| 4 | Ay kaynakları, işleme, yeni binalar ve gelişmiş roketle başka gezegene sefer Tip 0 sonunu oluşturur. Kesin tetik anı S01. | 1, 15 |
| 5 | Bilim/nüfus vb. uzmanlaşma ve min-max mümkün; trade ayrı tasarlanır, bütün üreticiler zorunlu yapılmaz. | 7, 14, 15 |
| 6 | Sabit öğretici Terran, devam veya rastgele farklı gövde ve ona uygun skill ağacı fikri korunur; kapsamı açık. | 4, 18 |
| 7 | Dört katman medeniyetle yukarı kayar; en alt içerik solda listelenir, kendi coğrafyası olmaz; merkez eşleme tablosu kullanıcıya bırakılır. | 2, 9, 10, 11 |
| 8 | Nüfus bütün imparatorluğun ortak havuzu olur. | 3 |
| 9 | Goods/Fuel/Rare üst tier'da daha gerekli ve karşılığını veren girdiler olur. | 4, 6, 13 |
| 10 | Depo taşması silinmez; gelecekte trade ile krediye çevrilebilir. Otomatik satış henüz seçilmedi. | 7 |
| 11 | 12 ham kaynak medeniyet tiplerine göre açılır; sistem uzaklığı ana ilerleme kilidi olmaktan çıkar. | 4 |
| 12 | İşleme kaynağını oyuncu seçer ve çıkacak ürünü görür; en nadir otomatik seçilmez. | 5 |
| 13 | Fuel/Goods gibi tariflerin ham tüketim ve ödül dengesi tek tek yeniden kurulur. | 6 |
| 14 | Temel %50 kredi iadesi ve skill ile yükselmesi planlanır. | 8 |
| 15 | Bina level sistemi olmayacak; ileride skill'e bağlama yalnız geleceğe bırakılan ihtimal. | 8, 12 |
| 16 | Tier çalışan ihtiyaçları düzenli üstel büyümeyle yeniden dengelenir. | 3, 12 |
| 17 | Bina fiyatını yalnız aynı bina türünün tekrarları artırır. | 8 |
| 18 | District fiyatını yalnız aynı district türünün tekrarları artırır; oran sonra seçilir. | 8 |
| 19 | Tip 0 City türsüz; Tip 1'de City district rolüne geçince tür ve aynı tür fiyat artışı gelir. | 2, 8 |
| 20 | Üretim/tüketim turu olmayan nesnede sahte saniye alanı ve çubuk olmaz; gerçek inşaat/bakım ayrılır. | 12 |
| 21 | Sürekli arazi yüzdeleri yerine görünen özelliğe bağlı basit sabit uygunluk. | 9 |
| 22 | Yakın ve uzak stratejiler farklı, anlamlı, skill destekli ve her durumda tek kazananı olmayan tercihler olur. | 11, 14 |
| 23 | Residential temel ilişkisinin rolü kredi değil nüfus/konut olur; eski satırın yönü de açıklanır. | 11 |
| 24 | Capital yol komşularına; normal district aynı türe bonus verir. Farklı tür bağlantısı skill/özel bina açar. | 11, 14 |
| 25 | City kendi başına bonus dağıtmaz; Capital ilişkisi yalnız yol komşuluğunda işler. | 2, 11 |
| 26 | Yol kesişimi ve paylaşılan yol kalınlığı bonusu kaldırılır. | 11 |
| 27 | Eski derecenin anlamı ve eski uzaklık kazancı basit örnekle açıklanır; yeni mesafe ayrıca tasarlanır. | 10, 11 |
| 28 | District seviye artışı, incremental büyüme ve maliyetle birlikte yeniden planlanır. | 12 |
| 29 | Ham madde isteyen ödemede harcanacak kaynakları oyuncu seçer. | 5 |
| 30 | Zor ve pahalı binalar daha fazla malzeme isterken daha iyi ödül verir; bütün aileler kıyaslanır. | 6, 12, 13 |
| 31 | Energy ailesindeki tercih farkı düzeltilir; özel kuruluş şartı karşılıksız kalmaz. Wind'in yeni coğrafyası açık soru. | 12, 13 |
| 32 | Tier 4 başlangıç/katalog erişim hataları düzeltilir; önizleme erişimi ile kurma erişimi ayrılır. | 13, 17 |
| 33 | Bütün medeniyetleri hissettiren dev skill ağacı önizlemesi olur. | 14, 17 |
| 34 | Yeni strateji kolları dallanıp birleşir; herkesin sonunda aynı hale gelmesini önleyecek mekanizma henüz seçilmez. | 14 |
| 35 | Alt butonlar districtin nerede daha iyi sonuç vereceğini gösterir; örneğin Science için dağlar parlar. | 16 |
| 36 | Mesafe görsel gezegen boyutuna bağlı anlaşılmaz derece hesabıyla sunulmaz; kapasite ayrı karar olur. | 10 |
| 37 | Yüksekliğin yanında volkanik alan, göl, eski yerleşim ve tundra gibi görünür özellikler kullanılır. | 9 |
| 38 | Eski doğal saha puanları tamamen iptal edilir. | 9 |
| 39 | Tutorial yeni sistem için baştan ele alınır; sabit seed kararı açık bırakılır. | 18 |
| 40 | İsteğe bağlı offline ilerleme planlanır; 1/10 oranı ve sınırları soru olarak bırakılır. | 19 |
| 41 | Kaynak türü eklenmez; mevcut ham ve işlenmiş liste korunur. | 4, 7 |
| 42 | Üst tier'ın bir avantajı ve açık bedeli olur; başlangıç seçeneğinin rolü kaybolmaz. | 12, 13 |
| 43 | Küçük ara bonus düğümleri dengeye fayda sağlıyorsa kullanılacak; eski örnek sayılar otomatik onaylanmaz. | 12, 14 |
| 44 | Her yeni bina kendi district ailesinde bulunur. | 13 |
| 45 | Yeni bina havuzu alınır; her binanın kuruluş nedeni ve rakibinden farkı tanımlanır. | 13 |
| 46 | Yeni skill havuzu strateji kollarına yerleştirilir; Rare ve Fuel daha erken açılır ve birlikte dengelenir. | 6, 14 |
| 47 | Yeni uygunluk butonları fikri uygulama planına alınır. | 16 |
| 48 | Basit kademeler, district ve ilgili binaya aynı coğrafyanın aktarımı, yerleşim önerisi ve eski görünümün tamamen kalkması. | 9, 16 |

## 24. Gelecek uygulamada etkilenecek başlıca dosyalar

Bu liste kod değişikliği değildir; sonraki çalışma için güncel proje alanlarını gösterir.

| Alan | Dosyalar |
| --- | --- |
| Medeniyet, kaynak havuzu, Ay geçişi, kayıt | [GameState.gd](C:/Users/drosm/Voidle/scripts/game/GameState.gd), [PlanetProgress.gd](C:/Users/drosm/Voidle/scripts/game/PlanetProgress.gd). |
| Ortak nüfus, fiyat, kaynak erişimi, depo | [Economy.gd](C:/Users/drosm/Voidle/scripts/game/Economy.gd), [BodyResources.gd](C:/Users/drosm/Voidle/scripts/game/BodyResources.gd). |
| Üretim girdisi, bonus aktarımı, akış ve offline | [ProductionManager.gd](C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd). |
| Bina/district türleri ve yeni içerik | [BuildingDef.gd](C:/Users/drosm/Voidle/scripts/game/BuildingDef.gd), [DistrictDef.gd](C:/Users/drosm/Voidle/scripts/game/DistrictDef.gd), [bina kaynakları](C:/Users/drosm/Voidle/resources/buildings), [district kaynakları](C:/Users/drosm/Voidle/resources/districts). |
| Seviye, erişim, yeni strateji düğümleri | [Leveling.gd](C:/Users/drosm/Voidle/scripts/game/Leveling.gd), [SkillTree.gd](C:/Users/drosm/Voidle/scripts/game/SkillTree.gd), [SkillTreeView.gd](C:/Users/drosm/Voidle/scripts/ui/SkillTreeView.gd). |
| Uygunluk, coğrafya, yerleşim, yollar | [PlanetaryView.gd](C:/Users/drosm/Voidle/scripts/planetary/PlanetaryView.gd), [TerrainSampler.gd](C:/Users/drosm/Voidle/scripts/planetary/TerrainSampler.gd), [ResourceMap.gd](C:/Users/drosm/Voidle/scripts/planetary/ResourceMap.gd), [POIData.gd](C:/Users/drosm/Voidle/scripts/planetary/POIData.gd), [RoadNetwork.gd](C:/Users/drosm/Voidle/scripts/planetary/RoadNetwork.gd). |
| Harita görünürlüğü ve oynanış erişimi | [SolarView.gd](C:/Users/drosm/Voidle/scripts/solar/SolarView.gd), [GalaxyView.gd](C:/Users/drosm/Voidle/scripts/galaxy/GalaxyView.gd). Evren/çoklu evren önizlemesi için yeni görsel alanlar gerekebilir. |
| Eski gemi bağımlılıklarından sade sefer olayına geçiş | [ShipManager.gd](C:/Users/drosm/Voidle/scripts/game/ShipManager.gd), [SpaceportLogic.gd](C:/Users/drosm/Voidle/scripts/game/logic/SpaceportLogic.gd) ve bunları kullanan Ay/yerleşim akışı. Genel filo sistemi genişletilmeyecek. |
| Tutorial, göstergeler, ayarlar | [TutorialManager.gd](C:/Users/drosm/Voidle/scripts/system/TutorialManager.gd), [HUDManager.gd](C:/Users/drosm/Voidle/scripts/system/HUDManager.gd), [SettingsManager.gd](C:/Users/drosm/Voidle/scripts/system/SettingsManager.gd). |

### Sonraki belgeyi güncelleme biçimi

Yanıtlanan her S numarası ilgili başlıktaki kesin karara dönüştürülecek. Sayısal tablolar ve iş paketleri buna göre yenilenecek. Kullanıcı tarafından doldurulan medeniyet/Capital tablosu sonraki sürümde ana eşleme olacak.

Bu sürümün teslimi: **yeni tasarım belgesi**. Oyun dosyaları değiştirilmedi, eski envanter yeniden yazılmadı, kayıtlar değiştirilmedi, Godot veya test çalıştırılmadı.




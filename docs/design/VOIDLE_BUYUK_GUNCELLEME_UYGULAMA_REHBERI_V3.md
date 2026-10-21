# Voidle büyük güncelleme V3: uygulama rehberi

Tarih: 20 Ekim 2026  
Durum: Kullanıcının incelemesi için hazırlanmış rehber. Bu çalışma sırasında oyun güncellenmedi.

## 1. Bu belgeyi uygulayacak yapay zekâya

Bu belge hem tasarım sözleşmesi hem uygulama sırasıdır. Güncel disk üzerindeki [V2](C:/Users/drosm/Voidle/VOIDLE_BUYUK_GUNCELLEME_TASARIM_V2.md), [V1](C:/Users/drosm/Voidle/VOIDLE_BUYUK_GUNCELLEME_TASARIM_V1.md), [ilk mekanik envanteri](C:/Users/drosm/Voidle/MEDENIYET_0_MEKANIK_VE_MATEMATIK.md) ve kullanıcının son cevapları okunarak hazırlanmıştır.

**Öncelik:** Kullanıcının daha sonraki mesajı veya dosyaya yaptığı açık düzeltme > V3'teki güncel kural > eski belgeler. Eski belgeler mevcut kaynakları bulmak ve karar geçmişi içindir. V3'ün değiştirdiği bir kuralı eski belgeden geri getirme.

| İşaret | Nasıl uygulanmalı? |
| --- | --- |
| **Kesin karar** | Kullanıcının belirlediği davranış; tekrar onay isteme. |
| **Sayısal taslak** | Kullanıcının matematiği hazırlama yetkisiyle seçilmiş somut değer. Uygulama onayı verilirse bu değerleri başlangıç ayarı kabul et; çalıştığı veya dengeli olduğu kanıtlanmış sayma. |
| **Önerilen tasarım** | Henüz kullanıcı tarafından seçilmemiş içerik/işleyiş önerisi. Son bölümde karar gerekiyorsa ayrıca işaretlidir. |
| **Gelecek kapsamı** | Mimari buna uygun olsun; bütün ileri medeniyet ekonomisini bu demo çalışmasında uydurup açma. |

### Çalışma sınırı

- Şimdiki görev yalnız bu yeni Markdown'ı hazırlamaktır. Kaynak, sahne, kaynak tanımı, ayar veya kayıt dosyası değiştirme yetkisi bu belge hazırlanırken kullanılmadı.
- İleride kullanıcı uygulama dediğinde aşağıdaki paket sırasını izle. Tamamlanmamış paketi tamamlanmış gibi bildirme.
- **Kullanıcı ayrıca istemedikçe Godot/Unity, oyun, otomatik test, test komutu veya build çalıştırma. Testi kullanıcı yapacak.** Bölüm 25'teki kabul ölçütleri beklenen davranışın tarifidir; test çalıştırma talimatı değildir.
- Eski kayıtları dönüştürmek zorunlu değil. Mevcut kayıtları şimdi silme. Uygulamada yeni kayıt sürümü kullan ve eski sürümü yeni ekonomiyle karıştırma.
- Genel filo/kargo/gemi görev planlayıcısı ekleme. Roketler sade hazırlık, hedef seçimi ve varış olaylarıdır.
- Yeni ham veya işlenmiş kaynak türü, demografik nüfus büyümesi ve bina level sistemi ekleme.
- Sayıları tek tanım noktasında tut. Arayüz, önizleme, satın alma ve offline aynı hesapları çağırmalı.

### Rehberin haritası

| Konu | Bölüm |
| --- | --- |
| Son cevaplar ve değişen kurallar | 2 |
| Medeniyetler, ölçekler, türler, hazır planlar | 3-6 |
| Kaynak, ortak üretim döngüsü, nüfus ve konum | 7-10 |
| Fiyat, seviye, bina ve skill katalogları | 11-13 |
| Fraktal ağaç, yıkım, sıfırlama ve taşıma | 14-16 |
| Trade, offline, Ay ve görevler | 17-20 |
| Demo, yan sistemler, kayıt ve kaynak dosyalar | 21-23 |
| Uygulama paketleri ve kabul ölçütleri | 24-25 |
| Kalan kararlar ve cevap izleme | 26-27 |

## 2. V2'den sonra kesinleşen değişiklikler

| Konu | V3 kuralı |
| --- | --- |
| Ay kaynaklarının anlamı | Ay'a özel bina tarifleri Moonstone ister. Seçilmiş ileri ana dünya binaları da Moonstone ister. İlk Ay çıkarımını başlatan genel yapılar kendi kaynağını istemez. |
| Alt katman | Tip 1 district, Tip 2 City, Tip 3 gezegen, Tip 4 güneş sistemi, Tip 5 Gökada için otomatik yerleşim ve elle düzenleme ayrı ayrı tanımlıdır. |
| Plan güncelleme | Yeni açılan içerikler otomatik bedava eklenmez. **Güncelle** teklifi hazırlanır, gerçek bedeliyle alınır. |
| Karma/Genel | Eşitlik ve boş içerik durumunun ikisinin adı **Genel**. Karma ekonomik türü kaldırılır. |
| Kaynak grubu arayüzü | Bir bina ailesi tek karttır; farklı girdiler aynı kart içinde alt satırlardır. |
| Fazla nüfus | Üst arayüzdeki toplam kapasite eksi kullanılan kapasite. City'nin ücretsiz nüfusu da hesaba girer. V2'deki bina konutuyla sınırlama kaldırılır. |
| Mineral yatakları | Yok. Gövdedeki mineral, uygun Production aracıyla o gövdenin her geçerli kuruluş yerinden çıkarılır. |
| Capital | Yakınlık hesabında yol istisnası yok. Capital da fiziksel mesafeyle çalışır. |
| Yakın kaynaklar | Her uygun kaynak tam katkısını verir. Sıra, yarıya indirme, kaynak sayısı tavanı veya gizli normalizasyon yok. |
| Üretim/bakım | Oyuncuya ortak zaman aralığında bütün kaynak giriş/çıkışları gösterilir. Ayrı gizli bakım saati yerine ortak döngü sözleşmesi kullanılır. |
| Yuva | Büyük binalar da 2 yuva kullanır ve arayüzde büyük karttır. Spaceport tek istisna değildir. |
| Fraktal ağaç | Artık askıda değil: önceki ağacın tamamı sonraki medeniyette satın alınabilir tek miras düğümü olur. Haklar bir kez uygulanır. |
| İşlenmiş ürün trade'i | Araştırmayla açılan Goods/Fuel/Rare, fabrikası kurulmadan alınabilir. |
| Taşma | Trade açılınca kapasite fazlası satış fiyatıyla krediye çevrilir. Offline kazanç sınırındaki durum ayrıca Bölüm 18'de tanımlıdır. |
| Offline | 1/10 devam eder; eski 10x/saat sınırı iptal. Kredi ve Science'ın **offline yeni kazancına** medeniyet bazlı kota önerilir. Online cüzdanlara üst sınır gelmez. |
| Demo sonrası | Dünya/Ay ekonomisi çalışır. Yeni hedefte yerleşim kapalıdır; üst evrenler incelenebilir. |
| Taşımanın anlamı | Otomatik yerleştirilmiş gerçek nesneler, ayrıntıya girilerek yeniden konumlandırılabilir. Yalnız district değil, bütün üst ölçek eşlenikleri kapsanır. |

### Eski K01-K05 artık açık soru değildir

| Eski soru | Sonuç |
| --- | --- |
| K01 | Kabul: Science alınıp satılabilir; açılmış işlenmiş ürün fabrikasız satın alınabilir. |
| K02 | 10x unutuldu. Amaç offline otomasyonun sınırsız kredi/Science üretmesini önlemek. Bölüm 18'in sayısal kota önerisi bunu karşılar. |
| K03 | Kabul: eski ekonomi durmaz; üst ölçek incelemesi açılır. |
| K04 | Kabul: kuruluş fiyat ailesi sabit, canlı işlevsel tür değişebilir. |
| K05 | Kabul: eski tutorial para/Science/eksik kaynak tamamlama ödülleri kaldırılır; yeni görevler ödülsüz yönlendirmedir. |

Kullanıcının dosyada değiştirdiği uzaklık katkıları **%0 / %12,5 / %25 / %37,5 / %50** olarak korunmuştur. V2'de kalmış eski %35/%45 karşılaştırmaları kullanılmaz.

## 3. Her medeniyette dört katman ve otomatik merkez

| Tip | Kapsayıcı harita | Büyük yerleşim | Alt yerleşim | Üst görünümde panelden yönetilen en alt nesne |
| --- | --- | --- | --- | --- |
| 0 | Gezegen | City | District | Bina |
| 1 | Güneş sistemi | Gezegen | City | District |
| 2 | Gökada | Güneş sistemi | Gezegen | City |
| 3 | Galaksi | Gökada | Güneş sistemi | Gezegen |
| 4 | Evren | Galaksi | Gökada | Güneş sistemi |
| 5 | Paralel Evrenler | Evren | Galaksi | Gökada |

Gökada ve Galaksi kullanıcının verdiği iki ayrı oyun katmanıdır; birleştirme veya araya yeni küme katmanı koyma.

| Tip | Yerleşilen nesne | Otomatik merkez alt nesnesi | Etki yönü |
| --- | --- | --- | --- |
| 0 | City | Capital District | Yakındaki districtlere. |
| 1 | Gezegen | Orbital City | Yakındaki City'lere. |
| 2 | Güneş sistemi | Dyson Sphere Gezegen | Yakındaki gezegenlere. |
| 3 | Gökada | Stellar Engine System | Yakındaki güneş sistemlerine. |
| 4 | Galaksi | Black Hole Gökada | Yakındaki Gökada'lara. |
| 5 | Evren | Spacetime Galaksi | Yakındaki galaksilere. |

Otomatik merkez ilk yerleşim işleminin parçasıdır. Aynı ekranı açmak, planı tekrar uygulamak veya kayıt yüklemek ikinci merkez kurmaz. Merkez bir üretim ailesi değildir; tür sayımına katılmaz.

### Otomatik plan her alt katmanda ne yapar?

| Tip | En alt nesnenin gerçek davranışı | Hazır plan | Elle yönetim |
| --- | --- | --- | --- |
| 0 | Bina bağımsız yüzey koordinatı taşımaz. Districtinin koşullarını miras alır. | District yuvalarına gerçek bina adetleri kurar. | Panelden adet, girdi, duraklatma, yıkım ve başka uygun districte aktarım. |
| 1 | District gerçek yüzey konumu ve bütün konum bonuslarını korur. | City içine districtleri ve onların gerçek binalarını yerleştirir. | Gezegen görünümüne in; district konumunu, alt binalarını ve planını düzenle. |
| 2 | City gerçek konumu, Capital'ı ve districtleriyle yaşar. | Gezegene City'leri ve alt ağaçlarını yerleştirir. | Gezegene in; City konumundan bina girdisine kadar düzenle. |
| 3 | Gezegen gerçek sistem konumu ve bütün yerleşimleriyle yaşar. | Güneş sistemindeki gezegen yerleşim planlarını kurar. Doğal gövdeyi bedava kopyalamaz. | Sisteme in; gezegenin konumunu ilgili düzenleme yetkisiyle değiştir, City/district/binalara in. |
| 4 | Güneş sistemi gerçek Gökada konumu ve gezegenleriyle yaşar. | Gökada içine sistem yerleşim planlarını uygular. | Gökada'ya in; sistemin konumunu ve gezegenlere kadar alt içeriği düzenle. |
| 5 | Gökada gerçek galaksi konumu ve güneş sistemleriyle yaşar. | Galaksi içinde Gökada yerleşim planlarını uygular. | Galaksiye in; Gökada konumunu ve sistem/gezegen/City ayrıntılarını düzenle. |

**Tek gerçek nesne kuralı:** Üstte görülen özet ile alttaki ayrıntı aynı kimlik ve aynı alt ağaca bakar. Özet ikinci kez gelir üretmez. Kamera aşağı indiğinde mevcut nesneler yeniden satın alınmaz veya ücretsiz yeniden oluşturulmaz.

**Uzamsızlık yalnız binaya aittir.** Panelde listeleniyor diye district/City/gezegenin konum ilişkilerini silme. Üst ölçekteki otomatik plan onun yerini oyuncu adına seçer; seçim sonucu hâlâ gerçektir.

Üst medeniyet içerikleri için veri sözleşmesi bu tabloya uygun kurulacak. Demo bitişinden sonra bütün Tip 1-5 ekonomisini oynatmak bu çalışmanın kapsamı değildir.

## 4. Her ölçekte 50 tür üretmek yerine rol ve kuruluş planı

**Önerilen tasarım:** Her medeniyete önceki 50 bina adını kopyalayıp 50 district, sonra 50 City tanımı yaratmayalım. Aile, kuruluş planı ve profil birbirinden ayrı olsun.

| Bilgi | Örnek | Ekonomide kullanımı |
| --- | --- | --- |
| Aile | Energy / Production / Science / Residential / Commercial / Genel | Yakınlık ilişkisi, temel rol ve fiyat ailesi. |
| Profil | Küçük / Standart / Yoğun | Yuva, yatırım, çalışan ve çıktı tercihi. |
| Kuruluş planı | Dağ Araştırma City planı | Gerçek alt nesnelerin listesi ve konumlandırma tercihi. |
| Coğrafi uyarlama | Kıyı / rüzgâr / sıcak saha | Erişilebilir bina veya alt plan seçimi. |
| Teknolojik dönem | Başlangıç / gelişmiş / Ay sonrası | Açılmış içeriği filtreler. |

Merkez, lojistik ve sefer altyapısı destek rolleridir. Bunları ana ekonomi ailelerinin 50 ayrı eşanlamlı türüne dönüştürme.

### Tip 0 içerik sunumu önerisi

Ana katalog yaklaşık **24 çekirdek model** sunabilir: 6 enerji, 7 çıkarım/işleme, 3 bilim, 3 konut, 3 ticaret, 2 Spaceport. Küçük, kıyı/dağ, Ay ve Capital destekleri ayrı koşullu seçeneklerdir. Bu sayı başlangıçta 24 açık bina demek değildir.

Bölüm 12 bütün eski/yeni adayları kaybetmeden gösterir. Her adayı ana listede aynı anda göstermek zorunlu değildir. Kullanıcının “yaklaşık 20” tahmini kesin içerik sınırı olarak alınmadı. Katalog büyüklüğü R02'de konuşulabilir; tip başına 50 tür varsayımıyla kaynak üretme.

### Yüksek tier binaların gelecekteki anlamı

- Tier 1-3, Tip 0'da kullanılabilir; seçilmiş modeller Ay sonrası açılır.
- Tip 1'de üretim gerçekte hâlâ bu alt binalardan gelir. Oyuncu district planı üzerinden yönetir; isterse ayrıntıya inebilir.
- Bina tier'ını her medeniyette sonsuza dek büyütmek zorunda değiliz. Yeni ana ilerleme, yeni en alt nesnenin profili ve hazır planıdır.
- Eski Tier 4 Antimatter/Quantum/Arcology/Interstellar Bank tanımlarını sırf dosyada var diye yeni bina olarak açma. Bunlar üst ölçeğin enerji/bilim/konut/ticaret planlarına tema veya açılış olarak eşlenir.
- Üst planın çıktısını, içindeki binaların çıktısına ikinci bir sabit gelir olarak ekleme. Tek ekonomi, farklı yönetim ölçeği vardır.

## 5. Tür, isim ve kuruluş fiyat ailesi

Her yerleşimde ayrı alanlar tutulur:

| Alan | Davranış |
| --- | --- |
| Oyuncu adı | Kullanıcı değiştirmedikçe aynı kalır. |
| Kuruluş planı ve sürümü | Hangi gerçek alt içerikle kurulduğunu ve son güncellemesini gösterir. |
| Canlı işlevsel aile | Tamamlanmış alt yerleşimlerin baskın sayısına göre değişir. |
| Kuruluş fiyat ailesi | Onaylanan planın ailesi; bedel alınırken sabitlenir. Sonraki işlev değişimi bunu değiştirmez. |

### Otomatik tür ataması

1. Tip 0'da normal City ekonomik tür taşımaz.
2. Tip 1'e geçince tamamlanmış normal districtler sayılır. Capital sayılmaz. Seviye, bina adedi ve üretim hızı ağırlık vermez.
3. Tek başına en yüksek sayılı aile canlı türdür.
4. En yüksek sayıda eşitlik veya merkez dışında hiç çocuk yoksa **Genel**.
5. Tip 2'de gezegen City ailelerinden; sonraki tiplerde aynı kural alt yerleşim ailelerinden hesaplanır.
6. Ekleme/yıkım/aktarım tamamlandığında canlı tür yeniden hesaplanır. Tür kendi başına gizli çıktı bonusu değildir.

Örnek: Riva'da 3 Production ve 2 Science varsa Production City. 3/3 olursa Genel City. İsim Riva kalır.

İlk medeniyet dönüşümünde mevcut yerleşimlerin fiyat ailesi o andaki sınıflandırmadan bir kez atanır; geçmişe dönük ödeme alınmaz. Daha sonra değiştirilmez. Kullanıcının kabul ettiği K04 budur.

“Kendi City'ni/gezegenini kur” bir **elle kuruluş yöntemi**. Boş fiyat ailesi veya sınırsız yeni indirim türü değildir. Özel plan onayında fiyat ailesi görünür ve sayaca katılır. Genel de tek gerçek fiyat ailesidir; her özel isim için yeni Genel sayacı oluşturulmaz.

## 6. Hazır plan, Güncelle ve elle düzenleme

### Plan oluşturma

- Yalnız keşfedilmiş/araştırılmış ve o konumda geçerli içerik seçilir.
- Enerji, nüfus, yuva, gövde boyutu ve minimum yerleşim aralığı gözetilir.
- Yakın küme, bağımsız uzak veya dengeli yerleşim tercihi planın girdisidir.
- Gerçek alt nesnelerin bütün kredi ve isimli malzeme bedelleri toplanır. Aynı tür tekrarları teklif içinde sırayla fiyatlandırılır.
- Bedel bir kez alınır; her ödeme gerçek nesnesinin maliyet kaydına dağıtılır. Ebeveyne aynı toplam ikinci defa yazılmaz.
- Plan ekranda gösterilir. Yer veya para yoksa sessiz yarım kuruluş yapılmaz; daha küçük kapsam açıkça teklif edilir.

### Yeni içerik açılınca Güncelle

Skill, miras düğümü veya kaynak açılışı ilgili planlarda güncelleme önerisi üretir. **Hak açılması yeni bina adetlerini bedava vermez.**

| Aşama | Zorunlu davranış |
| --- | --- |
| 1. Farkı bul | Uygulanmış plan sürümü ile güncel planı ve mevcut gerçek nesneleri karşılaştır. |
| 2. Önizle | Eklenecek, değiştirilecek ve kalacak nesneleri; net çıktı, yuva, nüfus ve enerji farkını göster. |
| 3. Fiyatlandır | Yeni adetler gerçek kuruluş fiyatıyla; kaldırılacaklar gerçek ödeme kaydına göre iadeyle. |
| 4. Elle değişiklikleri koru | Elle sabitlenmiş nesneleri taşıma/yıkma. Çakışmayı göster. |
| 5. Uygula | Tek işlem kimliğiyle bedeli al ve işi kuyruğa koy. Tekrar tıklamak ikinci iş yaratmaz. |
| 6. Kaydet | Plan sürümünü ancak alınan kapsam gerçekten tamamlanınca güncelle. |

**Varsayılan Güncelle yalnız boş kapasiteye ekleme yapar.** Dolu planda değiştirme gerekiyorsa “değiştirerek güncelle” ayrı önizleme olur. Bina level'ı eklenmez; örneğin iki küçük binayı kaldırıp bir büyük model kurmak açık yıkım + kuruluş işlemidir.

### Aynı kartın ortak işlemleri

`Güncelle`, `Ayrıntıya in`, `Elle düzenle`, `Taşı`, `İçeriği temizle`, `Sıfırla`, `Yık` işlemleri uygun seviyelerde sunulur. Her tuş her nesnede açık olmak zorunda değil; eksik skill/uygunluk nedeni gösterilir. Yıkım ve yeniden kurma, taşıma skill'i yokken de mümkün kalır.

Yeni planın daha verimli olduğu gerçek mevcut koşullardan hesaplanır. Uygun rüzgârı olmayan yere yalnız tier'ı yüksek diye türbin seçilmez. Ayrıntıdaki düzenlenmiş nesne üstteki aynı satırı günceller.

## 7. Kaynaklar: gövde genelinde çıkarım ve tek aile kartı

### Kaynak dağılımı

| Tip | Açılabilecek hamlar | İlgili üretim katmanı |
| --- | --- | --- |
| 0 | Ferrite, Moonstone | Production District; ana dünya ve Ay. |
| 1 | Cinderite, Cryolite | Production City; uygun volkanik/buzlu gövde. |
| 2 | Dune Quartz, Helion | Production gezegeni; çöl/gaz gövde ailesi. |
| 3 | Astralite, Aurorium | Production güneş sistemi; kristal/metal zengin sistem ailesi. |
| 4 | Xenite, Nyxium | Production Gökada; sıra dışı madde/karanlık bölge ailesi. |
| 5 | Quantium, Singularite | Production galaksi; anomali/yoğun kara delik bölgesi ailesi. |

İşlenmişler değişmez: Goods, Fuel, Rare. Üst katman tanımları ileride içerik üretimi içindir; demoda keşfedilemez.

### Keşif kuralı

1. Gövde verisi hangi mineralleri içerdiğini belirler. Yerel yatak veya mineral yoğunluk haritası yoktur.
2. Gerekli medeniyet tipi ve o gövdede tamamlanmış uygun Production aracı birlikte gerekir.
3. İlk Production District gibi kendi başına çıkaran birim veya Mine gibi çıkarım aracı tamamlanınca, o gövdenin erişilebilir mineralleri keşfedilir.
4. Aynı gövdedeki geçerli **her** Production konumundan çıkarılabilir. Coğrafya miktarı etkiler; mineral türünü açıp kapatmaz.
5. Keşif kalıcıdır. Son üretici yıkılınca kaynak adı ve stok gizlenmez; yerel aktif çıkarım durur.
6. Keşif öncesinde ad, ikon, stok, trade fiyatı ve isimli maliyet satırı sızdırılmaz. Gelecek harita önizlemesi de bu kilidi aşmaz.

Ay'da Production'ın regolit üzerinde olması gerekmez. Her geçerli kuruluş yeri Moonstone çıkarır. İlk 100 Moonstone görevi gerçek üretim olaylarını sayar; keşif, ticaret ve iade bunu saymaz.

İlk çıkarımı açacak yapı kendi gizli hammaddesini istemez. Ana dünyada ilk Production yalnız krediyle; Ay'da ilk Production 300 kredi + 30 Ferrite ile kurulur.

### İşleme ve ödeme

| Tür | Kural |
| --- | --- |
| Üretim girdisi | Oyuncu mineral seçer. Kendiliğinden en nadiri seçilmez. |
| Malzeme bedeli | `100 Ferrite + 50 Moonstone` gibi isimli miktarlar. Genel `raw` cüzdanından ikame ödeme yapılmaz. |
| Nadirlik verimi | R1 ×1, R2 ×1,75; sonraki her nadirlik +0,75. Yalnız işlenmiş çıktı hesabına bir kez. |
| Mineral bitince | O girdiyi kullanan adetler bekler. Başka mineral otomatik harcanmaz. |
| Girdi değişince | Başlamış turun ödenmiş girdisi/çıktısı korunur; seçim sonraki turda etkili. |

### Tek aile kartı, farklı girdi satırları

```text
Goods Factory                           Toplam: 5 adet
  Ferrite kullanan: 3 adet   -12 Ferrite -> +6 Goods / 20 sn
  Moonstone kullanan: 2 adet -8 Moonstone -> +7 Goods / 20 sn
  Toplam: +13 Goods / 20 sn, enerji ve çalışan ihtiyacı
```

Bu örnek bonuslar öncesidir. Aynı binanın girdileri için ayrı ana kartlar açılmaz. Alt satırlar oyuncu tarafından dağıtılır. Tekrar fiyatı aynı ailede toplam 5 adedi görür; iki mineral beşer ücretsiz ilk fiyat yaratmaz.

Stok 3 binayı değil 2 binayı besliyorsa 2'si çalışır, biri bekler. Gruplar oyuncu önceliğiyle, eşit öncelikte dönüşümlü çalıştırılır. Aynı turu iki eksik mineral türünü toplayarak besleme yapılmaz.

## 8. Tek kaynak döngüsü, ortak kart ve kapasite ayrımı

**Kesin yön:** Oyuncu her binada aynı zaman aralığıyla artan ve azalan kaynakları görür. “Üretim başka, bakım görünmez başka saat” sunumu kaldırılır.

**Sayısal taslak:** Bütün stok tarifleri **20 ekonomi saniyelik döngüye** çevrilir. Mevcut dakikalık hız korunur: 6 Science/30 sn = 4 Science/20 sn. 1 Goods/60 sn gider = 20 saniyede 1/3 Goods. İç hesap kesirli değeri korur; arayüz yuvarlar, her turda değeri kesip kayıp yaratmaz.

Her tanımda tek döngü kaydı bulunur:

| Alan | Örnek |
| --- | --- |
| Tüketilen stoklar | -12 seçili mineral, -0,33 Goods. |
| Üretilen stoklar | +6 taban Goods; nadirlik ve çıktı bonusu ayrıca. |
| Etkin enerji/konut kapasitesi | +9 enerji veya +7.500 konut. |
| Ayrılan çalışan | 750. |
| Yuva | 2. |

Konut zamanla büyüyen insan stoku değildir. `+7.500 konut` her 20 saniyede 7.500 insan eklemek anlamına gelmez. Enerji de eski akış/kapasite rolünü korur, yeni depolanan pil kaynağına dönüşmez. **Aynı kart ve aynı döngü kullanmak, stok ile kapasiteyi aynı sayaca toplamak değildir.**

### Hesap ve işlem sırası

1. Önce biten inşaat/taşıma olaylarını işle.
2. Aynı stokun iki işe harcanmasını önleyecek biçimde, başlayabilecek adetler için döngünün bütün stok giderlerini ayır.
3. Gideri ödenmeyen adet yeni döngüye başlamaz. Kapasite veren tüketimli bina bu ücretli dönem için etkinleşmez.
4. Etkin kapasite/çalışan ve enerji dengelerini hesapla.
5. Stok çıktısına Bölüm 9'daki verim cezasını uygula. Bu taslakta giderler tam döngü bedeli; açık varsa çıktı düşer. Gizli ikinci bakım saati yok.
6. Döngü sonunda vaat edilmiş çıktıyı bir kez ver; trade/depo/ offline kota kurallarını aynı kaynak akışı üzerinden işle.
7. Sonraki döngü için durum ve gerçek net değerleri yeniden hesapla.

Bu V3 taslağı, “ceza üretim turunu uzatır ama bakım ayrı saatte azalır” eski modelinin yerine geçer. Tek çevrimin basit karşılığı: **verimsiz çalışırken aynı döngüde daha az çıktı**. Formül ve kart aynı sonucu göstermeli.

Temel Goods: `-4 ham -> +2 Goods / 20 sn`. Fuel: `-8 ham -> +2 Fuel`. Rare: `-12 ham -> +1 Rare`. Tier miktarları aynı oranla ×3/×9 büyür. R2 Moonstone ile çıktılar 3,5 / 3,5 / 1,75 olur.

Saf pasif kapasitede stok giriş/çıkışı yoksa `Kaynak tüketimi yok; etkin kapasite +...` yazılır. Sahte tüketim veya sahte nüfus üretimi icat edilmez. İnşaat süresi yine ayrı gerçek işlemdir.

## 9. Global nüfus ve enerji

Nüfus bütün imparatorluğun konut/iş gücü kapasitesidir; zamanla büyümez.

```text
Boş nüfus = en fazla(0, toplam nüfus kapasitesi - kullanılan nüfus)
```

Üst arayüzdeki toplam ve kullanılan değerler tek doğru kaynaktır. **City'nin ücretsiz 15.000 kapasitesi dahil bütün kapasite sayılır.** Binaların konutuyla sınırlama, uygun/uygunsuz ücretsiz nüfus ayrımı yoktur.

### Fazla nüfus skill'leri

| Skill | Sayısal taslak |
| --- | --- |
| Sivil Girişimler | Her 1.000 boş nüfus: +10 kredi/dk. |
| Serbest Araştırma | Her 1.000 boş nüfus: +2 Science/dk. |
| Üretim Rezervi | Boş kapasite oranının %20'si kadar ham/işlenmiş bonusu; %50 boşsa +%10, tamamen boşsa +%20. |

Örnek: Toplam 30.000, kullanılan 20.000 -> boş 10.000. İlk iki skill +100 kredi/dk ve +20 Science/dk sağlar. Doğrudan 20 saniye kartında +33,33 kredi ve +6,67 Science eşdeğeri gösterilebilir.

İlk City tek başına 15.000 kapasite, 2.000 yük verdiğinde boş 13.000'dir. Bu iki skill alınmışsa +130 kredi ve +26 Science/dk sağlar. City'nin +60 kredi/+4 Science tabanıyla toplam **190 kredi ve 30 Science/dk** olur. Bu, kullanıcının ücretsiz kapasitenin de çalışması kararıdır; eski V2 örnekleri buna göre değiştirilmiştir.

Nüfus gelirine konum bonusu yeniden uygulanmaz: toplam nüfus zaten konumdan etkilenmiş kapasitedir. Konut kendi çıktısını büyüten gelir döngüsüne sokulmaz.

### Açık cezası

```text
Karşılama = en fazla 1 olacak şekilde kapasite / ihtiyaç
Verim = 0,5 + 0,5 × karşılama
```

İhtiyaç 0 ise karşılama 1. 30.000 kapasite/40.000 yük -> %87,5; 30.000/60.000 -> %75. Nüfus cezası global stok üretimine, enerji cezası enerji isteyen stok üreticilerine uygulanır. İkisi varsa çarpılır. İki %75 ceza birlikte %56,25 çıktı verir.

Konut ve enerji kapasitesini aynı cezayla tekrar azaltıp kendi kendini büyüten açık yaratma. Gideri ödenmediği için kapanan bir kapasite binası farklıdır; gerçek etkin kapasiteden düşer. Kaynak kartı mevcut verimdeki gerçek üretim ve tam döngü giderini gösterir.

## 10. Coğrafya, mesafe ve tam yakınlık katkısı

### Üç coğrafi durum

| Konum | Tam bonusun payı |
| --- | ---: |
| Dışarıda | %0 |
| Tip 0'da sınırın dışındaki 250 km yakın kuşakta | %50 |
| Görünen özelliğin üzerinde | %100 |

Farklı coğrafya türleri toplanır. Aynı türün City ve district üzerinden gelen etkisi bir çıktıda tekrar sayılmaz: **coğrafya türü + çıktı ailesi** için en güçlü geçerli katkı kullanılır. Dağ yakını +%10 Production ve başka dağ üzerinde +%20 -> dağ toplamı +%20. Krater yakını ayrıca +%5 ise toplam +%25.

| Görünen özellik | Tam rol bonusu |
| --- | --- |
| Dağ | Production +%20, Science +%30. |
|  |
| Ova | Residential +%20, Commercial +%10. |
|  |
| Orman | Residential +%10, Science +%10. |
| Deniz kıyısı | Residential +%20, Commercial +%20, tidal enerji +%20. |
| Göl kenarı | Residential +%20, Science +%10; gelgit alanı değil. |
| Nehir | Residential +%10, Commercial +%20. |
|  |
| Çöl | Solar enerji +%30, Science +%10. |
| Tundra | Science +%20, Residential +%10. |
| Buzul | Science +%20. |
| Volkanik alan | Jeotermal +%30, Production +%20. |
| Jeotermal yarık | Jeotermal +%40; görünür ayrı özellikse volkanla toplanabilir. |
| Rüzgârlı bölge | Wind enerji +%30; görünür yönlü bulut/toz/bitki hareketi. |
|  |
| Eski yerleşim | Science +%30, Commercial +%20; henüz hikâye ödülü yok. |
|  |
| Krater | Production +%10, Science +%20. |
|  |
|  |

**Ferrite yatağı satırı kaldırıldı.** Mineralin bulunma haritası ile yukarıdaki görünen arazi birbirine bağlanmaz. Bütün Ay konumlarından Moonstone çıkarılır; örneğin krater coğrafyası yalnız miktarı değiştirebilir.

Görsel hazır değilse görünmez özellik üzerinden bonus verme. Arazi butonsuz ayırt edilebilmeli. Energy district tabanı, geçerli enerji ailelerinden en yüksek coğrafi toplamı bir kez kullanır. Wind binası yalnız Wind, Solar yalnız Solar özelliklerini alır.

### Beş mesafe etiketi

| Mesafe | Tip 0 gerçek yüzey uzaklığı | Uzaklık bonusu |
| --- | --- | ---: |
| Çok yakın | 0-500 km | %0 |
| Yakın | 500-1.000 km | +%12,5 |
| Orta | 1.000-2.000 km | +%25 |
| Uzak | 2.000-3.500 km | +%37,5 |
| Çok uzak | 3.500 km ve üstü | +%50 |

Sınırlar kodda tek anlamlı olacak: 500 dahil çok yakın, sonra 1.000 dahil yakın, sonra 2.000 dahil orta, sonra 3.500'den küçük uzak; 3.500 ve üzeri çok uzak. Temel arayüz etiketi gösterir, ayrıntıda km görülebilir; derece kullanılmaz.

Tip 0 minimum district aralığı 250 km, City merkez aralığı 3.000 km. Dünya referans yarıçapı 6.000 km, Ay oranı 0,45 ise Ay yüzeyi dünyanın %20,25'i. Görsel zoom bu uzaklığı değiştirmez. Dar City erişim yarıçapı uzak stratejiyi baştan engellemez; ebeveyn kapasitesi ve fiziksel yer geçerlidir.

Üst ölçekler aynı etiketleri korur, fiziksel birimleri haritanın mesafesine göre büyür. Demo uygulamasında Tip 0 km değerlerini bütün evrene kopyalama. Üst haritalar oynanabilir hale getirilirken harita başına açık `distance_profile` kullanılacak. Coğrafi yakınlık kuşağı da bu profilin alanıdır; 250 km bütün üst ölçeklere aynen taşınmaz.

### Yakınlık: bütün uygun kaynaklar tam sayılır

Sayısal taslak:

| Kaynak uzaklığı | Aynı tür normal kaynağın katkısı | Merkez katkısı |
| --- | ---: | ---: |
| Çok yakın | +%10 | +%10 |
| Yakın | +%5 | +%5 |
| Daha uzak | 0 | 0 |

Normal kaynak aynı aileyi destekler; merkez uygun bütün aileleri destekler. Çapraz aile skill'i ilişkiyi genişletir. Bu, kaynak binanın kendi üretiminin aktarılması değildir; alıcının tabanına sabit yüzde eklenir.

- Her uygun nesne tam katkı verir. İlkine %10, ikincisine %5, üçüncüsüne %2,5 şeklinde sıra indirimi **yoktur**.
- Yol, kesişim, kalınlık ve araya giren nesne hesaba etki etmez. Capital için de yol şartı yoktur.
- Aynı ekonomik haritada gerçek yakın kaynaklar sayılır; panelde gizlenmiş nesneler hesaptan düşmez.
- Merkezlerde de aynı harita ve aynı katman kapsamı geçerlidir: başka City'ye ait olsa bile uygun mesafedeki merkez katkı verir. Yol veya yalnız kendi ebeveyninin merkezi şartı yoktur. Kendisi hariç bütün uygun merkezler tam sayılır.
- Aynı kaynak kimliği aynı ilişkiyle bir kez sayılır. Kendisini kaynak saymaz.
- Uzaklık, merkezler dahil en yakın diğer tamamlanmış aynı katman nesnesine göre belirlenir. Böylece Capital'ın yanındaki yapı aynı anda “herkesten çok uzak” sayılmaz.
- İnşaat planı gerçek kaynak değildir; tamamlanınca katılır. Durdurulmuş ama fiziksel olarak duran tamamlanmış yerleşim mesafeden kaybolmaz.

| Hepsi çok yakın aynı aile kaynağı | Yakınlık | Yakın merkez de varsa |
| ---: | ---: | ---: |
| 1 | +%10 | +%20 |
| 2 | +%20 | +%30 |
| 4 | +%40 | +%50 |
| 8 | +%80 | +%90 |
| 20 | +%200 | +%210 |

Dört çok yakın kaynak + merkez %50 ile, bağımsız çok uzak yerleşim %50 aynı başlangıç örneğine ulaşır. Daha büyük kümeler daha yüksek bonus verebilir. **Tam ve sınırsız katkı korunurken her büyüklükte yakın/uzak eşitliği vaat edilemez.** Bu sonucu gizli tavanla değiştirme. Kümelenmenin bedeli gerçek kuruluş, aynı tür tekrar maliyeti, nüfus/enerji, kapasite ve fiziksel alan olacak; uzak düzen iyi coğrafya ve daha az eşlikçi yatırımıyla oynanır.

Bu ilişkiler başlangıçtan açıktır. Skill'ler stratejiyi güçlendirir, yakınlığın varlığını satın aldırmaz. Araştırmalar kaynak başına katkıyı açıkça artırabilir; toplamı ikinci kez saymaz.

### Performans kuralı

Her karede bütün imparatorluk çiftlerini karşılaştırma. Gövde/harita başına konum hücreleri tut; yarıçapla kesişen hücrelerden **bütün** uygun nesneleri al. Kuruluş, yıkım, taşıma, aile veya ilişki skill'i değişince etkilenen alanları güncelle. “İlk 20 kaynağı kullan” gibi hesabı değiştiren kestirme yapma.

## 11. Ortak fiyat, seviye, yuva ve çıktı matematiği

Bütün sayılar oynanışta ölçülmemiş başlangıç taslağıdır. Kullanıcı matematik katsayısını seçmek zorunda değil; geri bildirimden sonra ortak katsayılar yeniden hesaplanır.

### Başlangıç ve district tabanları

| Parametre | Değer |
| --- | --- |
| Yeni oyun | 3.000 kredi, 450 Science, 0 malzeme. |
| İlk City | Gövde başına ilk City ücretsiz; 15.000 nüfus kapasitesi, 2.000 yük, 8 enerji. |
| City stok tabanı | 20 kredi ve 4/3 Science / 20 sn; dakikada 60 kredi ve 4 Science. |
| Production tabanı | 10 seçili yerel ham / 20 sn. |
| Science tabanı | 2 Science / 20 sn. |
| Commercial tabanı | 10 kredi / 20 sn. |
| Residential tabanı | 1.500 nüfus kapasitesi. |
| Energy tabanı | 3 etkin enerji. |
| Yeni normal district | 300 kredi, 500 yük; Residential yükü 0. |
| Capital kuruluş yükü | City'nin 2.000 yükünün içinde; ikinci kez ekleme. |
| Temel aileler | Başlangıçtan açık. Goods işleme de açık. |
| Genel inşaat | 4 sn; küçük modeller 2 sn, özel sefer yapıları kendi süreleri. |

450 Science örneği: Ticaret Erişimi 150 + Sivil Girişimler 150 + Serbest Araştırma 150. Ticaret Erişimi ortak dal; diğer ikisinin ana dalı Nüfus. Çapraz dal zammı bu örneği 453'e çıkarmaz. Oyuncu bu üçlüyü seçmek zorunda değil.

### Aynı tür tekrar fiyatı

| Satın alınan | Tekrar sayacı | Kredi büyümesi |
| --- | --- | ---: |
| Bina | Aynı districtte aynı modelin tamamlanmış + inşaattaki adedi | ×1,20 / adet |
| District | Aynı City'de aynı fiyat ailesinin adedi | ×1,50 / adet |
| Tip 0 City | Aynı gövdede mevcut normal City adedi | İlk ücretsiz; sonra 2.000, 3.000, 4.500... |
| Üst yerleşim | Aynı ebeveynde sabit kuruluş fiyat ailesi | ×1,50 / adet; taban yeni ölçeğin planından. |

Yıkım sayacı azaltır. Başka mineral seçmek, grup bölmek, isim değiştirmek ve plan sürümü değiştirmek yeni indirim sayacı açmaz. Yalnız krediler tekrar katsayısıyla artar; isimli malzeme listesi her adette ikinci kez şişmez.

150 tabanlı bina: 150 / 180 / 216 / 259,20 / 311,04. 300 tabanlı district: 300 / 450 / 675 / 1.012,50 / 1.518,75.

### Bina tier ve boyutu

| Profil | Tier miktarı | Standart çalışan | Standart yuva |
| --- | ---: | ---: | ---: |
| Küçük Tier 1 | ×0,5 | 125 | 1 |
| Normal Tier 1 | ×1 | 250 | 1 |
| Büyük Tier 1 | Karttaki açık profil | Karttaki açık yük | 2 |
| Tier 2 | ×3 | 750 | 2 |
| Tier 3 | ×9 | 2.250 | 2 |

Konut çalışan istemez. Depo/desteklerin açık profili kendi tablosundadır. Tier 4 bina otomatik açılmaz; ileri ana ilerleme üst ölçeğin kuruluş planlarına taşınır.

Katalog çıktıları tier'ı **zaten içerir**. Institute 12 Science/20 sn diye yazıldıysa tekrar ×3 uygulama. Bina level çarpanı kullanma.

### İsimli kuruluş malzemesi

| Kural | Krediye ek malzeme |
| --- | --- |
| Genel Tier 1 | Yok. |
| Genel Tier 2 | 30 Ferrite + 5 Goods. |
| Genel Tier 3 | 90 Ferrite + 15 Goods + 5 Fuel + 2 Rare. |
| Particle Accelerator | Genel T3 + **60 Moonstone**. |
| Luxury Spires | Genel T3 + **60 Moonstone**. |
| Commodity Exchange | Genel T3 + **90 Moonstone**. |
| Planetary Command | Genel T3 + **60 Moonstone**. |
| Fusion / Mantle | Genel T3; Moonstone 0, Ay öncesi yoğunluk alternatifleri. |
| Ay'a özel modeller | Bölüm 12/19'daki kendi listesi; genel tier listesi ayrıca eklenmez. |

Moonstone isteyen Dünya modellerinin teklifinde Moonstone keşfi de gerekir. Keşiften önce adını/miktarını sızdıran tarif gösterilmez. İlk Ay seferi için bunların hiçbiri zorunlu değildir.

### District seviyesi

```text
Çıktı çarpanı = 1,25^(seviye - 1)
Normal yuva = 3 + 2 × (seviye - 1)
Capital yuvası = seviye
Yükseltme kredi = 250 × 1,25^(mevcut seviye - 1)
Ek yük = 500 × 1,25^(mevcut seviye - 1)
Süre = 5 × hedef seviye saniye
```

Maksimum 10. Residential ek yükü 0. Eski yol komşusu seviye şartı kalkar. Çocuk bina çıktıları da district seviye çarpanını bir kez alır.

| Seviye | Çıktı | Normal yuva | Capital yuvası |
| ---: | ---: | ---: | ---: |
| 1 | ×1 | 3 | 1 |
| 2 | ×1,25 | 5 | 2 |
| 3 | ×1,5625 | 7 | 3 |
| 5 | ×2,4414 | 11 | 5 |
| 10 | ×7,4506 | 21 | 10 |

| Geçiş | Kredi | Ek yük | Süre |
| --- | ---: | ---: | ---: |
| 1 -> 2 | 250 | 500 | 10 sn |
| 2 -> 3 | 312,50 | 625 | 15 sn |
| 3 -> 4 | 390,625 | 781,25 | 20 sn |
| 4 -> 5 | 488,28125 | 976,5625 | 25 sn |

İç hesap gerçek değeri korur; arayüz yuvarlar. Kredi küçük para biriminde tahsil edilir; teklif ve gerçek ödeme aynı yuvarlama kuralını kullanır.

### City ve gezegen

City normal çocuk kapasitesi `3 + 2 × (seviye - 1)`; Capital bu sayıya dahil değil. Gezegen City kapasitesi `seviye + 1`. Fiziksel yer ayrıca sınırdır.

| City hedefi | Gereken tamamlanmış normal district seviyeleri toplamı | Kredi | Ek yük | Süre |
| --- | ---: | ---: | ---: | ---: |
| Lv2 | 3 | 1.000 | 2.000 | 20 sn |
| Lv3 | 6 | 1.500 | 2.500 | 30 sn |
| Lv4 | 10 | 2.250 | 3.125 | 40 sn |
| Lv5 | 15 | 3.375 | 3.906,25 | 50 sn |

| Gezegen hedefi | City seviyeleri toplamı | İsimli bedel | Süre |
| --- | ---: | --- | ---: |
| Lv2 | 3 | 2.000 kredi + 100 Ferrite | 10 sn |
| Lv3 | 5 | 3.000 kredi + 150 Ferrite + 10 Goods | 15 sn |
| Lv4 | 7 | 4.500 kredi + 225 Ferrite + 20 Goods | 20 sn |
| Lv5 | 9 | 6.750 kredi + 300 Ferrite + 50 Moonstone + 10 Fuel + 5 Rare | 25 sn |

Gezegen seviyesi Fuel/Rare araştırmasını açan kapı değildir. Lv5 Ay sonrası seçenektir, ilk Ay seferinin şartı değil.

### Çıktı hesabının tek sözleşmesi

```text
Katalogdaki tek bina tabanı × çalışan adet
× district seviye çarpanı
× (1 + tekilleştirilmiş coğrafya toplamı)
× (1 + yakınlık toplamı + uzaklık + merkez toplamı)
× (1 + uygun araştırma/destek toplamı)
× stok çıktısıysa nüfus/enerji verimi
× işlenmiş çıktıysa seçilen mineral nadirlik verimi
```

Girdi ve giderler bu çıktı çarpanlarıyla artmaz. Aynı ödeme/bonus miras yolunda ikinci kez uygulanmaz. Bina tabanında veya kaydedilmiş çıktıda nadirlik zaten uygulanmış değer saklayıp bir daha çarpma.

## 12. Tip 0 bina kataloğu ve büyük kartlar

Bu bölüm V2'nin bina sayılarını ortak döngü ve yeni yuva kararına taşır. Stok değerleri **20 ekonomi saniyesi** içindir. `G/F/R` sırasıyla Goods/Fuel/Rare gideridir. `0,33` gösterimi iç hesapta 1/3'tür. Enerji ve konut etkin kapasitedir; stok çıktısı değildir.

Kredi ilk adettir. Genel kuruluş malzemesi Bölüm 11'den eklenir; özel Ay tarifleri onun yerine geçer. Belirtilmeyen çalışan T1 250, T2 750, T3 2.250; küçük model 125. Bütün konutlar 0 çalışan. Normal küçük bina inşaatı 2 sn, diğer standartlar 4 sn.

### Energy

| Model / eski kimlik | Tier | Yuva | Kredi | Enerji kapasitesi | Döngü gideri | Açılış/rol |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| Solar Array / `solar_panel` | 1 | 1 | 150 | +3 | Yok | Başlangıç, özel arazi istemez. |
| Wind Turbine / `wind_turbine` | 1 | 1 | 200 | +4 | Yok | Wind Power; görünen rüzgârlı alan üzerinde. |
| Tidal Generator / `tidal_generator` | 2 | 2 | 600 | +12 | 0,33 G | Tidal Power; deniz kıyısı üzerinde. |
| Geothermal Plant / `geothermal_plant` | 2 | 2 | 750 | +15 | 0,33 G | Geothermal; volkan/jeotermal yarık. |
| Solar Matrix / `solar_matrix` | 2 | 2 | 450 | +9 | 0,33 G | Solar Matrix; genel yoğun enerji. |
| Fusion Reactor / `fusion_reactor` | 3 | 2 | 1.350 | +27 | 0,67 F | Fusion; iç hesap 2/3 Fuel. Moonstone istemez. |
| Yeni Sığ Jeotermal Kuyu | 1 | 1 | 250 | +5 | Yok | Sığ Isı; sıcak saha, küçük ilk yatırım. |
| Yeni Sırt Türbini | 2 | 2 | 900 | +18 | 0,33 G | Sırt Rüzgârları; görünen sırt + rüzgâr. |

Fusion gideri V2'deki 1 Fuel/dk'dan bu taslakta **2 Fuel/dk** oldu. Solar Matrix Goods alış gideri 24,2/9 = 2,69 kredi/enerji-dk; Fusion Fuel alış gideri 74,8/27 = 2,77. Yoğunluk artışı ucuz bakım üstünlüğüyle birleşmesin diye aynı mertebede tutuldu.

### Production: çıkarım ve işleme

| Model / eski kimlik | Tier | Yuva | Kredi | Döngüde girdi -> çıktı | Enerji | Ayrı rol |
| --- | ---: | ---: | ---: | --- | ---: | --- |
| Mine / `mine` | 1 | 1 | 200 | Yok -> 10 ham | -1 | Genel çıkarım. |
| Gelişmiş Ekskavatör / `rich_vein_excavator` | 2 | 2 | 800 | Yok -> 40 ham | -3 | Yatak şartı kaldırıldı; güçlü, pahalı yoğunluk. |
| Deep Drill / `deep_drill` | 2 | 2 | 600 | Yok -> 30 ham | -3 | Daha ucuz yoğun çıkarım. |
| Mantle Cracker / `mantle_cracker` | 3 | 2 | 1.800 | 0,33 F -> 90 ham | -9 | İleri çıkarım; Moonstone istemez. |
| Goods Factory / `refinery` | 1 | 1 | 300 | 4 ham -> 2 G | -2 | Başlangıç işlemesi. |
| Fuel Refinery / `plasma_smelter` | 2 | 2 | 1.350 | 24 ham + 0,33 G -> 6 F | -6 | Büyük Fuel; küçük modelin ×3 tarifi. |
| Rare Element Forge / `molecular_forge` | 1 | 1 | 600 | 12 ham -> 1 R | -3 | Erken Rare araştırmasıyla açılır. |
| Yeni Yüzey Ocağı | Küçük 1 | 1 | 100 | Yok -> 5 ham | -0,5 | 125 çalışan, yarı yuva verimi. |
| Yeni Cevher Ayıklama Atölyesi | 2 | 2 | 900 | 12 ham + 0,33 G -> 6 G | -6 | Yoğun Goods. |
| Yeni Kompakt Yakıt Atölyesi | 1 | 1 | 450 | 8 ham -> 2 F | -2 | İlk Fuel'a küçük yatırım. |
| Regolit Goods planı | 2 | 2 | 900 | 12 Moonstone + 0,33 G -> 6 taban G | -6 | Moonstone ile 10,5 brüt G; Ay Malzemeleri alternatif açılışı. |

Regolit, Cevher Atölyesi'nin Ay görünümü/yerel planı olarak aynı model ve tekrar sayacını paylaşır. İki ayrı ekonomik kopya üretme. Ay planıyla kuruluş: **100 Moonstone + 20 Goods + 900 kredi**. Ay dışı planın genel T2 tarifi farklı açılış yoludur; malzemeler iki kez alınmaz.

Kendi Goods giderini isteyen büyük fabrikanın ilk küçük stoku temel fabrikadan veya trade'den gelebilir. Temel bakımsız model kapatılmaz. Sıfır girdide büyük fabrika, gelecekte üreteceği Goods'u şimdiden harcamış sayılmaz.

### Depo

| Model | Yuva | Kredi | Kapasite | Enerji / çalışan |
| --- | ---: | ---: | --- | --- |
| Warehouse / `warehouse` | 1 | 300 | Açılmış ham türü başına +1.000, G +150, F +150, R +75 | -1 / 250 |
| Yeni Yakıt Deposu | 1 | 150 | F +300 | -0,5 / 125 |
| Yeni Yörünge Yakıt Tankı | 2 | 600 | F +1.200; yörünge planında | -2 / 750 |

Taban depo: ham türü başına 500, G 200, F 200, R 100. Depo katkısı kendiliğinden mineral keşfetmez. Kredi/Science'ın normal cüzdan tavanı yoktur.

### Science

| Model / eski kimlik | Tier | Yuva | Kredi | Science / 20 sn | Gider | Enerji |
| --- | ---: | ---: | ---: | ---: | --- | ---: |
| Research Lab / `lab` | 1 | 1 | 150 | 4 | Yok | -1 |
| Mountain Observatory / `mountain_observatory` | 2 | 2 | 600 | 16 | 0,33 G | -3 |
| Research Institute / `advanced_lab` | 2 | 2 | 450 | 12 | 0,33 G | -3 |
| Particle Accelerator / `particle_accelerator` | 3 | 2 | 1.350 | 36 | 0,33 R | -9 |
| Yeni Saha Gözlem Evi | Küçük 1 | 1 | 75 | 2 | Yok | -0,5 |
| Yeni Ay Numune Laboratuvarı | 2 özel | 2 | 750 | 20 | 0,33 R | -4 |

Observatory dağ, Saha Gözlem dağ/plato, Ay Numune yalnız Ay ister. Ay Numune kuruluşu: **75 Moonstone + 10 Goods + 5 Rare + 750 kredi**. Particle'ın genel T3 tarifine 60 Moonstone eklendi.

### Residential

| Model / eski kimlik | Tier | Yuva | Kredi | Nüfus kapasitesi | Döngü gideri | Enerji |
| --- | ---: | ---: | ---: | ---: | --- | ---: |
| Habitat Block / `residential` | 1 | 1 | 120 | +2.500 | Yok | -1 |
| Seaside Villas / `seaside_villas` | 2 | 2 | 360 | +6.000 | 0,33 G | -1 |
| Apartment Towers / `apartments` | 2 | 2 | 360 | +7.500 | 0,33 G | -2 |
| Luxury Spires / `luxury_complex` | 3 | 2 | 1.080 | +22.500 | 0,67 G + 0,33 F | -6 |
| Yeni Düşük Katlı Konut | Küçük 1 | 1 | 60 | +1.250 | Yok | -0,5 |
| Yeni Kıyı Apartmanları | 2 özel | 2 | 432 | +9.000 | 0,33 G | -3 |
| Yeni Modüler Ay Habitatı | 2 özel | 2 | 480 | +10.000 | 0,67 G | -3 |

Villas ve Kıyı Apartmanı kıyı ister; biri enerji tasarrufu, diğeri yoğunluk tercihidir. Ay Habitatı kuruluşu: **50 Moonstone + 10 Goods + 480 kredi**. Luxury genel T3 +60 Moonstone ister. Bütün konut çalışanları 0.

### Commercial

| Model / eski kimlik | Profil | Yuva | Kredi | Çıktı / 20 sn | Gider | Enerji / çalışan |
| --- | --- | ---: | ---: | ---: | --- | --- |
| Market / `commercial` | T1 | 1 | 150 | 20 kredi | Yok | -1 / 250 |
| Bazaar / `bazaar` | Büyük T1 | 2 | 450 | 80 kredi | 1 G | -3 / 625 |
| Harbor Market / `harbor_market` | T2 | 2 | 600 | 80 kredi | 0,33 G | -3 / 750 |
| Trade Hub / `trading_post` | T2 | 2 | 450 | 60 kredi | 0,33 G | -3 / 750 |
| Commodity Exchange / `commodities_exchange` | T3 | 2 | 1.800 | 270 kredi | 3 G + 0,33 F | -9 / 2.250 |
| Yeni Yerel Ticaret Merkezi | Büyük T1 | 2 | 375 | 50 kredi | Yok | -3 / 625 |
| Yeni Ay İkmal Pazarı | T2 özel | 2 | 900 | 120 kredi | 1 G + 0,33 F | -4 / 750 |

Büyük T1'ler V2'den yeniden hesaplandı; yalnız yuvaları ikiye çıkarılıp eski zayıf çıktıları korunmadı. İki Market 40 kredi/20 sn, 500 çalışan ve 2 enerji ister. Yerel Merkez 50, 625 ve 3 ister; yoğunluk için ek bedel vardır.

Bazaar 250 Science Consumer Goods açılışı ister. Harbor kıyı şartıyla güçlüdür. Ay Pazarı kuruluşu **75 Moonstone + 20 Goods + 10 Fuel + 900 kredi**. Commodity genel T3 +90 Moonstone ister.

### Capital destekleri ve Spaceport

Destekler merkezden aynı mesafe profiliyle ulaşılabilen ilgili hedeflere etki eder; yol istemez. Her destekten merkez başına bir adet. Üretim yüzdeleri ilgili araştırma/destek grubuna eklenir, yeni gizli çarpım katmanı açmaz.

| Model / eski kimlik | Tier | Yuva | Kredi | Etki | Enerji / çalışan |
| --- | ---: | ---: | ---: | --- | --- |
| Financial District / `financial_district` | 2 | 2 | 600 | Uygun Commercial kredi +%10 | -2 / 750 |
| Research Directorate / `research_academy` | 2 | 2 | 600 | Uygun Science +%10 | -2 / 750 |
| Housing Authority / `cryo_vault` | 2 | 2 | 600 | Uygun Residential konut +%10 | -2 / 750 |
| Logistics Center / `logistics_center` | 2 | 2 | 1.200 | Uygun Production +%10; Warehouse kadar depo | -2 / 750 |
| Planetary Command / `command_center` | 3 | 2 | 1.800 | Uygun Energy +%10 | -3 / 2.250 |
| Spaceport / `spaceport` | Özel | 2 | 500 | Dünya-Ay seferi | 0 / 250 |
| Yeni İnşaat Dairesi | 2 | 2 | 600 | Uygun districtlerde bina inşaatı -%10 | -1 / 750 |
| Yeni Lunar Spaceport | Özel | 2 | 8.000 | Ay-gezegen özel roketi; tarif Bölüm 19 | -2 / 750 |

Destek mesafe payı çok yakında tam, yakında yarım; daha uzakta 0. Örneğin Financial'ın +%10'u yakında +%5 olur. Capital kendi temel merkez katkısına ek olarak bu seçilmiş desteği verir. Capital olmayan City ikinci merkez katkısı üretmez; City konumunun coğrafyası kendi alt üretimlerine aktarılır.

### Eski ileri/orbital tanımların kaybolmayan eşlemesi

| Eski kimlik | V3 hedefi |
| --- | --- |
| `antimatter_chamber` | Tip 1+ enerji kuruluş planı teması; Tip 0 bina kataloğunda açık değil. |
| `quantum_computer` | Tip 1+ bilim kuruluş planı teması; gezegen Lv4 katalog hatası kapatılır. |
| `arcology` | Tip 1+ konut kuruluş planı teması; başlangıç açık işareti kaldırılır. |
| `central_bank` | Tip 1+ ticaret planı; Tip 0'da yok. |
| `zero_g_nexus` | Orbital Science District planı. |
| `orbital_mirrors` | Orbital Energy destek planı. |
| `orbital_offworld_market` | Orbital Commercial planı. |
| `orbital_shipyard` | Orbital sefer hazırlık districti; Lunar Program'ın zorunlu kapısı kaldırılır. |
| `orbital_logistics` | Orbital Logistics District; kapasite ve destek rolü. |

Yörünge City gibi örgütlenecek, içinde district seviyesinde yapı olacak. Bütün orbital oynanış alt tasarımı demo ana yolunun şartı yapılmaz. Yalnız var olan 5 modülü eski bina yuvalarına aynen doldurmak yeni ölçek tasarımı sayılmaz.

### Büyük bina arayüzü

İki yuvalı bina iki normal hücre genişliğinde tek kart olsun. Tek bina kimliği, tek adet ve tek ödeme kaydı taşır; yan yana iki ayrı kopya değildir. Dar ekranda büyük kart iki standart satır yüksekliğine geçebilir.

Toplam iki boş yuva varken yalnız kartların görsel sırası yüzünden “yan yana boşluk yok” kilidi koyma. Panel otomatik paketlenebilir. Bina listesi konumsuzdur; bu görsel düzen coğrafi yerleşim değildir.

Institute artık **iki yuvada** 12 Science/20 sn verir. İki Lab aynı iki yuvada 8 verir. Yoğunluk avantajı %50; çalışan 750 yerine 500 ve gider farkı karşılığında gelir. V2'nin “üç Lab tek yuvada” cümlesi kaldırılmıştır.

## 13. Skill ağacı: strateji, erken ürünler ve eski kimlikler

### Ortak kurallar

- Seçim/adet sınırı yok. Satın alınmış etkiler geçişte silinmez.
- Birleşen grafik yollarında ebeveynlerden herhangi biri yeterli: `ANY`. Ürün erişimi, yerel çıkarım, özel yapı gibi ayrı fiziksel koşullar birlikte zorunlu olabilir.
- Fuel/Rare açılışı Science ile; gezegen Lv kapısı yok.
- Yakın/uzak/coğrafya temel bonusları başlangıçtan çalışır. Skill bunları güçlendirir veya çapraz aile ilişkisi açar.
- Gelecek medeniyet silueti görülebilir; kaynak adları veya satın alma erişimi açılmaz.

```text
Strateji skill bedeli = taban × (1 + 0,02 × diğer dallarda alınmış farklı düğüm sayısı)
Tekrarlı bonus seviye bedelleri = taban × 1 / 2 / 3
```

Aynı düğümün ek seviyesi yeni farklı düğüm sayılmaz. Her düğümün tek ana dalı var; çok yoldan erişim ana dalını çoğaltmaz. Ortak ilerleme ve miras düğümü bu çapraz dal zammının dışındadır. Mirasın verdiği eski haklar, yeni medeniyetin dal sayacını yüzlerce artırmaz.

Dal fiyat sayacı **yalnız aynı medeniyette bireysel satın alınmış farklı strateji düğümlerini** sayar. Tip 0'da bireysel alınmış eski düğümler de Tip 1 fiyatını artırmaz. Sayaç anahtarı medeniyet + canonical düğümdür; mirasın grant'leri bireysel satın alma sayılmaz.

### Ortak Tip 0 araştırma yolu

| Düğüm | Science | Koşul | Hak |
| --- | ---: | --- | --- |
| Temel İşleme | 0 | Başlangıç | Goods Factory ve girdi seçimi. |
| Ticaret Erişimi | 150 | Başlangıç | Manuel al/sat; taşanı satışa çevir. |
| Fuel İşleme | 450 | Temel İşleme | Kompakt Fuel. |
| Rare İşleme | 900 | Fuel İşleme | Rare Forge. |
| Rocketry | 600 | Fuel İşleme | Dünya Spaceport. |
| Lunar Program | 1.200 | Rocketry | Ay lander. |
| Ay Malzemeleri | 1.200 | Ay'da çıkarım yapabilen Production tamamlanmış | Yerel Goods planı, Habitat, Lunar Spaceport. |
| Gelişmiş Gezegen Roketi | 2.000 | Ay Malzemeleri + Rare İşleme + yerel 100 Moonstone görevi | Son roket. |

Nominal toplam **6.500 Science**, trade seçilmezse 6.350. Başlangıç 450 bu toplamın bir kısmını ödeyebilir. Strateji, bonus ve otomasyon alımları dahil değil. Orbital Assembly/Shipyard ve gezegen Lv şartı bu yola geri eklenmez.

### Strateji düğümleri

| Ana dal | Düğüm ve taban Science | Etki / yol |
| --- | --- | --- |
| Production | Yüzey Kazı 75; Gelişmiş Ekskavatör 450; Deep Drilling 350; Mantle 900 | Küçük / yoğun / ağır çıkarım. Eski Vein adı yatak şartı yaratmaz. |
| İşleme | Cevher Ayıklama 450; Yoğun Fuel 350; Yakıt Süreçleri 150/300/450 | Büyük Goods, büyük Fuel, Fuel +%10/seviye. |
| Enerji | Wind 150; Tidal 350; Geothermal 450; Solar Matrix 350; Fusion 900 | Coğrafi veya genel yoğun enerji. Fusion için Fuel erişimi de gerekli. |
| Coğrafya | Sığ Isı 250; Sırt Rüzgârları 450 | Küçük sıcak saha / yoğun sırt enerjisi. |
| Bilim | Saha Araştırma 100; Mountain Optics 450; Advanced Research 350; Particle Physics 900 | Küçük/dağ/genel/ileri bilim. Particle için Rare ve Moonstone erişimi. |
| Nüfus | Mahalle İnşası 75; Coastal Living 250; Kıyı Yoğunlaşması 350; High-Rise 350; Luxury 900 | Küçük/enerji tasarrufu/yoğun konut. Luxury Moonstone erişimi. |
| Nüfus | Sivil Girişimler 150; Serbest Araştırma 150; Üretim Rezervi 300 | Boş kapasite kredi/Science/üretim. Serbest Araştırma Bilim yolundan da erişilebilir, ana dalı Nüfus. |
| Ticaret | Consumer Goods 250; Yerel İşletmeler 150; Trade Networks 350; Harbor Trade 450; Commodity 900 | Büyük T1/genel/kıyı/ileri kredi. Commodity Moonstone ister. |
| Ticaret | Ticaret Otomasyonu 300 | Rezerv/hedef stok ve otomatik Science al/sat. |
| Kamu | Kamu Yönetimi 350; Lojistik 450; İleri Koordinasyon 900; İnşaat Organizasyonu 350 | Capital destekleri; ilgili aile yolu ayrıca açılmış olmalı. |
| Kamu | Yakıt Depolama 200; Orbital Depolama 600 | Normal yakıt deposu / yörünge tankı. |
| Kamu | Geri Kazanım I 250; II 500 | Kredi iadesi %50 -> %65 -> %75. |
| Ay/Bilim | Ay Araştırmaları 600 | Ay Numune Lab; Ay City'si ve Rare erişimi. |
| Ay/Ticaret | Ay İkmal Ağı 600 | Ay Pazarı; Ay City'si ve Ticaret Erişimi. |
| Yakınlık | Küme Planlama 200/400/600 | Kaynak başına yakınlık katkısını seviye başına %10 artırır: %10 -> %11 -> %12 -> %13. Kaynak sırası indirimi yok. |
| Uzaklık | Bağımsız Merkezler 200/400/600 | Uzak/çok uzak bonusuna seviye başına +10 yüzde puanı. |
| Yakınlık | Karma Ağlar 450 | Başka uygun ailelerden kaynak başına %5 çok yakın / %2,5 yakın katkı; sınırsız bütün kaynaklar tam sayılır. Adı Karma olabilir, ekonomik yerleşim türü yine Genel. |
| Coğrafya | Yerel Coğrafya Uzmanlığı 200/400/600 | Seçilen görünür arazi ailesinin mevcut bonusunu +%10/seviye büyütür; olmayan araziyi yaratmaz. |
| Kamu | Yerleşim Düzenleme 250 | Tip 0/1 district konumlandırma ve aynı ailede bina aktarma; Bölüm 16. |

Ön koşullar aşağıdaki açık grafiktir. Temel aile düğümleri ücretsiz köktür. Bunlara ek rastgele Lv/City sayısı kapısı uydurulmaz.

### Canonical düğümler ve kesin grafik bağlantıları

Bu kimlikler yeni verinin hedef sözleşmesidir. Eski kimlikler sonraki eşleme tablosundaki adlarına göre bunlara bağlanır. Maliyet ve ana dal üst tablolardadır; aşağıdaki tablo grafiği ve ek koşulu kesinleştirir. `ANY` sütunundaki **bir** ebeveyn yeterli; son sütundaki şartların **hepsi** gerekir. Belirtilmeyen azami seviye1; tekrarlı bonuslar3.

| Düğüm / canonical kimlik | ANY ebeveyn kimlikleri | Birlikte gereken ek erişim/olay |
| --- | --- | --- |
| Başlangıç `root` | Yok | Ücretsiz. |
| Energy `start_energy`; Production `start_production`; Science `start_science`; Residential `start_residential`; Commercial `start_commercial` | `root` | Ücretsiz başlangıç ailesi. |
| Temel İşleme `processing_basics` | `start_production` | Ücretsiz başlangıç hakkı. |
| Ticaret Erişimi `trade_access` | `root` | Yok. |
| Fuel İşleme `fuel_processing` | `processing_basics` | Yok. |
| Rare İşleme `rare_processing` | `fuel_processing` | Yok. |
| Rocketry `rocketry` | `fuel_processing` | Yok. |
| Lunar Program `lunar_program` | `rocketry` | Yok; Spaceport sefer başlatırken fiziksel şarttır. |
| Ay Malzemeleri `lunar_materials` | `lunar_program` | Ay'da tamamlanmış çıkarabilen Production. |
| Gelişmiş Roket `advanced_planet_rocket` | `lunar_materials` | `rare_processing`, gerçek yerel 100 Moonstone olayı. |
| Yüzey Kazı `surface_excavation`; Gelişmiş Ekskavatör `advanced_excavation`; Deep Drill `deep_drilling` | `start_production` | Yatak şartı yok. |
| Mantle `mantle_cracking` | `advanced_excavation`, `deep_drilling` | Fuel ve Rare erişimi. |
| Cevher Ayıklama `ore_sorting` | `processing_basics` | Yok. |
| Yoğun Fuel `dense_fuel`; Yakıt Süreçleri `fuel_process_efficiency` | `fuel_processing` | İkinci düğüm3 seviye. |
| Wind `wind_power`; Solar Matrix `solar_matrix` | `start_energy` | Araştırma için yer şartı yok; bina konumu ayrıca denetlenir. |
| Tidal `tidal_power` | `wind_power`, `start_commercial` | Yok. |
| Sığ Isı `shallow_heat` | `start_energy` | Yok. |
| Geothermal `geothermal_power` | `shallow_heat`, `tidal_power` | Yok. |
| Sırt Rüzgârları `ridge_wind` | `wind_power` | Yok. |
| Fusion `fusion_power` | `solar_matrix`, `geothermal_power` | Fuel ve Rare erişimi; kuruluş genel T3 malzemelerini ister. |
| Saha Araştırma `field_research`; Mountain Optics `mountain_optics`; Advanced Research `advanced_research` | `start_science` | Yok. |
| Particle `particle_physics` | `advanced_research`, `rare_processing` | Rare ve Moonstone erişimi. |
| Mahalle İnşası `neighborhood_building`; Coastal Living `coastal_living` | `start_residential` | Yok. |
| Kıyı Yoğunlaşması `coastal_density` | `coastal_living` | Yok. |
| Sivil Girişimler `civic_enterprise` | `start_residential` | Yok. |
| Serbest Araştırma `free_research` | `start_residential`, `start_science` | Ana dalı Nüfus. |
| Üretim Rezervi `population_reserve` | `civic_enterprise`, `free_research` | Yok. |
| High-Rise `high_rise` | `coastal_living`, `civic_enterprise` | Yok. |
| Luxury `luxury_living` | `high_rise` | Fuel, Rare ve Moonstone erişimi. |
| Consumer Goods `consumer_goods` | `start_commercial` | Goods erişimi başlangıçtan vardır. |
| Yerel İşletmeler `local_business` | `trade_access` | Yok. |
| Trade Networks `trade_networks` | `consumer_goods`, `local_business` | Yok. |
| Harbor `harbor_trade` | `coastal_living`, `trade_networks` | Yok. |
| Commodity `commodity_markets` | `trade_networks` | Fuel, Rare ve Moonstone erişimi. |
| Ticaret Otomasyonu `trade_automation` | `trade_access` | Yok. |
| Kamu Yönetimi `public_administration` | `root` | Yok. |
| Lojistik `logistics` | `ore_sorting`, `trade_networks` | `public_administration`. |
| İleri Koordinasyon `advanced_coordination` | `fusion_power`, `advanced_research` | `public_administration`, Fuel/Rare/Moonstone erişimi. |
| İnşaat Organizasyonu `construction_management` | `public_administration` | Yok. |
| Yakıt Depolama `fuel_storage` | `fuel_processing` | Yok. |
| Orbital Depolama `orbital_storage` | Gelecek `orbital_assembly` | Yörünge planı oynanabilir açılmış olmalı; demo ana yoluna şart değil. |
| Geri Kazanım I `recycling_1`; Yerleşim Düzenleme `settlement_layout` | `root` | Yok. |
| Geri Kazanım II `recycling_2` | `recycling_1` | Yok. |
| Ay Araştırmaları `lunar_research` | `lunar_materials` | Ay City'si, Rare erişimi. |
| Ay İkmal Ağı `lunar_supply` | `lunar_materials`, `trade_networks` | Ay City'si, `trade_access`, Fuel erişimi. |
| Küme Planlama `cluster_planning`; Bağımsız Merkezler `independent_centers` | `root` | Her biri3 seviye. |
| Karma Ağlar `cross_networks` | `cluster_planning`, `science_efficiency`, `trade_efficiency` | Yok. |
| Coğrafya Uzmanlığı `geography_specialization:<terrain_id>` | `root` | Her tanımlı görünen Tip 0 arazi türü için ayrı 3 seviye. Tür seçimi sonradan ücretsiz değiştirilemez; seçim sınırı yok. |
| Photovoltaics `solar_efficiency`; Grid `grid_efficiency` | `start_energy` | Her biri3 seviye. |
| Çıkarım Verimi `extraction_efficiency` | `start_production` | 3 seviye. |
| Bilim Verimi `science_efficiency` | `start_science` | 3 seviye. |
| Konut Verimi `housing_efficiency` | `start_residential` | 3 seviye. |
| Ticaret Verimi `trade_efficiency` | `start_commercial` | 3 seviye. |
| Tip 0 Mirası `legacy_civ_0` | `civilization_root_1` | Medeniyet1; oynanabilirlik/R01 demo koşulu. |

Capital bina hakları da belirlidir: Financial = Kamu Yönetimi +Trade Networks; Research Directorate = Kamu Yönetimi +Advanced Research; Housing Authority = Kamu Yönetimi +High-Rise. Logistics/Command/İnşaat kendi düğümleriyle açılır. Başlangıç `unlocked` değeri bu kapıları aşamaz.

Miras düğümünün kapsadığı Tip 0 hak kümesi bu gerçek canonical kimliklerdir; gelecek orbital/gelecek içerik kimlikleri değildir. Üst düzenleme skill'leri ilgili medeniyet köküne bağlanır, aynı zamanda oynanabilir tip ve Bölüm 16 yetkisini ister. Demo önizleme kökü satın alma izni değildir.

### Tekrarlı eski bonusların sade yeni karşılıkları

| Yeni bonus | Science | Etki |
| --- | --- | --- |
| Photovoltaics | 150/300/450 | Solar +%10/seviye. |
| Superconducting Grid | 300/600/900 | Enerji ihtiyacı -%5/seviye, toplam -%15. |
| Çıkarım Verimi | 150/300/450 | Ham miktarı +%10/seviye. Eski hız ve miktar düğümleri tekleşir. |
| Bilim Verimi | 150/300/450 | Science +%10/seviye. |
| Konut Verimi | 150/300/450 | Konut kapasitesi +%10/seviye. |
| Ticaret Verimi | 150/300/450 | Üretilen kredi +%10/seviye. Trade fiyatını değiştirmez. |

### Eski 54 skill kimliğinin dönüşümü

Gruplanmış satırdaki her kimlik aynı yeni hakkı gösterir; iki kimlik için aynı bonus iki kez açılmaz. Yeni koda geçerken grant ve bina bağları birlikte değiştirilir.

| Eski kimlikler | Yeni hedef |
| --- | --- |
| `root` | Ücretsiz kök. |
| `unlock_solar_panel`, `unlock_residential`, `unlock_lab`, `unlock_commercial` | Ücretsiz ilgili aile başlangıçları. |
| `unlock_mining` | Ücretsiz Production/Mine/Warehouse/Temel İşleme. |
| `unlock_spaceport`, `unlock_moon` | Rocketry, Lunar Program. |
| `unlock_space_station` | Orbital City kuruluşu, ayrı yörünge planı. |
| `unlock_zero_g_nexus`, `unlock_orbital_mirrors` | Orbital Science/Energy destek planları. |
| `unlock_orbital_shipyard`, `unlock_orbital_offworld_market` | Orbital sefer hazırlığı/Commercial. Ay zorunlu yolu değil. |
| `unlock_asteroids`, `unlock_planetary_colonization`, `unlock_interstellar`, `unlock_orbital_logistics` | Gelecek oynanabilir keşif/yerleşim/yörünge. Tip 0 mirası bunları vermez. |
| `unlock_wind_turbine`, `unlock_tidal_generator`, `unlock_geothermal_plant`, `unlock_solar_matrix`, `unlock_fusion_reactor` | Aynı adlı yeni enerji açılışları. |
| `solar_efficiency`, `power_transmission` | Photovoltaics, Grid. |
| `unlock_antimatter_chamber` | Üst ölçek enerji planı; Tip 0'dan kapalı. |
| `unlock_rich_vein_excavator`, `unlock_deep_drill`, `unlock_mantle_cracker` | Gelişmiş Ekskavatör, Deep Drill, Mantle. |
| `mine_speed`, `deep_mining` | Tek Çıkarım Verimi. |
| `unlock_plasma_smelter`, `unlock_molecular_forge` | Fuel İşleme/Yoğun Fuel ve Rare İşleme. |
| `unlock_quantum_harvester` | Gelecek Production önizlemesi; olmayan bina açılmaz. |
| `unlock_mountain_observatory`, `unlock_advanced_lab`, `unlock_particle_accelerator` | Mountain, Advanced Research, Particle. |
| `science_income_1`, `science_income_2` | Tek Bilim Verimi. |
| `unlock_quantum_computer` | Üst ölçek bilim planı; Tip 0 kapalı. |
| `unlock_seaside_villas`, `unlock_apartments`, `unlock_luxury_complex` | Coastal, High-Rise, Luxury. |
| `housing_income_1`, `housing_income_2` | Tek Konut Verimi. |
| `unlock_arcology` | Üst ölçek konut planı; Tip 0 kapalı. |
| `unlock_harbor_market`, `unlock_bazaar`, `unlock_trading_post`, `unlock_commodities_exchange` | Harbor, Consumer Goods, Trade Networks, Commodity. |
| `trade_income_1`, `trade_income_2` | Tek Ticaret Verimi. |
| `unlock_logistics_center`, `unlock_command_center` | Lojistik, İleri Koordinasyon. |
| `unlock_central_bank` | Üst ölçek ticaret planı; Tip 0 kapalı. |

Yeni 16 bina/skill adayları Bölüm 12 ve bu tablolara dahil; küçük Fuel ve Ay Malzemeleri aynı ortak açılışa ikinci kez ücret olarak eklenmez. Orbital dalların bedel ve harita ayrıntıları ayrı kapsamdır; demo yolunu bekletmez.

## 14. Fraktal skill ağacı ve demodaki gösterimi

**Kesin karar:** Tip 1'de bütün gerçek Tip 0 ağacı tek ücretli **Tip 0 Mirası** düğümüne dönüşür. Satın alınca önceki ağacın eksik hakları da tamamlanır. Sonraki geçişler aynı özyinelemeli modeli destekler.

### Haklar nasıl tamamlanır?

```text
Etkin skill seviyesi = bireysel satın alınan seviye ile mirasın verdiği seviyenin büyüğü
```

Miras bütün gerçek alt düğümler için azami seviyeyi verir. Örnek: Photovoltaics bireysel Lv2 + miras Lv3 -> etkin Lv3, +%30. Lv5 veya +%50 olmaz. Aynı canonical kimlik üzerinde birleşir; ikinci bir miras çarpanı açılmaz.

- Eski alınmış haklar satın alma öncesinde de çalışır; geçişte kapatılmaz.
- Miras satın almak bina modellerini açar, yeni bina adetleri oluşturmaz.
- Fiziksel Ay çıkarımı/Spaceport/uçuş görevini tamamlanmış saymaz.
- Mirasın içeriği yalnız gerçek Tip 0 düğümleridir. Gelecek 9 önizleme düğümü dahil değildir.
- Önceki yatırımlar için otomatik iade verilmez; daha önce yararlanılmış ilerleme silinmez.
- Alttaki ağaç ayrıntıya açılabilir. Üstteki tek düğüm eski düğümlere verilen hakların özetidir.
- Tip 2'de Tip 1 mirası önceki miras hakkını da içerir; aynı alt hak yine `max` ile birleşir.

**Sayısal taslak:** Tip 1'de Tip 0 Mirası 4.000 Science. Sonraki miras tabanı öncekinin ×10'u: `4.000 × 10^(yeni tip - 1)`. Çapraz dal fiyat zammı uygulanmaz. İleri ekonomiler oynanabilir yapılırken bu tek ortak katsayı yeniden dengelenebilir.

### Demo

Varışta Tip 0 ağacının tek düğüme görsel olarak toplanması ve kalan üst ağın açılması gösterilir. Oyuncu düğüme basıp eksik haklar/etkiler ve mevcut yerleşimlerde oluşacak **Güncelle** önerisini görebilir.

**R01 açık kapsam kararı:** Bu miras düğümü demoda gerçekten satın alınabilir mi? Bu rehberin önerisi, hedefte Tip 1 ekonomisi kapalıyken **kilitli etkileşimli önizleme** göstermektir. Önizleme gerçek Science harcamaz, grant vermez ve eski Dünya ekonomisini değiştirmez. Gerçek satın alma istenirse bunun bir demo istisnası olduğu açıkça kararlaştırılmalı. Diğer fraktal kurallar kesinleşmiştir; bu soru onları yeniden askıya almaz.

## 15. Yıkma, içeriği temizleme ve sıfırlama

**Kesin istek:** Bina, district, City, gezegen yerleşimi ve üst eşlenikleri kaldırılabilir veya sıfırlanabilir. Otomatik plan oyuncunun değiştirilemez son kararı değildir.

### Birbirinden farklı işlemler

| İşlem | Kalan | Kaldırılan |
| --- | --- | --- |
| Binadan adet kaldır | Diğer adetler ve district | Seçilmiş gerçek adetler. |
| İçeriği temizle | Seçilmiş yerleşimin kabuğu, adı, yeri ve seviyesi | Oyuncunun seçtiği alt içerik kapsamı. |
| Yerleşimi sıfırla | Aynı kabuk/kimlik/konum; seviye 1 | Alt ağaç ve üst seviyelere yapılmış geliştirmeler. |
| Yerleşimi yık | Üst ebeveyn ve doğal harita | Seçilen oyuncu yerleşimi ve bütün alt ağacı. |
| Yeni oyun | Ayrı mevcut menü işlemi | Bütün oyun ilerlemesi; ekonomik yıkım düğmesi değildir. |

“Gezegeni yık” burada **oyuncunun gezegen üzerindeki ekonomik yerleşimini kaldırmak** demektir. Doğal gövdeyi, seed'i veya evren kataloğunu patlatıp silmek için ayrı afet/silah sistemi eklenmez. Aynı ayrım güneş sistemi/Gökada vb. için geçerli.

Merkez de sıfırlanabilir veya yıkılabilir. Yıkılmış merkez ekran açılınca bedava yüksek seviyesiyle geri doğmaz. İlk kuruluş otomatiği yalnız ilk yerleşim işleminde çalışır. Merkez eksikse Güncelle teklifinde yeniden kurulabilir; aynı ebeveynin merkez rolünde en fazla bir gerçek nesne bulunur. Sıfırlama seçilirse merkez iskeleti Lv1 olarak korunur; yüksek seviye ve binalar ayrı birer kez tasfiye edilir.

### İade hesabı

Temel kredi iadesi %50, Geri Kazanım I ile %65, II ile %75. Malzeme iadesi yok. Esas güncel katalog değil gerçek ödenmiş kredi.

```text
N = eşdeğer adet sayısı
C = bu adetlerin kalan toplam gerçek edinim kredisi
k adet kaldırmanın maliyet payı = C × k / N
İade = bu pay × iade oranı
Kalan C = eski C - maliyet payı
Kalan N = eski N - k
```

Örnek: 150/180/216 ödenmiş 3 Lab, toplam C=546. Bir adedin payı 182. %50 iade 91, %75 iade 136,50. Kalan C=364, N=2. **C'den iade tutarı değil maliyet payı düşülür.**

Birleştirme N/C toplamlarını toplar; bölme C'yi adet oranında ayırır. Son adet kalan küçük para farkını alır. Her adedin bütün satın alma tarihini tutmak gerekmez.

### Alt ağaçta çift iade olmasın

- Ebeveynin kendi kabuk/kuruluş kredisi ve seviye yatırımları ayrı maliyetlerdir.
- Çocukların bedelleri çocuk maliyet kayıtlarına aittir.
- Hazır plan toplamı hem ebeveyne hem çocuklara yazılmaz.
- Otomatik ücretsiz merkez ve ücretsiz ilk kabuk için gerçek ödeme 0'dır.
- Tekrarlı açılış/kuruluş/keşif görevleri sıfırlamayla yeniden ödül vermez.

Yıkım önizlemesi kaldırılacak nesne/adetleri, iade toplamını, kaybolacak kapasiteyi, üretimi ve kuyrukları gösterir. Ardından tek işlemle üretim/inşaat rezervlerini kapat, nesneleri kaldır, bir kez iade et ve eski/yeni sayımları yeniden hesapla.

Önceden tüketilmiş döngü malzemesi geri verilmez. Henüz harcanmamış ayrılmış stok serbest bırakılır. İnşaat iptalinde aynı kredi iade oranı geçerlidir. Devam eden işin durumu ve kaybı önizlemede görünür; sessizce başka yerde devam etmez.

### Depo yıkılınca

Önceden sahip olunan stok silinmez. Yeni kapasitenin üzerinde kalırsa `kapasite aşıldı` gösterilir. Yeni malzeme kabulü için alan açılır; trade açıkken yeni taşma satılır, trade kapalıyken yeni taşma kaybolur. Eski stok kendiliğinden yeniden üretilmiş/satılmış sayılmaz. Yeniden kurulan depo eski stoku ikinci kez vermez.

Sıfırlama medeniyet, araştırma, keşif, isimli görev geçmişi ve global cüzdanı silmez. Son yerleşim yıkılırsa eski başlangıç 3.000/450 bütçesi yeniden dağıtılmaz. Oyuncu haritada tekrar yerleşebilir; ilk ücretsiz City kuralı “yeni oyun ödülünü tekrar ver” anlamına gelmez.

## 16. Her ölçekte yeniden konumlandırma ve taşıma skill'i

Kullanıcının son açıklaması bu bölümün kapsamıdır: **Otomatik planla yerleşmiş en alt nesne beğenilmezse ayrıntıya girip başka konuma alınabilmeli.** Bu yalnız district için değildir.

### Ölçek tablosu

| Aktif tip | Paneldeki en alt nesne | Ayrıntıda düzenlenen yer | Taşınırken korunacak alt içerik |
| --- | --- | --- | --- |
| 0 | Bina | Yüzey koordinatı yok; uygun districtler arasında adet aktarımı | Aynı model, girdi tercihi ve gerçek ödeme payı. |
| 1 | District | Aynı gezegende district yüzey konumu | İçindeki gerçek bina adetleri ve ayarları. |
| 2 | City | Aynı gezegende City konumu | Capital, districtler ve binalar. |
| 3 | Gezegen | Aynı güneş sistemi içinde gezegenin ekonomik harita konumu | City/district/bina alt ağacı ve gövde kimliği. |
| 4 | Güneş sistemi | Aynı Gökada içinde sistem konumu | Gezegenler ve bütün alt yerleşimler. |
| 5 | Gökada | Aynı galaksi içinde Gökada konumu | Güneş sistemleri ve bütün alt yerleşimler. |

Tip 3-5 satırlarını yalnız “gezegen üzerindeki binaları taşı” diye daraltma. **Seçilen üst nesnenin konumu değişir**, alt içerik onunla birlikte korunur. Gövde yeniden seed edilmez, minerali/türü/boyutu değişmez, ikinci gövde üretilmez. Hareketin yörünge fiziği, yakıtlı filo yolculuğu veya çarpışma simülasyonu bu düzenleme özelliğine eklenmez; değişen şey oyun haritasındaki gerçek ekonomik konumdur.

Üst nesne taşındığında kendi iç koordinat sistemi korunur. Gezegen taşınırken City'lerin enlem/boylamı aynı kalır. City taşınırken districtlerin yerel düzeni yeni yere aktarılır ve o yeni yerdeki arazi şartları yeniden değerlendirilir. Aynı km aralıkları korunur; kamera ölçeği yüzünden mesafeler şişmez.

### Yetki ve önerilen bedel

Bu özellik henüz mevcut bir sistem olarak sunulmuyor; büyük güncellemeye eklenecek skill tasarımıdır. Yıkıp yeniden kurma her zaman alternatif kalır.

| Yetki | İlk kullanım | Science tabanı |
| --- | --- | ---: |
| Yerleşim Düzenleme | Tip 0'da district/City yüzey düzenleme ve bina aktarımı; Tip 1 district yönetiminde de sürer | 250 |
| Üst Ölçek Düzenleme: City | Tip 2 otomatik City planlarını üst arayüzden düzenleme | 2.500 |
| Üst Ölçek Düzenleme: Gezegen | Tip 3 gezegen konumu | 25.000 |
| Üst Ölçek Düzenleme: Sistem | Tip 4 sistem konumu | 250.000 |
| Üst Ölçek Düzenleme: Gökada | Tip 5 Gökada konumu | 2.500.000 |

City yetkisi Tip 0'da bir City'yi elle taşımayı geri almaz. Üst yetki büyük otomatik City planlarını toplu/üst görünümden düzenlemeyi açar. Aynı alt nesneyi daha yüksek tipte gördü diye eski kazanılmış taşıma hakkı kapatılmaz. İleri yetkiler ayrı açık `scope` taşır; yalnız ad benzerliğiyle eski yetki gezegen taşıma izni olmaz.

**Taşıma hizmeti:** Aynı ebeveynde konum değişikliği, seçilen nesne + alt ağacın gerçek edinim kredi toplamının %10'u. Daha az gelişmiş nesneyi taşımak ucuzdur; bütün gelişmiş City daha büyük yatırım ister. Bu hizmet gideri sonradan yıkım iadesine eklenmez.

Başka district/City ebeveynine aktarım ayrıca hedefteki aynı tür fiyatını atlamamalı:

```text
B = ebeveyni değişen nesnenin yalnız kendi kuruluş kredi payı
P = hedefte aynı nesnenin sıradaki kuruluş kredi fiyatı
Fiyat farkı = en fazla(0, P - B)
Toplam taşıma = hizmet bedeli + fiyat farkı
Yeni edinim kaydı = eski edinim kaydı + fiyat farkı
```

Örnek: 150 kredi paylı Lab, hedefte 259,20 kredi sırasına gidecekse fark 109,20 + hizmet 15 = **124,20 kredi**. Yeni maliyet payı259,20; hizmet 15 iade tabanına girmez. Böylece boş yerde ucuz kurup dolu districte ucuz aktarmak fiyat kuralını aşmaz.

Alt ağaç içindeki ebeveynleri değişmeyen çocukları ikinci kez satın alınmış sayma. Yalnız gerçekten değişen hedef sayacı ve konum hizmeti fiyatlanır. Başka doğal gövdeye koloni transferi, bu aynı harita içi düzenleme kapsamına otomatik dahil değildir; yeni kolonizasyonu veya demo kilidini aşamaz.

Fiyat farkındaki B'ye çocukların veya değişmeyen seviye yükseltmelerinin maliyetini katma. Her değişen ebeveyn ilişkisi için ayrı kök kuruluş payı ve hedef fiyatı karşılaştırılır, farklar toplanır. Örnek: kuruluşu 300 olan district ve 3.000 kredilik çocukları, hedefte 675 kredi sırasına taşınırsa fark **375**; hizmet 330; toplam 705 kredi. Çocukların maliyeti yalnız hizmet hesabına girer, 375 farkı sıfırlamaz. Aynı ebeveynde yalnız konum değişiyorsa fiyat farkı 0'dır.

### Taşıma işlemi

1. Hedefin yetki, aynı harita, boş yer, minimum aralık, ebeveyn kapasitesi ve kaynak koşullarını denetle.
2. Bütün alt ağacın yeni koşullarını önizle. Eski/yeni coğrafya, yakınlık, uzaklık, nüfus ve enerji farkı gösterilir.
3. Özel arazi isteyen çocuklar uygunsuz kalıyorsa sessizce silme. Varsayılan işlem geçersizdir; oyuncu konumu/planı değiştirir veya açık ek düzenleme seçer.
4. Devam eden ücretli üretim turunu tamamla; taşınmayı bekleyen adetler yeni tur başlatmasın. Sonra tek atomik taşıma uygula.
5. Kimlikler, ödeme kayıtları, kullanıcı isimleri, seviyeler ve girdi ayarları korunur. Eski/yeni sayımlar ve bonuslar yenilenir.
6. Taşıma bitince ilgili otomatik plan `elle değiştirildi` olur. **Güncelle** bu konumu kendiliğinden geri almaz. Oyuncu isterse sabitlemeyi kaldırabilir.

Bekleme sırasında hedef veya fiyat değişebileceği için atomik işlemden hemen önce bütün koşulları tekrar denetle. Onaylanan bedel artmışsa sessizce ek tahsil etme; yeni teklif göster. Hedef artık geçersizse eski konum/ödeme korunur.

Hareket ücretsiz üretim, iade veya görev tekrarı doğurmaz. İptal edilen taşıma hizmeti tahsil edilmemişse ödeme yoktur; tamamlanmadan yer değişmiş gibi bonus verilmez.

Demo sınırı geçerlidir: eski Dünya/Ay'da izinli düzenleme yapılabilir, varılan yeni gezegende bu araçla bedava yerleşim veya Tip 1 ekonomisi oluşturulamaz. İleri ölçeklerde yetki/oynanış kilidi önizleme arayüzünden ayrı uygulanır.

## 17. Trade: kabul edilmiş kapsam ve sabit ilk fiyatlar

**Kesin kararlar:** Science krediyle alınıp satılabilir. Fuel/Rare araştırması açıldıysa fabrikası kurulmadan satın alınabilir. Goods başlangıçtan işleme erişimine sahiptir. Ham kaynaklar yine medeniyet + yerel keşif koşulunu ister.

### Fiyat tablosu

| Ürün | Referans | Oyuncu satış | Oyuncu alış |
| --- | ---: | ---: | ---: |
| Ferrite | 2 | 1,8 | 2,2 |
| Moonstone | 3,5 | 3,15 | 3,85 |
| Science | 5 | 4,5 | 5,5 |
| Goods | 22 | 19,8 | 24,2 |
| Fuel | 34 | 30,6 | 37,4 |
| Rare | 92 | 82,8 | 101,2 |

Sayısal taslak: satış referansın %90'ı, alış %110'u. Gelecek ham referansı `2 × nadirlik verimi`; keşiften önce fiyat/ad gösterme. Sürekli arz/talep ve oynayan fiyat sistemi bu sürüme eklenmez.

Bir şeyi alıp hemen satmak paranın yaklaşık %81,82'sini geri verir; bu işlem kâr yaratmaz. Hammaddeyi işleyip satmak ise gerçek bina, girdi, süre ve kapasite kullanan geçerli stratejidir.

### Erişim ve taşma

- Ticaret Erişimi150 ile manuel al/sat ve kapasite fazlasını krediye çevirme açılır.
- Ticaret Otomasyonu300, rezerv üstü satış ve hedef stok alışını açar; manuel Science satışı için bu ikinci skill gerekmez.
- Trade öncesi yeni taşma kaybolur. Trade sonrası yeni taşma satış fiyatıyla kredi olur.
- Trade ilk fiziksel Moonstone keşfini veya yerel 100 çıkarım görevini tamamlamaz.
- Aynı üründe alış hedefi satış başlangıç stokundan yüksek olamaz. Böylece otomasyon aynı anda alıp geri satmaz.
- Bakım/döngü ve ilan edilmiş kuruluş rezervi satıştan önce ayrılır. Roket için tutulacak Moonstone satılmaz.
- Kredi yoksa yalnız karşılanabilir miktar alınır; borç veya tekrar ödeme yok.
- Offline kaynak akışları aynı trade fonksiyonundan geçer; Bölüm 18 kotası ayrıca uygulanır.

### Değer karşılaştırması

Normal koşulda Goods Factory: dakikada12 Ferrite ->6 Goods. Bütün Ferrite alınırsa net satış118,8 - alış26,4 = **92,4 kredi/dk**. Fuel küçük model net183,6 -52,8 =130,8; Rare net248,4 -79,2 =169,2. Taban krediye göre geri dönüşler yaklaşık 3,25 /3,44 /3,55 dakika.

Bu karşılaştırma district, araştırma, enerji/nüfus desteği, tekrar artışı, coğrafya ve yerleşim bakımının tamamını kapsamaz; oynanış dengesi ispatı değildir. Üç temel tarifin fırsat maliyetini aynı ölçüyle kıyaslamak içindir.

## 18. Offline: 1/10 ortak saat ve medeniyete bağlı kazanç kotası

**Kesin karar:** Varsayılan açık, kapatılabilir. Üretim, tüketim, trade otomasyonu, inşaat, yükseltme ve başlamış uçuş dahil. Eski 10x/saat üst sınırı kaldırıldı. Amaç depolu malzemeyi sınırlamak değil, otomasyondan sınırsız kredi/Science birikmesini önlemek.

### Ortak saat

```text
Offline ekonomi zamanı = kapalı geçen gerçek zaman × 0,10
```

Bir saat kapalı ->6 dakika ekonomi. Üretim20 sn, sefer60 sn, inşaat4 sn gibi bütün ekonomi olayları bu ortak zamandan ilerler. Üretimi yavaşlatıp aynı aralıkta tüketimi veya uçuşu başka hızda işletme.

Yeni skill alınmaz, yeni yerleşim veya yeni roket kendiliğinden başlatılmaz. Önceden başlatılmış inşaat tamamlanabilir ve kalan sürede üretime katılır. Varış bir kez işlenir; demo varışı sonrasında eski Dünya/Ay kalan süre boyunca çalışır.

### Sayısal kota tasarımı

**Önerilen işleyiş:** Cüzdandaki toplam paraya değil, offline kaynaklı **yeni pozitif kazançlara** kota. Harcamak kotayı geri doldurmaz.

| Medeniyet tipi | En fazla yeni offline kredi bütçesi | En fazla yeni offline Science bütçesi |
| ---: | ---: | ---: |
| 0 | 10.000 | 2.000 |
| 1 | 100.000 | 20.000 |
| 2 | 1.000.000 | 200.000 |
| 3 | 10.000.000 | 2.000.000 |
| 4 | 100.000.000 | 20.000.000 |
| 5 | 1.000.000.000 | 200.000.000 |

Tek formül: kredi10.000×10^tip, Science 2.000×10^tip. Bunlar ilk sayısal ayardır. Online servet100 milyon ise offline açılışta para silinmez; online kazançta tavan yoktur.

### Kota aç-kapatla yenilenmesin

Saklanan iki ayrı kullanılabilir offline bütçe vardır. Yeni oyunda doludur. **Yalnız oyun açık, ekonomi aktifken** yavaşça dolar:60 dakika aktif online süre bir tam bütçe doldurur; üstü birikmez. Duraklatma veya offline süre bütçeyi doldurmaz. Kapatıp açmak, kayıt yüklemek ve harcama yapmak yeni bütçe vermez.

Dolum, oyun hızından ve takvim saatinden bağımsız gerçek aktif süreyle ölçülür. Bütçe kesirli saklanır; her kare küçük payı sıfıra yuvarlama. Oyunun zaman hızını artırmak kotayı hızlandırmaz. Takvim saati geriye gitmişse geçen süre0 sayılır ve son işlenmiş zaman damgası da geriye çekilmez.

Bu sayede bir hafta kapalı kalma haftalarca para kotası üretmez. Oyuncu kısa süre açıp kapatarak da her seferinde10.000 kredi alamaz. Günlük takvim reseti ve geriye dönük saatlik kota çoğaltımı kullanılmaz.

Medeniyet değişince kota üst sınırı yeni tipe çıkar; önceki kalan bütçe korunur, ilerleme anında tam dolu yeni hediye verilmez. Kullanılan offline dönemin bütçesi kapanışta sabitlenir; uçuşun offline varışta tipi artırması aynı dönemin kazanç hakkını büyütmez. Sonraki online sürede yeni tipe göre doldurulur.

### Neler kotadan düşer?

| Kaynak akışı | İşlem |
| --- | --- |
| Bina/district/City/nüfus kaynaklı kredi | Yeni kredi bütçesini kullanır. |
| Science üretimi | Yeni Science bütçesini kullanır. |
| Malzeme veya Science satışı | Kazanılan kredi kredi kotasına dahildir. |
| Krediyle Science alışı | Alınan Science Science kotasına dahildir. |
| Kredi/Science harcama | Kullanılmış kota geri gelmez. |
| Malzeme alışı | Mevcut krediyle yapılır; yeni kredi hakkı üretmez. |
| Bina/iade veya görev olayı | Kaynak veren bütün pozitif otomatik akışlar aynı kota kapısından geçer; ayrı kestirme gelir yolu yok. |

Örnek:10.000 kredi offline kazanılıp Fuel'a harcansa da yeni kredi kotası0'dır. Science 2000 üretilip satıldıysa Science kotası yine0; satış kredisi ayrıca kredi kotasını kullanır. Alış yapıldıktan sonra kota dolu diye Science'ı çöpe atma: alış miktarı işlemden **önce** kalan hakka düşürülür.

### Kota dolunca diğer ekonomi

- Kredi/Science kazancı kendi kalan hakkı kadar verilir; negatife inmez. Üreten akış bekleme nedeni gösterir.
- Malzemeler depoya sığıyorsa üretim devam eder. Kredi kotası doluyken otomatik satış yalnız kalan hak kadar stok satar; tamamını alıp paranın yarısını silmez.
- Depo da dolu ve satış hakkı yoksa yeni ilgili üretim döngüsü başlatılmaz, girdisi alınmaz. Önceden ödenmiş en fazla bir tur/çalışan adet çıktısı tamamlanma bekleyebilir; sınırsız gizli depo oluşmaz.
- Bu durum bütün inşaat, kapasite ve uçuşu durdurmaz. Yerel bağımsız akışlar çalışmayı sürdürür.
- Tek kaynak kapısından geçen kota denetimi ticaret, nüfus ve doğrudan gelirde aynıdır. Üst görünüm geliri yeniden eklemez.

**Turdan küçük kalan kota:** Yeni offline döngü başlamadan tam adetlerin beklenen kredi/Science çıktısına kota ayrılır; bir tam adede yetmiyorsa o adet başlamaz, gideri alınmaz. Daha küçük başka akış kalan hakkı kullanabilir. Önceden başlamış, girdisi ödenmiş bir turun sonunda örneğin 20 Science gelirken yalnız 3 hak kalmışsa en fazla 3 verilir; kalan 17 offline sınırı nedeniyle **üretilemeyen potansiyel** sayılır, sonradan online'a taşınan gizli Science borcu/deposu olmaz. Önceden tüketilmiş girdi geri verilmez. Bu sınırlı son tur durumu sonraki boş döngülerin sürmesine izin vermez. Malzeme için tanımlanan tek tur bekleyen çıktı kuralı, kredi/Science sınırını aşmak için kullanılamaz.

Kota ayırma, stok gideri, satışta stok düşümü ve kaynak ekleme aynı işlem kaydına bağlıdır. İptal edilen, çıktısı verilmemiş rezerv serbest bırakılır; verilmiş gelir için kota iadesi olmaz. Böylece aynı hak hem bir üretime hem otomatik satışa iki kez ayrılmaz.

Uzun sürede her kareyi çalıştırma. İnşaat bitişi, girdi tükenmesi, depo/kota dolması, döngü bitişi ve uçuş gibi sonucu değiştiren olaylar arasında ilerle. Yapılandırma değişmedikçe bütün akışlar duruma oturmuşsa kalan süre aynı durumdan hesaplanır. Büyük sayıdaki gök cismi önizlemesi ekonomiye katılmaz.

Kayıt zaman damgası ve işlenmiş aralık tek kez güncellenir. Negatif geçen süre0. Aynı offline aralık yüklemeyle tekrar kazanılmaz. Oyuncu kapatırsa yeni offline hesap yapılmaz; yeniden açmak kapalı bırakılmış geçmişi geriye dönük toplamaz. Özet ekranı kredi/Science kota kullanımı, üretim, tüketim, trade ve net malzeme farkını gösterir.

## 19. Doldurulmuş Ay ve gelişmiş roket akışı

Bu yol genişleme noktasıdır; bütün oyuncular aynı fabrika listesini kurmak zorunda değildir. **Yerel Production, gerçek çıkarım ve Lunar Spaceport** fiziksel zorunluluktur. İşlenmiş ürünler üretilerek veya araştırması açıldıktan sonra trade ile alınabilir.

| Adım | Gerekli durum | Açık bedel | Süre / sonuç |
| --- | --- | --- | --- |
| Dünya Capital Lv2 | Capital Lv1 | 250 kredi; +500 yük | 10 sn, 2 yuva. |
| Dünya Spaceport | Rocketry; 2 boş Capital yuvası | 500 kredi | 4 sn. Moonstone istemez. |
| Ay lander | Lunar Program + Spaceport | 3.000 kredi + 40 Ferrite + 20 Fuel | 30 sn hazırlık +30 sn uçuş. |
| Ay ilk City | Lander varışı | Ücretsiz ilk kabuk/merkez | 4 sn; global kapasite ve taban gelirlere katılır. |
| Ay ilk Production | Herhangi bir geçerli kuruluş yeri | 300 kredi +30 Ferrite | 4 sn; Moonstone keşfedilir ve çıkarılır. |
| Yerel çıkarım | Gerçek Moonstone üretimi | Toplam100 Moonstone üretim olayı | Ticaret veya keşif tek başına sayılmaz. Harcama değil sayaçtır. |
| Ay Malzemeleri | Çıkarım yapabilen Ay Production tamamlanmış | 1.200 Science | Lunar Spaceport ve yerel Ay planları. |
| Ay Capital Lv2 | Capital Lv1 | 250 kredi; +500 yük | 10 sn; Lunar Spaceport'un2 yuvası. |
| Regolit Goods planı, isteğe bağlı | Ay Malzemeleri | 900 kredi +100 Moonstone +20 Goods | 4 sn,2 yuva; temel/ithal Goods alternatifi. |
| Lunar Spaceport | Ay Malzemeleri;2 boş Capital yuvası | 8.000 kredi +200 Moonstone +50 Goods +30 Fuel +10 Rare | 30 sn; zorunlu özel tesis. |
| Gelişmiş Gezegen Roketi | Ay Malzemeleri +Rare İşleme +100 yerel çıkarım | 2.000 Science | Araştırma anlık. |
| Gelişmiş roket | Araştırma +Lunar Spaceport | 12.000 kredi +1.200 Moonstone +30 Goods +120 Fuel +40 Rare | 60 sn hazırlık. |
| Uçuş | Oyuncu sistemdeki diğer gezegenlerden birini seçmiş | Ek mesafe bedeli yok | 60 sn; varışta Tip 0 biter, Tip 1 başlar. |

Hedef uzaklığı demo fiyatını değiştirmez. Gaz gezegeni seçilirse varış yörüngeye erişim olarak gösterilebilir; yüzey City kuruluşu zaten demoda kapalıdır. Hazırlıkta hedef ücretsiz değişebilir, kalkıştan sonra sabittir.

### Son hazırlık toplamı

| Kapsam | Kredi | Moonstone | Goods | Fuel | Rare |
| --- | ---: | ---: | ---: | ---: | ---: |
| Lunar Spaceport + roket | 20.000 | 1.400 | 80 | 150 | 50 |
| Ay Capital Lv2 dahil | 20.250 | 1.400 | 80 | 150 | 50 |
| Ay Capital Lv2 ve Regolit planı dahil | 21.150 | 1.500 | 100 | 150 | 50 |

Roketin1.200 Moonstone tek ödemesi taban500 depoya sığmaz. Örneğin bir Warehouse kapasiteyi1.500'e çıkarır. Depo Dünya'da veya Ay'da olabilir; global stok kapasitesi aynı hesaptır. Başka uygun depo desteği de hedefi sağlayabilir; Warehouse kimliği özel zorunlu kapı değildir.

Tablodaki Dünya/Ay sefer-kuruluş adımlarına standart Warehouse 300 de eklenirse, başlangıç Dünya üretim yatırımları hariç görünen zorunlu kredi **24.600** olur. Bunun dışında araştırma, temel Dünya district/binaları, ek seviye, enerji, tüketim ve tercihe bağlı binalar vardır. Bu rakam “bütün demo maliyeti” değildir.

Yerel100 Moonstone görevi ayrı ödeme değildir; bu stok normal malzemelerde kullanılabilir. İşlenmiş ürünleri yapmak için harcanan ham doğrudan Moonstone bedeline dahil değil:

- Son satırdaki100 Goods +150 Fuel +50 Rare, normal Ferrite tarifinde ayrıca **1.400 Ferrite** ister.
- Aynı ürünler Moonstone ile yaklaşık **800 Moonstone** ister;1500 doğrudan +800 işleme = **2300 Moonstone** eşdeğeri.
- Tam tur, döngü Goods gideri, nüfus/enerji verimi ve diğer bonuslar gerçek toplamı değiştirir. Bu örnek normal verim ve giderler hariç karşılaştırmadır.

Lander'ın ilk20 Fuel'ı Ay'a gitmeden önce sağlanır; son Ay işleme örneği bütün önceki Fuel'ın Moonstone ile üretildiğini varsaymaz.

Ay Habitatı, Numune Lab, İkmal Pazarı ve bazı Dünya ileri modelleri Moonstone istediği için madenin rolü yalnız roket ödeme simgesi değildir. Ancak bunların hepsini kurmak zorunlu yapılmaz.

## 20. Sürekli görev paneli ve alt yerleşim butonları

### Görev paneli

Ana görev medeniyet geçişini, ara görevler gerekli adımları gösterir. Panel sürekli erişilebilir ve daraltılabilir; tam ekran kilit değildir. İleride narrative hook'lar aynı yapıya eklenebilir.

| Görev | Koşul |
| --- | --- |
| Ana: Tip 1'e ulaş | Ay roketinin seçilmiş gezegene varması. |
| Üretim temelini oluştur | Geçerli ilk normal district ve çalışabilen enerji/nüfus. |
| İlk minerali keşfet/çıkar | Ana dünyada uygun Production ve gerçek Ferrite üretimi. |
| Bir strateji kur | Bilim, nüfus, ticaret veya sanayi gelir yolunu işler hale getir; hepsini zorunlu isteme. |
| İşlenmiş ürünlere eriş | Goods/Fuel/Rare gerekli araştırmaları ve ihtiyacın temini. |
| Ay'a ulaş | Spaceport, lander, varış alt işaretleri. |
| Ay üretimi | City +Production;100 gerçek Moonstone. |
| Lunar Spaceport | Yerel özel tesis tamamlanmış. |
| Gelişmiş roket | Gerekli araştırma ve isimli malzeme ödemesi. |
| Hedef ve varış | Seçim, hazırlık, uçuş, bir kez medeniyet geçişi. |
| Demo sonrası | Fraktal ağaç gösterimi ve serbest üst harita incelemesi. |

Liste yeni sert araştırma sırası değildir. Rare tamamlanmadan Ay'a gidilebilir. Ara görevler erken tamamlanabilir. “Fuel edin” üretim ve izinli trade'i kabul eder; “mutlaka şu rafineriyi kur” demez.

İlk sürümde ekonomik görev ödülü 0. Eski tutorial kredi/Science ödülü, eksik parayı tamamlama, atlamada Ferrite ve tekrarlanabilir eski yardım yolları devreden çıkar. Tutorial metni/seed'i yeniden tasarlamak ise hâlâ askıda; eski ekonomiyi sürdürmek anlamına gelmez.

Tamamlanma `event_id` ile bir kez kaydedilir. Aynı binayı yıkıp kurmak, oyun yüklemek veya offline işlemek tekrar ödül/başarı tamamlaması üretmez.

### Eski lenslerin yerine rol butonları

| Buton | Görsel vurgu / öneri |
| --- | --- |
| Energy | Seçilen enerji ailesi için uygun görünen arazi. |
| Population | Konut kapasitesine uygun arazi. |
| Production | Dağ, volkan, krater vb. miktar bonusları; mineral yatağı haritası değil. |
| Science | Dağ, eski yerleşim, soğuk saha vb. |
| Commercial | Kıyı, liman, delta ve mesafe tercihi. |

Eski Terran/Tidal/yeraltı mineral yoğunluğu ve sürekli saha yüzdeleri kaldırılır. Görünür coğrafyayı vurgulayan üç kademe kullanılır; yalnız renkle anlatılmaz. İlk bakışta görülmeyen coğrafyayı açmak için butona basma zorunluluğu yaratma.

Öneri düğmesi oyuncunun yakın/uzak/dengeli hedefi, coğrafya, enerji/nüfus ve fiyatıyla **en fazla üç kuruluş önerisi** verir. Örnek gerekçe: “Dağ üzerinde; aynı türden4 yakın kaynak.” Tek belirsiz toplam puan yerine nedeni göster. Taşıma ve Güncelle önizlemesi aynı konum hesaplarını kullanır.

## 21. Demo sınırı, fraktal gösterim ve evren incelemesi

### Durum akışı

| Durum | İzin |
| --- | --- |
| Tip 0, ilk dünya | Normal ekonomi; bütün üst haritalarda serbest tur yok. |
| Lunar Program / hedef seçimi | Ay ve sınırlı Solar görev görünümü açılabilir. |
| Ay varışı / ilk Ay City'si | Demo bitmez; yerel ekonomi gelişir. |
| Seçilen yeni gezegene ilk varış | Tip 0 tamamlandı, medeniyet1; demo içeriği sonuna ulaşıldı. |
| Demo sonrası | Dünya/Ay ekonomisi ve izinli Tip 0 düzenlemeler devam; ayrıntılı üst ölçekler serbest inceleme. |

**Varış yerleşim değildir.** Hedef gezegende otomatik Orbital City veya başka ekonomi oluşturma. Otomatik merkez, gerçekten izin verilmiş yerleşim işleminde oluşturulur; demo varışında değil.

İki ayrı alan gereklidir: `civilization_type = 1`, fakat `playable_content_type = 0` ve `demo_completed = true`. Eski Dünya/Ay'ı yönetmek sürer; Tip 1 yeni kuruluş, kaynak veya research satın alma yetkisi yalnız civilization alanından türetilmez. R01'de miras satın alma seçilirse ayrı açık istisna gerekir.

Eski City'lere Tip 1 canlı aile etiketleri atanabilir; mevcut adlar ve gerçek alt nesneler korunur. Demo devamında eski yüzey City kuruluşu Tip 0 kurallarıyla çalışır. Tip 1'deki yeni planetary ekonomi/City plan fiyatı yanlışlıkla bu eski ekrana uygulanmaz.

Varış mesajı kapatılabilir. Eski engelleyici demo paneli yerine ilerleme sonucu, fraktal dönüşüm ve evreni inceleme girişleri gösterilir. Ekonomiyi durdurma.

### Büyük evren hissi

Güneş sistemi, Gökada, Galaksi, Evren, Paralel Evrenler ve içlerindeki ayrıntılar varıştan sonra incelenebilir. Oyuncu gezegenlere kadar yakınlaşabilmeli. Oynanabilir olmayan nesnede satın alma/kuruluş/taşıma/araştırma çağrıları altta da engellenir; yalnız düğmeyi gizlemek yetmez.

İncelenen bölgeler deterministik seed ile gerektiğinde üretilir. Milyarlarca gezegen aynı anda belleğe yüklenmez. Önizleme kaydı aktif koloni veya gelir kaydı değildir. İnceleme sırasında eski koloniler bağımsız ekonomi saatinde çalışır.

Skill ağacında büyük geleceğin silueti oyun sırasında da görülebilir. Tam evren turu ise demo sonundadır. Kilitli mineral isimlerini iki görünüm de erkenden sızdırmaz.

## 22. Yan sistemler ve yeni kayıt şeması

### Tutulacak en az veri

| Veri | Neden gerekli? |
| --- | --- |
| Medeniyet, oynanabilir içerik tipi, demo ve varış olayları | Demo bitişi ile eski ekonominin sürmesini ayırmak. |
| Gerçek ebeveyn/çocuk kimlikleri | Özet ve ayrıntıda tek ekonomi; alt ağaç yıkımı/taşıması. |
| Oyuncu adı, plan/sürüm, canlı aile, sabit fiyat ailesi | Kullanıcı ismini korumak ve fiyatı canlı tür değişiminden ayırmak. |
| Konum, fiziksel yarıçap, yerel koordinat sistemi | Her ölçeğin gerçek mesafesi ve taşıma. |
| Manuel sabitlemeler ve plan sapmaları | Güncelle'nin elle düzeni geri almaması. |
| Kalıcı keşif ve gövde mineral kümesi | Yataksız erişim; son üretici yıkılınca stokların gizlenmemesi. |
| Bina modeli, adet ve girdi alt satırları | Tek aile kartı ve ortak fiyat sayacı. |
| N/C edinim toplamları, seviye yatırımı, hizmet gideri ayrımı | Doğru iade ve taşıma bedeli. |
| Etkin bireysel/miras grant seviyeleri | Fraktal bonusu iki kez uygulamamak. |
| Döngü başlangıcı, ödenmiş girdiler, vaat edilen çıktı ve bekleme | Kayıt/taşıma/offline'da aynı gideri iki kez almamak. |
| İnşaat/sefer/taşıma işlem kimlikleri | İşlemlerin tekrar çalışmaması. |
| Trade kuralları, rezervler ve hedefler | Aynı otomasyonun online/offline sürmesi. |
| Offline kalan kredi/Science bütçesi ve son işlenen aralık | Sınırsız gelir ve tekrar yükleme kazancı oluşturmamak. |
| Tek seferlik görev/başarım olayları | Yeniden kurarak ödül tekrarı olmaması. |

Eski kayıt taşıma katmanı zorunlu değil. Yeni sürümde kaydı yükledikten sonra yeni oyun başlangıç bütçesi/erişim flag'leri üzerine yeniden yazılmamalı. Yalnız gerçekten yeni oyunda3.000/450 dağıtılır.

### Başarımlar

Eski envanterde117 tanım vardı; ekonomik ödül eklenmez. Bina sayımı kart/grup sayısı yerine gerçek adetleri toplar. District/City/gezegen sayımı gerçek sahip olunan nesnelerden gelir. Ay varışı, Ay City'si, başka gezegene varış ve medeniyet geçişi farklı olaylardır. Eski enum/skill kimliği hataları yeni sözleşmeye eşlenir; tanım dosyası bulunması çalıştığı kanıtı değildir.

### Keşif, yörünge ve askıdaki işler

- Genel filo/kargo tasarımı genişletilmez; eski gemi türleri demo seferinin zorunlu kapısı yapılmaz.
- Eski ücretli survey/asteroit taraması serbest demo önizlemesini engellemez. Gerçek ileri keşif ekonomisi ayrı gelecektir.
- Orbit City rolü ve iç districtleri için ayrıntılı oynanış ayrı pakettir; demo ana yolu onsuz tamamlanır. Tip 1 otomatik Orbital City aynı hiyerarşi sözleşmesine bağlıdır.
- Sabit tutorial seed'i, random/volkanik/gaz başlangıcı ve gövdeye göre ayrı skill ağacı askıda kalır.
- Narrative hook'lar için görev alanları ayrılır; hikâye bu rehberde yazılmış sayılmaz.
- Görsel gün/gece, yörünge dönüşü ve kamera hareketi ekonomik konum veya ikinci zaman saati değildir. Yeniden konumlandırma işlemi gerçek konum verisini değiştirir; kozmetik animasyon değiştirmez.

## 23. Kaynak dosyaları ve uygulanacak veri sözleşmeleri

Bu bölümdeki mevcut dosya/fonksiyon adları20 Ekim2026 tarihinde klasörden okunmuştur. Yeni sistemin oyunda hazır olduğu iddia edilmez. Uygulama sırasında satır numarası yerine işlevi tekrar bul; aktif çağıranları da değiştir.

| Mevcut yer | İncelenecek işlev / değişiklik |
| --- | --- |
| `scripts/game/GameState.gd` | `add_resource`, `consume_resource`, `earn_credits`, `add_science`: tek kaynak akışı, trade/kota bağlantısı. `get_body_resources`, `_populate_mineral_densities`, `_register_resources`: gövde mineral kümesi ve keşif; yoğunluk kaldırılır. |
| Aynı dosya | `moon_colonize_block`, `start_moon_colonization`, `_on_ship_arrived`, `complete_act1`, `finish_colonization`: Ay ve son gezegen olayını ayır; medeniyet/demoyu son varışa taşı. `save/load_save/_bootstrap_world`: yeni şema, başlangıç üstüne yazmama. |
| `scripts/game/Economy.gd` | `RAW_TABLE`, `BASE_CAP`, `BUILD_COST_GROWTH`, `CITY_BASE_POP`, `DISTRICT_POP`, `LEVEL_POP_BASE`: bütün ortak sayıları yeni tablolara bağla. |
| `scripts/game/PlanetProgress.gd` | `district_slots`, `slots_used_in_district`, `build_in_district`, `stack_building_unchecked`, `split_building`, `merge_identical`, `remove_building_stack`: iki yuva, ortak aile sayacı, N/C ödeme, girdi alt satırı ve alt ağaç komutları. Eski bina yükseltme yolu etkinleşmesin. |
| `scripts/game/ProductionManager.gd` | `_tick_all`, `_tick_district_base`, `_pay_inputs`, `_on_tick_complete`, `_produce_raw`, `output_per_cycle`, `resource_rates`: ortak döngü, seçili mineral, tek çıktı ve offline ortak hesap. |
| Aynı dosya | `district_income`, `district_base`, `get_site_mult`, `local_mineral_factor`, `_calc_global_energy`, `planet_pop_speed`, `ISOLATION_RANGE_DEG`: global nüfus, yataksız üretim, km profili, bütün tam katkılar; eski dereceli/azalan/yol ekonomisini kaldır. |
| `scripts/game/BuildingDef.gd` | `site_block_reason`, `site_mult`, `pop_use`, `get_build_cost` ve kaynak tanımı alanları: yeni coğrafya, iki yuva, tek döngü ve isimli tarif. Eski `get_upgrade_cost` aktif bina level yolu olarak kullanılmaz. |
| `scripts/game/DistrictDef.gd` | `site_mult`, `income_from`, `type_key`, kuruluş sabitleri: ekonomik aile/merkez ayrımı, mesafeye bağlı ilişki, yeni fiyat. Enum `CITY` adını Capital/City rolüyle körlemesine eşitleme. |
| `resources/buildings/*.tres` ve district kaynakları | Katalog sayıları, `slot_cost`, açılış, `cycle_inputs/outputs`, `active_capacity_effects`, gerçek aile/plan kimlikleri. Bunlar hedef alan adlarıdır, mevcut oldukları varsayılmaz. |
| `scripts/game/SkillTree.gd` | `_init`, `gate_block`, `building_unlocked`, `get_next_cost`, `purchase_skill`, bonus getter'ları: yeni düğümler, ortak yol, aile zammı, canonical grant ve fraktal max birleştirmesi. |
| `scripts/ui/SkillTreeView.gd` | `_build_tree_graph`, bağlantı çizimi, satın alma görünümü: büyük ağaç, üst miras düğümü ve R01 demo izni. |
| `scripts/planetary/PlanetaryView.gd` | `_rebuild_lens_bar`, `_site_resource_lines`, `_district_options`, `_build_slot_card`, `_build_production_bar`, `_build_district_panel`, `_build_city_panel`: rol lensi, büyük kart, tek aile/girdi satırları, Güncelle/taşı/yık/sıfırla önizlemeleri. |
| Aynı dosya | `_rebuild_roads`, `_store_road_relations`, `_road_links`: görseller kalabilir, bonus kaynağı olmasın. `_build_spaceport_card` ve `_sp_*`: filo paneli yerine sade sefer durumları. |
| `scripts/solar/SolarView.gd` | Hedef seçimi ve `_build_planets`, erişim kontrolü: sadece sınırlı seçim ile demo sonrası tam incelemeyi ayır. |
| `scripts/galaxy/GalaxyView.gd` ve ilgili harita verisi | Üst ölçek önizlemesi, gerektiğinde üretim, ekonomik erişimden ayrı kamera/inceleme hakkı. Evren/Paralel Evren görünümleri yoksa eklenecek ayrı görünümlerdir. |
| `scripts/game/ShipManager.gd`, `scripts/game/logic/SpaceportLogic.gd` | Eski zorunlu gemi/Shipyard bağlarını sade hazırlık/uçuş olayına ayır; genel filo ekleme. |
| `scripts/system/TutorialManager.gd`, `scripts/game/AchievementManager.gd` | Eski ekonomik yardımları kapat; yeni görev/başarım olaylarını gerçek adet/medeniyet kimliklerine bağla. |

### Hedef servis sınırları

Mevcut bir dosyanın binlerce satırına her yeni kuralı gömmek yerine sorumlulukları ayır. Aşağıdaki adlar önerilen sorumluluklardır; mevcut altyapıyla birleştirilebilir:

| Sorumluluk | Tek doğru hesabı |
| --- | --- |
| Medeniyet/erişim | `can_play`, `can_preview`, `can_discover`, geçiş olayı. |
| Ekonomi akışı | Kaynak ekle/harca, kapasite, taşma, kota ve ledger. |
| Döngü yürütme | Online ve offline aynı girdiler/çıktılar/olay sırası. |
| Yerleşim planlama | Plan farkı ve gerçek bedel teklifi; nesne kopyalamama. |
| Konum hesabı | Coğrafya, mesafe, bütün yakın kaynaklar, önizleme ve gerçek sonuç. |
| Yerleşim komutları | Kur, Güncelle, aktar, taşı, temizle, sıfırla, yık. |
| Haklar | Bireysel +miras canonical seviyeleri; bina erişimi. |

Arayüz yalnız teklif ve komut çağırır; kendi ayrı ucuz fiyatını veya farklı bonus formülünü hesaplamaz. Kaynak işlemi başarısızsa nesne oluşturmadan geri döner. Onay ile uygulama arasında durum değiştiyse teklif yeniden hesaplanır; gizli ek ücret alınmaz.

## 24. Uygulama paketleri ve bağımlılık sırası

Bu sıra ileride kod değişikliği için kullanılacak. **Şimdi hiçbir paket oyuna uygulanmadı.** Her paketin tesliminde değişen davranış ve kalan iş açıkça raporlanır; sonraki pakete eski çelişkiler taşınmaz.

| Paket | Yapılacak iş | Bağımlılık / teslim |
| --- | --- | --- |
| P01 | Medeniyet, oynanabilir içerik ve önizleme izinlerini ayır | Yeni alanlar ve durum akışı. `act1_complete` eski Ay City'sinden son roket varışına taşınacak hedef hazırlanır. |
| P02 | Gerçek yerleşim ağacı ve yeni kayıt | Sabit kimlik, ebeveyn/çocuk, aile/plan/fiyat ailesi, N/C ledger. Yeni oyun başlangıcı yüklemede tekrarlanmaz. |
| P03 | Ortak kaynak ekle/harca/kapasite sistemi | Bütün stok akışları tek kapıdan geçer. Henüz trade/offline eklenmeden görünürlük ve ödeme doğru olur. |
| P04 | Yataksız kaynak keşfi | Gövde mineral kümesi; medeniyet +ilk uygun araç. Eski mineral yoğunluğu/yatak şartı, Rich Vein şartı ve regolit kuruluş zorunluluğu kaldırılır. |
| P05 | Tek20 sn döngü ve global nüfus/enerji | Eski 30/60 sn değerler dakikalık hız korunarak çevrilir. Tüketim, kapasite ve çıktı aynı kart verisinden gelir. Ücretsiz City nüfusu dahil boş nüfus. |
| P06 | Fiyat, level, iade ve büyük bina | Aynı model/aile yerel sayacı, yeni seviye eğrileri,2 yuva, N/C iade. Yük ve stok gerçek kuralla alınır. |
| P07 | Görünen coğrafya ve fiziksel mesafe | Üç uygunluk; bütün tam kaynak katkıları. Capital yol şartı, yol kesişimi ve yarıya azalma kaldırılır. |
| P08 | Yeni bina tanımları | Bölüm 12; Ay ve Dünya ileri Moonstone bedelleri; büyük T1 yeniden sayıları; Tier4 açık hataları kapatılır. |
| P09 | Yeni skill verisi | Ortak 6500 yol, stratejiler, erkenFuel/Rare, eski 54 kimlik eşlemesi, grant tekleştirme. |
| P10 | Trade | Manuel tüm ürünler, erken taşma satışı, rezervler ve otomasyon. P03 üzerinden çalışır. |
| P11 | Plan/Güncelle ve tip ataması | Aynı gerçek alt ağaç; yeni haklardan ücretli fark teklifi; Genel eşitlik; sabit fiyat ailesi. |
| P12 | Yık/temizle/sıfırla | Alt ağaç tek işlem, çift iade yok, geçmiş olay ve doğal gövde korunur, kaybolan depo eski stoku silmez. |
| P13 | Düzenleme/taşıma | P07/P11/P12 ile gerçek nesneler taşınır. Manuel sapma korunur; ilgili bütün ölçekler aynı sözleşmeyi kullanır. |
| P14 | Rol butonları ve ortak bina kartı | Eski lens tamamen kalkar; tek aile içinde mineral satırları; büyük kart; yer/plan/taşıma aynı gerekçeyi gösterir. |
| P15 | Ay, özel Spaceport ve son roket | Bölüm 19; zorunlu yerel üretim, seçilen hedef, iki sefer ve tek son varış. Eski Shipyard zorunluluğu kalkar. |
| P16 | Görev/başarım ve eski tutorial ekonomisi | Yeni sürekli panel; alternatif temin; ekonomik ödül 0; eski yardım çağrıları kaldırılır; olaylar bir kez. |
| P17 | Fraktal ağaç | Önceki hakların max ile tamamlanması; satın alma ve plan kurma ayrı. R01 demo kapsamına göre UI. |
| P18 | Demo sonucu ve üst önizleme | P01/P15/P17; hedefte City yok, eski ekonomi devam, büyük evren incelemesi ve fraktal sunum. |
| P19 | Offline | P03/P05/P10/P15 hazırken aynı olay yürütücüsü.1/10, kredi/Science bütçesi, online dolum ve kalan işlenmiş aralık. |
| P20 | Üst medeniyet veri sözleşmeleri | Tip 1-5 hazır plan/merkez/taşıma/ayrıntı açılımı; oynanabilir tam ileri içerik bu demo için varsayılmaz. R02 katalog yaklaşımına göre genişletilir. |
| P21 | Kullanıcının denge geri bildirimi | Farklı stratejilerin gerçek karar aralıkları, hedefe varış, kritik darboğazlar. Kullanıcı istemeden motor/test/build çalıştırılmaz. |

### Paketin tamamlanmış sayılması

Kaynakta tek yeni fonksiyon bulunması yeterli değildir. Örneğin iki yuva yalnız kartta yazıyorsa ama `slots_used` hâlâ1 sayıyorsa P06 tamamlanmış değildir. “Yol ekonomisi kaldırıldı” demek için gerçek gelir, önizleme ve eski destek yolları aynı mesafe kuralına bağlı olmalı.

Yapay zekâ her teslimde şu dört bilgiyi verir: değişen davranış; dokunulan gerçek dosyalar; kaynakta kalan sınırlamalar; **motor/test/build çalıştırılmadığı**. Oynanmış veya dengeli olduğunu söylemez.

## 25. Beklenen davranışlar ve matematik örnekleri

Bu bölüm otomatik test yazma/çalıştırma talimatı değildir. Kullanıcının incelemesi ve daha sonra kendisinin oynarken bakacağı ölçütlerdir. Yapay zekâ kendi başına bu senaryoları motor açarak denemez.

### Ekonomi ve erişim

- Yeni oyunda3.000/450 bir kez verilir; kayıt açmak tekrar vermez.
- İlk Production Dünya'nın her geçerli yerinde Ferrite keşfeder. Ay Production her geçerli yerinde Moonstone keşfeder. Yatak koşulu yok.
- Ticaretle ilk Moonstone'u almaya çalışmak yerel keşif öncesi mümkün olmaz; keşiften sonra alım mümkündür,100 yerel çıkarım sayacı ilerlemez.
- Aynı Goods kartında3 Ferrite+2 Moonstone adetleri toplam 5 bina sayılır. Normal verimde13 Goods/20 sn gösterir.
- Üst arayüz30.000/20.000 nüfus gösteriyorsa gelir skill'i10.000 boş nüfustan hesaplanır. Ücretsiz City farkı dışlanmaz.
- Tüketimli enerji binası aynı20 sn kartında gerçek Fuel giderini gösterir; Fuel bitince o ücretli dönem enerjisi etkinleşmez.

### Konum

- Yol yokken de aynı km'deki iki district yakınlık katkısı verir. Capital için de bu geçerli.
- Dört çok yakın uygun kaynak%40; sekiz kaynak%80. Beşinci kaynak gizlice yarım katkıya düşmez.
- Minimum aralık ve gövde alanı fiziksel yer sınırıdır; ekonomiye gizli “en fazla8 kaynak” sayacı eklenmez.
- Dağ yakını yarım, üzerinde tam. Aynı dağ türü City ve district aracılığıyla iki kez çarpılmaz.
- Yeni bir mineral keşfi arazi haritasına görünmez yatak eklemez.

### Katalog ve plan

- İki yuvalı Institute iki gerçek yuva ister. İki Lab ile aynı alan karşılaştırmasında12 yerine8 Science/20 sn ayrımı görünür.
- İlk Ay seferini açan **Dünya Spaceport'u** Moonstone gerektirmez; Lunar Spaceport ve seçilmiş Dünya ileri modelleri gerektirir.
- Fraktal grant eskiLv2 ilebirleşipLv3 olur, Lv5 olmaz. Yeni bina adedi oluşmaz.
- Aynı planın Güncelle'sine tekrar basınca aynı bina iki defa kurulmaz. Yer yetmiyorsa açık teklif gerekir.
- Oyuncu otomatik districti taşıyıp konumu sabitlerse sonraki Güncelle onu eski yere geri koymaz.

### Yıkım ve taşıma

- C 546/N 3 grubundan1 adet yıkım%50 ile91 kredi; kalanC364/N 2.
- City yıkımı kendi kabuk+seviye bedelini ve çocuklarını ayrı birer kez sayar; plan toplamı ikinci iade vermez.
- District sıfırlama ile içeriği temizleme farklı sonuç verir: ilkiLv1, ikincisi mevcut seviyeyi korur.
- Planet/System/Gökada taşıma aynı üst nesneyi taşır. Alt nesneler, keşifler ve kaynak türleri yeniden üretilmez.
- Hedefte259,20 fiyatlı Lab'ın150 payıyla aktarımında109,20 fark+15 hizmetödenir. Yalnız hizmet 15 ödeyerek aynı tür fiyatı aşılmaz.

### Offline ve demo

- Bir gerçek saat kapalı6 dakika ekonomi sağlar; uçuş, üretim ve tüketim bu aynı6 dakikayı kullanır.
- Tip 0 offline10.000 kredi kazanılıp harcansa yeni10.000 hak açılmaz.2.000 Science sınırı otomatik alışla da aşılamaz.
- Aynı kaydı tekrar yükleme ve kısa aç/kapat tam kota oluşturmaz. Online aktif süre yalnız tanımlı hızda doldurur.
- Kredi kotası dolu olması başlamış roketi durdurmaz; varış olayı bir kez işlenir.
- İlk Ay City'si demo sonu değildir. Başka seçilmiş gezegene varış Tip 1 olayıdır.
- Varıştan sonra Dünya/Ay ekonomisi devam, hedefte City yok, evren incelemesi açık.

### İlk denge hesaplarının anlamı

| Karşılaştırma | Normal koşuldaki hesap | Sınır |
| --- | --- | --- |
| İki Lab / bir Institute | 2 yuva:8 /12 Science; çalışan500 /750 | Institute materyal/araştırma/gider ister. |
| İki Market / Yerel Merkez | 2 yuva: 40 / 50 kredi/20 sn; çalışan 500 / 625 | Merkez bedeli 375 kredi; enerji 2 / 3. |
| İki Market / Bazaar | 120 kredi/dk /167,4 netkredi/dk | Bazaar Goods satın alma gideri dahil; araştırma/enerji/yer maliyeti hariç. |
| Boş2.500 nüfus | +25 kredi +5 Science/dk | Kaynağı bina veya City diye ayırma; gerçek boş kapasite yeterli. |
| İkinci City | +15.000 kapasite -2.000 yük; uygun skill'lerle +130 kredi/+26 Science ek etki | Gerçek ebeveyn kapasitesi, kuruluş bedeli ve toplam kullanılan nüfus değişimi hesaba girer. |
| Yakın küme | N aynı tür nesnenin, her biri diğerlerine çok yakınsa çarpanı1+0,10(N-1) | Tam kümelerin toplamı N×[1+0,10(N-1)] büyür; gizli tavan yok. |

Tip 0 demo45-75 dakika ve30-90 saniyede anlamlı karar yalnız tasarım hedefidir. Hiçbir stratejide bekleme olmayacağı veya hepsinin eşit sürede biteceği kanıtlanmış değildir. Kullanıcının oynanış geri bildirimine göre önce ortak fiyat, temel akış, seviye ve yakınlık katsayıları ayarlanır; düzinelerce gizli istisna eklenmez.

## 26. Cevap bekleyen iki içerik kararı

Eski K01-K05 kapanmıştır. Aşağıdakiler yeni matematik sorusu değildir; uygulanacak içerik kapsamını seçer. İlgili olmayan paketler bu kararlar yüzünden durdurulmaz.

### R01. Fraktal miras demoda satın alınacak mı?

**Önerim:** Gerçek ekonomiyi değiştirmeyen etkileşimli önizleme. Oyuncu bütün Tip 0 ağacının tek düğüm oluşunu, fiyatı/eksik hakları ve mevcut yerleşimdeki Güncelle örneğini görür. Tip 1 oynanabilirliği açılmaz.

Alternatif: Miras satın alınabilir, yalnız eski Dünya/Ay'a etkiler uygulanır; yeni hedefe yerleşim yine kapalı. Bu seçilirse `demo_allowed_research` içinde sadece bu düğüm açık istisna olur. Kullanıcı söylemeden gerçek satın alma izni verilmez.

**Cevabın:** Henüz seçilmedi.

### R02. Her medeniyette yaklaşık 50 yeni tür mü, ortak aile +ölçeğe özgü plan mı?

**Önerim:** Beş ekonomi ailesi +Genel +merkez/destek rolleri; ölçeğe özgü küçük/standart/yoğun ve coğrafi kuruluş planları. Tip 0 ana katalogda yaklaşık 24 çekirdek model, diğerleri koşullu seçenekler. Böylece50 districtve50 City'yi yalnız eski bina isimlerini kopyalayarak doldurmayız.

Kullanıcı50 gerçek ayrı tür isterse her biri farklı kuruluş nedeni, malzeme ve oyun rolüyle ayrıca tasarlanmalı.50 adı otomatik üretip aynı matematiği kopyalamak bu rehberin önerisi değildir. Bu karar Tip 1+tam içerik üretimini etkiler; mevcut Tip 0 adaylarının tabloları kaybolmaz.

**Cevabın:** Henüz seçilmedi.

Taşıma artık anlamı belirsiz soru değildir. Kullanıcının iki takip açıklamasıyla bütün ölçeklerdeki otomatik yerleşimi ayrıntıdan düzenlemek olduğu kesinleşti; yalnız districtle sınırlandırılmayacak.

## 27. Son cevapların eksiksiz eşlemesi ve önceki kapsam

### Son 16 seçim

| Seçim | V3 karşılığı | Bölüm |
| ---: | --- | --- |
| 1 | Ay özel modelleri ve seçilmiş Dünya T3 modelleri Moonstone ister; ilk çıkarım/sefer yolu kendi kaynağıyla kilitlenmez. | 11-12, 19 |
| 2 | Tip 3 gezegen, Tip 4 sistem, Tip 5 Gökada otomatik plan ve elle düzenlemesi ayrı tarif edildi. | 3, 16 |
| 3 | Yeni açılan modeller için ücretli fark ve manuel düzeni koruyan Güncelle; fraktal hakla fiziksel kurulum ayrı. | 6,14 |
| 4 | Eşit ve boş türün ortak adı Genel; Karma ekonomik türü kaldırıldı. | 5 |
| 5 | Alt bina yatırımı korunur; yeni ana ilerleme üst ölçeğin planı. 50 tür kopyalamama önerisi ve R02. | 4, 12, 26 |
| 6 | Tek model kartı içinde farklı mineral kullanan adet satırları. | 7,12 |
| 7 | Boş nüfus yalnız üstteki toplam-kullanılan; ücretsiz City kapasitesi dahil. | 9 |
| 8 | Yatak/yerel mineral yoğunluğu yok; gövde genelinde çıkarım ve ilk araçla keşif. | 7,10,12 |
| 9 | Capital yol istisnası kaldırıldı; bütün konum bonusları fiziksel mesafeyle. | 10 |
| 10 | Her yakın kaynak tam katkı; azalma/tavan/sıra indirimi yok. | 10 |
| 11 | Ortak 20 sn döngü, aynı kartta bütün stok artış/azalışı; kapasiteyi stok gibi biriktirme yok. | 8 |
| 12 | Büyük T1/T2/T3 iki yuva ve büyük kart; karşılaştırmalar yeni alana göre. | 11-12 |
| 13 | Fraktal gerçek tasarım; eski ağacı tek ücretli düğümle tamamla; demoda gösterim, satın alma kapsamı R01. | 14,21,26 |
| 14 | Araştırmayla açılmış işlenmiş ürün fabrikasız satın alınabilir. | 17 |
| 15 | Trade sonrası taşma doğrudan kredi; offline kotası doluysa gizli para üretme/stoğu bedelsiz tüketme yok. | 17-18 |
| 16 | Eski 10x iptal; medeniyete göre offline kredi/Science yeni kazanç kotası. | 18 |

### Sonradan eklenen taşıma açıklamaları

| Açıklama | Uygulama |
| --- | --- |
| Tip 1'de otomatik districtleri beğenmezse Tip 0 ayrıntısından düzenlemek | Aynı gerçek districti ve binalarını koruyarak konumlandırma; skill, hizmet bedeli ve bonus önizlemesi. |
| Yalnız district düşünme; Tip 2 City, Tip 3 gezegen ve sonrası da aynı | Bölüm 16'nın bütün ölçek tablosu; ilgili nesnenin konumu ve bütün alt ağacı korunur. |
| İsterse yıkıp sıfırlayabilsin | İçeriği temizle/sıfırla/yık ayrı işlemler, bütün oyuncu yerleşim katmanlarında. |

### Önceki gereksinimlerin korunması

| Önceki karar grubu | V3 konumu / yeni cevabın değiştirdiği kısım |
| --- | --- |
| Act yerine Tip 0-5, Ay'dan sonra seçilen gezegene varış, filo kullanılmaması | 1-3,19,21. |
| Kullanıcının doldurduğu katman/merkez/kaynak tabloları | 3,7. Yerel yatak yorumu son cevapla kaldırıldı. |
| İmparatorluk nüfusu, sabit kapasite, ortak ceza, fazla nüfus stratejisi | 8-9. Bina konutuyla sınırlama son cevapla kaldırıldı. |
| Kaynak gizliliği, kalıcı keşif, oyuncu girdi seçimi, isimli ödeme, nadirlik | 7,11,17. Yatak ve otomatik en nadir tüketimi yok. |
| Goods/Fuel/Rare 4:2/8:2/12:1 ve erken Science açılışı | 8, 12-13. Ortak 20 sn; bütün 3 tarif korunur. |
| Aynı tür yerel fiyat artışı, yıkımda sayaç azalması, %50-%75 iade | 11,15-16. Üstte sabit fiyat ailesi K04 kabul. |
| Bina level olmaması, üstel tier/worker/district, üst tier avantaj ve bedel | 11-12. Yeni 2 yuva kararına göre güncellendi. |
| Görünen coğrafya, üç kademe, toplama/tekilleştirme, City konumu | 10. Mineral yatak bonusu kaldırıldı. |
| Yakın/uzak strateji, fiziksel uzaklık, boyuta göre yerleşim, yol kesişiminin kalkması | 10. Yol istisnası ve katkı azalması kaldırıldı; kullanıcının son uzaklık sayıları kullanıldı. |
| Büyük skill ağacı, birleşen strateji yolları, ANY, seçim sınırı olmaması, kalıcı haklar | 13-14. Fraktal artık kesin; önceki askı metni uygulanmaz. |
| Yeni 16 bina/16 skill havuzu, mevcut 42 bina/54 skill kaybolmasın | 12-13. Ekonomik kopya model birleştirmesi açık, eski ileri/orbital kimlikler eşlendi. |
| Orbital City/district rolü | 3, 12, 22. Ayrı içerik alt paketi; eski Shipyard demo şartı değil. |
| Alt rol butonları, yer önerileri, eski lenslerin tamamen kalkması | 20. |
| Sürekli görev, narrative için alanlar | 20. Ekonomik ödül 0; K05 ile eski yardımlar kaldırılır. |
| Demo sonrası inceleme, devasa evren, başlangıçta açılmaması | 21. Eski ekonomi K03 kabulüyle çalışır. |
| Offline 1/10, tüm ekonomi, varsayılan açık, kapatma | 18. 10x/saat sınırı yerine yeni kazanç kotası. |
| Eski kayıt taşıma zorunluluğu yok, yüklemede başlangıç üstüne yazılmasın | 1,22-23. |
| Tutorial/random başlangıç/gövdeye göre ayrı ağaç askıda | 22. Bu karar eski ekonomik yardımların açık kalması demek değil. |

### Sonraki adım

Bu dosya üzerinde kullanıcı düzeltme yapabilir. R01/R02 numaralarıyla içerik tercihlerini cevaplayabilir; sayılar için “çok hızlı/yavaş”, “bu modelin rolü zayıf”, “bu strateji daha güçlü olsun” demesi yeterli. Katsayıları kullanıcıya yeniden çözdürmeden ortak kurallarla hesapla.

**Bu rehber hazırlanırken yalnız bu yeni Markdown oluşturuldu. V2 dahil eski belgeler, oyun kaynakları, ayarlar ve kayıtlar değiştirilmedi. Godot/Unity, oyun, test ve build çalıştırılmadı.**

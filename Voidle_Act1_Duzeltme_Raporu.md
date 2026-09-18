# Ana gezegen, yörünge ve Ay: uygulama denetimi

18 Eylül 2026. Bu belge önceki uygulamanın yeniden incelenmesinde bulunan hataları ve yapılan düzeltmeleri kaydeder. Act 1 yalnızca geliştirme kapsamının adıdır, oyuncuya gösterilen bölüm adı değildir.

## Kapsam ve doğrulama sınırı

Hedef: gelişmiş ana gezegen, çalışan orbital tesis, Ay kolonisi, Ay araştırması ve ilk gezegenler arası koloni gemisi. Bütün araştırmaların ve bina seviyelerinin tamamlanması zorunlu değildir.

Kontroller ayrı proje kopyası ve ayrı kayıt klasöründe çalıştırılır. Gerçek kullanıcı kaydı kullanılmaz. Teknik testler belirli durumları doğrudan hazırlayarak işlem kurallarını ve sayısal sonuçları doğrular. Bunlar sıfırdan oynanmış bir ekonomi koşusu değildir. Toplam bölüm süresi, oyuncunun kararları ve uzun beklemelerin eğlenceli olup olmadığı kullanıcı oynanışıyla değerlendirilmelidir.

## Düzeltilen hatalar

| Sorun | Düzeltme |
|---|---|
| Bina yükseltme düğmesinde çalışma anında geçersiz özellik ataması | Godot'un doğru kenarlık ayarlama metodu kullanılıyor. Gerçek bina paneli teknik kontrolde oluşturuluyor. |
| Yeni seviye 1 binanın seviye 3 gibi bir gruba ücretsiz yükselerek katılması | Normal satın alma yalnızca seviye 1 gruplarla birleşiyor. Yüksek seviyeli gruba ekleme kendi seviye bedelini ödüyor. İnşaat sırasında hedefin seviyesi değişirse yeni bina kendi satın alınan seviyesinde kalıyor. |
| Gruba ekleme yolunun district slot sınırını aşması | İşlem tarafında kapasite, kolonileştirme ve district inşaat durumu kontrol ediliyor. |
| Reddedilen bina kurulumunda paranın kaybolması | Başarısız kurulumda ödeme geri veriliyor. |
| Gezegen yükseltmesinin eski paneldeki kaynak kontrolüne güvenmesi | İşlem anında bütün kaynaklar kontrol ediliyor; eksikse hiçbir kaynak harcanmıyor. Çift yükseltme engelleniyor. |
| District yükseltme maliyetinin yalnızca arayüzde alınması | Maliyet ve seviye koşulu yükseltme işleminde birlikte uygulanıyor. |
| District yerleştirme yollarının farklı sınırlar kullanması | Koloni, araştırma, gezegen türü, yüzey/yörünge kapasitesi ve tür sınırı ortak denetleniyor. |
| Aynı district adıyla bina kayıtlarının karışması | Yerleştirmede benzersiz ad oluşturuluyor; yeniden adlandırmada çakışma reddediliyor. Devam eden yükseltme ve orbital bağlantı da taşınıyor. |
| İstasyona gemi panelinden girince binaların silinebilmesi | Gerçek orbital district bulunuyor; binalar boş gemi verisinden yeniden oluşturulmuyor. |
| Aynı orbital tesisin hem POI hem bağımsız gemi olarak çizilmesi | Bağlı station kaydı görevler için korunuyor, görsel ve inşaat kaynağı gerçek district olarak kalıyor. Bağlı istasyon başka gezegene gönderilemiyor. |
| Durdurulan orbital desteklerin bonus vermesi | Durdurulmuş destekler hesaplamadan çıkarılıyor. |
| Genel enerji, gezegen özeti ve bina kartlarının farklı hesap yapması | Ortak bina enerji hesabı seviye, miktar, yakıt, durdurma, araştırma ve district bonuslarını kullanıyor. |
| Çalışan rafineriyi yükseltince düşük bedelli girdiden yüksek seviyeli çıktı alınması | Ücretli döngünün bina seviyesi ve adedi saklanıyor. Yükseltmenin artan çıktısı sonraki ücretli döngüde başlıyor. |
| Kayıt yüklemenin tüketilmiş yakıt bayrağını yeniden açabilmesi | Yeni kayıtlardaki açık/kapalı döngü bilgisi korunuyor; eski kayıt düzeltmesi yalnızca alan eksikse uygulanıyor. |
| İşlenmiş ürünün kayıt sonrasında ad değiştirmesi | Cevher ve işlenmiş ürün aynı mineral adını koruyor. |
| Rafineri ürün seçicisinin yalnızca doğal yataklara bakması | Seçici bilinen, doğru tür ve tier'daki malzemeleri listeliyor. Rafineri çıktısının bildirimi gerçek işlenmiş ürünü gösteriyor. |
| Tersane araştırmasının üst seviyelerinin faydasız olması | Bina seviyeleri 1-5 sırasıyla %20, %25, %30, %35, %40 gemi maliyeti indirimi veriyor. En güçlü aktif tersane uygulanıyor. |
| Bilim ağacı açıkken para birikmesine rağmen araştırmanın kilitli görünmesi | Satın alınabilirlik değişince ağaç güncelleniyor. Bilim harcandığı açıkça yazıyor. |
| Yükseltme ve ekleme düğmelerinin kredi birikince kapalı kalması | Açık panelde satın alınabilirlik yenileniyor. |
| Spaceport kartında sadece Operational yazması | Doğrudan koloni gemisi üretme düğmesi, maliyet ve kalan süre gösteriliyor. Ana gezegen panelinden de erişiliyor. |
| Aynı hedefe yinelenen sefer ve yerleşim işlemleri | Varış, mevcut sefer, devam eden kolonileştirme ve tüketilecek gerçek gemi tekrar kontrol ediliyor. |

## Korunan temel ekonomi

| Unsur | Değer |
|---|---|
| Ana gezegen başlangıç şebekesi | +4 enerji |
| Solar Array, seviye 1 | +2 enerji |
| Residential | 50 kredi / 60 saniye, 2 enerji |
| University | 2 bilim / 25 saniye, 2 enerji |
| Advanced Lab | 10 bilim / 25 saniye, 8 enerji |
| Zero-G Nexus | 12 bilim / 30 saniye, 8 enerji; kendi gezegenine +%10 bilim çıktısı |
| Lunar Observatory | 24 bilim / 30 saniye, 12 enerji; Ay Outpost district'inde |
| Lunar Helium-3 | 20 enerji, Ay başına bir tesis |
| Gezegen seviye 2 | 250 kredi |
| Gezegen seviye 3 | 1000 kredi + 50 T1 cevher |
| Gezegen seviye 4 | 2000 kredi + 400 T1 cevher |
| District yükseltmesi | Mevcut district seviyesi × 500 kredi; +2 slot |
| Koloni gemisi | Tersanesiz 600 kredi + 20 T2 ingot, 30 saniye |
| Ay seferi | 60 saniye |
| Diğer gezegene sefer | 120 saniye |
| Yeni yerleşim | Varış yapan koloni gemisi + 1000 kredi, 30 saniye |

Başlangıç örneği: şebeke 4 + Solar 2 = 6 enerji arzı. Residential 2 + University 2 = 4 talep. İlk Mine eklendiğinde talep 6 olur, üretim yine %100 hızdadır. Daha fazla tüketici için enerji yatırımı gerekir.

T1 ham cevher rafineride T2 ingot olur. Bu, ilk seferin tek işlenmiş ürün basamağıdır; doğal T2 maden bulma zorunluluğu yoktur. Daha sonraki gezegen seviyelerindeki T2 ödeme kontrolü de işlenmiş ürün sınıfını kullanır.

## Seviyeler ve araştırma

Araştırma bina seviye tavanını açar. Bina ayrıca krediyle yükseltilir.

```text
Çıktı çarpanı = 1 + 0,5 × log2(bina seviyesi)
Girdi/enerji tüketim çarpanı = 1 + 0,25 × log2(bina seviyesi)
L seviyesinden L+1'e yükseltme = temel bina fiyatı × 1,5^(L-1) × bina adedi
Yeni yüksek seviyeli bina = temel fiyat + o seviyeye kadarki yükseltme bedelleri
Araştırma fiyatı = temel araştırma fiyatı × hedef araştırma seviyesi
```

Örnek: University seviye 2'de 3 bilim / 25 saniye üretir, 2,5 enerji tüketir. Bina yükseltmesi 200 kredidir. Araştırma tavanını açmak binanın seviyesini kendiliğinden değiştirmez.

Educational Grants ve Subsidized Housing her araştırma seviyesinde başlangıç değerine göre +%15; Heat Capture Loops +%5 verir. Orbital Facilities, Moon Outpost ve Interplanetary Travel tek alımlık erişim araştırmalarıdır.

Nexus ve Spaceport bina seviyeleri bilinçli olarak 1 ile sınırlıdır. Tersane seviyeleri doğrudan üretim çarpanı yerine yukarıdaki indirim basamaklarını kullanır.

## İlerleme bağlantısı

1. Ana gezegende kredi, bilim, enerji ve T1 madencilik ekonomisi kurulur.
2. Ana gezegen seviye 3 sonrası Orbital Facilities araştırılır ve yörünge district'i kurulabilir.
3. Launch Engineering araştırması Spaceport ve koloni gemisi yapımını açar.
4. Tamamlanmış yörünge district'i ve Spaceport, Moon Outpost araştırmasının koşuludur.
5. Koloni gemisi üretilir, Ay'a gönderilir; varış sonrası gemi tüketilerek Lunar Outpost kurulur.
6. Lunar Observatory araştırılır ve Ay'daki Outpost içine kurulup çalıştırılır.
7. Ana gezegen seviye 4 ve çalışan Lunar Observatory, Interplanetary Travel araştırmasının koşuludur.
8. Bu araştırma güneş sistemi erişimini açar. Sonraki koloni gemisi başka gezegene gönderilebilir; özel çevreler kendi yaşanabilirlik araştırmalarını gerektirir.

## Teknik doğrulama

`tests/Run-Act1Audit.ps1`, proje kopyasını geçici klasöre alır, Godot içe aktarımını çalıştırır ve ayrı APPDATA altında kontrol sahnesini açar. Sonuç günlüğü o klasörde kalır. Test sahnesi doğrudan normal oyun kaydıyla çalıştırılmamalıdır; kontrol betiği kullanılır.

Kontroller araştırma bağlantıları, 1-10 University seviyeleri, tekrarlanan pasifler, gerçek üretim, seviye tavanı, enerji, kapasite, ödeme, rafineri, Ay yerleşimi, tersane, koloni gemisi, gerçek arayüz bileşenlerinin oluşturulması ve kayıt dönüşünü kapsar.

Son çalıştırma: **292 kontrol, 0 başarısızlık**. Godot içe aktarımı ve test sahnesi tamamlandı; betik hatası çıkmadı. Ortamın kök sertifika deposunu okuyamadığı uyarısı mevcut, bu kontroller ağ erişimi kullanmıyor.

Üretim döngüsü süresi ve maden dağılımı da ortak hesaba taşındı. Kaynak bilgi kutusu artık karışık cevher çıkaran Mine'ın payını, rafinerinin gerçek ürününü, bina seviyesini, yakıt tüketimini ve enerjiyle yavaşlamayı hesaba katıyor. Sürekli çalışan tesisler için gösterilen tüketim hızı döngü ortalamasıdır; tarif girdisi döngü başlangıcında topluca ödenir.

Act 1 dışındaki mevcut `Find Available Star` düğümünün `dyson_swarm_dummy` önkoşulu ileri oyun yer tutucusudur. Bu denetimde yeni bir ileri oyun tasarımı yapılmadı ve o yer tutucu test kapsamına alınmadı.

Uzun süreli denge ve sıfırdan oynanış tamamlanmış sayılmıyor. Bu rapor teknik doğrulamayı, süre ve eğlence dengesinin oynanışla doğrulanmasından ayrı tutar.

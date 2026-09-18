# Voidle: Act 1 analizi ve geliştirme planı

Tarih: 17 Eylül 2026. Kaynak: mevcut proje dosyalarının statik incelemesi. Bu belge bir tasarım önerisidir; sayısal öneriler oynanış testiyle doğrulanmış nihai denge değildir. Oyun kodunda değişiklik yapılmadı.

## 1. Bölüm sınırı

Kullanıcının tanımı: Act 1 ana gezegenin gelişimi, yörüngesi ve Ay; Act 2 güneş sistemindeki diğer gezegenlere yayılma.

Önerilen akış:

```text
Başlangıç kolonisi
  → Enerji, kredi, bilim ve T1 maden üretimi
  → Ana gezegende district geliştirme ve uzmanlaşma
  → Yörünge altyapısı
  → Ana gezegenin Ay'ına sefer ve işleyen üs
  → Gezegenler arası sefer hazırlığı
  → Başka gezegene ilk sefer: Act 2
```

Kullanıcının onayladığı bitiş tanımı: **belirli gelişim hedefleri; dengeli üretim, orbital tesis, Ay kolonisi ve ilk gezegenler arası gemi**. Bütün yuvaları doldurmak veya bütün araştırmaları tamamlamak zorunlu değil. Aşağıdaki seviye ve süre değerleri bu onaylı çerçeve içindeki önerilerdir.

Ana gezegen seviyesi için geçici Act 1 hedefi Level 4. Bu önceki test kapsamıyla uyumludur, fakat kullanıcı tarafından kesin Act sınırı olarak belirlenmedi. Mevcut Level 5 ham T2 şartı çözülmeden daha yüksek seviye zorunlu tutulmamalı.

Onaylı Act 1 bitiş çerçevesinin önerilen ölçülebilir koşulları:

- Ana gezegen Level 4.
- Kredi, bilim ve T1 üretimi işliyor; zorunlu gelecek harcamalar için tekrar üretim mümkün.
- En az bir işleyen orbital district ve görevine uygun bina var.
- Ay üssü kurulmuş, Ay'a özgü bir tesis çalışıyor.
- Gezegenler arası araştırma ve sefer aracı hazır.
- Başka gezegene sefer gönderilince Act 2 başlıyor.

Haritayı açmak ile başka gezegene gidebilmek ayrı izinler olmalı. Ay'a gidebilmek için bütün güneş sistemini kolonileştirme yetkisi gerekmemeli. Yerel gezegen-yörünge-Ay görünümü Act 1 içinde kullanılabilir.

## 2. Önceki test raporunun düzeltilmesi

Önceki rapor normal oyuncunun baştan sona oynadığı bir koşuyu kanıtlamıyor:

- Test bazı bilim ve kredi miktarlarını elle yükseltti.
- Bina satın alma maliyetleri ve district kapasitesi gerçek arayüz akışıyla eksiksiz uygulanmadı.
- Gezegen yükseltmelerindeki mineral ödemeleri gerçek satın alma yoluyla doğrulanmadı.
- Orbital district tamamlanması gerçek animasyon yerine elle işaretlendi.
- Tutorial ödülleri ekonomik değerlendirmeye dahil edilmedi.

Özellikle University görevi 25 bilim verir; Mining Operations 20 bilimdir. Dolayısıyla rapordaki “Mining açılması 16,7 dakika” hesabı normal tutorial akışını temsil etmez. Yalnızca ödülsüz, tek University ve %25 enerji oranı varsayımının hesabıdır.

“1000 T1 yaklaşık 3,5 saat” de tek Mine ve tek Solar sabit tutularak yapılan sınırlı bir tahmindir. Yeni maden, ek enerji, district upgrade ve Deep Drill yatırımlarıyla normal ilerleme süresi değişir. Bu sayı Act 1 süresi değildir.

Capital kapasitesi konusunda arayüz mevcut yüzey POI sayısını kullanıyor (`PlanetaryView.gd`, `can_add_surface`). Eski `districts_used` alanının güncel olmaması, bu arayüzden fazladan district kurulabildiğini tek başına kanıtlamaz.

Yeni denge çalışmasının başlangıç verisi bu düzeltilmiş değerlendirme olmalı.

## 3. Act sınırını bozan mevcut bağlantılar

| Konu | Mevcut durum | Tasarıma etkisi | Yapılacak iş |
|---|---|---|---|
| Orbital araştırma | `unlock_space_station`, 300 bilim; `solar_unlocked=true` yapıyor | Yörünge ile güneş sistemi erişimi aynı anda açılıyor | Yörünge, Ay ve gezegenler arası seyahat izinlerini ayır |
| Ay araştırması | `unlock_moon`, 500 bilim, orbital araştırmanın çocuğu | Araştırma var, gerçek sefer zorunluluğuyla birleşmiyor | Araştırma + araç + varış + üs kurulumunu bağla |
| Kolonileştirme | 1000 kredi, 30 saniye; işlem gemi, varış veya araştırma kontrol etmiyor | Act 1'in tamamlanması zorunlu değil | Koşulları yalnızca düğmede değil, kolonileştirme işleminde doğrula |
| Gezegenler arası dal | Orbital 300 → Ay 500 → asteroid 1200 → kolonileştirme 2000 | Diğer gezegene açılmak için asteroid dalı önkoşul; toplam 4000 bilim | Asteroidleri Act 2 yan dalı yap; Act 1 finalini Ay gelişimine bağla |
| Spaceport | 500 kredi, 2 slot, başlangıçta kilitli; normal ağaçta `unlock_spaceport` yok | Roket sisteminin normal erişim yolu eksik | Orbital hazırlık aşamasında açık bir Spaceport araştırması tanımla |
| Orbital Shipyard | 10000 kredi; 50 refined girdi, 5000 kredi çıktı tanımı; `GeneratorLogic` bağlı | Tersane adı gemi üretimine karşılık gelmiyor; bağlı logic kredi de üretmiyor | Act 1 için gerçek araç üretim rolü tanımla veya binayı ileri oyuna taşı |
| İstasyon temsili | Orbital district bir POI; görev seçicisindeki istasyonlar `ShipData` gemilerinden seçiliyor | İnşa edilen district, gemi görevlerinin beklediği istasyon olmayabilir | Tek kimlik veya açık POI-gemi bağlantısı kur |

Kaynaklar: [SkillTree](C:/Users/drosm/Voidle/scripts/game/SkillTree.gd), [GameState](C:/Users/drosm/Voidle/scripts/game/GameState.gd), [PlanetaryView](C:/Users/drosm/Voidle/scripts/planetary/PlanetaryView.gd), [Spaceport](C:/Users/drosm/Voidle/resources/buildings/spaceport.tres), [Orbital Shipyard](C:/Users/drosm/Voidle/resources/buildings/orbital_shipyard.tres).

Bu bağlantılar düzelmeden yalnızca fiyatları azaltmak tutarlı bir Act 1 oluşturmaz.

## 4. Bilim geliştirmeleri: mevcut durum ve önerilen rol

Tablodaki maliyetler ilk satın alma maliyetidir. Başlangıçta açık düğümlerin bir sonraki seviyeleri ayrıca ücretlidir.

| Araştırma | Mevcut bilim bedeli | Act 1 kararı |
|---|---:|---|
| Residential, Solar, University başlangıç açılımları | Başlangıçta açık | Başlangıç çekirdeği; üst seviyeler üretime gerçekten yansıtılmalı |
| Mining Operations | 20 | İlk zorunlu araştırma; tutorial'ın 25 bilim ödülüyle açılabiliyor |
| Market Square | 30 | Erken gelir alternatifi; konutu tamamen geçersiz kılmamalı |
| Thermal Plant | 100 | Maden kullanan güçlü enerji seçeneği; yakıt rezerviyle birlikte öğretilmeli |
| Solar Arrays verimlilik | 50; Thermal Plant önkoşullu | Güneş enerjisi yolunu termik seçiminden bağımsızlaştır |
| Deep Drill | 200 | Ana gezegen sanayi aşamasının temel üretim sıçraması |
| Library | 150 | Birden fazla University bulunan district için isteğe bağlı uzmanlaşma |
| Educational Grants | 300 | Bilim yatırımı; seviye başına fayda açık ve gerçekten uygulanır olmalı |
| Advanced Research | 500; Grants önkoşullu | Mevcut -100 enerjiyle zorunlu tutulmamalı; enerji verimini yeniden ayarla |
| Refinery | 400; Deep Drill önkoşullu | Ürün dönüşümü düzeltilmeden zorunlu ilerleme yolu yapma |
| Housing bonusu → Apartments | 300 + 500 | İsteğe bağlı şehir uzmanlaşması; 800 bilime karşı faydası çok zayıf |
| Orbital Facilities | 300 | Bir kez alınan ana dönüm noktası; yüzey gelişim şartı ekle |
| Orbital Mirrors | 2000 | İlk orbital için pahalı; inşaat hatası giderilince yerel enerji seçeneği yap |
| Moon Outpost | 500 | İşleyen orbital altyapıdan sonra zorunlu aşama |
| Lunar Observatory | 1500 | Ay'da erişilebilirlik ve üretim düzeltildikten sonra araştırma uzmanlaşması |
| Helium-3 Extractor | 1500 | Ay'ın enerji uzmanlaşması; +500 enerji etkisini ölçekle |
| Orbital Shipyard | 1000 | Gerçek araç rolü verilirse final hazırlığı; mevcut haliyle zorunlu değil |
| Deep Space Tracking / asteroidler | 1200 | Act 2 yan dalına taşı |
| Planetary Colonization | 2000 | Ay hedefleri sonrası Act 1 final araştırması olarak yeniden bağla |
| Ice / Desert / Gas / Volcanic kolonileştirme | Her biri 2500 | Act 2 çevre uzmanlaşmaları |
| Interstellar Travel | 10000 | Sistem dışına geçiş; Act 1 dışında |

Mevcut Orbital Facilities 10 seviyeli, fakat ilk alımdan sonraki seviyeler aynı temel açılımı yeniden sağlamıyor. Tek seferlik erişim teknolojisi ile tekrarlanabilir verim araştırmasını ayırmak gerekir.

Mevcut parent kontrolü “ebeveynlerden herhangi biri” mantığında. Final teknolojisinde “orbital tesis VE işleyen Ay üssü” isteniyorsa bunu ayrıca ifade eden zorunlu koşullar gerekir. İki bağlantı çizmek tek başına iki şartı birden zorunlu yapmaz.

Önerilen ana dal:

```text
Temel koloni → Mining → Deep Drill / üretim gelişimi
                         ↓
                  Orbital mühendislik
                  + Spaceport erişimi
                         ↓
                Tamamlanmış orbital tesis
                         ↓
                   Ay sefer programı
                         ↓
                    İşleyen Ay üssü
                         ↓
              Gezegenler arası sefer teknolojisi
                         ↓
                 İlk dış gezegen seferi
```

Konut, pazar, kütüphane, solar verimlilik ve termik enerji bu ana dalı hızlandıran seçenekler olmalı. Hepsini tamamlamak zorunlu olursa bilim ağacı tercih sunan sistem olmaktan çıkar.

## 5. Binaların matematiksel değerlendirmesi

Tablodaki hızlar seviye 1, ek bonus yok ve enerji tam karşılanıyor varsayımındadır. Madenler için ana gezegenin yaklaşık 0,88284 hız çarpanı dahil edilmiştir. Enerji kapasitedir; “tick başına stoklanan enerji” değildir.

| Bina | Kredi | Slot | Enerji talebi / arzı | Gerçek temel hız veya etki | Değerlendirme |
|---|---:|---:|---:|---|---|
| Residential | 100 | 1 | -2 | 50/60 = 0,833 kredi/sn | Ucuz başlangıç geliri |
| Market Square | 200 | 1 | -2 | 15/10 = 1,5 kredi/sn | Aynı slot ve enerjide konuttan %80 fazla gelir; farkı esasen ilk fiyat ve unlock |
| Apartments | 250 | 1 | -4 | 150/120 = 1,25 kredi/sn | Pazar daha çok gelir üretirken yarı enerji kullanıyor; gelişmiş konutun rolü zayıf |
| University | 200 | 1 | -2 | 2/25 = 0,08 bilim/sn | Temel bilim birimi |
| Advanced Lab | 1500 | 1 | -100 | 25/75 = 0,333 bilim/sn | University'nin 4,17 katı bilim, 50 katı enerji; enerji başına 12 kat daha verimsiz |
| Library | 500 | 1 | -5 | Aynı district bilim çıktısına +%15 | Tek University ile +0,012 bilim/sn; erken yatırım olarak çok zayıf |
| Solar Array | 150 | 1 | +1 | Yakıtsız kapasite | Çok fazla slot istiyor; 3 tüketici binanın -6 ihtiyacına 6 Solar gerekiyor |
| Thermic Generator | 100 | 1 | +5 | R1 yakıtla 5 T1/30 sn | Ucuz ve güçlü; maden netini düşürüyor, yakıtsız kalma riski var |
| Mine | 150 | 1 | -2 | Yaklaşık 0,4905 ham/sn | Temel T1 üretimi |
| Deep Drill | 600 | 1 | -5 | Yaklaşık 1,648 ham/sn | 3,36 kat üretim, 2,5 kat enerji; anlamlı gelişim |
| Refinery | 800 | 1 | -8 | Tanım: 15 ham/15 sn → 3 ürün/15 sn | Mevcut dönüşüm ürünü kaydı sorunlu; nominal 0,2 ürün/sn güvenilir gerçek çıktı değil |
| Zero-G Nexus | 400 | 1 | -10 | Doğrudan bilim yok; gezegen çapında +%30 bilim buff'ı | Tanım 20/30 science vaat ediyor, logic yok; enerji açığında toplam bilimi azaltabilir |
| Orbital Mirrors | 500 | 2 | 0 | Amaç: gezegen solar kapasitesine +%15 | `tick_duration=0` nedeniyle inşaat işlemine erişemiyor |
| Lunar Observatory | 5000 | 1 | -20 | Tanım: 200/60 bilim/sn; logic yok | Üretim ve yerleşim yolu eksik |
| Lunar Helium-3 | 1000 | 2 | +500 | Yakıtsız, global enerji kapasitesi | Bir tesisten 500 Solar eşdeğeri; önceki enerji yatırımlarını aniden önemsizleştirir |

Kaynaklar: [bina tanımları](C:/Users/drosm/Voidle/resources/buildings), [ProductionManager](C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd), [CreditLogic](C:/Users/drosm/Voidle/scripts/game/logic/CreditLogic.gd), [ScienceLogic](C:/Users/drosm/Voidle/scripts/game/logic/ScienceLogic.gd).

### 5.1 Bilim binası kurmak bilimi azaltabiliyor

Örnek: 1 University, 1 Residential ve 1 Solar.

```text
Enerji oranı = 1 / (2 + 2) = 0,25
Bilim hızı = 0,08 × 0,25 = 0,02 bilim/sn
```

Mevcut Zero-G Nexus tamamlanınca:

```text
Yeni enerji oranı = 1 / (2 + 2 + 10) = 1/14
Yeni bilim hızı = 0,08 × 1,30 / 14 ≈ 0,00743 bilim/sn
```

Yani “bilimi artıran” bina, bu enerji yetersizliği örneğinde toplam bilimi yaklaşık %63 azaltır. Bu her kurulumda geçerli değildir; enerjisi yeterli kolonide +%30 buff çalışır. Bina önizlemesi net sonuç göstermeli ve gerekli enerji altyapısı orbital aşamadan önce erişilebilir olmalı.

### 5.2 Kütüphane hangi koşulda anlamlı?

Bonus ve enerji yetersizliği yokken aynı seviyedeki N University'ye Library eklemek 0,15 × N University eşdeğeri çıktı verir. Bir slot daha University kurmakla eşit çıktıya ulaşmak için N yaklaşık 6,67, yani en az 7 University gerekir. Library daha pahalı ve daha çok enerji de ister.

Bu yüzden +%15 mevcut haliyle ilk bilim uzmanlaşması için zayıftır. Çözüm yalnızca bonus artırmak değildir: daha düşük enerji, daha düşük maliyet, daha yüksek yoğunluk veya farklı bir işlev birlikte değerlendirilmeli.

### 5.3 Yakıt ve üretim bütçesi

Tam enerjide bir Mine yaklaşık 0,4905 ham/sn üretir. Bir R1 yakıtlı Generator yaklaşık 0,1667 ham/sn tüketir. Böyle bir çiftin toplam mineral neti yaklaşık 0,3238 ham/sn olur. Generator belirli bir mineral tükettiğinden bu kontrol kaynak türü bazında da yapılmalı.

Refinery nominal 1 ham/sn tüketir. Dolayısıyla tek Mine, tam hızda bir Refinery'yi sürekli besleyemez. R1 üretimi Mine başına yaklaşık 0,436 ham/sn olduğundan 2 Mine da R1 kullanan tam hızdaki Refinery için yetmez. Deep Drill bu sanayi zincirinde anlamlı bir basamaktır.

Yakıt harcayan üretim ile seviye yükseltmek için biriktirilen maden aynı stoktan çıktığından, maliyetleri brüt üretime göre değil kalan net üretime göre hesaplamak gerekir.

## 6. Ay ve kaynak zincirindeki eksikler

### Ay üssü

Kolonileştirme Ay üzerinde `OUTPOST` tipli Lunar Outpost oluşturuyor. Lunar Observatory ise `CITY` istiyor. City district tanımında Ay izinli değil. Normal yerleşim yolunda araştırma binasına ulaşmak için gerekli district bağlantısı bulunmuyor.

Öneri: Ay üssünün izin verilen bina listesini açık tanımla. İlk sürümde ayrı büyük bir bina ailesi yerine Outpost içine Lunar Observatory ve bir temel destek tesisi koymak yeterli olabilir. Helium-3 Mining district içinde kalabilir. Observatory'ye Ay kısıtı da eklenmeli; mevcut bina tanımı yalnızca Ay'a özel değil.

Ay yalnızca “+500 global enerji açılan yer” olmamalı. İki anlaşılır uzmanlaşma sunabilir:

- Araştırma üssü: bir sonraki teknolojiyi hızlandırır.
- Enerji üssü: ana gezegenin kapasitesini büyütür.

Act 1 bitişi için birini çalışır hale getirmek yeterli olabilir; ikincisi Act 2 öncesi isteğe bağlı yatırımdır. Böylece iki adet 1500 bilimlik araştırmayı zorunlu listeye koymayız.

### Tier ve rafineri kararı

Mevcut kaynak üreticisi doğal olarak yalnızca ham T1 kaynakları oluşturuyor. Refinery, aynı isimli bir üst tier refined kayıt arıyor; bu kayıt bulunmazsa çıktı kimliği ham girdide kalabiliyor. Bu yüzden “rafineri kurunca daha üst ürünümüz var” varsayımı geçersiz.

Önceki testin T1 sınırı ile yeni Act kapsamını ayırmak gerekir. Bu belge için en küçük öneri: Act 1 T1 ham mineral ve bundan üretilen temel işlenmiş malzemeyle sınırlı olsun. İşlenmiş malzemeye T1 refined mı T2 ürün mü deneceği mevcut kodda tutarsız; tek ürün tanımı ve açık tarif gerekir. Bu karar henüz uygulanmadı.

İki uygulanabilir seçenek:

1. En küçük Act 1: bütün zorunlu maliyetler T1 ham + kredi + bilim. Rafineri isteğe bağlı veya Act 2'ye ertelenir.
2. Sanayi odaklı Act 1: açık bir ham → işlenmiş malzeme tarifi; yörünge ve seferler bu malzemeyi kullanır.

Önerim ikinci seçenek, ancak yalnızca tek işlenmiş ürün basamağıyla. Daha derin malzeme zincirlerini Act 2'ye bırakmak Act 1'in öğrenme yükünü sınırlar.

## 7. District mantığı

Mevcut district sistemi tür, slot ve aynı district içindeki bina bonuslarını destekliyor. İncelenen üretim hesabında harita komşuluğuna dayalı bir bonus yok. Dolayısıyla Civilization 6 esini şu an daha çok alan tahsisi ve uzmanlaşma düzeyinde.

İlk denge çalışmasında öncelik:

- City: kredi mi bilim mi ağırlıklı olacak?
- Generator: yakıtsız ve çok slot kullanan yol mu, maden yakan yoğun yol mu?
- Mining: birikim için ham maden mi, işlenmiş ürün hattı mı?
- Orbital: bilim desteği mi, enerji desteği mi?
- Ay: araştırma üssü mü, enerji üssü mü?

Yeni komşuluk bonusu eklemeden bu seçimlerin ekonomik karşılığını kurmak gerekir. Slot başına ve enerji başına verimi aynı anda en yüksek tek bir bina varsa seçim alanı daralır.

District seviye 1'de 3 slot, her seviyede +2 slot veriyor. Level 4'te district başına 9 slot mümkün. Ana gezegen Level 4'te 5 yüzey district kapasitesi olduğundan teorik toplam 45 slot var; fakat hepsini geliştirmek kredi ister. Sadece başlangıçtaki 3 slot üzerinden bütün Act 1 kapasitesi hesaplanmamalı.

## 8. Dengeyi nasıl kuracağız?

Tam dengeli sonucu yalnızca tablo seçerek garanti edemeyiz. Önce hedef tempo, ardından üretim ve maliyetler, son olarak gerçek koşular gerekir.

### 8.1 İlk deneme için tempo önerisi

Bu süreler tasarım tercihi önerisidir; ölçülmüş sonuç veya onaylanmış hedef değildir. Aktif karar veren, gerektiğinde yatırımlarını büyüten oyuncunun oyun içi geçen süresini ifade eder. Çevrimdışı kazanım mevcut olmadığı için gerçek hayattaki geri dönüş aralıkları ayrıca değerlendirilmelidir.

| Aşama | Başlangıçtan itibaren aday hedef | Öğrenilecek karar |
|---|---|---|
| İlk ekonomi | 0-10 dakika | Enerji, kredi, bilim |
| Sanayi büyümesi | 10-35 dakika | Maden, district yükseltme, net üretim |
| Yörünge | 35-65 dakika | Gezegen çapında destek yatırımı |
| Ay üssü | 65-110 dakika | İlk dış üs ve uzmanlaşma |
| Act 2 hazırlığı | 110-150 dakika | Sefer bütçesi ve üretim rezervi |

Hedef daha uzun bir idle deneyimse tüm aşamalar aynı oranda uzatılmamalı. İlk oynanabilir kararlar hızlı tutulup daha sonraki büyüme hedefleri genişletilebilir.

### 8.2 Temel hesaplar

```text
Enerji oranı = min(1, toplam arz / toplam talep)
Gerçek üretim/sn = döngü çıktısı × hız çarpanları × enerji oranı / döngü süresi
Net kaynak/sn = brüt üretim/sn - yakıt/sn - tarif girdileri/sn
Kaynak bekleme süresi = max(0, hedef maliyet - mevcut stok) / net kaynak hızı
Birden fazla kaynak için yaklaşık bekleme = kaynak bekleme sürelerinin en büyüğü
Yatırımın geri ödeme süresi = maliyet / yatırımın eklediği net üretim
```

Hız sabit değilse bu formüller yalnızca yerel tahmindir; sonraki yatırımları ve kesintili yakıt döngülerini simülasyon hesaplamalı. Net kaynak hızı sıfır veya negatifse bekleme süresi sonlu bir sayı olarak gösterilmemeli.

Bilim fiyatını belirlemek için örnek: yörüngeye hazırlanırken oyuncunun gerçek net bilimi 0,5/sn ise 300 bilim 10 dakikalık bir hedef olur. Aynı 300 bilim 0,02/sn hızda 250 dakika ister. Bu yüzden “300 pahalı mı?” sorusu bina parkı ve enerji oranından bağımsız cevaplanamaz.

### 8.3 İlk sayısal deneme önerileri

- Solar Array çıktısını önce +2 ile dene. İki panel, Residential + University talebini karşılar; Mine eklemek yeni bir enerji kararı yaratır. Bu tek başına tamamlanmış denge değildir.
- University'yi başlangıç bilim ölçü birimi olarak tut; Advanced Lab'in enerji başına verimi University'nin çok altına düşmesin. Örneğin mevcut 25/75 çıktı korunursa -6 ile -8 enerji aralığı ilk deneme olabilir; -100 korunursa çıktı bambaşka ölçekte olmalı.
- Library'yi hedef district doluluğunda anlamlı yap. İlk uzmanlaşmanın 3-4 University civarında düşünülmesi isteniyorsa bonus, fiyat ve enerji birlikte yeniden seçilmeli.
- Zero-G Nexus'u gerçek bilim üreticisi + destek olarak tutacaksak eksik logic bağlanmalı. Mevcut 20/30 bilim, University'nin 8,33 katı olduğundan fiyatı ve erken erişimi tekrar ölçülmeli.
- Helium-3 için +500'ü doğrudan kabul etme. Ay'a ilk varışta mevcut toplam kapasitenin örneğin %30-60'ı kadar yeni enerji sağlayan bir aday değerle dene. Son değer hedef bina parkı çıkarılınca belirlenmeli; bu yüzde dinamik ölçekleme önerisi değildir.
- Level 3'ün 5 ham, Level 4'ün 1000 ham bedeli 200 kat sıçrıyor. Level 4 maliyetini o aşamadaki net maden hızında hedeflenen bekleme süresinden türet; örneğin 10 dakikalık hedef için `600 × net ham/sn`.
- Ana ilerleme teknolojileri tek seferlik olsun. Tekrarlı bilim seviyeleri yalnızca açıkça artan ve çalışan bir fayda için alınsın.

## 9. Uygulama sırası

### Paket 1: Hesapların doğruluğu

Önce fiyat ayarını geçersiz kılabilecek işlev hataları giderilmeli:

1. Bina seviye çarpanını gösterilen miktarla gerçek üretimde eşitle.
2. `tick_duration=0` olan destek binalarının inşaatını üretim döngüsünden bağımsız tamamla.
3. Nexus ve Observatory'nin üretim rolünü kesinleştir ve uygula.
4. Rafineri ürünü oluşturma ve kayıt zincirini düzelt.
5. Enerji sıfırken aynı üretim döngüsünün girdisinin tekrar tekrar tüketilmesini önle.
6. Yörünge inşaatının sahne değiştirme ve kayıt yüklemede devam etmesini doğrula.
7. Kayıt yüklemede kredi ve erişimlerin başlangıç değerlerine dönmesini gider; `_build_home_solar` başlangıç atamalarını yeni oyunla sınırla.

### Paket 2: Act 1'in erişim zinciri

1. Orbital, Ay ve gezegenler arası izinleri ayır.
2. Spaceport açılma yolunu ekle.
3. Ay üs tipini, bina yerleşimini ve sefer gereksinimlerini bağla.
4. Kolonileştirme işleminde araştırma, araç, varış ve maliyeti birlikte denetle.
5. Asteroid araştırmasını ilk dış gezegen seferinin zorunlu önkoşulundan çıkar.
6. Act 1 bitiş koşulunu kayıt dosyasında saklanan tek bir ilerleme durumu yap.

### Paket 3: Ekonomi ve bilim

1. Tutorial dahil ve tutorial atlanmış başlangıçları ayrı bütçele.
2. Enerji, bilim ve kredi bina ailelerini slot ve enerji başına karşılaştır.
3. Ana gezegen upgrade bedellerini net üretim hızlarından çıkar.
4. Orbital ve Ay araştırma maliyetlerini hedef aşama temposuna oturt.
5. Seferden sonra koloninin yeniden üretim yapabilmesi için yakıt ve kredi rezervlerini ölç.

### Paket 4: Gerçek ilerleme doğrulaması

Aşağıdaki koşullar gerçekleşmeden “Act 1 dengelendi” denmemeli:

- Sıfır kayıtla başlanır; kredi, bilim, mineral ve inşaat durumu elle tamamlanmaz.
- Tutorial ödülleri gerçek olaylardan yalnızca bir kez kazanılır.
- Bütün satın almalar maliyet, kapasite, seviye ve araştırma kontrolünden geçer.
- En az üç strateji denenir: solar ağırlıklı, termik ağırlıklı, bilim/gelir ağırlıklı.
- Bu stratejiler birden fazla başlangıç seed'i üzerinde denenir; zorunlu Ay kaynağı rastgele kaybolmamalı.
- Normal oyuncu hataları denenir: yanlış yatırımı durdurma, yakıtsız kalma, bilimden önce gelire yönelme. Geri dönülemez kilit olmamalı.
- Yörünge ve Ay seferi sırasında kayıt alınıp yüklenir, sahne değiştirilir.
- Act 1 bitmeden dış gezegen kolonileştirme işlemi reddedilir; bittikten sonra gerçek sefer başarıyla yapılır.
- Ekrandaki çıktı, stoğa eklenen çıktı ve tüketim aynı olmalıdır.
- Her aşama için geçen süre, aktif karar sayısı, kesintisiz bekleme, enerji oranı ve net kaynak hızı kaydedilir.

## 10. Öncelikli tasarım kararı

Önce birbirine bağlı şu üç işi tamamlamak en yüksek etkiyi sağlar:

1. Ana gezegen → orbital → Ay → diğer gezegen sırasını gerçekten zorunlu ve çalışır hale getirmek.
2. Bilim ve enerji bina ailelerinin gerçek çıktısını tutarlı yapmak.
3. Seçilen Act 1 süresine göre araştırma ve büyüme maliyetlerini hesaplamak.

Ana gezegendeki bütün yuvaları doldurmak, bütün bilimleri almak ve bütün bina seviyelerini yükseltmek ayrı hedeflerdir. Bunların hepsini Act 1 bitiş koşulu yapmak hem seçenekleri azaltır hem süreyi şişirir. Önerilen bitiş, gelişmiş ana gezegen ve işleyen orbital-Ay altyapısıyla ilk dış gezegen seferini mümkün kılmaktır.

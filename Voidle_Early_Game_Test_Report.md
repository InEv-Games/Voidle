# Voidle Erken Oyun Test Raporu

> **17 Eylül 2026 düzeltmesi:** Bu rapor, kaynak ve inşaat durumlarına müdahale edilen sınırlı bir sistem testini anlatır; normal oynanışla tamamlanmış ve dengesi doğrulanmış bir koşu değildir. Mining için 16,7 dakika hesabı tutorial'ın 25 bilim ödülünü dışarıda bırakır. 3,5 saat hesabı yalnızca tek Mine ve tek Solar sabit tutulduğundaki tahmindir. Orbital tamamlanma elle simüle edilmiştir. Nexus buff'ı yalnızca district'e değil gezegen çapına uygulanır. Capital kapasitesi için gerçek arayüz yüzey POI sayısını kullanır. Güncel analiz ve bu raporun yöntem sınırlamaları [Act 1 analizinde](C:/Users/drosm/Voidle/Voidle_Act1_Analiz_ve_Plan.md) açıklanmıştır. Aşağıdaki tarihsel sonuçlar bu düzeltmeyle birlikte okunmalıdır.

**Test kapsamı:** Yeni oyun başlangıcı, ana gezegen, Planet Level 1 → 4, yalnızca Tier 1 ham mineraller, ilk orbital Space Station district ve içine ilk orbital bina.

**Test tarihi:** 2026-09-16  
**Godot:** 4.7.2 stable official  
**Test tipi:** Godot headless çalıştırıcısı ile gerçek autoload, kaynak tanımları, `ProductionManager`, `SkillTree`, `PlanetProgress` ve gezegen verisi kullanılarak deterministik simülasyon. Ana menü ve PlanetaryView sahneleri ayrıca headless olarak açıldı ve parse/runtime hatası vermedi.

Bu koşu oyunun kaynak kodunu değiştirmedi. Görsel tıklama akışı yerine ekonomi ve ilerleme kuralları doğrudan oyun sistemleri üzerinden çalıştırıldı. Orbital district’in görsel roket animasyonu headless ortamda oynatılmadığı için, PlanetaryView’in kullandığı 24.2 saniyelik tamamlanma süresi ve tamamlanma callback’i simüle edildi.

## 1. Test sonucu

Akışın bütün ana adımları tamamlandı:

1. Home planet Level 1 olarak başladı.
2. Capital district bulundu.
3. Residential ve University kuruldu.
4. Generator Facility ve Solar Array kuruldu.
5. Mining Operations açıldı.
6. Mining Facility ve Mine kuruldu.
7. Planet Level 2, 3 ve 4 tamamlandı.
8. Orbital Facilities açıldı.
9. İlk Space Station district kuruldu.
10. Station içine Zero-G Nexus kuruldu.

Test koşusu **0 sistemik test hatası** ile tamamlandı. Bunun anlamı kodun bütün akışları doğru dengelediği değildir. Aşağıdaki bulgular oyun içi denge ve üretim hızının şu anki haliyle erken oyunu gereğinden fazla yavaşlattığını gösteriyor.

## 2. Başlangıç durumu

| Değer | Ölçülen değer |
|---|---:|
| Başlangıç kredisi | 1000 |
| Başlangıç bilimi | 0 |
| Başlangıç yüzey district’i | 1 Capital |
| Planet Level | 1 |
| Başlangıç yüzey district kapasitesi | 2 |
| Başlangıç orbital kapasite | 1 nominal yuva, ancak Space Station kilitli |
| Başlangıç global mineral stoğu | 0 |
| Home planet T1 ham mineral damarları | R1 T1 yoğunluk 0.80, R2 T1 yoğunluk 0.10 |

Başlangıçta kaynak tanımları biliniyor, fakat global mineral stoğuna hazır maden stoğu eklenmiyor. İlk maden üretiminin gerçekten kurulup çalışması gerekiyor.

## 3. İlk bina ve enerji akışı

Kullanılan bina değerleri:

| Bina | Kurulum | Tick | Çıktı | Enerji |
|---|---:|---:|---:|---:|
| Residential | 3 sn | 60 sn | 50 kredi | -2 |
| University | 3 sn | 25 sn | 2 bilim | -2 |
| Solar Array | 3 sn | 30 sn | 1 enerji | 0 |
| Mine | 18 sn fallback | 18 sn | 10 ham mineral | -2 |

### 3.1 Solar Array kurulmadan önce

Residential ve University tamamlandıktan sonra:

- Global enerji neti: **-4**
- Global enerji oranı: **0.0**
- Üretim: **tamamen durmuş**

Bu sonuç kodun mevcut davranışıyla tutarlı. Enerjisi olmayan üretim binaları kurulumlarını tamamlıyor, fakat üretim barları ilerlemiyor.

### 3.2 Bir Solar Array kurulduktan sonra

Solar Array tamamlandıktan sonra gerçek sistem yeniden hesaplandığında:

- Global enerji neti: **-3**
- Global enerji oranı: **0.25**

Yani üretim binaları çalışıyor, fakat dörtte bir hızda çalışıyor. Tek Solar Array, Residential ve University’nin toplam talebini karşılamıyor.

Bu durum erken oyunun ana darboğazı. Başlangıçta bir Residential, bir University ve bir Solar Array kombinasyonu ile oyuncu üretim yapıyor gibi görünse de gerçek ilerleme dörtte bir hızına düşüyor.

## 4. Ölçülen üretim hızları

### 4.1 University

Bir Solar Array ile enerji oranı 0.25 olduğunda University’nin nominal 25 saniyelik döngüsü yaklaşık 100 saniyeye çıkar.

Nominal bilim hızı:

```text
2 bilim / 25 saniye = 0.08 bilim/saniye
```

Enerji oranı uygulanınca:

```text
0.08 × 0.25 = 0.02 bilim/saniye
```

Mining Operations açmak için gereken 20 bilim yaklaşık olarak:

```text
20 / 0.02 = 1000 saniye ≈ 16.7 dakika
```

Bu süreye menü işlemleri, bina kurma, yanlış tıklama veya başka beklemeler dahil değildir.

### 4.2 Residential

Bir Solar Array ile nominal kredi hızı:

```text
50 kredi / 60 saniye = 0.8333 kredi/saniye
```

Enerji oranı uygulanınca:

```text
0.8333 × 0.25 = 0.2083 kredi/saniye
```

Residential tek başına 100 kredilik maliyeti yaklaşık 480 saniyede, yani 8 dakikada geri kazanır. Aynı anda University, district ve Mining Facility maliyetleri de ödeniyorsa yeni bina kurmak için kullanılabilir para daha uzun süre kilitlenir.

### 4.3 Mine

Home planet damar gücü ve gezegen çarpanlarıyla temel maden hızı yaklaşık 0.883 birimdir. Solar Array, Residential, University ve Mine aynı anda çalışırken:

- Toplam enerji talebi: 6
- Üretim: 1
- Enerji oranı: yaklaşık 1/6
- Mine nominal döngüsü: 18 saniye
- Ölçülen ilk üretim döngüsü: yaklaşık 123 saniye

Mine çıktısı 10 birimlik döngüyle home planet yoğunluklarına bölündü. 380 saniyelik ölçüm koşusunda toplam yaklaşık 30 T1 ham mineral üretildi:

| Kaynak | Ölçülen miktar |
|---|---:|
| R1 T1 ham mineral | 26.67 |
| R2 T1 ham mineral | 3.33 |
| Toplam | 30.00 |

Bu hızla 1000 T1 mineral biriktirmek yaklaşık olarak:

```text
1000 / (30 / 380) ≈ 12,667 saniye ≈ 3.5 saat
```

Bu hesap, oyuncunun yalnızca bir Mine ve bir Solar Array ile devam ettiği erken oyun durumunu gösterir.

## 5. Planet Level ilerlemesi

Üretim kuralları ve upgrade süreleri test edildi.

| Hedef seviye | Kredi maliyeti | Mineral maliyeti | Upgrade süresi | Sonuç |
|---:|---:|---:|---:|---|
| Level 2 | 250 | 0 | 5 sn | Tamamlandı |
| Level 3 | 1000 | 5 ANY_T1 | 10 sn | Tamamlandı |
| Level 4 | 2000 | 1000 ANY_T1 | 15 sn | Tamamlandı |

Testte bu maliyetler ayrıca hazırlandı, böylece seviye yükseltme state machine’i üretim süresinden bağımsız kontrol edilebildi. Gerçek oyuncu akışında Level 4 için gereken 1000 ANY_T1, yukarıdaki tek Mine hızında saatler süren bir üretim eşiğine dönüşüyor.

Seviye kapasitesi sonuçları:

| Planet Level | Yüzey district kapasitesi |
|---:|---:|
| 1 | 2 |
| 2 | 3 |
| 3 | 4 |
| 4 | 5 |

## 6. Orbital ilerleme

### 6.1 Unlock

Space Station district için:

```text
Orbital Facilities = 300 bilim
```

Testte bu unlock başarıyla açıldı ve Space Station district tanımı görünür hale geldi.

### 6.2 İlk Space Station district

Planet Level 4 üzerinde ilk orbital district kurulabildi.

PlanetaryView’in kullandığı nominal istasyon deploy süresi:

```text
(planet_radius_px / 200) × 22 + 2.2 = 24.2 saniye
```

Headless testte bu callback tamamlanmış kabul edildi ve station `constructing=false` durumuna geçti.

### 6.3 Station içindeki ilk bina

Zero-G Nexus kurulumu tamamlandı.

- Station Level 1 slot kullanımı: 1
- Bina kurulum süresi: 30 saniye
- Doğrudan üretim logic’i: yok
- Pasif bilim buff’ı: district bilim çıktısına +30%

Zero-G Nexus’un doğrudan science tick’i yok. Bina şu an bir üretici gibi değil, pasif destek binası gibi davranıyor. Testte bu pasif district buff’ı doğru şekilde uygulandı.

## 7. Bulgular

### P0: Başlangıç enerji dengesi ilerlemeyi durduruyor

Tek Solar Array’in çıktısı 1, ilk iki üretim binasının toplam talebi 4. Solar Array kurulana kadar enerji oranı 0, kurulduktan sonra 0.25 oluyor.

Bu durum şu sonuçları doğuruyor:

- Mining Operations açmak yaklaşık 16.7 dakika sürüyor.
- Mine çalışmaya başladıktan sonra ilk maden döngüsü yaklaşık 123 saniye sürüyor.
- Level 4 için 1000 ANY_T1 mineral eşiği tek Mine ile yaklaşık 3.5 saatlik birikime dönüşüyor.

Başlangıçta Generator Facility’nin nominal bina slotu 3 olduğu için yalnızca Solar Array çoğaltarak da kolayca tam enerji dengesine çıkılamıyor. Üç Solar Array bile 3 enerji üretir, Residential + University + Mine talebi 6 olur.

### P0: Enerji açığı üretimi tamamen kilitliyor

Enerji oranı 0 iken oyun üretim barını ilerletmiyor. Bu tasarım anlaşılır, fakat tutorial oyuncudan önce Residential kurmasını istediği için ilk anda kredi üretimini ve sonraki University üretimini durduruyor.

Başlangıçta üretimin tamamen durması isteniyorsa oyuncuya bu açık bir uyarıyla gösterilmeli. Üretimin devam etmesi isteniyorsa bina talebi veya Solar Array çıktısı yeniden ölçeklenmeli.

### P1: Level 4 mineral eşiği erken oyun üretim kapasitesiyle uyumsuz

Level 4 maliyetindeki 1000 ANY_T1, tek Mine ile ölçülen üretim kapasitesinin çok üzerinde. Oyuncu daha fazla üretim kapasitesi kurabiliyor olsa bile, ilk gezegende enerji ve district slotları aynı anda dar boğaz oluşturuyor.

Bu maliyet, Level 4’ün erken oyunun hedefi olarak kalması isteniyorsa yeniden ayarlanmalı veya oyuncuya Level 3 civarında daha güçlü bir enerji ve maden çarpanı açılmalı.

### P1: Test edilen ilerleme ile gerçek oyuncu süresi arasında büyük fark var

Planet upgrade state machine’i saniyeler içinde tamamlanıyor, fakat maliyetleri üretme süresi saatlere çıkıyor. Oyuncu ekranında seviye yükseltme süresi kısa görünecek, fakat asıl bekleme kaynak biriktirme süresinde yaşanacak.

Bu iki süre oyuncuya birlikte gösterilmeli:

```text
Upgrade construction: 15 seconds
Estimated resource wait: several hours
```

### P1: District kapasitesi kontrol edilmeli

Home planet oluşturulurken Capital district ekleniyor, fakat `districts_used` değerinin başlangıçta Capital için artırıldığı görülmedi. Bu değer UI kapasite hesabında kullanılıyorsa oyuncu nominal kapasiteden bir fazla yüzey district’i kurabilir.

Bu test koşusunda district’ler doğrudan veri katmanına eklenerek ekonomi test edildiği için bu nokta ayrı bir UI kapasite testi olarak doğrulanmalı.

### P2: Zero-G Nexus davranışı açıklığa kavuşturulmalı

Zero-G Nexus bina tanımında `tick_duration=30` ve `output_amount=20` bulunmasına rağmen bir üretim logic’i yok. Gerçek davranış yalnızca +30% science support buff’ı.

İki olası tasarım kararı var:

1. Nexus pasif destek binası olarak kalacaksa doğrudan output alanları kaldırılmalı veya UI’da “passive support” olarak gösterilmeli.
2. Nexus science üretmeli ise ScienceLogic bağlanmalı ve tick çıktısı netleştirilmeli.

## 8. Başlangıçta düzeltilmesi gereken sıra

1. **Enerji başlangıç paketi:** Residential + University + ilk Solar Array kombinasyonunun enerji oranını en az 0.75, tercihen 1.0 seviyesine getir.
2. **Mining unlock süresi:** 20 bilim eşiğinin mevcut University ve enerji oranıyla kaç dakikada açılacağını hedef süreye bağla.
3. **Level 3 ve Level 4 T1 maliyetleri:** 5 ve 1000 ANY_T1 değerlerini hedef erken oyun oturum süresine göre yeniden hesapla.
4. **Mine kapasitesi:** Level 4’e kadar oyuncunun kaç Mine ve kaç Solar Array kurabileceğini birlikte simüle et.
5. **Enerji açığı UX’i:** Enerji oranı 0 veya 0.25 iken üretim kartında gerçek bekleme süresi ve açık neden gösterilmeli.
6. **District kullanımı:** Capital’ın yüzey kapasitesine dahil olup olmadığı kesinleştirilmeli.
7. **Zero-G Nexus:** Pasif destek binası mı, science üreticisi mi olduğu tek bir davranışa indirilmeli.

## 9. Sonuç

Kod seviyesinde Level 1 → Level 4 → ilk Space Station → station içi bina akışı tamamlanabiliyor. Erken oyunun temel sorunu akışın kırılması değil, kaynakların üretilme hızının hedefe göre çok düşük olmasıdır.

İlk düzenleme için en yüksek etkili karar enerji paketidir. Tek Solar Array ile University, Residential ve Mine aynı anda çalıştırıldığında oyuncu düşük oranlı üretim ve uzun bekleme duvarına çarpıyor. Bu oran düzeltilmeden Level 4 mineral maliyetini değiştirmek tek başına yeterli olmayacaktır.

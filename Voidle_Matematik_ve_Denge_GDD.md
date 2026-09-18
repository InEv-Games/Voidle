# Voidle: Matematik, Ekonomi ve İlerleme GDD'si

İnceleme tarihi: 16 Eylül 2026  
Kapsam: mevcut proje kaynaklarının statik incelemesi. Oyun kodu ve denge değerleri değiştirilmemiştir.  
Amaç: incremental idle uzay kolonizasyonunun çalışan kurallarını, bütün bina ve araştırma sayılarını ve dengeyi bozan uygulama farklarını birlikte düzenlenebilir tek belgede toplamak.

## İçindekiler

1. Kapsam, kanıt düzeyi ve mevcut oyun döngüsü
2. Başlangıç ekonomisi ve öğretici ödülleri
3. District ve gezegen gelişimi
4. Kaynaklar, ürün zinciri ve rastgelelik
5. Üretim matematiği
6. Enerji matematiği
7. Destek binaları ve etkileşimler
8. Bina kataloğu: 76 tanım
9. Araştırma kuralları ve 119 düğümlük katalog
10. Keşif, kolonizasyon ve evren ölçeği
11. Gemi ve görev sisteminin mevcut durumu
12. Kayıt, zaman ve idle davranışı
13. Sayısal denge karşılaştırmaları
14. Sorun listesi ve düzeltme öncelikleri
15. Denge çalışması için karar tablosu
16. Başarı eşikleri ve kaynak envanteri

## 1. Kapsam, kanıt düzeyi ve mevcut oyun döngüsü

### 1.1. Belge nasıl okunmalı?

- **Uygulanan:** normal oyun yolunda çağrılan koddan çıkarılan davranış.
- **Tanımlı:** kaynak dosyasında sayı veya açıklama var; bu tek başına mekanizmanın çalıştığı anlamına gelmez.
- **Bağlantısı eksik:** tanım var fakat açılma, üretim veya uygulama yolu eksik.
- **Hesaplanan:** kaynak formüllerinden türetilen sonuç. Belirtilen enerji, seviye ve bonus varsayımlarına bağlıdır.
- **Çalıştırılarak doğrulanmalı:** statik incelemede belirlenen riskin sahne veya motor koşullarındaki sonucu ayrıca ölçülmelidir.

Bu çalışma oyun oynanarak yapılan süre ölçümü değildir. Komut ortamında Godot çalıştırıcısı bulunmadığından motor içinde test yapılmadı. Sayılar kaynaklardan çıkarıldı; tabloların kapsamı ve aritmetiği ayrıca kontrol edildi. Duygusal hedefler, hikâye, pazarlama ve görsel kimlik kapsam dışıdır.

Eski `Voidle_Simulation_Legacy_GDD.md`, yerel depo ve zorunlu taşımacılık dönemini anlatıyor. Bugünkü üretim global envanter ve global enerji kullanıyor. Eski belgedeki tasarım, mevcut davranış olarak aktarılmadı. Kök dizindeki üretim/yama Python dosyaları da çalışma zamanı kuralı değil; son üretilmiş `.gd` ve `.tres` değerleri esas alındı.

### 1.2. Mevcut temel döngü

```text
Başlangıç kolonisi
  → kredi üreten bina + enerji altyapısı
  → bilim üretimi
  → bilimle teknoloji açma
  → yeni district / bina / üretim kapasitesi
  → mineral çıkarma ve amaçlanan işleme zinciri
  → kredi + mineral ile gezegen seviyesi
  → daha çok district ve bina alanı
  → yörünge / ay / asteroit / başka sistemler
  → ortak ekonomiye yeni koloniler ekleme
```

Üretim bütün kolonilerde birlikte işler. Yeni koloni kendi enerji santralini kurmadan diğer kolonilerin enerjisinden yararlanabilir. Mineralin bir gezegenden diğerine kullanılabilmesi için gemi veya nakliye beklenmez. Kredi ve bilim de ortaktır.

Mevcut kaynaklarda nüfusun sayısal büyümesi, işçi atama, gıda ihtiyacı, mutluluk, düşman imparatorluk, savaş, diplomasi, fetih muharebesi, prestige/reset çarpanı, birden fazla galaksiye geçiş veya bitiş/zafer koşulu uygulanmış değil. “Uzay fetih” bağlamındaki mevcut genişleme, ekonomik kolonizasyondur.

### 1.3. Civilization 6 benzetmesinin mevcut karşılığı

District, belirli bina türlerini barındıran sınırlı bir kapasite alanıdır. Gerçek stratejik seçimler district türü, aynı türden kaç tane kurulacağı, bina slotlarının kullanımı ve destek/üretici dağılımıdır.

Hex harita, komşuluk bonusu, tile verimi, araziye göre üretim veya mesafeye bağlı district etkileşimi yok. Destekler aynı district etiketi içindeki bütün uygun binaları etkiler. “Range” yazan araştırmaların çalışan bir etki yarıçapı hesabı yoktur. Konum bulma büyük ölçüde görseldir.

## 2. Başlangıç ekonomisi ve öğretici ödülleri

### 2.1. Yeni oyun

| Değer | Mevcut başlangıç |
|---|---:|
| Kredi | 1000 |
| Bilim | 0 |
| Mineral stoku | 0 |
| Ana gezegen | Garantili Terran |
| Ana gezegen seviyesi | 1 |
| Kolonize durumu | Evet |
| Başlangıç district'i | Capital, City türünde |
| Capital bina slotu | 3 |
| Başlangıç binaları | Yok |
| Yüzey district üst sınırı | 2 |
| Yörünge kapasitesi | 1, kullanımı teknolojiye bağlı |
| Açık araştırmalar | root, unlock_solar_panel, unlock_residential, unlock_lab |
| Bu üç başlangıç araştırmasının seviyesi | 1 |
| Solar / Galaxy erişimi | Kapalı |
| Ana gezegen uydusu | Tam olarak 1 |
| Ana gezegen seed'i | 1000 ile 99999 arasında rastgele |

`credits = 500` alan varsayılanı gerçek yeni oyun bakiyesi değildir: dünya kurulurken `start_credits = 1000` atanır. Bu atamanın kayıt yüklemede de çalışması ayrıca sorun listesinde ele alındı.

### 2.2. Öğretici ekonomisi

| Sıra | İstenen eylem | Kredi ödülü | Bilim ödülü |
|---|---|---:|---:|
| 1 | Residential kur | 250 | 0 |
| 2 | Generator Facility ve Solar Array kur | 300 | 0 |
| 3 | University kur | 0 | 25 |
| 4 | unlock_mining satın al | 500 | 0 |
| 5 | Gezegen seviyesini artır | 300 | 0 |
| 6 | Bir district seviyesini artır | 400 | 10 |
| 7 | Ek Solar Array hedefi | 500 | 5 |
| 8 | Mine kur | 400 | 0 |
| Toplam | Bütün hedefler | 2650 | 40 |

İlk altı hedefin toplamı 1750 kredi ve 35 bilimdir. Yönlendirmeli öğretici bitince görev dizini 6'ya alınır; aynı ilk altı ödül normal akışta iki kez sayılmamalıdır. Son iki hedefin toplamı 900 kredi ve 5 bilimdir.

Opsiyonel görev panelini atlamak 30 adet R3/T1 ham mineral verir. İlk oyundan sonra `SettingsManager.tutorial_ever_done` yönlendirmeli kısmın atlanmasını etkiler. Dolayısıyla “ilk oyun” ve “öğreticiyi daha önce bitirmiş oyuncu” ekonomik başlangıçları aynı deneyim değildir.

İlk Residential 100 kredi/3 saniye, ilk enerji district'i 300 kredi/15 saniye nominal, ilk Solar Array 150 kredi/3 saniye, University 200 kredi/3 saniyedir. Bunların toplam ilk yatırımı 750 kredidir. Görev ödülleri bu maliyeti büyük ölçüde finanse eder.

**Önemli:** tek Solar Array yalnızca 1 enerji üretir. Residential 2 ve University 2 enerji ister. İkisi açıkken kapsama 1/4 olur. Öğretici enerji açığı olan bir ekonomiyi normal başlangıç olarak oluşturur.

## 3. District ve gezegen gelişimi

### 3.1. District türleri

| Tür | Temel kredi maliyeti | Nominal inşaat | Gezegen izni | Açılma |
|---|---:|---:|---|---|
| City | 500 | 15 s | Terran, Arid, Volcanic, Gas Giant | Başlangıç |
| Generator Facility | 300 | 15 s | Bütün türler | Başlangıç |
| Mining Facility | 250 | 15 s | Bütün türler | unlock_mining |
| Space Station | 800 | 30 s tanımı | Bütün türler | unlock_space_station |

District kataloglarındaki `building_ids` dizisi aktif bina seçim filtresi değildir. Gerçek filtre bina tanımının POI türü, gezegen türü, minimum gezegen seviyesi ve açılma durumudur. Generator listesindeki `power_plant` için bina dosyası bulunmuyor.

Yeni City kurulamayan Ice/Barren gezegenlerine kolonizasyon tamamlanırken yine ücretsiz City verilir. Moon ücretsiz Outpost alır. Bu başlangıç yerleşimi district kataloğunun gezegen filtresinden geçmez.

### 3.2. Aynı tür district maliyeti

```text
Yeni district maliyeti = temel_maliyet × 2^n
n = aynı gezegende mevcut aynı POI türündeki district sayısı
```

İnşaatı devam edenler de sayılır. Ücretsiz Capital bir City olduğu için ana gezegene eklenen ilk yeni City 1000 kredidir; 500 değildir.

| Yeni satın alınan aynı türün sırası, başlangıçta hiç yoksa | City | Generator | Mining | Station |
|---|---:|---:|---:|---:|
| 1 | 500 | 300 | 250 | 800 |
| 2 | 1000 | 600 | 500 | 1600 |
| 3 | 2000 | 1200 | 1000 | 3200 |
| 4 | 4000 | 2400 | 2000 | 6400 |
| 5 | 8000 | 4800 | 4000 | 12800 |

Başlangıçta n tane varken k yeni district toplamı: `B × 2^n × (2^k - 1)`. Bu yalnız fiyat eğrisidir; kapasite izin vermiyorsa satın alınamaz.

### 3.3. Gezegen ve district kapasitesi

```text
Yüzey district kapasitesi = gezegen_seviyesi + 1
Yörünge district kapasitesi = ceil(gezegen_seviyesi / 5)
District bina slotu = 3 + 2 × (district_seviyesi - 1)
District seviyesi ≤ gezegen seviyesi
Kullanılan slot = Σ(bina.slot_cost × bina.adet)
```

Tamamlanmamış binalar da slot tüketir. District seviyesi doğrudan üretim çarpanı vermez; slot açar.

`cryo_vault` tamamlanmışsa kapasite yeniden hesaplamasında +2 yüzey district öngörülür. `planetary_architecture` için +skill seviyesi yolu vardır; ancak bu yol `Engine.has_singleton("SceneTree")` kontrolüne bağlıdır. SceneTree bir motor döngüsü nesnesidir; bu kontrolün standart koşullarda false kalması beklenir. Motor testi gerekli. Ayrıca araştırma satın almak tek başına mevcut kolonilerin kapasitesini yeniden hesaplamıyor.

PlanetModifier içindeki Terran +2, Volcanic -2 vb. district etkileri kapasiteye bağlanmamış. `POIData.max_building_slots()` içindeki başka formül de aktif bina slotu hesabı değil.

`max_mining_lv = L`, `max_generators = 2L`, `max_spaceports = 1 if L>=2 else 0` alanları tanımlı; normal bina satın alma bu sınırları kullanmıyor. Aktif bina limiti araştırma kaynaklı seviyedir.

### 3.4. Gezegen yükseltme maliyetleri

Hedef seviye N için:

- N=2: 250 kredi.
- N=3: 1000 kredi + 5 ANY_T1.
- N≥4: 500N kredi + 250N ANY_T1.
- N>4 ise ayrıca 50(N-4) ANY_T2.
- Süre: `5 × mevcut_seviye` saniye. Kaynaktaki 60 saniyelik varsayılan aktif satın alma yolunda üzerine yazılır.
- Malzemeler başlangıçta ödenir. Üretim yükseltme sırasında devam eder.
- Kodda gezegen seviyesi için açık bir azami sınır yok.

| Hedef N | Kredi | ANY_T1 | ANY_T2 | Süre s | Yüzey / yörünge kapasitesi |
|---|---:|---:|---:|---:|---|
| 2 | 250 | 0 | 0 | 5 | 3 / 1 |
| 3 | 1000 | 5 | 0 | 10 | 4 / 1 |
| 4 | 2000 | 1000 | 0 | 15 | 5 / 1 |
| 5 | 2500 | 1250 | 50 | 20 | 6 / 1 |
| 6 | 3000 | 1500 | 100 | 25 | 7 / 2 |
| 7 | 3500 | 1750 | 150 | 30 | 8 / 2 |
| 8 | 4000 | 2000 | 200 | 35 | 9 / 2 |
| 9 | 4500 | 2250 | 250 | 40 | 10 / 2 |
| 10 | 5000 | 2500 | 300 | 45 | 11 / 2 |
| 11 | 5500 | 2750 | 350 | 50 | 12 / 3 |

ANY_TN mevcut kodda **RAW_MINERAL etiketli ve tier=N** kaynakları toplar. En düşük rarity önce harcanır. İşlenmiş T2 malzeme bu filtreye girmez. Normal kaynak üretimi yalnız ham T1 oluşturduğu için L5 ve sonrası malzeme kapısı mevcut zincirde karşılanamaz.

Arayüz yükseltme ödülünü “+2 Max Districts” diye yazıyor, gerçek artış +1.

### 3.5. District yükseltmesi ve yerleşim

```text
d → d+1 fiyatı = 500d kredi
Süre = 5(d+1) saniye
1 → D toplam fiyatı = 250D(D-1)
Kazanç = +2 slot
```

D=1,2,3,4,5 için slotlar 3,5,7,9,11; toplam yükseltme maliyetleri 0,500,1500,3000,5000 kredidir.

Yüzey district inşaatı hem ProductionManager hem görünür district ilerleme çubuğu olan PlanetaryView tarafından artırılabilir. İki yol birlikte çalışırsa 15 saniyelik district yaklaşık 7,5 saniyede biter; başka ekranda nominal süreye döner. Bu bir denge kuralı değil, çift zaman ilerletme sorunudur.

Yörünge district'inde nominal 30 saniye yerine `22 × ekran_planet_yarıçapı/200 + 2.2` saniyelik animasyon kullanılır. ProductionManager yörünge inşaatını atlar. Dolayısıyla süre pencere/geometriden etkilenebilir ve gezegenden ayrılınca animasyon ilerlemesi kaybolabilir.

LocationFinder 8 denemeye kadar, boylamda 38° yakınlığı önlemeye çalışır; her denemede +52° kaydırır. Bu kapasite veya üretim hesabı değildir. Kaynak district dosyalarında placement=1, enum'da SEA anlamına gelir. Arazi tercihi açıklamalarından bağımsız bu fiili eşleme korunmuştur.

## 4. Kaynaklar, ürün zinciri ve rastgelelik

### 4.1. Kaynak kimliği

`R{rarity}_T{tier}_{tag}` kimliği bütün evrende ortaktır. Örneğin `R1_T1_RAW_MINERAL` farklı gezegenlerde aynı stok kalemidir.

- Rarity: madenin nadirlik sınıfı.
- Tier: işlenme aşaması.
- T1 Ore, T2 Ingot, T3 Alloy, T4 Component, T5 Core.
- Tag: RAW_MINERAL, REFINED_MINERAL, ENERGY, CREDITS, GAS, FOOD, EXOTIC.
- Son üçü tanımlı etiketlerdir; çalışan gıda/gaz/egzotik üretim ekonomisi bulunmuyor. Atmospheric Siphon GAS değil RAW_MINERAL üretimi olarak tanımlı.
- Kredi/bilim ayrı sayısal bakiyelerdir. Enerji biriken stok değil, sürekli kapasitedir.

```text
power(R,T) = sqrt(R) + sqrt(T)
base_value = power × etiket_katsayısı
stack_size(T) = max(20, 100 - 15(T-1))
```

Etiket katsayıları: ham 1, işlenmiş 3.5, enerji 8, gaz 2, gıda 1.5, egzotik 25, diğer 1. T1..T5 stack_size: 100,85,70,55,40. Mevcut global depoda bunlarla uygulanan bir stok üst sınırı yok. `base_value` aktif otomatik satış fiyatı değildir; ticaret binalarının sabit çıktı tarifeleri kullanılır.

Örnek R1/T1 power=2, ham değer=2. R4/T1 power=3. R4/T2 power≈3.414214, işlenmiş değer≈11.949747. Bunlar tanımlı değerlerdir, doğrudan kazanılan kredi değildir.

### 4.2. Gövdedeki maden havuzu

Türün temel rarity tavanı:
- Terran, Moon, Gas Giant: 2.
- Asteroid: 4.
- Arid, Ice, Volcanic, Barren: 3.

Ana sistemden en kısa bağlantı uzaklığı h için:

```text
r_min = 1 + h
r_max = min(8, temel_tavan + h + min(h,1))
```

BodyResources içindeki Asteroid minimum 2 tanımı bu çağrıda kullanılmaz; ana sistemde asteroid havuzu R1'den başlayabilir.

Aralıktaki en düşük rarity kesin eklenir. Her üst rarity ayrı %65 eşikle eklenir. n olası rarity varsa beklenen maden çeşidi `1+0.65(n-1)`. Bu, her üretim çevriminde yeniden zar atılması değildir; dünya seed'inden bir kez belirlenmiş yataktır.

h≥8 olduğunda alt sınır 9 veya üstü, tavan ise 8 olabilir. Aralık boş kalırsa garanti mekanizması r_min madeni oluşturur. Böylece “R8 tavanı” fiilen aşılabilir.

### 4.3. Yoğunluk ve üretim payı

```text
w_i = 2.5^(-(R_i-r_min)) × U(0.8,1.2)
d_i = (w_i / Σw) × gezegen_yoğunluğu × U(0.9,1.1)
Üretim payı_i = d_i / Σd
```

U(a,b) ilgili seed akışından a ile b arasındaki rastgele sayıdır. Yoğunluğun bütün madenleri aynı oranda artıran kısmı normalizasyonda sadeleşir. Daha yüksek toplam deposit_density, tek başına daha çok toplam cevher üretmez. Madencilik hızı da yoğunluğu değil ortalama resource power'ını okur.

Ana gezegen R1 ve R2'yi garanti eder; yoğunlukları 0.80 ve 0.10'dur. Sonuç: toplam üretimin 8/9'u R1, 1/9'u R2. “%80 ve %10” gösterimi toplam stok veriminin %90 olduğu anlamına gelmez.

Normal tür üretimindeki yoğunluk aralıkları: Terran 0.7..1.2, Arid 0.7..1.3, Ice 0.5..1, Volcanic 1..1.8, Barren 0.6..1.2, Moon 0.8..1.4, Asteroid 1.2..2, diğer 1. Ancak solar ayları `make_moon()` ile üretilir ve burada yoğunluk varsayılan 1 olarak kalır. Asteroid sahnesi türü sonradan değiştirdiğinden asteroid aralığı da her ziyaret yolunda garanti değildir.

### 4.4. İşleme zincirinin mevcut kopukluğu

Amaçlanan zincir T1 → T2 → T3 → T4 → T5 olarak tarif edilmiş. Fakat:

1. BodyResources.generate yalnız RAW_MINERAL/T1 oluşturuyor.
2. RefineryLogic, yerel havuzda aynı mineral adı ve tier+1 olan REFINED_MINERAL arıyor.
3. Böyle bir kayıt üretilmediği için bulamazsa girdi kimliğini değiştirmeden aynı kaynağı geri ekliyor.
4. Standart Refinery normal şartta 15 ham tüketip 3 aynı ham geri verir; gerçek T2 oluşturmaz.
5. Üst rafineriler RAW_MINERAL input_type ile T2/T3/T4 istiyor. Seçim ekranı bu tier'larda ham kayıt bulamıyor; otomatik fallback ilk ham cevhere dönebilir.
6. Refined input kullanan ticaret/enerji binalarında fallback `ref_{planet_seed}` adlı, normal stokta üretilmeyen bir kimliktir.
7. ResourceData.processed() tier artırsa da tag'i korur ve normal üretim yolunda çağrılmıyor.
8. Mineral adı seed'ine tag dahil olduğu için ayrı RAW ve REFINED üretimi eklemek de tek başına yetmez; aynı rarity'nin adları eşleşmeyebilir.

Bu nedenle üst tier ekonomisinin aşağıdaki katalog sayıları **amaçlanan tarifeleri** gösterir; tamamı erişilebilir çalışan ürün zinciri olarak okunmamalıdır.

## 5. Üretim matematiği

### 5.1. Ortak değişkenler

| Sembol | Anlam |
|---|---|
| A | Aynı kayıtta birleştirilmiş bina adedi |
| L | Bina seviyesi |
| B | Bina temel kredi maliyeti |
| O | Bina tanımındaki çevrim çıktısı |
| I | Bina tanımındaki çevrim girdisi |
| T | Bina tanımındaki çevrim süresi |
| q | Global enerji kapsama oranı, 0..1 |
| S | İlgili hız çarpanlarının çarpımı |

```text
Seviye çıktı çarpanı M(L) = 1 + 0.5 log2(max(1,L))
Seviye tüketim çarpanı C(L) = 1 + 0.25 log2(max(1,L))
Yükseltme fiyatı L→L+1 = B × 1.5^(L-1) × A
```

**Temel fark:** M(L), enerji kapasitesi ve destek etkilerinde uygulanır. MineLogic, RefineryLogic, CreditLogic ve ScienceLogic gerçek çevrim çıktısına M(L) uygulamaz. Üretim kartı ise uygular. Bu yüzden bina yükseltmesinin gösterilen getirisi ile depoya/bakiyeye yazılan getirisi farklıdır.

Girdi miktarı `I × A × C(L)`; enerji tüketimi de C(L) ile büyür. Mevcut uygulamada birçok üretim binasını yükseltmek çıktı artırmadan maliyeti yükseltir.

### 5.2. Çevrim sırası

1. Bina tanımı yoksa veya tick_duration≤0 ise bina tamamen atlanır.
2. İnşaat varsa süre ilerletilir, üretim yapılmaz.
3. Kullanıcı kapattıysa üretim durur.
4. Çevrim ilerlemesi 0 ise bütün girdiler tek seferde global stoktan alınır. A adet binaya kısmi girdi yeterli olmaz.
5. Girdi yetmiyorsa otomatik duraklama açılır.
6. Enerji tüketen binada q=0 ise ilerleme durur; 0<q<1 ise hız q ile çarpılır.
7. `ilerleme += delta × S / etkin_T`.
8. İlerleme≥1 olduğunda bir kez çıktı verilir ve ilerleme 0 yapılır.

Fazla ilerleme taşınmaz. Aynı karede birden fazla çevrim tamamlanmaz. Dolayısıyla `O×S/T` formülü kesintisiz ve yeterince küçük zaman adımı varsayımıyla nominal ortalamadır. Çok hızlı üretim veya düşük kare hızında gerçek çıktı düşer.

İnşaat süresi: construct_duration>0 ise bu süre, değilse T. İnşaat enerji ve üretim hızı bonusuyla hızlanmaz. Ancak tick_duration=0 erken atlandığı için bu binaların inşaatı, ayrı construct_duration verilse bile tamamlanmaz.

### 5.3. Hız çarpanları

```text
Ortak hız = global_skill_hızı × gezegen_logistics_hızı × enerji_hızı
gezegen_logistics_hızı = 1.20, tamamlanmış logistics_center varsa; yoksa 1
enerji_hızı = q, energy_per_tick<0 ise; aksi halde 1

Ham madencilik ek hızı =
 clamp(0.4 × yerel_havuz_ortalama_power, 0.5, 3)
 × gezegen_maden_hızı × skill_maden_hızı × district_maden_hızı

Rafineri ek hızı = skill_rafineri_hızı × district_rafineri_hızı
Bilim ek hızı = district_bilim_hızı
Kredi ek hızı = skill_ticaret_hızı × district_ticaret_hızı
```

Kredi hız yolu bütün CREDITS binalarına uygulanır; konutlar da ticaret hızından yararlanır. Atmospheric Siphon ve Aerosol Refinery ayrıca district gas_mining_speed_mult alır.

Yakıtlı enerji üreticisinin etkin süresi `T × district_generator_duration × yakıt_rarity`. Rarity çıktıyı artırmaz, yakıtın yanma süresini uzatır. Global hız artışı yakıt tüketimini artırır fakat enerji kapasitesini aynı oranda artırmaz.

### 5.4. Çevrim başına gerçek çıktılar

```text
Ham toplam = O × A × gezegen_maden_verimi × skill_maden_verimi × district_maden_verimi
Magma Dredge ayrıca district_magma_verimi alır.
Karışık üretimde her kaynağa toplam × yoğunluk_payı verilir.

Rafineri = O × A × gezegen_maden_verimi × skill_maden_verimi
District mine_output_mult ve bina seviye M(L) uygulanmaz.

Kredi = O × A × global_kredi_çarpanı × bina_sınıfı_çarpanı

Bilim = O × A × (1 + .15·science_income_1_açık
                           + .20·science_income_2_açık
                           + .20·omega_core_açık)
                   × district_bilim_verimi
```

Kredi bina sınıfı: residential için residential_mult, apartments için apartments_mult, luxury_complex için luxury_complex_mult. Geri kalan CreditLogic binaları district trade_output_mult ve skill trade_output_mult alır. Housing income bonusu bütün kredi kaynaklarına uygulanır.

Precision Extractor ve Quantum Harvester yalnız target_mineral doluysa hedefli üretir. Mevcut normal bina kurma yolu hedef göndermiyor; MineLogic mineral seçici de istemiyor. Bu yüzden hedef seçimi olmadan ikisi de karışık üretime düşer.

## 6. Enerji matematiği

### 6.1. Global kapasite

Enerji her çevrim sonunda birikmez. Her karede üretim kapasitesi P ve talep D hesaplanır:

```text
Net enerji = P - D
q = 1, D≤0 ise
q = clamp(P/D,0,1), diğer durumda
```

100 enerji üretim, 200 talep varsa bütün enerji tüketen üreticilerin hızı %50 olur. Arz fazlası üretimi 1'in üstüne hızlandırmaz. Enerji depolama, batarya veya gezegenler arası iletim kaybı yok.

İnşa halindeki, kullanıcı tarafından kapatılmış veya otomatik durmuş binalar enerji hesabına alınmaz. Otomatik duraklama bir önceki üretim adımından gelebilir; yakıt giriş/çıkışlarında bir kare gecikme olabilir.

### 6.2. Üretici ve tüketici formülleri

Enerji üreticisinin output_amount kapasitesi:

- Solar Array/Matrix: `O × A × M(L) × skill_solar × district_clean × district_solar`.
- Geothermal: `O × A × M(L) × skill_generator × district_clean × district_geothermal`.
- Yakıtlı üretici: `O × A × M(L) × skill_generator`; burning_mineral boşsa 0.
- Diğer ENERGY çıktıları: `O × A × M(L)`.
- Pozitif energy_per_tick tanımı varsa ayrıca kapasiteye eklenir. Bu iki alan genel tasarımda aynı enerjiyi iki kez tanımlamamalıdır.

Negatif energy_per_tick için:

```text
Talep = abs(E) × A × C(L) × maden_tüketim_çarpanı
                           × etkin_skill_enerji_çarpanı
                           × command_center_çarpanı
```

Maden/refinery için maden tüketim çarpanı:
`max(0.1, district_mining_energy_cost_mult) × skill_mining_energy_mult`; diğer binalarda 1.

Etkin skill çarpanı, global enerji çarpanından uygun durumlarda 0.10 housing, 0.10 science veya 0.10 trade indirimi çıkarılarak hesaplanır. Housing kontrolü CITY'nin bina allowed_poi_types listesinde bulunmasıdır. Bu nedenle City'ye uygun bilim binaları iki indirimi birden alabilir. Trade indirimi yalnız CITY'ye uygun olmayan kredi binalarına uygulanır.

Command Center varsa ×0.85; binanın sayısı veya seviyesi ek çarpan yaratmaz. Bina mevcut normal inşaat yolunda tamamlanamadığı için bu etki şu anda koşulludur.

PlanetModifier ENERGY_COST_MULT bu global talep formülüne bağlanmamıştır. Terran'ın yazılı %15 enerji avantajı gerçek enerji hesabında uygulanmaz.

### 6.3. Kritik girdi tüketim kenar durumu

q=0, ilerleme=0 ve girdi isteyen bir bina düşünelim. Kod önce girdiyi harcar, sonra enerjisiz olduğu için ilerlemeyi artırmadan çıkar. Sonraki karede ilerleme hâlâ 0 olduğundan girdiyi yeniden harcar. Stok bitene kadar çevrim başına değil **kare başına girdi kaybı** oluşabilir.

Örnek: Refinery için 15 ham/kare; 60 kare/saniye varsayımında stok yeterliyse 900 ham/saniyeye kadar kayıp. Bu varsayımsal bir performans ölçümü değil, ilgili kontrol akışının aritmetik sonucudur. Sayısal dengelemeden önce çözülmelidir.

## 7. Destek binaları ve etkileşimler

Bir destek binasının katkısı genel olarak `katsayı × adet × M(seviye)` şeklinde aynı bonus havuzuna eklenir. Aynı havuz içi bonuslar toplanır; farklı havuzlar çarpılır.

| Destek bina | Etki alanı | Her adet için L1 katkısı |
|---|---|---:|
| circuit_overloader | Aynı district Solar Array/Matrix | +%3 çıktı |
| magma_resonator | Aynı district Geothermal | +%2 çıktı |
| grid_optimizer | Aynı district temiz enerji | +%1 çıktı |
| combustion_stabilizer | Aynı district yakıtlı üretici | +%5 yakıt çevrim süresi |
| extraction_optimizer | Aynı district ham madencilik | +%5 çıktı |
| sonic_resonator | Aynı district ham madencilik | +%5 hız |
| thermal_crusher | Aynı district rafineri | +%5 hız |
| logistics_hub | Aynı district ham/refined enerji talebi | -%5; district çarpanı en az 0.1 |
| tectonic_stabilizer | Aynı district Magma Dredge | +%50 çıktı |
| pressure_funnel | Aynı district Siphon/Aerosol | +%50 hız |
| zero_g_sorter | Aynı district ham madencilik | +%20 hız |
| culture_center | Aynı district Residential | +%20 çıktı |
| recreation_center | Aynı district Apartments | +%25 çıktı |
| opera_house | Aynı district Luxury Complex | +%30 çıktı |
| library | Aynı district bilim | +%15 çıktı |
| observatory | Aynı district bilim | +%10 hız |
| research_nexus | Aynı district bilim | +%30 çıktı |
| customs_office | Aynı district ticaret sınıfı | +%15 çıktı |
| logistics_center | Aynı district bütün kredi üreticileri | +%10 hız |
| central_bank | Aynı district ticaret sınıfı | +%30 çıktı |
| orbital_mirrors | Gezegendeki bütün solar üreticiler | +%15 çıktı |
| orbital_logistics | Gezegendeki kredi hızı ve ticaret çıktısı | +%25 hız, +%25 çıktı |
| zero_g_nexus | Gezegendeki bütün bilim üreticileri | +%30 çıktı |

Logistics Center ayrıca gezegendeki bütün çevrimlere tek seferlik ×1.20 hız verir. Command Center bütün gezegen enerji talebini ×0.85 yapar. Cryo-Vault kapasite yeniden hesaplandığında +2 district verir.

**Uygulama sınırları:**
- İnşaatı bitmemiş destek katkı vermez.
- Duraklatılmış veya enerjisiz destek için buff taramasında kontrol yoktur. İnşaatı tamamlandıktan sonra kapatılan destek bonusunu koruyabilir, enerji talebi ise sıfırlanır.
- tick_duration=0 olan sekiz binanın inşaat sorunu nedeniyle ilgili katkılar normal yeni oyunda devreye giremez.
- Solar ve temiz enerji ayrı havuzdur. Örnek: bir L1 Overloader ve bir L1 Grid Optimizer sonucu 1.03×1.01=1.0403, yani %4.03 artıştır.
- Üç L1 Library için tanım seviyesinde bilim çarpanı 1+3×0.15=1.45 olur. Ancak max_per_district ve yığın limitlerinin tutarsız uygulanması ayrıca değerlendirilmelidir.
- “Her level +%15” gibi metinler gerçek destek seviyesiyle birebir değildir. L2 Library etkisi .15×1.5=.225, yani %22.5'tir; %30 değil.

## 8. Bina kataloğu

### 8.1. Tablo kuralları

Bu bölüm bütün **76 bina tanımını** kapsar. Dosyada yazılmayan alanlar BuildingDef varsayılanlarıyla tamamlandı: slot=1, minimum gezegen seviyesi=1, çevrim=30 s, özel inşaat süresi=0, enerji=0, girdi/çıktı=NONE, input_tier=1, district adet sınırı=0.

İlk tablo ham denge değerlerini; ikinci tablo açılma, yerleşim ve uygulama durumunu gösterir. Kredi/bilim/cevher “çıktı” değeri çevrim başınadır. ENERGY çıktısı sürekli enerji kapasitesidir. Süre sütunundaki “ilerlemez”, tick_duration=0 nedeniyle gerçek inşaat yolunun durduğunu belirtir.

Başlangıç bina kataloğunda lab, mine, residential ve solar_panel varsayılan açıktır; Mine'ın kullanılacağı Mining district araştırmayla açılır. moon_observatory ve zero_g_nexus de unlocked_by_default=true taşır, fakat ayrıca kendi unlock_skill koşulları vardır.

### 8.2. Tam maliyet ve üretim tablosu

| Bina kimliği | Oyun içi ad | Kredi | Slot | Min. gezegen L | İnşaat s | Çevrim s | Enerji +/- | Çıktı | Girdi / çevrim |
|---|---|---:|---:|---:|---|---:|---:|---|---|
| `advanced_lab` | Institute of Technology | 1500 | 1 | 2 | 75 | 75 | -100 | 25 bilim | yok |
| `aerosol_refinery` | Aerosol Refinery | 3500 | 1 | 3 | 20 | 20 | -5 | 10 işlenmiş | 20 ham (T1) |
| `antimatter_chamber` | Antimatter Chamber | 2000 | 1 | 4 | 30 | 30 | 0 | 120 enerji | 1 işlenmiş (T4) |
| `apartments` | Apartments | 250 | 1 | 1 | 120 | 120 | -4 | 150 kredi | yok |
| `arid_housing` | Subterranean Arcology | 400 | 3 | 2 | 30 tanım; ilerlemez | 0 | -20 | 0 yok | yok |
| `arid_trade` | Spice Exchange | 600 | 2 | 2 | 30 | 30 | -10 | 400 kredi | yok |
| `asteroid_harvester` | Asteroid Harvester | 8000 | 2 | 1 | 20 | 20 | -50 | 500 ham | yok |
| `atmospheric_siphon` | Atmospheric Siphon | 3000 | 1 | 3 | 25 | 25 | -8 | 200 ham | yok |
| `central_bank` | Central Bank | 12000 | 1 | 3 | 0 tanım; ilerlemez | 0 | -200 | 0 yok | yok |
| `circuit_overloader` | Circuit Overloader | 400 | 1 | 2 | 30 | 30 | 0 | 0 yok | yok |
| `combustion_stabilizer` | Combustion Stabilizer | 600 | 1 | 2 | 30 | 30 | 0 | 0 yok | yok |
| `command_center` | Command Center | 15000 | 3 | 3 | 0 tanım; ilerlemez | 0 | 0 | 0 yok | yok |
| `commercial_hub` | Commercial Hub | 3000 | 1 | 2 | 30 | 30 | -10 | 150 kredi | 5 işlenmiş (T1) |
| `commercial` | Commercial Center | 500 | 1 | 1 | 40 | 40 | -6 | 65 kredi | yok |
| `commodities_exchange` | Commodities Exchange | 10000 | 2 | 3 | 25 | 25 | -60 | 1200 kredi | 10 işlenmiş (T3) |
| `cryo_vault` | Cryo-Vault | 2500 | 1 | 1 | 0 tanım; ilerlemez | 0 | -5 | 0 yok | yok |
| `culture_center` | Culture Center | 400 | 1 | 1 | 30 | 30 | -5 | 0 yok | yok |
| `customs_office` | Customs Office | 1500 | 1 | 1 | 0 tanım; ilerlemez | 0 | -20 | 0 yok | yok |
| `data_center` | Data Center | 1000 | 1 | 1 | 15 | 15 | -150 | 15 bilim | yok |
| `deep_drill` | Deep Drill | 600 | 1 | 2 | 15 | 15 | -5 | 28 ham | yok |
| `extraction_optimizer` | Extraction Optimizer | 1200 | 1 | 2 | 30 | 30 | -10 | 0 yok | yok |
| `financial_district` | Financial District | 3000 | 1 | 2 | 20 | 20 | -15 | 250 kredi | 10 işlenmiş (T2) |
| `fusion_reactor` | Fusion Reactor | 1200 | 2 | 2 | 12 | 12 | 0 | 25 enerji | 8 ham (T1) |
| `generator` | Thermic Generator | 100 | 1 | 1 | 30 | 30 | 0 | 5 enerji | 5 ham (T1) |
| `geothermal_plant` | Geothermal Plant | 1000 | 1 | 3 | 30 | 30 | 0 | 10 enerji | yok |
| `grid_optimizer` | Grid Optimizer | 500 | 1 | 2 | 30 | 30 | 0 | 0 yok | yok |
| `ice_science` | Subglacial Laboratory | 800 | 2 | 2 | 30 | 30 | -40 | 25 bilim | yok |
| `interstellar_syndicate` | Interstellar Syndicate | 100000 | 3 | 5 | 45 | 45 | -1000 | 35000 kredi | 10 işlenmiş (T5) |
| `lab` | University | 200 | 1 | 1 | 3 | 25 | -2 | 2 bilim | yok |
| `library` | Library | 500 | 1 | 1 | 30 | 30 | -5 | 0 yok | yok |
| `logistics_center` | Logistics Center | 4000 | 1 | 2 | 0 tanım; ilerlemez | 0 | -50 | 0 yok | yok |
| `logistics_hub` | Logistics Hub | 2000 | 1 | 3 | 30 | 30 | -5 | 0 yok | yok |
| `lunar_observatory` | Lunar Observatory | 5000 | 1 | 1 | 60 | 60 | -20 | 200 bilim | yok |
| `luxury_complex` | Luxury Complex | 1200 | 2 | 2 | 240 | 240 | -12 | 500 kredi | yok |
| `magma_dredge` | Magma Dredge | 3000 | 1 | 3 | 10 | 10 | -10 | 150 ham | yok |
| `magma_resonator` | Magma Resonator | 800 | 1 | 3 | 30 | 30 | 0 | 0 yok | yok |
| `mantle_cracker` | Mantle Cracker | 4000 | 1 | 4 | 12 | 12 | -40 | 250 ham | yok |
| `market_square` | Market Square | 200 | 1 | 1 | 10 | 10 | -2 | 15 kredi | yok |
| `micro_g_drill` | Micro-G Drill | 1200 | 1 | 2 | 12 | 12 | -15 | 40 ham | yok |
| `mine` | Mine | 150 | 1 | 1 | 18 | 18 | -2 | 10 ham | yok |
| `molecular_forge` | Molecular Forge | 7000 | 1 | 4 | 60 | 60 | -60 | 1 işlenmiş | 15 ham (T3) |
| `moon_helium3` | Lunar Helium-3 Extractor | 1000 | 2 | 2 | 20 | 30 | 0 | 500 enerji | yok |
| `moon_observatory` | Deep Space Observatory | 1200 | 2 | 2 | 20 | 30 | -60 | 30 bilim | yok |
| `observatory` | Observatory | 1500 | 1 | 1 | 30 | 30 | -20 | 0 yok | yok |
| `opera_house` | Opera House | 4000 | 1 | 1 | 30 | 30 | -20 | 0 yok | yok |
| `orbital_logistics` | Orbital Logistics Hub | 1000 | 2 | 3 | 30 tanım; ilerlemez | 0 | 0 | 0 yok | yok |
| `orbital_mirrors` | Orbital Mirrors | 500 | 2 | 2 | 30 tanım; ilerlemez | 0 | 0 | 0 yok | yok |
| `orbital_offworld_market` | Offworld Trading Hub | 5000 | 2 | 2 | 60 | 300 | -50 | 25000 kredi | 1000 ham (T1) |
| `orbital_shipyard` | Orbital Shipyard | 10000 | 2 | 1 | 120 | 120 | -30 | 5000 kredi | 50 işlenmiş (T1) |
| `orbital_trade_port` | Orbital Trade Port | 35000 | 2 | 4 | 30 | 30 | -200 | 6000 kredi | 10 işlenmiş (T4) |
| `particle_accelerator` | Particle Accelerator | 3000 | 1 | 1 | 90 | 90 | -250 | 100 bilim | 20 kredi (T1) |
| `plasma_reactor` | Plasma Reactor | 800 | 1 | 3 | 30 | 30 | 0 | 45 enerji | 1 işlenmiş (T3) |
| `plasma_smelter` | Plasma Smelter | 2500 | 1 | 3 | 30 | 30 | -25 | 2 işlenmiş | 15 ham (T2) |
| `precision_extractor` | Precision Extractor | 1500 | 1 | 3 | 20 | 20 | -15 | 80 ham | yok |
| `pressure_funnel` | Pressure Funnel | 2000 | 1 | 3 | 30 | 30 | -5 | 0 yok | yok |
| `pyroclastic_forge` | Pyroclastic Forge | 3500 | 1 | 3 | 12 | 12 | -2 | 5 işlenmiş | 5 ham (T1) |
| `quantum_computer` | Quantum Computer | 10000 | 1 | 1 | 180 | 180 | -1000 | 300 bilim | 50 kredi (T1) |
| `quantum_harvester` | Quantum Harvester | 12000 | 1 | 5 | 8 | 8 | -120 | 800 ham | yok |
| `recreation_center` | Recreation Center | 1000 | 1 | 1 | 30 | 30 | -10 | 0 yok | yok |
| `refinery` | Refinery | 800 | 1 | 2 | 15 | 15 | -8 | 3 işlenmiş | 15 ham (T1) |
| `research_academy` | Research Academy | 800 | 2 | 2 | 45 | 45 | -30 | 10 bilim | yok |
| `research_nexus` | Research Nexus | 5000 | 1 | 1 | 30 | 30 | -50 | 0 yok | yok |
| `residential` | Residential Block | 100 | 1 | 1 | 3 | 60 | -2 | 50 kredi | yok |
| `scanner` | Deep Scanner | 400 | 1 | 1 | 55 | 55 | -3 | 10 kredi | yok |
| `singularity_core` | Singularity Core | 5000 | 1 | 5 | 30 | 30 | 0 | 350 enerji | 1 işlenmiş (T5) |
| `singularity_forge` | Singularity Forge | 20000 | 1 | 5 | 120 | 120 | -150 | 1 işlenmiş | 15 ham (T4) |
| `solar_matrix` | Solar Matrix | 600 | 1 | 2 | 30 | 30 | 0 | 4 enerji | yok |
| `solar_panel` | Solar Array | 150 | 1 | 1 | 3 | 30 | 0 | 1 enerji | yok |
| `sonic_resonator` | Sonic Resonator | 1500 | 1 | 2 | 30 | 30 | -15 | 0 yok | yok |
| `spaceport` | Spaceport | 500 | 2 | 1 | 3 | 45 | 0 | 0 yok | yok |
| `tectonic_stabilizer` | Tectonic Stabilizer | 2000 | 1 | 3 | 30 | 30 | -5 | 0 yok | yok |
| `thermal_crusher` | Thermal Crusher | 1500 | 1 | 2 | 30 | 30 | -12 | 0 yok | yok |
| `thermic_burner` | Thermic Burner | 300 | 1 | 2 | 30 | 30 | 0 | 15 enerji | 2 işlenmiş (T2) |
| `trading_post` | Trading Post | 1000 | 1 | 1 | 15 | 15 | -5 | 60 kredi | 10 işlenmiş (T1) |
| `zero_g_nexus` | No Gravity Research Station | 400 | 1 | 1 | 30 | 30 | -10 | 20 bilim | yok |
| `zero_g_sorter` | Zero-G Sorter | 1800 | 1 | 2 | 30 | 30 | -8 | 0 yok | yok |

### 8.3. Yerleşim, açılma ve çalışan davranış

“Başlangıç” açılma durumunu belirtir; ayrıca district, gezegen ve minimum seviye koşulları sağlanmalıdır. “Araştırma” kayıtlı bina kimliğini açar. Bina seviyesi artışı ayrıca Bölüm 9 kurallarına bağlıdır. District sınırındaki “yok” sıfır/adet sınırsız tanımıdır; slot kapasitesi yine geçerlidir.

| Bina kimliği | POI izni | Gezegen izni | Açılma yolu | District adet sınırı | Gerçek uygulama notu |
|---|---|---|---|---:|---|
| `advanced_lab` | City, Science | Tümü | unlock_advanced_lab | yok | Bağlı üretim mantığı çalışır |
| `aerosol_refinery` | Mining | Gas Giant | unlock_aerosol_refinery | yok | İşlenmiş havuz eksik; girdi kimliğine geri üretir |
| `antimatter_chamber` | Energy | Tümü | unlock_antimatter_chamber | yok | İşlenmiş girdi zinciri kapalı |
| `apartments` | City | Tümü | unlock_apartments | yok | Bağlı üretim mantığı çalışır |
| `arid_housing` | City | Arid | unlock_arid_housing | 2 | İnşaat tamamlanmaz |
| `arid_trade` | City | Arid | unlock_arid_trade | 2 | Üretim mantığı bağlı değil: gerçek çıktı 0 |
| `asteroid_harvester` | Mining | Tümü | unlock_asteroid_harvester | yok | Üretim mantığı bağlı değil: gerçek çıktı 0 |
| `atmospheric_siphon` | Mining | Gas Giant | unlock_atmospheric_siphon | yok | Gas Giant verim çarpanı 0: ham çıktı 0 |
| `central_bank` | City | Tümü | unlock_central_bank | 1 | İnşaat tamamlanmaz |
| `circuit_overloader` | Energy | Tümü | unlock_circuit_overloader | yok | Destek tablosundaki etki |
| `combustion_stabilizer` | Energy | Tümü | unlock_combustion_stabilizer | yok | Destek tablosundaki etki |
| `command_center` | City | Tümü | unlock_command_center | yok | İnşaat tamamlanmaz |
| `commercial_hub` | City | Tümü | NORMAL AÇILMA YOK | yok | Yanlış GeneratorLogic: kredi çıktısı 0; İşlenmiş girdi zinciri kapalı |
| `commercial` | City | Tümü | NORMAL AÇILMA YOK | yok | Bağlı üretim mantığı çalışır |
| `commodities_exchange` | City | Tümü | unlock_commodities_exchange | yok | İşlenmiş girdi zinciri kapalı |
| `cryo_vault` | City | Tümü | unlock_cryo_vault | yok | İnşaat tamamlanmaz |
| `culture_center` | City | Tümü | unlock_culture_center | 1 | Destek tablosundaki etki |
| `customs_office` | City | Tümü | unlock_customs_office | 1 | İnşaat tamamlanmaz |
| `data_center` | City, Science | Tümü | NORMAL AÇILMA YOK | yok | Bağlı üretim mantığı çalışır |
| `deep_drill` | Mining | Tümü | unlock_deep_drill | yok | Bağlı üretim mantığı çalışır |
| `extraction_optimizer` | Mining | Tümü | unlock_extraction_optimizer | yok | Destek tablosundaki etki |
| `financial_district` | City | Tümü | unlock_financial_district | yok | İşlenmiş girdi zinciri kapalı |
| `fusion_reactor` | Energy | Tümü | unlock_fusion_reactor | yok | Enerji kapasitesi hesabıyla çalışır |
| `generator` | Energy | Tümü | unlock_generator | yok | Enerji kapasitesi hesabıyla çalışır |
| `geothermal_plant` | Energy | Moon | unlock_geothermal_plant | yok | Gezegen enum'u açıklamayla uyuşmuyor |
| `grid_optimizer` | Energy | Tümü | unlock_grid_optimizer | yok | Destek tablosundaki etki |
| `ice_science` | Science | Ice | unlock_ice_science | 2 | Üretim mantığı bağlı değil: gerçek çıktı 0 |
| `interstellar_syndicate` | City | Tümü | unlock_interstellar_syndicate | yok | İşlenmiş girdi zinciri kapalı |
| `lab` | City, Science | Tümü | Başlangıç | yok | Bağlı üretim mantığı çalışır |
| `library` | City, Science | Tümü | unlock_library | 1 | Destek tablosundaki etki |
| `logistics_center` | City | Tümü | unlock_logistics_center | 1 | İnşaat tamamlanmaz |
| `logistics_hub` | Mining | Tümü | unlock_logistics_hub | yok | Destek tablosundaki etki |
| `lunar_observatory` | City | Tümü | unlock_lunar_observatory | yok | Üretim mantığı bağlı değil: gerçek çıktı 0 |
| `luxury_complex` | City | Tümü | unlock_luxury_complex | yok | Bağlı üretim mantığı çalışır |
| `magma_dredge` | Mining | Volcanic | unlock_magma_dredge | yok | Bağlı üretim mantığı çalışır |
| `magma_resonator` | Mining | Moon | unlock_magma_resonator | yok | Gezegen enum'u açıklamayla uyuşmuyor |
| `mantle_cracker` | Mining | Tümü | unlock_mantle_cracker | yok | Bağlı üretim mantığı çalışır |
| `market_square` | City | Tümü | unlock_market_square | yok | Bağlı üretim mantığı çalışır |
| `micro_g_drill` | Mining | Asteroid | unlock_micro_g_drill | yok | Bağlı üretim mantığı çalışır |
| `mine` | Mining | Tümü | Başlangıç | yok | Bağlı üretim mantığı çalışır |
| `molecular_forge` | Mining | Tümü | unlock_molecular_forge | yok | İşlenmiş havuz eksik; girdi kimliğine geri üretir |
| `moon_helium3` | Mining | Moon | unlock_moon_helium3 | 2 | Enerji kapasitesi 500 çalışır; yakıt gerektirmez |
| `moon_observatory` | Science | Moon | unlock_lunar_observatory | 1 | Üretim mantığı bağlı değil: gerçek çıktı 0; unlocked_by_default=true + skill şartı; yalnız Science POI, kurulabilir district yok |
| `observatory` | City, Science | Tümü | unlock_observatory | 1 | Destek tablosundaki etki |
| `opera_house` | City | Tümü | unlock_opera_house | 1 | Destek tablosundaki etki |
| `orbital_logistics` | Station | Tümü | unlock_orbital_logistics | 1 | İnşaat tamamlanmaz |
| `orbital_mirrors` | Station | Tümü | unlock_orbital_mirrors | 1 | İnşaat tamamlanmaz |
| `orbital_offworld_market` | Station | Tümü | unlock_orbital_offworld_market | 1 | Bağlı üretim mantığı çalışır |
| `orbital_shipyard` | Station | Tümü | unlock_orbital_shipyard | yok | Yanlış GeneratorLogic: kredi çıktısı 0; İşlenmiş girdi zinciri kapalı |
| `orbital_trade_port` | City | Tümü | unlock_orbital_trade_port | yok | İşlenmiş girdi zinciri kapalı |
| `particle_accelerator` | City, Science | Tümü | NORMAL AÇILMA YOK | yok | Girdi CREDITS enum'u; kaynak anahtarı boş, bekler |
| `plasma_reactor` | Energy | Tümü | unlock_plasma_reactor | yok | İşlenmiş girdi zinciri kapalı |
| `plasma_smelter` | Mining | Tümü | unlock_plasma_smelter | yok | İşlenmiş havuz eksik; girdi kimliğine geri üretir |
| `precision_extractor` | Mining | Tümü | unlock_precision_extractor | yok | Normal arayüz hedef atamıyor; karışık üretim |
| `pressure_funnel` | Mining | Gas Giant | unlock_pressure_funnel | yok | Destek tablosundaki etki |
| `pyroclastic_forge` | Mining | Volcanic | unlock_pyroclastic_forge | yok | İşlenmiş havuz eksik; girdi kimliğine geri üretir |
| `quantum_computer` | City, Science | Tümü | NORMAL AÇILMA YOK | yok | Girdi CREDITS enum'u; kaynak anahtarı boş, bekler |
| `quantum_harvester` | Mining | Tümü | unlock_quantum_harvester | yok | Normal arayüz hedef atamıyor; karışık üretim |
| `recreation_center` | City | Tümü | unlock_recreation_center | 1 | Destek tablosundaki etki |
| `refinery` | Mining | Tümü | unlock_refinery | yok | İşlenmiş havuz eksik; girdi kimliğine geri üretir |
| `research_academy` | City | Tümü | unlock_research_academy | yok | Üretim mantığı bağlı değil: gerçek çıktı 0 |
| `research_nexus` | City, Science | Tümü | unlock_research_nexus | 1 | Destek tablosundaki etki |
| `residential` | City | Tümü | Başlangıç | yok | Bağlı üretim mantığı çalışır |
| `scanner` | Science | Tümü | NORMAL AÇILMA YOK | yok | Bağlı üretim mantığı çalışır |
| `singularity_core` | Energy | Tümü | unlock_singularity_core | yok | İşlenmiş girdi zinciri kapalı |
| `singularity_forge` | Mining | Tümü | unlock_singularity_forge | yok | İşlenmiş havuz eksik; girdi kimliğine geri üretir |
| `solar_matrix` | Energy | Ice | unlock_solar_matrix | yok | Gezegen enum'u açıklamayla uyuşmuyor |
| `solar_panel` | Energy | Tümü | Başlangıç | yok | Enerji kapasitesi hesabıyla çalışır |
| `sonic_resonator` | Mining | Tümü | unlock_sonic_resonator | yok | Destek tablosundaki etki |
| `spaceport` | City | Tümü | NORMAL AÇILMA YOK | yok | Destek tablosundaki etki |
| `tectonic_stabilizer` | Mining | Volcanic | unlock_tectonic_stabilizer | yok | Destek tablosundaki etki |
| `thermal_crusher` | Mining | Tümü | unlock_thermal_crusher | yok | Destek tablosundaki etki |
| `thermic_burner` | Mining | Tümü | unlock_thermic_burner | yok | İşlenmiş girdi zinciri kapalı |
| `trading_post` | City | Tümü | unlock_trading_post | yok | İşlenmiş girdi zinciri kapalı |
| `zero_g_nexus` | Station | Tümü | unlock_space_station | 1 | Üretim mantığı bağlı değil: gerçek çıktı 0; Doğrudan bilim yok; gezegen +%30 bilim desteği var |
| `zero_g_sorter` | Mining | Asteroid | unlock_zero_g_sorter | yok | Destek tablosundaki etki |

### 8.4. Katalogda özellikle dikkat edilmesi gerekenler

- Solar Matrix açıklamada Arid, veride ICE=2. Geothermal Plant ve Magma Resonator açıklamada Volcanic, veride MOON=6.
- Thermic Burner Energy yerine Mining POI'sinde kuruluyor.
- Orbital Trade Port adı yörünge çağrıştırsa da yalnız City POI'sine izin veriyor.
- Asteroid Harvester gezegen filtresi taşımıyor; adı tek başına asteroid şartı getirmiyor.
- Cryo-Vault ve lunar_observatory açıklamalarında özel gezegenler olsa da tanımlarında gezegen filtresi yok.
- ice_science yalnız Science POI'sine izin veriyor. Kurulabilir district kataloğunda Science district'i yok.
- moon_observatory yalnız Science POI için tanımlı. unlocked_by_default=true ve unlock_lunar_observatory şartıyla katalogda açılabilir; fakat kurulabilir Science district'i yok. Aynı skill farklı lunar_observatory binasını da açıyor.
- max_per_district yeni slot menüsünde kayıt adediyle sayılıyor, yığın adediyle değil. “+” yığın düğmesi bu sınırı kontrol etmiyor.
- Bina sökümünde kredi veya malzeme iadesi yok. Bir yığından bir adet silinir.
- Yeni aynı bina mevcut yükseltilmiş yığına yalnız temel maliyetle birleşebilir. Eklenen adet yığının seviyesini fiilen miras alır; tanımlı kümülatif yükseltme fiyatı satın almada kullanılmıyor.
- Bina yükseltmesi anlıktır. Ayrı yükseltme inşaat süresi yoktur.

## 9. Araştırma kuralları ve tam skill kataloğu

### 9.1. Ödeme, seviye ve önkoşul

Araştırmalar **bilim** harcar. Bazı arayüz metinleri kredi dese de çalışan satın alma GameState.spend_science kullanır.

```text
Mevcut skill seviyesi l iken sonraki fiyat = temel_bilim_fiyatı × (1+l)
Sıfırdan N seviyeye toplam = temel_fiyat × N(N+1)/2
```

Örneğin taban 50, üst sınır 5 ise seviye fiyatları 50,100,150,200,250; toplam 750 bilim.

İstisna unlock_mining: L1=20, L2=110, L3=60; devamı 80,100,120,140,160,180,200. On seviyenin toplamı 1170 bilim. L2'nin L3'ten pahalı olması gerçek mevcut eğridir.

Başlangıçta L1 olan solar/residential/lab düğümleri için yeniden L1 ödenmez. L10'a kadar ilave toplam sırasıyla 2700,2700,5400 bilimdir.

Birden çok parent varsa **en az biri açık** olması yeterlidir; hepsi aranmaz. Parent seviyesi 1 yeterli. Sadece ilk alımda parent kontrolü yapılır. Ayrıca:
- Magma Dredge ve Atmospheric Siphon ilk alımında Precision Extractor açık olmalıdır.
- Micro-G Drill ilk alımında Deep Drill açık olmalıdır.
- Skill tier alanı bağımsız bir araştırma çağı kilidi olarak kullanılmaz.

Bina azami seviyesi genel olarak `unlock_{building_id}` skill seviyesidir. Mine için unlock_mining kullanılır. Varsayılan 1'dir; L1 skill bina L2 açmaz. Bina yükseltme düğmesindeki SceneTree singleton kontrolü nedeniyle bu arayüz yolunun motor içinde doğrulanması gerekir.

### 9.2. Gerçek pasif çarpanlar

Aşağıda l ilgili skill seviyesi, I açık olma göstergesi (0/1):

| Hesap | Gerçek formül |
|---|---|
| Solar | 1 + .10·l_solar_efficiency + 1·I_dyson_swarm |
| Mine hızı | 1 + .05·l_mine_speed + .20·I_omega_core |
| Mine/refinery çıktı | 1 + .02·l_deep_mining |
| Refinery hızı | 1 + .05·l_refinery_efficiency |
| Maden enerji | max(.1, 1 - .02·l_mining_logistics) |
| Generator | 1 + .05·I_generator_efficiency + .02·(l_supercharged + l_thermic + l_plasma + l_antimatter + l_singularity) |
| Global kredi | 1 + .15·I_housing_income_1 + .20·I_housing_income_2 |
| Ticaret çıktısı | 1 + .15·l_trade_income_1 + .20·l_trade_income_2 |
| Kredi hızı | 1 + .10·l_trade_speed |
| Global enerji talebi | max(.1, 1 - .15·I_power_transmission - .02·l_energy_efficiency) |
| Global hız | 1 + .20·I_omega_core + .05·l_global_logistics |
| Ek district | l_planetary_architecture, kapasiteye bağlantı koşullu |

omega_core ve global_logistics getter'larda okunuyor ancak satın alınabilir düğüm tanımı yok. Bu yüzden normal oyunda katkıları 0.

Housing/science income ve generator_efficiency çok seviyeli tanımlandığı hâlde sadece açık/kapalı kontrolüyle bonus verir. L2 ve sonrası bu etkileri büyütmez. Üç maintenance araştırmasında da çalışan enerji yolu skill seviyesini kullanmadan sabit .10 indirir.

power_transmission açıklaması -%5, gerçek global etki -%15'tir. get_trade_maintenance_mult seviye başına -%10 hesaplar ama üretim hesabı bu getter'ı çağırmaz.

Gezegen uzmanlıklarının 16 pasif düğümünde (ice_*, desert_*, gas_* ve volcanic_* pasifleri) yazılı hız/verim/menzil etkilerini uygulayan okuma bulunmuyor. Parent kilidini açmaları ayrı bir faydadır; vaat edilen üretim bonusu uygulanmıyor.

### 9.3. Tüm araştırma düğümleri

Aşağıdaki 119 satırda “vaat” oyundaki effect_desc alanıdır, doğrulanmış etki değildir. “Gerçek” sütunu bu ayrımı açıklar. Taban fiyat bilimdir. Maksimuma toplam maliyet sıfırdan hesaplanmıştır; başlangıçta verilmiş düğümlerde başlangıç indirimi yukarıdadır. Parent listesinde virgül **VEYA** anlamındadır.

| Kimlik / ad | Taban bilim | Max L | Toplam bilim | Tier | Parent (VEYA) | Yazılı vaat | Gerçek etki / sınır |
|---|---:|---:|---:|---:|---|---|---|
| `root` / Central Core | 0 | 1 | 0 | 1 | yok | Unlocks basic structures | Başlangıç düğümü |
| `unlock_space_station` / Orbital Facilities | 300 | 10 | 16500 | 2 | root | Unlocks Space Station District | Solar erişimi ve Station açılır; sonraki seviyeler kapasite artırmaz |
| `unlock_orbital_shipyard` / Orbital Shipyard | 1000 | 10 | 55000 | 3 | unlock_space_station | Unlocks Orbital Shipyard | orbital_shipyard açılır; skill seviyesi bina tavanı |
| `unlock_orbital_offworld_market` / Offworld Trade Hub | 5000 | 10 | 275000 | 4 | unlock_orbital_shipyard | Unlocks Offworld Trade Hub | orbital_offworld_market açılır; skill seviyesi bina tavanı |
| `unlock_orbital_mirrors` / Orbital Mirrors | 2000 | 10 | 110000 | 3 | unlock_space_station | Unlocks Orbital Mirrors | orbital_mirrors açılır; skill seviyesi bina tavanı; inşaatı ilerlemez |
| `unlock_moon` / Moon Outpost | 500 | 1 | 500 | 3 | unlock_space_station | Unlocks Moon Outpost | Moon erişimini açar |
| `unlock_lunar_observatory` / Lunar Observatory | 1500 | 10 | 82500 | 4 | unlock_moon | Unlocks Lunar Observatory | lunar_observatory açılır; skill seviyesi bina tavanı; üretim mantığı eksik |
| `unlock_moon_helium3` / Helium-3 Extractor | 1500 | 10 | 82500 | 4 | unlock_moon | Unlocks Helium-3 Extractor | moon_helium3 açılır; skill seviyesi bina tavanı |
| `unlock_asteroids` / Deep Space Tracking | 1200 | 1 | 1200 | 4 | unlock_moon | Unlocks Asteroid Mining | Asteroid tarama düğmesini açar |
| `unlock_asteroid_harvester` / Asteroid Harvester | 3000 | 1 | 3000 | 5 | unlock_asteroids | Unlocks Asteroid Harvester | asteroid_harvester açılır; bina tavanı 1; üretim mantığı eksik |
| `unlock_planetary_colonization` / Planetary Colonization | 2000 | 1 | 2000 | 5 | unlock_asteroids | Unlocks Specialized Colonization | Alt dalların parent'ı; kolonizasyon çağrısı bunu kontrol etmez |
| `colonize_ice` / Cryo-Habitation | 2500 | 1 | 2500 | 5 | unlock_planetary_colonization | Unlocks Ice Planet Colonization | Alt dallara parent; gezegen kolonizasyonunda tür kilidi uygulanmıyor |
| `unlock_ice_science` / Subglacial Laboratory | 3500 | 10 | 192500 | 4 | colonize_ice | Unlocks Subglacial Laboratory | ice_science açılır; skill seviyesi bina tavanı; üretim mantığı eksik |
| `ice_extraction` / Cryo-Extraction | 1500 | 5 | 22500 | 4 | colonize_ice | +20% Mine Speed on Ice Planets | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `ice_logistics` / Cryo-Logistics | 1500 | 5 | 22500 | 4 | colonize_ice | -10% Energy Cost on Ice Planets | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `unlock_cryo_vault` / Cryo-Vault Architecture | 4000 | 10 | 220000 | 6 | ice_logistics, ice_extraction | Unlocks Cryo-Vault | cryo_vault açılır; skill seviyesi bina tavanı; inşaatı ilerlemez |
| `colonize_desert` / Arid Habitation | 2500 | 1 | 2500 | 5 | unlock_planetary_colonization | Unlocks Desert Planet Colonization | Alt dallara parent; gezegen kolonizasyonunda tür kilidi uygulanmıyor |
| `desert_solar_cost` / Arid Mirrors | 1500 | 5 | 22500 | 4 | colonize_desert | -10% Solar Matrix Cost | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `unlock_arid_housing` / Subterranean Arcology | 3000 | 10 | 165000 | 4 | colonize_desert | Unlocks Subterranean Arcology | arid_housing açılır; skill seviyesi bina tavanı; inşaatı ilerlemez |
| `desert_solar_output` / Arid Photovoltaics | 1500 | 5 | 22500 | 4 | colonize_desert | +20% Solar Energy on Desert | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `unlock_arid_trade` / Spice Exchange | 3500 | 10 | 192500 | 4 | colonize_desert | Unlocks Spice Exchange | arid_trade açılır; skill seviyesi bina tavanı; üretim mantığı eksik |
| `unlock_solar_matrix` / Solar Matrix | 4000 | 10 | 220000 | 6 | desert_solar_output, desert_solar_cost | Unlocks Solar Matrix | solar_matrix açılır; skill seviyesi bina tavanı |
| `colonize_gas` / Atmospheric Harvesters | 2500 | 1 | 2500 | 5 | unlock_planetary_colonization | Unlocks Gas Planet Colonization | Alt dallara parent; gezegen kolonizasyonunda tür kilidi uygulanmıyor |
| `gas_siphon_speed` / Aero-Siphon | 1500 | 5 | 22500 | 4 | colonize_gas | +20% Siphon Speed | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `gas_siphon_yield` / Aero-Condenser | 1500 | 5 | 22500 | 4 | colonize_gas | +20% Siphon Output | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `unlock_atmospheric_siphon` / Atmospheric Siphon | 2500 | 10 | 137500 | 4 | gas_siphon_speed, gas_siphon_yield | Unlocks Atmospheric Siphon (Gas Giant) | atmospheric_siphon açılır; skill seviyesi bina tavanı |
| `gas_refinery_speed` / Pressure Refining | 1500 | 5 | 22500 | 4 | unlock_atmospheric_siphon | +20% Refinery Speed | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `gas_refinery_yield` / Pressure Condensation | 1500 | 5 | 22500 | 4 | unlock_atmospheric_siphon | +20% Refinery Output | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `unlock_aerosol_refinery` / Aerosol Refinery | 3000 | 10 | 165000 | 4 | gas_refinery_speed, gas_refinery_yield | Unlocks Aerosol Refinery (Gas Giant) | aerosol_refinery açılır; skill seviyesi bina tavanı |
| `gas_funnel_boost` / Vortex Funnel | 1500 | 5 | 22500 | 4 | unlock_aerosol_refinery | +10% Funnel Boost Multiplier | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `gas_funnel_range` / Vortex Reach | 1500 | 5 | 22500 | 4 | unlock_aerosol_refinery | +1 Range to Pressure Funnel | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `unlock_pressure_funnel` / Pressure Funnel | 2000 | 10 | 110000 | 5 | gas_funnel_boost, gas_funnel_range | Unlocks Pressure Funnel | pressure_funnel açılır; skill seviyesi bina tavanı |
| `colonize_volcanic` / Thermal Shielding | 2500 | 1 | 2500 | 5 | unlock_planetary_colonization | Unlocks Volcanic Planet Colonization | Alt dallara parent; gezegen kolonizasyonunda tür kilidi uygulanmıyor |
| `volcanic_dredge_speed` / Magma Flow | 1500 | 5 | 22500 | 4 | colonize_volcanic | +20% Dredge Speed | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `volcanic_dredge_yield` / Magma Filtering | 1500 | 5 | 22500 | 4 | colonize_volcanic | +20% Dredge Output | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `unlock_magma_dredge` / Magma Dredge | 2500 | 10 | 137500 | 4 | volcanic_dredge_speed, volcanic_dredge_yield | Unlocks Magma Dredge (Volcanic) | magma_dredge açılır; skill seviyesi bina tavanı |
| `unlock_geothermal_plant` / Geothermal Plant | 4000 | 10 | 220000 | 6 | volcanic_dredge_yield | Unlocks Geothermal Plant | geothermal_plant açılır; skill seviyesi bina tavanı |
| `volcanic_forge_speed` / Pyro-Smelting | 1500 | 5 | 22500 | 4 | unlock_magma_dredge | +20% Forge Speed | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `volcanic_forge_yield` / Pyro-Casting | 1500 | 5 | 22500 | 4 | unlock_magma_dredge | +20% Forge Output | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `unlock_pyroclastic_forge` / Pyroclastic Forge | 3000 | 10 | 165000 | 4 | volcanic_forge_speed, volcanic_forge_yield | Unlocks Pyroclastic Forge (Volcanic) | pyroclastic_forge açılır; skill seviyesi bina tavanı |
| `volcanic_stab_boost` / Tectonic Resonance | 1500 | 5 | 22500 | 4 | unlock_pyroclastic_forge | +10% Stabilizer Boost Multiplier | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `volcanic_stab_range` / Tectonic Wave | 1500 | 5 | 22500 | 4 | unlock_pyroclastic_forge | +1 Range to Tectonic Stabilizer | Yazılı pasif uygulanmıyor; alt düğümlere parent olabilir |
| `unlock_tectonic_stabilizer` / Tectonic Stabilizer | 2000 | 10 | 110000 | 5 | volcanic_stab_boost, volcanic_stab_range | Unlocks Tectonic Stabilizer | tectonic_stabilizer açılır; skill seviyesi bina tavanı |
| `unlock_interstellar` / Interstellar Travel | 10000 | 999 | 4995000000 | 7 | unlock_planetary_colonization | Discovers 1 New Star System per level | İlk seviye Galaxy açar; sonraki seviyeler yeni sistem açmıyor |
| `unlock_library` / Archival Systems | 150 | 10 | 8250 | 2 | unlock_lab | Unlocks Library | library açılır; skill seviyesi bina tavanı |
| `science_income_1` / Educational Grants | 300 | 5 | 4500 | 2 | unlock_lab | +15% Global Science output. | Açıkken +%15 bilim; sonraki seviyeler etkisiz |
| `unlock_advanced_lab` / Advanced Research | 500 | 10 | 27500 | 3 | science_income_1 | Unlocks Institute of Technology | advanced_lab açılır; skill seviyesi bina tavanı |
| `unlock_observatory` / Deep Space Optics | 800 | 10 | 44000 | 3 | unlock_advanced_lab | Unlocks Observatory | observatory açılır; skill seviyesi bina tavanı |
| `science_income_2` / Unified Theory | 1200 | 5 | 18000 | 4 | unlock_advanced_lab | +20% Global Science output. | Açıkken +%20 bilim; sonraki seviyeler etkisiz |
| `unlock_research_academy` / Research Academy | 2000 | 10 | 110000 | 4 | science_income_2 | Unlocks Research Academy | research_academy açılır; skill seviyesi bina tavanı; üretim mantığı eksik |
| `unlock_research_nexus` / Scientific Nexus | 3500 | 10 | 192500 | 5 | unlock_research_academy | Unlocks Research Nexus | research_nexus açılır; skill seviyesi bina tavanı |
| `science_maintenance` / Energy Conservation | 5000 | 5 | 75000 | 5 | unlock_research_academy | -10% Energy consumption for Science buildings | SCIENCE çıktılarda sabit -.10 enerji çarpanı |
| `unlock_mining` / Mining Operations | 20 | 10 | 1170 | 1 | root | Unlocks Mining District & Mine & +1 Max Level | mine açılır; skill seviyesi bina tavanı |
| `unlock_deep_drill` / Deep Drill | 200 | 10 | 11000 | 2 | unlock_mining | Unlocks Deep Drill | deep_drill açılır; skill seviyesi bina tavanı |
| `unlock_precision_extractor` / Precision Extractor | 1000 | 10 | 55000 | 3 | unlock_deep_drill | Unlocks Precision Extractor | precision_extractor açılır; skill seviyesi bina tavanı |
| `unlock_mantle_cracker` / Mantle Cracker | 3000 | 10 | 165000 | 4 | unlock_precision_extractor | Unlocks Mantle Cracker | mantle_cracker açılır; skill seviyesi bina tavanı |
| `unlock_quantum_harvester` / Quantum Harvester | 10000 | 10 | 550000 | 5 | unlock_mantle_cracker | Unlocks Quantum Harvester | quantum_harvester açılır; skill seviyesi bina tavanı |
| `unlock_refinery` / Refinery | 400 | 10 | 22000 | 2 | unlock_deep_drill | Unlocks Refinery | refinery açılır; skill seviyesi bina tavanı |
| `unlock_plasma_smelter` / Plasma Smelter | 1500 | 10 | 82500 | 3 | unlock_refinery | Unlocks Plasma Smelter | plasma_smelter açılır; skill seviyesi bina tavanı |
| `unlock_molecular_forge` / Molecular Forge | 5000 | 10 | 275000 | 4 | unlock_plasma_smelter | Unlocks Molecular Forge | molecular_forge açılır; skill seviyesi bina tavanı |
| `unlock_singularity_forge` / Singularity Forge | 15000 | 10 | 825000 | 5 | unlock_molecular_forge | Unlocks Singularity Forge | singularity_forge açılır; skill seviyesi bina tavanı |
| `mine_speed` / Excavation Drills | 50 | 10 | 2750 | 2 | unlock_deep_drill | +5% Mining speed per level | 9.2 formülünde seviye ile uygulanır |
| `deep_mining` / Seismic Sensors | 350 | 10 | 19250 | 3 | unlock_deep_drill | +2% Mine output multiplier per level | 9.2 formülünde seviye ile uygulanır |
| `mining_logistics` / Automated Conveyors | 900 | 10 | 49500 | 4 | deep_mining | -2% Mining Energy Cost per level | 9.2 formülünde seviye ile uygulanır |
| `refinery_efficiency` / Refinery Optimization | 450 | 10 | 24750 | 3 | unlock_refinery | +5% Refinery speed per level | 9.2 formülünde seviye ile uygulanır |
| `unlock_extraction_optimizer` / Extraction Optimizer | 800 | 10 | 44000 | 3 | mine_speed | Unlocks Extraction Optimizer | extraction_optimizer açılır; skill seviyesi bina tavanı |
| `unlock_sonic_resonator` / Sonic Resonator | 1200 | 10 | 66000 | 3 | unlock_quantum_harvester | Unlocks Sonic Resonator | sonic_resonator açılır; skill seviyesi bina tavanı |
| `unlock_thermal_crusher` / Thermal Crusher | 1200 | 10 | 66000 | 3 | unlock_mantle_cracker | Unlocks Thermal Crusher | thermal_crusher açılır; skill seviyesi bina tavanı |
| `unlock_logistics_hub` / Logistics Hub | 1800 | 10 | 99000 | 4 | unlock_plasma_smelter | Unlocks Logistics Hub | logistics_hub açılır; skill seviyesi bina tavanı |
| `unlock_micro_g_drill` / Micro-G Drill | 1200 | 10 | 66000 | 3 | unlock_asteroids | Unlocks Micro-G Drill (Asteroid) | micro_g_drill açılır; skill seviyesi bina tavanı |
| `unlock_zero_g_sorter` / Zero-G Sorter | 1500 | 10 | 82500 | 4 | unlock_micro_g_drill | Unlocks Zero-G Sorter | zero_g_sorter açılır; skill seviyesi bina tavanı |
| `unlock_culture_center` / Cultural Investments | 150 | 10 | 8250 | 2 | unlock_residential | Unlocks Culture Center | culture_center açılır; skill seviyesi bina tavanı |
| `housing_income_1` / Subsidized Housing | 300 | 5 | 4500 | 2 | unlock_residential | +15% Global credit payout from all housing. | Bütün kredi çıktısına sabit +%15; sonraki seviyeler etkisiz |
| `unlock_apartments` / Apartments | 500 | 10 | 27500 | 3 | housing_income_1 | Unlocks Apartments | apartments açılır; skill seviyesi bina tavanı |
| `unlock_recreation_center` / Public Entertainment | 800 | 10 | 44000 | 3 | unlock_apartments | Unlocks Recreation Center | recreation_center açılır; skill seviyesi bina tavanı |
| `housing_income_2` / Urban Sprawl | 1200 | 5 | 18000 | 4 | unlock_apartments | +20% Global credit payout from all housing. | Bütün kredi çıktısına sabit +%20; sonraki seviyeler etkisiz |
| `unlock_luxury_complex` / Luxury Complex | 2000 | 10 | 110000 | 4 | housing_income_2 | Unlocks Luxury Complex | luxury_complex açılır; skill seviyesi bina tavanı |
| `unlock_opera_house` / High Society | 3500 | 10 | 192500 | 5 | unlock_luxury_complex | Unlocks Opera House | opera_house açılır; skill seviyesi bina tavanı |
| `housing_maintenance` / Self-Sustaining Architecture | 5000 | 5 | 75000 | 5 | unlock_luxury_complex | -10% Energy consumption for City buildings | CITY'ye uygun binalarda sabit -.10 enerji çarpanı |
| `unlock_market_square` / Market Square | 30 | 10 | 1650 | 2 | root | Unlocks Market Square | market_square açılır; skill seviyesi bina tavanı |
| `trade_income_1` / Free Trade Agreement | 300 | 5 | 4500 | 2 | unlock_market_square | +15% Global credit output from Trade | 9.2 formülünde seviye ile uygulanır |
| `unlock_trading_post` / Trading Post | 500 | 10 | 27500 | 3 | trade_income_1 | Unlocks Trading Post | trading_post açılır; skill seviyesi bina tavanı |
| `unlock_customs_office` / Customs Authority | 800 | 10 | 44000 | 3 | unlock_trading_post | Unlocks Customs Office | customs_office açılır; skill seviyesi bina tavanı; inşaatı ilerlemez |
| `trade_income_2` / Interplanetary Commerce | 1200 | 5 | 18000 | 4 | unlock_trading_post | +20% Global credit output from Trade | 9.2 formülünde seviye ile uygulanır |
| `unlock_financial_district` / Financial District | 2000 | 10 | 110000 | 4 | trade_income_2 | Unlocks Financial District | financial_district açılır; skill seviyesi bina tavanı |
| `unlock_logistics_center` / Planetary Logistics | 3500 | 10 | 192500 | 4 | unlock_financial_district | Unlocks Logistics Center | logistics_center açılır; skill seviyesi bina tavanı; inşaatı ilerlemez |
| `trade_speed` / High-Frequency Trading | 5000 | 5 | 75000 | 5 | unlock_financial_district | +10% Global Trade Speed | 9.2 formülünde seviye ile uygulanır |
| `unlock_commodities_exchange` / Commodities Exchange | 8000 | 10 | 440000 | 5 | trade_speed | Unlocks Commodities Exchange | commodities_exchange açılır; skill seviyesi bina tavanı |
| `unlock_central_bank` / Central Banking | 12000 | 10 | 660000 | 5 | unlock_commodities_exchange | Unlocks Central Bank | central_bank açılır; skill seviyesi bina tavanı; inşaatı ilerlemez |
| `trade_maintenance` / Corporate Subsidies | 15000 | 5 | 225000 | 6 | unlock_commodities_exchange | -10% Energy consumption for Trade | CITY'ye uygun olmayan kredi binalarında sabit -.10 |
| `unlock_orbital_trade_port` / Orbital Trade Port | 25000 | 10 | 1375000 | 6 | trade_maintenance | Unlocks Orbital Trade Port | orbital_trade_port açılır; skill seviyesi bina tavanı |
| `unlock_orbital_logistics` / Orbital Logistics | 28000 | 10 | 1540000 | 6 | unlock_orbital_trade_port | Unlocks Orbital Logistics Hub | orbital_logistics açılır; skill seviyesi bina tavanı; inşaatı ilerlemez |
| `planetary_architecture` / Planetary Architecture | 30000 | 3 | 180000 | 6 | unlock_orbital_trade_port | +1 Max District | Seviye başına +1 tanımı; kapasite bağlantısı sorunlu |
| `unlock_command_center` / Planetary Command | 40000 | 1 | 40000 | 6 | planetary_architecture | Unlocks Command Center | command_center açılır; bina tavanı 1; inşaatı ilerlemez |
| `unlock_interstellar_syndicate` / Interstellar Syndicate | 50000 | 10 | 2750000 | 7 | unlock_orbital_trade_port | Unlocks Interstellar Syndicate | interstellar_syndicate açılır; skill seviyesi bina tavanı |
| `unlock_generator` / Thermal Plant | 100 | 10 | 5500 | 2 | unlock_solar_panel | Unlocks Thermal Generator. | generator açılır; skill seviyesi bina tavanı |
| `solar_efficiency` / Solar Arrays | 50 | 5 | 750 | 2 | unlock_generator | +10% Solar Array output | 9.2 formülünde seviye ile uygulanır |
| `generator_efficiency` / Heat Capture Loops | 250 | 5 | 3750 | 3 | unlock_generator | +5% Generator Energy output | Generator havuzuna sabit +%5; sonraki seviyeler etkisiz |
| `power_transmission` / Superconducting Grid | 400 | 1 | 400 | 3 | unlock_generator | -5% Energy consumption on all buildings | Global enerji talebine -%15, vaat -%5 |
| `supercharged_generators` / Plasma Ignition | 800 | 10 | 44000 | 4 | generator_efficiency | +2% Generator Energy output | 9.2 formülünde seviye ile uygulanır |
| `energy_efficiency` / Zero-Point Regulators | 800 | 5 | 12000 | 4 | power_transmission | -2% global energy consumption | 9.2 formülünde seviye ile uygulanır |
| `unlock_fusion_reactor` / Fusion Reactor | 1000 | 10 | 55000 | 4 | power_transmission, generator_efficiency | Unlocks Fusion Reactor. | fusion_reactor açılır; skill seviyesi bina tavanı |
| `find_available_star` / Find Available Star | 9999999 | 1 | 9999999 | 6 | dyson_swarm_dummy | Required for Dyson Swarm. | Parent dyson_swarm_dummy yok; satın alınamaz |
| `dyson_swarm` / Dyson Swarm Blueprint | 50000 | 1 | 50000 | 5 | unlock_fusion_reactor, find_available_star | +100% Solar Array output | Solar havuzuna +1; OR koşulu yıldız şartını aşar |
| `unlock_thermic_burner` / Thermic Burner | 400 | 10 | 22000 | 3 | unlock_generator | Unlocks Thermic Burner. | thermic_burner açılır; skill seviyesi bina tavanı |
| `thermic_mastery` / Thermic Mastery | 300 | 10 | 16500 | 3 | unlock_thermic_burner | +2% Generator Output | 9.2 formülünde seviye ile uygulanır |
| `unlock_plasma_reactor` / Plasma Reactor | 1200 | 10 | 66000 | 4 | unlock_thermic_burner | Unlocks Plasma Reactor. | plasma_reactor açılır; skill seviyesi bina tavanı |
| `plasma_mastery` / Plasma Mastery | 800 | 10 | 44000 | 4 | unlock_plasma_reactor | +2% Generator Output | 9.2 formülünde seviye ile uygulanır |
| `unlock_antimatter_chamber` / Antimatter Chamber | 4000 | 10 | 220000 | 5 | unlock_plasma_reactor | Unlocks Antimatter Chamber. | antimatter_chamber açılır; skill seviyesi bina tavanı |
| `antimatter_mastery` / Antimatter Mastery | 2500 | 10 | 137500 | 5 | unlock_antimatter_chamber | +2% Generator Output | 9.2 formülünde seviye ile uygulanır |
| `unlock_singularity_core` / Singularity Core | 10000 | 10 | 550000 | 6 | unlock_antimatter_chamber | Unlocks Singularity Core. | singularity_core açılır; skill seviyesi bina tavanı |
| `singularity_mastery` / Singularity Mastery | 8000 | 10 | 440000 | 6 | unlock_singularity_core | +2% Generator Output | 9.2 formülünde seviye ile uygulanır |
| `unlock_circuit_overloader` / Circuit Overloader | 600 | 10 | 33000 | 3 | solar_efficiency | Unlocks Circuit Overloader. Boosts district Solar output by +3%. | circuit_overloader açılır; skill seviyesi bina tavanı |
| `unlock_magma_resonator` / Magma Resonator | 1200 | 10 | 66000 | 4 | supercharged_generators | Unlocks Magma Resonator. Boosts district Geothermal output by +2%. | magma_resonator açılır; skill seviyesi bina tavanı |
| `unlock_grid_optimizer` / Grid Optimizer | 2000 | 10 | 110000 | 5 | unlock_fusion_reactor | Unlocks Grid Optimizer. Boosts all district clean energy by +1%. | grid_optimizer açılır; skill seviyesi bina tavanı |
| `unlock_combustion_stabilizer` / Combustion Stabilizer | 1500 | 10 | 82500 | 4 | plasma_mastery | Unlocks Combustion Stabilizer. Extends district burner fuel duration by +5%. | combustion_stabilizer açılır; skill seviyesi bina tavanı |
| `unlock_solar_panel` / Energy Operations | 50 | 10 | 2750 | 1 | root | Unlocks Solar Panel & +1 Max Level | solar_panel açılır; skill seviyesi bina tavanı |
| `unlock_residential` / Habitation Operations | 50 | 10 | 2750 | 1 | root | Unlocks Residential & +1 Max Level | residential açılır; skill seviyesi bina tavanı |
| `unlock_lab` / Research Operations | 100 | 10 | 5500 | 1 | root | Unlocks University & +1 Max Level | lab açılır; skill seviyesi bina tavanı |

### 9.4. Açılma yolunda boşa giden seviyeler

unlock_space_station için 10 seviye vardır fakat orbital kapasite skill seviyesinden değil gezegen seviyesinden gelir. zero_g_nexus bu skill'e bağlı görünür ancak bina seviye getter'ı unlock_zero_g_nexus arar; böyle düğüm yoktur.

unlock_interstellar 999 seviyeye izin verir. Sıfırdan 999'a toplam 4,995,000,000 bilimdir; L1 sonrası yeni yıldız açan mekanizma yoktur. Aynı düğümün 999 seviyeye çıkarılabilmesi evrenin 999 sistem içerdiği anlamına gelmez.

find_available_star parent'ı bulunmayan bir düğümdür. Dyson Swarm'ın iki parent'ından yalnız Fusion Reactor yettiği için yıldız araştırması zorunlu değildir. Gerçek megayapı inşaat projesi bulunmaz; satın alma doğrudan solar çarpanı artırır.

## 10. Keşif, kolonizasyon ve evren ölçeği

### 10.1. Mevcut evren büyüklüğü

- Tek GalaxyData içinde 34 yıldız sistemi vardır; ana sistem indeks 0.
- Her sistem 3..6 ana gezegen üretir. Homojen çekilişin ortalaması 4.5, bütün galakside beklenen ana gezegen sayısı 153'tür. Minimum 102, maksimum 204.
- Aylar ve taranan asteroidler buna eklenir.
- Galaksiler arasında geçiş veya yeni galaksi üretimini açan bir ilerleme katmanı yoktur.
- Bağlantılar önce bütün yıldızları bağlayan en kısa ağaçla oluşturulur. Daha sonra yıldız başına yaklaşık %30 olasılıkla kısa ek bağlantı denenir.
- Yıldız mesafesi 55..580 harita birimi; %25 olasılıkla ×0.35. Bu uzaklık kredi/yakıt yol maliyeti değildir.
- Kaynak rarity'sini etkileyen mesafe, geometrik uzaklık değil ana sistemden en az bağlantı sayısıdır.

### 10.2. Gezegen türleri ve uydular

| Ana gezegen ilk çekilişi | Olasılık | Ay adedi, eşit olasılıklı |
|---|---:|---|
| Barren | %22 | 0..1 |
| Arid | %20 | 0 |
| Ice | %18 | 0..2 |
| Volcanic | %18 | 0..1 |
| Gas Giant | %17 | 0..3 |
| Terran | %5 | 0..2 |

İç yörüngede orbit_ratio<0.35 ve ilk tür Gas Giant ise seed+3 ile bir kez yeniden oluşturulur. Yeni çekiliş yine gas olabilir; “iç yörüngede gas imkânsız” kuralı yok. Bu nedenle tabloda verilenler bütün son gezegenlerin kesin dağılımı değil ilk çekiliş oranlarıdır.

Ana sistem oluşturulurken gas giant garanti edilmeye çalışılır, sonra rastgele bir slot ana Terran ile değiştirilir. Eğer seçilen slot tek gas giant ise son sistemde gas kalmayabilir. Ana Terran uyduları ayrıca tam olarak 1'e zorlanır.

Galaxy yıldız türleri: Red Dwarf %30, Yellow Dwarf %30, Orange Subgiant %20, Blue Giant %10, White Dwarf %10. Ana yıldız Yellow Dwarf. SolarData'nın bağımsız yıldız çekilişi %40/%30/%20/%10 (Yellow/Red/Orange/Blue), galaksi üzerinden girildiğinde GalaxyData tipi üzerine yazılır. İkili yıldız olasılığı %25, eşlikçi türü Red/White/Orange eşit olasılıklıdır. Yıldız türünün üretime bağlı ekonomik çarpanı yok.

### 10.3. Keşif maliyetleri ve erişim

| İşlem | Maliyet | Süre / sonuç |
|---|---:|---|
| Orbital Facilities L1 | 300 bilim | Solar erişimi ve Station district |
| Moon Outpost | 500 bilim | Ay erişimi |
| Deep Space Tracking | 1200 bilim | Asteroid tarama seçeneği |
| Planetary Colonization | 2000 bilim | Alt araştırma dalları |
| Interstellar Travel L1 | 10000 bilim | Galaxy erişimi |
| Bir asteroid açma | 5000 bilim | Anlık, sıradaki kuşağa +1 |
| Tam bir kuşak, 3 asteroid | 15000 bilim | 3 ayrı tarama |
| Survey System | 200000 kredi + 50000 bilim | Anlık, yıldızı surveyed yapar |
| Gezegen/ay/asteroid kolonizasyonu | 1000 kredi | 30 s; sonra ücretsiz City veya Moon için Outpost |

İlk Galaxy açılmasının exploration hattında toplam bilim maliyeti 300+500+1200+2000+10000=14000. Bu yalnız araştırma maliyeti; bilim üreten altyapı, koloniler ve survey bunun dışındadır.

Galaxy'de açık yıldızlar ve onlara komşu yıldızlar görünür. Görünür fakat survey edilmemiş yıldıza girmek serbesttir; girişte gemi/yakıt/zaman maliyeti yok. SolarView erişim kontrolü ana gezegenler için solar_unlocked, uydular için moon_unlocked kullanır.

Tür bazlı colonize_ice/desert/gas/volcanic araştırmaları kolonizasyon düğmesinde veya GameState.colonize_planet içinde doğrulanmaz. Bunlar mevcut hâliyle alt bina araştırmalarına kapı açar; belirtilen gezegen türünü kolonize etmenin zorunlu şartı değildir.

Survey yapılmadan görülen bir sisteme girip gezegeni kolonize etmek mümkündür. Sistem yeniden gösterilirken herhangi bir gezegende custom_pois bulunması sistemi otomatik unlock eder. Bu, pahalı survey ödemesini aşan bir yol oluşturur.

### 10.4. Asteroid kimliği ve tarama

Sistem başına 1 veya 2 kuşak denemesi vardır. İkinci deneme aynı aralığı seçerse tekrar çekilmediğinden sonuç tek kuşak olabilir. N gezegen için iki farklı kuşak olasılığı `0.5 × (1-1/(N-1))`; beklenen kuşak sayısı `1.5-0.5/(N-1)`. N=3..6 için 1.25..1.40 aralığındadır.

Kuşak başına 3 asteroid keşfedilir. Tarama rastgele kuşak seçmez, doymamış ilk kuşağı artırır. Tarama kayıt anahtarı sadece slot indeksidir; sistem kimliği içermez. Bir sistemde taranan slot başka sistemde aynı slotu da açılmış gösterebilir.

Gezegen görünümüne açılan asteroid seed'i `(asteroid_indeksi×0x1337) XOR int(ekrandaki_yörünge_yarıçapı) XOR 0xBEEF` üzerinden gelir. Sistem seed'i bu kimliğe dahil değil. Ayrıca system_hop taşınmıyor; varsayılan 0 kalıyor. Böylece asteroid kimliği ve yüksek rarity ilerlemesi sistemler arasında güvenilir değildir. Tür ASTEROID olarak sonradan atanır, eski rastgele türün diğer özellikleri yeniden ayarlanmaz.

### 10.5. Gezegen türü bonusları

| Tür | Maden hız | Maden çıktı | District ek | Slot ek | Enerji maliyet tanımı | Bina fiyat tanımı |
|---|---:|---:|---:|---:|---:|---:|
| Terran | 1 | 1 | +2 | 0 | .85 | 1 |
| Arid | .80 | 1 | -1 | 0 | .90 | 1 |
| Ice | 1 | 1.20 | 0 | -1 | 1.30 | 1 |
| Volcanic | 1.50 | 1.75 | -2 | 0 | 1.20 | 1 |
| Barren | 1.20 | 1 | -1 | 0 | 1 | .90 |
| Gas Giant | 1 | 0 | 0 | 0 | .70 | .80 |
| Moon | 1 | 1.30 | -2 | 0 | .75 | 1 |
| Asteroid | 3 | 1.75 | -3 | -1 | 1 | 1 |

**Uygulanan:** maden hız ve maden çıktı; çıktı çarpanı rafineriye de uygulanır.  
**Bağlı olmayan:** district/slot ekleri, enerji maliyeti ve bina fiyatı çarpanları.

Eşit maden havuzu ve enerji varsayımında genel ham verim oranı Terran=1, Arid=.8, Ice=1.2, Volcanic=2.625, Barren=1.2, Gas=0, Moon=1.3, Asteroid=5.25. Türün özel binaları bu karşılaştırmanın dışındadır.

Gas Giant “No Surface” çarpanı özel Atmospheric Siphon'a da uygulandığı için bu bina sıfır üretir. Aerosol Refinery de aynı çıktı çarpanından etkilenir.

## 11. Gemi ve görev sisteminin mevcut durumu

Bu sistem eski yerel lojistik modelinin önemli parçalarını hâlâ taşıyor. Global ekonomi için zorunlu taşıma hattı değil. Spaceport normal açılma yoluna bağlı olmadığından normal yeni oyunda erişilebilirliği yoktur; aşağıdaki mekanikler bu binanın başka yoldan açıldığı koşula aittir.

### 11.1. Fırlatma ve taşıma maliyetleri

| Gemi türü | Kapasite fonksiyonu | Fırlatma kredi maliyeti |
|---|---:|---|
| shuttle | 5 | 200 + 12W |
| hauler | 20 | 800 + 8W |
| heavy_hauler | 60 | 2500 + 5W |
| station | 60 | 5000 |

`W = Σ[(rarity+tier-1) × int(adet)]`. Görev panelinin bazı kapasite hesapları ise yalnız adet toplamını kullanıyor. Bir R5/T1 biriminin ağırlığı 5; miktar ve ağırlık aynı kapasite birimi gibi kullanılmamalıdır.

Gemi tip kaynağı olarak shuttle ve station dosyaları mevcut. Hauler/heavy_hauler fonksiyon dalları, tam açılabilir gemi ilerlemesi bulunduğunun kanıtı değildir. “Prepare Mission” yolu tipi shuttle olarak ayarlıyor.

Fazlar: idle → preparing → launch_ready → oyuncunun Launch seçimi → cooldown → idle.
- Hazırlık temel 20 s.
- Spaceport çevrim/cooldown temel 45 s.
- Fırlatma animasyonu 22×R_px/200 s.
- Station yerleşim animasyonu ek 2.2 s.
- Fırlatırken cooldown başlar; animasyonla ardışık toplamak doğru değildir.
- Hazırlık maliyeti ve yük peşin düşer.
- Yük düşümü max(0, stok-yük) yapar; istenen yük ile gerçek düşülen miktarı eşitleyen yeniden doğrulama yoktur.

### 11.2. Görev türleri

| Görev | Giriş durumu | Son durum | Panel tahmin maliyeti |
|---|---|---|---:|
| pick_planet | on_pad | on_pad | 0 |
| move_orbit | on_pad | in_orbit | 80 |
| move_station | on_pad veya in_orbit | at_station:hedef | 40 |
| pickup | move_station iç görevi | Aynı konum | 0 |
| deliver | move_station iç görevi | Aynı konum | 0 |
| land | in_orbit veya at_station | on_pad | 30 |
| deploy | in_orbit; station türü | Panelde on_pad | 0 |

Panel bunların tahmin toplamını gösterir; ödeme anında kullanılan formül yukarıdaki gemi/ağırlık tarifesidir. Örneğin boş shuttle “orbit + land” panelde 110 kredi, fiili launch ödeme yolu 200 kredidir.

Görev zinciri yerel yörünge/istasyon ilişkileri içerir. ShipManager.dispatch seyahat altyapısı vardır fakat mevcut görev akışından çağrılan bir gezegenler arası dispatch yolu bulunmadı. Dolayısıyla mesafeye göre gemi seyahat ekonomisi tamamlanmış sayılmamalıdır.

Rendezvous ekran izdüşümünde mesafe<gezegen_yarıçapı×0.07 olduğunda tamamlanır. Gemi hızı bu sırada ×2, orbit_node değişim adımı 1.2×delta'dır. Sabit ETA veya fiziksel yakıt modeli değildir.

İniş 1.2+2.8+1.4=5.4 saniyelik üç fazdır; gemi listeden silinir, taşıdığı yük global stoğa eklenir. Deliver alt görevi seçilen kısmi miktarı değil tüm gemi kargosunu hedefe aktarır. Pickup min(istenen, mevcut) alır; çalışma anında kapasite kontrolü yoktur.

repeat_cycle saklanıyor fakat zamanlayıp görevleri döndüren çalışan bir kullanım bulunmadı. Kuyruk tüketimi de görünüm oluşturma işlevindedir; ekrandan bağımsız bir otomasyon çekirdeği olarak değerlendirilmemelidir.

## 12. Kayıt, zaman ve idle davranışı

### 12.1. Zaman modeli

Üretim uygulama açık ve oyun ağacı çalışırken _process(delta) ile ilerler. Pause menüsü SceneTree.paused=true yapar; üretim durur. Yalnız görünüm gizlemek üretimi durdurmaz. Autoload üreticisi sahneden bağımsız olduğu için ana menüde de özel bir üretim durdurma kapısı yoktur.

Oyun kapalıyken geçen süreyi stoklara işleyen offline üretim hesabı bulunmuyor. Işık/gün-gece görsel zamanı ekonomik offline kazanç değildir. Gün-gece döngüsü solar enerjiyi azaltmaz veya artırmaz.

### 12.2. Kayıt içeriği

Otomatik kayıt aralığı 60 s. Çıkış bildirimi ve skill satın alma da kayıt çağırır.

Kaydedilenler: kredi/bilim, kaynak miktarları, açılmış bina/skill listeleri ve skill seviyeleri, gezegen seviyeleri, district seviyeleri/yükseltme ilerlemesi, gezegen yükseltme/kolonizasyon ilerlemesi, bina kayıtları, custom POI'ler, gemilerin temel durumları, tutorial ve achievement durumu.

Kaydedilmeyen veya eksik kalan ekonomik durum:
- ProductionManager çevrim ilerlemesi, bina inşaat ilerlemesi, kullanıcı kapatma ve otomatik duraklatma sözlükleri.
- known_resources ve mineral yoğunlukları.
- Ana sistem dışı gezegenin doğru türünü, system_hop'unu ve sistem bağını yeniden kurmaya yetecek tam dünya kaydı.
- GalaxyData.unlocked survey listesi.
- Gemilerin görev dizisi, görev indeksi, rendezvous ve station binaları.
- Offline geçen zaman ve üretim ödemesi.

### 12.3. Kaydın dengeye etkisi

1. _build_home_solar her dünya başlangıcında krediyi 1000'e ve solar/galaxy bayraklarını başlangıç değerlerine yazar. Yüklenmiş değerlerin üstüne yazılabilir.
2. Skill açık kalırken solar/galaxy erişimi kapanabilir; mevcut skill'i tekrar yükseltmek ilk alım yan etkisini yeniden çalıştırmaz.
3. İnşa edilen bina kaydı korunur ama ilerleme sözlüğü kaybolur: yeniden açılışta bina inşaatı baştan başlayabilir.
4. Çevrim başında alınan girdi stoktan düşmüştür; çevrim ilerlemesi kaybolunca yeniden girdi istenebilir.
5. Yabancı mineral stok kimliği kaydedilir ama known_resources yeniden kurulmamışsa arayüz ve ANY_T filtreleri bunu tanımayabilir.
6. Kayıttaki yabancı POI'ler için PlanetData.from_seed fallback kullanımı eski gezegen türü/hop'unu korumaz.
7. Yabancı sistemi yeniden ziyaret etmek yeni SolarData/PlanetData oluşturur; seed'e bağlı progress kaydı ile yeni boş custom_pois ayrışabilir.
8. delete_save kaynak/gezegen cache'lerini, ProductionManager sözlüklerini ve gemi listesini bütünüyle temizlemiyor. Aynı uygulama içinde yeni oyun ayrıca denenmelidir.
9. GameState autoload sırasında kendisinden sonra gelen SkillTree/TutorialManager/AchievementManager düğümlerine kayıt yükleme erişimi var. Başlatma sırasının gerçek motor sonucu ayrıca doğrulanmalıdır.

Bunlar giderilmeden uzun seanslar arasında ekonomik ilerlemenin tutarlı korunduğu varsayılamaz.

## 13. Sayısal denge karşılaştırmaları

Bu bölüm **hesaplanan** değerleri içerir. Aksi yazmadıkça L1, tek bina, bonus yok, tam enerji ve kesintisiz girdi varsayılmıştır. İnşaat, araştırma ve district maliyetleri geri dönüş hesabına dahil edilmediyse ayrıca belirtilir.

### 13.1. Seviye eğrisi

| Bina L | M(L) çıktı/destek | C(L) tüketim | Sonraki yükseltme, B katı | Bu seviyeye toplam yatırım, B katı |
|---|---:|---:|---:|---:|
| 1 | 1.0000 | 1.0000 | 1.0000 | 1.0000 |
| 2 | 1.5000 | 1.2500 | 1.5000 | 2.0000 |
| 3 | 1.7925 | 1.3962 | 2.2500 | 3.5000 |
| 4 | 2.0000 | 1.5000 | 3.3750 | 5.7500 |
| 5 | 2.1610 | 1.5805 | 5.0625 | 9.1250 |
| 6 | 2.2925 | 1.6462 | 7.5938 | 14.1875 |
| 7 | 2.4037 | 1.7018 | 11.3906 | 21.7813 |
| 8 | 2.5000 | 1.7500 | 17.0859 | 33.1719 |
| 9 | 2.5850 | 1.7925 | 25.6289 | 50.2578 |
| 10 | 2.6610 | 1.8305 | 38.4434 | 75.8867 |

Toplam yatırım formülü `B × (2×1.5^(L-1)-1)`. Bu formül bir binayı satın alıp tek tek yükseltme maliyetidir; ucuz yığın birleşme yolu bu eğriyi aşabilir.

L10 enerji/destek 2.661 kat, tüketim 1.8305 kat, toplam yatırım yaklaşık 75.887B. Aynı çevrim çıktısına M(L) uygulanmayan maden/kredi/bilim binalarında bu yatırımın vaat edilen verim geri dönüşü yoktur.

### 13.2. Erken enerji darboğazı

Residential + University talebi 4'tür.

| Solar Array sayısı | Enerji q | Residential kredi/s | University bilim/s |
|---|---:|---:|---:|
| 1 | .25 | .208333 | .020000 |
| 2 | .50 | .416667 | .040000 |
| 3 | .75 | .625000 | .060000 |
| 4 | 1 | .833333 | .080000 |

Bir L1 Generator Facility 3 slot taşır. Solar-only açılışta bu district tek başına konut+üniversiteyi tam besleyemez. Başka enerji kaynağı, district yükseltmesi, ikinci enerji district'i veya bina kapatma gerekir.

Yalnız bir University:
- 300 bilim: q=1 iken 3750 s = 62.5 dakika.
- q=.25 iken 15000 s = 250 dakika.
- Exploration araştırmalarının toplam 14000 bilimi: q=1 iken 48.61 saat.
- 5000 bilim asteroid taraması: q=1 iken 17.36 saat.
- 50000 bilim survey: q=1 iken 173.61 saat.

Bunlar “oyuncu kesin bu kadar bekler” tahmini değildir. Yeni bilim binaları, görev ödülleri, destekler ve yatırımlar olmayan sabit tek University referansıdır. Mevcut bilim ağacındaki üretimsiz binalar nedeniyle hızlanma basamakları ayrıca doğrulanmalıdır.

### 13.3. Konut ve basit ticaret

| Bina | Çıktı/çevrim | Temel çevrim s | Kredi/s | Kredi/dakika | Yalnız bina fiyatı geri dönüşü s |
|---|---:|---:|---:|---:|---:|
| residential | 50 | 60 | 0.833333 | 50.000 | 120.000 |
| apartments | 150 | 120 | 1.250000 | 75.000 | 200.000 |
| luxury_complex | 500 | 240 | 2.083333 | 125.000 | 576.000 |
| market_square | 15 | 10 | 1.500000 | 90.000 | 133.333 |
| commercial | 65 | 40 | 1.625000 | 97.500 | 307.692 |

Commercial normal açılma yolu olmayan referans tanımdır. Bina maliyeti geri dönüşü district, araştırma, enerji yatırımı ve inşaat bekleme süresini içermez.

Market Square düşük bilim kapısıyla açılır ve konutla aynı City slotlarını kullanır. L1 Market Square ile Residential aynı 1 slot ve 2 enerji kullanır; Market Square 1.5 kredi/s ile Residential'ın .833333 kredi/s değerinden %80 yüksektir. İlk fiyatı iki katıdır (200/100), çıplak geri dönüşü 133.333/120 saniyedir. Apartments 1.25 kredi/s üretirken 4 enerji ister; bu karşılaştırmada Market Square hem hız hem enerji bakımından avantajlıdır. Luxury Complex 2 slotta 2.083333 kredi/s, slot başına 1.041667 kredi/s verir; 12 enerji ister. Konutlara özel destekler, farklı fiyatlar ve ilk açılma maliyetleri bu üstünlükleri değiştirebilir.

University 1 slotta .08 bilim/s ve 2 enerji; Advanced Lab 1 slotta .333333 bilim/s ve 100 enerji verir. Advanced Lab slot başına 4.167 kat, enerji başına ise yaklaşık 12 kat daha düşük verimlidir. Global enerji kıtlığı sürüyorsa daha gelişmiş bilim binası toplam ekonomiyi yavaşlatabilir. Research Academy'nin nominal .222222 bilim/s değerini bu karşılaştırmaya çalışan üretici olarak katmak doğru değildir; logic bağlantısı eksiktir.

### 13.4. Ham üretim örneği

Ana gezegende R1/T1 power=2, R2/T1 power≈2.414214:
- Ortalama power≈2.207107.
- Deposit hızı≈0.882843.
- Mine etkin çevrimi: 18/0.882843≈20.388683 s.
- Toplam cevher≈0.490468/s, yani 29.428/dakika.
- R1≈0.435972/s; R2≈0.054496/s.
- L4 için 1000 T1 biriktirmek, sıfır stok ve tek Mine ile yaklaşık 2038.868 s =33.981 dakika.
- Bu sırada yakıt/ticaret/refinery tüketimi varsa bekleme uzar; q=.5 ise iki katına çıkar.

Ana sistemin normal tür havuzunda ilk maden garantili, üst madenler %65 olduğu için koloniler arası hem kaynak çeşitliliği hem ortalama power farkı oluşur. Kaynak sayısı arttıkça bütün nadirlerin eşit miktarda üretildiği varsayılmamalıdır.

### 13.5. Rafineri tarifelerinin tasarımsal oranı

Aşağıdaki oranlar yalnız tanımlı tarifelerdir. Mevcut işlenmiş kaynak kopukluğu düzeltilmeden gerçek T2..T5 üretim verimi değildir.

| Rafineri | Amaçlanan giriş tier | Girdi → çıktı | Çevrim s | Girdi/s | Çıktı/s | Bir üst ürünün giriş maliyeti |
|---|---:|---|---:|---:|---:|---:|
| aerosol_refinery | 1 | 20 → 10 | 20 | 1.000000 | 0.500000 | 2.000 |
| molecular_forge | 3 | 15 → 1 | 60 | 0.250000 | 0.016667 | 15.000 |
| plasma_smelter | 2 | 15 → 2 | 30 | 0.500000 | 0.066667 | 7.500 |
| pyroclastic_forge | 1 | 5 → 5 | 12 | 0.416667 | 0.416667 | 1.000 |
| refinery | 1 | 15 → 3 | 15 | 1.000000 | 0.200000 | 5.000 |
| singularity_forge | 4 | 15 → 1 | 120 | 0.125000 | 0.008333 | 15.000 |

Genel rafineri hattında tanımlı dönüşümler 15→3, 15→2, 15→1, 15→1'dir. Bonus yoksa bir T5'in teorik T1 ihtiyacı 5×7.5×15×15=8437.5 ham cevherdir. Bu kesirli stok sistemiyle ortalama maliyettir. T5 zinciri için zaman, ara stoklar, bina oranları ve enerji ayrıca gereklidir.

Üretim zinciri dengesi:
`net_stok_hızı = toplam_üretim_hızı - toplam_tüketim_hızı`.
Sürdürülebilirlik için her ara ürünün net hızı en az 0 olmalıdır. Stok yeterli olmadığında tüketiciler bina/koloni iterasyon sırasına göre kaynağa erişir; paylaştıran bir öncelik sistemi yoktur.

### 13.6. Enerji ve yakıt

L1 Thermic Generator: 100 kredi, 1 slot, 5 enerji, 30 s'de 5 T1.
- R1 yakıt: 1/6 birim/s, enerji başına 1/30 birim/s.
- R2 yakıt: 60 s'de 5, 1/12 birim/s.
- R8 yakıt: 240 s'de 5, 1/48 birim/s.
- Rarity arttıkça sürekli enerji kapasitesi 5 kalır.

L1 Solar Array: 150 kredi, 1 slot, 1 enerji, yakıt yok.
L1 Moon Helium-3 Extractor: 1000 kredi, 2 slot, 500 enerji, input_type=NONE. Açılma maliyeti 1500 bilim ve gezegen seviyesi 2 şartıyla birlikte düşünülmeli. Kaynağı yakmayan 500 enerji, solar başına 1 enerjiye kıyasla çok büyük bir sıçramadır. İsmi/izotop açıklaması yakıt tüketildiği anlamına gelmez.

Destek değerlendirme: k adet eşdeğer üreticinin her birine +b bonus veren tek destek, yalnız slot verimi açısından yeni üreticiye üstün olmak için yaklaşık `k×b>1` sağlamalıdır. Örneğin +%5 optimizer için k>20; +%15 library için k>6.667. District alanı küçükken destek, ek üreticiden daha az toplam çıktı sağlayabilir. Gerçek karşılaştırmada fiyat, enerji ve mevcut bonus havuzu da hesaba katılmalıdır.

### 13.7. Merkezi bina oranları

Bu tablo bütün pozitif çıktı tanımlarını karşılaştırır. Enerjide oran enerji/slot; diğerlerinde çıktı/saniye/slot. Nominal oranlara gezegen, skill, enerji, girdi ve destek eklenmemiştir. “0” durumu bağlı mantığın kesin eksikliğini; “zincir sorunlu” gerekli ürünün erişim sorununu belirtir.

| Bina | Çıktı türü | Nominal toplam/s veya enerji | Slot başına nominal | Enerji talebi | Fiili koşul |
|---|---|---:|---:|---:|---|
| advanced_lab | bilim | 0.333333 | 0.333333 | 100 | Bonus ve enerjiye göre değişir |
| aerosol_refinery | işlenmiş | 0.500000 | 0.500000 | 5 | Zincir sorunlu, T+1 üretmez |
| antimatter_chamber | enerji | 120.000000 | 120.000000 | 0 | Zincir sorunlu: işlenmiş girdi |
| apartments | kredi | 1.250000 | 1.250000 | 4 | Bonus ve enerjiye göre değişir |
| arid_trade | kredi | 13.333333 | 6.666667 | 10 | Çıktı 0: mantık yok |
| asteroid_harvester | ham | 25.000000 | 12.500000 | 50 | Çıktı 0: mantık yok |
| atmospheric_siphon | ham | 8.000000 | 8.000000 | 8 | Çıktı 0: gezegen çarpanı |
| commercial_hub | kredi | 5.000000 | 5.000000 | 10 | Çıktı 0: yanlış mantık |
| commercial | kredi | 1.625000 | 1.625000 | 6 | Bonus ve enerjiye göre değişir |
| commodities_exchange | kredi | 48.000000 | 24.000000 | 60 | Zincir sorunlu: işlenmiş girdi |
| data_center | bilim | 1.000000 | 1.000000 | 150 | Bonus ve enerjiye göre değişir |
| deep_drill | ham | 1.866667 | 1.866667 | 5 | Bonus ve enerjiye göre değişir |
| financial_district | kredi | 12.500000 | 12.500000 | 15 | Zincir sorunlu: işlenmiş girdi |
| fusion_reactor | enerji | 25.000000 | 12.500000 | 0 | Bonus ve enerjiye göre değişir |
| generator | enerji | 5.000000 | 5.000000 | 0 | Bonus ve enerjiye göre değişir |
| geothermal_plant | enerji | 10.000000 | 10.000000 | 0 | Bonus ve enerjiye göre değişir |
| ice_science | bilim | 0.833333 | 0.416667 | 40 | Çıktı 0: mantık yok |
| interstellar_syndicate | kredi | 777.777778 | 259.259259 | 1000 | Zincir sorunlu: işlenmiş girdi |
| lab | bilim | 0.080000 | 0.080000 | 2 | Bonus ve enerjiye göre değişir |
| lunar_observatory | bilim | 3.333333 | 3.333333 | 20 | Çıktı 0: mantık yok |
| luxury_complex | kredi | 2.083333 | 1.041667 | 12 | Bonus ve enerjiye göre değişir |
| magma_dredge | ham | 15.000000 | 15.000000 | 10 | Bonus ve enerjiye göre değişir |
| mantle_cracker | ham | 20.833333 | 20.833333 | 40 | Bonus ve enerjiye göre değişir |
| market_square | kredi | 1.500000 | 1.500000 | 2 | Bonus ve enerjiye göre değişir |
| micro_g_drill | ham | 3.333333 | 3.333333 | 15 | Bonus ve enerjiye göre değişir |
| mine | ham | 0.555556 | 0.555556 | 2 | Bonus ve enerjiye göre değişir |
| molecular_forge | işlenmiş | 0.016667 | 0.016667 | 60 | Zincir sorunlu, T+1 üretmez |
| moon_helium3 | enerji | 500.000000 | 250.000000 | 0 | Bonus ve enerjiye göre değişir |
| moon_observatory | bilim | 1.000000 | 0.500000 | 60 | Çıktı 0: mantık yok |
| orbital_offworld_market | kredi | 83.333333 | 41.666667 | 50 | Bonus ve enerjiye göre değişir |
| orbital_shipyard | kredi | 41.666667 | 20.833333 | 30 | Çıktı 0: yanlış mantık |
| orbital_trade_port | kredi | 200.000000 | 100.000000 | 200 | Zincir sorunlu: işlenmiş girdi |
| particle_accelerator | bilim | 1.111111 | 1.111111 | 250 | Boş kaynak anahtarıyla durur |
| plasma_reactor | enerji | 45.000000 | 45.000000 | 0 | Zincir sorunlu: işlenmiş girdi |
| plasma_smelter | işlenmiş | 0.066667 | 0.066667 | 25 | Zincir sorunlu, T+1 üretmez |
| precision_extractor | ham | 4.000000 | 4.000000 | 15 | Bonus ve enerjiye göre değişir |
| pyroclastic_forge | işlenmiş | 0.416667 | 0.416667 | 2 | Zincir sorunlu, T+1 üretmez |
| quantum_computer | bilim | 1.666667 | 1.666667 | 1000 | Boş kaynak anahtarıyla durur |
| quantum_harvester | ham | 100.000000 | 100.000000 | 120 | Bonus ve enerjiye göre değişir |
| refinery | işlenmiş | 0.200000 | 0.200000 | 8 | Zincir sorunlu, T+1 üretmez |
| research_academy | bilim | 0.222222 | 0.111111 | 30 | Çıktı 0: mantık yok |
| residential | kredi | 0.833333 | 0.833333 | 2 | Bonus ve enerjiye göre değişir |
| scanner | kredi | 0.181818 | 0.181818 | 3 | Bonus ve enerjiye göre değişir |
| singularity_core | enerji | 350.000000 | 350.000000 | 0 | Zincir sorunlu: işlenmiş girdi |
| singularity_forge | işlenmiş | 0.008333 | 0.008333 | 150 | Zincir sorunlu, T+1 üretmez |
| solar_matrix | enerji | 4.000000 | 4.000000 | 0 | Bonus ve enerjiye göre değişir |
| solar_panel | enerji | 1.000000 | 1.000000 | 0 | Bonus ve enerjiye göre değişir |
| thermic_burner | enerji | 15.000000 | 15.000000 | 0 | Zincir sorunlu: işlenmiş girdi |
| trading_post | kredi | 4.000000 | 4.000000 | 5 | Zincir sorunlu: işlenmiş girdi |
| zero_g_nexus | bilim | 0.666667 | 0.666667 | 10 | Çıktı 0: mantık yok |

## 14. Sorun listesi ve düzeltme öncelikleri

Burada “öncelik” oyunun matematiğine etkidir. Bütün maddeler bu incelemede düzeltilmiş değildir. P0 üretimi/ilerlemeyi bozan, P1 ekonomik sonucu veya erişimi ciddi biçimde değiştiren, P2 gösterim/izleme tutarsızlığı anlamındadır.

| No | Öncelik | Bulgu | Ekonomik sonuç | Kaynak / doğrulama |
|---|---|---|---|---|
| D01 | P0 | tick_duration≤0 kontrolü inşaat kontrolünden önce | 8 bina sonsuza kadar inşaatta kalır | ProductionManager._tick_all; yeni customs_office kurulumuyla motor testi |
| D02 | P0 | İşlenmiş kaynak havuzu üretilmiyor | T2..T5 ekonomi zinciri oluşmaz | BodyResources.generate, RefineryLogic.produce |
| D03 | P0 | ANY_T2 yalnız RAW_MINERAL kabul ediyor | L5 gezegen kapısı normal kaynaklarla geçilemez | PlanetaryView._show_level_up_popup |
| D04 | P0 | q=0 iken çevrim girdisi tekrar tekrar çekiliyor | Stok üretim olmadan kare hızına bağlı erir | ProductionManager._tick_all, girdi tüketimi enerji kontrolünden önce |
| D05 | P0 | Seviye çarpanı gerçek cevher/kredi/bilim çıktısında yok | Yükseltme gelir artırmadan tüketimi artırır | Dört üretim Logic dosyası, ProductionManager gösterim hesabı |
| D06 | P0 | Kayıt sonrası başlangıç kredi/bayrakları yeniden atanıyor | İlerleme gerileyebilir, düşük bakiye yeniden 1000 olabilir | GameState.load_save → _bootstrap_world → _build_home_solar |
| D07 | P1 | Bazı çıktı binalarında logic yok | Kaynak tanımı ve kart vaat etse de çıktı 0 | Bina kataloğu 8.3 |
| D08 | P1 | commercial_hub ve orbital_shipyard GeneratorLogic kullanıyor | Kredi üretmez | İlgili .tres ve GeneratorLogic.produce |
| D09 | P1 | Gas Giant çıktı çarpanı 0 özel binalara da uygulanıyor | Atmospheric Siphon ve Aerosol üretimi sıfır | PlanetModifier, MineLogic, RefineryLogic |
| D10 | P1 | Üst rafinerilerin girdi etiketi RAW, refined tüketicilerin fallback kimliği başka | Ürün zinciri düzelse bile giriş seçimleri tutarsız kalır | input_type/input_tier, _resource_key, mineral seçici |
| D11 | P1 | particle_accelerator ve quantum_computer input_type=2 | CREDITS enum'u boş kaynak kimliğine çözülür; üretim bekler | İlgili .tres, ProductionManager._resource_key |
| D12 | P1 | 7 binanın normal açılma yolu yok | İçeriğin bir bölümü, Spaceport dahil, kullanılamaz | SkillTree ile BuildingDef katalog karşılaştırması |
| D13 | P1 | Science POI'si için bina var, kurulabilir district yok | ice_science/moon_observatory yerleştirilemez | DistrictDef kataloğu, POI izinleri |
| D14 | P1 | 16 uzmanlık pasifi üretimde okunmuyor | Bilim harcaması yazılı bonusu vermez | Skill ID kullanım taraması |
| D15 | P1 | Çok seviyeli income/maintenance/efficiency yalnız boolean okunuyor | Sonraki seviyelerden marjinal kazanç yok | SkillTree getter'ları, ScienceLogic, enerji hesabı |
| D16 | P1 | PlanetModifier kapasite/enerji/fiyat etkileri uygulanmıyor | Gezegen türlerinin avantaj/dezavantajları eksik | Aktif fiyat, kapasite ve enerji çağrıları |
| D17 | P1 | Solar Matrix, Geothermal, Magma Resonator yanlış tür enum'u | Uzmanlık araştırması başka gövdede sonuç verir | Building .tres ile PlanetData.Type |
| D18 | P1 | Parent listeleri VEYA | Çift önkoşullu teknoloji beklenenden erken açılır | SkillTree.can_purchase |
| D19 | P1 | Interstellar seviyeleri sistem açmıyor | 999 seviyelik milyarlarca bilim harcaması karşılıksız | purchase_skill ve GalaxyData |
| D20 | P1 | Tür kolonizasyon skill'leri kontrol edilmiyor | Ekonomik yayılma kapıları atlanır | SolarView._can_access, colonize_planet |
| D21 | P1 | Survey olmadan koloni/POI yıldızı açabiliyor | 200000 kredi + 50000 bilim gideri atlanır | SolarView._check_poi_unlock |
| D22 | P1 | Destek kapalı olsa da bonus kalıyor | Destek enerji maliyeti kaldırılıp bonus korunur | get_district_buffs ile enerji duraklama filtresi |
| D23 | P1 | Yükseltilmiş yığına temel fiyatla bina ekleme | Pahalı bina seviye maliyeti aşılır | stack_building_unchecked, pending_merges |
| D24 | P1 | max_per_district yığınlarda ve + düğmesinde uygulanmıyor | Sınırlı desteklerin çoğaltılması mümkün | PlanetaryView satın alma ve stacking |
| D25 | P1 | Görünür yüzey inşaatında çift zaman ilerlemesi | Ekrana bakmak inşaatı hızlandırır | ProductionManager + PlanetaryView._process |
| D26 | P1 | Orbital inşaat animasyona ve ekran yarıçapına bağlı | Ekran boyutu/sahne değişimi üretim başlangıcını etkiler | _play_rocket_animation, orbital skip |
| D27 | P1 | Asteroid kayıtları sistem/seed ile düzgün ayrılmıyor | Keşif ücreti/rarity ilerlemesi güvenilmez | asteroid_scan_counts, AsteroidBelt._navigate_to_asteroid |
| D28 | P1 | Üretim ilerlemesi, pause ve dünya bağlamı tam kaydedilmiyor | Tekrar ödeme, stok tanıma ve koloni görünümü farkları | GameState.save/load, ShipManager.serialize |
| D29 | P1 | District adı anahtar olarak kullanılıyor | Aynı adlar kapasite/bonus/yığınları karıştırabilir | district_id, district_levels, ProductionManager._key |
| D30 | P1 | Rename bütün sözlük anahtarlarını taşımıyor | District seviyesi/çevrim ilerlemesi/pause kaybolabilir | _build_district_panel rename callback |
| D31 | P1 | SceneTree singleton kontrolü skill düğümüne erişimi engelleyebilir | Bina yükseltme UI'si ve skill district bonusu görünmeyebilir | Engine.has_singleton kontrolü, motor testi gerekli |
| D32 | P1 | Gemi yükü miktarı ödeme anında doğrulanmıyor | Eksik stoktan tam kargo yaratılabilir | _sp_build_idle / _sp_build_config |
| D33 | P1 | Rafinaj seçili input_mineral'i okur, kilitlenen burning_mineral'i değil | Çevrim ortası seçim değişimi tüketim/çıktı kimliğini ayırır | RefineryLogic.produce |
| D34 | P2 | Üretim göstergeleri farklı formüller kullanıyor | Oyuncu yanlış getiriyi temel alarak yatırım yapar | get_building_output, kartlar, floating output |
| D35 | P2 | Power Transmission açıklaması %5, gerçek %15 | Skill fiyat/verim kıyaslaması yanıltıcı | SkillTree |
| D36 | P2 | Planet level-up açıklaması +2, gerçek +1 district | Kapasite beklentisi yanlış | PlanetProgress ve popup |
| D37 | P2 | Başarı sayaçları gerçek adetleri izlemiyor | İlerleme ölçümü güvenilir değil | AchievementManager |
| D38 | P2 | Görev tahmin ve fiili ödeme tarifesi farklı | Gemi maliyeti öngörülemiyor | MissionBuilderPanel ve launch cost |
| D39 | P1 | Normal depo kapasitesi/offline kazanç modeli yok | Uzun idle seansı ve geri dönüş temposu tanımlı değil | Global kaynak ve save/load akışı |
| D40 | P1 | Başlangıç/yeniden yükleme autoload bağımlılıkları | Kayıt yükleme hata riski; motor başlatma testi gerekir | project.godot autoload sırası, GameState.load_save |

### 14.1. Sonsuz inşaat kümesi

arid_housing, central_bank, command_center, cryo_vault, customs_office, logistics_center, orbital_logistics, orbital_mirrors.

### 14.2. Pozitif çıktı tanımı olup üretim mantığı bulunmayan küme

arid_trade, asteroid_harvester, ice_science, lunar_observatory, moon_observatory, research_academy, zero_g_nexus. zero_g_nexus doğrudan bilim üretmez fakat tamamlandıktan sonra pasif +%30 gezegen bilim bonusu verebilir.

ENERGY türünde logic olmaması tek başına hata değildir; Solar Array ve Moon Helium-3 gibi binaların kapasitesi merkezi enerji hesabında çalışır.

### 14.3. Normal açılma yolu bulunmayan küme

commercial, commercial_hub, data_center, particle_accelerator, quantum_computer, scanner, spaceport.

Bunların katalogda bulunması normal oyuncunun elde edebildiği anlamına gelmez. Debug veya eski kayıt, erişilebilirliği değiştirebilir. Projede DebugGameState sahneye bağlı ve enabled=true varsayılanlı; DevConsole da autoload'dur. Denge ölçümlerinde debug müdahalesi yapılmış kayıt kullanılmamalıdır.

### 14.4. Denge ayarından önce önerilen çalışma sırası

Bu bir sonraki çalışma için öneridir; bu belgede uygulama yapılmadı.

1. Kaynak kimliği ve gerçek T1..T5 dönüşüm sözleşmesini netleştir.
2. Bina inşaatı, enerji sıfırı ve gerçek seviye getirisi hatalarını düzelt.
3. Kayıt/yükleme ile gezegen ve kaynak kimliklerini koru.
4. Bina açılma, POI türü ve skill etkilerini tek doğrulanmış sözleşmeye bağla.
5. Gerçek üretim oranından türeyen ortak arayüz hesaplarını oluştur.
6. Ondan sonra erken enerji, bilim temposu, ürün oranları ve keşif fiyatlarını dengele.

## 15. Denge çalışması için karar tablosu

Buradaki hedef değerler henüz kullanıcı tarafından kararlaştırılmadı. Mevcut değerlere karşı yeni sayılar uydurulmadı.

| Konu | Mevcut durum | Verilmesi gereken tasarım kararı | Ölçülecek sonuç |
|---|---|---|---|
| İlk enerji | Solar 1, konut+lab 4 talep | Açılışta kriz öğretilecek mi, nötr enerji mi? | İlk 10 dakikada q ve bekleme süresi |
| Bilim temposu | University 2/25s | İlk mining, refinery, moon, galaxy kaç dakikada açılmalı? | Araştırma milestone süreleri |
| Bina seviyeleri | Logaritmik çıktı tanımı, üstel fiyat | Slot verimliliği mi, ana büyüme aracı mı? | Seviye başına marjinal getiri |
| District büyümesi | Aynı tür fiyatı her defasında ×2 | Uzmanlaşma ne kadar cezalandırılmalı? | Yeni district / yükseltme alternatif maliyeti |
| Yerleşim stratejisi | Konumdan bağımsız district bonusu | Komşuluk veya arazi verimi istenecek mi? | Anlamlı alternatif yerleşim sayısı |
| Tier ekonomisi | Zincir kopuk, tarifeler çok kayıplı | Her tier ürününün işlevi ve standart etiketi ne? | Ham eşdeğer maliyet, sürdürülebilir ürün/s |
| Rarity | Power ve yakıt süresini etkiler | Nadir ürün yeni karar mı, yalnız katsayı mı? | Rarity başına marjinal ekonomi |
| Uzman gezegenler | Kısmi bonuslar ve yanlış filtreler | Her tür hangi üretimde üstün olmalı? | Eşit yatırımda çıktı/enerji/slot |
| Moon enerji sıçraması | 500 yakıtsız enerji | Bu sıçrama hedef mi, geçici sayı mı? | Ay öncesi/sonrası q ve bilim hızı |
| Yeni koloni | 1000 kredi, ücretsiz yerleşim | Yayılma ile tek gezegeni büyütme nasıl yarışmalı? | Marjinal slot ve gelir maliyeti |
| Survey | 200000 cr + 50000 sci; aşılabiliyor | Survey kolonizasyonun zorunlu önkoşulu mu? | Keşif başına maliyet ve yeni imkân |
| Gemi ekonomisi | Global stokla zorunluluğunu kaybetmiş | Görevler ekonomik rol üstlenecek mi? | Aktif yönetim yükü / sağladığı fayda |
| Idle | Uygulama açıkken üretim | Offline süre, verim ve üst sınır olacak mı? | 1h/8h/24h geri dönüş kazancı |
| Sonsuz ilerleme | Tek 34 sistemlik galaksi | Sonlu galaksi sonrası büyüme nedir? | Son içerikten sonraki kaynak gideri |

### 15.1. Karşılaştırma için kullanılacak ortak denklemler

```text
Üretim/s = gerçek_çevrim_çıktısı / gerçek_çevrim_süresi
Net kaynak/s = Σüretim/s - Σtüketim/s
Slot verimi = net üretim/s / kullanılan_slot
Enerji verimi = net üretim/s / enerji_talebi
Marjinal geri dönüş = ek_kredi_yatırımı / ek_net_kredi_hızı
Bilim eşiğine süre ≈ max(0, gereken_bilim-mevcut_bilim) / net_bilim_hızı
Malzeme eşiğine süre ≈ max(0, gereken_stok-mevcut_stok) / net_malzeme_hızı
Birden çok eşzamanlı ihtiyaç için bekleme ≈ ihtiyaç sürelerinin maksimumu
```

Son denklem üretim oranlarının bu sırada sabit ve birlikte sürdürülebilir olduğu varsayımıyla geçerlidir. Bina yapımı, yeni teknoloji, enerji açığı ve stok tıkanması varsa olay bazlı hesap gerekir. Net gelir≤0 ise geri dönüş süresi sonlu değildir.

### 15.2. Daha sonra yapılacak doğrulama senaryoları

- Yeni oyunda 0,1,2,3,4 Solar Array ile konut ve üniversite gelirini karşılaştır.
- Aynı binayı L1 ve L2'de çalıştır, kartı değil gerçek stok farkını ölç.
- Rafineride her rarity için T1→T2 kimliğini doğrula.
- Enerjiyi sıfırlayıp girdinin sadece bir kez ayrıldığını doğrula.
- Destek binasını aç/kapat ve bonus/enerji ilişkisini kontrol et.
- District kurarken aynı ekranda kalma ile başka ekrana geçmenin sürelerini karşılaştır.
- Oyun kapat/aç; kredi, skill erişimi, pause, üretim ilerlemesi ve yabancı koloni durumunu karşılaştır.
- Aynı isimde district'ler ve rename işlemiyle ekonomik durumun korunmasını kontrol et.
- Survey edilmemiş komşu yıldızda kolonizasyon kapısını doğrula.
- Asteroidleri farklı sistemlerde ve pencere boyutlarında açıp seed/hop'un sabit kaldığını kontrol et.

Bu senaryolar çalıştırılmış test sonuçları değildir; statik bulguları doğrulamak ve ileride düzeltmeleri kabul etmek için somut ölçüm planıdır.

## 16. Başarı eşikleri ve kaynak envanteri

### 16.1. Başarıların ekonomiyle ilişkisi

117 achievement tanımı vardır. _grant yalnız kilidi açar, bildirim/ses üretir; kredi, bilim, mineral veya üretim çarpanı ödülü vermez. Bu nedenle başarıların pazarlama/adlandırma kısmı çıkarıldı; denge için sayısal eşikler korundu.

CREDITS_TOTAL ve SCIENCE_TOTAL isimleri ömür boyu kazanımı çağrıştırır; gerçek kontrol o anki bakiyedir. BUILDING_COUNT amount toplamını değil tamamlanmış bina kayıt sayısını sayar. DISTRICT_COUNT olmayan custom_pois_count metodunu denediği için 0'a düşer; kolonize gezegen sayımı da buna bağlıdır. Mineral/skill/gezegen seviyesi için gerekli bildirimlerin normal olay yolunda bağlantısı eksiktir. TUTORIAL_COMPLETE çağrılır fakat notify_trigger match içinde ilgili dal yoktur.

Aşağıdaki liste tanım eşikleridir, hepsinin fiilen kazanılabilir olduğu anlamına gelmez.

| Tetik türü | Tanım sayısı | Eşikler / hedefler |
|---|---:|---|
| FIRST_DISTRICT | 1 | ilk olay |
| FIRST_BUILDING | 1 | ilk olay |
| FIRST_ORBITAL | 1 | ilk olay |
| FIRST_ASTEROID_SCAN | 2 | ilk olay |
| FIRST_MOON_COLONY | 1 | ilk olay |
| FIRST_SOLAR_TRAVEL | 1 | ilk olay |
| FIRST_GALAXY_VIEW | 1 | ilk olay |
| FIRST_SURVEY | 1 | ilk olay |
| PLANET_LEVEL | 9 | 2, 3, 4, 5, 6, 7, 8, 9, 10 |
| CREDITS_TOTAL | 12 | 10000, 100000, 1000000, 10000000, 100000000, 1000000000, 10000000000, 100000000000, 1000000000000, 1000000000000000, 1000000000000000000, 1e+21 |
| SCIENCE_TOTAL | 12 | 5000, 50000, 500000, 5000000, 50000000, 500000000, 5000000000, 50000000000, 500000000000, 5000000000000, 5000000000000000, 5000000000000000000 |
| MINERAL_COLLECTED | 15 | 10000, 50000, 250000, 1000000, 5000000, 25000000, 100000000, 500000000, 2500000000, 10000000000, 50000000000, 250000000000, 1000000000000, 1000000000000000, 1000000000000000000 |
| SKILL_PURCHASED | 26 | unlock_antimatter_reactor, unlock_apartments, unlock_arcologies, unlock_asteroid_mining, unlock_black_hole_extractor, unlock_commercial_hub, unlock_commodities_exchange, unlock_deep_core_mining, unlock_dyson_sphere, unlock_financial_district, unlock_fusion_reactor, unlock_interstellar, unlock_interstellar_syndicate, unlock_lab, unlock_lunar_observatory, unlock_luxury_complex, unlock_market_square, unlock_mohole_mine, unlock_moon, unlock_orbital_mirrors, unlock_orbital_offworld_market, unlock_orbital_shipyard, unlock_research_academy, unlock_research_nexus, unlock_space_station, unlock_trading_post |
| BUILDING_COUNT | 12 | 10, 50, 250, 1000, 5000, 10000, 25000, 50000, 100000, 250000, 500000, 1000000 |
| DISTRICT_COUNT | 10 | 5, 25, 100, 250, 500, 1000, 2500, 5000, 10000, 25000 |
| COLONIZED_PLANETS_COUNT | 12 | ilk olay, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 5000 |

Bazı başarı skill hedefleri eski kimlikleri kullanır. Örneğin unlock_asteroid_mining ile çalışan unlock_asteroids aynı kimlik değildir. Yukarıdaki hedefler mevcut başarı dosyalarından aynen korunmuştur.

### 16.2. Ana kaynak haritası

Her ana sistemin esas dosyası aşağıdadır. Bina tablolarındaki kimlik `resources/buildings/{kimlik}.tres` dosyasına karşılık gelir. Tablolar bu kaynakların bütün sayısal oyun alanlarını kapsar; görsel renk/simge gibi denge dışı alanlar dahil edilmedi.

| Sistem | Dosya |
|---|---|
| Başlangıç, ekonomi, kolonizasyon, kayıt | [scripts/game/GameState.gd](C:/Users/drosm/Voidle/scripts/game/GameState.gd) |
| Çevrim, enerji, seviye ve district bonusları | [scripts/game/ProductionManager.gd](C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd) |
| Gezegen/district kapasitesi ve bina yığınları | [scripts/game/PlanetProgress.gd](C:/Users/drosm/Voidle/scripts/game/PlanetProgress.gd) |
| Bina alan varsayılanları ve katalog filtreleri | [scripts/game/BuildingDef.gd](C:/Users/drosm/Voidle/scripts/game/BuildingDef.gd) |
| District maliyeti ve filtreleri | [scripts/game/DistrictDef.gd](C:/Users/drosm/Voidle/scripts/game/DistrictDef.gd) |
| Araştırma ağacı, fiyatlar, koşullar ve çarpanlar | [scripts/game/SkillTree.gd](C:/Users/drosm/Voidle/scripts/game/SkillTree.gd) |
| Kaynak değer, power ve tier formülleri | [scripts/game/ResourceData.gd](C:/Users/drosm/Voidle/scripts/game/ResourceData.gd) |
| Maden havuzu ve bulunma olasılıkları | [scripts/game/BodyResources.gd](C:/Users/drosm/Voidle/scripts/game/BodyResources.gd) |
| Gezegen türü bonus tanımları | [scripts/game/PlanetModifier.gd](C:/Users/drosm/Voidle/scripts/game/PlanetModifier.gd) |
| Ham üretimin gerçek stok yazımı | [scripts/game/logic/MineLogic.gd](C:/Users/drosm/Voidle/scripts/game/logic/MineLogic.gd) |
| İşleme ve çıktı kaynak kimliği | [scripts/game/logic/RefineryLogic.gd](C:/Users/drosm/Voidle/scripts/game/logic/RefineryLogic.gd) |
| Kredi üretiminin gerçek bakiye yazımı | [scripts/game/logic/CreditLogic.gd](C:/Users/drosm/Voidle/scripts/game/logic/CreditLogic.gd) |
| Bilim üretiminin gerçek bakiye yazımı | [scripts/game/logic/ScienceLogic.gd](C:/Users/drosm/Voidle/scripts/game/logic/ScienceLogic.gd) |
| Satın alma, yükseltme, district, gemi ve UI içi kurallar | [scripts/planetary/PlanetaryView.gd](C:/Users/drosm/Voidle/scripts/planetary/PlanetaryView.gd) |
| Gezegen üretimi ve tür enum'ları | [scripts/planetary/PlanetData.gd](C:/Users/drosm/Voidle/scripts/planetary/PlanetData.gd) |
| Yıldız sistemi üretimi | [scripts/solar/SolarData.gd](C:/Users/drosm/Voidle/scripts/solar/SolarData.gd) |
| Galaksi büyüklüğü ve bağlantılar | [scripts/galaxy/GalaxyData.gd](C:/Users/drosm/Voidle/scripts/galaxy/GalaxyData.gd) |
| Sistem erişimi, survey ve tarama | [scripts/solar/SolarView.gd](C:/Users/drosm/Voidle/scripts/solar/SolarView.gd) |
| Galaksi erişimi ve hop aktarımı | [scripts/galaxy/GalaxyView.gd](C:/Users/drosm/Voidle/scripts/galaxy/GalaxyView.gd) |
| Asteroid kimliği ve gezegen geçişi | [scripts/solar/AsteroidBelt.gd](C:/Users/drosm/Voidle/scripts/solar/AsteroidBelt.gd) |
| Gemiler, taşıma altyapısı ve kayıt | [scripts/game/ShipManager.gd](C:/Users/drosm/Voidle/scripts/game/ShipManager.gd) |
| Görev paneli ve maliyet gösterimi | [scripts/mission/MissionBuilderPanel.gd](C:/Users/drosm/Voidle/scripts/mission/MissionBuilderPanel.gd) |
| Öğretici ödülleri | [scripts/system/TutorialManager.gd](C:/Users/drosm/Voidle/scripts/system/TutorialManager.gd) |
| Başarıların fiili tetiklenmesi | [scripts/game/AchievementManager.gd](C:/Users/drosm/Voidle/scripts/game/AchievementManager.gd) |
| Duraklatma ve bakiye/enerji gösterimi | [scripts/system/HUDManager.gd](C:/Users/drosm/Voidle/scripts/system/HUDManager.gd) |
| Sahne başlangıcı ve autoload sırası | [project.godot](C:/Users/drosm/Voidle/project.godot) |

### 16.3. İnceleme envanteri

İlk taramada oyun kaynakları, sahneler, shader'lar, veri tanımları, proje ayarları ve geçmiş üretim/yama betikleri envantere alındı. Görsel çizim, ses, font ve ikon varlıkları ekonomik veri olarak değerlendirilmedi. Aşağıda script/sahne/ayar kaynakları ve inceleme rolleri listelenmiştir. Bu liste her görsel satırın tasarım kuralı olduğu anlamına gelmez.

| Kaynak | Satır | İnceleme rolü |
|---|---:|---|
| [export_presets.cfg](C:/Users/drosm/Voidle/export_presets.cfg) | 334 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [project.godot](C:/Users/drosm/Voidle/project.godot) | 55 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [test_energy.gd](C:/Users/drosm/Voidle/test_energy.gd) | 10 | Geliştirme/test aracı; normal dengeye dahil değil |
| [test_image.gd](C:/Users/drosm/Voidle/test_image.gd) | 6 | Geliştirme/test aracı; normal dengeye dahil değil |
| [test_mineral_icon.gd](C:/Users/drosm/Voidle/test_mineral_icon.gd) | 9 | Geliştirme/test aracı; normal dengeye dahil değil |
| [resources/achievements/AchievementDef.gd](C:/Users/drosm/Voidle/resources/achievements/AchievementDef.gd) | 36 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scenes/MainMenu.tscn](C:/Users/drosm/Voidle/scenes/MainMenu.tscn) | 8 | Sahne bağlantıları ve başlangıç değerleri |
| [scenes/galaxy/GalaxyView.tscn](C:/Users/drosm/Voidle/scenes/galaxy/GalaxyView.tscn) | 42 | Sahne bağlantıları ve başlangıç değerleri |
| [scenes/planetary/PlanetaryView.tscn](C:/Users/drosm/Voidle/scenes/planetary/PlanetaryView.tscn) | 127 | Sahne bağlantıları ve başlangıç değerleri |
| [scenes/solar/SolarView.tscn](C:/Users/drosm/Voidle/scenes/solar/SolarView.tscn) | 80 | Sahne bağlantıları ve başlangıç değerleri |
| [scenes/tools/IconExporter.tscn](C:/Users/drosm/Voidle/scenes/tools/IconExporter.tscn) | 13 | Sahne bağlantıları ve başlangıç değerleri |
| [scripts/data/ShipData.gd](C:/Users/drosm/Voidle/scripts/data/ShipData.gd) | 83 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/galaxy/GalaxyCanvas.gd](C:/Users/drosm/Voidle/scripts/galaxy/GalaxyCanvas.gd) | 8 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/galaxy/GalaxyData.gd](C:/Users/drosm/Voidle/scripts/galaxy/GalaxyData.gd) | 155 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/galaxy/GalaxyView.gd](C:/Users/drosm/Voidle/scripts/galaxy/GalaxyView.gd) | 444 | Aktif satın alma ve erişim yolları |
| [scripts/game/AchievementManager.gd](C:/Users/drosm/Voidle/scripts/game/AchievementManager.gd) | 122 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/BodyResources.gd](C:/Users/drosm/Voidle/scripts/game/BodyResources.gd) | 78 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/BuildingDef.gd](C:/Users/drosm/Voidle/scripts/game/BuildingDef.gd) | 104 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/DebugGameState.gd](C:/Users/drosm/Voidle/scripts/game/DebugGameState.gd) | 94 | Geliştirme/test aracı; normal dengeye dahil değil |
| [scripts/game/DebugResourceGen.gd](C:/Users/drosm/Voidle/scripts/game/DebugResourceGen.gd) | 68 | Geliştirme/test aracı; normal dengeye dahil değil |
| [scripts/game/DistrictDef.gd](C:/Users/drosm/Voidle/scripts/game/DistrictDef.gd) | 98 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/GameState.gd](C:/Users/drosm/Voidle/scripts/game/GameState.gd) | 603 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/PlanetModifier.gd](C:/Users/drosm/Voidle/scripts/game/PlanetModifier.gd) | 126 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/PlanetProgress.gd](C:/Users/drosm/Voidle/scripts/game/PlanetProgress.gd) | 252 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/ProductionManager.gd](C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd) | 626 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/ResourceData.gd](C:/Users/drosm/Voidle/scripts/game/ResourceData.gd) | 180 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/ShipManager.gd](C:/Users/drosm/Voidle/scripts/game/ShipManager.gd) | 117 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/SkillTree.gd](C:/Users/drosm/Voidle/scripts/game/SkillTree.gd) | 466 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/logic/BuildingLogic.gd](C:/Users/drosm/Voidle/scripts/game/logic/BuildingLogic.gd) | 14 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/logic/CreditConsumerLogic.gd](C:/Users/drosm/Voidle/scripts/game/logic/CreditConsumerLogic.gd) | 5 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/logic/CreditLogic.gd](C:/Users/drosm/Voidle/scripts/game/logic/CreditLogic.gd) | 25 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/logic/EnergyLogic.gd](C:/Users/drosm/Voidle/scripts/game/logic/EnergyLogic.gd) | 5 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/logic/GeneratorLogic.gd](C:/Users/drosm/Voidle/scripts/game/logic/GeneratorLogic.gd) | 8 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/logic/MineLogic.gd](C:/Users/drosm/Voidle/scripts/game/logic/MineLogic.gd) | 39 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/logic/RefineryLogic.gd](C:/Users/drosm/Voidle/scripts/game/logic/RefineryLogic.gd) | 35 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/logic/ScienceLogic.gd](C:/Users/drosm/Voidle/scripts/game/logic/ScienceLogic.gd) | 19 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/game/logic/SpaceportLogic.gd](C:/Users/drosm/Voidle/scripts/game/logic/SpaceportLogic.gd) | 33 | Üretim/ekonomi/ilerleme; ayrıntılı inceleme |
| [scripts/mission/MissionBuilderPanel.gd](C:/Users/drosm/Voidle/scripts/mission/MissionBuilderPanel.gd) | 810 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/mission/MissionTaskDef.gd](C:/Users/drosm/Voidle/scripts/mission/MissionTaskDef.gd) | 34 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/mission/MissionTaskRegistry.gd](C:/Users/drosm/Voidle/scripts/mission/MissionTaskRegistry.gd) | 59 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/planetary/LocationFinder.gd](C:/Users/drosm/Voidle/scripts/planetary/LocationFinder.gd) | 65 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/planetary/OrbitalLayer.gd](C:/Users/drosm/Voidle/scripts/planetary/OrbitalLayer.gd) | 758 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/planetary/PlanetaryView.gd](C:/Users/drosm/Voidle/scripts/planetary/PlanetaryView.gd) | 7406 | Aktif satın alma ve erişim yolları |
| [scripts/planetary/PlanetData.gd](C:/Users/drosm/Voidle/scripts/planetary/PlanetData.gd) | 423 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/planetary/PlanetNoise.gd](C:/Users/drosm/Voidle/scripts/planetary/PlanetNoise.gd) | 85 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/planetary/PlanetRenderer.gd](C:/Users/drosm/Voidle/scripts/planetary/PlanetRenderer.gd) | 226 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/planetary/POIData.gd](C:/Users/drosm/Voidle/scripts/planetary/POIData.gd) | 53 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/planetary/POILayer.gd](C:/Users/drosm/Voidle/scripts/planetary/POILayer.gd) | 357 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/ships/ShipCommandDef.gd](C:/Users/drosm/Voidle/scripts/ships/ShipCommandDef.gd) | 17 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/ships/ShipCommandRegistry.gd](C:/Users/drosm/Voidle/scripts/ships/ShipCommandRegistry.gd) | 63 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/ships/ShipTypeDef.gd](C:/Users/drosm/Voidle/scripts/ships/ShipTypeDef.gd) | 7 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/solar/AsteroidBelt.gd](C:/Users/drosm/Voidle/scripts/solar/AsteroidBelt.gd) | 264 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/solar/MoonOrbitNode.gd](C:/Users/drosm/Voidle/scripts/solar/MoonOrbitNode.gd) | 73 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/solar/OrbitLines.gd](C:/Users/drosm/Voidle/scripts/solar/OrbitLines.gd) | 51 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/solar/PlanetOrbitNode.gd](C:/Users/drosm/Voidle/scripts/solar/PlanetOrbitNode.gd) | 354 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/solar/SolarData.gd](C:/Users/drosm/Voidle/scripts/solar/SolarData.gd) | 119 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/solar/SolarView.gd](C:/Users/drosm/Voidle/scripts/solar/SolarView.gd) | 1070 | Aktif satın alma ve erişim yolları |
| [scripts/system/AudioManager.gd](C:/Users/drosm/Voidle/scripts/system/AudioManager.gd) | 641 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/system/CursorManager.gd](C:/Users/drosm/Voidle/scripts/system/CursorManager.gd) | 244 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/system/DevConsole.gd](C:/Users/drosm/Voidle/scripts/system/DevConsole.gd) | 568 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/system/HUDManager.gd](C:/Users/drosm/Voidle/scripts/system/HUDManager.gd) | 992 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/system/MainMenu.gd](C:/Users/drosm/Voidle/scripts/system/MainMenu.gd) | 325 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/system/ScreenshotManager.gd](C:/Users/drosm/Voidle/scripts/system/ScreenshotManager.gd) | 25 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/system/SettingsManager.gd](C:/Users/drosm/Voidle/scripts/system/SettingsManager.gd) | 92 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/system/TooltipManager.gd](C:/Users/drosm/Voidle/scripts/system/TooltipManager.gd) | 236 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/system/TutorialManager.gd](C:/Users/drosm/Voidle/scripts/system/TutorialManager.gd) | 1318 | Ödüller ve başlangıç akışı |
| [scripts/tools/IconExporter.gd](C:/Users/drosm/Voidle/scripts/tools/IconExporter.gd) | 175 | Geliştirme/test aracı; normal dengeye dahil değil |
| [scripts/ui/MineralIcon.gd](C:/Users/drosm/Voidle/scripts/ui/MineralIcon.gd) | 169 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/ui/SceneTransition.gd](C:/Users/drosm/Voidle/scripts/ui/SceneTransition.gd) | 36 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/ui/SkillTreeView.gd](C:/Users/drosm/Voidle/scripts/ui/SkillTreeView.gd) | 730 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |
| [scripts/ui/TechIcon.gd](C:/Users/drosm/Voidle/scripts/ui/TechIcon.gd) | 144 | Görünüm/yardımcı, ekonomik bağlantılar tarandı |

### 16.4. Terimler

- **Çevrim:** Bir binanın girdiyi alıp çıktıyı vermesine kadar geçen üretim turu.
- **Slot:** District içinde binanın kapladığı kapasite birimi.
- **Yığın:** Aynı kayıt üzerinde adet olarak birleştirilmiş binalar.
- **Rarity:** Mineral nadirlik sınıfı; tier ile aynı şey değildir.
- **Tier:** Mineralin işlenme aşaması.
- **Hop:** Ana yıldızdan en kısa bağlantı yolu üzerindeki atlama sayısı.
- **Çarpan:** Sonucu katlayan sayı. 1.20, öncekinin %120'si demektir.
- **Marjinal getiri:** Bir sonraki yatırımın, mevcut üretimin üstüne eklediği kazanç.
- **Darboğaz:** Sistemin geri kalanını bekleten kaynak veya kapasite eksikliği.
- **Nominal:** Bonuslar, enerji yetersizliği ve uygulama kopuklukları uygulanmadan tanımlanmış değer.

### 16.5. Değişiklik kaydı

| Tarih | Belge değişikliği | Oyun değişikliği |
|---|---|---|
| 2026-09-16 | Mevcut kaynaklardan ilk matematik ve denge GDD'si | Yok |

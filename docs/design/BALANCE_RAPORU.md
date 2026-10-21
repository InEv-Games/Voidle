# Denge raporu: maliyet eğrileri ve tekrar oranları

Tarih: 21 Ekim 2026
Kapsam: Tip 0 ekonomisi (Dünya + Ay, 45–75 dakikalık ilk oturum)
Girdiler: Kongregate "The Math of Idle Games" I–III, `KARARLAR.md`, `PLAN.md`, `VOIDLE_GDD.md` (§7.5, §8, §9, §11, §12, §13, §16, §17, §18), `scripts/game/*.gd`, `resources/buildings/*.tres`, `resources/districts/*.tres`

**Etiketler.** Raporda her iddianın kaynağı işaretlidir:

- **[Hesap]**: Koddan veya GDD'den alınan sayılarla yapılmış aritmetik. Tekrar üretilebilir.
- **[Makale]**: Kongregate yazılarının yönlendirmesi.
- **[Öneri]**: Benim önerim. Hiçbiri oynanışla test edilmedi.
- **[Model]**: Basit açgözlü oyuncu simülasyonunun çıktısı (bkz. §3.5). Sonuçlar yalnız maliyet eğrilerini kıyaslamak içindir. Gerçek oyun süresi tahmini değildir.

Kredi eşdeğeri hesaplarında GDD §18.3 satış fiyatları kullanıldı: Ferrite 1,8; Science 4,5; Goods 19,8; Fuel 30,6; Rare 82,8 kredi. Mevcut kodda trade yok. Bu yüzden mevcut kod için verilen "kredi eşdeğeri" bir karşılaştırma ölçüsüdür, oyunun bugünkü gerçek değeri değildir.

---

## 1. Makalelerin özeti

### 1.1 Temel model (Part I) [Makale]

Idle oyunlar üretim hızı ile maliyet arasında gidip gelen bir tahterevallidir. Maliyet üstel, üretim doğrusal veya polinom büyür. Bu yüzden üretim başta önde gider, sonunda maliyet her zaman yetişip geçer.

- **Maliyet:** `fiyat_sonraki = taban × oran^sahip_olunan`
- **Üretim:** `üretim = (birim_üretim × sahip_olunan) × çarpanlar`
- **Örnek (AdVenture Capitalist, Lemonade Stand):** taban 4, oran 1,07, birim üretim 1,67/sn. 10 adetle sonraki fiyat 4 × 1,07^10 ≈ 7,87, üretim 16,7/sn. 25 ve 50 adette birikimli ×2 çarpan verilir.
- **Oran aralığı:** Metinden doğrulananlar Lemonade için 1,07 ve Derivative Clicker için `5 × 1,1^n`. AdCap'in jeneratör tablosu PDF'te görsel olduğu için metin olarak okunamadı. Sık alıntılanan 1,07–1,15 aralığı o tablodan gelir.
- **Toplu alım (bulk):** k adede sahipken n adet almanın fiyatı `b × r^k × (r^n − 1)/(r − 1)`.
- **Azami alım:** c paranın yettiği en büyük adet `floor(log_r(c(r − 1)/(b × r^k) + 1))`.
- **Çarpan eşikleri:** Belli adetlerdeki çarpanlar üretimi geçici olarak maliyetin önüne iter. Alımlar bu eşiklerin çevresinde yoğunlaşır.
- **En yeni jeneratör baskınlığı:** Bütün jeneratörler aynı eşik çarpanlarını alırsa hep en yeni jeneratör baskın olur ve eskiler önemsizleşir. Eşik çarpanları jeneratöre göre farklılaştırılırsa öncelik zamanla el değiştirir ve oyuncunun çözmesi gereken bir bulmaca çıkar.
- **Optimal oyuncu modeli:** Her fırsatta gelir/maliyet oranı en iyi olan alınır. Gerçek oyuncu bunu tam uygulamaz, toplu alır, ama uzun vadede bu modelin çevresinde kalır.

### 1.2 Türev büyüme (Part II) [Makale]

Jeneratörler başka jeneratörleri üretebilir. m katmanlı zincir `t^m/m!` terimleriyle büyür, katman sayısı arttıkça e^t'ye yaklaşır ama ona ulaşmaz. Bu yüzden üstel maliyet yine sonunda kazanır. Alt katmanları alakalı tutmak için **satın alınmış adet** sayılır, bedava gelen adet sayılmaz. Ayrıca her satın alma küçük bir katman desteği verir (Derivative Clicker'da %0,05).

> Voidle karşılığı: Bir district "jeneratör üreten jeneratör"dür. Kendi tabanı vardır, bina yuvası açar, seviyeyle yuva ve çarpan kazanır. City district açar, gezegen City açar. Bu katmanlı yapı polinom-üstü bir büyüme kaynağıdır ve fiyatlandırması tek binadan dik olmalıdır.

### 1.3 Prestij (Part III) [Makale]

Prestij iki işe yarar: merdiven tırmanma hissi verir ve büyümeyi yönetilebilir sayılara indirir. Formüller çoğunlukla kesirli üstlüdür (logaritma değildir):

| Oyun | Formül | Prestiji ikiye katlamak için gereken kazanç |
| --- | --- | --- |
| Realm Grinder | p ≈ √(2·c_M/10¹²) (üçgen sayı tersi) | ~4× |
| AdVenture Capitalist | p = 150·√(c_L/10¹⁵) | ~3–4× |
| Cookie Clicker | p = ∛(c_L/10¹²) | ~8× |
| Egg, Inc. | Δp ≈ (c_R/10⁶)^0,14 | ~128× |

- **Ömür boyu kazanca dayalı formüller:** Aynı noktada resetlemeye devam etmek kazanç getirir, ama azalarak.
- **Koşu başına (since-reset) formüller:** Her koşu bağımsızdır. Eğri çok düz tutulmalıdır.
- **Tempo:** Koşu içindeki gibi prestij döngüsü de "engebeli" olmalı, yani hızlı ve yavaş bölümler içermeli.

### 1.4 Bizim için özü [Makale → Voidle dili]

1. Üretim katmanlarının her biri, maliyetin aynı katmandaki büyümesinden **yavaş** büyümelidir. Yoksa yarış tersine döner ve her şey "her zaman al" olur.
2. Çarpanlar (bizde district seviyesi, araştırma, yakınlık) üretimi periyodik olarak maliyetin önüne iter. Ama çarpanın büyüme hızı, onu satın alma maliyetinin büyüme hızını geçmemelidir.
3. Geri ödeme süresi (`fiyat / dakikalık getiri`) en kullanışlı tek ölçüdür. Sağlıklı eğride geri ödeme oturum boyunca yavaşça uzar. Kısalırsa düzleşme var demektir, kontrolsüz uzarsa patlama var demektir.

---

## 2. Voidle'a uygulanabilirlik

### 2.1 Yapısal fark: tekrar sayaçlarımız yerel [Hesap]

AdCap'te bir jeneratörün sayacı tektir ve yüzlerce, binlerce adede çıkar. 1,07^99 ≈ 811 ve 1,07^199 ≈ 703.674 olduğundan oran tek başına bütün ekonomiyi frenler.

Voidle'da sayaçlar yereldir:

| Sayaç | Anahtar | Azami adet |
| --- | --- | --- |
| Bina | District (mevcut kod) veya district + model (GDD, KARARLAR §1) | District yuvası: 3 + 2(L−1), en fazla **21** (Capital: L, en fazla 10) |
| District | City (mevcut kod, tür fark etmez) | City kapasitesi: 3 + 2(Lv−1), en fazla **21** |
| City | Gövde | Gezegen seviyesi + 1, en fazla **11** |

Bir districti tamamen doldurmanın maliyeti (taban fiyatın katı olarak, 21 yuva için `Σ r^0..r^20`):

| Oran | 21. adet / 1. adet | 21 yuvanın toplamı |
| ---: | ---: | ---: |
| 1,07 | 3,87× | 44,9× |
| 1,08 | 4,66× | 50,4× |
| 1,10 | 6,73× | 64,0× |
| 1,15 | 16,4× | 118,8× |
| 1,20 (GDD) | 38,3× | 225× |
| 1,35 (mevcut) | 404× | 1.556× |

**Sonuç [Hesap + Öneri]:** Yerel sayaçta tekrar oranı ekonominin genel frenini oluşturmaz. Yalnızca "aynı yere bir tane daha" kararının yerel cezasıdır. Bu yüzden 1,07 ile 1,10 arasındaki fark oyun temposunda neredeyse görünmez (bkz. §3.5, model tablosu). Oran seçimi şu soruya göre yapılmalı: Yuvanın son adedi ilkine göre kaç kat pahalı olsun? Makalenin geri ödeme mantığıyla bunun cevabı 4–5 kattır, bu da **1,07–1,08** demektir. 1,35'te son yuva 404 kat pahalıdır. Bu, yuvaları anlamsızlaştırır: mevcut kodda 21. Market 60.600 kredi tutar ve geri ödemesi 1.000 dakikayı geçer.

### 2.2 Büyüme nereden gelmeli? [Öneri]

Yerel sayaçta üstel fren katmanların kapılarından gelmelidir:

| Katman | Üretimi büyüten | Maliyeti büyüten (fren) |
| --- | --- | --- |
| Bina adedi | +1 bina | Bina tekrar oranı (düşük, yerel) |
| District seviyesi | Çıktı ×g (GDD: g = 1,25) ve +2 yuva | District seviye kredisi (**ana fren**) + nüfus |
| District sayısı | Yeni taban ve yuva | District tekrar oranı (City içinde) |
| City seviyesi | +2 district kapasitesi | City seviye kredisi + seviye eşiği |
| City sayısı | Yeni taban ve 15.000 kapasite | City tekrar oranı |
| Gezegen seviyesi | +1 City kapasitesi | Gezegen kredisi + isimli malzeme |
| Model ve tier | Yuva başına daha çok çıktı (T2 ×3 çıktı / 2 yuva) | Araştırma bedeli + isimli malzeme |
| Araştırma | +%10/seviye, 3 seviye | Science, çapraz dal +%2 |

**Sağlıklı yarışın kuralı [Hesap → Öneri]:** Her katmanda `maliyet büyüme oranı / çıktı büyüme oranı ≥ ~1,5` olmalı. District seviyesinde bu `seviye kredisi büyümesi / g` demektir. GDD'de bu oran 1,25/1,25 = **1,0** olduğu için yarış tersine döner (bkz. §3.3). Model taramasında oran ~1,4'ün altına indiğinde gezegen çoğu kombinasyonda 60 dakika içinde Lv8–10'a koşuyor. Oran ~1,5'te ise ilerleme 2–3 gezegen seviyesinde makul kalıyor (§3.5).

### 2.3 Maliyet ve çıktı sağlıklı yarışıyor mu? Kısa cevap [Hesap]

- **Mevcut kod: patlıyor.** Bina ×1,35, district seviyesi ×2,2 kredi ve ×2 nüfus, City seviyesi ×2,5, City ×2,5 ve district ×1,6 ile maliyetler hızla büyüyor. Çıktı ise doğrusal: seviye yalnız district tabanını büyütüyor (`1 + 0,5(L−1)`), binaları büyütmüyor. Seviye yükseltmenin geri ödemesi Lv1→2'de 9 dakika, Lv9→10'da 2.400 dakika.
- **GDD: düzleşiyor, yani tersine dönüyor.** Seviye kredisi ile seviye çıktısı aynı oranla (1,25) büyüdüğünden seviye yükseltmenin geri ödemesi seviye arttıkça **kısalıyor**: 4,8 dakikadan 0,9 dakikaya. Nüfus yükü de 1,25 ile büyüyor ve çok küçük kalıyor (Lv1→10 toplamı 12.900).
- **Önerilen:** Seviye kredisi ×1,9 (çıktı ×1,25 kalırsa) veya ×1,8 (çıktı ×1,20'ye inerse). Geri ödeme 6 dakikadan 30 dakikaya yavaşça uzuyor.

---

## 3. Mevcut durum analizi

### 3.1 Koddaki formüller [Hesap]

| Kalem | Kod | Formül |
| --- | --- | --- |
| Bina fiyatı | `Economy.building_cost` | `taban × 1,35^(districtteki bütün bina adedi)` |
| District yeri | `DistrictDef.placement_cost` | `300 × 1,6^(City'deki district sayısı)`, tür fark etmez |
| City | aynı | ilk 0, sonra `2.500 × 2,5^(c−2)` (Orbit bir City sayılır) |
| District seviye kredisi | `Leveling.district_level_credits` | `400 × 2,2^(L−1)` |
| District seviye çıktısı | `DistrictDef.level_mult` | `1 + 0,5(L−1)`, **yalnız district tabanına**. Bina çıktısı (`ProductionManager.output_per_cycle`) seviyeden etkilenmiyor. |
| District kuruluş nüfusu | `Economy.district_found_pop` | `3.000 × (1 + 0,5k)`, k = City'deki sıra |
| District seviye nüfusu | `Economy.level_up_pop` | `2.000 × 2^(L−1)` |
| City seviyesi | `Leveling.city_level_*` | kredi `1.500 × 2,5^(n−2)`, nüfus `4.000(n−1)`, eşik `1,5·n(n−1)` |
| Gezegen seviyesi | `PlanetProgress.get_upgrade_cost` | 4.000; 12.000 + 200 ham; sonra `8.000n` + `250n` ham (+ Lv5'ten itibaren Goods). **Doğrusal.** |
| Nüfus açığı | `Economy.pop_speed` | Süre uzar, en kötü %50 hız (KARARLAR §3 bunu çıktı azaltmaya çevirecek) |
| Araştırma | `SkillTree.get_next_cost` | `taban × (1 + mevcut seviye)`, çok seviyeli düğümler en fazla 5 seviye |
| Başlangıç | `GameState.start_credits` | 1.000 kredi (`delete_save` 500'e sıfırlıyor). GDD: 3.000 kredi + 450 Science |

### 3.2 Maliyet tabloları, n = 1, 5, 10, 20 [Hesap]

**Bina (taban 150), n. adet fiyatı**

| Oran | n=1 | n=5 | n=10 | n=20 |
| --- | ---: | ---: | ---: | ---: |
| ×1,07 | 150 | 197 | 276 | 542 |
| ×1,08 | 150 | 204 | 300 | 647 |
| ×1,10 | 150 | 220 | 354 | 917 |
| ×1,20 (GDD) | 150 | 311 | 774 | 4.792 |
| ×1,35 (mevcut) | 150 | 498 | 2.234 | 44.919 |

**District yeri, City içindeki n. district**

| Kural | n=1 | n=3 | n=5 | n=9 | n=13 | n=21 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Mevcut 300×1,6^(n−1) | 300 | 768 | 1.966 | 12.885 | 84.442 | 3.626.777 |
| GDD 300×1,5^(aynı aile) | 300 | 675 | 1.519 | 7.689 | 38.924 | 997.577 |
| Öneri 300×1,30^(n−1) | 300 | 507 | 857 | 2.447 | 6.989 | 57.015 |

**City (gövdedeki c. City)**

| c | Mevcut 2.500×2,5^(c−2) | GDD 2.000×1,5^(c−2) | Öneri 2.000×1,6^(c−2) |
| ---: | ---: | ---: | ---: |
| 2 | 2.500 | 2.000 | 2.000 |
| 3 | 6.250 | 3.000 | 3.200 |
| 4 | 15.625 | 4.500 | 5.120 |
| 5 | 39.062 | 6.750 | 8.192 |
| 6 | 97.656 | 10.125 | 13.107 |
| 8 | 610.352 | 22.781 | 33.554 |

**District seviyesi (L → L+1)**

| L | Mevcut kredi 400×2,2^(L−1) | GDD kredi 250×1,25^(L−1) | Öneri A 300×1,9^(L−1) | Mevcut nüfus 2.000×2^(L−1) | GDD nüfus 500×1,25^(L−1) | Öneri nüfus 1.500×1,5^(L−1) |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 400 | 250 | 300 | 2.000 | 500 | 1.500 |
| 3 | 1.936 | 391 | 1.083 | 8.000 | 781 | 3.375 |
| 5 | 9.370 | 610 | 3.910 | 32.000 | 1.221 | 7.594 |
| 7 | 45.352 | 954 | 14.114 | 128.000 | 1.907 | 17.086 |
| 9 | 219.503 | 1.490 | 50.951 | 512.000 | 2.980 | 38.443 |
| **Toplam 1→10** | **402.090** | **6.451** | **107.229** | **1.022.000** | **12.901** | **112.330** |

**City seviyesi (hedef n)**

| n | Mevcut kredi | Mevcut eşik | GDD kredi | GDD eşik | Öneri kredi 1.200×1,8^(n−2) |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 2 | 1.500 | 3 | 1.000 | 3 | 1.200 |
| 3 | 3.750 | 9 | 1.500 | 6 | 2.160 |
| 4 | 9.375 | 18 | 2.250 | 10 | 3.888 |
| 5 | 23.438 | 30 | 3.375 | 15 | 6.998 |
| 10 | 2.288.818 | 135 | 25.629 | 55 | 132.240 |

**Gezegen seviyesi (hedef n)**

| n | Mevcut | GDD 2.000×1,5^(n−2) | Öneri 2.500×1,8^(n−2) |
| ---: | ---: | ---: | ---: |
| 2 | 4.000 | 2.000 | 2.500 |
| 3 | 12.000 + 200 ham | 3.000 | 4.500 |
| 4 | 32.000 + 1.000 ham | 4.500 | 8.100 |
| 5 | 40.000 + … | 6.750 | 14.580 |
| 10 | 80.000 + … | 51.258 | 275.499 |

### 3.3 Geri ödeme süreleri [Hesap]

Bina geri ödemesi, seviye çarpanı olmadan (Lv1 district), dakika cinsinden: `fiyat / (kredi eşdeğeri/dk)`. Enerji bakımı dahil değil.

**Mevcut kod değerleri, ×1,35 (districtteki bütün binalar sayılır)**

| Bina | Taban | Kr-eşd./dk | n=1 | n=5 | n=10 | n=20 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Market | 150 | 60 | 2,5 | 8,3 | 37,2 | 749 |
| Harbor Market | 700 | 210 | 3,3 | 11,1 | 49,6 | 998 |
| Bazaar (−1 Goods) | 400 | 106 | 3,8 | 12,6 | 56,4 | 1.134 |
| Mine (3 ham) | 200 | 16 | 12,3 | 41,0 | 184 | 3.697 |
| Goods Factory | 500 | 97 | 5,1 | 17,1 | 76,6 | 1.540 |
| Lab (2 Sci/30 sn) | 150 | 18 | 8,3 | 27,7 | 124 | 2.496 |
| Mountain Observatory | 900 | 72 | 12,5 | 41,5 | 186 | 3.743 |
| Commodity Exchange | 1.800 | 361 | 5,0 | 16,6 | 74,3 | 1.495 |

**GDD katalog değerleri, ×1,20 (aynı model)**

| Bina | Taban | Kr-eşd./dk | n=1 | n=5 | n=10 | n=20 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Market | 150 | 60 | 2,5 | 5,2 | 12,9 | 79,9 |
| Mine (10 ham) | 200 | 54 | 3,7 | 7,7 | 19,1 | 118 |
| Goods Factory | 300 | 97 | 3,1 | 6,4 | 15,9 | 98,6 |
| Lab (4 Sci/20 sn) | 150 | 54 | 2,8 | 5,8 | 14,3 | 88,7 |
| Research Institute | 450 | 162 | 2,8 | 5,8 | 14,3 | 88,7 |
| Commodity Exchange | 1.800 | 810 | 2,2 | 4,6 | 11,5 | 71,0 |

**GDD katalog değerleri, ×1,07**

| Bina | n=1 | n=5 | n=10 | n=20 |
| --- | ---: | ---: | ---: | ---: |
| Market | 2,5 | 3,3 | 4,6 | 9,0 |
| Mine | 3,7 | 4,9 | 6,8 | 13,4 |
| Goods Factory | 3,1 | 4,0 | 5,7 | 11,2 |
| Lab | 2,8 | 3,6 | 5,1 | 10,0 |
| Commodity Exchange | 2,2 | 2,9 | 4,1 | 8,0 |

**District seviye yükseltmesinin geri ödemesi (dakika).** Varsayım: Commercial district dolu (3 + 2(L−1) Market), taban 30 kr/dk, Market 60 kr/dk. Mevcut satırda yeni açılan iki yuvaya konacak Market'lerin bedeli ve getirisi de dahildir.

| Şema | L1→2 | L3→4 | L5→6 | L7→8 | L9→10 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Mevcut: 400×2,2^(L−1), taban +%50, 2 yeni Market (×1,35) | 9,4 | 35,7 | 140 | 571 | 2.408 |
| GDD: 250×1,25^(L−1), çıktı ×1,25 | 4,8 | 2,2 | 1,4 | 1,1 | **0,9** |
| Öneri A: 300×1,9^(L−1), çıktı ×1,25 | 5,7 | 6,2 | 9,3 | 15,9 | 29,2 |
| Öneri B: 300×1,8^(L−1), çıktı ×1,20 | 7,1 | 7,5 | 11,0 | 18,4 | 32,9 |

### 3.4 Nerede patlıyor, nerede düzleşiyor? [Hesap]

**Mevcut kodda patlayanlar**

1. **Bina ×1,35, bütün türler ortak sayaçta.** Bir districtin 10. binası tabanın 20 katı, 21. binası 404 katıdır. Geri ödeme 5. adetten sonra 10 dakikayı, 10. adetten sonra 30 dakikayı geçer. Lv5+ yuvalar pratikte doldurulamaz.
2. **District seviyesi.** Kredi ×2,2 ve nüfus ×2 büyürken getiri doğrusal ve yalnız tabana uygulanıyor. Lv1→10 toplamı 402.090 kredi ve 1.022.000 nüfus tutuyor. Tek bir Lv10 district için gereken nüfus, 68 City'nin 15.000'lik tabanına eşit.
3. **City seviyesi ×2,5.** Lv10 tek başına 2,29 milyon kredi. Eşik `1,5·n(n−1)`, GDD'nin `n(n+1)/2`'sinin yaklaşık 3 katı.
4. **City ×2,5.** 6. City 97.656, 8. City 610.352 kredi.
5. **District ×1,6.** 13. district 84.442, 21. district 3,6 milyon kredi.

**Mevcut kodda düzleşenler**

- **Gezegen seviyesi doğrusal (8.000n).** Diğer her şey üstelken Lv10 yalnız 80.000. Gezegen seviyesi geç oyunda en ucuz kapıya dönüşüyor.

**Mevcut koddaki iç dengesizlik**

- Kredi eşdeğeriyle Mine (12,3 dk) ve Lab (8,3 dk), Market'ten (2,5 dk) 3–5 kat kötü.
- GDD bunu düzeltiyor (Mine 10 ham, Lab 4 Sci/20 sn). Bütün T1'ler 2,5–3,7 dakikada toplanıyor.

**GDD'de düzleşenler (yarış tersine dönüyor)**

1. **District seviyesi.** Kredi 1,25, çıktı 1,25 ile büyüyor ve yükseltme yuva da açıyor. Bu yüzden geri ödeme seviyeyle kısalıyor (4,8 → 0,9 dk). Seviye yükseltmek her zaman ilk tercih oluyor.
2. **Seviye nüfusu.** 500×1,25 ile Lv1→10 toplamı 12.900 nüfus, yani tek bir City tabanından az. Nüfus pratikte fren değil.
3. **City seviyesi (1.000×1,5) ve gezegen seviyesi (2.000×1,5).** Bunlar da çıktının toplam büyümesinin (yuva × 1,25^L × district sayısı) altında kalıyor.

### 3.5 Model: açgözlü oyuncu simülasyonu [Model]

**Yöntem.** Makale I'deki "en iyi gelir/maliyet oranını al" modeli. Betik scratchpad'de, repoda değil.

- **Para birimi:** Tek birim, kredi eşdeğeri/dk.
- **Bina:** T1 bina 150 kredi, 60/dk.
- **Tabanlar:** District tabanı 30/dk, City merkezi 78/dk.
- **Başlangıç ve süre:** 3.000 kredi, 80 dakika.
- **Hedef:** Gelirin %40'ı "hedef kovası"na gider. Kova 70.000'e ulaştığında hedefe varılmış sayılır. Bu, GDD §16.11'deki ~43.500 kredilik yalın Ay paketi + ~6.050 Science'ın (~27.000 kr) kaba karşılığıdır.

**Modelde olmayanlar:**

- nüfus, enerji, isimli malzeme
- inşaat süresi, araştırma kapıları
- coğrafya ve yakınlık
- oyuncu dikkati

Bu yüzden model süreleri **alt sınırdır**. Gerçek oyun belirgin şekilde daha yavaş olur.

| Şema | Hedefe varış (dk) | Gelir 30. dk | Gelir 60. dk | 60/30 | 0–60 dk'da büyük karar* | Büyük kararlar arası medyan (sn) | Gezegen Lv (80. dk) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Mevcut kod | 54,4 | 3.036 | 8.454 | 2,8 | 59 | 51 | 2 |
| GDD (aile sayacı tek aile kabul edildi) | 22,2 | 83.213 | 1.759.717 | **21,1** | 1.926 | 1 | **10** |
| GDD + bina ×1,07 | **10,5** | 1.884.663 | 2.221.057 | 1,2 | 2.428 | 0 | **10** |
| Mevcut + bina ×1,07 | 46,7 | 4.326 | 12.099 | 2,8 | – | – | 2 |
| **Öneri A** (bina 1,07; seviye ×1,25 / kredi 300×1,9; district 1,30; City lv 1.200×1,8; gezegen 2.500×1,8) | 28,4 | 21.442 | 90.993 | 4,2 | 101 | 23 | 3 |
| **Öneri B** (bina 1,08; seviye ×1,20 / kredi 300×1,8; diğerleri A gibi) | 30,4 | 16.818 | 78.946 | 4,7 | 143 | 11 | 3 |
| Öneri C (bina 1,10; seviye ×1,15 / kredi 300×1,7) | 32,8 | 12.263 | 55.838 | 4,6 | 143 | 16 | 3 |
| Öneri B, district ×1,60 (mevcut oran) | 32,2 | 14.041 | 55.503 | 4,0 | 96 | 16 | 3 |
| Öneri B, bina ×1,20 | 34,9 | 10.495 | 42.853 | 4,1 | 87 | 31 | 2 |
| Öneri B, bina ×1,35 | 39,9 | 6.449 | 28.228 | 4,4 | 96 | 24 | 3 |

\* Büyük karar: district kurma, seviye yükseltme, City, gezegen. Bina tıklamaları sayılmadı.

Taramada (96 kombinasyon) bina oranı 1,07 ile 1,10 arasında gidip gelmek hedef süresini yalnız 1–2 dakika oynatıyor. Seviye kredisi büyümesinin çıktı büyümesine oranı ise belirleyici:

- **≤ 1,36:** Gezegen Lv8–10 ve 60/30 gelir oranı 10–29. Kaçak büyüme var.
- **≥ 1,48:** Gezegen Lv2–3 ve 60/30 gelir oranı ~4. Kontrollü büyüme.

**Modelde nüfusun durumu [Hesap].** Model nüfusu yok saydığı için districtleri Lv10'a çıkarıyor. Mevcut nüfus kurallarıyla bu son durumların yükü şöyle:

| Şema | Nüfus yükü | Kapasite |
| --- | ---: | ---: |
| Öneri A | 25,8 milyon | 60.000 |
| Mevcut kod | 487.500 | 45.000 |

KARARLAR §3'ün mevcut nüfus ölçeklemesi gerçekte en sert fren olur. Bu durum Risk 5.5'te ayrıca değerlendiriliyor.

---

## 4. Önerilen başlangıç değerleri [Öneri]

### 4.1 Gerekçe: geri ödeme hedefleri

GDD §16'nın hedefleri Tip 0 için 45–75 dakika ve 30–90 saniyede bir anlamlı karar. Bunları makalenin geri ödeme mantığına çevirdim:

| Ölçü | Erken (0–15 dk) | Orta (15–40 dk) | Geç (40–75 dk) |
| --- | --- | --- | --- |
| Tek bina geri ödemesi | 2–4 dk | 4–8 dk | 8–15 dk |
| District seviye geri ödemesi | 5–7 dk | 7–12 dk | 12–30 dk |
| Sıradaki büyük kararı karşılama süresi (fiyat/toplam gelir) | 15–45 sn | 30–90 sn | 60–120 sn |
| Bina tıklaması | Toplu alımla tek karar | aynı | aynı |

Model (§3.5) Öneri A/B için hedefe nüfus, enerji ve malzeme olmadan ~28–30 dakikada varıyor. Bu sürtünmeler hedefi 45–75 dakika bandına itmelidir. Test edilmeden bu bir **tahmindir**.

### 4.2 Değer tablosu

| Sabit | Mevcut kod | GDD | **Öneri** | Gerekçe |
| --- | --- | --- | --- | --- |
| Bina tekrar oranı | 1,35 | 1,20 | **1,08** (bant 1,07–1,10) | Yerel sayaçta 21. yuva ≈ 4,7× fiyat. Geri ödeme 2,5 → ~11 dk (§3.3). KARARLAR'ın 1,07'si de kabul edilebilir, fark modelde 1–2 dk. |
| Bina sayaç anahtarı | District, bütün binalar | District + model | **District + model** (KARARLAR §1 ile uyumlu) | 1,08'de anahtarın uzmanlaşmaya etkisi küçük (§5.3). |
| District yeri | 300 × 1,6^n, City içi, tür fark etmez | 300 × 1,5^(aynı aile) | **300 × 1,30^n, tür fark etmez** (bant 1,25–1,40) | KARARLAR §2'nin türden bağımsız anahtarı korunur. Oran 1,6'dan inmeli: 13. district 84k → 7k, 21. district 3,6M → 57k. District "jeneratör üreten jeneratör" olduğundan oranı binadan dik kalmalı. |
| City | 0; 2.500 × 2,5^(c−2) | 0; 2.000 × 1,5^(c−2) | **0; 2.000 × 1,6^(c−2)** | 6. City 13k. City de bir alt ağaç doğurduğu için GDD'den biraz dik. |
| District seviye çıktısı | 1 + 0,5(L−1), yalnız taban | 1,25^(L−1), taban + binalar | **1,25^(L−1)** (A) veya **1,20^(L−1)** (B) | GDD kabul edildi (KARARLAR §7). B daha güvenli: L10 ×5,16 yerine ×7,45. |
| District seviye kredisi | 400 × 2,2^(L−1) | 250 × 1,25^(L−1) | **300 × 1,9^(L−1)** (A) veya **300 × 1,8^(L−1)** (B) | Kural: kredi büyümesi ≥ 1,5 × çıktı büyümesi. Geri ödeme 6 → 30 dk. |
| District seviye nüfusu | 2.000 × 2^(L−1) | 500 × 1,25^(L−1) | **1.500 × 1,5^(L−1)** | KARARLAR §3 "ölçeklenmeye devam" der. Ölçekleme korunur, üs 2 → 1,5'e iner. Lv1→10 toplamı 1,02M → 112k. Konut çıktısı seviyeyle 1,25 büyüdüğünden nüfus yine de giderek önemli kalır. |
| District kuruluş nüfusu | 3.000 × (1 + 0,5k) | 500 sabit | **2.000 × (1 + 0,25k)** | Mevcut doğrusal yapı korunur, eğim yarıya iner. 21 districtin toplamı 378k → 147k. |
| City seviye kredisi | 1.500 × 2,5^(n−2) | 1.000 × 1,5^(n−2) | **1.200 × 1,8^(n−2)** | Lv5 7k, Lv10 132k. |
| City seviye eşiği | 1,5·n(n−1) | n(n+1)/2, Capital hariç | **n(n+1)/2** | Mevcut eşik, düşük oranlarla gereksiz bekleme yaratır. |
| City seviye nüfusu | 4.000(n−1) | 2.000 × 1,25^(n−2) | **3.000 × 1,3^(n−2)** | Ara değer. |
| Gezegen seviye kredisi | 4k, 12k, 8.000n | 2.000 × 1,5^(n−2) + malzeme | **2.500 × 1,8^(n−2) + GDD malzeme listesi** | Doğrusal eğri geçte en ucuz kapıya dönüşüyordu. Lv3 4,5k, Lv5 14,6k, Lv10 275k. |
| Araştırma seviye fiyatı | taban × (1 + lv), en fazla 5 seviye | taban × hedef seviye × (1 + 0,02 × diğer dal düğümü), en fazla 3 seviye | **GDD aynen** | Doğrusal seviye ve 3 seviye, +%10'luk etkilerle uyumlu. Çapraz dal +%2 hafif bir fırsat maliyeti. |
| Araştırma düğüm tabanları | 20–7.000 | 75–2.000; ortak yol 6.500 | **GDD aynen**, ilk testte dokunma | Asıl ayar Science gelirinde (Lab 12 Sci/dk, boş nüfus). |
| Başlangıç | 1.000 kr (500 sıfırlamada) | 3.000 kr + 450 Sci | **3.000 + 450** | Model 3.000 ile kuruldu. |
| Nüfus açığı tabanı | Süre, %50 hız | Çıktı, 0,5 + 0,5k | **0,5 + 0,5k**, sabit tunable | Bkz. §5.5. |
| Çarpan eşikleri | yok | yok (seviye var) | **İlk testte eklenmesin** | Seviyeler zaten eşik görevini görüyor. İsteğe bağlı: §4.3. |

**Not.** "A" ve "B" iki tutarlı pakettir; ikisi karıştırılmamalı. İlk denge testi için **B**'yi öneriyorum:

- Bina 1,08
- Seviye çıktısı ×1,20, seviye kredisi 300×1,8
- District 1,30, City 2.000×1,6
- City seviyesi 1.200×1,8, gezegen 2.500×1,8

B, GDD'nin ×1,25 kararından küçük bir sapmadır ve kaçak büyüme riskinden daha uzaktır. GDD'ye sadık kalmak istenirse A kullanılabilir.

### 4.3 İsteğe bağlı çarpan eşikleri [Öneri]

Makale I'in "jeneratöre göre farklı eşik" fikri bizde aile başına seviye çıktısı olarak uygulanabilir. Örneğin Science ve Production seviye başına ×1,22, Commercial ×1,18. Böylece öncelik oturum içinde el değiştirir. Adet eşikleri (25, 50 gibi) bizim yerel 21 yuvalı sayaçlarımıza uymuyor. Önerim bu çeşitlendirmeyi ilk testten sonra, "her şey aynı yolu izliyor" gözlemi çıkarsa açmak.

### 4.4 Toplu alım

Bina oranı 1,07–1,10'a indiğinde model bina alımlarının %75–85'ini 10 saniyeden kısa bekleme gerektiren tıklamalar olarak gösteriyor [Model]. Makale I'in formülleriyle "districti doldur" veya "×5 / azami" alımı eklenmeli:

- maliyet: `b × r^k × (r^n − 1)/(r − 1)`
- azami adet: `floor(log_r(c(r−1)/(b r^k) + 1))`

Böylece anlamlı kararlar (district, seviye, City) 30–90 saniyelik ritmi taşır, bina alımı tek karar olur.

---

## 5. Riskler

### 5.1 Sınırsız yakınlık bonusu (GDD §7.5) [Hesap + Öneri]

**Kural.** Çok yakın (≤500 km) her aynı aile kaynağı +%10, yakın (≤1.000 km) +%5 verir, tavan yoktur. N'lik tam kümenin toplamı `N × taban × (1 + 0,1(N−1))`. N. districtin marjinal değeri ise `taban × (1 + 0,2(N−1))`: 5. district 1,8×, 10. district 2,8×.

**Fiziksel sınır.** District arası minimum 250 km'lik altıgen dizilimde bir districtin 500 km içinde en fazla 18 komşusu olur (6 + 6 + 6). Pratik tavan yaklaşık +%180'dir. GDD'nin "20 kaynak = +%200" örneği bu tavana yakın.

**Uzaklık bonusuyla kıyas.** Uzaklık bonusu en fazla +%50 ve en yakın komşudan ölçülür; kümedeki district bunu alamaz. Yakınlık ≥5 kaynakta +%50'yi geçer, bu yüzden 6+ district kuran oyuncu için kümelenme kesin baskın strateji olur. GDD'nin "yakın ile uzak arasında gerçek tercih" hedefi orta oyundan sonra çöker.

**Çarpımsal birikim.** GDD §13.11'e göre etki grupları çarpılır. Lv10 (×7,45) × yakınlık (×2,8) × coğrafya × araştırma ile tek district taban çıktısının 20–25 katına çıkar. Küme Planlama Lv3 ile %10'luk pay %13 olur (×3,34).

**Olumlu yanı.** Türden bağımsız district fiyatıyla birlikte aynı aileyi bir City'de toplamayı ödüllendirir. Bu KARARLAR §2'nin uzmanlaşma hedefine hizmet eder.

**Öneri:**

- `PROXIMITY_CAP = +%100` (çok yakın + yakın toplamı; Küme Planlama tavanı da ×1,3 büyütsün).
- Alternatif: ilk 5 kaynak %10, sonraki 5 kaynak %5, sonrası %2,5. Bunda 20 kaynak +%100 eder.
- Uzaklık bonusu en fazla +%50'de kalırsa denge noktası ~5 komşu olur. Bu bir tercih aralığı bırakır.

### 5.2 Boş nüfus geliri (GDD §9.7, KARARLAR §3) [Hesap + Öneri]

**Değer.** 1.000 boş nüfus = +10 kr/dk + 2 Sci/dk ≈ **19 kredi eşdeğeri/dk**.

- **Başlangıçta.** İlk City'nin 13.000 boş kapasitesi 130 kr + 26 Sci/dk verir. Bu, City tabanının (60 kr + 4 Sci) Science'ta **6,5 katı**. GDD §16.8 bunu bilinçli "nüfus yolu" sayıyor.
- **Habitat Block (GDD).** 2.500 kapasite, 120 kredi. Boşken 48 kr-eşd/dk getirir, geri ödemesi 2,5 dk. Bu, Market (2,5 dk) ile aynıdır; üstelik çalışan istemez ve başka üreticilere nüfus sağlar.
- **District seviyesiyle birlikte.** GDD §13.3'e göre konut kapasitesi de seviye çarpanını alır, Residential seviye yükü ise 0'dır. Lv10 Residential + 21 Habitat Block + Konut Verimi %30 ≈ 520.000 kapasite eder. Boşken bu ≈ **9.900 kr-eşd/dk** demektir. Aynı seviyedeki 21 Market'li Commercial ≈ 9.600 kr/dk verir ve üstüne nüfus ister. Konut, "nüfus sağlayan" bir destek olmaktan çıkıp **baskın bir gelir ailesine** dönüşüyor.
- **Mevcut kod konut değerleriyle (çok daha büyük) uygulanırsa:**

| Bina | Kapasite | Fiyat | Boşken getiri | Geri ödeme |
| --- | ---: | ---: | ---: | ---: |
| Luxury | 60.000 | 1.400 | 1.140 kr-eşd/dk | 1,2 dk |
| Arcology | 300.000 | 3.500 | 5.700 kr-eşd/dk | 0,6 dk |

Uygulamada kesinlikle önce GDD konut değerlerine geçilmeli.

**Öneri:**

1. Değerleri yarıya indir: **+5 kr/dk, +1 Sci/dk per 1.000**. Habitat Block'un geri ödemesi ~5 dk olur, Market'in iki katı.
2. Boş nüfus gelirine **district seviye çarpanını uygulama**. Alternatif olarak geliri `√(boş)` gibi azalan getirili bir eğriye bağla.
3. PLAN açık soru 2 için: City'nin ücretsiz 15.000'i dahil edilecekse (GDD böyle der) erken Science'ın ~26/dk'sı oradan gelir. Bu, araştırma hızı hedefine (80–135 Sci/dk ortalama, §16.7) bilinçli olarak sayılmalı.
4. Sabitleri tek yerde tut: `IDLE_POP_CREDITS_PER_1000`, `IDLE_POP_SCIENCE_PER_1000`, `IDLE_POP_COUNT_CITY_BASE`.

### 5.3 Düşük tekrar oranı ile uzmanlaşma (KARARLAR §2) [Hesap]

**Bina tarafı.** Sayaç model başınaysa farklı modele geçmenin cazibesi `r^(adet)` ile ölçülür. 6. aynı modelin fiyatı:

| Oran | 6. aynı model / 1. yeni model |
| ---: | ---: |
| 1,07 | 1,40× |
| 1,20 | 2,49× |
| 1,35 | 4,48× |

Düşük oranda karıştırma baskısı neredeyse yoktur, yani uzmanlaşmayı **öldürmez**. Sayaç district genelindeyse (mevcut) oran tür seçimini hiç etkilemez. Bu yüzden KARARLAR §2'deki açık soru 1,07–1,10 bandında pratikte önemsizdir.

**District tarafı.** Sorun aile başına sayaçtı (GDD 1,5). Beş ailenin her biri 300'den başladığı için her City'ye her aileyi kurmak en ucuzuydu. Türden bağımsız sayaçta oran ne olursa olsun aile seçimi fiyattan bağımsızdır. Önerdiğim ×1,30 bu kararı bozmaz, yalnız City başına district sayısının frenini yumuşatır.

**Gerçek risk ters yönde.** Düşük district oranı + sınırsız yakınlık + aile içi seviye çarpanı ile **tek aileli dev kümeler** baskın olur. Örneğin bütün gezegende Commercial kümeleri ve Residential boş nüfus çiftlikleri. Uzmanlaşma artık bir tercih olmaktan çıkıp zorunluluk olabilir. Bunu §5.1 ve §5.2'deki tavanlar sınırlar. Testte "City başına aile çeşitliliği" ölçülmeli (§6).

### 5.4 Fraktal miras: 4.000 × 10^(tip−1) Science (GDD §17.30–17.32) [Hesap]

Miras klasik bir prestij değildir: reset yok, kalıcı çarpan yok. Alt medeniyetin bütün araştırma haklarını azami seviyede tamamlayan tek bir satın almadır. Makale III'ün prestij formülleri doğrudan uygulanmaz, ama iki ilkesi geçerlidir:

- ödül hissedilmeli
- ödülün maliyeti ilerlemeyle doğru oranda büyümeli

**Fiyat oranı.** Tip 0 ağacının toplamı:

| Kalem | Science |
| --- | ---: |
| Ortak yol | 6.500 |
| 42 tekil strateji düğümü | 17.100 |
| 9 adet 3 seviyeli düğüm (her biri 6× taban) | 9.600 |
| **Toplam (çapraz dal zammı hariç)** | **33.200** |

Ortalama ~%40 çapraz dal zammıyla toplam ≈ 45.000 olur. Miras bunun **%9–12'sine** tüm eksikleri veriyor.

**Riskler:**

1. **Ertele stratejisi.** Tam oyunda oyuncu, Tip 0'ın isteğe bağlı strateji düğümlerini almayıp Tip 1'de 4.000'e toplamak ister. Bu, KARARLAR §7'nin kabul ettiği strateji derinliğini aşındırır. Demoda miras yalnız önizleme olduğu için **demo için risk yok**.
2. **Sabit ×10 artış.** Tip başına Science geliri ×10'dan hızlı büyürse miras giderek "bedava" olur, yavaş büyürse duvar olur. Tip 1 ekonomisi tasarlanmadan bu çarpan doğrulanamaz.

**Öneri:** `fiyat = max(4.000 × 10^(t−1), MIRAS_PAYI × eksik düğümlerin zamsız toplamı)`, `MIRAS_PAYI ≈ 0,5`. Böylece miras bir indirimdir, ama ertelemeyi ödüllendiren bir kısayol olmaz.

### 5.5 Nüfus: KARARLAR §3 ve %50 tabanı [Hesap]

KARARLAR'a göre nüfus maliyetleri mevcut ölçeklemeyle kalacak, açıkta çıktı `0,5 + 0,5 × karşılama` olacak.

**Açıktaki davranış.** Açıkta toplam çıktı `Y = 0,5·Y_nom + 0,5·P·(Y_nom/U)` olur.

- Her yeni üretici nominal çıktısının **en az %50'sini** daima ekler.
- Her ek konut nüfusu ise ortalama "nüfus başına verimin" yarısı kadar ekler.

Nüfus bir duvar değil, aşırı kuruluşa uygulanan **en fazla %50'lik bir vergidir**.

**Mevcut ölçeklemeyle sorun.** Seviye nüfusu ×2 büyür (Lv10 için 1,02M). GDD'nin ×1,25 seviye çarpanıyla Lv1→10 çıktı ×7,45 olur. Nüfusu tamamen yok sayıp her şeyi Lv10'a çıkaran oyuncu ×0,5 ile bile ×3,7 net kazanır. Dolayısıyla "mevcut ölçekleme" kağıt üzerinde sert, pratikte **göz ardı edilebilir** olur. Bu, KARARLAR'ın niyetiyle çelişiyor gibi görünüyor.

**Öneri:**

- Seviye nüfusu `1.500 × 1,5^(L−1)` olsun (§4.2). Açık tabanı ilk testte 0,5 kalsın.
- Testte "açıkta geçen süre oranı" %30'u aşarsa tabanı 0,35'e indir.
- Alternatif: yalnız seviye yükseltmesini (konutu değil) boş nüfus şartına bağla.

---

## 6. Denge testi için öneriler

### 6.1 İzlenecek ölçüler

| Ölçü | Hedef / alarm |
| --- | --- |
| Ay'a varış ve Tip 0 tamamlanma süresi | Ay 15–35 dk, Tip 0 45–75 dk (GDD §16.10) |
| Büyük kararlar arası süre (district, seviye, City, gezegen, araştırma) | Medyan 30–90 sn. 3 dakikadan uzun boşluk alarm. |
| "Sıradaki en iyi alımı karşılama" süresinin dağılımı | Oturum boyunca yavaş artmalı. Sıçrama duvar, sıfıra yakınlık düzleşme demek. |
| Her alımın geri ödeme süresi (bina / seviye / district) | §4.1 bantları. Geri ödeme seviyeyle **kısalıyorsa** yarış tersine dönmüştür. |
| 60. dk gelir / 30. dk gelir | 3–5 arası sağlıklı. >8 kaçak büyüme, <2 duvar. |
| Gelirin kaynak dağılımı (bina, district tabanı, boş nüfus, yakınlık payı, trade) | Boş nüfus >%25 veya yakınlık payı >%40 ise alarm. |
| Nüfus ve enerji karşılama oranı, açıkta geçen süre | Açıkta süre >%30 ise taban veya ölçek gözden geçirilmeli. |
| District seviye dağılımı (oturum sonunda) | Hepsi Lv10 ise seviye kredisi ucuz. Hepsi Lv2 ise pahalı. |
| City başına aile çeşitliliği (örneğin 1 − Σ pay², Herfindahl tümleyeni) | 0'a yakınsa zorunlu tek aile, 0,8'e yakınsa "her şey her yerde" (KARARLAR §2 sorunu). |
| Küme büyüklüğü ve yakınlık bonusu dağılımı | 10+ kümeler yaygınsa §5.1 tavanı gerekir. |
| Science/dk eğrisi ve kaynak payı | Ortak yol için ortalama 80–135 Sci/dk (GDD §16.7). |
| Bina alımlarının kaçı toplu alım | Toplu alım yoksa tıklama yorgunluğu raporlanmalı. |
| Depo taşmaları ve trade hacmi | Taşma oranı, alış/satış dengesi. Trade kısayola dönüşmemeli. |

### 6.2 Tek bir yerde tutulması gereken sabitler

Önerim tek bir `Balance` sınıfı veya Economy.gd'de bölümlenmiş sabitler. Şu an bu sabitler üç dosyaya dağılmış durumda: `DistrictDef.gd`, `Leveling.gd`, `PlanetProgress.gd`.

| Grup | Sabitler |
| --- | --- |
| Bina | `BUILD_COST_GROWTH`, `BUILD_COUNTER_KEY` (district/model) |
| District | `DISTRICT_BASE_COST`, `DISTRICT_COST_GROWTH`, `DISTRICT_FOUND_POP_BASE`, `DISTRICT_FOUND_POP_STEP` |
| City | `CITY_BASE_COST`, `CITY_COST_GROWTH`, `FIRST_CITY_FREE` |
| District seviyesi | `LEVEL_OUTPUT_GROWTH` (isteğe bağlı aile başına), `LEVEL_CREDIT_BASE`, `LEVEL_CREDIT_GROWTH`, `LEVEL_POP_BASE`, `LEVEL_POP_GROWTH`, `MAX_DISTRICT_LEVEL` |
| City seviyesi | `CITY_LEVEL_CREDIT_BASE`, `CITY_LEVEL_CREDIT_GROWTH`, `CITY_LEVEL_POP_BASE`, `CITY_LEVEL_POP_GROWTH`, eşik formülü |
| Gezegen | `PLANET_LEVEL_CREDIT_BASE`, `PLANET_LEVEL_CREDIT_GROWTH`, malzeme ölçeği |
| Açıklar | `POP_DEFICIT_FLOOR` (0,5), `ENERGY_DEFICIT_FLOOR` (0,5) |
| Boş nüfus | `IDLE_POP_CREDITS_PER_1000`, `IDLE_POP_SCIENCE_PER_1000`, `IDLE_POP_COUNT_CITY_BASE`, `IDLE_POP_USES_LEVEL_MULT` |
| Konum | `PROXIMITY_VERY_NEAR`, `PROXIMITY_NEAR`, `PROXIMITY_CAP`, `DISTANCE_BONUS_MAX` |
| Araştırma | `RESEARCH_CROSS_BRANCH` (0,02), `LEGACY_BASE` (4.000), `LEGACY_GROWTH` (10), `LEGACY_MISSING_SHARE` |
| Başlangıç ve offline | `START_CREDITS`, `START_SCIENCE`, `OFFLINE_PROGRESS_ENABLED` |
| Trade | Referans fiyat tablosu, satış oranı 0,9, alış oranı 1,1 |

Test kolaylığı için bir **hata ayıklama paneli** önerilir: sabitleri çalışırken değiştirsin ve §6.1'deki ölçüleri CSV'ye yazsın. Bu oyunu değiştirmez, yalnız ölçüm sağlar.

---

## 7. Belgeler ve kod arasında dikkat çeken noktalar

1. **KARARLAR iç çelişkisi.** §1 "Her model kendi fiyat sayacını kullanır" diyor. §2 ise bina sayacının district geneli mi model mi olacağını "açık" bırakıyor. PLAN açık soru 1 de aynı soruyu soruyor. Biri güncellenmeli. Önerim model başı: §1 ile uyumlu ve 1,08'de uzmanlaşmaya zararsız.
2. **KARARLAR §2 belirsizliği.** "District fiyatlandırması mevcut haliyle kalır" deniyor, ama aynı paragrafta ×1,07'nin "bina ve district için ayrı ayrı" sabit olacağı söyleniyor. Mevcut district oranı 1,6 ve `DistrictDef.gd`'de duruyor, Economy'de değil. District oranı 1,07 olursa 21 districtin hepsi 1.200 kredinin altında kalır ve City kapasitesi tek fren olur. Ben anahtarın (türden bağımsız) korunmasını, oranın 1,30'a inmesini öneriyorum. Bu yeni bir KARARLAR maddesi gerektirir.
3. **GDD seviye fiyatı ile çıktısı aynı oranda (1,25).** Bu, seviyelerin geri ödemesini seviyeyle kısaltıyor (§3.3). GDD'deki en kritik sayısal sorun bu.
4. **Mevcut kodda seviye bina çıktısını büyütmüyor.** Yalnız taban büyüyor. GDD binaları da büyütüyor. Bu geçiş tek başına bina ekonomisini Lv10'da 7,45 katına çıkarır ve bütün eğriler yeniden ayarlanmadan yapılmamalı.
5. **Mevcut konut değerleri GDD'nin 2,5–13 katı.** Apartments 12.000 ↔ 7.500, Luxury 60.000 ↔ 22.500, Arcology 300.000. Boş nüfus geliri bu değerlerle açılırsa ekonomi çöker (§5.2).
6. **KARARLAR §3 + %50 tabanı.** Mevcut ×2 seviye nüfusu bu tabanla birlikte pratikte göz ardı edilebilir bir vergiye dönüşüyor (§5.5).
7. **Gezegen seviyesi doğrusal.** Mevcut kodda `8.000n`, geri kalan her şey üstel.
8. **Başlangıç kredisi tutarsız.** `GameState.start_credits` 1.000, `delete_save` 500, GDD 3.000 + 450 Science.
9. **Mine ve Lab'ın verimi düşük.** Mevcut kodda kredi eşdeğeriyle Market'in 3–5 katı kötü. GDD katalog değerleri bunu düzeltiyor.
10. GDD'nin kaynak haritalarında başka bir makinenin yolları geçiyor (`C:/Users/drosm/...`). Satır numaraları güncel koddan kaymış olabilir.

---

## Ek: Yöntem notu

**Hesap betikleri.** Hepsi oturumun scratchpad dizininde, repoda değil.

| Betik | İçerik |
| --- | --- |
| `tables.py` | Maliyet tabloları |
| `payback.py` | Bina geri ödemeleri |
| `lvpay.py` | Seviye geri ödemeleri, öneri değerleri |
| `sim.py`, `grid.py`, `final.py` | Açgözlü model ve tarama |
| `tree.py` | Araştırma ağacı toplamı |

**Model sınırları.** Model nüfus, enerji, malzeme, inşaat süresi, araştırma kapıları ve coğrafyayı içermez. Tek bir T1 bina tipi (60 kr-eşd/dk) ve tek tip district tabanı (30/dk) kullanır. Sonuçları mutlak süre olarak değil, şemalar arası **göreli** karşılaştırma olarak okuyun.

**Doğrulanamayanlar.** Hiçbir sayı oynanışla doğrulanmadı.

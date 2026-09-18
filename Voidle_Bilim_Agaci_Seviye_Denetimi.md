# Ana gezegen, yörünge ve Ay: araştırma seviyeleri denetimi

18 Eylül 2026. Mevcut kod incelendi; önceki konuşmadaki yeni denge değerleri henüz uygulanmadı. Buradaki “Act 1” yalnızca geliştirme kapsamıdır; oyuncuya gösterilecek bir isim değildir. Oyun kodu değiştirilmedi.

## 1. Kısa sonuç

Bina seviyesi kodda var. Araştırma seviyesi, bina seviyesi, bina adedi ve district seviyesi farklı değerler. Sorun, bunların arayüz ve gerçek üretim bağlantılarının eksik olması.

- Araştırmayı bilimle satın almak çoğu binada yalnızca ulaşılabilir bina seviyesi tavanını artırıyor.
- Bina ayrıca krediyle yükseltilmeli. Araştırma mevcut binaları otomatik yükseltmiyor.
- Bina kartındaki `^` yükseltme düğmesi hatalı bir kontrolden dolayı görünmüyor.
- Düğme düzeltilse bile birçok üretici binada seviye bonusu gerçek çıktıya uygulanmıyor.
- Bazı pasiflerin 2. ve sonraki seviyeleri ek fayda sağlamıyor.

## 2. Solar örneği: birbirine benzeyen iki araştırma

**Energy Operations** (`unlock_solar_panel`) başlangıçta seviye 1. Araştırmayı seviye 2 yapmak 100 bilim ister. Bunun karşılığı Solar Array'leri bina seviyesi 2'ye yükseltme iznidir. Sonra tek Solar Array'i 1'den 2'ye çıkarmak ayrıca 150 kredi ister. Doğru çalışan bağlantıda mevcut +1 enerji, bina seviyesi 2'de +1,5 enerji olur.

**Solar Arrays** (`solar_efficiency`) başka bir araştırmadır. İlk seviye 50 bilimdir, Solar kapasitesine doğrudan +%10 ekler ve en fazla 5 seviyelidir. Bina yükseltmesi gerektirmez. Önkoşulu Thermal Plant'tir.

Örnek: bina seviyesi 2 ve Solar Arrays seviyesi 3 birlikte olursa, diğer bonuslar yokken mevcut +1 temel enerji × 1,5 × 1,3 = **1,95 enerji**. Energy Operations araştırmasını 2 yapmak tek başına bu sonucu sağlamaz.

## 3. Yükseltme düğmesi neden görünmüyor?

[PlanetaryView](C:/Users/drosm/Voidle/scripts/planetary/PlanetaryView.gd:4820) SkillTree'ye ulaşmadan önce `Engine.has_singleton("SceneTree")` kontrolü yapıyor. Godot 4.7.2 ile bağımsız bir kontrol çalıştırıldı:

```text
SCENETREE_SINGLETON=false
MAIN_LOOP_EXISTS=true
```

SceneTree ana döngü olarak mevcut, fakat bu singleton sorgusunun parçası değil. Sonuçta arayüz bina üst sınırını 1 kabul ediyor; 1. seviyedeki binanın yükseltme düğmesi çizilmiyor. Bu kontrol motor üzerinde doğrulandı; bütün düğmelere tıklanan görsel oynanış testi yapılmadı.

Ayrıca [upgrade_building](C:/Users/drosm/Voidle/scripts/game/PlanetProgress.gd:180) para harcayıp seviyeyi artırıyor ama araştırma tavanını kendi içinde doğrulamıyor. Düğmeyi düzeltirken işlem tarafına da sınır kontrolü eklenmeli.

## 4. Her araştırmanın 1–10 seviyesi için bilim maliyeti

Hücreler o seviyeye ulaşmak için **tek satın alma bedeli**, birikimli toplam değil. “Açık” başlangıçta ücretsiz verilen seviyedir. “Yok” o seviyenin satın alınamadığını gösterir.

Genel kural: hedef seviye L için temel fiyat × L. Mining özel: 20, 110, 60, 80... Dolayısıyla Mining 3. seviye, 2. seviyeden daha ucuz.

| Araştırma | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Energy Operations | Açık | 100 | 150 | 200 | 250 | 300 | 350 | 400 | 450 | 500 |
| Habitation Operations | Açık | 100 | 150 | 200 | 250 | 300 | 350 | 400 | 450 | 500 |
| Research Operations | Açık | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 | 1000 |
| Mining Operations | 20 | 110 | 60 | 80 | 100 | 120 | 140 | 160 | 180 | 200 |
| Thermal Plant | 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 | 1000 |
| Deep Drill | 200 | 400 | 600 | 800 | 1000 | 1200 | 1400 | 1600 | 1800 | 2000 |
| Market Square | 30 | 60 | 90 | 120 | 150 | 180 | 210 | 240 | 270 | 300 |
| Archival Systems | 150 | 300 | 450 | 600 | 750 | 900 | 1050 | 1200 | 1350 | 1500 |
| Advanced Research | 500 | 1000 | 1500 | 2000 | 2500 | 3000 | 3500 | 4000 | 4500 | 5000 |
| Deep Space Optics | 800 | 1600 | 2400 | 3200 | 4000 | 4800 | 5600 | 6400 | 7200 | 8000 |
| Refinery | 400 | 800 | 1200 | 1600 | 2000 | 2400 | 2800 | 3200 | 3600 | 4000 |
| Cultural Investments | 150 | 300 | 450 | 600 | 750 | 900 | 1050 | 1200 | 1350 | 1500 |
| Apartments | 500 | 1000 | 1500 | 2000 | 2500 | 3000 | 3500 | 4000 | 4500 | 5000 |
| Orbital Facilities | 300 | 600 | 900 | 1200 | 1500 | 1800 | 2100 | 2400 | 2700 | 3000 |
| Orbital Shipyard | 1000 | 2000 | 3000 | 4000 | 5000 | 6000 | 7000 | 8000 | 9000 | 10000 |
| Orbital Mirrors | 2000 | 4000 | 6000 | 8000 | 10000 | 12000 | 14000 | 16000 | 18000 | 20000 |
| Moon Outpost | 500 | Yok | Yok | Yok | Yok | Yok | Yok | Yok | Yok | Yok |
| Lunar Observatory | 1500 | 3000 | 4500 | 6000 | 7500 | 9000 | 10500 | 12000 | 13500 | 15000 |
| Helium-3 Extractor | 1500 | 3000 | 4500 | 6000 | 7500 | 9000 | 10500 | 12000 | 13500 | 15000 |
| Planetary Colonization | 2000 | Yok | Yok | Yok | Yok | Yok | Yok | Yok | Yok | Yok |
| Solar Arrays | 50 | 100 | 150 | 200 | 250 | Yok | Yok | Yok | Yok | Yok |
| Excavation Drills | 50 | 100 | 150 | 200 | 250 | 300 | 350 | 400 | 450 | 500 |
| Seismic Sensors | 350 | 700 | 1050 | 1400 | 1750 | 2100 | 2450 | 2800 | 3150 | 3500 |
| Automated Conveyors | 900 | 1800 | 2700 | 3600 | 4500 | 5400 | 6300 | 7200 | 8100 | 9000 |
| Refinery Optimization | 450 | 900 | 1350 | 1800 | 2250 | 2700 | 3150 | 3600 | 4050 | 4500 |
| Educational Grants | 300 | 600 | 900 | 1200 | 1500 | Yok | Yok | Yok | Yok | Yok |
| Subsidized Housing | 300 | 600 | 900 | 1200 | 1500 | Yok | Yok | Yok | Yok | Yok |
| Heat Capture Loops | 250 | 500 | 750 | 1000 | 1250 | Yok | Yok | Yok | Yok | Yok |
| Superconducting Grid | 400 | Yok | Yok | Yok | Yok | Yok | Yok | Yok | Yok | Yok |
| Zero-Point Regulators | 800 | 1600 | 2400 | 3200 | 4000 | Yok | Yok | Yok | Yok | Yok |
| Free Trade Agreement | 300 | 600 | 900 | 1200 | 1500 | Yok | Yok | Yok | Yok | Yok |
| Plasma Ignition | 800 | 1600 | 2400 | 3200 | 4000 | 4800 | 5600 | 6400 | 7200 | 8000 |

## 5. Bina ve erişim araştırmaları: her seviye ne veriyor?

“Bina tavanı L”: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 araştırma seviyeleri sırasıyla aynı bina seviye sınırlarını tanımlar. Sonraki seviyelerde yeni bina tipi açılmaz. Bu tavanın arayüzden kullanılmasını yukarıdaki hata engelliyor.

| Araştırma | Mevcut gerçek bağlantı |
|---|---|
| Energy Operations (`unlock_solar_panel`) | Solar Array bina seviye tavanı L; üretimi doğrudan artırmaz. |
| Habitation Operations (`unlock_residential`) | Residential bina seviye tavanı L. |
| Research Operations (`unlock_lab`) | University bina seviye tavanı L. |
| Mining Operations (`unlock_mining`) | L1: Mining district ve Mine; L2–10: Mine seviye tavanı L. |
| Thermal Plant (`unlock_generator`) | L1: Generator erişimi; sonraki seviyeler bina seviye tavanı L. |
| Deep Drill (`unlock_deep_drill`) | L1: Deep Drill erişimi; sonraki seviyeler bina seviye tavanı L. |
| Market Square (`unlock_market_square`) | L1: Market Square erişimi; sonraki seviyeler bina seviye tavanı L. |
| Archival Systems (`unlock_library`) | L1: Library erişimi; sonraki seviyeler bina seviye tavanı L. Araştırma başına doğrudan +%15 yok. |
| Advanced Research (`unlock_advanced_lab`) | L1: ayrı Advanced Lab erişimi; University otomatik dönüşmez. Sonrası bina seviye tavanı L. |
| Deep Space Optics (`unlock_observatory`) | L1: Observatory erişimi; sonrası bina seviye tavanı L. |
| Refinery (`unlock_refinery`) | L1: Refinery erişimi; sonrası bina seviye tavanı L. Ürün dönüşümü ayrıca sorunlu. |
| Cultural Investments (`unlock_culture_center`) | L1: Culture Center erişimi; sonrası bina seviye tavanı L. Araştırma başına doğrudan +%20 yok. |
| Apartments (`unlock_apartments`) | L1: Apartments erişimi; sonrası bina seviye tavanı L. |
| Orbital Facilities (`unlock_space_station`) | L1: orbital district, Nexus erişimi ve güneş sistemi izni. L2–10: ek işlev yok; district seviyesi veya Nexus tavanı artmaz. |
| Orbital Shipyard (`unlock_orbital_shipyard`) | L1: Shipyard erişimi; sonrası bina tavanı L. Mevcut GeneratorLogic kredi veya gemi üretmez. |
| Orbital Mirrors (`unlock_orbital_mirrors`) | L1: Mirrors erişimi; sonrası bina tavanı L. tick=0 inşaat hatası var. |
| Moon Outpost (`unlock_moon`) | L1: Ay izni. L2–10 yok. |
| Lunar Observatory (`unlock_lunar_observatory`) | L1: bina erişim kaydı; sonrası bina tavanı L. Üretim logic'i ve Ay yerleşim bağlantısı eksik. |
| Helium-3 Extractor (`unlock_moon_helium3`) | L1: bina erişimi; sonrası bina tavanı L. Araştırma tek başına +500 enerji vermez; bina kurmak gerekir. |
| Planetary Colonization (`unlock_planetary_colonization`) | L1: araştırma bayrağı ve sonraki dallar. Mevcut kolonileştirme işlemi bunu zorunlu kontrol etmiyor; L2–10 yok. |

**Nexus istisnası:** `unlock_space_station` ile erişilebilir oluyor ama bina tavanı hesabı `unlock_zero_g_nexus` arıyor. Böyle bir araştırma yok. Orbital Facilities'i 10 yapmak Nexus'u 10'a yükseltme izni sağlamıyor. Bu yüzden Orbital Facilities'in 2–10 seviyeleri bu binaya da fayda vermiyor.

**Eksik plan bağlantıları:** Spaceport için normal araştırma düğümü yok. Ay gözlemevi sonrası konuştuğumuz yeni gezegenler arası geçiş koşulu henüz eklenmedi. Mevcut Planetary Colonization düğümü, önerilen yeni davranışla karıştırılmamalı.

## 6. Pasiflerde 1–10 seviyelerinin toplam etkisi

Bonuslar her seviye için başlangıç değerine göre toplamdır. Örneğin +%10, sonra +%20, önceki sonucu yeniden %10 çarpmak değildir. Farklı bonusların birleşimi ilgili formüle bağlıdır.

| Araştırma | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Solar Arrays | +%10 | +%20 | +%30 | +%40 | +%50 | Yok | Yok | Yok | Yok | Yok |
| Excavation Drills | +%5 | +%10 | +%15 | +%20 | +%25 | +%30 | +%35 | +%40 | +%45 | +%50 |
| Seismic Sensors | +%2 | +%4 | +%6 | +%8 | +%10 | +%12 | +%14 | +%16 | +%18 | +%20 |
| Automated Conveyors | -%2 | -%4 | -%6 | -%8 | -%10 | -%12 | -%14 | -%16 | -%18 | -%20 |
| Refinery Optimization | +%5 | +%10 | +%15 | +%20 | +%25 | +%30 | +%35 | +%40 | +%45 | +%50 |
| Educational Grants | +%15 | +%15 | +%15 | +%15 | +%15 | Yok | Yok | Yok | Yok | Yok |
| Subsidized Housing | +%15 | +%15 | +%15 | +%15 | +%15 | Yok | Yok | Yok | Yok | Yok |
| Heat Capture Loops | +%5 | +%5 | +%5 | +%5 | +%5 | Yok | Yok | Yok | Yok | Yok |
| Superconducting Grid | -%15 | Yok | Yok | Yok | Yok | Yok | Yok | Yok | Yok | Yok |
| Zero-Point Regulators | -%2 | -%4 | -%6 | -%8 | -%10 | Yok | Yok | Yok | Yok | Yok |
| Free Trade Agreement | +%15 | +%30 | +%45 | +%60 | +%75 | Yok | Yok | Yok | Yok | Yok |
| Plasma Ignition | +%2 | +%4 | +%6 | +%8 | +%10 | +%12 | +%14 | +%16 | +%18 | +%20 |

Sonuçlar:

- Educational Grants 2–5: toplam **4200 bilim**, ek bilim bonusu **0**.
- Subsidized Housing 2–5: toplam **4200 bilim**, ek kredi bonusu **0**.
- Heat Capture Loops 2–5: toplam **3500 bilim**, ek enerji bonusu **0**.
- Orbital Facilities 2–10: toplam **16200 bilim**, mevcut akışta ek erişim/bina tavanı etkisi **0**.
- Superconducting Grid metni -%5, uygulama -%15. Hangisinin amaçlandığı tasarım kararı; metin ile uygulama eşleşmeli.
- Seismic Sensors rafineri çıktısına da uygulanıyor. Automated Conveyors hem ham hem refined üreticileri etkiliyor. İsim ve açıklamalar bu kapsamı anlatmalı.
- Housing bonusu yalnızca konutla sınırlı değil: Market Square'i de üreten CreditLogic aynı genel kredi çarpanını kullanıyor.

## 7. Bina seviyesinin 1–10 matematiği

Araştırma seviyesiyle karıştırılmamalı. Bunlar ayrıca kredi ödenerek yükseltilen **binanın** seviyesidir.

```text
Tanımlı çıktı çarpanı = 1 + 0,5 × log2(bina seviyesi)
Enerji / girdi tüketim çarpanı = 1 + 0,25 × log2(bina seviyesi)
L seviyesinden L+1'e yükseltme kredisi = temel bina fiyatı × 1,5^(L-1) × bina adedi
```

| Bina seviyesi | Tanımlı çıktı çarpanı | Tüketim çarpanı | Mevcut Solar temel +1 için gerçek kapasite |
|---:|---:|---:|---:|
| 1 | 1.000 | 1.000 | 1.000 |
| 2 | 1.500 | 1.250 | 1.500 |
| 3 | 1.792 | 1.396 | 1.792 |
| 4 | 2.000 | 1.500 | 2.000 |
| 5 | 2.161 | 1.580 | 2.161 |
| 6 | 2.292 | 1.646 | 2.292 |
| 7 | 2.404 | 1.702 | 2.404 |
| 8 | 2.500 | 1.750 | 2.500 |
| 9 | 2.585 | 1.792 | 2.585 |
| 10 | 2.661 | 1.830 | 2.661 |

### Uygulama farkı

- **Solar ve Generator:** bina seviyesinin çıktı çarpanı enerji hesabında uygulanıyor. Generator için yakıt tüketimi de yükseliyor.
- **Library, Culture Center, Observatory gibi destekler:** destek etkisi bina çıktı çarpanını kullanıyor. Library seviye 2'de +%22,5, seviye 10'da yaklaşık +%39,9 verir. Araştırma seviyesi başına +%15 veya bina seviyesi 10'da +%150 değildir.
- **Residential, Market Square, University, Advanced Lab, Mine, Deep Drill, Refinery:** ilgili üretim logic'lerinde bina seviyesi çıktı çarpanı yok. Gösterilen çıktı artabilir ama stoğa eklenen temel çıktı artmaz. Enerji ve girdiler ise seviye çarpanıyla artar. Enerji açığında gerçek üretim hızı da düşebilir.
- **Nexus ve Lunar Observatory:** doğrudan üretim logic'i eksik olduğundan seviye bonusundan önce temel üretim bağlantısı çözülmeli.
- **Orbital Mirrors:** sıfır tick süresi nedeniyle inşaatın atlanması, seviye sisteminden ayrı bir engel.

Örnek: University bina seviyesi 2'ye bir test/başka çağrı yoluyla çıkarılırsa gösterim 2 × 1,5 = 3 bilim hesaplayabilir; ScienceLogic temel 2 bilim üzerinden üretir. Enerji talebi 2 × 1,25 = 2,5 olur. Arayüz düğmesini düzeltmek tek başına yeterli değil.

## 8. Nasıl düzenlemeliyiz?

1. **Erişim teknolojileri:** Orbital Facilities, Moon Outpost ve gezegenler arası erişim tek seviyeli olsun. İkinci satın alımın ayrı faydası yoksa bilim harcatmayalım.
2. **Bina geliştirme araştırmaları:** İki aşamalı sistem tutulacaksa açıklama “Solar Array azami bina seviyesini 2 yapar; mevcut binaları ayrıca krediyle yükselt” demeli. Bina kartında mevcut seviye, araştırmayla açılmış tavan ve gerçek yükseltme farkı görünmeli.
3. **Pasif verim araştırmaları:** Her satın alım gerçek fayda sağlamalı. Beş seviyeli bir düğüm 10 seviyeli gibi sunulmamalı. Toplam bonus, sonraki seviyenin ek bonusu ve bilim fiyatı birlikte gösterilmeli.
4. **Gerçek üretim:** Görsel çıktı ile stok hesabı ortak hesaplamayı kullanmalı. Aksi halde matematik tablosu güvenilir olmaz.
5. **İlk bölüm kapsamı:** On seviyenin tamamını bitirmeyi zorunlu yapmayalım. Ana gezegen-yörünge-Ay hedefleri esas; fazla seviyeler isteğe bağlı veya daha sonraki gelişime kalabilir. Kesin tavanlar süre testinden sonra seçilmeli.
6. **Mining fiyat eğrisi:** 110'dan 60'a düşen ikinci/üçüncü seviye maliyetini bilinçli tasarım kararı değilse düzeltelim.

Önce hataları gidermek, sonra bonus büyüklüklerini dengelemek gerekir. Örneğin pasifi gerçekten her seviyede +%15 yaparsak eski +%15 toplam bir anda +%75'e çıkar; bu bir hata düzeltmesi yanında önemli ekonomi değişimidir ve test edilmelidir.

## 9. Kaynaklar ve doğrulama kapsamı

- [Araştırma tanımları, satın alma ve pasif çarpanlar](C:/Users/drosm/Voidle/scripts/game/SkillTree.gd:235)
- [Bina yükseltme işlemi](C:/Users/drosm/Voidle/scripts/game/PlanetProgress.gd:180)
- [Yükseltme düğmesi](C:/Users/drosm/Voidle/scripts/planetary/PlanetaryView.gd:4820)
- [Bina seviye ve destek formülleri](C:/Users/drosm/Voidle/scripts/game/ProductionManager.gd:326)
- [Bilim üretimi](C:/Users/drosm/Voidle/scripts/game/logic/ScienceLogic.gd:6)
- [Kredi üretimi](C:/Users/drosm/Voidle/scripts/game/logic/CreditLogic.gd:4)
- [Maden üretimi](C:/Users/drosm/Voidle/scripts/game/logic/MineLogic.gd:4)
- [Rafineri üretimi](C:/Users/drosm/Voidle/scripts/game/logic/RefineryLogic.gd:7)

32 araştırma için fiyat ve etki tablosu statik koddan çıkarıldı. Seviye düğmesindeki motor sorgusu ayrıca Godot 4.7.2 üzerinde çalıştırıldı. Bu rapor yeni denge değerlerini uygulamaz ve baştan sona oynanış testi iddiası taşımaz.


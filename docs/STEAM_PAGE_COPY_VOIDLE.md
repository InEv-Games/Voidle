# VOIDLE — Steam Mağaza Sayfası Metinleri & Optimizasyon Raporu
*(InEv Games / InEv Creative Marka Dili × Chris Zukowski Veri Odaklı Steam Optimizasyonu × Anchor Games Analizi)*

---

## BÖLÜM 0: Referans Oyunlar Kıyaslama Raporu (`Comp Games Analysis`)

### İncelenen Referans Oyunlar (Anchor / Comp Games)
1. **Sid Meier's Civilization VI** (`AppID: 289070`)
2. **Stellaris** (`AppID: 281990`)
3. **Offworld Trading Company** (`AppID: 271240`)

### 1. Short Description & Kelime Havuzu (Gameplay Verbs)
* **Alt-Tür Tanımlamaları:**
  * *Stellaris:* `"sci-fi grand strategy game"`, `"explore a galaxy"`, `"expand the reach of your empire"`.
  * *Offworld Trading Company:* `"economic real-time strategy"`, `"manipulate a dynamic supply-and-demand market"`, `"acquire resources"`.
  * *Civilization VI:* `"cities physically expand across the map"`, `"active research in technology"`, `"take advantage of local terrain"`.
* **Ortak Oynanış Fiilleri (Gameplay Verbs):**
  * `Found`, `Expand`, `Colonize`, `Survey`, `Extract`, `Refine`, `Manipulate`, `Automate`, `Research`, `Excavate`, `Launch`.

### 2. Long Description ("About This Game") Yapısı ve Tonu
* **Civilization VI:** Harita üzerindeki **fiziksel yayılımı** (*Unstacking Cities / Districts*), **coğrafya ve komşuluk bonuslarını** (*Terrain & Adjacency*) ve **aktif araştırmayı** öne çıkarır.
* **Stellaris:** **Karanlık uzay estetiği içinde büyük ölçekli imparatorluk yönetimini**, **gezegen yüzeylerindeki anomalileri/arkeolojik kazıları** ve **sistemler arası genişlemeyi** vurgular.
* **Offworld Trading Company:** Geleneksel ordular yerine **canlı arz-talep piyasasını**, **13 farklı kaynağın işlenmesini**, **otomatik alım-satım/stok manipülasyonunu** merkeze alır.

### 3. İlk 4 Hover Screenshot & PC Strateji UI Beklentisi
* Bu üç referans oyunun oyuncu kitlesi (4X, Grand Strategy ve Ekonomi Simülasyonu oyuncuları) ekranda **"Zengin Veri ve Karmaşık Arayüz" (*Zukowski: PC Players Love Complex UI*)** görmeyi bekler:
  1. **Üst Kaynak Barı (Top HUD):** Kredi, Enerji dengesi (`⚡/s`), Bilim, Nüfus kapasitesi ve işlenmiş/ham materyallerin anlık akışı.
  2. **Sol/Sağ Outliner Paneli:** Şehirlerin, District'lerin, üretim barlarının ve piyasa emirlerinin listelendiği yüksek kontrastlı, okunaklı yönetim paneli.
  3. **Harita Üzeri Coğrafya & Bölge Sınırları:** Gezegen üzerinde büyüyen renk kodlu District sınırları, şehirleri birbirine bağlayan yol ağları (*Road Network*) ve yörünge halkaları (*Orbital Layer*).
  4. **İç İçe Geçmiş Bilgi Kutuları (Nested Tooltips):** Bir binanın veya gezegen özelliğinin üzerine gelindiğinde açılan, coğrafya çarpanlarını (`×1.5`, `×2.0`) ve sözlük kavramlarını (*Glossary*) açıklayan kilitlenebilir Tooltip pencereleri.

### 4. Konumlandırma: "Swap Test" & "Law of Opposition"
* **Tür Klişesini Kırma (*Law of Opposition*):**
  * Klasik 4X oyunlarındaki (*Stellaris*, *Civ VI*) **geç oyun mikro-yönetim ve birim taşıma yorgunluğunu (micromanagement & unit-shuffling fatigue)** ortadan kaldırır: Kaynaklar küresel stokta birikir, yorucu kargo gemisi angaryası yerine makro mimariye odaklanılır.
  * Klasik Idle/Incremental oyunlarındaki **"sabit bir ekranda tek bir sayının büyümesini izleme"** klişesini kırar: Gerçek gezegen coğrafyası, dinamik arz-talep borsası ve **4 katmanlı Kardashev ölçeği (Gezegen › Güneş Sistemi › Gökada › Galaksi)** sunar.
* **Benzersiz Mekanik Kanca (*Swap Test*):**
  * **Fraktal Teknoloji Ağacı (Fractal Skill Tree) & Ölçek Kaydırma (Scale-Shifting):** Bir medeniyet çağını (örn. Tip 0) tamamlayıp roketini yeni bir gezegene ulaştırdığında, tüm o devasa teknoloji ağacı bir sonraki medeniyetin (Tip 1) **tek bir merkez düğümüne** dönüşür ve daha önce tek tek yönettiğin gezegen içi District'ler, Güneş Sistemi görünümünde hızlı ekonomik birimlere evrilir.

---

## BÖLÜM 1: Godot Projesi Keşif Özeti (`Voidle` Teknik & İçerik Analizi)

* **Motor & Mimari:** Godot 4.7 ([`project.godot`](file:///Users/uluckaymak/.gemini/antigravity/worktrees/Voidle/steam_page_generator/project.godot)), özel piksel-kuantize gezegen/atmosfer/nehir/rüzgâr shader'ları (`planet_rocky.gdshader`, `district_territory.gdshaderinc`), A* tabanlı gerçek arazi yol ağı ([`RoadNetwork.gd`](file:///Users/uluckaymak/.gemini/antigravity/worktrees/Voidle/steam_page_generator/scripts/planetary/RoadNetwork.gd)).
* **Başlangıç Olayı (*Inciting Incident*):** Yıl 2387. Koloni gemin (*Ark*) yabancı bir dünyaya (`Vesyn`) güçlükle iner. Kırılgan bir ilk yerleşimin Valisi (*Governor*) olarak sıfırdan başlayıp önce yörüngeye, sonra Ay'a ve nihayet yıldızlararası Kardashev ölçeklerine (Tip 0 → Tip 5) tırmanırsın.
* **Somut İçerik Sayıları:**
  * **82 Bina Modeli:** 5 uzmanlık ailesine (*Energy, Production, Science, Residential, Commercial*) ve coğrafi koşullara (*kıyı, dağ, nehir, çöl, krater*) duyarlı yapılar.
  * **13 District Türü:** *Capital District*, 5 Yüzey Uzmanlık District'i, *Spaceport*, *Orbit City* ve 5 *Orbital Destek District'i*.
  * **12 Ham Mineral & 3 İşlenmiş Ürün:** Nadirlik matrisine (R1–R12) göre *Ferrite, Moonstone, Cinderite, Cryolite, Dune Quartz, Helion, Astralite, Aurorium, Xenite, Nyxium, Quantium, Singularite* + *Consumer Goods, Fuel Rods, Rare Elements*.
  * **Canlı Arz-Talep Borsası ([`Trade.gd`](file:///Users/uluckaymak/.gemini/antigravity/worktrees/Voidle/steam_page_generator/scripts/game/Trade.gd) & [`TradePanel.gd`](file:///Users/uluckaymak/.gemini/antigravity/worktrees/Voidle/steam_page_generator/scripts/ui/TradePanel.gd)):** Her alım fiyatı yükseltir, her satış düşürür; otomatik rezerv ve emir modları (`▲ Buy until`, `▼ Sell until`, `■ Keep at`).
  * **9 İnteraktif Arkeolojik Kazı Hikayesi & 2 Yoldaş (Companions):** Ana dünya ve Ay üzerindeki kalıntılarda seçim odaklı kazılar ([`StoryDialog.gd`](file:///Users/uluckaymak/.gemini/antigravity/worktrees/Voidle/steam_page_generator/scripts/ui/excavation/StoryDialog.gd)), ekibe katılan uzmanlar (*Sera Vale*, *Dorian Hale*) ve kalıcı yadigârlar (*Relics*).
  * **16 Gezegen Özelliği ([`PlanetTags.gd`](file:///Users/uluckaymak/.gemini/antigravity/worktrees/Voidle/steam_page_generator/scripts/game/PlanetTags.gd)):** Gezegen seviye atladıkça açılan 3 karttan 1'ini seçme (*Roguelite/4X draft* mekaniği).
  * **117 Başarım ([`AchievementManager.gd`](file:///Users/uluckaymak/.gemini/antigravity/worktrees/Voidle/steam_page_generator/scripts/game/AchievementManager.gd)).**

---

## BÖLÜM 2: Short Description (EN & TR) + 5 Kural Doğrulaması

### 🇬🇧 Short Description (English)
> **A sci-fi 4X incremental strategy game where you scale from a single colony to a galactic civilization. Found cities, exploit terrain multipliers, manipulate a live resource market, and unlock a fractal tech tree—all with zero unit-shuffling micromanagement.**
*(38 kelime, 267 karakter — 290 karakter sınırının altında)*

#### Alternatif (Daha Sıkı Mekanik Odaklı - 41 kelime, 279 karakter):
> **A sci-fi 4X incremental colony builder. Found specialized cities, chain 82 terrain-driven buildings, manipulate a dynamic supply-and-demand market, and launch rockets to the Moon and beyond. Scale from planetary districts to star systems—without tedious unit micromanagement.**

### 🇹🇷 Kısa Açıklama (Türkçe)
> **Tek bir koloniden galaktik medeniyete uzanan bilimkurgu 4X incremental strateji oyunu. Şehirler kur, coğrafya çarpanlarını kullan, canlı arz-talep borsasını yönet ve fraktal teknoloji ağacında ilerle; üstelik yorucu birim taşıma angaryası olmadan.**
*(33 kelime, 255 karakter — 290 karakter sınırının altında)*

---

### ✅ Zukowski & InEv 5 Kural Doğrulaması (Short Description Audit)
1. **İlk 10 Kelimede Alt-Tür (Sub-Genre) & Anchor Game Dili:**
   * İlk 6 kelimede (`"A sci-fi 4X incremental strategy game..."` / `"A sci-fi 4X incremental colony builder."`) hem *Stellaris/Civ VI* kitlesinin aradığı `sci-fi 4X strategy / colony builder` hem de `incremental` alt-türü net biçimde tanımlandı.
2. **"So What Do You DO?" (Aksiyon Fiilleri / Verbs):**
   * Soyut sıfatlar sıfırlandı; doğrudan oyuncunun ekranda yaptığı emir kipli fiiller sıralandı: **`Scale`**, **`Found`** (cities), **`Exploit / Chain`** (terrain multipliers / buildings), **`Manipulate`** (live resource market), **`Launch`** (rockets), **`Unlock`** (fractal tech tree).
3. **"Swap Test" (İsim Değiştirme Testi):**
   * *Voidle* adını çıkarıp yerine *Stellaris* veya *Civilization VI* koyduğumuzda *"scale from a single colony... unlock a fractal tech tree—all with zero unit-shuffling micromanagement"* cümlesi o oyunlara uymaz; oyunun **Fraktal Teknoloji Ağacı** ve **4X-Incremental ölçek sıçraması** kancası metni benzersiz kılar.
4. **"Law of Opposition" (Tür Klişesini Kırma):**
   * 4X ve koloni simülasyonu oyuncularının en büyük ağrı noktası olan geç oyun kargo/birim taşıma angaryası **`"with zero unit-shuffling micromanagement"`** (*"yorucu birim taşıma angaryası olmadan"*) ifadesiyle doğrudan kırıldı.
5. **"Proper Noun Filter" (Özel İsim Sınırı):**
   * Soğuk ziyaretçiyi yabancılaştıracak uydurma özel isim sayısı: **0** (veya en fazla herkesin bildiği *Moon*). Ziyaretçi ilk saniyede tüm terimleri anlar.

---

## BÖLÜM 3: Long Description ("About This Game") & GIF/Video Kurgusu (EN & TR)

> **Uygulanan Mimari:** **Şablon C (*Data.exe / Potato.exe* — Küçükten Devasa Ölçeğe Otomasyon Adımları)** + **Şablon B (*Kardiya* — Derin Sistemik Sinerji, Seçimli Kazılar ve Fraktal İlerleme)** hibrit yapısı.

---

### 🇬🇧 ENGLISH — LONG DESCRIPTION ("ABOUT THIS GAME")

```bbcode
[p][b]Year 2387.[/b] Your colony ark has barely survived touchdown on a procedural world. You start with a single free Capital shell, 3,000 Credits, and an untouched wilderness. Your goal is not just to survive—it is to climb the Kardashev scale from a [b]Type 0 Planetary Colony[/b] to a [b]Type 1 Star System Empire[/b] and beyond.[/p]

[p][b]Voidle[/b] fuses the spatial territory planning of [i]Civilization[/i], the cosmic scale of [i]Stellaris[/i], and the live market manipulation of [i]Offworld Trading Company[/i] into a sleek, dark-mode [b]4X Incremental Strategy[/b] experience.[/p]

[hr][/hr]

[h2]1. READ THE TERRAIN, BUILD SPECIALIZED CITIES[/h2]
[i][🎥 GIF/WEBM #1 — 4 sec loop: Zooming in on a rotating Terran globe. The player toggles the Geography Lens, places a Mining District on a mountain ridge (popping a glowing "×2.0 Site Multiplier" badge), and watches A* road networks automatically snake across the valleys to connect with the Capital.][/i]

Every planet is procedurally generated with real elevation, coastlines, river basins, wind corridors, and geothermal vents. Where you place your districts directly dictates your economic ceiling:
[list]
[*] [b]5 Core District Families:[/b] Expand your cities with specialized [b]Energy, Production, Science, Residential, and Commercial[/b] districts—backed by your Capital District and Orbital ring.
[*] [b]Half-Step Site Multipliers:[/b] Match your districts to visible geography (mountain optics, coastal harbors, river extractors) to lock in clean [b]1.5×, 2.0×, and higher[/b] output multipliers.
[*] [b]Living Road & Territory Networks:[/b] Watch your borders physically expand across the globe as A* road networks and maritime shipping lanes link neighboring districts, spreading level caps outward from your Capital.
[/list]

[h2]2. EXTRACT, REFINE & MANIPULATE A LIVE MARKET[/h2]
[i][🎥 GIF/WEBM #2 — 5 sec loop: Left Panel flips with a cyber-scramble animation into the Market screen. Green and red sparkline charts (▁▃▅) pulse as the player dumps a x10 lot of Ferrite, dropping its price, then sets a standing "■ Keep at 150" automation order on Moonstone.][/i]

Forget tedious cargo-ship micro. All extracted resources feed into a unified global stock, letting you focus on industrial synergy and financial warfare:
[list]
[*] [b]82 Buildings & Fixed Industrial Recipes:[/b] Survey planetary crusts to unlock [b]12 distinct raw minerals[/b] (from common [i]Ferrite[/i] and lunar [i]Moonstone[/i] to exotic [i]Cryolite[/i] and [i]Singularite[/i]) and refine them into [b]Consumer Goods, Fuel Rods, and Rare Elements[/b].
[*] [b]Dynamic Supply-and-Demand Exchange:[/b] Every crate you buy drives market prices up; every surplus you dump drives them down. Read the live sparkline charts and time your trades between 0.4× and 3.0× price waves.
[*] [b]Standing Market Automation:[/b] Research [i]Trade Automation[/i] to set autonomous reserve thresholds ([b]▲ Buy Until, ▼ Sell Until, ■ Keep At[/b]) so your economy self-balances while you expand.
[/list]

[h2]3. CONQUER THE FRACTAL TECH TREE[/h2]
[i][🎥 GIF/WEBM #3 — 5 sec loop: The camera zooms out from the planet as the full-screen Blueprint Upgrade Tree fades in. The player unlocks "Lunar Program" along the glowing Exploration branch, then double-clicks the central hub node to zoom recursively into the previous civilization's entire tech tree.][/i]

Research is not a flat checklist—it is a radial, multi-branch strategy web that scales with your civilization:
[list]
[*] [b]10 Radial Research Lines:[/b] Invest Science across [b]Exploration, Orbital, Lunar, Industry, Energy, Science, Trade, Population, Planning, and Administration[/b].
[*] [b]Cross-Branch Strategy Surcharge:[/b] Every off-path specialization increases the Science cost of other branches, forcing meaningful build decisions on every run.
[*] [b]Recursive Fractal Legacy:[/b] When you advance to a higher Civilization Type, your entire previous tech tree compresses into the [b]single center node[/b] of the new tree. Double-click the center at any time to dive back in or buy out remaining legacy nodes in one click.
[/list]

[h2]4. EXCAVATE ANCIENT RUINS & RECRUIT COMPANIONS[/h2]
[i][🎥 GIF/WEBM #4 — 4 sec loop: Clicking a pulsing ruin marker on the planet opens the Story Dialog card. Sera Vale's portrait appears beside branching narrative choices offering immediate Credits, Science, or permanent Companion recruitment.][/i]

You are not the first to build on these worlds. Beneath the regolith lie toppled stones, sealed lunar hatches, and sighting lines aimed at the stars:
[list]
[*] [b]9 Branching Excavation Stories:[/b] Send survey crews into ancient ruins across your homeworld and the Moon. Choose whether to catalogue artifacts for Science, sell bronze instruments for fast Credits, or breach sealed vaults.
[*] [b]Companions & Relics:[/b] Recruit specialists like [b]Sera Vale[/b] (Wandering Trader) and [b]Dorian Hale[/b] (Lunar Contractor) and recover permanent relics that boost your empire across every world.
[*] [b]16 Planet Traits:[/b] Every planetary level-up triggers a 3-card trait draft ([i]Ancient Archives, Boomtown, Rich Crust, Regolith Seas[/i]) with rerolls to tailor each world's role.
[/list]

[h2]5. ASCEND THE KARDASHEV SCALE[/h2]
[i][🎥 GIF/WEBM #5 — 5 sec loop: Launching an Orbital Space Station, landing a colony module on the Moon ("FIRST STEP ON THE MOON"), and watching the Advanced Planetary Rocket trace a glowing curved trajectory across the Solar System View toward a new planet.][/i]

What starts as careful district placement on a single globe transforms into macro-scale system management:
[list]
[*] [b]Build the Orbital Ring:[/b] Assemble an [b]Orbit City[/b] and 5 specialized orbital support stations ([i]Zero-G Nexus, Solar Mirrors, Orbital Production[/i]) that multiply your entire planet's output.
[*] [b]Settle the Moon & Launch for New Worlds:[/b] Land on the Moon, refine local [i]Moonstone[/i], construct the [b]Lunar Spaceport[/b], and launch the [b]Advanced Planetary Rocket[/b] across the solar system.
[*] [b]4-Layer Scale Shifting:[/b] As you ascend from Type 0 to Type 1, the districts you once micromanaged on the surface become streamlined economic units on the [b]Solar System[/b] and [b]Galaxy[/b] maps—without ever deleting your underlying cities.
[/list]

[hr][/hr]

[h2]AT A GLANCE — SYSTEM SPECIFICATIONS[/h2]
[table]
  [tr]
    [th]System / Layer[/th]
    [th]What You Command[/th]
    [th]Strategic Depth[/th]
  [/tr]
  [tr]
    [td][b]Planetary & Orbital Build[/b][/td]
    [td]13 District Types & 82 Building Models[/td]
    [td]5 core families, orbital stations, coastal/mountain/river terrain requirements, and half-step site multipliers (1.5×, 2.0×).[/td]
  [/tr]
  [tr]
    [td][b]Resource & Market Engine[/b][/td]
    [td]12 Raw Minerals + 3 Processed Products[/td]
    [td]Live supply-and-demand price waves (0.4×–3.0×), sparkline charts, overflow auto-sell, and 3 standing order modes.[/td]
  [/tr]
  [tr]
    [td][b]Research & Progression[/b][/td]
    [td]10-Branch Radial Fractal Skill Tree[/td]
    [td]Cross-branch specialization pricing, recursive center-node legacy trees, and one-click legacy buyouts.[/td]
  [/tr]
  [tr]
    [td][b]Discovery & Narrative[/b][/td]
    [td]9 Excavation Sites, 2 Companions, 16 Planet Traits[/td]
    [td]Choice-driven archaeological digs, permanent empire relics, 3-card planetary trait drafts, and 117 Achievements.[/td]
  [/tr]
[/table]
```

---

### 🇹🇷 TÜRKÇE — UZUN AÇIKLAMA ("BU OYUN HAKKINDA")

```bbcode
[p][b]Yıl 2387.[/b] Koloni gemin prosedürel olarak üretilmiş yabancı bir dünyaya güçlükle indi. Elinde yalnızca ücretsiz ilk Başkent kabuğu, 3.000 Kredi ve el değmemiş bir gezegen var. Amacın sadece hayatta kalmak değil; Kardashev ölçeğinde [b]Tip 0 Gezegen Kolonisinden[/b] [b]Tip 1 Güneş Sistemi İmparatorluğuna[/b] ve ötesine tırmanmak.[/p]

[p][b]Voidle[/b]; [i]Civilization[/i]'ın coğrafyaya dayalı bölge planlamasını, [i]Stellaris[/i]'in kozmik ölçeğini ve [i]Offworld Trading Company[/i]'nin canlı piyasa manipülasyonunu karanlık ve modern bir [b]4X Incremental Strateji[/b] deneyiminde birleştirir.[/p]

[hr][/hr]

[h2]1. COĞRAFYAYI OKU, UZMANLAŞMIŞ ŞEHİRLER KUR[/h2]
[i][🎥 GIF/WEBM #1 — 4 sn döngü: Dönen bir Terran gezegenine yakınlaşma. Oyuncu Coğrafya Lensini açar, dağ sırtına bir Maden District'i yerleştirir ("×2.0 Yer Çarpanı" rozeti parlar) ve A* yol ağlarının vadiler boyunca kıvrılarak Başkent'e bağlanmasını izler.][/i]

Her gezegen gerçek yükselti, kıyı şeridi, nehir havzası, rüzgâr koridoru ve jeotermal kaynaklarla üretilir. District'lerini nereye kurduğun, ekonomik tavanını doğrudan belirler:
[list]
[*] [b]5 Çekirdek District Ailesi:[/b] Şehirlerini [b]Enerji, Üretim, Bilim, Konut ve Ticaret[/b] uzmanlıklarıyla büyüt; Başkent District'i ve Yörünge halkasıyla destekle.
[*] [b]Yarım Adımlı Yer Çarpanları:[/b] District ve binalarını görünür coğrafyayla (dağ gözlemevleri, kıyı limanları, nehir çıkarıcıları) eşleştirerek net [b]1,5×, 2,0× ve üzeri[/b] üretim çarpanları yakala.
[*] [b]Canlı Yol ve Bölge Ağları:[/b] Komşu district'ler A* kara yolları ve deniz rotalarıyla birbirine bağlandıkça sınırlarının gezegen yüzeyinde fiziksel olarak yayılmasını izle.
[/list]

[h2]2. ÇIKAR, İŞLE VE CANLI BORSAYI MANİPÜLE ET[/h2]
[i][🎥 GIF/WEBM #2 — 5 sn döngü: Sol panel siber-kod animasyonuyla Piyasa (Market) ekranına döner. Yeşil ve kırmızı fiyat grafikleri (▁▃▅) dalgalanırken oyuncu 10'luk Ferrite partisi satarak fiyatı düşürür, ardından Moonstone için "■ 150'de Tut" otomatik emrini aktif eder.][/i]

Yorucu kargo gemisi mikro-yönetimini unut. Çıkarılan tüm kaynaklar ortak küresel stoğa akar; böylece tamamen endüstriyel sinerjiye ve finansal stratejiye odaklanırsın:
[list]
[*] [b]82 Bina Modeli & Sabit Üretim Tarifleri:[/b] Gezegen kabuğunu kazarak [b]12 farklı ham minerali[/b] ([i]Ferrite[/i] ve [i]Moonstone[/i]'dan nadir [i]Cryolite[/i] ve [i]Singularite[/i]'e kadar) keşfet; bunları [b]Consumer Goods, Fuel Rods ve Rare Elements[/b] ürünlerine işle.
[*] [b]Dinamik Arz-Talep Borsası:[/b] Satın aldığın her sandık piyasa fiyatını yükseltir, sattığın her stok fazlası fiyatı düşürür. Canlı grafikleri oku ve işlemlerini 0,4× ile 3,0× arasındaki fiyat dalgalarına göre zamanla.
[*] [b]Otonom Ticaret Emirleri:[/b] [i]Trade Automation[/i] araştırmasını açarak rezerv hedefleri ([b]▲ Şuna Kadar Al, ▼ Şuna Kadar Sat, ■ Bu Seviyede Tut[/b]) belirle; sen yeni dünyalara açılırken ekonomin kendi kendini dengelesin.
[/list]

[h2]3. FRAKTAL TEKNOLOJİ AĞACINA HÜKMET[/h2]
[i][🎥 GIF/WEBM #3 — 5 sn döngü: Kamera gezegenden uzaklaşırken tam ekran Blueprint Teknoloji Ağacı açılır. Oyuncu parlayan Keşif dalında "Lunar Program" düğümünü açar, ardından merkez düğüme çift tıklayarak bir önceki medeniyetin tüm teknoloji ağacının içine doğru yakınlaşır.][/i]

Araştırma düz bir liste değil; medeniyetinle birlikte ölçeklenen çok dallı bir strateji ağıdır:
[list]
[*] [b]10 Radyal Araştırma Dalı:[/b] Bilim puanlarını [b]Keşif, Yörünge, Ay, Sanayi, Enerji, Bilim, Ticaret, Nüfus, Planlama ve Yönetim[/b] hatlarına yatır.
[*] [b]Çapraz Dal Uzmanlık Bedeli:[/b] Ana yol dışında açtığın her strateji dalı, diğer dalların Bilim maliyetini artırır; her oturumda farklı bir ekonomik mimari kurmaya zorlar.
[*] [b]Özyinelemeli Fraktal Miras:[/b] Bir üst Medeniyet Tipine geçtiğinde, önceki medeniyetin tüm teknoloji ağacı yeni ağacın [b]tek bir merkez düğümüne[/b] sıkışır. İstediğin an merkeze çift tıklayarak eski ağaca inebilir veya eksik düğümleri tek tıkla satın alabilirsin ([i]Buyout[/i]).
[/list]

[h2]4. KADİM KALINTILARI KAZ VE YOLDAŞLARI EKİBE KAT[/h2]
[i][🎥 GIF/WEBM #4 — 4 sn döngü: Gezegen üzerindeki parlayan kalıntı işaretine tıklanır ve Hikaye Diyalog kartı açılır. Sera Vale'in portresi yanında Kredi, Bilim veya kalıcı Yoldaş katılımı sunan dallanan seçimler belirir.][/i]

Bu dünyalarda inşa yapan ilk kişi sen değilsin. Regolitin altında devrilmiş taşlar, mühürlü Ay kapakları ve yıldızları işaret eden nişan hatları yatıyor:
[list]
[*] [b]9 Dallanan Arkeolojik Kazı Hikayesi:[/b] Ana dünyadaki ve Ay'daki kadim kalıntılara kazı ekipleri gönder. Buluntuları Bilim için katalogla, bronz aletleri sıcak Kredi için sat ya da mühürlü mahzenleri aç.
[*] [b]Yoldaşlar ve Yadigârlar (Companions & Relics):[/b] [b]Sera Vale[/b] (Gezgin Tüccar) ve [b]Dorian Hale[/b] (Ay Müteahhidi) gibi uzmanları ekibine kat; tüm dünyalarında kalıcı bonus veren kadim yadigârları ortaya çıkar.
[*] [b]16 Gezegen Özelliği (Planet Traits):[/b] Gezegenin her seviye atladığında açılan 3 kartlık seçim ekranından ([i]Ancient Archives, Boomtown, Rich Crust, Regolith Seas[/i]) dünyana kalıcı kimlik kazandır.
[/list]

[h2]5. KARDASHEV ÖLÇEĞİNDE YÜKSEL[/h2]
[i][🎥 GIF/WEBM #5 — 5 sn döngü: Yörünge Uzay İstasyonunun fırlatılışı, Ay yüzeyine koloni modülünün inişi ("FIRST STEP ON THE MOON") ve Gelişmiş Gezegen Roketinin Güneş Sistemi görünümünde kavisli bir yörünge çizerek yeni bir gezegene uçuşu.][/i]

Tek bir küre üzerinde başlayan dikkatli yerleşim planlaması, adım adım yıldız sistemi ölçeğinde makro yönetime dönüşür:
[list]
[*] [b]Yörünge Halkasını Kur:[/b] Gezegenin etrafında [b]Orbit City[/b] ve 5 uzmanlaşmış yörünge istasyonu ([i]Zero-G Nexus, Solar Mirrors, Orbital Production[/i]) inşa ederek tüm gezegenin üretimini katla.
[*] [b]Ay'a Yerleş ve Yeni Dünyalara Fırlat:[/b] Ay'a in, yerel [i]Moonstone[/i] çıkar, [b]Lunar Spaceport[/b]'u kur ve [b]Gelişmiş Gezegen Roketini[/b] güneş sistemindeki yeni bir dünyaya ulaştır.
[*] [b]4 Katmanlı Ölçek Kaydırma:[/b] Tip 0'dan Tip 1'e yükseldiğinde, yüzeyde tek tek kurduğun şehir ve district'leri silmeden [b]Güneş Sistemi[/b] ve [b]Galaksi[/b] haritalarında üst ölçekli ekonomik birimler olarak yönet.
[/list]

[hr][/hr]

[h2]BİR BAKIŞTA — SİSTEM ÖZELLİKLERİ[/h2]
[table]
  [tr]
    [th]Sistem / Katman[/th]
    [th]Yönettiğin İçerik[/th]
    [th]Stratejik Derinlik[/th]
  [/tr]
  [tr]
    [td][b]Gezegen & Yörünge İnşası[/b][/td]
    [td]13 District Türü & 82 Bina Modeli[/td]
    [td]5 çekirdek uzmanlık ailesi, yörünge istasyonları, kıyı/dağ/nehir coğrafya şartları ve yarım adımlı yer çarpanları (1,5×, 2,0×).[/td]
  [/tr]
  [tr]
    [td][b]Kaynak & Borsa Motoru[/b][/td]
    [td]12 Ham Mineral + 3 İşlenmiş Ürün[/td]
    [td]Canlı arz-talep fiyat dalgaları (0,4×–3,0×), anlık grafikler, taşma satışı ve 3 otonom ticaret emir modu.[/td]
  [/tr]
  [tr]
    [td][b]Araştırma & İlerleme[/b][/td]
    [td]10 Dallı Radyal Fraktal Teknoloji Ağacı[/td]
    [td]Çapraz dal uzmanlık fiyatlandırması, merkez düğümde özyinelemeli eski çağ ağaçları ve tek tıkla miras satın alma (Buyout).[/td]
  [/tr]
  [tr]
    [td][b]Keşif & Anlatı[/b][/td]
    [td]9 Kazı Alanı, 2 Yoldaş, 16 Gezegen Özelliği[/td]
    [td]Seçim odaklı arkeolojik kazılar, kalıcı imparatorluk yadigârları, 3 kartlı gezegen özelliği seçimi ve 117 Başarım.[/td]
  [/tr]
[/table]
```

---

## BÖLÜM 4: İlk 20 Steam Tag (Etiket) Hiyerarşisi

> **Zukowski Kuralı Doğrulaması:** İlk 5 etikette `Indie`, `Action`, `Adventure`, `Singleplayer`, `2D`, `3D`, `Great Soundtrack` gibi genel etiketler **kesinlikle kullanılmamıştır**. İlk 5 sıra tamamen *Stellaris*, *Civilization VI* ve *Offworld Trading Company* ile ortak olan + oyunun çekirdek döngüsünü tanımlayan yüksek dönüşümlü alt-tür ve mekanik etiketlerinden oluşmaktadır.

| Sıra | Steam Tag (Etiket) | Kategori / Rol | Hangi Referans Oyunla Eşleşir? (*More Like This* Hedefi) |
| :--- | :--- | :--- | :--- |
| **1** | **4X** | Çekirdek Alt-Tür | *Civilization VI*, *Stellaris* |
| **2** | **Colony Sim** | Çekirdek Alt-Tür | *Offworld Trading Company*, *Stellaris* |
| **3** | **Resource Management** | Çekirdek Mekanik | *Offworld Trading Company*, *Stellaris* |
| **4** | **Economy** | Çekirdek Mekanik | *Offworld Trading Company* |
| **5** | **Automation** | Çekirdek Mekanik | *InEv (Data.exe)* + *Offworld Trading Company* |
| **6** | **Grand Strategy** | Alt-Tür | *Stellaris*, *Civilization VI* |
| **7** | **Idler** | Alt-Tür (Incremental) | Incremental / Sayısal Ölçeklenme Kitlesi |
| **8** | **City Builder** | Mekanik | *Civilization VI* (District & Adjacency sistemi) |
| **9** | **Base Building** | Mekanik | *Offworld Trading Company*, *Colony Sim* kitlesi |
| **10** | **Space** | Tema / Atmosfer | *Stellaris*, *Offworld Trading Company* |
| **11** | **Sci-fi** | Tema / Atmosfer | *Stellaris*, *Offworld Trading Company* |
| **12** | **Management** | Mekanik | *Civilization VI*, *Stellaris*, *Offworld Trading Company* |
| **13** | **Procedural Generation** | Teknik / Sistemik | *Stellaris*, *Civilization VI* |
| **14** | **Capitalism** | Mekanik (Canlı Borsa) | *Offworld Trading Company* |
| **15** | **Exploration** | Mekanik (Kazı & Sistem) | *Stellaris*, *Civilization VI* |
| **16** | **Choices Matter** | Yan Mekanik (9 Kazı + Trait) | *InEv Games* anlatı kitlesi + *Stellaris* |
| **17** | **Strategy** | Ana Tür | Üç referans oyunun ortak ana şemsiyesi |
| **18** | **Simulation** | Ana Tür | Üç referans oyunun ortak ana şemsiyesi |
| **19** | **Futuristic** | Atmosfer | *Stellaris*, *Offworld Trading Company* |
| **20** | **Singleplayer** | Oyuncu Modu | Yalnızca son sırada (algoritma ağırlığını sulandırmamak için) |

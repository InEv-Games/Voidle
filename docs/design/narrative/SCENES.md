# Voidle sahne metinleri

[Anlatı akışı](STORY.md) · [Karakter sesleri ve gündelik replikler](DIALOGUE.md) · [Oyun bağlantıları](IMPLEMENTATION.md)

İngilizce metinler doğrudan oyuna aktarılabilecek ilk yazım sürümüdür. Tablo sırası satırların gösterim sırasıdır. Konuşan adları, satır kimlikleri ve seçim hedefleri kayda bağlanabilir. Sahne etiketleri oyuncuya gösterilmez.

## Açılış ve danışman seçimi

### `opening_intro`

Ana dünya görünür görünmez bir kez açılır. Oyuncu gezegeni arka planda görür. Burada şehrin kurulma gerekçesi ve yıldız haritasındaki uyuşmazlık verilir. Lazarus'un ayrıntıları, solucan deliği ve Aniara daha sonra açılabilir.

| Satır | Konuşan | Metin |
| --- | --- | --- |
| `intro_01` | Narrator | In 2440, I-330 landed on a world that looked like its destination. Its charts did not match the sky. |
| `intro_02` | Narrator | The ship carried the embryos of a colony. The caretakers raised the first generation aboard. Today, they are ready to build a city of their own. |
| `intro_03` | High Father | Seventeen thousand four hundred and ninety people are ready to settle. We have enough hands to build, and enough work for all of them. |
| `intro_04` | Mother Superior | Until today, everyone you grew up with has lived under the same roof. You can see the world they chose you to settle. Look at it for a moment. |
| `intro_05` | High Father | The colony has chosen you as its first Facilitator. You may appoint either of us as your advisor. |

Son satırdan sonra iki profil seçeneği açılır. Onaylanan profil etkin danışman olarak kaydedilir ve `opening_handover` başlar. Profilde görünen bonus açıklaması danışman verisinden gelir.

| Seçim | Profil metni |
| --- | --- |
| **Mother Superior** | I can help you organise supplies and give the colony room to grow. |
| **High Father** | I can help keep your power grid steady as the City expands. |

### `opening_handover`

| Satır | Konuşan | Metin |
| --- | --- | --- |
| `handover_ms_01` | Mother Superior | You have our authority, Facilitator. We will carry out your orders. I will serve with you for at least five years. Choose where we will build our first home. |
| `handover_hf_01` | High Father | Authority transferred. We will carry out your orders. My term is five years at minimum. Select a site for the first City. |

Seçilen AI'ın satırı gösterilir. Oyuncu ilerleyince `Found your first City` hedefi ve mevcut yerleştirme modu açılır.

## AI ile tamamlanan öğretici

Aşağıdaki rehberlik birer kez gösterilir. Görevler güncel oyun durumunu okur. Oyuncu bir adımı daha önce yaptıysa tamamlanmış kabul edilir. Kazı, araştırma satın alımı ve belirli bir district rolü öğreticinin tamamlanma koşullarından bağımsızdır.

| Adım | Hedef kartı | Mother Superior | High Father | Tamamlanma |
| --- | --- | --- | --- | --- |
| `guide_city` | Found your first City | Look for a place where you would want to put down roots. Select it when you are ready. | Inspect the terrain. Confirm a valid site for the City. | Ana dünyadaki ilk City'nin inşaatı biter. |
| `guide_capital` | Open the Capital District | Your City already has a centre. Open its Capital District. This is where you can see what the first crews have set up. | Open the City panel, then the Capital District. It came with the City and has its own building slots. | Oyuncu City içindeki Capital District görünümünü açar. |
| `guide_district` | Build a district in your City | A district gives part of the City a job. Pick the one you need and place it within the City. | Select a district role in the City panel. Check the site and the price before confirming. | Ana dünya City'sinde Capital dışı ilk yüzey district'i tamamlanır. |
| `guide_building` | Complete a building | Open a district and choose a building. Its card will show what it needs and what it gives the City. | Open a district and inspect a building's inputs, outputs and capacity requirements. Place it when you are ready. | Ana dünyada oyuncunun yaptırdığı bir bina tamamlanır. |
| `guide_done` | Continue developing your City | The crews know the way to work now. What they build next is up to you. | The basic controls are covered. Keep an eye on the objectives when you want to plan your next expansion. | Öğretici tamamlanmış olarak kaydedilir. |

### `archive_lazarus`

İlk City tamamlandıktan ve Capital District açıklaması okunduktan sonra açılabilen kısa gemi kaydı. Öğretici adımlarını kesmemek için hedef kartında `Read ship record` girişinden isteğe bağlı açılır.

| Satır | Konuşan | Metin |
| --- | --- | --- |
| `lazarus_01` | I-330 Archive | In 2200, the nuclear war began. Project Lazarus launched eight seedships before Earth's last launch sites went dark. |
| `lazarus_02` | I-330 Archive | I-330 was bound for LHS 1140 b. During the crossing, a field of debris forced the ship off course. The next confirmed position is the world below. |
| `lazarus_03` | I-330 Archive | Navigation note. The planet resembles the target. No catalogue match for the sky. |

Son satır bilgi olarak günlüğe eklenir. Bu kaydın okunması kazı veya sefer koşulu değildir.

### `first_ruin_signal`

İlk City tamamlandıktan sonra ana dünyadaki mevcut The Toppled Stones işaretine isteğe bağlı giriş. Kazı işareti, hedef kartı ve maliyet mevcut kazı sisteminden okunur.

| Konuşan | Metin |
| --- | --- |
| Mother Superior | The surveyors found steps under the fallen stones. Someone once took care to build there. We can send a crew when you are ready. |
| High Father | The survey has marked a chamber under the fallen stones. I have added the site to the map. The excavation card has the cost and estimated time. |

İlk oturumda aktif AI'ın satırı kullanılır. Oyuncu sahayı daha önce açtıysa hedef mevcut ilerlemeyi gösterir. Kazının bitişi öğretici için beklenmez.

## The Toppled Stones ve Bolo

### `meet_bolo`

Ana dünyanın ilk kazısının mevcut sonuç akışına bağlanır. Oyuncu önce bronz aletlerle ilgili mevcut tercihi yapar. Bolo'yla henüz tanışılmadıysa her iki dalın sonunda aşağıdaki ortak görüşme açılır. Maliyet ve mevcut ödül için [uygulama eşlemesi](IMPLEMENTATION.md#kazı-ve-sefer-eşlemesi) kullanılır.

| Satır | Konuşan | Metin |
| --- | --- | --- |
| `bolo_01` | Narrator | There is a lamp at the foot of the stairs. A woman sits beside it, sorting fragments into a row. She moves one aside to make room for your boots. |
| `bolo_02` | Unknown Woman | Careful. That bit with the scratch goes next to the hinge. I've been looking for it since before your surveyors arrived. |
| `bolo_03` | Unknown Woman | You're the Facilitator. Your survey crews cut down my fig tree. I planted it the night your ship came down. |
| `bolo_04` | Unknown Woman | I called the tree Bolo. You can call me that. |
| `bolo_roots_01` | Bolo | I grew up underground. When the floods came, my people taught a fungus to cut rooms through rock. My family lived in one of those rooms. People still live there. |
| `bolo_roots_02` | Bolo | I came up when your ship landed. I learned your words from the broadcasts. I wanted to ask what your ship had heard on its way down. |
| `bolo_05` | Bolo | There is a record in here. I can read parts of it. The pauses are the same as a signal I have been hearing from the Moon. |
| `bolo_measurements` | Bolo | I used my own blood to try the equipment down here. I ran the test again years later. My readings should have changed by then. They match right down to the last decimal. |

| Seçim | Bolo'nun cevabı | Devam |
| --- | --- | --- |
| `bolo_ask_signal` · **What do you hear?** | A hum with a gap in it. Always the same gap. That is usually where somebody has left room for an answer. | `bolo_06` |
| `bolo_ask_tree` · **Tell me about your tree.** | It shaded the entrance in the afternoon. I used to set my recorder there. The soil is still bare where the roots were. | `bolo_06` |

| Satır | Konuşan | Metin |
| --- | --- | --- |
| `bolo_06` | Bolo | I can give you my recordings. In return, I want to see what I-330's receivers pick up before your caretakers clean it. Some of those gaps might have data in them. |
| `bolo_07` | Player | You'll have access to the signal. Let me know what you find. |
| `bolo_08` | Bolo | Then we can work together. I will start with the Moon. |

Oyuncu sahneyi tamamladığında Bolo Companions listesine eklenir ve Ay sinyali bilinir. Danışman değişimi ayrı bir onaydır. Seçimler konuşmanın tonunu değiştirir. Kazının ekonomik sonuçları mevcut bronz kararıyla işlenir.

### `bolo_before_moon`

Oyuncu Bolo'yla henüz tanışmadan ilk Ay aracı için kullanılabilir `Prepare Lander` eylemini seçerse uzay limanında bu kısa karşılaşma açılır. Görüşme kapanınca Bolo sefere katılır, Companions kartı açılır ve Ay sinyali kayda girer. Bekleyen hazırlık eylemi devam eder. Gündelik danışman olarak mevcut karakter görevini sürdürür.

| Satır | Konuşan | Metin |
| --- | --- | --- |
| `bolo_port_01` | Narrator | A woman waits by the Spaceport cargo ramp with a recorder wrapped in a cloth. She keeps one hand on it when the ground crew passes. |
| `bolo_port_02` | Unknown Woman | Call me Bolo. It's the name of a fig tree I planted the night your ship came down. |
| `bolo_port_roots` | Bolo | My people moved underground when the floods came. I grew up in rooms they carved with fungus. They're still down there. I came up to see what had landed. |
| `bolo_port_signal` | Bolo | I picked up a pulse from a crater on the Moon. The pause matches a recording I've been working on under the fallen stones. |
| `bolo_port_03` | Bolo | I used my blood to test an instrument in that room. Years later I got the same reading, down to the last decimal. I'd like to try the instrument at the other end. |
| `bolo_port_04` | Player | Come with us. I'll give you access to the ship's raw receiver logs. |
| `bolo_port_05` | Bolo | Good. I'll carry the recorder on board myself. Where can I strap it down? |

İki tanışma yolunda da portre ilk replikten itibaren kullanılabilir. Konuşmacı etiketi adın söylendiği satır tamamlanınca `Bolo` olur. Narrative Log daha önce gösterilen etiketi korur. Bolo yeraltı halkının varlığını anlatır. Kesin konumu vermek için halkının kararını bekler.

### `bolo_at_toppled_stones`

Oyuncu Bolo'yla uzay limanında tanıştıktan sonra The Toppled Stones'a dönerse ilk kazının mevcut bronz tercihi ve ödülleri işlenir. İki dal da tek bir tanıdık repliğine bağlanır.

| Satır | Konuşan | Metin |
| --- | --- | --- |
| `bolo_return_01` | Bolo | This is the room I told you about at the port. I copied the marks on the plate next to the hinge. Watch where you put your lamp. |

### `bolo_surface_invitation`

Bolo'yla tanışmış oyuncu ana dünyadaki beş kazının sonuçlarını tamamladığında davet sahnesi Companions'ta açılır. Bolo, ilk tanışmada söz ettiği halk adına teklifi getirir. Kabulde yüzeydeki buluşma yeri ekiplerle konuşma içinde paylaşılır.

| Konuşan | Metin |
| --- | --- |
| Bolo | I took all five surveys home. We put them beside the maps we've kept since the floods. Your crews found a road we thought we'd lost. A cart can take it all the way to the surface. |
| Bolo | Every household sent someone to the meeting. By morning, everyone had agreed to move up. They asked me to find out if you'll make room for us. |

| Seçim | Bolo'nun cevabı | Sonuç |
| --- | --- | --- |
| **Tell them they are welcome.** | I'll send word. Tell your crews to meet us at the road by the survey camp. The first carts will come up there. | Halkın tamamı katılır. +17.490 Population kapasitesi kabul ile aynı kayıt işleminde bir kez uygulanır. |
| **Let's make room first.** | I'll tell them to keep the carts below. Come find me when you're ready. | Oyuncu teklifi daha sonra seçim düğümünden yeniden açabilir. |

## Ay'a giden sinyal

### `bolo_lunar_signal`

Bolo'nun görüşmesinden sonra haritada `Trace Bolo's signal` anlatı hedefi görünür. Oyuncu hedefi açınca Bolo bir kez konuşur. Hedef, Ay'a erişim varsa The Rim Echo'ya odaklanır. Ay'a henüz gidilemiyorsa sefer hedefi görünür kalır.

| Satır | Konuşan | Metin |
| --- | --- | --- |
| `lunar_01` | Bolo | I compared the raw recording with the chamber's record. Listen to the gap between the pulses. It is the same length in both. |
| `lunar_02` | Bolo | Your receiver places it in a crater. When you can get a crew there, we should see what has been waiting for an answer. |

### `meet_burkai`

The Rim Echo sonuçlandığında mevcut keşif veya patlayıcı dalının ardından ortak görüşme açılır. Bolo iki tanışma yolunda da Ay'a kendi ölçümleriyle gelir. Sinyal hedefindeki isteğe bağlı konuşma atlanmış olsa da iki tanışmada da ölçümlerini anlattığı için ortak satırlar geçerlidir.

| Satır | Konuşan | Metin |
| --- | --- | --- |
| `burkai_01` | Narrator | A figure waits in the shadow below the rim. The light from your visor catches the dust on his coat. |
| `burkai_loud` | Burkai | Dust from the charge is still in the seam. Hold your receiver close. The pulse is there. |
| `burkai_quiet` | Burkai | Stand in the shadow. You can see the seam from here. |
| `burkai_02` | Burkai | Ece. Hold your light a little lower. |
| `burkai_03` | Bolo | How do you know that name? |
| `burkai_04` | Burkai | I'm Burkai. Look at the stone while the light is off it. |
| `burkai_05` | Narrator | In the shadow, three shallow cuts come into view. Bolo holds the receiver to the first one. The pulse returns. |
| `burkai_06` | Bolo | The record from the chamber starts with these same cuts. Someone put a receiver here. |
| `burkai_07` | Burkai | Listen to the gap. There are two replies in it. Put your meter on the third cut. |
| `burkai_08` | Narrator | Two traces come up on the meter. A second line follows each one back to its starting point. |
| `burkai_09` | Bolo | That's my blood test. The other trace came from an I-330 scanner. Look at the date. |
| `burkai_10` | Player | My medical scan from before the handover. The scanner sent it to a receiver on the surface. |
| `burkai_11` | Burkai | The receiver has a copy of your tissue. See where the lines meet? When the tissue changes with age, the signal puts it back the way it was. |
| `burkai_12` | Bolo | I spent years trying to find a fault in my meter. It was giving me the right answer. If the receiver keeps doing this, neither of us will grow old. |
| `burkai_13` | Burkai | The gap is closing. Copy the traces while they are here. |

`burkai_loud` ve `burkai_quiet` satırlarından birini aynı kazı sonucunun geçici `moon_loud` tercihi belirler. Görüşme bitince Burkai kadroya katılır, Ay kaydı saklanır ve `immortality_revealed` işlenir. Bolo ile Facilitator'ın ölçümlerinin ağda neden bulunduğu, ilkinde Bolo'nun kendi testi, ikincisinde geminin ağa yanıt veren muayene tarayıcısı olarak hikâye kaydına girer. Ece adının kaynağı ile Burkai'nin geçmişi bu sahnede belirsiz kalır.

### `mission_after_reveal`

Ay görüşmesinin ardından bir kez açılır. Açılış anında varış ve varsa hedef gövdenin türü okunur. Her dalda Facilitator genişleme hedefini üstlenir. Tip 0'ın sonundaki mevcut oyun eylemi roketin varışıdır. Kalıcı üs hedefi sonraki medeniyetin hikâyesine taşınır.

| Dal | Konuşan | Metin |
| --- | --- | --- |
| Roket henüz varmadı | Player | The crews we send out may spend their lives away from home. I'll be here to see what they build. Let's give them somewhere to work and a way back. |
| Roket yüzeyi olan gezegene vardı | Player | We have readings from another world now. Let's use them to find a landing site. I can be here for the crews who go there and the ones who follow. |
| Roket gaz devine vardı | Player | Use the readings to find a safe orbit. A crew could work from a station there. I'll make sure the next crew can reach it too. |
| Ortak | Bolo | Leave room for a receiver wherever the crew sets up. I want a clean trace from farther out than the Moon. |

## İlk gezegen seferi

### `expedition_briefing`

Advanced Planetary Rocket açıldıktan sonra oyuncu ortak hedef kartındaki Final Rocket bölümünü gördüğünde `Read expedition briefing` eylemi görünür. Brifing bulunduğu gezegenden bağımsız ve isteğe bağlıdır. Eylem sahne okunana veya roket kalkana kadar görünür. Hazırlık ve fırlatma kendi koşullarıyla ilerler.

| Dal | Konuşan | Metin |
| --- | --- | --- |
| Ortak | I-330 Flight Control | The next vehicle can reach another planet. Its readings will tell us where we could send a crew if we need a second home. |
| Ay kaydı varsa | Bolo | Leave the receiver on during the crossing. We know what the pulse sounds like at the Moon. I want to hear what changes as we leave it behind. |
| Ay kaydı henüz yoksa | I-330 Flight Control | The vehicle will keep a raw receiver log throughout the crossing. We can compare it with our surveys after arrival. |

### `planetary_arrival`

İleri roketin seçilmiş gezegene varışında bir kez açılır. Varış ve medeniyet geçişi oyunun mevcut davranışıyla tamamlanır. Sahne, önceki kazılardan elde edilen bilgiye göre bir dal gösterir.

| Dal | Konuşan | Metin |
| --- | --- | --- |
| Ortak | I-330 Flight Control | Arrival confirmed. The vehicle has reached the selected world. We are receiving its telemetry. |
| Ay kaydı varsa · `arrival_signal_comparison` | Bolo | I checked the arrival telemetry against our copy from the Moon. The same pause is there. We have two places we can measure it now. |
| Ay kaydı henüz yoksa | I-330 Archive | The vehicle's receiver has recorded a repeating pulse. Its raw trace has been saved for comparison. |
| Ortak | Unknown Voice | Receiver at the edge of the survey, give us your bearing. |
| Ortak | I-330 Flight Control | Signal stored. We have a direction for the voice. It came from beyond the selected world. |

Bu ses, ileride karşılaşılacak bir yoldaşa veya başka bir topluluğa işaret eder. Kimliği Tip 0'da açıklanmaz. Varış dalı sahne ekrana ilk geldiğinde seçilir ve saklanır. Ay kaydı o sırada varsa Bolo'nun karşılaştırma satırı burada görünür. Varış sahnesi ham kayıt dalıyla kapandıysa ve Ay kaydı sonradan elde edildiyse aynı satır `mission_after_reveal` ortak satırından önce görünür. İki giriş aynı `arrival_signal_comparison` kimliğini kullanır. Varış ve ekonomik geçiş bir kez işlenir.

## Dönüş ve gemi uykusu

`return_from_stasis`, kalıcı kaydın yokluk aralığı uygulandığında açılır. Oyuncunun I-330'daki koruyucu uyku kabininden çıkışı, takvimde ilerleyen süreyi açıklar. `{elapsed}` uygulanan koloni süresidir. Bir tam aydan kısa sürelerde zaman belirtmeyen varyant kullanılır. Konuşan, yokluk kaydında etkin olan danışmandır.

| Konuşan | Zaman belirtilen karşılama | Kısa yokluk |
| --- | --- | --- |
| Mother Superior | Welcome back. You were in I-330's suspension berth for {elapsed}. I kept the work orders you left. | Welcome back. The berth is open. I have the shift report. |
| High Father | Suspension berth released. The colony clock advanced by {elapsed}. Your standing orders remained in effect. | Berth released. I have the latest work log. |
| Bolo | You were under for {elapsed}. I copied the records while the berth was sealed. Come and look. | I heard the berth open. I have the latest records here. |
| Burkai | The berth opened. {elapsed} passed outside it. I can show you what changed. | You're awake. I kept the report. |

Ardından gerçekleşmiş işler ve olaylar gösterilir. Yüzeye dönme, olayın yerine gitme veya ayrıntıları okuma eylemleri veriye bağlıdır. [Olay CSV'leri](OFFLINE_EVENTS.md)

## Kalp konuşmaları

Her danışmanın 50 yıl aralıkla açılan on kısa konuşması vardır. Öğretici tamamlandıktan sonra Companions üzerinden okunur. Kimlikler kayıtta ayrı tutulur. Oyuncu konuşmaları farklı sırada açabildiğinden her biri tek başına anlaşılır. Konuşmalar, Bolo'nun halkıyla ilgili keşifler, ölümsüzlük sahnesi veya seferdeki ilerleme hakkında bilgi varsaymaz.

| Kimlik | Danışman | Görev yılı | Metin |
| --- | --- | --- | --- |
| `friend_ms_050` | Mother Superior | 50 | Someone brought the first City plan back to the ship. They had drawn the paths their children actually use over our neat little roads. |
| `friend_ms_100` | Mother Superior | 100 | The night staff at the nursery used to warm a cup before they woke the children. I still ask the kitchen to do it for someone coming out of the berth. |
| `friend_ms_150` | Mother Superior | 150 | A clerk asked which names to keep on the old shift rosters. I asked her to keep the misspellings too. Some people wrote their own names there for the first time. |
| `friend_ms_200` | Mother Superior | 200 | There is a chair next to my desk now. The crew put it there when they noticed how often you stop to listen. |
| `friend_ms_250` | Mother Superior | 250 | I used to prepare the handover report with your name in the subject line. Now I keep a copy for you at the table. |
| `friend_ms_300` | Mother Superior | 300 | Someone sent me a photograph of a school bench made from an old berth lid. I recognised the blue handle. We used to catch our sleeves on it. |
| `friend_ms_350` | Mother Superior | 350 | The night cook has started leaving the good pears by my terminal. If you want one, ask me before the morning shift finds them. |
| `friend_ms_400` | Mother Superior | 400 | A girl asked if the drawing beside my desk was yours. I said you could tell her yourself. She wants to know where you meant to put the front door. |
| `friend_ms_450` | Mother Superior | 450 | I know the knock you use when you have a question you could have sent in writing. Come in. I have time for it. |
| `friend_ms_500` | Mother Superior | 500 | The archive wants my account of the handover. It has the official recording. I want to hear what you noticed while we were talking. |
| `friend_hf_050` | High Father | 50 | I used to send you the entire grid report. You always asked for the same page. I have moved it to the front. |
| `friend_hf_100` | High Father | 100 | A technician left a correction in the margin of my schedule. She was right. I asked her to sign it. |
| `friend_hf_150` | High Father | 150 | The first crew insisted on keeping a paper copy of the load plan. We still use it when someone needs to point at two lines at once. |
| `friend_hf_200` | High Father | 200 | You asked me to tell you when I was uncertain. I have added a column for it. I use it more than I expected. |
| `friend_hf_250` | High Father | 250 | The grid is steady. I can leave the report with the duty crew for a while. Walk with me to the observation window. |
| `friend_hf_300` | High Father | 300 | I keep a voltmeter from the first workshop. Its needle sticks at zero. Tap the left side and it reads correctly. |
| `friend_hf_350` | High Father | 350 | The drill team asked me to sign off on a shorter inspection. I sent them your notes from the last review. They kept the extra minute. |
| `friend_hf_400` | High Father | 400 | I have drawn the feeder route by hand. You catch things on paper that I miss in a schematic. Start with the bend above the pump. |
| `friend_hf_450` | High Father | 450 | Dispatch has my direct number. So do you. Call if you want a second reading before you sign. |
| `friend_hf_500` | High Father | 500 | A new technician asked who reviews my decisions. I gave her your extension. Expect a call after shift change. |
| `friend_bolo_050` | Bolo | 50 | I left a pause in the recording where the metal rings. Wait through it. You can hear the smaller piece slide along the shelf. |
| `friend_bolo_100` | Bolo | 100 | One of your crew asked what the word on the door meant. She came back the next shift with a pencil rubbing. I kept it. |
| `friend_bolo_150` | Bolo | 150 | I started putting your replies in the margins of my field notes. They make it easier to tell where I was guessing. |
| `friend_bolo_200` | Bolo | 200 | I took a cutting from a fig tree and put it by the workshop window. Come look when it puts out a leaf. |
| `friend_bolo_250` | Bolo | 250 | I've got two copies of the survey now. Take the one with my marks in it. You'll know which ones to ask me about. |
| `friend_bolo_300` | Bolo | 300 | I found a thumbprint in a lump of fired clay. Here. Hold it to the light from the side and you can count the ridges. |
| `friend_bolo_350` | Bolo | 350 | Someone wrote 'unknown' over a word I spent a week translating. I put my notes on your desk. Leave the coffee ring. It shows where I stopped for the night. |
| `friend_bolo_400` | Bolo | 400 | The survey crew gave me a fresh pencil. I'll keep this stub until I finish the page. It fits the groove in my thumb. |
| `friend_bolo_450` | Bolo | 450 | I've put your name on the second pair of gloves. Come help me turn the slab. I want somebody here who'll stop when I say stop. |
| `friend_bolo_500` | Bolo | 500 | I still say the field notes out loud. There are two voices on this reel now. Yours comes in halfway through, asking where I got the date. |
| `friend_burkai_050` | Burkai | 50 | There is a loose clip on your receiver. Hold it down with one finger. The small rattle goes away. |
| `friend_burkai_100` | Burkai | 100 | There's a lamp at the bend in the rim. It points at the ground. I can see where you put your feet. |
| `friend_burkai_150` | Burkai | 150 | When the crew takes a break, the wall sounds the way it did before they came. I wait there a while. |
| `friend_burkai_200` | Burkai | 200 | Your boots make a different sound from the crew's. I hear you at the turn. |
| `friend_burkai_250` | Burkai | 250 | The receiver sits in the shade. There's room beside it. |
| `friend_burkai_300` | Burkai | 300 | The door sticks at the top. Put your palm against it before you pull. |
| `friend_burkai_350` | Burkai | 350 | There is a page face down on the desk. You can turn it over. Leave the others where they are. |
| `friend_burkai_400` | Burkai | 400 | Your lamp is fine there. The lip of the crater keeps it out of my eyes. |
| `friend_burkai_450` | Burkai | 450 | The seal hums when the dome gets cold. Sit here and you can feel it through the bench. |
| `friend_burkai_500` | Burkai | 500 | I'm at the window. Bring your chair over. The ridge is just coming into view. |

## Eski yoldaş repliklerini uyarlama

Bu satırlar mevcut kazıları yeni kadro ve sinyal hattına bağlar. Oyuncunun mevcut kazı tercihleri, kaynak ödemeleri ve dalların bayrakları korunur. Tablonun dışındaki girişler, seçenekler ve sonuç satırları kaynak VSM sayfalarından gelir.

| Sahne | Nokta | Konuşan | Yeni metin |
| --- | --- | --- | --- |
| `vesyn_2_traders_cache` | Sandık ilk görüldüğünde | Narrator | The crew lifts the crate out. A trader's mark shows through the flaking paint. |
| `vesyn_2_traders_cache` | Sandık açıldı | Narrator | Trade goods, well packed. Cloth still separates the pieces. |
| `vesyn_2_traders_cache` | Sandık notla kapalı bırakıldı | Narrator | You tuck the note under the handle before the crew lowers the crate back into place. |
| `vesyn_2_traders_cache` | Bronz alıcısına işaret gösterildi | Narrator | The buyer recognises the mark from another crate. They pay for a copy and leave the original with your surveyors. |
| `vesyn_3_compass_bearer` | Açılış | Narrator | A narrow passage runs past the crate chamber. A metal pointer catches the survey lamp at the far end. |
| `vesyn_3_compass_bearer` | Sandık kapalı bırakıldı | Bolo | You left the crate sealed. Good. Its contents are still in the order somebody packed them. |
| `vesyn_3_compass_bearer` | Sandık açıldı | Bolo | The crate was opened. I can still take a reading, if the pieces are all here. |
| `vesyn_3_compass_bearer` | Ortak bulgu | Bolo | Watch the needle when the Moon clears the ridge. It turns with it. Hold the compass steady while I take a reading. |
| `vesyn_3_compass_bearer` | İlk seçim etiketi | Player | Record the instrument for the survey crews. |
| `vesyn_3_compass_bearer` | İkinci seçim etiketi | Player | Follow the bearing in the archive. |
| `vesyn_3_compass_bearer` | Kapanış | Narrator | The survey crew files the bearing beside Bolo's recording. |
| `vesyn_4_ledger_vault` | Açılış | Bolo | The bearing passes another ruin. The door has a ledger mark over the lintel. Bring a crew if you want to see what they kept behind it. |
| `vesyn_4_ledger_vault` | Sonuç | Bolo | An accounts office. There is a route number beside each entry. Some of them run straight into the sky. |
| `vesyn_5_pale_line` | Ortak kapanış | Narrator | The survey follows the stones to the horizon. At moonrise, the bearing passes through the centre of the Moon. |
| `moon_2_builders_marks` | Sonuç açılışı | Narrator | The crew clears a section of wall. The same cut repeats at equal intervals all the way around the rim. |
| `moon_3_sealed_hatch` | Açılış | Narrator | The marks end at a sealed hatch. A path along the rim gives your crew room to bring down the equipment. |
| `moon_3_sealed_hatch` | Patlayıcı kullanıldı | Survey Lead | The charge loosened a plate. We can see a second seal underneath. |
| `moon_3_sealed_hatch` | Patlayıcı kullanılmadı | Survey Lead | We followed the markings by hand. They run straight into the seal. |
| `moon_3_sealed_hatch` | Ortak bulgu | Survey Lead | This is a builder's mark. We can copy the assembly or open the hatch while the instruments are in place. |
| `moon_3_sealed_hatch` | Kapanış | Narrator | Your crews return with a diagram of the seal and the route to the next chamber. |
| `moon_4_foundations` | Açılış | Survey Lead | We found another hatch across the plain. Same marks. We will need heavy gear to reach the chamber. |
| `moon_4_foundations` | Sonuç | Survey Lead | There are plans for a city here. The first section matches the foundations under our feet. |
| `moon_4_foundations` | Son kayıt | Narrator | The last sheet contains a series of bearings. One begins here and continues beyond the Moon. |

### Kazı kartı ve haber metinleri

Aşağıdaki satırlar saha kaynağının `teaser` alanına yazılır. Kazı kartı ile hazır ve bitiş haberleri aynı alanı okur.

| Saha | Yeni metin |
| --- | --- |
| `vesyn_compass_bearer` | A metal pointer is visible at the far end of a narrow passage. |
| `vesyn_ledger_vault` | A door with a ledger mark stands at the end of the bearing. |
| `moon_sealed_hatch` | The cuts in the crater wall end at a sealed hatch. |
| `moon_foundations` | The survey crews found a second hatch across the plain. |

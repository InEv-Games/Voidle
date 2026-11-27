# Voidle yapılacaklar

## 1. Narrative

- [ ] Açılıştan ilk kazıya kadar danışman akışını yeni öğreticiye göre yaz. Mother Superior ve High Father oyuncuyu karşılar. Government Building tamamlanınca ilk danışman seçilir. Aktif danışman görevleri ve eksik kaynak desteğini hikâye içinde anlatır. Oyuncu her adımda devam yanıtı verir ve eksik kaynak varsa tamamlanır. Açıklayıcı replikler danışmana, oyuncunun seçtiği yanıtlar Narrative Log'da YOU etiketine ait.
- [ ] Kazı seçimlerini ve sonuçlarını tek tek gözden geçir. Oyuncunun seçimiyle gelen ödülleri anlaşılır biçimde göster. Bolo ilk kazı sonucunda tanışılır ve geçmişini anlatır. Öğretici, Bolo'ya ücretli geçişi de kapsar. [Güncel anlatı paketi](design/narrative/README.md)
- [ ] Welcome Back repliklerini danışmana göre yaz. Aktif danışman şu anda gerçekleşen rastgele olayları ve net kaynak değişimlerini anlatıyor. Yoklukta tamamlanan işler de Narrative turunda özete bağlanacak.
- [ ] **20 majör ve 100 minör olay** yaz. [Olay tablosunu](../resources/narrative/colony_events.csv) ve [danışman replikleri tablosunu](../resources/narrative/colony_event_advisors.csv) doldur. Her danışman için olayın ilgili sahnelerine ayrı replik yaz. İlk içerikte iki minör olay, iletken toz fırtınası ve kıyı taşkını var.
  - Majör olayları City veya gezegen ölçeğinde mini hikâyeler olarak yaz. Belirtileri, kararın maliyetini ve 2–4 koloni yılı sonraki etkisini aynı olayda takip et. Kalıcı bina kayıplarında oyuncuya karar öncesi binaları göster. Müdahale seçeneği çalışan Emergency Response Center gerektiriyor ve bir ay boyunca toplam enerji talebini %20 artırıyor.
  - Minör olayların çevrimdışı repliklerinde danışman aldığı kararı ve gerçekleşen ödülü anlatır. Majör olaylarda danışman gelişmeyi bildirir ve kararı oyuncuya bırakır.
- [ ] Piyasa olayları için ayrı CSV hazırla. Kaynak, fiyat etkisi, süre, haber ve Trade tooltip'i aynı olaydan gelsin. Küçük piyasa dalgası grafikte, karar değiştirici fiyat hareketinin nedeni ve süresi haber ile tooltip'te görünsün.
- [ ] Government'taki basın yardımcısının News açıklamalarını yaz. Yardımcının adı ve açıklaması haberlerde yer alır. Oyun içi yönlendirme, olay tepkileri ve hikâye diyaloglarını aktif danışman yürütür.
- [ ] New Game'deki Tip 0–6 açıklamalarını onaylı uygarlık adları ve bir sonraki fetih ölçeği üzerinden tamamla. Kayıt silme metni, aynı seed tekrar kullanılsa bile koloni geçmişinin ve oyuncu kararlarının kaybolmasını anlatmalı. Sağ üstteki Type tooltip'ine ulaşılan aşamayı anlatan kısa bir lore metni yaz.

## 2. Notifications

- [ ] Narrative sonrasında paneli koloni takibi için yeniden tasarla. Hangi sorunların uyarı ürettiğini, tıklamanın oyuncuyu hangi panel veya konuma götürdüğünü ve sorun çözülünce uyarının nasıl kapandığını tanımla. Öğreticide nüfus yetersizliği ile üretim düşüşü aynı uyarıda anlatılsın. Enerji açığı, boş bina ve district yuvaları sıradaki eyleme götürsün.

## 3. Son öğretici ve demo temposu incelemesi

- [ ] Öğreticiyi iki yerleşim seçeneğiyle baştan sona ekipçe gözden geçir. Sabit seed'deki yardımlı önerilerin geçerliliğini ve hedeflenen 2× verimi incele. Yardımsız konumlarda normal yerleşim kurallarının sonraki adımlara izin verdiğini ve şebeke dersinin dağda Wind Turbine, diğer arazilerde Solar Matrix ile tamamlandığını doğrula.
- [ ] İlk City konutunu, nüfus ve enerji açıklarının doğru adımda oluşup kapanmasını, Ferrite taşması ve Warehouse dersini, araştırma fiyat artışını, manuel Trade adımlarını ve kazıdan Bolo'ya geçişi incele. Öğreticiyle normal oynanışta City, district ve binaların inşa, üretim ve işletme tarifeleri ortak olmalı. Başlangıç kasası ve danışmanın eksik kaynağı tamamlama miktarlarını bu sırada dengele.
- [ ] Demo ilerleme temposunu son oynanış turunda değerlendir. Özellikle oyun fazla kolaylaştığında hangi gelir veya desteğin tempoyu değiştirdiğine bak.

## Sonraya ayrılan işler

- [ ] Wonder için geçici harita işareti yerine kalıcı sembol tasarla. Sembol district işaretinden biraz küçük.
- [ ] **UI ekibi.** Ana menü gezegenleri, Satürn benzeri gaz devinin pus, bant ve halka görünümü.
- [ ] **Ses ekibi.** NPC diyalog sesleri. Eksik ses eşlemeleri sonraki kontrolde ele alınacak.
- [ ] **Kodcu.** Çıkış panelindeki playtest e-posta alanı ve Send düğmesini abonelik altyapısına bağla.
- [ ] **Sonraki kontrol.** Başarım sayaçlarını güncel binalar, araştırmalar ve öğretici akışıyla karşılaştır.

## Tamamlanan kararlar

- [x] **Depo kapasitesi aşımı.** Bir ham maden veya işlenmiş kaynak, depo yıkımı ya da kapasite düşüşünden sonra yeni sınırın üstünde kalırsa imparatorluktaki üretim %10 azalır. Ceza bir kez uygulanır ve tüm stoklar kapasiteye sığdığında kalkar. Kaynak tooltip'leri kapasiteyi aşan kaynağı gösterir.
- [x] **Başlangıç.** Her yeni koloni aynı öğreticiye giriyor. Placement Assist sadece City ve district yerinin önerilmesini belirliyor. Ayrı öğreticisiz başlangıç paketi ve telafi bütçesi tasarımı kapandı. Irk seçimi ve nüfus tooltip'indeki ırk dağılımı geri alındı. Lider adı ve koloni adı seçilebiliyor. Logo demoda kilitli.
- [x] **Upgrade Tree ve yeni mekanik binaları.** Simetrik Tip 0 ağı, tier bazlı araştırma tarifesi, ortak Fuel açılışı, iki seviyeli Recycling, beş Ay araştırması ve coğrafya uzmanlıkları oyunda. Emergency Response Center, Civil Administration, Wonder Construction Bureau, Trade Administration ve Science district'indeki Spaceport araştırmalara bağlı. Öğreticide açılan Capital binaları kendi akışında geliyor.
- [x] **Wonder.** Capital dışındaki beş türün her birinde bir T4 model var. City başına bir Wonder kurulabiliyor. Her model iki yuva kullanıyor, kendi City'sine %10 bonus veriyor ve aynı işletme gideri ile iş gücü tarifesini kullanıyor.
- [x] **Demo ekonomi kararları.** Bina ve Trade tarifeleri, Commercial ile satış karşılaştırması, Ay giderleri, roket maliyeti ve Trade taşma davranışı gözden geçirildi. Ay giderleri, roket maliyeti ve taşma davranışı mevcut değerleriyle kabul edildi. Cavern Refinery aylık 72 Energy ve 53 Moonstone tüketiyor. Diğer dört Ay modeli 18 Moonstone ek gider ödüyor.
- [x] **Küçük işler.** Steam Wishlist ve çıkış paneli, New Game önizlemeleri ve açıklama alanları, district konum ve komşuluk hesabı, haber şeridi etkileşimi, kazı harita tooltip'i, First Residents temizliği ve eski tasarım kalıntılarının taraması tamamlandı.

Kod değişiklikleri [teknik günlükte](VOIDLE_KOD_DEGISIKLIK_GUNLUGU.md) tutulur.

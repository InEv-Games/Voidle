# Ece — Görsel Promptları (v4)

7 Kasım 2026 · `Visual_Notes.md`'deki sahne ve pozlardan, yapıştırılan JSON düzeniyle.

**Nasıl kullanılır**
- Her blok tek başına çalışır: Flow önceki promptu hatırlamadığı için `style`, `character.identity` ve `negative_prompt` her blokta tekrarlanıyor.
- `character.identity` tüm promptlarda aynı; yalnızca saç topuzu ya da kask gibi sahneye özel küçük farklar var. Karakteri tutarlı tutan bu blok.
- Sahneler arasında `outfit`, `props`, `pose`, `composition` ve `style.mood` değişiyor.

## Görsel yön

**Stil:** 80'lerin sonu / 90'ların başı OVA anime cel'i ve kaset fütürizmi (cassette punk). Elle boyanmış cel'ler, film greni, VHS gürültüsü. Teknoloji tıknaz ve analog: bej ve kül grisi plastik, kadranlar, toggle anahtarlar, kıvrık kablolar, manyetik bant, yeşil fosforlu CRT ve LCD ekranlar.

**Kıyafet anahtar kelimeleri: lateks, cropped, transparent.** `style.fashion_keywords` alanı bunları her promptta taşıyor.

| Katman | Saha (0–3, 8, 10, 11) | Laboratuvar (4, 5, 9) | Ay (6, 7) | Stüdyo (12) |
| --- | --- | --- | --- | --- |
| **Opak lateks** | Teal-siyah cropped yarış üstü (dik yaka, mavi-yeşil biyeler, göbek üstünde biter) ve yüksek bel şort | Teal-siyah halter bodysuit (yüksek boyun, içe kesik omuz, yüksek bacak kesimi) ve siyah lateks kalem mini etek | Teal-siyah tam boy basınç giysisi | Halter bodysuit |
| **Transparent lateks** | Kaburgada biten dumanlı zeytin yeşili cropped ceket; şortun üstünde yandan açık sarma mini etek | Buzlu beyaz uzun önlük | Omuzlarda cropped bolero, kalçada mini etek gibi paneller | Cropped ceket |
| **Plastik donanım** | Bej kemer, kaset kaydedici kılıfı, platform botlarda kaval koruması | Kemer tokası, cep klipsleri | Kadranlı göğüs plakası, kol korumaları, sırt ünitesi, kabarcık kask | Platform spor ayakkabı |
| **Bacak** | File tayt üstüne lateks diz üstü çorap | Lateks diz üstü çorap | Lateks uyluk boyu platform bot | Lateks diz üstü çorap |
| **Hep aynı** | Bilekte yeşil LCD'li tıknaz bilgisayar, mikro kaset ses kaydedici | | | |

**Arka plan:** Tüm promptlarda aynı nötr, düz gri-bej arka plan; mekân, mobilya ya da manzara yok. Sahnenin havası ışık, poz ve proplardan geliyor. Bu kural kodda zorunlu: her promptun `background` alanı aynı değere yazılıyor.

**Pozlar:** Her poz o anın kendi duygusu içinde seductive. `pose.allure` alanı bu cazibenin o sahnede nasıl okunduğunu yazıyor: kapıda meydan okuma, Zone 6'da "takip et" daveti, yeşil ışıkta utangaç yakınlık, laboratuvarda gece yarısı mahremiyeti, pencerede söylenmemiş özlem, Ay'da cesaret gösterisi, nefeste rahatlama. A-pose ve model sheet'te gövde yapısı korunuyor; cazibe yüzde ve duruşta.

**SFW kuralı:** Transparent katman yalnızca opak lateksin, kolların, karnın ya da bacakların üstüne gelir; göğüs ve kalça her zaman opak. Negatif promptta "see-through top, exposed chest, visible underwear" bu yüzden var.

**Referanslardan alınanlar** (birebir kopyalanmadan):

| Referans | Alınan |
| --- | --- |
| Evangelion'un yetişkin bilim insanı karakteri (Ritsuko) | Olgun, serin yüz; yarı kapalı bakış; koyu kırmızı ruj; dik yaka; kalem etek; açık önlük; bir el belde, bir el saçta (9) |
| Evangelion'un yetişkin komutan karakteri (Misato) | Dar elbisenin üstünde kısa, omuzları kabarık cropped ceket |
| Cowboy Bebop'un kadın baş karakteri (Faye) | Parlak cropped üst, açık göbek, kısa alt, uzun bacak çizgisi |
| Yarış kıyafetli retro anime görseli | Dik yakalı, neon biyeli cropped yarış üstü, okunmaz yamalar, yüksek bel alt |
| Puf montlu retro anime görseli | Platform botlar, file tayt, yeşil ışıklı mekân |
| Ekose etekli retro anime görseli | Parlak cropped ceket, diz üstü çorap, omuz üstünden bakış |
| Fotoğraf: yüksek yakalı body | Halter bodysuit kesimi; alt açıdan, bacakları açık, kalçası yana kırık duruş (12) |
| Fotoğraf: kılıçlı alçak hamle | Yere bir diz, diğer bacak yana uzanmış duruş; kılıç yerine Ece'nin saha ölçüm çubuğu (11) |

Bilerek **alınmayanlar:** Ritsuko'nun sarı bob'u, beni, halka fermuarı ve küpeleri; Misato'nun beresi ve haç kolyesi; Faye'in sarı yeleği ve saç bandı. Negatif promptta bunlar da var. Promptlarda dizi ya da karakter adı yok.

**Pileli etek:** Ekose etek referansında var, ama diz üstü çorapla birleşince model okul üniformasına kayıyor. Bu yüzden pileli etek negatif promptta kaldı; etekler sarma ve kalem kesim.

**Ece'yi sabitleyen dört şey:** yeşile çalan uzun kızıl saç, çenede ince yara izi, çiller, mavi-yeşil mantar ışığı.

| # | Prompt | Kıyafet | Sahne |
| --- | --- | --- | --- |
| 0 | Model sheet | Saha | Kimlik referansı (önce bunu üretin) |
| 1 | Kapıdaki yabancı | Saha | §2 İlk temas |
| 2 | Kül ve hendek | Saha | §5 Zone 6'ya yürüyüş |
| 3 | Karanlıktaki yeşil | Saha | §5 Mantar ışığı |
| 4 | Kırağı yazı | Laboratuvar | §6 Laboratuvar |
| 5 | Pencere | Laboratuvar (önlüksüz) | §6 Ay'a bakış |
| 6 | Ay giysisi | Ay | Act II iniş |
| 7 | Nefes | Ay (kasksız) | Act II Burkai sonrası |
| 8 | İfade sayfası | Saha | Duygu referansı |
| 9 | Laboratuvar portresi | Laboratuvar | Ritsuko referansının duruşu |
| 10 | A-pose | Saha | Simetrik tam boy referans |
| 11 | Saha duruşu | Saha | Alçak hamle, ölçüm çubuğuyla |
| 12 | Stüdyo duruşu | Stüdyo | Alt açı, moda pozu |

---

## 0 · Model sheet (kimlik referansı)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime official character model sheet, hand-painted cels, retro-futuristic anime",
    "design_language": "cassette futurism: chunky beige and ash-grey plastic hardware, analog dials, toggle switches, rubber buttons, coiled cables, magnetic tape, green phosphor CRT and LCD readouts",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers over opaque latex, bare midriff, high collars, knee-high socks, chunky platform boots",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted white specular streaks on hair, glossy latex and transparent materials",
    "color": "faded analog colors, deep teal-black latex, smoky olive transparent latex, beige plastic hardware, fungus blue-green accents, green phosphor glow, green-tinted red hair, deep red lips",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "confident, guarded, seductive field scientist"
  },
  "character": {
    "name": "Ece",
    "identity": {
      "age": "adult woman, 35 years old, clearly mature",
      "face": {
        "shape": "elegant mature 80s OVA anime face of a cool adult scientist, sharp striking features, defined cheekbones, narrow chin",
        "eyes": "narrow half-lidded green-hazel eyes with thin dark lashes and painted catchlights, cool appraising gaze, faint fine lines at the outer corners",
        "lips": "deep red lipstick, small knowing smirk",
        "default_expression": "cool, dry and guarded, looking down slightly at the viewer"
      },
      "hair": {
        "color": "long red hair with a green tint: deep crimson red that shifts toward olive green in the shadows",
        "style": "long loose wavy hair reaching mid-back, side-parted, a few strands framing the face, slightly messy, no blunt bangs",
        "highlights": "painted glossy highlight bands with a green sheen"
      },
      "marks": {
        "scar": "thin pale scar along the left jawline",
        "freckles": "faint freckles across the nose and cheeks"
      },
      "body": "tall, athletic hourglass figure, long legs, toned arms and stomach, adult proportions"
    },
    "outfit": {
      "top": "opaque glossy teal-black latex cropped racing top with a high mandarin collar and short sleeves, fungus blue-green trim at collar, cuffs and hem, small blank patches with unreadable symbols, ending above the navel",
      "midriff": "bare toned midriff between top and shorts",
      "jacket": "cropped jacket of transparent smoky olive latex worn over the top, ending at the ribs, high stand-up collar, puffed shoulders, sleeves pushed to the elbow, chunky cargo pockets, light dust",
      "bottoms": "opaque glossy teal-black latex high-waist hot pants",
      "skirt": "transparent smoky olive latex wrap mini skirt over the hot pants, open at one side",
      "belt": "beige plastic utility belt with a chunky clip buckle, small pouches and a holster for a cassette recorder",
      "wrist_unit": "chunky beige wrist computer with a small green phosphor LCD, rubber buttons and a coiled cable",
      "legwear": "sheer black fishnet tights under glossy black latex knee-high socks with a single blue-green stripe at the top",
      "footwear": "chunky platform boots with beige plastic shin guards, scuffed",
      "accessories": "cross-body satchel with a reinforced beige plastic flap"
    },
    "props": {
      "recorder": "palm-sized microcassette voice recorder with a visible tape window, a red record light and a coiled cable, in the belt holster"
    }
  },
  "pose": {
    "camera": "model sheet turnaround: front view, three-quarter view, side view, back view, all full body, eye-level",
    "action": "relaxed contrapposto in every view: weight on one leg, hip popped to the side, one hand resting on her hip, shoulders loose, chin slightly lowered",
    "expression": "cool, heavy-lidded, a faint sultry half-smile, same face in every view",
    "allure": "seduction through ease: a woman fully comfortable in her body, the pose itself is the invitation. Tasteful and SFW, adult woman"
  },
  "composition": {
    "framing": "four full-body views side by side, horizontal 16:9, consistent scale",
    "background": "plain neutral flat background, muted grey-beige, no scenery",
    "lighting": "soft flat frontal light, subtle cel shadows"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, schoolgirl, school uniform, pleated skirt, sailor collar, nudity, nsfw, explicit, nipples, see-through top, exposed chest, visible underwear, lingerie, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, smartphone, touchscreen, sleek modern technology, holographic UI, minimalist design, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, red bodysuit, hair clips, beret, cross necklace, yellow vest, headband, detailed background, scenery, environment, room, furniture, landscape, lewd gesture, crotch focus, upskirt, spread legs facing camera, wardrobe malfunction"
}
```

---

## 1 · Kapıdaki yabancı (§2 İlk temas)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels over painted backgrounds, retro-futuristic anime screencap",
    "design_language": "cassette futurism: chunky beige and ash-grey plastic hardware, analog dials, toggle switches, rubber buttons, coiled cables, magnetic tape, green phosphor CRT and LCD readouts",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers over opaque latex, bare midriff, high collars, knee-high socks, chunky platform boots",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted white specular streaks on hair, glossy latex and transparent materials",
    "color": "faded analog colors, deep teal-black latex, smoky olive transparent latex, beige plastic hardware, fungus blue-green accents, green phosphor glow, green-tinted red hair, deep red lips",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "a dusty stranger entering a sterile room, defiant, magnetic and seductive"
  },
  "character": {
    "name": "Ece",
    "identity": {
      "age": "adult woman, 35 years old, clearly mature",
      "face": {
        "shape": "elegant mature 80s OVA anime face of a cool adult scientist, sharp striking features, defined cheekbones, narrow chin",
        "eyes": "narrow half-lidded green-hazel eyes with thin dark lashes and painted catchlights, cool appraising gaze, faint fine lines at the outer corners",
        "lips": "deep red lipstick, small knowing smirk",
        "default_expression": "cool, dry and guarded, looking down slightly at the viewer"
      },
      "hair": {
        "color": "long red hair with a green tint: deep crimson red that shifts toward olive green in the shadows",
        "style": "long loose wavy hair reaching mid-back, side-parted, a few strands framing the face, slightly messy, no blunt bangs",
        "highlights": "painted glossy highlight bands with a green sheen"
      },
      "marks": {
        "scar": "thin pale scar along the left jawline",
        "freckles": "faint freckles across the nose and cheeks"
      },
      "body": "tall, athletic hourglass figure, long legs, toned arms and stomach, adult proportions"
    },
    "outfit": {
      "top": "opaque glossy teal-black latex cropped racing top with a high mandarin collar and short sleeves, fungus blue-green trim at collar, cuffs and hem, small blank patches with unreadable symbols, ending above the navel",
      "midriff": "bare toned midriff between top and shorts",
      "jacket": "cropped jacket of transparent smoky olive latex worn over the top, ending at the ribs, high stand-up collar, puffed shoulders, sleeves pushed to the elbow, chunky cargo pockets, heavily coated in grey dust",
      "bottoms": "opaque glossy teal-black latex high-waist hot pants",
      "skirt": "transparent smoky olive latex wrap mini skirt over the hot pants, open at one side",
      "belt": "beige plastic utility belt with a chunky clip buckle, small pouches and a holster for a cassette recorder",
      "wrist_unit": "chunky beige wrist computer with a small green phosphor LCD, rubber buttons and a coiled cable",
      "legwear": "sheer black fishnet tights under glossy black latex knee-high socks with a single blue-green stripe at the top",
      "footwear": "chunky platform boots with beige plastic shin guards, scuffed",
      "accessories": "cross-body satchel with a reinforced beige plastic flap"
    },
    "props": {
      "recorder": "palm-sized microcassette voice recorder with a visible tape window, a red record light and a coiled cable, in the belt holster"
    }
  },
  "pose": {
    "camera": "full front view, slightly low angle",
    "action": "slow catwalk step forward, one platform boot crossing in front of the other, hips swaying, one hand on her hip, the other hanging loose, chin down, head tilted as if listening to an echo",
    "expression": "looking at the viewer from under her lashes, a smoldering mocking half-smile",
    "allure": "seduction as a challenge: she knows the room is staring and lets it. Tasteful and SFW, adult woman"
  },
  "composition": {
    "framing": "knee-up shot, centered, vertical 4:5",
    "background": "plain neutral flat background, muted grey-beige, no scenery",
    "lighting": "cold flat white overhead light, hard cel shadows, a few dust motes drifting off her jacket"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, schoolgirl, school uniform, pleated skirt, sailor collar, nudity, nsfw, explicit, nipples, see-through top, exposed chest, visible underwear, lingerie, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, smartphone, touchscreen, sleek modern technology, holographic UI, minimalist design, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, red bodysuit, hair clips, beret, cross necklace, yellow vest, headband, detailed background, scenery, environment, room, furniture, landscape, lewd gesture, crotch focus, upskirt, spread legs facing camera, wardrobe malfunction"
}
```

---

## 2 · Kül ve hendek (§5 Zone 6'ya yürüyüş)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels over painted backgrounds, retro-futuristic anime screencap",
    "design_language": "cassette futurism: chunky beige and ash-grey plastic hardware, analog dials, toggle switches, rubber buttons, coiled cables, magnetic tape, green phosphor CRT and LCD readouts",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers over opaque latex, bare midriff, high collars, knee-high socks, chunky platform boots",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted white specular streaks on hair, glossy latex and transparent materials",
    "color": "faded analog colors, deep teal-black latex, smoky olive transparent latex, beige plastic hardware, fungus blue-green accents, green phosphor glow, green-tinted red hair, deep red lips",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "eerie and quiet, she leads and expects to be followed"
  },
  "character": {
    "name": "Ece",
    "identity": {
      "age": "adult woman, 35 years old, clearly mature",
      "face": {
        "shape": "elegant mature 80s OVA anime face of a cool adult scientist, sharp striking features, defined cheekbones, narrow chin",
        "eyes": "narrow half-lidded green-hazel eyes with thin dark lashes and painted catchlights, cool appraising gaze, faint fine lines at the outer corners",
        "lips": "deep red lipstick, small knowing smirk",
        "default_expression": "cool, dry and guarded, looking down slightly at the viewer"
      },
      "hair": {
        "color": "long red hair with a green tint: deep crimson red that shifts toward olive green in the shadows",
        "style": "long loose wavy hair reaching mid-back, side-parted, a few strands framing the face, slightly messy, no blunt bangs",
        "highlights": "painted glossy highlight bands with a green sheen"
      },
      "marks": {
        "scar": "thin pale scar along the left jawline",
        "freckles": "faint freckles across the nose and cheeks"
      },
      "body": "tall, athletic hourglass figure, long legs, toned arms and stomach, adult proportions"
    },
    "outfit": {
      "top": "opaque glossy teal-black latex cropped racing top with a high mandarin collar and short sleeves, fungus blue-green trim at collar, cuffs and hem, small blank patches with unreadable symbols, ending above the navel",
      "midriff": "bare toned midriff between top and shorts",
      "jacket": "cropped jacket of transparent smoky olive latex worn over the top, ending at the ribs, high stand-up collar, puffed shoulders, sleeves pushed to the elbow, chunky cargo pockets, light dust",
      "bottoms": "opaque glossy teal-black latex high-waist hot pants",
      "skirt": "transparent smoky olive latex wrap mini skirt over the hot pants, open at one side",
      "belt": "beige plastic utility belt with a chunky clip buckle, small pouches and a holster for a cassette recorder",
      "wrist_unit": "chunky beige wrist computer with a small green phosphor LCD, rubber buttons and a coiled cable",
      "legwear": "sheer black fishnet tights under glossy black latex knee-high socks with a single blue-green stripe at the top",
      "footwear": "chunky platform boots with beige plastic shin guards, scuffed",
      "accessories": "cross-body satchel with a reinforced beige plastic flap"
    },
    "props": {
      "recorder": "palm-sized microcassette voice recorder with a visible tape window, a red record light and a coiled cable, held up to her lips, red light on"
    }
  },
  "pose": {
    "camera": "three-quarter view from behind and slightly to the side, eye-level, as if following her",
    "action": "walking away with a slow swaying stride, glancing back over her shoulder, recorder held lightly against her lower lip, hair swinging across her back, a little grey dust trailing behind her boots",
    "expression": "an inviting half-lidded look back at the viewer, the corner of her mouth lifted",
    "allure": "seduction as a dare: follow me, if you can keep up. Tasteful and SFW, adult woman"
  },
  "composition": {
    "framing": "full body, vertical 4:5, figure in the left third",
    "background": "plain neutral flat background, muted grey-beige, no scenery",
    "lighting": "flat diffuse grey daylight with no clear direction, soft cel shadows"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, schoolgirl, school uniform, pleated skirt, sailor collar, nudity, nsfw, explicit, nipples, see-through top, exposed chest, visible underwear, lingerie, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, smartphone, touchscreen, sleek modern technology, holographic UI, minimalist design, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, red bodysuit, hair clips, beret, cross necklace, yellow vest, headband, detailed background, scenery, environment, room, furniture, landscape, lewd gesture, crotch focus, upskirt, spread legs facing camera, wardrobe malfunction"
}
```

---

## 3 · Karanlıktaki yeşil (§5 Mantar ışığı)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels over painted backgrounds, retro-futuristic anime screencap",
    "design_language": "cassette futurism: chunky beige and ash-grey plastic hardware, analog dials, toggle switches, rubber buttons, coiled cables, magnetic tape, green phosphor CRT and LCD readouts",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers over opaque latex, bare midriff, high collars, knee-high socks, chunky platform boots",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted white specular streaks on hair, glossy latex and transparent materials",
    "color": "faded analog colors, deep teal-black latex, smoky olive transparent latex, beige plastic hardware, fungus blue-green accents, green phosphor glow, green-tinted red hair, deep red lips",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "intimate, quiet, caught being looked at, slow-burning tension"
  },
  "character": {
    "name": "Ece",
    "identity": {
      "age": "adult woman, 35 years old, clearly mature",
      "face": {
        "shape": "elegant mature 80s OVA anime face of a cool adult scientist, sharp striking features, defined cheekbones, narrow chin",
        "eyes": "narrow half-lidded green-hazel eyes with thin dark lashes and painted catchlights, cool appraising gaze, faint fine lines at the outer corners",
        "lips": "deep red lipstick, small knowing smirk",
        "default_expression": "cool, dry and guarded, looking down slightly at the viewer"
      },
      "hair": {
        "color": "long red hair with a green tint: deep crimson red that shifts toward olive green in the shadows",
        "style": "long loose wavy hair reaching mid-back, side-parted, a few strands framing the face, slightly messy, no blunt bangs",
        "highlights": "painted glossy highlight bands with a green sheen"
      },
      "marks": {
        "scar": "thin pale scar along the left jawline, clearly visible in this light",
        "freckles": "freckles across the nose and cheeks, clearly visible in this light"
      },
      "body": "tall, athletic hourglass figure, long legs, toned arms and stomach, adult proportions"
    },
    "outfit": {
      "top": "opaque glossy teal-black latex cropped racing top with a high mandarin collar and short sleeves, fungus blue-green trim at collar, cuffs and hem, small blank patches with unreadable symbols, ending above the navel",
      "midriff": "bare toned midriff between top and shorts",
      "jacket": "cropped jacket of transparent smoky olive latex worn over the top, ending at the ribs, high stand-up collar, puffed shoulders, sleeves pushed to the elbow, chunky cargo pockets, light dust, slipped off one shoulder",
      "bottoms": "opaque glossy teal-black latex high-waist hot pants",
      "skirt": "transparent smoky olive latex wrap mini skirt over the hot pants, open at one side",
      "belt": "beige plastic utility belt with a chunky clip buckle, small pouches and a holster for a cassette recorder",
      "wrist_unit": "chunky beige wrist computer with a small green phosphor LCD, rubber buttons and a coiled cable",
      "legwear": "sheer black fishnet tights under glossy black latex knee-high socks with a single blue-green stripe at the top"
    },
    "props": {
      "light_stick": "short organic stick held low in both hands, glowing soft blue-green like fungus on wet bark, the only light source",
      "wrist_unit_state": "wrist computer screen dark and dead"
    }
  },
  "pose": {
    "camera": "close medium shot, eye-level, slightly to the side",
    "action": "sitting on the floor leaning back on one elbow, legs folded together to one side, upper body turned toward the viewer, the glowing stick held close under her chin, jacket sliding off one shoulder",
    "expression": "holding the viewer's eyes and not looking away, lips slightly parted, a flustered blush that shows as a dark shadow under her skin in the green light",
    "allure": "seduction as vulnerability: embarrassed, but choosing to stay close. Tasteful and SFW, adult woman"
  },
  "composition": {
    "framing": "waist-up, vertical 4:5, face in the upper third",
    "background": "plain neutral flat background, muted grey-beige, no scenery",
    "lighting": "single soft blue-green light from the stick below her face, transparent latex glowing faintly green, deep shadows on the upper half of her face"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, schoolgirl, school uniform, pleated skirt, sailor collar, nudity, nsfw, explicit, nipples, see-through top, exposed chest, visible underwear, lingerie, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, smartphone, touchscreen, sleek modern technology, holographic UI, minimalist design, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, red bodysuit, hair clips, beret, cross necklace, yellow vest, headband, detailed background, scenery, environment, room, furniture, landscape, lewd gesture, crotch focus, upskirt, spread legs facing camera, wardrobe malfunction, pink blush, warm light"
}
```

---

## 4 · Kırağı yazı (§6 Laboratuvar)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels over painted backgrounds, retro-futuristic anime screencap",
    "design_language": "cassette futurism: chunky beige and ash-grey plastic hardware, analog dials, toggle switches, rubber buttons, coiled cables, magnetic tape, green phosphor CRT and LCD readouts",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers over opaque latex, bare midriff, high collars, knee-high socks, chunky platform boots",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted white specular streaks on hair, glossy latex and transparent materials",
    "color": "faded analog colors, deep teal-black latex, smoky olive transparent latex, beige plastic hardware, fungus blue-green accents, green phosphor glow, green-tinted red hair, deep red lips",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "tired, obsessive, quiet wonder with a private warmth"
  },
  "character": {
    "name": "Ece",
    "identity": {
      "age": "adult woman, 35 years old, clearly mature",
      "face": {
        "shape": "elegant mature 80s OVA anime face of a cool adult scientist, sharp striking features, defined cheekbones, narrow chin",
        "eyes": "narrow half-lidded green-hazel eyes with thin dark lashes and painted catchlights, cool appraising gaze, faint fine lines at the outer corners",
        "lips": "deep red lipstick, small knowing smirk",
        "default_expression": "cool, dry and guarded, looking down slightly at the viewer"
      },
      "hair": {
        "color": "long red hair with a green tint: deep crimson red that shifts toward olive green in the shadows",
        "style": "long wavy hair pinned up loosely with a pen, strands falling out around the face",
        "highlights": "painted glossy highlight bands with a green sheen"
      },
      "marks": {
        "scar": "thin pale scar along the left jawline",
        "freckles": "faint freckles across the nose and cheeks"
      },
      "body": "tall, athletic hourglass figure, long legs, toned arms and stomach, adult proportions"
    },
    "outfit": {
      "base_layer": "opaque glossy teal-black latex sleeveless halter bodysuit with a high neck, cut-in shoulders, high-cut legs and a plain vertical front zipper, thin fungus blue-green seam lines",
      "coat": "long open lab coat of frosted transparent white latex reaching the shins, sleeves pushed up to the elbows, collar turned up, beige plastic pocket clips, a pen-light in the breast pocket",
      "skirt": "high-waist black latex pencil mini skirt ending mid-thigh, wide black belt with a chunky beige plastic buckle",
      "wrist_unit": "chunky beige wrist computer with a small green phosphor LCD, rubber buttons and a coiled cable",
      "legwear": "glossy black latex knee-high socks with a single blue-green stripe at the top",
      "footwear": "no shoes, standing in socks"
    },
    "props": {
      "disk": "palm-sized seamless grey disk, two lines of thin pale green alien script rising across its face like frost on glass",
      "blanket": "rumpled blanket draped over one shoulder",
      "camera": "chunky retro instant camera raised in one hand"
    }
  },
  "pose": {
    "camera": "three-quarter view, slightly high angle",
    "action": "leaning forward with her back gently arched, holding the glowing disk up in one palm near her face, camera lowered in the other hand, blanket slipping off one shoulder, loose strands falling from the pinned-up hair",
    "expression": "looking over the top of the disk at the viewer with soft half-lidded eyes, lips slightly parted",
    "allure": "seduction as intimacy: the late-night lab, only the two of you awake. Tasteful and SFW, adult woman"
  },
  "composition": {
    "framing": "thigh-up, vertical 4:5",
    "background": "plain neutral flat background, muted grey-beige, no scenery",
    "lighting": "lit only by the pale green glow of the disk from below, on her face, the latex and the frosted coat"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, schoolgirl, school uniform, pleated skirt, sailor collar, nudity, nsfw, explicit, nipples, see-through top, exposed chest, visible underwear, lingerie, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, smartphone, touchscreen, sleek modern technology, holographic UI, minimalist design, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, red bodysuit, hair clips, beret, cross necklace, yellow vest, headband, detailed background, scenery, environment, room, furniture, landscape, lewd gesture, crotch focus, upskirt, spread legs facing camera, wardrobe malfunction"
}
```

---

## 5 · Pencere (§6 Ay'a bakış)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels over painted backgrounds, retro-futuristic anime screencap",
    "design_language": "cassette futurism: chunky beige and ash-grey plastic hardware, analog dials, toggle switches, rubber buttons, coiled cables, magnetic tape, green phosphor CRT and LCD readouts",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers over opaque latex, bare midriff, high collars, knee-high socks, chunky platform boots",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted white specular streaks on hair, glossy latex and transparent materials",
    "color": "faded analog colors, deep teal-black latex, smoky olive transparent latex, beige plastic hardware, fungus blue-green accents, green phosphor glow, green-tinted red hair, deep red lips",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "restless, hidden fear, longing"
  },
  "character": {
    "name": "Ece",
    "identity": {
      "age": "adult woman, 35 years old, clearly mature",
      "face": {
        "shape": "elegant mature 80s OVA anime face of a cool adult scientist, sharp striking features, defined cheekbones, narrow chin",
        "eyes": "narrow half-lidded green-hazel eyes with thin dark lashes and painted catchlights, cool appraising gaze, faint fine lines at the outer corners",
        "lips": "deep red lipstick, small knowing smirk",
        "default_expression": "cool, dry and guarded, looking down slightly at the viewer"
      },
      "hair": {
        "color": "long red hair with a green tint: deep crimson red that shifts toward olive green in the shadows",
        "style": "long loose wavy hair reaching mid-back, side-parted, a few strands framing the face, slightly messy, no blunt bangs",
        "highlights": "painted glossy highlight bands with a green sheen"
      },
      "marks": {
        "scar": "thin pale scar along the left jawline",
        "freckles": "faint freckles across the nose and cheeks"
      },
      "body": "tall, athletic hourglass figure, long legs, toned arms and stomach, adult proportions"
    },
    "outfit": {
      "base_layer": "opaque glossy teal-black latex sleeveless halter bodysuit with a high neck, cut-in shoulders, high-cut legs and a plain vertical front zipper, thin fungus blue-green seam lines",
      "skirt": "high-waist black latex pencil mini skirt ending mid-thigh, wide black belt with a chunky beige plastic buckle",
      "wrist_unit": "chunky beige wrist computer with a small green phosphor LCD, rubber buttons and a coiled cable",
      "legwear": "glossy black latex knee-high socks with a single blue-green stripe at the top",
      "footwear": "standing in socks"
    },
    "props": {}
  },
  "pose": {
    "camera": "three-quarter rear view, eye-level",
    "action": "three-quarter turned away, back softly arched, one hand lifting her hair off the nape of her neck, the other arm wrapped around her waist, weight on one leg",
    "expression": "looking back over her shoulder, eyes lowered, lips pressed together then parting",
    "allure": "seduction as longing: she wants to be held but will not ask. Tasteful and SFW, adult woman"
  },
  "composition": {
    "framing": "full body, vertical 4:5, centered",
    "background": "plain neutral flat background, muted grey-beige, no scenery",
    "lighting": "cool pale rim light on hair and latex from above, soft front fill"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, schoolgirl, school uniform, pleated skirt, sailor collar, nudity, nsfw, explicit, nipples, see-through top, exposed chest, visible underwear, lingerie, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, smartphone, touchscreen, sleek modern technology, holographic UI, minimalist design, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, red bodysuit, hair clips, beret, cross necklace, yellow vest, headband, detailed background, scenery, environment, room, furniture, landscape, lewd gesture, crotch focus, upskirt, spread legs facing camera, wardrobe malfunction"
}
```

---

## 6 · Ay giysisi (Act II iniş)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels over painted backgrounds, retro-futuristic anime screencap",
    "design_language": "cassette futurism: chunky beige and ash-grey plastic hardware, analog dials, toggle switches, rubber buttons, coiled cables, magnetic tape, green phosphor CRT and LCD readouts",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers over opaque latex, bare midriff, high collars, knee-high socks, chunky platform boots",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted white specular streaks on hair, glossy latex and transparent materials",
    "color": "faded analog colors, deep teal-black latex, smoky olive transparent latex, beige plastic hardware, fungus blue-green accents, green phosphor glow, green-tinted red hair, deep red lips",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "bold, sleek, slightly uneasy, showing off"
  },
  "character": {
    "name": "Ece",
    "identity": {
      "age": "adult woman, 35 years old, clearly mature",
      "face": {
        "shape": "elegant mature 80s OVA anime face of a cool adult scientist, sharp striking features, defined cheekbones, narrow chin",
        "eyes": "narrow half-lidded green-hazel eyes with thin dark lashes and painted catchlights, cool appraising gaze, faint fine lines at the outer corners",
        "lips": "deep red lipstick, small knowing smirk",
        "default_expression": "cool, dry and guarded, looking down slightly at the viewer"
      },
      "hair": {
        "color": "long red hair with a green tint: deep crimson red that shifts toward olive green in the shadows",
        "style": "long wavy hair tucked inside the helmet, a few strands against her cheek",
        "highlights": "painted glossy highlight bands with a green sheen"
      },
      "marks": {
        "scar": "thin pale scar along the left jawline",
        "freckles": "faint freckles across the nose and cheeks"
      },
      "body": "tall, athletic hourglass figure, long legs, toned arms and stomach, adult proportions"
    },
    "outfit": {
      "base_layer": "opaque glossy teal-black latex full-body pressure suit, high collar ring, plugsuit-inspired panel lines, thin fungus blue-green seam lines",
      "pressure_shell": "clip-on hard shell pieces in beige and ash-grey plastic over the suit: chest plate with analog dials and toggle switches, forearm guards",
      "jacket": "short cropped bolero of transparent smoky olive latex over the shoulders and chest plate, high stand-up collar",
      "hips": "short layered tasset panels of transparent smoky olive latex at the hips like a mini skirt",
      "legwear": "thigh-high glossy black latex platform pressure boots with beige plastic knee caps",
      "life_support": "compact beige life-support backpack with a coiled hose to the collar ring",
      "helmet": "clear round bubble helmet sealed to the collar ring with chunky clamps, a small green phosphor readout inside the rim",
      "wrist_unit": "chunky beige wrist computer with a small green phosphor LCD, rubber buttons and a coiled cable"
    },
    "props": {
      "recorder": "palm-sized microcassette voice recorder with a visible tape window, a red record light and a coiled cable, clipped to the chest plate"
    }
  },
  "pose": {
    "camera": "full front view, low angle",
    "action": "weight on one leg, hip popped, back slightly arched, one hand on her hip, a gloved fingertip slowly tracing the helmet seal",
    "expression": "a cool confident smirk hiding nerves, chin raised, eyes on the viewer",
    "allure": "seduction as bravado: if she is scared, she will look good being scared. Tasteful and SFW, adult woman"
  },
  "composition": {
    "framing": "full body, vertical 4:5, centered",
    "background": "plain neutral flat background, muted grey-beige, no scenery",
    "lighting": "hard white light from one side, strong cel shadows, bright reflections on the helmet and latex"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, schoolgirl, school uniform, pleated skirt, sailor collar, nudity, nsfw, explicit, nipples, see-through top, exposed chest, visible underwear, lingerie, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, smartphone, touchscreen, sleek modern technology, holographic UI, minimalist design, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, red bodysuit, hair clips, beret, cross necklace, yellow vest, headband, detailed background, scenery, environment, room, furniture, landscape, lewd gesture, crotch focus, upskirt, spread legs facing camera, wardrobe malfunction, bulky NASA spacesuit"
}
```

---

## 7 · Nefes (Act II, Burkai'den sonra)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels over painted backgrounds, retro-futuristic anime screencap",
    "design_language": "cassette futurism: chunky beige and ash-grey plastic hardware, analog dials, toggle switches, rubber buttons, coiled cables, magnetic tape, green phosphor CRT and LCD readouts",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers over opaque latex, bare midriff, high collars, knee-high socks, chunky platform boots",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted white specular streaks on hair, glossy latex and transparent materials",
    "color": "faded analog colors, deep teal-black latex, smoky olive transparent latex, beige plastic hardware, fungus blue-green accents, green phosphor glow, green-tinted red hair, deep red lips",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "impossible, breathless, awe"
  },
  "character": {
    "name": "Ece",
    "identity": {
      "age": "adult woman, 35 years old, clearly mature",
      "face": {
        "shape": "elegant mature 80s OVA anime face of a cool adult scientist, sharp striking features, defined cheekbones, narrow chin",
        "eyes": "narrow half-lidded green-hazel eyes with thin dark lashes and painted catchlights, cool appraising gaze, faint fine lines at the outer corners",
        "lips": "deep red lipstick, small knowing smirk",
        "default_expression": "cool, dry and guarded, looking down slightly at the viewer"
      },
      "hair": {
        "color": "long red hair with a green tint: deep crimson red that shifts toward olive green in the shadows",
        "style": "long loose wavy hair drifting upward and outward in low gravity",
        "highlights": "painted glossy highlight bands with a green sheen"
      },
      "marks": {
        "scar": "thin pale scar along the left jawline",
        "freckles": "faint freckles across the nose and cheeks"
      },
      "body": "tall, athletic hourglass figure, long legs, toned arms and stomach, adult proportions"
    },
    "outfit": {
      "base_layer": "opaque glossy teal-black latex full-body pressure suit, high collar ring, plugsuit-inspired panel lines, thin fungus blue-green seam lines",
      "pressure_shell": "clip-on hard shell pieces in beige and ash-grey plastic over the suit: chest plate with analog dials and toggle switches, forearm guards",
      "jacket": "short cropped bolero of transparent smoky olive latex over the shoulders and chest plate, high stand-up collar",
      "hips": "short layered tasset panels of transparent smoky olive latex at the hips like a mini skirt",
      "legwear": "thigh-high glossy black latex platform pressure boots with beige plastic knee caps",
      "life_support": "compact beige life-support backpack with a coiled hose to the collar ring",
      "helmet": "none, open collar ring where the helmet was",
      "wrist_unit": "chunky beige wrist computer with a small green phosphor LCD, rubber buttons and a coiled cable"
    },
    "props": {
      "helmet": "clear bubble helmet drifting slowly away beside her"
    }
  },
  "pose": {
    "camera": "medium close-up, slightly low angle",
    "action": "head tilted back, one hand at her throat sliding down to her collarbone, the other arm loose and half raised, chest rising in a deep first breath, hair drifting around her face",
    "expression": "eyes half closed, lips parted, astonishment melting into relief",
    "allure": "seduction as release: the first full breath after holding it for too long. Tasteful and SFW, adult woman"
  },
  "composition": {
    "framing": "chest-up, vertical 4:5",
    "background": "plain neutral flat background, muted grey-beige, no scenery",
    "lighting": "hard white side light, glossy reflections along the latex collar and hair"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, schoolgirl, school uniform, pleated skirt, sailor collar, nudity, nsfw, explicit, nipples, see-through top, exposed chest, visible underwear, lingerie, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, smartphone, touchscreen, sleek modern technology, holographic UI, minimalist design, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, red bodysuit, hair clips, beret, cross necklace, yellow vest, headband, detailed background, scenery, environment, room, furniture, landscape, lewd gesture, crotch focus, upskirt, spread legs facing camera, wardrobe malfunction"
}
```

---

## 8 · İfade sayfası

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime official character expression sheet, hand-painted cels",
    "design_language": "cassette futurism: chunky beige and ash-grey plastic hardware, analog dials, toggle switches, rubber buttons, coiled cables, magnetic tape, green phosphor CRT and LCD readouts",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers over opaque latex, bare midriff, high collars, knee-high socks, chunky platform boots",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted white specular streaks on hair, glossy latex and transparent materials",
    "color": "faded analog colors, deep teal-black latex, smoky olive transparent latex, beige plastic hardware, fungus blue-green accents, green phosphor glow, green-tinted red hair, deep red lips",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "character reference, mature and alluring"
  },
  "character": {
    "name": "Ece",
    "identity": {
      "age": "adult woman, 35 years old, clearly mature",
      "face": {
        "shape": "elegant mature 80s OVA anime face of a cool adult scientist, sharp striking features, defined cheekbones, narrow chin",
        "eyes": "narrow half-lidded green-hazel eyes with thin dark lashes and painted catchlights, cool appraising gaze, faint fine lines at the outer corners",
        "lips": "deep red lipstick, small knowing smirk",
        "default_expression": "cool, dry and guarded, looking down slightly at the viewer"
      },
      "hair": {
        "color": "long red hair with a green tint: deep crimson red that shifts toward olive green in the shadows",
        "style": "long loose wavy hair reaching mid-back, side-parted, a few strands framing the face, slightly messy, no blunt bangs",
        "highlights": "painted glossy highlight bands with a green sheen"
      },
      "marks": {
        "scar": "thin pale scar along the left jawline",
        "freckles": "faint freckles across the nose and cheeks"
      },
      "body": "tall, athletic hourglass figure, long legs, toned arms and stomach, adult proportions"
    },
    "outfit": {
      "top": "high mandarin collar of an opaque glossy teal-black latex racing top with blue-green trim",
      "jacket": "high stand-up collar of a transparent smoky olive latex cropped jacket"
    },
    "props": {}
  },
  "pose": {
    "camera": "head-and-shoulders portraits, front and three-quarter views",
    "action": "nine expressions in a 3x3 grid",
    "expression": "1 cool default with heavy-lidded eyes, 2 mocking sultry half-smile, 3 hard unyielding stare, 4 caught off guard blinking, 5 short closed-mouth laugh turning away, 6 peaceful eyes half closed head tilted listening, 7 flustered blush with parted lips, 8 afraid, 9 cold and emotionless; every expression with a mature, alluring edge",
    "allure": "allure lives in the eyes and lips, never in a cute or girlish read. Tasteful and SFW, adult woman"
  },
  "composition": {
    "framing": "3x3 grid of head-and-shoulder portraits, square 1:1, same scale and same face in every cell",
    "background": "plain neutral flat background, muted grey-beige, no scenery",
    "lighting": "soft flat frontal light, subtle cel shadows"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, schoolgirl, school uniform, pleated skirt, sailor collar, nudity, nsfw, explicit, nipples, see-through top, exposed chest, visible underwear, lingerie, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, smartphone, touchscreen, sleek modern technology, holographic UI, minimalist design, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, red bodysuit, hair clips, beret, cross necklace, yellow vest, headband, detailed background, scenery, environment, room, furniture, landscape, lewd gesture, crotch focus, upskirt, spread legs facing camera, wardrobe malfunction, labels, different faces"
}
```

---

## 9 · Laboratuvar portresi (Ritsuko referansının duruşu)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime official character art, standing pose, hand-painted cels",
    "design_language": "cassette futurism: chunky beige and ash-grey plastic hardware, analog dials, toggle switches, rubber buttons, coiled cables, magnetic tape, green phosphor CRT and LCD readouts",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers over opaque latex, bare midriff, high collars, knee-high socks, chunky platform boots",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted white specular streaks on hair, glossy latex and transparent materials",
    "color": "faded analog colors, deep teal-black latex, smoky olive transparent latex, beige plastic hardware, fungus blue-green accents, green phosphor glow, green-tinted red hair, deep red lips",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "cool, confident, seductive adult scientist"
  },
  "character": {
    "name": "Ece",
    "identity": {
      "age": "adult woman, 35 years old, clearly mature",
      "face": {
        "shape": "elegant mature 80s OVA anime face of a cool adult scientist, sharp striking features, defined cheekbones, narrow chin",
        "eyes": "narrow half-lidded green-hazel eyes with thin dark lashes and painted catchlights, cool appraising gaze, faint fine lines at the outer corners",
        "lips": "deep red lipstick, small knowing smirk",
        "default_expression": "cool, dry and guarded, looking down slightly at the viewer"
      },
      "hair": {
        "color": "long red hair with a green tint: deep crimson red that shifts toward olive green in the shadows",
        "style": "long loose wavy hair reaching mid-back, side-parted, a few strands framing the face, slightly messy, no blunt bangs",
        "highlights": "painted glossy highlight bands with a green sheen"
      },
      "marks": {
        "scar": "thin pale scar along the left jawline",
        "freckles": "faint freckles across the nose and cheeks"
      },
      "body": "tall, athletic hourglass figure, long legs, toned arms and stomach, adult proportions"
    },
    "outfit": {
      "base_layer": "opaque glossy teal-black latex sleeveless halter bodysuit with a high neck, cut-in shoulders, high-cut legs and a plain vertical front zipper, thin fungus blue-green seam lines",
      "coat": "long open lab coat of frosted transparent white latex reaching the shins, sleeves pushed up to the elbows, collar turned up, beige plastic pocket clips, a pen-light in the breast pocket",
      "skirt": "high-waist black latex pencil mini skirt ending mid-thigh, wide black belt with a chunky beige plastic buckle",
      "wrist_unit": "chunky beige wrist computer with a small green phosphor LCD, rubber buttons and a coiled cable",
      "legwear": "glossy black latex knee-high socks with a single blue-green stripe at the top",
      "footwear": "black platform heels"
    },
    "props": {
      "recorder": "palm-sized microcassette voice recorder with a visible tape window, a red record light and a coiled cable, clipped to the coat breast pocket"
    }
  },
  "pose": {
    "camera": "three-quarter front view, eye-level, slightly below her face",
    "action": "standing with her back gently arched, one hand on her hip pushing the coat open, the other hand running slowly through her hair, one shoulder turned forward, head tilted to the side",
    "expression": "a sultry half-lidded gaze down at the viewer, faint smirk",
    "allure": "seduction as authority: she knows exactly how she looks and is grading you on it. Tasteful and SFW, adult woman"
  },
  "composition": {
    "framing": "knee-up, vertical 1:2, figure filling the frame",
    "background": "plain neutral flat background, muted grey-beige, no scenery",
    "lighting": "soft flat frontal light, subtle cel shadows"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, schoolgirl, school uniform, pleated skirt, sailor collar, nudity, nsfw, explicit, nipples, see-through top, exposed chest, visible underwear, lingerie, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, smartphone, touchscreen, sleek modern technology, holographic UI, minimalist design, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, red bodysuit, hair clips, beret, cross necklace, yellow vest, headband, detailed background, scenery, environment, room, furniture, landscape, lewd gesture, crotch focus, upskirt, spread legs facing camera, wardrobe malfunction, blonde hair, short bob haircut, beauty mark under the eye, ring zipper pull, earrings, blue turtleneck"
}
```

---

## 10 · A-pose (karakter referansı)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime official character model sheet, hand-painted cels, retro-futuristic anime",
    "design_language": "cassette futurism: chunky beige and ash-grey plastic hardware, analog dials, toggle switches, rubber buttons, coiled cables, magnetic tape, green phosphor CRT and LCD readouts",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers over opaque latex, bare midriff, high collars, knee-high socks, chunky platform boots",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted white specular streaks on hair, glossy latex and transparent materials",
    "color": "faded analog colors, deep teal-black latex, smoky olive transparent latex, beige plastic hardware, fungus blue-green accents, green phosphor glow, green-tinted red hair, deep red lips",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "neutral character reference with quiet confidence"
  },
  "character": {
    "name": "Ece",
    "identity": {
      "age": "adult woman, 35 years old, clearly mature",
      "face": {
        "shape": "elegant mature 80s OVA anime face of a cool adult scientist, sharp striking features, defined cheekbones, narrow chin",
        "eyes": "narrow half-lidded green-hazel eyes with thin dark lashes and painted catchlights, cool appraising gaze, faint fine lines at the outer corners",
        "lips": "deep red lipstick, mouth closed and relaxed",
        "default_expression": "neutral and calm"
      },
      "hair": {
        "color": "long red hair with a green tint: deep crimson red that shifts toward olive green in the shadows",
        "style": "long loose wavy hair reaching mid-back, side-parted, a few strands framing the face, slightly messy, no blunt bangs",
        "highlights": "painted glossy highlight bands with a green sheen"
      },
      "marks": {
        "scar": "thin pale scar along the left jawline",
        "freckles": "faint freckles across the nose and cheeks"
      },
      "body": "tall, athletic hourglass figure, long legs, toned arms and stomach, adult proportions"
    },
    "outfit": {
      "top": "opaque glossy teal-black latex cropped racing top with a high mandarin collar and short sleeves, fungus blue-green trim at collar, cuffs and hem, small blank patches with unreadable symbols, ending above the navel",
      "midriff": "bare toned midriff between top and shorts",
      "jacket": "cropped jacket of transparent smoky olive latex worn over the top, ending at the ribs, high stand-up collar, puffed shoulders, sleeves pushed to the elbow, chunky cargo pockets, light dust",
      "bottoms": "opaque glossy teal-black latex high-waist hot pants",
      "skirt": "transparent smoky olive latex wrap mini skirt over the hot pants, open at one side",
      "belt": "beige plastic utility belt with a chunky clip buckle, small pouches and a holster for a cassette recorder",
      "wrist_unit": "chunky beige wrist computer with a small green phosphor LCD, rubber buttons and a coiled cable",
      "legwear": "sheer black fishnet tights under glossy black latex knee-high socks with a single blue-green stripe at the top",
      "footwear": "chunky platform boots with beige plastic shin guards, scuffed",
      "accessories": "cross-body satchel with a reinforced beige plastic flap"
    },
    "props": {
      "recorder": "palm-sized microcassette voice recorder with a visible tape window, a red record light and a coiled cable, in the belt holster"
    }
  },
  "pose": {
    "camera": "straight front view, eye-level at chest height, orthographic feel, no perspective distortion",
    "action": "symmetrical A-pose: standing straight, feet shoulder-width apart and flat on the ground, arms straight and angled about 45 degrees down and away from the body, palms facing inward, fingers relaxed and slightly apart, head facing forward",
    "expression": "calm and confident, heavy-lidded eyes, a faint closed-lip half-smile, eyes straight ahead",
    "allure": "allure only in the face and posture: shoulders back, chest open, chin level; the body stays in a strict symmetrical A-pose. Tasteful and SFW, adult woman"
  },
  "composition": {
    "framing": "full body from head to toe with a small margin, centered, vertical 9:16",
    "background": "plain neutral flat background, muted grey-beige, no scenery",
    "lighting": "even flat frontal light, minimal cel shadows, no dramatic lighting"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, schoolgirl, school uniform, pleated skirt, sailor collar, nudity, nsfw, explicit, nipples, see-through top, exposed chest, visible underwear, lingerie, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, smartphone, touchscreen, sleek modern technology, holographic UI, minimalist design, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, red bodysuit, hair clips, beret, cross necklace, yellow vest, headband, detailed background, scenery, environment, room, furniture, landscape, lewd gesture, crotch focus, upskirt, spread legs facing camera, wardrobe malfunction, dynamic pose, T-pose, crossed arms, hands on hips, tilted head, cropped limbs, cropped feet, perspective distortion, props in hands"
}
```

---

## 11 · Saha duruşu (alçak hamle)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels over painted backgrounds, retro-futuristic anime screencap",
    "design_language": "cassette futurism: chunky beige and ash-grey plastic hardware, analog dials, toggle switches, rubber buttons, coiled cables, magnetic tape, green phosphor CRT and LCD readouts",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers over opaque latex, bare midriff, high collars, knee-high socks, chunky platform boots",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted white specular streaks on hair, glossy latex and transparent materials",
    "color": "faded analog colors, deep teal-black latex, smoky olive transparent latex, beige plastic hardware, fungus blue-green accents, green phosphor glow, green-tinted red hair, deep red lips",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "fierce, ready, dangerous and seductive"
  },
  "character": {
    "name": "Ece",
    "identity": {
      "age": "adult woman, 35 years old, clearly mature",
      "face": {
        "shape": "elegant mature 80s OVA anime face of a cool adult scientist, sharp striking features, defined cheekbones, narrow chin",
        "eyes": "narrow half-lidded green-hazel eyes with thin dark lashes and painted catchlights, cool appraising gaze, faint fine lines at the outer corners",
        "lips": "deep red lipstick, small knowing smirk",
        "default_expression": "cool, dry and guarded, looking down slightly at the viewer"
      },
      "hair": {
        "color": "long red hair with a green tint: deep crimson red that shifts toward olive green in the shadows",
        "style": "long loose wavy hair reaching mid-back, side-parted, a few strands framing the face, slightly messy, no blunt bangs",
        "highlights": "painted glossy highlight bands with a green sheen"
      },
      "marks": {
        "scar": "thin pale scar along the left jawline",
        "freckles": "faint freckles across the nose and cheeks"
      },
      "body": "tall, athletic hourglass figure, long legs, toned arms and stomach, adult proportions"
    },
    "outfit": {
      "top": "opaque glossy teal-black latex cropped racing top with a high mandarin collar and short sleeves, fungus blue-green trim at collar, cuffs and hem, small blank patches with unreadable symbols, ending above the navel",
      "midriff": "bare toned midriff between top and shorts",
      "jacket": "cropped jacket of transparent smoky olive latex worn over the top, ending at the ribs, high stand-up collar, puffed shoulders, sleeves pushed to the elbow, chunky cargo pockets, light dust",
      "bottoms": "opaque glossy teal-black latex high-waist hot pants",
      "skirt": "transparent smoky olive latex wrap mini skirt over the hot pants, open at one side",
      "belt": "beige plastic utility belt with a chunky clip buckle, small pouches and a holster for a cassette recorder",
      "wrist_unit": "chunky beige wrist computer with a small green phosphor LCD, rubber buttons and a coiled cable",
      "legwear": "sheer black fishnet tights under glossy black latex knee-high socks with a single blue-green stripe at the top",
      "footwear": "chunky platform boots with beige plastic shin guards, scuffed"
    },
    "props": {
      "survey_rod": "long retro survey probe rod with a beige plastic grip, a small analog needle meter and a coiled cable, carried like a staff",
      "recorder": "palm-sized microcassette voice recorder with a visible tape window, a red record light and a coiled cable, in the belt holster"
    }
  },
  "pose": {
    "camera": "full front view, low camera at knee height",
    "action": "deep wide side lunge seen from the front-side: one knee down on the ground, the other leg stretched long to the side, back arched, rod held up over one shoulder in one hand, other hand resting on the extended thigh, hair falling over one shoulder",
    "expression": "intense sultry stare at the viewer from under her brows, lips slightly parted",
    "allure": "seduction as danger: graceful, strong, and completely sure of the next move. Tasteful and SFW, adult woman"
  },
  "composition": {
    "framing": "full body, square 1:1, figure spread across the frame",
    "background": "plain neutral flat background, muted grey-beige, no scenery",
    "lighting": "flat soft light, subtle cel shadows"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, schoolgirl, school uniform, pleated skirt, sailor collar, nudity, nsfw, explicit, nipples, see-through top, exposed chest, visible underwear, lingerie, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, smartphone, touchscreen, sleek modern technology, holographic UI, minimalist design, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, red bodysuit, hair clips, beret, cross necklace, yellow vest, headband, detailed background, scenery, environment, room, furniture, landscape, lewd gesture, crotch focus, upskirt, spread legs facing camera, wardrobe malfunction, sword, katana, weapon"
}
```

---

## 12 · Stüdyo duruşu (alt açı)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels over painted backgrounds, retro-futuristic anime screencap",
    "design_language": "cassette futurism: chunky beige and ash-grey plastic hardware, analog dials, toggle switches, rubber buttons, coiled cables, magnetic tape, green phosphor CRT and LCD readouts",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers over opaque latex, bare midriff, high collars, knee-high socks, chunky platform boots",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted white specular streaks on hair, glossy latex and transparent materials",
    "color": "faded analog colors, deep teal-black latex, smoky olive transparent latex, beige plastic hardware, fungus blue-green accents, green phosphor glow, green-tinted red hair, deep red lips",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "confident, statuesque, seductive fashion editorial"
  },
  "character": {
    "name": "Ece",
    "identity": {
      "age": "adult woman, 35 years old, clearly mature",
      "face": {
        "shape": "elegant mature 80s OVA anime face of a cool adult scientist, sharp striking features, defined cheekbones, narrow chin",
        "eyes": "narrow half-lidded green-hazel eyes with thin dark lashes and painted catchlights, cool appraising gaze, faint fine lines at the outer corners",
        "lips": "deep red lipstick, small knowing smirk",
        "default_expression": "cool, dry and guarded, looking down slightly at the viewer"
      },
      "hair": {
        "color": "long red hair with a green tint: deep crimson red that shifts toward olive green in the shadows",
        "style": "long loose wavy hair reaching mid-back, side-parted, a few strands framing the face, slightly messy, no blunt bangs",
        "highlights": "painted glossy highlight bands with a green sheen"
      },
      "marks": {
        "scar": "thin pale scar along the left jawline",
        "freckles": "faint freckles across the nose and cheeks"
      },
      "body": "tall, athletic hourglass figure, long legs, toned arms and stomach, adult proportions"
    },
    "outfit": {
      "base_layer": "opaque glossy teal-black latex sleeveless halter bodysuit with a high neck, cut-in shoulders, high-cut legs and a plain vertical front zipper, thin fungus blue-green seam lines",
      "jacket": "cropped jacket of transparent smoky olive latex ending at the ribs, high stand-up collar, puffed shoulders, sleeves pushed to the elbow",
      "wrist_unit": "chunky beige wrist computer with a small green phosphor LCD, rubber buttons and a coiled cable",
      "legwear": "glossy black latex knee-high socks with a single blue-green stripe at the top",
      "footwear": "chunky beige platform sneakers with plastic panels"
    },
    "props": {}
  },
  "pose": {
    "camera": "very low angle looking up, full front view",
    "action": "standing tall with feet wide apart, hips tilted strongly to one side, back arched, one hand resting on her hip, the other fingertips on her waist, head tilted, looking down at the camera",
    "expression": "cool, unbothered, heavy-lidded eyes, lips slightly parted",
    "allure": "seduction as power: the low angle makes her tower over the viewer. Tasteful and SFW, adult woman"
  },
  "composition": {
    "framing": "full body, vertical 4:5, long legs leading up to the face",
    "background": "plain neutral flat background, muted grey-beige, no scenery",
    "lighting": "soft even light, gentle cel shadows"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, schoolgirl, school uniform, pleated skirt, sailor collar, nudity, nsfw, explicit, nipples, see-through top, exposed chest, visible underwear, lingerie, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, smartphone, touchscreen, sleek modern technology, holographic UI, minimalist design, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, red bodysuit, hair clips, beret, cross necklace, yellow vest, headband, detailed background, scenery, environment, room, furniture, landscape, lewd gesture, crotch focus, upskirt, spread legs facing camera, wardrobe malfunction"
}
```

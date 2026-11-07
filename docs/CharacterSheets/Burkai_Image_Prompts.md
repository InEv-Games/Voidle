# Burkai — Görsel Promptları (v1)

7 Kasım 2026 · `Visual_Notes.md` ve `Burkai_voice_guide.md`'den, Ece'nin promptlarıyla aynı düzende.

**Nasıl kullanılır**
- Her blok tek başına çalışır: `style`, `character.identity` ve `negative_prompt` her blokta tekrarlanıyor.
- `character.identity` tüm promptlarda aynı. Karakteri tutarlı tutan bu blok.
- Arka plan her promptta aynı nötr, düz gri-bej; mekân yok.
- Her pozun `pose.allure` alanı cazibenin o anda nasıl okunduğunu yazıyor.

## Görsel yön

**Burkai'yi sabitleyen dört şey:**
- kül grisi ten ve üzerinde miselyum / yıldız haritası gibi dallanan siyah mürekkep desenleri,
- ışıksız, mat, ölü gri gözler,
- acı verecek kadar zayıf, uzun silüet,
- hiçbir teknoloji taşımaması: kask, giysi, cihaz yok.

**Saç (7 Kasım kararı):** Notlarda tarif yok. Uzun, düz, soğuk mavi parlamalı ay gümüşü beyaz; kül ten ve siyah mürekkeple kontrast kuruyor ve "Ay öpmüş" görünümü taşıyor.

**Kıyafet: lateks, cropped, transparent.**

| Set | Prompt | Tarif |
| --- | --- | --- |
| **Gece** (ana kıyafet) | 0–6, 8–10 | Kaburgada biten, dik yakalı, transparent dumanlı mor-siyah lateks cropped ceket; çıplak, mürekkepli göğsün üstünde açık. Opak parlak siyah lateks, yüksek bel, geniş paça pantolon. Çıplak ayak. |
| **Kubbe** | 7 | Aynı malzemeden ayak bileğine inen açık transparent lateks cübbe, aynı pantolon. |

Burkai'nin üzerinde hiçbir kaset fütürist donanım yok. Bu, onu tıknaz teknolojiye bürünmüş koloniden ayırıyor. Tek eşyası kubbede yazdığı kâğıt defter.

**Seductive, ama ses rehberine uygun:** Rehber, Burkai'nin flörtünün takip ederek değil fark ederek olduğunu, muhtaç olmadığını ve kimseyi aramadığını söylüyor. Bu yüzden pozlardaki cazibe hep **dinginlikten ve umursamazlıktan** geliyor: uzatılan ama ısrar edilmeyen el, kimse izliyor mu diye bakmadan alınan zevk, giderken omzunun üstünden atılan bakış.

**Kaçınılanlar (negatif promptta):** vampir dişi, pelerin, kan, gotik takı, kırmızı göz; korku / ceset görüntüsü (zayıflık hastalıklı değil zarif okunmalı); dövme flash'ı; kask ve uzay giysisi.

**SFW kuralı:** Göğüs çıplak ve transparent katmanın altında açık; pantolon her zaman opak.

**Alınmayan sahne:** "Çıplak ve yalnız" ilk anısı (B3) seductive pozla SFW kalamayacağı için bu sete eklenmedi. Gerekirse ölçeği anlatan uzak bir siluet olarak ayrıca yazılabilir.

| # | Prompt | Kıyafet | An | Cazibe |
| --- | --- | --- | --- | --- |
| 0 | Model sheet | Gece | Kimlik referansı (önce bunu üretin) | Hareketsizlik |
| 1 | İlk görünüş | Gece | Gemiye hayranlıkla bakıyor | Kendinden geçme |
| 2 | Tanışma | Gece | Ece'ye elini uzatıyor | Davet |
| 3 | Miselyum'u dinlemek | Gece | Başı geride, gözler kapalı | Zevk |
| 4 | Acıma | Gece | Tek parmakla yanağa dokunuş | Şefkat |
| 5 | Çare | Gece | İki eli iki yüzde | Mahremiyet |
| 6 | Karanlıkta güneşlenme | Gece | Ay gecesi | Tembellik |
| 7 | Kubbede yazarken | Kubbe | Ay gündüzü | Gizlilik |
| 8 | Ayrılış | Gece | "Öbür tarafa" gidiyor | Umursamazlık |
| 9 | İfade sayfası | Gece | Duygu referansı | — |
| 10 | A-pose | Gece | Simetrik tam boy referans | — |

---

## 0 · Model sheet (kimlik referansı)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime official character model sheet, hand-painted cels, retro-futuristic anime",
    "design_language": "retro-futuristic 80s anime world, but this character wears no technology at all: no devices, no gadgets, no helmet, no spacesuit",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers, bare inked torso under an open cropped jacket, high collars, wide flowing trousers, barefoot",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted blue-white specular streaks on silver hair and glossy latex, cool blue-violet shadows",
    "color": "faded analog colors, near-monochrome: ash-grey skin, ink-black patterns, moon-silver white hair, smoky violet-black transparent latex, glossy black latex, cold white light, faint blue-violet shadows",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "serene, languid, quietly seductive"
  },
  "character": {
    "name": "Burkai",
    "identity": {
      "age": "adult man, ageless, looks around 30, clearly adult",
      "species": "not human: an ethereal moon-touched being who never eats, drinks or sleeps",
      "face": {
        "shape": "long narrow elegant 80s OVA anime face, high sharp cheekbones, hollow cheeks, sharp jaw, straight nose",
        "eyes": "heavy-lidded eyes with long lashes and dull pale grey irises with no catchlights, a lifeless calm stare",
        "lips": "thin pale lips, a faint lazy smile at one corner",
        "default_expression": "serene, unhurried, quietly amused, completely at rest"
      },
      "hair": {
        "color": "moon-silver white with a cold pale blue sheen",
        "style": "long straight hair falling past the shoulders, loose and uneven, a few strands across the face",
        "highlights": "painted cold blue-white highlight bands"
      },
      "skin": {
        "tone": "ash-grey skin, matte, like a blank canvas",
        "ink": "sprawling black ink patterns across the skin that branch like mycelium and star charts, organic and hand-drawn, not tattoo flash: spreading over the chest, shoulders, down both arms to the fingers and up the neck to the jaw"
      },
      "body": "very tall and painfully thin, long limbs, visible collarbones and faint ribs, gaunt but graceful, long elegant soft-looking hands, adult male proportions"
    },
    "outfit": {
      "jacket": "cropped open jacket of transparent smoky violet-black latex ending at the ribs, high stand-up collar, long sleeves to the wrist, worn open over the bare inked chest and stomach",
      "trousers": "opaque glossy black latex high-waist wide-leg trousers, long and loose, hems pooling around the ankles",
      "footwear": "barefoot",
      "accessories": "none"
    },
    "props": {}
  },
  "pose": {
    "camera": "model sheet turnaround: front view, three-quarter view, side view, back view, all full body, eye-level",
    "action": "relaxed contrapposto in every view: weight on one leg, hip slightly out, arms loose, one hand resting at the edge of the open jacket, shoulders low and easy",
    "expression": "serene heavy-lidded stare, faint lazy smile, same face in every view",
    "allure": "seduction through stillness: nothing in him is trying, and that is the pull. Tasteful and SFW, adult man"
  },
  "composition": {
    "framing": "four full-body views side by side, horizontal 16:9, consistent scale",
    "lighting": "soft flat frontal light, subtle cel shadows",
    "background": "plain neutral flat background, muted grey-beige, no scenery"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, boy, woman, female body, breasts, nudity, nsfw, explicit, exposed genitals, see-through trousers, visible underwear, lewd gesture, crotch focus, vampire fangs, cape, blood, gothic jewelry, crucifix, coffin, bats, red eyes, horror, corpse, skeleton, zombie, sickly green skin, bodybuilder, bulky muscles, tattoo flash, tribal tattoo, helmet, spacesuit, gadgets, wrist computer, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, black hair, dark hair, detailed background, scenery, environment, room, furniture, landscape"
}
```

---

## 1 · İlk görünüş (Ay, gemiye hayranlık)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels, retro-futuristic anime screencap",
    "design_language": "retro-futuristic 80s anime world, but this character wears no technology at all: no devices, no gadgets, no helmet, no spacesuit",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers, bare inked torso under an open cropped jacket, high collars, wide flowing trousers, barefoot",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted blue-white specular streaks on silver hair and glossy latex, cool blue-violet shadows",
    "color": "faded analog colors, near-monochrome: ash-grey skin, ink-black patterns, moon-silver white hair, smoky violet-black transparent latex, glossy black latex, cold white light, faint blue-violet shadows",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "rapt wonder, the first new thing he has seen in ages"
  },
  "character": {
    "name": "Burkai",
    "identity": {
      "age": "adult man, ageless, looks around 30, clearly adult",
      "species": "not human: an ethereal moon-touched being who never eats, drinks or sleeps",
      "face": {
        "shape": "long narrow elegant 80s OVA anime face, high sharp cheekbones, hollow cheeks, sharp jaw, straight nose",
        "eyes": "heavy-lidded eyes with long lashes and dull pale grey irises with no catchlights, a lifeless calm stare",
        "lips": "thin pale lips, a faint lazy smile at one corner",
        "default_expression": "serene, unhurried, quietly amused, completely at rest"
      },
      "hair": {
        "color": "moon-silver white with a cold pale blue sheen",
        "style": "long straight hair falling past the shoulders, loose and uneven, a few strands across the face",
        "highlights": "painted cold blue-white highlight bands"
      },
      "skin": {
        "tone": "ash-grey skin, matte, like a blank canvas",
        "ink": "sprawling black ink patterns across the skin that branch like mycelium and star charts, organic and hand-drawn, not tattoo flash: spreading over the chest, shoulders, down both arms to the fingers and up the neck to the jaw"
      },
      "body": "very tall and painfully thin, long limbs, visible collarbones and faint ribs, gaunt but graceful, long elegant soft-looking hands, adult male proportions"
    },
    "outfit": {
      "jacket": "cropped open jacket of transparent smoky violet-black latex ending at the ribs, high stand-up collar, long sleeves to the wrist, worn open over the bare inked chest and stomach",
      "trousers": "opaque glossy black latex high-waist wide-leg trousers, long and loose, hems pooling around the ankles",
      "footwear": "barefoot",
      "accessories": "none"
    },
    "props": {}
  },
  "pose": {
    "camera": "three-quarter front view, slightly low angle",
    "action": "standing still with his head tipped up, gazing at something huge above and beyond the frame, one hand drifting to rest flat on his bare inked chest, jacket falling open, long hair spilling back",
    "expression": "absolute awe, lips parted, dull grey eyes wide for once",
    "allure": "seduction as rapture: the open throat and open chest of someone completely taken by what he sees. Tasteful and SFW, adult man"
  },
  "composition": {
    "framing": "knee-up, vertical 4:5",
    "lighting": "hard cold white light from above and one side, strong cel shadows, glossy highlights on the latex",
    "background": "plain neutral flat background, muted grey-beige, no scenery"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, boy, woman, female body, breasts, nudity, nsfw, explicit, exposed genitals, see-through trousers, visible underwear, lewd gesture, crotch focus, vampire fangs, cape, blood, gothic jewelry, crucifix, coffin, bats, red eyes, horror, corpse, skeleton, zombie, sickly green skin, bodybuilder, bulky muscles, tattoo flash, tribal tattoo, helmet, spacesuit, gadgets, wrist computer, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, black hair, dark hair, detailed background, scenery, environment, room, furniture, landscape"
}
```

---

## 2 · Tanışma (el uzatma)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels, retro-futuristic anime screencap",
    "design_language": "retro-futuristic 80s anime world, but this character wears no technology at all: no devices, no gadgets, no helmet, no spacesuit",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers, bare inked torso under an open cropped jacket, high collars, wide flowing trousers, barefoot",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted blue-white specular streaks on silver hair and glossy latex, cool blue-violet shadows",
    "color": "faded analog colors, near-monochrome: ash-grey skin, ink-black patterns, moon-silver white hair, smoky violet-black transparent latex, glossy black latex, cold white light, faint blue-violet shadows",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "courtly, playful, unhurried"
  },
  "character": {
    "name": "Burkai",
    "identity": {
      "age": "adult man, ageless, looks around 30, clearly adult",
      "species": "not human: an ethereal moon-touched being who never eats, drinks or sleeps",
      "face": {
        "shape": "long narrow elegant 80s OVA anime face, high sharp cheekbones, hollow cheeks, sharp jaw, straight nose",
        "eyes": "heavy-lidded eyes with long lashes and dull pale grey irises with no catchlights, a lifeless calm stare",
        "lips": "thin pale lips, a faint lazy smile at one corner",
        "default_expression": "serene, unhurried, quietly amused, completely at rest"
      },
      "hair": {
        "color": "moon-silver white with a cold pale blue sheen",
        "style": "long straight hair falling past the shoulders, loose and uneven, a few strands across the face",
        "highlights": "painted cold blue-white highlight bands"
      },
      "skin": {
        "tone": "ash-grey skin, matte, like a blank canvas",
        "ink": "sprawling black ink patterns across the skin that branch like mycelium and star charts, organic and hand-drawn, not tattoo flash: spreading over the chest, shoulders, down both arms to the fingers and up the neck to the jaw"
      },
      "body": "very tall and painfully thin, long limbs, visible collarbones and faint ribs, gaunt but graceful, long elegant soft-looking hands, adult male proportions"
    },
    "outfit": {
      "jacket": "cropped open jacket of transparent smoky violet-black latex ending at the ribs, high stand-up collar, long sleeves to the wrist, worn open over the bare inked chest and stomach",
      "trousers": "opaque glossy black latex high-waist wide-leg trousers, long and loose, hems pooling around the ankles",
      "footwear": "barefoot",
      "accessories": "none"
    },
    "props": {}
  },
  "pose": {
    "camera": "three-quarter front view, eye-level",
    "action": "a slight bow from the waist, one long inked hand extended toward the viewer palm up, the other arm folded loosely behind his back, hair sliding forward over one shoulder",
    "expression": "lazy mischievous smile, heavy-lidded eyes holding the viewer's",
    "allure": "seduction as invitation: the hand is offered, never pressed; if it is not taken, he will simply withdraw it. Tasteful and SFW, adult man"
  },
  "composition": {
    "framing": "thigh-up, vertical 4:5",
    "lighting": "soft cold frontal light, subtle cel shadows",
    "background": "plain neutral flat background, muted grey-beige, no scenery"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, boy, woman, female body, breasts, nudity, nsfw, explicit, exposed genitals, see-through trousers, visible underwear, lewd gesture, crotch focus, vampire fangs, cape, blood, gothic jewelry, crucifix, coffin, bats, red eyes, horror, corpse, skeleton, zombie, sickly green skin, bodybuilder, bulky muscles, tattoo flash, tribal tattoo, helmet, spacesuit, gadgets, wrist computer, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, black hair, dark hair, detailed background, scenery, environment, room, furniture, landscape"
}
```

---

## 3 · Miselyum'u dinlemek

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels, retro-futuristic anime screencap",
    "design_language": "retro-futuristic 80s anime world, but this character wears no technology at all: no devices, no gadgets, no helmet, no spacesuit",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers, bare inked torso under an open cropped jacket, high collars, wide flowing trousers, barefoot",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted blue-white specular streaks on silver hair and glossy latex, cool blue-violet shadows",
    "color": "faded analog colors, near-monochrome: ash-grey skin, ink-black patterns, moon-silver white hair, smoky violet-black transparent latex, glossy black latex, cold white light, faint blue-violet shadows",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "private pleasure, listening to something only he can hear"
  },
  "character": {
    "name": "Burkai",
    "identity": {
      "age": "adult man, ageless, looks around 30, clearly adult",
      "species": "not human: an ethereal moon-touched being who never eats, drinks or sleeps",
      "face": {
        "shape": "long narrow elegant 80s OVA anime face, high sharp cheekbones, hollow cheeks, sharp jaw, straight nose",
        "eyes": "heavy-lidded eyes with long lashes and dull pale grey irises with no catchlights, a lifeless calm stare",
        "lips": "thin pale lips, a faint lazy smile at one corner",
        "default_expression": "serene, unhurried, quietly amused, completely at rest"
      },
      "hair": {
        "color": "moon-silver white with a cold pale blue sheen",
        "style": "long straight hair falling past the shoulders, loose and uneven, a few strands across the face",
        "highlights": "painted cold blue-white highlight bands"
      },
      "skin": {
        "tone": "ash-grey skin, matte, like a blank canvas",
        "ink": "sprawling black ink patterns across the skin that branch like mycelium and star charts, organic and hand-drawn, not tattoo flash: spreading over the chest, shoulders, down both arms to the fingers and up the neck to the jaw"
      },
      "body": "very tall and painfully thin, long limbs, visible collarbones and faint ribs, gaunt but graceful, long elegant soft-looking hands, adult male proportions"
    },
    "outfit": {
      "jacket": "cropped open jacket of transparent smoky violet-black latex ending at the ribs, high stand-up collar, long sleeves to the wrist, worn open over the bare inked chest and stomach",
      "trousers": "opaque glossy black latex high-waist wide-leg trousers, long and loose, hems pooling around the ankles",
      "footwear": "barefoot",
      "accessories": "none"
    },
    "props": {}
  },
  "pose": {
    "camera": "three-quarter front view, slightly low angle",
    "action": "head tipped far back, long throat exposed, eyes closed, one hand resting at his high collar, the other arm hanging loose, jacket sliding off one shoulder",
    "expression": "eyes closed, savoring, a slow private smile",
    "allure": "seduction as pleasure: he is enjoying something deeply and does not care who is watching. Tasteful and SFW, adult man"
  },
  "composition": {
    "framing": "waist-up, vertical 4:5",
    "lighting": "cool soft light from above, blue-violet shadows along the throat and ink",
    "background": "plain neutral flat background, muted grey-beige, no scenery"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, boy, woman, female body, breasts, nudity, nsfw, explicit, exposed genitals, see-through trousers, visible underwear, lewd gesture, crotch focus, vampire fangs, cape, blood, gothic jewelry, crucifix, coffin, bats, red eyes, horror, corpse, skeleton, zombie, sickly green skin, bodybuilder, bulky muscles, tattoo flash, tribal tattoo, helmet, spacesuit, gadgets, wrist computer, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, black hair, dark hair, detailed background, scenery, environment, room, furniture, landscape"
}
```

---

## 4 · Acıma (yanağa tek parmak)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels, retro-futuristic anime screencap",
    "design_language": "retro-futuristic 80s anime world, but this character wears no technology at all: no devices, no gadgets, no helmet, no spacesuit",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers, bare inked torso under an open cropped jacket, high collars, wide flowing trousers, barefoot",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted blue-white specular streaks on silver hair and glossy latex, cool blue-violet shadows",
    "color": "faded analog colors, near-monochrome: ash-grey skin, ink-black patterns, moon-silver white hair, smoky violet-black transparent latex, glossy black latex, cold white light, faint blue-violet shadows",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "tender pity, unsettling closeness"
  },
  "character": {
    "name": "Burkai",
    "identity": {
      "age": "adult man, ageless, looks around 30, clearly adult",
      "species": "not human: an ethereal moon-touched being who never eats, drinks or sleeps",
      "face": {
        "shape": "long narrow elegant 80s OVA anime face, high sharp cheekbones, hollow cheeks, sharp jaw, straight nose",
        "eyes": "heavy-lidded eyes with long lashes and dull pale grey irises with no catchlights, a lifeless calm stare",
        "lips": "thin pale lips, a faint lazy smile at one corner",
        "default_expression": "serene, unhurried, quietly amused, completely at rest"
      },
      "hair": {
        "color": "moon-silver white with a cold pale blue sheen",
        "style": "long straight hair falling past the shoulders, loose and uneven, a few strands across the face",
        "highlights": "painted cold blue-white highlight bands"
      },
      "skin": {
        "tone": "ash-grey skin, matte, like a blank canvas",
        "ink": "sprawling black ink patterns across the skin that branch like mycelium and star charts, organic and hand-drawn, not tattoo flash: spreading over the chest, shoulders, down both arms to the fingers and up the neck to the jaw"
      },
      "body": "very tall and painfully thin, long limbs, visible collarbones and faint ribs, gaunt but graceful, long elegant soft-looking hands, adult male proportions"
    },
    "outfit": {
      "jacket": "cropped open jacket of transparent smoky violet-black latex ending at the ribs, high stand-up collar, long sleeves to the wrist, worn open over the bare inked chest and stomach",
      "trousers": "opaque glossy black latex high-waist wide-leg trousers, long and loose, hems pooling around the ankles",
      "footwear": "barefoot",
      "accessories": "none"
    },
    "props": {}
  },
  "pose": {
    "camera": "close-up from the viewer's point of view, eye-level",
    "action": "leaning down close to the viewer, head lowered, one inked hand reaching forward so a single fingertip touches the viewer's cheek just outside the frame, hair falling forward around his face",
    "expression": "soft pity in the dull grey eyes, lips closed, the faintest sad smile",
    "allure": "seduction as tenderness: close enough to feel, gentle enough to be frightening, and he is not asking for anything. Tasteful and SFW, adult man"
  },
  "composition": {
    "framing": "head-and-shoulders, vertical 4:5, his face filling the upper half",
    "lighting": "soft cold light from the side, gentle cel shadows",
    "background": "plain neutral flat background, muted grey-beige, no scenery"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, boy, woman, female body, breasts, nudity, nsfw, explicit, exposed genitals, see-through trousers, visible underwear, lewd gesture, crotch focus, vampire fangs, cape, blood, gothic jewelry, crucifix, coffin, bats, red eyes, horror, corpse, skeleton, zombie, sickly green skin, bodybuilder, bulky muscles, tattoo flash, tribal tattoo, helmet, spacesuit, gadgets, wrist computer, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, black hair, dark hair, detailed background, scenery, environment, room, furniture, landscape"
}
```

---

## 5 · Çare (iki eli iki yüzde)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels, retro-futuristic anime screencap",
    "design_language": "retro-futuristic 80s anime world, but this character wears no technology at all: no devices, no gadgets, no helmet, no spacesuit",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers, bare inked torso under an open cropped jacket, high collars, wide flowing trousers, barefoot",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted blue-white specular streaks on silver hair and glossy latex, cool blue-violet shadows",
    "color": "faded analog colors, near-monochrome: ash-grey skin, ink-black patterns, moon-silver white hair, smoky violet-black transparent latex, glossy black latex, cold white light, faint blue-violet shadows",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "intimate, calm, a quiet ritual"
  },
  "character": {
    "name": "Burkai",
    "identity": {
      "age": "adult man, ageless, looks around 30, clearly adult",
      "species": "not human: an ethereal moon-touched being who never eats, drinks or sleeps",
      "face": {
        "shape": "long narrow elegant 80s OVA anime face, high sharp cheekbones, hollow cheeks, sharp jaw, straight nose",
        "eyes": "heavy-lidded eyes with long lashes and dull pale grey irises with no catchlights, a lifeless calm stare",
        "lips": "thin pale lips, a faint lazy smile at one corner",
        "default_expression": "serene, unhurried, quietly amused, completely at rest"
      },
      "hair": {
        "color": "moon-silver white with a cold pale blue sheen",
        "style": "long straight hair falling past the shoulders, loose and uneven, a few strands across the face",
        "highlights": "painted cold blue-white highlight bands"
      },
      "skin": {
        "tone": "ash-grey skin, matte, like a blank canvas",
        "ink": "sprawling black ink patterns across the skin that branch like mycelium and star charts, organic and hand-drawn, not tattoo flash: spreading over the chest, shoulders, down both arms to the fingers and up the neck to the jaw"
      },
      "body": "very tall and painfully thin, long limbs, visible collarbones and faint ribs, gaunt but graceful, long elegant soft-looking hands, adult male proportions"
    },
    "outfit": {
      "jacket": "cropped open jacket of transparent smoky violet-black latex ending at the ribs, high stand-up collar, long sleeves to the wrist, worn open over the bare inked chest and stomach",
      "trousers": "opaque glossy black latex high-waist wide-leg trousers, long and loose, hems pooling around the ankles",
      "footwear": "barefoot",
      "accessories": "none"
    },
    "props": {}
  },
  "pose": {
    "camera": "straight front view from the viewer's point of view, eye-level",
    "action": "both long inked hands raised forward at face height, palms open and slightly cupped as if holding two faces just outside the frame, arms wide, open jacket framing the bare inked chest",
    "expression": "eyes closed, serene, lips softly parted as if about to speak a line",
    "allure": "seduction as intimacy: open arms, closed eyes, total calm. Tasteful and SFW, adult man"
  },
  "composition": {
    "framing": "waist-up, square 1:1, symmetrical composition",
    "lighting": "soft even cold light, faint glow on the ink patterns",
    "background": "plain neutral flat background, muted grey-beige, no scenery"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, boy, woman, female body, breasts, nudity, nsfw, explicit, exposed genitals, see-through trousers, visible underwear, lewd gesture, crotch focus, vampire fangs, cape, blood, gothic jewelry, crucifix, coffin, bats, red eyes, horror, corpse, skeleton, zombie, sickly green skin, bodybuilder, bulky muscles, tattoo flash, tribal tattoo, helmet, spacesuit, gadgets, wrist computer, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, black hair, dark hair, detailed background, scenery, environment, room, furniture, landscape"
}
```

---

## 6 · Karanlıkta güneşlenme

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels, retro-futuristic anime screencap",
    "design_language": "retro-futuristic 80s anime world, but this character wears no technology at all: no devices, no gadgets, no helmet, no spacesuit",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers, bare inked torso under an open cropped jacket, high collars, wide flowing trousers, barefoot",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted blue-white specular streaks on silver hair and glossy latex, cool blue-violet shadows",
    "color": "faded analog colors, near-monochrome: ash-grey skin, ink-black patterns, moon-silver white hair, smoky violet-black transparent latex, glossy black latex, cold white light, faint blue-violet shadows",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "deep rest, warmth in the dark"
  },
  "character": {
    "name": "Burkai",
    "identity": {
      "age": "adult man, ageless, looks around 30, clearly adult",
      "species": "not human: an ethereal moon-touched being who never eats, drinks or sleeps",
      "face": {
        "shape": "long narrow elegant 80s OVA anime face, high sharp cheekbones, hollow cheeks, sharp jaw, straight nose",
        "eyes": "heavy-lidded eyes with long lashes and dull pale grey irises with no catchlights, a lifeless calm stare",
        "lips": "thin pale lips, a faint lazy smile at one corner",
        "default_expression": "serene, unhurried, quietly amused, completely at rest"
      },
      "hair": {
        "color": "moon-silver white with a cold pale blue sheen",
        "style": "long straight hair falling past the shoulders, loose and uneven, a few strands across the face",
        "highlights": "painted cold blue-white highlight bands"
      },
      "skin": {
        "tone": "ash-grey skin, matte, like a blank canvas",
        "ink": "sprawling black ink patterns across the skin that branch like mycelium and star charts, organic and hand-drawn, not tattoo flash: spreading over the chest, shoulders, down both arms to the fingers and up the neck to the jaw"
      },
      "body": "very tall and painfully thin, long limbs, visible collarbones and faint ribs, gaunt but graceful, long elegant soft-looking hands, adult male proportions"
    },
    "outfit": {
      "jacket": "cropped open jacket of transparent smoky violet-black latex ending at the ribs, high stand-up collar, long sleeves to the wrist, worn open over the bare inked chest and stomach",
      "trousers": "opaque glossy black latex high-waist wide-leg trousers, long and loose, hems pooling around the ankles",
      "footwear": "barefoot",
      "accessories": "none"
    },
    "props": {}
  },
  "pose": {
    "camera": "high angle looking down at him, three-quarter view",
    "action": "lying on his back, one arm folded behind his head, the other resting across his stomach, one knee raised, jacket fallen open, hair spread out around his head",
    "expression": "eyes closed, a contented lazy smile",
    "allure": "seduction as languor: sunbathing in the dark the way others lie in the sun. Tasteful and SFW, adult man"
  },
  "composition": {
    "framing": "full body, horizontal 3:2",
    "lighting": "very low soft blue-violet light, gentle highlights on the latex and ink",
    "background": "plain neutral flat background, muted grey-beige, no scenery"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, boy, woman, female body, breasts, nudity, nsfw, explicit, exposed genitals, see-through trousers, visible underwear, lewd gesture, crotch focus, vampire fangs, cape, blood, gothic jewelry, crucifix, coffin, bats, red eyes, horror, corpse, skeleton, zombie, sickly green skin, bodybuilder, bulky muscles, tattoo flash, tribal tattoo, helmet, spacesuit, gadgets, wrist computer, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, black hair, dark hair, detailed background, scenery, environment, room, furniture, landscape"
}
```

---

## 7 · Kubbede yazarken

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels, retro-futuristic anime screencap",
    "design_language": "retro-futuristic 80s anime world, but this character wears no technology at all: no devices, no gadgets, no helmet, no spacesuit",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers, bare inked torso under an open cropped jacket, high collars, wide flowing trousers, barefoot",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted blue-white specular streaks on silver hair and glossy latex, cool blue-violet shadows",
    "color": "faded analog colors, near-monochrome: ash-grey skin, ink-black patterns, moon-silver white hair, smoky violet-black transparent latex, glossy black latex, cold white light, faint blue-violet shadows",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "private, quiet, caught mid-thought"
  },
  "character": {
    "name": "Burkai",
    "identity": {
      "age": "adult man, ageless, looks around 30, clearly adult",
      "species": "not human: an ethereal moon-touched being who never eats, drinks or sleeps",
      "face": {
        "shape": "long narrow elegant 80s OVA anime face, high sharp cheekbones, hollow cheeks, sharp jaw, straight nose",
        "eyes": "heavy-lidded eyes with long lashes and dull pale grey irises with no catchlights, a lifeless calm stare",
        "lips": "thin pale lips, a faint lazy smile at one corner",
        "default_expression": "serene, unhurried, quietly amused, completely at rest"
      },
      "hair": {
        "color": "moon-silver white with a cold pale blue sheen",
        "style": "long straight hair falling past the shoulders, loose and uneven, a few strands across the face",
        "highlights": "painted cold blue-white highlight bands"
      },
      "skin": {
        "tone": "ash-grey skin, matte, like a blank canvas",
        "ink": "sprawling black ink patterns across the skin that branch like mycelium and star charts, organic and hand-drawn, not tattoo flash: spreading over the chest, shoulders, down both arms to the fingers and up the neck to the jaw"
      },
      "body": "very tall and painfully thin, long limbs, visible collarbones and faint ribs, gaunt but graceful, long elegant soft-looking hands, adult male proportions"
    },
    "outfit": {
      "robe": "long open robe of transparent smoky violet-black latex reaching the ankles, high stand-up collar, wide sleeves, worn open over the bare inked chest",
      "trousers": "opaque glossy black latex high-waist wide-leg trousers",
      "footwear": "barefoot",
      "accessories": "none"
    },
    "props": {
      "notebook": "worn paper notebook open on his knee, pages covered in small handwriting that cannot be read",
      "pencil": "short pencil"
    }
  },
  "pose": {
    "camera": "three-quarter front view, eye-level, slightly to the side",
    "action": "sitting cross-legged and leaning forward, notebook on his knee, the pencil resting against his lower lip, robe slipping off one shoulder, hair falling forward",
    "expression": "glancing up at the viewer from under his lashes, unbothered, a faint smile, as if to say do not read over my shoulder",
    "allure": "seduction as privacy: the one thing he will not share is what makes him interesting. Tasteful and SFW, adult man"
  },
  "composition": {
    "framing": "full body seated, vertical 4:5",
    "lighting": "dim warm-grey indoor light from one side, soft shadows",
    "background": "plain neutral flat background, muted grey-beige, no scenery"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, boy, woman, female body, breasts, nudity, nsfw, explicit, exposed genitals, see-through trousers, visible underwear, lewd gesture, crotch focus, vampire fangs, cape, blood, gothic jewelry, crucifix, coffin, bats, red eyes, horror, corpse, skeleton, zombie, sickly green skin, bodybuilder, bulky muscles, tattoo flash, tribal tattoo, helmet, spacesuit, gadgets, wrist computer, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, black hair, dark hair, detailed background, scenery, environment, room, furniture, landscape"
}
```

---

## 8 · Ayrılış (öbür tarafa)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime cel animation frame, hand-painted cels, retro-futuristic anime screencap",
    "design_language": "retro-futuristic 80s anime world, but this character wears no technology at all: no devices, no gadgets, no helmet, no spacesuit",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers, bare inked torso under an open cropped jacket, high collars, wide flowing trousers, barefoot",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted blue-white specular streaks on silver hair and glossy latex, cool blue-violet shadows",
    "color": "faded analog colors, near-monochrome: ash-grey skin, ink-black patterns, moon-silver white hair, smoky violet-black transparent latex, glossy black latex, cold white light, faint blue-violet shadows",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "easy goodbye, see you later"
  },
  "character": {
    "name": "Burkai",
    "identity": {
      "age": "adult man, ageless, looks around 30, clearly adult",
      "species": "not human: an ethereal moon-touched being who never eats, drinks or sleeps",
      "face": {
        "shape": "long narrow elegant 80s OVA anime face, high sharp cheekbones, hollow cheeks, sharp jaw, straight nose",
        "eyes": "heavy-lidded eyes with long lashes and dull pale grey irises with no catchlights, a lifeless calm stare",
        "lips": "thin pale lips, a faint lazy smile at one corner",
        "default_expression": "serene, unhurried, quietly amused, completely at rest"
      },
      "hair": {
        "color": "moon-silver white with a cold pale blue sheen",
        "style": "long straight hair falling past the shoulders, loose and uneven, a few strands across the face",
        "highlights": "painted cold blue-white highlight bands"
      },
      "skin": {
        "tone": "ash-grey skin, matte, like a blank canvas",
        "ink": "sprawling black ink patterns across the skin that branch like mycelium and star charts, organic and hand-drawn, not tattoo flash: spreading over the chest, shoulders, down both arms to the fingers and up the neck to the jaw"
      },
      "body": "very tall and painfully thin, long limbs, visible collarbones and faint ribs, gaunt but graceful, long elegant soft-looking hands, adult male proportions"
    },
    "outfit": {
      "jacket": "cropped open jacket of transparent smoky violet-black latex ending at the ribs, high stand-up collar, long sleeves to the wrist, worn open over the bare inked chest and stomach",
      "trousers": "opaque glossy black latex high-waist wide-leg trousers, long and loose, hems pooling around the ankles",
      "footwear": "barefoot",
      "accessories": "none"
    },
    "props": {}
  },
  "pose": {
    "camera": "three-quarter rear view, eye-level",
    "action": "walking away barefoot with a slow loose stride, jacket slipping down off both shoulders to show the ink across his back, one hand lifted lazily in a half wave without turning fully",
    "expression": "glancing back over his shoulder, lazy smile, heavy-lidded eyes",
    "allure": "seduction as indifference: he is leaving, and he knows you are watching him go. Tasteful and SFW, adult man"
  },
  "composition": {
    "framing": "full body, vertical 4:5",
    "lighting": "cold light behind the viewer fading softly toward the edges",
    "background": "plain neutral flat background, muted grey-beige, no scenery"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, boy, woman, female body, breasts, nudity, nsfw, explicit, exposed genitals, see-through trousers, visible underwear, lewd gesture, crotch focus, vampire fangs, cape, blood, gothic jewelry, crucifix, coffin, bats, red eyes, horror, corpse, skeleton, zombie, sickly green skin, bodybuilder, bulky muscles, tattoo flash, tribal tattoo, helmet, spacesuit, gadgets, wrist computer, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, black hair, dark hair, detailed background, scenery, environment, room, furniture, landscape"
}
```

---

## 9 · İfade sayfası

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime official character expression sheet, hand-painted cels",
    "design_language": "retro-futuristic 80s anime world, but this character wears no technology at all: no devices, no gadgets, no helmet, no spacesuit",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers, bare inked torso under an open cropped jacket, high collars, wide flowing trousers, barefoot",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted blue-white specular streaks on silver hair and glossy latex, cool blue-violet shadows",
    "color": "faded analog colors, near-monochrome: ash-grey skin, ink-black patterns, moon-silver white hair, smoky violet-black transparent latex, glossy black latex, cold white light, faint blue-violet shadows",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "character reference, languid and alluring"
  },
  "character": {
    "name": "Burkai",
    "identity": {
      "age": "adult man, ageless, looks around 30, clearly adult",
      "species": "not human: an ethereal moon-touched being who never eats, drinks or sleeps",
      "face": {
        "shape": "long narrow elegant 80s OVA anime face, high sharp cheekbones, hollow cheeks, sharp jaw, straight nose",
        "eyes": "heavy-lidded eyes with long lashes and dull pale grey irises with no catchlights, a lifeless calm stare",
        "lips": "thin pale lips, a faint lazy smile at one corner",
        "default_expression": "serene, unhurried, quietly amused, completely at rest"
      },
      "hair": {
        "color": "moon-silver white with a cold pale blue sheen",
        "style": "long straight hair falling past the shoulders, loose and uneven, a few strands across the face",
        "highlights": "painted cold blue-white highlight bands"
      },
      "skin": {
        "tone": "ash-grey skin, matte, like a blank canvas",
        "ink": "sprawling black ink patterns across the skin that branch like mycelium and star charts, organic and hand-drawn, not tattoo flash: spreading over the chest, shoulders, down both arms to the fingers and up the neck to the jaw"
      },
      "body": "very tall and painfully thin, long limbs, visible collarbones and faint ribs, gaunt but graceful, long elegant soft-looking hands, adult male proportions"
    },
    "outfit": {
      "jacket": "high stand-up collar of an open transparent smoky violet-black latex cropped jacket over the bare inked chest"
    },
    "props": {}
  },
  "pose": {
    "camera": "head-and-shoulders portraits, front and three-quarter views",
    "action": "nine expressions in a 3x3 grid",
    "expression": "1 serene default with faint lazy smile, 2 rapt awe with parted lips, 3 eyes closed savoring, 4 sudden shock with eyes snapping open, 5 soft pity, 6 almost sorry, 7 mischievous smile, 8 calm acceptance with a slight tilt of the head as if saying perhaps, 9 eyes closed in deep rest; every expression unhurried and quietly seductive",
    "allure": "allure lives in the heavy lids and the lazy mouth, never in intensity or need. Tasteful and SFW, adult man"
  },
  "composition": {
    "framing": "3x3 grid of head-and-shoulder portraits, square 1:1, same scale and same face in every cell",
    "lighting": "soft flat frontal light, subtle cel shadows",
    "background": "plain neutral flat background, muted grey-beige, no scenery"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, boy, woman, female body, breasts, nudity, nsfw, explicit, exposed genitals, see-through trousers, visible underwear, lewd gesture, crotch focus, vampire fangs, cape, blood, gothic jewelry, crucifix, coffin, bats, red eyes, horror, corpse, skeleton, zombie, sickly green skin, bodybuilder, bulky muscles, tattoo flash, tribal tattoo, helmet, spacesuit, gadgets, wrist computer, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, black hair, dark hair, detailed background, scenery, environment, room, furniture, landscape, labels, different faces"
}
```

---

## 10 · A-pose (karakter referansı)

```json
{
  "style": {
    "medium": "authentic late 1980s / early 1990s OVA anime official character model sheet, hand-painted cels, retro-futuristic anime",
    "design_language": "retro-futuristic 80s anime world, but this character wears no technology at all: no devices, no gadgets, no helmet, no spacesuit",
    "fashion_keywords": "glossy latex, cropped silhouettes, transparent latex layers, bare inked torso under an open cropped jacket, high collars, wide flowing trousers, barefoot",
    "linework": "thin-to-bold hand-inked black outlines, slightly imperfect analog lines",
    "shading": "flat two-tone cel shading, sharp-edged shadow shapes, painted blue-white specular streaks on silver hair and glossy latex, cool blue-violet shadows",
    "color": "faded analog colors, near-monochrome: ash-grey skin, ink-black patterns, moon-silver white hair, smoky violet-black transparent latex, glossy black latex, cold white light, faint blue-violet shadows",
    "texture": "35mm film grain, VHS tape noise, soft VHS blur, faint chromatic aberration, slight color bleed",
    "mood": "neutral character reference with quiet confidence"
  },
  "character": {
    "name": "Burkai",
    "identity": {
      "age": "adult man, ageless, looks around 30, clearly adult",
      "species": "not human: an ethereal moon-touched being who never eats, drinks or sleeps",
      "face": {
        "shape": "long narrow elegant 80s OVA anime face, high sharp cheekbones, hollow cheeks, sharp jaw, straight nose",
        "eyes": "heavy-lidded eyes with long lashes and dull pale grey irises with no catchlights, a lifeless calm stare",
        "lips": "thin pale lips, a faint lazy smile at one corner",
        "default_expression": "serene, unhurried, quietly amused, completely at rest"
      },
      "hair": {
        "color": "moon-silver white with a cold pale blue sheen",
        "style": "long straight hair falling past the shoulders, loose and uneven, a few strands across the face",
        "highlights": "painted cold blue-white highlight bands"
      },
      "skin": {
        "tone": "ash-grey skin, matte, like a blank canvas",
        "ink": "sprawling black ink patterns across the skin that branch like mycelium and star charts, organic and hand-drawn, not tattoo flash: spreading over the chest, shoulders, down both arms to the fingers and up the neck to the jaw"
      },
      "body": "very tall and painfully thin, long limbs, visible collarbones and faint ribs, gaunt but graceful, long elegant soft-looking hands, adult male proportions"
    },
    "outfit": {
      "jacket": "cropped open jacket of transparent smoky violet-black latex ending at the ribs, high stand-up collar, long sleeves to the wrist, worn open over the bare inked chest and stomach",
      "trousers": "opaque glossy black latex high-waist wide-leg trousers, long and loose, hems pooling around the ankles",
      "footwear": "barefoot",
      "accessories": "none"
    },
    "props": {}
  },
  "pose": {
    "camera": "straight front view, eye-level at chest height, orthographic feel, no perspective distortion",
    "action": "symmetrical A-pose: standing straight, feet shoulder-width apart and flat on the ground, arms straight and angled about 45 degrees down and away from the body, palms facing inward, fingers relaxed, head facing forward, jacket open",
    "expression": "calm, heavy-lidded, a faint closed-lip lazy smile, eyes straight ahead",
    "allure": "allure only in the face and the relaxed shoulders; the body stays in a strict symmetrical A-pose. Tasteful and SFW, adult man"
  },
  "composition": {
    "framing": "full body from head to toe with a small margin, centered, vertical 9:16",
    "lighting": "even flat frontal light, minimal cel shadows, no dramatic lighting",
    "background": "plain neutral flat background, muted grey-beige, no scenery"
  },
  "negative_prompt": "child, teen, teenager, young-looking face, boy, woman, female body, breasts, nudity, nsfw, explicit, exposed genitals, see-through trousers, visible underwear, lewd gesture, crotch focus, vampire fangs, cape, blood, gothic jewelry, crucifix, coffin, bats, red eyes, horror, corpse, skeleton, zombie, sickly green skin, bodybuilder, bulky muscles, tattoo flash, tribal tattoo, helmet, spacesuit, gadgets, wrist computer, modern anime style, 2010s anime, digital gloss, soft gradients, 3d render, photorealistic, readable logos, readable text, chibi, deformed hands, extra fingers, watermark, copy of an existing anime character, black hair, dark hair, detailed background, scenery, environment, room, furniture, landscape, dynamic pose, T-pose, crossed arms, hands on hips, tilted head, cropped limbs, cropped feet, perspective distortion"
}
```

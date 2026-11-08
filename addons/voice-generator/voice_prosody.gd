class_name VoiceProsody
extends RefCounted
## Turns a line of text into a timed list of syllable "parts" for natural
## playback: heuristic syllable splitting (English/Turkish-friendly) plus an
## intonation contour (declination, stress, question rise, final fall,
## smooth drift). Pure data — no audio — so it can be tested headless.
##
## Each part is a Dictionary:
##   letter    : String  sample key (single lowercase letter)
##   reveal    : int     characters of the text revealed when this part starts
##   delay     : float   seconds after the previous part's start
##   pitch     : float   final pitch scale (includes profile.base_pitch)
##   volume_db : float   offset for this part
##   syllable  : String  the syllable's letters (debug)

enum Boundary { NONE, COMMA, PERIOD, QUESTION, EXCLAIM }

const VOWELS := "aeiouyıöüâîû"
const DIGRAPHS := ["sh", "ch", "th", "ph", "ck", "ng", "qu", "wh", "gh"]


static func plan(text: String, profile: VoiceProfile, rng_seed: int = 0) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = rng.randi()
	noise.frequency = profile.drift_speed

	var words := _split_words(text)
	var parts: Array[Dictionary] = []
	var interval := 1.0 / maxf(profile.syllables_per_second, 0.1)
	var syllable_index := 0
	var pending_gap := 0.0  # pause owed before the next part

	var sentence: Array[Dictionary] = []
	for w in words.size():
		sentence.append(words[w])
		var boundary: Boundary = words[w].boundary
		var ends_sentence := boundary in [Boundary.PERIOD, Boundary.QUESTION, Boundary.EXCLAIM] \
				or w == words.size() - 1
		if not ends_sentence:
			continue

		var syllables := _sentence_syllables(sentence, profile)
		_apply_intonation(syllables, sentence, profile)
		for s in syllables.size():
			var syl: Dictionary = syllables[s]
			var drift := noise.get_noise_1d(float(syllable_index)) * 1.6
			var pitch: float = syl.pitch * (1.0 + profile.drift_amount * drift)
			pitch *= 1.0 + rng.randf_range(-profile.pitch_jitter, profile.pitch_jitter)
			var delay := 0.0
			if not parts.is_empty():
				delay = interval + pending_gap
			pending_gap = 0.0
			parts.append({
				"letter": syl.letter,
				"reveal": syl.reveal,
				"delay": delay,
				"pitch": profile.base_pitch * maxf(pitch, 0.1),
				"volume_db": syl.volume_db,
				"syllable": syl.text,
			})
			syllable_index += 1
			if syl.word_last:
				match syl.boundary:
					Boundary.COMMA:
						pending_gap = profile.comma_pause
					Boundary.PERIOD, Boundary.QUESTION, Boundary.EXCLAIM:
						pending_gap = profile.sentence_pause
					_:
						pending_gap = profile.word_pause
		sentence.clear()
	return parts


## Splits text into words of letters, recording what punctuation follows each.
static func _split_words(text: String) -> Array[Dictionary]:
	var words: Array[Dictionary] = []
	var i := 0
	var n := text.length()
	while i < n:
		if not _is_letter(text[i]):
			i += 1
			continue
		var start := i
		var chars: Array[Dictionary] = []
		while i < n and (_is_letter(text[i]) or (text[i] == "'" and i + 1 < n and _is_letter(text[i + 1]))):
			if text[i] != "'":
				chars.append({"c": text[i].to_lower(), "pos": i})
			i += 1
		var word := {"start": start, "end": i, "chars": chars, "boundary": Boundary.NONE}
		# Punctuation up to the next word decides the boundary.
		var j := i
		while j < n and not _is_letter(text[j]):
			var c := text[j]
			if c == "?":
				word.boundary = Boundary.QUESTION
			elif c == "!" and word.boundary != Boundary.QUESTION:
				word.boundary = Boundary.EXCLAIM
			elif (c == "." or c == "\n" or c == ";" or c == ":" or c == "…") and word.boundary in [Boundary.NONE, Boundary.COMMA]:
				word.boundary = Boundary.PERIOD
			elif (c == "," or c == "—" or c == "–") and word.boundary == Boundary.NONE:
				word.boundary = Boundary.COMMA
			j += 1
		words.append(word)
	return words


static func _is_letter(c: String) -> bool:
	return c.to_lower() != c.to_upper()


static func _is_vowel(c: String) -> bool:
	return VOWELS.contains(c)


## Syllables for every word of a sentence, with word/stress bookkeeping.
static func _sentence_syllables(sentence: Array[Dictionary], profile: VoiceProfile) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for w in sentence.size():
		var word: Dictionary = sentence[w]
		var syls := syllabify(word.chars, profile)
		if syls.is_empty():
			continue
		var stressed := -1
		if syls.size() >= 2:
			stressed = syls.size() - 1 if profile.stress_last_syllable else 0
		elif word.chars.size() >= 4:
			stressed = 0
		for s in syls.size():
			var syl: Dictionary = syls[s]
			syl.word_index = w
			syl.stressed = s == stressed
			syl.word_last = s == syls.size() - 1
			syl.boundary = word.boundary if syl.word_last else Boundary.NONE
			if syl.word_last:
				syl.reveal = word.end
			syl.pitch = 1.0
			syl.volume_db = 0.0
			out.append(syl)
	return out


## Heuristic syllable split. chars: [{c, pos}]. Returns [{letter, reveal, text}].
static func syllabify(chars: Array, profile: VoiceProfile) -> Array[Dictionary]:
	var n := chars.size()
	if n == 0:
		return []
	# 1) Units: digraphs and doubled consonants collapse into one sound.
	var units: Array[Dictionary] = []
	var i := 0
	while i < n:
		var c: String = chars[i].c
		var take := 1
		if i + 1 < n:
			var pair: String = c + chars[i + 1].c
			if pair in DIGRAPHS or (chars[i + 1].c == c and not _is_vowel(c)):
				take = 2
		var vowel := _is_vowel(c) and take == 1
		if c == "y" and i == 0 and n > 1 and _is_vowel(chars[1].c):
			vowel = false  # "yes", "you": consonant y
		var text := ""
		for k in take:
			text += chars[i + k].c
		units.append({"text": text, "vowel": vowel, "end_pos": chars[i + take - 1].pos})
		i += take

	# 2) Silent final e ("time", "here") when another vowel exists.
	if profile.silent_final_e and units.size() >= 3:
		var last: Dictionary = units[-1]
		if last.text == "e" and not units[-2].vowel:
			for k in units.size() - 2:
				if units[k].vowel:
					last.vowel = false
					break

	# 3) Nuclei: runs of vowel units.
	var nuclei: Array[Vector2i] = []  # (first unit, last unit)
	var u := 0
	while u < units.size():
		if units[u].vowel:
			var first := u
			while u + 1 < units.size() and units[u + 1].vowel:
				u += 1
			nuclei.append(Vector2i(first, u))
		u += 1

	if nuclei.is_empty():
		var whole := ""
		for unit in units:
			whole += unit.text
		return [{"letter": units[0].text[0], "reveal": units[-1].end_pos + 1, "text": whole}]

	# 4) Boundaries: V-CV for one consonant, VC-CV for clusters.
	var starts: Array[int] = [0]
	for k in range(1, nuclei.size()):
		var gap_first := nuclei[k - 1].y + 1
		var gap := nuclei[k].x - gap_first
		if gap <= 0:
			starts.append(nuclei[k].x)
		elif gap == 1:
			starts.append(gap_first)
		else:
			starts.append(gap_first + 1)

	var out: Array[Dictionary] = []
	for k in nuclei.size():
		var from: int = starts[k]
		var to: int = (starts[k + 1] if k + 1 < starts.size() else units.size())
		var text := ""
		for x in range(from, to):
			text += units[x].text
		var letter: String = units[nuclei[k].x].text[0]
		if profile.syllable_sample == VoiceProfile.SyllableSample.ONSET:
			letter = units[from].text[0]
		out.append({"letter": letter, "reveal": units[to - 1].end_pos + 1, "text": text})
	return out


## Pitch/volume contour over one sentence (before drift and base pitch).
static func _apply_intonation(syls: Array[Dictionary], sentence: Array[Dictionary], profile: VoiceProfile) -> void:
	var n := syls.size()
	if n == 0:
		return
	var ending: Boundary = sentence[-1].boundary
	var is_question := ending == Boundary.QUESTION
	var declination := profile.declination * (0.5 if is_question else 1.0)
	for i in n:
		var syl: Dictionary = syls[i]
		var t := float(i) / float(maxi(n - 1, 1))
		var p := 1.0 + declination * (0.5 - t)
		if ending == Boundary.EXCLAIM:
			p *= 1.0 + profile.exclamation_lift
		if syl.stressed:
			p *= 1.0 + profile.stress_pitch
			syl.volume_db += profile.stress_volume_db
		if syl.boundary == Boundary.COMMA:
			p *= 1.0 + profile.comma_rise
		syl.pitch = p

	match ending:
		Boundary.QUESTION:
			var k := mini(profile.question_rise_syllables, n)
			for j in k:
				syls[n - k + j].pitch *= 1.0 + profile.question_rise * float(j + 1) / float(k)
		Boundary.EXCLAIM:
			syls[n - 1].pitch *= 1.0 - profile.final_fall * 0.5
		_:
			syls[n - 1].pitch *= 1.0 - profile.final_fall
			syls[n - 1].volume_db -= 1.5
			if n >= 2:
				syls[n - 2].pitch *= 1.0 - profile.final_fall * 0.35

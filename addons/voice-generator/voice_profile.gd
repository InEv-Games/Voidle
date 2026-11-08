@tool
class_name VoiceProfile
extends Resource
## One character's voice: sample bank, base pitch and the syllable/intonation
## settings used by VoiceAudioStreamPlayer's natural mode. Assign it with
## VoiceAudioStreamPlayer.apply_profile().

enum SyllableSample {
	## Each syllable plays its vowel's sample (smoother, more "sung").
	NUCLEUS,
	## Each syllable plays its first letter's sample (more consonant texture).
	ONSET,
}

enum VoiceEngine { NATURAL, CLASSIC, SYSTEM_TTS }

const LETTERS :="abcdefghijklmnopqrstuvwxyz"
## Turkish letters fall back to their closest Latin sample.
const LETTER_FALLBACK := {"ç": "c", "ğ": "g", "ı": "i", "ö": "o", "ş": "s", "ü": "u"}

@export_group("Voice")
## Folder holding a.wav … z.wav.
@export_dir var sample_dir := "res://addons/voice-generator/sound/alphabet/med"
@export_range(0.25, 4.0, 0.01) var base_pitch := 1.5
@export_range(-30.0, 12.0, 0.1) var volume_db := 0.0
## NATURAL = syllable babble with intonation. CLASSIC = the original
## letter-by-letter babble (for A/B). SYSTEM_TTS = the OS speech voice via
## DisplayServer.tts_speak() (needs audio/general/text_to_speech enabled;
## does not go through audio buses).
@export var voice_engine := VoiceEngine.NATURAL

@export_group("Syllables")
@export_range(1.0, 12.0, 0.1) var syllables_per_second := 5.5
@export var syllable_sample := SyllableSample.NUCLEUS
@export_range(0.0, 1.0, 0.005) var word_pause := 0.05
@export_range(0.0, 1.0, 0.005) var comma_pause := 0.18
@export_range(0.0, 2.0, 0.01) var sentence_pause := 0.38
## English-style silent final "e" (time, here, some).
@export var silent_final_e := true
## Stress the last syllable of a word (Turkish) instead of the first (English).
@export var stress_last_syllable := false

@export_group("Intonation")
## Pitch falls this much from the start to the end of a sentence.
@export_range(0.0, 0.5, 0.005) var declination := 0.12
## Extra drop on the last syllable of a statement.
@export_range(0.0, 0.5, 0.005) var final_fall := 0.10
## Rise over the last syllables of a question.
@export_range(0.0, 1.0, 0.01) var question_rise := 0.30
@export_range(1, 6, 1) var question_rise_syllables := 3
## Whole sentence is raised by this much when it ends with "!".
@export_range(0.0, 0.5, 0.005) var exclamation_lift := 0.10
## Small rise before a comma ("there is more to come").
@export_range(0.0, 0.3, 0.005) var comma_rise := 0.05
@export_range(0.0, 0.3, 0.005) var stress_pitch := 0.06
@export_range(0.0, 6.0, 0.1) var stress_volume_db := 2.0
## Slow, smooth pitch wander across syllables (replaces per-letter jumps).
@export_range(0.0, 0.3, 0.005) var drift_amount := 0.05
@export_range(0.01, 1.0, 0.01) var drift_speed := 0.25
## Tiny independent per-syllable variation on top of the smooth drift.
@export_range(0.0, 0.1, 0.001) var pitch_jitter := 0.01

@export_group("System TTS")
## OS voice id (DisplayServer.tts_get_voices()). Empty = first voice for tts_language.
@export var tts_voice_id := ""
@export var tts_language := "en"
@export_range(0.0, 2.0, 0.01) var tts_pitch := 1.0
@export_range(0.1, 3.0, 0.01) var tts_rate := 1.0
@export_range(0, 100, 1) var tts_volume := 80

var _alphabet_cache: Dictionary = {}
var _alphabet_cache_dir := ""


## Voice id to pass to tts_speak(): tts_voice_id if installed, otherwise the
## first voice for tts_language, otherwise the first voice at all ("" if none).
func resolve_tts_voice() -> String:
	var all := DisplayServer.tts_get_voices()
	for v in all:
		if v.get("id", "") == tts_voice_id and not tts_voice_id.is_empty():
			return tts_voice_id
	# Best voice for the language: premium/enhanced first, novelty voices last.
	var best := ""
	var best_score := -1000
	for id in DisplayServer.tts_get_voices_for_language(tts_language):
		var score := _tts_voice_score(id)
		if score > best_score:
			best = id
			best_score = score
	if not best.is_empty():
		return best
	return all[0].get("id", "") if not all.is_empty() else ""


static func _tts_voice_score(id: String) -> int:
	var lower := id.to_lower()
	if lower.contains("premium"):
		return 3
	if lower.contains("enhanced") or lower.contains("neural"):
		return 2
	if lower.contains("speech.synthesis.voice"):
		return -1  # macOS novelty voices (Bells, Zarvox, …)
	return 0


## Letter -> AudioStream for this profile's sample_dir (cached).
func load_alphabet() -> Dictionary:
	if _alphabet_cache_dir == sample_dir and not _alphabet_cache.is_empty():
		return _alphabet_cache
	var mapping := {}
	var dir := sample_dir.trim_suffix("/") + "/"
	for letter in LETTERS:
		var path := dir + letter + ".wav"
		if ResourceLoader.exists(path):
			mapping[letter] = load(path)
	for tr_letter in LETTER_FALLBACK:
		if mapping.has(LETTER_FALLBACK[tr_letter]):
			mapping[tr_letter] = mapping[LETTER_FALLBACK[tr_letter]]
	_alphabet_cache = mapping
	_alphabet_cache_dir = sample_dir
	return mapping

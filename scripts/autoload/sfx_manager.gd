extends Node
## SfxManager — procedural placeholder SFX system.
## Generates 13 WAV sounds on _ready() and exposes play("sound_name") API.
## Uses a pool of 8 AudioStreamPlayer nodes for polyphonic playback.

var _sounds: Dictionary = {}  # name -> AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0

const POOL_SIZE := 8
const SAMPLE_RATE := 44100

func _ready() -> void:
	_create_player_pool()
	_generate_all_sounds()

func _create_player_pool() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)

func play(sound_name: String) -> void:
	if not _sounds.has(sound_name):
		return
	var vol: float = GameManager.settings.get("master_volume", 1.0) * GameManager.settings.get("sfx_volume", 1.0)
	if vol <= 0.0:
		return
	var player: AudioStreamPlayer = _players[_next_player]
	player.stream = _sounds[sound_name]
	player.volume_db = linear_to_db(vol)
	player.play()
	_next_player = (_next_player + 1) % POOL_SIZE

func _generate_all_sounds() -> void:
	_sounds["ui_navigate"] = _gen_sine(800.0, 0.04)
	_sounds["ui_select"] = _gen_sine(1200.0, 0.08)
	_sounds["ui_confirm"] = _gen_chord([1000.0, 1500.0], 0.1)
	_sounds["ui_back"] = _gen_sine(400.0, 0.1)
	_sounds["attack_hit"] = _gen_noise(0.08)
	_sounds["attack_miss"] = _gen_filtered_noise(200.0, 0.12)
	_sounds["judgment_perfect"] = _gen_chord([1400.0, 1800.0], 0.15)
	_sounds["judgment_great"] = _gen_sine(1100.0, 0.12)
	_sounds["judgment_good"] = _gen_sine(800.0, 0.1)
	_sounds["judgment_bad"] = _gen_sine(350.0, 0.1)
	_sounds["unit_death"] = _gen_sweep(600.0, 150.0, 0.3)
	_sounds["battle_victory"] = _gen_arpeggio(500.0, 1200.0, 0.5)
	_sounds["battle_defeat"] = _gen_arpeggio(500.0, 200.0, 0.6)

func _gen_sine(freq: float, duration: float) -> AudioStreamWAV:
	var num_samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = 1.0 - (float(i) / float(num_samples))
		var sample: float = sin(t * freq * TAU) * envelope * 0.5
		var s16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return _make_wav(data)

func _gen_chord(freqs: Array, duration: float) -> AudioStreamWAV:
	var num_samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	var amp: float = 0.5 / float(freqs.size())
	for i in num_samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = 1.0 - (float(i) / float(num_samples))
		var sample: float = 0.0
		for freq in freqs:
			sample += sin(t * freq * TAU)
		sample *= amp * envelope
		var s16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return _make_wav(data)

func _gen_noise(duration: float) -> AudioStreamWAV:
	var num_samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var envelope: float = 1.0 - (float(i) / float(num_samples))
		var sample: float = (randf() * 2.0 - 1.0) * envelope * 0.4
		var s16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return _make_wav(data)

func _gen_filtered_noise(freq: float, duration: float) -> AudioStreamWAV:
	var num_samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = 1.0 - (float(i) / float(num_samples))
		var noise: float = randf() * 2.0 - 1.0
		var tone: float = sin(t * freq * TAU)
		var sample: float = (noise * 0.3 + tone * 0.2) * envelope
		var s16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return _make_wav(data)

func _gen_sweep(start_freq: float, end_freq: float, duration: float) -> AudioStreamWAV:
	var num_samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	var phase := 0.0
	for i in num_samples:
		var progress: float = float(i) / float(num_samples)
		var freq: float = lerp(start_freq, end_freq, progress)
		phase += freq * TAU / float(SAMPLE_RATE)
		var envelope: float = 1.0 - progress
		var sample: float = sin(phase) * envelope * 0.5
		var s16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return _make_wav(data)

func _gen_arpeggio(start_freq: float, end_freq: float, duration: float) -> AudioStreamWAV:
	var num_samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	var steps := 5
	var phase := 0.0
	for i in num_samples:
		var progress: float = float(i) / float(num_samples)
		var step: int = mini(int(progress * steps), steps - 1)
		var step_progress: float = float(step) / float(steps - 1)
		var freq: float = lerp(start_freq, end_freq, step_progress)
		phase += freq * TAU / float(SAMPLE_RATE)
		var envelope: float = 1.0 - progress
		var sample: float = sin(phase) * envelope * 0.4
		var s16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return _make_wav(data)

func _make_wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

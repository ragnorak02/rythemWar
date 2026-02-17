extends Node
## Conductor — master beat clock + audio sync.
## Uses system clock approach (Time.get_ticks_usec() - AudioServer latency)
## for drift-proof timing. All rhythm systems read song_position from here.

signal beat_hit(beat_number: int)
signal measure_hit(measure_number: int)

var bpm: float = 100.0
var beat_length: float = 0.6  # seconds per beat (60/bpm)
var song_position: float = 0.0  # current position in seconds
var song_position_in_beats: float = 0.0
var last_reported_beat: int = -1
var offset_sec: float = 0.0  # chart offset

var _audio_player: AudioStreamPlayer = null
var _start_time_usec: int = 0
var _playing: bool = false
var _paused: bool = false

func _ready() -> void:
	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = "Master"
	add_child(_audio_player)
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_song(stream: AudioStream, song_bpm: float, song_offset: float = 0.0) -> void:
	bpm = song_bpm
	beat_length = 60.0 / bpm
	offset_sec = song_offset
	song_position = 0.0
	song_position_in_beats = 0.0
	last_reported_beat = -1
	_audio_player.stream = stream
	_audio_player.play()
	_start_time_usec = Time.get_ticks_usec()
	_playing = true
	_paused = false

func stop_song() -> void:
	_audio_player.stop()
	_playing = false
	_paused = false
	song_position = 0.0
	song_position_in_beats = 0.0
	last_reported_beat = -1

func pause_song() -> void:
	if _playing and not _paused:
		_audio_player.stream_paused = true
		_paused = true

func resume_song() -> void:
	if _playing and _paused:
		_audio_player.stream_paused = false
		_start_time_usec = Time.get_ticks_usec() - int(song_position * 1_000_000.0)
		_paused = false

func is_playing() -> bool:
	return _playing and not _paused

func _process(_delta: float) -> void:
	if not _playing or _paused:
		return

	# System clock approach: use AudioServer playback position for drift-proof sync
	var audio_time: float = _audio_player.get_playback_position()
	var latency: float = AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	song_position = audio_time + latency - offset_sec

	song_position_in_beats = song_position / beat_length

	var current_beat: int = int(floor(song_position_in_beats))
	if current_beat > last_reported_beat and current_beat >= 0:
		last_reported_beat = current_beat
		beat_hit.emit(current_beat)
		if current_beat % 4 == 0:
			measure_hit.emit(current_beat / 4)

	# Check if song ended
	if not _audio_player.playing and _playing:
		_playing = false
		Events.song_finished.emit()

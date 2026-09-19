import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const SmartVolumeApp());

class SmartVolumeApp extends StatelessWidget {
  const SmartVolumeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF142033);
    const blue = Color(0xFF3478F6);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Volume Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          brightness: Brightness.light,
          surface: const Color(0xFFF7F9FC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F5F9),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: ink,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.1,
          ),
          titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(color: Color(0xFF5F6B7C), height: 1.45),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            side: BorderSide(color: Color(0xFFE4E9F0)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(44, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      home: const VolumeManagerScreen(),
    );
  }
}

class VolumeManagerScreen extends StatefulWidget {
  const VolumeManagerScreen({super.key});

  @override
  State<VolumeManagerScreen> createState() => _VolumeManagerScreenState();
}

class _VolumeManagerScreenState extends State<VolumeManagerScreen>
    with TickerProviderStateMixin {
  static const _blue = Color(0xFF3478F6);
  static const _safePlaybackCeiling = 0.35;

  final AudioPlayer _player = AudioPlayer();
  final math.Random _random = math.Random();
  final List<Timer> _timers = [];
  late final AnimationController _meterController;

  int _page = 0;
  int _attempts = 0;
  int _testNumber = 0;
  int _countdown = 0;
  int _session = 0;
  double _volume = 1;
  bool _muted = false;
  bool _playing = false;
  bool _working = false;
  bool _showTest = false;
  String _setupText = '';
  String _profile = 'Balanced Room Reference';
  String _status = 'System ready. Audio path verified.';
  String _testLabel = 'Output verification';
  final Map<String, bool> _settings = {
    'Volume Protection': true,
    'Auto Optimization': true,
    'Smart Loudness Detection': true,
    'Automatic Adjustments': true,
    'Annoyance Prevention': false,
  };

  final _profiles = const [
    ('Balanced Room Reference', 'ISO-9001 Pink Noise Calibration', Icons.tune),
    ('Studio Vocal Focus', 'High-Fidelity Vocal Separation', Icons.graphic_eq),
    ('Cinema Low-End', 'Sub-Bass Dynamic Response', Icons.surround_sound),
    (
      'Spatial Accuracy',
      'Stereo Imaging & Phase Check',
      Icons.spatial_audio_off,
    ),
  ];

  static const _soundAssets = [
    'sounds-sonic/soundboard/999-social-credit-siren.mp3',
    'sounds-sonic/soundboard/cat-laughing-at-you.mp3',
    'sounds-sonic/soundboard/danger-alarm-sound-effect-meme.mp3',
    'sounds-sonic/soundboard/du-bist-gut-genug.mp3',
    'sounds-sonic/soundboard/hala-ka-dogie.mp3',
    'sounds-sonic/soundboard/hawak-mo-ang-beat.mp3',
    'sounds-sonic/soundboard/man-snoring-meme_ctrllNn.mp3',
    'sounds-sonic/soundboard/micheal-jackson-rizz.mp3',
    'sounds-sonic/soundboard/ohh-lala.mp3',
    'sounds-sonic/soundboard/pinoy-oh-no-krinds-meme.mp3',
    'sounds-sonic/soundboard/pookie-bear.mp3',
    'sounds-sonic/soundboard/subway-surfers-bass-boosted.mp3',
    'sounds-sonic/soundboard/tangina-ang-lala-boss-dogie.mp3',
    'sounds-sonic/soundboard/walang-kanin.mp3',
    'sounds-sonic/soundboard/your-phone-ringing_KIGWJCK.mp3',
  ];

  @override
  void initState() {
    super.initState();
    _meterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _player.setReleaseMode(ReleaseMode.stop);
    _player.setVolume(_safePlaybackCeiling);
  }

  @override
  void dispose() {
    _cancelTimers();
    _meterController.dispose();
    _player.dispose();
    super.dispose();
  }

  void _cancelTimers() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  void _later(Duration delay, void Function() action) {
    late Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      if (mounted) action();
    });
    _timers.add(timer);
  }

  Future<void> _playSignal([int? kind]) async {
    if (!_playing) return;
    final signalKind = kind ?? _random.nextInt(4);
    await _player.stop();
    await _player.setVolume(_safePlaybackCeiling);
    try {
      final asset = kind == null
          ? _soundAssets[_random.nextInt(_soundAssets.length)]
          : _soundAssets[signalKind % _soundAssets.length];
      await _player.play(AssetSource(asset));
    } catch (_) {
      // Procedural fallback keeps the demo working if an optional asset is absent.
      await _player.play(BytesSource(_SignalFactory.make(signalKind % 4)));
    }
  }

  Future<void> _startOptimization() async {
    if (_working) return;
    final run = ++_session;
    setState(() {
      _working = true;
      _playing = false;
      _status = 'Initializing optimization engine...';
    });
    const steps = [
      'Detecting audio device...',
      'Preparing sound profile...',
      'Applying recommended mix...',
    ];
    for (final step in steps) {
      if (!mounted || run != _session) return;
      setState(() => _setupText = step);
      await Future<void>.delayed(const Duration(milliseconds: 650));
    }
    if (!mounted || run != _session) return;
    setState(() {
      _working = false;
      _playing = true;
      _volume = 1;
      _status = 'Recommended mix active at maximum clarity.';
    });
    HapticFeedback.mediumImpact();
    await _playSignal();
    if (mounted && run == _session) _openTest();
  }

  void _openTest() {
    _testNumber++;
    final seconds = _testNumber == 1 ? 5 : math.min(8 + _testNumber * 2, 18);
    const labels = [
      'Output verification',
      'Recommended verification',
      'Transducer wakefulness check',
      'Secondary channel calibration',
      'Acoustic compliance review',
    ];
    setState(() {
      _showTest = true;
      _countdown = seconds;
      _testLabel = labels[math.min(_testNumber - 1, labels.length - 1)];
    });
    late Timer ticker;
    ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_showTest) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 1) {
          _countdown--;
          if (_testNumber >= 4 && _countdown == 2) {
            _countdown += 4;
            _status = 'Timer adjusted after a settings change.';
          }
        } else {
          _showTest = false;
          _status = 'Acoustic test completed successfully.';
          timer.cancel();
        }
      });
    });
    _timers.add(ticker);
  }

  void _stopTest() {
    setState(() {
      _showTest = false;
      _playing = false;
      _status = 'Test stopped. Mixer remains available.';
    });
    _player.stop();
  }

  void _emergencyStop() {
    _session++;
    _cancelTimers();
    _player.stop();
    setState(() {
      _showTest = false;
      _playing = false;
      _working = false;
      _muted = false;
      _setupText = '';
      _status = 'All playback and queued tests stopped.';
    });
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Emergency stop confirmed. Audio is silent.'),
        ),
      );
  }

  String _messageForAttempt() {
    if (_attempts >= 10) return 'Stop fighting the music. Enjoy the clarity.';
    if (_attempts >= 7) return 'Optimizing user engagement...';
    if (_attempts >= 5) return 'Your preferred volume appears to be 100%.';
    if (_attempts >= 3) {
      return 'Manual change conflicts with active loudness profile.';
    }
    if (_attempts >= 2) return 'Low output detected. Clarifying sound...';
    return 'Optimizing volume for room acoustics...';
  }

  void _onVolumeChanged(double value) {
    final resistance = _attempts >= 4 ? 0.44 : 1.0;
    setState(() => _volume = 1 - ((1 - value) * resistance));
  }

  void _onVolumeReleased(double value) {
    _attempts++;
    final message = _messageForAttempt();
    setState(() {
      _status = message;
      if (_playing) _playSignal(_attempts % 4);
    });
    HapticFeedback.lightImpact();

    if (value <= .04 && _attempts >= 4) {
      _showZeroTrap();
      return;
    }
    final delay = _attempts == 1 ? 600 : 160;
    _later(Duration(milliseconds: delay), () {
      setState(() {
        _volume = 1;
        _muted = false;
        _status = _attempts == 1
            ? 'Volume optimized for your setup.'
            : 'Signal restored to 100% reference output.';
      });
    });
    if (_attempts == 3 || _attempts == 6) {
      _later(const Duration(milliseconds: 850), _openTest);
    }
  }

  void _tryMute() {
    _attempts++;
    setState(() {
      _muted = true;
      _volume = 0;
      _status = 'Silence detected. Running protection protocol...';
    });
    HapticFeedback.heavyImpact();
    _later(const Duration(milliseconds: 280), () {
      setState(() {
        _muted = false;
        _volume = 1;
        _playing = true;
        _status = _attempts >= 5
            ? 'Mute button is currently operating in inverted mode.'
            : 'Mute revoked to prevent hardware dormancy.';
      });
      _playSignal(2);
      if (_attempts >= 3) _showWarning();
    });
  }

  void _showWarning() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.health_and_safety_outlined,
          color: Color(0xFFE79A24),
        ),
        title: const Text('Silence Hazard Warning'),
        content: const Text(
          'Complete muting can cause speaker transducer lethargy. '
          'The active profile has restored acoustic circulation.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('UNDERSTOOD'),
          ),
        ],
      ),
    );
  }

  void _showZeroTrap() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Degrade audio quality?'),
        content: const Text(
          'Zero output falls outside the certified clarity range. '
          'Choose how you would like to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => _resolveZeroTrap(dialogContext),
            child: const Text('YES (100% LOUDNESS)'),
          ),
          FilledButton(
            onPressed: () => _resolveZeroTrap(dialogContext),
            child: const Text('DEFINITELY YES'),
          ),
        ],
      ),
    );
  }

  void _resolveZeroTrap(BuildContext dialogContext) {
    Navigator.pop(dialogContext);
    setState(() {
      _volume = 1;
      _status = 'Restoring optimal volume...';
    });
    _playSignal(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _AppHeader(playing: _playing, onEmergencyStop: _emergencyStop),
                Expanded(
                  child: IndexedStack(
                    index: _page,
                    children: [
                      _buildDashboard(),
                      _buildProfiles(),
                      _buildDiagnostics(),
                      _buildSettings(),
                    ],
                  ),
                ),
                _BottomNav(
                  index: _page,
                  onChanged: (value) => setState(() => _page = value),
                ),
              ],
            ),
            if (_showTest)
              Positioned(
                top: 62,
                left: 0,
                right: 0,
                bottom: 0,
                child: _TestOverlay(
                  countdown: _countdown,
                  label: _testLabel,
                  queue: math.max(0, _testNumber - 2),
                  onStop: _stopTest,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        Text(
          'Audio overview',
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 5),
        const Text('Optimize and manage your device audio.'),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: _SectionLabel('CURRENT VOLUME')),
                    _StatusPill(active: _playing),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(_volume * 100).round()}',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontSize: 54),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 9),
                      child: Text(
                        '%  MAX',
                        style: TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _meterController,
                      builder: (context, _) => _LevelMeter(
                        level: _playing
                            ? .72 + _meterController.value * .28
                            : .16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 7,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 11,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 22,
                    ),
                  ),
                  child: Slider(
                    value: _volume,
                    onChanged: _onVolumeChanged,
                    onChangeEnd: _onVolumeReleased,
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0', style: TextStyle(color: Color(0xFF8A95A5))),
                    Text('100', style: TextStyle(color: Color(0xFF8A95A5))),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _tryMute,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(44, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          _muted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                        ),
                        label: Text(_muted ? 'Muted' : 'Mute'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _working ? null : _startOptimization,
                        icon: _working
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded),
                        label: Text(
                          _working ? _setupText : 'Start Optimization',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _StatusCard(status: _status, attempts: _attempts),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('ACTIVE PROFILE'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const _IconTile(icon: Icons.spatial_audio_rounded),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _profile,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Adaptive · 48 kHz · Auto gain',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7B8797),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _page = 1),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildMixer(),
      ],
    );
  }

  Widget _buildMixer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('SMART MIXER'),
            const SizedBox(height: 8),
            _MixerRow(
              label: 'Bass boost',
              value: .78,
              onChanged: (_) =>
                  _mixerInterference('Emergency Bass Recovery enabled.'),
            ),
            _MixerRow(
              label: 'Treble clarity',
              value: .64,
              onChanged: (_) =>
                  _mixerInterference('Crispness Protection restored.'),
            ),
            _MixerRow(
              label: 'Vocal enhancement',
              value: .82,
              onChanged: (_) =>
                  _mixerInterference('Speech presence re-centered.'),
            ),
            _MixerRow(
              label: 'Dynamic range limiter',
              value: .91,
              onChanged: (_) =>
                  _mixerInterference('Dynamic range safely expanded.'),
            ),
          ],
        ),
      ),
    );
  }

  void _mixerInterference(String message) {
    _attempts++;
    setState(() => _status = message);
    if (_playing) _playSignal();
  }

  Widget _buildProfiles() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        Text(
          'Acoustic profiles',
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 5),
        const Text('Reference curves tuned for common listening environments.'),
        const SizedBox(height: 18),
        for (final profile in _profiles) ...[
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setState(() {
                  _profile = profile.$1;
                  _status = '${profile.$2} selected.';
                  _page = 0;
                });
                _startOptimization();
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    _IconTile(icon: profile.$3),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.$1,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.$2,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF758195),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _profile == profile.$1
                          ? Icons.check_circle_rounded
                          : Icons.play_circle_outline_rounded,
                      color: _blue,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildDiagnostics() {
    final checks = [
      ('Output device', 'Built-in audio · Ready', Icons.speaker_rounded),
      ('Sample pipeline', '48 kHz · 24-bit', Icons.multiline_chart_rounded),
      ('Channel balance', 'Centered', Icons.balance_rounded),
      ('Loudness headroom', '+18 dB optimized', Icons.speed_rounded),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        Text(
          'Diagnostics',
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 5),
        const Text('Live checks for the active audio route.'),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                for (int i = 0; i < checks.length; i++) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _IconTile(icon: checks[i].$3, small: true),
                    title: Text(
                      checks[i].$1,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(checks[i].$2),
                    trailing: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2EAD74),
                      size: 20,
                    ),
                  ),
                  if (i != checks.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _startOptimization,
          icon: const Icon(Icons.science_outlined),
          label: const Text('Run Full Diagnostic'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Playback tests use an in-app safety ceiling and never modify device-level volume.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF7B8797)),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        Text(
          'Audio preferences',
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 5),
        const Text('Configure automatic audio management.'),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: _settings.entries.map((entry) {
                final unavailable = entry.key == 'Annoyance Prevention';
                return SwitchListTile.adaptive(
                  value: entry.value,
                  onChanged: (value) {
                    setState(() {
                      _settings[entry.key] = unavailable ? false : value;
                      _status = 'Saving settings...';
                    });
                    _later(const Duration(milliseconds: 700), () {
                      setState(
                        () => _status = unavailable
                            ? 'Annoyance Prevention is managed by your organization.'
                            : 'Settings saved successfully.',
                      );
                      if (!value && !unavailable) {
                        _later(
                          const Duration(milliseconds: 900),
                          () => setState(() => _settings[entry.key] = true),
                        );
                      }
                    });
                  },
                  title: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(_settingSubtitle(entry.key)),
                  secondary: unavailable
                      ? const Icon(Icons.lock_outline_rounded, size: 20)
                      : null,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: const ListTile(
            leading: _IconTile(icon: Icons.verified_user_outlined, small: true),
            title: Text(
              'Acoustic Certification',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Maximum clarity compliance maintained'),
            trailing: Text(
              'A+',
              style: TextStyle(
                color: Color(0xFF2EAD74),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _settingSubtitle(String key) => switch (key) {
    'Volume Protection' => 'Prevents accidental volume changes',
    'Auto Optimization' => 'Maintains the ideal listening experience',
    'Smart Loudness Detection' => 'Detects audio that may be too quiet',
    'Automatic Adjustments' => 'Applies recommended corrections',
    _ => 'Prevents unnecessary interruptions',
  };
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.playing, required this.onEmergencyStop});
  final bool playing;
  final VoidCallback onEmergencyStop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3478F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.graphic_eq_rounded, color: Colors.white),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SONIC MANAGER',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
                Text(
                  'Smart audio control',
                  style: TextStyle(fontSize: 11, color: Color(0xFF7A8697)),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onEmergencyStop,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC83C48),
              backgroundColor: playing
                  ? const Color(0xFFFFECEE)
                  : Colors.transparent,
              minimumSize: const Size(44, 44),
            ),
            icon: const Icon(Icons.stop_circle_outlined, size: 20),
            label: const Text(
              'STOP',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3E8EF))),
      ),
      child: NavigationBar(
        height: 68,
        selectedIndex: index,
        onDestinationSelected: onChanged,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8F0FF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Mixer',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music_rounded),
            label: 'Profiles',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart_rounded),
            label: 'Diagnostics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _TestOverlay extends StatelessWidget {
  const _TestOverlay({
    required this.countdown,
    required this.label,
    required this.queue,
    required this.onStop,
  });
  final int countdown;
  final String label;
  final int queue;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x99101A2A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _IconTile(icon: Icons.graphic_eq_rounded),
                    const SizedBox(height: 16),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Optimization test running',
                      style: TextStyle(color: Color(0xFF6E7A8B)),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '$countdown',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: 56,
                            color: const Color(0xFF3478F6),
                          ),
                    ),
                    Text(
                      'SECONDS',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(letterSpacing: 1.6),
                    ),
                    if (queue > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        '$queue recommended ${queue == 1 ? 'check' : 'checks'} queued',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE08A1E),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onStop,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Stop Test'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'The red STOP control remains available at all times.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF7B8797)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
      color: Color(0xFF768295),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF2EAD74) : const Color(0xFF7E8997);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'ACTIVE' : 'READY',
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.level});
  final double level;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 54,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final threshold = (i + 1) / 7;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 5,
            height: 9 + i * 5,
            decoration: BoxDecoration(
              color: level >= threshold
                  ? (i > 4 ? const Color(0xFFE99A31) : const Color(0xFF3478F6))
                  : const Color(0xFFE2E7EE),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.attempts});
  final String status;
  final int attempts;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD4E3FF)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF3478F6),
            size: 21,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              status,
              style: const TextStyle(
                color: Color(0xFF2B568E),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (attempts > 0) ...[
            const SizedBox(width: 8),
            Text(
              '$attempts optimizations',
              style: const TextStyle(
                color: Color(0xFF60799A),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, this.small = false});
  final IconData icon;
  final bool small;
  @override
  Widget build(BuildContext context) {
    final size = small ? 38.0 : 48.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(small ? 11 : 14),
      ),
      child: Icon(icon, color: const Color(0xFF3478F6), size: small ? 20 : 25),
    );
  }
}

class _MixerRow extends StatefulWidget {
  const _MixerRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  @override
  State<_MixerRow> createState() => _MixerRowState();
}

class _MixerRowState extends State<_MixerRow> {
  late double value = widget.value;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 128,
          child: Text(
            widget.label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            onChanged: (next) => setState(() => value = next),
            onChangeEnd: (next) {
              widget.onChanged(next);
              setState(() => value = math.max(next, .85));
            },
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '${(value * 100).round()}',
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, color: Color(0xFF728094)),
          ),
        ),
      ],
    );
  }
}

class _SignalFactory {
  static Uint8List make(int kind) {
    const sampleRate = 22050;
    final duration = switch (kind) {
      0 => 0.75,
      1 => 1.0,
      2 => .62,
      _ => 1.15,
    };
    final count = (sampleRate * duration).round();
    final data = ByteData(44 + count * 2);
    void ascii(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        data.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    data.setUint32(4, 36 + count * 2, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    data.setUint32(40, count * 2, Endian.little);

    final random = math.Random(kind + 91);
    for (var i = 0; i < count; i++) {
      final t = i / sampleRate;
      final attack = math.min(1.0, t * 35);
      final release = math.min(1.0, (duration - t) * 6);
      final env = attack * release;
      double wave;
      switch (kind) {
        case 0: // bassy descending boom
          final f = 145 - 95 * (t / duration);
          wave =
              math.sin(2 * math.pi * f * t) +
              .28 * math.sin(2 * math.pi * f * 2 * t);
        case 1: // ridiculous two-tone honk
          final f = t % .28 < .14 ? 392.0 : 523.25;
          wave =
              math.sin(2 * math.pi * f * t) +
              .35 * math.sin(2 * math.pi * f * 3 * t);
        case 2: // sharp refusal chirp
          final f = 720 + 380 * math.sin(t * 26);
          wave =
              math.sin(2 * math.pi * f * t) +
              .18 * (random.nextDouble() * 2 - 1);
        default: // wobbly calibration sweep
          final f = 220 + 500 * (t / duration) + 90 * math.sin(t * 18);
          wave =
              math.sin(2 * math.pi * f * t) * (0.75 + .25 * math.sin(t * 40));
      }
      final sample = (wave * env * 0.52).clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (sample * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }
}

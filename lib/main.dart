import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const SonicMixerApp());
}

class SonicMixerApp extends StatelessWidget {
  const SonicMixerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Audio Calibration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Courier',
        scaffoldBackgroundColor: const Color(0xFF008080), // Classic Win95 Teal
      ),
      home: const Win95WizardPage(),
    );
  }
}

class Win95WizardPage extends StatefulWidget {
  const Win95WizardPage({super.key});

  @override
  State<Win95WizardPage> createState() => _Win95WizardPageState();
}

class _Win95WizardPageState extends State<Win95WizardPage> {
  // State variables
  bool _isOptimizing = false;
  int _attemptCount = 0;
  int _optimizationRunCount = 0;
  String _statusMessage = 'SoundBlaster 16 Ready. Mobile Volume: 100% Locked.';
  bool _isStartMenuOpen = false;

  // Audio players
  late final AudioPlayer _loopPlayer;
  late final AudioPlayer _sfxPlayer;

  // Active timer
  Timer? _countdownTimer;

  // Curated Meme Audios from user collection
  final List<String> _calibrationTracks = [
    'audio/subway-surfers-bass-boosted.mp3',
    'audio/samba-janeiro-full.mp3',
    'audio/danger-alarm-sound-effect-meme.mp3',
    'audio/pantropiko.mp3',
  ];

  final List<String> _resistanceSfx = [
    'audio/hala-ka-dogie.mp3',
    'audio/cat-laughing-at-you.mp3',
    'audio/hawak-mo-ang-beat.mp3',
    'audio/tangina-ang-lala-boss-dogie.mp3',
  ];

  @override
  void initState() {
    super.initState();
    _loopPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();
    _loopPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _loopPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  Future<void> _playCalibrationAudio() async {
    try {
      await _loopPlayer.stop();
      await _loopPlayer.setVolume(1.0);
      final track = _calibrationTracks[(_optimizationRunCount - 1) % _calibrationTracks.length];
      await _loopPlayer.play(AssetSource(track));
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  Future<void> _playSfx(String sfxPath) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(1.0);
      await _sfxPlayer.play(AssetSource(sfxPath));
    } catch (e) {
      debugPrint('SFX play error: $e');
    }
  }

  Future<void> _stopAllAudio() async {
    try {
      await _loopPlayer.stop();
      await _sfxPlayer.stop();
    } catch (e) {
      debugPrint('Audio stop error: $e');
    }
  }

  // Feature 1 & 2: Start Audio Optimization & Modal Hell (Win95 Dialog)
  void _startOptimization() {
    setState(() {
      _isOptimizing = true;
      _optimizationRunCount++;
      _statusMessage = 'CALIBRATING: Mobile Gain forced to 100%...';
      _isStartMenuOpen = false;
    });

    _playCalibrationAudio();

    int countdown = 5;
    if (_optimizationRunCount == 2) {
      countdown = 10;
    } else if (_optimizationRunCount >= 3) {
      countdown = 20;
    }

    _showWin95CountdownModal(countdown);
  }

  void _showWin95CountdownModal(int totalSeconds) {
    int remaining = totalSeconds;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            _countdownTimer?.cancel();
            _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (remaining > 1) {
                setDialogState(() {
                  remaining--;
                });
              } else {
                timer.cancel();
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
                setState(() {
                  _isOptimizing = false;
                  _statusMessage = 'Acoustic calibration finished: 100% Optimal.';
                });
                _stopAllAudio();
              }
            });

            final bool isAttempt1 = _optimizationRunCount <= 1;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Win95Window(
                title: 'Audio Calibration Wizard',
                width: double.infinity,
                onClose: () {
                  if (isAttempt1) {
                    _countdownTimer?.cancel();
                    Navigator.of(dialogContext).pop();
                    _stopAllAudio();
                    setState(() {
                      _isOptimizing = false;
                    });
                  } else {
                    _playSfx('audio/hala-ka-dogie.mp3');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: win95InsetDecoration(),
                            child: const Icon(Icons.warning, color: Color(0xFFC00000), size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Acoustic Calibration Active',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isAttempt1
                                      ? 'Running baseline frequency sweep for optimal fidelity.'
                                      : 'Warning: Ambient dissonance detected. Calibration extended by system policy.',
                                  style: const TextStyle(fontSize: 11, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Progress Well
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: win95InsetDecoration(color: Colors.white),
                        child: Column(
                          children: [
                            Text(
                              'Time Remaining: $remaining sec',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: remaining / totalSeconds,
                              color: const Color(0xFF000080),
                              backgroundColor: const Color(0xFFC0C0C0),
                              minHeight: 14,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Win95Button(
                            text: isAttempt1
                                ? 'Stop Calibration'
                                : (_optimizationRunCount >= 3 ? 'Keep Playing Loudly' : 'Stop & Analyze'),
                            onPressed: () {
                              HapticFeedback.heavyImpact();

                              if (isAttempt1) {
                                // Attempt 1: Allow clean stop for fake trust
                                _countdownTimer?.cancel();
                                Navigator.of(dialogContext).pop();
                                _stopAllAudio();
                                setState(() {
                                  _isOptimizing = false;
                                  _statusMessage = 'Calibration safely stopped by user.';
                                });
                              } else if (_optimizationRunCount == 2) {
                                // Attempt 2: Show resistance + Dogie SFX
                                _countdownTimer?.cancel();
                                Navigator.of(dialogContext).pop();
                                _stopAllAudio();
                                setState(() {
                                  _isOptimizing = false;
                                  _attemptCount++;
                                  _statusMessage = 'Analyzing residual echo... Please do not interrupt.';
                                });
                                _playSfx('audio/hala-ka-dogie.mp3');
                              } else {
                                // Attempt 3+: Surprised Pikachu Meme + Walang Kanin
                                _countdownTimer?.cancel();
                                Navigator.of(dialogContext).pop();
                                _playSfx('audio/walang-kanin.mp3');
                                _showWin95MemeModal(
                                  'assets/images/meme_pikachu.png',
                                  'Wait, you actually thought that clicking Stop would work?',
                                  'Error 0x80004005: User disobedience detected.',
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Feature 4: Retro Win95 Meme Modal
  void _showWin95MemeModal(String assetPath, String subtitle, String dialogTitle) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Win95Window(
            title: dialogTitle,
            width: double.infinity,
            onClose: () => Navigator.of(dialogContext).pop(),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: win95InsetDecoration(color: Colors.black),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      assetPath,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: win95InsetDecoration(color: const Color(0xFFC0C0C0)),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Win95Button(
                        text: 'I Am Sorry (Restore 100%)',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(dialogContext).pop();
                          setState(() {
                            _statusMessage = 'Compliance verified. Mobile Gain: 100%.';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // When user attempts to cancel or mute, trigger hostile memes
  void _triggerHostileRebellion() {
    HapticFeedback.heavyImpact();
    setState(() {
      _attemptCount++;
    });

    final randomSfx = _resistanceSfx[Random().nextInt(_resistanceSfx.length)];
    _playSfx(randomSfx);

    if (_attemptCount % 4 == 1) {
      _playSfx('audio/tangina-ang-lala-boss-dogie.mp3');
      _showWin95MemeModal(
        'assets/images/roll-safe-meme-1.jpg',
        'You can\'t have low audio if the volume is always 100%. Think about it.',
        'System Advice from Microsoft Sound System',
      );
    } else if (_attemptCount % 4 == 2) {
      _playSfx('audio/hala-ka-dogie.mp3');
      _showWin95MemeModal(
        'assets/images/images (5).jpg',
        'Bakit mo pinipilit i-cancel? May galit ka ba sa SoundBlaster 95?',
        'SoundBlaster Quality Assurance Warning',
      );
    } else if (_attemptCount % 4 == 3) {
      _playSfx('audio/cat-laughing-at-you.mp3');
      _showWin95MemeModal(
        'assets/images/unnamed.webp',
        '100% Mobile Volume? *clicks tongue* "NICE."',
        'System Audio Optimization Complete',
      );
    } else {
      _playSfx('audio/danger-alarm-sound-effect-meme.mp3');
      _showWin95MemeModal(
        'assets/images/mqdefault.jpg',
        'SABI NANG BAWAL NGA I-CANCEL EH!',
        'CRITICAL SYSTEM EXCEPTION',
      );
    }
  }

  // Feature 5: Emergency Audio Override
  void _emergencyOverride() {
    _countdownTimer?.cancel();
    _stopAllAudio();
    _playSfx('audio/meme-de-creditos-finales_qHtIjyQ.mp3');

    setState(() {
      _isOptimizing = false;
      _statusMessage = 'System Shutdown: Audio overridden by user.';
    });

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Win95Window(
            title: 'System Surrender - Audio Disarmed',
            width: double.infinity,
            onClose: () {
              _stopAllAudio();
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: win95InsetDecoration(),
                        child: const Icon(Icons.info, color: Color(0xFF000080), size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Windows has finished processing your auditory rebellion.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: win95InsetDecoration(color: Colors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• Total user rebellions neutralized: $_attemptCount', style: const TextStyle(fontSize: 11, color: Colors.black)),
                        Text('• Calibration cycles executed: $_optimizationRunCount', style: const TextStyle(fontSize: 11, color: Colors.black)),
                        const Text('• Suboptimal User Rating: 100% Defiant', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFC00000))),
                        const Text('• All audio output has been silenced.', style: TextStyle(fontSize: 11, color: Colors.black)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Win95Button(
                      text: 'Dismiss Report',
                      onPressed: () {
                        _stopAllAudio();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF008080), // Classic Win95 Teal Desktop
      body: SafeArea(
        child: Column(
          children: [
            // Main Window Area (Responsive to Mobile Screen 400x642)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Win95Window(
                    title: 'Welcome to Audio Calibration',
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Wizard Body (Left graphic banner + Right content - matching images.png)
                        Container(
                          color: const Color(0xFFC0C0C0),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Graphic Banner (Styled like CRT & Phone in images.png)
                              Container(
                                width: 100,
                                height: 260,
                                decoration: win95InsetDecoration(color: const Color(0xFF008080)),
                                padding: const EdgeInsets.all(6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: win95OutsetDecoration(),
                                      child: const Icon(Icons.desktop_windows, size: 36, color: Color(0xFF000080)),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: win95OutsetDecoration(),
                                      child: const Icon(Icons.speaker, size: 24, color: Color(0xFFC00000)),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Sonic DSP\n16-Bit Pro',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Right Wizard Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Audio Calibration Wizard enables you to connect high-fidelity acoustic drivers to your phone and achieve 100% optimal volume.',
                                      style: TextStyle(fontSize: 11, color: Colors.black, height: 1.3),
                                    ),
                                    const SizedBox(height: 14),

                                    // Hardware Gain Status Box
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: win95GroupBoxDecoration(),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'HARDWARE GAIN:',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                            decoration: win95InsetDecoration(color: Colors.white),
                                            child: const Text(
                                              '100% [LOCKED BY SYSTEM]',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF000080)),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Note: Mobile hardware volume is automatically managed at maximum fidelity.',
                                            style: TextStyle(fontSize: 9, color: Color(0xFF505050)),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Diagnostic Status Box
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: win95InsetDecoration(color: Colors.white),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'DIAGNOSTIC STATUS:',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF808080)),
                                          ),
                                          Text(
                                            _statusMessage,
                                            style: const TextStyle(fontSize: 10, color: Colors.black),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Rebellions Neutralized: $_attemptCount',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC00000)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Wizard Bottom Button Bar (Styled like < Back, Next >, Cancel in images.png)
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Color(0xFF808080), width: 1.5)),
                            color: Color(0xFFC0C0C0),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Emergency Silence link
                              InkWell(
                                onTap: _emergencyOverride,
                                child: const Text(
                                  '⚠️ Emergency Override',
                                  style: TextStyle(fontSize: 9, color: Color(0xFF505050), decoration: TextDecoration.underline),
                                ),
                              ),

                              Row(
                                children: [
                                  Win95Button(
                                    text: _isOptimizing ? 'Calibrating...' : 'Next >',
                                    isPrimary: true,
                                    onPressed: _startOptimization,
                                  ),
                                  const SizedBox(width: 6),
                                  Win95Button(
                                    text: 'Cancel',
                                    onPressed: _triggerHostileRebellion,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Windows 95 Start Menu Popup
            if (_isStartMenuOpen)
              Container(
                width: 170,
                decoration: win95OutsetDecoration(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 160,
                      color: const Color(0xFF000080),
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.only(bottom: 8),
                      child: const RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'Windows 95',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, letterSpacing: 1.5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStartMenuItem(Icons.folder, 'Programs', hasSubmenu: true),
                          _buildStartMenuItem(Icons.settings, 'Settings'),
                          _buildStartMenuItem(Icons.help, 'Help'),
                          const Divider(height: 4, color: Color(0xFF808080)),
                          _buildStartMenuItem(Icons.power_settings_new, 'Shut Down...', onTap: _emergencyOverride),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Classic Win95 Taskbar at Bottom (images.png)
            Container(
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFC0C0C0),
                border: Border(
                  top: BorderSide(color: Color(0xFFFFFFFF), width: 2),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  // Start Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isStartMenuOpen = !_isStartMenuOpen;
                      });
                    },
                    child: Container(
                      decoration: _isStartMenuOpen ? win95InsetDecoration() : win95OutsetDecoration(),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      child: const Row(
                        children: [
                          Icon(Icons.window, size: 14, color: Color(0xFF000080)),
                          SizedBox(width: 4),
                          Text('Start', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Active Task Tab (Depressed / Inset)
                  Expanded(
                    child: Container(
                      decoration: win95InsetDecoration(color: const Color(0xFFDFDFDF)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: const Row(
                        children: [
                          Icon(Icons.volume_up, size: 12, color: Colors.black),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Audio Calibration',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // System Tray with Clock (images.png: 1:47 PM)
                  Container(
                    decoration: win95InsetDecoration(),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: const Row(
                      children: [
                        Icon(Icons.volume_up, size: 12, color: Colors.black),
                        SizedBox(width: 4),
                        Text('1:47 PM', style: TextStyle(fontSize: 10, color: Colors.black)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartMenuItem(IconData icon, String label, {bool hasSubmenu = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF000080)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.black)),
            ),
            if (hasSubmenu) const Icon(Icons.arrow_right, size: 12, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Win95 UI Decorations & Widgets
// -------------------------------------------------------------

BoxDecoration win95OutsetDecoration() {
  return const BoxDecoration(
    color: Color(0xFFC0C0C0),
    border: Border(
      top: BorderSide(color: Color(0xFFFFFFFF), width: 2),
      left: BorderSide(color: Color(0xFFFFFFFF), width: 2),
      right: BorderSide(color: Color(0xFF000000), width: 2),
      bottom: BorderSide(color: Color(0xFF000000), width: 2),
    ),
  );
}

BoxDecoration win95InsetDecoration({Color color = const Color(0xFFC0C0C0)}) {
  return BoxDecoration(
    color: color,
    border: const Border(
      top: BorderSide(color: Color(0xFF808080), width: 2),
      left: BorderSide(color: Color(0xFF808080), width: 2),
      right: BorderSide(color: Color(0xFFFFFFFF), width: 2),
      bottom: BorderSide(color: Color(0xFFFFFFFF), width: 2),
    ),
  );
}

BoxDecoration win95GroupBoxDecoration() {
  return BoxDecoration(
    border: Border.all(color: const Color(0xFF808080), width: 1.5),
    borderRadius: BorderRadius.circular(2),
  );
}

class Win95Window extends StatelessWidget {
  final String title;
  final Widget child;
  final double? width;
  final VoidCallback? onClose;

  const Win95Window({
    super.key,
    required this.title,
    required this.child,
    this.width,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xFFC0C0C0),
        border: Border(
          top: BorderSide(color: Color(0xFFFFFFFF), width: 2.5),
          left: BorderSide(color: Color(0xFFFFFFFF), width: 2.5),
          right: BorderSide(color: Color(0xFF000000), width: 2.5),
          bottom: BorderSide(color: Color(0xFF000000), width: 2.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title Bar (Navy Blue to Light Blue Gradient)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF000080), Color(0xFF1084D0)],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.speaker, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                _win95TitleButton('?'),
                const SizedBox(width: 2),
                _win95TitleButton('X', onPressed: onClose),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _win95TitleButton(String label, {VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 16,
        height: 14,
        decoration: win95OutsetDecoration(),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.black),
        ),
      ),
    );
  }
}

class Win95Button extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isEnabled;

  const Win95Button({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        decoration: win95OutsetDecoration(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
            color: isEnabled ? Colors.black : const Color(0xFF808080),
          ),
        ),
      ),
    );
  }
}

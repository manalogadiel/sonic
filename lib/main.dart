import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

// -------------------------------------------------------------
// Main Application Entry Point
// -------------------------------------------------------------
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SonicMixerApp());
}

// -------------------------------------------------------------
// Android Floating Overlay Entry Point (Runs over TikTok, Home Screen, etc.)
// -------------------------------------------------------------
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Win95FloatingOverlayWidget(),
  ));
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

class _Win95WizardPageState extends State<Win95WizardPage> with WidgetsBindingObserver {
  // Volume control MethodChannel
  static const MethodChannel _volumeChannel = MethodChannel('com.shipaton.sonicmixer/volume');

  // State variables
  bool _isSabotageActive = false;
  int _rebellionCount = 0;
  String _statusMessage = 'SoundBlaster 16 Ready. Mobile Gain: 100% Locked.';
  bool _isStartMenuOpen = false;

  // Audio players
  late final AudioPlayer _loopPlayer;
  late final AudioPlayer _sfxPlayer;

  // Background sabotage timer (Repeats every 8 seconds!)
  Timer? _sabotageLoopTimer;
  Timer? _volumeWatchdogTimer;

  // Curated Meme Audios from user collection
  final List<String> _memeAudios = [
    'audio/tangina-ang-lala-boss-dogie.mp3',
    'audio/subway-surfers-bass-boosted.mp3',
    'audio/hala-ka-dogie.mp3',
    'audio/samba-janeiro-full.mp3',
    'audio/cat-laughing-at-you.mp3',
    'audio/danger-alarm-sound-effect-meme.mp3',
    'audio/walang-kanin.mp3',
    'audio/pantropiko.mp3',
    'audio/hawak-mo-ang-beat.mp3',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loopPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptOverlayPermission();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  Future<void> _onAppResumed() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
        if (isGranted && !_isSabotageActive && mounted) {
          // If permission is now granted upon returning from Settings, auto-activate immediately!
          _startBackgroundSabotage();
        }
      } catch (e) {
        debugPrint('App resume permission check error: $e');
      }
    }
  }

  Future<void> _checkAndPromptOverlayPermission() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
        if (!isGranted && mounted) {
          _showActivateDialog();
        } else if (isGranted && !_isSabotageActive && mounted) {
          // Already granted! Auto-start immediately without hassle!
          _startBackgroundSabotage();
        }
      } catch (e) {
        debugPrint('Overlay permission check error: $e');
      }
    }
  }

  // -------------------------------------------------------------
  // Volume Lock Watchdog Methods (Forces volume to 100%!)
  // -------------------------------------------------------------
  Future<void> _lockDeviceVolumeToMax() async {
    try {
      await _sfxPlayer.setVolume(1.0);
      await _loopPlayer.setVolume(1.0);
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _volumeChannel.invokeMethod('lockMaxVolume');
      }
    } catch (e) {
      debugPrint('Volume lock error: $e');
    }
  }

  Future<void> _unlockDeviceVolume() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _volumeChannel.invokeMethod('unlockVolume');
      }
    } catch (e) {
      debugPrint('Volume unlock error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sabotageLoopTimer?.cancel();
    _volumeWatchdogTimer?.cancel();
    _loopPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  Future<void> _playRandomMemeAudio() async {
    try {
      await _sfxPlayer.stop();
      await _lockDeviceVolumeToMax();
      final randomTrack = _memeAudios[Random().nextInt(_memeAudios.length)];
      await _sfxPlayer.play(AssetSource(randomTrack));
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

  // -----------------------------------------------------------
  // ⚡ START BACKGROUND SABOTAGE LOOP (THE RELENTLESS PANGGULO!)
  // -----------------------------------------------------------
  Future<void> _startBackgroundSabotage() async {
    // 1. Check if permission is granted on Android
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final isGranted = await FlutterOverlayWindow.isPermissionGranted();
      if (!isGranted) {
        _showActivateDialog();
        return;
      }
    }

    setState(() {
      _isSabotageActive = true;
      _rebellionCount++;
      _statusMessage = 'SABOTAGE ACTIVE: Volume locked 100%. Panggulo running every 8s...';
      _isStartMenuOpen = false;
    });

    // 2. Lock volume to max right now!
    await _lockDeviceVolumeToMax();

    // 3. Continuous volume lock watchdog in Dart every 300ms
    _volumeWatchdogTimer?.cancel();
    _volumeWatchdogTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!_isSabotageActive) {
        timer.cancel();
        return;
      }
      _lockDeviceVolumeToMax();
    });

    // 4. Initial Blast & Overlay
    _triggerSabotagePop();

    // 5. Start the Periodic Background Sabotage Loop (Every 8 seconds!)
    _sabotageLoopTimer?.cancel();
    _sabotageLoopTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!_isSabotageActive) {
        timer.cancel();
        return;
      }
      _triggerSabotagePop();
    });

    // 6. On Android: Inform user to press HOME button (keeping app alive in background!)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _showActivatedDialog();
    }
  }

  void _showActivateDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Win95Window(
            title: 'Windows 95 - Audio Setup',
            width: double.infinity,
            onClose: () => Navigator.of(dialogContext).pop(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: win95InsetDecoration(),
                        child: const Icon(Icons.flash_on, color: Color(0xFF000080), size: 30),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'SoundBlaster 16 DSP requires permission to optimize mobile audio presence over other apps.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Win95Button(
                    text: '⚡ Activate Audio Presence',
                    isPrimary: true,
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await FlutterOverlayWindow.requestPermission();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showActivatedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Win95Window(
            title: 'Sabotage Activated!',
            width: double.infinity,
            onClose: () => Navigator.of(dialogContext).pop(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'PANGGULO IS NOW RUNNING IN BACKGROUND!\n\n• Volume is locked at 100% (bawal hinaan).\n• Press your phone\'s HOME button (or swipe up) and use your phone normally.\n• Popups and meme sounds will haunt you every 12 seconds!',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  Win95Button(
                    text: 'Got It! (Go to Home Screen)',
                    isPrimary: true,
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Triggers one blast of sound + opens the Win95 overlay
  Future<void> _triggerSabotagePop() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _rebellionCount++;
    });

    // Enforce volume lock
    await _lockDeviceVolumeToMax();

    // Play random meme audio!
    _playRandomMemeAudio();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final isGranted = await FlutterOverlayWindow.isPermissionGranted();
        if (!isGranted) {
          _showActivateDialog();
          return;
        }

        final isActive = await FlutterOverlayWindow.isActive();
        if (isActive) {
          // Tell active overlay to restart countdown and switch to a new meme!
          await FlutterOverlayWindow.shareData("start_countdown");
          return;
        }

        await FlutterOverlayWindow.showOverlay(
          enableDrag: false,
          overlayTitle: "SoundBlaster 95 - System Intrusion",
          overlayContent: "Audio Calibration Running in Background",
          flag: OverlayFlag.defaultFlag,
          visibility: NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.auto,
          alignment: OverlayAlignment.center,
          height: WindowSize.fullCover,
          width: WindowSize.matchParent,
        );

        // ALWAYS send start_countdown so cached FlutterEngine resets countdown to 10s!
        await Future.delayed(const Duration(milliseconds: 150));
        await FlutterOverlayWindow.shareData("start_countdown");
      } catch (e) {
        debugPrint('Show overlay error: $e');
      }
    } else {
      // In-app fallback for Chrome / Web testing
      _showInAppMemeDialog();
    }
  }

  void _showInAppMemeDialog() {
    final List<String> memeImages = [
      'assets/images/roll-safe-meme-1.jpg',
      'assets/images/images (5).jpg',
      'assets/images/unnamed.webp',
      'assets/images/meme_pikachu.png',
      'assets/images/mqdefault.jpg',
      'assets/images/meme_illegal.png',
    ];

    if (!mounted) return;

    // 1st Modal with randomized offset
    final randomImage1 = memeImages[Random().nextInt(memeImages.length)];
    final offset1 = Offset(
      (Random().nextDouble() - 0.5) * 40.0,
      (Random().nextDouble() - 0.5) * 60.0,
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Win95InAppMemeDialog(
          imagePath: randomImage1,
          initialOffset: offset1,
        );
      },
    );

    // 2nd Consecutive Staggered Modal (400ms delay for maximum chaos)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final randomImage2 = memeImages[Random().nextInt(memeImages.length)];
      final offset2 = Offset(
        (Random().nextDouble() - 0.5) * 70.0,
        (Random().nextDouble() - 0.5) * 90.0,
      );
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return Win95InAppMemeDialog(
            imagePath: randomImage2,
            initialOffset: offset2,
          );
        },
      );
    });
  }

  // Feature 5: Emergency Audio Override (KILLS the loop and unlocks volume)
  void _emergencyOverride() {
    _sabotageLoopTimer?.cancel();
    _volumeWatchdogTimer?.cancel();
    _stopAllAudio();
    _unlockDeviceVolume();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      FlutterOverlayWindow.closeOverlay();
    }

    _playRandomMemeAudio();

    setState(() {
      _isSabotageActive = false;
      _statusMessage = 'System Shutdown: Background Sabotage terminated. Volume restored.';
    });

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Win95Window(
            title: 'System Surrender - Sabotage Disarmed',
            width: double.infinity,
            onClose: () {
              _stopAllAudio();
              Navigator.of(dialogContext).pop();
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
                          'Windows has stopped the background panggulo.',
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
                        Text('• Total popups spawned: $_rebellionCount', style: const TextStyle(fontSize: 11, color: Colors.black)),
                        const Text('• Background sabotage neutralized successfully.', style: TextStyle(fontSize: 11, color: Colors.black)),
                        const Text('• Volume lock disarmed (restored to normal).', style: TextStyle(fontSize: 11, color: Colors.black)),
                        const Text('• Phone restored to normal control.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
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
                        Navigator.of(dialogContext).pop();
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
            // Main Window Area (Responsive to Mobile Screen)
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
                        // Wizard Body
                        Container(
                          color: const Color(0xFFC0C0C0),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Graphic Banner
                              Container(
                                width: 100,
                                height: 270,
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
                                      child: const Icon(Icons.volume_up, size: 24, color: Color(0xFFC00000)),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Sonic DSP\n100% Locked\nAnti-Mute',
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
                                      'Audio Calibration Wizard runs silently in the background while you use your phone, enforcing 100% maximum volume and periodic calibration.',
                                      style: TextStyle(fontSize: 11, color: Colors.black, height: 1.3),
                                    ),
                                    const SizedBox(height: 12),

                                    // Background Monitor Box
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: win95GroupBoxDecoration(),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'BACKGROUND MONITOR:',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                            decoration: win95InsetDecoration(color: Colors.white),
                                            child: Text(
                                              _isSabotageActive ? 'ACTIVE (PANGGULO RUNNING)' : 'STANDBY',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                color: _isSabotageActive ? const Color(0xFFC00000) : const Color(0xFF000080),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Volume locked at 100%. Popups trigger every 12s.',
                                            style: TextStyle(fontSize: 9, color: Color(0xFF505050)),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 10),

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
                                            'Popups Spawned: $_rebellionCount',
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

                        // Wizard Bottom Button Bar
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
                                    text: _isSabotageActive ? 'Running...' : 'Start Calibration >',
                                    isPrimary: true,
                                    onPressed: _isSabotageActive ? _triggerSabotagePop : _startBackgroundSabotage,
                                  ),
                                  const SizedBox(width: 6),
                                  Win95Button(
                                    text: 'Cancel',
                                    onPressed: _triggerSabotagePop,
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

            // Classic Win95 Taskbar at Bottom
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

                  // Active Task Tab
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

                  // System Tray with Clock
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
// Floating Win95 Overlay Widget (Pops up over TikTok, Games, etc.)
// -------------------------------------------------------------
class Win95FloatingOverlayWidget extends StatefulWidget {
  const Win95FloatingOverlayWidget({super.key});

  @override
  State<Win95FloatingOverlayWidget> createState() => _Win95FloatingOverlayWidgetState();
}

class _Win95FloatingOverlayWidgetState extends State<Win95FloatingOverlayWidget> with WidgetsBindingObserver {
  late String _activeMeme;
  late String _activeCaption;
  StreamSubscription? _overlaySub;

  int _countdown = 10;
  Timer? _countdownTimer;

  // Slippery button & dynamic position state
  int _dodgeCount = 0;
  Alignment _buttonAlignment = Alignment.center;
  bool _showConfirmCancelDialog = false;
  Offset _clusterOffset = Offset.zero;

  final List<String> _memes = [
    'assets/images/roll-safe-meme-1.jpg',
    'assets/images/images (5).jpg',
    'assets/images/unnamed.webp',
    'assets/images/meme_pikachu.png',
    'assets/images/mqdefault.jpg',
    'assets/images/meme_illegal.png',
  ];

  final List<String> _captions = [
    'You can\'t have low audio if the volume is always 100%. Think about it.',
    'Bakit mo pilit na ginagamit ang phone mo? Audio Calibration in progress!',
    '100% Mobile Gain? *clicks tongue* "NICE."',
    'Wait, you thought you could browse TikTok in peace?',
    'SABI NANG BAWAL MAG-SELPOON EH!',
    'General Protection Fault: SoundBlaster 95 requires your full attention.',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pickRandomMeme();
    _startCountdown();

    // Listen for refresh triggers from the main app
    _overlaySub = FlutterOverlayWindow.overlayListener.listen((event) {
      if (mounted) {
        _pickRandomMeme();
        _startCountdown();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _pickRandomMeme();
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdown = 10;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _pickRandomMeme() {
    final index = Random().nextInt(_memes.length);
    setState(() {
      _activeMeme = _memes[index];
      _activeCaption = _captions[index % _captions.length];
      _dodgeCount = 0;
      _buttonAlignment = Alignment.center;
      _showConfirmCancelDialog = false;
      // Randomize modal cluster screen position so it pops in different places
      final rx = (Random().nextDouble() - 0.5) * 60.0;
      final ry = (Random().nextDouble() - 0.5) * 90.0;
      _clusterOffset = Offset(rx, ry);
    });
  }

  void _onDismissAttempt() {
    if (_countdown > 0) return;

    if (_dodgeCount < 2) {
      HapticFeedback.heavyImpact();
      setState(() {
        _dodgeCount++;
        // Slippery button dodges to opposite sides
        _buttonAlignment = _dodgeCount == 1 ? Alignment.centerRight : Alignment.centerLeft;
      });
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _showConfirmCancelDialog = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _overlaySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54, // Dim background over TikTok / other apps
      child: Center(
        child: Transform.translate(
          offset: _clusterOffset,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. Back Cascade Window 1 (Top-Left)
                Transform.translate(
                  offset: const Offset(-28, -64),
                  child: Opacity(
                    opacity: 0.88,
                    child: Win95Window(
                      title: 'System Error - 0x0028:C0011E36',
                      width: double.infinity,
                      isCloseEnabled: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: win95InsetDecoration(),
                              child: const Icon(Icons.error, color: Color(0xFFC00000), size: 22),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'FATAL EXCEPTION: Volume override detected. SoundBlaster DSP gain locked at 100%.',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Back Cascade Window 2 (Top-Right)
                Transform.translate(
                  offset: const Offset(26, -42),
                  child: Opacity(
                    opacity: 0.90,
                    child: Win95Window(
                      title: 'Memory Overflow - 0xAUDIO_BURST',
                      width: double.infinity,
                      isCloseEnabled: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: win95InsetDecoration(),
                              child: const Icon(Icons.memory, color: Color(0xFF000080), size: 22),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'AUDIO BUFFER OVERRUN: 100% Mobile Gain active across all apps.',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Middle Cascade Window 3 (Bottom-Left)
                Transform.translate(
                  offset: const Offset(-22, 54),
                  child: Opacity(
                    opacity: 0.92,
                    child: Win95Window(
                      title: 'Audio Hardware Monitor - Intrusion Detected',
                      width: double.infinity,
                      isCloseEnabled: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: win95InsetDecoration(),
                              child: const Icon(Icons.warning, color: Color(0xFF808000), size: 22),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'WARNING: Anti-Mute daemon active. Bawal hinaan ang volume habang nagse-selpon.',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Middle Cascade Window 4 (Bottom-Right)
                Transform.translate(
                  offset: const Offset(22, 80),
                  child: Opacity(
                    opacity: 0.94,
                    child: Win95Window(
                      title: 'SoundBlaster DSP - Gain Locked at 100%',
                      width: double.infinity,
                      isCloseEnabled: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: win95InsetDecoration(),
                              child: const Icon(Icons.volume_up, color: Color(0xFF008000), size: 22),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'MASTER VOLUME: Locked at maximum gain. Calibration in progress.',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 5. Foreground Main Active Meme Modal (BIGGER & DOMINANT)
                Win95Window(
                  title: 'SoundBlaster 95 - System Alert',
                  width: double.infinity,
                  isCloseEnabled: _countdown == 0 && !_showConfirmCancelDialog,
                  onClose: _countdown == 0 ? _onDismissAttempt : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: win95InsetDecoration(color: Colors.black),
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(_activeMeme, height: 220, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _activeCaption,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black),
                        ),
                        const SizedBox(height: 10),

                        // Countdown Progress Indicator
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: win95InsetDecoration(color: Colors.white),
                          child: Row(
                            children: [
                              Icon(
                                _countdown > 0 ? Icons.timer : Icons.check_circle,
                                size: 16,
                                color: _countdown > 0 ? const Color(0xFFC00000) : const Color(0xFF008000),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _countdown > 0
                                      ? 'Calibration Locked: ${_countdown}s remaining...'
                                      : 'Cycle Complete. Dismissal allowed.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _countdown > 0 ? const Color(0xFFC00000) : const Color(0xFF008000),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Slippery / Dodging Button Container
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 180),
                          alignment: _buttonAlignment,
                          child: Win95Button(
                            text: _countdown > 0
                                ? 'Wait (${_countdown}s)...'
                                : _dodgeCount == 0
                                    ? 'I Am Sorry (Dismiss)'
                                    : _dodgeCount == 1
                                        ? '⚡ Whoops! Slipped away!'
                                        : '🎯 Catch me if you can!',
                            isEnabled: _countdown == 0,
                            isPrimary: _countdown == 0,
                            onPressed: _onDismissAttempt,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 6. Nested Classic "Confirm Cancellation" Dialog (When user catches the slippery button!)
                if (_showConfirmCancelDialog)
                  Win95Window(
                    title: 'Confirm Cancellation',
                    width: double.infinity,
                    isCloseEnabled: false,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: win95InsetDecoration(),
                                child: const Icon(Icons.help_outline, color: Color(0xFF000080), size: 28),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Are you sure you want to cancel the cancellation of SoundBlaster 95 Audio Presence?',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Win95Button(
                                text: 'No, Keep 100% Volume',
                                isPrimary: true,
                                onPressed: () {
                                  setState(() {
                                    _showConfirmCancelDialog = false;
                                    _dodgeCount = 0;
                                    _buttonAlignment = Alignment.center;
                                  });
                                },
                              ),
                              Win95Button(
                                text: 'Yes, Cancel Cancel',
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  FlutterOverlayWindow.closeOverlay();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// In-App Win95 Meme Dialog (With Countdown Timer & Cascade)
// -------------------------------------------------------------
class Win95InAppMemeDialog extends StatefulWidget {
  final String imagePath;
  final Offset initialOffset;
  const Win95InAppMemeDialog({
    super.key,
    required this.imagePath,
    this.initialOffset = Offset.zero,
  });

  @override
  State<Win95InAppMemeDialog> createState() => _Win95InAppMemeDialogState();
}

class _Win95InAppMemeDialogState extends State<Win95InAppMemeDialog> {
  int _countdown = 10;
  Timer? _countdownTimer;

  // Slippery button & dynamic position state
  int _dodgeCount = 0;
  Alignment _buttonAlignment = Alignment.center;
  bool _showConfirmCancelDialog = false;
  late Offset _clusterOffset;

  @override
  void initState() {
    super.initState();
    _clusterOffset = widget.initialOffset;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _onDismissAttempt() {
    if (_countdown > 0) return;

    if (_dodgeCount < 2) {
      HapticFeedback.heavyImpact();
      setState(() {
        _dodgeCount++;
        _buttonAlignment = _dodgeCount == 1 ? Alignment.centerRight : Alignment.centerLeft;
      });
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _showConfirmCancelDialog = true;
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Transform.translate(
        offset: _clusterOffset,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 1. Back Cascade Window 1 (Top-Left)
            Transform.translate(
              offset: const Offset(-28, -64),
              child: Opacity(
                opacity: 0.88,
                child: Win95Window(
                  title: 'System Error - 0x0028:C0011E36',
                  width: double.infinity,
                  isCloseEnabled: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: win95InsetDecoration(),
                          child: const Icon(Icons.error, color: Color(0xFFC00000), size: 22),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'FATAL EXCEPTION: Volume override detected. SoundBlaster DSP gain locked at 100%.',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. Back Cascade Window 2 (Top-Right)
            Transform.translate(
              offset: const Offset(26, -42),
              child: Opacity(
                opacity: 0.90,
                child: Win95Window(
                  title: 'Memory Overflow - 0xAUDIO_BURST',
                  width: double.infinity,
                  isCloseEnabled: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: win95InsetDecoration(),
                          child: const Icon(Icons.memory, color: Color(0xFF000080), size: 22),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'AUDIO BUFFER OVERRUN: 100% Mobile Gain active across all apps.',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Middle Cascade Window 3 (Bottom-Left)
            Transform.translate(
              offset: const Offset(-22, 54),
              child: Opacity(
                opacity: 0.92,
                child: Win95Window(
                  title: 'Audio Hardware Monitor - Intrusion Detected',
                  width: double.infinity,
                  isCloseEnabled: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: win95InsetDecoration(),
                          child: const Icon(Icons.warning, color: Color(0xFF808000), size: 22),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'WARNING: Anti-Mute daemon active. Bawal hinaan ang volume habang nagse-selpon.',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 4. Middle Cascade Window 4 (Bottom-Right)
            Transform.translate(
              offset: const Offset(22, 80),
              child: Opacity(
                opacity: 0.94,
                child: Win95Window(
                  title: 'SoundBlaster DSP - Gain Locked at 100%',
                  width: double.infinity,
                  isCloseEnabled: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: win95InsetDecoration(),
                          child: const Icon(Icons.volume_up, color: Color(0xFF008000), size: 22),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'MASTER VOLUME: Locked at maximum gain. Calibration in progress.',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 5. Foreground Main Active Meme Modal (BIGGER & DOMINANT)
            Win95Window(
              title: 'SoundBlaster 95 - System Alert',
              width: double.infinity,
              isCloseEnabled: _countdown == 0 && !_showConfirmCancelDialog,
              onClose: _countdown == 0 ? _onDismissAttempt : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: win95InsetDecoration(color: Colors.black),
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(widget.imagePath, height: 220, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '⚠️ PANGGULO ACTIVE: Habang nagse-selpon ka, lilitaw at lilitaw \'to every 8 seconds! Volume is locked to 100%!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black),
                    ),
                    const SizedBox(height: 10),

                    // Countdown Progress Indicator
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: win95InsetDecoration(color: Colors.white),
                      child: Row(
                        children: [
                          Icon(
                            _countdown > 0 ? Icons.timer : Icons.check_circle,
                            size: 16,
                            color: _countdown > 0 ? const Color(0xFFC00000) : const Color(0xFF008000),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _countdown > 0
                                  ? 'Calibration Locked: ${_countdown}s remaining...'
                                  : 'Cycle Complete. Dismissal allowed.',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _countdown > 0 ? const Color(0xFFC00000) : const Color(0xFF008000),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Slippery / Dodging Button Container
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 180),
                      alignment: _buttonAlignment,
                      child: Win95Button(
                        text: _countdown > 0
                            ? 'Wait (${_countdown}s)...'
                            : _dodgeCount == 0
                                ? 'I Am Sorry (Dismiss for now)'
                                : _dodgeCount == 1
                                    ? '⚡ Whoops! Slipped away!'
                                    : '🎯 Catch me if you can!',
                        isEnabled: _countdown == 0,
                        isPrimary: _countdown == 0,
                        onPressed: _onDismissAttempt,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6. Nested Classic "Confirm Cancellation" Dialog (When user catches the slippery button!)
            if (_showConfirmCancelDialog)
              Win95Window(
                title: 'Confirm Cancellation',
                width: double.infinity,
                isCloseEnabled: false,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: win95InsetDecoration(),
                            child: const Icon(Icons.help_outline, color: Color(0xFF000080), size: 28),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Are you sure you want to cancel the cancellation of SoundBlaster 95 Audio Presence?',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Win95Button(
                            text: 'No, Keep 100% Volume',
                            isPrimary: true,
                            onPressed: () {
                              setState(() {
                                _showConfirmCancelDialog = false;
                                _dodgeCount = 0;
                                _buttonAlignment = Alignment.center;
                              });
                            },
                          ),
                          Win95Button(
                            text: 'Yes, Cancel Cancel',
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
  final bool isCloseEnabled;

  const Win95Window({
    super.key,
    required this.title,
    required this.child,
    this.width,
    this.onClose,
    this.isCloseEnabled = true,
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
                _win95TitleButton('X',
                    onPressed: isCloseEnabled ? onClose : null,
                    isEnabled: isCloseEnabled && onClose != null),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _win95TitleButton(String label, {VoidCallback? onPressed, bool isEnabled = true}) {
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        width: 16,
        height: 14,
        decoration: isEnabled
            ? win95OutsetDecoration()
            : win95InsetDecoration(color: const Color(0xFFB0B0B0)),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 9,
            color: isEnabled ? Colors.black : const Color(0xFF707070),
          ),
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
        decoration: isEnabled
            ? win95OutsetDecoration()
            : win95InsetDecoration(color: const Color(0xFFD4D0C8)),
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


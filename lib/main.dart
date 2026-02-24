import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await IAPService.initialize();
  runApp(const BullsEyeApp());
}

class BullsEyeApp extends StatelessWidget {
  const BullsEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Dart Games",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        textTheme: GoogleFonts.luckiestGuyTextTheme(
          ThemeData.dark()
              .textTheme
              .apply(bodyColor: Colors.white, displayColor: Colors.white),
        ),
      ),
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Wait for a frame to ensure things are ready
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Check ATT status and request if needed
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      debugPrint("ATT Error: $e");
    }

    // Initialize Mobile Ads
    await MobileAds.instance.initialize();

    // Preload Interstitial Ad
    AdService.loadInterstitialAd();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LaunchPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.4),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.green),
                const SizedBox(height: 20),
                Text(
                  "Loading...",
                  style: GoogleFonts.luckiestGuy(
                      color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum GameMode { normal, playWithAi }

class LaunchPage extends StatelessWidget {
  const LaunchPage({super.key});

  static void startGame(BuildContext context, GameMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GamePage(mode: mode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/bg.png',
                fit: BoxFit.cover,
              ),
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _LeftGlassPanel(),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: _RightGlassPanel(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BannerAdWidget(),
          ),
        ],
      ),
    );
  }
}

class _LeftGlassPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModeButton(
                  image: "assets/images/btn_play.png",
                  onTap: () => LaunchPage.startGame(context, GameMode.normal),
                ),
                const SizedBox(height: 10),
                _ModeButton(
                  image: "assets/images/btn_play_ai.png",
                  onTap: () =>
                      LaunchPage.startGame(context, GameMode.playWithAi),
                ),
                const SizedBox(height: 10),
                if (!Platform.isAndroid)
                  ValueListenableBuilder<bool>(
                    valueListenable: IAPService.adsRemovedNotifier,
                    builder: (context, isAdsRemoved, child) {
                      if (isAdsRemoved) return const SizedBox.shrink();
                      return _ModeButton(
                        image: 'assets/images/btn_remove_ads.png',
                        onTap: () => IAPService.showRemoveAdsAlert(context),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RightGlassPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
          ),
          child: const _LeaderboardPreview(),
        ),
      ),
    );
  }
}

class _LeaderboardPreview extends StatelessWidget {
  const _LeaderboardPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            "Leaderboard",
            style: GoogleFonts.luckiestGuy(
              color: const Color(0xFF1A1A2E),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          const _LeaderboardRow(rank: "1", label: "Top Archer", score: 1200),
          const SizedBox(height: 6),
          const _LeaderboardRow(rank: "2", label: "Steady Hand", score: 980),
          const SizedBox(height: 6),
          const _LeaderboardRow(rank: "3", label: "Robin Jr.", score: 860),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.label,
    required this.score,
  });

  final String rank;
  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            rank,
            style: GoogleFonts.luckiestGuy(
                color: const Color(0xFF1A1A2E), fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.luckiestGuy(
                color: const Color(0xFF3D3D5C), fontSize: 14),
          ),
        ),
        Text(
          "$score",
          style: GoogleFonts.luckiestGuy(
              color: const Color(0xFF1A1A2E), fontSize: 14),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.image, required this.onTap});

  final String image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Image.asset(
          image,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key, this.mode = GameMode.normal});

  final GameMode mode;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  static const double _baseBoardSpeed = 160;
  static const double _dartSpeed = 560;
  static const double _dartGravity = 0;
  static const double _turbulenceStrength = 14;
  static const double _boardPadding = 24;
  static const int _maxLives = 5;
  static const double _characterHitRadius = 36;
  static const double _verticalMargin = 50;

  final Random _random = Random();
  final List<DartProjectile> _darts = [];
  final List<DartProjectile> _aiDarts = [];
  final List<BloodParticle> _bloodParticles = [];
  final List<StuckDart> _stuckDarts = [];
  final List<StuckDart> _stuckDartsOnUser = [];
  final List<StuckDart> _stuckDartsOnAi = [];
  final List<StoneParticle> _stones = [];
  double _stoneSpawnTimer = 0;
  double _nextStoneDelay = 0;
  late final Ticker _ticker;
  late final AnimationController _characterController;
  ui.Image? _rockImage;

  int _score = 0;
  int _lives = _maxLives;
  double _boardY = 0;
  double _boardDirection = 1;
  double _boardRotation = 0;
  double _rotationPhase = 0;
  bool _isInitialized = false;

  double _userCharacterY = double.infinity; // will be centered on first frame
  double _aiCharacterY = 0;
  double _aiFireTimer = 0;
  double _nextAiFireDelay = 0;
  double _userFireTimer = 0; // Debounce timer for user dart firing
  static const double _userFireCooldown = 0.3; // 300ms between darts
  double _aiMoveDirection = 1;
  static const double _aiPatrolSpeed = 160;
  static const double _aiDodgeSpeed = 180;
  int _aiRageLevel = 0; // increases each time AI is hit

  double get _aiCurrentPatrolSpeed =>
      _aiPatrolSpeed * (1.0 + _aiRageLevel * 0.4);
  double get _aiCurrentDodgeSpeed => _aiDodgeSpeed * (1.0 + _aiRageLevel * 0.4);
  double get _aiFireSpeedMultiplier =>
      _aiRageLevel == 0 ? 1.0 : (1.0 / (1.0 + _aiRageLevel * 2.0));

  static const int _maxUserBloodHearts = 5;
  static const int _maxAiBloodHearts = 5;
  int _userBloodLifeHearts = _maxUserBloodHearts;
  int _aiBloodLifeHearts = _maxAiBloodHearts;

  double _userHitFlash = 0;
  double _aiHitFlash = 0;
  final List<HitSplash> _hitSplashes = [];
  double _fightIntroTime = 0;

  Duration _lastElapsed = Duration.zero;
  double _time = 0;
  bool _gameOverDialogShown = false;

  bool get _isGameOver =>
      _lives <= 0 ||
      (_isAiMode && (_userBloodLifeHearts <= 0 || _aiBloodLifeHearts <= 0));

  bool get _isAiMode => widget.mode == GameMode.playWithAi;

  Size _gameSize() => MediaQuery.sizeOf(context);

  @override
  void initState() {
    super.initState();
    _characterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _ticker = createTicker(_onTick)..start();
    _loadRockImage();
  }

  Future<void> _loadRockImage() async {
    try {
      final data = await rootBundle.load('assets/images/angry-rock.png');
      ui.decodeImageFromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        (ui.Image image) {
          if (mounted) setState(() => _rockImage = image);
        },
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker.dispose();
    _characterController.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!_isInitialized) {
      _lastElapsed = elapsed;
      return;
    }

    final rawDt = (elapsed - _lastElapsed).inMicroseconds / 1000000;
    _lastElapsed = elapsed;
    if (rawDt <= 0) {
      return;
    }
    _time += rawDt;
    final dt = rawDt;

    final size = _gameSize();

    if (_isAiMode) {
      _updateAiMovement(size, dt);

      if (_userBloodLifeHearts > 0 && _aiBloodLifeHearts > 0) {
        if (_nextAiFireDelay <= 0) {
          _nextAiFireDelay =
              (1.0 + _random.nextDouble() * 0.8) * _aiFireSpeedMultiplier;
        }
        _aiFireTimer += dt;
        if (_aiFireTimer >= _nextAiFireDelay) {
          _aiFireTimer = 0;
          _nextAiFireDelay =
              (1.0 + _random.nextDouble() * 0.8) * _aiFireSpeedMultiplier;
          _throwAiDart(size);
        }
      }

      // Update user dart firing cooldown
      _userFireTimer = (_userFireTimer - dt).clamp(0.0, double.infinity);

      _updateDartsAiMode(size, dt);
      _userHitFlash = (_userHitFlash - dt).clamp(0.0, 1.0);
      _aiHitFlash = (_aiHitFlash - dt).clamp(0.0, 1.0);
      for (var i = _hitSplashes.length - 1; i >= 0; i--) {
        _hitSplashes[i].life -= dt;
        if (_hitSplashes[i].life <= 0) _hitSplashes.removeAt(i);
      }
      if (_fightIntroTime > 0)
        _fightIntroTime = (_fightIntroTime - dt).clamp(0.0, 2.0);
    } else {
      _updateStones(size, dt);
      final boardRadius = _boardRadius(size);
      final overshoot = boardRadius * 0.65;
      final minY = boardRadius - overshoot;
      final maxY = size.height - boardRadius + overshoot;

      final speedFactor = _speedFactor(size);
      final boardSpeed = _baseBoardSpeed * speedFactor;
      _boardY += _boardDirection * boardSpeed * dt;
      if (_boardY <= minY) {
        _boardY = minY;
        _boardDirection = 1;
      } else if (_boardY >= maxY) {
        _boardY = maxY;
        _boardDirection = -1;
      }

      if ((_score ~/ 100) >= 10) {
        _rotationPhase += dt * 1.6;
        final maxRotation = 120 * pi / 180;
        _boardRotation = (sin(_rotationPhase) * 0.5 + 0.5) * maxRotation;
      } else {
        _boardRotation = 0;
      }

      _updateDarts(size, boardRadius, dt);
    }
    setState(() {});
  }

  StoneParticle _spawnStone(Size size, double minX, double maxX) {
    return StoneParticle(
      x: minX + _random.nextDouble() * (maxX - minX),
      y: -40,
      size: 26 + _random.nextDouble() * 18,
      speed: 140 + _random.nextDouble() * 120,
      drift: -20 + _random.nextDouble() * 40,
      opacity: 0.7 + _random.nextDouble() * 0.25,
    );
  }

  void _updateStones(Size size, double dt) {
    if (_nextStoneDelay <= 0) {
      _nextStoneDelay = 10 + _random.nextDouble() * 20;
    }
    final charX = _characterPosition(size).dx + 80;
    final boardX = _boardCenter(size, _boardRadius(size)).dx - 80;
    final minX = min(charX, boardX - 1);
    final maxX = max(charX + 1, boardX);
    _stoneSpawnTimer += dt;
    if (_stoneSpawnTimer >= _nextStoneDelay) {
      _stoneSpawnTimer = 0;
      _nextStoneDelay = 10 + _random.nextDouble() * 20;
      final count = 1 + (_score ~/ 25);
      for (var i = 0; i < count; i++) {
        _stones.add(_spawnStone(size, minX, maxX));
      }
    }

    for (var i = 0; i < _stones.length; i++) {
      final stone = _stones[i];
      stone.y += stone.speed * dt;
      stone.x += stone.drift * dt;
      if (stone.y > size.height + 40) {
        _stones.removeAt(i);
        i -= 1;
        continue;
      }
    }
  }

  void _updateDarts(Size size, double boardRadius, double dt) {
    if (_lives <= 0) {
      _darts.clear();
      return;
    }

    final boardCenter = _boardCenter(size, boardRadius);
    final dartsToRemove = <DartProjectile>[];

    for (final dart in _darts) {
      dart.vy += _dartGravity * dt;
      dart.x += dart.vx * dt;
      dart.y += dart.vy * dt;
      dart.wobblePhase += dt;
      dart.y += sin(dart.wobblePhase * 6 + dart.turbulenceSeed) *
          _turbulenceStrength *
          dt;
      dart.angle = pi;

      var missLife = false;
      var remove = false;

      if (!dart.checked && dart.x >= boardCenter.dx) {
        dart.checked = true;
        final distance = _boardDistance(Offset(dart.x, dart.y), boardCenter);
        if (distance <= boardRadius) {
          dart.didHit = true;
          final points = _pointsForDistance(distance, boardRadius);
          _score += points;
          _playCrowdHitSound(points);
          _stickDart(dart, boardCenter);
          remove = true;
        } else {
          dart.missed = true;
          _loseLife();
        }
      }

      if (!dart.didHit && !dart.missed && _stoneHitsDart(dart)) {
        dart.missed = true;
        dart.vx = 0;
        dart.vy = 240;
        _loseLife();
      }

      if (dart.x > size.width + 120 ||
          dart.y < -120 ||
          dart.y > size.height + 120) {
        if (!dart.didHit && !dart.missed) {
          missLife = true;
        }
        dart.missed = true;
        remove = true;
      }

      if (remove) {
        dartsToRemove.add(dart);
        if (missLife) {
          _loseLife();
        }
      }

      if (!dart.checked && dart.x > boardCenter.dx + boardRadius) {
        dart.checked = true;
        dart.missed = true;
        _loseLife();
      }
    }

    _darts.removeWhere(dartsToRemove.contains);
  }

  bool _stoneHitsDart(DartProjectile dart) {
    for (final stone in _stones) {
      final dx = dart.x - stone.x;
      final dy = dart.y - stone.y;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance < stone.size * 0.6) {
        return true;
      }
    }
    return false;
  }

  void _loseLife() {
    if (_lives > 0) {
      _lives -= 1;
    }
  }

  void _stickDart(DartProjectile dart, Offset boardCenter) {
    final relative = Offset(dart.x, dart.y) - boardCenter;
    final local = _rotateOffset(relative, -_boardRotation);
    final localAngle = dart.angle - _boardRotation;
    _stuckDarts.add(StuckDart(localOffset: local, angle: localAngle));
  }

  Offset _rotateOffset(Offset input, double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return Offset(
      input.dx * cosA - input.dy * sinA,
      input.dx * sinA + input.dy * cosA,
    );
  }

  double _boardDistance(Offset point, Offset center) {
    return (point - center).distance;
  }

  void _throwDart(Size size) {
    // Check if in cooldown for user firing
    if (_isAiMode && _userFireTimer > 0) {
      return; // Still in cooldown, ignore tap
    }

    if (_lives <= 0 && !_isAiMode) {
      _resetGame(size);
      return;
    }
    if (_isAiMode && (_userBloodLifeHearts <= 0 || _aiBloodLifeHearts <= 0)) {
      _resetGame(size);
      return;
    }

    final charPos = _characterPosition(size);
    final speed = _dartSpeed * (0.95 + _random.nextDouble() * 0.1);
    _darts.add(
      DartProjectile(
        x: charPos.dx + 60,
        y: charPos.dy - 10,
        vx: speed,
        vy: 0,
        angle: pi,
        turbulenceSeed: _random.nextDouble() * pi * 2,
      ),
    );

    // Start cooldown for next dart
    if (_isAiMode) {
      _userFireTimer = _userFireCooldown;
    }
  }

  void _throwAiDart(Size size) {
    final aiPos = _aiCharacterPosition(size);
    final userPos = _characterPosition(size);
    // Aim from AI toward user (high precision: small random offset)
    double dx = userPos.dx - (aiPos.dx - 60);
    double dy = (userPos.dy - 10) - (aiPos.dy - 10);
    double dist = sqrt(dx * dx + dy * dy);
    if (dist < 20) {
      dx = -1;
      dy = 0;
      dist = 1;
    }
    double vx = (dx / dist);
    double vy = (dy / dist);
    // Small angle jitter for high-but-not-robot precision (±~1.5°)
    final jitter = (_random.nextDouble() - 0.5) * 0.052;
    final c = cos(jitter), s = sin(jitter);
    final vx2 = vx * c - vy * s;
    final vy2 = vx * s + vy * c;
    vx = vx2;
    vy = vy2;
    // Varied dart speed: 50%–92% of base (random but not too fast)
    final speed = _dartSpeed * (0.5 + _random.nextDouble() * 0.42);
    _aiDarts.add(
      DartProjectile(
        x: aiPos.dx - 60,
        y: aiPos.dy - 10,
        vx: vx * speed,
        vy: vy * speed,
        angle: atan2(vy, vx) - pi, // draw angle: shape points left at 0
        turbulenceSeed: _random.nextDouble() * pi * 2,
      ),
    );
  }

  void _updateAiMovement(Size size, double dt) {
    if (_aiBloodLifeHearts <= 0 || _userBloodLifeHearts <= 0) return;

    final playableTop = _verticalMargin;
    final playableBottom = size.height - _verticalMargin;
    final rangeHeight = playableBottom - playableTop;
    // Allow AI to go 30% out of screen top/bottom
    final patrolTop = playableTop - (rangeHeight * 0.3);
    final patrolBottom = playableBottom + (rangeHeight * 0.3);
    final aiX = size.width * 0.88;

    bool dodging = false;
    double dodgeDir = 0;

    for (final dart in _darts) {
      if (dart.didHit || dart.missed || dart.vx <= 0 || dart.x >= aiX - 20)
        continue;
      final t = (aiX - dart.x) / dart.vx;
      if (t <= 0 || t > 2) continue;
      final predictedY = dart.y + dart.vy * t;
      final gap = (predictedY - _aiCharacterY).abs();
      if (gap < _characterHitRadius * 2) {
        dodging = true;
        dodgeDir = predictedY > _aiCharacterY ? -1 : 1;
        break;
      }
    }

    if (dodging && dodgeDir != 0) {
      _aiCharacterY += dodgeDir * _aiCurrentDodgeSpeed * dt;
      _aiCharacterY = _aiCharacterY.clamp(patrolTop, patrolBottom);
    } else {
      _aiCharacterY += _aiMoveDirection * _aiCurrentPatrolSpeed * dt;
      if (_aiCharacterY >= patrolBottom) {
        _aiCharacterY = patrolBottom;
        _aiMoveDirection = -1;
      } else if (_aiCharacterY <= patrolTop) {
        _aiCharacterY = patrolTop;
        _aiMoveDirection = 1;
      }
    }
  }

  void _updateDartsAiMode(Size size, double dt) {
    final userPos = _characterPosition(size);
    final aiPos = _aiCharacterPosition(size);

    // 1) Update positions for both dart lists
    for (final dart in _darts) {
      dart.vy += _dartGravity * dt;
      dart.x += dart.vx * dt;
      dart.y += dart.vy * dt;
      dart.wobblePhase += dt;
      dart.y += sin(dart.wobblePhase * 6 + dart.turbulenceSeed) *
          _turbulenceStrength *
          dt;
      dart.angle = pi;
    }
    for (final dart in _aiDarts) {
      dart.vy += _dartGravity * dt;
      dart.x += dart.vx * dt;
      dart.y += dart.vy * dt;
      dart.wobblePhase += dt;
      dart.y += sin(dart.wobblePhase * 6 + dart.turbulenceSeed) *
          _turbulenceStrength *
          dt;
      dart.angle = atan2(dart.vy, dart.vx) - pi;
    }

    // 2) Dart-vs-dart collision: when darts hit each other, both destroyed and blood shown
    for (final ud in _darts) {
      if (ud.didHit || ud.missed) continue;
      for (final ad in _aiDarts) {
        if (ad.didHit || ad.missed) continue;
        final dist = (Offset(ud.x, ud.y) - Offset(ad.x, ad.y)).distance;
        if (dist < 48) {
          ud.didHit = true;
          ad.didHit = true;
          _spawnBlood((ud.x + ad.x) * 0.5, (ud.y + ad.y) * 0.5);
          break;
        }
      }
    }

    // 3) User darts vs AI character
    for (final dart in _darts) {
      if (dart.didHit || dart.missed) continue;

      // Broader x-window to ensure no skips (140px)
      if (dart.x >= aiPos.dx - 100 && dart.x <= aiPos.dx + 40) {
        final dx = dart.x - aiPos.dx;
        final dy = dart.y - aiPos.dy;

        // Torso check (broadened for better gameplay feel)
        final bool hitTorso = dx.abs() <= 32 && dy <= 0 && dy >= -65;

        // Head check (Circle at y=-72 relative to base)
        final headPos = Offset(0, -72);
        final headDist = (Offset(dx, dy) - headPos).distance;
        final bool hitHead = headDist <= 32;

        if (hitTorso || hitHead) {
          dart.didHit = true;
          _spawnBlood(dart.x, dart.y);

          _aiBloodLifeHearts =
              (_aiBloodLifeHearts - 1).clamp(0, _maxAiBloodHearts);
          _aiRageLevel++; // AI gets angrier with each hit
          _hitSplashes.add(HitSplash(
            x: aiPos.dx,
            y: hitHead ? aiPos.dy - 75 : aiPos.dy - 35,
            life: 0.6,
          ));

          _aiHitFlash = 0.35;
          _stuckDartsOnAi.add(StuckDart(
            localOffset: Offset(dart.x - aiPos.dx, dart.y - aiPos.dy),
            angle: dart.angle,
          ));

          if (_isGameOver && !_isAiMode) {
            AdService.showInterstitialAd();
          }
          _playCrowdHitSound(hitHead ? 100 : 25);
        }
      }
      if (dart.x > size.width + 120 ||
          dart.y < -120 ||
          dart.y > size.height + 120) {
        dart.missed = true;
      }
    }
    _darts.removeWhere((d) => d.didHit || d.missed || d.x > size.width + 50);

    // 4) AI darts vs user character
    for (final dart in _aiDarts) {
      if (dart.didHit || dart.missed) continue;

      if (dart.x <= userPos.dx + 100 && dart.x >= userPos.dx - 40) {
        final dx = dart.x - userPos.dx;
        final dy = dart.y - userPos.dy;

        final bool hitTorso = dx.abs() <= 32 && dy <= 0 && dy >= -65;

        final headPos = Offset(0, -72);
        final headDist = (Offset(dx, dy) - headPos).distance;
        final bool hitHead = headDist <= 32;

        if (hitTorso || hitHead) {
          dart.didHit = true;
          _spawnBlood(dart.x, dart.y);

          _userBloodLifeHearts =
              (_userBloodLifeHearts - 1).clamp(0, _maxUserBloodHearts);
          _hitSplashes.add(HitSplash(
            x: userPos.dx,
            y: hitHead ? userPos.dy - 75 : userPos.dy - 35,
            life: 0.6,
          ));

          _userHitFlash = 0.35;
          if (_isGameOver && !_isAiMode) {
            AdService.showInterstitialAd();
          }
          _stuckDartsOnUser.add(StuckDart(
            localOffset: Offset(dart.x - userPos.dx, dart.y - userPos.dy),
            angle: dart.angle,
          ));
          _playCrowdHitSound(hitHead ? 50 : 10);
        }
      }
      if (dart.x < -120 || dart.y < -120 || dart.y > size.height + 120) {
        dart.missed = true;
      }
    }
    _aiDarts.removeWhere((d) => d.didHit || d.missed || d.x < -50);

    for (var i = _bloodParticles.length - 1; i >= 0; i--) {
      final p = _bloodParticles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 120 * dt;
      p.life -= dt;
      if (p.life <= 0) _bloodParticles.removeAt(i);
    }
  }

  void _spawnBlood(double x, double y) {
    for (var i = 0; i < 12; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 80 + _random.nextDouble() * 120;
      _bloodParticles.add(BloodParticle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: -speed * 0.3 + _random.nextDouble() * 40,
        life: 0.5 + _random.nextDouble() * 0.4,
        size: 4 + _random.nextDouble() * 6,
      ));
    }
  }

  void _playCrowdHitSound(int points) {
    var repeats = 1;
    if (points >= 100) {
      repeats = 4;
    } else if (points >= 50) {
      repeats = 3;
    } else if (points >= 25) {
      repeats = 2;
    }

    for (var i = 0; i < repeats; i++) {
      Future.delayed(Duration(milliseconds: i * 70), () {
        SystemSound.play(SystemSoundType.click);
      });
    }
  }

  void _resetGame(Size size) {
    _score = 0;
    _lives = _maxLives;
    _darts.clear();
    _aiDarts.clear();
    _bloodParticles.clear();
    _stuckDarts.clear();
    _stuckDartsOnUser.clear();
    _stuckDartsOnAi.clear();
    _stones.clear();
    _userCharacterY = size.height * 0.5;
    _aiCharacterY = size.height * 0.5;
    _aiFireTimer = 0;
    _userFireTimer = 0;
    _nextAiFireDelay = 1.0;
    _aiMoveDirection = 1;
    _userBloodLifeHearts = _maxUserBloodHearts;
    _aiBloodLifeHearts = _maxAiBloodHearts;
    _aiRageLevel = 0;
    _userHitFlash = 0;
    _aiHitFlash = 0;
    _hitSplashes.clear();
    if (_isAiMode) {
      _fightIntroTime = 1.2;
    }

    if (!_isAiMode) {
      final boardRadius = _boardRadius(size);
      _boardY = size.height / 2;
      final overshoot = boardRadius * 0.65;
      final minY = boardRadius - overshoot;
      final maxY = size.height - boardRadius + overshoot;
      _boardY = _boardY.clamp(minY, maxY);
      _boardDirection = 1;
    }
  }

  Future<void> _showGameOverDialog(
      BuildContext context, Size size, bool isWin) async {
    if (!mounted) return;
    if (!_isAiMode) AdService.showInterstitialAd();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => _GameOverDialog(isWin: isWin),
    );
    if (!mounted) return;
    if (result == 'restart') {
      _gameOverDialogShown = false;
      _resetGame(size);
      setState(() {});
    } else if (result == 'back') {
      Navigator.of(context).pop();
    } else if (result == 'remove_ads') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('No ads in this version.', style: GoogleFonts.luckiestGuy()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  double _boardRadius(Size size) => min(size.height * 0.16, size.width * 0.09);

  Offset _boardCenter(Size size, double radius) {
    return Offset(size.width - radius - _boardPadding, _boardY);
  }

  Offset _characterPosition(Size size) {
    if (_isAiMode) {
      return Offset(size.width * 0.12, _userCharacterY);
    }
    var position = Offset(size.width * 0.12, size.height * 0.65);
    if (_score >= 100) {
      position = position.translate(0, sin(_time * 1.8) * 14);
    }
    return position;
  }

  Offset _aiCharacterPosition(Size size) {
    return Offset(size.width * 0.88, _aiCharacterY);
  }

  bool _isTabletDevice(Size size) {
    if (kIsWeb) {
      return size.shortestSide >= 600;
    }
    if (Platform.isIOS) {
      return size.shortestSide >= 600;
    }
    return size.shortestSide >= 720;
  }

  double _speedFactor(Size size) {
    final speedMultiplier = 1 + (_score ~/ 10) * 0.1;
    return speedMultiplier * (_isTabletDevice(size) ? 2 : 1);
  }

  int _pointsForDistance(double distance, double radius) {
    if (distance <= radius * 0.0625) {
      return 100;
    } else if (distance <= radius * 0.14) {
      return 50;
    } else if (distance <= radius * 0.28) {
      return 25;
    } else if (distance <= radius * 0.5) {
      return 10;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final size = _gameSize();
    if (!_isInitialized) {
      _isInitialized = true;
      _resetGame(size);
    }

    if (_isGameOver && !_gameOverDialogShown) {
      _gameOverDialogShown = true;
      final isWin =
          _isAiMode && _aiBloodLifeHearts <= 0 && _userBloodLifeHearts > 0;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _showGameOverDialog(context, size, isWin));
    }

    Widget gameContent = Stack(
      children: [
        Image.asset(
          'assets/images/bg.png',
          fit: BoxFit.cover,
          width: size.width,
          height: size.height,
        ),
        CustomPaint(
          size: size,
          painter: GamePainter(
            darts: _darts,
            aiDarts: _aiDarts,
            stuckDarts: _stuckDarts,
            stuckDartsOnUser: _stuckDartsOnUser,
            stuckDartsOnAi: _stuckDartsOnAi,
            stones: _stones,
            score: _score,
            lives: _lives,
            boardCenter: _boardCenter(size, _boardRadius(size)),
            boardRadius: _boardRadius(size),
            boardRotation: _boardRotation,
            time: _time,
            characterPosition: _characterPosition(size),
            characterAnim: _characterController.value,
            rockImage: _rockImage,
            isAiMode: _isAiMode,
            aiCharacterPosition: _isAiMode ? _aiCharacterPosition(size) : null,
            topBoundaryY: _isAiMode ? _verticalMargin : null,
            bottomBoundaryY: _isAiMode ? size.height - _verticalMargin : null,
            bloodParticles: _bloodParticles,
            userHitFlash: _userHitFlash,
            aiHitFlash: _aiHitFlash,
            hitSplashes: _hitSplashes,
            userHearts: _userBloodLifeHearts,
            aiHearts: _aiBloodLifeHearts,
          ),
        ),
        if (_isAiMode && _fightIntroTime > 0)
          Positioned.fill(
            child: Center(
              child: Text(
                'Fight!',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 56,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        color: Colors.black87,
                        offset: const Offset(2, 2),
                        blurRadius: 4),
                    Shadow(
                        color: const Color(0xFFE53935),
                        offset: Offset.zero,
                        blurRadius: 12),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: _isAiMode
                ? _AiModeHud(
                    userBloodHearts: _userBloodLifeHearts,
                    aiBloodHearts: _aiBloodLifeHearts,
                    maxBloodHearts: _maxUserBloodHearts,
                  )
                : HudBadge(
                    score: _score,
                    lives: _lives,
                  ),
          ),
        ),
        if (_lives <= 0 || (_isAiMode && _userBloodLifeHearts <= 0))
          const Center(child: GameOverBanner()),
        if (_isAiMode && _aiBloodLifeHearts <= 0 && _userBloodLifeHearts > 0)
          const Center(child: _YouWinBanner()),
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: GestureDetector(
                  onTap: () async {
                    final exit = await showDialog<bool>(
                      context: context,
                      barrierColor: Colors.black54,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.85,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: Colors.white24, width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 20,
                                    spreadRadius: 4),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Exit game?',
                                  style: GoogleFonts.luckiestGuy(
                                    color: Colors.white,
                                    fontSize: 28,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your progress will be lost.',
                                  style: GoogleFonts.luckiestGuy(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.white24,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.luckiestGuy(
                                            color: Colors.white, fontSize: 18),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: TextButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFB71C1C),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      child: Text(
                                        'Exit',
                                        style: GoogleFonts.luckiestGuy(
                                            color: Colors.white, fontSize: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                    if (exit == true && mounted) {
                      if (!_isAiMode) AdService.showInterstitialAd();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  child: Image.asset(
                    'assets/images/exit.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (_isAiMode) {
      gameContent = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _throwDart(size),
        onVerticalDragUpdate: (details) {
          if (_userBloodLifeHearts <= 0 || _aiBloodLifeHearts <= 0) return;
          setState(() {
            _userCharacterY = (_userCharacterY + details.delta.dy)
                .clamp(_verticalMargin, size.height - _verticalMargin);
          });
        },
        child: gameContent,
      );
    } else {
      gameContent = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _throwDart(size),
        child: gameContent,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2D),
      body: Stack(
        children: [
          gameContent,
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BannerAdWidget(),
          ),
        ],
      ),
    );
  }
}

class DartProjectile {
  DartProjectile({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.angle,
    required this.turbulenceSeed,
    this.speedScale = 1,
  })  : checked = false,
        didHit = false,
        missed = false,
        wobblePhase = 0;

  double x;
  double y;
  double vx;
  double vy;
  double angle;
  double turbulenceSeed;
  double speedScale;
  double wobblePhase;
  bool checked;
  bool didHit;
  bool missed;
}

class StuckDart {
  StuckDart({required this.localOffset, required this.angle});

  final Offset localOffset;
  final double angle;
}

class StoneParticle {
  StoneParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.opacity,
  });

  double x;
  double y;
  double size;
  double speed;
  double drift;
  double opacity;
}

class BloodParticle {
  BloodParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
  }) : maxLife = life;

  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double maxLife;
  final double size;
}

class HitSplash {
  HitSplash({required this.x, required this.y, required this.life});
  double x;
  double y;
  double life;
}

class GamePainter extends CustomPainter {
  GamePainter({
    required this.darts,
    required this.stuckDarts,
    required this.stones,
    required this.score,
    required this.lives,
    required this.boardCenter,
    required this.boardRadius,
    required this.boardRotation,
    required this.time,
    required this.characterPosition,
    required this.characterAnim,
    this.rockImage,
    this.aiDarts = const [],
    this.isAiMode = false,
    this.aiCharacterPosition,
    this.topBoundaryY,
    this.bottomBoundaryY,
    this.bloodParticles = const [],
    this.userHitFlash = 0,
    this.aiHitFlash = 0,
    this.hitSplashes = const [],
    required this.stuckDartsOnUser,
    required this.stuckDartsOnAi,
    this.userHearts = 5,
    this.aiHearts = 5,
  });

  final List<DartProjectile> darts;
  final List<DartProjectile> aiDarts;
  final List<StuckDart> stuckDarts;
  final List<StuckDart> stuckDartsOnUser;
  final List<StuckDart> stuckDartsOnAi;
  final List<StoneParticle> stones;
  final List<BloodParticle> bloodParticles;
  final int score;
  final int lives;
  final Offset boardCenter;
  final double boardRadius;
  final double boardRotation;
  final double time;
  final Offset characterPosition;
  final double characterAnim;
  final ui.Image? rockImage;
  final bool isAiMode;
  final Offset? aiCharacterPosition;
  final double? topBoundaryY;
  final double? bottomBoundaryY;
  final double userHitFlash;
  final double aiHitFlash;
  final List<HitSplash> hitSplashes;
  final int userHearts;
  final int aiHearts;

  @override
  void paint(Canvas canvas, Size size) {
    // _drawStadiumBackground(canvas, size); // Removed to use bg.png Image.asset background
    if (!isAiMode) {
      _drawStones(canvas);
      _drawBoard(canvas);
    }
    if (topBoundaryY != null && bottomBoundaryY != null) {
      _drawBoundaryLines(canvas, size);
    }
    _drawDarts(canvas);
    if (aiDarts.isNotEmpty) _drawAiDarts(canvas);
    _drawBlood(canvas);
    _drawCharacter(canvas, hitFlash: userHitFlash);
    if (aiCharacterPosition != null)
      _drawCharacter(canvas, rightSide: true, hitFlash: aiHitFlash);
    _drawHitSplashes(canvas);
  }

  void _drawBlood(Canvas canvas) {
    for (final p in bloodParticles) {
      final t = (p.life / p.maxLife).clamp(0.0, 1.0);
      final paint = Paint()
        ..color =
            Color.lerp(const Color(0xFF8B0000), const Color(0xFF660000), 1 - t)!
                .withOpacity(t)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  void _drawHitSplashes(Canvas canvas) {
    if (hitSplashes.isEmpty) return;
    const maxLife = 0.6;
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'HIT!',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: [
            Shadow(
                color: Colors.black87,
                offset: const Offset(1, 1),
                blurRadius: 2),
            Shadow(
                color: const Color(0xFFE53935),
                offset: Offset.zero,
                blurRadius: 6),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    for (final splash in hitSplashes) {
      final t = (splash.life / maxLife).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(splash.x, splash.y - 42);
      final circlePaint = Paint()
        ..color = const Color(0xFFE53935).withOpacity(0.4 * t)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, 28, circlePaint);
      canvas.translate(-textPainter.width / 2, -16);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  void _drawBoundaryLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(0, topBoundaryY!), Offset(size.width, topBoundaryY!), linePaint);
    canvas.drawLine(Offset(0, bottomBoundaryY!),
        Offset(size.width, bottomBoundaryY!), linePaint);
  }

  void _drawStones(Canvas canvas) {
    if (rockImage != null) {
      final src = Rect.fromLTWH(
          0, 0, rockImage!.width.toDouble(), rockImage!.height.toDouble());
      for (final stone in stones) {
        final w = stone.size * 1.6;
        final h = stone.size * 1.2;
        final dst = Rect.fromCenter(
          center: Offset(stone.x, stone.y),
          width: w,
          height: h,
        );
        final paint = Paint()
          ..filterQuality = FilterQuality.medium
          ..isAntiAlias = true
          ..color = Color.fromRGBO(255, 255, 255, stone.opacity);
        canvas.drawImageRect(rockImage!, src, dst, paint);
      }
      return;
    }
    final stonePaint = Paint()..color = const Color(0xFF6F727A);
    final highlightPaint = Paint()..color = const Color(0xFFB9BDC6);
    for (final stone in stones) {
      stonePaint.color = stonePaint.color.withOpacity(stone.opacity);
      highlightPaint.color = highlightPaint.color.withOpacity(stone.opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(stone.x, stone.y),
            width: stone.size * 1.6,
            height: stone.size * 1.2,
          ),
          Radius.circular(stone.size * 0.4),
        ),
        stonePaint,
      );
      canvas.drawCircle(
        Offset(stone.x - stone.size * 0.2, stone.y - stone.size * 0.15),
        stone.size * 0.28,
        highlightPaint,
      );
    }
  }

  void _drawBoard(Canvas canvas) {
    canvas.save();
    canvas.translate(boardCenter.dx, boardCenter.dy);
    canvas.rotate(boardRotation);

    final outer = Paint()..color = Colors.white;
    final second = Paint()..color = const Color(0xFFF28C28);
    final third = Paint()..color = const Color(0xFFCC2B2B);
    final fourth = Paint()..color = const Color(0xFF2D5B9A);
    final inner = Paint()..color = Colors.black;

    canvas.drawCircle(Offset.zero, boardRadius, outer);
    canvas.drawCircle(Offset.zero, boardRadius * 0.5, second);
    canvas.drawCircle(Offset.zero, boardRadius * 0.28, third);
    canvas.drawCircle(Offset.zero, boardRadius * 0.14, fourth);
    canvas.drawCircle(Offset.zero, boardRadius * 0.0625, inner);

    final ring = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, boardRadius * 0.0625, ring);
    canvas.drawCircle(Offset.zero, boardRadius * 0.14, ring);
    canvas.drawCircle(Offset.zero, boardRadius * 0.28, ring);
    canvas.drawCircle(Offset.zero, boardRadius * 0.5, ring);
    canvas.drawCircle(Offset.zero, boardRadius, ring);

    _drawStuckDarts(canvas);
    canvas.restore();
  }

  void _drawDarts(Canvas canvas) {
    final dartPaint = Paint()..color = const Color(0xFF2E3A46);
    final tipPaint = Paint()..color = const Color(0xFFC9A26A);
    final featherPaint = Paint()..color = const Color(0xFF6AA7D8);
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const tiltAngle = -0.14;
    for (final dart in darts) {
      _drawSingleDart(
        canvas,
        Offset(dart.x, dart.y),
        tiltAngle,
        dart.angle,
        dartPaint,
        tipPaint,
        featherPaint,
        highlightPaint,
      );
    }
  }

  void _drawAiDarts(Canvas canvas) {
    final dartPaint = Paint()..color = const Color(0xFFD500F9); // Neon Purple
    final tipPaint = Paint()..color = const Color(0xFFFFD600); // Bright Gold
    final featherPaint = Paint()..color = const Color(0xFF00E676); // Neon Green
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const tiltAngle = -0.14;
    for (final dart in aiDarts) {
      _drawSingleDart(
        canvas,
        Offset(dart.x, dart.y),
        tiltAngle,
        dart.angle,
        dartPaint,
        tipPaint,
        featherPaint,
        highlightPaint,
      );
    }
  }

  void _drawStuckDarts(Canvas canvas) {
    final dartPaint = Paint()..color = const Color(0xFF2E3A46);
    final tipPaint = Paint()..color = const Color(0xFFC9A26A);
    final featherPaint = Paint()..color = const Color(0xFF6AA7D8);
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const tiltAngle = -0.14;
    for (final dart in stuckDarts) {
      _drawSingleDart(
        canvas,
        dart.localOffset,
        tiltAngle,
        dart.angle,
        dartPaint,
        tipPaint,
        featherPaint,
        highlightPaint,
      );
    }
  }

  void _drawInternalStuckDarts(
      Canvas canvas, List<StuckDart> darts, bool rightSide) {
    if (darts.isEmpty) return;

    final dartPaint = Paint()..color = const Color(0xFF2E3A46);
    final tipPaint = Paint()..color = const Color(0xFFC9A26A);
    final featherPaint = Paint()..color = const Color(0xFF6AA7D8);

    const tiltAngle = -0.14;

    for (final dart in darts) {
      canvas.save();
      // If rightSide (AI), we are already scaled -1 horizontally.
      // The localOffset was calculated as (dart.x - pos.dx, dart.y - pos.dy).
      // Since aiCharacter's x scale is -1, a positive localOffset.dx means to the LEFT in screen space.
      // But in the character's local coordinate system (after scale(-1,1)),
      // X increases to the LEFT. So localOffset.dx works naturally?
      // Wait, if dart.x = aiPos.x + 10, then localOffset.dx = 10.
      // After scale(-1, 1), x=10 is 10 pixels to the LEFT of origin.
      // This is exactly where the dart was.
      final dx = rightSide ? -dart.localOffset.dx : dart.localOffset.dx;
      canvas.translate(dx, dart.localOffset.dy);

      // Angle needs adjustment because of the scale(-1,1)
      double angle = dart.angle;
      if (rightSide) {
        angle = pi - angle;
      }

      canvas.rotate(angle);
      canvas.rotate(tiltAngle);

      final body = Rect.fromLTWH(12, -4, 24, 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(4)),
        dartPaint,
      );
      final tip = Path()
        ..moveTo(0, 0)
        ..lineTo(12, -6)
        ..lineTo(12, 6)
        ..close();
      canvas.drawPath(tip, tipPaint);

      final feather = Path()
        ..moveTo(36, 0)
        ..lineTo(48, -10)
        ..lineTo(54, 0)
        ..lineTo(48, 10)
        ..close();
      canvas.drawPath(feather, featherPaint);
      canvas.drawLine(const Offset(36, 0), const Offset(48, 0), featherPaint);
      canvas.restore();
    }
  }

  void _drawSingleDart(
    Canvas canvas,
    Offset position,
    double tiltAngle,
    double dartAngle,
    Paint dartPaint,
    Paint tipPaint,
    Paint featherPaint,
    Paint highlightPaint,
  ) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(dartAngle);
    canvas.rotate(tiltAngle);

    final body = Rect.fromLTWH(12, -4, 24, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(4)),
      dartPaint,
    );
    final tip = Path()
      ..moveTo(0, 0)
      ..lineTo(12, -6)
      ..lineTo(12, 6)
      ..close();
    canvas.drawPath(tip, tipPaint);

    final feather = Path()
      ..moveTo(36, 0)
      ..lineTo(48, -10)
      ..lineTo(54, 0)
      ..lineTo(48, 10)
      ..close();
    canvas.drawPath(feather, featherPaint);

    canvas.drawLine(const Offset(36, 0), const Offset(48, 0), featherPaint);

    canvas.drawLine(
      const Offset(14, -3),
      const Offset(32, -3),
      highlightPaint,
    );
    canvas.restore();
  }

  void _drawCharacter(Canvas canvas,
      {bool rightSide = false,
      double hitFlash = 0,
      List<StuckDart> stuckDarts = const []}) {
    final pos = rightSide ? aiCharacterPosition! : characterPosition;
    final isDead = rightSide ? aiHearts <= 0 : userHearts <= 0;
    final bob = isDead ? 0.0 : sin(characterAnim * pi) * 4;
    final base = pos.translate(0, bob);
    canvas.save();
    final sway = isDead ? 0.0 : sin(time * 2) * 3;
    final lean = isDead ? 0.0 : sin(time * 1.6) * 0.04;
    canvas.translate(base.dx, base.dy + sway);
    if (rightSide) canvas.scale(-1, 1);
    if (isDead) {
      canvas.rotate(rightSide ? pi / 2 : -pi / 2);
      // Sink slightly to stay on ground when rotated
      canvas.translate(0, 15);
    } else {
      canvas.rotate(lean);
    }

    // Draw stuck darts relative to the character (un-swayed/un-leaned base)
    // Actually, drawing them inside the rotated character space makes them follow animations.
    _drawInternalStuckDarts(canvas, stuckDarts, rightSide);
    if (hitFlash > 0) {
      final flashPaint = Paint()
        ..color = const Color(0xFFFF4444).withOpacity(0.5 * hitFlash)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-22, -95, 44, 75), const Radius.circular(14)),
        flashPaint,
      );
    }

    final bool isEnemy = rightSide;
    final bodyPaint = Paint()
      ..color = isEnemy ? const Color(0xFF4D2E2E) : const Color(0xFF2E4D2F);
    final bodyShadow = Paint()
      ..color = isEnemy ? const Color(0xFF3B2525) : const Color(0xFF243B25);
    final headPaint = Paint()
      ..color = isEnemy ? const Color(0xFFC9A88E) : const Color(0xFFE3C9A8);
    final hoodPaint = Paint()
      ..color = isEnemy ? const Color(0xFF3D1E1E) : const Color(0xFF6F3D2E);
    final capePaint = Paint()
      ..color = isEnemy ? const Color(0xFF2E1A1A) : const Color(0xFF273C59);
    final armPaint = Paint()
      ..color = isEnemy ? const Color(0xFF3D1F1F) : const Color(0xFF2B3D1F);
    final beltPaint = Paint()
      ..color = isEnemy ? const Color(0xFF5E3C3C) : const Color(0xFF8B5E3C);
    final bootPaint = Paint()..color = const Color(0xFF1E1E1E);

    final capeFlutter = sin(time * 3) * 4;
    final cape = Path()
      ..moveTo(-18, -28)
      ..lineTo(-28, 16 + capeFlutter)
      ..lineTo(8, 18)
      ..lineTo(-4, -22)
      ..close();
    canvas.drawPath(cape, capePaint);

    final bodyRect = Rect.fromLTWH(-18, -40, 36, 52);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(12)),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-18, -40, 16, 52),
        const Radius.circular(12),
      ),
      bodyShadow,
    );
    canvas.drawCircle(const Offset(0, -52), 14, headPaint);

    final blink = (sin(time * 4) + 1) / 2;
    final eyeHeight = blink > 0.95 ? 0.4 : 1.6;
    final eyePaint = Paint()
      ..color = isEnemy ? const Color(0xFFCC2222) : Colors.black;
    if (isDead) {
      final xPaint = eyePaint..strokeWidth = 2;
      _drawX(canvas, const Offset(-5, -54), 3, xPaint);
      _drawX(canvas, const Offset(5, -54), 3, xPaint);
    } else if (isEnemy) {
      canvas.drawCircle(const Offset(-4, -54), 2.5, eyePaint);
      canvas.drawCircle(const Offset(4, -54), 2.5, eyePaint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: const Offset(-4, -54), width: 3, height: eyeHeight),
          const Radius.circular(2),
        ),
        eyePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: const Offset(4, -54), width: 3, height: eyeHeight),
          const Radius.circular(2),
        ),
        eyePaint,
      );
    }
    canvas.drawCircle(
        const Offset(0, -50),
        1.2,
        Paint()
          ..color =
              isEnemy ? const Color(0xFF8B6B5C) : const Color(0xFFB77C5C));

    final hood = Path()
      ..moveTo(-16, -64)
      ..lineTo(0, -92)
      ..lineTo(16, -64)
      ..close();
    canvas.drawPath(hood, hoodPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-18, -10, 36, 8),
        const Radius.circular(4),
      ),
      beltPaint,
    );

    final legPaint = Paint()..color = const Color(0xFF2B3D1F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-14, 0, 12, 26),
        const Radius.circular(5),
      ),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 0, 12, 26),
        const Radius.circular(5),
      ),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16, 24, 16, 8),
        const Radius.circular(4),
      ),
      bootPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 24, 16, 8),
        const Radius.circular(4),
      ),
      bootPaint,
    );

    final armAngle = -0.4 + (1.2 * characterAnim) + sin(time * 2.4) * 0.08;
    canvas.save();
    canvas.translate(8, -30);
    canvas.rotate(armAngle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, -6, 28, 12),
        const Radius.circular(6),
      ),
      armPaint,
    );
    canvas.drawCircle(const Offset(30, 0), 4, headPaint);
    canvas.restore();

    final bowPaint = Paint()
      ..color = const Color(0xFFB88A4F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      const Rect.fromLTWH(8, -44, 26, 40),
      -pi / 2,
      pi,
      false,
      bowPaint,
    );
    canvas.restore();
  }

  void _drawX(Canvas canvas, Offset center, double size, Paint paint) {
    canvas.drawLine(
        center.translate(-size, -size), center.translate(size, size), paint);
    canvas.drawLine(
        center.translate(size, -size), center.translate(-size, size), paint);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return oldDelegate.darts != darts ||
        oldDelegate.aiDarts != aiDarts ||
        oldDelegate.stuckDarts != stuckDarts ||
        oldDelegate.stones != stones ||
        oldDelegate.score != score ||
        oldDelegate.lives != lives ||
        oldDelegate.boardCenter != boardCenter ||
        oldDelegate.boardRotation != boardRotation ||
        oldDelegate.characterAnim != characterAnim ||
        oldDelegate.rockImage != rockImage ||
        oldDelegate.isAiMode != isAiMode ||
        oldDelegate.aiCharacterPosition != aiCharacterPosition ||
        oldDelegate.topBoundaryY != topBoundaryY ||
        oldDelegate.bottomBoundaryY != bottomBoundaryY ||
        oldDelegate.bloodParticles != bloodParticles ||
        oldDelegate.userHitFlash != userHitFlash ||
        oldDelegate.aiHitFlash != aiHitFlash ||
        oldDelegate.hitSplashes != hitSplashes ||
        oldDelegate.stuckDartsOnUser != stuckDartsOnUser ||
        oldDelegate.stuckDartsOnAi != stuckDartsOnAi ||
        oldDelegate.userHearts != userHearts ||
        oldDelegate.aiHearts != aiHearts;
  }
}

class HudBadge extends StatelessWidget {
  const HudBadge({
    super.key,
    required this.score,
    required this.lives,
  });

  final int score;
  final int lives;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF172640),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Score: $score",
            style: GoogleFonts.luckiestGuy(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(width: 16),
          Text(
            "Lives: $lives",
            style: GoogleFonts.luckiestGuy(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _AiModeHud extends StatelessWidget {
  const _AiModeHud({
    required this.userBloodHearts,
    required this.aiBloodHearts,
    required this.maxBloodHearts,
  });

  final int userBloodHearts;
  final int aiBloodHearts;
  final int maxBloodHearts;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CharacterHudSection(
          label: 'You',
          bloodHearts: userBloodHearts,
          maxBloodHearts: maxBloodHearts,
          isUser: true,
        ),
        const SizedBox(width: 24),
        Container(
          width: 2,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 24),
        _CharacterHudSection(
          label: 'Enemy',
          bloodHearts: aiBloodHearts,
          maxBloodHearts: maxBloodHearts,
          isUser: false,
        ),
      ],
    );
  }
}

class _CharacterHudSection extends StatelessWidget {
  const _CharacterHudSection({
    required this.label,
    required this.bloodHearts,
    required this.maxBloodHearts,
    required this.isUser,
  });

  final String label;
  final int bloodHearts;
  final int maxBloodHearts;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isUser ? Colors.white24 : const Color(0xFF4A2E2E)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.luckiestGuy(
              color: isUser ? const Color(0xFF6AA7D8) : const Color(0xFFD86A6A),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(maxBloodHearts, (i) {
              final filled = i < bloodHearts;
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  filled ? Icons.favorite : Icons.favorite_border,
                  color: filled ? const Color(0xFFE53935) : Colors.white38,
                  size: 22,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class FractionallySizedBox extends StatelessWidget {
  const FractionallySizedBox(
      {super.key, required this.widthFactor, required this.child});

  final double widthFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth * widthFactor)
            .clamp(0.0, constraints.maxWidth);
        return SizedBox(width: w, child: child);
      },
    );
  }
}

class _YouWinBanner extends StatelessWidget {
  const _YouWinBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        "You Win! Tap to play again",
        style: GoogleFonts.luckiestGuy(
          color: Colors.white,
          fontSize: 22,
        ),
      ),
    );
  }
}

class GameOverBanner extends StatelessWidget {
  const GameOverBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF20324F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        "Game Over! Tap to restart",
        style: GoogleFonts.luckiestGuy(
          color: Colors.white,
          fontSize: 22,
        ),
      ),
    );
  }
}

class _GameOverDialog extends StatelessWidget {
  const _GameOverDialog({required this.isWin});

  final bool isWin;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 4),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isWin ? 'You Win!' : 'Game Over!',
              style: GoogleFonts.luckiestGuy(
                color: Colors.white,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ImageDialogButton(
                      image: 'assets/images/restart.png',
                      onTap: () => Navigator.of(context).pop('restart'),
                    ),
                    const SizedBox(height: 4),
                    _ImageDialogButton(
                      image: 'assets/images/go-back.png',
                      onTap: () => Navigator.of(context).pop('back'),
                    )
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

class _ImageDialogButton extends StatelessWidget {
  const _ImageDialogButton({required this.image, required this.onTap});

  final String image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        image,
        width: 220,
        height: 72,
        fit: BoxFit.contain,
      ),
    );
  }
}

class IAPService {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static const String _removeAdsId = 'com.sf.dart.removeads';
  static const String _adsRemovedKey = 'ads_removed';
  static bool _isAdsRemoved = false;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static final ValueNotifier<bool> _adsRemovedNotifier =
      ValueNotifier<bool>(false);

  static bool get isAdsRemoved => _isAdsRemoved;
  static ValueNotifier<bool> get adsRemovedNotifier => _adsRemovedNotifier;

  static Future<void> initialize() async {
    // First, load saved status from local storage
    await _loadSavedStatus();

    final bool available = await _iap.isAvailable();
    debugPrint('IAP Available: $available');
    if (!available) {
      debugPrint('IAP not available on this device/platform');
      return;
    }

    // Check for previously purchased products from StoreKit
    try {
      final productDetails = await _iap.queryProductDetails({_removeAdsId});
      if (productDetails.productDetails.isNotEmpty) {
        debugPrint('Product found in StoreKit');
      } else {
        debugPrint('Product not found in StoreKit');
      }
    } catch (e) {
      debugPrint('Error querying products: $e');
    }

    _subscription = _iap.purchaseStream.listen((purchases) {
      debugPrint('Purchase stream received ${purchases.length} purchase(s)');
      _handlePurchaseUpdates(purchases);
    }, onError: (error) {
      debugPrint('Purchase stream error: $error');
    });
    debugPrint('IAP initialized and listening to purchase stream');
  }

  static Future<void> _loadSavedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_adsRemovedKey) ?? false;
      _isAdsRemoved = saved;
      _adsRemovedNotifier.value = saved;
      debugPrint('Loaded saved ads removal status: $saved');
    } catch (e) {
      debugPrint('Error loading saved status: $e');
    }
  }

  static Future<void> _saveSts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_adsRemovedKey, _isAdsRemoved);
      debugPrint('Saved ads removal status: $_isAdsRemoved');
    } catch (e) {
      debugPrint('Error saving status: $e');
    }
  }

  static void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (var purchase in purchases) {
      debugPrint(
          'Purchase update received: ${purchase.productID} - Status: ${purchase.status}');

      if (purchase.status == PurchaseStatus.purchased) {
        debugPrint('Purchase successful: ${purchase.productID}');
        _isAdsRemoved = true;
        _adsRemovedNotifier.value = true;
        _saveSts(); // Save to local storage
        if (purchase.pendingCompletePurchase) {
          debugPrint('Completing purchase: ${purchase.productID}');
          _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.restored) {
        debugPrint('Purchase restored: ${purchase.productID}');
        _isAdsRemoved = true;
        _adsRemovedNotifier.value = true;
        _saveSts(); // Save to local storage
        if (purchase.pendingCompletePurchase) {
          debugPrint('Completing restored purchase: ${purchase.productID}');
          _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchase.error}');
      } else if (purchase.status == PurchaseStatus.pending) {
        debugPrint('Purchase pending: ${purchase.productID}');
      }
    }
  }

  static Future<void> showRemoveAdsAlert(BuildContext context) async {
    if (Platform.isAndroid) {
      return; // Don't show on Android
    }

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 4),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Remove Ads',
                style: GoogleFonts.luckiestGuy(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Purchase Remove Ads or restore your previous purchase?',
                style: GoogleFonts.luckiestGuy(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white24,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.luckiestGuy(
                          color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      buyRemoveAds();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Purchase',
                      style: GoogleFonts.luckiestGuy(
                          color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      restorePurchases();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF558B2F),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Restore',
                      style: GoogleFonts.luckiestGuy(
                          color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> buyRemoveAds() async {
    try {
      final ProductDetailsResponse response =
          await _iap.queryProductDetails({_removeAdsId});

      debugPrint(
          'IAP queryProductDetails - notFoundIDs: ${response.notFoundIDs}');
      debugPrint(
          'IAP queryProductDetails - productDetails count: ${response.productDetails.length}');

      if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
        debugPrint(
            'Product not found or not configured. Check AppStore/PlayStore setup.');
        return;
      }

      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: response.productDetails.first);
      debugPrint(
          'Initiating purchase for: ${response.productDetails.first.id}');
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('Purchase initiated successfully');
    } catch (e) {
      debugPrint('Error in buyRemoveAds: $e');
    }
  }

  static Future<void> restorePurchases() async {
    try {
      debugPrint('Restoring purchases...');
      await _iap.restorePurchases();
      debugPrint('Restore purchases completed');
    } catch (e) {
      debugPrint('Error in restorePurchases: $e');
    }
  }

  static void dispose() {
    _subscription?.cancel();
  }
}

class AdService {
  static bool get showAds => !IAPService.isAdsRemoved;

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static InterstitialAd? _interstitialAd;
  static int _interstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          _interstitialLoadAttempts++;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= maxFailedLoadAttempts) {
            loadInterstitialAd();
          }
        },
      ),
    );
  }

  static void showInterstitialAd() {
    if (!showAds) return;
    if (_interstitialAd == null) {
      loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  AdSize? _adSize;

  @override
  void initState() {
    super.initState();
    // Listener to rebuild when ads removal status changes
    IAPService.adsRemovedNotifier.addListener(_onAdsStatusChanged);
  }

  void _onAdsStatusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (_bannerAd != null) return;

    final query = MediaQuery.of(context);
    final width = query.size.width.truncate();

    // Get adaptive banner size
    final adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (adaptiveSize == null) return;

    try {
      _bannerAd = BannerAd(
        adUnitId: AdService.bannerAdUnitId,
        request: const AdRequest(),
        size: adaptiveSize,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _adSize = adaptiveSize;
                _isLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
          },
        ),
      )..load();
    } catch (e) {
      debugPrint("Error loading banner ad: $e");
    }
  }

  @override
  void dispose() {
    IAPService.adsRemovedNotifier.removeListener(_onAdsStatusChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.showAds) return const SizedBox.shrink();
    if (!_isLoaded || _bannerAd == null || _adSize == null)
      return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: _adSize!.height.toDouble(),
      child: Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}

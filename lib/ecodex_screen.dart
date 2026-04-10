import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'waste_classifier.dart';

class EcoDexScreen extends StatefulWidget {
  const EcoDexScreen({super.key});

  @override
  State<EcoDexScreen> createState() => _EcoDexScreenState();
}

class _EcoDexScreenState extends State<EcoDexScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraActive = false;
  bool _cameraLoading = false;
  File? _capturedImage;
  bool _flashOn = false;

  bool _analyzing = false;
  String? _resultName;
  String? _resultCategory;
  String? _resultEmoji;
  int _resultConfidence = 0;
  String _ecoTip = 'Point camera at an item\nand press SCAN!';

  final WasteClassifier _classifier = WasteClassifier();

  late AnimationController _scanLineController;
  late AnimationController _resultController;
  late Animation<double> _resultSlide;

  int _selectedTab = 1;
  int _userPoints = 0;

  // Rewards data
  final List<Map<String, dynamic>> _rewards = [
    {
      'name': 'Discord Nitro',
      'points': 2500,
      'icon': '🎮',
      'color': Color(0xFF5865F2),
    },
    {
      'name': 'Spotify Premium',
      'points': 1500,
      'icon': '🎵',
      'color': Color(0xFF1DB954),
    },
    {
      'name': 'YouTube Premium',
      'points': 3000,
      'icon': '📺',
      'color': Color(0xFFFF0000),
    },
  ];

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeOutBack),
    );

    _classifier.init().catchError((_) {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _classifier.dispose();
    _scanLineController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    setState(() => _cameraLoading = true);

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _cameraLoading = false);
      _showPixelDialog('PERMISSION DENIED', 'Camera access is required to scan items.');
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _cameraLoading = false);
        _showPixelDialog('NO CAMERA', 'No camera found on this device.');
        return;
      }

      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _cameraActive = true;
          _cameraLoading = false;
          _capturedImage = null;
          _resultName = null;
          _resultCategory = null;
          _analyzing = false;
          _ecoTip = 'Point camera at an item\nand press SCAN!';
        });
      }
    } catch (e) {
      setState(() => _cameraLoading = false);
      _showPixelDialog('ERROR', 'Failed to initialize camera: $e');
    }
  }

  Future<void> _stopCamera() async {
    await _cameraController?.dispose();
    _cameraController = null;
    if (mounted) {
      setState(() {
        _cameraActive = false;
        _capturedImage = null;
        _resultName = null;
        _resultCategory = null;
        _analyzing = false;
        _ecoTip = 'Point camera at an item\nand press SCAN!';
      });
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_analyzing) return;

    try {
      final xFile = await _cameraController!.takePicture();
      final file = File(xFile.path);

      if (mounted) {
        setState(() {
          _capturedImage = file;
          _cameraActive = false;
          _analyzing = true;
          _resultName = null;
          _resultCategory = null;
        });
      }

      final result = await _classifier.classify(file);

      if (mounted) {
        setState(() {
          _analyzing = false;
          _resultName = result.name;
          _resultCategory = result.category;
          _resultEmoji = result.emoji;
          _resultConfidence = result.confidence;
          _ecoTip = result.tip;
          _userPoints += 10; // Add points for scanning
        });
        _resultController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _analyzing = false);
        _showPixelDialog('SCAN ERROR', 'Failed to classify image.\n$e');
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    _flashOn = !_flashOn;
    await _cameraController!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  void _showPixelDialog(String title, String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: _PixelDialog(title: title, message: message),
      ),
    );
  }

  void _showRedeemDialog(Map<String, dynamic> reward) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            border: Border(
              top: BorderSide(color: Color(0xFF4444AA), width: 3),
              left: BorderSide(color: Color(0xFF4444AA), width: 3),
              right: BorderSide(color: Color(0xFF0A0A1A), width: 3),
              bottom: BorderSide(color: Color(0xFF0A0A1A), width: 3),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${reward['icon']} ${reward['name']}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFFFFCC00),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Redeem for ${reward['points']} points?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF555555),
                        border: Border(
                          top: BorderSide(color: Color(0xFF888888), width: 2),
                          left: BorderSide(color: Color(0xFF888888), width: 2),
                          right: BorderSide(color: Color(0xFF222222), width: 2),
                          bottom: BorderSide(color: Color(0xFF222222), width: 2),
                        ),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_userPoints >= reward['points']) {
                        setState(() {
                          _userPoints -= reward['points'] as int;
                        });
                        Navigator.of(context).pop();
                        _showPixelDialog(
                          'REDEEMED!',
                          'You successfully redeemed ${reward['name']}!\nCode will be sent to your email.',
                        );
                      } else {
                        Navigator.of(context).pop();
                        _showPixelDialog(
                          'INSUFFICIENT POINTS',
                          'You need ${reward['points']} points to redeem this reward.\nCurrent points: $_userPoints',
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4A7A3A),
                        border: Border(
                          top: BorderSide(color: Color(0xFF88CC66), width: 2),
                          left: BorderSide(color: Color(0xFF88CC66), width: 2),
                          right: BorderSide(color: Color(0xFF1A3A0F), width: 2),
                          bottom: BorderSide(color: Color(0xFF1A3A0F), width: 2),
                        ),
                      ),
                      child: const Text(
                        'REDEEM',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0C8),
      body: SafeArea(
        child: Stack(
          children: [
            CustomPaint(size: Size.infinite, painter: _PixelGridPainter()),
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _selectedTab == 0 ? _buildRewardsTab() : _buildPokedexBody(),
                        const SizedBox(height: 16),
                        if (_selectedTab != 0) _buildEcoTipBox(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsTab() {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFCC3300),
            border: Border(
              top: BorderSide(color: Color(0xFFFF6644), width: 4),
              left: BorderSide(color: Color(0xFFFF6644), width: 4),
              right: BorderSide(color: Color(0xFF7A1E00), width: 4),
              bottom: BorderSide(color: Color(0xFF7A1E00), width: 4),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildPointsDisplay(),
              const SizedBox(height: 12),
              ..._rewards.map((reward) => _buildRewardCard(reward)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPointsDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          border: Border(
            top: BorderSide(color: Color(0xFF333355), width: 2),
            left: BorderSide(color: Color(0xFF333355), width: 2),
            right: BorderSide(color: Color(0xFF0A0A1A), width: 2),
            bottom: BorderSide(color: Color(0xFF0A0A1A), width: 2),
          ),
        ),
        child: Column(
          children: [
            const Text(
              'YOUR POINTS',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFFCCCCCC),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_userPoints',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFCC00),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Scan items to earn points!',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Color(0xFF88CC66),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward) {
    bool canAfford = _userPoints >= reward['points'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          border: Border(
            top: BorderSide(color: Color(0xFF333355), width: 2),
            left: BorderSide(color: Color(0xFF333355), width: 2),
            right: BorderSide(color: Color(0xFF0A0A1A), width: 2),
            bottom: BorderSide(color: Color(0xFF0A0A1A), width: 2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: reward['color'],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Center(
                  child: Text(
                    reward['icon'],
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward['name'],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reward['points']} points',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFFFFCC00),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showRedeemDialog(reward),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: canAfford ? const Color(0xFF4A7A3A) : const Color(0xFF555555),
                    border: Border(
                      top: BorderSide(color: canAfford ? const Color(0xFF88CC66) : const Color(0xFF888888), width: 2),
                      left: BorderSide(color: canAfford ? const Color(0xFF88CC66) : const Color(0xFF888888), width: 2),
                      right: BorderSide(color: canAfford ? const Color(0xFF1A3A0F) : const Color(0xFF222222), width: 2),
                      bottom: BorderSide(color: canAfford ? const Color(0xFF1A3A0F) : const Color(0xFF222222), width: 2),
                    ),
                  ),
                  child: Text(
                    canAfford ? 'REDEEM' : 'LOCKED',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F0C8),
        border: Border(bottom: BorderSide(color: Color(0xFFD8D8B0), width: 2)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _stopCamera();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF2D5A1B),
                border: Border(
                  top: BorderSide(color: Color(0xFF5A8F3C), width: 2),
                  left: BorderSide(color: Color(0xFF5A8F3C), width: 2),
                  right: BorderSide(color: Color(0xFF1A3A0F), width: 2),
                  bottom: BorderSide(color: Color(0xFF1A3A0F), width: 2),
                ),
              ),
              child: const Text('◀', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFF2D5A1B)),
                child: const Text('🌿', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              const Text(
                'EcoDex',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D5A1B),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const Spacer(),
          _PixelIconButton(icon: '🔔', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildPokedexBody() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFCC3300),
        border: Border(
          top: BorderSide(color: Color(0xFFFF6644), width: 4),
          left: BorderSide(color: Color(0xFFFF6644), width: 4),
          right: BorderSide(color: Color(0xFF7A1E00), width: 4),
          bottom: BorderSide(color: Color(0xFF7A1E00), width: 4),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildIndicatorLights(),
            ),
          ),
          const SizedBox(height: 6),
          _buildScreen(),
          const SizedBox(height: 12),
          _buildScanBar(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _cameraActive ? _toggleFlash : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _flashOn ? const Color(0xFFFFCC00) : const Color(0xFF555555),
                      border: Border(
                        top: BorderSide(color: _flashOn ? const Color(0xFFFFEE88) : const Color(0xFF888888), width: 2),
                        left: BorderSide(color: _flashOn ? const Color(0xFFFFEE88) : const Color(0xFF888888), width: 2),
                        right: BorderSide(color: _flashOn ? const Color(0xFFAA8800) : const Color(0xFF222222), width: 2),
                        bottom: BorderSide(color: _flashOn ? const Color(0xFFAA8800) : const Color(0xFF222222), width: 2),
                      ),
                    ),
                    child: Text(
                      'FLASH',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _flashOn ? Colors.black : Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildResultPanel(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildIndicatorLights() {
    return Row(
      children: [
        _buildLight(const Color(0xFF4499FF), size: 20),
        const SizedBox(width: 6),
        _buildLight(const Color(0xFFFF4444), size: 10),
        const SizedBox(width: 4),
        _buildLight(const Color(0xFFFFCC00), size: 10),
        const SizedBox(width: 4),
        _buildLight(const Color(0xFF44CC44), size: 10),
      ],
    );
  }

  Widget _buildLight(Color color, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black38, width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 4, spreadRadius: 1)],
      ),
    );
  }

  Widget _buildScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 240,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          border: Border(
            top: BorderSide(color: Color(0xFF444444), width: 3),
            left: BorderSide(color: Color(0xFF444444), width: 3),
            right: BorderSide(color: Color(0xFF111111), width: 3),
            bottom: BorderSide(color: Color(0xFF111111), width: 3),
          ),
        ),
        child: ClipRect(
          child: Stack(
            children: [
              _buildScreenContent(),
              _buildCornerBrackets(),
              if (_cameraActive)
                AnimatedBuilder(
                  animation: _scanLineController,
                  builder: (_, __) => Positioned(
                    top: 240 * _scanLineController.value - 2,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      color: const Color(0xFF44FF44).withOpacity(0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreenContent() {
    if (_cameraLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF44CC44)),
            SizedBox(height: 12),
            Text(
              'INITIALIZING...',
              style: TextStyle(fontFamily: 'monospace', color: Color(0xFF44CC44), fontSize: 12, letterSpacing: 2),
            ),
          ],
        ),
      );
    }

    if (_analyzing) {
      return Container(
        color: const Color(0xFF0A1A0A),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF44FF88), strokeWidth: 2),
              SizedBox(height: 16),
              Text(
                'ANALYZING...',
                style: TextStyle(fontFamily: 'monospace', color: Color(0xFF44FF88), fontSize: 13, letterSpacing: 3),
              ),
            ],
          ),
        ),
      );
    }

    if (_capturedImage != null) {
      return Image.file(_capturedImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }

    if (_cameraActive && _cameraController != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize?.height ?? 1,
            height: _cameraController!.value.previewSize?.width ?? 1,
            child: CameraPreview(_cameraController!),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF0A1A0A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomPaint(size: const Size(64, 64), painter: _IdleScreenPainter()),
            const SizedBox(height: 16),
            const Text(
              'PRESS SCAN\nTO BEGIN',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'monospace', color: Color(0xFF2A6B1A), fontSize: 13, letterSpacing: 2, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBrackets() {
    const bracketColor = Color(0xFF44FF44);
    const bracketSize = 16.0;
    const bracketWidth = 2.5;
    return Stack(
      children: [
        Positioned(top: 10, left: 10, child: CustomPaint(size: const Size(bracketSize, bracketSize), painter: _BracketPainter(bracketColor, bracketWidth, corner: 'TL'))),
        Positioned(top: 10, right: 10, child: CustomPaint(size: const Size(bracketSize, bracketSize), painter: _BracketPainter(bracketColor, bracketWidth, corner: 'TR'))),
        Positioned(bottom: 10, left: 10, child: CustomPaint(size: const Size(bracketSize, bracketSize), painter: _BracketPainter(bracketColor, bracketWidth, corner: 'BL'))),
        Positioned(bottom: 10, right: 10, child: CustomPaint(size: const Size(bracketSize, bracketSize), painter: _BracketPainter(bracketColor, bracketWidth, corner: 'BR'))),
      ],
    );
  }

  Widget _buildScanBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          border: Border(
            top: BorderSide(color: Color(0xFF333355), width: 2),
            left: BorderSide(color: Color(0xFF333355), width: 2),
            right: BorderSide(color: Color(0xFF0A0A1A), width: 2),
            bottom: BorderSide(color: Color(0xFF0A0A1A), width: 2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A4A),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF0A0A1A), width: 2),
                  right: BorderSide(color: Color(0xFF0A0A1A), width: 2),
                  top: BorderSide(color: Color(0xFF444466), width: 2),
                  left: BorderSide(color: Color(0xFF444466), width: 2),
                ),
              ),
              child: Center(
                child: Text(
                  _analyzing ? '...' : '[ ]',
                  style: const TextStyle(color: Color(0xFF44FF88), fontSize: 14, fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _analyzing
                        ? 'ANALYZING...'
                        : _resultName != null
                        ? 'Confidence Score'
                        : _cameraActive
                        ? 'READY TO SCAN'
                        : 'STANDBY',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFCCCCCC),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A0A1A),
                      border: Border(
                        top: BorderSide(color: Color(0xFF0A0A1A), width: 1),
                        left: BorderSide(color: Color(0xFF0A0A1A), width: 1),
                        right: BorderSide(color: Color(0xFF333355), width: 1),
                        bottom: BorderSide(color: Color(0xFF333355), width: 1),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (ctx, constraints) {
                        final fillWidth = constraints.maxWidth * (_resultName != null ? 1.0 : 0);
                        return Container(
                          width: fillWidth,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _resultName != null
                                  ? [const Color(0xFF44CC44), const Color(0xFF88FF88)]
                                  : [const Color(0xFF44FF88), const Color(0xFF00CCFF)],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _resultName != null ? '$_resultConfidence%' : '--',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFCC00),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AnimatedBuilder(
        animation: _resultController,
        builder: (_, __) {
          return Transform.translate(
            offset: Offset(0, _resultName != null ? _resultSlide.value : 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _resultName != null ? const Color(0xFF4A7A3A) : const Color(0xFF333333),
                border: Border(
                  top: BorderSide(color: _resultName != null ? const Color(0xFF88CC66) : const Color(0xFF555555), width: 2),
                  left: BorderSide(color: _resultName != null ? const Color(0xFF88CC66) : const Color(0xFF555555), width: 2),
                  right: BorderSide(color: _resultName != null ? const Color(0xFF1A3A0F) : const Color(0xFF111111), width: 2),
                  bottom: BorderSide(color: _resultName != null ? const Color(0xFF1A3A0F) : const Color(0xFF111111), width: 2),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _resultName != null ? '✦' : '○',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _resultName != null
                              ? '${_resultEmoji ?? ''} ${_resultName!}'
                              : 'Awaiting scan...',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: _resultName != null ? 17 : 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (_resultCategory != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Category: $_resultCategory',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Color(0xFFCCEEBB),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_resultName != null)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D5A1B),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF88CC66), width: 2),
                      ),
                      child: const Center(child: Text('i', style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w900))),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEcoTipBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF0E0),
        border: Border(
          top: BorderSide(color: Color(0xFFFFD580), width: 2),
          left: BorderSide(color: Color(0xFFFFD580), width: 2),
          right: BorderSide(color: Color(0xFFBB8800), width: 2),
          bottom: BorderSide(color: Color(0xFFBB8800), width: 2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(
                  text: 'Eco Tip: ',
                  style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF5A3A00)),
                ),
                TextSpan(
                  text: _ecoTip,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFF5A3A00), height: 1.4),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF0F0C8),
        border: Border(top: BorderSide(color: Color(0xFFD8D8B0), width: 2)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: '🏠', label: 'HOME', selected: _selectedTab == 0, onTap: () {
            setState(() => _selectedTab = 0);
            _stopCamera();
          }),
          GestureDetector(
            onTap: () {
              setState(() => _selectedTab = 1);
              if (_analyzing) return;
              if (_cameraActive) {
                _captureAndAnalyze();
              } else if (_capturedImage != null || _resultName != null) {
                _stopCamera().then((_) => _startCamera());
              } else {
                _startCamera();
              }
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _selectedTab == 1 ? const Color(0xFFCC3300) : const Color(0xFF4A7A3A),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedTab == 1 ? const Color(0xFFFF6644) : const Color(0xFF88CC66),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_selectedTab == 1 ? const Color(0xFFCC3300) : const Color(0xFF4A7A3A)).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _analyzing ? '...' : _cameraActive ? '[+]' : _resultName != null ? '<>' : '( )',
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          _NavItem(icon: '📊', label: 'RANK', selected: _selectedTab == 2, onTap: () => setState(() => _selectedTab = 2)),
          _NavItem(icon: '👤', label: 'USER', selected: _selectedTab == 3, onTap: () => setState(() => _selectedTab = 3)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: selected
            ? const BoxDecoration(color: Color(0xFF4A7A3A), borderRadius: BorderRadius.all(Radius.circular(8)))
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: selected ? Colors.white : const Color(0xFF5A6A4A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PixelIconButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  const _PixelIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFE0E0A8),
          border: Border(
            top: BorderSide(color: Color(0xFFF8F8E0), width: 2),
            left: BorderSide(color: Color(0xFFF8F8E0), width: 2),
            right: BorderSide(color: Color(0xFF888866), width: 2),
            bottom: BorderSide(color: Color(0xFF888866), width: 2),
          ),
        ),
        child: Text(icon, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

class _PixelDialog extends StatelessWidget {
  final String title;
  final String message;
  const _PixelDialog({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(
          top: BorderSide(color: Color(0xFF4444AA), width: 3),
          left: BorderSide(color: Color(0xFF4444AA), width: 3),
          right: BorderSide(color: Color(0xFF0A0A1A), width: 3),
          bottom: BorderSide(color: Color(0xFF0A0A1A), width: 3),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFFFCC00), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFCC3300),
                border: Border(
                  top: BorderSide(color: Color(0xFFFF6644), width: 2),
                  left: BorderSide(color: Color(0xFFFF6644), width: 2),
                  right: BorderSide(color: Color(0xFF7A1E00), width: 2),
                  bottom: BorderSide(color: Color(0xFF7A1E00), width: 2),
                ),
              ),
              child: const Text('OK', style: TextStyle(fontFamily: 'monospace', color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double width;
  final String corner;
  _BracketPainter(this.color, this.width, {required this.corner});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = width..style = PaintingStyle.stroke;
    final s = size.width;
    switch (corner) {
      case 'TL': canvas.drawLine(Offset(0, s), Offset(0, 0), paint); canvas.drawLine(Offset(0, 0), Offset(s, 0), paint); break;
      case 'TR': canvas.drawLine(Offset(0, 0), Offset(s, 0), paint); canvas.drawLine(Offset(s, 0), Offset(s, s), paint); break;
      case 'BL': canvas.drawLine(Offset(0, 0), Offset(0, s), paint); canvas.drawLine(Offset(0, s), Offset(s, s), paint); break;
      case 'BR': canvas.drawLine(Offset(s, 0), Offset(s, s), paint); canvas.drawLine(Offset(s, s), Offset(0, s), paint); break;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _IdleScreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ps = size.width / 16;
    final green = Paint()..color = const Color(0xFF2A7A1A);
    final lime = Paint()..color = const Color(0xFF44CC44);
    final dark = Paint()..color = const Color(0xFF0A2A0A);

    final pixels = {
      green: [[7,2],[8,2],[6,3],[7,3],[8,3],[9,3],[5,4],[6,4],[7,4],[8,4],[9,4],[10,4],[4,5],[5,5],[6,5],[7,5],[8,5],[9,5],[10,5],[11,5],[5,6],[6,6],[7,6],[8,6],[9,6],[10,6],[7,7],[8,7],[7,8],[7,9],[8,9],[6,10],[7,10],[8,10],[9,10],[7,11],[8,11],[7,12],[7,13],[7,14],[7,15]],
      lime: [[7,3],[8,3],[6,4],[7,4],[8,4],[6,5],[7,5],[8,5]],
      dark: [[6,2],[9,2],[5,3],[10,3],[4,4],[11,4],[3,5],[12,5]],
    };

    for (final entry in pixels.entries) {
      for (final p in entry.value) {
        canvas.drawRect(Rect.fromLTWH(p[0] * ps, p[1] * ps, ps - 0.5, ps - 0.5), entry.key);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _PixelGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFD8D8B0)..strokeWidth = 0.5;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
import 'package:flutter/material.dart';
import 'ecodex_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapDown(_) => setState(() => _pressed = true);
  void _onTapUp(_) => setState(() => _pressed = false);
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0C8),
      body: SafeArea(
        child: Stack(
          children: [
            // Pixel grid background
            CustomPaint(
              size: Size.infinite,
              painter: _PixelGridPainter(),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  _PixelText(
                    'ECO',
                    fontSize: 52,
                    color: const Color(0xFF2D5A1B),
                    shadowColor: const Color(0xFF8FBC5A),
                  ),
                  _PixelText(
                    'DEX',
                    fontSize: 52,
                    color: const Color(0xFFCC3300),
                    shadowColor: const Color(0xFFFF8855),
                  ),
                  const SizedBox(height: 8),
                  // Pixel leaf decorations
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _pixelLeaf(flip: true),
                      const SizedBox(width: 12),
                      Container(
                        width: 6,
                        height: 6,
                        color: const Color(0xFF2D5A1B),
                      ),
                      const SizedBox(width: 12),
                      _pixelLeaf(flip: false),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // Animated EcoDex Button
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: GestureDetector(
                      onTapDown: _onTapDown,
                      onTapUp: _onTapUp,
                      onTapCancel: _onTapCancel,
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, anim, __) =>
                                FadeTransition(
                                  opacity: anim,
                                  child: const EcoDexScreen(),
                                ),
                            transitionDuration:
                            const Duration(milliseconds: 400),
                          ),
                        );
                      },
                      child: AnimatedScale(
                        scale: _pressed ? 0.92 : 1.0,
                        duration: const Duration(milliseconds: 80),
                        child: _PixelButton(
                          label: '▶  OPEN ECODEX',
                          bgColor: const Color(0xFFCC3300),
                          shadowColor: const Color(0xFF7A1E00),
                          textColor: Colors.white,
                          width: 260,
                          height: 58,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Sub caption
                  _PixelText(
                    'SCAN · IDENTIFY · RECYCLE',
                    fontSize: 11,
                    color: const Color(0xFF2D5A1B),
                    shadowColor: Colors.transparent,
                    letterSpacing: 2.5,
                  ),
                  const SizedBox(height: 60),
                  // Bottom sprite row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PixelSprite(color: const Color(0xFF5A8F3C), size: 14),
                      const SizedBox(width: 16),
                      _PixelSprite(color: const Color(0xFFCC3300), size: 18),
                      const SizedBox(width: 16),
                      _PixelSprite(color: const Color(0xFF5A8F3C), size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pixelLeaf({required bool flip}) {
    return Transform.scale(
      scaleX: flip ? -1 : 1,
      child: CustomPaint(
        size: const Size(28, 18),
        painter: _LeafPainter(),
      ),
    );
  }
}

// ─── Pixel Text Widget ────────────────────────────────────────────────────────
class _PixelText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final Color shadowColor;
  final double letterSpacing;

  const _PixelText(
      this.text, {
        required this.fontSize,
        required this.color,
        required this.shadowColor,
        this.letterSpacing = 4,
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: letterSpacing,
        height: 1.0,
        shadows: shadowColor != Colors.transparent
            ? [
          Shadow(offset: const Offset(3, 3), color: shadowColor),
          Shadow(offset: const Offset(4, 4), color: Colors.black26),
        ]
            : null,
      ),
    );
  }
}

// ─── Pixel Button Widget ──────────────────────────────────────────────────────
class _PixelButton extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color shadowColor;
  final Color textColor;
  final double width;
  final double height;

  const _PixelButton({
    required this.label,
    required this.bgColor,
    required this.shadowColor,
    required this.textColor,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        // Pixel-style border (no rounded corners)
        border: Border(
          top: BorderSide(color: _lighten(bgColor), width: 3),
          left: BorderSide(color: _lighten(bgColor), width: 3),
          right: BorderSide(color: shadowColor, width: 3),
          bottom: BorderSide(color: shadowColor, width: 3),
        ),
      ),
      child: Stack(
        children: [
          // Inner shadow pixel effect
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: width - 3,
              height: height - 3,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: shadowColor.withOpacity(0.4), width: 2),
                  right: BorderSide(color: shadowColor.withOpacity(0.4), width: 2),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    offset: const Offset(2, 2),
                    color: shadowColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _lighten(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + 0.2).clamp(0, 1)).toColor();
  }
}

// ─── Pixel Sprite (decorative) ────────────────────────────────────────────────
class _PixelSprite extends StatelessWidget {
  final Color color;
  final double size;
  const _PixelSprite({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 2, size * 2),
      painter: _SpritePainter(color),
    );
  }
}

class _SpritePainter extends CustomPainter {
  final Color color;
  _SpritePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final dark = Paint()..color = color.withOpacity(0.5);
    final ps = size.width / 8;
    // Simple pixel leaf/plant sprite
    final pixels = [
      [3, 0], [4, 0],
      [2, 1], [3, 1], [4, 1], [5, 1],
      [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2],
      [2, 3], [3, 3], [4, 3], [5, 3],
      [3, 4], [4, 4],
      [3, 5],
      [3, 6],
      [3, 7],
    ];
    for (final p in pixels) {
      canvas.drawRect(
        Rect.fromLTWH(p[0] * ps, p[1] * ps, ps, ps),
        p[1] < 4 ? paint : dark,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Leaf Painter ─────────────────────────────────────────────────────────────
class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF5A8F3C);
    final ps = size.width / 7;
    final pixels = [
      [3, 0], [4, 0], [5, 0],
      [2, 1], [3, 1], [4, 1], [5, 1], [6, 1],
      [1, 2], [2, 2], [3, 2], [4, 2], [5, 2],
      [0, 3], [1, 3], [2, 3], [3, 3],
      [1, 4], [2, 4],
    ];
    for (final p in pixels) {
      canvas.drawRect(
        Rect.fromLTWH(p[0] * ps, p[1] * ps, ps - 0.5, ps - 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Pixel Grid Background Painter ───────────────────────────────────────────
class _PixelGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8D8B0)
      ..strokeWidth = 0.5;
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
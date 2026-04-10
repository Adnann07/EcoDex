import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'register_screen.dart';
import 'api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _blinkController;


  static const String _baseUrl = 'https://ecodex-production.up.railway.app';


  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ApiService.setToken(data['token']); // ADD THIS
        if (!mounted) return;
        // Navigate to HomeScreen and clear stack
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => FadeTransition(
              opacity: anim,
              child: const HomeScreen(),
            ),
            transitionDuration: const Duration(milliseconds: 400),
          ),
              (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = data['message'] ??
              data['errors']?['email']?[0] ??
              'LOGIN FAILED';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'CONNECTION ERROR';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0C8),
      body: SafeArea(
        child: Stack(
          children: [
            CustomPaint(size: Size.infinite, painter: _PixelGridPainter()),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  _PixelText('ECO', fontSize: 44, color: const Color(0xFF2D5A1B), shadowColor: const Color(0xFF8FBC5A)),
                  _PixelText('DEX', fontSize: 44, color: const Color(0xFFCC3300), shadowColor: const Color(0xFFFF8855)),
                  const SizedBox(height: 6),
                  _PixelText('PLAYER LOGIN', fontSize: 11, color: const Color(0xFF2D5A1B), shadowColor: Colors.transparent, letterSpacing: 3),
                  const SizedBox(height: 36),


                  _PixelBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PixelText('► EMAIL', fontSize: 11, color: const Color(0xFFCCCCCC), shadowColor: Colors.transparent, letterSpacing: 2),
                        const SizedBox(height: 6),
                        _PixelTextField(
                          controller: _emailController,
                          hint: 'enter email...',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _PixelText('► PASSWORD', fontSize: 11, color: const Color(0xFFCCCCCC), shadowColor: Colors.transparent, letterSpacing: 2),
                        const SizedBox(height: 6),
                        _PixelTextField(
                          controller: _passwordController,
                          hint: 'enter password...',
                          obscure: _obscurePassword,
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                            child: Text(
                              _obscurePassword ? '👁' : '🙈',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF7A1E00),
                              border: Border(
                                top: BorderSide(color: Color(0xFFFF4444), width: 2),
                                left: BorderSide(color: Color(0xFFFF4444), width: 2),
                                right: BorderSide(color: Color(0xFF330000), width: 2),
                                bottom: BorderSide(color: Color(0xFF330000), width: 2),
                              ),
                            ),
                            child: Text(
                              '✖ $_errorMessage',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Color(0xFFFF8888),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        GestureDetector(
                          onTap: _loading ? null : _login,
                          child: _loading
                              ? _LoadingButton()
                              : _PixelButton(
                            label: '▶  LOGIN',
                            bgColor: const Color(0xFF2D5A1B),
                            shadowColor: const Color(0xFF1A3A0F),
                            textColor: Colors.white,
                            width: double.infinity,
                            height: 52,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, anim, __) => FadeTransition(
                            opacity: anim,
                            child: const RegisterScreen(),
                          ),
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E0A8),
                        border: Border(
                          top: BorderSide(color: Color(0xFFF8F8E0), width: 2),
                          left: BorderSide(color: Color(0xFFF8F8E0), width: 2),
                          right: BorderSide(color: Color(0xFF888866), width: 2),
                          bottom: BorderSide(color: Color(0xFF888866), width: 2),
                        ),
                      ),
                      child: const Text(
                        'NEW PLAYER? REGISTER ▶',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2D5A1B),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PixelSprite(color: const Color(0xFF5A8F3C), size: 12),
                      const SizedBox(width: 16),
                      _PixelSprite(color: const Color(0xFFCC3300), size: 16),
                      const SizedBox(width: 16),
                      _PixelSprite(color: const Color(0xFF5A8F3C), size: 12),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _PixelBox extends StatelessWidget {
  final Widget child;
  const _PixelBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(
          top: BorderSide(color: Color(0xFF4444AA), width: 3),
          left: BorderSide(color: Color(0xFF4444AA), width: 3),
          right: BorderSide(color: Color(0xFF0A0A1A), width: 3),
          bottom: BorderSide(color: Color(0xFF0A0A1A), width: 3),
        ),
      ),
      child: child,
    );
  }
}

class _PixelTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  const _PixelTextField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A1A),
        border: Border(
          top: BorderSide(color: Color(0xFF0A0A1A), width: 2),
          left: BorderSide(color: Color(0xFF0A0A1A), width: 2),
          right: BorderSide(color: Color(0xFF333355), width: 2),
          bottom: BorderSide(color: Color(0xFF333355), width: 2),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'monospace',
          color: Color(0xFF44FF88),
          fontSize: 14,
          letterSpacing: 1,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFF334433),
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: InputBorder.none,
          suffixIcon: suffixIcon != null
              ? Padding(
            padding: const EdgeInsets.only(right: 10),
            child: suffixIcon,
          )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        cursorColor: const Color(0xFF44FF88),
        cursorWidth: 3,
      ),
    );
  }
}

class _LoadingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFF1A3A0F),
        border: Border(
          top: BorderSide(color: Color(0xFF2D5A1B), width: 3),
          left: BorderSide(color: Color(0xFF2D5A1B), width: 3),
          right: BorderSide(color: Color(0xFF0A1A05), width: 3),
          bottom: BorderSide(color: Color(0xFF0A1A05), width: 3),
        ),
      ),
      child: const Center(
        child: Text(
          '⟳  LOADING...',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF44FF88),
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}


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
        border: Border(
          top: BorderSide(color: _lighten(bgColor), width: 3),
          left: BorderSide(color: _lighten(bgColor), width: 3),
          right: BorderSide(color: shadowColor, width: 3),
          bottom: BorderSide(color: shadowColor, width: 3),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: 2,
            shadows: [Shadow(offset: const Offset(2, 2), color: shadowColor)],
          ),
        ),
      ),
    );
  }

  Color _lighten(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + 0.2).clamp(0, 1)).toColor();
  }
}

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
    final pixels = [
      [3, 0], [4, 0],
      [2, 1], [3, 1], [4, 1], [5, 1],
      [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2],
      [2, 3], [3, 3], [4, 3], [5, 3],
      [3, 4], [4, 4],
      [3, 5], [3, 6], [3, 7],
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
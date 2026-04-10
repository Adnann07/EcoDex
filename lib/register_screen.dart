import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  String? _successMessage;

  // ── Change this to your actual backend URL ────────────────────────────────
  static const String _baseUrl = 'https://ecodex-production.up.railway.app';
  // For physical device use your PC's local IP e.g. 'http://192.168.1.x:8080'

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        setState(() => _successMessage = 'REGISTERED! REDIRECTING...');
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
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
        // Extract first validation error
        String error = 'REGISTRATION FAILED';
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          error = errors.values.first[0].toString().toUpperCase();
        } else if (data['message'] != null) {
          error = data['message'].toString().toUpperCase();
        }
        setState(() => _errorMessage = error);
      }
    } catch (e) {
      setState(() => _errorMessage = 'CONNECTION ERROR');
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
                  const SizedBox(height: 40),

                  // ── Back button ────────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF333333),
                          border: Border(
                            top: BorderSide(color: Color(0xFF555555), width: 2),
                            left: BorderSide(color: Color(0xFF555555), width: 2),
                            right: BorderSide(color: Color(0xFF111111), width: 2),
                            bottom: BorderSide(color: Color(0xFF111111), width: 2),
                          ),
                        ),
                        child: const Text(
                          '◀ BACK',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Title ──────────────────────────────────────────────
                  _PixelText('NEW', fontSize: 38, color: const Color(0xFF2D5A1B), shadowColor: const Color(0xFF8FBC5A)),
                  _PixelText('PLAYER', fontSize: 38, color: const Color(0xFFCC3300), shadowColor: const Color(0xFFFF8855)),
                  const SizedBox(height: 6),
                  _PixelText('CREATE ACCOUNT', fontSize: 11, color: const Color(0xFF2D5A1B), shadowColor: Colors.transparent, letterSpacing: 2.5),
                  const SizedBox(height: 28),

                  // ── Register Box ───────────────────────────────────────
                  _PixelBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        _PixelText('► NAME', fontSize: 11, color: const Color(0xFFCCCCCC), shadowColor: Colors.transparent, letterSpacing: 2),
                        const SizedBox(height: 6),
                        _PixelTextField(
                          controller: _nameController,
                          hint: 'enter your name...',
                        ),
                        const SizedBox(height: 14),

                        // Email
                        _PixelText('► EMAIL', fontSize: 11, color: const Color(0xFFCCCCCC), shadowColor: Colors.transparent, letterSpacing: 2),
                        const SizedBox(height: 6),
                        _PixelTextField(
                          controller: _emailController,
                          hint: 'enter email...',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),

                        // Password
                        _PixelText('► PASSWORD', fontSize: 11, color: const Color(0xFFCCCCCC), shadowColor: Colors.transparent, letterSpacing: 2),
                        const SizedBox(height: 6),
                        _PixelTextField(
                          controller: _passwordController,
                          hint: 'min 8 characters...',
                          obscure: _obscurePassword,
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                            child: Text(_obscurePassword ? '👁' : '🙈', style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Confirm Password
                        _PixelText('► CONFIRM PASSWORD', fontSize: 11, color: const Color(0xFFCCCCCC), shadowColor: Colors.transparent, letterSpacing: 2),
                        const SizedBox(height: 6),
                        _PixelTextField(
                          controller: _confirmPasswordController,
                          hint: 'repeat password...',
                          obscure: _obscureConfirm,
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            child: Text(_obscureConfirm ? '👁' : '🙈', style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Error message ──────────────────────────────
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

                        // ── Success message ────────────────────────────
                        if (_successMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A3A0F),
                              border: Border(
                                top: BorderSide(color: Color(0xFF44FF88), width: 2),
                                left: BorderSide(color: Color(0xFF44FF88), width: 2),
                                right: BorderSide(color: Color(0xFF0A1A05), width: 2),
                                bottom: BorderSide(color: Color(0xFF0A1A05), width: 2),
                              ),
                            ),
                            child: Text(
                              '✔ $_successMessage',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Color(0xFF44FF88),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Register Button ────────────────────────────
                        GestureDetector(
                          onTap: _loading ? null : _register,
                          child: _loading
                              ? _LoadingButton()
                              : _PixelButton(
                            label: '▶  CREATE ACCOUNT',
                            bgColor: const Color(0xFFCC3300),
                            shadowColor: const Color(0xFF7A1E00),
                            textColor: Colors.white,
                            width: double.infinity,
                            height: 52,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Login link ─────────────────────────────────────────
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (_, anim, __) => FadeTransition(
                            opacity: anim,
                            child: const LoginScreen(),
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
                        'HAVE ACCOUNT? LOGIN ▶',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

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
        color: Color(0xFF7A1E00),
        border: Border(
          top: BorderSide(color: Color(0xFFCC3300), width: 3),
          left: BorderSide(color: Color(0xFFCC3300), width: 3),
          right: BorderSide(color: Color(0xFF330A00), width: 3),
          bottom: BorderSide(color: Color(0xFF330A00), width: 3),
        ),
      ),
      child: const Center(
        child: Text(
          '⟳  LOADING...',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFF8855),
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
            fontSize: 15,
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
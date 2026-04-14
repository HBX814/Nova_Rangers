import 'dart:math' as math;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _authError;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _particleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _handleSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _authError = null;
    });
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(() => _isLoading = false);
        context.go('/dashboard');
        return;
      }
      setState(() {
        _isLoading = false;
        _authError = 'Sign in failed [${res.statusCode}]';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _authError = e.toString();
      });
    }
  }

  void _handleGoogleSignIn() {
    _handleSignIn();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0D2137),
              Color(0xFF1A2744),
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildParticle(
              top: 40,
              left: 22,
              size: 26,
              opacity: 0.12,
              phase: 0.0,
            ),
            _buildParticle(
              top: 110,
              right: 48,
              size: 16,
              opacity: 0.18,
              phase: 0.9,
            ),
            _buildParticle(
              top: 300,
              left: 16,
              size: 32,
              opacity: 0.24,
              phase: 1.8,
            ),
            _buildParticle(
              bottom: 150,
              right: 24,
              size: 22,
              opacity: 0.3,
              phase: 2.6,
            ),
            _buildParticle(
              bottom: 60,
              left: 70,
              size: 14,
              opacity: 0.1,
              phase: 3.2,
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ── Hero section ──────────────────────────────────────
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1565C0),
                                  Color(0xFF42A5F5),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF1565C0).withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Color(0xFF90CAF9)],
                            ).createShader(bounds),
                            child: const Text(
                              'CommunityPulse',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Coordinate. Respond. Impact.',
                            style: TextStyle(
                              color: Color(0xFFB0C4DE),
                              fontSize: 16,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // ── Login card ────────────────────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1B2A).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color:
                                    const Color(0xFF1565C0).withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF000000)
                                      .withOpacity(0.5),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Title
                                    const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Email field
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        return null;
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        labelStyle:
                                            TextStyle(color: Color(0xFFB0C4DE)),
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: Color(0xFF90CAF9),
                                        ),
                                        filled: true,
                                        fillColor: Color(0xFF1A2744),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(14),
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFF2A4A7F),
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(14),
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFF2A4A7F),
                                            width: 1.6,
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(14),
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFF2A4A7F),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Password field
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _handleSignIn(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: const TextStyle(
                                          color: Color(0xFFB0C4DE),
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.lock_outlined,
                                          color: Color(0xFF90CAF9),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFF1A2744),
                                        enabledBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(14),
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFF2A4A7F),
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(14),
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFF2A4A7F),
                                            width: 1.6,
                                          ),
                                        ),
                                        border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(14),
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFF2A4A7F),
                                            width: 1,
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: const Color(0xFF90CAF9),
                                          ),
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                          tooltip: _obscurePassword
                                              ? 'Show password'
                                              : 'Hide password',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    if (_authError != null) ...[
                                      Text(
                                        _authError!,
                                        style: const TextStyle(
                                          color: Color(0xFFC62828),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    // Sign In button
                                    Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF1565C0),
                                            Color(0xFF0D47A1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF1565C0)
                                                .withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: FilledButton(
                                        onPressed:
                                            _isLoading ? null : _handleSignIn,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          disabledBackgroundColor:
                                              Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                'Sign In',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Google sign-in button
                                    SizedBox(
                                      height: 50,
                                      child: OutlinedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleGoogleSignIn,
                                        icon: _GoogleIcon(),
                                        label: const Text(
                                          'Continue with Google',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFFB0C4DE),
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFF2A4A7F),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ── Footer ────────────────────────────────────────────
                          const SizedBox(height: 32),
                          const Text(
                            'CommunityPulse © 2025 Nova Rangers',
                            style: TextStyle(
                              color: Color(0xFF6B8CAE),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticle({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required double size,
    required double opacity,
    required double phase,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          final wave = math.sin((_particleController.value * 2 * math.pi) + phase);
          final scale = 0.9 + (wave * 0.18);
          final alpha = (opacity + (wave * 0.05)).clamp(0.1, 0.3);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withOpacity(alpha),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Inline Google "G" icon (no external asset needed) ──────────────────────

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Full circle in grey (base)
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = const Color(0xFFE0E0E0),
    );

    // Blue segment (right)
    _drawArc(canvas, cx, cy, r, -30, 120, const Color(0xFF4285F4));
    // Red segment (top-left)
    _drawArc(canvas, cx, cy, r, 90, 120, const Color(0xFFEA4335));
    // Yellow segment (bottom-left)
    _drawArc(canvas, cx, cy, r, 210, 120, const Color(0xFFFBBC05));
    // Green segment (bottom)
    _drawArc(canvas, cx, cy, r, 150, 60, const Color(0xFF34A853));

    // White centre cutout
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.55,
      Paint()..color = Colors.white,
    );

    // Blue "G" bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(
      cx, cy - r * 0.18, r * 0.95, r * 0.36,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, Radius.circular(r * 0.1)),
      barPaint,
    );
  }

  void _drawArc(Canvas canvas, double cx, double cy, double r,
      double startDeg, double sweepDeg, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    const degToRad = 3.14159265 / 180;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startDeg * degToRad,
      sweepDeg * degToRad,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

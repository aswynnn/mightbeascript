import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rive/rive.dart';
import '../app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter both email and password.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await context.read<AppState>().signInWithEmail(email, password);
      } else {
        await context.read<AppState>().signUpWithEmail(email, password);
        if (mounted) _showSuccess("Account created! Please log in.");
        setState(() => _isLoginMode = true);
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception:', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleAuth() async {
    try {
      setState(() => _isLoading = true);
      await context.read<AppState>().signInWithGoogle();
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception:', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final sidebarColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 800;

          if (!isWide) {
            return Container(
              color: sidebarColor,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: _AuthForm(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isLoading: _isLoading,
                  isDark: isDark,
                  isLoginMode: _isLoginMode,
                  onEmailTap: _handleEmailAuth,
                  onGoogleTap: _handleGoogleAuth,
                  onToggleMode: () =>
                      setState(() => _isLoginMode = !_isLoginMode),
                ),
              ),
            );
          }

          return Row(
            children: [
              // LEFT SIDE (60%)
              Expanded(
                flex: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: sidebarColor,
                    border: Border(right: BorderSide(color: borderColor)),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: _AuthForm(
                          emailController: _emailController,
                          passwordController: _passwordController,
                          isLoading: _isLoading,
                          isDark: isDark,
                          isLoginMode: _isLoginMode,
                          onEmailTap: _handleEmailAuth,
                          onGoogleTap: _handleGoogleAuth,
                          onToggleMode: () =>
                              setState(() => _isLoginMode = !_isLoginMode),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // RIGHT SIDE (40%)
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.transparent,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const RiveAnimation.asset(
                        'assets/rive/login_bg.riv',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                      Positioned(
                        bottom: 32,
                        right: 32,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Text(
                                "v13.0",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool isDark;
  final bool isLoginMode;
  final VoidCallback onEmailTap;
  final VoidCallback onGoogleTap;
  final VoidCallback onToggleMode;

  const _AuthForm({
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.isDark,
    required this.isLoginMode,
    required this.onEmailTap,
    required this.onGoogleTap,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderIcon(),
        const SizedBox(height: 32),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            isLoginMode ? "Welcome Back" : "Create Account",
            key: ValueKey(isLoginMode),
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -1,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            isLoginMode
                ? "Enter your credentials or use Google."
                : "Sign up to start writing your next masterpiece.",
            key: ValueKey(isLoginMode),
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),

        const SizedBox(height: 48),

        // EMAIL INPUT
        _IOSInput(
          controller: emailController,
          hint: "Email",
          icon: LucideIcons.mail,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        // PASSWORD INPUT
        _IOSInput(
          controller: passwordController,
          hint: "Password",
          icon: LucideIcons.lock,
          isObscure: true,
          isDark: isDark,
        ),

        const SizedBox(height: 32),

        // MAIN BUTTON (Login/Sign Up)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onEmailTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    isLoginMode ? "Sign In" : "Sign Up",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 32),

        // DIVIDER
        Row(
          children: [
            Expanded(
              child: Divider(color: isDark ? Colors.white10 : Colors.grey[200]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "or",
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
            Expanded(
              child: Divider(color: isDark ? Colors.white10 : Colors.grey[200]),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // GOOGLE BUTTON
        _SocialButton(
          text: "Sign in with Google",
          icon: LucideIcons.chrome,
          onTap: onGoogleTap,
          isDark: isDark,
        ),

        const SizedBox(height: 24),

        // TOGGLE TEXT
        Center(
          child: TextButton(
            onPressed: onToggleMode,
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                children: [
                  TextSpan(
                    text: isLoginMode
                        ? "Don't have an account? "
                        : "Already have an account? ",
                  ),
                  TextSpan(
                    text: isLoginMode ? "Create one" : "Log in",
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ... (Keep _HeaderIcon, _IOSInput, _SocialButton widgets from previous version)
class _HeaderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(LucideIcons.feather, size: 36, color: Colors.blue),
    );
  }
}

class _IOSInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isObscure;
  final bool isDark;

  const _IOSInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.isObscure = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isObscure,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _SocialButton({
    required this.text,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black87),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

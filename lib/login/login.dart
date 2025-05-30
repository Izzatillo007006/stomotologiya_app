import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

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
  final _auth = FirebaseAuth.instance;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final box = Hive.box('authBox');
    final savedEmail = box.get('savedEmail', defaultValue: '');
    final rememberMe = box.get('rememberMe', defaultValue: false);

    if (rememberMe && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Firebase Authentication
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // if (userCredential.user != null) {
      //   final box = Hive.box('authBox');
      //
      //   // Save authentication state
      //   await box.put('isAuthenticated', true);
      //   await box.put('userEmail', email);
      //   await box.put('userId', userCredential.user!.uid);
      //
      //   // Save credentials if remember me is checked
      //   if (_rememberMe) {
      //     await box.put('savedEmail', email);
      //     await box.put('rememberMe', true);
      //   } else {
      //     await box.delete('savedEmail');
      //     await box.put('rememberMe', false);
      //   }
      //
      //
      // }

      if (mounted) {
        // Navigate to home screen - Firebase StreamBuilder avtomatik o'tkazadi
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      print(e.code);
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Bu email bilan foydalanuvchi topilmadi';
          break;
        case 'wrong-password':
          errorMessage = 'Noto\'g\'ri parol kiritildi';
          break;
        case 'user-disabled':
          errorMessage = 'Bu akkaunt bloklangan';
          break;
        case 'too-many-requests':
          errorMessage = 'Juda ko\'p urinish. Keyinroq qaytadan urining';
          break;
        case 'invalid-email':
          errorMessage = 'Email format noto\'g\'ri';
          break;
        case 'network-request-failed':
          errorMessage = 'Internet aloqasi yo\'q';
        case 'invalid-credential':
          errorMessage = 'Invalid credentials';
          break;
        default:
          errorMessage = 'Xatolik yuz berdi: ${e.message}';
      }

      _showErrorSnackBar(errorMessage);

      print(e);
    } catch (e) {
      _showErrorSnackBar('Kutilmagan xatolik yuz berdi');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Firebase da yangi foydalanuvchi yaratish
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Email tasdiqlash yuborish
        await userCredential.user!.sendEmailVerification();

        _showSuccessSnackBar(
            'Akkaunt yaratildi! Email orqali tasdiqlovchi xabar yuborild');

        // Avtomatik login qilish
        await _login();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Parol juda oddiy';
          break;
        case 'email-already-in-use':
          errorMessage = 'Bu email allaqachon ishlatilmoqda';
          break;
        case 'invalid-email':
          errorMessage = 'Email format noto\'g\'ri';
          break;
        case 'network-request-failed':
          errorMessage = 'Internet aloqasi yo\'q';
          break;
        default:
          errorMessage = 'Xatolik yuz berdi: ${e.message}';
      }

      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('Kutilmagan xatolik yuz berdi');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorSnackBar('Avval email kiriting');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSuccessSnackBar('Parolni tiklash uchun email yuborildi');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showErrorSnackBar('Bu email bilan foydalanuvchi topilmadi');
      } else {
        _showErrorSnackBar('Xatolik yuz berdi: ${e.message}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      final box = Hive.box('authBox');
      await box.clear(); // Barcha auth ma'lumotlarni tozalash
    } catch (e) {
      _showErrorSnackBar('Chiqishda xatolik yuz berdi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and Title
                      _buildHeader(),
                      const SizedBox(height: 48),

                      // Login Form
                      _buildLoginForm(),
                      const SizedBox(height: 32),

                      // Login Button
                      _buildLoginButton(),
                      const SizedBox(height: 16),

                      // Sign Up Button
                      _buildSignUpButton(),
                      const SizedBox(height: 24),

                      // Forgot Password
                      _buildForgotPassword(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade400,
                Colors.blue.shade600,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Stomatologiya App',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tizimga kirish yoki ro\'yxatdan o\'tish',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Colors.blue.shade400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                labelStyle: TextStyle(color: Colors.grey.shade600),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email kiriting';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'To\'g\'ri email kiriting';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Parol',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.blue.shade400,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                labelStyle: TextStyle(color: Colors.grey.shade600),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Parol kiriting';
                }
                if (value.length < 6) {
                  return 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Remember Me Checkbox
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: Colors.blue.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  'Meni eslab qol',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade400,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Kirish',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signUp,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue.shade400,
          side: BorderSide(color: Colors.blue.shade400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Ro\'yxatdan o\'tish',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: _resetPassword,
      child: Text(
        'Parolni unutdingizmi?',
        style: TextStyle(
          color: Colors.blue.shade400,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildGoogleSignIn() {
    return const SizedBox.shrink(); // Google Sign In ni olib tashlash
  }
}

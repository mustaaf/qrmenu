import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberPassword = false; // Şifre hatırlama durumu için yeni değişken

  @override
  void initState() {
    super.initState();
    // Uygulama başlatıldığında kaydedilmiş şifre varsa yükle
    _loadSavedCredentials();
  }

  // Kaydedilmiş kullanıcı bilgilerini yükle
  Future<void> _loadSavedCredentials() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = await authProvider.getSavedEmail();
    final password = await authProvider.getSavedPassword();

    if (email != null && password != null) {
      setState(() {
        _emailController.text = email;
        _passwordController.text = password;
        _rememberPassword = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Şifre hatırlama ayarını kaydet
    if (_rememberPassword) {
      await authProvider.saveCredentials(email, password);
    } else {
      await authProvider.clearSavedCredentials();
    }

    final success = await authProvider.login(email, password);

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'QR Menu Admin',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Emailinizi giriniz';
                            }
                            if (!value.contains('@')) {
                              return 'lütfen geçerli bir email giriniz';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Şifre',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen şifrenizi giriniz';
                            }
                            if (value.length < 6) {
                              return 'şifre en az 6 karakter olmalıdır';
                            }
                            return null;
                          },
                        ),

                        // "Beni hatırla" checkbox'ı
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberPassword,
                              onChanged: (value) {
                                setState(() {
                                  _rememberPassword = value ?? false;
                                });
                              },
                            ),
                            const Text('Beni Hatırla'),
                          ],
                        ),

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child:
                                authProvider.isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text(
                                      'Giriş yap',
                                      style: TextStyle(fontSize: 16),
                                    ),
                          ),
                        ),
                        if (authProvider.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              authProvider.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
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
}

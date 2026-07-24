import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/neon_loading.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _urlController = TextEditingController(
    text: "http://192.168.2.147:8443",
  );
  final _tokenController = TextEditingController(
    text: "8c2a4a73ce9ac8b57ee448c2d623cf00",
  );
  bool _busy = false;

  Future<void> _login() async {
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    if (url.isEmpty || token.isEmpty) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthProvider>().login(url, token);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.four),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ThemedText.title('tiredAgent'),
              const SizedBox(height: AppSpacing.two),
              ThemedText.small('Connect to your manager server'),
              const SizedBox(height: AppSpacing.six),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Manager URL',
                  hintText: 'http://192.168.1.10:3099',
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                enabled: !_busy,
              ),
              const SizedBox(height: AppSpacing.three),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(labelText: 'Access Token'),
                obscureText: true,
                autocorrect: false,
                enabled: !_busy,
              ),
              const SizedBox(height: AppSpacing.six),
              ElevatedButton(
                onPressed:
                    (_busy ||
                        _urlController.text.trim().isEmpty ||
                        _tokenController.text.trim().isEmpty)
                    ? null
                    : _login,
                child: _busy
                    ? const NeonLoading(size: 20)
                    : Text('Connect'),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: AppSpacing.three),
                ThemedText.small(auth.error!, color: AppColors.danger),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

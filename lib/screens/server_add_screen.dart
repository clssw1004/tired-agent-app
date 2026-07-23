import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tired_agent_app/providers/server_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class ServerAddScreen extends StatefulWidget {
  const ServerAddScreen({super.key});

  @override
  State<ServerAddScreen> createState() => _ServerAddScreenState();
}

class _ServerAddScreenState extends State<ServerAddScreen> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    if (name.isEmpty || url.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields required'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<ServerProvider>().addServer(name, url, token);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: ThemedText.title('Add Server')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.four),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'my-agent'),
              enabled: !_busy,
            ),
            const SizedBox(height: AppSpacing.three),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'Base URL', hintText: 'http://agent.local:8444'),
              keyboardType: TextInputType.url,
              autocorrect: false,
              enabled: !_busy,
            ),
            const SizedBox(height: AppSpacing.three),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(labelText: 'Access Token'),
              obscureText: true,
              enabled: !_busy,
            ),
            const SizedBox(height: AppSpacing.six),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : ThemedText.body('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

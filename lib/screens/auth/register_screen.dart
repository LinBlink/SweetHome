import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/auth_models.dart';
import '../../services/auth_service.dart';
import '../../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _familyNameCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _familyNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.register(RegisterRequest(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        familyName: _familyNameCtrl.text.trim(),
      ));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('注册'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1 header
              _buildSectionHeader('01', '个人信息', '填写您的基本信息', AppColors.primary),
              const SizedBox(height: 16),
              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration('真实姓名', Icons.person_outline),
                validator: (v) => (v == null || v.trim().isEmpty) ? '请输入真实姓名' : null,
              ),
              const SizedBox(height: 14),
              // Phone
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('手机号', Icons.phone_outlined),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '请输入手机号';
                  if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(v.trim())) return '手机号格式不正确';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Password
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: _inputDecoration('密码（至少6位）', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    color: AppColors.textSecondary,
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return '请输入密码';
                  if (v.length < 6) return '密码至少6位';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Confirm Password
              TextFormField(
                controller: _confirmPasswordCtrl,
                obscureText: _obscureConfirm,
                decoration: _inputDecoration('确认密码', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    color: AppColors.textSecondary,
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return '请再次输入密码';
                  if (v != _passwordCtrl.text) return '两次密码不一致';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              // Divider
              Row(children: [
                Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.2))),
                const SizedBox(width: 12),
                Text('接下来', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(width: 12),
                Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.2))),
              ]),
              const SizedBox(height: 28),
              // Section 2 header
              _buildSectionHeader('02', '创建家庭', '为您的家庭取一个名字', AppColors.accent),
              const SizedBox(height: 16),
              // Family name
              TextFormField(
                controller: _familyNameCtrl,
                decoration: _inputDecoration('家庭名称', Icons.home_outlined).copyWith(
                  hintText: '例如：王家、李氏一族',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? '请为您的家庭取个名字' : null,
              ),
              const SizedBox(height: 8),
              Text(
                '您将成为家庭管理员，可邀请其他家庭成员加入',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              // Register button
              FilledButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('创建家庭并注册', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('已有账号？', style: TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('返回登录', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String number, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDD8D0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDD8D0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
    );
  }
}

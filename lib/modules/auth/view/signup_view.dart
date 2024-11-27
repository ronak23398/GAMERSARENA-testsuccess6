import 'package:flutter/material.dart';
import 'package:gamers_gram/core/utils/loading_state.dart';
import 'package:gamers_gram/core/widgets/custom_text_field.dart';
import 'package:gamers_gram/core/widgets/custom_widget.dart';
import 'package:gamers_gram/modules/auth/controllers/auth_controller.dart';
import 'package:gamers_gram/modules/auth/view/auth_background.dart';
import 'package:get/get.dart';

class SignUpView extends GetView<AuthController> {
  SignUpView({super.key});

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // New optional team name controllers
  final TextEditingController _valorantTeamController = TextEditingController();
  final TextEditingController _cs2TeamController = TextEditingController();
  final TextEditingController _bgmiTeamController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                const SizedBox(height: 48),
                CustomTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password',
                  controller: _passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                // Optional Team Name Sections
                const SizedBox(height: 16),
                Text(
                  'Optional Team Names',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  label: 'Valorant Team Name (Optional)',
                  controller: _valorantTeamController,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'CS2 Team Name (Optional)',
                  controller: _cs2TeamController,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'BGMI Team Name (Optional)',
                  controller: _bgmiTeamController,
                  keyboardType: TextInputType.text,
                ),

                const SizedBox(height: 24),
                Obx(() => CustomButton(
                      text: 'Sign Up',
                      isLoading:
                          controller.loadingState.value == LoadingState.loading,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          controller.signUp(
                            _emailController.text,
                            _passwordController.text,
                            _nameController.text,
                            // Pass optional team names
                            valorantTeam: _valorantTeamController.text.isEmpty
                                ? null
                                : _valorantTeamController.text,
                            cs2Team: _cs2TeamController.text.isEmpty
                                ? null
                                : _cs2TeamController.text,
                            bgmiTeam: _bgmiTeamController.text.isEmpty
                                ? null
                                : _bgmiTeamController.text,
                          );
                        }
                      },
                    )),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Obx(() {
                  if (controller.errorMessage.isNotEmpty) {
                    return Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        controller.errorMessage.value,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

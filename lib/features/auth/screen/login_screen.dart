import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:talkest/app/theme/text_styles.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/shared/widgets/app_scaffold.dart';
import 'package:talkest/shared/widgets/custom_message_box.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.signInWithGoogle();
      // GoRouter will handle redirect automatically via auth state changes
    } catch (e) {
      // Show error when popup closed or cancelled
      if (mounted) {
        debugPrint("SIGN-IN ERROR: $e");
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sign-in was cancelled. Please try again.';
        });
      }
    }
  }

  // Future<void> _openUrl(String url) async {
  //   final uri = Uri.parse(url);
  //   if (await canLaunchUrl(uri)) {
  //     await launchUrl(uri, mode: LaunchMode.externalApplication);
  //   } else {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Could not open link')),
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showAppBarTitle: false,
      showProfileIcon: false,
      body: (context, constraints) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),

                  // App Name
                  Text(
                    'Talkest.', // Nama app Anda
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),

                  const SizedBox(height: 8),

                  // Welcome Message
                  Container(
                    constraints: BoxConstraints(maxWidth: 340),
                    child: Text(
                      'Sign in with your Google account to get started and enjoy all features.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMessage != null) ...[
                    ErrorMessageBox(
                      message: _errorMessage!,
                      maxWidth: 400,
                      onDismiss: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Google Sign In Button
                  Container(
                    constraints: BoxConstraints(minWidth: 400),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            )
                          : SvgPicture.asset(
                              'assets/icons/google_icon.svg',
                              height: 20,
                              width: 20,
                            ),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          _isLoading ? 'Signing in...' : 'Continue with Google',
                          style: AppTextStyles.titleSmall,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: _isLoading
                                ? Theme.of(context).colorScheme.outline
                                : Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Legal Text with Links
                  Container(
                    constraints: BoxConstraints(maxWidth: 300),
                    child: RichText(
                      text: TextSpan(
                        // style: TextStyle(
                        //   fontSize: 12,
                        //   color: Theme.of(context).colorScheme.onSurface,
                        //   height: 1.5,
                        // ),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        children: [
                          const TextSpan(
                            text: 'By continuing, you agree to our ',
                          ),
                          TextSpan(
                            text: 'Terms of Service',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            recognizer: TapGestureRecognizer()
                              // ..onTap = () => _openUrl('https://yourapp.com/terms'),
                              ..onTap = () {},
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            recognizer: TapGestureRecognizer()
                              // ..onTap = () => _openUrl('https://yourapp.com/privacy'),
                              ..onTap = () {},
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

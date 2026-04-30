import 'package:flutter/material.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/l10n/app_localizations.dart';

class TermsPrivacyPage extends StatefulWidget {
  const TermsPrivacyPage({super.key});

  @override
  State<TermsPrivacyPage> createState() => _TermsPrivacyPageState();
}

class _TermsPrivacyPageState extends State<TermsPrivacyPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkAuthStatus(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    const Color hassalaGreen = Color(0xFF37C4BE);
    const Color titleColor = Color(0xFF2C3E50);
    const Color bodyColor = Color(0xFF607D8B);

    checkAuthStatus(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: AlignmentDirectional.topCenter,
            end: AlignmentDirectional.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: titleColor,
                        size: 26,
                      
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.termsAndPrivacy,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 0),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.policyOverview,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: hassalaGreen,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildBulletPoint(
                          l10n.policyPoint1,
                          hassalaGreen,
                          bodyColor,
                        ),
                        _buildBulletPoint(
                          l10n.policyPoint2,
                          hassalaGreen,
                          bodyColor,
                        ),
                        _buildBulletPoint(
                          l10n.policyPoint3,
                          hassalaGreen,
                          bodyColor,
                        ),

                        const SizedBox(height: 24),
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 24),

                        Text(
                          l10n.termsOfUse,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.termsOfUseFullText,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: bodyColor,
                          ),
                          textAlign: TextAlign.justify,
                        ),

                        const SizedBox(height: 24),
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 24),

                        Text(
                          l10n.privacyPolicyTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.privacyPolicyFullText,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: bodyColor,
                          ),
                          textAlign: TextAlign.justify,
                        ),

                        const SizedBox(height: 24),
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 24),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: hassalaGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                l10n.questionsOrConcerns,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.supportEmail,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: hassalaGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
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

  Widget _buildBulletPoint(String text, Color dotColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 7, end: 10),
            child: Icon(Icons.circle, size: 8, color: dotColor),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class TermsPrivacyPage extends StatelessWidget {
  const TermsPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Terms & privacy policy',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              const Text(
                'Terms & privacy policy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 16),

              // Main Points
              _buildBulletPoint('Using Hessala means you agree to our terms and policies'),
              _buildBulletPoint('You control your data and permissions'),
              _buildBulletPoint('Your data is encrypted and never shared without consent'),

              const SizedBox(height: 24),
              const Divider(height: 1, color: Colors.grey),
              const SizedBox(height: 24),

              // Terms of Use Section
              const Text(
                'Terms of Use',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You agree to use Hessala responsibly and for family financial education purposes. '
                'All accounts created under a parent are subject to parental supervision. '
                'Transactions are eliminated or processed via licensed PSPs. '
                'The app follows SAMA and Saudi data protection standards. '
                'Misuse of the platform may result in account suspension.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.justify,
              ),

              const SizedBox(height: 24),
              const Divider(height: 1, color: Colors.grey),
              const SizedBox(height: 24),

              // Privacy Policy Section
              const Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hessala does not share your personal or financial data with third parties without consent. '
                'All sensitive data (PINs, passwords, tokens) are encrypted at rest and in transit. '
                'You can request data deletion or unlink your bank anytime. '
                'Only aggregated, anonymized data may be used for analytics.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.justify,
              ),

              const SizedBox(height: 24),
              const Divider(height: 1, color: Colors.grey),
              const SizedBox(height: 24),

              // Contact Section
              const Text(
                'Questions or concerns?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Email: support@hessala.sa',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.teal,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(
              Icons.circle,
              size: 6,
              color: Colors.teal,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class MorePage extends StatelessWidget {
  final int parentId;
  const MorePage({super.key, required this.parentId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Security Settings'),
          ),
          ListTile(
            leading: const Icon(Icons.family_restroom_outlined),
            title: const Text('Manage Kids'),
            onTap: () {
              //print("Manage Kids tapped!");
              Navigator.pushNamed(
                context,
                '/manageKids',
                arguments: {'parentId': parentId},
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Terms & Privacy Policy'),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/mobile',
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

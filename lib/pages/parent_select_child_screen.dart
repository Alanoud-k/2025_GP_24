import 'package:flutter/material.dart';
import 'parent_transfer_screen.dart';

class ParentSelectChildScreen extends StatelessWidget {
  final int parentId;
  const ParentSelectChildScreen({super.key, required this.parentId});

  @override
  Widget build(BuildContext context) {
    // مؤقت — لاحقًا بنجيبهم من API
    final kids = [
      {"id": 1, "name": "Ahmed", "balance": 50.00},
      {"id": 2, "name": "Lama", "balance": 20.50},
      {"id": 3, "name": "Sara", "balance": 15.75},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Child"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          itemCount: kids.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final kid = kids[index];

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.teal.shade300,
                  child: const Icon(Icons.person, color: Colors.white, size: 30),
                ),
                title: Text(
                  kid["name"].toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "Balance: ${kid["balance"]} SAR",
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentTransferScreen(
                        parentId: parentId,
                        childId: kid["id"] as int,
                        childName: kid["name"].toString(),
                        childBalance: kid["balance"].toString(),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

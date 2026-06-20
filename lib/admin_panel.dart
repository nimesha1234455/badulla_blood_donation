import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  // ලේ වර්ග ලැයිස්තුව
  final List<String> bloodGroups = const ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];

  Future<void> sendGroupNotification(String bloodType, BuildContext context) async {
    try {
      final result = await FirebaseFunctions.instance.httpsCallable('sendGroupNotification').call({
        "bloodType": bloodType,
        "messageContent": "හදිසි ලේ අවශ්‍යතාවයක්! ඔබගේ ලේ වර්ගය ($bloodType) හි හිඟයක් පවතී. කරුණාකර රෝහල හා සම්බන්ධ වන්න."
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.data['success'] ? "$bloodType: ${result.data['count']} දෙනෙකුට යැවීය!" : result.data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("දෝෂයක්: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel - සමූහ පණිවිඩ")),
      body: Column(
        children: [
          // සියලුම ලේ වර්ග බොත්තම්
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 10,
              children: bloodGroups.map((type) => ElevatedButton(
                onPressed: () => sendGroupNotification(type, context),
                child: Text(type),
              )).toList(),
            ),
          ),
          const Divider(),
          // පරිත්‍යාගශීලීන්ගේ ලැයිස්තුව
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('donors').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name'] ?? 'නමක් නැත'),
                      subtitle: Text("ලේ වර්ගය: ${data['bloodGroup'] ?? 'N/A'}"),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
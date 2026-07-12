import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'donor_details_screen.dart';

// Badulla Blood Bank theme colors
const Color kPrimaryRed = Color(0xffB3221A);
const Color kBgCream = Color(0xffFBEAE4);
const Color kLightRed = Color(0xffF7D9D3);
const Color kTextBrown = Color(0xff3A2620);
const Color kSubTextBrown = Color(0xff7A5A50);

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  // ලේ වර්ග ලැයිස්තුව
  final List<String> bloodGroups = const [
    "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"
  ];

  Future<void> sendGroupNotification(String bloodType, BuildContext context) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('sendGroupNotification')
          .call({
        "bloodType": bloodType,
        "messageContent":
        "හදිසි ලේ අවශ්‍යතාවයක්! ඔබගේ ලේ වර්ගය ($bloodType) හි හිඟයක් පවතී. කරුණාකර රෝහල හා සම්බන්ධ වන්න."
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: kPrimaryRed,
            content: Text(
              result.data['success']
                  ? "$bloodType: ${result.data['count']} දෙනෙකුට යැවීය!"
                  : result.data['message'],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("දෝෂයක්: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgCream,

      appBar: AppBar(
        backgroundColor: kPrimaryRed,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Admin Panel",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      body: Column(
        children: [

          // Section label
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "සමූහ පණිවිඩ යවන්න",
                style: TextStyle(
                  color: kTextBrown,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // සියලුම ලේ වර්ග බොත්තම් (themed chips)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bloodGroups.map((type) {
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => sendGroupNotification(type, context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: kPrimaryRed,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryRed.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "පරිත්‍යාගශීලීන්",
                style: TextStyle(
                  color: kTextBrown,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // පරිත්‍යාගශීලීන්ගේ ලැයිස්තුව (themed cards)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('donors')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "දෝෂයක්: ${snapshot.error}",
                        style: const TextStyle(color: kPrimaryRed, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryRed),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "පරිත්‍යාගශීලීන් නොමැත",
                      style: TextStyle(color: kSubTextBrown, fontSize: 15),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DonorDetailsScreen(data: data),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryRed.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: kLightRed,
                              child: const Icon(
                                Icons.person,
                                color: kPrimaryRed,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'නමක් නැත',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: kTextBrown,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.bloodtype,
                                          size: 15, color: kPrimaryRed),
                                      const SizedBox(width: 4),
                                      Text(
                                        "ලේ වර්ගය: ${data['bloodGroup'] ?? 'N/A'}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: kSubTextBrown,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xffC99B90),
                            ),
                          ],
                        ),
                      ),
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
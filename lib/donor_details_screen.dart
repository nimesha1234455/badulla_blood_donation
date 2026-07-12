import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color kPrimaryRed = Color(0xffB3221A);
const Color kBgCream = Color(0xffFBEAE4);
const Color kLightRed = Color(0xffF7D9D3);
const Color kTextBrown = Color(0xff3A2620);
const Color kSubTextBrown = Color(0xff7A5A50);

class DonorDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DonorDetailsScreen({super.key, required this.data});

  void _makeCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) await launchUrl(callUri);
  }

  void _sendSMS(String phoneNumber, String bloodGroup) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{
        'body': "Hello, regarding blood donation ($bloodGroup)..."
      },
    );
    if (await canLaunchUrl(smsUri)) await launchUrl(smsUri);
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'නොදනී';
    if (date is Timestamp) {
      final d = date.toDate();
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }
    return date.toString();
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kPrimaryRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: kSubTextBrown)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kTextBrown)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = data['phone']?.toString() ?? '';

    return Scaffold(
      backgroundColor: kBgCream,
      appBar: AppBar(
        backgroundColor: kPrimaryRed,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Donor Details",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: kLightRed,
                child: const Icon(Icons.person, color: kPrimaryRed, size: 40),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                data['name'] ?? 'නමක් නැත',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kTextBrown),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
              child: Column(
                children: [
                  _infoRow(Icons.bloodtype, "ලේ වර්ගය",
                      data['bloodGroup'] ?? 'N/A'),
                  const Divider(height: 1),
                  _infoRow(Icons.cake, "වයස",
                      data['age']?.toString() ?? 'N/A'),
                  const Divider(height: 1),
                  _infoRow(Icons.phone, "දුරකථන අංකය", phone.isEmpty ? 'N/A' : phone),
                  const Divider(height: 1),
                  _infoRow(Icons.badge, "හැඳුනුම්පත් අංකය",
                      data['nic']?.toString() ?? 'N/A'),
                  const Divider(height: 1),
                  _infoRow(Icons.location_on, "නගරය",
                      data['city']?.toString() ?? 'N/A'),
                  const Divider(height: 1),
                  _infoRow(Icons.calendar_today, "අන්තිම ලේ දුන් දිනය",
                      _formatDate(data['lastDonationDate'])),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: phone.isEmpty ? null : () => _makeCall(phone),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.call, color: Colors.white),
                    label: const Text("Call",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: phone.isEmpty
                        ? null
                        : () => _sendSMS(phone, data['bloodGroup'] ?? ''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.message, color: Colors.white),
                    label: const Text("Message",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
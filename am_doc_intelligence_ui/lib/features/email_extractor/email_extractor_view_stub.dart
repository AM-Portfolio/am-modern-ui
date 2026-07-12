import 'package:flutter/material.dart';

class EmailExtractorView extends StatelessWidget {
  const EmailExtractorView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mail_lock_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Email Extractor Offline',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'The Email Extractor is not supported on native mobile platforms.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

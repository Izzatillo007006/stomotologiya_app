import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:hive/hive.dart';

import 'home.dart';

class LockScreen extends StatelessWidget {
  final Box authBox = Hive.box('authBox');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Text('Ilovani ochish'),
          onPressed: () {
            screenLock(
              context: context,
              correctString: '4444', // Siz belgilagan parol
              canCancel: false,
              onUnlocked: () {
                authBox.put('isAuthenticated', true);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomeScreen()),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

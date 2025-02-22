import 'package:flutter/material.dart';

class MonText extends StatefulWidget {
  const MonText({super.key});

  @override
  State<MonText> createState() => MonTextState();
}

class MonTextState extends State<MonText> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Hello wold",
          style: TextStyle(color: Colors.blue),
        ),
      ),
    );
  }
}

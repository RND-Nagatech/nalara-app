import 'package:flutter/material.dart';
import 'home_style.dart';

/// One continuous image behind the system inset, header and greeting.
class HomeBackdrop extends StatelessWidget {
  const HomeBackdrop({super.key});
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        HomeStyle.artwork,
        key: const ValueKey('home-artwork'),
        fit: BoxFit.cover,
        alignment: const Alignment(0, .15),
        excludeFromSemantics: true,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0x5CF7F3EC), Color(0x00F7F3EC)],
            stops: [0, .72],
          ),
        ),
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00F7F3EC), HomeStyle.cream],
            stops: [.84, 1],
          ),
        ),
      ),
    ],
  );
}

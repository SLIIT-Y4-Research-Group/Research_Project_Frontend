import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ListeningIndicator extends StatefulWidget {
  final bool useLottie;
  const ListeningIndicator({super.key, this.useLottie = true});

  @override
  State<ListeningIndicator> createState() => _ListeningIndicatorState();
}

class _ListeningIndicatorState extends State<ListeningIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 120,
        child: Lottie.asset(
          "assets/lottie/mic_listening.json",
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _ring(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          width: 6,
          color: Colors.deepPurple.withOpacity(opacity),
        ),
      ),
    );
  }
}

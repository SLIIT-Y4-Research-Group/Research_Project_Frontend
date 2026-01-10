import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool useLottie;

  const LoadingOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    this.useLottie = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.35),
      child: Center(
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (useLottie)
                  SizedBox(
                    height: 140,
                    child: Lottie.asset("assets/lottie/thinking.json"),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(),
                  ),
                const SizedBox(height: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.65),
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

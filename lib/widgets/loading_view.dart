import 'package:flutter/material.dart';

/// Состояние «грузится»: центрированный индикатор (белый экран при загрузке — грех C8).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

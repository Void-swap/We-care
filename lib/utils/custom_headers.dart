import 'package:flutter/material.dart';

class CustomHeaders extends StatelessWidget {
  String Header;
  CustomHeaders({
    super.key,
    required this.context,
    required this.Header,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          Header,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 16,
                height: (20 / 16),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(
          height: 10,
        )
      ],
    );
  }
}

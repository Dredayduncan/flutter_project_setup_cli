import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:{{project-name}}/l10n/l10n.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(context.l10n.counterAppBarTitle),
    );
  }
}
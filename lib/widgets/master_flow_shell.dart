import 'package:flutter/material.dart';
import '../nummakadai/presentation/numma_admin_flow_shell.dart';

class MasterFlowShell extends StatelessWidget {
  final String? initialMode;

  const MasterFlowShell({super.key, this.initialMode});

  @override
  Widget build(BuildContext context) {
    return const NummaAdminFlowShell();
  }
}

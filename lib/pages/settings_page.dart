import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend base URL',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.baseUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.3:8000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(
                  onPressed: controller.saveBaseUrl,
                  child: const Text('Save'),
                ),
                const SizedBox(width: 12),
                Obx(
                  () => FilledButton.tonalIcon(
                    onPressed: controller.isTestingConnection.value
                        ? null
                        : controller.testConnection,
                    icon: controller.isTestingConnection.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering),
                    label: const Text('Test Connection'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final ok = controller.connectionOk.value;
              if (ok == null) return const SizedBox.shrink();
              return Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle : Icons.error,
                    color: ok
                        ? Colors.green
                        : Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ok ? 'Connected successfully' : 'Could not reach backend',
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

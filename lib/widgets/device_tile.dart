import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DeviceTile extends StatelessWidget {
  final String apartmentId;
  final String roomId;
  final Map device;

  const DeviceTile({
    super.key,
    required this.apartmentId,
    required this.roomId,
    required this.device,
  });

  void toggleDevice() async {
    try {
      final deviceId = device['id'];
      final currentStatus = device['status'];

      if (deviceId == null || currentStatus == null || currentStatus is! bool) {
        debugPrint('❌ Invalid device data: id=$deviceId, status=$currentStatus');
        return;
      }

      final deviceRef = FirebaseDatabase.instance
          .ref('apartments/$apartmentId/rooms/$roomId/devices/$deviceId');

      await deviceRef.update({'status': !currentStatus});
    } catch (e, stack) {
      debugPrint('❌ Error toggling device: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceName = device['name'] ?? 'Unnamed Device';
    final status = device['status'];
    final bool isOn = status is bool ? status : false;

    return GestureDetector(
      onTap: toggleDevice,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Icon(
                isOn ? Icons.power : Icons.power_off,
                color: isOn ? Colors.green : Colors.grey,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  deviceName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isOn ? Colors.green : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Switch(
                  value: isOn,
                  onChanged: (_) => toggleDevice(),
                  activeColor: Colors.white,
                  activeTrackColor: Colors.green,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

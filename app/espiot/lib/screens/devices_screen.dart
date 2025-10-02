import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/device_tile.dart';
import 'sensors_graph_screen.dart';

class DevicesScreen extends StatelessWidget {
  final String apartmentId;
  final String roomId;
  const DevicesScreen({super.key, required this.apartmentId, required this.roomId});

  @override
  Widget build(BuildContext context) {
    DatabaseReference devicesRef = FirebaseDatabase.instance
        .ref('apartments/$apartmentId/rooms/$roomId/devices');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // زر عرض بيانات الحساسات
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SensorsGraphScreen(
                      apartmentId: apartmentId,
                      roomId: roomId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.show_chart),
              label: const Text("عرض بيانات الحساسات"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),

          // ✅ قائمة الأجهزة
          Expanded(
            child: StreamBuilder(
              stream: devicesRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('⚠️ حصلت مشكلة في الاتصال بقاعدة البيانات'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(
                    child: Text('لا يوجد أجهزة حالياً'),
                  );
                }

                Map data = snapshot.data!.snapshot.value as Map;
                List devices = data.entries.map((e) {
                  final dev = Map<String, dynamic>.from(e.value);
                  return {
                    'id': e.key,
                    'name': dev['name'] ?? 'بدون اسم',
                    'type': dev['type'] ?? 'switch',
                    'status': dev['status'] ?? false,
                    'value': dev['value'] ?? 0,
                    'min': dev['min'] ?? 0,
                    'max': dev['max'] ?? 100,
                    'unit': dev['unit'] ?? '',
                  };
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];

                    if (device['type'] == 'knob') {
                      // ✅ لو الجهاز نوعه knob → Slider
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(device['name'],
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  Expanded(
                                    child: Slider(
                                      value: (device['value'] as num).toDouble(),
                                      min: (device['min'] as num).toDouble(),
                                      max: (device['max'] as num).toDouble(),
                                      divisions: ((device['max'] - device['min'])).toInt(),
                                      label:
                                          "${device['value']} ${device['unit']}",
                                      onChanged: (val) {
                                        FirebaseDatabase.instance
                                            .ref(
                                                'apartments/$apartmentId/rooms/$roomId/devices/${device['id']}/value')
                                            .set(val.round());
                                      },
                                    ),
                                  ),
                                  Text("${device['value']} ${device['unit']}"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      // ✅ لو device عادي (switch)
                      return DeviceTile(
                        apartmentId: apartmentId,
                        roomId: roomId,
                        device: device,
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

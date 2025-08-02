import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/device_tile.dart';
import 'sensors_graph_screen.dart'; // ✅ تأكد إنك ضايف ملف الجراف

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
          // ✅ زر عرض بيانات الحساسات
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
                List devices = data.entries.map((e) => {
                      'id': e.key,
                      'name': e.value['name'] ?? 'بدون اسم',
                      'status': e.value['status'] ?? false,
                    }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    return DeviceTile(
                      apartmentId: apartmentId,
                      roomId: roomId,
                      device: devices[index],
                    );
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

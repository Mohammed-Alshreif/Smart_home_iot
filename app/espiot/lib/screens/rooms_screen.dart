import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/animated_card.dart';
import 'devices_screen.dart';

class RoomsScreen extends StatelessWidget {
  final String apartmentId;
  const RoomsScreen({super.key, required this.apartmentId});

  @override
  Widget build(BuildContext context) {
    DatabaseReference roomsRef = FirebaseDatabase.instance.ref('apartments/$apartmentId/rooms');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: roomsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('⚠️ حصلت مشكلة في الاتصال بقاعدة البيانات'));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('لا يوجد غرف حالياً'));
          }

          Map data = snapshot.data!.snapshot.value as Map;
          List rooms = data.entries.map((e) => {
            'id': e.key,
            'name': e.value['name'] ?? 'بدون اسم',
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return AnimatedCard(
                icon: Icons.meeting_room,
                title: room['name'],
                subtitle: 'اضغط لعرض الأجهزة',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DevicesScreen(
                        apartmentId: apartmentId,
                        roomId: room['id'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/animated_card.dart';
import 'rooms_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apartmentsRef = FirebaseDatabase.instance.ref('apartments');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Systems"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: apartmentsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('There was a problem connecting to the database ⚠️'));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('NO Systems Found '));
          }

          Map data = snapshot.data!.snapshot.value as Map;
          List apartments = data.entries.map((e) => {
            'id': e.key,
            'name': e.value['name'] ?? 'Unnamed Apartment',
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: apartments.length,
            itemBuilder: (context, index) {
              final apartment = apartments[index];
              return AnimatedCard(
                icon: Icons.apartment,
                title: apartment['name'],
                subtitle: 'click to view the system',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoomsScreen(apartmentId: apartment['id']),
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

import 'dart:html' as html; // ✅ تستخدم لحفظ الملف على الويب
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'dart:math';

class SensorsGraphScreen extends StatefulWidget {
  final String apartmentId;
  final String roomId;
  const SensorsGraphScreen({super.key, required this.apartmentId, required this.roomId});

  @override
  
  State<SensorsGraphScreen> createState() => _SensorsGraphScreenState();
}

class _SensorsGraphScreenState extends State<SensorsGraphScreen> {
  Map<String, List<FlSpot>> sensorData = {};
  List<List<dynamic>> csvData = [["Timestamp", "Sensor", "Value"]];
  List<String> sensorNames = [];
  int counter = 0;
  final List<Color> colors = [
    Colors.red, Colors.blue, Colors.green,
    Colors.orange, Colors.purple, Colors.cyan,
  ];

  void _saveCSVWeb() {
    if (csvData.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ لا توجد بيانات لحفظها")),
      );
      return;
    }

    final csv = const ListToCsvConverter().convert(csvData);
    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'sensors_${DateTime.now().toIso8601String().split("T")[0]}.csv')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ تم حفظ الملف في التحميلات")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sensorsRef = FirebaseDatabase.instance
        .ref('apartments/${widget.apartmentId}/rooms/${widget.roomId}/sensors');

    return Scaffold(
      appBar: AppBar(
        title: const Text("بيانات المستشعرات"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCSVWeb,
          )
        ],
      ),
      body: StreamBuilder(
        stream: sensorsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("⚠️ خطأ في قراءة البيانات"));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("لا توجد بيانات حالياً"));
          }

          final Map data = snapshot.data!.snapshot.value as Map;

          data.forEach((key, value) {
            try {
              String sensorName = value['name']?.toString() ?? key;
              sensorName = sensorName.toLowerCase();

              double? sensorValue = double.tryParse(value['value'].toString());
              if (sensorValue == null || sensorValue.isNaN) return;

              sensorData.putIfAbsent(sensorName, () => []);
              sensorData[sensorName]!.add(FlSpot(counter.toDouble(), sensorValue));
              csvData.add([DateTime.now().toIso8601String(), sensorName, sensorValue]);

              if (!sensorNames.contains(sensorName)) {
                sensorNames.add(sensorName);
              }
            } catch (_) {
              // تجاهل الحساسات غير الصالحة
            }
          });

          counter++;

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("الرسم البياني للبيانات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: sensorNames.mapIndexed((index, name) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 12, height: 12, color: colors[index % colors.length]),
                        const SizedBox(width: 6),
                        Text(name, style: const TextStyle(fontSize: 14)),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: LineChart(
                    LineChartData(
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, _) => Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: max(1, counter ~/ 5).toDouble(),
                            getTitlesWidget: (value, _) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: true),
                      lineBarsData: sensorData.entries.mapIndexed((index, entry) {
                        return LineChartBarData(
                          spots: entry.value,
                          isCurved: true,
                          barWidth: 2,
                          color: colors[index % colors.length],
                          dotData: FlDotData(show: false),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

extension MapIndexed<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int, E) f) {
    int i = 0;
    return map((e) => f(i++, e));
  }
}

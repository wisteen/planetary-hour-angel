import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

void main() => runApp(PlanetHourAngelApp());

class PlanetHourAngelApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: PlanetHourScreen(),
    );
  }
}

class PlanetHourScreen extends StatefulWidget {
  @override
  _PlanetHourScreenState createState() => _PlanetHourScreenState();
}

class _PlanetHourScreenState extends State<PlanetHourScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final List<String> planets = [
    'Saturn', 'Jupiter', 'Mars', 'Sun', 'Venus', 'Mercury', 'Moon'
  ];

  final Map<String, String> angels = {
    'Saturn': 'Cassiel',
    'Jupiter': 'Sachiel',
    'Mars': 'Samael',
    'Sun': 'Michael',
    'Venus': 'Anael',
    'Mercury': 'Raphael',
    'Moon': 'Gabriel',
  };

  final Map<String, String> sigils = {
    'Saturn': '🜄',
    'Jupiter': '♃',
    'Mars': '♂',
    'Sun': '☉',
    'Venus': '♀',
    'Mercury': '☿',
    'Moon': '☽',
  };

  final Map<int, String> dayRulers = {
    DateTime.sunday: 'Sun',
    DateTime.monday: 'Moon',
    DateTime.tuesday: 'Mars',
    DateTime.wednesday: 'Mercury',
    DateTime.thursday: 'Jupiter',
    DateTime.friday: 'Venus',
    DateTime.saturday: 'Saturn',
  };

  String planetaryHour = 'Calculating...';
  String rulingAngel = 'Calculating...';
  String currentPlanet = '';
  String sigil = '...';
  String formattedTime = '';

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initNotifications();
    calculatePlanetaryHour();
    // Refresh every minute to keep display updated
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) setState(() => calculatePlanetaryHour());
    });
  }

  void _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    scheduleHourlyNotification();
  }

  void scheduleHourlyNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    final now = DateTime.now();
    final location = tz.local;
    for (int i = 0; i < 24; i++) {
      final scheduledTime = now.add(Duration(hours: i));
      final targetTime = DateTime(
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        scheduledTime.hour,
        0,
        0,
      );
      if (targetTime.isAfter(now)) {
        int weekday = targetTime.weekday;
        String dayRuler = dayRulers[weekday]!;
        int startIndex = planets.indexOf(dayRuler);
        int hour = targetTime.hour;
        String planet = planets[(startIndex + hour) % 7];
        String angel = angels[planet]!;
        String symbol = sigils[planet]!;

        await flutterLocalNotificationsPlugin.zonedSchedule(
          i,
          'Planetary Hour: $planet',
          'Angel: $angel  Sigil: $symbol',
          tz.TZDateTime.from(targetTime, location),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'planetary_channel',
              'Planetary Hours',
              channelDescription: 'Hourly angel and planet notifications',
              importance: Importance.high,
              priority: Priority.high,
              sound: RawResourceAndroidNotificationSound('notification'),
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  void calculatePlanetaryHour() {
    DateTime now = DateTime.now();
    int hour = now.hour;
    int weekday = now.weekday;

    String dayRuler = dayRulers[weekday]!;
    int startIndex = planets.indexOf(dayRuler);
    String planet = planets[(startIndex + hour) % 7];
    String angel = angels[planet]!;
    String symbol = sigils[planet]!;

    setState(() {
      formattedTime = DateFormat('EEEE, hh:mm a').format(now);
      planetaryHour = planet;
      rulingAngel = angel;
      currentPlanet = dayRuler;
      sigil = symbol;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        title: const Text('Planetary Hour & Angel'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formattedTime,
                style: const TextStyle(color: Colors.white70, fontSize: 22),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.deepPurple, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      'Current Planetary Hour',
                      style: TextStyle(
                        color: Colors.amber[200],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      planetaryHour,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Ruling Angel',
                      style: TextStyle(
                        color: Colors.lightBlueAccent[200],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      rulingAngel,
                      style: const TextStyle(
                        color: Colors.lightBlueAccent,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Planetary Sigil',
                      style: TextStyle(
                        color: Colors.greenAccent[200],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      sigil,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 48,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Update Information"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[800],
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  calculatePlanetaryHour();
                  scheduleHourlyNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Information updated!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

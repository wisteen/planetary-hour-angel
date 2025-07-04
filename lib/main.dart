import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:awesome_notifications/awesome_notifications.dart'; // New import
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// --- Constants ---
const String kCalculating = 'Calculating...';
const String kErrorOccurred = 'Error';
const String kPlanetaryChannelId = 'planetary_channel_v1';
const String kPlanetaryChannelName = 'Planetary Hours';
const String kPlanetaryChannelDescription = 'Hourly angel and planet notifications';
const String kDefaultNotificationSound = 'resource://raw/notification'; // Path for awesome_notifications

// --- Data Model ---
class PlanetInfo {
  final String name;
  final String angel;
  final String sigil;

  const PlanetInfo({required this.name, required this.angel, required this.sigil});
}

// --- Data Store ---
final List<PlanetInfo> orderedPlanets = [
  const PlanetInfo(name: 'Saturn', angel: 'Cassiel', sigil: '🜄'),
  const PlanetInfo(name: 'Jupiter', angel: 'Sachiel', sigil: '♃'),
  const PlanetInfo(name: 'Mars', angel: 'Samael', sigil: '♂'),
  const PlanetInfo(name: 'Sun', angel: 'Michael', sigil: '☉'),
  const PlanetInfo(name: 'Venus', angel: 'Anael', sigil: '♀'),
  const PlanetInfo(name: 'Mercury', angel: 'Raphael', sigil: '☿'),
  const PlanetInfo(name: 'Moon', angel: 'Gabriel', sigil: '☽'),
];

final Map<String, PlanetInfo> planetDataByName = {
  for (var planet in orderedPlanets) planet.name: planet,
};

final Map<int, String> dayRulerPlanetNames = {
  DateTime.sunday: 'Sun',
  DateTime.monday: 'Moon',
  DateTime.tuesday: 'Mars',
  DateTime.wednesday: 'Mercury',
  DateTime.thursday: 'Jupiter',
  DateTime.friday: 'Venus',
  DateTime.saturday: 'Saturn',
};

// --- Service for Logic ---
class PlanetaryHourService {
  PlanetInfo getPlanetInfoForHour(DateTime dateTime) {
    int weekday = dateTime.weekday;
    int hour = dateTime.hour;

    String? dayRulerName = dayRulerPlanetNames[weekday];
    if (dayRulerName == null) {
      throw ArgumentError('Invalid weekday for day ruler lookup: $weekday');
    }

    int startIndex = orderedPlanets.indexWhere((p) => p.name == dayRulerName);
    if (startIndex == -1) {
      throw ArgumentError('Day ruler planet not found in orderedPlanets: $dayRulerName');
    }

    // Calculate the current planetary hour based on the day ruler and current hour
    // The sequence of planets repeats every 7 hours for a given day.
    // However, the rule is that the *first* hour of the day is ruled by the day's ruler,
    // and then the sequence follows the order (Saturn, Jupiter, Mars, Sun, Venus, Mercury, Moon).
    // So, for the 0th hour (12 AM to 1 AM), it's the day ruler.
    // For the 1st hour (1 AM to 2 AM), it's the next planet in the sequence after the day ruler, and so on.
    // The modulus 7 is applied to the hour, not the sum with startIndex,
    // because the sequence is 7 planets repeating.
    // The 'hour' variable is 0-23, so we need to adjust it to fit the 7-planet cycle.
    // The actual planetary hour calculation is a bit more complex, often involving
    // the concept of "natural day" (sunrise to sunset) and "natural night" (sunset to sunrise)
    // divided into 12 equal hours each. For simplicity, this code uses fixed clock hours.
    // If 'hour' is 0, it's the day ruler. If 'hour' is 1, it's the next.
    // The sequence is: Day Ruler, then the next 6 planets, then repeat.
    // The formula for the planet index for a given hour (0-23) is:
    // (startIndex + (hour % 7)) % orderedPlanets.length.
    // However, the traditional planetary hours cycle through all 7 planets every 7 hours,
    // so it's (startIndex + hour) % 7, then map that back to the orderedPlanets list.
    // Let's stick to the original logic's intent, which seems to be:
    // The planet for the current hour is `startIndex + current_hour_of_day`.
    // This is then modded by `orderedPlanets.length` to cycle through the planets.
    // This assumes a fixed 24-hour cycle where the planetary ruler changes every hour.
    // The `(startIndex + hour) % orderedPlanets.length` logic correctly cycles through the list.
    int currentPlanetIndex = (startIndex + hour) % orderedPlanets.length;
    return orderedPlanets[currentPlanetIndex];
  }

  PlanetInfo getDayRulerPlanet(DateTime dateTime) {
    int weekday = dateTime.weekday;
    String? dayRulerName = dayRulerPlanetNames[weekday];
    if (dayRulerName == null) {
      throw ArgumentError('Invalid weekday for day ruler lookup: $weekday');
    }
    PlanetInfo? planet = planetDataByName[dayRulerName];
    if (planet == null) {
      throw ArgumentError('Day ruler planet details not found: $dayRulerName');
    }
    return planet;
  }
}

// --- Main Application ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Initialize Awesome Notifications
  await AwesomeNotifications().initialize(
    // Set the icon for the notifications. This should be an Android drawable resource.
    // For example, if you have 'ic_launcher.png' in 'android/app/src/main/res/mipmap',
    // you would use '@mipmap/ic_launcher'.
    '@mipmap/ic_launcher',
    [
      NotificationChannel(
        channelKey: kPlanetaryChannelId,
        channelName: kPlanetaryChannelName,
        channelDescription: kPlanetaryChannelDescription,
        defaultColor: Colors.deepPurple,
        ledColor: Colors.deepPurple,
        playSound: true,
        enableVibration: true,
        importance: NotificationImportance.Default,
        // Set the sound. 'resource://raw/notification' assumes 'notification.mp3' or 'notification.wav'
        // is in 'android/app/src/main/res/raw/'.
        soundSource: kDefaultNotificationSound,
      )
    ],
    debug: true, // Set to false for production
  );

  // Request notification permissions
  // Corrected: Use isNotificationAllowed() method
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }

  runApp(const PlanetHourAngelApp());
}

class PlanetHourAngelApp extends StatelessWidget {
  const PlanetHourAngelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurple[700]!,
          secondary: Colors.amber[600]!,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple[900],
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple[800],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
      home: const PlanetHourScreen(),
    );
  }
}

// --- Screen Widget ---
class PlanetHourScreen extends StatefulWidget {
  const PlanetHourScreen({super.key});

  @override
  _PlanetHourScreenState createState() => _PlanetHourScreenState();
}

class _PlanetHourScreenState extends State<PlanetHourScreen> {
  // Removed FlutterLocalNotificationsPlugin instance
  final PlanetaryHourService _planetaryHourService = PlanetaryHourService();

  String _formattedTime = DateFormat('EEEE, hh:mm:ss a').format(DateTime.now());
  PlanetInfo? _currentHourPlanetInfo;
  PlanetInfo? _currentDayRulerPlanet;
  String _planetaryHourDisplay = kCalculating;
  String _rulingAngelDisplay = kCalculating;
  String _sigilDisplay = '...';
  String _dayRulerDisplay = kCalculating;

  Timer? _perSecondTimer;
  Timer? _hourlyUpdateTimer;

  bool _notificationsInitialized = false; // Awesome Notifications handles its own initialization internally
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAsyncDependencies();
  }

  Future<void> _initializeAsyncDependencies() async {
    // Awesome Notifications is initialized in main(), so we just need to ensure permissions
    // are handled and then proceed with UI updates and scheduling.
    // Corrected: Use isNotificationAllowed() method
    _notificationsInitialized = await AwesomeNotifications().isNotificationAllowed();
    if (!_notificationsInitialized) {
      // If not allowed, request again (though it's also requested in main)
      _notificationsInitialized = await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    _updatePlanetaryData();
    _startTimers();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      await _scheduleAllHourlyNotifications();
    }
  }

  // Removed _initNotifications as Awesome Notifications is initialized in main()

  void _updatePlanetaryData() {
    final now = DateTime.now();
    try {
      final hourPlanet = _planetaryHourService.getPlanetInfoForHour(now);
      final dayRuler = _planetaryHourService.getDayRulerPlanet(now);

      if (mounted) {
        setState(() {
          _formattedTime = DateFormat('EEEE, hh:mm:ss a').format(now);
          _currentHourPlanetInfo = hourPlanet;
          _currentDayRulerPlanet = dayRuler;
          _planetaryHourDisplay = hourPlanet.name;
          _rulingAngelDisplay = hourPlanet.angel;
          _sigilDisplay = hourPlanet.sigil;
          _dayRulerDisplay = dayRuler.name;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _planetaryHourDisplay = kErrorOccurred;
          _rulingAngelDisplay = kErrorOccurred;
          _sigilDisplay = '-';
          _dayRulerDisplay = kErrorOccurred;
          // print("Error updating planetary data: $e");
        });
      }
    }
  }

  void _startTimers() {
    _perSecondTimer?.cancel();
    _perSecondTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        setState(() {
          _formattedTime = DateFormat('EEEE, hh:mm:ss a').format(DateTime.now());
        });
      }
    });
    _scheduleNextHourlyDataUpdate();
  }

  void _scheduleNextHourlyDataUpdate() {
    _hourlyUpdateTimer?.cancel();
    final now = DateTime.now();
    // Schedule for 1 second past the next exact hour to ensure it triggers after the hour changes
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1, 0, 1);
    final durationUntilNextHour = nextHour.difference(now);

    _hourlyUpdateTimer = Timer(durationUntilNextHour, () {
      if (mounted) {
        _updatePlanetaryData();
        _scheduleNextHourlyDataUpdate();
        if (_notificationsInitialized) {
          _scheduleAllHourlyNotifications();
        }
      }
    });
  }

  Future<void> _scheduleAllHourlyNotifications() async {
    if (!_notificationsInitialized) {
      // If permissions are not granted, try requesting again
      _notificationsInitialized = await AwesomeNotifications().requestPermissionToSendNotifications();
      if (!_notificationsInitialized) return; // If still not granted, exit
    }

    // Cancel all existing notifications before rescheduling
    await AwesomeNotifications().cancelAll();

    final tz.TZDateTime nowTz = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < 24; i++) {
      // Calculate the scheduled time for each hour of the day
      final DateTime baseScheduledHourDateTime = DateTime(nowTz.year, nowTz.month, nowTz.day, i);
      tz.TZDateTime scheduledTzTime = tz.TZDateTime.from(baseScheduledHourDateTime, tz.local);

      // If the scheduled time is in the past, schedule it for the same hour tomorrow
      if (scheduledTzTime.isBefore(nowTz)) {
        scheduledTzTime = scheduledTzTime.add(const Duration(days: 1));
      }

      try {
        final PlanetInfo info = _planetaryHourService.getPlanetInfoForHour(scheduledTzTime);

        // Corrected: Use createNotification instead of createScheduledNotification
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: i, // Unique ID for each hourly notification
            channelKey: kPlanetaryChannelId,
            title: 'Planetary Hour: ${info.name}',
            body: 'Angel: ${info.angel}  Sigil: ${info.sigil}',
            notificationLayout: NotificationLayout.Default,
            category: NotificationCategory.Reminder,
            wakeUpScreen: true, // Optional: wakes up the screen on notification
            fullScreenIntent: false, // Optional: shows as full screen intent (requires permission)
            autoDismissible: true, // Notification dismisses when tapped
            payload: {'hour': i.toString(), 'planet': info.name}, // Custom data
          ),
          schedule: NotificationCalendar(
            year: scheduledTzTime.year,
            month: scheduledTzTime.month,
            day: scheduledTzTime.day,
            hour: scheduledTzTime.hour,
            minute: scheduledTzTime.minute,
            second: scheduledTzTime.second,
            millisecond: scheduledTzTime.millisecond,
            repeats: true, // Repeat daily
            allowWhileIdle: true, // Allow notifications even if device is in idle mode
            timeZone: tz.local.name,
          ),
        );
      } catch (e) {
        // print("Error scheduling notification for $scheduledTzTime: $e");
      }
    }
  }

  void _handleRefresh() {
    if (mounted) {
      setState(() { _isLoading = true; });
      _updatePlanetaryData();
      if (_notificationsInitialized) {
        _scheduleAllHourlyNotifications();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Information updated and notifications rescheduled!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _perSecondTimer?.cancel();
    _hourlyUpdateTimer?.cancel();
    super.dispose();
  }

  Widget _buildInfoCard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInfoRow('Ruler of the Day:', _dayRulerDisplay, Colors.tealAccent[100]!, Colors.tealAccent, fontSize: 22),
          const SizedBox(height: 25),
          _buildInfoRow('Current Planetary Hour:', _planetaryHourDisplay, Colors.amber[200]!, Colors.amber),
          _buildInfoRow('Ruling Angel:', _rulingAngelDisplay, Colors.lightBlueAccent[100]!, Colors.lightBlueAccent),
          _buildInfoRow('Planetary Sigil:', _sigilDisplay, Colors.greenAccent[100]!, Colors.greenAccent, valueFontSize: 48),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, Color titleColor, Color valueColor, {double fontSize = 26, double valueFontSize = 0}) {
    final finalValueFontSize = valueFontSize > 0 ? valueFontSize : fontSize;
    return Column(
      children: [
        Text(title, textAlign: TextAlign.center, style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(value, textAlign: TextAlign.center, style: TextStyle(color: valueColor, fontSize: finalValueFontSize, fontWeight: FontWeight.bold, shadows: [
          Shadow(blurRadius: 10.0, color: Colors.black.withOpacity(0.5), offset: const Offset(2.0, 2.0)),
        ])),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planetary Hour & Angel'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_formattedTime, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 22, fontWeight: FontWeight.w300)),
              const SizedBox(height: 30),
              _buildInfoCard(),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh & Reschedule"),
                  onPressed: _handleRefresh,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

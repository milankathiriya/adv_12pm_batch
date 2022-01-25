import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  print("Handling a background message: ${message.data}");
  print("Title: ${message.notification!.title}");
  print("Body: ${message.notification!.body}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();

    fetchToken();

    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      if (msg.notification != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("${msg.data['my_body']}"),
            content: Text("${msg.data['my_content']}"),
            // title: Text("${msg.notification!.title}"),
            // content: Text("${msg.notification!.body}"),
          ),
        );
      }
    });

    var initializationSettingsAndroid =
        const AndroidInitializationSettings('mipmap/ic_launcher');
    var initializationSettingsIOs = const IOSInitializationSettings();
    var initSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOs);

    tz.initializeTimeZones();

    flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onSelectNotification: onSelectNotification,
    );
  }

  onSelectNotification(String? payload) {
    print("Notification Clicked...\nPayload: $payload");
  }

  fetchToken() async {
    String? token = await messaging.getToken();
    print(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification App"),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Simple Local Push Notification"),
              onPressed: showSimpleNotification,
            ),
            ElevatedButton(
              child: const Text("Scheduled Local Push Notification"),
              onPressed: showScheduleNotification,
            ),
            ElevatedButton(
              child: const Text("Big Picture Local Push Notification"),
              onPressed: showBigPictureNotification,
            ),
            ElevatedButton(
              child: const Text("Media Local Push Notification"),
              onPressed: showNotificationMediaStyle,
            ),
            ElevatedButton(
              child: const Text("Firebase Push Notification"),
              style: ElevatedButton.styleFrom(
                primary: Colors.amber,
                onPrimary: Colors.black,
              ),
              onPressed: () async {
                sendFCMNotification(body: "Laptop", content: "Out of stock", topic: "sport");
              },
            ),
          ],
        ),
      ),
    );
  }

  sendFCMNotification({String body = "", String content = "", String topic = "weather"}) async {
    var url = Uri.parse('https://fcm.googleapis.com/fcm/send');
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'key=AAAArc9fdOE:APA91bFm3pWBcytlutIf_n40xgvk2bnTP5wkiQwVQalYEnaLaak0RVlWKZVS48BAhuw0w9kqllCfq39SISg2ozXSWR9eCgrHXi_lhZ6L1-AoOd0tp6rYhMRto4BXF8WZqsPd9IPRzjmt',
      },
      body: jsonEncode({
        "to":
            "eAXVAeBrRri49w576T36Hd:APA91bHi_OLk8cqJiFMBs6V-_FTnf5C1SxZSO75uilQtXLlgpsFjgiMKjDMHVpvbDKC2TELfVh8dfudFq3nY32e1Gmi8RB82MOYRf4JiSEABq1gZeOTc5uPRhtjYTU7YEI_trbh5njer",
        // "topic": topic,
        "notification": {
          "title": "hello",
          "body": "New announcement assigned",
          "content_available": true,
          "priority": "high"
        },
        "data": {
          "priority": "high",
          "sound": "app_sound.wav",
          "content_available": true,
          "my_body": body,
          "my_content": content
        }
      }),
    );

    print(response.body);
  }

  Future<void> showSimpleNotification() async {
    var android = const AndroidNotificationDetails(
      'id',
      'channel ',
      channelDescription: 'description',
      priority: Priority.high,
      importance: Importance.max,
    );

    var iOS = const IOSNotificationDetails();

    var platform = NotificationDetails(android: android, iOS: iOS);

    await flutterLocalNotificationsPlugin.show(
        0, 'Flutter devs', 'Flutter Local Notification Demo', platform,
        payload: 'Welcome to the Local Notification demo');
  }

  Future<void> showScheduleNotification() async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'channel id',
      'channel name',
      channelDescription: 'channel description',
      icon: 'mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('mipmap/ic_launcher'),
    );
    var iOSPlatformChannelSpecifics = const IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      "Notification Title",
      "This is the Notification Body!",
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 2)),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showBigPictureNotification() async {
    var bigPictureStyleInformation = const BigPictureStyleInformation(
      DrawableResourceAndroidBitmap("mipmap/ic_launcher"),
      largeIcon: DrawableResourceAndroidBitmap("mipmap/ic_launcher"),
      contentTitle: 'flutter devs',
      summaryText: 'summaryText',
    );
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'big text channel id', 'big text channel name',
        channelDescription: 'big text channel description',
        styleInformation: bigPictureStyleInformation);
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: null);
    await flutterLocalNotificationsPlugin.show(
        0, 'big text title', 'silent body', platformChannelSpecifics,
        payload: "big image notifications");
  }

  Future<void> showNotificationMediaStyle() async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'media channel id',
      'media channel name',
      channelDescription: 'media channel description',
      color: Colors.red,
      enableLights: true,
      largeIcon: DrawableResourceAndroidBitmap("mipmap/ic_launcher"),
      styleInformation: MediaStyleInformation(),
    );
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: null);
    await flutterLocalNotificationsPlugin.show(
        0, 'notification title', 'notification body', platformChannelSpecifics);
  }
}

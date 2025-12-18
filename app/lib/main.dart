import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notice_list_page.dart';

// 로컬 알림 플러그인 초기화
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 백그라운드 메시지 핸들러 (앱이 종료된 상태에서도 알림 수신)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('백그라운드 메시지 수신: ${message.messageId}');
}

// Android 알림 채널 초기화
Future<void> _initializeNotifications() async {
  // Android 초기화 설정
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  // Android 알림 채널 생성
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'lh_notice_channel', // 채널 ID
    '공모 알림', // 채널 이름
    description: '새로운 공모 정보 알림을 받습니다', // 채널 설명
    importance: Importance.high,
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

// 포그라운드 알림 표시 함수
Future<void> _showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'lh_notice_channel',
    '공모 알림',
    channelDescription: '새로운 공모 정보 알림을 받습니다',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? '공모 알림',
    message.notification?.body ?? '',
    platformChannelSpecifics,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 로컬 알림 초기화
  await _initializeNotifications();

  // FCM 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // FCM 초기화 및 토픽 구독
  final messaging = FirebaseMessaging.instance;

  // 알림 권한 요청 (Android 13 이상)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('🔍 알림 권한 상태: ${settings.authorizationStatus}');

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ 알림 권한 허용됨');

    // 'lh_notice' 토픽 구독
    try {
      await messaging.subscribeToTopic('lh_notice');
      print('✅ lh_notice 토픽 구독 완료');
    } catch (e) {
      print('❌ 토픽 구독 실패: $e');
    }

    // FCM 토큰 가져오기 (디버깅용)
    try {
      String? token = await messaging.getToken();
      print('📱 FCM 토큰: $token');
    } catch (e) {
      print('❌ FCM 토큰 가져오기 실패: $e');
    }
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('⚠️ 알림 권한 임시 허용됨');
    await messaging.subscribeToTopic('lh_notice');
    print('✅ lh_notice 토픽 구독 완료 (임시 권한)');
  } else {
    print('❌ 알림 권한 거부됨: ${settings.authorizationStatus}');
  }

  // 포그라운드 메시지 핸들러 (앱이 실행 중일 때)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('🔔 포그라운드 메시지 수신: ${message.messageId}');
    print('제목: ${message.notification?.title}');
    print('내용: ${message.notification?.body}');
    print('데이터: ${message.data}');

    // 포그라운드에서도 알림 표시
    try {
      await _showNotification(message);
      print('✅ 로컬 알림 표시 완료');
    } catch (e) {
      print('❌ 로컬 알림 표시 실패: $e');
    }
  });

  // 알림 클릭 핸들러
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('알림 클릭: ${message.messageId}');
    print('링크: ${message.data['link']}');
  });

  // 앱이 종료된 상태에서 알림을 클릭하여 앱이 열린 경우 처리
  RemoteMessage? initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    print('앱 종료 상태에서 알림 클릭으로 앱 열림');
    print('링크: ${initialMessage.data['link']}');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Design System Colors
  static const Color primaryColor = Color(0xFF268BD3);
  static const Color secondaryColor = Color(0xFFE3F2FD);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF191F28);
  static const Color textSecondary = Color(0xFF8B95A1);
  static const Color errorColor = Color(0xFFFF4D4F);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '공모 알림',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: surfaceColor,
          error: errorColor,
          onPrimary: Colors.white,
          onSecondary: textPrimary,
          onSurface: textPrimary,
          onError: Colors.white,
        ),
        textTheme: GoogleFonts.notoSansKrTextTheme(
          ThemeData.light().textTheme.copyWith(
                headlineMedium: GoogleFonts.notoSansKr(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
                titleMedium: GoogleFonts.notoSansKr(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                bodyMedium: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: textPrimary,
                ),
                bodySmall: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: textSecondary,
                ),
              ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: surfaceColor,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.notoSansKr(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.notoSansKr(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'source': 'LH',
      'title': 'LH 공모안내',
      'icon': Icons.home,
    },
    {
      'source': 'KAMS',
      'title': '예술경영지원센터',
      'icon': Icons.palette,
    },
    {
      'source': 'Seoul',
      'title': '서울 공공디자인',
      'icon': Icons.location_city,
    },
    {
      'source': 'SeoulPublicArt',
      'title': '서울 공공미술 공모',
      'icon': Icons.brush,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '공모 알림',
          style: GoogleFonts.notoSansKr(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: MyApp.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: MyApp.surfaceColor,
        foregroundColor: MyApp.textPrimary,
        automaticallyImplyLeading: false, // 왼쪽 햄버거 아이콘 제거
      ),
      endDrawer: Theme(
        data: Theme.of(context).copyWith(
          dividerTheme: const DividerThemeData(
            color: Color(0xFFEEEEEE),
            thickness: 1,
          ),
        ),
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: const Color(0xFF3783BB),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '공모 알림',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '다양한 공모 정보를 한 곳에서',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              ..._pages.asMap().entries.expand((entry) {
                final index = entry.key;
                final page = entry.value;
                final isSelected = _currentIndex == index;

                return [
                  ListTile(
                    leading: Icon(
                      page['icon'],
                      color:
                          isSelected ? MyApp.primaryColor : MyApp.textSecondary,
                    ),
                    title: Text(
                      page['title'],
                      style: GoogleFonts.notoSansKr(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color:
                            isSelected ? MyApp.primaryColor : MyApp.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _currentIndex = index;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  if (index < _pages.length - 1)
                    Divider(
                      color: const Color(0xFFEEEEEE),
                      thickness: 1,
                      height: 1,
                    ),
                ];
              }),
              Divider(
                color: const Color(0xFFEEEEEE),
                thickness: 1,
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(
                  '앱 정보',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                subtitle: Text(
                  '버전 1.0.0',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages.map((page) {
          return NoticeListPage(
            source: page['source'],
            pageTitle: page['title'],
          );
        }).toList(),
      ),
    );
  }
}

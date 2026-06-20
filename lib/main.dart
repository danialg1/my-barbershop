import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/dashboard/presentation/pages/main_screen.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/pages/barber_dashboard_page.dart';
import 'features/dashboard/presentation/pages/admin_dashboard_page.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<int> profileUpdateNotifier = ValueNotifier(0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyBarbershopApp());
}

class MyBarbershopApp extends StatefulWidget {
  const MyBarbershopApp({super.key});

  @override
  State<MyBarbershopApp> createState() => _MyBarbershopAppState();
}

class _MyBarbershopAppState extends State<MyBarbershopApp> {
  late Future<SharedPreferences> _prefsFuture;

  @override
  void initState() {
    super.initState();
    _prefsFuture = SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'My Barbershop',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFD4AF37),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFD4AF37),
              brightness: Brightness.dark,
            ),
          ),
          home: FutureBuilder<SharedPreferences>(
            future: _prefsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  ),
                );
              }

              if (snapshot.hasData) {
                final prefs = snapshot.data!;
                final userId = prefs.getString('user_id');
                if (userId != null && userId.isNotEmpty) {
                  // Ambil role dari memori, kalau kosong anggap saja customer
                  final userRole = prefs.getString('user_role') ?? 'customer';

                  // Tentukan arah berdasarkan role
                  if (userRole == 'admin') {
                    return const AdminDashboardPage();
                  } else if (userRole == 'barber') {
                    return const BarberDashboardPage();
                  } else {
                    return const MainScreen();
                  }
                }
              }

              return const LoginPage();
            },
          ),
        );
      },
    );
  }
}

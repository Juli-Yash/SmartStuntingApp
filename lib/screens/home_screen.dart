// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_stunting_app/screens/tabs/child_data_tab.dart';
import 'package:smart_stunting_app/screens/tabs/profile_tab.dart';
import 'package:smart_stunting_app/screens/tabs/dashboard_tab.dart';
import 'package:smart_stunting_app/services/auth_service.dart';
import 'package:smart_stunting_app/models/user.dart';
import 'package:smart_stunting_app/screens/login_screen.dart';
import 'package:smart_stunting_app/models/news.dart';
import 'package:smart_stunting_app/utils/api_endpoints.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  User? _currentUser;
  final AuthService _authService = AuthService();

  bool _isLoadingProfile = true;
  List<News> _allNews = [];
  bool _isLoadingNews = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _fetchData() async {
    await _fetchCurrentUser();
    await _fetchNews();
  }

  Future<void> _fetchCurrentUser() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProfile = true;
    });
    try {
      final user = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      print('Error fetching current user: $e');
      if (mounted) {
        if (e.toString().contains('Unauthorized') ||
            e.toString().contains('Invalid token')) {
          _authService.logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal memuat profil: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _fetchNews() async {
    if (!mounted) return;
    setState(() {
      _isLoadingNews = true;
    });

    // Menggunakan konstanta dari ApiEndpoints
    final url =
        '${ApiEndpoints.newsApiUrl}?q=stunting&apiKey=${ApiEndpoints.newsApiKey}&language=id';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> articlesJson = data['articles'];

        final List<News> fetchedNews = articlesJson.map((json) {
          return News.fromJson(json as Map<String, dynamic>);
        }).toList();

        if (mounted) {
          setState(() {
            _allNews = fetchedNews;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat berita: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNews = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      RefreshIndicator(
        onRefresh: _fetchData,
        child: DashboardTab(
          currentUser: _currentUser,
          allNews: _allNews,
          onItemTapped: _onItemTapped,
          isLoadingProfile: _isLoadingProfile,
          isLoadingNews: _isLoadingNews,
        ),
      ),
      const ChildDataTab(),
      ProfileTab(
        onProfileUpdated: () {
          _fetchCurrentUser();
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Stunting'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
            icon: Icon(Icons.child_care),
            label: 'Data Anak',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}

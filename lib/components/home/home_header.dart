import 'package:flutter/material.dart';
import '../../colors.dart';
import '../../pages/profile/profile_page.dart';
import '../../services/api/user.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String _fullName = 'User';
  String? _avatarUrl;
  bool _isLoading = true;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload user data when returning to this page (e.g., after profile update)
    // Only reload if we've already loaded once (to avoid double loading on first build)
    if (_hasLoadedOnce) {
      _loadUserData(forceRefresh: true);
    }
  }

  Future<void> _loadUserData({bool forceRefresh = false}) async {
    try {
      final response = await UserApi.getUser(forceRefresh: forceRefresh);
      if (response.data is Map) {
        final data = response.data['data'];
        if (data != null) {
          // Load full name
          if (data['full_name'] != null) {
            final fullName = data['full_name'].toString().trim();
            // Check if full_name is valid (not empty, not "null" string)
            if (fullName.isNotEmpty && 
                fullName != 'null' &&
                fullName.length > 1) {
              // If full_name is "string", it's a placeholder, use username instead
              if (fullName == 'string') {
                print('HomeHeader: full_name is placeholder "string", will use username');
              } else {
                // Split by space and take only the first part (first name)
                final firstName = fullName.split(' ').first;
                setState(() {
                  _fullName = firstName;
                });
                print('HomeHeader: Using full_name (first part): $firstName');
              }
            } else {
              print('HomeHeader: full_name is invalid: "$fullName", will use username');
            }
          }
          
          // Fallback to username if full_name is empty, "string", or "null"
          if (_fullName == 'User' && data['username'] != null) {
            final username = data['username'].toString();
            setState(() {
              _fullName = username;
            });
            print('HomeHeader: Using username: $username');
          }
          
          // Load avatar URL
          if (data['avatar'] != null && data['avatar'].toString().isNotEmpty) {
            final avatarUrl = data['avatar'].toString();
            print('HomeHeader: Avatar URL from API: $avatarUrl');
            // Check if avatar URL is not "null" string
            if (avatarUrl != 'null' && avatarUrl.isNotEmpty) {
              setState(() {
                _avatarUrl = avatarUrl;
              });
              print('HomeHeader: Avatar URL set: $_avatarUrl');
            } else {
              print('HomeHeader: Avatar URL is null or empty string');
            }
          } else {
            print('HomeHeader: No avatar in response data');
          }
        }
      }
      setState(() {
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Greeting and name
            SizedBox(
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola,',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 60,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                          ),
                        )
                      : Text(
                          _fullName,
                          style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Profile picture - clickable to navigate to ProfilePage
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque, // Make entire area tappable
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.getGrey50Color(brightness),
                ),
                child: ClipOval(
                  child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? Image.network(
                          _avatarUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                            print('HomeHeader: Error loading avatar: $error');
                            print('HomeHeader: Avatar URL was: $_avatarUrl');
                            return Icon(
                              Icons.person,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 24,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              print('HomeHeader: Avatar loaded successfully');
                              return child;
                            }
                      return Icon(
                        Icons.person,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 24,
                      );
                    },
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


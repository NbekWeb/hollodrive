import 'package:flutter/material.dart';
import '../../colors.dart';
import '../../services/api/user.dart';

class UserInfoHeader extends StatefulWidget {
  const UserInfoHeader({super.key});

  @override
  State<UserInfoHeader> createState() => _UserInfoHeaderState();
}

class _UserInfoHeaderState extends State<UserInfoHeader> {
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
          // Load full name and take only first part (first name)
          if (data['full_name'] != null) {
            final fullName = data['full_name'].toString().trim();
            // Check if full_name is valid (not empty, not "null" string)
            if (fullName.isNotEmpty && 
                fullName != 'null' &&
                fullName.length > 1) {
              // If full_name is "string", it's a placeholder, use username instead
              if (fullName == 'string') {
                print('UserInfoHeader: full_name is placeholder "string", will use username');
              } else {
                // Split by space and take only the first part (first name)
                final firstName = fullName.split(' ').first;
                setState(() {
                  _fullName = firstName;
                });
                print('UserInfoHeader: Using full_name (first part): $firstName');
              }
            } else {
              print('UserInfoHeader: full_name is invalid: "$fullName", will use username');
            }
          }
          
          // Fallback to username if full_name is empty, "string", or "null"
          if (_fullName == 'User' && data['username'] != null) {
            final username = data['username'].toString();
            setState(() {
              _fullName = username;
            });
            print('UserInfoHeader: Using username: $username');
          }
          
          // Load avatar URL
          if (data['avatar'] != null && data['avatar'].toString().isNotEmpty) {
            final avatarUrl = data['avatar'].toString();
            print('UserInfoHeader: Avatar URL from API: $avatarUrl');
            // Check if avatar URL is not "null" string
            if (avatarUrl != 'null' && avatarUrl.isNotEmpty) {
              setState(() {
                _avatarUrl = avatarUrl;
              });
              print('UserInfoHeader: Avatar URL set: $_avatarUrl');
            } else {
              print('UserInfoHeader: Avatar URL is null or empty string');
            }
          } else {
            print('UserInfoHeader: No avatar in response data');
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Greeting and name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Hola,',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.star,
                          color: Colors.yellow,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '4.8',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 100,
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
              // Avatar (without dropdown)
                  Container(
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
                                print('UserInfoHeader: Error loading avatar: $error');
                                print('UserInfoHeader: Avatar URL was: $_avatarUrl');
                                return Icon(
                                  Icons.person,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 24,
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  print('UserInfoHeader: Avatar loaded successfully');
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
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(
            color: Colors.white.withValues(alpha: 0.1),
            height: 1,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}


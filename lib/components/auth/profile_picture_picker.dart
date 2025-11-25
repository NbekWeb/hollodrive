import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../colors.dart';

class ProfilePicturePicker extends StatefulWidget {
  final Function(File?)? onImageSelected;
  final String? initialImagePath;
  final String? initialImageUrl; // URL for network image

  const ProfilePicturePicker({
    super.key,
    this.onImageSelected,
    this.initialImagePath,
    this.initialImageUrl,
  });

  @override
  State<ProfilePicturePicker> createState() => _ProfilePicturePickerState();
}

class _ProfilePicturePickerState extends State<ProfilePicturePicker> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      _selectedImage = File(widget.initialImagePath!);
    }
  }

  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.photos.status;
      if (!status.isGranted) {
        await Permission.photos.request();
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.status;
      if (!status.isGranted) {
        await Permission.photos.request();
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    await _requestPermission();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        widget.onImageSelected?.call(_selectedImage);
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    await _requestPermission();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        widget.onImageSelected?.call(_selectedImage);
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurfaceColor(Theme.of(context).brightness),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteImage() {
    setState(() {
      _selectedImage = null;
    });
    widget.onImageSelected?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final greyColor = AppColors.getGreyColor(brightness);

    return Center(
      child: Stack(
        children: [
          // Profile picture circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: greyColor,
            ),
            child: _selectedImage != null
                ? ClipOval(
                    child: Image.file(
                      _selectedImage!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                : widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          widget.initialImageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: SvgPicture.asset(
                                'assets/svg/user.svg',
                                width: 40,
                                height: 40,
                                colorFilter: ColorFilter.mode(
                                  Colors.white.withValues(alpha: 0.5),
                                  BlendMode.srcIn,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            );
                          },
                    ),
                  )
                : Center(
                    child: SvgPicture.asset(
                      'assets/svg/user.svg',
                      width: 40,
                      height: 40,
                      colorFilter: ColorFilter.mode(
                        Colors.white.withValues(alpha: 0.5),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
          ),
          // Camera icon button (bottom right) - only show if no image is selected and no initial URL
          if (_selectedImage == null && (widget.initialImageUrl == null || widget.initialImageUrl!.isEmpty))
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF555555),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: Color(0xFF262626),
                  ),
                ),
              ),
            ),
          // Delete/Change icon button (bottom right) - show if image is selected OR if initial URL exists
          if (_selectedImage != null || (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty))
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _selectedImage != null ? _deleteImage : _showImageSourceDialog,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.getErrorColor(brightness),
                  ),
                  child: Icon(
                    _selectedImage != null ? Icons.delete : Icons.camera_alt,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


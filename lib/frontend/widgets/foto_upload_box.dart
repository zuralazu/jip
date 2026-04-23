import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/colors.dart';
import '../utils/image_utils.dart';

class FotoUploadBox extends StatelessWidget {
  final String label;
  final Function(File)? onImagePicked;
  final File? imageFile;
  final VoidCallback? onRemove;

  const FotoUploadBox({
    super.key,
    required this.label,
    this.onImagePicked,
    this.imageFile,
    this.onRemove,
  });

  Future<void> _showPicker(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil dari Kamera'),
              onTap: () async {
                Navigator.pop(context);

                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );

                if (image != null && onImagePicked != null) {
                  final compressed = await ImageUtils.compressImage(
                    File(image.path),
                    quality: 70,
                    maxWidth: 1280,
                    maxHeight: 1280,
                  );
                  onImagePicked!(compressed);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(context);

                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );

                if (image != null && onImagePicked != null) {
                  onImagePicked!(File(image.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
              image: imageFile != null
                  ? DecorationImage(
                image: FileImage(imageFile!),
                fit: BoxFit.cover,
              )
                  : null,
            ),

            // 🔥 CONTENT KALAU BELUM ADA GAMBAR
            child: imageFile == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
                : null,
          ),

          // 🔥 BUTTON HAPUS (kalau ada gambar)
          if (imageFile != null && onRemove != null)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
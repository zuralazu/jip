import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
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
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        onCamera: () async {
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
            // ── Auto-save ke galeri ──────────────────────────────────────
            try {
              await Gal.putImage(compressed.path, album: 'JIM');
            } catch (e) {
              debugPrint('Gagal simpan ke galeri: $e');
            }
            onImagePicked!(compressed);
          }
        },
        onGallery: () async {
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
    );
  }

  void _openPreview(BuildContext context) {
    if (imageFile == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullScreenPreview(
          imageFile: imageFile!,
          label: label,
          heroTag: 'foto_$label${imageFile!.path}',
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = 'foto_$label${imageFile?.path ?? "empty"}';

    return SizedBox(
      height: 110,
      child: Stack(
        children: [
          // ── Main box ────────────────────────────────────────────────────
          GestureDetector(
            onTap: imageFile != null
                ? () => _openPreview(context)
                : () => _showPicker(context),
            child: Hero(
              tag: heroTag,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
                  image: imageFile != null
                      ? DecorationImage(
                    image: FileImage(imageFile!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: imageFile == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ketuk untuk upload',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                )
                    : null,
              ),
            ),
          ),

          // ── Overlay saat ada foto: tombol ganti + hapus ──────────────
          if (imageFile != null) ...[
            // Gradient bawah supaya tombol kebaca
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
              ),
            ),

            // Tombol ganti (kiri bawah)
            Positioned(
              bottom: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => _showPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Ganti',
                        style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tombol hapus (kanan atas)
            if (onRemove != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ),

            // Icon preview (tengah, hint visual)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: const Icon(Icons.fullscreen_rounded, size: 14, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bottom sheet picker yang keren ───────────────────────────────────────────
class _PickerSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _PickerSheet({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16, top: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const Text(
                'Upload Foto',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _SheetOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Kamera',
                      sublabel: 'Foto langsung',
                      color: AppColors.primary,
                      onTap: onCamera,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Galeri',
                      sublabel: 'Pilih dari galeri',
                      color: const Color(0xFF8E24AA),
                      onTap: onGallery,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full screen preview dengan pinch-to-zoom & swipe-to-dismiss ──────────────
class _FullScreenPreview extends StatefulWidget {
  final File imageFile;
  final String label;
  final String heroTag;

  const _FullScreenPreview({
    required this.imageFile,
    required this.label,
    required this.heroTag,
  });

  @override
  State<_FullScreenPreview> createState() => _FullScreenPreviewState();
}

class _FullScreenPreviewState extends State<_FullScreenPreview> {
  final TransformationController _transformController = TransformationController();
  double _dragOffset = 0;
  double _bgOpacity = 1.0;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    // Hide status bar saat preview
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    return WillPopScope(
      onWillPop: () async {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          // Swipe down to dismiss
          onVerticalDragUpdate: (details) {
            setState(() {
              _dragOffset += details.delta.dy;
              _bgOpacity = (1.0 - (_dragOffset.abs() / 300)).clamp(0.3, 1.0);
            });
          },
          onVerticalDragEnd: (details) {
            if (_dragOffset.abs() > 100 || details.velocity.pixelsPerSecond.dy.abs() > 500) {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              Navigator.of(context).pop();
            } else {
              setState(() {
                _dragOffset = 0;
                _bgOpacity = 1.0;
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: Colors.black.withOpacity(_bgOpacity),
            child: Stack(
              children: [
                // ── Zoomable image ─────────────────────────────────────────
                Center(
                  child: Transform.translate(
                    offset: Offset(0, _dragOffset),
                    child: Hero(
                      tag: widget.heroTag,
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        minScale: 1.0,
                        maxScale: 5.0,
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Top bar ───────────────────────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 8,
                      right: 16,
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                        Expanded(
                          child: Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Reset zoom button
                        IconButton(
                          onPressed: _resetZoom,
                          icon: const Icon(Icons.zoom_out_map_rounded, color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Swipe hint ────────────────────────────────────────────
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Geser ke bawah untuk tutup · Cubit untuk zoom',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
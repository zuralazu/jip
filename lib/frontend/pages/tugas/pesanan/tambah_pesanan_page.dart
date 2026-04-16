import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/base_page.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/colors.dart';

class TambahPesananPage extends StatefulWidget {
  const TambahPesananPage({super.key});

  @override
  State<TambahPesananPage> createState() => _TambahPesananPageState();
}

class _TambahPesananPageState extends State<TambahPesananPage> with BasePage {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _namaPelangganC   = TextEditingController();
  final _emailPelangganC  = TextEditingController();
  final _noHpC            = TextEditingController();
  final _merekMobilC      = TextEditingController();
  final _modelMobilC      = TextEditingController();
  final _tahunMobilC      = TextEditingController();
  final _lokasiC          = TextEditingController();
  final _biayaC           = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _namaPelangganC.dispose();
    _emailPelangganC.dispose();
    _noHpC.dispose();
    _merekMobilC.dispose();
    _modelMobilC.dispose();
    _tahunMobilC.dispose();
    _lokasiC.dispose();
    _biayaC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatDate(DateTime dt) {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  String _formatDateApi(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showSnackbar('Pilih tanggal inspeksi dulu', isError: true);
      return;
    }
    if (_selectedTime == null) {
      _showSnackbar('Pilih waktu inspeksi dulu', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'nama_pelanggan'  : _namaPelangganC.text.trim(),
        'email_pelanggan' : _emailPelangganC.text.trim(),
        'no_hp_pelanggan' : _noHpC.text.trim(),
        'merek_mobil'     : _merekMobilC.text.trim(),
        'model_mobil'     : _modelMobilC.text.trim(),
        'tahun_mobil'     : _tahunMobilC.text.trim(),
        'lokasi'          : _lokasiC.text.trim(),
        'tanggal_inspeksi': _formatDateApi(_selectedDate!),
        'waktu_inspeksi'  : _formatTime(_selectedTime!),
        'biaya'           : _biayaC.text.trim(),
      };

      final result = await ApiService.tambahPesanan(payload);

      if (result['statusCode'] == 201) {
        _showSnackbar('Pesanan berhasil ditambahkan!');
        if (!mounted) return;
        Navigator.pop(context, true); // true = trigger refresh di TugasPage
      } else {
        final errors = result['data']?['errors'];
        final msg = errors != null
            ? (errors as Map).values.first[0]
            : result['data']?['message'] ?? 'Gagal menambahkan pesanan';
        _showSnackbar(msg, isError: true);
      }
    } catch (e) {
      handleApiError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade400 : const Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  _buildSection(
                    title: 'Data Pelanggan',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _buildField(
                        controller: _namaPelangganC,
                        label: 'Nama Pelanggan',
                        hint: 'Masukkan nama lengkap',
                        icon: Icons.badge_outlined,
                        validator: (v) =>
                        v!.isEmpty ? 'Nama pelanggan wajib diisi' : null,
                      ),
                      _buildField(
                        controller: _emailPelangganC,
                        label: 'Email',
                        hint: 'contoh@email.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v!.isEmpty) return 'Email wajib diisi';
                          if (!v.contains('@')) return 'Format email tidak valid';
                          return null;
                        },
                      ),
                      _buildField(
                        controller: _noHpC,
                        label: 'No. HP',
                        hint: '08xxxxxxxxxx',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                        v!.isEmpty ? 'No. HP wajib diisi' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Data Kendaraan',
                    icon: Icons.directions_car_outlined,
                    children: [
                      _buildField(
                        controller: _merekMobilC,
                        label: 'Merek Mobil',
                        hint: 'Toyota, Honda, dll',
                        icon: Icons.branding_watermark_outlined,
                        validator: (v) =>
                        v!.isEmpty ? 'Merek mobil wajib diisi' : null,
                      ),
                      _buildField(
                        controller: _modelMobilC,
                        label: 'Model Mobil',
                        hint: 'Avanza, Civic, dll',
                        icon: Icons.car_repair_outlined,
                        validator: (v) =>
                        v!.isEmpty ? 'Model mobil wajib diisi' : null,
                      ),
                      _buildField(
                        controller: _tahunMobilC,
                        label: 'Tahun Mobil',
                        hint: '2020',
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (v) {
                          if (v!.isEmpty) return 'Tahun wajib diisi';
                          if (v.length != 4) return 'Tahun harus 4 digit';
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Detail Inspeksi',
                    icon: Icons.assignment_outlined,
                    children: [
                      _buildField(
                        controller: _lokasiC,
                        label: 'Lokasi Inspeksi',
                        hint: 'Alamat lengkap lokasi',
                        icon: Icons.location_on_outlined,
                        validator: (v) =>
                        v!.isEmpty ? 'Lokasi wajib diisi' : null,
                      ),
                      _buildField(
                        controller: _biayaC,
                        label: 'Biaya Inspeksi',
                        hint: '100000',
                        icon: Icons.payments_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) =>
                        v!.isEmpty ? 'Biaya wajib diisi' : null,
                      ),
                      // Tanggal
                      _buildDateTimePicker(
                        label: 'Tanggal Inspeksi',
                        icon: Icons.event_outlined,
                        value: _selectedDate != null
                            ? _formatDate(_selectedDate!)
                            : null,
                        hint: 'Pilih tanggal',
                        onTap: _pickDate,
                      ),
                      // Waktu
                      _buildDateTimePicker(
                        label: 'Waktu Inspeksi',
                        icon: Icons.access_time_rounded,
                        value: _selectedTime != null
                            ? _formatTime(_selectedTime!)
                            : null,
                        hint: 'Pilih waktu',
                        onTap: _pickTime,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 8,
        right: 20,
        bottom: 20,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          const Expanded(
            child: Text(
              'Tambah Pesanan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16, thickness: 0.5, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: const TextStyle(fontSize: 13, color: AppColors.textDark),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
          labelStyle: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required IconData icon,
    required String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value ?? hint,
                  style: TextStyle(
                    fontSize: 13,
                    color: value != null
                        ? AppColors.textDark
                        : AppColors.textGrey,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        )
            : const Text(
          'Simpan Pesanan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
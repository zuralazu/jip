import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/base_page.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/colors.dart';
import 'package:intl/intl.dart';

class TambahPesananPage extends StatefulWidget {
  const TambahPesananPage({super.key});

  @override
  State<TambahPesananPage> createState() => _TambahPesananPageState();
}

class _TambahPesananPageState extends State<TambahPesananPage>
    with BasePage, TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _hasAttemptedSubmit = false;

  // Track which fields have been touched (for early validation feedback)
  final Set<String> _touchedFields = {};

  // Controllers
  final _namaPelangganC   = TextEditingController();
  final _emailPelangganC  = TextEditingController();
  final _noHpC            = TextEditingController();
  final _alamatPelangganC = TextEditingController();
  final _merekMobilC      = TextEditingController();
  final _modelMobilC      = TextEditingController();
  final _tahunMobilC      = TextEditingController();
  final _lokasiC          = TextEditingController();
  final _biayaC           = TextEditingController();

  // Focus nodes for better UX
  final _namaFocus    = FocusNode();
  final _emailFocus   = FocusNode();
  final _noHpFocus    = FocusNode();
  final _alamatFocus  = FocusNode();
  final _merekFocus   = FocusNode();
  final _modelFocus   = FocusNode();
  final _tahunFocus   = FocusNode();
  final _lokasiFocus  = FocusNode();
  final _biayaFocus   = FocusNode();

  AnimationController? _shakeController;
  Animation<double>? _shakeAnimation;

  final _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Computed completion progress (0.0 - 1.0)
  double get _completionProgress {
    int filled = 0;
    int total = 11;
    if (_namaPelangganC.text.trim().isNotEmpty) filled++;
    if (_emailPelangganC.text.trim().isNotEmpty &&
        _emailPelangganC.text.contains('@') &&
        _emailPelangganC.text.contains('.')) filled++;
    if (_noHpC.text.trim().length >= 2) filled++;
    if (_alamatPelangganC.text.trim().isNotEmpty) filled++;
    if (_merekMobilC.text.trim().isNotEmpty) filled++;
    if (_modelMobilC.text.trim().isNotEmpty) filled++;
    if (_tahunMobilC.text.trim().length == 4) filled++;
    if (_lokasiC.text.trim().isNotEmpty) filled++;
    if (_biayaC.text.trim().isNotEmpty) filled++;
    if (_selectedDate != null) filled++;
    if (_selectedTime != null) filled++;
    return filled / total;
  }

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController!, curve: Curves.elasticIn),
    );

    // Rupiah formatter
    _biayaC.addListener(() {
      final raw = _biayaC.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (raw.isEmpty) return;
      final number = int.tryParse(raw);
      if (number == null) return;
      final formatted = _rupiahFormat.format(number);
      if (_biayaC.text != formatted) {
        _biayaC.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
      if (_hasAttemptedSubmit) setState(() {});
    });

    // Rebuild on change for progress bar
    for (final c in [
      _namaPelangganC, _emailPelangganC, _noHpC, _alamatPelangganC,
      _merekMobilC, _modelMobilC, _tahunMobilC, _lokasiC,
    ]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }

    // Mark fields as touched when focus is lost
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    final pairs = {
      'nama'   : _namaFocus,
      'email'  : _emailFocus,
      'noHp'   : _noHpFocus,
      'alamat' : _alamatFocus,
      'merek'  : _merekFocus,
      'model'  : _modelFocus,
      'tahun'  : _tahunFocus,
      'lokasi' : _lokasiFocus,
      'biaya'  : _biayaFocus,
    };
    pairs.forEach((key, node) {
      node.addListener(() {
        if (!node.hasFocus) {
          setState(() => _touchedFields.add(key));
        }
      });
    });
  }

  @override
  void dispose() {
    _shakeController?.dispose();
    for (final c in [
      _namaPelangganC, _emailPelangganC, _noHpC, _alamatPelangganC,
      _merekMobilC, _modelMobilC, _tahunMobilC, _lokasiC, _biayaC,
    ]) {
      c.dispose();
    }
    for (final f in [
      _namaFocus, _emailFocus, _noHpFocus, _alamatFocus,
      _merekFocus, _modelFocus, _tahunFocus, _lokasiFocus, _biayaFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Validators ────────────────────────────────────────────────────────────

  String? _validateNama(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nama pelanggan wajib diisi';
    if (v.trim().length < 3) return 'Nama minimal 3 karakter';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(v.trim())) return 'Format email tidak valid';
    return null;
  }

  String? _validateNoHp(String? v) {
    if (v == null || v.trim().isEmpty) return 'No. HP wajib diisi';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'No. HP minimal 10 digit';
    if (digits.length > 13) return 'No. HP maksimal 13 digit';
    if (!digits.startsWith('0') && !digits.startsWith('62')) {
      return 'No. HP harus diawali 0 atau 62';
    }
    return null;
  }

  String? _validateAlamat(String? v) {
    if (v == null || v.trim().isEmpty) return 'Alamat wajib diisi';
    if (v.trim().length < 2) return 'Alamat terlalu singkat (min 2 karakter)';
    return null;
  }

  String? _validateMerek(String? v) {
    if (v == null || v.trim().isEmpty) return 'Merek mobil wajib diisi';
    return null;
  }

  String? _validateModel(String? v) {
    if (v == null || v.trim().isEmpty) return 'Model mobil wajib diisi';
    return null;
  }

  String? _validateTahun(String? v) {
    if (v == null || v.trim().isEmpty) return 'Tahun wajib diisi';
    if (v.length != 4) return 'Tahun harus 4 digit';
    final year = int.tryParse(v);
    if (year == null) return 'Tahun tidak valid';
    final currentYear = DateTime.now().year;
    if (year < 1980) return 'Tahun terlalu lama (min 1980)';
    if (year > currentYear + 1) return 'Tahun tidak valid';
    return null;
  }

  String? _validateLokasi(String? v) {
    if (v == null || v.trim().isEmpty) return 'Lokasi inspeksi wajib diisi';
    if (v.trim().length < 5) return 'Lokasi terlalu singkat';
    return null;
  }

  String? _validateBiaya(String? v) {
    if (v == null || v.trim().isEmpty) return 'Biaya wajib diisi';
    final raw = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return 'Biaya wajib diisi';
    final amount = int.tryParse(raw) ?? 0;
    if (amount < 10000) return 'Biaya minimum Rp 10.000';
    return null;
  }

  // ── Date / Time ───────────────────────────────────────────────────────────

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
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formatDate(DateTime dt) {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final hari = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    return '${hari[dt.weekday % 7]}, ${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  String _formatDateApi(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() {
      _hasAttemptedSubmit = true;
      _touchedFields.addAll([
        'nama', 'email', 'noHp', 'alamat', 'merek', 'model',
        'tahun', 'lokasi', 'biaya'
      ]);
    });

    final formValid = _formKey.currentState!.validate();
    if (!formValid || _selectedDate == null || _selectedTime == null) {
      // Shake the submit button & show snackbar
      _shakeController?.forward(from: 0);
      _showErrorSnackbar();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'nama_pelanggan'  : _namaPelangganC.text.trim(),
        'email_pelanggan' : _emailPelangganC.text.trim(),
        'no_hp_pelanggan' : _noHpC.text.trim(),
        'alamat_pelanggan': _alamatPelangganC.text.trim(),
        'merek_mobil'     : _merekMobilC.text.trim(),
        'model_mobil'     : _modelMobilC.text.trim(),
        'tahun_mobil'     : _tahunMobilC.text.trim(),
        'lokasi'          : _lokasiC.text.trim(),
        'tanggal_inspeksi': _formatDateApi(_selectedDate!),
        'waktu_inspeksi'  : _formatTime(_selectedTime!),
        'biaya': _biayaC.text.replaceAll(RegExp(r'[^0-9]'), ''),
      };

      final result = await ApiService.tambahPesanan(payload);

      if (result['statusCode'] == 201) {
        _showSuccessSnackbar('Pesanan berhasil ditambahkan!');
        if (!mounted) return;
        Navigator.pop(context, true);
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

  void _showErrorSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Harap lengkapi semua data yang diperlukan',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: const Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          _buildHeader(),
          // Progress bar
          _buildProgressBar(),
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: _hasAttemptedSubmit
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  _buildSection(
                    title: 'Data Pelanggan',
                    icon: Icons.person_outline_rounded,
                    badge: _sectionBadge(['nama', 'email', 'noHp', 'alamat']),
                    children: [
                      _buildField(
                        controller: _namaPelangganC,
                        focusNode: _namaFocus,
                        fieldKey: 'nama',
                        label: 'Nama Pelanggan',
                        hint: 'Masukkan nama lengkap',
                        icon: Icons.badge_outlined,
                        validator: _validateNama,
                        nextFocus: _emailFocus,
                      ),
                      _buildField(
                        controller: _emailPelangganC,
                        focusNode: _emailFocus,
                        fieldKey: 'email',
                        label: 'Email',
                        hint: 'contoh@email.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        nextFocus: _noHpFocus,
                      ),
                      _buildField(
                        controller: _noHpC,
                        focusNode: _noHpFocus,
                        fieldKey: 'noHp',
                        label: 'No. HP',
                        hint: '08xxxxxxxxxx',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: _validateNoHp,
                        nextFocus: _alamatFocus,
                        helperText: 'Format: 08xx atau 62xx',
                      ),
                      _buildField(
                        controller: _alamatPelangganC,
                        focusNode: _alamatFocus,
                        fieldKey: 'alamat',
                        label: 'Alamat Pelanggan',
                        hint: 'Masukkan alamat lengkap',
                        icon: Icons.home_outlined,
                        validator: _validateAlamat,
                        maxLines: 2,
                        helperText: 'Minimal 2 karakter',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    title: 'Data Kendaraan',
                    icon: Icons.directions_car_outlined,
                    badge: _sectionBadge(['merek', 'model', 'tahun']),
                    children: [
                      _buildField(
                        controller: _merekMobilC,
                        focusNode: _merekFocus,
                        fieldKey: 'merek',
                        label: 'Merek Mobil',
                        hint: 'Toyota, Honda, Suzuki...',
                        icon: Icons.branding_watermark_outlined,
                        validator: _validateMerek,
                        nextFocus: _modelFocus,
                      ),
                      _buildField(
                        controller: _modelMobilC,
                        focusNode: _modelFocus,
                        fieldKey: 'model',
                        label: 'Model Mobil',
                        hint: 'Avanza, Civic, Ertiga...',
                        icon: Icons.directions_car_filled_outlined,
                        validator: _validateModel,
                        nextFocus: _tahunFocus,
                      ),
                      _buildField(
                        controller: _tahunMobilC,
                        focusNode: _tahunFocus,
                        fieldKey: 'tahun',
                        label: 'Tahun Pembuatan',
                        hint: 'Contoh: 2020',
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: _validateTahun,
                        helperText: 'Tahun 1980 – ${DateTime.now().year + 1}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    title: 'Detail Inspeksi',
                    icon: Icons.assignment_outlined,
                    badge: _sectionBadge(['lokasi', 'biaya']),
                    children: [
                      _buildField(
                        controller: _lokasiC,
                        focusNode: _lokasiFocus,
                        fieldKey: 'lokasi',
                        label: 'Lokasi Inspeksi',
                        hint: 'Alamat lengkap lokasi inspeksi',
                        icon: Icons.location_on_outlined,
                        validator: _validateLokasi,
                        nextFocus: _biayaFocus,
                      ),
                      _buildField(
                        controller: _biayaC,
                        focusNode: _biayaFocus,
                        fieldKey: 'biaya',
                        label: 'Biaya Inspeksi',
                        hint: 'Rp 0',
                        icon: Icons.payments_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: _validateBiaya,
                        helperText: 'Minimum Rp 10.000',
                      ),
                      _buildDateTimePicker(
                        label: 'Tanggal Inspeksi',
                        icon: Icons.event_outlined,
                        value: _selectedDate != null
                            ? _formatDate(_selectedDate!)
                            : null,
                        hint: 'Pilih tanggal inspeksi',
                        onTap: _pickDate,
                        hasError: _hasAttemptedSubmit && _selectedDate == null,
                        errorText: 'Tanggal inspeksi wajib dipilih',
                      ),
                      _buildDateTimePicker(
                        label: 'Waktu Inspeksi',
                        icon: Icons.access_time_rounded,
                        value: _selectedTime != null
                            ? _formatTime(_selectedTime!)
                            : null,
                        hint: 'Pilih waktu inspeksi',
                        onTap: _pickTime,
                        hasError: _hasAttemptedSubmit && _selectedTime == null,
                        errorText: 'Waktu inspeksi wajib dipilih',
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildSubmitButton(),
                  const SizedBox(height: 8),
                  // Hint text
                  Center(
                    child: Text(
                      'Semua field bertanda * wajib diisi',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Returns how many fields in a section are complete
  int _sectionBadge(List<String> fields) {
    int filled = 0;
    for (final f in fields) {
      switch (f) {
        case 'nama':
          if (_namaPelangganC.text.trim().length >= 3) filled++;
          break;
        case 'email':
          final em = _emailPelangganC.text.trim();
          if (RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$').hasMatch(em)) filled++;
          break;
        case 'noHp':
          final d = _noHpC.text.replaceAll(RegExp(r'\D'), '');
          if (d.length >= 10) filled++;
          break;
        case 'alamat':
          if (_alamatPelangganC.text.trim().length >= 10) filled++;
          break;
        case 'merek':
          if (_merekMobilC.text.trim().isNotEmpty) filled++;
          break;
        case 'model':
          if (_modelMobilC.text.trim().isNotEmpty) filled++;
          break;
        case 'tahun':
          if (_tahunMobilC.text.length == 4) filled++;
          break;
        case 'lokasi':
          if (_lokasiC.text.trim().length >= 5) filled++;
          break;
        case 'biaya':
          final raw = _biayaC.text.replaceAll(RegExp(r'[^0-9]'), '');
          if ((int.tryParse(raw) ?? 0) >= 10000) filled++;
          break;
      }
    }
    return filled;
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 4,
        right: 20,
        bottom: 18,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tambah Pesanan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Isi semua data dengan benar',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _completionProgress;
    final percent = (progress * 100).round();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kelengkapan Form',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: percent == 100
                            ? const Color(0xFF2ECC71)
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent == 100
                          ? const Color(0xFF2ECC71)
                          : AppColors.primary,
                    ),
                    minHeight: 5,
                  ),
                ),
              ],
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
    required int badge,
  }) {
    final total = children.length;
    final isComplete = badge == total;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
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
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 15, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? const Color(0xFF2ECC71).withOpacity(0.12)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isComplete
                          ? const Color(0xFF2ECC71).withOpacity(0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isComplete)
                        const Icon(Icons.check_circle_rounded,
                            size: 12, color: Color(0xFF2ECC71))
                      else
                        Icon(Icons.radio_button_unchecked_rounded,
                            size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '$badge/$total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isComplete
                              ? const Color(0xFF2ECC71)
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 16,
            thickness: 0.5,
            color: Colors.grey.shade100,
          ),
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
    required FocusNode focusNode,
    required String fieldKey,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    FocusNode? nextFocus,
    String? helperText,
    int maxLines = 1,
  }) {
    // Validate current value for real-time border coloring
    final currentError = _touchedFields.contains(fieldKey) || _hasAttemptedSubmit
        ? validator?.call(controller.text)
        : null;
    final isValid = controller.text.isNotEmpty && currentError == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            maxLines: maxLines,
            textInputAction:
            nextFocus != null ? TextInputAction.next : TextInputAction.done,
            onFieldSubmitted: (_) {
              if (nextFocus != null) {
                FocusScope.of(context).requestFocus(nextFocus);
              }
            },
            onChanged: (_) {
              if (_touchedFields.contains(fieldKey) || _hasAttemptedSubmit) {
                setState(() {});
              }
            },
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: Icon(
                icon,
                size: 18,
                color: isValid
                    ? const Color(0xFF2ECC71)
                    : currentError != null
                    ? Colors.red.shade400
                    : AppColors.primary,
              ),
              suffixIcon: controller.text.isNotEmpty
                  ? isValid
                  ? const Icon(Icons.check_circle_rounded,
                  size: 18, color: Color(0xFF2ECC71))
                  : currentError != null
                  ? Icon(Icons.error_rounded,
                  size: 18, color: Colors.red.shade400)
                  : null
                  : null,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isValid
                    ? const Color(0xFF2ECC71)
                    : currentError != null
                    ? Colors.red.shade400
                    : AppColors.textGrey,
              ),
              hintStyle: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade400,
              ),
              helperText: helperText,
              helperStyle: TextStyle(
                fontSize: 10.5,
                color: Colors.grey.shade500,
              ),
              filled: true,
              fillColor: isValid
                  ? const Color(0xFFEFF9F4)
                  : currentError != null
                  ? Colors.red.shade50
                  : const Color(0xFFF8F9FA),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isValid
                      ? const Color(0xFF2ECC71).withOpacity(0.5)
                      : currentError != null
                      ? Colors.red.shade200
                      : const Color(0xFFE8E8E8),
                  width: isValid || currentError != null ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isValid
                      ? const Color(0xFF2ECC71)
                      : currentError != null
                      ? Colors.red.shade400
                      : AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 2),
              ),
              errorStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required IconData icon,
    required String? value,
    required String hint,
    required VoidCallback onTap,
    bool hasError = false,
    String? errorText,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: value != null
                    ? const Color(0xFFEFF9F4)
                    : hasError
                    ? Colors.red.shade50
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: value != null
                      ? const Color(0xFF2ECC71).withOpacity(0.5)
                      : hasError
                      ? Colors.red.shade300
                      : const Color(0xFFE8E8E8),
                  width: value != null || hasError ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: value != null
                        ? const Color(0xFF2ECC71)
                        : hasError
                        ? Colors.red.shade400
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: value != null
                                ? const Color(0xFF2ECC71)
                                : hasError
                                ? Colors.red.shade400
                                : AppColors.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value ?? hint,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: value != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: value != null
                                ? AppColors.textDark
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (value != null)
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: Color(0xFF2ECC71))
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: hasError
                          ? Colors.red.shade400
                          : Colors.grey.shade400,
                    ),
                ],
              ),
            ),
          ),
          if (hasError && errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 12, color: Colors.red.shade400),
                  const SizedBox(width: 4),
                  Text(
                    errorText,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final progress = _completionProgress;

    final button = SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: progress == 1.0
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.85),
          elevation: progress == 1.0 ? 3 : 0,
          shadowColor: AppColors.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2.5),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save_alt_rounded,
                size: 18, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Simpan Pesanan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );

    final anim = _shakeAnimation;
    if (anim == null) return button;

    return AnimatedBuilder(
      animation: anim,
      builder: (ctx, child) {
        final isShaking = _shakeController?.isAnimating ?? false;
        return Transform.translate(
          offset: Offset(
            isShaking ? 6 * (0.5 - (anim.value % 0.2) / 0.2).abs() : 0,
            0,
          ),
          child: child,
        );
      },
      child: button,
    );
  }
}
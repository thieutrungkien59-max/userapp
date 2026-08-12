import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/state/app_state.dart';
import '../../../core/state/session_store.dart';
import '../../../theme/app_colors.dart';
import '../../auth/data/auth_api.dart';
import '../../orders/data/geocoding_service.dart';
import '../../orders/presentation/location_picker_screen.dart';
import '../data/default_pickup_store.dart';

const Color _profileRed = Color(0xFFEF1D36);

class EditCustomerProfileScreen extends StatefulWidget {
  const EditCustomerProfileScreen({
    super.key,
    required this.customerId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.address,
  });

  final String customerId;
  final String fullName;
  final String phone;
  final String email;
  final String address;

  @override
  State<EditCustomerProfileScreen> createState() =>
      _EditCustomerProfileScreenState();
}

class _EditCustomerProfileScreenState extends State<EditCustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  DefaultPickupLocation? _savedPickup;
  DefaultPickupLocation? _selectedPickup;
  bool _loadingPickup = true;
  bool _savingPickup = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.fullName.trim());
    _phoneController = TextEditingController(text: widget.phone.trim());
    _emailController = TextEditingController(text: widget.email.trim());

    _loadDefaultPickup();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }

    if (name.length < 2) {
      return 'Họ và tên phải có ít nhất 2 ký tự';
    }

    if (name.length > 100) {
      return 'Họ và tên tối đa 100 ký tự';
    }

    if (!RegExp(r"^[a-zA-ZÀ-ỹĐđ\s'.-]+$").hasMatch(name)) {
      return "Họ tên chỉ được chứa chữ, khoảng trắng, dấu '.', '-' hoặc \"'\"";
    }

    if (RegExp(r'\s{2,}').hasMatch(name)) {
      return 'Không nhập nhiều khoảng trắng liên tiếp';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }

    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      return 'Số điện thoại phải gồm đúng 10 số và bắt đầu bằng 0';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) return null;

    if (email.length > 100) {
      return 'Email tối đa 100 ký tự';
    }

    final emailRegex = RegExp(
      r'^[A-Za-z0-9.!#$%&*+/=?^_`{|}~-]+@'
      r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
      r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Email không đúng định dạng';
    }

    return null;
  }

  Future<void> _loadDefaultPickup() async {
    try {
      final saved = await defaultPickupStore.load(widget.customerId);

      if (!mounted) return;

      setState(() {
        _savedPickup = saved;
        _selectedPickup = saved;
        _loadingPickup = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingPickup = false;
      });
    }
  }

  Future<void> _pickDefaultPickup() async {
    final current = _selectedPickup;

    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          title: 'Chọn điểm lấy hàng mặc định',
          initialLocation: current == null
              ? null
              : LatLng(current.latitude, current.longitude),
        ),
      ),
    );

    if (!mounted || result == null) return;

    try {
      final address = await geocodingService.reverseGeocode(result);

      if (!mounted) return;

      setState(() {
        _selectedPickup = DefaultPickupLocation(
          address: address,
          latitude: result.latitude,
          longitude: result.longitude,
        );
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveDefaultPickup() async {
    final location = _selectedPickup;

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn một vị trí trên bản đồ trước.'),
        ),
      );
      return;
    }

    setState(() => _savingPickup = true);

    try {
      await defaultPickupStore.save(widget.customerId, location);

      if (!mounted) return;

      setState(() {
        _savedPickup = location;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu điểm lấy mặc định trên thiết bị.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lưu điểm lấy mặc định: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingPickup = false);
      }
    }
  }

  Future<void> _clearDefaultPickup() async {
    await defaultPickupStore.clear(widget.customerId);

    if (!mounted) return;

    setState(() {
      _savedPickup = null;
      _selectedPickup = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa điểm lấy mặc định trên thiết bị.')),
    );
  }

  String _normalizeSpaces(String value) {
    return value.trim().replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final fullName = _normalizeSpaces(_nameController.text);
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    setState(() => _saving = true);

    try {
      // Dùng đúng AuthApi đang được ProfileScreen cũ sử dụng.
      // Backend vẫn là nơi validate cuối cùng và kiểm tra unique SĐT/email.
      final session = await authApi.updateCustomer(
        customerId: widget.customerId,
        name: fullName,
        phone: phone,
        email: email.isEmpty ? null : email,

        // Backend hiện chưa có lat/lng mặc định.
        // Không ghi text map vào DiaChi để tránh tạo dữ liệu nửa vời.
        address: null,
      );

      // Đồng bộ ngay dữ liệu đang hiển thị toàn app.
      final current = appState.value;
      appState.value = current.copyWith(
        name: session.name,
        phone: session.phone,
        email: session.email,
        defaultAddress: current.defaultAddress,
      );

      // Lưu session để thoát/mở app lại vẫn thấy dữ liệu mới.
      await sessionStore.save(appState.value);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ thành công'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể cập nhật hồ sơ: '
            '${error.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F8),
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: Text(
          'Chỉnh sửa hồ sơ',
          style: GoogleFonts.spaceGrotesk(
            color: _profileRed,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _infoBanner(),
              const SizedBox(height: 22),
              Text(
                'Thông tin có thể chỉnh sửa',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const SizedBox(height: 16),
              _field(
                controller: _nameController,
                label: 'Họ và tên',
                hint: 'Ví dụ: Nguyễn Văn An',
                icon: Icons.person_outline,
                maxLength: 100,
                validator: _validateName,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r"[a-zA-ZÀ-ỹĐđ\s'.-]"),
                  ),
                  LengthLimitingTextInputFormatter(100),
                ],
              ),
              const SizedBox(height: 14),
              _field(
                controller: _phoneController,
                label: 'Số điện thoại',
                hint: 'Ví dụ: 0912345678',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: _validatePhone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              const SizedBox(height: 14),
              _field(
                controller: _emailController,
                label: 'Email',
                hint: 'ten@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                maxLength: 100,
                validator: _validateEmail,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  LengthLimitingTextInputFormatter(100),
                ],
              ),
              const SizedBox(height: 22),

              Text(
                'Điểm lấy hàng mặc định',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bạn có thể lưu trước điểm lấy hàng trên bản đồ bằng cách chọn pin.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              _defaultPickupCard(),
              const SizedBox(height: 22),
              Text(
                'Thông tin không được chỉnh sửa',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _lockedCustomerId(),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _profileRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _profileRed.withOpacity(0.45),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'LƯU THAY ĐỔI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _profileRed.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _profileRed.withOpacity(0.14)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.manage_accounts_outlined, color: _profileRed),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bạn vui lòng cập nhật thông tin liên hệ chính xác để tổng đài LogiRoute có thể '
              'liên hệ xử lý đơn hàng.',
              style: TextStyle(height: 1.45, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
      textInputAction: maxLines == 1
          ? TextInputAction.next
          : TextInputAction.newline,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        alignLabelWithHint: maxLines > 1,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _profileRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _defaultPickupCard() {
    if (_loadingPickup) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const CircularProgressIndicator(),
      );
    }

    final selected = _selectedPickup;
    final hasSaved = _savedPickup != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected == null
              ? Colors.grey.shade300
              : Colors.green.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected == null
                    ? Icons.add_location_alt_outlined
                    : Icons.location_on,
                color: selected == null
                    ? Colors.grey.shade600
                    : Colors.green.shade700,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: selected == null
                    ? const Text(
                        'Chưa thiết lập điểm lấy hàng mặc định.',
                        style: TextStyle(color: AppColors.muted, height: 1.4),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.address,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${selected.latitude.toStringAsFixed(6)}, '
                            '${selected.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            hasSaved && _samePickup(selected, _savedPickup!)
                                ? 'Đã lưu trên thiết bị'
                                : 'Chưa lưu thay đổi vị trí',
                            style: TextStyle(
                              color:
                                  hasSaved &&
                                      _samePickup(selected, _savedPickup!)
                                  ? Colors.green.shade700
                                  : Colors.orange.shade800,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDefaultPickup,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(
                    selected == null ? 'Chọn trên bản đồ' : 'Chọn lại',
                  ),
                ),
              ),
              if (selected != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _savingPickup ? null : _saveDefaultPickup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _profileRed,
                      foregroundColor: Colors.white,
                    ),
                    icon: _savingPickup
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Lưu điểm'),
                  ),
                ),
              ],
            ],
          ),
          if (_savedPickup != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _clearDefaultPickup,
                child: const Text('Xóa điểm mặc định'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _samePickup(DefaultPickupLocation a, DefaultPickupLocation b) {
    return a.address == b.address &&
        (a.latitude - b.latitude).abs() < 0.0000001 &&
        (a.longitude - b.longitude).abs() < 0.0000001;
  }

  Widget _lockedCustomerId() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.badge_outlined, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mã khách hàng',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.customerId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade500),
        ],
      ),
    );
  }
}

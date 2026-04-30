import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../account/account_state.dart';
import '../api/token_storage.dart';
import '../requests/home_requests.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.profile,
    required this.onProfileChanged,
    required this.onLogout,
  });

  final MemberProfileResponse profile;
  final Future<void> Function() onProfileChanged;
  final Future<void> Function() onLogout;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushEnabled = false;
  bool _isSavingPush = false;
  bool _isWithdrawing = false;
  bool _isEditingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadPushState();
  }

  Future<void> _loadPushState() async {
    final enabled = await TokenStorage.instance.getPushEnabled();
    if (!mounted) return;
    setState(() {
      _pushEnabled = enabled;
    });
  }

  Future<void> _togglePush(bool value) async {
    if (_isSavingPush) return;
    setState(() {
      _isSavingPush = true;
    });

    final token = await _getOrCreateLocalDeviceToken();
    try {
      if (value) {
        await HomeRequests.syncDeviceToken(deviceToken: token);
      } else {
        await HomeRequests.deleteDeviceToken(deviceToken: token);
      }
      await TokenStorage.instance.setPushEnabled(value);
      if (!mounted) return;
      setState(() {
        _pushEnabled = value;
      });
    } catch (error) {
      if (mounted) {
        _showSnack(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPush = false;
        });
      }
    }
  }

  Future<String> _getOrCreateLocalDeviceToken() async {
    final savedToken = await TokenStorage.instance.getDeviceToken();
    if (savedToken != null && savedToken.isNotEmpty) return savedToken;
    final token = 'local-${DateTime.now().millisecondsSinceEpoch}';
    await TokenStorage.instance.setDeviceToken(token);
    return token;
  }

  Future<void> _saveProfile({required String nickname, XFile? image}) async {
    if (nickname.trim().isEmpty) {
      _showSnack('닉네임을 입력해주세요');
      return;
    }
    try {
      String? profileImageKey;
      if (image != null) {
        final bytes = await image.readAsBytes();
        final upload = await HomeRequests.createProfileImageUploadUrl(
          fileName: image.name,
        );
        await HomeRequests.uploadFileToPresignedUrl(
          presignedUrl: upload.presignedUrl,
          bytes: bytes,
          contentType: _contentTypeFor(image.name),
        );
        await HomeRequests.completeUpload(objectKey: upload.objectKey);
        profileImageKey = upload.objectKey;
      }

      await HomeRequests.updateProfile(
        nickname: nickname.trim(),
        profileImageKey: profileImageKey,
      );
      AccountState.instance.setLoggedInUser(
        loginId: widget.profile.loginId,
        nickname: nickname.trim(),
        createdAt: widget.profile.createdAt,
        profileImageUrl: widget.profile.profileImageUrl,
        preferences: widget.profile.preferences,
      );
      await widget.onProfileChanged();
      if (!mounted) return;
      setState(() {
        _isEditingProfile = false;
      });
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString());
    }
  }

  Future<void> _editPreference(AccountPreference? preference) async {
    final categories = await HomeRequests.fetchCategories();
    if (!mounted) return;
    final result = await Navigator.of(context).push<_PreferenceEditResult>(
      MaterialPageRoute(
        builder: (context) => _PreferenceEditPage(
          categories: categories,
          preference: preference,
          usedCount: widget.profile.preferences.length,
        ),
      ),
    );
    if (result == null) return;

    try {
      if (preference == null) {
        await HomeRequests.appendPreference(
          categoryTopicId: result.categoryTopicId,
          difficulty: result.difficulty,
        );
      } else {
        await HomeRequests.updatePreference(
          preferenceId: preference.preferenceId,
          categoryTopicId: result.categoryTopicId,
          difficulty: result.difficulty,
        );
      }
      await widget.onProfileChanged();
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString());
    }
  }

  Future<void> _withdraw() async {
    if (_isWithdrawing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('정말 탈퇴하시겠습니까? 계정과 관련 데이터가 삭제 처리됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isWithdrawing = true;
    });
    try {
      await HomeRequests.withdrawMember();
      await widget.onLogout();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isWithdrawing = false;
      });
      _showSnack(error.toString());
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final preferences = widget.profile.preferences;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileCard(
          profile: widget.profile,
          isEditing: _isEditingProfile,
          onEdit: () {
            setState(() {
              _isEditingProfile = true;
            });
          },
          onCancel: () {
            setState(() {
              _isEditingProfile = false;
            });
          },
          onSave: _saveProfile,
        ),
        const SizedBox(height: 34),
        _SectionTitle(
          title: '학습 설정',
          trailing: '${preferences.length}/5',
          actionLabel: '+ 추가',
          onAction: preferences.length >= 5
              ? null
              : () => _editPreference(null),
        ),
        const SizedBox(height: 18),
        if (preferences.isEmpty)
          const _EmptyPreferenceCard()
        else
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (var i = 0; i < preferences.length; i++)
                _PreferenceCard(
                  index: i + 1,
                  preference: preferences[i],
                  onEdit: () => _editPreference(preferences[i]),
                ),
            ],
          ),
        const SizedBox(height: 36),
        const _SectionTitle(title: '알림 설정'),
        const SizedBox(height: 16),
        _PushSettingCard(
          enabled: _pushEnabled,
          isSaving: _isSavingPush,
          onChanged: _togglePush,
        ),
        const SizedBox(height: 36),
        const Text(
          '나의 계정',
          style: TextStyle(
            color: Color(0xFF8B99B0),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        _WithdrawCard(isWithdrawing: _isWithdrawing, onTap: _withdraw),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.isEditing,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  final MemberProfileResponse profile;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final Future<void> Function({required String nickname, XFile? image}) onSave;

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return _EditableProfileCard(
        profile: profile,
        onCancel: onCancel,
        onSave: onSave,
      );
    }

    final name = profile.nickname.isNotEmpty
        ? profile.nickname
        : profile.loginId;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF4D68FF), Color(0xFF4E3FE8)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334B63FF),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0x335D74FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _ProfileImageOrInitial(
              name: name,
              imageUrl: profile.profileImageUrl,
              size: 92,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• 학습자 프로필',
                  style: TextStyle(
                    color: Color(0xFFDDE4FF),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${_formatDate(profile.createdAt)} 가입',
                  style: const TextStyle(
                    color: Color(0xFFDDE4FF),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            color: Colors.white,
            style: IconButton.styleFrom(
              side: const BorderSide(color: Color(0x44FFFFFF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableProfileCard extends StatefulWidget {
  const _EditableProfileCard({
    required this.profile,
    required this.onCancel,
    required this.onSave,
  });

  final MemberProfileResponse profile;
  final VoidCallback onCancel;
  final Future<void> Function({required String nickname, XFile? image}) onSave;

  @override
  State<_EditableProfileCard> createState() => _EditableProfileCardState();
}

class _EditableProfileCardState extends State<_EditableProfileCard> {
  late final TextEditingController _nicknameController;
  XFile? _image;
  Uint8List? _imageBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: widget.profile.nickname.isNotEmpty
          ? widget.profile.nickname
          : widget.profile.loginId,
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _image = image;
        _imageBytes = bytes;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });
    await widget.onSave(nickname: _nicknameController.text, image: _image);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _nicknameController.text.isNotEmpty
        ? _nicknameController.text
        : widget.profile.loginId;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF4D68FF), Color(0xFF4E3FE8)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  '• 프로필 수정',
                  style: TextStyle(
                    color: Color(0xFFDDE4FF),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isSaving ? null : widget.onCancel,
                icon: const Icon(Icons.close_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0x22FFFFFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Tooltip(
                message: '프로필 이미지 변경',
                child: InkWell(
                  onTap: _isSaving ? null : _pickImage,
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: const Color(0x335D74FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _imageBytes == null
                            ? _ProfileImageOrInitial(
                                name: name,
                                imageUrl: widget.profile.profileImageUrl,
                                size: 92,
                              )
                            : Image.memory(_imageBytes!, fit: BoxFit.cover),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          color: Color(0xFF4B63FF),
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '닉네임',
                      style: TextStyle(
                        color: Color(0xFFDDE4FF),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nicknameController,
                      enabled: !_isSaving,
                      maxLength: 50,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0x225D74FF),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0x55FFFFFF),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0x99FFFFFF),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 58,
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0x44FFFFFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 58,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2547D8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _isSaving ? '저장 중...' : '저장',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileImageOrInitial extends StatelessWidget {
  const _ProfileImageOrInitial({
    required this.name,
    required this.imageUrl,
    required this.size,
  });

  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _InitialText(name: name),
      );
    }
    return _InitialText(name: name);
  }
}

class _InitialText extends StatelessWidget {
  const _InitialText({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isEmpty ? 'H' : name.substring(0, 1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF4B63FF),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF8B99B0),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Text(
            trailing!,
            style: const TextStyle(
              color: Color(0xFF4B63FF),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
      ],
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({
    required this.index,
    required this.preference,
    required this.onEdit,
  });

  final int index;
  final AccountPreference preference;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12121B40),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#$index',
                style: const TextStyle(
                  color: Color(0xFF6C85FF),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onEdit,
                child: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFFC3CEDD),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            preference.categoryTopicName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          _SmallPill(label: _difficultyLabel(preference.difficulty)),
        ],
      ),
    );
  }
}

class _EmptyPreferenceCard extends StatelessWidget {
  const _EmptyPreferenceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text(
        '등록된 학습 설정이 없습니다.',
        style: TextStyle(color: Color(0xFF8B99B0), fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PushSettingCard extends StatelessWidget {
  const _PushSettingCard({
    required this.enabled,
    required this.isSaving,
    required this.onChanged,
  });

  final bool enabled;
  final bool isSaving;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingSurface(
      icon: Icons.notifications_none_rounded,
      iconColor: const Color(0xFF657BFF),
      title: '푸시 알림',
      subtitle: enabled ? '설정됨' : '미설정',
      trailing: Switch(value: enabled, onChanged: isSaving ? null : onChanged),
    );
  }
}

class _WithdrawCard extends StatelessWidget {
  const _WithdrawCard({required this.isWithdrawing, required this.onTap});

  final bool isWithdrawing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SettingSurface(
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFFF3045),
      iconBackground: const Color(0xFFFFEEF1),
      title: '회원 탈퇴',
      trailing: isWithdrawing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.3),
            )
          : const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFC4CDDA),
              size: 30,
            ),
      onTap: isWithdrawing ? null : onTap,
    );
  }
}

class _SettingSurface extends StatelessWidget {
  const _SettingSurface({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.iconBackground = const Color(0xFFF2F4FF),
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      shadowColor: const Color(0x14121B40),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF2E3A50),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Color(0xFF92A0B6),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _NicknameDialog extends StatefulWidget {
  const _NicknameDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('닉네임 수정'),
      content: TextField(
        controller: _controller,
        maxLength: 50,
        decoration: const InputDecoration(hintText: '닉네임'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('저장'),
        ),
      ],
    );
  }
}

class _PreferenceEditPage extends StatefulWidget {
  const _PreferenceEditPage({
    required this.categories,
    required this.preference,
    required this.usedCount,
  });

  final CategoryListResponse categories;
  final AccountPreference? preference;
  final int usedCount;

  @override
  State<_PreferenceEditPage> createState() => _PreferenceEditPageState();
}

class _PreferenceEditPageState extends State<_PreferenceEditPage> {
  CategoryResponse? _category;
  CategoryGroupResponse? _group;
  CategoryTopicResponse? _topic;
  String _difficulty = 'EASY';

  @override
  void initState() {
    super.initState();
    _difficulty = widget.preference?.difficulty ?? 'EASY';
  }

  @override
  Widget build(BuildContext context) {
    final groups = _category?.groups ?? const <CategoryGroupResponse>[];
    final topics = _group?.topics ?? const <CategoryTopicResponse>[];
    final canSubmit = _topic != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.chevron_left_rounded, size: 30),
                  label: const Text(
                    '뒤로 가기',
                    style: TextStyle(
                      color: Color(0xFF92A0B6),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.preference == null ? '학습 설정 추가' : '학습 설정 수정',
                style: const TextStyle(
                  color: Color(0xFF11182C),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  text: '새로운 학습 주제를 추가합니다. ',
                  style: const TextStyle(
                    color: Color(0xFF687794),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    TextSpan(
                      text: '${widget.usedCount}/5',
                      style: const TextStyle(
                        color: Color(0xFF3F57FF),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const TextSpan(text: ' 개 사용 중'),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              const _EditSectionLabel(title: '카테고리 선택'),
              const SizedBox(height: 14),
              const _EditStepLabel(title: '1. 분야'),
              const SizedBox(height: 12),
              _SelectBox(
                text: _category?.name ?? '분야를 선택하세요',
                enabled: true,
                onTap: () => _pickCategory(widget.categories.categories),
              ),
              const SizedBox(height: 24),
              const _EditStepLabel(title: '2. 분류'),
              const SizedBox(height: 12),
              _SelectBox(
                text: _group?.name ?? '먼저 분야를 선택하세요',
                enabled: _category != null,
                onTap: () => _pickGroup(groups),
              ),
              const SizedBox(height: 24),
              const _EditStepLabel(title: '3. 주제'),
              const SizedBox(height: 12),
              _SelectBox(
                text: _topic?.name ?? '분류를 먼저 선택하세요',
                enabled: _group != null,
                onTap: () => _pickTopic(topics),
              ),
              const SizedBox(height: 44),
              const _EditSectionLabel(title: '난이도 선택'),
              const SizedBox(height: 14),
              _DifficultyOption(
                title: '쉬움',
                subtitle: '기초적인 개념과 간단한 문제',
                selected: _difficulty == 'EASY',
                onTap: () => setState(() => _difficulty = 'EASY'),
              ),
              const SizedBox(height: 16),
              _DifficultyOption(
                title: '보통',
                subtitle: '실무에 필요한 중급 수준의 문제',
                selected: _difficulty == 'MEDIUM',
                onTap: () => setState(() => _difficulty = 'MEDIUM'),
              ),
              const SizedBox(height: 16),
              _DifficultyOption(
                title: '어려움',
                subtitle: '심화 학습과 복잡한 문제',
                selected: _difficulty == 'HARD',
                onTap: () => setState(() => _difficulty = 'HARD'),
              ),
              const SizedBox(height: 44),
              SizedBox(
                height: 64,
                child: FilledButton(
                  onPressed: canSubmit
                      ? () {
                          Navigator.of(context).pop(
                            _PreferenceEditResult(
                              categoryTopicId: _topic!.id,
                              difficulty: _difficulty,
                            ),
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4B63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    widget.preference == null ? '학습 설정 추가' : '학습 설정 수정',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 64,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F5FC),
                    foregroundColor: const Color(0xFF2547D8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    '취소',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCategory(List<CategoryResponse> categories) async {
    final selected = await _showPicker<CategoryResponse>(
      title: '분야 선택',
      items: categories,
      labelBuilder: (category) => category.name,
    );
    if (selected == null) return;
    setState(() {
      _category = selected;
      _group = null;
      _topic = null;
    });
  }

  Future<void> _pickGroup(List<CategoryGroupResponse> groups) async {
    final selected = await _showPicker<CategoryGroupResponse>(
      title: '분류 선택',
      items: groups,
      labelBuilder: (group) => group.name,
    );
    if (selected == null) return;
    setState(() {
      _group = selected;
      _topic = null;
    });
  }

  Future<void> _pickTopic(List<CategoryTopicResponse> topics) async {
    final selected = await _showPicker<CategoryTopicResponse>(
      title: '주제 선택',
      items: topics,
      labelBuilder: (topic) => topic.name,
    );
    if (selected == null) return;
    setState(() {
      _topic = selected;
    });
  }

  Future<T?> _showPicker<T>({
    required String title,
    required List<T> items,
    required String Function(T item) labelBuilder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF11182C),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text('선택 가능한 항목이 없습니다.'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          title: Text(
                            labelBuilder(item),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EditSectionLabel extends StatelessWidget {
  const _EditSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF3F57FF),
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EditStepLabel extends StatelessWidget {
  const _EditStepLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF92A0B6),
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.text,
    required this.enabled,
    required this.onTap,
  });

  final String text;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: enabled ? 2 : 0,
      shadowColor: const Color(0x14121B40),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(
              color: enabled
                  ? const Color(0xFF2E3A50)
                  : const Color(0xFF9BA8BC),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyOption extends StatelessWidget {
  const _DifficultyOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF4B63FF)
                  : const Color(0xFFE9EEF6),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF2E3A50),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8B99B0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceEditResult {
  const _PreferenceEditResult({
    required this.categoryTopicId,
    required this.difficulty,
  });

  final int categoryTopicId;
  final String difficulty;
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDFFBE8),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0F9F45),
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}/$month/$day';
}

String _difficultyLabel(String difficulty) {
  switch (difficulty.toUpperCase()) {
    case 'EASY':
      return '쉬움';
    case 'MEDIUM':
      return '보통';
    case 'HARD':
      return '어려움';
    default:
      return difficulty.isEmpty ? '-' : difficulty;
  }
}

String _contentTypeFor(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  return 'image/png';
}

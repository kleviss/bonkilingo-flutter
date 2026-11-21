import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import '../../../core/theme/brand_colors.dart';
import '../../widgets/brand/auth_layout.dart' show BrandTextField;
import '../../widgets/brand/pill_button.dart';
import '../auth/login_screen.dart';

/// Bottom sheet for entering the Solana wallet BONK is paid out to.
///
/// Replaces an alert dialog whose text field was clipped by the buttons.
/// Rises with the keyboard, checks the address format before saving, and
/// asks guests to sign in first (wallets belong to an account).
class WalletAddressSheet extends StatefulWidget {
  final bool isDark;
  final bool isSignedIn;
  final String? currentAddress;

  /// Saves the address; returns whether it worked.
  final Future<bool> Function(String address) onSave;

  const WalletAddressSheet({
    required this.isDark,
    required this.isSignedIn,
    required this.onSave,
    this.currentAddress,
    super.key,
  });

  /// Solana addresses are base58 public keys: 32 to 44 characters without
  /// 0, O, I or l.
  static final _solanaAddress = RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$');

  static bool isValidAddress(String value) =>
      _solanaAddress.hasMatch(value.trim());

  /// Shows the sheet; resolves to true when an address was saved.
  static Future<bool?> show(
    BuildContext context, {
    required bool isDark,
    required bool isSignedIn,
    required Future<bool> Function(String address) onSave,
    String? currentAddress,
  }) {
    return showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => WalletAddressSheet(
        isDark: isDark,
        isSignedIn: isSignedIn,
        onSave: onSave,
        currentAddress: currentAddress,
      ),
    );
  }

  @override
  State<WalletAddressSheet> createState() => _WalletAddressSheetState();
}

class _WalletAddressSheetState extends State<WalletAddressSheet> {
  late final _controller = TextEditingController(text: widget.currentAddress);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _controller.text = text;
      setState(() => _error = null);
    }
  }

  Future<void> _save() async {
    final address = _controller.text.trim();
    if (!WalletAddressSheet.isValidAddress(address)) {
      setState(() => _error =
          "That doesn't look like a Solana address. Check it and try again.");
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await widget.onSave(address);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error =
            "Couldn't save your wallet. Check your connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = BrandPalette(widget.isDark);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      // Rise above the keyboard.
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + (bottomInset > 0 ? 0 : safeBottom),
        ),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1C1C1F) : BrandColors.cream,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: p.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Connect your Solana wallet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isSignedIn
                    ? 'Your BONK is paid out to this address when you withdraw.'
                    : 'Sign in first: your wallet and BONK balance belong to your account.',
                style: TextStyle(fontSize: 15, height: 1.4, color: p.muted),
              ),
              const SizedBox(height: 20),
              if (widget.isSignedIn) ...[
                BrandTextField(
                  isDark: widget.isDark,
                  label: 'Wallet address',
                  controller: _controller,
                  icon: Icons.account_balance_wallet_outlined,
                  placeholder: 'e.g. 7xKX…',
                  enabled: !_saving,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size.zero,
                    onPressed: _saving ? null : _paste,
                    child: const Text(
                      'Paste',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style:
                        const TextStyle(fontSize: 14, color: BrandPalette.red),
                  ),
                  const SizedBox(height: 12),
                ],
                PillButton(
                  label: widget.currentAddress == null
                      ? 'Connect wallet'
                      : 'Save address',
                  loading: _saving,
                  onPressed: _save,
                ),
              ] else
                PillButton(
                  label: 'Sign in',
                  onPressed: () {
                    // The sheet is on the root navigator; take it before
                    // closing the sheet, whose context goes away.
                    final navigator =
                        Navigator.of(context, rootNavigator: true);
                    navigator.pop(false);
                    navigator.push(
                      CupertinoPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
              const SizedBox(height: 8),
              CupertinoButton(
                onPressed:
                    _saving ? null : () => Navigator.of(context).pop(false),
                child: Text('Cancel', style: TextStyle(color: p.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

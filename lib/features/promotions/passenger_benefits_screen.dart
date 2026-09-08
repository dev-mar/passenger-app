import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/device/passenger_device_identity.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../core/utils/money_formatter.dart';
import '../../gen_l10n/app_localizations.dart';
import 'passenger_promotions_repository.dart';

/// Beneficios TEXIAPP: listado, código y referido. Vacío si el motor está apagado.
class PassengerBenefitsScreen extends ConsumerStatefulWidget {
  const PassengerBenefitsScreen({super.key});

  @override
  ConsumerState<PassengerBenefitsScreen> createState() =>
      _PassengerBenefitsScreenState();
}

class _PassengerBenefitsScreenState
    extends ConsumerState<PassengerBenefitsScreen> {
  PassengerPromotionsSnapshot? _snap;
  bool _loading = true;
  bool _busyCode = false;
  bool _busyReferral = false;
  final _codeCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final lang = Localizations.localeOf(context).languageCode;
    final snap = await ref
        .read(passengerPromotionsRepositoryProvider)
        .fetchMine(languageCode: lang);
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _loading = false;
    });
  }

  Future<void> _applyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty || _busyCode) return;
    final l10n = AppLocalizations.of(context)!;
    TexiUiFeedback.lightTap();
    setState(() => _busyCode = true);
    final ok =
        await ref.read(passengerPromotionsRepositoryProvider).applyCode(code);
    if (!mounted) return;
    setState(() => _busyCode = false);
    if (ok) {
      ref.read(passengerPromoCodeProvider.notifier).state = code;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.promoCodeApplied)),
      );
      await _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.promoCodeUnavailable)),
      );
    }
  }

  Future<void> _claimReferral() async {
    final code = _referralCtrl.text.trim();
    if (code.isEmpty || _busyReferral) return;
    final l10n = AppLocalizations.of(context)!;
    TexiUiFeedback.lightTap();
    setState(() => _busyReferral = true);
    String? deviceId;
    try {
      deviceId = await PassengerDeviceIdentity.stableDeviceId();
    } catch (_) {}
    final ok = await ref
        .read(passengerPromotionsRepositoryProvider)
        .claimReferral(code, deviceId: deviceId);
    if (!mounted) return;
    setState(() => _busyReferral = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.promoReferralClaimed)),
      );
      await _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.promoReferralUnavailable)),
      );
    }
  }

  Future<void> _copyMine(String code) async {
    TexiUiFeedback.lightTap();
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.promoReferralMine)),
    );
  }

  Future<void> _shareMine(String code) async {
    TexiUiFeedback.lightTap();
    final l10n = AppLocalizations.of(context)!;
    await SharePlus.instance.share(
      ShareParams(text: l10n.promoReferralShareMessage(code)),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  String _inviteeLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'granted':
        return l10n.promoReferralInviteeGranted;
      case 'rejected':
        return l10n.promoReferralInviteeRejected;
      default:
        return l10n.promoReferralInviteePending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _snap?.items ?? const <PassengerPromotionItem>[];
    final referralCode = _snap?.referralCode;
    final claimed = _snap?.claimedReferral ?? false;
    final graceEnds = _snap?.claimGraceEndsAt;
    final graceClosed = !claimed &&
        referralCode != null &&
        referralCode.trim().isNotEmpty &&
        graceEnds == null;
    final showClaim = !claimed && !graceClosed;
    final wallet = _snap?.wallet;
    final invitees = _snap?.invitees ?? const <PassengerReferralInvitee>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      TexiUiFeedback.lightTap();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/profile');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.primary,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                  Expanded(
                    child: Text(
                      l10n.promoBenefitsTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxx,
                        AppSpacing.xl,
                        AppSpacing.xxx,
                        AppSpacing.sheetBodyV,
                      ),
                      children: [
                        if (items.isEmpty)
                          Text(
                            l10n.promoBenefitsEmpty,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppColors.textSecondary),
                          )
                        else
                          ...items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xl,
                              ),
                              child: _BenefitCard(text: item.rulesText),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.section),
                        Text(
                          l10n.promoCodeLabel,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: l10n.promoCodeHint,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton(
                          onPressed: _busyCode ? null : _applyCode,
                          child: _busyCode
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : Text(l10n.promoCodeApply),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        Text(
                          l10n.promoReferralTitle,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                        if (wallet != null && wallet.balance > 0) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.promoReferralWallet(
                              formatMoney(
                                wallet.balance,
                                currencyCode: 'BOB',
                                decimals: 1,
                              ),
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          if (wallet.expiresAt != null)
                            Text(
                              l10n.promoReferralWalletExpires(
                                _formatDate(wallet.expiresAt!),
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          if (wallet.maxPerTrip != null &&
                              wallet.maxPerTrip! > 0)
                            Text(
                              l10n.promoReferralMaxPerTrip(
                                formatMoney(
                                  wallet.maxPerTrip!,
                                  currencyCode: 'BOB',
                                  decimals: 1,
                                ),
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                        ],
                        if (referralCode != null &&
                            referralCode.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.promoReferralMine,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          InkWell(
                            onTap: () => _copyMine(referralCode),
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            child: Ink(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.lg),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      referralCode,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.2,
                                          ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.copy_rounded,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          OutlinedButton.icon(
                            onPressed: () => _shareMine(referralCode),
                            icon: const Icon(Icons.ios_share_rounded),
                            label: Text(l10n.promoReferralShare),
                          ),
                        ],
                        if (claimed) ...[
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            l10n.promoReferralClaimed,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                        if (graceClosed) ...[
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            l10n.promoReferralGraceClosed,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                        if (showClaim) ...[
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            l10n.promoReferralClaimLabel,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _referralCtrl,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 16,
                            decoration: InputDecoration(
                              hintText: l10n.promoReferralClaimLabel,
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          OutlinedButton(
                            onPressed:
                                _busyReferral ? null : _claimReferral,
                            child: Text(l10n.promoReferralClaim),
                          ),
                        ],
                        if (invitees.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.section),
                          Text(
                            l10n.promoReferralInviteesTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...invitees.map(
                            (row) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: Text(
                                _inviteeLabel(l10n, row.status),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Text(
        text.isEmpty ? '—' : text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
      ),
    );
  }
}

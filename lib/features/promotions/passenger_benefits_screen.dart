import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/device/passenger_device_identity.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../core/ui/app_safe_scrolling.dart';
import '../../core/ui/texi_motion.dart';
import '../../core/utils/money_formatter.dart';
import '../../gen_l10n/app_localizations.dart';
import 'passenger_promotions_repository.dart';
import 'widgets/passenger_benefits_ui.dart';

/// Beneficios TEXIAPP: listado, código y referido. Vacío si el motor está apagado.
class PassengerBenefitsScreen extends ConsumerStatefulWidget {
  const PassengerBenefitsScreen({super.key});

  @override
  ConsumerState<PassengerBenefitsScreen> createState() =>
      _PassengerBenefitsScreenState();
}

class _PassengerBenefitsScreenState
    extends ConsumerState<PassengerBenefitsScreen>
    with TickerProviderStateMixin {
  PassengerPromotionsSnapshot? _snap;
  bool _loading = true;
  bool _busyCode = false;
  bool _busyReferral = false;
  final _codeCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  late final AnimationController _enter;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: TexiMotion.emphasized);
    _pulse = AnimationController(vsync: this, duration: TexiMotion.pulseLoop);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _referralCtrl.dispose();
    _enter.dispose();
    _pulse.dispose();
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
    _enter.forward(from: 0);
    _pulse.repeat(reverse: true);
  }

  Future<void> _applyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty || _busyCode) return;
    final l10n = AppLocalizations.of(context)!;
    TexiUiFeedback.lightTap();
    setState(() => _busyCode = true);
    final ok = await ref
        .read(passengerPromotionsRepositoryProvider)
        .applyCode(code);
    if (!mounted) return;
    setState(() => _busyCode = false);
    if (ok) {
      ref.read(passengerPromoCodeProvider.notifier).state = code;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.promoCodeApplied)));
      await _reload();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.promoCodeUnavailable)));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.promoReferralClaimed)));
      await _reload();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.promoReferralUnavailable)));
    }
  }

  Future<void> _copyMine(String code) async {
    TexiUiFeedback.lightTap();
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.promoReferralCopied)));
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

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Color accent = AppColors.primary,
  }) {
    final radius = BorderRadius.circular(AppRadii.md);
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: accent, size: 20),
      filled: true,
      fillColor: BenefitsVisual.cardHi,
      counterText: '',
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: accent, width: AppBorders.strong),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _snap?.items ?? const <PassengerPromotionItem>[];
    final referralCode = _snap?.referralCode;
    final claimed = _snap?.claimedReferral ?? false;
    final graceEnds = _snap?.claimGraceEndsAt;
    final graceClosed =
        !claimed &&
        referralCode != null &&
        referralCode.trim().isNotEmpty &&
        graceEnds == null;
    final showClaim = !claimed && !graceClosed;
    final wallet = _snap?.wallet;
    final invitees = _snap?.invitees ?? const <PassengerReferralInvitee>[];
    final hasWallet = wallet != null && wallet.balance > 0;
    var stagger = 0;

    return Scaffold(
      backgroundColor: BenefitsVisual.canvas,
      body: Stack(
        children: [
          const BenefitsGlowBackdrop(),
          SafeArea(
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
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                      ),
                      Expanded(
                        child: Text(
                          l10n.promoBenefitsTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
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
                          padding: AppSafeScrolling.pagePadding(
                            context,
                            horizontal: AppSpacing.xxx,
                            top: AppSpacing.xl,
                            bottomExtra: AppSpacing.sheetBodyV,
                          ),
                          children: [
                            BenefitsStagger(
                              animation: _enter,
                              index: stagger++,
                              child: BenefitsHeroCard(
                                pulse: _pulse,
                                lead: l10n.promoBenefitsHeroLead,
                                walletTitle: hasWallet
                                    ? l10n.promoReferralWalletLabel
                                    : null,
                                walletAmount: hasWallet
                                    ? formatMoney(
                                        wallet.balance,
                                        currencyCode: 'BOB',
                                        decimals: 1,
                                      )
                                    : null,
                                walletMeta: [
                                  if (hasWallet && wallet.expiresAt != null)
                                    l10n.promoReferralWalletExpires(
                                      _formatDate(wallet.expiresAt!),
                                    ),
                                  if (hasWallet &&
                                      wallet.maxPerTrip != null &&
                                      wallet.maxPerTrip! > 0)
                                    l10n.promoReferralMaxPerTrip(
                                      formatMoney(
                                        wallet.maxPerTrip!,
                                        currencyCode: 'BOB',
                                        decimals: 1,
                                      ),
                                    ),
                                ],
                                emptyMessage: items.isEmpty
                                    ? l10n.promoBenefitsEmpty
                                    : null,
                                activeTitle: items.isNotEmpty
                                    ? l10n.promoBenefitsActiveTitle
                                    : null,
                                activeCount: items.isNotEmpty
                                    ? items.length
                                    : null,
                              ),
                            ),
                            if (items.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xl),
                              ...items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xl,
                                  ),
                                  child: BenefitsStagger(
                                    animation: _enter,
                                    index: stagger++,
                                    child: BenefitsRuleCard(
                                      text: item.rulesText,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.section),
                            BenefitsStagger(
                              animation: _enter,
                              index: stagger++,
                              child: BenefitsPanel(
                                icon: Icons.confirmation_number_outlined,
                                accent: AppColors.primary,
                                title: l10n.promoCodeLabel,
                                subtitle: l10n.promoCodeCardLead,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _codeCtrl,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      decoration: _fieldDecoration(
                                        hint: l10n.promoCodeHint,
                                        icon: Icons.vpn_key_rounded,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    BenefitsPrimaryButton(
                                      label: l10n.promoCodeApply,
                                      busy: _busyCode,
                                      onPressed: _applyCode,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.section),
                            BenefitsStagger(
                              animation: _enter,
                              index: stagger++,
                              child: BenefitsPanel(
                                icon: Icons.handshake_outlined,
                                accent: BenefitsVisual.teal,
                                title: l10n.promoReferralTitle,
                                subtitle: l10n.promoReferralCardLead,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (referralCode != null &&
                                        referralCode.trim().isNotEmpty) ...[
                                      Text(
                                        l10n.promoReferralMine,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      BenefitsTicketCode(
                                        code: referralCode,
                                        onCopy: () => _copyMine(referralCode),
                                      ),
                                      const SizedBox(height: AppSpacing.xl),
                                      BenefitsGhostButton(
                                        icon: Icons.ios_share_rounded,
                                        label: l10n.promoReferralShare,
                                        onPressed: () =>
                                            _shareMine(referralCode),
                                      ),
                                    ],
                                    if (claimed) ...[
                                      const SizedBox(height: AppSpacing.xl),
                                      BenefitsStatusNote(
                                        icon: Icons.verified_rounded,
                                        color: BenefitsVisual.teal,
                                        text: l10n.promoReferralClaimed,
                                      ),
                                    ],
                                    if (graceClosed) ...[
                                      const SizedBox(height: AppSpacing.xl),
                                      BenefitsStatusNote(
                                        icon: Icons.schedule_rounded,
                                        color: AppColors.textSecondary,
                                        text: l10n.promoReferralGraceClosed,
                                      ),
                                    ],
                                    if (showClaim) ...[
                                      const SizedBox(height: AppSpacing.xl),
                                      Text(
                                        l10n.promoReferralClaimLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      TextField(
                                        controller: _referralCtrl,
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        maxLength: 16,
                                        decoration: _fieldDecoration(
                                          hint: l10n.promoReferralClaimLabel,
                                          icon: Icons.person_add_alt_1_rounded,
                                          accent: BenefitsVisual.violet,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xl),
                                      BenefitsGhostButton(
                                        icon: Icons.add_link_rounded,
                                        label: l10n.promoReferralClaim,
                                        busy: _busyReferral,
                                        onPressed: _claimReferral,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (invitees.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.section),
                              BenefitsStagger(
                                animation: _enter,
                                index: stagger++,
                                child: BenefitsPanel(
                                  icon: Icons.groups_rounded,
                                  accent: BenefitsVisual.sky,
                                  title: l10n.promoReferralInviteesTitle,
                                  child: Column(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < invitees.length;
                                        i++
                                      ) ...[
                                        if (i > 0)
                                          const SizedBox(height: AppSpacing.sm),
                                        BenefitsInviteeRow(
                                          label: _inviteeLabel(
                                            l10n,
                                            invitees[i].status,
                                          ),
                                          status: invitees[i].status,
                                        ),
                                      ],
                                    ],
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
        ],
      ),
    );
  }
}

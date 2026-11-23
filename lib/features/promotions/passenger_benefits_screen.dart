import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/device/passenger_device_identity.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../core/ui/app_safe_scrolling.dart';
import '../../core/ui/texi_motion.dart';
import '../../core/utils/money_formatter.dart';
import '../../gen_l10n/app_localizations.dart';
import '../home/widgets/passenger_home_look.dart';
import 'passenger_promotions_repository.dart';
import 'widgets/passenger_benefits_icons.dart';
import 'widgets/passenger_benefits_ui.dart';

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
      ShareParams(
        text: l10n.promoReferralShareMessage(code, AppConfig.playStoreUrl),
        subject: AppConfig.appName,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  String _money(double value) {
    return formatMoney(value, currencyCode: 'BOB', decimals: 1);
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

  String _statusLabel(AppLocalizations l10n, PassengerPromotionItem item) {
    if (item.isUsed) return l10n.promoBenefitUsed;
    if (item.isEligible) return l10n.promoBenefitReady;
    return l10n.promoBenefitUnavailable;
  }

  BenefitsIconKind _kindFor(PassengerPromotionItem item) {
    if (item.isUsed) return BenefitsIconKind.check;
    switch (item.audience) {
      case 'new_registrations':
        return BenefitsIconKind.gift;
      case 'assigned':
        return BenefitsIconKind.ticket;
      default:
        return BenefitsIconKind.spark;
    }
  }

  String _titleFor(AppLocalizations l10n, PassengerPromotionItem item) {
    final title = item.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    if (item.audience == 'new_registrations') {
      return l10n.promoBenefitsGrantedTitle;
    }
    return item.rulesText.trim().isNotEmpty
        ? item.rulesText
        : l10n.promoBenefitsGrantedTitle;
  }

  List<String> _chipsFor(AppLocalizations l10n, PassengerPromotionItem item) {
    final chips = <String>[];
    if (item.minFare != null && item.minFare! > 0) {
      chips.add(l10n.promoBenefitMinFare(_money(item.minFare!)));
    }
    if (item.validDays != null && item.validDays! > 0) {
      chips.add(l10n.promoBenefitValidDays('${item.validDays}'));
    }
    if (item.endsAt != null) {
      chips.add(l10n.promoBenefitEnds(_formatDate(item.endsAt!)));
    } else {
      chips.add(l10n.promoBenefitNoEnd);
    }
    return chips;
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Color accent = PassengerHomeLook.sky,
  }) {
    final radius = BorderRadius.circular(AppRadii.md);
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: PassengerHomeLook.muted),
      prefixIcon: Icon(icon, color: accent, size: 20),
      filled: true,
      fillColor: PassengerHomeLook.cardLift,
      counterText: '',
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: PassengerHomeLook.hairline),
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
    final totals = _snap?.totals ?? const PassengerReferralTotals();
    final hasWallet = wallet != null && wallet.balance > 0;
    final readyCount = items.where((e) => e.isEligible).length;
    final showReferralTotals =
        totals.invitedCount > 0 ||
        totals.creditedAmount > 0 ||
        invitees.isNotEmpty;
    var stagger = 0;

    return Scaffold(
      backgroundColor: PassengerHomeLook.canvas,
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
                        color: PassengerHomeLook.ink,
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
                                color: PassengerHomeLook.ink,
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
                              color: PassengerHomeLook.sky,
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
                                    ? _money(wallet.balance)
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
                                      _money(wallet.maxPerTrip!),
                                    ),
                                ],
                                emptyMessage: items.isEmpty
                                    ? l10n.promoBenefitsEmpty
                                    : null,
                                activeTitle: items.isNotEmpty
                                    ? l10n.promoBenefitsActiveTitle
                                    : null,
                                activeCount: items.isNotEmpty
                                    ? readyCount
                                    : null,
                              ),
                            ),
                            if (items.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.section),
                              BenefitsStagger(
                                animation: _enter,
                                index: stagger++,
                                child: Text(
                                  l10n.promoBenefitsGrantedTitle,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: PassengerHomeLook.ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              ...items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xl,
                                  ),
                                  child: BenefitsStagger(
                                    animation: _enter,
                                    index: stagger++,
                                    child: BenefitsGrantCard(
                                      title: _titleFor(l10n, item),
                                      statusLabel: _statusLabel(l10n, item),
                                      used: item.isUsed,
                                      ready: item.isEligible,
                                      kind: _kindFor(item),
                                      amountLabel: item.discountAmount != null
                                          ? l10n.promoBenefitAmount(
                                              _money(item.discountAmount!),
                                            )
                                          : null,
                                      chips: _chipsFor(l10n, item),
                                      rulesText: item.rulesText,
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
                                accent: PassengerHomeLook.sky,
                                title: l10n.promoCodeLabel,
                                subtitle: l10n.promoCodeCardLead,
                                leading: const BenefitsCanvasOrb(
                                  kind: BenefitsIconKind.ticket,
                                  accent: PassengerHomeLook.sky,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _codeCtrl,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      style: const TextStyle(
                                        color: PassengerHomeLook.ink,
                                      ),
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
                                accent: PassengerHomeLook.teal,
                                title: l10n.promoReferralTitle,
                                subtitle: l10n.promoReferralCardLead,
                                leading: const BenefitsCanvasOrb(
                                  kind: BenefitsIconKind.people,
                                  accent: PassengerHomeLook.teal,
                                ),
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
                                              color: PassengerHomeLook.muted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      BenefitsTicketCode(
                                        code: referralCode,
                                        onCopy: () => _copyMine(referralCode),
                                        onShare: () => _shareMine(referralCode),
                                        copyTooltip: l10n.promoReferralCopy,
                                        shareTooltip: l10n.promoReferralShare,
                                      ),
                                    ],
                                    if (claimed) ...[
                                      const SizedBox(height: AppSpacing.xl),
                                      BenefitsStatusNote(
                                        icon: Icons.verified_rounded,
                                        color: PassengerHomeLook.teal,
                                        text: l10n.promoReferralClaimed,
                                      ),
                                    ],
                                    if (graceClosed) ...[
                                      const SizedBox(height: AppSpacing.xl),
                                      BenefitsStatusNote(
                                        icon: Icons.schedule_rounded,
                                        color: PassengerHomeLook.muted,
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
                                              color: PassengerHomeLook.muted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      TextField(
                                        controller: _referralCtrl,
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        maxLength: 16,
                                        style: const TextStyle(
                                          color: PassengerHomeLook.ink,
                                        ),
                                        decoration: _fieldDecoration(
                                          hint: l10n.promoReferralClaimLabel,
                                          icon: Icons.person_add_alt_1_rounded,
                                          accent: PassengerHomeLook.violet,
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
                            if (showReferralTotals) ...[
                              const SizedBox(height: AppSpacing.section),
                              BenefitsStagger(
                                animation: _enter,
                                index: stagger++,
                                child: BenefitsPanel(
                                  icon: Icons.groups_rounded,
                                  accent: PassengerHomeLook.violet,
                                  title: l10n.promoReferralTotalsTitle,
                                  leading: const BenefitsCanvasOrb(
                                    kind: BenefitsIconKind.people,
                                    accent: PassengerHomeLook.violet,
                                  ),
                                  child: BenefitsTotalsGrid(
                                    tiles: [
                                      BenefitsTotalTile(
                                        label: l10n.promoReferralTotalInvited,
                                        value: '${totals.invitedCount}',
                                        kind: BenefitsIconKind.people,
                                        accent: PassengerHomeLook.sky,
                                      ),
                                      BenefitsTotalTile(
                                        label: l10n.promoReferralTotalQualified,
                                        value: '${totals.qualifiedCount}',
                                        kind: BenefitsIconKind.check,
                                        accent: PassengerHomeLook.teal,
                                      ),
                                      BenefitsTotalTile(
                                        label: l10n.promoReferralTotalPending,
                                        value: '${totals.pendingCount}',
                                        kind: BenefitsIconKind.clock,
                                        accent: PassengerHomeLook.violet,
                                      ),
                                      BenefitsTotalTile(
                                        label: l10n.promoReferralTotalCredited,
                                        value: _money(totals.creditedAmount),
                                        kind: BenefitsIconKind.wallet,
                                        accent: PassengerHomeLook.teal,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (invitees.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xl),
                              BenefitsStagger(
                                animation: _enter,
                                index: stagger++,
                                child: BenefitsPanel(
                                  icon: Icons.groups_rounded,
                                  accent: PassengerHomeLook.sky,
                                  title: l10n.promoReferralInviteesTitle,
                                  leading: const BenefitsCanvasOrb(
                                    kind: BenefitsIconKind.clock,
                                    accent: PassengerHomeLook.sky,
                                  ),
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

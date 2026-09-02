import '../../gen_l10n/app_localizations.dart';

String localizedSupportCategory(AppLocalizations l10n, String category) {
  switch (category.trim().toLowerCase()) {
    case 'trip':
      return l10n.profileSupportCategoryTrip;
    case 'payment':
      return l10n.profileSupportCategoryPayment;
    case 'account':
      return l10n.profileSupportCategoryAccount;
    case 'safety':
      return l10n.profileSupportCategorySafety;
    case 'technical':
      return l10n.profileSupportCategoryTechnical;
    default:
      return l10n.profileSupportCategoryGeneral;
  }
}

String localizedSupportStatus(AppLocalizations l10n, String status) {
  switch (status.trim().toLowerCase()) {
    case 'closed':
      return l10n.profileSupportStatusClosed;
    case 'pending':
    case 'in_progress':
    case 'in-progress':
      return l10n.profileSupportStatusPending;
    case 'resolved':
      return l10n.profileSupportStatusResolved;
    default:
      return l10n.profileSupportStatusOpen;
  }
}

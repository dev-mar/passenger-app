// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Texi';

  @override
  String get splashGettingLocation => 'Getting your location...';

  @override
  String get loginWelcome => 'Welcome';

  @override
  String get loginSubtitle => 'Enter your number to continue';

  @override
  String get loginCode => 'Code';

  @override
  String get loginPhone => 'Phone';

  @override
  String get loginCountryCodeHint => '+591';

  @override
  String get loginPhoneHint => '7 123 4567';

  @override
  String get loginContinue => 'Continue';

  @override
  String get loginErrorInvalidCredentials =>
      'Could not sign in. Check your number.';

  @override
  String get loginErrorPhoneRegisteredAsDriver =>
      'This number is already registered as a driver. Use another number for the passenger app, or sign in with the driver app using this same number.';

  @override
  String get loginErrorPhoneOtherAccountType =>
      'This number is already linked to another type of Texi account. Use another number or the app that matches that account.';

  @override
  String get loginErrorPhoneDuplicatePassenger =>
      'We could not start passenger registration with this number. If you already use it as a driver, use the driver app or another number here.';

  @override
  String get serviceTypeNameStandard => 'Standard';

  @override
  String get loginPhoneRequired => 'Enter your phone number';

  @override
  String get homeRequestRide => 'Request ride';

  @override
  String get homeProfileQuickAccess => 'My profile';

  @override
  String get homeProfileQuickAccessSubtitle =>
      'Account details and profile photo';

  @override
  String homeNearbyDrivers(int count) {
    return '$count nearby driver';
  }

  @override
  String get homeNearbyDriversNone => 'No nearby drivers at the moment';

  @override
  String homeUpdatesEvery(int seconds) {
    return 'Updates every $seconds seconds';
  }

  @override
  String get homeLocationError =>
      'Enable location to see the map and nearby drivers.';

  @override
  String get homeLocationErrorGps => 'Could not get your location. Check GPS.';

  @override
  String get homeRetry => 'Retry';

  @override
  String get tripOrigin => 'Origin';

  @override
  String get tripDestination => 'Destination';

  @override
  String get tripYourLocation => 'Your current location';

  @override
  String get tripWherePickup => 'Where should we pick you up?';

  @override
  String get tripUseMyLocation => 'Use my current location';

  @override
  String get tripSearchAddress => 'Search address';

  @override
  String get tripChooseOnMap => 'Choose on map';

  @override
  String get tripUseAsPickup => 'Use as pickup point';

  @override
  String get tripUseAsDestination => 'Use as destination';

  @override
  String get tripMoveMapSetPickup =>
      'Move the map and tap the button to set where you\'ll be picked up.';

  @override
  String get tripMoveMapSetDestination =>
      'Move the map and tap the button to set the destination.';

  @override
  String get tripTapMapDestination => 'Tap the map or choose an option below';

  @override
  String get tripSeePrices => 'See prices';

  @override
  String get tripCancelQuoteDraft => 'Cancel and start over';

  @override
  String get tripSearchPlaceholder => 'Search address...';

  @override
  String get tripUseMapCenter => 'Use this location';

  @override
  String get tripWhereTo => 'Where to?';

  @override
  String get tripSearchError => 'Address not found';

  @override
  String get tripSearchingAddress => 'Searching...';

  @override
  String get tripNoCoverageInZone =>
      'We don\'t have service coverage in this area at the moment. Try another location or move to a service zone.';

  @override
  String get tripNoDriversAvailable =>
      'No drivers available at the moment. Please try again in a few moments.';

  @override
  String get tripNext => 'Next';

  @override
  String get quoteTitle => 'Choose your ride';

  @override
  String get quoteSubtitle => 'Select a service type';

  @override
  String get quotePerTrip => 'per trip';

  @override
  String get quoteConfirm => 'Confirm';

  @override
  String get confirmTitle => 'Confirm your ride';

  @override
  String get confirmFrom => 'From';

  @override
  String get confirmTo => 'To';

  @override
  String get confirmRequestRide => 'Request ride';

  @override
  String get searchingTitle => 'Looking for a driver';

  @override
  String get searchingSubtitle => 'We are finding the best option for you';

  @override
  String get tripConnectionError =>
      'Could not connect to receive trip updates. Check your connection.';

  @override
  String get tripRbacForbidden =>
      'Your account doesn’t have permission for this trip action. If it keeps happening, sign out and sign back in or contact support.';

  @override
  String get tripRbacSession =>
      'We couldn’t validate your session. Sign out and sign in again.';

  @override
  String get tripRbacTechnical =>
      'We couldn’t verify permissions. Please try again in a few seconds.';

  @override
  String get tripRealtimeNoToken =>
      'Your session is invalid or expired. Sign in again to follow the trip.';

  @override
  String get tripRateDriver => 'Rate your driver';

  @override
  String get tripRateDriverSubtitle =>
      'Your feedback helps us improve the service.';

  @override
  String get tripSendRating => 'Submit rating';

  @override
  String get tripSkipRating => 'Skip';

  @override
  String get tripStatusEstimatedTime => 'Approx. time';

  @override
  String get tripStatusCost => 'Estimated cost';

  @override
  String get tripStatusFrom => 'Pickup';

  @override
  String get tripStatusTo => 'Destination';

  @override
  String tripStatusMinutes(int count) {
    return '$count min';
  }

  @override
  String tripStatusKm(String value) {
    return '$value km';
  }

  @override
  String get tripStatusDriver => 'Driver';

  @override
  String get tripStatusVehicle => 'Vehicle';

  @override
  String get tripStatusDragHint => 'Drag to see trip details';

  @override
  String get tripStatusLabelEnRoute => 'Driver on the way';

  @override
  String get tripStatusLabelArrived => 'Driver has arrived';

  @override
  String get tripStatusLabelStarted => 'Trip in progress';

  @override
  String get tripStatusLabelCompleted => 'Trip completed';

  @override
  String get tripStatusLabelDefault => 'On the way';

  @override
  String get tripStatusDriverAssigned => 'Driver assigned';

  @override
  String get tripDriverNameFallback => 'TEXI driver';

  @override
  String get tripMapRecenterShort => 'Recenter';

  @override
  String get tripRequireGpsForRequest =>
      'We need your real location (GPS on and permission granted) to request a ride. Check GPS and location permissions.';

  @override
  String get tripConfirmOriginFirst =>
      'Please confirm your pickup point first.';

  @override
  String get tripConfirmOrigin => 'Confirm origin';

  @override
  String get tripConfirmDestination => 'Confirm destination';

  @override
  String get tripLogout => 'Log out';

  @override
  String get profileSetupTitle => 'Complete your profile';

  @override
  String profileSetupSubtitle(String phone) {
    return 'To finish registering with $phone, enter your name. Photo is optional.';
  }

  @override
  String get profileSetupPhotoSoon => 'Photo selection coming soon.';

  @override
  String get profileSetupNameLabel => 'Your name';

  @override
  String get profileSetupNameHint => 'e.g. Juan Perez';

  @override
  String get profileSetupNameRequired => 'Name is required';

  @override
  String get profileSetupNameTooShort => 'Enter at least 2 characters';

  @override
  String get profileSetupContinue => 'Continue';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get tripRecoverySnackbarTitle => 'Request restored';

  @override
  String get tripRecoverySnackbarBody => 'We resumed your current trip.';

  @override
  String get tripRecoverySnackbarAction => 'OK';

  @override
  String get tripRecoveringStateTitle => 'Restoring your trip…';

  @override
  String get verifyCodeTitle => 'Verify your number';

  @override
  String verifyCodeSubtitle(String phone) {
    return 'We sent a 4-digit SMS code to $phone. Enter it to continue.';
  }

  @override
  String get verifyCodeFieldLabel => '4-digit verification code';

  @override
  String get verifyCodeMaskHint => '••••';

  @override
  String get verifyCodeConfirm => 'Confirm code';

  @override
  String get verifyCodeRetryHint =>
      'If you did not receive the SMS, check the number and try again in a few minutes.';

  @override
  String get profilePhotoTooLarge =>
      'The photo is too large. Choose another one or take a lower-resolution photo.';

  @override
  String get profilePhotoPickFailed =>
      'Could not select the photo. Please try again.';

  @override
  String get profilePhotoTake => 'Take photo';

  @override
  String get profilePhotoGallery => 'Choose from gallery';

  @override
  String get profileReviewInfoTitle => 'Review your information';

  @override
  String get profileAcknowledge => 'Got it';

  @override
  String get homeTooltipLanguage => 'Change language';

  @override
  String get homeTooltipProfile => 'Open profile';

  @override
  String get homeLocationMissingTitle => 'We could not detect your location';

  @override
  String get homeMapMe => 'Your position';

  @override
  String homeMapDriverTitle(String id) {
    return 'Driver $id';
  }

  @override
  String get profileFieldPhone => 'Phone';

  @override
  String get profileFieldFullName => 'Name';

  @override
  String get profileSectionBasics => 'Account';

  @override
  String get profilePhotoFromServer => 'Profile photo (server)';

  @override
  String get profileNoServerPhoto =>
      'No profile photo on file. You can add one when editing your profile.';

  @override
  String get profileErrorNoSession => 'Session expired. Sign in again.';

  @override
  String get profileErrorForbidden =>
      'This action needs a passenger session. Sign out and sign in again with your phone number.';

  @override
  String get profileErrorNotFound =>
      'We could not find your passenger profile. If this continues, contact support.';

  @override
  String get profileTaglinePassenger => 'Texi passenger';

  @override
  String get profileAccountLabel => 'Account';

  @override
  String get profileScreenTitle => 'My profile';

  @override
  String get profileStateLoaded => 'State: loaded';

  @override
  String get profileStateLoading => 'State: loading';

  @override
  String get profileStateEmpty => 'State: empty';

  @override
  String get profileStateError => 'State: error';

  @override
  String get profileStateOffline => 'State: offline';

  @override
  String get profileEmptyTitle => 'Complete your profile';

  @override
  String get profileEmptyBody =>
      'We could not find profile data yet. You can create it in a few steps.';

  @override
  String get profileCompleteNow => 'Complete now';

  @override
  String get profileErrorTitle => 'We could not load your profile';

  @override
  String get profileErrorBody =>
      'A temporary issue occurred. Please try again.';

  @override
  String get profileOfflineTitle => 'Offline';

  @override
  String get profileOfflineBody =>
      'Check your network to sync your profile information.';

  @override
  String get profileRefresh => 'Refresh';

  @override
  String get profileSavedPlaces => 'Saved places';

  @override
  String get profileRecentPlaces => 'Recent';

  @override
  String get placeHome => 'Home';

  @override
  String get placeOffice => 'Office';

  @override
  String get placeFavorite => 'Favorite';

  @override
  String get placeMainSquare => 'Main Square';

  @override
  String get placeDowntown => 'Downtown';

  @override
  String get placeAirport => 'Airport';

  @override
  String get placeNorthZone => 'North zone';

  @override
  String get quickGps => 'GPS';

  @override
  String get quickSearch => 'Search';

  @override
  String get quickMap => 'Map';

  @override
  String get tripMissingDataTitle => 'Missing trip data';

  @override
  String get loginReviewDataTitle => 'Review your details';

  @override
  String get loginContinueA11y => 'Continue to access';

  @override
  String get profileRefreshTooltip => 'Refresh';

  @override
  String get profileStatesPreviewTooltip => 'States preview';

  @override
  String get profileAvatarSemantics => 'Passenger avatar';

  @override
  String get profileMockInitials => 'JP';

  @override
  String get profileMockName => 'Juan Perez';

  @override
  String get profileMockPhone => '+591 71234567';

  @override
  String get profileVerifiedBadge => 'Verified account';

  @override
  String get profileStatTrips => 'Trips';

  @override
  String get profileStatRating => 'Rate';

  @override
  String get profileStatSavings => 'Savings';

  @override
  String get profileStatTripsValue => '126';

  @override
  String get profileStatRatingValue => '4.9';

  @override
  String get profileStatSavingsValue => 'Bs 340';

  @override
  String get profileSectionPersonalData => 'Personal data';

  @override
  String get profileFieldEmail => 'Email';

  @override
  String get profileFieldDocument => 'Document';

  @override
  String get profileFieldAddress => 'Address';

  @override
  String get profileMockEmail => 'juan@email.com';

  @override
  String get profileMockDocument => '1234567 LP';

  @override
  String get profileMockAddress => 'South Zone, La Paz';

  @override
  String get profileSectionPreferences => 'Preferences';

  @override
  String get profileFieldNotifications => 'Notifications';

  @override
  String get profileFieldNotificationsDesc => 'Trip alerts and promotions';

  @override
  String get profileFieldDarkMode => 'Dark mode';

  @override
  String get profileFieldDarkModeDesc => 'Premium visual tuning';

  @override
  String get profileSectionSecurity => 'Security';

  @override
  String get profileFieldBiometrics => 'Biometrics';

  @override
  String get profileFieldLastAccess => 'Last access';

  @override
  String get profileMockBiometricsValue => 'Enabled';

  @override
  String get profileMockLastAccessValue => 'Today, 09:14';

  @override
  String get profileActionEditInfo => 'Edit information';

  @override
  String get profileActionSupport => 'Support and help';

  @override
  String get commonEnabled => 'enabled';

  @override
  String get commonDisabled => 'disabled';

  @override
  String homeDriverDistanceKm(String km) {
    return '$km km';
  }
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'TEXIAPP';

  @override
  String get splashGettingLocation => 'Getting your location...';

  @override
  String get loginWelcome => 'Welcome';

  @override
  String get loginSubtitle =>
      'Enter your number to sign in or create your account.';

  @override
  String get loginMethodChoiceTitle => 'Your ride starts here';

  @override
  String get loginMethodChoiceSubtitle =>
      'Choose how you want to sign in. Fast, secure, and simple.';

  @override
  String get loginMethodPhoneTitle => 'Mobile number';

  @override
  String get loginMethodPhoneSubtitle => 'We verify your identity via WhatsApp';

  @override
  String get loginMethodGoogleTitle => 'Continue with Google';

  @override
  String get loginMethodGoogleSubtitle => 'Sign in with your Gmail account';

  @override
  String get loginMethodGoogleBadge => 'Coming soon';

  @override
  String get loginGoogleComingSoon => 'Google sign-in will be available soon.';

  @override
  String get loginBackToMethods => 'Back to sign-in options';

  @override
  String get loginPhoneStepTitle => 'What\'s your number?';

  @override
  String get loginPhoneStepSubtitle =>
      'Enter your number. Then confirm you\'re human and choose how to verify.';

  @override
  String get loginCaptchaTitle => 'Confirm you\'re human';

  @override
  String get loginCaptchaSubtitle =>
      'A quick security step before continuing. Only once this session.';

  @override
  String get loginGoogleCaptchaTitle => 'Verify your Google sign-in';

  @override
  String get loginGoogleCaptchaSubtitle =>
      'Complete the captcha to protect your account and continue with Google.';

  @override
  String get loginCaptchaLoading => 'Loading verification…';

  @override
  String get loginCaptchaInteractiveHint =>
      'Check the security box to continue.';

  @override
  String get loginCaptchaReady => 'Verification complete.';

  @override
  String get loginCaptchaLoadFailed =>
      'We couldn\'t load the captcha. Check your connection.';

  @override
  String get loginCaptchaReadyHint =>
      'You\'re good to go. Continue to the next step.';

  @override
  String get loginCaptchaDevPlaceholder =>
      'Cloudflare Turnstile appears here in production. Set TURNSTILE_SITE_KEY in the APK build.';

  @override
  String get loginVerifyMethodTitle => 'How do you want to verify?';

  @override
  String loginVerifyMethodSubtitle(String phoneMasked) {
    return 'Pick the most convenient option to confirm $phoneMasked.';
  }

  @override
  String get loginVerifyMethodRecommendedBadge => 'Recommended';

  @override
  String get loginVerifyMethodWaInboundTitle => 'Send secure key from WhatsApp';

  @override
  String get loginVerifyMethodWaInboundSubtitle =>
      'Fast and secure. We open WhatsApp with the message ready to send.';

  @override
  String get loginVerifyMethodOrDivider => 'or';

  @override
  String get loginVerifyMethodCodeTitle => 'Receive verification code';

  @override
  String get loginVerifyMethodCodeSubtitle =>
      'We send a 6-digit code via WhatsApp for you to enter in the app.';

  @override
  String get loginVerifyMethodCodeComingSoon =>
      'Receive code will be available soon.';

  @override
  String get loginVerifyMethodLoadingWa => 'Preparing verification…';

  @override
  String loginPhoneStepSubtitleGoogle(String email) {
    return 'Google verified ($email). Now confirm your number via WhatsApp.';
  }

  @override
  String get loginGoogleError =>
      'Could not sign in with Google. Please try again.';

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
  String get loginErrorOtpRateLimit =>
      'Too many attempts. Wait a few minutes and try again.';

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
  String get loginErrorVerificationServiceUnavailable =>
      'Verification service unavailable. Please try again later.';

  @override
  String get loginErrorWhatsAppVerificationUnavailable =>
      'WhatsApp verification is not available. Contact support or try again later.';

  @override
  String get loginErrorSessionSuperseded =>
      'Your session was opened on another device.';

  @override
  String get loginErrorTripOperationalLock =>
      'Finish or cancel your current trip before signing in on another device.';

  @override
  String get serviceTypeNameStandard => 'Standard';

  @override
  String get serviceTypeNameTwoWheels => 'Moto';

  @override
  String get serviceTypeNameComfort => 'Comfort';

  @override
  String get serviceTypeNamePremium => 'Premium';

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
  String get tripCancelQuoteDraft => 'Cancel request';

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
  String get tripDraftSearchHint => 'Search street, area or place';

  @override
  String get tripDraftNoRecentPlaces => 'No recent places yet for this stop';

  @override
  String get tripDraftQuoting => 'Getting prices…';

  @override
  String get tripDraftCloseMapPicker => 'Close and search or adjust on the map';

  @override
  String get tripDraftCalculatingRoute => 'Calculating the route on the map…';

  @override
  String get tripDraftEditStop => 'Edit';

  @override
  String get tripSecureChat => 'Secure chat';

  @override
  String get tripShareRide => 'Share trip';

  @override
  String tripShareMessage(String url, String driverName, String plate) {
    return 'Hi! I\'m on my way with TEXIAPP. Track my trip live here: $url\n\nDriver: $driverName | Vehicle: ($plate)';
  }

  @override
  String get tripShareError =>
      'Couldn\'t create the tracking link. Please try again.';

  @override
  String get passengerTripChatTitle => 'Trip chat';

  @override
  String get passengerTripChatSubtitle => 'Live conversation with your driver.';

  @override
  String get passengerTripChatOnline => 'Online';

  @override
  String get passengerTripChatOffline => 'Offline';

  @override
  String get passengerTripChatTemplateCantFindVehicle =>
      'I can\'t see your vehicle';

  @override
  String get passengerTripChatTemplateWhereAreYou => 'Where are you exactly?';

  @override
  String get passengerTripChatTemplateWaitingHere => 'I\'m waiting here';

  @override
  String get passengerTripChatNow => 'Now';

  @override
  String get passengerTripChatErrorStorage =>
      'Chat unavailable. Contact support.';

  @override
  String get passengerTripChatErrorPhase =>
      'Chat isn\'t available at this trip stage.';

  @override
  String get passengerTripChatErrorNotReady =>
      'Chat isn\'t ready yet. Try again in a few seconds.';

  @override
  String passengerTripChatErrorSendReceive(String code) {
    return 'Couldn\'t send the message ($code). Check your connection.';
  }

  @override
  String get passengerTripChatEmptyState =>
      'No messages yet.\nSend one to start the conversation.';

  @override
  String get passengerTripChatMessageHint => 'Write a message';

  @override
  String get passengerTripChatSenderYou => 'You';

  @override
  String get passengerTripChatSenderDriver => 'Driver';

  @override
  String get passengerTripChatDriverTemplateAtPickup =>
      'I arrived at the pickup point';

  @override
  String get passengerTripChatDriverTemplateCannotFind =>
      'I can\'t find you at the pickup point';

  @override
  String get passengerTripChatDriverTemplateConfirmLocation =>
      'Please confirm your exact location';

  @override
  String get commonEmptyDash => '—';

  @override
  String get tripNoCoverageInZone =>
      'We don\'t have service coverage in this area at the moment. Try another location or move to a service zone.';

  @override
  String get tripNoDriversAvailable =>
      'We couldn\'t find drivers nearby right now. Please try again in a few minutes.';

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
  String confirmRequestRideWithService(String serviceName) {
    return 'Request $serviceName';
  }

  @override
  String get searchingTitle => 'Looking for a driver';

  @override
  String get searchingSubtitle => 'Connecting with the closest drivers.';

  @override
  String get tripSearchingStage2Title => 'Widening the search…';

  @override
  String get tripSearchingStage2Body =>
      'There\'s some traffic nearby, but we\'re still finding the best option for you.';

  @override
  String get tripSearchingStage3Title => 'Keep searching?';

  @override
  String get tripSearchingStage3Body =>
      'Demand is high in your area, but your request is still active.';

  @override
  String get tripSearchingCancelRequest => 'Cancel request';

  @override
  String get tripSearchingContinueCta => 'Continue';

  @override
  String get tripSearchingEtaHint => 'Estimated match: 1–3 min';

  @override
  String get tripSearchingRotateCheck2km => 'Checking drivers within 2 km…';

  @override
  String get tripSearchingRotateAvailability => 'Checking availability…';

  @override
  String get tripSearchingRotateOptimizeRoute => 'Optimizing your route…';

  @override
  String get tripSearchingOfflineBanner => 'No internet connection. Retrying…';

  @override
  String get tripSearchingLocationBanner =>
      'Turn on location to improve matching.';

  @override
  String get tripSearchingPatienceHint =>
      'There\'s some traffic nearby, but we\'re still finding the best option for you.';

  @override
  String get tripSearchingLongWaitTitle => 'Keep searching?';

  @override
  String get tripSearchingLongWaitBody =>
      'Demand is high in your area, but your request is still active.';

  @override
  String get tripSearchingKeepWaitingCta => 'Continue';

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
  String get tripRatingSheetHeaderTitle => 'Trip completed';

  @override
  String get tripRatingYourRating => 'Your rating';

  @override
  String get tripRatingFeedbackPromptLow =>
      'What affected your experience? (multiple)';

  @override
  String get tripRatingFeedbackPromptHigh =>
      'What stood out about the service? (multiple)';

  @override
  String get tripFinishedBackToHome => 'Back to home';

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
  String get tripSavedPlaceFallbackLabel => 'Place';

  @override
  String tripSavedPlacesMax(int count) {
    return 'Maximum $count places.';
  }

  @override
  String get tripSavedPlaceDialogTitle => 'New saved place';

  @override
  String get tripSavedPlaceNameLabel => 'Name';

  @override
  String get tripSavedPlaceNameHint => 'E.g.: Home, Work';

  @override
  String get tripSavedPlaceSaveCta => 'Save';

  @override
  String get tripSavedPlaceSaved => 'Place saved';

  @override
  String tripSavedPlacesLimitReached(int count) {
    return '$count places limit reached.';
  }

  @override
  String get tripSavedPlaceSaveMapCta => 'Save location on map';

  @override
  String get tripSavedPlaceDeleteCta => 'Delete';

  @override
  String get tripMapAdjustPickupHint =>
      'Adjust the map to set your pickup point';

  @override
  String get tripMapAdjustDestinationHint =>
      'Adjust the map to set your destination';

  @override
  String get tripMapPinHintOriginShort => 'Pickup — move map, then confirm';

  @override
  String get tripMapPinHintDestShort => 'Destination — move map, then confirm';

  @override
  String get tripMapPinSearchInstead => 'Search';

  @override
  String get tripDraftSaveOriginShortcut => 'Save pickup to favorites';

  @override
  String get tripDraftSaveDestinationShortcut =>
      'Save destination to favorites';

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
  String get menuLeaveAppTitle => 'Are you sure you want to leave?';

  @override
  String get menuLeaveAppMessage =>
      'Your verification will stay active when you return.';

  @override
  String get menuLeaveAppConfirm => 'Leave the app';

  @override
  String get menuLeaveAppLogout => 'Log out';

  @override
  String get menuLogoutConfirmTitle => 'Log out?';

  @override
  String get menuLogoutConfirmMessage =>
      'You will need to verify your account again when you return.';

  @override
  String get menuLogoutConfirmAction => 'Log out';

  @override
  String get menuLogoutConfirmBack => 'Go back';

  @override
  String get profileSettingsTitle => 'Settings';

  @override
  String get profileLogoutSubtitle => 'Sign out from this account';

  @override
  String get tripHistoryMenu => 'History';

  @override
  String get tripHistoryTitle => 'Trip history';

  @override
  String get tripHistoryFilterAll => 'All';

  @override
  String get tripHistoryFilterCompleted => 'Completed';

  @override
  String get tripHistoryFilterCancelled => 'Cancelled';

  @override
  String get tripHistoryFilterInProgress => 'In progress';

  @override
  String get tripHistoryDateAll => 'All time';

  @override
  String get tripHistoryDateToday => 'Today';

  @override
  String get tripHistoryDate7d => 'Last 7 days';

  @override
  String get tripHistoryDate30d => 'Last 30 days';

  @override
  String get tripHistoryStatusCompleted => 'Completed';

  @override
  String get tripHistoryStatusCancelled => 'Cancelled';

  @override
  String get tripHistoryStatusInProgress => 'In progress';

  @override
  String get tripHistoryDateCustom => 'Custom';

  @override
  String get tripHistoryActiveFilters => 'Active filters';

  @override
  String get tripHistoryCustomRangeLabel => 'Selected range';

  @override
  String get tripHistorySectionToday => 'Today';

  @override
  String get tripHistorySectionYesterday => 'Yesterday';

  @override
  String get tripHistorySectionOlder => 'Older';

  @override
  String get tripHistoryEmpty => 'You have no trips for this filter yet.';

  @override
  String get tripHistoryLoadError =>
      'We could not load your history. Please try again.';

  @override
  String get tripHistoryNoSession =>
      'Your session expired. Please sign in again.';

  @override
  String get tripHistoryPrevPage => 'Previous';

  @override
  String get tripHistoryNextPage => 'Next';

  @override
  String get tripHistoryPricePending => 'No amount';

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
  String get tripRecoveringStuckTitle => 'We couldn\'t restore your trip';

  @override
  String get tripRecoveringStuckBody =>
      'Your trip is still active. Check your connection and try again. Don\'t tap Cancel — that only applies while matching a driver.';

  @override
  String get tripRecoveringCheckNetwork => 'Internet connection';

  @override
  String get tripRecoveringCheckLocation => 'Location permission and GPS';

  @override
  String get tripRecoveringRetryCta => 'Retry reconnection';

  @override
  String get tripCancelBlockedActiveBody =>
      'Your trip is already in progress. It can\'t be cancelled from here.';

  @override
  String get verifyCodeTitle => 'Verify your number';

  @override
  String verifyCodeSubtitle(String phone) {
    return 'We sent a 6-digit code to $phone. Enter it to continue.';
  }

  @override
  String get verifyCodeFieldLabel => '6-digit verification code';

  @override
  String get verifyCodeMaskHint => '••••••';

  @override
  String get verifyCodeWaTitle => 'Verify with WhatsApp';

  @override
  String verifyCodeWaSubtitle(String phone) {
    return 'Send the pre-filled message from WhatsApp to confirm $phone.';
  }

  @override
  String get verifyCodeWaOpenButton => 'Open WhatsApp';

  @override
  String get verifyCodeWaWaiting => 'Waiting for your WhatsApp message…';

  @override
  String get verifyCodeWaFallbackHint =>
      'If WhatsApp did not open, tap the button above to try again.';

  @override
  String get verifyCodeWaRequestOutbound => 'Receive code via WhatsApp';

  @override
  String get verifyCodeWaOutboundFailed =>
      'We could not send the WhatsApp code. Please try again.';

  @override
  String get stepUpTitle => 'Additional verification';

  @override
  String get stepUpSubtitle =>
      'For your security, confirm your email and complete the captcha to continue.';

  @override
  String get stepUpEmailLabel => 'Email address';

  @override
  String get stepUpEmailHint => 'you@email.com';

  @override
  String get stepUpUseGoogleEmail => 'Use Google account on this device';

  @override
  String get stepUpSendEmailCode => 'Send code to email';

  @override
  String stepUpEmailSentBanner(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get stepUpResendCode => 'Resend code';

  @override
  String get stepUpSecurityLabel => 'Security verification';

  @override
  String get stepUpEmailCodeLabel => 'Email code';

  @override
  String get stepUpConfirmButton => 'Confirm and continue';

  @override
  String get stepUpCompleteContinueLogin =>
      'Additional verification complete. Continue with WhatsApp to verify your number.';

  @override
  String get stepUpEmailInvalid => 'Enter a valid email address.';

  @override
  String get stepUpCodeInvalid => 'Enter the 6-digit code from your email.';

  @override
  String get stepUpCaptchaRequired => 'Complete the captcha before continuing.';

  @override
  String get stepUpCaptchaLoadFailed =>
      'We could not load the captcha. Check your connection and try again.';

  @override
  String get stepUpCaptchaLoading => 'Loading security verification…';

  @override
  String get stepUpCaptchaInteractiveHint =>
      'Complete the Cloudflare checkbox above.';

  @override
  String get stepUpCaptchaReady => 'Security verification completed.';

  @override
  String get stepUpCaptchaRetry => 'Retry captcha';

  @override
  String get stepUpEmailSendFailed =>
      'We could not send the code to your email.';

  @override
  String get stepUpCompleteFailed =>
      'Additional verification could not be completed.';

  @override
  String get verifyCodeConfirm => 'Confirm code';

  @override
  String get verifyCodeRetryHint =>
      'If you did not receive the code, check the number and try again in a few minutes.';

  @override
  String get verifyCodeErrorActivateAccount =>
      'Could not activate the passenger account.';

  @override
  String get verifyCodeErrorIncompleteResponse => 'Incomplete server response.';

  @override
  String get verifyCodeErrorTokenMissing => 'Token not received.';

  @override
  String get verifyCodeErrorNetwork =>
      'Could not connect. Check your internet and try again.';

  @override
  String get verifyCodeErrorConnection =>
      'No connection to the server. Check your network.';

  @override
  String get verifyCodeErrorInvalidCodeInput =>
      'Enter the 6-digit code you received.';

  @override
  String get verifyCodeErrorValidateCode => 'Could not validate the code.';

  @override
  String get verifyCodeErrorUnexpected =>
      'Unexpected error while validating the code.';

  @override
  String get profileSetupErrorCompleteRegistration =>
      'Could not complete registration.';

  @override
  String get profileSetupErrorNetwork =>
      'Could not connect. Check your internet and try again.';

  @override
  String get profileSetupErrorConnection =>
      'No connection to the server. Check your network.';

  @override
  String profileSetupErrorRegisterStatus(String status) {
    return 'Error $status while registering profile.';
  }

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
  String get profilePhotoCropTitle => 'Adjust selfie';

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
  String get profileStatSavingsValue => 'BOB 340';

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
  String get profileSecurityNotAvailable => 'Not available';

  @override
  String get profileMockBiometricsValue => 'Enabled';

  @override
  String get profileMockLastAccessValue => 'Today, 09:14';

  @override
  String get profileActionEditInfo => 'Edit information';

  @override
  String get profileActionSupport => 'Safety';

  @override
  String get profileQuickActions => 'Quick actions';

  @override
  String get profileEditDisplayNameLabel => 'Display name';

  @override
  String get profileEditNameInvalid => 'Enter a valid name';

  @override
  String get profileEditSaveFailed => 'Could not save';

  @override
  String get profileEditSaving => 'Saving...';

  @override
  String get profileEditSaveChanges => 'Save changes';

  @override
  String get profileSupportCenterTitle => 'Support center';

  @override
  String get profileSupportCategoryGeneral => 'General';

  @override
  String get profileSupportCategoryTrip => 'Trip';

  @override
  String get profileSupportCategoryPayment => 'Payment';

  @override
  String get profileSupportCategoryAccount => 'Account';

  @override
  String get profileSupportCategorySafety => 'Safety';

  @override
  String get profileSupportCategoryTechnical => 'Technical';

  @override
  String get profileSupportCategoryLabel => 'Category';

  @override
  String get profileSupportSubjectLabel => 'Subject';

  @override
  String get profileSupportDetailLabel => 'Details';

  @override
  String get profileSupportValidationError =>
      'Complete subject and details (min. 3/10 characters).';

  @override
  String get profileSupportCreateFailed => 'Could not create ticket';

  @override
  String get profileSupportSentSuccess => 'Ticket submitted successfully';

  @override
  String get profileSupportSending => 'Sending...';

  @override
  String get profileSupportSendTicket => 'Submit ticket';

  @override
  String get profileSupportRecentTickets => 'My recent tickets';

  @override
  String get profileSupportNoTickets => 'You have no tickets yet.';

  @override
  String get profileSupportTicketsLoadFailed => 'Could not load tickets';

  @override
  String profileSupportTicketStatusChanged(String ticketNumber, String status) {
    return 'Ticket $ticketNumber changed to $status';
  }

  @override
  String get profileSupportDetailLoadFailed => 'Could not load details';

  @override
  String get profileSupportAttachUploading => 'Uploading...';

  @override
  String get profileSupportAttachImage => 'Attach image';

  @override
  String get profileSupportAttachSuccess => 'Attachment uploaded successfully';

  @override
  String get profileSupportAttachPrepFailed => 'Could not prepare attachment';

  @override
  String get profileSupportPresignInvalid => 'Invalid presign response';

  @override
  String get profileSupportAttachRegisterFailed =>
      'Could not register attachment';

  @override
  String get profileSupportTimeline => 'Timeline';

  @override
  String get profileSupportAttachments => 'Attachments';

  @override
  String get profileSupportNoAttachments => 'No attachments';

  @override
  String get passengerRatingFallbackDelay => 'Took too long to arrive';

  @override
  String get passengerRatingFallbackRoute => 'Inconvenient route';

  @override
  String get passengerRatingFallbackCleanliness => 'Uncomfortable vehicle';

  @override
  String get passengerRatingFallbackAttitude => 'Could improve attitude';

  @override
  String get passengerRatingFallbackOther => 'Other reason';

  @override
  String get passengerRatingFallbackSafe => 'Safe driving';

  @override
  String get passengerRatingFallbackClean => 'Clean vehicle';

  @override
  String get passengerRatingFallbackKind => 'Very kind';

  @override
  String get passengerRatingFallbackPunctual => 'Arrived quickly';

  @override
  String get passengerRatingFallbackExcellent => 'Excellent service';

  @override
  String get passengerNotifyArrivalReminder =>
      'Your driver is waiting at the pickup point.';

  @override
  String get passengerNotifyDriverArrivedTitle => 'Your driver arrived';

  @override
  String get passengerNotifyDriverArrivedBody =>
      'They\'re waiting at the pickup point.';

  @override
  String passengerNotifyDriverArrivedBodyNamed(String name) {
    return '$name is waiting at the pickup point.';
  }

  @override
  String get passengerNotifyChatNewTitle => 'Trip message';

  @override
  String get passengerNotifyChatSenderDriver => 'Driver';

  @override
  String get passengerNotifyChatSenderPassenger => 'Passenger';

  @override
  String get passengerNotificationChannelName => 'Trip updates';

  @override
  String get passengerNotificationChannelDescription =>
      'Trip status notifications for passengers.';

  @override
  String get passengerNotificationChannelFcmDescription =>
      'FCM alerts and trip status.';

  @override
  String get passengerNotificationChannelDriverArrivedDescription =>
      'Alerts when the driver arrives at pickup.';

  @override
  String get passengerNotificationChannelChatDescription =>
      'Messages from the active trip chat.';

  @override
  String get passengerLabsTitle => 'Labs';

  @override
  String get passengerLabsTitleBeta => 'Labs (beta)';

  @override
  String get passengerLabsNotAvailable => 'Not available.';

  @override
  String get passengerLabsGateError => 'Error checking access.';

  @override
  String get passengerLabsDescription =>
      'Reserved space for product testing (map, sockets, flags). The flask icon on Home only appears with a QA number or dart-define.';

  @override
  String tripHistoryDriverName(String name) {
    return 'Driver: $name';
  }

  @override
  String tripHistoryVehicleDetails(String details) {
    return 'Vehicle: $details';
  }

  @override
  String tripHistoryCreatedTime(String time) {
    return 'Time: $time';
  }

  @override
  String tripHistoryTripId(String id) {
    return 'ID: $id';
  }

  @override
  String get commonEnabled => 'enabled';

  @override
  String get commonDisabled => 'disabled';

  @override
  String homeDriverDistanceKm(String km) {
    return '$km km';
  }

  @override
  String get passengerLegalSectionTitle => 'Legal & privacy';

  @override
  String get passengerLegalSectionSubtitle =>
      'Review the documents that apply to your account and manage your data.';

  @override
  String get passengerLegalPrivacyPolicy => 'Privacy policy';

  @override
  String get passengerLegalTermsOfService => 'Terms of service';

  @override
  String get passengerLegalDeleteAccountTitle => 'Delete account';

  @override
  String get passengerLegalDeleteAccountBody =>
      'You can delete your account in the app or open the official page with instructions to submit a request.';

  @override
  String get passengerLegalDeleteAccountAction => 'How to request';

  @override
  String get passengerLegalDeleteAccountConfirmNow => 'Schedule deletion';

  @override
  String get passengerLegalDeleteAccountDeleting => 'Scheduling deletion…';

  @override
  String get passengerLegalDeleteAccountScheduledSuccess =>
      'Deletion scheduled. Your session was closed; sign in to recover your account before the deadline.';

  @override
  String passengerLegalDeleteAccountBodyGrace(int graceDays) {
    return 'Your account will enter a scheduled deletion period for $graceDays days. After you confirm, your session will close and you cannot use the app. To recover it, sign in with your phone number and cancel the request before the deadline.';
  }

  @override
  String get passengerLegalLoginHint =>
      'By continuing, you agree to our Privacy policy and Terms of service.';

  @override
  String get passengerLegalRegistrationHint =>
      'Before continuing, review the Privacy policy and Terms of service.';

  @override
  String get passengerLegalLoginPrefix => 'By continuing, you agree to our ';

  @override
  String get passengerLegalRegistrationPrefix =>
      'Before continuing, review our ';

  @override
  String get passengerLegalLoginConjunction => ' and ';

  @override
  String get passengerLoginAccountDeletionPendingTitle => 'Deletion scheduled';

  @override
  String passengerLoginAccountDeletionPendingBody(String effectiveDate) {
    return 'This account is scheduled for deletion on $effectiveDate. You cannot use the app until you recover it.';
  }

  @override
  String get passengerLoginAccountDeletionPendingDateFallback =>
      'the scheduled date';

  @override
  String get passengerLoginAccountDeletionRecover => 'Recover account';

  @override
  String get passengerLoginAccountDeletionDismiss => 'OK';

  @override
  String get passengerLoginAccountDeletionRecovering => 'Recovering account…';

  @override
  String get passengerLoginAccountDeletionRecoverSuccess =>
      'Account recovered. Welcome back.';

  @override
  String get passengerLegalDeleteAccountPendingTitle => 'Deletion scheduled';

  @override
  String passengerLegalDeleteAccountPendingBody(
    String effectiveDate,
    int daysRemaining,
  ) {
    return 'Your account will be deleted on $effectiveDate. You have $daysRemaining days left to cancel and restore access.';
  }

  @override
  String get passengerLegalDeleteAccountPendingDateFallback =>
      'the scheduled date';

  @override
  String get passengerLegalDeleteAccountCancelAction => 'Cancel deletion';

  @override
  String get passengerLegalDeleteAccountCancelling => 'Cancelling deletion…';

  @override
  String get passengerLegalDeleteAccountCancelSuccess =>
      'Deletion cancelled. Your account is still active.';

  @override
  String get passengerAccountDeletionErrorSessionExpired =>
      'Session expired. Sign in and try again.';

  @override
  String get passengerAccountDeletionErrorScheduleFailed =>
      'Could not schedule account deletion.';

  @override
  String get passengerAccountDeletionErrorCancelFailed =>
      'Could not cancel account deletion.';

  @override
  String get passengerPlayCameraDisclosureTitle => 'Camera access';

  @override
  String get passengerPlayCameraDisclosureBody =>
      'Texi uses the camera to take your profile photo or attach images in support. Photos are sent securely to our servers.';

  @override
  String get passengerPlayGalleryDisclosureTitle => 'Photo library access';

  @override
  String get passengerPlayGalleryDisclosureBody =>
      'Texi accesses photos you choose from your library for your profile or support tickets. Only the image you select is uploaded.';

  @override
  String get passengerPlayNotificationDisclosureTitle => 'Trip notifications';

  @override
  String get passengerPlayNotificationDisclosureBody =>
      'Texi needs to send you notifications when a driver accepts your trip, trip status changes, or the driver sends a message during an active ride.';

  @override
  String get passengerPlayLocationDisclosureTitle =>
      'Location for trip requests';

  @override
  String get passengerPlayLocationDisclosureBody =>
      'Texi uses your location to show you on the map, find nearby drivers, and help with pickup at your origin point.';

  @override
  String get passengerPlayDisclosureContinue => 'Continue';

  @override
  String get passengerPlayNotificationDisclosureRequired =>
      'Enable notifications to receive trip updates from your driver.';

  @override
  String get menuSupportHelp => 'Safety';

  @override
  String get menuOperatorTexi => 'Operator';

  @override
  String get menuProfile => 'Profile';

  @override
  String get menuTripHistory => 'My trips';

  @override
  String get menuOpenTooltip => 'Menu';

  @override
  String get safetyEmergencyCta => 'Emergency';

  @override
  String get safetyLiveTrackingTitle => 'Live tracking';

  @override
  String get safetyLiveTrackingUnavailable =>
      'This feature is only available once your trip is underway.';

  @override
  String get supportHelpSubtitle => 'Emergency and assistance 24/7';

  @override
  String get supportEmergencyTitle => 'Emergency';

  @override
  String supportEmergencyBody(String number) {
    return 'If you\'re in danger or need immediate help, call $number.';
  }

  @override
  String get supportCallNowCta => 'CALL NOW';

  @override
  String get supportMoreOptionsTitle => 'More help options';

  @override
  String get supportWhatsAppTitle => 'WhatsApp';

  @override
  String get supportTicketsSubtitle => 'Create or review support tickets';

  @override
  String get supportCompanyCallTitle => 'Call Texi';

  @override
  String get supportCallFailed =>
      'Could not start the call. Check phone permissions.';

  @override
  String get supportTrustFooter =>
      'Your safety comes first. Operators and protocols ready to assist you.';

  @override
  String get operatorTexiSubtitle =>
      'Contact our Operators and learn more about our services.';

  @override
  String get operatorSecurityCtaTitle => 'Safety';

  @override
  String get operatorSecurityCtaSubtitle => 'Emergency 110 and assistance';

  @override
  String get operatorSecurityCareMessage =>
      'Your safety matters to us. We\'re here to look after you on every ride.';

  @override
  String get operatorCallTitle => 'Call operator';

  @override
  String get operatorVerifiedDriversCtaTitle => 'Verified drivers';

  @override
  String get operatorVerifiedDriversCtaSubtitle =>
      'How TEXI validates every driver';

  @override
  String get operatorVerifiedDriversTitle => 'Verified drivers';

  @override
  String get operatorCheckIdentityTitle => 'Identity verified';

  @override
  String get operatorCheckIdentityBody => 'Document and photo reviewed';

  @override
  String get operatorCheckBackgroundTitle => 'Background checks';

  @override
  String get operatorCheckBackgroundBody => 'Security filters applied';

  @override
  String get operatorCheckInspectionTitle => 'Vehicle inspection';

  @override
  String get operatorCheckInspectionBody =>
      'Condition and paperwork up to date';

  @override
  String get operatorCheckInsuranceTitle => 'Active insurance';

  @override
  String get operatorCheckInsuranceBody => 'Coverage active for service';

  @override
  String get operatorCheckTrainingTitle => 'Training';

  @override
  String get operatorCheckTrainingBody => 'Texi service standards';

  @override
  String get operatorTrustClosing =>
      'Ride with confidence. Drivers verified by Texi.';

  @override
  String get profileCompletenessTitle => 'Complete your information';

  @override
  String profileCompletenessMissing(int count) {
    return '$count fields left to complete';
  }

  @override
  String get profileCompletenessDone => 'Your profile is complete';

  @override
  String get profileCompleteInfoCta => 'COMPLETE INFORMATION';

  @override
  String get profileVerifiedUserLabel => 'Verified user';

  @override
  String get profileBrandTitle => 'TEXIAPP';
}

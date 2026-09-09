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
  String get loginMethodChoiceSubtitle => 'Choose how you want to sign in.';

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
  String get loginMethodPhoneInfo =>
      'Enter your mobile number. Then complete a security check and choose how to confirm it on WhatsApp.';

  @override
  String get loginMethodGoogleInfo =>
      'Use your Google account (Gmail) to sign in without another password. First time? We\'ll ask you to confirm your mobile number.';

  @override
  String get loginAuthInfoTitle => 'Additional information';

  @override
  String get loginAuthInfoSecureNote =>
      'Secure, encrypted process. We only use your data to sign you in—we don\'t share it with third parties.';

  @override
  String get loginAuthInfoGotIt => 'Got it';

  @override
  String get loginGoogleNotConfiguredInApp =>
      'Google sign-in is unavailable right now. Use your mobile number or contact our team.';

  @override
  String get loginBackToMethods => 'Back to sign-in options';

  @override
  String get loginPhoneStepTitle => 'What\'s your number?';

  @override
  String get loginPhoneStepSubtitle =>
      'Then choose how to confirm it on WhatsApp.';

  @override
  String get loginAttemptsLimitTitle => 'Too many attempts';

  @override
  String get loginAttemptsLimitBody =>
      'Check your details. Wait a few minutes before trying again, or choose another sign-in method on the home screen.';

  @override
  String get loginAttemptsLimitAction => 'Back to start';

  @override
  String get authLockoutTitle => 'Please wait';

  @override
  String get authLockoutBody =>
      'For your security we paused sign-in attempts. You can continue when the timer ends.';

  @override
  String get authLockoutWaitLabel => 'Time remaining';

  @override
  String get authLockoutSecondsUnit => 'sec';

  @override
  String get authLockoutAlternateHint =>
      'You can also verify your number by sending the WhatsApp message.';

  @override
  String get authLockoutWhatsAppCta => 'Verify with WhatsApp';

  @override
  String get loginCaptchaTitle => 'Security verification';

  @override
  String get loginCaptchaSubtitle =>
      'A quick step before continuing. Only once this session.';

  @override
  String get loginGoogleCaptchaTitle => 'Verify your Google sign-in';

  @override
  String get loginGoogleCaptchaSubtitle =>
      'Complete the security check to protect your account and continue with Google.';

  @override
  String get loginCaptchaLoading => 'Loading verification…';

  @override
  String get loginCaptchaInteractiveHint => 'Check the box to continue.';

  @override
  String get loginCaptchaReady => 'Verification complete.';

  @override
  String get loginCaptchaLoadFailed =>
      'We couldn\'t load the security check. Check your connection.';

  @override
  String get loginCaptchaReadyHint =>
      'You\'re good to go. Continue to the next step.';

  @override
  String get loginCaptchaDevPlaceholder =>
      'Security verification is unavailable right now. Try again later.';

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
  String get loginVerifyMethodLoadingWa => 'Preparing verification…';

  @override
  String get loginPhoneUnifiedTitle => 'Enter your number';

  @override
  String get loginVerifySectionLabel => 'Choose how to verify';

  @override
  String get loginVerifyMethodWaInboundShort => 'Secure key via WhatsApp';

  @override
  String get loginVerifyMethodCodeShort => 'Verification code';

  @override
  String get loginVerifyMethodWaInboundInfo =>
      'We open WhatsApp with a ready-to-send message. Send it and we confirm it\'s you.';

  @override
  String get loginVerifyMethodCodeInfo =>
      'We send a 6-digit code via WhatsApp. Enter it in the app to confirm it\'s you.';

  @override
  String get loginGoogleUnifiedTitle => 'Sign in with email';

  @override
  String get loginGoogleEmailHint => 'you@email.com';

  @override
  String get loginGoogleEmailInfo =>
      'Enter your email or pick an account from this phone. We\'ll send you a code.';

  @override
  String get loginEmailPickFromDevice => 'Use email from this phone';

  @override
  String get loginGoogleSignInButton => 'Sign in with Google';

  @override
  String get loginGoogleOrDivider => 'or';

  @override
  String get loginGoogleContinue => 'Continue';

  @override
  String loginPhoneStepSubtitleGoogle(String email) {
    return 'Confirm your number on WhatsApp ($email).';
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
  String get loginPhoneHint => 'E.g.: 70000000';

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
      'This number is already registered as a driver.';

  @override
  String get loginErrorPhoneOtherAccountType =>
      'This number is already on another account.';

  @override
  String get loginErrorPhoneDuplicatePassenger =>
      'This number is already registered on another passenger account.';

  @override
  String get loginErrorVerificationServiceUnavailable =>
      'We could not verify right now. Try again later.';

  @override
  String get loginErrorBackendUnavailable =>
      'The service is temporarily unavailable. Please try again in a few minutes.';

  @override
  String get loginErrorWhatsAppVerificationUnavailable =>
      'WhatsApp verification is not available. Contact our team or try again later.';

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
  String get loginPhoneRequired => 'Enter your number.';

  @override
  String get loginPhoneInvalidBolivia => 'Enter your number. E.g.: 70000000';

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
  String get tripSecureChat => 'Chat';

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
  String get passengerTripChatSubtitle => 'You can message your driver.';

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
      'Chat isn\'t available. Contact our team.';

  @override
  String get passengerTripChatErrorPhase =>
      'Chat isn\'t available at this point in the trip.';

  @override
  String get passengerTripChatErrorNotReady =>
      'Chat is still connecting. Try again in a few seconds.';

  @override
  String get passengerTripChatErrorSendReceive =>
      'Couldn\'t send the message. Check your connection.';

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
      'Confirma tu ubicación exacta';

  @override
  String get commonEmptyDash => '—';

  @override
  String get tripNoCoverageInZone =>
      'We don\'t have service coverage in this area at the moment. Try another location or move to a service zone.';

  @override
  String get tripFaresNotConfigured =>
      'Fares are not available in this city yet. Try another area or try again later.';

  @override
  String get tripInvalidCoordinates =>
      'We couldn\'t locate the origin or destination. Choose the points on the map again.';

  @override
  String get tripServiceTypeUnavailable =>
      'That service type isn\'t available right now. Choose another option.';

  @override
  String get tripRequestInvalid =>
      'We couldn\'t create your request. Check origin and destination and try again.';

  @override
  String get tripCreateRateLimited =>
      'You sent several requests in a row. Wait a moment and try again.';

  @override
  String get tripQuoteNetworkError =>
      'We couldn\'t calculate the fare. Check your connection and try again.';

  @override
  String get tripQuoteUnavailable =>
      'We couldn\'t calculate the fare right now. Try again in a few seconds.';

  @override
  String get tripRequestNetworkError =>
      'We couldn\'t send your request. Check your connection and try again.';

  @override
  String get tripRequestUnavailable =>
      'We couldn\'t send your request right now. Try again in a few seconds.';

  @override
  String get tripNoDriversAvailable =>
      'We couldn\'t find drivers nearby right now. Try again in a few minutes.';

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
  String get tripPaymentMethodCash => 'Cash';

  @override
  String get tripPaymentMethodCashBody => 'Pay the driver in cash.';

  @override
  String get tripPaymentMethodQr => 'QR';

  @override
  String get tripPaymentMethodQrBody => 'Pay with the driver\'s QR code.';

  @override
  String get tripRequestDetailsTitle => 'Trip settings';

  @override
  String get tripRequestDetailsHint =>
      'Choose how you\'ll pay and tell the driver what to know before you go.';

  @override
  String get tripRequestDetailsTooltip => 'Trip settings';

  @override
  String get tripRequestDetailsDone => 'Done';

  @override
  String get tripRequestDetailsLearnMore => 'Learn more about these settings';

  @override
  String get tripRequestDetailsLearnMoreError =>
      'We couldn\'t open the page. Check your connection and try again.';

  @override
  String get tripPaymentSectionTitle => 'How you\'ll pay';

  @override
  String get tripPrefsSectionTitle => 'Trip preferences';

  @override
  String get tripPrefsSectionHint =>
      'The driver will see this. It doesn\'t change the fare.';

  @override
  String get tripPrefPetTitle => 'Traveling with my pet';

  @override
  String get tripPrefPetBody => 'Bring a blanket or carrier for the ride.';

  @override
  String get tripPrefPetInfo =>
      'Lets the driver prepare the seat. Bring a blanket or carrier. It does not add to the fare.';

  @override
  String get tripPrefWheelchairTitle => 'Wheelchair';

  @override
  String get tripPrefWheelchairBody =>
      'Trunk space and a little extra time to board.';

  @override
  String get tripPrefWheelchairInfo =>
      'The driver will know you need the trunk for the wheelchair and a moment extra to board. It does not add to the fare.';

  @override
  String get tripPrefLuggageTitle => 'Bags or luggage';

  @override
  String get tripPrefLuggageBody => 'Up to 2 medium bags in the trunk.';

  @override
  String get tripPrefLuggageInfo =>
      'Up to 2 medium suitcases that fit in the trunk. Typical traveler luggage should stay around 50 kg. It does not add to the fare.';

  @override
  String get tripPrefAcTitle => 'Air conditioning';

  @override
  String get tripPrefAcBody => 'You prefer to ride with A/C on.';

  @override
  String get tripPrefAcInfo =>
      'This informs the driver. On Comfort it does not change the price — it’s a preference, not a surcharge.';

  @override
  String tripPrefsCount(int count) {
    return '$count preferences';
  }

  @override
  String get tripSpecialsSectionTitle => 'Special requirements';

  @override
  String get tripSpecialsSectionHint => 'This can change the trip fare.';

  @override
  String get tripSpecialSeats6Title => 'Up to 6 people';

  @override
  String get tripSpecialSeats6Body => 'We\'ll look for a larger vehicle.';

  @override
  String get tripSpecialSeats6Info =>
      'We look for a car with more seats. If none is nearby, the request still goes out to available drivers.';

  @override
  String get tripSpecialRoofRackTitle => 'Roof rack';

  @override
  String get tripSpecialRoofRackBody => 'For bundles tied on top of the car.';

  @override
  String get tripSpecialRoofRackInfo =>
      'For bundles, boxes, or goods tied on the roof. Volume and weight similar to a standard car. Not for moving house or construction materials.';

  @override
  String get tripSpecialCargoTitle => 'Cargo or merchandise';

  @override
  String get tripSpecialCargoBody => 'Boxes or bundles in the trunk and seats.';

  @override
  String get tripSpecialCargoInfo =>
      'For boxes, sacks, or large bundles in the trunk and seats. Same limits as a standard car. Not for moving house or construction materials.';

  @override
  String tripSpecialsCount(int count) {
    return '$count requirements';
  }

  @override
  String tripSpecialsPricePreview(String total) {
    return 'Your trip would be $total';
  }

  @override
  String get tripAddonInfoClose => 'Got it';

  @override
  String get tripMotoServiceTitle => 'Your shortcut in the city';

  @override
  String get tripMotoServiceBody =>
      'One passenger. Usually the quickest way to get there on urban trips.';

  @override
  String get tripMotoPerkSpeed => 'Quicker in traffic';

  @override
  String get tripMotoPerkSolo => 'Built for one person';

  @override
  String get tripMotoPerkLight => 'No large bags or car extras';

  @override
  String get tripPremiumIncludedTitle => 'Your Premium experience';

  @override
  String get tripPremiumIncludedHint =>
      'It’s already included. You only choose how to pay.';

  @override
  String get tripPremiumAmenityCharger => 'Charger and music';

  @override
  String get tripPremiumAmenityChargerBody =>
      'Charge your phone (iPhone or USB-C) or play your music over Bluetooth.';

  @override
  String get tripPremiumAmenityCourtesy => 'Welcomed in style';

  @override
  String get tripPremiumAmenityCourtesyBody =>
      'They open the door and help with light luggage.';

  @override
  String get tripPremiumAmenityWater => 'Courtesy water';

  @override
  String get tripPremiumAmenityWaterBody =>
      'Ready in the back seat when available.';

  @override
  String get tripPremiumAmenityInvoice => 'Ready for business';

  @override
  String get tripPremiumAmenityInvoiceBody =>
      'You can request an invoice or a company profile, when available.';

  @override
  String get tripPremiumAmenityWait => 'Leave at your pace';

  @override
  String get tripPremiumAmenityWaitBody =>
      'A few extra minutes of wait, with no surcharge.';

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
  String get tripSearchingEtaHint => 'Usually takes 1–3 min';

  @override
  String get tripSearchingRotateCheck2km => 'Looking for drivers near you…';

  @override
  String get tripSearchingRotateAvailability =>
      'Looking for someone who can take you…';

  @override
  String get tripSearchingRotateOptimizeRoute => 'Getting your trip ready…';

  @override
  String get tripSearchingOfflineBanner => 'No internet. Trying again…';

  @override
  String get tripSearchingLocationBanner =>
      'Turn on location to improve the search.';

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
      'We couldn’t update your trip. Check your connection.';

  @override
  String get tripRbacForbidden =>
      'We could not complete this action. If it keeps happening, sign out and sign back in or contact our team.';

  @override
  String get tripRbacSession =>
      'We couldn’t validate your session. Sign out and sign in again.';

  @override
  String get tripRbacTechnical =>
      'We couldn’t complete this action. Try again in a few seconds.';

  @override
  String get tripPhoneRequired =>
      'Verify your mobile number to request a trip.';

  @override
  String get tripPhoneGateTitle => 'Confirm your number';

  @override
  String get tripPhoneGateBody =>
      'You signed in with email. To request a trip you need to verify your mobile number once.';

  @override
  String get tripPhoneGatePrimaryAction => 'See verification options';

  @override
  String get tripPhoneGateDismiss => 'Not now';

  @override
  String get phoneLinkTitle => 'Verify your phone';

  @override
  String get phoneLinkSubtitle =>
      'Confirm your number on WhatsApp to request a ride.';

  @override
  String get phoneLinkContinue => 'Send code';

  @override
  String get phoneLinkSuccess => 'Number verified. You can now request trips.';

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
  String get tripRatingFeedbackPromptLow => 'What affected your experience?';

  @override
  String get tripRatingFeedbackPromptHigh =>
      'What stood out about the service?';

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
  String tripLiveEtaPickup(int count) {
    return 'Arrives in $count min';
  }

  @override
  String tripLiveEtaDestination(int count) {
    return '$count min to destination';
  }

  @override
  String tripLiveEtaClockHint(String time) {
    return 'around $time';
  }

  @override
  String get tripLiveEtaAtPickup => 'Already at the pickup point';

  @override
  String tripPickupWaitWaiting(String time) {
    return 'Waiting at the pickup point · $time';
  }

  @override
  String tripPickupWaitGrace(String time) {
    return 'Wait time is up. Extra time · $time';
  }

  @override
  String get tripPickupWaitEnded => 'The wait time has ended.';

  @override
  String get tripPassengerEnRouteCta => 'On my way';

  @override
  String get tripPassengerEnRouteSent => 'We let the driver know.';

  @override
  String tripPassengerEnRouteCooldown(int seconds) {
    return 'You can send this again in $seconds s';
  }

  @override
  String get tripPassengerEnRouteNeedConnection =>
      'You\'re offline, so we can\'t send this. Try again when you\'re back online.';

  @override
  String get tripPassengerEnRouteError =>
      'We couldn\'t reach the driver. Try again.';

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
  String get profileSetupPhotoSoon => 'You can choose a profile photo.';

  @override
  String get profileSetupNameLabel => 'Your name';

  @override
  String get profileSetupNameHint => 'e.g. Juan Perez';

  @override
  String get profileSetupNameRequired => 'Enter your name.';

  @override
  String get profileSetupNameTooShort => 'That name is too short.';

  @override
  String get profileSetupContinue => 'Continue';

  @override
  String get profileSetupReferralLabel => 'Referral code (optional)';

  @override
  String get profileSetupReferralHint => 'Code from who referred you';

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
      'Your trip is still active. Check your connection and try again. If you\'re still matching a driver, you can cancel the search.';

  @override
  String get tripRecoveringCheckNetwork => 'Internet connection';

  @override
  String get tripRecoveringCheckLocation => 'Location permission and GPS';

  @override
  String get tripRecoveringRetryCta => 'Try again';

  @override
  String get tripRecoveringCancelMatchingCta => 'Cancel search';

  @override
  String get tripCancelBlockedActiveBody =>
      'Your trip is already in progress. It can\'t be cancelled from here.';

  @override
  String get tripCancelCta => 'Cancel trip';

  @override
  String get tripCancelChooseReason => 'Why are you cancelling?';

  @override
  String get tripCancelNoteHint => 'Write the reason';

  @override
  String get tripCancelContinue => 'Continue';

  @override
  String get tripCancelConfirmTitle => 'Confirm cancellation';

  @override
  String get tripCancelConfirm => 'Confirm';

  @override
  String get tripCancelBack => 'Back';

  @override
  String get tripCancelNeedConnection =>
      'We can\'t cancel without a connection. Try again when you\'re back online.';

  @override
  String get tripCancelReasonsLoadError =>
      'We couldn\'t load the reasons. Check your connection and try again.';

  @override
  String get tripCancelReasonsEmpty =>
      'There are no cancel reasons available right now.';

  @override
  String get tripCancelConfirmFallback =>
      'If you confirm, the trip is cancelled. Our team may review the reason.';

  @override
  String get tripCancelError =>
      'We couldn\'t cancel the trip. Check your connection and try again.';

  @override
  String get tripCancelCapExceeded =>
      'Wait a moment before requesting another trip.';

  @override
  String get tripClaimAsk => 'Do you want to send a claim to our team?';

  @override
  String get tripClaimHint =>
      'Tell us what happened. Our team can review the trip.';

  @override
  String get tripClaimSend => 'Send claim';

  @override
  String get tripClaimSkip => 'Not now';

  @override
  String get tripClaimSent => 'We sent your claim to our team.';

  @override
  String get tripClaimError => 'We couldn\'t send the claim. Try again later.';

  @override
  String get tripClaimAlreadySent => 'You already sent a claim for this trip.';

  @override
  String get tripCancelledByDriver => 'The driver canceled the trip.';

  @override
  String get tripNeedHelp => 'I need help';

  @override
  String get tripAlreadyFinalized =>
      'This trip already ended. Refresh to continue.';

  @override
  String get tripCannotCancelRace =>
      'The trip changed stage. Refresh and try again.';

  @override
  String get tripCancelEnRouteTooSoon =>
      'The driver is still within the on-the-way time.';

  @override
  String get tripCancelWaitStillWaiting => 'You\'re still in the waiting time.';

  @override
  String get tripCancelWaitStillGrace => 'You\'re still in the grace period.';

  @override
  String get tripCancelWaitNotAtPickup =>
      'It looks like you\'re not at the pickup point.';

  @override
  String get tripCancelWaitNoLocation =>
      'We couldn\'t confirm you\'re at the pickup point.';

  @override
  String get tripCancelWaitNotEligible =>
      'The wait-time reason doesn\'t apply at this stage.';

  @override
  String get verifyCodeTitle => 'Verify your number';

  @override
  String verifyCodeSubtitle(String phone) {
    return 'We sent a 6-digit code to $phone. Enter it to continue.';
  }

  @override
  String get verifyCodeEmailTitle => 'Verify your email';

  @override
  String verifyCodeEmailSubtitle(String email) {
    return 'We sent a 6-digit code to $email. Enter it to continue.';
  }

  @override
  String get verifyCodeEmailInfo =>
      'Check your email for a 6-digit code. Enter all six digits here. It may take a few seconds to arrive.';

  @override
  String get verifyCodeEmailRetryHint =>
      'If you did not receive the code, check your email (including spam) and try again in a few minutes.';

  @override
  String get verifyCodeFieldLabel => '6-digit verification code';

  @override
  String get verifyCodeMaskHint => '••••••';

  @override
  String get verifyCodeWaTitle => 'Verify with WhatsApp';

  @override
  String verifyCodeWaSubtitle(String phone) {
    return 'Send the WhatsApp message to confirm $phone. Then come back here.';
  }

  @override
  String get verifyCodeWaOpenButton => 'Open WhatsApp';

  @override
  String get verifyCodeWaWaiting => 'Waiting for your WhatsApp message…';

  @override
  String get verifyCodeWaVerified => 'Message received! Continuing…';

  @override
  String get verifyCodeWaFallbackHint =>
      'If WhatsApp did not open, tap the button above to try again.';

  @override
  String get verifyCodeWaRequestOutbound => 'Receive code via WhatsApp';

  @override
  String get verifyCodeWaRequestSms => 'Receive code via SMS';

  @override
  String get verifyCodeSmsTitle => 'Verify with SMS';

  @override
  String verifyCodeSmsSubtitle(String phone) {
    return 'We’ll send a 6-digit code by SMS to $phone.';
  }

  @override
  String get verifyCodeSmsWaiting => 'Waiting for the SMS…';

  @override
  String get verifyCodeSmsFailed => 'We couldn’t send the SMS. Try again.';

  @override
  String get verifyCodeSmsEmailRequired =>
      'To use SMS, confirm your Google account on this device.';

  @override
  String get verifySmsGoogleTitle => 'Confirm with Google';

  @override
  String verifySmsGoogleSubtitle(String phone) {
    return 'To receive an SMS at $phone, use the Google account linked on this device.';
  }

  @override
  String get verifySmsGoogleButton => 'Continue with Google';

  @override
  String get verifySmsGoogleHint =>
      'We only accept the Google account on this phone. You cannot type another email.';

  @override
  String get verifySmsGoogleCancelled =>
      'You did not finish Google sign-in. Tap the button below to try again.';

  @override
  String get verifySmsGoogleRequired =>
      'To receive SMS, confirm your Google account on this device.';

  @override
  String verifySmsLinkedAccount(String email) {
    return 'Linked account: $email';
  }

  @override
  String get verifySmsFirebaseNotConfigured =>
      'SMS verification is not available yet. Try signing in with WhatsApp.';

  @override
  String get verifySmsFirebaseShaMissing =>
      'This app version cannot receive SMS yet. Update the app or use WhatsApp to continue.';

  @override
  String get verifySmsFirebaseRateLimited =>
      'You requested several codes in a row. Wait a few minutes and try again.';

  @override
  String get verifySmsFirebasePhoneDisabled =>
      'SMS is not active for your number yet. You can use WhatsApp or try again later.';

  @override
  String get verifySmsErrorTitleGeneric => 'We could not continue';

  @override
  String get verifySmsErrorTitleSmsUnavailable => 'SMS unavailable';

  @override
  String get verifySmsErrorTitleRateLimited => 'Too many attempts';

  @override
  String get verifySmsErrorTitleNetwork => 'No connection';

  @override
  String get verifySmsErrorTitleGoogleCancelled => 'Google sign-in incomplete';

  @override
  String get verifySmsErrorTitleSmsBlocked => 'SMS temporarily blocked';

  @override
  String get verifySmsErrorTitleCaptcha => 'Security verification';

  @override
  String get verifySmsFirebaseError39 =>
      'The SMS could not be sent. This often happens after too many attempts. Wait a few minutes or use WhatsApp.';

  @override
  String get verifySmsFirebaseCaptchaFailed =>
      'We could not complete the security check. Try again in a few minutes or verify your number with WhatsApp.';

  @override
  String get verifySmsTryWhatsApp => 'Verify with WhatsApp';

  @override
  String get verifySmsBackToLogin => 'Back to sign in';

  @override
  String get loginErrorWaOutboundRateLimit =>
      'We sent a WhatsApp code recently. Wait a few minutes or send the WhatsApp message.';

  @override
  String get tripMapsRestKeyMissing =>
      'Address search is unavailable right now. Try again later.';

  @override
  String get tripMapsRestKeyDenied =>
      'We could not search addresses or routes. Try again later.';

  @override
  String get tripMapsRestUnavailable =>
      'We could not load addresses or routes. Check your connection and try again.';

  @override
  String get verifyCodeWaOutboundFailed =>
      'We could not send the WhatsApp code. Please try again.';

  @override
  String get stepUpTitle => 'Additional verification';

  @override
  String get stepUpSubtitle =>
      'For your security, confirm your email and complete the verification to continue.';

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
  String get stepUpCodeInvalid => 'Enter the 6-digit code.';

  @override
  String get stepUpCaptchaRequired =>
      'Complete the security check before continuing.';

  @override
  String get stepUpCaptchaLoadFailed =>
      'We could not load the security check. Check your connection and try again.';

  @override
  String get stepUpCaptchaLoading => 'Loading security verification…';

  @override
  String get stepUpCaptchaInteractiveHint =>
      'Complete the security check above.';

  @override
  String get stepUpCaptchaReady => 'Security verification completed.';

  @override
  String get stepUpCaptchaRetry => 'Retry verification';

  @override
  String get stepUpEmailSendFailed =>
      'We could not send the code to your email.';

  @override
  String get stepUpCompleteFailed =>
      'Additional verification could not be completed.';

  @override
  String get verifyCodeConfirm => 'Confirm code';

  @override
  String get verifyCodeEntryInfo =>
      'Check WhatsApp for a 6-digit code. Enter all six digits here. It may take a few seconds to arrive.';

  @override
  String get verifyCodeWaInfo =>
      'We open WhatsApp with a ready-to-send message. Send it, return to the app, and we\'ll confirm it\'s you.';

  @override
  String get verifyCodeRetryHint =>
      'If you did not receive the code, check the number and try again in a few minutes.';

  @override
  String get verifyCodeOutboundHelpLink => 'Didn\'t get the code?';

  @override
  String get verifyCodeOutboundHelpSubtitle =>
      'Try another way to verify your number.';

  @override
  String get verifyCodeOutboundResend => 'Resend code via WhatsApp';

  @override
  String get verifyCodeOutboundResent => 'We sent you a new code via WhatsApp.';

  @override
  String get verifyCodePlayReviewSubtitle =>
      'Play Store test account: enter the access code from the store listing instructions (no WhatsApp or SMS needed).';

  @override
  String get verifyCodeErrorActivateAccount =>
      'Could not activate the passenger account.';

  @override
  String get verifyCodeErrorIncompleteResponse =>
      'We could not complete registration. Try again.';

  @override
  String get verifyCodeErrorTokenMissing => 'We could not sign in. Try again.';

  @override
  String get verifyCodeErrorNetwork =>
      'Could not connect. Check your internet and try again.';

  @override
  String get verifyCodeErrorConnection => 'No connection. Check your network.';

  @override
  String get verifyCodeErrorInvalidCodeInput =>
      'Enter the 6-digit code you received.';

  @override
  String get verifyCodeErrorValidateCode => 'Could not validate the code.';

  @override
  String get verifyCodeErrorUnexpected =>
      'We could not validate the code. Try again.';

  @override
  String get profileSetupErrorCompleteRegistration =>
      'Could not complete registration.';

  @override
  String get profileSetupErrorNetwork =>
      'Could not connect. Check your internet and try again.';

  @override
  String get profileSetupErrorConnection =>
      'No connection. Check your network.';

  @override
  String get profileSetupErrorRegisterStatus =>
      'Could not complete registration.';

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
  String get profilePhotoFromServer => 'Profile photo';

  @override
  String get profileNoServerPhoto =>
      'No profile photo on file. You can add one when editing your profile.';

  @override
  String get profileErrorNoSession => 'Your session expired. Sign in again.';

  @override
  String get profileErrorForbidden =>
      'This action needs a passenger session. Sign out and sign in again with your phone number.';

  @override
  String get profileErrorNotFound =>
      'We could not find your passenger profile. If this continues, contact our team.';

  @override
  String get profileTaglinePassenger => 'TEXIAPP passenger';

  @override
  String get profileAccountLabel => 'Account';

  @override
  String get profileScreenTitle => 'My profile';

  @override
  String get profileStateLoaded => 'Ready';

  @override
  String get profileStateLoading => 'Loading…';

  @override
  String get profileStateEmpty => 'No saved places yet.';

  @override
  String get profileStateError => 'Couldn\'t load.';

  @override
  String get profileStateOffline => 'Offline.';

  @override
  String get profileEmptyTitle => 'Complete your profile';

  @override
  String get profileEmptyBody =>
      'We couldn\'t find your profile yet. You can complete it in a few steps.';

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
  String get tripMissingDataBody =>
      'Choose origin and destination again to continue.';

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
  String get profileSupportCenterTitle => 'Help center';

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
  String get profileSupportCategoryTechnical => 'App';

  @override
  String get profileSupportCategoryLabel => 'Category';

  @override
  String get profileSupportSubjectLabel => 'Subject';

  @override
  String get profileSupportDetailLabel => 'Details';

  @override
  String get profileSupportValidationError =>
      'Write a subject and tell us what happened.';

  @override
  String get profileSupportCreateFailed => 'We couldn\'t create your request.';

  @override
  String get profileSupportSentSuccess => 'Your request was sent.';

  @override
  String get profileSupportSending => 'Sending...';

  @override
  String get profileSupportSendTicket => 'Send request';

  @override
  String get profileSupportRecentTickets => 'My recent requests';

  @override
  String get profileSupportNoTickets => 'You have no requests yet.';

  @override
  String get profileSupportTicketsLoadFailed =>
      'We couldn\'t load your requests.';

  @override
  String profileSupportTicketStatusChanged(String ticketNumber, String status) {
    return 'Your request $ticketNumber is now $status';
  }

  @override
  String get profileSupportDetailLoadFailed => 'We couldn\'t load the details.';

  @override
  String get profileSupportAttachUploading => 'Uploading...';

  @override
  String get profileSupportAttachImage => 'Attach image';

  @override
  String get profileSupportAttachSuccess => 'Image sent.';

  @override
  String get profileSupportAttachPrepFailed =>
      'We couldn\'t prepare the image.';

  @override
  String get profileSupportPresignInvalid =>
      'We could not upload the file. Try again.';

  @override
  String get profileSupportAttachRegisterFailed =>
      'We couldn\'t save the image.';

  @override
  String get profileSupportTimeline => 'History';

  @override
  String get profileSupportStatusOpen => 'Open';

  @override
  String get profileSupportStatusClosed => 'Closed';

  @override
  String get profileSupportStatusPending => 'In review';

  @override
  String get profileSupportStatusResolved => 'Resolved';

  @override
  String get profileSupportEventUpdate => 'Update';

  @override
  String get profileSupportAttachments => 'Images';

  @override
  String get profileSupportNoAttachments => 'No images yet.';

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
      'Your driver is waiting at the pickup point.';

  @override
  String passengerNotifyDriverArrivedBodyNamed(String name) {
    return '$name is waiting at the pickup point.';
  }

  @override
  String get passengerNotifyPickupGraceTitle => 'Wait time is over';

  @override
  String passengerNotifyPickupGraceBody(int minutes) {
    return 'You have $minutes min of grace at the pickup point.';
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
      'Trip alerts and status.';

  @override
  String get passengerNotificationChannelDriverArrivedDescription =>
      'Alerts when the driver arrives at pickup.';

  @override
  String get passengerNotificationChannelChatDescription =>
      'Messages from the active trip chat.';

  @override
  String get passengerNotificationChannelAuthName => 'Account verification';

  @override
  String get passengerNotificationChannelAuthDescription =>
      'Alerts to finish sign-in or registration. Does not include trip updates.';

  @override
  String get passengerNotifyWaVerifiedTitle => 'Verification received';

  @override
  String get passengerNotifyWaVerifiedBody => 'Tap to continue in TEXIAPP.';

  @override
  String get passengerLabsTitle => 'Labs';

  @override
  String get passengerLabsTitleBeta => 'Labs (beta)';

  @override
  String get passengerLabsNotAvailable => 'Not available.';

  @override
  String get passengerLabsGateError => 'Error checking access.';

  @override
  String get passengerLabsDescription => 'Test tools.';

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
      'Review the privacy policy and terms.';

  @override
  String get passengerSettingsAccountSection => 'Account';

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
  String get passengerLegalAuthContinuePrefix =>
      'By continuing, you confirm you are 18 or older and accept our ';

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
      'Your session expired. Sign in and try again.';

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
      'TEXIAPP uses the camera to take your profile photo or attach images in a help request. Photos are sent securely to our servers.';

  @override
  String get passengerPlayGalleryDisclosureTitle => 'Photo library access';

  @override
  String get passengerPlayGalleryDisclosureBody =>
      'TEXIAPP accesses photos you choose from your library for your profile or help requests. Only the image you select is uploaded.';

  @override
  String get passengerPlayNotificationDisclosureTitle => 'Trip notifications';

  @override
  String get passengerPlayNotificationDisclosureBody =>
      'TEXIAPP needs to send you notifications when a driver accepts your trip, trip status changes, or the driver sends a message during an active ride.';

  @override
  String get passengerPlayLocationDisclosureTitle =>
      'Location for trip requests';

  @override
  String get passengerPlayLocationDisclosureBody =>
      'TEXIAPP uses your location to show you on the map, find nearby drivers, and help with pickup at your origin point.';

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
      'Live tracking is available once your trip is underway.';

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
  String get supportTicketsSubtitle => 'Create or review your help requests';

  @override
  String get supportCompanyCallTitle => 'Call TEXIAPP';

  @override
  String get supportCallFailed =>
      'Could not start the call. Check phone permissions.';

  @override
  String get supportTrustFooter =>
      'Your safety comes first. Our team is ready to help you.';

  @override
  String get operatorTexiSubtitle =>
      'Call the operator and learn more about our services.';

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
      'How TEXIAPP validates every driver';

  @override
  String get operatorVerifiedDriversTitle => 'Verified drivers';

  @override
  String get operatorCheckIdentityTitle => 'Identity verified';

  @override
  String get operatorCheckIdentityBody => 'Document and photo reviewed';

  @override
  String get operatorCheckBackgroundTitle => 'Background checks';

  @override
  String get operatorCheckBackgroundBody => 'Security review';

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
  String get operatorCheckTrainingBody => 'TEXIAPP service standards';

  @override
  String get operatorTrustClosing =>
      'Ride with confidence. Drivers verified by TEXIAPP.';

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

  @override
  String get appUpdateRequiredTitle => 'Update required';

  @override
  String get appUpdateRequiredMessage =>
      'A new version of TEXIAPP is available. Update the app to continue.';

  @override
  String get appUpdateOptionalTitle => 'New version available';

  @override
  String get appUpdateOptionalMessage =>
      'An update is available on the Play Store. Install it to get the latest version.';

  @override
  String get appUpdateOpenStore => 'Go to Play Store';

  @override
  String get appUpdateLater => 'Later';

  @override
  String get promoBenefitsTitle => 'Your benefits';

  @override
  String get promoBenefitsEmpty =>
      'When you have an active TEXIAPP benefit, it will show up here.';

  @override
  String get promoBenefitsHeroLead =>
      'Codes, trip support, and what TEXIAPP covers for you.';

  @override
  String get promoBenefitsActiveTitle => 'Active now';

  @override
  String get promoCodeCardLead => 'Use it when you request your next trip.';

  @override
  String get promoReferralCardLead => 'Your guests ride. You get trip support.';

  @override
  String get promoReferralCopied => 'Code copied';

  @override
  String get promoReferralWalletLabel => 'Available support';

  @override
  String promoChipYouPay(String amount) {
    return 'You pay $amount';
  }

  @override
  String get promoConfirmHint =>
      'The trip fare stays the same. You pay less in cash and TEXIAPP covers the difference with the driver.';

  @override
  String get promoCodeLabel => 'Benefit code';

  @override
  String get promoCodeHint => 'Example: TEXI5';

  @override
  String get promoCodeApply => 'Apply code';

  @override
  String get promoCodeApplied => 'Code ready for your next trip.';

  @override
  String get promoCodeUnavailable => 'That code is not available.';

  @override
  String get promoReferralTitle => 'Invite and get trip support';

  @override
  String get promoReferralMine => 'Your code to share';

  @override
  String get promoReferralClaimLabel => 'Code from who referred you';

  @override
  String get promoReferralClaim => 'Save code';

  @override
  String get promoReferralClaimed => 'Code saved.';

  @override
  String get promoReferralUnavailable => 'We could not use that code.';

  @override
  String get promoReferralShare => 'Share';

  @override
  String promoReferralShareMessage(String code) {
    return 'Come ride with TEXIAPP. Use my code $code.';
  }

  @override
  String promoReferralWallet(String amount) {
    return 'Available support: $amount';
  }

  @override
  String promoReferralWalletExpires(String date) {
    return 'Valid until $date';
  }

  @override
  String promoReferralMaxPerTrip(String amount) {
    return 'Up to $amount per trip';
  }

  @override
  String get promoReferralInviteesTitle => 'People who used your code';

  @override
  String get promoReferralInviteePending => 'Waiting for first trip';

  @override
  String get promoReferralInviteeGranted => 'Support credited';

  @override
  String get promoReferralInviteeRejected => 'Not valid';

  @override
  String get promoReferralGraceClosed => 'The window to add a code has closed.';

  @override
  String get tripSupportConfirmHint =>
      'The trip fare stays the same. Our team covers part with TEXIAPP support.';

  @override
  String get promoBenefitsEntry => 'TEXIAPP benefits';
}

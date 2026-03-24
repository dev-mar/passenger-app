import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Texi'**
  String get appName;

  /// No description provided for @splashGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get splashGettingLocation;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your number to continue'**
  String get loginSubtitle;

  /// No description provided for @loginCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get loginCode;

  /// No description provided for @loginPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get loginPhone;

  /// No description provided for @loginCountryCodeHint.
  ///
  /// In en, this message translates to:
  /// **'+591'**
  String get loginCountryCodeHint;

  /// No description provided for @loginPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'7 123 4567'**
  String get loginPhoneHint;

  /// No description provided for @loginContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get loginContinue;

  /// No description provided for @loginErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Check your number.'**
  String get loginErrorInvalidCredentials;

  /// No description provided for @loginPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get loginPhoneRequired;

  /// No description provided for @homeRequestRide.
  ///
  /// In en, this message translates to:
  /// **'Request ride'**
  String get homeRequestRide;

  /// No description provided for @homeNearbyDrivers.
  ///
  /// In en, this message translates to:
  /// **'{count} nearby driver'**
  String homeNearbyDrivers(int count);

  /// No description provided for @homeNearbyDriversNone.
  ///
  /// In en, this message translates to:
  /// **'No nearby drivers at the moment'**
  String get homeNearbyDriversNone;

  /// No description provided for @homeUpdatesEvery.
  ///
  /// In en, this message translates to:
  /// **'Updates every {seconds} seconds'**
  String homeUpdatesEvery(int seconds);

  /// No description provided for @homeLocationError.
  ///
  /// In en, this message translates to:
  /// **'Enable location to see the map and nearby drivers.'**
  String get homeLocationError;

  /// No description provided for @homeLocationErrorGps.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Check GPS.'**
  String get homeLocationErrorGps;

  /// No description provided for @homeRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get homeRetry;

  /// No description provided for @tripOrigin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get tripOrigin;

  /// No description provided for @tripDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get tripDestination;

  /// No description provided for @tripYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your current location'**
  String get tripYourLocation;

  /// No description provided for @tripWherePickup.
  ///
  /// In en, this message translates to:
  /// **'Where should we pick you up?'**
  String get tripWherePickup;

  /// No description provided for @tripUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get tripUseMyLocation;

  /// No description provided for @tripSearchAddress.
  ///
  /// In en, this message translates to:
  /// **'Search address'**
  String get tripSearchAddress;

  /// No description provided for @tripChooseOnMap.
  ///
  /// In en, this message translates to:
  /// **'Choose on map'**
  String get tripChooseOnMap;

  /// No description provided for @tripUseAsPickup.
  ///
  /// In en, this message translates to:
  /// **'Use as pickup point'**
  String get tripUseAsPickup;

  /// No description provided for @tripUseAsDestination.
  ///
  /// In en, this message translates to:
  /// **'Use as destination'**
  String get tripUseAsDestination;

  /// No description provided for @tripMoveMapSetPickup.
  ///
  /// In en, this message translates to:
  /// **'Move the map and tap the button to set where you\'ll be picked up.'**
  String get tripMoveMapSetPickup;

  /// No description provided for @tripMoveMapSetDestination.
  ///
  /// In en, this message translates to:
  /// **'Move the map and tap the button to set the destination.'**
  String get tripMoveMapSetDestination;

  /// No description provided for @tripTapMapDestination.
  ///
  /// In en, this message translates to:
  /// **'Tap the map or choose an option below'**
  String get tripTapMapDestination;

  /// No description provided for @tripSeePrices.
  ///
  /// In en, this message translates to:
  /// **'See prices'**
  String get tripSeePrices;

  /// Clears quote, route and destination before requesting a driver
  ///
  /// In en, this message translates to:
  /// **'Cancel and start over'**
  String get tripCancelQuoteDraft;

  /// No description provided for @tripSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search address...'**
  String get tripSearchPlaceholder;

  /// No description provided for @tripUseMapCenter.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get tripUseMapCenter;

  /// No description provided for @tripWhereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get tripWhereTo;

  /// No description provided for @tripSearchError.
  ///
  /// In en, this message translates to:
  /// **'Address not found'**
  String get tripSearchError;

  /// No description provided for @tripSearchingAddress.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get tripSearchingAddress;

  /// No description provided for @tripNoCoverageInZone.
  ///
  /// In en, this message translates to:
  /// **'We don\'t have service coverage in this area at the moment. Try another location or move to a service zone.'**
  String get tripNoCoverageInZone;

  /// No description provided for @tripNoDriversAvailable.
  ///
  /// In en, this message translates to:
  /// **'No drivers available at the moment. Please try again in a few moments.'**
  String get tripNoDriversAvailable;

  /// No description provided for @tripNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tripNext;

  /// No description provided for @quoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your ride'**
  String get quoteTitle;

  /// No description provided for @quoteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a service type'**
  String get quoteSubtitle;

  /// No description provided for @quotePerTrip.
  ///
  /// In en, this message translates to:
  /// **'per trip'**
  String get quotePerTrip;

  /// No description provided for @quoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get quoteConfirm;

  /// No description provided for @confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your ride'**
  String get confirmTitle;

  /// No description provided for @confirmFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get confirmFrom;

  /// No description provided for @confirmTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get confirmTo;

  /// No description provided for @confirmRequestRide.
  ///
  /// In en, this message translates to:
  /// **'Request ride'**
  String get confirmRequestRide;

  /// No description provided for @searchingTitle.
  ///
  /// In en, this message translates to:
  /// **'Looking for a driver'**
  String get searchingTitle;

  /// No description provided for @searchingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We are finding the best option for you'**
  String get searchingSubtitle;

  /// No description provided for @tripConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to receive trip updates. Check your connection.'**
  String get tripConnectionError;

  /// No description provided for @tripRateDriver.
  ///
  /// In en, this message translates to:
  /// **'Rate your driver'**
  String get tripRateDriver;

  /// No description provided for @tripRateDriverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps us improve the service.'**
  String get tripRateDriverSubtitle;

  /// No description provided for @tripSendRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get tripSendRating;

  /// No description provided for @tripSkipRating.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tripSkipRating;

  /// No description provided for @tripStatusEstimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Approx. time'**
  String get tripStatusEstimatedTime;

  /// No description provided for @tripStatusCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated cost'**
  String get tripStatusCost;

  /// No description provided for @tripStatusFrom.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get tripStatusFrom;

  /// No description provided for @tripStatusTo.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get tripStatusTo;

  /// No description provided for @tripStatusMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String tripStatusMinutes(int count);

  /// No description provided for @tripStatusKm.
  ///
  /// In en, this message translates to:
  /// **'{value} km'**
  String tripStatusKm(String value);

  /// No description provided for @tripStatusDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get tripStatusDriver;

  /// No description provided for @tripStatusVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get tripStatusVehicle;

  /// No description provided for @tripStatusDragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to see trip details'**
  String get tripStatusDragHint;

  /// No description provided for @tripStatusLabelEnRoute.
  ///
  /// In en, this message translates to:
  /// **'Driver on the way'**
  String get tripStatusLabelEnRoute;

  /// No description provided for @tripStatusLabelArrived.
  ///
  /// In en, this message translates to:
  /// **'Driver has arrived'**
  String get tripStatusLabelArrived;

  /// No description provided for @tripStatusLabelStarted.
  ///
  /// In en, this message translates to:
  /// **'Trip in progress'**
  String get tripStatusLabelStarted;

  /// No description provided for @tripStatusLabelCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get tripStatusLabelCompleted;

  /// No description provided for @tripStatusLabelDefault.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get tripStatusLabelDefault;

  /// No description provided for @tripStatusDriverAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned'**
  String get tripStatusDriverAssigned;

  /// Text when driver name is empty or is phone (username)
  ///
  /// In en, this message translates to:
  /// **'TEXI driver'**
  String get tripDriverNameFallback;

  /// No description provided for @tripMapRecenterShort.
  ///
  /// In en, this message translates to:
  /// **'Recenter'**
  String get tripMapRecenterShort;

  /// No description provided for @tripRequireGpsForRequest.
  ///
  /// In en, this message translates to:
  /// **'We need your real location (GPS on and permission granted) to request a ride. Check GPS and location permissions.'**
  String get tripRequireGpsForRequest;

  /// No description provided for @tripConfirmOriginFirst.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your pickup point first.'**
  String get tripConfirmOriginFirst;

  /// No description provided for @tripConfirmOrigin.
  ///
  /// In en, this message translates to:
  /// **'Confirm origin'**
  String get tripConfirmOrigin;

  /// No description provided for @tripConfirmDestination.
  ///
  /// In en, this message translates to:
  /// **'Confirm destination'**
  String get tripConfirmDestination;

  /// No description provided for @tripLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get tripLogout;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To finish registering with {phone}, enter your name. Photo is optional.'**
  String profileSetupSubtitle(String phone);

  /// No description provided for @profileSetupPhotoSoon.
  ///
  /// In en, this message translates to:
  /// **'Photo selection coming soon.'**
  String get profileSetupPhotoSoon;

  /// No description provided for @profileSetupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get profileSetupNameLabel;

  /// No description provided for @profileSetupNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Juan Perez'**
  String get profileSetupNameHint;

  /// No description provided for @profileSetupNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get profileSetupNameRequired;

  /// No description provided for @profileSetupNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters'**
  String get profileSetupNameTooShort;

  /// No description provided for @profileSetupContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get profileSetupContinue;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Title when the same trip is recovered without duplicating POST
  ///
  /// In en, this message translates to:
  /// **'Request restored'**
  String get tripRecoverySnackbarTitle;

  /// Body of SnackBar when reconciling an in-progress trip
  ///
  /// In en, this message translates to:
  /// **'We resumed your current trip.'**
  String get tripRecoverySnackbarBody;

  /// No description provided for @tripRecoverySnackbarAction.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get tripRecoverySnackbarAction;

  /// Shown while syncing trip state after reopening the app
  ///
  /// In en, this message translates to:
  /// **'Restoring your trip…'**
  String get tripRecoveringStateTitle;

  /// No description provided for @verifyCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your number'**
  String get verifyCodeTitle;

  /// No description provided for @verifyCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 4-digit SMS code to {phone}. Enter it to continue.'**
  String verifyCodeSubtitle(String phone);

  /// No description provided for @verifyCodeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'4-digit verification code'**
  String get verifyCodeFieldLabel;

  /// No description provided for @verifyCodeMaskHint.
  ///
  /// In en, this message translates to:
  /// **'••••'**
  String get verifyCodeMaskHint;

  /// No description provided for @verifyCodeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm code'**
  String get verifyCodeConfirm;

  /// No description provided for @verifyCodeRetryHint.
  ///
  /// In en, this message translates to:
  /// **'If you did not receive the SMS, check the number and try again in a few minutes.'**
  String get verifyCodeRetryHint;

  /// No description provided for @profilePhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The photo is too large. Choose another one or take a lower-resolution photo.'**
  String get profilePhotoTooLarge;

  /// No description provided for @profilePhotoPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not select the photo. Please try again.'**
  String get profilePhotoPickFailed;

  /// No description provided for @profilePhotoTake.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get profilePhotoTake;

  /// No description provided for @profilePhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get profilePhotoGallery;

  /// No description provided for @profileReviewInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your information'**
  String get profileReviewInfoTitle;

  /// No description provided for @profileAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get profileAcknowledge;

  String get homeTooltipLanguage;
  String get homeTooltipProfile;
  String get homeLocationMissingTitle;
  String get homeMapMe;
  String homeMapDriverTitle(String id);
  String get profileScreenTitle;
  String get profileStateLoaded;
  String get profileStateLoading;
  String get profileStateEmpty;
  String get profileStateError;
  String get profileStateOffline;
  String get profileEmptyTitle;
  String get profileEmptyBody;
  String get profileCompleteNow;
  String get profileErrorTitle;
  String get profileErrorBody;
  String get profileOfflineTitle;
  String get profileOfflineBody;
  String get profileRefresh;
  String get profileSavedPlaces;
  String get profileRecentPlaces;
  String get placeHome;
  String get placeOffice;
  String get placeFavorite;
  String get placeMainSquare;
  String get placeDowntown;
  String get placeAirport;
  String get placeNorthZone;
  String get quickGps;
  String get quickSearch;
  String get quickMap;
  String get tripMissingDataTitle;
  String get loginReviewDataTitle;
  String get loginContinueA11y;
  String get profileRefreshTooltip;
  String get profileStatesPreviewTooltip;
  String get profileAvatarSemantics;
  String get profileMockInitials;
  String get profileMockName;
  String get profileMockPhone;
  String get profileVerifiedBadge;
  String get profileStatTrips;
  String get profileStatRating;
  String get profileStatSavings;
  String get profileStatTripsValue;
  String get profileStatRatingValue;
  String get profileStatSavingsValue;
  String get profileSectionPersonalData;
  String get profileFieldEmail;
  String get profileFieldDocument;
  String get profileFieldAddress;
  String get profileMockEmail;
  String get profileMockDocument;
  String get profileMockAddress;
  String get profileSectionPreferences;
  String get profileFieldNotifications;
  String get profileFieldNotificationsDesc;
  String get profileFieldDarkMode;
  String get profileFieldDarkModeDesc;
  String get profileSectionSecurity;
  String get profileFieldBiometrics;
  String get profileFieldLastAccess;
  String get profileMockBiometricsValue;
  String get profileMockLastAccessValue;
  String get profileActionEditInfo;
  String get profileActionSupport;
  String get commonEnabled;
  String get commonDisabled;
  String homeDriverDistanceKm(String km);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

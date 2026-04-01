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

  /// No description provided for @loginErrorPhoneRegisteredAsDriver.
  ///
  /// In en, this message translates to:
  /// **'This number is already registered as a driver. Use another number for the passenger app, or sign in with the driver app using this same number.'**
  String get loginErrorPhoneRegisteredAsDriver;

  /// No description provided for @loginErrorPhoneOtherAccountType.
  ///
  /// In en, this message translates to:
  /// **'This number is already linked to another type of Texi account. Use another number or the app that matches that account.'**
  String get loginErrorPhoneOtherAccountType;

  /// No description provided for @loginErrorPhoneDuplicatePassenger.
  ///
  /// In en, this message translates to:
  /// **'We could not start passenger registration with this number. If you already use it as a driver, use the driver app or another number here.'**
  String get loginErrorPhoneDuplicatePassenger;

  /// No description provided for @serviceTypeNameStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get serviceTypeNameStandard;

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

  /// No description provided for @homeProfileQuickAccess.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get homeProfileQuickAccess;

  /// No description provided for @homeProfileQuickAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Account details and profile photo'**
  String get homeProfileQuickAccessSubtitle;

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

  /// No description provided for @tripRbacForbidden.
  ///
  /// In en, this message translates to:
  /// **'Your account doesn’t have permission for this trip action. If it keeps happening, sign out and sign back in or contact support.'**
  String get tripRbacForbidden;

  /// No description provided for @tripRbacSession.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t validate your session. Sign out and sign in again.'**
  String get tripRbacSession;

  /// No description provided for @tripRbacTechnical.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t verify permissions. Please try again in a few seconds.'**
  String get tripRbacTechnical;

  /// No description provided for @tripRealtimeNoToken.
  ///
  /// In en, this message translates to:
  /// **'Your session is invalid or expired. Sign in again to follow the trip.'**
  String get tripRealtimeNoToken;

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

  /// No description provided for @homeTooltipLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get homeTooltipLanguage;

  /// No description provided for @homeTooltipProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get homeTooltipProfile;

  /// No description provided for @homeLocationMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not detect your location'**
  String get homeLocationMissingTitle;

  /// No description provided for @homeMapMe.
  ///
  /// In en, this message translates to:
  /// **'Your position'**
  String get homeMapMe;

  /// No description provided for @homeMapDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver {id}'**
  String homeMapDriverTitle(String id);

  /// No description provided for @profileFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profileFieldPhone;

  /// No description provided for @profileFieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileFieldFullName;

  /// No description provided for @profileSectionBasics.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileSectionBasics;

  /// No description provided for @profilePhotoFromServer.
  ///
  /// In en, this message translates to:
  /// **'Profile photo (server)'**
  String get profilePhotoFromServer;

  /// No description provided for @profileNoServerPhoto.
  ///
  /// In en, this message translates to:
  /// **'No profile photo on file. You can add one when editing your profile.'**
  String get profileNoServerPhoto;

  /// No description provided for @profileErrorNoSession.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Sign in again.'**
  String get profileErrorNoSession;

  /// No description provided for @profileErrorForbidden.
  ///
  /// In en, this message translates to:
  /// **'This action needs a passenger session. Sign out and sign in again with your phone number.'**
  String get profileErrorForbidden;

  /// No description provided for @profileErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'We could not find your passenger profile. If this continues, contact support.'**
  String get profileErrorNotFound;

  /// No description provided for @profileTaglinePassenger.
  ///
  /// In en, this message translates to:
  /// **'Texi passenger'**
  String get profileTaglinePassenger;

  /// No description provided for @profileAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccountLabel;

  /// No description provided for @profileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get profileScreenTitle;

  /// No description provided for @profileStateLoaded.
  ///
  /// In en, this message translates to:
  /// **'State: loaded'**
  String get profileStateLoaded;

  /// No description provided for @profileStateLoading.
  ///
  /// In en, this message translates to:
  /// **'State: loading'**
  String get profileStateLoading;

  /// No description provided for @profileStateEmpty.
  ///
  /// In en, this message translates to:
  /// **'State: empty'**
  String get profileStateEmpty;

  /// No description provided for @profileStateError.
  ///
  /// In en, this message translates to:
  /// **'State: error'**
  String get profileStateError;

  /// No description provided for @profileStateOffline.
  ///
  /// In en, this message translates to:
  /// **'State: offline'**
  String get profileStateOffline;

  /// No description provided for @profileEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get profileEmptyTitle;

  /// No description provided for @profileEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'We could not find profile data yet. You can create it in a few steps.'**
  String get profileEmptyBody;

  /// No description provided for @profileCompleteNow.
  ///
  /// In en, this message translates to:
  /// **'Complete now'**
  String get profileCompleteNow;

  /// No description provided for @profileErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not load your profile'**
  String get profileErrorTitle;

  /// No description provided for @profileErrorBody.
  ///
  /// In en, this message translates to:
  /// **'A temporary issue occurred. Please try again.'**
  String get profileErrorBody;

  /// No description provided for @profileOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get profileOfflineTitle;

  /// No description provided for @profileOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Check your network to sync your profile information.'**
  String get profileOfflineBody;

  /// No description provided for @profileRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get profileRefresh;

  /// No description provided for @profileSavedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get profileSavedPlaces;

  /// No description provided for @profileRecentPlaces.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get profileRecentPlaces;

  /// No description provided for @placeHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get placeHome;

  /// No description provided for @placeOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get placeOffice;

  /// No description provided for @placeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get placeFavorite;

  /// No description provided for @placeMainSquare.
  ///
  /// In en, this message translates to:
  /// **'Main Square'**
  String get placeMainSquare;

  /// No description provided for @placeDowntown.
  ///
  /// In en, this message translates to:
  /// **'Downtown'**
  String get placeDowntown;

  /// No description provided for @placeAirport.
  ///
  /// In en, this message translates to:
  /// **'Airport'**
  String get placeAirport;

  /// No description provided for @placeNorthZone.
  ///
  /// In en, this message translates to:
  /// **'North zone'**
  String get placeNorthZone;

  /// No description provided for @quickGps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get quickGps;

  /// No description provided for @quickSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get quickSearch;

  /// No description provided for @quickMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get quickMap;

  /// No description provided for @tripMissingDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing trip data'**
  String get tripMissingDataTitle;

  /// No description provided for @loginReviewDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your details'**
  String get loginReviewDataTitle;

  /// No description provided for @loginContinueA11y.
  ///
  /// In en, this message translates to:
  /// **'Continue to access'**
  String get loginContinueA11y;

  /// No description provided for @profileRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get profileRefreshTooltip;

  /// No description provided for @profileStatesPreviewTooltip.
  ///
  /// In en, this message translates to:
  /// **'States preview'**
  String get profileStatesPreviewTooltip;

  /// No description provided for @profileAvatarSemantics.
  ///
  /// In en, this message translates to:
  /// **'Passenger avatar'**
  String get profileAvatarSemantics;

  /// No description provided for @profileMockInitials.
  ///
  /// In en, this message translates to:
  /// **'JP'**
  String get profileMockInitials;

  /// No description provided for @profileMockName.
  ///
  /// In en, this message translates to:
  /// **'Juan Perez'**
  String get profileMockName;

  /// No description provided for @profileMockPhone.
  ///
  /// In en, this message translates to:
  /// **'+591 71234567'**
  String get profileMockPhone;

  /// No description provided for @profileVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified account'**
  String get profileVerifiedBadge;

  /// No description provided for @profileStatTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get profileStatTrips;

  /// No description provided for @profileStatRating.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get profileStatRating;

  /// No description provided for @profileStatSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get profileStatSavings;

  /// No description provided for @profileStatTripsValue.
  ///
  /// In en, this message translates to:
  /// **'126'**
  String get profileStatTripsValue;

  /// No description provided for @profileStatRatingValue.
  ///
  /// In en, this message translates to:
  /// **'4.9'**
  String get profileStatRatingValue;

  /// No description provided for @profileStatSavingsValue.
  ///
  /// In en, this message translates to:
  /// **'Bs 340'**
  String get profileStatSavingsValue;

  /// No description provided for @profileSectionPersonalData.
  ///
  /// In en, this message translates to:
  /// **'Personal data'**
  String get profileSectionPersonalData;

  /// No description provided for @profileFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileFieldEmail;

  /// No description provided for @profileFieldDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get profileFieldDocument;

  /// No description provided for @profileFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get profileFieldAddress;

  /// No description provided for @profileMockEmail.
  ///
  /// In en, this message translates to:
  /// **'juan@email.com'**
  String get profileMockEmail;

  /// No description provided for @profileMockDocument.
  ///
  /// In en, this message translates to:
  /// **'1234567 LP'**
  String get profileMockDocument;

  /// No description provided for @profileMockAddress.
  ///
  /// In en, this message translates to:
  /// **'South Zone, La Paz'**
  String get profileMockAddress;

  /// No description provided for @profileSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profileSectionPreferences;

  /// No description provided for @profileFieldNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileFieldNotifications;

  /// No description provided for @profileFieldNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Trip alerts and promotions'**
  String get profileFieldNotificationsDesc;

  /// No description provided for @profileFieldDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get profileFieldDarkMode;

  /// No description provided for @profileFieldDarkModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Premium visual tuning'**
  String get profileFieldDarkModeDesc;

  /// No description provided for @profileSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get profileSectionSecurity;

  /// No description provided for @profileFieldBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get profileFieldBiometrics;

  /// No description provided for @profileFieldLastAccess.
  ///
  /// In en, this message translates to:
  /// **'Last access'**
  String get profileFieldLastAccess;

  /// No description provided for @profileMockBiometricsValue.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get profileMockBiometricsValue;

  /// No description provided for @profileMockLastAccessValue.
  ///
  /// In en, this message translates to:
  /// **'Today, 09:14'**
  String get profileMockLastAccessValue;

  /// No description provided for @profileActionEditInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit information'**
  String get profileActionEditInfo;

  /// No description provided for @profileActionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support and help'**
  String get profileActionSupport;

  /// No description provided for @commonEnabled.
  ///
  /// In en, this message translates to:
  /// **'enabled'**
  String get commonEnabled;

  /// No description provided for @commonDisabled.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get commonDisabled;

  /// No description provided for @homeDriverDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
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

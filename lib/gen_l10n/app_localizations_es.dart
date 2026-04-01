// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Texi';

  @override
  String get splashGettingLocation => 'Obteniendo tu ubicación...';

  @override
  String get loginWelcome => 'Bienvenido';

  @override
  String get loginSubtitle => 'Ingresa tu número para continuar';

  @override
  String get loginCode => 'Código';

  @override
  String get loginPhone => 'Teléfono';

  @override
  String get loginCountryCodeHint => '+591';

  @override
  String get loginPhoneHint => '7 123 4567';

  @override
  String get loginContinue => 'Continuar';

  @override
  String get loginErrorInvalidCredentials =>
      'No se pudo iniciar sesión. Revisa tu número.';

  @override
  String get loginErrorPhoneRegisteredAsDriver =>
      'Este número ya está registrado como conductor. Para la app pasajero usá otro número, o iniciá sesión en la app de conductor con este mismo número.';

  @override
  String get loginErrorPhoneOtherAccountType =>
      'Este número ya está asociado a otro tipo de cuenta en Texi. Usá otro número o la aplicación que corresponda a esa cuenta.';

  @override
  String get loginErrorPhoneDuplicatePassenger =>
      'No pudimos iniciar el registro pasajero con este número. Si ya lo usás como conductor, usá la app de conductor u otro número aquí.';

  @override
  String get serviceTypeNameStandard => 'Estándar';

  @override
  String get loginPhoneRequired => 'Ingresa tu número de teléfono';

  @override
  String get homeRequestRide => 'Solicitar viaje';

  @override
  String get homeProfileQuickAccess => 'Mi perfil';

  @override
  String get homeProfileQuickAccessSubtitle => 'Tus datos y foto de perfil';

  @override
  String homeNearbyDrivers(int count) {
    return '$count conductor cercano';
  }

  @override
  String get homeNearbyDriversNone =>
      'No hay conductores cercanos en este momento';

  @override
  String homeUpdatesEvery(int seconds) {
    return 'Se actualiza cada $seconds segundos';
  }

  @override
  String get homeLocationError =>
      'Activa la ubicación para ver el mapa y conductores cercanos.';

  @override
  String get homeLocationErrorGps =>
      'No se pudo obtener tu ubicación. Revisa el GPS.';

  @override
  String get homeRetry => 'Reintentar';

  @override
  String get tripOrigin => 'Origen';

  @override
  String get tripDestination => 'Destino';

  @override
  String get tripYourLocation => 'Tu ubicación actual';

  @override
  String get tripWherePickup => '¿Dónde te recogemos?';

  @override
  String get tripUseMyLocation => 'Usar mi ubicación actual';

  @override
  String get tripSearchAddress => 'Buscar dirección';

  @override
  String get tripChooseOnMap => 'Elegir en el mapa';

  @override
  String get tripUseAsPickup => 'Usar como punto de recogida';

  @override
  String get tripUseAsDestination => 'Usar como destino';

  @override
  String get tripMoveMapSetPickup =>
      'Mueve el mapa y toca el botón para fijar dónde te recogerán.';

  @override
  String get tripMoveMapSetDestination =>
      'Mueve el mapa y toca el botón para fijar el destino.';

  @override
  String get tripTapMapDestination => 'Toca el mapa o elige una opción abajo';

  @override
  String get tripSeePrices => 'Ver precios';

  @override
  String get tripCancelQuoteDraft => 'Cancelar y empezar de nuevo';

  @override
  String get tripSearchPlaceholder => 'Buscar dirección...';

  @override
  String get tripUseMapCenter => 'Usar esta ubicación';

  @override
  String get tripWhereTo => '¿A dónde vas?';

  @override
  String get tripSearchError => 'No se encontró la dirección';

  @override
  String get tripSearchingAddress => 'Buscando...';

  @override
  String get tripNoCoverageInZone =>
      'No tenemos cobertura del servicio en esta zona por el momento. Prueba en otra ubicación o acércate a una zona de servicio.';

  @override
  String get tripNoDriversAvailable =>
      'No hay conductores disponibles en este momento. Intenta de nuevo en unos instantes.';

  @override
  String get tripNext => 'Siguiente';

  @override
  String get quoteTitle => 'Elige tu viaje';

  @override
  String get quoteSubtitle => 'Selecciona un tipo de servicio';

  @override
  String get quotePerTrip => 'por viaje';

  @override
  String get quoteConfirm => 'Confirmar';

  @override
  String get confirmTitle => 'Confirma tu viaje';

  @override
  String get confirmFrom => 'Desde';

  @override
  String get confirmTo => 'Hasta';

  @override
  String get confirmRequestRide => 'Solicitar viaje';

  @override
  String get searchingTitle => 'Buscando conductor';

  @override
  String get searchingSubtitle => 'Estamos encontrando la mejor opción para ti';

  @override
  String get tripConnectionError =>
      'No se pudo conectar para recibir actualizaciones del viaje. Revisa tu conexión.';

  @override
  String get tripRbacForbidden =>
      'Tu cuenta no tiene permiso para esta acción en viajes. Si sigue pasando, cerrá sesión y volvé a entrar o contactá soporte.';

  @override
  String get tripRbacSession =>
      'No pudimos validar tu sesión. Cerrá sesión y volvé a iniciar sesión.';

  @override
  String get tripRbacTechnical =>
      'Hubo un problema al verificar permisos. Intentá de nuevo en unos segundos.';

  @override
  String get tripRealtimeNoToken =>
      'Sesión inválida o vencida. Volvé a iniciar sesión para seguir el viaje.';

  @override
  String get tripRateDriver => 'Califica a tu conductor';

  @override
  String get tripRateDriverSubtitle =>
      'Tu opinión nos ayuda a mejorar el servicio.';

  @override
  String get tripSendRating => 'Enviar calificación';

  @override
  String get tripSkipRating => 'Omitir';

  @override
  String get tripStatusEstimatedTime => 'Tiempo aprox.';

  @override
  String get tripStatusCost => 'Costo estimado';

  @override
  String get tripStatusFrom => 'Origen';

  @override
  String get tripStatusTo => 'Destino';

  @override
  String tripStatusMinutes(int count) {
    return '$count min';
  }

  @override
  String tripStatusKm(String value) {
    return '$value km';
  }

  @override
  String get tripStatusDriver => 'Conductor';

  @override
  String get tripStatusVehicle => 'Vehículo';

  @override
  String get tripStatusDragHint => 'Desliza para ver los detalles del viaje';

  @override
  String get tripStatusLabelEnRoute => 'Conductor en camino';

  @override
  String get tripStatusLabelArrived => 'El conductor llegó';

  @override
  String get tripStatusLabelStarted => 'Viaje en curso';

  @override
  String get tripStatusLabelCompleted => 'Viaje finalizado';

  @override
  String get tripStatusLabelDefault => 'En camino';

  @override
  String get tripStatusDriverAssigned => 'Conductor asignado';

  @override
  String get tripDriverNameFallback => 'Conductor TEXI';

  @override
  String get tripMapRecenterShort => 'Centrarme';

  @override
  String get tripRequireGpsForRequest =>
      'Necesitamos tu ubicación real (GPS activo y permiso) para solicitar un viaje. Revisa el GPS y los permisos de ubicación.';

  @override
  String get tripConfirmOriginFirst => 'Primero confirma el origen.';

  @override
  String get tripConfirmOrigin => 'Confirmar origen';

  @override
  String get tripConfirmDestination => 'Confirmar destino';

  @override
  String get tripLogout => 'Cerrar sesion';

  @override
  String get profileSetupTitle => 'Completa tu perfil';

  @override
  String profileSetupSubtitle(String phone) {
    return 'Para finalizar tu registro con el número $phone, ingresa tu nombre. La foto es opcional.';
  }

  @override
  String get profileSetupPhotoSoon => 'Selección de foto disponible pronto.';

  @override
  String get profileSetupNameLabel => 'Tu nombre';

  @override
  String get profileSetupNameHint => 'Ej. Juan Pérez';

  @override
  String get profileSetupNameRequired => 'El nombre es obligatorio';

  @override
  String get profileSetupNameTooShort => 'Ingresa al menos 2 caracteres';

  @override
  String get profileSetupContinue => 'Continuar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String get commonError => 'Algo salió mal';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get tripRecoverySnackbarTitle => 'Solicitud recuperada';

  @override
  String get tripRecoverySnackbarBody => 'Continuamos con tu viaje en curso.';

  @override
  String get tripRecoverySnackbarAction => 'Aceptar';

  @override
  String get tripRecoveringStateTitle => 'Recuperando tu viaje…';

  @override
  String get verifyCodeTitle => 'Verifica tu numero';

  @override
  String verifyCodeSubtitle(String phone) {
    return 'Te enviamos un codigo de 4 digitos por SMS a $phone. Ingresalo para continuar.';
  }

  @override
  String get verifyCodeFieldLabel => 'Codigo de verificacion de cuatro digitos';

  @override
  String get verifyCodeMaskHint => '••••';

  @override
  String get verifyCodeConfirm => 'Confirmar codigo';

  @override
  String get verifyCodeRetryHint =>
      'Si no recibiste el SMS, revisa el numero y vuelve a intentar en unos minutos.';

  @override
  String get profilePhotoTooLarge =>
      'La foto es muy pesada. Elige otra o toma una con menor resolucion.';

  @override
  String get profilePhotoPickFailed =>
      'No se pudo seleccionar la foto. Intenta de nuevo.';

  @override
  String get profilePhotoTake => 'Tomar foto';

  @override
  String get profilePhotoGallery => 'Elegir de galeria';

  @override
  String get profileReviewInfoTitle => 'Revisa tu informacion';

  @override
  String get profileAcknowledge => 'Entendido';

  @override
  String get homeTooltipLanguage => 'Cambiar idioma';

  @override
  String get homeTooltipProfile => 'Abrir perfil';

  @override
  String get homeLocationMissingTitle => 'No detectamos tu ubicacion';

  @override
  String get homeMapMe => 'Tu posicion';

  @override
  String homeMapDriverTitle(String id) {
    return 'Conductor $id';
  }

  @override
  String get profileFieldPhone => 'Teléfono';

  @override
  String get profileFieldFullName => 'Nombre';

  @override
  String get profileSectionBasics => 'Cuenta';

  @override
  String get profilePhotoFromServer => 'Foto de perfil (servidor)';

  @override
  String get profileNoServerPhoto =>
      'No hay foto de perfil guardada. Podés agregarla al editar tu perfil.';

  @override
  String get profileErrorNoSession => 'Sesión vencida. Iniciá sesión de nuevo.';

  @override
  String get profileErrorForbidden =>
      'Esta acción requiere sesión de pasajero. Cerrá sesión e ingresá de nuevo con tu número.';

  @override
  String get profileErrorNotFound =>
      'No encontramos tu perfil de pasajero. Si sigue pasando, contactá soporte.';

  @override
  String get profileTaglinePassenger => 'Pasajero Texi';

  @override
  String get profileAccountLabel => 'Cuenta';

  @override
  String get profileScreenTitle => 'Mi perfil';

  @override
  String get profileStateLoaded => 'Estado: cargado';

  @override
  String get profileStateLoading => 'Estado: cargando';

  @override
  String get profileStateEmpty => 'Estado: vacio';

  @override
  String get profileStateError => 'Estado: error';

  @override
  String get profileStateOffline => 'Estado: sin conexion';

  @override
  String get profileEmptyTitle => 'Completa tu perfil';

  @override
  String get profileEmptyBody =>
      'Aun no encontramos datos de perfil. Puedes crearlos en unos pasos.';

  @override
  String get profileCompleteNow => 'Completar ahora';

  @override
  String get profileErrorTitle => 'No pudimos cargar tu perfil';

  @override
  String get profileErrorBody =>
      'Ocurrio un problema temporal. Intenta nuevamente.';

  @override
  String get profileOfflineTitle => 'Sin conexion';

  @override
  String get profileOfflineBody =>
      'Revisa tu red para sincronizar tu informacion de perfil.';

  @override
  String get profileRefresh => 'Actualizar';

  @override
  String get profileSavedPlaces => 'Lugares guardados';

  @override
  String get profileRecentPlaces => 'Recientes';

  @override
  String get placeHome => 'Casa';

  @override
  String get placeOffice => 'Oficina';

  @override
  String get placeFavorite => 'Favorito';

  @override
  String get placeMainSquare => 'Plaza Principal';

  @override
  String get placeDowntown => 'Centro';

  @override
  String get placeAirport => 'Aeropuerto';

  @override
  String get placeNorthZone => 'Zona norte';

  @override
  String get quickGps => 'GPS';

  @override
  String get quickSearch => 'Buscar';

  @override
  String get quickMap => 'Mapa';

  @override
  String get tripMissingDataTitle => 'Faltan datos del viaje';

  @override
  String get loginReviewDataTitle => 'Revisa tus datos';

  @override
  String get loginContinueA11y => 'Continuar al acceso';

  @override
  String get profileRefreshTooltip => 'Actualizar';

  @override
  String get profileStatesPreviewTooltip => 'Vista previa de estados';

  @override
  String get profileAvatarSemantics => 'Avatar del pasajero';

  @override
  String get profileMockInitials => 'JP';

  @override
  String get profileMockName => 'Juan Perez';

  @override
  String get profileMockPhone => '+591 71234567';

  @override
  String get profileVerifiedBadge => 'Cuenta verificada';

  @override
  String get profileStatTrips => 'Viajes';

  @override
  String get profileStatRating => 'Calif.';

  @override
  String get profileStatSavings => 'Ahorro';

  @override
  String get profileStatTripsValue => '126';

  @override
  String get profileStatRatingValue => '4.9';

  @override
  String get profileStatSavingsValue => 'Bs 340';

  @override
  String get profileSectionPersonalData => 'Datos personales';

  @override
  String get profileFieldEmail => 'Correo';

  @override
  String get profileFieldDocument => 'Documento';

  @override
  String get profileFieldAddress => 'Direccion';

  @override
  String get profileMockEmail => 'juan@email.com';

  @override
  String get profileMockDocument => '1234567 LP';

  @override
  String get profileMockAddress => 'Zona Sur, La Paz';

  @override
  String get profileSectionPreferences => 'Preferencias';

  @override
  String get profileFieldNotifications => 'Notificaciones';

  @override
  String get profileFieldNotificationsDesc => 'Alertas de viaje y promociones';

  @override
  String get profileFieldDarkMode => 'Tema oscuro';

  @override
  String get profileFieldDarkModeDesc => 'Ajuste visual premium';

  @override
  String get profileSectionSecurity => 'Seguridad';

  @override
  String get profileFieldBiometrics => 'Biometria';

  @override
  String get profileFieldLastAccess => 'Ultimo acceso';

  @override
  String get profileMockBiometricsValue => 'Activa';

  @override
  String get profileMockLastAccessValue => 'Hoy, 09:14';

  @override
  String get profileActionEditInfo => 'Editar informacion';

  @override
  String get profileActionSupport => 'Soporte y ayuda';

  @override
  String get commonEnabled => 'activado';

  @override
  String get commonDisabled => 'desactivado';

  @override
  String homeDriverDistanceKm(String km) {
    return '$km km';
  }
}

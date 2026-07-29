// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'TEXIAPP';

  @override
  String get splashGettingLocation => 'Obteniendo tu ubicación...';

  @override
  String get loginWelcome => 'Bienvenido';

  @override
  String get loginSubtitle =>
      'Ingresa tu número para iniciar sesión o crear tu cuenta.';

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
      'Este número ya está registrado como conductor. Para la app de pasajero, usa otro número o inicia sesión en la app de conductor con el mismo número.';

  @override
  String get loginErrorPhoneOtherAccountType =>
      'Este número ya está asociado a otro tipo de cuenta en Texi. Usa otro número o la aplicación que corresponda a esa cuenta.';

  @override
  String get loginErrorPhoneDuplicatePassenger =>
      'No pudimos iniciar el registro como pasajero con este número. Si ya lo usas como conductor, usa la app de conductor u otro número aquí.';

  @override
  String get loginErrorVerificationServiceUnavailable =>
      'Servicio de verificación no disponible. Intenta más tarde.';

  @override
  String get loginErrorSessionSuperseded =>
      'Tu sesión se abrió en otro dispositivo.';

  @override
  String get loginErrorTripOperationalLock =>
      'Terminá o cancelá tu viaje actual antes de iniciar sesión en otro dispositivo.';

  @override
  String get serviceTypeNameStandard => 'Estándar';

  @override
  String get serviceTypeNameTwoWheels => 'Moto';

  @override
  String get serviceTypeNameComfort => 'Confort';

  @override
  String get serviceTypeNamePremium => 'Premium';

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
  String get tripCancelQuoteDraft => 'Cancelar la solicitud';

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
  String get tripDraftSearchHint => 'Buscar calle, barrio o lugar';

  @override
  String get tripDraftNoRecentPlaces =>
      'Aún no hay lugares recientes para este punto';

  @override
  String get tripDraftQuoting => 'Obteniendo precios…';

  @override
  String get tripDraftCloseMapPicker => 'Cerrar y buscar o ajustar en el mapa';

  @override
  String get tripDraftCalculatingRoute => 'Calculando la ruta en el mapa…';

  @override
  String get tripDraftEditStop => 'Editar';

  @override
  String get tripSecureChat => 'Chat seguro';

  @override
  String get tripShareRide => 'Compartir viaje';

  @override
  String tripShareMessage(String url, String driverName, String plate) {
    return '¡Hola! Voy en camino a mi destino con TEXIAPP. Sigue mi viaje en tiempo real aquí: $url\n\nConductor: $driverName | Vehículo: ($plate)';
  }

  @override
  String get tripShareError =>
      'No se pudo generar el enlace de seguimiento. Intenta de nuevo.';

  @override
  String get passengerTripChatTitle => 'Chat del viaje';

  @override
  String get passengerTripChatSubtitle =>
      'Conversación activa con el conductor en tiempo real.';

  @override
  String get passengerTripChatOnline => 'En línea';

  @override
  String get passengerTripChatOffline => 'Sin conexión';

  @override
  String get passengerTripChatTemplateCantFindVehicle => 'No veo tu vehículo';

  @override
  String get passengerTripChatTemplateWhereAreYou =>
      '¿Dónde estás exactamente?';

  @override
  String get passengerTripChatTemplateWaitingHere => 'Estoy esperando aquí';

  @override
  String get passengerTripChatNow => 'Ahora';

  @override
  String get passengerTripChatErrorStorage =>
      'Chat no disponible. Contacta a soporte.';

  @override
  String get passengerTripChatErrorPhase =>
      'El chat no está disponible en esta etapa del viaje.';

  @override
  String get passengerTripChatErrorNotReady =>
      'El chat aún no está listo. Intenta en unos segundos.';

  @override
  String passengerTripChatErrorSendReceive(String code) {
    return 'No se pudo enviar el mensaje ($code). Revisa tu conexión.';
  }

  @override
  String get passengerTripChatEmptyState =>
      'Aún no hay mensajes.\nEnvía uno para iniciar la conversación.';

  @override
  String get passengerTripChatMessageHint => 'Escribe un mensaje';

  @override
  String get passengerTripChatSenderYou => 'Tú';

  @override
  String get passengerTripChatSenderDriver => 'Conductor';

  @override
  String get passengerTripChatDriverTemplateAtPickup =>
      'Ya llegué al punto de recogida';

  @override
  String get passengerTripChatDriverTemplateCannotFind =>
      'No logro ubicarte en el punto';

  @override
  String get passengerTripChatDriverTemplateConfirmLocation =>
      'Confirma tu ubicación exacta';

  @override
  String get commonEmptyDash => '—';

  @override
  String get tripNoCoverageInZone =>
      'No tenemos cobertura del servicio en esta zona por el momento. Prueba en otra ubicación o acércate a una zona de servicio.';

  @override
  String get tripNoDriversAvailable =>
      'No encontramos conductores cerca por ahora. Por favor, reintenta en unos minutos.';

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
  String confirmRequestRideWithService(String serviceName) {
    return 'Solicitar $serviceName';
  }

  @override
  String get searchingTitle => 'Buscando conductor';

  @override
  String get searchingSubtitle =>
      'Conectando con los conductores más cercanos.';

  @override
  String get tripSearchingStage2Title => 'Ampliando la búsqueda…';

  @override
  String get tripSearchingStage2Body =>
      'Hay algo de tráfico cerca, pero seguimos buscando la mejor opción para ti.';

  @override
  String get tripSearchingStage3Title => '¿Deseas mantener la búsqueda?';

  @override
  String get tripSearchingStage3Body =>
      'Hay alta demanda en tu zona, pero tu solicitud sigue activa.';

  @override
  String get tripSearchingCancelRequest => 'Cancelar solicitud';

  @override
  String get tripSearchingContinueCta => 'Continuar';

  @override
  String get tripSearchingEtaHint => 'Asignación estimada: 1–3 min';

  @override
  String get tripSearchingRotateCheck2km =>
      'Revisando conductores a 2 km a la redonda…';

  @override
  String get tripSearchingRotateAvailability => 'Consultando disponibilidad…';

  @override
  String get tripSearchingRotateOptimizeRoute => 'Optimizando tu ruta…';

  @override
  String get tripSearchingOfflineBanner =>
      'Sin conexión a internet. Reintentando…';

  @override
  String get tripSearchingLocationBanner =>
      'Activa la ubicación para mejorar la búsqueda.';

  @override
  String get tripSearchingPatienceHint =>
      'Hay algo de tráfico cerca, pero seguimos buscando la mejor opción para ti.';

  @override
  String get tripSearchingLongWaitTitle => '¿Deseas mantener la búsqueda?';

  @override
  String get tripSearchingLongWaitBody =>
      'Hay alta demanda en tu zona, pero tu solicitud sigue activa.';

  @override
  String get tripSearchingKeepWaitingCta => 'Continuar';

  @override
  String get tripConnectionError =>
      'No se pudo conectar para recibir actualizaciones del viaje. Revisa tu conexión.';

  @override
  String get tripRbacForbidden =>
      'Tu cuenta no tiene permiso para esta acción en viajes. Si sigue ocurriendo, cierra sesión y vuelve a entrar, o contacta a soporte.';

  @override
  String get tripRbacSession =>
      'No pudimos validar tu sesión. Cierra sesión y vuelve a iniciar sesión.';

  @override
  String get tripRbacTechnical =>
      'Hubo un problema al verificar permisos. Intenta de nuevo en unos segundos.';

  @override
  String get tripRealtimeNoToken =>
      'Sesión inválida o vencida. Vuelve a iniciar sesión para seguir el viaje.';

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
  String get tripRatingSheetHeaderTitle => 'Viaje completado';

  @override
  String get tripRatingYourRating => 'Tu valoración';

  @override
  String get tripRatingFeedbackPromptLow =>
      '¿Qué afectó tu experiencia? (múltiple)';

  @override
  String get tripRatingFeedbackPromptHigh =>
      '¿Qué destacó del servicio? (múltiple)';

  @override
  String get tripFinishedBackToHome => 'Volver al inicio';

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
  String get tripSavedPlaceFallbackLabel => 'Lugar';

  @override
  String tripSavedPlacesMax(int count) {
    return 'Máximo $count lugares.';
  }

  @override
  String get tripSavedPlaceDialogTitle => 'Nuevo lugar guardado';

  @override
  String get tripSavedPlaceNameLabel => 'Nombre';

  @override
  String get tripSavedPlaceNameHint => 'Ej.: Casa, Trabajo';

  @override
  String get tripSavedPlaceSaveCta => 'Guardar';

  @override
  String get tripSavedPlaceSaved => 'Lugar guardado';

  @override
  String tripSavedPlacesLimitReached(int count) {
    return 'Límite de $count lugares alcanzado.';
  }

  @override
  String get tripSavedPlaceSaveMapCta => 'Guardar ubicación en el mapa';

  @override
  String get tripSavedPlaceDeleteCta => 'Eliminar';

  @override
  String get tripMapAdjustPickupHint =>
      'Ajusta el mapa para definir tu punto de partida';

  @override
  String get tripMapAdjustDestinationHint =>
      'Ajusta el mapa para definir tu destino';

  @override
  String get tripMapPinHintOriginShort => 'Partida: mueve el mapa y confirma';

  @override
  String get tripMapPinHintDestShort => 'Destino: mueve el mapa y confirma';

  @override
  String get tripMapPinSearchInstead => 'Buscar';

  @override
  String get tripDraftSaveOriginShortcut => 'Guardar partida en favoritos';

  @override
  String get tripDraftSaveDestinationShortcut => 'Guardar destino en favoritos';

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
  String get tripLogout => 'Cerrar sesión';

  @override
  String get menuLeaveAppTitle => '¿Seguro que deseas salir?';

  @override
  String get menuLeaveAppMessage =>
      'Tu verificación seguirá activa cuando vuelvas.';

  @override
  String get menuLeaveAppConfirm => 'Salir de la app';

  @override
  String get menuLeaveAppLogout => 'Cerrar sesión';

  @override
  String get menuLogoutConfirmTitle => '¿Cerrar sesión?';

  @override
  String get menuLogoutConfirmMessage =>
      'Tendrás que verificar tu usuario de nuevo al volver.';

  @override
  String get menuLogoutConfirmAction => 'Cerrar sesión';

  @override
  String get menuLogoutConfirmBack => 'Volver';

  @override
  String get profileSettingsTitle => 'Ajustes';

  @override
  String get profileLogoutSubtitle => 'Salir de la cuenta actual';

  @override
  String get tripHistoryMenu => 'Historial';

  @override
  String get tripHistoryTitle => 'Historial de viajes';

  @override
  String get tripHistoryFilterAll => 'Todos';

  @override
  String get tripHistoryFilterCompleted => 'Completados';

  @override
  String get tripHistoryFilterCancelled => 'Cancelados';

  @override
  String get tripHistoryFilterInProgress => 'En curso';

  @override
  String get tripHistoryDateAll => 'Todo el tiempo';

  @override
  String get tripHistoryDateToday => 'Hoy';

  @override
  String get tripHistoryDate7d => 'Últimos 7 días';

  @override
  String get tripHistoryDate30d => 'Últimos 30 días';

  @override
  String get tripHistoryStatusCompleted => 'Completado';

  @override
  String get tripHistoryStatusCancelled => 'Cancelado';

  @override
  String get tripHistoryStatusInProgress => 'En curso';

  @override
  String get tripHistoryDateCustom => 'Personalizado';

  @override
  String get tripHistoryActiveFilters => 'Filtros activos';

  @override
  String get tripHistoryCustomRangeLabel => 'Rango elegido';

  @override
  String get tripHistorySectionToday => 'Hoy';

  @override
  String get tripHistorySectionYesterday => 'Ayer';

  @override
  String get tripHistorySectionOlder => 'Anteriores';

  @override
  String get tripHistoryEmpty => 'Aún no tienes viajes en este filtro.';

  @override
  String get tripHistoryLoadError =>
      'No se pudo cargar tu historial. Intenta nuevamente.';

  @override
  String get tripHistoryNoSession =>
      'Tu sesión expiró. Vuelve a iniciar sesión.';

  @override
  String get tripHistoryPrevPage => 'Anterior';

  @override
  String get tripHistoryNextPage => 'Siguiente';

  @override
  String get tripHistoryPricePending => 'Sin monto';

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
  String get tripRecoveringStuckTitle => 'No pudimos recuperar tu viaje';

  @override
  String get tripRecoveringStuckBody =>
      'Tu viaje sigue activo. Revisa tu conexión e intenta de nuevo. No uses Cancelar: eso solo aplica mientras se busca conductor.';

  @override
  String get tripRecoveringCheckNetwork => 'Conexión a internet';

  @override
  String get tripRecoveringCheckLocation => 'Permiso y GPS de ubicación';

  @override
  String get tripRecoveringRetryCta => 'Reintentar reconexión';

  @override
  String get tripCancelBlockedActiveBody =>
      'Tu viaje ya está en curso. No se puede cancelar desde aquí.';

  @override
  String get verifyCodeTitle => 'Verifica tu número';

  @override
  String verifyCodeSubtitle(String phone) {
    return 'Te enviamos un código de 6 dígitos a $phone. Ingrésalo para continuar.';
  }

  @override
  String get verifyCodeFieldLabel => 'Código de verificación de seis dígitos';

  @override
  String get verifyCodeMaskHint => '••••••';

  @override
  String get verifyCodeWaTitle => 'Verificá con WhatsApp';

  @override
  String verifyCodeWaSubtitle(String phone) {
    return 'Enviá el mensaje prellenado desde WhatsApp para confirmar $phone.';
  }

  @override
  String get verifyCodeWaOpenButton => 'Abrir WhatsApp';

  @override
  String get verifyCodeWaWaiting => 'Esperando tu mensaje en WhatsApp…';

  @override
  String get verifyCodeWaFallbackHint =>
      '¿Problemas? Podés ingresar el código manualmente abajo.';

  @override
  String get verifyCodeConfirm => 'Confirmar código';

  @override
  String get verifyCodeRetryHint =>
      'Si no recibiste el código, revisa el número y vuelve a intentar en unos minutos.';

  @override
  String get verifyCodeErrorActivateAccount =>
      'No se pudo activar la cuenta de pasajero.';

  @override
  String get verifyCodeErrorIncompleteResponse =>
      'Respuesta incompleta del servidor.';

  @override
  String get verifyCodeErrorTokenMissing => 'No se recibió token.';

  @override
  String get verifyCodeErrorNetwork =>
      'No se pudo conectar. Revisa tu internet e intenta de nuevo.';

  @override
  String get verifyCodeErrorConnection =>
      'Sin conexión con el servidor. Verifica tu red.';

  @override
  String get verifyCodeErrorInvalidCodeInput =>
      'Ingresa el código de 6 dígitos que recibiste.';

  @override
  String get verifyCodeErrorValidateCode => 'No se pudo validar el código.';

  @override
  String get verifyCodeErrorUnexpected =>
      'Error inesperado al validar el código.';

  @override
  String get profileSetupErrorCompleteRegistration =>
      'No se pudo completar el registro.';

  @override
  String get profileSetupErrorNetwork =>
      'No se pudo conectar. Revisa tu internet e intenta de nuevo.';

  @override
  String get profileSetupErrorConnection =>
      'Sin conexión con el servidor. Verifica tu red.';

  @override
  String profileSetupErrorRegisterStatus(String status) {
    return 'Error $status al registrar el perfil.';
  }

  @override
  String get profilePhotoTooLarge =>
      'La foto es muy pesada. Elige otra o toma una con menor resolución.';

  @override
  String get profilePhotoPickFailed =>
      'No se pudo seleccionar la foto. Intenta de nuevo.';

  @override
  String get profilePhotoTake => 'Tomar foto';

  @override
  String get profilePhotoGallery => 'Elegir de galería';

  @override
  String get profilePhotoCropTitle => 'Ajustar selfie';

  @override
  String get profileReviewInfoTitle => 'Revisa tu información';

  @override
  String get profileAcknowledge => 'Entendido';

  @override
  String get homeTooltipLanguage => 'Cambiar idioma';

  @override
  String get homeTooltipProfile => 'Abrir perfil';

  @override
  String get homeLocationMissingTitle => 'No detectamos tu ubicación';

  @override
  String get homeMapMe => 'Tu posición';

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
      'No hay foto de perfil guardada. Puedes agregarla al editar tu perfil.';

  @override
  String get profileErrorNoSession => 'Sesión vencida. Inicia sesión de nuevo.';

  @override
  String get profileErrorForbidden =>
      'Esta acción requiere sesión de pasajero. Cierra sesión e ingresa de nuevo con tu número.';

  @override
  String get profileErrorNotFound =>
      'No encontramos tu perfil de pasajero. Si sigue ocurriendo, contacta a soporte.';

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
  String get profileStateEmpty => 'Estado: vacío';

  @override
  String get profileStateError => 'Estado: error';

  @override
  String get profileStateOffline => 'Estado: sin conexión';

  @override
  String get profileEmptyTitle => 'Completa tu perfil';

  @override
  String get profileEmptyBody =>
      'Aún no encontramos datos de perfil. Puedes crearlos en unos pasos.';

  @override
  String get profileCompleteNow => 'Completar ahora';

  @override
  String get profileErrorTitle => 'No pudimos cargar tu perfil';

  @override
  String get profileErrorBody =>
      'Ocurrió un problema temporal. Intenta nuevamente.';

  @override
  String get profileOfflineTitle => 'Sin conexión';

  @override
  String get profileOfflineBody =>
      'Revisa tu red para sincronizar tu información de perfil.';

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
  String get profileMockName => 'Juan Pérez';

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
  String get profileStatSavingsValue => 'BOB 340';

  @override
  String get profileSectionPersonalData => 'Datos personales';

  @override
  String get profileFieldEmail => 'Correo';

  @override
  String get profileFieldDocument => 'Documento';

  @override
  String get profileFieldAddress => 'Dirección';

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
  String get profileFieldBiometrics => 'Biometría';

  @override
  String get profileFieldLastAccess => 'Último acceso';

  @override
  String get profileSecurityNotAvailable => 'No disponible';

  @override
  String get profileMockBiometricsValue => 'Activa';

  @override
  String get profileMockLastAccessValue => 'Hoy, 09:14';

  @override
  String get profileActionEditInfo => 'Editar información';

  @override
  String get profileActionSupport => 'Seguridad';

  @override
  String get profileQuickActions => 'Acciones rápidas';

  @override
  String get profileEditDisplayNameLabel => 'Nombre visible';

  @override
  String get profileEditNameInvalid => 'Ingresa un nombre válido';

  @override
  String get profileEditSaveFailed => 'No se pudo guardar';

  @override
  String get profileEditSaving => 'Guardando...';

  @override
  String get profileEditSaveChanges => 'Guardar cambios';

  @override
  String get profileSupportCenterTitle => 'Centro de soporte';

  @override
  String get profileSupportCategoryGeneral => 'General';

  @override
  String get profileSupportCategoryTrip => 'Viaje';

  @override
  String get profileSupportCategoryPayment => 'Pago';

  @override
  String get profileSupportCategoryAccount => 'Cuenta';

  @override
  String get profileSupportCategorySafety => 'Seguridad';

  @override
  String get profileSupportCategoryTechnical => 'Técnico';

  @override
  String get profileSupportCategoryLabel => 'Categoría';

  @override
  String get profileSupportSubjectLabel => 'Asunto';

  @override
  String get profileSupportDetailLabel => 'Detalle';

  @override
  String get profileSupportValidationError =>
      'Completa asunto y detalle (mín. 3/10 caracteres).';

  @override
  String get profileSupportCreateFailed => 'No se pudo crear ticket';

  @override
  String get profileSupportSentSuccess => 'Ticket enviado correctamente';

  @override
  String get profileSupportSending => 'Enviando...';

  @override
  String get profileSupportSendTicket => 'Enviar ticket';

  @override
  String get profileSupportRecentTickets => 'Mis tickets recientes';

  @override
  String get profileSupportNoTickets => 'Aún no tienes tickets registrados.';

  @override
  String get profileSupportTicketsLoadFailed => 'No se pudo cargar tickets';

  @override
  String profileSupportTicketStatusChanged(String ticketNumber, String status) {
    return 'Ticket $ticketNumber cambió a $status';
  }

  @override
  String get profileSupportDetailLoadFailed => 'No se pudo cargar detalle';

  @override
  String get profileSupportAttachUploading => 'Subiendo...';

  @override
  String get profileSupportAttachImage => 'Adjuntar imagen';

  @override
  String get profileSupportAttachSuccess => 'Adjunto subido correctamente';

  @override
  String get profileSupportAttachPrepFailed => 'No se pudo preparar adjunto';

  @override
  String get profileSupportPresignInvalid => 'Respuesta de presign inválida';

  @override
  String get profileSupportAttachRegisterFailed =>
      'No se pudo registrar adjunto';

  @override
  String get profileSupportTimeline => 'Timeline';

  @override
  String get profileSupportAttachments => 'Adjuntos';

  @override
  String get profileSupportNoAttachments => 'Sin adjuntos';

  @override
  String get passengerRatingFallbackDelay => 'Tardó en llegar';

  @override
  String get passengerRatingFallbackRoute => 'Ruta poco conveniente';

  @override
  String get passengerRatingFallbackCleanliness => 'Vehículo poco cómodo';

  @override
  String get passengerRatingFallbackAttitude => 'Trato mejorable';

  @override
  String get passengerRatingFallbackOther => 'Otro motivo';

  @override
  String get passengerRatingFallbackSafe => 'Conducción segura';

  @override
  String get passengerRatingFallbackClean => 'Vehículo limpio';

  @override
  String get passengerRatingFallbackKind => 'Muy amable';

  @override
  String get passengerRatingFallbackPunctual => 'Llegó rápido';

  @override
  String get passengerRatingFallbackExcellent => 'Excelente servicio';

  @override
  String get passengerNotifyArrivalReminder =>
      'Tu conductor te espera en el punto de recogida.';

  @override
  String get passengerNotifyDriverArrivedTitle => 'Tu conductor llegó';

  @override
  String get passengerNotifyDriverArrivedBody =>
      'Te espera en el punto de recogida.';

  @override
  String passengerNotifyDriverArrivedBodyNamed(String name) {
    return '$name te espera en el punto de recogida.';
  }

  @override
  String get passengerNotifyChatNewTitle => 'Mensaje del viaje';

  @override
  String get passengerNotifyChatSenderDriver => 'Conductor';

  @override
  String get passengerNotifyChatSenderPassenger => 'Pasajero';

  @override
  String get passengerNotificationChannelName => 'Actualizaciones de viaje';

  @override
  String get passengerNotificationChannelDescription =>
      'Notificaciones de estado de viaje para pasajero.';

  @override
  String get passengerNotificationChannelFcmDescription =>
      'Avisos FCM y estado de viaje.';

  @override
  String get passengerNotificationChannelDriverArrivedDescription =>
      'Avisos cuando el conductor llega al punto de recogida.';

  @override
  String get passengerNotificationChannelChatDescription =>
      'Mensajes de chat del viaje activo.';

  @override
  String get passengerLabsTitle => 'Labs';

  @override
  String get passengerLabsTitleBeta => 'Labs (beta)';

  @override
  String get passengerLabsNotAvailable => 'No disponible.';

  @override
  String get passengerLabsGateError => 'Error al comprobar acceso.';

  @override
  String get passengerLabsDescription =>
      'Espacio reservado para pruebas de producto (mapa, sockets, flags). El icono de matraz en Home solo aparece con número QA o dart-define.';

  @override
  String tripHistoryDriverName(String name) {
    return 'Conductor: $name';
  }

  @override
  String tripHistoryVehicleDetails(String details) {
    return 'Vehículo: $details';
  }

  @override
  String tripHistoryCreatedTime(String time) {
    return 'Hora: $time';
  }

  @override
  String tripHistoryTripId(String id) {
    return 'ID: $id';
  }

  @override
  String get commonEnabled => 'activado';

  @override
  String get commonDisabled => 'desactivado';

  @override
  String homeDriverDistanceKm(String km) {
    return '$km km';
  }

  @override
  String get passengerLegalSectionTitle => 'Legal y privacidad';

  @override
  String get passengerLegalSectionSubtitle =>
      'Consulta los documentos aplicables a tu cuenta y gestiona tus datos.';

  @override
  String get passengerLegalPrivacyPolicy => 'Política de privacidad';

  @override
  String get passengerLegalTermsOfService => 'Términos de servicio';

  @override
  String get passengerLegalDeleteAccountTitle => 'Eliminar cuenta';

  @override
  String get passengerLegalDeleteAccountBody =>
      'Puedes eliminar tu cuenta desde la app o consultar la información oficial para completar la solicitud.';

  @override
  String get passengerLegalDeleteAccountAction => 'Ver cómo solicitar';

  @override
  String get passengerLegalDeleteAccountConfirmNow => 'Programar eliminación';

  @override
  String get passengerLegalDeleteAccountDeleting => 'Programando eliminación…';

  @override
  String get passengerLegalDeleteAccountScheduledSuccess =>
      'Eliminación programada. Tu sesión se cerró; inicia sesión para recuperar tu cuenta antes de la fecha límite.';

  @override
  String passengerLegalDeleteAccountBodyGrace(int graceDays) {
    return 'Tu cuenta entrará en eliminación programada durante $graceDays días. Al confirmar se cerrará tu sesión y no podrás usar la app. Para recuperarla, inicia sesión con tu número y cancela la solicitud antes de la fecha límite.';
  }

  @override
  String get passengerLegalLoginHint =>
      'Al continuar, aceptas nuestra Política de privacidad y Términos de servicio.';

  @override
  String get passengerLegalRegistrationHint =>
      'Antes de continuar, revisa la Política de privacidad y los Términos de servicio.';

  @override
  String get passengerLegalLoginPrefix => 'Al continuar, aceptas nuestra ';

  @override
  String get passengerLegalRegistrationPrefix =>
      'Antes de continuar, revisa nuestra ';

  @override
  String get passengerLegalLoginConjunction => ' y ';

  @override
  String get passengerLoginAccountDeletionPendingTitle =>
      'Eliminación programada';

  @override
  String passengerLoginAccountDeletionPendingBody(String effectiveDate) {
    return 'Esta cuenta tiene una eliminación programada para el $effectiveDate. No puedes usar la app hasta recuperarla.';
  }

  @override
  String get passengerLoginAccountDeletionPendingDateFallback =>
      'la fecha indicada';

  @override
  String get passengerLoginAccountDeletionRecover => 'Recuperar cuenta';

  @override
  String get passengerLoginAccountDeletionDismiss => 'Entendido';

  @override
  String get passengerLoginAccountDeletionRecovering => 'Recuperando cuenta…';

  @override
  String get passengerLoginAccountDeletionRecoverSuccess =>
      'Cuenta recuperada. Bienvenido de nuevo.';

  @override
  String get passengerLegalDeleteAccountPendingTitle =>
      'Eliminación programada';

  @override
  String passengerLegalDeleteAccountPendingBody(
    String effectiveDate,
    int daysRemaining,
  ) {
    return 'Tu cuenta se eliminará el $effectiveDate. Quedan $daysRemaining días para cancelar y reactivar tu acceso.';
  }

  @override
  String get passengerLegalDeleteAccountPendingDateFallback =>
      'la fecha indicada';

  @override
  String get passengerLegalDeleteAccountCancelAction => 'Cancelar eliminación';

  @override
  String get passengerLegalDeleteAccountCancelling => 'Cancelando eliminación…';

  @override
  String get passengerLegalDeleteAccountCancelSuccess =>
      'Eliminación cancelada. Tu cuenta sigue activa.';

  @override
  String get passengerAccountDeletionErrorSessionExpired =>
      'Sesión expirada. Inicia sesión e intenta de nuevo.';

  @override
  String get passengerAccountDeletionErrorScheduleFailed =>
      'No se pudo programar la eliminación.';

  @override
  String get passengerAccountDeletionErrorCancelFailed =>
      'No se pudo cancelar la eliminación.';

  @override
  String get passengerPlayCameraDisclosureTitle => 'Acceso a la cámara';

  @override
  String get passengerPlayCameraDisclosureBody =>
      'Texi usa la cámara para tomar tu foto de perfil o adjuntar imágenes en soporte. Las fotos se envían de forma segura a nuestros servidores.';

  @override
  String get passengerPlayGalleryDisclosureTitle => 'Acceso a fotos';

  @override
  String get passengerPlayGalleryDisclosureBody =>
      'Texi accede a fotos que elijas de tu galería para tu perfil o tickets de soporte. Solo se sube la imagen que selecciones.';

  @override
  String get passengerPlayNotificationDisclosureTitle =>
      'Notificaciones de viaje';

  @override
  String get passengerPlayNotificationDisclosureBody =>
      'Texi necesita enviarte notificaciones cuando un conductor acepte tu viaje, cambie el estado del trayecto o te envíe un mensaje durante el viaje.';

  @override
  String get passengerPlayLocationDisclosureTitle =>
      'Ubicación para solicitar viajes';

  @override
  String get passengerPlayLocationDisclosureBody =>
      'Texi usa tu ubicación para mostrarte en el mapa, encontrar conductores cercanos y facilitar la recogida en el punto de origen.';

  @override
  String get passengerPlayDisclosureContinue => 'Continuar';

  @override
  String get passengerPlayNotificationDisclosureRequired =>
      'Activa las notificaciones para recibir avisos de tu viaje.';

  @override
  String get menuSupportHelp => 'Seguridad';

  @override
  String get menuOperatorTexi => 'Operador';

  @override
  String get menuProfile => 'Perfil';

  @override
  String get menuTripHistory => 'Mis viajes';

  @override
  String get menuOpenTooltip => 'Menú';

  @override
  String get safetyEmergencyCta => 'Emergencia';

  @override
  String get safetyLiveTrackingTitle => 'Seguimiento en tiempo real';

  @override
  String get safetyLiveTrackingUnavailable =>
      'Esta función solo está disponible cuando tu viaje ya está en curso.';

  @override
  String get supportHelpSubtitle => 'Emergencia y asistencia 24/7';

  @override
  String get supportEmergencyTitle => 'Emergencia';

  @override
  String supportEmergencyBody(String number) {
    return 'Si estás en peligro o necesitas ayuda inmediata, llama al $number.';
  }

  @override
  String get supportCallNowCta => 'LLAMAR AHORA';

  @override
  String get supportMoreOptionsTitle => 'Más opciones de ayuda';

  @override
  String get supportWhatsAppTitle => 'WhatsApp';

  @override
  String get supportTicketsSubtitle => 'Crea o revisa tickets de soporte';

  @override
  String get supportCompanyCallTitle => 'Llamar a Texi';

  @override
  String get supportCallFailed =>
      'No se pudo abrir la llamada. Revisa los permisos del teléfono.';

  @override
  String get supportTrustFooter =>
      'Tu seguridad es prioridad. Operadores y protocolos listos para asistirte.';

  @override
  String get operatorTexiSubtitle =>
      'Contacta con nuestros Operadores y conoce más de nuestros servicios.';

  @override
  String get operatorSecurityCtaTitle => 'Seguridad';

  @override
  String get operatorSecurityCtaSubtitle => 'Emergencia 110 y asistencia';

  @override
  String get operatorSecurityCareMessage =>
      'Tu seguridad nos importa. Estamos aquí para cuidarte en cada viaje.';

  @override
  String get operatorCallTitle => 'Llamar a operadora';

  @override
  String get operatorVerifiedDriversCtaTitle => 'Conductores verificados';

  @override
  String get operatorVerifiedDriversCtaSubtitle =>
      'Cómo TEXI valida a cada conductor';

  @override
  String get operatorVerifiedDriversTitle => 'Conductores verificados';

  @override
  String get operatorCheckIdentityTitle => 'Identidad validada';

  @override
  String get operatorCheckIdentityBody => 'Documento y foto revisados';

  @override
  String get operatorCheckBackgroundTitle => 'Antecedentes';

  @override
  String get operatorCheckBackgroundBody => 'Filtros de seguridad aplicados';

  @override
  String get operatorCheckInspectionTitle => 'Inspección del vehículo';

  @override
  String get operatorCheckInspectionBody => 'Estado y documentación al día';

  @override
  String get operatorCheckInsuranceTitle => 'Seguro vigente';

  @override
  String get operatorCheckInsuranceBody => 'Cobertura activa para el servicio';

  @override
  String get operatorCheckTrainingTitle => 'Capacitación';

  @override
  String get operatorCheckTrainingBody => 'Estándares de servicio Texi';

  @override
  String get operatorTrustClosing =>
      'Viaja con confianza. Conductores verificados por Texi.';

  @override
  String get profileCompletenessTitle => 'Completa tu información';

  @override
  String profileCompletenessMissing(int count) {
    return 'Faltan $count datos por completar';
  }

  @override
  String get profileCompletenessDone => 'Tu perfil está completo';

  @override
  String get profileCompleteInfoCta => 'COMPLETAR INFORMACIÓN';

  @override
  String get profileVerifiedUserLabel => 'Usuario verificado';

  @override
  String get profileBrandTitle => 'TEXIAPP';
}

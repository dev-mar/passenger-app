import 'package:url_launcher/url_launcher.dart';

/// Contactos oficiales Texi (pasajero).
class PassengerCompanyContacts {
  PassengerCompanyContacts._();

  static const String companyPhoneE164 = '+59177010777';
  static const String companyPhoneDisplay = '+591 7701 0777';
  static const String emergencyNumber = '110';
  static const String emergencyDisplay = '110';

  static Uri companyTelUri() => Uri(scheme: 'tel', path: companyPhoneE164);

  static Uri emergencyTelUri() => Uri(scheme: 'tel', path: emergencyNumber);

  static Uri companyWhatsAppUri() =>
      Uri.parse('https://wa.me/59177010777');

  static Future<bool> callCompany() =>
      launchUrl(companyTelUri(), mode: LaunchMode.externalApplication);

  static Future<bool> callEmergency() =>
      launchUrl(emergencyTelUri(), mode: LaunchMode.externalApplication);

  static Future<bool> openCompanyWhatsApp() =>
      launchUrl(companyWhatsAppUri(), mode: LaunchMode.externalApplication);
}

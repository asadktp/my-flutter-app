import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 2)
class SettingsModel extends HiveObject {
  @HiveField(0)
  String orgName;

  @HiveField(1)
  String address;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String email;

  @HiveField(4)
  String? logoPath;

  @HiveField(5)
  String defaultCurrency;

  @HiveField(6)
  String? whatsappNumber;

  @HiveField(7)
  bool isBiometricEnabled;

  @HiveField(8)
  String? pinCode;

  @HiveField(9)
  String receiptFooterMessage;

  SettingsModel({
    this.orgName = 'Organization Name',
    this.address = '123 Charity Street, City, State',
    this.phone = '+91 9876543210',
    this.email = 'info@donation.org',
    this.logoPath,
    this.defaultCurrency = 'INR',
    this.whatsappNumber,
    this.isBiometricEnabled = false,
    this.pinCode,
    this.receiptFooterMessage = 'Thank you for your generous donation!',
  });
}

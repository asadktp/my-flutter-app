// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 2;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      orgName: fields[0] as String,
      address: fields[1] as String,
      phone: fields[2] as String,
      email: fields[3] as String,
      logoPath: fields[4] as String?,
      defaultCurrency: fields[5] as String,
      whatsappNumber: fields[6] as String?,
      isBiometricEnabled: fields[7] as bool,
      pinCode: fields[8] as String?,
      receiptFooterMessage: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.orgName)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.logoPath)
      ..writeByte(5)
      ..write(obj.defaultCurrency)
      ..writeByte(6)
      ..write(obj.whatsappNumber)
      ..writeByte(7)
      ..write(obj.isBiometricEnabled)
      ..writeByte(8)
      ..write(obj.pinCode)
      ..writeByte(9)
      ..write(obj.receiptFooterMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

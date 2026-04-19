// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DeviceInfoTable extends DeviceInfo
    with TableInfo<$DeviceInfoTable, DeviceInfoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceInfoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _branchMeta = const VerificationMeta('branch');
  @override
  late final GeneratedColumn<String> branch = GeneratedColumn<String>(
      'branch', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _areaMeta = const VerificationMeta('area');
  @override
  late final GeneratedColumn<String> area = GeneratedColumn<String>(
      'area', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _registeredAtMeta =
      const VerificationMeta('registeredAt');
  @override
  late final GeneratedColumn<int> registeredAt = GeneratedColumn<int>(
      'registered_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, deviceId, branch, area, registeredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_info';
  @override
  VerificationContext validateIntegrity(Insertable<DeviceInfoData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('branch')) {
      context.handle(_branchMeta,
          branch.isAcceptableOrUnknown(data['branch']!, _branchMeta));
    }
    if (data.containsKey('area')) {
      context.handle(
          _areaMeta, area.isAcceptableOrUnknown(data['area']!, _areaMeta));
    }
    if (data.containsKey('registered_at')) {
      context.handle(
          _registeredAtMeta,
          registeredAt.isAcceptableOrUnknown(
              data['registered_at']!, _registeredAtMeta));
    } else if (isInserting) {
      context.missing(_registeredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceInfoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceInfoData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      branch: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch'])!,
      area: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}area'])!,
      registeredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}registered_at'])!,
    );
  }

  @override
  $DeviceInfoTable createAlias(String alias) {
    return $DeviceInfoTable(attachedDatabase, alias);
  }
}

class DeviceInfoData extends DataClass implements Insertable<DeviceInfoData> {
  final int id;
  final String deviceId;
  final String branch;
  final String area;

  /// Unix timestamp (seconds).
  final int registeredAt;
  const DeviceInfoData(
      {required this.id,
      required this.deviceId,
      required this.branch,
      required this.area,
      required this.registeredAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['branch'] = Variable<String>(branch);
    map['area'] = Variable<String>(area);
    map['registered_at'] = Variable<int>(registeredAt);
    return map;
  }

  DeviceInfoCompanion toCompanion(bool nullToAbsent) {
    return DeviceInfoCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      branch: Value(branch),
      area: Value(area),
      registeredAt: Value(registeredAt),
    );
  }

  factory DeviceInfoData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceInfoData(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      branch: serializer.fromJson<String>(json['branch']),
      area: serializer.fromJson<String>(json['area']),
      registeredAt: serializer.fromJson<int>(json['registeredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'branch': serializer.toJson<String>(branch),
      'area': serializer.toJson<String>(area),
      'registeredAt': serializer.toJson<int>(registeredAt),
    };
  }

  DeviceInfoData copyWith(
          {int? id,
          String? deviceId,
          String? branch,
          String? area,
          int? registeredAt}) =>
      DeviceInfoData(
        id: id ?? this.id,
        deviceId: deviceId ?? this.deviceId,
        branch: branch ?? this.branch,
        area: area ?? this.area,
        registeredAt: registeredAt ?? this.registeredAt,
      );
  DeviceInfoData copyWithCompanion(DeviceInfoCompanion data) {
    return DeviceInfoData(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      branch: data.branch.present ? data.branch.value : this.branch,
      area: data.area.present ? data.area.value : this.area,
      registeredAt: data.registeredAt.present
          ? data.registeredAt.value
          : this.registeredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceInfoData(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('branch: $branch, ')
          ..write('area: $area, ')
          ..write('registeredAt: $registeredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, deviceId, branch, area, registeredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceInfoData &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.branch == this.branch &&
          other.area == this.area &&
          other.registeredAt == this.registeredAt);
}

class DeviceInfoCompanion extends UpdateCompanion<DeviceInfoData> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<String> branch;
  final Value<String> area;
  final Value<int> registeredAt;
  const DeviceInfoCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.branch = const Value.absent(),
    this.area = const Value.absent(),
    this.registeredAt = const Value.absent(),
  });
  DeviceInfoCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    this.branch = const Value.absent(),
    this.area = const Value.absent(),
    required int registeredAt,
  })  : deviceId = Value(deviceId),
        registeredAt = Value(registeredAt);
  static Insertable<DeviceInfoData> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<String>? branch,
    Expression<String>? area,
    Expression<int>? registeredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (branch != null) 'branch': branch,
      if (area != null) 'area': area,
      if (registeredAt != null) 'registered_at': registeredAt,
    });
  }

  DeviceInfoCompanion copyWith(
      {Value<int>? id,
      Value<String>? deviceId,
      Value<String>? branch,
      Value<String>? area,
      Value<int>? registeredAt}) {
    return DeviceInfoCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      branch: branch ?? this.branch,
      area: area ?? this.area,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (branch.present) {
      map['branch'] = Variable<String>(branch.value);
    }
    if (area.present) {
      map['area'] = Variable<String>(area.value);
    }
    if (registeredAt.present) {
      map['registered_at'] = Variable<int>(registeredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceInfoCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('branch: $branch, ')
          ..write('area: $area, ')
          ..write('registeredAt: $registeredAt')
          ..write(')'))
        .toString();
  }
}

class $DeviceIdentityTable extends DeviceIdentity
    with TableInfo<$DeviceIdentityTable, DeviceIdentityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceIdentityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _deviceLabelMeta =
      const VerificationMeta('deviceLabel');
  @override
  late final GeneratedColumn<String> deviceLabel = GeneratedColumn<String>(
      'device_label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverDeviceIdMeta =
      const VerificationMeta('serverDeviceId');
  @override
  late final GeneratedColumn<String> serverDeviceId = GeneratedColumn<String>(
      'server_device_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _androidIdHashMeta =
      const VerificationMeta('androidIdHash');
  @override
  late final GeneratedColumn<String> androidIdHash = GeneratedColumn<String>(
      'android_id_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchMeta = const VerificationMeta('branch');
  @override
  late final GeneratedColumn<String> branch = GeneratedColumn<String>(
      'branch', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _areaMeta = const VerificationMeta('area');
  @override
  late final GeneratedColumn<String> area = GeneratedColumn<String>(
      'area', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _claimedAtMeta =
      const VerificationMeta('claimedAt');
  @override
  late final GeneratedColumn<DateTime> claimedAt = GeneratedColumn<DateTime>(
      'claimed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        deviceLabel,
        serverDeviceId,
        androidIdHash,
        branch,
        area,
        isActive,
        claimedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_identity';
  @override
  VerificationContext validateIntegrity(Insertable<DeviceIdentityData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_label')) {
      context.handle(
          _deviceLabelMeta,
          deviceLabel.isAcceptableOrUnknown(
              data['device_label']!, _deviceLabelMeta));
    } else if (isInserting) {
      context.missing(_deviceLabelMeta);
    }
    if (data.containsKey('server_device_id')) {
      context.handle(
          _serverDeviceIdMeta,
          serverDeviceId.isAcceptableOrUnknown(
              data['server_device_id']!, _serverDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_serverDeviceIdMeta);
    }
    if (data.containsKey('android_id_hash')) {
      context.handle(
          _androidIdHashMeta,
          androidIdHash.isAcceptableOrUnknown(
              data['android_id_hash']!, _androidIdHashMeta));
    } else if (isInserting) {
      context.missing(_androidIdHashMeta);
    }
    if (data.containsKey('branch')) {
      context.handle(_branchMeta,
          branch.isAcceptableOrUnknown(data['branch']!, _branchMeta));
    } else if (isInserting) {
      context.missing(_branchMeta);
    }
    if (data.containsKey('area')) {
      context.handle(
          _areaMeta, area.isAcceptableOrUnknown(data['area']!, _areaMeta));
    } else if (isInserting) {
      context.missing(_areaMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('claimed_at')) {
      context.handle(_claimedAtMeta,
          claimedAt.isAcceptableOrUnknown(data['claimed_at']!, _claimedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceIdentityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceIdentityData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      deviceLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_label'])!,
      serverDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}server_device_id'])!,
      androidIdHash: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}android_id_hash'])!,
      branch: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch'])!,
      area: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}area'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      claimedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}claimed_at']),
    );
  }

  @override
  $DeviceIdentityTable createAlias(String alias) {
    return $DeviceIdentityTable(attachedDatabase, alias);
  }
}

class DeviceIdentityData extends DataClass
    implements Insertable<DeviceIdentityData> {
  final int id;
  final String deviceLabel;
  final String serverDeviceId;

  /// SHA-256 of raw ANDROID_ID (never store raw id).
  final String androidIdHash;
  final String branch;
  final String area;
  final bool isActive;
  final DateTime? claimedAt;
  const DeviceIdentityData(
      {required this.id,
      required this.deviceLabel,
      required this.serverDeviceId,
      required this.androidIdHash,
      required this.branch,
      required this.area,
      required this.isActive,
      this.claimedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_label'] = Variable<String>(deviceLabel);
    map['server_device_id'] = Variable<String>(serverDeviceId);
    map['android_id_hash'] = Variable<String>(androidIdHash);
    map['branch'] = Variable<String>(branch);
    map['area'] = Variable<String>(area);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || claimedAt != null) {
      map['claimed_at'] = Variable<DateTime>(claimedAt);
    }
    return map;
  }

  DeviceIdentityCompanion toCompanion(bool nullToAbsent) {
    return DeviceIdentityCompanion(
      id: Value(id),
      deviceLabel: Value(deviceLabel),
      serverDeviceId: Value(serverDeviceId),
      androidIdHash: Value(androidIdHash),
      branch: Value(branch),
      area: Value(area),
      isActive: Value(isActive),
      claimedAt: claimedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(claimedAt),
    );
  }

  factory DeviceIdentityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceIdentityData(
      id: serializer.fromJson<int>(json['id']),
      deviceLabel: serializer.fromJson<String>(json['deviceLabel']),
      serverDeviceId: serializer.fromJson<String>(json['serverDeviceId']),
      androidIdHash: serializer.fromJson<String>(json['androidIdHash']),
      branch: serializer.fromJson<String>(json['branch']),
      area: serializer.fromJson<String>(json['area']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      claimedAt: serializer.fromJson<DateTime?>(json['claimedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceLabel': serializer.toJson<String>(deviceLabel),
      'serverDeviceId': serializer.toJson<String>(serverDeviceId),
      'androidIdHash': serializer.toJson<String>(androidIdHash),
      'branch': serializer.toJson<String>(branch),
      'area': serializer.toJson<String>(area),
      'isActive': serializer.toJson<bool>(isActive),
      'claimedAt': serializer.toJson<DateTime?>(claimedAt),
    };
  }

  DeviceIdentityData copyWith(
          {int? id,
          String? deviceLabel,
          String? serverDeviceId,
          String? androidIdHash,
          String? branch,
          String? area,
          bool? isActive,
          Value<DateTime?> claimedAt = const Value.absent()}) =>
      DeviceIdentityData(
        id: id ?? this.id,
        deviceLabel: deviceLabel ?? this.deviceLabel,
        serverDeviceId: serverDeviceId ?? this.serverDeviceId,
        androidIdHash: androidIdHash ?? this.androidIdHash,
        branch: branch ?? this.branch,
        area: area ?? this.area,
        isActive: isActive ?? this.isActive,
        claimedAt: claimedAt.present ? claimedAt.value : this.claimedAt,
      );
  DeviceIdentityData copyWithCompanion(DeviceIdentityCompanion data) {
    return DeviceIdentityData(
      id: data.id.present ? data.id.value : this.id,
      deviceLabel:
          data.deviceLabel.present ? data.deviceLabel.value : this.deviceLabel,
      serverDeviceId: data.serverDeviceId.present
          ? data.serverDeviceId.value
          : this.serverDeviceId,
      androidIdHash: data.androidIdHash.present
          ? data.androidIdHash.value
          : this.androidIdHash,
      branch: data.branch.present ? data.branch.value : this.branch,
      area: data.area.present ? data.area.value : this.area,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      claimedAt: data.claimedAt.present ? data.claimedAt.value : this.claimedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceIdentityData(')
          ..write('id: $id, ')
          ..write('deviceLabel: $deviceLabel, ')
          ..write('serverDeviceId: $serverDeviceId, ')
          ..write('androidIdHash: $androidIdHash, ')
          ..write('branch: $branch, ')
          ..write('area: $area, ')
          ..write('isActive: $isActive, ')
          ..write('claimedAt: $claimedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, deviceLabel, serverDeviceId,
      androidIdHash, branch, area, isActive, claimedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceIdentityData &&
          other.id == this.id &&
          other.deviceLabel == this.deviceLabel &&
          other.serverDeviceId == this.serverDeviceId &&
          other.androidIdHash == this.androidIdHash &&
          other.branch == this.branch &&
          other.area == this.area &&
          other.isActive == this.isActive &&
          other.claimedAt == this.claimedAt);
}

class DeviceIdentityCompanion extends UpdateCompanion<DeviceIdentityData> {
  final Value<int> id;
  final Value<String> deviceLabel;
  final Value<String> serverDeviceId;
  final Value<String> androidIdHash;
  final Value<String> branch;
  final Value<String> area;
  final Value<bool> isActive;
  final Value<DateTime?> claimedAt;
  const DeviceIdentityCompanion({
    this.id = const Value.absent(),
    this.deviceLabel = const Value.absent(),
    this.serverDeviceId = const Value.absent(),
    this.androidIdHash = const Value.absent(),
    this.branch = const Value.absent(),
    this.area = const Value.absent(),
    this.isActive = const Value.absent(),
    this.claimedAt = const Value.absent(),
  });
  DeviceIdentityCompanion.insert({
    this.id = const Value.absent(),
    required String deviceLabel,
    required String serverDeviceId,
    required String androidIdHash,
    required String branch,
    required String area,
    this.isActive = const Value.absent(),
    this.claimedAt = const Value.absent(),
  })  : deviceLabel = Value(deviceLabel),
        serverDeviceId = Value(serverDeviceId),
        androidIdHash = Value(androidIdHash),
        branch = Value(branch),
        area = Value(area);
  static Insertable<DeviceIdentityData> custom({
    Expression<int>? id,
    Expression<String>? deviceLabel,
    Expression<String>? serverDeviceId,
    Expression<String>? androidIdHash,
    Expression<String>? branch,
    Expression<String>? area,
    Expression<bool>? isActive,
    Expression<DateTime>? claimedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceLabel != null) 'device_label': deviceLabel,
      if (serverDeviceId != null) 'server_device_id': serverDeviceId,
      if (androidIdHash != null) 'android_id_hash': androidIdHash,
      if (branch != null) 'branch': branch,
      if (area != null) 'area': area,
      if (isActive != null) 'is_active': isActive,
      if (claimedAt != null) 'claimed_at': claimedAt,
    });
  }

  DeviceIdentityCompanion copyWith(
      {Value<int>? id,
      Value<String>? deviceLabel,
      Value<String>? serverDeviceId,
      Value<String>? androidIdHash,
      Value<String>? branch,
      Value<String>? area,
      Value<bool>? isActive,
      Value<DateTime?>? claimedAt}) {
    return DeviceIdentityCompanion(
      id: id ?? this.id,
      deviceLabel: deviceLabel ?? this.deviceLabel,
      serverDeviceId: serverDeviceId ?? this.serverDeviceId,
      androidIdHash: androidIdHash ?? this.androidIdHash,
      branch: branch ?? this.branch,
      area: area ?? this.area,
      isActive: isActive ?? this.isActive,
      claimedAt: claimedAt ?? this.claimedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceLabel.present) {
      map['device_label'] = Variable<String>(deviceLabel.value);
    }
    if (serverDeviceId.present) {
      map['server_device_id'] = Variable<String>(serverDeviceId.value);
    }
    if (androidIdHash.present) {
      map['android_id_hash'] = Variable<String>(androidIdHash.value);
    }
    if (branch.present) {
      map['branch'] = Variable<String>(branch.value);
    }
    if (area.present) {
      map['area'] = Variable<String>(area.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (claimedAt.present) {
      map['claimed_at'] = Variable<DateTime>(claimedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceIdentityCompanion(')
          ..write('id: $id, ')
          ..write('deviceLabel: $deviceLabel, ')
          ..write('serverDeviceId: $serverDeviceId, ')
          ..write('androidIdHash: $androidIdHash, ')
          ..write('branch: $branch, ')
          ..write('area: $area, ')
          ..write('isActive: $isActive, ')
          ..write('claimedAt: $claimedAt')
          ..write(')'))
        .toString();
  }
}

class $OfflineAccountsTable extends OfflineAccounts
    with TableInfo<$OfflineAccountsTable, OfflineAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverUserIdMeta =
      const VerificationMeta('serverUserId');
  @override
  late final GeneratedColumn<String> serverUserId = GeneratedColumn<String>(
      'server_user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _passwordHashMeta =
      const VerificationMeta('passwordHash');
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
      'password_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fullNameMeta =
      const VerificationMeta('fullName');
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
      'full_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastOnlineLoginMeta =
      const VerificationMeta('lastOnlineLogin');
  @override
  late final GeneratedColumn<int> lastOnlineLogin = GeneratedColumn<int>(
      'last_online_login', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverUserId,
        email,
        passwordHash,
        fullName,
        role,
        lastOnlineLogin,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_accounts';
  @override
  VerificationContext validateIntegrity(Insertable<OfflineAccount> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_user_id')) {
      context.handle(
          _serverUserIdMeta,
          serverUserId.isAcceptableOrUnknown(
              data['server_user_id']!, _serverUserIdMeta));
    } else if (isInserting) {
      context.missing(_serverUserIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
          _passwordHashMeta,
          passwordHash.isAcceptableOrUnknown(
              data['password_hash']!, _passwordHashMeta));
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(_fullNameMeta,
          fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta));
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('last_online_login')) {
      context.handle(
          _lastOnlineLoginMeta,
          lastOnlineLogin.isAcceptableOrUnknown(
              data['last_online_login']!, _lastOnlineLoginMeta));
    } else if (isInserting) {
      context.missing(_lastOnlineLoginMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineAccount(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_user_id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      passwordHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password_hash'])!,
      fullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_name'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      lastOnlineLogin: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_online_login'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $OfflineAccountsTable createAlias(String alias) {
    return $OfflineAccountsTable(attachedDatabase, alias);
  }
}

class OfflineAccount extends DataClass implements Insertable<OfflineAccount> {
  final int id;

  /// Server user id (UUID string from API).
  final String serverUserId;
  final String email;
  final String passwordHash;
  final String fullName;
  final String role;

  /// Unix timestamp (seconds).
  final int lastOnlineLogin;
  final int createdAt;
  final int updatedAt;
  const OfflineAccount(
      {required this.id,
      required this.serverUserId,
      required this.email,
      required this.passwordHash,
      required this.fullName,
      required this.role,
      required this.lastOnlineLogin,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_user_id'] = Variable<String>(serverUserId);
    map['email'] = Variable<String>(email);
    map['password_hash'] = Variable<String>(passwordHash);
    map['full_name'] = Variable<String>(fullName);
    map['role'] = Variable<String>(role);
    map['last_online_login'] = Variable<int>(lastOnlineLogin);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  OfflineAccountsCompanion toCompanion(bool nullToAbsent) {
    return OfflineAccountsCompanion(
      id: Value(id),
      serverUserId: Value(serverUserId),
      email: Value(email),
      passwordHash: Value(passwordHash),
      fullName: Value(fullName),
      role: Value(role),
      lastOnlineLogin: Value(lastOnlineLogin),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OfflineAccount.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineAccount(
      id: serializer.fromJson<int>(json['id']),
      serverUserId: serializer.fromJson<String>(json['serverUserId']),
      email: serializer.fromJson<String>(json['email']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      fullName: serializer.fromJson<String>(json['fullName']),
      role: serializer.fromJson<String>(json['role']),
      lastOnlineLogin: serializer.fromJson<int>(json['lastOnlineLogin']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverUserId': serializer.toJson<String>(serverUserId),
      'email': serializer.toJson<String>(email),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'fullName': serializer.toJson<String>(fullName),
      'role': serializer.toJson<String>(role),
      'lastOnlineLogin': serializer.toJson<int>(lastOnlineLogin),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  OfflineAccount copyWith(
          {int? id,
          String? serverUserId,
          String? email,
          String? passwordHash,
          String? fullName,
          String? role,
          int? lastOnlineLogin,
          int? createdAt,
          int? updatedAt}) =>
      OfflineAccount(
        id: id ?? this.id,
        serverUserId: serverUserId ?? this.serverUserId,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
        lastOnlineLogin: lastOnlineLogin ?? this.lastOnlineLogin,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  OfflineAccount copyWithCompanion(OfflineAccountsCompanion data) {
    return OfflineAccount(
      id: data.id.present ? data.id.value : this.id,
      serverUserId: data.serverUserId.present
          ? data.serverUserId.value
          : this.serverUserId,
      email: data.email.present ? data.email.value : this.email,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      role: data.role.present ? data.role.value : this.role,
      lastOnlineLogin: data.lastOnlineLogin.present
          ? data.lastOnlineLogin.value
          : this.lastOnlineLogin,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineAccount(')
          ..write('id: $id, ')
          ..write('serverUserId: $serverUserId, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('fullName: $fullName, ')
          ..write('role: $role, ')
          ..write('lastOnlineLogin: $lastOnlineLogin, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, serverUserId, email, passwordHash,
      fullName, role, lastOnlineLogin, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineAccount &&
          other.id == this.id &&
          other.serverUserId == this.serverUserId &&
          other.email == this.email &&
          other.passwordHash == this.passwordHash &&
          other.fullName == this.fullName &&
          other.role == this.role &&
          other.lastOnlineLogin == this.lastOnlineLogin &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OfflineAccountsCompanion extends UpdateCompanion<OfflineAccount> {
  final Value<int> id;
  final Value<String> serverUserId;
  final Value<String> email;
  final Value<String> passwordHash;
  final Value<String> fullName;
  final Value<String> role;
  final Value<int> lastOnlineLogin;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const OfflineAccountsCompanion({
    this.id = const Value.absent(),
    this.serverUserId = const Value.absent(),
    this.email = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.fullName = const Value.absent(),
    this.role = const Value.absent(),
    this.lastOnlineLogin = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  OfflineAccountsCompanion.insert({
    this.id = const Value.absent(),
    required String serverUserId,
    required String email,
    required String passwordHash,
    required String fullName,
    required String role,
    required int lastOnlineLogin,
    required int createdAt,
    required int updatedAt,
  })  : serverUserId = Value(serverUserId),
        email = Value(email),
        passwordHash = Value(passwordHash),
        fullName = Value(fullName),
        role = Value(role),
        lastOnlineLogin = Value(lastOnlineLogin),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<OfflineAccount> custom({
    Expression<int>? id,
    Expression<String>? serverUserId,
    Expression<String>? email,
    Expression<String>? passwordHash,
    Expression<String>? fullName,
    Expression<String>? role,
    Expression<int>? lastOnlineLogin,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverUserId != null) 'server_user_id': serverUserId,
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (fullName != null) 'full_name': fullName,
      if (role != null) 'role': role,
      if (lastOnlineLogin != null) 'last_online_login': lastOnlineLogin,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  OfflineAccountsCompanion copyWith(
      {Value<int>? id,
      Value<String>? serverUserId,
      Value<String>? email,
      Value<String>? passwordHash,
      Value<String>? fullName,
      Value<String>? role,
      Value<int>? lastOnlineLogin,
      Value<int>? createdAt,
      Value<int>? updatedAt}) {
    return OfflineAccountsCompanion(
      id: id ?? this.id,
      serverUserId: serverUserId ?? this.serverUserId,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      lastOnlineLogin: lastOnlineLogin ?? this.lastOnlineLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverUserId.present) {
      map['server_user_id'] = Variable<String>(serverUserId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (lastOnlineLogin.present) {
      map['last_online_login'] = Variable<int>(lastOnlineLogin.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineAccountsCompanion(')
          ..write('id: $id, ')
          ..write('serverUserId: $serverUserId, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('fullName: $fullName, ')
          ..write('role: $role, ')
          ..write('lastOnlineLogin: $lastOnlineLogin, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES offline_accounts (id)'));
  static const VerificationMeta _authTokenMeta =
      const VerificationMeta('authToken');
  @override
  late final GeneratedColumn<String> authToken = GeneratedColumn<String>(
      'auth_token', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _loginAtMeta =
      const VerificationMeta('loginAt');
  @override
  late final GeneratedColumn<int> loginAt = GeneratedColumn<int>(
      'login_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastVerifiedAtMeta =
      const VerificationMeta('lastVerifiedAt');
  @override
  late final GeneratedColumn<int> lastVerifiedAt = GeneratedColumn<int>(
      'last_verified_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _logoutAtMeta =
      const VerificationMeta('logoutAt');
  @override
  late final GeneratedColumn<int> logoutAt = GeneratedColumn<int>(
      'logout_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isOfflineSessionMeta =
      const VerificationMeta('isOfflineSession');
  @override
  late final GeneratedColumn<bool> isOfflineSession = GeneratedColumn<bool>(
      'is_offline_session', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_offline_session" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        authToken,
        isActive,
        loginAt,
        lastVerifiedAt,
        logoutAt,
        isOfflineSession
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(Insertable<Session> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('auth_token')) {
      context.handle(_authTokenMeta,
          authToken.isAcceptableOrUnknown(data['auth_token']!, _authTokenMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('login_at')) {
      context.handle(_loginAtMeta,
          loginAt.isAcceptableOrUnknown(data['login_at']!, _loginAtMeta));
    } else if (isInserting) {
      context.missing(_loginAtMeta);
    }
    if (data.containsKey('last_verified_at')) {
      context.handle(
          _lastVerifiedAtMeta,
          lastVerifiedAt.isAcceptableOrUnknown(
              data['last_verified_at']!, _lastVerifiedAtMeta));
    }
    if (data.containsKey('logout_at')) {
      context.handle(_logoutAtMeta,
          logoutAt.isAcceptableOrUnknown(data['logout_at']!, _logoutAtMeta));
    }
    if (data.containsKey('is_offline_session')) {
      context.handle(
          _isOfflineSessionMeta,
          isOfflineSession.isAcceptableOrUnknown(
              data['is_offline_session']!, _isOfflineSessionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      authToken: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}auth_token']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      loginAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}login_at'])!,
      lastVerifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_verified_at']),
      logoutAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}logout_at']),
      isOfflineSession: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_offline_session'])!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;

  /// Local [OfflineAccounts.id] (not server id).
  final int userId;
  final String? authToken;
  final bool isActive;
  final int loginAt;
  final int? lastVerifiedAt;
  final int? logoutAt;
  final bool isOfflineSession;
  const Session(
      {required this.id,
      required this.userId,
      this.authToken,
      required this.isActive,
      required this.loginAt,
      this.lastVerifiedAt,
      this.logoutAt,
      required this.isOfflineSession});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    if (!nullToAbsent || authToken != null) {
      map['auth_token'] = Variable<String>(authToken);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['login_at'] = Variable<int>(loginAt);
    if (!nullToAbsent || lastVerifiedAt != null) {
      map['last_verified_at'] = Variable<int>(lastVerifiedAt);
    }
    if (!nullToAbsent || logoutAt != null) {
      map['logout_at'] = Variable<int>(logoutAt);
    }
    map['is_offline_session'] = Variable<bool>(isOfflineSession);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      authToken: authToken == null && nullToAbsent
          ? const Value.absent()
          : Value(authToken),
      isActive: Value(isActive),
      loginAt: Value(loginAt),
      lastVerifiedAt: lastVerifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVerifiedAt),
      logoutAt: logoutAt == null && nullToAbsent
          ? const Value.absent()
          : Value(logoutAt),
      isOfflineSession: Value(isOfflineSession),
    );
  }

  factory Session.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      authToken: serializer.fromJson<String?>(json['authToken']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      loginAt: serializer.fromJson<int>(json['loginAt']),
      lastVerifiedAt: serializer.fromJson<int?>(json['lastVerifiedAt']),
      logoutAt: serializer.fromJson<int?>(json['logoutAt']),
      isOfflineSession: serializer.fromJson<bool>(json['isOfflineSession']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'authToken': serializer.toJson<String?>(authToken),
      'isActive': serializer.toJson<bool>(isActive),
      'loginAt': serializer.toJson<int>(loginAt),
      'lastVerifiedAt': serializer.toJson<int?>(lastVerifiedAt),
      'logoutAt': serializer.toJson<int?>(logoutAt),
      'isOfflineSession': serializer.toJson<bool>(isOfflineSession),
    };
  }

  Session copyWith(
          {int? id,
          int? userId,
          Value<String?> authToken = const Value.absent(),
          bool? isActive,
          int? loginAt,
          Value<int?> lastVerifiedAt = const Value.absent(),
          Value<int?> logoutAt = const Value.absent(),
          bool? isOfflineSession}) =>
      Session(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        authToken: authToken.present ? authToken.value : this.authToken,
        isActive: isActive ?? this.isActive,
        loginAt: loginAt ?? this.loginAt,
        lastVerifiedAt:
            lastVerifiedAt.present ? lastVerifiedAt.value : this.lastVerifiedAt,
        logoutAt: logoutAt.present ? logoutAt.value : this.logoutAt,
        isOfflineSession: isOfflineSession ?? this.isOfflineSession,
      );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      authToken: data.authToken.present ? data.authToken.value : this.authToken,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      loginAt: data.loginAt.present ? data.loginAt.value : this.loginAt,
      lastVerifiedAt: data.lastVerifiedAt.present
          ? data.lastVerifiedAt.value
          : this.lastVerifiedAt,
      logoutAt: data.logoutAt.present ? data.logoutAt.value : this.logoutAt,
      isOfflineSession: data.isOfflineSession.present
          ? data.isOfflineSession.value
          : this.isOfflineSession,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('authToken: $authToken, ')
          ..write('isActive: $isActive, ')
          ..write('loginAt: $loginAt, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('logoutAt: $logoutAt, ')
          ..write('isOfflineSession: $isOfflineSession')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, authToken, isActive, loginAt,
      lastVerifiedAt, logoutAt, isOfflineSession);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.authToken == this.authToken &&
          other.isActive == this.isActive &&
          other.loginAt == this.loginAt &&
          other.lastVerifiedAt == this.lastVerifiedAt &&
          other.logoutAt == this.logoutAt &&
          other.isOfflineSession == this.isOfflineSession);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String?> authToken;
  final Value<bool> isActive;
  final Value<int> loginAt;
  final Value<int?> lastVerifiedAt;
  final Value<int?> logoutAt;
  final Value<bool> isOfflineSession;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.authToken = const Value.absent(),
    this.isActive = const Value.absent(),
    this.loginAt = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.logoutAt = const Value.absent(),
    this.isOfflineSession = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    this.authToken = const Value.absent(),
    this.isActive = const Value.absent(),
    required int loginAt,
    this.lastVerifiedAt = const Value.absent(),
    this.logoutAt = const Value.absent(),
    this.isOfflineSession = const Value.absent(),
  })  : userId = Value(userId),
        loginAt = Value(loginAt);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? authToken,
    Expression<bool>? isActive,
    Expression<int>? loginAt,
    Expression<int>? lastVerifiedAt,
    Expression<int>? logoutAt,
    Expression<bool>? isOfflineSession,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (authToken != null) 'auth_token': authToken,
      if (isActive != null) 'is_active': isActive,
      if (loginAt != null) 'login_at': loginAt,
      if (lastVerifiedAt != null) 'last_verified_at': lastVerifiedAt,
      if (logoutAt != null) 'logout_at': logoutAt,
      if (isOfflineSession != null) 'is_offline_session': isOfflineSession,
    });
  }

  SessionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? userId,
      Value<String?>? authToken,
      Value<bool>? isActive,
      Value<int>? loginAt,
      Value<int?>? lastVerifiedAt,
      Value<int?>? logoutAt,
      Value<bool>? isOfflineSession}) {
    return SessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      authToken: authToken ?? this.authToken,
      isActive: isActive ?? this.isActive,
      loginAt: loginAt ?? this.loginAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      logoutAt: logoutAt ?? this.logoutAt,
      isOfflineSession: isOfflineSession ?? this.isOfflineSession,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (authToken.present) {
      map['auth_token'] = Variable<String>(authToken.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (loginAt.present) {
      map['login_at'] = Variable<int>(loginAt.value);
    }
    if (lastVerifiedAt.present) {
      map['last_verified_at'] = Variable<int>(lastVerifiedAt.value);
    }
    if (logoutAt.present) {
      map['logout_at'] = Variable<int>(logoutAt.value);
    }
    if (isOfflineSession.present) {
      map['is_offline_session'] = Variable<bool>(isOfflineSession.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('authToken: $authToken, ')
          ..write('isActive: $isActive, ')
          ..write('loginAt: $loginAt, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('logoutAt: $logoutAt, ')
          ..write('isOfflineSession: $isOfflineSession')
          ..write(')'))
        .toString();
  }
}

class $ShiftsTable extends Shifts with TableInfo<$ShiftsTable, Shift> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _openedAtMeta =
      const VerificationMeta('openedAt');
  @override
  late final GeneratedColumn<String> openedAt = GeneratedColumn<String>(
      'opened_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _closedAtMeta =
      const VerificationMeta('closedAt');
  @override
  late final GeneratedColumn<String> closedAt = GeneratedColumn<String>(
      'closed_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _openingFloatMeta =
      const VerificationMeta('openingFloat');
  @override
  late final GeneratedColumn<double> openingFloat = GeneratedColumn<double>(
      'opening_float', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _closingCashMeta =
      const VerificationMeta('closingCash');
  @override
  late final GeneratedColumn<double> closingCash = GeneratedColumn<double>(
      'closing_cash', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        branchId,
        openedAt,
        closedAt,
        openingFloat,
        closingCash,
        status,
        syncStatus,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shifts';
  @override
  VerificationContext validateIntegrity(Insertable<Shift> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(_openedAtMeta,
          openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta));
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(_closedAtMeta,
          closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta));
    }
    if (data.containsKey('opening_float')) {
      context.handle(
          _openingFloatMeta,
          openingFloat.isAcceptableOrUnknown(
              data['opening_float']!, _openingFloatMeta));
    } else if (isInserting) {
      context.missing(_openingFloatMeta);
    }
    if (data.containsKey('closing_cash')) {
      context.handle(
          _closingCashMeta,
          closingCash.isAcceptableOrUnknown(
              data['closing_cash']!, _closingCashMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Shift map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shift(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      openedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}opened_at'])!,
      closedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}closed_at']),
      openingFloat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}opening_float'])!,
      closingCash: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}closing_cash']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ShiftsTable createAlias(String alias) {
    return $ShiftsTable(attachedDatabase, alias);
  }
}

class Shift extends DataClass implements Insertable<Shift> {
  final String id;

  /// [OfflineAccounts.serverUserId] as string.
  final String userId;
  final String branchId;

  /// ISO8601, Asia/Manila.
  final String openedAt;

  /// ISO8601, nullable when shift is open.
  final String? closedAt;
  final double openingFloat;
  final double? closingCash;

  /// `open` | `closed`
  final String status;

  /// `pending` | `synced`
  final String syncStatus;

  /// ISO8601 row creation time.
  final String createdAt;
  const Shift(
      {required this.id,
      required this.userId,
      required this.branchId,
      required this.openedAt,
      this.closedAt,
      required this.openingFloat,
      this.closingCash,
      required this.status,
      required this.syncStatus,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['branch_id'] = Variable<String>(branchId);
    map['opened_at'] = Variable<String>(openedAt);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<String>(closedAt);
    }
    map['opening_float'] = Variable<double>(openingFloat);
    if (!nullToAbsent || closingCash != null) {
      map['closing_cash'] = Variable<double>(closingCash);
    }
    map['status'] = Variable<String>(status);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  ShiftsCompanion toCompanion(bool nullToAbsent) {
    return ShiftsCompanion(
      id: Value(id),
      userId: Value(userId),
      branchId: Value(branchId),
      openedAt: Value(openedAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      openingFloat: Value(openingFloat),
      closingCash: closingCash == null && nullToAbsent
          ? const Value.absent()
          : Value(closingCash),
      status: Value(status),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
    );
  }

  factory Shift.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shift(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      openedAt: serializer.fromJson<String>(json['openedAt']),
      closedAt: serializer.fromJson<String?>(json['closedAt']),
      openingFloat: serializer.fromJson<double>(json['openingFloat']),
      closingCash: serializer.fromJson<double?>(json['closingCash']),
      status: serializer.fromJson<String>(json['status']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'branchId': serializer.toJson<String>(branchId),
      'openedAt': serializer.toJson<String>(openedAt),
      'closedAt': serializer.toJson<String?>(closedAt),
      'openingFloat': serializer.toJson<double>(openingFloat),
      'closingCash': serializer.toJson<double?>(closingCash),
      'status': serializer.toJson<String>(status),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Shift copyWith(
          {String? id,
          String? userId,
          String? branchId,
          String? openedAt,
          Value<String?> closedAt = const Value.absent(),
          double? openingFloat,
          Value<double?> closingCash = const Value.absent(),
          String? status,
          String? syncStatus,
          String? createdAt}) =>
      Shift(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        branchId: branchId ?? this.branchId,
        openedAt: openedAt ?? this.openedAt,
        closedAt: closedAt.present ? closedAt.value : this.closedAt,
        openingFloat: openingFloat ?? this.openingFloat,
        closingCash: closingCash.present ? closingCash.value : this.closingCash,
        status: status ?? this.status,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
      );
  Shift copyWithCompanion(ShiftsCompanion data) {
    return Shift(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      openingFloat: data.openingFloat.present
          ? data.openingFloat.value
          : this.openingFloat,
      closingCash:
          data.closingCash.present ? data.closingCash.value : this.closingCash,
      status: data.status.present ? data.status.value : this.status,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shift(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('branchId: $branchId, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('openingFloat: $openingFloat, ')
          ..write('closingCash: $closingCash, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, branchId, openedAt, closedAt,
      openingFloat, closingCash, status, syncStatus, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shift &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.branchId == this.branchId &&
          other.openedAt == this.openedAt &&
          other.closedAt == this.closedAt &&
          other.openingFloat == this.openingFloat &&
          other.closingCash == this.closingCash &&
          other.status == this.status &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt);
}

class ShiftsCompanion extends UpdateCompanion<Shift> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> branchId;
  final Value<String> openedAt;
  final Value<String?> closedAt;
  final Value<double> openingFloat;
  final Value<double?> closingCash;
  final Value<String> status;
  final Value<String> syncStatus;
  final Value<String> createdAt;
  final Value<int> rowid;
  const ShiftsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.openingFloat = const Value.absent(),
    this.closingCash = const Value.absent(),
    this.status = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShiftsCompanion.insert({
    required String id,
    required String userId,
    required String branchId,
    required String openedAt,
    this.closedAt = const Value.absent(),
    required double openingFloat,
    this.closingCash = const Value.absent(),
    required String status,
    required String syncStatus,
    required String createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        branchId = Value(branchId),
        openedAt = Value(openedAt),
        openingFloat = Value(openingFloat),
        status = Value(status),
        syncStatus = Value(syncStatus),
        createdAt = Value(createdAt);
  static Insertable<Shift> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? branchId,
    Expression<String>? openedAt,
    Expression<String>? closedAt,
    Expression<double>? openingFloat,
    Expression<double>? closingCash,
    Expression<String>? status,
    Expression<String>? syncStatus,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (branchId != null) 'branch_id': branchId,
      if (openedAt != null) 'opened_at': openedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (openingFloat != null) 'opening_float': openingFloat,
      if (closingCash != null) 'closing_cash': closingCash,
      if (status != null) 'status': status,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShiftsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? branchId,
      Value<String>? openedAt,
      Value<String?>? closedAt,
      Value<double>? openingFloat,
      Value<double?>? closingCash,
      Value<String>? status,
      Value<String>? syncStatus,
      Value<String>? createdAt,
      Value<int>? rowid}) {
    return ShiftsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      branchId: branchId ?? this.branchId,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      openingFloat: openingFloat ?? this.openingFloat,
      closingCash: closingCash ?? this.closingCash,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<String>(openedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<String>(closedAt.value);
    }
    if (openingFloat.present) {
      map['opening_float'] = Variable<double>(openingFloat.value);
    }
    if (closingCash.present) {
      map['closing_cash'] = Variable<double>(closingCash.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('branchId: $branchId, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('openingFloat: $openingFloat, ')
          ..write('closingCash: $closingCash, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TicketsTable extends Tickets with TableInfo<$TicketsTable, Ticket> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TicketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shiftIdMeta =
      const VerificationMeta('shiftId');
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
      'shift_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES shifts (id)'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _plateNumberMeta =
      const VerificationMeta('plateNumber');
  @override
  late final GeneratedColumn<String> plateNumber = GeneratedColumn<String>(
      'plate_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vehicleBrandMeta =
      const VerificationMeta('vehicleBrand');
  @override
  late final GeneratedColumn<String> vehicleBrand = GeneratedColumn<String>(
      'vehicle_brand', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vehicleColorMeta =
      const VerificationMeta('vehicleColor');
  @override
  late final GeneratedColumn<String> vehicleColor = GeneratedColumn<String>(
      'vehicle_color', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vehicleTypeMeta =
      const VerificationMeta('vehicleType');
  @override
  late final GeneratedColumn<String> vehicleType = GeneratedColumn<String>(
      'vehicle_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cellphoneNumberMeta =
      const VerificationMeta('cellphoneNumber');
  @override
  late final GeneratedColumn<String> cellphoneNumber = GeneratedColumn<String>(
      'cellphone_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _damageMarkersMeta =
      const VerificationMeta('damageMarkers');
  @override
  late final GeneratedColumn<String> damageMarkers = GeneratedColumn<String>(
      'damage_markers', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _personalBelongingsMeta =
      const VerificationMeta('personalBelongings');
  @override
  late final GeneratedColumn<String> personalBelongings =
      GeneratedColumn<String>('personal_belongings', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _signaturePngMeta =
      const VerificationMeta('signaturePng');
  @override
  late final GeneratedColumn<String> signaturePng = GeneratedColumn<String>(
      'signature_png', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _checkInAtMeta =
      const VerificationMeta('checkInAt');
  @override
  late final GeneratedColumn<String> checkInAt = GeneratedColumn<String>(
      'check_in_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _checkOutAtMeta =
      const VerificationMeta('checkOutAt');
  @override
  late final GeneratedColumn<String> checkOutAt = GeneratedColumn<String>(
      'check_out_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _feeMeta = const VerificationMeta('fee');
  @override
  late final GeneratedColumn<double> fee = GeneratedColumn<double>(
      'fee', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverTicketIdMeta =
      const VerificationMeta('serverTicketId');
  @override
  late final GeneratedColumn<String> serverTicketId = GeneratedColumn<String>(
      'server_ticket_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        shiftId,
        userId,
        branchId,
        plateNumber,
        vehicleBrand,
        vehicleColor,
        vehicleType,
        cellphoneNumber,
        damageMarkers,
        personalBelongings,
        signaturePng,
        checkInAt,
        checkOutAt,
        fee,
        status,
        syncStatus,
        createdAt,
        serverTicketId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tickets';
  @override
  VerificationContext validateIntegrity(Insertable<Ticket> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(_shiftIdMeta,
          shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta));
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('plate_number')) {
      context.handle(
          _plateNumberMeta,
          plateNumber.isAcceptableOrUnknown(
              data['plate_number']!, _plateNumberMeta));
    } else if (isInserting) {
      context.missing(_plateNumberMeta);
    }
    if (data.containsKey('vehicle_brand')) {
      context.handle(
          _vehicleBrandMeta,
          vehicleBrand.isAcceptableOrUnknown(
              data['vehicle_brand']!, _vehicleBrandMeta));
    } else if (isInserting) {
      context.missing(_vehicleBrandMeta);
    }
    if (data.containsKey('vehicle_color')) {
      context.handle(
          _vehicleColorMeta,
          vehicleColor.isAcceptableOrUnknown(
              data['vehicle_color']!, _vehicleColorMeta));
    } else if (isInserting) {
      context.missing(_vehicleColorMeta);
    }
    if (data.containsKey('vehicle_type')) {
      context.handle(
          _vehicleTypeMeta,
          vehicleType.isAcceptableOrUnknown(
              data['vehicle_type']!, _vehicleTypeMeta));
    } else if (isInserting) {
      context.missing(_vehicleTypeMeta);
    }
    if (data.containsKey('cellphone_number')) {
      context.handle(
          _cellphoneNumberMeta,
          cellphoneNumber.isAcceptableOrUnknown(
              data['cellphone_number']!, _cellphoneNumberMeta));
    } else if (isInserting) {
      context.missing(_cellphoneNumberMeta);
    }
    if (data.containsKey('damage_markers')) {
      context.handle(
          _damageMarkersMeta,
          damageMarkers.isAcceptableOrUnknown(
              data['damage_markers']!, _damageMarkersMeta));
    } else if (isInserting) {
      context.missing(_damageMarkersMeta);
    }
    if (data.containsKey('personal_belongings')) {
      context.handle(
          _personalBelongingsMeta,
          personalBelongings.isAcceptableOrUnknown(
              data['personal_belongings']!, _personalBelongingsMeta));
    } else if (isInserting) {
      context.missing(_personalBelongingsMeta);
    }
    if (data.containsKey('signature_png')) {
      context.handle(
          _signaturePngMeta,
          signaturePng.isAcceptableOrUnknown(
              data['signature_png']!, _signaturePngMeta));
    }
    if (data.containsKey('check_in_at')) {
      context.handle(
          _checkInAtMeta,
          checkInAt.isAcceptableOrUnknown(
              data['check_in_at']!, _checkInAtMeta));
    } else if (isInserting) {
      context.missing(_checkInAtMeta);
    }
    if (data.containsKey('check_out_at')) {
      context.handle(
          _checkOutAtMeta,
          checkOutAt.isAcceptableOrUnknown(
              data['check_out_at']!, _checkOutAtMeta));
    }
    if (data.containsKey('fee')) {
      context.handle(
          _feeMeta, fee.isAcceptableOrUnknown(data['fee']!, _feeMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('server_ticket_id')) {
      context.handle(
          _serverTicketIdMeta,
          serverTicketId.isAcceptableOrUnknown(
              data['server_ticket_id']!, _serverTicketIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ticket map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ticket(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      shiftId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shift_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      plateNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plate_number'])!,
      vehicleBrand: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vehicle_brand'])!,
      vehicleColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vehicle_color'])!,
      vehicleType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vehicle_type'])!,
      cellphoneNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}cellphone_number'])!,
      damageMarkers: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}damage_markers'])!,
      personalBelongings: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}personal_belongings'])!,
      signaturePng: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}signature_png']),
      checkInAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}check_in_at'])!,
      checkOutAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}check_out_at']),
      fee: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fee']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      serverTicketId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}server_ticket_id']),
    );
  }

  @override
  $TicketsTable createAlias(String alias) {
    return $TicketsTable(attachedDatabase, alias);
  }
}

class Ticket extends DataClass implements Insertable<Ticket> {
  final String id;
  final String shiftId;
  final String userId;
  final String branchId;
  final String plateNumber;
  final String vehicleBrand;
  final String vehicleColor;
  final String vehicleType;
  final String cellphoneNumber;

  /// JSON: [{zone, type, x, y}, ...]
  final String damageMarkers;

  /// JSON: ["iPad", ...]
  final String personalBelongings;

  /// Base64-encoded PNG, nullable until signed.
  final String? signaturePng;
  final String checkInAt;
  final String? checkOutAt;
  final double? fee;

  /// `active` | `completed` | `lost` | `draft` (reserved id before check-in completes)
  final String status;

  /// `pending` | `synced`
  final String syncStatus;
  final String createdAt;

  /// Server `transactions.id` (UUID) after draft POST; local [id] stays `TKT-…`.
  final String? serverTicketId;
  const Ticket(
      {required this.id,
      required this.shiftId,
      required this.userId,
      required this.branchId,
      required this.plateNumber,
      required this.vehicleBrand,
      required this.vehicleColor,
      required this.vehicleType,
      required this.cellphoneNumber,
      required this.damageMarkers,
      required this.personalBelongings,
      this.signaturePng,
      required this.checkInAt,
      this.checkOutAt,
      this.fee,
      required this.status,
      required this.syncStatus,
      required this.createdAt,
      this.serverTicketId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shift_id'] = Variable<String>(shiftId);
    map['user_id'] = Variable<String>(userId);
    map['branch_id'] = Variable<String>(branchId);
    map['plate_number'] = Variable<String>(plateNumber);
    map['vehicle_brand'] = Variable<String>(vehicleBrand);
    map['vehicle_color'] = Variable<String>(vehicleColor);
    map['vehicle_type'] = Variable<String>(vehicleType);
    map['cellphone_number'] = Variable<String>(cellphoneNumber);
    map['damage_markers'] = Variable<String>(damageMarkers);
    map['personal_belongings'] = Variable<String>(personalBelongings);
    if (!nullToAbsent || signaturePng != null) {
      map['signature_png'] = Variable<String>(signaturePng);
    }
    map['check_in_at'] = Variable<String>(checkInAt);
    if (!nullToAbsent || checkOutAt != null) {
      map['check_out_at'] = Variable<String>(checkOutAt);
    }
    if (!nullToAbsent || fee != null) {
      map['fee'] = Variable<double>(fee);
    }
    map['status'] = Variable<String>(status);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || serverTicketId != null) {
      map['server_ticket_id'] = Variable<String>(serverTicketId);
    }
    return map;
  }

  TicketsCompanion toCompanion(bool nullToAbsent) {
    return TicketsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      userId: Value(userId),
      branchId: Value(branchId),
      plateNumber: Value(plateNumber),
      vehicleBrand: Value(vehicleBrand),
      vehicleColor: Value(vehicleColor),
      vehicleType: Value(vehicleType),
      cellphoneNumber: Value(cellphoneNumber),
      damageMarkers: Value(damageMarkers),
      personalBelongings: Value(personalBelongings),
      signaturePng: signaturePng == null && nullToAbsent
          ? const Value.absent()
          : Value(signaturePng),
      checkInAt: Value(checkInAt),
      checkOutAt: checkOutAt == null && nullToAbsent
          ? const Value.absent()
          : Value(checkOutAt),
      fee: fee == null && nullToAbsent ? const Value.absent() : Value(fee),
      status: Value(status),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      serverTicketId: serverTicketId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverTicketId),
    );
  }

  factory Ticket.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ticket(
      id: serializer.fromJson<String>(json['id']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      userId: serializer.fromJson<String>(json['userId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      plateNumber: serializer.fromJson<String>(json['plateNumber']),
      vehicleBrand: serializer.fromJson<String>(json['vehicleBrand']),
      vehicleColor: serializer.fromJson<String>(json['vehicleColor']),
      vehicleType: serializer.fromJson<String>(json['vehicleType']),
      cellphoneNumber: serializer.fromJson<String>(json['cellphoneNumber']),
      damageMarkers: serializer.fromJson<String>(json['damageMarkers']),
      personalBelongings:
          serializer.fromJson<String>(json['personalBelongings']),
      signaturePng: serializer.fromJson<String?>(json['signaturePng']),
      checkInAt: serializer.fromJson<String>(json['checkInAt']),
      checkOutAt: serializer.fromJson<String?>(json['checkOutAt']),
      fee: serializer.fromJson<double?>(json['fee']),
      status: serializer.fromJson<String>(json['status']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      serverTicketId: serializer.fromJson<String?>(json['serverTicketId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shiftId': serializer.toJson<String>(shiftId),
      'userId': serializer.toJson<String>(userId),
      'branchId': serializer.toJson<String>(branchId),
      'plateNumber': serializer.toJson<String>(plateNumber),
      'vehicleBrand': serializer.toJson<String>(vehicleBrand),
      'vehicleColor': serializer.toJson<String>(vehicleColor),
      'vehicleType': serializer.toJson<String>(vehicleType),
      'cellphoneNumber': serializer.toJson<String>(cellphoneNumber),
      'damageMarkers': serializer.toJson<String>(damageMarkers),
      'personalBelongings': serializer.toJson<String>(personalBelongings),
      'signaturePng': serializer.toJson<String?>(signaturePng),
      'checkInAt': serializer.toJson<String>(checkInAt),
      'checkOutAt': serializer.toJson<String?>(checkOutAt),
      'fee': serializer.toJson<double?>(fee),
      'status': serializer.toJson<String>(status),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<String>(createdAt),
      'serverTicketId': serializer.toJson<String?>(serverTicketId),
    };
  }

  Ticket copyWith(
          {String? id,
          String? shiftId,
          String? userId,
          String? branchId,
          String? plateNumber,
          String? vehicleBrand,
          String? vehicleColor,
          String? vehicleType,
          String? cellphoneNumber,
          String? damageMarkers,
          String? personalBelongings,
          Value<String?> signaturePng = const Value.absent(),
          String? checkInAt,
          Value<String?> checkOutAt = const Value.absent(),
          Value<double?> fee = const Value.absent(),
          String? status,
          String? syncStatus,
          String? createdAt,
          Value<String?> serverTicketId = const Value.absent()}) =>
      Ticket(
        id: id ?? this.id,
        shiftId: shiftId ?? this.shiftId,
        userId: userId ?? this.userId,
        branchId: branchId ?? this.branchId,
        plateNumber: plateNumber ?? this.plateNumber,
        vehicleBrand: vehicleBrand ?? this.vehicleBrand,
        vehicleColor: vehicleColor ?? this.vehicleColor,
        vehicleType: vehicleType ?? this.vehicleType,
        cellphoneNumber: cellphoneNumber ?? this.cellphoneNumber,
        damageMarkers: damageMarkers ?? this.damageMarkers,
        personalBelongings: personalBelongings ?? this.personalBelongings,
        signaturePng:
            signaturePng.present ? signaturePng.value : this.signaturePng,
        checkInAt: checkInAt ?? this.checkInAt,
        checkOutAt: checkOutAt.present ? checkOutAt.value : this.checkOutAt,
        fee: fee.present ? fee.value : this.fee,
        status: status ?? this.status,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        serverTicketId:
            serverTicketId.present ? serverTicketId.value : this.serverTicketId,
      );
  Ticket copyWithCompanion(TicketsCompanion data) {
    return Ticket(
      id: data.id.present ? data.id.value : this.id,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      userId: data.userId.present ? data.userId.value : this.userId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      plateNumber:
          data.plateNumber.present ? data.plateNumber.value : this.plateNumber,
      vehicleBrand: data.vehicleBrand.present
          ? data.vehicleBrand.value
          : this.vehicleBrand,
      vehicleColor: data.vehicleColor.present
          ? data.vehicleColor.value
          : this.vehicleColor,
      vehicleType:
          data.vehicleType.present ? data.vehicleType.value : this.vehicleType,
      cellphoneNumber: data.cellphoneNumber.present
          ? data.cellphoneNumber.value
          : this.cellphoneNumber,
      damageMarkers: data.damageMarkers.present
          ? data.damageMarkers.value
          : this.damageMarkers,
      personalBelongings: data.personalBelongings.present
          ? data.personalBelongings.value
          : this.personalBelongings,
      signaturePng: data.signaturePng.present
          ? data.signaturePng.value
          : this.signaturePng,
      checkInAt: data.checkInAt.present ? data.checkInAt.value : this.checkInAt,
      checkOutAt:
          data.checkOutAt.present ? data.checkOutAt.value : this.checkOutAt,
      fee: data.fee.present ? data.fee.value : this.fee,
      status: data.status.present ? data.status.value : this.status,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      serverTicketId: data.serverTicketId.present
          ? data.serverTicketId.value
          : this.serverTicketId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ticket(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('userId: $userId, ')
          ..write('branchId: $branchId, ')
          ..write('plateNumber: $plateNumber, ')
          ..write('vehicleBrand: $vehicleBrand, ')
          ..write('vehicleColor: $vehicleColor, ')
          ..write('vehicleType: $vehicleType, ')
          ..write('cellphoneNumber: $cellphoneNumber, ')
          ..write('damageMarkers: $damageMarkers, ')
          ..write('personalBelongings: $personalBelongings, ')
          ..write('signaturePng: $signaturePng, ')
          ..write('checkInAt: $checkInAt, ')
          ..write('checkOutAt: $checkOutAt, ')
          ..write('fee: $fee, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverTicketId: $serverTicketId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      shiftId,
      userId,
      branchId,
      plateNumber,
      vehicleBrand,
      vehicleColor,
      vehicleType,
      cellphoneNumber,
      damageMarkers,
      personalBelongings,
      signaturePng,
      checkInAt,
      checkOutAt,
      fee,
      status,
      syncStatus,
      createdAt,
      serverTicketId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ticket &&
          other.id == this.id &&
          other.shiftId == this.shiftId &&
          other.userId == this.userId &&
          other.branchId == this.branchId &&
          other.plateNumber == this.plateNumber &&
          other.vehicleBrand == this.vehicleBrand &&
          other.vehicleColor == this.vehicleColor &&
          other.vehicleType == this.vehicleType &&
          other.cellphoneNumber == this.cellphoneNumber &&
          other.damageMarkers == this.damageMarkers &&
          other.personalBelongings == this.personalBelongings &&
          other.signaturePng == this.signaturePng &&
          other.checkInAt == this.checkInAt &&
          other.checkOutAt == this.checkOutAt &&
          other.fee == this.fee &&
          other.status == this.status &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.serverTicketId == this.serverTicketId);
}

class TicketsCompanion extends UpdateCompanion<Ticket> {
  final Value<String> id;
  final Value<String> shiftId;
  final Value<String> userId;
  final Value<String> branchId;
  final Value<String> plateNumber;
  final Value<String> vehicleBrand;
  final Value<String> vehicleColor;
  final Value<String> vehicleType;
  final Value<String> cellphoneNumber;
  final Value<String> damageMarkers;
  final Value<String> personalBelongings;
  final Value<String?> signaturePng;
  final Value<String> checkInAt;
  final Value<String?> checkOutAt;
  final Value<double?> fee;
  final Value<String> status;
  final Value<String> syncStatus;
  final Value<String> createdAt;
  final Value<String?> serverTicketId;
  final Value<int> rowid;
  const TicketsCompanion({
    this.id = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.userId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.plateNumber = const Value.absent(),
    this.vehicleBrand = const Value.absent(),
    this.vehicleColor = const Value.absent(),
    this.vehicleType = const Value.absent(),
    this.cellphoneNumber = const Value.absent(),
    this.damageMarkers = const Value.absent(),
    this.personalBelongings = const Value.absent(),
    this.signaturePng = const Value.absent(),
    this.checkInAt = const Value.absent(),
    this.checkOutAt = const Value.absent(),
    this.fee = const Value.absent(),
    this.status = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.serverTicketId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TicketsCompanion.insert({
    required String id,
    required String shiftId,
    required String userId,
    required String branchId,
    required String plateNumber,
    required String vehicleBrand,
    required String vehicleColor,
    required String vehicleType,
    required String cellphoneNumber,
    required String damageMarkers,
    required String personalBelongings,
    this.signaturePng = const Value.absent(),
    required String checkInAt,
    this.checkOutAt = const Value.absent(),
    this.fee = const Value.absent(),
    required String status,
    required String syncStatus,
    required String createdAt,
    this.serverTicketId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        shiftId = Value(shiftId),
        userId = Value(userId),
        branchId = Value(branchId),
        plateNumber = Value(plateNumber),
        vehicleBrand = Value(vehicleBrand),
        vehicleColor = Value(vehicleColor),
        vehicleType = Value(vehicleType),
        cellphoneNumber = Value(cellphoneNumber),
        damageMarkers = Value(damageMarkers),
        personalBelongings = Value(personalBelongings),
        checkInAt = Value(checkInAt),
        status = Value(status),
        syncStatus = Value(syncStatus),
        createdAt = Value(createdAt);
  static Insertable<Ticket> custom({
    Expression<String>? id,
    Expression<String>? shiftId,
    Expression<String>? userId,
    Expression<String>? branchId,
    Expression<String>? plateNumber,
    Expression<String>? vehicleBrand,
    Expression<String>? vehicleColor,
    Expression<String>? vehicleType,
    Expression<String>? cellphoneNumber,
    Expression<String>? damageMarkers,
    Expression<String>? personalBelongings,
    Expression<String>? signaturePng,
    Expression<String>? checkInAt,
    Expression<String>? checkOutAt,
    Expression<double>? fee,
    Expression<String>? status,
    Expression<String>? syncStatus,
    Expression<String>? createdAt,
    Expression<String>? serverTicketId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shiftId != null) 'shift_id': shiftId,
      if (userId != null) 'user_id': userId,
      if (branchId != null) 'branch_id': branchId,
      if (plateNumber != null) 'plate_number': plateNumber,
      if (vehicleBrand != null) 'vehicle_brand': vehicleBrand,
      if (vehicleColor != null) 'vehicle_color': vehicleColor,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (cellphoneNumber != null) 'cellphone_number': cellphoneNumber,
      if (damageMarkers != null) 'damage_markers': damageMarkers,
      if (personalBelongings != null) 'personal_belongings': personalBelongings,
      if (signaturePng != null) 'signature_png': signaturePng,
      if (checkInAt != null) 'check_in_at': checkInAt,
      if (checkOutAt != null) 'check_out_at': checkOutAt,
      if (fee != null) 'fee': fee,
      if (status != null) 'status': status,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (serverTicketId != null) 'server_ticket_id': serverTicketId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TicketsCompanion copyWith(
      {Value<String>? id,
      Value<String>? shiftId,
      Value<String>? userId,
      Value<String>? branchId,
      Value<String>? plateNumber,
      Value<String>? vehicleBrand,
      Value<String>? vehicleColor,
      Value<String>? vehicleType,
      Value<String>? cellphoneNumber,
      Value<String>? damageMarkers,
      Value<String>? personalBelongings,
      Value<String?>? signaturePng,
      Value<String>? checkInAt,
      Value<String?>? checkOutAt,
      Value<double?>? fee,
      Value<String>? status,
      Value<String>? syncStatus,
      Value<String>? createdAt,
      Value<String?>? serverTicketId,
      Value<int>? rowid}) {
    return TicketsCompanion(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      userId: userId ?? this.userId,
      branchId: branchId ?? this.branchId,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleType: vehicleType ?? this.vehicleType,
      cellphoneNumber: cellphoneNumber ?? this.cellphoneNumber,
      damageMarkers: damageMarkers ?? this.damageMarkers,
      personalBelongings: personalBelongings ?? this.personalBelongings,
      signaturePng: signaturePng ?? this.signaturePng,
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      fee: fee ?? this.fee,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      serverTicketId: serverTicketId ?? this.serverTicketId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (plateNumber.present) {
      map['plate_number'] = Variable<String>(plateNumber.value);
    }
    if (vehicleBrand.present) {
      map['vehicle_brand'] = Variable<String>(vehicleBrand.value);
    }
    if (vehicleColor.present) {
      map['vehicle_color'] = Variable<String>(vehicleColor.value);
    }
    if (vehicleType.present) {
      map['vehicle_type'] = Variable<String>(vehicleType.value);
    }
    if (cellphoneNumber.present) {
      map['cellphone_number'] = Variable<String>(cellphoneNumber.value);
    }
    if (damageMarkers.present) {
      map['damage_markers'] = Variable<String>(damageMarkers.value);
    }
    if (personalBelongings.present) {
      map['personal_belongings'] = Variable<String>(personalBelongings.value);
    }
    if (signaturePng.present) {
      map['signature_png'] = Variable<String>(signaturePng.value);
    }
    if (checkInAt.present) {
      map['check_in_at'] = Variable<String>(checkInAt.value);
    }
    if (checkOutAt.present) {
      map['check_out_at'] = Variable<String>(checkOutAt.value);
    }
    if (fee.present) {
      map['fee'] = Variable<double>(fee.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (serverTicketId.present) {
      map['server_ticket_id'] = Variable<String>(serverTicketId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TicketsCompanion(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('userId: $userId, ')
          ..write('branchId: $branchId, ')
          ..write('plateNumber: $plateNumber, ')
          ..write('vehicleBrand: $vehicleBrand, ')
          ..write('vehicleColor: $vehicleColor, ')
          ..write('vehicleType: $vehicleType, ')
          ..write('cellphoneNumber: $cellphoneNumber, ')
          ..write('damageMarkers: $damageMarkers, ')
          ..write('personalBelongings: $personalBelongings, ')
          ..write('signaturePng: $signaturePng, ')
          ..write('checkInAt: $checkInAt, ')
          ..write('checkOutAt: $checkOutAt, ')
          ..write('fee: $fee, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverTicketId: $serverTicketId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _queueTableNameMeta =
      const VerificationMeta('queueTableName');
  @override
  late final GeneratedColumn<String> queueTableName = GeneratedColumn<String>(
      'table_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
      'record_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        operation,
        queueTableName,
        recordId,
        payload,
        syncStatus,
        retryCount,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('table_name')) {
      context.handle(
          _queueTableNameMeta,
          queueTableName.isAcceptableOrUnknown(
              data['table_name']!, _queueTableNameMeta));
    } else if (isInserting) {
      context.missing(_queueTableNameMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      queueTableName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}table_name'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_id'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String id;

  /// `create` | `update`
  final String operation;

  /// Logical table for API routing: `shifts` | `tickets` (SQL: `table_name`).
  final String queueTableName;
  final String recordId;

  /// Full row JSON.
  final String payload;

  /// `pending` | `synced` | `failed`
  final String syncStatus;
  final int retryCount;
  final String createdAt;
  const SyncQueueData(
      {required this.id,
      required this.operation,
      required this.queueTableName,
      required this.recordId,
      required this.payload,
      required this.syncStatus,
      required this.retryCount,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['operation'] = Variable<String>(operation);
    map['table_name'] = Variable<String>(queueTableName);
    map['record_id'] = Variable<String>(recordId);
    map['payload'] = Variable<String>(payload);
    map['sync_status'] = Variable<String>(syncStatus);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      operation: Value(operation),
      queueTableName: Value(queueTableName),
      recordId: Value(recordId),
      payload: Value(payload),
      syncStatus: Value(syncStatus),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      operation: serializer.fromJson<String>(json['operation']),
      queueTableName: serializer.fromJson<String>(json['queueTableName']),
      recordId: serializer.fromJson<String>(json['recordId']),
      payload: serializer.fromJson<String>(json['payload']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operation': serializer.toJson<String>(operation),
      'queueTableName': serializer.toJson<String>(queueTableName),
      'recordId': serializer.toJson<String>(recordId),
      'payload': serializer.toJson<String>(payload),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  SyncQueueData copyWith(
          {String? id,
          String? operation,
          String? queueTableName,
          String? recordId,
          String? payload,
          String? syncStatus,
          int? retryCount,
          String? createdAt}) =>
      SyncQueueData(
        id: id ?? this.id,
        operation: operation ?? this.operation,
        queueTableName: queueTableName ?? this.queueTableName,
        recordId: recordId ?? this.recordId,
        payload: payload ?? this.payload,
        syncStatus: syncStatus ?? this.syncStatus,
        retryCount: retryCount ?? this.retryCount,
        createdAt: createdAt ?? this.createdAt,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      operation: data.operation.present ? data.operation.value : this.operation,
      queueTableName: data.queueTableName.present
          ? data.queueTableName.value
          : this.queueTableName,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      payload: data.payload.present ? data.payload.value : this.payload,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('queueTableName: $queueTableName, ')
          ..write('recordId: $recordId, ')
          ..write('payload: $payload, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, operation, queueTableName, recordId,
      payload, syncStatus, retryCount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.operation == this.operation &&
          other.queueTableName == this.queueTableName &&
          other.recordId == this.recordId &&
          other.payload == this.payload &&
          other.syncStatus == this.syncStatus &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> id;
  final Value<String> operation;
  final Value<String> queueTableName;
  final Value<String> recordId;
  final Value<String> payload;
  final Value<String> syncStatus;
  final Value<int> retryCount;
  final Value<String> createdAt;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.operation = const Value.absent(),
    this.queueTableName = const Value.absent(),
    this.recordId = const Value.absent(),
    this.payload = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String operation,
    required String queueTableName,
    required String recordId,
    required String payload,
    required String syncStatus,
    this.retryCount = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        operation = Value(operation),
        queueTableName = Value(queueTableName),
        recordId = Value(recordId),
        payload = Value(payload),
        syncStatus = Value(syncStatus),
        createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? operation,
    Expression<String>? queueTableName,
    Expression<String>? recordId,
    Expression<String>? payload,
    Expression<String>? syncStatus,
    Expression<int>? retryCount,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operation != null) 'operation': operation,
      if (queueTableName != null) 'table_name': queueTableName,
      if (recordId != null) 'record_id': recordId,
      if (payload != null) 'payload': payload,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<String>? id,
      Value<String>? operation,
      Value<String>? queueTableName,
      Value<String>? recordId,
      Value<String>? payload,
      Value<String>? syncStatus,
      Value<int>? retryCount,
      Value<String>? createdAt,
      Value<int>? rowid}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      queueTableName: queueTableName ?? this.queueTableName,
      recordId: recordId ?? this.recordId,
      payload: payload ?? this.payload,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (queueTableName.present) {
      map['table_name'] = Variable<String>(queueTableName.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('queueTableName: $queueTableName, ')
          ..write('recordId: $recordId, ')
          ..write('payload: $payload, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RatesTable extends Rates with TableInfo<$RatesTable, Rate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vehicleTypeMeta =
      const VerificationMeta('vehicleType');
  @override
  late final GeneratedColumn<String> vehicleType = GeneratedColumn<String>(
      'vehicle_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _flatRateHoursMeta =
      const VerificationMeta('flatRateHours');
  @override
  late final GeneratedColumn<int> flatRateHours = GeneratedColumn<int>(
      'flat_rate_hours', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _flatRateFeeMeta =
      const VerificationMeta('flatRateFee');
  @override
  late final GeneratedColumn<double> flatRateFee = GeneratedColumn<double>(
      'flat_rate_fee', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _succeedingHourFeeMeta =
      const VerificationMeta('succeedingHourFee');
  @override
  late final GeneratedColumn<double> succeedingHourFee =
      GeneratedColumn<double>('succeeding_hour_fee', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _overnightFeeMeta =
      const VerificationMeta('overnightFee');
  @override
  late final GeneratedColumn<double> overnightFee = GeneratedColumn<double>(
      'overnight_fee', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lostTicketFeeMeta =
      const VerificationMeta('lostTicketFee');
  @override
  late final GeneratedColumn<double> lostTicketFee = GeneratedColumn<double>(
      'lost_ticket_fee', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        branchId,
        vehicleType,
        flatRateHours,
        flatRateFee,
        succeedingHourFee,
        overnightFee,
        lostTicketFee,
        syncStatus,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rates';
  @override
  VerificationContext validateIntegrity(Insertable<Rate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('vehicle_type')) {
      context.handle(
          _vehicleTypeMeta,
          vehicleType.isAcceptableOrUnknown(
              data['vehicle_type']!, _vehicleTypeMeta));
    } else if (isInserting) {
      context.missing(_vehicleTypeMeta);
    }
    if (data.containsKey('flat_rate_hours')) {
      context.handle(
          _flatRateHoursMeta,
          flatRateHours.isAcceptableOrUnknown(
              data['flat_rate_hours']!, _flatRateHoursMeta));
    } else if (isInserting) {
      context.missing(_flatRateHoursMeta);
    }
    if (data.containsKey('flat_rate_fee')) {
      context.handle(
          _flatRateFeeMeta,
          flatRateFee.isAcceptableOrUnknown(
              data['flat_rate_fee']!, _flatRateFeeMeta));
    } else if (isInserting) {
      context.missing(_flatRateFeeMeta);
    }
    if (data.containsKey('succeeding_hour_fee')) {
      context.handle(
          _succeedingHourFeeMeta,
          succeedingHourFee.isAcceptableOrUnknown(
              data['succeeding_hour_fee']!, _succeedingHourFeeMeta));
    } else if (isInserting) {
      context.missing(_succeedingHourFeeMeta);
    }
    if (data.containsKey('overnight_fee')) {
      context.handle(
          _overnightFeeMeta,
          overnightFee.isAcceptableOrUnknown(
              data['overnight_fee']!, _overnightFeeMeta));
    } else if (isInserting) {
      context.missing(_overnightFeeMeta);
    }
    if (data.containsKey('lost_ticket_fee')) {
      context.handle(
          _lostTicketFeeMeta,
          lostTicketFee.isAcceptableOrUnknown(
              data['lost_ticket_fee']!, _lostTicketFeeMeta));
    } else if (isInserting) {
      context.missing(_lostTicketFeeMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {branchId, vehicleType},
      ];
  @override
  Rate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Rate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      vehicleType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vehicle_type'])!,
      flatRateHours: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}flat_rate_hours'])!,
      flatRateFee: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}flat_rate_fee'])!,
      succeedingHourFee: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}succeeding_hour_fee'])!,
      overnightFee: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}overnight_fee'])!,
      lostTicketFee: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}lost_ticket_fee'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $RatesTable createAlias(String alias) {
    return $RatesTable(attachedDatabase, alias);
  }
}

class Rate extends DataClass implements Insertable<Rate> {
  final String id;
  final String branchId;
  final String vehicleType;
  final int flatRateHours;
  final double flatRateFee;
  final double succeedingHourFee;
  final double overnightFee;
  final double lostTicketFee;

  /// `pending` | `synced`
  final String syncStatus;
  final String updatedAt;
  const Rate(
      {required this.id,
      required this.branchId,
      required this.vehicleType,
      required this.flatRateHours,
      required this.flatRateFee,
      required this.succeedingHourFee,
      required this.overnightFee,
      required this.lostTicketFee,
      required this.syncStatus,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['branch_id'] = Variable<String>(branchId);
    map['vehicle_type'] = Variable<String>(vehicleType);
    map['flat_rate_hours'] = Variable<int>(flatRateHours);
    map['flat_rate_fee'] = Variable<double>(flatRateFee);
    map['succeeding_hour_fee'] = Variable<double>(succeedingHourFee);
    map['overnight_fee'] = Variable<double>(overnightFee);
    map['lost_ticket_fee'] = Variable<double>(lostTicketFee);
    map['sync_status'] = Variable<String>(syncStatus);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  RatesCompanion toCompanion(bool nullToAbsent) {
    return RatesCompanion(
      id: Value(id),
      branchId: Value(branchId),
      vehicleType: Value(vehicleType),
      flatRateHours: Value(flatRateHours),
      flatRateFee: Value(flatRateFee),
      succeedingHourFee: Value(succeedingHourFee),
      overnightFee: Value(overnightFee),
      lostTicketFee: Value(lostTicketFee),
      syncStatus: Value(syncStatus),
      updatedAt: Value(updatedAt),
    );
  }

  factory Rate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Rate(
      id: serializer.fromJson<String>(json['id']),
      branchId: serializer.fromJson<String>(json['branchId']),
      vehicleType: serializer.fromJson<String>(json['vehicleType']),
      flatRateHours: serializer.fromJson<int>(json['flatRateHours']),
      flatRateFee: serializer.fromJson<double>(json['flatRateFee']),
      succeedingHourFee: serializer.fromJson<double>(json['succeedingHourFee']),
      overnightFee: serializer.fromJson<double>(json['overnightFee']),
      lostTicketFee: serializer.fromJson<double>(json['lostTicketFee']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'branchId': serializer.toJson<String>(branchId),
      'vehicleType': serializer.toJson<String>(vehicleType),
      'flatRateHours': serializer.toJson<int>(flatRateHours),
      'flatRateFee': serializer.toJson<double>(flatRateFee),
      'succeedingHourFee': serializer.toJson<double>(succeedingHourFee),
      'overnightFee': serializer.toJson<double>(overnightFee),
      'lostTicketFee': serializer.toJson<double>(lostTicketFee),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Rate copyWith(
          {String? id,
          String? branchId,
          String? vehicleType,
          int? flatRateHours,
          double? flatRateFee,
          double? succeedingHourFee,
          double? overnightFee,
          double? lostTicketFee,
          String? syncStatus,
          String? updatedAt}) =>
      Rate(
        id: id ?? this.id,
        branchId: branchId ?? this.branchId,
        vehicleType: vehicleType ?? this.vehicleType,
        flatRateHours: flatRateHours ?? this.flatRateHours,
        flatRateFee: flatRateFee ?? this.flatRateFee,
        succeedingHourFee: succeedingHourFee ?? this.succeedingHourFee,
        overnightFee: overnightFee ?? this.overnightFee,
        lostTicketFee: lostTicketFee ?? this.lostTicketFee,
        syncStatus: syncStatus ?? this.syncStatus,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Rate copyWithCompanion(RatesCompanion data) {
    return Rate(
      id: data.id.present ? data.id.value : this.id,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      vehicleType:
          data.vehicleType.present ? data.vehicleType.value : this.vehicleType,
      flatRateHours: data.flatRateHours.present
          ? data.flatRateHours.value
          : this.flatRateHours,
      flatRateFee:
          data.flatRateFee.present ? data.flatRateFee.value : this.flatRateFee,
      succeedingHourFee: data.succeedingHourFee.present
          ? data.succeedingHourFee.value
          : this.succeedingHourFee,
      overnightFee: data.overnightFee.present
          ? data.overnightFee.value
          : this.overnightFee,
      lostTicketFee: data.lostTicketFee.present
          ? data.lostTicketFee.value
          : this.lostTicketFee,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Rate(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('vehicleType: $vehicleType, ')
          ..write('flatRateHours: $flatRateHours, ')
          ..write('flatRateFee: $flatRateFee, ')
          ..write('succeedingHourFee: $succeedingHourFee, ')
          ..write('overnightFee: $overnightFee, ')
          ..write('lostTicketFee: $lostTicketFee, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      branchId,
      vehicleType,
      flatRateHours,
      flatRateFee,
      succeedingHourFee,
      overnightFee,
      lostTicketFee,
      syncStatus,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Rate &&
          other.id == this.id &&
          other.branchId == this.branchId &&
          other.vehicleType == this.vehicleType &&
          other.flatRateHours == this.flatRateHours &&
          other.flatRateFee == this.flatRateFee &&
          other.succeedingHourFee == this.succeedingHourFee &&
          other.overnightFee == this.overnightFee &&
          other.lostTicketFee == this.lostTicketFee &&
          other.syncStatus == this.syncStatus &&
          other.updatedAt == this.updatedAt);
}

class RatesCompanion extends UpdateCompanion<Rate> {
  final Value<String> id;
  final Value<String> branchId;
  final Value<String> vehicleType;
  final Value<int> flatRateHours;
  final Value<double> flatRateFee;
  final Value<double> succeedingHourFee;
  final Value<double> overnightFee;
  final Value<double> lostTicketFee;
  final Value<String> syncStatus;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const RatesCompanion({
    this.id = const Value.absent(),
    this.branchId = const Value.absent(),
    this.vehicleType = const Value.absent(),
    this.flatRateHours = const Value.absent(),
    this.flatRateFee = const Value.absent(),
    this.succeedingHourFee = const Value.absent(),
    this.overnightFee = const Value.absent(),
    this.lostTicketFee = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RatesCompanion.insert({
    required String id,
    required String branchId,
    required String vehicleType,
    required int flatRateHours,
    required double flatRateFee,
    required double succeedingHourFee,
    required double overnightFee,
    required double lostTicketFee,
    required String syncStatus,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        branchId = Value(branchId),
        vehicleType = Value(vehicleType),
        flatRateHours = Value(flatRateHours),
        flatRateFee = Value(flatRateFee),
        succeedingHourFee = Value(succeedingHourFee),
        overnightFee = Value(overnightFee),
        lostTicketFee = Value(lostTicketFee),
        syncStatus = Value(syncStatus),
        updatedAt = Value(updatedAt);
  static Insertable<Rate> custom({
    Expression<String>? id,
    Expression<String>? branchId,
    Expression<String>? vehicleType,
    Expression<int>? flatRateHours,
    Expression<double>? flatRateFee,
    Expression<double>? succeedingHourFee,
    Expression<double>? overnightFee,
    Expression<double>? lostTicketFee,
    Expression<String>? syncStatus,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (branchId != null) 'branch_id': branchId,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (flatRateHours != null) 'flat_rate_hours': flatRateHours,
      if (flatRateFee != null) 'flat_rate_fee': flatRateFee,
      if (succeedingHourFee != null) 'succeeding_hour_fee': succeedingHourFee,
      if (overnightFee != null) 'overnight_fee': overnightFee,
      if (lostTicketFee != null) 'lost_ticket_fee': lostTicketFee,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RatesCompanion copyWith(
      {Value<String>? id,
      Value<String>? branchId,
      Value<String>? vehicleType,
      Value<int>? flatRateHours,
      Value<double>? flatRateFee,
      Value<double>? succeedingHourFee,
      Value<double>? overnightFee,
      Value<double>? lostTicketFee,
      Value<String>? syncStatus,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return RatesCompanion(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      vehicleType: vehicleType ?? this.vehicleType,
      flatRateHours: flatRateHours ?? this.flatRateHours,
      flatRateFee: flatRateFee ?? this.flatRateFee,
      succeedingHourFee: succeedingHourFee ?? this.succeedingHourFee,
      overnightFee: overnightFee ?? this.overnightFee,
      lostTicketFee: lostTicketFee ?? this.lostTicketFee,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (vehicleType.present) {
      map['vehicle_type'] = Variable<String>(vehicleType.value);
    }
    if (flatRateHours.present) {
      map['flat_rate_hours'] = Variable<int>(flatRateHours.value);
    }
    if (flatRateFee.present) {
      map['flat_rate_fee'] = Variable<double>(flatRateFee.value);
    }
    if (succeedingHourFee.present) {
      map['succeeding_hour_fee'] = Variable<double>(succeedingHourFee.value);
    }
    if (overnightFee.present) {
      map['overnight_fee'] = Variable<double>(overnightFee.value);
    }
    if (lostTicketFee.present) {
      map['lost_ticket_fee'] = Variable<double>(lostTicketFee.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RatesCompanion(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('vehicleType: $vehicleType, ')
          ..write('flatRateHours: $flatRateHours, ')
          ..write('flatRateFee: $flatRateFee, ')
          ..write('succeedingHourFee: $succeedingHourFee, ')
          ..write('overnightFee: $overnightFee, ')
          ..write('lostTicketFee: $lostTicketFee, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BranchConfigsTable extends BranchConfigs
    with TableInfo<$BranchConfigsTable, BranchConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BranchConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _configKeyMeta =
      const VerificationMeta('configKey');
  @override
  late final GeneratedColumn<String> configKey = GeneratedColumn<String>(
      'config_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _configValueMeta =
      const VerificationMeta('configValue');
  @override
  late final GeneratedColumn<String> configValue = GeneratedColumn<String>(
      'config_value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, branchId, configKey, configValue, syncStatus, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'branch_config';
  @override
  VerificationContext validateIntegrity(Insertable<BranchConfig> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('config_key')) {
      context.handle(_configKeyMeta,
          configKey.isAcceptableOrUnknown(data['config_key']!, _configKeyMeta));
    } else if (isInserting) {
      context.missing(_configKeyMeta);
    }
    if (data.containsKey('config_value')) {
      context.handle(
          _configValueMeta,
          configValue.isAcceptableOrUnknown(
              data['config_value']!, _configValueMeta));
    } else if (isInserting) {
      context.missing(_configValueMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {branchId, configKey},
      ];
  @override
  BranchConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BranchConfig(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      configKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}config_key'])!,
      configValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}config_value'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BranchConfigsTable createAlias(String alias) {
    return $BranchConfigsTable(attachedDatabase, alias);
  }
}

class BranchConfig extends DataClass implements Insertable<BranchConfig> {
  final String id;
  final String branchId;
  final String configKey;
  final String configValue;

  /// `pending` | `synced`
  final String syncStatus;
  final String updatedAt;
  const BranchConfig(
      {required this.id,
      required this.branchId,
      required this.configKey,
      required this.configValue,
      required this.syncStatus,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['branch_id'] = Variable<String>(branchId);
    map['config_key'] = Variable<String>(configKey);
    map['config_value'] = Variable<String>(configValue);
    map['sync_status'] = Variable<String>(syncStatus);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  BranchConfigsCompanion toCompanion(bool nullToAbsent) {
    return BranchConfigsCompanion(
      id: Value(id),
      branchId: Value(branchId),
      configKey: Value(configKey),
      configValue: Value(configValue),
      syncStatus: Value(syncStatus),
      updatedAt: Value(updatedAt),
    );
  }

  factory BranchConfig.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BranchConfig(
      id: serializer.fromJson<String>(json['id']),
      branchId: serializer.fromJson<String>(json['branchId']),
      configKey: serializer.fromJson<String>(json['configKey']),
      configValue: serializer.fromJson<String>(json['configValue']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'branchId': serializer.toJson<String>(branchId),
      'configKey': serializer.toJson<String>(configKey),
      'configValue': serializer.toJson<String>(configValue),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  BranchConfig copyWith(
          {String? id,
          String? branchId,
          String? configKey,
          String? configValue,
          String? syncStatus,
          String? updatedAt}) =>
      BranchConfig(
        id: id ?? this.id,
        branchId: branchId ?? this.branchId,
        configKey: configKey ?? this.configKey,
        configValue: configValue ?? this.configValue,
        syncStatus: syncStatus ?? this.syncStatus,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BranchConfig copyWithCompanion(BranchConfigsCompanion data) {
    return BranchConfig(
      id: data.id.present ? data.id.value : this.id,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      configKey: data.configKey.present ? data.configKey.value : this.configKey,
      configValue:
          data.configValue.present ? data.configValue.value : this.configValue,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BranchConfig(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('configKey: $configKey, ')
          ..write('configValue: $configValue, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, branchId, configKey, configValue, syncStatus, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BranchConfig &&
          other.id == this.id &&
          other.branchId == this.branchId &&
          other.configKey == this.configKey &&
          other.configValue == this.configValue &&
          other.syncStatus == this.syncStatus &&
          other.updatedAt == this.updatedAt);
}

class BranchConfigsCompanion extends UpdateCompanion<BranchConfig> {
  final Value<String> id;
  final Value<String> branchId;
  final Value<String> configKey;
  final Value<String> configValue;
  final Value<String> syncStatus;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const BranchConfigsCompanion({
    this.id = const Value.absent(),
    this.branchId = const Value.absent(),
    this.configKey = const Value.absent(),
    this.configValue = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BranchConfigsCompanion.insert({
    required String id,
    required String branchId,
    required String configKey,
    required String configValue,
    required String syncStatus,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        branchId = Value(branchId),
        configKey = Value(configKey),
        configValue = Value(configValue),
        syncStatus = Value(syncStatus),
        updatedAt = Value(updatedAt);
  static Insertable<BranchConfig> custom({
    Expression<String>? id,
    Expression<String>? branchId,
    Expression<String>? configKey,
    Expression<String>? configValue,
    Expression<String>? syncStatus,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (branchId != null) 'branch_id': branchId,
      if (configKey != null) 'config_key': configKey,
      if (configValue != null) 'config_value': configValue,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BranchConfigsCompanion copyWith(
      {Value<String>? id,
      Value<String>? branchId,
      Value<String>? configKey,
      Value<String>? configValue,
      Value<String>? syncStatus,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return BranchConfigsCompanion(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      configKey: configKey ?? this.configKey,
      configValue: configValue ?? this.configValue,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (configKey.present) {
      map['config_key'] = Variable<String>(configKey.value);
    }
    if (configValue.present) {
      map['config_value'] = Variable<String>(configValue.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BranchConfigsCompanion(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('configKey: $configKey, ')
          ..write('configValue: $configValue, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DeviceInfoTable deviceInfo = $DeviceInfoTable(this);
  late final $DeviceIdentityTable deviceIdentity = $DeviceIdentityTable(this);
  late final $OfflineAccountsTable offlineAccounts =
      $OfflineAccountsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $ShiftsTable shifts = $ShiftsTable(this);
  late final $TicketsTable tickets = $TicketsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $RatesTable rates = $RatesTable(this);
  late final $BranchConfigsTable branchConfigs = $BranchConfigsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        deviceInfo,
        deviceIdentity,
        offlineAccounts,
        sessions,
        shifts,
        tickets,
        syncQueue,
        rates,
        branchConfigs
      ];
}

typedef $$DeviceInfoTableCreateCompanionBuilder = DeviceInfoCompanion Function({
  Value<int> id,
  required String deviceId,
  Value<String> branch,
  Value<String> area,
  required int registeredAt,
});
typedef $$DeviceInfoTableUpdateCompanionBuilder = DeviceInfoCompanion Function({
  Value<int> id,
  Value<String> deviceId,
  Value<String> branch,
  Value<String> area,
  Value<int> registeredAt,
});

class $$DeviceInfoTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DeviceInfoTable,
    DeviceInfoData,
    $$DeviceInfoTableFilterComposer,
    $$DeviceInfoTableOrderingComposer,
    $$DeviceInfoTableCreateCompanionBuilder,
    $$DeviceInfoTableUpdateCompanionBuilder> {
  $$DeviceInfoTableTableManager(_$AppDatabase db, $DeviceInfoTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DeviceInfoTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DeviceInfoTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<String> branch = const Value.absent(),
            Value<String> area = const Value.absent(),
            Value<int> registeredAt = const Value.absent(),
          }) =>
              DeviceInfoCompanion(
            id: id,
            deviceId: deviceId,
            branch: branch,
            area: area,
            registeredAt: registeredAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String deviceId,
            Value<String> branch = const Value.absent(),
            Value<String> area = const Value.absent(),
            required int registeredAt,
          }) =>
              DeviceInfoCompanion.insert(
            id: id,
            deviceId: deviceId,
            branch: branch,
            area: area,
            registeredAt: registeredAt,
          ),
        ));
}

class $$DeviceInfoTableFilterComposer
    extends FilterComposer<_$AppDatabase, $DeviceInfoTable> {
  $$DeviceInfoTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get deviceId => $state.composableBuilder(
      column: $state.table.deviceId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get branch => $state.composableBuilder(
      column: $state.table.branch,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get area => $state.composableBuilder(
      column: $state.table.area,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get registeredAt => $state.composableBuilder(
      column: $state.table.registeredAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DeviceInfoTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $DeviceInfoTable> {
  $$DeviceInfoTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get deviceId => $state.composableBuilder(
      column: $state.table.deviceId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get branch => $state.composableBuilder(
      column: $state.table.branch,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get area => $state.composableBuilder(
      column: $state.table.area,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get registeredAt => $state.composableBuilder(
      column: $state.table.registeredAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$DeviceIdentityTableCreateCompanionBuilder = DeviceIdentityCompanion
    Function({
  Value<int> id,
  required String deviceLabel,
  required String serverDeviceId,
  required String androidIdHash,
  required String branch,
  required String area,
  Value<bool> isActive,
  Value<DateTime?> claimedAt,
});
typedef $$DeviceIdentityTableUpdateCompanionBuilder = DeviceIdentityCompanion
    Function({
  Value<int> id,
  Value<String> deviceLabel,
  Value<String> serverDeviceId,
  Value<String> androidIdHash,
  Value<String> branch,
  Value<String> area,
  Value<bool> isActive,
  Value<DateTime?> claimedAt,
});

class $$DeviceIdentityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DeviceIdentityTable,
    DeviceIdentityData,
    $$DeviceIdentityTableFilterComposer,
    $$DeviceIdentityTableOrderingComposer,
    $$DeviceIdentityTableCreateCompanionBuilder,
    $$DeviceIdentityTableUpdateCompanionBuilder> {
  $$DeviceIdentityTableTableManager(
      _$AppDatabase db, $DeviceIdentityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DeviceIdentityTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DeviceIdentityTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> deviceLabel = const Value.absent(),
            Value<String> serverDeviceId = const Value.absent(),
            Value<String> androidIdHash = const Value.absent(),
            Value<String> branch = const Value.absent(),
            Value<String> area = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> claimedAt = const Value.absent(),
          }) =>
              DeviceIdentityCompanion(
            id: id,
            deviceLabel: deviceLabel,
            serverDeviceId: serverDeviceId,
            androidIdHash: androidIdHash,
            branch: branch,
            area: area,
            isActive: isActive,
            claimedAt: claimedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String deviceLabel,
            required String serverDeviceId,
            required String androidIdHash,
            required String branch,
            required String area,
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> claimedAt = const Value.absent(),
          }) =>
              DeviceIdentityCompanion.insert(
            id: id,
            deviceLabel: deviceLabel,
            serverDeviceId: serverDeviceId,
            androidIdHash: androidIdHash,
            branch: branch,
            area: area,
            isActive: isActive,
            claimedAt: claimedAt,
          ),
        ));
}

class $$DeviceIdentityTableFilterComposer
    extends FilterComposer<_$AppDatabase, $DeviceIdentityTable> {
  $$DeviceIdentityTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get deviceLabel => $state.composableBuilder(
      column: $state.table.deviceLabel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get serverDeviceId => $state.composableBuilder(
      column: $state.table.serverDeviceId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get androidIdHash => $state.composableBuilder(
      column: $state.table.androidIdHash,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get branch => $state.composableBuilder(
      column: $state.table.branch,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get area => $state.composableBuilder(
      column: $state.table.area,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get claimedAt => $state.composableBuilder(
      column: $state.table.claimedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DeviceIdentityTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $DeviceIdentityTable> {
  $$DeviceIdentityTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get deviceLabel => $state.composableBuilder(
      column: $state.table.deviceLabel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get serverDeviceId => $state.composableBuilder(
      column: $state.table.serverDeviceId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get androidIdHash => $state.composableBuilder(
      column: $state.table.androidIdHash,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get branch => $state.composableBuilder(
      column: $state.table.branch,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get area => $state.composableBuilder(
      column: $state.table.area,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get claimedAt => $state.composableBuilder(
      column: $state.table.claimedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$OfflineAccountsTableCreateCompanionBuilder = OfflineAccountsCompanion
    Function({
  Value<int> id,
  required String serverUserId,
  required String email,
  required String passwordHash,
  required String fullName,
  required String role,
  required int lastOnlineLogin,
  required int createdAt,
  required int updatedAt,
});
typedef $$OfflineAccountsTableUpdateCompanionBuilder = OfflineAccountsCompanion
    Function({
  Value<int> id,
  Value<String> serverUserId,
  Value<String> email,
  Value<String> passwordHash,
  Value<String> fullName,
  Value<String> role,
  Value<int> lastOnlineLogin,
  Value<int> createdAt,
  Value<int> updatedAt,
});

class $$OfflineAccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OfflineAccountsTable,
    OfflineAccount,
    $$OfflineAccountsTableFilterComposer,
    $$OfflineAccountsTableOrderingComposer,
    $$OfflineAccountsTableCreateCompanionBuilder,
    $$OfflineAccountsTableUpdateCompanionBuilder> {
  $$OfflineAccountsTableTableManager(
      _$AppDatabase db, $OfflineAccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$OfflineAccountsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$OfflineAccountsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> serverUserId = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> passwordHash = const Value.absent(),
            Value<String> fullName = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<int> lastOnlineLogin = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              OfflineAccountsCompanion(
            id: id,
            serverUserId: serverUserId,
            email: email,
            passwordHash: passwordHash,
            fullName: fullName,
            role: role,
            lastOnlineLogin: lastOnlineLogin,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String serverUserId,
            required String email,
            required String passwordHash,
            required String fullName,
            required String role,
            required int lastOnlineLogin,
            required int createdAt,
            required int updatedAt,
          }) =>
              OfflineAccountsCompanion.insert(
            id: id,
            serverUserId: serverUserId,
            email: email,
            passwordHash: passwordHash,
            fullName: fullName,
            role: role,
            lastOnlineLogin: lastOnlineLogin,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$OfflineAccountsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $OfflineAccountsTable> {
  $$OfflineAccountsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get serverUserId => $state.composableBuilder(
      column: $state.table.serverUserId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get passwordHash => $state.composableBuilder(
      column: $state.table.passwordHash,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get fullName => $state.composableBuilder(
      column: $state.table.fullName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get role => $state.composableBuilder(
      column: $state.table.role,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get lastOnlineLogin => $state.composableBuilder(
      column: $state.table.lastOnlineLogin,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter sessionsRefs(
      ComposableFilter Function($$SessionsTableFilterComposer f) f) {
    final $$SessionsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.sessions,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder, parentComposers) =>
            $$SessionsTableFilterComposer(ComposerState(
                $state.db, $state.db.sessions, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$OfflineAccountsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $OfflineAccountsTable> {
  $$OfflineAccountsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get serverUserId => $state.composableBuilder(
      column: $state.table.serverUserId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get passwordHash => $state.composableBuilder(
      column: $state.table.passwordHash,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get fullName => $state.composableBuilder(
      column: $state.table.fullName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get role => $state.composableBuilder(
      column: $state.table.role,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get lastOnlineLogin => $state.composableBuilder(
      column: $state.table.lastOnlineLogin,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required int userId,
  Value<String?> authToken,
  Value<bool> isActive,
  required int loginAt,
  Value<int?> lastVerifiedAt,
  Value<int?> logoutAt,
  Value<bool> isOfflineSession,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<int> userId,
  Value<String?> authToken,
  Value<bool> isActive,
  Value<int> loginAt,
  Value<int?> lastVerifiedAt,
  Value<int?> logoutAt,
  Value<bool> isOfflineSession,
});

class $$SessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder> {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SessionsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SessionsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String?> authToken = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> loginAt = const Value.absent(),
            Value<int?> lastVerifiedAt = const Value.absent(),
            Value<int?> logoutAt = const Value.absent(),
            Value<bool> isOfflineSession = const Value.absent(),
          }) =>
              SessionsCompanion(
            id: id,
            userId: userId,
            authToken: authToken,
            isActive: isActive,
            loginAt: loginAt,
            lastVerifiedAt: lastVerifiedAt,
            logoutAt: logoutAt,
            isOfflineSession: isOfflineSession,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int userId,
            Value<String?> authToken = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required int loginAt,
            Value<int?> lastVerifiedAt = const Value.absent(),
            Value<int?> logoutAt = const Value.absent(),
            Value<bool> isOfflineSession = const Value.absent(),
          }) =>
              SessionsCompanion.insert(
            id: id,
            userId: userId,
            authToken: authToken,
            isActive: isActive,
            loginAt: loginAt,
            lastVerifiedAt: lastVerifiedAt,
            logoutAt: logoutAt,
            isOfflineSession: isOfflineSession,
          ),
        ));
}

class $$SessionsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get authToken => $state.composableBuilder(
      column: $state.table.authToken,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get loginAt => $state.composableBuilder(
      column: $state.table.loginAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get lastVerifiedAt => $state.composableBuilder(
      column: $state.table.lastVerifiedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get logoutAt => $state.composableBuilder(
      column: $state.table.logoutAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isOfflineSession => $state.composableBuilder(
      column: $state.table.isOfflineSession,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$OfflineAccountsTableFilterComposer get userId {
    final $$OfflineAccountsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.userId,
            referencedTable: $state.db.offlineAccounts,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$OfflineAccountsTableFilterComposer(ComposerState($state.db,
                    $state.db.offlineAccounts, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$SessionsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get authToken => $state.composableBuilder(
      column: $state.table.authToken,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get loginAt => $state.composableBuilder(
      column: $state.table.loginAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get lastVerifiedAt => $state.composableBuilder(
      column: $state.table.lastVerifiedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get logoutAt => $state.composableBuilder(
      column: $state.table.logoutAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isOfflineSession => $state.composableBuilder(
      column: $state.table.isOfflineSession,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$OfflineAccountsTableOrderingComposer get userId {
    final $$OfflineAccountsTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.userId,
            referencedTable: $state.db.offlineAccounts,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$OfflineAccountsTableOrderingComposer(ComposerState($state.db,
                    $state.db.offlineAccounts, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$ShiftsTableCreateCompanionBuilder = ShiftsCompanion Function({
  required String id,
  required String userId,
  required String branchId,
  required String openedAt,
  Value<String?> closedAt,
  required double openingFloat,
  Value<double?> closingCash,
  required String status,
  required String syncStatus,
  required String createdAt,
  Value<int> rowid,
});
typedef $$ShiftsTableUpdateCompanionBuilder = ShiftsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> branchId,
  Value<String> openedAt,
  Value<String?> closedAt,
  Value<double> openingFloat,
  Value<double?> closingCash,
  Value<String> status,
  Value<String> syncStatus,
  Value<String> createdAt,
  Value<int> rowid,
});

class $$ShiftsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShiftsTable,
    Shift,
    $$ShiftsTableFilterComposer,
    $$ShiftsTableOrderingComposer,
    $$ShiftsTableCreateCompanionBuilder,
    $$ShiftsTableUpdateCompanionBuilder> {
  $$ShiftsTableTableManager(_$AppDatabase db, $ShiftsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ShiftsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ShiftsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> openedAt = const Value.absent(),
            Value<String?> closedAt = const Value.absent(),
            Value<double> openingFloat = const Value.absent(),
            Value<double?> closingCash = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShiftsCompanion(
            id: id,
            userId: userId,
            branchId: branchId,
            openedAt: openedAt,
            closedAt: closedAt,
            openingFloat: openingFloat,
            closingCash: closingCash,
            status: status,
            syncStatus: syncStatus,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String branchId,
            required String openedAt,
            Value<String?> closedAt = const Value.absent(),
            required double openingFloat,
            Value<double?> closingCash = const Value.absent(),
            required String status,
            required String syncStatus,
            required String createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ShiftsCompanion.insert(
            id: id,
            userId: userId,
            branchId: branchId,
            openedAt: openedAt,
            closedAt: closedAt,
            openingFloat: openingFloat,
            closingCash: closingCash,
            status: status,
            syncStatus: syncStatus,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$ShiftsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get branchId => $state.composableBuilder(
      column: $state.table.branchId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get openedAt => $state.composableBuilder(
      column: $state.table.openedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get closedAt => $state.composableBuilder(
      column: $state.table.closedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get openingFloat => $state.composableBuilder(
      column: $state.table.openingFloat,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get closingCash => $state.composableBuilder(
      column: $state.table.closingCash,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get syncStatus => $state.composableBuilder(
      column: $state.table.syncStatus,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter ticketsRefs(
      ComposableFilter Function($$TicketsTableFilterComposer f) f) {
    final $$TicketsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.tickets,
        getReferencedColumn: (t) => t.shiftId,
        builder: (joinBuilder, parentComposers) => $$TicketsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.tickets, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$ShiftsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get branchId => $state.composableBuilder(
      column: $state.table.branchId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get openedAt => $state.composableBuilder(
      column: $state.table.openedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get closedAt => $state.composableBuilder(
      column: $state.table.closedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get openingFloat => $state.composableBuilder(
      column: $state.table.openingFloat,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get closingCash => $state.composableBuilder(
      column: $state.table.closingCash,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get syncStatus => $state.composableBuilder(
      column: $state.table.syncStatus,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$TicketsTableCreateCompanionBuilder = TicketsCompanion Function({
  required String id,
  required String shiftId,
  required String userId,
  required String branchId,
  required String plateNumber,
  required String vehicleBrand,
  required String vehicleColor,
  required String vehicleType,
  required String cellphoneNumber,
  required String damageMarkers,
  required String personalBelongings,
  Value<String?> signaturePng,
  required String checkInAt,
  Value<String?> checkOutAt,
  Value<double?> fee,
  required String status,
  required String syncStatus,
  required String createdAt,
  Value<String?> serverTicketId,
  Value<int> rowid,
});
typedef $$TicketsTableUpdateCompanionBuilder = TicketsCompanion Function({
  Value<String> id,
  Value<String> shiftId,
  Value<String> userId,
  Value<String> branchId,
  Value<String> plateNumber,
  Value<String> vehicleBrand,
  Value<String> vehicleColor,
  Value<String> vehicleType,
  Value<String> cellphoneNumber,
  Value<String> damageMarkers,
  Value<String> personalBelongings,
  Value<String?> signaturePng,
  Value<String> checkInAt,
  Value<String?> checkOutAt,
  Value<double?> fee,
  Value<String> status,
  Value<String> syncStatus,
  Value<String> createdAt,
  Value<String?> serverTicketId,
  Value<int> rowid,
});

class $$TicketsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TicketsTable,
    Ticket,
    $$TicketsTableFilterComposer,
    $$TicketsTableOrderingComposer,
    $$TicketsTableCreateCompanionBuilder,
    $$TicketsTableUpdateCompanionBuilder> {
  $$TicketsTableTableManager(_$AppDatabase db, $TicketsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TicketsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TicketsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> shiftId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> plateNumber = const Value.absent(),
            Value<String> vehicleBrand = const Value.absent(),
            Value<String> vehicleColor = const Value.absent(),
            Value<String> vehicleType = const Value.absent(),
            Value<String> cellphoneNumber = const Value.absent(),
            Value<String> damageMarkers = const Value.absent(),
            Value<String> personalBelongings = const Value.absent(),
            Value<String?> signaturePng = const Value.absent(),
            Value<String> checkInAt = const Value.absent(),
            Value<String?> checkOutAt = const Value.absent(),
            Value<double?> fee = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String?> serverTicketId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TicketsCompanion(
            id: id,
            shiftId: shiftId,
            userId: userId,
            branchId: branchId,
            plateNumber: plateNumber,
            vehicleBrand: vehicleBrand,
            vehicleColor: vehicleColor,
            vehicleType: vehicleType,
            cellphoneNumber: cellphoneNumber,
            damageMarkers: damageMarkers,
            personalBelongings: personalBelongings,
            signaturePng: signaturePng,
            checkInAt: checkInAt,
            checkOutAt: checkOutAt,
            fee: fee,
            status: status,
            syncStatus: syncStatus,
            createdAt: createdAt,
            serverTicketId: serverTicketId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String shiftId,
            required String userId,
            required String branchId,
            required String plateNumber,
            required String vehicleBrand,
            required String vehicleColor,
            required String vehicleType,
            required String cellphoneNumber,
            required String damageMarkers,
            required String personalBelongings,
            Value<String?> signaturePng = const Value.absent(),
            required String checkInAt,
            Value<String?> checkOutAt = const Value.absent(),
            Value<double?> fee = const Value.absent(),
            required String status,
            required String syncStatus,
            required String createdAt,
            Value<String?> serverTicketId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TicketsCompanion.insert(
            id: id,
            shiftId: shiftId,
            userId: userId,
            branchId: branchId,
            plateNumber: plateNumber,
            vehicleBrand: vehicleBrand,
            vehicleColor: vehicleColor,
            vehicleType: vehicleType,
            cellphoneNumber: cellphoneNumber,
            damageMarkers: damageMarkers,
            personalBelongings: personalBelongings,
            signaturePng: signaturePng,
            checkInAt: checkInAt,
            checkOutAt: checkOutAt,
            fee: fee,
            status: status,
            syncStatus: syncStatus,
            createdAt: createdAt,
            serverTicketId: serverTicketId,
            rowid: rowid,
          ),
        ));
}

class $$TicketsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $TicketsTable> {
  $$TicketsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get branchId => $state.composableBuilder(
      column: $state.table.branchId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get plateNumber => $state.composableBuilder(
      column: $state.table.plateNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get vehicleBrand => $state.composableBuilder(
      column: $state.table.vehicleBrand,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get vehicleColor => $state.composableBuilder(
      column: $state.table.vehicleColor,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get vehicleType => $state.composableBuilder(
      column: $state.table.vehicleType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get cellphoneNumber => $state.composableBuilder(
      column: $state.table.cellphoneNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get damageMarkers => $state.composableBuilder(
      column: $state.table.damageMarkers,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get personalBelongings => $state.composableBuilder(
      column: $state.table.personalBelongings,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get signaturePng => $state.composableBuilder(
      column: $state.table.signaturePng,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get checkInAt => $state.composableBuilder(
      column: $state.table.checkInAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get checkOutAt => $state.composableBuilder(
      column: $state.table.checkOutAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get fee => $state.composableBuilder(
      column: $state.table.fee,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get syncStatus => $state.composableBuilder(
      column: $state.table.syncStatus,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get serverTicketId => $state.composableBuilder(
      column: $state.table.serverTicketId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shiftId,
        referencedTable: $state.db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$ShiftsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.shifts, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$TicketsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $TicketsTable> {
  $$TicketsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get branchId => $state.composableBuilder(
      column: $state.table.branchId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get plateNumber => $state.composableBuilder(
      column: $state.table.plateNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get vehicleBrand => $state.composableBuilder(
      column: $state.table.vehicleBrand,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get vehicleColor => $state.composableBuilder(
      column: $state.table.vehicleColor,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get vehicleType => $state.composableBuilder(
      column: $state.table.vehicleType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get cellphoneNumber => $state.composableBuilder(
      column: $state.table.cellphoneNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get damageMarkers => $state.composableBuilder(
      column: $state.table.damageMarkers,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get personalBelongings => $state.composableBuilder(
      column: $state.table.personalBelongings,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get signaturePng => $state.composableBuilder(
      column: $state.table.signaturePng,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get checkInAt => $state.composableBuilder(
      column: $state.table.checkInAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get checkOutAt => $state.composableBuilder(
      column: $state.table.checkOutAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get fee => $state.composableBuilder(
      column: $state.table.fee,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get syncStatus => $state.composableBuilder(
      column: $state.table.syncStatus,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get serverTicketId => $state.composableBuilder(
      column: $state.table.serverTicketId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shiftId,
        referencedTable: $state.db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ShiftsTableOrderingComposer(ComposerState(
                $state.db, $state.db.shifts, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  required String id,
  required String operation,
  required String queueTableName,
  required String recordId,
  required String payload,
  required String syncStatus,
  Value<int> retryCount,
  required String createdAt,
  Value<int> rowid,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<String> id,
  Value<String> operation,
  Value<String> queueTableName,
  Value<String> recordId,
  Value<String> payload,
  Value<String> syncStatus,
  Value<int> retryCount,
  Value<String> createdAt,
  Value<int> rowid,
});

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SyncQueueTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SyncQueueTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> queueTableName = const Value.absent(),
            Value<String> recordId = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            operation: operation,
            queueTableName: queueTableName,
            recordId: recordId,
            payload: payload,
            syncStatus: syncStatus,
            retryCount: retryCount,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String operation,
            required String queueTableName,
            required String recordId,
            required String payload,
            required String syncStatus,
            Value<int> retryCount = const Value.absent(),
            required String createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            operation: operation,
            queueTableName: queueTableName,
            recordId: recordId,
            payload: payload,
            syncStatus: syncStatus,
            retryCount: retryCount,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$SyncQueueTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get operation => $state.composableBuilder(
      column: $state.table.operation,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get queueTableName => $state.composableBuilder(
      column: $state.table.queueTableName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get recordId => $state.composableBuilder(
      column: $state.table.recordId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get syncStatus => $state.composableBuilder(
      column: $state.table.syncStatus,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SyncQueueTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get operation => $state.composableBuilder(
      column: $state.table.operation,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get queueTableName => $state.composableBuilder(
      column: $state.table.queueTableName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get recordId => $state.composableBuilder(
      column: $state.table.recordId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get syncStatus => $state.composableBuilder(
      column: $state.table.syncStatus,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$RatesTableCreateCompanionBuilder = RatesCompanion Function({
  required String id,
  required String branchId,
  required String vehicleType,
  required int flatRateHours,
  required double flatRateFee,
  required double succeedingHourFee,
  required double overnightFee,
  required double lostTicketFee,
  required String syncStatus,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$RatesTableUpdateCompanionBuilder = RatesCompanion Function({
  Value<String> id,
  Value<String> branchId,
  Value<String> vehicleType,
  Value<int> flatRateHours,
  Value<double> flatRateFee,
  Value<double> succeedingHourFee,
  Value<double> overnightFee,
  Value<double> lostTicketFee,
  Value<String> syncStatus,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$RatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RatesTable,
    Rate,
    $$RatesTableFilterComposer,
    $$RatesTableOrderingComposer,
    $$RatesTableCreateCompanionBuilder,
    $$RatesTableUpdateCompanionBuilder> {
  $$RatesTableTableManager(_$AppDatabase db, $RatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$RatesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$RatesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> vehicleType = const Value.absent(),
            Value<int> flatRateHours = const Value.absent(),
            Value<double> flatRateFee = const Value.absent(),
            Value<double> succeedingHourFee = const Value.absent(),
            Value<double> overnightFee = const Value.absent(),
            Value<double> lostTicketFee = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RatesCompanion(
            id: id,
            branchId: branchId,
            vehicleType: vehicleType,
            flatRateHours: flatRateHours,
            flatRateFee: flatRateFee,
            succeedingHourFee: succeedingHourFee,
            overnightFee: overnightFee,
            lostTicketFee: lostTicketFee,
            syncStatus: syncStatus,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String branchId,
            required String vehicleType,
            required int flatRateHours,
            required double flatRateFee,
            required double succeedingHourFee,
            required double overnightFee,
            required double lostTicketFee,
            required String syncStatus,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              RatesCompanion.insert(
            id: id,
            branchId: branchId,
            vehicleType: vehicleType,
            flatRateHours: flatRateHours,
            flatRateFee: flatRateFee,
            succeedingHourFee: succeedingHourFee,
            overnightFee: overnightFee,
            lostTicketFee: lostTicketFee,
            syncStatus: syncStatus,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$RatesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $RatesTable> {
  $$RatesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get branchId => $state.composableBuilder(
      column: $state.table.branchId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get vehicleType => $state.composableBuilder(
      column: $state.table.vehicleType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get flatRateHours => $state.composableBuilder(
      column: $state.table.flatRateHours,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get flatRateFee => $state.composableBuilder(
      column: $state.table.flatRateFee,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get succeedingHourFee => $state.composableBuilder(
      column: $state.table.succeedingHourFee,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get overnightFee => $state.composableBuilder(
      column: $state.table.overnightFee,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get lostTicketFee => $state.composableBuilder(
      column: $state.table.lostTicketFee,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get syncStatus => $state.composableBuilder(
      column: $state.table.syncStatus,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$RatesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $RatesTable> {
  $$RatesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get branchId => $state.composableBuilder(
      column: $state.table.branchId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get vehicleType => $state.composableBuilder(
      column: $state.table.vehicleType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get flatRateHours => $state.composableBuilder(
      column: $state.table.flatRateHours,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get flatRateFee => $state.composableBuilder(
      column: $state.table.flatRateFee,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get succeedingHourFee => $state.composableBuilder(
      column: $state.table.succeedingHourFee,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get overnightFee => $state.composableBuilder(
      column: $state.table.overnightFee,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get lostTicketFee => $state.composableBuilder(
      column: $state.table.lostTicketFee,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get syncStatus => $state.composableBuilder(
      column: $state.table.syncStatus,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$BranchConfigsTableCreateCompanionBuilder = BranchConfigsCompanion
    Function({
  required String id,
  required String branchId,
  required String configKey,
  required String configValue,
  required String syncStatus,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$BranchConfigsTableUpdateCompanionBuilder = BranchConfigsCompanion
    Function({
  Value<String> id,
  Value<String> branchId,
  Value<String> configKey,
  Value<String> configValue,
  Value<String> syncStatus,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$BranchConfigsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BranchConfigsTable,
    BranchConfig,
    $$BranchConfigsTableFilterComposer,
    $$BranchConfigsTableOrderingComposer,
    $$BranchConfigsTableCreateCompanionBuilder,
    $$BranchConfigsTableUpdateCompanionBuilder> {
  $$BranchConfigsTableTableManager(_$AppDatabase db, $BranchConfigsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BranchConfigsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BranchConfigsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> configKey = const Value.absent(),
            Value<String> configValue = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BranchConfigsCompanion(
            id: id,
            branchId: branchId,
            configKey: configKey,
            configValue: configValue,
            syncStatus: syncStatus,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String branchId,
            required String configKey,
            required String configValue,
            required String syncStatus,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BranchConfigsCompanion.insert(
            id: id,
            branchId: branchId,
            configKey: configKey,
            configValue: configValue,
            syncStatus: syncStatus,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$BranchConfigsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BranchConfigsTable> {
  $$BranchConfigsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get branchId => $state.composableBuilder(
      column: $state.table.branchId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get configKey => $state.composableBuilder(
      column: $state.table.configKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get configValue => $state.composableBuilder(
      column: $state.table.configValue,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get syncStatus => $state.composableBuilder(
      column: $state.table.syncStatus,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$BranchConfigsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BranchConfigsTable> {
  $$BranchConfigsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get branchId => $state.composableBuilder(
      column: $state.table.branchId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get configKey => $state.composableBuilder(
      column: $state.table.configKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get configValue => $state.composableBuilder(
      column: $state.table.configValue,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get syncStatus => $state.composableBuilder(
      column: $state.table.syncStatus,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DeviceInfoTableTableManager get deviceInfo =>
      $$DeviceInfoTableTableManager(_db, _db.deviceInfo);
  $$DeviceIdentityTableTableManager get deviceIdentity =>
      $$DeviceIdentityTableTableManager(_db, _db.deviceIdentity);
  $$OfflineAccountsTableTableManager get offlineAccounts =>
      $$OfflineAccountsTableTableManager(_db, _db.offlineAccounts);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$ShiftsTableTableManager get shifts =>
      $$ShiftsTableTableManager(_db, _db.shifts);
  $$TicketsTableTableManager get tickets =>
      $$TicketsTableTableManager(_db, _db.tickets);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$RatesTableTableManager get rates =>
      $$RatesTableTableManager(_db, _db.rates);
  $$BranchConfigsTableTableManager get branchConfigs =>
      $$BranchConfigsTableTableManager(_db, _db.branchConfigs);
}

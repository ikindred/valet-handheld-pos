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
  late final GeneratedColumn<int> serverUserId = GeneratedColumn<int>(
      'server_user_id', aliasedName, false,
      type: DriftSqlType.int,
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
          .read(DriftSqlType.int, data['${effectivePrefix}server_user_id'])!,
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

  /// Canonical user id from API.
  final int serverUserId;
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
    map['server_user_id'] = Variable<int>(serverUserId);
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
      serverUserId: serializer.fromJson<int>(json['serverUserId']),
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
      'serverUserId': serializer.toJson<int>(serverUserId),
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
          int? serverUserId,
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
  final Value<int> serverUserId;
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
    required int serverUserId,
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
    Expression<int>? serverUserId,
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
      Value<int>? serverUserId,
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
      map['server_user_id'] = Variable<int>(serverUserId.value);
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
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
      'session_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES sessions (id)'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES offline_accounts (id)'));
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
  static const VerificationMeta _shiftDateMeta =
      const VerificationMeta('shiftDate');
  @override
  late final GeneratedColumn<String> shiftDate = GeneratedColumn<String>(
      'shift_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isOpenMeta = const VerificationMeta('isOpen');
  @override
  late final GeneratedColumn<bool> isOpen = GeneratedColumn<bool>(
      'is_open', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_open" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _openingFloatMeta =
      const VerificationMeta('openingFloat');
  @override
  late final GeneratedColumn<double> openingFloat = GeneratedColumn<double>(
      'opening_float', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _openingNotesMeta =
      const VerificationMeta('openingNotes');
  @override
  late final GeneratedColumn<String> openingNotes = GeneratedColumn<String>(
      'opening_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _closingFloatMeta =
      const VerificationMeta('closingFloat');
  @override
  late final GeneratedColumn<double> closingFloat = GeneratedColumn<double>(
      'closing_float', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _closingNotesMeta =
      const VerificationMeta('closingNotes');
  @override
  late final GeneratedColumn<String> closingNotes = GeneratedColumn<String>(
      'closing_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalSalesMeta =
      const VerificationMeta('totalSales');
  @override
  late final GeneratedColumn<double> totalSales = GeneratedColumn<double>(
      'total_sales', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _expectedCashMeta =
      const VerificationMeta('expectedCash');
  @override
  late final GeneratedColumn<double> expectedCash = GeneratedColumn<double>(
      'expected_cash', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _varianceMeta =
      const VerificationMeta('variance');
  @override
  late final GeneratedColumn<double> variance = GeneratedColumn<double>(
      'variance', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _remittanceMeta =
      const VerificationMeta('remittance');
  @override
  late final GeneratedColumn<double> remittance = GeneratedColumn<double>(
      'remittance', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _transactionsCountMeta =
      const VerificationMeta('transactionsCount');
  @override
  late final GeneratedColumn<int> transactionsCount = GeneratedColumn<int>(
      'transactions_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _openedAtMeta =
      const VerificationMeta('openedAt');
  @override
  late final GeneratedColumn<int> openedAt = GeneratedColumn<int>(
      'opened_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _closedAtMeta =
      const VerificationMeta('closedAt');
  @override
  late final GeneratedColumn<int> closedAt = GeneratedColumn<int>(
      'closed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sessionId,
        userId,
        branch,
        area,
        shiftDate,
        isOpen,
        openingFloat,
        openingNotes,
        closingFloat,
        closingNotes,
        totalSales,
        expectedCash,
        variance,
        remittance,
        transactionsCount,
        openedAt,
        closedAt,
        syncedAt
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
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
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
    if (data.containsKey('shift_date')) {
      context.handle(_shiftDateMeta,
          shiftDate.isAcceptableOrUnknown(data['shift_date']!, _shiftDateMeta));
    } else if (isInserting) {
      context.missing(_shiftDateMeta);
    }
    if (data.containsKey('is_open')) {
      context.handle(_isOpenMeta,
          isOpen.isAcceptableOrUnknown(data['is_open']!, _isOpenMeta));
    }
    if (data.containsKey('opening_float')) {
      context.handle(
          _openingFloatMeta,
          openingFloat.isAcceptableOrUnknown(
              data['opening_float']!, _openingFloatMeta));
    }
    if (data.containsKey('opening_notes')) {
      context.handle(
          _openingNotesMeta,
          openingNotes.isAcceptableOrUnknown(
              data['opening_notes']!, _openingNotesMeta));
    }
    if (data.containsKey('closing_float')) {
      context.handle(
          _closingFloatMeta,
          closingFloat.isAcceptableOrUnknown(
              data['closing_float']!, _closingFloatMeta));
    }
    if (data.containsKey('closing_notes')) {
      context.handle(
          _closingNotesMeta,
          closingNotes.isAcceptableOrUnknown(
              data['closing_notes']!, _closingNotesMeta));
    }
    if (data.containsKey('total_sales')) {
      context.handle(
          _totalSalesMeta,
          totalSales.isAcceptableOrUnknown(
              data['total_sales']!, _totalSalesMeta));
    }
    if (data.containsKey('expected_cash')) {
      context.handle(
          _expectedCashMeta,
          expectedCash.isAcceptableOrUnknown(
              data['expected_cash']!, _expectedCashMeta));
    }
    if (data.containsKey('variance')) {
      context.handle(_varianceMeta,
          variance.isAcceptableOrUnknown(data['variance']!, _varianceMeta));
    }
    if (data.containsKey('remittance')) {
      context.handle(
          _remittanceMeta,
          remittance.isAcceptableOrUnknown(
              data['remittance']!, _remittanceMeta));
    }
    if (data.containsKey('transactions_count')) {
      context.handle(
          _transactionsCountMeta,
          transactionsCount.isAcceptableOrUnknown(
              data['transactions_count']!, _transactionsCountMeta));
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
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
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
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}session_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      branch: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch'])!,
      area: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}area'])!,
      shiftDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shift_date'])!,
      isOpen: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_open'])!,
      openingFloat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}opening_float'])!,
      openingNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}opening_notes']),
      closingFloat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}closing_float']),
      closingNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}closing_notes']),
      totalSales: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_sales'])!,
      expectedCash: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}expected_cash']),
      variance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}variance']),
      remittance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}remittance']),
      transactionsCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}transactions_count'])!,
      openedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}opened_at'])!,
      closedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}closed_at']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $ShiftsTable createAlias(String alias) {
    return $ShiftsTable(attachedDatabase, alias);
  }
}

class Shift extends DataClass implements Insertable<Shift> {
  final int id;
  final int sessionId;
  final int userId;
  final String branch;
  final String area;

  /// YYYY-MM-DD
  final String shiftDate;
  final bool isOpen;
  final double openingFloat;
  final String? openingNotes;
  final double? closingFloat;
  final String? closingNotes;
  final double totalSales;
  final double? expectedCash;
  final double? variance;
  final double? remittance;
  final int transactionsCount;
  final int openedAt;
  final int? closedAt;
  final int? syncedAt;
  const Shift(
      {required this.id,
      required this.sessionId,
      required this.userId,
      required this.branch,
      required this.area,
      required this.shiftDate,
      required this.isOpen,
      required this.openingFloat,
      this.openingNotes,
      this.closingFloat,
      this.closingNotes,
      required this.totalSales,
      this.expectedCash,
      this.variance,
      this.remittance,
      required this.transactionsCount,
      required this.openedAt,
      this.closedAt,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['user_id'] = Variable<int>(userId);
    map['branch'] = Variable<String>(branch);
    map['area'] = Variable<String>(area);
    map['shift_date'] = Variable<String>(shiftDate);
    map['is_open'] = Variable<bool>(isOpen);
    map['opening_float'] = Variable<double>(openingFloat);
    if (!nullToAbsent || openingNotes != null) {
      map['opening_notes'] = Variable<String>(openingNotes);
    }
    if (!nullToAbsent || closingFloat != null) {
      map['closing_float'] = Variable<double>(closingFloat);
    }
    if (!nullToAbsent || closingNotes != null) {
      map['closing_notes'] = Variable<String>(closingNotes);
    }
    map['total_sales'] = Variable<double>(totalSales);
    if (!nullToAbsent || expectedCash != null) {
      map['expected_cash'] = Variable<double>(expectedCash);
    }
    if (!nullToAbsent || variance != null) {
      map['variance'] = Variable<double>(variance);
    }
    if (!nullToAbsent || remittance != null) {
      map['remittance'] = Variable<double>(remittance);
    }
    map['transactions_count'] = Variable<int>(transactionsCount);
    map['opened_at'] = Variable<int>(openedAt);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<int>(closedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<int>(syncedAt);
    }
    return map;
  }

  ShiftsCompanion toCompanion(bool nullToAbsent) {
    return ShiftsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      userId: Value(userId),
      branch: Value(branch),
      area: Value(area),
      shiftDate: Value(shiftDate),
      isOpen: Value(isOpen),
      openingFloat: Value(openingFloat),
      openingNotes: openingNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(openingNotes),
      closingFloat: closingFloat == null && nullToAbsent
          ? const Value.absent()
          : Value(closingFloat),
      closingNotes: closingNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(closingNotes),
      totalSales: Value(totalSales),
      expectedCash: expectedCash == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedCash),
      variance: variance == null && nullToAbsent
          ? const Value.absent()
          : Value(variance),
      remittance: remittance == null && nullToAbsent
          ? const Value.absent()
          : Value(remittance),
      transactionsCount: Value(transactionsCount),
      openedAt: Value(openedAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory Shift.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shift(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      userId: serializer.fromJson<int>(json['userId']),
      branch: serializer.fromJson<String>(json['branch']),
      area: serializer.fromJson<String>(json['area']),
      shiftDate: serializer.fromJson<String>(json['shiftDate']),
      isOpen: serializer.fromJson<bool>(json['isOpen']),
      openingFloat: serializer.fromJson<double>(json['openingFloat']),
      openingNotes: serializer.fromJson<String?>(json['openingNotes']),
      closingFloat: serializer.fromJson<double?>(json['closingFloat']),
      closingNotes: serializer.fromJson<String?>(json['closingNotes']),
      totalSales: serializer.fromJson<double>(json['totalSales']),
      expectedCash: serializer.fromJson<double?>(json['expectedCash']),
      variance: serializer.fromJson<double?>(json['variance']),
      remittance: serializer.fromJson<double?>(json['remittance']),
      transactionsCount: serializer.fromJson<int>(json['transactionsCount']),
      openedAt: serializer.fromJson<int>(json['openedAt']),
      closedAt: serializer.fromJson<int?>(json['closedAt']),
      syncedAt: serializer.fromJson<int?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'userId': serializer.toJson<int>(userId),
      'branch': serializer.toJson<String>(branch),
      'area': serializer.toJson<String>(area),
      'shiftDate': serializer.toJson<String>(shiftDate),
      'isOpen': serializer.toJson<bool>(isOpen),
      'openingFloat': serializer.toJson<double>(openingFloat),
      'openingNotes': serializer.toJson<String?>(openingNotes),
      'closingFloat': serializer.toJson<double?>(closingFloat),
      'closingNotes': serializer.toJson<String?>(closingNotes),
      'totalSales': serializer.toJson<double>(totalSales),
      'expectedCash': serializer.toJson<double?>(expectedCash),
      'variance': serializer.toJson<double?>(variance),
      'remittance': serializer.toJson<double?>(remittance),
      'transactionsCount': serializer.toJson<int>(transactionsCount),
      'openedAt': serializer.toJson<int>(openedAt),
      'closedAt': serializer.toJson<int?>(closedAt),
      'syncedAt': serializer.toJson<int?>(syncedAt),
    };
  }

  Shift copyWith(
          {int? id,
          int? sessionId,
          int? userId,
          String? branch,
          String? area,
          String? shiftDate,
          bool? isOpen,
          double? openingFloat,
          Value<String?> openingNotes = const Value.absent(),
          Value<double?> closingFloat = const Value.absent(),
          Value<String?> closingNotes = const Value.absent(),
          double? totalSales,
          Value<double?> expectedCash = const Value.absent(),
          Value<double?> variance = const Value.absent(),
          Value<double?> remittance = const Value.absent(),
          int? transactionsCount,
          int? openedAt,
          Value<int?> closedAt = const Value.absent(),
          Value<int?> syncedAt = const Value.absent()}) =>
      Shift(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        userId: userId ?? this.userId,
        branch: branch ?? this.branch,
        area: area ?? this.area,
        shiftDate: shiftDate ?? this.shiftDate,
        isOpen: isOpen ?? this.isOpen,
        openingFloat: openingFloat ?? this.openingFloat,
        openingNotes:
            openingNotes.present ? openingNotes.value : this.openingNotes,
        closingFloat:
            closingFloat.present ? closingFloat.value : this.closingFloat,
        closingNotes:
            closingNotes.present ? closingNotes.value : this.closingNotes,
        totalSales: totalSales ?? this.totalSales,
        expectedCash:
            expectedCash.present ? expectedCash.value : this.expectedCash,
        variance: variance.present ? variance.value : this.variance,
        remittance: remittance.present ? remittance.value : this.remittance,
        transactionsCount: transactionsCount ?? this.transactionsCount,
        openedAt: openedAt ?? this.openedAt,
        closedAt: closedAt.present ? closedAt.value : this.closedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  Shift copyWithCompanion(ShiftsCompanion data) {
    return Shift(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      userId: data.userId.present ? data.userId.value : this.userId,
      branch: data.branch.present ? data.branch.value : this.branch,
      area: data.area.present ? data.area.value : this.area,
      shiftDate: data.shiftDate.present ? data.shiftDate.value : this.shiftDate,
      isOpen: data.isOpen.present ? data.isOpen.value : this.isOpen,
      openingFloat: data.openingFloat.present
          ? data.openingFloat.value
          : this.openingFloat,
      openingNotes: data.openingNotes.present
          ? data.openingNotes.value
          : this.openingNotes,
      closingFloat: data.closingFloat.present
          ? data.closingFloat.value
          : this.closingFloat,
      closingNotes: data.closingNotes.present
          ? data.closingNotes.value
          : this.closingNotes,
      totalSales:
          data.totalSales.present ? data.totalSales.value : this.totalSales,
      expectedCash: data.expectedCash.present
          ? data.expectedCash.value
          : this.expectedCash,
      variance: data.variance.present ? data.variance.value : this.variance,
      remittance:
          data.remittance.present ? data.remittance.value : this.remittance,
      transactionsCount: data.transactionsCount.present
          ? data.transactionsCount.value
          : this.transactionsCount,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shift(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('userId: $userId, ')
          ..write('branch: $branch, ')
          ..write('area: $area, ')
          ..write('shiftDate: $shiftDate, ')
          ..write('isOpen: $isOpen, ')
          ..write('openingFloat: $openingFloat, ')
          ..write('openingNotes: $openingNotes, ')
          ..write('closingFloat: $closingFloat, ')
          ..write('closingNotes: $closingNotes, ')
          ..write('totalSales: $totalSales, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('variance: $variance, ')
          ..write('remittance: $remittance, ')
          ..write('transactionsCount: $transactionsCount, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      sessionId,
      userId,
      branch,
      area,
      shiftDate,
      isOpen,
      openingFloat,
      openingNotes,
      closingFloat,
      closingNotes,
      totalSales,
      expectedCash,
      variance,
      remittance,
      transactionsCount,
      openedAt,
      closedAt,
      syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shift &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.userId == this.userId &&
          other.branch == this.branch &&
          other.area == this.area &&
          other.shiftDate == this.shiftDate &&
          other.isOpen == this.isOpen &&
          other.openingFloat == this.openingFloat &&
          other.openingNotes == this.openingNotes &&
          other.closingFloat == this.closingFloat &&
          other.closingNotes == this.closingNotes &&
          other.totalSales == this.totalSales &&
          other.expectedCash == this.expectedCash &&
          other.variance == this.variance &&
          other.remittance == this.remittance &&
          other.transactionsCount == this.transactionsCount &&
          other.openedAt == this.openedAt &&
          other.closedAt == this.closedAt &&
          other.syncedAt == this.syncedAt);
}

class ShiftsCompanion extends UpdateCompanion<Shift> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> userId;
  final Value<String> branch;
  final Value<String> area;
  final Value<String> shiftDate;
  final Value<bool> isOpen;
  final Value<double> openingFloat;
  final Value<String?> openingNotes;
  final Value<double?> closingFloat;
  final Value<String?> closingNotes;
  final Value<double> totalSales;
  final Value<double?> expectedCash;
  final Value<double?> variance;
  final Value<double?> remittance;
  final Value<int> transactionsCount;
  final Value<int> openedAt;
  final Value<int?> closedAt;
  final Value<int?> syncedAt;
  const ShiftsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.userId = const Value.absent(),
    this.branch = const Value.absent(),
    this.area = const Value.absent(),
    this.shiftDate = const Value.absent(),
    this.isOpen = const Value.absent(),
    this.openingFloat = const Value.absent(),
    this.openingNotes = const Value.absent(),
    this.closingFloat = const Value.absent(),
    this.closingNotes = const Value.absent(),
    this.totalSales = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.variance = const Value.absent(),
    this.remittance = const Value.absent(),
    this.transactionsCount = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  ShiftsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int userId,
    required String branch,
    required String area,
    required String shiftDate,
    this.isOpen = const Value.absent(),
    this.openingFloat = const Value.absent(),
    this.openingNotes = const Value.absent(),
    this.closingFloat = const Value.absent(),
    this.closingNotes = const Value.absent(),
    this.totalSales = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.variance = const Value.absent(),
    this.remittance = const Value.absent(),
    this.transactionsCount = const Value.absent(),
    required int openedAt,
    this.closedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  })  : sessionId = Value(sessionId),
        userId = Value(userId),
        branch = Value(branch),
        area = Value(area),
        shiftDate = Value(shiftDate),
        openedAt = Value(openedAt);
  static Insertable<Shift> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? userId,
    Expression<String>? branch,
    Expression<String>? area,
    Expression<String>? shiftDate,
    Expression<bool>? isOpen,
    Expression<double>? openingFloat,
    Expression<String>? openingNotes,
    Expression<double>? closingFloat,
    Expression<String>? closingNotes,
    Expression<double>? totalSales,
    Expression<double>? expectedCash,
    Expression<double>? variance,
    Expression<double>? remittance,
    Expression<int>? transactionsCount,
    Expression<int>? openedAt,
    Expression<int>? closedAt,
    Expression<int>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (userId != null) 'user_id': userId,
      if (branch != null) 'branch': branch,
      if (area != null) 'area': area,
      if (shiftDate != null) 'shift_date': shiftDate,
      if (isOpen != null) 'is_open': isOpen,
      if (openingFloat != null) 'opening_float': openingFloat,
      if (openingNotes != null) 'opening_notes': openingNotes,
      if (closingFloat != null) 'closing_float': closingFloat,
      if (closingNotes != null) 'closing_notes': closingNotes,
      if (totalSales != null) 'total_sales': totalSales,
      if (expectedCash != null) 'expected_cash': expectedCash,
      if (variance != null) 'variance': variance,
      if (remittance != null) 'remittance': remittance,
      if (transactionsCount != null) 'transactions_count': transactionsCount,
      if (openedAt != null) 'opened_at': openedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  ShiftsCompanion copyWith(
      {Value<int>? id,
      Value<int>? sessionId,
      Value<int>? userId,
      Value<String>? branch,
      Value<String>? area,
      Value<String>? shiftDate,
      Value<bool>? isOpen,
      Value<double>? openingFloat,
      Value<String?>? openingNotes,
      Value<double?>? closingFloat,
      Value<String?>? closingNotes,
      Value<double>? totalSales,
      Value<double?>? expectedCash,
      Value<double?>? variance,
      Value<double?>? remittance,
      Value<int>? transactionsCount,
      Value<int>? openedAt,
      Value<int?>? closedAt,
      Value<int?>? syncedAt}) {
    return ShiftsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      branch: branch ?? this.branch,
      area: area ?? this.area,
      shiftDate: shiftDate ?? this.shiftDate,
      isOpen: isOpen ?? this.isOpen,
      openingFloat: openingFloat ?? this.openingFloat,
      openingNotes: openingNotes ?? this.openingNotes,
      closingFloat: closingFloat ?? this.closingFloat,
      closingNotes: closingNotes ?? this.closingNotes,
      totalSales: totalSales ?? this.totalSales,
      expectedCash: expectedCash ?? this.expectedCash,
      variance: variance ?? this.variance,
      remittance: remittance ?? this.remittance,
      transactionsCount: transactionsCount ?? this.transactionsCount,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (branch.present) {
      map['branch'] = Variable<String>(branch.value);
    }
    if (area.present) {
      map['area'] = Variable<String>(area.value);
    }
    if (shiftDate.present) {
      map['shift_date'] = Variable<String>(shiftDate.value);
    }
    if (isOpen.present) {
      map['is_open'] = Variable<bool>(isOpen.value);
    }
    if (openingFloat.present) {
      map['opening_float'] = Variable<double>(openingFloat.value);
    }
    if (openingNotes.present) {
      map['opening_notes'] = Variable<String>(openingNotes.value);
    }
    if (closingFloat.present) {
      map['closing_float'] = Variable<double>(closingFloat.value);
    }
    if (closingNotes.present) {
      map['closing_notes'] = Variable<String>(closingNotes.value);
    }
    if (totalSales.present) {
      map['total_sales'] = Variable<double>(totalSales.value);
    }
    if (expectedCash.present) {
      map['expected_cash'] = Variable<double>(expectedCash.value);
    }
    if (variance.present) {
      map['variance'] = Variable<double>(variance.value);
    }
    if (remittance.present) {
      map['remittance'] = Variable<double>(remittance.value);
    }
    if (transactionsCount.present) {
      map['transactions_count'] = Variable<int>(transactionsCount.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<int>(openedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<int>(closedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('userId: $userId, ')
          ..write('branch: $branch, ')
          ..write('area: $area, ')
          ..write('shiftDate: $shiftDate, ')
          ..write('isOpen: $isOpen, ')
          ..write('openingFloat: $openingFloat, ')
          ..write('openingNotes: $openingNotes, ')
          ..write('closingFloat: $closingFloat, ')
          ..write('closingNotes: $closingNotes, ')
          ..write('totalSales: $totalSales, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('variance: $variance, ')
          ..write('remittance: $remittance, ')
          ..write('transactionsCount: $transactionsCount, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $ShiftOpeningDenominationsTable extends ShiftOpeningDenominations
    with TableInfo<$ShiftOpeningDenominationsTable, ShiftOpeningDenomination> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftOpeningDenominationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _shiftIdMeta =
      const VerificationMeta('shiftId');
  @override
  late final GeneratedColumn<int> shiftId = GeneratedColumn<int>(
      'shift_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES shifts (id)'));
  static const VerificationMeta _denomMeta = const VerificationMeta('denom');
  @override
  late final GeneratedColumn<int> denom = GeneratedColumn<int>(
      'denom', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _subtotalMeta =
      const VerificationMeta('subtotal');
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
      'subtotal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, shiftId, denom, quantity, subtotal];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shift_opening_denominations';
  @override
  VerificationContext validateIntegrity(
      Insertable<ShiftOpeningDenomination> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shift_id')) {
      context.handle(_shiftIdMeta,
          shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta));
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('denom')) {
      context.handle(
          _denomMeta, denom.isAcceptableOrUnknown(data['denom']!, _denomMeta));
    } else if (isInserting) {
      context.missing(_denomMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('subtotal')) {
      context.handle(_subtotalMeta,
          subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftOpeningDenomination map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftOpeningDenomination(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      shiftId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shift_id'])!,
      denom: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}denom'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      subtotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}subtotal'])!,
    );
  }

  @override
  $ShiftOpeningDenominationsTable createAlias(String alias) {
    return $ShiftOpeningDenominationsTable(attachedDatabase, alias);
  }
}

class ShiftOpeningDenomination extends DataClass
    implements Insertable<ShiftOpeningDenomination> {
  final int id;
  final int shiftId;

  /// 1000, 500, 200, …
  final int denom;
  final int quantity;
  final double subtotal;
  const ShiftOpeningDenomination(
      {required this.id,
      required this.shiftId,
      required this.denom,
      required this.quantity,
      required this.subtotal});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['shift_id'] = Variable<int>(shiftId);
    map['denom'] = Variable<int>(denom);
    map['quantity'] = Variable<int>(quantity);
    map['subtotal'] = Variable<double>(subtotal);
    return map;
  }

  ShiftOpeningDenominationsCompanion toCompanion(bool nullToAbsent) {
    return ShiftOpeningDenominationsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      denom: Value(denom),
      quantity: Value(quantity),
      subtotal: Value(subtotal),
    );
  }

  factory ShiftOpeningDenomination.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftOpeningDenomination(
      id: serializer.fromJson<int>(json['id']),
      shiftId: serializer.fromJson<int>(json['shiftId']),
      denom: serializer.fromJson<int>(json['denom']),
      quantity: serializer.fromJson<int>(json['quantity']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shiftId': serializer.toJson<int>(shiftId),
      'denom': serializer.toJson<int>(denom),
      'quantity': serializer.toJson<int>(quantity),
      'subtotal': serializer.toJson<double>(subtotal),
    };
  }

  ShiftOpeningDenomination copyWith(
          {int? id,
          int? shiftId,
          int? denom,
          int? quantity,
          double? subtotal}) =>
      ShiftOpeningDenomination(
        id: id ?? this.id,
        shiftId: shiftId ?? this.shiftId,
        denom: denom ?? this.denom,
        quantity: quantity ?? this.quantity,
        subtotal: subtotal ?? this.subtotal,
      );
  ShiftOpeningDenomination copyWithCompanion(
      ShiftOpeningDenominationsCompanion data) {
    return ShiftOpeningDenomination(
      id: data.id.present ? data.id.value : this.id,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      denom: data.denom.present ? data.denom.value : this.denom,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftOpeningDenomination(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('denom: $denom, ')
          ..write('quantity: $quantity, ')
          ..write('subtotal: $subtotal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, shiftId, denom, quantity, subtotal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftOpeningDenomination &&
          other.id == this.id &&
          other.shiftId == this.shiftId &&
          other.denom == this.denom &&
          other.quantity == this.quantity &&
          other.subtotal == this.subtotal);
}

class ShiftOpeningDenominationsCompanion
    extends UpdateCompanion<ShiftOpeningDenomination> {
  final Value<int> id;
  final Value<int> shiftId;
  final Value<int> denom;
  final Value<int> quantity;
  final Value<double> subtotal;
  const ShiftOpeningDenominationsCompanion({
    this.id = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.denom = const Value.absent(),
    this.quantity = const Value.absent(),
    this.subtotal = const Value.absent(),
  });
  ShiftOpeningDenominationsCompanion.insert({
    this.id = const Value.absent(),
    required int shiftId,
    required int denom,
    this.quantity = const Value.absent(),
    this.subtotal = const Value.absent(),
  })  : shiftId = Value(shiftId),
        denom = Value(denom);
  static Insertable<ShiftOpeningDenomination> custom({
    Expression<int>? id,
    Expression<int>? shiftId,
    Expression<int>? denom,
    Expression<int>? quantity,
    Expression<double>? subtotal,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shiftId != null) 'shift_id': shiftId,
      if (denom != null) 'denom': denom,
      if (quantity != null) 'quantity': quantity,
      if (subtotal != null) 'subtotal': subtotal,
    });
  }

  ShiftOpeningDenominationsCompanion copyWith(
      {Value<int>? id,
      Value<int>? shiftId,
      Value<int>? denom,
      Value<int>? quantity,
      Value<double>? subtotal}) {
    return ShiftOpeningDenominationsCompanion(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      denom: denom ?? this.denom,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<int>(shiftId.value);
    }
    if (denom.present) {
      map['denom'] = Variable<int>(denom.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftOpeningDenominationsCompanion(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('denom: $denom, ')
          ..write('quantity: $quantity, ')
          ..write('subtotal: $subtotal')
          ..write(')'))
        .toString();
  }
}

class $ShiftClosingDenominationsTable extends ShiftClosingDenominations
    with TableInfo<$ShiftClosingDenominationsTable, ShiftClosingDenomination> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftClosingDenominationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _shiftIdMeta =
      const VerificationMeta('shiftId');
  @override
  late final GeneratedColumn<int> shiftId = GeneratedColumn<int>(
      'shift_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES shifts (id)'));
  static const VerificationMeta _denomMeta = const VerificationMeta('denom');
  @override
  late final GeneratedColumn<int> denom = GeneratedColumn<int>(
      'denom', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _subtotalMeta =
      const VerificationMeta('subtotal');
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
      'subtotal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, shiftId, denom, quantity, subtotal];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shift_closing_denominations';
  @override
  VerificationContext validateIntegrity(
      Insertable<ShiftClosingDenomination> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shift_id')) {
      context.handle(_shiftIdMeta,
          shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta));
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('denom')) {
      context.handle(
          _denomMeta, denom.isAcceptableOrUnknown(data['denom']!, _denomMeta));
    } else if (isInserting) {
      context.missing(_denomMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('subtotal')) {
      context.handle(_subtotalMeta,
          subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftClosingDenomination map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftClosingDenomination(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      shiftId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shift_id'])!,
      denom: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}denom'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      subtotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}subtotal'])!,
    );
  }

  @override
  $ShiftClosingDenominationsTable createAlias(String alias) {
    return $ShiftClosingDenominationsTable(attachedDatabase, alias);
  }
}

class ShiftClosingDenomination extends DataClass
    implements Insertable<ShiftClosingDenomination> {
  final int id;
  final int shiftId;
  final int denom;
  final int quantity;
  final double subtotal;
  const ShiftClosingDenomination(
      {required this.id,
      required this.shiftId,
      required this.denom,
      required this.quantity,
      required this.subtotal});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['shift_id'] = Variable<int>(shiftId);
    map['denom'] = Variable<int>(denom);
    map['quantity'] = Variable<int>(quantity);
    map['subtotal'] = Variable<double>(subtotal);
    return map;
  }

  ShiftClosingDenominationsCompanion toCompanion(bool nullToAbsent) {
    return ShiftClosingDenominationsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      denom: Value(denom),
      quantity: Value(quantity),
      subtotal: Value(subtotal),
    );
  }

  factory ShiftClosingDenomination.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftClosingDenomination(
      id: serializer.fromJson<int>(json['id']),
      shiftId: serializer.fromJson<int>(json['shiftId']),
      denom: serializer.fromJson<int>(json['denom']),
      quantity: serializer.fromJson<int>(json['quantity']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shiftId': serializer.toJson<int>(shiftId),
      'denom': serializer.toJson<int>(denom),
      'quantity': serializer.toJson<int>(quantity),
      'subtotal': serializer.toJson<double>(subtotal),
    };
  }

  ShiftClosingDenomination copyWith(
          {int? id,
          int? shiftId,
          int? denom,
          int? quantity,
          double? subtotal}) =>
      ShiftClosingDenomination(
        id: id ?? this.id,
        shiftId: shiftId ?? this.shiftId,
        denom: denom ?? this.denom,
        quantity: quantity ?? this.quantity,
        subtotal: subtotal ?? this.subtotal,
      );
  ShiftClosingDenomination copyWithCompanion(
      ShiftClosingDenominationsCompanion data) {
    return ShiftClosingDenomination(
      id: data.id.present ? data.id.value : this.id,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      denom: data.denom.present ? data.denom.value : this.denom,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftClosingDenomination(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('denom: $denom, ')
          ..write('quantity: $quantity, ')
          ..write('subtotal: $subtotal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, shiftId, denom, quantity, subtotal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftClosingDenomination &&
          other.id == this.id &&
          other.shiftId == this.shiftId &&
          other.denom == this.denom &&
          other.quantity == this.quantity &&
          other.subtotal == this.subtotal);
}

class ShiftClosingDenominationsCompanion
    extends UpdateCompanion<ShiftClosingDenomination> {
  final Value<int> id;
  final Value<int> shiftId;
  final Value<int> denom;
  final Value<int> quantity;
  final Value<double> subtotal;
  const ShiftClosingDenominationsCompanion({
    this.id = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.denom = const Value.absent(),
    this.quantity = const Value.absent(),
    this.subtotal = const Value.absent(),
  });
  ShiftClosingDenominationsCompanion.insert({
    this.id = const Value.absent(),
    required int shiftId,
    required int denom,
    this.quantity = const Value.absent(),
    this.subtotal = const Value.absent(),
  })  : shiftId = Value(shiftId),
        denom = Value(denom);
  static Insertable<ShiftClosingDenomination> custom({
    Expression<int>? id,
    Expression<int>? shiftId,
    Expression<int>? denom,
    Expression<int>? quantity,
    Expression<double>? subtotal,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shiftId != null) 'shift_id': shiftId,
      if (denom != null) 'denom': denom,
      if (quantity != null) 'quantity': quantity,
      if (subtotal != null) 'subtotal': subtotal,
    });
  }

  ShiftClosingDenominationsCompanion copyWith(
      {Value<int>? id,
      Value<int>? shiftId,
      Value<int>? denom,
      Value<int>? quantity,
      Value<double>? subtotal}) {
    return ShiftClosingDenominationsCompanion(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      denom: denom ?? this.denom,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<int>(shiftId.value);
    }
    if (denom.present) {
      map['denom'] = Variable<int>(denom.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftClosingDenominationsCompanion(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('denom: $denom, ')
          ..write('quantity: $quantity, ')
          ..write('subtotal: $subtotal')
          ..write(')'))
        .toString();
  }
}

class $ValetTransactionsTable extends ValetTransactions
    with TableInfo<$ValetTransactionsTable, ValetTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ValetTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _localUuidMeta =
      const VerificationMeta('localUuid');
  @override
  late final GeneratedColumn<String> localUuid = GeneratedColumn<String>(
      'local_uuid', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _checkinShiftIdMeta =
      const VerificationMeta('checkinShiftId');
  @override
  late final GeneratedColumn<int> checkinShiftId = GeneratedColumn<int>(
      'checkin_shift_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES shifts (id)'));
  static const VerificationMeta _checkoutShiftIdMeta =
      const VerificationMeta('checkoutShiftId');
  @override
  late final GeneratedColumn<int> checkoutShiftId = GeneratedColumn<int>(
      'checkout_shift_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES shifts (id)'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES offline_accounts (id)'));
  static const VerificationMeta _ticketNumberMeta =
      const VerificationMeta('ticketNumber');
  @override
  late final GeneratedColumn<String> ticketNumber = GeneratedColumn<String>(
      'ticket_number', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
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
      'vehicle_brand', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _vehicleModelMeta =
      const VerificationMeta('vehicleModel');
  @override
  late final GeneratedColumn<String> vehicleModel = GeneratedColumn<String>(
      'vehicle_model', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _vehicleYearMeta =
      const VerificationMeta('vehicleYear');
  @override
  late final GeneratedColumn<String> vehicleYear = GeneratedColumn<String>(
      'vehicle_year', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _vehicleColorMeta =
      const VerificationMeta('vehicleColor');
  @override
  late final GeneratedColumn<String> vehicleColor = GeneratedColumn<String>(
      'vehicle_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _vehicleTypeMeta =
      const VerificationMeta('vehicleType');
  @override
  late final GeneratedColumn<String> vehicleType = GeneratedColumn<String>(
      'vehicle_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
      'slot', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parkingLevelMeta =
      const VerificationMeta('parkingLevel');
  @override
  late final GeneratedColumn<String> parkingLevel = GeneratedColumn<String>(
      'parking_level', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parkingSlotMeta =
      const VerificationMeta('parkingSlot');
  @override
  late final GeneratedColumn<String> parkingSlot = GeneratedColumn<String>(
      'parking_slot', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _belongingsJsonMeta =
      const VerificationMeta('belongingsJson');
  @override
  late final GeneratedColumn<String> belongingsJson = GeneratedColumn<String>(
      'belongings_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _otherBelongingsMeta =
      const VerificationMeta('otherBelongings');
  @override
  late final GeneratedColumn<String> otherBelongings = GeneratedColumn<String>(
      'other_belongings', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _signaturePngMeta =
      const VerificationMeta('signaturePng');
  @override
  late final GeneratedColumn<String> signaturePng = GeneratedColumn<String>(
      'signature_png', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _signatureCapturedAtMeta =
      const VerificationMeta('signatureCapturedAt');
  @override
  late final GeneratedColumn<int> signatureCapturedAt = GeneratedColumn<int>(
      'signature_captured_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _customerFullNameMeta =
      const VerificationMeta('customerFullName');
  @override
  late final GeneratedColumn<String> customerFullName = GeneratedColumn<String>(
      'customer_full_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerMobileMeta =
      const VerificationMeta('customerMobile');
  @override
  late final GeneratedColumn<String> customerMobile = GeneratedColumn<String>(
      'customer_mobile', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _assignedValetDriverMeta =
      const VerificationMeta('assignedValetDriver');
  @override
  late final GeneratedColumn<String> assignedValetDriver =
      GeneratedColumn<String>('assigned_valet_driver', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _specialInstructionsMeta =
      const VerificationMeta('specialInstructions');
  @override
  late final GeneratedColumn<String> specialInstructions =
      GeneratedColumn<String>('special_instructions', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _valetServiceTypeMeta =
      const VerificationMeta('valetServiceType');
  @override
  late final GeneratedColumn<String> valetServiceType = GeneratedColumn<String>(
      'valet_service_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _vehicleDamageJsonMeta =
      const VerificationMeta('vehicleDamageJson');
  @override
  late final GeneratedColumn<String> vehicleDamageJson =
      GeneratedColumn<String>('vehicle_damage_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _branchSnapshotMeta =
      const VerificationMeta('branchSnapshot');
  @override
  late final GeneratedColumn<String> branchSnapshot = GeneratedColumn<String>(
      'branch_snapshot', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _areaSnapshotMeta =
      const VerificationMeta('areaSnapshot');
  @override
  late final GeneratedColumn<String> areaSnapshot = GeneratedColumn<String>(
      'area_snapshot', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deviceIdSnapshotMeta =
      const VerificationMeta('deviceIdSnapshot');
  @override
  late final GeneratedColumn<String> deviceIdSnapshot = GeneratedColumn<String>(
      'device_id_snapshot', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serverTicketIdMeta =
      const VerificationMeta('serverTicketId');
  @override
  late final GeneratedColumn<String> serverTicketId = GeneratedColumn<String>(
      'server_ticket_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastModifiedAtMeta =
      const VerificationMeta('lastModifiedAt');
  @override
  late final GeneratedColumn<int> lastModifiedAt = GeneratedColumn<int>(
      'last_modified_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _localCreatedAtMeta =
      const VerificationMeta('localCreatedAt');
  @override
  late final GeneratedColumn<int> localCreatedAt = GeneratedColumn<int>(
      'local_created_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _timeInMeta = const VerificationMeta('timeIn');
  @override
  late final GeneratedColumn<int> timeIn = GeneratedColumn<int>(
      'time_in', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _timeOutMeta =
      const VerificationMeta('timeOut');
  @override
  late final GeneratedColumn<int> timeOut = GeneratedColumn<int>(
      'time_out', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _flatRateMeta =
      const VerificationMeta('flatRate');
  @override
  late final GeneratedColumn<double> flatRate = GeneratedColumn<double>(
      'flat_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _succeedingFeeMeta =
      const VerificationMeta('succeedingFee');
  @override
  late final GeneratedColumn<double> succeedingFee = GeneratedColumn<double>(
      'succeeding_fee', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _overnightFeeMeta =
      const VerificationMeta('overnightFee');
  @override
  late final GeneratedColumn<double> overnightFee = GeneratedColumn<double>(
      'overnight_fee', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _lostTicketFeeMeta =
      const VerificationMeta('lostTicketFee');
  @override
  late final GeneratedColumn<double> lostTicketFee = GeneratedColumn<double>(
      'lost_ticket_fee', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalFeeMeta =
      const VerificationMeta('totalFee');
  @override
  late final GeneratedColumn<double> totalFee = GeneratedColumn<double>(
      'total_fee', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _amountTenderedMeta =
      const VerificationMeta('amountTendered');
  @override
  late final GeneratedColumn<double> amountTendered = GeneratedColumn<double>(
      'amount_tendered', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _changeAmountMeta =
      const VerificationMeta('changeAmount');
  @override
  late final GeneratedColumn<double> changeAmount = GeneratedColumn<double>(
      'change_amount', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        localUuid,
        checkinShiftId,
        checkoutShiftId,
        userId,
        ticketNumber,
        plateNumber,
        vehicleBrand,
        vehicleModel,
        vehicleYear,
        vehicleColor,
        vehicleType,
        slot,
        parkingLevel,
        parkingSlot,
        belongingsJson,
        otherBelongings,
        signaturePng,
        signatureCapturedAt,
        customerFullName,
        customerMobile,
        assignedValetDriver,
        specialInstructions,
        valetServiceType,
        vehicleDamageJson,
        branchSnapshot,
        areaSnapshot,
        deviceIdSnapshot,
        serverTicketId,
        lastModifiedAt,
        localCreatedAt,
        timeIn,
        timeOut,
        durationMinutes,
        flatRate,
        succeedingFee,
        overnightFee,
        lostTicketFee,
        totalFee,
        amountTendered,
        changeAmount,
        status,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<ValetTransaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_uuid')) {
      context.handle(_localUuidMeta,
          localUuid.isAcceptableOrUnknown(data['local_uuid']!, _localUuidMeta));
    }
    if (data.containsKey('checkin_shift_id')) {
      context.handle(
          _checkinShiftIdMeta,
          checkinShiftId.isAcceptableOrUnknown(
              data['checkin_shift_id']!, _checkinShiftIdMeta));
    } else if (isInserting) {
      context.missing(_checkinShiftIdMeta);
    }
    if (data.containsKey('checkout_shift_id')) {
      context.handle(
          _checkoutShiftIdMeta,
          checkoutShiftId.isAcceptableOrUnknown(
              data['checkout_shift_id']!, _checkoutShiftIdMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('ticket_number')) {
      context.handle(
          _ticketNumberMeta,
          ticketNumber.isAcceptableOrUnknown(
              data['ticket_number']!, _ticketNumberMeta));
    } else if (isInserting) {
      context.missing(_ticketNumberMeta);
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
    }
    if (data.containsKey('vehicle_model')) {
      context.handle(
          _vehicleModelMeta,
          vehicleModel.isAcceptableOrUnknown(
              data['vehicle_model']!, _vehicleModelMeta));
    }
    if (data.containsKey('vehicle_year')) {
      context.handle(
          _vehicleYearMeta,
          vehicleYear.isAcceptableOrUnknown(
              data['vehicle_year']!, _vehicleYearMeta));
    }
    if (data.containsKey('vehicle_color')) {
      context.handle(
          _vehicleColorMeta,
          vehicleColor.isAcceptableOrUnknown(
              data['vehicle_color']!, _vehicleColorMeta));
    }
    if (data.containsKey('vehicle_type')) {
      context.handle(
          _vehicleTypeMeta,
          vehicleType.isAcceptableOrUnknown(
              data['vehicle_type']!, _vehicleTypeMeta));
    }
    if (data.containsKey('slot')) {
      context.handle(
          _slotMeta, slot.isAcceptableOrUnknown(data['slot']!, _slotMeta));
    }
    if (data.containsKey('parking_level')) {
      context.handle(
          _parkingLevelMeta,
          parkingLevel.isAcceptableOrUnknown(
              data['parking_level']!, _parkingLevelMeta));
    }
    if (data.containsKey('parking_slot')) {
      context.handle(
          _parkingSlotMeta,
          parkingSlot.isAcceptableOrUnknown(
              data['parking_slot']!, _parkingSlotMeta));
    }
    if (data.containsKey('belongings_json')) {
      context.handle(
          _belongingsJsonMeta,
          belongingsJson.isAcceptableOrUnknown(
              data['belongings_json']!, _belongingsJsonMeta));
    }
    if (data.containsKey('other_belongings')) {
      context.handle(
          _otherBelongingsMeta,
          otherBelongings.isAcceptableOrUnknown(
              data['other_belongings']!, _otherBelongingsMeta));
    }
    if (data.containsKey('signature_png')) {
      context.handle(
          _signaturePngMeta,
          signaturePng.isAcceptableOrUnknown(
              data['signature_png']!, _signaturePngMeta));
    }
    if (data.containsKey('signature_captured_at')) {
      context.handle(
          _signatureCapturedAtMeta,
          signatureCapturedAt.isAcceptableOrUnknown(
              data['signature_captured_at']!, _signatureCapturedAtMeta));
    }
    if (data.containsKey('customer_full_name')) {
      context.handle(
          _customerFullNameMeta,
          customerFullName.isAcceptableOrUnknown(
              data['customer_full_name']!, _customerFullNameMeta));
    }
    if (data.containsKey('customer_mobile')) {
      context.handle(
          _customerMobileMeta,
          customerMobile.isAcceptableOrUnknown(
              data['customer_mobile']!, _customerMobileMeta));
    }
    if (data.containsKey('assigned_valet_driver')) {
      context.handle(
          _assignedValetDriverMeta,
          assignedValetDriver.isAcceptableOrUnknown(
              data['assigned_valet_driver']!, _assignedValetDriverMeta));
    }
    if (data.containsKey('special_instructions')) {
      context.handle(
          _specialInstructionsMeta,
          specialInstructions.isAcceptableOrUnknown(
              data['special_instructions']!, _specialInstructionsMeta));
    }
    if (data.containsKey('valet_service_type')) {
      context.handle(
          _valetServiceTypeMeta,
          valetServiceType.isAcceptableOrUnknown(
              data['valet_service_type']!, _valetServiceTypeMeta));
    }
    if (data.containsKey('vehicle_damage_json')) {
      context.handle(
          _vehicleDamageJsonMeta,
          vehicleDamageJson.isAcceptableOrUnknown(
              data['vehicle_damage_json']!, _vehicleDamageJsonMeta));
    }
    if (data.containsKey('branch_snapshot')) {
      context.handle(
          _branchSnapshotMeta,
          branchSnapshot.isAcceptableOrUnknown(
              data['branch_snapshot']!, _branchSnapshotMeta));
    }
    if (data.containsKey('area_snapshot')) {
      context.handle(
          _areaSnapshotMeta,
          areaSnapshot.isAcceptableOrUnknown(
              data['area_snapshot']!, _areaSnapshotMeta));
    }
    if (data.containsKey('device_id_snapshot')) {
      context.handle(
          _deviceIdSnapshotMeta,
          deviceIdSnapshot.isAcceptableOrUnknown(
              data['device_id_snapshot']!, _deviceIdSnapshotMeta));
    }
    if (data.containsKey('server_ticket_id')) {
      context.handle(
          _serverTicketIdMeta,
          serverTicketId.isAcceptableOrUnknown(
              data['server_ticket_id']!, _serverTicketIdMeta));
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
          _lastModifiedAtMeta,
          lastModifiedAt.isAcceptableOrUnknown(
              data['last_modified_at']!, _lastModifiedAtMeta));
    }
    if (data.containsKey('local_created_at')) {
      context.handle(
          _localCreatedAtMeta,
          localCreatedAt.isAcceptableOrUnknown(
              data['local_created_at']!, _localCreatedAtMeta));
    }
    if (data.containsKey('time_in')) {
      context.handle(_timeInMeta,
          timeIn.isAcceptableOrUnknown(data['time_in']!, _timeInMeta));
    } else if (isInserting) {
      context.missing(_timeInMeta);
    }
    if (data.containsKey('time_out')) {
      context.handle(_timeOutMeta,
          timeOut.isAcceptableOrUnknown(data['time_out']!, _timeOutMeta));
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    }
    if (data.containsKey('flat_rate')) {
      context.handle(_flatRateMeta,
          flatRate.isAcceptableOrUnknown(data['flat_rate']!, _flatRateMeta));
    }
    if (data.containsKey('succeeding_fee')) {
      context.handle(
          _succeedingFeeMeta,
          succeedingFee.isAcceptableOrUnknown(
              data['succeeding_fee']!, _succeedingFeeMeta));
    }
    if (data.containsKey('overnight_fee')) {
      context.handle(
          _overnightFeeMeta,
          overnightFee.isAcceptableOrUnknown(
              data['overnight_fee']!, _overnightFeeMeta));
    }
    if (data.containsKey('lost_ticket_fee')) {
      context.handle(
          _lostTicketFeeMeta,
          lostTicketFee.isAcceptableOrUnknown(
              data['lost_ticket_fee']!, _lostTicketFeeMeta));
    }
    if (data.containsKey('total_fee')) {
      context.handle(_totalFeeMeta,
          totalFee.isAcceptableOrUnknown(data['total_fee']!, _totalFeeMeta));
    }
    if (data.containsKey('amount_tendered')) {
      context.handle(
          _amountTenderedMeta,
          amountTendered.isAcceptableOrUnknown(
              data['amount_tendered']!, _amountTenderedMeta));
    }
    if (data.containsKey('change_amount')) {
      context.handle(
          _changeAmountMeta,
          changeAmount.isAcceptableOrUnknown(
              data['change_amount']!, _changeAmountMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ValetTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ValetTransaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      localUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_uuid']),
      checkinShiftId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}checkin_shift_id'])!,
      checkoutShiftId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}checkout_shift_id']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      ticketNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ticket_number'])!,
      plateNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plate_number'])!,
      vehicleBrand: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vehicle_brand']),
      vehicleModel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vehicle_model']),
      vehicleYear: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vehicle_year']),
      vehicleColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vehicle_color']),
      vehicleType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vehicle_type']),
      slot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slot']),
      parkingLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parking_level']),
      parkingSlot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parking_slot']),
      belongingsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}belongings_json']),
      otherBelongings: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}other_belongings']),
      signaturePng: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}signature_png']),
      signatureCapturedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}signature_captured_at']),
      customerFullName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}customer_full_name']),
      customerMobile: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_mobile']),
      assignedValetDriver: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}assigned_valet_driver']),
      specialInstructions: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}special_instructions']),
      valetServiceType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}valet_service_type']),
      vehicleDamageJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}vehicle_damage_json']),
      branchSnapshot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_snapshot']),
      areaSnapshot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}area_snapshot']),
      deviceIdSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}device_id_snapshot']),
      serverTicketId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}server_ticket_id']),
      lastModifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_modified_at']),
      localCreatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_created_at']),
      timeIn: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}time_in'])!,
      timeOut: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}time_out']),
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes']),
      flatRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}flat_rate']),
      succeedingFee: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}succeeding_fee']),
      overnightFee: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}overnight_fee']),
      lostTicketFee: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lost_ticket_fee']),
      totalFee: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_fee']),
      amountTendered: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount_tendered']),
      changeAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}change_amount']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $ValetTransactionsTable createAlias(String alias) {
    return $ValetTransactionsTable(attachedDatabase, alias);
  }
}

class ValetTransaction extends DataClass
    implements Insertable<ValetTransaction> {
  final int id;

  /// Client UUID for idempotent sync; backfilled on upgrade for legacy rows.
  final String? localUuid;

  /// Shift that was open when the vehicle was checked in (immutable).
  final int checkinShiftId;

  /// Shift responsible for checkout: set when adopting from a prior cashier's
  /// open tickets, or on actual checkout. Null until assigned.
  final int? checkoutShiftId;
  final int userId;
  final String ticketNumber;
  final String plateNumber;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleYear;
  final String? vehicleColor;
  final String? vehicleType;
  final String? slot;
  final String? parkingLevel;
  final String? parkingSlot;
  final String? belongingsJson;
  final String? otherBelongings;

  /// Base64-encoded PNG (same bytes as before; stored as TEXT instead of BLOB).
  final String? signaturePng;
  final int? signatureCapturedAt;
  final String? customerFullName;
  final String? customerMobile;
  final String? assignedValetDriver;
  final String? specialInstructions;
  final String? valetServiceType;
  final String? vehicleDamageJson;
  final String? branchSnapshot;
  final String? areaSnapshot;
  final String? deviceIdSnapshot;
  final String? serverTicketId;
  final int? lastModifiedAt;
  final int? localCreatedAt;
  final int timeIn;
  final int? timeOut;
  final int? durationMinutes;
  final double? flatRate;
  final double? succeedingFee;
  final double? overnightFee;
  final double? lostTicketFee;
  final double? totalFee;
  final double? amountTendered;
  final double? changeAmount;
  final String status;
  final int? syncedAt;
  const ValetTransaction(
      {required this.id,
      this.localUuid,
      required this.checkinShiftId,
      this.checkoutShiftId,
      required this.userId,
      required this.ticketNumber,
      required this.plateNumber,
      this.vehicleBrand,
      this.vehicleModel,
      this.vehicleYear,
      this.vehicleColor,
      this.vehicleType,
      this.slot,
      this.parkingLevel,
      this.parkingSlot,
      this.belongingsJson,
      this.otherBelongings,
      this.signaturePng,
      this.signatureCapturedAt,
      this.customerFullName,
      this.customerMobile,
      this.assignedValetDriver,
      this.specialInstructions,
      this.valetServiceType,
      this.vehicleDamageJson,
      this.branchSnapshot,
      this.areaSnapshot,
      this.deviceIdSnapshot,
      this.serverTicketId,
      this.lastModifiedAt,
      this.localCreatedAt,
      required this.timeIn,
      this.timeOut,
      this.durationMinutes,
      this.flatRate,
      this.succeedingFee,
      this.overnightFee,
      this.lostTicketFee,
      this.totalFee,
      this.amountTendered,
      this.changeAmount,
      required this.status,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || localUuid != null) {
      map['local_uuid'] = Variable<String>(localUuid);
    }
    map['checkin_shift_id'] = Variable<int>(checkinShiftId);
    if (!nullToAbsent || checkoutShiftId != null) {
      map['checkout_shift_id'] = Variable<int>(checkoutShiftId);
    }
    map['user_id'] = Variable<int>(userId);
    map['ticket_number'] = Variable<String>(ticketNumber);
    map['plate_number'] = Variable<String>(plateNumber);
    if (!nullToAbsent || vehicleBrand != null) {
      map['vehicle_brand'] = Variable<String>(vehicleBrand);
    }
    if (!nullToAbsent || vehicleModel != null) {
      map['vehicle_model'] = Variable<String>(vehicleModel);
    }
    if (!nullToAbsent || vehicleYear != null) {
      map['vehicle_year'] = Variable<String>(vehicleYear);
    }
    if (!nullToAbsent || vehicleColor != null) {
      map['vehicle_color'] = Variable<String>(vehicleColor);
    }
    if (!nullToAbsent || vehicleType != null) {
      map['vehicle_type'] = Variable<String>(vehicleType);
    }
    if (!nullToAbsent || slot != null) {
      map['slot'] = Variable<String>(slot);
    }
    if (!nullToAbsent || parkingLevel != null) {
      map['parking_level'] = Variable<String>(parkingLevel);
    }
    if (!nullToAbsent || parkingSlot != null) {
      map['parking_slot'] = Variable<String>(parkingSlot);
    }
    if (!nullToAbsent || belongingsJson != null) {
      map['belongings_json'] = Variable<String>(belongingsJson);
    }
    if (!nullToAbsent || otherBelongings != null) {
      map['other_belongings'] = Variable<String>(otherBelongings);
    }
    if (!nullToAbsent || signaturePng != null) {
      map['signature_png'] = Variable<String>(signaturePng);
    }
    if (!nullToAbsent || signatureCapturedAt != null) {
      map['signature_captured_at'] = Variable<int>(signatureCapturedAt);
    }
    if (!nullToAbsent || customerFullName != null) {
      map['customer_full_name'] = Variable<String>(customerFullName);
    }
    if (!nullToAbsent || customerMobile != null) {
      map['customer_mobile'] = Variable<String>(customerMobile);
    }
    if (!nullToAbsent || assignedValetDriver != null) {
      map['assigned_valet_driver'] = Variable<String>(assignedValetDriver);
    }
    if (!nullToAbsent || specialInstructions != null) {
      map['special_instructions'] = Variable<String>(specialInstructions);
    }
    if (!nullToAbsent || valetServiceType != null) {
      map['valet_service_type'] = Variable<String>(valetServiceType);
    }
    if (!nullToAbsent || vehicleDamageJson != null) {
      map['vehicle_damage_json'] = Variable<String>(vehicleDamageJson);
    }
    if (!nullToAbsent || branchSnapshot != null) {
      map['branch_snapshot'] = Variable<String>(branchSnapshot);
    }
    if (!nullToAbsent || areaSnapshot != null) {
      map['area_snapshot'] = Variable<String>(areaSnapshot);
    }
    if (!nullToAbsent || deviceIdSnapshot != null) {
      map['device_id_snapshot'] = Variable<String>(deviceIdSnapshot);
    }
    if (!nullToAbsent || serverTicketId != null) {
      map['server_ticket_id'] = Variable<String>(serverTicketId);
    }
    if (!nullToAbsent || lastModifiedAt != null) {
      map['last_modified_at'] = Variable<int>(lastModifiedAt);
    }
    if (!nullToAbsent || localCreatedAt != null) {
      map['local_created_at'] = Variable<int>(localCreatedAt);
    }
    map['time_in'] = Variable<int>(timeIn);
    if (!nullToAbsent || timeOut != null) {
      map['time_out'] = Variable<int>(timeOut);
    }
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    if (!nullToAbsent || flatRate != null) {
      map['flat_rate'] = Variable<double>(flatRate);
    }
    if (!nullToAbsent || succeedingFee != null) {
      map['succeeding_fee'] = Variable<double>(succeedingFee);
    }
    if (!nullToAbsent || overnightFee != null) {
      map['overnight_fee'] = Variable<double>(overnightFee);
    }
    if (!nullToAbsent || lostTicketFee != null) {
      map['lost_ticket_fee'] = Variable<double>(lostTicketFee);
    }
    if (!nullToAbsent || totalFee != null) {
      map['total_fee'] = Variable<double>(totalFee);
    }
    if (!nullToAbsent || amountTendered != null) {
      map['amount_tendered'] = Variable<double>(amountTendered);
    }
    if (!nullToAbsent || changeAmount != null) {
      map['change_amount'] = Variable<double>(changeAmount);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<int>(syncedAt);
    }
    return map;
  }

  ValetTransactionsCompanion toCompanion(bool nullToAbsent) {
    return ValetTransactionsCompanion(
      id: Value(id),
      localUuid: localUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(localUuid),
      checkinShiftId: Value(checkinShiftId),
      checkoutShiftId: checkoutShiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(checkoutShiftId),
      userId: Value(userId),
      ticketNumber: Value(ticketNumber),
      plateNumber: Value(plateNumber),
      vehicleBrand: vehicleBrand == null && nullToAbsent
          ? const Value.absent()
          : Value(vehicleBrand),
      vehicleModel: vehicleModel == null && nullToAbsent
          ? const Value.absent()
          : Value(vehicleModel),
      vehicleYear: vehicleYear == null && nullToAbsent
          ? const Value.absent()
          : Value(vehicleYear),
      vehicleColor: vehicleColor == null && nullToAbsent
          ? const Value.absent()
          : Value(vehicleColor),
      vehicleType: vehicleType == null && nullToAbsent
          ? const Value.absent()
          : Value(vehicleType),
      slot: slot == null && nullToAbsent ? const Value.absent() : Value(slot),
      parkingLevel: parkingLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(parkingLevel),
      parkingSlot: parkingSlot == null && nullToAbsent
          ? const Value.absent()
          : Value(parkingSlot),
      belongingsJson: belongingsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(belongingsJson),
      otherBelongings: otherBelongings == null && nullToAbsent
          ? const Value.absent()
          : Value(otherBelongings),
      signaturePng: signaturePng == null && nullToAbsent
          ? const Value.absent()
          : Value(signaturePng),
      signatureCapturedAt: signatureCapturedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(signatureCapturedAt),
      customerFullName: customerFullName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerFullName),
      customerMobile: customerMobile == null && nullToAbsent
          ? const Value.absent()
          : Value(customerMobile),
      assignedValetDriver: assignedValetDriver == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedValetDriver),
      specialInstructions: specialInstructions == null && nullToAbsent
          ? const Value.absent()
          : Value(specialInstructions),
      valetServiceType: valetServiceType == null && nullToAbsent
          ? const Value.absent()
          : Value(valetServiceType),
      vehicleDamageJson: vehicleDamageJson == null && nullToAbsent
          ? const Value.absent()
          : Value(vehicleDamageJson),
      branchSnapshot: branchSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(branchSnapshot),
      areaSnapshot: areaSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(areaSnapshot),
      deviceIdSnapshot: deviceIdSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceIdSnapshot),
      serverTicketId: serverTicketId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverTicketId),
      lastModifiedAt: lastModifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedAt),
      localCreatedAt: localCreatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(localCreatedAt),
      timeIn: Value(timeIn),
      timeOut: timeOut == null && nullToAbsent
          ? const Value.absent()
          : Value(timeOut),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      flatRate: flatRate == null && nullToAbsent
          ? const Value.absent()
          : Value(flatRate),
      succeedingFee: succeedingFee == null && nullToAbsent
          ? const Value.absent()
          : Value(succeedingFee),
      overnightFee: overnightFee == null && nullToAbsent
          ? const Value.absent()
          : Value(overnightFee),
      lostTicketFee: lostTicketFee == null && nullToAbsent
          ? const Value.absent()
          : Value(lostTicketFee),
      totalFee: totalFee == null && nullToAbsent
          ? const Value.absent()
          : Value(totalFee),
      amountTendered: amountTendered == null && nullToAbsent
          ? const Value.absent()
          : Value(amountTendered),
      changeAmount: changeAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(changeAmount),
      status: Value(status),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory ValetTransaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ValetTransaction(
      id: serializer.fromJson<int>(json['id']),
      localUuid: serializer.fromJson<String?>(json['localUuid']),
      checkinShiftId: serializer.fromJson<int>(json['checkinShiftId']),
      checkoutShiftId: serializer.fromJson<int?>(json['checkoutShiftId']),
      userId: serializer.fromJson<int>(json['userId']),
      ticketNumber: serializer.fromJson<String>(json['ticketNumber']),
      plateNumber: serializer.fromJson<String>(json['plateNumber']),
      vehicleBrand: serializer.fromJson<String?>(json['vehicleBrand']),
      vehicleModel: serializer.fromJson<String?>(json['vehicleModel']),
      vehicleYear: serializer.fromJson<String?>(json['vehicleYear']),
      vehicleColor: serializer.fromJson<String?>(json['vehicleColor']),
      vehicleType: serializer.fromJson<String?>(json['vehicleType']),
      slot: serializer.fromJson<String?>(json['slot']),
      parkingLevel: serializer.fromJson<String?>(json['parkingLevel']),
      parkingSlot: serializer.fromJson<String?>(json['parkingSlot']),
      belongingsJson: serializer.fromJson<String?>(json['belongingsJson']),
      otherBelongings: serializer.fromJson<String?>(json['otherBelongings']),
      signaturePng: serializer.fromJson<String?>(json['signaturePng']),
      signatureCapturedAt:
          serializer.fromJson<int?>(json['signatureCapturedAt']),
      customerFullName: serializer.fromJson<String?>(json['customerFullName']),
      customerMobile: serializer.fromJson<String?>(json['customerMobile']),
      assignedValetDriver:
          serializer.fromJson<String?>(json['assignedValetDriver']),
      specialInstructions:
          serializer.fromJson<String?>(json['specialInstructions']),
      valetServiceType: serializer.fromJson<String?>(json['valetServiceType']),
      vehicleDamageJson:
          serializer.fromJson<String?>(json['vehicleDamageJson']),
      branchSnapshot: serializer.fromJson<String?>(json['branchSnapshot']),
      areaSnapshot: serializer.fromJson<String?>(json['areaSnapshot']),
      deviceIdSnapshot: serializer.fromJson<String?>(json['deviceIdSnapshot']),
      serverTicketId: serializer.fromJson<String?>(json['serverTicketId']),
      lastModifiedAt: serializer.fromJson<int?>(json['lastModifiedAt']),
      localCreatedAt: serializer.fromJson<int?>(json['localCreatedAt']),
      timeIn: serializer.fromJson<int>(json['timeIn']),
      timeOut: serializer.fromJson<int?>(json['timeOut']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      flatRate: serializer.fromJson<double?>(json['flatRate']),
      succeedingFee: serializer.fromJson<double?>(json['succeedingFee']),
      overnightFee: serializer.fromJson<double?>(json['overnightFee']),
      lostTicketFee: serializer.fromJson<double?>(json['lostTicketFee']),
      totalFee: serializer.fromJson<double?>(json['totalFee']),
      amountTendered: serializer.fromJson<double?>(json['amountTendered']),
      changeAmount: serializer.fromJson<double?>(json['changeAmount']),
      status: serializer.fromJson<String>(json['status']),
      syncedAt: serializer.fromJson<int?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localUuid': serializer.toJson<String?>(localUuid),
      'checkinShiftId': serializer.toJson<int>(checkinShiftId),
      'checkoutShiftId': serializer.toJson<int?>(checkoutShiftId),
      'userId': serializer.toJson<int>(userId),
      'ticketNumber': serializer.toJson<String>(ticketNumber),
      'plateNumber': serializer.toJson<String>(plateNumber),
      'vehicleBrand': serializer.toJson<String?>(vehicleBrand),
      'vehicleModel': serializer.toJson<String?>(vehicleModel),
      'vehicleYear': serializer.toJson<String?>(vehicleYear),
      'vehicleColor': serializer.toJson<String?>(vehicleColor),
      'vehicleType': serializer.toJson<String?>(vehicleType),
      'slot': serializer.toJson<String?>(slot),
      'parkingLevel': serializer.toJson<String?>(parkingLevel),
      'parkingSlot': serializer.toJson<String?>(parkingSlot),
      'belongingsJson': serializer.toJson<String?>(belongingsJson),
      'otherBelongings': serializer.toJson<String?>(otherBelongings),
      'signaturePng': serializer.toJson<String?>(signaturePng),
      'signatureCapturedAt': serializer.toJson<int?>(signatureCapturedAt),
      'customerFullName': serializer.toJson<String?>(customerFullName),
      'customerMobile': serializer.toJson<String?>(customerMobile),
      'assignedValetDriver': serializer.toJson<String?>(assignedValetDriver),
      'specialInstructions': serializer.toJson<String?>(specialInstructions),
      'valetServiceType': serializer.toJson<String?>(valetServiceType),
      'vehicleDamageJson': serializer.toJson<String?>(vehicleDamageJson),
      'branchSnapshot': serializer.toJson<String?>(branchSnapshot),
      'areaSnapshot': serializer.toJson<String?>(areaSnapshot),
      'deviceIdSnapshot': serializer.toJson<String?>(deviceIdSnapshot),
      'serverTicketId': serializer.toJson<String?>(serverTicketId),
      'lastModifiedAt': serializer.toJson<int?>(lastModifiedAt),
      'localCreatedAt': serializer.toJson<int?>(localCreatedAt),
      'timeIn': serializer.toJson<int>(timeIn),
      'timeOut': serializer.toJson<int?>(timeOut),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'flatRate': serializer.toJson<double?>(flatRate),
      'succeedingFee': serializer.toJson<double?>(succeedingFee),
      'overnightFee': serializer.toJson<double?>(overnightFee),
      'lostTicketFee': serializer.toJson<double?>(lostTicketFee),
      'totalFee': serializer.toJson<double?>(totalFee),
      'amountTendered': serializer.toJson<double?>(amountTendered),
      'changeAmount': serializer.toJson<double?>(changeAmount),
      'status': serializer.toJson<String>(status),
      'syncedAt': serializer.toJson<int?>(syncedAt),
    };
  }

  ValetTransaction copyWith(
          {int? id,
          Value<String?> localUuid = const Value.absent(),
          int? checkinShiftId,
          Value<int?> checkoutShiftId = const Value.absent(),
          int? userId,
          String? ticketNumber,
          String? plateNumber,
          Value<String?> vehicleBrand = const Value.absent(),
          Value<String?> vehicleModel = const Value.absent(),
          Value<String?> vehicleYear = const Value.absent(),
          Value<String?> vehicleColor = const Value.absent(),
          Value<String?> vehicleType = const Value.absent(),
          Value<String?> slot = const Value.absent(),
          Value<String?> parkingLevel = const Value.absent(),
          Value<String?> parkingSlot = const Value.absent(),
          Value<String?> belongingsJson = const Value.absent(),
          Value<String?> otherBelongings = const Value.absent(),
          Value<String?> signaturePng = const Value.absent(),
          Value<int?> signatureCapturedAt = const Value.absent(),
          Value<String?> customerFullName = const Value.absent(),
          Value<String?> customerMobile = const Value.absent(),
          Value<String?> assignedValetDriver = const Value.absent(),
          Value<String?> specialInstructions = const Value.absent(),
          Value<String?> valetServiceType = const Value.absent(),
          Value<String?> vehicleDamageJson = const Value.absent(),
          Value<String?> branchSnapshot = const Value.absent(),
          Value<String?> areaSnapshot = const Value.absent(),
          Value<String?> deviceIdSnapshot = const Value.absent(),
          Value<String?> serverTicketId = const Value.absent(),
          Value<int?> lastModifiedAt = const Value.absent(),
          Value<int?> localCreatedAt = const Value.absent(),
          int? timeIn,
          Value<int?> timeOut = const Value.absent(),
          Value<int?> durationMinutes = const Value.absent(),
          Value<double?> flatRate = const Value.absent(),
          Value<double?> succeedingFee = const Value.absent(),
          Value<double?> overnightFee = const Value.absent(),
          Value<double?> lostTicketFee = const Value.absent(),
          Value<double?> totalFee = const Value.absent(),
          Value<double?> amountTendered = const Value.absent(),
          Value<double?> changeAmount = const Value.absent(),
          String? status,
          Value<int?> syncedAt = const Value.absent()}) =>
      ValetTransaction(
        id: id ?? this.id,
        localUuid: localUuid.present ? localUuid.value : this.localUuid,
        checkinShiftId: checkinShiftId ?? this.checkinShiftId,
        checkoutShiftId: checkoutShiftId.present
            ? checkoutShiftId.value
            : this.checkoutShiftId,
        userId: userId ?? this.userId,
        ticketNumber: ticketNumber ?? this.ticketNumber,
        plateNumber: plateNumber ?? this.plateNumber,
        vehicleBrand:
            vehicleBrand.present ? vehicleBrand.value : this.vehicleBrand,
        vehicleModel:
            vehicleModel.present ? vehicleModel.value : this.vehicleModel,
        vehicleYear: vehicleYear.present ? vehicleYear.value : this.vehicleYear,
        vehicleColor:
            vehicleColor.present ? vehicleColor.value : this.vehicleColor,
        vehicleType: vehicleType.present ? vehicleType.value : this.vehicleType,
        slot: slot.present ? slot.value : this.slot,
        parkingLevel:
            parkingLevel.present ? parkingLevel.value : this.parkingLevel,
        parkingSlot: parkingSlot.present ? parkingSlot.value : this.parkingSlot,
        belongingsJson:
            belongingsJson.present ? belongingsJson.value : this.belongingsJson,
        otherBelongings: otherBelongings.present
            ? otherBelongings.value
            : this.otherBelongings,
        signaturePng:
            signaturePng.present ? signaturePng.value : this.signaturePng,
        signatureCapturedAt: signatureCapturedAt.present
            ? signatureCapturedAt.value
            : this.signatureCapturedAt,
        customerFullName: customerFullName.present
            ? customerFullName.value
            : this.customerFullName,
        customerMobile:
            customerMobile.present ? customerMobile.value : this.customerMobile,
        assignedValetDriver: assignedValetDriver.present
            ? assignedValetDriver.value
            : this.assignedValetDriver,
        specialInstructions: specialInstructions.present
            ? specialInstructions.value
            : this.specialInstructions,
        valetServiceType: valetServiceType.present
            ? valetServiceType.value
            : this.valetServiceType,
        vehicleDamageJson: vehicleDamageJson.present
            ? vehicleDamageJson.value
            : this.vehicleDamageJson,
        branchSnapshot:
            branchSnapshot.present ? branchSnapshot.value : this.branchSnapshot,
        areaSnapshot:
            areaSnapshot.present ? areaSnapshot.value : this.areaSnapshot,
        deviceIdSnapshot: deviceIdSnapshot.present
            ? deviceIdSnapshot.value
            : this.deviceIdSnapshot,
        serverTicketId:
            serverTicketId.present ? serverTicketId.value : this.serverTicketId,
        lastModifiedAt:
            lastModifiedAt.present ? lastModifiedAt.value : this.lastModifiedAt,
        localCreatedAt:
            localCreatedAt.present ? localCreatedAt.value : this.localCreatedAt,
        timeIn: timeIn ?? this.timeIn,
        timeOut: timeOut.present ? timeOut.value : this.timeOut,
        durationMinutes: durationMinutes.present
            ? durationMinutes.value
            : this.durationMinutes,
        flatRate: flatRate.present ? flatRate.value : this.flatRate,
        succeedingFee:
            succeedingFee.present ? succeedingFee.value : this.succeedingFee,
        overnightFee:
            overnightFee.present ? overnightFee.value : this.overnightFee,
        lostTicketFee:
            lostTicketFee.present ? lostTicketFee.value : this.lostTicketFee,
        totalFee: totalFee.present ? totalFee.value : this.totalFee,
        amountTendered:
            amountTendered.present ? amountTendered.value : this.amountTendered,
        changeAmount:
            changeAmount.present ? changeAmount.value : this.changeAmount,
        status: status ?? this.status,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  ValetTransaction copyWithCompanion(ValetTransactionsCompanion data) {
    return ValetTransaction(
      id: data.id.present ? data.id.value : this.id,
      localUuid: data.localUuid.present ? data.localUuid.value : this.localUuid,
      checkinShiftId: data.checkinShiftId.present
          ? data.checkinShiftId.value
          : this.checkinShiftId,
      checkoutShiftId: data.checkoutShiftId.present
          ? data.checkoutShiftId.value
          : this.checkoutShiftId,
      userId: data.userId.present ? data.userId.value : this.userId,
      ticketNumber: data.ticketNumber.present
          ? data.ticketNumber.value
          : this.ticketNumber,
      plateNumber:
          data.plateNumber.present ? data.plateNumber.value : this.plateNumber,
      vehicleBrand: data.vehicleBrand.present
          ? data.vehicleBrand.value
          : this.vehicleBrand,
      vehicleModel: data.vehicleModel.present
          ? data.vehicleModel.value
          : this.vehicleModel,
      vehicleYear:
          data.vehicleYear.present ? data.vehicleYear.value : this.vehicleYear,
      vehicleColor: data.vehicleColor.present
          ? data.vehicleColor.value
          : this.vehicleColor,
      vehicleType:
          data.vehicleType.present ? data.vehicleType.value : this.vehicleType,
      slot: data.slot.present ? data.slot.value : this.slot,
      parkingLevel: data.parkingLevel.present
          ? data.parkingLevel.value
          : this.parkingLevel,
      parkingSlot:
          data.parkingSlot.present ? data.parkingSlot.value : this.parkingSlot,
      belongingsJson: data.belongingsJson.present
          ? data.belongingsJson.value
          : this.belongingsJson,
      otherBelongings: data.otherBelongings.present
          ? data.otherBelongings.value
          : this.otherBelongings,
      signaturePng: data.signaturePng.present
          ? data.signaturePng.value
          : this.signaturePng,
      signatureCapturedAt: data.signatureCapturedAt.present
          ? data.signatureCapturedAt.value
          : this.signatureCapturedAt,
      customerFullName: data.customerFullName.present
          ? data.customerFullName.value
          : this.customerFullName,
      customerMobile: data.customerMobile.present
          ? data.customerMobile.value
          : this.customerMobile,
      assignedValetDriver: data.assignedValetDriver.present
          ? data.assignedValetDriver.value
          : this.assignedValetDriver,
      specialInstructions: data.specialInstructions.present
          ? data.specialInstructions.value
          : this.specialInstructions,
      valetServiceType: data.valetServiceType.present
          ? data.valetServiceType.value
          : this.valetServiceType,
      vehicleDamageJson: data.vehicleDamageJson.present
          ? data.vehicleDamageJson.value
          : this.vehicleDamageJson,
      branchSnapshot: data.branchSnapshot.present
          ? data.branchSnapshot.value
          : this.branchSnapshot,
      areaSnapshot: data.areaSnapshot.present
          ? data.areaSnapshot.value
          : this.areaSnapshot,
      deviceIdSnapshot: data.deviceIdSnapshot.present
          ? data.deviceIdSnapshot.value
          : this.deviceIdSnapshot,
      serverTicketId: data.serverTicketId.present
          ? data.serverTicketId.value
          : this.serverTicketId,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
      localCreatedAt: data.localCreatedAt.present
          ? data.localCreatedAt.value
          : this.localCreatedAt,
      timeIn: data.timeIn.present ? data.timeIn.value : this.timeIn,
      timeOut: data.timeOut.present ? data.timeOut.value : this.timeOut,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      flatRate: data.flatRate.present ? data.flatRate.value : this.flatRate,
      succeedingFee: data.succeedingFee.present
          ? data.succeedingFee.value
          : this.succeedingFee,
      overnightFee: data.overnightFee.present
          ? data.overnightFee.value
          : this.overnightFee,
      lostTicketFee: data.lostTicketFee.present
          ? data.lostTicketFee.value
          : this.lostTicketFee,
      totalFee: data.totalFee.present ? data.totalFee.value : this.totalFee,
      amountTendered: data.amountTendered.present
          ? data.amountTendered.value
          : this.amountTendered,
      changeAmount: data.changeAmount.present
          ? data.changeAmount.value
          : this.changeAmount,
      status: data.status.present ? data.status.value : this.status,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ValetTransaction(')
          ..write('id: $id, ')
          ..write('localUuid: $localUuid, ')
          ..write('checkinShiftId: $checkinShiftId, ')
          ..write('checkoutShiftId: $checkoutShiftId, ')
          ..write('userId: $userId, ')
          ..write('ticketNumber: $ticketNumber, ')
          ..write('plateNumber: $plateNumber, ')
          ..write('vehicleBrand: $vehicleBrand, ')
          ..write('vehicleModel: $vehicleModel, ')
          ..write('vehicleYear: $vehicleYear, ')
          ..write('vehicleColor: $vehicleColor, ')
          ..write('vehicleType: $vehicleType, ')
          ..write('slot: $slot, ')
          ..write('parkingLevel: $parkingLevel, ')
          ..write('parkingSlot: $parkingSlot, ')
          ..write('belongingsJson: $belongingsJson, ')
          ..write('otherBelongings: $otherBelongings, ')
          ..write('signaturePng: $signaturePng, ')
          ..write('signatureCapturedAt: $signatureCapturedAt, ')
          ..write('customerFullName: $customerFullName, ')
          ..write('customerMobile: $customerMobile, ')
          ..write('assignedValetDriver: $assignedValetDriver, ')
          ..write('specialInstructions: $specialInstructions, ')
          ..write('valetServiceType: $valetServiceType, ')
          ..write('vehicleDamageJson: $vehicleDamageJson, ')
          ..write('branchSnapshot: $branchSnapshot, ')
          ..write('areaSnapshot: $areaSnapshot, ')
          ..write('deviceIdSnapshot: $deviceIdSnapshot, ')
          ..write('serverTicketId: $serverTicketId, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('localCreatedAt: $localCreatedAt, ')
          ..write('timeIn: $timeIn, ')
          ..write('timeOut: $timeOut, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('flatRate: $flatRate, ')
          ..write('succeedingFee: $succeedingFee, ')
          ..write('overnightFee: $overnightFee, ')
          ..write('lostTicketFee: $lostTicketFee, ')
          ..write('totalFee: $totalFee, ')
          ..write('amountTendered: $amountTendered, ')
          ..write('changeAmount: $changeAmount, ')
          ..write('status: $status, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        localUuid,
        checkinShiftId,
        checkoutShiftId,
        userId,
        ticketNumber,
        plateNumber,
        vehicleBrand,
        vehicleModel,
        vehicleYear,
        vehicleColor,
        vehicleType,
        slot,
        parkingLevel,
        parkingSlot,
        belongingsJson,
        otherBelongings,
        signaturePng,
        signatureCapturedAt,
        customerFullName,
        customerMobile,
        assignedValetDriver,
        specialInstructions,
        valetServiceType,
        vehicleDamageJson,
        branchSnapshot,
        areaSnapshot,
        deviceIdSnapshot,
        serverTicketId,
        lastModifiedAt,
        localCreatedAt,
        timeIn,
        timeOut,
        durationMinutes,
        flatRate,
        succeedingFee,
        overnightFee,
        lostTicketFee,
        totalFee,
        amountTendered,
        changeAmount,
        status,
        syncedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ValetTransaction &&
          other.id == this.id &&
          other.localUuid == this.localUuid &&
          other.checkinShiftId == this.checkinShiftId &&
          other.checkoutShiftId == this.checkoutShiftId &&
          other.userId == this.userId &&
          other.ticketNumber == this.ticketNumber &&
          other.plateNumber == this.plateNumber &&
          other.vehicleBrand == this.vehicleBrand &&
          other.vehicleModel == this.vehicleModel &&
          other.vehicleYear == this.vehicleYear &&
          other.vehicleColor == this.vehicleColor &&
          other.vehicleType == this.vehicleType &&
          other.slot == this.slot &&
          other.parkingLevel == this.parkingLevel &&
          other.parkingSlot == this.parkingSlot &&
          other.belongingsJson == this.belongingsJson &&
          other.otherBelongings == this.otherBelongings &&
          other.signaturePng == this.signaturePng &&
          other.signatureCapturedAt == this.signatureCapturedAt &&
          other.customerFullName == this.customerFullName &&
          other.customerMobile == this.customerMobile &&
          other.assignedValetDriver == this.assignedValetDriver &&
          other.specialInstructions == this.specialInstructions &&
          other.valetServiceType == this.valetServiceType &&
          other.vehicleDamageJson == this.vehicleDamageJson &&
          other.branchSnapshot == this.branchSnapshot &&
          other.areaSnapshot == this.areaSnapshot &&
          other.deviceIdSnapshot == this.deviceIdSnapshot &&
          other.serverTicketId == this.serverTicketId &&
          other.lastModifiedAt == this.lastModifiedAt &&
          other.localCreatedAt == this.localCreatedAt &&
          other.timeIn == this.timeIn &&
          other.timeOut == this.timeOut &&
          other.durationMinutes == this.durationMinutes &&
          other.flatRate == this.flatRate &&
          other.succeedingFee == this.succeedingFee &&
          other.overnightFee == this.overnightFee &&
          other.lostTicketFee == this.lostTicketFee &&
          other.totalFee == this.totalFee &&
          other.amountTendered == this.amountTendered &&
          other.changeAmount == this.changeAmount &&
          other.status == this.status &&
          other.syncedAt == this.syncedAt);
}

class ValetTransactionsCompanion extends UpdateCompanion<ValetTransaction> {
  final Value<int> id;
  final Value<String?> localUuid;
  final Value<int> checkinShiftId;
  final Value<int?> checkoutShiftId;
  final Value<int> userId;
  final Value<String> ticketNumber;
  final Value<String> plateNumber;
  final Value<String?> vehicleBrand;
  final Value<String?> vehicleModel;
  final Value<String?> vehicleYear;
  final Value<String?> vehicleColor;
  final Value<String?> vehicleType;
  final Value<String?> slot;
  final Value<String?> parkingLevel;
  final Value<String?> parkingSlot;
  final Value<String?> belongingsJson;
  final Value<String?> otherBelongings;
  final Value<String?> signaturePng;
  final Value<int?> signatureCapturedAt;
  final Value<String?> customerFullName;
  final Value<String?> customerMobile;
  final Value<String?> assignedValetDriver;
  final Value<String?> specialInstructions;
  final Value<String?> valetServiceType;
  final Value<String?> vehicleDamageJson;
  final Value<String?> branchSnapshot;
  final Value<String?> areaSnapshot;
  final Value<String?> deviceIdSnapshot;
  final Value<String?> serverTicketId;
  final Value<int?> lastModifiedAt;
  final Value<int?> localCreatedAt;
  final Value<int> timeIn;
  final Value<int?> timeOut;
  final Value<int?> durationMinutes;
  final Value<double?> flatRate;
  final Value<double?> succeedingFee;
  final Value<double?> overnightFee;
  final Value<double?> lostTicketFee;
  final Value<double?> totalFee;
  final Value<double?> amountTendered;
  final Value<double?> changeAmount;
  final Value<String> status;
  final Value<int?> syncedAt;
  const ValetTransactionsCompanion({
    this.id = const Value.absent(),
    this.localUuid = const Value.absent(),
    this.checkinShiftId = const Value.absent(),
    this.checkoutShiftId = const Value.absent(),
    this.userId = const Value.absent(),
    this.ticketNumber = const Value.absent(),
    this.plateNumber = const Value.absent(),
    this.vehicleBrand = const Value.absent(),
    this.vehicleModel = const Value.absent(),
    this.vehicleYear = const Value.absent(),
    this.vehicleColor = const Value.absent(),
    this.vehicleType = const Value.absent(),
    this.slot = const Value.absent(),
    this.parkingLevel = const Value.absent(),
    this.parkingSlot = const Value.absent(),
    this.belongingsJson = const Value.absent(),
    this.otherBelongings = const Value.absent(),
    this.signaturePng = const Value.absent(),
    this.signatureCapturedAt = const Value.absent(),
    this.customerFullName = const Value.absent(),
    this.customerMobile = const Value.absent(),
    this.assignedValetDriver = const Value.absent(),
    this.specialInstructions = const Value.absent(),
    this.valetServiceType = const Value.absent(),
    this.vehicleDamageJson = const Value.absent(),
    this.branchSnapshot = const Value.absent(),
    this.areaSnapshot = const Value.absent(),
    this.deviceIdSnapshot = const Value.absent(),
    this.serverTicketId = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.localCreatedAt = const Value.absent(),
    this.timeIn = const Value.absent(),
    this.timeOut = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.flatRate = const Value.absent(),
    this.succeedingFee = const Value.absent(),
    this.overnightFee = const Value.absent(),
    this.lostTicketFee = const Value.absent(),
    this.totalFee = const Value.absent(),
    this.amountTendered = const Value.absent(),
    this.changeAmount = const Value.absent(),
    this.status = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  ValetTransactionsCompanion.insert({
    this.id = const Value.absent(),
    this.localUuid = const Value.absent(),
    required int checkinShiftId,
    this.checkoutShiftId = const Value.absent(),
    required int userId,
    required String ticketNumber,
    required String plateNumber,
    this.vehicleBrand = const Value.absent(),
    this.vehicleModel = const Value.absent(),
    this.vehicleYear = const Value.absent(),
    this.vehicleColor = const Value.absent(),
    this.vehicleType = const Value.absent(),
    this.slot = const Value.absent(),
    this.parkingLevel = const Value.absent(),
    this.parkingSlot = const Value.absent(),
    this.belongingsJson = const Value.absent(),
    this.otherBelongings = const Value.absent(),
    this.signaturePng = const Value.absent(),
    this.signatureCapturedAt = const Value.absent(),
    this.customerFullName = const Value.absent(),
    this.customerMobile = const Value.absent(),
    this.assignedValetDriver = const Value.absent(),
    this.specialInstructions = const Value.absent(),
    this.valetServiceType = const Value.absent(),
    this.vehicleDamageJson = const Value.absent(),
    this.branchSnapshot = const Value.absent(),
    this.areaSnapshot = const Value.absent(),
    this.deviceIdSnapshot = const Value.absent(),
    this.serverTicketId = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.localCreatedAt = const Value.absent(),
    required int timeIn,
    this.timeOut = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.flatRate = const Value.absent(),
    this.succeedingFee = const Value.absent(),
    this.overnightFee = const Value.absent(),
    this.lostTicketFee = const Value.absent(),
    this.totalFee = const Value.absent(),
    this.amountTendered = const Value.absent(),
    this.changeAmount = const Value.absent(),
    this.status = const Value.absent(),
    this.syncedAt = const Value.absent(),
  })  : checkinShiftId = Value(checkinShiftId),
        userId = Value(userId),
        ticketNumber = Value(ticketNumber),
        plateNumber = Value(plateNumber),
        timeIn = Value(timeIn);
  static Insertable<ValetTransaction> custom({
    Expression<int>? id,
    Expression<String>? localUuid,
    Expression<int>? checkinShiftId,
    Expression<int>? checkoutShiftId,
    Expression<int>? userId,
    Expression<String>? ticketNumber,
    Expression<String>? plateNumber,
    Expression<String>? vehicleBrand,
    Expression<String>? vehicleModel,
    Expression<String>? vehicleYear,
    Expression<String>? vehicleColor,
    Expression<String>? vehicleType,
    Expression<String>? slot,
    Expression<String>? parkingLevel,
    Expression<String>? parkingSlot,
    Expression<String>? belongingsJson,
    Expression<String>? otherBelongings,
    Expression<String>? signaturePng,
    Expression<int>? signatureCapturedAt,
    Expression<String>? customerFullName,
    Expression<String>? customerMobile,
    Expression<String>? assignedValetDriver,
    Expression<String>? specialInstructions,
    Expression<String>? valetServiceType,
    Expression<String>? vehicleDamageJson,
    Expression<String>? branchSnapshot,
    Expression<String>? areaSnapshot,
    Expression<String>? deviceIdSnapshot,
    Expression<String>? serverTicketId,
    Expression<int>? lastModifiedAt,
    Expression<int>? localCreatedAt,
    Expression<int>? timeIn,
    Expression<int>? timeOut,
    Expression<int>? durationMinutes,
    Expression<double>? flatRate,
    Expression<double>? succeedingFee,
    Expression<double>? overnightFee,
    Expression<double>? lostTicketFee,
    Expression<double>? totalFee,
    Expression<double>? amountTendered,
    Expression<double>? changeAmount,
    Expression<String>? status,
    Expression<int>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localUuid != null) 'local_uuid': localUuid,
      if (checkinShiftId != null) 'checkin_shift_id': checkinShiftId,
      if (checkoutShiftId != null) 'checkout_shift_id': checkoutShiftId,
      if (userId != null) 'user_id': userId,
      if (ticketNumber != null) 'ticket_number': ticketNumber,
      if (plateNumber != null) 'plate_number': plateNumber,
      if (vehicleBrand != null) 'vehicle_brand': vehicleBrand,
      if (vehicleModel != null) 'vehicle_model': vehicleModel,
      if (vehicleYear != null) 'vehicle_year': vehicleYear,
      if (vehicleColor != null) 'vehicle_color': vehicleColor,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (slot != null) 'slot': slot,
      if (parkingLevel != null) 'parking_level': parkingLevel,
      if (parkingSlot != null) 'parking_slot': parkingSlot,
      if (belongingsJson != null) 'belongings_json': belongingsJson,
      if (otherBelongings != null) 'other_belongings': otherBelongings,
      if (signaturePng != null) 'signature_png': signaturePng,
      if (signatureCapturedAt != null)
        'signature_captured_at': signatureCapturedAt,
      if (customerFullName != null) 'customer_full_name': customerFullName,
      if (customerMobile != null) 'customer_mobile': customerMobile,
      if (assignedValetDriver != null)
        'assigned_valet_driver': assignedValetDriver,
      if (specialInstructions != null)
        'special_instructions': specialInstructions,
      if (valetServiceType != null) 'valet_service_type': valetServiceType,
      if (vehicleDamageJson != null) 'vehicle_damage_json': vehicleDamageJson,
      if (branchSnapshot != null) 'branch_snapshot': branchSnapshot,
      if (areaSnapshot != null) 'area_snapshot': areaSnapshot,
      if (deviceIdSnapshot != null) 'device_id_snapshot': deviceIdSnapshot,
      if (serverTicketId != null) 'server_ticket_id': serverTicketId,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (localCreatedAt != null) 'local_created_at': localCreatedAt,
      if (timeIn != null) 'time_in': timeIn,
      if (timeOut != null) 'time_out': timeOut,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (flatRate != null) 'flat_rate': flatRate,
      if (succeedingFee != null) 'succeeding_fee': succeedingFee,
      if (overnightFee != null) 'overnight_fee': overnightFee,
      if (lostTicketFee != null) 'lost_ticket_fee': lostTicketFee,
      if (totalFee != null) 'total_fee': totalFee,
      if (amountTendered != null) 'amount_tendered': amountTendered,
      if (changeAmount != null) 'change_amount': changeAmount,
      if (status != null) 'status': status,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  ValetTransactionsCompanion copyWith(
      {Value<int>? id,
      Value<String?>? localUuid,
      Value<int>? checkinShiftId,
      Value<int?>? checkoutShiftId,
      Value<int>? userId,
      Value<String>? ticketNumber,
      Value<String>? plateNumber,
      Value<String?>? vehicleBrand,
      Value<String?>? vehicleModel,
      Value<String?>? vehicleYear,
      Value<String?>? vehicleColor,
      Value<String?>? vehicleType,
      Value<String?>? slot,
      Value<String?>? parkingLevel,
      Value<String?>? parkingSlot,
      Value<String?>? belongingsJson,
      Value<String?>? otherBelongings,
      Value<String?>? signaturePng,
      Value<int?>? signatureCapturedAt,
      Value<String?>? customerFullName,
      Value<String?>? customerMobile,
      Value<String?>? assignedValetDriver,
      Value<String?>? specialInstructions,
      Value<String?>? valetServiceType,
      Value<String?>? vehicleDamageJson,
      Value<String?>? branchSnapshot,
      Value<String?>? areaSnapshot,
      Value<String?>? deviceIdSnapshot,
      Value<String?>? serverTicketId,
      Value<int?>? lastModifiedAt,
      Value<int?>? localCreatedAt,
      Value<int>? timeIn,
      Value<int?>? timeOut,
      Value<int?>? durationMinutes,
      Value<double?>? flatRate,
      Value<double?>? succeedingFee,
      Value<double?>? overnightFee,
      Value<double?>? lostTicketFee,
      Value<double?>? totalFee,
      Value<double?>? amountTendered,
      Value<double?>? changeAmount,
      Value<String>? status,
      Value<int?>? syncedAt}) {
    return ValetTransactionsCompanion(
      id: id ?? this.id,
      localUuid: localUuid ?? this.localUuid,
      checkinShiftId: checkinShiftId ?? this.checkinShiftId,
      checkoutShiftId: checkoutShiftId ?? this.checkoutShiftId,
      userId: userId ?? this.userId,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleType: vehicleType ?? this.vehicleType,
      slot: slot ?? this.slot,
      parkingLevel: parkingLevel ?? this.parkingLevel,
      parkingSlot: parkingSlot ?? this.parkingSlot,
      belongingsJson: belongingsJson ?? this.belongingsJson,
      otherBelongings: otherBelongings ?? this.otherBelongings,
      signaturePng: signaturePng ?? this.signaturePng,
      signatureCapturedAt: signatureCapturedAt ?? this.signatureCapturedAt,
      customerFullName: customerFullName ?? this.customerFullName,
      customerMobile: customerMobile ?? this.customerMobile,
      assignedValetDriver: assignedValetDriver ?? this.assignedValetDriver,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      valetServiceType: valetServiceType ?? this.valetServiceType,
      vehicleDamageJson: vehicleDamageJson ?? this.vehicleDamageJson,
      branchSnapshot: branchSnapshot ?? this.branchSnapshot,
      areaSnapshot: areaSnapshot ?? this.areaSnapshot,
      deviceIdSnapshot: deviceIdSnapshot ?? this.deviceIdSnapshot,
      serverTicketId: serverTicketId ?? this.serverTicketId,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      localCreatedAt: localCreatedAt ?? this.localCreatedAt,
      timeIn: timeIn ?? this.timeIn,
      timeOut: timeOut ?? this.timeOut,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      flatRate: flatRate ?? this.flatRate,
      succeedingFee: succeedingFee ?? this.succeedingFee,
      overnightFee: overnightFee ?? this.overnightFee,
      lostTicketFee: lostTicketFee ?? this.lostTicketFee,
      totalFee: totalFee ?? this.totalFee,
      amountTendered: amountTendered ?? this.amountTendered,
      changeAmount: changeAmount ?? this.changeAmount,
      status: status ?? this.status,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localUuid.present) {
      map['local_uuid'] = Variable<String>(localUuid.value);
    }
    if (checkinShiftId.present) {
      map['checkin_shift_id'] = Variable<int>(checkinShiftId.value);
    }
    if (checkoutShiftId.present) {
      map['checkout_shift_id'] = Variable<int>(checkoutShiftId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (ticketNumber.present) {
      map['ticket_number'] = Variable<String>(ticketNumber.value);
    }
    if (plateNumber.present) {
      map['plate_number'] = Variable<String>(plateNumber.value);
    }
    if (vehicleBrand.present) {
      map['vehicle_brand'] = Variable<String>(vehicleBrand.value);
    }
    if (vehicleModel.present) {
      map['vehicle_model'] = Variable<String>(vehicleModel.value);
    }
    if (vehicleYear.present) {
      map['vehicle_year'] = Variable<String>(vehicleYear.value);
    }
    if (vehicleColor.present) {
      map['vehicle_color'] = Variable<String>(vehicleColor.value);
    }
    if (vehicleType.present) {
      map['vehicle_type'] = Variable<String>(vehicleType.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (parkingLevel.present) {
      map['parking_level'] = Variable<String>(parkingLevel.value);
    }
    if (parkingSlot.present) {
      map['parking_slot'] = Variable<String>(parkingSlot.value);
    }
    if (belongingsJson.present) {
      map['belongings_json'] = Variable<String>(belongingsJson.value);
    }
    if (otherBelongings.present) {
      map['other_belongings'] = Variable<String>(otherBelongings.value);
    }
    if (signaturePng.present) {
      map['signature_png'] = Variable<String>(signaturePng.value);
    }
    if (signatureCapturedAt.present) {
      map['signature_captured_at'] = Variable<int>(signatureCapturedAt.value);
    }
    if (customerFullName.present) {
      map['customer_full_name'] = Variable<String>(customerFullName.value);
    }
    if (customerMobile.present) {
      map['customer_mobile'] = Variable<String>(customerMobile.value);
    }
    if (assignedValetDriver.present) {
      map['assigned_valet_driver'] =
          Variable<String>(assignedValetDriver.value);
    }
    if (specialInstructions.present) {
      map['special_instructions'] = Variable<String>(specialInstructions.value);
    }
    if (valetServiceType.present) {
      map['valet_service_type'] = Variable<String>(valetServiceType.value);
    }
    if (vehicleDamageJson.present) {
      map['vehicle_damage_json'] = Variable<String>(vehicleDamageJson.value);
    }
    if (branchSnapshot.present) {
      map['branch_snapshot'] = Variable<String>(branchSnapshot.value);
    }
    if (areaSnapshot.present) {
      map['area_snapshot'] = Variable<String>(areaSnapshot.value);
    }
    if (deviceIdSnapshot.present) {
      map['device_id_snapshot'] = Variable<String>(deviceIdSnapshot.value);
    }
    if (serverTicketId.present) {
      map['server_ticket_id'] = Variable<String>(serverTicketId.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<int>(lastModifiedAt.value);
    }
    if (localCreatedAt.present) {
      map['local_created_at'] = Variable<int>(localCreatedAt.value);
    }
    if (timeIn.present) {
      map['time_in'] = Variable<int>(timeIn.value);
    }
    if (timeOut.present) {
      map['time_out'] = Variable<int>(timeOut.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (flatRate.present) {
      map['flat_rate'] = Variable<double>(flatRate.value);
    }
    if (succeedingFee.present) {
      map['succeeding_fee'] = Variable<double>(succeedingFee.value);
    }
    if (overnightFee.present) {
      map['overnight_fee'] = Variable<double>(overnightFee.value);
    }
    if (lostTicketFee.present) {
      map['lost_ticket_fee'] = Variable<double>(lostTicketFee.value);
    }
    if (totalFee.present) {
      map['total_fee'] = Variable<double>(totalFee.value);
    }
    if (amountTendered.present) {
      map['amount_tendered'] = Variable<double>(amountTendered.value);
    }
    if (changeAmount.present) {
      map['change_amount'] = Variable<double>(changeAmount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ValetTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('localUuid: $localUuid, ')
          ..write('checkinShiftId: $checkinShiftId, ')
          ..write('checkoutShiftId: $checkoutShiftId, ')
          ..write('userId: $userId, ')
          ..write('ticketNumber: $ticketNumber, ')
          ..write('plateNumber: $plateNumber, ')
          ..write('vehicleBrand: $vehicleBrand, ')
          ..write('vehicleModel: $vehicleModel, ')
          ..write('vehicleYear: $vehicleYear, ')
          ..write('vehicleColor: $vehicleColor, ')
          ..write('vehicleType: $vehicleType, ')
          ..write('slot: $slot, ')
          ..write('parkingLevel: $parkingLevel, ')
          ..write('parkingSlot: $parkingSlot, ')
          ..write('belongingsJson: $belongingsJson, ')
          ..write('otherBelongings: $otherBelongings, ')
          ..write('signaturePng: $signaturePng, ')
          ..write('signatureCapturedAt: $signatureCapturedAt, ')
          ..write('customerFullName: $customerFullName, ')
          ..write('customerMobile: $customerMobile, ')
          ..write('assignedValetDriver: $assignedValetDriver, ')
          ..write('specialInstructions: $specialInstructions, ')
          ..write('valetServiceType: $valetServiceType, ')
          ..write('vehicleDamageJson: $vehicleDamageJson, ')
          ..write('branchSnapshot: $branchSnapshot, ')
          ..write('areaSnapshot: $areaSnapshot, ')
          ..write('deviceIdSnapshot: $deviceIdSnapshot, ')
          ..write('serverTicketId: $serverTicketId, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('localCreatedAt: $localCreatedAt, ')
          ..write('timeIn: $timeIn, ')
          ..write('timeOut: $timeOut, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('flatRate: $flatRate, ')
          ..write('succeedingFee: $succeedingFee, ')
          ..write('overnightFee: $overnightFee, ')
          ..write('lostTicketFee: $lostTicketFee, ')
          ..write('totalFee: $totalFee, ')
          ..write('amountTendered: $amountTendered, ')
          ..write('changeAmount: $changeAmount, ')
          ..write('status: $status, ')
          ..write('syncedAt: $syncedAt')
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
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, type, entityId, payload, createdAt, syncedAt, retryCount, lastError];
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
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
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
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entity_id'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}synced_at']),
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String type;
  final int entityId;
  final String payload;
  final int createdAt;
  final int? syncedAt;
  final int retryCount;
  final String? lastError;
  const SyncQueueData(
      {required this.id,
      required this.type,
      required this.entityId,
      required this.payload,
      required this.createdAt,
      this.syncedAt,
      required this.retryCount,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['entity_id'] = Variable<int>(entityId);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<int>(syncedAt);
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      type: Value(type),
      entityId: Value(entityId),
      payload: Value(payload),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      entityId: serializer.fromJson<int>(json['entityId']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      syncedAt: serializer.fromJson<int?>(json['syncedAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'entityId': serializer.toJson<int>(entityId),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<int>(createdAt),
      'syncedAt': serializer.toJson<int?>(syncedAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueData copyWith(
          {int? id,
          String? type,
          int? entityId,
          String? payload,
          int? createdAt,
          Value<int?> syncedAt = const Value.absent(),
          int? retryCount,
          Value<String?> lastError = const Value.absent()}) =>
      SyncQueueData(
        id: id ?? this.id,
        type: type ?? this.type,
        entityId: entityId ?? this.entityId,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        retryCount: retryCount ?? this.retryCount,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, type, entityId, payload, createdAt, syncedAt, retryCount, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.type == this.type &&
          other.entityId == this.entityId &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> type;
  final Value<int> entityId;
  final Value<String> payload;
  final Value<int> createdAt;
  final Value<int?> syncedAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required int entityId,
    required String payload,
    required int createdAt,
    this.syncedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
  })  : type = Value(type),
        entityId = Value(entityId),
        payload = Value(payload),
        createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<int>? entityId,
    Expression<String>? payload,
    Expression<int>? createdAt,
    Expression<int>? syncedAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (entityId != null) 'entity_id': entityId,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? type,
      Value<int>? entityId,
      Value<String>? payload,
      Value<int>? createdAt,
      Value<int?>? syncedAt,
      Value<int>? retryCount,
      Value<String?>? lastError}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DeviceInfoTable deviceInfo = $DeviceInfoTable(this);
  late final $OfflineAccountsTable offlineAccounts =
      $OfflineAccountsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $ShiftsTable shifts = $ShiftsTable(this);
  late final $ShiftOpeningDenominationsTable shiftOpeningDenominations =
      $ShiftOpeningDenominationsTable(this);
  late final $ShiftClosingDenominationsTable shiftClosingDenominations =
      $ShiftClosingDenominationsTable(this);
  late final $ValetTransactionsTable valetTransactions =
      $ValetTransactionsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        deviceInfo,
        offlineAccounts,
        sessions,
        shifts,
        shiftOpeningDenominations,
        shiftClosingDenominations,
        valetTransactions,
        syncQueue
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

typedef $$OfflineAccountsTableCreateCompanionBuilder = OfflineAccountsCompanion
    Function({
  Value<int> id,
  required int serverUserId,
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
  Value<int> serverUserId,
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
            Value<int> serverUserId = const Value.absent(),
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
            required int serverUserId,
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

  ColumnFilters<int> get serverUserId => $state.composableBuilder(
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

  ComposableFilter shiftsRefs(
      ComposableFilter Function($$ShiftsTableFilterComposer f) f) {
    final $$ShiftsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.shifts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder, parentComposers) => $$ShiftsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.shifts, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter valetTransactionsRefs(
      ComposableFilter Function($$ValetTransactionsTableFilterComposer f) f) {
    final $$ValetTransactionsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.valetTransactions,
            getReferencedColumn: (t) => t.userId,
            builder: (joinBuilder, parentComposers) =>
                $$ValetTransactionsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.valetTransactions,
                    joinBuilder,
                    parentComposers)));
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

  ColumnOrderings<int> get serverUserId => $state.composableBuilder(
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

  ComposableFilter shiftsRefs(
      ComposableFilter Function($$ShiftsTableFilterComposer f) f) {
    final $$ShiftsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.shifts,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder, parentComposers) => $$ShiftsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.shifts, joinBuilder, parentComposers)));
    return f(composer);
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
  Value<int> id,
  required int sessionId,
  required int userId,
  required String branch,
  required String area,
  required String shiftDate,
  Value<bool> isOpen,
  Value<double> openingFloat,
  Value<String?> openingNotes,
  Value<double?> closingFloat,
  Value<String?> closingNotes,
  Value<double> totalSales,
  Value<double?> expectedCash,
  Value<double?> variance,
  Value<double?> remittance,
  Value<int> transactionsCount,
  required int openedAt,
  Value<int?> closedAt,
  Value<int?> syncedAt,
});
typedef $$ShiftsTableUpdateCompanionBuilder = ShiftsCompanion Function({
  Value<int> id,
  Value<int> sessionId,
  Value<int> userId,
  Value<String> branch,
  Value<String> area,
  Value<String> shiftDate,
  Value<bool> isOpen,
  Value<double> openingFloat,
  Value<String?> openingNotes,
  Value<double?> closingFloat,
  Value<String?> closingNotes,
  Value<double> totalSales,
  Value<double?> expectedCash,
  Value<double?> variance,
  Value<double?> remittance,
  Value<int> transactionsCount,
  Value<int> openedAt,
  Value<int?> closedAt,
  Value<int?> syncedAt,
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
            Value<int> id = const Value.absent(),
            Value<int> sessionId = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> branch = const Value.absent(),
            Value<String> area = const Value.absent(),
            Value<String> shiftDate = const Value.absent(),
            Value<bool> isOpen = const Value.absent(),
            Value<double> openingFloat = const Value.absent(),
            Value<String?> openingNotes = const Value.absent(),
            Value<double?> closingFloat = const Value.absent(),
            Value<String?> closingNotes = const Value.absent(),
            Value<double> totalSales = const Value.absent(),
            Value<double?> expectedCash = const Value.absent(),
            Value<double?> variance = const Value.absent(),
            Value<double?> remittance = const Value.absent(),
            Value<int> transactionsCount = const Value.absent(),
            Value<int> openedAt = const Value.absent(),
            Value<int?> closedAt = const Value.absent(),
            Value<int?> syncedAt = const Value.absent(),
          }) =>
              ShiftsCompanion(
            id: id,
            sessionId: sessionId,
            userId: userId,
            branch: branch,
            area: area,
            shiftDate: shiftDate,
            isOpen: isOpen,
            openingFloat: openingFloat,
            openingNotes: openingNotes,
            closingFloat: closingFloat,
            closingNotes: closingNotes,
            totalSales: totalSales,
            expectedCash: expectedCash,
            variance: variance,
            remittance: remittance,
            transactionsCount: transactionsCount,
            openedAt: openedAt,
            closedAt: closedAt,
            syncedAt: syncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int sessionId,
            required int userId,
            required String branch,
            required String area,
            required String shiftDate,
            Value<bool> isOpen = const Value.absent(),
            Value<double> openingFloat = const Value.absent(),
            Value<String?> openingNotes = const Value.absent(),
            Value<double?> closingFloat = const Value.absent(),
            Value<String?> closingNotes = const Value.absent(),
            Value<double> totalSales = const Value.absent(),
            Value<double?> expectedCash = const Value.absent(),
            Value<double?> variance = const Value.absent(),
            Value<double?> remittance = const Value.absent(),
            Value<int> transactionsCount = const Value.absent(),
            required int openedAt,
            Value<int?> closedAt = const Value.absent(),
            Value<int?> syncedAt = const Value.absent(),
          }) =>
              ShiftsCompanion.insert(
            id: id,
            sessionId: sessionId,
            userId: userId,
            branch: branch,
            area: area,
            shiftDate: shiftDate,
            isOpen: isOpen,
            openingFloat: openingFloat,
            openingNotes: openingNotes,
            closingFloat: closingFloat,
            closingNotes: closingNotes,
            totalSales: totalSales,
            expectedCash: expectedCash,
            variance: variance,
            remittance: remittance,
            transactionsCount: transactionsCount,
            openedAt: openedAt,
            closedAt: closedAt,
            syncedAt: syncedAt,
          ),
        ));
}

class $$ShiftsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
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

  ColumnFilters<String> get shiftDate => $state.composableBuilder(
      column: $state.table.shiftDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isOpen => $state.composableBuilder(
      column: $state.table.isOpen,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get openingFloat => $state.composableBuilder(
      column: $state.table.openingFloat,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get openingNotes => $state.composableBuilder(
      column: $state.table.openingNotes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get closingFloat => $state.composableBuilder(
      column: $state.table.closingFloat,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get closingNotes => $state.composableBuilder(
      column: $state.table.closingNotes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get totalSales => $state.composableBuilder(
      column: $state.table.totalSales,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get expectedCash => $state.composableBuilder(
      column: $state.table.expectedCash,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get variance => $state.composableBuilder(
      column: $state.table.variance,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get remittance => $state.composableBuilder(
      column: $state.table.remittance,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get transactionsCount => $state.composableBuilder(
      column: $state.table.transactionsCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get openedAt => $state.composableBuilder(
      column: $state.table.openedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get closedAt => $state.composableBuilder(
      column: $state.table.closedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $state.db.sessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$SessionsTableFilterComposer(ComposerState(
                $state.db, $state.db.sessions, joinBuilder, parentComposers)));
    return composer;
  }

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

  ComposableFilter shiftOpeningDenominationsRefs(
      ComposableFilter Function(
              $$ShiftOpeningDenominationsTableFilterComposer f)
          f) {
    final $$ShiftOpeningDenominationsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.shiftOpeningDenominations,
            getReferencedColumn: (t) => t.shiftId,
            builder: (joinBuilder, parentComposers) =>
                $$ShiftOpeningDenominationsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.shiftOpeningDenominations,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter shiftClosingDenominationsRefs(
      ComposableFilter Function(
              $$ShiftClosingDenominationsTableFilterComposer f)
          f) {
    final $$ShiftClosingDenominationsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.shiftClosingDenominations,
            getReferencedColumn: (t) => t.shiftId,
            builder: (joinBuilder, parentComposers) =>
                $$ShiftClosingDenominationsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.shiftClosingDenominations,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter valet_tx_checkin_shift_ref(
      ComposableFilter Function($$ValetTransactionsTableFilterComposer f) f) {
    final $$ValetTransactionsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.valetTransactions,
            getReferencedColumn: (t) => t.checkinShiftId,
            builder: (joinBuilder, parentComposers) =>
                $$ValetTransactionsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.valetTransactions,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter valet_tx_checkout_shift_ref(
      ComposableFilter Function($$ValetTransactionsTableFilterComposer f) f) {
    final $$ValetTransactionsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.valetTransactions,
            getReferencedColumn: (t) => t.checkoutShiftId,
            builder: (joinBuilder, parentComposers) =>
                $$ValetTransactionsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.valetTransactions,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }
}

class $$ShiftsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
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

  ColumnOrderings<String> get shiftDate => $state.composableBuilder(
      column: $state.table.shiftDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isOpen => $state.composableBuilder(
      column: $state.table.isOpen,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get openingFloat => $state.composableBuilder(
      column: $state.table.openingFloat,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get openingNotes => $state.composableBuilder(
      column: $state.table.openingNotes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get closingFloat => $state.composableBuilder(
      column: $state.table.closingFloat,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get closingNotes => $state.composableBuilder(
      column: $state.table.closingNotes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get totalSales => $state.composableBuilder(
      column: $state.table.totalSales,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get expectedCash => $state.composableBuilder(
      column: $state.table.expectedCash,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get variance => $state.composableBuilder(
      column: $state.table.variance,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get remittance => $state.composableBuilder(
      column: $state.table.remittance,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get transactionsCount => $state.composableBuilder(
      column: $state.table.transactionsCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get openedAt => $state.composableBuilder(
      column: $state.table.openedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get closedAt => $state.composableBuilder(
      column: $state.table.closedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $state.db.sessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$SessionsTableOrderingComposer(ComposerState(
                $state.db, $state.db.sessions, joinBuilder, parentComposers)));
    return composer;
  }

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

typedef $$ShiftOpeningDenominationsTableCreateCompanionBuilder
    = ShiftOpeningDenominationsCompanion Function({
  Value<int> id,
  required int shiftId,
  required int denom,
  Value<int> quantity,
  Value<double> subtotal,
});
typedef $$ShiftOpeningDenominationsTableUpdateCompanionBuilder
    = ShiftOpeningDenominationsCompanion Function({
  Value<int> id,
  Value<int> shiftId,
  Value<int> denom,
  Value<int> quantity,
  Value<double> subtotal,
});

class $$ShiftOpeningDenominationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShiftOpeningDenominationsTable,
    ShiftOpeningDenomination,
    $$ShiftOpeningDenominationsTableFilterComposer,
    $$ShiftOpeningDenominationsTableOrderingComposer,
    $$ShiftOpeningDenominationsTableCreateCompanionBuilder,
    $$ShiftOpeningDenominationsTableUpdateCompanionBuilder> {
  $$ShiftOpeningDenominationsTableTableManager(
      _$AppDatabase db, $ShiftOpeningDenominationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$ShiftOpeningDenominationsTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$ShiftOpeningDenominationsTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> shiftId = const Value.absent(),
            Value<int> denom = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
          }) =>
              ShiftOpeningDenominationsCompanion(
            id: id,
            shiftId: shiftId,
            denom: denom,
            quantity: quantity,
            subtotal: subtotal,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int shiftId,
            required int denom,
            Value<int> quantity = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
          }) =>
              ShiftOpeningDenominationsCompanion.insert(
            id: id,
            shiftId: shiftId,
            denom: denom,
            quantity: quantity,
            subtotal: subtotal,
          ),
        ));
}

class $$ShiftOpeningDenominationsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ShiftOpeningDenominationsTable> {
  $$ShiftOpeningDenominationsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get denom => $state.composableBuilder(
      column: $state.table.denom,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get subtotal => $state.composableBuilder(
      column: $state.table.subtotal,
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

class $$ShiftOpeningDenominationsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ShiftOpeningDenominationsTable> {
  $$ShiftOpeningDenominationsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get denom => $state.composableBuilder(
      column: $state.table.denom,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get subtotal => $state.composableBuilder(
      column: $state.table.subtotal,
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

typedef $$ShiftClosingDenominationsTableCreateCompanionBuilder
    = ShiftClosingDenominationsCompanion Function({
  Value<int> id,
  required int shiftId,
  required int denom,
  Value<int> quantity,
  Value<double> subtotal,
});
typedef $$ShiftClosingDenominationsTableUpdateCompanionBuilder
    = ShiftClosingDenominationsCompanion Function({
  Value<int> id,
  Value<int> shiftId,
  Value<int> denom,
  Value<int> quantity,
  Value<double> subtotal,
});

class $$ShiftClosingDenominationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShiftClosingDenominationsTable,
    ShiftClosingDenomination,
    $$ShiftClosingDenominationsTableFilterComposer,
    $$ShiftClosingDenominationsTableOrderingComposer,
    $$ShiftClosingDenominationsTableCreateCompanionBuilder,
    $$ShiftClosingDenominationsTableUpdateCompanionBuilder> {
  $$ShiftClosingDenominationsTableTableManager(
      _$AppDatabase db, $ShiftClosingDenominationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$ShiftClosingDenominationsTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$ShiftClosingDenominationsTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> shiftId = const Value.absent(),
            Value<int> denom = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
          }) =>
              ShiftClosingDenominationsCompanion(
            id: id,
            shiftId: shiftId,
            denom: denom,
            quantity: quantity,
            subtotal: subtotal,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int shiftId,
            required int denom,
            Value<int> quantity = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
          }) =>
              ShiftClosingDenominationsCompanion.insert(
            id: id,
            shiftId: shiftId,
            denom: denom,
            quantity: quantity,
            subtotal: subtotal,
          ),
        ));
}

class $$ShiftClosingDenominationsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ShiftClosingDenominationsTable> {
  $$ShiftClosingDenominationsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get denom => $state.composableBuilder(
      column: $state.table.denom,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get subtotal => $state.composableBuilder(
      column: $state.table.subtotal,
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

class $$ShiftClosingDenominationsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ShiftClosingDenominationsTable> {
  $$ShiftClosingDenominationsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get denom => $state.composableBuilder(
      column: $state.table.denom,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get subtotal => $state.composableBuilder(
      column: $state.table.subtotal,
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

typedef $$ValetTransactionsTableCreateCompanionBuilder
    = ValetTransactionsCompanion Function({
  Value<int> id,
  Value<String?> localUuid,
  required int checkinShiftId,
  Value<int?> checkoutShiftId,
  required int userId,
  required String ticketNumber,
  required String plateNumber,
  Value<String?> vehicleBrand,
  Value<String?> vehicleModel,
  Value<String?> vehicleYear,
  Value<String?> vehicleColor,
  Value<String?> vehicleType,
  Value<String?> slot,
  Value<String?> parkingLevel,
  Value<String?> parkingSlot,
  Value<String?> belongingsJson,
  Value<String?> otherBelongings,
  Value<String?> signaturePng,
  Value<int?> signatureCapturedAt,
  Value<String?> customerFullName,
  Value<String?> customerMobile,
  Value<String?> assignedValetDriver,
  Value<String?> specialInstructions,
  Value<String?> valetServiceType,
  Value<String?> vehicleDamageJson,
  Value<String?> branchSnapshot,
  Value<String?> areaSnapshot,
  Value<String?> deviceIdSnapshot,
  Value<String?> serverTicketId,
  Value<int?> lastModifiedAt,
  Value<int?> localCreatedAt,
  required int timeIn,
  Value<int?> timeOut,
  Value<int?> durationMinutes,
  Value<double?> flatRate,
  Value<double?> succeedingFee,
  Value<double?> overnightFee,
  Value<double?> lostTicketFee,
  Value<double?> totalFee,
  Value<double?> amountTendered,
  Value<double?> changeAmount,
  Value<String> status,
  Value<int?> syncedAt,
});
typedef $$ValetTransactionsTableUpdateCompanionBuilder
    = ValetTransactionsCompanion Function({
  Value<int> id,
  Value<String?> localUuid,
  Value<int> checkinShiftId,
  Value<int?> checkoutShiftId,
  Value<int> userId,
  Value<String> ticketNumber,
  Value<String> plateNumber,
  Value<String?> vehicleBrand,
  Value<String?> vehicleModel,
  Value<String?> vehicleYear,
  Value<String?> vehicleColor,
  Value<String?> vehicleType,
  Value<String?> slot,
  Value<String?> parkingLevel,
  Value<String?> parkingSlot,
  Value<String?> belongingsJson,
  Value<String?> otherBelongings,
  Value<String?> signaturePng,
  Value<int?> signatureCapturedAt,
  Value<String?> customerFullName,
  Value<String?> customerMobile,
  Value<String?> assignedValetDriver,
  Value<String?> specialInstructions,
  Value<String?> valetServiceType,
  Value<String?> vehicleDamageJson,
  Value<String?> branchSnapshot,
  Value<String?> areaSnapshot,
  Value<String?> deviceIdSnapshot,
  Value<String?> serverTicketId,
  Value<int?> lastModifiedAt,
  Value<int?> localCreatedAt,
  Value<int> timeIn,
  Value<int?> timeOut,
  Value<int?> durationMinutes,
  Value<double?> flatRate,
  Value<double?> succeedingFee,
  Value<double?> overnightFee,
  Value<double?> lostTicketFee,
  Value<double?> totalFee,
  Value<double?> amountTendered,
  Value<double?> changeAmount,
  Value<String> status,
  Value<int?> syncedAt,
});

class $$ValetTransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ValetTransactionsTable,
    ValetTransaction,
    $$ValetTransactionsTableFilterComposer,
    $$ValetTransactionsTableOrderingComposer,
    $$ValetTransactionsTableCreateCompanionBuilder,
    $$ValetTransactionsTableUpdateCompanionBuilder> {
  $$ValetTransactionsTableTableManager(
      _$AppDatabase db, $ValetTransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ValetTransactionsTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$ValetTransactionsTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> localUuid = const Value.absent(),
            Value<int> checkinShiftId = const Value.absent(),
            Value<int?> checkoutShiftId = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> ticketNumber = const Value.absent(),
            Value<String> plateNumber = const Value.absent(),
            Value<String?> vehicleBrand = const Value.absent(),
            Value<String?> vehicleModel = const Value.absent(),
            Value<String?> vehicleYear = const Value.absent(),
            Value<String?> vehicleColor = const Value.absent(),
            Value<String?> vehicleType = const Value.absent(),
            Value<String?> slot = const Value.absent(),
            Value<String?> parkingLevel = const Value.absent(),
            Value<String?> parkingSlot = const Value.absent(),
            Value<String?> belongingsJson = const Value.absent(),
            Value<String?> otherBelongings = const Value.absent(),
            Value<String?> signaturePng = const Value.absent(),
            Value<int?> signatureCapturedAt = const Value.absent(),
            Value<String?> customerFullName = const Value.absent(),
            Value<String?> customerMobile = const Value.absent(),
            Value<String?> assignedValetDriver = const Value.absent(),
            Value<String?> specialInstructions = const Value.absent(),
            Value<String?> valetServiceType = const Value.absent(),
            Value<String?> vehicleDamageJson = const Value.absent(),
            Value<String?> branchSnapshot = const Value.absent(),
            Value<String?> areaSnapshot = const Value.absent(),
            Value<String?> deviceIdSnapshot = const Value.absent(),
            Value<String?> serverTicketId = const Value.absent(),
            Value<int?> lastModifiedAt = const Value.absent(),
            Value<int?> localCreatedAt = const Value.absent(),
            Value<int> timeIn = const Value.absent(),
            Value<int?> timeOut = const Value.absent(),
            Value<int?> durationMinutes = const Value.absent(),
            Value<double?> flatRate = const Value.absent(),
            Value<double?> succeedingFee = const Value.absent(),
            Value<double?> overnightFee = const Value.absent(),
            Value<double?> lostTicketFee = const Value.absent(),
            Value<double?> totalFee = const Value.absent(),
            Value<double?> amountTendered = const Value.absent(),
            Value<double?> changeAmount = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> syncedAt = const Value.absent(),
          }) =>
              ValetTransactionsCompanion(
            id: id,
            localUuid: localUuid,
            checkinShiftId: checkinShiftId,
            checkoutShiftId: checkoutShiftId,
            userId: userId,
            ticketNumber: ticketNumber,
            plateNumber: plateNumber,
            vehicleBrand: vehicleBrand,
            vehicleModel: vehicleModel,
            vehicleYear: vehicleYear,
            vehicleColor: vehicleColor,
            vehicleType: vehicleType,
            slot: slot,
            parkingLevel: parkingLevel,
            parkingSlot: parkingSlot,
            belongingsJson: belongingsJson,
            otherBelongings: otherBelongings,
            signaturePng: signaturePng,
            signatureCapturedAt: signatureCapturedAt,
            customerFullName: customerFullName,
            customerMobile: customerMobile,
            assignedValetDriver: assignedValetDriver,
            specialInstructions: specialInstructions,
            valetServiceType: valetServiceType,
            vehicleDamageJson: vehicleDamageJson,
            branchSnapshot: branchSnapshot,
            areaSnapshot: areaSnapshot,
            deviceIdSnapshot: deviceIdSnapshot,
            serverTicketId: serverTicketId,
            lastModifiedAt: lastModifiedAt,
            localCreatedAt: localCreatedAt,
            timeIn: timeIn,
            timeOut: timeOut,
            durationMinutes: durationMinutes,
            flatRate: flatRate,
            succeedingFee: succeedingFee,
            overnightFee: overnightFee,
            lostTicketFee: lostTicketFee,
            totalFee: totalFee,
            amountTendered: amountTendered,
            changeAmount: changeAmount,
            status: status,
            syncedAt: syncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> localUuid = const Value.absent(),
            required int checkinShiftId,
            Value<int?> checkoutShiftId = const Value.absent(),
            required int userId,
            required String ticketNumber,
            required String plateNumber,
            Value<String?> vehicleBrand = const Value.absent(),
            Value<String?> vehicleModel = const Value.absent(),
            Value<String?> vehicleYear = const Value.absent(),
            Value<String?> vehicleColor = const Value.absent(),
            Value<String?> vehicleType = const Value.absent(),
            Value<String?> slot = const Value.absent(),
            Value<String?> parkingLevel = const Value.absent(),
            Value<String?> parkingSlot = const Value.absent(),
            Value<String?> belongingsJson = const Value.absent(),
            Value<String?> otherBelongings = const Value.absent(),
            Value<String?> signaturePng = const Value.absent(),
            Value<int?> signatureCapturedAt = const Value.absent(),
            Value<String?> customerFullName = const Value.absent(),
            Value<String?> customerMobile = const Value.absent(),
            Value<String?> assignedValetDriver = const Value.absent(),
            Value<String?> specialInstructions = const Value.absent(),
            Value<String?> valetServiceType = const Value.absent(),
            Value<String?> vehicleDamageJson = const Value.absent(),
            Value<String?> branchSnapshot = const Value.absent(),
            Value<String?> areaSnapshot = const Value.absent(),
            Value<String?> deviceIdSnapshot = const Value.absent(),
            Value<String?> serverTicketId = const Value.absent(),
            Value<int?> lastModifiedAt = const Value.absent(),
            Value<int?> localCreatedAt = const Value.absent(),
            required int timeIn,
            Value<int?> timeOut = const Value.absent(),
            Value<int?> durationMinutes = const Value.absent(),
            Value<double?> flatRate = const Value.absent(),
            Value<double?> succeedingFee = const Value.absent(),
            Value<double?> overnightFee = const Value.absent(),
            Value<double?> lostTicketFee = const Value.absent(),
            Value<double?> totalFee = const Value.absent(),
            Value<double?> amountTendered = const Value.absent(),
            Value<double?> changeAmount = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> syncedAt = const Value.absent(),
          }) =>
              ValetTransactionsCompanion.insert(
            id: id,
            localUuid: localUuid,
            checkinShiftId: checkinShiftId,
            checkoutShiftId: checkoutShiftId,
            userId: userId,
            ticketNumber: ticketNumber,
            plateNumber: plateNumber,
            vehicleBrand: vehicleBrand,
            vehicleModel: vehicleModel,
            vehicleYear: vehicleYear,
            vehicleColor: vehicleColor,
            vehicleType: vehicleType,
            slot: slot,
            parkingLevel: parkingLevel,
            parkingSlot: parkingSlot,
            belongingsJson: belongingsJson,
            otherBelongings: otherBelongings,
            signaturePng: signaturePng,
            signatureCapturedAt: signatureCapturedAt,
            customerFullName: customerFullName,
            customerMobile: customerMobile,
            assignedValetDriver: assignedValetDriver,
            specialInstructions: specialInstructions,
            valetServiceType: valetServiceType,
            vehicleDamageJson: vehicleDamageJson,
            branchSnapshot: branchSnapshot,
            areaSnapshot: areaSnapshot,
            deviceIdSnapshot: deviceIdSnapshot,
            serverTicketId: serverTicketId,
            lastModifiedAt: lastModifiedAt,
            localCreatedAt: localCreatedAt,
            timeIn: timeIn,
            timeOut: timeOut,
            durationMinutes: durationMinutes,
            flatRate: flatRate,
            succeedingFee: succeedingFee,
            overnightFee: overnightFee,
            lostTicketFee: lostTicketFee,
            totalFee: totalFee,
            amountTendered: amountTendered,
            changeAmount: changeAmount,
            status: status,
            syncedAt: syncedAt,
          ),
        ));
}

class $$ValetTransactionsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ValetTransactionsTable> {
  $$ValetTransactionsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get localUuid => $state.composableBuilder(
      column: $state.table.localUuid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get ticketNumber => $state.composableBuilder(
      column: $state.table.ticketNumber,
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

  ColumnFilters<String> get vehicleModel => $state.composableBuilder(
      column: $state.table.vehicleModel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get vehicleYear => $state.composableBuilder(
      column: $state.table.vehicleYear,
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

  ColumnFilters<String> get slot => $state.composableBuilder(
      column: $state.table.slot,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get parkingLevel => $state.composableBuilder(
      column: $state.table.parkingLevel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get parkingSlot => $state.composableBuilder(
      column: $state.table.parkingSlot,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get belongingsJson => $state.composableBuilder(
      column: $state.table.belongingsJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get otherBelongings => $state.composableBuilder(
      column: $state.table.otherBelongings,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get signaturePng => $state.composableBuilder(
      column: $state.table.signaturePng,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get signatureCapturedAt => $state.composableBuilder(
      column: $state.table.signatureCapturedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customerFullName => $state.composableBuilder(
      column: $state.table.customerFullName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customerMobile => $state.composableBuilder(
      column: $state.table.customerMobile,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get assignedValetDriver => $state.composableBuilder(
      column: $state.table.assignedValetDriver,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get specialInstructions => $state.composableBuilder(
      column: $state.table.specialInstructions,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get valetServiceType => $state.composableBuilder(
      column: $state.table.valetServiceType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get vehicleDamageJson => $state.composableBuilder(
      column: $state.table.vehicleDamageJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get branchSnapshot => $state.composableBuilder(
      column: $state.table.branchSnapshot,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get areaSnapshot => $state.composableBuilder(
      column: $state.table.areaSnapshot,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get deviceIdSnapshot => $state.composableBuilder(
      column: $state.table.deviceIdSnapshot,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get serverTicketId => $state.composableBuilder(
      column: $state.table.serverTicketId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get localCreatedAt => $state.composableBuilder(
      column: $state.table.localCreatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get timeIn => $state.composableBuilder(
      column: $state.table.timeIn,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get timeOut => $state.composableBuilder(
      column: $state.table.timeOut,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get durationMinutes => $state.composableBuilder(
      column: $state.table.durationMinutes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get flatRate => $state.composableBuilder(
      column: $state.table.flatRate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get succeedingFee => $state.composableBuilder(
      column: $state.table.succeedingFee,
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

  ColumnFilters<double> get totalFee => $state.composableBuilder(
      column: $state.table.totalFee,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get amountTendered => $state.composableBuilder(
      column: $state.table.amountTendered,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get changeAmount => $state.composableBuilder(
      column: $state.table.changeAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ShiftsTableFilterComposer get checkinShiftId {
    final $$ShiftsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.checkinShiftId,
        referencedTable: $state.db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$ShiftsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.shifts, joinBuilder, parentComposers)));
    return composer;
  }

  $$ShiftsTableFilterComposer get checkoutShiftId {
    final $$ShiftsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.checkoutShiftId,
        referencedTable: $state.db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$ShiftsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.shifts, joinBuilder, parentComposers)));
    return composer;
  }

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

class $$ValetTransactionsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ValetTransactionsTable> {
  $$ValetTransactionsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get localUuid => $state.composableBuilder(
      column: $state.table.localUuid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get ticketNumber => $state.composableBuilder(
      column: $state.table.ticketNumber,
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

  ColumnOrderings<String> get vehicleModel => $state.composableBuilder(
      column: $state.table.vehicleModel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get vehicleYear => $state.composableBuilder(
      column: $state.table.vehicleYear,
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

  ColumnOrderings<String> get slot => $state.composableBuilder(
      column: $state.table.slot,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get parkingLevel => $state.composableBuilder(
      column: $state.table.parkingLevel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get parkingSlot => $state.composableBuilder(
      column: $state.table.parkingSlot,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get belongingsJson => $state.composableBuilder(
      column: $state.table.belongingsJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get otherBelongings => $state.composableBuilder(
      column: $state.table.otherBelongings,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get signaturePng => $state.composableBuilder(
      column: $state.table.signaturePng,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get signatureCapturedAt => $state.composableBuilder(
      column: $state.table.signatureCapturedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customerFullName => $state.composableBuilder(
      column: $state.table.customerFullName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customerMobile => $state.composableBuilder(
      column: $state.table.customerMobile,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get assignedValetDriver => $state.composableBuilder(
      column: $state.table.assignedValetDriver,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get specialInstructions => $state.composableBuilder(
      column: $state.table.specialInstructions,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get valetServiceType => $state.composableBuilder(
      column: $state.table.valetServiceType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get vehicleDamageJson => $state.composableBuilder(
      column: $state.table.vehicleDamageJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get branchSnapshot => $state.composableBuilder(
      column: $state.table.branchSnapshot,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get areaSnapshot => $state.composableBuilder(
      column: $state.table.areaSnapshot,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get deviceIdSnapshot => $state.composableBuilder(
      column: $state.table.deviceIdSnapshot,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get serverTicketId => $state.composableBuilder(
      column: $state.table.serverTicketId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get lastModifiedAt => $state.composableBuilder(
      column: $state.table.lastModifiedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get localCreatedAt => $state.composableBuilder(
      column: $state.table.localCreatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get timeIn => $state.composableBuilder(
      column: $state.table.timeIn,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get timeOut => $state.composableBuilder(
      column: $state.table.timeOut,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get durationMinutes => $state.composableBuilder(
      column: $state.table.durationMinutes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get flatRate => $state.composableBuilder(
      column: $state.table.flatRate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get succeedingFee => $state.composableBuilder(
      column: $state.table.succeedingFee,
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

  ColumnOrderings<double> get totalFee => $state.composableBuilder(
      column: $state.table.totalFee,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get amountTendered => $state.composableBuilder(
      column: $state.table.amountTendered,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get changeAmount => $state.composableBuilder(
      column: $state.table.changeAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ShiftsTableOrderingComposer get checkinShiftId {
    final $$ShiftsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.checkinShiftId,
        referencedTable: $state.db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ShiftsTableOrderingComposer(ComposerState(
                $state.db, $state.db.shifts, joinBuilder, parentComposers)));
    return composer;
  }

  $$ShiftsTableOrderingComposer get checkoutShiftId {
    final $$ShiftsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.checkoutShiftId,
        referencedTable: $state.db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ShiftsTableOrderingComposer(ComposerState(
                $state.db, $state.db.shifts, joinBuilder, parentComposers)));
    return composer;
  }

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

typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String type,
  required int entityId,
  required String payload,
  required int createdAt,
  Value<int?> syncedAt,
  Value<int> retryCount,
  Value<String?> lastError,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> type,
  Value<int> entityId,
  Value<String> payload,
  Value<int> createdAt,
  Value<int?> syncedAt,
  Value<int> retryCount,
  Value<String?> lastError,
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
            Value<int> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> entityId = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> syncedAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            type: type,
            entityId: entityId,
            payload: payload,
            createdAt: createdAt,
            syncedAt: syncedAt,
            retryCount: retryCount,
            lastError: lastError,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String type,
            required int entityId,
            required String payload,
            required int createdAt,
            Value<int?> syncedAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            type: type,
            entityId: entityId,
            payload: payload,
            createdAt: createdAt,
            syncedAt: syncedAt,
            retryCount: retryCount,
            lastError: lastError,
          ),
        ));
}

class $$SyncQueueTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get entityId => $state.composableBuilder(
      column: $state.table.entityId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastError => $state.composableBuilder(
      column: $state.table.lastError,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SyncQueueTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get entityId => $state.composableBuilder(
      column: $state.table.entityId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get syncedAt => $state.composableBuilder(
      column: $state.table.syncedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastError => $state.composableBuilder(
      column: $state.table.lastError,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DeviceInfoTableTableManager get deviceInfo =>
      $$DeviceInfoTableTableManager(_db, _db.deviceInfo);
  $$OfflineAccountsTableTableManager get offlineAccounts =>
      $$OfflineAccountsTableTableManager(_db, _db.offlineAccounts);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$ShiftsTableTableManager get shifts =>
      $$ShiftsTableTableManager(_db, _db.shifts);
  $$ShiftOpeningDenominationsTableTableManager get shiftOpeningDenominations =>
      $$ShiftOpeningDenominationsTableTableManager(
          _db, _db.shiftOpeningDenominations);
  $$ShiftClosingDenominationsTableTableManager get shiftClosingDenominations =>
      $$ShiftClosingDenominationsTableTableManager(
          _db, _db.shiftClosingDenominations);
  $$ValetTransactionsTableTableManager get valetTransactions =>
      $$ValetTransactionsTableTableManager(_db, _db.valetTransactions);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}

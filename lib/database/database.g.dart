// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
    'hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
    'minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekdayMaskMeta = const VerificationMeta(
    'weekdayMask',
  );
  @override
  late final GeneratedColumn<int> weekdayMask = GeneratedColumn<int>(
    'weekday_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(Weekdays.everyDay),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _speakAloudMeta = const VerificationMeta(
    'speakAloud',
  );
  @override
  late final GeneratedColumn<bool> speakAloud = GeneratedColumn<bool>(
    'speak_aloud',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("speak_aloud" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isBuiltInMeta = const VerificationMeta(
    'isBuiltIn',
  );
  @override
  late final GeneratedColumn<bool> isBuiltIn = GeneratedColumn<bool>(
    'is_built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    body,
    hour,
    minute,
    weekdayMask,
    enabled,
    speakAloud,
    isBuiltIn,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('hour')) {
      context.handle(
        _hourMeta,
        hour.isAcceptableOrUnknown(data['hour']!, _hourMeta),
      );
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(
        _minuteMeta,
        minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta),
      );
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    if (data.containsKey('weekday_mask')) {
      context.handle(
        _weekdayMaskMeta,
        weekdayMask.isAcceptableOrUnknown(
          data['weekday_mask']!,
          _weekdayMaskMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('speak_aloud')) {
      context.handle(
        _speakAloudMeta,
        speakAloud.isAcceptableOrUnknown(data['speak_aloud']!, _speakAloudMeta),
      );
    }
    if (data.containsKey('is_built_in')) {
      context.handle(
        _isBuiltInMeta,
        isBuiltIn.isAcceptableOrUnknown(data['is_built_in']!, _isBuiltInMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      hour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour'],
      )!,
      minute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute'],
      )!,
      weekdayMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday_mask'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      speakAloud: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}speak_aloud'],
      )!,
      isBuiltIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_built_in'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final int id;
  final String title;

  /// Текст тіла сповіщення. `null`/порожній — показувати лише [title].
  final String? body;

  /// Година спрацювання, 0–23.
  final int hour;

  /// Хвилина спрацювання, 0–59.
  final int minute;

  /// Бітова маска днів тижня, див. [Weekdays].
  final int weekdayMask;
  final bool enabled;

  /// Чи проговорювати текст сповіщення вголос (TTS) при спрацюванні.
  final bool speakAloud;
  final bool isBuiltIn;
  final DateTime createdAt;
  const Reminder({
    required this.id,
    required this.title,
    this.body,
    required this.hour,
    required this.minute,
    required this.weekdayMask,
    required this.enabled,
    required this.speakAloud,
    required this.isBuiltIn,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    map['weekday_mask'] = Variable<int>(weekdayMask);
    map['enabled'] = Variable<bool>(enabled);
    map['speak_aloud'] = Variable<bool>(speakAloud);
    map['is_built_in'] = Variable<bool>(isBuiltIn);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      title: Value(title),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      hour: Value(hour),
      minute: Value(minute),
      weekdayMask: Value(weekdayMask),
      enabled: Value(enabled),
      speakAloud: Value(speakAloud),
      isBuiltIn: Value(isBuiltIn),
      createdAt: Value(createdAt),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String?>(json['body']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
      weekdayMask: serializer.fromJson<int>(json['weekdayMask']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      speakAloud: serializer.fromJson<bool>(json['speakAloud']),
      isBuiltIn: serializer.fromJson<bool>(json['isBuiltIn']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String?>(body),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
      'weekdayMask': serializer.toJson<int>(weekdayMask),
      'enabled': serializer.toJson<bool>(enabled),
      'speakAloud': serializer.toJson<bool>(speakAloud),
      'isBuiltIn': serializer.toJson<bool>(isBuiltIn),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Reminder copyWith({
    int? id,
    String? title,
    Value<String?> body = const Value.absent(),
    int? hour,
    int? minute,
    int? weekdayMask,
    bool? enabled,
    bool? speakAloud,
    bool? isBuiltIn,
    DateTime? createdAt,
  }) => Reminder(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body.present ? body.value : this.body,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    weekdayMask: weekdayMask ?? this.weekdayMask,
    enabled: enabled ?? this.enabled,
    speakAloud: speakAloud ?? this.speakAloud,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    createdAt: createdAt ?? this.createdAt,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      weekdayMask: data.weekdayMask.present
          ? data.weekdayMask.value
          : this.weekdayMask,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      speakAloud: data.speakAloud.present
          ? data.speakAloud.value
          : this.speakAloud,
      isBuiltIn: data.isBuiltIn.present ? data.isBuiltIn.value : this.isBuiltIn,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('weekdayMask: $weekdayMask, ')
          ..write('enabled: $enabled, ')
          ..write('speakAloud: $speakAloud, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    body,
    hour,
    minute,
    weekdayMask,
    enabled,
    speakAloud,
    isBuiltIn,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.title == this.title &&
          other.body == this.body &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.weekdayMask == this.weekdayMask &&
          other.enabled == this.enabled &&
          other.speakAloud == this.speakAloud &&
          other.isBuiltIn == this.isBuiltIn &&
          other.createdAt == this.createdAt);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> body;
  final Value<int> hour;
  final Value<int> minute;
  final Value<int> weekdayMask;
  final Value<bool> enabled;
  final Value<bool> speakAloud;
  final Value<bool> isBuiltIn;
  final Value<DateTime> createdAt;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.weekdayMask = const Value.absent(),
    this.enabled = const Value.absent(),
    this.speakAloud = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.body = const Value.absent(),
    required int hour,
    required int minute,
    this.weekdayMask = const Value.absent(),
    this.enabled = const Value.absent(),
    this.speakAloud = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title),
       hour = Value(hour),
       minute = Value(minute);
  static Insertable<Reminder> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<int>? weekdayMask,
    Expression<bool>? enabled,
    Expression<bool>? speakAloud,
    Expression<bool>? isBuiltIn,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (weekdayMask != null) 'weekday_mask': weekdayMask,
      if (enabled != null) 'enabled': enabled,
      if (speakAloud != null) 'speak_aloud': speakAloud,
      if (isBuiltIn != null) 'is_built_in': isBuiltIn,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? body,
    Value<int>? hour,
    Value<int>? minute,
    Value<int>? weekdayMask,
    Value<bool>? enabled,
    Value<bool>? speakAloud,
    Value<bool>? isBuiltIn,
    Value<DateTime>? createdAt,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdayMask: weekdayMask ?? this.weekdayMask,
      enabled: enabled ?? this.enabled,
      speakAloud: speakAloud ?? this.speakAloud,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (weekdayMask.present) {
      map['weekday_mask'] = Variable<int>(weekdayMask.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (speakAloud.present) {
      map['speak_aloud'] = Variable<bool>(speakAloud.value);
    }
    if (isBuiltIn.present) {
      map['is_built_in'] = Variable<bool>(isBuiltIn.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('weekdayMask: $weekdayMask, ')
          ..write('enabled: $enabled, ')
          ..write('speakAloud: $speakAloud, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [reminders];
}

typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  required String title,
  Value<String?> body,
  required int hour,
  required int minute,
  Value<int> weekdayMask,
  Value<bool> enabled,
  Value<bool> speakAloud,
  Value<bool> isBuiltIn,
  Value<DateTime> createdAt,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String?> body,
  Value<int> hour,
  Value<int> minute,
  Value<int> weekdayMask,
  Value<bool> enabled,
  Value<bool> speakAloud,
  Value<bool> isBuiltIn,
  Value<DateTime> createdAt,
});

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekdayMask => $composableBuilder(
    column: $table.weekdayMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get speakAloud => $composableBuilder(
    column: $table.speakAloud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekdayMask => $composableBuilder(
    column: $table.weekdayMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get speakAloud => $composableBuilder(
    column: $table.speakAloud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);

  GeneratedColumn<int> get weekdayMask => $composableBuilder(
    column: $table.weekdayMask,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get speakAloud => $composableBuilder(
    column: $table.speakAloud,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBuiltIn =>
      $composableBuilder(column: $table.isBuiltIn, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
          Reminder,
          PrefetchHooks Function()
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<int> hour = const Value.absent(),
                Value<int> minute = const Value.absent(),
                Value<int> weekdayMask = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> speakAloud = const Value.absent(),
                Value<bool> isBuiltIn = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                title: title,
                body: body,
                hour: hour,
                minute: minute,
                weekdayMask: weekdayMask,
                enabled: enabled,
                speakAloud: speakAloud,
                isBuiltIn: isBuiltIn,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> body = const Value.absent(),
                required int hour,
                required int minute,
                Value<int> weekdayMask = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> speakAloud = const Value.absent(),
                Value<bool> isBuiltIn = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                title: title,
                body: body,
                hour: hour,
                minute: minute,
                weekdayMask: weekdayMask,
                enabled: enabled,
                speakAloud: speakAloud,
                isBuiltIn: isBuiltIn,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
      Reminder,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
}

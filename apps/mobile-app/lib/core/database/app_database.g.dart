// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $InvoicesTableTable extends InvoicesTable
    with TableInfo<$InvoicesTableTable, InvoicesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoicesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerPhoneMeta = const VerificationMeta(
    'customerPhone',
  );
  @override
  late final GeneratedColumn<String> customerPhone = GeneratedColumn<String>(
    'customer_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _invoiceNumberMeta = const VerificationMeta(
    'invoiceNumber',
  );
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
    'invoice_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _docTypeMeta = const VerificationMeta(
    'docType',
  );
  @override
  late final GeneratedColumn<String> docType = GeneratedColumn<String>(
    'doc_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('invoice'),
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountAmountMeta = const VerificationMeta(
    'discountAmount',
  );
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
    'discount_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxMeta = const VerificationMeta('tax');
  @override
  late final GeneratedColumn<double> tax = GeneratedColumn<double>(
    'tax',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPaidMeta = const VerificationMeta(
    'amountPaid',
  );
  @override
  late final GeneratedColumn<double> amountPaid = GeneratedColumn<double>(
    'amount_paid',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _paymentAccountIdMeta = const VerificationMeta(
    'paymentAccountId',
  );
  @override
  late final GeneratedColumn<String> paymentAccountId = GeneratedColumn<String>(
    'payment_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hasReturnMeta = const VerificationMeta(
    'hasReturn',
  );
  @override
  late final GeneratedColumn<int> hasReturn = GeneratedColumn<int>(
    'has_return',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _returnedAmountMeta = const VerificationMeta(
    'returnedAmount',
  );
  @override
  late final GeneratedColumn<double> returnedAmount = GeneratedColumn<double>(
    'returned_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _creditNoteNumberMeta = const VerificationMeta(
    'creditNoteNumber',
  );
  @override
  late final GeneratedColumn<String> creditNoteNumber = GeneratedColumn<String>(
    'credit_note_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> serverUpdatedAt = GeneratedColumn<int>(
    'server_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_create'),
  );
  static const VerificationMeta _localVersionMeta = const VerificationMeta(
    'localVersion',
  );
  @override
  late final GeneratedColumn<int> localVersion = GeneratedColumn<int>(
    'local_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    customerId,
    customerName,
    customerPhone,
    invoiceNumber,
    date,
    dueDate,
    status,
    docType,
    subtotal,
    discountAmount,
    tax,
    total,
    amountPaid,
    paymentMethod,
    paymentAccountId,
    note,
    createdBy,
    hasReturn,
    returnedAmount,
    creditNoteNumber,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    localVersion,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoices';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvoicesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('customer_phone')) {
      context.handle(
        _customerPhoneMeta,
        customerPhone.isAcceptableOrUnknown(
          data['customer_phone']!,
          _customerPhoneMeta,
        ),
      );
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
        _invoiceNumberMeta,
        invoiceNumber.isAcceptableOrUnknown(
          data['invoice_number']!,
          _invoiceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invoiceNumberMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('doc_type')) {
      context.handle(
        _docTypeMeta,
        docType.isAcceptableOrUnknown(data['doc_type']!, _docTypeMeta),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
        _discountAmountMeta,
        discountAmount.isAcceptableOrUnknown(
          data['discount_amount']!,
          _discountAmountMeta,
        ),
      );
    }
    if (data.containsKey('tax')) {
      context.handle(
        _taxMeta,
        tax.isAcceptableOrUnknown(data['tax']!, _taxMeta),
      );
    } else if (isInserting) {
      context.missing(_taxMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('amount_paid')) {
      context.handle(
        _amountPaidMeta,
        amountPaid.isAcceptableOrUnknown(data['amount_paid']!, _amountPaidMeta),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('payment_account_id')) {
      context.handle(
        _paymentAccountIdMeta,
        paymentAccountId.isAcceptableOrUnknown(
          data['payment_account_id']!,
          _paymentAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('has_return')) {
      context.handle(
        _hasReturnMeta,
        hasReturn.isAcceptableOrUnknown(data['has_return']!, _hasReturnMeta),
      );
    }
    if (data.containsKey('returned_amount')) {
      context.handle(
        _returnedAmountMeta,
        returnedAmount.isAcceptableOrUnknown(
          data['returned_amount']!,
          _returnedAmountMeta,
        ),
      );
    }
    if (data.containsKey('credit_note_number')) {
      context.handle(
        _creditNoteNumberMeta,
        creditNoteNumber.isAcceptableOrUnknown(
          data['credit_note_number']!,
          _creditNoteNumberMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('local_version')) {
      context.handle(
        _localVersionMeta,
        localVersion.isAcceptableOrUnknown(
          data['local_version']!,
          _localVersionMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoicesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoicesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      customerPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_phone'],
      )!,
      invoiceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_number'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      docType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc_type'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      discountAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_amount'],
      )!,
      tax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total'],
      )!,
      amountPaid: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount_paid'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      paymentAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_account_id'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      hasReturn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}has_return'],
      )!,
      returnedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}returned_amount'],
      )!,
      creditNoteNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit_note_number'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_updated_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      localVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_version'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $InvoicesTableTable createAlias(String alias) {
    return $InvoicesTableTable(attachedDatabase, alias);
  }
}

class InvoicesTableData extends DataClass
    implements Insertable<InvoicesTableData> {
  final String id;
  final String businessId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String invoiceNumber;
  final String date;
  final String dueDate;
  final String status;
  final String docType;
  final double subtotal;
  final double discountAmount;
  final double tax;
  final double total;
  final double amountPaid;
  final String paymentMethod;
  final String paymentAccountId;
  final String note;
  final String createdBy;
  final int hasReturn;
  final double returnedAmount;
  final String creditNoteNumber;
  final int createdAt;
  final int updatedAt;
  final int? serverUpdatedAt;
  final String syncStatus;
  final int localVersion;
  final int isDeleted;
  const InvoicesTableData({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.invoiceNumber,
    required this.date,
    required this.dueDate,
    required this.status,
    required this.docType,
    required this.subtotal,
    required this.discountAmount,
    required this.tax,
    required this.total,
    required this.amountPaid,
    required this.paymentMethod,
    required this.paymentAccountId,
    required this.note,
    required this.createdBy,
    required this.hasReturn,
    required this.returnedAmount,
    required this.creditNoteNumber,
    required this.createdAt,
    required this.updatedAt,
    this.serverUpdatedAt,
    required this.syncStatus,
    required this.localVersion,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['customer_id'] = Variable<String>(customerId);
    map['customer_name'] = Variable<String>(customerName);
    map['customer_phone'] = Variable<String>(customerPhone);
    map['invoice_number'] = Variable<String>(invoiceNumber);
    map['date'] = Variable<String>(date);
    map['due_date'] = Variable<String>(dueDate);
    map['status'] = Variable<String>(status);
    map['doc_type'] = Variable<String>(docType);
    map['subtotal'] = Variable<double>(subtotal);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['tax'] = Variable<double>(tax);
    map['total'] = Variable<double>(total);
    map['amount_paid'] = Variable<double>(amountPaid);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['payment_account_id'] = Variable<String>(paymentAccountId);
    map['note'] = Variable<String>(note);
    map['created_by'] = Variable<String>(createdBy);
    map['has_return'] = Variable<int>(hasReturn);
    map['returned_amount'] = Variable<double>(returnedAmount);
    map['credit_note_number'] = Variable<String>(creditNoteNumber);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['local_version'] = Variable<int>(localVersion);
    map['is_deleted'] = Variable<int>(isDeleted);
    return map;
  }

  InvoicesTableCompanion toCompanion(bool nullToAbsent) {
    return InvoicesTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      customerId: Value(customerId),
      customerName: Value(customerName),
      customerPhone: Value(customerPhone),
      invoiceNumber: Value(invoiceNumber),
      date: Value(date),
      dueDate: Value(dueDate),
      status: Value(status),
      docType: Value(docType),
      subtotal: Value(subtotal),
      discountAmount: Value(discountAmount),
      tax: Value(tax),
      total: Value(total),
      amountPaid: Value(amountPaid),
      paymentMethod: Value(paymentMethod),
      paymentAccountId: Value(paymentAccountId),
      note: Value(note),
      createdBy: Value(createdBy),
      hasReturn: Value(hasReturn),
      returnedAmount: Value(returnedAmount),
      creditNoteNumber: Value(creditNoteNumber),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      localVersion: Value(localVersion),
      isDeleted: Value(isDeleted),
    );
  }

  factory InvoicesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoicesTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      customerName: serializer.fromJson<String>(json['customerName']),
      customerPhone: serializer.fromJson<String>(json['customerPhone']),
      invoiceNumber: serializer.fromJson<String>(json['invoiceNumber']),
      date: serializer.fromJson<String>(json['date']),
      dueDate: serializer.fromJson<String>(json['dueDate']),
      status: serializer.fromJson<String>(json['status']),
      docType: serializer.fromJson<String>(json['docType']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      tax: serializer.fromJson<double>(json['tax']),
      total: serializer.fromJson<double>(json['total']),
      amountPaid: serializer.fromJson<double>(json['amountPaid']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      paymentAccountId: serializer.fromJson<String>(json['paymentAccountId']),
      note: serializer.fromJson<String>(json['note']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      hasReturn: serializer.fromJson<int>(json['hasReturn']),
      returnedAmount: serializer.fromJson<double>(json['returnedAmount']),
      creditNoteNumber: serializer.fromJson<String>(json['creditNoteNumber']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      serverUpdatedAt: serializer.fromJson<int?>(json['serverUpdatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      localVersion: serializer.fromJson<int>(json['localVersion']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'customerId': serializer.toJson<String>(customerId),
      'customerName': serializer.toJson<String>(customerName),
      'customerPhone': serializer.toJson<String>(customerPhone),
      'invoiceNumber': serializer.toJson<String>(invoiceNumber),
      'date': serializer.toJson<String>(date),
      'dueDate': serializer.toJson<String>(dueDate),
      'status': serializer.toJson<String>(status),
      'docType': serializer.toJson<String>(docType),
      'subtotal': serializer.toJson<double>(subtotal),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'tax': serializer.toJson<double>(tax),
      'total': serializer.toJson<double>(total),
      'amountPaid': serializer.toJson<double>(amountPaid),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'paymentAccountId': serializer.toJson<String>(paymentAccountId),
      'note': serializer.toJson<String>(note),
      'createdBy': serializer.toJson<String>(createdBy),
      'hasReturn': serializer.toJson<int>(hasReturn),
      'returnedAmount': serializer.toJson<double>(returnedAmount),
      'creditNoteNumber': serializer.toJson<String>(creditNoteNumber),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'serverUpdatedAt': serializer.toJson<int?>(serverUpdatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'localVersion': serializer.toJson<int>(localVersion),
      'isDeleted': serializer.toJson<int>(isDeleted),
    };
  }

  InvoicesTableData copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? invoiceNumber,
    String? date,
    String? dueDate,
    String? status,
    String? docType,
    double? subtotal,
    double? discountAmount,
    double? tax,
    double? total,
    double? amountPaid,
    String? paymentMethod,
    String? paymentAccountId,
    String? note,
    String? createdBy,
    int? hasReturn,
    double? returnedAmount,
    String? creditNoteNumber,
    int? createdAt,
    int? updatedAt,
    Value<int?> serverUpdatedAt = const Value.absent(),
    String? syncStatus,
    int? localVersion,
    int? isDeleted,
  }) => InvoicesTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone ?? this.customerPhone,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    date: date ?? this.date,
    dueDate: dueDate ?? this.dueDate,
    status: status ?? this.status,
    docType: docType ?? this.docType,
    subtotal: subtotal ?? this.subtotal,
    discountAmount: discountAmount ?? this.discountAmount,
    tax: tax ?? this.tax,
    total: total ?? this.total,
    amountPaid: amountPaid ?? this.amountPaid,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paymentAccountId: paymentAccountId ?? this.paymentAccountId,
    note: note ?? this.note,
    createdBy: createdBy ?? this.createdBy,
    hasReturn: hasReturn ?? this.hasReturn,
    returnedAmount: returnedAmount ?? this.returnedAmount,
    creditNoteNumber: creditNoteNumber ?? this.creditNoteNumber,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    localVersion: localVersion ?? this.localVersion,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  InvoicesTableData copyWithCompanion(InvoicesTableCompanion data) {
    return InvoicesTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerPhone: data.customerPhone.present
          ? data.customerPhone.value
          : this.customerPhone,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      date: data.date.present ? data.date.value : this.date,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      status: data.status.present ? data.status.value : this.status,
      docType: data.docType.present ? data.docType.value : this.docType,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      tax: data.tax.present ? data.tax.value : this.tax,
      total: data.total.present ? data.total.value : this.total,
      amountPaid: data.amountPaid.present
          ? data.amountPaid.value
          : this.amountPaid,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      paymentAccountId: data.paymentAccountId.present
          ? data.paymentAccountId.value
          : this.paymentAccountId,
      note: data.note.present ? data.note.value : this.note,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      hasReturn: data.hasReturn.present ? data.hasReturn.value : this.hasReturn,
      returnedAmount: data.returnedAmount.present
          ? data.returnedAmount.value
          : this.returnedAmount,
      creditNoteNumber: data.creditNoteNumber.present
          ? data.creditNoteNumber.value
          : this.creditNoteNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      localVersion: data.localVersion.present
          ? data.localVersion.value
          : this.localVersion,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoicesTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('date: $date, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('docType: $docType, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('tax: $tax, ')
          ..write('total: $total, ')
          ..write('amountPaid: $amountPaid, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentAccountId: $paymentAccountId, ')
          ..write('note: $note, ')
          ..write('createdBy: $createdBy, ')
          ..write('hasReturn: $hasReturn, ')
          ..write('returnedAmount: $returnedAmount, ')
          ..write('creditNoteNumber: $creditNoteNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localVersion: $localVersion, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    businessId,
    customerId,
    customerName,
    customerPhone,
    invoiceNumber,
    date,
    dueDate,
    status,
    docType,
    subtotal,
    discountAmount,
    tax,
    total,
    amountPaid,
    paymentMethod,
    paymentAccountId,
    note,
    createdBy,
    hasReturn,
    returnedAmount,
    creditNoteNumber,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    localVersion,
    isDeleted,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoicesTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName &&
          other.customerPhone == this.customerPhone &&
          other.invoiceNumber == this.invoiceNumber &&
          other.date == this.date &&
          other.dueDate == this.dueDate &&
          other.status == this.status &&
          other.docType == this.docType &&
          other.subtotal == this.subtotal &&
          other.discountAmount == this.discountAmount &&
          other.tax == this.tax &&
          other.total == this.total &&
          other.amountPaid == this.amountPaid &&
          other.paymentMethod == this.paymentMethod &&
          other.paymentAccountId == this.paymentAccountId &&
          other.note == this.note &&
          other.createdBy == this.createdBy &&
          other.hasReturn == this.hasReturn &&
          other.returnedAmount == this.returnedAmount &&
          other.creditNoteNumber == this.creditNoteNumber &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.syncStatus == this.syncStatus &&
          other.localVersion == this.localVersion &&
          other.isDeleted == this.isDeleted);
}

class InvoicesTableCompanion extends UpdateCompanion<InvoicesTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> customerId;
  final Value<String> customerName;
  final Value<String> customerPhone;
  final Value<String> invoiceNumber;
  final Value<String> date;
  final Value<String> dueDate;
  final Value<String> status;
  final Value<String> docType;
  final Value<double> subtotal;
  final Value<double> discountAmount;
  final Value<double> tax;
  final Value<double> total;
  final Value<double> amountPaid;
  final Value<String> paymentMethod;
  final Value<String> paymentAccountId;
  final Value<String> note;
  final Value<String> createdBy;
  final Value<int> hasReturn;
  final Value<double> returnedAmount;
  final Value<String> creditNoteNumber;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> serverUpdatedAt;
  final Value<String> syncStatus;
  final Value<int> localVersion;
  final Value<int> isDeleted;
  final Value<int> rowid;
  const InvoicesTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.date = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.docType = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.tax = const Value.absent(),
    this.total = const Value.absent(),
    this.amountPaid = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.paymentAccountId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.hasReturn = const Value.absent(),
    this.returnedAmount = const Value.absent(),
    this.creditNoteNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoicesTableCompanion.insert({
    required String id,
    required String businessId,
    required String customerId,
    required String customerName,
    this.customerPhone = const Value.absent(),
    required String invoiceNumber,
    required String date,
    required String dueDate,
    this.status = const Value.absent(),
    this.docType = const Value.absent(),
    required double subtotal,
    this.discountAmount = const Value.absent(),
    required double tax,
    required double total,
    this.amountPaid = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.paymentAccountId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.hasReturn = const Value.absent(),
    this.returnedAmount = const Value.absent(),
    this.creditNoteNumber = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       customerId = Value(customerId),
       customerName = Value(customerName),
       invoiceNumber = Value(invoiceNumber),
       date = Value(date),
       dueDate = Value(dueDate),
       subtotal = Value(subtotal),
       tax = Value(tax),
       total = Value(total),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<InvoicesTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? customerId,
    Expression<String>? customerName,
    Expression<String>? customerPhone,
    Expression<String>? invoiceNumber,
    Expression<String>? date,
    Expression<String>? dueDate,
    Expression<String>? status,
    Expression<String>? docType,
    Expression<double>? subtotal,
    Expression<double>? discountAmount,
    Expression<double>? tax,
    Expression<double>? total,
    Expression<double>? amountPaid,
    Expression<String>? paymentMethod,
    Expression<String>? paymentAccountId,
    Expression<String>? note,
    Expression<String>? createdBy,
    Expression<int>? hasReturn,
    Expression<double>? returnedAmount,
    Expression<String>? creditNoteNumber,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? serverUpdatedAt,
    Expression<String>? syncStatus,
    Expression<int>? localVersion,
    Expression<int>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (date != null) 'date': date,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (docType != null) 'doc_type': docType,
      if (subtotal != null) 'subtotal': subtotal,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (tax != null) 'tax': tax,
      if (total != null) 'total': total,
      if (amountPaid != null) 'amount_paid': amountPaid,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (paymentAccountId != null) 'payment_account_id': paymentAccountId,
      if (note != null) 'note': note,
      if (createdBy != null) 'created_by': createdBy,
      if (hasReturn != null) 'has_return': hasReturn,
      if (returnedAmount != null) 'returned_amount': returnedAmount,
      if (creditNoteNumber != null) 'credit_note_number': creditNoteNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localVersion != null) 'local_version': localVersion,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoicesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? customerId,
    Value<String>? customerName,
    Value<String>? customerPhone,
    Value<String>? invoiceNumber,
    Value<String>? date,
    Value<String>? dueDate,
    Value<String>? status,
    Value<String>? docType,
    Value<double>? subtotal,
    Value<double>? discountAmount,
    Value<double>? tax,
    Value<double>? total,
    Value<double>? amountPaid,
    Value<String>? paymentMethod,
    Value<String>? paymentAccountId,
    Value<String>? note,
    Value<String>? createdBy,
    Value<int>? hasReturn,
    Value<double>? returnedAmount,
    Value<String>? creditNoteNumber,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? serverUpdatedAt,
    Value<String>? syncStatus,
    Value<int>? localVersion,
    Value<int>? isDeleted,
    Value<int>? rowid,
  }) {
    return InvoicesTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      docType: docType ?? this.docType,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentAccountId: paymentAccountId ?? this.paymentAccountId,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      hasReturn: hasReturn ?? this.hasReturn,
      returnedAmount: returnedAmount ?? this.returnedAmount,
      creditNoteNumber: creditNoteNumber ?? this.creditNoteNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      localVersion: localVersion ?? this.localVersion,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerPhone.present) {
      map['customer_phone'] = Variable<String>(customerPhone.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (docType.present) {
      map['doc_type'] = Variable<String>(docType.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (tax.present) {
      map['tax'] = Variable<double>(tax.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (amountPaid.present) {
      map['amount_paid'] = Variable<double>(amountPaid.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (paymentAccountId.present) {
      map['payment_account_id'] = Variable<String>(paymentAccountId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (hasReturn.present) {
      map['has_return'] = Variable<int>(hasReturn.value);
    }
    if (returnedAmount.present) {
      map['returned_amount'] = Variable<double>(returnedAmount.value);
    }
    if (creditNoteNumber.present) {
      map['credit_note_number'] = Variable<String>(creditNoteNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (localVersion.present) {
      map['local_version'] = Variable<int>(localVersion.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoicesTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('date: $date, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('docType: $docType, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('tax: $tax, ')
          ..write('total: $total, ')
          ..write('amountPaid: $amountPaid, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentAccountId: $paymentAccountId, ')
          ..write('note: $note, ')
          ..write('createdBy: $createdBy, ')
          ..write('hasReturn: $hasReturn, ')
          ..write('returnedAmount: $returnedAmount, ')
          ..write('creditNoteNumber: $creditNoteNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localVersion: $localVersion, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvoiceItemsTableTable extends InvoiceItemsTable
    with TableInfo<$InvoiceItemsTableTable, InvoiceItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoiceItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES invoices (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    invoiceId,
    name,
    description,
    quantity,
    unitPrice,
    total,
    productId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoice_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvoiceItemsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceItemsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceItemsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
    );
  }

  @override
  $InvoiceItemsTableTable createAlias(String alias) {
    return $InvoiceItemsTableTable(attachedDatabase, alias);
  }
}

class InvoiceItemsTableData extends DataClass
    implements Insertable<InvoiceItemsTableData> {
  final String id;
  final String invoiceId;
  final String name;
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;
  final String productId;
  const InvoiceItemsTableData({
    required this.id,
    required this.invoiceId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.productId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['invoice_id'] = Variable<String>(invoiceId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['quantity'] = Variable<double>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    map['total'] = Variable<double>(total);
    map['product_id'] = Variable<String>(productId);
    return map;
  }

  InvoiceItemsTableCompanion toCompanion(bool nullToAbsent) {
    return InvoiceItemsTableCompanion(
      id: Value(id),
      invoiceId: Value(invoiceId),
      name: Value(name),
      description: Value(description),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      total: Value(total),
      productId: Value(productId),
    );
  }

  factory InvoiceItemsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceItemsTableData(
      id: serializer.fromJson<String>(json['id']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      total: serializer.fromJson<double>(json['total']),
      productId: serializer.fromJson<String>(json['productId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'quantity': serializer.toJson<double>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'total': serializer.toJson<double>(total),
      'productId': serializer.toJson<String>(productId),
    };
  }

  InvoiceItemsTableData copyWith({
    String? id,
    String? invoiceId,
    String? name,
    String? description,
    double? quantity,
    double? unitPrice,
    double? total,
    String? productId,
  }) => InvoiceItemsTableData(
    id: id ?? this.id,
    invoiceId: invoiceId ?? this.invoiceId,
    name: name ?? this.name,
    description: description ?? this.description,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    total: total ?? this.total,
    productId: productId ?? this.productId,
  );
  InvoiceItemsTableData copyWithCompanion(InvoiceItemsTableCompanion data) {
    return InvoiceItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      total: data.total.present ? data.total.value : this.total,
      productId: data.productId.present ? data.productId.value : this.productId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItemsTableData(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('total: $total, ')
          ..write('productId: $productId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    invoiceId,
    name,
    description,
    quantity,
    unitPrice,
    total,
    productId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceItemsTableData &&
          other.id == this.id &&
          other.invoiceId == this.invoiceId &&
          other.name == this.name &&
          other.description == this.description &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.total == this.total &&
          other.productId == this.productId);
}

class InvoiceItemsTableCompanion
    extends UpdateCompanion<InvoiceItemsTableData> {
  final Value<String> id;
  final Value<String> invoiceId;
  final Value<String> name;
  final Value<String> description;
  final Value<double> quantity;
  final Value<double> unitPrice;
  final Value<double> total;
  final Value<String> productId;
  final Value<int> rowid;
  const InvoiceItemsTableCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.total = const Value.absent(),
    this.productId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoiceItemsTableCompanion.insert({
    required String id,
    required String invoiceId,
    required String name,
    this.description = const Value.absent(),
    required double quantity,
    required double unitPrice,
    required double total,
    this.productId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       invoiceId = Value(invoiceId),
       name = Value(name),
       quantity = Value(quantity),
       unitPrice = Value(unitPrice),
       total = Value(total);
  static Insertable<InvoiceItemsTableData> custom({
    Expression<String>? id,
    Expression<String>? invoiceId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? quantity,
    Expression<double>? unitPrice,
    Expression<double>? total,
    Expression<String>? productId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (total != null) 'total': total,
      if (productId != null) 'product_id': productId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoiceItemsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? invoiceId,
    Value<String>? name,
    Value<String>? description,
    Value<double>? quantity,
    Value<double>? unitPrice,
    Value<double>? total,
    Value<String>? productId,
    Value<int>? rowid,
  }) {
    return InvoiceItemsTableCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      productId: productId ?? this.productId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('total: $total, ')
          ..write('productId: $productId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomersTableTable extends CustomersTable
    with TableInfo<$CustomersTableTable, CustomersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastTransactionDateMeta =
      const VerificationMeta('lastTransactionDate');
  @override
  late final GeneratedColumn<String> lastTransactionDate =
      GeneratedColumn<String>(
        'last_transaction_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _isOrganisationMeta = const VerificationMeta(
    'isOrganisation',
  );
  @override
  late final GeneratedColumn<int> isOrganisation = GeneratedColumn<int>(
    'is_organisation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tinNumberMeta = const VerificationMeta(
    'tinNumber',
  );
  @override
  late final GeneratedColumn<String> tinNumber = GeneratedColumn<String>(
    'tin_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<double> creditLimit = GeneratedColumn<double>(
    'credit_limit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _assignedToUserIdMeta = const VerificationMeta(
    'assignedToUserId',
  );
  @override
  late final GeneratedColumn<String> assignedToUserId = GeneratedColumn<String>(
    'assigned_to_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> serverUpdatedAt = GeneratedColumn<int>(
    'server_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_create'),
  );
  static const VerificationMeta _localVersionMeta = const VerificationMeta(
    'localVersion',
  );
  @override
  late final GeneratedColumn<int> localVersion = GeneratedColumn<int>(
    'local_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    phone,
    email,
    balance,
    lastTransactionDate,
    tags,
    isOrganisation,
    tinNumber,
    address,
    creditLimit,
    createdBy,
    assignedToUserId,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    localVersion,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    }
    if (data.containsKey('last_transaction_date')) {
      context.handle(
        _lastTransactionDateMeta,
        lastTransactionDate.isAcceptableOrUnknown(
          data['last_transaction_date']!,
          _lastTransactionDateMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('is_organisation')) {
      context.handle(
        _isOrganisationMeta,
        isOrganisation.isAcceptableOrUnknown(
          data['is_organisation']!,
          _isOrganisationMeta,
        ),
      );
    }
    if (data.containsKey('tin_number')) {
      context.handle(
        _tinNumberMeta,
        tinNumber.isAcceptableOrUnknown(data['tin_number']!, _tinNumberMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('assigned_to_user_id')) {
      context.handle(
        _assignedToUserIdMeta,
        assignedToUserId.isAcceptableOrUnknown(
          data['assigned_to_user_id']!,
          _assignedToUserIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('local_version')) {
      context.handle(
        _localVersionMeta,
        localVersion.isAcceptableOrUnknown(
          data['local_version']!,
          _localVersionMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance'],
      )!,
      lastTransactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_transaction_date'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      isOrganisation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_organisation'],
      )!,
      tinNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tin_number'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}credit_limit'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      assignedToUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_to_user_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_updated_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      localVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_version'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $CustomersTableTable createAlias(String alias) {
    return $CustomersTableTable(attachedDatabase, alias);
  }
}

class CustomersTableData extends DataClass
    implements Insertable<CustomersTableData> {
  final String id;
  final String businessId;
  final String name;
  final String phone;
  final String email;
  final double balance;
  final String lastTransactionDate;
  final String tags;
  final int isOrganisation;
  final String tinNumber;
  final String address;
  final double creditLimit;
  final String createdBy;
  final String assignedToUserId;
  final int createdAt;
  final int updatedAt;
  final int? serverUpdatedAt;
  final String syncStatus;
  final int localVersion;
  final int isDeleted;
  const CustomersTableData({
    required this.id,
    required this.businessId,
    required this.name,
    required this.phone,
    required this.email,
    required this.balance,
    required this.lastTransactionDate,
    required this.tags,
    required this.isOrganisation,
    required this.tinNumber,
    required this.address,
    required this.creditLimit,
    required this.createdBy,
    required this.assignedToUserId,
    required this.createdAt,
    required this.updatedAt,
    this.serverUpdatedAt,
    required this.syncStatus,
    required this.localVersion,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['email'] = Variable<String>(email);
    map['balance'] = Variable<double>(balance);
    map['last_transaction_date'] = Variable<String>(lastTransactionDate);
    map['tags'] = Variable<String>(tags);
    map['is_organisation'] = Variable<int>(isOrganisation);
    map['tin_number'] = Variable<String>(tinNumber);
    map['address'] = Variable<String>(address);
    map['credit_limit'] = Variable<double>(creditLimit);
    map['created_by'] = Variable<String>(createdBy);
    map['assigned_to_user_id'] = Variable<String>(assignedToUserId);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['local_version'] = Variable<int>(localVersion);
    map['is_deleted'] = Variable<int>(isDeleted);
    return map;
  }

  CustomersTableCompanion toCompanion(bool nullToAbsent) {
    return CustomersTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      phone: Value(phone),
      email: Value(email),
      balance: Value(balance),
      lastTransactionDate: Value(lastTransactionDate),
      tags: Value(tags),
      isOrganisation: Value(isOrganisation),
      tinNumber: Value(tinNumber),
      address: Value(address),
      creditLimit: Value(creditLimit),
      createdBy: Value(createdBy),
      assignedToUserId: Value(assignedToUserId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      localVersion: Value(localVersion),
      isDeleted: Value(isDeleted),
    );
  }

  factory CustomersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomersTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      email: serializer.fromJson<String>(json['email']),
      balance: serializer.fromJson<double>(json['balance']),
      lastTransactionDate: serializer.fromJson<String>(
        json['lastTransactionDate'],
      ),
      tags: serializer.fromJson<String>(json['tags']),
      isOrganisation: serializer.fromJson<int>(json['isOrganisation']),
      tinNumber: serializer.fromJson<String>(json['tinNumber']),
      address: serializer.fromJson<String>(json['address']),
      creditLimit: serializer.fromJson<double>(json['creditLimit']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      assignedToUserId: serializer.fromJson<String>(json['assignedToUserId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      serverUpdatedAt: serializer.fromJson<int?>(json['serverUpdatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      localVersion: serializer.fromJson<int>(json['localVersion']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'email': serializer.toJson<String>(email),
      'balance': serializer.toJson<double>(balance),
      'lastTransactionDate': serializer.toJson<String>(lastTransactionDate),
      'tags': serializer.toJson<String>(tags),
      'isOrganisation': serializer.toJson<int>(isOrganisation),
      'tinNumber': serializer.toJson<String>(tinNumber),
      'address': serializer.toJson<String>(address),
      'creditLimit': serializer.toJson<double>(creditLimit),
      'createdBy': serializer.toJson<String>(createdBy),
      'assignedToUserId': serializer.toJson<String>(assignedToUserId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'serverUpdatedAt': serializer.toJson<int?>(serverUpdatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'localVersion': serializer.toJson<int>(localVersion),
      'isDeleted': serializer.toJson<int>(isDeleted),
    };
  }

  CustomersTableData copyWith({
    String? id,
    String? businessId,
    String? name,
    String? phone,
    String? email,
    double? balance,
    String? lastTransactionDate,
    String? tags,
    int? isOrganisation,
    String? tinNumber,
    String? address,
    double? creditLimit,
    String? createdBy,
    String? assignedToUserId,
    int? createdAt,
    int? updatedAt,
    Value<int?> serverUpdatedAt = const Value.absent(),
    String? syncStatus,
    int? localVersion,
    int? isDeleted,
  }) => CustomersTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    balance: balance ?? this.balance,
    lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
    tags: tags ?? this.tags,
    isOrganisation: isOrganisation ?? this.isOrganisation,
    tinNumber: tinNumber ?? this.tinNumber,
    address: address ?? this.address,
    creditLimit: creditLimit ?? this.creditLimit,
    createdBy: createdBy ?? this.createdBy,
    assignedToUserId: assignedToUserId ?? this.assignedToUserId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    localVersion: localVersion ?? this.localVersion,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  CustomersTableData copyWithCompanion(CustomersTableCompanion data) {
    return CustomersTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      balance: data.balance.present ? data.balance.value : this.balance,
      lastTransactionDate: data.lastTransactionDate.present
          ? data.lastTransactionDate.value
          : this.lastTransactionDate,
      tags: data.tags.present ? data.tags.value : this.tags,
      isOrganisation: data.isOrganisation.present
          ? data.isOrganisation.value
          : this.isOrganisation,
      tinNumber: data.tinNumber.present ? data.tinNumber.value : this.tinNumber,
      address: data.address.present ? data.address.value : this.address,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      assignedToUserId: data.assignedToUserId.present
          ? data.assignedToUserId.value
          : this.assignedToUserId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      localVersion: data.localVersion.present
          ? data.localVersion.value
          : this.localVersion,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomersTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('balance: $balance, ')
          ..write('lastTransactionDate: $lastTransactionDate, ')
          ..write('tags: $tags, ')
          ..write('isOrganisation: $isOrganisation, ')
          ..write('tinNumber: $tinNumber, ')
          ..write('address: $address, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('createdBy: $createdBy, ')
          ..write('assignedToUserId: $assignedToUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localVersion: $localVersion, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    phone,
    email,
    balance,
    lastTransactionDate,
    tags,
    isOrganisation,
    tinNumber,
    address,
    creditLimit,
    createdBy,
    assignedToUserId,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    localVersion,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomersTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.balance == this.balance &&
          other.lastTransactionDate == this.lastTransactionDate &&
          other.tags == this.tags &&
          other.isOrganisation == this.isOrganisation &&
          other.tinNumber == this.tinNumber &&
          other.address == this.address &&
          other.creditLimit == this.creditLimit &&
          other.createdBy == this.createdBy &&
          other.assignedToUserId == this.assignedToUserId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.syncStatus == this.syncStatus &&
          other.localVersion == this.localVersion &&
          other.isDeleted == this.isDeleted);
}

class CustomersTableCompanion extends UpdateCompanion<CustomersTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String> phone;
  final Value<String> email;
  final Value<double> balance;
  final Value<String> lastTransactionDate;
  final Value<String> tags;
  final Value<int> isOrganisation;
  final Value<String> tinNumber;
  final Value<String> address;
  final Value<double> creditLimit;
  final Value<String> createdBy;
  final Value<String> assignedToUserId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> serverUpdatedAt;
  final Value<String> syncStatus;
  final Value<int> localVersion;
  final Value<int> isDeleted;
  final Value<int> rowid;
  const CustomersTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.balance = const Value.absent(),
    this.lastTransactionDate = const Value.absent(),
    this.tags = const Value.absent(),
    this.isOrganisation = const Value.absent(),
    this.tinNumber = const Value.absent(),
    this.address = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.assignedToUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersTableCompanion.insert({
    required String id,
    required String businessId,
    required String name,
    required String phone,
    this.email = const Value.absent(),
    this.balance = const Value.absent(),
    this.lastTransactionDate = const Value.absent(),
    this.tags = const Value.absent(),
    this.isOrganisation = const Value.absent(),
    this.tinNumber = const Value.absent(),
    this.address = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.assignedToUserId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name),
       phone = Value(phone),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CustomersTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<double>? balance,
    Expression<String>? lastTransactionDate,
    Expression<String>? tags,
    Expression<int>? isOrganisation,
    Expression<String>? tinNumber,
    Expression<String>? address,
    Expression<double>? creditLimit,
    Expression<String>? createdBy,
    Expression<String>? assignedToUserId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? serverUpdatedAt,
    Expression<String>? syncStatus,
    Expression<int>? localVersion,
    Expression<int>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (balance != null) 'balance': balance,
      if (lastTransactionDate != null)
        'last_transaction_date': lastTransactionDate,
      if (tags != null) 'tags': tags,
      if (isOrganisation != null) 'is_organisation': isOrganisation,
      if (tinNumber != null) 'tin_number': tinNumber,
      if (address != null) 'address': address,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (createdBy != null) 'created_by': createdBy,
      if (assignedToUserId != null) 'assigned_to_user_id': assignedToUserId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localVersion != null) 'local_version': localVersion,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<String>? phone,
    Value<String>? email,
    Value<double>? balance,
    Value<String>? lastTransactionDate,
    Value<String>? tags,
    Value<int>? isOrganisation,
    Value<String>? tinNumber,
    Value<String>? address,
    Value<double>? creditLimit,
    Value<String>? createdBy,
    Value<String>? assignedToUserId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? serverUpdatedAt,
    Value<String>? syncStatus,
    Value<int>? localVersion,
    Value<int>? isDeleted,
    Value<int>? rowid,
  }) {
    return CustomersTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      tags: tags ?? this.tags,
      isOrganisation: isOrganisation ?? this.isOrganisation,
      tinNumber: tinNumber ?? this.tinNumber,
      address: address ?? this.address,
      creditLimit: creditLimit ?? this.creditLimit,
      createdBy: createdBy ?? this.createdBy,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      localVersion: localVersion ?? this.localVersion,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (lastTransactionDate.present) {
      map['last_transaction_date'] = Variable<String>(
        lastTransactionDate.value,
      );
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (isOrganisation.present) {
      map['is_organisation'] = Variable<int>(isOrganisation.value);
    }
    if (tinNumber.present) {
      map['tin_number'] = Variable<String>(tinNumber.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<double>(creditLimit.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (assignedToUserId.present) {
      map['assigned_to_user_id'] = Variable<String>(assignedToUserId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (localVersion.present) {
      map['local_version'] = Variable<int>(localVersion.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('balance: $balance, ')
          ..write('lastTransactionDate: $lastTransactionDate, ')
          ..write('tags: $tags, ')
          ..write('isOrganisation: $isOrganisation, ')
          ..write('tinNumber: $tinNumber, ')
          ..write('address: $address, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('createdBy: $createdBy, ')
          ..write('assignedToUserId: $assignedToUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localVersion: $localVersion, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTableTable extends ExpensesTable
    with TableInfo<$ExpensesTableTable, ExpensesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _recipientMeta = const VerificationMeta(
    'recipient',
  );
  @override
  late final GeneratedColumn<String> recipient = GeneratedColumn<String>(
    'recipient',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isRecurringMeta = const VerificationMeta(
    'isRecurring',
  );
  @override
  late final GeneratedColumn<int> isRecurring = GeneratedColumn<int>(
    'is_recurring',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _recurrenceTypeMeta = const VerificationMeta(
    'recurrenceType',
  );
  @override
  late final GeneratedColumn<String> recurrenceType = GeneratedColumn<String>(
    'recurrence_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nextDueDateMeta = const VerificationMeta(
    'nextDueDate',
  );
  @override
  late final GeneratedColumn<String> nextDueDate = GeneratedColumn<String>(
    'next_due_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _receiptUrlMeta = const VerificationMeta(
    'receiptUrl',
  );
  @override
  late final GeneratedColumn<String> receiptUrl = GeneratedColumn<String>(
    'receipt_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _paymentAccountIdMeta = const VerificationMeta(
    'paymentAccountId',
  );
  @override
  late final GeneratedColumn<String> paymentAccountId = GeneratedColumn<String>(
    'payment_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('approved'),
  );
  static const VerificationMeta _approvedByMeta = const VerificationMeta(
    'approvedBy',
  );
  @override
  late final GeneratedColumn<String> approvedBy = GeneratedColumn<String>(
    'approved_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> serverUpdatedAt = GeneratedColumn<int>(
    'server_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_create'),
  );
  static const VerificationMeta _localVersionMeta = const VerificationMeta(
    'localVersion',
  );
  @override
  late final GeneratedColumn<int> localVersion = GeneratedColumn<int>(
    'local_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    category,
    amount,
    date,
    note,
    recipient,
    isRecurring,
    recurrenceType,
    nextDueDate,
    templateId,
    receiptUrl,
    paymentMethod,
    paymentAccountId,
    status,
    approvedBy,
    createdBy,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    localVersion,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpensesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('recipient')) {
      context.handle(
        _recipientMeta,
        recipient.isAcceptableOrUnknown(data['recipient']!, _recipientMeta),
      );
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
        _isRecurringMeta,
        isRecurring.isAcceptableOrUnknown(
          data['is_recurring']!,
          _isRecurringMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_type')) {
      context.handle(
        _recurrenceTypeMeta,
        recurrenceType.isAcceptableOrUnknown(
          data['recurrence_type']!,
          _recurrenceTypeMeta,
        ),
      );
    }
    if (data.containsKey('next_due_date')) {
      context.handle(
        _nextDueDateMeta,
        nextDueDate.isAcceptableOrUnknown(
          data['next_due_date']!,
          _nextDueDateMeta,
        ),
      );
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('receipt_url')) {
      context.handle(
        _receiptUrlMeta,
        receiptUrl.isAcceptableOrUnknown(data['receipt_url']!, _receiptUrlMeta),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('payment_account_id')) {
      context.handle(
        _paymentAccountIdMeta,
        paymentAccountId.isAcceptableOrUnknown(
          data['payment_account_id']!,
          _paymentAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('approved_by')) {
      context.handle(
        _approvedByMeta,
        approvedBy.isAcceptableOrUnknown(data['approved_by']!, _approvedByMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('local_version')) {
      context.handle(
        _localVersionMeta,
        localVersion.isAcceptableOrUnknown(
          data['local_version']!,
          _localVersionMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpensesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpensesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      recipient: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient'],
      )!,
      isRecurring: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_recurring'],
      )!,
      recurrenceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_type'],
      )!,
      nextDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_due_date'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      receiptUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_url'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      paymentAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_account_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      approvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_updated_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      localVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_version'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $ExpensesTableTable createAlias(String alias) {
    return $ExpensesTableTable(attachedDatabase, alias);
  }
}

class ExpensesTableData extends DataClass
    implements Insertable<ExpensesTableData> {
  final String id;
  final String businessId;
  final String category;
  final double amount;
  final String date;
  final String note;
  final String recipient;
  final int isRecurring;
  final String recurrenceType;
  final String nextDueDate;
  final String templateId;
  final String receiptUrl;
  final String paymentMethod;
  final String paymentAccountId;
  final String status;
  final String approvedBy;
  final String createdBy;
  final int createdAt;
  final int updatedAt;
  final int? serverUpdatedAt;
  final String syncStatus;
  final int localVersion;
  final int isDeleted;
  const ExpensesTableData({
    required this.id,
    required this.businessId,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
    required this.recipient,
    required this.isRecurring,
    required this.recurrenceType,
    required this.nextDueDate,
    required this.templateId,
    required this.receiptUrl,
    required this.paymentMethod,
    required this.paymentAccountId,
    required this.status,
    required this.approvedBy,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.serverUpdatedAt,
    required this.syncStatus,
    required this.localVersion,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['category'] = Variable<String>(category);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<String>(date);
    map['note'] = Variable<String>(note);
    map['recipient'] = Variable<String>(recipient);
    map['is_recurring'] = Variable<int>(isRecurring);
    map['recurrence_type'] = Variable<String>(recurrenceType);
    map['next_due_date'] = Variable<String>(nextDueDate);
    map['template_id'] = Variable<String>(templateId);
    map['receipt_url'] = Variable<String>(receiptUrl);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['payment_account_id'] = Variable<String>(paymentAccountId);
    map['status'] = Variable<String>(status);
    map['approved_by'] = Variable<String>(approvedBy);
    map['created_by'] = Variable<String>(createdBy);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['local_version'] = Variable<int>(localVersion);
    map['is_deleted'] = Variable<int>(isDeleted);
    return map;
  }

  ExpensesTableCompanion toCompanion(bool nullToAbsent) {
    return ExpensesTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      category: Value(category),
      amount: Value(amount),
      date: Value(date),
      note: Value(note),
      recipient: Value(recipient),
      isRecurring: Value(isRecurring),
      recurrenceType: Value(recurrenceType),
      nextDueDate: Value(nextDueDate),
      templateId: Value(templateId),
      receiptUrl: Value(receiptUrl),
      paymentMethod: Value(paymentMethod),
      paymentAccountId: Value(paymentAccountId),
      status: Value(status),
      approvedBy: Value(approvedBy),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      localVersion: Value(localVersion),
      isDeleted: Value(isDeleted),
    );
  }

  factory ExpensesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpensesTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      category: serializer.fromJson<String>(json['category']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<String>(json['date']),
      note: serializer.fromJson<String>(json['note']),
      recipient: serializer.fromJson<String>(json['recipient']),
      isRecurring: serializer.fromJson<int>(json['isRecurring']),
      recurrenceType: serializer.fromJson<String>(json['recurrenceType']),
      nextDueDate: serializer.fromJson<String>(json['nextDueDate']),
      templateId: serializer.fromJson<String>(json['templateId']),
      receiptUrl: serializer.fromJson<String>(json['receiptUrl']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      paymentAccountId: serializer.fromJson<String>(json['paymentAccountId']),
      status: serializer.fromJson<String>(json['status']),
      approvedBy: serializer.fromJson<String>(json['approvedBy']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      serverUpdatedAt: serializer.fromJson<int?>(json['serverUpdatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      localVersion: serializer.fromJson<int>(json['localVersion']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'category': serializer.toJson<String>(category),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<String>(date),
      'note': serializer.toJson<String>(note),
      'recipient': serializer.toJson<String>(recipient),
      'isRecurring': serializer.toJson<int>(isRecurring),
      'recurrenceType': serializer.toJson<String>(recurrenceType),
      'nextDueDate': serializer.toJson<String>(nextDueDate),
      'templateId': serializer.toJson<String>(templateId),
      'receiptUrl': serializer.toJson<String>(receiptUrl),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'paymentAccountId': serializer.toJson<String>(paymentAccountId),
      'status': serializer.toJson<String>(status),
      'approvedBy': serializer.toJson<String>(approvedBy),
      'createdBy': serializer.toJson<String>(createdBy),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'serverUpdatedAt': serializer.toJson<int?>(serverUpdatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'localVersion': serializer.toJson<int>(localVersion),
      'isDeleted': serializer.toJson<int>(isDeleted),
    };
  }

  ExpensesTableData copyWith({
    String? id,
    String? businessId,
    String? category,
    double? amount,
    String? date,
    String? note,
    String? recipient,
    int? isRecurring,
    String? recurrenceType,
    String? nextDueDate,
    String? templateId,
    String? receiptUrl,
    String? paymentMethod,
    String? paymentAccountId,
    String? status,
    String? approvedBy,
    String? createdBy,
    int? createdAt,
    int? updatedAt,
    Value<int?> serverUpdatedAt = const Value.absent(),
    String? syncStatus,
    int? localVersion,
    int? isDeleted,
  }) => ExpensesTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    note: note ?? this.note,
    recipient: recipient ?? this.recipient,
    isRecurring: isRecurring ?? this.isRecurring,
    recurrenceType: recurrenceType ?? this.recurrenceType,
    nextDueDate: nextDueDate ?? this.nextDueDate,
    templateId: templateId ?? this.templateId,
    receiptUrl: receiptUrl ?? this.receiptUrl,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paymentAccountId: paymentAccountId ?? this.paymentAccountId,
    status: status ?? this.status,
    approvedBy: approvedBy ?? this.approvedBy,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    localVersion: localVersion ?? this.localVersion,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  ExpensesTableData copyWithCompanion(ExpensesTableCompanion data) {
    return ExpensesTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      category: data.category.present ? data.category.value : this.category,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
      recipient: data.recipient.present ? data.recipient.value : this.recipient,
      isRecurring: data.isRecurring.present
          ? data.isRecurring.value
          : this.isRecurring,
      recurrenceType: data.recurrenceType.present
          ? data.recurrenceType.value
          : this.recurrenceType,
      nextDueDate: data.nextDueDate.present
          ? data.nextDueDate.value
          : this.nextDueDate,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      receiptUrl: data.receiptUrl.present
          ? data.receiptUrl.value
          : this.receiptUrl,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      paymentAccountId: data.paymentAccountId.present
          ? data.paymentAccountId.value
          : this.paymentAccountId,
      status: data.status.present ? data.status.value : this.status,
      approvedBy: data.approvedBy.present
          ? data.approvedBy.value
          : this.approvedBy,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      localVersion: data.localVersion.present
          ? data.localVersion.value
          : this.localVersion,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('recipient: $recipient, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('templateId: $templateId, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentAccountId: $paymentAccountId, ')
          ..write('status: $status, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localVersion: $localVersion, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    businessId,
    category,
    amount,
    date,
    note,
    recipient,
    isRecurring,
    recurrenceType,
    nextDueDate,
    templateId,
    receiptUrl,
    paymentMethod,
    paymentAccountId,
    status,
    approvedBy,
    createdBy,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    localVersion,
    isDeleted,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpensesTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.category == this.category &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.note == this.note &&
          other.recipient == this.recipient &&
          other.isRecurring == this.isRecurring &&
          other.recurrenceType == this.recurrenceType &&
          other.nextDueDate == this.nextDueDate &&
          other.templateId == this.templateId &&
          other.receiptUrl == this.receiptUrl &&
          other.paymentMethod == this.paymentMethod &&
          other.paymentAccountId == this.paymentAccountId &&
          other.status == this.status &&
          other.approvedBy == this.approvedBy &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.syncStatus == this.syncStatus &&
          other.localVersion == this.localVersion &&
          other.isDeleted == this.isDeleted);
}

class ExpensesTableCompanion extends UpdateCompanion<ExpensesTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> category;
  final Value<double> amount;
  final Value<String> date;
  final Value<String> note;
  final Value<String> recipient;
  final Value<int> isRecurring;
  final Value<String> recurrenceType;
  final Value<String> nextDueDate;
  final Value<String> templateId;
  final Value<String> receiptUrl;
  final Value<String> paymentMethod;
  final Value<String> paymentAccountId;
  final Value<String> status;
  final Value<String> approvedBy;
  final Value<String> createdBy;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> serverUpdatedAt;
  final Value<String> syncStatus;
  final Value<int> localVersion;
  final Value<int> isDeleted;
  final Value<int> rowid;
  const ExpensesTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.category = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.recipient = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurrenceType = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.templateId = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.paymentAccountId = const Value.absent(),
    this.status = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesTableCompanion.insert({
    required String id,
    required String businessId,
    required String category,
    required double amount,
    required String date,
    this.note = const Value.absent(),
    this.recipient = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurrenceType = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.templateId = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.paymentAccountId = const Value.absent(),
    this.status = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.createdBy = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       category = Value(category),
       amount = Value(amount),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ExpensesTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? category,
    Expression<double>? amount,
    Expression<String>? date,
    Expression<String>? note,
    Expression<String>? recipient,
    Expression<int>? isRecurring,
    Expression<String>? recurrenceType,
    Expression<String>? nextDueDate,
    Expression<String>? templateId,
    Expression<String>? receiptUrl,
    Expression<String>? paymentMethod,
    Expression<String>? paymentAccountId,
    Expression<String>? status,
    Expression<String>? approvedBy,
    Expression<String>? createdBy,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? serverUpdatedAt,
    Expression<String>? syncStatus,
    Expression<int>? localVersion,
    Expression<int>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (category != null) 'category': category,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (recipient != null) 'recipient': recipient,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (recurrenceType != null) 'recurrence_type': recurrenceType,
      if (nextDueDate != null) 'next_due_date': nextDueDate,
      if (templateId != null) 'template_id': templateId,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (paymentAccountId != null) 'payment_account_id': paymentAccountId,
      if (status != null) 'status': status,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localVersion != null) 'local_version': localVersion,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? category,
    Value<double>? amount,
    Value<String>? date,
    Value<String>? note,
    Value<String>? recipient,
    Value<int>? isRecurring,
    Value<String>? recurrenceType,
    Value<String>? nextDueDate,
    Value<String>? templateId,
    Value<String>? receiptUrl,
    Value<String>? paymentMethod,
    Value<String>? paymentAccountId,
    Value<String>? status,
    Value<String>? approvedBy,
    Value<String>? createdBy,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? serverUpdatedAt,
    Value<String>? syncStatus,
    Value<int>? localVersion,
    Value<int>? isDeleted,
    Value<int>? rowid,
  }) {
    return ExpensesTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      recipient: recipient ?? this.recipient,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      templateId: templateId ?? this.templateId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentAccountId: paymentAccountId ?? this.paymentAccountId,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      localVersion: localVersion ?? this.localVersion,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (recipient.present) {
      map['recipient'] = Variable<String>(recipient.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<int>(isRecurring.value);
    }
    if (recurrenceType.present) {
      map['recurrence_type'] = Variable<String>(recurrenceType.value);
    }
    if (nextDueDate.present) {
      map['next_due_date'] = Variable<String>(nextDueDate.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (receiptUrl.present) {
      map['receipt_url'] = Variable<String>(receiptUrl.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (paymentAccountId.present) {
      map['payment_account_id'] = Variable<String>(paymentAccountId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (approvedBy.present) {
      map['approved_by'] = Variable<String>(approvedBy.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (localVersion.present) {
      map['local_version'] = Variable<int>(localVersion.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('recipient: $recipient, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurrenceType: $recurrenceType, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('templateId: $templateId, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentAccountId: $paymentAccountId, ')
          ..write('status: $status, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localVersion: $localVersion, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryTableTable extends InventoryTable
    with TableInfo<$InventoryTableTable, InventoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pcs'),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quantityDeltaMeta = const VerificationMeta(
    'quantityDelta',
  );
  @override
  late final GeneratedColumn<double> quantityDelta = GeneratedColumn<double>(
    'quantity_delta',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lowStockThresholdMeta = const VerificationMeta(
    'lowStockThreshold',
  );
  @override
  late final GeneratedColumn<double> lowStockThreshold =
      GeneratedColumn<double>(
        'low_stock_threshold',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _costPriceMeta = const VerificationMeta(
    'costPrice',
  );
  @override
  late final GeneratedColumn<double> costPrice = GeneratedColumn<double>(
    'cost_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<int> isActive = GeneratedColumn<int>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> serverUpdatedAt = GeneratedColumn<int>(
    'server_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_create'),
  );
  static const VerificationMeta _localVersionMeta = const VerificationMeta(
    'localVersion',
  );
  @override
  late final GeneratedColumn<int> localVersion = GeneratedColumn<int>(
    'local_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    sku,
    barcode,
    category,
    unit,
    quantity,
    quantityDelta,
    lowStockThreshold,
    unitPrice,
    costPrice,
    description,
    imageUrl,
    isActive,
    createdBy,
    metadata,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    localVersion,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('quantity_delta')) {
      context.handle(
        _quantityDeltaMeta,
        quantityDelta.isAcceptableOrUnknown(
          data['quantity_delta']!,
          _quantityDeltaMeta,
        ),
      );
    }
    if (data.containsKey('low_stock_threshold')) {
      context.handle(
        _lowStockThresholdMeta,
        lowStockThreshold.isAcceptableOrUnknown(
          data['low_stock_threshold']!,
          _lowStockThresholdMeta,
        ),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    }
    if (data.containsKey('cost_price')) {
      context.handle(
        _costPriceMeta,
        costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('local_version')) {
      context.handle(
        _localVersionMeta,
        localVersion.isAcceptableOrUnknown(
          data['local_version']!,
          _localVersionMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      quantityDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_delta'],
      )!,
      lowStockThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}low_stock_threshold'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      costPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_price'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_active'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_updated_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      localVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_version'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $InventoryTableTable createAlias(String alias) {
    return $InventoryTableTable(attachedDatabase, alias);
  }
}

class InventoryTableData extends DataClass
    implements Insertable<InventoryTableData> {
  final String id;
  final String businessId;
  final String name;
  final String sku;
  final String barcode;
  final String category;
  final String unit;
  final double quantity;
  final double quantityDelta;
  final double lowStockThreshold;
  final double unitPrice;
  final double costPrice;
  final String description;
  final String imageUrl;
  final int isActive;
  final String createdBy;
  final String metadata;
  final int createdAt;
  final int updatedAt;
  final int? serverUpdatedAt;
  final String syncStatus;
  final int localVersion;
  final int isDeleted;
  const InventoryTableData({
    required this.id,
    required this.businessId,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.category,
    required this.unit,
    required this.quantity,
    required this.quantityDelta,
    required this.lowStockThreshold,
    required this.unitPrice,
    required this.costPrice,
    required this.description,
    required this.imageUrl,
    required this.isActive,
    required this.createdBy,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.serverUpdatedAt,
    required this.syncStatus,
    required this.localVersion,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    map['sku'] = Variable<String>(sku);
    map['barcode'] = Variable<String>(barcode);
    map['category'] = Variable<String>(category);
    map['unit'] = Variable<String>(unit);
    map['quantity'] = Variable<double>(quantity);
    map['quantity_delta'] = Variable<double>(quantityDelta);
    map['low_stock_threshold'] = Variable<double>(lowStockThreshold);
    map['unit_price'] = Variable<double>(unitPrice);
    map['cost_price'] = Variable<double>(costPrice);
    map['description'] = Variable<String>(description);
    map['image_url'] = Variable<String>(imageUrl);
    map['is_active'] = Variable<int>(isActive);
    map['created_by'] = Variable<String>(createdBy);
    map['metadata'] = Variable<String>(metadata);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['local_version'] = Variable<int>(localVersion);
    map['is_deleted'] = Variable<int>(isDeleted);
    return map;
  }

  InventoryTableCompanion toCompanion(bool nullToAbsent) {
    return InventoryTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      sku: Value(sku),
      barcode: Value(barcode),
      category: Value(category),
      unit: Value(unit),
      quantity: Value(quantity),
      quantityDelta: Value(quantityDelta),
      lowStockThreshold: Value(lowStockThreshold),
      unitPrice: Value(unitPrice),
      costPrice: Value(costPrice),
      description: Value(description),
      imageUrl: Value(imageUrl),
      isActive: Value(isActive),
      createdBy: Value(createdBy),
      metadata: Value(metadata),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      localVersion: Value(localVersion),
      isDeleted: Value(isDeleted),
    );
  }

  factory InventoryTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      sku: serializer.fromJson<String>(json['sku']),
      barcode: serializer.fromJson<String>(json['barcode']),
      category: serializer.fromJson<String>(json['category']),
      unit: serializer.fromJson<String>(json['unit']),
      quantity: serializer.fromJson<double>(json['quantity']),
      quantityDelta: serializer.fromJson<double>(json['quantityDelta']),
      lowStockThreshold: serializer.fromJson<double>(json['lowStockThreshold']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      costPrice: serializer.fromJson<double>(json['costPrice']),
      description: serializer.fromJson<String>(json['description']),
      imageUrl: serializer.fromJson<String>(json['imageUrl']),
      isActive: serializer.fromJson<int>(json['isActive']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      metadata: serializer.fromJson<String>(json['metadata']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      serverUpdatedAt: serializer.fromJson<int?>(json['serverUpdatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      localVersion: serializer.fromJson<int>(json['localVersion']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'sku': serializer.toJson<String>(sku),
      'barcode': serializer.toJson<String>(barcode),
      'category': serializer.toJson<String>(category),
      'unit': serializer.toJson<String>(unit),
      'quantity': serializer.toJson<double>(quantity),
      'quantityDelta': serializer.toJson<double>(quantityDelta),
      'lowStockThreshold': serializer.toJson<double>(lowStockThreshold),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'costPrice': serializer.toJson<double>(costPrice),
      'description': serializer.toJson<String>(description),
      'imageUrl': serializer.toJson<String>(imageUrl),
      'isActive': serializer.toJson<int>(isActive),
      'createdBy': serializer.toJson<String>(createdBy),
      'metadata': serializer.toJson<String>(metadata),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'serverUpdatedAt': serializer.toJson<int?>(serverUpdatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'localVersion': serializer.toJson<int>(localVersion),
      'isDeleted': serializer.toJson<int>(isDeleted),
    };
  }

  InventoryTableData copyWith({
    String? id,
    String? businessId,
    String? name,
    String? sku,
    String? barcode,
    String? category,
    String? unit,
    double? quantity,
    double? quantityDelta,
    double? lowStockThreshold,
    double? unitPrice,
    double? costPrice,
    String? description,
    String? imageUrl,
    int? isActive,
    String? createdBy,
    String? metadata,
    int? createdAt,
    int? updatedAt,
    Value<int?> serverUpdatedAt = const Value.absent(),
    String? syncStatus,
    int? localVersion,
    int? isDeleted,
  }) => InventoryTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    sku: sku ?? this.sku,
    barcode: barcode ?? this.barcode,
    category: category ?? this.category,
    unit: unit ?? this.unit,
    quantity: quantity ?? this.quantity,
    quantityDelta: quantityDelta ?? this.quantityDelta,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    unitPrice: unitPrice ?? this.unitPrice,
    costPrice: costPrice ?? this.costPrice,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    isActive: isActive ?? this.isActive,
    createdBy: createdBy ?? this.createdBy,
    metadata: metadata ?? this.metadata,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    localVersion: localVersion ?? this.localVersion,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  InventoryTableData copyWithCompanion(InventoryTableCompanion data) {
    return InventoryTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      sku: data.sku.present ? data.sku.value : this.sku,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      category: data.category.present ? data.category.value : this.category,
      unit: data.unit.present ? data.unit.value : this.unit,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      quantityDelta: data.quantityDelta.present
          ? data.quantityDelta.value
          : this.quantityDelta,
      lowStockThreshold: data.lowStockThreshold.present
          ? data.lowStockThreshold.value
          : this.lowStockThreshold,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      description: data.description.present
          ? data.description.value
          : this.description,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      localVersion: data.localVersion.present
          ? data.localVersion.value
          : this.localVersion,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('category: $category, ')
          ..write('unit: $unit, ')
          ..write('quantity: $quantity, ')
          ..write('quantityDelta: $quantityDelta, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('costPrice: $costPrice, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('isActive: $isActive, ')
          ..write('createdBy: $createdBy, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localVersion: $localVersion, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    businessId,
    name,
    sku,
    barcode,
    category,
    unit,
    quantity,
    quantityDelta,
    lowStockThreshold,
    unitPrice,
    costPrice,
    description,
    imageUrl,
    isActive,
    createdBy,
    metadata,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    localVersion,
    isDeleted,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.sku == this.sku &&
          other.barcode == this.barcode &&
          other.category == this.category &&
          other.unit == this.unit &&
          other.quantity == this.quantity &&
          other.quantityDelta == this.quantityDelta &&
          other.lowStockThreshold == this.lowStockThreshold &&
          other.unitPrice == this.unitPrice &&
          other.costPrice == this.costPrice &&
          other.description == this.description &&
          other.imageUrl == this.imageUrl &&
          other.isActive == this.isActive &&
          other.createdBy == this.createdBy &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.syncStatus == this.syncStatus &&
          other.localVersion == this.localVersion &&
          other.isDeleted == this.isDeleted);
}

class InventoryTableCompanion extends UpdateCompanion<InventoryTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String> sku;
  final Value<String> barcode;
  final Value<String> category;
  final Value<String> unit;
  final Value<double> quantity;
  final Value<double> quantityDelta;
  final Value<double> lowStockThreshold;
  final Value<double> unitPrice;
  final Value<double> costPrice;
  final Value<String> description;
  final Value<String> imageUrl;
  final Value<int> isActive;
  final Value<String> createdBy;
  final Value<String> metadata;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> serverUpdatedAt;
  final Value<String> syncStatus;
  final Value<int> localVersion;
  final Value<int> isDeleted;
  final Value<int> rowid;
  const InventoryTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.category = const Value.absent(),
    this.unit = const Value.absent(),
    this.quantity = const Value.absent(),
    this.quantityDelta = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryTableCompanion.insert({
    required String id,
    required String businessId,
    required String name,
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.category = const Value.absent(),
    this.unit = const Value.absent(),
    this.quantity = const Value.absent(),
    this.quantityDelta = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.metadata = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<InventoryTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? sku,
    Expression<String>? barcode,
    Expression<String>? category,
    Expression<String>? unit,
    Expression<double>? quantity,
    Expression<double>? quantityDelta,
    Expression<double>? lowStockThreshold,
    Expression<double>? unitPrice,
    Expression<double>? costPrice,
    Expression<String>? description,
    Expression<String>? imageUrl,
    Expression<int>? isActive,
    Expression<String>? createdBy,
    Expression<String>? metadata,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? serverUpdatedAt,
    Expression<String>? syncStatus,
    Expression<int>? localVersion,
    Expression<int>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (category != null) 'category': category,
      if (unit != null) 'unit': unit,
      if (quantity != null) 'quantity': quantity,
      if (quantityDelta != null) 'quantity_delta': quantityDelta,
      if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (costPrice != null) 'cost_price': costPrice,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (isActive != null) 'is_active': isActive,
      if (createdBy != null) 'created_by': createdBy,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localVersion != null) 'local_version': localVersion,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<String>? sku,
    Value<String>? barcode,
    Value<String>? category,
    Value<String>? unit,
    Value<double>? quantity,
    Value<double>? quantityDelta,
    Value<double>? lowStockThreshold,
    Value<double>? unitPrice,
    Value<double>? costPrice,
    Value<String>? description,
    Value<String>? imageUrl,
    Value<int>? isActive,
    Value<String>? createdBy,
    Value<String>? metadata,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? serverUpdatedAt,
    Value<String>? syncStatus,
    Value<int>? localVersion,
    Value<int>? isDeleted,
    Value<int>? rowid,
  }) {
    return InventoryTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      quantityDelta: quantityDelta ?? this.quantityDelta,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      localVersion: localVersion ?? this.localVersion,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (quantityDelta.present) {
      map['quantity_delta'] = Variable<double>(quantityDelta.value);
    }
    if (lowStockThreshold.present) {
      map['low_stock_threshold'] = Variable<double>(lowStockThreshold.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<double>(costPrice.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<int>(isActive.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (localVersion.present) {
      map['local_version'] = Variable<int>(localVersion.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('category: $category, ')
          ..write('unit: $unit, ')
          ..write('quantity: $quantity, ')
          ..write('quantityDelta: $quantityDelta, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('costPrice: $costPrice, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('isActive: $isActive, ')
          ..write('createdBy: $createdBy, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localVersion: $localVersion, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxAttemptsMeta = const VerificationMeta(
    'maxAttempts',
  );
  @override
  late final GeneratedColumn<int> maxAttempts = GeneratedColumn<int>(
    'max_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<int> nextRetryAt = GeneratedColumn<int>(
    'next_retry_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localVersionMeta = const VerificationMeta(
    'localVersion',
  );
  @override
  late final GeneratedColumn<int> localVersion = GeneratedColumn<int>(
    'local_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationId,
    entityType,
    entityId,
    operation,
    payload,
    status,
    attempts,
    maxAttempts,
    nextRetryAt,
    createdAt,
    updatedAt,
    errorMessage,
    checksum,
    localVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('max_attempts')) {
      context.handle(
        _maxAttemptsMeta,
        maxAttempts.isAcceptableOrUnknown(
          data['max_attempts']!,
          _maxAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('local_version')) {
      context.handle(
        _localVersionMeta,
        localVersion.isAcceptableOrUnknown(
          data['local_version']!,
          _localVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      maxAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_attempts'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_retry_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      localVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_version'],
      )!,
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueTableData extends DataClass
    implements Insertable<SyncQueueTableData> {
  final int id;
  final String operationId;
  final String entityType;
  final String entityId;
  final String operation;
  final String payload;
  final String status;
  final int attempts;
  final int maxAttempts;
  final int nextRetryAt;
  final int createdAt;
  final int updatedAt;
  final String errorMessage;
  final String checksum;
  final int localVersion;
  const SyncQueueTableData({
    required this.id,
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.status,
    required this.attempts,
    required this.maxAttempts,
    required this.nextRetryAt,
    required this.createdAt,
    required this.updatedAt,
    required this.errorMessage,
    required this.checksum,
    required this.localVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation_id'] = Variable<String>(operationId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    map['max_attempts'] = Variable<int>(maxAttempts);
    map['next_retry_at'] = Variable<int>(nextRetryAt);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['error_message'] = Variable<String>(errorMessage);
    map['checksum'] = Variable<String>(checksum);
    map['local_version'] = Variable<int>(localVersion);
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      operationId: Value(operationId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payload: Value(payload),
      status: Value(status),
      attempts: Value(attempts),
      maxAttempts: Value(maxAttempts),
      nextRetryAt: Value(nextRetryAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      errorMessage: Value(errorMessage),
      checksum: Value(checksum),
      localVersion: Value(localVersion),
    );
  }

  factory SyncQueueTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueTableData(
      id: serializer.fromJson<int>(json['id']),
      operationId: serializer.fromJson<String>(json['operationId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      maxAttempts: serializer.fromJson<int>(json['maxAttempts']),
      nextRetryAt: serializer.fromJson<int>(json['nextRetryAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      errorMessage: serializer.fromJson<String>(json['errorMessage']),
      checksum: serializer.fromJson<String>(json['checksum']),
      localVersion: serializer.fromJson<int>(json['localVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operationId': serializer.toJson<String>(operationId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'maxAttempts': serializer.toJson<int>(maxAttempts),
      'nextRetryAt': serializer.toJson<int>(nextRetryAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'errorMessage': serializer.toJson<String>(errorMessage),
      'checksum': serializer.toJson<String>(checksum),
      'localVersion': serializer.toJson<int>(localVersion),
    };
  }

  SyncQueueTableData copyWith({
    int? id,
    String? operationId,
    String? entityType,
    String? entityId,
    String? operation,
    String? payload,
    String? status,
    int? attempts,
    int? maxAttempts,
    int? nextRetryAt,
    int? createdAt,
    int? updatedAt,
    String? errorMessage,
    String? checksum,
    int? localVersion,
  }) => SyncQueueTableData(
    id: id ?? this.id,
    operationId: operationId ?? this.operationId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    maxAttempts: maxAttempts ?? this.maxAttempts,
    nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    errorMessage: errorMessage ?? this.errorMessage,
    checksum: checksum ?? this.checksum,
    localVersion: localVersion ?? this.localVersion,
  );
  SyncQueueTableData copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      maxAttempts: data.maxAttempts.present
          ? data.maxAttempts.value
          : this.maxAttempts,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      localVersion: data.localVersion.present
          ? data.localVersion.value
          : this.localVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableData(')
          ..write('id: $id, ')
          ..write('operationId: $operationId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('maxAttempts: $maxAttempts, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('checksum: $checksum, ')
          ..write('localVersion: $localVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operationId,
    entityType,
    entityId,
    operation,
    payload,
    status,
    attempts,
    maxAttempts,
    nextRetryAt,
    createdAt,
    updatedAt,
    errorMessage,
    checksum,
    localVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueTableData &&
          other.id == this.id &&
          other.operationId == this.operationId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.maxAttempts == this.maxAttempts &&
          other.nextRetryAt == this.nextRetryAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.errorMessage == this.errorMessage &&
          other.checksum == this.checksum &&
          other.localVersion == this.localVersion);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueTableData> {
  final Value<int> id;
  final Value<String> operationId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<String> status;
  final Value<int> attempts;
  final Value<int> maxAttempts;
  final Value<int> nextRetryAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> errorMessage;
  final Value<String> checksum;
  final Value<int> localVersion;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.operationId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.maxAttempts = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.checksum = const Value.absent(),
    this.localVersion = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    this.id = const Value.absent(),
    required String operationId,
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.maxAttempts = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.errorMessage = const Value.absent(),
    required String checksum,
    required int localVersion,
  }) : operationId = Value(operationId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       payload = Value(payload),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       checksum = Value(checksum),
       localVersion = Value(localVersion);
  static Insertable<SyncQueueTableData> custom({
    Expression<int>? id,
    Expression<String>? operationId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<int>? maxAttempts,
    Expression<int>? nextRetryAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? errorMessage,
    Expression<String>? checksum,
    Expression<int>? localVersion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationId != null) 'operation_id': operationId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (maxAttempts != null) 'max_attempts': maxAttempts,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (errorMessage != null) 'error_message': errorMessage,
      if (checksum != null) 'checksum': checksum,
      if (localVersion != null) 'local_version': localVersion,
    });
  }

  SyncQueueTableCompanion copyWith({
    Value<int>? id,
    Value<String>? operationId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? payload,
    Value<String>? status,
    Value<int>? attempts,
    Value<int>? maxAttempts,
    Value<int>? nextRetryAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? errorMessage,
    Value<String>? checksum,
    Value<int>? localVersion,
  }) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      operationId: operationId ?? this.operationId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      checksum: checksum ?? this.checksum,
      localVersion: localVersion ?? this.localVersion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (maxAttempts.present) {
      map['max_attempts'] = Variable<int>(maxAttempts.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<int>(nextRetryAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (localVersion.present) {
      map['local_version'] = Variable<int>(localVersion.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('operationId: $operationId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('maxAttempts: $maxAttempts, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('checksum: $checksum, ')
          ..write('localVersion: $localVersion')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTableTable extends UserSettingsTable
    with TableInfo<$UserSettingsTableTable, UserSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncAt = GeneratedColumn<int>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastOnlineAtMeta = const VerificationMeta(
    'lastOnlineAt',
  );
  @override
  late final GeneratedColumn<int> lastOnlineAt = GeneratedColumn<int>(
    'last_online_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offlineSinceMeta = const VerificationMeta(
    'offlineSince',
  );
  @override
  late final GeneratedColumn<int> offlineSince = GeneratedColumn<int>(
    'offline_since',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncOnWifiOnlyMeta = const VerificationMeta(
    'syncOnWifiOnly',
  );
  @override
  late final GeneratedColumn<int> syncOnWifiOnly = GeneratedColumn<int>(
    'sync_on_wifi_only',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _autoSyncIntervalMeta = const VerificationMeta(
    'autoSyncInterval',
  );
  @override
  late final GeneratedColumn<int> autoSyncInterval = GeneratedColumn<int>(
    'auto_sync_interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sw'),
  );
  static const VerificationMeta _notificationSettingsMeta =
      const VerificationMeta('notificationSettings');
  @override
  late final GeneratedColumn<String> notificationSettings =
      GeneratedColumn<String>(
        'notification_settings',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    businessId,
    lastSyncAt,
    lastOnlineAt,
    offlineSince,
    syncOnWifiOnly,
    autoSyncInterval,
    language,
    notificationSettings,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('last_online_at')) {
      context.handle(
        _lastOnlineAtMeta,
        lastOnlineAt.isAcceptableOrUnknown(
          data['last_online_at']!,
          _lastOnlineAtMeta,
        ),
      );
    }
    if (data.containsKey('offline_since')) {
      context.handle(
        _offlineSinceMeta,
        offlineSince.isAcceptableOrUnknown(
          data['offline_since']!,
          _offlineSinceMeta,
        ),
      );
    }
    if (data.containsKey('sync_on_wifi_only')) {
      context.handle(
        _syncOnWifiOnlyMeta,
        syncOnWifiOnly.isAcceptableOrUnknown(
          data['sync_on_wifi_only']!,
          _syncOnWifiOnlyMeta,
        ),
      );
    }
    if (data.containsKey('auto_sync_interval')) {
      context.handle(
        _autoSyncIntervalMeta,
        autoSyncInterval.isAcceptableOrUnknown(
          data['auto_sync_interval']!,
          _autoSyncIntervalMeta,
        ),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('notification_settings')) {
      context.handle(
        _notificationSettingsMeta,
        notificationSettings.isAcceptableOrUnknown(
          data['notification_settings']!,
          _notificationSettingsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSettingsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sync_at'],
      ),
      lastOnlineAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_online_at'],
      ),
      offlineSince: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offline_since'],
      ),
      syncOnWifiOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_on_wifi_only'],
      )!,
      autoSyncInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}auto_sync_interval'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      notificationSettings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notification_settings'],
      )!,
    );
  }

  @override
  $UserSettingsTableTable createAlias(String alias) {
    return $UserSettingsTableTable(attachedDatabase, alias);
  }
}

class UserSettingsTableData extends DataClass
    implements Insertable<UserSettingsTableData> {
  final int id;
  final String userId;
  final String businessId;
  final int? lastSyncAt;
  final int? lastOnlineAt;
  final int? offlineSince;
  final int syncOnWifiOnly;
  final int autoSyncInterval;
  final String language;
  final String notificationSettings;
  const UserSettingsTableData({
    required this.id,
    required this.userId,
    required this.businessId,
    this.lastSyncAt,
    this.lastOnlineAt,
    this.offlineSince,
    required this.syncOnWifiOnly,
    required this.autoSyncInterval,
    required this.language,
    required this.notificationSettings,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['business_id'] = Variable<String>(businessId);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<int>(lastSyncAt);
    }
    if (!nullToAbsent || lastOnlineAt != null) {
      map['last_online_at'] = Variable<int>(lastOnlineAt);
    }
    if (!nullToAbsent || offlineSince != null) {
      map['offline_since'] = Variable<int>(offlineSince);
    }
    map['sync_on_wifi_only'] = Variable<int>(syncOnWifiOnly);
    map['auto_sync_interval'] = Variable<int>(autoSyncInterval);
    map['language'] = Variable<String>(language);
    map['notification_settings'] = Variable<String>(notificationSettings);
    return map;
  }

  UserSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      businessId: Value(businessId),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      lastOnlineAt: lastOnlineAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOnlineAt),
      offlineSince: offlineSince == null && nullToAbsent
          ? const Value.absent()
          : Value(offlineSince),
      syncOnWifiOnly: Value(syncOnWifiOnly),
      autoSyncInterval: Value(autoSyncInterval),
      language: Value(language),
      notificationSettings: Value(notificationSettings),
    );
  }

  factory UserSettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSettingsTableData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      businessId: serializer.fromJson<String>(json['businessId']),
      lastSyncAt: serializer.fromJson<int?>(json['lastSyncAt']),
      lastOnlineAt: serializer.fromJson<int?>(json['lastOnlineAt']),
      offlineSince: serializer.fromJson<int?>(json['offlineSince']),
      syncOnWifiOnly: serializer.fromJson<int>(json['syncOnWifiOnly']),
      autoSyncInterval: serializer.fromJson<int>(json['autoSyncInterval']),
      language: serializer.fromJson<String>(json['language']),
      notificationSettings: serializer.fromJson<String>(
        json['notificationSettings'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'businessId': serializer.toJson<String>(businessId),
      'lastSyncAt': serializer.toJson<int?>(lastSyncAt),
      'lastOnlineAt': serializer.toJson<int?>(lastOnlineAt),
      'offlineSince': serializer.toJson<int?>(offlineSince),
      'syncOnWifiOnly': serializer.toJson<int>(syncOnWifiOnly),
      'autoSyncInterval': serializer.toJson<int>(autoSyncInterval),
      'language': serializer.toJson<String>(language),
      'notificationSettings': serializer.toJson<String>(notificationSettings),
    };
  }

  UserSettingsTableData copyWith({
    int? id,
    String? userId,
    String? businessId,
    Value<int?> lastSyncAt = const Value.absent(),
    Value<int?> lastOnlineAt = const Value.absent(),
    Value<int?> offlineSince = const Value.absent(),
    int? syncOnWifiOnly,
    int? autoSyncInterval,
    String? language,
    String? notificationSettings,
  }) => UserSettingsTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    businessId: businessId ?? this.businessId,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    lastOnlineAt: lastOnlineAt.present ? lastOnlineAt.value : this.lastOnlineAt,
    offlineSince: offlineSince.present ? offlineSince.value : this.offlineSince,
    syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
    autoSyncInterval: autoSyncInterval ?? this.autoSyncInterval,
    language: language ?? this.language,
    notificationSettings: notificationSettings ?? this.notificationSettings,
  );
  UserSettingsTableData copyWithCompanion(UserSettingsTableCompanion data) {
    return UserSettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      lastOnlineAt: data.lastOnlineAt.present
          ? data.lastOnlineAt.value
          : this.lastOnlineAt,
      offlineSince: data.offlineSince.present
          ? data.offlineSince.value
          : this.offlineSince,
      syncOnWifiOnly: data.syncOnWifiOnly.present
          ? data.syncOnWifiOnly.value
          : this.syncOnWifiOnly,
      autoSyncInterval: data.autoSyncInterval.present
          ? data.autoSyncInterval.value
          : this.autoSyncInterval,
      language: data.language.present ? data.language.value : this.language,
      notificationSettings: data.notificationSettings.present
          ? data.notificationSettings.value
          : this.notificationSettings,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('businessId: $businessId, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastOnlineAt: $lastOnlineAt, ')
          ..write('offlineSince: $offlineSince, ')
          ..write('syncOnWifiOnly: $syncOnWifiOnly, ')
          ..write('autoSyncInterval: $autoSyncInterval, ')
          ..write('language: $language, ')
          ..write('notificationSettings: $notificationSettings')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    businessId,
    lastSyncAt,
    lastOnlineAt,
    offlineSince,
    syncOnWifiOnly,
    autoSyncInterval,
    language,
    notificationSettings,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSettingsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.businessId == this.businessId &&
          other.lastSyncAt == this.lastSyncAt &&
          other.lastOnlineAt == this.lastOnlineAt &&
          other.offlineSince == this.offlineSince &&
          other.syncOnWifiOnly == this.syncOnWifiOnly &&
          other.autoSyncInterval == this.autoSyncInterval &&
          other.language == this.language &&
          other.notificationSettings == this.notificationSettings);
}

class UserSettingsTableCompanion
    extends UpdateCompanion<UserSettingsTableData> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> businessId;
  final Value<int?> lastSyncAt;
  final Value<int?> lastOnlineAt;
  final Value<int?> offlineSince;
  final Value<int> syncOnWifiOnly;
  final Value<int> autoSyncInterval;
  final Value<String> language;
  final Value<String> notificationSettings;
  const UserSettingsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.businessId = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastOnlineAt = const Value.absent(),
    this.offlineSince = const Value.absent(),
    this.syncOnWifiOnly = const Value.absent(),
    this.autoSyncInterval = const Value.absent(),
    this.language = const Value.absent(),
    this.notificationSettings = const Value.absent(),
  });
  UserSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String businessId,
    this.lastSyncAt = const Value.absent(),
    this.lastOnlineAt = const Value.absent(),
    this.offlineSince = const Value.absent(),
    this.syncOnWifiOnly = const Value.absent(),
    this.autoSyncInterval = const Value.absent(),
    this.language = const Value.absent(),
    this.notificationSettings = const Value.absent(),
  }) : userId = Value(userId),
       businessId = Value(businessId);
  static Insertable<UserSettingsTableData> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? businessId,
    Expression<int>? lastSyncAt,
    Expression<int>? lastOnlineAt,
    Expression<int>? offlineSince,
    Expression<int>? syncOnWifiOnly,
    Expression<int>? autoSyncInterval,
    Expression<String>? language,
    Expression<String>? notificationSettings,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (businessId != null) 'business_id': businessId,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (lastOnlineAt != null) 'last_online_at': lastOnlineAt,
      if (offlineSince != null) 'offline_since': offlineSince,
      if (syncOnWifiOnly != null) 'sync_on_wifi_only': syncOnWifiOnly,
      if (autoSyncInterval != null) 'auto_sync_interval': autoSyncInterval,
      if (language != null) 'language': language,
      if (notificationSettings != null)
        'notification_settings': notificationSettings,
    });
  }

  UserSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? businessId,
    Value<int?>? lastSyncAt,
    Value<int?>? lastOnlineAt,
    Value<int?>? offlineSince,
    Value<int>? syncOnWifiOnly,
    Value<int>? autoSyncInterval,
    Value<String>? language,
    Value<String>? notificationSettings,
  }) {
    return UserSettingsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastOnlineAt: lastOnlineAt ?? this.lastOnlineAt,
      offlineSince: offlineSince ?? this.offlineSince,
      syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
      autoSyncInterval: autoSyncInterval ?? this.autoSyncInterval,
      language: language ?? this.language,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<int>(lastSyncAt.value);
    }
    if (lastOnlineAt.present) {
      map['last_online_at'] = Variable<int>(lastOnlineAt.value);
    }
    if (offlineSince.present) {
      map['offline_since'] = Variable<int>(offlineSince.value);
    }
    if (syncOnWifiOnly.present) {
      map['sync_on_wifi_only'] = Variable<int>(syncOnWifiOnly.value);
    }
    if (autoSyncInterval.present) {
      map['auto_sync_interval'] = Variable<int>(autoSyncInterval.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (notificationSettings.present) {
      map['notification_settings'] = Variable<String>(
        notificationSettings.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('businessId: $businessId, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastOnlineAt: $lastOnlineAt, ')
          ..write('offlineSince: $offlineSince, ')
          ..write('syncOnWifiOnly: $syncOnWifiOnly, ')
          ..write('autoSyncInterval: $autoSyncInterval, ')
          ..write('language: $language, ')
          ..write('notificationSettings: $notificationSettings')
          ..write(')'))
        .toString();
  }
}

class $BusinessSettingsTableTable extends BusinessSettingsTable
    with TableInfo<$BusinessSettingsTableTable, BusinessSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BusinessSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessNameMeta = const VerificationMeta(
    'businessName',
  );
  @override
  late final GeneratedColumn<String> businessName = GeneratedColumn<String>(
    'business_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessTypeMeta = const VerificationMeta(
    'businessType',
  );
  @override
  late final GeneratedColumn<String> businessType = GeneratedColumn<String>(
    'business_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tinNumberMeta = const VerificationMeta(
    'tinNumber',
  );
  @override
  late final GeneratedColumn<String> tinNumber = GeneratedColumn<String>(
    'tin_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _vatRegisteredMeta = const VerificationMeta(
    'vatRegistered',
  );
  @override
  late final GeneratedColumn<int> vatRegistered = GeneratedColumn<int>(
    'vat_registered',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vatRateMeta = const VerificationMeta(
    'vatRate',
  );
  @override
  late final GeneratedColumn<double> vatRate = GeneratedColumn<double>(
    'vat_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.18),
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('TZS'),
  );
  static const VerificationMeta _invoicePrefixMeta = const VerificationMeta(
    'invoicePrefix',
  );
  @override
  late final GeneratedColumn<String> invoicePrefix = GeneratedColumn<String>(
    'invoice_prefix',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INV'),
  );
  static const VerificationMeta _nextInvoiceNumberMeta = const VerificationMeta(
    'nextInvoiceNumber',
  );
  @override
  late final GeneratedColumn<int> nextInvoiceNumber = GeneratedColumn<int>(
    'next_invoice_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _logoUrlMeta = const VerificationMeta(
    'logoUrl',
  );
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _planMeta = const VerificationMeta('plan');
  @override
  late final GeneratedColumn<String> plan = GeneratedColumn<String>(
    'plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('starter'),
  );
  static const VerificationMeta _planExpiresAtMeta = const VerificationMeta(
    'planExpiresAt',
  );
  @override
  late final GeneratedColumn<int> planExpiresAt = GeneratedColumn<int>(
    'plan_expires_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> serverUpdatedAt = GeneratedColumn<int>(
    'server_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_create'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    businessName,
    businessType,
    phone,
    address,
    tinNumber,
    vatRegistered,
    vatRate,
    currency,
    invoicePrefix,
    nextInvoiceNumber,
    logoUrl,
    plan,
    planExpiresAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'business_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<BusinessSettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('business_name')) {
      context.handle(
        _businessNameMeta,
        businessName.isAcceptableOrUnknown(
          data['business_name']!,
          _businessNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessNameMeta);
    }
    if (data.containsKey('business_type')) {
      context.handle(
        _businessTypeMeta,
        businessType.isAcceptableOrUnknown(
          data['business_type']!,
          _businessTypeMeta,
        ),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('tin_number')) {
      context.handle(
        _tinNumberMeta,
        tinNumber.isAcceptableOrUnknown(data['tin_number']!, _tinNumberMeta),
      );
    }
    if (data.containsKey('vat_registered')) {
      context.handle(
        _vatRegisteredMeta,
        vatRegistered.isAcceptableOrUnknown(
          data['vat_registered']!,
          _vatRegisteredMeta,
        ),
      );
    }
    if (data.containsKey('vat_rate')) {
      context.handle(
        _vatRateMeta,
        vatRate.isAcceptableOrUnknown(data['vat_rate']!, _vatRateMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('invoice_prefix')) {
      context.handle(
        _invoicePrefixMeta,
        invoicePrefix.isAcceptableOrUnknown(
          data['invoice_prefix']!,
          _invoicePrefixMeta,
        ),
      );
    }
    if (data.containsKey('next_invoice_number')) {
      context.handle(
        _nextInvoiceNumberMeta,
        nextInvoiceNumber.isAcceptableOrUnknown(
          data['next_invoice_number']!,
          _nextInvoiceNumberMeta,
        ),
      );
    }
    if (data.containsKey('logo_url')) {
      context.handle(
        _logoUrlMeta,
        logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta),
      );
    }
    if (data.containsKey('plan')) {
      context.handle(
        _planMeta,
        plan.isAcceptableOrUnknown(data['plan']!, _planMeta),
      );
    }
    if (data.containsKey('plan_expires_at')) {
      context.handle(
        _planExpiresAtMeta,
        planExpiresAt.isAcceptableOrUnknown(
          data['plan_expires_at']!,
          _planExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BusinessSettingsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusinessSettingsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      businessName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_name'],
      )!,
      businessType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_type'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      tinNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tin_number'],
      )!,
      vatRegistered: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vat_registered'],
      )!,
      vatRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vat_rate'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      invoicePrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_prefix'],
      )!,
      nextInvoiceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_invoice_number'],
      )!,
      logoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_url'],
      )!,
      plan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan'],
      )!,
      planExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_expires_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_updated_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $BusinessSettingsTableTable createAlias(String alias) {
    return $BusinessSettingsTableTable(attachedDatabase, alias);
  }
}

class BusinessSettingsTableData extends DataClass
    implements Insertable<BusinessSettingsTableData> {
  final int id;
  final String businessId;
  final String businessName;
  final String businessType;
  final String phone;
  final String address;
  final String tinNumber;
  final int vatRegistered;
  final double vatRate;
  final String currency;
  final String invoicePrefix;
  final int nextInvoiceNumber;
  final String logoUrl;
  final String plan;
  final int? planExpiresAt;
  final int updatedAt;
  final int? serverUpdatedAt;
  final String syncStatus;
  const BusinessSettingsTableData({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.businessType,
    required this.phone,
    required this.address,
    required this.tinNumber,
    required this.vatRegistered,
    required this.vatRate,
    required this.currency,
    required this.invoicePrefix,
    required this.nextInvoiceNumber,
    required this.logoUrl,
    required this.plan,
    this.planExpiresAt,
    required this.updatedAt,
    this.serverUpdatedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['business_id'] = Variable<String>(businessId);
    map['business_name'] = Variable<String>(businessName);
    map['business_type'] = Variable<String>(businessType);
    map['phone'] = Variable<String>(phone);
    map['address'] = Variable<String>(address);
    map['tin_number'] = Variable<String>(tinNumber);
    map['vat_registered'] = Variable<int>(vatRegistered);
    map['vat_rate'] = Variable<double>(vatRate);
    map['currency'] = Variable<String>(currency);
    map['invoice_prefix'] = Variable<String>(invoicePrefix);
    map['next_invoice_number'] = Variable<int>(nextInvoiceNumber);
    map['logo_url'] = Variable<String>(logoUrl);
    map['plan'] = Variable<String>(plan);
    if (!nullToAbsent || planExpiresAt != null) {
      map['plan_expires_at'] = Variable<int>(planExpiresAt);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  BusinessSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return BusinessSettingsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      businessName: Value(businessName),
      businessType: Value(businessType),
      phone: Value(phone),
      address: Value(address),
      tinNumber: Value(tinNumber),
      vatRegistered: Value(vatRegistered),
      vatRate: Value(vatRate),
      currency: Value(currency),
      invoicePrefix: Value(invoicePrefix),
      nextInvoiceNumber: Value(nextInvoiceNumber),
      logoUrl: Value(logoUrl),
      plan: Value(plan),
      planExpiresAt: planExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(planExpiresAt),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory BusinessSettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusinessSettingsTableData(
      id: serializer.fromJson<int>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      businessName: serializer.fromJson<String>(json['businessName']),
      businessType: serializer.fromJson<String>(json['businessType']),
      phone: serializer.fromJson<String>(json['phone']),
      address: serializer.fromJson<String>(json['address']),
      tinNumber: serializer.fromJson<String>(json['tinNumber']),
      vatRegistered: serializer.fromJson<int>(json['vatRegistered']),
      vatRate: serializer.fromJson<double>(json['vatRate']),
      currency: serializer.fromJson<String>(json['currency']),
      invoicePrefix: serializer.fromJson<String>(json['invoicePrefix']),
      nextInvoiceNumber: serializer.fromJson<int>(json['nextInvoiceNumber']),
      logoUrl: serializer.fromJson<String>(json['logoUrl']),
      plan: serializer.fromJson<String>(json['plan']),
      planExpiresAt: serializer.fromJson<int?>(json['planExpiresAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      serverUpdatedAt: serializer.fromJson<int?>(json['serverUpdatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'businessId': serializer.toJson<String>(businessId),
      'businessName': serializer.toJson<String>(businessName),
      'businessType': serializer.toJson<String>(businessType),
      'phone': serializer.toJson<String>(phone),
      'address': serializer.toJson<String>(address),
      'tinNumber': serializer.toJson<String>(tinNumber),
      'vatRegistered': serializer.toJson<int>(vatRegistered),
      'vatRate': serializer.toJson<double>(vatRate),
      'currency': serializer.toJson<String>(currency),
      'invoicePrefix': serializer.toJson<String>(invoicePrefix),
      'nextInvoiceNumber': serializer.toJson<int>(nextInvoiceNumber),
      'logoUrl': serializer.toJson<String>(logoUrl),
      'plan': serializer.toJson<String>(plan),
      'planExpiresAt': serializer.toJson<int?>(planExpiresAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'serverUpdatedAt': serializer.toJson<int?>(serverUpdatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  BusinessSettingsTableData copyWith({
    int? id,
    String? businessId,
    String? businessName,
    String? businessType,
    String? phone,
    String? address,
    String? tinNumber,
    int? vatRegistered,
    double? vatRate,
    String? currency,
    String? invoicePrefix,
    int? nextInvoiceNumber,
    String? logoUrl,
    String? plan,
    Value<int?> planExpiresAt = const Value.absent(),
    int? updatedAt,
    Value<int?> serverUpdatedAt = const Value.absent(),
    String? syncStatus,
  }) => BusinessSettingsTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    businessName: businessName ?? this.businessName,
    businessType: businessType ?? this.businessType,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    tinNumber: tinNumber ?? this.tinNumber,
    vatRegistered: vatRegistered ?? this.vatRegistered,
    vatRate: vatRate ?? this.vatRate,
    currency: currency ?? this.currency,
    invoicePrefix: invoicePrefix ?? this.invoicePrefix,
    nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
    logoUrl: logoUrl ?? this.logoUrl,
    plan: plan ?? this.plan,
    planExpiresAt: planExpiresAt.present
        ? planExpiresAt.value
        : this.planExpiresAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  BusinessSettingsTableData copyWithCompanion(
    BusinessSettingsTableCompanion data,
  ) {
    return BusinessSettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      businessName: data.businessName.present
          ? data.businessName.value
          : this.businessName,
      businessType: data.businessType.present
          ? data.businessType.value
          : this.businessType,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      tinNumber: data.tinNumber.present ? data.tinNumber.value : this.tinNumber,
      vatRegistered: data.vatRegistered.present
          ? data.vatRegistered.value
          : this.vatRegistered,
      vatRate: data.vatRate.present ? data.vatRate.value : this.vatRate,
      currency: data.currency.present ? data.currency.value : this.currency,
      invoicePrefix: data.invoicePrefix.present
          ? data.invoicePrefix.value
          : this.invoicePrefix,
      nextInvoiceNumber: data.nextInvoiceNumber.present
          ? data.nextInvoiceNumber.value
          : this.nextInvoiceNumber,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      plan: data.plan.present ? data.plan.value : this.plan,
      planExpiresAt: data.planExpiresAt.present
          ? data.planExpiresAt.value
          : this.planExpiresAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusinessSettingsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('businessName: $businessName, ')
          ..write('businessType: $businessType, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('tinNumber: $tinNumber, ')
          ..write('vatRegistered: $vatRegistered, ')
          ..write('vatRate: $vatRate, ')
          ..write('currency: $currency, ')
          ..write('invoicePrefix: $invoicePrefix, ')
          ..write('nextInvoiceNumber: $nextInvoiceNumber, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('plan: $plan, ')
          ..write('planExpiresAt: $planExpiresAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    businessName,
    businessType,
    phone,
    address,
    tinNumber,
    vatRegistered,
    vatRate,
    currency,
    invoicePrefix,
    nextInvoiceNumber,
    logoUrl,
    plan,
    planExpiresAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessSettingsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.businessName == this.businessName &&
          other.businessType == this.businessType &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.tinNumber == this.tinNumber &&
          other.vatRegistered == this.vatRegistered &&
          other.vatRate == this.vatRate &&
          other.currency == this.currency &&
          other.invoicePrefix == this.invoicePrefix &&
          other.nextInvoiceNumber == this.nextInvoiceNumber &&
          other.logoUrl == this.logoUrl &&
          other.plan == this.plan &&
          other.planExpiresAt == this.planExpiresAt &&
          other.updatedAt == this.updatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.syncStatus == this.syncStatus);
}

class BusinessSettingsTableCompanion
    extends UpdateCompanion<BusinessSettingsTableData> {
  final Value<int> id;
  final Value<String> businessId;
  final Value<String> businessName;
  final Value<String> businessType;
  final Value<String> phone;
  final Value<String> address;
  final Value<String> tinNumber;
  final Value<int> vatRegistered;
  final Value<double> vatRate;
  final Value<String> currency;
  final Value<String> invoicePrefix;
  final Value<int> nextInvoiceNumber;
  final Value<String> logoUrl;
  final Value<String> plan;
  final Value<int?> planExpiresAt;
  final Value<int> updatedAt;
  final Value<int?> serverUpdatedAt;
  final Value<String> syncStatus;
  const BusinessSettingsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.businessName = const Value.absent(),
    this.businessType = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.tinNumber = const Value.absent(),
    this.vatRegistered = const Value.absent(),
    this.vatRate = const Value.absent(),
    this.currency = const Value.absent(),
    this.invoicePrefix = const Value.absent(),
    this.nextInvoiceNumber = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.plan = const Value.absent(),
    this.planExpiresAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
  });
  BusinessSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required String businessId,
    required String businessName,
    this.businessType = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.tinNumber = const Value.absent(),
    this.vatRegistered = const Value.absent(),
    this.vatRate = const Value.absent(),
    this.currency = const Value.absent(),
    this.invoicePrefix = const Value.absent(),
    this.nextInvoiceNumber = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.plan = const Value.absent(),
    this.planExpiresAt = const Value.absent(),
    required int updatedAt,
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
  }) : businessId = Value(businessId),
       businessName = Value(businessName),
       updatedAt = Value(updatedAt);
  static Insertable<BusinessSettingsTableData> custom({
    Expression<int>? id,
    Expression<String>? businessId,
    Expression<String>? businessName,
    Expression<String>? businessType,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<String>? tinNumber,
    Expression<int>? vatRegistered,
    Expression<double>? vatRate,
    Expression<String>? currency,
    Expression<String>? invoicePrefix,
    Expression<int>? nextInvoiceNumber,
    Expression<String>? logoUrl,
    Expression<String>? plan,
    Expression<int>? planExpiresAt,
    Expression<int>? updatedAt,
    Expression<int>? serverUpdatedAt,
    Expression<String>? syncStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (businessName != null) 'business_name': businessName,
      if (businessType != null) 'business_type': businessType,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (tinNumber != null) 'tin_number': tinNumber,
      if (vatRegistered != null) 'vat_registered': vatRegistered,
      if (vatRate != null) 'vat_rate': vatRate,
      if (currency != null) 'currency': currency,
      if (invoicePrefix != null) 'invoice_prefix': invoicePrefix,
      if (nextInvoiceNumber != null) 'next_invoice_number': nextInvoiceNumber,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (plan != null) 'plan': plan,
      if (planExpiresAt != null) 'plan_expires_at': planExpiresAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
    });
  }

  BusinessSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? businessId,
    Value<String>? businessName,
    Value<String>? businessType,
    Value<String>? phone,
    Value<String>? address,
    Value<String>? tinNumber,
    Value<int>? vatRegistered,
    Value<double>? vatRate,
    Value<String>? currency,
    Value<String>? invoicePrefix,
    Value<int>? nextInvoiceNumber,
    Value<String>? logoUrl,
    Value<String>? plan,
    Value<int?>? planExpiresAt,
    Value<int>? updatedAt,
    Value<int?>? serverUpdatedAt,
    Value<String>? syncStatus,
  }) {
    return BusinessSettingsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      tinNumber: tinNumber ?? this.tinNumber,
      vatRegistered: vatRegistered ?? this.vatRegistered,
      vatRate: vatRate ?? this.vatRate,
      currency: currency ?? this.currency,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      logoUrl: logoUrl ?? this.logoUrl,
      plan: plan ?? this.plan,
      planExpiresAt: planExpiresAt ?? this.planExpiresAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (businessName.present) {
      map['business_name'] = Variable<String>(businessName.value);
    }
    if (businessType.present) {
      map['business_type'] = Variable<String>(businessType.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (tinNumber.present) {
      map['tin_number'] = Variable<String>(tinNumber.value);
    }
    if (vatRegistered.present) {
      map['vat_registered'] = Variable<int>(vatRegistered.value);
    }
    if (vatRate.present) {
      map['vat_rate'] = Variable<double>(vatRate.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (invoicePrefix.present) {
      map['invoice_prefix'] = Variable<String>(invoicePrefix.value);
    }
    if (nextInvoiceNumber.present) {
      map['next_invoice_number'] = Variable<int>(nextInvoiceNumber.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (plan.present) {
      map['plan'] = Variable<String>(plan.value);
    }
    if (planExpiresAt.present) {
      map['plan_expires_at'] = Variable<int>(planExpiresAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BusinessSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('businessName: $businessName, ')
          ..write('businessType: $businessType, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('tinNumber: $tinNumber, ')
          ..write('vatRegistered: $vatRegistered, ')
          ..write('vatRate: $vatRate, ')
          ..write('currency: $currency, ')
          ..write('invoicePrefix: $invoicePrefix, ')
          ..write('nextInvoiceNumber: $nextInvoiceNumber, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('plan: $plan, ')
          ..write('planExpiresAt: $planExpiresAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }
}

class $DebtsTableTable extends DebtsTable
    with TableInfo<$DebtsTableTable, DebtsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partyNameMeta = const VerificationMeta(
    'partyName',
  );
  @override
  late final GeneratedColumn<String> partyName = GeneratedColumn<String>(
    'party_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partyPhoneMeta = const VerificationMeta(
    'partyPhone',
  );
  @override
  late final GeneratedColumn<String> partyPhone = GeneratedColumn<String>(
    'party_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _partyIdMeta = const VerificationMeta(
    'partyId',
  );
  @override
  late final GeneratedColumn<String> partyId = GeneratedColumn<String>(
    'party_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalAmountMeta = const VerificationMeta(
    'originalAmount',
  );
  @override
  late final GeneratedColumn<double> originalAmount = GeneratedColumn<double>(
    'original_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAmountMeta = const VerificationMeta(
    'paidAmount',
  );
  @override
  late final GeneratedColumn<double> paidAmount = GeneratedColumn<double>(
    'paid_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('current'),
  );
  static const VerificationMeta _invoiceRefMeta = const VerificationMeta(
    'invoiceRef',
  );
  @override
  late final GeneratedColumn<String> invoiceRef = GeneratedColumn<String>(
    'invoice_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _debtCreatedAtMeta = const VerificationMeta(
    'debtCreatedAt',
  );
  @override
  late final GeneratedColumn<String> debtCreatedAt = GeneratedColumn<String>(
    'debt_created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isWrittenOffMeta = const VerificationMeta(
    'isWrittenOff',
  );
  @override
  late final GeneratedColumn<int> isWrittenOff = GeneratedColumn<int>(
    'is_written_off',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _writeOffReasonMeta = const VerificationMeta(
    'writeOffReason',
  );
  @override
  late final GeneratedColumn<String> writeOffReason = GeneratedColumn<String>(
    'write_off_reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _writtenOffByMeta = const VerificationMeta(
    'writtenOffBy',
  );
  @override
  late final GeneratedColumn<String> writtenOffBy = GeneratedColumn<String>(
    'written_off_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _writtenOffAtMeta = const VerificationMeta(
    'writtenOffAt',
  );
  @override
  late final GeneratedColumn<String> writtenOffAt = GeneratedColumn<String>(
    'written_off_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _interestRatePercentMeta =
      const VerificationMeta('interestRatePercent');
  @override
  late final GeneratedColumn<double> interestRatePercent =
      GeneratedColumn<double>(
        'interest_rate_percent',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _interestPeriodMeta = const VerificationMeta(
    'interestPeriod',
  );
  @override
  late final GeneratedColumn<String> interestPeriod = GeneratedColumn<String>(
    'interest_period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('monthly'),
  );
  static const VerificationMeta _interestTypeMeta = const VerificationMeta(
    'interestType',
  );
  @override
  late final GeneratedColumn<String> interestType = GeneratedColumn<String>(
    'interest_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('simple'),
  );
  static const VerificationMeta _loanDateMeta = const VerificationMeta(
    'loanDate',
  );
  @override
  late final GeneratedColumn<String> loanDate = GeneratedColumn<String>(
    'loan_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> serverUpdatedAt = GeneratedColumn<int>(
    'server_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_create'),
  );
  static const VerificationMeta _localVersionMeta = const VerificationMeta(
    'localVersion',
  );
  @override
  late final GeneratedColumn<int> localVersion = GeneratedColumn<int>(
    'local_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    partyName,
    partyPhone,
    partyId,
    type,
    originalAmount,
    paidAmount,
    dueDate,
    status,
    invoiceRef,
    note,
    createdBy,
    debtCreatedAt,
    isWrittenOff,
    writeOffReason,
    writtenOffBy,
    writtenOffAt,
    interestRatePercent,
    interestPeriod,
    interestType,
    loanDate,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    localVersion,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DebtsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('party_name')) {
      context.handle(
        _partyNameMeta,
        partyName.isAcceptableOrUnknown(data['party_name']!, _partyNameMeta),
      );
    } else if (isInserting) {
      context.missing(_partyNameMeta);
    }
    if (data.containsKey('party_phone')) {
      context.handle(
        _partyPhoneMeta,
        partyPhone.isAcceptableOrUnknown(data['party_phone']!, _partyPhoneMeta),
      );
    }
    if (data.containsKey('party_id')) {
      context.handle(
        _partyIdMeta,
        partyId.isAcceptableOrUnknown(data['party_id']!, _partyIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('original_amount')) {
      context.handle(
        _originalAmountMeta,
        originalAmount.isAcceptableOrUnknown(
          data['original_amount']!,
          _originalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalAmountMeta);
    }
    if (data.containsKey('paid_amount')) {
      context.handle(
        _paidAmountMeta,
        paidAmount.isAcceptableOrUnknown(data['paid_amount']!, _paidAmountMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('invoice_ref')) {
      context.handle(
        _invoiceRefMeta,
        invoiceRef.isAcceptableOrUnknown(data['invoice_ref']!, _invoiceRefMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('debt_created_at')) {
      context.handle(
        _debtCreatedAtMeta,
        debtCreatedAt.isAcceptableOrUnknown(
          data['debt_created_at']!,
          _debtCreatedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_written_off')) {
      context.handle(
        _isWrittenOffMeta,
        isWrittenOff.isAcceptableOrUnknown(
          data['is_written_off']!,
          _isWrittenOffMeta,
        ),
      );
    }
    if (data.containsKey('write_off_reason')) {
      context.handle(
        _writeOffReasonMeta,
        writeOffReason.isAcceptableOrUnknown(
          data['write_off_reason']!,
          _writeOffReasonMeta,
        ),
      );
    }
    if (data.containsKey('written_off_by')) {
      context.handle(
        _writtenOffByMeta,
        writtenOffBy.isAcceptableOrUnknown(
          data['written_off_by']!,
          _writtenOffByMeta,
        ),
      );
    }
    if (data.containsKey('written_off_at')) {
      context.handle(
        _writtenOffAtMeta,
        writtenOffAt.isAcceptableOrUnknown(
          data['written_off_at']!,
          _writtenOffAtMeta,
        ),
      );
    }
    if (data.containsKey('interest_rate_percent')) {
      context.handle(
        _interestRatePercentMeta,
        interestRatePercent.isAcceptableOrUnknown(
          data['interest_rate_percent']!,
          _interestRatePercentMeta,
        ),
      );
    }
    if (data.containsKey('interest_period')) {
      context.handle(
        _interestPeriodMeta,
        interestPeriod.isAcceptableOrUnknown(
          data['interest_period']!,
          _interestPeriodMeta,
        ),
      );
    }
    if (data.containsKey('interest_type')) {
      context.handle(
        _interestTypeMeta,
        interestType.isAcceptableOrUnknown(
          data['interest_type']!,
          _interestTypeMeta,
        ),
      );
    }
    if (data.containsKey('loan_date')) {
      context.handle(
        _loanDateMeta,
        loanDate.isAcceptableOrUnknown(data['loan_date']!, _loanDateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('local_version')) {
      context.handle(
        _localVersionMeta,
        localVersion.isAcceptableOrUnknown(
          data['local_version']!,
          _localVersionMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DebtsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DebtsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      partyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_name'],
      )!,
      partyPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_phone'],
      )!,
      partyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      originalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}original_amount'],
      )!,
      paidAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}paid_amount'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      invoiceRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_ref'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      debtCreatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}debt_created_at'],
      )!,
      isWrittenOff: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_written_off'],
      )!,
      writeOffReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}write_off_reason'],
      )!,
      writtenOffBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}written_off_by'],
      )!,
      writtenOffAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}written_off_at'],
      )!,
      interestRatePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interest_rate_percent'],
      )!,
      interestPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interest_period'],
      )!,
      interestType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interest_type'],
      )!,
      loanDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loan_date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_updated_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      localVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_version'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $DebtsTableTable createAlias(String alias) {
    return $DebtsTableTable(attachedDatabase, alias);
  }
}

class DebtsTableData extends DataClass implements Insertable<DebtsTableData> {
  final String id;
  final String businessId;
  final String partyName;
  final String partyPhone;
  final String partyId;
  final String type;
  final double originalAmount;
  final double paidAmount;
  final String dueDate;
  final String status;
  final String invoiceRef;
  final String note;
  final String createdBy;
  final String debtCreatedAt;
  final int isWrittenOff;
  final String writeOffReason;
  final String writtenOffBy;
  final String writtenOffAt;
  final double interestRatePercent;
  final String interestPeriod;
  final String interestType;
  final String loanDate;
  final int createdAt;
  final int updatedAt;
  final int? serverUpdatedAt;
  final String syncStatus;
  final int localVersion;
  final int isDeleted;
  const DebtsTableData({
    required this.id,
    required this.businessId,
    required this.partyName,
    required this.partyPhone,
    required this.partyId,
    required this.type,
    required this.originalAmount,
    required this.paidAmount,
    required this.dueDate,
    required this.status,
    required this.invoiceRef,
    required this.note,
    required this.createdBy,
    required this.debtCreatedAt,
    required this.isWrittenOff,
    required this.writeOffReason,
    required this.writtenOffBy,
    required this.writtenOffAt,
    required this.interestRatePercent,
    required this.interestPeriod,
    required this.interestType,
    required this.loanDate,
    required this.createdAt,
    required this.updatedAt,
    this.serverUpdatedAt,
    required this.syncStatus,
    required this.localVersion,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['party_name'] = Variable<String>(partyName);
    map['party_phone'] = Variable<String>(partyPhone);
    map['party_id'] = Variable<String>(partyId);
    map['type'] = Variable<String>(type);
    map['original_amount'] = Variable<double>(originalAmount);
    map['paid_amount'] = Variable<double>(paidAmount);
    map['due_date'] = Variable<String>(dueDate);
    map['status'] = Variable<String>(status);
    map['invoice_ref'] = Variable<String>(invoiceRef);
    map['note'] = Variable<String>(note);
    map['created_by'] = Variable<String>(createdBy);
    map['debt_created_at'] = Variable<String>(debtCreatedAt);
    map['is_written_off'] = Variable<int>(isWrittenOff);
    map['write_off_reason'] = Variable<String>(writeOffReason);
    map['written_off_by'] = Variable<String>(writtenOffBy);
    map['written_off_at'] = Variable<String>(writtenOffAt);
    map['interest_rate_percent'] = Variable<double>(interestRatePercent);
    map['interest_period'] = Variable<String>(interestPeriod);
    map['interest_type'] = Variable<String>(interestType);
    map['loan_date'] = Variable<String>(loanDate);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['local_version'] = Variable<int>(localVersion);
    map['is_deleted'] = Variable<int>(isDeleted);
    return map;
  }

  DebtsTableCompanion toCompanion(bool nullToAbsent) {
    return DebtsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      partyName: Value(partyName),
      partyPhone: Value(partyPhone),
      partyId: Value(partyId),
      type: Value(type),
      originalAmount: Value(originalAmount),
      paidAmount: Value(paidAmount),
      dueDate: Value(dueDate),
      status: Value(status),
      invoiceRef: Value(invoiceRef),
      note: Value(note),
      createdBy: Value(createdBy),
      debtCreatedAt: Value(debtCreatedAt),
      isWrittenOff: Value(isWrittenOff),
      writeOffReason: Value(writeOffReason),
      writtenOffBy: Value(writtenOffBy),
      writtenOffAt: Value(writtenOffAt),
      interestRatePercent: Value(interestRatePercent),
      interestPeriod: Value(interestPeriod),
      interestType: Value(interestType),
      loanDate: Value(loanDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      localVersion: Value(localVersion),
      isDeleted: Value(isDeleted),
    );
  }

  factory DebtsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DebtsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      partyName: serializer.fromJson<String>(json['partyName']),
      partyPhone: serializer.fromJson<String>(json['partyPhone']),
      partyId: serializer.fromJson<String>(json['partyId']),
      type: serializer.fromJson<String>(json['type']),
      originalAmount: serializer.fromJson<double>(json['originalAmount']),
      paidAmount: serializer.fromJson<double>(json['paidAmount']),
      dueDate: serializer.fromJson<String>(json['dueDate']),
      status: serializer.fromJson<String>(json['status']),
      invoiceRef: serializer.fromJson<String>(json['invoiceRef']),
      note: serializer.fromJson<String>(json['note']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      debtCreatedAt: serializer.fromJson<String>(json['debtCreatedAt']),
      isWrittenOff: serializer.fromJson<int>(json['isWrittenOff']),
      writeOffReason: serializer.fromJson<String>(json['writeOffReason']),
      writtenOffBy: serializer.fromJson<String>(json['writtenOffBy']),
      writtenOffAt: serializer.fromJson<String>(json['writtenOffAt']),
      interestRatePercent: serializer.fromJson<double>(
        json['interestRatePercent'],
      ),
      interestPeriod: serializer.fromJson<String>(json['interestPeriod']),
      interestType: serializer.fromJson<String>(json['interestType']),
      loanDate: serializer.fromJson<String>(json['loanDate']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      serverUpdatedAt: serializer.fromJson<int?>(json['serverUpdatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      localVersion: serializer.fromJson<int>(json['localVersion']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'partyName': serializer.toJson<String>(partyName),
      'partyPhone': serializer.toJson<String>(partyPhone),
      'partyId': serializer.toJson<String>(partyId),
      'type': serializer.toJson<String>(type),
      'originalAmount': serializer.toJson<double>(originalAmount),
      'paidAmount': serializer.toJson<double>(paidAmount),
      'dueDate': serializer.toJson<String>(dueDate),
      'status': serializer.toJson<String>(status),
      'invoiceRef': serializer.toJson<String>(invoiceRef),
      'note': serializer.toJson<String>(note),
      'createdBy': serializer.toJson<String>(createdBy),
      'debtCreatedAt': serializer.toJson<String>(debtCreatedAt),
      'isWrittenOff': serializer.toJson<int>(isWrittenOff),
      'writeOffReason': serializer.toJson<String>(writeOffReason),
      'writtenOffBy': serializer.toJson<String>(writtenOffBy),
      'writtenOffAt': serializer.toJson<String>(writtenOffAt),
      'interestRatePercent': serializer.toJson<double>(interestRatePercent),
      'interestPeriod': serializer.toJson<String>(interestPeriod),
      'interestType': serializer.toJson<String>(interestType),
      'loanDate': serializer.toJson<String>(loanDate),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'serverUpdatedAt': serializer.toJson<int?>(serverUpdatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'localVersion': serializer.toJson<int>(localVersion),
      'isDeleted': serializer.toJson<int>(isDeleted),
    };
  }

  DebtsTableData copyWith({
    String? id,
    String? businessId,
    String? partyName,
    String? partyPhone,
    String? partyId,
    String? type,
    double? originalAmount,
    double? paidAmount,
    String? dueDate,
    String? status,
    String? invoiceRef,
    String? note,
    String? createdBy,
    String? debtCreatedAt,
    int? isWrittenOff,
    String? writeOffReason,
    String? writtenOffBy,
    String? writtenOffAt,
    double? interestRatePercent,
    String? interestPeriod,
    String? interestType,
    String? loanDate,
    int? createdAt,
    int? updatedAt,
    Value<int?> serverUpdatedAt = const Value.absent(),
    String? syncStatus,
    int? localVersion,
    int? isDeleted,
  }) => DebtsTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    partyName: partyName ?? this.partyName,
    partyPhone: partyPhone ?? this.partyPhone,
    partyId: partyId ?? this.partyId,
    type: type ?? this.type,
    originalAmount: originalAmount ?? this.originalAmount,
    paidAmount: paidAmount ?? this.paidAmount,
    dueDate: dueDate ?? this.dueDate,
    status: status ?? this.status,
    invoiceRef: invoiceRef ?? this.invoiceRef,
    note: note ?? this.note,
    createdBy: createdBy ?? this.createdBy,
    debtCreatedAt: debtCreatedAt ?? this.debtCreatedAt,
    isWrittenOff: isWrittenOff ?? this.isWrittenOff,
    writeOffReason: writeOffReason ?? this.writeOffReason,
    writtenOffBy: writtenOffBy ?? this.writtenOffBy,
    writtenOffAt: writtenOffAt ?? this.writtenOffAt,
    interestRatePercent: interestRatePercent ?? this.interestRatePercent,
    interestPeriod: interestPeriod ?? this.interestPeriod,
    interestType: interestType ?? this.interestType,
    loanDate: loanDate ?? this.loanDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    localVersion: localVersion ?? this.localVersion,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  DebtsTableData copyWithCompanion(DebtsTableCompanion data) {
    return DebtsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      partyName: data.partyName.present ? data.partyName.value : this.partyName,
      partyPhone: data.partyPhone.present
          ? data.partyPhone.value
          : this.partyPhone,
      partyId: data.partyId.present ? data.partyId.value : this.partyId,
      type: data.type.present ? data.type.value : this.type,
      originalAmount: data.originalAmount.present
          ? data.originalAmount.value
          : this.originalAmount,
      paidAmount: data.paidAmount.present
          ? data.paidAmount.value
          : this.paidAmount,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      status: data.status.present ? data.status.value : this.status,
      invoiceRef: data.invoiceRef.present
          ? data.invoiceRef.value
          : this.invoiceRef,
      note: data.note.present ? data.note.value : this.note,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      debtCreatedAt: data.debtCreatedAt.present
          ? data.debtCreatedAt.value
          : this.debtCreatedAt,
      isWrittenOff: data.isWrittenOff.present
          ? data.isWrittenOff.value
          : this.isWrittenOff,
      writeOffReason: data.writeOffReason.present
          ? data.writeOffReason.value
          : this.writeOffReason,
      writtenOffBy: data.writtenOffBy.present
          ? data.writtenOffBy.value
          : this.writtenOffBy,
      writtenOffAt: data.writtenOffAt.present
          ? data.writtenOffAt.value
          : this.writtenOffAt,
      interestRatePercent: data.interestRatePercent.present
          ? data.interestRatePercent.value
          : this.interestRatePercent,
      interestPeriod: data.interestPeriod.present
          ? data.interestPeriod.value
          : this.interestPeriod,
      interestType: data.interestType.present
          ? data.interestType.value
          : this.interestType,
      loanDate: data.loanDate.present ? data.loanDate.value : this.loanDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      localVersion: data.localVersion.present
          ? data.localVersion.value
          : this.localVersion,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DebtsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('partyName: $partyName, ')
          ..write('partyPhone: $partyPhone, ')
          ..write('partyId: $partyId, ')
          ..write('type: $type, ')
          ..write('originalAmount: $originalAmount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('invoiceRef: $invoiceRef, ')
          ..write('note: $note, ')
          ..write('createdBy: $createdBy, ')
          ..write('debtCreatedAt: $debtCreatedAt, ')
          ..write('isWrittenOff: $isWrittenOff, ')
          ..write('writeOffReason: $writeOffReason, ')
          ..write('writtenOffBy: $writtenOffBy, ')
          ..write('writtenOffAt: $writtenOffAt, ')
          ..write('interestRatePercent: $interestRatePercent, ')
          ..write('interestPeriod: $interestPeriod, ')
          ..write('interestType: $interestType, ')
          ..write('loanDate: $loanDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localVersion: $localVersion, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    businessId,
    partyName,
    partyPhone,
    partyId,
    type,
    originalAmount,
    paidAmount,
    dueDate,
    status,
    invoiceRef,
    note,
    createdBy,
    debtCreatedAt,
    isWrittenOff,
    writeOffReason,
    writtenOffBy,
    writtenOffAt,
    interestRatePercent,
    interestPeriod,
    interestType,
    loanDate,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    localVersion,
    isDeleted,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DebtsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.partyName == this.partyName &&
          other.partyPhone == this.partyPhone &&
          other.partyId == this.partyId &&
          other.type == this.type &&
          other.originalAmount == this.originalAmount &&
          other.paidAmount == this.paidAmount &&
          other.dueDate == this.dueDate &&
          other.status == this.status &&
          other.invoiceRef == this.invoiceRef &&
          other.note == this.note &&
          other.createdBy == this.createdBy &&
          other.debtCreatedAt == this.debtCreatedAt &&
          other.isWrittenOff == this.isWrittenOff &&
          other.writeOffReason == this.writeOffReason &&
          other.writtenOffBy == this.writtenOffBy &&
          other.writtenOffAt == this.writtenOffAt &&
          other.interestRatePercent == this.interestRatePercent &&
          other.interestPeriod == this.interestPeriod &&
          other.interestType == this.interestType &&
          other.loanDate == this.loanDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.syncStatus == this.syncStatus &&
          other.localVersion == this.localVersion &&
          other.isDeleted == this.isDeleted);
}

class DebtsTableCompanion extends UpdateCompanion<DebtsTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> partyName;
  final Value<String> partyPhone;
  final Value<String> partyId;
  final Value<String> type;
  final Value<double> originalAmount;
  final Value<double> paidAmount;
  final Value<String> dueDate;
  final Value<String> status;
  final Value<String> invoiceRef;
  final Value<String> note;
  final Value<String> createdBy;
  final Value<String> debtCreatedAt;
  final Value<int> isWrittenOff;
  final Value<String> writeOffReason;
  final Value<String> writtenOffBy;
  final Value<String> writtenOffAt;
  final Value<double> interestRatePercent;
  final Value<String> interestPeriod;
  final Value<String> interestType;
  final Value<String> loanDate;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> serverUpdatedAt;
  final Value<String> syncStatus;
  final Value<int> localVersion;
  final Value<int> isDeleted;
  final Value<int> rowid;
  const DebtsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.partyName = const Value.absent(),
    this.partyPhone = const Value.absent(),
    this.partyId = const Value.absent(),
    this.type = const Value.absent(),
    this.originalAmount = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.invoiceRef = const Value.absent(),
    this.note = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.debtCreatedAt = const Value.absent(),
    this.isWrittenOff = const Value.absent(),
    this.writeOffReason = const Value.absent(),
    this.writtenOffBy = const Value.absent(),
    this.writtenOffAt = const Value.absent(),
    this.interestRatePercent = const Value.absent(),
    this.interestPeriod = const Value.absent(),
    this.interestType = const Value.absent(),
    this.loanDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DebtsTableCompanion.insert({
    required String id,
    required String businessId,
    required String partyName,
    this.partyPhone = const Value.absent(),
    this.partyId = const Value.absent(),
    required String type,
    required double originalAmount,
    this.paidAmount = const Value.absent(),
    required String dueDate,
    this.status = const Value.absent(),
    this.invoiceRef = const Value.absent(),
    this.note = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.debtCreatedAt = const Value.absent(),
    this.isWrittenOff = const Value.absent(),
    this.writeOffReason = const Value.absent(),
    this.writtenOffBy = const Value.absent(),
    this.writtenOffAt = const Value.absent(),
    this.interestRatePercent = const Value.absent(),
    this.interestPeriod = const Value.absent(),
    this.interestType = const Value.absent(),
    this.loanDate = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       partyName = Value(partyName),
       type = Value(type),
       originalAmount = Value(originalAmount),
       dueDate = Value(dueDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DebtsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? partyName,
    Expression<String>? partyPhone,
    Expression<String>? partyId,
    Expression<String>? type,
    Expression<double>? originalAmount,
    Expression<double>? paidAmount,
    Expression<String>? dueDate,
    Expression<String>? status,
    Expression<String>? invoiceRef,
    Expression<String>? note,
    Expression<String>? createdBy,
    Expression<String>? debtCreatedAt,
    Expression<int>? isWrittenOff,
    Expression<String>? writeOffReason,
    Expression<String>? writtenOffBy,
    Expression<String>? writtenOffAt,
    Expression<double>? interestRatePercent,
    Expression<String>? interestPeriod,
    Expression<String>? interestType,
    Expression<String>? loanDate,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? serverUpdatedAt,
    Expression<String>? syncStatus,
    Expression<int>? localVersion,
    Expression<int>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (partyName != null) 'party_name': partyName,
      if (partyPhone != null) 'party_phone': partyPhone,
      if (partyId != null) 'party_id': partyId,
      if (type != null) 'type': type,
      if (originalAmount != null) 'original_amount': originalAmount,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (invoiceRef != null) 'invoice_ref': invoiceRef,
      if (note != null) 'note': note,
      if (createdBy != null) 'created_by': createdBy,
      if (debtCreatedAt != null) 'debt_created_at': debtCreatedAt,
      if (isWrittenOff != null) 'is_written_off': isWrittenOff,
      if (writeOffReason != null) 'write_off_reason': writeOffReason,
      if (writtenOffBy != null) 'written_off_by': writtenOffBy,
      if (writtenOffAt != null) 'written_off_at': writtenOffAt,
      if (interestRatePercent != null)
        'interest_rate_percent': interestRatePercent,
      if (interestPeriod != null) 'interest_period': interestPeriod,
      if (interestType != null) 'interest_type': interestType,
      if (loanDate != null) 'loan_date': loanDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localVersion != null) 'local_version': localVersion,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DebtsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? partyName,
    Value<String>? partyPhone,
    Value<String>? partyId,
    Value<String>? type,
    Value<double>? originalAmount,
    Value<double>? paidAmount,
    Value<String>? dueDate,
    Value<String>? status,
    Value<String>? invoiceRef,
    Value<String>? note,
    Value<String>? createdBy,
    Value<String>? debtCreatedAt,
    Value<int>? isWrittenOff,
    Value<String>? writeOffReason,
    Value<String>? writtenOffBy,
    Value<String>? writtenOffAt,
    Value<double>? interestRatePercent,
    Value<String>? interestPeriod,
    Value<String>? interestType,
    Value<String>? loanDate,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? serverUpdatedAt,
    Value<String>? syncStatus,
    Value<int>? localVersion,
    Value<int>? isDeleted,
    Value<int>? rowid,
  }) {
    return DebtsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      partyName: partyName ?? this.partyName,
      partyPhone: partyPhone ?? this.partyPhone,
      partyId: partyId ?? this.partyId,
      type: type ?? this.type,
      originalAmount: originalAmount ?? this.originalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      invoiceRef: invoiceRef ?? this.invoiceRef,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      debtCreatedAt: debtCreatedAt ?? this.debtCreatedAt,
      isWrittenOff: isWrittenOff ?? this.isWrittenOff,
      writeOffReason: writeOffReason ?? this.writeOffReason,
      writtenOffBy: writtenOffBy ?? this.writtenOffBy,
      writtenOffAt: writtenOffAt ?? this.writtenOffAt,
      interestRatePercent: interestRatePercent ?? this.interestRatePercent,
      interestPeriod: interestPeriod ?? this.interestPeriod,
      interestType: interestType ?? this.interestType,
      loanDate: loanDate ?? this.loanDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      localVersion: localVersion ?? this.localVersion,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (partyName.present) {
      map['party_name'] = Variable<String>(partyName.value);
    }
    if (partyPhone.present) {
      map['party_phone'] = Variable<String>(partyPhone.value);
    }
    if (partyId.present) {
      map['party_id'] = Variable<String>(partyId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (originalAmount.present) {
      map['original_amount'] = Variable<double>(originalAmount.value);
    }
    if (paidAmount.present) {
      map['paid_amount'] = Variable<double>(paidAmount.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (invoiceRef.present) {
      map['invoice_ref'] = Variable<String>(invoiceRef.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (debtCreatedAt.present) {
      map['debt_created_at'] = Variable<String>(debtCreatedAt.value);
    }
    if (isWrittenOff.present) {
      map['is_written_off'] = Variable<int>(isWrittenOff.value);
    }
    if (writeOffReason.present) {
      map['write_off_reason'] = Variable<String>(writeOffReason.value);
    }
    if (writtenOffBy.present) {
      map['written_off_by'] = Variable<String>(writtenOffBy.value);
    }
    if (writtenOffAt.present) {
      map['written_off_at'] = Variable<String>(writtenOffAt.value);
    }
    if (interestRatePercent.present) {
      map['interest_rate_percent'] = Variable<double>(
        interestRatePercent.value,
      );
    }
    if (interestPeriod.present) {
      map['interest_period'] = Variable<String>(interestPeriod.value);
    }
    if (interestType.present) {
      map['interest_type'] = Variable<String>(interestType.value);
    }
    if (loanDate.present) {
      map['loan_date'] = Variable<String>(loanDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (localVersion.present) {
      map['local_version'] = Variable<int>(localVersion.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('partyName: $partyName, ')
          ..write('partyPhone: $partyPhone, ')
          ..write('partyId: $partyId, ')
          ..write('type: $type, ')
          ..write('originalAmount: $originalAmount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('invoiceRef: $invoiceRef, ')
          ..write('note: $note, ')
          ..write('createdBy: $createdBy, ')
          ..write('debtCreatedAt: $debtCreatedAt, ')
          ..write('isWrittenOff: $isWrittenOff, ')
          ..write('writeOffReason: $writeOffReason, ')
          ..write('writtenOffBy: $writtenOffBy, ')
          ..write('writtenOffAt: $writtenOffAt, ')
          ..write('interestRatePercent: $interestRatePercent, ')
          ..write('interestPeriod: $interestPeriod, ')
          ..write('interestType: $interestType, ')
          ..write('loanDate: $loanDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localVersion: $localVersion, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DebtPaymentsTableTable extends DebtPaymentsTable
    with TableInfo<$DebtPaymentsTableTable, DebtPaymentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtPaymentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _debtIdMeta = const VerificationMeta('debtId');
  @override
  late final GeneratedColumn<String> debtId = GeneratedColumn<String>(
    'debt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _recordedByMeta = const VerificationMeta(
    'recordedBy',
  );
  @override
  late final GeneratedColumn<String> recordedBy = GeneratedColumn<String>(
    'recorded_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> serverUpdatedAt = GeneratedColumn<int>(
    'server_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_create'),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    debtId,
    businessId,
    amount,
    date,
    method,
    note,
    recordedBy,
    accountId,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debt_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<DebtPaymentsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('debt_id')) {
      context.handle(
        _debtIdMeta,
        debtId.isAcceptableOrUnknown(data['debt_id']!, _debtIdMeta),
      );
    } else if (isInserting) {
      context.missing(_debtIdMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('recorded_by')) {
      context.handle(
        _recordedByMeta,
        recordedBy.isAcceptableOrUnknown(data['recorded_by']!, _recordedByMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DebtPaymentsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DebtPaymentsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      debtId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}debt_id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      recordedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_updated_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $DebtPaymentsTableTable createAlias(String alias) {
    return $DebtPaymentsTableTable(attachedDatabase, alias);
  }
}

class DebtPaymentsTableData extends DataClass
    implements Insertable<DebtPaymentsTableData> {
  final String id;
  final String debtId;
  final String businessId;
  final double amount;
  final String date;
  final String method;
  final String note;
  final String recordedBy;
  final String accountId;
  final int createdAt;
  final int updatedAt;
  final int? serverUpdatedAt;
  final String syncStatus;
  final int isDeleted;
  const DebtPaymentsTableData({
    required this.id,
    required this.debtId,
    required this.businessId,
    required this.amount,
    required this.date,
    required this.method,
    required this.note,
    required this.recordedBy,
    required this.accountId,
    required this.createdAt,
    required this.updatedAt,
    this.serverUpdatedAt,
    required this.syncStatus,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['debt_id'] = Variable<String>(debtId);
    map['business_id'] = Variable<String>(businessId);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<String>(date);
    map['method'] = Variable<String>(method);
    map['note'] = Variable<String>(note);
    map['recorded_by'] = Variable<String>(recordedBy);
    map['account_id'] = Variable<String>(accountId);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['is_deleted'] = Variable<int>(isDeleted);
    return map;
  }

  DebtPaymentsTableCompanion toCompanion(bool nullToAbsent) {
    return DebtPaymentsTableCompanion(
      id: Value(id),
      debtId: Value(debtId),
      businessId: Value(businessId),
      amount: Value(amount),
      date: Value(date),
      method: Value(method),
      note: Value(note),
      recordedBy: Value(recordedBy),
      accountId: Value(accountId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      isDeleted: Value(isDeleted),
    );
  }

  factory DebtPaymentsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DebtPaymentsTableData(
      id: serializer.fromJson<String>(json['id']),
      debtId: serializer.fromJson<String>(json['debtId']),
      businessId: serializer.fromJson<String>(json['businessId']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<String>(json['date']),
      method: serializer.fromJson<String>(json['method']),
      note: serializer.fromJson<String>(json['note']),
      recordedBy: serializer.fromJson<String>(json['recordedBy']),
      accountId: serializer.fromJson<String>(json['accountId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      serverUpdatedAt: serializer.fromJson<int?>(json['serverUpdatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'debtId': serializer.toJson<String>(debtId),
      'businessId': serializer.toJson<String>(businessId),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<String>(date),
      'method': serializer.toJson<String>(method),
      'note': serializer.toJson<String>(note),
      'recordedBy': serializer.toJson<String>(recordedBy),
      'accountId': serializer.toJson<String>(accountId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'serverUpdatedAt': serializer.toJson<int?>(serverUpdatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'isDeleted': serializer.toJson<int>(isDeleted),
    };
  }

  DebtPaymentsTableData copyWith({
    String? id,
    String? debtId,
    String? businessId,
    double? amount,
    String? date,
    String? method,
    String? note,
    String? recordedBy,
    String? accountId,
    int? createdAt,
    int? updatedAt,
    Value<int?> serverUpdatedAt = const Value.absent(),
    String? syncStatus,
    int? isDeleted,
  }) => DebtPaymentsTableData(
    id: id ?? this.id,
    debtId: debtId ?? this.debtId,
    businessId: businessId ?? this.businessId,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    method: method ?? this.method,
    note: note ?? this.note,
    recordedBy: recordedBy ?? this.recordedBy,
    accountId: accountId ?? this.accountId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  DebtPaymentsTableData copyWithCompanion(DebtPaymentsTableCompanion data) {
    return DebtPaymentsTableData(
      id: data.id.present ? data.id.value : this.id,
      debtId: data.debtId.present ? data.debtId.value : this.debtId,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      method: data.method.present ? data.method.value : this.method,
      note: data.note.present ? data.note.value : this.note,
      recordedBy: data.recordedBy.present
          ? data.recordedBy.value
          : this.recordedBy,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DebtPaymentsTableData(')
          ..write('id: $id, ')
          ..write('debtId: $debtId, ')
          ..write('businessId: $businessId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('method: $method, ')
          ..write('note: $note, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('accountId: $accountId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    debtId,
    businessId,
    amount,
    date,
    method,
    note,
    recordedBy,
    accountId,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DebtPaymentsTableData &&
          other.id == this.id &&
          other.debtId == this.debtId &&
          other.businessId == this.businessId &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.method == this.method &&
          other.note == this.note &&
          other.recordedBy == this.recordedBy &&
          other.accountId == this.accountId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.syncStatus == this.syncStatus &&
          other.isDeleted == this.isDeleted);
}

class DebtPaymentsTableCompanion
    extends UpdateCompanion<DebtPaymentsTableData> {
  final Value<String> id;
  final Value<String> debtId;
  final Value<String> businessId;
  final Value<double> amount;
  final Value<String> date;
  final Value<String> method;
  final Value<String> note;
  final Value<String> recordedBy;
  final Value<String> accountId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> serverUpdatedAt;
  final Value<String> syncStatus;
  final Value<int> isDeleted;
  final Value<int> rowid;
  const DebtPaymentsTableCompanion({
    this.id = const Value.absent(),
    this.debtId = const Value.absent(),
    this.businessId = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.method = const Value.absent(),
    this.note = const Value.absent(),
    this.recordedBy = const Value.absent(),
    this.accountId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DebtPaymentsTableCompanion.insert({
    required String id,
    required String debtId,
    required String businessId,
    required double amount,
    required String date,
    this.method = const Value.absent(),
    this.note = const Value.absent(),
    this.recordedBy = const Value.absent(),
    this.accountId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       debtId = Value(debtId),
       businessId = Value(businessId),
       amount = Value(amount),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DebtPaymentsTableData> custom({
    Expression<String>? id,
    Expression<String>? debtId,
    Expression<String>? businessId,
    Expression<double>? amount,
    Expression<String>? date,
    Expression<String>? method,
    Expression<String>? note,
    Expression<String>? recordedBy,
    Expression<String>? accountId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? serverUpdatedAt,
    Expression<String>? syncStatus,
    Expression<int>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (debtId != null) 'debt_id': debtId,
      if (businessId != null) 'business_id': businessId,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (method != null) 'method': method,
      if (note != null) 'note': note,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (accountId != null) 'account_id': accountId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DebtPaymentsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? debtId,
    Value<String>? businessId,
    Value<double>? amount,
    Value<String>? date,
    Value<String>? method,
    Value<String>? note,
    Value<String>? recordedBy,
    Value<String>? accountId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? serverUpdatedAt,
    Value<String>? syncStatus,
    Value<int>? isDeleted,
    Value<int>? rowid,
  }) {
    return DebtPaymentsTableCompanion(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      businessId: businessId ?? this.businessId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      method: method ?? this.method,
      note: note ?? this.note,
      recordedBy: recordedBy ?? this.recordedBy,
      accountId: accountId ?? this.accountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (debtId.present) {
      map['debt_id'] = Variable<String>(debtId.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (recordedBy.present) {
      map['recorded_by'] = Variable<String>(recordedBy.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtPaymentsTableCompanion(')
          ..write('id: $id, ')
          ..write('debtId: $debtId, ')
          ..write('businessId: $businessId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('method: $method, ')
          ..write('note: $note, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('accountId: $accountId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamMembersTableTable extends TeamMembersTable
    with TableInfo<$TeamMembersTableTable, TeamMembersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamMembersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customPermissionsMeta = const VerificationMeta(
    'customPermissions',
  );
  @override
  late final GeneratedColumn<String> customPermissions =
      GeneratedColumn<String>(
        'custom_permissions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _invitedAtMeta = const VerificationMeta(
    'invitedAt',
  );
  @override
  late final GeneratedColumn<int> invitedAt = GeneratedColumn<int>(
    'invited_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acceptedAtMeta = const VerificationMeta(
    'acceptedAt',
  );
  @override
  late final GeneratedColumn<int> acceptedAt = GeneratedColumn<int>(
    'accepted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invitedByMeta = const VerificationMeta(
    'invitedBy',
  );
  @override
  late final GeneratedColumn<String> invitedBy = GeneratedColumn<String>(
    'invited_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dataScopeMeta = const VerificationMeta(
    'dataScope',
  );
  @override
  late final GeneratedColumn<String> dataScope = GeneratedColumn<String>(
    'data_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('all'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> serverUpdatedAt = GeneratedColumn<int>(
    'server_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_create'),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    email,
    phone,
    role,
    customPermissions,
    status,
    invitedAt,
    acceptedAt,
    invitedBy,
    notes,
    userId,
    dataScope,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'team_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeamMembersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('custom_permissions')) {
      context.handle(
        _customPermissionsMeta,
        customPermissions.isAcceptableOrUnknown(
          data['custom_permissions']!,
          _customPermissionsMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('invited_at')) {
      context.handle(
        _invitedAtMeta,
        invitedAt.isAcceptableOrUnknown(data['invited_at']!, _invitedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_invitedAtMeta);
    }
    if (data.containsKey('accepted_at')) {
      context.handle(
        _acceptedAtMeta,
        acceptedAt.isAcceptableOrUnknown(data['accepted_at']!, _acceptedAtMeta),
      );
    }
    if (data.containsKey('invited_by')) {
      context.handle(
        _invitedByMeta,
        invitedBy.isAcceptableOrUnknown(data['invited_by']!, _invitedByMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('data_scope')) {
      context.handle(
        _dataScopeMeta,
        dataScope.isAcceptableOrUnknown(data['data_scope']!, _dataScopeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeamMembersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeamMembersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      customPermissions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_permissions'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      invitedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}invited_at'],
      )!,
      acceptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accepted_at'],
      ),
      invitedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invited_by'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      dataScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_scope'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_updated_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $TeamMembersTableTable createAlias(String alias) {
    return $TeamMembersTableTable(attachedDatabase, alias);
  }
}

class TeamMembersTableData extends DataClass
    implements Insertable<TeamMembersTableData> {
  final String id;
  final String businessId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String customPermissions;
  final String status;
  final int invitedAt;
  final int? acceptedAt;
  final String invitedBy;
  final String notes;
  final String userId;
  final String dataScope;
  final int createdAt;
  final int updatedAt;
  final int? serverUpdatedAt;
  final String syncStatus;
  final int isDeleted;
  const TeamMembersTableData({
    required this.id,
    required this.businessId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.customPermissions,
    required this.status,
    required this.invitedAt,
    this.acceptedAt,
    required this.invitedBy,
    required this.notes,
    required this.userId,
    required this.dataScope,
    required this.createdAt,
    required this.updatedAt,
    this.serverUpdatedAt,
    required this.syncStatus,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    map['phone'] = Variable<String>(phone);
    map['role'] = Variable<String>(role);
    map['custom_permissions'] = Variable<String>(customPermissions);
    map['status'] = Variable<String>(status);
    map['invited_at'] = Variable<int>(invitedAt);
    if (!nullToAbsent || acceptedAt != null) {
      map['accepted_at'] = Variable<int>(acceptedAt);
    }
    map['invited_by'] = Variable<String>(invitedBy);
    map['notes'] = Variable<String>(notes);
    map['user_id'] = Variable<String>(userId);
    map['data_scope'] = Variable<String>(dataScope);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['is_deleted'] = Variable<int>(isDeleted);
    return map;
  }

  TeamMembersTableCompanion toCompanion(bool nullToAbsent) {
    return TeamMembersTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      email: Value(email),
      phone: Value(phone),
      role: Value(role),
      customPermissions: Value(customPermissions),
      status: Value(status),
      invitedAt: Value(invitedAt),
      acceptedAt: acceptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acceptedAt),
      invitedBy: Value(invitedBy),
      notes: Value(notes),
      userId: Value(userId),
      dataScope: Value(dataScope),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      isDeleted: Value(isDeleted),
    );
  }

  factory TeamMembersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeamMembersTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      phone: serializer.fromJson<String>(json['phone']),
      role: serializer.fromJson<String>(json['role']),
      customPermissions: serializer.fromJson<String>(json['customPermissions']),
      status: serializer.fromJson<String>(json['status']),
      invitedAt: serializer.fromJson<int>(json['invitedAt']),
      acceptedAt: serializer.fromJson<int?>(json['acceptedAt']),
      invitedBy: serializer.fromJson<String>(json['invitedBy']),
      notes: serializer.fromJson<String>(json['notes']),
      userId: serializer.fromJson<String>(json['userId']),
      dataScope: serializer.fromJson<String>(json['dataScope']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      serverUpdatedAt: serializer.fromJson<int?>(json['serverUpdatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'phone': serializer.toJson<String>(phone),
      'role': serializer.toJson<String>(role),
      'customPermissions': serializer.toJson<String>(customPermissions),
      'status': serializer.toJson<String>(status),
      'invitedAt': serializer.toJson<int>(invitedAt),
      'acceptedAt': serializer.toJson<int?>(acceptedAt),
      'invitedBy': serializer.toJson<String>(invitedBy),
      'notes': serializer.toJson<String>(notes),
      'userId': serializer.toJson<String>(userId),
      'dataScope': serializer.toJson<String>(dataScope),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'serverUpdatedAt': serializer.toJson<int?>(serverUpdatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'isDeleted': serializer.toJson<int>(isDeleted),
    };
  }

  TeamMembersTableData copyWith({
    String? id,
    String? businessId,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? customPermissions,
    String? status,
    int? invitedAt,
    Value<int?> acceptedAt = const Value.absent(),
    String? invitedBy,
    String? notes,
    String? userId,
    String? dataScope,
    int? createdAt,
    int? updatedAt,
    Value<int?> serverUpdatedAt = const Value.absent(),
    String? syncStatus,
    int? isDeleted,
  }) => TeamMembersTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    role: role ?? this.role,
    customPermissions: customPermissions ?? this.customPermissions,
    status: status ?? this.status,
    invitedAt: invitedAt ?? this.invitedAt,
    acceptedAt: acceptedAt.present ? acceptedAt.value : this.acceptedAt,
    invitedBy: invitedBy ?? this.invitedBy,
    notes: notes ?? this.notes,
    userId: userId ?? this.userId,
    dataScope: dataScope ?? this.dataScope,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  TeamMembersTableData copyWithCompanion(TeamMembersTableCompanion data) {
    return TeamMembersTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      role: data.role.present ? data.role.value : this.role,
      customPermissions: data.customPermissions.present
          ? data.customPermissions.value
          : this.customPermissions,
      status: data.status.present ? data.status.value : this.status,
      invitedAt: data.invitedAt.present ? data.invitedAt.value : this.invitedAt,
      acceptedAt: data.acceptedAt.present
          ? data.acceptedAt.value
          : this.acceptedAt,
      invitedBy: data.invitedBy.present ? data.invitedBy.value : this.invitedBy,
      notes: data.notes.present ? data.notes.value : this.notes,
      userId: data.userId.present ? data.userId.value : this.userId,
      dataScope: data.dataScope.present ? data.dataScope.value : this.dataScope,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeamMembersTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('role: $role, ')
          ..write('customPermissions: $customPermissions, ')
          ..write('status: $status, ')
          ..write('invitedAt: $invitedAt, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('invitedBy: $invitedBy, ')
          ..write('notes: $notes, ')
          ..write('userId: $userId, ')
          ..write('dataScope: $dataScope, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    email,
    phone,
    role,
    customPermissions,
    status,
    invitedAt,
    acceptedAt,
    invitedBy,
    notes,
    userId,
    dataScope,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeamMembersTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.role == this.role &&
          other.customPermissions == this.customPermissions &&
          other.status == this.status &&
          other.invitedAt == this.invitedAt &&
          other.acceptedAt == this.acceptedAt &&
          other.invitedBy == this.invitedBy &&
          other.notes == this.notes &&
          other.userId == this.userId &&
          other.dataScope == this.dataScope &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.syncStatus == this.syncStatus &&
          other.isDeleted == this.isDeleted);
}

class TeamMembersTableCompanion extends UpdateCompanion<TeamMembersTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String> email;
  final Value<String> phone;
  final Value<String> role;
  final Value<String> customPermissions;
  final Value<String> status;
  final Value<int> invitedAt;
  final Value<int?> acceptedAt;
  final Value<String> invitedBy;
  final Value<String> notes;
  final Value<String> userId;
  final Value<String> dataScope;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> serverUpdatedAt;
  final Value<String> syncStatus;
  final Value<int> isDeleted;
  final Value<int> rowid;
  const TeamMembersTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.role = const Value.absent(),
    this.customPermissions = const Value.absent(),
    this.status = const Value.absent(),
    this.invitedAt = const Value.absent(),
    this.acceptedAt = const Value.absent(),
    this.invitedBy = const Value.absent(),
    this.notes = const Value.absent(),
    this.userId = const Value.absent(),
    this.dataScope = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamMembersTableCompanion.insert({
    required String id,
    required String businessId,
    required String name,
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    required String role,
    this.customPermissions = const Value.absent(),
    this.status = const Value.absent(),
    required int invitedAt,
    this.acceptedAt = const Value.absent(),
    this.invitedBy = const Value.absent(),
    this.notes = const Value.absent(),
    this.userId = const Value.absent(),
    this.dataScope = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name),
       role = Value(role),
       invitedAt = Value(invitedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TeamMembersTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? role,
    Expression<String>? customPermissions,
    Expression<String>? status,
    Expression<int>? invitedAt,
    Expression<int>? acceptedAt,
    Expression<String>? invitedBy,
    Expression<String>? notes,
    Expression<String>? userId,
    Expression<String>? dataScope,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? serverUpdatedAt,
    Expression<String>? syncStatus,
    Expression<int>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role,
      if (customPermissions != null) 'custom_permissions': customPermissions,
      if (status != null) 'status': status,
      if (invitedAt != null) 'invited_at': invitedAt,
      if (acceptedAt != null) 'accepted_at': acceptedAt,
      if (invitedBy != null) 'invited_by': invitedBy,
      if (notes != null) 'notes': notes,
      if (userId != null) 'user_id': userId,
      if (dataScope != null) 'data_scope': dataScope,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamMembersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<String>? email,
    Value<String>? phone,
    Value<String>? role,
    Value<String>? customPermissions,
    Value<String>? status,
    Value<int>? invitedAt,
    Value<int?>? acceptedAt,
    Value<String>? invitedBy,
    Value<String>? notes,
    Value<String>? userId,
    Value<String>? dataScope,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? serverUpdatedAt,
    Value<String>? syncStatus,
    Value<int>? isDeleted,
    Value<int>? rowid,
  }) {
    return TeamMembersTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      customPermissions: customPermissions ?? this.customPermissions,
      status: status ?? this.status,
      invitedAt: invitedAt ?? this.invitedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      invitedBy: invitedBy ?? this.invitedBy,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      dataScope: dataScope ?? this.dataScope,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (customPermissions.present) {
      map['custom_permissions'] = Variable<String>(customPermissions.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (invitedAt.present) {
      map['invited_at'] = Variable<int>(invitedAt.value);
    }
    if (acceptedAt.present) {
      map['accepted_at'] = Variable<int>(acceptedAt.value);
    }
    if (invitedBy.present) {
      map['invited_by'] = Variable<String>(invitedBy.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (dataScope.present) {
      map['data_scope'] = Variable<String>(dataScope.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamMembersTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('role: $role, ')
          ..write('customPermissions: $customPermissions, ')
          ..write('status: $status, ')
          ..write('invitedAt: $invitedAt, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('invitedBy: $invitedBy, ')
          ..write('notes: $notes, ')
          ..write('userId: $userId, ')
          ..write('dataScope: $dataScope, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashAccountsTableTable extends CashAccountsTable
    with TableInfo<$CashAccountsTableTable, CashAccountsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashAccountsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _accountNumberMeta = const VerificationMeta(
    'accountNumber',
  );
  @override
  late final GeneratedColumn<String> accountNumber = GeneratedColumn<String>(
    'account_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('TZS'),
  );
  static const VerificationMeta _lastReconciledMeta = const VerificationMeta(
    'lastReconciled',
  );
  @override
  late final GeneratedColumn<String> lastReconciled = GeneratedColumn<String>(
    'last_reconciled',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> serverUpdatedAt = GeneratedColumn<int>(
    'server_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_create'),
  );
  static const VerificationMeta _localVersionMeta = const VerificationMeta(
    'localVersion',
  );
  @override
  late final GeneratedColumn<int> localVersion = GeneratedColumn<int>(
    'local_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    type,
    balance,
    accountNumber,
    currency,
    lastReconciled,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    localVersion,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashAccountsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    }
    if (data.containsKey('account_number')) {
      context.handle(
        _accountNumberMeta,
        accountNumber.isAcceptableOrUnknown(
          data['account_number']!,
          _accountNumberMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('last_reconciled')) {
      context.handle(
        _lastReconciledMeta,
        lastReconciled.isAcceptableOrUnknown(
          data['last_reconciled']!,
          _lastReconciledMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('local_version')) {
      context.handle(
        _localVersionMeta,
        localVersion.isAcceptableOrUnknown(
          data['local_version']!,
          _localVersionMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashAccountsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashAccountsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance'],
      )!,
      accountNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_number'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      lastReconciled: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_reconciled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_updated_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      localVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_version'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $CashAccountsTableTable createAlias(String alias) {
    return $CashAccountsTableTable(attachedDatabase, alias);
  }
}

class CashAccountsTableData extends DataClass
    implements Insertable<CashAccountsTableData> {
  final String id;
  final String businessId;
  final String name;
  final String type;
  final double balance;
  final String accountNumber;
  final String currency;
  final String lastReconciled;
  final int createdAt;
  final int updatedAt;
  final int? serverUpdatedAt;
  final String syncStatus;
  final int localVersion;
  final int isDeleted;
  const CashAccountsTableData({
    required this.id,
    required this.businessId,
    required this.name,
    required this.type,
    required this.balance,
    required this.accountNumber,
    required this.currency,
    required this.lastReconciled,
    required this.createdAt,
    required this.updatedAt,
    this.serverUpdatedAt,
    required this.syncStatus,
    required this.localVersion,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['balance'] = Variable<double>(balance);
    map['account_number'] = Variable<String>(accountNumber);
    map['currency'] = Variable<String>(currency);
    map['last_reconciled'] = Variable<String>(lastReconciled);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['local_version'] = Variable<int>(localVersion);
    map['is_deleted'] = Variable<int>(isDeleted);
    return map;
  }

  CashAccountsTableCompanion toCompanion(bool nullToAbsent) {
    return CashAccountsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      type: Value(type),
      balance: Value(balance),
      accountNumber: Value(accountNumber),
      currency: Value(currency),
      lastReconciled: Value(lastReconciled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      localVersion: Value(localVersion),
      isDeleted: Value(isDeleted),
    );
  }

  factory CashAccountsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashAccountsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      balance: serializer.fromJson<double>(json['balance']),
      accountNumber: serializer.fromJson<String>(json['accountNumber']),
      currency: serializer.fromJson<String>(json['currency']),
      lastReconciled: serializer.fromJson<String>(json['lastReconciled']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      serverUpdatedAt: serializer.fromJson<int?>(json['serverUpdatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      localVersion: serializer.fromJson<int>(json['localVersion']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'balance': serializer.toJson<double>(balance),
      'accountNumber': serializer.toJson<String>(accountNumber),
      'currency': serializer.toJson<String>(currency),
      'lastReconciled': serializer.toJson<String>(lastReconciled),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'serverUpdatedAt': serializer.toJson<int?>(serverUpdatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'localVersion': serializer.toJson<int>(localVersion),
      'isDeleted': serializer.toJson<int>(isDeleted),
    };
  }

  CashAccountsTableData copyWith({
    String? id,
    String? businessId,
    String? name,
    String? type,
    double? balance,
    String? accountNumber,
    String? currency,
    String? lastReconciled,
    int? createdAt,
    int? updatedAt,
    Value<int?> serverUpdatedAt = const Value.absent(),
    String? syncStatus,
    int? localVersion,
    int? isDeleted,
  }) => CashAccountsTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    type: type ?? this.type,
    balance: balance ?? this.balance,
    accountNumber: accountNumber ?? this.accountNumber,
    currency: currency ?? this.currency,
    lastReconciled: lastReconciled ?? this.lastReconciled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    localVersion: localVersion ?? this.localVersion,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  CashAccountsTableData copyWithCompanion(CashAccountsTableCompanion data) {
    return CashAccountsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      balance: data.balance.present ? data.balance.value : this.balance,
      accountNumber: data.accountNumber.present
          ? data.accountNumber.value
          : this.accountNumber,
      currency: data.currency.present ? data.currency.value : this.currency,
      lastReconciled: data.lastReconciled.present
          ? data.lastReconciled.value
          : this.lastReconciled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      localVersion: data.localVersion.present
          ? data.localVersion.value
          : this.localVersion,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashAccountsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('balance: $balance, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('currency: $currency, ')
          ..write('lastReconciled: $lastReconciled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localVersion: $localVersion, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    type,
    balance,
    accountNumber,
    currency,
    lastReconciled,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    localVersion,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashAccountsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.type == this.type &&
          other.balance == this.balance &&
          other.accountNumber == this.accountNumber &&
          other.currency == this.currency &&
          other.lastReconciled == this.lastReconciled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.syncStatus == this.syncStatus &&
          other.localVersion == this.localVersion &&
          other.isDeleted == this.isDeleted);
}

class CashAccountsTableCompanion
    extends UpdateCompanion<CashAccountsTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String> type;
  final Value<double> balance;
  final Value<String> accountNumber;
  final Value<String> currency;
  final Value<String> lastReconciled;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> serverUpdatedAt;
  final Value<String> syncStatus;
  final Value<int> localVersion;
  final Value<int> isDeleted;
  final Value<int> rowid;
  const CashAccountsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.balance = const Value.absent(),
    this.accountNumber = const Value.absent(),
    this.currency = const Value.absent(),
    this.lastReconciled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashAccountsTableCompanion.insert({
    required String id,
    required String businessId,
    required String name,
    required String type,
    this.balance = const Value.absent(),
    this.accountNumber = const Value.absent(),
    this.currency = const Value.absent(),
    this.lastReconciled = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CashAccountsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<double>? balance,
    Expression<String>? accountNumber,
    Expression<String>? currency,
    Expression<String>? lastReconciled,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? serverUpdatedAt,
    Expression<String>? syncStatus,
    Expression<int>? localVersion,
    Expression<int>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (balance != null) 'balance': balance,
      if (accountNumber != null) 'account_number': accountNumber,
      if (currency != null) 'currency': currency,
      if (lastReconciled != null) 'last_reconciled': lastReconciled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localVersion != null) 'local_version': localVersion,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashAccountsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<String>? type,
    Value<double>? balance,
    Value<String>? accountNumber,
    Value<String>? currency,
    Value<String>? lastReconciled,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? serverUpdatedAt,
    Value<String>? syncStatus,
    Value<int>? localVersion,
    Value<int>? isDeleted,
    Value<int>? rowid,
  }) {
    return CashAccountsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      accountNumber: accountNumber ?? this.accountNumber,
      currency: currency ?? this.currency,
      lastReconciled: lastReconciled ?? this.lastReconciled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      localVersion: localVersion ?? this.localVersion,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (accountNumber.present) {
      map['account_number'] = Variable<String>(accountNumber.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (lastReconciled.present) {
      map['last_reconciled'] = Variable<String>(lastReconciled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (localVersion.present) {
      map['local_version'] = Variable<int>(localVersion.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashAccountsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('balance: $balance, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('currency: $currency, ')
          ..write('lastReconciled: $lastReconciled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localVersion: $localVersion, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashTransactionsTableTable extends CashTransactionsTable
    with TableInfo<$CashTransactionsTableTable, CashTransactionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashTransactionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromAccountIdMeta = const VerificationMeta(
    'fromAccountId',
  );
  @override
  late final GeneratedColumn<String> fromAccountId = GeneratedColumn<String>(
    'from_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<String> toAccountId = GeneratedColumn<String>(
    'to_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _activityCategoryMeta = const VerificationMeta(
    'activityCategory',
  );
  @override
  late final GeneratedColumn<String> activityCategory = GeneratedColumn<String>(
    'activity_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('operating'),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> serverUpdatedAt = GeneratedColumn<int>(
    'server_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_create'),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    type,
    amount,
    fromAccountId,
    toAccountId,
    description,
    date,
    reference,
    activityCategory,
    createdBy,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashTransactionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('from_account_id')) {
      context.handle(
        _fromAccountIdMeta,
        fromAccountId.isAcceptableOrUnknown(
          data['from_account_id']!,
          _fromAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('activity_category')) {
      context.handle(
        _activityCategoryMeta,
        activityCategory.isAcceptableOrUnknown(
          data['activity_category']!,
          _activityCategoryMeta,
        ),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashTransactionsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashTransactionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      fromAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_account_id'],
      )!,
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_account_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      activityCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_category'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_updated_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $CashTransactionsTableTable createAlias(String alias) {
    return $CashTransactionsTableTable(attachedDatabase, alias);
  }
}

class CashTransactionsTableData extends DataClass
    implements Insertable<CashTransactionsTableData> {
  final String id;
  final String businessId;
  final String type;
  final double amount;
  final String fromAccountId;
  final String toAccountId;
  final String description;
  final String date;
  final String reference;
  final String activityCategory;
  final String createdBy;
  final int createdAt;
  final int updatedAt;
  final int? serverUpdatedAt;
  final String syncStatus;
  final int isDeleted;
  const CashTransactionsTableData({
    required this.id,
    required this.businessId,
    required this.type,
    required this.amount,
    required this.fromAccountId,
    required this.toAccountId,
    required this.description,
    required this.date,
    required this.reference,
    required this.activityCategory,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.serverUpdatedAt,
    required this.syncStatus,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<double>(amount);
    map['from_account_id'] = Variable<String>(fromAccountId);
    map['to_account_id'] = Variable<String>(toAccountId);
    map['description'] = Variable<String>(description);
    map['date'] = Variable<String>(date);
    map['reference'] = Variable<String>(reference);
    map['activity_category'] = Variable<String>(activityCategory);
    map['created_by'] = Variable<String>(createdBy);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['is_deleted'] = Variable<int>(isDeleted);
    return map;
  }

  CashTransactionsTableCompanion toCompanion(bool nullToAbsent) {
    return CashTransactionsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      type: Value(type),
      amount: Value(amount),
      fromAccountId: Value(fromAccountId),
      toAccountId: Value(toAccountId),
      description: Value(description),
      date: Value(date),
      reference: Value(reference),
      activityCategory: Value(activityCategory),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      isDeleted: Value(isDeleted),
    );
  }

  factory CashTransactionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashTransactionsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<double>(json['amount']),
      fromAccountId: serializer.fromJson<String>(json['fromAccountId']),
      toAccountId: serializer.fromJson<String>(json['toAccountId']),
      description: serializer.fromJson<String>(json['description']),
      date: serializer.fromJson<String>(json['date']),
      reference: serializer.fromJson<String>(json['reference']),
      activityCategory: serializer.fromJson<String>(json['activityCategory']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      serverUpdatedAt: serializer.fromJson<int?>(json['serverUpdatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<double>(amount),
      'fromAccountId': serializer.toJson<String>(fromAccountId),
      'toAccountId': serializer.toJson<String>(toAccountId),
      'description': serializer.toJson<String>(description),
      'date': serializer.toJson<String>(date),
      'reference': serializer.toJson<String>(reference),
      'activityCategory': serializer.toJson<String>(activityCategory),
      'createdBy': serializer.toJson<String>(createdBy),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'serverUpdatedAt': serializer.toJson<int?>(serverUpdatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'isDeleted': serializer.toJson<int>(isDeleted),
    };
  }

  CashTransactionsTableData copyWith({
    String? id,
    String? businessId,
    String? type,
    double? amount,
    String? fromAccountId,
    String? toAccountId,
    String? description,
    String? date,
    String? reference,
    String? activityCategory,
    String? createdBy,
    int? createdAt,
    int? updatedAt,
    Value<int?> serverUpdatedAt = const Value.absent(),
    String? syncStatus,
    int? isDeleted,
  }) => CashTransactionsTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    fromAccountId: fromAccountId ?? this.fromAccountId,
    toAccountId: toAccountId ?? this.toAccountId,
    description: description ?? this.description,
    date: date ?? this.date,
    reference: reference ?? this.reference,
    activityCategory: activityCategory ?? this.activityCategory,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  CashTransactionsTableData copyWithCompanion(
    CashTransactionsTableCompanion data,
  ) {
    return CashTransactionsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      fromAccountId: data.fromAccountId.present
          ? data.fromAccountId.value
          : this.fromAccountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      description: data.description.present
          ? data.description.value
          : this.description,
      date: data.date.present ? data.date.value : this.date,
      reference: data.reference.present ? data.reference.value : this.reference,
      activityCategory: data.activityCategory.present
          ? data.activityCategory.value
          : this.activityCategory,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashTransactionsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('description: $description, ')
          ..write('date: $date, ')
          ..write('reference: $reference, ')
          ..write('activityCategory: $activityCategory, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    type,
    amount,
    fromAccountId,
    toAccountId,
    description,
    date,
    reference,
    activityCategory,
    createdBy,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashTransactionsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.fromAccountId == this.fromAccountId &&
          other.toAccountId == this.toAccountId &&
          other.description == this.description &&
          other.date == this.date &&
          other.reference == this.reference &&
          other.activityCategory == this.activityCategory &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.syncStatus == this.syncStatus &&
          other.isDeleted == this.isDeleted);
}

class CashTransactionsTableCompanion
    extends UpdateCompanion<CashTransactionsTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> type;
  final Value<double> amount;
  final Value<String> fromAccountId;
  final Value<String> toAccountId;
  final Value<String> description;
  final Value<String> date;
  final Value<String> reference;
  final Value<String> activityCategory;
  final Value<String> createdBy;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> serverUpdatedAt;
  final Value<String> syncStatus;
  final Value<int> isDeleted;
  final Value<int> rowid;
  const CashTransactionsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.description = const Value.absent(),
    this.date = const Value.absent(),
    this.reference = const Value.absent(),
    this.activityCategory = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashTransactionsTableCompanion.insert({
    required String id,
    required String businessId,
    required String type,
    required double amount,
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.description = const Value.absent(),
    required String date,
    this.reference = const Value.absent(),
    this.activityCategory = const Value.absent(),
    this.createdBy = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       type = Value(type),
       amount = Value(amount),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CashTransactionsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? type,
    Expression<double>? amount,
    Expression<String>? fromAccountId,
    Expression<String>? toAccountId,
    Expression<String>? description,
    Expression<String>? date,
    Expression<String>? reference,
    Expression<String>? activityCategory,
    Expression<String>? createdBy,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? serverUpdatedAt,
    Expression<String>? syncStatus,
    Expression<int>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (fromAccountId != null) 'from_account_id': fromAccountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (description != null) 'description': description,
      if (date != null) 'date': date,
      if (reference != null) 'reference': reference,
      if (activityCategory != null) 'activity_category': activityCategory,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashTransactionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? type,
    Value<double>? amount,
    Value<String>? fromAccountId,
    Value<String>? toAccountId,
    Value<String>? description,
    Value<String>? date,
    Value<String>? reference,
    Value<String>? activityCategory,
    Value<String>? createdBy,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? serverUpdatedAt,
    Value<String>? syncStatus,
    Value<int>? isDeleted,
    Value<int>? rowid,
  }) {
    return CashTransactionsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      description: description ?? this.description,
      date: date ?? this.date,
      reference: reference ?? this.reference,
      activityCategory: activityCategory ?? this.activityCategory,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (fromAccountId.present) {
      map['from_account_id'] = Variable<String>(fromAccountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<String>(toAccountId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (activityCategory.present) {
      map['activity_category'] = Variable<String>(activityCategory.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashTransactionsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('description: $description, ')
          ..write('date: $date, ')
          ..write('reference: $reference, ')
          ..write('activityCategory: $activityCategory, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyReconciliationsTableTable extends DailyReconciliationsTable
    with
        TableInfo<
          $DailyReconciliationsTableTable,
          DailyReconciliationsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyReconciliationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openingBalanceMeta = const VerificationMeta(
    'openingBalance',
  );
  @override
  late final GeneratedColumn<double> openingBalance = GeneratedColumn<double>(
    'opening_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _closingBalanceMeta = const VerificationMeta(
    'closingBalance',
  );
  @override
  late final GeneratedColumn<double> closingBalance = GeneratedColumn<double>(
    'closing_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalDepositsMeta = const VerificationMeta(
    'totalDeposits',
  );
  @override
  late final GeneratedColumn<double> totalDeposits = GeneratedColumn<double>(
    'total_deposits',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalWithdrawalsMeta = const VerificationMeta(
    'totalWithdrawals',
  );
  @override
  late final GeneratedColumn<double> totalWithdrawals = GeneratedColumn<double>(
    'total_withdrawals',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _reconciledByMeta = const VerificationMeta(
    'reconciledBy',
  );
  @override
  late final GeneratedColumn<String> reconciledBy = GeneratedColumn<String>(
    'reconciled_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isReconciledMeta = const VerificationMeta(
    'isReconciled',
  );
  @override
  late final GeneratedColumn<int> isReconciled = GeneratedColumn<int>(
    'is_reconciled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> serverUpdatedAt = GeneratedColumn<int>(
    'server_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_create'),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    accountId,
    date,
    openingBalance,
    closingBalance,
    totalDeposits,
    totalWithdrawals,
    notes,
    reconciledBy,
    isReconciled,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_reconciliations';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyReconciliationsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
        _openingBalanceMeta,
        openingBalance.isAcceptableOrUnknown(
          data['opening_balance']!,
          _openingBalanceMeta,
        ),
      );
    }
    if (data.containsKey('closing_balance')) {
      context.handle(
        _closingBalanceMeta,
        closingBalance.isAcceptableOrUnknown(
          data['closing_balance']!,
          _closingBalanceMeta,
        ),
      );
    }
    if (data.containsKey('total_deposits')) {
      context.handle(
        _totalDepositsMeta,
        totalDeposits.isAcceptableOrUnknown(
          data['total_deposits']!,
          _totalDepositsMeta,
        ),
      );
    }
    if (data.containsKey('total_withdrawals')) {
      context.handle(
        _totalWithdrawalsMeta,
        totalWithdrawals.isAcceptableOrUnknown(
          data['total_withdrawals']!,
          _totalWithdrawalsMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('reconciled_by')) {
      context.handle(
        _reconciledByMeta,
        reconciledBy.isAcceptableOrUnknown(
          data['reconciled_by']!,
          _reconciledByMeta,
        ),
      );
    }
    if (data.containsKey('is_reconciled')) {
      context.handle(
        _isReconciledMeta,
        isReconciled.isAcceptableOrUnknown(
          data['is_reconciled']!,
          _isReconciledMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyReconciliationsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyReconciliationsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      openingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}opening_balance'],
      )!,
      closingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}closing_balance'],
      )!,
      totalDeposits: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_deposits'],
      )!,
      totalWithdrawals: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_withdrawals'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      reconciledBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reconciled_by'],
      )!,
      isReconciled: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_reconciled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_updated_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $DailyReconciliationsTableTable createAlias(String alias) {
    return $DailyReconciliationsTableTable(attachedDatabase, alias);
  }
}

class DailyReconciliationsTableData extends DataClass
    implements Insertable<DailyReconciliationsTableData> {
  final String id;
  final String businessId;
  final String accountId;
  final String date;
  final double openingBalance;
  final double closingBalance;
  final double totalDeposits;
  final double totalWithdrawals;
  final String notes;
  final String reconciledBy;
  final int isReconciled;
  final int createdAt;
  final int updatedAt;
  final int? serverUpdatedAt;
  final String syncStatus;
  final int isDeleted;
  const DailyReconciliationsTableData({
    required this.id,
    required this.businessId,
    required this.accountId,
    required this.date,
    required this.openingBalance,
    required this.closingBalance,
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.notes,
    required this.reconciledBy,
    required this.isReconciled,
    required this.createdAt,
    required this.updatedAt,
    this.serverUpdatedAt,
    required this.syncStatus,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['account_id'] = Variable<String>(accountId);
    map['date'] = Variable<String>(date);
    map['opening_balance'] = Variable<double>(openingBalance);
    map['closing_balance'] = Variable<double>(closingBalance);
    map['total_deposits'] = Variable<double>(totalDeposits);
    map['total_withdrawals'] = Variable<double>(totalWithdrawals);
    map['notes'] = Variable<String>(notes);
    map['reconciled_by'] = Variable<String>(reconciledBy);
    map['is_reconciled'] = Variable<int>(isReconciled);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['is_deleted'] = Variable<int>(isDeleted);
    return map;
  }

  DailyReconciliationsTableCompanion toCompanion(bool nullToAbsent) {
    return DailyReconciliationsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      accountId: Value(accountId),
      date: Value(date),
      openingBalance: Value(openingBalance),
      closingBalance: Value(closingBalance),
      totalDeposits: Value(totalDeposits),
      totalWithdrawals: Value(totalWithdrawals),
      notes: Value(notes),
      reconciledBy: Value(reconciledBy),
      isReconciled: Value(isReconciled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      syncStatus: Value(syncStatus),
      isDeleted: Value(isDeleted),
    );
  }

  factory DailyReconciliationsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyReconciliationsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      date: serializer.fromJson<String>(json['date']),
      openingBalance: serializer.fromJson<double>(json['openingBalance']),
      closingBalance: serializer.fromJson<double>(json['closingBalance']),
      totalDeposits: serializer.fromJson<double>(json['totalDeposits']),
      totalWithdrawals: serializer.fromJson<double>(json['totalWithdrawals']),
      notes: serializer.fromJson<String>(json['notes']),
      reconciledBy: serializer.fromJson<String>(json['reconciledBy']),
      isReconciled: serializer.fromJson<int>(json['isReconciled']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      serverUpdatedAt: serializer.fromJson<int?>(json['serverUpdatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'accountId': serializer.toJson<String>(accountId),
      'date': serializer.toJson<String>(date),
      'openingBalance': serializer.toJson<double>(openingBalance),
      'closingBalance': serializer.toJson<double>(closingBalance),
      'totalDeposits': serializer.toJson<double>(totalDeposits),
      'totalWithdrawals': serializer.toJson<double>(totalWithdrawals),
      'notes': serializer.toJson<String>(notes),
      'reconciledBy': serializer.toJson<String>(reconciledBy),
      'isReconciled': serializer.toJson<int>(isReconciled),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'serverUpdatedAt': serializer.toJson<int?>(serverUpdatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'isDeleted': serializer.toJson<int>(isDeleted),
    };
  }

  DailyReconciliationsTableData copyWith({
    String? id,
    String? businessId,
    String? accountId,
    String? date,
    double? openingBalance,
    double? closingBalance,
    double? totalDeposits,
    double? totalWithdrawals,
    String? notes,
    String? reconciledBy,
    int? isReconciled,
    int? createdAt,
    int? updatedAt,
    Value<int?> serverUpdatedAt = const Value.absent(),
    String? syncStatus,
    int? isDeleted,
  }) => DailyReconciliationsTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    accountId: accountId ?? this.accountId,
    date: date ?? this.date,
    openingBalance: openingBalance ?? this.openingBalance,
    closingBalance: closingBalance ?? this.closingBalance,
    totalDeposits: totalDeposits ?? this.totalDeposits,
    totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
    notes: notes ?? this.notes,
    reconciledBy: reconciledBy ?? this.reconciledBy,
    isReconciled: isReconciled ?? this.isReconciled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  DailyReconciliationsTableData copyWithCompanion(
    DailyReconciliationsTableCompanion data,
  ) {
    return DailyReconciliationsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      date: data.date.present ? data.date.value : this.date,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      closingBalance: data.closingBalance.present
          ? data.closingBalance.value
          : this.closingBalance,
      totalDeposits: data.totalDeposits.present
          ? data.totalDeposits.value
          : this.totalDeposits,
      totalWithdrawals: data.totalWithdrawals.present
          ? data.totalWithdrawals.value
          : this.totalWithdrawals,
      notes: data.notes.present ? data.notes.value : this.notes,
      reconciledBy: data.reconciledBy.present
          ? data.reconciledBy.value
          : this.reconciledBy,
      isReconciled: data.isReconciled.present
          ? data.isReconciled.value
          : this.isReconciled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyReconciliationsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('accountId: $accountId, ')
          ..write('date: $date, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('closingBalance: $closingBalance, ')
          ..write('totalDeposits: $totalDeposits, ')
          ..write('totalWithdrawals: $totalWithdrawals, ')
          ..write('notes: $notes, ')
          ..write('reconciledBy: $reconciledBy, ')
          ..write('isReconciled: $isReconciled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    accountId,
    date,
    openingBalance,
    closingBalance,
    totalDeposits,
    totalWithdrawals,
    notes,
    reconciledBy,
    isReconciled,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyReconciliationsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.accountId == this.accountId &&
          other.date == this.date &&
          other.openingBalance == this.openingBalance &&
          other.closingBalance == this.closingBalance &&
          other.totalDeposits == this.totalDeposits &&
          other.totalWithdrawals == this.totalWithdrawals &&
          other.notes == this.notes &&
          other.reconciledBy == this.reconciledBy &&
          other.isReconciled == this.isReconciled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.syncStatus == this.syncStatus &&
          other.isDeleted == this.isDeleted);
}

class DailyReconciliationsTableCompanion
    extends UpdateCompanion<DailyReconciliationsTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> accountId;
  final Value<String> date;
  final Value<double> openingBalance;
  final Value<double> closingBalance;
  final Value<double> totalDeposits;
  final Value<double> totalWithdrawals;
  final Value<String> notes;
  final Value<String> reconciledBy;
  final Value<int> isReconciled;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> serverUpdatedAt;
  final Value<String> syncStatus;
  final Value<int> isDeleted;
  final Value<int> rowid;
  const DailyReconciliationsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.date = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.closingBalance = const Value.absent(),
    this.totalDeposits = const Value.absent(),
    this.totalWithdrawals = const Value.absent(),
    this.notes = const Value.absent(),
    this.reconciledBy = const Value.absent(),
    this.isReconciled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyReconciliationsTableCompanion.insert({
    required String id,
    required String businessId,
    required String accountId,
    required String date,
    this.openingBalance = const Value.absent(),
    this.closingBalance = const Value.absent(),
    this.totalDeposits = const Value.absent(),
    this.totalWithdrawals = const Value.absent(),
    this.notes = const Value.absent(),
    this.reconciledBy = const Value.absent(),
    this.isReconciled = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.serverUpdatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       accountId = Value(accountId),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DailyReconciliationsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? accountId,
    Expression<String>? date,
    Expression<double>? openingBalance,
    Expression<double>? closingBalance,
    Expression<double>? totalDeposits,
    Expression<double>? totalWithdrawals,
    Expression<String>? notes,
    Expression<String>? reconciledBy,
    Expression<int>? isReconciled,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? serverUpdatedAt,
    Expression<String>? syncStatus,
    Expression<int>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (accountId != null) 'account_id': accountId,
      if (date != null) 'date': date,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (closingBalance != null) 'closing_balance': closingBalance,
      if (totalDeposits != null) 'total_deposits': totalDeposits,
      if (totalWithdrawals != null) 'total_withdrawals': totalWithdrawals,
      if (notes != null) 'notes': notes,
      if (reconciledBy != null) 'reconciled_by': reconciledBy,
      if (isReconciled != null) 'is_reconciled': isReconciled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyReconciliationsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? accountId,
    Value<String>? date,
    Value<double>? openingBalance,
    Value<double>? closingBalance,
    Value<double>? totalDeposits,
    Value<double>? totalWithdrawals,
    Value<String>? notes,
    Value<String>? reconciledBy,
    Value<int>? isReconciled,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? serverUpdatedAt,
    Value<String>? syncStatus,
    Value<int>? isDeleted,
    Value<int>? rowid,
  }) {
    return DailyReconciliationsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      openingBalance: openingBalance ?? this.openingBalance,
      closingBalance: closingBalance ?? this.closingBalance,
      totalDeposits: totalDeposits ?? this.totalDeposits,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      notes: notes ?? this.notes,
      reconciledBy: reconciledBy ?? this.reconciledBy,
      isReconciled: isReconciled ?? this.isReconciled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<double>(openingBalance.value);
    }
    if (closingBalance.present) {
      map['closing_balance'] = Variable<double>(closingBalance.value);
    }
    if (totalDeposits.present) {
      map['total_deposits'] = Variable<double>(totalDeposits.value);
    }
    if (totalWithdrawals.present) {
      map['total_withdrawals'] = Variable<double>(totalWithdrawals.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (reconciledBy.present) {
      map['reconciled_by'] = Variable<String>(reconciledBy.value);
    }
    if (isReconciled.present) {
      map['is_reconciled'] = Variable<int>(isReconciled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<int>(serverUpdatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyReconciliationsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('accountId: $accountId, ')
          ..write('date: $date, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('closingBalance: $closingBalance, ')
          ..write('totalDeposits: $totalDeposits, ')
          ..write('totalWithdrawals: $totalWithdrawals, ')
          ..write('notes: $notes, ')
          ..write('reconciledBy: $reconciledBy, ')
          ..write('isReconciled: $isReconciled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MasterCategoriesTableTable extends MasterCategoriesTable
    with TableInfo<$MasterCategoriesTableTable, MasterCategoriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MasterCategoriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessTypeMeta = const VerificationMeta(
    'businessType',
  );
  @override
  late final GeneratedColumn<String> businessType = GeneratedColumn<String>(
    'business_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryNameSwMeta = const VerificationMeta(
    'categoryNameSw',
  );
  @override
  late final GeneratedColumn<String> categoryNameSw = GeneratedColumn<String>(
    'category_name_sw',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categorySlugMeta = const VerificationMeta(
    'categorySlug',
  );
  @override
  late final GeneratedColumn<String> categorySlug = GeneratedColumn<String>(
    'category_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessType,
    categoryName,
    categoryNameSw,
    categorySlug,
    icon,
    displayOrder,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'master_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<MasterCategoriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_type')) {
      context.handle(
        _businessTypeMeta,
        businessType.isAcceptableOrUnknown(
          data['business_type']!,
          _businessTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessTypeMeta);
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryNameMeta);
    }
    if (data.containsKey('category_name_sw')) {
      context.handle(
        _categoryNameSwMeta,
        categoryNameSw.isAcceptableOrUnknown(
          data['category_name_sw']!,
          _categoryNameSwMeta,
        ),
      );
    }
    if (data.containsKey('category_slug')) {
      context.handle(
        _categorySlugMeta,
        categorySlug.isAcceptableOrUnknown(
          data['category_slug']!,
          _categorySlugMeta,
        ),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, businessType};
  @override
  MasterCategoriesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MasterCategoriesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_type'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      categoryNameSw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name_sw'],
      )!,
      categorySlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_slug'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $MasterCategoriesTableTable createAlias(String alias) {
    return $MasterCategoriesTableTable(attachedDatabase, alias);
  }
}

class MasterCategoriesTableData extends DataClass
    implements Insertable<MasterCategoriesTableData> {
  final String id;
  final String businessType;
  final String categoryName;
  final String categoryNameSw;
  final String categorySlug;
  final String icon;
  final int displayOrder;
  final int cachedAt;
  const MasterCategoriesTableData({
    required this.id,
    required this.businessType,
    required this.categoryName,
    required this.categoryNameSw,
    required this.categorySlug,
    required this.icon,
    required this.displayOrder,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_type'] = Variable<String>(businessType);
    map['category_name'] = Variable<String>(categoryName);
    map['category_name_sw'] = Variable<String>(categoryNameSw);
    map['category_slug'] = Variable<String>(categorySlug);
    map['icon'] = Variable<String>(icon);
    map['display_order'] = Variable<int>(displayOrder);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  MasterCategoriesTableCompanion toCompanion(bool nullToAbsent) {
    return MasterCategoriesTableCompanion(
      id: Value(id),
      businessType: Value(businessType),
      categoryName: Value(categoryName),
      categoryNameSw: Value(categoryNameSw),
      categorySlug: Value(categorySlug),
      icon: Value(icon),
      displayOrder: Value(displayOrder),
      cachedAt: Value(cachedAt),
    );
  }

  factory MasterCategoriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MasterCategoriesTableData(
      id: serializer.fromJson<String>(json['id']),
      businessType: serializer.fromJson<String>(json['businessType']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      categoryNameSw: serializer.fromJson<String>(json['categoryNameSw']),
      categorySlug: serializer.fromJson<String>(json['categorySlug']),
      icon: serializer.fromJson<String>(json['icon']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessType': serializer.toJson<String>(businessType),
      'categoryName': serializer.toJson<String>(categoryName),
      'categoryNameSw': serializer.toJson<String>(categoryNameSw),
      'categorySlug': serializer.toJson<String>(categorySlug),
      'icon': serializer.toJson<String>(icon),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  MasterCategoriesTableData copyWith({
    String? id,
    String? businessType,
    String? categoryName,
    String? categoryNameSw,
    String? categorySlug,
    String? icon,
    int? displayOrder,
    int? cachedAt,
  }) => MasterCategoriesTableData(
    id: id ?? this.id,
    businessType: businessType ?? this.businessType,
    categoryName: categoryName ?? this.categoryName,
    categoryNameSw: categoryNameSw ?? this.categoryNameSw,
    categorySlug: categorySlug ?? this.categorySlug,
    icon: icon ?? this.icon,
    displayOrder: displayOrder ?? this.displayOrder,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  MasterCategoriesTableData copyWithCompanion(
    MasterCategoriesTableCompanion data,
  ) {
    return MasterCategoriesTableData(
      id: data.id.present ? data.id.value : this.id,
      businessType: data.businessType.present
          ? data.businessType.value
          : this.businessType,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      categoryNameSw: data.categoryNameSw.present
          ? data.categoryNameSw.value
          : this.categoryNameSw,
      categorySlug: data.categorySlug.present
          ? data.categorySlug.value
          : this.categorySlug,
      icon: data.icon.present ? data.icon.value : this.icon,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MasterCategoriesTableData(')
          ..write('id: $id, ')
          ..write('businessType: $businessType, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryNameSw: $categoryNameSw, ')
          ..write('categorySlug: $categorySlug, ')
          ..write('icon: $icon, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessType,
    categoryName,
    categoryNameSw,
    categorySlug,
    icon,
    displayOrder,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MasterCategoriesTableData &&
          other.id == this.id &&
          other.businessType == this.businessType &&
          other.categoryName == this.categoryName &&
          other.categoryNameSw == this.categoryNameSw &&
          other.categorySlug == this.categorySlug &&
          other.icon == this.icon &&
          other.displayOrder == this.displayOrder &&
          other.cachedAt == this.cachedAt);
}

class MasterCategoriesTableCompanion
    extends UpdateCompanion<MasterCategoriesTableData> {
  final Value<String> id;
  final Value<String> businessType;
  final Value<String> categoryName;
  final Value<String> categoryNameSw;
  final Value<String> categorySlug;
  final Value<String> icon;
  final Value<int> displayOrder;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const MasterCategoriesTableCompanion({
    this.id = const Value.absent(),
    this.businessType = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryNameSw = const Value.absent(),
    this.categorySlug = const Value.absent(),
    this.icon = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MasterCategoriesTableCompanion.insert({
    required String id,
    required String businessType,
    required String categoryName,
    this.categoryNameSw = const Value.absent(),
    this.categorySlug = const Value.absent(),
    this.icon = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessType = Value(businessType),
       categoryName = Value(categoryName);
  static Insertable<MasterCategoriesTableData> custom({
    Expression<String>? id,
    Expression<String>? businessType,
    Expression<String>? categoryName,
    Expression<String>? categoryNameSw,
    Expression<String>? categorySlug,
    Expression<String>? icon,
    Expression<int>? displayOrder,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessType != null) 'business_type': businessType,
      if (categoryName != null) 'category_name': categoryName,
      if (categoryNameSw != null) 'category_name_sw': categoryNameSw,
      if (categorySlug != null) 'category_slug': categorySlug,
      if (icon != null) 'icon': icon,
      if (displayOrder != null) 'display_order': displayOrder,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MasterCategoriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessType,
    Value<String>? categoryName,
    Value<String>? categoryNameSw,
    Value<String>? categorySlug,
    Value<String>? icon,
    Value<int>? displayOrder,
    Value<int>? cachedAt,
    Value<int>? rowid,
  }) {
    return MasterCategoriesTableCompanion(
      id: id ?? this.id,
      businessType: businessType ?? this.businessType,
      categoryName: categoryName ?? this.categoryName,
      categoryNameSw: categoryNameSw ?? this.categoryNameSw,
      categorySlug: categorySlug ?? this.categorySlug,
      icon: icon ?? this.icon,
      displayOrder: displayOrder ?? this.displayOrder,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessType.present) {
      map['business_type'] = Variable<String>(businessType.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (categoryNameSw.present) {
      map['category_name_sw'] = Variable<String>(categoryNameSw.value);
    }
    if (categorySlug.present) {
      map['category_slug'] = Variable<String>(categorySlug.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MasterCategoriesTableCompanion(')
          ..write('id: $id, ')
          ..write('businessType: $businessType, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryNameSw: $categoryNameSw, ')
          ..write('categorySlug: $categorySlug, ')
          ..write('icon: $icon, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MasterProductsTableTable extends MasterProductsTable
    with TableInfo<$MasterProductsTableTable, MasterProductsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MasterProductsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessTypeMeta = const VerificationMeta(
    'businessType',
  );
  @override
  late final GeneratedColumn<String> businessType = GeneratedColumn<String>(
    'business_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categorySlugMeta = const VerificationMeta(
    'categorySlug',
  );
  @override
  late final GeneratedColumn<String> categorySlug = GeneratedColumn<String>(
    'category_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameSwMeta = const VerificationMeta(
    'productNameSw',
  );
  @override
  late final GeneratedColumn<String> productNameSw = GeneratedColumn<String>(
    'product_name_sw',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _productSlugMeta = const VerificationMeta(
    'productSlug',
  );
  @override
  late final GeneratedColumn<String> productSlug = GeneratedColumn<String>(
    'product_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _genericNameMeta = const VerificationMeta(
    'genericName',
  );
  @override
  late final GeneratedColumn<String> genericName = GeneratedColumn<String>(
    'generic_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _brandNamesMeta = const VerificationMeta(
    'brandNames',
  );
  @override
  late final GeneratedColumn<String> brandNames = GeneratedColumn<String>(
    'brand_names',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Piece'),
  );
  static const VerificationMeta _unitAlternativesMeta = const VerificationMeta(
    'unitAlternatives',
  );
  @override
  late final GeneratedColumn<String> unitAlternatives = GeneratedColumn<String>(
    'unit_alternatives',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _commonBarcodesMeta = const VerificationMeta(
    'commonBarcodes',
  );
  @override
  late final GeneratedColumn<String> commonBarcodes = GeneratedColumn<String>(
    'common_barcodes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _searchKeywordsMeta = const VerificationMeta(
    'searchKeywords',
  );
  @override
  late final GeneratedColumn<String> searchKeywords = GeneratedColumn<String>(
    'search_keywords',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _prescriptionRequiredMeta =
      const VerificationMeta('prescriptionRequired');
  @override
  late final GeneratedColumn<int> prescriptionRequired = GeneratedColumn<int>(
    'prescription_required',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _coldStorageMeta = const VerificationMeta(
    'coldStorage',
  );
  @override
  late final GeneratedColumn<int> coldStorage = GeneratedColumn<int>(
    'cold_storage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessType,
    categorySlug,
    productName,
    productNameSw,
    productSlug,
    genericName,
    brandNames,
    unit,
    unitAlternatives,
    commonBarcodes,
    searchKeywords,
    tags,
    prescriptionRequired,
    coldStorage,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'master_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<MasterProductsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_type')) {
      context.handle(
        _businessTypeMeta,
        businessType.isAcceptableOrUnknown(
          data['business_type']!,
          _businessTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessTypeMeta);
    }
    if (data.containsKey('category_slug')) {
      context.handle(
        _categorySlugMeta,
        categorySlug.isAcceptableOrUnknown(
          data['category_slug']!,
          _categorySlugMeta,
        ),
      );
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('product_name_sw')) {
      context.handle(
        _productNameSwMeta,
        productNameSw.isAcceptableOrUnknown(
          data['product_name_sw']!,
          _productNameSwMeta,
        ),
      );
    }
    if (data.containsKey('product_slug')) {
      context.handle(
        _productSlugMeta,
        productSlug.isAcceptableOrUnknown(
          data['product_slug']!,
          _productSlugMeta,
        ),
      );
    }
    if (data.containsKey('generic_name')) {
      context.handle(
        _genericNameMeta,
        genericName.isAcceptableOrUnknown(
          data['generic_name']!,
          _genericNameMeta,
        ),
      );
    }
    if (data.containsKey('brand_names')) {
      context.handle(
        _brandNamesMeta,
        brandNames.isAcceptableOrUnknown(data['brand_names']!, _brandNamesMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('unit_alternatives')) {
      context.handle(
        _unitAlternativesMeta,
        unitAlternatives.isAcceptableOrUnknown(
          data['unit_alternatives']!,
          _unitAlternativesMeta,
        ),
      );
    }
    if (data.containsKey('common_barcodes')) {
      context.handle(
        _commonBarcodesMeta,
        commonBarcodes.isAcceptableOrUnknown(
          data['common_barcodes']!,
          _commonBarcodesMeta,
        ),
      );
    }
    if (data.containsKey('search_keywords')) {
      context.handle(
        _searchKeywordsMeta,
        searchKeywords.isAcceptableOrUnknown(
          data['search_keywords']!,
          _searchKeywordsMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('prescription_required')) {
      context.handle(
        _prescriptionRequiredMeta,
        prescriptionRequired.isAcceptableOrUnknown(
          data['prescription_required']!,
          _prescriptionRequiredMeta,
        ),
      );
    }
    if (data.containsKey('cold_storage')) {
      context.handle(
        _coldStorageMeta,
        coldStorage.isAcceptableOrUnknown(
          data['cold_storage']!,
          _coldStorageMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, businessType};
  @override
  MasterProductsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MasterProductsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_type'],
      )!,
      categorySlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_slug'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      productNameSw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name_sw'],
      )!,
      productSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_slug'],
      )!,
      genericName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}generic_name'],
      )!,
      brandNames: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_names'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      unitAlternatives: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_alternatives'],
      )!,
      commonBarcodes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}common_barcodes'],
      )!,
      searchKeywords: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_keywords'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      prescriptionRequired: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prescription_required'],
      )!,
      coldStorage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cold_storage'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $MasterProductsTableTable createAlias(String alias) {
    return $MasterProductsTableTable(attachedDatabase, alias);
  }
}

class MasterProductsTableData extends DataClass
    implements Insertable<MasterProductsTableData> {
  final String id;
  final String businessType;
  final String categorySlug;
  final String productName;
  final String productNameSw;
  final String productSlug;
  final String genericName;
  final String brandNames;
  final String unit;
  final String unitAlternatives;
  final String commonBarcodes;
  final String searchKeywords;
  final String tags;
  final int prescriptionRequired;
  final int coldStorage;
  final int cachedAt;
  const MasterProductsTableData({
    required this.id,
    required this.businessType,
    required this.categorySlug,
    required this.productName,
    required this.productNameSw,
    required this.productSlug,
    required this.genericName,
    required this.brandNames,
    required this.unit,
    required this.unitAlternatives,
    required this.commonBarcodes,
    required this.searchKeywords,
    required this.tags,
    required this.prescriptionRequired,
    required this.coldStorage,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_type'] = Variable<String>(businessType);
    map['category_slug'] = Variable<String>(categorySlug);
    map['product_name'] = Variable<String>(productName);
    map['product_name_sw'] = Variable<String>(productNameSw);
    map['product_slug'] = Variable<String>(productSlug);
    map['generic_name'] = Variable<String>(genericName);
    map['brand_names'] = Variable<String>(brandNames);
    map['unit'] = Variable<String>(unit);
    map['unit_alternatives'] = Variable<String>(unitAlternatives);
    map['common_barcodes'] = Variable<String>(commonBarcodes);
    map['search_keywords'] = Variable<String>(searchKeywords);
    map['tags'] = Variable<String>(tags);
    map['prescription_required'] = Variable<int>(prescriptionRequired);
    map['cold_storage'] = Variable<int>(coldStorage);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  MasterProductsTableCompanion toCompanion(bool nullToAbsent) {
    return MasterProductsTableCompanion(
      id: Value(id),
      businessType: Value(businessType),
      categorySlug: Value(categorySlug),
      productName: Value(productName),
      productNameSw: Value(productNameSw),
      productSlug: Value(productSlug),
      genericName: Value(genericName),
      brandNames: Value(brandNames),
      unit: Value(unit),
      unitAlternatives: Value(unitAlternatives),
      commonBarcodes: Value(commonBarcodes),
      searchKeywords: Value(searchKeywords),
      tags: Value(tags),
      prescriptionRequired: Value(prescriptionRequired),
      coldStorage: Value(coldStorage),
      cachedAt: Value(cachedAt),
    );
  }

  factory MasterProductsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MasterProductsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessType: serializer.fromJson<String>(json['businessType']),
      categorySlug: serializer.fromJson<String>(json['categorySlug']),
      productName: serializer.fromJson<String>(json['productName']),
      productNameSw: serializer.fromJson<String>(json['productNameSw']),
      productSlug: serializer.fromJson<String>(json['productSlug']),
      genericName: serializer.fromJson<String>(json['genericName']),
      brandNames: serializer.fromJson<String>(json['brandNames']),
      unit: serializer.fromJson<String>(json['unit']),
      unitAlternatives: serializer.fromJson<String>(json['unitAlternatives']),
      commonBarcodes: serializer.fromJson<String>(json['commonBarcodes']),
      searchKeywords: serializer.fromJson<String>(json['searchKeywords']),
      tags: serializer.fromJson<String>(json['tags']),
      prescriptionRequired: serializer.fromJson<int>(
        json['prescriptionRequired'],
      ),
      coldStorage: serializer.fromJson<int>(json['coldStorage']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessType': serializer.toJson<String>(businessType),
      'categorySlug': serializer.toJson<String>(categorySlug),
      'productName': serializer.toJson<String>(productName),
      'productNameSw': serializer.toJson<String>(productNameSw),
      'productSlug': serializer.toJson<String>(productSlug),
      'genericName': serializer.toJson<String>(genericName),
      'brandNames': serializer.toJson<String>(brandNames),
      'unit': serializer.toJson<String>(unit),
      'unitAlternatives': serializer.toJson<String>(unitAlternatives),
      'commonBarcodes': serializer.toJson<String>(commonBarcodes),
      'searchKeywords': serializer.toJson<String>(searchKeywords),
      'tags': serializer.toJson<String>(tags),
      'prescriptionRequired': serializer.toJson<int>(prescriptionRequired),
      'coldStorage': serializer.toJson<int>(coldStorage),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  MasterProductsTableData copyWith({
    String? id,
    String? businessType,
    String? categorySlug,
    String? productName,
    String? productNameSw,
    String? productSlug,
    String? genericName,
    String? brandNames,
    String? unit,
    String? unitAlternatives,
    String? commonBarcodes,
    String? searchKeywords,
    String? tags,
    int? prescriptionRequired,
    int? coldStorage,
    int? cachedAt,
  }) => MasterProductsTableData(
    id: id ?? this.id,
    businessType: businessType ?? this.businessType,
    categorySlug: categorySlug ?? this.categorySlug,
    productName: productName ?? this.productName,
    productNameSw: productNameSw ?? this.productNameSw,
    productSlug: productSlug ?? this.productSlug,
    genericName: genericName ?? this.genericName,
    brandNames: brandNames ?? this.brandNames,
    unit: unit ?? this.unit,
    unitAlternatives: unitAlternatives ?? this.unitAlternatives,
    commonBarcodes: commonBarcodes ?? this.commonBarcodes,
    searchKeywords: searchKeywords ?? this.searchKeywords,
    tags: tags ?? this.tags,
    prescriptionRequired: prescriptionRequired ?? this.prescriptionRequired,
    coldStorage: coldStorage ?? this.coldStorage,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  MasterProductsTableData copyWithCompanion(MasterProductsTableCompanion data) {
    return MasterProductsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessType: data.businessType.present
          ? data.businessType.value
          : this.businessType,
      categorySlug: data.categorySlug.present
          ? data.categorySlug.value
          : this.categorySlug,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      productNameSw: data.productNameSw.present
          ? data.productNameSw.value
          : this.productNameSw,
      productSlug: data.productSlug.present
          ? data.productSlug.value
          : this.productSlug,
      genericName: data.genericName.present
          ? data.genericName.value
          : this.genericName,
      brandNames: data.brandNames.present
          ? data.brandNames.value
          : this.brandNames,
      unit: data.unit.present ? data.unit.value : this.unit,
      unitAlternatives: data.unitAlternatives.present
          ? data.unitAlternatives.value
          : this.unitAlternatives,
      commonBarcodes: data.commonBarcodes.present
          ? data.commonBarcodes.value
          : this.commonBarcodes,
      searchKeywords: data.searchKeywords.present
          ? data.searchKeywords.value
          : this.searchKeywords,
      tags: data.tags.present ? data.tags.value : this.tags,
      prescriptionRequired: data.prescriptionRequired.present
          ? data.prescriptionRequired.value
          : this.prescriptionRequired,
      coldStorage: data.coldStorage.present
          ? data.coldStorage.value
          : this.coldStorage,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MasterProductsTableData(')
          ..write('id: $id, ')
          ..write('businessType: $businessType, ')
          ..write('categorySlug: $categorySlug, ')
          ..write('productName: $productName, ')
          ..write('productNameSw: $productNameSw, ')
          ..write('productSlug: $productSlug, ')
          ..write('genericName: $genericName, ')
          ..write('brandNames: $brandNames, ')
          ..write('unit: $unit, ')
          ..write('unitAlternatives: $unitAlternatives, ')
          ..write('commonBarcodes: $commonBarcodes, ')
          ..write('searchKeywords: $searchKeywords, ')
          ..write('tags: $tags, ')
          ..write('prescriptionRequired: $prescriptionRequired, ')
          ..write('coldStorage: $coldStorage, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessType,
    categorySlug,
    productName,
    productNameSw,
    productSlug,
    genericName,
    brandNames,
    unit,
    unitAlternatives,
    commonBarcodes,
    searchKeywords,
    tags,
    prescriptionRequired,
    coldStorage,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MasterProductsTableData &&
          other.id == this.id &&
          other.businessType == this.businessType &&
          other.categorySlug == this.categorySlug &&
          other.productName == this.productName &&
          other.productNameSw == this.productNameSw &&
          other.productSlug == this.productSlug &&
          other.genericName == this.genericName &&
          other.brandNames == this.brandNames &&
          other.unit == this.unit &&
          other.unitAlternatives == this.unitAlternatives &&
          other.commonBarcodes == this.commonBarcodes &&
          other.searchKeywords == this.searchKeywords &&
          other.tags == this.tags &&
          other.prescriptionRequired == this.prescriptionRequired &&
          other.coldStorage == this.coldStorage &&
          other.cachedAt == this.cachedAt);
}

class MasterProductsTableCompanion
    extends UpdateCompanion<MasterProductsTableData> {
  final Value<String> id;
  final Value<String> businessType;
  final Value<String> categorySlug;
  final Value<String> productName;
  final Value<String> productNameSw;
  final Value<String> productSlug;
  final Value<String> genericName;
  final Value<String> brandNames;
  final Value<String> unit;
  final Value<String> unitAlternatives;
  final Value<String> commonBarcodes;
  final Value<String> searchKeywords;
  final Value<String> tags;
  final Value<int> prescriptionRequired;
  final Value<int> coldStorage;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const MasterProductsTableCompanion({
    this.id = const Value.absent(),
    this.businessType = const Value.absent(),
    this.categorySlug = const Value.absent(),
    this.productName = const Value.absent(),
    this.productNameSw = const Value.absent(),
    this.productSlug = const Value.absent(),
    this.genericName = const Value.absent(),
    this.brandNames = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitAlternatives = const Value.absent(),
    this.commonBarcodes = const Value.absent(),
    this.searchKeywords = const Value.absent(),
    this.tags = const Value.absent(),
    this.prescriptionRequired = const Value.absent(),
    this.coldStorage = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MasterProductsTableCompanion.insert({
    required String id,
    required String businessType,
    this.categorySlug = const Value.absent(),
    required String productName,
    this.productNameSw = const Value.absent(),
    this.productSlug = const Value.absent(),
    this.genericName = const Value.absent(),
    this.brandNames = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitAlternatives = const Value.absent(),
    this.commonBarcodes = const Value.absent(),
    this.searchKeywords = const Value.absent(),
    this.tags = const Value.absent(),
    this.prescriptionRequired = const Value.absent(),
    this.coldStorage = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessType = Value(businessType),
       productName = Value(productName);
  static Insertable<MasterProductsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessType,
    Expression<String>? categorySlug,
    Expression<String>? productName,
    Expression<String>? productNameSw,
    Expression<String>? productSlug,
    Expression<String>? genericName,
    Expression<String>? brandNames,
    Expression<String>? unit,
    Expression<String>? unitAlternatives,
    Expression<String>? commonBarcodes,
    Expression<String>? searchKeywords,
    Expression<String>? tags,
    Expression<int>? prescriptionRequired,
    Expression<int>? coldStorage,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessType != null) 'business_type': businessType,
      if (categorySlug != null) 'category_slug': categorySlug,
      if (productName != null) 'product_name': productName,
      if (productNameSw != null) 'product_name_sw': productNameSw,
      if (productSlug != null) 'product_slug': productSlug,
      if (genericName != null) 'generic_name': genericName,
      if (brandNames != null) 'brand_names': brandNames,
      if (unit != null) 'unit': unit,
      if (unitAlternatives != null) 'unit_alternatives': unitAlternatives,
      if (commonBarcodes != null) 'common_barcodes': commonBarcodes,
      if (searchKeywords != null) 'search_keywords': searchKeywords,
      if (tags != null) 'tags': tags,
      if (prescriptionRequired != null)
        'prescription_required': prescriptionRequired,
      if (coldStorage != null) 'cold_storage': coldStorage,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MasterProductsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessType,
    Value<String>? categorySlug,
    Value<String>? productName,
    Value<String>? productNameSw,
    Value<String>? productSlug,
    Value<String>? genericName,
    Value<String>? brandNames,
    Value<String>? unit,
    Value<String>? unitAlternatives,
    Value<String>? commonBarcodes,
    Value<String>? searchKeywords,
    Value<String>? tags,
    Value<int>? prescriptionRequired,
    Value<int>? coldStorage,
    Value<int>? cachedAt,
    Value<int>? rowid,
  }) {
    return MasterProductsTableCompanion(
      id: id ?? this.id,
      businessType: businessType ?? this.businessType,
      categorySlug: categorySlug ?? this.categorySlug,
      productName: productName ?? this.productName,
      productNameSw: productNameSw ?? this.productNameSw,
      productSlug: productSlug ?? this.productSlug,
      genericName: genericName ?? this.genericName,
      brandNames: brandNames ?? this.brandNames,
      unit: unit ?? this.unit,
      unitAlternatives: unitAlternatives ?? this.unitAlternatives,
      commonBarcodes: commonBarcodes ?? this.commonBarcodes,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      tags: tags ?? this.tags,
      prescriptionRequired: prescriptionRequired ?? this.prescriptionRequired,
      coldStorage: coldStorage ?? this.coldStorage,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessType.present) {
      map['business_type'] = Variable<String>(businessType.value);
    }
    if (categorySlug.present) {
      map['category_slug'] = Variable<String>(categorySlug.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (productNameSw.present) {
      map['product_name_sw'] = Variable<String>(productNameSw.value);
    }
    if (productSlug.present) {
      map['product_slug'] = Variable<String>(productSlug.value);
    }
    if (genericName.present) {
      map['generic_name'] = Variable<String>(genericName.value);
    }
    if (brandNames.present) {
      map['brand_names'] = Variable<String>(brandNames.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (unitAlternatives.present) {
      map['unit_alternatives'] = Variable<String>(unitAlternatives.value);
    }
    if (commonBarcodes.present) {
      map['common_barcodes'] = Variable<String>(commonBarcodes.value);
    }
    if (searchKeywords.present) {
      map['search_keywords'] = Variable<String>(searchKeywords.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (prescriptionRequired.present) {
      map['prescription_required'] = Variable<int>(prescriptionRequired.value);
    }
    if (coldStorage.present) {
      map['cold_storage'] = Variable<int>(coldStorage.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MasterProductsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessType: $businessType, ')
          ..write('categorySlug: $categorySlug, ')
          ..write('productName: $productName, ')
          ..write('productNameSw: $productNameSw, ')
          ..write('productSlug: $productSlug, ')
          ..write('genericName: $genericName, ')
          ..write('brandNames: $brandNames, ')
          ..write('unit: $unit, ')
          ..write('unitAlternatives: $unitAlternatives, ')
          ..write('commonBarcodes: $commonBarcodes, ')
          ..write('searchKeywords: $searchKeywords, ')
          ..write('tags: $tags, ')
          ..write('prescriptionRequired: $prescriptionRequired, ')
          ..write('coldStorage: $coldStorage, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationLogTableTable extends NotificationLogTable
    with TableInfo<$NotificationLogTableTable, NotificationLogTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationLogTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<int> isRead = GeneratedColumn<int>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    type,
    entityId,
    title,
    body,
    isRead,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationLogTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
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
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationLogTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationLogTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_read'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NotificationLogTableTable createAlias(String alias) {
    return $NotificationLogTableTable(attachedDatabase, alias);
  }
}

class NotificationLogTableData extends DataClass
    implements Insertable<NotificationLogTableData> {
  final String id;
  final String businessId;

  /// 'low_stock' | 'overdue_debt' | 'overdue_invoice' | 'sync_failure'
  final String type;

  /// The inventory/debt/invoice id this alert refers to. Null for
  /// sync_failure, which is a single per-business row, not per-entity.
  final String? entityId;
  final String title;
  final String body;
  final int isRead;
  final int createdAt;
  final int updatedAt;
  const NotificationLogTableData({
    required this.id,
    required this.businessId,
    required this.type,
    this.entityId,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['is_read'] = Variable<int>(isRead);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  NotificationLogTableCompanion toCompanion(bool nullToAbsent) {
    return NotificationLogTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      type: Value(type),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      title: Value(title),
      body: Value(body),
      isRead: Value(isRead),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory NotificationLogTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationLogTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      type: serializer.fromJson<String>(json['type']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      isRead: serializer.fromJson<int>(json['isRead']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'type': serializer.toJson<String>(type),
      'entityId': serializer.toJson<String?>(entityId),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'isRead': serializer.toJson<int>(isRead),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  NotificationLogTableData copyWith({
    String? id,
    String? businessId,
    String? type,
    Value<String?> entityId = const Value.absent(),
    String? title,
    String? body,
    int? isRead,
    int? createdAt,
    int? updatedAt,
  }) => NotificationLogTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    type: type ?? this.type,
    entityId: entityId.present ? entityId.value : this.entityId,
    title: title ?? this.title,
    body: body ?? this.body,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NotificationLogTableData copyWithCompanion(
    NotificationLogTableCompanion data,
  ) {
    return NotificationLogTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      type: data.type.present ? data.type.value : this.type,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationLogTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('type: $type, ')
          ..write('entityId: $entityId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    type,
    entityId,
    title,
    body,
    isRead,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationLogTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.type == this.type &&
          other.entityId == this.entityId &&
          other.title == this.title &&
          other.body == this.body &&
          other.isRead == this.isRead &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotificationLogTableCompanion
    extends UpdateCompanion<NotificationLogTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> type;
  final Value<String?> entityId;
  final Value<String> title;
  final Value<String> body;
  final Value<int> isRead;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const NotificationLogTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.type = const Value.absent(),
    this.entityId = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationLogTableCompanion.insert({
    required String id,
    required String businessId,
    required String type,
    this.entityId = const Value.absent(),
    required String title,
    required String body,
    this.isRead = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       type = Value(type),
       title = Value(title),
       body = Value(body),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<NotificationLogTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? type,
    Expression<String>? entityId,
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? isRead,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (type != null) 'type': type,
      if (entityId != null) 'entity_id': entityId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (isRead != null) 'is_read': isRead,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationLogTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? type,
    Value<String?>? entityId,
    Value<String>? title,
    Value<String>? body,
    Value<int>? isRead,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return NotificationLogTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      entityId: entityId ?? this.entityId,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
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
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<int>(isRead.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationLogTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('type: $type, ')
          ..write('entityId: $entityId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $InvoicesTableTable invoicesTable = $InvoicesTableTable(this);
  late final $InvoiceItemsTableTable invoiceItemsTable =
      $InvoiceItemsTableTable(this);
  late final $CustomersTableTable customersTable = $CustomersTableTable(this);
  late final $ExpensesTableTable expensesTable = $ExpensesTableTable(this);
  late final $InventoryTableTable inventoryTable = $InventoryTableTable(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  late final $UserSettingsTableTable userSettingsTable =
      $UserSettingsTableTable(this);
  late final $BusinessSettingsTableTable businessSettingsTable =
      $BusinessSettingsTableTable(this);
  late final $DebtsTableTable debtsTable = $DebtsTableTable(this);
  late final $DebtPaymentsTableTable debtPaymentsTable =
      $DebtPaymentsTableTable(this);
  late final $TeamMembersTableTable teamMembersTable = $TeamMembersTableTable(
    this,
  );
  late final $CashAccountsTableTable cashAccountsTable =
      $CashAccountsTableTable(this);
  late final $CashTransactionsTableTable cashTransactionsTable =
      $CashTransactionsTableTable(this);
  late final $DailyReconciliationsTableTable dailyReconciliationsTable =
      $DailyReconciliationsTableTable(this);
  late final $MasterCategoriesTableTable masterCategoriesTable =
      $MasterCategoriesTableTable(this);
  late final $MasterProductsTableTable masterProductsTable =
      $MasterProductsTableTable(this);
  late final $NotificationLogTableTable notificationLogTable =
      $NotificationLogTableTable(this);
  late final InvoiceDao invoiceDao = InvoiceDao(this as AppDatabase);
  late final CustomerDao customerDao = CustomerDao(this as AppDatabase);
  late final ExpenseDao expenseDao = ExpenseDao(this as AppDatabase);
  late final InventoryDao inventoryDao = InventoryDao(this as AppDatabase);
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final DebtDao debtDao = DebtDao(this as AppDatabase);
  late final TeamDao teamDao = TeamDao(this as AppDatabase);
  late final CashFlowDao cashFlowDao = CashFlowDao(this as AppDatabase);
  late final MasterCatalogDao masterCatalogDao = MasterCatalogDao(
    this as AppDatabase,
  );
  late final NotificationLogDao notificationLogDao = NotificationLogDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    invoicesTable,
    invoiceItemsTable,
    customersTable,
    expensesTable,
    inventoryTable,
    syncQueueTable,
    userSettingsTable,
    businessSettingsTable,
    debtsTable,
    debtPaymentsTable,
    teamMembersTable,
    cashAccountsTable,
    cashTransactionsTable,
    dailyReconciliationsTable,
    masterCategoriesTable,
    masterProductsTable,
    notificationLogTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'invoices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('invoice_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$InvoicesTableTableCreateCompanionBuilder =
    InvoicesTableCompanion Function({
      required String id,
      required String businessId,
      required String customerId,
      required String customerName,
      Value<String> customerPhone,
      required String invoiceNumber,
      required String date,
      required String dueDate,
      Value<String> status,
      Value<String> docType,
      required double subtotal,
      Value<double> discountAmount,
      required double tax,
      required double total,
      Value<double> amountPaid,
      Value<String> paymentMethod,
      Value<String> paymentAccountId,
      Value<String> note,
      Value<String> createdBy,
      Value<int> hasReturn,
      Value<double> returnedAmount,
      Value<String> creditNoteNumber,
      required int createdAt,
      required int updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> localVersion,
      Value<int> isDeleted,
      Value<int> rowid,
    });
typedef $$InvoicesTableTableUpdateCompanionBuilder =
    InvoicesTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> customerId,
      Value<String> customerName,
      Value<String> customerPhone,
      Value<String> invoiceNumber,
      Value<String> date,
      Value<String> dueDate,
      Value<String> status,
      Value<String> docType,
      Value<double> subtotal,
      Value<double> discountAmount,
      Value<double> tax,
      Value<double> total,
      Value<double> amountPaid,
      Value<String> paymentMethod,
      Value<String> paymentAccountId,
      Value<String> note,
      Value<String> createdBy,
      Value<int> hasReturn,
      Value<double> returnedAmount,
      Value<String> creditNoteNumber,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> localVersion,
      Value<int> isDeleted,
      Value<int> rowid,
    });

final class $$InvoicesTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $InvoicesTableTable, InvoicesTableData> {
  $$InvoicesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $InvoiceItemsTableTable,
    List<InvoiceItemsTableData>
  >
  _invoiceItemsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.invoiceItemsTable,
        aliasName: 'invoices__id__invoice_items__invoice_id',
      );

  $$InvoiceItemsTableTableProcessedTableManager get invoiceItemsTableRefs {
    final manager = $$InvoiceItemsTableTableTableManager(
      $_db,
      $_db.invoiceItemsTable,
    ).filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _invoiceItemsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InvoicesTableTableFilterComposer
    extends Composer<_$AppDatabase, $InvoicesTableTable> {
  $$InvoicesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docType => $composableBuilder(
    column: $table.docType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tax => $composableBuilder(
    column: $table.tax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amountPaid => $composableBuilder(
    column: $table.amountPaid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentAccountId => $composableBuilder(
    column: $table.paymentAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hasReturn => $composableBuilder(
    column: $table.hasReturn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get returnedAmount => $composableBuilder(
    column: $table.returnedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creditNoteNumber => $composableBuilder(
    column: $table.creditNoteNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> invoiceItemsTableRefs(
    Expression<bool> Function($$InvoiceItemsTableTableFilterComposer f) f,
  ) {
    final $$InvoiceItemsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceItemsTable,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceItemsTableTableFilterComposer(
            $db: $db,
            $table: $db.invoiceItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InvoicesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoicesTableTable> {
  $$InvoicesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docType => $composableBuilder(
    column: $table.docType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tax => $composableBuilder(
    column: $table.tax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amountPaid => $composableBuilder(
    column: $table.amountPaid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentAccountId => $composableBuilder(
    column: $table.paymentAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hasReturn => $composableBuilder(
    column: $table.hasReturn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get returnedAmount => $composableBuilder(
    column: $table.returnedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creditNoteNumber => $composableBuilder(
    column: $table.creditNoteNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InvoicesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoicesTableTable> {
  $$InvoicesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get docType =>
      $composableBuilder(column: $table.docType, builder: (column) => column);

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get tax =>
      $composableBuilder(column: $table.tax, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<double> get amountPaid => $composableBuilder(
    column: $table.amountPaid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentAccountId => $composableBuilder(
    column: $table.paymentAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get hasReturn =>
      $composableBuilder(column: $table.hasReturn, builder: (column) => column);

  GeneratedColumn<double> get returnedAmount => $composableBuilder(
    column: $table.returnedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creditNoteNumber => $composableBuilder(
    column: $table.creditNoteNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  Expression<T> invoiceItemsTableRefs<T extends Object>(
    Expression<T> Function($$InvoiceItemsTableTableAnnotationComposer a) f,
  ) {
    final $$InvoiceItemsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.invoiceItemsTable,
          getReferencedColumn: (t) => t.invoiceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InvoiceItemsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.invoiceItemsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$InvoicesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvoicesTableTable,
          InvoicesTableData,
          $$InvoicesTableTableFilterComposer,
          $$InvoicesTableTableOrderingComposer,
          $$InvoicesTableTableAnnotationComposer,
          $$InvoicesTableTableCreateCompanionBuilder,
          $$InvoicesTableTableUpdateCompanionBuilder,
          (InvoicesTableData, $$InvoicesTableTableReferences),
          InvoicesTableData,
          PrefetchHooks Function({bool invoiceItemsTableRefs})
        > {
  $$InvoicesTableTableTableManager(_$AppDatabase db, $InvoicesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoicesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoicesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoicesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String> customerPhone = const Value.absent(),
                Value<String> invoiceNumber = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> dueDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> docType = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> tax = const Value.absent(),
                Value<double> total = const Value.absent(),
                Value<double> amountPaid = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> paymentAccountId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<int> hasReturn = const Value.absent(),
                Value<double> returnedAmount = const Value.absent(),
                Value<String> creditNoteNumber = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> localVersion = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoicesTableCompanion(
                id: id,
                businessId: businessId,
                customerId: customerId,
                customerName: customerName,
                customerPhone: customerPhone,
                invoiceNumber: invoiceNumber,
                date: date,
                dueDate: dueDate,
                status: status,
                docType: docType,
                subtotal: subtotal,
                discountAmount: discountAmount,
                tax: tax,
                total: total,
                amountPaid: amountPaid,
                paymentMethod: paymentMethod,
                paymentAccountId: paymentAccountId,
                note: note,
                createdBy: createdBy,
                hasReturn: hasReturn,
                returnedAmount: returnedAmount,
                creditNoteNumber: creditNoteNumber,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                localVersion: localVersion,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String customerId,
                required String customerName,
                Value<String> customerPhone = const Value.absent(),
                required String invoiceNumber,
                required String date,
                required String dueDate,
                Value<String> status = const Value.absent(),
                Value<String> docType = const Value.absent(),
                required double subtotal,
                Value<double> discountAmount = const Value.absent(),
                required double tax,
                required double total,
                Value<double> amountPaid = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> paymentAccountId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<int> hasReturn = const Value.absent(),
                Value<double> returnedAmount = const Value.absent(),
                Value<String> creditNoteNumber = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> localVersion = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoicesTableCompanion.insert(
                id: id,
                businessId: businessId,
                customerId: customerId,
                customerName: customerName,
                customerPhone: customerPhone,
                invoiceNumber: invoiceNumber,
                date: date,
                dueDate: dueDate,
                status: status,
                docType: docType,
                subtotal: subtotal,
                discountAmount: discountAmount,
                tax: tax,
                total: total,
                amountPaid: amountPaid,
                paymentMethod: paymentMethod,
                paymentAccountId: paymentAccountId,
                note: note,
                createdBy: createdBy,
                hasReturn: hasReturn,
                returnedAmount: returnedAmount,
                creditNoteNumber: creditNoteNumber,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                localVersion: localVersion,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InvoicesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({invoiceItemsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (invoiceItemsTableRefs) db.invoiceItemsTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (invoiceItemsTableRefs)
                    await $_getPrefetchedData<
                      InvoicesTableData,
                      $InvoicesTableTable,
                      InvoiceItemsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$InvoicesTableTableReferences
                          ._invoiceItemsTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$InvoicesTableTableReferences(
                            db,
                            table,
                            p0,
                          ).invoiceItemsTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.invoiceId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$InvoicesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvoicesTableTable,
      InvoicesTableData,
      $$InvoicesTableTableFilterComposer,
      $$InvoicesTableTableOrderingComposer,
      $$InvoicesTableTableAnnotationComposer,
      $$InvoicesTableTableCreateCompanionBuilder,
      $$InvoicesTableTableUpdateCompanionBuilder,
      (InvoicesTableData, $$InvoicesTableTableReferences),
      InvoicesTableData,
      PrefetchHooks Function({bool invoiceItemsTableRefs})
    >;
typedef $$InvoiceItemsTableTableCreateCompanionBuilder =
    InvoiceItemsTableCompanion Function({
      required String id,
      required String invoiceId,
      required String name,
      Value<String> description,
      required double quantity,
      required double unitPrice,
      required double total,
      Value<String> productId,
      Value<int> rowid,
    });
typedef $$InvoiceItemsTableTableUpdateCompanionBuilder =
    InvoiceItemsTableCompanion Function({
      Value<String> id,
      Value<String> invoiceId,
      Value<String> name,
      Value<String> description,
      Value<double> quantity,
      Value<double> unitPrice,
      Value<double> total,
      Value<String> productId,
      Value<int> rowid,
    });

final class $$InvoiceItemsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InvoiceItemsTableTable,
          InvoiceItemsTableData
        > {
  $$InvoiceItemsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $InvoicesTableTable _invoiceIdTable(_$AppDatabase db) =>
      db.invoicesTable.createAlias('invoice_items__invoice_id__invoices__id');

  $$InvoicesTableTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<String>('invoice_id')!;

    final manager = $$InvoicesTableTableTableManager(
      $_db,
      $_db.invoicesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InvoiceItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTableTable> {
  $$InvoiceItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  $$InvoicesTableTableFilterComposer get invoiceId {
    final $$InvoicesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoicesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableTableFilterComposer(
            $db: $db,
            $table: $db.invoicesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTableTable> {
  $$InvoiceItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  $$InvoicesTableTableOrderingComposer get invoiceId {
    final $$InvoicesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoicesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableTableOrderingComposer(
            $db: $db,
            $table: $db.invoicesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTableTable> {
  $$InvoiceItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  $$InvoicesTableTableAnnotationComposer get invoiceId {
    final $$InvoicesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoicesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.invoicesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceItemsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvoiceItemsTableTable,
          InvoiceItemsTableData,
          $$InvoiceItemsTableTableFilterComposer,
          $$InvoiceItemsTableTableOrderingComposer,
          $$InvoiceItemsTableTableAnnotationComposer,
          $$InvoiceItemsTableTableCreateCompanionBuilder,
          $$InvoiceItemsTableTableUpdateCompanionBuilder,
          (InvoiceItemsTableData, $$InvoiceItemsTableTableReferences),
          InvoiceItemsTableData,
          PrefetchHooks Function({bool invoiceId})
        > {
  $$InvoiceItemsTableTableTableManager(
    _$AppDatabase db,
    $InvoiceItemsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoiceItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoiceItemsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoiceItemsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> invoiceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> total = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoiceItemsTableCompanion(
                id: id,
                invoiceId: invoiceId,
                name: name,
                description: description,
                quantity: quantity,
                unitPrice: unitPrice,
                total: total,
                productId: productId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String invoiceId,
                required String name,
                Value<String> description = const Value.absent(),
                required double quantity,
                required double unitPrice,
                required double total,
                Value<String> productId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvoiceItemsTableCompanion.insert(
                id: id,
                invoiceId: invoiceId,
                name: name,
                description: description,
                quantity: quantity,
                unitPrice: unitPrice,
                total: total,
                productId: productId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InvoiceItemsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({invoiceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (invoiceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.invoiceId,
                                referencedTable:
                                    $$InvoiceItemsTableTableReferences
                                        ._invoiceIdTable(db),
                                referencedColumn:
                                    $$InvoiceItemsTableTableReferences
                                        ._invoiceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InvoiceItemsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvoiceItemsTableTable,
      InvoiceItemsTableData,
      $$InvoiceItemsTableTableFilterComposer,
      $$InvoiceItemsTableTableOrderingComposer,
      $$InvoiceItemsTableTableAnnotationComposer,
      $$InvoiceItemsTableTableCreateCompanionBuilder,
      $$InvoiceItemsTableTableUpdateCompanionBuilder,
      (InvoiceItemsTableData, $$InvoiceItemsTableTableReferences),
      InvoiceItemsTableData,
      PrefetchHooks Function({bool invoiceId})
    >;
typedef $$CustomersTableTableCreateCompanionBuilder =
    CustomersTableCompanion Function({
      required String id,
      required String businessId,
      required String name,
      required String phone,
      Value<String> email,
      Value<double> balance,
      Value<String> lastTransactionDate,
      Value<String> tags,
      Value<int> isOrganisation,
      Value<String> tinNumber,
      Value<String> address,
      Value<double> creditLimit,
      Value<String> createdBy,
      Value<String> assignedToUserId,
      required int createdAt,
      required int updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> localVersion,
      Value<int> isDeleted,
      Value<int> rowid,
    });
typedef $$CustomersTableTableUpdateCompanionBuilder =
    CustomersTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<String> phone,
      Value<String> email,
      Value<double> balance,
      Value<String> lastTransactionDate,
      Value<String> tags,
      Value<int> isOrganisation,
      Value<String> tinNumber,
      Value<String> address,
      Value<double> creditLimit,
      Value<String> createdBy,
      Value<String> assignedToUserId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> localVersion,
      Value<int> isDeleted,
      Value<int> rowid,
    });

class $$CustomersTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastTransactionDate => $composableBuilder(
    column: $table.lastTransactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isOrganisation => $composableBuilder(
    column: $table.isOrganisation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tinNumber => $composableBuilder(
    column: $table.tinNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assignedToUserId => $composableBuilder(
    column: $table.assignedToUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastTransactionDate => $composableBuilder(
    column: $table.lastTransactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isOrganisation => $composableBuilder(
    column: $table.isOrganisation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tinNumber => $composableBuilder(
    column: $table.tinNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assignedToUserId => $composableBuilder(
    column: $table.assignedToUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<String> get lastTransactionDate => $composableBuilder(
    column: $table.lastTransactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get isOrganisation => $composableBuilder(
    column: $table.isOrganisation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tinNumber =>
      $composableBuilder(column: $table.tinNumber, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get assignedToUserId => $composableBuilder(
    column: $table.assignedToUserId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$CustomersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTableTable,
          CustomersTableData,
          $$CustomersTableTableFilterComposer,
          $$CustomersTableTableOrderingComposer,
          $$CustomersTableTableAnnotationComposer,
          $$CustomersTableTableCreateCompanionBuilder,
          $$CustomersTableTableUpdateCompanionBuilder,
          (
            CustomersTableData,
            BaseReferences<
              _$AppDatabase,
              $CustomersTableTable,
              CustomersTableData
            >,
          ),
          CustomersTableData,
          PrefetchHooks Function()
        > {
  $$CustomersTableTableTableManager(
    _$AppDatabase db,
    $CustomersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<String> lastTransactionDate = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<int> isOrganisation = const Value.absent(),
                Value<String> tinNumber = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<double> creditLimit = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> assignedToUserId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> localVersion = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersTableCompanion(
                id: id,
                businessId: businessId,
                name: name,
                phone: phone,
                email: email,
                balance: balance,
                lastTransactionDate: lastTransactionDate,
                tags: tags,
                isOrganisation: isOrganisation,
                tinNumber: tinNumber,
                address: address,
                creditLimit: creditLimit,
                createdBy: createdBy,
                assignedToUserId: assignedToUserId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                localVersion: localVersion,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String name,
                required String phone,
                Value<String> email = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<String> lastTransactionDate = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<int> isOrganisation = const Value.absent(),
                Value<String> tinNumber = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<double> creditLimit = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> assignedToUserId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> localVersion = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersTableCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                phone: phone,
                email: email,
                balance: balance,
                lastTransactionDate: lastTransactionDate,
                tags: tags,
                isOrganisation: isOrganisation,
                tinNumber: tinNumber,
                address: address,
                creditLimit: creditLimit,
                createdBy: createdBy,
                assignedToUserId: assignedToUserId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                localVersion: localVersion,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTableTable,
      CustomersTableData,
      $$CustomersTableTableFilterComposer,
      $$CustomersTableTableOrderingComposer,
      $$CustomersTableTableAnnotationComposer,
      $$CustomersTableTableCreateCompanionBuilder,
      $$CustomersTableTableUpdateCompanionBuilder,
      (
        CustomersTableData,
        BaseReferences<_$AppDatabase, $CustomersTableTable, CustomersTableData>,
      ),
      CustomersTableData,
      PrefetchHooks Function()
    >;
typedef $$ExpensesTableTableCreateCompanionBuilder =
    ExpensesTableCompanion Function({
      required String id,
      required String businessId,
      required String category,
      required double amount,
      required String date,
      Value<String> note,
      Value<String> recipient,
      Value<int> isRecurring,
      Value<String> recurrenceType,
      Value<String> nextDueDate,
      Value<String> templateId,
      Value<String> receiptUrl,
      Value<String> paymentMethod,
      Value<String> paymentAccountId,
      Value<String> status,
      Value<String> approvedBy,
      Value<String> createdBy,
      required int createdAt,
      required int updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> localVersion,
      Value<int> isDeleted,
      Value<int> rowid,
    });
typedef $$ExpensesTableTableUpdateCompanionBuilder =
    ExpensesTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> category,
      Value<double> amount,
      Value<String> date,
      Value<String> note,
      Value<String> recipient,
      Value<int> isRecurring,
      Value<String> recurrenceType,
      Value<String> nextDueDate,
      Value<String> templateId,
      Value<String> receiptUrl,
      Value<String> paymentMethod,
      Value<String> paymentAccountId,
      Value<String> status,
      Value<String> approvedBy,
      Value<String> createdBy,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> localVersion,
      Value<int> isDeleted,
      Value<int> rowid,
    });

class $$ExpensesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTableTable> {
  $$ExpensesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipient => $composableBuilder(
    column: $table.recipient,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptUrl => $composableBuilder(
    column: $table.receiptUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentAccountId => $composableBuilder(
    column: $table.paymentAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpensesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTableTable> {
  $$ExpensesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipient => $composableBuilder(
    column: $table.recipient,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptUrl => $composableBuilder(
    column: $table.receiptUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentAccountId => $composableBuilder(
    column: $table.paymentAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpensesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTableTable> {
  $$ExpensesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get recipient =>
      $composableBuilder(column: $table.recipient, builder: (column) => column);

  GeneratedColumn<int> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceType => $composableBuilder(
    column: $table.recurrenceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptUrl => $composableBuilder(
    column: $table.receiptUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentAccountId => $composableBuilder(
    column: $table.paymentAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$ExpensesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTableTable,
          ExpensesTableData,
          $$ExpensesTableTableFilterComposer,
          $$ExpensesTableTableOrderingComposer,
          $$ExpensesTableTableAnnotationComposer,
          $$ExpensesTableTableCreateCompanionBuilder,
          $$ExpensesTableTableUpdateCompanionBuilder,
          (
            ExpensesTableData,
            BaseReferences<
              _$AppDatabase,
              $ExpensesTableTable,
              ExpensesTableData
            >,
          ),
          ExpensesTableData,
          PrefetchHooks Function()
        > {
  $$ExpensesTableTableTableManager(_$AppDatabase db, $ExpensesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> recipient = const Value.absent(),
                Value<int> isRecurring = const Value.absent(),
                Value<String> recurrenceType = const Value.absent(),
                Value<String> nextDueDate = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> receiptUrl = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> paymentAccountId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> approvedBy = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> localVersion = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesTableCompanion(
                id: id,
                businessId: businessId,
                category: category,
                amount: amount,
                date: date,
                note: note,
                recipient: recipient,
                isRecurring: isRecurring,
                recurrenceType: recurrenceType,
                nextDueDate: nextDueDate,
                templateId: templateId,
                receiptUrl: receiptUrl,
                paymentMethod: paymentMethod,
                paymentAccountId: paymentAccountId,
                status: status,
                approvedBy: approvedBy,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                localVersion: localVersion,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String category,
                required double amount,
                required String date,
                Value<String> note = const Value.absent(),
                Value<String> recipient = const Value.absent(),
                Value<int> isRecurring = const Value.absent(),
                Value<String> recurrenceType = const Value.absent(),
                Value<String> nextDueDate = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> receiptUrl = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> paymentAccountId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> approvedBy = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> localVersion = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesTableCompanion.insert(
                id: id,
                businessId: businessId,
                category: category,
                amount: amount,
                date: date,
                note: note,
                recipient: recipient,
                isRecurring: isRecurring,
                recurrenceType: recurrenceType,
                nextDueDate: nextDueDate,
                templateId: templateId,
                receiptUrl: receiptUrl,
                paymentMethod: paymentMethod,
                paymentAccountId: paymentAccountId,
                status: status,
                approvedBy: approvedBy,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                localVersion: localVersion,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpensesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTableTable,
      ExpensesTableData,
      $$ExpensesTableTableFilterComposer,
      $$ExpensesTableTableOrderingComposer,
      $$ExpensesTableTableAnnotationComposer,
      $$ExpensesTableTableCreateCompanionBuilder,
      $$ExpensesTableTableUpdateCompanionBuilder,
      (
        ExpensesTableData,
        BaseReferences<_$AppDatabase, $ExpensesTableTable, ExpensesTableData>,
      ),
      ExpensesTableData,
      PrefetchHooks Function()
    >;
typedef $$InventoryTableTableCreateCompanionBuilder =
    InventoryTableCompanion Function({
      required String id,
      required String businessId,
      required String name,
      Value<String> sku,
      Value<String> barcode,
      Value<String> category,
      Value<String> unit,
      Value<double> quantity,
      Value<double> quantityDelta,
      Value<double> lowStockThreshold,
      Value<double> unitPrice,
      Value<double> costPrice,
      Value<String> description,
      Value<String> imageUrl,
      Value<int> isActive,
      Value<String> createdBy,
      Value<String> metadata,
      required int createdAt,
      required int updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> localVersion,
      Value<int> isDeleted,
      Value<int> rowid,
    });
typedef $$InventoryTableTableUpdateCompanionBuilder =
    InventoryTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<String> sku,
      Value<String> barcode,
      Value<String> category,
      Value<String> unit,
      Value<double> quantity,
      Value<double> quantityDelta,
      Value<double> lowStockThreshold,
      Value<double> unitPrice,
      Value<double> costPrice,
      Value<String> description,
      Value<String> imageUrl,
      Value<int> isActive,
      Value<String> createdBy,
      Value<String> metadata,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> localVersion,
      Value<int> isDeleted,
      Value<int> rowid,
    });

class $$InventoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryTableTable> {
  $$InventoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityDelta => $composableBuilder(
    column: $table.quantityDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryTableTable> {
  $$InventoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityDelta => $composableBuilder(
    column: $table.quantityDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryTableTable> {
  $$InventoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get quantityDelta => $composableBuilder(
    column: $table.quantityDelta,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$InventoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryTableTable,
          InventoryTableData,
          $$InventoryTableTableFilterComposer,
          $$InventoryTableTableOrderingComposer,
          $$InventoryTableTableAnnotationComposer,
          $$InventoryTableTableCreateCompanionBuilder,
          $$InventoryTableTableUpdateCompanionBuilder,
          (
            InventoryTableData,
            BaseReferences<
              _$AppDatabase,
              $InventoryTableTable,
              InventoryTableData
            >,
          ),
          InventoryTableData,
          PrefetchHooks Function()
        > {
  $$InventoryTableTableTableManager(
    _$AppDatabase db,
    $InventoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<String> barcode = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> quantityDelta = const Value.absent(),
                Value<double> lowStockThreshold = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> costPrice = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> imageUrl = const Value.absent(),
                Value<int> isActive = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> metadata = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> localVersion = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryTableCompanion(
                id: id,
                businessId: businessId,
                name: name,
                sku: sku,
                barcode: barcode,
                category: category,
                unit: unit,
                quantity: quantity,
                quantityDelta: quantityDelta,
                lowStockThreshold: lowStockThreshold,
                unitPrice: unitPrice,
                costPrice: costPrice,
                description: description,
                imageUrl: imageUrl,
                isActive: isActive,
                createdBy: createdBy,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                localVersion: localVersion,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String name,
                Value<String> sku = const Value.absent(),
                Value<String> barcode = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> quantityDelta = const Value.absent(),
                Value<double> lowStockThreshold = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> costPrice = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> imageUrl = const Value.absent(),
                Value<int> isActive = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> metadata = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> localVersion = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryTableCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                sku: sku,
                barcode: barcode,
                category: category,
                unit: unit,
                quantity: quantity,
                quantityDelta: quantityDelta,
                lowStockThreshold: lowStockThreshold,
                unitPrice: unitPrice,
                costPrice: costPrice,
                description: description,
                imageUrl: imageUrl,
                isActive: isActive,
                createdBy: createdBy,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                localVersion: localVersion,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryTableTable,
      InventoryTableData,
      $$InventoryTableTableFilterComposer,
      $$InventoryTableTableOrderingComposer,
      $$InventoryTableTableAnnotationComposer,
      $$InventoryTableTableCreateCompanionBuilder,
      $$InventoryTableTableUpdateCompanionBuilder,
      (
        InventoryTableData,
        BaseReferences<_$AppDatabase, $InventoryTableTable, InventoryTableData>,
      ),
      InventoryTableData,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableTableCreateCompanionBuilder =
    SyncQueueTableCompanion Function({
      Value<int> id,
      required String operationId,
      required String entityType,
      required String entityId,
      required String operation,
      required String payload,
      Value<String> status,
      Value<int> attempts,
      Value<int> maxAttempts,
      Value<int> nextRetryAt,
      required int createdAt,
      required int updatedAt,
      Value<String> errorMessage,
      required String checksum,
      required int localVersion,
    });
typedef $$SyncQueueTableTableUpdateCompanionBuilder =
    SyncQueueTableCompanion Function({
      Value<int> id,
      Value<String> operationId,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> operation,
      Value<String> payload,
      Value<String> status,
      Value<int> attempts,
      Value<int> maxAttempts,
      Value<int> nextRetryAt,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> errorMessage,
      Value<String> checksum,
      Value<int> localVersion,
    });

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
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

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxAttempts => $composableBuilder(
    column: $table.maxAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
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

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxAttempts => $composableBuilder(
    column: $table.maxAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get maxAttempts => $composableBuilder(
    column: $table.maxAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => column,
  );
}

class $$SyncQueueTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTableTable,
          SyncQueueTableData,
          $$SyncQueueTableTableFilterComposer,
          $$SyncQueueTableTableOrderingComposer,
          $$SyncQueueTableTableAnnotationComposer,
          $$SyncQueueTableTableCreateCompanionBuilder,
          $$SyncQueueTableTableUpdateCompanionBuilder,
          (
            SyncQueueTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncQueueTableTable,
              SyncQueueTableData
            >,
          ),
          SyncQueueTableData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableTableManager(
    _$AppDatabase db,
    $SyncQueueTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> maxAttempts = const Value.absent(),
                Value<int> nextRetryAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> errorMessage = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<int> localVersion = const Value.absent(),
              }) => SyncQueueTableCompanion(
                id: id,
                operationId: operationId,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payload: payload,
                status: status,
                attempts: attempts,
                maxAttempts: maxAttempts,
                nextRetryAt: nextRetryAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                errorMessage: errorMessage,
                checksum: checksum,
                localVersion: localVersion,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String operationId,
                required String entityType,
                required String entityId,
                required String operation,
                required String payload,
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> maxAttempts = const Value.absent(),
                Value<int> nextRetryAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<String> errorMessage = const Value.absent(),
                required String checksum,
                required int localVersion,
              }) => SyncQueueTableCompanion.insert(
                id: id,
                operationId: operationId,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payload: payload,
                status: status,
                attempts: attempts,
                maxAttempts: maxAttempts,
                nextRetryAt: nextRetryAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                errorMessage: errorMessage,
                checksum: checksum,
                localVersion: localVersion,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTableTable,
      SyncQueueTableData,
      $$SyncQueueTableTableFilterComposer,
      $$SyncQueueTableTableOrderingComposer,
      $$SyncQueueTableTableAnnotationComposer,
      $$SyncQueueTableTableCreateCompanionBuilder,
      $$SyncQueueTableTableUpdateCompanionBuilder,
      (
        SyncQueueTableData,
        BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>,
      ),
      SyncQueueTableData,
      PrefetchHooks Function()
    >;
typedef $$UserSettingsTableTableCreateCompanionBuilder =
    UserSettingsTableCompanion Function({
      Value<int> id,
      required String userId,
      required String businessId,
      Value<int?> lastSyncAt,
      Value<int?> lastOnlineAt,
      Value<int?> offlineSince,
      Value<int> syncOnWifiOnly,
      Value<int> autoSyncInterval,
      Value<String> language,
      Value<String> notificationSettings,
    });
typedef $$UserSettingsTableTableUpdateCompanionBuilder =
    UserSettingsTableCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> businessId,
      Value<int?> lastSyncAt,
      Value<int?> lastOnlineAt,
      Value<int?> offlineSince,
      Value<int> syncOnWifiOnly,
      Value<int> autoSyncInterval,
      Value<String> language,
      Value<String> notificationSettings,
    });

class $$UserSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastOnlineAt => $composableBuilder(
    column: $table.lastOnlineAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offlineSince => $composableBuilder(
    column: $table.offlineSince,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncOnWifiOnly => $composableBuilder(
    column: $table.syncOnWifiOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get autoSyncInterval => $composableBuilder(
    column: $table.autoSyncInterval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notificationSettings => $composableBuilder(
    column: $table.notificationSettings,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastOnlineAt => $composableBuilder(
    column: $table.lastOnlineAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offlineSince => $composableBuilder(
    column: $table.offlineSince,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncOnWifiOnly => $composableBuilder(
    column: $table.syncOnWifiOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get autoSyncInterval => $composableBuilder(
    column: $table.autoSyncInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notificationSettings => $composableBuilder(
    column: $table.notificationSettings,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastOnlineAt => $composableBuilder(
    column: $table.lastOnlineAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offlineSince => $composableBuilder(
    column: $table.offlineSince,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncOnWifiOnly => $composableBuilder(
    column: $table.syncOnWifiOnly,
    builder: (column) => column,
  );

  GeneratedColumn<int> get autoSyncInterval => $composableBuilder(
    column: $table.autoSyncInterval,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get notificationSettings => $composableBuilder(
    column: $table.notificationSettings,
    builder: (column) => column,
  );
}

class $$UserSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSettingsTableTable,
          UserSettingsTableData,
          $$UserSettingsTableTableFilterComposer,
          $$UserSettingsTableTableOrderingComposer,
          $$UserSettingsTableTableAnnotationComposer,
          $$UserSettingsTableTableCreateCompanionBuilder,
          $$UserSettingsTableTableUpdateCompanionBuilder,
          (
            UserSettingsTableData,
            BaseReferences<
              _$AppDatabase,
              $UserSettingsTableTable,
              UserSettingsTableData
            >,
          ),
          UserSettingsTableData,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableTableManager(
    _$AppDatabase db,
    $UserSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
                Value<int?> lastOnlineAt = const Value.absent(),
                Value<int?> offlineSince = const Value.absent(),
                Value<int> syncOnWifiOnly = const Value.absent(),
                Value<int> autoSyncInterval = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> notificationSettings = const Value.absent(),
              }) => UserSettingsTableCompanion(
                id: id,
                userId: userId,
                businessId: businessId,
                lastSyncAt: lastSyncAt,
                lastOnlineAt: lastOnlineAt,
                offlineSince: offlineSince,
                syncOnWifiOnly: syncOnWifiOnly,
                autoSyncInterval: autoSyncInterval,
                language: language,
                notificationSettings: notificationSettings,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String businessId,
                Value<int?> lastSyncAt = const Value.absent(),
                Value<int?> lastOnlineAt = const Value.absent(),
                Value<int?> offlineSince = const Value.absent(),
                Value<int> syncOnWifiOnly = const Value.absent(),
                Value<int> autoSyncInterval = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> notificationSettings = const Value.absent(),
              }) => UserSettingsTableCompanion.insert(
                id: id,
                userId: userId,
                businessId: businessId,
                lastSyncAt: lastSyncAt,
                lastOnlineAt: lastOnlineAt,
                offlineSince: offlineSince,
                syncOnWifiOnly: syncOnWifiOnly,
                autoSyncInterval: autoSyncInterval,
                language: language,
                notificationSettings: notificationSettings,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSettingsTableTable,
      UserSettingsTableData,
      $$UserSettingsTableTableFilterComposer,
      $$UserSettingsTableTableOrderingComposer,
      $$UserSettingsTableTableAnnotationComposer,
      $$UserSettingsTableTableCreateCompanionBuilder,
      $$UserSettingsTableTableUpdateCompanionBuilder,
      (
        UserSettingsTableData,
        BaseReferences<
          _$AppDatabase,
          $UserSettingsTableTable,
          UserSettingsTableData
        >,
      ),
      UserSettingsTableData,
      PrefetchHooks Function()
    >;
typedef $$BusinessSettingsTableTableCreateCompanionBuilder =
    BusinessSettingsTableCompanion Function({
      Value<int> id,
      required String businessId,
      required String businessName,
      Value<String> businessType,
      Value<String> phone,
      Value<String> address,
      Value<String> tinNumber,
      Value<int> vatRegistered,
      Value<double> vatRate,
      Value<String> currency,
      Value<String> invoicePrefix,
      Value<int> nextInvoiceNumber,
      Value<String> logoUrl,
      Value<String> plan,
      Value<int?> planExpiresAt,
      required int updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
    });
typedef $$BusinessSettingsTableTableUpdateCompanionBuilder =
    BusinessSettingsTableCompanion Function({
      Value<int> id,
      Value<String> businessId,
      Value<String> businessName,
      Value<String> businessType,
      Value<String> phone,
      Value<String> address,
      Value<String> tinNumber,
      Value<int> vatRegistered,
      Value<double> vatRate,
      Value<String> currency,
      Value<String> invoicePrefix,
      Value<int> nextInvoiceNumber,
      Value<String> logoUrl,
      Value<String> plan,
      Value<int?> planExpiresAt,
      Value<int> updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
    });

class $$BusinessSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $BusinessSettingsTableTable> {
  $$BusinessSettingsTableTableFilterComposer({
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

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tinNumber => $composableBuilder(
    column: $table.tinNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vatRegistered => $composableBuilder(
    column: $table.vatRegistered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatRate => $composableBuilder(
    column: $table.vatRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoicePrefix => $composableBuilder(
    column: $table.invoicePrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextInvoiceNumber => $composableBuilder(
    column: $table.nextInvoiceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planExpiresAt => $composableBuilder(
    column: $table.planExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BusinessSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BusinessSettingsTableTable> {
  $$BusinessSettingsTableTableOrderingComposer({
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

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tinNumber => $composableBuilder(
    column: $table.tinNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vatRegistered => $composableBuilder(
    column: $table.vatRegistered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatRate => $composableBuilder(
    column: $table.vatRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoicePrefix => $composableBuilder(
    column: $table.invoicePrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextInvoiceNumber => $composableBuilder(
    column: $table.nextInvoiceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planExpiresAt => $composableBuilder(
    column: $table.planExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BusinessSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BusinessSettingsTableTable> {
  $$BusinessSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get tinNumber =>
      $composableBuilder(column: $table.tinNumber, builder: (column) => column);

  GeneratedColumn<int> get vatRegistered => $composableBuilder(
    column: $table.vatRegistered,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vatRate =>
      $composableBuilder(column: $table.vatRate, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get invoicePrefix => $composableBuilder(
    column: $table.invoicePrefix,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextInvoiceNumber => $composableBuilder(
    column: $table.nextInvoiceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<String> get plan =>
      $composableBuilder(column: $table.plan, builder: (column) => column);

  GeneratedColumn<int> get planExpiresAt => $composableBuilder(
    column: $table.planExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$BusinessSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BusinessSettingsTableTable,
          BusinessSettingsTableData,
          $$BusinessSettingsTableTableFilterComposer,
          $$BusinessSettingsTableTableOrderingComposer,
          $$BusinessSettingsTableTableAnnotationComposer,
          $$BusinessSettingsTableTableCreateCompanionBuilder,
          $$BusinessSettingsTableTableUpdateCompanionBuilder,
          (
            BusinessSettingsTableData,
            BaseReferences<
              _$AppDatabase,
              $BusinessSettingsTableTable,
              BusinessSettingsTableData
            >,
          ),
          BusinessSettingsTableData,
          PrefetchHooks Function()
        > {
  $$BusinessSettingsTableTableTableManager(
    _$AppDatabase db,
    $BusinessSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BusinessSettingsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$BusinessSettingsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BusinessSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> businessName = const Value.absent(),
                Value<String> businessType = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> tinNumber = const Value.absent(),
                Value<int> vatRegistered = const Value.absent(),
                Value<double> vatRate = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> invoicePrefix = const Value.absent(),
                Value<int> nextInvoiceNumber = const Value.absent(),
                Value<String> logoUrl = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<int?> planExpiresAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
              }) => BusinessSettingsTableCompanion(
                id: id,
                businessId: businessId,
                businessName: businessName,
                businessType: businessType,
                phone: phone,
                address: address,
                tinNumber: tinNumber,
                vatRegistered: vatRegistered,
                vatRate: vatRate,
                currency: currency,
                invoicePrefix: invoicePrefix,
                nextInvoiceNumber: nextInvoiceNumber,
                logoUrl: logoUrl,
                plan: plan,
                planExpiresAt: planExpiresAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String businessId,
                required String businessName,
                Value<String> businessType = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> tinNumber = const Value.absent(),
                Value<int> vatRegistered = const Value.absent(),
                Value<double> vatRate = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> invoicePrefix = const Value.absent(),
                Value<int> nextInvoiceNumber = const Value.absent(),
                Value<String> logoUrl = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<int?> planExpiresAt = const Value.absent(),
                required int updatedAt,
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
              }) => BusinessSettingsTableCompanion.insert(
                id: id,
                businessId: businessId,
                businessName: businessName,
                businessType: businessType,
                phone: phone,
                address: address,
                tinNumber: tinNumber,
                vatRegistered: vatRegistered,
                vatRate: vatRate,
                currency: currency,
                invoicePrefix: invoicePrefix,
                nextInvoiceNumber: nextInvoiceNumber,
                logoUrl: logoUrl,
                plan: plan,
                planExpiresAt: planExpiresAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BusinessSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BusinessSettingsTableTable,
      BusinessSettingsTableData,
      $$BusinessSettingsTableTableFilterComposer,
      $$BusinessSettingsTableTableOrderingComposer,
      $$BusinessSettingsTableTableAnnotationComposer,
      $$BusinessSettingsTableTableCreateCompanionBuilder,
      $$BusinessSettingsTableTableUpdateCompanionBuilder,
      (
        BusinessSettingsTableData,
        BaseReferences<
          _$AppDatabase,
          $BusinessSettingsTableTable,
          BusinessSettingsTableData
        >,
      ),
      BusinessSettingsTableData,
      PrefetchHooks Function()
    >;
typedef $$DebtsTableTableCreateCompanionBuilder =
    DebtsTableCompanion Function({
      required String id,
      required String businessId,
      required String partyName,
      Value<String> partyPhone,
      Value<String> partyId,
      required String type,
      required double originalAmount,
      Value<double> paidAmount,
      required String dueDate,
      Value<String> status,
      Value<String> invoiceRef,
      Value<String> note,
      Value<String> createdBy,
      Value<String> debtCreatedAt,
      Value<int> isWrittenOff,
      Value<String> writeOffReason,
      Value<String> writtenOffBy,
      Value<String> writtenOffAt,
      Value<double> interestRatePercent,
      Value<String> interestPeriod,
      Value<String> interestType,
      Value<String> loanDate,
      required int createdAt,
      required int updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> localVersion,
      Value<int> isDeleted,
      Value<int> rowid,
    });
typedef $$DebtsTableTableUpdateCompanionBuilder =
    DebtsTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> partyName,
      Value<String> partyPhone,
      Value<String> partyId,
      Value<String> type,
      Value<double> originalAmount,
      Value<double> paidAmount,
      Value<String> dueDate,
      Value<String> status,
      Value<String> invoiceRef,
      Value<String> note,
      Value<String> createdBy,
      Value<String> debtCreatedAt,
      Value<int> isWrittenOff,
      Value<String> writeOffReason,
      Value<String> writtenOffBy,
      Value<String> writtenOffAt,
      Value<double> interestRatePercent,
      Value<String> interestPeriod,
      Value<String> interestType,
      Value<String> loanDate,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> localVersion,
      Value<int> isDeleted,
      Value<int> rowid,
    });

class $$DebtsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DebtsTableTable> {
  $$DebtsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partyPhone => $composableBuilder(
    column: $table.partyPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partyId => $composableBuilder(
    column: $table.partyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get originalAmount => $composableBuilder(
    column: $table.originalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceRef => $composableBuilder(
    column: $table.invoiceRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get debtCreatedAt => $composableBuilder(
    column: $table.debtCreatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isWrittenOff => $composableBuilder(
    column: $table.isWrittenOff,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get writeOffReason => $composableBuilder(
    column: $table.writeOffReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get writtenOffBy => $composableBuilder(
    column: $table.writtenOffBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get writtenOffAt => $composableBuilder(
    column: $table.writtenOffAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get interestRatePercent => $composableBuilder(
    column: $table.interestRatePercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get interestPeriod => $composableBuilder(
    column: $table.interestPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get interestType => $composableBuilder(
    column: $table.interestType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loanDate => $composableBuilder(
    column: $table.loanDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DebtsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DebtsTableTable> {
  $$DebtsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partyPhone => $composableBuilder(
    column: $table.partyPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partyId => $composableBuilder(
    column: $table.partyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get originalAmount => $composableBuilder(
    column: $table.originalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceRef => $composableBuilder(
    column: $table.invoiceRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get debtCreatedAt => $composableBuilder(
    column: $table.debtCreatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isWrittenOff => $composableBuilder(
    column: $table.isWrittenOff,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get writeOffReason => $composableBuilder(
    column: $table.writeOffReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get writtenOffBy => $composableBuilder(
    column: $table.writtenOffBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get writtenOffAt => $composableBuilder(
    column: $table.writtenOffAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get interestRatePercent => $composableBuilder(
    column: $table.interestRatePercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get interestPeriod => $composableBuilder(
    column: $table.interestPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get interestType => $composableBuilder(
    column: $table.interestType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loanDate => $composableBuilder(
    column: $table.loanDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DebtsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DebtsTableTable> {
  $$DebtsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partyName =>
      $composableBuilder(column: $table.partyName, builder: (column) => column);

  GeneratedColumn<String> get partyPhone => $composableBuilder(
    column: $table.partyPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partyId =>
      $composableBuilder(column: $table.partyId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get originalAmount => $composableBuilder(
    column: $table.originalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get invoiceRef => $composableBuilder(
    column: $table.invoiceRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get debtCreatedAt => $composableBuilder(
    column: $table.debtCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isWrittenOff => $composableBuilder(
    column: $table.isWrittenOff,
    builder: (column) => column,
  );

  GeneratedColumn<String> get writeOffReason => $composableBuilder(
    column: $table.writeOffReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get writtenOffBy => $composableBuilder(
    column: $table.writtenOffBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get writtenOffAt => $composableBuilder(
    column: $table.writtenOffAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get interestRatePercent => $composableBuilder(
    column: $table.interestRatePercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get interestPeriod => $composableBuilder(
    column: $table.interestPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get interestType => $composableBuilder(
    column: $table.interestType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get loanDate =>
      $composableBuilder(column: $table.loanDate, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$DebtsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DebtsTableTable,
          DebtsTableData,
          $$DebtsTableTableFilterComposer,
          $$DebtsTableTableOrderingComposer,
          $$DebtsTableTableAnnotationComposer,
          $$DebtsTableTableCreateCompanionBuilder,
          $$DebtsTableTableUpdateCompanionBuilder,
          (
            DebtsTableData,
            BaseReferences<_$AppDatabase, $DebtsTableTable, DebtsTableData>,
          ),
          DebtsTableData,
          PrefetchHooks Function()
        > {
  $$DebtsTableTableTableManager(_$AppDatabase db, $DebtsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> partyName = const Value.absent(),
                Value<String> partyPhone = const Value.absent(),
                Value<String> partyId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> originalAmount = const Value.absent(),
                Value<double> paidAmount = const Value.absent(),
                Value<String> dueDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> invoiceRef = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> debtCreatedAt = const Value.absent(),
                Value<int> isWrittenOff = const Value.absent(),
                Value<String> writeOffReason = const Value.absent(),
                Value<String> writtenOffBy = const Value.absent(),
                Value<String> writtenOffAt = const Value.absent(),
                Value<double> interestRatePercent = const Value.absent(),
                Value<String> interestPeriod = const Value.absent(),
                Value<String> interestType = const Value.absent(),
                Value<String> loanDate = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> localVersion = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtsTableCompanion(
                id: id,
                businessId: businessId,
                partyName: partyName,
                partyPhone: partyPhone,
                partyId: partyId,
                type: type,
                originalAmount: originalAmount,
                paidAmount: paidAmount,
                dueDate: dueDate,
                status: status,
                invoiceRef: invoiceRef,
                note: note,
                createdBy: createdBy,
                debtCreatedAt: debtCreatedAt,
                isWrittenOff: isWrittenOff,
                writeOffReason: writeOffReason,
                writtenOffBy: writtenOffBy,
                writtenOffAt: writtenOffAt,
                interestRatePercent: interestRatePercent,
                interestPeriod: interestPeriod,
                interestType: interestType,
                loanDate: loanDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                localVersion: localVersion,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String partyName,
                Value<String> partyPhone = const Value.absent(),
                Value<String> partyId = const Value.absent(),
                required String type,
                required double originalAmount,
                Value<double> paidAmount = const Value.absent(),
                required String dueDate,
                Value<String> status = const Value.absent(),
                Value<String> invoiceRef = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> debtCreatedAt = const Value.absent(),
                Value<int> isWrittenOff = const Value.absent(),
                Value<String> writeOffReason = const Value.absent(),
                Value<String> writtenOffBy = const Value.absent(),
                Value<String> writtenOffAt = const Value.absent(),
                Value<double> interestRatePercent = const Value.absent(),
                Value<String> interestPeriod = const Value.absent(),
                Value<String> interestType = const Value.absent(),
                Value<String> loanDate = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> localVersion = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtsTableCompanion.insert(
                id: id,
                businessId: businessId,
                partyName: partyName,
                partyPhone: partyPhone,
                partyId: partyId,
                type: type,
                originalAmount: originalAmount,
                paidAmount: paidAmount,
                dueDate: dueDate,
                status: status,
                invoiceRef: invoiceRef,
                note: note,
                createdBy: createdBy,
                debtCreatedAt: debtCreatedAt,
                isWrittenOff: isWrittenOff,
                writeOffReason: writeOffReason,
                writtenOffBy: writtenOffBy,
                writtenOffAt: writtenOffAt,
                interestRatePercent: interestRatePercent,
                interestPeriod: interestPeriod,
                interestType: interestType,
                loanDate: loanDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                localVersion: localVersion,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DebtsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DebtsTableTable,
      DebtsTableData,
      $$DebtsTableTableFilterComposer,
      $$DebtsTableTableOrderingComposer,
      $$DebtsTableTableAnnotationComposer,
      $$DebtsTableTableCreateCompanionBuilder,
      $$DebtsTableTableUpdateCompanionBuilder,
      (
        DebtsTableData,
        BaseReferences<_$AppDatabase, $DebtsTableTable, DebtsTableData>,
      ),
      DebtsTableData,
      PrefetchHooks Function()
    >;
typedef $$DebtPaymentsTableTableCreateCompanionBuilder =
    DebtPaymentsTableCompanion Function({
      required String id,
      required String debtId,
      required String businessId,
      required double amount,
      required String date,
      Value<String> method,
      Value<String> note,
      Value<String> recordedBy,
      Value<String> accountId,
      required int createdAt,
      required int updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> isDeleted,
      Value<int> rowid,
    });
typedef $$DebtPaymentsTableTableUpdateCompanionBuilder =
    DebtPaymentsTableCompanion Function({
      Value<String> id,
      Value<String> debtId,
      Value<String> businessId,
      Value<double> amount,
      Value<String> date,
      Value<String> method,
      Value<String> note,
      Value<String> recordedBy,
      Value<String> accountId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> isDeleted,
      Value<int> rowid,
    });

class $$DebtPaymentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DebtPaymentsTableTable> {
  $$DebtPaymentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get debtId => $composableBuilder(
    column: $table.debtId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedBy => $composableBuilder(
    column: $table.recordedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DebtPaymentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DebtPaymentsTableTable> {
  $$DebtPaymentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get debtId => $composableBuilder(
    column: $table.debtId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedBy => $composableBuilder(
    column: $table.recordedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DebtPaymentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DebtPaymentsTableTable> {
  $$DebtPaymentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get debtId =>
      $composableBuilder(column: $table.debtId, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get recordedBy => $composableBuilder(
    column: $table.recordedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$DebtPaymentsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DebtPaymentsTableTable,
          DebtPaymentsTableData,
          $$DebtPaymentsTableTableFilterComposer,
          $$DebtPaymentsTableTableOrderingComposer,
          $$DebtPaymentsTableTableAnnotationComposer,
          $$DebtPaymentsTableTableCreateCompanionBuilder,
          $$DebtPaymentsTableTableUpdateCompanionBuilder,
          (
            DebtPaymentsTableData,
            BaseReferences<
              _$AppDatabase,
              $DebtPaymentsTableTable,
              DebtPaymentsTableData
            >,
          ),
          DebtPaymentsTableData,
          PrefetchHooks Function()
        > {
  $$DebtPaymentsTableTableTableManager(
    _$AppDatabase db,
    $DebtPaymentsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtPaymentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtPaymentsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtPaymentsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> debtId = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> recordedBy = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtPaymentsTableCompanion(
                id: id,
                debtId: debtId,
                businessId: businessId,
                amount: amount,
                date: date,
                method: method,
                note: note,
                recordedBy: recordedBy,
                accountId: accountId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String debtId,
                required String businessId,
                required double amount,
                required String date,
                Value<String> method = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> recordedBy = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtPaymentsTableCompanion.insert(
                id: id,
                debtId: debtId,
                businessId: businessId,
                amount: amount,
                date: date,
                method: method,
                note: note,
                recordedBy: recordedBy,
                accountId: accountId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DebtPaymentsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DebtPaymentsTableTable,
      DebtPaymentsTableData,
      $$DebtPaymentsTableTableFilterComposer,
      $$DebtPaymentsTableTableOrderingComposer,
      $$DebtPaymentsTableTableAnnotationComposer,
      $$DebtPaymentsTableTableCreateCompanionBuilder,
      $$DebtPaymentsTableTableUpdateCompanionBuilder,
      (
        DebtPaymentsTableData,
        BaseReferences<
          _$AppDatabase,
          $DebtPaymentsTableTable,
          DebtPaymentsTableData
        >,
      ),
      DebtPaymentsTableData,
      PrefetchHooks Function()
    >;
typedef $$TeamMembersTableTableCreateCompanionBuilder =
    TeamMembersTableCompanion Function({
      required String id,
      required String businessId,
      required String name,
      Value<String> email,
      Value<String> phone,
      required String role,
      Value<String> customPermissions,
      Value<String> status,
      required int invitedAt,
      Value<int?> acceptedAt,
      Value<String> invitedBy,
      Value<String> notes,
      Value<String> userId,
      Value<String> dataScope,
      required int createdAt,
      required int updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> isDeleted,
      Value<int> rowid,
    });
typedef $$TeamMembersTableTableUpdateCompanionBuilder =
    TeamMembersTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<String> email,
      Value<String> phone,
      Value<String> role,
      Value<String> customPermissions,
      Value<String> status,
      Value<int> invitedAt,
      Value<int?> acceptedAt,
      Value<String> invitedBy,
      Value<String> notes,
      Value<String> userId,
      Value<String> dataScope,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> isDeleted,
      Value<int> rowid,
    });

class $$TeamMembersTableTableFilterComposer
    extends Composer<_$AppDatabase, $TeamMembersTableTable> {
  $$TeamMembersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customPermissions => $composableBuilder(
    column: $table.customPermissions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get invitedAt => $composableBuilder(
    column: $table.invitedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invitedBy => $composableBuilder(
    column: $table.invitedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataScope => $composableBuilder(
    column: $table.dataScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TeamMembersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamMembersTableTable> {
  $$TeamMembersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customPermissions => $composableBuilder(
    column: $table.customPermissions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get invitedAt => $composableBuilder(
    column: $table.invitedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invitedBy => $composableBuilder(
    column: $table.invitedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataScope => $composableBuilder(
    column: $table.dataScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TeamMembersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamMembersTableTable> {
  $$TeamMembersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get customPermissions => $composableBuilder(
    column: $table.customPermissions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get invitedAt =>
      $composableBuilder(column: $table.invitedAt, builder: (column) => column);

  GeneratedColumn<int> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invitedBy =>
      $composableBuilder(column: $table.invitedBy, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get dataScope =>
      $composableBuilder(column: $table.dataScope, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$TeamMembersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamMembersTableTable,
          TeamMembersTableData,
          $$TeamMembersTableTableFilterComposer,
          $$TeamMembersTableTableOrderingComposer,
          $$TeamMembersTableTableAnnotationComposer,
          $$TeamMembersTableTableCreateCompanionBuilder,
          $$TeamMembersTableTableUpdateCompanionBuilder,
          (
            TeamMembersTableData,
            BaseReferences<
              _$AppDatabase,
              $TeamMembersTableTable,
              TeamMembersTableData
            >,
          ),
          TeamMembersTableData,
          PrefetchHooks Function()
        > {
  $$TeamMembersTableTableTableManager(
    _$AppDatabase db,
    $TeamMembersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamMembersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamMembersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamMembersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> customPermissions = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> invitedAt = const Value.absent(),
                Value<int?> acceptedAt = const Value.absent(),
                Value<String> invitedBy = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> dataScope = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamMembersTableCompanion(
                id: id,
                businessId: businessId,
                name: name,
                email: email,
                phone: phone,
                role: role,
                customPermissions: customPermissions,
                status: status,
                invitedAt: invitedAt,
                acceptedAt: acceptedAt,
                invitedBy: invitedBy,
                notes: notes,
                userId: userId,
                dataScope: dataScope,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String name,
                Value<String> email = const Value.absent(),
                Value<String> phone = const Value.absent(),
                required String role,
                Value<String> customPermissions = const Value.absent(),
                Value<String> status = const Value.absent(),
                required int invitedAt,
                Value<int?> acceptedAt = const Value.absent(),
                Value<String> invitedBy = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> dataScope = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamMembersTableCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                email: email,
                phone: phone,
                role: role,
                customPermissions: customPermissions,
                status: status,
                invitedAt: invitedAt,
                acceptedAt: acceptedAt,
                invitedBy: invitedBy,
                notes: notes,
                userId: userId,
                dataScope: dataScope,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TeamMembersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamMembersTableTable,
      TeamMembersTableData,
      $$TeamMembersTableTableFilterComposer,
      $$TeamMembersTableTableOrderingComposer,
      $$TeamMembersTableTableAnnotationComposer,
      $$TeamMembersTableTableCreateCompanionBuilder,
      $$TeamMembersTableTableUpdateCompanionBuilder,
      (
        TeamMembersTableData,
        BaseReferences<
          _$AppDatabase,
          $TeamMembersTableTable,
          TeamMembersTableData
        >,
      ),
      TeamMembersTableData,
      PrefetchHooks Function()
    >;
typedef $$CashAccountsTableTableCreateCompanionBuilder =
    CashAccountsTableCompanion Function({
      required String id,
      required String businessId,
      required String name,
      required String type,
      Value<double> balance,
      Value<String> accountNumber,
      Value<String> currency,
      Value<String> lastReconciled,
      required int createdAt,
      required int updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> localVersion,
      Value<int> isDeleted,
      Value<int> rowid,
    });
typedef $$CashAccountsTableTableUpdateCompanionBuilder =
    CashAccountsTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<String> type,
      Value<double> balance,
      Value<String> accountNumber,
      Value<String> currency,
      Value<String> lastReconciled,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> localVersion,
      Value<int> isDeleted,
      Value<int> rowid,
    });

class $$CashAccountsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CashAccountsTableTable> {
  $$CashAccountsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastReconciled => $composableBuilder(
    column: $table.lastReconciled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CashAccountsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CashAccountsTableTable> {
  $$CashAccountsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastReconciled => $composableBuilder(
    column: $table.lastReconciled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CashAccountsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashAccountsTableTable> {
  $$CashAccountsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get lastReconciled => $composableBuilder(
    column: $table.lastReconciled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$CashAccountsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CashAccountsTableTable,
          CashAccountsTableData,
          $$CashAccountsTableTableFilterComposer,
          $$CashAccountsTableTableOrderingComposer,
          $$CashAccountsTableTableAnnotationComposer,
          $$CashAccountsTableTableCreateCompanionBuilder,
          $$CashAccountsTableTableUpdateCompanionBuilder,
          (
            CashAccountsTableData,
            BaseReferences<
              _$AppDatabase,
              $CashAccountsTableTable,
              CashAccountsTableData
            >,
          ),
          CashAccountsTableData,
          PrefetchHooks Function()
        > {
  $$CashAccountsTableTableTableManager(
    _$AppDatabase db,
    $CashAccountsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashAccountsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashAccountsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashAccountsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<String> accountNumber = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> lastReconciled = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> localVersion = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashAccountsTableCompanion(
                id: id,
                businessId: businessId,
                name: name,
                type: type,
                balance: balance,
                accountNumber: accountNumber,
                currency: currency,
                lastReconciled: lastReconciled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                localVersion: localVersion,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String name,
                required String type,
                Value<double> balance = const Value.absent(),
                Value<String> accountNumber = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> lastReconciled = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> localVersion = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashAccountsTableCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                type: type,
                balance: balance,
                accountNumber: accountNumber,
                currency: currency,
                lastReconciled: lastReconciled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                localVersion: localVersion,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CashAccountsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CashAccountsTableTable,
      CashAccountsTableData,
      $$CashAccountsTableTableFilterComposer,
      $$CashAccountsTableTableOrderingComposer,
      $$CashAccountsTableTableAnnotationComposer,
      $$CashAccountsTableTableCreateCompanionBuilder,
      $$CashAccountsTableTableUpdateCompanionBuilder,
      (
        CashAccountsTableData,
        BaseReferences<
          _$AppDatabase,
          $CashAccountsTableTable,
          CashAccountsTableData
        >,
      ),
      CashAccountsTableData,
      PrefetchHooks Function()
    >;
typedef $$CashTransactionsTableTableCreateCompanionBuilder =
    CashTransactionsTableCompanion Function({
      required String id,
      required String businessId,
      required String type,
      required double amount,
      Value<String> fromAccountId,
      Value<String> toAccountId,
      Value<String> description,
      required String date,
      Value<String> reference,
      Value<String> activityCategory,
      Value<String> createdBy,
      required int createdAt,
      required int updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> isDeleted,
      Value<int> rowid,
    });
typedef $$CashTransactionsTableTableUpdateCompanionBuilder =
    CashTransactionsTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> type,
      Value<double> amount,
      Value<String> fromAccountId,
      Value<String> toAccountId,
      Value<String> description,
      Value<String> date,
      Value<String> reference,
      Value<String> activityCategory,
      Value<String> createdBy,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> isDeleted,
      Value<int> rowid,
    });

class $$CashTransactionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CashTransactionsTableTable> {
  $$CashTransactionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromAccountId => $composableBuilder(
    column: $table.fromAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityCategory => $composableBuilder(
    column: $table.activityCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CashTransactionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CashTransactionsTableTable> {
  $$CashTransactionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromAccountId => $composableBuilder(
    column: $table.fromAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityCategory => $composableBuilder(
    column: $table.activityCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CashTransactionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashTransactionsTableTable> {
  $$CashTransactionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get fromAccountId => $composableBuilder(
    column: $table.fromAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get activityCategory => $composableBuilder(
    column: $table.activityCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$CashTransactionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CashTransactionsTableTable,
          CashTransactionsTableData,
          $$CashTransactionsTableTableFilterComposer,
          $$CashTransactionsTableTableOrderingComposer,
          $$CashTransactionsTableTableAnnotationComposer,
          $$CashTransactionsTableTableCreateCompanionBuilder,
          $$CashTransactionsTableTableUpdateCompanionBuilder,
          (
            CashTransactionsTableData,
            BaseReferences<
              _$AppDatabase,
              $CashTransactionsTableTable,
              CashTransactionsTableData
            >,
          ),
          CashTransactionsTableData,
          PrefetchHooks Function()
        > {
  $$CashTransactionsTableTableTableManager(
    _$AppDatabase db,
    $CashTransactionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashTransactionsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CashTransactionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CashTransactionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> fromAccountId = const Value.absent(),
                Value<String> toAccountId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String> activityCategory = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashTransactionsTableCompanion(
                id: id,
                businessId: businessId,
                type: type,
                amount: amount,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                description: description,
                date: date,
                reference: reference,
                activityCategory: activityCategory,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String type,
                required double amount,
                Value<String> fromAccountId = const Value.absent(),
                Value<String> toAccountId = const Value.absent(),
                Value<String> description = const Value.absent(),
                required String date,
                Value<String> reference = const Value.absent(),
                Value<String> activityCategory = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashTransactionsTableCompanion.insert(
                id: id,
                businessId: businessId,
                type: type,
                amount: amount,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                description: description,
                date: date,
                reference: reference,
                activityCategory: activityCategory,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CashTransactionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CashTransactionsTableTable,
      CashTransactionsTableData,
      $$CashTransactionsTableTableFilterComposer,
      $$CashTransactionsTableTableOrderingComposer,
      $$CashTransactionsTableTableAnnotationComposer,
      $$CashTransactionsTableTableCreateCompanionBuilder,
      $$CashTransactionsTableTableUpdateCompanionBuilder,
      (
        CashTransactionsTableData,
        BaseReferences<
          _$AppDatabase,
          $CashTransactionsTableTable,
          CashTransactionsTableData
        >,
      ),
      CashTransactionsTableData,
      PrefetchHooks Function()
    >;
typedef $$DailyReconciliationsTableTableCreateCompanionBuilder =
    DailyReconciliationsTableCompanion Function({
      required String id,
      required String businessId,
      required String accountId,
      required String date,
      Value<double> openingBalance,
      Value<double> closingBalance,
      Value<double> totalDeposits,
      Value<double> totalWithdrawals,
      Value<String> notes,
      Value<String> reconciledBy,
      Value<int> isReconciled,
      required int createdAt,
      required int updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> isDeleted,
      Value<int> rowid,
    });
typedef $$DailyReconciliationsTableTableUpdateCompanionBuilder =
    DailyReconciliationsTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> accountId,
      Value<String> date,
      Value<double> openingBalance,
      Value<double> closingBalance,
      Value<double> totalDeposits,
      Value<double> totalWithdrawals,
      Value<String> notes,
      Value<String> reconciledBy,
      Value<int> isReconciled,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> serverUpdatedAt,
      Value<String> syncStatus,
      Value<int> isDeleted,
      Value<int> rowid,
    });

class $$DailyReconciliationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DailyReconciliationsTableTable> {
  $$DailyReconciliationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get closingBalance => $composableBuilder(
    column: $table.closingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDeposits => $composableBuilder(
    column: $table.totalDeposits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalWithdrawals => $composableBuilder(
    column: $table.totalWithdrawals,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reconciledBy => $composableBuilder(
    column: $table.reconciledBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isReconciled => $composableBuilder(
    column: $table.isReconciled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyReconciliationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyReconciliationsTableTable> {
  $$DailyReconciliationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get closingBalance => $composableBuilder(
    column: $table.closingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDeposits => $composableBuilder(
    column: $table.totalDeposits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalWithdrawals => $composableBuilder(
    column: $table.totalWithdrawals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reconciledBy => $composableBuilder(
    column: $table.reconciledBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isReconciled => $composableBuilder(
    column: $table.isReconciled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyReconciliationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyReconciliationsTableTable> {
  $$DailyReconciliationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get closingBalance => $composableBuilder(
    column: $table.closingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalDeposits => $composableBuilder(
    column: $table.totalDeposits,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalWithdrawals => $composableBuilder(
    column: $table.totalWithdrawals,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get reconciledBy => $composableBuilder(
    column: $table.reconciledBy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isReconciled => $composableBuilder(
    column: $table.isReconciled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$DailyReconciliationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyReconciliationsTableTable,
          DailyReconciliationsTableData,
          $$DailyReconciliationsTableTableFilterComposer,
          $$DailyReconciliationsTableTableOrderingComposer,
          $$DailyReconciliationsTableTableAnnotationComposer,
          $$DailyReconciliationsTableTableCreateCompanionBuilder,
          $$DailyReconciliationsTableTableUpdateCompanionBuilder,
          (
            DailyReconciliationsTableData,
            BaseReferences<
              _$AppDatabase,
              $DailyReconciliationsTableTable,
              DailyReconciliationsTableData
            >,
          ),
          DailyReconciliationsTableData,
          PrefetchHooks Function()
        > {
  $$DailyReconciliationsTableTableTableManager(
    _$AppDatabase db,
    $DailyReconciliationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyReconciliationsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DailyReconciliationsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DailyReconciliationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> openingBalance = const Value.absent(),
                Value<double> closingBalance = const Value.absent(),
                Value<double> totalDeposits = const Value.absent(),
                Value<double> totalWithdrawals = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> reconciledBy = const Value.absent(),
                Value<int> isReconciled = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyReconciliationsTableCompanion(
                id: id,
                businessId: businessId,
                accountId: accountId,
                date: date,
                openingBalance: openingBalance,
                closingBalance: closingBalance,
                totalDeposits: totalDeposits,
                totalWithdrawals: totalWithdrawals,
                notes: notes,
                reconciledBy: reconciledBy,
                isReconciled: isReconciled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String accountId,
                required String date,
                Value<double> openingBalance = const Value.absent(),
                Value<double> closingBalance = const Value.absent(),
                Value<double> totalDeposits = const Value.absent(),
                Value<double> totalWithdrawals = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> reconciledBy = const Value.absent(),
                Value<int> isReconciled = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> serverUpdatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyReconciliationsTableCompanion.insert(
                id: id,
                businessId: businessId,
                accountId: accountId,
                date: date,
                openingBalance: openingBalance,
                closingBalance: closingBalance,
                totalDeposits: totalDeposits,
                totalWithdrawals: totalWithdrawals,
                notes: notes,
                reconciledBy: reconciledBy,
                isReconciled: isReconciled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                syncStatus: syncStatus,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyReconciliationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyReconciliationsTableTable,
      DailyReconciliationsTableData,
      $$DailyReconciliationsTableTableFilterComposer,
      $$DailyReconciliationsTableTableOrderingComposer,
      $$DailyReconciliationsTableTableAnnotationComposer,
      $$DailyReconciliationsTableTableCreateCompanionBuilder,
      $$DailyReconciliationsTableTableUpdateCompanionBuilder,
      (
        DailyReconciliationsTableData,
        BaseReferences<
          _$AppDatabase,
          $DailyReconciliationsTableTable,
          DailyReconciliationsTableData
        >,
      ),
      DailyReconciliationsTableData,
      PrefetchHooks Function()
    >;
typedef $$MasterCategoriesTableTableCreateCompanionBuilder =
    MasterCategoriesTableCompanion Function({
      required String id,
      required String businessType,
      required String categoryName,
      Value<String> categoryNameSw,
      Value<String> categorySlug,
      Value<String> icon,
      Value<int> displayOrder,
      Value<int> cachedAt,
      Value<int> rowid,
    });
typedef $$MasterCategoriesTableTableUpdateCompanionBuilder =
    MasterCategoriesTableCompanion Function({
      Value<String> id,
      Value<String> businessType,
      Value<String> categoryName,
      Value<String> categoryNameSw,
      Value<String> categorySlug,
      Value<String> icon,
      Value<int> displayOrder,
      Value<int> cachedAt,
      Value<int> rowid,
    });

class $$MasterCategoriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $MasterCategoriesTableTable> {
  $$MasterCategoriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryNameSw => $composableBuilder(
    column: $table.categoryNameSw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categorySlug => $composableBuilder(
    column: $table.categorySlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MasterCategoriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MasterCategoriesTableTable> {
  $$MasterCategoriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryNameSw => $composableBuilder(
    column: $table.categoryNameSw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categorySlug => $composableBuilder(
    column: $table.categorySlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MasterCategoriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MasterCategoriesTableTable> {
  $$MasterCategoriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryNameSw => $composableBuilder(
    column: $table.categoryNameSw,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categorySlug => $composableBuilder(
    column: $table.categorySlug,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$MasterCategoriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MasterCategoriesTableTable,
          MasterCategoriesTableData,
          $$MasterCategoriesTableTableFilterComposer,
          $$MasterCategoriesTableTableOrderingComposer,
          $$MasterCategoriesTableTableAnnotationComposer,
          $$MasterCategoriesTableTableCreateCompanionBuilder,
          $$MasterCategoriesTableTableUpdateCompanionBuilder,
          (
            MasterCategoriesTableData,
            BaseReferences<
              _$AppDatabase,
              $MasterCategoriesTableTable,
              MasterCategoriesTableData
            >,
          ),
          MasterCategoriesTableData,
          PrefetchHooks Function()
        > {
  $$MasterCategoriesTableTableTableManager(
    _$AppDatabase db,
    $MasterCategoriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MasterCategoriesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MasterCategoriesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MasterCategoriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessType = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<String> categoryNameSw = const Value.absent(),
                Value<String> categorySlug = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MasterCategoriesTableCompanion(
                id: id,
                businessType: businessType,
                categoryName: categoryName,
                categoryNameSw: categoryNameSw,
                categorySlug: categorySlug,
                icon: icon,
                displayOrder: displayOrder,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessType,
                required String categoryName,
                Value<String> categoryNameSw = const Value.absent(),
                Value<String> categorySlug = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MasterCategoriesTableCompanion.insert(
                id: id,
                businessType: businessType,
                categoryName: categoryName,
                categoryNameSw: categoryNameSw,
                categorySlug: categorySlug,
                icon: icon,
                displayOrder: displayOrder,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MasterCategoriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MasterCategoriesTableTable,
      MasterCategoriesTableData,
      $$MasterCategoriesTableTableFilterComposer,
      $$MasterCategoriesTableTableOrderingComposer,
      $$MasterCategoriesTableTableAnnotationComposer,
      $$MasterCategoriesTableTableCreateCompanionBuilder,
      $$MasterCategoriesTableTableUpdateCompanionBuilder,
      (
        MasterCategoriesTableData,
        BaseReferences<
          _$AppDatabase,
          $MasterCategoriesTableTable,
          MasterCategoriesTableData
        >,
      ),
      MasterCategoriesTableData,
      PrefetchHooks Function()
    >;
typedef $$MasterProductsTableTableCreateCompanionBuilder =
    MasterProductsTableCompanion Function({
      required String id,
      required String businessType,
      Value<String> categorySlug,
      required String productName,
      Value<String> productNameSw,
      Value<String> productSlug,
      Value<String> genericName,
      Value<String> brandNames,
      Value<String> unit,
      Value<String> unitAlternatives,
      Value<String> commonBarcodes,
      Value<String> searchKeywords,
      Value<String> tags,
      Value<int> prescriptionRequired,
      Value<int> coldStorage,
      Value<int> cachedAt,
      Value<int> rowid,
    });
typedef $$MasterProductsTableTableUpdateCompanionBuilder =
    MasterProductsTableCompanion Function({
      Value<String> id,
      Value<String> businessType,
      Value<String> categorySlug,
      Value<String> productName,
      Value<String> productNameSw,
      Value<String> productSlug,
      Value<String> genericName,
      Value<String> brandNames,
      Value<String> unit,
      Value<String> unitAlternatives,
      Value<String> commonBarcodes,
      Value<String> searchKeywords,
      Value<String> tags,
      Value<int> prescriptionRequired,
      Value<int> coldStorage,
      Value<int> cachedAt,
      Value<int> rowid,
    });

class $$MasterProductsTableTableFilterComposer
    extends Composer<_$AppDatabase, $MasterProductsTableTable> {
  $$MasterProductsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categorySlug => $composableBuilder(
    column: $table.categorySlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productNameSw => $composableBuilder(
    column: $table.productNameSw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productSlug => $composableBuilder(
    column: $table.productSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genericName => $composableBuilder(
    column: $table.genericName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brandNames => $composableBuilder(
    column: $table.brandNames,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitAlternatives => $composableBuilder(
    column: $table.unitAlternatives,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commonBarcodes => $composableBuilder(
    column: $table.commonBarcodes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchKeywords => $composableBuilder(
    column: $table.searchKeywords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prescriptionRequired => $composableBuilder(
    column: $table.prescriptionRequired,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coldStorage => $composableBuilder(
    column: $table.coldStorage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MasterProductsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MasterProductsTableTable> {
  $$MasterProductsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categorySlug => $composableBuilder(
    column: $table.categorySlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productNameSw => $composableBuilder(
    column: $table.productNameSw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productSlug => $composableBuilder(
    column: $table.productSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genericName => $composableBuilder(
    column: $table.genericName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brandNames => $composableBuilder(
    column: $table.brandNames,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitAlternatives => $composableBuilder(
    column: $table.unitAlternatives,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commonBarcodes => $composableBuilder(
    column: $table.commonBarcodes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchKeywords => $composableBuilder(
    column: $table.searchKeywords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prescriptionRequired => $composableBuilder(
    column: $table.prescriptionRequired,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coldStorage => $composableBuilder(
    column: $table.coldStorage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MasterProductsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MasterProductsTableTable> {
  $$MasterProductsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categorySlug => $composableBuilder(
    column: $table.categorySlug,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productNameSw => $composableBuilder(
    column: $table.productNameSw,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productSlug => $composableBuilder(
    column: $table.productSlug,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genericName => $composableBuilder(
    column: $table.genericName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brandNames => $composableBuilder(
    column: $table.brandNames,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get unitAlternatives => $composableBuilder(
    column: $table.unitAlternatives,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commonBarcodes => $composableBuilder(
    column: $table.commonBarcodes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get searchKeywords => $composableBuilder(
    column: $table.searchKeywords,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get prescriptionRequired => $composableBuilder(
    column: $table.prescriptionRequired,
    builder: (column) => column,
  );

  GeneratedColumn<int> get coldStorage => $composableBuilder(
    column: $table.coldStorage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$MasterProductsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MasterProductsTableTable,
          MasterProductsTableData,
          $$MasterProductsTableTableFilterComposer,
          $$MasterProductsTableTableOrderingComposer,
          $$MasterProductsTableTableAnnotationComposer,
          $$MasterProductsTableTableCreateCompanionBuilder,
          $$MasterProductsTableTableUpdateCompanionBuilder,
          (
            MasterProductsTableData,
            BaseReferences<
              _$AppDatabase,
              $MasterProductsTableTable,
              MasterProductsTableData
            >,
          ),
          MasterProductsTableData,
          PrefetchHooks Function()
        > {
  $$MasterProductsTableTableTableManager(
    _$AppDatabase db,
    $MasterProductsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MasterProductsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MasterProductsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MasterProductsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessType = const Value.absent(),
                Value<String> categorySlug = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String> productNameSw = const Value.absent(),
                Value<String> productSlug = const Value.absent(),
                Value<String> genericName = const Value.absent(),
                Value<String> brandNames = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> unitAlternatives = const Value.absent(),
                Value<String> commonBarcodes = const Value.absent(),
                Value<String> searchKeywords = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<int> prescriptionRequired = const Value.absent(),
                Value<int> coldStorage = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MasterProductsTableCompanion(
                id: id,
                businessType: businessType,
                categorySlug: categorySlug,
                productName: productName,
                productNameSw: productNameSw,
                productSlug: productSlug,
                genericName: genericName,
                brandNames: brandNames,
                unit: unit,
                unitAlternatives: unitAlternatives,
                commonBarcodes: commonBarcodes,
                searchKeywords: searchKeywords,
                tags: tags,
                prescriptionRequired: prescriptionRequired,
                coldStorage: coldStorage,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessType,
                Value<String> categorySlug = const Value.absent(),
                required String productName,
                Value<String> productNameSw = const Value.absent(),
                Value<String> productSlug = const Value.absent(),
                Value<String> genericName = const Value.absent(),
                Value<String> brandNames = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> unitAlternatives = const Value.absent(),
                Value<String> commonBarcodes = const Value.absent(),
                Value<String> searchKeywords = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<int> prescriptionRequired = const Value.absent(),
                Value<int> coldStorage = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MasterProductsTableCompanion.insert(
                id: id,
                businessType: businessType,
                categorySlug: categorySlug,
                productName: productName,
                productNameSw: productNameSw,
                productSlug: productSlug,
                genericName: genericName,
                brandNames: brandNames,
                unit: unit,
                unitAlternatives: unitAlternatives,
                commonBarcodes: commonBarcodes,
                searchKeywords: searchKeywords,
                tags: tags,
                prescriptionRequired: prescriptionRequired,
                coldStorage: coldStorage,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MasterProductsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MasterProductsTableTable,
      MasterProductsTableData,
      $$MasterProductsTableTableFilterComposer,
      $$MasterProductsTableTableOrderingComposer,
      $$MasterProductsTableTableAnnotationComposer,
      $$MasterProductsTableTableCreateCompanionBuilder,
      $$MasterProductsTableTableUpdateCompanionBuilder,
      (
        MasterProductsTableData,
        BaseReferences<
          _$AppDatabase,
          $MasterProductsTableTable,
          MasterProductsTableData
        >,
      ),
      MasterProductsTableData,
      PrefetchHooks Function()
    >;
typedef $$NotificationLogTableTableCreateCompanionBuilder =
    NotificationLogTableCompanion Function({
      required String id,
      required String businessId,
      required String type,
      Value<String?> entityId,
      required String title,
      required String body,
      Value<int> isRead,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$NotificationLogTableTableUpdateCompanionBuilder =
    NotificationLogTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> type,
      Value<String?> entityId,
      Value<String> title,
      Value<String> body,
      Value<int> isRead,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$NotificationLogTableTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationLogTableTable> {
  $$NotificationLogTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
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

  ColumnFilters<int> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationLogTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationLogTableTable> {
  $$NotificationLogTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
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

  ColumnOrderings<int> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationLogTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationLogTableTable> {
  $$NotificationLogTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NotificationLogTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationLogTableTable,
          NotificationLogTableData,
          $$NotificationLogTableTableFilterComposer,
          $$NotificationLogTableTableOrderingComposer,
          $$NotificationLogTableTableAnnotationComposer,
          $$NotificationLogTableTableCreateCompanionBuilder,
          $$NotificationLogTableTableUpdateCompanionBuilder,
          (
            NotificationLogTableData,
            BaseReferences<
              _$AppDatabase,
              $NotificationLogTableTable,
              NotificationLogTableData
            >,
          ),
          NotificationLogTableData,
          PrefetchHooks Function()
        > {
  $$NotificationLogTableTableTableManager(
    _$AppDatabase db,
    $NotificationLogTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationLogTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationLogTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$NotificationLogTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> isRead = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationLogTableCompanion(
                id: id,
                businessId: businessId,
                type: type,
                entityId: entityId,
                title: title,
                body: body,
                isRead: isRead,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String type,
                Value<String?> entityId = const Value.absent(),
                required String title,
                required String body,
                Value<int> isRead = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => NotificationLogTableCompanion.insert(
                id: id,
                businessId: businessId,
                type: type,
                entityId: entityId,
                title: title,
                body: body,
                isRead: isRead,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationLogTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationLogTableTable,
      NotificationLogTableData,
      $$NotificationLogTableTableFilterComposer,
      $$NotificationLogTableTableOrderingComposer,
      $$NotificationLogTableTableAnnotationComposer,
      $$NotificationLogTableTableCreateCompanionBuilder,
      $$NotificationLogTableTableUpdateCompanionBuilder,
      (
        NotificationLogTableData,
        BaseReferences<
          _$AppDatabase,
          $NotificationLogTableTable,
          NotificationLogTableData
        >,
      ),
      NotificationLogTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$InvoicesTableTableTableManager get invoicesTable =>
      $$InvoicesTableTableTableManager(_db, _db.invoicesTable);
  $$InvoiceItemsTableTableTableManager get invoiceItemsTable =>
      $$InvoiceItemsTableTableTableManager(_db, _db.invoiceItemsTable);
  $$CustomersTableTableTableManager get customersTable =>
      $$CustomersTableTableTableManager(_db, _db.customersTable);
  $$ExpensesTableTableTableManager get expensesTable =>
      $$ExpensesTableTableTableManager(_db, _db.expensesTable);
  $$InventoryTableTableTableManager get inventoryTable =>
      $$InventoryTableTableTableManager(_db, _db.inventoryTable);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
  $$UserSettingsTableTableTableManager get userSettingsTable =>
      $$UserSettingsTableTableTableManager(_db, _db.userSettingsTable);
  $$BusinessSettingsTableTableTableManager get businessSettingsTable =>
      $$BusinessSettingsTableTableTableManager(_db, _db.businessSettingsTable);
  $$DebtsTableTableTableManager get debtsTable =>
      $$DebtsTableTableTableManager(_db, _db.debtsTable);
  $$DebtPaymentsTableTableTableManager get debtPaymentsTable =>
      $$DebtPaymentsTableTableTableManager(_db, _db.debtPaymentsTable);
  $$TeamMembersTableTableTableManager get teamMembersTable =>
      $$TeamMembersTableTableTableManager(_db, _db.teamMembersTable);
  $$CashAccountsTableTableTableManager get cashAccountsTable =>
      $$CashAccountsTableTableTableManager(_db, _db.cashAccountsTable);
  $$CashTransactionsTableTableTableManager get cashTransactionsTable =>
      $$CashTransactionsTableTableTableManager(_db, _db.cashTransactionsTable);
  $$DailyReconciliationsTableTableTableManager get dailyReconciliationsTable =>
      $$DailyReconciliationsTableTableTableManager(
        _db,
        _db.dailyReconciliationsTable,
      );
  $$MasterCategoriesTableTableTableManager get masterCategoriesTable =>
      $$MasterCategoriesTableTableTableManager(_db, _db.masterCategoriesTable);
  $$MasterProductsTableTableTableManager get masterProductsTable =>
      $$MasterProductsTableTableTableManager(_db, _db.masterProductsTable);
  $$NotificationLogTableTableTableManager get notificationLogTable =>
      $$NotificationLogTableTableTableManager(_db, _db.notificationLogTable);
}

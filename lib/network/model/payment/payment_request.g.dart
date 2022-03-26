// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentRequest _$PaymentRequestFromJson(Map<String, dynamic> json) {
  return PaymentRequest(
    action: json['action'] as String,
    account: json['account'] as String,
    amount_raw: json['amount_raw'] as String,
    requesting_account: json['requesting_account'] as String,
    request_signature: json['request_signature'] as String,
    request_nonce: json['request_nonce'] as String,
    memo: json['memo'] as String,
  );
}

Map<String, dynamic> _$PaymentRequestToJson(PaymentRequest instance) {
  final val = <String, dynamic>{
    'action': instance.action,
    'account': instance.account,
    'amount_raw': instance.amount_raw,
    'requesting_account': instance.requesting_account,
    'request_signature': instance.request_signature,
    'request_nonce': instance.request_nonce,
    'memo': instance.memo,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  return val;
}
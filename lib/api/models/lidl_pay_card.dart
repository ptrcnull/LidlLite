class LidlPayCardModel {
  final String number;
  final String brand;
  final String loyaltyId;
  final String alias;
  final bool isDefault;
  final bool isExpired;

  LidlPayCardModel.fromJson(Map<String, dynamic> json)
      : number = json['number'],
        brand = json['brand'],
        loyaltyId = json['loyaltyId'],
        alias = json['alias'],
        isDefault = json['isDefault'],
        isExpired = json['isExpired'];

  Map<String, dynamic> asJson() {
    return {
      'number': number,
      'brand': brand,
      'loyaltyId': loyaltyId,
      'alias': alias,
      'isDefault': isDefault,
      'isExpired': isExpired,
    };
  }
}

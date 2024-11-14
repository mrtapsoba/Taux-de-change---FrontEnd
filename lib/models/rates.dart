class Rate {
  final String company;
  final String? website;
  final String currencyFrom;
  final List<Map<String, dynamic>> rates;

  Rate({
    required this.company,
    this.website,
    required this.currencyFrom,
    required this.rates,
  });

  factory Rate.fromJson(Map<String, dynamic> json) {
    return Rate(
      company: json['company'],
      website: json['website'],
      currencyFrom: json['currency_from'],
      rates: List<Map<String, dynamic>>.from(json['rates']),
    );
  }
}

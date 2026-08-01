class BusinessInfo {
  final String companyName;
  final String companyLogoUrl;
  final String address;
  final String mobileNumber;
  final String whatsappNumber;
  final String email;
  final String upiId;
  final String facebookLink;
  final String instagramLink;
  final String twitterLink;
  final String aboutUs;
  final String contactInfo;
  final String termsAndConditions;
  final String privacyPolicy;
  final String refundPolicy;
  final String shippingPolicy;
  final String faviconUrl;

  BusinessInfo({
    required this.companyName,
    required this.companyLogoUrl,
    required this.address,
    required this.mobileNumber,
    required this.whatsappNumber,
    required this.email,
    required this.upiId,
    this.facebookLink = '',
    this.instagramLink = '',
    this.twitterLink = '',
    this.aboutUs = '',
    this.contactInfo = '',
    this.termsAndConditions = '',
    this.privacyPolicy = '',
    this.refundPolicy = '',
    this.shippingPolicy = '',
    this.faviconUrl = '',
  });

  factory BusinessInfo.fromMap(Map<String, dynamic> map) {
    return BusinessInfo(
      companyName: map['companyName'] ?? 'Al Ruby Perfumes',
      companyLogoUrl: map['companyLogoUrl'] ?? '',
      address: map['address'] ?? 'Erumathadam Malappuram - 679338',
      mobileNumber: map['mobileNumber'] ?? '9400859846',
      whatsappNumber: map['whatsappNumber'] ?? '9656978468',
      email: map['email'] ?? 'info@alrubyperfumes.com',
      upiId: map['upiId'] ?? 'ismuchelembra-0002@oksbi',
      facebookLink: map['facebookLink'] ?? '',
      instagramLink: map['instagramLink'] ?? '',
      twitterLink: map['twitterLink'] ?? '',
      aboutUs: map['aboutUs'] ?? '',
      contactInfo: map['contactInfo'] ?? '',
      termsAndConditions: map['termsAndConditions'] ?? '',
      privacyPolicy: map['privacyPolicy'] ?? '',
      refundPolicy: map['refundPolicy'] ?? '',
      shippingPolicy: map['shippingPolicy'] ?? '',
      faviconUrl: map['faviconUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'companyLogoUrl': companyLogoUrl,
      'address': address,
      'mobileNumber': mobileNumber,
      'whatsappNumber': whatsappNumber,
      'email': email,
      'upiId': upiId,
      'facebookLink': facebookLink,
      'instagramLink': instagramLink,
      'twitterLink': twitterLink,
      'aboutUs': aboutUs,
      'contactInfo': contactInfo,
      'termsAndConditions': termsAndConditions,
      'privacyPolicy': privacyPolicy,
      'refundPolicy': refundPolicy,
      'shippingPolicy': shippingPolicy,
      'faviconUrl': faviconUrl,
    };
  }

  BusinessInfo copyWith({
    String? companyName,
    String? companyLogoUrl,
    String? address,
    String? mobileNumber,
    String? whatsappNumber,
    String? email,
    String? upiId,
    String? facebookLink,
    String? instagramLink,
    String? twitterLink,
    String? aboutUs,
    String? contactInfo,
    String? termsAndConditions,
    String? privacyPolicy,
    String? refundPolicy,
    String? shippingPolicy,
    String? faviconUrl,
  }) {
    return BusinessInfo(
      companyName: companyName ?? this.companyName,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      address: address ?? this.address,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      email: email ?? this.email,
      upiId: upiId ?? this.upiId,
      facebookLink: facebookLink ?? this.facebookLink,
      instagramLink: instagramLink ?? this.instagramLink,
      twitterLink: twitterLink ?? this.twitterLink,
      aboutUs: aboutUs ?? this.aboutUs,
      contactInfo: contactInfo ?? this.contactInfo,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      refundPolicy: refundPolicy ?? this.refundPolicy,
      shippingPolicy: shippingPolicy ?? this.shippingPolicy,
      faviconUrl: faviconUrl ?? this.faviconUrl,
    );
  }
}

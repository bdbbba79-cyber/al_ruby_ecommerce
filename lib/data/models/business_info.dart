class HomeBanner {
  final String imageUrl;
  final String? productId;

  HomeBanner({required this.imageUrl, this.productId});

  factory HomeBanner.fromMap(Map<String, dynamic> map) {
    return HomeBanner(
      imageUrl: map['imageUrl'] ?? '',
      productId: map['productId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'productId': productId,
    };
  }
}

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
  final List<String> bannerUrls;
  final List<HomeBanner> banners;
  
  // Coupon configuration
  final String couponCode;
  final double couponDiscountPercentage;
  final List<String> couponProductIds;

  // Promo / Lifestyle Specials Banner
  final String promoBannerTag;
  final String promoBannerTitle;
  final String promoBannerButtonText;
  final String promoBannerTargetType; // 'all_products', 'category', 'product', 'url'
  final String promoBannerTargetValue; // category name, productId, or route/url

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
    this.bannerUrls = const [],
    this.banners = const [],
    this.couponCode = '',
    this.couponDiscountPercentage = 0.0,
    this.couponProductIds = const [],
    this.promoBannerTag = 'LIFESTYLE SPECIALS',
    this.promoBannerTitle = 'UP TO 40% OFF ON WATCHES, APPAREL & FOOTWEAR',
    this.promoBannerButtonText = 'SHOP NOW',
    this.promoBannerTargetType = 'all_products',
    this.promoBannerTargetValue = '',
  });

  List<HomeBanner> get activeBanners {
    if (banners.isNotEmpty) return banners;
    return bannerUrls.map((url) => HomeBanner(imageUrl: url)).toList();
  }

  factory BusinessInfo.fromMap(Map<String, dynamic> map) {
    return BusinessInfo(
      companyName: map['companyName'] ?? 'IZZFAH NOOBI',
      companyLogoUrl: map['companyLogoUrl'] ?? '',
      address: map['address'] ?? 'Erumathadam Malappuram - 679338',
      mobileNumber: map['mobileNumber'] ?? '9400859846',
      whatsappNumber: map['whatsappNumber'] ?? '919656978468',
      email: map['email'] ?? 'support@izzfahnoobi.com',
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
      bannerUrls: List<String>.from(map['bannerUrls'] ?? []),
      banners: (map['banners'] as List?)
              ?.map((b) => HomeBanner.fromMap(Map<String, dynamic>.from(b)))
              .toList() ??
          [],
      couponCode: map['couponCode'] ?? '',
      couponDiscountPercentage: (map['couponDiscountPercentage'] as num?)?.toDouble() ?? 0.0,
      couponProductIds: List<String>.from(map['couponProductIds'] ?? []),
      promoBannerTag: map['promoBannerTag'] ?? 'LIFESTYLE SPECIALS',
      promoBannerTitle: map['promoBannerTitle'] ?? 'UP TO 40% OFF ON WATCHES, APPAREL & FOOTWEAR',
      promoBannerButtonText: map['promoBannerButtonText'] ?? 'SHOP NOW',
      promoBannerTargetType: map['promoBannerTargetType'] ?? 'all_products',
      promoBannerTargetValue: map['promoBannerTargetValue'] ?? '',
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
      'bannerUrls': bannerUrls,
      'banners': banners.map((b) => b.toMap()).toList(),
      'couponCode': couponCode,
      'couponDiscountPercentage': couponDiscountPercentage,
      'couponProductIds': couponProductIds,
      'promoBannerTag': promoBannerTag,
      'promoBannerTitle': promoBannerTitle,
      'promoBannerButtonText': promoBannerButtonText,
      'promoBannerTargetType': promoBannerTargetType,
      'promoBannerTargetValue': promoBannerTargetValue,
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
    List<String>? bannerUrls,
    List<HomeBanner>? banners,
    String? couponCode,
    double? couponDiscountPercentage,
    List<String>? couponProductIds,
    String? promoBannerTag,
    String? promoBannerTitle,
    String? promoBannerButtonText,
    String? promoBannerTargetType,
    String? promoBannerTargetValue,
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
      bannerUrls: bannerUrls ?? this.bannerUrls,
      banners: banners ?? this.banners,
      couponCode: couponCode ?? this.couponCode,
      couponDiscountPercentage: couponDiscountPercentage ?? this.couponDiscountPercentage,
      couponProductIds: couponProductIds ?? this.couponProductIds,
      promoBannerTag: promoBannerTag ?? this.promoBannerTag,
      promoBannerTitle: promoBannerTitle ?? this.promoBannerTitle,
      promoBannerButtonText: promoBannerButtonText ?? this.promoBannerButtonText,
      promoBannerTargetType: promoBannerTargetType ?? this.promoBannerTargetType,
      promoBannerTargetValue: promoBannerTargetValue ?? this.promoBannerTargetValue,
    );
  }
}

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:al_ruby_ecommerce/data/models/business_info.dart';
import 'package:al_ruby_ecommerce/data/repositories/store_repository.dart';

class BusinessRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StoreRepository _storeRepo = StoreRepository();

  Stream<BusinessInfo> watchBusinessInfo() {
    return _firestore
        .collection('business_information')
        .doc('details')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return BusinessInfo.fromMap(snapshot.data()!);
      }
      return BusinessInfo(
        companyName: 'Al Ruby Perfumes',
        companyLogoUrl: '',
        address: 'Erumathadam Malappuram - 679338',
        mobileNumber: '9400859846',
        whatsappNumber: '9656978468',
        email: 'info@alrubyperfumes.com',
        upiId: 'ismuchelembra-0002@oksbi',
      );
    });
  }

  Future<BusinessInfo> getBusinessInfo() async {
    final doc = await _firestore.collection('business_information').doc('details').get();
    if (doc.exists && doc.data() != null) {
      return BusinessInfo.fromMap(doc.data()!);
    }
    return BusinessInfo(
      companyName: 'Al Ruby Perfumes',
      companyLogoUrl: '',
      address: 'Erumathadam Malappuram - 679338',
      mobileNumber: '9400859846',
      whatsappNumber: '9656978468',
      email: 'info@alrubyperfumes.com',
      upiId: 'ismuchelembra-0002@oksbi',
    );
  }

  Future<void> updateBusinessInfo(BusinessInfo info) async {
    await _firestore.collection('business_information').doc('details').set(info.toMap());
  }

  Future<String> uploadLogo(Uint8List logoBytes) async {
    return await _storeRepo.uploadImage(logoBytes, 'business/logo.png');
  }

  Future<String> uploadFavicon(Uint8List faviconBytes) async {
    return await _storeRepo.uploadImage(faviconBytes, 'business/favicon.png');
  }
}

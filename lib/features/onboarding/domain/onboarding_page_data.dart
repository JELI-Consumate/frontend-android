import 'package:flutter/foundation.dart';

@immutable
class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.illustrationAsset,
    required this.illustrationLabel,
    required this.body,
    required this.ctaLabel,
  });

  final String title;
  final String subtitle;
  final String illustrationAsset;
  final String illustrationLabel;
  final String body;
  final String ctaLabel;
}

const List<OnboardingPageData> onboardingPages = [
  OnboardingPageData(
    title: 'Selamat Datang!',
    subtitle: 'Mari menjadi konsumen yang lebih cerdas dan terlindungi.',
    illustrationAsset: 'assets/images/welcome_shopping.png',
    illustrationLabel:
        'Ilustrasi seorang konsumen mendorong troli belanja berisi tas belanja.',
    body:
        'Tingkatkan pengetahuanmu dan jadilah **konsumen cerdas** '
        'di berbagai sektor kehidupan.',
    ctaLabel: 'Mulai',
  ),
];

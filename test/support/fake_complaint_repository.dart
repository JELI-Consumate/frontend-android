import 'package:consumate/core/network/api_exception.dart';
import 'package:consumate/features/complaint/data/complaint_repository.dart';
import 'package:consumate/features/complaint/data/models/complaint_agency.dart';

class FakeComplaintRepository implements ComplaintRepository {
  FakeComplaintRepository({this.channels});

  List<ComplaintChannel>? channels;

  ApiException? failAgenciesWith;
  ApiException? failDetailWith;

  final List<String> calls = [];

  static const bpom = ComplaintAgency(
    id: 'a1',
    slug: 'bpom',
    shortName: 'BPOM',
    fullName: 'Badan Pengawas Obat dan Makanan',
    summary: 'Pengaduan terkait obat, makanan, dan kosmetik.',
    logoUrl: null,
    order: 1,
  );

  static const ylki = ComplaintAgency(
    id: 'a2',
    slug: 'ylki',
    shortName: 'YLKI',
    fullName: 'Yayasan Lembaga Konsumen Indonesia',
    summary: 'Informasi, konsultasi, dan pengaduan konsumen.',
    logoUrl: null,
    order: 2,
  );

  static const defaultChannels = [
    ComplaintChannel(
      type: ComplaintChannelType.whatsapp,
      label: 'WhatsApp Halo BPOM',
      value: '0811-9181-533',
      url: 'https://wa.me/6281191811533',
      buttonLabel: 'Hubungi Halo BPOM',
    ),
    ComplaintChannel(
      type: ComplaintChannelType.address,
      label: 'Alamat',
      value: 'Jl. Percetakan Negara',
      url: null,
      buttonLabel: null,
    ),
  ];

  @override
  Future<List<ComplaintAgency>> agencies() async {
    calls.add('agencies');
    if (failAgenciesWith != null) throw failAgenciesWith!;
    return const [bpom, ylki];
  }

  @override
  Future<ComplaintAgencyDetail> agencyDetail(String slug) async {
    calls.add('agencyDetail($slug)');
    if (failDetailWith != null) throw failDetailWith!;
    return ComplaintAgencyDetail(
      id: bpom.id,
      slug: bpom.slug,
      shortName: bpom.shortName,
      fullName: bpom.fullName,
      summary: bpom.summary,
      logoUrl: null,
      order: 1,
      description: 'BPOM mengawasi obat dan makanan.',
      whenToContact: const ['Menemukan produk ilegal.', 'Kosmetik berbahaya.'],
      howToAccess: 'Gunakan kanal resmi BPOM.',
      notes: null,
      channels: channels ?? defaultChannels,
    );
  }

  @override
  Future<List<ComplaintCategory>> categories() async {
    calls.add('categories');
    return const [
      ComplaintCategory(
        id: 'c1',
        problem: 'Dugaan produk obat atau makanan ilegal',
        agencies: [ComplaintCategoryAgency(slug: 'bpom', shortName: 'BPOM')],
      ),
    ];
  }
}

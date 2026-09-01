import 'package:perlindungan_konsumen/core/network/api_exception.dart';
import 'package:perlindungan_konsumen/features/learning/data/learning_repository.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/journey.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/journey_detail.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/learning_module.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/learning_status.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/sector.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/sector_detail.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/sector_survey.dart';

/// Data tiruan yang bentuknya persis hasil `curl` sungguhan ke
/// `GET /sectors/e-commerce` dan `GET /journeys/1` saat menyusun fitur ini
/// (lihat ringkasan pekerjaan) — bukan data karangan.
class FakeLearningRepository implements LearningRepository {
  FakeLearningRepository({
    List<Journey>? journeys,
    List<LearningModule>? modules,
    Sector? sector,
    this.quizScore,
  }) : journeys = journeys ?? defaultJourneys,
       modules = modules ?? _defaultModules,
       sector = sector ?? defaultSector;

  List<Journey> journeys;
  List<LearningModule> modules;

  /// Mutable seperti [journeys]/[modules] -- test survei mengganti ini
  /// dengan varian yang punya `surveys.pretest`/`posttest` terkonfigurasi.
  Sector sector;

  /// Mutable -- test bisa mengubahnya di tengah jalan (mis. sesudah
  /// men-simulasikan kuis selesai lewat `FakeModuleRepository.onComplete`)
  /// supaya panggilan `journeyDetail` BERIKUTNYA memuat nilai barunya.
  int? quizScore;

  ApiException? failWith;

  final List<String> calls = [];

  static const defaultSector = Sector(
    id: '1',
    slug: 'e-commerce',
    name: 'E-Commerce',
    description:
        'Edukasi perlindungan konsumen untuk transaksi jual-beli online.',
    iconUrl: null,
    color: null,
    order: 1,
    progress: LearningProgress(status: LearningStatus.inProgress, percent: 2),
  );

  static const defaultJourneys = [
    Journey(
      id: '1',
      slug: 'kenali-hakmu-sebagai-konsumen',
      title: 'Kenali Hakmu sebagai Konsumen',
      description:
          'Pengantar tentang kepraktisan belanja online, risiko dasar '
          'e-commerce, serta pengenalan awal mengenai peran konsumen.',
      order: 1,
      estimatedMinutes: 68,
      isUnlocked: true,
      modulesCount: 12,
      progress: LearningProgress(status: LearningStatus.inProgress, percent: 2),
    ),
    Journey(
      id: '2',
      slug: 'belanja-online-dengan-lebih-cerdas',
      title: 'Belanja Online dengan Lebih Cerdas',
      description: 'Panduan praktis mengenali toko asli dan aman bertransaksi.',
      order: 2,
      estimatedMinutes: 61,
      isUnlocked: false,
      modulesCount: 10,
      progress: LearningProgress.zero,
    ),
    Journey(
      id: '3',
      slug: 'lindungi-dirimu-dari-risiko-digital',
      title: 'Lindungi Dirimu dari Risiko Digital',
      description: 'Edukasi pencegahan kejahatan siber dan phishing.',
      order: 3,
      estimatedMinutes: 66,
      isUnlocked: false,
      modulesCount: 11,
      progress: LearningProgress.zero,
    ),
    Journey(
      id: '4',
      slug: 'berani-memperjuangkan-hakmu',
      title: 'Berani Memperjuangkan Hakmu',
      description: 'Langkah penyelesaian sengketa transaksi secara legal.',
      order: 4,
      estimatedMinutes: 66,
      isUnlocked: false,
      modulesCount: 11,
      progress: LearningProgress.zero,
    ),
  ];

  static const _defaultModules = [
    LearningModule(
      id: '1',
      type: ModuleContentType.opening,
      title: 'Pembuka Journey',
      description: null,
      order: 1,
      estimatedMinutes: 2,
      isRequired: true,
      progress: LearningProgress(
        status: LearningStatus.completed,
        percent: 100,
      ),
      locked: false,
    ),
    LearningModule(
      id: '2',
      type: ModuleContentType.video,
      title: 'Pentingnya Perlindungan Konsumen dalam E-Commerce',
      description: null,
      order: 2,
      estimatedMinutes: 10,
      isRequired: true,
      progress: LearningProgress.zero,
      locked: false, // module 1 (sebelumnya) sudah completed
    ),
    LearningModule(
      id: '3',
      type: ModuleContentType.materi,
      title: 'Mengenal Aturan Hukum Saat Belanja Online',
      description: null,
      order: 3,
      estimatedMinutes: 5,
      isRequired: true,
      progress: LearningProgress.zero,
      locked: true, // module 2 (sebelumnya) belum completed
    ),
    LearningModule(
      id: '11',
      type: ModuleContentType.kuis,
      title: 'Kuis Evaluasi Journey 1',
      description: null,
      order: 11,
      estimatedMinutes: 10,
      isRequired: true,
      progress: LearningProgress.zero,
      locked: true,
    ),
    LearningModule(
      id: '12',
      type: ModuleContentType.refleksi,
      title: 'Lembar Pemahaman Hak Dasar',
      description: null,
      order: 12,
      estimatedMinutes: 5,
      isRequired: true,
      progress: LearningProgress.zero,
      locked: true,
    ),
  ];

  @override
  Future<List<Sector>> sectors() async {
    calls.add('sectors');
    if (failWith != null) throw failWith!;
    return [sector];
  }

  @override
  Future<SectorDetail> sectorDetail(String slug) async {
    calls.add('sectorDetail($slug)');
    if (failWith != null) throw failWith!;
    return SectorDetail(sector: sector, journeys: journeys);
  }

  @override
  Future<JourneyDetail> journeyDetail(String journeyId) async {
    calls.add('journeyDetail($journeyId)');
    if (failWith != null) throw failWith!;
    final journey = journeys.firstWhere((j) => j.id == journeyId);
    return JourneyDetail(
      journey: journey,
      modules: modules,
      quizScore: quizScore,
    );
  }

  @override
  Future<void> completePretestSurvey(String slug) async {
    calls.add('completePretestSurvey($slug)');
    if (failWith != null) throw failWith!;
    sector = Sector(
      id: sector.id,
      slug: sector.slug,
      name: sector.name,
      description: sector.description,
      iconUrl: sector.iconUrl,
      color: sector.color,
      order: sector.order,
      progress: sector.progress,
      surveys: SectorSurveys(
        pretest: SectorSurvey(
          link: sector.surveys.pretest.link,
          completedAt: DateTime(2026),
        ),
        posttest: sector.surveys.posttest,
      ),
    );
  }

  @override
  Future<void> completePosttestSurvey(String slug) async {
    calls.add('completePosttestSurvey($slug)');
    if (failWith != null) throw failWith!;
    sector = Sector(
      id: sector.id,
      slug: sector.slug,
      name: sector.name,
      description: sector.description,
      iconUrl: sector.iconUrl,
      color: sector.color,
      order: sector.order,
      progress: sector.progress,
      surveys: SectorSurveys(
        pretest: sector.surveys.pretest,
        posttest: SectorSurvey(
          link: sector.surveys.posttest.link,
          completedAt: DateTime(2026),
        ),
      ),
    );
  }
}

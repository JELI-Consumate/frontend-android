import 'package:perlindungan_konsumen/features/learning/data/models/learning_module.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/learning_status.dart';
import 'package:perlindungan_konsumen/features/module/data/models/content/article_content.dart';
import 'package:perlindungan_konsumen/features/module/data/models/content/quiz_content.dart';
import 'package:perlindungan_konsumen/features/module/data/models/content/reflection_content.dart';
import 'package:perlindungan_konsumen/features/module/data/models/content/simulation_content.dart';
import 'package:perlindungan_konsumen/features/module/data/models/content/video_content.dart';
import 'package:perlindungan_konsumen/features/module/data/models/module_detail.dart';
import 'package:perlindungan_konsumen/features/module/data/models/module_page.dart';

/// Fixture satu [ModuleDetail] per tipe module, dipakai `module_flow_test.dart`
/// dan potongan tes navigasi di `learning_flow_test.dart`. ID soal/opsi/langkah
/// di sini SENGAJA disamakan dengan konstanta di `FakeModuleRepository`
/// (`correctChoiceOptionByQuestion`, `correctOrderingPosition`, dst.) supaya
/// alur jawab-benar/jawab-salah di test itu benar-benar tersimulasikan.
ModuleDetail videoModuleFixture({
  LearningStatus status = LearningStatus.notStarted,
}) {
  return ModuleDetail(
    id: 10,
    type: ModuleContentType.video,
    title: 'Pentingnya Perlindungan Konsumen dalam E-Commerce',
    description: null,
    estimatedMinutes: 10,
    pages: [
      ModulePage(
        id: 1010,
        order: 1,
        contentType: ContentType.video,
        content: const VideoPageContent(
          VideoContent(
            id: 900,
            title: 'Pentingnya Perlindungan Konsumen dalam E-Commerce',
            description:
                'Kenali hak-hak dasarmu sebagai konsumen sebelum belanja online.',
            youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            youtubeVideoId: 'dQw4w9WgXcQ',
            promptQuestion:
                'Apa risiko belanja online yang paling sering kamu temui?',
          ),
        ),
        status: status,
        lastPosition: 0,
      ),
    ],
  );
}

ModuleDetail articleModuleFixture({
  ModuleContentType type = ModuleContentType.materi,
  LearningStatus status = LearningStatus.notStarted,
}) {
  return ModuleDetail(
    id: 12,
    type: type,
    title: 'Mengenal Aturan Hukum Saat Belanja Online',
    description: 'Ringkasan aturan dasar transaksi online.',
    estimatedMinutes: 5,
    pages: [
      ModulePage(
        id: 1012,
        order: 1,
        contentType: ContentType.article,
        content: ArticlePageContent(
          ArticleContent(
            id: 910,
            title: 'Mengenal Aturan Hukum Saat Belanja Online',
            blocks: const [
              ArticleBlock(
                id: 9101,
                blockType: ArticleBlockType.paragraph,
                text:
                    'Setiap transaksi online tunduk pada UU Perlindungan Konsumen.',
                imageUrl: null,
                altText: null,
                order: 1,
              ),
              ArticleBlock(
                id: 9102,
                blockType: ArticleBlockType.image,
                text: null,
                imageUrl: 'https://placehold.co/800x600?text=Infografis',
                altText: 'Infografis aturan belanja online',
                order: 2,
              ),
              ArticleBlock(
                id: 9103,
                blockType: ArticleBlockType.listItem,
                text: 'Simpan selalu bukti transaksi.',
                imageUrl: null,
                altText: null,
                order: 3,
              ),
              ArticleBlock(
                id: 9104,
                blockType: ArticleBlockType.reference,
                text: 'UU No. 8 Tahun 1999 tentang Perlindungan Konsumen.',
                imageUrl: null,
                altText: null,
                order: 4,
              ),
            ],
          ),
        ),
        status: status,
        lastPosition: 0,
      ),
    ],
  );
}

ModuleDetail quizModuleFixture() {
  return ModuleDetail(
    id: 15,
    type: ModuleContentType.kuis,
    title: 'Kuis Evaluasi Journey 1',
    description: null,
    estimatedMinutes: 10,
    pages: [
      ModulePage(
        id: 1015,
        order: 1,
        contentType: ContentType.quiz,
        content: const QuizPageContent(
          QuizContent(
            id: 100,
            passingScore: 70,
            shuffleQuestions: false,
            segments: [
              QuizSegment(
                id: 20,
                segmentType: QuizSegmentType.multipleChoice,
                title: 'Pilihan Ganda',
                instruction: 'Pilih satu jawaban yang paling tepat.',
                order: 1,
                questions: [
                  QuizQuestion(
                    id: 201,
                    question: 'Apa hak dasar konsumen saat belanja online?',
                    order: 1,
                    choiceOptions: [
                      QuizChoiceOption(
                        id: 301,
                        optionText: 'Mendapat informasi yang benar',
                        order: 1,
                      ),
                      QuizChoiceOption(
                        id: 302,
                        optionText: 'Dilarang komplain',
                        order: 2,
                      ),
                    ],
                  ),
                  QuizQuestion(
                    id: 202,
                    question: 'Apa yang sebaiknya disimpan setelah transaksi?',
                    order: 2,
                    choiceOptions: [
                      QuizChoiceOption(
                        id: 303,
                        optionText: 'Tidak perlu apa-apa',
                        order: 1,
                      ),
                      QuizChoiceOption(
                        id: 304,
                        optionText: 'Bukti transaksi',
                        order: 2,
                      ),
                    ],
                  ),
                ],
                likertScaleOptions: [],
              ),
              QuizSegment(
                id: 21,
                segmentType: QuizSegmentType.likert,
                title: 'Refleksi Diri',
                instruction: 'Seberapa yakin kamu dengan pemahamanmu?',
                order: 2,
                questions: [
                  QuizQuestion(
                    id: 203,
                    question: 'Saya paham hak dasar konsumen.',
                    order: 1,
                    choiceOptions: [],
                  ),
                ],
                likertScaleOptions: [
                  LikertScaleOption(
                    id: 401,
                    value: 1,
                    label: 'Sangat tidak yakin',
                    order: 1,
                  ),
                  LikertScaleOption(
                    id: 402,
                    value: 2,
                    label: 'Tidak yakin',
                    order: 2,
                  ),
                  LikertScaleOption(
                    id: 403,
                    value: 3,
                    label: 'Netral',
                    order: 3,
                  ),
                  LikertScaleOption(
                    id: 404,
                    value: 4,
                    label: 'Yakin',
                    order: 4,
                  ),
                  LikertScaleOption(
                    id: 405,
                    value: 5,
                    label: 'Sangat yakin',
                    order: 5,
                  ),
                ],
              ),
            ],
          ),
        ),
        status: LearningStatus.notStarted,
        lastPosition: 0,
      ),
    ],
  );
}

ModuleDetail simulationMatchingModuleFixture() {
  return ModuleDetail(
    id: 16,
    type: ModuleContentType.simulasi,
    title: 'Game Pilah Cepat: Keranjang Belanja Berdaya',
    description: null,
    estimatedMinutes: 8,
    pages: [
      ModulePage(
        id: 1016,
        order: 1,
        contentType: ContentType.simulation,
        content: const SimulationPageContent(
          SimulationContent(
            id: 500,
            title: 'Game Pilah Cepat: Keranjang Belanja Berdaya',
            simulationType: SimulationGameType.matching,
            scenario:
                'Pasangkan setiap situasi dengan tindakan konsumen yang tepat.',
            matchingPairs: [
              SimulationMatchingPair(
                id: 701,
                leftLabel: 'Barang datang tidak sesuai pesanan',
                leftDescription: null,
                leftImageUrl: null,
                rightLabel: 'Ajukan komplain ke penjual',
                rightDescription: null,
                rightImageUrl: null,
                order: 1,
              ),
              SimulationMatchingPair(
                id: 702,
                leftLabel: 'Harga terlalu murah dari pasaran',
                leftDescription: null,
                leftImageUrl: null,
                rightLabel: 'Waspada indikasi penipuan',
                rightDescription: null,
                rightImageUrl: null,
                order: 2,
              ),
            ],
            orderingSteps: [],
          ),
        ),
        status: LearningStatus.notStarted,
        lastPosition: 0,
      ),
    ],
  );
}

ModuleDetail simulationOrderingModuleFixture() {
  return ModuleDetail(
    id: 17,
    type: ModuleContentType.simulasi,
    title: 'Game Susun Jalur Solusi: Misi Ganti Rugi',
    description: null,
    estimatedMinutes: 8,
    pages: [
      ModulePage(
        id: 1017,
        order: 1,
        contentType: ContentType.simulation,
        content: const SimulationPageContent(
          SimulationContent(
            id: 501,
            title: 'Game Susun Jalur Solusi: Misi Ganti Rugi',
            simulationType: SimulationGameType.ordering,
            scenario:
                'Susun langkah penyelesaian sengketa transaksi sesuai urutannya.',
            matchingPairs: [],
            orderingSteps: [
              SimulationOrderingStep(
                id: 601,
                label: 'Hubungi penjual',
                imageUrl: null,
                order: 1,
              ),
              SimulationOrderingStep(
                id: 602,
                label: 'Ajukan komplain ke platform',
                imageUrl: null,
                order: 2,
              ),
              SimulationOrderingStep(
                id: 603,
                label: 'Laporkan ke BPKN',
                imageUrl: null,
                order: 3,
              ),
            ],
          ),
        ),
        status: LearningStatus.notStarted,
        lastPosition: 0,
      ),
    ],
  );
}

ModuleDetail reflectionModuleFixture() {
  return ModuleDetail(
    id: 18,
    type: ModuleContentType.refleksi,
    title: 'Lembar Pemahaman Hak Dasar',
    description: null,
    estimatedMinutes: 5,
    pages: [
      ModulePage(
        id: 1018,
        order: 1,
        contentType: ContentType.reflection,
        content: const ReflectionPageContent(
          ReflectionContent(
            id: 800,
            title: 'Lembar Pemahaman Hak Dasar',
            openingMessage: 'Yuk, refleksikan apa yang sudah kamu pelajari.',
            closingTitle: 'Terima kasih!',
            closingMessage: 'Refleksimu sudah tersimpan.',
            sections: [
              ReflectionSection(
                id: 30,
                title: 'Pemahaman',
                instruction: null,
                order: 1,
                questions: [
                  ReflectionQuestion(
                    id: 40,
                    questionType: ReflectionQuestionType.openQuestion,
                    questionText:
                        'Apa hak konsumen yang paling penting menurutmu?',
                    order: 1,
                    answerText: null,
                    checklistItems: [],
                  ),
                  ReflectionQuestion(
                    id: 41,
                    questionType: ReflectionQuestionType.checklist,
                    questionText: 'Centang hal yang sudah kamu lakukan:',
                    order: 2,
                    answerText: null,
                    checklistItems: [
                      ReflectionChecklistItem(
                        id: 50,
                        label: 'Membaca ulasan sebelum membeli',
                        order: 1,
                        isChecked: false,
                      ),
                      ReflectionChecklistItem(
                        id: 51,
                        label: 'Menyimpan bukti transaksi',
                        order: 2,
                        isChecked: false,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        status: LearningStatus.notStarted,
        lastPosition: 0,
      ),
    ],
  );
}

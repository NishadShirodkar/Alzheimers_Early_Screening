// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/theme/app_colors.dart';
import '../../widgets/common/neura_button.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  SHARED FIELD DECORATION
// ═══════════════════════════════════════════════════════════════════════════

InputDecoration _decoration({
  String hint = 'Enter your answer',
  Widget? suffixIcon,
}) =>
    InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

// ═══════════════════════════════════════════════════════════════════════════
//  ENUMS & MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum AnswerType {
  /// Keyboard text field + mic button — used for most questions
  text,

  /// Mic-only (no keyboard) — Registration repeat-back & Repetition phrase
  speechOnly,

  /// Five number rows for Serial 7s, each with its own mic
  serial7,

  /// Five single-letter boxes for WORLD backwards
  spellBackwards,
}

class MmseQuestion {
  final String id;
  final String prompt;
  final String? subtitle;
  final AnswerType type;
  final int maxScore;

  /// Exact accepted answers (lowercased). null = open / non-empty = credit.
  final List<String>? acceptedAnswers;

  /// For spellBackwards: the source word to reverse (e.g. 'WORLD')
  final String? wordToSpell;

  const MmseQuestion({
    required this.id,
    required this.prompt,
    this.subtitle,
    required this.type,
    required this.maxScore,
    this.acceptedAnswers,
    this.wordToSpell,
  });
}

class MmseSection {
  final String title;
  final String description;
  final IconData icon;
  final List<MmseQuestion> questions;

  const MmseSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.questions,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
//  QUESTION BANK  —  30 points, zero self-reported items
// ═══════════════════════════════════════════════════════════════════════════
//
//  Section                  Pts   Notes
//  ─────────────────────────────────────────────────────────────────────────
//  Orientation to Time       6    +1 vs original: time-of-day question added
//  Orientation to Place      5    unchanged
//  Registration              3    speech-only (STT-verified, not checkbox)
//  Attention & Calculation   7    Serial-7s (5) + WORLD backwards (2)
//  Recall                    3    unchanged
//  Language                  6    Naming ×2 (text+mic) + Repetition phrase (4,
//                                 1pt per key word via STT)
//  ─────────────────────────────────────────────────────────────────────────
//  Total                    30

final List<MmseSection> mmseSections = [
  // ── 1. Orientation to Time ── 6 pts ──────────────────────────────────────
  MmseSection(
    title: 'Orientation to Time',
    description: 'Answer each question about the current date and time.',
    icon: Icons.access_time_rounded,
    questions: [
      MmseQuestion(
        id: 'time_year',
        prompt: 'What year is it?',
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: [DateTime.now().year.toString()],
      ),
      MmseQuestion(
        id: 'time_season',
        prompt: 'What season is it?',
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: _getCurrentSeason(),
      ),
      MmseQuestion(
        id: 'time_month',
        prompt: 'What month is it?',
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: _getCurrentMonthAnswers(),
      ),
      MmseQuestion(
        id: 'time_date',
        prompt: "What is today's date?",
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: [DateTime.now().day.toString()],
      ),
      MmseQuestion(
        id: 'time_day',
        prompt: 'What day of the week is it?',
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: _getCurrentDayAnswers(),
      ),
      MmseQuestion(
        id: 'time_timeofday',
        prompt: 'What time of day is it?',
        subtitle: '(morning / afternoon / evening / night)',
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: _getCurrentTimeOfDay(),
      ),
    ],
  ),

  // ── 2. Orientation to Place ── 5 pts ─────────────────────────────────────
  MmseSection(
    title: 'Orientation to Place',
    description: 'Answer each question about where you are.',
    icon: Icons.location_on_rounded,
    questions: [
      MmseQuestion(
        id: 'place_country',
        prompt: 'What country are we in?',
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: null,
      ),
      MmseQuestion(
        id: 'place_state',
        prompt: 'What state or province are we in?',
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: null,
      ),
      MmseQuestion(
        id: 'place_city',
        prompt: 'What city or town are we in?',
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: null,
      ),
      MmseQuestion(
        id: 'place_building',
        prompt: 'What building are we in?',
        subtitle: '(e.g. hospital, clinic, home)',
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: null,
      ),
      MmseQuestion(
        id: 'place_floor',
        prompt: 'What floor are we on?',
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: null,
      ),
    ],
  ),

  // ── 3. Registration ── 3 pts ─ speech-only, STT-verified ─────────────────
  MmseSection(
    title: 'Registration',
    description:
        'Listen to each object. Tap the mic and say the word aloud — it will be verified automatically.',
    icon: Icons.psychology_rounded,
    questions: [
      MmseQuestion(
        id: 'reg_apple',
        prompt: 'The examiner says: "Apple"\n\nRepeat it aloud:',
        type: AnswerType.speechOnly,
        maxScore: 1,
        acceptedAnswers: ['apple'],
      ),
      MmseQuestion(
        id: 'reg_table',
        prompt: 'The examiner says: "Table"\n\nRepeat it aloud:',
        type: AnswerType.speechOnly,
        maxScore: 1,
        acceptedAnswers: ['table'],
      ),
      MmseQuestion(
        id: 'reg_penny',
        prompt: 'The examiner says: "Penny"\n\nRepeat it aloud:',
        type: AnswerType.speechOnly,
        maxScore: 1,
        acceptedAnswers: ['penny'],
      ),
    ],
  ),

  // ── 4. Attention & Calculation ── 7 pts ───────────────────────────────────
  MmseSection(
    title: 'Attention & Calculation',
    description: 'Two attention tasks — Serial 7s and spelling.',
    icon: Icons.calculate_rounded,
    questions: [
      MmseQuestion(
        id: 'serial7',
        prompt: 'Serial 7s: Starting from 100, subtract 7 five times.',
        subtitle: 'Enter each result after subtracting 7. You may type or use the mic.',
        type: AnswerType.serial7,
        maxScore: 5,
      ),
      MmseQuestion(
        id: 'world_backwards',
        prompt: 'Spell the word "WORLD" backwards.',
        subtitle: 'Enter one letter per box. Correct order: D – L – R – O – W',
        type: AnswerType.spellBackwards,
        maxScore: 2,
        wordToSpell: 'WORLD',
      ),
    ],
  ),

  // ── 5. Recall ── 3 pts ────────────────────────────────────────────────────
  MmseSection(
    title: 'Recall',
    description: 'Try to remember the 3 objects named in Registration.',
    icon: Icons.replay_rounded,
    questions: [
      MmseQuestion(
        id: 'recall_1',
        prompt: 'What was the first object?',
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: ['apple'],
      ),
      MmseQuestion(
        id: 'recall_2',
        prompt: 'What was the second object?',
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: ['table'],
      ),
      MmseQuestion(
        id: 'recall_3',
        prompt: 'What was the third object?',
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: ['penny'],
      ),
    ],
  ),

  // ── 6. Language ── 6 pts ──────────────────────────────────────────────────
  MmseSection(
    title: 'Language',
    description: 'Object naming and verbal repetition tasks.',
    icon: Icons.translate_rounded,
    questions: [
      MmseQuestion(
        id: 'lang_pencil',
        prompt: 'Naming: What is this object called?',
        subtitle: '(The examiner holds up a pencil)',
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: ['pencil', 'pen'],
      ),
      MmseQuestion(
        id: 'lang_watch',
        prompt: 'Naming: What is this object called?',
        subtitle: '(The examiner holds up a watch)',
        type: AnswerType.text,
        maxScore: 1,
        acceptedAnswers: ['watch', 'clock', 'wristwatch'],
      ),
      MmseQuestion(
        id: 'lang_repeat',
        prompt:
            'Repetition: Tap the mic and repeat this sentence exactly:\n\n"No ifs, ands, or buts."',
        subtitle:
            'Your speech is transcribed automatically. '
            '1 point is awarded for each key word spoken: no · ifs · ands · buts (max 4).',
        type: AnswerType.speechOnly,
        maxScore: 4,
        acceptedAnswers: null, // fuzzy-scored via MmseScorer.scoreRepetition
      ),
    ],
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════════════════════

List<String> _getCurrentSeason() {
  final m = DateTime.now().month;
  if (m >= 3 && m <= 5) return ['spring'];
  if (m >= 6 && m <= 8) return ['summer'];
  if (m >= 9 && m <= 11) return ['fall', 'autumn'];
  return ['winter'];
}

List<String> _getCurrentMonthAnswers() {
  const months = [
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
  ];
  final n = DateTime.now().month;
  return [months[n - 1], n.toString()];
}

List<String> _getCurrentDayAnswers() {
  const days = [
    'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday',
  ];
  return [days[DateTime.now().weekday - 1]];
}

List<String> _getCurrentTimeOfDay() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 12) return ['morning'];
  if (h >= 12 && h < 17) return ['afternoon'];
  if (h >= 17 && h < 21) return ['evening'];
  return ['night'];
}

// ═══════════════════════════════════════════════════════════════════════════
//  SCORING ENGINE
// ═══════════════════════════════════════════════════════════════════════════

class MmseScorer {
  // ── Text (keyboard or STT-filled) ──────────────────────────────────────
  static int scoreText(MmseQuestion q, String answer) {
    if (q.acceptedAnswers == null) return answer.trim().isNotEmpty ? 1 : 0;
    return q.acceptedAnswers!.contains(answer.trim().toLowerCase())
        ? q.maxScore
        : 0;
  }

  // ── Speech-only (Registration words + Repetition phrase) ───────────────
  static int scoreSpeech(MmseQuestion q, String transcript) {
    if (q.id == 'lang_repeat') return _scoreRepetition(transcript);
    if (q.acceptedAnswers == null) return transcript.trim().isNotEmpty ? 1 : 0;
    final words = transcript.toLowerCase().split(RegExp(r'\s+'));
    return q.acceptedAnswers!.any((a) => words.contains(a)) ? 1 : 0;
  }

  // Repetition: 1pt per key word present in transcript — max 4
  static int _scoreRepetition(String transcript) {
    final t = transcript.toLowerCase();
    const tokens = ['no', 'ifs', 'ands', 'buts'];
    return tokens.where(t.contains).length;
  }

  // ── Serial 7s ───────────────────────────────────────────────────────────
  static int scoreSerial7(List<String> answers) {
    const expected = [93, 86, 79, 72, 65];
    int score = 0;
    for (int i = 0; i < answers.length && i < 5; i++) {
      if (int.tryParse(answers[i].trim()) == expected[i]) score++;
    }
    return score;
  }

  // ── WORLD backwards ─────────────────────────────────────────────────────
  // 5/5 correct → 2 pts | 3–4/5 → 1 pt | <3 → 0 pts
  static int scoreWorldBackwards(List<String> letters) {
    const correct = ['D', 'L', 'R', 'O', 'W'];
    final hits = [
      for (int i = 0; i < 5; i++)
        letters[i].trim().toUpperCase() == correct[i] ? 1 : 0
    ].fold(0, (a, b) => a + b);
    if (hits == 5) return 2;
    if (hits >= 3) return 1;
    return 0;
  }

  // ── Aggregate ───────────────────────────────────────────────────────────
  static Map<String, int> calculateSectionScores(
      Map<String, dynamic> answers) {
    final Map<String, int> out = {};
    for (final section in mmseSections) {
      int total = 0;
      for (final q in section.questions) {
        final ans = answers[q.id];
        if (ans == null) continue;
        total += switch (q.type) {
          AnswerType.text => scoreText(q, ans as String),
          AnswerType.speechOnly => scoreSpeech(q, ans as String),
          AnswerType.serial7 => scoreSerial7(ans as List<String>),
          AnswerType.spellBackwards =>
            scoreWorldBackwards(ans as List<String>),
        };
      }
      out[section.title] = total;
    }
    return out;
  }

  static int totalScore(Map<String, int> s) =>
      s.values.fold(0, (a, b) => a + b);

  static String interpretation(int score) {
    if (score >= 24) return 'Normal / No impairment';
    if (score >= 18) return 'Mild cognitive impairment';
    if (score >= 12) return 'Moderate cognitive impairment';
    return 'Severe cognitive impairment';
  }

  static Color interpretationColor(int score) {
    if (score >= 24) return const Color(0xFF34C759);
    if (score >= 18) return const Color(0xFFFF9500);
    if (score >= 12) return const Color(0xFFFF6B35);
    return const Color(0xFFFF3B30);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MIC BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _MicBtn extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  final bool small;

  const _MicBtn({
    required this.active,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final sz = small ? 32.0 : 38.0;
    final iconSz = small ? 15.0 : 19.0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: sz,
        height: sz,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFFF3B30)
              : AppColors.primary.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          active ? Icons.stop_rounded : Icons.mic_rounded,
          size: iconSz,
          color: active ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STT CONTROLLER
//  Single instance owned by _MmseTestScreenState and passed down.
//  Only one question can listen at a time; starting a new one auto-cancels.
// ═══════════════════════════════════════════════════════════════════════════

class SttController {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _ready = false;

  /// The question-id (or sub-id like 'serial7_2') currently recording.
  String? activeId;

  bool get isListening => _speech.isListening;

  Future<bool> _ensureReady() async {
    if (_ready) return true;
    _ready = await _speech.initialize(onError: (_) {}, onStatus: (_) {});
    return _ready;
  }

  Future<void> startListening({
    required String id,
    required void Function(String partial) onPartial,
    required void Function(String final_) onDone,
  }) async {
    if (!await _ensureReady()) return;
    activeId = id;
    await _speech.listen(
      onResult: (r) {
        if (r.finalResult) {
          activeId = null;
          onDone(r.recognizedWords);
        } else {
          onPartial(r.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 4),
      localeId: 'en_US',
    );
  }

  Future<void> stop() async {
    activeId = null;
    await _speech.stop();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  INPUT WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// ── Text field + mic suffix ──────────────────────────────────────────────
class _TextWithMic extends StatefulWidget {
  final String questionId;
  final String value;
  final SttController stt;
  final ValueChanged<String> onChanged;
  final VoidCallback onRebuild;

  const _TextWithMic({
    required this.questionId,
    required this.value,
    required this.stt,
    required this.onChanged,
    required this.onRebuild,
  });

  @override
  State<_TextWithMic> createState() => _TextWithMicState();
}

class _TextWithMicState extends State<_TextWithMic> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_TextWithMic old) {
    super.didUpdateWidget(old);
    // Sync when parent sets value (e.g. STT populates the field)
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
      _ctrl.selection =
          TextSelection.collapsed(offset: _ctrl.text.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _active =>
      widget.stt.isListening &&
      widget.stt.activeId == widget.questionId;

  Future<void> _toggle() async {
    if (_active) {
      await widget.stt.stop();
      widget.onRebuild();
      return;
    }
    await widget.stt.startListening(
      id: widget.questionId,
      onPartial: (p) {
        _ctrl.text = p;
        _ctrl.selection =
            TextSelection.collapsed(offset: p.length);
        widget.onChanged(p);
        widget.onRebuild();
      },
      onDone: (f) {
        _ctrl.text = f;
        _ctrl.selection =
            TextSelection.collapsed(offset: f.length);
        widget.onChanged(f);
        widget.onRebuild();
      },
    );
    widget.onRebuild();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      decoration: _decoration(
        suffixIcon: _MicBtn(active: _active, onTap: _toggle),
      ),
    );
  }
}

/// ── Speech-only (no keyboard) ─────────────────────────────────────────────
class _SpeechOnly extends StatefulWidget {
  final String questionId;
  final String transcript;
  final SttController stt;
  final ValueChanged<String> onTranscript;
  final VoidCallback onRebuild;

  const _SpeechOnly({
    required this.questionId,
    required this.transcript,
    required this.stt,
    required this.onTranscript,
    required this.onRebuild,
  });

  @override
  State<_SpeechOnly> createState() => _SpeechOnlyState();
}

class _SpeechOnlyState extends State<_SpeechOnly> {
  bool get _active =>
      widget.stt.isListening &&
      widget.stt.activeId == widget.questionId;

  Future<void> _toggle() async {
    if (_active) {
      await widget.stt.stop();
      widget.onRebuild();
      return;
    }
    await widget.stt.startListening(
      id: widget.questionId,
      onPartial: (p) {
        widget.onTranscript(p);
        widget.onRebuild();
      },
      onDone: (f) {
        widget.onTranscript(f);
        widget.onRebuild();
      },
    );
    widget.onRebuild();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.transcript.trim().isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _active
            ? AppColors.primary.withOpacity(0.06)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _active
              ? AppColors.primary.withOpacity(0.45)
              : Colors.grey.shade200,
          width: _active ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasText
                  ? widget.transcript
                  : _active
                      ? 'Listening…'
                      : 'Tap the mic to speak',
              style: TextStyle(
                fontSize: 14,
                color: hasText ? Colors.black87 : Colors.grey.shade500,
                fontStyle:
                    hasText ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _MicBtn(active: _active, onTap: _toggle),
        ],
      ),
    );
  }
}

/// ── Serial 7s: 5 rows, each with text field + individual mic ─────────────
class _Serial7 extends StatefulWidget {
  final String questionId;
  final List<String> values;
  final SttController stt;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback onRebuild;

  const _Serial7({
    required this.questionId,
    required this.values,
    required this.stt,
    required this.onChanged,
    required this.onRebuild,
  });

  @override
  State<_Serial7> createState() => _Serial7State();
}

class _Serial7State extends State<_Serial7> {
  late final List<TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
        5, (i) => TextEditingController(text: widget.values[i]));
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  String _subId(int i) => '${widget.questionId}_$i';
  bool _active(int i) =>
      widget.stt.isListening && widget.stt.activeId == _subId(i);

  Future<void> _toggle(int i) async {
    if (_active(i)) {
      await widget.stt.stop();
      widget.onRebuild();
      return;
    }
    await widget.stt.startListening(
      id: _subId(i),
      onPartial: (p) => _applyDigit(i, p),
      onDone: (f) => _applyDigit(i, f),
    );
    widget.onRebuild();
  }

  void _applyDigit(int i, String raw) {
    final digits = RegExp(r'\d+').firstMatch(raw)?.group(0) ?? raw;
    _ctrls[i].text = digits;
    _ctrls[i].selection =
        TextSelection.collapsed(offset: digits.length);
    final updated = List<String>.from(widget.values);
    updated[i] = digits;
    widget.onChanged(updated);
    widget.onRebuild();
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['1st', '2nd', '3rd', '4th', '5th'];
    return Column(
      children: List.generate(5, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text('${labels[i]}:',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _ctrls[i],
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final updated = List<String>.from(widget.values);
                    updated[i] = v;
                    widget.onChanged(updated);
                  },
                  decoration: _decoration(
                    hint: 'Result',
                    suffixIcon: _MicBtn(
                      active: _active(i),
                      onTap: () => _toggle(i),
                      small: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// ── WORLD backwards: 5 single-letter boxes ───────────────────────────────
class _SpellBackwards extends StatefulWidget {
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  const _SpellBackwards({required this.values, required this.onChanged});

  @override
  State<_SpellBackwards> createState() => _SpellBackwardsState();
}

class _SpellBackwardsState extends State<_SpellBackwards> {
  late final List<TextEditingController> _ctrls;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
        5, (i) => TextEditingController(text: widget.values[i]));
    _nodes = List.generate(5, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // hint banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Correct order:  D  –  L  –  R  –  O  –  W',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            return SizedBox(
              width: 52,
              child: TextField(
                controller: _ctrls[i],
                focusNode: _nodes[i],
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                maxLength: 1,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppColors.primary, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (v) {
                  final updated = List<String>.from(widget.values);
                  updated[i] = v.toUpperCase();
                  widget.onChanged(updated);
                  if (v.isNotEmpty && i < 4) {
                    _nodes[i + 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ROOT SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class MmseTestScreen extends StatefulWidget {
  const MmseTestScreen({super.key});
  @override
  State<MmseTestScreen> createState() => _MmseTestScreenState();
}

class _MmseTestScreenState extends State<MmseTestScreen>
    with SingleTickerProviderStateMixin {
  int _currentSection = 0;
  bool _showResults = false;
  final Map<String, dynamic> _answers = {};
  final SttController _stt = SttController();
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
    _resetAnswers();
  }

  void _resetAnswers() {
    for (final s in mmseSections) {
      for (final q in s.questions) {
        _answers[q.id] = switch (q.type) {
          AnswerType.text || AnswerType.speechOnly => '',
          AnswerType.serial7 || AnswerType.spellBackwards =>
            List<String>.filled(5, ''),
        };
      }
    }
  }

  @override
  void dispose() {
    _stt.stop();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _go(int delta) async {
    await _stt.stop();
    await _fadeCtrl.reverse();
    setState(() {
      _currentSection += delta;
      if (_currentSection >= mmseSections.length) _showResults = true;
    });
    _fadeCtrl.forward();
  }

  int get _maxPossible => mmseSections.fold(
      0, (s, sec) => s + sec.questions.fold(0, (s2, q) => s2 + q.maxScore));

  @override
  Widget build(BuildContext context) {
    final scores = MmseScorer.calculateSectionScores(_answers);
    final total = MmseScorer.totalScore(scores);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MMSE Assessment'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (!_showResults)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentSection + 1} / ${mmseSections.length}',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: _showResults
            ? _ResultsView(
                scores: scores,
                total: total,
                maxPossible: _maxPossible,
                onRetake: () async {
                  await _fadeCtrl.reverse();
                  setState(() {
                    _currentSection = 0;
                    _showResults = false;
                    _resetAnswers();
                  });
                  _fadeCtrl.forward();
                },
              )
            : _SectionView(
                section: mmseSections[_currentSection],
                sectionIndex: _currentSection,
                totalSections: mmseSections.length,
                answers: _answers,
                stt: _stt,
                onChanged: (id, val) => setState(() => _answers[id] = val),
                onSttRebuild: () => setState(() {}),
                onNext: () => _go(1),
                onBack: _currentSection > 0 ? () => _go(-1) : null,
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SECTION VIEW
// ═══════════════════════════════════════════════════════════════════════════

class _SectionView extends StatelessWidget {
  final MmseSection section;
  final int sectionIndex;
  final int totalSections;
  final Map<String, dynamic> answers;
  final SttController stt;
  final void Function(String id, dynamic val) onChanged;
  final VoidCallback onSttRebuild;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const _SectionView({
    required this.section,
    required this.sectionIndex,
    required this.totalSections,
    required this.answers,
    required this.stt,
    required this.onChanged,
    required this.onSttRebuild,
    required this.onNext,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── progress bar ──────────────────────────────────────────────────
        LinearProgressIndicator(
          value: (sectionIndex + 1) / totalSections,
          backgroundColor: Colors.grey.shade200,
          color: AppColors.primary,
          minHeight: 4,
        ),

        // ── scrollable content ────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // section header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(section.icon,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(section.title,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text(section.description,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // question cards
                ...section.questions.map(_buildCard),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // ── navigation ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Row(
            children: [
              if (onBack != null) ...[
                OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: NeuraButton(
                  text: sectionIndex == totalSections - 1
                      ? 'View Results'
                      : 'Next Section',
                  onTap: onNext,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(MmseQuestion q) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.prompt,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.45)),
            if (q.subtitle != null) ...[
              const SizedBox(height: 5),
              Text(q.subtitle!,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500)),
            ],
            const SizedBox(height: 14),
            switch (q.type) {
              AnswerType.text => _TextWithMic(
                  questionId: q.id,
                  value: answers[q.id] as String? ?? '',
                  stt: stt,
                  onChanged: (v) => onChanged(q.id, v),
                  onRebuild: onSttRebuild,
                ),
              AnswerType.speechOnly => _SpeechOnly(
                  questionId: q.id,
                  transcript: answers[q.id] as String? ?? '',
                  stt: stt,
                  onTranscript: (v) => onChanged(q.id, v),
                  onRebuild: onSttRebuild,
                ),
              AnswerType.serial7 => _Serial7(
                  questionId: q.id,
                  values: answers[q.id] as List<String>? ??
                      List.filled(5, ''),
                  stt: stt,
                  onChanged: (v) => onChanged(q.id, v),
                  onRebuild: onSttRebuild,
                ),
              AnswerType.spellBackwards => _SpellBackwards(
                  values: answers[q.id] as List<String>? ??
                      List.filled(5, ''),
                  onChanged: (v) => onChanged(q.id, v),
                ),
            },
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  RESULTS VIEW
// ═══════════════════════════════════════════════════════════════════════════

class _ResultsView extends StatelessWidget {
  final Map<String, int> scores;
  final int total;
  final int maxPossible;
  final VoidCallback onRetake;

  const _ResultsView({
    required this.scores,
    required this.total,
    required this.maxPossible,
    required this.onRetake,
  });

  static const Map<String, int> _sectionMax = {
    'Orientation to Time': 6,
    'Orientation to Place': 5,
    'Registration': 3,
    'Attention & Calculation': 7,
    'Recall': 3,
    'Language': 6,
  };

  @override
  Widget build(BuildContext context) {
    final color = MmseScorer.interpretationColor(total);
    final label = MmseScorer.interpretation(total);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── big score card ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  '$total',
                  style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1),
                ),
                Text('out of $maxPossible',
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: color)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── severity legend ─────────────────────────────────────────────
          _SeverityLegend(),
          const SizedBox(height: 24),

          // ── section breakdown ───────────────────────────────────────────
          const Text('Score Breakdown',
              style:
                  TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...scores.entries.map((e) => _ScoreRow(
                label: e.key,
                score: e.value,
                max: _sectionMax[e.key] ?? 1,
              )),
          const SizedBox(height: 24),

          // ── disclaimer ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This result is a screening tool, not a medical '
                    'diagnosis. Please consult a qualified healthcare '
                    'professional for a full clinical evaluation.',
                    style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 13,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── actions ─────────────────────────────────────────────────────
          NeuraButton(
            text: 'Save & Continue',
            onTap: () => context.go('/assessment/voice-analysis'),
          ),
          const SizedBox(height: 12),
          NeuraButton(text: 'Retake Test', onTap: onRetake),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SeverityLegend extends StatelessWidget {
  static const _bands = [
    ('24–30', 'Normal', Color(0xFF34C759)),
    ('18–23', 'Mild', Color(0xFFFF9500)),
    ('12–17', 'Moderate', Color(0xFFFF6B35)),
    ('<12', 'Severe', Color(0xFFFF3B30)),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _bands.map((b) {
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: b.$3.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: b.$3.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: b.$3, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('${b.$1} — ${b.$2}',
                  style: TextStyle(
                      fontSize: 12,
                      color: b.$3,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;
  final int max;

  const _ScoreRow(
      {required this.label, required this.score, required this.max});

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? score / max : 0.0;
    final color = ratio >= 0.8
        ? const Color(0xFF34C759)
        : ratio >= 0.5
            ? const Color(0xFFFF9500)
            : const Color(0xFFFF3B30);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                Text('$score / $max',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.toDouble(),
                backgroundColor: Colors.grey.shade200,
                color: color,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
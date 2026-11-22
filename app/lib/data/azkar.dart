// GENERATED from tool/azkar_template.dart — Quranic texts are filled in from
// assets/quran (QuranEnc Uthmani text, Saheeh International, Maududi, Tanzil
// transliteration). Hadith duas follow Hisn al-Muslim with their references.

class Dhikr {
  final String key;
  final String arabic;
  final String en;
  final String ur;
  final int target;
  const Dhikr(this.key, this.arabic, this.en, this.ur, this.target);
}

/// Built-in counters on the Tasbeeh screen.
const List<Dhikr> tasbeehList = [
  Dhikr('subhanallah', 'سُبْحَانَ ٱللَّٰهِ', 'SubhanAllah', 'سبحان اللہ', 100),
  Dhikr('alhamdulillah', 'ٱلْحَمْدُ لِلَّٰهِ', 'Alhamdulillah', 'الحمد للہ', 100),
  Dhikr('allahuakbar', 'ٱللَّٰهُ أَكْبَرُ', 'Allahu Akbar', 'اللہ اکبر', 100),
  Dhikr('astaghfirullah', 'أَسْتَغْفِرُ ٱللَّٰهَ', 'Astaghfirullah', 'استغفر اللہ', 100),
  Dhikr('durood', 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ', 'Durood Shareef', 'درود شریف', 100),
  Dhikr('lailaha', 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ', 'La ilaha illallah', 'لا الہ الا اللہ', 100),
  Dhikr('kalima1', 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ مُحَمَّدٌ رَسُولُ ٱللَّٰهِ', 'First Kalima', 'پہلا کلمہ', 100),
  Dhikr(
    'kalima3',
    'سُبْحَانَ ٱللَّٰهِ وَٱلْحَمْدُ لِلَّٰهِ وَلَا إِلَٰهَ إِلَّا ٱللَّٰهُ وَٱللَّٰهُ أَكْبَرُ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّٰهِ ٱلْعَلِيِّ ٱلْعَظِيمِ',
    'Third Kalima',
    'تیسرا کلمہ',
    100,
  ),
];

/// Tasbeeh sessions: a dhikr key may carry a suffix so morning and evening
/// counts are kept separately (e.g. "durood@m", "durood@e").
const tasbeehSessions = ['', '@m', '@e'];

String dhikrBase(String key) => key.split('@').first;
String dhikrSession(String key) => key.contains('@') ? '@${key.split('@').last}' : '';

class Zikr {
  final String id;
  final String arabic;
  final String translit;
  final String en;
  final String ur;
  final int count;
  final String reference;
  final String titleEn;
  final String titleUr;
  /// Extra (optional) masnoon azkar: shown in their own section and not
  /// required to complete the set.
  final bool extra;
  const Zikr({
    required this.id,
    required this.arabic,
    required this.translit,
    required this.en,
    required this.ur,
    required this.count,
    required this.reference,
    this.titleEn = '',
    this.titleUr = '',
    this.extra = false,
  });
}

enum AzkarType { morning, evening, sleep, afterSalah, wakeUp, daily, protection, travel, salah, kalimas }

const Map<AzkarType, List<String>> azkarTypeNames = {
  AzkarType.morning: ['Morning Azkar', 'صبح کے اذکار'],
  AzkarType.evening: ['Evening Azkar', 'شام کے اذکار'],
  AzkarType.sleep: ['Sleep Azkar', 'سونے کے اذکار'],
  AzkarType.afterSalah: ['After Salah', 'نماز کے بعد'],
  AzkarType.wakeUp: ['Wake-up Dua', 'جاگنے کی دعا'],
  AzkarType.daily: ['Daily Duas', 'روزمرہ کی دعائیں'],
  AzkarType.protection: ['Protection Duas', 'حفاظت کی دعائیں'],
  AzkarType.travel: ['Travel Duas', 'سفر کی دعائیں'],
  AzkarType.salah: ['Namaz Azkar', 'نماز کے اذکار'],
  AzkarType.kalimas: ['Six Kalimas', 'چھ کلمے'],
};

const _kursi = Zikr(
  id: 'kursi',
  titleEn: 'Ayat-ul-Kursi',
  titleUr: 'آیت الکرسی',
  arabic: 'ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡحَيُّ ٱلۡقَيُّومُۚ لَا تَأۡخُذُهُۥ سِنَةٞ وَلَا نَوۡمٞۚ لَّهُۥ مَا فِي ٱلسَّمَٰوَٰتِ وَمَا فِي ٱلۡأَرۡضِۗ مَن ذَا ٱلَّذِي يَشۡفَعُ عِندَهُۥٓ إِلَّا بِإِذۡنِهِۦۚ يَعۡلَمُ مَا بَيۡنَ أَيۡدِيهِمۡ وَمَا خَلۡفَهُمۡۖ وَلَا يُحِيطُونَ بِشَيۡءٖ مِّنۡ عِلۡمِهِۦٓ إِلَّا بِمَا شَآءَۚ وَسِعَ كُرۡسِيُّهُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَۖ وَلَا يَـُٔودُهُۥ حِفۡظُهُمَاۚ وَهُوَ ٱلۡعَلِيُّ ٱلۡعَظِيمُ',
  translit: 'Allahu la ilaha illa huwa alhayyu alqayyoomu la takhuthuhu sinatun wala nawmun lahu ma fee alssamawati wama fee alardi man tha allathee yashfaAAu AAindahu illa biithnihi yaAAlamu ma bayna aydeehim wama khalfahum wala yuheetoona bishayin min AAilmihi illa bima shaa wasiAAa kursiyyuhu alssamawati waalarda wala yaooduhu hifthuhuma wahuwa alAAaliyyu alAAatheemu',
  en: 'Allah - there is no deity except Him, the Ever-Living, the Sustainer of [all] existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is [presently] before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great',
  ur: 'اللہ، وہ زندہ جاوید ہستی، جو تمام کائنات کو سنبھالے ہوئے ہے، اُس کے سوا کوئی خدا نہیں ہے وہ نہ سوتا ہے اور نہ اُسے اونگھ لگتی ہے زمین اور آسمانوں میں جو کچھ ہے، اُسی کا ہے کون ہے جو اُس کی جناب میں اُس کی اجازت کے بغیر سفارش کر سکے؟ جو کچھ بندوں کے سامنے ہے اسے بھی وہ جانتا ہے اور جو کچھ اُن سے اوجھل ہے، اس سے بھی وہ واقف ہے اور اُس کی معلومات میں سے کوئی چیز اُن کی گرفت ادراک میں نہیں آسکتی الّا یہ کہ کسی چیز کا علم وہ خود ہی اُن کو دینا چاہے اُس کی حکومت آسمانوں اور زمین پر چھائی ہوئی ہے اور اُن کی نگہبانی اس کے لیے کوئی تھکا دینے والا کام نہیں ہے بس وہی ایک بزرگ و برتر ذات ہے',
  count: 1,
  reference: 'Al-Baqarah 2:255',
);

const _ikhlas = Zikr(
  id: 'ikhlas',
  titleEn: 'Surah Al-Ikhlas',
  titleUr: 'سورۃ الاخلاص',
  arabic: 'قُلۡ هُوَ ٱللَّهُ أَحَدٌ ﴿١﴾ ٱللَّهُ ٱلصَّمَدُ ﴿٢﴾ لَمۡ يَلِدۡ وَلَمۡ يُولَدۡ ﴿٣﴾ وَلَمۡ يَكُن لَّهُۥ كُفُوًا أَحَدُۢ ﴿٤﴾',
  translit: '(1) Qul huwa Allahu ahadun (2) Allahu alssamadu (3) Lam yalid walam yooladu (4) Walam yakun lahu kufuwan ahadun',
  en: '(1) Say, "He is Allah, [who is] One (2) Allah, the Eternal Refuge (3) He neither begets nor is born (4) Nor is there to Him any equivalent',
  ur: '(1) کہو، وہ اللہ ہے، یکتا (2) اللہ سب سے بے نیاز ہے اور سب اس کے محتاج ہیں (3) نہ اس کی کوئی اولاد ہے اور نہ وہ کسی کی اولاد (4) اور کوئی اس کا ہمسر نہیں ہے',
  count: 3,
  reference: 'Abu Dawud 5082, Tirmidhi 3575',
);

const _falaq = Zikr(
  id: 'falaq',
  titleEn: 'Surah Al-Falaq',
  titleUr: 'سورۃ الفلق',
  arabic: 'قُلۡ أَعُوذُ بِرَبِّ ٱلۡفَلَقِ ﴿١﴾ مِن شَرِّ مَا خَلَقَ ﴿٢﴾ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ﴿٣﴾ وَمِن شَرِّ ٱلنَّفَّـٰثَٰتِ فِي ٱلۡعُقَدِ ﴿٤﴾ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ ﴿٥﴾',
  translit: '(1) Qul aAAoothu birabbi alfalaqi (2) Min sharri ma khalaqa (3) Wamin sharri ghasiqin itha waqaba (4) Wamin sharri alnnaffathati fee alAAuqadi (5) Wamin sharri hasidin itha hasada',
  en: '(1) Say, "I seek refuge in the Lord of daybreak (2) From the evil of that which He created (3) And from the evil of darkness when it settles (4) And from the evil of the blowers in knots (5) And from the evil of an envier when he envies',
  ur: '(1) کہو، میں پناہ مانگتا ہوں صبح کے رب کی (2) ہر اُس چیز کے شر سے جو اُس نے پیدا کی ہے (3) اور رات کی تاریکی کے شر سے جب کہ وہ چھا جائے (4) اور گرہوں میں پھونکنے والوں (یا والیوں) کے شر سے (5) اور حاسد کے شر سے جب کہ وہ حسد کرے',
  count: 3,
  reference: 'Abu Dawud 5082, Tirmidhi 3575',
);

const _nas = Zikr(
  id: 'nas',
  titleEn: 'Surah An-Nas',
  titleUr: 'سورۃ الناس',
  arabic: 'قُلۡ أَعُوذُ بِرَبِّ ٱلنَّاسِ ﴿١﴾ مَلِكِ ٱلنَّاسِ ﴿٢﴾ إِلَٰهِ ٱلنَّاسِ ﴿٣﴾ مِن شَرِّ ٱلۡوَسۡوَاسِ ٱلۡخَنَّاسِ ﴿٤﴾ ٱلَّذِي يُوَسۡوِسُ فِي صُدُورِ ٱلنَّاسِ ﴿٥﴾ مِنَ ٱلۡجِنَّةِ وَٱلنَّاسِ ﴿٦﴾',
  translit: '(1) Qul aAAoothu birabbi alnnasi (2) Maliki alnnasi (3) Ilahi alnnasi (4) Min sharri alwaswasi alkhannasi (5) Allathee yuwaswisu fee sudoori alnnasi (6) Mina aljinnati wa alnnasm',
  en: '(1) Say, "I seek refuge in the Lord of mankind (2) The Sovereign of mankind (3) The God of mankind (4) From the evil of the retreating whisperer (5) Who whispers [evil] into the breasts of mankind (6) From among the jinn and mankind',
  ur: '(1) کہو، میں پناہ مانگتا ہوں انسانوں کے رب (2) انسانوں کے بادشاہ (3) انسانوں کے حقیقی معبود کی (4) اُس وسوسہ ڈالنے والے کے شر سے جو بار بار پلٹ کر آتا ہے (5) جو لوگوں کے دلوں میں وسوسے ڈالتا ہے (6) خواہ وہ جنوں میں سے ہو یا انسانوں میں سے',
  count: 3,
  reference: 'Abu Dawud 5082, Tirmidhi 3575',
);

const _bismillahLaYadurru = Zikr(
  id: 'la_yadurru',
  arabic: 'بِسْمِ ٱللَّٰهِ ٱلَّذِي لَا يَضُرُّ مَعَ ٱسْمِهِ شَيْءٌ فِي ٱلْأَرْضِ وَلَا فِي ٱلسَّمَاءِ وَهُوَ ٱلسَّمِيعُ ٱلْعَلِيمُ',
  translit: "Bismillahil-ladhi la yadurru ma'as-mihi shay'un fil-ardi wa la fis-sama'i, wa huwas-Sami'ul-'Alim",
  en: 'In the name of Allah, with whose name nothing on earth or in heaven can cause harm, and He is the All-Hearing, All-Knowing.',
  ur: 'اللہ کے نام سے جس کے نام کے ساتھ زمین و آسمان میں کوئی چیز نقصان نہیں پہنچا سکتی، اور وہ سننے والا جاننے والا ہے۔',
  count: 3,
  reference: 'Abu Dawud 5088, Tirmidhi 3388',
);

const _subhanAllahWaBihamdihi = Zikr(
  id: 'subhan_bihamdihi',
  arabic: 'سُبْحَانَ ٱللَّٰهِ وَبِحَمْدِهِ',
  translit: 'SubhanAllahi wa bihamdihi',
  en: 'Glory be to Allah and praise be to Him.',
  ur: 'اللہ پاک ہے اور اسی کی تعریف ہے۔',
  count: 100,
  reference: 'Sahih Muslim 2692',
);

const _audhuKalimat = Zikr(
  id: 'audhu_kalimat',
  arabic: 'أَعُوذُ بِكَلِمَاتِ ٱللَّٰهِ ٱلتَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
  translit: "A'udhu bikalimatillahit-tammati min sharri ma khalaq",
  en: 'I seek refuge in the perfect words of Allah from the evil of what He has created.',
  ur: 'میں اللہ کے کامل کلمات کی پناہ مانگتا ہوں ہر اس چیز کے شر سے جو اس نے پیدا کی۔',
  count: 3,
  reference: 'Sahih Muslim 2709',
);

const _tahlil = Zikr(
  id: 'tahlil',
  arabic: 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ ٱلْمُلْكُ وَلَهُ ٱلْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
  translit: "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir",
  en: 'None has the right to be worshipped but Allah alone, without partner. To Him belongs the dominion and to Him belongs all praise, and He is over all things competent.',
  ur: 'اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے، اس کا کوئی شریک نہیں، اسی کی بادشاہی ہے اور اسی کے لیے تعریف ہے اور وہ ہر چیز پر قادر ہے۔',
  count: 1,
  reference: 'Sahih Muslim 597',
);

// ---- Added in 3.2 (equranlibrary.com azkaar chapters as checklist) ----
const _z_sayyid_istighfar = Zikr(
  id: 'sayyid_istighfar',
  titleEn: 'Sayyid-ul-Istighfar',
  titleUr: 'سید الاستغفار',
  arabic: 'اَللّٰهُمَّ أَنْتَ رَبِّي لَا إِلٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
  translit: "Allahumma anta Rabbi la ilaha illa anta, khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika mastata'tu, a'udhu bika min sharri ma sana'tu, abu'u laka bini'matika 'alayya, wa abu'u laka bidhanbi faghfir li, fa innahu la yaghfirudh-dhunuba illa anta",
  en: 'O Allah, You are my Lord, there is no god but You. You created me and I am Your servant. I keep Your covenant and promise as much as I can. I seek refuge in You from the evil of what I have done. I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for none forgives sins except You.',
  ur: 'اے اللہ! تو میرا رب ہے، تیرے سوا کوئی معبود نہیں۔ تو نے مجھے پیدا کیا اور میں تیرا بندہ ہوں، اور میں اپنی طاقت کے مطابق تیرے عہد اور وعدے پر قائم ہوں۔ میں اپنے کیے کے شر سے تیری پناہ چاہتا ہوں، مجھ پر تیری جو نعمتیں ہیں ان کا اقرار کرتا ہوں اور اپنے گناہ کا اعتراف کرتا ہوں، پس مجھے بخش دے کیونکہ تیرے سوا کوئی گناہ معاف نہیں کرتا۔',
  count: 1,
  reference: 'Bukhari 6306',
  extra: true,
);

const _z_bika_m = Zikr(
  id: 'bika_m',
  titleEn: "Allah's companionship",
  titleUr: 'اللہ تعالیٰ کی معیت',
  arabic: 'اَللّٰهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
  translit: 'Allahumma bika asbahna, wa bika amsayna, wa bika nahya, wa bika namutu, wa ilaykan-nushur',
  en: 'O Allah, by You we enter the morning and by You we enter the evening, by You we live and by You we die, and to You is the resurrection.',
  ur: 'اے اللہ! تیرے ہی حکم سے ہم نے صبح کی اور تیرے ہی حکم سے شام کی، تیرے ہی حکم سے ہم جیتے اور مرتے ہیں، اور تیری ہی طرف اٹھ کر جانا ہے۔',
  count: 1,
  reference: 'Tirmidhi 3391, Abu Dawud 5068',
  extra: true,
);

const _z_fitrah_m = Zikr(
  id: 'fitrah_m',
  titleEn: 'Upon the natural religion of Islam',
  titleUr: 'فطرتِ اسلام پر',
  arabic: 'أَصْبَحْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ ﷺ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا، وَمَا كَانَ مِنَ الْمُشْرِكِينَ',
  translit: "Asbahna 'ala fitratil-Islam, wa 'ala kalimatil-ikhlas, wa 'ala dini nabiyyina Muhammadin, wa 'ala millati abina Ibrahima hanifan musliman, wa ma kana minal-mushrikin",
  en: 'We have entered the morning upon the natural religion of Islam, the word of sincerity, the religion of our Prophet Muhammad ﷺ and the way of our father Ibrahim, who was upright, a Muslim, and not one of the polytheists.',
  ur: 'ہم نے فطرتِ اسلام پر، کلمۂ اخلاص پر، اپنے نبی محمد ﷺ کے دین پر اور اپنے باپ ابراہیم کی ملت پر صبح کی جو یکسو مسلمان تھے اور مشرکوں میں سے نہ تھے۔',
  count: 1,
  reference: "Musnad Ahmad; Nasa'i (Amal al-Yawm)",
  extra: true,
);

const _z_afini_badani = Zikr(
  id: 'afini_badani',
  titleEn: 'Well-being of body',
  titleUr: 'بدن کی عافیت',
  arabic: 'اَللّٰهُمَّ عَافِنِي فِي بَدَنِي، اَللّٰهُمَّ عَافِنِي فِي سَمْعِي، اَللّٰهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلٰهَ إِلَّا أَنْتَ. اَللّٰهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلٰهَ إِلَّا أَنْتَ',
  translit: "Allahumma 'afini fi badani, Allahumma 'afini fi sam'i, Allahumma 'afini fi basari, la ilaha illa anta. Allahumma inni a'udhu bika minal-kufri wal-faqr, wa a'udhu bika min 'adhabil-qabr, la ilaha illa anta",
  en: 'O Allah, grant me well-being in my body, in my hearing and in my sight; there is no god but You. O Allah, I seek refuge in You from disbelief and poverty, and from the punishment of the grave; there is no god but You.',
  ur: 'اے اللہ! مجھے میرے بدن، میری سماعت اور میری بصارت میں عافیت دے، تیرے سوا کوئی معبود نہیں۔ اے اللہ! میں کفر اور فقر سے اور قبر کے عذاب سے تیری پناہ مانگتا ہوں، تیرے سوا کوئی معبود نہیں۔',
  count: 3,
  reference: 'Abu Dawud 5090',
  extra: true,
);

const _z_ya_hayyu = Zikr(
  id: 'ya_hayyu',
  titleEn: 'Setting all affairs right',
  titleUr: 'تمام کاموں کی اصلاح',
  arabic: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
  translit: "Ya Hayyu ya Qayyum, birahmatika astaghith, aslih li sha'ni kullahu, wa la takilni ila nafsi tarfata 'ayn",
  en: 'O Ever-Living, O Sustainer of all, by Your mercy I seek help: set right all my affairs and do not leave me to myself even for the blink of an eye.',
  ur: 'اے ہمیشہ زندہ، اے سب کو قائم رکھنے والے! تیری رحمت کے وسیلے سے فریاد کرتا ہوں، میرے سب کام درست فرما دے اور مجھے پلک جھپکنے کے برابر بھی میرے نفس کے حوالے نہ کر۔',
  count: 1,
  reference: "Mustadrak Hakim 2000, Nasa'i (Amal al-Yawm)",
  extra: true,
);

const _z_afw_afiyah = Zikr(
  id: 'afw_afiyah',
  titleEn: 'Pardon and well-being',
  titleUr: 'معافی اور عافیت',
  arabic: 'اَللّٰهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اَللّٰهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اَللّٰهُمَّ اسْتُرْ عَوْرَاتِي، وَآمِنْ رَوْعَاتِي، اَللّٰهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ، وَمِنْ خَلْفِي، وَعَنْ يَمِينِي، وَعَنْ شِمَالِي، وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي',
  translit: "Allahumma inni as'alukal-'afwa wal-'afiyata fid-dunya wal-akhirah. Allahumma inni as'alukal-'afwa wal-'afiyata fi dini wa dunyaya wa ahli wa mali. Allahummastur 'awrati wa amin raw'ati. Allahummahfazni min bayni yadayya wa min khalfi wa 'an yamini wa 'an shimali wa min fawqi, wa a'udhu bi'azamatika an ughtala min tahti",
  en: 'O Allah, I ask You for pardon and well-being in this world and the Hereafter. O Allah, I ask You for pardon and well-being in my religion, my worldly life, my family and my wealth. O Allah, cover my faults and calm my fears. O Allah, guard me from in front of me, behind me, on my right, on my left and above me, and I seek refuge in Your greatness from being taken unawares from beneath me.',
  ur: 'اے اللہ! میں تجھ سے دنیا اور آخرت میں معافی اور عافیت مانگتا ہوں۔ اے اللہ! میں تجھ سے اپنے دین، اپنی دنیا، اپنے گھر والوں اور اپنے مال میں معافی اور عافیت مانگتا ہوں۔ اے اللہ! میرے عیبوں پر پردہ ڈال دے اور میرے خوف کو امن میں بدل دے۔ اے اللہ! میرے آگے سے، پیچھے سے، دائیں سے، بائیں سے اور اوپر سے میری حفاظت فرما، اور میں تیری عظمت کی پناہ چاہتا ہوں اس سے کہ نیچے سے اچانک ہلاک کیا جاؤں۔',
  count: 1,
  reference: 'Abu Dawud 5074, Ibn Majah 3871',
  extra: true,
);

const _z_alim_al_ghayb = Zikr(
  id: 'alim_al_ghayb',
  titleEn: 'Refuge from the evil of the self and Satan',
  titleUr: 'نفس اور شیطان کے شر سے پناہ',
  arabic: 'اَللّٰهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ، فَاطِرَ السَّمٰوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ الشَّيْطَانِ وَشِرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءًا أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ',
  translit: "Allahumma 'Alimal-ghaybi wash-shahadah, Fatiras-samawati wal-ard, Rabba kulli shay'in wa malikah, ashhadu an la ilaha illa anta, a'udhu bika min sharri nafsi, wa min sharrish-shaytani wa shirkih, wa an aqtarifa 'ala nafsi su'an aw ajurrahu ila muslim",
  en: 'O Allah, Knower of the unseen and the seen, Creator of the heavens and the earth, Lord and Owner of everything: I bear witness that there is no god but You. I seek refuge in You from the evil of my soul, from the evil of Satan and his call to shirk, and from doing wrong against myself or bringing it upon a Muslim.',
  ur: 'اے اللہ! غائب اور حاضر کے جاننے والے، آسمانوں اور زمین کے پیدا کرنے والے، ہر چیز کے رب اور مالک! میں گواہی دیتا ہوں کہ تیرے سوا کوئی معبود نہیں۔ میں اپنے نفس کے شر سے، شیطان کے شر اور اس کے شرک سے تیری پناہ مانگتا ہوں، اور اس سے کہ اپنی جان پر کوئی برائی کروں یا کسی مسلمان کی طرف اسے لے جاؤں۔',
  count: 1,
  reference: 'Abu Dawud 5067, Tirmidhi 3392',
  extra: true,
);

const _z_hasbiyallah_7 = Zikr(
  id: 'hasbiyallah_7',
  titleEn: 'Allah is sufficient for me',
  titleUr: 'مجھے اللہ کافی ہے',
  arabic: 'حَسْبِيَ اللّٰهُ لَا إِلٰهَ إِلَّا هُوَ، عَلَيْهِ تَوَكَّلْتُ، وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
  translit: "Hasbiyallahu la ilaha illa huwa, 'alayhi tawakkaltu, wa huwa Rabbul-'Arshil-'Azim",
  en: 'Allah is sufficient for me; there is no god but He. In Him I put my trust, and He is the Lord of the Mighty Throne.',
  ur: 'مجھے اللہ کافی ہے، اس کے سوا کوئی معبود نہیں، اسی پر میں نے بھروسہ کیا اور وہی عرشِ عظیم کا رب ہے۔',
  count: 7,
  reference: 'Abu Dawud 5081',
  extra: true,
);

const _z_ma_bi_nimah_m = Zikr(
  id: 'ma_bi_nimah_m',
  titleEn: 'Gratitude for blessings',
  titleUr: 'نعمتوں پر شکر',
  arabic: 'اَللّٰهُمَّ مَا أَصْبَحَ بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ',
  translit: "Allahumma ma asbaha bi min ni'matin aw bi-ahadin min khalqika faminka wahdaka la sharika lak, falakal-hamdu wa lakash-shukr",
  en: 'O Allah, whatever blessing I or any of Your creation have this morning is from You alone, without partner; so to You is all praise and all thanks.',
  ur: 'اے اللہ! صبح کے وقت مجھ پر یا تیری مخلوق میں سے کسی پر جو بھی نعمت ہے وہ صرف تیری طرف سے ہے، تیرا کوئی شریک نہیں، پس تیرے ہی لیے تعریف ہے اور تیرا ہی شکر ہے۔',
  count: 1,
  reference: 'Abu Dawud 5073',
  extra: true,
);

const _z_tahlil_10 = Zikr(
  id: 'tahlil_10',
  titleEn: 'Tahlil (10 times)',
  titleUr: 'تہلیل (10 مرتبہ)',
  arabic: 'لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
  translit: "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa huwa 'ala kulli shay'in qadir",
  en: 'There is no god but Allah, alone without partner. His is the dominion and His is the praise, and He has power over all things.',
  ur: 'اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے اس کا کوئی شریک نہیں، اسی کی بادشاہی ہے اور اسی کے لیے تعریف ہے، اور وہ ہر چیز پر قادر ہے۔',
  count: 10,
  reference: 'Musnad Ahmad 23568',
  extra: true,
);

const _z_ajirni_nar = Zikr(
  id: 'ajirni_nar',
  titleEn: 'Protection from the Fire (after Fajr and Maghrib)',
  titleUr: 'جہنم سے پناہ (فجر اور مغرب کے بعد)',
  arabic: 'اَللّٰهُمَّ أَجِرْنِي مِنَ النَّارِ',
  translit: 'Allahumma ajirni minan-nar',
  en: 'O Allah, protect me from the Fire.',
  ur: 'اے اللہ! مجھے جہنم کی آگ سے بچا لے۔',
  count: 7,
  reference: 'Abu Dawud 5079',
  extra: true,
);

const _z_ilman_nafia = Zikr(
  id: 'ilman_nafia',
  titleEn: 'Beneficial knowledge (after Fajr)',
  titleUr: 'نفع بخش علم (فجر کے بعد)',
  arabic: 'اَللّٰهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا',
  translit: "Allahumma inni as'aluka 'ilman nafi'an, wa rizqan tayyiban, wa 'amalan mutaqabbala",
  en: 'O Allah, I ask You for beneficial knowledge, good provision and accepted deeds.',
  ur: 'اے اللہ! میں تجھ سے نفع دینے والا علم، پاکیزہ رزق اور قبول ہونے والا عمل مانگتا ہوں۔',
  count: 1,
  reference: 'Ibn Majah 925',
  extra: true,
);

const _z_adada_khalqihi = Zikr(
  id: 'adada_khalqihi',
  titleEn: 'Words heavy on the scale',
  titleUr: 'میزان میں بھاری کلمات',
  arabic: 'سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ',
  translit: "Subhanallahi wa bihamdihi, 'adada khalqihi, wa rida nafsihi, wa zinata 'arshihi, wa midada kalimatih",
  en: 'Glory and praise be to Allah, as many times as the number of His creation, as much as pleases Him, as heavy as His Throne and as much as the ink of His words.',
  ur: 'اللہ پاک ہے اور اپنی تعریف کے ساتھ، اپنی مخلوق کی تعداد کے برابر، اپنی رضا کے مطابق، اپنے عرش کے وزن کے برابر اور اپنے کلمات کی سیاہی کے برابر۔',
  count: 3,
  reference: 'Muslim 2726',
  extra: true,
);

const _z_hashr_last = Zikr(
  id: 'hashr_last',
  titleEn: 'Refuge + last 3 ayat of Surah Al-Hashr',
  titleUr: 'تعوذ اور سورۃ الحشر کی آخری تین آیات',
  arabic: 'أَعُوذُ بِاللّٰهِ السَّمِيعِ الْعَلِيمِ مِنَ الشَّيْطَانِ الرَّجِيمِ (٣)\nهُوَ ٱللَّهُ ٱلَّذِي لَآ إِلَٰهَ إِلَّا هُوَۖ عَٰلِمُ ٱلۡغَيۡبِ وَٱلشَّهَٰدَةِۖ هُوَ ٱلرَّحۡمَٰنُ ٱلرَّحِيمُ ﴿٢٢﴾ هُوَ ٱللَّهُ ٱلَّذِي لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡمَلِكُ ٱلۡقُدُّوسُ ٱلسَّلَٰمُ ٱلۡمُؤۡمِنُ ٱلۡمُهَيۡمِنُ ٱلۡعَزِيزُ ٱلۡجَبَّارُ ٱلۡمُتَكَبِّرُۚ سُبۡحَٰنَ ٱللَّهِ عَمَّا يُشۡرِكُونَ ﴿٢٣﴾ هُوَ ٱللَّهُ ٱلۡخَٰلِقُ ٱلۡبَارِئُ ٱلۡمُصَوِّرُۖ لَهُ ٱلۡأَسۡمَآءُ ٱلۡحُسۡنَىٰۚ يُسَبِّحُ لَهُۥ مَا فِي ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِۖ وَهُوَ ٱلۡعَزِيزُ ٱلۡحَكِيمُ ﴿٢٤﴾',
  translit: "A'udhu billahis-Sami'il-'Alimi minash-shaytanir-rajim (3 times), then: (22) Huwa Allahu allathee la ilaha illa huwa AAalimu alghaybi waalshshahadati huwa alrrahmanu alrraheemu (23) Huwa Allahu allathee la ilaha illa huwa almaliku alquddoosu alssalamu almuminu almuhayminu alAAazeezu aljabbaru almutakabbiru subhana Allahi AAamma yushrikoona (24) Huwa Allahu alkhaliqu albario almusawwiru lahu alasmao alhusna yusabbihu lahu ma fee alssamawati waalardi wahuwa alAAazeezu alhakeemu",
  en: 'I seek refuge in Allah, the All-Hearing, the All-Knowing, from Satan the accursed (3 times). Then: (22) He is Allah, other than whom there is no deity, Knower of the unseen and the witnessed. He is the Entirely Merciful, the Especially Merciful (23) He is Allah, other than whom there is no deity, the Sovereign, the Pure, the Perfection, the Bestower of Faith, the Overseer, the Exalted in Might, the Compeller, the Superior. Exalted is Allah above whatever they associate with Him (24) He is Allah, the Creator, the Inventor, the Fashioner; to Him belong the best names. Whatever is in the heavens and earth is exalting Him. And He is the Exalted in Might, the Wise',
  ur: 'میں شیطان مردود سے اللہ سننے والے، جاننے والے کی پناہ مانگتا ہوں (3 مرتبہ)، پھر: (22) وہ اللہ ہی ہے جس کے سوا کوئی معبود نہیں، غائب اور ظاہر ہر چیز کا جاننے والا، وہی رحمٰن اور رحیم ہے (23) وہ اللہ ہی ہے جس کے سوا کوئی معبود نہیں وہ بادشاہ ہے نہایت مقدس، سراسر سلامتی، امن دینے والا، نگہبان، سب پر غالب، اپنا حکم بزور نافذ کرنے والا، اور بڑا ہی ہو کر رہنے والا پاک ہے اللہ اُس شرک سے جو لوگ کر رہے ہیں (24) وہ اللہ ہی ہے جو تخلیق کا منصوبہ بنانے والا اور اس کو نافذ کرنے والا اور اس کے مطابق صورت گری کرنے والا ہے اس کے لیے بہترین نام ہیں ہر چیز جو آسمانوں اور زمین میں ہے اُس کی تسبیح کر رہی ہے، اور وہ زبردست اور حکیم ہے',
  count: 1,
  reference: 'Tirmidhi 2922; Al-Hashr 59:22-24',
  extra: true,
);

const _z_rum_17_19 = Zikr(
  id: 'rum_17_19',
  titleEn: 'Surah Ar-Rum 17–19',
  titleUr: 'سورۃ الروم آیات 17–19',
  arabic: 'فَسُبۡحَٰنَ ٱللَّهِ حِينَ تُمۡسُونَ وَحِينَ تُصۡبِحُونَ ﴿١٧﴾ وَلَهُ ٱلۡحَمۡدُ فِي ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِ وَعَشِيّٗا وَحِينَ تُظۡهِرُونَ ﴿١٨﴾ يُخۡرِجُ ٱلۡحَيَّ مِنَ ٱلۡمَيِّتِ وَيُخۡرِجُ ٱلۡمَيِّتَ مِنَ ٱلۡحَيِّ وَيُحۡيِ ٱلۡأَرۡضَ بَعۡدَ مَوۡتِهَاۚ وَكَذَٰلِكَ تُخۡرَجُونَ ﴿١٩﴾',
  translit: '(17) Fasubhana Allahi heena tumsoona waheena tusbihoona (18) Walahu alhamdu fee alssamawati waalardi waAAashiyyan waheena tuthhiroona (19) Yukhriju alhayya mina almayyiti wayukhriju almayyita mina alhayyi wayuhyee alarda baAAda mawtiha wakathalika tukhrajoona',
  en: '(17) So exalted is Allah when you reach the evening and when you reach the morning (18) And to Him is [due all] praise throughout the heavens and the earth. And [exalted is He] at night and when you are at noon (19) He brings the living out of the dead and brings the dead out of the living and brings to life the earth after its lifelessness. And thus will you be brought out',
  ur: '(17) پس تسبیح کرو اللہ کی جبکہ تم شام کرتے ہو اور جب صبح کرتے ہو (18) آسمانوں اور زمین میں اُسی کے لیے حمد ہے اور (تسبیح کرو اس کی) تیسرے پہر اور جبکہ تم پر ظہر کا وقت آتا ہے (19) وہ زندہ میں سے مُردے کو نکالتا ہے اور مُردے میں سے زندہ کو نکالتا ہے اور زمین کو اس کی موت کے بعد زندگی بخشتا ہے اسی طرح تم لوگ بھی (حالت موت سے) نکال لیے جاؤ گے',
  count: 1,
  reference: 'Abu Dawud 5076; Ar-Rum 30:17-19',
  extra: true,
);

const _z_bika_e = Zikr(
  id: 'bika_e',
  titleEn: "Allah's companionship",
  titleUr: 'اللہ تعالیٰ کی معیت',
  arabic: 'اَللّٰهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
  translit: 'Allahumma bika amsayna, wa bika asbahna, wa bika nahya, wa bika namutu, wa ilaykal-masir',
  en: 'O Allah, by You we enter the evening and by You we enter the morning, by You we live and by You we die, and to You is the final return.',
  ur: 'اے اللہ! تیرے ہی حکم سے ہم نے شام کی اور تیرے ہی حکم سے صبح کی، تیرے ہی حکم سے ہم جیتے اور مرتے ہیں، اور تیری ہی طرف لوٹ کر جانا ہے۔',
  count: 1,
  reference: 'Tirmidhi 3391, Abu Dawud 5068',
  extra: true,
);

const _z_fitrah_e = Zikr(
  id: 'fitrah_e',
  titleEn: 'Upon the natural religion of Islam',
  titleUr: 'فطرتِ اسلام پر',
  arabic: 'أَمْسَيْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ ﷺ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا، وَمَا كَانَ مِنَ الْمُشْرِكِينَ',
  translit: "Amsayna 'ala fitratil-Islam, wa 'ala kalimatil-ikhlas, wa 'ala dini nabiyyina Muhammadin, wa 'ala millati abina Ibrahima hanifan musliman, wa ma kana minal-mushrikin",
  en: 'We have entered the evening upon the natural religion of Islam, the word of sincerity, the religion of our Prophet Muhammad ﷺ and the way of our father Ibrahim, who was upright, a Muslim, and not one of the polytheists.',
  ur: 'ہم نے فطرتِ اسلام پر، کلمۂ اخلاص پر، اپنے نبی محمد ﷺ کے دین پر اور اپنے باپ ابراہیم کی ملت پر شام کی جو یکسو مسلمان تھے اور مشرکوں میں سے نہ تھے۔',
  count: 1,
  reference: "Musnad Ahmad; Nasa'i (Amal al-Yawm)",
  extra: true,
);

const _z_ma_bi_nimah_e = Zikr(
  id: 'ma_bi_nimah_e',
  titleEn: 'Gratitude for blessings',
  titleUr: 'نعمتوں پر شکر',
  arabic: 'اَللّٰهُمَّ مَا أَمْسَى بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ',
  translit: "Allahumma ma amsa bi min ni'matin aw bi-ahadin min khalqika faminka wahdaka la sharika lak, falakal-hamdu wa lakash-shukr",
  en: 'O Allah, whatever blessing I or any of Your creation have this evening is from You alone, without partner; so to You is all praise and all thanks.',
  ur: 'اے اللہ! شام کے وقت مجھ پر یا تیری مخلوق میں سے کسی پر جو بھی نعمت ہے وہ صرف تیری طرف سے ہے، تیرا کوئی شریک نہیں، پس تیرے ہی لیے تعریف ہے اور تیرا ہی شکر ہے۔',
  count: 1,
  reference: 'Abu Dawud 5073',
  extra: true,
);

const _z_bismika_rabbi = Zikr(
  id: 'bismika_rabbi',
  titleEn: 'Lying down on the bed',
  titleUr: 'بستر پر لیٹتے وقت',
  arabic: 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ',
  translit: "Bismika Rabbi wada'tu janbi, wa bika arfa'uh, fa in amsakta nafsi farhamha, wa in arsaltaha fahfazha bima tahfazu bihi 'ibadakas-salihin",
  en: 'In Your name, my Lord, I lay down my side and by You I raise it. If You take my soul, have mercy on it, and if You send it back, protect it as You protect Your righteous servants.',
  ur: 'اے میرے رب! تیرے نام سے میں نے اپنا پہلو رکھا اور تیرے ہی نام سے اسے اٹھاؤں گا۔ اگر تو میری جان روک لے تو اس پر رحم فرما، اور اگر اسے چھوڑ دے تو اس کی ویسی ہی حفاظت فرما جیسی اپنے نیک بندوں کی حفاظت فرماتا ہے۔',
  count: 1,
  reference: 'Bukhari 6320',
  extra: true,
);

const _z_qini_adhabak = Zikr(
  id: 'qini_adhabak',
  titleEn: 'Protection from punishment',
  titleUr: 'عذاب سے پناہ',
  arabic: 'اَللّٰهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ',
  translit: "Allahumma qini 'adhabaka yawma tab'athu 'ibadak",
  en: 'O Allah, protect me from Your punishment on the Day You resurrect Your servants.',
  ur: 'اے اللہ! جس دن تو اپنے بندوں کو اٹھائے گا اس دن مجھے اپنے عذاب سے بچا لینا۔',
  count: 3,
  reference: 'Abu Dawud 5045, Tirmidhi 3398',
  extra: true,
);

const _z_aslamtu_nafsi = Zikr(
  id: 'aslamtu_nafsi',
  titleEn: 'Sleeping upon the fitrah',
  titleUr: 'فطرت پر سونا',
  arabic: 'اَللّٰهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ',
  translit: "Allahumma aslamtu nafsi ilayk, wa fawwadtu amri ilayk, wa wajjahtu wajhi ilayk, wa alja'tu zahri ilayk, raghbatan wa rahbatan ilayk, la malja'a wa la manja minka illa ilayk, amantu bikitabikal-ladhi anzalt, wa binabiyyikal-ladhi arsalt",
  en: 'O Allah, I submit myself to You, entrust my affairs to You, turn my face to You and rely on You, out of hope and fear of You. There is no refuge and no escape from You except to You. I believe in Your Book which You revealed and in Your Prophet whom You sent.',
  ur: 'اے اللہ! میں نے اپنی جان تیرے سپرد کی، اپنا معاملہ تیرے حوالے کیا، اپنا چہرہ تیری طرف کیا اور اپنی پشت تیرے سہارے پر ٹکا دی، تیری رغبت اور تیرے خوف کے ساتھ۔ تجھ سے بچ کر کوئی پناہ گاہ اور جائے نجات نہیں مگر تیری ہی طرف۔ میں تیری اس کتاب پر ایمان لایا جو تو نے نازل کی اور تیرے اس نبی پر جسے تو نے بھیجا۔',
  count: 1,
  reference: 'Bukhari 6311, Muslim 2710',
  extra: true,
);

const _z_atamana = Zikr(
  id: 'atamana',
  titleEn: 'Thanks for food and shelter',
  titleUr: 'کھانے اور ٹھکانے پر شکر',
  arabic: 'اَلْحَمْدُ لِلّٰهِ الَّذِي أَطْعَمَنَا وَسَقَانَا، وَكَفَانَا وَآوَانَا، فَكَمْ مِمَّنْ لَا كَافِيَ لَهُ وَلَا مُؤْوِيَ',
  translit: "Alhamdu lillahil-ladhi at'amana wa saqana, wa kafana wa awana, fakam mimman la kafiya lahu wa la mu'wi",
  en: 'All praise is for Allah who fed us, gave us drink, sufficed us and gave us shelter; for how many have no one to suffice them or shelter them.',
  ur: 'تمام تعریفیں اللہ کے لیے ہیں جس نے ہمیں کھلایا، پلایا، ہماری کفایت کی اور ہمیں ٹھکانا دیا، کتنے ہی لوگ ہیں جن کا نہ کوئی کفایت کرنے والا ہے نہ ٹھکانا دینے والا۔',
  count: 1,
  reference: 'Muslim 2715',
  extra: true,
);

const _z_khalaqta_nafsi = Zikr(
  id: 'khalaqta_nafsi',
  titleEn: 'Asking for well-being',
  titleUr: 'عافیت کا سوال',
  arabic: 'اَللّٰهُمَّ خَلَقْتَ نَفْسِي وَأَنْتَ تَوَفَّاهَا، لَكَ مَمَاتُهَا وَمَحْيَاهَا، إِنْ أَحْيَيْتَهَا فَاحْفَظْهَا، وَإِنْ أَمَتَّهَا فَاغْفِرْ لَهَا، اَللّٰهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ',
  translit: "Allahumma khalaqta nafsi wa anta tawaffaha, laka mamatuha wa mahyaha, in ahyaytaha fahfazha, wa in amattaha faghfir laha. Allahumma inni as'alukal-'afiyah",
  en: 'O Allah, You created my soul and You take it; its death and its life belong to You. If You keep it alive, protect it, and if You cause it to die, forgive it. O Allah, I ask You for well-being.',
  ur: 'اے اللہ! تو نے میری جان پیدا کی اور تو ہی اسے وفات دے گا، اس کی موت اور زندگی تیرے ہی لیے ہے۔ اگر تو اسے زندہ رکھے تو اس کی حفاظت فرما اور اگر اسے موت دے تو اسے بخش دے۔ اے اللہ! میں تجھ سے عافیت مانگتا ہوں۔',
  count: 1,
  reference: 'Muslim 2712',
  extra: true,
);

const _z_astaghfir_sleep = Zikr(
  id: 'astaghfir_sleep',
  titleEn: 'Forgiveness of all sins',
  titleUr: 'تمام گناہوں کی معافی',
  arabic: 'أَسْتَغْفِرُ اللّٰهَ الَّذِي لَا إِلٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ',
  translit: 'Astaghfirullahal-ladhi la ilaha illa huwal-Hayyul-Qayyumu wa atubu ilayh',
  en: 'I seek forgiveness from Allah, there is no god but He, the Ever-Living, the Sustainer, and I repent to Him.',
  ur: 'میں اللہ سے بخشش مانگتا ہوں جس کے سوا کوئی معبود نہیں، وہ ہمیشہ زندہ اور سب کو قائم رکھنے والا ہے، اور میں اسی کی طرف توبہ کرتا ہوں۔',
  count: 3,
  reference: 'Tirmidhi 3397',
  extra: true,
);

const _z_before_wudu = Zikr(
  id: 'before_wudu',
  titleEn: 'Before wudu',
  titleUr: 'وضو سے پہلے',
  arabic: 'بِسْمِ اللّٰهِ',
  translit: 'Bismillah',
  en: 'In the name of Allah.',
  ur: 'اللہ کے نام سے۔',
  count: 1,
  reference: 'Abu Dawud 101, Tirmidhi 25',
);

const _z_after_wudu = Zikr(
  id: 'after_wudu',
  titleEn: 'After wudu',
  titleUr: 'وضو کے بعد',
  arabic: 'أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ، اَللّٰهُمَّ اجْعَلْنِي مِنَ التَّوَّابِينَ، وَاجْعَلْنِي مِنَ الْمُتَطَهِّرِينَ',
  translit: "Ashhadu an la ilaha illallahu wahdahu la sharika lah, wa ashhadu anna Muhammadan 'abduhu wa rasuluh. Allahummaj'alni minat-tawwabin, waj'alni minal-mutatahhirin",
  en: 'I bear witness that there is no god but Allah, alone without partner, and I bear witness that Muhammad is His servant and Messenger. O Allah, make me among those who repent and make me among those who purify themselves.',
  ur: 'میں گواہی دیتا ہوں کہ اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے اس کا کوئی شریک نہیں، اور میں گواہی دیتا ہوں کہ محمد ﷺ اس کے بندے اور رسول ہیں۔ اے اللہ! مجھے توبہ کرنے والوں میں شامل فرما اور پاکیزگی اختیار کرنے والوں میں شامل فرما۔',
  count: 1,
  reference: 'Muslim 234, Tirmidhi 55',
);

const _z_after_adhan = Zikr(
  id: 'after_adhan',
  titleEn: 'After the adhan',
  titleUr: 'اذان کے بعد',
  arabic: 'اَللّٰهُمَّ رَبَّ هٰذِهِ الدَّعْوَةِ التَّامَّةِ، وَالصَّلَاةِ الْقَائِمَةِ، آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ، وَابْعَثْهُ مَقَامًا مَحْمُودًا الَّذِي وَعَدْتَهُ',
  translit: "Allahumma Rabba hadhihid-da'watit-tammah, was-salatil-qa'imah, ati Muhammadanil-wasilata wal-fadilah, wab'athhu maqaman mahmudanil-ladhi wa'adtah",
  en: 'O Allah, Lord of this perfect call and of the prayer about to be established, grant Muhammad al-Wasilah and excellence, and raise him to the praised station that You promised him.',
  ur: 'اے اللہ! اس کامل دعوت اور قائم ہونے والی نماز کے رب! محمد ﷺ کو وسیلہ اور فضیلت عطا فرما اور انہیں اس مقامِ محمود پر فائز فرما جس کا تو نے ان سے وعدہ کیا ہے۔',
  count: 1,
  reference: 'Bukhari 614',
);

const _z_enter_home = Zikr(
  id: 'enter_home',
  titleEn: 'Entering the home',
  titleUr: 'گھر میں داخل ہوتے وقت',
  arabic: 'بِسْمِ اللّٰهِ وَلَجْنَا، وَبِسْمِ اللّٰهِ خَرَجْنَا، وَعَلَى اللّٰهِ رَبِّنَا تَوَكَّلْنَا',
  translit: "Bismillahi walajna, wa bismillahi kharajna, wa 'alallahi Rabbina tawakkalna",
  en: 'In the name of Allah we enter, in the name of Allah we leave, and upon Allah our Lord we rely. (Then greet your family with salam.)',
  ur: 'اللہ کے نام سے ہم داخل ہوئے، اللہ کے نام سے نکلے اور اپنے رب اللہ پر ہم نے بھروسہ کیا۔ (پھر گھر والوں کو سلام کریں)',
  count: 1,
  reference: 'Abu Dawud 5096',
);

const _z_iftar = Zikr(
  id: 'iftar',
  titleEn: 'At iftar',
  titleUr: 'افطار کے وقت',
  arabic: 'ذَهَبَ الظَّمَأُ، وَابْتَلَّتِ الْعُرُوقُ، وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللّٰهُ',
  translit: "Dhahabaz-zama'u wabtallatil-'uruq, wa thabatal-ajru in sha' Allah",
  en: 'The thirst is gone, the veins are moistened, and the reward is confirmed, if Allah wills.',
  ur: 'پیاس بجھ گئی، رگیں تر ہو گئیں اور ان شاء اللہ اجر ثابت ہو گیا۔',
  count: 1,
  reference: 'Abu Dawud 2357',
);

const _z_iftar_laka_sumtu = Zikr(
  id: 'iftar_laka_sumtu',
  titleEn: 'At iftar (2)',
  titleUr: 'افطار کے وقت (2)',
  arabic: 'اَللّٰهُمَّ لَكَ صُمْتُ وَعَلَى رِزْقِكَ أَفْطَرْتُ',
  translit: "Allahumma laka sumtu wa 'ala rizqika aftartu",
  en: 'O Allah, for You I fasted and with Your provision I break my fast.',
  ur: 'اے اللہ! میں نے تیرے لیے روزہ رکھا اور تیرے ہی رزق سے افطار کیا۔',
  count: 1,
  reference: 'Abu Dawud 2358 (mursal)',
);

const _z_fed_by_other = Zikr(
  id: 'fed_by_other',
  titleEn: 'When someone feeds you',
  titleUr: 'جب کوئی کھانا کھلائے',
  arabic: 'اَللّٰهُمَّ أَطْعِمْ مَنْ أَطْعَمَنِي، وَاسْقِ مَنْ سَقَانِي',
  translit: "Allahumma at'im man at'amani, wasqi man saqani",
  en: 'O Allah, feed the one who fed me and give drink to the one who gave me drink.',
  ur: 'اے اللہ! جس نے مجھے کھلایا اسے کھلا اور جس نے مجھے پلایا اسے پلا۔',
  count: 1,
  reference: 'Muslim 2055',
);

const _z_wearing_clothes = Zikr(
  id: 'wearing_clothes',
  titleEn: 'Putting on clothes',
  titleUr: 'کپڑے پہنتے وقت',
  arabic: 'اَلْحَمْدُ لِلّٰهِ الَّذِي كَسَانِي هٰذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
  translit: 'Alhamdu lillahil-ladhi kasani hadha wa razaqanihi min ghayri hawlin minni wa la quwwah',
  en: 'Praise be to Allah who clothed me with this and provided it for me without any power or strength from me.',
  ur: 'تمام تعریفیں اللہ کے لیے جس نے مجھے یہ پہنایا اور میری کسی طاقت و قوت کے بغیر مجھے یہ عطا کیا۔',
  count: 1,
  reference: 'Abu Dawud 4023, Tirmidhi 3458',
);

const _z_new_clothes = Zikr(
  id: 'new_clothes',
  titleEn: 'Wearing new clothes',
  titleUr: 'نیا کپڑا پہنتے وقت',
  arabic: 'اَللّٰهُمَّ لَكَ الْحَمْدُ أَنْتَ كَسَوْتَنِيهِ، أَسْأَلُكَ مِنْ خَيْرِهِ وَخَيْرِ مَا صُنِعَ لَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّهِ وَشَرِّ مَا صُنِعَ لَهُ',
  translit: "Allahumma lakal-hamdu anta kasawtanih, as'aluka min khayrihi wa khayri ma suni'a lah, wa a'udhu bika min sharrihi wa sharri ma suni'a lah",
  en: 'O Allah, praise be to You; You clothed me with it. I ask You for its good and the good it was made for, and I seek refuge in You from its evil and the evil it was made for.',
  ur: 'اے اللہ! تیرے ہی لیے تعریف ہے، تو نے ہی مجھے یہ پہنایا۔ میں تجھ سے اس کی بھلائی اور جس کام کے لیے یہ بنایا گیا اس کی بھلائی مانگتا ہوں، اور اس کے شر اور جس کام کے لیے یہ بنایا گیا اس کے شر سے تیری پناہ مانگتا ہوں۔',
  count: 1,
  reference: 'Abu Dawud 4020, Tirmidhi 1767',
);

const _z_market = Zikr(
  id: 'market',
  titleEn: 'Entering the market',
  titleUr: 'بازار میں داخل ہوتے وقت',
  arabic: 'لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، يُحْيِي وَيُمِيتُ، وَهُوَ حَيٌّ لَا يَمُوتُ، بِيَدِهِ الْخَيْرُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
  translit: "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, yuhyi wa yumit, wa huwa hayyun la yamut, biyadihil-khayr, wa huwa 'ala kulli shay'in qadir",
  en: 'There is no god but Allah, alone without partner. His is the dominion and His is the praise. He gives life and causes death, and He is Ever-Living and does not die. In His hand is all good, and He has power over all things.',
  ur: 'اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے، اس کا کوئی شریک نہیں، اسی کی بادشاہی ہے اور اسی کے لیے تعریف ہے، وہی زندہ کرتا اور مارتا ہے، وہ ہمیشہ زندہ ہے کبھی نہیں مرے گا، ہر بھلائی اسی کے ہاتھ میں ہے اور وہ ہر چیز پر قادر ہے۔',
  count: 1,
  reference: 'Tirmidhi 3428, Ibn Majah 2235',
);

const _z_new_moon = Zikr(
  id: 'new_moon',
  titleEn: 'Seeing the new moon',
  titleUr: 'نیا چاند دیکھ کر',
  arabic: 'اَللّٰهُمَّ أَهِلَّهُ عَلَيْنَا بِالْيُمْنِ وَالْإِيمَانِ، وَالسَّلَامَةِ وَالْإِسْلَامِ، رَبِّي وَرَبُّكَ اللّٰهُ',
  translit: "Allahumma ahillahu 'alayna bil-yumni wal-iman, was-salamati wal-Islam, Rabbi wa Rabbukallah",
  en: 'O Allah, let this moon rise over us with blessing and faith, safety and Islam. (O moon) my Lord and your Lord is Allah.',
  ur: 'اے اللہ! اس چاند کو ہم پر برکت اور ایمان، سلامتی اور اسلام کے ساتھ طلوع فرما۔ (اے چاند) میرا اور تیرا رب اللہ ہے۔',
  count: 1,
  reference: 'Tirmidhi 3451',
);

const _z_anger = Zikr(
  id: 'anger',
  titleEn: 'When angry',
  titleUr: 'غصہ آنے پر',
  arabic: 'أَعُوذُ بِاللّٰهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
  translit: "A'udhu billahi minash-shaytanir-rajim",
  en: 'I seek refuge in Allah from Satan the accursed.',
  ur: 'میں شیطان مردود سے اللہ کی پناہ مانگتا ہوں۔',
  count: 1,
  reference: 'Bukhari 6115, Muslim 2610',
);

const _z_visiting_sick = Zikr(
  id: 'visiting_sick',
  titleEn: 'Visiting the sick',
  titleUr: 'مریض کی عیادت',
  arabic: 'لَا بَأْسَ طَهُورٌ إِنْ شَاءَ اللّٰهُ',
  translit: "La ba'sa tahurun in sha' Allah",
  en: 'No harm; it is a purification, if Allah wills.',
  ur: 'کوئی حرج نہیں، ان شاء اللہ یہ (بیماری) گناہوں سے پاکی کا ذریعہ ہے۔',
  count: 1,
  reference: 'Bukhari 3616',
);

const _z_shifa = Zikr(
  id: 'shifa',
  titleEn: 'Dua for healing the sick',
  titleUr: 'مریض کی شفا کی دعا',
  arabic: 'اَللّٰهُمَّ رَبَّ النَّاسِ، أَذْهِبِ الْبَأْسَ، اشْفِ أَنْتَ الشَّافِي، لَا شِفَاءَ إِلَّا شِفَاؤُكَ، شِفَاءً لَا يُغَادِرُ سَقَمًا',
  translit: "Allahumma Rabban-nas, adhhibil-ba's, ishfi antash-Shafi, la shifa'a illa shifa'uk, shifa'an la yughadiru saqama",
  en: 'O Allah, Lord of mankind, remove the harm and heal; You are the Healer. There is no healing but Your healing, a healing that leaves no illness.',
  ur: 'اے اللہ! لوگوں کے رب! تکلیف دور فرما اور شفا دے، تو ہی شفا دینے والا ہے، تیری شفا کے سوا کوئی شفا نہیں، ایسی شفا جو کوئی بیماری باقی نہ چھوڑے۔',
  count: 1,
  reference: 'Bukhari 5743, Muslim 2191',
);

const _z_seeing_afflicted = Zikr(
  id: 'seeing_afflicted',
  titleEn: 'Seeing someone afflicted (say quietly)',
  titleUr: 'کسی مصیبت زدہ کو دیکھ کر (آہستہ پڑھیں)',
  arabic: 'اَلْحَمْدُ لِلّٰهِ الَّذِي عَافَانِي مِمَّا ابْتَلَاكَ بِهِ، وَفَضَّلَنِي عَلَى كَثِيرٍ مِمَّنْ خَلَقَ تَفْضِيلًا',
  translit: "Alhamdu lillahil-ladhi 'afani mimmabtalaka bih, wa faddalani 'ala kathirin mimman khalaqa tafdila",
  en: 'Praise be to Allah who saved me from what He has tested you with and favoured me over much of His creation.',
  ur: 'تمام تعریفیں اللہ کے لیے جس نے مجھے اس آزمائش سے عافیت دی جس میں تجھے مبتلا کیا، اور مجھے اپنی بہت سی مخلوق پر فضیلت دی۔',
  count: 1,
  reference: 'Tirmidhi 3432',
);

const _z_end_gathering = Zikr(
  id: 'end_gathering',
  titleEn: 'End of a gathering',
  titleUr: 'مجلس کے اختتام پر',
  arabic: 'سُبْحَانَكَ اللّٰهُمَّ وَبِحَمْدِكَ، أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا أَنْتَ، أَسْتَغْفِرُكَ وَأَتُوبُ إِلَيْكَ',
  translit: 'Subhanakallahumma wa bihamdik, ashhadu an la ilaha illa ant, astaghfiruka wa atubu ilayk',
  en: 'Glory be to You, O Allah, and praise. I bear witness that there is no god but You. I seek Your forgiveness and turn to You in repentance.',
  ur: 'اے اللہ! تو پاک ہے اور تیری ہی تعریف ہے، میں گواہی دیتا ہوں کہ تیرے سوا کوئی معبود نہیں، میں تجھ سے بخشش مانگتا ہوں اور تیری طرف توبہ کرتا ہوں۔',
  count: 1,
  reference: 'Tirmidhi 3433, Abu Dawud 4859',
);

const _z_mirror = Zikr(
  id: 'mirror',
  titleEn: 'Looking in the mirror',
  titleUr: 'آئینہ دیکھتے وقت',
  arabic: 'اَللّٰهُمَّ أَنْتَ حَسَّنْتَ خَلْقِي فَحَسِّنْ خُلُقِي',
  translit: 'Allahumma anta hassanta khalqi fahassin khuluqi',
  en: 'O Allah, You made my appearance beautiful, so make my character beautiful too.',
  ur: 'اے اللہ! تو نے میری صورت اچھی بنائی ہے تو میرے اخلاق بھی اچھے کر دے۔',
  count: 1,
  reference: 'Musnad Ahmad',
);

const _z_difficult_task = Zikr(
  id: 'difficult_task',
  titleEn: 'When a task is difficult',
  titleUr: 'جب کوئی کام مشکل لگے',
  arabic: 'اَللّٰهُمَّ لَا سَهْلَ إِلَّا مَا جَعَلْتَهُ سَهْلًا، وَأَنْتَ تَجْعَلُ الْحَزْنَ إِذَا شِئْتَ سَهْلًا',
  translit: "Allahumma la sahla illa ma ja'altahu sahla, wa anta taj'alul-hazna idha shi'ta sahla",
  en: 'O Allah, nothing is easy except what You make easy, and You make the difficult easy if You will.',
  ur: 'اے اللہ! کوئی کام آسان نہیں سوائے اس کے جسے تو آسان کر دے، اور تو جب چاہے مشکل کو آسان کر دیتا ہے۔',
  count: 1,
  reference: 'Sahih Ibn Hibban 974',
);

const _z_fear_enemy = Zikr(
  id: 'fear_enemy',
  titleEn: 'When fearing an enemy',
  titleUr: 'دشمن کا خوف ہو',
  arabic: 'اَللّٰهُمَّ إِنَّا نَجْعَلُكَ فِي نُحُورِهِمْ، وَنَعُوذُ بِكَ مِنْ شُرُورِهِمْ',
  translit: "Allahumma inna naj'aluka fi nuhurihim, wa na'udhu bika min shururihim",
  en: 'O Allah, we place You before them and we seek refuge in You from their evil.',
  ur: 'اے اللہ! ہم تجھے ان کے مقابلے میں کرتے ہیں اور ان کی شرارتوں سے تیری پناہ مانگتے ہیں۔',
  count: 1,
  reference: 'Abu Dawud 1537',
);

const _z_marriage = Zikr(
  id: 'marriage',
  titleEn: 'Congratulating on a marriage',
  titleUr: 'نکاح کی مبارکباد',
  arabic: 'بَارَكَ اللّٰهُ لَكَ، وَبَارَكَ عَلَيْكَ، وَجَمَعَ بَيْنَكُمَا فِي خَيْرٍ',
  translit: "Barakallahu laka, wa baraka 'alayka, wa jama'a baynakuma fi khayr",
  en: 'May Allah bless you, shower blessings upon you and join you both in goodness.',
  ur: 'اللہ تمہیں برکت دے، تم پر برکت نازل فرمائے اور تم دونوں کو بھلائی میں جمع رکھے۔',
  count: 1,
  reference: 'Abu Dawud 2130, Tirmidhi 1091',
);

const _z_istikhara = Zikr(
  id: 'istikhara',
  titleEn: 'Dua of Istikhara',
  titleUr: 'استخارہ کی دعا',
  arabic: 'اَللّٰهُمَّ إِنِّي أَسْتَخِيرُكَ بِعِلْمِكَ، وَأَسْتَقْدِرُكَ بِقُدْرَتِكَ، وَأَسْأَلُكَ مِنْ فَضْلِكَ الْعَظِيمِ، فَإِنَّكَ تَقْدِرُ وَلَا أَقْدِرُ، وَتَعْلَمُ وَلَا أَعْلَمُ، وَأَنْتَ عَلَّامُ الْغُيُوبِ. اَللّٰهُمَّ إِنْ كُنْتَ تَعْلَمُ أَنَّ هٰذَا الْأَمْرَ خَيْرٌ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي فَاقْدُرْهُ لِي وَيَسِّرْهُ لِي ثُمَّ بَارِكْ لِي فِيهِ، وَإِنْ كُنْتَ تَعْلَمُ أَنَّ هٰذَا الْأَمْرَ شَرٌّ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي فَاصْرِفْهُ عَنِّي وَاصْرِفْنِي عَنْهُ، وَاقْدُرْ لِيَ الْخَيْرَ حَيْثُ كَانَ ثُمَّ أَرْضِنِي بِهِ',
  translit: "Allahumma inni astakhiruka bi'ilmik, wa astaqdiruka biqudratik, wa as'aluka min fadlikal-'azim, fa innaka taqdiru wa la aqdir, wa ta'lamu wa la a'lam, wa anta 'allamul-ghuyub. Allahumma in kunta ta'lamu anna hadhal-amra khayrun li fi dini wa ma'ashi wa 'aqibati amri faqdurhu li wa yassirhu li thumma barik li fih, wa in kunta ta'lamu anna hadhal-amra sharrun li fi dini wa ma'ashi wa 'aqibati amri fasrifhu 'anni wasrifni 'anh, waqdur liyal-khayra haythu kana thumma ardini bih",
  en: 'O Allah, I seek Your guidance through Your knowledge and Your ability through Your power, and I ask You of Your great bounty. You have power and I have none; You know and I do not, and You are the Knower of the unseen. O Allah, if You know that this matter is good for me in my religion, my livelihood and my final outcome, then decree it for me, make it easy for me and bless me in it. And if You know that this matter is bad for me in my religion, my livelihood and my final outcome, then turn it away from me and turn me away from it, decree for me the good wherever it may be, and make me content with it. (Mention your need where it says "this matter".)',
  ur: 'اے اللہ! میں تیرے علم کے ذریعے تجھ سے بھلائی طلب کرتا ہوں، تیری قدرت کے ذریعے تجھ سے طاقت مانگتا ہوں اور تیرے بڑے فضل کا سوال کرتا ہوں، کیونکہ تو قدرت رکھتا ہے اور میں قدرت نہیں رکھتا، تو جانتا ہے اور میں نہیں جانتا، اور تو غیب کی باتوں کو خوب جاننے والا ہے۔ اے اللہ! اگر تیرے علم میں یہ کام میرے دین، میری معاش اور میرے انجام کے لحاظ سے میرے لیے بہتر ہے تو اسے میرے لیے مقدر کر دے، آسان کر دے اور پھر اس میں برکت دے۔ اور اگر تیرے علم میں یہ کام میرے دین، میری معاش اور میرے انجام کے لحاظ سے میرے لیے برا ہے تو اسے مجھ سے پھیر دے اور مجھے اس سے پھیر دے، اور میرے لیے بھلائی مقدر کر دے جہاں بھی ہو، پھر مجھے اس پر راضی کر دے۔ ("یہ کام" کی جگہ اپنی حاجت کا خیال کریں)',
  count: 1,
  reference: 'Bukhari 1162',
);

const _z_janazah = Zikr(
  id: 'janazah',
  titleEn: 'Funeral prayer dua',
  titleUr: 'نمازِ جنازہ کی دعا',
  arabic: 'اَللّٰهُمَّ اغْفِرْ لِحَيِّنَا وَمَيِّتِنَا، وَشَاهِدِنَا وَغَائِبِنَا، وَصَغِيرِنَا وَكَبِيرِنَا، وَذَكَرِنَا وَأُنْثَانَا، اَللّٰهُمَّ مَنْ أَحْيَيْتَهُ مِنَّا فَأَحْيِهِ عَلَى الْإِسْلَامِ، وَمَنْ تَوَفَّيْتَهُ مِنَّا فَتَوَفَّهُ عَلَى الْإِيمَانِ',
  translit: "Allahummaghfir lihayyina wa mayyitina, wa shahidina wa gha'ibina, wa saghirina wa kabirina, wa dhakarina wa unthana. Allahumma man ahyaytahu minna fa-ahyihi 'alal-Islam, wa man tawaffaytahu minna fatawaffahu 'alal-iman",
  en: 'O Allah, forgive our living and our dead, those present and those absent, our young and our old, our males and our females. O Allah, whomever of us You keep alive, keep him alive upon Islam, and whomever of us You cause to die, let him die upon faith.',
  ur: 'اے اللہ! ہمارے زندوں اور مُردوں کو، حاضر اور غائب کو، چھوٹوں اور بڑوں کو، مردوں اور عورتوں کو بخش دے۔ اے اللہ! ہم میں سے جسے تو زندہ رکھے اسے اسلام پر زندہ رکھ اور جسے موت دے اسے ایمان پر موت دے۔',
  count: 1,
  reference: 'Tirmidhi 1024, Abu Dawud 3201',
);

const _z_dua_ayyub = Zikr(
  id: 'dua_ayyub',
  titleEn: 'Dua for recovery (Prophet Ayyub)',
  titleUr: 'بیماری سے شفا کی دعا (حضرت ایوب)',
  arabic: '۞وَأَيُّوبَ إِذۡ نَادَىٰ رَبَّهُۥٓ أَنِّي مَسَّنِيَ ٱلضُّرُّ وَأَنتَ أَرۡحَمُ ٱلرَّـٰحِمِينَ',
  translit: 'Waayyooba ith nada rabbahu annee massaniya alddurru waanta arhamu alrrahimeena',
  en: 'And [mention] Job, when he called to his Lord, "Indeed, adversity has touched me, and you are the Most Merciful of the merciful',
  ur: 'اور یہی (ہوش مندی اور حکم و علم کی نعمت) ہم نے ایّوبؑ کو دی تھی یاد کرو، جبکہ اس نے اپنے رب کو پکارا کہ "مجھے بیماری لگ گئی ہے اور تو ارحم الراحمین ہے',
  count: 1,
  reference: 'Al-Anbiya 21:83',
);

const _z_dua_family = Zikr(
  id: 'dua_family',
  titleEn: 'For righteous spouses and children',
  titleUr: 'نیک بیوی بچوں کی دعا',
  arabic: 'وَٱلَّذِينَ يَقُولُونَ رَبَّنَا هَبۡ لَنَا مِنۡ أَزۡوَٰجِنَا وَذُرِّيَّـٰتِنَا قُرَّةَ أَعۡيُنٖ وَٱجۡعَلۡنَا لِلۡمُتَّقِينَ إِمَامًا',
  translit: 'Waallatheena yaqooloona rabbana hab lana min azwajina wathurriyyatina qurrata aAAyunin waijAAalna lilmuttaqeena imaman',
  en: 'And those who say, "Our Lord, grant us from among our wives and offspring comfort to our eyes and make us an example for the righteous',
  ur: 'جو دعائیں مانگا کرتے ہیں کہ "اے ہمارے رب، ہمیں اپنی بیویوں اور اپنی اولاد سے آنکھوں کی ٹھنڈک دے اور ہم کو پرہیز گاروں کا امام بنا',
  count: 1,
  reference: 'Al-Furqan 25:74',
);

const _z_dua_steadfast = Zikr(
  id: 'dua_steadfast',
  titleEn: 'Steadfastness of the heart',
  titleUr: 'دل کی استقامت',
  arabic: 'رَبَّنَا لَا تُزِغۡ قُلُوبَنَا بَعۡدَ إِذۡ هَدَيۡتَنَا وَهَبۡ لَنَا مِن لَّدُنكَ رَحۡمَةًۚ إِنَّكَ أَنتَ ٱلۡوَهَّابُ',
  translit: 'Rabbana la tuzigh quloobana baAAda ith hadaytana wahab lana min ladunka rahmatan innaka anta alwahhabu',
  en: '[Who say], "Our Lord, let not our hearts deviate after You have guided us and grant us from Yourself mercy. Indeed, You are the Bestower',
  ur: 'وہ اللہ سے دعا کرتے رہتے ہیں کہ: "پروردگار! جب تو ہمیں سیدھے رستہ پر لگا چکا ہے، تو پھر کہیں ہمارے دلوں کو کجی میں مبتلا نہ کر دیجیو ہمیں اپنے خزانہ فیض سے رحمت عطا کر کہ تو ہی فیاض حقیقی ہے',
  count: 1,
  reference: 'Aal-i-Imran 3:8',
);

const _z_dua_adam = Zikr(
  id: 'dua_adam',
  titleEn: 'Dua of repentance (Adam AS)',
  titleUr: 'توبہ کی دعا (حضرت آدم)',
  arabic: 'قَالَا رَبَّنَا ظَلَمۡنَآ أَنفُسَنَا وَإِن لَّمۡ تَغۡفِرۡ لَنَا وَتَرۡحَمۡنَا لَنَكُونَنَّ مِنَ ٱلۡخَٰسِرِينَ',
  translit: 'Qala rabbana thalamna anfusana wain lam taghfir lana watarhamna lanakoonanna mina alkhasireena',
  en: 'They said, "Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers',
  ur: 'دونوں بول اٹھے، "اے رب، ہم نے اپنے اوپر ستم کیا، اب اگر تو نے ہم سے در گزر نہ فرمایا اور رحم نہ کیا تو یقیناً ہم تباہ ہو جائیں گے',
  count: 1,
  reference: 'Al-Araf 7:23',
);

const _z_thana = Zikr(
  id: 'thana',
  titleEn: 'Thana (opening)',
  titleUr: 'ثنا',
  arabic: 'سُبْحَانَكَ اللّٰهُمَّ وَبِحَمْدِكَ، وَتَبَارَكَ اسْمُكَ، وَتَعَالَى جَدُّكَ، وَلَا إِلٰهَ غَيْرُكَ',
  translit: "Subhanakallahumma wa bihamdika, wa tabarakasmuka, wa ta'ala jadduka, wa la ilaha ghayruk",
  en: 'Glory be to You, O Allah, and praise. Blessed is Your name, exalted is Your majesty, and there is no god besides You.',
  ur: 'اے اللہ! تو پاک ہے اور تیری ہی تعریف ہے، تیرا نام بابرکت ہے، تیری شان بلند ہے اور تیرے سوا کوئی معبود نہیں۔',
  count: 1,
  reference: 'Abu Dawud 775, Tirmidhi 243',
);

const _z_taawwudh = Zikr(
  id: 'taawwudh',
  titleEn: "Ta'awwudh and Tasmiyah",
  titleUr: 'تعوذ و تسمیہ',
  arabic: 'أَعُوذُ بِاللّٰهِ مِنَ الشَّيْطَانِ الرَّجِيمِ\nبِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ',
  translit: "A'udhu billahi minash-shaytanir-rajim. Bismillahir-Rahmanir-Rahim",
  en: 'I seek refuge in Allah from Satan the accursed. In the name of Allah, the Most Gracious, the Most Merciful.',
  ur: 'میں شیطان مردود سے اللہ کی پناہ مانگتا ہوں۔ اللہ کے نام سے جو بڑا مہربان، نہایت رحم والا ہے۔',
  count: 1,
  reference: 'An-Nahl 16:98',
);

const _z_ruku = Zikr(
  id: 'ruku',
  titleEn: 'Tasbih in Ruku',
  titleUr: 'رکوع کی تسبیح',
  arabic: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
  translit: "Subhana Rabbiyal-'Azim",
  en: 'Glory be to my Lord, the Most Great.',
  ur: 'پاک ہے میرا رب جو عظمت والا ہے۔',
  count: 3,
  reference: 'Muslim 772, Abu Dawud 869',
);

const _z_qawmah = Zikr(
  id: 'qawmah',
  titleEn: 'Rising from Ruku',
  titleUr: 'رکوع سے اٹھتے وقت',
  arabic: 'سَمِعَ اللّٰهُ لِمَنْ حَمِدَهُ\nرَبَّنَا لَكَ الْحَمْدُ',
  translit: "Sami'allahu liman hamidah. Rabbana lakal-hamd",
  en: 'Allah hears the one who praises Him. Our Lord, to You is all praise.',
  ur: 'اللہ نے اس کی سن لی جس نے اس کی تعریف کی۔ اے ہمارے رب! تمام تعریف تیرے ہی لیے ہے۔',
  count: 1,
  reference: 'Bukhari 789',
);

const _z_sujood = Zikr(
  id: 'sujood',
  titleEn: 'Tasbih in Sajdah',
  titleUr: 'سجدے کی تسبیح',
  arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
  translit: "Subhana Rabbiyal-A'la",
  en: 'Glory be to my Lord, the Most High.',
  ur: 'پاک ہے میرا رب جو سب سے بلند ہے۔',
  count: 3,
  reference: 'Muslim 772, Abu Dawud 869',
);

const _z_jalsah = Zikr(
  id: 'jalsah',
  titleEn: 'Between the two Sajdahs',
  titleUr: 'دو سجدوں کے درمیان',
  arabic: 'رَبِّ اغْفِرْ لِي، رَبِّ اغْفِرْ لِي',
  translit: 'Rabbighfir li, Rabbighfir li',
  en: 'My Lord, forgive me; my Lord, forgive me.',
  ur: 'اے میرے رب! مجھے بخش دے، اے میرے رب! مجھے بخش دے۔',
  count: 1,
  reference: 'Abu Dawud 874, Ibn Majah 897',
);

const _z_tashahhud = Zikr(
  id: 'tashahhud',
  titleEn: 'Tashahhud (At-Tahiyyat)',
  titleUr: 'تشہد (التحیات)',
  arabic: 'اَلتَّحِيَّاتُ لِلّٰهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، اَلسَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللّٰهِ وَبَرَكَاتُهُ، اَلسَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللّٰهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللّٰهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
  translit: "At-tahiyyatu lillahi was-salawatu wat-tayyibat, as-salamu 'alayka ayyuhan-Nabiyyu wa rahmatullahi wa barakatuh, as-salamu 'alayna wa 'ala 'ibadillahis-salihin, ashhadu an la ilaha illallahu wa ashhadu anna Muhammadan 'abduhu wa rasuluh",
  en: 'All greetings, prayers and good things are for Allah. Peace be upon you, O Prophet, and the mercy of Allah and His blessings. Peace be upon us and upon the righteous servants of Allah. I bear witness that there is no god but Allah, and I bear witness that Muhammad is His servant and Messenger.',
  ur: 'تمام قولی، بدنی اور مالی عبادتیں اللہ کے لیے ہیں۔ اے نبی! آپ پر سلام ہو اور اللہ کی رحمت اور برکتیں۔ ہم پر اور اللہ کے نیک بندوں پر سلام ہو۔ میں گواہی دیتا ہوں کہ اللہ کے سوا کوئی معبود نہیں اور میں گواہی دیتا ہوں کہ محمد ﷺ اس کے بندے اور رسول ہیں۔',
  count: 1,
  reference: 'Bukhari 831, Muslim 402',
);

const _z_durood_ibrahimi = Zikr(
  id: 'durood_ibrahimi',
  titleEn: 'Durood-e-Ibrahimi',
  titleUr: 'درودِ ابراہیمی',
  arabic: 'اَللّٰهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ. اَللّٰهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
  translit: "Allahumma salli 'ala Muhammadin wa 'ala ali Muhammad, kama sallayta 'ala Ibrahima wa 'ala ali Ibrahim, innaka Hamidun Majid. Allahumma barik 'ala Muhammadin wa 'ala ali Muhammad, kama barakta 'ala Ibrahima wa 'ala ali Ibrahim, innaka Hamidun Majid",
  en: 'O Allah, send blessings upon Muhammad and the family of Muhammad, as You sent blessings upon Ibrahim and the family of Ibrahim; You are Praiseworthy, Glorious. O Allah, bless Muhammad and the family of Muhammad, as You blessed Ibrahim and the family of Ibrahim; You are Praiseworthy, Glorious.',
  ur: 'اے اللہ! محمد ﷺ اور آلِ محمد پر رحمت نازل فرما جیسے تو نے ابراہیم اور آلِ ابراہیم پر رحمت نازل فرمائی، بے شک تو تعریف والا، بزرگی والا ہے۔ اے اللہ! محمد ﷺ اور آلِ محمد پر برکت نازل فرما جیسے تو نے ابراہیم اور آلِ ابراہیم پر برکت نازل فرمائی، بے شک تو تعریف والا، بزرگی والا ہے۔',
  count: 1,
  reference: 'Bukhari 3370',
);

const _z_after_durood = Zikr(
  id: 'after_durood',
  titleEn: 'Dua after Durood',
  titleUr: 'درود کے بعد کی دعا',
  arabic: 'اَللّٰهُمَّ إِنِّي ظَلَمْتُ نَفْسِي ظُلْمًا كَثِيرًا، وَلَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ، فَاغْفِرْ لِي مَغْفِرَةً مِنْ عِنْدِكَ، وَارْحَمْنِي، إِنَّكَ أَنْتَ الْغَفُورُ الرَّحِيمُ',
  translit: "Allahumma inni zalamtu nafsi zulman kathira, wa la yaghfirudh-dhunuba illa ant, faghfir li maghfiratan min 'indik, warhamni, innaka antal-Ghafurur-Rahim",
  en: 'O Allah, I have wronged myself greatly and none forgives sins but You, so grant me forgiveness from You and have mercy on me; You are the Forgiving, the Merciful.',
  ur: 'اے اللہ! میں نے اپنی جان پر بہت ظلم کیا اور تیرے سوا کوئی گناہ معاف نہیں کرتا، پس اپنی طرف سے مجھے بخش دے اور مجھ پر رحم فرما، بے شک تو بخشنے والا، رحم کرنے والا ہے۔',
  count: 1,
  reference: 'Bukhari 834, Muslim 2705',
);

const _z_qunoot = Zikr(
  id: 'qunoot',
  titleEn: 'Dua-e-Qunoot (Witr)',
  titleUr: 'دعائے قنوت (وتر)',
  arabic: 'اَللّٰهُمَّ إِنَّا نَسْتَعِينُكَ وَنَسْتَغْفِرُكَ، وَنُؤْمِنُ بِكَ وَنَتَوَكَّلُ عَلَيْكَ، وَنُثْنِي عَلَيْكَ الْخَيْرَ، وَنَشْكُرُكَ وَلَا نَكْفُرُكَ، وَنَخْلَعُ وَنَتْرُكُ مَنْ يَفْجُرُكَ. اَللّٰهُمَّ إِيَّاكَ نَعْبُدُ، وَلَكَ نُصَلِّي وَنَسْجُدُ، وَإِلَيْكَ نَسْعَى وَنَحْفِدُ، وَنَرْجُو رَحْمَتَكَ وَنَخْشَى عَذَابَكَ، إِنَّ عَذَابَكَ بِالْكُفَّارِ مُلْحِقٌ',
  translit: "Allahumma inna nasta'inuka wa nastaghfiruk, wa nu'minu bika wa natawakkalu 'alayk, wa nuthni 'alaykal-khayr, wa nashkuruka wa la nakfuruk, wa nakhla'u wa natruku man yafjuruk. Allahumma iyyaka na'budu, wa laka nusalli wa nasjud, wa ilayka nas'a wa nahfid, wa narju rahmataka wa nakhsha 'adhabak, inna 'adhabaka bil-kuffari mulhiq",
  en: 'O Allah, we seek Your help and Your forgiveness, we believe in You and rely on You, we praise You with all good, we thank You and are not ungrateful to You, and we cast off and leave whoever disobeys You. O Allah, You alone we worship, to You we pray and prostrate, to You we hasten and strive; we hope for Your mercy and fear Your punishment. Surely Your punishment will reach the disbelievers.',
  ur: 'اے اللہ! ہم تجھ سے مدد مانگتے ہیں اور تجھ سے بخشش چاہتے ہیں، تجھ پر ایمان لاتے ہیں اور تجھ پر بھروسہ کرتے ہیں، تیری بہترین تعریف کرتے ہیں، تیرا شکر کرتے ہیں اور تیری ناشکری نہیں کرتے، اور جو تیری نافرمانی کرے اسے چھوڑتے اور الگ کرتے ہیں۔ اے اللہ! ہم تیری ہی عبادت کرتے ہیں، تیرے ہی لیے نماز پڑھتے اور سجدہ کرتے ہیں، تیری ہی طرف دوڑتے اور کوشش کرتے ہیں، تیری رحمت کے امیدوار ہیں اور تیرے عذاب سے ڈرتے ہیں، بے شک تیرا عذاب کافروں کو پہنچنے والا ہے۔',
  count: 1,
  reference: 'Musannaf Ibn Abi Shaybah; Sunan al-Kubra (Bayhaqi)',
);

const _z_kalima_1 = Zikr(
  id: 'kalima_1',
  titleEn: 'First Kalima – Tayyib',
  titleUr: 'پہلا کلمہ – طیب',
  arabic: 'لَا إِلٰهَ إِلَّا اللّٰهُ مُحَمَّدٌ رَسُولُ اللّٰهِ',
  translit: 'La ilaha illallahu Muhammadur-Rasulullah',
  en: 'There is no god but Allah; Muhammad is the Messenger of Allah.',
  ur: 'اللہ کے سوا کوئی معبود نہیں، محمد ﷺ اللہ کے رسول ہیں۔',
  count: 1,
  reference: 'Commonly taught (phrases from Quran & Sunnah)',
);

const _z_kalima_2 = Zikr(
  id: 'kalima_2',
  titleEn: 'Second Kalima – Shahadat',
  titleUr: 'دوسرا کلمہ – شہادت',
  arabic: 'أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
  translit: "Ashhadu an la ilaha illallahu wahdahu la sharika lah, wa ashhadu anna Muhammadan 'abduhu wa rasuluh",
  en: 'I bear witness that there is no god but Allah, alone without partner, and I bear witness that Muhammad is His servant and Messenger.',
  ur: 'میں گواہی دیتا ہوں کہ اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے اس کا کوئی شریک نہیں، اور میں گواہی دیتا ہوں کہ محمد ﷺ اس کے بندے اور رسول ہیں۔',
  count: 1,
  reference: 'Commonly taught (phrases from Quran & Sunnah)',
);

const _z_kalima_3 = Zikr(
  id: 'kalima_3',
  titleEn: 'Third Kalima – Tamjeed',
  titleUr: 'تیسرا کلمہ – تمجید',
  arabic: 'سُبْحَانَ اللّٰهِ وَالْحَمْدُ لِلّٰهِ وَلَا إِلٰهَ إِلَّا اللّٰهُ وَاللّٰهُ أَكْبَرُ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ الْعَلِيِّ الْعَظِيمِ',
  translit: "Subhanallahi wal-hamdu lillahi wa la ilaha illallahu wallahu akbar, wa la hawla wa la quwwata illa billahil-'Aliyyil-'Azim",
  en: 'Glory be to Allah, all praise is for Allah, there is no god but Allah, and Allah is the Greatest. There is no power and no strength except with Allah, the Most High, the Most Great.',
  ur: 'اللہ پاک ہے، تمام تعریفیں اللہ کے لیے ہیں، اللہ کے سوا کوئی معبود نہیں اور اللہ سب سے بڑا ہے۔ گناہوں سے بچنے کی طاقت اور نیکی کرنے کی قوت صرف اللہ کی مدد سے ہے جو بلند اور عظمت والا ہے۔',
  count: 1,
  reference: 'Commonly taught (phrases from Quran & Sunnah)',
);

const _z_kalima_4 = Zikr(
  id: 'kalima_4',
  titleEn: 'Fourth Kalima – Tawheed',
  titleUr: 'چوتھا کلمہ – توحید',
  arabic: 'لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، يُحْيِي وَيُمِيتُ، وَهُوَ حَيٌّ لَا يَمُوتُ أَبَدًا أَبَدًا، ذُو الْجَلَالِ وَالْإِكْرَامِ، بِيَدِهِ الْخَيْرُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
  translit: "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, yuhyi wa yumit, wa huwa hayyun la yamutu abadan abada, dhul-jalali wal-ikram, biyadihil-khayr, wa huwa 'ala kulli shay'in qadir",
  en: 'There is no god but Allah, alone without partner. His is the dominion and His is the praise. He gives life and causes death, and He is Ever-Living and will never ever die, Owner of majesty and honour. In His hand is all good, and He has power over all things.',
  ur: 'اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے، اس کا کوئی شریک نہیں، اسی کی بادشاہی ہے اور اسی کے لیے تعریف ہے، وہی زندہ کرتا اور مارتا ہے، وہ ہمیشہ زندہ ہے کبھی نہیں مرے گا، بڑے جلال اور عزت والا ہے، ہر بھلائی اسی کے ہاتھ میں ہے اور وہ ہر چیز پر قادر ہے۔',
  count: 1,
  reference: 'Commonly taught (phrases from Quran & Sunnah)',
);

const _z_kalima_5 = Zikr(
  id: 'kalima_5',
  titleEn: 'Fifth Kalima – Astaghfar',
  titleUr: 'پانچواں کلمہ – استغفار',
  arabic: 'أَسْتَغْفِرُ اللّٰهَ رَبِّي مِنْ كُلِّ ذَنْبٍ أَذْنَبْتُهُ عَمْدًا أَوْ خَطَأً، سِرًّا أَوْ عَلَانِيَةً، وَأَتُوبُ إِلَيْهِ مِنَ الذَّنْبِ الَّذِي أَعْلَمُ وَمِنَ الذَّنْبِ الَّذِي لَا أَعْلَمُ، إِنَّكَ أَنْتَ عَلَّامُ الْغُيُوبِ وَسَتَّارُ الْعُيُوبِ وَغَفَّارُ الذُّنُوبِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ الْعَلِيِّ الْعَظِيمِ',
  translit: "Astaghfirullaha Rabbi min kulli dhanbin adhnabtuhu 'amdan aw khata'an, sirran aw 'alaniyah, wa atubu ilayhi minadh-dhanbil-ladhi a'lamu wa minadh-dhanbil-ladhi la a'lam, innaka anta 'allamul-ghuyubi wa sattarul-'uyubi wa ghaffarudh-dhunub, wa la hawla wa la quwwata illa billahil-'Aliyyil-'Azim",
  en: 'I seek forgiveness from Allah, my Lord, for every sin I committed knowingly or by mistake, secretly or openly, and I turn to Him in repentance from the sin I know and the sin I do not know. Surely You are the Knower of the unseen, the Concealer of faults and the Forgiver of sins. There is no power and no strength except with Allah, the Most High, the Most Great.',
  ur: 'میں اللہ سے جو میرا رب ہے ہر اس گناہ کی معافی مانگتا ہوں جو میں نے جان بوجھ کر یا بھول کر، چھپ کر یا کھلم کھلا کیا، اور اس گناہ سے بھی توبہ کرتا ہوں جسے میں جانتا ہوں اور اس سے بھی جسے میں نہیں جانتا۔ بے شک تو غیبوں کا جاننے والا، عیبوں کو چھپانے والا اور گناہوں کو بخشنے والا ہے، اور گناہوں سے بچنے کی طاقت اور نیکی کی قوت صرف اللہ کی مدد سے ہے جو بلند اور عظمت والا ہے۔',
  count: 1,
  reference: 'Commonly taught (phrases from Quran & Sunnah)',
);

const _z_kalima_6 = Zikr(
  id: 'kalima_6',
  titleEn: 'Sixth Kalima – Radd-e-Kufr',
  titleUr: 'چھٹا کلمہ – ردِّ کفر',
  arabic: 'اَللّٰهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ أَنْ أُشْرِكَ بِكَ شَيْئًا وَأَنَا أَعْلَمُ بِهِ، وَأَسْتَغْفِرُكَ لِمَا لَا أَعْلَمُ بِهِ، تُبْتُ عَنْهُ، وَتَبَرَّأْتُ مِنَ الْكُفْرِ وَالشِّرْكِ وَالْكِذْبِ وَالْغِيبَةِ وَالْبِدْعَةِ وَالنَّمِيمَةِ وَالْفَوَاحِشِ وَالْبُهْتَانِ وَالْمَعَاصِي كُلِّهَا، وَأَسْلَمْتُ وَأَقُولُ لَا إِلٰهَ إِلَّا اللّٰهُ مُحَمَّدٌ رَسُولُ اللّٰهِ',
  translit: "Allahumma inni a'udhu bika min an ushrika bika shay'an wa ana a'lamu bih, wa astaghfiruka lima la a'lamu bih, tubtu 'anhu, wa tabarra'tu minal-kufri wash-shirki wal-kidhbi wal-ghibati wal-bid'ati wan-namimati wal-fawahishi wal-buhtani wal-ma'asi kulliha, wa aslamtu wa aqulu la ilaha illallahu Muhammadur-Rasulullah",
  en: 'O Allah, I seek refuge in You from knowingly associating anything with You, and I ask Your forgiveness for what I do not know. I repent from it, and I disown disbelief, shirk, lying, backbiting, innovation, tale-bearing, indecency, slander and all sins. I submit and I say: there is no god but Allah, Muhammad is the Messenger of Allah.',
  ur: 'اے اللہ! میں تیری پناہ مانگتا ہوں اس سے کہ جان بوجھ کر کسی چیز کو تیرا شریک ٹھہراؤں، اور جو میں نہیں جانتا اس کی تجھ سے معافی مانگتا ہوں۔ میں نے اس سے توبہ کی اور کفر، شرک، جھوٹ، غیبت، بدعت، چغلی، بے حیائی، بہتان اور ہر قسم کے گناہوں سے بیزاری اختیار کی۔ میں اسلام لایا اور کہتا ہوں: اللہ کے سوا کوئی معبود نہیں، محمد ﷺ اللہ کے رسول ہیں۔',
  count: 1,
  reference: 'Commonly taught (phrases from Quran & Sunnah)',
);

const Map<AzkarType, List<Zikr>> azkar = {
  AzkarType.morning: [
    _kursi,
    _ikhlas,
    _falaq,
    _nas,
    _bismillahLaYadurru,
    Zikr(
      id: 'raditu',
      arabic: 'رَضِيتُ بِٱللَّٰهِ رَبًّا، وَبِٱلْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا',
      translit: 'Raditu billahi Rabba, wa bil-Islami dina, wa bi-Muhammadin ﷺ nabiyya',
      en: 'I am pleased with Allah as my Lord, Islam as my religion and Muhammad ﷺ as my Prophet.',
      ur: 'میں اللہ کے رب ہونے، اسلام کے دین ہونے اور محمد ﷺ کے نبی ہونے پر راضی ہوں۔',
      count: 3,
      reference: 'Abu Dawud 5072',
    ),
    _subhanAllahWaBihamdihi,
    Zikr(
      id: 'asbahna',
      arabic: 'أَصْبَحْنَا وَأَصْبَحَ ٱلْمُلْكُ لِلَّٰهِ، وَٱلْحَمْدُ لِلَّٰهِ، لَا إِلَٰهَ إِلَّا ٱللَّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ ٱلْمُلْكُ وَلَهُ ٱلْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
      translit: "Asbahna wa asbahal-mulku lillah, wal-hamdu lillah, la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir",
      en: 'We have entered the morning and the dominion belongs to Allah; praise be to Allah. None has the right to be worshipped but Allah alone, without partner; His is the dominion and His the praise, and He is over all things competent.',
      ur: 'ہم نے صبح کی اور ساری بادشاہی اللہ کی ہے، تمام تعریفیں اللہ کے لیے ہیں، اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے اس کا کوئی شریک نہیں، اسی کی بادشاہی اور اسی کی تعریف ہے اور وہ ہر چیز پر قادر ہے۔',
      count: 1,
      reference: 'Sahih Muslim 2723',
    ),
    Zikr(
      id: 'istighfar_100',
      arabic: 'أَسْتَغْفِرُ ٱللَّٰهَ وَأَتُوبُ إِلَيْهِ',
      translit: 'Astaghfirullaha wa atubu ilayh',
      en: 'I seek forgiveness from Allah and repent to Him.',
      ur: 'میں اللہ سے بخشش مانگتا ہوں اور اسی کی طرف رجوع کرتا ہوں۔',
      count: 100,
      reference: 'Sahih Bukhari 6307, Sahih Muslim 2702',
    ),
    _z_sayyid_istighfar,
    _z_bika_m,
    _z_fitrah_m,
    _z_afini_badani,
    _z_ya_hayyu,
    _z_afw_afiyah,
    _z_alim_al_ghayb,
    _z_hasbiyallah_7,
    _z_ma_bi_nimah_m,
    _z_tahlil_10,
    _z_ajirni_nar,
    _z_ilman_nafia,
    _z_adada_khalqihi,
    _z_hashr_last,
    _z_rum_17_19,
  ],
  AzkarType.evening: [
    _kursi,
    _ikhlas,
    _falaq,
    _nas,
    _bismillahLaYadurru,
    _audhuKalimat,
    Zikr(
      id: 'amsayna',
      arabic: 'أَمْسَيْنَا وَأَمْسَى ٱلْمُلْكُ لِلَّٰهِ، وَٱلْحَمْدُ لِلَّٰهِ، لَا إِلَٰهَ إِلَّا ٱللَّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ ٱلْمُلْكُ وَلَهُ ٱلْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
      translit: "Amsayna wa amsal-mulku lillah, wal-hamdu lillah, la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir",
      en: 'We have entered the evening and the dominion belongs to Allah; praise be to Allah. None has the right to be worshipped but Allah alone, without partner; His is the dominion and His the praise, and He is over all things competent.',
      ur: 'ہم نے شام کی اور ساری بادشاہی اللہ کی ہے، تمام تعریفیں اللہ کے لیے ہیں، اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے اس کا کوئی شریک نہیں، اسی کی بادشاہی اور اسی کی تعریف ہے اور وہ ہر چیز پر قادر ہے۔',
      count: 1,
      reference: 'Sahih Muslim 2723',
    ),
    _subhanAllahWaBihamdihi,
    _z_sayyid_istighfar,
    _z_bika_e,
    _z_fitrah_e,
    _z_afini_badani,
    _z_ya_hayyu,
    _z_afw_afiyah,
    _z_alim_al_ghayb,
    _z_hasbiyallah_7,
    _z_ma_bi_nimah_e,
    _z_ajirni_nar,
    _z_hashr_last,
    _z_rum_17_19,
  ],
  AzkarType.sleep: [
    Zikr(
      id: 'bismika_amutu',
      arabic: 'بِٱسْمِكَ ٱللَّٰهُمَّ أَمُوتُ وَأَحْيَا',
      translit: 'Bismika Allahumma amutu wa ahya',
      en: 'In Your name, O Allah, I die and I live.',
      ur: 'اے اللہ! تیرے ہی نام سے مرتا (سوتا) ہوں اور جیتا (جاگتا) ہوں۔',
      count: 1,
      reference: 'Sahih Bukhari 6324',
    ),
    Zikr(
      id: 'kursi_sleep',
      titleEn: 'Ayat-ul-Kursi',
      titleUr: 'آیت الکرسی',
      arabic: 'ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡحَيُّ ٱلۡقَيُّومُۚ لَا تَأۡخُذُهُۥ سِنَةٞ وَلَا نَوۡمٞۚ لَّهُۥ مَا فِي ٱلسَّمَٰوَٰتِ وَمَا فِي ٱلۡأَرۡضِۗ مَن ذَا ٱلَّذِي يَشۡفَعُ عِندَهُۥٓ إِلَّا بِإِذۡنِهِۦۚ يَعۡلَمُ مَا بَيۡنَ أَيۡدِيهِمۡ وَمَا خَلۡفَهُمۡۖ وَلَا يُحِيطُونَ بِشَيۡءٖ مِّنۡ عِلۡمِهِۦٓ إِلَّا بِمَا شَآءَۚ وَسِعَ كُرۡسِيُّهُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَۖ وَلَا يَـُٔودُهُۥ حِفۡظُهُمَاۚ وَهُوَ ٱلۡعَلِيُّ ٱلۡعَظِيمُ',
      translit: 'Allahu la ilaha illa huwa alhayyu alqayyoomu la takhuthuhu sinatun wala nawmun lahu ma fee alssamawati wama fee alardi man tha allathee yashfaAAu AAindahu illa biithnihi yaAAlamu ma bayna aydeehim wama khalfahum wala yuheetoona bishayin min AAilmihi illa bima shaa wasiAAa kursiyyuhu alssamawati waalarda wala yaooduhu hifthuhuma wahuwa alAAaliyyu alAAatheemu',
      en: 'Allah - there is no deity except Him, the Ever-Living, the Sustainer of [all] existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is [presently] before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great',
      ur: 'اللہ، وہ زندہ جاوید ہستی، جو تمام کائنات کو سنبھالے ہوئے ہے، اُس کے سوا کوئی خدا نہیں ہے وہ نہ سوتا ہے اور نہ اُسے اونگھ لگتی ہے زمین اور آسمانوں میں جو کچھ ہے، اُسی کا ہے کون ہے جو اُس کی جناب میں اُس کی اجازت کے بغیر سفارش کر سکے؟ جو کچھ بندوں کے سامنے ہے اسے بھی وہ جانتا ہے اور جو کچھ اُن سے اوجھل ہے، اس سے بھی وہ واقف ہے اور اُس کی معلومات میں سے کوئی چیز اُن کی گرفت ادراک میں نہیں آسکتی الّا یہ کہ کسی چیز کا علم وہ خود ہی اُن کو دینا چاہے اُس کی حکومت آسمانوں اور زمین پر چھائی ہوئی ہے اور اُن کی نگہبانی اس کے لیے کوئی تھکا دینے والا کام نہیں ہے بس وہی ایک بزرگ و برتر ذات ہے',
      count: 1,
      reference: 'Sahih Bukhari 2311',
    ),
    Zikr(
      id: 'baqarah_285_286',
      titleEn: 'Last two ayat of Surah Al-Baqarah',
      titleUr: 'سورۃ البقرہ کی آخری دو آیات',
      arabic: 'ءَامَنَ ٱلرَّسُولُ بِمَآ أُنزِلَ إِلَيۡهِ مِن رَّبِّهِۦ وَٱلۡمُؤۡمِنُونَۚ كُلٌّ ءَامَنَ بِٱللَّهِ وَمَلَـٰٓئِكَتِهِۦ وَكُتُبِهِۦ وَرُسُلِهِۦ لَا نُفَرِّقُ بَيۡنَ أَحَدٖ مِّن رُّسُلِهِۦۚ وَقَالُواْ سَمِعۡنَا وَأَطَعۡنَاۖ غُفۡرَانَكَ رَبَّنَا وَإِلَيۡكَ ٱلۡمَصِيرُ ﴿٢٨٥﴾ لَا يُكَلِّفُ ٱللَّهُ نَفۡسًا إِلَّا وُسۡعَهَاۚ لَهَا مَا كَسَبَتۡ وَعَلَيۡهَا مَا ٱكۡتَسَبَتۡۗ رَبَّنَا لَا تُؤَاخِذۡنَآ إِن نَّسِينَآ أَوۡ أَخۡطَأۡنَاۚ رَبَّنَا وَلَا تَحۡمِلۡ عَلَيۡنَآ إِصۡرٗا كَمَا حَمَلۡتَهُۥ عَلَى ٱلَّذِينَ مِن قَبۡلِنَاۚ رَبَّنَا وَلَا تُحَمِّلۡنَا مَا لَا طَاقَةَ لَنَا بِهِۦۖ وَٱعۡفُ عَنَّا وَٱغۡفِرۡ لَنَا وَٱرۡحَمۡنَآۚ أَنتَ مَوۡلَىٰنَا فَٱنصُرۡنَا عَلَى ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ ﴿٢٨٦﴾',
      translit: '(285) Amana alrrasoolu bima onzila ilayhi min rabbihi waalmuminoona kullun amana biAllahi wamalaikatihi wakutubihi warusulihi la nufarriqu bayna ahadin min rusulihi waqaloo samiAAna waataAAna ghufranaka rabbana wailayka almaseeru (286) La yukallifu Allahu nafsan illa wusAAaha laha ma kasabat waAAalayha ma iktasabat rabbana la tuakhithna in naseena aw akhtana rabbana wala tahmil AAalayna isran kama hamaltahu AAala allatheena min qablina rabbana wala tuhammilna ma la taqata lana bihi waoAAfu AAanna waighfir lana wairhamna anta mawlana faonsurna AAala alqawmi alkafireena',
      en: '(285) The Messenger has believed in what was revealed to him from his Lord, and [so have] the believers. All of them have believed in Allah and His angels and His books and His messengers, [saying], "We make no distinction between any of His messengers." And they say, "We hear and we obey. [We seek] Your forgiveness, our Lord, and to You is the [final] destination (286) Allah does not charge a soul except [with that within] its capacity. It will have [the consequence of] what [good] it has gained, and it will bear [the consequence of] what [evil] it has earned. "Our Lord, do not impose blame upon us if we have forgotten or erred. Our Lord, and lay not upon us a burden like that which You laid upon those before us. Our Lord, and burden us not with that which we have no ability to bear. And pardon us; and forgive us; and have mercy upon us. You are our protector, so give us victory over the disbelieving people',
      ur: '(285) رسول اُس ہدایت پر ایمان لایا ہے جو اس کے رب کی طرف سے اس پر نازل ہوئی ہے اور جو لوگ اِس رسول کے ماننے والے ہیں، انہوں نے بھی اس ہدایت کو دل سے تسلیم کر لیا ہے یہ سب اللہ اور اس کے فرشتوں اوراس کی کتابوں اور اس کے رسولوں کو مانتے ہیں اور ان کا قول یہ ہے کہ: "ہم اللہ کے رسولوں کو ایک دوسرے سے الگ نہیں کرتے، ہم نے حکم سنا اور اطاعت قبول کی مالک! ہم تجھ سے خطا بخشی کے طالب ہیں اور ہمیں تیری ہی طرف پلٹنا ہے (286) اللہ کسی متنفس پر اُس کی مقدرت سے بڑھ کر ذمہ داری کا بوجھ نہیں ڈالتا ہر شخص نے جو نیکی کمائی ہے، اس کا پھل اسی کے لیے ہے اور جو بدی سمیٹی ہے، اس کا وبال اسی پر ہے (ایمان لانے والو! تم یوں دعا کیا کرو) اے ہمارے رب! ہم سے بھول چوک میں جو قصور ہو جائیں، ان پر گرفت نہ کر مالک! ہم پر وہ بوجھ نہ ڈال، جو تو نے ہم سے پہلے لوگوں پر ڈالے تھے پروردگار! جس بار کو اٹھانے کی طاقت ہم میں نہیں ہے، وہ ہم پر نہ رکھ، ہمارے ساتھ نرمی کر، ہم سے در گزر فرما، ہم پر رحم کر، تو ہمارا مولیٰ ہے، کافروں کے مقابلے میں ہماری مدد کر',
      count: 1,
      reference: 'Sahih Bukhari 5009',
    ),
    Zikr(
      id: 'sleep_subhanallah',
      arabic: 'سُبْحَانَ ٱللَّٰهِ',
      translit: 'SubhanAllah',
      en: 'Glory be to Allah.',
      ur: 'اللہ پاک ہے۔',
      count: 33,
      reference: 'Sahih Bukhari 3705',
    ),
    Zikr(
      id: 'sleep_alhamdulillah',
      arabic: 'ٱلْحَمْدُ لِلَّٰهِ',
      translit: 'Alhamdulillah',
      en: 'All praise is for Allah.',
      ur: 'تمام تعریفیں اللہ کے لیے ہیں۔',
      count: 33,
      reference: 'Sahih Bukhari 3705',
    ),
    Zikr(
      id: 'sleep_allahuakbar',
      arabic: 'ٱللَّٰهُ أَكْبَرُ',
      translit: 'Allahu Akbar',
      en: 'Allah is the Greatest.',
      ur: 'اللہ سب سے بڑا ہے۔',
      count: 34,
      reference: 'Sahih Bukhari 3705',
    ),
    Zikr(
      id: 'sleep_quls',
      titleEn: 'The three Quls (blow into palms and wipe over the body)',
      titleUr: 'تینوں قل (ہتھیلیوں پر دم کر کے جسم پر پھیریں)',
      arabic: 'قُلْ هُوَ ٱللَّٰهُ أَحَدٌ • قُلْ أَعُوذُ بِرَبِّ ٱلْفَلَقِ • قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ',
      translit: "Qul huwallahu ahad • Qul a'udhu bi rabbil-falaq • Qul a'udhu bi rabbin-nas",
      en: 'Recite Surah Al-Ikhlas, Al-Falaq and An-Nas, blow into the palms and wipe over the body.',
      ur: 'سورۃ الاخلاص، الفلق اور الناس پڑھ کر ہتھیلیوں پر دم کریں اور جسم پر پھیریں۔',
      count: 3,
      reference: 'Sahih Bukhari 5017',
    ),
    _z_bismika_rabbi,
    _z_qini_adhabak,
    _z_aslamtu_nafsi,
    _z_atamana,
    _z_khalaqta_nafsi,
    _z_astaghfir_sleep,
  ],
  AzkarType.afterSalah: [
    Zikr(
      id: 'salah_istighfar',
      arabic: 'أَسْتَغْفِرُ ٱللَّٰهَ',
      translit: 'Astaghfirullah',
      en: 'I seek the forgiveness of Allah.',
      ur: 'میں اللہ سے بخشش مانگتا ہوں۔',
      count: 3,
      reference: 'Sahih Muslim 591',
    ),
    Zikr(
      id: 'antas_salam',
      arabic: 'ٱللَّٰهُمَّ أَنْتَ ٱلسَّلَامُ وَمِنْكَ ٱلسَّلَامُ، تَبَارَكْتَ يَا ذَا ٱلْجَلَالِ وَٱلْإِكْرَامِ',
      translit: "Allahumma antas-salamu wa minkas-salam, tabarakta ya dhal-jalali wal-ikram",
      en: 'O Allah, You are Peace and from You comes peace. Blessed are You, O Possessor of majesty and honour.',
      ur: 'اے اللہ! تو ہی سلامتی والا ہے اور تجھ ہی سے سلامتی ہے، تو بڑی برکت والا ہے اے عظمت اور عزت والے۔',
      count: 1,
      reference: 'Sahih Muslim 591',
    ),
    Zikr(
      id: 'la_mania',
      arabic: 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ ٱلْمُلْكُ وَلَهُ ٱلْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ، ٱللَّٰهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا ٱلْجَدِّ مِنْكَ ٱلْجَدُّ',
      translit: "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir. Allahumma la mani'a lima a'tayta, wa la mu'tiya lima mana'ta, wa la yanfa'u dhal-jaddi minkal-jadd",
      en: 'None has the right to be worshipped but Allah alone, without partner; His is the dominion and His the praise, and He is over all things competent. O Allah, none can withhold what You give, none can give what You withhold, and the wealth of the wealthy cannot avail him against You.',
      ur: 'اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے، اس کا کوئی شریک نہیں، اسی کی بادشاہی اور اسی کی تعریف ہے اور وہ ہر چیز پر قادر ہے۔ اے اللہ! جو تو دے اسے کوئی روکنے والا نہیں، جو تو روک لے اسے کوئی دینے والا نہیں، اور کسی دولت مند کو اس کی دولت تیرے مقابلے میں نفع نہیں دیتی۔',
      count: 1,
      reference: 'Sahih Bukhari 844, Sahih Muslim 593',
    ),
    Zikr(
      id: 'salah_subhanallah',
      arabic: 'سُبْحَانَ ٱللَّٰهِ',
      translit: 'SubhanAllah',
      en: 'Glory be to Allah.',
      ur: 'اللہ پاک ہے۔',
      count: 33,
      reference: 'Sahih Muslim 597',
    ),
    Zikr(
      id: 'salah_alhamdulillah',
      arabic: 'ٱلْحَمْدُ لِلَّٰهِ',
      translit: 'Alhamdulillah',
      en: 'All praise is for Allah.',
      ur: 'تمام تعریفیں اللہ کے لیے ہیں۔',
      count: 33,
      reference: 'Sahih Muslim 597',
    ),
    Zikr(
      id: 'salah_allahuakbar',
      arabic: 'ٱللَّٰهُ أَكْبَرُ',
      translit: 'Allahu Akbar',
      en: 'Allah is the Greatest.',
      ur: 'اللہ سب سے بڑا ہے۔',
      count: 33,
      reference: 'Sahih Muslim 597',
    ),
    _tahlil,
    Zikr(
      id: 'kursi_salah',
      titleEn: 'Ayat-ul-Kursi',
      titleUr: 'آیت الکرسی',
      arabic: 'ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡحَيُّ ٱلۡقَيُّومُۚ لَا تَأۡخُذُهُۥ سِنَةٞ وَلَا نَوۡمٞۚ لَّهُۥ مَا فِي ٱلسَّمَٰوَٰتِ وَمَا فِي ٱلۡأَرۡضِۗ مَن ذَا ٱلَّذِي يَشۡفَعُ عِندَهُۥٓ إِلَّا بِإِذۡنِهِۦۚ يَعۡلَمُ مَا بَيۡنَ أَيۡدِيهِمۡ وَمَا خَلۡفَهُمۡۖ وَلَا يُحِيطُونَ بِشَيۡءٖ مِّنۡ عِلۡمِهِۦٓ إِلَّا بِمَا شَآءَۚ وَسِعَ كُرۡسِيُّهُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَۖ وَلَا يَـُٔودُهُۥ حِفۡظُهُمَاۚ وَهُوَ ٱلۡعَلِيُّ ٱلۡعَظِيمُ',
      translit: 'Allahu la ilaha illa huwa alhayyu alqayyoomu la takhuthuhu sinatun wala nawmun lahu ma fee alssamawati wama fee alardi man tha allathee yashfaAAu AAindahu illa biithnihi yaAAlamu ma bayna aydeehim wama khalfahum wala yuheetoona bishayin min AAilmihi illa bima shaa wasiAAa kursiyyuhu alssamawati waalarda wala yaooduhu hifthuhuma wahuwa alAAaliyyu alAAatheemu',
      en: 'Allah - there is no deity except Him, the Ever-Living, the Sustainer of [all] existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is [presently] before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great',
      ur: 'اللہ، وہ زندہ جاوید ہستی، جو تمام کائنات کو سنبھالے ہوئے ہے، اُس کے سوا کوئی خدا نہیں ہے وہ نہ سوتا ہے اور نہ اُسے اونگھ لگتی ہے زمین اور آسمانوں میں جو کچھ ہے، اُسی کا ہے کون ہے جو اُس کی جناب میں اُس کی اجازت کے بغیر سفارش کر سکے؟ جو کچھ بندوں کے سامنے ہے اسے بھی وہ جانتا ہے اور جو کچھ اُن سے اوجھل ہے، اس سے بھی وہ واقف ہے اور اُس کی معلومات میں سے کوئی چیز اُن کی گرفت ادراک میں نہیں آسکتی الّا یہ کہ کسی چیز کا علم وہ خود ہی اُن کو دینا چاہے اُس کی حکومت آسمانوں اور زمین پر چھائی ہوئی ہے اور اُن کی نگہبانی اس کے لیے کوئی تھکا دینے والا کام نہیں ہے بس وہی ایک بزرگ و برتر ذات ہے',
      count: 1,
      reference: "An-Nasa'i, As-Sunan al-Kubra 9928",
    ),
    Zikr(
      id: 'ainni',
      arabic: 'ٱللَّٰهُمَّ أَعِنِّي عَلَىٰ ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
      translit: "Allahumma a'inni 'ala dhikrika wa shukrika wa husni 'ibadatik",
      en: 'O Allah, help me to remember You, to thank You and to worship You well.',
      ur: 'اے اللہ! اپنے ذکر، اپنے شکر اور اپنی اچھی عبادت پر میری مدد فرما۔',
      count: 1,
      reference: 'Abu Dawud 1522',
    ),
  ],
  AzkarType.wakeUp: [
    Zikr(
      id: 'wake_ahyana',
      arabic: 'ٱلْحَمْدُ لِلَّٰهِ ٱلَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ ٱلنُّشُورُ',
      translit: "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur",
      en: 'All praise is for Allah who gave us life after having taken it from us, and unto Him is the resurrection.',
      ur: 'تمام تعریفیں اللہ کے لیے ہیں جس نے ہمیں مارنے (سلانے) کے بعد زندہ کیا (جگایا) اور اسی کی طرف اٹھ کر جانا ہے۔',
      count: 1,
      reference: 'Sahih Bukhari 6312',
    ),
  ],
  AzkarType.daily: [
    Zikr(
      id: 'before_eating',
      titleEn: 'Before eating',
      titleUr: 'کھانے سے پہلے',
      arabic: 'بِسْمِ ٱللَّٰهِ',
      translit: 'Bismillah',
      en: 'In the name of Allah.',
      ur: 'اللہ کے نام سے۔',
      count: 1,
      reference: 'Abu Dawud 3767, Tirmidhi 1858',
    ),
    Zikr(
      id: 'forgot_bismillah',
      titleEn: 'If you forgot to say Bismillah at the start',
      titleUr: 'اگر شروع میں بسم اللہ بھول جائیں',
      arabic: 'بِسْمِ ٱللَّٰهِ أَوَّلَهُ وَآخِرَهُ',
      translit: 'Bismillahi awwalahu wa akhirahu',
      en: 'In the name of Allah at its beginning and at its end.',
      ur: 'اللہ کے نام سے، اس کے شروع میں اور اس کے آخر میں۔',
      count: 1,
      reference: 'Abu Dawud 3767, Tirmidhi 1858',
    ),
    Zikr(
      id: 'after_eating',
      titleEn: 'After eating',
      titleUr: 'کھانے کے بعد',
      arabic: 'ٱلْحَمْدُ لِلَّٰهِ ٱلَّذِي أَطْعَمَنِي هَٰذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
      translit: "Alhamdu lillahil-ladhi at'amani hadha wa razaqanihi min ghayri hawlin minni wa la quwwah",
      en: 'All praise is for Allah who fed me this and provided it for me without any might or power from myself.',
      ur: 'تمام تعریفیں اللہ کے لیے ہیں جس نے مجھے یہ کھلایا اور میری کسی طاقت اور قوت کے بغیر مجھے یہ عطا کیا۔',
      count: 1,
      reference: 'Abu Dawud 4023, Tirmidhi 3458',
    ),
    Zikr(
      id: 'leaving_home',
      titleEn: 'Leaving the home',
      titleUr: 'گھر سے نکلتے وقت',
      arabic: 'بِسْمِ ٱللَّٰهِ، تَوَكَّلْتُ عَلَى ٱللَّٰهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّٰهِ',
      translit: "Bismillah, tawakkaltu 'alallah, wa la hawla wa la quwwata illa billah",
      en: 'In the name of Allah, I place my trust in Allah, and there is no might nor power except with Allah.',
      ur: 'اللہ کے نام سے، میں نے اللہ پر بھروسہ کیا، اور اللہ کے بغیر نہ کوئی طاقت ہے نہ قوت۔',
      count: 1,
      reference: 'Abu Dawud 5095, Tirmidhi 3426',
    ),
    Zikr(
      id: 'enter_masjid',
      titleEn: 'Entering the masjid',
      titleUr: 'مسجد میں داخل ہوتے وقت',
      arabic: 'ٱللَّٰهُمَّ ٱفْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
      translit: 'Allahummaf-tah li abwaba rahmatik',
      en: 'O Allah, open for me the doors of Your mercy.',
      ur: 'اے اللہ! میرے لیے اپنی رحمت کے دروازے کھول دے۔',
      count: 1,
      reference: 'Sahih Muslim 713',
    ),
    Zikr(
      id: 'leave_masjid',
      titleEn: 'Leaving the masjid',
      titleUr: 'مسجد سے نکلتے وقت',
      arabic: 'ٱللَّٰهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
      translit: "Allahumma inni as'aluka min fadlik",
      en: 'O Allah, I ask You of Your bounty.',
      ur: 'اے اللہ! میں تجھ سے تیرے فضل کا سوال کرتا ہوں۔',
      count: 1,
      reference: 'Sahih Muslim 713',
    ),
    Zikr(
      id: 'enter_toilet',
      titleEn: 'Entering the toilet',
      titleUr: 'بیت الخلاء میں داخل ہوتے وقت',
      arabic: 'ٱللَّٰهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ ٱلْخُبُثِ وَٱلْخَبَائِثِ',
      translit: "Allahumma inni a'udhu bika minal-khubuthi wal-khaba'ith",
      en: 'O Allah, I seek refuge in You from the male and female devils.',
      ur: 'اے اللہ! میں ناپاک جنوں اور ناپاک جنیوں سے تیری پناہ مانگتا ہوں۔',
      count: 1,
      reference: 'Sahih Bukhari 142, Sahih Muslim 375',
    ),
    Zikr(
      id: 'leave_toilet',
      titleEn: 'Leaving the toilet',
      titleUr: 'بیت الخلاء سے نکلتے وقت',
      arabic: 'غُفْرَانَكَ',
      translit: 'Ghufranak',
      en: 'I seek Your forgiveness.',
      ur: 'میں تیری بخشش چاہتا ہوں۔',
      count: 1,
      reference: 'Abu Dawud 30, Tirmidhi 7',
    ),
    Zikr(
      id: 'rabbana_atina',
      titleEn: 'Good in this world and the Hereafter',
      titleUr: 'دنیا اور آخرت کی بھلائی',
      arabic: 'وَمِنۡهُم مَّن يَقُولُ رَبَّنَآ ءَاتِنَا فِي ٱلدُّنۡيَا حَسَنَةٗ وَفِي ٱلۡأٓخِرَةِ حَسَنَةٗ وَقِنَا عَذَابَ ٱلنَّارِ',
      translit: 'Waminhum man yaqoolu rabbana atina fee alddunya hasanatan wafee alakhirati hasanatan waqina AAathaba alnnari',
      en: 'But among them is he who says, "Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire',
      ur: 'اور کوئی کہتا ہے کہ اے ہمارے رب! ہمیں دنیا میں بھی بھلائی دے اور آخرت میں بھی بھلائی اور آگ کے عذاب سے ہمیں بچا',
      count: 1,
      reference: 'Al-Baqarah 2:201; Sahih Bukhari 6389',
    ),
    Zikr(
      id: 'parents',
      titleEn: 'For parents',
      titleUr: 'والدین کے لیے',
      arabic: 'وَٱخۡفِضۡ لَهُمَا جَنَاحَ ٱلذُّلِّ مِنَ ٱلرَّحۡمَةِ وَقُل رَّبِّ ٱرۡحَمۡهُمَا كَمَا رَبَّيَانِي صَغِيرٗا',
      translit: 'Waikhfid lahuma janaha alththulli mina alrrahmati waqul rabbi irhamhuma kama rabbayanee sagheeran',
      en: 'And lower to them the wing of humility out of mercy and say, "My Lord, have mercy upon them as they brought me up [when I was] small',
      ur: 'اور نرمی و رحم کے ساتھ ان کے سامنے جھک کر رہو، اور دعا کیا کرو کہ "پروردگار، ان پر رحم فرما جس طرح اِنہوں نے رحمت و شفقت کے ساتھ مجھے بچپن میں پالا تھا',
      count: 1,
      reference: "Al-Isra' 17:24",
    ),
    _z_before_wudu,
    _z_after_wudu,
    _z_after_adhan,
    _z_enter_home,
    _z_iftar,
    _z_iftar_laka_sumtu,
    _z_fed_by_other,
    _z_wearing_clothes,
    _z_new_clothes,
    _z_market,
    _z_new_moon,
    _z_anger,
    _z_visiting_sick,
    _z_shifa,
    _z_seeing_afflicted,
    _z_end_gathering,
    _z_mirror,
    _z_difficult_task,
    _z_fear_enemy,
    _z_marriage,
    _z_istikhara,
    _z_janazah,
    _z_dua_ayyub,
    _z_dua_family,
    _z_dua_steadfast,
    _z_dua_adam,
  ],
  AzkarType.protection: [
    _bismillahLaYadurru,
    Zikr(
      id: 'audhu_place',
      titleEn: 'When stopping at a place',
      titleUr: 'کسی جگہ ٹھہرتے وقت',
      arabic: 'أَعُوذُ بِكَلِمَاتِ ٱللَّٰهِ ٱلتَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      translit: "A'udhu bikalimatillahit-tammati min sharri ma khalaq",
      en: 'I seek refuge in the perfect words of Allah from the evil of what He has created.',
      ur: 'میں اللہ کے کامل کلمات کی پناہ مانگتا ہوں ہر اس چیز کے شر سے جو اس نے پیدا کی۔',
      count: 1,
      reference: 'Sahih Muslim 2708',
    ),
    Zikr(
      id: 'hamm_hazan',
      titleEn: 'From worry, grief and debt',
      titleUr: 'فکر، غم اور قرض سے پناہ',
      arabic: 'ٱللَّٰهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ ٱلْهَمِّ وَٱلْحَزَنِ، وَٱلْعَجْزِ وَٱلْكَسَلِ، وَٱلْبُخْلِ وَٱلْجُبْنِ، وَضَلَعِ ٱلدَّيْنِ، وَغَلَبَةِ ٱلرِّجَالِ',
      translit: "Allahumma inni a'udhu bika minal-hammi wal-hazan, wal-'ajzi wal-kasal, wal-bukhli wal-jubn, wa dala'id-dayn, wa ghalabatir-rijal",
      en: 'O Allah, I seek refuge in You from worry and grief, from incapacity and laziness, from miserliness and cowardice, from the burden of debt and from being overpowered by men.',
      ur: 'اے اللہ! میں تیری پناہ مانگتا ہوں فکر اور غم سے، عاجزی اور سستی سے، بخل اور بزدلی سے، قرض کے بوجھ سے اور لوگوں کے غلبے سے۔',
      count: 1,
      reference: 'Sahih Bukhari 6369',
    ),
    Zikr(
      id: 'hasbunallah',
      titleEn: 'Trust in Allah',
      titleUr: 'اللہ پر بھروسہ',
      arabic: 'حَسْبُنَا ٱللَّٰهُ وَنِعْمَ ٱلْوَكِيلُ',
      translit: "Hasbunallahu wa ni'mal-wakil",
      en: 'Allah is sufficient for us, and He is the best Disposer of affairs.',
      ur: 'ہمارے لیے اللہ کافی ہے اور وہ بہترین کارساز ہے۔',
      count: 1,
      reference: "Al 'Imran 3:173; Sahih Bukhari 4563",
    ),
    _ikhlas,
    _falaq,
    _nas,
  ],
  AzkarType.travel: [
    Zikr(
      id: 'travel_dua',
      titleEn: 'Dua for travelling (after saying Allahu Akbar three times)',
      titleUr: 'سفر کی دعا (تین مرتبہ اللہ اکبر کہنے کے بعد)',
      arabic: 'سُبْحَانَ ٱلَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ، وَإِنَّا إِلَىٰ رَبِّنَا لَمُنْقَلِبُونَ، ٱللَّٰهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَٰذَا ٱلْبِرَّ وَٱلتَّقْوَىٰ، وَمِنَ ٱلْعَمَلِ مَا تَرْضَىٰ',
      translit: "Subhanal-ladhi sakhkhara lana hadha wa ma kunna lahu muqrinin, wa inna ila Rabbina lamunqalibun. Allahumma inna nas'aluka fi safarina hadhal-birra wat-taqwa, wa minal-'amali ma tarda",
      en: 'Glory be to Him who has subjected this to us, and we could never have it by our own efforts; and to our Lord we will surely return. O Allah, we ask You on this journey of ours for righteousness and piety, and for deeds that please You.',
      ur: 'پاک ہے وہ ذات جس نے اسے ہمارے بس میں کر دیا حالانکہ ہم اسے قابو میں لانے والے نہ تھے، اور ہم اپنے رب کی طرف لوٹنے والے ہیں۔ اے اللہ! ہم اپنے اس سفر میں تجھ سے نیکی اور تقویٰ کا اور ایسے عمل کا سوال کرتے ہیں جو تجھے پسند ہو۔',
      count: 1,
      reference: 'Sahih Muslim 1342',
    ),
    Zikr(
      id: 'travel_stop',
      titleEn: 'When stopping during a journey',
      titleUr: 'سفر میں کسی جگہ ٹھہرتے وقت',
      arabic: 'أَعُوذُ بِكَلِمَاتِ ٱللَّٰهِ ٱلتَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      translit: "A'udhu bikalimatillahit-tammati min sharri ma khalaq",
      en: 'I seek refuge in the perfect words of Allah from the evil of what He has created.',
      ur: 'میں اللہ کے کامل کلمات کی پناہ مانگتا ہوں ہر اس چیز کے شر سے جو اس نے پیدا کی۔',
      count: 1,
      reference: 'Sahih Muslim 2708',
    ),
    Zikr(
      id: 'travel_return',
      titleEn: 'When returning from a journey',
      titleUr: 'سفر سے واپسی پر',
      arabic: 'آيِبُونَ تَائِبُونَ عَابِدُونَ لِرَبِّنَا حَامِدُونَ',
      translit: "Ayibuna, ta'ibuna, 'abiduna, li-Rabbina hamidun",
      en: 'We return, repenting, worshipping and praising our Lord.',
      ur: 'ہم لوٹنے والے، توبہ کرنے والے، عبادت کرنے والے اور اپنے رب کی تعریف کرنے والے ہیں۔',
      count: 1,
      reference: 'Sahih Muslim 1342',
    ),
  ],
  AzkarType.salah: [
    _z_thana,
    _z_taawwudh,
    _z_ruku,
    _z_qawmah,
    _z_sujood,
    _z_jalsah,
    _z_tashahhud,
    _z_durood_ibrahimi,
    _z_after_durood,
    _z_qunoot,
  ],
  AzkarType.kalimas: [
    _z_kalima_1,
    _z_kalima_2,
    _z_kalima_3,
    _z_kalima_4,
    _z_kalima_5,
    _z_kalima_6,
  ],
};

/// Routine item that should be ticked when an azkar set is completed.
const Map<AzkarType, String> azkarRoutineId = {
  AzkarType.morning: 'morning_azkar',
  AzkarType.evening: 'evening_azkar',
  AzkarType.sleep: 'sleep_azkar',
};

/// All duas usable as "Dua of the day".
List<Zikr> get dailyDuaPool => [
      ...azkar[AzkarType.daily]!,
      ...azkar[AzkarType.protection]!.where((z) => z.count == 1),
      ...azkar[AzkarType.wakeUp]!,
      ...azkar[AzkarType.travel]!,
      azkar[AzkarType.afterSalah]!.firstWhere((z) => z.id == 'ainni'),
    ];

/// Indices (in [azkar] order) of the azkar of [t] that count towards
/// completing the set; extras are optional. Count keys stay `type_index`, so
/// appending items never changes saved progress.
List<int> coreAzkarIndices(AzkarType t) {
  final list = azkar[t]!;
  return [for (var i = 0; i < list.length; i++) if (!list[i].extra) i];
}

/// Number of completed core azkar of [t], given a counter lookup.
int coreAzkarDone(AzkarType t, int Function(String key) countOf) {
  final list = azkar[t]!;
  return coreAzkarIndices(t).where((i) => countOf('${t.name}_$i') >= list[i].count).length;
}

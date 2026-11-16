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
];

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
  });
}

enum AzkarType { morning, evening, sleep, afterSalah, wakeUp, daily, protection, travel }

const Map<AzkarType, List<String>> azkarTypeNames = {
  AzkarType.morning: ['Morning Azkar', 'صبح کے اذکار'],
  AzkarType.evening: ['Evening Azkar', 'شام کے اذکار'],
  AzkarType.sleep: ['Sleep Azkar', 'سونے کے اذکار'],
  AzkarType.afterSalah: ['After Salah', 'نماز کے بعد'],
  AzkarType.wakeUp: ['Wake-up Dua', 'جاگنے کی دعا'],
  AzkarType.daily: ['Daily Duas', 'روزمرہ کی دعائیں'],
  AzkarType.protection: ['Protection Duas', 'حفاظت کی دعائیں'],
  AzkarType.travel: ['Travel Duas', 'سفر کی دعائیں'],
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

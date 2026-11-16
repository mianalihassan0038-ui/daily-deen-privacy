class Dhikr {
  final String key;
  final String arabic;
  final String en;
  final String ur;
  final int target;
  const Dhikr(this.key, this.arabic, this.en, this.ur, this.target);
}

/// Counters available on the Tasbeeh screen.
const List<Dhikr> tasbeehList = [
  Dhikr('subhanallah', 'سُبْحَانَ ٱللَّٰهِ', 'SubhanAllah', 'سبحان اللہ', 100),
  Dhikr('alhamdulillah', 'ٱلْحَمْدُ لِلَّٰهِ', 'Alhamdulillah', 'الحمد للہ', 100),
  Dhikr('allahuakbar', 'ٱللَّٰهُ أَكْبَرُ', 'Allahu Akbar', 'اللہ اکبر', 100),
  Dhikr('astaghfirullah', 'أَسْتَغْفِرُ ٱللَّٰهَ', 'Astaghfirullah', 'استغفر اللہ', 100),
  Dhikr('durood', 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ', 'Durood Shareef', 'درود شریف', 100),
  Dhikr('lailaha', 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ', 'La ilaha illallah', 'لا الہ الا اللہ', 100),
];

class Zikr {
  final String arabic;
  final String en;
  final String ur;
  final int count;
  final String reference;
  const Zikr(this.arabic, this.en, this.ur, this.count, this.reference);
}

enum AzkarType { morning, evening, sleep }

const List<Zikr> _common = [
  Zikr(
    'ٱللَّٰهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ ۚ لَا تَأْخُذُهُۥ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُۥ مَا فِى ٱلسَّمَٰوَٰتِ وَمَا فِى ٱلْأَرْضِ ۗ مَن ذَا ٱلَّذِى يَشْفَعُ عِندَهُۥٓ إِلَّا بِإِذْنِهِۦ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَىْءٍ مِّنْ عِلْمِهِۦٓ إِلَّا بِمَا شَآءَ ۚ وَسِعَ كُرْسِيُّهُ ٱلسَّمَٰوَٰتِ وَٱلْأَرْضَ ۖ وَلَا يَـُٔودُهُۥ حِفْظُهُمَا ۚ وَهُوَ ٱلْعَلِىُّ ٱلْعَظِيمُ',
    'Ayat-ul-Kursi', 'آیت الکرسی', 1, 'Al-Baqarah 2:255'),
  Zikr('قُلْ هُوَ ٱللَّٰهُ أَحَدٌ ...', 'Surah Al-Ikhlas', 'سورۃ الاخلاص', 3, 'Abu Dawud 5082, Tirmidhi 3575'),
  Zikr('قُلْ أَعُوذُ بِرَبِّ ٱلْفَلَقِ ...', 'Surah Al-Falaq', 'سورۃ الفلق', 3, 'Abu Dawud 5082, Tirmidhi 3575'),
  Zikr('قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ ...', 'Surah An-Nas', 'سورۃ الناس', 3, 'Abu Dawud 5082, Tirmidhi 3575'),
];

const Map<AzkarType, List<Zikr>> azkar = {
  AzkarType.morning: [
    ..._common,
    Zikr('بِسْمِ ٱللَّٰهِ ٱلَّذِي لَا يَضُرُّ مَعَ ٱسْمِهِ شَيْءٌ فِي ٱلْأَرْضِ وَلَا فِي ٱلسَّمَاءِ وَهُوَ ٱلسَّمِيعُ ٱلْعَلِيمُ',
        'In the name of Allah, with whose name nothing on earth or in heaven can cause harm, and He is the All-Hearing, All-Knowing.',
        'اللہ کے نام سے جس کے نام کے ساتھ زمین و آسمان میں کوئی چیز نقصان نہیں پہنچا سکتی، اور وہ سننے والا جاننے والا ہے۔',
        3, 'Abu Dawud 5088, Tirmidhi 3388'),
    Zikr('رَضِيتُ بِٱللَّٰهِ رَبًّا، وَبِٱلْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا',
        'I am pleased with Allah as my Lord, Islam as my religion and Muhammad ﷺ as my Prophet.',
        'میں اللہ کے رب ہونے، اسلام کے دین ہونے اور محمد ﷺ کے نبی ہونے پر راضی ہوں۔',
        3, 'Abu Dawud 5072'),
    Zikr('سُبْحَانَ ٱللَّٰهِ وَبِحَمْدِهِ',
        'Glory be to Allah and praise be to Him.', 'اللہ پاک ہے اور اسی کی تعریف ہے۔', 100, 'Sahih Muslim 2692'),
    Zikr('أَصْبَحْنَا وَأَصْبَحَ ٱلْمُلْكُ لِلَّٰهِ، وَٱلْحَمْدُ لِلَّٰهِ، لَا إِلَٰهَ إِلَّا ٱللَّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
        'We have entered the morning and the dominion belongs to Allah; praise be to Allah, none has the right to be worshipped but Allah alone.',
        'ہم نے صبح کی اور ساری بادشاہی اللہ کی ہے، تمام تعریفیں اللہ کے لیے ہیں، اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے۔',
        1, 'Sahih Muslim 2723'),
    Zikr('أَسْتَغْفِرُ ٱللَّٰهَ وَأَتُوبُ إِلَيْهِ',
        'I seek forgiveness from Allah and repent to Him.', 'میں اللہ سے بخشش مانگتا ہوں اور اسی کی طرف رجوع کرتا ہوں۔', 100, 'Sahih Muslim 2702'),
  ],
  AzkarType.evening: [
    ..._common,
    Zikr('بِسْمِ ٱللَّٰهِ ٱلَّذِي لَا يَضُرُّ مَعَ ٱسْمِهِ شَيْءٌ فِي ٱلْأَرْضِ وَلَا فِي ٱلسَّمَاءِ وَهُوَ ٱلسَّمِيعُ ٱلْعَلِيمُ',
        'In the name of Allah, with whose name nothing on earth or in heaven can cause harm, and He is the All-Hearing, All-Knowing.',
        'اللہ کے نام سے جس کے نام کے ساتھ زمین و آسمان میں کوئی چیز نقصان نہیں پہنچا سکتی، اور وہ سننے والا جاننے والا ہے۔',
        3, 'Abu Dawud 5088, Tirmidhi 3388'),
    Zikr('أَعُوذُ بِكَلِمَاتِ ٱللَّٰهِ ٱلتَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
        'I seek refuge in the perfect words of Allah from the evil of what He has created.',
        'میں اللہ کے کامل کلمات کی پناہ مانگتا ہوں ہر اس چیز کے شر سے جو اس نے پیدا کی۔',
        3, 'Sahih Muslim 2709'),
    Zikr('أَمْسَيْنَا وَأَمْسَى ٱلْمُلْكُ لِلَّٰهِ، وَٱلْحَمْدُ لِلَّٰهِ، لَا إِلَٰهَ إِلَّا ٱللَّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
        'We have entered the evening and the dominion belongs to Allah; praise be to Allah, none has the right to be worshipped but Allah alone.',
        'ہم نے شام کی اور ساری بادشاہی اللہ کی ہے، تمام تعریفیں اللہ کے لیے ہیں، اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے۔',
        1, 'Sahih Muslim 2723'),
    Zikr('سُبْحَانَ ٱللَّٰهِ وَبِحَمْدِهِ',
        'Glory be to Allah and praise be to Him.', 'اللہ پاک ہے اور اسی کی تعریف ہے۔', 100, 'Sahih Muslim 2692'),
  ],
  AzkarType.sleep: [
    Zikr('بِٱسْمِكَ ٱللَّٰهُمَّ أَمُوتُ وَأَحْيَا',
        'In Your name, O Allah, I die and I live.', 'اے اللہ! تیرے ہی نام سے مرتا (سوتا) ہوں اور جیتا (جاگتا) ہوں۔', 1, 'Sahih Bukhari 6324'),
    Zikr('آيَةُ ٱلْكُرْسِيِّ (البقرة ٢٥٥)', 'Ayat-ul-Kursi', 'آیت الکرسی', 1, 'Sahih Bukhari 2311'),
    Zikr('آمَنَ ٱلرَّسُولُ ... (البقرة ٢٨٥-٢٨٦)', 'Last two ayat of Surah Al-Baqarah', 'سورۃ البقرہ کی آخری دو آیات', 1, 'Sahih Bukhari 5009'),
    Zikr('سُبْحَانَ ٱللَّٰهِ', 'SubhanAllah', 'سبحان اللہ', 33, 'Sahih Bukhari 3705'),
    Zikr('ٱلْحَمْدُ لِلَّٰهِ', 'Alhamdulillah', 'الحمد للہ', 33, 'Sahih Bukhari 3705'),
    Zikr('ٱللَّٰهُ أَكْبَرُ', 'Allahu Akbar', 'اللہ اکبر', 34, 'Sahih Bukhari 3705'),
    Zikr('قُلْ هُوَ ٱللَّٰهُ أَحَدٌ • قُلْ أَعُوذُ بِرَبِّ ٱلْفَلَقِ • قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ',
        'Recite the three Quls, blow into palms and wipe over body', 'تینوں قل پڑھ کر ہاتھوں پر دم کر کے جسم پر پھیریں', 3, 'Sahih Bukhari 5017'),
  ],
};

/// Routine item that should be ticked when an azkar set is completed.
const Map<AzkarType, String> azkarRoutineId = {
  AzkarType.morning: 'morning_azkar',
  AzkarType.evening: 'evening_azkar',
  AzkarType.sleep: 'sleep_azkar',
};

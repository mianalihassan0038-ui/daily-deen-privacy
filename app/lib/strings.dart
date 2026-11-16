/// Lightweight two-language (English / Urdu) string table.
class S {
  final bool urdu;
  const S(this.urdu);

  String t(String key) {
    final v = _strings[key];
    if (v == null) return key;
    return urdu ? v[1] : v[0];
  }

  static const Map<String, List<String>> _strings = {
    'app_name': ['Daily Deen', 'ڈیلی دین'],
    'tagline': ['Build your daily connection with Allah', 'اللہ سے اپنا روزانہ تعلق مضبوط کریں'],
    'salam': ['Assalamu Alaikum!', 'السلام علیکم!'],
    'salam_sub': ['Make today a day of remembrance.', 'آج کا دن اللہ کی یاد میں گزاریں۔'],
    'nav_home': ['Home', 'ہوم'],
    'nav_namaz': ['Namaz', 'نماز'],
    'nav_quran': ['Quran', 'قرآن'],
    'nav_tasbeeh': ['Tasbeeh', 'تسبیح'],
    'nav_progress': ['Progress', 'پیش رفت'],
    'next_prayer': ['NEXT PRAYER', 'اگلی نماز'],
    'in': ['in', 'باقی'],
    'todays_progress': ["Today's Progress", 'آج کی پیش رفت'],
    'completed_of': ['completed', 'مکمل'],
    'of': ['of', 'میں سے'],
    'daily_activities': ['Daily Activities', 'روزانہ کے معمولات'],
    'sec_early': ['Early Morning', 'صبح سویرے'],
    'sec_day': ['Daytime', 'دن'],
    'sec_night': ['Evening & Night', 'شام اور رات'],
    'optional': ['Optional', 'اختیاری'],
    'fajr': ['Fajr', 'فجر'],
    'sunrise': ['Sunrise', 'طلوع آفتاب'],
    'dhuhr': ['Dhuhr', 'ظہر'],
    'asr': ['Asr', 'عصر'],
    'maghrib': ['Maghrib', 'مغرب'],
    'isha': ['Isha', 'عشاء'],
    'prayer_times': ['Prayer Times', 'اوقاتِ نماز'],
    'status_none': ['Not marked', 'درج نہیں'],
    'status_alone': ['Prayed alone', 'انفرادی'],
    'status_jamaat': ['With Jamaat', 'باجماعت'],
    'status_qaza': ['Qaza', 'قضا'],
    'status_missed': ['Missed', 'چھوٹ گئی'],
    'sunnah_nafl': ['Sunnah / Nafl prayed', 'سنت / نفل ادا کیے'],
    'monthly_report': ['Last 30 days', 'پچھلے 30 دن'],
    'qaza_pending': ['Qaza to make up', 'باقی قضا نمازیں'],
    'qaza_add': ['Add', 'شامل کریں'],
    'qaza_done': ['Prayed one', 'ایک ادا کی'],
    'quran_tracker': ['Quran Tracker', 'قرآن ٹریکر'],
    'pages_today': ['Pages read today', 'آج پڑھے گئے صفحات'],
    'daily_target': ['Daily target', 'روزانہ ہدف'],
    'pages': ['pages', 'صفحات'],
    'khatam_progress': ['Khatam progress', 'ختم قرآن کی پیش رفت'],
    'para_progress': ['Para (Juz) progress', 'پاروں کی پیش رفت'],
    'reset_khatam': ['Start new Khatam', 'نیا ختم شروع کریں'],
    'khatams_done': ['Khatams completed', 'مکمل ختم'],
    'surah_checklist': ['Daily Surah checklist', 'روزانہ سورتوں کی فہرست'],
    'tasbeeh': ['Tasbeeh', 'تسبیح'],
    'azkar': ['Azkar', 'اذکار'],
    'morning_azkar': ['Morning Azkar', 'صبح کے اذکار'],
    'evening_azkar': ['Evening Azkar', 'شام کے اذکار'],
    'sleep_azkar': ['Before Sleep', 'سونے سے پہلے'],
    'az_m': ['Morning', 'صبح'],
    'az_e': ['Evening', 'شام'],
    'az_s': ['Sleep', 'سونا'],
    'tap_to_count': ['Tap to count', 'گننے کے لیے ٹیپ کریں'],
    'reset': ['Reset', 'ری سیٹ'],
    'today_total': ['Today', 'آج'],
    'target': ['Target', 'ہدف'],
    'custom_tasbeeh': ['Custom', 'اپنی تسبیح'],
    'mark_complete': ['Mark set complete', 'مکمل نشان لگائیں'],
    'completed': ['Completed', 'مکمل'],
    'progress': ['Progress', 'پیش رفت'],
    'current_streak': ['Current streak', 'موجودہ تسلسل'],
    'best_streak': ['Best streak', 'بہترین تسلسل'],
    'days': ['days', 'دن'],
    'this_week': ['This week', 'یہ ہفتہ'],
    'this_month': ['Last 30 days', 'پچھلے 30 دن'],
    'avg_completion': ['Average completion', 'اوسط تکمیل'],
    'prayers_on_time': ['Farz prayers prayed', 'ادا شدہ فرض نمازیں'],
    'most_missed': ['Most missed activities', 'سب سے زیادہ چھوٹنے والے معمولات'],
    'streak_hint': ['A streak day = all 5 farz prayers prayed', 'تسلسل کا دن = پانچوں فرض نمازیں ادا'],
    'settings': ['Settings', 'ترتیبات'],
    'language': ['Language', 'زبان'],
    'theme': ['Theme', 'تھیم'],
    'theme_system': ['System', 'سسٹم'],
    'theme_light': ['Light', 'لائٹ'],
    'theme_dark': ['Dark', 'ڈارک'],
    'location': ['Location (city)', 'مقام (شہر)'],
    'calc_method': ['Calculation method', 'حساب کا طریقہ'],
    'asr_method': ['Asr calculation', 'عصر کا حساب'],
    'hanafi': ['Hanafi', 'حنفی'],
    'shafi': ["Standard (Shafi'i, Maliki, Hanbali)", 'شافعی / مالکی / حنبلی'],
    'hijri_adjust': ['Hijri date adjustment', 'ہجری تاریخ میں تبدیلی'],
    'notifications': ['Prayer notifications', 'نماز کی اطلاعات'],
    'tahajjud_alarm': ['Wake-up / Tahajjud reminder', 'تہجد کی یاد دہانی'],
    'wake_time': ['Wake-up time', 'جاگنے کا وقت'],
    'quran_target': ['Daily Quran target (pages)', 'روزانہ قرآن کا ہدف (صفحات)'],
    'routine_items': ['Customize daily routine', 'روزانہ معمولات میں تبدیلی'],
    'add_custom': ['Add custom activity', 'نیا معمول شامل کریں'],
    'activity_name': ['Activity name', 'معمول کا نام'],
    'activity_target': ['Target (optional)', 'ہدف (اختیاری)'],
    'section': ['Section', 'حصہ'],
    'save': ['Save', 'محفوظ کریں'],
    'cancel': ['Cancel', 'منسوخ'],
    'delete': ['Delete', 'حذف کریں'],
    'about': ['About', 'تعارف'],
    'privacy': ['Privacy', 'پرائیویسی'],
    'privacy_text': [
      'All your records are stored only on this device. Daily Deen does not collect, share or upload any personal data.',
      'آپ کا تمام ریکارڈ صرف اسی فون میں محفوظ ہوتا ہے۔ ڈیلی دین کوئی ذاتی معلومات جمع، شیئر یا اپلوڈ نہیں کرتی۔'
    ],
    'disclaimer': [
      'Prayer times are calculated astronomically. Please confirm with your local masjid.',
      'نماز کے اوقات فلکیاتی حساب سے ہیں۔ براہِ کرم اپنی مقامی مسجد سے تصدیق کر لیں۔'
    ],
    'notif_title': ['Time for', 'وقت ہو گیا'],
    'notif_body': ['It is time to pray. May Allah accept it.', 'نماز کا وقت ہو گیا ہے۔ اللہ قبول فرمائے۔'],
    'tahajjud_notif': ['Time for Tahajjud', 'تہجد کا وقت'],
    'tahajjud_body': ['Wake up for Tahajjud and Dua.', 'تہجد اور دعا کے لیے اٹھیں۔'],
    'friday': ['Friday', 'جمعہ'],
    'all_done': ['MashaAllah! All done today.', 'ماشاءاللہ! آج کے سب معمولات مکمل۔'],
    'remaining': ['remaining', 'باقی'],
    'muhasaba_hint': ['How was your day? Note something to improve tomorrow.', 'آج کا دن کیسا رہا؟ کل کے لیے بہتری لکھیں۔'],
    'note': ['Note', 'نوٹ'],
  };
}

const List<String> weekdaysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const List<String> weekdaysUr = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];
const List<String> monthsEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];
const List<String> monthsUr = [
  'جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون', 'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'
];

String formatTime(DateTime t, {bool urdu = false}) {
  final local = t.toLocal();
  var h = local.hour % 12;
  if (h == 0) h = 12;
  final m = local.minute.toString().padLeft(2, '0');
  final ampm = local.hour < 12 ? (urdu ? 'صبح' : 'AM') : (urdu ? 'شام' : 'PM');
  return '$h:$m $ampm';
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

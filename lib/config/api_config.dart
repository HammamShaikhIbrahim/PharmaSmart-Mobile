// ==========================================
// ملف الإعدادات المركزية (Central Configuration)
// ==========================================
class ApiConfig {
  // 💡 ضع الـ IP الخاص بك هنا. (غيّره هنا فقط وسيتغير في كل التطبيق!)
  // ملاحظة ذهبية: إذا كنت تشغل التطبيق على متصفح Chrome، يمكنك كتابة localhost بدلاً من الأرقام!
  static const String serverIp = "192.168.68.120"; // مثال: "

  // الرابط الأساسي للسيرفر (Base URL)
  static const String baseUrl = "http://$serverIp/PharmaSmart-Web/api/";
}

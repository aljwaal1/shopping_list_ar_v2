import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const App());
const appTitle = 'قائمة المشتريات';
const appVersion = 'V3';
const developerEmail = 'fastunlocked2017@gmail.com';
const seed = Color(0xFF16A34A);

class Item {
  final String title;
  final String category;
  final int qty;
  final bool done;
  final DateTime date;
  const Item(this.title, this.category, this.qty, this.done, this.date);
  String encode() => [title, category, qty.toString(), done ? '1' : '0', date.toIso8601String()].join('|||');
  static Item decode(String raw) {
    final p = raw.split('|||');
    return Item(p.isNotEmpty ? p[0] : 'عنصر', p.length > 1 ? p[1] : 'عام', p.length > 2 ? int.tryParse(p[2]) ?? 1 : 1, p.length > 3 ? p[3] == '1' : false, p.length > 4 ? DateTime.tryParse(p[4]) ?? DateTime.now() : DateTime.now());
  }
  Item copy({bool? done}) => Item(title, category, qty, done ?? this.done, date);
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: appTitle,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: seed), scaffoldBackgroundColor: const Color(0xFFF6F8F7), fontFamily: 'Arial'),
    home: const Directionality(textDirection: TextDirection.rtl, child: Home()),
  );
}

class Home extends StatefulWidget { const Home({super.key}); @override State<Home> createState() => _HomeState(); }

class _HomeState extends State<Home> {
  int tab = 0;
  String filter = 'الكل';
  String category = 'بقالة';
  int qty = 1;
  bool reminders = true;
  TimeOfDay reminderTime = const TimeOfDay(hour: 18, minute: 0);
  final itemCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  List<Item> items = [];

  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getStringList('items_v3') ?? p.getStringList('items_v2');
    setState(() { items = (saved == null || saved.isEmpty) ? starter() : saved.map(Item.decode).toList(); reminders = p.getBool('reminders') ?? true; reminderTime = TimeOfDay(hour: p.getInt('reminder_h') ?? 18, minute: p.getInt('reminder_m') ?? 0); });
  }
  List<Item> starter() => [Item('خبز', 'بقالة', 1, false, DateTime.now()), Item('حليب', 'ألبان', 2, false, DateTime.now()), Item('خضار للسلطة', 'خضار', 1, true, DateTime.now())];
  Future<void> save() async { final p = await SharedPreferences.getInstance(); await p.setStringList('items_v3', items.map((e) => e.encode()).toList()); await p.setBool('reminders', reminders); await p.setInt('reminder_h', reminderTime.hour); await p.setInt('reminder_m', reminderTime.minute); }

  int get pending => items.where((e) => !e.done).length;
  int get done => items.where((e) => e.done).length;
  List<Item> get visible {
    final q = searchCtrl.text.trim();
    return items.where((e) {
      final f = filter == 'الكل' || (filter == 'المتبقي' && !e.done) || (filter == 'تم شراؤه' && e.done) || e.category == filter;
      final s = q.isEmpty || e.title.contains(q) || e.category.contains(q);
      return f && s;
    }).toList();
  }

  void addItem() {
    final title = itemCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() { items.insert(0, Item(title, category, qty, false, DateTime.now())); itemCtrl.clear(); qty = 1; });
    save();
    SystemSound.play(SystemSoundType.click);
  }
  void toggle(Item item) { final i = items.indexOf(item); if (i < 0) return; setState(() => items[i] = items[i].copy(done: !items[i].done)); save(); }
  void deleteItem(Item item) { final i = items.indexOf(item); setState(() => items.remove(item)); save(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حذف ${item.title}'), action: SnackBarAction(label: 'تراجع', onPressed: () { setState(() => items.insert(i < 0 ? 0 : i, item)); save(); }))); }
  void copyList() { final text = items.map((e) => '${e.done ? '✓' : '○'} ${e.title} - ${e.category} - العدد ${e.qty}').join('\n'); Clipboard.setData(ClipboardData(text: text)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ القائمة'))); }

  @override Widget build(BuildContext context) { final pages = [dashboard(), listPage(), historyPage(), settingsPage(), aboutPage()]; return Scaffold(body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: pages[tab])), bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [NavigationDestination(icon: Icon(Icons.home_rounded), label: 'الرئيسية'), NavigationDestination(icon: Icon(Icons.playlist_add_check_rounded), label: 'القائمة'), NavigationDestination(icon: Icon(Icons.history_rounded), label: 'السجل'), NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'الإعدادات'), NavigationDestination(icon: Icon(Icons.info_rounded), label: 'عن')])); }

  Widget dashboard() => ListView(padding: const EdgeInsets.all(16), children: [hero(), const SizedBox(height: 14), Row(children: [Expanded(child: stat('المتبقي', '$pending', Icons.shopping_cart_checkout_rounded)), const SizedBox(width: 10), Expanded(child: stat('المكتمل', '$done', Icons.verified_rounded))]), const SizedBox(height: 14), section('إضافة سريعة'), addCard(compact: true), const SizedBox(height: 14), section('آخر العناصر'), if (items.isEmpty) empty('لا توجد عناصر بعد'), ...items.take(4).map(tile)]);
  Widget listPage() => ListView(padding: const EdgeInsets.all(16), children: [pageHeader('القائمة الأساسية', 'أضف، ابحث، وصنف مشترياتك بسهولة.'), addCard(compact: false), const SizedBox(height: 12), TextField(controller: searchCtrl, onChanged: (_) => setState(() {}), decoration: input('بحث داخل القائمة', Icons.search_rounded)), const SizedBox(height: 12), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['الكل', 'المتبقي', 'تم شراؤه', 'بقالة', 'ألبان', 'خضار', 'منزل', 'أخرى'].map((f) => Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(f), selected: filter == f, onSelected: (_) => setState(() => filter = f)))).toList())), const SizedBox(height: 12), if (visible.isEmpty) empty('لا توجد عناصر مطابقة'), ...visible.map(tile)]);
  Widget historyPage() => ListView(padding: const EdgeInsets.all(16), children: [pageHeader('السجل والمحفوظات', 'تابع ما تم شراؤه وانسخ القائمة.'), progressCard(), const SizedBox(height: 12), FilledButton.icon(onPressed: items.isEmpty ? null : copyList, icon: const Icon(Icons.copy_all_rounded), label: const Text('نسخ القائمة')), const SizedBox(height: 12), ...items.where((e) => e.done).map(tile), if (done == 0) empty('لم يتم تعليم أي عنصر كمكتمل بعد')]);
  Widget settingsPage() => ListView(padding: const EdgeInsets.all(16), children: [pageHeader('الإعدادات', 'تحكم بطريقة استخدام التطبيق.'), card(SwitchListTile(value: reminders, onChanged: (v) { setState(() => reminders = v); save(); }, title: const Text('تذكير التسوق'), subtitle: Text(reminders ? 'مفعل عند ${reminderTime.format(context)}' : 'متوقف'), secondary: const Icon(Icons.notifications_active_rounded))), const SizedBox(height: 10), card(ListTile(leading: const Icon(Icons.schedule_rounded), title: const Text('وقت التذكير'), subtitle: Text(reminderTime.format(context)), trailing: const Icon(Icons.chevron_left_rounded), onTap: () async { final t = await showTimePicker(context: context, initialTime: reminderTime); if (t != null) { setState(() => reminderTime = t); save(); } })), const SizedBox(height: 10), card(ListTile(leading: const Icon(Icons.cleaning_services_rounded), title: const Text('حذف العناصر المكتملة'), subtitle: const Text('يبقي القائمة خفيفة ومنظمة'), onTap: () { setState(() => items.removeWhere((e) => e.done)); save(); }))]);
  Widget aboutPage() => ListView(padding: const EdgeInsets.all(16), children: [pageHeader('عن التطبيق', 'هوية احترافية وتجربة عربية بالكامل.'), card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('$appTitle $appVersion', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 8), const Text('تنظيم مشترياتك اليومية مع بحث، تصنيفات، سجل، نسخ للقائمة، وحفظ محلي مع قراءة بيانات V2 القديمة.'), const SizedBox(height: 12), const SelectableText(developerEmail)]))]);

  Widget hero() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF047857)], begin: Alignment.topRight, end: Alignment.bottomLeft), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: seed.withValues(alpha: .22), blurRadius: 24, offset: const Offset(0, 12))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text(appTitle, style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 6), const Text('V3 - قائمة مرتبة وسريعة للتسوق اليومي', style: TextStyle(color: Colors.white70)), const SizedBox(height: 18), LinearProgressIndicator(value: items.isEmpty ? 0 : done / items.length, minHeight: 12, backgroundColor: Colors.white24, color: Colors.white, borderRadius: BorderRadius.circular(18))]));
  Widget addCard({required bool compact}) => card(Column(children: [TextField(controller: itemCtrl, textInputAction: TextInputAction.done, onSubmitted: (_) => addItem(), decoration: input('اسم الغرض', Icons.add_shopping_cart_rounded)), if (!compact) const SizedBox(height: 8), if (!compact) Row(children: [Expanded(child: DropdownButtonFormField<String>(value: category, decoration: input('التصنيف', Icons.category_rounded), items: ['بقالة', 'ألبان', 'خضار', 'منزل', 'أخرى'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => category = v ?? category))), const SizedBox(width: 10), SizedBox(width: 92, child: DropdownButtonFormField<int>(value: qty, decoration: input('العدد', Icons.numbers_rounded), items: List.generate(9, (i) => i + 1).map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(), onChanged: (v) => setState(() => qty = v ?? 1)))]), const SizedBox(height: 10), Align(alignment: AlignmentDirectional.centerEnd, child: FilledButton.icon(onPressed: addItem, icon: const Icon(Icons.add_rounded), label: const Text('إضافة')))]));
  Widget tile(Item e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: card(Row(children: [Checkbox(value: e.done, onChanged: (_) => toggle(e)), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, decoration: e.done ? TextDecoration.lineThrough : null)), const SizedBox(height: 3), Text('${e.category} • العدد ${e.qty} • ${date(e.date)}', style: TextStyle(color: Colors.grey.shade700))])), IconButton(onPressed: () => deleteItem(e), icon: const Icon(Icons.delete_outline_rounded))])));
  Widget progressCard() => card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('نسبة الإنجاز', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(items.isEmpty ? '0%' : '${((done / items.length) * 100).round()}%', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)), const SizedBox(height: 8), LinearProgressIndicator(value: items.isEmpty ? 0 : done / items.length, minHeight: 10, borderRadius: BorderRadius.circular(20))]));
  Widget stat(String title, String value, IconData icon) => card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: seed), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), Text(title)]));
  Widget pageHeader(String title, String sub) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(sub, style: TextStyle(color: Colors.grey.shade700))]));
  Widget section(String s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(s, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)));
  Widget empty(String text) => card(Center(child: Padding(padding: const EdgeInsets.all(10), child: Text(text, style: TextStyle(color: Colors.grey.shade700)))));
  InputDecoration input(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none));
  Widget card(Widget child) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .055), blurRadius: 22, offset: const Offset(0, 10))]), child: child);
  String date(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

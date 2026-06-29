import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const ShoppingProApp());

const String appTitle = 'قائمة المشتريات';
const String appVersion = 'V2';
const String developerEmail = 'fastunlocked2017@gmail.com';
const Color seedColor = Color(0xFF16A34A);

class ShoppingItem {
  final String title;
  final String category;
  final int qty;
  final bool done;
  final DateTime createdAt;

  const ShoppingItem({required this.title, required this.category, required this.qty, required this.done, required this.createdAt});

  String encode() => [title, category, qty.toString(), done ? '1' : '0', createdAt.toIso8601String()].join('|||');

  static ShoppingItem decode(String raw) {
    final p = raw.split('|||');
    return ShoppingItem(
      title: p.isNotEmpty ? p[0] : 'عنصر',
      category: p.length > 1 ? p[1] : 'عام',
      qty: p.length > 2 ? int.tryParse(p[2]) ?? 1 : 1,
      done: p.length > 3 ? p[3] == '1' : false,
      createdAt: p.length > 4 ? DateTime.tryParse(p[4]) ?? DateTime.now() : DateTime.now(),
    );
  }

  ShoppingItem copyWith({String? title, String? category, int? qty, bool? done}) => ShoppingItem(
    title: title ?? this.title,
    category: category ?? this.category,
    qty: qty ?? this.qty,
    done: done ?? this.done,
    createdAt: createdAt,
  );
}

class ShoppingProApp extends StatelessWidget {
  const ShoppingProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appTitle,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
        fontFamily: 'Arial',
        cardTheme: CardThemeData(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
      ),
      home: const Directionality(textDirection: TextDirection.rtl, child: SplashScreen()),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: HomeScreen())));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF065F46)], begin: Alignment.topRight, end: Alignment.bottomLeft)),
        child: SafeArea(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 104, height: 104, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(34), border: Border.all(color: Colors.white.withValues(alpha: .28))), child: const Text('🛒', style: TextStyle(fontSize: 54))),
            const SizedBox(height: 22),
            const Text(appTitle, style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('تنظيم ذكي لمشترياتك اليومية', style: TextStyle(color: Colors.white.withValues(alpha: .86), fontSize: 16)),
            const SizedBox(height: 36),
            const SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)),
          ]),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  String filter = 'الكل';
  bool reminders = true;
  TimeOfDay reminderTime = const TimeOfDay(hour: 18, minute: 0);
  final TextEditingController itemCtrl = TextEditingController();
  final TextEditingController searchCtrl = TextEditingController();
  String category = 'بقالة';
  int qty = 1;
  List<ShoppingItem> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getStringList('items_v2');
    setState(() {
      items = (saved == null || saved.isEmpty) ? _starter() : saved.map(ShoppingItem.decode).toList();
      reminders = p.getBool('reminders') ?? true;
      final h = p.getInt('reminder_h') ?? 18;
      final m = p.getInt('reminder_m') ?? 0;
      reminderTime = TimeOfDay(hour: h, minute: m);
    });
  }

  List<ShoppingItem> _starter() => [
    ShoppingItem(title: 'خبز', category: 'بقالة', qty: 1, done: false, createdAt: DateTime.now()),
    ShoppingItem(title: 'حليب', category: 'ألبان', qty: 2, done: false, createdAt: DateTime.now()),
    ShoppingItem(title: 'خضار للسلطة', category: 'خضار', qty: 1, done: true, createdAt: DateTime.now()),
  ];

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('items_v2', items.map((e) => e.encode()).toList());
    await p.setBool('reminders', reminders);
    await p.setInt('reminder_h', reminderTime.hour);
    await p.setInt('reminder_m', reminderTime.minute);
  }

  void _tap([bool alert = false]) => SystemSound.play(alert ? SystemSoundType.alert : SystemSoundType.click);

  void _addItem() {
    final title = itemCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() {
      items.insert(0, ShoppingItem(title: title, category: category, qty: qty, done: false, createdAt: DateTime.now()));
      itemCtrl.clear();
      qty = 1;
    });
    _save();
    _tap();
  }

  void _toggle(int i) {
    setState(() => items[i] = items[i].copyWith(done: !items[i].done));
    _save();
    _tap();
  }

  void _delete(int i) {
    final removed = items[i];
    setState(() => items.removeAt(i));
    _save();
    _tap(true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حذف ${removed.title}'), action: SnackBarAction(label: 'تراجع', onPressed: () { setState(() => items.insert(i, removed)); _save(); })));
  }

  int get pending => items.where((e) => !e.done).length;
  int get done => items.where((e) => e.done).length;

  List<ShoppingItem> get visibleItems {
    final q = searchCtrl.text.trim();
    return items.where((e) {
      final matchFilter = filter == 'الكل' || (filter == 'المتبقي' && !e.done) || (filter == 'تم شراؤه' && e.done) || e.category == filter;
      final matchSearch = q.isEmpty || e.title.contains(q) || e.category.contains(q);
      return matchFilter && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_dashboard(), _listPage(), _historyPage(), _settingsPage(), _aboutPage()];
    return Scaffold(
      body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: pages[index])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) { setState(() => index = v); _tap(); },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.playlist_add_check_rounded), label: 'القائمة'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'السجل'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'الإعدادات'),
          NavigationDestination(icon: Icon(Icons.info_rounded), label: 'عن'),
        ],
      ),
    );
  }

  Widget _dashboard() => ListView(padding: const EdgeInsets.all(16), children: [
    _hero(),
    const SizedBox(height: 14),
    Row(children: [Expanded(child: _stat('المتبقي', '$pending', Icons.shopping_cart_checkout_rounded)), const SizedBox(width: 10), Expanded(child: _stat('المكتمل', '$done', Icons.verified_rounded))]),
    const SizedBox(height: 14),
    _sectionTitle('إضافة سريعة'),
    _addCard(compact: true),
    const SizedBox(height: 14),
    _sectionTitle('آخر العناصر'),
    ...items.take(4).map((e) => _itemTile(items.indexOf(e))),
  ]);

  Widget _listPage() => ListView(padding: const EdgeInsets.all(16), children: [
    _pageHeader('القائمة الأساسية', 'أضف، ابحث، وصنف مشترياتك بسهولة.'),
    _addCard(compact: false),
    const SizedBox(height: 12),
    TextField(controller: searchCtrl, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: 'بحث داخل القائمة', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none))),
    const SizedBox(height: 12),
    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['الكل', 'المتبقي', 'تم شراؤه', 'بقالة', 'ألبان', 'خضار', 'منزل'].map((f) => Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(f), selected: filter == f, onSelected: (_) => setState(() => filter = f)))).toList())),
    const SizedBox(height: 12),
    if (visibleItems.isEmpty) _emptyCard('لا توجد عناصر مطابقة الآن.'),
    ...visibleItems.map((e) => _itemTile(items.indexOf(e))),
  ]);

  Widget _historyPage() => ListView(padding: const EdgeInsets.all(16), children: [
    _pageHeader('السجل والمحفوظات', 'تابع ما أضفته وما تم شراؤه.'),
    _progressCard(),
    const SizedBox(height: 12),
    ...items.where((e) => e.done).map((e) => _historyTile(e)),
    if (done == 0) _emptyCard('لم يتم تعليم أي عنصر كمكتمل بعد.'),
  ]);

  Widget _settingsPage() => ListView(padding: const EdgeInsets.all(16), children: [
    _pageHeader('الإعدادات', 'تحكم بطريقة استخدام التطبيق.'),
    ProCard(child: SwitchListTile(
      value: reminders,
      onChanged: (v) { setState(() => reminders = v); _save(); },
      title: const Text('تذكير التسوق'),
      subtitle: Text(reminders ? 'مفعل عند ${reminderTime.format(context)}' : 'متوقف'),
      secondary: const Icon(Icons.notifications_active_rounded),
    )),
    const SizedBox(height: 10),
    ProCard(child: ListTile(leading: const Icon(Icons.schedule_rounded), title: const Text('وقت التذكير'), subtitle: Text(reminderTime.format(context)), trailing: const Icon(Icons.chevron_left_rounded), onTap: () async { final t = await showTimePicker(context: context, initialTime: reminderTime); if (t != null) { setState(() => reminderTime = t); _save(); } })),
    const SizedBox(height: 10),
    ProCard(child: ListTile(leading: const Icon(Icons.cleaning_services_rounded), title: const Text('حذف العناصر المكتملة'), subtitle: const Text('يبقي القائمة خفيفة ومنظمة'), onTap: () { setState(() => items.removeWhere((e) => e.done)); _save(); })),
  ]);

  Widget _aboutPage() => ListView(padding: const EdgeInsets.all(16), children: [
    _pageHeader('عن التطبيق', 'هوية احترافية وتجربة عربية بالكامل.'),
    ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 58, height: 58, alignment: Alignment.center, decoration: BoxDecoration(color: seedColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(18)), child: const Text('🛒', style: TextStyle(fontSize: 30))), const SizedBox(width: 12), const Expanded(child: Text('$appTitle $appVersion', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)))]),
      const SizedBox(height: 12),
      const Text('تطبيق بسيط واحترافي لتنظيم مشترياتك اليومية، مع بحث، تصنيفات، سجل، وإعدادات مناسبة للاستخدام اليومي.'),
    ])),
    const SizedBox(height: 12),
    ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('مراسلة المطور', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      const SelectableText(developerEmail),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: () { Clipboard.setData(const ClipboardData(text: 'السلام عليكم، لدي ملاحظة حول تطبيق قائمة المشتريات:\n\nالبريد: fastunlocked2017@gmail.com')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رسالة المطور'))); }, icon: const Icon(Icons.copy_all_rounded), label: const Text('نسخ الرسالة للمطور')),
    ])),
  ]);

  Widget _hero() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF047857)], begin: Alignment.topRight, end: Alignment.bottomLeft), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: seedColor.withValues(alpha: .22), blurRadius: 24, offset: const Offset(0, 12))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 64, height: 64, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(22)), child: const Text('🛒', style: TextStyle(fontSize: 34))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text(appTitle, style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('قائمة مرتبة، سريعة، ومناسبة للتسوق اليومي', style: TextStyle(color: Colors.white.withValues(alpha: .86)))]))]),
      const SizedBox(height: 18),
      ClipRRect(borderRadius: BorderRadius.circular(18), child: LinearProgressIndicator(value: items.isEmpty ? 0 : done / items.length, minHeight: 12, backgroundColor: Colors.white.withValues(alpha: .22), color: Colors.white)),
    ]),
  );

  Widget _addCard({required bool compact}) => ProCard(child: Column(children: [
    Row(children: [Expanded(child: TextField(controller: itemCtrl, textInputAction: TextInputAction.done, onSubmitted: (_) => _addItem(), decoration: const InputDecoration(labelText: 'اسم الغرض', border: InputBorder.none))), const SizedBox(width: 8), FilledButton.icon(onPressed: _addItem, icon: const Icon(Icons.add_rounded), label: Text(compact ? 'أضف' : 'إضافة'))]),
    if (!compact) const SizedBox(height: 8),
    if (!compact) Row(children: [Expanded(child: DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'التصنيف'), items: ['بقالة', 'ألبان', 'خضار', 'منزل', 'أخرى'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => category = v ?? category))), const SizedBox(width: 10), SizedBox(width: 92, child: DropdownButtonFormField<int>(value: qty, decoration: const InputDecoration(labelText: 'العدد'), items: List.generate(9, (i) => i + 1).map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(), onChanged: (v) => setState(() => qty = v ?? 1)))])
  ]));

  Widget _itemTile(int i) {
    final e = items[i];
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: ProCard(child: Row(children: [
      Checkbox(value: e.done, onChanged: (_) => _toggle(i)),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, decoration: e.done ? TextDecoration.lineThrough : null)), const SizedBox(height: 3), Text('${e.category} • العدد ${e.qty}', style: TextStyle(color: Colors.grey.shade700))])),
      IconButton(onPressed: () => _delete(i), icon: const Icon(Icons.delete_outline_rounded)),
    ])));
  }

  Widget _historyTile(ShoppingItem e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: ProCard(child: ListTile(leading: const Icon(Icons.check_circle_rounded, color: seedColor), title: Text(e.title), subtitle: Text('${e.category} • ${_date(e.createdAt)}'))));
  Widget _progressCard() => ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('نسبة الإنجاز', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(items.isEmpty ? '0%' : '${((done / items.length) * 100).round()}%', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)), const SizedBox(height: 8), LinearProgressIndicator(value: items.isEmpty ? 0 : done / items.length, minHeight: 10, borderRadius: BorderRadius.circular(20))]));
  Widget _stat(String title, String value, IconData icon) => ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: seedColor), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), Text(title)]));
  Widget _pageHeader(String title, String sub) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(sub, style: TextStyle(color: Colors.grey.shade700))]));
  Widget _sectionTitle(String s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(s, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)));
  Widget _emptyCard(String text) => ProCard(child: Center(child: Padding(padding: const EdgeInsets.all(10), child: Text(text, style: TextStyle(color: Colors.grey.shade700)))));
  String _date(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

class ProCard extends StatelessWidget {
  final Widget child;
  const ProCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .055), blurRadius: 22, offset: const Offset(0, 10))]),
    child: child,
  );
}

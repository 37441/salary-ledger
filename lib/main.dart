import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/calc.dart';
import 'src/pages/calendar_page.dart';
import 'src/pages/settings_page.dart';
import 'src/pages/stats_page.dart';
import 'src/pages/year_page.dart';
import 'src/storage.dart';
import 'src/theme.dart';
import 'src/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 状态栏常驻黑色背景 + 白色图标（刘海屏可读）。
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final store = AppStore();
  await store.load();
  runApp(SalaryLedgerApp(store: store));
}

class SalaryLedgerApp extends StatelessWidget {
  final AppStore store;

  const SalaryLedgerApp({super.key, required this.store});

  /// 根 Flutter 入口：跟随主题设置系统状态栏样式（浅色主题深图标，深色主题白图标）。
  static void applyStatusBarStyle(int theme) {
    final dark = AppThemes.isDark(theme);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: store.themeNotifier,
      builder: (context, theme, _) {
        applyStatusBarStyle(theme);
        return ValueListenableBuilder<double>(
          valueListenable: store.fontScaleNotifier,
          builder: (context, fs, _) {
            return AppState(
              theme: theme,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(fs),
                ),
                child: MaterialApp(
                  title: '薪时记账',
                  debugShowCheckedModeBanner: false,
                  theme: _buildTheme(theme),
                  home: SplashGate(store: store),
                ),
              ),
            );
          },
        );
      },
    );
  }

  ThemeData _buildTheme(int theme) {
    final primaryC = AppThemes.primary[theme];
    final pageC = AppThemes.page[theme];
    final dark = AppThemes.isDark(theme);
    return ThemeData(
      useMaterial3: false,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: pageC,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryC,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      appBarTheme: AppBarTheme(backgroundColor: pageC),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

/// 开屏动画：应用名缩放淡入，短暂展示后进入主页。
class SplashGate extends StatefulWidget {
  final AppStore store;

  const SplashGate({super.key, required this.store});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => HomePage(store: widget.store),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor(context),
      body: Center(
        child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) => Opacity(
                  opacity: scale.clamp(0.0, 1.0),
                  child: Transform.scale(scale: scale, child: child),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppThemes.primary[widget.store.theme],
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.payments, size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text('薪时记账',
                        style: TextStyle(
                            fontSize: 22,
                            color: textMain(context),
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
        ),
    );
  }
}

/// 主框架：顶部工具栏 + 内容区（带切换动画）+ 底部导航（4 项）。
class HomePage extends StatefulWidget {
  final AppStore store;

  const HomePage({super.key, required this.store});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late SalaryCalc _calc;
  final PageController _pageController = PageController();
  int _tab = 0;
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  bool _multiSelectMode = false;
  final Set<String> _selectedDates = <String>{};

  @override
  void initState() {
    super.initState();
    _calc = SalaryCalc(widget.store);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _changeMonth(int offset) {
    var m = _month + offset;
    var y = _year;
    if (m < 1) {
      m = 12;
      y--;
    } else if (m > 12) {
      m = 1;
      y++;
    }
    setState(() {
      _year = y;
      _month = m;
    });
  }

  void _changeYear(int offset) => setState(() => _year += offset);

  void _goToMonth(int month) {
    setState(() => _month = month);
    _pageController.animateToPage(1,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  void _toggleMultiSelect(bool enabled) {
    setState(() {
      _multiSelectMode = enabled;
      if (!enabled) _selectedDates.clear();
    });
  }

  /// 批量操作前自动结束多选（等同点击「完成」）。
  void _exitMultiSelect() {
    if (!_multiSelectMode && _selectedDates.isEmpty) return;
    setState(() {
      _multiSelectMode = false;
      _selectedDates.clear();
    });
  }

  void _updateSelection(Set<String> next) => setState(() {
        _selectedDates
          ..clear()
          ..addAll(next);
      });

  // —— 顶部标题 ——
  String get _title {
    switch (_tab) {
      case 0:
        return '月度小结';
      case 1:
        return '月度统计';
      case 2:
        return '整年总览';
      default:
        return '软件设置';
    }
  }

  String get _subtitle {
    if (_tab == 3) return '外观 · 工资 · 数据 · 导航栏';
    final s = _calc.summarizeMonth(_year, _month);
    switch (_tab) {
      case 0:
        return '加班 ${Fmt.hours(s.totalHours)}h  请假 ${Fmt.hours(s.leaveHours)}h';
      case 1:
        return '$_year年$_month月  加班 ${Fmt.hours(s.totalHours)} 小时  请假 ${Fmt.hours(s.leaveHours)} 小时';
      default:
        final ys = _calc.summarizeYear(_year);
        return '$_year 年  总加班 ${Fmt.hours(ys.hours)} 小时';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor(context),
      // 键盘弹出时不收缩/移动主页布局（顶栏保持原位；弹窗在 Overlay 自行处理）
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  _toolbar(),
                  Expanded(child: _pageStack()),
                ],
              ),
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: _navBar()),
          ],
        ),
      ),
    );
  }

  /// 四个页签内容：PageView（只布局当前可见页，键盘弹出/切页均不牵动隐藏页，120Hz 流畅）。
  Widget _pageStack() {
    return PageView(
      controller: _pageController,
      physics: const ClampingScrollPhysics(),
      onPageChanged: (i) {
        if (_tab != i) setState(() => _tab = i);
      },
      children: [
        for (var i = 0; i < 4; i++) RepaintBoundary(child: _pageFor(i)),
      ],
    );
  }

  Widget _pageFor(int i) {
    switch (i) {
      case 0:
        return CalendarPage(
          store: widget.store,
          calc: _calc,
          year: _year,
          month: _month,
          multiSelectMode: _multiSelectMode,
          selectedDates: _selectedDates,
          onMonthChange: _changeMonth,
          onRefresh: _refresh,
          onMultiSelectToggle: _toggleMultiSelect,
          onSelectionChange: _updateSelection,
          onExitMultiSelect: _exitMultiSelect,
        );
      case 1:
        return StatsPage(
          store: widget.store,
          calc: _calc,
          year: _year,
          month: _month,
          onMonthChange: _changeMonth,
          onRefresh: _refresh,
        );
      case 2:
        return YearPage(
          store: widget.store,
          calc: _calc,
          year: _year,
          onYearChange: _changeYear,
          onMonthSelected: _goToMonth,
          onRefresh: _refresh,
        );
      default:
        return SettingsPage(store: widget.store);
    }
  }

  /// 顶栏：背景跟随主题，内容延伸到状态栏（edge-to-edge），
  /// padding-top 适配状态栏（刘海）高度，避免与系统栏重叠。
  Widget _toolbar() {
    final tm = textMain(context);
    final mtd = textMuted(context);
    final subtitle = _subtitle;
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 10),
      decoration: BoxDecoration(color: pageColor(context)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(_title,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 22,
                          color: tm,
                          fontWeight: FontWeight.w700)),
                ),
                if (subtitle.isNotEmpty)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: mtd)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 底部悬浮胶囊导航（参考设计图 2）：白卡 + 弥散阴影 + 选中圆形高亮。
  Widget _navBar() {
    final items = [
      ('日历', Icons.calendar_month),
      ('统计', Icons.pie_chart),
      ('整年', Icons.event_note),
      ('设置', Icons.settings_outlined),
    ];
    final content = Row(
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _pageController.animateToPage(i,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: i == _tab
                          ? softPrimary(context)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      items[i].$2,
                      size: 22,
                      color: i == _tab ? primary(context) : textMuted(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      items[i].$1,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11,
                        color: i == _tab ? primary(context) : textMuted(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    final glass = widget.store.glassNav;
    final panel = panelColor(context);
    final bar = ValueListenableBuilder<double>(
      valueListenable: widget.store.glassOpacityNotifier,
      builder: (_, opacity, __) => Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        color: glass ? panel.withValues(alpha: opacity) : panel,
        child: content,
      ),
    );

    final capsule = Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme(context)
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: glass
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: bar,
              )
            : bar,
      ),
    );
    return capsule;
  }
}
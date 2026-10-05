import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salary_ledger/main.dart';
import 'package:salary_ledger/src/pages/settings_page.dart';
import 'package:salary_ledger/src/storage.dart';

void main() {
  testWidgets('主页与设置页冒烟测试', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    await store.load();
    await tester.pumpWidget(SalaryLedgerApp(store: store));
    // 等开屏动画结束进入主页
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 打开设置页
    final ctx = tester.element(find.byType(HomePage));
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => SettingsPage(store: store)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('软件设置'), findsOneWidget);
  });
}

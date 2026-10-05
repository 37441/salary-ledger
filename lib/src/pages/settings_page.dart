import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../dialogs.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets.dart';

/// 设置页：主题 / 工资设置 / 字体大小 / 文件导出导入 / 液态玻璃开关。
class SettingsPage extends StatefulWidget {
  final AppStore store;

  const SettingsPage({super.key, required this.store});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  AppStore get store => widget.store;

  @override
  bool get wantKeepAlive => true;

  void _save() {
    store.save();
    setState(() {});
  }

  void _toast(String msg) => showAppToast(context, msg);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle('外观'),
                        _themeBox(),
                        const Divider(height: 20),
                        _sectionTitle('字体大小'),
                        _fontScaleBox(),
                      ],
                    ),
                  ),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle('工资'),
                        _tile('工资设置', Icons.payments_outlined, () {
                          showSalaryDialog(
                            context: context,
                            store: store,
                            onChanged: _save,
                          );
                        }, subtitle: '底薪 / 绩效比例'),
                      ],
                    ),
                  ),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle('数据'),
                        _tile('导出数据', Icons.upload_file_outlined, () => _export(),
                            subtitle: '保存为 JSON 备份文件'),
                        const SizedBox(height: 4),
                        _tile('导入数据', Icons.download_outlined, () => _import(),
                            subtitle: '从备份文件恢复'),
                      ],
                    ),
                  ),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle('导航栏'),
                        _tile('液态玻璃导航栏', Icons.blur_on, () {}, isSwitch: true,
                            switchValue: store.glassNav,
                            onSwitchChanged: (v) {
                              store.glassNav = v;
                              _save();
                            }),
                        PanelText(
                          store.glassNav ? '开启：毛玻璃半透明效果' : '关闭：纯白/纯色背景',
                          size: 12,
                          color: textMuted(context),
                        ),
                      ],
                    ),
                  ),
                ],
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 13,
                color: textMuted(context),
                fontWeight: FontWeight.w600)),
      );

  Widget _themeBox() {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        for (var i = 0; i < AppThemes.names.length; i++)
          GestureDetector(
            onTap: () {
              store.theme = i;
              _save();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppThemes.primary[i],
                    shape: BoxShape.circle,
                    border: store.theme == i
                        ? Border.all(color: accent(context), width: 3)
                        : null,
                  ),
                  child: store.theme == i
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(AppThemes.names[i],
                    style: TextStyle(
                        fontSize: 10,
                        color: store.theme == i ? accent(context) : textMuted(context))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _fontScaleBox() {
    return Row(
      children: [
        PanelText('小', size: 12, color: textMuted(context)),
        Expanded(
          child: Slider(
            value: store.fontScale,
            min: 0.8,
            max: 1.4,
            divisions: 6,
            activeColor: accent(context),
            onChanged: (v) {
              store.fontScale = v;
              _save();
            },
          ),
        ),
        PanelText('大', size: 14, color: textMuted(context)),
        SizedBox(
          width: 44,
          child: Text('${(store.fontScale * 100).round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, color: textMain(context))),
        ),
      ],
    );
  }

  /// 设置项行：左浅蓝圆角图标块 + 标题/副标题 + 右箭头或开关（参考设计图 1）。
  static const Color _iconBg = Color(0xFFD8E3EE);
  static const Color _iconFg = Color(0xFF2B84BC);

  Widget _tile(String title, IconData icon, VoidCallback onTap,
      {String? subtitle, bool isSwitch = false, bool switchValue = false,
      ValueChanged<bool>? onSwitchChanged}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isSwitch ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: _iconFg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          color: textMain(context),
                          fontWeight: FontWeight.w500)),
                  if (subtitle != null)
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: textMuted(context))),
                ],
              ),
            ),
            if (isSwitch)
              Switch(
                value: switchValue,
                activeColor: accent(context),
                onChanged: onSwitchChanged,
              )
            else
              Icon(Icons.chevron_right, size: 20, color: textMuted(context)),
          ],
        ),
      ),
    );
  }

  /// 导出：调系统「保存为」对话框，文件名带时间戳。
  Future<void> _export() async {
    final now = DateTime.now();
    final stamp = '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
    final fileName = '薪时记账_备份_$stamp.json';
    final bytes = Uint8List.fromList(utf8.encode(store.exportData()));
    final path = await FilePicker.platform.saveFile(
      dialogTitle: '导出数据',
      fileName: fileName,
      bytes: bytes,
    );
    if (!mounted) return;
    if (path == null) {
      _toast('已取消导出');
    } else {
      _toast('已导出到：$path');
    }
  }

  /// 导入：调系统文件选择器，选择 JSON 备份恢复。
  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: '选择备份文件',
    );
    if (result == null) {
      if (mounted) _toast('已取消导入');
      return;
    }
    final f = result.files.single;
    String content;
    if (f.path != null) {
      content = await File(f.path!).readAsString();
    } else {
      content = utf8.decode(f.bytes!);
    }
    try {
      store.importData(content);
      await store.save();
      if (!mounted) return;
      _toast('导入成功');
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      _toast('导入失败：文件格式无效');
    }
  }

  static String two(int v) => v < 10 ? '0$v' : '$v';
}
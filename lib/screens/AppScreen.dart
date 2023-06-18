import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:pikapika/basic/config/Version.dart';
import 'package:pikapika/basic/config/WillPopNotice.dart';
import 'package:pikapika/screens/components/Badge.dart';
import '../basic/Common.dart';
import 'CategoriesScreen.dart';
import 'SpaceScreen.dart';

// MAIN UI 底部导航栏
class AppScreen extends StatefulWidget {
  const AppScreen({Key? key}) : super(key: key);

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  late StreamSubscription<String?> _linkSubscription;

  @override
  void initState() {
    versionEvent.subscribe(_onVersion);
    _linkSubscription = linkSubscript(context);
    super.initState();
    Future.delayed(Duration.zero, () async {
      versionPop(context);
      versionEvent.subscribe(_versionSub);
    });
  }

  @override
  void dispose() {
    versionEvent.unsubscribe(_onVersion);
    _linkSubscription.cancel();
    versionEvent.unsubscribe(_versionSub);
    super.dispose();
  }

  _versionSub(_) {
    versionPop(context);
  }

  void _onVersion(dynamic a) {
    setState(() {});
  }

  static const List<Widget> _widgetOptions = <Widget>[
    CategoriesScreen(),
    SpaceScreen(),
  ];

  late int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: '浏览',
          ),
          BottomNavigationBarItem(
            icon: Badged(
              child: const Icon(Icons.face),
              badge: latestVersion() == null ? null : "1",
            ),
            label: '我的',
          ),
        ],
        currentIndex: _selectedIndex,
        iconSize: 20,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: _onItemTapped,
      ),
    );
    return willPop(body);
  }

  int _noticeTime = 0;

  Widget willPop(Scaffold body) {
    return WillPopScope(
      child: body,
      onWillPop: () async {
        if (willPopNotice()) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (_noticeTime + 3000 > now) {
            return true;
          } else {
            _noticeTime = now;
            showToast(
              "再次返回将会退出应用程序",
              context: context,
              position: StyledToastPosition.center,
              animation: StyledToastAnimation.scale,
              reverseAnimation: StyledToastAnimation.fade,
              duration: const Duration(seconds: 3),
              animDuration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              reverseCurve: Curves.linear,
            );
            return false;
          }
        }
        return true;
      },
    );
  }
}

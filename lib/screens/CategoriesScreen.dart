import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart' as fsb;
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/config/ShadowCategoriesEvent.dart';
import 'package:pikapika/basic/config/ShadowCategoriesMode.dart';
import 'package:pikapika/basic/store/Categories.dart';
import 'package:pikapika/basic/config/ShadowCategories.dart';
import 'package:pikapika/screens/ComicCollectionsScreen.dart';
import 'package:pikapika/screens/RankingsScreen.dart';
import 'package:pikapika/screens/SearchScreen.dart';
import 'package:pikapika/screens/components/ContentError.dart';
import 'package:pikapika/basic/Method.dart';
import '../basic/config/Address.dart';
import '../basic/config/CategoriesColumnCount.dart';
import '../basic/config/IconLoading.dart';
import 'ComicsScreen.dart';
import 'GamesScreen.dart';
import 'RandomComicsScreen.dart';
import 'components/Common.dart';
import 'components/ContentLoading.dart';
import 'components/Images.dart';
import 'components/ListView.dart';

// 分类
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final fsb.SearchBar _searchBar = fsb.SearchBar(
    hintText: '搜索',
    inBar: false,
    setState: setState,
    onSubmitted: (value) {
      if (value.isNotEmpty) {
        Navigator.push(
          context,
          mixRoute(
            builder: (context) => SearchScreen(keyword: value),
          ),
        );
      }
    },
    buildDefaultAppBar: (BuildContext context) {
      return AppBar(
        title: const Text('分类'),
        actions: [
          commonPopMenu(context),
          addressPopMenu(context),
          _searchBar.getSearchAction(context),
        ],
      );
    },
  );

  late Future<List<Category>> _categoriesFuture = _fetch();

  Future<List<Category>> _fetch() async {
    List<Category> categories = await method.categories();
    storedCategories = [];
    for (var element in categories) {
      if (!element.isWeb) {
        storedCategories.add(element.title);
      }
    }
    return categories;
  }

  void _reloadCategories() {
    setState(() {
      this._categoriesFuture = _fetch();
    });
  }

  @override
  void initState() {
    shadowCategoriesEvent.subscribe(_onShadowChange);
    categoriesColumnCountEvent.subscribe(_setState);
    super.initState();
  }

  @override
  void dispose() {
    shadowCategoriesEvent.unsubscribe(_onShadowChange);
    categoriesColumnCountEvent.unsubscribe(_setState);
    super.dispose();
  }

  void _onShadowChange(EventArgs? args) {
    _reloadCategories();
  }

  _setState(_) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var themeBackground = theme.scaffoldBackgroundColor;
    var shadeBackground = Color.fromARGB(
      0x11,
      255 - themeBackground.red,
      255 - themeBackground.green,
      255 - themeBackground.blue,
    );
    return Scaffold(
      appBar: _searchBar.build(context),
      body: Container(
        color: shadeBackground,
        child: FutureBuilder(
          future: _categoriesFuture,
          builder:
              ((BuildContext context, AsyncSnapshot<List<Category>> snapshot) {
            if (snapshot.hasError) {
              return ContentError(
                error: snapshot.error,
                stackTrace: snapshot.stackTrace,
                onRefresh: () async {
                  _reloadCategories();
                },
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const ContentLoading(label: '加载中');
            }
            return PikaListView(
              children: [
                Container(height: 20),
                Wrap(
                  runSpacing: 20,
                  alignment: WrapAlignment.spaceAround,
                  children: _buildChannels(),
                ),
                const Divider(),
                Wrap(
                  runSpacing: 20,
                  alignment: WrapAlignment.spaceAround,
                  children: _buildCategories(snapshot.data!),
                ),
                Container(height: 20),
              ],
            );
          }),
        ),
      ),
    );
  }

  List<Widget> _buildCategories(List<Category> cList) {
    late double blockSize;
    late double imageSize;
    late double imageRs;

    if (categoriesColumnCount == 0) {
      var size = MediaQuery.of(context).size;
      var min = size.width < size.height ? size.width : size.height;
      blockSize = (min ~/ 3).floorToDouble();
    } else {
      var size = MediaQuery.of(context).size;
      var min = size.width;
      blockSize = (min ~/ categoriesColumnCount).floorToDouble();
    }

    imageSize = blockSize - 15;
    imageRs = imageSize / 10;

    List<Widget> list = [];

    append(Widget widget, String title, Function() onTap) {
      list.add(
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: blockSize,
            child: Column(
              children: [
                Card(
                  elevation: .5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(imageRs)),
                    child: widget,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(imageRs)),
                  ),
                ),
                Container(height: 5),
                Center(
                  child: Text(title),
                ),
              ],
            ),
          ),
        ),
      );
    }

    append(
      buildSvg('lib/assets/books.svg', imageSize, imageSize, margin: 20),
      "全分类",
      () => _navigateToCategory(null),
    );

    append(
      Icon(
        Icons.recommend_outlined,
        size: imageSize,
        color: Colors.grey,
      ),
      "推荐",
      () {
        Navigator.push(
          context,
          mixRoute(
            builder: (context) => const ComicCollectionsScreen(),
          ),
        );
      },
    );

    for (var i = 0; i < cList.length; i++) {
      var c = cList[i];
      if (c.isWeb) continue;
      switch (currentShadowCategoriesMode()) {
        case ShadowCategoriesMode.BLACK_LIST:
          if (shadowCategories.contains(c.title)) continue;
          break;
        case ShadowCategoriesMode.WHITE_LIST:
          if (!shadowCategories.contains(c.title)) continue;
          break;
      }
      append(
        RemoteImage(
          fileServer: c.thumb.fileServer,
          path: c.thumb.path,
          width: imageSize,
          height: imageSize,
        ),
        c.title,
        () => _navigateToCategory(c.title),
      );
    }

    return list;
  }

  List<Widget> _buildChannels() {
    late double blockSize;
    late double imageSize;
    late double imageRs;

    if (categoriesColumnCount == 0) {
      var size = MediaQuery.of(context).size;
      var min = size.width < size.height ? size.width : size.height;
      blockSize = (min ~/ 3).floorToDouble();
    } else {
      var size = MediaQuery.of(context).size;
      var min = size.width;
      blockSize = (min ~/ categoriesColumnCount).floorToDouble();
    }

    imageSize = blockSize - 15;
    imageRs = imageSize / 10;

    List<Widget> list = [];

    append(Widget widget, String title, Function() onTap) {
      list.add(
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: blockSize,
            child: Column(
              children: [
                Card(
                  elevation: .5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(imageRs)),
                    child: widget,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(imageRs)),
                  ),
                ),
                Container(height: 5),
                Center(
                  child: Text(title),
                ),
              ],
            ),
          ),
        ),
      );
    }

    append(
      buildSvg('lib/assets/rankings.svg', imageSize, imageSize,
          margin: 20, color: Colors.red.shade700),
      "排行榜",
      () {
        Navigator.push(
          context,
          mixRoute(builder: (context) => const RankingsScreen()),
        );
      },
    );

    append(
      buildSvg('lib/assets/random.svg', imageSize, imageSize,
          margin: 20, color: Colors.orangeAccent.shade700),
      "随机本子",
      () {
        Navigator.push(
          context,
          mixRoute(builder: (context) => const RandomComicsScreen()),
        );
      },
    );

    append(
      buildSvg('lib/assets/gamepad.svg', imageSize, imageSize,
          margin: 20, color: Colors.blue.shade500),
      "游戏专区",
      () {
        Navigator.push(
          context,
          mixRoute(builder: (context) => const GamesScreen()),
        );
      },
    );

    return list;
  }

  void _navigateToCategory(String? categoryTitle) {
    Navigator.push(
      context,
      mixRoute(
        builder: (context) => ComicsScreen(category: categoryTitle),
      ),
    );
  }
}

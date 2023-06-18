import 'dart:math';

import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/basic/config/ShadowCategories.dart';
import 'package:pikapika/basic/config/ListLayout.dart';
import 'package:pikapika/basic/config/ShadowCategoriesMode.dart';

import 'ComicInfoCard.dart';
import 'Images.dart';
import 'LinkToComicInfo.dart';
import 'ListView.dart';

class ComicListController {
  _ComicListState? _state;

  bool get selecting => _state?._selecting ?? false;

  set selecting(bool value) => _state?._setSelect(value);

  List<String> get selected => _state?._selected ?? [];

  selectAll() {
    _state?._selectAll();
  }
}

// 漫画列表页
class ComicList extends StatefulWidget {
  final Widget? appendWidget;
  final List<ComicSimple> comicList;
  final ScrollController? scrollController;
  final ComicListController? listController;

  const ComicList(
    this.comicList, {
    this.appendWidget,
    this.scrollController,
    Key? key,
    // required
    this.listController,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicListState();
}

class _ComicListState extends State<ComicList> {
  final List<String> viewedList = [];
  bool _selecting = false;
  List<String> _selected = [];

  _selectAll() {
    setState(() {
      if (_selected.length == widget.comicList.length) {
        _selected.clear();
      } else {
        _selected.addAll(widget.comicList.map((e) => e.id));
      }
    });
  }

  _setSelect(bool value) {
    setState(() {
      _selected.clear();
      _selecting = value;
    });
  }

  Future _loadViewed() async {
    if (widget.comicList.isNotEmpty) {
      viewedList.addAll(await method
          .loadViewedList(widget.comicList.map((e) => e.id).toList()));
      setState(() {});
    }
  }

  @override
  void initState() {
    widget.listController?._state = this;
    _loadViewed();
    listLayoutEvent.subscribe(_onLayoutChange);
    super.initState();
  }

  @override
  void dispose() {
    if (widget.listController?._state == this) {
      widget.listController?._state = null;
    }
    listLayoutEvent.unsubscribe(_onLayoutChange);
    super.dispose();
  }

  void _onLayoutChange(EventArgs? args) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    switch (currentLayout) {
      case ListLayout.INFO_CARD:
        return _buildInfoCardList();
      case ListLayout.ONLY_IMAGE:
        return _buildGridImageWarp();
      case ListLayout.COVER_AND_TITLE:
        return _buildGridImageTitleWarp();
      default:
        return Container();
    }
  }

  Widget _buildInfoCardList() {
    return PikaListView(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ...widget.comicList.map((e) {
          late bool shadow;
          X:
          switch (currentShadowCategoriesMode()) {
            case ShadowCategoriesMode.BLACK_LIST:
              shadow = e.categories
                  .map((c) => shadowCategories.contains(c))
                  .reduce((value, element) => value || element);
              break;
            case ShadowCategoriesMode.WHITE_LIST:
              for (var c in e.categories) {
                if (shadowCategories.contains(c)) {
                  shadow = false;
                  break X;
                }
              }
              shadow = true;
              break;
          }
          if (shadow) {
            return InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    '被封印的本子',
                    style: TextStyle(
                      fontSize: 12,
                      color: (Theme.of(context).textTheme.bodyText1?.color ??
                              Colors.black)
                          .withOpacity(.3),
                    ),
                  ),
                ),
              ),
            );
          }
          if (_selecting) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (_selected.contains(e.id)) {
                    _selected.remove(e.id);
                  } else {
                    _selected.add(e.id);
                  }
                });
              },
              child: Stack(children: [
                AbsorbPointer(
                  child: LinkToComicInfo(
                    comicId: e.id,
                    child: ComicInfoCard(
                      e,
                      viewed: viewedList.contains(e.id),
                    ),
                  ),
                ),
                Row(children: [
                  Expanded(child: Container()),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      _selected.contains(e.id)
                          ? Icons.check_circle_sharp
                          : Icons.circle_outlined,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ]),
              ]),
            );
          }
          return LinkToComicInfo(
            comicId: e.id,
            child: ComicInfoCard(
              e,
              viewed: viewedList.contains(e.id),
            ),
          );
        }).toList(),
        ...widget.appendWidget != null
            ? [
                SizedBox(
                  height: 80,
                  child: widget.appendWidget,
                ),
              ]
            : [],
      ],
    );
  }

  Widget _buildGridImageWarp() {
    var gap = 3.0;
    var size = MediaQuery.of(context).size;
    var min = size.width < size.height ? size.width : size.height;
    var widthAndGap = min / 4;
    int rowCap = size.width ~/ widthAndGap;
    var width = widthAndGap - gap * 2;
    var height = width * coverHeight / coverWidth;
    List<Widget> wraps = [];
    List<Widget> tmp = [];
    for (var e in widget.comicList) {
      late bool shadow;
      X:
      switch (currentShadowCategoriesMode()) {
        case ShadowCategoriesMode.BLACK_LIST:
          shadow = e.categories
              .map((c) => shadowCategories.contains(c))
              .reduce((value, element) => value || element);
          break;
        case ShadowCategoriesMode.WHITE_LIST:
          for (var c in e.categories) {
            if (shadowCategories.contains(c)) {
              shadow = false;
              break X;
            }
          }
          shadow = true;
          break;
      }
      if (shadow) {
        tmp.add(
          Container(
            padding: EdgeInsets.all(gap),
            child: Container(
              width: width,
              height: height,
              color:
                  (Theme.of(context).textTheme.bodyText1?.color ?? Colors.black)
                      .withOpacity(.05),
              child: Center(
                child: Text(
                  '被封印的本子',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: (Theme.of(context).textTheme.bodyText1?.color ??
                            Colors.black)
                        .withOpacity(.5),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        tmp.add(LinkToComicInfo(
          comicId: e.id,
          child: Container(
            padding: EdgeInsets.all(gap),
            child: RemoteImage(
              fileServer: e.thumb.fileServer,
              path: e.thumb.path,
              width: width,
              height: height,
            ),
          ),
        ));
      }
      if (tmp.length == rowCap) {
        wraps.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tmp,
        ));
        tmp = [];
      }
    }
    // 追加特殊按钮
    if (widget.appendWidget != null) {
      tmp.add(Container(
        color:
            (Theme.of(context).textTheme.bodyText1?.color ?? Colors.transparent)
                .withOpacity(.1),
        margin: EdgeInsets.only(
          left: (rowCap - tmp.length) * gap,
          right: (rowCap - tmp.length) * gap,
          top: gap,
          bottom: gap,
        ),
        width: (rowCap - tmp.length) * width,
        height: height,
        child: widget.appendWidget,
      ));
    }
    // 最后一页没有下一页所有有可能为空
    if (tmp.isNotEmpty) {
      wraps.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tmp,
      ));
      tmp = [];
    }
    // 返回
    return PikaListView(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: gap, bottom: gap),
      children: wraps,
    );
  }

  Widget _buildGridImageTitleWarp() {
    var gap = 3.0;
    var size = MediaQuery.of(context).size;
    var min = size.width < size.height ? size.width : size.height;
    var widthAndGap = min / 3;
    int rowCap = size.width ~/ widthAndGap;
    var width = widthAndGap - gap * 2;
    var height = width * coverHeight / coverWidth;
    double titleFontSize = max(width / 11, 10);
    double shadowFontSize = max(width / 9, 12);
    List<Widget> wraps = [];
    List<Widget> tmp = [];
    for (var e in widget.comicList) {
      late bool shadow;
      X:
      switch (currentShadowCategoriesMode()) {
        case ShadowCategoriesMode.BLACK_LIST:
          shadow = e.categories
              .map((c) => shadowCategories.contains(c))
              .reduce((value, element) => value || element);
          break;
        case ShadowCategoriesMode.WHITE_LIST:
          for (var c in e.categories) {
            if (shadowCategories.contains(c)) {
              shadow = false;
              break X;
            }
          }
          shadow = true;
          break;
      }
      if (shadow) {
        tmp.add(
          Container(
            padding: EdgeInsets.all(gap),
            child: Container(
              width: width,
              height: height,
              color:
                  (Theme.of(context).textTheme.bodyText1?.color ?? Colors.black)
                      .withOpacity(.05),
              child: Center(
                child: Text(
                  '被封印的本子',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: shadowFontSize,
                    color: (Theme.of(context).textTheme.bodyText1?.color ??
                            Colors.black)
                        .withOpacity(.5),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        tmp.add(LinkToComicInfo(
          comicId: e.id,
          child: Container(
            margin: EdgeInsets.all(gap),
            width: width,
            height: height,
            child: Stack(
              children: [
                RemoteImage(
                  fileServer: e.thumb.fileServer,
                  path: e.thumb.path,
                  width: width,
                  height: height,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: Colors.black.withOpacity(.3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.title + '\n',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleFontSize,
                              height: 1.2,
                            ),
                            strutStyle: const StrutStyle(height: 1.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
      }
      if (tmp.length == rowCap) {
        wraps.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tmp,
        ));
        tmp = [];
      }
    }
    // 追加特殊按钮
    if (widget.appendWidget != null) {
      tmp.add(Container(
        color:
            (Theme.of(context).textTheme.bodyText1?.color ?? Colors.transparent)
                .withOpacity(.1),
        margin: EdgeInsets.only(
          left: (rowCap - tmp.length) * gap,
          right: (rowCap - tmp.length) * gap,
          top: gap,
          bottom: gap,
        ),
        width: (rowCap - tmp.length) * width,
        height: height,
        child: widget.appendWidget,
      ));
    }
    // 最后一页没有下一页所有有可能为空
    if (tmp.isNotEmpty) {
      wraps.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tmp,
      ));
      tmp = [];
    }
    // 返回
    return PikaListView(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: gap, bottom: gap),
      children: wraps,
    );
  }
}

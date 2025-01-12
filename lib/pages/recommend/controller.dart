import 'dart:developer';

import 'package:bili_you/common/models/local/home/recommend_item_info.dart';
import 'package:bili_you/common/utils/index.dart';
import 'package:bili_you/common/values/cache_keys.dart';
import 'package:bili_you/common/values/hero_tag_id.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
// import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'widgets/recommend_card.dart';
import 'package:bili_you/common/api/home_api.dart';

class RecommendController extends GetxController {
  RecommendController();
  List<Widget> recommendViewList = <Widget>[];

  ScrollController scrollController = ScrollController();
  EasyRefreshController refreshController = EasyRefreshController(
      controlFinishLoad: true, controlFinishRefresh: true);
  int refreshIdx = 0;
  CacheManager cacheManager =
      CacheManager(Config(CacheKeys.recommendItemCoverKey));
  int recommendColumnCount = 1;

  @override
  void onInit() {
    recommendColumnCount = BiliYouStorage.settings
        .get(SettingsStorageKeys.recommendColumnCount, defaultValue: 2);
    super.onInit();
  }

  // Function()? updateWidget;

  void animateToTop() {
    scrollController.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.linear);
  }

//加载并追加视频推荐
  Future<bool> _addRecommendItems() async {
    late List<RecommendVideoItemInfo> list;
    try {
      list =
          await HomeApi.getRecommendVideoItems(num: 16, refreshIdx: refreshIdx);
    } catch (e) {
      log("加载推荐视频失败:${e.toString()}");
      return false;
    }
    for (var i in list) {
      recommendViewList.add(RecommendCard(
          key: ValueKey("${i.bvid}:RecommendCard"),
          heroTagId: HeroTagId.id++,
          cacheManager: cacheManager,
          imageUrl: i.coverUrl,
          playNum: StringFormatUtils.numFormat(i.playNum),
          danmakuNum: StringFormatUtils.numFormat(i.danmakuNum),
          timeLength: StringFormatUtils.timeLengthFormat(i.timeLength),
          title: i.title,
          upName: i.upName,
          bvid: i.bvid,
          cid: i.cid));
    }
    refreshIdx += 1;
    return true;
  }

  Future<void> onRefresh() async {
    recommendViewList.clear();
    await cacheManager.emptyCache();
    if (await _addRecommendItems()) {
      refreshController.finishRefresh(IndicatorResult.success);
    } else {
      refreshController.finishRefresh(IndicatorResult.fail);
    }
  }

  Future<void> onLoad() async {
    if (await _addRecommendItems()) {
      refreshController.finishLoad(IndicatorResult.success);
      refreshController.resetFooter();
    } else {
      refreshController.finishLoad(IndicatorResult.fail);
    }
  }

  _initData() {
    // update(["recommend"]);
  }

  void onTap() {}

  // @override
  // void onInit() {
  //   super.onInit();
  // }

  @override
  void onReady() {
    super.onReady();
    _initData();
  }

  // @override
  // void onClose() {
  //   super.onClose();
  // }
}

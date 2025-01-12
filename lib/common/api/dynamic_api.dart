import 'package:bili_you/common/api/api_constants.dart';
import 'package:bili_you/common/models/local/dynamic/dynamic_author.dart';
import 'package:bili_you/common/models/local/dynamic/dynamic_content.dart';
import 'package:bili_you/common/models/local/dynamic/dynamic_item.dart';
import 'package:bili_you/common/models/local/dynamic/dynamic_stat.dart';
import 'package:bili_you/common/models/local/reply/official_verify.dart';
import 'package:bili_you/common/models/local/reply/reply_content.dart';
import 'package:bili_you/common/models/local/reply/reply_item.dart';
import 'package:bili_you/common/models/network/dynamic/dynamic.dart' as raw;
import 'package:bili_you/common/utils/index.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/local/reply/vip.dart';

class DynamicApi {
  static String _offset = "";
  static Future<raw.DynamicResponse> _requestDynamic(
      {required String type, required int page}) async {
    if (page == 1) {
      _offset = "";
    }
    var response = await MyDio.dio.get(
      ApiConstants.dynamicFeed,
      queryParameters: _offset.isEmpty
          ? {
              'type': type,
              'page': page,
            }
          : {'type': type, 'page': page, 'offset': _offset},
      options: Options(responseType: ResponseType.plain),
    );
    return await compute((message) async {
      return raw.DynamicResponse.fromRawJson(message);
    }, response.data);
  }

  static Future<List<DynamicItem>> getDynamicItems({required int page}) async {
    raw.DynamicResponse response =
        await _requestDynamic(type: "all", page: page);
    _offset = response.data?.offset ?? "";
    List<DynamicItem> list = [];
    if (response.code != 0) {
      throw "getDynamicItems: code:${response.code}, message:${response.message}";
    }
    if (response.data == null || response.data!.items == null) {
      return list;
    }
    for (var i in response.data!.items!) {
      var moduleAuthor = i.modules?.moduleAuthor;
      //构造DynamicAuthor
      DynamicAuthor dynamicAuthor = DynamicAuthor(
          avatarUrl: moduleAuthor?.face ?? "",
          name: moduleAuthor?.name ?? "",
          mid: moduleAuthor?.mid ?? 0,
          officialVerify: OfficialVerify(
              type: OfficialVerifyTypeCode.fromCode(
                  moduleAuthor?.officialVerify?.type ?? 0),
              description: moduleAuthor?.officialVerify?.desc ?? ""),
          vip: Vip(
              isVip: moduleAuthor?.vip?.status == 1,
              type: VipTypeCode.fromCode(moduleAuthor?.vip?.type ?? 0)),
          pubTime: moduleAuthor?.pubTime ?? "",
          pubAction: moduleAuthor?.pubAction ?? "");
      var moduleStat = i.modules?.moduleStat;
      //构造DynamicStat
      DynamicStat dynamicStat = DynamicStat(
          shareCount: moduleStat?.forward?.forbidden == false
              ? moduleStat?.forward?.count ?? 0
              : -1,
          replyCount: moduleStat?.comment?.forbidden == false
              ? moduleStat?.comment?.count ?? 0
              : -1,
          likeCount: moduleStat?.like?.forbidden == false
              ? moduleStat?.like?.count ?? 0
              : -1);
      var moduleDynamic = i.modules?.moduleDynamic;
      //构造DynamicContent
      late DynamicContent dynamicContent;
      //由于动态有不同类型,所以分各种情况进行构造
      switch (DynamicItemTypeCode.fromCode(i.type ?? "")) {
        case DynamicItemType.word:
          //消息
          dynamicContent = _buildWordDynamicContent(moduleDynamic);
          break;
        case DynamicItemType.article:
          //文章
          dynamicContent = _buildWordDynamicContent(moduleDynamic);
          break;
        case DynamicItemType.av:
          //视频投稿
          dynamicContent = AVDynamicContent(
              description: moduleDynamic?.desc?.text ?? '',
              emotes: _buildEmoteList(
                  moduleDynamic?.desc?.richTextNodes ?? <raw.RichTextNode>[]),
              picUrl: moduleDynamic?.major?.archive?.cover ?? '',
              bvid: moduleDynamic?.major?.archive?.bvid ?? '',
              title: moduleDynamic?.major?.archive?.title ?? '',
              subTitle: moduleDynamic?.major?.archive?.desc ?? '',
              duration: moduleDynamic?.major?.archive?.durationText ?? '',
              damakuCount: moduleDynamic?.major?.archive?.stat?.danmaku ?? '',
              playCount: moduleDynamic?.major?.archive?.stat?.play ?? '');

          break;
        case DynamicItemType.draw:
          //抽奖&互动
          dynamicContent = _buildWordDynamicContent(moduleDynamic);
          break;
        case DynamicItemType.liveRecommend:
          //直播推荐
          dynamicContent = _buildWordDynamicContent(moduleDynamic);
          break;
        case DynamicItemType.forward:
          //转发
          dynamicContent = _buildWordDynamicContent(moduleDynamic);
          break;
        case DynamicItemType.unkown:
          //未知
          dynamicContent = _buildWordDynamicContent(moduleDynamic);
          break;
      }
      list.add(DynamicItem(
          replyId: i.basic?.commentIdStr ?? '',
          replyType: ReplyTypeCode.fromCode(i.basic?.commentType ?? 0),
          author: dynamicAuthor,
          type: DynamicItemTypeCode.fromCode(i.type ?? ""),
          content: dynamicContent,
          stat: dynamicStat));
    }
    return list;
  }

  static List<Emote> _buildEmoteList(List<raw.RichTextNode> richTextNodes) {
    return [
      for (var i in richTextNodes)
        if (i.emoji != null)
          Emote(
              text: i.emoji?.text ?? '',
              url: i.emoji?.iconUrl ?? '',
              size: i.emoji?.size == 2 ? EmoteSize.big : EmoteSize.small)
    ];
  }

  static DynamicContent _buildWordDynamicContent(
      raw.ModuleDynamic? moduleDynamic) {
    return WordDynamicContent(
        description: moduleDynamic?.desc?.text ?? "",
        emotes: _buildEmoteList(
            moduleDynamic?.desc?.richTextNodes ?? <raw.RichTextNode>[]));
  }
}

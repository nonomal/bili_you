import 'package:bili_you/common/api/api_constants.dart';
import 'package:bili_you/common/models/local/related_video/related_video_info.dart';
import 'package:bili_you/common/models/network/related_video/related_video.dart';
import 'package:bili_you/common/utils/my_dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RelatedVideoApi {
  static Future<RelatedVideoResponse> _requestRelatedVideo(
      {required String bvid}) async {
    var dio = MyDio.dio;
    var response = await dio.get(ApiConstants.relatedVideo,
        queryParameters: {'bvid': bvid},
        options: Options(responseType: ResponseType.plain));
    var ret = await compute((data) {
      return RelatedVideoResponse.fromRawJson(data);
    }, response.data);
    return ret;
  }

  ///获取相关视频
  static Future<List<RelatedVideoInfo>> getRelatedVideo(
      {required String bvid}) async {
    List<RelatedVideoInfo> list = [];
    var response = await _requestRelatedVideo(bvid: bvid);
    if (response.code != 0) {
      throw "getRelatedVideo: code:${response.code}, message:${response.message}";
    }
    if (response.data == null) {
      return list;
    }
    for (var i in response.data!) {
      list.add(RelatedVideoInfo(
          coverUrl: i.pic ?? "",
          bvid: i.bvid ?? "",
          cid: i.cid ?? 0,
          title: i.title ?? "",
          upName: i.owner?.name ?? "",
          timeLength: i.duration ?? 0,
          playNum: i.stat?.view ?? 0,
          pubDate: i.pubdate ?? 0));
    }
    return list;
  }
}

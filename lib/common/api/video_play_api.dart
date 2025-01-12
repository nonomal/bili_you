import 'package:bili_you/common/api/api_constants.dart';
import 'package:bili_you/common/models/local/video/audio_play_item.dart';
import 'package:bili_you/common/models/local/video/video_play_info.dart';
import 'package:bili_you/common/models/local/video/video_play_item.dart';
import 'package:bili_you/common/models/network/video_play/video_play.dart';
import 'package:bili_you/common/utils/my_dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class VideoPlayApi {
  static Map<String, String> videoPlayerHttpHeaders = {
    'user-agent': ApiConstants.userAgent,
    'referer': ApiConstants.bilibiliBase
  };

  static Future<VideoPlayResponse> _requestVideoPlay(
      {required String bvid, required int cid, int fnval = 16}) async {
    var dio = MyDio.dio;
    var response = await dio.get(ApiConstants.videoPlay,
        queryParameters: {
          'bvid': bvid,
          'cid': cid,
          'fnver': 0,
          'fnval': fnval,
          'fourk': 1
        },
        options: Options(headers: {
          'user_agent': ApiConstants.userAgent,
        }, responseType: ResponseType.plain));
    var ret = await compute((data) async {
      return VideoPlayResponse.fromRawJson(data);
    }, response.data);
    return ret;
  }

  static Future<VideoPlayInfo> getVideoPlay({
    required String bvid,
    required int cid,
  }) async {
    var response =
        await _requestVideoPlay(bvid: bvid, cid: cid, fnval: _Fnval.dash.code);
    if (response.code != 0) {
      throw "getVideoPlay: code:${response.code}, message:${response.message}";
    }
    if (response.data == null ||
        response.data!.acceptQuality == null ||
        response.data!.acceptDescription == null) {
      return VideoPlayInfo.zero;
    }
    //获取支持的视频质量
    List<VideoQuality> supportVideoQualities = [];
    for (var i in response.data!.acceptQuality ?? <int>[]) {
      supportVideoQualities.add(VideoQualityCode.fromCode(i));
    }
    //获取视频
    List<VideoPlayItem> videos = [];
    for (var i in response.data!.dash?.video ?? <VideoOrAudioRaw>[]) {
      List<String> urls = [];
      if (i.baseUrl != null) {
        urls.add(i.baseUrl!);
      }
      if (i.backupUrl != null) {
        urls.addAll(i.backupUrl!);
      }
      videos.add(VideoPlayItem(
          urls: urls,
          quality: VideoQualityCode.fromCode(i.id ?? -1),
          bandWidth: i.bandwidth ?? 0,
          codecs: i.codecs ?? "",
          width: i.width ?? 0,
          height: i.height ?? 0,
          frameRate: double.tryParse(i.frameRate ?? "0") ?? 0));
    }
    //获取音频
    List<AudioPlayItem> audios = [];
    for (var i in response.data!.dash?.audio ?? <VideoOrAudioRaw>[]) {
      List<String> urls = [];
      if (i.baseUrl != null) {
        urls.add(i.baseUrl!);
      }
      if (i.backupUrl != null) {
        urls.addAll(i.backupUrl!);
      }
      audios.add(AudioPlayItem(
          urls: urls,
          quality: AudioQualityCode.fromCode(i.id ?? -1),
          bandWidth: i.bandwidth ?? 0,
          codecs: i.codecs ?? ""));
    }
    //如果有dolby的话
    for (var i in response.data!.dash?.dolby?.audio ?? <VideoOrAudioRaw>[]) {
      List<String> urls = [];
      if (i.baseUrl != null) {
        urls.add(i.baseUrl!);
      }
      if (i.backupUrl != null) {
        urls.addAll(i.backupUrl!);
      }
      audios.add(AudioPlayItem(
          urls: urls,
          quality: AudioQualityCode.fromCode(i.id ?? -1),
          bandWidth: i.bandwidth ?? 0,
          codecs: i.codecs ?? ""));
    }
    //如果有flac的话
    List<String> flacUrls = [];
    if (response.data!.dash?.flac?.audio?.baseUrl != null) {
      flacUrls.add(response.data!.dash!.flac!.audio!.baseUrl!);
    }
    if (response.data!.dash?.flac?.audio?.backupUrl != null) {
      flacUrls.addAll(response.data!.dash!.flac!.audio!.backupUrl!);
    }
    List<AudioQuality> supportAudioQualities = [];
    //获取支持的音质
    for (var i in audios) {
      supportAudioQualities.add(i.quality);
    }
    return VideoPlayInfo(
        // defualtVideoQuality:
        //     VideoQualityCode.fromCode(response.data!.quality ?? -1),
        supportVideoQualities: supportVideoQualities,
        supportAudioQualities: supportAudioQualities,
        timeLength: response.data!.dash?.duration ?? 0,
        videos: videos,
        audios: audios,
        lastPlayCid: response.data!.lastPlayCid ?? 0,
        lastPlayTime: Duration(milliseconds: response.data!.lastPlayTime ?? 0));
  }

  static Future<void> reportHistory(
      {required String bvid, required int cid, required int playedTime}) async {
    var response = await MyDio.dio.post(ApiConstants.heartBeat,
        queryParameters: {'bvid': bvid, 'cid': cid, 'played_time': playedTime});
    if (response.data['code'] != 0) {
      throw 'reportHistory: code:${response.data['code']},message:${response.data['message']}';
    }
  }
}

///视频流格式标识
// ignore: unused_field
enum _Fnval { dash, hdr, fourK, dolby, dolbyVision, eightK, av1 }

///视频流格式标识代码
// ignore: library_private_types_in_public_api
extension FnvalValue on _Fnval {
  int get code => [16, 64, 128, 256, 512, 1024, 2048][index];
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import '../models/user_model.dart';

class VideoCallService {
  static void initCallService(UserModel user, GlobalKey<NavigatorState> navigatorKey) {
    try {
      final appIdStr = dotenv.env['ZEGO_APP_ID'] ?? '0';
      final appSign = dotenv.env['ZEGO_APP_SIGN'] ?? '';
      
      if (appIdStr == '0' || appSign.isEmpty) {
        debugPrint('Zego credentials missing in .env. Skipping init.');
        return;
      }

      ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

      ZegoUIKitPrebuiltCallInvitationService().init(
        appID: int.tryParse(appIdStr) ?? 0,
        appSign: appSign,
        userID: user.id,
        userName: user.name,
        plugins: [ZegoUIKitSignalingPlugin()],
        requireConfig: (ZegoCallInvitationData data) {
          final config = (data.invitees.length > 1)
              ? ZegoCallInvitationType.videoCall == data.type
                  ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
              : ZegoCallInvitationType.videoCall == data.type
                  ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
                  
          return config;
        },
      );
    } catch (e) {
      debugPrint('Error initializing Zego: $e');
    }
  }

  static void deinitCallService() {
    ZegoUIKitPrebuiltCallInvitationService().uninit();
  }
}


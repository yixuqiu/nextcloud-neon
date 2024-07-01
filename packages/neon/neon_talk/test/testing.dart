import 'package:mocktail/mocktail.dart';
import 'package:neon_talk/src/blocs/room.dart';
import 'package:neon_talk/src/blocs/talk.dart';
import 'package:nextcloud/spreed.dart' as spreed;

class MockRoom extends Mock implements spreed.Room {}

class MockChatMessage extends Mock implements spreed.ChatMessage {}

class MockChatMessageWithParent extends Mock implements spreed.ChatMessageWithParent {}

class MockReaction extends Mock implements spreed.Reaction {}

class MockRoomBloc extends Mock implements TalkRoomBloc {}

class MockTalkBloc extends Mock implements TalkBloc {}

Map<String, dynamic> getRoom({
  int? id,
  String? token,
  int? unreadMessages,
}) =>
    {
      'actorId': '',
      'actorType': spreed.ActorType.users.name,
      'attendeeId': 0,
      'attendeePermissions': 0,
      'avatarVersion': '',
      'breakoutRoomMode': 0,
      'breakoutRoomStatus': 0,
      'callFlag': 0,
      'callPermissions': 0,
      'callRecording': 0,
      'callStartTime': 0,
      'canDeleteConversation': false,
      'canEnableSIP': false,
      'canLeaveConversation': false,
      'canStartCall': false,
      'defaultPermissions': 0,
      'description': '',
      'displayName': (id ?? 0).toString(),
      'hasCall': false,
      'hasPassword': false,
      'id': id ?? 0,
      'isCustomAvatar': false,
      'isFavorite': false,
      'lastActivity': 0,
      'lastCommonReadMessage': 0,
      'lastMessage': <dynamic>[],
      'lastPing': 0,
      'lastReadMessage': 0,
      'listable': 0,
      'lobbyState': 0,
      'lobbyTimer': 0,
      'messageExpiration': 0,
      'name': '',
      'notificationCalls': 0,
      'notificationLevel': 0,
      'objectId': '',
      'objectType': '',
      'participantFlags': 0,
      'participantType': 0,
      'permissions': 0,
      'readOnly': 0,
      'recordingConsent': 0,
      'sessionId': '',
      'sipEnabled': 0,
      'token': token ?? '',
      'type': 0,
      'unreadMention': false,
      'unreadMentionDirect': false,
      'unreadMessages': unreadMessages ?? 0,
    };

Map<String, dynamic> getChatMessage({
  int? id,
  String? message,
  Map<String, dynamic>? reactions,
  String? systemMessage,
  Map<String, dynamic>? parent,
}) =>
    {
      'actorDisplayName': '',
      'actorId': '',
      'actorType': spreed.ActorType.users.name,
      'expirationTimestamp': 0,
      'id': id ?? 0,
      'isReplyable': false,
      'markdown': false,
      'message': message ?? '',
      'messageParameters': <dynamic, dynamic>{},
      'messageType': spreed.MessageType.comment.name,
      'reactions': reactions ?? <dynamic, dynamic>{},
      'referenceId': '',
      'systemMessage': systemMessage ?? '',
      'timestamp': 0,
      'token': '',
      if (parent != null) 'parent': parent,
    };

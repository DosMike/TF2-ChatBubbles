ChatBubbles
=====

Say and TeamSay will trigger cursor annoations above player heads.

The plugins is customizable with client cookies (!settings) that can hide
the annotations from players or complete disable the feature for player that
don't want to see chat bubbles.

With the convar `sm_chatbubble_enabled` you can enable chat bubbles for say and teamsay (1)
for only teamsay (2) or disable it temporarily (0).

The convar `sm_chatbubble_distance` defines the maximum distance in hammer units
between players that still triggers chat bubbles.

If you don't want chat bubbles to be shown by default I recommend you set
`sm_chatbubble_default` to hidden / send only (2), default (1) is enabled but can also be completely disabled (0).
I recommend not setting this to 0, as it will stop the player from triggering chat bubbles for other players.

#### Note about using Chat-Processors:
While this plugin is default compiled to use any of the Chat-Processors listed in requirements, they remain optional.
Using a chat processor however will break a spy check that is in place for non-cp-ed messages.

Requirements
-----
- [smlib](https://github.com/bcserv/smlib/tree/transitional_syntax) (Transitional Syntax)
- [tf2hudmsg](https://github.com/DosMike/tf2hudmsg) (for managed CursorAnnotations)
- [SCP Redux](https://forums.alliedmods.net/showthread.php?p=1820365) (Optional)
- [ANY Chat-Processor](https://forums.alliedmods.net/showthread.php?p=2448733) (Optional)
- [CiderChatProcessor](https://forums.alliedmods.net/showthread.php?p=2646798) (Optional)
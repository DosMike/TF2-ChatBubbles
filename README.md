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

Requirements
-----
- smlib
- tf2rputils (for managed CursorAnnotations)
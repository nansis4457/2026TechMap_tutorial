# VisionOS_Spatial-Computing-Tutorial
Learning visionOS spatial computing — turning real rooms into a dungeon with RoomTrackingProvider 

## Team
Norton · Andy · Hazi


## Overview (개요)

This project is part of the **Spatial Computing Tech Map** at Apple Developer Academy @ POSTECH. 

이 프로젝트는 애플 디벨로퍼 아카데미 **Spatial Computing Tech Map**의 일환으로 진행됩니다. 

### Why visionOS (왜 visionOS인가)

`RoomTrackingProvider` and hand tracking have no equivalent on other platforms. Here the physical room is not a backdrop — it is input. The app has to ask *which room am I in* and *is this object inside it*, and those questions only exist on visionOS.


## How it works (진행 방식)

1. **Enter** — Hand tracking summons a sword. Each room has its own NPCs and hidden gear.

2. **Fight** — Defeat the room's mobs. Hidden gear equips automatically when you get close.

3. **Advance** — Leave the cleared room, enter the next. A different NPC is waiting.


## Requirements
- visionOS 2.0+ / Xcode 26+
- **Apple Vision Pro required** — room tracking and hand tracking do not work in the simulator.

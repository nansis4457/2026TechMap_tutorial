# ``CookieDungeon``

visionOS의 룸 트래킹으로 실제 방을 인식하고, 방마다 다른 3D 쿠키를 놓는 앱입니다.

## Overview

Cookie Dungeon은 Apple Vision Pro가 사용자가 서 있는 방의 형태를 어떻게 파악하는지, 그리고 그 정보를 어떻게 가상 콘텐츠 배치에 쓰는지를 보여주는 학습용 프로젝트입니다.

핵심은 세 가지입니다.

- **월드 센싱 권한** — 방 정보는 민감한 데이터라 사용자의 명시적 허가가 필요합니다.
- **룸 트래킹** — `RoomTrackingProvider`가 방이 바뀔 때마다 지오메트리를 밀어 줍니다.
- **오클루전** — 방의 형태에 투명한 재질을 입혀 벽 너머의 물체를 가립니다.

### 실행 요구 사항

- Xcode 26.6 이상
- visionOS 26.5 이상
- **Apple Vision Pro 실기기 필수** — 룸 트래킹은 시뮬레이터에서 동작하지 않습니다.

## Topics

### 튜토리얼

- <doc:TableOfContents>

# Gui Class
오토핫키 v2의 Gui 클래스를 v1에서 사용하도록 만든 라이브러리입니다.

## Installation
아래 두가지 방법중 하나를 선택하여 설치하세요. 먼저 [git](https://git-scm.com/download/win)이 설치되어 있어야 합니다.

오토핫키 스크립트로 설치하는 방법:
```ahk
; 표준 라이브러리에 설치
RunWait git clone https://github.com/neovis22/gui.git, % a_ahkPath "\..\Lib"

; 로컬 라이브러리에 설치
RunWait git clone https://github.com/neovis22/gui.git Lib/gui
```

사용할 스크립트에 아래 코드를 추가하세요.
```ahk
#Include <gui\gui>
```

## Usage
- [v2 Examples 참조](https://lexikos.github.io/v2/docs/objects/Gui.htm#Examples)

## Methods
- [v2 Gui 문서 참조](https://lexikos.github.io/v2/docs/objects/Gui.htm#Methods)
- [v2 GuiControl 문서 참조](https://lexikos.github.io/v2/docs/objects/GuiControl.htm#Methods)

## Properties
- [v2 Gui 문서 참조](https://lexikos.github.io/v2/docs/objects/Gui.htm#Properties)
- [v2 GuiControl 문서 참조](https://lexikos.github.io/v2/docs/objects/GuiControl.htm#Properties)

## Functions
- `guiFromHwnd(hwnd)`
- `guiCtrlFromHwnd(hwnd)`

## Changelog
#### 2022-05-14
- Added: `edit.append(text)`
- Added: `edit.replaceSel(text="", canUndo=false)`
- Added: `edit.setSel(start="", end="")`
#### 2022-05-10
- Added: `gui.visible`
- Added: `gui.emit(event, args*)`
- Added: `control.emit(event, args*)`
    - 이벤트를 발생시키는 함수로 커스텀 이벤트 추가하거나 이벤트를 직접 발생시킬 때 사용
#### 2022-04-29
- 컨트롤 생성 옵션으로 `#name` 형식의 이름 입력방식 허용
- Added: `gui.default()` v1 전용 현재 Gui를 기본으로 지정
- Added: `gui.disable()`
- Added: `gui.enable()`
- Added: `gui.owner`
- Added: `gui.style`
- Added: `gui.exStyle`
- Added: `control.default()` v1 전용 현재 Gui를 기본으로 지정
- Added: `control.disable()`
- Added: `control.enable()`
- Added: `control.anchor(rx=0, ry=0, rw=0, rh=0, redraw=false)`
    - 참조: [Control Anchoring v4 for resizing windows
](https://www.autohotkey.com/board/topic/4105-control-anchoring-v4-for-resizing-windows)
- Added: `control.style`
- Added: `control.exStyle`
#### 2022-04-16
- Autohotkey v2 beta 버전의 문서를 기준으로 구현
- 차이점:
    - 반환값이 없는 함수의 경우 `this`를 반환하여 체인구조의 호출 가능
    - v1에서는 컨트롤 배경 색상을 임의로 지정할 수 없으므로 `Gui Color` 명령어를 `myGui.color()` 로 호출할 수 있게 추가
    - 컨트롤의 이벤트발생시 유연한 처리를 위해 별도의 queue로 관리하며 `Gui`의 이벤트는 즉시 실행

## Contact
[카카오톡 오픈 프로필](https://open.kakao.com/me/neovis)

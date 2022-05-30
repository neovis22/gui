/*
    Library: gui
    Author: neovis
    https://github.com/neovis22/gui
*/

gui(options="", title="", eventObj="") {
    return new __Gui__(options, title, eventObj)
}

class __Gui__ {
    
    ; 전역에서 핸들값으로 `guiFromHwnd()` 함수를 이용해 Gui에 접근할 수 있도록 객체를 색인하며 객체는 레퍼런스카운트를 유지하기 위해 포인터로 저장
    static _instances := []
    
    static _eventQueue := [] ; 컨트롤 이벤트 큐
    
    ; 컨트롤 생성할 떄 타입을 매개변수로 전달하는 `add(type)` 외에 함수이름에 타입을 포함하여 생성할 수 있는 `add[Type]()` 함수를 연결
    static addText := __Gui__._add.bind("Text")
    static addEdit := __Gui__._add.bind("Edit")
    static addUpDown := __Gui__._add.bind("UpDown")
    static addPicture := __Gui__._add.bind("Picture")
    static addPic := __Gui__._add.bind("Picture")
    static addButton := __Gui__._add.bind("Button")
    static addCheckbox := __Gui__._add.bind("Checkbox")
    static addRadio := __Gui__._add.bind("Radio")
    static addDropDownList := __Gui__._add.bind("DropDownList")
    static addDDL := __Gui__._add.bind("DropDownList")
    static addComboBox := __Gui__._add.bind("ComboBox")
    static addListBox := __Gui__._add.bind("ListBox")
    static addListView := __Gui__._add.bind("ListView")
    static addTreeView := __Gui__._add.bind("TreeView")
    static addLink := __Gui__._add.bind("Link")
    static addHotkey := __Gui__._add.bind("Hotkey")
    static addDateTime := __Gui__._add.bind("DateTime")
    static addMonthCal := __Gui__._add.bind("MonthCal")
    static addSlider := __Gui__._add.bind("Slider")
    static addProgress := __Gui__._add.bind("Progress")
    static addGroupBox := __Gui__._add.bind("GroupBox")
    static addTab := __Gui__._add.bind("Tab")
    static addTab2 := __Gui__._add.bind("Tab2")
    static addTab3 := __Gui__._add.bind("Tab3")
    static addStatusBar := __Gui__._add.bind("StatusBar")
    static addActiveX := __Gui__._add.bind("ActiveX")
    static addCustom := __Gui__._add.bind("Custom")
    
    _controls := [] ; 생성된 모든 컨트롤
    
    _controlNames := [] ; 이름이 지정된 컨트롤
    
    _events := []
    
    ; 탭 컨트롤의 `useTab()` 함수에서 탭의 순서를 기억하기 위해 생성된 탭 컨트롤을 카운팅
    _tabCount := 0
    
    _delimiter := "|" ; v1 명령어 호환
    
    _anchoredControls := []
    
    hwnd := _guiCreate(this)
    
    __new(options="", title="", eventObj="") {
        if (options != "")
            this.opt(options)
        if (title != "")
            this.title := title
        this._eventObj := IsObject(eventObj) ? &eventObj : 0
    }
    
    __delete() {
        this.destroy()
        __Gui__._instances.delete(this.hwnd)
    }
    
    /*
        생성된 컨트롤의 핸들과 객체로 열거
        ```ahk
        for hwnd, control in myGui {
        }
        ```
    */
    _newEnum() {
        return ObjNewEnum(this._controls)
    }
    
    _resizeControls(w, h) {
        if (this._initSize == "")
            this._initSize := [w, h]
        gw := w-this._initSize[1]
        gh := h-this._initSize[2]
        
        for hwnd, c in this._anchoredControls {
            DllCall("SetWindowPos"
                , "ptr",hwnd
                , "ptr",0
                , "int",gw*c._anchor.rx+c._anchor.x
                , "int",gh*c._anchor.ry+c._anchor.y
                , "int",gw*c._anchor.rw+c._anchor.w
                , "int",gh*c._anchor.rh+c._anchor.h
                , "uint",0x4) ; SWP_NOZORDER
            if (c._anchor.redraw)
                ; RDW_UPDATENOW = 0x0100
                ; RDW_INVALIDATE = 0x0001
                DllCall("RedrawWindow"
                    , "ptr",hwnd
                    , "ptr",0
                    , "ptr",0
                    , "uint",0x101) ; RDW_UPDATENOW | RDW_INVALIDATE
        }
    }
    
    ; `add[type]()` 바인드용 함수
    _add(g, args*) {
        return g.add(this, args*)
    }
    
    add(type, options="", text="") {
        switch (type) {
            case "DDL": type := "DropDownList"
            case "Pic": type := "Picture"
        }
        
        options := " " options " "
        if (p := RegExMatch(options, "(?<= [vV#])\S+(?= )", name))
            options := SubStr(options, 1, p-2) SubStr(options, p+StrLen(name)+1)
        
        if (IsObject(text)) {
            for i, v in text
                _text .= a_index-1 ? this._delimiter v : v
            text := _text
        }
        
        Gui % this.hwnd ":Add", % type, % options " Hwndhwnd", % text
        
        control := new __Gui__[type]
        control.hwnd := hwnd+0
        control.name := name
        control.type := type
        control.pgui := &this
        control.hparent := this.hwnd
        
        if type in Tab,Tab2,Tab3
            control._tabNumber := ++ this._tabCount
        
        if (name != "") {
            this[name] := control
            this._controlNames.push(name)
        }
        this._controls[hwnd+0] := control
        
        return control
    }
    
    destroy() {
        Gui % this.hwnd ":Destroy"
        return this
    }
    
    flash(blink=1) {
        Gui % this.hwnd ":Flash", % blink ? "" : "Off"
        return this
    }
    
    getClientPos(byref x="", byref y="", byref width="", byref height="") {
        VarSetCapacity(rc, 16)
        , DllCall("GetClientRect", "ptr",this.hwnd, "ptr",&rc)
        , DllCall("ClientToScreen", "ptr",this.hwnd, "ptr",&rc)
        , x := NumGet(rc, 0, "int")
        , y := NumGet(rc, 4, "int")
        , width := NumGet(rc, 8, "int")
        , height := NumGet(rc, 12, "int")
        return this
    }
    
    getPos(byref x="", byref y="", byref width="", byref height="") {
        VarSetCapacity(rc, 16)
        , DllCall("GetWindowRect", "ptr",this.hwnd, "ptr",&rc)
        , x := NumGet(rc, 0, "int")
        , y := NumGet(rc, 4, "int")
        , width := NumGet(rc, 8, "int")-x
        , height := NumGet(rc, 12, "int")-y
        return this
    }
    
    hide() {
        Gui % this.hwnd ":Hide"
        return this
    }
    
    maximize() {
        Gui % this.hwnd ":Maximize"
        return this
    }
    
    minimize() {
        Gui % this.hwnd ":Minimize"
        return this
    }
    
    move(x="", y="", width="", height="") {
        return this, DllCall("MoveWindow", "int",x, "int",y, "int",width, "int",height, "int",true)
    }
    
    onEvent(eventName, callback, addRemove=1) {
        if (!this._events[eventName])
            this._events[eventName] := []
        switch (addRemove) {
            case  1: this._events[eventName].push(callback)
            case -1: this._events[eventName].insertAt(1, callback)
            case  0: this._events[eventName] := []
            default: throw Exception("invalid parameter value for addRemove: " addRemove)
        }
        return this
    }
    
    opt(options) {
        if (RegExMatch(options, "i)(?<=Delimiter)\S+", match))
            this._delimiter := match
        Gui % this.hwnd ":" options
        return this
    }
    
    restore() {
        Gui % this.hwnd ":Restore"
        return this
    }
    
    setFont(options="", fontName="") {
        Gui % this.hwnd ":Font", % options, % fontName
        return this
    }
    
    show(options="") {
        Gui % this.hwnd ":Show", % options
        ; HACK: 쓰레드가 바쁜경우 간혹 사이즈 이벤트가 무시되는 경우가 발생하여 강제 실행으로 대처
        this.getClientPos(,, w, h)
        _guiSize(this.hwnd, 0, w, h)
        return this
    }
    
    submit() {
        form := []
        for i, v in this._controlNames
            form[v] := this[v].value
        return form
    }
    
    color(windowColor="", controlColor="") {
        Gui % this.hwnd ":Color", % windowColor, % controlColor
        return this
    }
    
    disable() {
        Gui % this.hwnd ":+Disabled"
        return this
    }
    
    enable() {
        Gui % this.hwnd ":-Disabled"
        return this
    }
    
    emit(event, args*) {
        for i, v in this._events[event] {
            if (IsObject(v))
                prevent := v.call(this, args*)
            else
                prevent := this._eventObj
                    ? Object(this._eventObj)[v](this, args*)
                    : Func(v).call(this, args*)
            if (prevent != "")
                return prevent
        }
    }
    
    backColor[] {
        get {
            return this._backColor
        }
        set {
            Gui % this.hwnd ":Color", % value
            return this._backColor := value
        }
    }
    
    focusedCtrl[] {
        get {
            GuiControlGet classNN, % this.hwnd ":Focus"
            ControlGet hwnd, hwnd,, % classNN, % "ahk_id" this.hwnd
            return this._controls[hwnd]
        }
        set {
            return value
        }
    }
    
    marginX[] {
        get {
            return this._marginX
        }
        set {
            Gui % this.hwnd ":Margin", % value
            return this._marginX := value
        }
    }
    
    marginY[] {
        get {
            return this._marginY
        }
        set {
            Gui % this.hwnd ":Margin",, % value
            return this._marginY := value
        }
    }
    
    menuBar[] {
        get {
            return this._menuBar
        }
        set {
            Gui % this.hwnd ":Menu", % IsObject(value) ? value.name : value
            return this._menuBar := value
        }
    }
    
    title[] {
        get {
            WinGetTitle value, % "ahk_id" this.hwnd
            return value
        }
        set {
            WinSetTitle % "ahk_id" this.hwnd,, % value
            return value
        }
    }
    
    owner[] {
        get {
            return this._owner
        }
        set {
            this.opt("+Owner" (value ? value.hwnd : ""))
            return this._owner := value
        }
    }
    
    style[] {
        get {
            return DllCall("GetWindowLong", "ptr",this.hwnd, "int",-16)
        }
        set {
            return value, DllCall("SetWindowLong", "ptr",this.hwnd, "int",-16, "uint",value)
        }
    }
    
    exStyle[] {
        get {
            return DllCall("GetWindowLong", "ptr",this.hwnd, "int",-20)
        }
        set {
            return value, DllCall("SetWindowLong", "ptr",this.hwnd, "int",-20, "uint",value)
        }
    }
    
    visible[] {
        get {
            return DllCall("IsWindowVisible", "ptr",this.hwnd)
        }
        set {
            Gui % this.hwnd ":" (value ? "Show" : "Hide")
            return value
        }
    }
    
    class Control {
        
        _events := []
        
        _eventHandler(type, args*) {
            this.emit(this._v2events[type], args*)
        }
        
        default() {
            if (a_defaultGui != this.hparent)
                Gui % this.hparent ":Default"
            return this
        }
        
        focus() {
            GuiControl Focus, % this.hwnd
            return this
        }
        
        getPos(byref x="", byref y="", byref width="", byref height="") {
            GuiControlGet p, Pos, % this.hwnd
            x := px, y := py, width := pw, height := ph
            return this
        }
        
        move(byref x="", byref y="", byref width="", byref height="") {
            GuiControl Move, % this.hwnd, % (x == "" ? "" : "x" x) (y == "" ? "" : " y" y) (width == "" ? "" : " w" width) (height == "" ? "" : " h" height)
            return this
        }
        
        onCommand(notifyCode, callback, addRemove=1) {
            ; TODO
            return this
        }
        
        onEvent(eventName, callback, addRemove=1) {
            if (!this._events[eventName])
                this._events[eventName] := []
            switch (addRemove) {
                case  1: this._events[eventName].push(callback)
                case -1: this._events[eventName].insertAt(1, callback)
                case  0: this._events[eventName] := []
                default: throw Exception("invalid parameter value for addRemove: " addRemove)
            }
            ; 이벤트가 존재할때만 콜백 적용
            for i, event in this._events {
                if (event.length()) {
                    func := Func("_guiEnqueueControlEvent").bind(&this)
                    GuiControl +g, % this.hwnd, % func
                    return this
                }
            }
            GuiControl -g, % this.hwnd
            return this
        }
        
        onNotify(notifyCode, callback, addRemove=1) {
            ; TODO
            return this
        }
        
        opt(options) {
            GuiControl % options, % this.hwnd
            return this
        }
        
        redraw() {
            GuiControl MoveDraw, % this.hwnd
            return this
        }
        
        setFont(options="", fontName="") {
            this.gui.setFont(options, fontName)
            GuiControl Font, % this.hwnd
            return this
        }
        
        disable() {
            GuiControl Disable, % this.hwnd
            return this
        }
        
        enable() {
            GuiControl Enable, % this.hwnd
            return this
        }
        
        /*
            Anchor 함수를 참조하여 구현
            https://www.autohotkey.com/board/topic/4105-control-anchoring-v4-for-resizing-windows
        */
        anchor(rx=0, ry=0, rw=0, rh=0, redraw=false) {
            GuiControlGet p, Pos, % this.hwnd
            this._anchor := {redraw:redraw
                , x:px, y:py, w:pw, h:ph
                , rx:rx, ry:ry, rw:rw, rh:rh}
            this.gui._anchoredControls[this.hwnd] := this
            return this
        }
        
        emit(type, args*) {
            for i, v in this._events[type] {
                if (IsObject(v)) {
                    prevent := v.call(this, args*)
                } else {
                    if (this.gui._eventObj)
                        prevent := Object(this.gui._eventObj)[v](this, args*)
                    else
                        prevent := Func(v).call(this, args*)
                }
                if (prevent != "")
                    return prevent
            }
        }
        
        length[] {
            get {
                return DllCall("SendMessage"
                    , "ptr",this.hwnd
                    , "uint",0xE ; WM_GETTEXTLENGTH
                    , "uptr",0
                    , "ptr",0)
            }
        }
        
        classNN[] {
            get {
                ; TODO
            }
            set {
                return value
            }
        }
        
        enabled[] {
            get {
                GuiControlGet value, Enabled, % this.hwnd
                return value
            }
            set {
                return value
            }
        }
        
        focused[] {
            get {
                return this.gui.focusedCtrl == this
            }
            set {
                return value
            }
        }
        
        gui[] {
            get {
                return Object(this.pgui)
            }
            set {
                return value
            }
        }
        
        text[] {
            get {
                if (!length := DllCall("GetWindowTextLength", "ptr",this.hwnd, "int"))
                    return ""
                VarSetCapacity(value, length*2, 0)
                DllCall("GetWindowText", "ptr",this.hwnd, "str",value, "uint",length*2)
                return value
            }
            set {
                GuiControl Text, % this.hwnd, % value
                return value
            }
        }
        
        value[] {
            get {
                GuiControlGet value,, % this.hwnd
                return value
            }
            set {
                GuiControl,, % this.hwnd, % value
                return value
            }
        }
        
        visible[] {
            get {
                GuiControlGet value, Visible, % this.hwnd
                return value
            }
            set {
                GuiControl % value ? "Show" : "Hide", % this.hwnd
                return value
            }
        }
        
        style[] {
            get {
                return DllCall("GetWindowLong", "ptr",this.hwnd, "int",-16)
            }
            set {
                return value, DllCall("SetWindowLong", "ptr",this.hwnd, "int",-16, "uint",value)
            }
        }
        
        exStyle[] {
            get {
                return DllCall("GetWindowLong", "ptr",this.hwnd, "int",-20)
            }
            set {
                return value, DllCall("SetWindowLong", "ptr",this.hwnd, "int",-20, "uint",value)
            }
        }
    }
    
    class Text extends __Gui__.Control {
        
        static _v2events := {normal:"click", doubleClick:"doubleClick"}
    }
    
    class Edit extends __Gui__.Control {
        
        static _v2events := {normal:"change"}
        
        append(text) {
            return this.setSel(-1), this.replaceSel(text)
        }
        
        replaceSel(text="", canUndo=false) {
            return this, DllCall("SendMessage"
                , "ptr",this.hwnd
                , "uint",0xC2 ; EM_REPLACESEL
                , "uptr",canUndo
                , "str",text)
        }
        
        setSel(start="", end="") {
            if (start == "")
                start := this.length+1
            if (end == "")
                end := start
            return this, DllCall("SendMessage"
                , "ptr",this.hwnd
                , "uint",0xB1 ; EM_SETSEL
                , "uptr",start-1
                , "ptr",end-1)
        }
    }
    
    class UpDown extends __Gui__.Control {
        
        static _v2events := {normal:"change"}
    }
    
    class Picture extends __Gui__.Control {
        
        static _v2events := {normal:"click", doubleClick:"doubleClick"}
    }
    
    class Button extends __Gui__.Control {
        
        static _v2events := {normal:"click"}
    }
    
    class Checkbox extends __Gui__.Control {
        
    }
    
    class Radio extends __Gui__.Checkbox {
        
        static _v2events := {normal:"click", doubleClick:"doubleClick"}
    }
    
    class DropDownList extends __Gui__.ComboBox {
        
    }
    
    class ComboBox extends __Gui__.Control {
        
        static _v2events := {normal:"change"}
        
        add(items) {
            for i, v in items
                DllCall("SendMessage"
                    , "ptr",this.hwnd
                    , "uint",0x143 ; CB_ADDSTRING
                    , "uptr",0
                    , "wstr",v)
            return this
        }
        
        choose(value) {
            if value is Integer
                GuiControl Choose, % this.hwnd, % value
            else
                GuiControl ChooseString, % this.hwnd, % value
            return this
        }
        
        delete(value="") {
            if (value == "")
                GuiControl,, % this.hwnd, % this.gui._delimiter
            else
                DllCall("SendMessage"
                    , "ptr",this.hwnd
                    , "uint",0x144 ; CB_DELETESTRING
                    , "uptr",value-1
                    , "ptr",0)
            return this
        }
    }
    
    class ListBox extends __Gui__.Control {
        
        static _v2events := {normal:"change", doubleClick:"doubleClick"}
        
        add(items) {
            for i, v in items
                DllCall("SendMessage"
                    , "ptr",this.hwnd
                    , "uint",0x180 ; LB_ADDSTRING
                    , "uptr",0
                    , "wstr",v)
            return this
        }
        
        choose(value) {
            if value is Integer
                GuiControl Choose, % this.hwnd, % value
            else
                GuiControl ChooseString, % this.hwnd, % value
            return this
        }
        
        delete(value="") {
            if (value == "")
                GuiControl,, % this.hwnd, % this.gui._delimiter
            else
                DllCall("SendMessage"
                    , "ptr",this.hwnd
                    , "uint",0x182 ; LB_DELETESTRING
                    , "uptr",value-1
                    , "ptr",0)
            return this
        }
        
        value[] {
            get {
                if (this.style & 0x800) ; LBS_EXTENDEDSEL
                    return StrSplit(base.value, this.gui._delimiter)
                else
                    return base.value
            }
            set {
                return base.value := value
            }
        }
    }
    
    class ListView extends __Gui__.Control {
        
        _eventHandler(type, args*) {
            switch (type) {
                /*
                    v2 버전에 없는 이벤트
                        - D: The user has attempted to start dragging a row or icon (there is currently no built-in support for dragging rows or icons). The variable A_EventInfo contains the focused row number. [v1.0.44+]: This notification occurs even without AltSubmit.
                        - d (lowercase D): Same as above except a right-click-drag rather than a left-drag.
                        - A: A row has been activated, which by default occurs when it is double clicked. The variable A_EventInfo contains the row number.
                        - C: The ListView has released mouse capture.
                        - K: The user has pressed a key while the ListView has focus. A_EventInfo contains the virtual key code of the key, which is a number between 1 and 255. This can be translated to a key name or character via GetKeyName(). For example, key := GetKeyName(Format("vk{:x}", A_EventInfo)). On most keyboard layouts, keys A-Z can be translated to the corresponding character via Chr(A_EventInfo). F2 keystrokes are received regardless of WantF2. However, the Enter keystroke is not received; to receive it, use a default button as described below.
                        - M: Marquee. The user has started to drag a selection-rectangle around a group of rows or icons.
                        - S: The user has begun scrolling the ListView.
                        - s (lowercase S): The user has finished scrolling the ListView.
                */
                case "Normal":
                    this.emit("click", args[1])
                case "DoubleClick":
                    this.emit("doubleClick", args[1])
                case "I":
                    loop parse, % args[2]
                        switch (a_loopField) {
                            case "s": this.emit("itemSelect", args[1], a_loopField == "S")
                            case "c": this.emit("itemCheck", args[1], this._data[args[1], "checked"] := a_loopField == "C")
                            case "f": this.emit("itemFocus", args[1])
                        }
                case "ColClick":
                    this.emit("colClick", args[1])
                case "E":
                    if (type == "e")
                        this.emit("itemEdit", args[1])
                case "F":
                    this.emit(type == "F" ? "focus" : "loseFocus")
                case "D":
                    this.emit("dragStart", args[1])
            }
        }
        
        default() {
            if (a_defaultGui != this.hparent)
                Gui % this.hparent ":Default"
            if (a_defaultListView != this.hwnd)
                Gui % this.hparent ":ListView", % this.hwnd
            return this
        }
        
        add(options="", cols*) {
            this.default()
            return LV_Add(options, cols*)
        }
        
        insert(rowNumber, options="", cols*) {
            this.default()
            return LV_Insert(rowNumber, options, cols*)
        }
        
        modify(rowNumber, options="", cols*) {
            this.default()
            return LV_Modify(rowNumber, options, cols*)
        }
        
        delete(rowNumber="") {
            this.default()
            return LV_Delete(rowNumber)
        }
        
        modifyCol(args*) {
            this.default()
            return LV_ModifyCol(args*)
        }
        
        insertCol(colNumber, options="", columnTitle="") {
            this.default()
            return LV_InsertCol(colNumber, options, columnTitle)
        }
        
        deleteCol(colNumber) {
            this.default()
            return LV_DeleteCol(colNumber)
        }
        
        getCount(mode="") {
            this.default()
            return LV_GetCount(mode)
        }
        
        getNext(startingRowNumber="", rowType="") {
            this.default()
            return LV_GetNext(startingRowNumber, rowType)
        }
        
        getText(rowNumber, colNumber=1) {
            this.default()
            LV_GetText(text, rowNumber, colNumber)
            return text
        }
        
        setImageList(imageListId, iconType="") {
            this.default()
            return LV_SetImageList(imageListId, iconType)
        }
    }
    
    class TreeView extends __Gui__.Control {
        
        _eventHandler(type, args*) {
            switch (type) {
                /*
                    v2 버전에 없는 이벤트
                        - E: The user has begun editing an item (the user may edit items only when the TreeView has -ReadOnly in its options). The variable A_EventInfo contains the item ID.
                        - K: The user has pressed a key while the TreeView has focus. A_EventInfo contains the virtual key code of the key, which is a number between 1 and 255. If the key is alphabetic, on most keyboard layouts it can be translated to the corresponding character via Chr(A_EventInfo). F2 keystrokes are received regardless of WantF2. However, the Enter keystroke is not received; to receive it, use a default button as described below.
                */
                case "Normal": this.emit("click", args[1])
                case "DoubleClick": this.emit("doubleClick", args[1])
                case "S": this.emit("itemSelect", args[1], type == "S")
                case "e": this.emit("itemEdit", args[1])
                case "+" : this.emit("itemExpand", args[1], type == "+")
                case "F": this.emit(type == "F" ? "focus" : "loseFocus")
                case "D": this.emit("dragStart", args[1])
            }
        }
        
        default() {
            if (a_defaultGui != this.hparent)
                Gui % this.hparent ":Default"
            if (a_defaultTreeView != this.hwnd)
                Gui % this.hparent ":TreeView", % this.hwnd
            return this
        }
        
        add(name, parentItemId="", options="") {
            this.default()
            return TV_Add(name, parentItemId, options)
        }
        
        modify(itemId, options="", newName*) {
            this.default()
            if (newName.length())
                return TV_Modify(itemId, options, newName[1])
            else
                return TV_Modify(itemId, options)
        }
        
        delete(itemId="") {
            this.default()
            return TV_Delete(itemId)
        }
        
        getSelection() {
            this.default()
            return TV_GetSelection()
        }
        
        getCount() {
            this.default()
            return TV_GetCount()
        }
        
        getParent(itemId) {
            this.default()
            return TV_GetParent(itemId)
        }
        
        getChild(parentItemId) {
            this.default()
            return TV_GetChild(parentItemId)
        }
        
        getPrev(itemId) {
            this.default()
            return TV_GetPrev(itemId)
        }
        
        getNext(itemId="", itemType="Full") {
            this.default()
            return TV_GetNext(itemId, itemType)
        }
        
        getText(itemId) {
            this.default()
            TV_GetText(text, itemId)
            return text
        }
        
        get(itemId, attribute) {
            this.default()
            return TV_Get(itemId, attribute)
        }
        
        setImageList(imageListId , iconType="") {
            this.default()
            return TV_SetImageList(imageListId , iconType)
        }
    }
    
    class Link extends __Gui__.Control {
        
        static _v2events := {normal:"click"}
    }
    
    class Hotkey extends __Gui__.Control {
        
        static _v2events := {normal:"change"}
    }
    
    class DateTime extends __Gui__.Control {
        
        static _v2events := {normal:"change"}
        
        setFormat(format="") {
            GuiControl Text, % this.hwnd, % format
            return this
        }
    }
    
    class MonthCal extends __Gui__.Control {
        
        static _v2events := {normal:"change"}
    }
    
    class Slider extends __Gui__.Control {
        
        static _v2events := {normal:"change"}
        
        ; AltSubmit 옵션을 추가할 경우 type이 시작 값으로 전달되므로 "change"로 강제고정
        _eventHandler(type, args*) {
            this.emit("change", args*)
        }
    }
    
    class Progress extends __Gui__.Control {
        
    }
    
    class GroupBox extends __Gui__.Control {
        
    }
    
    class Tab extends __Gui__.Control {
        
        static _v2events := {normal:"change"}
        
        useTab(value="", exactMatch="") {
            if (value == "")
                Gui % this.hparent ":Tab"
            else
                Gui % this.hparent ":Tab", % value, % this._tabNumber, % exactMatch ? "Exact" : ""
            return this
        }
        
        add(items) {
            count := DllCall("SendMessage"
                , "ptr",this.hwnd
                , "uint",0x1304 ; TCM_GETITEMCOUNT
                , "uptr",0
                , "ptr",0)
            VarSetCapacity(tcitem, 20+a_ptrSize*2, 0)
            ; TCIF_TEXT 0x1
            NumPut(0x1, tcitem, 0, "uint") ; mask
            for i, v in items {
                NumPut(&v, tcitem, 12, "ptr") ; pszText
                DllCall("SendMessage"
                    , "ptr",this.hwnd
                    , "uint",0x133E ; TCM_INSERTITEMW
                    , "uptr",count+a_index-1
                    , "ptr",&tcitem)
            }
            return this
        }
        
        choose(value) {
            if value is Integer
                GuiControl Choose, % this.hwnd, % value
            else
                GuiControl ChooseString, % this.hwnd, % value
            return this
        }
        
        delete(value="") {
            if (value == "")
                GuiControl,, % this.hwnd, % this.gui._delimiter
            else
                DllCall("SendMessage"
                    , "ptr",this.hwnd
                    , "uint",0x416 ; TB_DELETEBUTTON
                    , "uptr",value-1
                    , "ptr",0)
            return this
        }
    }
    
    class Tab2 extends __Gui__.Tab {
        
    }
    
    class Tab3 extends __Gui__.Tab {
        
    }
    
    class StatusBar extends __Gui__.Control {
        
        static _v2events := {normal:"click", doubleClick:"doubleClick", rightClick:"click"}
        
        setText(newText, partNumber="", style="") {
            this.default()
            return SB_SetText(newText, partNumber, style)
        }
        
        setParts(width*) {
            this.default()
            return SB_SetParts(width*)
        }
        
        setIcon(filename, iconNumber="", partNumber="") {
            this.default()
            return SB_SetIcon(filename, iconNumber, partNumber)
        }
    }
    
    class ActiveX extends __Gui__.Control {
        
    }
    
    class Custom extends __Gui__.Control {
        
    }
}

_guiCreate(gui) {
    Gui New, +Hwndhwnd +Label_gui
    __Gui__._instances[hwnd+0] := &gui
    return hwnd+0
}

_guiClose(hwnd) {
    return guiFromHwnd(hwnd).emit("close")
}

_guiSize(hwnd, type, w, h) {
    gui := guiFromHwnd(hwnd)
    gui._resizeControls(w, h)
    gui.emit("size", type, w, h)
}

_guiContextMenu(hwnd, hctrl, item, isRightClick, x, y) {
    gui := guiFromHwnd(hwnd)
    gui._controls[hctrl].emit("contextMenu", item, isRightClick, x, y)
    gui.emit("contextMenu", gui._controls[hctrl], item, isRightClick, x, y)
}

_guiDropFiles(hwnd, files, hctrl, x, y) {
    gui := guiFromHwnd(hwnd)
    gui.emit("dropFiles", gui._controls[hctrl], files, x, y)
}

_guiEscape(hwnd) {
    guiFromHwnd(hwnd).emit("escape")
}

_guiEnqueueControlEvent(pctrl, hwnd, type, args*) {
    ; 여러 이벤트가 빠르게 발생시 문제가 있음
    ; Object(pctrl)._eventHandler(type, args*) ; 이벤트 즉시처리
    critical
    __Gui__._eventQueue.push({ctrl:Object(pctrl), type:type, args:args, tc:a_tickCount})
    SetTimer _guiControlEventHandler, -1
}

_guiControlEventHandler() {
    loop % __Gui__._eventQueue.length() {
        event := __Gui__._eventQueue.removeAt(1)
        if (event.tc+200 < a_tickCount)
            continue
        event.ctrl.default()
        event.ctrl._eventHandler(event.type, event.args*)
        Sleep -1 ; 새 이벤트가 스택에 추가되도록 쓰레드새치기 허용
    }
    if (__Gui__._eventQueue.length())
        SetTimer _guiControlEventHandler, -1
}

guiFromHwnd(hwnd) {
    if (p := __Gui__._instances[hwnd])
        return Object(p)
}

guiCtrlFromHwnd(hwnd) {
    if (g := guiFromHwnd(DllCall("GetParent", "ptr",hwnd, "int")))
        return g._controls[hwnd]
}
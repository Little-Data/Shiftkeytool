; 模拟按键配置说明
; ■ 基础按键：
;   a-z 0-9 符号键直接使用字母/符号，如: a 1 $ [
; 
; ■ 功能键：
;   F1-F24            Esc       Tab
;   Enter             Backspace Delete
;   Insert            Home      End
;   PgUp              PgDn      Pause
;   CapsLock          NumLock   ScrollLock
;   PrintScreen       AppsKey
;
; ■ 方向键：
;   Up    Down    Left    Right
;
; ■ 修饰符（可组合使用）：
;   ^ = Ctrl       ! = Alt
;   + = Shift     # = Win
;
; ■ 鼠标按键：
;   LButton（左键）  RButton（右键） MButton（中键）
;   XButton1（侧键1）XButton2（侧键2）
;   WheelUp（滚轮上）WheelDown（滚轮下）
;   WheelLeft（滚轮左）WheelRight（滚轮右）
;
; ■ 多媒体键：
;   Volume_Mute    Volume_Up     Volume_Down
;   Media_Next     Media_Prev    Media_Play_Pause
;   Browser_Back   Browser_Forward Browser_Refresh
;   Launch_Mail    Launch_App1   Launch_App2
;
; ■ 特殊语法：
;   {按键名}       包裹含空格的键名（必须）
;   {Blind}       保持修饰键状态
;   {Text}        发送原始文本
;   {Raw}         同{Text}
; 
; ■ 组合键示例：
;   ^c           → Ctrl+C
;   +!{F12}      → Shift+Alt+F12
;   #r           → Win+R
;   ^#{Up}       → Ctrl+Win+↑
;   XButton1 & a → 侧键1 + A
;   WheelUp & WheelDown → 滚轮组合
; 
; ■ 高级用法：
;   vkNN        → 虚拟键代码（NN为十六进制）
;   scNNN       → 扫描码（NNN为十进制）
;   {U+00A3}    → Unicode字符（£符号）
; 
;  更多按键请看 Autohotkey 2.0 文档
#Requires AutoHotkey v2.0
#SingleInstance force
A_IconTip := "双击Shift模拟按键"
Persistent()

; 初始化全局变量
Global LastShiftUpTime := 0
Global LastShiftKey := ""
Global BlockNextPress := false
Global DoubleClickThreshold := 180 ; 双击时间
Global isEnabled := true  ; 全局状态控制变量

; 设置初始托盘图标（启用状态）并预加载
UpdateTrayIcon() {
    Try TraySetIcon A_ScriptDir (isEnabled ? "\enabled.ico" : "\disabled.ico")
}
UpdateTrayIcon()  ; 初始化时设置正确图标

; 初始化托盘菜单
A_TrayMenu.Delete()
A_TrayMenu.Add("启用脚本", ToggleScript)
A_TrayMenu.Check("启用脚本")
A_TrayMenu.Add("关于", ShowAbout)
A_TrayMenu.Add("退出", ExitScript)
A_TrayMenu.Default := "启用脚本"

; 初始注册热键
RegisterHotkeys()

; 注册热键的函数
RegisterHotkeys() {
    Hotkey "~LShift Up", (*) => HandleShiftUp("LShift"), "On"
    Hotkey "~RShift Up", (*) => HandleShiftUp("RShift"), "On"
}
; 注销热键的函数
UnregisterHotkeys() {
    Hotkey "~LShift Up", "Off"
    Hotkey "~RShift Up", "Off"
}

; 处理Shift键释放事件的函数
HandleShiftUp(ThisShiftKey) {
    Global isEnabled, LastShiftUpTime, LastShiftKey, BlockNextPress
    
    ; 禁用状态直接返回
    if (!isEnabled)
        return
    
    ; 修复点：优化自动重复过滤逻辑
    if (A_PriorKey = ThisShiftKey) {
        TimeSincePrior := A_TimeSincePriorHotkey != "" ? Integer(A_TimeSincePriorHotkey) : 1000
        if (TimeSincePrior < 20) {
            return
        }
    }
    
    CurrentTime := A_TickCount
    
    ; 修复点：仅在需要时拦截操作
    if (BlockNextPress) {
        return
    }
    
    ; 修复点：优化双击判断逻辑
    if (LastShiftKey == ThisShiftKey) {
        ElapsedTime := CurrentTime - LastShiftUpTime
        if (ElapsedTime < DoubleClickThreshold) {
            Send("^{Space}") ; 在此修改发送的按键
            LastShiftUpTime := 0
            LastShiftKey := ""
            BlockNextPress := true
            ; 添加定时器，在阈值后重置BlockNextPress
            SetTimer(() => BlockNextPress := false, -DoubleClickThreshold)
            return
        }
    }
    
    ; 记录新的按键信息
    LastShiftUpTime := CurrentTime
    LastShiftKey := ThisShiftKey
    SetTimer(ResetDoubleClick, -DoubleClickThreshold)
}

; 重置双击检测
ResetDoubleClick() {
    Global LastShiftUpTime, LastShiftKey
    LastShiftUpTime := 0
    LastShiftKey := ""
}

; 切换脚本启用状态
ToggleScript(*) {
    Global isEnabled
    isEnabled := !isEnabled  ; 切换状态
    
    ; 动态控制热键注册
    if (isEnabled) {
        RegisterHotkeys()
    } else {
        UnregisterHotkeys()
    }
    
    ; 更新托盘图标和菜单状态
    UpdateTrayIcon()
    A_TrayMenu.ToggleCheck("启用脚本")
}

; 显示关于信息
ShowAbout(*) {
    MsgBox("双击Shift模拟按键脚本`n版本 1.0")
}

; 退出脚本
ExitScript(*) {
    ExitApp
}
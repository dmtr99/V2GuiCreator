#Requires AutoHotKey v2.0-beta.3
#SingleInstance Force

; #Include SetSystemCursor.ahk
#Include Lib\ToolBar.ah2
#Include Lib\ObjectGui.ah2
#Include Lib\Gdip_All.ahk
#Include Lib\SetSystemCursor.ahk
#Include Lib\RestoreCursors.ahk
#Include Lib\ImagePut.ahk

If !pToken := Gdip_Startup()
{
    MsgBox "Gdiplus failed to start. Please ensure you have gdiplus on your system"
    ExitApp
}
OnExit((ExitReason, ExitCode) => Gdip_Shutdown(pToken))
CoordMode("Mouse")
OnMessage(0x0200, WM_MOUSEMOVE)
DetectHiddenWindows true
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode "Input"	; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir	; Ensures a consistent starting directory.
global IconLib := "Auto-GUI.icl"
tray := A_TrayMenu

tray.Add()
tray.Add("Open program folder", (ItemName, ItemPos, MyMenu) => Run(A_ScriptDir))

Global oG := {}
oG.Window := {}
oG.ControlList := Map()
Class DefCtl {
    __New(DisplayName, Prefix, Width, Height, Options := "", Style := "", ExStyle := "0", Text := "", Icon := 1) {
        this.DisplayName := DisplayName
        this.Prefix := Prefix
        this.Text := (Text == "=") ? this.DisplayName : Text
        this.Width := Width
        this.Height := Height
        this.Options := Options
        this.Style := Style
        this.ExStyle := ExStyle
        this.IconIndex := Icon
        this.Menu := ""
        this.ActiveTab := ""
        this.ActiveTabCtrl := ""
    }
}

Global Default := {}
Default.ActiveX := DefCtl("ActiveX", "Ax", 200, 100, "", 0x54000000, , "HTMLFile", -33)
Default.Button := DefCtl("Button", "Btn", 80, 23, "", 0x50012000, , "&OK", -9)
Default.CheckBox := DefCtl("CheckBox", "Chk", 120, 23, "", 0x50012003, , "=", -10)
Default.ComboBox := DefCtl("ComboBox", "Cbx", 120, 21, "", 0x50010242, , ["ComboBox"], -11)
Default.DateTime := DefCtl("Date Time Picker", "Date", 100, 24, "", 0x5201000C, , "", -12)
Default.DropDownList := DefCtl("Drop-Down List", "DDL", 120, 21, "", 0x50010203, , ["DropDownList"], -13)
Default.Edit := DefCtl("Edit Box", "Edt", 120, 21, "", 0x50010080, 0x200, "", -14)
Default.GroupBox := DefCtl("GroupBox", "Grp", 120, 80, "", 0x50000007, , "=", -15)
Default.Hotkey := DefCtl("Hotkey Box", "Hk", 120, 21, "", 0x50010000, 0x200, "", -16)
Default.Link := DefCtl("Link", "Lnk", 120, 23, "", 0x50010000, , 'This is a <a href="https://www.autohotkey.com">link</a>', -17)
Default.ListBox := DefCtl("ListBox", "Lbx", 120, 160, "", 0x50010081, 0x200, ["ListBox1"], -18)
Default.ListView := DefCtl("ListView", "Lv", 200, 150, "+LV0x4000", 0x50010009, 0x200, ["ListView1"], -19)
Default.MonthCal := DefCtl("Month Calendar", "Month", 225, 160, "", 0x50010000, , "", -21)
Default.Picture := DefCtl("Picture", "Pic", 32, 32, "", 0x50000003, , "mspaint.exe", -22)
Default.Progress := DefCtl("Progress Bar", "Prg", 120, 20, "-Smooth", 0x50000000, , "33", -23)
Default.Radio := DefCtl("Radio Button", "Rad", 120, 23, "", 0x50036009, , "=", -24)
; Default.Separator := DefCtl("Separator", "Sep", 200, 2, "+0x10", 0x50020010, 0x20000, "", -25)
Default.Slider := DefCtl("Slider", "Sldr", 120, 32, "", 0x50010000, , "50", -26)
Default.StatusBar := DefCtl("Status Bar", "Sb", "", "", "", 0x50000800, , "=", -27)
Default.Tab2 := DefCtl("Tab", "Tab", 225, 160, "", 0x54010240, , ["Tab 1","Tab 2"], -28)
Default.Text := DefCtl("Text", "Txt", 120, 23, "+0x200", 0x50000200, , "=", -29)
Default.ToolBar := DefCtl("Toolbar", "Tb", 225, 160, "", 0x50009901, , "=", -30)
Default.TreeView := DefCtl("TreeView", "Tv", 160, 160, "", 0x50010027, 0x200, "", -31)
Default.UpDown := DefCtl("UpDown", "UpDn", 16, 21, "", 0x50000026, , "1", -32)
Default.Custom := DefCtl("Custom", "Ctl", 100, 23, "", 0x50010000, , "Custom", -34)
; Default.CommandLink := DefCtl("Command Link", "CmdLnk", 200, 42, "ClassButton +0x200E", 0x5001200E, , "=", -35)
Default.MenuBar := DefCtl("MenuBar", "MenuBar",10 , 10, "", 0x5001200E, , "", -35)

Default.ListView.ExExStyle := 0x30

Default.Button.Menu := ["Default", "Disabled", "No Theme", "", "UAC Shield"]
Default.CheckBox.Menu := ["Checked", "Disabled"]
Default.ComboBox.Menu := ["Alternate Submit", "Sort Alphabetically", "Uppercase All Items", "Lowercase All Items", "Simple (Edit + ListBox)", "Hint Text...", "No Theme", "Disabled"]
Default.DateTime.Menu := ["Show Checkbox", "Right Align the Drop-down Calendar", "Disabled"]
Default.DropDownList.Menu := ["Alternate Submit", "Sort Alphabetically", "Uppercase All Items", "Lowercase All Items", "No Theme", "Disabled"]
Default.Edit.Menu := ["Read Only", "Multiline", "No Scrollbar", "Numbers Only", "Text Alignment...", "Hint Text...", "Password Field", "No Theme", "Disabled"]
Default.GroupBox.Menu := ["Text Alignment...", "No Theme"]
Default.Hotkey.Menu := ["Disabled"]
Default.ListBox.Menu := ["Alternate Submit", "No Integral Height", "Multiple Selection (Extended)", "Multiple Selection (Simplified)", "Sort Alphabetically", "Disabled"]
Default.ListView.Menu := ["View Mode...", "Alternate Submit", "No Column Header", "Show Checkboxes", "Show Grid", "Single Row Selection", "Show ToolTips", "Explorer Theme", "Prevent Flickering", "Sort Alphabetically", "No Sort Header", "Editable First Cell", "Underline Hot Items", "Disabled"]
Default.MonthCal.Menu := ["Multiple Selection", "Show Week Numbers", "No Today Circle", "No Bottom Label"]
Default.Picture.Menu := ["Transparent Background", "Use GDI+", "Show Border", "Sunken", "3D Sunken Edge", "3D Outset Border", "Thick Frame"]
Default.Progress.Menu := ["No Smooth Style", "Show Border", "Vertical", "Disabled"]
Default.Radio.Menu := ["Checked", "Disabled"]
; Default.Separator.Menu := ["Vertical Line"]
Default.Slider.Menu := ["Vertical", "No Ticks", "Blunt", "Thick Thumb", "Show ToolTip", "Disabled"]
Default.StatusBar.Menu := ["Show on Top", "No Theme"]
Default.Tab2.Menu := ["Single Row (No Wrap)", "Buttons", "Flat Buttons", "Tabs on the Bottom", "Alternate Submit"]
Default.Text.Menu := ["Single Line", "Show Border", "Sunken", "3D Sunken Edge", "3D Outset Border", "Text Alignment...", "No GUI Background", "Disabled"]
Default.TreeView.Menu := ["Alternate Submit", "Show Checkboxes", "No Expansion Glyph", "No Dotted Lines", "Explorer Theme", "Full Row Select", "Disabled"]
Default.UpDown.Menu := ["No Buddy (Isolated)", "No Thousands Separator", "Left-sided", "Horizontal", "Disabled"]
; Default.CommandLink.Menu := ["Default Button", "Show Border", "Disabled", "No Theme"]

Class DefEvent {
    __New(EventName, Parameters, ControlTypes, EventFunctionName:="", EventFunction:= "") {
        this.EventName := EventName
        this.Parameters := Parameters
        this.ControlTypes := ControlTypes
        this.EventFunctionName := EventFunctionName
        this.EventFunction := EventFunction
    }
}

Global DefaultEvents := {}
DefaultEvents.Close := DefEvent("Close", "GuiObj","Gui")
DefaultEvents.ContextMenu := DefEvent("ContextMenu", "GuiObj, GuiCtrlObj, Item, IsRightClick, X, Y","Gui")
DefaultEvents.DropFiles := DefEvent("DropFiles", "GuiObj, GuiCtrlObj, FileArray, X, Y","Gui")
DefaultEvents.Escape := DefEvent("Escape", "GuiObj","Gui")
DefaultEvents.Size := DefEvent("Size", "GuiObj, MinMax, Width, Height","Gui")
DefaultEvents.Change := DefEvent("Change", "GuiObj,Info","DDL, ComboBox, ListBox, Edit, DateTime, MonthCal, Hotkey, UpDown, Slider, Tab")
DefaultEvents.Click := DefEvent("Click", "GuiObj,Info","Text, Pic, Button, CheckBox, Radio, ListView, TreeView, StatusBar")
DefaultEvents.ClickLink := DefEvent("Click", "GuiObj,Info","Link")
DefaultEvents.DoubleClick := DefEvent("DoubleClick", "GuiObj,Info","Text, Pic, Button, CheckBox, Radio, ComboBox, ListBox, ListView, TreeView, StatusBar")
DefaultEvents.ColClick := DefEvent("ColClick", "GuiCtrlObj, Info","ListView")
DefaultEvents.ContextMenuCtrl := DefEvent("ContextMenu", "GuiCtrlObj, Item, IsRightClick, X, Y","Text, Edit Pic, Button, CheckBox, Radio, ComboBox, ListBox, ListView, TreeView, StatusBar")
DefaultEvents.Focus := DefEvent("Focus", "GuiCtrlObj, Info","Button, CheckBox, Radio, DDL, ComboBox, ListBox, ListView, TreeView, Edit, DateTime")
DefaultEvents.LoseFocus := DefEvent("LoseFocus", "GuiCtrlObj, Info","Button, CheckBox, Radio, DDL, ComboBox, ListBox, ListView, TreeView, Edit, DateTime")
DefaultEvents.ItemCheck := DefEvent("ItemCheck", "GuiCtrlObj, Item, Checked","ListView, TreeView")
DefaultEvents.ItemEdit := DefEvent("ItemEdit", "GuiCtrlObj, Item","ListView, TreeView")
DefaultEvents.ItemExpanded := DefEvent("ItemExpanded", "GuiCtrlObj, Item, Expanded","TreeView")
DefaultEvents.ItemFocus := DefEvent("ItemFocus", "GuiCtrlObj, Item","ListView")
DefaultEvents.ItemSelect := DefEvent("ItemSelect", "GuiCtrlObj, Item, Selected","ListView")
DefaultEvents.ItemSelectTV := DefEvent("ItemSelect", "GuiCtrlObj, Item","TreeView")

Class DefWinOption {
    __New(Name, Option) {
        this.Name := Name
        this.Option := Option
    }
}

Global DefaultWinOpt := {}
DefaultWinOpt.Resize := DefWinOption("Resizable", "+Resize")
DefaultWinOpt.MinimizeBox := DefWinOption("No Minimize Box", "-MinimizeBox")
DefaultWinOpt.MaximizeBox := DefWinOption("No Maximize Box", "-MaximizeBox")
DefaultWinOpt.MinSize := DefWinOption("MinSize ", "+MinSize")
DefaultWinOpt.MaxSize := DefWinOption("MaxSize ", "+MaxSize")
DefaultWinOpt.SysMenu := DefWinOption("No System Menu", "-SysMenu")
DefaultWinOpt.AlwaysOnTop := DefWinOption("Always on Top", "+AlwaysOnTop")
DefaultWinOpt.Border := DefWinOption("Border", "+Border")
DefaultWinOpt.Disabled := DefWinOption("Disabled", "+Disabled")
DefaultWinOpt.OwnDialogs := DefWinOption("Own Dialogs", "+OwnDialogs")
DefaultWinOpt.ToolWindow := DefWinOption("Tool Window", "+ToolWindow")
DefaultWinOpt.DPIScale := DefWinOption("No DPI Scale", "-DPIScale")
DefaultWinOpt.HelpButton := DefWinOption("Help Button", "+E0x400")
DefaultWinOpt.Theme := DefWinOption("Classic Theme", "-Theme")
DefaultWinOpt.Caption := DefWinOption("No Title Bar", "-Caption")
DefaultWinOpt.Owner := DefWinOption("No Taskbar Button", "+Owner")
DefaultWinOpt.Parent := DefWinOption("No Taskbar Button", "+Parent")

Class DefCtrlOption {
    __New(Name, Option, ControlTypes) {
        this.Name := Name
        this.Option := Option
        this.ControlTypes := ControlTypes
    }
}
Global DefaultCtrlOptions := {}
DefaultCtrlOptions.Default := DefCtrlOption("Default", "+Default","Button")
DefaultCtrlOptions.Disabled := DefCtrlOption("Disabled", "+Disabled","All")
DefaultCtrlOptions.Checked := DefCtrlOption("Checked", "+Checked","Checkbox, Radio")
DefaultCtrlOptions.Multiline := DefCtrlOption("Multiline", "+Multi","Edit")
DefaultCtrlOptions.MultiCal := DefCtrlOption("Multi-Select", "+Multi","MonthCal")
DefaultCtrlOptions.RangeCal := DefCtrlOption("Range", "+Range20050101-20050615","MonthCal,DateTime")
DefaultCtrlOptions.WeekNumbersCal := DefCtrlOption("WeekNumbers", "+4","MonthCal")
DefaultCtrlOptions.NoTodayCircleCal := DefCtrlOption("No Today circle", "+8","MonthCal")
DefaultCtrlOptions.NoTodayCal := DefCtrlOption("No Today", "+16","MonthCal")
DefaultCtrlOptions.VScrollbar := DefCtrlOption("VScrollbar", "+VScroll","All")
DefaultCtrlOptions.HScrollbar := DefCtrlOption("HScrollbar", "+HScroll","All")
DefaultCtrlOptions.Border := DefCtrlOption("Border", "+Border","All")
DefaultCtrlOptions.Password := DefCtrlOption("Password", "+Password","Edit")
DefaultCtrlOptions.Number := DefCtrlOption("Numbers Only", "+Number","Edit")
DefaultCtrlOptions.ReadOnly := DefCtrlOption("Read Only", "+ReadOnly","All")
DefaultCtrlOptions.Grid := DefCtrlOption("Show Grid", "+Grid","ListView")
DefaultCtrlOptions.NoSort := DefCtrlOption("No Sort", "+NoSort","ListView")
DefaultCtrlOptions.NoSortHdr := DefCtrlOption("No Sort Header", "+NoSortHdr","ListView")
DefaultCtrlOptions.NoHdr := DefCtrlOption("No Header", "-Hdr","ListView")
DefaultCtrlOptions.Sort := DefCtrlOption("Sort first column", "+Sort","ListView")
DefaultCtrlOptions.SortDesc := DefCtrlOption("Sort first column Desc", "+SortDesc","ListView")
DefaultCtrlOptions.WantF2 := DefCtrlOption("WantF2", "+WantF2","ListView")
DefaultCtrlOptions.MultiLV := DefCtrlOption("Prevent Multi selection", "-Multi","ListView")
DefaultCtrlOptions.Limit := DefCtrlOption("Limit input", "+Limit10","Edit")
DefaultCtrlOptions.Uppercase := DefCtrlOption("Uppercase", "+Uppercase","Edit")
DefaultCtrlOptions.LowerCase := DefCtrlOption("LowerCase", "+LowerCase","Edit")
DefaultCtrlOptions.CtrlAPrevent := DefCtrlOption("Prevent Ctrl+A", "-WantCtrlA","Edit")
DefaultCtrlOptions.AllowReturn := DefCtrlOption("Allow Return", "-WantReturn","Edit")
DefaultCtrlOptions.AllowTab := DefCtrlOption("Allow Tab", "-WantTab","Edit")
DefaultCtrlOptions.Wrap := DefCtrlOption("Wrap", "+Wrap","Edit,Tab1,Tab2,Tab3")
DefaultCtrlOptions.AltSubmit := DefCtrlOption("AltSubmit", "+AltSubmit","Combobox,ListBox,Slider,Picture,tab")
DefaultCtrlOptions.Invert := DefCtrlOption("Invert", "+Invert","Slider")
DefaultCtrlOptions.Left := DefCtrlOption("Left", "+Left","Slider,Tab1,Tab2,Tab3")
DefaultCtrlOptions.Line := DefCtrlOption("Line", "+Line","Slider")
DefaultCtrlOptions.Thick := DefCtrlOption("Thick", "+Thick30","Slider")
DefaultCtrlOptions.ThickInterval := DefCtrlOption("ThickInterval", "+ThickInterval10","Slider")
DefaultCtrlOptions.NoTicks := DefCtrlOption("NoTicks", "+NoTicks","Slider")
DefaultCtrlOptions.Page := DefCtrlOption("Page", "+Page","Slider")
DefaultCtrlOptions.Range := DefCtrlOption("Range", "+Range0-10","Slider,Progress")
DefaultCtrlOptions.Tooltip := DefCtrlOption("Tooltip", "+Tooltip","Slider")
DefaultCtrlOptions.Vertical := DefCtrlOption("Vertical", "+Vertical","Slider,Progress")
DefaultCtrlOptions.Smooth := DefCtrlOption("Smooth", "+Smooth","Progress")
DefaultCtrlOptions.Buttons := DefCtrlOption("Buttons", "+Buttons","Tab1,Tab2,Tab3")
DefaultCtrlOptions.UpDown := DefCtrlOption("up-down control", "+1","DateTime")
DefaultCtrlOptions.DateTimeCheckBox := DefCtrlOption("Checkbox", "+2","DateTime")
DefaultCtrlOptions.Right := DefCtrlOption("Right", "+Right","Tab1,Tab2,Tab3,DateTime")
DefaultCtrlOptions.Bottom := DefCtrlOption("Bottom", "+Bottom","Tab1,Tab2,Tab3")
; Global g_ControlOptions := {"Default": "+Default"
; , "Show ToolTips": "+LV0x4000"
; , "No Integral Height": "+0x100"
; , "Multiple Selection (simplified)": "+0x8"
; , "No Theme": "-Theme"
; , "No Smooth Style": "-Smooth"
; , "Simple (Edit + ListBox)": "+Simple"
; , "Multiple Selection": "+Multi"
; , "Show Week Numbers": "4"
; , "No Today Circle": "8"
; , "No Bottom Label": "16"
; , "Show Checkbox": "2"
; , "Right Align the Drop-down Calendar": "+Right"
; , "Use GDI+": "+AltSubmit"
; , "Single Line": "+0x200"
; , "Sunken": "+0x1000"
; , "3D Sunken Edge": "+E0x200"
; , "3D Outset Border": "+0x400000"
; , "Thick Frame": "+0x40000"
; , "Transparent Background": "+BackgroundTrans"
; , "No Expansion Glyph": "-Buttons"
; , "No Dotted Lines": "-Lines"
; , "Thick Thumb": "+0x40"
; , "No Ticks": "+NoTicks"
; , "Blunt": "+Center"
; , "Show ToolTip": "+Tooltip"
; , "No Buddy (Isolated)": "-16"
; , "No Thousands Separator": "+0x80"
; , "Left-sided": "+Left"
; , "Horizontal": "+Horz"
; , "Buttons": "+Buttons"
; , "Flat Buttons": "+0x8"
; , "Tabs on the Bottom": "+Bottom"
; , "Single Row (No Wrap)": "-Wrap"
; , "Underline Hot Items": "+LV0x840"
; , "Default Button": "+0x1"
; , "Prevent Flickering": "+LV0x10000"
; , "Editable First Cell": "+0x200"
; , "Show on Top": "+0x1"
; , "Full Row Select": "+0x1000 -0x2"
; , "No GUI Background": "-Background"
; , "Vertical Line": "+0x1"}

; Settings initiation
oSettings_Default := Object()
oSettings_Default.MainGui := {
    WinX: 300,
    WinY: 200,
    WinW: 645,
    WinH: 645,
    WinAlwaysOnTop: 1,
    WinGetClientPos: true,
    WinResize: 1,
    WinHighlight: 1,
    WinWindow: 1,
    WinControl: 1,
    WinMouse: 1,
    WinList: 1,
    SnapToGrid:1,
    DefaultPos:1,
    DefaultSize: 1,
    ImportHiddenControls: 1,
    ImportUnknownControls: 1
}

global SettingsFile := Regexreplace(A_scriptName, "(.*)\..*", "$1.ini")
;Load the existing settings
global oSettings := FileExist(SettingsFile) ? ReadINI(SettingsFile, oSettings_Default) : oSettings_Default
global oSet := oSettings.MainGui
CreateCGui_V2GuiCreator()
return

CreateCGui_V2GuiCreator(){
    global MyGui, SelGui, ogLV_Controls, ogEdit_script, SB
    MyGui := Gui("Resize", "V2 GuiCreator")
    MyGui.OnEvent("Close", Gui_Close)
    MyGui.OnEvent("Size", Gui_Size)

    myMenuBar := MenuBar()
    FileMenu := Menu()
    FileMenu.Add("&New Gui", WorkGui_Create)
    FileMenu.SetIcon("&New Gui", IconLib, -2)
    FileMenu.Add()
    FileMenu.Add("Save", WorkGui_Save)
    FileMenu.SetIcon("Save", "Shell32.dll", 259)
    FileMenu.Add()
    FileMenu.Add("Copy Code to clipboard", (*) => (A_Clipboard := ogEdit_script.Text))
    FileMenu.SetIcon("Copy Code to clipboard", "Shell32.dll", 135)
    FileMenu.Add()
    FileMenu.Add("Import Window", WorkGui_Import)
    FileMenu.SetIcon("Import Window", IconLib, -3)
    FileMenu.Add("&Preview", (*) => ((FileExist("test.ahk") ? FileDelete("test.ahk") : ""), FileAppend(ogEdit_script.value, "test.ahk"), Run("test.ahk")))
    FileMenu.SetIcon("&Preview", IconLib, -73)
    FileMenu.Add("Explore", (*) => (ObjectGui(oG)))
    FileMenu.Add("Explore Gui", (*) => (ObjectGui(WorkGui)))
    FileMenu.Add("&Open ScriptDir", (*) => (Run(A_ScriptDir)))
    FileMenu.Add("&Reload", (*) => (Reload()))
    FileMenu.Add()
    FileMenu.Add("&Exit", (*) => (ExitApp))

    SettingsMenu := Menu()
    SettingsMenu.Add("Default pos", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.DefaultPos := !oSet.DefaultPos))
    (oSet.DefaultPos = 1) ? SettingsMenu.Check("Default pos") : ""
    SettingsMenu.Add("Default size", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.DefaultSize := !oSet.DefaultSize))
    (oSet.DefaultSize = 1) ? SettingsMenu.Check("Default size") : ""
    SettingsMenu.Add("Snap To Grid", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.SnapToGrid := !oSet.SnapToGrid))
    (oSet.SnapToGrid = 1) ? SettingsMenu.Check("Snap To Grid") : ""
    SettingsMenu.Add("Import Hidden controls", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.ImportHiddenControls := !oSet.ImportHiddenControls))
    (oSet.ImportHiddenControls = 1) ? SettingsMenu.Check("Import Hidden controls") : ""
    SettingsMenu.Add("Import Unknown controls", (ItemName, ItemPos, ItemMenu) => (ItemMenu.ToggleCheck(ItemName), oSet.ImportUnknownControls := !oSet.ImportUnknownControls))
    (oSet.ImportUnknownControls = 1) ? SettingsMenu.Check("Import Unknown controls") : ""
    myMenuBar.Add("&File", FileMenu)
    myMenuBar.Add("&Settings", SettingsMenu)
    myMenuBar.Add("&Reload", (*) => (Reload()))
    
    MyGui.MenuBar := myMenuBar

    oToolbar := Toolbar()
    ; oToolbar.Add("")
    oToolbar.Add("", "New Gui", WorkGui_Create, IconLib , -2)
    oToolbar.Add("", "Import Window", WorkGui_Import, IconLib , -3)
    oToolbar.Add("", "Save", WorkGui_Save, "Shell32.dll" , 259)
    oToolbar.Add("", "Copy Code to clipboard", (*)=>(A_Clipboard:= ogEdit_script.Text), "Shell32.dll" , 135)
    oToolbar.Add("")
    oToolbar.Add("", "Align Left", (*) => (Selection_CopyProp("x"), GenerateCode(), UpdateSelectionBox()), IconLib , -52)
    oToolbar.Add("", "Align Right", (*) => (Selection_CopyProp("xw", "max"), GenerateCode(), UpdateSelectionBox()), IconLib , -53)
    oToolbar.Add("", "Align Top", (*) => (Selection_CopyProp("y"), GenerateCode(), UpdateSelectionBox()), IconLib , -54)
    oToolbar.Add("", "Align Bottom", (*) => (Selection_CopyProp("yh","max"), GenerateCode(), UpdateSelectionBox()), IconLib , -55)
    oToolbar.Add("")
    oToolbar.Add("", "Same width", (*) => (Selection_CopyProp("w", "max"), GenerateCode(), UpdateSelectionBox()), IconLib , -60)
    oToolbar.Add("", "Same height", (*) => (Selection_CopyProp("h", "max"), GenerateCode(), UpdateSelectionBox()), IconLib , -61)
    oToolbar.Add("", "Same size", (*) => (Selection_CopyProp("w", "max"),Selection_CopyProp("h"), GenerateCode(), UpdateSelectionBox()), IconLib , -62)
    oToolbar.Add("")
    oToolbar.Add("", "Preview", (*) => ((FileExist("test.ahk") ? FileDelete("test.ahk") : ""), FileAppend(ogEdit_script.value, "test.ahk"), Run("test.ahk")), IconLib , -73)
    
    ; ogLine := myGui.AddText("x0 y0 w200 h1 Background0xDCDCDC")
    ogLine := myGui.AddGroupbox("x0 y-6 w200 h34 ")
    ogLine.LeftMargin := 0

    AddToolbar(oToolbar, myGui, , "x3 y3 h23 w400")
    MyGui.MarginX:=0
    MyGui.MarginY:=0
    ogLV_Controls := MyGui.AddListView("x1 y+2 r20 w120 +0x2000 -Hdr -e0x200",["Controls"])
    ogLV_Controls.BottomMargin := 23
    ogLV_Controls.OnEvent("Click", Click_LV_Controls)
    
    Global ImageListID := IL_Create(40)

    for key, value in Default.OwnProps(){
        IL_Add(ImageListID, IconLib, value.IconIndex)
    }
    ogLV_Controls.SetImageList(ImageListID,1)
    for key, value in Default.OwnProps(){
        ogLV_Controls.Add("Icon" A_Index ,Key)
    }
        
    ogEdit_script := MyGui.AddEdit("x+2 yp +Multi -E0x200")
    ogEdit_script.BottomMargin := 23
    ogEdit_script.LeftMargin:=1
    SB := MyGui.AddStatusBar()
    SB.SetParts(160, 160, 160,160)
    MyGui.Show("x" oSet.WinX " y" oSet.WinY " w" oSet.WinW " h" oSet.WinH " Hide")
    MyGui.Show()
    
    GenerateCode()
    return

    Click_LV_Controls(LV, RowNumber){
        global WorkGui
        ControlType := LV.GetText(RowNumber)	; Get the text from the row's first field.
        ; ToolTip("You double-clicked row number " RowNumber ". Text: '" ControlType "'")
        if (!IsSet(WorkGui) or !IsObject(WorkGui)){
            WorkGui_Create()
        }
        if(ControlType = "Statusbar"){
            SB := WorkGui.AddStatusBar(,Default.%ControlType%.text)
            oControl := Default.%ControlType%
            oControl.ControlType := ControlType
            oControl.CtrlName := "Control_" oG.ControlList.index
            oControl.oName := "SB"
            SB.CtrlName := oControl.CtrlName
            oG.ControlList[oControl.CtrlName] := oControl
            oG.ControlList.index++

            GenerateCode()
            return
        } else if (ControlType = "MenuBar"){
            myMenuBar := MenuBar()
            FileMenu := Menu()
            FileMenu.Add("&Open ScriptDir", (*) => (Run(A_ScriptDir)))
            FileMenu.Add("&Reload", (*) => (Reload()))
            FileMenu.Add()
            FileMenu.Add("&Exit", (*) => (ExitApp))
            myMenuBar.Add("&File", FileMenu)
            
            WorkGui.MenuBar := myMenuBar
            oG.Window.MenuBar := "
            (
            myMenuBar := MenuBar()
            FileMenu := Menu()
            FileMenu.Add("&Open ScriptDir", (*) => (Run(A_ScriptDir)))
            FileMenu.Add("&Reload", (*) => (Reload()))
            FileMenu.Add()
            FileMenu.Add("&Exit", (*) => (ExitApp))
            myMenuBar.Add("&File", FileMenu) 
            )"
            GenerateCode()
             return
        } else if (ControlType = "Custom") {
            title := "Custom Class"
            text1 := "Win32 Control Class Name"
            text2 := "Enter the name of a registered Win32 control class."
            aChoices := ["Button", "ComboBoxEx32", "ReBarWindow32", "ScrollBar", "SysAnimate32", "SysPager", "SysTabControl"]
            extraOption := Gui_Select(title, text1, text2, achoices)
            if (extraOption=""){
                Exit
            }
            PreCreateCtrl(ControlType, "Class" extraOption) 
            return
        } else if (ControlType = "ActiveX") {
            title := "ActiveX"
            text1 := "ActiveX Control"
            text2 := "Enter the identifier of an ActiveX object that can be embedded in a window.`nA folder path or an Internet address is loaded in Explorer"
            aChoices := ["Shell.Explorer", "HTMLFile", "WMPlayer.OCX"]
            extraText := Gui_Select(title, text1, text2, achoices)
            if (extraText = "") {
                Exit
            }
            PreCreateCtrl(ControlType, "", extraText) 
            return
        }
        PreCreateCtrl(ControlType,"")
    }

    Gui_Close(GuiObj) {
        global oSettings, oSet
        GuiObj.GetPos(&X, &Y)
        GuiObj.GetClientPos(, , &W, &H)
        oSet.WinX := X
        oSet.WinY := Y
        oSet.WinW := W
        oSet.WinH := H
        oSettings.MainGui := oSet
        WriteINI(&oSettings)
        return false
    }

    Gui_Size(thisGui, MinMax, Width, Height) {
        if MinMax = -1	; The window has been minimized. No action needed.
            return
        DllCall("LockWindowUpdate", "Uint", thisGui.Hwnd)
        For Hwnd, GuiCtrlObj in thisGui {
            if GuiCtrlObj.HasProp("LeftMargin") {
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(, , Width - cX - GuiCtrlObj.LeftMargin, )
            }
            if GuiCtrlObj.HasProp("LeftDistance") {
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(Width - cWidth - GuiCtrlObj.LeftDistance, , , )
            }
            if GuiCtrlObj.HasProp("BottomDistance") {
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(, Height - cHeight - GuiCtrlObj.BottomDistance, , )
            }
            if GuiCtrlObj.HasProp("BottomMargin") {
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(, , , Height - cY - GuiCtrlObj.BottomMargin)
            }
        }
        DllCall("LockWindowUpdate", "Uint", 0)
        GenerateCode()
    }
    
    PreCreateCtrl(ControlType, ExtraOption :="", ExtraText := "", p*){
        if (!IsSet(WorkGui) or !IsObject(WorkGui)) {
            return
        }
        WinActivate(WorkGui)
        CoordMode("Mouse", "Screen")
        xMouse_Prev := -1
        yMouse_Prev := -1
        
        ogNewCtrl := WorkGui.Add(ControlType,ExtraOption, ExtraText = "" ? Default.%ControlType%.Text : Default.%ControlType%.Text ExtraText)
        if (!oSet.DefaultPos){
            Loop {
                MouseGetPos(&xMouse, &yMouse, &WinHwndMouse, &ControlHwndMouse, 2)

                xMouse := oSet.SnapToGrid ? Round(xMouse/5)*5 : xMouse
                yMouse := oSet.SnapToGrid ? Round(yMouse/5)*5 : yMouse
                
                WinGetClientPos(&xWin, &yWin, , , WorkGui)
                if (xMouse_Prev != xMouse or yMouse_Prev != yMouse) {
                    ; ToolTip("MouseX:[" xMouse-xWin "]")
                    xCtrl := xMouse - xWin
                    yCtrl := yMouse - yWin
                    ; ToolTip("x" xCtrl " y" yCtrl)
                    ogNewCtrl.Move(xCtrl,yCtrl)

                }
                xMouse_Prev := xMouse
                yMouse_Prev := yMouse
                sleep 30
                if GetKeyState("LButton") {
                    Break
                }
                if GetKeyState("Escape") {
                    ogNewCtrl.Visible := 0
                    return
                }
            }
            if (!oSet.DefaultSize){
                loop {
                    if !GetKeyState("LButton") {
                        Break
                    }
                    if GetKeyState("Escape") {
                        ogNewCtrl.Visible := 0
                        return
                    }
                }

                Loop {
                    MouseGetPos(&xMouse, &yMouse, &WinHwndMouse, &ControlHwndMouse, 2)
                    xMouse := oSet.SnapToGrid ? Round(xMouse / 5) * 5 : xMouse
                    yMouse := oSet.SnapToGrid ? Round(yMouse / 5) * 5 : yMouse
                    WinGetClientPos(&xWin, &yWin, , , WorkGui)
                    if (xMouse_Prev != xMouse or yMouse_Prev != yMouse) {
                        wCtrl := xMouse - xWin - xCtrl
                        hCtrl := yMouse - yWin - yCtrl
                        ; ToolTip(wCtrl "x" hCtrl)
                        ogNewCtrl.Move(, , wCtrl, hCtrl)

                    }
                    xMouse_Prev := xMouse
                    yMouse_Prev := yMouse
                    sleep 30
                    if GetKeyState("LButton") {
                        Break
                    }
                }
            }
            
        }
        ogNewCtrl.Visible := 0
        MouseGetPos(&xMouse, &yMouse, &WinHwndMouse, &ControlHwndMouse, 2)
        GuiControlObj := GuiCtrlFromHwnd(ControlHwndMouse)
        
        if (GuiControlObj.Hasprop("Type") and SubStr(GuiControlObj.Type,1,3)="tab"){
            GuiControlObj.UseTab(GuiControlObj.Value)
            ogNewCtrl.ActiveTabCtrl := GuiControlObj
            ogNewCtrl.ActiveTab := GuiControlObj.Value
        } else{
            if (oG.Window.ActiveTabCtrl != ""){
                oG.Window.ActiveTabCtrl.UseTab()
                ogNewCtrl := WorkGui.Add(ControlType,"x" xCtrl " y" yCtrl " " ExtraOption , Default.%ControlType%.Text ExtraText) ; not possible to move the ctrl to the target tab, so create a new one
                oG.Window.ActiveTabCtrl := ""
                oG.Window.ActiveTab := ""
            }
        }
        ogNewCtrl.Visible := 1

        ogNewCtrl.Redraw()
        oControl := Default.%ControlType%
        
        aNameList := Map()
        For Index, oControlItem in oG.ControlList{
            aNameList[oControlItem.oName]:= 1
        }
        Loop{
            if aNameList.Has(oControl.Prefix A_Index){
                continue
            }
            oControl.oName := oControl.Prefix A_Index
            Break
        }
        ogNewCtrl.oName := oControl.oName
        ogNewCtrl.ControlType := ControlType
        ogNewCtrl.ExtraText := ExtraText
        ogNewCtrl.Options := ExtraOption
        if (Type(Default.%ControlType%.Text)="Array"){
            ogNewCtrl.Array := Default.%ControlType%.Text
        }
        ogNewCtrl.Events := {}
        if (!oSet.DefaultPos){
            ogNewCtrl.x := xCtrl
            ogNewCtrl.y := yCtrl
            if (!oSet.DefaultSize){
                ogNewCtrl.h := hCtrl
                ogNewCtrl.w := wCtrl
            }
        }
        ogNewCtrl.CtrlName := "Control_" oG.ControlList.index
        if (Substr(ControlType,1,3)="tab"){
            ogNewCtrl.OnEvent("Change",(GuiCtrlObj, Info)=>(GuiCtrlObj.UseTab(GuiCtrlObj.Text), oG.Window.ActiveTabCtrl := GuiCtrlObj, oG.Window.ActiveTab := GuiCtrlObj.Value))
            oG.Window.ActiveTabCtrl := ogNewCtrl
            oG.Window.ActiveTab := ogNewCtrl.Value
        }

        oG.ControlList[ogNewCtrl.CtrlName]:=ogNewCtrl
        oG.ControlList.index++
        GenerateCode()
    }
}

Gui_Select(title,text1,text2,achoices){
    guiSelect := Gui(, title)
    guiSelect.OnEvent("Close", Gui_Close)
    result := ""
    guiSelect.Add("Text", "x0 y-3 w434 h115 BackgroundWhite", "")
    guiSelect.Add("Text", "x10 y10 w145 BackgroundTrans", text1)
    guiSelect.Add("Text", "x10 y40 w260 r2 BackgroundTrans", text2)
    BtnOK := guiSelect.Add("Button", "x254 y126 w80", "&OK")
    BtnOK.OnEvent("Click",(*)=>(result:=Cbx_result.text, Gui_Close(guiSelect)))
    BtnCancel := guiSelect.Add("Button", "x340 y126 w80", "Cancel")
    BtnCancel.OnEvent("Click", (*) => (result := "", Gui_Close(guiSelect)))
    Cbx_result := guiSelect.Add("ComboBox", "x10 y71 w410", aChoices)
    guiSelect.Show("w430 h161")
    WinWaitClose(guiSelect)
    return result

    Gui_Close(thisGui) {
        guiSelect.Destroy()
        return
    }
}

WorkGui_Create(*) {

    Global WorkGui, SelGui
    Global oG := {}
    oG.Window := {}
    oG.Window.Events := {}
    oG.Window.Options := {}
    oG.Window.ActiveTab := ""
    oG.Window.ActiveTabCtrl := ""
    oG.ControlList := Map()
    oG.ControlList.index := 0

    oG.Window.title := "New Gui"
    oG.Window.oName := "MyGui"
    oG.Window.Name := ""
    oG.Window.w := 300
    oG.Window.h := 300

    WorkGui := Gui(, oG.Window.title)
    WorkGui.Selection := {}
    WorkGui.Selection.aCtrl := []
    WorkGui.oName := oG.Window.oName
    WorkGui.Opt("+Resize")
    WorkGui.Opt("+Owner" MyGui.Hwnd)
    WorkGui.OnEvent("ContextMenu", Gui_ContextMenu)
    WorkGui.Show("w" oG.Window.w " h" oG.Window.h)
    WorkGui.OnEvent("Size", Gui_Size)

    SelGui := Gui("+Parent" WorkGui.hwnd " -Caption +E0x80000 +AlwaysOnTop +LastFound +ToolWindow +OwnDialogs +0x40000000")
    SelGui.Show("NA")

    HotIfWinActive "ahk_id " WorkGui.hwnd
    Hotkey "~LButton", WorkGui_LBUTTON
    Hotkey "~^LButton", WorkGui_LBUTTON
    Hotkey "~Delete", WorkGui_Delete
    Hotkey "Left", (*) => (Selection_Move(-1,0) , GenerateCode(),UpdateSelectionBox())
    Hotkey "Right", (*) => (Selection_Move(1,0) , GenerateCode(), UpdateSelectionBox())
    Hotkey "Up", (*) => (Selection_Move(0,-1) , GenerateCode(), UpdateSelectionBox())
    Hotkey "Down", (*) => (Selection_Move(0,1) , GenerateCode(), UpdateSelectionBox())
        
         
    GenerateCode()

    Gui_ContextMenu(GuiObj, GuiCtrlObj, Item, IsRightClick, X, Y) {
        ContextMenu := Menu()
        ContextMenu.Add("Properties Window", Gui_Properties)
        ContextMenu.SetIcon("Properties Window", IconLib, -36)
        if IsObject(GuiCtrlObj){
            ContextMenu.Add("Properties Ctrl", (*)=>(GuiCtrl_Properties(GuiCtrlObj)))
            ContextMenu.SetIcon("Properties Ctrl", IconLib , -36)
            if(GuiCtrlObj.HasProp("Array")){
                ContextMenu.Add("Edit Array", gui_EditArray) ; does not work currently
                ContextMenu.Add("Delete Array", (*) => (GuiCtrlObj.Delete()))
            }
            ContextMenu.Add()
            ContextMenu.Add("Delete Ctrl", (*)=>(GuiCtrl_Delete(GuiCtrlObj)))
            ContextMenu.SetIcon("Delete Ctrl", IconLib , -45)
        }
        ContextMenu.Show()

        gui_EditArray(*) {
            ; aTemp :=GuiCtrlObj.Array.Clone()
            GuiCtrlObj.Array := EditGui(GuiCtrlObj.Array)
            GuiCtrlObj.Delete()
            GuiCtrlObj.Add(GuiCtrlObj.Array)
            ;  := aTemp
            Sleep(300)
            
            GenerateCode()
        }
    }

    
    Gui_Size(thisGui, MinMax, Width, Height){
        oG.Window.w := Width
        oG.Window.h := Height
        GenerateCode()
    }
}

WorkGui_Save(*){
    MsgBox(ogEdit_script.Text)
}

WorkGui_Import(*) {
    ToolTip("press F12 on the Window you want to clone")
    KeyWait("F12","D")
    KeyWait("F12")
    ToolTip("")
    Global WorkGui, SelGui
    Global oG := {}
    oG := {}
    WorkGui := Gui()
    WorkGui.Selection := {}
    WorkGui.Selection.aCtrl := []

    oG.Window := {}
    oG.Window.Events := {}
    oG.Window.Options := {}
    oG.Window.ActiveTab := ""
    oG.Window.ActiveTabCtrl := ""
    oG.ControlList := Map()
    oG.ControlList.index := 0
    WinID := WinGetID("A")
    WinTitle := WinGetTitle("ahk_id " WinID)
    oG.Window.title := WinTitle
    oG.Window.oName := "MyGui"
    oG.Window.Name := ""
    WinGetClientPos(&winX, &winY,,, "ahk_id " WinID)
    WinGetClientPos(,, &winClientWidth, &winClientHeight, "ahk_id " WinID)
    oG.Window.w := winClientWidth
    oG.Window.h := winClientHeight
    oG.Window.x := winX
    oG.Window.y := winY

    WindowStyle := WinGetStyle("ahk_id " WinID)
    if !(WindowStyle & 0x800000) {	; WS_BORDER
        oG.Window.Options.Border := Object()
        oG.Window.Options.Border.Option := "+Border"
    }
    if !(WindowStyle & 0x10000) {	; WS_MAXIMIZEBOX
        oG.Window.Options.MaximizeBox := Object()
        oG.Window.Options.MaximizeBox.Option := "-MaximizeBox"
    }
    if !(WindowStyle & 0x20000) {	; WS_MINIMIZEBOX
        oG.Window.Options.MinimizeBox := Object()
        oG.Window.Options.MinimizeBox.Option := "-MinimizeBox"
    }
    if (WindowStyle & 0x40000) {	; WS_SIZEBOX
        oG.Window.Options.Resize := Object()
        oG.Window.Options.Resize.Option := "+Resize"
    }
    if (WindowStyle & 0x200000) {	; WS_VSCROLL
        oG.Window.Options.VScroll := Object()
        oG.Window.Options.VScroll.Option := "+0x200000"
    }

    If (hMenu := GetMenu(WinID)) {
        oMenuBar := Array()
        oMenuBar.oName := "MyMenuBar"
        oMenuBar.type := "MenuBar"
        CloneMenuItems(hMenu, "", &oMenuBar)
        oG.Window.MenuBar := oMenuBar
        ; ObjectGui(oMenuBar)
    }

    ; for n, ClassNN in WinGetControls("ahk_id " WinID)
    for n, controlHwnd in WinGetControlsHwnd("ahk_id " WinID)
    {
        ClassNN := ControlGetClassNN(controlHwnd)
        ControlStyle := ControlGetStyle(controlHwnd)
        ControlExStyle := ControlGetExStyle(controlHwnd)
        ControlText := ControlGetText(controlHwnd)
        ControlType := ControlStyle & 0xF
        ControlGetPos(&ctrlX, &ctrlY, &ctrlWidth, &ctrlHeight, controlHwnd)
        AhkName := TranslateClassName(ClassNN)
        ControlVisible := ControlGetVisible(controlHwnd)
        if ((!ControlVisible && !oSet.ImportHiddenControls) || (AhkName="" and !oSet.ImportUnknownControls)) {
            continue
        }

        if (ControlStyle & 0xF=4 and Substr(ClassNN,1,1)="#"){
            ; This is probably the tab, ControlGetText(controlHwnd) could be used to extract the first tab
            continue
        }
        if (ClassNN ~= "^(SysHeader)"){
            continue
        }
        if (ClassNN ~= "^(ComboLBox)"){
            
            oG.ControlList[n-1].Options .= " +Simple"
            continue
        }
        Options := ""
        og.ControlList[n] := Object()
        oG.ControlList[n].oName := ClassNN
        oG.ControlList[n].Text := ControlGetText(controlHwnd)
        oG.ControlList[n].Visible := ControlVisible
        oG.ControlList[n].x := ctrlX
        oG.ControlList[n].y := ctrlY
        oG.ControlList[n].w := ctrlWidth
        oG.ControlList[n].h := ctrlHeight
        
        If (AhkName = "Button") {
            ; 1: BS_DEFPUSHBUTTON
            ; 2: BS_CHECKBOX
            ; 3: BS_AUTOCHECK
            ; 4: BS_RADIOBUTTON
            ; 5: BS_3STATE
            ; 6: BS_AUTO3STATE
            ; 9: BS_AUTORADIOBUTTON
            If (ControlType == 1) {
                AhkName := "Button"
                Options .= " +Default"
            } Else if (ControlType ~= "^(?i:2|3|5|6)$")
                AhkName := "CheckBox"
            Else if (ControlType ~= "^(?i:4|9)$")
                AhkName := "Radio"
            Else If (ControlType == 7)
                AhkName := "GroupBox"
            Else{
                AhkName := "Button"
                Options .= !(ControlStyle & 0x1) ? " +Default" : "" ;BS_DEFPUSHBUTTON
            }
            Checked := ControlGetChecked(ClassNN , "ahk_id " WinID)
            If (Checked) {
                Options .= " +Checked"
            }
        } Else If (AhkName == "ComboBox") {
            If (ControlType = 3) {
                AhkName := "DropDownList"
            } Else {
                AhkName := "ComboBox"
            }
        } Else If (AhkName == "Edit") {
            Options .= !(ControlExStyle & 0x200) ? " -E0x200" : "" ; no border
            Options .= (ControlExStyle & 0x2000) ? " +Number" : "" ; ES_NUMBER
            Options .= !(ControlExStyle & 0x4) ? " +Multi" : "" ; ES_MULTILINE
            Options .= (ControlExStyle & 0x800) ? " +ReadOnly" : "" ; ES_READONLY
        } Else If (AhkName == "Text") {
            If (ControlType = 1) {
                Options .= " +Center"
            } Else If (ControlType == 2) {
                Options .= " +Right"
            } Else If (ControlType == 3 || ControlType == 14) {
                ; 3:  SS_ICON
                ; 14: SS_BITMAP
                AhkName := "Picture"
                Options .= " 0x6 +Border"	; SS_WHITERECT
            }
            If (ControlText == "" && ctrlHeight == 2) {
                Options .= " 0x10"	; Separator
            }
        } Else If (AhkName == "Slider") {
            oG.ControlList[n].Text := SendMessage(0x400, 0, 0,ClassNN , "ahk_id " WinID)	; TBM_GETPOS
            ErrorLevel := SendMessage(0x401, 0, 0,ClassNN , "ahk_id " WinID)	; TBM_GETRANGEMIN
            Options .= " Range" . ErrorLevel
            ErrorLevel := SendMessage(0x402, 0, 0,ClassNN , "ahk_id " WinID)	; TBM_GETRANGEMAX
            Options .= "-" . ErrorLevel
            ; 2:  TBS_VERT
            ; 4:  TBS_TOP
            ; 8:  TBS_BOTH (blunt)
            ; 10: TBS_NOTICKS
            If (ControlStyle & 0x2) {
                Options .= " +Vertical"
            } Else If (ControlStyle & 0x4) {
                Options .= " +Left"
            } Else If (ControlStyle & 0x8) {
                Options .= " +Center"
            } Else If (ControlStyle & 0x10) {
                Options .= " +NoTicks"
            }
        } Else If (AhkName == "TreeView") {
            ControlText := ""
        } Else If (AhkName == "UpDown") {
            Options .= " -16"
        } Else If (AhkName == "Tab3") {
            ; itemCount := SendMessage(TCM_GETITEMCOUNT := 0x1304, , , , "ahk_id " controlHwnd)
            CurSel := SendMessage(TCM_GETCURSEL := 0x130B, 0, 0, , "ahk_id " controlHwnd)+1
            Options .= CurSel !=1 ? " Choose" CurSel : ""
            TabLabels := ControlGetTabs(controlHwnd)
            nTabs := TabLabels.Length
            oG.ControlList[n].Array := []
            Loop nTabs {
                 oG.ControlList[n].Array.Push(TabLabels[A_Index])
            }
            oG.ControlList[n].ActiveTab := TabLabels[CurSel]
        } Else If (AhkName == "Progress") {
            oG.ControlList[n].Text := SendMessage(0x408, 0, 0,ClassNN , "ahk_id " WinID)	; PBM_GETPOS
             
            If !(ControlStyle & 0x1) {
                Options .= " -Smooth"
            }
            If (ControlType == 4) {
                Options .= " +Vertical"
            }
        } Else If (AhkName == "Link" && !InStr(ControlText, "<a")) {
            ControlText := "<a>" . ControlText . "</a>"
        } else If (AhkName = "ListView"){
            ; itemCount := ListViewGetContent("Count Col", controlHwnd)
            ; itemCount := SendMessage(HDM_GETITEMCOUNT := 0x1200, , , , "ahk_id " controlHwnd) ; seems not to work
            ; itemCount := DllCall("SendMessageA", "uint", controlHwnd, "uint", HDM_GETITEMCOUNT := 0x1200, "uint", 0, "uint", 0)
            aoLVHeader := ControlGetLVHeaderInfo(controlHwnd)
            oG.ControlList[n].Array := []
            Loop aoLVHeader.Length {
                oG.ControlList[n].Array.Push(aoLVHeader[A_Index].Text)
            }

            LVContent := ListViewGetContent(, controlHwnd)
            Options .= (ControlStyle & 0x4000) ? " -Hdr" : "" ; LVS_NOCOLUMNHEADER
            Options .= (ControlStyle & 0x8000) ? " -NoSortHdr" : "" ; LVS_NOSORTHEADER
        }

        If (AhkName ~= "ComboBox|ListBox|DropDownList") {
            oG.ControlList[n].Array := ControlGetItems(controlHwnd)
        }
        If (AhkName ~= "CheckBox|Radio") {
            Options := ControlGetChecked(controlHwnd) ? " +Checked" : ""
        }
        If (AhkName ~= "StatusBar") {
            oG.ControlList[n].Sections := Array()
            loop{
                try{
                    oG.ControlList[n].Sections.Push({text:StatusBarGetText(A_index, "ahk_id " WinID)})
                } Catch{
                    break
                }
            }
        }

        ; Removal of default heights to reduce code
        if ((AhkName = "Button" and ctrlHeight = 23) || (AhkName = "CheckBox" and ctrlHeight = 16) || (AhkName = "Radio" and ctrlHeight = 13)){
            oG.ControlList[n].DeleteProp("h")
        }

        Enabled := ControlGetEnabled(controlHwnd)
        
        If (ControlExStyle & 0x08000000) {
            Options .= " +Disabled"
        }
        oG.ControlList[n].ControlType := AhkName
        oG.ControlList[n].Options := Options
         
    }
    ; Separate the Tabs
    oTabs := Map()
    
    for n, oControl in oG.ControlList {
        if (oControl.ControlType="Tab3"){
            oTabs[n]:= oControl
            oG.ControlList.Delete(n)
        }
    }
    mControlListBuffer := Map()
    Index := 1
    for n, oControl in oG.ControlList {
        if(oControl.Visible){
            for n, oTab in oTabs {
                if ((oControl.x > oTab.x) && (oControl.x < oTab.x+oTab.w) && (oControl.y > oTab.y) && (oControl.y < oTab.y + oTab.h) ){
                    if !oTab.HasProp("added"){
                        mControlListBuffer[Index] := oTab
                        oTabs[n].added := true
                        Index++
                    }
                    oControl.ActiveTabCtrl := Object()
                    oControl.ActiveTabCtrl.oName := oTab.oName
                    oControl.ActiveTab := oTab.ActiveTab
                }
            }

        }
        mControlListBuffer[Index] := oControl
        Index++
    }
    oG.ControlList := mControlListBuffer

    GenerateCode()
    return
}


GuiCtrl_Delete(GuiCtrlObj){
    if (oG.ControlList.Has(GuiCtrlObj.CtrlName)){
        oG.ControlList.Delete(GuiCtrlObj.CtrlName)
    }
    GuiCtrlObj.Visible := 0 ; We just hide the control
    GenerateCode()
}

Gui_Properties(p*) {
    if (!IsSet(WorkGui) or !IsObject(WorkGui)) {
        return
    }
    WinGetPos(&xWin, &yWin, &wWin, &hWin, WorkGui)
    ogProp := Gui(, "Window - Properties")
    ogProp.Opt("+Owner" MyGui.Hwnd)
    ogTab_Prop := ogProp.Add("Tab3", "w275 Section", ["General", "Styles", "Font", "Options", "Events"])
    ogTab_Prop.UseTab("General")
    ;
    ogProp.AddText("xs+10 ys+31 w40", "Title:")
    ogEdit_Title := ogProp.AddEdit("x+5 yp-4 w200", WorkGui.Title)
    ogProp.AddText("xs+10 y+m w40", "oName:")
    ogEdit_oName := ogProp.AddEdit("x+5 yp-4 w200", WorkGui.oName)
    ogProp.AddText("xs+10 y+m w40", "Name:")
    ogEdit_Name := ogProp.AddEdit("x+5 yp-4 w200", WorkGui.Name)

    ogProp.AddGroupBox("xs+5 y+m w250 h70", "Position")

    ogCB_x := ogProp.AddCheckbox("xs+15 yp+20 w40 ", "X:")
    ogEdit_xWin := ogProp.AddEdit("x+5 yp-4 w50 h22 ", oG.Window.HasProp("x") ? oG.Window.x : "")
    ogProp.Add("UpDown", "Range0-99999", oG.Window.HasProp("x") ? oG.Window.x : "")
    ogCB_y := ogProp.AddCheckbox("x+20 yp+4 w40 ", "Y:")
    ogEdit_yWin := ogProp.AddEdit("x+5 yp-4 w50 h22 ", oG.Window.HasProp("y") ? oG.Window.y : "")
    ogProp.Add("UpDown", "Range0-99999", oG.Window.HasProp("y") ? oG.Window.y : "")

    ogCB_w := ogProp.AddCheckbox("xs+15 y+m w40 ", "W:")
    ogEdit_wWin := ogProp.AddEdit("x+5 yp-4 w50 h22 +Number", wWin)
    ogProp.Add("UpDown", "Range0-99999", wWin)
    ogCB_h := ogProp.AddCheckbox("x+20 yp+4 w40 ", "H:")
    ogEdit_hWin := ogProp.AddEdit("x+5 yp-4 w50 h22 +Number", hWin)
    ogProp.Add("UpDown", "Range0-99999", hWin)

    ogProp.AddGroupBox("xs+5 y+m w250 h100", "Show Options")
    ogLV_ShowOpt := ogProp.AddListView("xs+15 yp+20 r4 Checked -Hdr", ["Options"])
    aShowOpt := ["Center","xCenter","yCenter","AutoSize"]
    For key, Option in aShowOpt {
        ogLV_ShowOpt.Add(, Option)
    }


    ogTab_Prop.UseTab("Font")
    ogProp.AddGroupBox("xs+5 ys+25 w250 h130", "Font")
    ogLV_Font := ogProp.Add("ListView", "xs+10 yp+20 w240 r4 -Hdr", ["Property", "Value"])
    ogLV_Font.Add("", "Name")
    ogLV_Font.Add("", "Style")
    ogLV_Font.Add("", "Size")
    ogLV_Font.Add("", "Color")

    Global fontObj := {}
    ogEdit_Font := ogProp.AddEdit("xs+10 y+m w150", )
    ogBut_SetFont := ogProp.AddButton("x+5 w60", "Change...")
    ogBut_SetFont.OnEvent("click", Pick_Font)

    ogProp.AddGroupBox("xs+5 y+10 w250 h45", "Window Color")

    ogProp.AddCheckbox("xs+10 yp+20 w80", "BackColor:")
    ogEdit_BackColor := ogProp.AddEdit("x+5 yp-4 w70 +ReadOnly", WorkGui.BackColor)
    ogLV_BGColorPreview := ogProp.AddListView("x+5 w21 h21 -Hdr Border")
    ogLV_BGColorPreview.OnEvent("click", Pick_Color)
    ogBut_SetColor := ogProp.AddButton("x+5 yp-1 w30", "Set")
    ogBut_SetColor.OnEvent("click", Pick_Color)

    ogTab_Prop.UseTab("Options")
    ogLV_Opt := ogProp.AddListView("Checked -HScroll -Hdr", ["Options","oName"])
    
    For PropName, oProp in DefaultWinOpt.OwnProps() {
        ogLV_Opt.Add(, oProp.Name,PropName)
    }

    ogLV_Opt.ModifyCol(1, 130)
    ogLV_Opt.ModifyCol(2, 0)

    ogTab_Prop.UseTab("Events")
    ogProp.AddGroupBox("xs+5 ys+25 w250 h130", "Standard Events")
    ogLV_Events := ogProp.AddListView("xp+5 yp+20 r5 Checked -Hdr", ["Events"])
    For EventName, oEvent in DefaultEvents.OwnProps(){
        if InStr(oEvent.ControlTypes,"Gui"){
            ogLV_Events.Add(, oEvent.EventName)
        }
    }
    ogLV_Events.ModifyCol(1, 100)
    
    ogTab_Prop.UseTab("")
    ogBut_OK := ogProp.AddButton("w80", "OK")
    ogBut_Cancel := ogProp.AddButton("x+5 w80", "Cancel")
    ogBut_Apply := ogProp.AddButton("x+5 w80", "Apply")
    ogBut_Apply.OnEvent("Click", Click_PropApply)
    ogProp.Show("")

    Pick_Color(ctl, info, *) {
        cc := (ogEdit_BackColor.value = "" ? "0xF0F0F0" : ogEdit_BackColor.value)	; pre-select color from gui background (optional)
        hwnd := ctl.gui.hwnd	; grab hwnd
        cc := Gui_Color(cc, hwnd, info)

        ogEdit_BackColor.Value := cc
        ogLV_BGColorPreview.Opt("+Background" cc)

    }

    Pick_Font(ctl, info) {
        Global fontObj

        If (!fontObj.HasProp("name"))	; init font obj and pre-populate settings
            fontObj := { name: "MS Shell Dlg", size: 8, color: 0x000000, strike: 0, underline: 0, italic: 0, bold: 0 }	; init font obj (optional)

        fontObj := FontSelect(fontObj, ctl.gui.hwnd)	; shows the user the font selection dialog

        If (!fontObj)
            return	; to get info from fontObj use ... bold := fontObj.bold, fontObj.name, etc.
        ogEdit_Font.Value := fontObj.str
        ogLV_Font.Modify(1, "", "Name", fontObj.name)
        ogLV_Font.Modify(2, "", "Style", StrReplace(StrReplace(fontObj.str, " c" fontObj.color), " s" fontObj.size))
        ogLV_Font.Modify(3, "", "Size", fontObj.size)
        ogLV_Font.Modify(4, "", "Color", fontObj.color)
    }

    Click_PropApply(*) {
        WorkGui.BackColor := ogEdit_BackColor.Value
        oG.Window.BackColor := ogEdit_BackColor.Value

        oG.Window.oName := ogEdit_oName.value
        WorkGui.title := ogEdit_Title.Value
        oG.Window.title := ogEdit_Title.Value
        if (ogEdit_Name.Value!=""){
            oG.Window.name := ogEdit_Name.Value
            WorkGui.name := ogEdit_Name.Value
        }
        
        (ogEdit_Name.Value != "") ? WorkGui.Name := ogEdit_Name.Value: ""
        ;WorkGui.Move(ogEdit_xWin.value, ogEdit_yWin.value, ogEdit_wWin.value, ogEdit_hWin.value)

        ; Options
        loop ogLV_Opt.GetCount()
        {
            Option := ogLV_Opt.GetText(A_Index,2)
            RowChecked := (A_Index = (ogLV_Opt.GetNext(A_Index - 1, "Checked")))
            if (RowChecked) {
                if !oG.Window.Options.HasProp(Option) {
                    oG.Window.Options.%Option% := DefaultWinOpt.%Option%
                    WorkGui.Opt(oG.Window.Options.%Option%.Option)
                }
            } else {
                if oG.Window.Options.HasProp(Option) {
                    oG.Window.Options.DeleteProp(Option)
                    ROption := StrReplace(StrReplace(DefaultWinOpt.%Option%.Option, "+","[+]"), "-", "[-]")
                    ROption := StrReplace(StrReplace(ROption, "[+]","-"), "[-]", "+")
                    WorkGui.Opt(ROption)
                }
            }
        }
        ; Events
        loop ogLV_Events.GetCount()
        {
            Event := ogLV_Events.GetText(A_Index)
            RowChecked := (A_Index = (ogLV_Events.GetNext(A_Index - 1, "Checked")))
            if (RowChecked){
                if !oG.Window.Events.HasProp(Event){
                    oG.Window.Events.%Event% := DefaultEvents.%Event%
                }
            }
            else{
                if oG.Window.Events.HasProp(Event) {
                    oG.Window.Events.DeleteProp(Event)
                }
            }
        }

        GenerateCode()
    }
}

GuiCtrl_Properties(GuiCtrlObj) {
    oControl := oG.ControlList[GuiCtrlObj.CtrlName]
    ControlGetPos(&xCtrl, &yCtrl, &wCtrl, &hCtrl, GuiCtrlObj)

    ogProp := Gui(, "Control - Properties")
    ogProp.Opt("+Owner" MyGui.Hwnd)
    ogTab_Prop := ogProp.Add("Tab3", "w275 Section", ["General", "Styles", "Font", "Options", "Events"])
    ogTab_Prop.UseTab("General")
    ;
    ogProp.AddText("xs+10 ys+31 w40", "Type:")
    ogEdit_ControlType := ogProp.AddEdit("x+5 yp-4 w200 ReadOnly", oControl.ControlType)
    ogProp.AddText("xs+10 y+m w40", "oName:")
    ogEdit_oName := ogProp.AddEdit("x+5 yp-4 w200", oControl.oName)
    ogProp.AddText("xs+10 y+m w40", "Text:")
    if (oControl.HasProp("Array")) {
        Text := '['
        for k, v in oControl.Array
        {
            Text .= (A_Index = 1 ? '' : ',') '"' v '"'
        }
        Text .= "]"
    } else{
        Text := oControl.Text
    }
    ogEdit_Text := ogProp.AddEdit("x+5 yp-4 w200", Text)

    ogProp.AddGroupBox("xs+5 y+m w250 h70", "Position")

    ogCB_x := ogProp.AddCheckbox("xs+15 yp+20 w40", "X:")
    IsNumber(xCtrl) & ogCB_x.Value := True
    ogEdit_xCtrl := ogProp.AddEdit("x+5 yp-4 w50 h22 +Number", xCtrl)
    ogEdit_xCtrl.Enabled := ogCB_x.value
    ogCB_x.OnEvent("Click",(*)=>(ogEdit_xCtrl.Enabled := ogCB_x.value))
    ogProp.Add("UpDown", "Range0-99999", xCtrl)
    
    ogCB_y := ogProp.AddCheckbox("x+20 yp+4 w40 ", "Y:")
    IsNumber(yCtrl) & ogCB_y.Value := True
    ogEdit_yCtrl := ogProp.AddEdit("x+5 yp-4 w50 h22 +Number", yCtrl)
    ogEdit_yCtrl.Enabled := ogCB_y.value
    ogCB_y.OnEvent("Click", (*) => (ogEdit_yCtrl.Enabled := ogCB_y.value))
    ogProp.Add("UpDown", "Range0-99999", yCtrl)

    ogCB_h := ogProp.AddCheckbox("xs+15 y+m w40 ", "W:")
    ogEdit_wCtrl := ogProp.AddEdit("x+5 yp-4 w50 h22 +Number", wCtrl)
    ogProp.Add("UpDown", "Range0-99999", wCtrl)
    ogCB_h := ogProp.AddCheckbox("x+20 yp+4 w40 ", "H:")
    ogEdit_hCtrl := ogProp.AddEdit("x+5 yp-4 w50 h22 +Number", hCtrl)
    ogProp.Add("UpDown", "Range0-99999", hCtrl)

    ogTab_Prop.UseTab("Font")
    ogProp.AddGroupBox("xs+5 ys+25 w250 h130", "Font")
    ogLV_Font := ogProp.Add("ListView", "xs+10 yp+20 w240 r4 -Hdr", ["Property", "Value"])
    ogLV_Font.Add("", "Name")
    ogLV_Font.Add("", "Style")
    ogLV_Font.Add("", "Size")
    ogLV_Font.Add("", "Color")

    Global fontObj := {}
    ogEdit_Font := ogProp.AddEdit("xs+10 y+m w150", )
    ogBut_SetFont := ogProp.AddButton("x+5 w60", "Change...")
    ogBut_SetFont.OnEvent("click", Pick_Font)

    ogProp.AddGroupBox("xs+5 y+10 w250 h45", "Window Color")

    ogProp.AddCheckbox("xs+10 yp+20 w80", "BackColor:")
    ogEdit_BackColor := ogProp.AddEdit("x+5 yp-4 w70 +ReadOnly", WorkGui.BackColor)
    ogLV_BGColorPreview := ogProp.AddListView("x+5 w21 h21 -Hdr Border")
    ogLV_BGColorPreview.OnEvent("click", Pick_Color)
    ogBut_SetColor := ogProp.AddButton("x+5 yp-1 w30", "Set")
    ogBut_SetColor.OnEvent("click", Pick_Color)

    ogTab_Prop.UseTab("Options")
    ogLV_Opt := ogProp.AddListView("Checked -HScroll -Hdr", ["Options"])
    ;aWinOpt := Array("AlwaysOnTop","Border","Caption","Disabled","DPIScale","LastFound","MaximizeBox","MinimizeBox","OwnDialogs","Resize","SysMenu","Theme","ToolWindow")
    For OptionName, oOpt in DefaultCtrlOptions.OwnProps() {
        if (InStr(oOpt.ControlTypes, oControl.ControlType) or oOpt.ControlTypes="All") {
            ogLV_Opt.Add(, oOpt.Name)
        }
    }
    ogLV_Opt.ModifyCol(1, 100)

    ogTab_Prop.UseTab("Events")
    ogProp.AddGroupBox("xs+5 ys+25 w250 h160", "Standard Events")
    ogLV_Events := ogProp.AddListView("xp+5 yp+20 r5 Checked -Hdr", ["Events"])

    For EventName, oEvent in DefaultEvents.OwnProps(){
        if InStr(oEvent.ControlTypes,oControl.ControlType){
            ogLV_Events.Add(, oEvent.EventName)
        }
    }
    
    ogLV_Events.ModifyCol(1, 100)
    ogCB_Event_Functions := ogProp.AddCheckbox("w80", "Function")
    
    ogTab_Prop.UseTab("")
    ogBut_OK := ogProp.AddButton("w80", "OK")
    ogBut_Cancel := ogProp.AddButton("x+5 w80", "Cancel")
    ogBut_Apply := ogProp.AddButton("x+5 w80", "Apply")
    ogBut_Apply.OnEvent("Click", Click_PropApply)
    ogProp.Show("")

    Pick_Color(ctl, info, *) {
        cc := (ogEdit_BackColor.value = "" ? "0xF0F0F0" : ogEdit_BackColor.value)	; pre-select color from gui background (optional)
        hwnd := ctl.gui.hwnd	; grab hwnd
        cc := Gui_Color(cc, hwnd, info)

        ogEdit_BackColor.Value := cc
        ogLV_BGColorPreview.Opt("+Background" cc)

    }

    Pick_Font(ctl, info) {
        Global fontObj

        If (!fontObj.HasProp("name"))	; init font obj and pre-populate settings
            fontObj := { name: "MS Shell Dlg", size: 8, color: 0x000000, strike: 0, underline: 0, italic: 0, bold: 0 }	; init font obj (optional)

        fontObj := FontSelect(fontObj, ctl.gui.hwnd)	; shows the user the font selection dialog

        If (!fontObj)
            return	; to get info from fontObj use ... bold := fontObj.bold, fontObj.name, etc.
        ogEdit_Font.Value := fontObj.str
        ogLV_Font.Modify(1, "", "Name", fontObj.name)
        ogLV_Font.Modify(2, "", "Style", StrReplace(StrReplace(fontObj.str, " c" fontObj.color), " s" fontObj.size))
        ogLV_Font.Modify(3, "", "Size", fontObj.size)
        ogLV_Font.Modify(4, "", "Color", fontObj.color)
    }

    Click_PropApply(*) {
        
        oCtrl := oG.ControlList[GuiCtrlObj.CtrlName]
        if (!oCtrl.HasProp("Array")){
            oCtrl.text := ogEdit_Text.Value
            GuiCtrlObj.text := ogEdit_Text.Value
        }

        if (ogEdit_oName.value != oCtrl.oName) {
            oCtrl.oName := ogEdit_oName.Value
            GuiCtrlObj.oName := ogEdit_oName.Value
        }

        ; WorkGui.BackColor := ogEdit_BackColor.Value
        ; oG.Window.BackColor := ogEdit_BackColor.Value

        ; WorkGui.Title := ogEdit_Title.Value
        ; oG.Window.title := ogEdit_Title.Value
        ; (ogEdit_Name.Value != "") ? WorkGui.Name := ogEdit_Name.Value: ""
        ; WorkGui.Move(ogEdit_xWin.value, ogEdit_yWin.value, ogEdit_wWin.value, ogEdit_hWin.value)

        ; Events
        
        if(ogCB_x.value and (!oCtrl.HasProp("x") or ogEdit_xCtrl.Value!= oCtrl.x) ){
            oCtrl.x := ogEdit_xCtrl.Value
            ControlMove(oCtrl.x, , , , GuiCtrlObj)
        }
        if (ogCB_y.value and (!oCtrl.HasProp("y") or ogEdit_yCtrl.Value != oCtrl.y)) {
            oCtrl.y := ogEdit_yCtrl.Value
            ControlMove(, oCtrl.y, , , GuiCtrlObj)
        }
        
        loop ogLV_Events.GetCount()
        {
            Event := ogLV_Events.GetText(A_Index)
            RowChecked := (A_Index = (ogLV_Events.GetNext(A_Index - 1, "Checked")))
            if (RowChecked){
                if !oCtrl.Events.HasProp(Event){
                    oCtrl.Events.%Event% := DefaultEvents.%Event%
                    if (ogCB_Event_Functions.value){
                        oCtrl.Events.%Event%.EventFunctionName := oCtrl.Events.%Event%.EventName
                    }
                }
            }
            else{
                if (oCtrl.HasProp("Events")){
                    if oCtrl.Events.HasProp(Event) {
                        oCtrl.Events.DeleteProp(Event)
                    }
                }
                
            }
        }
        oG.ControlList[GuiCtrlObj.CtrlName] := oCtrl
        GenerateCode()
    }
}

GenerateCode() {
    global
    if (!IsSet(WorkGui) or !IsObject(WorkGui)) {
        return
    }
    CRLF := "`n`r"
    Header := "#SingleInstance Force" . CRLF CRLF
    Indent := A_Tab
    ; Keep track of the active tab
    GuiTabCtrl := ""
    GuiTab := ""

    Code := ""
    Code .= oG.Window.oName '_Create()' CRLF
    Code .= 'Return' CRLF CRLF
    Code .= oG.Window.oName '_Create(){' CRLF
    Code .= Indent oG.Window.oName ' := Gui(' ', "' oG.Window.title '")' CRLF
    Code .= oG.Window.name= "" ? "" :  Indent oG.Window.oName '.name := "' oG.Window.name '"' CRLF

    
    Options := ""
    For OptionName, oOption in oG.Window.Options.OwnProps() {
        if oOption.HasProp("Option"){
            Options .= Options="" ? oOption.Option : " " oOption.Option
        }
    }
    Code .= Options="" ? "" :Indent oG.Window.oName '.Opt("' Options '")' CRLF
    
    For EventName, oEvent in oG.Window.Events.OwnProps() {
        Code .= Indent oG.Window.oName '.OnEvent("' oEvent.EventName '", (' oEvent.Parameters ')=>())' CRLF
    }

    Code .= oG.Window.HasProp("MenuBar") ? CRLF Indent "; MenuBar of Gui" CRLF GenerateMenuCode(oG.Window.MenuBar) Indent oG.Window.oName ".MenuBar := " oG.Window.MenuBar.oName CRLF CRLF : "" 
    ; Code .= (oG.Window.HasProp("MenuBar") and oG.Window.MenuBar != "") ? CRLF Indent StrReplace(oG.Window.MenuBar, "`n", "`n" Indent) CRLF Indent oG.Window.oName '.MenuBar := MyMenuBar' CRLF CRLF : ""
    
    Code .= (oG.Window.HasProp("BackColor") and oG.Window.BackColor != "") ? Indent oG.Window.oName '.BackColor := ' oG.Window.BackColor CRLF : ""
    Code .= CRLF

    if (oG.ControlList.Count>0) {
        For Each, oControl in oG.ControlList{
            Text := oControl.Text
            if((!oControl.HasProp("ActiveTabCtrl") and GuiTabCtrl !="")){
                Code .= Indent GuiTabCtrl '.UseTab()' CRLF
                GuiTabCtrl :=  ""
                GuiTab := ""
            } else if (oControl.HasProp("ActiveTabCtrl") and oControl.ActiveTabCtrl.HasProp("oName")and (GuiTabCtrl != oControl.ActiveTabCtrl.oName or oControl.ActiveTab != GuiTab)){
                Code .= Indent oControl.ActiveTabCtrl.oName '.UseTab("' oControl.ActiveTab '")' CRLF
                GuiTabCtrl := oControl.ActiveTabCtrl.oName
                GuiTab := oControl.ActiveTab
            }
            if (oControl.HasProp("Array")) {
                Text := '['
                for k, v in oControl.Array
                {
                    Text .= (A_Index = 1 ? '' : ',') '"' v '"'
                }
                Text .= "]"
            } else {
                Text := (oControl.HasProp("ExtraText") and oControl.ExtraText != "") ? oControl.ExtraText " " oControl.Text : oControl.Text
                Text := InStr(Text,'"') ? "'" Text "'" :  '"' Text '"'
            }
            
            Options := (oControl.HasProp("x") and oControl.x != "") ? "x" oControl.x : ""
            Options .= (oControl.HasProp("y") and oControl.y != "") ? " y" oControl.y : ""
            Options .= (oControl.HasProp("w") and oControl.w != "") ? " w" oControl.w : ""
            Options .= (oControl.HasProp("h") and oControl.h != "") ? " h" oControl.h : ""
            Options .= (oControl.HasProp("Visible") and !oControl.Visible) ? " +Hidden" : ""
            Options .= (oControl.HasProp("Options") and oControl.Options != "") ? " " oControl.Options : ""
            Options := (Options = "") ? "" : '"' trim(Options) '"'

            Code .= (oControl.ControlType = "") ? Indent "; " : Indent ; comment out not defined types
            Code .=  oControl.oName ' := ' oG.Window.oName '.Add("' oControl.ControlType '", ' Options ', ' Text ')' CRLF
            If (oControl.ControlType ~= "DropDownList|ComboBox" and oControl.HasProp("text") and oControl.text !=""){
                Code .= Indent oControl.oName '.text := "' oControl.text '"' CRLF
            }
            if (oControl.ControlType="StatusBar" && oControl.HasProp("Sections")){
                Code .= Indent oControl.oName ".SetParts("
                loop oControl.Sections.length-1 {
                    Code .= (A_Index!=1) ? "," : ""
                    Code .= oControl.Sections[A_Index].HasProp("Width") ? oControl.Sections[A_Index].Width : "100"
                }
                Code .= ")" CRLF
                loop oControl.Sections.length{
                    Code .= Indent oControl.oName '.SetText("' oControl.Sections[A_Index].text '", ' A_Index ')' CRLF
                }
            }

            if (oControl.HasProp("Events")){
                For EventName, oEvent in oControl.Events.OwnProps() {
                    if (oEvent.EventFunctionName!=""){
                        Callback := oEvent.EventFunctionName "_" oControl.oName
                    }else{
                        Callback := '(' oEvent.Parameters ')=>()'
                    }
                    Code .= Indent oControl.oName '.OnEvent("' EventName '", ' Callback ')' CRLF
                }
            }
            if (Substr(oControl.ControlType, 1, 3) = "tab") {
                GuiTabCtrl := oControl.oName
                GuiTab := 1
            }
        }
    }
    Options := oG.Window.HasProp("x") and oG.Window.x != "" ? "x" oG.Window.x : ""
    Options .= oG.Window.HasProp("y") and oG.Window.y != "" ? " y" oG.Window.y : ""
    Options .= oG.Window.HasProp("w") and oG.Window.w != "" ? " w" oG.Window.w : ""
    Options .= oG.Window.HasProp("h") and oG.Window.h != "" ? " h" oG.Window.h : ""
    Options := Options = "" ? "" : '"' trim(Options) '"'
    Code .= Indent oG.Window.oName '.Show(' Options ')' CRLF
    Code .= Indent 'Return' CRLF

    if (oG.ControlList.Count>0) {
        For Each, oControl in oG.ControlList
        {
            if (oControl.HasProp("Events")){
                For EventName, oEvent in oControl.Events.OwnProps() {
                    if (oEvent.EventFunctionName != "") {
                        Code .= Indent CRLF Indent oEvent.EventFunctionName "_" oControl.oName "(" oEvent.Parameters "){" Indent CRLF Indent CRLF Indent "}" CRLF
                    }
                }
            }
            
        }
    }
    Code .= '}' CRLF
    ogEdit_script.Value := ""
    ogEdit_script.Value := Header Code
}

GenerateMenuCode(oMenu, Indent := "`t"){
    CRLF := "`n`r"
    Code := Indent oMenu.oName " := " (oMenu.HasProp("Type") ? oMenu.Type : "Menu") "()" CRLF
    MenuObjectName := oMenu.oName
    for Index, oMenuItem in oMenu {
        if (type(oMenuItem)="Array"){
            Code .= GenerateMenuCode(oMenuItem)
            Code .= Indent MenuObjectName '.Add("' oMenuItem.name '",' oMenuItem.oName ')' CRLF
        } else if (oMenuItem="Separator"){
            Code .= Indent MenuObjectName '.Add()' CRLF
        } else{
            Code .= Indent MenuObjectName '.Add("' oMenuItem.name '",(ItemName, ItemPos, MyMenu)=>(MsgBox(ItemName)))' CRLF
        }
    }
    return Code
}

Gui_Color(cc, hwnd, info, *) {
    Global defColor := [0xAA0000, 0x00AA00, 0x0000AA]
    cc := ColorSelect(cc, hwnd, &defColor, 0)	; specifying start color, parent window, starting custom colors, and basic display

    If (cc = -1){
        Exit
    }

    colorList := ""
    For k, v in defColor	; if user changes Custom Colors, they will be stored in defColor array
        If v
            colorList .= "Index: " k " / Color: " Format("0x{:06X}", v) "`r`n"

    Return cc
}

;-------------------------------------------------------------------------------
WriteINI(&Array2D, INI_File :="") {	; write 2D-array to INI-file
    ;-------------------------------------------------------------------------------
    INI_File := INI_File="" ? Regexreplace(A_scriptName,"(.*)\..*","$1.ini") : INI_File
    for SectionName, Entry in Array2D.OwnProps() {
        Pairs := ""

        for Key, Value in Entry.OwnProps()
            Pairs .= Key "=" Value "`n"
        IniWrite(Pairs, INI_File, SectionName)
    }
}

;-------------------------------------------------------------------------------
ReadINI(INI_File:="", oResult := "") {	; return 2D-array from INI-file
    INI_File := INI_File = "" ? Regexreplace(A_scriptName, "(.*)\..*", "$1.ini") : INI_File
    oResult := IsObject(oResult) ? oResult : Object()
    if !FileExist(INI_File) {
        return oResult
    }
    oResult.Section := Object()
    SectionNames := IniRead(INI_File)
    for each, Section in StrSplit(SectionNames, "`n") {
        OutputVar_Section := IniRead(INI_File, Section)
        if !oResult.HasOwnProp(Section){
            oResult.%Section% := Object()
        }
        for each, Haystack in StrSplit(OutputVar_Section, "`n"){
            RegExMatch(Haystack, "(.*?)=(.*)", &match)
            ArrayProperty := match[1]
            oResult.%Section%.%ArrayProperty% := match[2]
        }
    }
    return oResult
}

WorkGui_LBUTTON(*){
    global WorkGui
    MouseGetPos(&xMouse, &yMouse, &WinHwndMouse, &ControlHwndMouse, 2)
    if (WinHwndMouse != WorkGui.hwnd){
        return
    }
    WinGetClientPos(&WinX, &WinY, , , WorkGui)
    GuiControlObj := GuiCtrlFromHwnd(ControlHwndMouse)
    
    MouseXWin := MouseX - WinX
    MouseYWin := MouseY - WinY
    cursor := "Default"
    xHotspot := 0
    yHotspot := 0
    XPos := ""
    yPos := ""
    DummyVar := ""
    if (WorkGui.Selection.HasProp("X1") and WorkGui.Selection.X1 != "") {
        if (Abs(MouseXWin - WorkGui.Selection.X1) < 5 and Abs(MouseYWin - WorkGui.Selection.Y1) < 5) {
            cursor := "SIZENWSE"
            XPos := "x1"
            yPos := "y1"
        } else if (Abs(MouseXWin - WorkGui.Selection.X2) < 5 and Abs(MouseYWin - WorkGui.Selection.Y2) < 5) {
            cursor := "SIZENWSE"
            XPos := "x2"
            yPos := "y2"
        } else if (Abs(MouseXWin - WorkGui.Selection.X1) < 5 and Abs(MouseYWin - WorkGui.Selection.Y2) < 5) {
            cursor := "SIZENESW"
            XPos := "x1"
            yPos := "y2"
        } else if (Abs(MouseXWin - WorkGui.Selection.X2) < 5 and Abs(MouseYWin - WorkGui.Selection.Y1) < 5) {
            cursor := "SIZENESW"
            XPos := "x2"
            yPos := "y1"
        } else if (Abs(MouseXWin - WorkGui.Selection.X1) < 5 and Abs(MouseYWin - (WorkGui.Selection.Y1 + WorkGui.Selection.Y2) / 2) < 5) {
            cursor := "SizeWE"
            XPos := "x1"
            yPos := "DummyVar"
        } else if (Abs(MouseXWin - WorkGui.Selection.X2) < 5 and Abs(MouseYWin - (WorkGui.Selection.Y1 + WorkGui.Selection.Y2) / 2) < 5) {
            cursor := "SizeWE"
            XPos := "x2"
            yPos := "DummyVar"
        } else if (Abs(MouseXWin - (WorkGui.Selection.X1 + WorkGui.Selection.X2) / 2) < 5 and Abs(MouseYWin - WorkGui.Selection.Y1) < 5) {
            cursor := "SIZENS"
            XPos := "DummyVar"
            yPos := "y1"
        } else if (Abs(MouseXWin - (WorkGui.Selection.X1 + WorkGui.Selection.X2) / 2) < 5 and Abs(MouseYWin - WorkGui.Selection.Y2) < 5) {
            cursor := "SIZENS"
            XPos := "DummyVar"
            yPos := "y2"
        } else if (MouseXWin > WorkGui.Selection.X1 and MouseXWin < WorkGui.Selection.X2 and MouseYWin > WorkGui.Selection.Y1 and MouseYWin < WorkGui.Selection.Y2) {
            cursor := "SizeAll"
        }
    }
    if(cursor = "SizeAll" and WorkGui.Selection.HasProp("Object") and WorkGui.Selection.Object != ""){ ; Moving the Control
        xMouse_Prev := xMouse
        yMouse_Prev := yMouse
        MouseGetPos(&xMouseInit, &yMouseInit)
        WorkGui.Selection.Object.Getpos(&xInit, &yInit, &wInit, &hInit)
        loop{
            MouseGetPos(&xMouse, &yMouse, &WinHwndMouse)
            xMouse := oSet.SnapToGrid ? Round(xMouse / 5) * 5 : xMouse
            yMouse := oSet.SnapToGrid ? Round(yMouse / 5) * 5 : yMouse
            if (xMouse_Prev != xMouse or yMouse_Prev != yMouse) {
                
                XCtrl := xInit - xMouseInit + xMouse
                YCtrl := yInit - yMouseInit + yMouse

                ; Enableling flipping of coordinates
                WorkGui.Selection.Object.Move(XCtrl, YCtrl)
                for oControl in WorkGui.Selection.aCtrl
                {
                    if (WorkGui.Selection.Object=oControl){
                        continue
                    }
                    oControl.GetPos(&Xc, &Yc)
                    oControl.Move(Xc+xMouse-xMouse_Prev, Yc+yMouse - yMouse_Prev)
                }

                WorkGui.Selection.Object.GetPos(&X, &Y, &W, &H)
                WorkGui.Selection.x1 := X - 1
                WorkGui.Selection.x2 := X + w
                WorkGui.Selection.y1 := Y - 1
                WorkGui.Selection.y2 := Y + H
                UpdateSelectionBox()
                WinRedraw(SelGui)
            }

            xMouse_Prev := xMouse
            yMouse_Prev := yMouse
            if !GetKeyState("LButton") {
                oControl := oG.ControlList[WorkGui.Selection.Object.CtrlName]
                WorkGui.Selection.Object.GetPos(&X, &Y, &W, &H)
                (xInit != x & oControl.x := x)
                (yInit != y & oControl.y := y)
                oG.ControlList[WorkGui.Selection.Object.CtrlName] := oControl
                WorkGui.Selection.Object.Redraw()
                GenerateCode()
                return
            }
        }
    }
    if (XPos != "" and WorkGui.Selection.HasProp("Object") and WorkGui.Selection.Object !=""){
        xMouse_Prev := xMouse
        yMouse_Prev := yMouse
        WorkGui.Selection.Object.Getpos(&xInit, &yInit, &wInit, &hInit)
        Loop {
            MouseGetPos(&xMouse, &yMouse, &WinHwndMouse)
            xMouse := oSet.SnapToGrid ? Round(xMouse / 5) * 5 : xMouse
            yMouse := oSet.SnapToGrid ? Round(yMouse / 5) * 5 : yMouse

            WinGetClientPos(&xWin, &yWin, , , WorkGui)
            if (xMouse_Prev != xMouse or yMouse_Prev != yMouse) {
                WorkGui.Selection.Object.Getpos(&x1, &y1, &wCtrl, &hCtrl)
                x2 := x1 + wCtrl
                y2 := y1 + hCtrl
                %XPos% := xMouse - xWin
                %yPos% := yMouse - yWin

                ; Enableling flipping of coordinates
                xPos := xPos="x1" and x1>x2 ? "x2" : xPos = "x2" and x1 > x2 ? "x1" : xPos
                yPos := yPos="y1" and y1>y2 ? "y2" : yPos = "y2" and y1 > y2 ? "y1" : yPos
                XCtrl := Min(x1, x2)
                YCtrl := Min(y1, y2)
                wCtrl := Max(x1, x2) - XCtrl
                hCtrl := Max(y1, y2) - YCtrl
                WorkGui.Selection.Object.Move(XCtrl, YCtrl, wCtrl, hCtrl)

                WorkGui.Selection.Object.GetPos(&X, &Y, &W, &H)
                WorkGui.Selection.x1 := X - 1
                WorkGui.Selection.x2 := X + w
                WorkGui.Selection.y1 := Y - 1
                WorkGui.Selection.y2 := Y + H
                UpdateSelectionBox()
                WinRedraw(SelGui)
            }
            
            xMouse_Prev := xMouse
            yMouse_Prev := yMouse
            if !GetKeyState("LButton") {
                oControl := oG.ControlList[WorkGui.Selection.Object.CtrlName]
                WorkGui.Selection.Object.GetPos(&X, &Y, &W, &H)
                (xInit != x & oControl.x := x)
                (yInit != y & oControl.y := y)
                (wInit != w & oControl.w := w)
                (hInit != h & oControl.h := h)
                oG.ControlList[WorkGui.Selection.Object.CtrlName] := oControl
                WorkGui.Selection.Object.Redraw()
                GenerateCode()
                return
            }
        }
        
    }
    if (GuiControlObj.HasProp("oName") and GuiControlObj.Gui = WorkGui){
        GuiControlObj.GetPos(&X,&Y,&W,&H)
        if GetKeyState("Ctrl") and IsObject(WorkGui.Selection.Object) {
            WorkGui.Selection.aCtrl.Push(WorkGui.Selection.Object)
        }
        WorkGui.Selection.Object := GuiControlObj
        WorkGui.Selection.x1 := X-1
        WorkGui.Selection.x2 := X+w
        WorkGui.Selection.y1 := Y-1
        WorkGui.Selection.y2 := Y+H
    } else{
        WorkGui.Selection.Object := ""
        WorkGui.Selection.x1 := ""
        WorkGui.Selection.x2 := ""
        WorkGui.Selection.y1 := ""
        WorkGui.Selection.y2 := ""
        if !GetKeyState("Ctrl"){
            WorkGui.Selection.aCtrl := [] ; Clear the selection array
        }
    }
    if !GetKeyState("Ctrl"){
        WorkGui.Selection.aCtrl := [] ; Clear the selection array
    } else{
        if (IsObject(GuiControlObj) and InStr(type(GuiControlObj), "Gui.") and GuiControlObj.Gui = WorkGui) {
            IsSelected := 0
            for index, oCtrl in WorkGui.Selection.aCtrl{
                if(oCtrl=GuiControlObj){
                    IsSelected := 1
                    WorkGui.Selection.aCtrl.RemoveAt(Index)
                    WorkGui.Selection.Object := ""
                    WorkGui.Selection.x1 := ""
                    WorkGui.Selection.x2 := ""
                    WorkGui.Selection.y1 := ""
                    WorkGui.Selection.y2 := ""
                    break
                }
            }
            if !IsSelected{
                WorkGui.Selection.aCtrl.Push(GuiControlObj)
            }
        }
    }
    UpdateSelectionBox() 
}

WorkGui_Delete(*){
    if (WorkGui.Selection.HasProp("Object") and WorkGui.Selection.Object != ""){
        GuiCtrl_Delete(WorkGui.Selection.Object)
        WorkGui.Selection.Object := ""
        WorkGui.Selection.x1 := ""
        WorkGui.Selection.x2 := ""
        WorkGui.Selection.y1 := ""
        WorkGui.Selection.y2 := ""
        for oControl in WorkGui.Selection.aCtrl
        {
            GuiCtrl_Delete(oControl)
        }
        WorkGui.Selection.aCtrl:= Array()
        GenerateCode()
        UpdateSelectionBox()
    }
}

Selection_Move(xOffset,yOffset,*){
    WorkGui.Selection.Object.GetPos(&Xc, &Yc)
    WorkGui.Selection.Object.Move(Xc + xOffset, Yc + yOffset)
    oG.ControlList[WorkGui.Selection.Object.CtrlName].x := Xc +xOffset
    oG.ControlList[WorkGui.Selection.Object.CtrlName].y := Yc +yOffset
    for oControl in WorkGui.Selection.aCtrl
    {
        if (WorkGui.Selection.Object = oControl) {
            continue
        }
        oControl.GetPos(&Xc, &Yc)
        oControl.Move(Xc + xOffset, Yc + yOffset)
        oG.ControlList[oControl.CtrlName].x := Xc + xOffset
        oG.ControlList[oControl.CtrlName].y := Yc + yOffset
    }
    WorkGui.Selection.x1 := WorkGui.Selection.x1 + xOffset
    WorkGui.Selection.x2 := WorkGui.Selection.x2 + xOffset
    WorkGui.Selection.y1 := WorkGui.Selection.y1 + yOffset
    WorkGui.Selection.y2 := WorkGui.Selection.y2 + yOffset
}

Selection_CopyProp(prop,function := "min"){
    xList := Array()
    xwList := Array()
    yList := Array()
    yhList := Array()
    wList := Array()
    hList := Array()

    for oControl in WorkGui.Selection.aCtrl
    {
        oControl.GetPos(&Xc, &Yc, &Wc, &Hc)
        xList.Push(Xc)
        xwList.Push(Xc+Wc)
        yList.Push(Yc)
        yhList.Push(Yc+Hc)
        wList.Push(Wc)
        hList.Push(Hc)
    }

    ; (Instr(prop,"x") ? WorkGui.Selection.Object.Move(%function%(xList)) : "")
    ; WorkGui.Selection.Object.GetPos(&Xc, &Yc, &Wc, &Hc)
    ; oG.ControlList[WorkGui.Selection.Object.CtrlName].x := Xc
    ; oG.ControlList[WorkGui.Selection.Object.CtrlName].y := Yc
    for oControl in WorkGui.Selection.aCtrl
    {
        oControl.GetPos(&Xc, &Yc, &Wc, &Hc)
        (prop = "x" ? oControl.Move(%function%(xList*)) : "")
        (prop = "xw" ? oControl.Move(%function%(xwList*)-Wc) : "")
        (prop = "y" ? oControl.Move(,%function%(yList*)) : "")
        (prop = "yh" ? oControl.Move(,%function%(yhList*)-Hc) : "")
        (prop = "w" ? oControl.Move(,,%function%(wList*)) : "")
        (prop = "h" ? oControl.Move(,,,%function%(hList*)) : "")
        oControl.GetPos(&Xc, &Yc, &Wc, &Hc)

        oG.ControlList[oControl.CtrlName].x := Xc
        oG.ControlList[oControl.CtrlName].y := Yc
    }
    WorkGui.Selection.Object.GetPos(&Xc, &Yc, &Wc, &Hc)
    WorkGui.Selection.x1 := Xc
    WorkGui.Selection.x2 := Xc+Wc
    WorkGui.Selection.y1 := Yc
    WorkGui.Selection.y2 := Yc+Hc
}

WM_MOUSEMOVE(wParam, lParam, msg, hwnd) {

    global
    static Cursor_Old := ""
    static PrevHwnd := 0
    static HoverControl := 0
    currControl := GuiCtrlFromHwnd(Hwnd)

    ; Setting the tooltips for controls with a property tooltip
    if (Hwnd != PrevHwnd) {
        Text := "", ToolTip()	; Turn off any previous tooltip.
        if CurrControl {
            if CurrControl.HasProp("ToolTip") {
                CheckHoverControl := () => hwnd != prevHwnd ? (SetTimer(DisplayToolTip, 0), SetTimer(CheckHoverControl, 0)) : ""
                DisplayToolTip := () => (ToolTip(CurrControl.ToolTip), SetTimer(CheckHoverControl, 0))
                SetTimer(CheckHoverControl, 50)	; Checks if hovered control is still the same
                SetTimer(DisplayToolTip, -500)
            }
        }
        PrevHwnd := Hwnd
    }
    if (isSet(WorkGui)) {
        MouseGetPos(&MouseX, &MouseY, &OutputVarWin, &HwndControl, 2)
        WinGetPos(&WinX, &WinY, , , WorkGui)
        WinGetClientPos(&WinX, &WinY, , , WorkGui)
        if (false) {
            MouseXpx := Round((MouseX - WinX))
            MouseYpx := Round((MouseY - WinY))
            ; StatusBarSetText2(SB, MouseXpx ", " MouseYpx " px", 1)
            ; if (Gui1.RunUpdate = 1) {
            ;     if (GetKeyState("LButton") or GetKeyState("RButton")) {
            ;         SB.SetText(MouseXpx - WorkGui.Selection.X1 " x " MouseYpx - WorkGui.Selection.Y1 " px", 2)
            ;         if (WorkGui.Selection.X2 != MouseXpx or WorkGui.Selection.Y2 != MouseYpx) {
            ;             WorkGui.Selection.Points .= "|" MouseXpx "," MouseYpx
            ;         }
            ;         WorkGui.Selection.X2 := MouseXpx
            ;         WorkGui.Selection.Y2 := MouseYpx
            ;     }
            ; }
        } else {
            ; StatusBarSetText2(SB, " ", 1)
        }

        MouseXWin := MouseX - WinX
        MouseYWin := MouseY - WinY

        if IsSet(SB) {
            SB.SetText("Cursor: " MouseXWin ", " MouseYWin,4)
            if (currControl.Hasprop("oName")){
                currControl.Getpos(&xCtrl, &yCtrl, &wCtrl, &hCtrl)
                SB.SetText(currControl.oName, 1)
                SB.SetText("Position: " xCtrl ", " yCtrl, 2)
                SB.SetText("Size: " wCtrl ", " hCtrl, 3)
            }
        }

        cursor := "Default"
        xHotspot := 0
        yHotspot := 0
        
        if (WorkGui.Selection.HasProp("X1") and WorkGui.Selection.X1 !=""){
            if (Abs(MouseXWin - WorkGui.Selection.X1) < 5 and Abs(MouseYWin - WorkGui.Selection.Y1) < 5) or (Abs(MouseXWin - WorkGui.Selection.X2) < 5 and Abs(MouseYWin - WorkGui.Selection.Y2) < 5) {
                cursor := "SIZENWSE"
            } else if (Abs(MouseXWin - WorkGui.Selection.X1) < 5 and Abs(MouseYWin - WorkGui.Selection.Y2) < 5) or (Abs(MouseXWin - WorkGui.Selection.X2) < 5 and Abs(MouseYWin - WorkGui.Selection.Y1) < 5) {
                cursor := "SIZENESW"
            } else if (Abs(MouseXWin - WorkGui.Selection.X1) < 5 and Abs(MouseYWin - (WorkGui.Selection.Y1 + WorkGui.Selection.Y2) / 2) < 5) or (Abs(MouseXWin - WorkGui.Selection.X2) < 5 and Abs(MouseYWin - (WorkGui.Selection.Y1 + WorkGui.Selection.Y2) / 2) < 5) {
                cursor := "SizeWE"
            } else if (Abs(MouseXWin - (WorkGui.Selection.X1 + WorkGui.Selection.X2) / 2) < 5 and Abs(MouseYWin - WorkGui.Selection.Y1) < 5) or (Abs(MouseXWin - (WorkGui.Selection.X1 + WorkGui.Selection.X2) / 2) < 5 and Abs(MouseYWin - WorkGui.Selection.Y2) < 5) {
                cursor := "SIZENS"
            } else if (MouseXWin > WorkGui.Selection.X1 and MouseXWin < WorkGui.Selection.X2 and MouseYWin > WorkGui.Selection.Y1 and MouseYWin < WorkGui.Selection.Y2) {
                cursor := "SizeAll"
            }
        }
        
        if (cursor_Old != cursor) {
            Cursor_Old := cursor
            ; ImageDestroy(A_Cursor)
            SetSystemCursor("Default")
            sleep 100
            if (cursor != "Default") {
                if (InStr(cursor, "Size")) {
                    SetSystemCursor(Cursor)
                } else {
                    ImagePutCursor(cursor, xHotspot, yHotspot)
                }
            }
        }
    }
}

UpdateSelectionBox() {
    global SelGui, WorkGui
    WinGetClientPos(&xWin, &yWin, &wWin, &hWin, WorkGui)
    WinMove(xWin, yWin, wWin, hWin, "ahk_id " SelGui.hwnd)
    if !IsSet(SelGui){
        return
    }

    ; Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
    hbm := CreateDIBSection(wWin, hWin)

    ; Get a device context compatible with the screen
    hdc := CreateCompatibleDC()

    ; Select the bitmap into the device context
    obm := SelectObject(hdc, hbm)

    ; Get a pointer to the graphics of the bitmap, for use with drawing functions
    GLayer := Gdip_GraphicsFromHDC(hdc)

    pPenSelect := Gdip_CreatePen("0xFF0078D7", 1)
    pPenBlack := Gdip_CreatePen("0xFF555555", 1)
    pPenWhite := Gdip_CreatePen("0xFFFFFFFF", 1)
    pBrushWhite := Gdip_BrushCreateSolid("0xFFFFFFFF")
    pBrushBlack := Gdip_BrushCreateSolid("0xFF000000")

    if (WorkGui.Selection.HasProp("aCtrl")) {
        for index, oCtrl in WorkGui.Selection.aCtrl {
            if (!oCtrl.Visible) {
                Continue
            }
            oCtrl.GetPos(&X1, &Y1, &W1, &H1)
            X2 := X1 + W1
            Y2 := Y1 + H1
            X1--
            Y1--
            Loop Round(X2 - X1) / 2 {
                Gdip_FillRectangle(GLayer, pBrushBlack, X1 + A_Index * 2 - 1, Y1, 1, 1)
                Gdip_FillRectangle(GLayer, pBrushBlack, X1 + A_Index * 2 - 1, Y2, 1, 1)
            }
            Loop Round(Y2 - Y1) / 2 {
                Gdip_FillRectangle(GLayer, pBrushBlack, X1, Y1 + A_Index * 2 - 1, 1, 1)
                Gdip_FillRectangle(GLayer, pBrushBlack, X2, Y1 + A_Index * 2 - 1, 1, 1)
            }
        }
    }

    if (WorkGui.Selection.HasProp("X1") and WorkGui.Selection.x1 !="") {
        X1 := Min(WorkGui.Selection.x1, WorkGui.Selection.x2)
        X2 := Max(WorkGui.Selection.x1, WorkGui.Selection.x2)
        Y1 := Min(WorkGui.Selection.y1, WorkGui.Selection.y2)
        Y2 := Max(WorkGui.Selection.y1, WorkGui.Selection.y2)
        ; Gdip_DrawRectangle(GLayer, pPenSelect, X1, Y1, X2 - X1, Y2 - Y1)
        Loop Round(X2 - X1) / 2 {
            Gdip_FillRectangle(GLayer, pBrushBlack, X1 +A_Index * 2 - 1, Y1, 1, 1)
            Gdip_FillRectangle(GLayer, pBrushBlack, X1 + A_Index * 2 - 1, Y2, 1, 1)
        }
        Loop Round(Y2 - Y1) / 2 {
            Gdip_FillRectangle(GLayer, pBrushBlack, X1 , Y1 + A_Index * 2 - 1, 1, 1)
            Gdip_FillRectangle(GLayer, pBrushBlack, X2 , Y1 + A_Index * 2 - 1, 1, 1)
        }

        Loop 3 {
            Xbox := X1 + (A_Index - 1) * (X2 - X1) / 2
            A_Index1 := A_Index
            Loop 3 {
                if (A_Index = 2 and A_Index1 = 2) {
                    Continue
                }
                Ybox := Y1 + (A_Index - 1) * (Y2 - Y1) / 2

                Gdip_FillRectangle(GLayer, pBrushWhite, Xbox - 2, Ybox - 2, 4, 4)
                Gdip_DrawRectangle(GLayer, pPenBlack, Xbox - 2, Ybox - 2, 4, 4)
            }
        }
    }
    

    Gdip_DeleteBrush(pBrushWhite)
    Gdip_DeletePen(pPenSelect)
    Gdip_DeletePen(pPenBlack)
    Gdip_DeletePen(pPenWhite)

    UpdateLayeredWindow(SelGui.hwnd, hdc, 0, 0, wWin, hWin)

    ; Select the object back into the hdc
    SelectObject(hdc, obm)

    ; Now the bitmap may be deleted
    DeleteObject(hbm)

    ; Also the device context related to the bitmap may be deleted
    DeleteDC(hdc)

    ; The graphics may now be deleted
    Gdip_DeleteGraphics(GLayer)
    WinRedraw(SelGui)
    return
}

; =============================================================================================
; Parameters
; =============================================================================================
; Color           = Start color (0 = black) - Format = 0xRRGGBB
; hwnd            = Parent window
; custColorObj    = Array() to load/save custom colors, must be &VarRef
; disp            = 1=full / 0=basic ... full displays custom colors panel, basic does not
; =============================================================================================
; All params are optional.  With no hwnd the dialog will show at top left of screen.  Use an
; object serializer (like JSON) to save/load custom colors to/from disk.
; =============================================================================================

ColorSelect(Color := 0, hwnd := 0, &custColorObj := "",disp:=false) {
    Static p := A_PtrSize
    disp := disp ? 0x3 : 0x1 ; init disp / 0x3 = full panel / 0x1 = basic panel
    
    If (custColorObj.Length > 16)
        throw Error("Too many custom colors.  The maximum allowed values is 16.")
    
    Loop (16 - custColorObj.Length)
        custColorObj.Push(0) ; fill out custColorObj to 16 values
    
    CUSTOM := Buffer(16 * 4, 0) ; init custom colors obj
    CHOOSECOLOR := Buffer((p=4)?36:72,0) ; init dialog
    
    If (IsObject(custColorObj)) {
        Loop 16 {
            custColor := RGB_BGR(custColorObj[A_Index])
            NumPut "UInt", custColor, CUSTOM, (A_Index-1) * 4
        }
    }
    
    NumPut "UInt", CHOOSECOLOR.size, CHOOSECOLOR, 0             ; lStructSize
    NumPut "UPtr", hwnd,             CHOOSECOLOR, p             ; hwndOwner
    NumPut "UInt", RGB_BGR(color),   CHOOSECOLOR, 3 * p         ; rgbResult
    NumPut "UPtr", CUSTOM.ptr,       CHOOSECOLOR, 4 * p         ; lpCustColors
    NumPut "UInt", disp,             CHOOSECOLOR, 5 * p         ; Flags
    
    if !DllCall("comdlg32\ChooseColor", "UPtr", CHOOSECOLOR.ptr, "UInt")
        return -1
    
    custColorObj := []
    Loop 16 {
        newCustCol := NumGet(CUSTOM, (A_Index-1) * 4, "UInt")
        custColorObj.InsertAt(A_Index, RGB_BGR(newCustCol))
    }
    
    Color := NumGet(CHOOSECOLOR, 3 * A_PtrSize, "UInt")
    return Format("0x{:06X}",RGB_BGR(color))
    
    RGB_BGR(c) {
        return ((c & 0xFF) << 16 | c & 0xFF00 | c >> 16)
    }
}

; ==================================================================
; Parameters
; ==================================================================
; fObj           = Initialize the dialog with specified values.
; hwnd           = Parent gui hwnd for modal, leave blank for not modal
; effects        = Allow selection of underline / strike out / italic
; ==================================================================
; fontObj output:
;
;    fontObj.str        = string to use with AutoHotkey to set GUI values - see examples
;    fontObj.size       = size of font
;    fontObj.name       = font name
;    fontObj.bold       = true/false
;    fontObj.italic     = true/false
;    fontObj.strike     = true/false
;    fontObj.underline  = true/false
;    fontObj.color      = 0xRRGGBB
; ==================================================================
FontSelect(fObj:="", hwnd:=0, Effects:=true) {
    Static _temp := {name:"", size:10, color:0, strike:0, underline:0, italic:0, bold:0}
    Static p := A_PtrSize, u := StrLen(Chr(0xFFFF)) ; u = IsUnicode
    
    fObj := (fObj="") ? _temp : fObj
    
    If (StrLen(fObj.name) > 31)
        throw Error("Font name length exceeds 31 characters.")
        
    LOGFONT := Buffer(!u ? 60 : 96,0) ; LOGFONT size based on IsUnicode, not A_PtrSize
    hDC := DllCall("GetDC","UPtr",0)
    LogPixels := DllCall("GetDeviceCaps","UPtr",hDC,"Int",90)
    Effects := 0x041 + (Effects ? 0x100 : 0)
    DllCall("ReleaseDC", "UPtr", 0, "UPtr", hDC) ; release DC
    
    fObj.bold := fObj.bold ? 700 : 400
    fObj.size := Floor(fObj.size*LogPixels/72)
    
    NumPut "uint", fObj.size, LOGFONT
    NumPut "uint", fObj.bold, "char", fObj.italic, "char", fObj.underline, "char", fObj.strike, LOGFONT, 16
    StrPut(fObj.name,LOGFONT.ptr+28)
    
    CHOOSEFONT := Buffer((p=8)?104:60,0)
    NumPut "UInt", CHOOSEFONT.size,     CHOOSEFONT
    NumPut "UPtr", hwnd,                CHOOSEFONT, p
    NumPut "UPtr", LOGFONT.ptr,         CHOOSEFONT, (p*3)
    NumPut "UInt", effects,             CHOOSEFONT, (p*4)+4
    NumPut "UInt", RGB_BGR(fObj.color), CHOOSEFONT, (p*4)+8
    
    r := DllCall("comdlg32\ChooseFont","UPtr",CHOOSEFONT.ptr) ; Font Select Dialog opens
    
    if !r
        return false
    
    fObj.Name := StrGet(LOGFONT.ptr+28)
    fObj.bold := ((b := NumGet(LOGFONT,16,"UInt")) <= 400) ? 0 : 1
    fObj.italic := !!NumGet(LOGFONT,20,"Char")
    fObj.underline := NumGet(LOGFONT,21,"Char")
    fObj.strike := NumGet(LOGFONT,22,"Char")
    fObj.size := NumGet(CHOOSEFONT,p*4,"UInt") / 10
    
    c := NumGet(CHOOSEFONT,(p=4)?6*p:5*p,"UInt") ; convert from BGR to RBG for output
    fObj.color := Format("0x{:06X}",RGB_BGR(c))
    
    str := ""
    str .= fObj.bold      ? "bold" : ""
    str .= fObj.italic    ? " italic" : ""
    str .= fObj.strike    ? " strike" : ""
    str .= fObj.color     ? " c" fObj.color : ""
    str .= fObj.size      ? " s" fObj.size : ""
    str .= fObj.underline ? " underline" : ""
    
    fObj.str := "norm " Trim(str)
    return fObj
    
    RGB_BGR(c) {
        return ((c & 0xFF) << 16 | c & 0xFF00 | c >> 16)
    }
}


TranslateClassName(ClassName) {
    AhkName := ""
    If (InStr(ClassName, "static")) {
        AhkName := "Text"
    } Else If (InStr(ClassName, "button")) {
        AhkName := "Button"
    } Else If (InStr(ClassName, "edit")) {
        AhkName := "Edit"
    } Else If (InStr(ClassName, "checkbox")) {
        AhkName := "CheckBox"
    } Else If (InStr(ClassName, "group")) {
        AhkName := "GroupBox"
    } Else If (InStr(ClassName, "radio")) {
        AhkName := "Radio"
    } Else If (InStr(ClassName, "combobox")) {
        AhkName := "ComboBox"
    } Else If (InStr(ClassName, "listview")) {
        AhkName := "ListView"
    } Else If (InStr(ClassName, "listbox")) {
        AhkName := "ListBox"
    } Else If (InStr(ClassName, "tree")) {
        AhkName := "TreeView"
    } Else If (InStr(ClassName, "status")) {
        AhkName := "StatusBar"
    } Else If (InStr(ClassName, "tab")) {
        AhkName := "Tab3"
    } Else If (InStr(ClassName, "updown")) {
        AhkName := "UpDown"
    } Else If (InStr(ClassName, "hotkey")) {
        AhkName := "Hotkey"
    } Else If (InStr(ClassName, "progress")) {
        AhkName := "Progress"
    } Else If (InStr(ClassName, "trackbar")) {
        AhkName := "Slider"
    } Else If (InStr(ClassName, "datetime")) {
        AhkName := "DateTime"
    } Else If (InStr(ClassName, "month")) {
        AhkName := "MonthCal"
    } Else If (InStr(ClassName, "link")) {
        AhkName := "Link"
    } Else If (InStr(ClassName, "richedit")) {
        AhkName := "Edit"
    } Else If (InStr(ClassName, "scintilla")) {
        AhkName := "Edit"
    } Else If (InStr(ClassName, "memo")) {
        AhkName := "Edit"
    } Else If (InStr(ClassName, "btn")) {
        AhkName := "Button"
    }
    Return AhkName
}

CloneMenuItems(hMenu, Prefix, &oMenu) {
    ItemCount := GetMenuItemCount(hMenu)
    ItemString := " "
    Loop ItemCount {
        ItemType := GetMenuString(&ItemString, hMenu, A_Index - 1)	; Types: MENUITEM, SUBMENU, SEPARATOR, ERROR
        ;OutputDebug %ItemType%: %ItemString%

        If (ItemType == "SUBMENU") {
            hSubMenu := GetSubMenu(hMenu, A_Index - 1)
            If (hSubMenu) {
                oSubMenu := Array()
                oSubMenu.name := ItemString
                OldItemString := ItemString
                ItemString := RegExReplace(ItemString, "[\W]")
                CloneMenuItems(hSubMenu, Prefix . ItemString . "Menu", &oSubMenu)
                MenuName := (Prefix = "") ? "MenuBar" : Prefix
                oSubMenu.oName := Prefix . ItemString . "Menu"
                oMenu.Push(oSubMenu)
                Continue
            }
        }
        If (Prefix != "") {
            If (ItemType == "SEPARATOR") {
                oMenu.Push("Separator")
            } Else {
                ItemString := StrReplace(ItemString, ",", "``,")
                oMenu.Push({name:ItemString})
            }
        }
    }
}

; Menu functions *******************************************************

GetMenu(hWnd) {
    Return DllCall("GetMenu", "Ptr", hWnd, "Ptr")
}

GetSubMenu(hMenu, nPos) {
    Return DllCall("GetSubMenu", "Ptr", hMenu, "UInt", nPos, "Ptr")
}

GetMenuItemID(hMenu, nPos) {
    Return DllCall("GetMenuItemID", "Ptr", hMenu, "UInt", nPos)
}

GetMenuItemCount(hMenu) {
    Return DllCall("GetMenuItemCount", "Ptr", hMenu)
}

GetMenuString(&OutputVar, hMenu, ItemPos) { ; Zero-based
    Local lpString
    OutputVar := ""

    ; lpString := Buffer(4096, 0) ; V1toV2: if 'lpString' is a UTF-16 string, use 
    VarSetStrCapacity(&lpString, 4096)
    If !(DllCall("GetMenuString", "Ptr", hMenu, "UInt", ItemPos, "Str", lpString, "UInt", 4096, "UInt", 0x400)) {
        Return (GetMenuItemID(hMenu, ItemPos) > -1) ? "SEPARATOR" : "ERROR"
    }

    OutputVar := lpString
    Return GetSubMenu(hMenu, ItemPos) ? "SUBMENU" : "MENUITEM"
}

CheckMenuRadioItem(hMenu, nPos, nFirst := 0, nLast := 0) {
    Return DllCall("CheckMenuRadioItem", "Ptr", hMenu, "UInt", nFirst, "UInt", nLast, "UInt", nPos, "UInt", 0x400)
}

DeleteMenu(hMenu, uPosition, uFlags := 0x400) { ; By position
    Return DllCall("DeleteMenu", "Ptr", hMenu, "UInt", uPosition, "UInt", uFlags)
}


ControlGetTabs(Control, WinTitle := "", WinText := "") {
    ; Original from Lexicos https://www.autohotkey.com/board/topic/70727-ahk-l-controlgettabs
    ; Converted to V2 by AHK_User, thanks to Helgef
    static TCM_GETITEMCOUNT := 0x1304
        , TCM_GETITEM := 0x133C
    , TCIF_TEXT := 1
    , MAX_TEXT_LENGTH := 260
    , MAX_TEXT_SIZE := MAX_TEXT_LENGTH * 2

    static PROCESS_VM_OPERATION := 0x8
        , PROCESS_VM_READ := 0x10
    , PROCESS_VM_WRITE := 0x20
    , READ_WRITE_ACCESS := PROCESS_VM_READ | PROCESS_VM_WRITE | PROCESS_VM_OPERATION
    , PROCESS_QUERY_INFORMATION := 0x400
    , MEM_COMMIT := 0x1000
    , MEM_RELEASE := 0x8000
    , PAGE_READWRITE := 4

    if !isInteger(Control) {
        Control := ControlGetHwnd(Control, WinTitle, WinText)
    }

    pid := WinGetPID("ahk_id " Control)

    ; Open the process for read/write and query info.
    hproc := DllCall("OpenProcess", "uint", READ_WRITE_ACCESS | PROCESS_QUERY_INFORMATION, "int", false, "uint", pid, "ptr")
    if !hproc
        return

    ; Should we use the 32-bit struct or the 64-bit struct?
    if A_Is64bitOS {
        try DllCall("IsWow64Process", "ptr", hproc, "int*", &is32bit := true)
    } else
        is32bit := true

    RPtrSize := is32bit ? 4 : 8
    TCITEM_SIZE := 16 + RPtrSize * 3

    ; Allocate a buffer in the (presumably) remote process.
    remote_item := DllCall("VirtualAllocEx", "ptr", hproc, "ptr", 0, "uptr", TCITEM_SIZE + MAX_TEXT_SIZE, "uint", MEM_COMMIT, "uint", PAGE_READWRITE, "ptr")
    remote_text := remote_item + TCITEM_SIZE

    ; Prepare the TCITEM structure locally.
    local_item := Buffer(TCITEM_SIZE, 0)	; V1toV2: if 'local_item' is a UTF-16 string, use 'VarSetStrCapacity(&local_item, TCITEM_SIZE)'
    NumPut("uint", TCIF_TEXT, local_item, 0)
    NumPut("UPtr", remote_text, local_item, 8 + RPtrSize)
    NumPut("int", MAX_TEXT_LENGTH, local_item, 8 + RPtrSize * 2)

    ; Prepare the local text buffer.
    ; VarSetStrCapacity(&local_text, MAX_TEXT_SIZE) ; V1toV2: if 'local_text' is NOT a UTF-16 string, use 'local_text := Buffer(MAX_TEXT_SIZE)'
    local_text := Buffer(MAX_TEXT_SIZE)

    ; Write the local structure into the remote buffer.
    DllCall("WriteProcessMemory", "ptr", hproc, "ptr", remote_item, "ptr", local_item, "uptr", TCITEM_SIZE, "ptr", 0)

    tabs := []

    itemCount := SendMessage(TCM_GETITEMCOUNT, , , , "ahk_id " Control)

    Loop itemCount
    {
        ; Retrieve the item text.
        try {
            SendMessage(TCM_GETITEM, A_Index - 1, remote_item, , "ahk_id " Control)
            DllCall("ReadProcessMemory", "ptr", hproc, "ptr", remote_text, "ptr", local_text, "uptr", MAX_TEXT_SIZE, "ptr", 0)
            tabs.Push(StrGet(local_text))
        } catch {
            tabs.Push("")
        }
    }

    ; Release the remote memory and handle.
    DllCall("VirtualFreeEx", "ptr", hproc, "ptr", remote_item, "uptr", 0, "uint", MEM_RELEASE)
    DllCall("CloseHandle", "ptr", hproc)

    return tabs
}

; Returns an array of objects containing the text and width of each item of a remote SysHeader32 control
ControlGetLVHeaderInfo(hwndLV) {
    ; Converted v1 function GetHeaderInfo of Alguimist https://www.autohotkey.com/boards/viewtopic.php?t=10157
    ; Converted by AHK_User
    Static MAX_TEXT_LENGTH := 260
            , MAX_TEXT_SIZE := MAX_TEXT_LENGTH * (1 ? 2 : 1)

    ; Accepts both the hwnd of listview as the hwnd of the header
    hwndHeader := SendMessage(0x101F, 0, 0,, "ahk_id " hwndLV) ; LVM_GETHEADER
    hwndHeader := (hwndHeader=0) ? hwndLV : hwndHeader
    
    PID := WinGetPID("ahk_id " hwndHeader)

    ; Open the process for read/write and query info.
    ; PROCESS_VM_READ | PROCESS_VM_WRITE | PROCESS_VM_OPERATION | PROCESS_QUERY_INFORMATION
    If !(hProc := DllCall("OpenProcess", "UInt", 0x438, "Int", False, "UInt", PID, "Ptr")) {
        Return
    }

    ; Should we use the 32-bit struct or the 64-bit struct?
    If (A_Is64bitOS) {
        Try DllCall("IsWow64Process", "Ptr", hProc, "int*", &Is32bit := true)
    } Else {
        Is32bit := True
    }

    RPtrSize := Is32bit ? 4 : 8
    cbHDITEM := (4 * 6) + (RPtrSize * 6)

    ; Allocate a buffer in the (presumably) remote process.
    remote_item := DllCall("VirtualAllocEx", "Ptr", hProc, "Ptr", 0, "uPtr", cbHDITEM + MAX_TEXT_SIZE, "UInt", 0x1000, "UInt", 4, "Ptr")
    remote_text := remote_item + cbHDITEM

    ; Prepare the HDITEM structure locally.
    HDITEM := Buffer(cbHDITEM, 0)
    NumPut("UInt", 0x3, HDITEM, 0) ; mask (HDI_WIDTH | HDI_TEXT)
    NumPut("Ptr", remote_text, HDITEM, 8) ; pszText
    NumPut("Int", MAX_TEXT_LENGTH, HDITEM, 8 + RPtrSize * 2) ; cchTextMax

    ; Write the local structure into the remote buffer.
    DllCall("WriteProcessMemory", "Ptr", hProc, "Ptr", remote_item, "Ptr", HDITEM, "uPtr", cbHDITEM, "Ptr", 0)

    HDInfo := []
    HDText := Buffer(MAX_TEXT_SIZE)
    
    itemCount := SendMessage(0x1200, 0, 0,, "ahk_id " hwndHeader) ; HDM_GETITEMCOUNT
    Loop itemCount {
        ; Retrieve the item text.
        try{
            SendMessage(0x120B, A_Index - 1, remote_item,, "ahk_id " hwndHeader) ; HDM_GETITEMW
            DllCall("ReadProcessMemory", "Ptr", hProc, "Ptr", remote_item, "Ptr", HDITEM, "uPtr", cbHDITEM, "Ptr", 0)
            DllCall("ReadProcessMemory", "Ptr", hProc, "Ptr", remote_text, "Ptr", HDText, "uPtr", MAX_TEXT_SIZE, "Ptr", 0)
            HDInfo.Push({w: NumGet(HDITEM, 4, "UInt"), Text: StrGet(HDText)})
        } Catch{
            HDInfo.Push({w: 0, Text: ""})
        }        
    }

    ; Release the remote memory and handle.
    DllCall("VirtualFreeEx", "Ptr", hProc, "Ptr", remote_item, "UPtr", 0, "UInt", 0x8000) ; MEM_RELEASE
    DllCall("CloseHandle", "Ptr", hProc)

    Return HDInfo
}
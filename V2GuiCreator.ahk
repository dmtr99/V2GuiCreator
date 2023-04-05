#Requires AutoHotKey v2.0-beta.3
#SingleInstance Force

; #Include SetSystemCursor.ahk
#Include Lib\ToolBar.ah2
#Include Lib\ObjectGui.ah2
#Include Lib\Gdip_All.ahk
#Include Lib\SetSystemCursor.ahk
#Include Lib\RestoreCursors.ahk
#Include Lib\ImagePut.ahk

; #Include <Scintilla>
; (Scintilla) ; Init class, or simply #INCLUDE the extension-lib at the top.


If !pToken := Gdip_Startup()
{
    MsgBox "Gdiplus failed to start. Please ensure you have gdiplus on your system"
    ExitApp
}
OnExit((ExitReason, ExitCode) => Gdip_Shutdown(pToken))
CoordMode("Mouse")
OnMessage(0x0200, WM_MOUSEMOVE)
DetectHiddenWindows true

SendMode "Input"	; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir	; Ensures a consistent starting directory.
global IconLib := "Auto-GUI.icl"
tray := A_TrayMenu

tray.Add()
tray.Add("Open program folder", (ItemName, ItemPos, MyMenu) => Run(A_ScriptDir))

Global oG := {}
oG.Window := {}
oG.ControlList := Map()

; Styles data
{
    Class Styles {
        __New(Style, Hex, Description, OptionText:="",SkipHex := "", Skip := "") {
            this.Style := Style
            this.Hex := Hex
            this.OptionText := OptionText
            this.Description := Description
            this.SkipHex := SkipHex ; used to skip this option if SkipHex applies in the option definition
            this.Skip := Skip ; used to skip this option always in the option definition
        }
    }
    Global aoWinStyles := Array()
    aoWinStyles.Push(Styles("WS_BORDER", "0x800000","+/-Border. Creates a window that has a thin-line border.", "Border","0xC00000"))
    aoWinStyles.Push(Styles("WS_POPUP", "0x80000000","Creates a pop-up window. This style cannot be used with the WS_CHILD style."))
    aoWinStyles.Push(Styles("WS_CAPTION", "0xC00000","+/-Caption. Creates a window that has a title bar. This style is a numerical combination of WS_BORDER and WS_DLGFRAME.", "Caption","-Border -0x400000 +E0x10000 -E0x100"))
    aoWinStyles.Push(Styles("WS_CLIPSIBLINGS", "0x4000000","Clips child windows relative to each other; that is, when a particular child window receives a WM_PAINT message, the WS_CLIPSIBLINGS style clips all other overlapping child windows out of the region of the child window to be updated. If WS_CLIPSIBLINGS is not specified and child windows overlap, it is possible, when drawing within the client area of a child window, to draw within the client area of a neighboring child window."))
    aoWinStyles.Push(Styles("WS_DISABLED", "0x8000000","+/-Disabled. Creates a window that is initially disabled.","Disabled"))
    aoWinStyles.Push(Styles("WS_DLGFRAME", "0x400000","Creates a window that has a border of a style typically used with dialog boxes."))
    aoWinStyles.Push(Styles("WS_HSCROLL", "0x100000", "Creates a window that has a horizontal scroll bar."))
    aoWinStyles.Push(Styles("WS_MAXIMIZE", "0x1000000", "Creates a window that is initially maximized."))
    aoWinStyles.Push(Styles("WS_MAXIMIZEBOX", "0x10000", "+/-MaximizeBox. Creates a window that has a maximize button. Cannot be combined with the WS_EX_CONTEXTHELP style. The WS_SYSMENU style must also be specified.","MaximizeBox"))
    aoWinStyles.Push(Styles("WS_MINIMIZE", "0x20000000", "Creates a window that is initially minimized."))
    aoWinStyles.Push(Styles("WS_MINIMIZEBOX", "0x20000", "+/-MinimizeBox. Creates a window that has a minimize button. Cannot be combined with the WS_EX_CONTEXTHELP style. The WS_SYSMENU style must also be specified.","MinimizeBox"))
    aoWinStyles.Push(Styles("WS_OVERLAPPED", "0x0", "Creates an overlapped window. An overlapped window has a title bar and a border. Same as the WS_TILED style."))
    aoWinStyles.Push(Styles("WS_OVERLAPPEDWINDOW", "0xCF0000", "Creates an overlapped window with the WS_OVERLAPPED, WS_CAPTION, WS_SYSMENU, WS_THICKFRAME, WS_MINIMIZEBOX, and WS_MAXIMIZEBOX styles. Same as the WS_TILEDWINDOW style.",,, true))
    aoWinStyles.Push(Styles("WS_POPUPWINDOW", "0x80880000", "Creates a pop-up window with WS_BORDER, WS_POPUP, and WS_SYSMENU styles. The WS_CAPTION and WS_POPUPWINDOW styles must be combined to make the window menu visible.",,,true))
    aoWinStyles.Push(Styles("WS_SIZEBOX", "0x40000", "+/-Resize. Creates a window that has a sizing border. Same as the WS_THICKFRAME style.","Resize","+MaximizeBox +E0x10000"))
    aoWinStyles.Push(Styles("WS_SYSMENU", "0x80000", "+/-SysMenu. Creates a window that has a window menu on its title bar. The WS_CAPTION style must also be specified.","SysMenu"," +E0x10000"))
    aoWinStyles.Push(Styles("WS_VSCROLL", "0x200000", "Creates a window that has a vertical scroll bar."))
    aoWinStyles.Push(Styles("WS_VISIBLE", "0x10000000", "Creates a window that is initially visible."))
    aoWinStyles.Push(Styles("WS_CHILD", "0x40000000", "Creates a child window. A window with this style cannot have a menu bar. This style cannot be used with the WS_POPUP style."))

    Global aoControlStyles := Array()
    ; stylest that seem double, for controls
    aoControlStyles.Push(Styles("WS_BORDER", "0x800000","+/-Border. Creates a window that has a thin-line border.", "Border","0xC00000"))
    aoControlStyles.Push(Styles("WS_DISABLED", "0x8000000", "+/-Disabled. Creates a window that is initially disabled.", "Disabled"))
    aoControlStyles.Push(Styles("WS_TABSTOP", "0x10000", "+/-Tabstop. Specifies a control that can receive the keyboard focus when the user presses Tab. Pressing Tab changes the keyboard focus to the next control with the WS_TABSTOP style.","Tabstop"))
    aoControlStyles.Push(Styles("WS_GROUP", "0x20000", '+/-Group. Indicates that this control is the first one in a group of controls. This style is automatically applied to manage the " only one at a time " behavior of radio buttons. In the rare case where two groups of radio buttons are added consecutively (with no other control types in between them), this style may be applied manually to the first control of the second radio group, which splits it off from the first.', "Group"))
    aoControlStyles.Push(Styles("WS_THICKFRAME", "0x40000", "Creates a window that has a sizing border. Same as the WS_SIZEBOX style.",,"0x40000",true))
    aoControlStyles.Push(Styles("WS_VSCROLL", "0x200000", "Creates a window that has a vertical scroll bar.","VScroll"))
    aoControlStyles.Push(Styles("WS_HSCROLL", "0x100000", "Creates a window that has a horizontal scroll bar.","HScroll"))

    Global aoWinExStyles := Array()
    aoWinExStyles.Push(Styles("WS_EX_ACCEPTFILES", "0x10", 'The window accepts drag-drop files.'))
    aoWinExStyles.Push(Styles("WS_EX_APPWINDOW", "0x40000", 'Forces a top-level window onto the taskbar when the window is visible.'))
    aoWinExStyles.Push(Styles("WS_EX_CLIENTEDGE", "0x200", 'The window has a border with a sunken edge.'))
    aoWinExStyles.Push(Styles("WS_EX_COMPOSITED", "0x2000000", 'Paints all descendants of a window in bottom-to-top painting order using double-buffering. Bottom-to-top painting order allows a descendent window to have translucency (alpha) and transparency (color-key) effects, but only if the descendent window also has the WS_EX_TRANSPARENT bit set. Double-buffering allows the window and its descendents to be painted without flicker. This cannot be used if the window has a class style of either CS_OWNDC or CS_CLASSDC. Windows 2000: This style is not supported.'))
    aoWinExStyles.Push(Styles("WS_EX_CONTEXTHELP", "0x400", 'The title bar of the window includes a question mark. When the user clicks the question mark, the cursor changes to a question mark with a pointer. If the user then clicks a child window, the child receives a WM_HELP message. The child window should pass the message to the parent window procedure, which should call the WinHelp function using the HELP_WM_HELP command. The Help application displays a pop-up window that typically contains help for the child window. WS_EX_CONTEXTHELP cannot be used with the WS_MAXIMIZEBOX or WS_MINIMIZEBOX styles.'))
    aoWinExStyles.Push(Styles("WS_EX_CONTROLPARENT", "0x10000", 'The window itself contains child windows that should take part in dialog box navigation. If this style is specified, the dialog manager recurses into children of this window when performing navigation operations such as handling the TAB key, an arrow key, or a keyboard mnemonic.'))
    aoWinExStyles.Push(Styles("WS_EX_DLGMODALFRAME", "0x1", 'The window has a double border; the window can, optionally, be created with a title bar by specifying the WS_CAPTION style in the dwStyle parameter.'))
    aoWinExStyles.Push(Styles("WS_EX_LAYERED", "0x80000", 'The window is a layered window. This style cannot be used if the window has a class style of either CS_OWNDC or CS_CLASSDC. Windows 8: The WS_EX_LAYERED style is supported for top-level windows and child windows. Previous Windows versions support WS_EX_LAYERED only for top-level windows.'))
    aoWinExStyles.Push(Styles("WS_EX_LAYOUTRTL", "0x400000", 'If the shell language is Hebrew, Arabic, or another language that supports reading order alignment, the horizontal origin of the window is on the right edge. Increasing horizontal values advance to the left.'))
    aoWinExStyles.Push(Styles("WS_EX_LEFT", "0x0", 'The window has generic left-aligned properties. This is the default.'))
    aoWinExStyles.Push(Styles("WS_EX_LEFTSCROLLBAR", "0x4000", 'If the shell language is Hebrew, Arabic, or another language that supports reading order alignment, the vertical scroll bar (if present) is to the left of the client area. For other languages, the style is ignored.'))
    aoWinExStyles.Push(Styles("WS_EX_LTRREADING", "0x0", 'The window text is displayed using left-to-right reading-order properties. This is the default.'))
    aoWinExStyles.Push(Styles("WS_EX_MDICHILD", "0x40", 'The window is a MDI child window.'))
    aoWinExStyles.Push(Styles("WS_EX_NOACTIVATE", "0x8000000", 'A top-level window created with this style does not become the foreground window when the user clicks it. The system does not bring this window to the foreground when the user minimizes or closes the foreground window. The window should not be activated The window does not appear on the taskbar by default. To force the window to appear on the taskbar, use the WS_EX_APPWINDOW style. To activate the window, use the SetActiveWindow or SetForegroundWindow function. through programmatic access or via keyboard navigation by accessible technology, such as Narrator.'))
    aoWinExStyles.Push(Styles("WS_EX_NOINHERITLAYOUT", "0x100000", 'The window does not pass its window layout to its child windows.'))
    aoWinExStyles.Push(Styles("WS_EX_NOPARENTNOTIFY", "0x4", 'The child window created with this style does not send the WM_PARENTNOTIFY message to its parent window when it is created or destroyed.'))
    aoWinExStyles.Push(Styles("WS_EX_NOREDIRECTIONBITMAP", "0x200000", 'The window does not render to a redirection surface. This is for windows that do not have visible content or that use mechanisms other than surfaces to provide their visual.'))
    aoWinExStyles.Push(Styles("WS_EX_RIGHT", "0x1000", 'The window has generic "right-aligned" properties. This depends on the window class. This style has an effect only if the shell language is Hebrew, Arabic, or another language that supports reading-order alignment; otherwise, the style is ignored. Using the WS_EX_RIGHT style for static or edit controls has the same effect as using the SS_RIGHT or ES_RIGHT style, respectively. Using this style with button controls has the same effect as using BS_RIGHT and BS_RIGHTBUTTON styles.'))
    aoWinExStyles.Push(Styles("WS_EX_RIGHTSCROLLBAR", "0x0", 'The vertical scroll bar (if present) is to the right of the client area. This is the default.'))
    aoWinExStyles.Push(Styles("WS_EX_RTLREADING", "0x2000", 'If the shell language is Hebrew, Arabic, or another language that supports reading-order alignment, the window text is displayed using right-to-left reading-order properties. For other languages, the style is ignored.'))
    aoWinExStyles.Push(Styles("WS_EX_STATICEDGE", "0x20000", 'The window has a three-dimensional border style intended to be used for items that do not accept user input.'))
    aoWinExStyles.Push(Styles("WS_EX_TOOLWINDOW", "0x80", 'The window is intended to be used as a floating toolbar. A tool window has a title bar that is shorter than a normal title bar, and the window title is drawn using a smaller font. A tool window does not appear in the taskbar or in the dialog that appears when the user presses ALT+TAB. If a tool window has a system menu, its icon is not displayed on the title bar. However, you can display the system menu by right-clicking or by typing ALT+SPACE.',"ToolWindow","+E0x10000"))
    aoWinExStyles.Push(Styles("WS_EX_TOPMOST", "0x8", 'The window should be placed above all non-topmost windows and should stay above them, even when the window is deactivated. To add or remove this style, use the SetWindowPos function.',"AlwaysOnTop"))
    aoWinExStyles.Push(Styles("WS_EX_TRANSPARENT", "0x20", 'The window should not be painted until siblings beneath the window (that were created by the same thread) have been painted. The window appears transparent because the bits of underlying sibling windows have already been painted. To achieve transparency without these restrictions, use the SetWindowRgn function.'))
    aoWinExStyles.Push(Styles("WS_EX_WINDOWEDGE", "0x100", 'The window has a border with a raised edge.'))

    global aoTextStyles := Array()
    aoTextStyles.Push(Styles("SS_BLACKFRAME", "0x7",'Specifies a box with a frame drawn in the same color as the window frames. This color is black in the default color scheme.'))
    aoTextStyles.Push(Styles("SS_BLACKRECT", "0x4",'Specifies a rectangle filled with the current window frame color. This color is black in the default color scheme.'))
    aoTextStyles.Push(Styles("SS_CENTER", "0x1",'+/-Center. Specifies a simple rectangle and centers the text in the rectangle. The control automatically wraps words that extend past the end of a line to the beginning of the next centered line.', 'Center'))
    aoTextStyles.Push(Styles("SS_ETCHEDFRAME", "0x12",'Draws the frame of the static control using the EDGE_ETCHED edge style.'))
    aoTextStyles.Push(Styles("SS_ETCHEDHORZ", "0x10",'Draws the top and bottom edges of the static control using the EDGE_ETCHED edge style.'))
    aoTextStyles.Push(Styles("SS_ETCHEDVERT", "0x11",'Draws the left and right edges of the static control using the EDGE_ETCHED edge style.'))
    aoTextStyles.Push(Styles("SS_GRAYFRAME", "0x8",'Specifies a box with a frame drawn with the same color as the screen background (desktop). This color is gray in the default color scheme.'))
    aoTextStyles.Push(Styles("SS_GRAYRECT", "0x5",'Specifies a rectangle filled with the current screen background color. This color is gray in the default color scheme.'))
    aoTextStyles.Push(Styles("SS_LEFT", "0x0",'+/-Left. This is the default. It specifies a simple rectangle and left-aligns the text in the rectangle. The text is formatted before it is displayed. Words that extend past the end of a line are automatically wrapped to the beginning of the next left-aligned line. Words that are longer than the width of the control are truncated.', 'Left'))
    aoTextStyles.Push(Styles("SS_LEFTNOWORDWRAP", "0xC",'+/-Wrap. Specifies a rectangle and left-aligns the text in the rectangle. Tabs are expanded, but words are not wrapped. Text that extends past the end of a line is clipped.', 'Wrap'))
    aoTextStyles.Push(Styles("SS_NOPREFIX", "0x80","Prevents interpretation of any ampersand (&) characters in the control's text as accelerator prefix characters. This can be useful when file names or other strings that might contain an ampersand (&) must be displayed within a text control."))
    aoTextStyles.Push(Styles("SS_NOTIFY", "0x100",'Sends the parent window the STN_CLICKED notification when the user clicks the control.'))
    aoTextStyles.Push(Styles("SS_RIGHT", "0x2",'+/-Right. Specifies a rectangle and right-aligns the specified text in the rectangle.', 'Right'))
    aoTextStyles.Push(Styles("SS_SUNKEN", "0x1000",'Draws a half-sunken border around a static control.'))
    aoTextStyles.Push(Styles("SS_WHITEFRAME", "0x9",'Specifies a box with a frame drawn with the same color as the window background. This color is white in the default color scheme.'))
    aoTextStyles.Push(Styles("SS_WHITERECT", "0x6",'Specifies a rectangle filled with the current window background color. This color is white in the default color scheme.'))

    global aoEditStyles := Array()
    aoEditStyles.Push(Styles("ES_AUTOHSCROLL", "0x80",'+/-Wrap for multi-line edits, and +/-Limit for single-line edits. Automatically scrolls text to the right by 10 characters when the user types a character at the end of the line. When the user presses Enter, the control scrolls all text back to the zero position.','Limit'))
    aoEditStyles.Push(Styles("ES_AUTOVSCROLL", "0x40",'Scrolls text up one page when the user presses Enter on the last line.'))
    aoEditStyles.Push(Styles("ES_CENTER", "0x1",'+/-Center. Centers text in a multiline edit control.', 'Center'))
    aoEditStyles.Push(Styles("ES_LOWERCASE", "0x10",'+/-Lowercase. Converts all characters to lowercase as they are typed into the edit control.', 'Lowercase'))
    aoEditStyles.Push(Styles("ES_NOHIDESEL", "0x100",'Negates the default behavior for an edit control. The default behavior hides the selection when the control loses the input focus and inverts the selection when the control receives the input focus. If you specify ES_NOHIDESEL, the selected text is inverted, even if the control does not have the focus.'))
    aoEditStyles.Push(Styles("ES_NUMBER", "0x2000",'+/-Number. Prevents the user from typing anything other than digits in the control.', 'Number'))
    aoEditStyles.Push(Styles("ES_OEMCONVERT", "0x400",'This style is most useful for edit controls that contain file names.'))
    aoEditStyles.Push(Styles("ES_MULTILINE", "0x4",'+/-Multi. Designates a multiline edit control. The default is a single-line edit control.','Multi'))
    aoEditStyles.Push(Styles("ES_PASSWORD", "0x20",'+/-Password. Displays a masking character in place of each character that is typed into the edit control, which conceals the text.', 'Password'))
    aoEditStyles.Push(Styles("ES_READONLY", "0x800",'+/-ReadOnly. Prevents the user from typing or editing text in the edit control.', 'ReadOnly'))
    aoEditStyles.Push(Styles("ES_RIGHT", "0x2",'+/-Right. Right-aligns text in a multiline edit control.', 'Right'))
    aoEditStyles.Push(Styles("ES_UPPERCASE", "0x8",'+/-Uppercase. Converts all characters to uppercase as they are typed into the edit control.', 'Uppercase'))
    aoEditStyles.Push(Styles("ES_WANTRETURN", "0x1000","+/-WantReturn. Specifies that a carriage return be inserted when the user presses Enter while typing text into a multiline edit control in a dialog box. If you do not specify this style, pressing Enter has the same effect as pressing the dialog box's default push button. This style has no effect on a single-line edit control.", 'WantReturn'))

    global aoEditMultiLineStyles := Array()
    aoEditMultiLineStyles.Push(Styles("ES_AUTOHSCROLL", "0x80",'+/-Wrap for multi-line edits, and +/-Limit for single-line edits. Automatically scrolls text to the right by 10 characters when the user types a character at the end of the line. When the user presses Enter, the control scrolls all text back to the zero position.','Wrap'))
    aoEditMultiLineStyles.Push(Styles("ES_AUTOVSCROLL", "0x40",'Scrolls text up one page when the user presses Enter on the last line.'))
    aoEditMultiLineStyles.Push(Styles("ES_CENTER", "0x1",'+/-Center. Centers text in a multiline edit control.', 'Center'))
    aoEditMultiLineStyles.Push(Styles("ES_LOWERCASE", "0x10",'+/-Lowercase. Converts all characters to lowercase as they are typed into the edit control.', 'Lowercase'))
    aoEditMultiLineStyles.Push(Styles("ES_NOHIDESEL", "0x100",'Negates the default behavior for an edit control. The default behavior hides the selection when the control loses the input focus and inverts the selection when the control receives the input focus. If you specify ES_NOHIDESEL, the selected text is inverted, even if the control does not have the focus.'))
    aoEditMultiLineStyles.Push(Styles("ES_NUMBER", "0x2000",'+/-Number. Prevents the user from typing anything other than digits in the control.', 'Number'))
    aoEditMultiLineStyles.Push(Styles("ES_OEMCONVERT", "0x400",'This style is most useful for edit controls that contain file names.'))
    aoEditMultiLineStyles.Push(Styles("ES_MULTILINE", "0x4",'+/-Multi. Designates a multiline edit control. The default is a single-line edit control.','Multi'))
    aoEditMultiLineStyles.Push(Styles("ES_PASSWORD", "0x20",'+/-Password. Displays a masking character in place of each character that is typed into the edit control, which conceals the text.', 'Password'))
    aoEditMultiLineStyles.Push(Styles("ES_READONLY", "0x800",'+/-ReadOnly. Prevents the user from typing or editing text in the edit control.', 'ReadOnly'))
    aoEditMultiLineStyles.Push(Styles("ES_RIGHT", "0x2",'+/-Right. Right-aligns text in a multiline edit control.', 'Right'))
    aoEditMultiLineStyles.Push(Styles("ES_UPPERCASE", "0x8",'+/-Uppercase. Converts all characters to uppercase as they are typed into the edit control.', 'Uppercase'))
    aoEditMultiLineStyles.Push(Styles("ES_WANTRETURN", "0x1000","+/-WantReturn. Specifies that a carriage return be inserted when the user presses Enter while typing text into a multiline edit control in a dialog box. If you do not specify this style, pressing Enter has the same effect as pressing the dialog box's default push button. This style has no effect on a single-line edit control.", 'WantReturn'))

    global aoUpDownStyles := Array()
    aoUpDownStyles.Push(Styles("UDS_WRAP", "0x1",'Named option "Wrap". Causes the control to wrap around to the other end of its range when the user attempts to go beyond the minimum or maximum. Without Wrap, the control stops when the minimum or maximum is reached.',"Wrap"))
    aoUpDownStyles.Push(Styles("UDS_SETBUDDYINT", "0x2",'Causes the UpDown control to set the text of the buddy control (using the WM_SETTEXT message) when the position changes. However, if the buddy is a ListBox, the ListBox`'s current selection is changed instead.',""))
    aoUpDownStyles.Push(Styles("UDS_ALIGNRIGHT", "0x4",'Named option "Right" (default). Positions UpDown on the right side of its buddy control.',"Right"))
    aoUpDownStyles.Push(Styles("UDS_ALIGNLEFT", "0x8",'Named option "Left". Positions UpDown on the left side of its buddy control.',"Left"))
    aoUpDownStyles.Push(Styles("UDS_AUTOBUDDY", "0x10",'Automatically selects the previous control in the z-order as the UpDown control`'s buddy control.',""))
    aoUpDownStyles.Push(Styles("UDS_ARROWKEYS", "0x20",'Allows the user to press ↑ or ↓ on the keyboard to increase or decrease the UpDown control`'s position.',""))
    aoUpDownStyles.Push(Styles("UDS_HORZ", "0x40",'Named option "Horz". Causes the control`'s arrows to point left and right instead of up and down.',"Horz"))
    aoUpDownStyles.Push(Styles("UDS_NOTHOUSANDS", "0x80",'Does not insert a thousands separator between every three decimal digits in the buddy control.',""))
    aoUpDownStyles.Push(Styles("UDS_HOTTRACK", "0x100",'Causes the control to exhibit "hot tracking" behavior. That is, it highlights the control`'s buttons as the mouse passes over them. This flag may be ignored if the desktop theme overrides it.',""))

    global aoPicStyles := Array()
    aoPicStyles.Push(Styles("SS_REALSIZECONTROL", "0x40",'Adjusts the bitmap to fit the size of the control.',""))
    aoPicStyles.Push(Styles("SS_CENTERIMAGE", "0x200",'Centers the bitmap in the control. If the bitmap is too large, it will be clipped. For text controls, if the control contains a single line of text, the text is centered vertically within the available height of the control.',""))


    global aoButtonStyles := Array()
    aoButtonStyles.Push(Styles("BS_AUTO3STATE", "0x6",'Creates a button that is the same as a three-state check box, except that the box changes its state when the user selects it. The state cycles through checked, indeterminate, and cleared.'))
    aoButtonStyles.Push(Styles("BS_AUTOCHECKBOX", "0x3",'Creates a button that is the same as a check box, except that the check state automatically toggles between checked and cleared each time the user selects the check box.'))
    aoButtonStyles.Push(Styles("BS_AUTORADIOBUTTON", "0x9","Creates a button that is the same as a radio button, except that when the user selects it, the system automatically sets the button's check state to checked and automatically sets the check state for all other buttons in the same group to cleared."))
    aoButtonStyles.Push(Styles("BS_LEFT", "0x100",'+/-Left. Left-aligns the text.', 'Left'))
    aoButtonStyles.Push(Styles("BS_PUSHBUTTON", "0x0",'Creates a push button that posts a WM_COMMAND message to the owner window when the user selects the button.'))
    aoButtonStyles.Push(Styles("BS_PUSHLIKE", "0x1000","Makes a checkbox or radio button look and act like a push button. The button looks raised when it isn't pushed or checked, and sunken when it is pushed or checked."))
    aoButtonStyles.Push(Styles("BS_RIGHT", "0x200",'+/-Right. Right-aligns the text.', 'Right'))
    aoButtonStyles.Push(Styles("BS_RIGHTBUTTON", "0x20","+Right (i.e. +Right includes both BS_RIGHT and BS_RIGHTBUTTON, but -Right removes only BS_RIGHT, not BS_RIGHTBUTTON). Positions a checkbox square or radio button circle on the right side of the control's available width instead of the left."))
    aoButtonStyles.Push(Styles("BS_BOTTOM", "0x800","Places the text at the bottom of the control's available height."))
    aoButtonStyles.Push(Styles("BS_CENTER", "0x300",'+/-Center. Centers the text horizontally within the control`'s available width.', 'Center'))
    aoButtonStyles.Push(Styles("BS_DEFPUSHBUTTON", "0x1",'+/-Default. Creates a push button with a heavy black border. If the button is in a dialog box, the user can select the button by pressing Enter, even when the button does not have the input focus. This style is useful for enabling the user to quickly select the most likely option.', 'Default'))
    aoButtonStyles.Push(Styles("BS_MULTILINE", "0x2000",'+/-Wrap. Wraps the text to multiple lines if the text is too long to fit on a single line in the control`'s available width. This also allows linefeed (``n) to start new lines of text.', 'Wrap'))
    aoButtonStyles.Push(Styles("BS_NOTIFY", "0x4000",'Enables a button to send BN_KILLFOCUS and BN_SETFOCUS notification codes to its parent window. Note that buttons send the BN_CLICKED notification code regardless of whether it has this style. To get BN_DBLCLK notification codes, the button must have the BS_RADIOBUTTON or BS_OWNERDRAW style.'))
    aoButtonStyles.Push(Styles("BS_TOP", "0x400",'Places text at the top of the control`'s available height.'))
    aoButtonStyles.Push(Styles("BS_VCENTER", "0xC00",'Vertically centers text in the control`'s available height.'))
    aoButtonStyles.Push(Styles("BS_FLAT", "0x8000",'Specifies that the button is two-dimensional; it does not use the default shading to create a 3-D effect.'))
    aoButtonStyles.Push(Styles("BS_GROUPBOX", "0x7",'Creates a rectangle in which other controls can be grouped. Any text associated with this style is displayed in the rectangle`'s upper left corner.'))

    global aoCBBStyles := Array()
    aoCBBStyles.Push(Styles("CBS_AUTOHSCROLL", "0x40", '+/-Limit. Automatically scrolls the text in an edit control to the right when the user types a character at the end of the line. If this style is not set, only text that fits within the rectangular boundary is enabled.', "Limit"))
    aoCBBStyles.Push(Styles("CBS_DISABLENOSCROLL", "0x800", 'Shows a disabled vertical scroll bar in the drop-down list when it does not contain enough items to scroll. Without this style, the scroll bar is hidden when the drop-down list does not contain enough items.', ""))
    aoCBBStyles.Push(Styles("CBS_DROPDOWN", "0x2", 'Similar to CBS_SIMPLE, except that the list box is not displayed unless the user selects an icon next to the edit control.', ""))
    aoCBBStyles.Push(Styles("CBS_DROPDOWNLIST", "0x3", 'Similar to CBS_DROPDOWN, except that the edit control is replaced by a static text item that displays the current selection in the list box.', ""))
    aoCBBStyles.Push(Styles("CBS_LOWERCASE", "0x4000", '+/-Lowercase. Converts to lowercase any uppercase characters that are typed into the edit control of a combo box.', "Lowercase"))
    aoCBBStyles.Push(Styles("CBS_NOINTEGRALHEIGHT", "0x400", 'Specifies that the combo box will be exactly the size specified by the application when it created the combo box. Usually, Windows CE sizes a combo box so that it does not display partial items.', ""))
    aoCBBStyles.Push(Styles("CBS_OEMCONVERT", "0x80", 'Converts text typed in the combo box edit control from the Windows CE character set to the OEM character set and then back to the Windows CE set. This style is most useful for combo boxes that contain file names. It applies only to combo boxes created with the CBS_DROPDOWN style.', ""))
    aoCBBStyles.Push(Styles("CBS_SIMPLE", "0x1", '+/-Simple (ComboBox only). Displays the drop-down list at all times. The current selection in the list is displayed in the edit control.', "Simple"))
    aoCBBStyles.Push(Styles("CBS_SORT", "0x100", '+/-Sort. Sorts the items in the drop-list alphabetically.', "Sort"))
    aoCBBStyles.Push(Styles("CBS_UPPERCASE", "0x2000", '+/-Uppercase. Converts to uppercase any lowercase characters that are typed into the edit control of a ComboBox.', "Uppercase"))

    global aoLBStyles := Array()
    aoLBStyles.Push(Styles("LBS_DISABLENOSCROLL", "0x1000", 'Shows a disabled vertical scroll bar for the list box when the box does not contain enough items to scroll. If you do not specify this style, the scroll bar is hidden when the list box does not contain enough items.', ""))
    aoLBStyles.Push(Styles("LBS_NOINTEGRALHEIGHT", "0x100", 'Specifies that the list box will be exactly the size specified by the application when it created the list box.', ""))
    aoLBStyles.Push(Styles("LBS_EXTENDEDSEL", "0x800", '+/-Multi. Allows multiple selections via control-click and shift-click.', "Multi"))
    aoLBStyles.Push(Styles("LBS_MULTIPLESEL", "0x8", 'A simplified version of multi-select in which control-click and shift-click are not necessary because normal left clicks serve to extend the selection or de-select a selected item.', ""))
    aoLBStyles.Push(Styles("LBS_NOSEL", "0x4000", '+/-ReadOnly. Specifies that the user can view list box strings but cannot select them.', "ReadOnly"))
    aoLBStyles.Push(Styles("LBS_NOTIFY", "0x1", 'Causes the list box to send a notification code to the parent window whenever the user clicks a list box item (LBN_SELCHANGE), double-clicks an item (LBN_DBLCLK), or cancels the selection (LBN_SELCANCEL).', ""))
    aoLBStyles.Push(Styles("LBS_SORT", "0x2", '+/-Sort. Sorts the items in the list box alphabetically.', "Sort"))
    aoLBStyles.Push(Styles("LBS_USETABSTOPS", "0x80", 'Enables a ListBox to recognize and expand tab characters when drawing its strings. The default tab positions are 32 dialog box units apart. A dialog box unit is equal to one-fourth of the current dialog box base-width unit.', ""))

    global aoLVStyles := Array()
    aoLVStyles.Push(Styles("LVS_ALIGNLEFT", "0x800",'Items are left-aligned in icon and small icon view.',""))
    aoLVStyles.Push(Styles("LVS_ALIGNTOP", "0x0",'Items are aligned with the top of the list-view control in icon and small icon view. This is the default.',""))
    aoLVStyles.Push(Styles("LVS_AUTOARRANGE", "0x100",'Icons are automatically kept arranged in icon and small icon view.',""))
    aoLVStyles.Push(Styles("LVS_EDITLABELS", "0x200",'+/-ReadOnly. Specifying -ReadOnly (or +0x200) allows the user to edit the first field of each row in place.',"ReadOnly"))
    aoLVStyles.Push(Styles("LVS_ICON", "0x0",'+Icon. Specifies large-icon view.',"Icon"))
    aoLVStyles.Push(Styles("LVS_LIST", "0x3",'+List. Specifies list view.',"List"))
    aoLVStyles.Push(Styles("LVS_NOCOLUMNHEADER", "0x4000",'+/-Hdr. Avoids displaying column headers in report view.',"-Hdr"))
    aoLVStyles.Push(Styles("LVS_NOLABELWRAP", "0x80",'Item text is displayed on a single line in icon view. By default, item text may wrap in icon view.',""))
    aoLVStyles.Push(Styles("LVS_NOSCROLL", "0x2000",'Scrolling is disabled. All items must be within the client area. This style is not compatible with the LVS_LIST or LVS_REPORT styles.',""))
    aoLVStyles.Push(Styles("LVS_NOSORTHEADER", "0x8000",'+/-NoSortHdr. Column headers do not work like buttons. This style can be used if clicking a column header in report view does not carry out an action, such as sorting.',"NoSortHdr"))
    aoLVStyles.Push(Styles("LVS_OWNERDATA", "0x1000",'This style specifies a virtual list-view control (not directly supported by AutoHotkey).',""))
    aoLVStyles.Push(Styles("LVS_OWNERDRAWFIXED", "0x400",'The owner window can paint items in report view in response to WM_DRAWITEM messages (not directly supported by AutoHotkey).',""))
    aoLVStyles.Push(Styles("LVS_REPORT", "0x1",'+Report. Specifies report view.',"Report"))
    aoLVStyles.Push(Styles("LVS_SHAREIMAGELISTS", "0x40",'The image list will not be deleted when the control is destroyed. This style enables the use of the same image lists with multiple list-view controls.',""))
    aoLVStyles.Push(Styles("LVS_SHOWSELALWAYS", "0x8",'The selection, if any, is always shown, even if the control does not have keyboard focus.',""))
    aoLVStyles.Push(Styles("LVS_SINGLESEL", "0x4",'+/-Multi. Only one item at a time can be selected. By default, multiple items can be selected.',"Multi"))
    aoLVStyles.Push(Styles("LVS_SMALLICON", "0x2",'+IconSmall. Specifies small-icon view.',"IconSmall"))
    aoLVStyles.Push(Styles("LVS_SORTASCENDING", "0x10",'+/-Sort. Rows are sorted in ascending order based on the contents of the first field.',"Sort"))
    aoLVStyles.Push(Styles("LVS_SORTDESCENDING", "0x20",'+/-SortDesc. Same as above but in descending order.',"SortDesc."))

    global aoLVExStyles := Array()
    aoLVExStyles.Push(Styles("LVS_EX_BORDERSELECT", "LV0x8000",'When an item is selected, the border color of the item changes rather than the item being highlighted (might be non-functional in recent operating systems).',""))
    aoLVExStyles.Push(Styles("LVS_EX_CHECKBOXES", "LV0x4",'+/-Checked. Displays a checkbox with each item. When set to this style, the control creates and sets a state image list with two images using DrawFrameControl. State image 1 is the unchecked box, and state image 2 is the checked box. Setting the state image to zero removes the check box altogether.',"Checked"))
    aoLVExStyles.Push(Styles("LVS_EX_DOUBLEBUFFER", "LV0x10000",'Paints via double-buffering, which reduces flicker. This extended style also enables alpha-blended marquee selection on systems where it is supported.',""))
    aoLVExStyles.Push(Styles("LVS_EX_FLATSB", "LV0x100",'Enables flat scroll bars in the list view.',""))
    aoLVExStyles.Push(Styles("LVS_EX_FULLROWSELECT", "LV0x20",'When a row is selected, all its fields are highlighted. This style is available only in conjunction with the LVS_REPORT style.',""))
    aoLVExStyles.Push(Styles("LVS_EX_GRIDLINES", "LV0x1",'+/-Grid. Displays gridlines around rows and columns. This style is available only in conjunction with the LVS_REPORT style.',"Grid"))
    aoLVExStyles.Push(Styles("LVS_EX_HEADERDRAGDROP", "LV0x10",'Enables drag-and-drop reordering of columns in a list-view control. This style is only available to list-view controls that use the LVS_REPORT style.',""))
    aoLVExStyles.Push(Styles("LVS_EX_INFOTIP", "LV0x400",'When a list-view control uses this style, the LVN_GETINFOTIP notification message is sent to the parent window before displaying an item`'s ToolTip.',""))
    aoLVExStyles.Push(Styles("LVS_EX_LABELTIP", "LV0x4000",'If a partially hidden label in any list-view mode lacks ToolTip text, the list-view control will unfold the label. If this style is not set, the list-view control will unfold partly hidden labels only for the large icon mode. Note: On some versions of Windows, this style might not work properly if the GUI window is set to be always-on-top.',""))
    aoLVExStyles.Push(Styles("LVS_EX_MULTIWORKAREAS", "LV0x2000",'If the list-view control has the LVS_AUTOARRANGE style, the control will not autoarrange its icons until one or more work areas are defined (see LVM_SETWORKAREAS). To be effective, this style must be set before any work areas are defined and any items have been added to the control.',""))
    aoLVExStyles.Push(Styles("LVS_EX_ONECLICKACTIVATE", "LV0x40",'The list-view control sends an LVN_ITEMACTIVATE notification message to the parent window when the user clicks an item. This style also enables hot tracking in the list-view control. Hot tracking means that when the cursor moves over an item, it is highlighted but not selected.',""))
    aoLVExStyles.Push(Styles("LVS_EX_REGIONAL", "LV0x200",'Sets the list-view window region to include only the item icons and text using SetWindowRgn. Any area that is not part of an item is excluded from the window region. This style is only available to list-view controls that use the LVS_ICON style.',""))
    aoLVExStyles.Push(Styles("LVS_EX_SIMPLESELECT", "LV0x100000",'In icon view, moves the state image of the item to the top right of the large icon rendering. In views other than icon view there is no change. When the user changes the state by using the space bar, all selected items cycle over, not the item with the focus.',""))
    aoLVExStyles.Push(Styles("LVS_EX_SUBITEMIMAGES", "LV0x2",'Allows images to be displayed for fields beyond the first. This style is available only in conjunction with the LVS_REPORT style.',""))
    aoLVExStyles.Push(Styles("LVS_EX_TRACKSELECT", "LV0x8",'Enables hot-track selection in a list-view control. Hot track selection means that an item is automatically selected when the cursor remains over the item for a certain period of time. The delay can be changed from the default system setting with a LVM_SETHOVERTIME message. This style applies to all styles of list-view control. You can check whether hot-track selection is enabled by calling SystemParametersInfo.',""))
    aoLVExStyles.Push(Styles("LVS_EX_TWOCLICKACTIVATE", "LV0x80",'The list-view control sends an LVN_ITEMACTIVATE notification message to the parent window when the user double-clicks an item. This style also enables hot tracking in the list-view control. Hot tracking means that when the cursor moves over an item, it is highlighted but not selected.',""))
    aoLVExStyles.Push(Styles("LVS_EX_UNDERLINECOLD", "LV0x1000",'Causes those non-hot items that may be activated to be displayed with underlined text. This style requires that LVS_EX_TWOCLICKACTIVATE be set also.',""))
    aoLVExStyles.Push(Styles("LVS_EX_UNDERLINEHOT", "LV0x800",'Causes those hot items that may be activated to be displayed with underlined text. This style requires that LVS_EX_ONECLICKACTIVATE or LVS_EX_TWOCLICKACTIVATE also be set.',""))


    global aoTreeViewStyles := Array()
    aoTreeViewStyles.Push(Styles("TVS_CHECKBOXES", "0x100",'+/-Checked. Displays a checkbox next to each item.',"Checked"))
    aoTreeViewStyles.Push(Styles("TVS_DISABLEDRAGDROP", "0x10",'Prevents the tree-view control from sending TVN_BEGINDRAG notification messages.',""))
    aoTreeViewStyles.Push(Styles("TVS_EDITLABELS", "0x8",'+/-ReadOnly. Allows the user to edit the names of tree-view items.',"ReadOnly"))
    aoTreeViewStyles.Push(Styles("TVS_FULLROWSELECT", "0x1000",'Enables full-row selection in the tree view. The entire row of the selected item is highlighted, and clicking anywhere on an item`'s row causes it to be selected. This style cannot be used in conjunction with the TVS_HASLINES style.',""))
    aoTreeViewStyles.Push(Styles("TVS_HASBUTTONS", "0x1",'+/-Buttons. Displays plus (+) and minus (-) buttons next to parent items. The user clicks the buttons to expand or collapse a parent item`'s list of child items. To include buttons with items at the root of the tree view, TVS_LINESATROOT must also be specified.',"Buttons"))
    aoTreeViewStyles.Push(Styles("TVS_HASLINES", "0x2",'+/-Lines. Uses lines to show the hierarchy of items.',"Lines"))
    aoTreeViewStyles.Push(Styles("TVS_INFOTIP", "0x800",'Obtains ToolTip information by sending the TVN_GETINFOTIP notification.',""))
    aoTreeViewStyles.Push(Styles("TVS_LINESATROOT", "0x4",'+/-Lines. Uses lines to link items at the root of the tree-view control. This value is ignored if TVS_HASLINES is not also specified.',"Lines"))
    aoTreeViewStyles.Push(Styles("TVS_NOHSCROLL", "0x8000",'+/-HScroll. Disables horizontal scrolling in the control. The control will not display any horizontal scroll bars.',"Hscroll"))
    aoTreeViewStyles.Push(Styles("TVS_NONEVENHEIGHT", "0x4000",'Sets the height of the items to an odd height with the TVM_SETITEMHEIGHT message. By default, the height of items must be an even value.',""))
    aoTreeViewStyles.Push(Styles("TVS_NOSCROLL", "0x2000",'Disables both horizontal and vertical scrolling in the control. The control will not display any scroll bars.',""))
    aoTreeViewStyles.Push(Styles("TVS_NOTOOLTIPS", "0x80",'Disables tooltips.',""))
    aoTreeViewStyles.Push(Styles("TVS_RTLREADING", "0x40",'Causes text to be displayed from right-to-left (RTL). Usually, windows display text left-to-right (LTR).',""))
    aoTreeViewStyles.Push(Styles("TVS_SHOWSELALWAYS", "0x20",'Causes a selected item to remain selected when the tree-view control loses focus.',""))
    aoTreeViewStyles.Push(Styles("TVS_SINGLEEXPAND", "0x400",'Causes the item being selected to expand and the item being unselected to collapse upon selection in the tree-view. If the user holds down Ctrl while selecting an item, the item being unselected will not be collapsed.',""))
    aoTreeViewStyles.Push(Styles("TVS_TRACKSELECT", "0x200",'Enables hot tracking of the mouse in a tree-view control.',""))


    global aoDateTimeStyles := Array()
    aoDateTimeStyles.Push(Styles("DTS_UPDOWN", "0x1",'Provides an up-down control to the right of the control to modify date-time values, which replaces the of the drop-down month calendar that would otherwise be available.',""))
    aoDateTimeStyles.Push(Styles("DTS_SHOWNONE", "0x2",'Displays a checkbox inside the control that users can uncheck to make the control have no date/time selected. Whenever the control has no date/time, Gui.Submit and GuiCtrl.Value will retrieve a blank value (empty string).',""))
    aoDateTimeStyles.Push(Styles("DTS_SHORTDATEFORMAT", "0x0",'Displays the date in short format. In some locales, it looks like 6/1/05 or 6/1/2005. On older operating systems, a two-digit year might be displayed. This is why DTS_SHORTDATECENTURYFORMAT is the default and not DTS_SHORTDATEFORMAT.',""))
    aoDateTimeStyles.Push(Styles("DTS_LONGDATEFORMAT", "0x4",'Format option "LongDate". Displays the date in long format. In some locales, it looks like Wednesday, June 01, 2005.',""))
    aoDateTimeStyles.Push(Styles("DTS_SHORTDATECENTURYFORMAT", "0xC",'Format option blank/omitted. Displays the date in short format with four-digit year. In some locales, it looks like 6/1/2005. If the system`'s version of Comctl32.dll is older than 5.8, this style is not supported and DTS_SHORTDATEFORMAT is automatically substituted.',""))
    aoDateTimeStyles.Push(Styles("DTS_TIMEFORMAT", "0x9",'Format option "Time". Displays only the time, which in some locales looks like 5:31:42 PM.',""))
    aoDateTimeStyles.Push(Styles("DTS_APPCANPARSE", "0x10",'Not yet supported. Allows the owner to parse user input and take necessary action. It enables users to edit within the client area of the control when they press F2. The control sends DTN_USERSTRING notification messages when users are finished.',""))
    aoDateTimeStyles.Push(Styles("DTS_RIGHTALIGN", "0x20",'+/-Right. The calendar will drop down on the right side of the control instead of the left.',"Right"))


    global aoMonthCalStyles := Array()
    aoMonthCalStyles.Push(Styles("MCS_DAYSTATE", "0x1",'Makes the control send MCN_GETDAYSTATE notifications to request information about which days should be displayed in bold. [Not yet supported]',""))
    aoMonthCalStyles.Push(Styles("MCS_WEEKNUMBERS", "0x4",'Displays week numbers (1-52) to the left of each row of days. Week 1 is defined as the first week that contains at least four days.',""))
    aoMonthCalStyles.Push(Styles("MCS_NOTODAYCIRCLE", "0x8",'Prevents the circling of today`'s date within the control.',""))
    aoMonthCalStyles.Push(Styles("MCS_NOTODAY", "0x10",'Prevents the display of today`'s date at the bottom of the control.',""))


    global aoSliderStyles := Array()
    aoSliderStyles.Push(Styles("TBS_VERT", "0x2",'+/-Vertical. The control is oriented vertically.',"Vertical"))
    aoSliderStyles.Push(Styles("TBS_LEFT", "0x4",'+/-Left. The control displays tick marks at the top of the control (or to its left if TBS_VERT is present). Same as TBS_TOP.',"Left"))
    aoSliderStyles.Push(Styles("TBS_TOP", "0x4",'same as TBS_LEFT.',""))
    aoSliderStyles.Push(Styles("TBS_BOTH", "0x8",'+/-Center. The control displays tick marks on both sides of the control. This will be both top and bottom when used with TBS_HORZ or both left and right if used with TBS_VERT.',"Center"))
    aoSliderStyles.Push(Styles("TBS_AUTOTICKS", "0x1",'The control has a tick mark for each increment in its range of values. Use +/-TickInterval to have more flexibility.',""))
    aoSliderStyles.Push(Styles("TBS_ENABLESELRANGE", "0x20",'The control displays a selection range only. The tick marks at the starting and ending positions of a selection range are displayed as triangles (instead of vertical dashes), and the selection range is highlighted (highlighting might require that the theme be removed via GuiObj.Opt("-Theme")).',""))
    aoSliderStyles.Push(Styles("TBS_FIXEDLENGTH", "0x40",'+/-Thick. Allows the thumb`'s size to be changed.',"Thick"))
    aoSliderStyles.Push(Styles("TBS_NOTHUMB", "0x80",'The control does not display the moveable bar.',""))
    aoSliderStyles.Push(Styles("TBS_NOTICKS", "0x10",'+/-NoTicks. The control does not display any tick marks.',"NoTicks"))
    aoSliderStyles.Push(Styles("TBS_TOOLTIPS", "0x100",'+/-ToolTip. The control supports tooltips. When a control is created using this style, it automatically creates a default ToolTip control that displays the slider`'s current position. You can change where the tooltips are displayed by using the TBM_SETTIPSIDE message.',"ToolTip"))
    aoSliderStyles.Push(Styles("TBS_REVERSED", "0x200",'Unfortunately, this style has no effect on the actual behavior of the control, so there is probably no point in using it (instead, use +Invert in the control`'s options to reverse it). Depending on OS version, this style might require Internet Explorer 5.0 or greater.',""))
    aoSliderStyles.Push(Styles("TBS_DOWNISLEFT", "0x400",'Unfortunately, this style has no effect on the actual behavior of the control, so there is probably no point in using it. Depending on OS version, this style might require Internet Explorer 5.01 or greater.',""))


    global aoProgressStyles := Array()
    aoProgressStyles.Push(Styles("PBS_SMOOTH", "0x1",'+/-Smooth. The progress bar displays progress status in a smooth scrolling bar instead of the default segmented bar. When this style is present, the control automatically reverts to the Classic Theme appearance.',"Smooth"))
    aoProgressStyles.Push(Styles("PBS_VERTICAL", "0x4",'+/-Vertical. The progress bar displays progress status vertically, from bottom to top.',"Vertical"))
    aoProgressStyles.Push(Styles("PBS_MARQUEE", "0x8",'The progress bar moves like a marquee; that is, each change to its position causes the bar to slide further along its available length until it wraps around to the other side. A bar with this style has no defined position. Each attempt to change its position will instead slide the bar by one increment. This style is typically used to indicate an ongoing operation whose completion time is unknown.',""))

    global aoTabStyles := Array()
    aoTabStyles.Push(Styles("TCS_SCROLLOPPOSITE", "0x1", 'Unneeded tabs scroll to the opposite side of the control when a tab is selected.', ""))
    aoTabStyles.Push(Styles("TCS_BOTTOM", "0x2", '+/-Bottom. Tabs appear at the bottom of the control instead of the top.', "Bottom"))
    aoTabStyles.Push(Styles("TCS_RIGHT", "0x2", 'Tabs appear vertically on the right side of controls that use the TCS_VERTICAL style.', ""))
    aoTabStyles.Push(Styles("TCS_MULTISELECT", "0x4", 'Multiple tabs can be selected by holding down Ctrl when clicking. This style must be used with the TCS_BUTTONS style.', ""))
    aoTabStyles.Push(Styles("TCS_FLATBUTTONS", "0x8", 'Selected tabs appear as being indented into the background while other tabs appear as being on the same plane as the background. This style only affects tab controls with the TCS_BUTTONS style.', ""))
    aoTabStyles.Push(Styles("TCS_FORCEICONLEFT", "0x10", 'Icons are aligned with the left edge of each fixed-width tab. This style can only be used with the TCS_FIXEDWIDTH style.', ""))
    aoTabStyles.Push(Styles("TCS_FORCELABELLEFT", "0x20", 'Labels are aligned with the left edge of each fixed-width tab; that is, the label is displayed immediately to the right of the icon instead of being centered. This style can only be used with the TCS_FIXEDWIDTH style, and it implies the TCS_FORCEICONLEFT style.', ""))
    aoTabStyles.Push(Styles("TCS_HOTTRACK", "0x40", 'Items under the pointer are automatically highlighted.', ""))
    aoTabStyles.Push(Styles("TCS_VERTICAL", "0x80", '+/-Left or +/-Right. Tabs appear at the left side of the control, with tab text displayed vertically. This style is valid only when used with the TCS_MULTILINE style. To make tabs appear on the right side of the control, also use the TCS_RIGHT style.', "Left"))
    aoTabStyles.Push(Styles("TCS_BUTTONS", "0x100", '+/-Buttons. Tabs appear as buttons, and no border is drawn around the display area.', "Buttons"))
    aoTabStyles.Push(Styles("TCS_SINGLELINE", "0x0", '+/-Wrap. Only one row of tabs is displayed. The user can scroll to see more tabs, if necessary. This style is the default.', "Wrap"))
    aoTabStyles.Push(Styles("TCS_MULTILINE", "0x200", '+/-Wrap. Multiple rows of tabs are displayed, if necessary, so all tabs are visible at once.', "Wrap"))
    aoTabStyles.Push(Styles("TCS_RIGHTJUSTIFY", "0x0", 'This is the default. The width of each tab is increased, if necessary, so that each row of tabs fills the entire width of the tab control. This style will not correctly display the tabs if a custom background color or text color is in effect. To workaround this, specify -Background and/or cDefault in the tab control`'s options. This window style is ignored unless the TCS_MULTILINE style is also specified.', ""))
    aoTabStyles.Push(Styles("TCS_FIXEDWIDTH", "0x400", 'All tabs are the same width. This style cannot be combined with the TCS_RIGHTJUSTIFY style.', ""))
    aoTabStyles.Push(Styles("TCS_RAGGEDRIGHT", "0x800", 'Rows of tabs will not be stretched to fill the entire width of the control. This style is the default.', ""))
    aoTabStyles.Push(Styles("TCS_FOCUSONBUTTONDOWN", "0x1000", 'The tab control receives the input focus when clicked.', ""))
    aoTabStyles.Push(Styles("TCS_OWNERDRAWFIXED", "0x2000", 'The parent window is responsible for drawing tabs.', ""))
    aoTabStyles.Push(Styles("TCS_TOOLTIPS", "0x4000", 'The tab control has a tooltip control associated with it.', ""))
    aoTabStyles.Push(Styles("TCS_FOCUSNEVER", "0x8000", 'The tab control does not receive the input focus when clicked.', ""))

    global aoStatusbarStyles := Array()
    aoStatusbarStyles.Push(Styles("SBARS_TOOLTIPS", "0x800",'Displays a tooltip when the mouse hovers over a part of the status bar that: 1) has too much text to be fully displayed; or 2) has an icon but no text. The text of the tooltip can be set via: SendMessage 0x0410, 0, "Text to display", "msctls_statusbar321", MyGui The bold 0 above is the zero-based part number. To use a part other than the first, specify 1 for second, 2 for the third, etc. NOTE: The tooltip might never appear on certain OS versions.',""))
    aoStatusbarStyles.Push(Styles("SBARS_SIZEGRIP", "0x100",'Includes a sizing grip at the right end of the status bar. A sizing grip is similar to a sizing border; it is a rectangular area that the user can click and drag to resize the parent window.',""))

    Global aoDefaultStyles := Object()
    aoDefaultStyles.window := {style:0xffffffff94ca0000, exStyle:0x100}
    aoDefaultStyles.gui := {style:0xffffffff94ca0000, exStyle:0x100}
    aoDefaultStyles.edit := {style:0x50010080, exStyle:0x200}
    aoDefaultStyles.editmultiLine := {style:0x50211040, exStyle:0x200}
    aoDefaultStyles.button := {style:0x50010000, exStyle:0x0}
    aoDefaultStyles.checkbox := {style:0x50010003, exStyle:0x0}
    aoDefaultStyles.hotkey := {style:0x50010000, exStyle:0x200}
    aoDefaultStyles.monthcal := {style:0x50010000, exStyle:0x0}
    aoDefaultStyles.picture := {style:0x50000003, exStyle:0x0}
    aoDefaultStyles.progress := {style:0x50000000, exStyle:0x0}
    aoDefaultStyles.radio := {style:0x50030009, exStyle:0x0}
    aoDefaultStyles.slider := {style:0x50030000, exStyle:0x0}
    aoDefaultStyles.tab3 := {style:0x54010240, exStyle:0x0}
    aoDefaultStyles.text := {style:0x50000000, exStyle:0x0}
    aoDefaultStyles.treeview := {style:0x50010027, exStyle:0x200}
    aoDefaultStyles.combobox := {style:0x50010242, exStyle:0x0}
    aoDefaultStyles.datetime := {style:0x5201000c, exStyle:0x0}
    aoDefaultStyles.dropdownlist := {style:0x50010203, exStyle:0x0}
    aoDefaultStyles.groupbox := {style:0x50000007, exStyle:0x0}
    aoDefaultStyles.link := {style:0x50010000, exStyle:0x0}
    aoDefaultStyles.listbox := {style:0x50010081, exStyle:0x200}
   aoDefaultStyles.listview := {style:0x50010009, exStyle:0x0}
    aoDefaultStyles.statusbar := {style:0x50000800, exStyle:0x0}
    aoDefaultStyles.separator := {style:0x50000000, exStyle:0x0}
}


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

    ; Attempt to use Scintilla control, but this generates an error
    ; ogEdit_script := MyGui.AddScintilla("x+2 yp w600 h500 DefaultOpt LightTheme")

    ; Scintilla_SetAHKV2(ogEdit_script)

    ; size := FileGetSize(sFile)
    ; size := StrPut(FileRead(sFile),"UTF-8") ; alternative code
    ; ptr := ogEdit_script.Doc.Create(3000+100)
    ; ogEdit_script.Doc.ptr := ptr

    ; ; ======================================================================
    ; ; These must usually be set after changing document ptr.
    ; ; ======================================================================
    ; ogEdit_script.Tab.Use := false ; use spaces instad of tabs
    ; ogEdit_script.Tab.Width := 4 ; number of spaces for a tab

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

            oControl := Array()
            oControl.oName := "myMenuBar"
            oSubMenu := Array()
            oSubMenu.name := "FileMenu"
            oSubMenu.oName := "FileMenu"
            oSubMenu.Push({name:"&Open ScriptDir", Callback: "(*) => (Run(A_ScriptDir))"})
            oSubMenu.Push({name:"&Reload", Callback: "(*) => (Reload())"})
            oSubMenu.Push("Separator")
            oSubMenu.Push({name:"&Exit", Callback: "(*) => (ExitApp)"})
            oControl.Push(oSubMenu)

            oG.Window.MenuBar := oControl
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
                ogNewCtrl.h := isSet(hCtrl) ? hCtrl : ""
                ogNewCtrl.w := isSet(wCtrl) ? wCtrl : ""
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
        ContextMenu.Add("Properties Window", Gui_Window_Properties)
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
    x_prev := 0
    y_prev := 0
    loop
    {
        mousegetpos( &x, &y)
        if (x_prev != x or y_prev != y){
            ToolTip("press F12 on the Window you want to clone")
        }

        x_prev := x
        y_prev := y
        if GetKeyState("F12"){
            break
        }

    }

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
    WinGetPos(&winX, &winY,,, "ahk_id " WinID)
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
        Control_Type := ControlGetType(controlHwnd)
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
        oG.ControlList[n].oName := StrReplace(ClassNN," ")
        oG.ControlList[n].Text := ControlText
        oG.ControlList[n].Visible := ControlVisible
        oG.ControlList[n].x := ctrlX
        oG.ControlList[n].y := ctrlY
        oG.ControlList[n].w := ctrlWidth
        oG.ControlList[n].h := ctrlHeight

        If (Control_Type = "Button") {
            If (ControlType == 1 or (ControlStyle & 0x1)) { ;BS_DEFPUSHBUTTON
                Options .= " +Default"
            }

        } Else If (Control_Type == "Edit") {
            Options .= !(ControlExStyle & 0x200) ? " -E0x200" : "" ; no border
            Options .= (ControlStyle & 0x2000) ? " +Number" : "" ; ES_NUMBER
            Options .= (ControlStyle & 0x4) ? " +Multi" : "" ; ES_MULTILINE
            Options .= (ControlStyle & 0x800) ? " +ReadOnly" : "" ; ES_READONLY
            Options .= (ControlStyle & 0x2) ? " +Right" : "" ; ES_RIGHT
            Options .= (ControlStyle & 0x8) ? " +UpperCase" : "" ; ES_UPPERCASE
            Options .= (ControlStyle & 0x10) ? " +LowerCase" : "" ; ES_LOWERCASE
            Options .= (ControlStyle & 0x20) ? " +Password" : "" ; ES_PASSWORD
            oG.ControlList[n].Text := StrReplace(StrReplace(ControlText, "‏"),"‎") ; Correction on strange characters

        } Else If (Control_Type == "Text") {
            If (ControlType = 1) {
                Options .= " +Center"
            } Else If (ControlType == 2) {
                Options .= " +Right"
            }
        }If (Control_Type = "Picture") {
            ; 3:  SS_ICON
            ; 14: SS_BITMAP

            Options .= " 0x6 +Border"	; SS_WHITERECT
        } Else If (Control_Type = "Separator") {
            Options .= " 0x10"	; Separator
        } Else If (Control_Type == "Slider") {
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
        } Else If (Control_Type == "TreeView") {
            ControlText := ""
        } Else If (Control_Type == "UpDown") {
            Options .= " -16"
        } Else If (Control_Type == "Tab3") {
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
        } Else If (Control_Type == "Progress") {
            oG.ControlList[n].Text := SendMessage(0x408, 0, 0,ClassNN , "ahk_id " WinID)	; PBM_GETPOS

            If !(ControlStyle & 0x1) {
                Options .= " -Smooth"
            }
            If (ControlType == 4) {
                Options .= " +Vertical"
            }
        } Else If (Control_Type == "Link" && !InStr(ControlText, "<a")) {
            ControlText := "<a>" . ControlText . "</a>"
        } else If (Control_Type = "ListView"){
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

        If (Control_Type ~= "ComboBox|ListBox|DropDownList") {
            oG.ControlList[n].Array := ControlGetItems(controlHwnd)
        }
        If (Control_Type ~= "CheckBox|Radio") {
            Checked := ControlGetChecked(ClassNN , "ahk_id " WinID)
            If (Checked) {
                Options .= " +Checked"
            }
            Options := ControlGetChecked(controlHwnd) ? " +Checked" : ""
        }
        If (Control_Type ~= "StatusBar") {
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
        if ((Control_Type = "Button" and ctrlHeight = 23) || (Control_Type = "CheckBox" and ctrlHeight = 16) || (Control_Type = "Radio" and ctrlHeight = 13) || Control_Type ~= "Combobox|DropDownList"){
            oG.ControlList[n].DeleteProp("h")
        }

        Enabled := ControlGetEnabled(controlHwnd)

        If (ControlStyle & 0x08000000) {
            Options .= " +Disabled"
        }
        oG.ControlList[n].ControlType := Control_Type
        ; oG.ControlList[n].Options := Options
        oG.ControlList[n].Options := ControlGetAHKOptions(Control_Type, ControlStyle, ControlExStyle)

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
    DllCall("DestroyWindow", "UInt", GuiCtrlObj.Hwnd) ; destroy the control
    GenerateCode()
}

Gui_Window_Properties(p*) {
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

    ogCB_BackColor := ogProp.AddCheckbox("xs+10 yp+20 w80", "BackColor:")
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
        ogLV_Font.Modify(2, "", "Style", StrReplace(fontObj.str, " c" fontObj.color, ""))
        ogLV_Font.Modify(3, "", "Size", fontObj.size)
        ogLV_Font.Modify(4, "", "Color", fontObj.color)
    }

    Click_PropApply(*) {

        if (ogCB_BackColor.value){
            WorkGui.BackColor := ogEdit_BackColor.Value
            oG.Window.BackColor := ogEdit_BackColor.Value
        } else{
            WorkGui.BackColor := 0xF0F0F0
            oG.Window.BackColor := ""
        }

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

    ogCB_w := ogProp.AddCheckbox("xs+15 y+m w40 ", "W:")
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

    ogProp.AddGroupBox("xs+5 y+10 w250 h45", "Control Color")

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
        (!ogCB_x.value && oCtrl.x := "")
        (!ogCB_y.value && oCtrl.y := "")
        (!ogCB_h.value && oCtrl.h := "")
        (!ogCB_h.value && oCtrl.h := "")
        if(ogCB_x.value and (!oCtrl.HasProp("x") or ogEdit_xCtrl.Value!= oCtrl.x) ){
            oCtrl.x := ogEdit_xCtrl.Value
            ControlMove(oCtrl.x, , , , GuiCtrlObj)
        }
        if (ogCB_y.value and (!oCtrl.HasProp("y") or ogEdit_yCtrl.Value != oCtrl.y)) {
            oCtrl.y := ogEdit_yCtrl.Value
            ControlMove(, oCtrl.y, , , GuiCtrlObj)
        }
        if (ogCB_w.value and (!oCtrl.HasProp("w") or ogEdit_wCtrl.Value != oCtrl.w)) {
            oCtrl.w := ogEdit_wCtrl.Value
            ControlMove(, ,oCtrl.w , , GuiCtrlObj)
        }
        if (ogCB_h.value and (!oCtrl.HasProp("h") or ogEdit_hCtrl.Value != oCtrl.h)) {
            oCtrl.h := ogEdit_hCtrl.Value
            ControlMove(, , ,oCtrl.h , GuiCtrlObj)
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
    Header := "#SingleInstance Force" CRLF "#Requires AutoHotkey v2.0-a" CRLF CRLF
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
                Text := (Text = "" && oControl.ControlType="Picture") ? "mspaint.exe" : Text
                Text := InStr(Text,'"') ? "'" Text "'" :  '"' Text '"'
            }

            Options := (oControl.HasProp("x") and oControl.x != "") ? "x" oControl.x : ""
            Options .= (oControl.HasProp("y") and oControl.y != "") ? " y" oControl.y : ""
            Options .= (oControl.HasProp("w") and oControl.w != "") ? " w" oControl.w : ""
            Options .= (oControl.HasProp("h") and oControl.h != "") ? " h" oControl.h : ""
            Options .= (oControl.HasProp("Visible") and !oControl.Visible) ? " +Hidden" : ""
            Options .= (oControl.HasProp("Options") and oControl.Options != "") ? " " oControl.Options : ""
            Options := (Options = "") ? "" : '"' trim(Options) '"'

            Code .= (oControl.ControlType = "" or oControl.ControlType ~= "i)Gui|Toolbar") ? Indent "; " : Indent ; comment out not defined types
            Code .=  oControl.oName ' := ' oG.Window.oName '.Add' oControl.ControlType '(' Options ', ' Text ')' CRLF
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
    ogEdit_script.Text := ""
    ; ControlSetText(Header,ogEdit_script.hwnd)
    ; ogEdit_script.Text := StrReplace(Header Code,"`r")
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
            Code .= Indent MenuObjectName '.Add("' oMenuItem.name '",' (oMenuItem.hasProp("CallBack") ? oMenuItem.callback : '(ItemName, ItemPos, MyMenu)=>(MsgBox(ItemName))') ')'  CRLF
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

    GuiControlObj := (ControlHwndMouse != "") ? GuiCtrlFromHwnd(ControlHwndMouse) : ControlHwndMouse

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
    fObj.size := Round(NumGet(CHOOSEFONT,p*4,"UInt") / 10)

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

ControlGetType(ctrl_hwnd) {
    ctrl_ClassNN := ControlGetClassNN(ctrl_hwnd)
    ctrl_text := ControlGetText(ctrl_hwnd)
    ctrl_AhkName := TranslateClassName(ctrl_ClassNN)
    ControlType := ControlGetStyle(ctrl_hwnd) & 0xF
    ControlGetPos(&ctrl_x, &ctrl_y, &ctrl_w, &ctrl_h, ctrl_hwnd)
    If (ctrl_AhkName = "Button") {
        ; 1: BS_DEFPUSHBUTTON
        ; 2: BS_CHECKBOX
        ; 3: BS_AUTOCHECK
        ; 4: BS_RADIOBUTTON
        ; 5: BS_3STATE
        ; 6: BS_AUTO3STATE
        ; 9: BS_AUTORADIOBUTTON
        If (ControlType == 1) {
            ctrl_AhkName := "Button"
        } Else if (ControlType ~= "^(?i:2|3|5|6)$")
            ctrl_AhkName := "CheckBox"
        Else if (ControlType ~= "^(?i:4|9)$")
            ctrl_AhkName := "Radio"
        Else If (ControlType == 7)
            ctrl_AhkName := "GroupBox"

    } Else If (ctrl_AhkName == "Text") {
        If (ControlType == 3 || ControlType == 14) {
            ; 3:  SS_ICON
            ; 14: SS_BITMAP
            ctrl_AhkName := "Picture"
        }
        ; If (ctrl_text == "" && ctrl_h == 2) {
        ;     ctrl_AhkName := "Separator"
        ; }
    } Else If (ctrl_AhkName == "ComboBox") {
        If (ControlType == 3) {
            ctrl_AhkName := "DropDownList"
        } Else {
            ctrl_AhkName := "ComboBox"
        }
    }
    return ctrl_AhkName
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
    } Else If (InStr(ClassName, "msctls_hotkey")) {
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
    } Else If (InStr(ClassName, "toolbar")) {
        AhkName := "ToolBar"
    } Else If (InStr(ClassName, "ScrollBar")) {
        AhkName := "ScrollBar"
    } Else If (InStr(ClassName, "AutoHotkeyGui")) {
        AhkName := "Gui"
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

ControlGetAHKOptions(ObjectType, object_Style, object_ExStyle) {
    Options := ""
    SkipOptions := ""	;Styles to be skipped because of set options
    optionsBuffer := ""
    aoStyles := (ObjectType = "window") ? aoWinStyles : aoControlStyles

    if !aoDefaultStyles.HasProp(ObjectType){
        return Options
    }

    defaultStyle := aoDefaultStyles.%ObjectType%.style
    defaultExStyle := aoDefaultStyles.%ObjectType%.exStyle

    if (ObjectType="Checkbox"){
        ; Correction on Check3 Checkbox
        if(object_Style & 0xF== 6){
            optionsBuffer .= "Check3 "
            defaultStyle := 0x50010006
        }
    }

    aoStyles_extra := ""
    aoStyles_extra := (ObjectType = "text") ? aoTextStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "Edit") ? aoEditStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "EditMultiline") ? aoEditMultilineStyles : aoStyles_extra
    aoStyles_extra := (ObjectType ~= "Button|CheckBox|Radio|GroupBox") ? aoButtonStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "text") ? aoTextStyles : aoStyles_extra

    aoStyles_extra := (ObjectType = "updown") ? aoUpDownStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "picture") ? aoPicStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "Combobox") ? aoCBBStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "DropDownList") ? aoCBBStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "ListBox") ? aoLBStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "ListView") ? aoLVStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "TreeView") ? aoTreeViewStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "DateTime") ? aoDateTimeStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "MonthCal") ? aoMonthCalStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "Slider") ? aoSliderStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "Progress") ? aoProgressStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "Tab3") ? aoTabStyles : aoStyles_extra
    aoStyles_extra := (ObjectType = "Statusbar") ? aoStatusbarStyles : aoStyles_extra

    ; general style
    for index, oStyle in aoStyles {
        Options .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " ((defaultStyle & oStyle.Hex) ? "-" : "+") (oStyle.OptionText = "" ? oStyle.Hex : oStyle.OptionText)
        SkipOptions .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " (oStyle.SkipHex)
    }

    ; object specific styles
    if (aoStyles_extra != "") {
        for index, oStyle in aoStyles_extra {
            Options .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " ((defaultStyle & oStyle.Hex) ? "-" : "+") (oStyle.OptionText = "" ? oStyle.Hex : oStyle.OptionText)
            SkipOptions .= (((defaultStyle & oStyle.Hex) && (object_Style & oStyle.Hex)) | (!(defaultStyle & oStyle.Hex) && !(object_Style & oStyle.Hex))) ? "" : " " (oStyle.SkipHex)
        }
    }

    for index, oExStyle in aoWinExStyles {
        Options .= (((defaultExStyle & oExStyle.Hex) && (object_ExStyle & oExStyle.Hex)) | (!(defaultExStyle & oExStyle.Hex) && !(object_ExStyle & oExStyle.Hex))) ? "" : " " ((defaultExStyle & oExStyle.Hex) ? "-" : "+") (oExStyle.OptionText = "" ? "E" oExStyle.Hex : oExStyle.OptionText)
        SkipOptions .= (((defaultExStyle & oExStyle.Hex) && (object_ExStyle & oExStyle.Hex)) | (!(defaultStyle & oExStyle.Hex) && !(object_ExStyle & oExStyle.Hex))) ? "" : " " (oExStyle.SkipHex)
    }

    Loop parse, Options, A_space {
        if !InStr(" " SkipOptions " ", " " A_LoopField " ", ) {
            optionsBuffer .= A_LoopField " "
        }
    }

    optionsBuffer :=StrReplace(optionsBuffer,"+-", "-")

    return optionsBuffer
}

Scintilla_SetAHKV2(ctl) {
    ctl.CaseSense := false	; turn off case sense (for AHK), do this before setting keywords
    kw1 := "Else If Continue Critical Break Goto Return Loop Read Reg Parse Files Switch Try Catch Finally Throw Until While For Exit ExitApp OnError OnExit Reload Suspend Thread"

    kw2 := "Abs ASin ACos ATan BlockInput Buffer CallbackCreate CallbackFree CaretGetPos Ceil Chr Click ClipboardAll ClipWait ComCall ComObjActive ComObjArray ComObjConnect ComObject ComObjFlags ComObjFromPtr ComObjGet ComObjQuery ComObjType ComObjValue ComValue ControlAddItem ControlChooseIndex ControlChooseString ControlClick ControlDeleteItem ControlFindItem ControlFocus ControlGetChecked ControlGetChoice ControlGetClassNN ControlGetEnabled ControlGetFocus ControlGetHwnd ControlGetIndex ControlGetItems ControlGetPos ControlGetStyle ControlGetExStyle ControlGetText ControlGetVisible ControlHide ControlHideDropDown ControlMove ControlSend ControlSendText ControlSetChecked ControlSetEnabled ControlSetStyle ControlSetExStyle ControlSetText ControlShow ControlShowDropDown CoordMode Cos DateAdd DateDiff DetectHiddenText DetectHiddenWindows DirCopy DirCreate DirDelete DirExist DirMove DirSelect DllCall Download DriveEject DriveGetCapacity DriveGetFileSystem DriveGetLabel DriveGetList DriveGetSerial DriveGetSpaceFree DriveGetStatus DriveGetStatusCD DriveGetType DriveLock DriveRetract DriveSetLabel DriveUnlock Edit EditGetCurrentCol EditGetCurrentLine EditGetLine EditGetLineCount EditGetSelectedText EditPaste EnvGet EnvSet Exp FileAppend FileCopy FileCreateShortcut FileDelete FileEncoding FileExist FileInstall FileGetAttrib FileGetShortcut FileGetSize FileGetTime FileGetVersion FileMove FileOpen FileRead FileRecycle FileRecycleEmpty FileSelect FileSetAttrib FileSetTime Float Floor Format FormatTime GetKeyName GetKeyVK GetKeySC GetKeyState GetMethod GroupAdd GroupClose GroupDeactivate Gui GuiCtrlFromHwnd GuiFromHwnd HasBase HasMethod HasProp HotIf HotIfWinActive HotIfWinExist HotIfWinNotActive HotIfWinNotExist Hotkey Hotstring IL_Create IL_Add IL_Destroy ImageSearch IniDelete IniRead IniWrite InputBox InputHook InstallKeybdHook InstallMouseHook InStr Integer IsLabel IsObject IsSet IsSetRef KeyHistory KeyWait ListHotkeys ListLines ListVars ListViewGetContent LoadPicture Log Ln Map Max MenuBar Menu MenuFromHandle MenuSelect Min Mod MonitorGet MonitorGetCount MonitorGetName MonitorGetPrimary MonitorGetWorkArea MouseClick MouseClickDrag MouseGetPos MouseMove MsgBox Number NumGet NumPut ObjAddRef ObjRelease ObjBindMethod ObjHasOwnProp ObjOwnProps ObjGetBase ObjGetCapacity ObjOwnPropCount ObjSetBase ObjSetCapacity OnClipboardChange OnMessage Ord OutputDebug Pause Persistent PixelGetColor PixelSearch PostMessage ProcessClose ProcessExist ProcessSetPriority ProcessWait ProcessWaitClose Random RegExMatch RegExReplace RegDelete RegDeleteKey RegRead RegWrite Round Run RunAs RunWait Send SendText SendInput SendPlay SendEvent SendLevel SendMessage SendMode SetCapsLockState SetControlDelay SetDefaultMouseSpeed SetKeyDelay SetMouseDelay SetNumLockState SetScrollLockState SetRegView SetStoreCapsLockMode SetTimer SetTitleMatchMode SetWinDelay SetWorkingDir Shutdown Sin Sleep Sort SoundBeep SoundGetInterface SoundGetMute SoundGetName SoundGetVolume SoundPlay SoundSetMute SoundSetVolume SplitPath Sqrt StatusBarGetText StatusBarWait StrCompare StrGet String StrLen StrLower StrPut StrReplace StrSplit StrUpper SubStr SysGet SysGetIPAddresses Tan ToolTip TraySetIcon TrayTip Trim LTrim RTrim Type VarSetStrCapacity VerCompare WinActivate WinActivateBottom WinActive WinClose WinExist WinGetClass WinGetClientPos WinGetControls WinGetControlsHwnd WinGetCount WinGetID WinGetIDLast WinGetList WinGetMinMax WinGetPID WinGetPos WinGetProcessName WinGetProcessPath WinGetStyle WinGetExStyle WinGetText WinGetTitle WinGetTransColor WinGetTransparent WinHide WinKill WinMaximize WinMinimize WinMinimizeAll WinMinimizeAllUndo WinMove WinMoveBottom WinMoveTop WinRedraw WinRestore WinSetAlwaysOnTop WinSetEnabled WinSetRegion WinSetStyle WinSetExStyle WinSetTitle WinSetTransColor WinSetTransparent WinShow WinWait WinWaitActive WinWaitNotActive WinWaitClose"

    kw3 := "Add AddActiveX AddButton AddCheckbox AddComboBox AddCustom AddDateTime AddDropDownList AddEdit AddGroupBox AddHotkey AddLink AddListBox AddListView AddMonthCal AddPicture AddProgress AddRadio AddSlider AddStandard AddStatusBar AddTab AddText AddTreeView AddUpDown Bind Check Choose Clear Clone Close Count DefineMethod DefineProp Delete DeleteCol DeleteMethod DeleteProp Destroy Disable Enable Flash Focus Get GetAddress GetCapacity GetChild GetClientPos GetCount GetNext GetOwnPropDesc GetParent GetPos GetPrev GetSelection GetText Has HasKey HasOwnMethod HasOwnProp Hide Insert InsertAt InsertCol Len Mark Maximize MaxIndex Minimize MinIndex Modify ModifyCol Move Name OnCommand OnEvent OnNotify Opt OwnMethods OwnProps Pop Pos Push RawRead RawWrite Read ReadLine ReadUInt ReadInt ReadInt64 ReadShort ReadUShort ReadChar ReadUChar ReadDouble ReadFloat Redraw RemoveAt Rename Restore Seek Set SetCapacity SetColor SetFont SetIcon SetImageList SetParts SetText Show Submit Tell ToggleCheck ToggleEnable Uncheck UseTab Write WriteLine WriteUInt WriteInt WriteInt64 WriteShort WriteUShort WriteChar WriteUChar WriteDouble WriteFloat"

    kw4 := "AtEOF BackColor Base Capacity CaseSense ClassNN ClickCount Count Default Enabled Encoding Focused FocusedCtrl Gui Handle Hwnd Length MarginX MarginY MenuBar Name Pos Position Ptr Size Text Title Value Visible __Handle"

    kw5 := "A_Space A_Tab A_Args A_WorkingDir A_InitialWorkingDir A_ScriptDir A_ScriptName A_ScriptFullPath A_ScriptHwnd A_LineNumber A_LineFile A_ThisFunc A_AhkVersion A_AhkPath A_IsCompiled A_YYYY A_MM A_DD A_MMMM A_MMM A_DDDD A_DDD A_WDay A_YDay A_YWeek A_Hour A_Min A_Sec A_MSec A_Now A_NowUTC A_TickCount A_IsSuspended A_IsPaused A_IsCritical A_ListLines A_TitleMatchMode A_TitleMatchModeSpeed A_DetectHiddenWindows A_DetectHiddenText A_FileEncoding A_SendMode A_SendLevel A_StoreCapsLockMode A_KeyDelay A_KeyDuration A_KeyDelayPlay A_KeyDurationPlay A_WinDelay A_ControlDelay A_MouseDelay A_MouseDelayPlay A_DefaultMouseSpeed A_CoordModeToolTip A_CoordModePixel A_CoordModeMouse A_CoordModeCaret A_CoordModeMenu A_RegView A_TrayMenu A_AllowMainWindow A_AllowMainWindow A_IconHidden A_IconTip A_IconFile A_IconNumber A_TimeIdle A_TimeIdlePhysical A_TimeIdleKeyboard A_TimeIdleMouse A_ThisHotkey A_PriorHotkey A_PriorKey A_TimeSinceThisHotkey A_TimeSincePriorHotkey A_EndChar A_EndChar A_MaxHotkeysPerInterval A_HotkeyInterval A_HotkeyModifierTimeout A_ComSpec A_Temp A_OSVersion A_Is64bitOS A_PtrSize A_Language A_ComputerName A_UserName A_WinDir A_ProgramFiles A_AppData A_AppDataCommon A_Desktop A_DesktopCommon A_StartMenu A_StartMenuCommon A_Programs A_ProgramsCommon A_Startup A_StartupCommon A_MyDocuments A_IsAdmin A_ScreenWidth A_ScreenHeight A_ScreenDPI A_Clipboard A_Cursor A_EventInfo A_LastError True False A_Index A_LoopFileName A_LoopRegName A_LoopReadLine A_LoopField this"

    kw6 := "#ClipboardTimeout #DllLoad #ErrorStdOut #Hotstring #HotIf #HotIfTimeout #Include #IncludeAgain #InputLevel #MaxThreads #MaxThreadsBuffer #MaxThreadsPerHotkey #NoTrayIcon #Requires #SingleInstance #SuspendExempt #UseHook #Warn #WinActivateForce #If"

    kw7 := "Global Local Static Class"

    ctl.setKeywords(kw1, kw2, kw3, kw4, kw5, kw6, kw7)

    ; ======================================================================

    ; ctl.UseDirect := true ; the DLL uses the Direct Ptr for now
    ; ctl.Wrap.LayoutCache := 3 ; speeds up window resize on large docs, but sometimes causes slower load times on large documents
    ; ======================================================================
    ; items that should be set by the user
    ; ======================================================================
    ctl.Brace.Chars := "[]{}()"	; modify braces list that will be tracked
    ctl.SyntaxEscapeChar := "``"	; set this to "\" to load up CustomLexer.c, or to "``" to load an AHK script.
    ctl.SyntaxCommentLine := ";"	; set this to "//" to load up CustomLexer.c, or to ";" to load an AHK script.

    ; ======================================================================
    ; Setting DLL punct and word chars:
    ;
    ; Below are the defaults for punct and word chars for the DLL.  Setting
    ; punct and word chars for Scintilla has a different purpose and a
    ; slightly different effect.  It's also kinda of squirrely.  Since it is
    ; possible to use a direct pointer to parse Scintilla text I leave the
    ; Scintilla defaults for punct and word chars alone.
    ;
    ; You'll notice that the punct defaults also contain braces, escape
    ; chars, and of course " and '.  The search for punct chars happens
    ; after searching for those other elements, and thus doesn't affect
    ; how braces, strings, and escape chars function.
    ;
    ; For WordChars, since a variable or function must normally start with
    ; a letter or underscore, only specify letters and underscore/pound sign
    ; if desired.  Matching for digits in a "word" is done separately assuming
    ; the first character of the "word" is not a digit.
    ; ======================================================================
    ; ctl.SyntaxPunctChars := "!`"$%&'()*+,-./:;<=>?@[\]^``{|}~"                      ; this is the default
    ; ctl.SyntaxWordChars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_#" ; this is the default

    ; ======================================================================
    ; Simple to apply vertical colored lines at specified column - uncomment to test
    ; ======================================================================
    ; ctl.Edge.Mode := 3 ; vertical lines - handy!
    ; ctl.Edge.Multi.Add(5,0xFF0000)
    ; ctl.Edge.Multi.Add(10,0x00FF00)
    ; ctl.Edge.Multi.Add(15,0x0000FF)
    ; ctl.Edge.View := 1

    ; ======================================================================
    ; To see white space/CRLF/other special non-printing chars
    ; ======================================================================
    ; ctl.WhiteSpace.View := 1
    ; ctl.LineEnding.View := 1
    ; ======================================================================

    ;ctl.callback := ctl_callback ; Adding a callback
    ctl.CustomSyntaxHighlighting := true	; turns syntax highlighting on
    ctl.AutoSizeNumberMargin := true
    ; ctl.Target.Flags := Scintilla.sc_search.RegXP | Scintilla.sc_search.CXX11RegEx ; CXX11RegEx | POSIX

    ; ======================================================================

    ; ctl.Styling.Idle := 3 ; do NOT set this when using my syntax highlighting.  My syntax highlighting works differently.

    ; ======================================================================
    ; Set this to prevent unnecessary parsing and improve load time.  While
    ; editing the document additional parsing must happen in order to
    ; properly color the various elements of the document correctly when
    ; adding/deleting/uncommenting text.  This value will automatically be
    ; set to 0 after loading a document.
    ; ======================================================================
    ctl.loading := 1
}

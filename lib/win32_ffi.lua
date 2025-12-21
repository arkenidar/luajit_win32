-- win32_ffi.lua
-- LuaJIT FFI bindings for Win32 GUI APIs

local ffi = require("ffi")
local M = {}

-- Store callbacks to prevent garbage collection
local _callbacks = {}

-- FFI Type and Structure Definitions
ffi.cdef[[
    // Basic Windows types
    typedef void* HWND;
    typedef void* HINSTANCE;
    typedef void* HMENU;
    typedef void* HICON;
    typedef void* HCURSOR;
    typedef void* HBRUSH;
    typedef void* LPVOID;
    typedef void* HANDLE;
    typedef long LONG;
    typedef unsigned long DWORD;
    typedef int BOOL;
    typedef unsigned int UINT;
    typedef long long LPARAM;
    typedef long long WPARAM;
    typedef long long LRESULT;
    typedef long long INT_PTR;
    typedef const wchar_t* LPCWSTR;
    typedef wchar_t* LPWSTR;
    typedef const char* LPCSTR;
    typedef char* LPSTR;
    typedef unsigned short WORD;
    typedef unsigned char BYTE;

    // Structures
    typedef struct {
        UINT    style;
        void*   lpfnWndProc;
        int     cbClsExtra;
        int     cbWndExtra;
        HINSTANCE hInstance;
        HICON   hIcon;
        HCURSOR hCursor;
        HBRUSH  hbrBackground;
        LPCWSTR lpszMenuName;
        LPCWSTR lpszClassName;
    } WNDCLASSW;

    typedef struct {
        HWND   hwnd;
        UINT   message;
        WPARAM wParam;
        LPARAM lParam;
        DWORD  time;
        struct { LONG x; LONG y; } pt;
    } MSG;

    typedef struct {
        LONG left;
        LONG top;
        LONG right;
        LONG bottom;
    } RECT;

    // user32.dll functions
    HINSTANCE GetModuleHandleW(LPCWSTR lpModuleName);
    int RegisterClassW(const WNDCLASSW* lpWndClass);
    HWND CreateWindowExW(
        DWORD dwExStyle,
        LPCWSTR lpClassName,
        LPCWSTR lpWindowName,
        DWORD dwStyle,
        int X, int Y,
        int nWidth, int nHeight,
        HWND hWndParent,
        HMENU hMenu,
        HINSTANCE hInstance,
        LPVOID lpParam
    );
    BOOL ShowWindow(HWND hWnd, int nCmdShow);
    BOOL UpdateWindow(HWND hWnd);
    BOOL GetMessageW(MSG* lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax);
    BOOL TranslateMessage(const MSG* lpMsg);
    LRESULT DispatchMessageW(const MSG* lpMsg);
    void PostQuitMessage(int nExitCode);
    LRESULT DefWindowProcW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
    LRESULT SendMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
    BOOL PostMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
    HCURSOR LoadCursorW(HINSTANCE hInstance, LPCWSTR lpCursorName);
    HICON LoadIconW(HINSTANCE hInstance, LPCWSTR lpIconName);
    HBRUSH GetSysColorBrush(int nIndex);
    BOOL DestroyWindow(HWND hWnd);
    int MessageBoxW(HWND hWnd, LPCWSTR lpText, LPCWSTR lpCaption, UINT uType);
    BOOL SetWindowTextW(HWND hWnd, LPCWSTR lpString);
    int GetWindowTextW(HWND hWnd, LPWSTR lpString, int nMaxCount);
    int GetWindowTextLengthW(HWND hWnd);
    BOOL EnableWindow(HWND hWnd, BOOL bEnable);

    // kernel32.dll functions
    DWORD GetLastError(void);
    int MultiByteToWideChar(
        UINT CodePage,
        DWORD dwFlags,
        LPCSTR lpMultiByteStr,
        int cbMultiByte,
        LPWSTR lpWideCharStr,
        int cchWideChar
    );
    int WideCharToMultiByte(
        UINT CodePage,
        DWORD dwFlags,
        LPCWSTR lpWideCharStr,
        int cchWideChar,
        LPSTR lpMultiByteStr,
        int cbMultiByte,
        LPCSTR lpDefaultChar,
        BOOL* lpUsedDefaultChar
    );

    // Timer functions
    typedef unsigned long long UINT_PTR;
    UINT_PTR SetTimer(HWND hWnd, UINT_PTR nIDEvent, UINT uElapse, void* lpTimerFunc);
    BOOL KillTimer(HWND hWnd, UINT_PTR uIDEvent);

    // Window positioning and sizing functions
    BOOL SetWindowPos(
        HWND hWnd,
        HWND hWndInsertAfter,
        int X,
        int Y,
        int cx,
        int cy,
        UINT uFlags
    );

    BOOL MoveWindow(HWND hWnd, int X, int Y, int nWidth, int nHeight, BOOL bRepaint);
    BOOL GetClientRect(HWND hWnd, RECT* lpRect);
    BOOL GetWindowRect(HWND hWnd, RECT* lpRect);
    BOOL InvalidateRect(HWND hWnd, const RECT* lpRect, BOOL bErase);

    // Batch window positioning for performance
    typedef void* HDWP;
    HDWP BeginDeferWindowPos(int nNumWindows);
    HDWP DeferWindowPos(
        HDWP hWinPosInfo,
        HWND hWnd,
        HWND hWndInsertAfter,
        int x,
        int y,
        int cx,
        int cy,
        UINT uFlags
    );
    BOOL EndDeferWindowPos(HDWP hWinPosInfo);

    // Min/Max size tracking
    typedef struct {
        struct { LONG x; LONG y; } ptReserved;
        struct { LONG x; LONG y; } ptMaxSize;
        struct { LONG x; LONG y; } ptMaxPosition;
        struct { LONG x; LONG y; } ptMinTrackSize;
        struct { LONG x; LONG y; } ptMaxTrackSize;
    } MINMAXINFO;
]]

-- Load DLLs
local user32 = ffi.load("user32")
local kernel32 = ffi.load("kernel32")

-- Windows Constants

-- Window Styles (WS_*)
M.WS_OVERLAPPED       = 0x00000000
M.WS_POPUP            = 0x80000000
M.WS_CHILD            = 0x40000000
M.WS_MINIMIZE         = 0x20000000
M.WS_VISIBLE          = 0x10000000
M.WS_DISABLED         = 0x08000000
M.WS_CLIPSIBLINGS     = 0x04000000
M.WS_CLIPCHILDREN     = 0x02000000
M.WS_MAXIMIZE         = 0x01000000
M.WS_CAPTION          = 0x00C00000
M.WS_BORDER           = 0x00800000
M.WS_DLGFRAME         = 0x00400000
M.WS_VSCROLL          = 0x00200000
M.WS_HSCROLL          = 0x00100000
M.WS_SYSMENU          = 0x00080000
M.WS_THICKFRAME       = 0x00040000
M.WS_GROUP            = 0x00020000
M.WS_TABSTOP          = 0x00010000
M.WS_MINIMIZEBOX      = 0x00020000
M.WS_MAXIMIZEBOX      = 0x00010000
M.WS_OVERLAPPEDWINDOW = 0x00CF0000  -- WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX

-- Window Messages (WM_*)
M.WM_NULL             = 0x0000
M.WM_CREATE           = 0x0001
M.WM_DESTROY          = 0x0002
M.WM_MOVE             = 0x0003
M.WM_SIZE             = 0x0005
M.WM_ACTIVATE         = 0x0006
M.WM_SETFOCUS         = 0x0007
M.WM_KILLFOCUS        = 0x0008
M.WM_ENABLE           = 0x000A
M.WM_SETTEXT          = 0x000C
M.WM_GETTEXT          = 0x000D
M.WM_GETTEXTLENGTH    = 0x000E
M.WM_PAINT            = 0x000F
M.WM_CLOSE            = 0x0010
M.WM_QUIT             = 0x0012
M.WM_QUERYOPEN        = 0x0013
M.WM_ERASEBKGND       = 0x0014
M.WM_SYSCOLORCHANGE   = 0x0015
M.WM_SHOWWINDOW       = 0x0018
M.WM_ACTIVATEAPP      = 0x001C
M.WM_SETCURSOR        = 0x0020
M.WM_MOUSEACTIVATE    = 0x0021
M.WM_GETMINMAXINFO    = 0x0024
M.WM_WINDOWPOSCHANGING= 0x0046
M.WM_WINDOWPOSCHANGED = 0x0047
M.WM_NCCREATE         = 0x0081
M.WM_NCDESTROY        = 0x0082
M.WM_NCCALCSIZE       = 0x0083
M.WM_NCHITTEST        = 0x0084
M.WM_NCPAINT          = 0x0085
M.WM_NCACTIVATE       = 0x0086
M.WM_GETDLGCODE       = 0x0087
M.WM_KEYDOWN          = 0x0100
M.WM_KEYUP            = 0x0101
M.WM_CHAR             = 0x0102
M.WM_COMMAND          = 0x0111
M.WM_SYSCOMMAND       = 0x0112
M.WM_GETMINMAXINFO    = 0x0024
M.WM_TIMER            = 0x0113
M.WM_HSCROLL          = 0x0114
M.WM_VSCROLL          = 0x0115
M.WM_INITMENU         = 0x0116
M.WM_INITMENUPOPUP    = 0x0117
M.WM_MENUSELECT       = 0x011F
M.WM_MENUCHAR         = 0x0120
M.WM_ENTERIDLE        = 0x0121
M.WM_CTLCOLORMSGBOX   = 0x0132
M.WM_CTLCOLOREDIT     = 0x0133
M.WM_CTLCOLORLISTBOX  = 0x0134
M.WM_CTLCOLORBTN      = 0x0135
M.WM_CTLCOLORDLG      = 0x0136
M.WM_CTLCOLORSCROLLBAR= 0x0137
M.WM_CTLCOLORSTATIC   = 0x0138
M.WM_MOUSEMOVE        = 0x0200
M.WM_LBUTTONDOWN      = 0x0201
M.WM_LBUTTONUP        = 0x0202
M.WM_LBUTTONDBLCLK    = 0x0203
M.WM_RBUTTONDOWN      = 0x0204
M.WM_RBUTTONUP        = 0x0205
M.WM_RBUTTONDBLCLK    = 0x0206
M.WM_USER             = 0x0400

-- Button Styles (BS_*)
M.BS_PUSHBUTTON       = 0x00000000
M.BS_DEFPUSHBUTTON    = 0x00000001
M.BS_CHECKBOX         = 0x00000002
M.BS_AUTOCHECKBOX     = 0x00000003
M.BS_RADIOBUTTON      = 0x00000004
M.BS_3STATE           = 0x00000005
M.BS_AUTO3STATE       = 0x00000006
M.BS_GROUPBOX         = 0x00000007
M.BS_AUTORADIOBUTTON  = 0x00000009

-- Button Notifications (BN_*)
M.BN_CLICKED          = 0
M.BN_PAINT            = 1
M.BN_HILITE           = 2
M.BN_UNHILITE         = 3
M.BN_DISABLE          = 4
M.BN_DOUBLECLICKED    = 5
M.BN_SETFOCUS         = 6
M.BN_KILLFOCUS        = 7

-- Listbox Styles (LBS_*)
M.LBS_NOTIFY          = 0x0001
M.LBS_SORT            = 0x0002
M.LBS_NOREDRAW        = 0x0004
M.LBS_MULTIPLESEL     = 0x0008
M.LBS_OWNERDRAWFIXED  = 0x0010
M.LBS_OWNERDRAWVARIABLE = 0x0020
M.LBS_HASSTRINGS      = 0x0040
M.LBS_USETABSTOPS     = 0x0080
M.LBS_NOINTEGRALHEIGHT = 0x0100
M.LBS_MULTICOLUMN     = 0x0200
M.LBS_WANTKEYBOARDINPUT = 0x0400
M.LBS_EXTENDEDSEL     = 0x0800
M.LBS_DISABLENOSCROLL = 0x1000
M.LBS_NODATA          = 0x2000
M.LBS_NOSEL           = 0x4000
M.LBS_STANDARD        = 0xA00003  -- LBS_NOTIFY | LBS_SORT | WS_VSCROLL | WS_BORDER

-- Listbox Messages (LB_*)
M.LB_ADDSTRING        = 0x0180
M.LB_INSERTSTRING     = 0x0181
M.LB_DELETESTRING     = 0x0182
M.LB_SELITEMRANGEEX   = 0x0183
M.LB_RESETCONTENT     = 0x0184
M.LB_SETSEL           = 0x0185
M.LB_SETCURSEL        = 0x0186
M.LB_GETSEL           = 0x0187
M.LB_GETCURSEL        = 0x0188
M.LB_GETTEXT          = 0x0189
M.LB_GETTEXTLEN       = 0x018A
M.LB_GETCOUNT         = 0x018B
M.LB_SELECTSTRING     = 0x018C
M.LB_DIR              = 0x018D
M.LB_GETTOPINDEX      = 0x018E
M.LB_FINDSTRING       = 0x018F
M.LB_GETSELCOUNT      = 0x0190
M.LB_GETSELITEMS      = 0x0191
M.LB_SETTABSTOPS      = 0x0192
M.LB_GETHORIZONTALEXTENT = 0x0193
M.LB_SETHORIZONTALEXTENT = 0x0194

-- Listbox Notifications (LBN_*)
M.LBN_ERRSPACE        = -2
M.LBN_SELCHANGE       = 1
M.LBN_DBLCLK          = 2
M.LBN_SELCANCEL       = 3
M.LBN_SETFOCUS        = 4
M.LBN_KILLFOCUS       = 5

-- Edit Control Styles (ES_*)
M.ES_LEFT             = 0x0000
M.ES_CENTER           = 0x0001
M.ES_RIGHT            = 0x0002
M.ES_MULTILINE        = 0x0004
M.ES_UPPERCASE        = 0x0008
M.ES_LOWERCASE        = 0x0010
M.ES_PASSWORD         = 0x0020
M.ES_AUTOVSCROLL      = 0x0040
M.ES_AUTOHSCROLL      = 0x0080
M.ES_NOHIDESEL        = 0x0100
M.ES_OEMCONVERT       = 0x0400
M.ES_READONLY         = 0x0800
M.ES_WANTRETURN       = 0x1000
M.ES_NUMBER           = 0x2000

-- Edit Control Messages (EM_*)
M.EM_GETSEL           = 0x00B0
M.EM_SETSEL           = 0x00B1
M.EM_GETRECT          = 0x00B2
M.EM_SETRECT          = 0x00B3
M.EM_SETRECTNP        = 0x00B4
M.EM_SCROLL           = 0x00B5
M.EM_LINESCROLL       = 0x00B6
M.EM_SCROLLCARET      = 0x00B7
M.EM_GETMODIFY        = 0x00B8
M.EM_SETMODIFY        = 0x00B9
M.EM_GETLINECOUNT     = 0x00BA
M.EM_LINEINDEX        = 0x00BB
M.EM_SETHANDLE        = 0x00BC
M.EM_GETHANDLE        = 0x00BD
M.EM_GETTHUMB         = 0x00BE
M.EM_LINELENGTH       = 0x00C1
M.EM_REPLACESEL       = 0x00C2
M.EM_GETLINE          = 0x00C4
M.EM_LIMITTEXT        = 0x00C5
M.EM_CANUNDO          = 0x00C6
M.EM_UNDO             = 0x00C7
M.EM_FMTLINES         = 0x00C8
M.EM_LINEFROMCHAR     = 0x00C9

-- Static Control Styles (SS_*)
M.SS_LEFT             = 0x00000000
M.SS_CENTER           = 0x00000001
M.SS_RIGHT            = 0x00000002
M.SS_ICON             = 0x00000003
M.SS_BLACKRECT        = 0x00000004
M.SS_GRAYRECT         = 0x00000005
M.SS_WHITERECT        = 0x00000006
M.SS_BLACKFRAME       = 0x00000007
M.SS_GRAYFRAME        = 0x00000008
M.SS_WHITEFRAME       = 0x00000009
M.SS_SIMPLE           = 0x0000000B
M.SS_LEFTNOWORDWRAP   = 0x0000000C

-- ShowWindow Commands (SW_*)
M.SW_HIDE             = 0
M.SW_SHOWNORMAL       = 1
M.SW_NORMAL           = 1
M.SW_SHOWMINIMIZED    = 2
M.SW_SHOWMAXIMIZED    = 3
M.SW_MAXIMIZE         = 3
M.SW_SHOWNOACTIVATE   = 4
M.SW_SHOW             = 5
M.SW_MINIMIZE         = 6
M.SW_SHOWMINNOACTIVE  = 7
M.SW_SHOWNA           = 8
M.SW_RESTORE          = 9
M.SW_SHOWDEFAULT      = 10

-- MessageBox Flags (MB_*)
M.MB_OK               = 0x00000000
M.MB_OKCANCEL         = 0x00000001
M.MB_ABORTRETRYIGNORE = 0x00000002
M.MB_YESNOCANCEL      = 0x00000003
M.MB_YESNO            = 0x00000004
M.MB_RETRYCANCEL      = 0x00000005
M.MB_ICONHAND         = 0x00000010
M.MB_ICONQUESTION     = 0x00000020
M.MB_ICONEXCLAMATION  = 0x00000030
M.MB_ICONASTERISK     = 0x00000040
M.MB_ICONWARNING      = M.MB_ICONEXCLAMATION
M.MB_ICONERROR        = M.MB_ICONHAND
M.MB_ICONINFORMATION  = M.MB_ICONASTERISK
M.MB_ICONSTOP         = M.MB_ICONHAND

-- MessageBox Return Values (ID*)
M.IDOK                = 1
M.IDCANCEL            = 2
M.IDABORT             = 3
M.IDRETRY             = 4
M.IDIGNORE            = 5
M.IDYES               = 6
M.IDNO                = 7

-- SetWindowPos flags
M.SWP_NOSIZE          = 0x0001
M.SWP_NOMOVE          = 0x0002
M.SWP_NOZORDER        = 0x0004
M.SWP_NOREDRAW        = 0x0008
M.SWP_NOACTIVATE      = 0x0010
M.SWP_FRAMECHANGED    = 0x0020
M.SWP_SHOWWINDOW      = 0x0040
M.SWP_HIDEWINDOW      = 0x0080
M.SWP_NOCOPYBITS      = 0x0100
M.SWP_NOOWNERZORDER   = 0x0200
M.SWP_NOSENDCHANGING  = 0x0400

-- SetWindowPos hWndInsertAfter values
M.HWND_TOP            = ffi.cast("HWND", 0)
M.HWND_BOTTOM         = ffi.cast("HWND", 1)
M.HWND_TOPMOST        = ffi.cast("HWND", -1)
M.HWND_NOTOPMOST      = ffi.cast("HWND", -2)

-- Other Constants
M.CW_USEDEFAULT       = 0x80000000
M.IDC_ARROW           = 32512
M.COLOR_3DFACE        = 15
M.COLOR_WINDOW        = 5
M.COLOR_WINDOWTEXT    = 8

-- CodePage constants for string conversion
local CP_UTF8 = 65001
local CP_ACP = 0

-- Helper Functions

-- Convert Lua UTF-8 string to Windows wide string (UTF-16)
function M.to_wstring(str)
    if str == nil or str == "" then
        local wstr = ffi.new("wchar_t[1]")
        wstr[0] = 0
        return wstr
    end

    -- Get required buffer size
    local size = ffi.C.MultiByteToWideChar(CP_UTF8, 0, str, #str, nil, 0)
    if size == 0 then
        error("MultiByteToWideChar failed: " .. ffi.C.GetLastError())
    end

    -- Allocate buffer and convert
    local wstr = ffi.new("wchar_t[?]", size + 1)
    local result = ffi.C.MultiByteToWideChar(CP_UTF8, 0, str, #str, wstr, size)
    if result == 0 then
        error("MultiByteToWideChar failed: " .. ffi.C.GetLastError())
    end
    wstr[size] = 0  -- Null terminator

    return wstr
end

-- Convert Windows wide string (UTF-16) to Lua UTF-8 string
function M.from_wstring(wstr, len)
    if wstr == nil then
        return ""
    end

    -- If length not provided, calculate it
    if len == nil or len < 0 then
        len = 0
        while wstr[len] ~= 0 do
            len = len + 1
        end
    end

    if len == 0 then
        return ""
    end

    -- Get required buffer size
    local size = ffi.C.WideCharToMultiByte(CP_UTF8, 0, wstr, len, nil, 0, nil, nil)
    if size == 0 then
        error("WideCharToMultiByte failed: " .. ffi.C.GetLastError())
    end

    -- Allocate buffer and convert
    local str = ffi.new("char[?]", size + 1)
    local result = ffi.C.WideCharToMultiByte(CP_UTF8, 0, wstr, len, str, size, nil, nil)
    if result == 0 then
        error("WideCharToMultiByte failed: " .. ffi.C.GetLastError())
    end
    str[size] = 0  -- Null terminator

    return ffi.string(str)
end

-- Create callback and prevent garbage collection
function M.create_callback(func)
    local callback = ffi.cast("LRESULT (*)(HWND, UINT, WPARAM, LPARAM)", func)
    table.insert(_callbacks, callback)
    return callback
end

-- Wrap Win32 API functions for easier use
M.GetModuleHandleW = ffi.C.GetModuleHandleW
M.RegisterClassW = ffi.C.RegisterClassW
M.CreateWindowExW = ffi.C.CreateWindowExW
M.ShowWindow = ffi.C.ShowWindow
M.UpdateWindow = ffi.C.UpdateWindow
M.GetMessageW = ffi.C.GetMessageW
M.TranslateMessage = ffi.C.TranslateMessage
M.DispatchMessageW = ffi.C.DispatchMessageW
M.PostQuitMessage = ffi.C.PostQuitMessage
M.DefWindowProcW = ffi.C.DefWindowProcW
M.SendMessageW = ffi.C.SendMessageW
M.PostMessageW = ffi.C.PostMessageW
M.LoadCursorW = ffi.C.LoadCursorW
M.LoadIconW = ffi.C.LoadIconW
M.GetSysColorBrush = ffi.C.GetSysColorBrush
M.DestroyWindow = ffi.C.DestroyWindow
M.MessageBoxW = ffi.C.MessageBoxW
M.SetWindowTextW = ffi.C.SetWindowTextW
M.GetWindowTextW = ffi.C.GetWindowTextW
M.GetWindowTextLengthW = ffi.C.GetWindowTextLengthW
M.EnableWindow = ffi.C.EnableWindow
M.GetLastError = ffi.C.GetLastError
M.SetTimer = ffi.C.SetTimer
M.KillTimer = ffi.C.KillTimer

-- Window positioning functions
M.SetWindowPos = ffi.C.SetWindowPos
M.MoveWindow = ffi.C.MoveWindow
M.GetClientRect = ffi.C.GetClientRect
M.GetWindowRect = ffi.C.GetWindowRect
M.InvalidateRect = ffi.C.InvalidateRect
M.BeginDeferWindowPos = ffi.C.BeginDeferWindowPos
M.DeferWindowPos = ffi.C.DeferWindowPos
M.EndDeferWindowPos = ffi.C.EndDeferWindowPos

-- Helper to extract control ID and notification code from WM_COMMAND wParam
function M.extract_command(wParam)
    local control_id = bit.band(tonumber(wParam), 0xFFFF)
    local notification = bit.rshift(tonumber(wParam), 16)
    return control_id, notification
end

-- Helper to cast LPARAM to HWND
function M.lparam_to_hwnd(lParam)
    return ffi.cast("HWND", lParam)
end

return M

#include <windows.h>
#include <commctrl.h>

#define IDC_LIST 1

HWND hList;

LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
void CreateControl(HWND);

///////////////// example from e-book: http://zetcode.com/ebooks/windowsapi/

/*
# cross-compilation notes (e.g. compiling for Windows from Ubuntu/Debian)

# install cross-compiler for cross-compiling for Win64
sudo apt-get install mingw-w64

# cross-compile app
x86_64-w64-mingw32-gcc -o app.exe winmain.c

# run app using Wine
wine app.exe

*/

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR pCmdLine, int nCmdShow) {

    MSG  msg ;    
    WNDCLASSW wc = {0};
    wc.lpszClassName = L"SimpleListBox";
    wc.hInstance     = hInstance;
    wc.hbrBackground = GetSysColorBrush(COLOR_3DFACE);
    wc.lpfnWndProc   = WndProc;
    wc.hCursor       = LoadCursor(0, IDC_ARROW);
  
    RegisterClassW(&wc);
    CreateWindowW(wc.lpszClassName, L"Simple List Box (native compiled in Geany+GCC)",
                  WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                  100, 100, 350, 200, 0, 0, hInstance, 0);  

    while (GetMessage(&msg, NULL, 0, 0)) {
    
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    
    return (int) msg.wParam;
}


LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, 
    WPARAM wParam, LPARAM lParam) {

    switch(msg) {

        case WM_CREATE:

            CreateControl(hwnd);
       
            break;
 
        case WM_DESTROY:
        
            PostQuitMessage(0);
            break;
    }

    return (DefWindowProcW(hwnd, msg, wParam, lParam));
}

void CreateControl(HWND hwnd) {

    hList = CreateWindowW(WC_LISTBOXW , NULL, WS_CHILD 
        | WS_VISIBLE | LBS_SORT, 10, 10, 200, 150, hwnd, 
        (HMENU) IDC_LIST, NULL, NULL);

    SendMessageW(hList, LB_ADDSTRING, 0, (LPARAM) L"Blue");
    SendMessageW(hList, LB_ADDSTRING, 0, (LPARAM) L"Red");
    SendMessageW(hList, LB_ADDSTRING, 0, (LPARAM) L"Green");
    SendMessageW(hList, LB_ADDSTRING, 0, (LPARAM) L"Yellow");
    SendMessageW(hList, LB_ADDSTRING, 0, (LPARAM) L"Brown");
    
    SendMessageW(hList, LB_ADDSTRING, 0, (LPARAM) L"?????");

    SendMessageW(hList, LB_SETCURSEL, 2, 0);
}

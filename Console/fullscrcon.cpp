#include <windows.h>
#include <stdio.h>

// prototypes
BOOL FullScreenConsole9x(void);
BOOL FullScreenConsoleNT(void);

// ---------------------------------------------------------------------- -----
BOOL FullScreenConsole9x(void)
{
    BOOL ok = FALSE;

        // console finding guid
        // a unique number to identify this console - replace this with your own
        #define CON_GUID TEXT("CON_GUID-{68E311EF-BF32-4b0f-8D35-E84E4A463096}")

        // hwnd for console window
        HWND hConWnd = NULL;

    // magic command
    WPARAM magic = 57359;

        // buffer for storing a substitute title
        TCHAR szTempTitle[] = CON_GUID;

        // buffer for storing current console title
        TCHAR szTempString[MAX_PATH];

        // obtain the current console title
        if( GetConsoleTitle(szTempString, sizeof(szTempString)/sizeof(TCHAR) ) )
        {
                // replace the current title with substitute title
                SetConsoleTitle(szTempTitle);

                // give it a chance to set in
                Sleep(50);

                // locate the console window

                // console window class on W9x is "tty"
                hConWnd = FindWindow(TEXT("tty"), szTempTitle);

                // restore the original console title
                SetConsoleTitle(szTempString);

        }

        // verify the console hwnd
        if ( hConWnd != NULL ) {

            // pause before changing to fullscreen
        Sleep(450);

        // this method works by faking a keyboard command
        SendMessage(hConWnd,WM_COMMAND,magic,0);

        ok = TRUE;

        }

    return ok;

}

// ---------------------------------------------------------------------- -----
BOOL FullScreenConsoleNT(void)
{
    // typedef function pointer for undocumented API
    typedef BOOL WINAPI (*SetConsoleDisplayModeT)(HANDLE,DWORD,DWORD*);

    // declare one such function pointer
    SetConsoleDisplayModeT SetConsoleDisplayMode;

        // load kernel32.dll
        HINSTANCE hLib = LoadLibrary("KERNEL32.DLL");
    if ( hLib == NULL ) {
        // highly unlikely but good practice just the same
        return FALSE;
    }

        // assign procedure address to function pointer
        SetConsoleDisplayMode = ( SetConsoleDisplayModeT )
                GetProcAddress(hLib,"SetConsoleDisplayMode");

        // check if the function pointer is valid
    // since the function is undocumented
        if ( SetConsoleDisplayMode == NULL ) {
        // play nice with windows
            FreeLibrary(hLib);
                return FALSE;
        }

        DWORD newmode = 1;      // fullscreen mode
        DWORD oldmode;

        // get handle to stdout
        HANDLE hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);

        // pause before changing to fullscreen
        Sleep(500);

        // set full screen mode
        SetConsoleDisplayMode(hStdOut,newmode,&oldmode);

    // play nice with windows
        FreeLibrary(hLib);

    return TRUE;

}

// ---------------------------------------------------------------------- -----
int main(void)
{

    OSVERSIONINFO VerInfo;
    ZeroMemory(&VerInfo,sizeof(VerInfo));
    VerInfo.dwOSVersionInfoSize = sizeof(VerInfo);
    GetVersionEx(&VerInfo);

        // Why a switch? because I felt like switching... har har
    switch ( VerInfo.dwPlatformId ) {

                case VER_PLATFORM_WIN32_NT :
                FullScreenConsoleNT();
                        break;

                case VER_PLATFORM_WIN32_WINDOWS :
                FullScreenConsole9x();
                        break;

                default:
                        break;

    }

        // issue a report
        printf("This is a test.\nHit enter to exit");

        // wait for keyboard hit
        getchar();

    return 0;
}
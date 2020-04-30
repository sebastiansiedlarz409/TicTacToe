.386
.MODEL Flat, STDCALL
option casemap:none

;biblioteki 
include \masm32\include\windows.inc 
include \masm32\include\kernel32.inc 
includelib \masm32\lib\kernel32.lib 
include \masm32\include\user32.inc 
includelib \masm32\lib\user32.lib 
include \masm32\include\gdi32.inc
includelib \masm32\lib\gdi32.lib

.data

klasa_okna db "WinClass",0
tytul db "Kółko Krzyżyk",0
tekst db "Witaj!",0
char WPARAM 20h  
tablica dd " "," "," "," "," "," "," "," "," "
ostatni_znak dd 88
er db "Błąd!",0
zly_klawisz db "Do wyboru pola użyj myszki lub klawiszy 1-9 oraz upewnij się czy pole nie jest już zajęte!!!",0
w db "WYGRANA!!!",0
wO db "Wygrywa O!!!",0
wX db "Wygrywa X!!!",0
pomoc db "R - nowa gra",13,10,"P - pomoc",13,10,"ESC - wyjście",0
uwaga db "Uwaga!!!",0
restart db "Gra rozpocznie się na nowo!",0
pom db "Pomoc",0
remis db "Brak zwycięscy!!!",0
licznik_remisu db 0

;kolory w RGB little endian
kolor_tla dd 00AA0000h 
kolor_kolka dd 0000AA00h
kolor_krzyzyka dd 000000FFh
kolor_siatki dd 00000000h
kolor_przekreslenia dd 0000FFFFh

.data?
hInstance HINSTANCE ?
hBrush dd ?
hKOPen dd ?
hKRZPen dd ?
hSPen dd ?
hPrzPen dd ?
wspolrzedne POINT <>

.code
start:

invoke GetModuleHandle, 0
mov hInstance, eax
call WinMain
invoke ExitProcess, 0    

WinMain proc
    LOCAL window:WNDCLASSEX
    LOCAL msg:MSG

    mov window.cbSize, sizeof WNDCLASSEX     
    mov window.style, CS_HREDRAW or CS_VREDRAW 
    mov window.lpfnWndProc, offset WndProc  
    push hInstance
    pop window.hInstance
    invoke CreateSolidBrush, kolor_tla 
    mov window.hbrBackground, eax                                          
    mov window.lpszMenuName, 0 
    mov window.lpszClassName, offset klasa_okna
    invoke LoadIcon, 0, IDI_APPLICATION
    mov window.hIcon, eax
    mov window.hIconSm, eax
    invoke LoadCursor, 0, IDC_CROSS
    mov window.hCursor, eax
    invoke RegisterClassEx, addr window
    invoke CreateWindowEx, 0, addr klasa_okna, addr tytul, WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX or WS_VISIBLE, 100, 100, 327, 349, 0, 0, hInstance, 0   
    .WHILE TRUE
        invoke GetMessage, addr msg, 0, 0, 0
    .BREAK .IF (!eax)
        invoke TranslateMessage, addr msg
        invoke DispatchMessage, addr msg
    .ENDW
    ret
WinMain endp

;kod do obslugi zdarzen
WndProc proc hWnd:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

LOCAL hdc:HDC
LOCAL ps:PAINTSTRUCT

.IF uMsg==WM_DESTROY  

    invoke DeleteObject,hKOPen
    invoke DeleteObject,hKRZPen
    invoke DeleteObject,hSPen
    invoke DeleteObject,hPrzPen
    invoke DeleteObject,hBrush
    invoke PostQuitMessage,0 
     
.ELSEIF uMsg==WM_CREATE

    invoke MessageBox, hWnd, addr pomoc, addr tekst, MB_OK or MB_ICONINFORMATION
    invoke	CreateSolidBrush, kolor_tla
    mov	hBrush,eax
    invoke	CreatePen,PS_SOLID,10, kolor_siatki
    mov	hSPen,eax
    invoke	CreatePen,PS_SOLID,10, kolor_kolka
    mov	hKOPen,eax
    invoke	CreatePen,PS_SOLID,10, kolor_krzyzyka
    mov	hKRZPen,eax
    invoke	CreatePen,PS_SOLID,10, kolor_przekreslenia
    mov	hPrzPen,eax
    	 
.ELSEIF uMsg==WM_PAINT

    ;przygotowanie do rysowania
    invoke	BeginPaint,hWnd,addr ps
    mov hdc, eax
    invoke	SelectObject,hdc,hBrush
    push eax
    invoke	SelectObject,hdc,hSPen
    push eax 

    ;rysuje siatke
    invoke MoveToEx,hdc,105,0,0
    invoke LineTo,hdc,105,345
    invoke MoveToEx, hdc, 215, 0, 0
    invoke LineTo, hdc, 215, 345
    invoke MoveToEx, hdc, 0, 105, 0
    invoke LineTo, hdc, 325, 105
    invoke MoveToEx, hdc, 0, 215, 0
    invoke LineTo, hdc, 325, 215

    ;sekcja ta rysuje X albo O na podstawie w. klawisza
    xor esi, esi
    mov esi, offset tablica
    
    mov edx, [esi+32] 
    .IF edx==79
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKOPen
        push eax
        invoke Ellipse, hdc, 230, 10, 310, 90
    .ELSEIF edx==88
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKRZPen
        push eax
        invoke MoveToEx, hdc, 230, 10, 0
        invoke LineTo, hdc, 310, 90
        invoke MoveToEx, hdc, 230, 90, 0
        invoke LineTo, hdc, 310, 10
    .ELSE
        nop
    .ENDIF

    mov edx, [esi+28]
    .IF edx==79
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKOPen
        push eax
        invoke Ellipse, hdc, 120, 10, 200, 90
    .ELSEIF edx==88
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKRZPen
        push eax
        invoke MoveToEx, hdc, 120, 10, 0
        invoke LineTo, hdc, 200, 90
        invoke MoveToEx, hdc, 120, 90, 0
        invoke LineTo, hdc, 200, 10
    .ELSE
        nop
    .ENDIF

    mov edx, [esi+24]
    .IF edx==79
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKOPen
        push eax
        invoke Ellipse, hdc, 10, 10, 90, 90
    .ELSEIF edx==88
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKRZPen
        push eax
        invoke MoveToEx, hdc, 10, 10, 0
        invoke LineTo, hdc, 90, 90
        invoke MoveToEx, hdc, 10, 90, 0
        invoke LineTo, hdc, 90, 10
    .ELSE
        nop
    .ENDIF

    mov edx, [esi+20]
    .IF edx==79
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKOPen
        push eax
        invoke Ellipse, hdc, 230, 120, 310, 200
    .ELSEIF edx==88
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKRZPen
        push eax
        invoke MoveToEx, hdc, 230, 120, 0
        invoke LineTo, hdc, 310, 200
        invoke MoveToEx, hdc, 230, 200, 0
        invoke LineTo, hdc, 310, 120
    .ELSE
        nop
    .ENDIF

    mov edx, [esi+16]
    .IF edx==79
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKOPen
        push eax
        invoke Ellipse, hdc, 120, 120, 200, 200
    .ELSEIF edx==88
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKRZPen
        push eax
        invoke MoveToEx, hdc, 120, 120, 0
        invoke LineTo, hdc, 200, 200
        invoke MoveToEx, hdc, 120, 200, 0
        invoke LineTo, hdc, 200, 120
    .ELSE
        nop
    .ENDIF

    mov edx, [esi+12]
    .IF edx==79
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKOPen
        push eax
        invoke Ellipse, hdc, 10, 120, 90, 200
    .ELSEIF edx==88
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKRZPen
        push eax
        invoke MoveToEx, hdc, 10, 120, 0
        invoke LineTo, hdc, 90, 200
        invoke MoveToEx, hdc, 10, 200, 0
        invoke LineTo, hdc, 90, 120
    .ELSE
        nop
    .ENDIF

    mov edx, [esi+8]
    .IF edx==79
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKOPen
        push eax
        invoke Ellipse, hdc, 230, 230, 310, 310
    .ELSEIF edx==88
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKRZPen
        push eax
        invoke MoveToEx, hdc, 230, 230, 0
        invoke LineTo, hdc, 310, 310
        invoke MoveToEx, hdc, 230, 310, 0
        invoke LineTo, hdc, 310, 230
    .ELSE
        nop
    .ENDIF

    mov edx, [esi+4]
    .IF edx==79
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKOPen
        push eax
        invoke Ellipse, hdc, 120, 230, 200, 310
    .ELSEIF edx==88
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKRZPen
        push eax
        invoke MoveToEx, hdc, 120, 230, 0
        invoke LineTo, hdc, 200, 310
        invoke MoveToEx, hdc, 120, 310, 0
        invoke LineTo, hdc, 200, 230
    .ELSE
        nop
    .ENDIF

    mov edx, [esi]
    .IF edx==79
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKOPen
        push eax
        invoke Ellipse, hdc, 10, 230, 90, 310
    .ELSEIF edx==88
        invoke	SelectObject,hdc,hBrush
        push eax
        invoke	SelectObject,hdc,hKRZPen
        push eax
        invoke MoveToEx, hdc, 10, 230, 0
        invoke LineTo, hdc, 90, 310
        invoke MoveToEx, hdc, 10, 310, 0
        invoke LineTo, hdc, 90, 230
    .ELSE
        nop
    .ENDIF
    ;koniec sekcji rysujacej X albo O na podstawie w. klawisza


    ;w tej sekcji sprawdzamy czy ktos wygral
    invoke	SelectObject,hdc,hBrush
    push eax
    invoke	SelectObject,hdc,hPrzPen
    push eax
    
    mov ebx, [esi]
    mov ecx, [esi+12]
    mov edx, [esi+24]
    .IF ebx==ecx && ecx==edx && edx==79
        invoke MoveToEx,hdc,50,0,0
        invoke LineTo,hdc,50,345
        invoke MessageBox, hWnd, addr wO, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov ebx, [esi+4]
    mov ecx, [esi+16]
    mov edx, [esi+28]
    .IF ebx==ecx && ecx==edx && edx==79
        invoke MoveToEx,hdc,160,0,0
        invoke LineTo,hdc,160,345
        invoke MessageBox, hWnd, addr wO, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov ebx, [esi+8]
    mov ecx, [esi+20]
    mov edx, [esi+32]
    .IF ebx==ecx && ecx==edx && edx==79
        invoke MoveToEx,hdc,270,0,0
        invoke LineTo,hdc,270,345
        invoke MessageBox, hWnd, addr wO, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov ebx, [esi+24]
    mov ecx, [esi+28]
    mov edx, [esi+32]
    .IF ebx==ecx && ecx==edx && edx==79
        invoke MoveToEx,hdc,0,50,0
        invoke LineTo,hdc,325,50
        invoke MessageBox, hWnd, addr wO, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov ebx, [esi+12]
    mov ecx, [esi+16]
    mov edx, [esi+20]
    .IF ebx==ecx && ecx==edx && edx==79
        invoke MoveToEx,hdc,0,160,0
        invoke LineTo,hdc,325,160
        invoke MessageBox, hWnd, addr wO, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov ebx, [esi]
    mov ecx, [esi+4]
    mov edx, [esi+8]
    .IF ebx==ecx && ecx==edx && edx==79
        invoke MoveToEx,hdc,0,270,0
        invoke LineTo,hdc,325,270
        invoke MessageBox, hWnd, addr wO, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov ebx, [esi]
    mov ecx, [esi+16]
    mov edx, [esi+32]
    .IF ebx==ecx && ecx==edx && edx==79                                
        invoke MoveToEx,hdc,320,0,0
        invoke LineTo,hdc,0,320
        invoke MessageBox, hWnd, addr wO, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov ebx, [esi+24]
    mov ecx, [esi+16]
    mov edx, [esi+8]
    .IF ebx==ecx && ecx==edx && edx==79                                  
        invoke MoveToEx,hdc,0,0,0
        invoke LineTo,hdc,320,320
        invoke MessageBox, hWnd, addr wO, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov ebx, [esi]
    mov ecx, [esi+12]
    mov edx, [esi+24]
    .IF ebx==ecx && ecx==edx && edx==88                                       
        invoke MoveToEx,hdc,50,0,0
        invoke LineTo,hdc,50,345
        invoke MessageBox, hWnd, addr wX, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov ebx, [esi+4]
    mov ecx, [esi+16]
    mov edx, [esi+28]
    .IF ebx==ecx && ecx==edx && edx==88
        invoke MoveToEx,hdc,160,0,0
        invoke LineTo,hdc,160,345
        invoke MessageBox, hWnd, addr wX, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov ebx, [esi+8]
    mov ecx, [esi+20]
    mov edx, [esi+32]
    .IF ebx==ecx && ecx==edx && edx==88
        invoke MoveToEx,hdc,270,0,0
        invoke LineTo,hdc,270,345
        invoke MessageBox, hWnd, addr wX, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov ebx, [esi+24]
    mov ecx, [esi+28]
    mov edx, [esi+32]
    .IF ebx==ecx && ecx==edx && edx==88
        invoke MoveToEx,hdc,0,50,0
        invoke LineTo,hdc,325,50
        invoke MessageBox, hWnd, addr wX, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov ebx, [esi+12]
    mov ecx, [esi+16]
    mov edx, [esi+20]
    .IF ebx==ecx && ecx==edx && edx==88
        invoke MoveToEx,hdc,0,160,0
        invoke LineTo,hdc,325,160
        invoke MessageBox, hWnd, addr wX, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov ebx, [esi]
    mov ecx, [esi+4]
    mov edx, [esi+8]
    .IF ebx==ecx && ecx==edx && edx==88
        invoke MoveToEx,hdc,0,270,0
        invoke LineTo,hdc,325,270
        invoke MessageBox, hWnd, addr wX, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov ebx, [esi]
    mov ecx, [esi+16]
    mov edx, [esi+32]
    .IF ebx==ecx && ecx==edx && edx==88
        invoke MoveToEx,hdc,320,0,0
        invoke LineTo,hdc,0,320
        invoke MessageBox, hWnd, addr wX, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov ebx, [esi+24]
    mov ecx, [esi+16]
    mov edx, [esi+8]
    .IF ebx==ecx && ecx==edx && edx==88
        invoke MoveToEx,hdc,0,0,0
        invoke LineTo,hdc,320,320
        invoke MessageBox, hWnd, addr wX, addr w, MB_OK or MB_ICONINFORMATION
        jmp reset
    .ENDIF

    mov licznik_remisu, 0
    mov esi, offset tablica
    mov ecx, 9
    spr_czy_remis:
        mov eax, [esi]
        .IF eax == 88 || eax == 79
            add licznik_remisu, 1
        .ENDIF
        add esi, 4
    loop spr_czy_remis
    .IF licznik_remisu==9
        invoke MessageBox, hWnd, addr remis, addr remis, MB_OK
        jmp reset
    .ENDIF
          
    ;koniec sekcji sprawdzajacej czy ktos wygral

    pop eax        
    invoke	SelectObject,hdc,eax
    pop eax
    invoke	SelectObject,hdc,eax
    invoke	EndPaint,hWnd,addr ps

;obsluga klawiszy 
.ELSEIF uMsg==WM_CHAR 

    push wParam 
    pop  char
    
    .IF char==57
        mov esi, offset tablica
        mov ebx, [esi+32]
        .IF ebx==88 || ebx==79
            jmp niedozwolony_wybor
        .ENDIF
        .IF ostatni_znak==88
            mov ebx, 79
            mov [esi+32], ebx
            mov ebx, 79
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ELSE
            mov ebx, 88
            mov [esi+32], ebx
            mov ebx, 88
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ENDIF

    .ELSEIF char==56
        mov esi, offset tablica
        mov ebx, [esi+28]
        .IF ebx==88 || ebx==79
            jmp niedozwolony_wybor
        .ENDIF
        .IF ostatni_znak==88
            mov ebx, 79
            mov [esi+28], ebx
            mov ebx, 79
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ELSE
            mov ebx, 88
            mov [esi+28], ebx
            mov ebx, 88
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ENDIF

    .ELSEIF char==55
        mov esi, offset tablica
        mov ebx, [esi+24]
        .IF ebx==88 || ebx==79
            jmp niedozwolony_wybor
        .ENDIF
        .IF ostatni_znak==88
            mov ebx, 79
            mov [esi+24], ebx
            mov ebx, 79
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ELSE
            mov ebx, 88
            mov [esi+24], ebx
            mov ebx, 88
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ENDIF

    .ELSEIF char==54
        mov esi, offset tablica
        mov ebx, [esi+20]
        .IF ebx==88 || ebx==79
            jmp niedozwolony_wybor
        .ENDIF
        .IF ostatni_znak==88
            mov ebx, 79
            mov [esi+20], ebx
            mov ebx, 79
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ELSE
            mov ebx, 88
            mov [esi+20], ebx
            mov ebx, 88
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ENDIF

    .ELSEIF char==53
        mov esi, offset tablica
        mov ebx, [esi+16]
        .IF ebx==88 || ebx==79
            jmp niedozwolony_wybor
        .ENDIF
        .IF ostatni_znak==88
            mov ebx, 79
            mov [esi+16], ebx
            mov ebx, 79
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ELSE
            mov ebx, 88
            mov [esi+16], ebx
            mov ebx, 88
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ENDIF

    .ELSEIF char==52
        mov esi, offset tablica
        mov ebx, [esi+12]
        .IF ebx==88 || ebx==79
            jmp niedozwolony_wybor
        .ENDIF
        .IF ostatni_znak==88
            mov ebx, 79
            mov [esi+12], ebx
            mov ebx, 79
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ELSE
            mov ebx, 88
            mov [esi+12], ebx
            mov ebx, 88
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ENDIF

    .ELSEIF char==51
        mov esi, offset tablica
        mov ebx, [esi+8]
        .IF ebx==88 || ebx==79
            jmp niedozwolony_wybor
        .ENDIF
        .IF ostatni_znak==88
            mov ebx, 79
            mov [esi+8], ebx
            mov ebx, 79
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ELSE
            mov ebx, 88
            mov [esi+8], ebx
            mov ebx, 88
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ENDIF

    .ELSEIF char==50
        mov esi, offset tablica
        mov ebx, [esi+4]
        .IF ebx==88 || ebx==79
            jmp niedozwolony_wybor
        .ENDIF
        .IF ostatni_znak==88
            mov ebx, 79
            mov [esi+4], ebx
            mov ebx, 79
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ELSE
            mov ebx, 88
            mov [esi+4], ebx
            mov ebx, 88
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ENDIF

    .ELSEIF char==49
        mov esi, offset tablica
        mov ebx, [esi]
        .IF ebx==88 || ebx==79
            jmp niedozwolony_wybor
        .ENDIF
        .IF ostatni_znak==88
            mov ebx, 79
            mov [esi], ebx
            mov ebx, 79
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ELSE
            mov ebx, 88
            mov [esi], ebx
            mov ebx, 88
            mov ostatni_znak, ebx
            invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
        .ENDIF

    .ELSEIF char==27

        invoke DeleteObject,hKOPen
        invoke DeleteObject,hKRZPen
        invoke DeleteObject,hSPen
        invoke DeleteObject,hBrush
        invoke PostQuitMessage,0
        
    .ELSEIF char==82 || char==114

        reset:
        invoke MessageBox, hWnd, addr restart, addr uwaga, MB_OK or MB_ICONINFORMATION
        mov esi, offset tablica
        mov ecx, 9
        mov ebx, 32
        zerowanie:
        mov [esi], ebx
        add esi, 4
        loop zerowanie
        invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE

    .ELSEIF char==80 || char==112
    
        invoke MessageBox, hWnd, addr pomoc, addr pom, MB_OK
       
    .ELSE

        niedozwolony_wybor:
        invoke MessageBox, hWnd, addr zly_klawisz, addr er, MB_OK or MB_ICONINFORMATION

    .ENDIF
    ;koniec obslugi klawiszy

.ELSEIF uMsg==WM_LBUTTONDOWN 

        ;obsluga myszy moze zawierac bledy we wspolrzednych
        ;bity 0-15 > X bity 16-31 > Y
        mov eax, lParam 
        and eax, 0FFFFh 
        mov wspolrzedne.x, eax 
        mov eax, lParam 
        shr eax, 16 
        mov wspolrzedne.y, eax

        .IF wspolrzedne.x<=325 &&  wspolrzedne.x>=220 && wspolrzedne.y<=100
            mov esi, offset tablica
            mov ebx, [esi+32]
            .IF ebx==88 || ebx==79
                jmp niedozwolony_wybor
            .ENDIF
            .IF ostatni_znak==88
                mov ebx, 79
                mov [esi+32], ebx
                mov ebx, 79
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ELSE
                mov ebx, 88
                mov [esi+32], ebx
                mov ebx, 88
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ENDIF
        
        .ELSEIF wspolrzedne.x>=110 && wspolrzedne.x<=210 && wspolrzedne.y<=100
            mov esi, offset tablica
            mov ebx, [esi+28]
            .IF ebx==88 || ebx==79
                jmp niedozwolony_wybor
            .ENDIF
            .IF ostatni_znak==88
                mov ebx, 79
                mov [esi+28], ebx
                mov ebx, 79
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ELSE
                mov ebx, 88
                mov [esi+28], ebx
                mov ebx, 88
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ENDIF
              
        .ELSEIF wspolrzedne.x<=100 && wspolrzedne.y<=100
            mov esi, offset tablica
            mov ebx, [esi+24]
            .IF ebx==88 || ebx==79
                jmp niedozwolony_wybor
            .ENDIF
            .IF ostatni_znak==88
                mov ebx, 79
                mov [esi+24], ebx
                mov ebx, 79
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ELSE
                mov ebx, 88
                mov [esi+24], ebx
                mov ebx, 88
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ENDIF

        .ELSEIF wspolrzedne.x<=325 && wspolrzedne.x>=220 && wspolrzedne.y>=110 && wspolrzedne.y<=210
            mov esi, offset tablica
            mov ebx, [esi+20]
            .IF ebx==88 || ebx==79
                jmp niedozwolony_wybor
            .ENDIF
            .IF ostatni_znak==88
                mov ebx, 79
                mov [esi+20], ebx
                mov ebx, 79
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ELSE
                mov ebx, 88
                mov [esi+20], ebx
                mov ebx, 88
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ENDIF

        .ELSEIF wspolrzedne.x>=110 && wspolrzedne.x<=220 && wspolrzedne.y>=110 && wspolrzedne.y<=210
            mov esi, offset tablica
            mov ebx, [esi+16]
            .IF ebx==88 || ebx==79
                jmp niedozwolony_wybor
            .ENDIF
            .IF ostatni_znak==88
                mov ebx, 79
                mov [esi+16], ebx
                mov ebx, 79
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ELSE
                mov ebx, 88
                mov [esi+16], ebx
                mov ebx, 88
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ENDIF

        .ELSEIF wspolrzedne.x<=110 && wspolrzedne.y>=110 && wspolrzedne.y<=210
            mov esi, offset tablica
            mov ebx, [esi+12]
            .IF ebx==88 || ebx==79
                jmp niedozwolony_wybor
            .ENDIF
            .IF ostatni_znak==88
                mov ebx, 79
                mov [esi+12], ebx
                mov ebx, 79
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ELSE
                mov ebx, 88
                mov [esi+12], ebx
                mov ebx, 88
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ENDIF

        .ELSEIF wspolrzedne.x<=325 && wspolrzedne.x>=220 && wspolrzedne.y>=220
            mov esi, offset tablica
            mov ebx, [esi+8]
            .IF ebx==88 || ebx==79
                jmp niedozwolony_wybor
            .ENDIF
            .IF ostatni_znak==88
                mov ebx, 79
                mov [esi+8], ebx
                mov ebx, 79
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ELSE
                mov ebx, 88
                mov [esi+8], ebx
                mov ebx, 88
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ENDIF

        .ELSEIF wspolrzedne.x>=110 && wspolrzedne.x<=220 && wspolrzedne.y>=220
            mov esi, offset tablica
            mov ebx, [esi+4]
            .IF ebx==88 || ebx==79
                jmp niedozwolony_wybor
            .ENDIF
            .IF ostatni_znak==88
                mov ebx, 79
                mov [esi+4], ebx
                mov ebx, 79
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ELSE
                mov ebx, 88
                mov [esi+4], ebx
                mov ebx, 88
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ENDIF

        .ELSEIF wspolrzedne.x<=110 && wspolrzedne.y>=220
            mov esi, offset tablica
            mov ebx, [esi]
            .IF ebx==88 || ebx==79
                jmp niedozwolony_wybor
            .ENDIF
            .IF ostatni_znak==88
                mov ebx, 79
                mov [esi], ebx
                mov ebx, 79
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ELSE
                mov ebx, 88
                mov [esi], ebx
                mov ebx, 88
                mov ostatni_znak, ebx
                invoke RedrawWindow, hWnd, NULL, NULL, RDW_UPDATENOW + RDW_INVALIDATE + RDW_ALLCHILDREN + RDW_ERASE
            .ENDIF

        .ENDIF  
                           
.ELSE

    invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
    
.ENDIF

xor eax, eax
ret

WndProc endp

end start                                                                    


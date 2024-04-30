unit KbdDefs;

interface



const
    WH_KEYBOARD_LL = 13;
    KbdWindowClass = 'uid_KbdWClass001';
     SCANQUERY = $000100; // Формирование запроса поиска
    SIEVEQUERY = $000200;
    kbbuff_len = 256;
     KF_SHIFT  = $01;
     KF_ALT    = $02;
     KF_CTRL   = $04;
     // Mouse Buttons
     KF_LBTN   = $08;
     KF_RBTN   = $10;
     KF_MBTN   = $20;
     KF_DBLC   = $40;
     // Extended Keyboard flags
     KF_WIN    = $80;
     KF_APPS   = $100;
     KF_RKEY   = $200; // w SHIFT, ALT, CTRL is defined right button
     KF_KEYUP  = $4000; // key now released
     KF_PRESS  = $8000; // key now pressed;
   KF_ALTDOWN  = $2000;
    KF_REPEAT  = $4000;
        KF_UP  = $8000;
        
 LLKHF_ALTDOWN = KF_ALTDOWN shl 8;
      LLKHF_UP = KF_UP shr 8;
implementation

end.
 
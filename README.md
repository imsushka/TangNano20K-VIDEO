Test system
-------------------------------------------------------------------
Z80 + AY8910x2 + SDcard + USART (115200bod) + 8MB sdram + VIDEO
IO ports:
AY8910 - 0xCA (1) / 0xCC (2) ( 0xCB/0xCD - reg addr / 0xCA/0xCC - data )
SDcard - 0xE8 ( bit access )
USART - 0xCE ( 0xCE - data / 0xCF - status )
VGA - 0xF0 ()
Mapper - 0xF8 ()

ROM - based on retromon.asm v1.8 - a monitor for the Z80-Retro! SBC	Kenny Maytum - KRSynthWorx - April 25th, 2023

NASCOM ROM BASIC Ver 4.7, (C) 1978 Microsoft

GAMES
----------------------------------------------------------------------
Ladder
RISE OUT
XONIX
2048 (console)
VGMPLAY
Music from Vampir Killer MSX (on keybord 1-0)
--------------------------------------------------------------------------------------------**
Tiled video controller for older processors such as Z80, 6502, 8086.

The screen resolution is set to 1024 x 768.

The screen turns out to be 128 x 96 spaces, with a font size of 8 x 8.
You can also choose fonts 8 x 16, 16 x 16, 16 x 32 and 32 x 32.
Accordingly, we get 128 x 48, 64 x 48, 64 x 24 and 32 x 24 acquaintances.

For each familiarity, the background color and symbol color are set. 16 colors. Same as CGA 80 x 25.
You can also enable line-by-line coloring for 8 x 8 and 8 x 16 modes.

For all modes.
You can also enable the mode 4 colors per point, out of 256 palettes.
And the mode is 16 colors per dot.

3 experimental graphics modes.
1024 x 768 mono, 512 x 384 - 4 colors and 256 x 192 - 16 colors.

--------------------------------------------------------------------------------------------------------

Тайловый видео контроллер для старых процессоров, таких как Z80, 6502, 8086. 

Разрешение экрана установленно 1024 x 768. 
Экран получается 128 x 96 знакомест,  при размере фонта 8 x 8.
Так же можно выбрать фонты 8 x 16, 16 x 16, 16 x 32 и 32 x 32.
Соответсвенно получается 128 x 48, 64 x 48, 64 x 24 и 32 x 24 знакоместа.

Для каждого знакоместа устанавливается цвет фона и цвет символа. 16 цветов. Как в CGA 80 x 25.
Так же для режимов 8 x 8 и 8 x 16 можно включить построчную раскраску.

Для всех режимов.
Так же можно включить режим 4 цвета на точку, из 256 палитр.
И режим 16 цветов на точку.

3 экперементальные графических режима.
1024 x 768 моно, 512 x 384 4 цвета и 256 x 192 16 цветов.

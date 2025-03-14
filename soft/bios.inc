iobyte		= 03h		; Intel standard I/O definition byte.
userdrv		= 04h		; Current user number and drive.
tpabuf		= 80h		; Default I/O buffer and command line storage.

mnttab	= BIOS_VAR

; disk actions only take place with current values
curvol	= BIOS_VAR + 3	; current volume
curtrk	= BIOS_VAR + 4	; current track
curhsec	= BIOS_VAR + 6	; current host sector
sector	= BIOS_VAR + 7	; current sector
; requested values for next disk action
reqvol	= BIOS_VAR + 9	; requested volume
reqtrk	= BIOS_VAR + 10	; requested track
reqhsec	= BIOS_VAR + 12	; requested host sector

xferCnt	= BIOS_VAR + 13	; number of sectors to transfer
xferAdr	= BIOS_VAR + 14	; disk read/write buffer
dmaAddr	= BIOS_VAR + 16	; last dma Address

dirty	= BIOS_VAR + 18	; flag to indicate mem/buff not synched
; current LBA
LBA0	= BIOS_VAR + 19
LBA1	= BIOS_VAR + 20
LBA2	= BIOS_VAR + 21
LBA3	= BIOS_VAR + 22

dirbuf	= BIOS_BUFFER		; scratch directory area
hstbuf	= BIOS_BUFFER + 128	; 512 bytes transfer buffer
alv00	= BIOS_BUFFER + 768	; allocation vectors 0 for 8 MB bootdisk A:
alv01	= BIOS_BUFFER + 1024	; allocation vectors 1 disk B:
alv02	= BIOS_BUFFER + 1280	; allocation vectors 2 disk C:
alv03	= BIOS_BUFFER + 1536	; allocation vectors ramdisk M:

; Simple Filetable
db "{"  ; Start
db "kernel.bin:03,"
db "calc:05,"
db "coolThing:07"
db "}"  ; End

times 512-($-$$) db 0

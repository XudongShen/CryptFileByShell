code segment
assume cs:code, ds:code
main:
   push es
   call next
next:
   pop bx; BX=next的运行时的实际偏移地址
   sub bx, offset next; bx=main在运行时的实际偏移地址
   mov si, 0
   mov di, si
   mov cx, bx
   push cs
   pop ds
   push cs
   pop es
decode:
   lodsb
   xor al, 44h
   stosb
   loop decode
   mov ax, [bx+head+4]; 获取载入内存的扇区数
   dec ax             ; 先扣去最后一个扇区
   mov dx, [bx+head+8]; 获取文件头的节数
   mov cl, 5
   shl ax, cl         ; 内存扇区数*0x20来转变为节数
   sub ax, dx         ; 获取待解密的节数
   mov cl, 4
   mov dx, [bx+head+2]; 获取最后扇区字节
   sub dx, 0 
   jnz add_tail       ; 判断最后扇区字节是否为0
   add ax, 20h        ; 如果是零则节数+20,也就是一个扇区
add_tail:
   shr dx, cl         ; 将最后扇区字节转变为节数并加上
   add ax, dx
   mov dx, bx
   mov cl, 4
   shr dx, cl         
   sub ax, dx         ; 计算尚未解密的节数
   mov cx, ax
   jcxz lable
decode_seg:
   mov ax, ds         ; 当前数据段
   dec ax             ; 降一段
   mov ds, ax
   mov es, ax
   mov si, 0
   mov di, si
   push cx            ; 保存计数器
   mov cx, 10h    
dede:                 ; 解密当前段的前10h个字节
   lodsb
   xor al, 44h
   stosb
   loop dede
   pop cx             ; 读取之前保存的计数器
   loop decode_seg
lable:
   push cs
   pop ds
   mov cx, [bx+head+6] 
   sub cx, 0
   jnz needre         ; 判断是否有重定向
   mov bp, es
   jmp return
needre:
   mov si, [bx+head+18h]; SI=1Eh
   lea si, [bx+head+si]; 找重定向表
relocate:
   mov di, [si]
   mov dx, [si+2]
   push es
   mov bp, es
   add dx, bp
   mov es, dx
   add es:[di], bp; 完成一项定位
   pop es
   add si, 4
   loop relocate
return:
   mov cx, [bx+head+16h]; 找原main入口
   mov ax, bp           ; 加上基段，也就是之前计算的载入首段
   add ax, cx
   pop es
   push ax
   mov ax, [bx+head+14h]; 
   push ax
   retf
head label word
code ends
end main
code segment
assume cs:code, ds:code
main:
   push es
   call next
next:
   pop bx; BX=next������ʱ��ʵ��ƫ�Ƶ�ַ
   sub bx, offset next; bx=main������ʱ��ʵ��ƫ�Ƶ�ַ
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
   mov ax, [bx+head+4]; ��ȡ�����ڴ��������
   dec ax             ; �ȿ�ȥ���һ������
   mov dx, [bx+head+8]; ��ȡ�ļ�ͷ�Ľ���
   mov cl, 5
   shl ax, cl         ; �ڴ�������*0x20��ת��Ϊ����
   sub ax, dx         ; ��ȡ�����ܵĽ���
   mov cl, 4
   mov dx, [bx+head+2]; ��ȡ��������ֽ�
   sub dx, 0 
   jnz add_tail       ; �ж���������ֽ��Ƿ�Ϊ0
   add ax, 20h        ; ������������+20,Ҳ����һ������
add_tail:
   shr dx, cl         ; ����������ֽ�ת��Ϊ����������
   add ax, dx
   mov dx, bx
   mov cl, 4
   shr dx, cl         
   sub ax, dx         ; ������δ���ܵĽ���
   mov cx, ax
   jcxz lable
decode_seg:
   mov ax, ds         ; ��ǰ���ݶ�
   dec ax             ; ��һ��
   mov ds, ax
   mov es, ax
   mov si, 0
   mov di, si
   push cx            ; ���������
   mov cx, 10h    
dede:                 ; ���ܵ�ǰ�ε�ǰ10h���ֽ�
   lodsb
   xor al, 44h
   stosb
   loop dede
   pop cx             ; ��ȡ֮ǰ����ļ�����
   loop decode_seg
lable:
   push cs
   pop ds
   mov cx, [bx+head+6] 
   sub cx, 0
   jnz needre         ; �ж��Ƿ����ض���
   mov bp, es
   jmp return
needre:
   mov si, [bx+head+18h]; SI=1Eh
   lea si, [bx+head+si]; ���ض����
relocate:
   mov di, [si]
   mov dx, [si+2]
   push es
   mov bp, es
   add dx, bp
   mov es, dx
   add es:[di], bp; ���һ�λ
   pop es
   add si, 4
   loop relocate
return:
   mov cx, [bx+head+16h]; ��ԭmain���
   mov ax, bp           ; ���ϻ��Σ�Ҳ����֮ǰ����������׶�
   add ax, cx
   pop es
   push ax
   mov ax, [bx+head+14h]; 
   push ax
   retf
head label word
code ends
end main
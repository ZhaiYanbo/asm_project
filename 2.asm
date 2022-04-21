;程序功能：实现四则运算器
;基本思想:中缀转后缀
;实验人:8207200203 计科2006班 翟衍博
;完成时间:2022.4.17
dataseg segment
    expression db   50,?,40 dup(0),'$'   ;表达式数组
    message    db   'Please Input Expression:','$'   ;输入提示
    message2   db   'The Answer is: ','$'  ;输出提示
    mode_note  db   'Continue?: [0]Continue [1]Exit:', '$'
    mode_err   db   'Mode Error,please input again!','$'
    div_err    db   'Expression error(divide 0)','$'
    crlf       db   0ah,0dh,'$'
    token      db   ?     ;token存放每一个标号
    arg        db   ?     ;arg为运算符  
    result     dw   ?     ;结果
    nozero     db   0     ;十进制输出辅助
dataseg ends 
  
codeseg segment
    assume cs:codeseg, ds:dataseg

;表达式处理函数
;参数传递：al为待处理表达式的起始地址,结果放入dx中
exp proc near
    local temp:WORD ;定义局部变量
    call term 
    mov temp,dx
while1: 
    cmp al,'+'
    je add_ 
    cmp al,'-'
    je sub_ 
     
    jmp end1 
add_: 
    mov cl,'+'
    mov [arg],cl
    call match 
    call term 
    add temp,dx
    jmp while1 
sub_: 
    mov cl,'-'
    mov [arg],cl
    call match 
    call term 
    sub temp,dx
    jmp while1 
end1: 
    mov dx,temp 
    ret
exp endp

;处理乘除法
term proc near
    local temp:WORD ;定义局部变量
    call factor 
    mov temp,dx
while2: 
    cmp al,'*'
    je mul_ 
    cmp al,'/'
    je div_ 
    jmp end_ 
mul_: 
    mov cl,'*'
    mov [arg],cl
    call match 
    call factor 
    mov cx,ax
    mov ax,temp 
    mul dx
    mov [temp],ax
    mov ax,cx
    jmp while2
div_: 
    mov cl,'/'
    mov [arg],cl
    call match 
    call factor 
    mov cx,ax
    mov ax,temp 
    cmp dl,0
    je div0
    div dl
    xor ah,ah
    mov [temp],ax
    mov ax,cx
    jmp while2
div0:
    lea dx,div_err
    mov ah,09H
    int 21H
    lea dx,crlf
    mov ah,09H
    int 21H
    jmp ed
end_: 
    mov dx,temp 
    ret
term endp

;读数字
factor proc near
    local temp:WORD ;定义局部变量

    cmp al,'('
    je lef 
    xor cx,cx
    mov cl,al
    xor ax,ax
;当从左边处理到的不是"("而是数字时，
while3:     
    sub cl,'0'  
    mov BL,10 
    imul BL
    add ax,cx
    mov cl,[si] 
    inc si
    cmp cl,'0'
    jb end3 
    cmp cl,'9'
    ja end3 
    jmp while3 
;是左括号就继续读入
lef: 
    mov cl,'('
    mov [arg],cl
    call match 
    call exp 
    mov temp,dx
    mov cl,')'
    mov [arg],cl
    call match 
    jmp endx 
end3: 
    mov dx,ax
    dec si
    mov al,[si] 
    inc si
    ret
endx: 
    mov dx,temp 
    ret
factor endp

;匹配
match proc near
    cmp al,arg
    je true 
true: 
    mov al,[si] 
    inc si
    ret
match endp

;十进制输出子程序
outputdec proc near
  push cx
  mov nozero,0
  mov cx,10000
  call oput
  mov cx,1000
  call oput
  mov cx,100
  call oput
  mov cx,10
  call oput
  mov cx,1
  call oput
  cmp nozero,0
  jne ll
  mov dl,30h
  mov ah,02H
  int 21H
  ll:
  pop cx
  ret

  oput proc near
   mov ax,bx
   mov dx,0
   div cx
   ;商在ax中，余数在dx中
   mov bx,dx
   mov dl,al
   cmp dl,0
   jne ll1  ;余数不为0就继续运算
   cmp nozero,0
   jne ll1
   jmp ll2
   ll1:
   mov nozero,1
   add dl,30h   ;数字转成ascii码
   mov ah,02H
   int 21H
   ll2:
   ret
 oput endp
outputdec endp

;主函数
main proc far
start: 
    mov ax,dataseg 
    mov ds,ax
again:
;输出提示信息   
    lea dx,message
    mov ah,09h
    int 21h
    lea dx,crlf
    mov ah,09h
    int 21h    
;输入算数表达式    
    lea dx,expression
    mov ah,0ah 
    int 21h
    lea dx,crlf
    mov ah,09H
    int 21H
;表达式解析     
    lea si,expression
    add si,2    ;加2开始处理
    mov al,[si]
    inc si
    mov [token],al
    call exp    ;计算表达式的值
    mov [result],dx
;输出提示及结果输出 
    lea dx,message2
    mov ah,09H
    int 21H
    mov bx,result
    call outputdec
    lea dx,crlf
    mov ah,09h
    int 21H
;是否继续
con:
    lea dx,mode_note
    mov ah,09H
    int 21h
    mov ah,01H
    int 21h
    lea dx,crlf
    mov ah,09H
    int 21H
    sub al,30h
    cmp al,0
    je again
    cmp al,1
    je ed
md_rrr:
    lea dx,mode_err
    mov ah,09h
    int 21h
    lea dx,crlf
    mov ah,09h
    int 21H
    jmp con
ed:
;返回DOS     
    mov ah, 4ch 
    int 21h
main endp
codeseg ends 
end start

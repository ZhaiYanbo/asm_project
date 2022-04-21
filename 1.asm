;程序功能：对文本文件实现加密解密功能
;加密解密算法：逐个对字符对应的ascii码进行异或操作，再次异或即可解密
;实验准备：将本地的"D:\test"路径挂载到dosbox的"e:\"
;实验人:8207200203 计科2006班 翟衍博
;完成时间:2022.4.14
dataseg SEGMENT

    in_note     db 'Please enter the input file path: ', '$'
    out_note    db 'Please enter the output file path: ', '$'
    mode_note   db 'Choose work mode: [0]Encode [1]Decode', '$'
    mode_err    db 'Invalid mode', '$'
    open_err    db 'Open file error', '$'
    close_err   db 'Close file error', '$'
    read_err    db 'Read file error', '$'
    write_err   db 'Write file error', '$'
    CRLF        db 0AH, 0DH, '$'
    mode        dw ?
    in_file     dw ?
    out_file    dw ?
    uri         db 100, ?, 100 dup(?)
    in_buf      db 100 dup(?)
    out_buf     db 100 dup(?)
    in_len      dw 0
    out_len     dw 0
    psw         dw ?

dataseg ENDS

stackseg SEGMENT stack
    dw 256 dup(?)
stackseg ENDS

codeseg SEGMENT

    ASSUME ds:dataseg, ss:stackseg, cs:codeseg
;创建文件
create PROC NEAR
    PUSH ax
    PUSH cx
    PUSH dx
    MOV ah, 3CH
    LEA dx, uri
    ADD dx, 2
    MOV cx, 0
    INT 21H
    JC  fail7
    MOV bx, ax
    JMP end7
fail7:
    MOV bx, 1
    LEA dx, open_err
    MOV ah, 09H
    INT 21H
end7:
    POP dx
    POP cx
    POP ax
    RET
create ENDP

;打开文件
open PROC NEAR
    PUSH ax
    PUSH dx

    MOV ah, 3DH
    LEA dx, uri
    ADD dx, 2   ;+2,空出字符串的前两个单元
                ;这两个单元分别存放的最大存放个数和实际存放个数
    MOV al, 02H ;2表示读/写
    INT 21H
    JC  fail3
    MOV bx, ax
    JMP end3
fail3:
    MOV bx, 1
    LEA dx, open_err
    MOV ah, 09H
    INT 21H
end3:
    POP dx
    POP ax
    RET
open ENDP

;关闭文件
close PROC NEAR
    PUSH ax
    MOV ah, 3EH
    INT 21H
    JC  fail4
    MOV bx, 0
    JMP end4
fail4:
    MOV bx, 1
    LEA dx, close_err
    MOV ah, 09H
    INT 21H
end4:
    POP ax
    RET
close ENDP

;读文件
read PROC NEAR
    PUSH ax
    PUSH cx
    PUSH dx
    MOV ah, 3FH
    MOV cx, 100
    LEA dx, in_buf
    INT 21H
    JC  fail1
    MOV bx, 0
    MOV in_len, ax
    JMP end1
fail1:
    MOV bx, 1
    LEA dx, read_err
    MOV ah, 09H
    INT 21H
end1:
    POP dx
    POP cx
    POP ax
    RET
read ENDP

;写文件
write PROC NEAR
    PUSH ax
    PUSH cx
    PUSH dx
    MOV ah, 40H
    MOV cx, out_len
    LEA dx, out_buf
    INT 21H
    JC  fail2
    MOV bx, 0
    MOV out_len, ax
    JMP end2
fail2:
    MOV bx, 1
    LEA dx, write_err
    MOV ah, 09H
    INT 21H
end2:
    POP dx
    POP cx
    POP ax
    RET
write ENDP

;加密
encode PROC NEAR
    PUSH ax
    PUSH bx
    PUSH cx
    PUSH si
    MOV cx, in_len
    MOV si, 0
loop1:
    CMP si, cx  ;为空就跳
    JGE end5    
    MOV al, in_buf[si]
    
    mov bx,psw
    xor al, bl       ;异或操作
    MOV out_buf[si], al
    INC si
    JMP loop1
end5:
    POP si
    POP cx
    POP bx
    POP ax
    RET
encode ENDP

;解密
decode PROC NEAR
    PUSH ax
    PUSH bx
    PUSH cx
    PUSH si
    MOV cx, in_len
    MOV si, 0
loop2:
    CMP si, cx
    JGE end6
    MOV al, in_buf[si]
    
    MOV bx, psw
    xor al,bl
    MOV out_buf[si], al
    INC si
    JMP loop2
end6:
    POP si
    POP cx
    POP bx
    POP ax
    RET
decode ENDP

;主函数
main PROC FAR
start:
    MOV ax, dataseg
    MOV ds, ax
    MOV ax, stackseg
    MOV ss, ax

    ;psw为指定密钥
    MOV ax, 00ffh
    MOV psw, ax

    LEA dx, in_note
    MOV ah, 09H
    INT 21H
    LEA dx, CRLF
    MOV ah, 09H
    INT 21H
    LEA dx, uri
    MOV ah, 0AH
    INT 21H
    LEA dx, CRLF
    MOV ah, 09H
    INT 21H
    ;对uri进行处理，asciz串以0结尾
    MOV cl, uri + 1  
    MOV ch, 0
    MOV si, cx
    ADD si, 2
    MOV uri[si], 30H    ;以0结尾，0的ascii码是48
    ;打开文件
    CALL open
    CMP bx, 1
    JE  ed      ;打开失败，程序结束
    MOV in_file, bx ;bx中返回的文件代号

    LEA dx, out_note  
    MOV ah, 09H
    INT 21H
    LEA dx, CRLF
    MOV ah, 09H
    INT 21H
    LEA dx, uri
    MOV ah, 0AH
    INT 21H
    LEA dx, CRLF
    MOV ah, 09H
    INT 21H
    MOV cl, uri + 1     
    MOV ch, 0
    MOV si, cx
    ADD si, 2
    MOV uri[si], 30H
    CALL create
    CMP bx, 1
    JE  ed
    MOV out_file, bx    ;bx为创建的文件的代号

    LEA dx, mode_note      
    MOV ah, 09H
    INT 21H
    LEA dx, CRLF
    MOV ah, 09H
    INT 21H
    MOV ah, 01H
    INT 21H
    MOV ah, 0
    SUB ax, 30H
    MOV mode, ax
    LEA dx, CRLF
    MOV ah, 09H
    INT 21H
next:
    MOV bx, in_file
    CALL read           ; 读入缓冲区
    CMP bx, 1
    JE  ed
    MOV cx, in_len
    MOV dx, mode
    CMP dx, 0
    JE  pass1
    CMP dx, 1
    JE  pass2
    JMP err
pass3:
    MOV out_len, cx
    MOV bx, out_file
    CALL write          ; 写入输出文件
    CMP cx, 100
    JGE next
    MOV bx, in_file
    CALL close
    MOV bx, out_file
    CALL close
    JMP ed
pass1:
    CALL encode
    JMP pass3
pass2:
    CALL decode
    JMP pass3
err:
    LEA dx, mode_err
    MOV ah, 09H
    INT 21H
    LEA dx, CRLF
    MOV ah, 09H
    INT 21H
ed:
    MOV ah, 4CH
    INT 21H
main ENDP

codeseg ENDS
    END start
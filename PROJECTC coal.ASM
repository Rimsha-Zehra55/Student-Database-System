.model small
.stack 100h

.data
; Menu & prompts  
menuMsg     db 13,10,'1. Add Student',13,10,'2. Search Student',13,10,'3. Delete Student',13,10,'4. Display All Students',13,10,'5. Exit',13,10,'Enter choice: $'
enterRoll   db 13,10,'Enter Roll Number (0-9): $'
enterName   db 13,10,'Enter Name (max 19 chars): $'
enterSem    db 13,10,'Enter Semester (1-8): $'
enterCgpa   db 13,10,'Enter CGPA point (0-4): $'
foundMsg    db 13,10,'Student Found!',13,10,'Name: $'
notFound    db 13,10,'Student Not Found!$'
deletedMsg  db 13,10,'Record Deleted Successfully!$'
allMsg      db 13,10,'--- All Students ---',13,10,'$'
labelRoll   db 'Roll: $'
labelName   db 'Name: $'
labelSem    db 'Semester: $'
labelCgpa   db 'CGPA: $'
divider     db '------------------------',13,10,'$'
newline     db 13,10,'$'

maxStudents equ 10

; Data arrays
rollArray    db maxStudents dup(0)        
nameArray    db maxStudents*20 dup('$')    
semArray     db maxStudents dup(0)       
cgpaArray    db maxStudents dup(0)        
studentCount db 0

.code

 
; readDigit - read single key, return numeric in AL (0..9)
 
readDigit PROC
    mov ah, 1
    int 21h
    sub al, '0'
    ret
readDigit ENDP

 
; readName - DI must point to destination address (absolute)
; reads up to 19 chars, terminates with '$'
 
readName PROC
    push cx
    push bx
    mov cx, 19
rn_loop:
    mov ah,1
    int 21h
    cmp al,13
    je rn_done
    mov [di], al
    inc di
    loop rn_loop
rn_done:
    mov byte ptr [di], '$'
    pop bx
    pop cx
    ret
readName ENDP

 
; printDigit - input in AL (0..9), prints digit character
 
printDigit PROC
    add al, '0'
    mov dl, al
    mov ah, 2
    int 21h
    ret
printDigit ENDP

 
; addStudent
 
addStudent PROC
    ; prompt roll
    mov dx, OFFSET enterRoll
    mov ah, 9
    int 21h

    call readDigit         
    mov bl, studentCount   
    mov [rollArray + bx], al

    ; prompt name
    mov dx, OFFSET enterName
    mov ah, 9
    int 21h

    ; compute name destination: OFFSET nameArray + index*20 -> put in DI
    xor ah, ah            
    mov al, bl             
    mov bx, 20
    mul bx                 
    mov di, OFFSET nameArray
    add di, ax
    call readName

    ; prompt semester and validate (1-8)
input_semester:
    mov dx, OFFSET enterSem
    mov ah, 9
    int 21h

    call readDigit       

    cmp al, 1
    jb input_semester     
    cmp al, 8
    ja input_semester     

    mov bl, studentCount
    mov [semArray + bx], al

    ; prompt cgpa and validate (0-4)
input_cgpa:
    mov dx, OFFSET enterCgpa
    mov ah, 9
    int 21h

    call readDigit         

    cmp al, 0
    jb input_cgpa        
    cmp al, 4
    ja input_cgpa         

    mov bl, studentCount
    mov [cgpaArray + bx], al

    
    inc studentCount
    ret
addStudent ENDP

 
; searchStudent (by roll)
 
searchStudent PROC
    mov dx, OFFSET enterRoll
    mov ah, 9
    int 21h

    call readDigit         
    mov dl, al             

    mov cl, studentCount
    xor ch, ch
    xor si, si             

s_loop:
    cmp cl, 0
    je s_notfound

    mov al, [rollArray + si]
    cmp al, dl
    je s_found

    inc si
    dec cl
    jmp s_loop

s_notfound:
    mov dx, OFFSET notFound
    mov ah,9
    int 21h
    ret

s_found:
    mov dx, OFFSET foundMsg
    mov ah,9
    int 21h

    ; print name
    mov ax, si
    mov bx, 20
    mul bx                 
    mov dx, OFFSET nameArray
    add dx, ax
    mov ah,9
    int 21h
    ret
searchStudent ENDP
 
deleteStudent PROC
    mov dx, OFFSET enterRoll
    mov ah, 9
    int 21h

    call readDigit        
    mov dl, al

    mov cl, studentCount
    xor ch, ch
    xor si, si

d_loop:
    cmp cl, 0
    je d_notfound

    mov al, [rollArray + si]
    cmp al, dl
    je d_found

    inc si
    dec cl
    jmp d_loop

d_notfound:
    mov dx, OFFSET notFound
    mov ah,9
    int 21h
    ret

d_found:
    ; clear roll/sem/cgpa
    mov byte ptr [rollArray + si], 0
    mov byte ptr [semArray + si], 0
    mov byte ptr [cgpaArray + si], 0

    ; set name slot start to '$' (empty)
    mov ax, si
    mov bx, 20
    mul bx                 
    mov di, OFFSET nameArray
    add di, ax
    mov byte ptr [di], '$'

    mov dx, OFFSET deletedMsg
    mov ah,9
    int 21h
    ret
deleteStudent ENDP

 
; displayAll
 
displayAll PROC
    mov dx, OFFSET allMsg
    mov ah,9
    int 21h

    mov cl, studentCount
    xor ch, ch
    xor si, si             

display_loop:
    cmp cl, 0
    je display_done

    ; divider
    mov dx, OFFSET divider
    mov ah,9
    int 21h

    ; Roll label
    mov dx, OFFSET labelRoll
    mov ah,9
    int 21h
    ; roll value
    mov al, [rollArray + si]
    call printDigit

    
    mov dx, OFFSET newline
    mov ah,9
    int 21h

    ; Name label
    mov dx, OFFSET labelName
    mov ah,9
    int 21h
    ; name value: compute offset = index*20
    mov ax, si
    mov bx, 20
    mul bx                 
    mov dx, OFFSET nameArray
    add dx, ax
    mov ah,9
    int 21h

     
    mov dx, OFFSET newline
    mov ah,9
    int 21h

    ; Semester label
    mov dx, OFFSET labelSem
    mov ah,9
    int 21h
    mov al, [semArray + si]
    call printDigit

    
    mov dx, OFFSET newline
    mov ah,9
    int 21h

     
    mov dx, OFFSET labelCgpa
    mov ah,9
    int 21h
    mov al, [cgpaArray + si]
    call printDigit

     
    mov dx, OFFSET newline
    mov ah,9
    int 21h

    inc si                 
    dec cl
    jmp display_loop

display_done:
    ret
displayAll ENDP
 
; main
 
main PROC
    mov ax, @data
    mov ds, ax

menuLoop:
    mov dx, OFFSET menuMsg
    mov ah,9
    int 21h

    mov ah,1
    int 21h
    mov bl, al

    cmp bl, '1'
    je L1
    cmp bl, '2'
    je L2
    cmp bl, '3'
    je L3
    cmp bl, '4'
    je L4
    cmp bl, '5'
    je L5
    jmp menuLoop

L1: call addStudent
    jmp menuLoop
L2: call searchStudent
    jmp menuLoop
L3: call deleteStudent
    jmp menuLoop
L4: call displayAll
    jmp menuLoop

L5:
    mov ah, 4Ch
    int 21h

main ENDP
end main

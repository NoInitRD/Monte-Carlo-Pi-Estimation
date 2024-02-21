option casemap:none


.data
; changes grid dimensions
GRID_SIZE EQU 27
origin dq GRID_SIZE / 2
array byte GRID_SIZE * GRID_SIZE dup(0)

; subtracted 1 to treat it like an offset correctly later
totalSize dq (GRID_SIZE * GRID_SIZE) - 1

totalPointsInsideCircle dq 0, 0
totalPoints dq 0, 0
piEstimate dq 0, 0

; changes how frequently to estimate pi relative to points generate
interval dq 10

; changes how many points to generate
maxPointsToGenerate dq (GRID_SIZE * GRID_SIZE) * 2

newLine byte 10, 0
fmtInteger byte '%d ', 0
fmtString byte '%s ', 0
fmtFloat byte '%.12f', 0
insideMessage byte "Number of points inside: ", 0
outsideMessage byte "Total number of points: ", 0
piMessage byte "Pi estimation: ", 0


fpuStorage dq ?
fpuResult dq ?


.code
externdef printf:proc
externdef time:proc


externdef generateRandomNumber:NEAR
externdef clearScreen:NEAR


public asmMain
public print
public populateGrid
public printGrid
public isInsideCircle
public pickRandomPoint
public checkPiEstimation
public printNewLine


asmMain proc
		sub rsp, 16							; 8 for return pointer, 8 for alignment 
		push r13							; save callee registers

		prefetch array						; prefetch data
		prefetch fmtInteger					;
		prefetch fmtString					;
		prefetch fmtFloat					;
		prefetch insideMessage				;
		prefetch outsideMessage				;
		prefetch piMessage					;
		prefetch fpuStorage					;
		prefetch fpuResult					;
		
		lea rdi, array						; make circle
		call populateGrid					;
		
printNums:
		call clearScreen
		
		lea rdi, array						; print grid
		call printGrid						;
		
		call printInfo						; print information
		mov r13, 0							; reset interval
		
start:					
		lea rdi, array
		call pickRandomPoint
		
		mov rdi, totalPoints				; stop if we've hit limit
		cmp rdi, maxPointsToGenerate		;
		jg stop								;

		inc r13								; jump if interval finished
		cmp r13, [interval]					; 
		je printNums						; 
		
		jmp start							; loop
		
stop:				
		;call clearScreen					; final result
		;call printInfo						;
		
		pop r13								;
		add rsp, 16							;
		ret									; return to caller
asmMain endp


; prints out relevant numerical information during estimation
printInfo proc
		sub rsp, 8
		
		call printNewLine					; show inside count
		lea rdi, insideMessage				; 
		lea rcx, fmtString					;
		call print							;
		mov rdi, [totalPointsInsideCircle]	;
		lea rcx, fmtInteger					;
		call print							;
		call printNewLine					;
		
		lea rdi, outsideMessage				; show outside count
		lea rcx, fmtString					;
		call print							;
		mov rdi, [totalPoints]				;
		lea rcx, fmtInteger					;
		call print							;
		call printNewLine					;
		
		lea rdi, piMessage					; print out pi estimate
		lea rcx, fmtString					;
		call print							;
		call checkPiEstimation				;
		lea rcx, fmtFloat					;
		mov rdi, piEstimate					;
		call print							;
		
		add rsp, 8
		ret
printInfo endp


; prints an item stored in RDI
; -RDI: thing to print
; -RCX: pointer to format identifier
print proc
		sub rsp, 40					; 8 for return pointer 32 for shadow storage
		mov rdx, rdi				; load input into second arg
		call printf
		add rsp, 40
		ret
print endp


; finds a circle within a grid
; -RDI: base address of array
populateGrid proc
		push r12					; save callee-saved registers
		push r13					;
		
		mov rdx, rdi				; copy base address to rdx
		mov r12, 0					; initialize i = 0
		mov r13, 0					; initialize j = 0
		
		xor rdi, rdi				; zero out rdi
		jmp innerLoop
		
outerLoop:
		cmp r12, GRID_SIZE			; grid size constant
		je stop
		
		mov r13, 0					; restart j at 0 each time
		inc r12						; increment outer loop

innerLoop:
		cmp r13, GRID_SIZE			; if innerloop is over
		je outerLoop				;
	
		mov r8, r12					; check if point is in circle
		mov r9, r13					;
		push rdx					; save array address
		call isInsideCircle			;
		pop rdx						; restore array address
		
		cmp al, 1
		je insideCirc
	
		inc r13						; increment inner loop
		inc rdx						; go to next num	
	
		jmp innerLoop
		
insideCirc:
		mov byte ptr [rdx], al
		
		inc r13						; increment inner loop
		inc rdx						; go to next num
		jmp innerLoop
		
stop:
		pop r12						; restore callee-saved registers
		pop r13						;
		
		ret
populateGrid endp



; prints out an array in 2D style
; -RDI: base address of array
printGrid proc
		push r12					; save callee-saved registers
		push r13					;
		
		mov rdx, rdi				; copy base address to rdx
		mov r12, 0					; initialize i = 0
		mov r13, 0					; initialize j = 0
		
		xor rdi, rdi				; zero out rdi
		jmp innerLoop
		
outerLoop:
		cmp r12, GRID_SIZE - 1		; grid size constant
		je stop
		
		push rdx					; save array address
		call printNewLine
		pop rdx						; restore array address
		
		mov r13, 0					; restart j at 0 each time
		inc r12						; increment outer loop

innerLoop:
		cmp r13, GRID_SIZE			; if innerloop is over
		je outerLoop				;
		
		mov dil, byte ptr [rdx]		; grab current character
		lea rcx, fmtInteger
		push rdx					; save array address
		call print
		pop rdx						; restore array address
		
		inc r13						; increment inner loop
		inc rdx						; go to next num
	
		jmp innerLoop
		
stop:
		pop r12						; restore callee-saved registers
		pop r13						;
			
		ret
printGrid endp


; determines whether a point is inside a circle of the same
; diameter as the side of the grids edges
; -R8: X coordinate of point
; -R9: Y coordinate of point
; -RAX: return register, contains the distance from the origin
; -EAX: return register, 0 if false, 1 if true
isInsideCircle proc
		; uses formula d = sqrt((x - n)^2 + (y - n)^2)
		; where n is the origin and d is the distance
		sub r8, origin				; (x - n)
		sub r9, origin				; (y - n)
		
		mov rdx, r8 				; squaring (x - n)
		mov rax, r8					;
		mul rdx						;
		mov r8, rax					;
		
		mov rdx, r9					; squaring (y - n)
		mov rax, r9					;
		
		mul rdx						;
		mov r9, rax					;
		
		add r8, r9 					; adding them together
		
		mov [fpuStorage], r8		; load result into fpu storage space
		fild fpuStorage 			; prep result for square root
		fsqrt						; compute square root
		fistp fpuResult				; store result 
		
		xor eax, eax				; zero out eax
		lea rax, fpuResult			; store for return
		mov rax, qword ptr [rax]	; dereference
		
		cmp rax, origin
		setle al
		ret
isInsideCircle endp


; picks a random point on the circle and flips marks it, also
; increments the number of points in the circle or outside depending on where
; the random point ended up
; -RDI: pointer to array
; -R11: holds the value of x
; -R12: holds the value of y
pickRandomPoint proc
		sub rsp, 8
		push rdi					; save array ptr
		
		mov rcx, totalSize			; get random position
		
		push rdx					; get random int 
		xor rax, rax
		call generateRandomNumber
		pop rdx						
		
		pop rdi						; restore pointer
		add rdi, rax				; mark point on grid
		mov byte ptr [rdi], 2		; 
		
		xor rdx, rdx				; zero out upper 64 bits of divisor
		mov rbx, GRID_SIZE			; load divisor into rbx
		div rbx						; rax contains lower 64 bits of divisor from randInt
		
		mov r8, rax					; quotient
		mov r9, rdx					; remainder
		call isInsideCircle			; check if x & y are inside
		
		cmp eax, 1					; jump if inside
		je insideCircle				;
		jmp exit					; otherwise exit

insideCircle:
		mov rdi, [totalPointsInsideCircle]	; add one to inside circle count
		inc rdi								;
		mov [totalPointsInsideCircle], rdi	;
		
exit:
		mov rdi, [totalPoints]	; add one to outside circle count
		inc rdi								;
		mov [totalPoints], rdi	;

		add rsp, 8
		ret
pickRandomPoint endp


; finds the pi estimation using the number of 2's that end up in 
; the circle vs outside
checkPiEstimation proc
		sub rsp, 8 
		
		cvtsi2sd xmm0, totalPointsInsideCircle			; convert to floating point
		
		cvtsi2sd xmm1, totalPoints						;
		
		divsd xmm0, xmm1
		
		addsd xmm0, xmm0								; multiply by 4
		addsd xmm0, xmm0 								;

		movsd [piEstimate], xmm0
		
		add rsp, 8
		ret
checkPiEstimation endp


; prints a newline
printNewLine proc
		sub rsp, 40					; 8 for return pointer 32 for shadow storage
		lea rcx, fmtString
		lea rdx, newLine
		call printf
		add rsp, 40
		ret
printNewLine endp


end

;Odwracanie bitmapy w poziomie
;
;Algorytm w ka¿dej pêtli zamienia miejscami 5 pikseli z pocz¹tku i koñca wiersza.
;Gdy pozostaje mniej ni¿ 10 nieodwróconych pikseli w wierszu, 
;to pozosta³e piksele zamieniane s¹ pojedyñczo.
;
;Wyk. Kacper Flis


;void MirrorASM(unsigned char*, DWORD, DWORD, DWORD)
;rcx tablica pikseli
;rdx szerokoœæ wiersza w bajtach (+ wyrównanie)
;r8 wysokoœæ góra
;r9 wysokoœæ dó³

;wyjœciowo
;rbx lewy indeks
;rsi prawy indeks
;r10 ile razy 30 siê mieœci w szer w bajtach - 32
;r11 ile poj. pikseli zostaje
;r12 ile bajtów z wyrównania
;r13 aktualny offset
;r14 offset (rdx + r12)


.code
MirrorASM proc
;zapisanie wartosci rejestrow
	push rbx
	push rbp
	push rdi
	push rsp
	push rsi

	;wyliczenie bajtów z wyrównania (r12)
	mov rbx, rdx
	cmp rbx, 4
	jle padend
padloop:
	sub rbx, 4
	cmp rbx, 4
	jle padend
	jmp padloop
padend:
	mov rax, 4
	sub rax, rbx
	mov r12, rax
	
	;wyliczenie offsetu
	mov rax, rdx
	add rax, r12
	mov r14, rax

	;wyliczenie aktualnego offsetu (r13)
	mov r13, 0
	mov rbx, 1
offcompare:
	cmp rbx, r9
	je offend
	inc rbx
	add r13, r14
	jmp offcompare
offend:

	;wyliczenie ile razy 30 mieœci siê w szerokoœci w bajtach - 32 (r10)
	mov rbx, 0
	push rdx
	sub rdx, 62
r10compare:
	cmp rdx, 0
	jl r10end
	sub rdx, 30
	inc rbx
	jmp r10compare
r10end:
	mov r10, rbx
	pop rdx

	;wyliczenie ile pojedyñczych pikseli zostaje (r11)
	push rdx
	mov rdx, 0
	mov rax, rdx
	mov rbx, 3
	div rbx
modcompare:
	cmp rax, 10
	jl modend
	sub rax, 10
	jmp modcompare
modend:
	mov r11, rbx
	pop rdx

	;ustawienie masek w xmm4 i xmm5
	;-> 0201000504030807060B0A090E0D0C0F
	;-> 000302010605040908070C0B0A0F0E0D
	mov rax, 00201000504030807h
	movd xmm4, rax
	pslldq xmm4, 8
	mov rax, 0060B0A090E0D0C0Fh
	movd xmm6, rax
	paddq xmm4, xmm6

	mov rax, 00003020106050409h
	movd xmm5, rax
	pslldq xmm5, 8
	mov rax, 008070C0B0A0F0E0Dh
	movd xmm6, rax
	paddq xmm5, xmm6

poczatek:
	push r10
	push r11

	;rbx na 0 + aktualny offset
	mov rbx, 0
	add rbx, r13

	;rsi na 16 pozycje od koñca wiersza
	mov rsi, rbx
	add rsi, rdx
	sub rsi, r12
	sub rsi, 16
	
	;jesli szer. w bajtach < 32 to po 1 pikselu
	cmp rdx, 32
	jl pojedynczo

	;pobranie bajtów do xmm0 i xmm2
	movdqu xmm0, xmmword ptr [rcx+rbx]
	movdqu xmm2, xmmword ptr [rcx+rsi]

	;sprawdzenie, czy zostaje mniej ni¿ 10 nieodwróconych pikseli
	cmp r10, 0
	je koniec_parzysty

	jmp glowna_petla

glowna_petla:

	;zmniejszenie petli
	dec r10

	;przesuniecie indeksów ku œrodkowi wiersza
	add rbx, 15
	sub rsi, 15

	;pobranie bajtów do xmm1 i xmm3
	movdqu xmm1, xmmword ptr [rcx+rbx]
	movdqu xmm3, xmmword ptr [rcx+rsi]

	;odwrócenie xmm0 i xmm2
	pshufb xmm0, xmm4
	pshufb xmm2, xmm5

	;przesuniecie indeksow do zewnatrz
	sub rbx, 15
	add rsi, 15

	;zapisanie xmm0 i xmm2
	movdqu xmmword ptr [rcx+rbx], xmm2
	movdqu xmmword ptr [rcx+rsi], xmm0

	;przesuniecie indeksow ku srodkowi
	add rbx, 15
	sub rsi, 15

	;jeœli r10 == 0, to skok do koniec_nieparzysty
	cmp r10, 0
	je koniec_nieparzysty

	;zmniejszenie petli
	dec r10

	;przesuniecie indeksow ku srodkowi
	add rbx, 15
	sub rsi, 15

	;pobranie bajtów do xmm0 i xmm2
	movdqu xmm0, xmmword ptr [rcx+rbx]
	movdqu xmm2, xmmword ptr [rcx+rsi]

	;odwrócenie xmm1 i xmm3
	pshufb xmm1, xmm4
	pshufb xmm3, xmm5

	;przesuniecie indeksow do zewnatrz
	sub rbx, 15
	add rsi, 15

	;zapisanie xmm1 i xmm3
	movdqu xmmword ptr [rcx+rbx], xmm3
	movdqu xmmword ptr [rcx+rsi], xmm1

	;przesuniecie indeksow ku srodkowi
	add rbx, 15
	sub rsi, 15

	;jeœli r10 == 0, to skok do koniec_parzysty
	cmp r10, 0
	je koniec_parzysty

	;skok do glowna_petla
	jmp glowna_petla

; dla xmm0 i xmm2
koniec_parzysty:
	;przesuniecie indeksu
	add rbx, 15

	;wczytanie po 1 bajcie z ka¿dej strony
	mov ah, byte ptr [rcx+rbx]
	mov al, byte ptr [rcx+rsi]

	;odwrócenie xmm0 i xmm2
	pshufb xmm0, xmm4
	pshufb xmm2, xmm5

	;przesuniecie indeksu
	sub rbx, 15

	;zapisanie xmm0 i xmm2
	movdqu xmmword ptr [rcx+rbx], xmm2
	movdqu xmmword ptr [rcx+rsi], xmm0

	;przesuniecie indeksu
	add rbx, 15

	;zapisanie pobranych bajtow
	mov byte ptr [rcx+rbx], ah
	mov byte ptr [rcx+rsi], al

	;skok do pojedynczo
	jmp pojedynczo

; dla xmm1 i xmm3
koniec_nieparzysty:

	;przesuniecie indeksu
	add rbx, 15

	;wczytanie po 1 bajcie z ka¿dej strony
	mov ah, byte ptr [rcx+rbx]
	mov al, byte ptr [rcx+rsi]

	;odwrócenie xmm0 i xmm2
	pshufb xmm1, xmm4
	pshufb xmm3, xmm5

	;przesuniecie indeksu
	sub rbx, 15

	;zapisanie xmm0 i xmm2
	movdqu xmmword ptr [rcx+rbx], xmm3
	movdqu xmmword ptr [rcx+rsi], xmm1

	;przesuniecie indeksu
	add rbx, 15

	;zapisanie pobranych bajtow
	mov byte ptr [rcx+rbx], ah
	mov byte ptr [rcx+rsi], al

	;skok do pojedynczo
	jmp pojedynczo

;zamiana dwoch pikseli po bajcie
pojedynczo:

	;jeœli liczba pozosta³ych pikseli < 2, to skok do koniec
	cmp r11, 2
	jl koniec_linii
	
	sub rsi, 2
	;b
	mov ah, byte ptr [rcx+rbx]
	mov al, byte ptr [rcx+rsi]
	mov byte ptr [rcx+rbx], al
	mov byte ptr [rcx+rsi], ah

	;g
	inc rbx
	inc rsi
	mov ah, byte ptr [rcx+rbx]
	mov al, byte ptr [rcx+rsi]
	mov byte ptr [rcx+rbx], al
	mov byte ptr [rcx+rsi], ah

	;r
	inc rbx
	inc rsi
	mov ah, byte ptr [rcx+rbx]
	mov al, byte ptr [rcx+rsi]
	mov byte ptr [rcx+rbx], al
	mov byte ptr [rcx+rsi], ah
	sub rsi, 3
	inc rbx

	;zmniejszenie petli
	sub r11, 2

	jmp pojedynczo

koniec_linii:
	pop r11
	pop r10
	
	;jesli wys. dó³ = wys. góra, to koniec
	cmp r8, r9
	je koniec
	
	;jesli nie, to kolejny wiersz
	inc r9

	;zwiekszenie offsetu i skok do poczatku petli
	add r13, r14
	jmp poczatek

koniec:
	;przywrocenie wartosci rejestrow
	pop rsi
	pop rsp
	pop rdi
	pop rbp
	pop rbx
	ret
MirrorASM endp
end
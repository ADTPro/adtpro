; copy memory


;	.export copymem
;	.exportzp copy_src
;	.exportzp copy_dest


	;.zeropage

; pointers for copying
copy_src	= $80			; source pointer
copy_dest	= $82			; destination pointer


;	.bss

end:		.res 1


;	.code

; copy memory
; set copy_src and copy_dest, length in A/X
copymem:
	sta end
	ldy #0

	cpx #0
	beq @tail

:	lda (copy_src),y
	sta (copy_dest),y
	iny
	bne :-

	dex
	bne :-

@tail:
	lda end
	beq @done

:	lda (copy_src),y
	sta (copy_dest),y
	iny
	cpy end
	bne :-

@done:
	rts

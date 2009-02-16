; copy memory


	.export copymem
	.exportzp copy_src
	.exportzp copy_dest


	.segment "IP65ZP" : zeropage

; pointers for copying
copy_src:	.res 2			; source pointer
copy_dest:	.res 2			; destination pointer


	.bss

end:		.res 1


	.code

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

	inc copy_src + 1
	inc copy_dest + 1

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

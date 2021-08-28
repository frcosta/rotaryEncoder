; Autor; Fabiano Costa
; 27-08-2021
; Trata as saidas de um encoder rotativo gerando pulsos de 20ms nas saidas a cada tick para a direita e esquerda
; As saidas do encoder deverao ser conectadas aos pinos 1 e 2 do PIC e o pino central devera ser conectado ao terra
; As saidas do PIC estao nos pinos 4 e 5
;
; MCU: PIC12F675
; Autor: Fabiano Costa
; Data de criacao: 27/08/2021
; Desenvolvido no MPLAB 8.92
; 
; GPIO,1 entrada
; GPIO,2 entrada (interrupcao)
; GPIO,4 saida
; GPIO,5 saida

 list		p=12f675		; MCU utilizada

 #include <p12f675.inc>

; ---- Fuse Bits ----

   __config _INTRC_OSC_NOCLKOUT & _WDTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF
 
; ---- Registradores de uso geral ----

 cblock					H'20'

 W_TEMP
 STATUS_TEMP

 endc

; ---- Definicao de I/O ----
 #define	out0		GPIO,4					; Saida pulso 0
 #define	out1		GPIO,5					; Saida pulso 1
 #define	in0			GPIO,1					; Entrada
;#define	in1			GPIO,2					; Entrada (configurado via interrupcao)
 
; ---- Vetor de inicializacao ----
 	org 				H'0000'					; Origem no endereco 0x00
 	goto				configs					; Desvia do vetor de interrupcao
 	
; ---- Vetor de interrupcao ----

	org					H'0004'					; Interrupcoes apontam para este endereco
	
; ---- Salvamento de contexto ---
	MOVWF 				W_TEMP					; W_TEMP = W
	SWAPF 				STATUS,W				; W = STATUS (nibbles invertidos)
	BCF 				STATUS,RP0				; Seleciona banco de memória
	MOVWF 				STATUS_TEMP				; STATUS_TEMP = W
	
; ---- ISR ----

	bcf					INTCON,INTF				; Apaga flag de interrupcao
	btfsc				in0						; Se in0 = 0 executa decrementa
	goto				incrementa				; Executa incrementa
	call				pulsoDecr
	goto				exit_ISR
incrementa:
	call				pulsoIncr
	
; ---- Fim ISR ----


; ---- Recuperacao de contexto ----
exit_ISR:
	SWAPF 				STATUS_TEMP,W			; W = STATUS_TEMP (nibbles invertidos)
												; SWAPF f,d
												; d = SWAP(f)
												; (aaaabbbb) -> (bbbbaaaa)
	MOVWF 				STATUS					; STATUS = W
	SWAPF 				W_TEMP,F				; W_TEMP = W_TEMP (invetido)
	SWAPF 				W_TEMP,W				; W = W_TEMP (invertido) 
	
	retfie

configs:

	bcf 				STATUS,RP0 				; Bank 0
	clrf 				GPIO 					; Inicializa GPIO

	movlw 				07h 					; Desabilita comparador
	movwf 				CMCON 					; Desabilita comparador
	
	bsf 				STATUS,RP0 				; Bank 1
	clrf 				ANSEL 					; Desabilita uso de portas analogicas
	
	bsf					INTCON,GIE				; Habilita interrupcoes
	bsf					INTCON,INTE				; Habilita interrupcao externa em GP2
	bcf					OPTION_REG,INTEDG		; Seta Interrupcao por borda de descida em GP2
	
	movlw				b'00001111'				; 
	movwf				TRISIO					; Configura GP4 e GP5 como saidas
	
	bcf 				STATUS,RP0 				; Bank 0
	
; ----LOOP PRINCIPAL --------------
inicio:
	nop
	goto				inicio
	
; ---- FIM DO LOOP PRINCIPAL ------

; ---- FUNCAO DE DELAY ----
; Loop externo D80 / Loop Interno D36 = 20ms a 4MHz
; Loop externo D40 / Loop Interno D36 = 10ms a 4MHz

delayMs:
	
	movlw				D'80'
	movwf				20h

delayMs2:

	movlw				D'36'
	movwf				21h
	
delayMsAux:
	
	nop
	nop
	nop
	nop
	nop
	
	decfsz				21h
	goto				delayMsAux
	decfsz				20h
	goto 				delayMs2
	return

pulsoIncr:
	bsf					out0
	call				delayMs
	bcf					out0
	return
	
pulsoDecr:
	bsf					out1
	call				delayMs
	bcf					out1
	return	


fim:
	end


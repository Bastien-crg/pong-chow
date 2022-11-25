	;; RK - Evalbot (Cortex M3 de Texas Instrument)
; programme - Pilotage 2 Moteurs Evalbot par PWM tout en ASM (Evalbot tourne sur lui m�me)



		AREA    |.text|, CODE, READONLY
		ENTRY
		EXPORT	__main
		
		; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIO EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)


			
		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; d�activer le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arri�re
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; d�activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arri�re
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche
			
		IMPORT	BUMPERS_INIT
		IMPORT	SWITCHERS_INIT
		IMPORT 	LED_INIT
		IMPORT 	TURN_ON_BOTH
		IMPORT 	TURN_OFF_BOTH
		IMPORT 	TURN_ON_LEFT
		IMPORT 	TURN_ON_RIGHT


__main	

				; ;; Enable the Port F & D peripheral clock 		(p291 datasheet de lm3s9B96.pdf)
		; ;;									
		ldr r9, = SYSCTL_PERIPH_GPIO  			;; RCGC2
        mov r0, #0x00000038  					;; Enable clock sur GPIO D et F o� sont branch�s les leds (0x28 == 0b111000)
		; ;;														 									      (GPIO::FEDCBA)
        str r0, [r9]
		
		; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
		nop	   									;; tres tres important....
		nop	   
		nop	   									;; pas necessaire en simu ou en debbug step by step...
	

;; BL Branchement vers un lien (sous programme)

		; Configure les PWM + GPIO
		BL 	SWITCHERS_INIT
		BL 	BUMPERS_INIT
		BL	MOTEUR_INIT
		BL 	LED_INIT
		
		; Activer les deux moteurs droit et gauche
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON


		;test clignotement
		;BL BLINK_BOTH_LED


		; Boucle de pilotage des 2 Moteurs (Evalbot tourne sur lui m�me)
		
avanceVoit	
		; Evalbot avance droit devant
		
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_AVANT
		
		; Avancement pendant une p�riode (deux WAIT)
		;BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		;BL	WAIT
		; Rotation � droite de l'Evalbot pendant une demi-p�riode (1 seul WAIT)
		b readBumper


		;; Boucle d'attante
WAIT	ldr r1, =0xAFFFFF 

wait1	subs r1, #1
        bne wait1
		
		;; retour � la suite du lien de branchement
		BX	LR

actionBumperGauche
		BL	TURN_ON_LEFT
		BL	MOTEUR_DROIT_ARRIERE	   
		BL	MOTEUR_GAUCHE_ARRIERE
		BL WAIT
		BL	MOTEUR_DROIT_OFF	   
		BL	MOTEUR_GAUCHE_AVANT
		BL WAIT
		BL	TURN_ON_RIGHT
		BL  MOTEUR_DROIT_ON
		b avanceVoit

actionBumperDroit
		BL	MOTEUR_DROIT_ARRIERE	   
		BL	MOTEUR_GAUCHE_ARRIERE
		BL WAIT
		BL	MOTEUR_GAUCHE_OFF	   
		BL	MOTEUR_DROIT_AVANT
		BL WAIT
		BL  MOTEUR_GAUCHE_ON
		b avanceVoit

readBumper
		ldr r10,[r8]
		CMP r10,#0x01							;;0x01 = bumber gauche , 0x02 = bumber droit
		BEQ actionBumperGauche
		CMP r10,#0x02
		BEQ actionBumperDroit
		b avanceVoit
		
		NOP
        END
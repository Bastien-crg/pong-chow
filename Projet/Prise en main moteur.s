	;; RK - Evalbot (Cortex M3 de Texas Instrument)
; programme - Pilotage 2 Moteurs Evalbot par PWM tout en ASM (Evalbot tourne sur lui même)



		AREA    |.text|, CODE, READONLY
		ENTRY
		EXPORT	__main
		
		; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIO EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)


			
		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arrière
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arrière
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche
			
		IMPORT	BUMPERS_INIT
		IMPORT	SWITCHERS_INIT
		IMPORT 	LED_INIT
		IMPORT 	TURN_ON_BOTH
		IMPORT 	TURN_OFF_BOTH
		IMPORT 	TURN_ON_LEFT
		IMPORT 	TURN_ON_RIGHT

DUREE					EQU		0x2FFFF
DUREELed   				EQU     0x8FFFF
DUREERecule   			EQU     0xAFFFF1	;0xAFFFFF
DUREETourne				EQU		0xAFFFF5	;0xAFFFFF
DUREEJeu				EQU 	0x4FFFFF	;0x43FFFF

__main	

				; ;; Enable the Port F & D peripheral clock 		(p291 datasheet de lm3s9B96.pdf)
		; ;;									
		ldr r9, = SYSCTL_PERIPH_GPIO  			;; RCGC2
        mov r0, #0x00000038  					;; Enable clock sur GPIO D et F où sont branchés les leds (0x28 == 0b111000)
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
		
		
		
CHOOSE_TIME
		ldr r10,[r7]
		CMP r10,#0x80
		BEQ FIRST_SELECTED
		B CHOOSE_TIME
UP_BUTTON 
		ldr r10, [r7]
		CMP r10,#0xC0
		BEQ CHOOSE_SPEED
		B UP_BUTTON
		
CHOOSE_SPEED
		ldr r10,[r7]
		CMP r10,#0x80
		BEQ SECOND_SELECTED
		CMP r10,#0x40
		BEQ avanceVoit
		B CHOOSE_SPEED
		
FIRST_SELECTED
		BL TURN_ON_LEFT
		B UP_BUTTON

SECOND_SELECTED
		BL TURN_ON_BOTH
		LDR r1, =DUREELed
		B WAIT_BOTH_SPEED
		
WAIT_BOTH_SPEED
		SUB r1, #1
		CMP r1, #0
		BEQ WAIT_LEFT_SPEED
		B WAIT_BOTH_SPEED
WAIT_LEFT_SPEED
		BL TURN_ON_BOTH
		
		
		
		
		; Activer les deux moteurs droit et gauche
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
		ldr r4, =DUREEJeu
		;B END_OF_GAME
		
		
		;test clignotement


		

		; Boucle de pilotage des 2 Moteurs (Evalbot tourne sur lui même)



avanceVoit	
		; Evalbot avance droit devant
		subs r4, #1
		cmp r4, #0
		BLE END_OF_GAME
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_AVANT
		
		
		b readBumper



;; Boucle d'attante pour reculer
TIMERRecule ldr r1, = DUREERecule
AuxtimerRecule 
		subs r4, #1
		subs r1, #1
		cmp r1, #0
        bne AuxtimerRecule
		cmp r2, #1
		BEQ repriseReculeBumperGauche
		b repriseReculeBumperDroit
		
TIMERTourne ldr r1, = DUREETourne
AuxtimerTourne 
		subs r4, #1
		subs r1, #1
		cmp r1, #0
        bne AuxtimerTourne
		cmp r2, #1
		BEQ repriseTourneBumperGauche
		b repriseTourneBumperDroit

actionBumperGauche
		mov r2, #1
		BL	MOTEUR_DROIT_ARRIERE	   
		BL	MOTEUR_GAUCHE_ARRIERE
		BL  TURN_ON_BOTH
		b TIMERRecule
		
repriseReculeBumperGauche
		BL	MOTEUR_DROIT_OFF	   
		BL	MOTEUR_GAUCHE_AVANT
		BL	TURN_OFF_BOTH
		BL	TURN_ON_RIGHT
		b TIMERTourne
		
repriseTourneBumperGauche
		BL	TURN_OFF_BOTH
		BL  MOTEUR_DROIT_ON
		b avanceVoit

actionBumperDroit
		mov r2, #2
		BL	MOTEUR_DROIT_ARRIERE	   
		BL	MOTEUR_GAUCHE_ARRIERE
		BL  TURN_ON_BOTH
		b TIMERRecule
		
repriseReculeBumperDroit
		BL	MOTEUR_GAUCHE_OFF	   
		BL	MOTEUR_DROIT_AVANT
		BL	TURN_OFF_BOTH
		BL	TURN_ON_LEFT
		b TIMERTourne
		
repriseTourneBumperDroit
		BL  TURN_OFF_BOTH
		BL  MOTEUR_GAUCHE_ON
		b avanceVoit
		
		
		
		
		
		

		

readSwitcher
		ldr r10,[r7]
		CMP r10,#0x80							;;0x01 = bumber gauche , 0x02 = bumber droit
		BEQ actionBumperGauche
		CMP r10,#0x40
		BEQ actionBumperDroit
		b avanceVoit


readBumper
		ldr r10,[r8]
		CMP r10,#0x01							;;0x01 = bumber gauche , 0x02 = bumber droit
		BEQ actionBumperGauche
		CMP r10,#0x02
		BEQ actionBumperDroit
		b avanceVoit
		
END_OF_GAME
			BL MOTEUR_GAUCHE_ON
			BL MOTEUR_GAUCHE_AVANT
			BL MOTEUR_DROIT_ON
			BL MOTEUR_DROIT_ARRIERE
loop
			BL TURN_ON_LEFT
			ldr r1, = DUREE 

wait_left	subs r1, #1
			bne wait_left

			BL TURN_ON_RIGHT 	
			ldr r1, = DUREE	

wait_right  subs r1, #1
			bne wait_right

			b loop 
		
		
		
		NOP
        END
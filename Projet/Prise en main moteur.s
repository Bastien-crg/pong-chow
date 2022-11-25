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

DUREELed   				EQU     0x2FF
DUREERecule   			EQU     0xAFFFF	;0xAFFFFF
DUREETourne				EQU		0xAFFFF	;0xAFFFFF

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
		
		; Activer les deux moteurs droit et gauche
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON


		;test clignotement

		;BL BLINK_BOTH_LED

		; Boucle de pilotage des 2 Moteurs (Evalbot tourne sur lui même)
		
avanceVoit	
		; Evalbot avance droit devant
		
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_AVANT
		
		
		; Avancement pendant une période (deux WAIT)
		;BL	WAIT	; BL (Branchement vers le lien WAIT); possibilité de retour à la suite avec (BX LR)
		;BL	WAIT
		; Rotation à droite de l'Evalbot pendant une demi-période (1 seul WAIT)
		b readBumper



;; Boucle d'attante pour reculer
TIMERRecule ldr r1, = DUREERecule
AuxtimerRecule subs r1, #1
		BL TURN_ON_BOTH
		ldr r4, = DUREELed 
TimerLed1	subs r4, #1
			bne TimerLed1
		BL TURN_OFF_BOTH
		BL TURN_ON_BOTH
		cmp r1, #0
        bne AuxtimerRecule
		cmp r2, #1
		BEQ repriseReculeBumperGauche
		b repriseReculeBumperDroit
		
TIMERTourne ldr r1, = DUREETourne
AuxtimerTourne subs r1, #1
		BL TURN_OFF_BOTH
		ldr r4, = DUREELed 
TimerLed	subs r4, #1
			bne TimerLed
		BL TURN_ON_BOTH
		cmp r1, #0
        bne AuxtimerTourne
		cmp r2, #1
		BEQ repriseTourneBumperGauche
		b repriseTourneBumperDroit

actionBumperGauche
		mov r2, #1
		BL	MOTEUR_DROIT_ARRIERE	   
		BL	MOTEUR_GAUCHE_ARRIERE
		b TIMERRecule
repriseReculeBumperGauche
		BL	MOTEUR_DROIT_OFF	   
		BL	MOTEUR_GAUCHE_AVANT
		b TIMERTourne
repriseTourneBumperGauche
		BL	TURN_OFF_BOTH
		BL  MOTEUR_DROIT_ON
		b avanceVoit

actionBumperDroit
		mov r2, #2
		BL	MOTEUR_DROIT_ARRIERE	   
		BL	MOTEUR_GAUCHE_ARRIERE
		b TIMERRecule
repriseReculeBumperDroit
		BL	MOTEUR_GAUCHE_OFF	   
		BL	MOTEUR_DROIT_AVANT
		b TIMERTourne
repriseTourneBumperDroit
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
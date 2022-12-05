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
DUREEJeu				EQU 	0x43FFFF	;0x43FFFF

TEMPSMax				EQU		0x43FFFFF
TEMPSMin				EQU		0xBBFFFF

VITESSE1				EQU 	0x1B2
VITESSE2				EQU 	0xFC
VITESSE3				EQU 	0xE2
VITESSE4				EQU 	0x8F
VITESSEMax				EQU		0xF



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
		BL 	LED_INIT

		ldr r4, =TEMPSMin
		
CHOOSE_TIME
		MOV r5, #0 ; prepare r5 for the speed
		ldr r10,[r7] ;load button state in r10
		CMP r10,#0x80 ; if button pull go to UP_BUTTON
		BEQ UP_BUTTON
		B chooseTime_Aux
		
chooseTime_Aux
		ldr r10, =TEMPSMax
		cmp r4, r10
		bhs resetGameTime ;si le temps de jeu est plus grand que le temp max
		add r4, #10
		b CHOOSE_TIME

resetGameTime
		ldr r4, =TEMPSMin
		b CHOOSE_TIME

UP_BUTTON 
		BL TURN_ON_LEFT ; turn on left led
		ldr r10, [r7] ;load button state in r10
		CMP r10,#0xC0 ; if both are up go to CHOOSE_SPEED
		BEQ CHOOSE_SPEED
		B UP_BUTTON
		
CHOOSE_SPEED
		ldr r10,[r7] ;load button state in r10
		CMP r10,#0x80 ; if button pull go to SPEED_SELECTOR
		BEQ SPEED_SELECTOR
		CMP r10,#0x40
		BEQ INIT_SPEED
		B CHOOSE_SPEED

SPEED_SELECTOR
		ADD r5, #1
		CMP r5, #5
		BEQ BACK_TO_ONE
load_r12		
		MOV r12, r5
		B BLINK_LOOP_r12
end_loop
		B UP_BUTTON


BACK_TO_ONE
		MOV r5, #1
		B load_r12		
		
BLINK_LOOP_r12
			CMP r12, #0
			BEQ end_loop
			SUBS r12, #1
			BL TURN_ON_BOTH
			ldr r1, = DUREELed 

both_light	subs r1, #1
			bne both_light

			BL TURN_ON_LEFT 	
			ldr r1, = DUREELed

left_light  subs r1, #1
			bne left_light

			b BLINK_LOOP_r12 	
		
		;test clignotement

INIT_SPEED
		cmp r5, #1
		BEQ load_vitesse1
		cmp r5, #2
		BEQ load_vitesse2
		cmp r5, #3
		BEQ load_vitesse3
		cmp r5, #4
		BEQ load_vitesse4	

load_vitesse1
		ldr r5, =VITESSE1
		b INIT_GAME
		
load_vitesse2
		ldr r5, =VITESSE2
		b INIT_GAME

load_vitesse3
		ldr r5, =VITESSE3
		b INIT_GAME

load_vitesse4
		ldr r5, =VITESSE4
		b INIT_GAME
		
INIT_GAME
		BL  TURN_OFF_BOTH
		BL	MOTEUR_INIT
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
		b avanceVoit

		; Boucle de pilotage des 2 Moteurs (Evalbot tourne sur lui même)

RECULE_et_VITESSE
		ldr r10, =VITESSEMax
		cmp r5, r10
		bls resetSpeed 
		subs r5, #40
		BL	MOTEUR_INIT	
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
		BL	MOTEUR_DROIT_ARRIERE	   
		BL	MOTEUR_GAUCHE_ARRIERE
		BL  TURN_ON_BOTH
		b TIMERRecule


resetSpeed
		ldr r5, =VITESSE1
		b RECULE_et_VITESSE

avanceVoit
		; Evalbot avance droit devant
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
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
		cmp r2, #0x01
		BEQ repriseReculeBumperGauche
		b repriseReculeBumperDroit
		
TIMERTourne ldr r1, = DUREETourne
AuxtimerTourne 
		subs r4, #1
		subs r1, #1
		cmp r1, #0
        bne AuxtimerTourne
		cmp r2, #0x01
		BEQ repriseTourneBumperGauche
		b repriseTourneBumperDroit

		
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

readBumper
		ldr r10,[r8]
		mov r2 ,r10					;;0x01 = bumber gauche , 0x02 = bumber droit
		CMP r10,#0x01							
		BEQ RECULE_et_VITESSE
		CMP r10,#0x02
		BEQ RECULE_et_VITESSE
		b avanceVoit
		
END_OF_GAME
			ldr r5, =VITESSEMax
			BL	MOTEUR_INIT
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
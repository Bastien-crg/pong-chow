GPIO_PORTF_BASE		EQU		0x40025000	; GPIO Port F (APB) base: 0x4002.5000 (p416 datasheet de lm3s9B92.pdf)
BROCHE4_5			EQU		0x30		; led1 & led2 sur broche 4 et 5
	
		; configure the corresponding pin to be an output
		; all GPIO pins are inputs by default
GPIO_O_DIR   		EQU 	0x00000400  ; GPIO Direction (p417 datasheet de lm3s9B92.pdf)
	
		; Digital enable register
		; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN  		EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

		; The GPIODR2R register is the 2-mA drive control register
		; By default, all GPIO pins have 2-mA drive.
GPIO_O_DR2R   		EQU 	0x00000500  ; GPIO 2-mA Drive Select (p428 datasheet de lm3s9B92.pdf)
	
DUREE   			EQU     0x002FFFFF
BOTH_LED			EQU		48
LEFT_LED			EQU		32
RIGHT_LED			EQU		16
NO_LED				EQU		0	

		AREA    |.text|, CODE, READONLY
		ENTRY
		
		;; The EXPORT command specifies that a symbol can be accessed by other shared objects or executables.
		EXPORT	LED_INIT
		EXPORT	TURN_ON_BOTH
		EXPORT 	TURN_OFF_BOTH
		EXPORT 	TURN_ON_LEFT
		EXPORT 	TURN_ON_RIGHT

		
LED_INIT
        ldr r9, = GPIO_PORTF_BASE+GPIO_O_DIR    ;; 1 Pin du portF en sortie (broche 4 : 00010000)
        ldr r0, = BROCHE4_5 	
        str r0, [r9]
		
		ldr r9, = GPIO_PORTF_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE4_5		
        str r0, [r9]
		
		ldr r9, = GPIO_PORTF_BASE+GPIO_O_DR2R	;; Choix de l'intensité de sortie (2mA)
        ldr r0, = BROCHE4_5			
        str r0, [r9]
     
		; allumer la led broche 4 (BROCHE4_5)
		mov r3, #BROCHE4_5		;; Allume LED1&2 portF broche 4&5 : 00110000
		
		ldr r9, = GPIO_PORTF_BASE + (BROCHE4_5<<2)  ;; @data Register = @base + (mask<<2) ==> LED1
		BX LR
		
			
TURN_ON_BOTH
		ldr r3, =BOTH_LED
		str r3, [r9]  							;; Allume LED1&2 portF broche 4&5 : 00110000
		BX LR
		
TURN_OFF_BOTH
		ldr r3, =NO_LED
		str r3, [r9]  							;; Eteint LED  
		BX LR		

TURN_ON_LEFT
		ldr r3, =LEFT_LED
		str r3, [r9]  							;; Allume LED1&2 portF broche 4&5 : 00110000 
		BX LR
		
TURN_ON_RIGHT
		ldr r3, =RIGHT_LED
		str r3, [r9]  							  
		BX LR	
					
		nop		
		END 


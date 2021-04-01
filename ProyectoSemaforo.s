; Documento: 
; Dispositivo: PIC16F887
; Autor: Juan Antonio Peneleu Vásquez 
; Programa: semaforo
; Creado: 30 febrereo, 2021
;-----------------------------------
PROCESSOR 16F887
#include <xc.inc>

; configuración word1
 CONFIG FOSC=INTRC_NOCLKOUT //Oscilador interno sin salidas
 CONFIG WDTE=OFF	    //WDT disabled (reinicio repetitivo del pic)
 CONFIG PWRTE=ON	    //PWRT enabled (espera de 72ms al iniciar
 CONFIG MCLRE=OFF	    //pin MCLR se utiliza como I/O
 CONFIG CP=OFF		    //sin protección de código
 CONFIG CPD=OFF		    //sin protección de datos
 
 CONFIG BOREN=OFF	    //sin reinicio cuando el voltaje baja de 4v
 CONFIG IESO=OFF	    //Reinicio sin cambio de reloj de interno a externo
 CONFIG FCMEN=OFF	    //Cambio de reloj externo a interno en caso de falla
 CONFIG LVP=ON		    //Programación en bajo voltaje permitida
 
;configuración word2
  CONFIG WRT=OFF	//Protección de autoescritura 
  CONFIG BOR4V=BOR40V	//Reinicio abajo de 4V 

 MODO	EQU 0
 INC	EQU 1
 DECRE	EQU 2
	
reiniciar_Tmr0 macro	//macro
    banksel TMR0	//Banco de TMR0
    movlw   25
    ;movf    T0_Actual, W
    movwf   TMR0        
    bcf	    T0IF	//Limpiar bandera de overflow para reinicio 
    endm
reiniciar_Tmr1 macro	//macro reiniciar Tmr1
    movlw   0x0B	//1 segundo
    movwf   TMR1H	//Asignar valor a TMR1H
    movlw   0xDC
    movwf   TMR1L	//Asignar valor a TMR1L
    bcf	    TMR1IF	//Limpiar bandera de carry/interrupción de Tmr1
    endm
reiniciar_tmr2 macro	//Macro reinicio Tmr2
    banksel PR2
    movlw   244		//Mover valor a PR2
    movwf   PR2		
    
    banksel T2CON
    clrf    TMR2	//Limpiar registro TMR2
    bcf	    TMR2IF	//Limpiar bandera para reinicio 
    endm
    
  PSECT udata_bank0 ;common memory
    cont:	DS  1
    var:	DS  1 ;1 byte apartado
    displayvar2:    DS	2;
    banderas:	DS  1
    nibble:	DS  2
    display_var:    DS	2
    centena:	DS  1
    centena1:	DS  1
    decena:	DS  1
    decena1:	DS  1
    unidad1:	DS  1
    unidad:	DS  1  
    valor_actual:   DS	1
  
    V2:		DS  1
    centena2:	DS  1
    centena22:	DS  1
    decena2:	DS  1
    decena22:	DS  1
    unidad2:	DS  1
    unidad22:	DS  1  
    
    cont_small: DS  1;1 byte
    cont_big:	DS  1
  
    V1:		DS  1
    Tmr0_temporal:   DS	1
    Tmr0_semitemporal:	DS  1
    T0_Actual:	    DS	1
    estado:	DS  1
    valorsemaforo_1: DS	1
    semaforo1:	DS 1
    display_semaforo1:	DS  1
  PSECT udata_shr ;common memory
    w_temp:	DS  1;1 byte apartado
    STATUS_TEMP:DS  1;1 byte
    PCLATH_TEMP:    DS	1
  
  PSECT resVect, class=CODE, abs, delta=2
  ;----------------------vector reset------------------------
  ORG 00h	;posición 000h para el reset
  resetVec:
    PAGESEL main
    goto main
    
  PSECT intVect, class=CODE, abs, delta=2
  ;----------------------interripción reset------------------------
  ORG 04h	;posición 0004h para interr
  push:
    movf    w_temp
    swapf   STATUS, W
    movwf   STATUS_TEMP
    movf    PCLATH, W
    movwf   PCLATH_TEMP
  isr:
    btfsc   RBIF
    call    int_ioCB
    
    btfsc   T0IF
    call    Interr_Tmr0
  pop:
    movf    PCLATH_TEMP, W
    movwf   PCLATH
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   w_temp, F
    swapf   w_temp, W
    retfie
;---------SubrutinasInterrupción-----------
Interr_Tmr0:
    reiniciar_Tmr0	;2 ms
    bcf	    STATUS, 0	    ;Dejo el STATUS 0 en un valor de 0
    clrf    PORTD	    ;Limpio el puerto D
    btfsc   banderas, 1	    ;Revisar bit 1 de banderas
    goto    displayunidad   ;Llamar a subrutina de displayunidad	    ;
    btfsc   banderas, 2	    ;Revisar bit 2 de banderas
    goto    displaydecena   ;Llamar a subrutina de displaydecena
    btfsc   banderas, 3	    ;Revisar bit 2 de banderas
    goto    displayunidad_SE1   ;Llamar a subrutina de displaydecena
    btfsc   banderas, 4	    ;Revisar bit 2 de banderas
    goto    displaydecen_SE1   ;Llamar a subrutina de displaydecena
    movlw   00000001B
    movwf   banderas	    ;Mover literal a banderas
siguientedisplay:
    RLF	    banderas, 1	    ;Rota a la izquierda los bits de variable banderas
    return
displayunidad_SE1:
    movf    unidad22, w	    //Mover el valor de centena1 (Tabla) a w
    movwf   PORTC	    //Mover w a PORTD
    bsf	    PORTD, 7	    //Encender bit4 de PORTB para transistor 
    goto    siguientedisplay
displaydecen_SE1:
    movf    decena22, w	    //Mover el valor de centena1 (Tabla) a w
    movwf   PORTC	    //Mover w a PORTD
    bsf	    PORTD, 6	    //Encender bit4 de PORTB para transistor 
    goto    siguientedisplay
displaydecena:
    movf    decena1, w	    //Mover el valor de decena1(Tabla) a w
    movwf   PORTC	    //Mover el valor de w a PORTD
    bsf	    PORTD, 0	    //Encender bit 5 PORTB para transistor
    goto    siguientedisplay	//Siguiente display
displayunidad:
    movf    unidad1, w	    //Mover el valor de Unidad1(Tabla) a w
    movwf   PORTC	    //mover el valor de w a PORTD
    bsf	    PORTD, 1	    //Encender bit 5 de PORTB para transistor
    goto    siguientedisplay	//Siguiente display

int_ioCB: 
    movf    estado, W
    clrf    PCLATH		
    andlw   0x03
    addwf   PCL
    goto    interrup_estado_0
    goto    interrup_estado_1
    goto    interrup_estado_2; 0
 interrup_estado_0:
    banksel PORTB
    btfsc   PORTB, MODO
    goto    finalIOC
    incf    estado
    movf    T0_Actual, W
    movwf   Tmr0_temporal
    goto    finalIOC
 
 interrup_estado_1:
    btfss   PORTB, INC
    incf    Tmr0_temporal, 1   ;se guarda en mismo registro 
    movlw   21
    subwf   Tmr0_temporal, 0
    btfsc   STATUS, 2
    goto    valor_minSemaforo1
    
    btfss   PORTB, DECRE
    decf    Tmr0_temporal, 1
    movlw   9
    subwf   Tmr0_temporal, 0
    btfsc   STATUS, 2
    goto    valor_maxSemaforo1
    
    btfss   PORTB, MODO
    incf    estado
    goto    finalIOC    
 interrup_estado_2:
    btfss   PORTB, DECRE
    clrf    estado
    btfsc   PORTB, INC
    goto    finalIOC
    movf    Tmr0_temporal, W
    movwf   T0_Actual
    movf    T0_Actual, W
    movwf   semaforo1
    clrf    estado
 finalIOC:
    bcf	    RBIF
    return
valor_minSemaforo1:
    movlw   10
    movwf   Tmr0_temporal
    bcf	    RBIF
    return
valor_maxSemaforo1:
    movlw   20
    movwf   Tmr0_temporal
    bcf	    RBIF
    return
    
  PSECT code, delta=2, abs
  ORG 100h	;Posición para el código
 ;------------------ TABLA -----------------------
  Tabla:
    clrf  PCLATH
    bsf   PCLATH,0
    andlw 0x0F
    addwf PCL
    retlw 00111111B          ; 0
    retlw 00000110B          ; 1
    retlw 01011011B          ; 2
    retlw 01001111B          ; 3
    retlw 01100110B          ; 4
    retlw 01101101B          ; 5
    retlw 01111101B          ; 6
    retlw 00000111B          ; 7
    retlw 01111111B          ; 8
    retlw 01101111B          ; 9
    retlw 01110111B          ; A
    retlw 01111100B          ; b
    retlw 00111001B          ; C
    retlw 01011110B          ; d
    retlw 01111001B          ; E
    retlw 01110001B          ; F
  ;---------------configuración------------------------------
  main: 
    call    config_io	
    call    config_reloj
    call    config_IOChange
    call    config_tmr0
    call    config_tmr1
    call    config_tmr2
    call    config_InterrupEnable  
    banksel PORTA 
    movlw   0x0F
    movwf   T0_Actual
    movf    T0_Actual, W
    movwf   semaforo1
    bsf	    PORTA, 0
    bcf	    PORTA, 1
    clrf    estado
;----------loop principal---------------------
 loop:
    btfss   TMR1IF	    ;Funcionamiento semaforo1 
    goto    $-1
    reiniciar_Tmr1
    decf    semaforo1, 1    ;Guardar en mismo registro  
    btfsc   STATUS, 2
    call    asignarvalor
    movlw   7
    subwf   semaforo1, 0	;Guarda en w
    btfss   STATUS, 0
    call    titileo_semaforo1
    
    movlw   4
    subwf   semaforo1, 0	;Guarda en w
    btfss   STATUS, 0
    call    amarillo_semaforo1
    
    movf    semaforo1, w    ;Displays semaforo1
    movwf   V1
    call    divcentenas	
    call    displaydecimal
       
    bcf	    GIE
    movf    estado, W
    clrf    PCLATH
    bsf	    PCLATH, 0
    andlw   0x03
    addwf   PCL
    goto    estado_0
    goto    estado_1
    goto    estado_2
 estado_0:
    bsf	    GIE
    clrf    valor_actual    
    movlw   001B
    movwf   PORTE   
    goto    loop    ;loop forever
 estado_1:
    bsf	    GIE
    movf    Tmr0_temporal, w
    movwf   V2
    call    divcentenas_SE1	//Subrutina de división para contador DECIMAL 
    call    displaydecimal_SE1
    movlw   010B
    movwf   PORTE
    goto    loop
 estado_2:
    bsf	    GIE
    movlw   100B
    movwf   PORTE
    goto    loop
;------------sub rutinas---------------------
amarillo_semaforo1:
    bcf	    PORTA, 0
    bsf	    PORTA, 1
    bcf	    PORTA, 2
    return
titileo_semaforo1: 
    bsf	    PORTA, 0
    btfss   TMR2IF	    ;Funcionamiento semaforo1 
    bcf	    PORTA, 0
    reiniciar_tmr2
    bsf	    PORTA, 0
    return
asignarvalor:
    bsf	    PORTA, 0
    bcf	    PORTA, 1
    bcf	    PORTA, 2
    movf    T0_Actual, W
    movwf   semaforo1
    return
;------------------DivisiónRutinaPrincipal-------------------
displaydecimal:
    movf    centena, w
    call    Tabla   //Asignamos el valor de centena a un valor de la tabla displays
    movwf   centena1	//Lo guardamos en variable centena1
    movf    decena, w	
    call    Tabla   //Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena1	//Lo guardamos en variable decena1
    movf    unidad, w
    call    Tabla   //Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad1	//Lo guardamos en variable unidad1
    return
divcentenas:
    clrf    centena	 //Limpiamos la variable centena 
    movlw   01100100B    //asignamos EL VALOR DE "100" W
    subwf   V1, 1	 //resta f DE w(ValorPORTA-100) y guardamos de nuevo en V1
    btfss   STATUS,0	 //Revisamos bandera de carry de Status (Indica un cambio de signo en la resta)
    goto    DECENAS	 //llama a subrutina para resta en decena
    incf    centena, 1	 //Incrementa el valor de centena y se guarda en ella misma
    goto    $-5		 //Regresa 5 líneas atras y resta nuevamente 
DECENAS:
    clrf    decena	//Limpiamo variable decena
    movlw   01100100B	 
    addwf   V1		//Sumamos 100 a V1 (Para que sea el valor ultimo correcto)
    movlw   00001010B	//Valor de 10 a w   
    subwf   V1,1	//Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	//Revisamo bit de carry Status
    goto    UNIDADES	//Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena, 1	//Incrementa variable decena 
    goto    $-5		//Ejecuta resta en decenas 
UNIDADES:
    clrf    unidad	//Limpiamos variable unidad
    movlw   00001010B	
    addwf   V1		//Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	//Valor de 1 a w
    subwf   V1,1	//Restamos f-w y guardamos en V1
    btfss   STATUS, 0	//Revisar bit carry de status
    return		//Return a donde fue llamado
    incf    unidad, 1	//Incrementar variable unidad
    goto    $-5		//Ejecutar de nuevo resta de unidad 
    
;---------------------------RutinaSemaforo1---------------------------
displaydecimal_SE1:
    movf    centena2, w
    call    Tabla   //Asignamos el valor de centena a un valor de la tabla displays
    movwf   centena22	//Lo guardamos en variable centena1
    movf    decena2, w	
    call    Tabla   //Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena22	//Lo guardamos en variable decena1
    movf    unidad2, w
    call    Tabla   //Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad22	//Lo guardamos en variable unidad1
    return
divcentenas_SE1:
    clrf    centena2	 //Limpiamos la variable centena 
    movlw   01100100B    //asignamos EL VALOR DE "100" W
    subwf   V2, 1	 //resta f DE w(ValorPORTA-100) y guardamos de nuevo en V1
    btfss   STATUS,0	 //Revisamos bandera de carry de Status (Indica un cambio de signo en la resta)
    goto    DECENAS_SE1	 //llama a subrutina para resta en decena
    incf    centena2, 1	 //Incrementa el valor de centena y se guarda en ella misma
    goto    $-5		 //Regresa 5 líneas atras y resta nuevamente 
DECENAS_SE1:
    clrf    decena2	//Limpiamo variable decena
    movlw   01100100B	 
    addwf   V2		//Sumamos 100 a V1 (Para que sea el valor ultimo correcto)
    movlw   00001010B	//Valor de 10 a w   
    subwf   V2,1	//Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	//Revisamo bit de carry Status
    goto    UNIDADES_SE1	//Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena2, 1	//Incrementa variable decena 
    goto    $-5		//Ejecuta resta en decenas 
UNIDADES_SE1:
    clrf    unidad2	//Limpiamos variable unidad
    movlw   00001010B	
    addwf   V2		//Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	//Valor de 1 a w
    subwf   V2,1	//Restamos f-w y guardamos en V1
    btfss   STATUS, 0	//Revisar bit carry de status
    return		//Return a donde fue llamado
    incf    unidad2, 1	//Incrementar variable unidad
    goto    $-5		//Ejecutar de nuevo resta de unidad 
    
config_IOChange:
    banksel TRISA
    bsf	    IOCB, MODO
    bsf	    IOCB, INC
    bsf	    IOCB, DECRE
    
    banksel PORTA
    movf    PORTB, W	;Condición mismatch
    return
config_io:
    bsf	    STATUS, 5   ;banco  11
    bsf	    STATUS, 6	;Banksel ANSEL
    clrf    ANSEL	;pines digitales
    clrf    ANSELH
    
    bsf	    STATUS, 5	;banco 01
    bcf	    STATUS, 6	;Banksel TRISA
    clrf    TRISA	;PORTA A salida
    clrf    TRISC
    clrf    TRISD
    clrf    TRISE
    bsf	    TRISB, MODO
    bsf	    TRISB, INC
    bsf	    TRISB, DECRE
    
    bcf	    OPTION_REG,	7   ;RBPU Enable bit - Habilitar
    bsf	    WPUB, MODO
    bsf	    WPUB, INC
    bsf	    WPUB, DECRE
    
    bcf	    STATUS, 5	;banco 00
    bcf	    STATUS, 6	;Banksel PORTA
    clrf    PORTA	;Valor incial 0 en puerto A
    clrf    PORTC
    clrf    PORTB
    clrf    PORTD
    return
    
 config_tmr0:
    banksel OPTION_REG   ;Banco de registros asociadas al puerto A
    bcf	    T0CS    ; reloj interno clock selection
    bcf	    PSA	    ;Prescaler 
    bcf	    PS2
    bcf	    PS1
    bsf	    PS0	    ;PS = 111 Tiempo en ejecutar , 256
    
    reiniciar_Tmr0  ;Macro reiniciar tmr0
    return
    
 config_tmr1:
    banksel T1CON
    bcf	    TMR1GE	;tmr1 como contador
    bcf	    TMR1CS	;Seleccionar reloj interno (FOSC/4)
    bsf	    TMR1ON	;Encender Tmr1
    bcf	    T1OSCEN	;Oscilador LP apagado
    bsf	    T1CKPS1	;Preescaler 10 = 1:4
    bcf	    T1CKPS0 
    
    reiniciar_Tmr1
    return

 config_tmr2:
    banksel T2CON
    bsf	    T2CON, 7 
    bsf	    TMR2ON
    bsf	    TOUTPS3	;Postscaler 1:16
    bsf	    TOUTPS2
    bsf	    TOUTPS1
    bsf	    TOUTPS0
    bsf	    T2CKPS1	;Preescaler 1:16
    bsf	    T2CKPS0
    
    reiniciar_tmr2
    return
    
 config_reloj:
    banksel OSCCON	;Banco OSCCON 
    bsf	    IRCF2	;OSCCON configuración bit2 IRCF
    bcf	    IRCF1	;OSCCON configuracuón bit1 IRCF
    bcf	    IRCF0	;OSCCON configuración bit0 IRCF
    bsf	    SCS		;reloj interno , 1Mhz
    return
    
config_InterrupEnable:
    bsf	    GIE		;Habilitar en general las interrupciones, Globales
    bsf	    RBIE	;Se encuentran en INTCON
    bcf	    RBIF	;Limpiamos bandera
    bsf	    T0IE	;Habilitar bit de interrupción tmr0
    bcf	    T0IF	;Limpiamos bandera de overflow de tmr0
    return
 
end

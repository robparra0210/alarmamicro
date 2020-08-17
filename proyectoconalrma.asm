;Proyecto de microprocesadores I 
;Perido academico 2018B, Universidad Rafael Urdaneta
;
;	
;Realizado Por
;Roberto Parra
;Grisbel Mejias
;Andres  Hurtado	
;Jesus   Duran	
;Eduardo  Gonzalez
;
;

	__CONFIG _CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC
						
	PROCESSOR 16F84A
	#INCLUDE <P16F84A.INC>
	
	CBLOCK 0x0C
	segundos
	cuenta
	cont1
	cont2
	cont_1
	cont_2
	minutos
	BCDcentenas
	BCDdecenas
	BCDunidades
	minutoss
	wtemp
	ENDC
				
	ORG 		0x00			;Establece el origen del programa
	
;Configuración de puertos:

	bsf		STATUS, RP0					;Acceso al banco 1
	movlw	b'00011100' 				;mueve el valor binario 00011100 al registro de trabajo
	movwf	TRISA						;Configura RA0 como entrada
	clrf	TRISB						;Configura el Puerto B como salida
	bcf		STATUS, RP0					;Acceso al banco 0
	
;Programa principal:

	clrf	cuenta						;Borra el registro para la cuenta
	clrf	PORTB						;Borra el Puerto B al inicio
	movlw	d'0'						;se mueve un cero decimal al registro de trabajo para comenzar la secuencia de reloj en 000
	movwf	cuenta						
	call	BINaBCD						;Conviértelo a BCD
	movf	BCDunidades, W				;Pasa las unidades a W
	call	siete_seg					;Obtén el código de 7 segmentos		
	movwf	PORTB						;Envíala al Puerto B
	call	retardo	

inicio
	call 	aumenta						;llama a la subrutina aumenta
	call	BINaBCD						;Conviértelo a BCD
	movf	BCDunidades, W				;Pasa las unidades a W
	call	siete_seg					;Obtén el código de 7 segmentos		
	movwf	PORTB						;Envíala al Puerto B
	call	retardo						;llama a un retardo
	btfss	PORTA, 2					;verifica el estado del pulsador conectado al primer pin
	call	pulsadores					;Si ha sido apretado llama a la subrutina pulsadores
	call	verificacionseg				;No, llama a la verificacionseg
	call	display						;llama la subrutina disply
    goto	inicio						;Se regresa al incion y entra en un bucle
    
aumenta									;Subrutina encargada del aumento de los valores del tiempo
	incf	cuenta, F					;Incrementa el valor de cuenta(segundos) en 1
	movlw	d'60'						;Mueve el valor decimal 60 ha W
	subwf	cuenta, W					;realiza un resta aritmetica entre el valor en cuenta y W y el valor lo guarda en W
	btfss	STATUS, Z					;Si la resta da 0, se enciende la badera de Z
	goto	finaumenta					;de no se 0 la resta llama a finaumenta para salir de la rutina
	clrf	cuenta						;como la resta da 0, se borra el valor de cuenta para comenzar de nuevo en el siguente llamado de aumenta
	incf	minutos, F					;incrementa el valor de minutos en 1
	movlw	d'10'						;Mueve el valor decimal 10 ha W
	subwf	minutos, W					;realiza un resta aritmetica entre el valor en minutos y W y el valor lo guarda en W
	btfsc	STATUS, Z					;¿minutos =10?	
	clrf	minutos						;Si, borra el valor de cuenta, no, prosigue con la siguiente instruccion
finaumenta
	return
	
display									;Subrutina para la salida de los display
   
	movf		cuenta, W				;Pasa el número de cuenta a W
	call		BINaBCD					;Conviértelo a BCD
	movf		BCDunidades, W			;Pasa las unidades a W
	call		siete_seg				;Obtén el código de 7 segmentos
	movwf		PORTB					;Envíalo al Puerto B
	bsf			PORTA, 0				;Habilita el display de unidades
	call		retardo_5ms				;Espera 5ms
	bcf			PORTA, 0				;Deshabilita display de unidades
	movf		BCDdecenas, W			;Pasa las decenas a W
	call		siete_seg				;Obtén el código de 7 segmentos
	movwf		PORTB					;Envíalo al Puerto B
	bsf			PORTA, 1				;Habilita el display de decenas
	call		retardo_5ms				;Espera 5ms
	bcf			PORTA, 1				;Deshabilita display de decenas
	movf		minutos, W				;Pasa el número de cuenta a W
	call		BINaBCD					;Conviértelo a BCD
	movf		minutos, W				;Pasa las unidades a W
	call		siete_seg				;Obtén el códgo de 7 segmentos
	movwf		PORTB					;Envíalo al Puerto B
	bsf			PORTB, 7				;Habilita el display de unidades
	call		retardo_5ms				;Espera 5ms
	bcf			PORTB, 7				;Deshabilita display de unidades
    return
    
	
pulsadores								;Monitoreo de los pulsadores, se invoca si el boton de alarma a sido accionado
	call	displayalarma				;se llama a displayalarma para mostrar en patalla el valor de la alarma guardada
	btfsc	PORTA, 2					;ha manera de una secuencia anti-rebotes se verifica que el boton sigue presionado
	return								;de no estarlo se retorna
	call	alarmaminutos				;de si estarlo se calla a la subrutina de alarma minutos
	call	alarmasegundos				;luego la de los segundos
	call	displayalarma				;muestra los valor de la alarma de nuevo en pantalla
	goto	pulsadores					;entra en un bucle hasta que el boton de la alarma haya sido desactivado
	
alarmaminutos							;Esta subrutina tiene el objetivo de verificar si se han aumentado los minutos en la alarma
	call	displayalarma				;Llama a la subrutina displayalarma
	btfss	PORTA, 3					;¿ha presionado el boton de los minutos?
	call	aumentaminutoss				;Si, ve aumenta minutoss
	return								;No, retorna

alarmasegundos							;Esta subrutina tiene el objetivo de verificar si se han aumentado los segundos en la alarma
	call	displayalarma				;Llama a la subrutina displayalarma
	btfss	PORTA, 4					;¿ha presionado el boton segundos?
	call	aumentasegundos				;Si, ve  aumenta el segundos
	return
	
	
aumentaminutoss							
	call	displayalarma				;Llama a la subrutina display
	btfsc	PORTA, 3					;¿Sigue pulsado	el boton de minutos?
	return								;no, me devuelvo a alarma
	incf	minutoss, F					;Si,Incremento los minutos
	movlw	d'10'						;guardo un 10 en W
	subwf	minutoss, W					
	btfsc	STATUS, Z					;¿minutos=10?
	clrf	minutoss					;limpio el valor en minutos
	call	retardo		
	call	displayalarma
	return
	
aumentasegundos
	call	displayalarma				;Llama a la subrutina display
	btfsc	PORTA, 4					;¿Sigue pulsado 1?
	return								;no, me devuelvo a alarma
	incf	segundos, F					;Si,Incrementa turno
	movlw	d'60'						;guardo un 60 en segundos
	subwf	segundos, W
	btfsc	STATUS, Z					;¿minutos=60?
	clrf	segundos	
	call	retardo
	call	displayalarma
	return
		
verificacionseg							;subrutina con objeto de comprobar si el valor guardado en la alarma y en el tiempo del reloj son la misma
	movwf	wtemp						;se guarda el en un registro temporal el valor que llevava hata ese momento w, para no ser afectad al retorno
	movf	segundos,W					;se guarda en w el valor de los segundos de la alarma
	subwf	cuenta, W					;se hace una resta entre el valor de la alarma y los segundos
	btfsc	STATUS, Z					;De ser 0, se activa la bandera Z
	goto	verificamin					;Si es 0, verifica el valor de los minutos
	movf	wtemp						;le da el valor origina a W, y retorna
	return 
	
verificamin								;subrutina con objeto de comprobar si el valor guardado en la alarma y en el tiempo del reloj son la misma
	movf	minutoss,W					;se hace una resta entre el valor de la alarma y los minutos 
	subwf	minutoss, W
	btfsc	STATUS, Z					;Si el valor es 0, se llama a la secuencia de alamr a
	call	display000
	movf	wtemp						
	return

display000								;secuncia de alarma, con retardo signifiativo en el valor de la alrma
	call	retardo
	call	retardo	
	call	retardo
	call	retardo	
	call	retardo
	call	retardo	
	call	retardo
	call	retardo	
	call	retardo
	call	retardo	
	call	retardo
	call	retardo	
	call	display	
	call	display	
	call	retardo
	call	retardo	
	call	retardo
	call	retardo	
	call	retardo
	call	retardo	
	call	retardo	
	call	retardo
	call	display	
	call	display	
	return
	
	

displayalarma							;Subrutina para la salida de los display
   
	movf		segundos, W				;Pasa el número de segundos a W
	call		BINaBCD					;Conviértelo a BCD
	movf		BCDunidades, W			;Pasa las unidades a W
	call		siete_seg				;Obtén el código de 7 segmentos
	movwf		PORTB					;Envíalo al Puerto B
	bsf			PORTA, 0				;Habilita el display de unidades
	call		retardo_5ms				;Espera 5ms
	bcf			PORTA, 0				;Deshabilita display de unidades
	movf		BCDdecenas, W			;Pasa las decenas a W
	call		siete_seg				;Obtén el código de 7 segmentos
	movwf		PORTB					;Envíalo al Puerto B
	bsf			PORTA, 1				;Habilita el display de decenas
	call		retardo_5ms				;Espera 5ms
	bcf			PORTA, 1				;Deshabilita display de decenas
	movf		minutoss, W				;Pasa el número de minutoss a W
	call		BINaBCD					;Conviértelo a BCD
	movf		minutoss, W				;Pasa las unidades a W
	call		siete_seg				;Obtén el código de 7 segmentos
	movwf		PORTB					;Envíalo al Puerto B
	bsf			PORTB, 7				;Habilita el display de unidades
	call		retardo_5ms				;Espera 5ms
	bcf			PORTB, 7				;Deshabilita display de unidades
    return
	

siete_seg					;Subrutina para convertir de BCD a 7 segmentos
	addwf	PCL, F
	
	DT		0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F	

retardo_5ms				;Subrutina de retardo aprox. 5ms
	movlw     .8       	
	movwf     cont_1     	
Loop1
	movlw     .207	
	movwf     cont_2 	
Loop2	
	decfsz    cont_2, 1	
	goto      Loop2    	
	decfsz    cont_1, 1	
	goto      Loop1	
	return	
	
retardo
	call	  display
	movlw     .8      	
	movwf     cont1
	call	  display   
Loop3
	movlw     .208
	movwf     cont2 
	call 	  display	
Loop4	
	decfsz    cont2, 1	
	goto      Loop4   	
	decfsz    cont1, 1	
	goto      Loop3	
	call	  display 
	return	
	
BINaBCD
	movwf		BCDunidades				;Mueve W al registro de unidades
	clrf		BCDcentenas	
borra_decenas
	clrf		BCDdecenas
convBCD
	movlw   	d'10'
	subwf		BCDunidades, F
	btfss		STATUS, C				;¿unidades < 10?
	goto		BCDfin		    		;Si, finaliza
	incf		BCDdecenas, F			;No, Suma una decena
	subwf		BCDdecenas, W
	btfss		STATUS, Z				;¿Se han acumulado 10 decenas?
	goto		convBCD				    ;No, continúa
	incf		BCDcentenas, F			;Si, incrementa las centenas
	goto		borra_decenas			;Y borra el valor de las decenas	
BCDfin
	addwf		BCDunidades, F			;Rcupera el valor de las unidades
	return				        		;Regresa
		
	END
	
.globl app
app:
	.equ BLANCO, 0x0000
	.equ NEGRO, 0xFFFF
	.equ VERDE, 0x07E0
	.equ LIMITE, 62
	.equ BORDER_UP, 4096
	.equ BORDER_DOWN, 4096
	
	//---------------- Inicialización GPIO --------------------

	mov w20, PERIPHERAL_BASE + GPIO_BASE     // Dirección de los GPIO.		
	// Configurar GPIO 17 como input:
	mov X21,#0
	str w21,[x20,GPIO_GPFSEL1] 		// Coloco 0 en Function Select 1 (base + 4)   	
	
	//---------------- Main code --------------------
	// X0 contiene la dirección base del framebuffer (NO MODIFICAR)
	
	add x10, x0, 0			// X10 contiene la dirección base del framebuffer
	mov w3, NEGRO  			// cargo el color negro en el registro w3 
	mov x7, 0  				// este lo usamos como "flag" para ir alternando entre blanco y negro 
	mov x12, BORDER_UP		// dejamos las primeras 8 filas de la pantalla para hacer el borde de arriba 
	bl borde				// vamos a pintar el borde 
	mov x6,8				// cantidad de filas
	
	
loop3:
	mov x5, LIMITE				// numero de pixeles de alto de cada cuadrado
	bl changecolor				// al final de cada fila de cuadrados alterno el color
loop2:
	mov x12, 8					// primeros 8 pixeles de la izq borde 
	bl borde					// va a pintar los primeros 8 pixeles con borde 
	mov x2,8         			// cuadrados por fila
loop1:
	mov x1,LIMITE        		// ancho del cuadrado
	bl changecolor				// al final de cada cuadrado dibujado alterno el color
loop0:
	sturh w3,[x10]	   			// setear el color del pixel N
	add x10,x10,2	   			// siguiente pixel
	sub x1,x1,1	   				// decrementar el contador de linea de cuadrado actual
	cbnz x1,loop0	   			// si no terminó la linea, pinta el siguiente pixel 
	sub x2,x2,1	   				// decrementar el contador de cuadrados por linea
	cbnz x2,loop1	  			// si no es el ultimo cuadrado de la linea, saltar
	mov x12, 8					// si es el ultimo cuadrado, preparo 8 pixeles para borde
	bl borde
	sub x5,x5,1	   				// decrementar el contador de pixeles de alto por fila de cuadrados
	cbnz x5,loop2	  			// si no es la última linea de pixeles de la fila, saltar
	sub x6,x6,1	   				// decrementar el contador de filas totales de cuadrados
	cbnz x6,loop3	  			// si no es la última fila, saltar
	mov x12, BORDER_DOWN		// 4 pixeles de alto borde abajo (4*512)
	bl borde
	// --- Delay loop ---
	movz x11, 0x10, lsl #16
	
delay1: 
	sub x11,x11,#1
	cbnz x11, delay1
	// --- Infinite Loop ---	
InfLoop: 
	b InfLoop

	
borde:
	mov w4, VERDE  		// como el borde es de otro color, cargamos el color verde en w4
	sturh w4,[x10]		// Setear el color verde del
	add x10,x10,2	   	// Pasa al siguiente pixel (le suma 2 porque se trata como un byte)
	sub x12,x12,1		// Va restando de a 1 la cantidad de pixeles a colorear 
	cbnz x12,borde		// Mientras no haya terminado de pintar el borde, vuelve al mismo bucle 
	ret					// Se retira. 
	
changecolor:
	cmp x7, 0
	beq changenegro
	b changeblanco

// cada vez que entra en alguna de estas dos subrutinas, se cambia el valor del registro x7
// el cual dijimos que actua como flag, para que, la proxima vez que salte en el codigo a la subrutina changecolor
// se cambie de color 

changenegro:
	mov w3, NEGRO
	mov x7, 1
	ret
	
changeblanco:
	mov w3, BLANCO  
	mov x7, 0
	ret
	
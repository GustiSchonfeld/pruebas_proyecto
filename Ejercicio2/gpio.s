//--------DEFINICIÓN DE FUNCIONES-----------//
.global inputRead
.global redOff
.global redOn
.global greenOff
.global greenOn
// DESCRIPCION: Lee el boton en el GPIO17.
//------FIN DEFINICION DE FUNCIONES-------//

.equ GPIO_GPSET0, 	0x1C
.equ GPIO_GPCLR0, 	0x28

.equ TOP, 0x04000
.equ RIGHT, 0x08000
.equ BOTTOM, 0x20000
.equ LEFT, 0x40000

/**
 * Lecutra de los estados de los botones.
 */
inputRead:
  ldr w2,[x29,GPIO_GPLEV0] // Leo el registro GPIO Pin Level 0 y lo guardo en X22
  and x5,x2, LEFT
  and x4,x2, BOTTOM // Limpio el bit 17 (estado del GPIO17)
  and x3,x2, RIGHT
  and x2,x2, TOP

  br x30

redOff:
  mov w2,#0b1000
  str w2,[x29,GPIO_GPSET0]
  br x30

redOn:
  mov w2,#0b1000
  str w2,[x29,GPIO_GPCLR0]
  br x30

greenOff:
  mov w2,#0b0100
  str w2,[x29,GPIO_GPSET0]
  br x30

greenOn:
  mov w2,#0b0100
  str w2,[x29,GPIO_GPCLR0]
  br x30

/* 
  [arriba] GPIO14 --> pin 8
  [derecha] GPIO15 --> pin 10
  [abajo] GPIO17 --> pin 11
  [izquierda] GPIO18 --> pin 12
  [led rojo] GPIO3 --> pin 3
  [led verde] GPIO2 --> pin 2
*/
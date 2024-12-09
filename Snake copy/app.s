.globl app
app:
  .equ TAM_CELL, 16 
  // Configuración de colores
  .equ RED, 0xF800
  .equ BLACK, 0x0000
  .equ GREEN, 0x07E0
  .equ BLUE, 0x001F
  // Configuración base del juego para el arreglo
  .equ EMPTY, 0x00
  .equ WALL, 0x01
  .equ HEAD, 0x02
  .equ TAIL, 0x03
  .equ APPLE, 0x04
  // Configuración movimientos
  .equ MOVE_RIGHT, 0x01
  .equ MOVE_LEFT, 0x02
  .equ MOVE_TOP, 0x03
  .equ MOVE_BOTTOM, 0x04

  //---------------- Inicialización GPIO --------------------

  mov w29, PERIPHERAL_BASE + GPIO_BASE // Dirección de los GPIO.

  // Configurar GPIO 21 como input:
  mov x21, #0
  str w21, [x29, GPIO_GPFSEL1] // Coloco 0 en Function Select 1 (base + 4)

  // Configuro GPIO 2 y 3 como Output (001 6-8 y 9-11)
  mov x21, #0x240
  str w21, [x29] // (direccion base)

//---------------- Main code --------------------
  // X0 contiene la dirección base del framebuffer (NO MODIFICAR)

  adr x1, grid

  bl greenOff
  bl redOff

  bl new_grid
  bl display_grid

  mov x6, MOVE_RIGHT //inicializador de movimiento 
  mov x8, 0x3000 //delay 
  mov x9, 464 //posicion de la cabeza 
  mov x10, 463 //posicion de la cola 
  adr x11, tail // puntero a la dirección de memoria de tail (tratamos como un arreglo)
  sturh w10, [x11, 0] //
  mov x12, 200

main_loop:
  sub x18, x6, MOVE_TOP
  cbz x18, moved_up

  sub x18, x6, MOVE_BOTTOM
  cbz x18, moved_down 

  sub x18, x6, MOVE_RIGHT
  cbz x18, moved_right 

  sub x18, x6, MOVE_LEFT
  cbz x18, moved_left 

refresh:
  bl display_grid
// --- Delay loop ---
  mov x19, x8 
  lsl x19, x19, #3
delay:
  bl inputRead

  sub x18, x2, TOP 
  cbz x18, do_move_up 

  sub x18, x3, RIGHT 
  cbz x18, do_move_right 

  sub x18, x4, BOTTOM  
  cbz x18, do_move_down

  sub x18, x5, LEFT 
  cbz x18, do_move_left 

keep_delay:
  sub x19, x19, #1
  cbnz x19, delay
  b main_loop

do_move_up:
  cmp x6, MOVE_BOTTOM //contemplamos el caso de que este yendo para abajo y quiera ir hacia arriba (no se puede)
  beq keep_delay
  mov x6, MOVE_TOP
  b keep_delay

do_move_down:
  //contemplamos el mismo caso siempre segun el movimiento 
  cmp x6, MOVE_TOP
  beq keep_delay
  mov x6, MOVE_BOTTOM
  b keep_delay

do_move_right:
  cmp x6, MOVE_LEFT
  beq keep_delay
  mov x6, MOVE_RIGHT
  b keep_delay

do_move_left:
  //aca tenemos que contemplar otro caso, que es que no puede empezar yendo para la izquierda 
  cmp x6, MOVE_RIGHT
  beq keep_delay
  mov x6, MOVE_LEFT
  b keep_delay

moved_up:
  add x4, x1, x9
  sub x3, x4, 32
  ldrb w14, [x3, 0]
  cmp x14, WALL 
  beq gameover 
  cmp x14, TAIL 
  beq gameover 
  //cmp x9, APPLE
  //beq eat_apple 
  mov x26, EMPTY
  strb w26, [x4]
  sub x9,x3,x1
  //bl move_tail
  b move_head

moved_right:
  add x4, x1, x9 
  add x3, x4, 32 
  ldrb w14, [x3, 0]
  cmp x14, WALL 
  beq gameover 
  cmp x14, TAIL 
  beq gameover 
  //cmp x9, APPLE
  //beq eat_apple
  bl move_tail
  mov x26, EMPTY
  strb w26, [x4]
  sub x9,x3,x1
  b move_head

moved_down:
  add x4, x1, x9 
  add x3, x4, 32 
  ldrb w14, [x3, 0]
  cmp x14, WALL 
  beq gameover 
  cmp x14, TAIL 
  beq gameover 
  //cmp x9, APPLE
  //beq eat_apple
  mov x26, EMPTY
  strb w26, [x4]
  sub x9,x3,x1
  //bl move_tail
  b move_head

moved_left:
  add x4, x1, x9 
  sub x3, x4, 1 
  ldrb w14, [x3, 0]
  cmp x14, WALL 
  beq gameover 
  cmp x14, TAIL 
  beq gameover 
  //cmp x9, APPLE
  //beq eat_apple
  mov x26, EMPTY
  strb w26, [x4]
  sub x9,x3,x1 
  //bl move_tail
  b move_head

move_head:
  mov x14, HEAD 
  sturb w14, [x3, 0]
  b refresh 

move_tail:
  ldurh w28, [x11, 0]
  sturh w9, [x11, 0]
  mov x27, 2
loop_tail:
  add x5,x11,x27
  ldurh w26,[x5,0]
  cmp x26,0
  beq end_tail
  sturh w28,[x5,0]
  mov x28,x26
  add x27,x27,2
  b loop_tail
end_tail:
  mov x27,2
  mov x10, TAIL
  end_tail_loop:
    add x5,x11,x27
    ldurh w26,[x5,0]
    cmp x26,0
    beq cont
    add x26,x1,x26
    sturb w10,[x26,0]
    add x27,x27,2
    b end_tail_loop
  cont:
  br x30

new_grid:
  mov x12, #0
  mov x13, WALL 

fill_top:
  strb w13, [x1, x12]
  add x12, x12, #1
  cmp x12, #31 // Comprobar si se completó la fila superior
  b.lt fill_top

  mov x12, #992
fill_bottom:
  strb w13, [x1, x12] // Llenar el borde inferior
  add x12, x12, #1
  cmp x12, #1024
  b.lt fill_bottom

  mov x12, #0
fill_row:
  strb w13, [x1, x12]
  add x12, x12, #31
  strb w13, [x1, x12]
  add x12, x12, #1
  cmp x12, #992
  b.le fill_row

  br x30


// ahora vamos a hacer la parte de dibujar la cuadricula, pero segun la posicion en la que se encuentre
// entonces arrancamos con esto para primero determinar que va en cada uno
// dsps hacemos subrutinas para dibujar segun la posicion
// al final hacemos una subrutina para dibujar la celda en base a que va en tal posicion

display_grid:
  mov x20, x10
  mov x21, x11
  mov x22, x12
  mov x23, x13
  mov x24, x14
  mov x25, x15
  mov x29, x30

  mov x10, #32
  mov x11, #0 //es el offset del arreglo
  mov x12, #1024 // limite + 1

loop_cell:
  lsr x16, x11, #5 //obtenemos la posición en y que despues vamos a usar para el framebuffer
  msub x17, x16, x10, x11 // obtenemos la posicion en x que despues vamos a usar para el framebuffer
  ldrb w13, [x1, x11] // lee el valor en la posición actual.

  // Comparaciones y llamadas a funciones para dibujar elementos.
  sub x14, x13, #EMPTY
  cbz x14, display_empty

  sub x14, x13, #WALL
  cbz x14, display_wall

  sub x14, x13, #HEAD
  cbz x14, display_head

  sub x14, x13, #TAIL
  cbz x14, display_tail

  sub x14, x13, #APPLE
  cbz x14, display_apple

display_empty:
  mov x15, GREEN
  bl draw_cell
  b break_cell

display_wall:
  mov x15, RED 
  bl draw_cell
  b break_cell

display_head:
  mov x15, BLUE
  bl draw_cell
  b break_cell

display_tail:
  mov x15, BLUE
  bl draw_cell
  b break_cell

display_apple:
  mov x15, BLACK 
  bl draw_apple
  b break_cell

break_cell:
  add x11, x11, #1
  cmp x11, x12
  b.lt loop_cell

return:
  mov x10, x20
  mov x11, x21
  mov x12, x22
  mov x13, x23
  mov x14, x24
  mov x15, x25
  mov x30, x29

  br x30


// AHORA TENEMOS QUE HACER LA FUNCIÓN QUE GRAFIQUE CADA CELDA, O SEA, VAMOS A HACER QUE
// EN CADA REFRESH, SE RECORRA CADA ELEMENTO DEL ARREGLO Y SE DIBUJE LO QUE PERTENECE
// ACA, CADA CELL TIENE UNA AREA DE (16X16 PIXELES) PORQUE ASI LO DEFINIMOS
// LO QUE VAMOS A HACER AHORA ES OBTENER LAS COORDENADAS EN BASE A LAS POSICIONES EN i Y j DE LA PANTALLA
// VAMOS A USAR X17 PARA LA POSICION EN X QUE OBTENEMOS DE ARRIBA Y X16 PARA LA POSICION EN Y IDEM
// FINALMENTE, USAMOS X4 PARA SETEAR UN COLOR EN BASE A SI SE TRATA DE VACIO, UNA PARED, ETC.

draw_cell:
  mov x20, x10
  mov x21, x11
  mov x22, x12
  mov x23, x13
  mov x24, x14
  mov x25, x15

  // Calcula las coordenadas de píxeles
  lsl x10, x17, #4 // Multiplica x por 16 para obtener la coordenada j de píxeles
  lsl x11, x16, #4 // Multiplica y por 16 para obtener la coordenada i de píxeles

  //marcamos los limites
  add x10, x10, TAM_CELL //le sumamos 16, ya que cada celda tiene 16 pixeles de ancho. Limite en j
  add x11, x11, TAM_CELL // limite en i

  // Dibuja la celda en el rango de píxeles correspondientes
  lsl x12, x16, #4 // x12 guarda la coordenada y de píxeles
loop_draw_pixel_i:
  lsl x13, x17, #4 // x13 guarda la coordenada x de píxeles
loop_draw_pixel_j: //todo lo que sigue es la formula del framebuffer del TP 
  lsl x14, x12, #9 //y * 512
  add x14, x14, x13 //x + (y * 512)
  lsl x14, x14, #1 // 2 * lo de arriba 
  add x14, x14, x0 // direccion = direccion de inicio + lo de arriba 
  sturh w15,[x14, #0] //aca pinto 

  add x13, x13, #1 // Avanza a la siguiente coordenada x
  cmp x13, x10 // Comprueba si hemos terminado de dibujar la fila
  b.lt loop_draw_pixel_j

  add x12, x12, #1 // Avanza a la siguiente coordenada y
  cmp x12, x11 // Comprueba si hemos terminado de dibujar la celda
  b.lt loop_draw_pixel_i

  mov x10, x20
  mov x11, x21
  mov x12, x22
  mov x13, x23
  mov x14, x14
  mov x15, x25

  br x30 //esta instruccion realiza un salto de retorno.


// QUEDARIA HACER LA FUNCION QUE DIBUJE LA MANZANA, DONDE ES LO MISMO QUE DRAW CELL BASICAMENTE 
// deberiamos ver como hacer para cambiar el formato de la manzana y que no tenga la misma forma geometrica 

draw_apple:

	mov x20, x10
  mov x21, x11
  mov x22, x12
  mov x23, x13
  mov x24, x14
  mov x25, x15

  // Calcula las coordenadas de píxeles
  lsl x10, x17, #4 // Multiplica x por 16 para obtener la coordenada x de píxeles
  lsl x11, x16, #4 // Multiplica y por 16 para obtener la coordenada y de píxeles

  //marcamos los limites
  add x10, x10, TAM_CELL //le sumamos 16, ya que cada celda tiene 16 pixeles de ancho. Limite en j
  add x11, x11, TAM_CELL // limite en i

  // Dibuja la celda en el rango de píxeles correspondientes
  lsl x12, x16, #4 // x12 guarda la coordenada y de píxeles
loop_draw_pixel_apple_i:
  lsl x13, x17, #4 // x13 guarda la coordenada x de píxeles
loop_draw_pixel_apple_j: //todo lo que sigue es la formula del framebuffer del TP 
  lsl x14, x12, #9 //y * 512
  add x14, x14, x13 // x + (y * 512)
  lsl x14, x14, #1 // 2 * lo de arriba 
  add x14, x14, x0 //direccion = direccion de inicio + lo de arriba 
  sturh w15,[x14, #0] //aca pinto con el framebufffer 

  add x13, x13, #1 // Avanza a la siguiente coordenada x
  cmp x13, x10 // Comprueba si hemos terminado de dibujar la fila
  b.lt loop_draw_pixel_apple_j 

  add x12, x12, #1 // Avanza a la siguiente coordenada y
  cmp x12, x11 // Comprueba si hemos terminado de dibujar la celda
  b.lt loop_draw_pixel_apple_i

  mov x10, x20
  mov x11, x21
  mov x12, x22
  mov x13, x23
  mov x14, x14
  mov x15, x25

  br x30 //esta instruccion realiza un salto de retorno.


gameover:
  bl redOn 
  bl display_grid
  b gameover

.data
  grid: .space 1024, 0x00
  tail: .space 1024, 0x0000

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

  mov x6, MOVE_RIGHT          //inicializador de movimiento
  mov x7, 700                 //posicion de la manzana
  mov x29, APPLE 
  strb w29, [x1, x7]          //cargo la manzana
  mov x8, 0x3000              //delay 
  mov x9, 464                 //posicion de la cabeza 
  mov x10, 463                //posicion de la cola 
  adr x11, tail               //puntero a la dirección de memoria de tail (tratamos como un arreglo)
  sturh w10, [x11, 0]         //cargo el primer valor de la cola en la dirección de tail  
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
  cbnz x19, delay
  b main_loop

correct_delay:
  mov x12, 1

do_move_up:
  cmp x6, MOVE_BOTTOM 
  beq keep_delay
  mov x6, MOVE_TOP
  b keep_delay

do_move_down:
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
  cmp x6, MOVE_RIGHT
  beq keep_delay
  mov x6, MOVE_LEFT
  b keep_delay


moved_up:
  add x4, x1, x9 
  sub x3, x4, 32
  ldurb w14, [x3, 0] 
  cmp x14, WALL 
  beq gameover 
  cmp x14, TAIL 
  beq gameover 
  //cmp x14, APPLE
  //beq eat_apple
  bl move_tail
  mov x14, HEAD
  sub x9, x9, 32 
  add x3, x1, x9  
  sturb w14, [x3, #0]
  b refresh 

moved_right:
  add x4, x1, x9 
  add x3, x4, 1 
  ldurb w14, [x3, 0] 
  cmp x14, WALL 
  beq gameover 
  cmp x14, TAIL 
  beq gameover 
  //cmp x14, APPLE
  //beq eat_apple
  bl move_tail
  bl greenOn
  mov x14, HEAD
  add x9, x9, x1 
  add x3, x1, x9 
  sturb w14, [x3, #0]
  b refresh 

moved_down:
  add x4, x1, x9 
  add x3, x4, 32
  ldurb w14, [x3, 0] 
  cmp x14, WALL 
  beq gameover 
  cmp x14, TAIL 
  beq gameover 
  //cmp x14, APPLE
  //beq eat_apple
  //bl move_tail
  mov x14, HEAD
  add x9, x9, 32
  add x3, x1, x9  
  sturb w14, [x3, #0]
  b refresh

moved_left:
  add x4, x1, x9 
  sub x3, x4, 1 
  ldurb w14, [x3, 0] 
  cmp x14, WALL 
  beq gameover 
  cmp x14, TAIL 
  beq gameover 
  //cmp x14, APPLE
  //beq eat_apple
  bl move_tail
  mov x14, HEAD
  sub x9, x9, 1
  add x3, x1, x9  
  sturb w14, [x3, #0]
  b refresh

move_tail:
  ldurh w15, [x11, 0]       //guardo en w15, la primera ubic mas cerca de la cabeza 
  sturh w9, [x11, 0]        //ahora, la ubic donde estaba la cabeza, pasa a ser la mas cercana a la cabeza 
  mov x14, TAIL 
  add x3, x1, x9            //obtengo la ubic donde estaba la cabeza
  sturb w14, [x3, 0]        //la sobreescribo con TAIL 
  mov x4, 2                 //uso para iterar en el loop 
loop_tail:
  add x5, x4, x11           //obtiene la ubicacion siguiente de la cola mas cerca a la cabeza previa 
  ldurh w26, [x5, 0]        //lee lo que hay en la siguiente ubicacion y lo guarda en w26 
  cmp x26, 0                //si no hay nada, no hay mas cola, no habria que hacer movimiento 
  beq end_tail              //salta en el caso de que no haya mas cola 
  //mov x14, TAIL           //declara TAIL en ese registro 
  add x3, x15, x1           //obtiene la direccion de la celda donde estaba la cola 
  sturb w14, [x3, 0]        //gurda TAIL en esa ubicacion 
  sturh w15, [x5, 0]        //guarda lo que estaba contenido previo de la celda en la que estaba la cola 
  mov x15, x26              //acualiza el contenido actual 
  add x4, x4, 2             //aumenta en 2 y se vuelve a llamar al loop 
  b loop_tail

end_tail:
  mov x14, EMPTY            // declara EMPTY ese registro
  add x3, x15, x1           // obtiene la ubic de la celda donde estaba la cola 
  sturb w14, [x3, 0]        // guarda EMPTY en ese lugar 
  ret   

// esta rutina va a ser la misma logica que la de mover la cola, pero lo unico que cambiaria
// es que, al final, en vez de declarar un registro como EMPTY, habria que agregar una cola nueva
// para que de esta manera se agrande en una unidad la cola de la snake
// como de momento no esta funcionando lo de mover la cola, por lo menos vamos a implementar 
// la función comom para ver despues cual es el error y tratar de que ande.
eat_apple:
  ldurh w15, [x11, 0]       //guardo en w15, la primera ubic mas cerca de la cabeza 
  sturh w9, [x11, 0]        //ahora, la ubic donde estaba la cabeza, pasa a ser la mas cercana a la cabeza 
  mov x14, TAIL 
  //add x3, x1, x9          //obtengo la ubic donde estaba la cabeza
  sturb w14, [x3, 0]        //la sobreescribo con TAIL 
  mov x4, 4                 //uso para iterar en el loop 
loop_tail2:
  add x5, x4, x11           //obtiene la ubicacion siguiente de la cola mas cerca a la cabeza previa 
  ldurh w26, [x5, 0]        //lee lo que hay en la siguiente ubicacion y lo guarda en w26 
  cmp x26, 0                //si no hay nada, no hay mas cola, no habria que hacer movimiento 
  beq end_tail              //salta en el caso de que no haya mas cola 
  mov x14, TAIL             //declara TAIL en ese registro 
  add x3, x15, x1           //obtiene la direccion de la celda donde estaba la cola 
  sturb w14, [x3, 0]        //gurda TAIL en esa ubicacion 
  sturh w15, [x5, 0]        //guarda lo que estaba contenido previo de la celda en la que estaba la cola 
  mov x15, x26              //acualiza el contenido actual 
  add x4, x4, 4             //aumenta en 4 y se vuelve a llamar al loop 
  b loop_tail

end_tail2:
  mov x14, TAIL             // en lugar de EMPTY, agregamos una TAIL 
  add x3, x15, x1            
  sturb w14, [x3, 0]        
  sturh w15, [x5, 0]
  //b new_apple (ESTA SERIA EN EL CASO DE QUE SE COMA LA MANZANA, SE AGREGUE UNA COLA Y SE GENERARIA UNA NUEVA MANZANA)


//esta funcion también es en el hipotetico caso de que andase.
//vamos a intentar hacer la logica 
new_apple:
  mov x2, x12 
  add x2, x2, x1 
  ldur w14, [x2, 0]
  // contemplamos en el caso de que quiera ponerse la manzana en un lugar donde hay snake
  cmp x14, HEAD 
  beq change_row
  cmp x14, TAIL
  beq change_row
  //vamos a suponer que nosotros elegimos el lugar donde aparecen las manzanas de momento para no tener problemas
  mov x14, APPLE 
  sturb w14, [x2, 0]
  add x12, x12, 1
  // de esta forma, siempre van a aparecer dentro de la grilla sin problemas con los bordes

change_row:
  add x12, x12, 32 
  ret 

// ------------------------------------------------------------------------------------------------
new_grid:
  mov x22, x12 
  mov x23, x13
  mov x29, x30

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

  mov x12, x22 
  mov x13, x23
  mov x30, x29 

  br x30 


// ahora vamos a hacer la parte de dibujar la cuadricula, pero segun la posicion en la que se encuentre
// entonces arrancamos con esto para primero determinar que va en cada uno
// dsps hacemos subrutinas para dibujar segun lo que se lee en esa posicion 
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
  mov x11, #0               //es el offset del arreglo
  mov x12, #1024            // limite + 1

loop_cell:
  lsr x16, x11, #5          //obtenemos la posición en y que despues vamos a usar para el framebuffer
  msub x17, x16, x10, x11   //obtenemos la posicion en x que despues vamos a usar para el framebuffer
  ldrb w13, [x1, x11]       //lee el valor en la posición actual.

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
// EN CADA REFRESH, SE RECORRA CADA ELEMENTO DEL ARREGLO Y SE DIBUJE LO QUE PERTENECE.
// ACA, CADA CELL TIENE UNA AREA DE (16X16 PIXELES) PORQUE ASI LO DEFINIMOS
// LO QUE VAMOS A HACER AHORA ES OBTENER LAS COORDENADAS EN BASE A LAS POSICIONES EN i Y j DE LA PANTALLA
// VAMOS A USAR X17 PARA LA POSICION EN X QUE OBTENEMOS DE ARRIBA Y X16 PARA LA POSICION EN Y IDEM
// FINALMENTE, USAMOS X15 PARA SETEAR UN COLOR EN BASE A SI SE TRATA DE VACIO, UNA PARED, ETC.

draw_cell:
  mov x20, x10
  mov x21, x11
  mov x22, x12
  mov x23, x13
  mov x24, x14
  mov x25, x15

  // Calcula las coordenadas de píxeles
  lsl x10, x17, #4              // Multiplica x por 16 para obtener la coordenada j de píxeles
  lsl x11, x16, #4              // Multiplica y por 16 para obtener la coordenada i de píxeles

  //marcamos los limites
  add x10, x10, TAM_CELL        //le sumamos 16, ya que cada celda tiene 16 pixeles de ancho. Limite en j
  add x11, x11, TAM_CELL        // limite en i

  // Dibuja la celda en el rango de píxeles correspondientes
  lsl x12, x16, #4              // x12 guarda la coordenada y de píxeles
loop_draw_pixel_i:
  lsl x13, x17, #4              // x13 guarda la coordenada x de píxeles
loop_draw_pixel_j:              //todo lo que sigue es la formula del framebuffer del TP 
  lsl x14, x12, #9              //y * 512
  add x14, x14, x13             //x + (y * 512)
  lsl x14, x14, #1              // 2 * lo de arriba 
  add x14, x14, x0              // direccion = direccion de inicio + lo de arriba 
  sturh w15,[x14, #0]           //aca pinto en la posicion que obtuvimos en x14

  add x13, x13, #1              // Avanza a la siguiente coordenada x
  cmp x13, x10                  // Comprueba si hemos terminado de dibujar la fila
  b.lt loop_draw_pixel_j

  add x12, x12, #1              // Avanza a la siguiente coordenada y
  cmp x12, x11                  // Comprueba si hemos terminado de dibujar la celda
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
  lsl x10, x17, #4                // Multiplica x por 16 para obtener la coordenada x de píxeles
  lsl x11, x16, #4                // Multiplica y por 16 para obtener la coordenada y de píxeles

  //marcamos los limites
  add x10, x10, TAM_CELL          //le sumamos 16, ya que cada celda tiene 16 pixeles de ancho. Limite en j
  add x11, x11, TAM_CELL          //limite en i

  // Dibuja la celda en el rango de píxeles correspondientes
  lsl x12, x16, #4                // x12 guarda la coordenada y de píxeles
loop_draw_pixel_apple_i:
  lsl x13, x17, #4                // x13 guarda la coordenada x de píxeles
loop_draw_pixel_apple_j:          //todo lo que sigue es la formula del framebuffer del TP 
  lsl x14, x12, #9                //y * 512
  add x14, x14, x13               // x + (y * 512)
  lsl x14, x14, #1                // 2 * lo de arriba 
  add x14, x14, x0                //direccion = direccion de inicio + lo de arriba 
  sturh w15,[x14, #0]             //aca pinto con el framebufffer 

  add x13, x13, #1                // Avanza a la siguiente coordenada x
  cmp x13, x10                    // Comprueba si hemos terminado de dibujar la fila
  b.lt loop_draw_pixel_apple_j 

  add x12, x12, #1                // Avanza a la siguiente coordenada y
  cmp x12, x11                    // Comprueba si hemos terminado de dibujar la celda
  b.lt loop_draw_pixel_apple_i

  mov x10, x20
  mov x11, x21
  mov x12, x22
  mov x13, x23
  mov x14, x14
  mov x15, x25

  br x30                          //esta instruccion realiza un salto de retorno.

gameover:
  bl redOn 
  b display_grid

.data
  grid: .space 1024, 0x00
  tail: .space 1024, 0x0000

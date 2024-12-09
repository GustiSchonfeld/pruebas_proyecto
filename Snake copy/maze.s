.text
.equ EMPTY,0x00
.equ WALL,0x01
.equ PLAYER,0x02
.equ FINISH,0x03

/**
 * Definición de los valores iniciales del arreglo de celdas.
 * Utilizamos una enumeración para los valores de cada elemento.
 * Poblamos el valor de x1.
 */
maze_new:
  mov x18,x8
 
  mov w8,WALL
  mov x2, #0
mov x3, #15
top_loop:
  strb w8,[x1,x2]
  add x2, x2, #1
  cmp x2, x3
  b.le top_loop

  mov x2, #0
  mov x3, #240
left_loop:
  strb w8,[x1,x2]
  add x2, x2, #16
  cmp x2, x3
  b.le left_loop

  mov x2, #15
  mov x3, #255
right_loop:
  strb w8,[x1,x2]
  add x2, x2, #16
  cmp x2, x3
  b.le right_loop

  mov x2, #240
  mov x3, #255
bottom_loop:
  strb w8,[x1,x2]
  add x2, x2, #1
  cmp x2, x3
  b.le bottom_loop

  mov x2, #93
  mov x3, #221

  mov x8, PLAYER
  sturb w8, [x1, #114]

  mov x8, FINISH
  sturb w8, [x1, #100]

  mov x8,x18
 
  br x30

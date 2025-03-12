#include "hardware/regs/addressmap.h"
#include "hardware/regs/m0plus.h"
 
.syntax unified                 @ Specify unified assembly syntax
.cpu    cortex-m0plus           @ Specify CPU type is Cortex M0+
.thumb                          @ Specify thumb assembly for RP2040
.global main_asm                @ Provide program starting address to the linker
.align 4                        @ Specify code alignment
 
.equ    SLEEP_TIME, 500         @ Specify the sleep time (in ms)
.equ    LED_GPIO_PIN, 25        @ Specify the pin that the LED is connected to
.equ    LED_GPIO_OUT, 1         @ Specify the direction of the GPIO pin
.equ    LED_VALUE_ON, 1         @ Specify the value that turns the LED "on"
.equ    LED_VALUE_OFF, 0        @ Specify the value that turns the LED "off"
.equ    SVC_ISR_OFFSET, 0x2C    @ The SVC is entry 11 in the vector table
.equ    SVC_MAX_INSTRS, 0x01    @ Maximum allowed SVC subroutines
 
@ Entry point to the ASM portion of the program
main_asm:
    bl      init_gpio_led       @ Initialise the GPIO LED pin
    bl      install_svc_isr     @ Install the SVC interrupt service routine
loop:
    svc     #0                  @ Call the SVC ISR with value 0 (turns on LED)
    nop                         @ Add a no-op instruction for alignment after SVC
    bl      do_sleep            @ Short pause before proceeding
    svc     #1                  @ Call the SVC ISR with value 1 (turns off LED)
    nop                         @ Add a no-op instruction for alignment after SVC
    bl      do_sleep            @ Add a short pause before proceeding
    b       loop                @ Always jump back to the start of the loop
 
@ Subroutine used to introduce a short delay in the application
do_sleep:
    @ Code from Lab03
    push    {lr}                        @ Save LR (bx lr causing hardfault)
    ldr     r0, =SLEEP_TIME
    bl      sleep_ms                    @ Sleep for sleep time.
    pop     {pc}                        @ return
 
@ Subroutine used to initialise the PI Pico built-in LED
init_gpio_led:
    @ Code from Assignment 1
    push    {lr}                        @ Save LR (bx lr causing hardfault)
    movs    r0, #LED_GPIO_PIN          
    bl      asm_gpio_init               @ Initialize LED GPIO pin PIN 25
    movs    r0, #LED_GPIO_PIN         
    movs    r1, #LED_GPIO_OUT                     
    bl      asm_gpio_set_dir            @ Set IO direction of LED to out
    pop     {pc}                        @ return
 
@ Subroutine used to install the SVC interrupt service handler
install_svc_isr:

    ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)    @ Private Peripheral Bus base + vector table offset distance
    ldr     r1, [r2]                                @ Load value at address in r2 (base address of vector table)
    movs    r2, #SVC_ISR_OFFSET                     @ Offset is 11 in vector table for SVC
    add     r2, r1                                  @ Add SVC offset to base address to get SVC entry address
    ldr     r0, =svc_isr                            @ Load the address of the SVC ISR handler into r0
    str     r0, [r2]                                @ Store handler address (r0) at the SVC entry 
    bx      lr                                      @ Restore LR and return
 
@ SVC interrupt service handler routine
.thumb_func                     @ Required for all interrupt service routines
svc_isr:
    push    {lr}                @ Save LR to stack
    ldr     r0, [sp, #0x1C]     @ Load value at stack pointer + 28, which is the saved program counter (instruction that was occuring)
    subs    r0, #0x2            @ Subtract 2 from r0 (SPC) to to point to SVC instruction address (thumb function PC is 2 ahead)
    ldr     r0, [r0]            @ Load the value at the address at r0, which is the instruction that was interrupted (info 0/1)
    ldr     r1, =#0xFF          @ Load SVC mask
    ands    r0, r1              @ Mask: only show lower 8 bits
    cmp     r0, #SVC_MAX_INSTRS @ Check if r0 corresponds to a valid entry in jump table
    bgt     svc_done            @ Exit to svc_done if invalid
    adr     r1, svc_jmptbl      @ SVC jump table, contains branches.
    lsls    r0, #2              @ Multiply interrupt instruction (0/1) by 4 to get address from jump table
    ldr     r1, [r1, r0]        @ load address of SVC subroutine from jump table into r1
    mov     pc, r1              @ Branch to subroutine
svc_done:
    pop     {pc}                @ Restore LR and return
 
@ First function of SVC subroutine - turn on the LED
svc_num0:
    @ code from lab03
    movs    r1, #LED_VALUE_ON
    movs    r0, #LED_GPIO_PIN
    bl      asm_gpio_put        @ Turn LED on
    b       svc_done            @ Branch back to the main ISR when done
 
@ Second function of SVC subroutine - turn off the LED
svc_num1:
    @ code from lab03
    movs    r1, #LED_VALUE_OFF
    movs    r0, #LED_GPIO_PIN
    bl      asm_gpio_put        @ Turn LED off
    b       svc_done            @ Branch back to the main ISR when done
 
@ SVC function entry jump table.
.align 2
svc_jmptbl:
    .word svc_num0              @ Entry zero goes to SVC function #0.
    .word svc_num1              @ Entry one goes to SVC function #1.
    .word 0                     @ Null termination of the jump table.
 
@ Set data alignment
.data
    .align 4
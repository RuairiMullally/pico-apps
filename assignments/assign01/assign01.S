#include "hardware/regs/addressmap.h"
#include "hardware/regs/io_bank0.h"
#include "hardware/regs/timer.h"
#include "hardware/regs/m0plus.h"

.syntax unified
.cpu    cortex-m0plus
.thumb
.global main_asm
.align  4

.equ    DFLT_STATE_STRT, 1            @ Specify the value to start flashing
.equ    DFLT_STATE_STOP, 0            @ Specify the value to stop flashing
.equ    DFLT_ALARM_TIME, 1000000      @ Specify the default alarm timeout

.equ    GPIO_BTN_DN_MSK, 0x00040000   @ Bit-18 for falling-edge event on GP20
.equ    GPIO_BTN_EN_MSK, 0x00400000   @ Bit-22 for falling-edge event on GP21
.equ    GPIO_BTN_UP_MSK, 0x04000000   @ Bit-26 for falling-edge event on GP22

.equ    GPIO_BTN_DN,  20              @ Specify pin for the "down" button
.equ    GPIO_BTN_EN,  21              @ Specify pin for the "enter" button
.equ    GPIO_BTN_UP,  22              @ Specify pin for the "up" button
.equ    GPIO_LED_PIN, 25              @ Specify pin for the built-in LED
.equ    GPIO_DIR_IN,   0              @ Specify input direction for a GPIO pin
.equ    GPIO_DIR_OUT,  1              @ Specify output direction for a GPIO pin

.equ    LED_VAL_ON,    1              @ Specify value that turns the LED "on"
.equ    LED_VAL_OFF,   0              @ Specify value that turns the LED "off"

.equ    GPIO_ISR_OFFSET, 0x74         @ GPIO is int #13 (vector table entry 29)
.equ    ALRM_ISR_OFFSET, 0x40         @ ALARM0 is int #0 (vector table entry 16)
.equ    PROC0_INTS2_OFFSET, 0x128     @ 0x128 PROC0_INTS2 Interrupt status after masking & forcing for proc0

@ Entry point to the ASM portion of the program
main_asm:
        ldr     r0, =msg
        bl      printf

        bl      init_LED
        bl      init_buttons
        bl      register_GPIO_isr_handler
main_loop:
                                                         
        bl      sub_toggle
        movs    r0, #100
        bl      sleep_ms                    @ Sleep for 100ms to allow button to travel back.
        b       main_loop

init_LED:
        push    {lr}
        movs    r0, #GPIO_LED_PIN           @ Initialize LED GPIO pin PIN 25
        bl      asm_gpio_init               
        movs    r0, #GPIO_LED_PIN          
        movs    r1, #GPIO_DIR_OUT           @OUT           
        bl      asm_gpio_set_dir
        pop     {pc}

init_buttons: 
        push    {lr}

        movs    r0, #GPIO_BTN_DN           @ Init DOWN button (half flash speed) PIN 20
        bl      asm_gpio_init               
        movs    r0, #GPIO_BTN_DN           
        movs    r1, #GPIO_DIR_IN           @ dir IN         
        bl      asm_gpio_set_irq           @ set falling edge interrupt request

        movs    r0, #GPIO_BTN_EN           @ Init ENABLE button (start/stop flashing) PIN 21
        bl      asm_gpio_init               
        movs    r0, #GPIO_BTN_EN           
        movs    r1, #GPIO_DIR_IN           @ dir IN         
        bl      asm_gpio_set_irq           @ set falling edge interrupt request

        movs    r0, #GPIO_BTN_UP           @ Init UP button (double flashing speed) PIN 22
        bl      asm_gpio_init               
        movs    r0, #GPIO_BTN_UP           
        movs    r1, #GPIO_DIR_IN           @ dir IN         
        bl      asm_gpio_set_irq           @ set falling edge interrupt request

        pop {pc}                           @ Back to main


register_GPIO_isr_handler:
        push {r0, r1, r2}                      @ save registers

        //store button_isr_handler address in the vector table at offset 0x74
        ldr r0, =button_isr_handler
        ldr r1, =PPB_BASE                   @ PPB_BASE is the is where the vector table base address is stored (private poeripheral bus)

        ldr r2, =M0PLUS_VTOR_OFFSET         @ Load VTOR offset
        ldr r2, [r1, r2]
        ldr r3, =GPIO_ISR_OFFSET            @ 29 x 4
        add r2, r2, r3
        str r0, [r2]
        //this stores the address of the button_isr_handler at PPB_BASE + VTOR_OFFSET (get to programmable exceptions)
        // + GPIO interrupt location (0x74)

        //enable the button_isr_handler by setting the Nested Vectored Interrupt Controller (NVIC)
        //which controls which interrputs are enabled
        ldr r1, =PPB_BASE
        ldr r2, =M0PLUS_NVIC_ICPR_OFFSET
        add r2, r1, r2
        ldr r0, =1                              @ 1 for enable
        lsls r0, #13                            @  13 IO_IRQ_BANK0 (position of IO enable bank)
        str r0, [r2]                            @ clear existing interrupts

        ldr r1, =PPB_BASE
        ldr r2, =M0PLUS_NVIC_ISER_OFFSET
        add r2, r1, r2
        ldr r0, =1                              @ 1 for enable
        lsls r0, #13                            @  13 IO_IRQ_BANK0 (position of IO enable bank)
        str r0, [r2]                            @ Interrupt Set Enable Register
        
        pop {r0, r1, r2}                        @ restore registers
        bx lr                                   @ return

.thumb_func
button_isr_handler:
        push      {r0, r1, r2, lr}
        ldr       r0, =msg             // enter button pressed message
        bl        printf
       
        ldr       r1, =IO_BANK0_BASE  //GPIO pin bank base reg
        ldr       r2, =PROC0_INTS2_OFFSET //  0x128 PROC0_INTS2 Interrupt status after masking & forcing for proc0
        adds      r3, r1, r2
        ldr       r0, [r3] 

        //compare interrupt with interrupt masks
        ldr       r1, =GPIO_BTN_EN_MSK
        cmp       r0, r1
        beq       clear_en

        ldr       r1, =GPIO_BTN_DN_MSK
        cmp       r0, r1
        beq       clear_dn

        ldr       r1, =GPIO_BTN_UP_MSK
        cmp       r0, r1
        beq       clear_up
                       
        pop       {r0, r1, r2, pc}
@ Part of button_isr_handler: clears the interrupt for GPIO20
clear_dn:
        ldr       r0, =msg_half_speed           // enter button pressed message
        bl        printf

        ldr       r0, =GPIO_BTN_DN_MSK          
        ldr       r1, =IO_BANK0_BASE  //GPIO pin bank base reg
        ldr       r2, =IO_BANK0_INTR2_OFFSET // IO_BANK0: INTR2 Register where falling edge is located
        adds      r3, r1, r2
        str       r0, [r3]     //mask the reg to clear interrupt   
        b         exit_clear                

@ Part of button_isr_handler: clears the interrupt for GPIO21
clear_en: 
        ldr       r0, =msg_toggle             // enter button pressed message
        bl        printf

        ldr       r0, =GPIO_BTN_EN_MSK          
        ldr       r1, =IO_BANK0_BASE  //GPIO pin bank base reg
        ldr       r2, =IO_BANK0_INTR2_OFFSET // IO_BANK0: INTR2 Register where falling edge is located
        adds      r3, r1, r2
        str       r0, [r3]     //mask the reg to clear interrupt                   
        b         exit_clear    

@ Part of button_isr_handler: clears the interrupt for GPIO22
clear_up:
        ldr       r0, =msg_double_speed             // enter button pressed message
        bl        printf

        ldr       r0, =GPIO_BTN_UP_MSK          
        ldr       r1, =IO_BANK0_BASE  //GPIO pin bank base reg
        ldr       r2, =IO_BANK0_INTR2_OFFSET // IO_BANK0: INTR2 Register where falling edge is located
        adds      r3, r1, r2
        str       r0, [r3]     //mask the reg to clear interrupt                   
        b         exit_clear    

exit_clear:
        pop       {r0, r1, r2, pc}



@ Subroutine to toggle the LED GPIO pin value
sub_toggle:
    push    {lr}
    movs    r0, #GPIO_LED_PIN
    bl      asm_gpio_get                @ Get current LED state
    cmp     r0, #LED_VAL_OFF
    beq     led_set_on
led_set_off:
    movs    r1, #LED_VAL_OFF
    b       led_set_state
led_set_on:
    movs    r1, #LED_VAL_ON
led_set_state:
    movs    r0, #GPIO_LED_PIN
    bl      asm_gpio_put
    pop     {pc}
        

.align 4
msg:                .asciz "Button Interrupt Triggered!\n"
msg_half_speed:     .asciz "Button GP20 pressed: Halve LED flashing speed\n"
msg_toggle:         .asciz "Button GP21 pressed: Toggle LED flashing\n"
msg_double_speed:   .asciz "Button GP22 pressed: Double LED flashing speed\n"


.data
lstate: .word   DFLT_STATE_STRT
ltimer: .word   DFLT_ALARM_TIME
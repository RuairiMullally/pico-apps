.syntax unified                 @ Specify unified assembly syntax
.cpu    cortex-m0plus           @ Specify CPU type is Cortex M0+
.thumb                          @ Specify thumb assembly for RP2040
.global main_asm                @ Provide program starting address to the linker
.align 4                        @ Specify code alignment

.equ    SLEEP_TIME, 100         @ Specify the amount of ms that we want to sleep for in the loop
.equ    LED_GPIO_PIN, 25        @ Specify the physical GPIO pin that the LED is connected to
.equ    LED_GPIO_OUT, 1         @ Specify the direction that we want to set the GPIO pin to
.equ    LED_VALUE_ON, 1         @ Specify the value that turns the LED "on"
.equ    LED_VALUE_OFF, 0        @ Specify the value that turns the LED "off"

.equ    BUT_GPIO_PIN, 21        @ Specify the physical GPIO pin that the BUTTON is connected to
.equ    BUT_GPIO_IN, 0          @ Specify the direction that we want to set the GPIO pin to

@ Entry point to the ASM portion of the program
main_asm:
    movs    r0, #LED_GPIO_PIN           @ Initialize LED GPIO pin
    bl      asm_gpio_init               
    movs    r0, #LED_GPIO_PIN           
    movs    r1, #LED_GPIO_OUT           
    bl      asm_gpio_set_dir            

    @ Set up for button
    movs    r0, #BUT_GPIO_PIN           @ Initialize BUTTON GPIO pin for input
    bl      asm_gpio_init               
    movs    r0, #BUT_GPIO_PIN           
    movs    r1, #BUT_GPIO_IN            
    bl      asm_gpio_set_dir            

loop:
    movs    r0, #BUT_GPIO_PIN           
    bl      asm_gpio_get                @ Read button state
    cmp     r0, #0                      @ Button is pressed (LOW is a press due to external pull-up)
    beq     sub_toggle                  @ Toggle LED when button is pressed

    movs    r0, #SLEEP_TIME
    bl      sleep_ms                    @ Sleep for 100ms to allow button to travel back.
    b       loop                        @ Return to main loop

@ Subroutine to toggle the LED GPIO pin value
sub_toggle:
    push    {lr}
    movs    r0, #LED_GPIO_PIN
    bl      asm_gpio_get                @ Get current LED state
    cmp     r0, #LED_VALUE_OFF
    beq     led_set_on
led_set_off:
    movs    r1, #LED_VALUE_OFF
    b       led_set_state
led_set_on:
    movs    r1, #LED_VALUE_ON
led_set_state:
    movs    r0, #LED_GPIO_PIN
    bl      asm_gpio_put
    pop     {pc}

@ Set data alignment
.data
    .align 4

# Specify the name of the executable.
add_executable(lab01)

# Specify the source files to be compiled.
target_sources(lab01 PRIVATE lab01.c)

# Pull in commonly used features.
target_link_libraries(lab01 PRIVATE pico_stdlib)

pico_enable_stdio_usb(lab01 0)
pico_enable_stdio_uart(lab01 1)

# Create map/bin/hex file etc.
pico_add_extra_outputs(lab01)

# Add the URL via pico_set_program_url.
apps_auto_set_url(lab01)

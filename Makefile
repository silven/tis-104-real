CC := gcc
AVR_CC := avr-gcc
CFLAGS := -std=c11 -g -Wall -Wextra -pedantic
PC_CFLAGS := -O0 -IUnity/src
AVR_CFLAGS := -mmcu=atmega328p -Os -DF_CPU=16000000ul

DEVICE ?= /dev/ttyACM0

.DEFAULT_GOAL = avr/main_avr.hex

avr/%.o:%.c
	mkdir -p $(dir $@)
	$(AVR_CC) $(CFLAGS) $(AVR_CFLAGS) -o $@ -c $^

pc/%.o:%.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(PC_CFLAGS) -o $@ -c $^

avr/%.elf:
	mkdir -p $(dir $@)
	$(AVR_CC) $(CFLAGS) $(AVR_CFLAGS) -o $@ $^

pc/%.elf:
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(PC_CFLAGS) -o $@ $^

.PRECIOUS: avr/%.s
avr/%.s: avr/%.elf
	avr-objdump -d $< > $(basename $@).s

avr/%.hex: avr/%.elf avr/%.s
	avr-objcopy -j .text -j .data -O ihex $< $@

.PHONY: flash
flash: ${TARGET}
	avrdude -v -p m328p -c arduino -P ${DEVICE} -U flash:w:$<:i

%_runner.c: %.c
	ruby Unity/auto/generate_test_runner.rb $< $@

results/%.txt: pc/%_test_runner.elf
	mkdir -p $(dir $@)
	-$< 2>&1 > $@

avr/blink.elf: avr/blink.o

avr/sender.elf: avr/sender.o avr/uart.o

avr/receiver.elf: avr/receiver.o avr/uart.o

AVR_SOURCES = font.c indexmap.c screen.c mem.c tft.c fonts.c disp.c pin.c spi_sw.c panic.c app.c
AVR_OBJECTS = $(addprefix avr/,$(patsubst %.c,%.o,${AVR_SOURCES}))

PC_SOURCES = font.c indexmap.c screen.c mem.c tft.c fonts.c disp.c pin_pc.c spi_print.c panic.c delay_pc.c
PC_OBJECTS = $(addprefix pc/,$(patsubst %.c,%.o,${PC_SOURCES}))

avr/main_avr.elf: avr/main_avr.o ${AVR_OBJECTS}

pc/main_pc.elf: pc/main_pc.o ${PC_OBJECTS}

pc/cpu_test_runner.elf: pc/Unity/src/unity.o pc/cpu_test.o pc/cpu_test_runner.o pc/cpu.o pc/pipe_mock.o pc/panic.o

pc/integration_test_runner.elf: pc/Unity/src/unity.o pc/integration_test.o pc/integration_test_runner.o pc/cpu.o pc/pipe_mock.o pc/panic.o

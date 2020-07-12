# Makefile for the STM32F103C8 blink program
#
# based on Kevin Cuzner's example
#

PROJECT = blink
PROJECTDIR = project

# Project Structure
BUILDDIR = $(PROJECTDIR)/build
BINDIR = $(BUILDDIR)/bin
OBJDIR = $(BUILDDIR)/obj
SRCDIR = src
COMDIR = common
INCDIR = include
TOOLDIR = "$(GNU_TOOLCHAIN_PATH)"

# Project target
CPU = cortex-m3

# Sources
SRC = $(wildcard $(SRCDIR)/*.c) $(wildcard $(COMDIR)/*.c)
ASM = $(wildcard $(PROJECTDIR)/*.s)

# Include directories
INCLUDE  = -I$(INCDIR) -Icmsis

# Linker 
LSCRIPT = $(PROJECTDIR)/STM32F103X8_FLASH.ld

# C Flags
GCFLAGS  = -std=c99 -Wall -fno-common -mthumb -mcpu=$(CPU) -DSTM32F103xB --specs=nosys.specs -g -Wa,-ahlms=$(addprefix $(OBJDIR)/,$(notdir $(<:.c=.lst)))
GCFLAGS += $(INCLUDE)
LDFLAGS += -T$(LSCRIPT) -mthumb -mcpu=$(CPU) --specs=nosys.specs 
ASFLAGS += -mcpu=$(CPU)

# Flashing
OCDFLAGS = -f $(BUILDDIR)/openocd.cfg


# Tools
CC = $(TOOLDIR)/arm-none-eabi-gcc
AS = $(TOOLDIR)/arm-none-eabi-as
AR = $(TOOLDIR)/arm-none-eabi-ar
LD = $(TOOLDIR)/arm-none-eabi-ld
OBJCOPY = $(TOOLDIR)/arm-none-eabi-objcopy
SIZE = $(TOOLDIR)/arm-none-eabi-size
OBJDUMP = $(TOOLDIR)/arm-none-eabi-objdump
OCD = openocd

RM = rm -rf

## Build process

OBJ := $(addprefix $(OBJDIR)/,$(notdir $(SRC:.c=.o)))
OBJ += $(addprefix $(OBJDIR)/,$(notdir $(ASM:.s=.o)))

# .PHONY: all

# all:
# 	@echo "tooldir $(TOOLDIR)"
# 	@echo "src dir $(SRC)"
# 	@echo "asm dir $(ASM)"

all:: $(BINDIR)/$(PROJECT).bin

build: $(BINDIR)/$(PROJECT).bin

install: $(BINDIR)/$(PROJECT).bin
	$(OCD) $(OCDFLAGS)

$(BINDIR)/$(PROJECT).hex: $(BINDIR)/$(PROJECT).elf
	$(OBJCOPY) -R .stack -O ihex $(BINDIR)/$(PROJECT).elf $(BINDIR)/$(PROJECT).hex

$(BINDIR)/$(PROJECT).bin: $(BINDIR)/$(PROJECT).elf
	$(OBJCOPY) -R .stack -O binary $(BINDIR)/$(PROJECT).elf $(BINDIR)/$(PROJECT).bin

$(BINDIR)/$(PROJECT).elf: $(OBJ)
	@mkdir -p $(dir $@)
	$(CC) $(OBJ) $(LDFLAGS) -o $(BINDIR)/$(PROJECT).elf
	$(OBJDUMP) -D $(BINDIR)/$(PROJECT).elf > $(BINDIR)/$(PROJECT).lst
	$(SIZE) $(BINDIR)/$(PROJECT).elf

macros:
	$(CC) $(GCFLAGS) -dM -E - < /dev/null

clean:
	$(RM) $(BINDIR)
	$(RM) $(OBJDIR)

clean-install: clean install

# Compilation
$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(GCFLAGS) -c $< -o $@

$(OBJDIR)/%.o: $(PROJECTDIR)/%.s
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -o $@ $<


$(OBJDIR)/%.o: $(COMDIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(GCFLAGS) -c $< -o $@

# $(OBJDIR)/%.o: $(COMDIR)/%.s
# 	@mkdir -p $(dir $@)
# 	$(AS) $(ASFLAGS) -o $@ $<

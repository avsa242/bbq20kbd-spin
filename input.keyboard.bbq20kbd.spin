{
    --------------------------------------------
    Filename: input.keyboard.bbq20kbd.spin
    Author: Jesse Burt
    Description: Driver for the BBQ20KBD I2C keyboard
    Copyright (c) 2024
    Started Dec 30, 2022
    Updated Jan 3, 2024
    See end of file for terms of use.
    --------------------------------------------
}

#include "input.pointer.common.spinh"           ' pull in code common to all pointing drivers

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    DEF_ADDR        = 0
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

    { interrupts - set }
    INT_KEY         = (1 << core#CFG_KEY_INT)
    INT_NUMLOCK     = (1 << core#CFG_NUMLOCK_INT)
    INT_CAPSLOCK    = (1 << core#CFG_CAPSLOCK_INT)
    INT_OVERFLOW    = (1 << core#CFG_OVERFLOW_INT)

    { interrupts - sources }
    INT_SRC_TOUCH   = (1 << core#INT_TOUCH)
    INT_SRC_GPIO    = (1 << core#INT_GPIO)
    INT_SRC_KEY     = (1 << core#INT_KEY)
    INT_SRC_NUMLOCK = (1 << core#INT_NUMLOCK)
    INT_SRC_CAPSLOCK= (1 << core#INT_CAPSLOCK)
    INT_SRC_OVERFLOW= (1 << core#INT_OVERFLOW)

    { default I/O settings; these can be overridden in the parent object }
    SCL             = DEF_SCL
    SDA             = DEF_SDA
    I2C_FREQ        = DEF_HZ
    I2C_ADDR        = DEF_ADDR

OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef BBQ20KBD_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif
    core: "core.con.bbq20kbd.spin"              ' hw-specific low-level const's
    time: "time"                                ' basic timing functions

VAR

    byte _i2c_addr, _i2c_addr_rd

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start using default I/O pins and 100kHz
    return startx(SCL, SDA, I2C_FREQ)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom IO pins and I2C bus frequency
    if (lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31))
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)             ' wait for device startup
            _i2c_addr := SLAVE_WR               ' init with the default slave address
            _i2c_addr_rd := SLAVE_RD
            if (version{} <> $ff)               ' check for something sensible
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE

PUB stop{}
' Stop the driver
    i2c.deinit{}

PUB defaults{}
' Set factory defaults

PUB available{}: f
' Get the number of characters available in the keyboard buffer/FIFO
'   Returns: unsigned integer (0..31)
    f := 0
    readreg(core#REG_KEY, 1, @f)
    f &= core#KEY_COUNT_BITS

PUB brightness(val)
' Set keyboard backlight brightness
'   Valid values: 0..255 (clamped to range; default: 255)
    val := 0 #> val <# 255
    writereg(core#REG_BKL, 1, @val)

PUB get_i2c_addr{}: addr
' Get currently set I2C address
'   Returns: I2C address (7-bit)
    addr := 0
    readreg(core#REG_ADR, 1, @addr)

CON #0, KEY_STATE, KEY_CODE
PUB rx = getchar
PUB charin = getchar
PUB getchar{}: ch | tmp
' Get a character from the keyboard
    tmp := 0

    readreg(core#REG_FIF, 2, @tmp)              ' LSB holds key state
    if (tmp.byte[KEY_STATE] == core#PRESSED)
        return tmp.byte[KEY_CODE]

PUB int_clear(mask)
' Clear interrupts
'   NOTE: the mask parameter is for compatibility with other drivers
'       All asserted interrupts are cleared
    mask := 0
    writereg(core#REG_INT, 1, @mask)

PUB int_dur{}: d
' Get currently set interrupt duration
'   Returns: time in milliseconds
    d := 0
    readreg(core#REG_IND, 1, @d)

PUB int_mask(mask) | tmp
' Set interrupt mask
'   Bits:
'       4 INT_KEY (16): generate an interrupt when a key is pressed
'       3 INT_NUMLOCK (8): generate an interrupt when Num Lock is pressed
'       2 INT_CAPSLOCK (4): generate an interrupt when Caps Lock is pressed
'       1 INT_OVERFLOW (2): generate an interrupt when the key FIFO overflows
'       (all other bits ignored)
'       (default: INT_OVERFLOW | INT_KEY)
    tmp := 0
    readreg(core#REG_CFG, 1, @tmp)

    mask := ((tmp & core#CFG_INT_MASK) | (mask & core#CFG_INT_BITS_SH))
    writereg(core#REG_CFG, 1, @mask)

PUB int_set_dur(dur)
' Set duration INT/IRQ pin is held low after an interrupt is asserted, in milliseconds
'   Valid values: 0..255 (clamped to range; default: 1)
    dur := 0 #> dur <# 255
    writereg(core#REG_IND, 1, @dur)

PUB interrupt{}: int_src
' Get active interrupt source(s)
'   Bits:
'       6 INT_SRC_TOUCH (64): trackpad motion
'       5 INT_SRC_GPIO (32): GPIO changed level
'       3 INT_SRC_KEY (8): a key was pressed
'       2 INT_SRC_NUMLOCK (4): Num Lock was pressed
'       1 INT_SRC_CAPSLOCK (2): Caps Lock was pressed
'       0 INT_SRC_OVERFLOW (1): key FIFO overflowed
    int_src := 0
    readreg(core#REG_INT, 1, @int_src)

PUB is_capslock_active{}: f
' Flag indicating Caps lock is active
'   Returns: TRUE (1) or FALSE (0)
    f := 0
    readreg(core#REG_KEY, 1, @f)
    return ((f >> core#KEY_CAPSLOCK) & 1)

PUB is_numlock_active{}: f
' Flag indicating Num lock is active
'   Returns: TRUE (1) or FALSE (0)
    f := 0
    readreg(core#REG_KEY, 1, @f)
    return ((f >> core#KEY_NUMLOCK) & 1)

PUB key_hold_time{}: t
' Get currently set keypress "hold" duration
'   Returns: milliseconds
    t := 0
    readreg(core#REG_HLD, 1, @t)
    return (t * 10)

PUB key_set_hold_time(thresh)
' Set duration a key must be pressed to be considered held down, in milliseconds
'   Valid values: 0, 10..2550 (multiples of 10; default: 300)
'   Any other value is ignored
    thresh := (0 #> thresh <# 2550) / 10
    writereg(core#REG_HLD, 1, @thresh)

PUB mod_keys_ena(state): curr_state
' Enable modification of keypresses when the 'Alt', 'Sym' or 'Shift' keys are pressed
'   Valid values: TRUE (-1 or 1), FALSE (0) (default: TRUE)
'   Any other value polls the device and returns the current setting
'   NOTE: If this setting is disabled, keypresses will return the upper-case letter
'       indicated on the key
    curr_state := 0
    readreg(core#REG_CFG, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ((state & 1) << core#CFG_USE_MODS)
            state := ((curr_state & core#CFG_USE_MODS_MASK) | state)
            writereg(core#REG_CFG, 1, @state)
        other:
            return (((curr_state >> core#CFG_USE_MODS) & 1) == 1)

PUB reset{}
' Reset the device
    writereg(core#REG_RST, 1, 0)                ' _any_ write (or read) triggers a reset

PUB read_x = pointer_rel_x
PUB pointer_rel_x{}: x
' Get the trackpad relative position (delta), X-axis
'   Returns: position relative to the last reading (signed 8-bit)
    x := 0
    readreg(core#REG_TOX, 1, @x)
    x := ~x / _pointer_x_sens                   ' extend sign, scale to sensitivity

    { update the trackpad absolute position and clamp to set limits }
    _pointer_x := _pointer_x_min #> (_pointer_x + x) <# _pointer_x_max

PUB read_y = pointer_rel_y
PUB pointer_rel_y{}: y
' Get the trackpad relative position (delta), Y-axis
'   Returns: position relative to the last reading (signed 8-bit)
    y := 0
    readreg(core#REG_TOY, 1, @y)
    y := ~y / _pointer_y_sens                   ' extend sign, scale to sensitivity

    { update the trackpad absolute position and clamp to set limits }
    _pointer_y := _pointer_y_min #> (_pointer_y + y) <# _pointer_y_max

PUB set_i2c_addr(addr)
' Set I2C address
'   Valid values: $08..$77 (default: $1f)
'   Any other value is ignored
'   NOTE: The new address is effective immediately
'   NOTE: The address is not saved after reset or power loss
    addr := $08 #> addr <# $77
    writereg(core#REG_ADR, 1, @addr)

    { update the address set in Propeller RAM, so it knows where to find the keyboard
        the next transaction }
    _i2c_addr := (addr << 1)
    _i2c_addr_rd := (_i2c_addr | 1)

PUB version{}: v
' Get the firmware version
'   Returns:
'       bits [3..0]: major version
'       bits [7..4]: minor version
'   Known values: $11
    v := 0
    readreg(core#REG_VER, 1, @v)

{ pointer method aliases }
PUB trackpad_rel_x = pointer_rel_x
PUB trackpad_rel_y = pointer_rel_y
PUB trackpad_abs_x = abs_x
PUB trackpad_abs_y = abs_y

PRI readreg(reg_nr, nr_bytes, ptr_buff)
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register num
        core#REG_VER..core#REG_TOY:
            i2c.start{}
            i2c.write(_i2c_addr)
            i2c.write(reg_nr)
            i2c.start{}
            i2c.wr_byte(_i2c_addr_rd)
            i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
            i2c.stop{}
        other:                                  ' invalid reg_nr
            return

PRI writereg(reg_nr, nr_bytes, ptr_buff)
' Write nr_bytes to the device from ptr_buff
    case reg_nr
        core#REG_CFG, core#REG_INT, core#REG_BKL, core#REG_RST, core#REG_BK2..core#REG_CF2:
            i2c.start{}
            i2c.write(_i2c_addr)
            i2c.write(reg_nr | core#WR_MASK)
            i2c.wrblock_lsbf(ptr_buff, nr_bytes)
            i2c.stop{}
        other:
            return


DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}


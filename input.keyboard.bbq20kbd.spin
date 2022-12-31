{
    --------------------------------------------
    Filename: input.keyboard.bbq20kbd.spin
    Author: Jesse Burt
    Description: Driver for the BBQ20KBD I2C keyboard
    Copyright (c) 2022
    Started Dec 30, 2022
    Updated Dec 31, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 100_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

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

    long _trackpad_x, _trackpad_y

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom IO pins and I2C bus frequency
    if (lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31))
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)             ' wait for device startup
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


PUB brightness(val)
' Set keyboard backlight brightness
'   Valid values: 0..255 (clamped to range; default: 255)
    val := 0 #> val <# 255
    writereg(core#REG_BKL, 1, @val)

CON #0, KEY_STATE, KEY_CODE
PUB rx = getchar
PUB charin = getchar
PUB getchar{}: ch | tmp
' Get a character from the keyboard
    tmp := 0

    readreg(core#REG_FIF, 2, @tmp)              ' LSB holds key state
    if (tmp.byte[KEY_STATE] == core#PRESSED)
        return tmp.byte[KEY_CODE]

PUB gpio(mask)


PUB gpio_dir(mask)


PUB gpio_int_mask(mask)


PUB gpio_interrupt{}: int_src


PUB gpio_pullup_ena(mask)


PUB gpio_pull_dir(mask)


PUB i2c_addr(addr)


PUB int_dur(dur)


PUB int_mask(mask)


PUB interrupt{}: int_src


PUB is_capslock_active{}: f


PUB is_numlock_active{}: f


PUB key_hold(thresh)


PUB reset{}
' Reset the device
    writereg(core#REG_RST, 1, 0)                ' _any_ write (or read) triggers a reset

PUB trackpad_abs_x{}: x
' Get the trackpad absolute position, X-axis
'   Returns: absolute X position (signed 32-bit)
    return _trackpad_x

PUB trackpad_abs_y{}: y
' Get the trackpad absolute position, Y-axis
'   Returns: absolute Y position (signed 32-bit)
    return _trackpad_y

PUB trackpad_rel_x{}: x
' Get the trackpad relative position (delta), X-axis
'   Returns: position relative to the last reading (signed 8-bit)
    x := 0
    readreg(core#REG_TOX, 1, @x)
    ~x                                          ' extend sign
    _trackpad_x += x                            ' update the absolute position

PUB trackpad_rel_y{}: y
' Get the trackpad relative position (delta), Y-axis
'   Returns: position relative to the last reading (signed 8-bit)
    y := 0
    readreg(core#REG_TOY, 1, @y)
    ~y                                          ' extend sign
    _trackpad_y += y                            ' update the absolute position

PUB version{}: v
' Get the firmware version
'   Returns:
'       bits [3..0]: major version
'       bits [7..4]: minor version
'   Known values: $11
    v := 0
    readreg(core#REG_VER, 1, @v)

PRI readreg(reg_nr, nr_bytes, ptr_buff)
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register num
        core#REG_VER..core#REG_TOY:
            i2c.start{}
            i2c.write(SLAVE_WR)
            i2c.write(reg_nr)
            i2c.start{}
            i2c.wr_byte(SLAVE_RD)
            i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
            i2c.stop{}
        other:                                  ' invalid reg_nr
            return

PRI writereg(reg_nr, nr_bytes, ptr_buff)
' Write nr_bytes to the device from ptr_buff
    case reg_nr
        core#REG_CFG, core#REG_INT, core#REG_BKL, core#REG_RST, core#REG_BK2..core#REG_CF2:
            i2c.start{}
            i2c.write(SLAVE_WR)
            i2c.write(reg_nr | core#WR_MASK)
            i2c.wrblock_lsbf(ptr_buff, nr_bytes)
            i2c.stop{}
        other:
            return


DAT
{
Copyright 2022 Jesse Burt

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


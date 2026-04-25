const builtin = @import("builtin");

const VGA = enum(u8) {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGray = 7,
    DarkGray = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    Pink = 13,
    Yellow = 14,
    White = 15,
};
const where = 0xB8000;

pub fn main() void {
    print();
}

const color = u8;

pub fn color_code(foreground: VGA, background: VGA) u8 {
    return (@intFromEnum(background) << 4) |
        @intFromEnum(foreground);
}

const BUFFER_WIDTH: usize = 80;
const BUFFER_HEIGHT: usize = 25;

const ScreenChar = struct {
    ascii_char: u8,
    color_code: color,
};

const Buffer = struct { chars: [BUFFER_HEIGHT][BUFFER_WIDTH]ScreenChar };

const Writer = struct {
    column_pos: usize,
    color_code: color,
    buffer: *Buffer,
};

pub fn new_line() void {
    return;
}
pub fn write_byte(writer: *Writer, byte: u8) !void {
    switch (byte) {
        '\n' => new_line(),
        else => {
            if (writer.column_pos >= BUFFER_WIDTH) {
                new_line();
            }
            const row = BUFFER_HEIGHT - 1;
            const col = writer.column_pos;
            const colcode = writer.color_code;
            writer.buffer.chars[row][col] = ScreenChar{
                .ascii_char = byte,
                .color_code = colcode,
            };
            writer.column_pos += 1;
        },
    }
}
pub fn write_string(writer: *Writer, s: []const u8) void {
    for (s) |byte| {
        try switch (byte) {
            0x20...0x7e, '\n' => write_byte(writer, byte),
            else => write_byte(writer, 0xfe),
        };
    }
}
pub fn print() void {
    var writer = Writer{
        .column_pos = 0,
        .color_code = color_code(VGA.Green, VGA.Black),
        .buffer = @as(*Buffer, @ptrFromInt(0xB8000)),
    };
    const hello: []const u8 = "Hello"[0.. :0];
    try write_byte(&writer, '+');
    write_string(&writer, hello);
    write_string(&writer, "World");
}

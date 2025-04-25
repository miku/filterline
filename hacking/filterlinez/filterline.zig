// Copyright 2015 by Leipzig University Library, http://ub.uni-leipzig.de
//                 by The Finc Authors, http://finc.info
//                 by Martin Czygan, <martin.czygan@uni-leipzig.de>
// Translated to Zig, 2025
//
// This file is part of some open source application.
//
// Some open source application is free software: you can redistribute
// it and/or modify it under the terms of the GNU General Public
// License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.
//
// Some open source application is distributed in the hope that it will
// be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
// of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
//
// @license GPL-3.0+ <http://spdx.org/licenses/GPL-3.0+>
//
// filterline: filter file by line number.
// http://unix.stackexchange.com/a/209470/376

const std = @import("std");

const PROGRAM_VERSION = "0.1.5";

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    defer _ = general_purpose_allocator.deinit();

    const stdout = std.io.getStdOut().writer();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    // Check for version flag
    if (args.len == 2 and std.mem.eql(u8, args[1], "-V")) {
        try stdout.print("{s}\n", .{PROGRAM_VERSION});
        return;
    }

    // Check for correct number of arguments
    if (args.len != 3 and args.len != 4) {
        try printUsage(stdout, args[0]);
        return;
    }

    // Parse arguments
    var invert_matches = false;
    var line_file: []const u8 = undefined;
    var input_file: []const u8 = undefined;

    if (args.len == 4 and std.mem.eql(u8, args[1], "-v")) {
        invert_matches = true;
        line_file = args[2];
        input_file = args[3];
    } else {
        line_file = args[1];
        input_file = args[2];
    }

    // Open files
    const line_file_handle = std.fs.cwd().openFile(line_file, .{}) catch {
        std.debug.print("Failed to open line number file: {s}\n", .{line_file});
        std.process.exit(1);
    };
    defer line_file_handle.close();

    const input_file_handle = std.fs.cwd().openFile(input_file, .{}) catch {
        std.debug.print("Failed to open input file: {s}\n", .{input_file});
        std.process.exit(1);
    };
    defer input_file_handle.close();

    var line_reader = std.io.bufferedReader(line_file_handle.reader());
    var input_reader = std.io.bufferedReader(input_file_handle.reader());

    // Process files
    if (!invert_matches) {
        try processKeepLines(gpa, line_reader.reader(), input_reader.reader(), stdout);
    } else {
        try processInvertLines(gpa, line_reader.reader(), input_reader.reader(), stdout);
    }
}

fn printUsage(writer: anytype, program_name: []const u8) !void {
    try writer.print("Usage: {s} [-v] FILE1 FILE2\n\n", .{program_name});
    try writer.print("FILE1: line numbers (sorted, no dups, one-based), FILE2: input file\n", .{});
    try writer.print("-v : print all lines in F not named in L (invert)\n", .{});
    try writer.print("-V : print version and exit\n", .{});
}

fn processKeepLines(
    allocator: std.mem.Allocator,
    line_reader: anytype,
    input_reader: anytype,
    writer: anytype,
) !void {
    var line_buffer = std.ArrayList(u8).init(allocator);
    defer line_buffer.deinit();

    var input_buffer = std.ArrayList(u8).init(allocator);
    defer input_buffer.deinit();

    var current_line: usize = 0;

    // Process one line number at a time
    while (true) {
        line_buffer.clearRetainingCapacity();
        line_reader.readUntilDelimiterArrayList(&line_buffer, '\n', 1024) catch |err| {
            if (err == error.EndOfStream and line_buffer.items.len == 0) break;
            if (err != error.EndOfStream) return err;
            // Continue with partial line at end of file (no newline)
        };

        // Parse the current line number to print
        const to_print = std.fmt.parseInt(usize, std.mem.trim(u8, line_buffer.items, &std.ascii.whitespace), 10) catch {
            continue; // Skip invalid line numbers
        };

        // Read lines from input file until we reach the target line
        while (current_line != to_print) {
            input_buffer.clearRetainingCapacity();
            input_reader.readUntilDelimiterArrayList(&input_buffer, '\n', 4096) catch |err| {
                if (err == error.EndOfStream and input_buffer.items.len == 0) {
                    // Reached EOF before finding the line
                    break;
                }
                if (err != error.EndOfStream) return err;
                // Continue with partial line at end of file
            };

            current_line += 1;

            // If we found the target line, print it
            if (current_line == to_print) {
                try writer.print("{s}\n", .{input_buffer.items});
            }
        }
    }
}

fn processInvertLines(
    allocator: std.mem.Allocator,
    line_reader: anytype,
    input_reader: anytype,
    writer: anytype,
) !void {
    var line_buffer = std.ArrayList(u8).init(allocator);
    defer line_buffer.deinit();

    var input_buffer = std.ArrayList(u8).init(allocator);
    defer input_buffer.deinit();

    var current_line: usize = 0;
    var to_print: usize = undefined;
    var have_line_number = false;

    // Read first line number
    line_buffer.clearRetainingCapacity();
    line_reader.readUntilDelimiterArrayList(&line_buffer, '\n', 1024) catch |err| {
        if (err == error.EndOfStream and line_buffer.items.len == 0) {
            // No line numbers, print all input lines
            while (true) {
                input_buffer.clearRetainingCapacity();
                input_reader.readUntilDelimiterArrayList(&input_buffer, '\n', 4096) catch |err2| {
                    if (err2 == error.EndOfStream and input_buffer.items.len == 0) break;
                    if (err2 != error.EndOfStream) return err2;
                };
                try writer.print("{s}\n", .{input_buffer.items});
            }
            return;
        }
        if (err != error.EndOfStream) return err;
    };

    to_print = std.fmt.parseInt(usize, std.mem.trim(u8, line_buffer.items, &std.ascii.whitespace), 10) catch {
        // Invalid line number, print all input lines
        while (true) {
            input_buffer.clearRetainingCapacity();
            input_reader.readUntilDelimiterArrayList(&input_buffer, '\n', 4096) catch |err| {
                if (err == error.EndOfStream and input_buffer.items.len == 0) break;
                if (err != error.EndOfStream) return err;
            };
            try writer.print("{s}\n", .{input_buffer.items});
        }
        return;
    };
    have_line_number = true;

    // Main processing loop
    while (have_line_number) {
        // Read input lines until we reach a target line or end of file
        while (current_line < to_print) {
            input_buffer.clearRetainingCapacity();
            input_reader.readUntilDelimiterArrayList(&input_buffer, '\n', 4096) catch |err| {
                if (err == error.EndOfStream and input_buffer.items.len == 0) {
                    // Reached EOF
                    return;
                }
                if (err != error.EndOfStream) return err;
            };
            current_line += 1;

            // Print lines that aren't in the line number file
            if (current_line < to_print) {
                try writer.print("{s}\n", .{input_buffer.items});
            }
        }

        // Get next line number
        line_buffer.clearRetainingCapacity();
        line_reader.readUntilDelimiterArrayList(&line_buffer, '\n', 1024) catch |err| {
            if (err == error.EndOfStream and line_buffer.items.len == 0) {
                // No more line numbers, print rest of file
                have_line_number = false;
                break;
            }
            if (err != error.EndOfStream) return err;
        };

        if (have_line_number) {
            to_print = std.fmt.parseInt(usize, std.mem.trim(u8, line_buffer.items, &std.ascii.whitespace), 10) catch {
                // Invalid line number, print rest of file
                have_line_number = false;
                break;
            };
        }
    }

    // Print remaining lines from input file
    while (true) {
        input_buffer.clearRetainingCapacity();
        input_reader.readUntilDelimiterArrayList(&input_buffer, '\n', 4096) catch |err| {
            if (err == error.EndOfStream and input_buffer.items.len == 0) break;
            if (err != error.EndOfStream) return err;
        };
        try writer.print("{s}\n", .{input_buffer.items});
    }
}

// Copyright 2015 by Martin Czygan, <martin.czygan@uni-leipzig.de>
// Translated to Rust, 2025
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

use std::env;
use std::fs::File;
use std::io::{self, BufRead, BufReader, Write};
use std::process;

const PROGRAM_VERSION: &str = "0.1.5";

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();

    if args.len() == 2 && args[1] == "-V" {
        println!("{}", PROGRAM_VERSION);
        return Ok(());
    }

    if args.len() != 3 && args.len() != 4 {
        print_usage(&args[0]);
        return Ok(());
    }

    let mut invert_matches = false;
    let (line_file, input_file) = if args.len() == 4 && args[1] == "-v" {
        invert_matches = true;
        (&args[2], &args[3])
    } else {
        (&args[1], &args[2])
    };

    let line_reader = match File::open(line_file) {
        Ok(file) => BufReader::new(file),
        Err(_) => {
            eprintln!("failed to open line number file: {}", line_file);
            process::exit(1);
        }
    };

    let input_reader = match File::open(input_file) {
        Ok(file) => BufReader::new(file),
        Err(_) => {
            eprintln!("failed to open input file: {}", input_file);
            process::exit(1);
        }
    };

    if !invert_matches {
        process_keep_lines(line_reader, input_reader)?;
    } else {
        process_invert_lines(line_reader, input_reader)?;
    }

    io::stdout().flush()?;
    Ok(())
}

fn print_usage(program_name: &str) {
    println!("Usage: {} [-v] FILE1 FILE2\n", program_name);
    println!("FILE1: line numbers (sorted, no dups, one-based), FILE2: input file");
    println!("-v : print all lines in F not named in L (invert)");
    println!("-V : print version and exit");
}

fn process_keep_lines<R1: BufRead, R2: BufRead>(
    mut line_reader: R1,
    mut input_reader: R2,
) -> io::Result<()> {
    let mut line_buffer = String::new();
    let mut input_buffer = String::new();
    let mut current_line = 0;

    while line_reader.read_line(&mut line_buffer)? > 0 {
        if let Ok(to_print) = line_buffer.trim().parse::<usize>() {
            while current_line != to_print {
                input_buffer.clear();
                if input_reader.read_line(&mut input_buffer)? == 0 {
                    break;
                }
                current_line += 1;
            }
            if current_line == to_print {
                print!("{}", input_buffer);
            }
        }
        line_buffer.clear();
    }
    Ok(())
}

fn process_invert_lines<R1: BufRead, R2: BufRead>(
    mut line_reader: R1,
    mut input_reader: R2,
) -> io::Result<()> {
    let mut line_buffer = String::new();
    let mut input_buffer = String::new();
    let mut current_line = 0;
    if line_reader.read_line(&mut line_buffer)? > 0 {
        let mut to_print = match line_buffer.trim().parse::<usize>() {
            Ok(num) => num,
            Err(_) => return Ok(()),
        };

        line_buffer.clear();
        loop {
            while current_line < to_print {
                input_buffer.clear();
                if input_reader.read_line(&mut input_buffer)? == 0 {
                    return Ok(());
                }
                current_line += 1;

                if current_line < to_print {
                    print!("{}", input_buffer);
                }
            }
            if line_reader.read_line(&mut line_buffer)? > 0 {
                if let Ok(num) = line_buffer.trim().parse::<usize>() {
                    to_print = num;
                    line_buffer.clear();
                } else {
                    break;
                }
            } else {
                break;
            }
        }
        while input_reader.read_line(&mut input_buffer)? > 0 {
            print!("{}", input_buffer);
            input_buffer.clear();
        }
    }
    Ok(())
}

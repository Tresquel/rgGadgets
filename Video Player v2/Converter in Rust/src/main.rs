extern crate image;

use std::thread;
use std::sync::mpsc;
use image::GenericImageView;
use std::fs::{metadata, File};
use std::io::{Write, Result};
use std::path::Path;
use std::process::{Command, exit};
use std::time::Instant;
use std::{fs, env, str};

// ffmpeg stuff
fn find_toconvert_file() -> Option<String> {
    for entry in fs::read_dir(env::current_dir().unwrap()).unwrap() {
        if let Ok(entry) = entry {
            if let Some(file_name) = entry.file_name().to_str() {
                if file_name.starts_with("toconvert.") {
                    return Some(file_name.to_string());
                }
            }
        }
    }
    None
}

fn create_palette(file: &str, temp_dir: &str) {
    let output_file = format!("{}/palette.png", temp_dir);

    let status = Command::new("ffmpeg")
        .args(&[
            "-v",
            "quiet",
            "-stats",
            "-i",
            file,
            "-vf",
            "palettegen",
            &output_file,
        ])
        .status()
        .expect("Failed to execute command");

    if status.success() {
        println!("Palette created");
    } else {
        println!("Command failed with exit code {:?}", status.code());
    }
}

fn scale_down(file: &str, temp_dir: &str) {
    let output_file = format!("{}/video.avi", temp_dir);

    let status = Command::new("ffmpeg")
        .args(&[
            "-v",
            "quiet",
            "-stats",
            "-i",
            file,
            "-filter:v", "scale=-1:224",
            &output_file,
        ])
        .status()
        .expect("Failed to execute command");

    if status.success() {
        println!("Video scaled down");
    } else {
        println!("Command failed with exit code {:?}", status.code());
    }
}

fn split_video(file: &str, temp_dir: &str) {
    let output_file = format!("{}/palette.png", temp_dir);

    let status = Command::new("ffmpeg")
    .args(&[
        "-v",
        "quiet",
        "-stats",
        "-i",
        file,
        "-i",
        &output_file,
        "-filter_complex", "paletteuse",
        &format!("{}/frames/%d.png", temp_dir)
    ])
    .status()
    .expect("Failed to execute command");

    if status.success() {
        println!("Video split into frames");
    } else {
        println!("Command failed with exit code {:?}", status.code());
    }
}

fn count_frames(temp_dir: &str) -> i32 {
    let mut count: i32 = 0;

    let paths = fs::read_dir(&format!("{}/frames", temp_dir)).unwrap();

    for path in paths {
        // i have no clue what i wrote here
        if path.unwrap().path().to_str().unwrap().ends_with(".png") {
            count += 1
        }
    }

    return count;
}

fn extract_palette(temp_dir: &str) -> Vec<image::Rgb<u8>> {
    let mut palette: Vec<image::Rgb<u8>> = Vec::new();

    if let Ok(imag) = image::open(format!("{}/palette.png", temp_dir)) {
        let imag = imag.to_rgb8();
        let (x, y) = imag.dimensions();

        for ypos in 0..y {
            for xpos in 0..x {
                let pixel_rgb = imag.get_pixel(xpos, ypos);

                if !palette.contains(&pixel_rgb) {
                    palette.push(*pixel_rgb);
                }
            }
        }
    }

    palette
}

fn parse_fraction(input: &str) -> Option<(u32, u32)> {
    let parts: Vec<&str> = input.split('/').collect();
    if parts.len() == 2 {
        if let Ok(numerator) = parts[0].parse::<u32>() {
            if let Ok(denominator) = parts[1].parse::<u32>() {
                return Some((numerator, denominator));
            }
        }
    }
    None
}

fn get_video_frame_rate(video_path: &str) -> Option<u8>  {
    let output = Command::new("ffprobe")
        .args(&[
            "-v", "error",
            "-select_streams", "v:0",
            "-show_entries", "stream=r_frame_rate",
            "-of", "default=noprint_wrappers=1:nokey=1",
            video_path,
        ])
        .output()
        .ok()?;

    if output.status.success() {
        let frame_rate_str = str::from_utf8(&output.stdout).ok()?.trim();

        if let Some((numerator, denominator)) = parse_fraction(frame_rate_str) {
            let rounded_frame_rate = ((numerator as f64) / (denominator as f64)).round() as u8;
            return Some(rounded_frame_rate);
        }
    }

    None
}

fn find_color_index(palette: &Vec<image::Rgb<u8>>, target_color: &image::Rgb<u8>) -> Option<usize> {
    palette.iter().position(|color| color == target_color)
}

fn convert_frame(temp_dir: &str, frame: i32, palette: &Vec<image::Rgb<u8>>) -> Vec<u8> {
    let start = Instant::now();
    let mut frame_data = Vec::new();

    if let Ok(imag) = image::open(format!("{}/frames/{}.png", temp_dir, frame)) {
        let imag = imag.to_rgb8();
        let (x, y) = imag.dimensions();

        for ypos in 0..y {
            for xpos in 0..x {
                let pixel_rgb = imag.get_pixel(xpos, ypos);
                if let Some(index) = find_color_index(&palette, pixel_rgb) {
                    frame_data.push(index as u8);
                } else {
                    println!("Target color not found in the palette");
                }
            }
        }
    }

    let end = Instant::now();
    let elapsed = end.duration_since(start);
    println!("Frame {} converted in {:?}", frame, elapsed);

    frame_data
}

fn main() -> Result<()> {
    // check if the temp directory exists
    let temp_dir = "./temp";

    if !metadata(&temp_dir).is_ok() {
        if let Err(err) = fs::create_dir(&temp_dir) {
            eprintln!("Couldn't create temp directory, make sure it exists.\nError: {}", err);
            exit(0);
        }

    }
    if !metadata(&format!("{}/frames", temp_dir)).is_ok() {
        if let Err(err) = fs::create_dir(&format!("{}/frames", temp_dir)) {
            eprintln!("Couldn't create frames directory, make sure it exists.\nError: {}", err);
            exit(0);
        }
    }
    // find the file to convert
    let to_convert: String = find_toconvert_file().unwrap_or_default();

    if to_convert == "" {
        println!("Couldn't find a file to convert, aborting...");
        exit(0);
    }
    // ffmpeg stuff
    println!("Creating palette...");
    create_palette(&to_convert, &temp_dir);

    println!("Scaling video down...");
    scale_down(&to_convert, &temp_dir);

    println!("Splitting into frames...");
    split_video(&format!("{}/video.avi", temp_dir), &temp_dir);

    let frame_count = count_frames(&temp_dir);
    println!("Detected {} frames in total", &frame_count);

    if frame_count == 0 {
        println!("Why is there no frames??");
        exit(0);
    }


    println!("Starting conversion...");
    let mut file = File::create("video.rgv")?;
    // headers
    file.write_all(b"RGVIDEO")?;
    // video width
    let mut vid_width: u32 = 0;

    if let Ok(img) = image::open(&Path::new(&format!("{}/frames/1.png", temp_dir))) {
        let dimensions = img.dimensions();

        vid_width = dimensions.0 as u32; // compatibility with the python version
        file.write_all(&vid_width.to_le_bytes())?;
    } else {
        eprintln!("Failed to open the image.");
        exit(0)
    }

    //framerate, frame count and writing the width to the file
    let frame_rate = get_video_frame_rate(&format!("{}/video.avi", temp_dir));
    let u32_frame_count = frame_count as u32; // compatibility with the python version
    file.write_all(&u32_frame_count.to_le_bytes())?;

    file.write_all(&[frame_rate.unwrap()])?;

    let palette = extract_palette(temp_dir);

    // write all the colors in the palette
    for color in &palette {
        for component in &color.0 {
            file.write_all(&[*component])?;
        }
    }

    file.write_all(b"VIDEODATA")?; // begin of video data

    println!("Starting frame conversion...");
    let start = Instant::now();
    // hyperthreading
    let (tx, rx) = mpsc::channel();

    for i in 1..=frame_count {
        let tx = tx.clone();
        let temp_dir = temp_dir.clone();
        let palette = palette.clone();
        // this will spawn a ton of threads causing the cpu usage to spike
        // won't be a problem for videos smaller than it's possible to play
        thread::spawn(move || {
            let frame_data = convert_frame(&temp_dir, i, &palette);
            tx.send((i, frame_data)).expect("Failed to send frame data");
        });
    }

    let mut results: Vec<(i32, Vec<u8>)> = Vec::with_capacity(frame_count as usize);

    for _ in 1..=frame_count {
        let (i, frame_data) = rx.recv().expect("Failed to receive frame data");
        results.push((i, frame_data));
    }
    // sort and write to file
    results.sort_by_key(|&(i, _)| i);

    for (_, frame_data) in results {
        file.write_all(&frame_data)?;
    }

    let end = Instant::now();
    let elapsed = end.duration_since(start);
    println!("{} frames converted in {:?}", frame_count, elapsed);

    // for i in 1..=frame_count {
    //     let frame_data = convert_frame(&temp_dir, i as u8, &palette);
    //     file.write_all(&frame_data)?;
    // }

    // cleanup
    match fs::remove_dir_all(&temp_dir) {
        Ok(_) => {
            println!("Done");
            exit(0);
        },
        Err(e) => {
            eprintln!("Couldn't clean up: {}", e);
            exit(0);
        }
    }

   Ok(())
}

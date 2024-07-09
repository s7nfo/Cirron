use libloading::{Library, Symbol};
use cty;

const CIRRONLIB: &str = "./cirronlib.so";
// this means its in rust/cirronlib.so

#[repr(C)]
#[derive(Default)]
#[derive(Debug)]
pub struct Counter {
  pub time_enabled_ns: cty::c_ulong,
  pub instruction_count: cty::c_ulong,
  pub branch_misses: cty::c_ulong,
  pub page_faults: cty::c_ulong
}

fn get_cirronlib() -> Library {
  unsafe {
    libloading::Library::new(CIRRONLIB)
      .expect("Failed to load lib")
  }
}

fn start() -> Result<u32, Box<dyn std::error::Error>> {
  let lib = get_cirronlib();
  unsafe {
    let start: Symbol<unsafe extern fn() -> u32> = lib.get(b"start").unwrap();
    Ok(start())
  }
}

fn end(fd: u32, counter: &mut Counter) -> Result<u32, Box<dyn std::error::Error>> {
  let lib = get_cirronlib();

  unsafe {
    let end: Symbol<unsafe extern fn(u32, *mut Counter) -> u32> = lib.get(b"end").unwrap();
    Ok(end(fd, counter))
  }
}

pub fn main() {

  let mut counter = Counter { ..Default::default() };

  let result = start().unwrap();
  println!("Hello");
  end(result, &mut counter).expect("Failed to start");

  println!("{:#?}", counter);
  println!("Goodbye!");
}

// Need sudo priveleges
// sudo cargo test
#[test]
fn test_start() {
  assert_eq!(start().expect("Failed to start"), 0);
}

#[test]
fn test_end() {
  let mut counter = Counter { ..Default::default() };
  assert_eq!(end(0, &mut counter).expect("Failed to start"), 0);
}
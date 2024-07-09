use libloading::{Library, Symbol};
use std::os::raw::{c_int, c_ulonglong};

const CIRRONLIB: &str = "./cirronlib.so";
// this means its in rust/cirronlib.so

#[repr(C, align(8))]
#[derive(Default, Debug)]
pub struct Counter {
  pub time_enabled_ns: c_ulonglong,
  pub instruction_count: c_ulonglong,
  pub branch_misses: c_ulonglong,
  pub page_faults: c_ulonglong
}

fn get_cirronlib() -> Library {
  unsafe {
    libloading::Library::new(CIRRONLIB)
      .expect("Failed to load lib")
  }
}

fn start() -> Result<c_int, Box<dyn std::error::Error>> {
  let lib = get_cirronlib();
  unsafe {
    let start: Symbol<unsafe extern fn() -> c_int> = lib.get(b"start").unwrap();
    Ok(start())
  }
}

fn end(fd: c_int, counter: &mut Counter) -> Result<c_int, Box<dyn std::error::Error>> {
  let lib = get_cirronlib();

  unsafe {
    let end_c: Symbol<unsafe extern fn(c_int, *mut Counter) -> c_int> = lib.get(b"end").unwrap();
    Ok(end_c(fd, counter as *mut Counter))
  }
}

pub fn main() {

  let mut counter = Counter::default();
  println!("{:#?}", counter);

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
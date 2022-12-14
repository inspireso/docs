fn main() {
  let n1: Result<i32, &'static str> = Ok(6);
  let n2 = n1
      .and_then(|x: i32| {
          println!("x * 2");
          Ok(x * 2)
      })
      .and_then(|_x: i32| {
          println!("x + 1");
          Err("在 x + 1 这一步出错")
      })
      .and_then(|x: i32| {
          println!("x * x");
          Ok(x * x)
      });

  println!("{:?}", n2);
}

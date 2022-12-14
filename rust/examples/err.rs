use std::num::ParseIntError as E;
// 使用 and_then
fn add1(a: &str, b: &str) -> Result<i32, E> {
    a.parse::<i32>()
        .and_then(|a| b.parse::<i32>().and_then(|b| Ok(a + b)))
}
// 使用问号表达式
fn add2(a: &str, b: &str) -> Result<i32, E> {
    Ok(a.parse::<i32>()? + b.parse::<i32>()?)
}

fn main() {
    println!("{:?}", add1("11", "22"));
    println!("{:?}", add2("11", "22"));
    /*
    Ok(33)
    Ok(33)
    */
    println!("{:?}", add1("a", "b"));
    println!("{:?}", add2("a", "b"));
    /*
    Err(ParseIntError { kind: InvalidDigit })
    Err(ParseIntError { kind: InvalidDigit })
    */
}

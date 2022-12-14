fn test(age: u8) -> Result<String, String> {
    if age >= 18 {
        Ok(String::from("欢迎来到极乐净土"))
    } else {
        Err(String::from("未成年"))
    }
}

fn main() {
    let res = test(18);
    println!("{:?}", res);
    /*
    Ok("欢迎来到极乐净土")
    */
    let res = test(17);
    println!("{:?}", res);
    /*
    Err("未成年")
    */

    // 可以使用 match 拿到 Ok 里面的值
    // 但还有没有更简单的办法呢
    let res = test(20).unwrap();
    println!("{}", res);
    /*
    欢迎来到极乐净土
    */
}

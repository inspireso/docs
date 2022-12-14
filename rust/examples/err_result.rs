// 计算两个 i32 的商
fn divide(a: i32, b: i32) -> Result<i32, &'static str> {
    let ret: Result<i32, &'static str>;
    // 如果 b != 0，返回 Ok(a / b)
    if b != 0 {
        ret = Ok(a / b);
    } else {
        // 否则返回除零错误
        ret = Err("ZeroDivisionError: division by zero")
    }
    return ret;
}

fn main() {
    let a = divide(100, 20);
    println!("a = {:?}", a);

    let b = divide(100, 0);
    println!("b = {:?}", b);
    /*
    a = Ok(5)
    b = Err("ZeroDivisionError: division by zero")
    */

    // 将返回值和 5 相加，由于 a 是 Ok(i32)
    // 显然它不能直接和 i32 相加
    let a = divide(100, 20);
    match a {
        Ok(i) => println!("a + 5 = {}", i + 5),
        Err(error) => println!("出错啦: {}", error),
    }

    let b = divide(100, 0);
    match b {
        Ok(i) => println!("b + 5 = {}", i + 5),
        Err(error) => println!("出错啦: {}", error),
    }
    /*
    a + 5 = 10
    出错啦: ZeroDivisionError: division by zero
    */
}

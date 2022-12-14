fn main() {
    let n1: Result<i32, &'static str> = Ok(123);
    // 如果是 Ok(...)，那么将里面的值乘以 2
    // 如果是 Err(...)，那么保持不变
    // 你也许会这么做
    let n2 = match n1 {
        Ok(val) => Ok(val * 2),
        Err(success) => Err(success),
    };
    println!("{:?}", n2); // Ok(246)

    // 上面是一种做法，但还可以通过 and_then 进行简化
    // 如果 n1 是 Ok(...)，那么会将 Ok 里面的值取出来
    // 放到匿名函数当中调用
    let n2 = n1.and_then(|x: i32| Ok(x * 2));
    println!("{:?}", n2); // Ok(246)

    // 如果 n1 是 Err(...)
    let n1 = Err("出错啦");
    // 那么不会执行 and_then，直接返回 Err(...)
    let n2 = n1.and_then(|x: i32| {
        println!("此处不会打印");
        Ok(x * 2)
    });
    println!("{:?}", n2); // Err("出错啦")
}

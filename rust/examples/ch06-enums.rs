#[derive(Debug)] // 这样可以立刻看到州的名称
enum UsState {
    Alabama,
    Alaska,
    // --snip--
}

enum Coin {
    Penny,
    Nickel,
    Dime,
    Quarter(UsState),
}

fn value_in_cents(coin: Coin) -> u8 {
    match coin {
        Coin::Penny => 1,
        Coin::Nickel => 5,
        Coin::Dime => 10,
        Coin::Quarter(state) => {
            println!("State quarter from {:?}!", state);
            25
        }
    }
}

fn plus_one(x: Option<i32>) -> Option<i32> {
    match x {
        None => None,
        Some(i) => Some(i + 1),
    }
}
#[allow(unused)]
fn main() {
    println!("-------- match ------------");

    println!("{}", value_in_cents(Coin::Penny));

    println!("{}", value_in_cents(Coin::Nickel));

    println!("{}", value_in_cents(Coin::Dime));

    println!("{}", value_in_cents(Coin::Quarter(UsState::Alabama)));

    println!("{}", value_in_cents(Coin::Quarter(UsState::Alabama)));
    println!("{}", value_in_cents(Coin::Quarter(UsState::Alaska)));

    println!("-------- Option<T> ------------");

    let five = Some(5);
    let six = plus_one(five);
    println!("{:?} plus one = {:?}", five, six);
    let none = plus_one(None);
    println!("None plus one = {:?}", none);

    println!("-------- if let ------------");

    let coin = Coin::Penny;
    let mut count = 0;
    if let Coin::Quarter(state) = coin {
        println!("State quarter from {:?}!", state);
    } else {
        count += 1;
    }
}

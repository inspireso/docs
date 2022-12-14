fn main() {
    let width1 = 30;
    let height1 = 50;
    println!(
        "The area of the rectangle is {} square pixels.",
        area(width1, height1)
    );

    // 元组
    let rect1 = (30, 50);
    println!(
        "The area of the rectangle is {} square pixels.",
        area1(rect1)
    );

    // 结构
    let rect2 = Rectangle {
        width: 30,
        height: 50,
    };
    println!("rect2 is {:?}", rect2);
    println!(
        "The area of the rectangle is {} square pixels.",
        area2(rect2)
    );

    let rect3 = Rectangle {
        width: 30,
        height: 50,
    };
    println!("rect3 is {:?}", rect3);
    println!(
        "The area of the rectangle is {} square pixels.",
        rect3.area()
    );

    let rect1 = Rectangle {
        width: 30,
        height: 50,
    };
    let rect2 = Rectangle {
        width: 10,
        height: 40,
    };
    let rect3 = Rectangle {
        width: 60,
        height: 45,
    };

    println!(
        "Can rect1:{:?} hold rect2:{:?}? {}",
        rect1,
        rect2,
        rect1.can_hold(&rect2)
    );
    println!(
        "Can rect1:{:?} hold rect3:{:?}? {}",
        rect1,
        rect3,
        rect1.can_hold(&rect3)
    );

    let sq = Rectangle::square(3);
    println!("{:?}", sq);
    
}

fn area(weight: u32, height: u32) -> u32 {
    weight * height
}

fn area1(dimensions: (u32, u32)) -> u32 {
    dimensions.0 * dimensions.1
}

#[derive(Debug)]
struct Rectangle {
    width: u32,
    height: u32,
}

impl Rectangle {
    fn area(&self) -> u32 {
        &self.height * &self.height
    }

    fn can_hold(&self, other: &Rectangle) -> bool {
        self.width > other.width && self.height > other.height
    }

    fn square(size: u32) -> Rectangle {
        Rectangle {
            width: size,
            height: size,
        }
    }
}
fn area2(rectangle: Rectangle) -> u32 {
    rectangle.width * rectangle.height
}

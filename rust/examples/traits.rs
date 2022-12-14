struct Number(i32);

trait SomeTrait<T: PartialOrd> {
    fn compare(&self, n: T) -> bool;
}

impl SomeTrait<i32> for Number {
    fn compare(&self, n: i32) -> bool {
        self.0 >= n
    }
}

fn main() {
    let num = Number(66);
    println!("{:?}", num.compare(67));
    println!("{:?}", num.compare(65));
}

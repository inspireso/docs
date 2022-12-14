mod a {
    pub mod b {
        mod c {
            pub fn func1() {
                println!("我是 func1")
            }
        }
        // func2 所在的模块是 b
        pub fn func2() {
            // 两者是等价的
            // 但是使用 self，语义会更加的明确
            c::func1();
            self::c::func1();
        }
    }
}
fn main() {
    a::b::func2();
    /*
    我是 func1
    我是 func1
    */
}

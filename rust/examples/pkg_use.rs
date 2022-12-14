mod a {
    pub mod b {
        pub mod c {
            pub fn mod_c_f3() {
                println!("我是模块 a/b/c 下的函数 f3");
            }
        }
    }
}

fn main() {
    // 引入指定模块，这里通过绝对路径
    use crate::a::b;
    // 然后便可以通过 b 来进行查找
    b::c::mod_c_f3(); //我是模块 a/b/c 下的函数 f3

    // 引入模块，通过相对路径
    use a::b::c;
    c::mod_c_f3(); //我是模块 a/b/c 下的函数 f3

    // 还可以导入到某一个具体的函数
    use a::b::c::mod_c_f3;
    mod_c_f3(); //我是模块 a/b/c 下的函数 f3
}

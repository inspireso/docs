## vi

### 查找

```sh
/xxx(?xxx)   
表示在整篇文档中搜索匹配xxx的字符串, / 表示向下查找, ? 表示向上查找其中xxx可以是正规表达式,关于正规式就不多说了.
一般来说是区分大小写的, 要想不区分大小写, 那得先输入:set ignorecase
查找到以后, 再输入 n 查找下一个匹配处, 输入 N 反方向查找

*(#)    
当光标停留在某个单词上时, 输入这条命令表示查找与该单词匹配的下(上)一个单词 同样, 再输入 n 查找下一个匹配处, 输入 N 反方向查找

g*(g#)       
此命令与上条命令相似, 只不过它不完全匹配光标所在处的单词, 而是匹配包含该单词的所有字符串

gd              
本命令查找与光标所在单词相匹配的单词, 并将光标停留在文档的非注释段中第一次出现这个单词的地方

%     
本命令查找与光标所在处相匹配的反括号, 包括 () [] { }

f(F)x           
本命令表示在光标所在行进行查找, 查找光标右(左)方第一个x字符
找到后:
输入 ; 表示继续往下找
输入 , 表示反方向查找
```

### 快速移动光标

```sh
w(e)          移动光标到下一个单词
b             移动光标到上一个单词
0             移动光标到本行最开头
^             移动光标到本行最开头的字符处
$             移动光标到本行结尾处

H             移动光标到屏幕的首行
M             移动光标到屏幕的中间一行
L             移动光标到屏幕的尾行
gg            移动光标到文档首行
G             移动光标到文档尾行
c-f           (即 ctrl 键与 f 键一同按下) 本命令即 page down
c-b           (即 ctrl 键与 b 键一同按下, 后同) 本命令即 page up

''            此命令相当有用, 它移动光标到上一个标记处, 比如用 gd, * 等查找到某个单词后, 再输入此命令则回到上次停留的位置

'             此命令相当好使, 它移动光标到上一次的修改行

`             此命令相当强大, 它移动光标到上一次的修改点
```

### 拷贝, 删除与粘贴

```sh
yw 　　 表示拷贝从当前光标到光标所在单词结尾的内容
dw 　　 表示删除从当前光标到光标所在单词结尾的内容
y0 　　 表示拷贝从当前光标到光标所在行首的内容
d0 　　 表示删除从当前光标到光标所在行首的内容
y$ 　　 表示拷贝从当前光标到光标所在行尾的内容
d$ 　　 表示删除从当前光标到光标所在行尾的内容
yfa 　　表示拷贝从当前光标到光标后面的第一个a字符之间的内容
dfa 　　表示删除从当前光标到光标后面的第一个a字符之间的内容
yy 　　表示拷贝光标所在行
dd 　　表示删除光标所在行
D 　　 表示删除从当前光标到光标所在行尾的内容
```

### 数字与命令

```sh
5fx 　　　　 表示查找光标后第5个x字符
5w(e) 　　   移动光标到下五个单词
5yy 　　　　  表示拷贝光标以下 5 行
5dd 　　　　  表示删除光标以下 5 行
y2fa 　　　　 表示拷贝从当前光标到光标后面的第二个a字符之间的内容
:12,24y 　　 表示拷贝第12行到第24行之间的内容
:12,y 　　　　表示拷贝第12行到光标所在行之间的内容
:,24y 　　　　表示拷贝光标所在行到第24行之间的内容 删除类似
```

### 快速输入字符

```sh
c-p(c-n) 在编辑模式中, 输入几个字符后再输入此命令则 vi 开始向上(下)搜索开头与其匹配的单词并补齐, 不断输入此命令则循环查找 此命令会在所有在这个 vim 程序中打开的文件中进行匹配

c-x-l 在编辑模式中, 此命令快速补齐整行内容, 但是仅在本窗口中出现的文档中进行匹配

c-x-f 在编辑模式中, 这个命令表示补齐文件名 如输入:/usr/local/tom 后再输入此命令则它会自动匹配出:/usr/local/tomcat/

abbr 即缩写 这是一个宏操作, 可以在编辑模式中用一个缩写代替另一个字符串 比如编写java文件的常常输入 Systemoutprintln, 这很是麻烦, 所以应该用缩写来减少敲字 可以这么做:
:abbr sprt Systemoutprintln
以后在输入sprt后再输入其他非字母符号, 它就会自动扩展为Systemoutprintln
```
### 替换

```sh
:s/aa/bb/g 　　 　　 将光标所在行出现的所有包含 aa 的字符串中的 aa 替换为 bb
:s/\/bb/g 　　  　　 将光标所在行出现的所有 aa 替换为 bb, 仅替换 aa 这个单词
:%s/aa/bb/g 　　　　 将文档中出现的所有包含 aa 的字符串中的 aa 替换为 bb
:12,23s/aa/bb/g 　　将从12行到23行中出现的所有包含 aa 的字符串中的 aa 替换为 bb
:12,23s/^/#/ 　　　　将从12行到23行的行首加入 # 字符
:%s= *$== 　　　　　　将所有行尾多余的空格删除
:g/^\s*$/d 　　　　　将所有不包含字符(空格也不包含)的空行删除
```
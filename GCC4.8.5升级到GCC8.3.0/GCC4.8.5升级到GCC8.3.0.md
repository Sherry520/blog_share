---
html:
    toc: true
    # number_sections: true # 标题开头加上编号
    toc_depth: 6
    toc_float:
        collapsed: false # 控制文档第一次打开时目录是否被折叠
        smooth_scroll: true # 控制页面滚动时，标题是否会随之变化
---

[toc]

---

# gcc 4.8.5升级到8.3.0
不能升级到最新版本，不支持

# 1. 下载gcc8.3.0源码
```bash
cd /public/home/04034/sourcecode
wget mirror.hust.edu.cn/gnu/gcc/gcc-8.3.0/gcc-8.3.0.tar.gz

# 解压gcc安装包
tar -zxf gcc-8.3.0.tar.gz

# 创建gcc安装路径
mkdir -p /usr/local/gcc-8.3.0
```

# 2. 验证依赖
```bash
cd gcc-8.3.0
./contrib/download_prerequisites --verify
./contrib/download_prerequisites  # 缺失则重新下载
```

# 3. 新建构建目录
```bash
mkdir ../gcc-build && cd ../gcc-build
```

# 4. 配置（关键选项）
```bash
../gcc-8.3.0/configure \
    --prefix=/usr/local/gcc-8.3.0 \
    --enable-threads=posix --disable-multilib \
    --enable-languages=c,c++,fortran \
    --disable-bootstrap
```

# 5. 清除干扰变量
```
unset LIBRARY_PATH CPATH C_INCLUDE_PATH PKG_CONFIG_PATH CPLUS_INCLUDE_PATH INCLUDE
```

# 6. 编译安装
```bash
make -j8 | tee build.log  # 保存日志
make install
```
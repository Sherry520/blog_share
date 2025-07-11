`LDheatmap` 已经进入了 CRAN 存档中，不可以直接通过 `install.packages()` 来安装了。

为了加速安装，此处使用国内**清华镜像**和**西湖大学镜像**；西湖大学镜像支持旧版本的 Bioconductor。
```r
options("repos" = c(CRAN="https://mirrors.tuna.tsinghua.edu.cn/CRAN/"))
options(BioC_mirror = "https://mirrors.westlake.edu.cn/bioconductor")
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("snpStats")
install.packages(c('genetics', 'Rcpp'))
install.packages("https://cran.r-project.org/src/contrib/Archive/LDheatmap/LDheatmap_1.0-6.tar.gz", repo=NULL, type="source")
```
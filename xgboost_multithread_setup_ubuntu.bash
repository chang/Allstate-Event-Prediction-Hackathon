#!/bin/bash

# for setup on MacOS: https://www.ibm.com/developerworks/community/blogs/jfp/entry/Installing_XGBoost_on_Mac_OSX?lang=en
#					            http://stackoverflow.com/questions/40942893/how-to-install-xgboost-on-osx-with-multi-threading
# MacOS's default c++ compiler (OpenMP) doesn't support multithreading, so to get the performance boost we need to
# build xgboost from source with g++, and install it using devtools in R.

# this script sets up xgboost on an Ubuntu AWS cluster. I'm using a c4.4xlarge at the moment.
# RUN AS SUDO - TO INSTALL PACKAGES, R NEEDS ROOT ACCESS
cd ~

sudo apt-get update
sudo apt-get install build-essential libcurl4-openssl-dev libxml2-dev libssl-dev  # dependencies

# install gcc-6
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt-get install gcc-6 g++-6

# install r-base and r-base-dev directly from CRAN, Ubuntu Software Center is unfortunately always out of date
sudo echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | sudo tee -a /etc/apt/sources.list
gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
gpg -a --export E084DAB9 | sudo apt-key add -
sudo apt-get update
sudo apt-get install r-base r-base-dev

# clone xgboost from git repo
git clone --recursive https://github.com/dmlc/xgboost

# set g++ compiler to gcc-5 for multithreading support
sed -ie "s/# export CC = gcc/export CC = gcc-6/g" xgboost/make/config.mk
sed -ie "s/# export CXX = g++/export CXX = g++-6/g" xgboost/make/config.mk

# build xgboost
cd xgboost
cp make/config.mk .
make -j16

# update R, install devtools, and finally install xgboost
sudo apt install libssl-dev libcurl4-openssl-dev
sudo R -q -e "install.packages(c('curl', 'httr', 'git2r', 'devtools'), repos='http://cran.rstudio.com/')"
sudo R -q -e "devtools::install('R-package')"
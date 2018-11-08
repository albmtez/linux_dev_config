# Dev environment configuration

# Dev base dir
export DEV_BASE=$HOME/dev

# Git config
export GIT_HOME=$DEV_BASE/git/default
export PATH=$GIT_HOME/bin:$PATH

# Python config
export PYTHONPATH=$DEV_BASE/python/default
export PATH=$PYTHONPATH/bin:$PATH

# Go config
export GOROOT=$DEV_BASE/go/default
export GOPATH=$DEV_BASE/code/go
export PATH=$GOROOT/bin:$PATH

# NodeJS config
export NODEJS_HOME=$DEV_BASE/nodejs/default/bin
export PATH=$NODEJS_HOME:$PATH

# Java config
export JAVA_HOME=$DEV_BASE/jdk/default
export PATH=$JAVA_HOME/bin:$PATH

# Maven config
export MAVEN_HOME=$DEV_BASE/apache-maven/default
export PATH=$MAVEN_HOME/bin:$PATH

# Maven config
export ANT_HOME=$DEV_BASE/apache-ant/default
export PATH=$ANT_HOME/bin:$PATH

# MongoDB config
export MONGODB_HOME=$DEV_BASE/mongodb/default
export PATH=$MONGODB_HOME/bin:$PATH

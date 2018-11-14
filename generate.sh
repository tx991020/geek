#!/usr/bin/env bash
daopkgname=dao
cachepkgname=cache
redispkgname=redis
setuppkgname=setup
daopkgpath=seed/$daopkgname
cachepkgpath=seed/$cachepkgname
redispkgpath=seed/$redispkgname
setuppkgpath=seed/$setuppkgname

go run dbgenerator.go -dbuser=root -dbpassword=123456 -dbaddress=127.0.0.1:3306 -dbname=api -daopkgname=$daopkgname -cachepkgname=$cachepkgname redispkgname=$redis -setuppkgname=$setup \
-taglabel=json -daopkgpath=$daopkgpath -cachepkgpath=$cachepkgpath -redispkgpath=$redispkgpath -setuppkgpath=$setuppkgpath \
gofmt -w generated/


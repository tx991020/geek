# Create a Gin/iris+Gorm+Redigo Restful API  Application
# 可选择生成grpc or http server 代码
# 一分钟由数据库生成一个后端Restful API  Application

```go get github.com/tx991020/geek```

### 第一个参数:生成的项目名,第二个参数 本地mysql连接, 第三个参数 选择的database name
 ```
 geek new gin go-api "root:123456@tcp(127.0.0.1:3306)" dbname
```


### 三级缓存
- memory cache
- redis dao cache
- redis url cache
- grpc
- runtime memstats
- cache
- session
- viper
- go-sh
- go-machinery
- zap
- jwt
- k8s
- excel
- alimsg

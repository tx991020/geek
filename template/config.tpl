# 服务名称
app_name = "logic"
# 模式，可选值：prod, dev。生产环境请设置为prod
mode = "dev"
port = ":5000"
# 生成jwt token的密钥
secret = "qwe"

# 外部缓存设置，都是redis的配置
[redis]
    server = "127.0.0.1:6379"
    password = ""
    database = 1
    max_idle = 100
    max_active = 500
    idle_timeout = 120
    redis_key_lifespan = 300
    cache_purge_interval = 300
    lifespan = 60


[log]
    # 日志输出目标，支持: file, console。如果包括file，需要指定log_dir
    output = "file"
    log_dir = "logs"

[database]
    # 使用mysql做为我们的数据库
    conn_str = "root:123456@tcp(127.0.0.1:3306)/api?charset=utf8mb4&parseTime=true&loc=Local"
    max_idle_conn = 30
    max_open_conn = 50

[sentry]
    dsn = "https://dd6790ce5bfe4b02a281aeed2bd27218:d999fcd0b8f244ad9b5bb53ebe0020f2@sentry.pipacoding.com/6"

[rabbitmq]
    conn_str = "amqp://guest:guest@10.200.11.62:5672/"

# 路由分组：外部访问，内部访问。
[router_group]
     app_path_group = "logic/v2"
     internal_path_group = "logic/v2/internal"

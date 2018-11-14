package {package}


import (
	"fmt"
	 "github.com/tx991020/utils"
	"github.com/spf13/viper"
	"github.com/DeanThompson/ginpprof"
	"{AppName}/redis"
	"{AppName}/cache"
	"{AppName}/dao"
	"{AppName}/handler"
	"github.com/gin-gonic/gin"

)

func ConfigInit() {
	viper.SetConfigName("config")
	viper.AddConfigPath(".")
	err := viper.ReadInConfig() // 搜索路径，并读取配置数据
	if err != nil {
		panic(fmt.Errorf("Fatal error config file: %s \n", err))
	}
	fmt.Println(viper.AllKeys())

}

//func InitLogs() {
//	switch config.Cfg().Log.Output {
//	case "file":
//		var logDir = config.Cfg().Log.LogDir
//		if logDir != "" {
//			if err := os.MkdirAll(logDir, os.ModePerm); err != nil {
//				logs.Critical("create logs folder fails: %s", err.Error())
//				panic(err.Error())
//			}
//		}
//		var fileCfg = fmt.Sprintf(`{"filename":"%s","level":7,"maxlines":0,"maxsize":0,"daily":true,"maxdays":10}`, logDir+"/logic.log")
//		logs.SetLogger(logs.AdapterFile, fileCfg)
//	default:
//		logs.SetLogger(logs.AdapterConsole)
//	}
//
//	// set logger to gin
//	gin.DefaultWriter = logs.GetBeeLogger()
//	gin.DefaultErrorWriter = logs.ErrWriter{}
//
//	var mode = config.Cfg().Mode
//	if mode == "dev" {
//		logs.SetLevel(logs.LevelDebug)
//		gin.SetMode(gin.DebugMode)
//	} else {
//		var sentryDsn = config.Cfg().Sentry.Dsn
//		if sentryDsn != "" {
//			var serviceName = config.Cfg().ServiceName
//			logs.SetupSentry(sentryDsn, serviceName)
//		}
//
//		logs.SetLevel(logs.LevelInformational)
//		gin.SetMode(gin.ReleaseMode)
//	}
//}

func ServerInit() {

	dao.DatabaseInit(viper.GetString("database.conn_str"), viper.GetInt("database.max_idle_conn"), viper.GetInt("database.max_open_conn"), viper.GetString("mode") == "dev")

	cache.CacheInit(
		viper.GetString("redis.server"),
		viper.GetString("redis.password"),
		viper.GetInt("redis.database"),
		viper.GetInt("redis.maxIdle"),
		viper.GetInt("redis.maxActive"),
		viper.GetInt("redis.idle_timeout"),
		viper.GetInt("redis.redis_key_lifespan"),
		viper.GetInt("redis.cache_purge_interval"),
		viper.GetInt("redis.lifespan"),
	)

	redis.Setup(viper.GetString("redis.server"), viper.GetString("redis.password"), viper.GetInt("redis.database"))

    r :=gin.Default()
	ginpprof.Wrap(r)
	r.Use(gin.Recovery())

	handlerSetup(r)
	r.Run(viper.GetString("port"))
}

func handlerSetup(r gin.IRouter) {
	var rs = r.Group(viper.GetString("app_name"))
	rs.GET("/ping", func(c *gin.Context) {
		c.Writer.Write([]byte("pong"))
	})

	rs.Use(utils.GJsonResponse)
	handler.HandlerInit(rs)

}

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

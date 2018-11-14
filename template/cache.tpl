package {package}



type CacheConfig struct {
	Server             string   `json:"server"`                 // redis address
	Password           string   `json:"password"`               // redis password
  	Database           int      `json:"database"`               // redis database
	MaxIdle            int      `json:"maxIdle"`                // redis max idle connections
	MaxActive          int      `json:"maxActive"`              // redis max active connections
	IdleTimeout        int      `json:"idleTimeout"`            // redis idle connection timeout, in seconds
	RedisKeyLifespan   int      `json:"redisKeyLifespan"`       // redis key lifespan, in seconds
	CachePurgeInterval int      `json:"cachePurgeInterval"`     // memory cache purge interval, in seconds
	Lifespan           int      `json:"lifespan"`               // memory cache k-v lifespan, in seconds

}

var cacheInitFuncs = map[string]func(c *CacheConfig){
  {namelist}
}



func CacheInit(server, passwd string, dbNum, maxIdle, maxActive, idleTimeout, keyLifeSpan, purgeInterval, lifeSpan int) {
	var cc = &CacheConfig{
		Server:             server,
		Password:           passwd,
		Database:           dbNum,
		MaxIdle:            maxIdle,
		MaxActive:          maxActive,
		IdleTimeout:        idleTimeout,
		RedisKeyLifespan:   keyLifeSpan,
		CachePurgeInterval: purgeInterval,
		Lifespan:           lifeSpan,
	}
	for _, f := range cacheInitFuncs {
		f(cc)
	}
}

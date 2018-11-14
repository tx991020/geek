package redis

import (
	"sync"
	"time"

	"github.com/garyburd/redigo/redis"
)

var redisOnce sync.Once
var redisInstance *htRedis

type htRedis struct {
	pool *redis.Pool
}

func Setup(connStr, auth string,db int) {
	redisOnce.Do(func() {
		redisInstance = &htRedis{}
		redisInstance.pool = &redis.Pool{
			Dial: func() (redis.Conn, error) {
				c, err := redis.Dial("tcp", connStr)
				if err != nil {
					return nil, err
				}
				if _, err := c.Do("AUTH", auth); err != nil {
					c.Close()
					return nil, err
				}
				if _, err := c.Do("SELECT", db); err != nil {
					c.Close()
					return nil, err
				}
				return c, nil
			},
			MaxIdle:     8,
			MaxActive:   64,
			IdleTimeout: time.Second * 5,
		}
	})
}

func Redis() *htRedis {
	return redisInstance
}

func (htr *htRedis) Do(command string, args ...interface{}) (interface{}, error) {
	var conn = htr.pool.Get()
	defer conn.Close()

	return conn.Do(command, args...)
}

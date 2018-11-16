package cache

import (
	"github.com/gin-gonic/contrib/cache"
	"time"


	"github.com/labstack/echo"

	. "github.com/hb-go/echo-web/conf"
)

const (
	DefaultExpiration = 3600
	DEFAULT           = time.Duration(0)
	FOREVER           = time.Duration(-1)
	DefaultKey        = "github.com/tx991020/geek/cache"
)


//Cache middleware + Cache page
func Cache() echo.MiddlewareFunc {
	var store cache.CacheStore

	switch Conf.CacheStore {
	case MEMCACHED:
		store = cache.NewMemcachedStore([]string{Conf.Memcached.Server}, time.Hour)
	case REDIS:
		store = cache.NewRedisCache(Conf.Redis.Server, Conf.Redis.Pwd, DefaultExpiration)
	default:
		store = cache.NewInMemoryStore(time.Hour)
	}

	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			c.Set(DefaultKey, store)

			return next(c)
		}
	}
}

// shortcut to get Cache
func Default(c echo.Context) cache.CacheStore {
	// return c.MustGet(DefaultKey).(ec.CacheStore)
	return c.Get(DefaultKey).(cache.CacheStore)
}

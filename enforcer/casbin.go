package enforcer

import (
	"github.com/casbin/casbin"
	"github.com/casbin/gorm-adapter"
)

func NewCasbinEnforcer(connStr string) *casbin.Enforcer {
	Adapter := gormadapter.NewAdapter("mysql", connStr, true)
	enforcer := casbin.NewEnforcer(casbin.NewModel(CasbinConf), Adapter)
	return enforcer
}

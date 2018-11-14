package {package}

import (
	"log"
	"github.com/tx991020/utils/logs"
	_ "github.com/go-sql-driver/mysql"
	"github.com/jinzhu/gorm"
)

var db *gorm.DB

func DatabaseInit(connStr string, maxOpen, maxIdle int, debugMode bool) {
	var err error
	db, err = gorm.Open("mysql", connStr)
	if err != nil {
		logs.Critical("connect to mysql fails: %s", err.Error())
		panic("database error")
	}

	if debugMode {
		db.LogMode(true)
		db.SetLogger(log.New(logs.GetBeeLogger(), "[GORM] ", 0))
	}

	db.SingularTable(true)
	db.DB().SetMaxOpenConns(maxOpen)
	db.DB().SetMaxIdleConns(maxIdle)
}

func DB(t string) *gorm.DB {
	return db

}

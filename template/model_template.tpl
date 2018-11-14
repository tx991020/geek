package {package}

import (
    "github.com/tx991020/utils"
	"github.com/tx991020/utils/logs"
	"github.com/jinzhu/gorm"
	"time"
)

{model}

const {Table}Table = "{snake}"

func Create{Table}(e *{Table}) *{Table} {
	return DBCreate{Table}(DB({Table}Table), e)
}

func DBCreate{Table}(db *gorm.DB, e *{Table}) *{Table} {
	err := db.Create(e).Error
	if err != nil {
		logs.Error("create {table} [%v] fails: %s", e, err.Error())
		return nil
	}
	return e
}

func Get{Table}(id int64) *{Table} {
	return DBGet{Table}(DB({Table}Table), id)
}

func DBGet{Table}(db *gorm.DB, id int64) *{Table} {
	e := &{Table}{}
	if err := db.Where("id = ?", id).First(e).Error; err != nil {
		logs.Error("get {table} [%d] fails: %s", id, err.Error())
		return nil
	}
	return e
}

func Get{Table}s(m map[string]interface{}) []*{Table} {
	return DBGet{Table}s(DB({Table}Table), m)
}

func DBGet{Table}s(db *gorm.DB, m map[string]interface{}) []*{Table} {
	result := []*{Table}{}
	if err := db.Where(m).Find(&result).Error; err != nil {
		logs.Error("get {table} with filter [%v] fails: %s", m, err.Error())
		return nil
	}
	return result
}

func Get{Table}sByIds(ids []int64) []*{Table} {
	return DBGet{Table}sByIds(DB({Table}Table), ids)
}

func DBGet{Table}sByIds(db *gorm.DB, ids []int64) []*{Table} {
	result := []*{Table}{}
	if err := db.Where("id in (?)", ids).Order("id asc").Find(&result).Error; err != nil {
		logs.Error("get {table} with ids %v fails: %s", ids, err.Error())
		return nil
	}
	return result
}

func Update{Table}(id int64, m map[string]interface{}) (*{Table}, int64, bool, error) {
	return DBUpdate{Table}(DB({Table}Table), id, m)
}

func DBUpdate{Table}(db *gorm.DB, id int64, m map[string]interface{}) (*{Table}, int64, bool, error) {
	delete(m, "id")
	delete(m, "ctime")
	delete(m, "utime")

	aff := db.Model(&{Table}{}).Where("id = ?", id).UpdateColumns(m).RowsAffected
	e := &{Table}{}
	if err := db.Where("id = ?", id).First(e).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, aff, false, nil
		} else {
			logs.Error("%v", err)
			return nil, aff, false, err
		}
	}
	return e, aff, true, nil
}

func Delete{Table}(id int64)  {
	 DBDelete{Table}(DB({Table}Table), id)
}

func DBDelete{Table}(db *gorm.DB, id int64){
	if err := db.Where("id = ?", id).Delete({Table}{}).Error; err != nil {
		logs.Error("delete {table} [%d] fails: %s", id, err.Error())

	}

}

func Get{Table}sByTime(start time.Time, end time.Time, m map[string]interface{}, rawq string, limit int, getCount bool) ([]*{Table}, int) {
	return DBGet{Table}sByTime(DB({Table}Table), start, end, m, rawq, limit, getCount)
}

func DBGet{Table}sByTime(db *gorm.DB, start time.Time, end time.Time, m map[string]interface{}, rawq string, limit int, getCount bool) ([]*{Table}, int) {
	totalCount := 0
	result := make([]*{Table}, 0)
	db = db.Model({Table}{})
	if m != nil {
		db = db.Where(m)
	}
	if len(rawq) > 0 {
		db = db.Where(rawq)
	}
	db = db.Where("ctime > ?", start)
	if end.After(start) {
		db = db.Where("ctime < ?", end)
	}
	if getCount {
		db.Count(&totalCount)
	}
	if err := db.Order("ctime asc").Limit(limit).Find(&result).Error; err != nil {
		logs.Error("get {table} by time fails: %s", err.Error())
		return nil, 0
	}
	return result, totalCount
}

func Get{Table}sById(id int64, m map[string]interface{}, rawq string, dir int, order int, ordcond string, limit int, getCount bool) ([]*{Table}, int) {
	return DBGet{Table}sById(DB({Table}Table), id, m, rawq, dir, order, ordcond, limit, getCount)
}

func DBGet{Table}sById(db *gorm.DB, id int64, m map[string]interface{}, rawq string, dir int, order int, ordcond string, limit int, getCount bool) ([]*{Table}, int) {
	totalCount := 0
	result := make([]*{Table}, 0)
	db = db.Model({Table}{})
	if m != nil {
		db = db.Where(m)
	}
	if len(rawq) > 0 {
		db = db.Where(rawq)
	}
	if id == 0 {
	} else if dir > 0 {
		db = db.Where("id > ?", id)
	} else {
		db = db.Where("id < ?", id)
	}
	if order > 0 {
		db = db.Order("id asc")
	} else if order < 0 {
		db = db.Order("id desc")
	} else if len(ordcond) > 0 {
		db = db.Order(ordcond)
	}
	if getCount {
		db.Count(&totalCount)
	}
	if err := db.Limit(limit).Find(&result).Error; err != nil {
		logs.Error("get {table} by id fails: %s", err.Error())
		return nil, 0
	}
	return result, totalCount
}

func Get{Table}sByOffset(offset int, m map[string]interface{}, rawq string, order int, ordcond string, limit int, getCount bool) ([]*{Table}, int) {
	return DBGet{Table}sByOffset(DB({Table}Table), offset, m, rawq, order, ordcond, limit, getCount)
}

func DBGet{Table}sByOffset(db *gorm.DB, offset int, m map[string]interface{}, rawq string, order int, ordcond string, limit int, getCount bool) ([]*{Table}, int) {
	totalCount := 0
	result := make([]*{Table}, 0)
	db = db.Model({Table}{})
	if m != nil {
	db = db.Where(m)
	}
	if len(rawq) > 0 {
		db = db.Where(rawq)
	}
	if order > 0 {
		db = db.Order("id asc")
	} else if order < 0 {
		db = db.Order("id desc")
	} else if len(ordcond) > 0 {
		db = db.Order(ordcond)
	}
	if getCount {
		db.Count(&totalCount)
	}
	if limit > 0 {
		db = db.Limit(limit)
	}
	if err := db.Offset(offset).Find(&result).Error; err != nil {
		logs.Error("get {table} by offset fails: %s", err.Error)
		return nil, 0
	}
	return result, totalCount
}

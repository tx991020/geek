package {package}

import (
    "{AppName}/cache"
     "{AppName}/dao"

)

type {Table}WithDetail struct {
	*dao.{Table}
}

func Get{Table}WithDetail(id int64) *{Table}WithDetail {
	item := cache.Get{Table}(id)
	if item == nil {
		return &{Table}WithDetail{}
	}
	detail := &{Table}WithDetail{
		{Table}: item,
	}
	return detail
}

func Fetch{Table}ByFilter(filter map[string]interface{}, current, pagesize int64) ([]*{Table}WithDetail, int) {
	items, cnt := cache.Get{Table}sByOffset(
		int(uint(current-1))*int(pagesize),
		filter,
		"",
		0,
		"",
		int(pagesize),
	)
	ret := make([]*{Table}WithDetail, 0)
	if items != nil && len(items) > 0 {
		for _, item := range items {
			ret = append(ret, Get{Table}WithDetail(item.Id))
		}
	}
	return ret, cnt
}

func InvalidCache{Table}ByFilter() {
	cache.Invalid{Table}sByOffset(
		0,
		map[string]interface{}{},
		"", // query
		-1, // order
		"", // order cond
		10,
	)
}

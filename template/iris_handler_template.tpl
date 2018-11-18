package {package}

import (
	"reflect"

	"encoding/json"
	"github.com/kataras/iris"
	"github.com/tx991020/utils/restful"
	"github.com/tx991020/utils"
	"{AppName}/dao"
	"{AppName}/service"
	"{AppName}/cache"
	"{AppName}/e"
)

func {Table}Init(r iris.Party) {
	rt := r.Party(`/{table}s`)
	rt.Post(
		``,
		restful.GRequestBodyObject(reflect.TypeOf(dao.{Table}{})),
		Create{Table},
	)

	rt.Put(
		`/:{table}Id`,
		restful.GPathRequireInt("{table}Id"),
		restful.GRequestBodyMap,
		Update{Table},
	)
	rt.Get(
		`/:{table}Id`,
		restful.GPathRequireInt("{table}Id"),
		Get{Table},
	)

	r.Get(
		`/{table}sByFilter`,
		restful.GQueryOptionalStringDefault("filter", "{}"),
		restful.GQueryOptionalIntDefault("current", 1),
		restful.GQueryOptionalIntDefault("pageSize", 10),
		Get{Table}ByFilter,
	)
	rt.Delete(
		`/:{table}Id`,
		restful.GPathRequireInt("{table}Id"),
		Delete{Table},
	)


}
// @{Table}  json
// @Param {table} body dao.{Table} true "Create {Table}"
// @Success 200 {object} dao.{Table}
// @Router /{AppName}/v1/{table}s [post]
func Create{Table}(c iris.Context) {
	u := c.Values().Get("requestBody").(*dao.{Table})
	item := cache.Create{Table}(u)

	service.InvalidCache{Table}ByFilter()

	c.JSON(iris.Map{"Code": e.SUCCESS, "Msg":"","Data":item})


}
// @{Table}  json
// @Param	id			path 	int	true		"The id you want to update"
// @Param	body		body 	dao.{Table}	true		"content"
// @Success 200 {object} dao.{Table}
// @router /{AppName}/v1/{{table}s/{id} [put]
func Update{Table}(c iris.Context) {
	m := c.Values().Get("requestBody").(map[string]interface{})
	delete(m, "id")
	r, _, _, err := cache.Update{Table}(c.Values().Get("{table}Id").(int64), utils.MCamelToSnake(m))
	if err !=nil{

    		c.JSON(iris.Map{"Code": e.ERROR_DATABASE, "Msg":err.Error(),"Data":nil})
    		return
    	}

    	c.JSON(iris.Map{"Code": e.SUCCESS, "Msg":"","Data":r})

}
// @{Table}  json
// @Param	id		path 	int	true		"id"
// @Success 200 {object} dao.{Table}
// @router /{AppName}/v1/{table}s/{id} [get]
func Get{Table}(c iris.Context) {
	r := cache.Get{Table}(c.Values().Get("{table}Id").(int64))

	c.JSON(iris.Map{"Code": e.SUCCESS, "Msg":"","Data":r})

}

// @{Table}  json
// @Param	id		path 	int	true		"id"
// @Success 200 {object} dao.{Table}
// @router /{AppName}/v1/{table}s/{id} [get]
func Delete{Table}(c iris.Context) {
	cache.Delete{Table}(c.Values().Get("{table}Id").(int64))
	service.InvalidCache{Table}ByFilter()

	c.JSON(iris.Map{"Code": e.SUCCESS, "Msg":"","Data":nil})
}

// @{Table}  json
// @Param  filter  query string true "{}"
// @Param  pageSize  query int false "PageSize"
// @Param  current query   int false "Current"
// @Success 200 {object} dao.{Table}
// @Router /{AppName}/v1/{table}ByFilter [get]
func Get{Table}ByFilter(c iris.Context) {
	current,_:= c.Values().GetInt64("current")
    pagesize,_:=  c.Values().GetInt64("pageSize")
    jsonstring:= c.Values().GetString("filter")
    filter := make(map[string]interface{})
    err := json.Unmarshal([]byte(jsonstring), &filter)
    if err != nil {

        c.JSON(iris.Map{"Code": e.INVALID_PARAMS, "Msg":err.Error(),"Data":nil})
        return
    }

    rels, cnt := service.Fetch{Table}ByFilter(utils.MCamelToSnake(filter), current, pagesize)

    c.Header("X-total-count", utils.Itoa(int64(cnt)))

    c.JSON(iris.Map{"Code": e.SUCCESS, "Msg":"","Data":rels})
}

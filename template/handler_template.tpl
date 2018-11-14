package {package}

import (
	"reflect"
	"net/http"
	"encoding/json"
	"github.com/gin-gonic/gin"
	"github.com/tx991020/utils"
	"{AppName}/dao"
	"{AppName}/service"
	"{AppName}/cache"
	"{AppName}/e"
)

func {Table}Init(r gin.IRouter) {
	rt := r.Group(`/{table}s`)
	rt.POST(
		``,
		utils.GRequestBodyObject(reflect.TypeOf(dao.{Table}{}), "json"),
		Create{Table},
	)

	rt.PUT(
		`/:{table}Id`,
		utils.GPathRequireInt("{table}Id"),
		utils.GRequestBodyMap,
		Update{Table},
	)
	rt.GET(
		`/:{table}Id`,
		utils.GPathRequireInt("{table}Id"),
		Get{Table},
	)

	r.GET(
		`/{table}sByFilter`,
		utils.GQueryOptionalStringDefault("filter", "{}"),
		utils.GQueryOptionalIntDefault("current", 1),
		utils.GQueryOptionalIntDefault("pageSize", 10),
		Get{Table}ByFilter,
	)
	rt.DELETE(
		`/:{table}Id`,
		utils.GPathRequireInt("{table}Id"),
		Delete{Table},
	)


}
// @{Table}  json
// @Param {table} body dao.{Table} true "Create {Table}"
// @Success 200 {object} dao.{Table}
// @Router /{AppName}/v1/{table}s [post]
func Create{Table}(c *gin.Context) {
	u := c.MustGet("requestBody").(*dao.{Table})
	item := cache.Create{Table}(u)

	service.InvalidCache{Table}ByFilter()

	c.JSON(http.StatusOK, &utils.Response{Code:e.SUCCESS,Msg:"",Data:item})
}
// @{Table}  json
// @Param	id			path 	int	true		"The id you want to update"
// @Param	body		body 	dao.{Table}	true		"content"
// @Success 200 {object} dao.{Table}
// @router /{AppName}/v1/{{table}s/{id} [put]
func Update{Table}(c *gin.Context) {
	m := c.MustGet("requestBody").(map[string]interface{})
	delete(m, "id")
	r, _, _, err := cache.Update{Table}(c.MustGet("{table}Id").(int64), utils.MCamelToSnake(m))
	if err !=nil{
    		c.JSON(http.StatusOK, &utils.Response{Code:e.ERROR_DATABASE,Msg:err.Error(),Data:nil})
    	}
    	c.JSON(http.StatusOK, &utils.Response{Code:e.SUCCESS,Msg:err.Error(),Data:r})

}
// @{Table}  json
// @Param	id		path 	int	true		"id"
// @Success 200 {object} dao.{Table}
// @router /{AppName}/v1/{table}s/{id} [get]
func Get{Table}(c *gin.Context) {
	r := cache.Get{Table}(c.MustGet("{table}Id").(int64))
	c.JSON(http.StatusOK, &utils.Response{Code:e.SUCCESS,Msg:"",Data:r})

}

// @{Table}  json
// @Param	id		path 	int	true		"id"
// @Success 200 {object} dao.{Table}
// @router /{AppName}/v1/{table}s/{id} [get]
func Delete{Table}(c *gin.Context) {
	cache.Delete{Table}(c.MustGet("{table}Id").(int64))
	service.InvalidCache{Table}ByFilter()
	c.JSON(http.StatusOK, &utils.Response{Code:e.SUCCESS,Msg:"",Data:nil})
}

// @{Table}  json
// @Param  filter  query string true "{}"
// @Param  pageSize  query int false "PageSize"
// @Param  current query   int false "Current"
// @Success 200 {object} dao.{Table}
// @Router /{AppName}/v1/{table}ByFilter [get]
func Get{Table}ByFilter(c *gin.Context) {
	current := c.MustGet("current").(int64)
    pagesize := c.MustGet("pageSize").(int64)

    jsonstring := c.MustGet("filter").(string)
    filter := make(map[string]interface{})
    err := json.Unmarshal([]byte(jsonstring), &filter)
    if err != nil {
        c.JSON(http.StatusOK, &utils.Response{Code:e.INVALID_PARAMS,Msg:err.Error(),Data:nil})
        return
    }

    rels, cnt := service.FetchGroupByFilter(utils.MCamelToSnake(filter), current, pagesize)

    c.Header("X-total-count", utils.Itoa(int64(cnt)))
    c.JSON(http.StatusOK, &utils.Response{Code:e.SUCCESS,Msg:"",Data:rels})
}

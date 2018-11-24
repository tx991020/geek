package main

import (
	"bytes"
	"database/sql"
	"errors"
	"fmt"
	"github.com/urfave/cli"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"sort"
	"strings"
	"unicode"

	_ "github.com/go-sql-driver/mysql"
)

var config Configuration

type Configuration struct {
	AppKind      string `json:"app_kind"`
	AppPath      string `json:"go_path"`
	TemplatePath string `json:"template_path"`
	DbAddress    string `json:"db_address"`
	DbName       string `json:"db_name"`
	AppName      string `json:"app_name"`
	// TagLabel produces tags commonly used to match db field names with Go struct members
	TagLabel string `json:"tag_label"`
}

type ColumnSchema struct {
	TableName              string
	ColumnName             string
	IsNullable             string
	DataType               string
	CharacterMaximumLength sql.NullInt64
	NumericPrecision       sql.NullInt64
	NumericScale           sql.NullInt64
	ColumnType             string
	ColumnKey              string
}

//生成目录
func initDirs() {

	os.MkdirAll(config.AppPath+config.AppName+"/", 0755)
	os.MkdirAll(config.AppPath+config.AppName+"/dao", 0755)
	os.MkdirAll(config.AppPath+config.AppName+"/cache", 0755)
	os.MkdirAll(config.AppPath+config.AppName+"/"+"handler", 0755)
	os.MkdirAll(config.AppPath+config.AppName+"/"+"service", 0755)
	os.MkdirAll(config.AppPath+config.AppName+"/"+"setup", 0755)
	os.MkdirAll(config.AppPath+config.AppName+"/"+"redis", 0755)
	os.MkdirAll(config.AppPath+config.AppName+"/"+"e", 0755)
}

func writeStructs(tables map[string][]*ColumnSchema) error {
	var cacheParam = ""
	var handlerParam = ""
	// To store the keys in slice in sorted order
	var keys []string
	for k := range tables {
		keys = append(keys, k)
	}
	//按表名排序
	sort.Strings(keys)
	fmt.Println(keys)
	for _, tableName := range keys {
		var columns = tables[tableName]
		//按表生成结构体
		generateModel(tableName, columns)
		//生成dao CRUD
		generateCacheCRUD(tableName)
		//生成Handler
		generateHandler(tableName)
		//生成Service
		generateService(tableName)

		ftn := formatName(tableName)
		ctn := getVarPrefix(ftn)
		cacheParam += "\n\"" + ctn + "\":" + ctn + "CacheInit,"
		handlerParam += "\n" + getDeclarePrefix(ftn) + "Init(r)"

	}
	//生成CaChe Init
	generateCacheInit(cacheParam)
	//生成Handler Init
	generateHandlerInit(handlerParam)

	return nil
}

//反射表结构
func getSchema(dbaddr, dbname string) map[string][]*ColumnSchema {
	conn, err := sql.Open("mysql", dbaddr+"/information_schema")
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()
	q := "SELECT TABLE_NAME, COLUMN_NAME, IS_NULLABLE, DATA_TYPE, " +
		"CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE, COLUMN_TYPE, " +
		"COLUMN_KEY FROM COLUMNS WHERE TABLE_SCHEMA = ? ORDER BY TABLE_NAME, ORDINAL_POSITION"
	rows, err := conn.Query(q, dbname)
	if err != nil {
		log.Fatal(err)
	}
	tables := make(map[string][]*ColumnSchema)
	for rows.Next() {
		cs := ColumnSchema{}
		err := rows.Scan(&cs.TableName, &cs.ColumnName, &cs.IsNullable, &cs.DataType,
			&cs.CharacterMaximumLength, &cs.NumericPrecision, &cs.NumericScale,
			&cs.ColumnType, &cs.ColumnKey)
		if err != nil {
			log.Fatal(err)
		}

		if _, ok := tables[cs.TableName]; !ok {
			tables[cs.TableName] = make([]*ColumnSchema, 0)
		}
		tables[cs.TableName] = append(tables[cs.TableName], &cs)
	}
	if err := rows.Err(); err != nil {
		log.Fatal(err)
	}
	return tables
}

func formatName(name string) string {
	parts := strings.Split(name, "_")
	newName := ""
	for _, p := range parts {
		if len(p) < 1 {
			continue
		}
		newName = newName + strings.Replace(p, string(p[0]), strings.ToUpper(string(p[0])), 1)
	}
	return newName
}

func getVarPrefix(tableName string) string {
	r := []rune(tableName)
	r[0] = unicode.ToLower(r[0])
	return string(r)
}

func getDeclarePrefix(tableName string) string {
	r1 := []rune(tableName)
	r1[0] = unicode.ToUpper(r1[0])
	return string(r1)
}

//生成cache Init 列表
func generateCacheInit(cacheParam string) {
	b, err := ioutil.ReadFile(config.TemplatePath + "/template/cache.tpl")
	if err != nil {
		fmt.Println(err)
	}

	b0 := strings.Replace(string(b), "{namelist}", cacheParam, -1)
	b1 := strings.Replace(string(b0), "{package}", "cache", -1)
	os.Mkdir(config.AppPath+config.AppName+"/cache/", os.FileMode(0755))
	ioutil.WriteFile(config.AppPath+config.AppName+"/cache/cache.go", []byte(b1), os.ModeAppend|os.FileMode(0664))
}

//生成handler Init 列表
func generateHandlerInit(handlerParam string) {
	var err error
	var b []byte
	if config.AppKind == "gin" {
		b, err = ioutil.ReadFile(config.TemplatePath + "/template/handlerInit.tpl")
		if err != nil {
			fmt.Println(err)
			return
		}

	} else {

		b, err = ioutil.ReadFile(config.TemplatePath + "/template/iris_handlerInit.tpl")
		if err != nil {
			fmt.Println(err)
			return
		}

	}

	b0 := strings.Replace(string(b), "{namelist}", handlerParam, -1)
	b1 := strings.Replace(string(b0), "{package}", "cache", -1)
	os.Mkdir(config.AppPath+config.AppName+"/cache/", os.FileMode(0755))
	ioutil.WriteFile(config.AppPath+config.AppName+"/"+"handler"+"/handler.go", []byte(b1), os.ModeAppend|os.FileMode(0664))
}

//生成cache CRUD
func generateCacheCRUD(tableName string) {
	b, err := ioutil.ReadFile(config.TemplatePath + "/template/cache_template.tpl")
	if err != nil {
		fmt.Println(err)
	}

	ftn := formatName(tableName)
	ctn := getVarPrefix(ftn)

	b0 := strings.Replace(string(b), "{package}", "cache", -1)
	b1 := strings.Replace(b0, "{table}", ctn, -1)
	b2 := strings.Replace(b1, "{Table}", ftn, -1)
	b3 := strings.Replace(b2, "{AppName}", config.AppName, -1)
	os.Mkdir(config.AppPath+config.AppName+"/cache/", os.FileMode(0755))
	ioutil.WriteFile(config.AppPath+config.AppName+"/cache/"+tableName+".go", []byte(b3), os.ModeAppend|os.FileMode(0664))
}

//生成handler
func generateHandler(tableName string) {
	var err error
	var b []byte
	if config.AppKind == "gin" {
		b, err = ioutil.ReadFile(config.TemplatePath + "/template/handler_template.tpl")
		if err != nil {
			fmt.Println(err)
			return
		}

	} else {

		b, err = ioutil.ReadFile(config.TemplatePath + "/template/iris_handler_template.tpl")
		if err != nil {
			fmt.Println(err)
			return
		}

	}

	ftn := formatName(tableName)
	ctn := getVarPrefix(ftn)

	b0 := strings.Replace(string(b), "{package}", "handler", -1)
	b1 := strings.Replace(b0, "{table}", ctn, -1)
	b2 := strings.Replace(b1, "{Table}", ftn, -1)
	b3 := strings.Replace(b2, "{AppName}", config.AppName, -1)
	os.Mkdir(config.AppPath+config.AppName+"/"+"handler/", os.FileMode(0755))
	ioutil.WriteFile(config.AppPath+config.AppName+"/"+"handler"+"/"+tableName+".go", []byte(b3), os.ModeAppend|os.FileMode(0664))
}

//生成service
func generateService(tableName string) {
	b, err := ioutil.ReadFile(config.TemplatePath + "/template/service_template.tpl")
	if err != nil {
		fmt.Println(err)
	}

	ftn := formatName(tableName)
	ctn := getVarPrefix(ftn)

	b0 := strings.Replace(string(b), "{package}", "service", -1)
	b1 := strings.Replace(b0, "{table}", ctn, -1)
	b2 := strings.Replace(b1, "{Table}", ftn, -1)
	b3 := strings.Replace(b2, "{AppName}", config.AppName, -1)
	os.Mkdir(config.AppPath+config.AppName+"/"+"service/", os.FileMode(0755))
	ioutil.WriteFile(config.AppPath+config.AppName+"/"+"service"+"/"+tableName+".go", []byte(b3), os.ModeAppend|os.FileMode(0664))
}

//生成database
func generateDatabase() {

	b, err := ioutil.ReadFile(config.TemplatePath + "/template/database.tpl")
	if err != nil {
		log.Fatal(err)
	}
	b0 := strings.Replace(string(b), "{package}", "dao", -1)
	ioutil.WriteFile(config.AppPath+config.AppName+"/dao/database.go", []byte(b0), os.FileMode(0644))
}

//生成redis
func generateRedis() {
	//path := strings.ToLower(config.RedisPkgName)
	b, err := ioutil.ReadFile(config.TemplatePath + "/template/redis.tpl")
	if err != nil {
		log.Fatal(err)
	}
	b0 := strings.Replace(string(b), "{package}", "redis", -1)
	ioutil.WriteFile(config.AppPath+config.AppName+"/redis/redis.go", []byte(b0), os.FileMode(0644))
}

//生成setup
func generateSetUp() {
	var err error
	var b []byte
	if config.AppKind == "gin" {
		b, err = ioutil.ReadFile(config.TemplatePath + "/template/setup.tpl")
		if err != nil {
			fmt.Println(err)
			return
		}

	} else {

		b, err = ioutil.ReadFile(config.TemplatePath + "/template/iris_setup.tpl")
		if err != nil {
			fmt.Println(err)
			return
		}

	}

	b0 := strings.Replace(string(b), "{package}", "setup", -1)
	b1 := strings.Replace(string(b0), "{AppName}", config.AppName, -1)
	ioutil.WriteFile(config.AppPath+config.AppName+"/setup/setup.go", []byte(b1), os.FileMode(0644))
}

//生成errcode
func generateErrorCode() {

	b, err := ioutil.ReadFile(config.TemplatePath + "/template/e.tpl")
	if err != nil {
		log.Fatal(err)
	}
	ioutil.WriteFile(config.AppPath+config.AppName+"/e/e.go", []byte(b), os.FileMode(0644))
}

//生成config.toml
func generateConfigExample() {

	b, err := ioutil.ReadFile(config.TemplatePath + "/template/config.tpl")
	if err != nil {
		log.Fatal(err)
	}
	ioutil.WriteFile(config.AppPath+config.AppName+"/config.toml", []byte(b), os.FileMode(0644))
}

//生成main
func generateMain() {

	b, err := ioutil.ReadFile(config.TemplatePath + "/template/main.tpl")
	if err != nil {
		log.Fatal(err)
	}
	b1 := strings.Replace(string(b), "{package}", "main", -1)
	b2 := strings.Replace(string(b1), "{AppName}", config.AppName, -1)
	ioutil.WriteFile(config.AppPath+config.AppName+"/main.go", []byte(b2), os.FileMode(0644))
}

//生成 dao.Model
func generateModel(tableName string, columns []*ColumnSchema) {
	var out bytes.Buffer
	// generate model
	ftn := formatName(tableName)
	ctn := getVarPrefix(ftn)

	out.WriteString("type ")
	out.WriteString(ftn)
	out.WriteString(" struct{\n")

	for _, column := range columns {

		//下划线转驼峰
		fcn := formatName(column.ColumnName)
		ccn := getVarPrefix(fcn)

		goType, _, err := goType(column)

		if err != nil {
			log.Fatal(err)
		}
		out.WriteString("\t")
		out.WriteString(fcn)
		out.WriteString(" ")
		out.WriteString(goType)
		if len(config.TagLabel) > 0 || goType == "*utils.JSONTime" {
			out.WriteString("\t`")
		}
		if len(config.TagLabel) > 0 {
			if goType == "*utils.JSONTime" {
				out.WriteString(config.TagLabel)
				out.WriteString(":\"-\" ")
			} else {
				out.WriteString(config.TagLabel)
				out.WriteString(":\"")
				out.WriteString(ccn)
				out.WriteString("\"")
			}
		}
		if goType == "*utils.JSONTime" {
			out.WriteString("sql:\"-\"")
		}
		out.WriteString("`\n")
	}

	out.WriteString("}")

	b, err := ioutil.ReadFile(config.TemplatePath + "/template/model_template.tpl")
	if err != nil {
		fmt.Println(err)
	}
	bb := strings.Replace(string(b), "{model}", out.String(), -1)

	b0 := strings.Replace(bb, "{package}", "dao", -1)
	b1 := strings.Replace(b0, "{table}", ctn, -1)
	b2 := strings.Replace(b1, "{Table}", ftn, -1)
	b3 := strings.Replace(b2, "{snake}", tableName, -1)
	os.Mkdir(config.AppPath+config.AppName+"/dao/", os.FileMode(0755))
	ioutil.WriteFile(config.AppPath+config.AppName+"/dao/"+tableName+".go", []byte(b3), os.ModeAppend|os.FileMode(0664))
}

//数据库字段类型转go类型
func goType(col *ColumnSchema) (string, string, error) {
	requiredImport := ""
	//   if col.IsNullable == "YES" {
	//     requiredImport = "db/sql"
	//   }
	var gt string = ""
	switch col.DataType {
	case "char", "varchar", "enum", "text", "longtext", "mediumtext", "tinytext":
		//     if col.IsNullable == "YES" {
		//       gt = "sql.NullString"
		//     } else {
		gt = "string"
		//     }
	case "blob", "mediumblob", "longblob", "varbinary", "binary":
		gt = "[]byte"
	case "date", "time", "datetime", "timestamp":
		//     gt, requiredImport = "time.Time", "time"
		gt, requiredImport = "*utils.JSONTime", "github.com/tx991020/utils"
	case "smallint", "int", "mediumint", "bigint":
		//     if col.IsNullable == "YES" {
		//       gt = "sql.NullInt64"
		//     } else {
		gt = "int64"
		//     }
	case "float", "decimal", "double":
		//     if col.IsNullable == "YES" {
		//       gt = "sql.NullFloat64"
		//     } else {
		gt = "float64"
		//     }
	case "tinyint":
		gt = "bool"
	}
	if gt == "" {
		n := col.TableName + "." + col.ColumnName
		return "", "", errors.New("No compatible datatype (" + col.DataType + ") for " + n + " found")
	}
	return gt, requiredImport, nil
}

func Create(c *cli.Context) error {
	fmt.Println(111, c.Args())
	if c.NArg() != 4 {
		err := errors.New(`参数格式不对,例如 gin new go-api "root:123456@tcp(127.0.0.1:3306)" dbname `)
		log.Fatal(err)
		return err
	}
	AppKind := c.Args()[0]
	fmt.Println(1111111, AppKind == "iris")
	AppName := c.Args()[1]
	DbAddress := c.Args()[2]
	DbName := c.Args()[3]
	fmt.Println(AppName, DbAddress, DbName)
	var cmd *exec.Cmd

	//获取本机goenv
	cmd = exec.Command("/bin/sh", "-c", `go env | grep GOPATH | awk -F    '"' '{print $2}'`)
	path, err := cmd.Output()
	if err != nil {
		err := errors.New("未找到 GOPATH , 请确定已设置GOPATH")
		log.Fatal(err)
		return err
	}
	AppPath := strings.TrimSpace(string(path)) + "/src/"
	TemplatePath := strings.TrimSpace(string(path)) + "/src/github.com/tx991020/geek/"
	config = Configuration{AppKind, AppPath, TemplatePath, DbAddress, DbName, AppName, "json"}

	tables := getSchema(config.DbAddress, config.DbName)

	//生成目录
	initDirs()
	//生成databse配置
	generateDatabase()
	//生成databse配置
	generateRedis()
	generateSetUp()
	generateErrorCode()
	generateConfigExample()
	generateMain()
	//结构体
	err1 := writeStructs(tables)
	if err1 != nil {
		log.Fatal(err1)
		return errors.New(err1.Error())
	}

	//cmd = exec.Command( "/bin/sh", "-c","swag init")
	//out, err2 := cmd.Output()
	//if err2 != nil {
	//	fmt.Println(err2.Error())
	//
	//	return err2
	//}
	//fmt.Println(strings.TrimSpace(string(out)))
	fmt.Println("Greate ! Success!")
	return nil

}

//适用于新增单表 dao,service,handler, table_name 要用数据库里表名 大小写完全一致
func GenerateSingleTable(table_name string) error {

	tables := getSchema(config.DbAddress, config.DbName)
	fmt.Println(tables)

	columns := tables[table_name]
	//按表生成结构体
	generateModel(table_name, columns)
	//生成dao CRUD
	generateCacheCRUD(table_name)
	//生成Handler
	generateHandler(table_name)
	//生成Service
	generateService(table_name)

	return nil

}
func GetPath(c *cli.Context) error {
	path, _ := os.Getwd()
	fmt.Println(path)
	return nil
}

//生成整个项目
func CLI() {
	app := cli.NewApp()
	app.Name = "is a Fast and Flexible tool for managing your gin restful API Application"
	app.Version = "1.0"

	var createCommand = cli.Command{
		Name:      "new",
		Usage:     `geek new iris go-api "root:123456@tcp(127.0.0.1:3306)" dbname`,
		ArgsUsage: "generate a gin/iris api application 第一个参数:项目Kind:iris或gin(default gin),第二个参数:项目名 第三个参数: 数据库连接 第四个参数 数据库名",

		Action: Create,
	}
	var getEnvCommand = cli.Command{
		Name:      "path",
		Usage:     `get local path`,
		ArgsUsage: "获取当前路径",

		Action: GetPath,
	}
	app.Commands = []cli.Command{
		createCommand,
		getEnvCommand,
	}
	err := app.Run(os.Args)
	if err != nil {
		log.Fatal(err)
	}
}
func main() {

	//dbUser := flag.String("dbuser", "root", "db user name")
	//dbPassword := flag.String("dbpassword", "password", "password for user name")
	//dbAddress := flag.String("dbaddress", "127.0.0.1:3306", "db address")
	//dbName := flag.String("dbname", "dbname", "db name")
	//daoPkgPath := flag.String("daopkgpath", "dao package path", "dao package path")
	//daoPkgName := flag.String("daopkgname", "dao package name", "dao package name")
	//cachePkgName := flag.String("cachepkgname", "cache package name", "cache package name")
	//tagLabel := flag.String("taglabel", "json", "json or xml")
	//flag.Parse()
	//
	//config.DbUser = *dbUser
	//config.DbPassword = *dbPassword
	//config.DbAddress = *dbAddress
	//config.DbName = *dbName
	//config.DaoPkgPath = *daoPkgPath
	//config.DaoPkgName = *daoPkgName
	//config.CachePkgName = *cachePkgName
	//config.TagLabel = *tagLabel
	config = Configuration{"iris", "/Users/andy/GoLang/src/", "/Users/andy/GoLang/src/github.com/tx991020/geek/", "root:123456@tcp(127.0.0.1:3306)", "api", "seed7", "json"}
	GenerateSingleTable("task")

}

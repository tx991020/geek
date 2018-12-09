package handler

import (
	"fmt"
	"github.com/tx991020/utils"

	"github.com/kataras/iris"
	"runtime"

	"time"
)





func DashboardInit(r iris.Party) {
	rt := r.Party(`/dashboard`)
	rt.Get(
		``,

		GetDashBoard,
	)

}


var (
	startTime = time.Now()
)

var sysStatus struct {
	Uptime       string
	NumGoroutine string

	// General statistics.
	MemAllocated string // bytes allocated and still in use
	MemTotal     string // bytes allocated (even if freed)
	MemSys       string // bytes obtained from system (sum of XxxSys below)
	Lookups      string // number of pointer lookups
	MemMallocs   string // number of mallocs
	MemFrees     string // number of frees

	// Main allocation heap statistics.
	HeapAlloc    string // bytes allocated and still in use
	HeapSys      string // bytes obtained from system
	HeapIdle     string // bytes in idle spans
	HeapInuse    string // bytes in non-idle span
	HeapReleased string // bytes released to the OS
	HeapObjects  string // total number of allocated objects

	// Low-level fixed-size structure allocator statistics.
	//	Inuse is bytes used now.
	//	Sys is bytes obtained from system.
	StackInuse  string // bootstrap stacks
	StackSys    string
	MSpanInuse  string // mspan structures
	MSpanSys    string
	MCacheInuse string // mcache structures
	MCacheSys   string
	BuckHashSys string // profiling bucket hash table
	GCSys       string // GC metadata
	OtherSys    string // other system allocations

	// Garbage collector statistics.
	NextGC       string // next run in HeapAlloc time (bytes)
	LastGC       string // last run in absolute time (ns)
	PauseTotalNs string
	PauseNs      string // circular buffer of recent GC pause times, most recent at [(NumGC+255)%256]
	NumGC        string
}

func updateSystemStatus() {
	sysStatus.Uptime = fmt.Sprintf("服务运行时间:%s",utils.TimeSincePro(startTime))

	m := new(runtime.MemStats)
	runtime.ReadMemStats(m)
	sysStatus.NumGoroutine = fmt.Sprintf("当前 Goroutines 数量:%d",runtime.NumGoroutine())

	sysStatus.MemAllocated = fmt.Sprintf("当前内存使用量:%s",utils.FileSize(int64(m.Alloc)))
	sysStatus.MemTotal = fmt.Sprintf("所有被分配的内存:%s",utils.FileSize(int64(m.TotalAlloc)))
	sysStatus.MemSys = fmt.Sprintf("内存占用量:%s",utils.FileSize(int64(m.Sys)))
	sysStatus.Lookups = fmt.Sprintf("指针查找次数:%d",m.Lookups)
	sysStatus.MemMallocs = fmt.Sprintf("内存分配次数:%d",m.Mallocs)
	sysStatus.MemFrees = fmt.Sprintf("内存释放次数:%d",m.Frees)

	sysStatus.HeapAlloc = fmt.Sprintf("当前 Heap 内存使用量:%s",utils.FileSize(int64(m.HeapAlloc)))
	sysStatus.HeapSys = fmt.Sprintf("Heap 内存占用量:%s",utils.FileSize(int64(m.HeapSys)))
	sysStatus.HeapIdle = fmt.Sprintf("Heap 内存空闲量:%s",utils.FileSize(int64(m.HeapIdle)))
	sysStatus.HeapInuse = fmt.Sprintf("正在使用的 Heap 内存:%s",utils.FileSize(int64(m.HeapInuse)))
	sysStatus.HeapReleased = fmt.Sprintf("被释放的 Heap 内存:%s",utils.FileSize(int64(m.HeapReleased)))
	sysStatus.HeapObjects = fmt.Sprintf("Heap 对象数量:%d",m.HeapObjects)

	sysStatus.StackInuse = fmt.Sprintf("启动 Stack 使用量:%s",utils.FileSize(int64(m.StackInuse)))
	sysStatus.StackSys = fmt.Sprintf("被分配的 Stack 内存:%s",utils.FileSize(int64(m.StackSys)))
	sysStatus.MSpanInuse = fmt.Sprintf("MSpan 结构内存使用量:%s",utils.FileSize(int64(m.MSpanInuse)))
	sysStatus.MSpanSys = fmt.Sprintf("被分配的 MSpan 结构内存:%s",utils.FileSize(int64(m.MSpanSys)))
	sysStatus.MCacheInuse = fmt.Sprintf("MCache 结构内存使用量:%s",utils.FileSize(int64(m.MCacheInuse)))
	sysStatus.MCacheSys = fmt.Sprintf("被分配的 MCache 结构内存:%s",utils.FileSize(int64(m.MCacheSys)))
	sysStatus.BuckHashSys = fmt.Sprintf("被分配的剖析哈希表内存:%s",utils.FileSize(int64(m.BuckHashSys)))
	sysStatus.GCSys = fmt.Sprintf("被分配的 GC 元数据内存:%s",utils.FileSize(int64(m.GCSys)))
	sysStatus.OtherSys = fmt.Sprintf("其它被分配的系统内存:%s",utils.FileSize(int64(m.OtherSys)))

	sysStatus.NextGC = fmt.Sprintf("下次 GC 内存回收量:%s",utils.FileSize(int64(m.NextGC)))
	sysStatus.LastGC = fmt.Sprintf("距离上次 GC 时间:%.3fs", float64(time.Now().UnixNano()-int64(m.LastGC))/1000/1000/1000)
	sysStatus.PauseTotalNs = fmt.Sprintf("GC 暂停时间总量:%.3fs", float64(m.PauseTotalNs)/1000/1000/1000)
	sysStatus.PauseNs = fmt.Sprintf("上次 GC 暂停时间:%.6fs", float64(m.PauseNs[(m.NumGC+255)%256])/1000/1000/1000)
	sysStatus.NumGC = fmt.Sprintf("GC 执行次数:%d",m.NumGC)
}

func GetDashBoard(c iris.Context)  {
	updateSystemStatus()
	c.JSON(iris.Map{"Code": e.SUCCESS, "Msg":"","Data":sysStatus})
}
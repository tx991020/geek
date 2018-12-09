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
	NumGoroutine int

	// General statistics.
	MemAllocated string // bytes allocated and still in use
	MemTotal     string // bytes allocated (even if freed)
	MemSys       string // bytes obtained from system (sum of XxxSys below)
	Lookups      uint64 // number of pointer lookups
	MemMallocs   uint64 // number of mallocs
	MemFrees     uint64 // number of frees

	// Main allocation heap statistics.
	HeapAlloc    string // bytes allocated and still in use
	HeapSys      string // bytes obtained from system
	HeapIdle     string // bytes in idle spans
	HeapInuse    string // bytes in non-idle span
	HeapReleased string // bytes released to the OS
	HeapObjects  uint64 // total number of allocated objects

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
	NumGC        uint32
}

func updateSystemStatus() {
	sysStatus.Uptime = utils.TimeSincePro(startTime)

	m := new(runtime.MemStats)
	runtime.ReadMemStats(m)
	sysStatus.NumGoroutine = runtime.NumGoroutine()

	sysStatus.MemAllocated = utils.FileSize(int64(m.Alloc))
	sysStatus.MemTotal = utils.FileSize(int64(m.TotalAlloc))
	sysStatus.MemSys = utils.FileSize(int64(m.Sys))
	sysStatus.Lookups = m.Lookups
	sysStatus.MemMallocs = m.Mallocs
	sysStatus.MemFrees = m.Frees

	sysStatus.HeapAlloc = utils.FileSize(int64(m.HeapAlloc))
	sysStatus.HeapSys = utils.FileSize(int64(m.HeapSys))
	sysStatus.HeapIdle = utils.FileSize(int64(m.HeapIdle))
	sysStatus.HeapInuse = utils.FileSize(int64(m.HeapInuse))
	sysStatus.HeapReleased = utils.FileSize(int64(m.HeapReleased))
	sysStatus.HeapObjects = m.HeapObjects

	sysStatus.StackInuse = utils.FileSize(int64(m.StackInuse))
	sysStatus.StackSys = utils.FileSize(int64(m.StackSys))
	sysStatus.MSpanInuse = utils.FileSize(int64(m.MSpanInuse))
	sysStatus.MSpanSys = utils.FileSize(int64(m.MSpanSys))
	sysStatus.MCacheInuse = utils.FileSize(int64(m.MCacheInuse))
	sysStatus.MCacheSys = utils.FileSize(int64(m.MCacheSys))
	sysStatus.BuckHashSys = utils.FileSize(int64(m.BuckHashSys))
	sysStatus.GCSys = utils.FileSize(int64(m.GCSys))
	sysStatus.OtherSys = utils.FileSize(int64(m.OtherSys))

	sysStatus.NextGC = utils.FileSize(int64(m.NextGC))
	sysStatus.LastGC = fmt.Sprintf("%.3fs", float64(time.Now().UnixNano()-int64(m.LastGC))/1000/1000/1000)
	sysStatus.PauseTotalNs = fmt.Sprintf("%.3fs", float64(m.PauseTotalNs)/1000/1000/1000)
	sysStatus.PauseNs = fmt.Sprintf("%.6fs", float64(m.PauseNs[(m.NumGC+255)%256])/1000/1000/1000)
	sysStatus.NumGC = m.NumGC
}

func GetDashBoard(c iris.Context)  {
	updateSystemStatus()
	c.JSON(iris.Map{"Code": e.SUCCESS, "Msg":"","Data":sysStatus})
}
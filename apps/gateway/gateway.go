package main

import (
	"flag"

	"github.com/wypwzc/go-mall/apps/gateway/internal/config"
	"github.com/wypwzc/go-mall/apps/gateway/internal/handler"
	"github.com/zeromicro/go-zero/core/conf"
	"github.com/zeromicro/go-zero/rest"
)

var configFile = flag.String("f", "etc/gateway.yaml", "the config file")

func main() {
	flag.Parse()

	var c config.Config
	conf.MustLoad(*configFile, &c)

	server := rest.MustNewServer(c.RestConf)
	defer server.Stop()

	handler.RegisterHandlers(server)
	server.Start()
}

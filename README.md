ggApp-ansible
=============
ggApp-ansible是[ggApp](https://github.com/sundream/ggApp)的ansible配置示例,可以利用[ansible](https://github.com/ansible/ansible)快速部署服务器

Table of Contents
================

* [名字](#ggApp-ansible)
* [已测试环境](#已测试环境)
* [安装ansible](#安装ansible)
* [部署ggApp](#部署)
* [管理ggApp](#管理)


已测试环境
=========
* Ubuntu-18.04.1
* Ubuntu-16.04.5
* Centos-7.5

安装ansible
===========
* [installation](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
* ubuntu
```
sudo apt install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
# 使用pip安装
pip install ansible
```
* centos
```
# 使用pip安装
pip install ansible
#pip install git+https://github.com/ansible/ansible.git@devel
```

[Back to TOC](#table-of-contents)

部署
====
```
# 暂时不支持macos下自动部署,ubuntu18.14.1/centos下测试通过
cd ~
git clone https://github.com/sundream/ggApp-ansible
cd ~/ggApp-ansible
# 免密登录
ssh-keygen
ssh-copy-id -i ~/.ssh/id_rsa.pub $USER@127.0.0.1
# 提前安装软件,防止一键部署出错
ansible-playbook -i hosts.machine --limit localhost install.yml -e home=$HOME -K
# 一键部署(默认部署的serverid为gamesrv_1,你也可以通过-e serverid=gamesrv_xxx来部署其他服务器)
ansible-playbook -i hosts deploy.yml -e home=$HOME -K
# 部署指定tag
# ansible-playbook -i hosts deploy.yml -e home=$HOME -K --tags TAG1,TAG2
```
部署完后会在本机生成如下目录
```
//ggApp工作目录
~/ggApp
	+accountcenter		//账号中心
	+gamesrv			//游戏服
	+client				//简易客户端
	+robot				//机器人压测工具
	+tools				//其他工具

//依赖软件源码目录
/usr/local/src
	+lua-5.3.5
	+openresty-1.13.6.2
	+luarocks-3.0.4
	+mongodb-linux-x86_64-4.0.5
	+redis-5.0.3

//依赖软件二进制包目录
/usr/local
	+openresty
	+bin
		+lua
		+luarocks
		+luarocks-5.3
		+mongodb
		+mongos
		+mongo
		+redis-server
		+redis-cli

//db工作目录
~/db
	+redis					//redis配置文件目录
	+mongodb				//mongo配置文件目录

# 可以执行以下指令检查安装软件的版本
redis-server -v
mongod --version
lua -v
openresty -v
luarocks --version
```

[Back to TOC](#table-of-contents)

管理
====
* 管理redis独立节点(账号中心用)
```
# 启动
ansible redis -i hosts -m shell -a "redis-server {{redis_workspace}}/{{inventory_hostname}}/redis.conf"
# 关闭
ansible redis -i hosts -m shell -a "redis-cli -p {{redis_port}} -a {{redis_password}} shutdown"
# 查看启动状态
ansible redis -i hosts -m shell -a "cat {{redis_workspace}}/{{inventory_hostname}}/redis.pid | xargs ps -cp"
```
* 管理rediscluster
```
# 启动
ansible rediscluster -i hosts -m shell -a "redis-server {{redis_workspace}}/{{inventory_hostname}}/redis.conf"
# 如果是首次启动,需要初始化redis集群,ip有变化可以修改127.0.0.1
redis-cli --cluster create 127.0.0.1:7001 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 127.0.0.1:7006 --cluster-replicas 1
# 关闭
ansible rediscluster -i hosts -m shell -a "redis-cli -p {{redis_port}} -a {{redis_password}} shutdown"
# 查看启动状态
ansible rediscluster -i hosts -m shell -a "cat {{redis_workspace}}/{{inventory_hostname}}/redis.pid | xargs ps -cp"
```
rediscluster正常启动后进程信息大致如[redis_process.txt](https://github.com/sundream/ggApp-ansible/blob/master/redis_process.txt)

* 管理mongodbcluster
```
# 启动configsvr(启动可能需要一段时间,最好等待>10s)
ansible configsvr -i hosts -m shell -a "mongod -f {{mongodb_workspace}}/{{inventory_hostname}}/mongodb.conf &"
# 启动shard(启动可能需要一段时间,最好等待>30s)
ansible shard -i hosts -m shell -a "mongod -f {{mongodb_workspace}}/{{inventory_hostname}}/mongodb.conf &"
# 启动router(启动可能需要一段时间,最好等待>10s)
ansible router -i hosts -m shell -a "mongos -f {{mongodb_workspace}}/{{inventory_hostname}}/mongodb.conf &"
# 如果是首次启动,需要初始化mongo集群
# 快速初始化集群
ansible router_1 -i hosts -m shell -a "sh ~/db/mongodb/js/initCluster.sh"
# 也可以分步初始化集群,如下:
	# 初始化configsvr副本集
	ansible configsvr_1 -i hosts -m shell -a "mongo --port {{mongodb_port}} {{mongodb_workspace}}/js/initReplSet_{{replSet}}.js"
	# 初始化shard副本集(可能要执行多次确保副本集初始化成功)
	ansible shard0001_1:shard0002_1:shard0003_1 -i hosts -m shell -a "mongo --port {{mongodb_port}} {{mongodb_workspace}}/js/initReplSet_{{replSet}}.js"
	# 向router添加shard
	ansible router_1 -i hosts -m shell -a "mongo --port {{mongodb_port}} {{mongodb_workspace}}/js/addShard.js"
	# 开启分片
	ansible router_1 -i hosts -m shell -a "mongo --port {{mongodb_port}} {{mongodb_workspace}}/js/enableSharding.js"
# 测试分片(执行需要一段时间,最好等待>=30s)
ansible router_1 -i hosts -m shell -a "mongo --port {{mongodb_port}} {{mongodb_workspace}}/js/testSharding.js"
# 关闭(关闭可能需要一段时间,最好等待>=30s)
ansible mongodbcluster -i hosts -m shell -a "cat {{mongodb_workspace}}/{{inventory_hostname}}/mongodb.pid | xargs kill -2"
# 查看启动状态
ansible mongodbcluster -i hosts -m shell -a "cat {{mongodb_workspace}}/{{inventory_hostname}}/mongodb.pid | xargs ps -cp"
```
mongodbcluster正常启动后进程信息大致如[mongodb_process.txt](https://github.com/sundream/ggApp-ansible/blob/master/mongodb_process.txt)

* 管理accountcenter
```
# 启动
ansible accountcenter -i hosts -m shell -a "cd ~/ggApp/accountcenter && /usr/local/openresty/bin/openresty -c conf/account.conf -p . &"
# 导入游戏服务器信息
ansible accountcenter -i hosts -m shell -a "cd ~/ggApp/tools/script && python import_servers.py --appid=appid --config=servers.config"
# 关闭
ansible accountcenter -i hosts -m shell -a "cd ~/ggApp/accountcenter && /usr/local/openresty/bin/openresty -c conf/account.conf -p . -s stop"
# 重新加载
ansible accountcenter -i hosts -m shell -a "cd ~/ggApp/accountcenter && /usr/local/openresty/bin/openresty -c conf/account.conf -p . -s reload"
```
* 管理gamesrv
```
# 启动
ansible gamesrv_1 -i hosts -m shell -a "cd ~/ggApp/gamesrv_1/shell && sh start.sh"
# 关闭
ansible gamesrv_1 -i hosts -m shell -a "cd ~/ggApp/gamesrv_1/shell && sh stop.sh"
# 重新启动
ansible gamesrv_1 -i hosts -m shell -a "cd ~/ggApp/gamesrv_1/shell && sh restart.sh"
# 强制关闭(非安全关闭)
ansible gamesrv_1 -i hosts -m shell -a "cd ~/ggApp/gamesrv_1/shell && sh kill.sh"
# 查看启动状态
ansible gamesrv_1 -i hosts -m shell -a "cd ~/ggApp/gamesrv_1/shell && sh status.sh"
# 执行gm
ansible gamesrv_1 -i hosts -m shell -a "cd ~/ggApp/gamesrv_1/shell && sh gm.sh 0 exec 'return 1+1'"
```

[Back to TOC](#table-of-contents)

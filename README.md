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
* [打包和发布](#打包和发布)


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
sudo apt install python
sudo apt install python-pip
pip install ansible
```
* centos
```
# 使用pip安装
sudo yum install -y python-pip
pip install ansible
#pip install git+https://github.com/ansible/ansible.git@devel
```

[Back to TOC](#table-of-contents)

部署
====
```
# 暂时不支持macos下自动部署,ubuntu18.14.1/centos下测试通过
# 免密登录
ssh-keygen   #一路按回车跳过
ssh-copy-id -i ~/.ssh/id_rsa.pub $USER@127.0.0.1  #中途需要输入用户密码
cd ~ && git clone https://github.com/sundream/ggApp-ansible
cd ~/ggApp-ansible
# 提前安装所有依赖软件/库
ansible-playbook -i hosts/gameserver.local --limit gameserver_1 install.yml -e home=$HOME -K
# 部署rediscluster
ansible-playbook -i hosts/redis.local deploy_rediscluster.yml -e home=$HOME -K
# 部署mongodbcluster
ansible-playbook -i hosts/mongodb.local deploy_mongodbcluster.yml -e home=$HOME -K
# 部署loginserver
ansible-playbook -i hosts/loginserver.local --limit loginserver deploy_loginserver.yml -e home=$HOME -K
# 部署gameserver
ansible-playbook -i hosts/gameserver.local --limit gameserver_1 deploy_gameserver.yml -e home=$HOME -K
```
部署完后会在本机生成如下目录
```
//ggApp工作目录
~/ggApp
	+loginserver		//登录服
	+gameserver			//游戏服
	+client				//简易客户端
	+robot				//机器人压测工具
	+tools				//其他工具

//依赖软件源码目录
/usr/local/src
	+lua-5.3.5
	+luarocks-3.0.4
	+mongodb-linux-x86_64-4.0.5
	+redis-5.0.3

//依赖软件二进制包目录
/usr/local
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
luarocks --version
```

[Back to TOC](#table-of-contents)

管理
====
* 管理redis独立节点(登录服用)
```
# 启动
ansible redis -i hosts/redis.local -m shell -a "redis-server {{redis_workspace}}/{{inventory_hostname}}/redis.conf"
# 关闭
ansible redis -i hosts/redis.local -m shell -a "redis-cli -p {{redis_port}} -a {{redis_password}} shutdown"
# 查看启动状态
ansible redis -i hosts/redis.local -m shell -a "cat {{redis_workspace}}/{{inventory_hostname}}/redis.pid | xargs ps -cp"
```
* 管理rediscluster
```
# 启动
ansible rediscluster -i hosts/redis.local -m shell -a "redis-server {{redis_workspace}}/{{inventory_hostname}}/redis.conf"
# 如果是首次启动,需要初始化redis集群,ip有变化可以修改127.0.0.1
redis-cli --cluster create 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 127.0.0.1:7006 --cluster-replicas 1
# 关闭
ansible rediscluster -i hosts/redis.local -m shell -a "redis-cli -p {{redis_port}} -a {{redis_password}} shutdown"
# 查看启动状态
ansible rediscluster -i hosts/redis.local -m shell -a "cat {{redis_workspace}}/{{inventory_hostname}}/redis.pid | xargs ps -cp"
```

* 管理mongodbcluster
```
# 启动configsvr(启动可能需要一段时间,最好等待>10s)
ansible configsvr -i hosts/mongodb.local -m shell -a "mongod -f {{mongodb_workspace}}/{{inventory_hostname}}/mongodb.conf &"
# 启动shard(启动可能需要一段时间,最好等待>30s)
ansible shard -i hosts/mongodb.local -m shell -a "mongod -f {{mongodb_workspace}}/{{inventory_hostname}}/mongodb.conf &"
# 启动router(启动可能需要一段时间,最好等待>10s)
ansible router -i hosts/mongodb.local -m shell -a "mongos -f {{mongodb_workspace}}/{{inventory_hostname}}/mongodb.conf &"
# 如果是首次启动,需要初始化mongo集群
# 快速初始化集群(可能需要尝试多次)
ansible router_1 -i hosts/mongodb.local -m shell -a "sh ~/db/mongodb/js/initCluster.sh"
# 也可以分步初始化集群,如下:
	# 初始化configsvr副本集
	ansible configsvr_1 -i hosts/mongodb.local -m shell -a "mongo --port {{mongodb_port}} {{mongodb_workspace}}/js/initReplSet_{{replSet}}.js"
	# 初始化shard副本集(可能要执行多次确保副本集初始化成功)
	ansible shard0001_1:shard0002_1:shard0003_1 -i hosts/mongodb.local -m shell -a "mongo --port {{mongodb_port}} {{mongodb_workspace}}/js/initReplSet_{{replSet}}.js"
	# 向router添加shard
	ansible router_1 -i hosts/mongodb.local -m shell -a "mongo --port {{mongodb_port}} {{mongodb_workspace}}/js/addShard.js"
	# 开启分片
	ansible router_1 -i hosts/mongodb.local -m shell -a "mongo --port {{mongodb_port}} {{mongodb_workspace}}/js/enableSharding.js"
# 测试分片(执行需要一段时间,最好等待>=30s)
ansible router_1 -i hosts/mongodb.local -m shell -a "mongo --port {{mongodb_port}} {{mongodb_workspace}}/js/testSharding.js"
# 关闭(关闭可能需要一段时间,最好等待>=30s)
ansible mongodbcluster -i hosts/mongodb.local -m shell -a "cat {{mongodb_workspace}}/{{inventory_hostname}}/mongodb.pid | xargs kill -2"
# 查看启动状态
ansible mongodbcluster -i hosts/mongodb.local -m shell -a "cat {{mongodb_workspace}}/{{inventory_hostname}}/mongodb.pid | xargs ps -cp"
```

* 管理loginserver
```
# 启动
ansible loginserver -i hosts/loginserver.local -m shell -a "cd {{ggApp_workspace}}/{{inventory_hostname}}/shell && sh start.sh"
# 关闭
ansible loginserver -i hosts/loginserver.local -m shell -a "cd {{ggApp_workspace}}/{{inventory_hostname}}/shell && sh stop.sh"
# 重新启动
ansible loginserver -i hosts/loginserver.local -m shell -a "cd {{ggApp_workspace}}/{{inventory_hostname}}/shell && sh restart.sh"
# 强制关闭(非安全关闭)
ansible loginserver -i hosts/loginserver.local -m shell -a "cd {{ggApp_workspace}}/{{inventory_hostname}}/shell && sh kill.sh"
# 查看启动状态
ansible loginserver -i hosts/loginserver.local -m shell -a "cd {{ggApp_workspace}}/{{inventory_hostname}}/shell && sh status.sh"
# 执行gm
ansible loginserver -i hosts/loginserver.local -m shell -a "cd {{ggApp_workspace}}/{{inventory_hostname}}/shell && sh gm.sh 0 exec 'return 1+1'"

```
* 管理gameserver
```
# 启动
ansible gameserver_1 -i hosts/gameserver.local -m shell -a "cd {{ggApp_workspace}}/{{inventory_hostname}}/shell && sh start.sh"
# 关闭
ansible gameserver_1 -i hosts/gameserver.local -m shell -a "cd {{ggApp_workspace}}/{{inventory_hostname}}/shell && sh stop.sh"
# 重新启动
ansible gameserver_1 -i hosts/gameserver.local -m shell -a "cd {{ggApp_workspace}}/{{inventory_hostname}}/shell && sh restart.sh"
# 强制关闭(非安全关闭)
ansible gameserver_1 -i hosts/gameserver.local -m shell -a "cd {{ggApp_workspace}}/{{inventory_hostname}}/shell && sh kill.sh"
# 查看启动状态
ansible gameserver_1 -i hosts/gameserver.local -m shell -a "cd {{ggApp_workspace}}/{{inventory_hostname}}/shell && sh status.sh"
# 执行gm
ansible gameserver_1 -i hosts/gameserver.local -m shell -a "cd {{ggApp_workspace}}/{{inventory_hostname}}/shell && sh gm.sh 0 exec 'return 1+1'"
```

打包和发布
==========
```
# 打包前先更新代码！！！
# 打整包
# 查看帮助
cd shell
sh pack.sh
# 对登录服打整包
sh pack.sh ~/ggApp/loginserver
# 执行pack.sh后会提示生成的包名
# 发布到外网登录服
ansible-playbook -i hosts/loginserver.test --limit loginserver publish.yml -e appName=ggApp -e packname=包名

# 对游戏服打整包
sh pack.sh ~/ggApp/gameserver
# 执行pack.sh后会提示生成的包名
# 发布到所有游戏服
ansible-playbook -i hosts/gameserver.test --limit gameserver publish.yml -e appName=ggApp -e packname=包名
# 发布到gameserver_50
ansible-playbook -i hosts/gameserver.test --limit gameserver_50 publish.yml -e appName=ggApp -e packname=包名
# 发布到登录服
ansible-playbook -i hosts/loginserver.test --limit loginserver publish.yml -e appName=ggApp -e packname=包名

# 打补丁包
# 查看帮助
cd shell
sh packpatch.sh
# 仓库是git管理
# 对游戏服最近2次提交生成补丁包
sh packpatch.sh ~/ggApp/gameserver HEAD~2..HEAD
# 对账号中心最近2次提交生成补丁包
sh packpatch.sh ~/ggApp/loginserver HEAD~2..HEAD
# 仓库是svn管理
# 对游戏服[530,532]之间提交生成补丁包
sh packpatch.sh -s ~/ggApp/gameserver 530:532
# 对账号中心[530,532]之间提交生成补丁包
sh packpatch.sh -s ~/ggApp/loginserver 530:532
# 执行packpatch.sh后会提示生成的补丁包名
# 向游戏服发布补丁包并自动热更
ansible-playbook -i hosts/gameserver.test --limit gameserver publish.yml -e appName=ggApp -e hotfix=true -e packname=补丁包名
# 向登录服发布补丁包并自动热更
ansible-playbook -i hosts/loginserver.test --limit loginserver publish.yml -e appName=ggApp -e hotfix=true -e packname=补丁包名 
```

[Back to TOC](#table-of-contents)

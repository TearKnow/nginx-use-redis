`可以在openresty容器中查看日志。`

### 操作步骤
```
1. docker-compose up -d
2. docker exec -it $(docker ps -qf "name=redis-cluster") redis-cli CONFIG SET cluster-announce-ip redis-cluster
3. docker-compose restart openresty
4. http://localhost:8080/api?id=888  第一次hit false，第二次就是true了，表示成功了
```


### 问题1:
[lua] cache_logic.lua:44: @@@ Redis 写入失败!! Key: user_node:888 Error: failed to parse host name "": no host, client: 172.18.0.1, server: , request: "GET /api?id=888 HTTP/1.1", host: "localhost:8080"

### 解答1:
docker exec -it $(docker ps -qf "name=redis-cluster") redis-cli CONFIG SET cluster-announce-ip redis-cluster


### maybe问题2:
2026/03/28 06:32:12 [error] 7#7: *2 [lua] cache_logic.lua:44: @@@ Redis 写入失败!! Key: user_node:888 Error: failed to parse host name "": no host, client: 172.19.0.1, server: , request: "GET /api?id=888 HTTP/1.1", host: "localhost:8080"
172.19.0.1 - - [28/Mar/2026:06:32:12 +0000] "GET /api?id=888 HTTP/1.1" 200 67 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36"
172.19.0.1 - - [28/Mar/2026:06:32:12 +0000] "GET /.well-known/appspecific/com.chrome.devtools.json HTTP/1.1" 404 561 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36"
### maybe解答2:
```
docker exec -it $(docker ps -qf "name=redis-cluster") redis-cli CONFIG SET cluster-announce-ip redis-cluster

docker exec -it $(docker ps -qf "name=redis-cluster") redis-cli cluster slots

docker-compose restart openresty

```


### 其它命令：
```
别忘了再次手动分配一次槽位（因为重置了）
docker exec -it $(docker ps -qf "name=redis-cluster") redis-cli cluster addslots $(seq 0 16383)
```


#### 笔记
https://docs.google.com/document/d/1GO6dURy8AAA1jj7qV37VyAvGOjwPg4mIZupQJq6aZUk/edit?tab=t.0



```
AI说我这个只是开启了集群模式，但节点数量不够，集群无法工作
参考pdf文件，让它生成了下方案，自己没试过。
```

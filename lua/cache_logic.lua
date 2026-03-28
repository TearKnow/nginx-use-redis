local redis_cluster = require "resty.rediscluster"

local config = {
    name = "test_cluster",
    serv_list = { { ip = "redis-cluster", port = 6379 } },
    use_config_host = true,
    -- 修改这里：从 0 改为 1000 (单位是毫秒)
    -- 这样它会定期同步集群状态，确保拿到 Slots 信息
    refresh_interval = 1000,
    keepalive_timeout = 60000,
    keepalive_cons = 10
}

-- 调试点 1：检查是否进入了逻辑
local id = ngx.var.arg_id or "default"
ngx.log(ngx.ERR, "@@@ 开始处理请求, ID: ", id)

local red, err = redis_cluster:new(config)
if not red then
    ngx.log(ngx.ERR, "@@@ Redis 连接失败: ", err)
    return ngx.exec("/_backend")
end

local cache_key = "user_node:" .. id

-- 1. 查 Redis
local res, err = red:get(cache_key)

if res and res ~= ngx.null then
    ngx.log(ngx.ERR, "@@@ 命中缓存! Key: ", cache_key) -- 调试点 2
    ngx.header["X-Cache-Hit"] = "true"
    ngx.say(res)
    return
end

-- 2. 缓存未命中
ngx.log(ngx.ERR, "@@@ 未命中缓存，尝试回源并写入 Redis...")

local res_up = ngx.location.capture("/_backend")
if res_up.status == 200 then
    -- 调试点 3：检查写入结果
    local ok, set_err = red:setex(cache_key, 60, res_up.body)
    if not ok then
        ngx.log(ngx.ERR, "@@@ Redis 写入失败!! Key: ", cache_key, " Error: ", set_err)
    else
        ngx.log(ngx.ERR, "@@@ Redis 写入成功! Key: ", cache_key)
    end
    
    ngx.header["X-Cache-Hit"] = "false"
    ngx.say(res_up.body)
end
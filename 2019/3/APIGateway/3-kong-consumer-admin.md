### 消费者作用

消费者就是远端用户设备，

- 鉴权：可以通过consumer控制是否允许访问后端api(是否转发问题)， 
- 限速：以comuser为单位进行限速度

#### 添加用户消费者帐号

```
curl -X POST http://127.0.0.1:8001/consumers/ --data 'username=local-test-user' --data 'custom_id=j075a5gnrem3nmhptshem4d6oatl44ekghd2cprb'
{"custom_id":"j075a5gnrem3nmhptshem4d6oatl44ekghd2cprb","created_at":1555471719,"id":"60aeba62-9104-476a-9feb-4f70d07bcd5a","tags":null,"username":"local-test-user"}
```

#### 添加用户apikey

curl -X POST http://localhost:8001/consumers/local-test-user/key-auth --data "key=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJqMDc1YTVnbnJlbTNubWhwdHNoZW00ZDZvYXRsNDRla2doZDJjcHJiIiwicYxbjhkdjEyIiwiYWNjb3VudCI6ImxpeHVhbi5jaGVuZ0ByaXNpbmd1cHRlY2guY29tIiwiVUlEIjoiNWI4NzllOTliY2Y3YzEwZWIwYThiZDRjIiwicm9sZSI6ImN1c3RvbWVyQWRtaW4iLCJpYXQiOjE1NTU0NzA4NzksImV4cCI6MTU1NTQ3NDQ3OX0.U7xFhgxTJhxY8k-gZoKoSzxIFPa9Zy5x_FJV3gmDaBM"

#### 用户通过apikey访问
```
curl -H 'Host: test-example-app.local' --header 'apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJqMDc1YTVnbnJlbTNubWhwdHNoZW00ZDZvYXRsNDRla2doZDJjcHJiIiwicYxbjhkdjEyIiwiYWNjb3VudCI6ImxpeHVhbi5jaGVuZ0ByaXNpbmd1cHRlY2guY29tIiwiVUlEIjoiNWI4NzllOTliY2Y3YzEwZWIwYThiZDRjIiwicm9sZSI6ImN1c3RvbWVyQWRtaW4iLCJpYXQiOjE1NTU0NzA4NzksImV4cCI6MTU1NTQ3NDQ3OX0.U7xFhgxTJhxY8k-gZoKoSzxIFPa9Zy5x_FJV3gmDaBM' http://10.5.7.12:8000
```


#### 添加consumer速度限制

下面是限制j075a5gnrem3nmhptshem4d6oatl44ekghd2cprb每分钟2次， 每小时50次例子

```
curl -X POST http://localhost:8001/plugins \
 --data "name=rate-limiting" \
 --data "consumer.id={60aeba62-9104-476a-9feb-4f70d07bcd5a}" \
 --data "config.minute=2" \
 --data "config.hour=50"
```

```
curl -X POST http://localhost:8001/plugins --data "name=rate-limiting" --data "consumer.id=60aeba62-9104-476a-9feb-4f70d07bcd5a" --data "config.minute=2" --data "config.hour=50"
{"created_at":1555484070,"config":{"minute":2,"policy":"cluster","month":null,"redis_timeout":2000,"limit_by":"consumer","hide_client_headers":false,"second":null,"day":null,"redis_password":null,"year":null,"redis_database":0,"hour":50,"redis_port":6379,"redis_host":null,"fault_tolerant":true},"id":"b951404b-c29b-4156-9633-a1e86a3c329e","service":null,"name":"rate-limiting","protocols":["http","https"],"enabled":true,"run_on":"first","consumer":{"id":"60aeba62-9104-476a-9feb-4f70d07bcd5a"},"route":null,"tags":null}
```


如果超过限速
```
curl -H 'Host: test-example-app.local' --header 'apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJqMDc1YTVnbnJlbTiIiwicYxbjhkdjEyIiwiYWNjb3VudCI6ImxpeHVhbi5jaGVuZ0ByaXNpbmd1cHRlY2guY29tIiwiVUlEIjoiNWI4NzllOTliY2Y3YzEwZWIwYThiZDRjIiwicm9sZSI6ImN1c3RvbWVyQWRtaW4iLCJpYXQiOjE1NTU0NzA4NzksImV4cCI6MTU1NTQ3NDQ3OX0.U7xFhgxTJhxY8k-gZoKoSzxIFPa9Zy5x_FJV3gmDaBM' http://10.5.7.12:8000
{"message":"API rate limit exceeded"}
```

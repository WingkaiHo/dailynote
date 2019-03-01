for ((i=1; i<=10; i++))
do
	echo connect count ${i}
	./ghz -insecure \
     -proto /home/heyj/workspace/git/yongjiahe/rpc_benchmark/src/grpc/helloworld.proto \
     -call helloworld.Greeter.SayHello \
     -d '{"name":"Joe"}' \
     -c ${i} \
     -n 10000 \
     127.0.0.1:5050
done




### 生成ssh-key
```
$ ssh-keygen -t rsa -C yourEmail@example.com
```

### 拷贝公钥内容到gitlab
```
$ cat ~/.ssh/id_rsa.pub 
```

点击生成以后就可以了

### 登陆git仓库
```
ssh -T git@github.com
```

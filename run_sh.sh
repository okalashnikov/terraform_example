#/bin/bash
yum -y update
yum -y install httpd

myip= `curl http://169.254.169.254/latest/meta-data/local-ipv4cat`
cat <<EOF > /var/www/html/index.html
<html>
<head>
</head>
<body>
<font color="green">Server:</font><font color="red">$myip</font>
</body>
</html>
EOF

sudo service httpd start
chkconfig httpd on
# vagrant-wssalud
Entorno Vagrant para MV de webservice salud

1. configurar los datos del la base de datos y la carpeta compartida
# Config virtual machine info
machine_name : 'WS Salud'
local_domain : 'ws-salud.dev'
private_ip   : '192.168.33.20'
machine_ram  : '2048'
machine_cpu  : '2'

mysql_root_pass : 'nokia3189'
mysql_user      : 'root'
mysql_user_pass : 'nokia3189'
mysql_user_db   : 'mysql_user_db'

# Config Synced folders
syncDir :
  - host:  ../src/ws-salud
    guest: /usr/local/ws-salud
    owner: vagrant
    group: www-data
    dmode: 775
    fmode: 775


2. clonar el proyecto dentro de src/ws-salud
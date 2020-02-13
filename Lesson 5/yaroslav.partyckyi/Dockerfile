FROM ubuntu:19.04

RUN apt update && apt install nginx -y

COPY index.html /var/www/html

COPY cake.jpg /var/www/html/image/

RUN service nginx restart

EXPOSE 80

CMD  ["nginx", "-g", "daemon off;"]

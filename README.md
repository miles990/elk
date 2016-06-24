### Run

`
sudo docker build -t my_elk ./
`

`
sudo docker run --name elk_container -d -p 80:80 -p 3333:3333 -p 3334:3334 -p 9200:9200 my_elk /start.sh
`

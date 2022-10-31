#!/bin/bash

IRISWS="https://service.iris.edu/fdsnws/dataselect/1/query?sta=ABPO,MSEY,SUR,KMBO&net=II,IU"
GFZWS="http://geofon.gfz-potsdam.de/fdsnws/dataselect/1/query?sta=KIBK,SBV,VOI"
RESIFWS="http://ws.resif.fr/fdsnws/dataselect/1/query?sta=YTMZ"
RTPRIVWS="http://rtpriv-cdd/fdsnws/dataselect/1/query?sta=RAE55,RCBF0,MCHI,FOMA,RER,BOR,FOR,SNE,CAB,DEMB,MOIN,SBC"
CAS_WS="http://192.168.9.5/fdsnws/dataselect/1/query?"
GGLO_WS="http://193.220.192.205:2080/fdsnws/dataselect/1/query?"

WebService=${GGLO_WS}

station="GGLO"
#station="CAS"
network="QM"
#network="PF"
location="00"
channel="HHZ"

start="2019-05-22T05:15:22"
end="2019-05-22T05:20:22"

channel="HH?"
nomFich=$network.$station.$location".HH.D."$(date -d $start +"%Y%m%d_%H%M%S")
echo ----- Recuperation de $nomFich
wget --no-check-certificate -O data/$nomFich ${WebService}"&starttime="${start}"&endtime="${end}"&network="${network}"&station="${station}"&location="${location}"&channel="${channel}

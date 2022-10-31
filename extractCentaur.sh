#!/bin/bash


#------------------------------------------------------------------------------------------------------------
#                FONCTIONS
#------------------------------------------------------------------------------------------------------------
addSecondes()
{   local sds=""
    local eds=""

    sds=$(date -d ${1:0:19} +%s) 
    eds=$(($sds + $2))
    resultat=$(date -d @$eds +%FT%T)        
}

#------------------------------------------------------------------------------------------------------------
#                SCRIPT
#------------------------------------------------------------------------------------------------------------
    verbose=0
    help=0
    IPport=80
    duree=0

    #--------------------------------------------------------------------------------------------------------
    #      VALEURS PAR DEFAUT
    #--------------------------------------------------------------------------------------------------------
    finEventWS="/fdsnws/event/1/query?"
    finDataWS="/fdsnws/dataselect/1/query?"
    catalogDebut="2019-04-29T15:00:00"
    duree=120
    
    configurationStations="/home/sysop/Outils_Glorieuse/configurationStations.txt"
    dataselectCmd="/home/sysop/Outils_Glorieuse/dataselect/dataselect"
    archiveDir="/home/sysop/Outils_Glorieuse/archive/"
    dataDir="/home/sysop/Outils_Glorieuse/data/"
    syncDir="/mnt/pitonbleu/DonneesAcquisition/Sismo/MINISEED_VALIDE/"
    #$yearCode/$networkCode/$stationCode/ dataPath

    
    while getopts "s:a:d:f:e:n:c:l:t:vh" option
    do 
         case $option in
           s) stationCode=$OPTARG;;
           a) data_WS="http://"$OPTARG"/fdsnws/dataselect/1/query?";;
	       e) event_WS="http://"$OPTARG"/fdsnws/event/1/query?";;
           n) networkCode=$OPTARG;;
           c) channelCode=$OPTARG;;
           l) locCode=$OPTARG;;
	       m) minMag=$OPTARG;;
           d) dateDebut=$(date -d $OPTARG +%FT%T);;
           f) dateFin=$(date -d $OPTARG +%FT%T);;
           t) duree=$OPTARG;;
           v) verbose=1;;
           h) help=1;;
         esac
    done

    if [ $help == 1 ]
    then
        echo "# DOCUMENTATION dataExtractFromCentaur.sh"
        echo "#     Extraction de donnees d un numerisuer centaur via les webservices"
        echo "#     Derniere mise a jour : 25/04/2019 par PhK"
        echo "#" 
        echo "# 1 - Objectif"
        echo "#     Recuperer des porton tres ciblees de signaux sismiques"
        echo "#" 
        echo "# 2 - Syntaxe"
        echo "#    ./dataExtractFromCentaur.sh [options] -s stationCode -d yyyy-mm-dd -t sss"
        echo "#"
        echo "# Parametres obligatoires :"
        echo "#    -d : la date de debut de periode a traiter sous la forme yyyy-mm-ddTHH:mm:ss"
        echo "#    -t : la duree en secondes de la periode a traiter"
        echo "#    -s : code le sation a traiter"
        echo "#"
        echo "# Parametres optionnels"
        echo "#    -n : network code de la station a traiter"
        echo "#      exemple : -n PF"
        echo "#    -c ch1,ch2,..,chn : liste des canaux a recuperer separes par des virgules"
        echo "#      exemple : -c EHZ,HHN,EHE"
        echo "#    -l : location code a traiter"
        echo "#      exemple : -l 00"
	    echo "#    -e event_WS : webservice 'events'"
	    echo "#      exemple : http://mayobs0sc3/fdsn/events/1/query?"
        echo "#    -a data_WS : webservice ou les donnees de la station peuvent etre recuperees"
        echo "#    		exemple : -a 195.83.188.30:453"
        echo "#    -m minMag : limite min de magnitude des evenements a recuperer"
        echo "#    -h : Cette documentation"
        echo "#    -v : mode verbose"
        echo "#"
        echo "# 3 - Limitations connues"
        echo "#"    

        exit 0
    fi
        
    echo "-----------------------------------------------------------------------------"
    echo "                             INITIALISATIONS"

    # interessant en cas de debuggage
    if [ $verbose == 1 ]
    then
        # Affichage des parametres recuperes
        echo "----- Paramètres recuperes via la ligne de commande -----"
        if ! [ -z $stationCode ]; then echo "----- --- stationCode="$stationCode; fi
        if ! [ -z $channelCode ]; then echo "----- --- channelCode="${channelCode//,/ }; fi
        if ! [ -z $locCode ]; then echo "----- --- locCode="$locCode; fi
        if ! [ -z $networkCode ]; then echo "----- --- networkCode="$networkCode; fi
        if ! [ -z $event_WS ]; then echo "----- --- event_WebService="$event_WS; fi
        if ! [ -z $data_WS ]; then echo "----- --- data_WebService="$data_WS; fi
        if ! [ -z $dateDebut ]; then echo "----- --- datedebut="$(date -d $dateDebut +%FT%T); fi
        if ! [ -z $dateFin ]; then echo "----- --- dateFin="$(date -d $dateFin +%FT%T); fi
        if ! [ -z $duree ]; then echo "----- --- duree="$duree; fi        
        if ! [ -z $minMag ]; then echo "----- --- magnitude min="$minMag; fi        
    fi
    # Verification de l existance de la station dans le fichier configuratioStations.txt
    # ---------------------------------------------------------------------
    infoStation=`grep $stationCode $configurationStations | awk '{ print $1 }' `
    if [ -z $infoStation ]
    then
        echo "La station doit exister dans le fichier de configuration !!"
        exit
    fi

    # Recuperation des parametres dans le fichier de configuartion des stations
    # A ce stade les date et la station son OK
    # Recuperation des parametres
    if [ $verbose == 1 ]
    then 
        echo ""
	echo "----- Paramètres recuperes via le fichier configurationStations -----"
    fi
    if [ -z $networkCode ]; then networkCode=`grep $stationCode $configurationStations | awk '{ print $2 }' `; fi
    if [ -z $locCode ]; then locCode=`grep $stationCode $configurationStations | awk '{ print $3 }' `; fi
    if [ -z $channelCode ]; then channelCode=`grep $stationCode $configurationStations | awk '{ print $4 }' `; fi
    if [ -z $data_WS ]; then data_WS="http://"`grep $stationCode $configurationStations | awk '{ print $5 }' `"/fdsnws/dataselect/1/query?"; fi
    if [ -z $event_WS ]; then event_WS="http://"`grep $stationCode $configurationStations | awk '{ print $6 }' `"/fdsnws/event/1/query?"; fi
    if [ -z $minMag ]; then minMag=`grep $stationCode $configurationStations | awk '{ print $7 }' `; fi
     
    # Display eventuel des parametres en mode verbeux
    # ---------------------------------------------------------------------
    if [ $verbose == 1 ]
    then
        #echo "----- Paramètres recuperes via le fichier configurationStations -----"
        echo "----- --- stationCode="$stationCode
        echo "----- --- networkCode="$networkCode
        echo "----- --- channelCode="${channelCode//,/ }
        echo "----- --- locCode="$locCode
        echo "----- --- event_WS="$event_WS
        echo "----- --- data_WS="$data_WS
        echo "----- --- duree="$duree
        echo "----- --- minMag="$minMag
    fi

    prefixFichier=$stationCode"."$networkCode"."$locCode"."${channelCode%?}"."

    # Display eventuel des parametres en mode verbeux
    # ---------------------------------------------------------------------
    if [ $verbose == 1 ]
    then
        echo ""
	echo "----- Variables deduites des parametres -----"
	echo "----- --- prefixFichier="$prefixFichier"YYYY-MM-DDTHH:MM:SS"
	echo "----- --- Nom du Webservice evenements : "$event_WS
	echo "----- --- Nom du Webservice data : "$data_WS
	echo ""
    fi
    

    # Recuperation de la date de debut de periode a telecharge 
    # ---------------------------------------------------------------------
 
   if [ -z $dateDebut ] 
    then
        # recuperation de la liste des fichiers de data
        for nomFich in $dataDir$prefixFichier*
        do
            if [[ ${nomFich:(-19)} > $catalogDebut ]]; then
                catalogDebut=${nomFich:(-19)}
            fi
        done

        # ajout "duree" a l'heure du dernier evenement deja present 
        dateStart=$(date -d $catalogDebut +%s)
        dateEnd=$(($dateStart + $duree))
        catalogDebut=$(date -d @$dateEnd +%FT%T)
        catalogFin=`date +%FT%T`
    else
        catalogDebut=$dateDebut
        if [ -z $dateFin ]
        then
            catalogFin=`date +%FT%T`
        else
            catalogFin=$dateFin
        fi 
    fi

    # Recuperation du catalogue BRGM
    # ---------------------------------------------------------------------
    rm $dataDir"catalogue.txt"
    echo "----- Recuperation du catalogue de "$catalogDebut" à "$catalogFin
    echo wget --no-check-certificate -O $dataDir"catalogue.txt "${event_WS}"starttime="${catalogDebut}"&minmagnitude="${minMag}
    echo "                   &format=text&nodata=404"
    wget --no-check-certificate -O ${dataDir}catalogue.txt ${event_WS}"starttime="${catalogDebut}"&endtime="${catalogFin}"&minmagnitude="${minMag}"&format=text&nodata=404"
    
    # Recuperation des signaux correspondant aux evenements du catalogue 
    # ---------------------------------------------------------------------

    echo "----- Recuperation des donnees evenements"
    while IFS="|" read eventID Time Longitude Depth Author Catalog Contributor ContributorID MagType Magnitude MagAuthor EventLocationName
    do
        if [ $Time != "Time" ] ;
        then
            startTime=${Time:0:19}
            sd=$(date -d $startTime +%s) 
            ed=$(($sd + $duree))
            endTime=$(date -d @$ed +%FT%T)
            dateFichier=$(date -d $startTime +%FT%T)

            echo -e "Evenement $eventID : $startTime a $endTime"
            wget --no-check-certificate -O $dataDir$prefixFichier$dateFichier ${data_WS}"starttime="${startTime}"&endtime="${endTime}"&network="${networkCode}"&station="${stationCode}"&channel="${channelCode}"&location="${locCode}"&nodata=404"
        else
            echo "Aucun nouvel evenement !"
        fi
    done < $dataDir"catalogue.txt"
    
    # Transformation en archive SDS
    # ---------------------------------------------------------------------
    echo ${dataselectCmd}" -SDS "${archiveDir} $dataDir$stationCode"."$networkCode".* "  
    $dataselectCmd -SDS ${archiveDir} $dataDir$stationCode.*
    
    # Transfert dans MINISEED_VALIDE
    #       rsync serait mieux mais je ne maitrise pas !!!!
    # rsync -av --no-owner --no-perms ${archiveDir} ${syncDir} data
  
  
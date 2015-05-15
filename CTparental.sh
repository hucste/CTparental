#!/bin/bash 
# CTparental.sh
#
# par Guillaume MARSAT
# Corrections orthographiques par Pierre-Edouard TESSIER
# une partie du code est tirée du script alcasar-bl.sh créé par Franck BOUIJOUX et Richard REY
# présente dans le code du projet alcasar en version 2.6.1 ; web page http://www.alcasar.net/
 
# This script is distributed under the Gnu General Public License (GPL)
arg1=${1}
if [ $# -ge 1 ];then
if [ $arg1 != "-listusers" ] ; then
if [ ! $UID -le 499 ]; then # considère comme root tous les utilisateurs avec un uid inferieur ou egale a 499,ce qui permet à apt-get,urpmi,yum... de lancer le script sans erreur.
   echo "Il vous faut des droits root pour lancer ce script"
   exit 1
fi
fi
fi
if  [ $(groups $(whoami) | grep -c -E "( ctoff$)|( ctoff )") -eq 0 ];then
  export https_proxy=http://127.0.0.1:8080
  export HTTPS_PROXY=http://127.0.0.1:8080
  export http_proxy=http://127.0.0.1:8080
  export HTTP_PROXY=http://127.0.0.1:8080
else
  unset https_proxy
  unset HTTPS_PROXY
  unset http_proxy
  unset HTTP_PROXY
fi

noinstalldep="0"
nomanuel="0"
ARGS=($*)
for (( narg=1; narg<=$#; narg++ )) ; do
        case "${ARGS[$narg]}" in
	  -nodep )
	     noinstalldep="1"
	  ;;
	  -nomanuel )
	     nomanuel="1"
	  ;;
	  -dirhtml )
	     narg=$(( $narg +1 ))
	     DIRhtmlPersonaliser=${ARGS[$narg]}
	     if [ ! -d $DIRhtmlPersonaliser ];then
		echo "Chemin de répertoire non valide!"
		exit 0
	     fi
	  ;;
	esac
done
pause () {   # fonction pause pour debugage
      MESSAGE="$*"
      choi=""
      MESSAGE=${MESSAGE:="pour continuer appuyez sur une touche :"}
      echo  "$MESSAGE"
      while (true); do
         read choi
         case $choi in
         * )
         break
         ;;
      esac
      done
}
SED="/bin/sed -i"
DIR_CONF="/usr/local/etc/CTparental"
FILE_CONF="$DIR_CONF/CTparental.conf"
FILE_GCTOFFCONF="$DIR_CONF/GCToff.conf"
FILE_HCOMPT="$DIR_CONF/CThourscompteur"
FILE_HCONF="$DIR_CONF/CThours.conf"
if [ ! -f $FILE_CONF ] ; then
mkdir -p $DIR_CONF
mkdir -p /usr/local/share/CTparental/
cat << EOF > $FILE_CONF
LASTUPDATE=0
DNSMASQ=BLACK
AUTOUPDATE=OFF
HOURSCONNECT=OFF
GCTOFF=OFF
# Parfeux minimal.
IPRULES=OFF
EOF

fi
FILTRAGEISOFF=$(cat $FILE_CONF | grep -c DNSMASQ=OFF)



## imports du plugin de la distributions si il existe
if [ -f $DIR_CONF/dist.conf ];then
	source  $DIR_CONF/dist.conf 
fi

tempDIR="/tmp/alcasar"
tempDIRRamfs="/tmp/alcasarRamfs"
if [ ! -d $tempDIRRamfs ] ; then
mkdir $tempDIRRamfs
fi
RougeD="\033[1;31m"
BleuD="\033[1;36m"
VertD="\033[1;32m"
Fcolor="\033[0m"
GESTIONNAIREDESESSIONS=" login gdm lightdm slim kdm xdm lxdm gdm3 "
FILEPAMTIMECONF="/etc/security/time.conf"
DIRPAM="/etc/pam.d/"
DAYS=${DAYS:="lundi mardi mercredi jeudi vendredi samedi dimanche "}
DAYS=( $DAYS )
DAYSPAM=( Mo Tu We Th Fr Sa Su )
DAYSCRON=( mon tue wed thu fri sat sun )
PROXYport=${PROXYport:="8888"}
DANSGport=${DANSGport:="8080"}
PROXYuser=${PROXYuser:="privoxy"}
#### DEPENDANCES par DEFAULT #####
DEPENDANCES=${DEPENDANCES:=" dnsmasq lighttpd php5-cgi libnotify-bin notification-daemon iptables-persistent rsyslog dansguardian privoxy openssl libnss3-tools whiptail "}
#### PACKETS EN CONFLI par DEFAULT #####
CONFLICTS=${CONFLICTS:=" mini-httpd apache2 firewalld "}

#### COMMANDES de services par DEFAULT #####
CMDSERVICE=${CMDSERVICE:="service "}
CRONstart=${CRONstart:="$CMDSERVICE cron start "}
CRONstop=${CRONstop:="$CMDSERVICE cron stop "}
CRONrestart=${CRONrestart:="$CMDSERVICE cron restart "}
LIGHTTPDstart=${LIGHTTPDstart:="$CMDSERVICE lighttpd start "}
LIGHTTPDstop=${LIGHTTPDstop:="$CMDSERVICE lighttpd stop "}
LIGHTTPDrestart=${LIGHTTPDrestart:="$CMDSERVICE lighttpd restart "}
DNSMASQstart=${DNSMASQstart:="$CMDSERVICE dnsmasq start "}
DNSMASQstop=${DNSMASQstop:="$CMDSERVICE dnsmasq stop "}
DNSMASQrestart=${DNSMASQrestart:="$CMDSERVICE dnsmasq restart "}
NWMANAGERstop=${NWMANAGERstop:="$CMDSERVICE network-manager stop"}
NWMANAGERstart=${NWMANAGERstart:="$CMDSERVICE network-manager start"}
NWMANAGERrestart=${NWMANAGERrestart:="$CMDSERVICE network-manager restart"}
IPTABLESsave=${IPTABLESsave:="$CMDSERVICE iptables-persistent save"}
DANSGOUARDIANrestart=${DANSGOUARDIANrestart:="$CMDSERVICE dansguardian restart"}
PRIVOXYrestart=${PRIVOXYrestart:="$CMDSERVICE privoxy restart"}
#### LOCALISATION du fichier PID lighttpd par default ####
LIGHTTPpidfile=${LIGHTTPpidfile:="/var/run/lighttpd.pid"}

#### LOCALISATION du fichier de chargement de modules ####
FILEMODULESLOAD=${MODULESLOAD:="/etc/modules-load.d/modules.conf"}

RSYSLOGCTPARENTAL=${RSYSLOGCTPARENTAL:="/etc/rsyslog.d/iptables.conf"}

#### COMMANDES D'ACTIVATION DES SERVICES AU DEMARAGE DU PC ####
ENCRON=${ENCRON:=""}
ENLIGHTTPD=${ENLIGHTTPD:=""}
ENDNSMASQ=${ENDNSMASQ:=""}
ENNWMANAGER=${ENNWMANAGER:=""}
ENIPTABLESSAVE=${ENIPTABLESSAVE:=""}
#### UID MINIMUM pour les UTILISATEUR
UIDMINUSER=${UIDMINUSER:=1000}


FILEConfDans=${FILEConfDans:="/etc/dansguardian/dansguardian.conf"}
FILEConfDansf1=${FILEConfDansf1:="/etc/dansguardian/dansguardianf1.conf"}
DNSMASQCONF=${DNSMASQCONF:="/etc/dnsmasq.conf"}
MAINCONFHTTPD=${MAINCONFHTTPD:="/etc/lighttpd/lighttpd.conf"}
DIRCONFENABLEDHTTPD=${DIRCONFENABLEDHTTPD:="/etc/lighttpd/conf-enabled"}
CTPARENTALCONFHTTPD=${CTPARENTALCONFHTTPD:="$DIRCONFENABLEDHTTPD/10-CTparental.conf"}
DIRHTML=${DIRHTML:="/var/www/CTparental"}
DIRadminHTML=${DIRadminHTML:="/var/www/CTadmin"}
PASSWORDFILEHTTPD=${PASSWORDFILEHTTPD:="/etc/lighttpd/lighttpd-htdigest.user"}
REALMADMINHTTPD=${REALMADMINHTTPD:="interface admin"}
CADIR=${CADIR:="/usr/share/ca-certificates/ctparental"}
PEMSRVDIR=${PEMSRVDIR:="/etc/ssl/private"}
CMDINSTALL=""
IPTABLES=${IPTABLES:="/sbin/iptables"}
ADDUSERTOGROUP=${ADDUSERTOGROUP:="gpasswd -a "}
DELUSERTOGROUP=${DELUSERTOGROUP:="gpasswd -d "}
PRIVOXYCONF=${PRIVOXYCONF:="/etc/privoxy/config"}
PRIVOXYUSERA=${PRIVOXYUSERA:="/etc/privoxy/user.action"}
PRIVOXYCTA=${PRIVOXYCTA:="/etc/privoxy/ctparental.action"}
CTFILEPROXY=${CTFILEPROXY:="$DIR_CONF/CT-proxy.sh"}
XSESSIONFILE=${XSESSIONFILE:="/etc/X11/Xsession"}
REPCAMOZ=${REPCAMOZ:="/usr/share/ca-certificates/mozilla/"}
XTERMINAL=${XTERMINAL:="x-terminal-emulator --hide-menubar  --hide-toolbar -e "}
if [ $(yum help 2> /dev/null | wc -l ) -ge 50 ] ; then
   ## "Distribution basée sur yum exemple redhat, fedora..."
   CMDINSTALL=${CMDINSTALL:="yum install "}
   CMDREMOVE=${CMDREMOVE:="rpm -e "}
fi
urpmi --help 2&> /dev/null
if [ $? -eq 1 ] ; then
   ## "Distribution basée sur urpmi exemple mandriva..."
   CMDINSTALL=${CMDINSTALL:="urpmi -a --auto "}
   CMDREMOVE=${CMDREMOVE:="rpm -e "}
fi
apt-get -h 2&> /dev/null
if [ $? -eq 0 ] ; then
   ## "Distribution basée sur apt-get exemple debian, ubuntu ..."
   CMDINSTALL=${CMDINSTALL:="apt-get -y --force-yes install "}
   CMDREMOVE=${CMDREMOVE:="dpkg --purge  "}
fi

if [ $( echo $CMDINSTALL | wc -m ) -eq 1 ] ; then
   echo "Aucun gestionner de paquet connu , n'a été détecté."
   set -e
   exit 1
fi
ISINTALLMANUEL=${ISINTALLMANUEL:=1}



interface_WAN=$(ip route | awk '/^default via/{print $5}' | sort -u ) 
ipbox=$(ip route | awk '/^default via/{print $3}' | sort -u )   # suppose que la passerelle est la route par défaut
ipinterface_WAN=$(ifconfig $interface_WAN | awk '/adr:/{print $2}' | cut -d":" -f2)
reseau_box=$(ip route | grep / | grep "$interface_WAN" | cut -d" " -f1 )
ip_broadcast=$(ifconfig $interface_WAN | awk '/Bcast:/{print $3}' | cut -d":" -f2)

DNS1=$(cat /etc/resolv.conf | grep ^nameserver | cut -d " " -f2 | tr "\n" " " | cut -d " " -f1)
DNS2=$(cat /etc/resolv.conf | grep ^nameserver | cut -d " " -f2 | tr "\n" " " | cut -d " " -f2)

resolvconffixon () {
echo "resolvconffixon"
# redemare dnsmasq 
$DNSMASQstop

resolvconf -u 2&> /dev/null 
if [ $? -eq 1 ];then # si resolvconf et bien installé
resolvconf -u
# on s'assure que les dns du FAI soit bien ajoutés au fichier /etc/resolv.conf malgré l'utilisation de dnsmasq.
cat /etc/resolv.conf | grep ^nameserver | sort -u > /etc/resolvconf/resolv.conf.d/tail
fi
$DNSMASQstart
echo "fin resolvconffixon"
}
resolvconffixoff () {
echo "resolvconffixoff"
$DNSMASQstop	
resolvconf -u 2&> /dev/null 
if [ $? -eq 1 ];then # si resolvconf et bien installé
echo > /etc/resolvconf/resolv.conf.d/tail
resolvconf -u
fi
echo "fin resolvconffixoff"
}


PRIVATE_IP="127.0.0.10"

FILE_tmp=${FILE_tmp:="$tempDIRRamfs/filetmp.txt"}
FILE_tmpSizeMax=${FILE_tmpSizeMax:="128M"}  # 70 Min, Recomend 128M 
LOWRAM=${LOWRAM:=0}
if [ $LOWRAM -eq 0 ] ; then
MFILEtmp="mount -t tmpfs -o size=$FILE_tmpSizeMax tmpfs $tempDIRRamfs"
UMFILEtmp="umount $tempDIRRamfs"
else
MFILEtmp=""
UMFILEtmp=""
fi
BL_SERVER="dsi.ut-capitole.fr"
FILEIPBLACKLIST="$DIR_CONF/ip-blackliste"
FILEIPTABLES="$DIR_CONF/iptables"
CATEGORIES_ENABLED="$DIR_CONF/categories-enabled"
BL_CATEGORIES_AVAILABLE="$DIR_CONF/bl-categories-available"
WL_CATEGORIES_AVAILABLE="$DIR_CONF/wl-categories-available"
DIR_DNS_FILTER_AVAILABLE="$DIR_CONF/dnsfilter-available"
DIR_DNS_BLACKLIST_ENABLED="$DIR_CONF/blacklist-enabled"
DIR_DNS_WHITELIST_ENABLED="$DIR_CONF/whitelist-enabled"
DNS_FILTER_OSSI="$DIR_CONF/blacklist-local"
DREAB="$DIR_CONF/domaine-rehabiliter" 
DANSXSITELIST="/etc/dansguardian/lists/exceptionsitelist"
THISDAYS=$(expr $(date +%Y) \* 365 + $(date +%j))
MAXDAYSFORUPDATE="7" # update tous les 7 jours
CHEMINCTPARENTLE=$(readlink -f $0)

initblenabled () {
   cat << EOF > $CATEGORIES_ENABLED
adult
agressif
dangerous_material
dating
drogue
gambling
hacking
malware
marketingware
mixed_adult
phishing
redirector
sect
strict_redirector
strong_redirector
tricheur
warez
ossi   
EOF
         

}
confdansguardian () {
echo "confdansguardian"
  $SED "s?^loglevel =.*?loglevel = 0?g" $FILEConfDans   
  $SED "s?^languagedir =.*?languagedir = '/etc/dansguardian/languages'?g" $FILEConfDans  
  $SED "s?^language =.*?language = 'french'?g" $FILEConfDans  
  $SED "s?^logexceptionhits =.*?logexceptionhits = 0?g" $FILEConfDans 
  $SED "s?^filterip =.*?filterip = 127.0.0.1?g" $FILEConfDans
  $SED "s?^proxyip =.*?proxyip = 127.0.0.1?g" $FILEConfDans  
  $SED "s?^filterport =.*?filterport = $DANSGport?g" $FILEConfDans 
  $SED "s?^proxyport =.*?proxyport = $PROXYport?g" $FILEConfDans 
  $SED "s?^proxyport =.*?proxyport = $PROXYport?g" $FILEConfDans 
  $SED "s?^accessdeniedaddress =.*?accessdeniedaddress = 'http://127.0.0.10/index.php'?g" $FILEConfDans
  $SED "s?.*UNCONFIGURED.*?#UNCONFIGURED?g" $FILEConfDans
  echo "#le filtrage de domaines est géré par dnsmasq, ne pa toucher ce fichier!!" > /etc/dansguardian/lists/bannedsitelist


$DANSGOUARDIANrestart
echo "fin confdansguardian" 
}
confprivoxy () {
echo "confprivoxy"
$SED "s?^debug.*?debug = 0?g"  $PRIVOXYCONF  
$SED "s?^listen-address.*?listen-address  127.0.0.1:$PROXYport?g"  $PRIVOXYCONF 

	test=$(grep "actionsfile ctparental.action" $PRIVOXYCONF |wc -l)
	if [ $test -ge "1" ] ; then
		$SED "s?actionsfile.*ctparental.*?actionsfile ctparental\.action      # ctparental customizations?g" $PRIVOXYCONF
	else
	    nline=$(grep "actionsfile.*user.action" $PRIVOXYCONF -n | cut -d":" -f1)
		$SED $nline"i\actionsfile ctparental.action      # ctparental customizations" $PRIVOXYCONF
	fi
	unset test

echo '{{alias}}' > $PRIVOXYCTA
echo '+crunch-all-cookies = +crunch-incoming-cookies +crunch-outgoing-cookies' >> $PRIVOXYCTA
echo '-crunch-all-cookies = -crunch-incoming-cookies -crunch-outgoing-cookies' >> $PRIVOXYCTA
echo ' allow-all-cookies  = -crunch-all-cookies -session-cookies-only -filter{content-cookies}' >> $PRIVOXYCTA
echo ' allow-popups       = -filter{all-popups} -filter{unsolicited-popups}' >> $PRIVOXYCTA
echo '+block-as-image     = +block{Blocked image request.} +handle-as-image' >> $PRIVOXYCTA
echo '-block-as-image     = -block' >> $PRIVOXYCTA
echo 'fragile     = -block -crunch-all-cookies -filter -fast-redirects -hide-referer -prevent-compression' >> $PRIVOXYCTA
echo 'shop        = -crunch-all-cookies allow-popups' >> $PRIVOXYCTA
echo 'myfilters   = +filter{html-annoyances} +filter{js-annoyances} +filter{all-popups}\' >> $PRIVOXYCTA
echo '              +filter{webbugs} +filter{banners-by-size}' >> $PRIVOXYCTA
echo 'allow-ads   = -block -filter{banners-by-size} -filter{banners-by-link}' >> $PRIVOXYCTA
echo '{ fragile }' >> $PRIVOXYCTA
echo 'http://127.0.0.10.*' >> $PRIVOXYCTA
echo 'http://localhost.*' >> $PRIVOXYCTA
echo '# BING Add &adlt=strict' >> $PRIVOXYCTA
echo '{+redirect{s@$@&adlt=strict@}}' >> $PRIVOXYCTA
echo '.bing./.*[&?]q=' >> $PRIVOXYCTA
echo '{-redirect}' >> $PRIVOXYCTA
echo '.bing./.*&adlt=strict' >> $PRIVOXYCTA
echo >> $PRIVOXYCTA
echo '# dailymotion.com ' >> $PRIVOXYCTA
echo '# remplace http://www.dailymotion.com/family_filter?enable=false....' >> $PRIVOXYCTA
echo '# par http://www.dailymotion.com/family_filter?enable=true...' >> $PRIVOXYCTA
echo '{+redirect{s@enable=[^&]+@enable=true@}}' >> $PRIVOXYCTA
echo ' .dailymotion.*/.*enable=(?!true)' >> $PRIVOXYCTA


$PRIVOXYrestart
setproxy
echo "fin confprivoxy"
}
unsetproxy () {
for user in `listeusers` ; do	
	HOMEPCUSER=$(getent passwd "$user" | cut -d ':' -f6)
	if [  -f $HOMEPCUSER/.profile ] ; then
	test=$(grep "^### CTparental ###" $HOMEPCUSER/.profile |wc -l)
		if [ $test -eq "1" ] ; then	 
		 $SED  2d $HOMEPCUSER/.profile
		 $SED  2d $HOMEPCUSER/.profile
		 $SED  2d $HOMEPCUSER/.profile
		 $SED  2d $HOMEPCUSER/.profile
		 $SED  2d $HOMEPCUSER/.profile
		 $SED  2d $HOMEPCUSER/.profile
		 $SED  2d $HOMEPCUSER/.profile
		fi
	unset test
	fi	
done
test=$(grep "^### CTparental ###" $XSESSIONFILE |wc -l)
		if [ $test -eq "1" ] ; then	 
		 $SED  2d $XSESSIONFILE
		 $SED  2d $XSESSIONFILE
		 $SED  2d $XSESSIONFILE
		 $SED  2d $XSESSIONFILE
		 $SED  2d $XSESSIONFILE
		 $SED  2d $XSESSIONFILE
		 $SED  2d $XSESSIONFILE
		fi
unset test
}
setproxy () {
if [  -f $XSESSIONFILE ] ; then
test=$(grep "^### CTparental ###" $XSESSIONFILE |wc -l)
		if [ $test -eq "0" ] ; then	 
		 $SED  2"i\### CTparental ###" $XSESSIONFILE
		 $SED  3'i\if  [ \$(groups \$(whoami) | grep -c -E "( ctoff\$)|( ctoff )") -eq 0 ];then' $XSESSIONFILE
		 $SED  4"i\  export https_proxy=http://127.0.0.1:$DANSGport" $XSESSIONFILE
		 $SED  5"i\  export HTTPS_PROXY=http://127.0.0.1:$DANSGport" $XSESSIONFILE
		 $SED  6"i\  export http_proxy=http://127.0.0.1:$DANSGport" $XSESSIONFILE
		 $SED  7"i\  export HTTP_PROXY=http://127.0.0.1:$DANSGport" $XSESSIONFILE
		 $SED  8"i\fi" $XSESSIONFILE
		fi
unset test
fi
for user in `listeusers` ; do	
	HOMEPCUSER=$(getent passwd "$user" | cut -d ':' -f6)
	if [  -f $HOMEPCUSER/.profile ] ; then
	test=$(grep "^### CTparental ###" $HOMEPCUSER/.profile |wc -l)
		if [ $test -eq "0" ] ; then	 
		 $SED  2"i\### CTparental ###" $HOMEPCUSER/.profile
		 $SED  3'i\if  [ \$(groups \$(whoami) | grep -c -E "( ctoff\$)|( ctoff )") -eq 0 ];then' $HOMEPCUSER/.profile
		 $SED  4"i\  export https_proxy=http://127.0.0.1:$DANSGport" $HOMEPCUSER/.profile
		 $SED  5"i\  export HTTPS_PROXY=http://127.0.0.1:$DANSGport" $HOMEPCUSER/.profile
		 $SED  6"i\  export http_proxy=http://127.0.0.1:$DANSGport" $HOMEPCUSER/.profile
		 $SED  7"i\  export HTTP_PROXY=http://127.0.0.1:$DANSGport" $HOMEPCUSER/.profile
		 $SED  8"i\fi" $HOMEPCUSER/.profile
		fi
	unset test
	fi
	
done
}

addadminhttpd() {
if [ ! -f $PASSWORDFILEHTTPD ] ; then
    echo -n > $PASSWORDFILEHTTPD   
fi

chown root:$USERHTTPD $PASSWORDFILEHTTPD
chmod 640 $PASSWORDFILEHTTPD
USERADMINHTTPD=${1}
pass=${2}
hash=$(echo -n "$USERADMINHTTPD:$REALMADMINHTTPD:$pass" | md5sum | cut -b -32)
ligne=$(echo "$USERADMINHTTPD:$REALMADMINHTTPD:$hash")
echo $ligne
$SED "/.*:$REALMADMINHTTPD.*/d" $PASSWORDFILEHTTPD 
echo $ligne >> $PASSWORDFILEHTTPD
}

download() {
   rm -rf $tempDIR
   mkdir $tempDIR
   # on attend que la connection remonte suite au redemarage de networkmanager
   echo "attente de connection au serveur de toulouse:"
   i=1
   while [ $(ping -c 1 $BL_SERVER 2> /dev/null | grep -c "1 received"  ) -eq 0 ]
   do
   echo -n .
   sleep 1
   i=$(($i + 1 ))
   if [ $i -ge 40 ];then # si au bout de 40 secondes on a toujours pas de connection on considaire qu'il y a une erreur
		echo "connection a $BL_SERVER impossible."
		set -e
		exit 1
   fi
   done
   echo
   echo "connection établit:"
   
   wget -P $tempDIR http://$BL_SERVER/blacklists/download/blacklists.tar.gz 2>&1 | cat
   if [ ! $? -eq 0 ]; then
      echo "erreur lors du téléchargement, processus interrompu"
      rm -rf $tempDIR
      set -e
      exit 1
   fi
   tar -xzf $tempDIR/blacklists.tar.gz -C $tempDIR
   if [ ! $? -eq 0 ]; then
      echo "erreur d'extraction de l'archive, processus interrompu"
      set -e
      exit 1
   fi
   rm -rf $DIR_DNS_FILTER_AVAILABLE/
   mkdir $DIR_DNS_FILTER_AVAILABLE
}
autoupdate() {
        LASTUPDATEDAY=`grep LASTUPDATE= $FILE_CONF | cut -d"=" -f2`
        LASTUPDATEDAY=${LASTUPDATEDAY:=0}
        DIFFDAY=$(expr $THISDAYS - $LASTUPDATEDAY)
	if [ $DIFFDAY -ge $MAXDAYSFORUPDATE ] ; then
		download
		adapt
		catChoice
		dnsmasqon
                $SED "s?^LASTUPDATE.*?LASTUPDATE=$THISDAYS=`date +%d-%m-%Y\ %T`?g" $FILE_CONF
		exit 0
	fi
}
autoupdateon() {
$SED "s?^AUTOUPDATE.*?AUTOUPDATE=ON?g" $FILE_CONF
echo "*/10 * * * * root $CHEMINCTPARENTLE -aup" > /etc/cron.d/CTparental-autoupdate
$CRONrestart
}

autoupdateoff() {
$SED "s?^AUTOUPDATE.*?AUTOUPDATE=OFF?g" $FILE_CONF
rm -f /etc/cron.d/CTparental-autoupdate
$CRONrestart
}
adapt() {
   echo adapt
   date +%H:%M:%S
   dnsmasqoff
   $MFILEtmp
   if [ ! -f $DNS_FILTER_OSSI ] ; then
            echo > $DNS_FILTER_OSSI
   fi

   if [ -d $tempDIR  ] ; then
	  CATEGORIES_AVAILABLE=$tempDIR/categories_available
	  ls -FR $tempDIR/blacklists | grep '/$' | sed -e "s/\///g" > $CATEGORIES_AVAILABLE
          echo -n > $BL_CATEGORIES_AVAILABLE
          echo -n > $WL_CATEGORIES_AVAILABLE
          if [ ! -f $DIR_DNS_FILTER_AVAILABLE/ossi.conf ] ; then
		echo > $DIR_DNS_FILTER_AVAILABLE/ossi.conf
	  fi
	  for categorie in `cat $CATEGORIES_AVAILABLE` # creation des deux fichiers de categories (BL / WL)
	  do
		if [ -e $tempDIR/blacklists/$categorie/usage ]
		then
			is_whitelist=`grep white $tempDIR/blacklists/$categorie/usage|wc -l`
		else
			is_whitelist=0 # ou si le fichier 'usage' n'existe pas, on considère que la catégorie est une BL
		fi
		if [ $is_whitelist -eq "0" ]
		then
			echo "$categorie" >> $BL_CATEGORIES_AVAILABLE
		else
			echo "$categorie" >> $WL_CATEGORIES_AVAILABLE
		fi
	   done
         echo -n "Toulouse Black and White List migration process. Please wait : "
         for DOMAINE in `cat  $CATEGORIES_AVAILABLE`  # pour chaque catégorie
         do
            echo -n "."
              # suppression des @IP, de caractères acccentués et des lignes commentées ou vides
            cp -f $tempDIR/blacklists/$DOMAINE/domains $FILE_tmp
            $SED -r '/([0-9]{1,3}\.){3}[0-9]{1,3}/d' $FILE_tmp
	    $SED "/[äâëêïîöôüû]/d" $FILE_tmp
	    $SED "/^#.*/d" $FILE_tmp
            $SED "/^$/d" $FILE_tmp
            $SED "s/\.\{2,10\}/\./g" $FILE_tmp # supprime les suite de "." exemple: address=/fucking-big-tits..com/127.0.0.10 devient address=/fucking-big-tits.com/127.0.0.10
	    is_blacklist=`grep $DOMAINE $BL_CATEGORIES_AVAILABLE |wc -l`
	    if [ $is_blacklist -ge "1" ] ; then
            	$SED "s?.*?address=/&/$PRIVATE_IP?g" $FILE_tmp  # Mise en forme dnsmasq des listes noires
		mv $FILE_tmp $DIR_DNS_FILTER_AVAILABLE/$DOMAINE.conf  
            else
		$SED "s?.*?server=/&/#?g" $FILE_tmp  # Mise en forme dnsmasq des listes blanches
		mv $FILE_tmp $DIR_DNS_FILTER_AVAILABLE/$DOMAINE.conf
            fi
         done
   else
         mkdir   $tempDIR
         echo -n "."
			# suppression des @IP, de caractères acccentués et des lignes commentées ou vides
         cp -f $DNS_FILTER_OSSI $FILE_tmp
         $SED -r '/([0-9]{1,3}\.){3}[0-9]{1,3}/d' $FILE_tmp
         $SED "/[äâëêïîöôüû]/d" $FILE_tmp 
         $SED "/^#.*/d" $FILE_tmp 
         $SED "/^$/d" $FILE_tmp 
         $SED "s/\.\{2,10\}/\./g" $FILE_tmp # supprime les suite de "." exemple: address=/fucking-big-tits..com/127.0.0.10 devient address=/fucking-big-tits.com/127.0.0.10
         $SED "s?.*?address=/&/$PRIVATE_IP?g" $FILE_tmp  # Mise en forme dnsmasq
         mv $FILE_tmp $DIR_DNS_FILTER_AVAILABLE/ossi.conf
   fi     
   echo
   $UMFILEtmp
   rm -rf $tempDIR
date +%H:%M:%S
}
catChoice() {
#   echo "catChoice"
   rm -rf $DIR_DNS_BLACKLIST_ENABLED/
   mkdir $DIR_DNS_BLACKLIST_ENABLED
   rm -rf  $DIR_DNS_WHITELIST_ENABLED/
   mkdir  $DIR_DNS_WHITELIST_ENABLED
     
      for CATEGORIE in `cat $CATEGORIES_ENABLED` # on affecte les catégories dnsmasq
      do
	 is_blacklist=`grep $CATEGORIE $BL_CATEGORIES_AVAILABLE |wc -l`
	 if [ $is_blacklist -ge "1" ] ; then
		cp $DIR_DNS_FILTER_AVAILABLE/$CATEGORIE.conf $DIR_DNS_BLACKLIST_ENABLED/
         else
		cp $DIR_DNS_FILTER_AVAILABLE/$CATEGORIE.conf $DIR_DNS_WHITELIST_ENABLED/
     	 fi     
      done
      cp $DIR_DNS_FILTER_AVAILABLE/ossi.conf $DIR_DNS_BLACKLIST_ENABLED/
#      echo "fincatChoice"
      reabdomaine
}

reabdomaine () {
echo reabdomaine
date +%H:%M:%S
$MFILEtmp
if [ ! -f $DREAB ] ; then
cat << EOF > $DREAB
www.google.com
www.google.fr
EOF
fi
if [ ! -f $DIR_DNS_BLACKLIST_ENABLED/ossi.conf ] ; then
	echo > $DIR_DNS_BLACKLIST_ENABLED/ossi.conf
fi
echo
echo -n "Application de la liste blanche (domaine réhabilité):"
for CATEGORIE in `cat  $CATEGORIES_ENABLED  `  # pour chaque catégorie
do 
	is_blacklist=`grep $CATEGORIE $BL_CATEGORIES_AVAILABLE |wc -l`
	if [ $is_blacklist -ge "1" ] ; then
		echo -n "."
		for DOMAINE in `cat  $DREAB`
		do
		    cp -f $DIR_DNS_BLACKLIST_ENABLED/$CATEGORIE.conf $FILE_tmp
		    $SED "/$DOMAINE/d" $FILE_tmp
                    cp -f $FILE_tmp $DIR_DNS_BLACKLIST_ENABLED/$CATEGORIE.conf
		done
        fi
done
echo "localhost" > $DANSXSITELIST
echo "127.0.0.1" >> $DANSXSITELIST
cat $DREAB | sed -e"s/^\.//g" | sed -e"s/^www.//g" >> $DANSXSITELIST
echo -n "."
cat $DREAB | sed -e "s? ??g" | sed -e "s?.*?server=/&/#?g" >  $DIR_DNS_WHITELIST_ENABLED/whiteliste.ossi.conf
echo
$UMFILEtmp
rm -f $FILE_tmp
date +%H:%M:%S
## on force a passer par forcesafesearch.google.com de maninière transparente
forcesafesearchgoogle=`host -ta forcesafesearch.google.com|cut -d" " -f4`	# retrieve forcesafesearch.google.com ip
echo "# nosslsearch redirect server for google" > $DIR_DNS_BLACKLIST_ENABLED/googlenosslsearch.conf	
for subdomaingoogle in `wget http://www.google.com/supported_domains -O - 2> /dev/null `  # pour chaque sous domain de google
do 
echo "address=/www$subdomaingoogle/$forcesafesearchgoogle" >> $DIR_DNS_BLACKLIST_ENABLED/forcesafesearch.conf	
done
## on force a passer par safe.duckduckgo.com
for ipsafeduckduckgo in `host -ta safe.duckduckgo.com|cut -d" " -f4 | grep -v alias`
do
echo "address=/safe.duckduckgo.com/$ipsafeduckduckgo" >> $DIR_DNS_BLACKLIST_ENABLED/forcesafesearch.conf
done
echo "address=/duckduckgo.com/127.0.0.1" >> $DIR_DNS_BLACKLIST_ENABLED/forcesafesearch.conf

## on attribut une seul ip pour les recherches sur bing de manière a pouvoir bloquer sont acces en https dans iptables.
## et ainci forcer le safesearch via privoxy.
## tous les sous domaines type fr.bing.com ... retourneront l'ip de www.bing.com
echo "address=/.bing.com/$(host -ta bing.com|cut -d" " -f4)" >> $DIR_DNS_BLACKLIST_ENABLED/forcesafesearch.conf

## on force a passer par search.yahoo.com pour redirection url par lighttpd
#ipsearchyahoo=`host -ta search.yahoo.com|cut -d" " -f4 | grep [0-9]`
#echo "address=/safe.search.yahoo.com/$ipsearchyahoo" >> $DIR_DNS_BLACKLIST_ENABLED/forcesafesearch.conf
#echo "address=/search.yahoo.com/127.0.0.1" >> $DIR_DNS_BLACKLIST_ENABLED/forcesafesearch.conf

# on bloque les moteurs de recherche pas asser sur
echo "address=/search.yahoo.com/127.0.0.10" >> $DIR_DNS_BLACKLIST_ENABLED/forcesafesearch.conf




}

dnsmasqon () {
echo "dnsmasqon"
   categorie1=$(sed -n "1 p" $CATEGORIES_ENABLED) # on considère que si la 1ère catégorie activée est un blacklist on fonctionne par blacklist.
   is_blacklist=$(grep $categorie1 $BL_CATEGORIES_AVAILABLE |wc -l)
   if [ $is_blacklist -ge "1" ] ; then
   $SED "s?^DNSMASQ.*?DNSMASQ=BLACK?g" $FILE_CONF
cat << EOF > $DNSMASQCONF 
# Configuration file for "dnsmasq with blackhole"
# Inclusion de la blacklist <domains> de Toulouse dans la configuration
conf-dir=$DIR_DNS_BLACKLIST_ENABLED
# conf-file=$DIR_DEST_ETC/alcasar-dns-name   # zone de definition de noms DNS locaux
interface=lo
listen-address=127.0.0.1
no-dhcp-interface=$interface_WAN
bind-interfaces
cache-size=1024
domain-needed
expand-hosts
bogus-priv
port=54
server=$DNS1
server=$DNS2  
EOF

resolvconffixon # redemare dnsmasq en prenent en compte la présence ou non de resolvconf.
$DANSGOUARDIANrestart
$PRIVOXYrestart
else
  dnsmasqwhitelistonly
fi
echo "fin dnsmasqon"
}
dnsmasqoff () {
   $SED "s?^DNSMASQ.*?DNSMASQ=OFF?g" $FILE_CONF
   resolvconffixoff
   $DANSGOUARDIANrestart
$PRIVOXYrestart
}
ipMaskValide() {
ip=$(echo $1 | cut -d"/" -f1)
mask=$(echo $1 | grep "/" | cut -d"/" -f2)
if [ $(echo $1 | grep -c "^\(\(2[0-5][0-5]\|2[0-4][0-9]\|1[0-9][0-9]\|[0-9]\{1,2\}\)\.\)\{3\}\(2[0-5][0-5]\|2[0-4][0-9]\|1[0-9][0-9]\|[0-9]\{1,2\}\)$") -eq 1 ];then
	echo 1
	return 1
fi
if [ ! $(echo $ip | grep -c "^\(\(2[0-5][0-5]\|2[0-4][0-9]\|1[0-9][0-9]\|[0-9]\{1,2\}\)\.\)\{3\}\(2[0-5][0-5]\|2[0-4][0-9]\|1[0-9][0-9]\|[0-9]\{1,2\}\)$") -eq 1 ];then
	echo 0
	return 0
fi
if [ $(echo $mask | grep -c "^\([1-9]\|[1-2][0-9]\|3[0-2]\)$") -eq 1 ];then
	echo 1
	return 1
fi
i=1 
octn=255
result=1
while [ $i -le 4 ]
do
oct=$( echo $mask | grep '\.'| cut -d "." -f$i )
if [ -z $oct ] ; then
	result=0
	break
fi
if [ ! $octn -eq 255 ];then
	if [ ! $oct -eq 0 ];then
		result=0
		break
	fi
fi 
octn=$oct
if [ ! $oct -eq 255 ] &&  [ ! $oct -eq 254 ]  &&  [ ! $oct -eq 252 ] &&  [ ! $oct -eq 248 ] &&  [ ! $oct -eq 240 ] &&  [ ! $oct -eq 224 ] &&  [ ! $oct -eq 192 ] &&  [ ! $oct -eq 128 ] &&  [ ! $oct -eq 0 ]; then
	result=0
	break	
  fi
i=$( expr $i + 1 )
done
   echo $result
   return $result
}
ipglobal () {
    ### BLOQUE TOUT PAR DEFAUT (si aucune règle n'est définie par la suite) ###
    $IPTABLES -P INPUT DROP
    $IPTABLES -P OUTPUT DROP
    $IPTABLES -P FORWARD DROP
    # TCP Syn Flood
    $IPTABLES -A INPUT -i $interface_WAN -p tcp --syn -m limit --limit 3/s -j ACCEPT
    # UDP Syn Flood
    $IPTABLES -A INPUT -i $interface_WAN -p udp -m limit --limit 10/s -j ACCEPT

	### IP indésirables
 
    if [ -e $FILEIPBLACKLIST ] ;  then
	   while read ligne
	   do
		ipdrop=`echo $ligne | cut -d " " -f1`  
	    if [ $( ipMaskValide $ipdrop ) -eq 1 ] ;then
			$IPTABLES -I INPUT  -s $ipdrop -j DROP
			$IPTABLES -I OUTPUT  -d $ipdrop -j DROP
		fi
       done < $FILEIPBLACKLIST
    else
	    echo >  $FILEIPBLACKLIST
	    chown root:root  $FILEIPBLACKLIST
	    chmod 750  $FILEIPBLACKLIST
    fi
   
    ### ACCEPT ALL interface loopback ###
    $IPTABLES -A INPUT  -i lo -j ACCEPT
    $IPTABLES -A OUTPUT -o lo -j ACCEPT
    ### accepte en entrée les connexions déjà établies (en gros cela permet d'accepter 
    ### les connexions initiées par sont propre PC)
    $IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
     
    ### DHCP
    $IPTABLES -A OUTPUT -o $interface_WAN -p udp --sport 68 --dport 67 -j ACCEPT
    $IPTABLES -A INPUT -i $interface_WAN -p udp --sport 67 --dport 68 -j ACCEPT
 
    ### DNS indispensable pour naviguer facilement sur le web ###
    $IPTABLES -A OUTPUT -p tcp -m tcp --dport 53 -j ACCEPT
    $IPTABLES -A OUTPUT -p udp -m udp --dport 53 -j ACCEPT
    $IPTABLES -A OUTPUT -d 127.0.0.1 -p tcp -m tcp --dport 54 -j ACCEPT
    $IPTABLES -A OUTPUT -d 127.0.0.1 -p udp -m udp --dport 54 -j ACCEPT
 
    ### HTTP navigation internet non sécurisée ###
    $IPTABLES -A OUTPUT -p tcp -m tcp --dport 80 -j ACCEPT
    
    ### HTTPS pour le site des banques .... ###
    $IPTABLES -A OUTPUT -p tcp -m tcp --dport 443 -j ACCEPT
    
    ### ping ... autorise à "pinger" un ordinateur distant ###
    $IPTABLES -A OUTPUT -p icmp -j ACCEPT
    
    ### clientNTP ... syncro à un serveur de temps ###
    $IPTABLES -A OUTPUT -p udp -m udp --dport 123 -j ACCEPT
    
    # On autorise les requêtes FTP 
	modprobe ip_conntrack_ftp
	$IPTABLES -A OUTPUT -p tcp --dport 21 -j ACCEPT
	$IPTABLES -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	
	if [ -e $FILEIPTABLES ] ;  then
		source $FILEIPTABLES
    else
	    initfileiptables
    fi


}
initfileiptables () {
    echo >  $FILEIPTABLES
	echo '' >>  $FILEIPTABLES
	echo '## on autorise tous le trafique sortent a destination de notre lan (PC imprimente de la maison)' >>  $FILEIPTABLES
	echo '$IPTABLES -A OUTPUT -d $reseau_box -j ACCEPT ' >>  $FILEIPTABLES
	echo '## on acepte tous le trafique entrant en provenence de notre lan (PC imprimente de la maison)' >>  $FILEIPTABLES
	echo '$IPTABLES -A INPUT -s $reseau_box -j ACCEPT  ' >>  $FILEIPTABLES
    echo '' >>  $FILEIPTABLES
    echo '### smtp + pop ssl thunderbird ...  ####' >>  $FILEIPTABLES
	echo '$IPTABLES -A OUTPUT -p tcp -m tcp --dport 993 -j ACCEPT		# imap/ssl' >>  $FILEIPTABLES
	echo '$IPTABLES -A OUTPUT -p tcp -m tcp --dport 995 -j ACCEPT		# pop/ssl' >>  $FILEIPTABLES
	echo '$IPTABLES -A OUTPUT -p tcp -m tcp --dport 465 -j ACCEPT      # smtp/ssl' >>  $FILEIPTABLES
	echo '' >>  $FILEIPTABLES
	echo '# Ping Externe' >>  $FILEIPTABLES
	echo '# $IPTABLES -A INPUT -i $interface_WAN -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT' >>  $FILEIPTABLES
    echo '# $IPTABLES -A INPUT -i $interface_WAN -p icmp --icmp-type echo-reply -m limit --limit 1/s -j ACCEPT' >>  $FILEIPTABLES
	echo '' >>  $FILEIPTABLES
	echo '### cups serveur , impriment partager sous cups' >>  $FILEIPTABLES
	echo '#$IPTABLES -A OUTPUT -d $ip_broadcast -p udp -m udp --sport 631 --dport 631 -j ACCEPT # diffusion des imprimantes partager sur le réseaux' >>  $FILEIPTABLES
	echo '#$IPTABLES -A INPUT -s $reseau_box -m state --state NEW -p TCP --dport 631 -j ACCEPT' >>  $FILEIPTABLES
	echo '#$IPTABLES -I INPUT -s $ipbox -m state --state NEW -p TCP --dport 631 -j DROP # drop les requette provenent de la passerelle' >>  $FILEIPTABLES
    echo '' >>  $FILEIPTABLES
    echo '### emesene,pindgin,amsn...  ####' >>  $FILEIPTABLES
    echo '#$IPTABLES -A OUTPUT -p tcp -m tcp --dport 1863 -j ACCEPT  ' >>  $FILEIPTABLES   
	echo '#$IPTABLES -A OUTPUT -p tcp -m tcp --dport 6891:6900 -j ACCEPT # pour transfert de fichiers , webcam' >>  $FILEIPTABLES
	echo '#$IPTABLES -A OUTPUT -p udp -m udp --dport 6891:6900 -j ACCEPT # pour transfert de fichiers , webcam' >>  $FILEIPTABLES
	echo '' >>  $FILEIPTABLES
    echo '###  smtp + pop thunderbird ...  ###' >>  $FILEIPTABLES
    echo '#$IPTABLES -A OUTPUT -p tcp -m tcp --dport 25 -j ACCEPT' >>  $FILEIPTABLES
    echo '#$IPTABLES -A OUTPUT -p tcp -m tcp --dport 110 -j ACCEPT' >>  $FILEIPTABLES
    echo '### client-transmission' >>  $FILEIPTABLES
    echo '# ouvre beaucoup de ports' >>  $FILEIPTABLES
    echo '#$IPTABLES -A OUTPUT -p udp -m udp --sport 51413 --dport 1023:65535  -j ACCEPT' >>  $FILEIPTABLES
	echo '#$IPTABLES -A OUTPUT -p tcp -m tcp --sport 30000:65535 --dport 1023:65535  -j ACCEPT' >>  $FILEIPTABLES
    echo '###Ryzom' >>  $FILEIPTABLES
	echo '#srvupdateRtzom=178.33.44.72' >>  $FILEIPTABLES
	echo '#srvRyzom1=176.31.229.93' >>  $FILEIPTABLES
	echo '#$IPTABLES -A OUTPUT  -d $srvupdateRtzom -p tcp --dport 873 -j ACCEPT' >>  $FILEIPTABLES
	echo '#$IPTABLES -A OUTPUT  -d $srvRyzom1 -p tcp --dport 43434 -j ACCEPT' >>  $FILEIPTABLES
	echo '#$IPTABLES -A OUTPUT  -d $srvRyzom1 -p tcp --dport 50000 -j ACCEPT' >>  $FILEIPTABLES
	echo '#$IPTABLES -A OUTPUT  -d $srvRyzom1 -p tcp --dport 40916 -j ACCEPT' >>  $FILEIPTABLES
	echo '#$IPTABLES -A OUTPUT  -d $srvRyzom1 -p udp --dport 47851:47860 -j ACCEPT' >>  $FILEIPTABLES
	echo '#$IPTABLES -A OUTPUT  -d $srvRyzom1 -p tcp --dport 47851:47860 -j ACCEPT' >>  $FILEIPTABLES
	echo '### Regnum Online' >>  $FILEIPTABLES
    echo '#$IPTABLES -A OUTPUT  -d 91.123.197.131 -p tcp --dport 47300 -j ACCEPT # autentification' >>  $FILEIPTABLES
	echo '#$IPTABLES -A OUTPUT  -d 91.123.197.142 -p tcp --dport 48000:48002  -j ACCEPT # nemon' >>  $FILEIPTABLES
    echo '### NeverWinter Nights 1' >>  $FILEIPTABLES
    echo '#$IPTABLES -A OUTPUT  -p udp --dport 5120:5121 -j ACCEPT' >>  $FILEIPTABLES
    echo "#\$IPTABLES -I OUTPUT  -d 204.50.199.9 -j DROP # nwmaster.bioware.com permet d'éviter le temps d'attente avant l'ouverture du multijoueur " >>  $FILEIPTABLES
    echo '### LandesEternelles' >>  $FILEIPTABLES
    echo '#$IPTABLES -A OUTPUT  -d 62.93.225.45 -p tcp --dport 3000 -j ACCEPT' >>  $FILEIPTABLES
    echo '### Batel for Wesnoth' >>  $FILEIPTABLES
    echo '#14998 pour version stable.' >>  $FILEIPTABLES
    echo '#14999 pour version stable précédente.' >>  $FILEIPTABLES
    echo '#15000 pour version de dévelopement.' >>  $FILEIPTABLES
    echo '#15001 télécharger addons' >>  $FILEIPTABLES
    echo '#$IPTABLES -A OUTPUT  -d 65.18.193.12 -p tcp --sport 1023:65535 --dport 14998:15001 -j ACCEPT' >>  $FILEIPTABLES
    echo '#$IPTABLES -A INPUT   -p tcp --sport 1023:65535 --dport 15000 -j ACCEPT' >>  $FILEIPTABLES
	chown root:root  $FILEIPTABLES
	chmod 750  $FILEIPTABLES
	
}

iptablesreload () {
	echo "iptablesreload"
   ### SUPPRESSION de TOUTES LES ANCIENNES TABLES (OUVRE TOUT!!) ###
   $IPTABLES -F
   $IPTABLES -X
   $IPTABLES -t nat -D OUTPUT -j ctparental 2> /bin/null
   $IPTABLES -t nat -F ctparental  2> /bin/null
   $IPTABLES -t nat -X ctparental  2> /bin/null
   $IPTABLES -P INPUT ACCEPT
   $IPTABLES -P OUTPUT ACCEPT
   $IPTABLES -P FORWARD ACCEPT
   if [ ! $FILTRAGEISOFF -eq 1 ];then
	 $IPTABLES -t nat -N ctparental
     $IPTABLES -t nat -A OUTPUT -j ctparental
      
      # Force privoxy a utiliser dnsmasq sur le port 54
	  $IPTABLES -t nat -A ctparental -m owner --uid-owner "$PROXYuser" -p udp --dport 53 -j DNAT --to 127.0.0.1:54
	  
	  # on interdit l'accès a bing en https .
	  ipbing=$(cat $DIR_DNS_BLACKLIST_ENABLED/forcesafesearch.conf | grep "address=/.bing.com/" | cut -d "/" -f3)
	  $IPTABLES -A OUTPUT -d $ipbing -m owner --uid-owner "$PROXYuser" -p tcp --dport 443 -j REJECT # on rejet l'acces https a bing
	  
	  for ipdailymotion in $(host -ta dailymotion.com|cut -d" " -f4)  
	  do 
		$IPTABLES -A OUTPUT -d $ipdailymotion -m owner --uid-owner "$PROXYuser" -p tcp --dport 443 -j REJECT # on rejet l'acces https a dailymotion.com
	  done

      for user in `listeusers` ; do
      if  [ $(groups $user | grep -c -E "( ctoff$)|( ctoff )" ) -eq 0 ];then
         #on rediriges les requet DNS des usagers filtrés sur dnsmasq
         $IPTABLES -t nat -A ctparental -m owner --uid-owner "$user" -p tcp --dport 53 -j DNAT --to 127.0.0.1:54 
         $IPTABLES -t nat -A ctparental -m owner --uid-owner "$user" -p udp --dport 53 -j DNAT --to 127.0.0.1:54
         #force passage par dansgourdian pour les utilisateurs filtrés 
		 $IPTABLES -t nat -A ctparental ! -d 127.0.0.1/8 -m owner --uid-owner "$user" -p tcp --dport 80 -j DNAT --to 127.0.0.1:$DANSGport
		 $IPTABLES -t nat -A ctparental ! -d 127.0.0.1/8 -m owner --uid-owner "$user" -p tcp --dport $PROXYport -j DNAT --to 127.0.0.1:$DANSGport
		 #$IPTABLES -t nat -A ctparental -m owner --uid-owner "$user" -p tcp --dport 443 -j DNAT --to 127.0.0.1:$DANSGport  # proxy https transparent n'est pas possible avec privoxy
		 $IPTABLES -A OUTPUT ! -d 127.0.0.1/8 -m owner --uid-owner "$user" -p tcp --dport 443 -j REJECT # on interdit l'aces https sans passer par le proxy pour les utilisateur filtré.	
      fi
      done
   fi

   if [ $(cat $FILE_CONF | grep -c IPRULES=ON ) -eq 1 ];then
    ipglobal
   fi
### LOG ### Log tout ce qui qui n'est pas accepté par une règles précédente
$IPTABLES -A OUTPUT -j LOG  --log-prefix "iptables: "
$IPTABLES -A INPUT -j LOG   --log-prefix "iptables: "
$IPTABLES -A FORWARD -j LOG  --log-prefix "iptables: "

# Save configuration so that it survives a reboot
   $IPTABLESsave
   
updatecauser
setproxy
echo "fin iptablesreload"
}
updatecauser () {
echo "updatecauser"
for user in `listeusers` ; do	
	HOMEPCUSER=$(getent passwd "$user" | cut -d ':' -f6)
	if [ -d $HOMEPCUSER ] ;then
			#on install le certificat dans tous les prifile firefoxe utilisateur existant 
		for profilefirefox in $(cat $HOMEPCUSER/.mozilla/firefox/profiles.ini | grep Path= | cut -d"=" -f2) ; do
			# on supprime tous les anciens certificats
			while true
			do
				certutil -D -d $HOMEPCUSER/.mozilla/firefox/$profilefirefox/ -n"CActparental - ctparental" 2&> /dev/null
				if [ ! $? -eq 0 ];then 
					break
				fi
			done
			# on ajoute le nouveau certificat
			certutil -A -d $HOMEPCUSER/.mozilla/firefox/$profilefirefox/ -i $DIRHTML/cactparental.crt -n"CActparental - ctparental" -t "CT,c,c"		
		done
	fi
done
echo "fin updatecauser"
}
iptablesoff () {

   $IPTABLES -F
   $IPTABLES -X
   $IPTABLES -P INPUT ACCEPT
   $IPTABLES -P OUTPUT ACCEPT
   $IPTABLES -P FORWARD ACCEPT
   $IPTABLES -t nat -D OUTPUT -j ctparental  2> /bin/null
   $IPTABLES -t nat -F ctparental  2> /bin/null
   $IPTABLES -t nat -X ctparental  2> /bin/null
   $IPTABLESsave
   unsetproxy
}
dnsmasqwhitelistonly  () {
   $SED "s?^DNSMASQ.*?DNSMASQ=WHITE?g" $FILE_CONF
   cat << EOF > $DNSMASQCONF
         # Configuration file for "dnsmasq with blackhole"
   # Inclusion de la blacklist <domains> de Toulouse dans la configuration
   conf-dir=$DIR_DNS_WHITELIST_ENABLED
   # conf-file=$DIR_DEST_ETC/alcasar-dns-name   # zone de definition de noms DNS locaux
   no-dhcp-interface=$interface_WAN
   bind-interfaces
   cache-size=0
   domain-needed
   expand-hosts
   bogus-priv
   server=$DNS1
   server=$DNS2
   address=/localhost/127.0.0.1
   address=/#/$PRIVATE_IP #redirige vers $PRIVATE_IP pour tout ce qui n'a pas été resolu dans les listes blanches
EOF

$DNSMASQrestart
$DANSGOUARDIANrestart
$PRIVOXYrestart
}


FoncHTTPDCONF () {
echo "FoncHTTPDCONF"
$LIGHTTPDstop
rm -rf $DIRHTML/*
mkdir $DIRHTML 2> /dev/null
if [ ! -z $DIRhtmlPersonaliser ];then
   cp -r $DIRhtmlPersonaliser/* $DIRHTML
else
s="span"
st="style"
c="$c"
cab=";\">"

cat << EOF > $DIRHTML/index.html
 <HTML>
<HEAD>
   <META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=utf-8">
   <TITLE>danger</TITLE>
</HEAD>
<BODY LANG="fr-FR" DIR="LTR">
<CENTER>
<img alt="Site dangereux pour des mineurs boquer par dnsmasq"
  HEIGHT="600"   
  src="data:image/png;base64,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
QmCC" />
</CENTER>
</BODY>
</HTML>
EOF
#<br><a href="http://localhost/CTparental/cactparental.crt">Installer le certificat racine de CTparental</a><br>
fi
## GENERATION

cat $DIRHTML/index.html > /etc/dansguardian/languages/french/template.html
$SED "s/dnsmasq/dansguardian/g"  /etc/dansguardian/languages/french/template.html  

ln -s  $DIRHTML/index.html $DIRHTML/err404.html
USERHTTPD=$(cat /etc/passwd | grep /var/www | cut -d":" -f1)
GROUPHTTPD=$(cat /etc/group | grep $USERHTTPD | cut -d":" -f1)
chmod 644 $FILE_CONF
chown root:$GROUPHTTPD $FILE_CONF
cat << EOF > $MAINCONFHTTPD
server.modules = (
"mod_access",
"mod_alias",
"mod_redirect",
"mod_auth",	#pour interface admin
"mod_fastcgi",  #pour interface admin (activation du php)
)
auth.debug                 = 0
auth.backend               = "htdigest" 
auth.backend.htdigest.userfile = "$PASSWORDFILEHTTPD" 

server.document-root = "/var/www"
server.upload-dirs = ( "/var/cache/lighttpd/uploads" )
#server.errorlog = "/var/log/lighttpd/error.log" # ne pas decommenter sur les eeepc qui on /var/log  en tmpfs
server.pid-file = "$LIGHTTPpidfile"
server.username = "$USERHTTPD"
server.groupname = "$GROUPHTTPD"
server.port = 80
server.bind = "127.0.0.1"


index-file.names = ( "index.php", "index.html" )
url.access-deny = ( "~", ".inc" )
static-file.exclude-extensions = (".php", ".pl", ".fcgi" )

server.tag = ""

include_shell "/usr/share/lighttpd/create-mime.assign.pl"
include_shell "/usr/share/lighttpd/include-conf-enabled.pl"
EOF

mkdir -p /usr/share/lighttpd/

if [ ! -f /usr/share/lighttpd/create-mime.assign.pl ];then
cat << EOF > /usr/share/lighttpd/create-mime.assign.pl
#!/usr/bin/perl -w
use strict;
open MIMETYPES, "/etc/mime.types" or exit;
print "mimetype.assign = (\n";
my %extensions;
while(<MIMETYPES>) {
  chomp;
  s/\#.*//;
  next if /^\w*$/;
  if(/^([a-z0-9\/+-.]+)\s+((?:[a-z0-9.+-]+[ ]?)+)$/) {
    foreach(split / /, \$2) {
      # mime.types can have same extension for different
      # mime types
      next if \$extensions{\$_};
      \$extensions{\$_} = 1;
      print "\".\$_\" => \"\$1\",\n";
    }
  }
}
print ")\n";
EOF
chmod +x /usr/share/lighttpd/create-mime.assign.pl
fi


if [ ! -f /usr/share/lighttpd/include-conf-enabled.pl ];then
cat << EOF > /usr/share/lighttpd/include-conf-enabled.pl
#!/usr/bin/perl -wl

use strict;
use File::Glob ':glob';

my \$confdir = shift || "/etc/lighttpd/";
my \$enabled = "conf-enabled/*.conf";

chdir(\$confdir);
my @files = bsd_glob(\$enabled);

for my \$file (@files)
{
        print "include \"\$file\"";
}
EOF
chmod +x /usr/share/lighttpd/include-conf-enabled.pl 

fi

mkdir -p $DIRCONFENABLEDHTTPD
mkdir -p $DIRadminHTML
cp -rf CTadmin/* $DIRadminHTML/

### configuration du login mot de passe de l'interface d'administration
if [ $nomanuel -eq 0 ]; then  
	configloginpassword
else
	## variable récupérer par éritage du script DEBIAN/postinst
	addadminhttpd "$debconfloginhttp" "$debconfpassword"
	unset debconfpassword
	unset debconfloginhttp
fi



chmod 700 /root/passwordCTadmin
chown root:root /root/passwordCTadmin
mkdir /run/lighttpd/ 2> /dev/null
chmod 770 /run/lighttpd/
chown root:$GROUPHTTPD /run/lighttpd/
cat << EOF > $CTPARENTALCONFHTTPD

fastcgi.server = (
    ".php" => (
      "localhost" => ( 
        "bin-path" => "/usr/bin/php-cgi",
        "socket" => "/run/lighttpd/php-fastcgi.sock",
        "max-procs" => 4, # default value
        "bin-environment" => (
          "PHP_FCGI_CHILDREN" => "1", # default value
        ),
        "broken-scriptfilename" => "enable"
      ))
)
  fastcgi.map-extensions     = ( ".php3" => ".php",
                               ".php4" => ".php",
                               ".php5" => ".php",
                               ".phps" => ".php",
                               ".phtml" => ".php" )

\$HTTP["url"] =~ ".*CTadmin.*" {
  auth.require = ( "" =>
                   (
                     "method"  => "digest",
                     "realm"   => "$REALMADMINHTTPD",
                     "require" => "user=$USERADMINHTTPD" 
                   )
                 )

}


\$HTTP["host"] =~ "search.yahoo.com" {
	\$SERVER["socket"] == ":443" {
	ssl.engine = "enable"
	ssl.pemfile = "$PEMSRVDIR/search.yahoo.com.pem" 
	server.document-root = "$DIRHTML"
	server.errorfile-prefix = "$DIRHTML/err" 
	}
}

\$HTTP["host"] =~ "localhost" {
	\$SERVER["socket"] == ":443" {
	ssl.engine = "enable"
	ssl.pemfile = "$PEMSRVDIR/localhost.pem" 	
	}
}
\$HTTP["host"] =~ "duckduckgo.com" {
	\$SERVER["socket"] == ":443" {
	ssl.engine = "enable"
	ssl.pemfile = "$PEMSRVDIR/duckduckgo.pem" 
	url.redirect  = (".*" => "https://safe.duckduckgo.com\$0" )
	}
	\$SERVER["socket"] == "127.0.0.1:80" {
	url.redirect  = (".*" => "https://safe.duckduckgo.com\$0" )
	}
}

\$SERVER["socket"] == "$PRIVATE_IP:80" {
server.document-root = "$DIRHTML"
server.errorfile-prefix = "$DIRHTML/err" 
}

EOF



chown root:$GROUPHTTPD $DREAB
chmod 660 $DREAB
chown root:$GROUPHTTPD $DNS_FILTER_OSSI
chmod 660 $DNS_FILTER_OSSI
chown root:$GROUPHTTPD $CATEGORIES_ENABLED
chmod 660 $CATEGORIES_ENABLED
chmod 660 /etc/sudoers

sudotest=`grep Defaults:$USERHTTPD /etc/sudoers |wc -l`
if [ $sudotest -ge "1" ] ; then
    $SED "s?^Defaults:$USERHTTPD.*requiretty.*?Defaults:$USERHTTPD     \!requiretty?g" /etc/sudoers
else
    echo "Defaults:$USERHTTPD     !requiretty" >> /etc/sudoers
fi

sudotest=`grep "$USERHTTPD ALL=" /etc/sudoers |wc -l`
if [ $sudotest -ge "1" ] ; then
    $SED "s?^$USERHTTPD.*?$USERHTTPD ALL=(ALL) NOPASSWD:/usr/local/bin/CTparental.sh -gctalist,/usr/local/bin/CTparental.sh -gctulist,/usr/local/bin/CTparental.sh -gcton,/usr/local/bin/CTparental.sh -gctoff,/usr/local/bin/CTparental.sh -tlu,/usr/local/bin/CTparental.sh -trf,/usr/local/bin/CTparental.sh -dble,/usr/local/bin/CTparental.sh -ubl,/usr/local/bin/CTparental.sh -dl,/usr/local/bin/CTparental.sh -on,/usr/local/bin/CTparental.sh -off,/usr/local/bin/CTparental.sh -aupon,/usr/local/bin/CTparental.sh -aupoff?g" /etc/sudoers
else
    echo "$USERHTTPD ALL=(ALL) NOPASSWD:/usr/local/bin/CTparental.sh -gctalist,/usr/local/bin/CTparental.sh -gctulist,/usr/local/bin/CTparental.sh -gcton,/usr/local/bin/CTparental.sh -gctoff,/usr/local/bin/CTparental.sh -tlu,/usr/local/bin/CTparental.sh -trf,/usr/local/bin/CTparental.sh -dble,/usr/local/bin/CTparental.sh -ubl,/usr/local/bin/CTparental.sh -dl,/usr/local/bin/CTparental.sh -on,/usr/local/bin/CTparental.sh -off,/usr/local/bin/CTparental.sh -aupon,/usr/local/bin/CTparental.sh -aupoff" >> /etc/sudoers
fi
	

sudotest=`grep %ctoff /etc/sudoers |wc -l`		
if [ $sudotest -ge "1" ] ; then	
   $SED "s?^%ctoff.*?%ctoff ALL=(ALL) NOPASSWD:/usr/local/bin/CTparental.sh -off,/usr/local/bin/CTparental.sh -on?g" /etc/sudoers
else
   echo "%ctoff ALL=(ALL) NOPASSWD:/usr/local/bin/CTparental.sh -off,/usr/local/bin/CTparental.sh -on"  >> /etc/sudoers
fi
sudotest=`grep "ALL  ALL=(ALL) NOPASSWD:/usr/local/bin/CTparental.sh" /etc/sudoers |wc -l`		
if [ $sudotest -ge "1" ] ; then	
	$SED "s?^ALL  ALL=(ALL) NOPASSWD:/usr/local/bin/CTparental.sh.*?ALL  ALL=(ALL) NOPASSWD:/usr/local/bin/CTparental.sh -on?g" /etc/sudoers
else
	echo "ALL  ALL=(ALL) NOPASSWD:/usr/local/bin/CTparental.sh -on" >> /etc/sudoers
fi
unset sudotest
    
chmod 440 /etc/sudoers
if [ ! -f $FILE_HCONF ] ; then 
	echo > $FILE_HCONF 
fi
chown root:$GROUPHTTPD $FILE_HCONF
chmod 660 $FILE_HCONF
if [ -f $FILE_GCTOFFCONF ] ; then 
	chown root:$GROUPHTTPD $FILE_GCTOFFCONF
	chmod 660 $FILE_GCTOFFCONF
fi

if [ ! -f $FILE_HCOMPT ] ; then
	echo "date=$(date +%D)" > $FILE_HCOMPT
fi
chown root:$GROUPHTTPD $FILE_HCOMPT
chmod 660 $FILE_HCOMPT

chown -R root:$GROUPHTTPD $DIRHTML
chown -R root:$GROUPHTTPD $DIRadminHTML
CActparental
$LIGHTTPDstart
test=$?
if [ ! $test -eq 0 ];then
	echo "Erreur au lancement du service lighttpd "
	set -e
	exit 1
fi
echo "fin FoncHTTPDCONF"
}
configloginpassword () {
PTNlogin='^[a-zA-Z0-9]*$'
while (true)
do
     
	loginhttp=$(whiptail --title "Login" --nocancel --inputbox "Entrer le login pour l'interface d'administration 
- que des lètres ou des chifres .
- 6 carratères minimum :" 10 60 3>&1 1>&2 2>&3)			
	if [ $(expr $loginhttp : $PTNlogin) -gt 6  ];then 
		break
	fi	

done
while (true)
do
password=$(whiptail --title "Mot de passe" --nocancel --passwordbox "Entrer votre mot de passe pour $loginhttp et valider par Ok pour continuer." 10 60 3>&1 1>&2 2>&3)
		password2=$(whiptail --title "Mot de passe" --nocancel --passwordbox "Confirmez votre mot de passe pour $loginhttp et valider par Ok pour continuer." 10 60 3>&1 1>&2 2>&3)
		if [ $password = $password2 ] ; then
			
			if [ $(echo $password | grep -E [a-z] | grep -E [0-9] | grep -E [A-Z] | grep -E '[&éè~#{}()ç_@à?.;:/!,$<>=£%]' | wc -c ) -ge 8 ] ; then
				break
			else
				whiptail --title "Mot de passe" --msgbox "Mot de pass n'est pas asser complex, il doit comptenir au moins:
- 8 carataire aux total,1 Majuscule,1 minuscule,1 nombre
et 1 caractaire spéciale parmis les suivants &éè~#{}()ç_@à?.;:/!,$<>=£% " 14 60 
			fi
		else
		    whiptail --title "Mot de passe" --msgbox "Le mot de pass rentré n'est pas identique au premier." 14 60 
				
		fi

done
addadminhttpd "$loginhttp" "$password"
}
CActparental () {
echo "CActparental"
DIR_TMP=${TMPDIR-/tmp}/ctparental-mkcert.$$
mkdir $DIR_TMP
mkdir $CADIR 2> /dev/null

## création de la clef priver ca et du certificat ca
openssl genrsa  1024 > $DIR_TMP/cactparental.key 2> /dev/null
openssl req -new -x509 -subj "/C=FR/ST=FRANCE/L=ici/O=ctparental/CN=CActparental" -days 10000 -key $DIR_TMP/cactparental.key > $DIR_TMP/cactparental.crt 

## création de la clef privée serveur localhost
openssl genrsa 1024 > $DIR_TMP/localhost.key 2> /dev/null
## création certificat localhost et signature par la ca
openssl req -new -subj "/C=FR/ST=FRANCE/L=ici/O=ctparental/CN=localhost" -key $DIR_TMP/localhost.key > $DIR_TMP/localhost.csr 
openssl x509 -req -in $DIR_TMP/localhost.csr -out $DIR_TMP/localhost.crt -CA $DIR_TMP/cactparental.crt -CAkey $DIR_TMP/cactparental.key -CAcreateserial -CAserial $DIR_TMP/ca.srl  

## création du certificat duckduckgo pour redirection vers safe.duckduckgo.com
openssl genrsa 1024 > $DIR_TMP/duckduckgo.key 2> /dev/null
openssl req -new -subj "/C=FR/ST=FRANCE/L=ici/O=ctparental/CN=duckduckgo.com" -key $DIR_TMP/duckduckgo.key > $DIR_TMP/duckduckgo.csr 
openssl x509 -req -in $DIR_TMP/duckduckgo.csr -out $DIR_TMP/duckduckgo.crt -CA $DIR_TMP/cactparental.crt -CAkey $DIR_TMP/cactparental.key -CAserial $DIR_TMP/ca.srl 

## création du certificat search.yahoo.com pour redirection vers pages d'interdiction
openssl genrsa 1024 > $DIR_TMP/search.yahoo.com.key 2> /dev/null
openssl req -new -subj "/C=FR/ST=FRANCE/L=ici/O=ctparental/CN=search.yahoo.com" -key $DIR_TMP/search.yahoo.com.key > $DIR_TMP/search.yahoo.com.csr 
openssl x509 -req -in $DIR_TMP/search.yahoo.com.csr -out $DIR_TMP/search.yahoo.com.crt -CA $DIR_TMP/cactparental.crt -CAkey $DIR_TMP/cactparental.key -CAserial $DIR_TMP/ca.srl 

## instalation de la CA dans les ca de confiance.
cp -f $DIR_TMP/cactparental.crt $CADIR/
cp -f $DIR_TMP/cactparental.crt $DIRHTML
cp -f $DIR_TMP/cactparental.crt $REPCAMOZ
## instalation des certificats serveur
cat $DIR_TMP/localhost.key $DIR_TMP/localhost.crt > $PEMSRVDIR/localhost.pem
cat $DIR_TMP/duckduckgo.key $DIR_TMP/duckduckgo.crt > $PEMSRVDIR/duckduckgo.pem
cat $DIR_TMP/search.yahoo.com.key $DIR_TMP/search.yahoo.com.crt > $PEMSRVDIR/search.yahoo.com.pem
rm -rf $DIR_TMP

updatecauser
echo "fin CActparental"
}


install () {
	iptablesoff
	groupadd ctoff
	unset https_proxy
	unset HTTPS_PROXY
	unset http_proxy
	unset HTTP_PROXY
	if [ $nomanuel -eq 0 ]; then 
		vim -h 2&> /dev/null
		if [ $? -eq 0 ] ; then
		EDIT="vim "
		fi
		nano -h 2&> /dev/null
		if [ $? -eq 0 ] ; then
		EDIT=${EDIT:="nano "}
		fi
		vi -h 2&> /dev/null
		if [ $? -eq 0 ] ; then
			EDIT=${EDIT:="vi "}
		fi
	
		if [ -f gpl-3.0.fr.txt ] ; then
			cp -f gpl-3.0.fr.txt /usr/local/share/CTparental/
		fi
		if [ -f gpl-3.0.txt ] ; then
			cp -f gpl-3.0.txt /usr/local/share/CTparental/
		fi
		if [ -f CHANGELOG ] ; then
			cp -f CHANGELOG /usr/local/share/CTparental/
		fi
		if [ -f dist.conf ];then
			cp -f dist.conf /usr/local/share/CTparental/dist.conf.orig
			cp -f dist.conf $DIR_CONF/
		fi
		while (true); do
		$EDIT $DIR_CONF/dist.conf
		clear
		cat  $DIR_CONF/dist.conf | grep -v -E ^# | grep -v ^$
		echo "Entrer : S pour continuer avec ces parramêtres ."
		echo "Entrer : Q pour Quiter l'installation."
		echo "Entrer tous autre choix pour modifier les parramêtres."
		 read choi
		case $choi in
			 S | s )
				break
			;;
			 Q | q )
				exit
			;;
			esac
		done
			
	fi
	if [ -f $DIR_CONF/dist.conf ];then
		source  $DIR_CONF/dist.conf 
	fi

	if [ -f /etc/NetworkManager/NetworkManager.conf ];then
    		 $SED "s/^dns=dnsmasq/#dns=dnsmasq/g" /etc/NetworkManager/NetworkManager.conf
    		 $NWMANAGERrestart
     		sleep 5
   	fi

      mkdir $tempDIR
      mkdir -p $DIR_CONF
      initblenabled
      cat /etc/resolv.conf > $DIR_CONF/resolv.conf.sav
      if [ $noinstalldep = "0" ]; then
	  for PACKAGECT in $CONFLICTS
         do
			$CMDREMOVE $PACKAGECT 2> /dev/null
         done
	  fi
      if [ $noinstalldep = "0" ]; then
	      $CMDINSTALL $DEPENDANCES
      fi
      # on desactive l'ipv6
		test=`grep net.ipv6.conf.all.disable_ipv6= /etc/sysctl.conf |wc -l`
		if [ $test -ge "1" ] ; then
			$SED "s?^net.ipv6.conf.all.disable_ipv6=.*?net.ipv6.conf.all.disable_ipv6=1?g" /etc/sysctl.conf
		else
			echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
		fi
		unset test
		test=`grep net.ipv6.conf.default.disable_ipv6= /etc/sysctl.conf |wc -l`
		if [ $test -ge "1" ] ; then
			$SED "s?^net.ipv6.conf.default.disable_ipv6=.*?net.ipv6.conf.default.disable_ipv6=1?g" /etc/sysctl.conf
		else
			echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
		fi
		unset test
				unset test
		test=`grep net.ipv6.conf.lo.disable_ipv6= /etc/sysctl.conf |wc -l`
		if [ $test -ge "1" ] ; then
			$SED "s?^net.ipv6.conf.lo.disable_ipv6=.*?net.ipv6.conf.lo.disable_ipv6=1?g" /etc/sysctl.conf
		else
			echo "net.ipv6.conf.lo.disable_ipv6=1" >> /etc/sysctl.conf
		fi
		unset test
		sysctl -w
      ######################
      # on charge le(s) module(s) indispensable(s) pour iptables.
		test=`grep ip_conntrack_ftp $FILEMODULESLOAD |wc -l`
		if [ $test -ge "1" ] ; then
			$SED "s?.*ip_conntrack_ftp.*?#ip_conntrack_ftp?g" $FILEMODULESLOAD
		else
			echo "#ip_conntrack_ftp" >> $FILEMODULESLOAD
		fi
		modprobe ip_conntrack_ftp	
		$SED "s?.*ip_conntrack_ftp.*?ip_conntrack_ftp?g" $FILEMODULESLOAD 
		echo ':msg,contains,"iptables" /var/log/iptables.log' > $RSYSLOGCTPARENTAL 
		echo '& ~' >> $RSYSLOGCTPARENTAL 
	  #######################
      
      if [ ! -f blacklists.tar.gz ]
      then
         download
      else
         tar -xzf blacklists.tar.gz -C $tempDIR
         if [ ! $? -eq 0 ]; then
            echo "Erreur d'extraction de l'archive, processus interrompu"
            uninstall
            set -e
            exit 1
         fi
         rm -rf $DIR_DNS_FILTER_AVAILABLE/
         mkdir $DIR_DNS_FILTER_AVAILABLE
      fi
      adapt
      catChoice
      dnsmasqon
      $SED "s?^LASTUPDATE.*?LASTUPDATE=$THISDAYS=`date +%d-%m-%Y\ %T`?g" $FILE_CONF
	  confdansguardian
	  confprivoxy
      FoncHTTPDCONF
      activegourpectoff
      iptablesreload
      $ENCRON
      $ENLIGHTTPD
      $ENDNSMASQ
      $ENNWMANAGER
      $ENIPTABLESSAVE
    
}


updatelistgctoff () {
	result="0"
	if [ ! -f $FILE_GCTOFFCONF ] ; then 
		echo -n > $FILE_GCTOFFCONF
	fi
	## on ajoute tous les utilisateurs manquants dans la liste
	for PCUSER in `listeusers`
	do
		if [ $(cat $FILE_GCTOFFCONF | sed -e "s/#//g" | grep -c -E "^$PCUSER$") -eq 0 ];then
			result="1"
			echo "#$PCUSER" >> $FILE_GCTOFFCONF
		fi
	done
	## on supprime tout ceux qui n'existent plus sur le pc.
	for PCUSER in $(cat $FILE_GCTOFFCONF | sed -e "s/#//g" )
	do
		if [ $( listeusers | grep -c -E "^$PCUSER$") -eq 0 ];then
			result="1"
			$SED "/^$PCUSER$/d" $FILE_GCTOFFCONF
			$SED "/^#$PCUSER$/d" $FILE_GCTOFFCONF
		fi
	done
	echo $result
	
}
applistegctoff () {
		$ADDUSERTOGROUP root ctoff 2> /dev/null
		for PCUSER in $(cat $FILE_GCTOFFCONF )
		do
			if [ $(echo $PCUSER | grep -c -v "#") -eq 1 ];then
				$ADDUSERTOGROUP $PCUSER ctoff 2> /dev/null
			else
				$DELUSERTOGROUP $(echo $PCUSER | sed -e "s/#//g" ) ctoff 2> /dev/null
			fi
		done 
	

}

activegourpectoff () {
echo "activegourpectoff"
   groupadd ctoff
   $SED "s?^GCTOFF.*?GCTOFF=ON?g" $FILE_CONF
   updatelistgctoff
   applistegctoff
   USERHTTPD=$(cat /etc/passwd | grep /var/www | cut -d":" -f1)
   GROUPHTTPD=$(cat /etc/group | grep $USERHTTPD | cut -d":" -f1)
   chown root:$GROUPHTTPD $FILE_GCTOFFCONF
   chmod 660 $FILE_GCTOFFCONF
   echo "PATH=$PATH"  > /etc/cron.d/CTparentalupdateuser
   echo "*/1 * * * * root /usr/local/bin/CTparental.sh -ucto" >> /etc/cron.d/CTparentalupdateuser
   $CRONrestart
echo "fin activegourpectoff"
}

desactivegourpectoff () {
   groupdel ctoff 2> /dev/null
   $SED "s?^GCTOFF.*?GCTOFF=OFF?g" $FILE_CONF
}

uninstall () {
   # On force la désinstall par dpkg ou rpm si l'install a était effectuer par un paquage.
   if [ $nomanuel -eq 0 ]; then 
	   muninstall="Une install par paquet a était détecter veuiller utiliser cette commande pour désinstaller ctparental."
	   if [ $(dpkg -l ctparental | grep -c ^i) -eq 1 ] ;then
			echo "$muninstall"
			echo "$CMDREMOVE ctparental"
			exit 0
	   fi
	   if [ $(rpm -q -a | grep ctparental ) -eq 1 ] ;then
			echo $muninstall
			echo "$CMDREMOVE ctparental"
			exit 0
	   fi
   fi
   autoupdateoff 
   dnsmasqoff
   desactivetimelogin
   iptablesoff
   desactivegourpectoff
   $LIGHTTPDstop
   $DNSMASQstop
   if [ $nomanuel -eq 1 ]; then 
	   # en install par le deb on n'efface pas les fichiers installer par celuis si
       rm -f /etc/cron.d/CTparental*
       rm -rf $DIRHTML
       rm -rf /usr/local/share/CTparental
       for file in $(ls $DIR_CONF | grep -v dist.conf)
       do
		  rm -rf $DIR_CONF/$(ls $DIR_CONF | grep -v dist.conf)
       done
       
   else 
       rm -f /etc/cron.d/CTparental*
       rm -rf $DIRadminHTML
       rm -rf $DIRHTML
       rm -rf /usr/local/share/CTparental
       rm -rf $DIR_CONF
   fi
   
   rm -rf $tempDIR
   rm -rf /usr/share/lighttpd/*
   rm -f $CTPARENTALCONFHTTPD
   if [ -f /etc/NetworkManager/NetworkManager.conf ];then
	$SED "s/^#dns=dnsmasq/dns=dnsmasq/g" /etc/NetworkManager/NetworkManager.conf
	$NWMANAGERrestart
  	sleep 5
   fi

   if [ $noinstalldep = "0" ]; then
	 for PACKAGECT in $DEPENDANCES
         do
			
			$CMDREMOVE $PACKAGECT 2> /dev/null
         done
   fi
   # desactivation du modules ip_conntrack_ftp
	test=`grep ip_conntrack_ftp $FILEMODULESLOAD |wc -l`
	if [ $test -ge "1" ] ; then
		$SED "s?.*ip_conntrack_ftp.*?#ip_conntrack_ftp?g" $FILEMODULESLOAD
	else
		echo "#ip_conntrack_ftp" >> $FILEMODULESLOAD
	fi
	modprobe -r ip_conntrack_ftp	
	$SED "s?.*ip_conntrack_ftp.*?#ip_conntrack_ftp?g" $FILEMODULESLOAD
	###

   rm -f $PEMSRVDIR/localhost.pem
   rm -f $PEMSRVDIR/duckduckgo.pem
   rm -f $CADIR/cactparental.crt
   rm -f $REPCAMOZ/cactparental.crt
   for user in `listeusers` ; do	
		HOMEPCUSER=$(getent passwd "$user" | cut -d ':' -f6)
		if [ -d $HOMEPCUSER ];then
			#on desinstall le certificat dans tous les prifiles firefoxe utilisateur existant 
			for profilefirefox in $(cat $HOMEPCUSER/.mozilla/firefox/profiles.ini | grep Path= | cut -d"=" -f2) ; do
				#firefox iceweachel
				# on supprime tous les anciens certificats
				while true
				do
					certutil -D -d $HOMEPCUSER/.mozilla/firefox/$profilefirefox/ -n"CActparental - ctparental" 2&> /dev/null
					if [ ! $? -eq 0 ];then 
						break
					fi
				done
			done
		fi
   done
   unsetproxy
}

choiblenabled () {
echo -n > $CATEGORIES_ENABLED
clear
echo "Voulez-vous filtrer par Blacklist ou Whitelist :"
echo -n " B/W :"
while (true); do
         read choi
         case $choi in
         B | b )
         echo "Vous allez maintenant choisir les \"Black listes\" à appliquer."
		for CATEGORIE in `cat  $BL_CATEGORIES_AVAILABLE`  # pour chaque catégorie
		do   
		      clear
		      echo "Voulez vous activer la categorie :"
		      echo -n "$CATEGORIE  O/N :"
		      while (true); do
			 read choi
			 case $choi in
			 O | o )
			 echo $CATEGORIE >> $CATEGORIES_ENABLED
			 break
			 ;;
			 N | n )
			 break
			 ;;
		      esac
		      done
		done
         break
         ;;
         W | w )
         echo "Vous allez maintenant choisir les \"White listes\" à appliquer."
		for CATEGORIE in `cat  $WL_CATEGORIES_AVAILABLE`  # pour chaque catégorie
		do   
		      clear
		      echo "Voulez vous activer la categorie :"
		      echo -n "$CATEGORIE  O/N :"
		      while (true); do
			 read choi
			 case $choi in
			 O | o )
			 echo $CATEGORIE >> $CATEGORIES_ENABLED
			 break
			 ;;
			 N | n )
			 break
			 ;;
		      esac
		      done
		done
         break
         ;;
      esac
done
}


errortime1 () {
clear
echo -e "L'heure de début doit être strictement inférieure  à l'heure de fin: $RougeD$input$Fcolor "
echo "exemple: 08h00 à 23h59 ou 08h00 à 12h00 et 14h00 à 23h59"
echo -e -n "$RougeD$PCUSER$Fcolor est autorisé à se connecter le $BleuD${DAYS[$NumDAY]}$Fcolor de :"
}
errortime2 () {
clear
echo -e "Mauvaise syntaxe: $RougeD$input$Fcolor "
echo "exemple: 08h00 à 23h59 ou 08h00 à 12h00 et 14h00 à 23h59"
echo -e -n "$RougeD$PCUSER$Fcolor est autorisé à se connecter le $BleuD${DAYS[$NumDAY]}$Fcolor de :"
}


timecronalert () {
MinAlert=${1} # temp en minute entre l'alerte et l'action
H=$((10#${2}))
M=$((10#${3}))
D=$((10#${4}))
MinTotalAlert="$(($H*60+$M-$MinAlert))"
if [ $(( $MinTotalAlert < 0 )) -eq 1 ] 
then
	if [ $Numday -eq 0 ] ; then
		D=6
	else
		D=$(( $D -1 ))
	fi
	MinTotalAlert="$(($(($H + 24))*60+$M-$MinAlert))"
fi
Halert=$(($MinTotalAlert/60))
MAlert=$(($MinTotalAlert - $(( $Halert *60 )) ))
echo "$MAlert $Halert * * ${DAYSCRON[$D]}"
}
updatetimelogin () {
	USERSCONECT=$(who | awk '//{print $1}' | sort -u)
   	if [ $(cat $FILE_HCOMPT | grep -c $(date +%D)) -eq 1 ] ; then
			# on incrément le conteur de temps de connection. pour chaque utilisateur connecter
		for PCUSER in $USERSCONECT
		do
		
			if [ $(cat $FILE_HCONF | grep -c ^$PCUSER=user= ) -eq 1 ] ;then
			   if [ $(cat $FILE_HCOMPT | grep -c ^$PCUSER= ) -eq 0 ] ;then
					echo "$PCUSER=1" >> $FILE_HCOMPT
			   else
					count=$(($(cat $FILE_HCOMPT | grep ^$PCUSER= | cut -d"=" -f2) + 1 ))
					$SED "s?^$PCUSER=.*?$PCUSER=$count?g" $FILE_HCOMPT
					temprest=$(($(cat $FILE_HCONF | grep ^$PCUSER=user= | cut -d "=" -f3 ) - $count ))
					echo $temprest
					# si le compteur de l'usager dépasse la valeur max autorisée on verrouille le compte et on deconnecte l'utilisateur.
					if [ $temprest -le 0 ];then
						/usr/bin/skill -KILL -u$PCUSER
						passwd -l $PCUSER
					else
						# On allerte l'usager que sont quota temps arrive a expiration 5-4-3-2-1 minutes avant.
						if [ $temprest -le 10 ];then
						HOMEPCUSER=$(getent passwd "$PCUSER" | cut -d ':' -f6)
						export HOME=$HOMEPCUSER && export DISPLAY=:0.0 && export XAUTHORITY=$HOMEPCUSER/.Xauthority && sudo -u $PCUSER  /usr/bin/notify-send -u critical "Alerte CTparental" "Votre temps de connexion restant est de $temprest minutes "
						fi
					fi
			   fi
			   
			else
			# on efface les ligne relative a cette utilisateur
			$SED "/^$PCUSER=/d" $FILE_HCOMPT
			fi

		done	
	else
		# on réactivent tous les comptes
		for PCUSER in `listeusers`
		do
			passwd -u $PCUSER
		done
		# on remait tous les compteurs a zero.
		echo "date=$(date +%D)" > $FILE_HCOMPT
		
	fi
	
}
activetimelogin () {
   TESTGESTIONNAIRE=""
   for FILE in `echo $GESTIONNAIREDESESSIONS`
   do
      if [ -f $DIRPAM$FILE ];then
         if [ $(cat $DIRPAM$FILE | grep -c "account required pam_time.so") -eq 0  ] ; then
            $SED "1i account required pam_time.so"  $DIRPAM$FILE
         fi
         TESTGESTIONNAIRE=$TESTGESTIONNAIRE\ $FILE
      fi
   done
   if [ $( echo $TESTGESTIONNAIRE | wc -m ) -eq 1 ] ; then
      echo "Aucun gestionnaire de session connu n'a été détecté."
      echo " il est donc impossible d'activer le contrôle horaire des connexions"
      desactivetimelogin
      exit 1
   fi
   
   if [ ! -f $FILEPAMTIMECONF.old ] ; then
   cp $FILEPAMTIMECONF $FILEPAMTIMECONF.old
   fi
   echo "*;*;root;Al0000-2400" > $FILEPAMTIMECONF
   for NumDAY in 0 1 2 3 4 5 6
   do
   echo "PATH=$PATH"  > /etc/cron.d/CTparental${DAYS[$NumDAY]}
   done
   for PCUSER in `listeusers`
   do
   HOMEPCUSER=$(getent passwd "$PCUSER" | cut -d ':' -f6)
   $SED "/^$PCUSER=/d" $FILE_HCONF
   echo -e -n "$PCUSER est autorisé a se connecter 7j/7 24h/24 O/N?" 
   choi=""
   while (true); do
   read choi
        case $choi in
         O | o )
	 alltime="O"
         echo "$PCUSER=admin=" >> $FILE_HCONF
   	break
         ;;
	 N| n )
         alltime="N"
         clear
         echo -e "$PCUSER est autorisé à se connecter X minutes par jours" 
         echo -e -n "X (1 a 1440) = " 
         while (true); do
         read choi
         if [ $choi -ge 1 ];then
			if [ $choi -le 1440 ];then
				break
			fi
		 fi	
         echo " X doit prendre un valeur entre 1 et 1440 "
         done
         echo "$PCUSER=user=$choi" >> $FILE_HCONF
		 break
         ;;	
   esac
   done
      HORAIRES=""
      for NumDAY in 0 1 2 3 4 5 6
         do
	 if [ $alltime = "O" ];then	
		break	
	 fi
	 
         clear
         echo "exemple: 00h00 à 23h59 ou 08h00 à 12h00 et 14h00 à 16h50"
         echo -e -n "$RougeD$PCUSER$Fcolor est autorisé à se connecter le $BleuD${DAYS[$NumDAY]}$Fcolor de :"
         while (true); do
            read choi
            input=$choi
            choi=$(echo $choi | sed -e "s/h//g" | sed -e "s/ //g" | sed -e "s/a/-/g" | sed -e "s/et/:/g" ) # mise en forme de la variable choi pour pam   
               if [ $( echo $choi | grep -E -c "^([0-1][0-9]|2[0-3])[0-5][0-9]-([0-1][0-9]|2[0-3])[0-5][0-9]$|^([0-1][0-9]|2[0-3])[0-5][0-9]-([0-1][0-9]|2[0-3])[0-5][0-9]:([0-1][0-9]|2[0-3])[0-5][0-9]-([0-1][0-9]|2[0-3])[0-5][0-9]$" ) -eq 1 ];then
                  int1=$(echo $choi | cut -d ":" -f1 | cut -d "-" -f1)
                  int2=$(echo $choi | cut -d ":" -f1 | cut -d "-" -f2)
                  int3=$(echo $choi | cut -d ":" -f2 | cut -d "-" -f1)
                  int4=$(echo $choi | cut -d ":" -f2 | cut -d "-" -f2)
                  if [ $int1 -lt $int2 ];then
                     if [ ! $(echo $choi | grep -E -c ":") -eq 1 ] ; then
                        if [ $NumDAY -eq 6 ] ; then
                           HORAIRESPAM="$HORAIRESPAM${DAYSPAM[$NumDAY]}$int1-$int2"
                        else
                           HORAIRESPAM="$HORAIRESPAM${DAYSPAM[$NumDAY]}$int1-$int2|"
                        fi
                        m1=$(echo $int1 | sed -e 's/.\{02\}//')
                        h1=$(echo $int1 | sed -e 's/.\{02\}$//') 
                        m2=$(echo $int2 | sed -e 's/.\{02\}//')
                        h2=$(echo $int2 | sed -e 's/.\{02\}$//')
						echo "$PCUSER=$NumDAY=$h1${h}h$m1:$h2${h}h$m2" >> $FILE_HCONF   
                        echo "$m2 $h2 * * ${DAYSCRON[$NumDAY]} root /usr/bin/skill -KILL -u$PCUSER" >> /etc/cron.d/CTparental${DAYS[$NumDAY]}
			for count in 1 2 3 4 5
			do
                        echo "$(timecronalert $count $h2 $m2 $NumDAY) root export HOME=$HOMEPCUSER && export DISPLAY=:0.0 && export XAUTHORITY=$HOMEPCUSER/.Xauthority && sudo -u $PCUSER  /usr/bin/notify-send -u critical \"Alerte CTparental\" \"fermeture de session dans $count minutes \" " >> /etc/cron.d/CTparental${DAYS[$NumDAY]}
			done
                        break
   
                     else   
                        if [ $int2 -lt $int3 ];then
                           if [ $int3 -lt $int4 ];then
                              if [ $NumDAY -eq 6 ] ; then
                                 HORAIRESPAM="$HORAIRESPAM${DAYSPAM[$NumDAY]}$int1-$int2|${DAYSPAM[$NumDAY]}$int3-$int4"
                              else
                                 HORAIRESPAM="$HORAIRESPAM${DAYSPAM[$NumDAY]}$int1-$int2|${DAYSPAM[$NumDAY]}$int3-$int4|"
                              fi
                              m1=$(echo $int1 | sed -e 's/.\{02\}//')
                              h1=$(echo $int1 | sed -e 's/.\{02\}$//')   
                              m2=$(echo $int2 | sed -e 's/.\{02\}//')
                              h2=$(echo $int2 | sed -e 's/.\{02\}$//')  
                              m3=$(echo $int3 | sed -e 's/.\{02\}//')
                              h3=$(echo $int3 | sed -e 's/.\{02\}$//')   
                              m4=$(echo $int4 | sed -e 's/.\{02\}//')
                              h4=$(echo $int4 | sed -e 's/.\{02\}$//')   
                              ## minutes heures jourdumoi moi jourdelasemaine utilisateur  commande
							  echo "$PCUSER=$NumDAY=$h1${h}h$m1:$h2${h}h$m2:$h3${h}h$m3:$h4${h}h$m4" >> $FILE_HCONF
                              echo "$m2 $h2 * * ${DAYSCRON[$NumDAY]} root /usr/bin/skill -KILL -u$PCUSER" >> /etc/cron.d/CTparental${DAYS[$NumDAY]}
			      echo "$m4 $h4 * * ${DAYSCRON[$NumDAY]} root /usr/bin/skill -KILL -u$PCUSER" >> /etc/cron.d/CTparental${DAYS[$NumDAY]}
			      for count in 1 2 3 4 5
			      do
                              echo "$(timecronalert $count $h2 $m2 $NumDAY) root export HOME=$HOMEPCUSER && export DISPLAY=:0.0 && export XAUTHORITY=$HOMEPCUSER/.Xauthority && sudo -u $PCUSER  /usr/bin/notify-send -u critical \"Alerte CTparental\" \"fermeture de session dans $count minutes \" " >> /etc/cron.d/CTparental${DAYS[$NumDAY]}
                              echo "$(timecronalert $count $h4 $m4 $NumDAY) root export HOME=$HOMEPCUSER && export DISPLAY=:0.0 && export XAUTHORITY=$HOMEPCUSER/.Xauthority && sudo -u $PCUSER  /usr/bin/notify-send -u critical \"Alerte CTparental\" \"fermeture de session dans $count minutes\" " >> /etc/cron.d/CTparental${DAYS[$NumDAY]}
			      done
                             
                              break   
                           else
                              errortime1
                           fi
                        else
                           errortime1
                        fi
                     fi
                  else
                     errortime1
   
                  fi
                       
               else
                  errortime2   
               fi
           
         done
     
        done
     	if [ $alltime = "N" ] ; then
		echo "*;*;$PCUSER;$HORAIRESPAM" >> $FILEPAMTIMECONF
	else
		echo "*;*;$PCUSER;Al0000-2400" >> $FILEPAMTIMECONF
	fi
   done
   
   for NumDAY in 0 1 2 3 4 5 6
   do
      echo >> /etc/cron.d/CTparental${DAYS[$NumDAY]}
   done
   echo >> $FILE_HCONF
echo "PATH=$PATH"  > /etc/cron.d/CTparentalmaxtimelogin
echo "*/1 * * * * root /usr/local/bin/CTparental.sh -uctl" >> /etc/cron.d/CTparentalmaxtimelogin
$SED "s?^HOURSCONNECT.*?HOURSCONNECT=ON?g" $FILE_CONF
$CRONrestart
}

desactivetimelogin () {
echo "desactivetimelogin"
for FILE in `echo $GESTIONNAIREDESESSIONS`
do
   $SED "/account required pam_time.so/d" $DIRPAM$FILE 2> /dev/null
done
cat $FILEPAMTIMECONF.old > $FILEPAMTIMECONF
for NumDAY in 0 1 2 3 4 5 6
do
   rm -f /etc/cron.d/CTparental${DAYS[$NumDAY]}
done
rm -f /etc/cron.d/CTparentalmaxtimelogin
$SED "s?^HOURSCONNECT.*?HOURSCONNECT=OFF?g" $FILE_CONF 
for PCUSER in `listeusers`
do
	passwd -u $PCUSER > /dev/null
done
# on remet tous les compteurs à zéro.
echo "date=$(date +%D)" > $FILE_HCOMPT
echo > $FILE_HCONF
$CRONrestart
echo "fin desactivetimelogin"
}


listeusers () {
TABUSER=( " $(getent passwd | cut -d":" -f1,3) " )
for LIGNES in $TABUSER
do
#echo $(echo $LIGNES | cut -d":" -f2)
if [ $(echo $LIGNES | cut -d":" -f2) -ge $UIDMINUSER ] ;then
	echo $LIGNES | cut -d":" -f1
fi
done


}


readTimeFILECONF () {
   TESTGESTIONNAIRE=""
   for FILE in `echo $GESTIONNAIREDESESSIONS`
   do
      if [ -f $DIRPAM$FILE ];then
         if [ $(cat $DIRPAM$FILE | grep -c "account required pam_time.so") -eq 0  ] ; then
            $SED "1i account required pam_time.so"  $DIRPAM$FILE
         fi
         TESTGESTIONNAIRE=$TESTGESTIONNAIRE\ $FILE
      fi
   done
   if [ $( echo $TESTGESTIONNAIRE | wc -m ) -eq 1 ] ; then
      echo "Aucun gestionnaire de session connu n'a été détecté."
      echo " il est donc impossible d'activer le contrôle horaire des connexions"
      desactivetimelogin
      exit 1
   fi
   
   if [ ! -f $FILEPAMTIMECONF.old ] ; then
   cp $FILEPAMTIMECONF $FILEPAMTIMECONF.old
   fi
   echo "*;*;root;Al0000-2400" > $FILEPAMTIMECONF
   for NumDAY in 0 1 2 3 4 5 6
   do
   echo "PATH=$PATH" > /etc/cron.d/CTparental${DAYS[$NumDAY]}
   done
   
   for PCUSER in `listeusers`
   do
   HOMEPCUSER=$(getent passwd "$PCUSER" | cut -d ':' -f6)
   HORAIRESPAM=""
  	userisconfigured="0"

	while read line
	do
	
			if [ $( echo $line | grep -E -c "^$PCUSER=[0-6]=" ) -eq 1 ] ; then
				echo "$line" 
				NumDAY=$(echo $line | cut -d"=" -f2)
				h1=$(echo $line | cut -d"=" -f3 | cut -d":" -f1 | cut -d"h" -f1)
				m1=$(echo $line | cut -d"=" -f3 | cut -d":" -f1 | cut -d"h" -f2)
				h2=$(echo $line | cut -d"=" -f3 | cut -d":" -f2 | cut -d"h" -f1)
				m2=$(echo $line | cut -d"=" -f3 | cut -d":" -f2 | cut -d"h" -f2)
				h3=$(echo $line | cut -d"=" -f3 | cut -d":" -f3 | cut -d"h" -f1)
				m3=$(echo $line | cut -d"=" -f3 | cut -d":" -f3 | cut -d"h" -f2)
				h4=$(echo $line | cut -d"=" -f3 | cut -d":" -f4 | cut -d"h" -f1)
				m4=$(echo $line | cut -d"=" -f3 | cut -d":" -f4 | cut -d"h" -f2)
				if [ $(echo -n $h3$m3 | wc -c) -gt 2 ]; then
 					if [ $NumDAY -eq 6 ] ; then
		                        	HORAIRESPAM="$HORAIRESPAM${DAYSPAM[$NumDAY]}$h1$m1-$h2$m2|${DAYSPAM[$NumDAY]}$h3$m3-$h4$m4"
						
		                      	else
		                        	HORAIRESPAM="$HORAIRESPAM${DAYSPAM[$NumDAY]}$h1$m1-$h2$m2|${DAYSPAM[$NumDAY]}$h3$m3-$h4$m4|"
		                      	fi
					echo "$m2 $h2 * * ${DAYSCRON[$NumDAY]} root /usr/bin/skill -KILL -u$PCUSER" >> /etc/cron.d/CTparental${DAYS[$NumDAY]}
					echo "$m4 $h4 * * ${DAYSCRON[$NumDAY]} root /usr/bin/skill -KILL -u$PCUSER" >> /etc/cron.d/CTparental${DAYS[$NumDAY]}
					for count in 1 2 3 4 5 6 7 8 9 10
					do
					echo "$(timecronalert $count $h2 $m2 $NumDAY) root export HOME=$HOMEPCUSER && export DISPLAY=:0.0 && export XAUTHORITY=$HOMEPCUSER/.Xauthority && sudo -u $PCUSER  /usr/bin/notify-send -u critical \"Alerte CTparental\" \"fermeture de session dans $count minutes \" " >> /etc/cron.d/CTparental${DAYS[$NumDAY]}
					echo "$(timecronalert $count $h4 $m4 $NumDAY) root export HOME=$HOMEPCUSER && export DISPLAY=:0.0 && export XAUTHORITY=$HOMEPCUSER/.Xauthority && sudo -u $PCUSER  /usr/bin/notify-send -u critical \"Alerte CTparental\" \"fermeture de session dans $count minutes \" " >> /etc/cron.d/CTparental${DAYS[$NumDAY]}
					userisconfigured="1"
					done

				else
				        if [ $NumDAY -eq 6 ] ; then
				           HORAIRESPAM="$HORAIRESPAM${DAYSPAM[$NumDAY]}$h1$m1-$h2$m2"
				        else
				           HORAIRESPAM="$HORAIRESPAM${DAYSPAM[$NumDAY]}$h1$m1-$h2$m2|"
				        fi
					for count in 1 2 3 4 5 6 7 8 9 10
					do
					echo "$(timecronalert $count $h2 $m2 $NumDAY) root export HOME=$HOMEPCUSER && export DISPLAY=:0.0 && export XAUTHORITY=$HOMEPCUSER/.Xauthority && sudo -u $PCUSER  /usr/bin/notify-send -u critical \"Alerte CTparental\" \"fermeture de session dans $count minutes \" " >> /etc/cron.d/CTparental${DAYS[$NumDAY]}
					done
					echo "$m2 $h2 * * ${DAYSCRON[$NumDAY]} root /usr/bin/skill -KILL -u$PCUSER" >> /etc/cron.d/CTparental${DAYS[$NumDAY]}
					
					userisconfigured="1"
				fi
			fi
	
	
	done < $FILE_HCONF
	if [ $userisconfigured -eq 1 ] ; then
		echo "*;*;$PCUSER;$HORAIRESPAM" >> $FILEPAMTIMECONF
	else
		echo "*;*;$PCUSER;Al0000-2400" >> $FILEPAMTIMECONF 
		$SED "/^$PCUSER=/d" $FILE_HCOMPT 
		passwd -u $PCUSER
	fi
   done
echo "PATH=$PATH"  > /etc/cron.d/CTparentalmaxtimelogin  
echo "*/1 * * * * root /usr/local/bin/CTparental.sh -uctl" >> /etc/cron.d/CTparentalmaxtimelogin
$SED "s?^HOURSCONNECT.*?HOURSCONNECT=ON?g" $FILE_CONF
$CRONrestart
}


# and func # ne pas effacer cette ligne !!

usage="Usage: CTparental.sh    {-i }|{ -u }|{ -dl }|{ -ubl }|{ -rl }|{ -on }|{ -off }|{ -cble }|{ -dble }
                               |{ -tlo }|{ -tlu }|{ -uhtml }|{ -aupon }|{ -aupoff }|{ -aup } 
-i      => Installe le contrôle parental sur l'ordinateur (pc de bureau). Peut être utilisé avec
           un paramètre supplémentaire pour indiquer un chemin de sources pour la page web de redirection.
           exemple : CTparental.sh -i -dirhtml /home/toto/html/
           si pas d'option le \"sens interdit\" est utilisé par défaut.
-u      => désinstalle le contrôle parental de l'ordinateur (pc de bureau)
-dl     => met à jour le contrôle parental à partir de la blacklist de l'université de Toulouse
-ubl    => A faire après chaque modification du fichier $DNS_FILTER_OSSI
-rl     => A faire après chaque modification manuelle du fichier $DREAB
-on     => Active le contrôle parental
-off    => Désactive le contrôle parental
-cble   => Configure le mode de filtrage par liste blanche ou par liste noire (défaut) ainsi que les 
           catégories que l'on veut activer.
-dble   => Remet les catégories actives par défaut et le filtrage par liste noire.
-tlo    => Active et paramètre les restrictions horaires de login pour les utilisateurs.
           Compatible avec les gestionnaire de sessions suivant $GESTIONNAIREDESESSIONS .
-tlu    => Désactive les restrictions horaires de login pour les utilisateurs.
-uhtml  => met à jour la page de redirection à partir d'un répertoire source ou par défaut avec 
            le \"sens interdit\".
            exemples:
                     - avec un repertoire source : CTparental.sh -uhtml -dirhtml /home/toto/html/
   		     - par défaut :              CTparental.sh -uhtml
            permet aussi de changer le couple login, mot de passe de l'interface web.
-aupon  => active la mise à jour automatique de la blacklist de Toulouse (tous les 7 jours).
-aupoff => désactive la mise à jour automatique de la blacklist de Toulouse.
-aup    => comme -dl mais seulement si il n'y a pas eu de mise à jour depuis plus de 7 jours.
-nodep  => si placé aprés -i ou -u permet de ne pas installer/désinstaller les dépendances, utiles si  
            on préfère les installer à la main , ou pour le script de postinst et prerm  
            du deb.
            exemples:
                     CTparental.sh -i -nodep	
		     CTparental.sh -i -dirhtml /home/toto/html/ -nodep   
		     CTparental.sh -u -nodep 
-nomanuel =>  utilisé uniquement pour le script de postinst et prerm  
            du deb.
-gcton	  => créé un groupe de privilégiés ne subissant pas le filtrage.
			 exemple:CTparental.sh -gctulist
			 editer $FILE_GCTOFFCONF et y commenter tous les utilisateurs que l'on veut filtrer.
			 CTparental.sh -gctalist
-gctoff   => supprime le groupe de privilégiés .
			 tous les utilisateurs du système subissent le filtrages!!
-gctulist => Met a jour le fichier de conf du groupe , $FILE_GCTOFFCONF
			 en fonction des utilisateurs ajoutés ou supprimés du pc.
-gctalist => Ajoute/Supprime les utilisateurs dans le group ctoff en fonction du fichier de conf.
-ipton	  => Active les règles de par feux personnalisées.
-iptoff   => Désactive les règles de par feux personnalisées.
	 
 "
case $arg1 in
   -\? | -h* | --h*)
      echo "$usage"
      exit 0
      ;;
   -i )
      install
      exit 0
      ;;
   -u )
	  uninstall
      exit 0
      ;;
   -dl )
      if [ ! $FILTRAGEISOFF -eq 1 ];then
		  download
		  adapt
		  catChoice
		  dnsmasqon
		  $SED "s?^LASTUPDATE.*?LASTUPDATE=$THISDAYS=`date +%d-%m-%Y\ %T`?g" $FILE_CONF
      fi
      exit 0
      ;;
   -ubl )
      if [ ! $FILTRAGEISOFF -eq 1 ];then
		  adapt
		  catChoice
		  dnsmasqon
      fi
       
      exit 0
      ;;
   -uhtml )
      FoncHTTPDCONF
      exit 0
      ;;
   -rl )
      if [ ! $FILTRAGEISOFF -eq 1 ];then
         catChoice
         dnsmasqon
      fi 
      exit 0
      ;;
   -on )
      dnsmasqon
      iptablesreload
      exit 0
      ;;
   -off )
	  desactivegourpectoff
      autoupdateoff 
      dnsmasqoff
      iptablesoff
      exit 0
      ;;
   -wlo )
	  if [ ! $FILTRAGEISOFF -eq 1 ];then
		  dnsmasqwhitelistonly
      fi
      exit 0
      ;;
   -cble )
      if [ ! $FILTRAGEISOFF -eq 1 ];then
		  choiblenabled
		  catChoice
		  dnsmasqon
      fi
      exit 0
      ;;
    -dble )
      if [ ! $FILTRAGEISOFF -eq 1 ];then
		  initblenabled
		  catChoice
		  dnsmasqon
      fi
      exit 0
      ;;
    -tlo )
      activetimelogin
      exit 0
      ;;
    -tlu )
      desactivetimelogin
      exit 0
      ;;
    -trf )
      readTimeFILECONF
      exit 0
      ;;
    -aupon )
      if [ ! $FILTRAGEISOFF -eq 1 ];then
		 autoupdateon
      fi
      exit 0
      ;;
    -aupoff )
      autoupdateoff
      exit 0
      ;;
    -aup )
      if [ ! $FILTRAGEISOFF -eq 1 ];then
		 autoupdate
      fi
      exit 0
      ;;
    -listusers )
      listeusers
      exit 0
      ;;
    -gcton )
      if [ ! $FILTRAGEISOFF -eq 1 ];then
		  activegourpectoff
		  iptablesreload
	  fi
	  exit 0
      ;;
    -gctoff )
	  desactivegourpectoff
	  iptablesreload
	  exit 0
      ;;
    -gctulist )
      if [ ! $FILTRAGEISOFF -eq 1 ];then
		  updatelistgctoff
		  iptablesreload
	  fi
	  exit 0
      ;;
    -gctalist )
      if [ ! $FILTRAGEISOFF -eq 1 ];then
		  test=$(updatelistgctoff)
		  if [ $test -eq 1 ];then
			updatecauser
			setproxy
		  fi
		  unset test
		  applistegctoff
		  iptablesreload
	  fi
	  exit 0
      ;;
    -ipton )
      $SED "s?.*IPRULES.*?IPRULES=ON?g" $FILE_CONF
      iptablesreload
      echo -e "$RougeD pour ajouter des règles personalisée éditer le fichier "
      echo " $FILEIPTABLES "
      echo -e " puis relancer la commande CTparental.sh -ipton $Fcolor"
      exit 0
      ;;
    -iptoff )
      $SED "s?.*IPRULES=.*?IPRULES=OFF?g" $FILE_CONF
      iptablesreload
      exit 0
      ;;
    -uctl )
	 # appelé toutes les minutes par cron pour activer désactiver les usagers ayant des restrictions de temps journalier de connexion.
	  updatetimelogin
	  exit 0
      ;;  
    -ucto )
      if [ ! $FILTRAGEISOFF -eq 1 ];then
		 # appelé toutes les minutes par cron pour activer le filtrage sur les usagers nouvelement créé .
		  test=$(updatelistgctoff)
		  if [ $test -eq 1 ];then
			applistegctoff
			updatecauser
			setproxy
			iptablesreload
		  fi
		  unset test
	  fi
	  exit 0
      ;;       
      
   *)
      echo "Argument inconnu :$1";
      echo "$usage";
      exit 1
      ;;
esac



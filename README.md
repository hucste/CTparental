Controle parental.
 Filtrage web basé sur iptables dnsmasq dansguardian privoxy lighttpd cron et la blacklist de l'université de Toulouse.
 une gestion des horaires de connection est aussi intégrée et
 une interface web (http://127.0.0.1/CTadmin) permettant de paramétrer tous ça.
 Le couple login mot de passe doit être saisi à l'install, mais peut être
 modifié par la suite grâce à la commande CTparental.sh -uhtml.
 Filtrage par Blackliste ou par Whiteliste .
 Filtre par Catégorie .
 Filtre personnalisé de site .
 Filtre Personnalisé de sites à laisser accessibles même s'il sont présents dans une des catégories que l'on veut bloquer.
 Réglages des heures de connexions autorisées par utilisateur.
 Nombres de minutes de connexions max par jours autorisées.
 Groupe de personnes privilégiées ne subissant pas de filtrage web.
 Notifications des Utilisateurs toutes les minutes durant les 5 dernières minutes avant déconnexion.
 dansguardian + privoxy (paramètre non disponible via l'interface.)
 force SafeSearch google
 force SafeSearch duckduckgo
 force SafeSearch bing
 blocage de moteurs de recherches jugés non sûr comme bing en https et search.yahoo.com.
 ajout de la gestion de règle personnalisées pour iptables a activer avec CTparental.sh -ipton


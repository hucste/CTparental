<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML><!-- written by Rexy -->
<HEAD>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<?php
# on détecte la langue system
$LANG=getenv('LANG'); 
if(isset($LANG)) {
$tab=explode(".",getenv('LANG'));
$domain=substr($tab[0],0,2);

// set the locale into the instance of gettext 
setlocale(LC_ALL,$LANG); // change by language, directory name fr_FR, not fr_FR.UTF-8 

// Spécifie la localisation des tables de traduction
// ce qui donne pour une variable $LANG='fr_FR.UTF-8' une répertoir ci dessous.
// ./locale/fr_FR/LC_MESSAGES/
bindtextdomain($domain, "./locale");

// Choisit le domaine
// ce qui nous donne un nom de fichier pour $LANG='fr_FR.UTF-8' de fr.mo
textdomain($domain);
// La traduction est cherché dans ./locale/fr_FR/LC_MESSAGES/fr.mo
}
$bl_dir="/usr/local/etc/CTparental/dnsfilter-available/";
  $l_title=gettext("Blacklist categories");
  $l_error_open_file=gettext("Error opening the file");
  $l_close=gettext("Close");
  $l_unknown_cat=gettext("This category isn't describe");
  $l_nb_domains=gettext("Number of filtered domain names :");
  $l_nb_urls=gettext("Number of filtered URL :");
  $l_explain_adult=gettext("Sites related to eroticism and pornography");
  $l_explain_agressif=gettext("Sites extremist, racist, anti-Semitic or hate");
  $l_explain_arjel=gettext("Online gambling sites allowed by the french authority 'ARJEL' (Autorité de Régulation des Jeux En Ligne)");
  $l_explain_astrology=gettext("Sites related to astrology");
  $l_explain_audio_video=gettext("Sites for downloading audio and video");
  $l_explain_bank=gettext("Online bank sites");
  $l_explain_blog=gettext("Sites hosting blogs");
  $l_explain_celebrity=gettext("Sites « people », stars, etc.");
  $l_explain_chat=gettext("Online chat sites");
  $l_explain_child=gettext("Sites for children");
  $l_explain_cleaning=gettext("Sites related to software update or antiviral");
  $l_explain_dangerous_material=gettext("Sites related to the creation of dangerous goods (explosives, poison, etc.)");
  $l_explain_dating=gettext("Online dating sites");
  $l_explain_drogue=gettext("Sites related to narcotic");
  $l_explain_filehosting=gettext("Warehouses of files (video, images, sound, software, etc.)");
  $l_explain_financial=gettext("Sites of financial information");
  $l_explain_forums=gettext("Sites hosting discussion forums");
  $l_explain_gambling=gettext("Online gambling sites (casino, virtual scratching, etc.)");
  $l_explain_games=gettext("Online games sites");
  $l_explain_hacking=gettext("Sites related to hacking");
  $l_explain_jobsearch=gettext("Job search sites");
  $l_explain_liste_bu=gettext("List of educational sites for library");
  $l_explain_malware=gettext("Malware sites (viruses, worms, trojans, etc.).");
  $l_explain_manga=gettext("Manga site");
  $l_explain_marketingware=gettext("doubtful commercial sites");
  $l_explain_mixed_adult=gettext("Adult sites (shock, gore, war, etc.).");
  $l_explain_mobile_phone=gettext("Sites related to GSM mobile (ringtones, logos, etc.)");
  $l_explain_ossi=gettext("Domain names and URLs you add to the blacklist (see below)");
  $l_explain_phishing=gettext("Phishing sites (traps banking, redirect, etc..)");
  $l_explain_press=gettext("News sites");
  $l_explain_publicite=gettext("Advertising sites");
  $l_explain_radio=gettext("Online radio podcast sites");
  $l_explain_reaffected=gettext("Sites that have changed ownership (and therefore content)");
  $l_explain_redirector=gettext("redirects, anonymization or bypass sites");
  $l_explain_remote_control=gettext("Sites for making remote control");
  $l_explain_sect=gettext("Sectarian sites");
  $l_explain_social_networks=gettext("Social networks sites");
  $l_explain_sexual_education=gettext("Sites related to sex education");
  $l_explain_shopping=gettext("Shopping sites and online shopping");
  $l_explain_sport=gettext("Sport sites");
  $l_explain_strict_redirector=gettext("Intentionally malformed URL");
  $l_explain_strong_redirector=gettext("Malformed URL in a 'google' query");
  $l_explain_tricheur=gettext("Sites related to cheating (tests, examinations, etc.)");
  $l_explain_webmail=gettext("Web sites for e-mail consultation");
  $l_explain_warez=gettext("Sites related to cracked softwares");

if (isset($_GET['cat'])){$categorie=$_GET['cat'];} 
$bl_categorie_domain_file=$bl_dir.$categorie.".conf";
if (file_exists($bl_categorie_domain_file))
	$nb_domains=exec ("wc -w $bl_categorie_domain_file|cut -d' ' -f1");
else
	$nb_domains=$l_error_openfilei." ".$bl_categorie_domain_file;
if (file_exists($bl_categorie_url_file))
	$nb_urls=exec ("wc -w $bl_categorie_url_file|cut -d' ' -f1");
else
	$nb_urls=$l_error_openfile." ".$bl_categorie_url_file;
echo "<TITLE>$l_title</TITLE>";
?>
<link rel="stylesheet" href="./css/style.css" type="text/css">
</HEAD>
<body>
<TABLE width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr><th><?php echo $categorie ;?></th></tr>
	<tr bgcolor="#FFCC66"><td><img src="/images/pix.gif" width="1" height="2"></td></tr>
</TABLE>
<TABLE width="100%" border=1 cellspacing=0 cellpadding=1>
<tr><td valign="middle" align="left">
<?php
$compat_categorie=strtr($categorie,"-","_");
if (!empty(${'l_explain_'.$compat_categorie}))
	echo "<center><b>${'l_explain_'.$compat_categorie}</b></center>";
else echo "$l_unknown_cat";
echo "<br>$l_nb_domains <b>$nb_domains</b><br>";
?>
</td></tr>
</TABLE>
<br>
<center><a href="javascript:window.close();"><b><?php echo "$l_close"; ?></b></a></center>
</BODY>
</HTML>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML><!-- written by Rexy -->
<HEAD>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<TITLE>CTparental DNS filtering</TITLE>
<link rel="stylesheet" href="css/style.css" type="text/css">
</HEAD>
<body>
<?php
function form_filter ($form_content)
{
// réencodage iso + format unix + rc fin de ligne (ouf...)
	$list = str_replace("\r\n", "\n", utf8_decode($form_content));
	if (strlen($list) != 0){
		if ($list[strlen($list)-1] != "\n") { $list[strlen($list)]="\n";} ;} ;
	return $list;
}
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

$week = array( gettext("monday"),gettext("tuesday"),gettext("wednesday"),gettext("thursday"),gettext("friday"),gettext("saturday"),gettext("sunday"));
$weeknum = array( 0,1,2,3,4,5,6);
$bl_categories="/usr/local/etc/CTparental/bl-categories-available";
$bl_categories_enabled="/usr/local/etc/CTparental/categories-enabled";
$conf_file="/usr/local/etc/CTparental/CTparental.conf";
$conf_ctoff_file="/usr/local/etc/CTparental/GCToff.conf";
$hconf_file="/usr/local/etc/CTparental/CThours.conf";
$wl_domains="/usr/local/etc/CTparental/domaine-rehabiliter";
$bl_domains="/usr/local/etc/CTparental/blacklist-local";
# default values


if (isset($_POST['choix'])){ $choix=$_POST['choix']; } else { $choix=""; }
switch ($choix)
{
case 'gct_Off' :
	exec ("sudo -u root /usr/local/bin/CTparental.sh -gctoff");
	break;
case 'gct_On' :
	exec ("sudo -u root /usr/local/bin/CTparental.sh -gcton");
	break;
case 'LogOFF' :
	header('HTTP/1.0 401 Unauthorized');
	header('WWW-Authenticate: Digest realm="interface admin"');
	exit;
	break;
case 'BL_On' :
	exec ("sudo -u root /usr/local/bin/CTparental.sh -on");
	break;
case 'BL_Off' :
	exec ("sudo -u root /usr/local/bin/CTparental.sh -off");
	break;
case 'H_On' :
	exec ("sudo -u root /usr/local/bin/CTparental.sh -trf");
	break;
case 'H_Off' :
	exec ("sudo -u root /usr/local/bin/CTparental.sh -tlu");
	break;
case 'AUP_On' :
	exec ("sudo -u root /usr/local/bin/CTparental.sh -aupon");
	break;
case 'AUP_Off' :
	exec ("sudo -u root /usr/local/bin/CTparental.sh -aupoff");
	break;
case 'INIT_BL' :
	exec ("sudo -u root /usr/local/bin/CTparental.sh -dble");
	break;
case 'Download_bl' :
	exec ("sudo -u root /usr/local/bin/CTparental.sh -dl");
	break;
case 'MAJ_cat' :
	$tab=file($bl_categories_enabled);	
	if ($tab)
		{
		$pointeur=fopen($bl_categories_enabled, "w+");
		foreach ($_POST as $key => $value)
			{
                        if (strstr($key,'chk-'))
				{	
				$line=str_replace('chk-','',$key)."\n";
				fwrite($pointeur,$line);
				}
			}
		fclose($pointeur);
		}
	else {echo gettext('Error opening the file')." ".$bl_categories_enabled;}
	$fichier=fopen($bl_domains,"w+");
	fputs($fichier, form_filter($_POST['OSSI_bl_domains']));
	fclose($fichier);
	unset($_POST['OSSI_bl_domains']);
	$fichier=fopen($wl_domains,"w+");
	fputs($fichier, form_filter($_POST['OSSI_wl_domains']));
	fclose($fichier);
	unset($_POST['OSSI_wl_domains']);
	exec ("sudo -u root /usr/local/bin/CTparental.sh -ubl");
	break;
case 'MAJ_H' :
	$formatheuresok=1;
	if (isset($_POST['selectuser'])){ $selectuser=$_POST['selectuser']; }
	#echo "$selectuser";
	$tab=file($hconf_file);	
	if ($tab)
	{
		$pointeur=fopen($hconf_file, "w+");	
		foreach ($tab as $line)
		{
			if (strstr($line,$selectuser) == false)
			{
				fwrite($pointeur,$line); # on reécrit toutes les lignes ne correspondant pas à l'utilisateur sélectionné
			}
	
		}
	}
	else {echo gettext('Error opening the file')." $hconf_file";}
	if (isset($_POST["isadmin"])){fwrite($pointeur,"$selectuser=admin="."\n"); } 
	else 
	{
		if (isset($_POST["tmax"])){
			if ( preg_match( "/^[1-9]$|^[1-9][0-9]$|^[1-9][0-9][0-9]$|^1[0-3][0-9][0-9]$|^14[0-3][0-9]$|^1440$/", $_POST["tmax"] ) == 1  )
			{fwrite($pointeur,"$selectuser=user=".$_POST["tmax"]."\n");}
			else {fwrite($pointeur,"$selectuser=user=1440"."\n"); 
				  echo "<H3>".gettext('You must enter a value between 1 and 1440 minutes.')."</H3>";}
		}
		else {fwrite($pointeur,"$selectuser=user=1440"."\n"); }
		foreach ($weeknum as $numday)
		{
			$formatheuresok=1;
			if (isset($_POST["h1$numday"])){ $h1[$numday]=$_POST["h1$numday"]; } else { $h1[$numday]="00h00"; }
			if (isset($_POST["h2$numday"])){ $h2[$numday]=$_POST["h2$numday"]; } else { $h2[$numday]="23h59"; }
			if (isset($_POST["h3$numday"])){ $h3[$numday]=$_POST["h3$numday"]; } else { $h3[$numday]=""; }
			if (isset($_POST["h4$numday"])){ $h4[$numday]=$_POST["h4$numday"]; } else { $h4[$numday]=""; }
			if (preg_match("/^[0-1][0-9]h[0-5][0-9]$|^2[0-3]h[0-5][0-9]$/",$h1[$numday])!=1){$formatheuresok=0;}
			if (preg_match("/^[0-1][0-9]h[0-5][0-9]$|^2[0-3]h[0-5][0-9]$/",$h2[$numday])!=1){$formatheuresok=0;}
			if ($h3[$numday]=="")
			{	
	
				if ($formatheuresok == 1)
				{
					$t1=explode("h", $h1[$numday]);
					$t2=explode("h", $h2[$numday]);
					$v1="$t1[0]$t1[1]";
					$v2="$t2[0]$t2[1]";
					if ( $v1 < $v2)
					{
						fwrite($pointeur,"$selectuser=$numday=$h1[$numday]:$h2[$numday]"."\n");
					}
					else
					{
						fwrite($pointeur,"$selectuser=$numday=00h00:23h59"."\n");
						echo "<H3>$week[$numday] : ".gettext('time inconsistency: ')." $h1[$numday]>=$h2[$numday]</H3>";
					}
				}
				else 
				{
					fwrite($pointeur,"$selectuser=$numday=00h00:23h59"."\n");
					echo "<H3>$week[$numday] : ".gettext('A bad time format has been found: 8h30 instance must be written 08h30')."</H3>";
				}
			}
			else 
			{
				if (preg_match("/^[0-1][0-9]h[0-5][0-9]$|^2[0-3]h[0-5][0-9]$/",$h3[$numday])!=1){$formatheuresok=0;}
				if (preg_match("/^[0-1][0-9]h[0-5][0-9]$|^2[0-3]h[0-5][0-9]$/",$h4[$numday])!=1){$formatheuresok=0;}
				if ($formatheuresok == 1)
				{
					$t1=explode("h", $h1[$numday]);
					$t2=explode("h", $h2[$numday]);
					$t3=explode("h", $h3[$numday]);
					$t4=explode("h", $h4[$numday]);
					$v1="$t1[0]$t1[1]";
					$v2="$t2[0]$t2[1]";
					$v3="$t3[0]$t3[1]";
					$v4="$t4[0]$t4[1]";
					if ( $v1 < $v2 && $v2 < $v3 && $v3 < $v4)
					{
					fwrite($pointeur,"$selectuser=$numday=$h1[$numday]:$h2[$numday]:$h3[$numday]:$h4[$numday]"."\n");
					}
					else
					{
						fwrite($pointeur,"$selectuser=$numday=00h00:23h59"."\n");
						echo "<H3>$week[$numday] : ".gettext('time inconsistency: ')." $h1[$numday]>=$h2[$numday]>=$h3[$numday]>=$h4[$numday]</H3>";
					}
				}
				else 
				{
					fwrite($pointeur,"$selectuser=$numday=00h00:23h59"."\n");
					echo "<H3>$week[$numday] : ".gettext('A bad time format has been found: 8h30 instance must be written 08h30')."</H3>";
					
				}
			}

		}
	}
	
	fclose($pointeur);
	exec ("sudo -u root /usr/local/bin/CTparental.sh -trf");
	break;
	
case 'change_user' :
$tab=file($conf_ctoff_file);
	if ($tab)
		{
		$pointeur=fopen($conf_ctoff_file,"w+");
		foreach ($tab as $ligne)
			{
			$CONF_CTOFF1 = str_replace('#','',$ligne);
			$actif = False ;	
			foreach ($_POST as $key => $value)
				{
					if (strstr($key,'chk-'))
					{
						$CONF_CTOFF2 = str_replace('chk-','',$key);
						if ( trim($CONF_CTOFF1) == trim($CONF_CTOFF2) )
						{ 
							$actif = True; 
							break;
						}
					}
				}

			if (! $actif) {	$line="#$CONF_CTOFF1";}
			else { $line="$CONF_CTOFF1";}
			fwrite($pointeur,$line);
				
			}
		fclose($pointeur);
		}
	exec ("sudo -u root /usr/local/bin/CTparental.sh -gctalist");
	break;

}

echo "<TABLE width='100%' border=0 cellspacing=0 cellpadding=0>";
echo "<tr><th>".gettext('Domain names filtering')."</th></tr>";
echo "<tr bgcolor='#FFCC66'><td><img src='/images/pix.gif' width=1 height=2></td></tr>";
echo "</TABLE>";
echo "<TABLE width='100%' border=1 cellspacing=0 cellpadding=0>";
echo "<tr><td valign='middle' align='left'>";
echo "<CENTER>";
echo "<FORM action='$_SERVER[PHP_SELF]' method=POST>";
echo "<input type=hidden name='choix' value=\"LogOFF\">";
echo "<input type=submit value=".gettext('Logout').">";
echo "</FORM>";
echo "</CENTER>";
if (is_file ($conf_file))
	{
	$tab=file($conf_file);
	if ($tab)
		{
		foreach ($tab as $line)
			{
			$field=explode("=", $line);
			if ($field[0] == "LASTUPDATE")	{$LASTUPDATE=trim($field[2]);}
			if ($field[0] == "DNSMASQ")		{$DNSMASQ=trim($field[1]);}
			if ($field[0] == "AUTOUPDATE")		{$AUTOUPDATE=trim($field[1]);}
			if ($field[0] == "HOURSCONNECT")	{$HOURSCONNECT=trim($field[1]);}
            if ($field[0] == "GCTOFF")	{$GCTOFF=trim($field[1]);}            
			}
		}
	}
else { echo gettext('Error opening the file')." ".$conf_file;}

include 'dns.php';

include 'hours.php';

include 'gctoff.php';

//echo "</td></tr>";
?>
</BODY>
</HTML>

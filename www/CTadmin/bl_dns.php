<?php
echo "<table border=0 width=400 cellpadding=0 cellspacing=2>";
echo "<tr valign=top>";
echo "</tr>";
echo" </table>";
echo "</td></tr>";


	function echo_file ($filename)
		{
		if (file_exists($filename))
			{
			if (filesize($filename) != 0)
				{
				$pointeur=fopen($filename,"r");
				$tampon = fread($pointeur, filesize($filename));
				fclose($pointeur);
				echo $tampon;
				}
			}
		else
			{
			echo "$l_error_openfile $filename";
			}
		}

	echo "<TABLE width='100%' border=1 cellspacing=0 cellpadding=1>";
	echo "<CENTER><H3>".gettext('Blacklist filtering')."</H3></CENTER>";
	echo "<tr><td valign='middle' align='left' colspan=10>";
	echo "<FORM action='$_SERVER[PHP_SELF]?dgfile=Blacklist filtering' method=POST>";
	echo "<center>".gettext('Version actuelle :')." $LASTUPDATE";
	echo "</center><BR>";
		echo "<input type='hidden' name='choix' value='Download_bl'>";
		echo "<input type='submit' value='".gettext('Download the last version')."'>";
		echo " ".gettext('Estimated time : one minute.')." : ";

	echo "</FORM>";
	echo "<FORM action='$_SERVER[PHP_SELF]?dgfile=Blacklist filtering' method=POST>";
	echo "<input type='hidden' name='choix' value='INIT_BL'>";
	echo "<input type='submit' value='".gettext('Init Categories')."'>";
	echo "</FORM>";
	if ($AUTOUPDATE == "ON")
		{
		echo "<CENTER><H3>".gettext('The update of the blacklist Toulouse every 7 days is activated')."</H3></CENTER>";
		echo "<FORM action='$_SERVER[PHP_SELF]?dgfile=Blacklist filtering' method=POST>";
		echo "<input type=hidden name='choix' value=\"AUP_Off\">";
		echo "<input type=submit value=".gettext('Disable Auto Shift').">";
	}
	else
		{
		echo "<CENTER><H3>".gettext('The update of the blacklist Toulouse every 7 days is disabled')."</H3></CENTER>";
		echo "<FORM action='$_SERVER[PHP_SELF]?dgfile=Blacklist filtering' method=POST>";
		echo "<input type=hidden name='choix' value=\"AUP_On\">";
		echo "<input type=submit value=".gettext('Enable Auto Shift').">";
		}
	echo "</FORM>";
	echo "</td></tr>";
	echo "<tr><td valign=\"middle\" align=\"left\" colspan=10>";
	echo "<FORM action='$_SERVER[PHP_SELF]?dgfile=Blacklist filtering' method=POST>";
	echo "<input type='hidden' name='choix' value='MAJ_cat'>";
	echo "<center>".gettext('Choice of filtered categories')."</center></td></tr>";
	//on lit et on interprète le fichier de catégories
	$cols=1; 
	if (file_exists($bl_categories))
		{
		$pointeur=fopen($bl_categories,"r");
		while (!feof ($pointeur))
			{
			$ligne=fgets($pointeur, 4096);
			if ($ligne)
				{
				if ($cols == 1) { echo "<tr>";}
				$categorie=trim(basename($ligne));
				echo "<td><a href='bl_categories_help.php?cat=$categorie' target='cat_help' onclick=window.open('bl_categories_help.php','cat_help','width=600,height=150,toolbar=no,scrollbars=no,resizable=yes') title='categories help page'>$categorie</a><br>";
				echo "<input type='checkbox' name='chk-$categorie'";
				// la catégorie n'existe pas dans le fichier de catégorie activé -> categorie non selectionnée
							$str = file_get_contents($bl_categories_enabled);
				if (strpos($str, $categorie)===false) { echo ">";}
				else { echo "checked>"; }
				echo "</td>";
				$cols++;
				if ($cols > 10) {
					echo "</tr>";
					$cols=1; }
				}
			}
		fclose($pointeur);
		}
	else	{
		echo gettext('Error opening the file')." $bl_categories";
		}
	echo "</td></tr>";
	echo "<tr><td valign='middle' align='left' colspan=10></td></tr>";
	echo "<tr><td colspan=5 align=center>";
	echo "<H3>".gettext('Rehabilitated domain names')."</H3>".gettext('1-Enter here domain names that are blocked by the blacklist and you want to rehabilitate.')."<BR>".gettext('Enter one domain name per row (example : .domain.org)')."<BR>";
	echo "<textarea name='OSSI_wl_domains' rows=5 cols=40>";
	echo_file ($wl_domains);
	echo "</textarea></td>";
	echo "<td colspan=5 align=center>";
	echo "<H3>".gettext('Filtered domain names')."</H3>".gettext('Enter one domain name per row (example : .domain.org)')."<BR>";
	echo "<textarea name='OSSI_bl_domains' rows=5 cols=40>";
	echo_file ($bl_domains);
	echo "</textarea></td>";
	echo "</tr><tr><td colspan=10>";

	echo "<input type='submit' value='".gettext('Save changes')."'>";
	echo "</form> ".gettext('Once validated, 30 seconds is necessary to compute your modifications')." ";

	echo "</td></tr>";
	echo "</TABLE>";
	echo "</TABLE>";





?>

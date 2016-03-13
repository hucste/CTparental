<?php
## affichage des formulaires

echo "<table width='100%' border=1 cellspacing=0 cellpadding=1>";
	echo "<CENTER><H3>".gettext('E2guardian configuration')."</H3></CENTER>";

	
	echo "<tr><td colspan=2 align='center'>";
	echo gettext('Select the mimetype has filtered')."</td></tr>";
	echo "<tr><td align='center' valign='middle'>";
	echo "<FORM action='$_SERVER[PHP_SELF]?dgfile=mimetype has filtered' method='POST'>";
	//echo "<input type='hidden' name='choix' value='change_banext'>";
	//echo "<input type='submit' value=".gettext('Save changes').">";
	echo "<table cellspacing=2 cellpadding=2 border=1>";
	echo "<tr><th>".$dg_file_edit."<th></tr>";
	// Read the bannedextensionlist file
	$tab=file($dg_file_edit);
	if ($tab)  # the file isn't empty
		{
		$chknum=1;
		foreach ($tab as $ligne)
			{
			if (trim($ligne) != '') # the line isn't empty
				{
					
					$ext_lignes=explode(" ", $ligne);
					$ext=trim($ext_lignes[0],"#");
					if(preg_match('/^#/',$ligne)) {
						echo "<tr><td>".substr($ligne,1);
					}
					else {
						echo "<tr><td>".$ligne;
					}
					
					if (strstr($ext_lignes[0],'/') ) {
						echo "<td><input type='checkbox' name='chk-$chknum'";
						if (preg_match('/^#/',$ligne)) {
							echo ">";}
						else {
							echo "checked>";}
						echo "</tr>";
					}
				}
			$chknum=$chknum+1;
			}
		}
	echo "</table>";
	echo "<input type='hidden' name='choix' value='change_file1'>";
	echo "<input type='submit' value=".gettext('Save changes').">";
	echo "</form>";


?>




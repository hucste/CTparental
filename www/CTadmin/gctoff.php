<?php
echo "<table width='100%' border=1 cellspacing=0 cellpadding=1>";
echo "<CENTER><H3>".gettext('privileged group')."</H3></CENTER>";
echo "<tr><td colspan=2 align='center'>";
if ($GCTOFF == "ON")
	{
	echo "<CENTER><H3>".gettext('The preferred Group is currently enabled')."</H3></CENTER>";
 	echo "<FORM action='$_SERVER[PHP_SELF]?dgfile=privileged group' method=POST>";
	echo "<input type=hidden name='choix' value=\"gct_Off\">";
	echo "<input type=submit value=".gettext('Disable privileged group.').">";
	echo "</FORM>";

	
	echo "<tr><td colspan=2 align='center'>";
	echo gettext('Select users who should not undergo screening')."</td></tr>";
	echo "<tr><td align='center' valign='middle'>";
	echo "<FORM action='$_SERVER[PHP_SELF]?dgfile=privileged group' method='POST'>";
	echo "<table cellspacing=2 cellpadding=2 border=1>";
	echo "<tr><th>".gettext('Username')."<th></tr>";
	// Read the "CTOFF.conf" file
	exec ("sudo /usr/local/bin/CTparental.sh -gctulist");
	$tab=file($conf_ctoff_file);
	if ($tab)  # the file isn't empty
		{
		foreach ($tab as $line)
			{
			if (trim($line) != '') # the line isn't empty
				{
				$user_lignes=explode(" ", $line);
				$userx=trim($user_lignes[0],"#");
				echo "<tr><td>$userx";
				echo "<td><input type='checkbox' name='chk-$userx'";
				if (preg_match('/^#/',$line, $r)) {
					echo ">";}
				else {
					echo "checked>";}
				echo "</tr>";
				}
			}
		}
	
	echo "</table>";
	echo "<input type='hidden' name='choix' value='change_user'>";
	echo "<input type='submit' value=".gettext('Save changes').">";
	echo "</form>";
}
else
	{
	echo "<CENTER><H3> ".gettext('The preferred Group is currently disabled')."</H3></CENTER>";
 	echo "<FORM action='$_SERVER[PHP_SELF]?dgfile=privileged group' method=POST>";
	echo "<input type=hidden name='choix' value=\"gct_On\">";
	echo "<input type=submit value=".gettext('Enable privileged group.').">";
	echo "</FORM>";
	}






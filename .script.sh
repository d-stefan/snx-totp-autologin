	#!/bin/sh
	export BW_CLIENTID="<API Client ID>"
	export BW_CLIENTSECRET="<API Client Secret>"
	export BW_PASSWORD="<Bitwarden password>"
	snx -d
	bw logout
	bw login --apikey $BW_CLIENTID $BW_CLIENTSECRET
	bw unlock --passwordenv BW_PASSWORD
	BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD| tail -1 | awk '{print $6}')
	export BW_SESSION
	(echo '<LoginPassword>|'`bw get totp <Item ID>`)|snx
	bw logout

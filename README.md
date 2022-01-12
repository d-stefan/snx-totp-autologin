### Automatic login to Checkpoint VPN from terminal

#### Steps:
* Install Checkpoint SNX
* Install Bitwarden CLI
* Create script to tie the two together
* Encrypt script with hard coded api keys and passwords
* Create script to decrypt and `eval` results

##### Installing Checkpoint SNX

1. Install `snx`  
 For Debian and Debian-based 64-bit systems like Ubuntu and Linux Mint, you might need to add the 32-bit architecture:  
 
	 `sudo dpkg --add-architecture i386 && sudo apt-get update`  
	 
	Install the following 32-bit packages:  
	
	`sudo apt-get install libstdc++5:i386 libx11-6:i386 libpam0g:i386`

	Run then the `snx` installation script:
	```
	chmod a+rx snx_install.sh
	sudo ./snx_install.sh
	```  
	Now we have a /usr/bin/snx 32-bit client binary executable. Check if any dynamic libraries are missing with:  
	
	`sudo ldd /usr/bin/snx`  
	
	You can move on to the next point only after all the dependencies are satisfied.
	
2.  Before using it, you create a `~/.snxrc file, using your regular user (not root)` with the following contents:  
    ```
    server IP_address_of_your_VPN
    username YOUR_USER
	  reauth yes
	  ```
		    
3. For connecting, type `snx`. For disconnecting, type `snd -d`.

##### Installing Bitwarden CLI  

1. Download binary using, making sure to update for the latest version:  

	`wget --no-check-certificate --server-response https://github.com/bitwarden/cli/releases/download/v1.20.0/bw-linux-1.20.0.zip`  

2. Move binary to `/usr/bin` using:  

	`mv ./bw /usr/bin`
3. Make binary executable using:  

	`chmod +x /usr/bin/bw`
	
##### Creating script for auto-run
1. Create the following script to replicate the steps necessary to run `snx`, input password, retrieve and input OTP code:  

	```
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
	```
	
	The script temporarily adds `BW_CLIENTID`, `BW_CLIENTSECRET`, `BW_PASSWORD` and `BW_SESSION` as environment variables, logs out of VPN and Bitwarden before attempting to log in to both and then finally, logs out of the current Bitwarden session.  
	
2. In order to make sure that the hardcoded API keys and VPN Login passwords are not stored clearly, the script is encrypted using GnuPG by running the following command. **Making sure to delete the clear text version of the script after it's finished**!

	`gpgp -c ~/.script.sh`  
	
3. Since now we have an encrypted file `.script.sh.gpg`, it would require us to decrypt, run the script and then delete the unencrypted file each time, which would defeat the purpose of this exercise. So we'll create another script `vpn-connect` which decrypts the encrypted file and runs the result:
	```
	#!/bin/sh
	##Decrypts the VPN log in script and executes the result
	decrypted=$(gpg -d ./.script.sh.gpg)
	eval "$decrypted"
	```
4. Now all that's left is to move the auto-connect script to `/usr/bin/` and make it executable so that it's available to run from the terminal:
	```
	mv ./vpn-connect /usr/bin/
	chmod +x /usr/bin/vpn-connect
	```
5. Now when you open the terminal and execute vpn-connect, it will connect to vpn without any further input.

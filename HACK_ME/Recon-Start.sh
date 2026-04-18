#!/bin/bash


# Debug: Print the received argument
echo "Received argument: $1"

# Check if IP address is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <IP Address>"
  exit 1
fi

IP="$1"

# Launch BUrpsuite
burpsuite & 

# Step 1: Open the IP in Firefox
echo "=========================="
echo "[*] 4 pings of $IP to check its up"
echo "=========================="
ping -c 3 $IP 


# Step 1: Open the IP in Firefox
echo "=========================="
echo "[*] Opening $IP in Firefox"
echo "=========================="
firefox "http://$IP" &

# Step 2: Perform a curl request to check the server response
echo "================================="
echo "[*] Running basic nmap for ports to $IP"
echo "================================="
sudo nmap -p- -Pn -n --open -vvv $IP -oG openPorts-nmap-starter-$IP.txt

# Step 3: Perform a curl request to check the server response
echo "================================="
echo "[*] Running curl request to $IP"
echo "================================="
curl -m 5 -I http://$IP > curl_$IP.txt
cat curl_$IP.txt


# Step 2: Perform an initial nmap scan (common ports)
echo "==================================="
echo "[*] Running initial Basic Nmap scan (top 1000 ports)"
echo "==================================="
nmap -oN initial_nmap_$IP.txt $IP



# Step : DNSENUM 100 thread
echo "==================================="
echo "[*] Running DNSenum"
echo "==================================="
dnsenum $IP --threads 100



# Step 4: Run a comprehensive nmap scan (all ports)
echo "===================================="
echo "[*] Running comprehensive Nmap scan (all open ports)"
echo "===================================="
nmap -p- -sC -sV -oN FULL_nmap_$IP.nmap $IP --open


# Step : Deeper DNSENUM 100 thread
echo "==================================="
echo "[*] Running Deeper DNSenum"
echo "==================================="
dnsenum --enum --dnsserver 8.8.8.8 --threads 10 --scrap 50 --pages 10 --file /usr/share/wordlists/seclists/Discovery/DNS/shubs-subdomains.txt --recursion --whois --output results-of-$IP.xml $IP


# Step : Createing a starter Contextual FuzzList with Cewl
echo "==================================="
echo "[*] Running Cewl to make a starter Contextual FuzzList : ContextualFuzzList.txt"
echo "==================================="
cewl http://$IP -m 5 >> ContextualFuzzList.txt
# gets rid of the dupes
awk '!seen[$0]++' ContextualFuzzList.txt > TempFile && mv TempFile ContextualFuzzList.txt

# Step 5: Run GoBuster to enumerate directories
echo "===================================="
echo "[*] Running GoBuster to enumerate directories"
echo "===================================="
# gobuster dir -u $IP -w /usr/share/seclists/Discovery/Web-Content/raft-medium-words-lowercase.txt -t 20 -o gobuster_$IP.txt
feroxbuster -u http://$IP -t 100 -x php,html,txt --rate-limit 200 --depth 4 --redirects --force-recursion -o Ferox-initial-p80_scanof$IP.txt


# Final output
echo "===================================="
echo "[*] Intial Enumeration complete for $IP"
echo "===================================="

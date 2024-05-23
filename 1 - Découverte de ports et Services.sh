                                               #### 1 - Découverte de ports et Services ####


decouverte_ports_services() {
    echo -e "${bleu}#### Découverte de ports et Services ####${reset}"
    

    nmap_cmd=$(nmap -sV $ip_cible)
    
#extrait et afficher les ports ouverts et les versions des services
    open_ports=$(echo "$nmap_cmd" | grep -E "^[0-9]+/tcp" | grep "open" | awk '{print $1, $3, $4}')
    
    if [ -n "$open_ports" ]; then
        echo "Voici les ports ouverts sur l'adresse $ip_cible :"
        echo "$open_ports"
    else
        echo "Aucun port n'est ouvert sur l'adresse $ip_cible."
        return  
    fi
}

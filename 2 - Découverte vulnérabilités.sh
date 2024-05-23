                                       #### 2 - Découverte de vulnérabilités ####


decouverte_vulnerabilites() {
    echo -e "${bleu}#### Découverte de vulnérabilités ####${reset}"
    
    # Récupère les infos de la liste des ports et affiche leurs vulnérabilités
    open_ports=$(echo "$nmap_cmd" | grep "open" | awk '{print $1}' | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')
    
    echo "Recherche des vulnérabilités connues sur les ports ouverts :"
    vuln_scan=$(nmap --script vulners -sV -p$open_ports $ip_cible)
    
    vuln_info=$(echo "$vuln_scan" | grep "|_" -A 1)
    
    if [ -n "$vuln_info" ]; then
        echo "Voici les vulnérabilités trouvées :"
        echo "$vuln_info"
    else
        echo "Aucune vulnérabilité connue trouvée sur les ports ouverts."
    fi
}

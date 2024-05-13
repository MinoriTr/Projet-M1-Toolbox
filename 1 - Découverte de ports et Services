#!/bin/bash

#1 - Découverte ports et Services
# Demander à l'utilisateur de saisir l'adresse IP cible
read -p "Entrez l'adresse IP cible : " ip_cible

# Valider l'adresse IP saisie par l'utilisateur
if ! [[ $ip_cible =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Adresse IP invalide. Veuillez entrer une adresse IP valide"
    exit 1
fi

echo "Adresse IP valide : $ip_cible"

# Tentative de connexion au port
nmap_cmd=$(nmap -O $ip_cible)

# Vérifier si des ports sont ouverts
if [[ $nmap_cmd =~ "open" ]]; then
    echo  "voici les ports ouverts $ip_cible :"
    echo "$nmap_cmd" 
else
    echo "Aucun port n'est ouvert sur $ip_cible."
fi



# 2 - Découverte vulnérabilités
# Extrait la liste des ports ouverts
open_ports=$(echo "$nmap_cmd" | grep succeeded | awk '{print $5}' | cut -d'/' -f1)

# Utilise Nmap pour rechercher les vulnérabilités sur les ports ouverts
echo "Recherche des vulnérabilités connues sur les ports ouverts :"
nmap -sV --script vulners -p 1-1024 $open_ports $ip_cible

# Supprime le fichier temporaire
# rm scan_result.txt # Il n'y a pas de fichier scan_result.txt dans ce code

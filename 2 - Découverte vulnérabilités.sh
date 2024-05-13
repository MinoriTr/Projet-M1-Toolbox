#!/bin/bash

# 2 - Découverte vulnérabilités
# Extrait la liste des ports ouverts
open_ports=$(echo "$nmap_cmd" | grep succeeded | awk '{print $5}' | cut -d'/' -f1)

# Utilise Nmap pour rechercher les vulnérabilités sur les ports ouverts
echo "Recherche des vulnérabilités connues sur les ports ouverts :"
nmap -sV --script vulners -p 1-1024 $open_ports $ip_cible

# Supprime le fichier temporaire
# rm scan_result.txt # Il n'y a pas de fichier scan_result.txt dans ce code

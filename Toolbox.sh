#!/bin/bash

#### 1 - Découverte ports et Services ####

echo -e "\033[34m#### 1 - Découverte ports et Services ####\033[0m"
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

        ##### 2 - Découverte vulnérabilités #####

echo -e "\033[34m#### 2 - Découverte vulnérabilités ####\033[0m"

# Extrait la liste des ports ouverts
open_ports=$(echo "$nmap_cmd" | grep succeeded | awk '{print $5}' | cut -d'/' -f1)

# Utilise Nmap pour rechercher les vulnérabilités sur les ports ouverts
echo "Recherche des vulnérabilités connues sur les ports ouverts :"
nmap -sV --script vulners -p 1-1024 $open_ports $ip_cible

# Supprime le fichier temporaire
# rm scan_result.txt # Il n'y a pas de fichier scan_result.txt dans ce code

            #### 3 - Analyse de mdp ####

echo -e "\033[34m#### 3 - Analyse de mdp ####\033[0m"

# vérifie si John the Ripper est déja installé
if ! command -v john &>/dev/null; then
    apt install john -y
fi

# vérifie si le fichier dictionnaire de mdp existe
fichier_dictionnaire="rockyou.txt"
if [ ! -f "$fichier_dictionnaire" ]; then
    echo "Erreur : Le fichier de dictionnaire '$fichier_dictionnaire' n'existe pas."
    exit 1
fi

# demande à l'user de saisir le mdp à analyser
read -sp "Entrez votre mot de passe : " mdp


#le mdp est basé sur une politique de mdp pour établir sa robustesse
#vérifie la longueur du mdp
if [ ${#mdp} -ge 14 ]; then
    longueur_mdp=true
else
    longueur_mdp=false
fi

# vérifie le nombre de majuscules
majuscule=$(echo "$mdp" | grep -o '[[:upper:]]' | wc -l)
if [ $majuscule -ge 2 ]; then
    majuscule_ok=true
else
    majuscule_ok=false
fi

# vérifie la présence de caractères spéciaux
if echo "$mdp" | grep -q '[^[:alnum:]]'; then
    caractere_spe=true
else
    caractere_spe=false
fi

# détermine la force du mdp
if $longueur_mdp && $majuscule_ok && $caractere_spe; then
    echo "Mot de passe fort."
elif [ ${#mdp} -gt 9 ] && [ $majuscule -gt 1 ] && ! $caractere_spe; then
    echo "Mot de passe acceptable."
else
    echo "Mot de passe faible."
fi

# vérifie si le mot de passe est présent dans le dictionnaire
if john --wordlist="$fichier_dictionnaire" --stdout | grep -q "$mdp"; then
    echo "Le mot de passe renseigné est un mot de passe commun."
fi

#si le mot de passe se trouve dans le dico il est potentiellement compromis
if $longueur_mdp && $majuscule_ok && $caractere_spe && john --wordlist="$fichier_dictionnaire" --stdout | grep -q "$mdp"; then
    echo "Mot de passe potentiellement compromis."
fi

                ##### 4 - Test d'authentification ####

echo -e "\033[34m##### 4 - Test d'authentification ####\033[0m"

#demande les identifiants de connexions ( login user et mot de passe )

read -sp "veuillez entrer votre login : "  login_user
read -sp "veuillez entrer votre mot de passe : " mdp_user

 auth_cmd=$(ssh -p 22 $login_user@$ip_cible)

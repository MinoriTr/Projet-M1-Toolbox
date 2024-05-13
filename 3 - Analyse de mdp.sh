#!/bin/bash

#3 - Analyse de mdp
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
echo

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

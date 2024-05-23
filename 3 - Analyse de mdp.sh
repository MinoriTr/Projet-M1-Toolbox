 #### 3 - Analyse de mot de passe ####


analyse_mot_de_passe() {
    echo -e "${bleu}#### Analyse de mot de passe ####${reset}"
    
#vérifie si John the Ripper est installé, si non, l'installe
    if ! command -v john &>/dev/null; then
        apt install john -y
    fi

#vérifie la présence duu fichier dictionnaire 
    fichier_dictionnaire="rockyou.txt"
    if [ ! -f "$fichier_dictionnaire" ]; then
        echo "Erreur : Le fichier de dictionnaire '$fichier_dictionnaire' n'existe pas."
        return  
    fi

    read -sp "Entrez votre mot de passe : " mdp
    echo

#le mot de passe est basé sur une politique de mot de passe pour établir sa robustesse
#vérifie la longueur du mot de passe
    if [ ${#mdp} -ge 14 ]; then
        longueur_mdp=true
    else
        longueur_mdp=false
    fi

    # Vérifie le nombre de majuscules
    majuscule=$(echo "$mdp" | grep -o '[[:upper:]]' | wc -l)
    if [ $majuscule -ge 2 ]; then
        majuscule_ok=true
    else
        majuscule_ok=false
    fi

    # Vérifie la présence de caractères spéciaux
    if echo "$mdp" | grep -q '[^[:alnum:]]'; then
        caractere_spe=true
    else
        caractere_spe=false
    fi

    # Détermine la force du mot de passe
    if $longueur_mdp && $majuscule_ok && $caractere_spe; then
        echo -e "${vert}Mot de passe robuste${reset}"
    elif [ ${#mdp} -gt 9 ] && [ $majuscule -gt 1 ] && ! $caractere_spe; then
        echo -e "${jaune}Mot de passe acceptable${reset}"
    else
        echo -e "${rouge}Mot de passe faible${reset}"
    fi

    # Vérifie si le mot de passe est présent dans le dictionnaire
    if john --wordlist="$fichier_dictionnaire" --stdout | grep -q "$mdp"; then
        echo -e "${rouge}Le mot de passe renseigné est un mot de passe commun${reset}"
    fi

    # Si le mot de passe se trouve dans le dictionnaire, il est potentiellement compromis
    if $longueur_mdp && $majuscule_ok && $caractere_spe && john --wordlist="$fichier_dictionnaire" --stdout | grep -q "$mdp"; then
        echo "Mot de passe potentiellement compromis."
    fi
}

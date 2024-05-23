   #### 4 - Test d'authentification ####


test_authentification() {
    echo -e "${bleu}#### Test d'authentification ####${reset}"
    

    read -p "Veuillez entrer votre login : " login_user
    echo
    read -sp "Veuillez entrer votre mot de passe : " mdp_user
    echo

 
    sshpass -p "$mdp_user" ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o HostKeyAlgorithms=+ssh-rsa $login_user@$ip_cible 'exit'

    if [ $? -eq 0 ]; then
        echo "Connexion SSH réussie et terminée."
    else
        echo "Échec de la connexion SSH."
    fi
}

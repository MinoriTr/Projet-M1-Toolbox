#!/bin/bash

#test d'authentification 
#demande les identifiants de connexions ( login user et mot de passe )

read -sp "veuillez entrer votre login : "  login_user
read -sp "veuillez entrer votre mot de passe : " mdp_user

 auth_cmd=$(ssh -p 22 $login_user@$target_ip)

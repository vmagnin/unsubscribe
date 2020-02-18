#! /bin/bash
# Ce script permet de se désinscrire massivement de listes de diffusion
# indésirables.
# Licence GNU GPL v3
# Vincent MAGNIN, 2020-02-15
# Dernière modification le 2020-02-18

# Mode strict :
set -euo pipefail

# On vérifie la présence des arguments :
if [ ${#} -eq 0 ]; then
    echo "Usage : ${0} CHEMIN"
    echo "Se désinscrit des listes de diffusion reçues dans CHEMIN, qui peut"
    echo "être un fichier ou un répertoire qui sera parcouru récursivement."
    echo
    echo "Exemples :"
    echo "  $ ./unsubscribe.sh ~/.thunderbird/rfjzi2xb.default/Mail/pop.aliceadsl.fr/Junk"
    echo "  $ ./unsubscribe.sh ~/.monlogicieldemail/Junk/"
    echo
    echo "Documentation : https://github.com/vmagnin/unsubscribe/blob/master/README.md"
    exit 1
else
    readonly chemin="${1}"
fi

# Si le paramètre est un chemin, grep fonctionnera en mode récursif, sinon
# il n'analysera que le fichier indiqué :
if [ -d "${chemin}" ]; then
    recursif="-R"
    echo "directory"
elif [ -f "${chemin}" ]; then
    recursif=""
    echo "file"
else
    echo "Chemin non valide !"
    exit 2
fi

# On cherche avec grep les liens de désinscription dans les en-têtes des emails
# -E : Extended Regular Expression
# -A 1 : affiche une ligne de plus
# -o : ne garde que la partie correspondant au pattern
readonly liens="$(grep ${recursif} -A 1 "List-Unsubscribe: <" "${chemin}"  | grep -o -E "http[^>]+")"

# Compteurs :
n=0
echecs=0

# Ne pas mettre de guillemets autour de ${liens} pour que ça reste une liste !
for un_lien in ${liens}; do
    n=$((n + 1))
    
    # On se connecte avec wget et si ça échoue, on incrémente le compteur
    # d'échecs. 
    # -a : ajouter ("append") la sortie de wget au fichier de log.
    # -t : nombre d'essais ("tries").
    # -T : délai d'attente ("timeout").
    # -P : répertoire où seront téléchargés les fichiers.
    if ! wget -a unsubscribe.log -P téléchargés -t 2 -T 10 "${un_lien}"
    then
        echecs=$((echecs + 1))
        # On affiche un zéro pour marquer la progression...
        echo -n "0"
    else
        # On affiche des points à la suite pour marquer la progression...
        echo -n "."
    fi
done

echo
echo "Statistiques :"
echo "* Nombre de liens : ${n}"
echo "* Echecs de connexion : ${echecs}"
echo "Dans le répértoire 'téléchargés' :"
echo "* Nombre de ' bien ' : $(grep -iR ' bien ' | wc -l)"
echo "* Nombre de ' success' : $(grep -iR ' success' | wc -l)"

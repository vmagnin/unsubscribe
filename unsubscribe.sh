#! /bin/bash
# Pour se désinscrire massivement de listes de diffusion indésirables.
# Licence GNU GPL v3
# Vincent MAGNIN, 2020-02-15
# Dernière modification le 2020-02-21

# Mode strict :
set -euo pipefail

function usage(){
    echo "Usage : ${0} [OPTION]... CHEMIN"
    echo
    echo "Se désinscrit des listes de diffusion reçues dans CHEMIN, qui peut"
    echo "être un fichier ou un répertoire qui sera parcouru récursivement."
    echo
    echo "Options :"
    echo "  -h       afficher l'aide"
    echo "  -n       ne pas se désinscrire (simuler)"
    echo
    echo "Exemples :"
    echo "  $ ./unsubscribe.sh ~/.thunderbird/rfjzi2xb.default/Mail/pop.aliceadsl.fr/Junk"
    echo "  $ ./unsubscribe.sh ~/.monlogicieldemail/Junk/"
    echo
    echo "Documentation : https://github.com/vmagnin/unsubscribe/blob/master/README.md"
}

ne_rien_faire=false

# On analyse les options de la ligne de commandes :
while getopts hn option ; do
    case "$option" in
        h) usage ; exit 0 ;;           # Afficher l'aide
        n) ne_rien_faire=true ;;       # Ne pas télécharger
        ?) echo ; usage ; exit 1 ;;    # Options inconnues
    esac
done
# On saute les arguments de type option :
shift $((OPTIND - 1))
# On vérifie la présence des autres arguments 
# et on affiche l'usage en cas d'oubli :
if [ ${#} -eq 0 ]; then
    usage
    exit 1
else
    # On récupère le chemin fourni en ligne de commandes :
    readonly chemin="${1}"
fi

# Si le paramètre est un répertoire, grep fonctionnera en mode récursif, sinon
# il n'analysera que le fichier indiqué :
if [ -d "${chemin}" ]; then
    readonly recursif="-R"
    echo "Analyse récursive du répertoire... Soyez patients... "
elif [ -f "${chemin}" ]; then
    readonly recursif=""
    echo "Analyse du fichier fourni... Soyez patients... "
else
    echo "Chemin non valide !"
    exit 2
fi

# On cherche avec grep les liens http(s) de désinscription dans les champs 
# List-Unsubscribe (ou X-List-Unsubscribe) des en-têtes des courriels.
# Options de grep :
# -z : remplace les retours à la ligne par des octets nuls
# -P : Perl-compatible regular expressions (PCREs)
# -o : ne garde que la partie correspondant au motif
# La commande tr fait l'opération inverse.
readonly liens="$(grep ${recursif} -zPo 'List-Unsubscribe:\s+?(?:<mailto:[^>]+?>,\s*?)?<http[s]?://[^>]+?>' "${chemin}" | tr '\000' '\n' | grep -Po 'http[s]?://[^>]+')"

# Compteurs :
n=0
echecs=0

# Ne pas mettre de guillemets autour de ${liens} pour que ça reste une liste !
for un_lien in ${liens}; do
    n=$((n + 1))
    
    if ${ne_rien_faire}  ; then
        echo "${un_lien}"
    else
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
    fi
done

echo
echo "Statistiques :"
echo "* Nombre de liens : ${n}"
echo "* Echecs de connexion : ${echecs}"
echo "Dans le répertoire 'téléchargés' :"
echo "* Nombre de ' bien ' : $(grep -iR ' bien ' téléchargés/ | wc -l)"
echo "* Nombre de ' success' : $(grep -iR ' success' téléchargés/ | wc -l)"
echo "* Nombre d'erreurs : $(grep -iRE 'err(eu|o)r' téléchargés/ | wc -l)"

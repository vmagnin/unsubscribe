#! /bin/bash
# Ce script permet de se désinscrire massivement de listes de diffusion
# indésirables.
# Licence GNU GPL v3
# Vincent MAGNIN, 2020-02-15
# Dernière modification le 2020-02-16

# Mode strict :
set -euo pipefail

# On vérifie la présence des arguments :
if [ ${#} -eq 0 ]; then
  echo "Usage : ${0} FICHIER"
  echo "Se désinscrit des listes de diffusion reçues dans FICHIER."
  echo "Exemple : ./unsubscribe.sh ~/.thunderbird/rfjzi2xb.default/Mail/pop.aliceadsl.fr/Junk"
  exit 1
else
  readonly fichier="${1}"
fi

# On cherche avec grep les liens de désinscription dans les en-têtes des emails
# -E : Extended Regular Expression
# -A 1 : affiche une ligne de plus
# -o : ne garde que la partie correspondant au pattern
readonly liens="$(grep -A 1 "List-Unsubscribe: <" "${fichier}"  | grep -o -E "http[^>]+")"

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

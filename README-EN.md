# Mass unsubscription of mailing lists

The ``unsubscribe.sh`` script allows the mass unsubscription from unwanted mailing lists. It is based on the ``List-Unsubscribe`` field defined by RFC 2369 (July 1998) and generally present in French advertising emails. This field contains links ``<mailto:>`` and/or ``<http:>` (or ``<https:>`). This script also detects non-standard ``X-List-Unsubscribe`` fields.

## Installation

* This script has been tested with the Mozilla Thunderbird email software but should work with any software that stores emails in text files.
* This ``bash`` script is essentially based on the ``grep`` and ``wget`` commands, which you may need to install separately. It should work on any UNIX-like system, including MSYS2 on Windows. But since there are many variants of the ``grep'' commands, if you encounter problems try to install GNU grep (it has been tested with version 3.3). Finally, with another shell, some minor modifications should be enough: in particular, the ``-o pipefail`` option can be removed without any problem.
* Clone the GitHub repository or download and extract the zip into a directory.

## Usage

### Preparation

* You can work on the "Undesirable" directory of your account or create a special directory in which you will move the emails you want to unsubscribe from.
* Il faut que les courriels aient été vraiment téléchargés sur votre disque (l'affichage du sujet du courriel ne suffit pas). Dans Thunderbird, s'ils n'ont pas été lus, il suffit de sélectionner l'ensemble des courriels et avec le bouton droit de cliquer sur "Relever les messages sélectionnés". Ou dans les propriétés du dossier d'aller dans l'onglet "Synchronisation" et de cliquer sur le bouton "Télécharger maintenant".
* Dans votre logiciel de courriel, par sécurité effacez du répertoire qui sera utilisé les éventuels courriels pouvant présenter un risque (hameçonnage...), même si l'utilisation de `wget` pour se connecter au web limite a priori énormément les risques par rapport à l'utilisation d'un navigateur.
* Utilisez l'éventuelle fonction "compacter les dossiers" afin d'éliminer définitivement du fichier les courriels déjà "effacés" (en fait simplement effacés de l'index).
* Repérez le chemin dans le système de fichiers du fichier ou du répertoire contenant les courriels à traiter. Vous pouvez aussi travailler sur une copie.

### Exécution

* Lancez le script soit en lui fournissant un fichier :

```bash
$ ./unsubscribe.sh  ~/.thunderbird/rfjzi2xb.default/Mail/pop.aliceadsl.fr/Junk
```
* soit en lui fournissant un répertoire dont il analysera tous les fichiers, sous-répertoires inclus :

```bash
$ ./unsubscribe.sh ~/.monlogicieldemail/Junk/
```

L'analyse par `grep` des fichiers peut prendre plusieurs dizaines de secondes pour un millier de pourriels. Ensuite, le script affiche sa progression dans les désinscriptions avec un point par lien ou un zéro en cas d'échec de la connexion (le lien peut par exemple ne plus être valide s'il date de plusieurs mois).

Les sorties de la commande ``wget`` sont ajoutées au fichier ``unsubscribe.log`` et les fichiers téléchargés sont enregistrés dans le répertoire ``téléchargés``. L'ensemble de ces fichiers vous permettra d'éventuellement identifier les désinscriptions qui ont échoué. Le script vous laisse la responsabilité d'y faire éventuellement le ménage.

Les champs comportant uniquement une adresse e-mail sont ensuite détectés et les adresses e-mail sont simplement collectées dans le fichier `courriels.log`. C'est à l'utilisateur d'exploiter ensuite ces adresses. Attention, un envoi massif de courriels de désinscription pourrait être mal interprété par votre fournisseur d'accès et vous risqueriez d'être filtré automatiquement comme *spammer*. Enfin, certaines adresses e-mail peuvent être suivies d'une chaîne du type `?subject=blablabla` qu'il appartiendra à l'utilisateur d'interpréter.

Enfin, le script affiche des statistiques vous permettant d'estimer le taux de succès de l'opération. 

### Options du script

* `-h` permet d'afficher l'aide.
* `-n` permet de ne pas se désinscrire. Le script affiche les liens trouvés mais `wget` n'est pas appelé.

## Limitations

Ce script échouera avec un petit pourcentage de pourriels car :

* certains courriels contiennent un lien ``<mailto:>`` mais pas de lien ``<http:>``,  
* certaines pages de désinscription demandent de confirmer en cliquant sur un bouton,
* les pourriels qui nous proviennent de l'étranger ne proposent pas toujours de champ ``List-Unsubscribe``, ou parfois les caractères contenus dans le champ sont encodés d'une façon qui empêche le script de trouver le lien.

Même si dans un premier temps le nombre de courriels reçus devrait être divisé au moins par trois, le traitement devra être probablement renouvelé régulièrement. Votre adresse e-mail étant en possession des spammeurs, vous risquez d'être inclus dans de nouvelles campagnes publicitaires. Mais je n'ai pas encore assez de recul pour en dire plus avec certitude.

## Références
* https://www.rfc-editor.org/info/rfc2369 
* https://litmus.com/blog/the-ultimate-guide-to-list-unsubscribe
* https://www.gnu.org/software/wget/ 
* La syntaxe de ce script a été vérifiée par l'utilitaire shellcheck : https://www.shellcheck.net/
* Bernard Desgraupes, *Introduction aux expressions régulières ; avec awk, Java, Perl, PHP, Tcl...* (2e édition), Paris : Vuibert, 2008, ISBN 978-2-7117-4867-9.
 

# Annexes

## Analyse de l'expression régulière pour les liens http://

La capture des liens est faite par la commande suivante :

```bash
grep ${recursif} -zPo 'List-Unsubscribe:\s+?(?:<mailto:[^>]+?>,\s*?)?<http[s]?://[^>]+?>' "${chemin}" 
| tr '\000' '\n' | grep -Po 'http[s]?://[^>]+'
```

* Le premier `grep` est chargé de détecter les champs `List-Unsubscribe`. Il n'est pas spécifié qu'ils doivent être en début de ligne, ce qui permet de détecter aussi les champs non standards `X-List-Unsubscribe`.
* L'option `-z` remplace les retours à la ligne du fichier par des octets nuls, ce qui va nous permettre de contourner le fait que `grep` cherche normalement les motifs dans chaque ligne d'un fichier, alors que les champs `List-Unsubscribe` occupent généralement une à trois lignes.
* L'option `-P` signifie *Perl-compatible regular expressions (PCREs)* qui est le type d'expressions régulières le plus complexe que gère la commande `grep`.
* L'option `-o` ne garde que la partie correspondant au motif détecté, au lieu de la ligne entière.
* `\s` désigne un caractère d'espacement, en particulier espace, tabulation, retour à la ligne, qui sont les trois caractères que l'on peut rencontrer à cet endroit. Le `+` indique qu'il y a au moins un caractère. Le `?` indique qu'il s'agit d'un quantificateur minimal : on inverse l'avidité du moteur d'expressions régulières pour capturer le moins de caractères possible jusqu'à la partie suivante de l'expression.
* `(?:` signifie que les parenthèses ne sont pas utilisées ici pour capturer un motif. La fermeture par `)?` signifie que la présence d'un lien `<mailto:>` à cet endroit est facultative (zéro ou un motif).
* `[^>]+?>` signifie que l'on cherche au moins un caractère différent d'un chevron fermant avant d'arriver à un chevron fermant.
* S'il y a un lien `<mailto:>` suivi d'un lien `<http:>`, il y aura une virgule suivi d'au moins un caractère d'espacement entre eux : parfois une espace si tout est sur la même ligne, ou un retour à la ligne et une espace ou une tabulation.
* Le `[s]?` (un s ou pas) permet de capturer aussi bien les liens `<http:>` que `<https:>`.
* La commande `tr` remplace les octets nuls par des retours à la ligne afin que le `grep` final puisse travailler ligne par ligne (pas de `-z` pour celui-là). 

## Analyse de l'expression régulière pour les liens mailto:

```bash
grep -oPz 'List-Unsubscribe:\s+?<mailto:[^>]+?>[^,]' "${chemin}" 
| tr '\000' '\n' | grep -oP '(?<=mailto:)[^>]+' > courriels.log
```

* `[^,]` : si le lien `<mailto:>` n'est pas suivi d'une virgule, il n'y a pas de lien `<http:>`.
* Dans le second `grep`, `(?<=mailto:)[^>]+` signifie que l'on cherche des caractères qui ne sont pas des chevrons fermants après un `mailto:`, qui lui ne sera pas capturé *(motif rétrospectif positif).*


-----

Vincent MAGNIN, premier commit : 2020-02-16





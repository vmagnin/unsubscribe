# Mass unsubscription of mailing lists

The `unsubscribe.sh` script allows the mass unsubscription from unwanted mailing lists. It is based on the `List-Unsubscribe` field defined by RFC 2369 (July 1998) and generally present in French advertising emails. This field contains links `<mailto:>` and/or `<http:>` (or `<https:>`). This script also detects non-standard `X-List-Unsubscribe` fields.

## Installation

* This script has been tested with the Mozilla Thunderbird email software but should work with any software that stores emails in text files.
* This `bash` script is essentially based on the `grep` and `wget` commands, which you may need to install separately. It should work on any UNIX-like system, including MSYS2 on Windows. But since there are many variants of the `grep` commands, if you encounter problems try to install GNU grep (it has been tested with version 3.3). Finally, with another shell, some minor modifications should be enough: in particular, the `-o pipefail` option can be removed without any problem.
* Clone the GitHub repository or download and extract the zip into a directory.

## Usage

### Preparation

* You can work on the "Spam" directory of your account or create a special directory in which you will move the emails you want to unsubscribe from.
* The e-mails must be physically present (downloaded) on your local hard drive (displaying the subject of the e-mail is not enough). In Thunderbird, if they have not been marked as read, just select all the emails and right click on "Read selected messages". Or in the folder properties go to the "Synchronization" tab and click on the "Download Now" button.
* For security reasons, it is advised to delete any e-mails that may present a risk (phishing...) from the directory that will be used (in your e-mail client), even if the use of `wget` to connect to the web theoretically limits the risks (compared to using a browser).
* Use the "compact folders" function in order to permanently delete from the file the e-mails already "deleted" (in fact simply deleted from the index).
* Locate the path in the file system of the file or directory containing the e-mails to be processed. You can also work on a copy.

### Execute

* Run the script either by providing it with a :

``` bash
./unsubscribe.sh ~/.thunderbird/rfjzi2xb.default/Mail/pop.aliceadsl.fr/Junk
```
* either by providing it with a directory from which it will scan all the files, including subdirectories :

``` bash
$ ./unsubscribe.sh ~/.myemailsoftware/Junk/
```

The `grep` analysis of files can take some time (several tens of seconds) for a thousand spam messages. Then, the script displays its progress of unsubscriptions with a dot per link or a zero if the connection fails (for example, the link may no longer be valid if it is several months old).

The output of the `wget` command is added to the `unsubscribe.log` file and the downloaded files are saved in the `downloaded` directory. All these files will allow you to eventually identify unsubscriptions that have failed. The script leaves it up to you to clean it up if necessary.

Fields containing only an e-mail address are then detected and the e-mail addresses are simply collected in the file `emails.log`. It is then up to the user to use these addresses. Be careful, a mass sending of unsubscribe e-mails could be misinterpreted by your provider and you could be automatically filtered as *spammer*. Finally, some e-mail addresses may be followed by a string of the type `?subject=blablablabla` which it will be up to the user to interpret.

Finally, the script displays statistics allowing you to estimate the success rate of the operation. 

### Script options

* `-h` displays help.
* `-n` allows you to not unsubscribe. The script displays the links found but `wget` is not called.

## Limitations

This script will fail with a small percentage of spam because :

* some emails contain a `<mailto:>` link but no `<http:>` link,  
* some unsubscribe pages ask you to confirm by clicking a button,
* Spam that comes to us from abroad does not always offer a List-Unsubscribe field, or sometimes the characters in the field are encoded in a way that prevents the script from finding the link.

Even if the number of emails received should be divided by at least three at first, the treatment will probably have to be renewed regularly. Since your e-mail address is in the possession of spammers, you risk being included in new advertising campaigns. But I don't yet have enough hindsight to say more for sure.

## References
* https://www.rfc-editor.org/info/rfc2369 
* https://litmus.com/blog/the-ultimate-guide-to-list-unsubscribe
* https://www.gnu.org/software/wget/ 
* The syntax of this script has been checked by the shellcheck utility: https://www.shellcheck.net/
* Bernard Desgraupes, *Introduction to regular expressions; with awk, Java, Perl, PHP, Tcl...* (2nd edition), Paris: Vuibert, 2008, ISBN 978-2-7117-4867-9.
 

# Appendices

## Regular expression analysis for http:// links

The capture of links is done by the following command:

``` bash
grep ${recursive} -zPo 'List-Unsubscribe:\s+?(?:<mailto:[^>]+?>,\s*?)?<http[s]?://[^>]+?>' "${path}" 
| ? tr'000 ? grep -Po'http[s]?://[^>]+'
```

* The first `grep` is responsible for detecting the `List-Unsubscribe` fields. They are not required to be at the beginning of the line, it allows detection of non-standard `X-List-Unsubscribe' fields.
* The `-z` option replaces line breaks in the file with null bytes, which allows to get around the fact that `grep` normally looks for patterns in every line of a file, whereas `List-Unsubscribe` fields usually take up one to three lines.
* The `-P` option stands for *Perl-compatible regular expressions (PCREs)*, which is the most complex type of regular expression handled by the `grep` command.
* The `-o` option keeps only the portion corresponding to the detected pattern, instead of the entire line.
* `\s` designates a space character, in particular space, tab, and linebreak, which are the three characters that can be encountered at that location. The `+` indicates that there is at least one character. The `?` indicates that this is a minimal quantizer: we reverse the regular expression engine's greed to capture as few characters as possible to the next part of the expression.
* `(?:` means that parentheses are not used here to capture a pattern. Closing with `)?` means that the presence of a `<mailto:>` link at this location is optional (zero or a pattern).
* `[^>]+?>` means looking for at least one character other than a closing "Greater-than sign" (">") before arriving at a closing "Greater-than sign" (">").
* If there is a `<mailto:>` link followed by a `<http:>` link, there will be a comma followed by at least one space character between them: sometimes a space if everything is on the same line, or a line break and a space or tab.
* The `[s]?` (one or not s) can capture both `<http:>` and `<https:>` links.
* The `tr` command replaces null bytes with linebreaks so that the final `grep` can work line-by-line (no `-z` for this one). 

## Regular expression parsing for mailto links:

``` bash
grep -oPz 'List-Unsubscribe:\s+?<mailto:[^>]+?>[^,]' "${path}" 
| ? tr '000' 'grep -oP '(?<=mailto:)[^>]+' > e-mails.log
```

* `[^,]`: if the `<mailto:>` link is not followed by a comma, there is no `<http:>` link.
* The second `grep`, `(?<=mailto:)[^>]+` command means looking for characters that are different than the closing "Greater-than sign" (">") after a `mailto:`, which will not be captured *(positive retrospective pattern).*


-----

Vincent MAGNIN, first commit: 2020-02-16




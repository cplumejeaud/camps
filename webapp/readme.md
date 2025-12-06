# webapp eurocamps.plumegeo.fr

Cette application propose une visualisation interactive des camps en Europe, base de données complétée et qualifiée de mars 2025, en collaboration avec Louis Fernier, doctorant à Migrinter. 

L'application a été développée dans le cadre du <i>Master 2 SPE à La Rochelle, UE Data to Information</i>, en décembre 2025, sous la responsabilité de <a href="https://migrinter.cnrs.fr/membres/christine-plumejeaud-perreau/">Christine Plumejeaud-Perreau</a>, 
enseignante de l'UE par des étudiants du Master 2 SPE : 
<ul>
  <li>Damien Glo,</li>
  <li>Killian Lheote,</li>
  <li>Joseph Fournier.</li>
</ul>
<br>C'est un <b>prototype</b> visant à démontrer les capacités d'exploration et visualisation des profils des camps avec Python (3.10). 
Il nécessite des améliorations pour une utilisation en production (en particulier pour le formulaire de saisie de nouveaux camps qui ne fonctionne pas). 
Le code source est disponible sur le github de l'enseignante, sous licence Affero GPL v3.

## Allure de l'application

![Interface_2025-12-05](./Interface_2025-12-05.png)

Attention "Ajouter un nouveau camps" ne marche pas. Ce sera modifié plus tard.

## Installation

http://eurocamps.plumegeo.fr

### environnement virtuel et wsgi

Si nécessaire, le fichier wsgi peut être édité avec *vi* ou *nano* sous Linux. Voir ce site https://www.linuxtricks.fr/wiki/guide-de-sur-vi-utilisation-de-vi

`vi eurocamps.wsgi`
```py
import sys
sys.path.insert(0, '/var/www/eurocamps')

from Code_projet_Vfinale import app as application
```

Installation d'un environnement virtuel pour python 3.10 dans ce répertoire
`cd ~/eurocamps`
`python3.10  -m venv py310-venv`

Environnement virtuel dans : 
- /home/cperreau/eurocamps/py310-venv

**entrer**
`source py310-venv/bin/activate`

**installer des packages listés dans un fichier requirements_venv.txt**
`pip3 install -r ../requirements_20251206.txt`

**intaller le module WSGI** / Successfully installed mod_wsgi-5.0.2
`pip install mod_wsgi --use-pep517`

`mod_wsgi-express module-config`
```sh
LoadModule wsgi_module "/home/cperreau/eurocamps/py310-venv/lib/python3.10/site-packages/mod_wsgi/server/mod_wsgi-py310.cpython-310-x86_64-linux-gnu.so"
WSGIPythonHome "/home/cperreau/eurocamps/py310-venv"
```

**sortir**
`deactivate`

### config Apache2

Supprimer mes Ctrl^M génants de Windows parfois
```sh
for fic in $(find /home/cperreau/eurocamps -type f -name "*.py"); do sudo dos2unix $fic; done
```

Attention, il faut qu'Apache2 (user :www-data) ait accès à votre environnement virtuel (en lecture et exécution, r+x)
```sh
sudo chown :www-data /home/cperreau/eurocamps/ -R
sudo chmod 755 /home/cperreau/eurocamps/ -R
```
Lier les sources à un répertoire fictif apache
`sudo ln -s  /home/cperreau/eurocamps/ /var/www/eurocamps`

DNS : eurocamps.plumegeo.fr
créer un mapping sur votre fournisseur de DNS : CNAME avec romarin.huma-num.fr.

Il faut reporter ces infos dans le fichier de config **eurocamps.conf** ci-dessous

`sudo vi /etc/apache2/sites-available/eurocamps.conf`
```sh
<VirtualHost *:80>
    ServerName eurocamps.plumegeo.fr
    DocumentRoot /var/www/eurocamps

    LoadModule wsgi_module "/home/cperreau/eurocamps/py310-venv/lib/python3.10/site-packages/mod_wsgi/server/mod_wsgi-py310.cpython-310-x86_64-linux-gnu.so"
    WSGIDaemonProcess eurocamps python-home="/home/cperreau/eurocamps/py310-venv"
    WSGIProcessGroup eurocamps

    WSGIApplicationGroup %{GLOBAL}

    WSGIScriptAlias / /var/www/eurocamps/eurocamps.wsgi

    <Directory /var/www/eurocamps>
        Require all granted
    </Directory>

</VirtualHost>

```

`sudo a2ensite eurocamps` Pour démarrer la webapp
`sudo a2dissite eurocamps` Pour retirer la webapp

`sudo systemctl reload apache2` pour recharger la config et le code de la Webapp
`sudo systemctl restart apache2.service` pour stopper/redémarrer apache2

`sudo systemctl status apache2.service` : état du service Apache2

`sudo vi /var/log/apache2/error.log` : debugger et regarder les traces de la webapp

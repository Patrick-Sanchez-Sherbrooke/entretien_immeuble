// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Entretien Immeuble';

  @override
  String get loginTitle => 'Entretien des résidences';

  @override
  String get loginSubtitle => 'Connectez-vous pour continuer';

  @override
  String get loginErrorBadCredentials =>
      'Identifiant ou mot de passe incorrect';

  @override
  String get loginErrorNetwork => 'Erreur de connexion. Vérifiez votre réseau.';

  @override
  String get identifiant => 'Identifiant';

  @override
  String get pleaseEnterIdentifiant => 'Veuillez entrer votre identifiant';

  @override
  String get motDePasse => 'Mot de passe';

  @override
  String get pleaseEnterPassword => 'Veuillez entrer votre mot de passe';

  @override
  String get seConnecter => 'Se connecter';

  @override
  String get splashTitle => 'Entretien Immeuble';

  @override
  String get home => 'Accueil';

  @override
  String get sync => 'Synchroniser';

  @override
  String bonjour(Object name) {
    return 'Bonjour $name !';
  }

  @override
  String get roleAdmin => '👑 Administrateur';

  @override
  String get rolePlanificateur => '🗓 Planificateur';

  @override
  String get roleExecutant => '🔧 Exécutant';

  @override
  String get enCours => 'En cours';

  @override
  String get terminees => 'Terminées';

  @override
  String get total => 'Total';

  @override
  String get accesRapide => 'Accès rapide';

  @override
  String get nouvelleTache => 'Nouvelle\ntâche';

  @override
  String get listeDesTaches => 'Liste des\ntâches';

  @override
  String get calendrier => 'Calendrier';

  @override
  String get rapports => 'Rapports';

  @override
  String get drawerUser => 'Utilisateur';

  @override
  String get drawerVersion => 'V 1.0';

  @override
  String get archives => 'Archives';

  @override
  String get profil => 'Profil';

  @override
  String get gestionImmeubles => 'Gestion des immeubles';

  @override
  String get gestionUtilisateurs => 'Gestion des utilisateurs';

  @override
  String get support => 'Support';

  @override
  String get deconnexion => 'Déconnexion';

  @override
  String get annuler => 'Annuler';

  @override
  String get modifier => 'Modifier';

  @override
  String get supprimer => 'Supprimer';

  @override
  String get archiver => 'Archiver';

  @override
  String get desarchiver => 'Désarchiver';

  @override
  String get enregistrer => 'Enregistrer';

  @override
  String get langue => 'Langue';

  @override
  String get francais => 'Français';

  @override
  String get anglais => 'English';

  @override
  String get espagnol => 'Espagnol';

  @override
  String get pasDeConnexion => 'Pas de connexion internet';

  @override
  String get erreur => 'Erreur';

  @override
  String get erreurPrefix => 'Erreur: ';

  @override
  String erreurDb(Object msg) {
    return 'Erreur base de données: $msg';
  }

  @override
  String get storageErrorTitle => 'Problème de stockage';

  @override
  String get storageErrorMessage =>
      'L\'application ne peut pas accéder au stockage local (données ou préférences). Libérez de l\'espace ou réinstallez l\'app.';

  @override
  String get storageErrorContactSupport =>
      'Souhaitez-vous contacter le support par email ?';

  @override
  String get storageErrorContactSupportButton => 'Envoyer un email';

  @override
  String get storageErrorPrefsFailed =>
      'Impossible d\'accéder aux préférences. Les paramètres par défaut sont utilisés.';

  @override
  String get profilEnregistre => '✅ Profil enregistré';

  @override
  String profilEnregistreLocalDistant(Object msg) {
    return '✅ Profil enregistré en local. Distant : $msg';
  }

  @override
  String get nom => 'Nom';

  @override
  String get prenom => 'Prénom';

  @override
  String get telephone => 'Téléphone';

  @override
  String get email => 'Email';

  @override
  String get motDePasseOptionnel =>
      'Nouveau mot de passe (laisser vide pour ne pas changer)';

  @override
  String get immeuble => 'Immeuble';

  @override
  String get immeubleRequired => 'Immeuble *';

  @override
  String get selectionnerImmeuble => 'Sélectionner un immeuble';

  @override
  String get veuillezSelectionnerImmeuble =>
      'Veuillez sélectionner un immeuble';

  @override
  String get etage => 'Étage';

  @override
  String get chambre => 'Chambre';

  @override
  String chambreShort(Object num) {
    return 'Ch. $num';
  }

  @override
  String get descriptionTache => 'Description de la tâche *';

  @override
  String get veuillezEntrerDescription => 'Veuillez entrer une description';

  @override
  String get datePlanifiee => 'Date planifiée';

  @override
  String get nonDefinie => 'Non définie';

  @override
  String get tacheTerminee => 'Tâche terminée';

  @override
  String get tacheEnCours => 'Tâche en cours';

  @override
  String get planificateurNePeutPasCloturer =>
      'Le planificateur ne peut pas clôturer une tâche';

  @override
  String get faitLe => 'Fait le';

  @override
  String get executePar => 'Exécuté par';

  @override
  String get noteExecution => 'Note d\'exécution';

  @override
  String get ajouterUneTache => 'Ajouter une tâche';

  @override
  String get modifierLaTache => 'Modifier la tâche';

  @override
  String modifierLaTacheNum(Object num) {
    return 'Modifier la tâche #$num';
  }

  @override
  String get photo => 'Photo';

  @override
  String get ajouterPhoto => 'Ajouter une photo';

  @override
  String get supprimerPhoto => 'Supprimer';

  @override
  String tacheCreee(Object num) {
    return '✅ Tâche #$num créée';
  }

  @override
  String get tacheModifiee => '✅ Tâche modifiée';

  @override
  String get tacheEnregistreeSyncAuRetour =>
      'Tâche enregistrée. Synchronisation (photo comprise) au retour du réseau.';

  @override
  String tacheCreeeOuModifieeDistant(Object msg, Object syncError) {
    return '$msg (distant : $syncError)';
  }

  @override
  String get datePlanificationPosterieure =>
      '❌ La date de planification doit être postérieure à la date du jour';

  @override
  String get listeTaches => 'Liste des tâches';

  @override
  String get filtreImmeuble => 'Immeuble';

  @override
  String get toutes => 'Toutes';

  @override
  String get actifs => 'Actifs';

  @override
  String get supprimerTacheConfirm => 'Supprimer la tâche ?';

  @override
  String supprimerTacheConfirmContent(Object num, Object desc) {
    return 'Voulez-vous vraiment supprimer la tâche $num ?\n\n\"$desc\"';
  }

  @override
  String get archiverTacheConfirm => 'Archiver la tâche ?';

  @override
  String archiverTacheConfirmContent(Object num, Object desc) {
    return 'Voulez-vous archiver la tâche $num ?\n\n\"$desc\"';
  }

  @override
  String get tacheSupprimee => '🗑️ Tâche supprimée';

  @override
  String tacheSupprimeeDistant(Object msg) {
    return '🗑️ Tâche supprimée (distant : $msg)';
  }

  @override
  String get tacheArchivee => '📦 Tâche archivée';

  @override
  String tacheArchiveeDistant(Object msg) {
    return '📦 Tâche archivée (distant : $msg)';
  }

  @override
  String get aucuneTache => 'Aucune tâche';

  @override
  String tache(Object num) {
    return 'Tâche $num';
  }

  @override
  String get historique => 'Historique';

  @override
  String detailTache(Object num) {
    return 'Tâche $num';
  }

  @override
  String get historiqueModifications => 'Historique des modifications';

  @override
  String get aucuneTachePlanifiee => 'Aucune tâche planifiée ce jour';

  @override
  String tachesCount(Object count) {
    return '$count tâche(s)';
  }

  @override
  String get archiverImmeubleConfirm => 'Archiver l\'immeuble ?';

  @override
  String get desarchiverImmeubleConfirm => 'Désarchiver l\'immeuble ?';

  @override
  String archiverImmeubleQuestion(Object nom) {
    return 'Voulez-vous archiver « $nom » ?';
  }

  @override
  String desarchiverImmeubleQuestion(Object nom) {
    return 'Voulez-vous désarchiver « $nom » ?';
  }

  @override
  String get immeubleArchive => '📦 Immeuble archivé';

  @override
  String get immeubleDesarchive => '✅ Immeuble désarchivé';

  @override
  String get immeubleModifie => '✅ Immeuble modifié';

  @override
  String get immeubleAjoute => '✅ Immeuble ajouté';

  @override
  String immeubleModifieLocalDistant(Object msg) {
    return '✅ Immeuble modifié en local. Distant : $msg';
  }

  @override
  String immeubleAjouteLocalDistant(Object msg) {
    return '✅ Immeuble ajouté en local. Distant : $msg';
  }

  @override
  String get nouvelImmeuble => 'Nouvel immeuble';

  @override
  String get modifierImmeuble => 'Modifier l\'immeuble';

  @override
  String get adresse => 'Adresse';

  @override
  String get gestionDesImmeubles => 'Gestion des immeubles';

  @override
  String get archiverUtilisateurConfirm => 'Archiver l\'utilisateur ?';

  @override
  String get desarchiverUtilisateurConfirm => 'Désarchiver l\'utilisateur ?';

  @override
  String archiverUtilisateurQuestion(Object name) {
    return 'Voulez-vous archiver $name ?';
  }

  @override
  String desarchiverUtilisateurQuestion(Object name) {
    return 'Voulez-vous désarchiver $name ?';
  }

  @override
  String get utilisateurArchive => '📦 Utilisateur archivé';

  @override
  String get utilisateurDesarchive => '✅ Utilisateur désarchivé';

  @override
  String utilisateurArchiveDistant(Object msg) {
    return '📦 Utilisateur archivé (distant : $msg)';
  }

  @override
  String utilisateurDesarchiveDistant(Object msg) {
    return '✅ Utilisateur désarchivé (distant : $msg)';
  }

  @override
  String get gestionDesUtilisateurs => 'Gestion des utilisateurs';

  @override
  String get nouvelUtilisateur => 'Nouvel utilisateur';

  @override
  String get modifierUtilisateur => 'Modifier l\'utilisateur';

  @override
  String get role => 'Rôle';

  @override
  String get administrateur => 'Administrateur';

  @override
  String get planificateur => 'Planificateur';

  @override
  String get executant => 'Exécutant';

  @override
  String get motDePasseObligatoireCreation =>
      'Le mot de passe est obligatoire pour la création';

  @override
  String get responsableInformatique => 'Responsable informatique';

  @override
  String get supportDbErrorInfo =>
      'En cas d\'erreur de base de données, un email pourra être envoyé à cette adresse avec le détail de l\'erreur.';

  @override
  String syncSuccess(Object msg) {
    return '✅ $msg';
  }

  @override
  String syncSuccessCount(Object count) {
    return '✅ $count éléments synchronisés';
  }

  @override
  String syncWarning(Object msg) {
    return '⚠️ $msg';
  }

  @override
  String syncError(Object msg) {
    return '❌ $msg';
  }

  @override
  String synchronisation(Object msg) {
    return 'Synchronisation: $msg';
  }

  @override
  String get delaiDepasse => 'Délai dépassé';

  @override
  String get syncInterrompue => 'Synchronisation interrompue (délai dépassé)';

  @override
  String get rapportsTitre => 'Rapports';

  @override
  String get dateCreation => 'Date création';

  @override
  String get dateExecution => 'Date exéc.';

  @override
  String get executantLabel => 'Exécutant';

  @override
  String get rechercher => 'Rechercher';

  @override
  String get genererPdf => 'Générer le PDF';

  @override
  String get partager => 'Partager';

  @override
  String get aucunResultat => 'Aucun résultat';

  @override
  String get sessionExpiree => 'Session expirée';

  @override
  String enregistreLocalSync(Object msg) {
    return 'Enregistré en local. Sync serveur : $msg';
  }

  @override
  String planifieeLe(Object date) {
    return 'Planifiée le : $date';
  }

  @override
  String etageLabel(Object num) {
    return 'Étage $num';
  }

  @override
  String get monProfil => 'Mon profil';

  @override
  String get nomRequired => 'Nom *';

  @override
  String get prenomRequired => 'Prénom *';

  @override
  String get veuillezEntrerNom => 'Veuillez entrer le nom';

  @override
  String get veuillezEntrerPrenom => 'Veuillez entrer le prénom';

  @override
  String get min4Caracteres => 'Minimum 4 caractères';

  @override
  String get enregistrement => 'Enregistrement...';

  @override
  String get distantLabel => 'distant';

  @override
  String get aucunUtilisateur => 'Aucun utilisateur';

  @override
  String get exNom => 'Ex: Résidence Les Lilas';

  @override
  String get exAdresse => 'Ex: 12 rue des Fleurs';

  @override
  String get aucunImmeuble => 'Aucun immeuble';

  @override
  String get voirHistorique => 'Voir l\'historique';

  @override
  String get aucuneModificationEnregistree => 'Aucune modification enregistrée';

  @override
  String get tousLesImmeubles => 'Tous les immeubles';

  @override
  String creeeLe(Object date) {
    return 'Créée le : $date';
  }

  @override
  String termineeLe(Object date) {
    return 'Terminée le : $date';
  }

  @override
  String get statusArchivee => 'Archivée';

  @override
  String get statusArchivees => 'Archivées';

  @override
  String get aujourdHui => 'Aujourd\'hui';

  @override
  String get photoTravail => 'Photo du travail';

  @override
  String get photoAjoutee => 'Photo ajoutée';

  @override
  String get optionnel => 'Optionnel';

  @override
  String get changer => 'Changer';

  @override
  String get ajouter => 'Ajouter';

  @override
  String get creerLaTache => 'Créer la tâche';

  @override
  String get dateExecutionLong => 'Date d\'exécution';

  @override
  String get dateCreationDetail => 'Date de création';

  @override
  String dateEtHeure(Object date, Object time) {
    return '$date à $time';
  }

  @override
  String get execution => 'Exécution';

  @override
  String get statut => 'Statut';

  @override
  String get archivage => 'Archivage';

  @override
  String get parModification => 'Par :';

  @override
  String get inconnu => 'Inconnu';

  @override
  String get tacheCreeeSansNum => 'Tâche créée';

  @override
  String get photoExistante => 'Photo existante';

  @override
  String get nouvellePhoto => 'Nouvelle photo';

  @override
  String get photoSupprimee => 'Photo supprimée';

  @override
  String get description => 'Description';

  @override
  String tachesArchiveesCount(Object count) {
    return '$count tâche(s) archivée(s)';
  }

  @override
  String get desarchiverTacheConfirm => 'Désarchiver la tâche ?';

  @override
  String desarchiverTacheQuestion(Object num, Object desc) {
    return 'Voulez-vous désarchiver la tâche $num ?\n\n\"$desc\"';
  }

  @override
  String get tacheDesarchiveeRestore =>
      '✅ Tâche désarchivée et restaurée dans la liste';

  @override
  String get filtres => 'Filtres';

  @override
  String get filtresEtTri => 'Filtres et tri';

  @override
  String get reinitialiser => 'Réinitialiser';

  @override
  String get appliquer => 'Appliquer';

  @override
  String get dateModif => 'Date modif.';

  @override
  String get ordre => 'Ordre :';

  @override
  String get croissant => 'Croissant ↑';

  @override
  String get decroissant => 'Décroissant ↓';

  @override
  String get aucuneTacheArchivee => 'Aucune tâche archivée';

  @override
  String get reessayer => 'Réessayer';

  @override
  String erreurChargement(Object msg) {
    return 'Erreur de chargement : $msg';
  }

  @override
  String get pasDeConnexionArchives =>
      'Pas de connexion internet.\nLes archives sont stockées sur le serveur distant.';

  @override
  String get trierPar => 'Trier par :';

  @override
  String get ajouterCriterTri => 'Ajouter un critère de tri';

  @override
  String get genererRapport => 'Générer le rapport';

  @override
  String get chargement => 'Chargement...';

  @override
  String get croissantShort => 'Croissant';

  @override
  String get decroissantShort => 'Décroissant';

  @override
  String get retirerCriterTri => 'Retirer ce critère';

  @override
  String get statutLabel => 'Statut :';

  @override
  String resultatsCount(Object count) {
    return '$count résultat(s)';
  }

  @override
  String get partagerEmail => 'Partager par email';

  @override
  String get imprimer => 'Imprimer';

  @override
  String get identifiantRequired => 'Identifiant *';

  @override
  String get seraUtiliseConnexion => 'Sera utilisé pour la connexion';

  @override
  String get veuillezEntrerIdentifiant => 'Veuillez entrer un identifiant';

  @override
  String get min3Caracteres => 'Minimum 3 caractères';

  @override
  String get veuillezEntrerMotDePasse => 'Veuillez entrer un mot de passe';

  @override
  String get roleUtilisateur => 'Rôle de l\'utilisateur';

  @override
  String get descriptionRoleExecutant => 'Peut voir et exécuter les tâches';

  @override
  String get descriptionRolePlanificateur =>
      'Peut créer et planifier les tâches, mais pas les exécuter';

  @override
  String get descriptionRoleAdmin => 'Accès complet à l\'application';

  @override
  String get creerUtilisateur => 'Créer l\'utilisateur';

  @override
  String get utilisateurModifie => '✅ Utilisateur modifié';

  @override
  String get utilisateurCree => '✅ Utilisateur créé';
}

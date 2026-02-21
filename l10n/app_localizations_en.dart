// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Building Maintenance';

  @override
  String get loginTitle => 'Residence maintenance';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get loginErrorBadCredentials => 'Incorrect username or password';

  @override
  String get loginErrorNetwork => 'Connection error. Check your network.';

  @override
  String get identifiant => 'Username';

  @override
  String get pleaseEnterIdentifiant => 'Please enter your username';

  @override
  String get motDePasse => 'Password';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get seConnecter => 'Sign in';

  @override
  String get splashTitle => 'Building Maintenance';

  @override
  String get home => 'Home';

  @override
  String get sync => 'Sync';

  @override
  String bonjour(Object name) {
    return 'Hello $name!';
  }

  @override
  String get roleAdmin => '👑 Administrator';

  @override
  String get rolePlanificateur => '🗓 Planner';

  @override
  String get roleExecutant => '🔧 Executant';

  @override
  String get enCours => 'Active';

  @override
  String get terminees => 'Done';

  @override
  String get total => 'Total';

  @override
  String get accesRapide => 'Quick access';

  @override
  String get nouvelleTache => 'New\ntask';

  @override
  String get listeDesTaches => 'Task\nlist';

  @override
  String get calendrier => 'Calendar';

  @override
  String get rapports => 'Reports';

  @override
  String get drawerUser => 'User';

  @override
  String get drawerVersion => 'V 1.0';

  @override
  String get archives => 'Archives';

  @override
  String get profil => 'Profile';

  @override
  String get gestionImmeubles => 'Building management';

  @override
  String get gestionUtilisateurs => 'User management';

  @override
  String get support => 'Support';

  @override
  String get deconnexion => 'Log out';

  @override
  String get annuler => 'Cancel';

  @override
  String get modifier => 'Edit';

  @override
  String get supprimer => 'Delete';

  @override
  String get archiver => 'Archive';

  @override
  String get desarchiver => 'Unarchive';

  @override
  String get enregistrer => 'Save';

  @override
  String get langue => 'Language';

  @override
  String get francais => 'Français';

  @override
  String get anglais => 'English';

  @override
  String get espagnol => 'Spanish';

  @override
  String get pasDeConnexion => 'No internet connection';

  @override
  String get erreur => 'Error';

  @override
  String get erreurPrefix => 'Error: ';

  @override
  String erreurDb(Object msg) {
    return 'Database error: $msg';
  }

  @override
  String get storageErrorTitle => 'Storage problem';

  @override
  String get storageErrorMessage =>
      'The app cannot access local storage (data or preferences). Free up space or reinstall the app.';

  @override
  String get storageErrorContactSupport =>
      'Do you want to contact support by email?';

  @override
  String get storageErrorContactSupportButton => 'Send email';

  @override
  String get storageErrorPrefsFailed =>
      'Cannot access preferences. Default settings are used.';

  @override
  String get profilEnregistre => '✅ Profile saved';

  @override
  String profilEnregistreLocalDistant(Object msg) {
    return '✅ Profile saved locally. Remote: $msg';
  }

  @override
  String get nom => 'Last name';

  @override
  String get prenom => 'First name';

  @override
  String get telephone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get motDePasseOptionnel =>
      'New password (leave blank to keep current)';

  @override
  String get immeuble => 'Building';

  @override
  String get immeubleRequired => 'Building *';

  @override
  String get selectionnerImmeuble => 'Select a building';

  @override
  String get veuillezSelectionnerImmeuble => 'Please select a building';

  @override
  String get etage => 'Floor';

  @override
  String get chambre => 'Room';

  @override
  String chambreShort(Object num) {
    return 'Rm. $num';
  }

  @override
  String get descriptionTache => 'Task description *';

  @override
  String get veuillezEntrerDescription => 'Please enter a description';

  @override
  String get datePlanifiee => 'Planned date';

  @override
  String get nonDefinie => 'Not set';

  @override
  String get tacheTerminee => 'Task completed';

  @override
  String get tacheEnCours => 'Task in progress';

  @override
  String get planificateurNePeutPasCloturer => 'Planner cannot close a task';

  @override
  String get faitLe => 'Done on';

  @override
  String get executePar => 'Done by';

  @override
  String get noteExecution => 'Execution note';

  @override
  String get ajouterUneTache => 'Add a task';

  @override
  String get modifierLaTache => 'Edit task';

  @override
  String modifierLaTacheNum(Object num) {
    return 'Edit task #$num';
  }

  @override
  String get photo => 'Photo';

  @override
  String get ajouterPhoto => 'Add photo';

  @override
  String get supprimerPhoto => 'Remove';

  @override
  String tacheCreee(Object num) {
    return '✅ Task #$num created';
  }

  @override
  String get tacheModifiee => '✅ Task updated';

  @override
  String get tacheEnregistreeSyncAuRetour =>
      'Task saved. Sync (including photo) when back online.';

  @override
  String tacheCreeeOuModifieeDistant(Object msg, Object syncError) {
    return '$msg (remote: $syncError)';
  }

  @override
  String get datePlanificationPosterieure => 'Planned date must be after today';

  @override
  String get listeTaches => 'Task list';

  @override
  String get filtreImmeuble => 'Building';

  @override
  String get toutes => 'All';

  @override
  String get actifs => 'Active';

  @override
  String get supprimerTacheConfirm => 'Delete task?';

  @override
  String supprimerTacheConfirmContent(Object num, Object desc) {
    return 'Are you sure you want to delete task $num?\n\n\"$desc\"';
  }

  @override
  String get archiverTacheConfirm => 'Archive task?';

  @override
  String archiverTacheConfirmContent(Object num, Object desc) {
    return 'Do you want to archive task $num?\n\n\"$desc\"';
  }

  @override
  String get tacheSupprimee => '🗑️ Task deleted';

  @override
  String tacheSupprimeeDistant(Object msg) {
    return '🗑️ Task deleted (remote: $msg)';
  }

  @override
  String get tacheArchivee => '📦 Task archived';

  @override
  String tacheArchiveeDistant(Object msg) {
    return '📦 Task archived (remote: $msg)';
  }

  @override
  String get aucuneTache => 'No tasks';

  @override
  String tache(Object num) {
    return 'Task $num';
  }

  @override
  String get historique => 'History';

  @override
  String detailTache(Object num) {
    return 'Task $num';
  }

  @override
  String get historiqueModifications => 'Modification history';

  @override
  String get aucuneTachePlanifiee => 'No tasks planned for this day';

  @override
  String tachesCount(Object count) {
    return '$count task(s)';
  }

  @override
  String get archiverImmeubleConfirm => 'Archive building?';

  @override
  String get desarchiverImmeubleConfirm => 'Unarchive building?';

  @override
  String archiverImmeubleQuestion(Object nom) {
    return 'Do you want to archive \"$nom\"?';
  }

  @override
  String desarchiverImmeubleQuestion(Object nom) {
    return 'Do you want to unarchive \"$nom\"?';
  }

  @override
  String get immeubleArchive => '📦 Building archived';

  @override
  String get immeubleDesarchive => '✅ Building unarchived';

  @override
  String get immeubleModifie => '✅ Building updated';

  @override
  String get immeubleAjoute => '✅ Building added';

  @override
  String immeubleModifieLocalDistant(Object msg) {
    return '✅ Building updated locally. Remote: $msg';
  }

  @override
  String immeubleAjouteLocalDistant(Object msg) {
    return '✅ Building added locally. Remote: $msg';
  }

  @override
  String get nouvelImmeuble => 'New building';

  @override
  String get modifierImmeuble => 'Edit building';

  @override
  String get adresse => 'Address';

  @override
  String get gestionDesImmeubles => 'Building management';

  @override
  String get archiverUtilisateurConfirm => 'Archive user?';

  @override
  String get desarchiverUtilisateurConfirm => 'Unarchive user?';

  @override
  String archiverUtilisateurQuestion(Object name) {
    return 'Do you want to archive $name?';
  }

  @override
  String desarchiverUtilisateurQuestion(Object name) {
    return 'Do you want to unarchive $name?';
  }

  @override
  String get utilisateurArchive => '📦 User archived';

  @override
  String get utilisateurDesarchive => '✅ User unarchived';

  @override
  String utilisateurArchiveDistant(Object msg) {
    return '📦 User archived (remote: $msg)';
  }

  @override
  String utilisateurDesarchiveDistant(Object msg) {
    return '✅ User unarchived (remote: $msg)';
  }

  @override
  String get gestionDesUtilisateurs => 'User management';

  @override
  String get nouvelUtilisateur => 'New user';

  @override
  String get modifierUtilisateur => 'Edit user';

  @override
  String get role => 'Role';

  @override
  String get administrateur => 'Administrator';

  @override
  String get planificateur => 'Planner';

  @override
  String get executant => 'Executant';

  @override
  String get motDePasseObligatoireCreation =>
      'Password is required for new users';

  @override
  String get responsableInformatique => 'IT contact';

  @override
  String get supportDbErrorInfo =>
      'In case of database error, an email can be sent to this address with the error details.';

  @override
  String syncSuccess(Object msg) {
    return '✅ $msg';
  }

  @override
  String syncSuccessCount(Object count) {
    return '✅ $count items synchronized';
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
    return 'Sync: $msg';
  }

  @override
  String get delaiDepasse => 'Timeout';

  @override
  String get syncInterrompue => 'Sync interrupted (timeout)';

  @override
  String get rapportsTitre => 'Reports';

  @override
  String get dateCreation => 'Created';

  @override
  String get dateExecution => 'Done date';

  @override
  String get executantLabel => 'Done by';

  @override
  String get rechercher => 'Search';

  @override
  String get genererPdf => 'Generate PDF';

  @override
  String get partager => 'Share';

  @override
  String get aucunResultat => 'No results';

  @override
  String get sessionExpiree => 'Session expired';

  @override
  String enregistreLocalSync(Object msg) {
    return 'Saved locally. Server sync: $msg';
  }

  @override
  String planifieeLe(Object date) {
    return 'Planned: $date';
  }

  @override
  String etageLabel(Object num) {
    return 'Floor $num';
  }

  @override
  String get monProfil => 'My profile';

  @override
  String get nomRequired => 'Last name *';

  @override
  String get prenomRequired => 'First name *';

  @override
  String get veuillezEntrerNom => 'Please enter last name';

  @override
  String get veuillezEntrerPrenom => 'Please enter first name';

  @override
  String get min4Caracteres => 'At least 4 characters';

  @override
  String get enregistrement => 'Saving...';

  @override
  String get distantLabel => 'remote';

  @override
  String get aucunUtilisateur => 'No users';

  @override
  String get exNom => 'e.g. Sunset Residence';

  @override
  String get exAdresse => 'e.g. 12 Main Street';

  @override
  String get aucunImmeuble => 'No buildings';

  @override
  String get voirHistorique => 'View history';

  @override
  String get aucuneModificationEnregistree => 'No modifications recorded';

  @override
  String get tousLesImmeubles => 'All buildings';

  @override
  String creeeLe(Object date) {
    return 'Created: $date';
  }

  @override
  String termineeLe(Object date) {
    return 'Done: $date';
  }

  @override
  String get statusArchivee => 'Archived';

  @override
  String get statusArchivees => 'Archived';

  @override
  String get aujourdHui => 'Today';

  @override
  String get photoTravail => 'Work photo';

  @override
  String get photoAjoutee => 'Photo added';

  @override
  String get optionnel => 'Optional';

  @override
  String get changer => 'Change';

  @override
  String get ajouter => 'Add';

  @override
  String get creerLaTache => 'Create task';

  @override
  String get dateExecutionLong => 'Execution date';

  @override
  String get dateCreationDetail => 'Creation date';

  @override
  String dateEtHeure(Object date, Object time) {
    return '$date at $time';
  }

  @override
  String get execution => 'Execution';

  @override
  String get statut => 'Status';

  @override
  String get archivage => 'Archive';

  @override
  String get parModification => 'By:';

  @override
  String get inconnu => 'Unknown';

  @override
  String get tacheCreeeSansNum => 'Task created';

  @override
  String get photoExistante => 'Existing photo';

  @override
  String get nouvellePhoto => 'New photo';

  @override
  String get photoSupprimee => 'Photo removed';

  @override
  String get description => 'Description';

  @override
  String tachesArchiveesCount(Object count) {
    return '$count archived task(s)';
  }

  @override
  String get desarchiverTacheConfirm => 'Unarchive task?';

  @override
  String desarchiverTacheQuestion(Object num, Object desc) {
    return 'Do you want to unarchive task $num?\n\n\"$desc\"';
  }

  @override
  String get tacheDesarchiveeRestore =>
      '✅ Task unarchived and restored to list';

  @override
  String get filtres => 'Filters';

  @override
  String get filtresEtTri => 'Filters and sort';

  @override
  String get reinitialiser => 'Reset';

  @override
  String get appliquer => 'Apply';

  @override
  String get dateModif => 'Date modified';

  @override
  String get ordre => 'Order:';

  @override
  String get croissant => 'Ascending ↑';

  @override
  String get decroissant => 'Descending ↓';

  @override
  String get aucuneTacheArchivee => 'No archived tasks';

  @override
  String get reessayer => 'Retry';

  @override
  String erreurChargement(Object msg) {
    return 'Load error: $msg';
  }

  @override
  String get pasDeConnexionArchives =>
      'No internet connection.\nArchives are stored on the remote server.';

  @override
  String get trierPar => 'Sort by:';

  @override
  String get ajouterCriterTri => 'Add sort criterion';

  @override
  String get genererRapport => 'Generate report';

  @override
  String get chargement => 'Loading...';

  @override
  String get croissantShort => 'Ascending';

  @override
  String get decroissantShort => 'Descending';

  @override
  String get retirerCriterTri => 'Remove this criterion';

  @override
  String get statutLabel => 'Status:';

  @override
  String resultatsCount(Object count) {
    return '$count result(s)';
  }

  @override
  String get partagerEmail => 'Share by email';

  @override
  String get imprimer => 'Print';

  @override
  String get identifiantRequired => 'Username *';

  @override
  String get seraUtiliseConnexion => 'Used for login';

  @override
  String get veuillezEntrerIdentifiant => 'Please enter a username';

  @override
  String get min3Caracteres => 'Minimum 3 characters';

  @override
  String get veuillezEntrerMotDePasse => 'Please enter a password';

  @override
  String get roleUtilisateur => 'User role';

  @override
  String get descriptionRoleExecutant => 'Can view and execute tasks';

  @override
  String get descriptionRolePlanificateur =>
      'Can create and plan tasks, but cannot execute them';

  @override
  String get descriptionRoleAdmin => 'Full access to the application';

  @override
  String get creerUtilisateur => 'Create user';

  @override
  String get utilisateurModifie => '✅ User updated';

  @override
  String get utilisateurCree => '✅ User created';
}

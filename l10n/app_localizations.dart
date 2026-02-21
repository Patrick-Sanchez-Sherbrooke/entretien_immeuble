import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Entretien Immeuble'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Entretien des résidences'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour continuer'**
  String get loginSubtitle;

  /// No description provided for @loginErrorBadCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant ou mot de passe incorrect'**
  String get loginErrorBadCredentials;

  /// No description provided for @loginErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion. Vérifiez votre réseau.'**
  String get loginErrorNetwork;

  /// No description provided for @identifiant.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant'**
  String get identifiant;

  /// No description provided for @pleaseEnterIdentifiant.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre identifiant'**
  String get pleaseEnterIdentifiant;

  /// No description provided for @motDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get motDePasse;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre mot de passe'**
  String get pleaseEnterPassword;

  /// No description provided for @seConnecter.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get seConnecter;

  /// No description provided for @splashTitle.
  ///
  /// In fr, this message translates to:
  /// **'Entretien Immeuble'**
  String get splashTitle;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @sync.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser'**
  String get sync;

  /// No description provided for @bonjour.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name} !'**
  String bonjour(Object name);

  /// No description provided for @roleAdmin.
  ///
  /// In fr, this message translates to:
  /// **'👑 Administrateur'**
  String get roleAdmin;

  /// No description provided for @rolePlanificateur.
  ///
  /// In fr, this message translates to:
  /// **'🗓 Planificateur'**
  String get rolePlanificateur;

  /// No description provided for @roleExecutant.
  ///
  /// In fr, this message translates to:
  /// **'🔧 Exécutant'**
  String get roleExecutant;

  /// No description provided for @enCours.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get enCours;

  /// No description provided for @terminees.
  ///
  /// In fr, this message translates to:
  /// **'Terminées'**
  String get terminees;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @accesRapide.
  ///
  /// In fr, this message translates to:
  /// **'Accès rapide'**
  String get accesRapide;

  /// No description provided for @nouvelleTache.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle\ntâche'**
  String get nouvelleTache;

  /// No description provided for @listeDesTaches.
  ///
  /// In fr, this message translates to:
  /// **'Liste des\ntâches'**
  String get listeDesTaches;

  /// No description provided for @calendrier.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get calendrier;

  /// No description provided for @rapports.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get rapports;

  /// No description provided for @drawerUser.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get drawerUser;

  /// No description provided for @drawerVersion.
  ///
  /// In fr, this message translates to:
  /// **'V 1.0'**
  String get drawerVersion;

  /// No description provided for @archives.
  ///
  /// In fr, this message translates to:
  /// **'Archives'**
  String get archives;

  /// No description provided for @profil.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profil;

  /// No description provided for @gestionImmeubles.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des immeubles'**
  String get gestionImmeubles;

  /// No description provided for @gestionUtilisateurs.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des utilisateurs'**
  String get gestionUtilisateurs;

  /// No description provided for @support.
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @deconnexion.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get deconnexion;

  /// No description provided for @annuler.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get annuler;

  /// No description provided for @modifier.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get modifier;

  /// No description provided for @supprimer.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get supprimer;

  /// No description provided for @archiver.
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get archiver;

  /// No description provided for @desarchiver.
  ///
  /// In fr, this message translates to:
  /// **'Désarchiver'**
  String get desarchiver;

  /// No description provided for @enregistrer.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get enregistrer;

  /// No description provided for @langue.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get langue;

  /// No description provided for @francais.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get francais;

  /// No description provided for @anglais.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get anglais;

  /// No description provided for @espagnol.
  ///
  /// In fr, this message translates to:
  /// **'Espagnol'**
  String get espagnol;

  /// No description provided for @pasDeConnexion.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet'**
  String get pasDeConnexion;

  /// No description provided for @erreur.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get erreur;

  /// No description provided for @erreurPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: '**
  String get erreurPrefix;

  /// No description provided for @erreurDb.
  ///
  /// In fr, this message translates to:
  /// **'Erreur base de données: {msg}'**
  String erreurDb(Object msg);

  /// No description provided for @storageErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Problème de stockage'**
  String get storageErrorTitle;

  /// No description provided for @storageErrorMessage.
  ///
  /// In fr, this message translates to:
  /// **'L\'application ne peut pas accéder au stockage local (données ou préférences). Libérez de l\'espace ou réinstallez l\'app.'**
  String get storageErrorMessage;

  /// No description provided for @storageErrorContactSupport.
  ///
  /// In fr, this message translates to:
  /// **'Souhaitez-vous contacter le support par email ?'**
  String get storageErrorContactSupport;

  /// No description provided for @storageErrorContactSupportButton.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un email'**
  String get storageErrorContactSupportButton;

  /// No description provided for @storageErrorPrefsFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'accéder aux préférences. Les paramètres par défaut sont utilisés.'**
  String get storageErrorPrefsFailed;

  /// No description provided for @profilEnregistre.
  ///
  /// In fr, this message translates to:
  /// **'✅ Profil enregistré'**
  String get profilEnregistre;

  /// No description provided for @profilEnregistreLocalDistant.
  ///
  /// In fr, this message translates to:
  /// **'✅ Profil enregistré en local. Distant : {msg}'**
  String profilEnregistreLocalDistant(Object msg);

  /// No description provided for @nom.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get nom;

  /// No description provided for @prenom.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get prenom;

  /// No description provided for @telephone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get telephone;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @motDePasseOptionnel.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe (laisser vide pour ne pas changer)'**
  String get motDePasseOptionnel;

  /// No description provided for @immeuble.
  ///
  /// In fr, this message translates to:
  /// **'Immeuble'**
  String get immeuble;

  /// No description provided for @immeubleRequired.
  ///
  /// In fr, this message translates to:
  /// **'Immeuble *'**
  String get immeubleRequired;

  /// No description provided for @selectionnerImmeuble.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner un immeuble'**
  String get selectionnerImmeuble;

  /// No description provided for @veuillezSelectionnerImmeuble.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un immeuble'**
  String get veuillezSelectionnerImmeuble;

  /// No description provided for @etage.
  ///
  /// In fr, this message translates to:
  /// **'Étage'**
  String get etage;

  /// No description provided for @chambre.
  ///
  /// In fr, this message translates to:
  /// **'Chambre'**
  String get chambre;

  /// No description provided for @chambreShort.
  ///
  /// In fr, this message translates to:
  /// **'Ch. {num}'**
  String chambreShort(Object num);

  /// No description provided for @descriptionTache.
  ///
  /// In fr, this message translates to:
  /// **'Description de la tâche *'**
  String get descriptionTache;

  /// No description provided for @veuillezEntrerDescription.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer une description'**
  String get veuillezEntrerDescription;

  /// No description provided for @datePlanifiee.
  ///
  /// In fr, this message translates to:
  /// **'Date planifiée'**
  String get datePlanifiee;

  /// No description provided for @nonDefinie.
  ///
  /// In fr, this message translates to:
  /// **'Non définie'**
  String get nonDefinie;

  /// No description provided for @tacheTerminee.
  ///
  /// In fr, this message translates to:
  /// **'Tâche terminée'**
  String get tacheTerminee;

  /// No description provided for @tacheEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Tâche en cours'**
  String get tacheEnCours;

  /// No description provided for @planificateurNePeutPasCloturer.
  ///
  /// In fr, this message translates to:
  /// **'Le planificateur ne peut pas clôturer une tâche'**
  String get planificateurNePeutPasCloturer;

  /// No description provided for @faitLe.
  ///
  /// In fr, this message translates to:
  /// **'Fait le'**
  String get faitLe;

  /// No description provided for @executePar.
  ///
  /// In fr, this message translates to:
  /// **'Exécuté par'**
  String get executePar;

  /// No description provided for @noteExecution.
  ///
  /// In fr, this message translates to:
  /// **'Note d\'exécution'**
  String get noteExecution;

  /// No description provided for @ajouterUneTache.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une tâche'**
  String get ajouterUneTache;

  /// No description provided for @modifierLaTache.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la tâche'**
  String get modifierLaTache;

  /// No description provided for @modifierLaTacheNum.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la tâche #{num}'**
  String modifierLaTacheNum(Object num);

  /// No description provided for @photo.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @ajouterPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get ajouterPhoto;

  /// No description provided for @supprimerPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get supprimerPhoto;

  /// No description provided for @tacheCreee.
  ///
  /// In fr, this message translates to:
  /// **'✅ Tâche #{num} créée'**
  String tacheCreee(Object num);

  /// No description provided for @tacheModifiee.
  ///
  /// In fr, this message translates to:
  /// **'✅ Tâche modifiée'**
  String get tacheModifiee;

  /// No description provided for @tacheEnregistreeSyncAuRetour.
  ///
  /// In fr, this message translates to:
  /// **'Tâche enregistrée. Synchronisation (photo comprise) au retour du réseau.'**
  String get tacheEnregistreeSyncAuRetour;

  /// No description provided for @tacheCreeeOuModifieeDistant.
  ///
  /// In fr, this message translates to:
  /// **'{msg} (distant : {syncError})'**
  String tacheCreeeOuModifieeDistant(Object msg, Object syncError);

  /// No description provided for @datePlanificationPosterieure.
  ///
  /// In fr, this message translates to:
  /// **'❌ La date de planification doit être postérieure à la date du jour'**
  String get datePlanificationPosterieure;

  /// No description provided for @listeTaches.
  ///
  /// In fr, this message translates to:
  /// **'Liste des tâches'**
  String get listeTaches;

  /// No description provided for @filtreImmeuble.
  ///
  /// In fr, this message translates to:
  /// **'Immeuble'**
  String get filtreImmeuble;

  /// No description provided for @toutes.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get toutes;

  /// No description provided for @actifs.
  ///
  /// In fr, this message translates to:
  /// **'Actifs'**
  String get actifs;

  /// No description provided for @supprimerTacheConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la tâche ?'**
  String get supprimerTacheConfirm;

  /// No description provided for @supprimerTacheConfirmContent.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer la tâche {num} ?\n\n\"{desc}\"'**
  String supprimerTacheConfirmContent(Object num, Object desc);

  /// No description provided for @archiverTacheConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Archiver la tâche ?'**
  String get archiverTacheConfirm;

  /// No description provided for @archiverTacheConfirmContent.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous archiver la tâche {num} ?\n\n\"{desc}\"'**
  String archiverTacheConfirmContent(Object num, Object desc);

  /// No description provided for @tacheSupprimee.
  ///
  /// In fr, this message translates to:
  /// **'🗑️ Tâche supprimée'**
  String get tacheSupprimee;

  /// No description provided for @tacheSupprimeeDistant.
  ///
  /// In fr, this message translates to:
  /// **'🗑️ Tâche supprimée (distant : {msg})'**
  String tacheSupprimeeDistant(Object msg);

  /// No description provided for @tacheArchivee.
  ///
  /// In fr, this message translates to:
  /// **'📦 Tâche archivée'**
  String get tacheArchivee;

  /// No description provided for @tacheArchiveeDistant.
  ///
  /// In fr, this message translates to:
  /// **'📦 Tâche archivée (distant : {msg})'**
  String tacheArchiveeDistant(Object msg);

  /// No description provided for @aucuneTache.
  ///
  /// In fr, this message translates to:
  /// **'Aucune tâche'**
  String get aucuneTache;

  /// No description provided for @tache.
  ///
  /// In fr, this message translates to:
  /// **'Tâche {num}'**
  String tache(Object num);

  /// No description provided for @historique.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get historique;

  /// No description provided for @detailTache.
  ///
  /// In fr, this message translates to:
  /// **'Tâche {num}'**
  String detailTache(Object num);

  /// No description provided for @historiqueModifications.
  ///
  /// In fr, this message translates to:
  /// **'Historique des modifications'**
  String get historiqueModifications;

  /// No description provided for @aucuneTachePlanifiee.
  ///
  /// In fr, this message translates to:
  /// **'Aucune tâche planifiée ce jour'**
  String get aucuneTachePlanifiee;

  /// No description provided for @tachesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} tâche(s)'**
  String tachesCount(Object count);

  /// No description provided for @archiverImmeubleConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Archiver l\'immeuble ?'**
  String get archiverImmeubleConfirm;

  /// No description provided for @desarchiverImmeubleConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Désarchiver l\'immeuble ?'**
  String get desarchiverImmeubleConfirm;

  /// No description provided for @archiverImmeubleQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous archiver « {nom} » ?'**
  String archiverImmeubleQuestion(Object nom);

  /// No description provided for @desarchiverImmeubleQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous désarchiver « {nom} » ?'**
  String desarchiverImmeubleQuestion(Object nom);

  /// No description provided for @immeubleArchive.
  ///
  /// In fr, this message translates to:
  /// **'📦 Immeuble archivé'**
  String get immeubleArchive;

  /// No description provided for @immeubleDesarchive.
  ///
  /// In fr, this message translates to:
  /// **'✅ Immeuble désarchivé'**
  String get immeubleDesarchive;

  /// No description provided for @immeubleModifie.
  ///
  /// In fr, this message translates to:
  /// **'✅ Immeuble modifié'**
  String get immeubleModifie;

  /// No description provided for @immeubleAjoute.
  ///
  /// In fr, this message translates to:
  /// **'✅ Immeuble ajouté'**
  String get immeubleAjoute;

  /// No description provided for @immeubleModifieLocalDistant.
  ///
  /// In fr, this message translates to:
  /// **'✅ Immeuble modifié en local. Distant : {msg}'**
  String immeubleModifieLocalDistant(Object msg);

  /// No description provided for @immeubleAjouteLocalDistant.
  ///
  /// In fr, this message translates to:
  /// **'✅ Immeuble ajouté en local. Distant : {msg}'**
  String immeubleAjouteLocalDistant(Object msg);

  /// No description provided for @nouvelImmeuble.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel immeuble'**
  String get nouvelImmeuble;

  /// No description provided for @modifierImmeuble.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'immeuble'**
  String get modifierImmeuble;

  /// No description provided for @adresse.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get adresse;

  /// No description provided for @gestionDesImmeubles.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des immeubles'**
  String get gestionDesImmeubles;

  /// No description provided for @archiverUtilisateurConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Archiver l\'utilisateur ?'**
  String get archiverUtilisateurConfirm;

  /// No description provided for @desarchiverUtilisateurConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Désarchiver l\'utilisateur ?'**
  String get desarchiverUtilisateurConfirm;

  /// No description provided for @archiverUtilisateurQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous archiver {name} ?'**
  String archiverUtilisateurQuestion(Object name);

  /// No description provided for @desarchiverUtilisateurQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous désarchiver {name} ?'**
  String desarchiverUtilisateurQuestion(Object name);

  /// No description provided for @utilisateurArchive.
  ///
  /// In fr, this message translates to:
  /// **'📦 Utilisateur archivé'**
  String get utilisateurArchive;

  /// No description provided for @utilisateurDesarchive.
  ///
  /// In fr, this message translates to:
  /// **'✅ Utilisateur désarchivé'**
  String get utilisateurDesarchive;

  /// No description provided for @utilisateurArchiveDistant.
  ///
  /// In fr, this message translates to:
  /// **'📦 Utilisateur archivé (distant : {msg})'**
  String utilisateurArchiveDistant(Object msg);

  /// No description provided for @utilisateurDesarchiveDistant.
  ///
  /// In fr, this message translates to:
  /// **'✅ Utilisateur désarchivé (distant : {msg})'**
  String utilisateurDesarchiveDistant(Object msg);

  /// No description provided for @gestionDesUtilisateurs.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des utilisateurs'**
  String get gestionDesUtilisateurs;

  /// No description provided for @nouvelUtilisateur.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel utilisateur'**
  String get nouvelUtilisateur;

  /// No description provided for @modifierUtilisateur.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'utilisateur'**
  String get modifierUtilisateur;

  /// No description provided for @role.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get role;

  /// No description provided for @administrateur.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get administrateur;

  /// No description provided for @planificateur.
  ///
  /// In fr, this message translates to:
  /// **'Planificateur'**
  String get planificateur;

  /// No description provided for @executant.
  ///
  /// In fr, this message translates to:
  /// **'Exécutant'**
  String get executant;

  /// No description provided for @motDePasseObligatoireCreation.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est obligatoire pour la création'**
  String get motDePasseObligatoireCreation;

  /// No description provided for @responsableInformatique.
  ///
  /// In fr, this message translates to:
  /// **'Responsable informatique'**
  String get responsableInformatique;

  /// No description provided for @supportDbErrorInfo.
  ///
  /// In fr, this message translates to:
  /// **'En cas d\'erreur de base de données, un email pourra être envoyé à cette adresse avec le détail de l\'erreur.'**
  String get supportDbErrorInfo;

  /// No description provided for @syncSuccess.
  ///
  /// In fr, this message translates to:
  /// **'✅ {msg}'**
  String syncSuccess(Object msg);

  /// No description provided for @syncSuccessCount.
  ///
  /// In fr, this message translates to:
  /// **'✅ {count} éléments synchronisés'**
  String syncSuccessCount(Object count);

  /// No description provided for @syncWarning.
  ///
  /// In fr, this message translates to:
  /// **'⚠️ {msg}'**
  String syncWarning(Object msg);

  /// No description provided for @syncError.
  ///
  /// In fr, this message translates to:
  /// **'❌ {msg}'**
  String syncError(Object msg);

  /// No description provided for @synchronisation.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation: {msg}'**
  String synchronisation(Object msg);

  /// No description provided for @delaiDepasse.
  ///
  /// In fr, this message translates to:
  /// **'Délai dépassé'**
  String get delaiDepasse;

  /// No description provided for @syncInterrompue.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation interrompue (délai dépassé)'**
  String get syncInterrompue;

  /// No description provided for @rapportsTitre.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get rapportsTitre;

  /// No description provided for @dateCreation.
  ///
  /// In fr, this message translates to:
  /// **'Date création'**
  String get dateCreation;

  /// No description provided for @dateExecution.
  ///
  /// In fr, this message translates to:
  /// **'Date exéc.'**
  String get dateExecution;

  /// No description provided for @executantLabel.
  ///
  /// In fr, this message translates to:
  /// **'Exécutant'**
  String get executantLabel;

  /// No description provided for @rechercher.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get rechercher;

  /// No description provided for @genererPdf.
  ///
  /// In fr, this message translates to:
  /// **'Générer le PDF'**
  String get genererPdf;

  /// No description provided for @partager.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get partager;

  /// No description provided for @aucunResultat.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get aucunResultat;

  /// No description provided for @sessionExpiree.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée'**
  String get sessionExpiree;

  /// No description provided for @enregistreLocalSync.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré en local. Sync serveur : {msg}'**
  String enregistreLocalSync(Object msg);

  /// No description provided for @planifieeLe.
  ///
  /// In fr, this message translates to:
  /// **'Planifiée le : {date}'**
  String planifieeLe(Object date);

  /// No description provided for @etageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Étage {num}'**
  String etageLabel(Object num);

  /// No description provided for @monProfil.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get monProfil;

  /// No description provided for @nomRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom *'**
  String get nomRequired;

  /// No description provided for @prenomRequired.
  ///
  /// In fr, this message translates to:
  /// **'Prénom *'**
  String get prenomRequired;

  /// No description provided for @veuillezEntrerNom.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer le nom'**
  String get veuillezEntrerNom;

  /// No description provided for @veuillezEntrerPrenom.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer le prénom'**
  String get veuillezEntrerPrenom;

  /// No description provided for @min4Caracteres.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 4 caractères'**
  String get min4Caracteres;

  /// No description provided for @enregistrement.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement...'**
  String get enregistrement;

  /// No description provided for @distantLabel.
  ///
  /// In fr, this message translates to:
  /// **'distant'**
  String get distantLabel;

  /// No description provided for @aucunUtilisateur.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur'**
  String get aucunUtilisateur;

  /// No description provided for @exNom.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Résidence Les Lilas'**
  String get exNom;

  /// No description provided for @exAdresse.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 12 rue des Fleurs'**
  String get exAdresse;

  /// No description provided for @aucunImmeuble.
  ///
  /// In fr, this message translates to:
  /// **'Aucun immeuble'**
  String get aucunImmeuble;

  /// No description provided for @voirHistorique.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'historique'**
  String get voirHistorique;

  /// No description provided for @aucuneModificationEnregistree.
  ///
  /// In fr, this message translates to:
  /// **'Aucune modification enregistrée'**
  String get aucuneModificationEnregistree;

  /// No description provided for @tousLesImmeubles.
  ///
  /// In fr, this message translates to:
  /// **'Tous les immeubles'**
  String get tousLesImmeubles;

  /// No description provided for @creeeLe.
  ///
  /// In fr, this message translates to:
  /// **'Créée le : {date}'**
  String creeeLe(Object date);

  /// No description provided for @termineeLe.
  ///
  /// In fr, this message translates to:
  /// **'Terminée le : {date}'**
  String termineeLe(Object date);

  /// No description provided for @statusArchivee.
  ///
  /// In fr, this message translates to:
  /// **'Archivée'**
  String get statusArchivee;

  /// No description provided for @statusArchivees.
  ///
  /// In fr, this message translates to:
  /// **'Archivées'**
  String get statusArchivees;

  /// No description provided for @aujourdHui.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get aujourdHui;

  /// No description provided for @photoTravail.
  ///
  /// In fr, this message translates to:
  /// **'Photo du travail'**
  String get photoTravail;

  /// No description provided for @photoAjoutee.
  ///
  /// In fr, this message translates to:
  /// **'Photo ajoutée'**
  String get photoAjoutee;

  /// No description provided for @optionnel.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel'**
  String get optionnel;

  /// No description provided for @changer.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get changer;

  /// No description provided for @ajouter.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get ajouter;

  /// No description provided for @creerLaTache.
  ///
  /// In fr, this message translates to:
  /// **'Créer la tâche'**
  String get creerLaTache;

  /// No description provided for @dateExecutionLong.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'exécution'**
  String get dateExecutionLong;

  /// No description provided for @dateCreationDetail.
  ///
  /// In fr, this message translates to:
  /// **'Date de création'**
  String get dateCreationDetail;

  /// No description provided for @dateEtHeure.
  ///
  /// In fr, this message translates to:
  /// **'{date} à {time}'**
  String dateEtHeure(Object date, Object time);

  /// No description provided for @execution.
  ///
  /// In fr, this message translates to:
  /// **'Exécution'**
  String get execution;

  /// No description provided for @statut.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get statut;

  /// No description provided for @archivage.
  ///
  /// In fr, this message translates to:
  /// **'Archivage'**
  String get archivage;

  /// No description provided for @parModification.
  ///
  /// In fr, this message translates to:
  /// **'Par :'**
  String get parModification;

  /// No description provided for @inconnu.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get inconnu;

  /// No description provided for @tacheCreeeSansNum.
  ///
  /// In fr, this message translates to:
  /// **'Tâche créée'**
  String get tacheCreeeSansNum;

  /// No description provided for @photoExistante.
  ///
  /// In fr, this message translates to:
  /// **'Photo existante'**
  String get photoExistante;

  /// No description provided for @nouvellePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle photo'**
  String get nouvellePhoto;

  /// No description provided for @photoSupprimee.
  ///
  /// In fr, this message translates to:
  /// **'Photo supprimée'**
  String get photoSupprimee;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @tachesArchiveesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} tâche(s) archivée(s)'**
  String tachesArchiveesCount(Object count);

  /// No description provided for @desarchiverTacheConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Désarchiver la tâche ?'**
  String get desarchiverTacheConfirm;

  /// No description provided for @desarchiverTacheQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous désarchiver la tâche {num} ?\n\n\"{desc}\"'**
  String desarchiverTacheQuestion(Object num, Object desc);

  /// No description provided for @tacheDesarchiveeRestore.
  ///
  /// In fr, this message translates to:
  /// **'✅ Tâche désarchivée et restaurée dans la liste'**
  String get tacheDesarchiveeRestore;

  /// No description provided for @filtres.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filtres;

  /// No description provided for @filtresEtTri.
  ///
  /// In fr, this message translates to:
  /// **'Filtres et tri'**
  String get filtresEtTri;

  /// No description provided for @reinitialiser.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reinitialiser;

  /// No description provided for @appliquer.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get appliquer;

  /// No description provided for @dateModif.
  ///
  /// In fr, this message translates to:
  /// **'Date modif.'**
  String get dateModif;

  /// No description provided for @ordre.
  ///
  /// In fr, this message translates to:
  /// **'Ordre :'**
  String get ordre;

  /// No description provided for @croissant.
  ///
  /// In fr, this message translates to:
  /// **'Croissant ↑'**
  String get croissant;

  /// No description provided for @decroissant.
  ///
  /// In fr, this message translates to:
  /// **'Décroissant ↓'**
  String get decroissant;

  /// No description provided for @aucuneTacheArchivee.
  ///
  /// In fr, this message translates to:
  /// **'Aucune tâche archivée'**
  String get aucuneTacheArchivee;

  /// No description provided for @reessayer.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get reessayer;

  /// No description provided for @erreurChargement.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement : {msg}'**
  String erreurChargement(Object msg);

  /// No description provided for @pasDeConnexionArchives.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet.\nLes archives sont stockées sur le serveur distant.'**
  String get pasDeConnexionArchives;

  /// No description provided for @trierPar.
  ///
  /// In fr, this message translates to:
  /// **'Trier par :'**
  String get trierPar;

  /// No description provided for @ajouterCriterTri.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un critère de tri'**
  String get ajouterCriterTri;

  /// No description provided for @genererRapport.
  ///
  /// In fr, this message translates to:
  /// **'Générer le rapport'**
  String get genererRapport;

  /// No description provided for @chargement.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get chargement;

  /// No description provided for @croissantShort.
  ///
  /// In fr, this message translates to:
  /// **'Croissant'**
  String get croissantShort;

  /// No description provided for @decroissantShort.
  ///
  /// In fr, this message translates to:
  /// **'Décroissant'**
  String get decroissantShort;

  /// No description provided for @retirerCriterTri.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ce critère'**
  String get retirerCriterTri;

  /// No description provided for @statutLabel.
  ///
  /// In fr, this message translates to:
  /// **'Statut :'**
  String get statutLabel;

  /// No description provided for @resultatsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} résultat(s)'**
  String resultatsCount(Object count);

  /// No description provided for @partagerEmail.
  ///
  /// In fr, this message translates to:
  /// **'Partager par email'**
  String get partagerEmail;

  /// No description provided for @imprimer.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer'**
  String get imprimer;

  /// No description provided for @identifiantRequired.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant *'**
  String get identifiantRequired;

  /// No description provided for @seraUtiliseConnexion.
  ///
  /// In fr, this message translates to:
  /// **'Sera utilisé pour la connexion'**
  String get seraUtiliseConnexion;

  /// No description provided for @veuillezEntrerIdentifiant.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un identifiant'**
  String get veuillezEntrerIdentifiant;

  /// No description provided for @min3Caracteres.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 3 caractères'**
  String get min3Caracteres;

  /// No description provided for @veuillezEntrerMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un mot de passe'**
  String get veuillezEntrerMotDePasse;

  /// No description provided for @roleUtilisateur.
  ///
  /// In fr, this message translates to:
  /// **'Rôle de l\'utilisateur'**
  String get roleUtilisateur;

  /// No description provided for @descriptionRoleExecutant.
  ///
  /// In fr, this message translates to:
  /// **'Peut voir et exécuter les tâches'**
  String get descriptionRoleExecutant;

  /// No description provided for @descriptionRolePlanificateur.
  ///
  /// In fr, this message translates to:
  /// **'Peut créer et planifier les tâches, mais pas les exécuter'**
  String get descriptionRolePlanificateur;

  /// No description provided for @descriptionRoleAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Accès complet à l\'application'**
  String get descriptionRoleAdmin;

  /// No description provided for @creerUtilisateur.
  ///
  /// In fr, this message translates to:
  /// **'Créer l\'utilisateur'**
  String get creerUtilisateur;

  /// No description provided for @utilisateurModifie.
  ///
  /// In fr, this message translates to:
  /// **'✅ Utilisateur modifié'**
  String get utilisateurModifie;

  /// No description provided for @utilisateurCree.
  ///
  /// In fr, this message translates to:
  /// **'✅ Utilisateur créé'**
  String get utilisateurCree;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

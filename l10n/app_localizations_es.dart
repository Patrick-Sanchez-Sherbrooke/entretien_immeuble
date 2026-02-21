// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Mantenimiento de Edificios';

  @override
  String get loginTitle => 'Mantenimiento de residencias';

  @override
  String get loginSubtitle => 'Conéctese para continuar';

  @override
  String get loginErrorBadCredentials => 'Usuario o contraseña incorrectos';

  @override
  String get loginErrorNetwork => 'Error de conexión. Compruebe su red.';

  @override
  String get identifiant => 'Usuario';

  @override
  String get pleaseEnterIdentifiant => 'Introduzca su usuario';

  @override
  String get motDePasse => 'Contraseña';

  @override
  String get pleaseEnterPassword => 'Introduzca su contraseña';

  @override
  String get seConnecter => 'Iniciar sesión';

  @override
  String get splashTitle => 'Mantenimiento de Edificios';

  @override
  String get home => 'Inicio';

  @override
  String get sync => 'Sincronizar';

  @override
  String bonjour(Object name) {
    return '¡Hola $name!';
  }

  @override
  String get roleAdmin => '👑 Administrador';

  @override
  String get rolePlanificateur => '🗓 Planificador';

  @override
  String get roleExecutant => '🔧 Ejecutante';

  @override
  String get enCours => 'En curso';

  @override
  String get terminees => 'Completadas';

  @override
  String get total => 'Total';

  @override
  String get accesRapide => 'Acceso rápido';

  @override
  String get nouvelleTache => 'Nueva\ntarea';

  @override
  String get listeDesTaches => 'Lista de\ntareas';

  @override
  String get calendrier => 'Calendario';

  @override
  String get rapports => 'Informes';

  @override
  String get drawerUser => 'Usuario';

  @override
  String get drawerVersion => 'V 1.0';

  @override
  String get archives => 'Archivos';

  @override
  String get profil => 'Perfil';

  @override
  String get gestionImmeubles => 'Gestión de edificios';

  @override
  String get gestionUtilisateurs => 'Gestión de usuarios';

  @override
  String get support => 'Soporte';

  @override
  String get deconnexion => 'Cerrar sesión';

  @override
  String get annuler => 'Cancelar';

  @override
  String get modifier => 'Editar';

  @override
  String get supprimer => 'Eliminar';

  @override
  String get archiver => 'Archivar';

  @override
  String get desarchiver => 'Desarchivar';

  @override
  String get enregistrer => 'Guardar';

  @override
  String get langue => 'Idioma';

  @override
  String get francais => 'Français';

  @override
  String get anglais => 'English';

  @override
  String get espagnol => 'Español';

  @override
  String get pasDeConnexion => 'Sin conexión a internet';

  @override
  String get erreur => 'Error';

  @override
  String get erreurPrefix => 'Error: ';

  @override
  String erreurDb(Object msg) {
    return 'Error de base de datos: $msg';
  }

  @override
  String get storageErrorTitle => 'Problema de almacenamiento';

  @override
  String get storageErrorMessage =>
      'La aplicación no puede acceder al almacenamiento local. Libere espacio o reinstale la aplicación.';

  @override
  String get storageErrorContactSupport =>
      '¿Desea contactar al soporte por correo?';

  @override
  String get storageErrorContactSupportButton => 'Enviar correo';

  @override
  String get storageErrorPrefsFailed =>
      'No se puede acceder a las preferencias. Se usan los valores por defecto.';

  @override
  String get profilEnregistre => '✅ Perfil guardado';

  @override
  String profilEnregistreLocalDistant(Object msg) {
    return '✅ Perfil guardado localmente. Remoto: $msg';
  }

  @override
  String get nom => 'Apellido';

  @override
  String get prenom => 'Nombre';

  @override
  String get telephone => 'Teléfono';

  @override
  String get email => 'Email';

  @override
  String get motDePasseOptionnel =>
      'Nueva contraseña (dejar en blanco para no cambiar)';

  @override
  String get immeuble => 'Edificio';

  @override
  String get immeubleRequired => 'Edificio *';

  @override
  String get selectionnerImmeuble => 'Seleccionar un edificio';

  @override
  String get veuillezSelectionnerImmeuble => 'Por favor seleccione un edificio';

  @override
  String get etage => 'Piso';

  @override
  String get chambre => 'Habitación';

  @override
  String chambreShort(Object num) {
    return 'Hab. $num';
  }

  @override
  String get descriptionTache => 'Descripción de la tarea *';

  @override
  String get veuillezEntrerDescription =>
      'Por favor introduzca una descripción';

  @override
  String get datePlanifiee => 'Fecha prevista';

  @override
  String get nonDefinie => 'No definida';

  @override
  String get tacheTerminee => 'Tarea completada';

  @override
  String get tacheEnCours => 'Tarea en curso';

  @override
  String get planificateurNePeutPasCloturer =>
      'El planificador no puede cerrar una tarea';

  @override
  String get faitLe => 'Hecho el';

  @override
  String get executePar => 'Hecho por';

  @override
  String get noteExecution => 'Nota de ejecución';

  @override
  String get ajouterUneTache => 'Añadir una tarea';

  @override
  String get modifierLaTache => 'Editar tarea';

  @override
  String modifierLaTacheNum(Object num) {
    return 'Editar tarea #$num';
  }

  @override
  String get photo => 'Foto';

  @override
  String get ajouterPhoto => 'Añadir foto';

  @override
  String get supprimerPhoto => 'Quitar';

  @override
  String tacheCreee(Object num) {
    return '✅ Tarea #$num creada';
  }

  @override
  String get tacheModifiee => '✅ Tarea actualizada';

  @override
  String get tacheEnregistreeSyncAuRetour =>
      'Tarea guardada. Sincronización (incl. foto) al volver a tener conexión.';

  @override
  String tacheCreeeOuModifieeDistant(Object msg, Object syncError) {
    return '$msg (remoto: $syncError)';
  }

  @override
  String get datePlanificationPosterieure =>
      'La fecha prevista debe ser posterior a hoy';

  @override
  String get listeTaches => 'Lista de tareas';

  @override
  String get filtreImmeuble => 'Edificio';

  @override
  String get toutes => 'Todas';

  @override
  String get actifs => 'Activos';

  @override
  String get supprimerTacheConfirm => '¿Eliminar tarea?';

  @override
  String supprimerTacheConfirmContent(Object num, Object desc) {
    return '¿Seguro que desea eliminar la tarea $num?\n\n\"$desc\"';
  }

  @override
  String get archiverTacheConfirm => '¿Archivar tarea?';

  @override
  String archiverTacheConfirmContent(Object num, Object desc) {
    return '¿Desea archivar la tarea $num?\n\n\"$desc\"';
  }

  @override
  String get tacheSupprimee => '🗑️ Tarea eliminada';

  @override
  String tacheSupprimeeDistant(Object msg) {
    return '🗑️ Tarea eliminada (remoto: $msg)';
  }

  @override
  String get tacheArchivee => '📦 Tarea archivada';

  @override
  String tacheArchiveeDistant(Object msg) {
    return '📦 Tarea archivada (remoto: $msg)';
  }

  @override
  String get aucuneTache => 'Ninguna tarea';

  @override
  String tache(Object num) {
    return 'Tarea $num';
  }

  @override
  String get historique => 'Historial';

  @override
  String detailTache(Object num) {
    return 'Tarea $num';
  }

  @override
  String get historiqueModifications => 'Historial de modificaciones';

  @override
  String get aucuneTachePlanifiee => 'Ninguna tarea prevista para este día';

  @override
  String tachesCount(Object count) {
    return '$count tarea(s)';
  }

  @override
  String get archiverImmeubleConfirm => '¿Archivar edificio?';

  @override
  String get desarchiverImmeubleConfirm => '¿Desarchivar edificio?';

  @override
  String archiverImmeubleQuestion(Object nom) {
    return '¿Desea archivar « $nom »?';
  }

  @override
  String desarchiverImmeubleQuestion(Object nom) {
    return '¿Desea desarchivar « $nom »?';
  }

  @override
  String get immeubleArchive => '📦 Edificio archivado';

  @override
  String get immeubleDesarchive => '✅ Edificio desarchivado';

  @override
  String get immeubleModifie => '✅ Edificio actualizado';

  @override
  String get immeubleAjoute => '✅ Edificio añadido';

  @override
  String immeubleModifieLocalDistant(Object msg) {
    return '✅ Edificio actualizado localmente. Remoto: $msg';
  }

  @override
  String immeubleAjouteLocalDistant(Object msg) {
    return '✅ Edificio añadido localmente. Remoto: $msg';
  }

  @override
  String get nouvelImmeuble => 'Nuevo edificio';

  @override
  String get modifierImmeuble => 'Editar edificio';

  @override
  String get adresse => 'Dirección';

  @override
  String get gestionDesImmeubles => 'Gestión de edificios';

  @override
  String get archiverUtilisateurConfirm => '¿Archivar usuario?';

  @override
  String get desarchiverUtilisateurConfirm => '¿Desarchivar usuario?';

  @override
  String archiverUtilisateurQuestion(Object name) {
    return '¿Desea archivar a $name?';
  }

  @override
  String desarchiverUtilisateurQuestion(Object name) {
    return '¿Desea desarchivar a $name?';
  }

  @override
  String get utilisateurArchive => '📦 Usuario archivado';

  @override
  String get utilisateurDesarchive => '✅ Usuario desarchivado';

  @override
  String utilisateurArchiveDistant(Object msg) {
    return '📦 Usuario archivado (remoto: $msg)';
  }

  @override
  String utilisateurDesarchiveDistant(Object msg) {
    return '✅ Usuario desarchivado (remoto: $msg)';
  }

  @override
  String get gestionDesUtilisateurs => 'Gestión de usuarios';

  @override
  String get nouvelUtilisateur => 'Nuevo usuario';

  @override
  String get modifierUtilisateur => 'Editar usuario';

  @override
  String get role => 'Rol';

  @override
  String get administrateur => 'Administrador';

  @override
  String get planificateur => 'Planificador';

  @override
  String get executant => 'Ejecutante';

  @override
  String get motDePasseObligatoireCreation =>
      'La contraseña es obligatoria para nuevos usuarios';

  @override
  String get responsableInformatique => 'Contacto informático';

  @override
  String get supportDbErrorInfo =>
      'En caso de error de base de datos, se puede enviar un email a esta dirección con el detalle del error.';

  @override
  String syncSuccess(Object msg) {
    return '✅ $msg';
  }

  @override
  String syncSuccessCount(Object count) {
    return '✅ $count elementos sincronizados';
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
    return 'Sincronización: $msg';
  }

  @override
  String get delaiDepasse => 'Tiempo superado';

  @override
  String get syncInterrompue => 'Sincronización interrumpida (tiempo superado)';

  @override
  String get rapportsTitre => 'Informes';

  @override
  String get dateCreation => 'Fecha creación';

  @override
  String get dateExecution => 'Fecha ejec.';

  @override
  String get executantLabel => 'Hecho por';

  @override
  String get rechercher => 'Buscar';

  @override
  String get genererPdf => 'Generar PDF';

  @override
  String get partager => 'Compartir';

  @override
  String get aucunResultat => 'Sin resultados';

  @override
  String get sessionExpiree => 'Sesión expirada';

  @override
  String enregistreLocalSync(Object msg) {
    return 'Guardado localmente. Sincronización servidor: $msg';
  }

  @override
  String planifieeLe(Object date) {
    return 'Prevista: $date';
  }

  @override
  String etageLabel(Object num) {
    return 'Piso $num';
  }

  @override
  String get monProfil => 'Mi perfil';

  @override
  String get nomRequired => 'Apellido *';

  @override
  String get prenomRequired => 'Nombre *';

  @override
  String get veuillezEntrerNom => 'Por favor introduzca el apellido';

  @override
  String get veuillezEntrerPrenom => 'Por favor introduzca el nombre';

  @override
  String get min4Caracteres => 'Mínimo 4 caracteres';

  @override
  String get enregistrement => 'Guardando...';

  @override
  String get distantLabel => 'remoto';

  @override
  String get aucunUtilisateur => 'Ningún usuario';

  @override
  String get exNom => 'Ej: Residencia Las Flores';

  @override
  String get exAdresse => 'Ej: Calle Mayor 12';

  @override
  String get aucunImmeuble => 'Ningún edificio';

  @override
  String get voirHistorique => 'Ver historial';

  @override
  String get aucuneModificationEnregistree => 'Ninguna modificación registrada';

  @override
  String get tousLesImmeubles => 'Todos los edificios';

  @override
  String creeeLe(Object date) {
    return 'Creada: $date';
  }

  @override
  String termineeLe(Object date) {
    return 'Completada: $date';
  }

  @override
  String get statusArchivee => 'Archivada';

  @override
  String get statusArchivees => 'Archivadas';

  @override
  String get aujourdHui => 'Hoy';

  @override
  String get photoTravail => 'Foto del trabajo';

  @override
  String get photoAjoutee => 'Foto añadida';

  @override
  String get optionnel => 'Opcional';

  @override
  String get changer => 'Cambiar';

  @override
  String get ajouter => 'Añadir';

  @override
  String get creerLaTache => 'Crear tarea';

  @override
  String get dateExecutionLong => 'Fecha de ejecución';

  @override
  String get dateCreationDetail => 'Fecha de creación';

  @override
  String dateEtHeure(Object date, Object time) {
    return '$date a las $time';
  }

  @override
  String get execution => 'Ejecución';

  @override
  String get statut => 'Estado';

  @override
  String get archivage => 'Archivo';

  @override
  String get parModification => 'Por:';

  @override
  String get inconnu => 'Desconocido';

  @override
  String get tacheCreeeSansNum => 'Tarea creada';

  @override
  String get photoExistante => 'Foto existente';

  @override
  String get nouvellePhoto => 'Nueva foto';

  @override
  String get photoSupprimee => 'Foto eliminada';

  @override
  String get description => 'Descripción';

  @override
  String tachesArchiveesCount(Object count) {
    return '$count tarea(s) archivada(s)';
  }

  @override
  String get desarchiverTacheConfirm => '¿Desarchivar tarea?';

  @override
  String desarchiverTacheQuestion(Object num, Object desc) {
    return '¿Desea desarchivar la tarea $num?\n\n\"$desc\"';
  }

  @override
  String get tacheDesarchiveeRestore =>
      '✅ Tarea desarchivada y restaurada en la lista';

  @override
  String get filtres => 'Filtros';

  @override
  String get filtresEtTri => 'Filtros y orden';

  @override
  String get reinitialiser => 'Restablecer';

  @override
  String get appliquer => 'Aplicar';

  @override
  String get dateModif => 'Fecha modif.';

  @override
  String get ordre => 'Orden:';

  @override
  String get croissant => 'Ascendente ↑';

  @override
  String get decroissant => 'Descendente ↓';

  @override
  String get aucuneTacheArchivee => 'Ninguna tarea archivada';

  @override
  String get reessayer => 'Reintentar';

  @override
  String erreurChargement(Object msg) {
    return 'Error de carga: $msg';
  }

  @override
  String get pasDeConnexionArchives =>
      'Sin conexión a internet.\nLos archivos se almacenan en el servidor remoto.';

  @override
  String get trierPar => 'Ordenar por:';

  @override
  String get ajouterCriterTri => 'Añadir criterio de orden';

  @override
  String get genererRapport => 'Generar informe';

  @override
  String get chargement => 'Cargando...';

  @override
  String get croissantShort => 'Ascendente';

  @override
  String get decroissantShort => 'Descendente';

  @override
  String get retirerCriterTri => 'Quitar este criterio';

  @override
  String get statutLabel => 'Estado:';

  @override
  String resultatsCount(Object count) {
    return '$count resultado(s)';
  }

  @override
  String get partagerEmail => 'Compartir por email';

  @override
  String get imprimer => 'Imprimir';

  @override
  String get identifiantRequired => 'Usuario *';

  @override
  String get seraUtiliseConnexion => 'Se utilizará para iniciar sesión';

  @override
  String get veuillezEntrerIdentifiant => 'Por favor introduzca un usuario';

  @override
  String get min3Caracteres => 'Mínimo 3 caracteres';

  @override
  String get veuillezEntrerMotDePasse => 'Por favor introduzca una contraseña';

  @override
  String get roleUtilisateur => 'Rol del usuario';

  @override
  String get descriptionRoleExecutant => 'Puede ver y ejecutar tareas';

  @override
  String get descriptionRolePlanificateur =>
      'Puede crear y planificar tareas, pero no ejecutarlas';

  @override
  String get descriptionRoleAdmin => 'Acceso completo a la aplicación';

  @override
  String get creerUtilisateur => 'Crear usuario';

  @override
  String get utilisateurModifie => '✅ Usuario actualizado';

  @override
  String get utilisateurCree => '✅ Usuario creado';
}

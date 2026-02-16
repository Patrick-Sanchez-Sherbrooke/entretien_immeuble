
#--------------------------------------------------------------------------
#
#
# Pour générer un fichier unique contenant tout le code des fichiers dart 
# du projet
#
# A exécuter dans le répertoire lib
#
#
#--------------------------------------------------------------------------

# Définir le chemin du fichier de sortie
$outputFile = "projet.txt"

# Supprimer le fichier de sortie s'il existe déjà
if (Test-Path $outputFile) {
    Remove-Item $outputFile
}

# Créer le fichier de sortie
New-Item -Path $outputFile -ItemType File -Force | Out-Null

# Récupérer tous les fichiers .dart récursivement
$dartFiles = Get-ChildItem -Path . -Filter "*.dart" -Recurse -File

# Parcourir chaque fichier .dart
foreach ($file in $dartFiles) {
    # Écrire le nom du fichier avec le format demandé
    Add-Content -Path $outputFile -Value "***dart file:<$($file.Name)>***"
    
    # Ajouter un saut de ligne
    Add-Content -Path $outputFile -Value ""
    
    # Lire et ajouter le contenu du fichier
    $content = Get-Content -Path $file.FullName -Raw
    Add-Content -Path $outputFile -Value $content
    
    # Ajouter un saut de ligne pour séparer les fichiers
    Add-Content -Path $outputFile -Value ""
    Add-Content -Path $outputFile -Value ""
}

Write-Host "Le fichier $outputFile a été créé avec succès!"
Write-Host "Nombre de fichiers .dart traités: $($dartFiles.Count)"
# SensCritique Exporter

Un script Ruby pour exporter vos films notés depuis SensCritique vers un fichier CSV.
Vous pouvez ensuite l'importer dans LetterboxD ici: [LetterboxD importer](https://letterboxd.com/import)

## Prérequis

- Ruby (2.7 ou supérieur)
- Les gems standards (net/http, uri, json, csv, time) sont incluses dans Ruby

## Installation

Aucune installation requise, les dépendances sont toutes des bibliothèques standard Ruby.

## Utilisation

### Utilisation basique

Pour exporter les films de l'utilisateur par défaut (migoo) :

```bash
ruby sens_critique_exporter.rb
```

### Spécifier un nom d'utilisateur

```bash
ruby sens_critique_exporter.rb <username>
```

Exemple :

```bash
ruby sens_critique_exporter.rb john_doe
```

### Spécifier le nom du fichier de sortie

```bash
ruby sens_critique_exporter.rb <username> <fichier_sortie.csv>
```

Exemple :

```bash
ruby sens_critique_exporter.rb john_doe mes_films.csv
```

## Format de sortie

Le script génère un fichier CSV avec les colonnes suivantes :

- **Title** : Titre du film
- **Year** : Année de production
- **Directors** : Réalisateur(s) du film
- **Rating10** : Note attribuée (sur 10)
- **WatchedDate** : Date à laquelle le film a été noté (format YYYY-MM-DD)

## Exemple de sortie

```csv
Title,Year,Directors,Rating10,WatchedDate
Inception,2010,Christopher Nolan,9,2024-03-15
The Shawshank Redemption,1994,Frank Darabont,10,2024-02-20
```

## Notes

- Le script respecte l'API de SensCritique avec des pauses entre les requêtes (0.3 secondes)
- Seuls les films avec une note sont exportés
- Si le profil est privé, le script affichera un message d'erreur approprié
- Le script charge les films par lots de 50

## Dépannage

Si vous rencontrez une erreur "User not found or profile is private" :

- Vérifiez que le nom d'utilisateur est correct
- Assurez-vous que le profil SensCritique est public
- Vérifiez que l'utilisateur a bien noté des films sur SensCritique

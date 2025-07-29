Tesla Datenanalyse – Testprojekt für SQL Views & Eventauswertung

Projektbeschreibung

Dieses Projekt dient als Testumgebung, um SQL-Analysen mithilfe von Views durchzuführen.
Im Fokus stehen fiktive Daten rund um Tesla (z. B. Börsenkurs, Social Media, Medien, Events), um exemplarisch auszuwerten:
    Wie beeinflussen Events (z. B. US-Wahlen, Produktlaunches) verschiedene Datenquellen?
    Welche Zusammenhänge bestehen zwischen Sentiment, Reichweite und Börsenkurs?
    Wie lässt sich Website-Traffic bei Tesla durch externe Ereignisse erklären?

Inhalte

Erstellung der MySQL-Tabellen
Beispiel-INSERTs für fiktive Daten
Alle SQL-Views für Analysen
Fiktive CSV-Daten zum Import
Projektbeschreibung

Hauptdatenquellen (Tabellen)

tesla_stock → Börsenkurse & Volumen
social_media_posts → Posts auf Twitter, Reddit etc.
media_articles → Medienberichte (Print/Online)
tesla_sales → Quartalszahlen (Verkäufe/Umsatz)
website_visits → Besucherzahlen tesla.com
key_events → Events: Wahlen, Produktlaunches etc.

Beispielanalysen (Views)
    Sentiment & Börsenkurs um US-Wahlen
    Absatzentwicklung nach Produktlaunch
    Medienreichweite vs. Kursbewegung
    Website-Traffic rund um Events
    Social Media Stimmung bei Wahlen

Datenimport

Alle CSV-Dateien können manuell oder per SQL importiert werden.

Tools & Anforderungen

MySQL Workbench oder andere MySQL-kompatible Umgebung
MySQL 8.x empfohlen

Lokales Setup (keine API-Anbindungen)

Hinweis
Dieses Projekt dient Lernzwecken und zeigt beispielhaft, wie sich reale Szenarien mit fiktiven Daten simulieren lassen.

Kontakt
Fragen oder Anregungen? Gerne melden!

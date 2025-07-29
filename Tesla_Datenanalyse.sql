/* Tesla-Datenanalyse (01.11.2020 – 31.07.2025)

Ziel:
Analyse, wie Medien, Social Media, politische Großereignisse (US-Wahlen) und andere Faktoren den Tesla-Aktienkurs, Absatzzahlen und Website-Traffic beeinflussen.

Hauptfokus-Events: 
Event											Datum
US-Präsidentschaftswahl 2020					03.11.2020
Tesla Model S Plaid Launch						10.06.2021
Inflation Reduction Act (E-Auto-Förderung USA)	16.08.2022
Elon Musk Twitter-Übernahme						27.10.2022
Cybertruck Launch								30.11.2023
US-Präsidentschaftswahl 2024					05.11.2024
Tesla Quartalszahlen (je Quartal)				fortlaufend

Geplante Analysen:
Analysefrage	   										Datengrundlage
Wie veränderte sich Sentiment & Kurs nach US-Wahlen?	stock + social_media + events
Einfluss Produktlaunch (Cybertruck etc.) auf Absatz?	events + tesla_sales + stock
Social Media Stimmung vor/um Wahlen 2020/2024?			social_media + events
Medienreichweite vs. Kursbewegung?						media_articles + stock
Besucherverhalten auf tesla.com bei Events?				website_visits + events */

-- 1. Datenbank erstellen
CREATE DATABASE IF NOT EXISTS TeslaDatenanalyse;
USE TeslaDatenanalyse;

-- 2. Tabellen erstellen
-- 2.1. Tesla Börsenkurse
CREATE TABLE tesla_stock (
	trade_date DATE PRIMARY KEY,
    closing_price DECIMAL(10,2),
    volume BIGINT,
    price_change DECIMAL(6,2)
);
-- 2.2. Social Media Posts (Twitter, Reddit, YouTube)
CREATE TABLE social_media_posts (
	post_id INT PRIMARY KEY AUTO_INCREMENT,
    platform VARCHAR(50),
    post_date DATE,
    sentiment VARCHAR(10),   -- positive, neutral, negative
    reach INT,
    topic VARCHAR(100),
    content TEXT
);
-- 2.3. Medienberichte (Online, Print)
CREATE TABLE media_articles (
	article_id INT PRIMARY KEY AUTO_INCREMENT,
    media_type VARCHAR(100),
    publish_date DATE,
    sentiment VARCHAR(10),
    topic VARCHAR(100),
    reach_estimate INT,
    content TEXT
);
-- 2.4. Tesla Absatzzahlen
CREATE TABLE tesla_sales (
	sales_quarter VARCHAR(7) PRIMARY KEY, -- Q4-2020 bis Q2-2025
    vehicles_sold INT,
    revenue_billion DECIMAL(10,2)
);
-- 2.5. Website-Traffic
CREATE TABLE website_visits (
	visit_date DATE PRIMARY KEY,
    visitors INT,
    avg_duration_minutes DECIMAL(5,2),
    bounce_rate DECIMAL(5,2)
);
-- 2.6. Wichtige Events (Wahl, Produktlaunch)
CREATE TABLE key_events (
	event_id INT PRIMARY KEY AUTO_INCREMENT,
    event_date DATE,
    event_name VARCHAR(100),
    event_type VARCHAR(50), -- Wahl, Produktlaunch, Politik
    content TEXT
);
INSERT INTO key_events (event_id, event_date, event_name, event_type, content) VALUES
(1, '2020-11-03', 'US Election 2020', 'Wahl', 'Joe Biden elected, impact on EV policy'),
(2, '2021-06-10', 'Model S Plaid Launch', 'Produktlaunch', 'New performance model released'),
(3, '2022-08-16', 'Inflation Reduction Act', 'Politik', 'New E-Auto incentives USA'),
(4, '2022-10-27', 'Elon Musk Twitter Takeover', 'CEO News', 'Social media control implications'),
(5, '2023-11-30', 'Cybertruck Launch', 'Produktlaunch', 'Highly anticipated launch'),
(6, '2024-11-05', 'US Election 2024', 'Wahl', 'Presidential election'),
(7, '2025-01-15', 'Q4 Earnings Release', 'Earnings', 'Strong/weak performance discussion');

-- 3. View: sentiment_stock_wahlanalyse 
/* Wie veränderten sich Sentiment und Kurs nach den US-Wahlen 2020 und 2024?

Ziel des Views:
Zeitraum	            Kursverlauf				Social Media Sentiment (Ø)		Event
7 Tage vor/nach Wahl	Preis, Veränderung		Sentiment-Ø pro Tag				Wahl 2020/2024

Zeitraumwahl pro Wahl:
	Wahl 2020 = 2020-11-03
	Wahl 2024 = 2024-11-05
→ Wir analysieren ±7 Tage um diese Daten. */

CREATE OR REPLACE VIEW sentiment_stock_wahlanalyse AS
SELECT 
    s.trade_date,
    e.event_name,
    e.event_date,
    
    -- Kursdaten
    s.closing_price,
    s.price_change,
    
    -- Ø Sentiment pro Tag (als Score)
    AVG(CASE 
        WHEN sm.sentiment = 'positive' THEN 1
        WHEN sm.sentiment = 'neutral' THEN 0
        WHEN sm.sentiment = 'negative' THEN -1
        ELSE NULL
    END) AS avg_sentiment_score,
    
    COUNT(sm.post_id) AS total_posts
    
FROM tesla_stock s
LEFT JOIN social_media_posts sm ON s.trade_date = sm.post_date
LEFT JOIN key_events e ON e.event_type = 'Wahl' 
    AND s.trade_date BETWEEN DATE_SUB(e.event_date, INTERVAL 7 DAY) 
                          AND DATE_ADD(e.event_date, INTERVAL 7 DAY)

WHERE e.event_name IN ('US Election 2020', 'US Election 2024')
GROUP BY s.trade_date, e.event_name, e.event_date, s.closing_price, s.price_change;

/* TESTS
SELECT * FROM sentiment_stock_wahlanalyse;

SELECT * FROM key_events WHERE event_type = 'Wahl';

SELECT * FROM tesla_stock 
WHERE trade_date BETWEEN '2020-10-27' AND '2020-11-10';

SELECT * FROM tesla_stock 
WHERE trade_date BETWEEN '2024-10-29' AND '2024-11-12';

SELECT * FROM social_media_posts 
WHERE post_date BETWEEN '2020-10-27' AND '2020-11-10'; 
*/

-- 4. Einfluss Produktlaunch auf Absatz & Börsenkurs
/* Ziel:
Untersuchen, ob sich Produktlaunches (z. B. Cybertruck Launch) auf:
	Tesla-Absatzzahlen (tesla_sales) UND
	Tesla-Börsenkurs (tesla_stock) ausgewirkt haben.

Datenquellen:
Tabelle				Inhalt
key_events			Alle Events → Filter: Produktlaunch
tesla_sales			Quartalszahlen Fahrzeuge, Umsatz
tesla_stock			Tageskurse rund um Launch-Datum

Vorgehen (View erstellen):
Produktlaunches isolieren (event_type = 'Produktlaunch')
Für jedes Launch-Datum:
	Finde Umsatz und Verkäufe im gleichen Quartal.
	Finde Kursveränderung ± 7 Tage um Launch. */
    
CREATE OR REPLACE VIEW launch_absatz_impact AS
SELECT 
    e.event_name,
    e.event_date,
    s.sales_quarter,
    s.vehicles_sold,
    s.revenue_billion,
    ts_before.closing_price AS price_before,
    ts_after.closing_price AS price_after,
    ROUND(ts_after.closing_price - ts_before.closing_price, 2) AS price_change
FROM key_events e
JOIN tesla_sales s 
    ON s.sales_quarter = CONCAT('Q', QUARTER(e.event_date), '-', YEAR(e.event_date))
LEFT JOIN tesla_stock ts_before 
    ON ts_before.trade_date = DATE_SUB(e.event_date, INTERVAL 15 DAY)
LEFT JOIN tesla_stock ts_after
    ON ts_after.trade_date = DATE_ADD(e.event_date, INTERVAL 15 DAY)
WHERE e.event_type = 'Produktlaunch';

/* Erklärung:
Spalte				Bedeutung
event_name			z. B. Cybertruck Launch
sales_quarter		Quartal, in dem Launch stattfand
vehicles_sold		Absatz im Quartal
price_before		Börsenkurs 15 Tage vor Launch
price_after			Börsenkurs 15 Tage nach Launch
price_change		Kursveränderung durch Launch*/
-- Query testen:
SELECT * FROM launch_absatz_impact;

-- 5. Social Media Stimmung vor/um Wahlen 2020 & 2024
/* Ziel:
Wie war das Social Media Sentiment rund um die US-Wahlen 2020 & 2024?

Datenquellen:
Tabelle				Inhalt
key_events			US Elections (event_type = 'Wahl')
social_media_posts	Posts mit Datum & Sentiment

Vorgehen:
Finde beide Wahltermine in key_events.
Ermittle Posts ±15 Tage um den jeweiligen Wahltermin.
Aggregiere: Anzahl positiv / neutral / negativ.*/

CREATE OR REPLACE VIEW sentiment_wahlen_view AS
SELECT
	e.event_name,
    e.event_date,
    sm.sentiment,
    COUNT(*) AS anzahl_posts
FROM key_events e
JOIN social_media_posts sm
	ON sm.post_date BETWEEN DATE_SUB(e.event_date, INTERVAL 15 DAY)
						AND DATE_ADD(e.event_date, INTERVAL 15 DAY)
WHERE e.event_type = 'Wahl'
GROUP BY e.event_name, e.event_date, sm.sentiment
ORDER BY e.event_date, sm.sentiment;
-- Query testen:
SELECT * FROM sentiment_wahlen_view;

-- 6. Medienreichweite vs. Kursbewegung
/* Ziel:
Beeinflusst Medien-Reichweite (z. B. Artikel über Tesla) die Kursbewegung?

Datenquellen:
Tabelle				Inhalt
media_articles		Artikel, Sentiment, Reach
tesla_stock			Kursdaten pro Tag, price_change

Vorgehen:
Gruppiere Artikel pro Tag → Summiere reach_estimate pro Tag.
Joine auf tesla_stock → Zeige Kursbewegung (price_change) am selben Tag.
Optional: Filtere z. B. nur Tage mit hoher Reichweite (> X), positiver/negativer Stimmung, etc.*/

CREATE OR REPLACE VIEW media_reach_vs_kurs AS
SELECT
	m.publish_date,
    SUM(m.reach_estimate) AS total_reach,
    COUNT(*) AS artikel_anzahl,
    s.closing_price,
    s.price_change
FROM media_articles m 
JOIN tesla_stock s ON m.publish_date = s.trade_date
GROUP BY m.publish_date, s.closing_price, s.price_change
ORDER BY m.publish_date;
-- Query testen:
SELECT * FROM media_reach_vs_kurs;

-- 7. Besucherverhalten bei Events (z. B. Produktlaunch, Wahl)
/* ZIel:
Wie verändert sich der Website-Traffic (z. B. Besucher, Dauer) rund um Tesla-Events?

Datenquellen:
Tabelle					Inhalt
website_visits			Besucher, Dauer, Bounce Rate pro Tag
key_events				Events (Launches, Wahlen etc.)

Vorgehen:
Betrachte Zeitraum um Events → ± 3 Tage (oder mehr, je nach Wunsch).
Joine Besucherdaten auf Events → Um zu analysieren: Sprung bei Traffic?*/

CREATE OR REPLACE VIEW website_traffic_around_events AS
SELECT
	e.event_date,
    e.event_name,
    e.event_type,
    w.visit_date,
    w.visitors,
    w.avg_duration_minutes,
    w.bounce_rate
FROM key_events e
JOIN website_visits w
	ON w.visit_date BETWEEN DATE_SUB(e.event_date, INTERVAL 15 DAY)
						AND DATE_ADD(e.event_date, INTERVAL 15 DAY)
ORDER BY e.event_date, w.visit_date;
-- Query testen:
SELECT * FROM website_traffic_around_events;

/* Interpretation:
Gab es Besucheranstieg bei Launch?
Unterschied Bounce Rate bei Politik vs. Produkt?*/








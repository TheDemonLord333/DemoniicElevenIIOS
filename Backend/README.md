# Demonic Eleven – Multiplayer-Backend

WebSocket-Server für den Online-Multiplayer von Demonic Eleven. Zwei Spieler
werden automatisch gematcht, der Server ist die einzige Instanz, die den
Spielstand kennt und Züge validiert (kein Cheaten über den Client möglich).

## Wie es funktioniert

- `src/gameRules.js` – reine Spielregeln (max. 10 pro Zug, nicht über 100 hinaus).
- `src/match.js` – ein `Match` hält zwei Spieler, den aktuellen Stand und wer am Zug ist.
- `src/matchmaking.js` – einfache Warteschlange: der erste wartende Spieler wird mit dem nächsten verbunden.
- `src/server.js` – WebSocket-Server (`ws`) + ein `/health`-Endpunkt für Monitoring.

### Protokoll (JSON über WebSocket)

**Client → Server**

| type   | Felder        | Bedeutung                          |
|--------|---------------|-------------------------------------|
| `join` | –             | In die Matchmaking-Warteschlange    |
| `move` | `value` (1–10)| Zug ausführen (nur wenn man am Zug ist) |
| `leave`| –             | Warteschlange verlassen / Match aufgeben |

**Server → Client**

| type          | Felder                                   | Bedeutung                          |
|---------------|-------------------------------------------|--------------------------------------|
| `welcome`     | `playerId`                                | Verbindung hergestellt               |
| `queued`      | –                                          | Wartet auf Gegner                    |
| `matchFound`  | `matchId`, `yourTurn`                     | Gegner gefunden, Spiel beginnt       |
| `move`        | `isYou`, `value`, `from`, `to`            | Ein Zug wurde ausgeführt (von dir oder dem Gegner) |
| `state`       | `total`, `yourTurn`, `winner` (`you`/`opponent`/`null`) | Aktueller Spielstand |
| `opponentLeft`| –                                          | Gegner hat die Verbindung getrennt   |
| `error`       | `message`                                  | z. B. `not_your_turn`, `invalid_move`|

Die Texte wie „Du hast 5 hinzugefügt! 11 -> 16“ werden weiterhin **im
iOS-Client** aus `from`/`to`/`isYou` gebaut (analog zur bestehenden lokalen
Logik in `GameViewModel.swift`) – der Server schickt nur die rohen Zahlen.

## Lokal starten

```bash
cd Backend
npm install
npm start
# Server läuft auf ws://localhost:4000, Health-Check: http://localhost:4000/health
```

---

## Installation auf dem Server (nginx + pm2 sind bereits vorhanden)

### 1. Node.js installieren (falls noch nicht vorhanden)

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt-get install -y nodejs
node --version   # sollte v18 oder neuer sein
```

### 2. Projekt auf den Server bringen

```bash
cd /var/www
git clone https://github.com/TheDemonLord333/DemoniicElevenIIOS.git
cd DemoniicElevenIIOS/Backend
npm install --production
```

### 3. Umgebungsvariablen setzen

```bash
cp .env.example .env
# Port bei Bedarf anpassen, PM2 liest ihn aus ecosystem.config.js (env.PORT)
```

### 4. Mit PM2 starten

```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup   # gibt einen Befehl aus, der PM2 beim Server-Neustart automatisch startet – den Befehl einmalig ausführen
```

Nützliche PM2-Befehle:

```bash
pm2 status
pm2 logs demonic-eleven-backend
pm2 restart demonic-eleven-backend
```

### 5. Nginx als Reverse-Proxy vor den WebSocket-Server schalten

Der Server lauscht nur intern auf `127.0.0.1:4000`. Nginx nimmt die
öffentlichen Verbindungen an und leitet sie mit den nötigen
`Upgrade`-Headern weiter, sonst funktioniert kein WebSocket-Handshake.

Neue Datei `/etc/nginx/sites-available/demonic-eleven`:

```nginx
server {
    listen 80;
    server_name game.deine-domain.tld;

    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # WebSockets brauchen laenger offene Verbindungen als der Default
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }
}
```

Aktivieren und neu laden:

```bash
sudo ln -s /etc/nginx/sites-available/demonic-eleven /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 6. HTTPS/TLS (Pflicht, iOS erlaubt keine unverschlüsselten WebSockets in Produktion)

```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d game.deine-domain.tld
```

Certbot passt den nginx-Server-Block automatisch für `443` + TLS an und
richtet die automatische Zertifikatserneuerung ein. Der iOS-Client verbindet
sich danach über `wss://game.deine-domain.tld` (nicht `ws://`).

### 7. Testen

```bash
curl https://game.deine-domain.tld/health
# {"status":"ok"}

# WebSocket-Verbindung testen (z. B. mit wscat, npm i -g wscat)
wscat -c wss://game.deine-domain.tld
> {"type":"join"}
```

Wenn zwei `wscat`-Sitzungen gleichzeitig `{"type":"join"}` senden, sollten
beide `matchFound` erhalten.

## Bekannte Einschränkungen (bewusst nicht umgesetzt)

- Kein Reconnect nach Verbindungsabbruch – ein Verbindungsabbruch beendet
  das Match für beide Seiten.
- Keine Accounts/Historie – Spieler sind nur für die Dauer der WebSocket-
  Verbindung identifiziert.
- Kein Rematch-Flow – nach einem Sieg muss der Client neu verbinden bzw.
  erneut `join` senden.

Diese Punkte lassen sich bei Bedarf ergänzen, sind für den ersten
funktionierenden Online-Multiplayer aber nicht nötig.

## Nächster Schritt

Der iOS-Client verbindet sich noch nicht mit diesem Server – das ist ein
eigener Schritt (WebSocket-Client in Swift, z. B. mit `URLSessionWebSocketTask`,
plus ein Online-Spielmodus in der UI).

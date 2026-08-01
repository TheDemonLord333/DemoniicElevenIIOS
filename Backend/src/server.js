'use strict';

require('dotenv').config();

const http = require('http');
const { randomUUID } = require('crypto');
const { WebSocketServer } = require('ws');
const { Matchmaker } = require('./matchmaking');

const PORT = process.env.PORT || 4000;
const matchmaker = new Matchmaker();

const httpServer = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
    return;
  }
  res.writeHead(404);
  res.end();
});

const wss = new WebSocketServer({ server: httpServer });

function send(player, payload) {
  if (player.socket.readyState === player.socket.OPEN) {
    player.socket.send(JSON.stringify(payload));
  }
}

function broadcastState(match) {
  for (const player of match.players) {
    send(player, {
      type: 'state',
      total: match.total,
      yourTurn: !match.winnerId && match.currentPlayer() === player,
      winner: match.winnerId ? (match.winnerId === player.id ? 'you' : 'opponent') : null,
    });
  }
}

function leaveMatch(player) {
  const match = player.match;
  if (!match || match.winnerId) return;
  const opponent = match.opponentOf(player);
  opponent.match = null;
  send(opponent, { type: 'opponentLeft' });
  player.match = null;
}

wss.on('connection', (socket) => {
  const player = { id: randomUUID(), socket, match: null };

  send(player, { type: 'welcome', playerId: player.id });

  socket.on('message', (raw) => {
    let message;
    try {
      message = JSON.parse(raw.toString());
    } catch {
      send(player, { type: 'error', message: 'invalid_json' });
      return;
    }

    switch (message.type) {
      case 'join': {
        if (player.match) return;
        const match = matchmaker.enqueue(player);
        if (match) {
          for (const p of match.players) {
            send(p, {
              type: 'matchFound',
              matchId: match.id,
              yourTurn: match.currentPlayer() === p,
            });
          }
        } else {
          send(player, { type: 'queued' });
        }
        break;
      }

      case 'move': {
        const match = player.match;
        if (!match) {
          send(player, { type: 'error', message: 'no_match' });
          return;
        }
        try {
          const result = match.applyMove(player, message.value);
          for (const p of match.players) {
            send(p, {
              type: 'move',
              isYou: result.byPlayerId === p.id,
              value: message.value,
              from: result.from,
              to: result.to,
            });
          }
          broadcastState(match);
        } catch (err) {
          send(player, { type: 'error', message: err.message });
        }
        break;
      }

      case 'leave': {
        matchmaker.dequeue(player);
        leaveMatch(player);
        break;
      }

      default:
        send(player, { type: 'error', message: 'unknown_type' });
    }
  });

  socket.on('close', () => {
    matchmaker.dequeue(player);
    leaveMatch(player);
  });
});

httpServer.listen(PORT, () => {
  console.log(`Demonic Eleven backend laeuft auf Port ${PORT}`);
});

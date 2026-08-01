'use strict';

const { Match } = require('./match');

class Matchmaker {
  constructor() {
    this.waitingPlayer = null;
  }

  // Reiht einen Spieler ein. Gibt das neue Match zurueck, sobald zwei
  // Spieler zusammengefunden haben, sonst null (Spieler wartet).
  enqueue(player) {
    if (this.waitingPlayer && this.waitingPlayer !== player) {
      const opponent = this.waitingPlayer;
      this.waitingPlayer = null;
      return new Match(opponent, player);
    }
    this.waitingPlayer = player;
    return null;
  }

  dequeue(player) {
    if (this.waitingPlayer === player) {
      this.waitingPlayer = null;
    }
  }
}

module.exports = { Matchmaker };

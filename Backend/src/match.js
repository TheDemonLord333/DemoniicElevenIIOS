'use strict';

const { randomUUID } = require('crypto');
const { TARGET, isValidMove } = require('./gameRules');

class Match {
  constructor(playerA, playerB) {
    this.id = randomUUID();
    this.players = [playerA, playerB];
    this.total = 0;
    this.winnerId = null;
    this.turnIndex = Math.random() < 0.5 ? 0 : 1;

    playerA.match = this;
    playerB.match = this;
  }

  currentPlayer() {
    return this.players[this.turnIndex];
  }

  opponentOf(player) {
    return this.players[0] === player ? this.players[1] : this.players[0];
  }

  applyMove(player, value) {
    if (this.winnerId) throw new Error('match_over');
    if (this.currentPlayer() !== player) throw new Error('not_your_turn');
    if (!isValidMove(this.total, value)) throw new Error('invalid_move');

    const from = this.total;
    this.total += value;

    if (this.total === TARGET) {
      this.winnerId = player.id;
    } else {
      this.turnIndex = 1 - this.turnIndex;
    }

    return { from, to: this.total, byPlayerId: player.id, winnerId: this.winnerId };
  }
}

module.exports = { Match };

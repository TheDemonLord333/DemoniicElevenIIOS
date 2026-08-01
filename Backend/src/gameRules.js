'use strict';

const TARGET = 100;
const MAX_STEP = 10;

function maxSelectable(total) {
  return Math.min(MAX_STEP, TARGET - total);
}

function isValidMove(total, value) {
  return Number.isInteger(value) && value >= 1 && value <= maxSelectable(total);
}

module.exports = { TARGET, MAX_STEP, maxSelectable, isValidMove };

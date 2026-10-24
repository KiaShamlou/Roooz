// Frozen upstream source with its license: no network and no Rooz-derived fixtures.
const { j2d, jalaaliMonthLength } = require('../tests/vendor/jalaali-js-1.2.8.cjs');
const { writeSync } = require('node:fs');
let batch = '';
for (let y = 1; y <= 3177; y++) for (let m = 1; m <= 12; m++) {
  for (const d of [1, 15, jalaaliMonthLength(y, m)]) {
    batch += `${j2d(y, m, d) - 2440588}\t${y}\t${m}\t${d}\n`;
    if (batch.length > 65536) { writeSync(1, batch); batch = ''; }
  }
}
if (batch) writeSync(1, batch);

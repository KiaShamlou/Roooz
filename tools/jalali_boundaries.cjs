// Derived only from pinned jalaali-js 1.2.8, not from the C implementation.
const { j2d, jalaaliMonthLength } = require('../tests/vendor/jalaali-js-1.2.8.cjs');
for (let y = 1; y <= 3177; y++) {
  for (const [m,d] of [[1,1], [12,jalaaliMonthLength(y,12)]])
    console.log(`${j2d(y,m,d)-2440588}\t${y}\t${m}\t${d}`);
}

/* Manually transcribed factual month lengths + first weekdays (Monday=1).
   University of Tehran Calendar Center, abstract-1405.pdf, page 1.
   Source: https://calendar.ut.ac.ir/documents/2139738/7092644/abstract-1405.pdf
   Retrieved 2026-10-24; visually checked against all twelve month panels.
   SHA256: 218cfa5b22f712f8f08d07dbd579f93e2972a34d773b08766d93ae5e8ed0b8cc
   No holiday, lunar-calendar or Gregorian conversion claim is encoded here. */
static const int official_1405[12][2] = {
    {31,6}, {31,2}, {31,5}, {31,1}, {31,4}, {31,7},
    {30,3}, {30,5}, {30,7}, {30,2}, {30,4}, {29,6}
};

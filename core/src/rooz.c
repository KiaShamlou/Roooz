#include "rooz.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* Jalali break-year computation adapted from jalaali-js 1.2.8 (MIT).
 * Copyright (c) 2020 Behrang Norouzinia. See THIRD_PARTY_NOTICES.md.
 * Integer division/remainder here deliberately truncate toward zero. */
static int jalali_march(int y, int *leap) {
    static const int breaks[] = {-61,9,38,199,426,686,756,818,1111,1181,1210,
        1635,2060,2097,2192,2262,2324,2394,2456,3178};
    int gy=y+621, leap_j=-14, jp=breaks[0], jump=0, n, i;
    for (i=1; i<20; ++i) {
        int jm=breaks[i]; jump=jm-jp;
        if (y<jm) break;
        leap_j += (jump/33)*8 + (jump%33)/4; jp=jm;
    }
    n=y-jp;
    leap_j += (n/33)*8 + ((n%33)+3)/4;
    if (jump%33==4 && jump-n==4) ++leap_j;
    int march=20+leap_j-(gy/4-((gy/100+1)*3)/4-150);
    if (jump-n<6) n=n-jump+((jump+4)/33)*33;
    *leap=((n+1)%33-1)%4;
    if (*leap==-1) *leap=4;
    return march;
}
static int valid_year(int c, int y) {
    return c>=0 && c<=3 && y>=1 && y<=(c==RC_JALALI?3177:9999);
}
int32_t rc_abi_version(void) { return 1; }
const char *rc_status_message(int32_t s) {
    static const char *messages[]={"ok","invalid input","reversed range","out of bounds",
        "range too short","range too long","disabled date","buffer too small","invalid pattern"};
    return s>=0 && s<=8 ? messages[s] : "unknown status";
}
int32_t rc_days_in_month(int32_t c,int32_t y,int32_t m) {
    static const int lengths[]={31,28,31,30,31,30,31,31,30,31,30,31};
    if (!valid_year(c,y) || m<1 || m>12) return 0;
    if (c==RC_JALALI) {
        int leap; jalali_march(y,&leap);
        return m<=6?31:m<=11?30:leap==0?30:29;
    }
    if (c==RC_ISLAMIC_CIVIL) return m==12 ? 29+((11*y+14)%30<11) : (m%2?30:29);
    return lengths[m-1]+(m==2 && y%4==0 && (c==RC_JULIAN || y%100!=0 || y%400==0));
}
static int32_t solar_day(int c,int y,int m,int d) {
    int a=(14-m)/12, yy=y+4800-a, mm=m+12*a-3;
    int jdn=d+(153*mm+2)/5+365*yy+yy/4;
    jdn += c==RC_JULIAN ? -32083 : -yy/100+yy/400-32045;
    return jdn-2440588;
}
static int32_t raw_day(int c,int y,int m,int d) {
    if (c==RC_JALALI) {
        int leap, march=jalali_march(y,&leap);
        return solar_day(RC_GREGORIAN,y+621,3,march)+(m-1)*31-(m/7)*(m-7)+d-1;
    }
    if (c==RC_ISLAMIC_CIVIL)
        return 1948440-2440588+354*(y-1)+(3+11*y)/30+(59*(m-1)+1)/2+d-1;
    return solar_day(c,y,m,d);
}
int32_t rc_to_day(int32_t c,int32_t y,int32_t m,int32_t d) {
    int length=rc_days_in_month(c,y,m);
    return d<1 || d>length ? RC_INVALID_DAY : raw_day(c,y,m,d);
}
static int parts(int c,int32_t day,int *y,int *m,int *d) {
    int max=c==RC_JALALI?3177:9999;
    if (!valid_year(c,1) || day<raw_day(c,1,1,1) ||
        day>raw_day(c,max,12,rc_days_in_month(c,max,12))) return 0;
    int lo=1, hi=max;
    while (lo<hi) {
        int mid=lo+(hi-lo+1)/2;
        if (raw_day(c,mid,1,1)<=day) lo=mid; else hi=mid-1;
    }
    *y=lo; *m=1;
    int remaining=day-raw_day(c,lo,1,1);
    while (remaining>=rc_days_in_month(c,*y,*m)) remaining-=rc_days_in_month(c,*y,(*m)++);
    *d=remaining+1; return 1;
}
static int weekday(int32_t day) { int r=(day+3)%7; return (r<0?r+7:r)+1; }
int32_t rc_get_field(int32_t c,int32_t day,int32_t field) {
    int y,m,d;
    if (!parts(c,day,&y,&m,&d)) return RC_INVALID_DAY;
    switch (field) {
        case RC_YEAR: return y; case RC_MONTH: return m; case RC_DAY: return d;
        case RC_WEEKDAY: return weekday(day); case RC_MONTH_LENGTH: return rc_days_in_month(c,y,m);
        case RC_DAY_OF_YEAR: return day-raw_day(c,y,1,1)+1; default: return RC_INVALID_DAY;
    }
}
int32_t rc_add_days(int32_t c,int32_t day,int32_t n) {
    int y,m,d; int64_t result=(int64_t)day+n;
    if (!parts(c,day,&y,&m,&d) || result<=INT32_MIN || result>INT32_MAX ||
        !parts(c,(int32_t)result,&y,&m,&d)) return RC_INVALID_DAY;
    return (int32_t)result;
}
int32_t rc_add_months(int32_t c,int32_t day,int32_t n,int32_t overflow) {
    int y,m,d;
    if ((overflow!=RC_CLAMP && overflow!=RC_REJECT) || !parts(c,day,&y,&m,&d)) return RC_INVALID_DAY;
    int64_t index=(int64_t)(y-1)*12+m-1+n;
    int max=c==RC_JALALI?3177:9999;
    if (index<0 || index>=(int64_t)max*12) return RC_INVALID_DAY;
    y=(int)(index/12)+1; m=(int)(index%12)+1;
    int length=rc_days_in_month(c,y,m);
    if (d>length) { if (overflow==RC_REJECT) return RC_INVALID_DAY; d=length; }
    return raw_day(c,y,m,d);
}
int32_t rc_grid_start(int32_t c,int32_t y,int32_t m,int32_t first) {
    int32_t day=rc_to_day(c,y,m,1);
    if (day==RC_INVALID_DAY || first<1 || first>7) return RC_INVALID_DAY;
    return day-(weekday(day)-first+7)%7;
}
static int valid_rules(const rc_rules *r) {
    return r && r->min_day!=RC_INVALID_DAY && r->max_day!=RC_INVALID_DAY &&
        r->min_day<=r->max_day && r->min_length>=1 && r->max_length>=r->min_length &&
        r->disabled_weekdays<128 && (!r->blocked_count || r->blocked_days);
}
int32_t rc_validate_range(int32_t start,int32_t end,const rc_rules *r) {
    if (start==RC_INVALID_DAY || end==RC_INVALID_DAY || !valid_rules(r)) return RC_INVALID;
    if (start>end) return RC_REVERSED;
    if (start<r->min_day || end>r->max_day) return RC_OUT_OF_BOUNDS;
    int64_t length=(int64_t)end-start+1;
    if (length<r->min_length) return RC_TOO_SHORT;
    if (length>r->max_length) return RC_TOO_LONG;
    /* Inspect at most one week, not every day in a long interval. */
    int count=length<7?(int)length:7;
    for (int i=0;i<count;++i) {
        int wd=(int)(((int64_t)start+3+i)%7); if (wd<0) wd+=7;
        if (r->disabled_weekdays & (1u<<wd)) return RC_DISABLED;
    }
    for (size_t i=0;i<r->blocked_count;++i)
        if (r->blocked_days[i]>=start && r->blocked_days[i]<=end) return RC_DISABLED;
    return RC_OK;
}
int32_t rc_select(int32_t mode,rc_selection current,int32_t tap,const rc_rules *r,rc_selection *out) {
    if (!out || !valid_rules(r) || (mode!=RC_SINGLE && mode!=RC_RANGE)) return RC_INVALID;
    if ((current.start==RC_INVALID_DAY && current.end!=RC_INVALID_DAY) ||
        (current.end!=RC_INVALID_DAY && current.start>current.end)) return RC_INVALID;
    rc_selection result; rc_rules one=*r; one.min_length=1;
    int status=rc_validate_range(tap,tap,&one);
    if (status) return status;
    if (mode==RC_SINGLE) { result.start=tap; result.end=tap; }
    else if (current.start==RC_INVALID_DAY || current.end!=RC_INVALID_DAY) {
        result.start=tap; result.end=RC_INVALID_DAY;
    } else {
        result.start=current.start<tap?current.start:tap;
        result.end=current.start>tap?current.start:tap;
        status=rc_validate_range(result.start,result.end,r);
        if (status) return status;
    }
    *out=result; return RC_OK;
}

#include "locales.inc"
const rc_locale *rc_builtin_locale(int32_t c,int32_t locale) {
    if (c<0 || c>3 || locale<0 || locale>2) return NULL;
    return &locales[c==RC_JULIAN?RC_GREGORIAN:c][locale];
}
typedef struct { char *out; size_t size, used; int failed; } writer;
static void append(writer *w,const char *s) {
    size_t n=strlen(s);
    if (w->used>=w->size || n>=w->size-w->used) { w->failed=1; return; }
    memcpy(w->out+w->used,s,n); w->used+=n; w->out[w->used]=0;
}
static void number(writer *w,int value,int width,int digits) {
    static const char *fa[]={"۰","۱","۲","۳","۴","۵","۶","۷","۸","۹"};
    static const char *ar[]={"٠","١","٢","٣","٤","٥","٦","٧","٨","٩"};
    char text[24]; snprintf(text,sizeof text,"%0*d",width,value);
    for (const char *p=text;*p;++p) {
        char ascii[2]={*p,0};
        append(w,digits==RC_PERSIAN?fa[*p-'0']:digits==RC_ARABIC?ar[*p-'0']:ascii);
    }
}
int32_t rc_format(int32_t c,int32_t day,const char *pattern,const rc_locale *locale,int32_t digits,char *out,size_t cap) {
    if (out && cap) out[0]=0;
    int y,m,d;
    if (!out || !cap) return RC_BUFFER_SMALL;
    if (!pattern || !parts(c,day,&y,&m,&d) || digits<0 || digits>2) return RC_INVALID;
    if (!locale) locale=rc_builtin_locale(c,0);
    writer w={out,cap,0,0};
    for (const char *p=pattern;*p;++p) {
        if (*p!='%') { char literal[2]={*p,0}; append(&w,literal); continue; }
        ++p;
        switch (*p) {
            case 'Y': number(&w,y,4,digits); break;
            case 'm': number(&w,m,2,digits); break;
            case 'd': number(&w,d,2,digits); break;
            case 'u': number(&w,weekday(day),1,digits); break;
            case 'j': number(&w,day-raw_day(c,y,1,1)+1,3,digits); break;
            case 'B': if (!locale->months[m-1]) { out[0]=0; return RC_INVALID; }
                append(&w,locale->months[m-1]); break;
            case 'A': if (!locale->weekdays[weekday(day)-1]) { out[0]=0; return RC_INVALID; }
                append(&w,locale->weekdays[weekday(day)-1]); break;
            case '%': append(&w,"%"); break;
            default: out[0]=0; return RC_PATTERN;
        }
    }
    if (w.failed) { out[0]=0; return RC_BUFFER_SMALL; }
    return RC_OK;
}
static int read_digit(const unsigned char **p) {
    if (**p>='0' && **p<='9') return *(*p)++-'0';
    if ((*p)[0]==0xdb && (*p)[1]>=0xb0 && (*p)[1]<=0xb9) { int n=(*p)[1]-0xb0; *p+=2; return n; }
    if ((*p)[0]==0xd9 && (*p)[1]>=0xa0 && (*p)[1]<=0xa9) { int n=(*p)[1]-0xa0; *p+=2; return n; }
    return -1;
}
int32_t rc_parse(int32_t c,const char *text,const char *pattern) {
    if (!text || !pattern) return RC_INVALID_DAY;
    int values[3]={0,0,0}, seen=0;
    const unsigned char *s=(const unsigned char *)text;
    for (const char *p=pattern;*p;++p) {
        if (*p!='%') { if (*s!=(unsigned char)*p) return RC_INVALID_DAY; ++s; continue; }
        ++p;
        int index=*p=='Y'?0:*p=='m'?1:*p=='d'?2:-1;
        if (index<0 || (seen&(1<<index))) return RC_INVALID_DAY;
        seen|=1<<index;
        for (int i=0;i<(index==0?4:2);++i) {
            int n=read_digit(&s); if (n<0) return RC_INVALID_DAY;
            values[index]=values[index]*10+n;
        }
    }
    return seen==7 && !*s ? rc_to_day(c,values[0],values[1],values[2]) : RC_INVALID_DAY;
}
void *rc_alloc(size_t size) { return malloc(size); }
void rc_free(void *memory) { free(memory); }

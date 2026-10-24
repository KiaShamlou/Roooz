#include "rooz.h"
#include "fixtures/official_1405.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
static unsigned long checks=0;
#define CHECK(x) do { ++checks; if (!(x)) { fprintf(stderr,"FAIL %s:%d: %s\n",__FILE__,__LINE__,#x); exit(1); } } while(0)

static void dates(void) {
    CHECK(rc_abi_version()==1);
    CHECK(rc_to_day(0,1970,1,1)==0);
    CHECK(rc_to_day(1,1403,1,1)==rc_to_day(0,2024,3,20));
    CHECK(rc_to_day(1,1404,1,1)==rc_to_day(0,2025,3,21));
    CHECK(rc_to_day(1,1405,1,1)==rc_to_day(0,2026,3,21));
    CHECK(rc_to_day(2,1,1,1)==rc_to_day(0,622,7,19));
    CHECK(rc_to_day(3,1582,10,5)==rc_to_day(0,1582,10,15));
    CHECK(rc_days_in_month(1,1399,12)==30);
    CHECK(rc_days_in_month(1,1400,12)==29);
    CHECK(rc_days_in_month(0,1900,2)==28);
    CHECK(rc_days_in_month(0,2000,2)==29);
    CHECK(rc_days_in_month(3,1900,2)==29);
    CHECK(rc_get_field(0,0,RC_WEEKDAY)==4);
    CHECK(rc_get_field(0,-1,RC_WEEKDAY)==3);
    CHECK(rc_to_day(1,1400,12,30)==RC_INVALID_DAY);
    CHECK(rc_to_day(1,3178,1,1)==RC_INVALID_DAY);
    CHECK(rc_to_day(9,2024,1,1)==RC_INVALID_DAY);
    CHECK(rc_to_day(0,INT_MAX,1,1)==RC_INVALID_DAY);
    CHECK(rc_get_field(1,INT_MAX,0)==RC_INVALID_DAY);
    CHECK(rc_get_field(1,INT_MIN,0)==RC_INVALID_DAY);
    CHECK(rc_add_days(1,0,INT_MAX)==RC_INVALID_DAY);
    CHECK(rc_add_months(1,0,INT_MIN,0)==RC_INVALID_DAY);
    int32_t last=rc_to_day(1,1403,6,31);
    CHECK(rc_add_months(1,last,1,0)==rc_to_day(1,1403,7,30));
    CHECK(rc_add_months(1,last,1,1)==RC_INVALID_DAY);
    CHECK(rc_add_months(1,rc_to_day(1,1403,1,1),-1,0)==rc_to_day(1,1402,12,1));
    CHECK(rc_grid_start(1,1403,1,6)==rc_to_day(1,1402,12,26));
    CHECK(rc_grid_start(1,1403,1,0)==RC_INVALID_DAY);
    /* Every supported day in all four calendars; adjacency + round-trip. */
    unsigned long dates=0;
    for (int c=0;c<4;++c) {
        int max=c==1?3177:9999;
        int32_t previous=rc_to_day(c,1,1,1)-1;
        for (int y=1;y<=max;++y) for (int m=1;m<=12;++m) {
            int length=rc_days_in_month(c,y,m);
            CHECK(rc_to_day(c,y,m,length+1)==RC_INVALID_DAY);
            for (int d=1;d<=length;++d) {
                int32_t day=rc_to_day(c,y,m,d);
                CHECK(day==previous+1); previous=day;
                CHECK(rc_get_field(c,day,0)==y);
                CHECK(rc_get_field(c,day,1)==m);
                CHECK(rc_get_field(c,day,2)==d); ++dates;
            }
        }
        CHECK(rc_get_field(c,previous+1,0)==RC_INVALID_DAY);
        CHECK(rc_get_field(c,rc_to_day(c,1,1,1)-1,0)==RC_INVALID_DAY);
        CHECK(rc_add_days(c,previous,1)==RC_INVALID_DAY);
    }
    printf("PASS exhaustive: %lu civil dates\n",dates);
}
static void official_calendar(void) {
    unsigned count = 0;
    for (int month = 1; month <= 12; ++month) {
        const int length = official_1405[month-1][0];
        const int weekday = official_1405[month-1][1];
        CHECK(rc_days_in_month(RC_JALALI, 1405, month) == length);
        CHECK(rc_to_day(RC_JALALI, 1405, month, length+1) == RC_INVALID_DAY);
        for (int day = 1; day <= length; ++day) {
            int epoch = rc_to_day(RC_JALALI, 1405, month, day);
            CHECK(rc_get_field(RC_JALALI, epoch, RC_WEEKDAY) == (weekday+day-2)%7+1);
            ++count;
        }
    }
    CHECK(count == 365);
    puts("PASS official 1405: 12 month lengths, 365 weekday positions");
}
static void formatting(void) {
    char out[256]; int32_t day=rc_to_day(1,1403,1,1);
    CHECK(rc_format(1,day,"%A %d %B %Y",rc_builtin_locale(1,1),1,out,sizeof out)==0);
    CHECK(strcmp(out,"چهارشنبه ۰۱ فروردین ۱۴۰۳")==0);
    CHECK(rc_format(1,day,"%Y/%m/%d (%u,%j) %%",NULL,0,out,sizeof out)==0);
    CHECK(strcmp(out,"1403/01/01 (3,001) %")==0);
    CHECK(rc_format(1,day,"%Y",NULL,0,out,4)==RC_BUFFER_SMALL && out[0]==0);
    CHECK(rc_format(1,day,"%Q",NULL,0,out,sizeof out)==RC_PATTERN && out[0]==0);
    CHECK(rc_format(1,day,"%",NULL,0,out,sizeof out)==RC_PATTERN);
    CHECK(rc_parse(1,"۱۴۰۳/۰۱/۰۱","%Y/%m/%d")==day);
    CHECK(rc_parse(1,"١٤٠٣-٠١-٠١","%Y-%m-%d")==day);
    CHECK(rc_parse(1,"01.01.1403","%d.%m.%Y")==day);
    const char *bad[]={"1403/1/01","1403/01/01extra","1403/00/00","1400/12/30","1403/01/01 ","","\xdb","\xd9"};
    for (size_t i=0;i<sizeof bad/sizeof bad[0];++i) CHECK(rc_parse(1,bad[i],"%Y/%m/%d")==RC_INVALID_DAY);
    CHECK(rc_parse(1,"1403/01/01","%Y/%m/%m")==RC_INVALID_DAY);
    CHECK(rc_parse(1,"1403","%Y")==RC_INVALID_DAY);
    CHECK(rc_parse(1,"","%")==RC_INVALID_DAY);
    rc_locale custom=*rc_builtin_locale(1,0); custom.months[0]="Custom month";
    CHECK(rc_format(1,day,"%B",&custom,0,out,sizeof out)==0 && strcmp(out,"Custom month")==0);
    puts("PASS formatting: UTF-8, custom names, digits, strict parsing, buffers");
}
static void selection(void) {
    int32_t blocked[]={15};
    rc_rules r={0,100,2,20,0,blocked,1};
    CHECK(rc_validate_range(10,20,&r)==RC_DISABLED);
    CHECK(rc_validate_range(10,11,&r)==RC_OK);
    CHECK(rc_validate_range(10,10,&r)==RC_TOO_SHORT);
    CHECK(rc_validate_range(20,10,&r)==RC_REVERSED);
    CHECK(rc_validate_range(-1,10,&r)==RC_OUT_OF_BOUNDS);
    CHECK(rc_validate_range(20,50,&r)==RC_TOO_LONG);
    r.disabled_weekdays=1u<<4; /* Friday */
    CHECK(rc_validate_range(0,2,&r)==RC_DISABLED);
    r.disabled_weekdays=0;
    rc_selection s={RC_INVALID_DAY,RC_INVALID_DAY};
    CHECK(rc_select(RC_RANGE,s,12,&r,&s)==RC_OK && s.start==12 && s.end==RC_INVALID_DAY);
    CHECK(rc_select(RC_RANGE,s,10,&r,&s)==RC_OK && s.start==10 && s.end==12);
    CHECK(rc_select(RC_RANGE,s,14,&r,&s)==RC_OK && s.end==RC_INVALID_DAY);
    CHECK(rc_select(RC_RANGE,s,17,&r,&s)==RC_DISABLED && s.start==14 && s.end==RC_INVALID_DAY);
    CHECK(rc_select(RC_SINGLE,s,20,&r,&s)==RC_OK && s.start==20 && s.end==20);
    CHECK(rc_select(2,s,20,&r,&s)==RC_INVALID);
    CHECK(rc_validate_range(0,1,NULL)==RC_INVALID);
    rc_rules huge={INT_MIN+1,INT_MAX,1,INT_MAX,127,NULL,0};
    CHECK(rc_validate_range(INT_MIN+1,INT_MAX,&huge)==RC_TOO_LONG);
    CHECK(rc_validate_range(INT_MAX-1,INT_MAX,&huge)==RC_DISABLED);
    puts("PASS selection: reverse taps, interior blocks, limits, atomic rejection");
}
static void oracle(const char *path) {
    FILE *f=fopen(path,"r"); CHECK(f!=NULL);
    int day,jy,jm,jd,hy,hm,hd; unsigned long count=0;
    while (fscanf(f,"%d %d %d %d %d %d %d",&day,&jy,&jm,&jd,&hy,&hm,&hd)==7) {
        CHECK(rc_to_day(1,jy,jm,jd)==day); CHECK(rc_to_day(2,hy,hm,hd)==day); ++count;
    }
    CHECK(feof(f)); CHECK(count>100000); fclose(f);
    printf("PASS ICU differential: %lu days x 2 calendars\n",count);
}
static void reference(const char *path) {
    FILE *f=fopen(path,"r"); CHECK(f!=NULL);
    int day,y,m,d; unsigned long count=0;
    while (fscanf(f,"%d %d %d %d",&day,&y,&m,&d)==4) {
        CHECK(rc_to_day(1,y,m,d)==day);
        CHECK(rc_get_field(1,day,0)==y);
        CHECK(rc_get_field(1,day,1)==m);
        CHECK(rc_get_field(1,day,2)==d); ++count;
    }
    CHECK(feof(f)); CHECK(count==114372); fclose(f);
    printf("PASS pinned Borkowski reference: %lu month samples\n",count);
}
static void malformed(void) {
    unsigned state=123456789u;
    for (int i=0;i<20000;++i) {
        char text[32];
        for (size_t j=0;j<sizeof text-1;++j) { state=1664525u*state+1013904223u; text[j]=(char)(state>>24); }
        text[31]=0;
        int32_t result=rc_parse(1,text,"%Y/%m/%d");
        CHECK(result==RC_INVALID_DAY || rc_get_field(1,result,0)!=RC_INVALID_DAY);
    }
    puts("PASS malformed input: 20000 deterministic byte strings");
}
int main(int argc,char **argv) {
    if (argc>2 && strcmp(argv[1],"--reference")==0) reference(argv[2]);
    else if (argc>1) oracle(argv[1]); else { dates(); official_calendar(); formatting(); selection(); malformed(); }
    printf("PASS total: %lu assertions\n",checks); return 0;
}

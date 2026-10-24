#include <jni.h>
#include <stdlib.h>
#include "rooz.h"
#define JNI_FN(name) JNIEXPORT name JNICALL
#define UNUSED (void)env; (void)self
static void error(JNIEnv *env,int code) {
    jclass type=(*env)->FindClass(env,"java/lang/IllegalArgumentException");
    if (type) (*env)->ThrowNew(env,type,rc_status_message(code));
}
JNI_FN(jint) Java_dev_rooz_Native_abi(JNIEnv *env,jobject self) { UNUSED; return rc_abi_version(); }
JNI_FN(jstring) Java_dev_rooz_Native_message(JNIEnv *env,jobject self,jint s) { (void)self; return (*env)->NewStringUTF(env,rc_status_message(s)); }
JNI_FN(jint) Java_dev_rooz_Native_toDay(JNIEnv *env,jobject self,jint c,jint y,jint m,jint d) { UNUSED; return rc_to_day(c,y,m,d); }
JNI_FN(jint) Java_dev_rooz_Native_field(JNIEnv *env,jobject self,jint c,jint d,jint f) { UNUSED; return rc_get_field(c,d,f); }
JNI_FN(jint) Java_dev_rooz_Native_addDays(JNIEnv *env,jobject self,jint c,jint d,jint n) { UNUSED; return rc_add_days(c,d,n); }
JNI_FN(jint) Java_dev_rooz_Native_addMonths(JNIEnv *env,jobject self,jint c,jint d,jint n,jint o) { UNUSED; return rc_add_months(c,d,n,o); }
JNI_FN(jint) Java_dev_rooz_Native_grid(JNIEnv *env,jobject self,jint c,jint y,jint m,jint f) { UNUSED; return rc_grid_start(c,y,m,f); }
JNI_FN(jint) Java_dev_rooz_Native_parse(JNIEnv *env,jobject self,jint c,jstring text,jstring pattern) {
    (void)self;
    const char *t=(*env)->GetStringUTFChars(env,text,NULL); if (!t) return RC_INVALID_DAY;
    const char *p=(*env)->GetStringUTFChars(env,pattern,NULL);
    int result=p?rc_parse(c,t,p):RC_INVALID_DAY;
    if (p) (*env)->ReleaseStringUTFChars(env,pattern,p);
    (*env)->ReleaseStringUTFChars(env,text,t); return result;
}
JNI_FN(jstring) Java_dev_rooz_Native_format(JNIEnv *env,jobject self,jint c,jint d,jstring pattern,jint locale,jint digits) {
    (void)self;
    const char *p=(*env)->GetStringUTFChars(env,pattern,NULL); if (!p) return NULL;
    size_t length=(size_t)(*env)->GetStringUTFLength(env,pattern), capacity=length*128+256;
    char *out=(char *)malloc(capacity);
    if (!out) { (*env)->ReleaseStringUTFChars(env,pattern,p); error(env,RC_BUFFER_SMALL); return NULL; }
    int status=rc_format(c,d,p,rc_builtin_locale(c,locale),digits,out,capacity);
    jstring result=status?NULL:(*env)->NewStringUTF(env,out);
    free(out); (*env)->ReleaseStringUTFChars(env,pattern,p);
    if (status) error(env,status);
    return result;
}
static int rules(JNIEnv *env,jintArray values,jintArray blocked,rc_rules *r,jint **buffer) {
    if (!values || !blocked || (*env)->GetArrayLength(env,values)!=5) return RC_INVALID;
    jint v[5]; (*env)->GetIntArrayRegion(env,values,0,5,v);
    if ((*env)->ExceptionCheck(env)) return RC_INVALID;
    jsize n=(*env)->GetArrayLength(env,blocked);
    *buffer=n?(*env)->GetIntArrayElements(env,blocked,NULL):NULL;
    if (n && !*buffer) return RC_INVALID;
    r->min_day=v[0]; r->max_day=v[1]; r->min_length=v[2]; r->max_length=v[3];
    r->disabled_weekdays=(uint32_t)v[4]; r->blocked_days=(const int32_t *)*buffer; r->blocked_count=(size_t)n;
    return RC_OK;
}
JNI_FN(jint) Java_dev_rooz_Native_validate(JNIEnv *env,jobject self,jint start,jint end,jintArray values,jintArray blocked) {
    (void)self; rc_rules r; jint *buffer=NULL;
    int s=rules(env,values,blocked,&r,&buffer);
    if (!s) s=rc_validate_range(start,end,&r);
    if (buffer) (*env)->ReleaseIntArrayElements(env,blocked,buffer,JNI_ABORT);
    return s;
}
JNI_FN(jintArray) Java_dev_rooz_Native_select(JNIEnv *env,jobject self,jint mode,jint start,jint end,jint tap,jintArray values,jintArray blocked) {
    (void)self; rc_rules r; jint *buffer=NULL; rc_selection old={start,end}, out=old;
    int s=rules(env,values,blocked,&r,&buffer);
    if (!s) s=rc_select(mode,old,tap,&r,&out);
    if (buffer) (*env)->ReleaseIntArrayElements(env,blocked,buffer,JNI_ABORT);
    if ((*env)->ExceptionCheck(env)) return NULL;
    jint result[3]={s,out.start,out.end};
    jintArray array=(*env)->NewIntArray(env,3);
    if (array) (*env)->SetIntArrayRegion(env,array,0,3,result);
    return array;
}

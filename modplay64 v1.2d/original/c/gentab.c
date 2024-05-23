/* converted from basic(!) by iAN CooG/HF
 * generator for pitch tables used in modplay 1.2x
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
int main(int argc, char *argv[])
{
    float aj[] = {19.9,
                  20.05,
                  20.05,
                  20.25,
                  19.75,
                  19.82,
                  20,
                  20,
                  16.61,
                  16.74,
                  16.82,
                  17.05,
                  17.32,
                  17.73,
                  16.72,
                  17.39,
                  17,
                  16.12};
    float lt[1024]={0};
    float lg,ajj;
    unsigned char mem[0x10000]={0};
    unsigned char cfile[260]={0};
    int x,l1,l2,z;
    int sp=0,di=0,pm=0;
    FILE *h;

    /*
    100 PRINT"{down}Generating LOG(x) Table{.*3}":FORx=0TO31:lt(x)=.:NEXT
    110 lg=LOG(2):FORx=32TO1023:lt(x)=LOG(x)/lg:gosub2:NEXT:l1=58880:l2=l1+1024
    */
    lg=log(2);
    for(x=0;x<32;x++)
        lt[x]=0.0;
    for(x=32;x<1024;x++)
        lt[x]=log(x)/lg;

    l1=0xe600;l2=l1+0x400;

    for(pm=1;pm<4;pm+=2)
    {
        for(sp=0;sp<2;sp++)
        {
            for(di=0;di<2;di++)
            {
                /*
                IFpm=1THENaj=aj(sp+di*2):GOTO2580
                IFpm=3THENaj=aj(4+sp)
                */
                if(pm==1)
                    ajj=aj[sp+di*2];
                else
                    ajj=aj[4+sp];
                /*
                120 FORx=0TO31:POKEl1+x,.:POKEl2+x,.:NEXT
                2580 FORx=32TO1023:z=2^(aj-lt(x)):POKEl1+x,z-INT(z/bg)*bg:POKEl2+x,INT(z/bg):next
                */

                for(x=0;x<32;x++)
                {
                    mem[l1+x]=0;
                    mem[l2+x]=0;
                }

                for(x=32;x<1024;x++)
                {
                    z=pow(2,ajj-lt[x]);
                                            /*bg=256;*/
                    mem[l1+x]=z&0xff;       /*z-INT(z/bg)*bg means low byte of word z */
                    mem[l2+x]=(z>>8)&0xff;  /*INT(z/bg)      means hi  byte of word z */
                }

                sprintf(cfile,"mem_e600_pm%dsp%ddi%d.bin",pm,sp,di);
                h=fopen(cfile,"wb");
                //fwrite(mem,0x10000,1,h);
                mem[l1-2]=l1&0xff;
                mem[l1-1]=l1>>8;
                fwrite(mem+l1-2,0x802,1,h);
                fclose(h);
            }
        }
    }
    /* useless, printed to file out of curiosity */
    /*
    sprintf(cfile,"logtable.txt",pm,sp,di);
    h=fopen(cfile,"wb");
    for(x=0;x<1024;x++)
        fprintf(h,"%lf\r\n",lt[x]);
    fclose(h);
    */
    return 0;
}

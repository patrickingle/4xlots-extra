//+------------------------------------------------------------------+
//|                                                  Urdala_News.mq4 |
//|                                        Sergei (urdala) Rashevsky |
//|                                                   urdala@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Sergei (urdala) Rashevsky"
#property link      "urdala@mail.ru"

#property description "News indicator."
#property description "News is taken from the site https://www.investing.com/economic-calendar/"
#property description "It does not work on history. Shows only the current week."
#property strict

#property indicator_chart_window
#property indicator_buffers 1

extern int   MinDo          = 30;         // Working minutes before the news    
extern int   MinPosle       = 30;         // Minutes after the news
extern int   offset         = 3;          // Server Time Zone
extern bool  Vhigh          = true;       // Show important news
extern bool  Vmedium        = true;       // Show average news
extern bool  Vlow           = true;       // Show weak news
extern string NewsSymb      = "USD,EUR,GBP,CHF,CAD,AUD,NZD,JPY"; //Currencies for display in news (empty - only current currencies)
extern bool  RisovatLini    = true;       // Draw lines on the chart
extern bool  Next           = false;      // Draw only the lines of future news  
extern bool  Signal         = false;      // To signal about the upcoming news
extern color highc          = clrRed;     // Color of important news
extern color mediumc        = clrBlue;    // Color medium news
extern color lowc           = clrLime;    // Color of weak news
extern int   Style          = 2;          // Line Style  
extern int   Upd            = 86400;      // News update period in seconds

//--------------------------------------------------------------------
#import "wininet.dll"
int InternetAttemptConnect(int x);
int InternetOpenW(string sAgent,int lAccessType,
                  string sProxyName="",string sProxyBypass="",
                  int lFlags=0);
int InternetOpenUrlW(int hInternetSession,string sUrl,
                     string sHeaders="",int lHeadersLength=0,
                     int lFlags=0,int lContext=0);
int InternetReadFile(int hFile,int &sBuffer[],int lNumBytesToRead,
                     int &lNumberOfBytesRead[]);
int InternetCloseHandle(int hInet);
#import
//---------------------------------------------------------------------
double Torg[1];
int NomNews = 0;
string NewsArr[4][1000];

int Now=0;
color Col;
datetime LastUpd;
string str1;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   IndicatorBuffers(1);
   SetIndexBuffer(0,Torg);
   if(StringLen(NewsSymb)>1)str1=NewsSymb;
     else str1=Symbol();   
//---
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason) 
{
   if(reason == REASON_REMOVE)ObjectsDeleteAll(0,OBJ_VLINE);
   if(reason == REASON_PARAMETERS)
      {
       for(int i=0;i<ObjectsTotal();i++)
         {
          string name = ObjectName(i);
          if(ObjectGet(name,OBJPROP_TYPE) == OBJ_VLINE && ObjectGet(name,OBJPROP_TIME) >= iTime(Symbol(),PERIOD_W1,0)){ObjectDelete(name);i--;}
         }
      }
   return;
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   if(TimeCurrent()-LastUpd>=Upd){
      Comment("Loading news...");
      Print("Loading news...");
      UpdateNews();
      LastUpd=TimeCurrent();
      Comment("");
   }
   WindowRedraw();
//---Drawing news lines on the chart--------------------------------------------
   if(RisovatLini)
     {
      for(int i=0;i<NomNews;i++)
        {
         //Print(NewsArr[3][i]);
         string Name = StringSubstr(TimeToStr(TimeNewsFunck(i),TIME_MINUTES)+"_"+NewsArr[1][i]+"_"+NewsArr[3][i],0,63);
         if(NewsArr[3][i]!="")if(ObjectFind(Name)==0)continue;
         if(StringFind(str1,NewsArr[1][i])<0)continue;
         if(TimeNewsFunck(i)<TimeCurrent() && Next)continue;
        
         color clrf = clrNONE;
         if(Vhigh &&   StringFind(NewsArr[2][i],"High")>=0    )clrf = highc;
         if(Vmedium && StringFind(NewsArr[2][i],"Moderate")>=0)clrf = mediumc;
         if(Vlow &&    StringFind(NewsArr[2][i],"Low")>=0     )clrf = lowc;
        
         if(clrf == clrNONE)continue;

         if(NewsArr[3][i]!="")
           {
            ObjectCreate(Name,0,OBJ_VLINE,TimeNewsFunck(i),0);
            ObjectSet(Name,OBJPROP_COLOR,clrf);
            ObjectSet(Name,OBJPROP_STYLE,Style);
           }
        }
     }
//---------------Event Handling------------------------------------
   int i;
   Torg[0]=0;
   for(i=0;i<NomNews;i++)
     {
      int power = 0;
      if(Vhigh &&   StringFind(NewsArr[2][i],"High")>=0     )power = 1;
      if(Vmedium && StringFind(NewsArr[2][i],"Moderate")>= 0)power = 2;
      if(Vlow &&    StringFind(NewsArr[2][i],"Low")>= 0     )power = 3;
      if(power == 0)continue;
      if(TimeCurrent()+MinDo*60>TimeNewsFunck(i) && TimeCurrent()-MinPosle*60<TimeNewsFunck(i) && StringFind(str1,NewsArr[1][i])>=0)
        {
         Torg[0]=1;
         break;
        }
      else Torg[0]=0;

     }
   if(Torg[0]==1 && i!=Now && Signal) {Alert("Across ",(int)(TimeNewsFunck(i)-TimeCurrent())/60," minutes will be news ",NewsArr[1][i],"_",NewsArr[3][i]);Now=i;}   
//--- return value of prev_calculated for next call
   return(rates_total);
  }

datetime TimeNewsFunck(int nomf)
   {
    string s = NewsArr[0][nomf];
    string time = StringConcatenate(StringSubstr(s,0,4),".",StringSubstr(s,5,2),".",StringSubstr(s,8,2)," ",StringSubstr(s,11,2),":",StringSubstr(s,14,4));
    return((datetime)(StringToTime(time) + offset*3600));
   }

//////////////////////////////////////////////////////////////////////////////////
void UpdateNews()
  {
   string TEXT = ReadCBOE();
   int sh = StringFind(TEXT,"pageStartAt>")+12;
   int sh2= StringFind(TEXT,"</tbody>");
   TEXT = StringSubstr(TEXT,sh,sh2-sh);
  
   sh = 0;
   while(!IsStopped())
     {
      sh = StringFind(TEXT,"event_timestamp",sh)+17;
      sh2= StringFind(TEXT,"onclick",sh)-2;
      if(sh<17 || sh2<0)break;
      NewsArr[0][NomNews]=StringSubstr(TEXT,sh,sh2-sh);
      
      sh = StringFind(TEXT,"flagCur",sh)+10;
      sh2= sh+3;
      if(sh<10 || sh2<3)break;
      NewsArr[1][NomNews]=StringSubstr(TEXT,sh,sh2-sh);
      if(StringFind(str1,NewsArr[1][NomNews])<0)continue;
      
      sh = StringFind(TEXT,"title",sh)+7;
      sh2= StringFind(TEXT,"Volatility",sh)-1;
      if(sh<7 || sh2<0)break;
      NewsArr[2][NomNews]=StringSubstr(TEXT,sh,sh2-sh);
      if(StringFind(NewsArr[2][NomNews],"High")>=0 && !Vhigh)continue;
      if(StringFind(NewsArr[2][NomNews],"Moderate")>=0 && !Vmedium)continue;
      if(StringFind(NewsArr[2][NomNews],"Low")>=0 && !Vlow)continue;
      
      sh = StringFind(TEXT,"left event",sh)+12;
      int sh1= StringFind(TEXT,"Speaks",sh);
      sh2= StringFind(TEXT,"<",sh);
      if(sh<12 || sh2<0)break;
      if(sh1<0 || sh1>sh2)NewsArr[3][NomNews]=StringSubstr(TEXT,sh,sh2-sh);
         else NewsArr[3][NomNews]=StringSubstr(TEXT,sh,sh1-sh);
      
      //Print(NomNews,"  ",NewsArr[0][NomNews],"  ",NewsArr[1][NomNews],"  ",NewsArr[2][NomNews],"  ",sh,"  ",sh1,"  ",sh2,"  ",NewsArr[3][NomNews]);
      NomNews ++ ;
      if(NomNews==300)break;
     }
  }
//////////////////////////////////////////////////////////////////////////////////
// It downloads the source code of the CBOE page into a text variable and 
// returns it as a result
//////////////////////////////////////////////////////////////////////////////////
string ReadCBOE()
{
   if(!IsDllsAllowed())
     {
       Alert("Allow in the settings to allow the use of DLLs");
       return("");
     }
   int rv = InternetAttemptConnect(0);
   if(rv != 0)
     {
       Alert("An error occurred while calling InternetAttemptConnect ()");
       return("");
     }
   int hInternetSession = InternetOpenW("Microsoft Internet Explorer",
                                        0, "", "", 0);
   if(hInternetSession <= 0)
     {
       Alert("An error occurred while calling InternetOpenA ()");
       return("");        
     }
   int hURL = InternetOpenUrlW(hInternetSession,
              "http://ec.forexprostools.com?columns=exc_currency,exc_importance&category=_employment,_economicActivity,_inflation,_credit,_centralBanks,_confidenceIndex,_balance,_Bonds&importance=1,2,3&countries=25,6,37,72,22,17,39,10,35,43,60,36,110,26,12,4,5&calType=week&timeZone=15&lang=1", "", 0, 0, 0);
   if(hURL <= 0)
     {
       Alert("An error occurred while calling InternetOpenUrlA ()");
       InternetCloseHandle(hInternetSession);
       return("");        
     }      
   int cBuffer[256];
   int dwBytesRead[1];
   string TXT = "";
   while(!IsStopped())
     {
       bool bResult = InternetReadFile(hURL, cBuffer, 1024, dwBytesRead);
       if(dwBytesRead[0] == 0)
           break;
       string text = "";  
       string text0= "";  
       for(int i = 0; i < 256; i++)
         {
              text0= CharToStr((char)(cBuffer[i] & 0x000000FF));
              if (text0!="\r") text = text + text0;
              else dwBytesRead[0]--;
              if(StringLen(text) == dwBytesRead[0]) break;
              
              text0= CharToStr((char)(cBuffer[i] >> (8 & 0x000000FF)));
              if (text0!="\r") text = text + text0;
              else dwBytesRead[0]--;
              if(StringLen(text) == dwBytesRead[0]) break;
              
              text0= CharToStr((char)(cBuffer[i] >> (16 & 0x000000FF)));
              if (text0!="\r") text = text + text0;
              else dwBytesRead[0]--;
              if(StringLen(text) == dwBytesRead[0]) break;

              text0= CharToStr((char)(cBuffer[i] >> (24 & 0x000000FF)));
              if (text0!="\r") text = text + text0;
              else dwBytesRead[0]--;
              if(StringLen(text) == dwBytesRead[0]) break;
              
         }
       TXT = TXT + text;
       Sleep(1);
     }
   InternetCloseHandle(hInternetSession);
   return(TXT);
} 
//+------------------------------------------------------------------+
